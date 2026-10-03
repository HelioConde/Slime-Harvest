extends Node2D
## Runtime house painting. The terrain and Player remain owned by the world.
const SAVE_PATH := "user://house_world2.json"
const MAX_CELLS := 2048
@export var player_path: NodePath
@export var ground_path: NodePath
@export var wall_tiles: TileSet
@export var roof_tiles: TileSet

@onready var player: CharacterBody2D = get_node_or_null(player_path) as CharacterBody2D
@onready var ground: TileMapLayer = get_node_or_null(ground_path) as TileMapLayer
@onready var walls: TileMapLayer = $Walls
@onready var roof: TileMapLayer = $Roof
@onready var ghost: Sprite2D = $Preview

var building := false
var selected_layer := 0
var selected_source := -1
var selected_atlas := Vector2i.ZERO
var previous_controls := true
var history: Array[Dictionary] = []
var blockers: Dictionary = {}
var panel: PanelContainer
var palette: GridContainer
var status: Label
var hint: Label
var last_cell := Vector2i(99999, 99999)
var last_button := 0

func _ready() -> void:
	walls.tile_set = wall_tiles
	roof.tile_set = roof_tiles
	_build_ui()
	_select_layer(0)
	panel.hide()
	ghost.hide()
	if player == null or ground == null:
		push_error("HouseBuilder: configure player_path e ground_path.")
		set_process(false)
		set_process_unhandled_key_input(false)

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)
	hint = Label.new()
	hint.text = "B: construir casa"
	hint.position = Vector2(8, 8)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hint)
	panel = PanelContainer.new()
	panel.position = Vector2(8, 8)
	panel.custom_minimum_size = Vector2(208, 0)
	canvas.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "Construir casa"
	box.add_child(title)
	var categories := HBoxContainer.new()
	box.add_child(categories)
	_button(categories, "Paredes", _select_layer.bind(0))
	_button(categories, "Telhado", _select_layer.bind(1))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(200, 132)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	palette = GridContainer.new()
	palette.columns = 5
	scroll.add_child(palette)
	var tools := HBoxContainer.new()
	box.add_child(tools)
	_button(tools, "Desfazer", _undo)
	_button(tools, "Ver telhado", _toggle_roof)
	var storage := HBoxContainer.new()
	box.add_child(storage)
	_button(storage, "Salvar", _save_house)
	_button(storage, "Carregar", _load_house)
	status = Label.new()
	status.text = "Escolha uma peça."
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.x = 200
	box.add_child(status)
	var help := Label.new()
	help.text = "Esquerdo: colocar\nDireito: apagar camada\nB / Esc: sair"
	box.add_child(help)

func _button(parent: Node, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	parent.add_child(button)

func _select_layer(layer: int) -> void:
	selected_layer = layer
	for child in palette.get_children():
		palette.remove_child(child)
		child.queue_free()
	var tiles: TileSet = wall_tiles if layer == 0 else roof_tiles
	var source_id := tiles.get_source_id(0)
	var source := tiles.get_source(source_id) as TileSetAtlasSource
	for index in range(source.get_tiles_count()):
		var atlas := source.get_tile_id(index)
		var texture := AtlasTexture.new()
		texture.atlas = source.texture
		texture.region = source.get_tile_texture_region(atlas)
		texture.filter_clip = true
		var button := Button.new()
		button.icon = texture
		button.expand_icon = true
		button.custom_minimum_size = Vector2(36, 36)
		button.tooltip_text = "Peça %s" % atlas
		button.pressed.connect(_select_tile.bind(source_id, atlas, texture))
		palette.add_child(button)
		if index == 0:
			_select_tile(source_id, atlas, texture)

func _select_tile(source_id: int, atlas: Vector2i, texture: Texture2D) -> void:
	selected_source = source_id
	selected_atlas = atlas
	ghost.texture = texture

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return
	if event.physical_keycode == KEY_B:
		_set_building(not building)
		get_viewport().set_input_as_handled()
	elif building and event.physical_keycode == KEY_ESCAPE:
		_set_building(false)
		get_viewport().set_input_as_handled()

func _set_building(enabled: bool) -> void:
	if player == null or ground == null:
		return
	if enabled:
		previous_controls = bool(player.get("controls_enabled"))
	player.call("set_controls_enabled", false if enabled else previous_controls)
	building = enabled
	panel.visible = enabled
	hint.visible = not enabled
	ghost.visible = enabled
	last_button = 0
	if not enabled:
		ghost.hide()

func _process(_delta: float) -> void:
	if not building:
		return
	var layer := walls if selected_layer == 0 else roof
	var cell := layer.local_to_map(layer.get_local_mouse_position())
	var over_panel := panel.get_global_rect().has_point(get_viewport().get_mouse_position())
	ghost.visible = not over_panel
	ghost.global_position = layer.to_global(layer.map_to_local(cell))
	var valid := _can_place(cell, selected_layer)
	ghost.modulate = Color(1, 1, 1, 0.65) if valid else Color(1, 0.25, 0.25, 0.6)
	var button := 1 if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) else 2 if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) else 0
	if button == 0 or over_panel:
		last_button = 0
		return
	if cell == last_cell and button == last_button:
		return
	last_cell = cell
	last_button = button
	if button == 1 and not valid:
		status.text = "Use chão livre; evite objetos e jogador."
		return
	_edit_cell(cell, button == 2)

