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

var roof_underlay: TileMapLayer
var wall_cells: Dictionary = {}
var roof_cells: Dictionary = {}
var brush := "Piso"
var floor_layer: TileMapLayer
var manually_hide_roof := false
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
	floor_layer = TileMapLayer.new()
	floor_layer.name = "InteriorFloor"
	floor_layer.tile_set = wall_tiles
	floor_layer.position = roof.position
	floor_layer.z_index = 4
	floor_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(floor_layer)
	roof.position = floor_layer.position
	walls.tile_set = wall_tiles
	_make_roof_terrain()
	var texture := AtlasTexture.new()
	texture.atlas = terrain_source.texture
	texture.region = Rect2(16, 16, 16, 16)
	texture.filter_clip = true
	ghost.texture = texture
	_build_ui()
	ghost.hide()

func _make_roof_terrain() -> void:
	roof.tile_set = roof_tiles
	roof_underlay = TileMapLayer.new()
	roof_underlay.name = "CornerBacking"
	roof_underlay.tile_set = roof_tiles
	roof_underlay.z_index = -1
	roof.add_child(roof_underlay)
	roof.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	terrain_source = roof_tiles.get_source(roof_tiles.get_source_id(0)) as TileSetAtlasSource

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
	var brushes := HBoxContainer.new()
	box.add_child(brushes)
	for name in ["Piso", "Parede"]:
		_button(brushes, name, _select_brush.bind(name))
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
	status.text = "Pinte piso e paredes; telhado automático."
	box.add_child(status)
	var help := Label.new()
	help.text = "Esquerdo: pintar / expandir\nDireito: apagar nesta camada\nB / Esc: sair"
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
	_update_roof_visibility()
	if not building:
		return
	cursor = floor_layer.local_to_map(floor_layer.get_local_mouse_position())
	var over_panel := panel.get_global_rect().has_point(get_viewport().get_mouse_position())
	ghost.visible = not over_panel
	ghost.global_position = floor_layer.to_global(floor_layer.map_to_local(cursor))
	var selected := _selected_cells()
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
		if selected.has(cursor):
			return
		if not reason.is_empty():
			status.text = reason
			return
		_remember()
		selected[cursor] = true
	else:
		if not selected.has(cursor):
			return
		_remember()
		selected.erase(cursor)
	_rebuild()
	status.text = "%s atualizado. Salve para guardar." % brush

func _selected_cells() -> Dictionary:
	if brush == "Parede":
		return wall_cells
	if brush == "Telhado":
		return roof_cells
	return footprint

func _select_brush(name: String) -> void:
	brush = name
	last_button = 0
	status.text = "Pintando: %s" % name
	var texture := ghost.texture as AtlasTexture
	texture.atlas = terrain_source.texture if name == "Telhado" else (wall_tiles.get_source(wall_tiles.get_source_id(0)) as TileSetAtlasSource).texture
	texture.region = Rect2(16, 16 if name != "Telhado" else 0, 16, 16)
	_update_roof_visibility()

func _add_reason(cell: Vector2i) -> String:
	if _selected_cells().has(cell):
		return ""
	if brush == "Piso" and footprint.size() >= material_limit:
		return "Materiais esgotados: limite de %d células de piso." % material_limit
	if brush == "Piso" and not footprint.is_empty():
		var connected := false
		for direction in DIRECTIONS:
			connected = connected or footprint.has(cell + direction)
		if not connected:
			return "Expanda o piso ao lado da casa."
	if brush != "Piso" and not _supported(cell, brush):
		return "Pinte %s junto do piso da casa." % brush.to_lower()
	var point := floor_layer.to_global(floor_layer.map_to_local(cell))
	if ground.get_cell_source_id(ground.local_to_map(ground.to_local(point))) == -1:
		return "Pinte sobre o solo."
	if brush == "Parede":
		var shape := RectangleShape2D.new()
		shape.size = Vector2(16, 16)
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = shape
		query.transform = Transform2D(0, point)
		query.collision_mask = 2
		if not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
			return "Não coloque uma parede sobre o jogador."
	return ""

func _supported(cell: Vector2i, layer: String) -> bool:
	var vertical := 2 if layer == "Telhado" else 1
	for y in range(-vertical, vertical + 1):
		for x in range(-1, 2):
			if footprint.has(cell + Vector2i(x, y)):
				return true
	return false

