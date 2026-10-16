extends TileMapLayer
## Enxada no terreno verde do World, sem mudar os tiles pintados originalmente.
## Objetos e a casa inicial impedem o preparo do solo.
const SAVE_PATH := "user://slimekeepers_world_hoeing_v1.json"

@export var ground_path: NodePath
@export var water_path: NodePath
@export var soil_water_path: NodePath
@export var house_path: NodePath
@export var player_path: NodePath
@export_range(0, 8, 1) var house_clearance_tiles: int = 3
@export_range(0, 17, 1) var tilled_terrain_set: int = 17

@onready var grass: TileMapLayer = get_node_or_null(ground_path) as TileMapLayer
@onready var water: TileMapLayer = get_node_or_null(water_path) as TileMapLayer
@onready var other_ground: TileMapLayer = get_node_or_null(soil_water_path) as TileMapLayer
@onready var house: Node2D = get_node_or_null(house_path) as Node2D
@onready var player: CharacterBody2D = get_node_or_null(player_path) as CharacterBody2D

var _prepared: Dictionary = {}
var _feedback: Label
var _feedback_tween: Tween


func _ready() -> void:
	if grass == null or water == null or other_ground == null or player == null or house == null:
		push_error("WorldHoeing: referencie grass2, water, soil_water, HouseBuilder e Player.")
		return
	if tile_set == null or tilled_terrain_set >= tile_set.get_terrain_sets_count():
		push_error("WorldHoeing: TileSet de terra arada ausente.")
		return
	player.tool_action_requested.connect(_on_tool_action)
	_create_feedback()
	_load_cells()


func _on_tool_action(tool_id: StringName, world_position: Vector2) -> void:
	if tool_id != &"hoe":
		return
	var reason: String = try_till(world_position)
	_show_feedback(reason)


func try_till(world_position: Vector2) -> String:
	var cell: Vector2i = local_to_map(to_local(world_position))
	var reason: String = rejection_reason(cell)
	if not reason.is_empty():
		return reason
	_prepared[cell] = true
	_repaint()
	_save_cells()
	return ""


func rejection_reason(cell: Vector2i) -> String:
	if _prepared.has(cell):
		return "Esta terra ja esta arada."
	if grass == null or tile_set == null:
		return "O terreno ainda nao esta carregado."
	var world_point: Vector2 = to_global(map_to_local(cell))
	var grass_cell: Vector2i = grass.local_to_map(grass.to_local(world_point))
	var source_id: int = grass.get_cell_source_id(grass_cell)
	if source_id == -1 or not _source_is_green(grass.tile_set, source_id):
		return "A enxada so prepara o chao verde."
	# water e soil_water ficam por BAIXO de grass2 no World original.
	# Uma celula verde pintada na camada superior pode sobrepor ambas.
	# Bloqueie superficies que nao sejam verdes pela fonte visivel acima.
	if house.has_method("is_world_point_protected"):
		if bool(house.call("is_world_point_protected", world_point, house_clearance_tiles)):
			return "Muito perto da casa inicial."
	if _object_overlaps(world_point):
		return "Remova ou colete o objeto antes de arar."
	return ""


func _source_is_green(tiles: TileSet, source_id: int) -> bool:
	if tiles == null or not tiles.has_source(source_id):
		return false
	var atlas: TileSetAtlasSource = tiles.get_source(source_id) as TileSetAtlasSource
	if atlas == null or atlas.texture == null:
		return false
	var path: String = atlas.texture.resource_path.to_lower()
	# Permite superficies de grama clara/escura e camadas existentes; nunca pedra, terra ou encostas.
	return "grass" in path and not "slope" in path and not "bush" in path


