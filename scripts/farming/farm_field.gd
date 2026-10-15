extends Node2D
## Cultivo experimental conectado ao inventario de ferramentas.
## Crescimento por dias de jogo com sprites reais das flores.

const FIELD := Rect2(320.0, 416.0, 320.0, 224.0)
const CELL_SIZE := 32
const COLUMNS := 10
const ROWS := 7
const DAYS_PER_STAGE := 3
const SAVE_PATH := "user://slimekeepers_farm_v1.json"

@export var player_path: NodePath

var _cells: Dictionary = {}
var _seeds := 12
var _harvested := 0
var _message := "Vá até o canteiro para começar a plantar."
var _crop_nodes: Dictionary = {}

const FLOWER_SCENES = [
	preload("res://scenes/objects/flowers/flower_blue.tscn"),
	preload("res://scenes/objects/flowers/flower_light_blue.tscn"),
	preload("res://scenes/objects/flowers/flower_light_yellow.tscn"),
	preload("res://scenes/objects/flowers/flower_pink.tscn"),
	preload("res://scenes/objects/flowers/flower_purple.tscn"),
	preload("res://scenes/objects/flowers/flower_yellow.tscn")
]
var _hud: Label


func _ready() -> void:
	_load_progress()
	GameCalendar.day_changed.connect(_on_day_changed)
	_on_day_changed(GameCalendar.day)
	_sync_crop_sprites()
	_create_hud()
	var player := get_node_or_null(player_path)
	if player == null or not player.has_signal("tool_action_requested"):
		push_warning("FarmField: Player ou sinal tool_action_requested nao encontrado.")
	else:
		player.connect("tool_action_requested", Callable(self, "_on_tool_action"))
	_refresh_hud()
	queue_redraw()


func _on_day_changed(new_day: int) -> void:
	var needs_save := false
	var stages_changed := false
	for coord in _cells.keys():
		var cell: Dictionary = _cells[coord]
		if not cell.get("seeded", false) or not cell.get("watered", false):
			continue
		var last_day := int(cell.get("last_day", new_day))
		var passed := maxi(0, new_day - last_day)
		if passed == 0:
			continue
		cell["growth_days"] = int(cell.get("growth_days", 0)) + passed
		cell["last_day"] = new_day
		var new_stage := mini(3, floori(float(cell["growth_days"]) / float(DAYS_PER_STAGE)))
		if new_stage != int(cell.get("stage", 0)):
			cell["stage"] = new_stage
			stages_changed = true
		_cells[coord] = cell
		needs_save = true
	if needs_save:
		_save_progress()
	if stages_changed:
		_sync_crop_sprites(true)
		queue_redraw()
		_refresh_hud()


func _sync_crop_sprites(animate: bool = false) -> void:
	for coord in _crop_nodes.keys():
		if not _cells.has(coord) or not _cells[coord].get("seeded", false):
			var old_crop = _crop_nodes[coord]
			if is_instance_valid(old_crop):
				old_crop.queue_free()
			_crop_nodes.erase(coord)
	for coord in _cells.keys():
		var cell: Dictionary = _cells[coord]
		if not cell.get("seeded", false):
			continue
		var crop: Node2D
		if _crop_nodes.has(coord):
			crop = _crop_nodes[coord] as Node2D
		else:
			var plant_index := posmod(coord.x + coord.y * 7, FLOWER_SCENES.size())
			crop = FLOWER_SCENES[plant_index].instantiate() as Node2D
			crop.set("use_calendar", false)
			crop.position = FIELD.position + Vector2(coord.x * CELL_SIZE + 16, coord.y * CELL_SIZE + 18)
			add_child(crop)
			_crop_nodes[coord] = crop
		if is_instance_valid(crop):
			crop.call("set_growth_level", int(cell.get("stage", 0)) + 1, animate)


func _max_crop_stage(coord: Vector2i) -> int:
	if _crop_nodes.has(coord):
		var crop = _crop_nodes[coord]
		if is_instance_valid(crop) and crop.has_method("get_max_level"):
			return maxi(1, int(crop.call("get_max_level")) - 1)
	return 3


