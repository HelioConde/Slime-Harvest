extends Node2D
## Populacao aleatoria do grass2, com localizacao fixa por partida.
## Recursos ja colhidos/cortados sao restaurados por seus scripts existentes.
@export var save_path: String = "user://slimekeepers_world_spawns_v1.json"
@export_range(1, 6, 1) var border_margin_tiles: int = 2
@export_range(32.0, 256.0, 1.0) var spawn_clearance: float = 88.0

const SAVE_VERSION := 1
const SAVE_PREFIX := "world_random_v1_"
const DEFINITIONS: Array[Dictionary] = [
	{"kind": "tree", "count": 10, "space": 34.0, "margin": 3, "paths": [
		"res://scenes/objects/trees/tree.tscn",
		"res://scenes/objects/trees/tree_small.tscn",
		"res://scenes/objects/trees/tree_large.tscn",
		"res://scenes/objects/trees/tree_apple.tscn",
		"res://scenes/objects/trees/tree_orange.tscn",
		"res://scenes/objects/trees/tree_pear.tscn",
		"res://scenes/objects/trees/tree_peach.tscn"
	]},
	{"kind": "wood", "count": 7, "space": 22.0, "margin": 2, "paths": [
		"res://scenes/objects/logs/log_small.tscn",
		"res://scenes/objects/logs/log_large.tscn"
	]},
	{"kind": "rock", "count": 10, "space": 21.0, "margin": 2, "paths": [
		"res://scenes/objects/rocks/rock_01.tscn",
		"res://scenes/objects/rocks/rock_02.tscn",
		"res://scenes/objects/rocks/rock_03.tscn",
		"res://scenes/objects/rocks/rock_04.tscn",
		"res://scenes/objects/rocks/rock_05.tscn",
		"res://scenes/objects/rocks/rock_large.tscn"
	]},
	{"kind": "mushroom", "count": 9, "space": 17.0, "margin": 2, "paths": [
		"res://scenes/objects/mushrooms/mushroom_red.tscn"
	]},
	{"kind": "flower", "count": 15, "space": 15.0, "margin": 2, "paths": [
		"res://scenes/objects/flowers/flower_blue.tscn",
		"res://scenes/objects/flowers/flower_light_blue.tscn",
		"res://scenes/objects/flowers/flower_light_yellow.tscn",
		"res://scenes/objects/flowers/flower_pink.tscn",
		"res://scenes/objects/flowers/flower_purple.tscn",
		"res://scenes/objects/flowers/flower_yellow.tscn"
	]}
]
@onready var grass: TileMapLayer = get_node_or_null("../grass2") as TileMapLayer
@onready var water: TileMapLayer = get_node_or_null("../water") as TileMapLayer
@onready var house: Node2D = get_node_or_null("../HouseBuilder") as Node2D
@onready var player: Node2D = get_node_or_null("../../Player") as Node2D

var _rng := RandomNumberGenerator.new()
var _reserved: Array[Dictionary] = []
var _records: Array[Dictionary] = []
var _valid_cells: Array[Vector2i] = []
var _allowed_paths: Dictionary = {}
var _initialized: bool = false


func _ready() -> void:
	# HouseBuilder carrega a casa e colliders antes de escolher lugares.
	call_deferred("_initialize")


func _initialize() -> void:
	if _initialized:
		return
	if grass == null or grass.tile_set == null or player == null or house == null:
		push_error("WorldPopulation: grass2, Player ou HouseBuilder ausente.")
		return
	_initialized = true
	for definition in DEFINITIONS:
		for path in definition["paths"]:
			_allowed_paths[str(path)] = true
	_build_ground_cells()
	if _valid_cells.is_empty():
		push_warning("WorldPopulation: nao existem celulas seguras no grass2.")
		return
	if FileAccess.file_exists(save_path):
		if not _read_records():
			push_error("WorldPopulation: layout salvo invalido; nao sobrescrever o save.")
			return
	else:
		_rng.randomize()
		_generate_records()
		if not _write_records():
			push_error("WorldPopulation: falha ao salvar distribuicao; nao gerar objetos instaveis.")
			return
	_reserved.clear()
	var created: int = 0
	for record in _records:
		var point := Vector2(float(record["x"]), float(record["y"]))
		var margin: int = int(record["margin"])
		var distance: float = float(record["space"])
		if not is_safe_spawn(point, distance, margin):
			push_warning("WorldPopulation: posicao ocupada ou alterada: " + str(record["id"]))
			continue
		# Reservar inclusive os locais de arvores derrubadas/pedras mineradas.
		_reserved.append({"point": point, "space": distance})
		var path: String = str(record["path"])
		if not ResourceLoader.exists(path):
			push_warning("WorldPopulation: recurso inexistente: " + path)
			continue
		var scene := load(path) as PackedScene
		if scene == null:
			continue
		var item := scene.instantiate() as Node2D
		if item == null:
			continue
		item.name = "Random_" + str(record["id"])
		item.position = to_local(point)
		item.set("persistent_id", SAVE_PREFIX + str(record["id"]))
		if str(record["kind"]) in ["flower", "mushroom"]:
			item.set("start_fully_grown", true)
		add_child(item)
		created += 1
	print("WorldPopulation: %d/%d objetos posicionados no grass2." % [created, _records.size()])


func _build_ground_cells() -> void:
	_valid_cells.clear()
	var max_margin: int = border_margin_tiles
	for definition in DEFINITIONS:
		max_margin = maxi(max_margin, int(definition["margin"]))
	for cell in grass.get_used_cells():
		if _ground_is_safe(cell, max_margin):
			_valid_cells.append(cell)