func _wall_atlas(cell: Vector2i) -> Vector2i:
	var left := wall_cells.has(cell + Vector2i.LEFT)
	var right := wall_cells.has(cell + Vector2i.RIGHT)
	var up := wall_cells.has(cell + Vector2i.UP)
	var down := wall_cells.has(cell + Vector2i.DOWN)
	var inner_left := footprint.has(cell + Vector2i.LEFT)
	var inner_right := footprint.has(cell + Vector2i.RIGHT)
	# Concave corners: horizontal and vertical walls meet around the floor.
	if up and left and footprint.has(cell + Vector2i(1, 1)) and not inner_left:
		return Vector2i(2, 2)
	if up and right and footprint.has(cell + Vector2i(-1, 1)) and not inner_right:
		return Vector2i(0, 2)
	if down and left and footprint.has(cell + Vector2i(1, -1)) and not inner_left:
		return Vector2i(2, 0)
	if down and right and footprint.has(cell + Vector2i(-1, -1)) and not inner_right:
		return Vector2i(0, 0)
	var x := 2 if inner_left and not inner_right else 0
	if up or down:
		if right and not left:
			return Vector2i(0, 0 if down else 2)
		if left and not right:
			return Vector2i(2, 0 if down else 2)
		return Vector2i(x, 1)
	return Vector2i(1, 2 if footprint.has(cell + Vector2i.UP) else 0)

func _roof_atlas(cell: Vector2i, ridge: int) -> Vector2i:
	var left := roof_cells.has(cell + Vector2i.LEFT)
	var right := roof_cells.has(cell + Vector2i.RIGHT)
	var up := roof_cells.has(cell + Vector2i.UP)
	var down := roof_cells.has(cell + Vector2i.DOWN)
	if up and left and not roof_cells.has(cell + Vector2i(-1, -1)):
		return Vector2i(3, 0)
	if up and right and not roof_cells.has(cell + Vector2i(1, -1)):
		return Vector2i(4, 0)
	if down and left and not roof_cells.has(cell + Vector2i(-1, 1)):
		return Vector2i(3, 1)
	if down and right and not roof_cells.has(cell + Vector2i(1, 1)):
		return Vector2i(4, 1)
	var x := 0 if not left else 2 if not right else 1
	var y := 0 if not up else 4 if not down else 2 if cell.y == ridge else 1 if cell.y < ridge else 3
	return Vector2i(x, y)

func _rebuild() -> void:
	# Remove orphan pieces when shrinking the floor or loading an old test.
	for cell in wall_cells.keys():
		if not _supported(cell, "Parede"):
			wall_cells.erase(cell)
	# Coverage is derived; it never needs a roof brush or extra materials.
	roof_cells = footprint.duplicate()
	for cell in wall_cells:
		roof_cells[cell] = true
	roof.clear()
	roof_underlay.clear()
	for child in roof.get_children():
		if child != roof_underlay:
			roof.remove_child(child)
			child.queue_free()
	walls.clear()
	floor_layer.clear()
	for body in bodies:
		body.collision_layer = 0
		body.queue_free()
	bodies.clear()
	var wall_source := wall_tiles.get_source_id(0)
	for cell in footprint:
		floor_layer.set_cell(cell, wall_source, Vector2i(1, 1))
	for key in wall_cells:
		var cell: Vector2i = key
		walls.set_cell(cell, wall_source, _wall_atlas(cell))
		_add_block(cell)
	# Original five rows: top edge, upper slope, ridge, lower slope, bottom edge.
	# A single ridge spans the painted roof, rather than repeating every tile.
	if not roof_cells.is_empty():
		var min_y := 2147483647
		var max_y := -2147483647
		for cell in roof_cells:
			min_y = mini(min_y, cell.y)
			max_y = maxi(max_y, cell.y)
		var ridge := floori((min_y + max_y) / 2.0)
		for key in roof_cells:
			var cell: Vector2i = key
			var atlas := _roof_atlas(cell, ridge)
			if atlas.x >= 3:
				# Junction pieces contain transparent pixels; preserve the slope
				# beneath them instead of exposing the floor through the roof.
				var slope := 2 if cell.y == ridge else 1 if cell.y < ridge else 3
				roof_underlay.set_cell(cell, roof_tiles.get_source_id(0), Vector2i(1, slope))
			roof.set_cell(cell, roof_tiles.get_source_id(0), atlas)
			_add_roof_overhang(cell, atlas)
	_update_roof_visibility()
	_refresh_balance()

