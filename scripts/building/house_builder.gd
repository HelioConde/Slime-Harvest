extends Node2D
## Test construction: one connected house, one material per painted area cell.
const SAVE_PATH := "user://house_terrain_test.json"
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
@export var player_path: NodePath
@export var ground_path: NodePath
@export var wall_tiles: TileSet
@export var roof_tiles: TileSet
@export_range(1, 100) var material_limit: int = 25

@onready var player: CharacterBody2D = get_node_or_null(player_path) as CharacterBody2D
@onready var ground: TileMapLayer = get_node_or_null(ground_path) as TileMapLayer
@onready var walls: TileMapLayer = $Walls
@onready var roof: TileMapLayer = $Roof
@onready var ghost: Sprite2D = $Preview

var footprint: Dictionary = {}
var history: Array[Dictionary] = []
var bodies: Array[StaticBody2D] = []
var building := false
var previous_controls := true
var panel: PanelContainer
var balance: Label
var status: Label
var hint: Label
var cursor := Vector2i(99999, 99999)
var last_button := 0
var terrain_source: TileSetAtlasSource
var previous_cell := Vector2i(99999, 99999)

func _ready() -> void:
	if player == null or ground == null or wall_tiles == null or roof_tiles == null:
		push_error("HouseBuilder: configure Player, solo e TileSets.")
		set_process(false)
		set_process_unhandled_key_input(false)
		return
	walls.tile_set = wall_tiles
	_make_roof_terrain()
	var texture := AtlasTexture.new()
	texture.atlas = terrain_source.texture
	texture.region = Rect2(15 * 16, 0, 16, 16)
	texture.filter_clip = true
	ghost.texture = texture
	_build_ui()
	ghost.hide()

func _make_roof_terrain() -> void:
	var original := roof_tiles.get_source(roof_tiles.get_source_id(0)) as TileSetAtlasSource
	var source_image := original.texture.get_image()
	var atlas_image := Image.create(16 * 16, 16, false, Image.FORMAT_RGBA8)
	# The vertical roof at x=0..2 contains transparent margins and a ridge.
	# Use the opaque horizontal roof filling instead; each neighbour pattern
	# receives only the exterior trim, so interior cells join without seams.
	var border := Color("69505c")
	for mask in range(16):
		var origin := Vector2i(mask * 16, 0)
		atlas_image.blit_rect(source_image, Rect2i(64, 48, 16, 16), origin)
		if (mask & 1) == 0:
			atlas_image.blit_rect(source_image, Rect2i(64, 32, 16, 3), origin)
			atlas_image.fill_rect(Rect2i(origin, Vector2i(16, 1)), border)
		if (mask & 4) == 0:
			atlas_image.blit_rect(source_image, Rect2i(64, 64, 16, 3), origin + Vector2i(0, 13))
			atlas_image.fill_rect(Rect2i(origin + Vector2i(0, 15), Vector2i(16, 1)), border)
		if (mask & 8) == 0:
			atlas_image.fill_rect(Rect2i(origin, Vector2i(1, 16)), border)
		if (mask & 2) == 0:
			atlas_image.fill_rect(Rect2i(origin + Vector2i(15, 0), Vector2i(1, 16)), border)
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(16, 16)
	tiles.add_terrain_set()
	tiles.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_SIDES)
	tiles.add_terrain(0)
	tiles.set_terrain_name(0, 0, "Casa")
	terrain_source = TileSetAtlasSource.new()
	terrain_source.texture = ImageTexture.create_from_image(atlas_image)
	terrain_source.texture_region_size = Vector2i(16, 16)
	tiles.add_source(terrain_source, 0)
	var peers: Array[int] = [TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_RIGHT_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_LEFT_SIDE]
	for mask in range(16):
		var atlas := Vector2i(mask, 0)
		terrain_source.create_tile(atlas)
		var data := terrain_source.get_tile_data(atlas, 0)
		data.terrain_set = 0
		data.terrain = 0
		for index in range(4):
			data.set_terrain_peering_bit(peers[index], 0 if (mask & (1 << index)) != 0 else -1)
	roof.tile_set = tiles
	roof.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)
	hint = Label.new()
	hint.text = "B: construir casa (%d materiais)" % material_limit
	hint.position = Vector2(8, 8)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hint)
	panel = PanelContainer.new()
	panel.position = Vector2(8, 8)
	panel.custom_minimum_size = Vector2(210, 0)
	canvas.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "Construir casa"
	box.add_child(title)
	balance = Label.new()
	box.add_child(balance)
	var tools := HBoxContainer.new()
	box.add_child(tools)
	_button(tools, "Desfazer", _undo)
	_button(tools, "Ver telhado", _toggle_roof)
	var storage := HBoxContainer.new()
	box.add_child(storage)
	_button(storage, "Salvar", _save_house)
	_button(storage, "Carregar", _load_house)
	status = Label.new()
	status.custom_minimum_size.x = 210
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.text = "Primeiro clique inicia sua casa."
	box.add_child(status)
	var help := Label.new()
	help.text = "Esquerdo: pintar / expandir\nDireito: remover e devolver\nB / Esc: sair"
	box.add_child(help)
	_refresh_balance()
	panel.hide()

