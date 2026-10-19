extends CanvasLayer
## Botao de configuracoes no mundo; a interface de jogo pausa durante o ajuste.
const SCALE_CONTROLS = preload("res://scripts/ui/ui_scale_controls.gd")

var _overlay: ColorRect
var _was_paused: bool = false


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_controls()


func _build_controls() -> void:
	var root := Control.new()
	root.name = "WorldSettingsRoot"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var open_button := Button.new()
	open_button.name = "OpenSettings"
	open_button.text = "⚙"
	open_button.tooltip_text = "Configuracoes de interface (F10)"
	open_button.anchor_left = 1.0
	open_button.anchor_right = 1.0
	open_button.offset_left = -36.0
	open_button.offset_right = -8.0
	open_button.offset_top = 8.0
	open_button.offset_bottom = 36.0
	open_button.pressed.connect(_open_options)
	root.add_child(open_button)

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
	var panel := PanelContainer.new()
	panel.name = "SettingsDialog"
	panel.custom_minimum_size.x = 320.0
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)
	var title := Label.new()
	title.text = "Configuracoes"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	content.add_child(title)
	content.add_child(SCALE_CONTROLS.new())
	var close := Button.new()
	close.name = "CloseSettings"
	close.text = "Voltar ao jogo"
	close.custom_minimum_size.y = 28.0
	close.pressed.connect(_close_options)
	content.add_child(close)


func _open_options() -> void:
	if _overlay.visible:
		return
	_was_paused = get_tree().paused
	_overlay.show()
	get_tree().paused = true


func _close_options() -> void:
	if not _overlay.visible:
		return
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
		get_tree().paused = _was_paused
