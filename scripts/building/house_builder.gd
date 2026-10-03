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
var pending_stamp_button := 0
var automatic := true
var house_width := 5
var roof_height := 5
var house_rects: Array[Rect2i] = []
var stamp_preview: Node2D
var preview_plan: Array[Dictionary] = []
var preview_valid := false
var palette_scroll: ScrollContainer
var size_controls: VBoxContainer

func _ready() -> void:
	walls.tile_set = wall_tiles
	roof.tile_set = roof_tiles
	_build_ui()
	_select_layer(0)
	palette_scroll.hide()
	stamp_preview = Node2D.new()
	stamp_preview.z_index = 30
	stamp_preview.draw.connect(_draw_stamp_preview)
	add_child(stamp_preview)
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
	var mode := HBoxContainer.new()
	box.add_child(mode)
	_button(mode, "Casa automática", _set_automatic.bind(true))
	_button(mode, "Peças", _set_automatic.bind(false))
	size_controls = VBoxContainer.new()
	box.add_child(size_controls)
	var width_row := HBoxContainer.new()
	size_controls.add_child(width_row)
	var height_row := HBoxContainer.new()
	size_controls.add_child(height_row)
	var width_label := Label.new()
	width_label.text = "Largura"
	width_row.add_child(width_label)
	var width := SpinBox.new()
	width.min_value = 3
	width.max_value = 12
	width.value = house_width
	width.value_changed.connect(_set_width)
	width_row.add_child(width)
	var height_label := Label.new()
	height_label.text = "Telhado"
	height_row.add_child(height_label)
	var height := SpinBox.new()
	height.min_value = 5
	height.max_value = 9
	height.step = 2
	height.value = roof_height
	height.value_changed.connect(_set_roof_height)
	height_row.add_child(height)
	var categories := HBoxContainer.new()
	box.add_child(categories)
	_button(categories, "Paredes", _select_layer.bind(0))
	_button(categories, "Telhado", _select_layer.bind(1))
	var scroll := ScrollContainer.new()
	palette_scroll = scroll
	scroll.custom_minimum_size = Vector2(200, 100)
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
	status.text = "Clique no chão para construir a casa."
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.x = 200
	box.add_child(status)
	var help := Label.new()
	help.text = "Esquerdo: construir / colocar\nDireito: remover\nB / Esc: sair"
	box.add_child(help)