func _can_place(cell: Vector2i, layer_id: int) -> bool:
	var center := walls.to_global(walls.map_to_local(cell))
	var ground_cell := ground.local_to_map(ground.to_local(center))
	if ground.get_cell_source_id(ground_cell) == -1:
		return false
	if layer_id == 1:
		return true
	var shape := RectangleShape2D.new()
	shape.size = Vector2(14, 14)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, center)
	query.collision_mask = 3
	if blockers.has(cell):
		query.exclude = [blockers[cell].get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func _edit_cell(cell: Vector2i, erase: bool) -> void:
	var layer := walls if selected_layer == 0 else roof
	var old_source := layer.get_cell_source_id(cell)
	var old_atlas := layer.get_cell_atlas_coords(cell)
	if erase and old_source == -1:
		return
	if not erase and old_source == selected_source and old_atlas == selected_atlas:
		return
	if not erase and old_source == -1 and walls.get_used_cells().size() + roof.get_used_cells().size() >= MAX_CELLS:
		status.text = "Limite de peças atingido."
		return
	history.append({"cell": cell, "layer": selected_layer, "source": old_source, "atlas": old_atlas})
	if history.size() > 256:
		history.pop_front()
	layer.set_cell(cell, -1 if erase else selected_source, Vector2i(-1, -1) if erase else selected_atlas)
	if selected_layer == 0:
		_update_blocker(cell, not erase)
	status.text = "Alterado. Clique Salvar para guardar."

func _update_blocker(cell: Vector2i, occupied: bool) -> void:
	if blockers.has(cell):
		var old: StaticBody2D = blockers[cell]
		old.collision_layer = 0
		old.queue_free()
		blockers.erase(cell)
	if not occupied:
		return
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
	blockers[cell] = body

func _undo() -> void:
	if history.is_empty():
		return
	var edit: Dictionary = history.back()
	if int(edit.layer) == 0 and int(edit.source) != -1 and not _can_place(edit.cell, 0):
		status.text = "Libere o espaço antes de desfazer."
		return
	history.pop_back()
	var layer := walls if int(edit.layer) == 0 else roof
	layer.set_cell(edit.cell, edit.source, edit.atlas)
	if int(edit.layer) == 0:
		_update_blocker(edit.cell, int(edit.source) != -1)
	status.text = "Última peça desfeita."

func _toggle_roof() -> void:
	roof.visible = not roof.visible

func _save_house() -> void:
	var cells: Array[Dictionary] = []
	for layer_id in range(2):
		var layer := walls if layer_id == 0 else roof
		for cell in layer.get_used_cells():
			var atlas := layer.get_cell_atlas_coords(cell)
			cells.append({"x": cell.x, "y": cell.y, "layer": layer_id, "source": layer.get_cell_source_id(cell), "ax": atlas.x, "ay": atlas.y})
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
	status.text = "Casa salva neste computador." if error == OK else "Falha ao salvar; arquivo anterior preservado."

func _load_house() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		status.text = "Ainda não há casa salva."
		return
	if FileAccess.get_file_as_bytes(SAVE_PATH).size() > 1048576:
		status.text = "Arquivo de casa inválido."
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary or data.get("version") != 1 or not data.get("cells") is Array:
		status.text = "Arquivo de casa inválido."
		return
	if data.cells.size() > MAX_CELLS:
		status.text = "Arquivo excede o limite de peças."
		return
	var seen: Dictionary = {}
	for entry in data.cells:
		if not entry is Dictionary:
			status.text = "Peça inválida no arquivo."
			return
		for key in ["x", "y", "layer", "source", "ax", "ay"]:
			if not entry.has(key) or not (entry[key] is float or entry[key] is int) or float(entry[key]) != floorf(float(entry[key])) or absf(float(entry[key])) > 4096:
				status.text = "Coordenada inválida."
				return
		var layer_id := int(entry.layer)
		if layer_id != 0 and layer_id != 1:
			status.text = "Camada inválida."
			return
		var tiles: TileSet = wall_tiles if layer_id == 0 else roof_tiles
		var source_id := int(entry.source)
		if not tiles.has_source(source_id) or not tiles.get_source(source_id).has_tile(Vector2i(int(entry.ax), int(entry.ay))):
			status.text = "Peça não existe no TileSet."
			return
		var cell := Vector2i(int(entry.x), int(entry.y))
		var key := "%s:%s:%s" % [layer_id, cell.x, cell.y]
		if seen.has(key) or not _can_place(cell, layer_id):
			status.text = "Casa inválida ou espaço ocupado."
			return
		seen[key] = true
	walls.clear()
	roof.clear()
	for cell in blockers.keys():
		_update_blocker(cell, false)
	for entry in data.cells:
		var cell := Vector2i(int(entry.x), int(entry.y))
		var layer := walls if int(entry.layer) == 0 else roof
		layer.set_cell(cell, int(entry.source), Vector2i(int(entry.ax), int(entry.ay)))
		if int(entry.layer) == 0:
			_update_blocker(cell, true)
	history.clear()
	status.text = "Casa carregada."