func _green_cell(cell: Vector2i) -> bool:
	var source_id: int = grass.get_cell_source_id(cell)
	if source_id == -1 or not grass.tile_set.has_source(source_id):
		return false
	var atlas := grass.tile_set.get_source(source_id) as TileSetAtlasSource
	if atlas == null or atlas.texture == null:
		return false
	var texture_path: String = atlas.texture.resource_path.to_lower()
	return "grass" in texture_path and not "slope" in texture_path and not "bush" in texture_path


func _ground_is_safe(cell: Vector2i, margin: int) -> bool:
	# Exige grama continua em um quadrado; nunca nas pontas recortadas.
	for dy in range(-margin, margin + 1):
		for dx in range(-margin, margin + 1):
			var checked := cell + Vector2i(dx, dy)
			if not _green_cell(checked):
				return false
			if water != null and water.get_cell_source_id(checked) != -1:
				return false
	return true


func is_safe_spawn(point: Vector2, distance: float, margin: int = 2) -> bool:
	if grass == null or player == null or house == null:
		return false
	var cell: Vector2i = grass.local_to_map(grass.to_local(point))
	if not _ground_is_safe(cell, maxi(border_margin_tiles, margin)):
		return false
	if point.distance_to(player.global_position) < spawn_clearance + distance * 0.5:
		return false
	if house.has_method("is_world_point_protected"):
		if bool(house.call("is_world_point_protected", point, maxi(3, ceili(distance / 16.0) + 1))):
			return false
	for entry in _reserved:
		var other: Vector2 = entry["point"]
		if point.distance_to(other) < (distance + float(entry["space"])) * 0.5 + 5.0:
			return false
	# Impede cruzamento com frutas, plantas fixas, drops e objetos do usuario.
	for group in ["world_objects", "world_drops"]:
		for candidate in get_tree().get_nodes_in_group(group):
			var obj := candidate as Node2D
			if obj == null or obj.is_queued_for_deletion() or not obj.is_visible_in_tree():
				continue
			if obj.has_method("can_pick") and not bool(obj.call("can_pick")):
				continue
			if point.distance_to(obj.global_position) < distance * 0.5 + 12.0:
				return false
	var circle := CircleShape2D.new()
	circle.radius = maxf(6.0, distance * 0.36)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, point)
	query.collision_mask = 1
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _generate_records() -> void:
	_records.clear()
	_reserved.clear()
	for definition in DEFINITIONS:
		var kind: String = str(definition["kind"])
		var count: int = int(definition["count"])
		var paths: Array = definition["paths"]
		var space: float = float(definition["space"])
		var margin: int = int(definition["margin"])
		var placed := 0
		var attempts := 0
		while placed < count and attempts < count * 250:
			attempts += 1
			var cell: Vector2i = _valid_cells[_rng.randi_range(0, _valid_cells.size() - 1)]
			var world_point: Vector2 = grass.to_global(grass.map_to_local(cell))
			world_point += Vector2(_rng.randf_range(-3.0, 3.0), _rng.randf_range(-3.0, 3.0))
			if not is_safe_spawn(world_point, space, margin):
				continue
			var resource: String = str(paths[_rng.randi_range(0, paths.size() - 1)])
			var entry: Dictionary = {
				"id": "%s_%03d" % [kind, placed],
				"kind": kind, "path": resource, "x": world_point.x, "y": world_point.y,
				"space": space, "margin": margin
			}
			_records.append(entry)
			_reserved.append({"point": world_point, "space": space})
			placed += 1
		if placed < count:
			push_warning("WorldPopulation: %s: apenas %d/%d lugares livres." % [kind, placed, count])


func _read_records() -> bool:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not parsed is Dictionary or int(parsed.get("version", 0)) != SAVE_VERSION:
		return false
	var rows: Variant = parsed.get("records")
	if not rows is Array or rows.size() > 180:
		return false
	var ids: Dictionary = {}
	var validated: Array[Dictionary] = []
	for row in rows:
		if not row is Dictionary:
			return false
		var path: String = str(row.get("path", ""))
		var kind: String = str(row.get("kind", ""))
		var id: String = str(row.get("id", ""))
		var x: Variant = row.get("x")
		var y: Variant = row.get("y")
		if not _allowed_paths.has(path) or id.is_empty() or id.length() > 45 or ids.has(id):
			return false
		if not kind in ["tree", "wood", "rock", "flower", "mushroom"]:
			return false
		if not (x is float or x is int) or not (y is float or y is int):
			return false
		if not is_finite(float(x)) or not is_finite(float(y)):
			return false
		if absf(float(x)) > 50000.0 or absf(float(y)) > 50000.0:
			return false
		var space: float = 17.0
		var margin: int = 2
		for definition in DEFINITIONS:
			if kind == definition["kind"]:
				if not path in definition["paths"]:
					return false
				space = float(definition["space"])
				margin = int(definition["margin"])
				break
		ids[id] = true
		validated.append({"id": id, "kind": kind, "path": path,
			"x": float(x), "y": float(y), "space": space, "margin": margin})
	_records = validated
	return true


func _write_records() -> bool:
	var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": SAVE_VERSION, "records": _records}))
	file.flush()
	file.close()
	var temp: String = ProjectSettings.globalize_path(save_path + ".tmp")
	var target: String = ProjectSettings.globalize_path(save_path)
	var result: Error = DirAccess.rename_absolute(temp, target)
	if result != OK:
		push_warning("WorldPopulation: falha ao substituir o arquivo do mapa (%d)." % result)
		return false
	return true