func _add_roof_overhang(cell: Vector2i, atlas: Vector2i) -> void:
	# Exactly one screen-world pixel outside the upper/lower wall boundary.
	# The atlas top edge includes transparent padding; use its first opaque
	# pixel row to keep the extension visible without stretching the roof.
	var source_image := terrain_source.texture.get_image()
	for direction in [Vector2i.UP, Vector2i.DOWN]:
		if roof_cells.has(cell + direction):
			continue
		var row := 0 if direction == Vector2i.UP else 15
		var step := 1 if direction == Vector2i.UP else -1
		for candidate in range(16):
			var test_row := candidate if step == 1 else 15 - candidate
			var opaque := false
			for x in range(16):
				if source_image.get_pixel(atlas.x * 16 + x, atlas.y * 16 + test_row).a > 0.0:
					opaque = true
					break
			if opaque:
				row = test_row
				break
		var texture := AtlasTexture.new()
		texture.atlas = terrain_source.texture
		texture.region = Rect2(atlas.x * 16, atlas.y * 16 + row, 16, 1)
		texture.filter_clip = true
		var edge := Sprite2D.new()
		edge.texture = texture
		edge.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		edge.position = roof.map_to_local(cell) + Vector2(0, direction.y * 8.5)
		roof.add_child(edge)

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
	history.append({"floor": footprint.duplicate(), "walls": wall_cells.duplicate(), "roof": roof_cells.duplicate()})
	if history.size() > 100:
		history.pop_front()

func _undo() -> void:
	if history.is_empty():
		return
	var previous: Dictionary = history.pop_back()
	footprint = previous.floor
	wall_cells = previous.walls
	roof_cells = previous.roof
	_rebuild()
	status.text = "Última pintura desfeita."

func _toggle_roof() -> void:
	manually_hide_roof = not manually_hide_roof
	_update_roof_visibility()

func _update_roof_visibility() -> void:
	var cell := floor_layer.local_to_map(floor_layer.to_local(player.global_position))
	var inside := footprint.has(cell) and not wall_cells.has(cell)
	roof.visible = not manually_hide_roof and (not building and not inside)

func _refresh_balance() -> void:
	balance.text = "Piso: %d / %d materiais livres" % [material_limit - footprint.size(), material_limit]

func _encode_cells(cells: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for cell in cells:
		result.append({"x": cell.x, "y": cell.y})
	return result

func _save_house() -> void:
	var file := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		status.text = "Não foi possível salvar."
		return
	file.store_string(JSON.stringify({"version": 2, "floor": _encode_cells(footprint), "walls": _encode_cells(wall_cells), "roof": []}))
	file.flush()
	var error := file.get_error()
	file.close()
	if error == OK:
		error = DirAccess.rename_absolute(SAVE_PATH + ".tmp", SAVE_PATH)
	status.text = "Três camadas salvas." if error == OK else "Falha ao salvar."

func _load_house() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		status.text = "Ainda não há casa salva."
		return
	if FileAccess.get_file_as_bytes(SAVE_PATH).size() > 65536:
		status.text = "Arquivo inválido."
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary or data.get("version") != 2:
		status.text = "Save antigo: redesenhe nas três camadas."
		return
	var decoded: Dictionary = {}
	for name in ["floor", "walls", "roof"]:
		if not data.get(name) is Array or data[name].size() > 1024:
			status.text = "Camada inválida."
			return
		var cells: Dictionary = {}
		for entry in data[name]:
			if not entry is Dictionary:
				return
			for axis in ["x", "y"]:
				if not entry.get(axis) is float and not entry.get(axis) is int:
					return
				if not is_finite(float(entry[axis])) or float(entry[axis]) != floorf(float(entry[axis])) or absf(float(entry[axis])) > 4096:
					return
			cells[Vector2i(int(entry.x), int(entry.y))] = true
		decoded[name] = cells
	if decoded.floor.size() > material_limit:
		status.text = "Piso ultrapassa o limite de materiais."
		return
	for cell in decoded.walls:
		var player_cell := floor_layer.local_to_map(floor_layer.to_local(player.global_position))
		if cell == player_cell:
			status.text = "Afaste o jogador da parede salva."
			return
	footprint = decoded.floor
	wall_cells = decoded.walls
	roof_cells = decoded.roof
	history.clear()
	_rebuild()
	status.text = "Três camadas carregadas."
