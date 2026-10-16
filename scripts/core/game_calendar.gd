extends Node
## Calendario global para crescimento das plantas: 1 dia = 10 minutos com o jogo aberto.

signal day_changed(new_day: int)

const SAVE_PATH := "user://slimekeepers_calendar_v1.json"
const SAVE_INTERVAL_SECONDS := 30.0

@export_range(30.0, 3600.0, 1.0) var seconds_per_day: float = 600.0

var day: int = 1
var seconds_into_day: float = 0.0
var _planting_days: Dictionary = {}
var _since_save: float = 0.0
var _day_label: Label


func _ready() -> void:
    _load_calendar()
    _create_day_label()
    _refresh_label()


func _process(delta: float) -> void:
    # Nao avancar dias enquanto a tela inicial estiver aberta.
    var active_scene: Node = get_tree().current_scene
    var is_main_menu: bool = active_scene != null and active_scene.scene_file_path == "res://scenes/ui/MainMenu.tscn"
    var calendar_hud := get_node_or_null("CalendarHUD") as CanvasLayer
    if calendar_hud != null:
        calendar_hud.visible = not is_main_menu
    if is_main_menu:
        return
    if delta <= 0.0:
        return
    seconds_into_day += delta
    _since_save += delta
    var changed := false
    while seconds_into_day >= seconds_per_day:
        seconds_into_day -= seconds_per_day
        day += 1
        day_changed.emit(day)
        changed = true
    if changed:
        _refresh_label()
    if changed or _since_save >= SAVE_INTERVAL_SECONDS:
        _save_calendar()


func _unhandled_key_input(event: InputEvent) -> void:
    # Atalho F9 apenas em execucoes de debug.
    if not OS.is_debug_build():
        return
    var key := event as InputEventKey
    if key == null or not key.pressed or key.echo:
        return
    if key.keycode == KEY_F9:
        advance_days(1)
        get_viewport().set_input_as_handled()


func advance_days(amount: int) -> void:
    for index in range(clampi(amount, 0, 30)):
        day += 1
        day_changed.emit(day)
    _refresh_label()
    _save_calendar()


func get_or_create_planting_day(plant_id: String) -> int:
    if plant_id.is_empty():
        return day
    if _planting_days.has(plant_id):
        return clampi(int(_planting_days[plant_id]), 1, day)
    _planting_days[plant_id] = day
    _save_calendar()
    return day


func replant(plant_id: String) -> int:
    if not plant_id.is_empty():
        _planting_days[plant_id] = day
        _save_calendar()
    return day


func forget_plant(plant_id: String) -> void:
    if _planting_days.erase(plant_id):
        _save_calendar()


func _create_day_label() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "CalendarHUD"
    canvas.layer = 11
    add_child(canvas)
    var chip := PanelContainer.new()
    chip.name = "CalendarChip"
    chip.position = Vector2(8, 8)
    chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.07, 0.15, 0.12, 0.88)
    style.border_color = Color("#718d75")
    style.set_border_width_all(1)
    style.set_corner_radius_all(7)
    style.content_margin_left = 8.0
    style.content_margin_right = 8.0
    style.content_margin_top = 4.0
    style.content_margin_bottom = 4.0
    chip.add_theme_stylebox_override("panel", style)
    canvas.add_child(chip)
    _day_label = Label.new()
    _day_label.name = "DayLabel"
    _day_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _day_label.add_theme_font_size_override("font_size", 10)
    _day_label.add_theme_color_override("font_color", Color("#edf4e3"))
    chip.add_child(_day_label)


func _refresh_label() -> void:
    if _day_label == null:
        return
    _day_label.text = "Dia %d  |  3 dias/fase" % day
    if OS.is_debug_build():
        _day_label.text += "  |  F9 +1"


func _load_calendar() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
    if not parsed is Dictionary or int(parsed.get("version", 0)) != 1:
        push_warning("GameCalendar: save invalido; iniciando calendario novo.")
        return
    day = maxi(1, int(parsed.get("day", 1)))
    seconds_into_day = clampf(float(parsed.get("seconds_into_day", 0.0)), 0.0, seconds_per_day - 0.001)
    var saved_plants = parsed.get("planting_days", {})
    if saved_plants is Dictionary:
        _planting_days = saved_plants


func _save_calendar() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_warning("GameCalendar: nao foi possivel salvar.")
        return
    file.store_string(JSON.stringify({
        "version": 1,
        "day": day,
        "seconds_into_day": seconds_into_day,
        "planting_days": _planting_days
    }))
    _since_save = 0.0


func _exit_tree() -> void:
    _save_calendar()
