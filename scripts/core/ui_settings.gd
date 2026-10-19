extends Node
## Preferencias visuais globais, independentes dos tres slots da fazenda.
signal ui_scale_changed

const SAVE_PATH := "user://slimekeepers_ui_settings_v1.cfg"
const DEFAULT_HOTBAR_SCALE := 0.75
const DEFAULT_HUD_SCALE := 0.85
const MIN_SCALE := 0.60
const MAX_SCALE := 1.15
const SCALE_STEP := 0.05

var hotbar_scale: float = DEFAULT_HOTBAR_SCALE
var hud_scale: float = DEFAULT_HUD_SCALE


func _ready() -> void:
	_load()


func set_hotbar_scale(value: float) -> void:
	var next: float = _sanitize(value, DEFAULT_HOTBAR_SCALE)
	if is_equal_approx(hotbar_scale, next):
		return
	hotbar_scale = next
	_save()
	ui_scale_changed.emit()


func set_hud_scale(value: float) -> void:
	var next: float = _sanitize(value, DEFAULT_HUD_SCALE)
	if is_equal_approx(hud_scale, next):
		return
	hud_scale = next
	_save()
	ui_scale_changed.emit()


func restore_defaults() -> void:
	preview_scales(DEFAULT_HOTBAR_SCALE, DEFAULT_HUD_SCALE)
	_save()


## Atualiza apenas a pre-visualizacao. O arquivo so e gravado ao confirmar.
func preview_scales(next_hotbar: float, next_hud: float) -> void:
	var sanitized_bar: float = _sanitize(next_hotbar, DEFAULT_HOTBAR_SCALE)
	var sanitized_hud: float = _sanitize(next_hud, DEFAULT_HUD_SCALE)
	if is_equal_approx(hotbar_scale, sanitized_bar) and is_equal_approx(hud_scale, sanitized_hud):
		return
	hotbar_scale = sanitized_bar
	hud_scale = sanitized_hud
	ui_scale_changed.emit()


func commit_preview() -> void:
	_save()


func _sanitize(value: float, fallback: float) -> float:
	if not is_finite(value):
		return fallback
	return clampf(roundf(value / SCALE_STEP) * SCALE_STEP, MIN_SCALE, MAX_SCALE)


func _load() -> void:
	var settings := ConfigFile.new()
	if settings.load(SAVE_PATH) != OK:
		return
	var bar_value: Variant = settings.get_value("interface", "hotbar_scale", DEFAULT_HOTBAR_SCALE)
	var hud_value: Variant = settings.get_value("interface", "hud_scale", DEFAULT_HUD_SCALE)
	if bar_value is float or bar_value is int:
		hotbar_scale = _sanitize(float(bar_value), DEFAULT_HOTBAR_SCALE)
	if hud_value is float or hud_value is int:
		hud_scale = _sanitize(float(hud_value), DEFAULT_HUD_SCALE)


func _save() -> void:
	var settings := ConfigFile.new()
	settings.set_value("interface", "hotbar_scale", hotbar_scale)
	settings.set_value("interface", "hud_scale", hud_scale)
	var result: Error = settings.save(SAVE_PATH)
	if result != OK:
		push_warning("UISettings: nao foi possivel salvar as preferencias (%d)." % result)