func _on_tool_action(tool_id: StringName, world_point: Vector2) -> void:
	if tool_id != &"hoe" and tool_id != &"watering_can":
		return
	var target := to_local(world_point)
	if not FIELD.has_point(target):
		_message = "Aponte dentro do canteiro."
		_refresh_hud()
		return
	var coord := Vector2i(
		floori((target.x - FIELD.position.x) / CELL_SIZE),
		floori((target.y - FIELD.position.y) / CELL_SIZE)
	)
	if coord.x < 0 or coord.x >= COLUMNS or coord.y < 0 or coord.y >= ROWS:
		return
	var cell: Dictionary = _cells.get(coord, {})
	var changed := false
	if tool_id == &"hoe":
		if cell.is_empty():
			_cells[coord] = {"tilled": true, "seeded": false, "watered": false, "stage": 0, "growth_days": 0, "last_day": GameCalendar.day}
			_message = "Solo preparado! Use a enxada novamente para plantar."
			changed = true
		elif not cell.get("seeded", false):
			if _seeds <= 0:
				_message = "Sem sementes. Colha uma planta para recuperar uma."
			else:
				cell["seeded"] = true
				cell["watered"] = false
				cell["stage"] = 0
				cell["growth_days"] = 0
				cell["last_day"] = GameCalendar.day
				_cells[coord] = cell
				_seeds -= 1
				_message = "Semente plantada! Equipe o regador (1)."
				changed = true
		elif int(cell.get("stage", 0)) >= _max_crop_stage(coord):
			cell["seeded"] = false
			cell["watered"] = false
			cell["stage"] = 0
			cell["growth_days"] = 0
			cell["last_day"] = GameCalendar.day
			_cells[coord] = cell
			_seeds += 1
			_harvested += 1
			_message = "Colhido! Uma semente recuperada."
			changed = true
		else:
			_message = "Ainda crescendo. Aguarde a maturidade ou regue."
	elif tool_id == &"watering_can":
		if cell.is_empty() or not cell.get("seeded", false):
			_message = "Plante primeiro usando a enxada (3)."
		elif cell.get("watered", false):
			_message = "Esta planta ja esta regada."
		else:
			cell["watered"] = true
			cell["last_day"] = GameCalendar.day
			_cells[coord] = cell
			_message = "Regado! +1 fase a cada 3 dias de jogo."
			changed = true
	if changed:
		_save_progress()
		_sync_crop_sprites()
		queue_redraw()
	_refresh_hud()


func _draw() -> void:
	for coord in _cells.keys():
		var cell: Dictionary = _cells[coord]
		var point := FIELD.position + Vector2(coord.x * CELL_SIZE, coord.y * CELL_SIZE)
		draw_rect(Rect2(point + Vector2(1, 1), Vector2(30, 30)), Color("#654530"))
		draw_rect(Rect2(point + Vector2(3, 26), Vector2(26, 2)), Color("#3f3024"))
		if cell.get("watered", false):
			draw_circle(point + Vector2(26, 25), 2.0, Color("#85d5ed"))


func _create_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "FarmingHUD"
	layer.layer = 10
	add_child(layer)
	_hud = Label.new()
	# Interface no canto superior direito: nao disputar espaco com o calendario.
	_hud.anchor_left = 1.0
	_hud.anchor_right = 1.0
	_hud.offset_left = -310.0
	_hud.offset_right = -8.0
	_hud.offset_top = 8.0
	_hud.offset_bottom = 72.0
	_hud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hud.add_theme_font_size_override("font_size", 10)
	_hud.add_theme_constant_override("outline_size", 3)
	_hud.add_theme_color_override("font_outline_color", Color("#173022"))
	layer.add_child(_hud)


func _refresh_hud() -> void:
	if _hud == null:
		return
	var objective := "OBJETIVO: colher 3 plantas (%d/3)" % mini(_harvested, 3)
	if _harvested >= 3:
		objective = "OBJETIVO CONCLUIDO! Proximo passo: conhecer um slime."
	_hud.text = "CULTIVO | Sementes: %d | Colhidas: %d\n" % [_seeds, _harvested] + \
		"3 Enxada | 1 Regador | F / clique\n" + \
		"%s\n%s" % [objective, _message]


func _save_progress() -> void:
	var stored_cells: Array[Dictionary] = []
	for coord in _cells.keys():
		var cell: Dictionary = _cells[coord]
		stored_cells.append({
			"x": coord.x,
			"y": coord.y,
			"seeded": bool(cell.get("seeded", false)),
			"watered": bool(cell.get("watered", false)),
			"stage": int(cell.get("stage", 0)),
			"growth_days": int(cell.get("growth_days", 0)),
			"last_day": int(cell.get("last_day", GameCalendar.day))
		})
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("FarmField: não foi possível salvar a fazenda.")
		return
	file.store_string(JSON.stringify({
		"version": 2,
		"seeds": _seeds,
		"harvested": _harvested,
		"cells": stored_cells
	}))


func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not parsed is Dictionary or int(parsed.get("version", 0)) not in [1, 2]:
		push_warning("FarmField: save incompatível, iniciando canteiro novo.")
		return
	_seeds = maxi(0, int(parsed.get("seeds", 12)))
	_harvested = maxi(0, int(parsed.get("harvested", 0)))
	var entries = parsed.get("cells", [])
	if not entries is Array:
		return
	for entry in entries:
		if not entry is Dictionary:
			continue
		var coord := Vector2i(int(entry.get("x", -1)), int(entry.get("y", -1)))
		if coord.x < 0 or coord.y < 0 or coord.x >= COLUMNS or coord.y >= ROWS:
			continue
		_cells[coord] = {
			"tilled": true,
			"seeded": bool(entry.get("seeded", false)),
			"watered": bool(entry.get("watered", false)),
			"stage": clampi(int(entry.get("stage", 0)), 0, 3),
			"growth_days": int(entry.get("growth_days", int(entry.get("stage", 0)) * DAYS_PER_STAGE)),
			"last_day": int(entry.get("last_day", GameCalendar.day))
		}


func _exit_tree() -> void:
	_save_progress()