func _button(parent: Node, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	parent.add_child(button)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.physical_keycode == KEY_B or building and event.physical_keycode == KEY_ESCAPE:
		if not building:
			previous_controls = bool(player.get("controls_enabled"))
		building = not building
		player.call("set_controls_enabled", false if building else previous_controls)
		panel.visible = building
		hint.visible = not building
		ghost.visible = building
		last_button = 0
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not building:
		return
	cursor = roof.local_to_map(roof.get_local_mouse_position())
	var over_panel := panel.get_global_rect().has_point(get_viewport().get_mouse_position())
	ghost.visible = not over_panel
	ghost.global_position = roof.to_global(roof.map_to_local(cursor))
	var reason := _add_reason(cursor)
	ghost.modulate = Color(1, 1, 1, 0.6) if reason.is_empty() else Color(1, 0.3, 0.3, 0.6)
	var button := 1 if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) else 2 if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) else 0
	if button == 0 or over_panel:
		last_button = 0
		return
	if button == last_button and cursor == previous_cell:
		return
	last_button = button
	previous_cell = cursor
	if button == 1:
		if footprint.has(cursor):
			return
		if not reason.is_empty():
			status.text = reason
			return
		_remember()
		footprint[cursor] = true
		_rebuild()
		status.text = "Área construída. Salve para guardar."
	else:
		if not footprint.has(cursor):
			return
		var next := footprint.duplicate()
		next.erase(cursor)
		if not _connected(next):
			status.text = "Não pode separar a casa em duas partes."
			return
		if not _space_free(next):
			status.text = "Libere o espaço das novas paredes."
			return
		_remember()
		footprint = next
		_rebuild()
		status.text = "Célula removida: 1 material devolvido."

func _add_reason(cell: Vector2i) -> String:
	if footprint.has(cell):
		return ""
	if footprint.size() >= material_limit:
		return "Materiais esgotados: limite de %d células." % material_limit
	if not footprint.is_empty():
		var adjacent := false
		for direction in DIRECTIONS:
			if footprint.has(cell + direction):
				adjacent = true
		if not adjacent:
			return "Pinte ao lado da casa para expandir."
	var next := footprint.duplicate()
	next[cell] = true
	if not _space_free(next):
		return "Use solo livre, longe da água e dos objetos."
	return ""

func _connected(cells: Dictionary) -> bool:
	if cells.is_empty():
		return true
	var pending: Array[Vector2i] = []
	pending.append(cells.keys()[0])
	var visited: Dictionary = {}
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_back()
		if visited.has(cell):
			continue
		visited[cell] = true
		for direction in DIRECTIONS:
			if cells.has(cell + direction) and not visited.has(cell + direction):
				pending.append(cell + direction)
	return visited.size() == cells.size()

