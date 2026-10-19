extends VBoxContainer
## Mesmo painel para as opcoes no menu principal e durante a partida.
var _hotbar_slider: HSlider
var _hud_slider: HSlider
var _hotbar_value: Label
var _hud_value: Label


func _ready() -> void:
	name = "InterfaceScaleControls"
	custom_minimum_size.x = 264.0
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)
	var header := Label.new()
	header.text = "Tamanho da interface"
	header.add_theme_font_size_override("font_size", 13)
	add_child(header)
	var bar: Dictionary = _make_row("Hotbar (1 a 0)")
	_hotbar_slider = bar["slider"] as HSlider
	_hotbar_value = bar["value_label"] as Label
	_hotbar_slider.value_changed.connect(_on_hotbar_changed)
	var hud: Dictionary = _make_row("HUD (dia e avisos)")
	_hud_slider = hud["slider"] as HSlider
	_hud_value = hud["value_label"] as Label
	_hud_slider.value_changed.connect(_on_hud_changed)
	var reset := Button.new()
	reset.name = "RestoreInterfaceSize"
	reset.text = "Restaurar tamanho padrao"
	reset.custom_minimum_size.y = 23.0
	reset.pressed.connect(UISettings.restore_defaults)
	add_child(reset)
	var hint := Label.new()
	hint.text = "O tamanho muda na hora e fica salvo."
	hint.add_theme_font_size_override("font_size", 10)
	add_child(hint)
	UISettings.ui_scale_changed.connect(_refresh)
	_refresh()


func _make_row(title: String) -> Dictionary:
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 11)
	add_child(label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	var slider := HSlider.new()
	slider.name = title.get_slice(" ", 0) + "Scale"
	slider.min_value = UISettings.MIN_SCALE
	slider.max_value = UISettings.MAX_SCALE
	slider.step = UISettings.SCALE_STEP
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(180, 20)
	row.add_child(slider)
	var value_label := Label.new()
	value_label.custom_minimum_size.x = 39.0
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	return {"slider": slider, "value_label": value_label}


func _on_hotbar_changed(value: float) -> void:
	UISettings.set_hotbar_scale(value)


func _on_hud_changed(value: float) -> void:
	UISettings.set_hud_scale(value)


func _refresh() -> void:
	_hotbar_slider.set_value_no_signal(UISettings.hotbar_scale)
	_hud_slider.set_value_no_signal(UISettings.hud_scale)
	_hotbar_value.text = "%d%%" % roundi(UISettings.hotbar_scale * 100.0)
	_hud_value.text = "%d%%" % roundi(UISettings.hud_scale * 100.0)
