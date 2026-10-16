extends TileMapLayer
## Uma superficie reutilizavel com os terrenos ja configurados em world_tileset.tres.
## A pintura manual no editor sempre tem prioridade sobre a geracao automatica.

@export_range(0, 17, 1) var terrain_set_index: int = 9
@export var size_in_tiles: Vector2i = Vector2i(11, 6)
@export var organic_border: bool = true


func _ready() -> void:
	if tile_set == null:
		push_error("TerrainPatch: associe o TileSet existente.")
		return
	if terrain_set_index < 0 or terrain_set_index >= tile_set.get_terrain_sets_count():
		push_error("TerrainPatch: conjunto de terreno invalido: %d" % terrain_set_index)
		return
	if tile_set.get_terrains_count(terrain_set_index) < 1:
		push_error("TerrainPatch: o conjunto nao possui terreno configurado.")
		return
	if not get_used_cells().is_empty():
		# Respeitar os tiles salvos manualmente no Godot.
		return
	var cells: Array[Vector2i] = []
	for y in range(maxi(1, size_in_tiles.y)):
		for x in range(maxi(1, size_in_tiles.x)):
			if organic_border and _clip_edge(x, y):
				continue
			cells.append(Vector2i(x, y))
	if not cells.is_empty():
		set_cells_terrain_connect(cells, terrain_set_index, 0, true)


func _clip_edge(x: int, y: int) -> bool:
	var last_x: int = size_in_tiles.x - 1
	var last_y: int = size_in_tiles.y - 1
	# Remover alguns cantos sem aleatoriedade: a mesma cena produz sempre a mesma ilha.
	if x == 0 and y in [0, last_y]:
		return true
	if x == last_x and y in [0, last_y]:
		return true
	return false