func _facade(cells: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in cells:
		var cell: Vector2i = key
		if cells.has(cell + Vector2i.DOWN):
			continue
		for y in range(1, 3):
			var front := cell + Vector2i(0, y)
			if not cells.has(front):
				result[front] = Vector2i(1, y)
	for key in result.keys():
		var cell: Vector2i = key
		var left := result.has(cell + Vector2i.LEFT)
		var right := result.has(cell + Vector2i.RIGHT)
		var x := 0 if not left and right else 2 if left and not right else 1
		result[cell] = Vector2i(x, result[cell].y)
	return result

func _space_free(cells: Dictionary) -> bool:
	var occupied := cells.duplicate()
	for cell in _facade(cells):
		occupied[cell] = true
	var exclusions: Array[RID] = []
	for body in bodies:
		if is_instance_valid(body):
			exclusions.append(body.get_rid())
	var shape := RectangleShape2D.new()
	shape.size = Vector2(14, 14)
	for key in occupied:
		var cell: Vector2i = key
		var point := roof.to_global(roof.map_to_local(cell))
		if ground.get_cell_source_id(ground.local_to_map(ground.to_local(point))) == -1:
			return false
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = shape
		query.transform = Transform2D(0, point)
		query.collision_mask = 3
		query.exclude = exclusions
		if not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
			return false
	return true

func _rebuild() -> void:
	roof.clear()
	walls.clear()
	for body in bodies:
		body.collision_layer = 0
		body.queue_free()
	bodies.clear()
	var cells: Array[Vector2i] = []
	for cell in footprint:
		cells.append(cell)
	if not cells.is_empty():
		roof.set_cells_terrain_connect(cells, 0, 0, false)
	var facade := _facade(footprint)
	var source := wall_tiles.get_source_id(0)
	for cell in facade:
		walls.set_cell(cell, source, facade[cell])
		_add_block(cell)
	_refresh_balance()

func _add_block(cell: Vector2i) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 2
	body.position = walls.map_to_local(cell)
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(16, 16)
	collider.shape = shape
	body.add_child(collider)
	walls.add_child(body)
	bodies.append(body)

func _remember() -> void:
	history.append(footprint.duplicate())
	if history.size() > 100:
		history.pop_front()

func _undo() -> void:
	if history.is_empty():
		return
	var previous: Dictionary = history.back()
	if not _space_free(previous):
		status.text = "Libere o espaço antes de desfazer."
		return
	history.pop_back()
	footprint = previous
	_rebuild()
	status.text = "Última pintura desfeita."

func _toggle_roof() -> void:
	roof.visible = not roof.visible

func _refresh_balance() -> void:
	balance.text = "Materiais: %d / %d" % [material_limit - footprint.size(), material_limit]

func _save_house() -> void:
	var cells: Array[Dictionary] = []
	for cell in footprint:
		cells.append({"x": cell.x, "y": cell.y})
	var file := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		status.text = "Não foi possível salvar."
		return
	file.store_string(JSON.stringify({"version": 1, "cells": cells}))
	file.flush()
	var error := file.get_error()
	file.close()
	if error == OK:
		error = DirAccess.rename_absolute(SAVE_PATH + ".tmp", SAVE_PATH)
	status.text = "Casa e materiais salvos." if error == OK else "Falha ao salvar."

func _load_house() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		status.text = "Ainda não há casa salva neste modo."
		return
	if FileAccess.get_file_as_bytes(SAVE_PATH).size() > 65536:
		status.text = "Arquivo inválido."
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary or data.get("version") != 1 or not data.get("cells") is Array:
		status.text = "Arquivo inválido."
		return
	if data.cells.size() > material_limit:
		status.text = "A casa ultrapassa os materiais disponíveis."
		return
	var next: Dictionary = {}
	for entry in data.cells:
		if not entry is Dictionary:
			status.text = "Célula inválida."
			return
		for axis in ["x", "y"]:
			if not entry.has(axis) or not (entry[axis] is int or entry[axis] is float) or float(entry[axis]) != floorf(float(entry[axis])) or absf(float(entry[axis])) > 4096:
				status.text = "Coordenada inválida."
				return
		var cell := Vector2i(int(entry.x), int(entry.y))
		if next.has(cell):
			status.text = "Célula repetida no arquivo."
			return
		next[cell] = true
	if not _connected(next) or not _space_free(next):
		status.text = "Casa desconectada ou espaço ocupado."
		return
	history.clear()
	footprint = next
	_rebuild()
	status.text = "Casa e saldo de materiais carregados."