func _button(parent: Node, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	parent.add_child(button)

func _select_layer(layer: int) -> void:
	selected_layer = layer
	if building:
		_set_automatic(false)
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
	pending_stamp_button = 0
	building = enabled
	panel.visible = enabled
	hint.visible = not enabled
	ghost.visible = enabled and not automatic
	last_button = 0
	if not enabled:
		ghost.hide()
		preview_plan.clear()
		stamp_preview.queue_redraw()

func _process(_delta: float) -> void:
	if not building:
		return
	if automatic:
		_process_automatic()
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
	if occupied and walls.get_cell_atlas_coords(cell) == Vector2i(3, 2):
		occupied = false
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
	if edit.has("batch"):
		for previous in edit.batch:
			if int(previous.layer) == 0 and int(previous.source) != -1 and not _can_place(previous.cell, 0):
				status.text = "Libere o espaço antes de desfazer."
				return
		history.pop_back()
		for previous in edit.batch:
			var target := walls if int(previous.layer) == 0 else roof
			target.set_cell(previous.cell, previous.source, previous.atlas)
			if int(previous.layer) == 0:
				_update_blocker(previous.cell, int(previous.source) != -1)
		house_rects.clear()
		for rect in edit.rects:
			house_rects.append(rect)
		status.text = "Construção desfeita."
		return
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
	var rectangles: Array[Dictionary] = []
	for rect in house_rects:
		rectangles.append({"x": rect.position.x, "y": rect.position.y, "w": rect.size.x, "h": rect.size.y})
	file.store_string(JSON.stringify({"version": 1, "cells": cells, "houses": rectangles}))
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
	var loaded_rects: Array[Rect2i] = []
	var records: Variant = data.get("houses", [])
	if not records is Array or records.size() > MAX_CELLS:
		status.text = "Lista de casas inválida."
		return
	for record in records:
		if not record is Dictionary:
			status.text = "Casa inválida."
			return
		for key in ["x", "y", "w", "h"]:
			if not record.has(key) or not (record[key] is float or record[key] is int) or float(record[key]) != floorf(float(record[key])) or absf(float(record[key])) > 4096:
				status.text = "Dimensões de casa inválidas."
				return
		if int(record.w) < 3 or int(record.w) > 12 or int(record.h) < 7 or int(record.h) > 11:
			status.text = "Dimensões de casa inválidas."
			return
		loaded_rects.append(Rect2i(int(record.x), int(record.y), int(record.w), int(record.h)))
	house_rects = loaded_rects
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


func _set_automatic(enabled: bool) -> void:
	pending_stamp_button = 0
	automatic = enabled
	palette_scroll.visible = not enabled
	size_controls.visible = enabled
	ghost.visible = building and not enabled
	preview_plan.clear()
	if is_instance_valid(stamp_preview):
		stamp_preview.queue_redraw()
	status.text = "Clique para construir a casa inteira." if enabled else "Escolha uma peça para editar."
	last_button = 0

func _set_width(value: float) -> void:
	house_width = int(value)

func _set_roof_height(value: float) -> void:
	roof_height = int(value)

func _house_plan(origin: Vector2i) -> Array[Dictionary]:
	var plan: Array[Dictionary] = []
	var wall_source := wall_tiles.get_source_id(0)
	var roof_source := roof_tiles.get_source_id(0)
	var ridge := floori(roof_height / 2.0)
	for y in range(roof_height):
		var atlas_y := 0 if y == 0 else 4 if y == roof_height - 1 else 2 if y == int(ridge) else 1 if y < int(ridge) else 3
		for x in range(house_width):
			var atlas_x := 0 if x == 0 else 2 if x == house_width - 1 else 1
			plan.append({"cell": origin + Vector2i(x, y), "layer": 1, "source": roof_source, "atlas": Vector2i(atlas_x, atlas_y), "solid": false})
	for y in range(3):
		for x in range(house_width):
			var atlas_x := 0 if x == 0 else 2 if x == house_width - 1 else 1
			var door := y == 2 and x == floori(house_width / 2.0)
			var atlas := Vector2i(3, 2) if door else Vector2i(atlas_x, y)
			plan.append({"cell": origin + Vector2i(x, roof_height - 1 + y), "layer": 0, "source": wall_source, "atlas": atlas, "solid": not door})
	return plan

func _plan_valid(plan: Array[Dictionary]) -> bool:
	if plan.size() + walls.get_used_cells().size() + roof.get_used_cells().size() > MAX_CELLS:
		return false
	for piece in plan:
		var target := walls if int(piece.layer) == 0 else roof
		if target.get_cell_source_id(piece.cell) != -1 or not _can_place(piece.cell, 0):
			return false
	return true

func _process_automatic() -> void:
	ghost.hide()
	var over_panel := panel.get_global_rect().has_point(get_viewport().get_mouse_position())
	var cell := walls.local_to_map(walls.get_local_mouse_position())
	preview_plan.clear()
	if not over_panel:
		preview_plan = _house_plan(cell)
		preview_valid = _plan_valid(preview_plan)
	stamp_preview.queue_redraw()
	if over_panel:
		pending_stamp_button = 0
		return
	var pressed := pending_stamp_button
	pending_stamp_button = 0
	if pressed == MOUSE_BUTTON_LEFT:
		if not preview_valid:
			status.text = "A casa precisa de chão livre em toda a área."
			return
		_place_house(cell, preview_plan)
	elif pressed == MOUSE_BUTTON_RIGHT:
		_remove_house(cell)

func _draw_stamp_preview() -> void:
	if not building or not automatic:
		return
	var tint := Color(1, 1, 1, 0.55) if preview_valid else Color(1, 0.3, 0.3, 0.55)
	# Draw the walls first, so the roof eave covers the top facade row.
	for layer_id in [0, 1]:
		var tiles: TileSet = wall_tiles if layer_id == 0 else roof_tiles
		var source := tiles.get_source(tiles.get_source_id(0)) as TileSetAtlasSource
		for piece in preview_plan:
			if int(piece.layer) != layer_id:
				continue
			var point := stamp_preview.to_local(walls.to_global(walls.map_to_local(piece.cell)))
			stamp_preview.draw_texture_rect_region(source.texture, Rect2(point - Vector2(8, 8), Vector2(16, 16)), source.get_tile_texture_region(piece.atlas), tint)

func _snapshot(plan: Array[Dictionary]) -> Array[Dictionary]:
	var previous: Array[Dictionary] = []
	for piece in plan:
		var target := walls if int(piece.layer) == 0 else roof
		previous.append({"cell": piece.cell, "layer": piece.layer, "source": target.get_cell_source_id(piece.cell), "atlas": target.get_cell_atlas_coords(piece.cell)})
	return previous

func _place_house(origin: Vector2i, plan: Array[Dictionary]) -> void:
	history.append({"batch": _snapshot(plan), "rects": house_rects.duplicate()})
	if history.size() > 256:
		history.pop_front()
	for piece in plan:
		var target := walls if int(piece.layer) == 0 else roof
		target.set_cell(piece.cell, piece.source, piece.atlas)
		if int(piece.layer) == 0:
			_update_blocker(piece.cell, bool(piece.solid))
	house_rects.append(Rect2i(origin, Vector2i(house_width, roof_height + 2)))
	status.text = "Casa construída. Clique Salvar para guardar."

func _remove_house(cell: Vector2i) -> void:
	for index in range(house_rects.size()):
		var rect := house_rects[index]
		if not rect.has_point(cell):
			continue
		var plan: Array[Dictionary] = []
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				for layer_id in range(2):
					plan.append({"cell": Vector2i(x, y), "layer": layer_id})
		history.append({"batch": _snapshot(plan), "rects": house_rects.duplicate()})
		if history.size() > 256:
			history.pop_front()
		for piece in plan:
			var target := walls if int(piece.layer) == 0 else roof
			target.erase_cell(piece.cell)
			if int(piece.layer) == 0:
				_update_blocker(piece.cell, false)
		house_rects.remove_at(index)
		status.text = "Casa removida. Desfazer restaura."
		return
	status.text = "Clique em uma casa automática para remover."


func _input(event: InputEvent) -> void:
	if building and automatic and event is InputEventMouseButton and event.pressed:
		pending_stamp_button = event.button_index