func _object_overlaps(world_point: Vector2) -> bool:
	var area := Rect2(world_point - Vector2(7, 7), Vector2(14, 14))
	var shape := RectangleShape2D.new()
	shape.size = Vector2(14, 14)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, world_point)
	query.collision_mask = 1 | 4
	query.collide_with_bodies = true
	query.collide_with_areas = true
	if not get_world_2d().direct_space_state.intersect_shape(query, 32).is_empty():
		return true
	var observed: Dictionary = {}
	for group in ["world_objects", "choppable_trees", "mineable_rocks", "pickable_plants", "world_drops"]:
		for candidate in get_tree().get_nodes_in_group(group):
			var object := candidate as Node2D
			if object == null or observed.has(object) or not object.is_visible_in_tree() or object.is_queued_for_deletion():
				continue
			observed[object] = true
			# Vegetacao ja arrancada permanece na cena invisivel ate regenerar.
			if object.has_method("can_pick") and not bool(object.call("can_pick")):
				continue
			if _visual_bounds(object).intersects(area):
				return true
	return false


func _visual_bounds(object: Node2D) -> Rect2:
	var visual: Node2D = object.get_node_or_null("AnimatedSprite2D") as Node2D
	if visual == null:
		visual = object.get_node_or_null("Sprite2D") as Node2D
	var texture: Texture2D
	if visual is AnimatedSprite2D:
		var sprite := visual as AnimatedSprite2D
		if sprite.visible and sprite.sprite_frames != null and sprite.sprite_frames.get_frame_count(sprite.animation) > 0:
			texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	elif visual is Sprite2D:
		var sprite := visual as Sprite2D
		if sprite.visible:
			texture = sprite.texture
	if texture != null and visual != null:
		var half: Vector2 = texture.get_size() * 0.5
		var top_left: Vector2 = visual.to_global(-half)
		var bottom_right: Vector2 = visual.to_global(half)
		return Rect2(top_left.min(bottom_right), (bottom_right - top_left).abs())
	return Rect2(object.global_position - Vector2(7, 7), Vector2(14, 14))


func is_tilled(cell: Vector2i) -> bool:
	return _prepared.has(cell)


func _repaint() -> void:
	clear()
	if _prepared.is_empty():
		return
	var cells: Array[Vector2i] = []
	for cell in _prepared:
		cells.append(cell)
	set_cells_terrain_connect(cells, tilled_terrain_set, 0, true)


func _load_cells() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary or int(data.get("version", 0)) != 1 or not data.get("cells", []) is Array:
		push_warning("WorldHoeing: save invalido, ignorando.")
		return
	for entry in data["cells"]:
		if not entry is Dictionary:
			continue
		var x: Variant = entry.get("x")
		var y: Variant = entry.get("y")
		# JSON do Godot normalmente carrega numeros inteiros como float.
		if not (x is float or x is int) or not (y is float or y is int):
			continue
		if not is_finite(float(x)) or not is_finite(float(y)):
			continue
		if float(x) != floorf(float(x)) or float(y) != floorf(float(y)):
			continue
		var cell := Vector2i(int(x), int(y))
		if absi(cell.x) > 4096 or absi(cell.y) > 4096:
			continue
		if rejection_reason(cell).is_empty():
			_prepared[cell] = true
	_repaint()


func _save_cells() -> void:
	var entries: Array[Dictionary] = []
	for cell in _prepared:
		entries.append({"x": cell.x, "y": cell.y})
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("WorldHoeing: nao foi possivel salvar.")
		return
	file.store_string(JSON.stringify({"version": 1, "cells": entries}))


func _create_feedback() -> void:
	var hud := CanvasLayer.new()
	hud.layer = 12
	add_child(hud)
	_feedback = Label.new()
	_feedback.name = "HoeFeedback"
	_feedback.position = Vector2(12, 44)
	_feedback.add_theme_font_size_override("font_size", 11)
	_feedback.add_theme_color_override("font_color", Color("#f4e8b3"))
	_feedback.add_theme_constant_override("outline_size", 2)
	_feedback.add_theme_color_override("font_outline_color", Color("#243024"))
	_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_feedback)


func _show_feedback(reason: String) -> void:
	if _feedback == null:
		return
	if is_instance_valid(_feedback_tween):
		_feedback_tween.kill()
	_feedback.text = "Terra arada!" if reason.is_empty() else reason
	_feedback.modulate.a = 1.0
	_feedback_tween = create_tween()
	_feedback_tween.tween_interval(0.8)
	_feedback_tween.tween_property(_feedback, "modulate:a", 0.0, 0.5)


func _exit_tree() -> void:
	if not _prepared.is_empty():
		_save_cells()
