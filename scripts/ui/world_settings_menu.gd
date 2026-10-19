extends CanvasLayer
## Opcoes in-game com pre-visualizacao reversivel e dialogo responsivo.
const SCALE_CONTROLS = preload("res://scripts/ui/ui_scale_controls.gd")

var _overlay: ColorRect
var _dialog: PanelContainer
var _scale_controls: VBoxContainer
var _open_button: Button
var _was_paused: bool = false


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_controls()
	get_viewport().size_changed.connect(_update_dialog_scale)
	UISettings.ui_scale_changed.connect(_update_dialog_scale)
	_update_dialog_scale.call_deferred()


func _build_controls() -> void:
	var root := Control.new()
	root.name = "WorldSettingsRoot"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_open_button = Button.new()
	_open_button.name = "OpenSettings"
	_open_button.text = "⚙"
	_open_button.tooltip_text = "Configuracoes de interface (F10)"
	_open_button.anchor_left = 1.0
	_open_button.anchor_right = 1.0
	_open_button.offset_left = -36.0
	_open_button.offset_right = -8.0
	_open_button.offset_top = 8.0
	_open_button.offset_bottom = 36.0
	_open_button.pressed.connect(_open_options)
	root.add_child(_open_button)

	_overlay = ColorRect.new()
	_overlay.name = "SettingsOverlay"
	_overlay.color = Color(0, 0, 0, 0.75)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.hide()

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog = PanelContainer.new()
	_dialog.name = "SettingsDialog"
	_dialog.custom_minimum_size.x = 320.0
	center.add_child(_dialog)
	_dialog.resized.connect(_update_dialog_scale)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_dialog.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)
	var title := Label.new()
	title.text = "Configuracoes"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	content.add_child(title)
	_scale_controls = SCALE_CONTROLS.new() as VBoxContainer
	content.add_child(_scale_controls)
	var close := Button.new()
	close.name = "CloseSettings"
	close.text = "Cancelar / Voltar ao jogo"
	close.custom_minimum_size.y = 28.0
	close.pressed.connect(_close_options)
	content.add_child(close)


func _update_dialog_scale() -> void:
	if is_instance_valid(_open_button):
		_open_button.pivot_offset = Vector2(_open_button.size.x, 0.0)
		_open_button.scale = Vector2.ONE * UISettings.hud_scale
	if not is_instance_valid(_dialog) or _dialog.size.x <= 0.0 or _dialog.size.y <= 0.0:
		return
	var available: Vector2 = get_viewport().get_visible_rect().size - Vector2(24.0, 24.0)
	var factor: float = minf(UISettings.hud_scale,
		minf(available.x / _dialog.size.x, available.y / _dialog.size.y))
	_dialog.pivot_offset = _dialog.size * 0.5
	_dialog.scale = Vector2.ONE * clampf(factor, 0.25, UISettings.MAX_SCALE)


func _open_options() -> void:
	if _overlay.visible:
		return
	_was_paused = get_tree().paused
	_scale_controls.call("begin_edit")
	_overlay.show()
	_update_dialog_scale.call_deferred()
	get_tree().paused = true


func _close_options() -> void:
	if not _overlay.visible:
		return
	_scale_controls.call("cancel_changes")
	_overlay.hide()
	get_tree().paused = _was_paused


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_ESCAPE and _overlay.visible:
		_close_options()
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_F10:
		if _overlay.visible:
			_close_options()
		else:
			_open_options()
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if _overlay != null and _overlay.visible:
		if is_instance_valid(_scale_controls):
			_scale_controls.call("cancel_changes")
		get_tree().paused = _was_paused
