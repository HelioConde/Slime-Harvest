extends Node2D
## First playable farming loop for the temporary World.tscn test map.
## Crops are drawn programmatically until final artwork is integrated.

const FIELD := Rect2(320.0, 416.0, 320.0, 224.0)
const CELL_SIZE := 32
const COLUMNS := 10
const ROWS := 7
const STAGE_SECONDS := 12.0
const SAVE_PATH := "user://slimekeepers_farm_v1.json"

enum Tool { HOE, SEED, WATER, HARVEST }

@export var player_path: NodePath

var _selected_tool: Tool = Tool.HOE
var _cells: Dictionary = {}
var _seeds := 12
var _harvested := 0
var _message := "Vá até o canteiro para começar a plantar."
var _hud: Label


func _ready() -> void:
	_load_progress()
	_create_hud()
	var player := get_node_or_null(player_path)
	if player == null or not player.has_signal("tool_use_requested"):
		push_warning("FarmField: Player ou sinal tool_use_requested não encontrado.")
	else:
		player.connect("tool_use_requested", Callable(self, "_on_tool_used"))
	_refresh_hud()
	queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_1:
			_selected_tool = Tool.HOE
		KEY_2:
			_selected_tool = Tool.SEED
		KEY_3:
			_selected_tool = Tool.WATER
		KEY_4:
			_selected_tool = Tool.HARVEST
		_:
			return
	_message = "Ferramenta alterada. Pressione F perto do canteiro."
	_refresh_hud()
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	var changed := false
	for coord in _cells.keys():
		var cell: Dictionary = _cells[coord]
		if not cell.get("seeded", false) or not cell.get("watered", false):
			continue
		if int(cell.get("stage", 0)) >= 3:
			continue
		var elapsed := float(cell.get("elapsed", 0.0)) + delta
		if elapsed < STAGE_SECONDS:
			cell["elapsed"] = elapsed
			_cells[coord] = cell
			continue
		cell["stage"] = mini(3, int(cell.get("stage", 0)) + 1)
		cell["elapsed"] = elapsed - STAGE_SECONDS
		_cells[coord] = cell
		changed = true
	if changed:
		_save_progress()
		queue_redraw()
		_refresh_hud()


func _on_tool_used(origin: Vector2, direction: Vector2) -> void:
	var target := to_local(origin + direction * 16.0)
	if not FIELD.has_point(target):
		_message = "Você precisa mirar dentro do canteiro."
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
	match _selected_tool:
		Tool.HOE:
			if cell.is_empty():
				_cells[coord] = {"tilled": true, "seeded": false, "watered": false, "stage": 0, "elapsed": 0.0}
				_message = "Terra preparada! Use 2 para escolher sementes."
				changed = true
			else:
				_message = "Esta área já foi preparada."
		Tool.SEED:
			if cell.is_empty():
				_message = "Primeiro prepare a terra com a enxada (1)."
			elif cell.get("seeded", false):
				_message = "Já existe uma planta aqui."
			elif _seeds <= 0:
				_message = "Sem sementes. Colha uma planta para recuperar uma."
			else:
				cell["seeded"] = true
				cell["watered"] = false
				cell["stage"] = 0
				cell["elapsed"] = 0.0
				_cells[coord] = cell
				_seeds -= 1
				_message = "Semente plantada! Regue usando 3."
				changed = true
		Tool.WATER:
			if cell.is_empty() or not cell.get("seeded", false):
				_message = "Plante uma semente antes de regar."
			elif cell.get("watered", false):
				_message = "Esta planta já foi regada."
			else:
				cell["watered"] = true
				_cells[coord] = cell
				_message = "Regado! A planta crescerá em três etapas."
				changed = true
		Tool.HARVEST:
			if not cell.get("seeded", false):
				_message = "Não existe planta para colher."
			elif int(cell.get("stage", 0)) < 3:
				_message = "A planta ainda está crescendo."
			else:
				cell["seeded"] = false
				cell["watered"] = false
				cell["stage"] = 0
				cell["elapsed"] = 0.0
				_cells[coord] = cell
				_seeds += 1
				_harvested += 1
				_message = "Colhido! Você recebeu uma semente para replantar."
				changed = true
	if changed:
		_save_progress()
		queue_redraw()
	_refresh_hud()


func _draw() -> void:
	for coord in _cells.keys():
		var cell: Dictionary = _cells[coord]
		var point := FIELD.position + Vector2(coord.x * CELL_SIZE, coord.y * CELL_SIZE)
		draw_rect(Rect2(point + Vector2(1, 1), Vector2(30, 30)), Color("#654530"))
		draw_rect(Rect2(point + Vector2(3, 26), Vector2(26, 2)), Color("#3f3024"))
		if not cell.get("seeded", false):
			continue
		var center := point + Vector2(16, 18)
		var stage := int(cell.get("stage", 0))
		var height := 5.0 + float(stage) * 4.0
		draw_line(center + Vector2(0, 5), center - Vector2(0, height), Color("#428347"), 3)
		draw_circle(center + Vector2(-4, -height * 0.55), 3.0 + stage * 0.8, Color("#67ac56"))
		draw_circle(center + Vector2(4, -height * 0.8), 3.0 + stage * 0.8, Color("#83bf57"))
		if stage >= 3:
			draw_circle(center + Vector2(0, -height + 3), 5.0, Color("#eda950"))
		if cell.get("watered", false):
			draw_circle(point + Vector2(26, 25), 2.0, Color("#85d5ed"))


func _create_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "FarmingHUD"
	layer.layer = 10
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(8, 8)
	_hud.custom_minimum_size = Vector2(620, 0)
	_hud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hud.add_theme_font_size_override("font_size", 12)
	_hud.add_theme_constant_override("outline_size", 3)
	_hud.add_theme_color_override("font_outline_color", Color("#173022"))
	layer.add_child(_hud)


func _refresh_hud() -> void:
	if _hud == null:
		return
	var names := ["Enxada", "Sementes", "Regador", "Colher"]
	var objective := "OBJETIVO: colher 3 plantas (%d/3)" % mini(_harvested, 3)
	if _harvested >= 3:
		objective = "OBJETIVO CONCLUÍDO! Próximo passo: conhecer um slime."
	_hud.text = "SLIMEKEEPERS: LOST VALLEY | Protótipo de cultivo\n" + \
		"1 Enxada  2 Semente  3 Regador  4 Colher  |  F usar: %s\n" % names[_selected_tool] + \
		"Sementes: %d  Colheitas: %d  |  %s\n%s" % [_seeds, _harvested, objective, _message]


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
			"elapsed": float(cell.get("elapsed", 0.0))
		})
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("FarmField: não foi possível salvar a fazenda.")
		return
	file.store_string(JSON.stringify({
		"version": 1,
		"seeds": _seeds,
		"harvested": _harvested,
		"cells": stored_cells
	}))


func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not parsed is Dictionary or int(parsed.get("version", 0)) != 1:
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
			"elapsed": clampf(float(entry.get("elapsed", 0.0)), 0.0, STAGE_SECONDS)
		}


func _exit_tree() -> void:
	_save_progress()
