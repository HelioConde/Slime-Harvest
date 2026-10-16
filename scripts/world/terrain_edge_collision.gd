extends StaticBody2D
## Colisao de margens por transparencia dos sprites do TileSet ja existente.
## Bloqueia apenas a agua exposta; grama/terra por cima continuam caminhaveis.
## A geometria se baseia na borda real do pixel art (resolucao de 1 pixel).

@export var water_path: NodePath
@export var grass_path: NodePath
@export var shore_path: NodePath
@export_range(0.01, 1.0, 0.01) var alpha_threshold: float = 0.20
@export_range(0, 4096, 1) var max_collision_rectangles: int = 4096

@onready var water: TileMapLayer = get_node_or_null(water_path) as TileMapLayer
@onready var grass: TileMapLayer = get_node_or_null(grass_path) as TileMapLayer
@onready var shore: TileMapLayer = get_node_or_null(shore_path) as TileMapLayer

var _mask_cache: Dictionary = {}
var _image_cache: Dictionary = {}
var _rectangles: int = 0
var _blocked_pixels: int = 0
var _tile_size: Vector2i = Vector2i(16, 16)
var _water_cells: Dictionary = {}


func _ready() -> void:
	collision_layer = 1
	collision_mask = 2
	if water == null or grass == null or shore == null or water.tile_set == null:
		push_error("TerrainEdgeCollision: configure water, grass2 e soil_water.")
		return
	_tile_size = water.tile_set.tile_size
	if _tile_size.x <= 0 or _tile_size.y <= 0:
		push_error("TerrainEdgeCollision: tiles invalidos.")
		return
	if water.tile_set != grass.tile_set or water.tile_set != shore.tile_set:
		push_error("TerrainEdgeCollision: as camadas precisam usar o mesmo TileSet.")
		return
	rebuild_collision()


func rebuild_collision() -> void:
	for shape in get_children():
		if shape is CollisionShape2D:
			remove_child(shape)
			shape.queue_free()
	_mask_cache.clear()
	_image_cache.clear()
	_water_cells.clear()
	_rectangles = 0
	_blocked_pixels = 0
	var used: Array[Vector2i] = water.get_used_cells()
	if used.is_empty():
		return
	var low: Vector2i = used[0]
	var high: Vector2i = low
	for cell in used:
		_water_cells[cell] = true
		low = Vector2i(mini(low.x, cell.x), mini(low.y, cell.y))
		high = Vector2i(maxi(high.x, cell.x), maxi(high.y, cell.y))

	# Cada linha tem runs horizontais de pixels de agua exposta.
	# Mesclar os mesmos runs nas linhas seguintes reduz os colliders.
	var active: Dictionary = {}
	for y in range(low.y * _tile_size.y, (high.y + 1) * _tile_size.y):
		var runs: Array[Vector2i] = []
		var begin: int = -1
		var left: int = low.x * _tile_size.x
		var right: int = (high.x + 1) * _tile_size.x
		for x in range(left, right):
			var occupied: bool = _is_water_pixel(Vector2i(x, y))
			if occupied:
				_blocked_pixels += 1
				if begin == -1:
					begin = x
			elif begin != -1:
				runs.append(Vector2i(begin, x))
				begin = -1
		if begin != -1:
			runs.append(Vector2i(begin, right))
		var next_active: Dictionary = {}
		for run in runs:
			if active.has(run):
				var extended: Rect2i = active[run]
				extended.size.y += 1
				next_active[run] = extended
			else:
				next_active[run] = Rect2i(run.x, y, run.y - run.x, 1)
		for key in active:
			if not next_active.has(key):
				_add_rectangle(active[key])
		active = next_active
	for rectangle in active.values():
		_add_rectangle(rectangle)
	if _rectangles >= max_collision_rectangles:
		push_warning("TerrainEdgeCollision: atingiu limite de colliders, revise o tamanho do mapa.")
	print("TerrainEdgeCollision: %d retangulos / %d pixels de agua exposta." % [_rectangles, _blocked_pixels])


func _is_water_pixel(pixel: Vector2i) -> bool:
	var cell := Vector2i(floori(float(pixel.x) / float(_tile_size.x)), floori(float(pixel.y) / float(_tile_size.y)))
	if not _water_cells.has(cell):
		return false
	var local_pixel := Vector2i(posmod(pixel.x, _tile_size.x), posmod(pixel.y, _tile_size.y))
	if not _cell_is_opaque(water, cell, local_pixel):
		return false
	if _cell_is_opaque(grass, cell, local_pixel):
		return false
	if _cell_is_opaque(shore, cell, local_pixel):
		return false
	return true


func _cell_is_opaque(layer: TileMapLayer, cell: Vector2i, local_pixel: Vector2i) -> bool:
	var mask: PackedByteArray = _get_tile_mask(layer, cell)
	if mask.is_empty():
		return false
	return mask[local_pixel.y * _tile_size.x + local_pixel.x] == 1


func _get_tile_mask(layer: TileMapLayer, cell: Vector2i) -> PackedByteArray:
	var source_id: int = layer.get_cell_source_id(cell)
	if source_id == -1:
		return PackedByteArray()
	var atlas: TileSetAtlasSource = layer.tile_set.get_source(source_id) as TileSetAtlasSource
	if atlas == null or atlas.texture == null:
		return PackedByteArray()
	var atlas_cell: Vector2i = layer.get_cell_atlas_coords(cell)
	var cache_key: String = "%d:%d:%d" % [source_id, atlas_cell.x, atlas_cell.y]
	if _mask_cache.has(cache_key):
		return _mask_cache[cache_key]
	if not _image_cache.has(source_id):
		_image_cache[source_id] = atlas.texture.get_image()
	var source_image: Image = _image_cache[source_id]
	if source_image == null or source_image.is_empty():
		return PackedByteArray()
	var region: Rect2i = atlas.get_tile_texture_region(atlas_cell)
	var mask := PackedByteArray()
	mask.resize(_tile_size.x * _tile_size.y)
	for y in range(_tile_size.y):
		for x in range(_tile_size.x):
			var image_x: int = region.position.x + x
			var image_y: int = region.position.y + y
			if image_x < source_image.get_width() and image_y < source_image.get_height():
				if source_image.get_pixel(image_x, image_y).a >= alpha_threshold:
					mask[y * _tile_size.x + x] = 1
	_mask_cache[cache_key] = mask
	return mask


func _add_rectangle(rectangle: Rect2i) -> void:
	if _rectangles >= max_collision_rectangles:
		return
	if rectangle.size.x <= 0 or rectangle.size.y <= 0:
		return
	var rect := RectangleShape2D.new()
	rect.size = Vector2(rectangle.size)
	var collider := CollisionShape2D.new()
	collider.shape = rect
	# Origem: o primeiro pixel da celula zero no TileMap.
	var tile_origin: Vector2 = water.map_to_local(Vector2i.ZERO) - Vector2(_tile_size) * 0.5
	var center: Vector2 = tile_origin + Vector2(rectangle.position) + Vector2(rectangle.size) * 0.5
	collider.global_position = center if is_inside_tree() else center
	add_child(collider)
	collider.global_position = water.to_global(center)
	_rectangles += 1


func collision_rectangle_count() -> int:
	return _rectangles


func blocked_pixel_count() -> int:
	return _blocked_pixels
