extends VBoxContainer
## Controles compartilhados: sliders fazem previa; Salvar persiste, Voltar desfaz.
var _hotbar_slider: HSlider
var _hud_slider: HSlider
var _hotbar_value: Label
var _hud_value: Label
var _hint: Label
var _saved_hotbar: float = UISettings.DEFAULT_HOTBAR_SCALE
var _saved_hud: float = UISettings.DEFAULT_HUD_SCALE


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
	var hud: Dictionary = _make_row("HUD (dia, avisos e menus)")
	_hud_slider = hud["slider"] as HSlider
	_hud_value = hud["value_label"] as Label
	_hud_slider.value_changed.connect(_on_hud_changed)
	var reset := Button.new()
	reset.name = "RestoreInterfaceSize"
	reset.text = "Restaurar tamanho padrao"
	reset.custom_minimum_size.y = 23.0
	reset.pressed.connect(_restore_preview_defaults)
	add_child(reset)
	var save := Button.new()
	save.name = "SaveInterfaceScale"
	save.text = "Salvar"
	save.custom_minimum_size.y = 27.0
	save.pressed.connect(_save_changes)
	add_child(save)
	_hint = Label.new()
	_hint.name = "InterfaceSaveHint"
	_hint.text = "Ajuste para visualizar. Salvar confirma; Voltar desfaz."
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_font_size_override("font_size", 10)
	add_child(_hint)
	UISettings.ui_scale_changed.connect(_refresh)
	begin_edit()


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


func begin_edit() -> void:
	_saved_hotbar = UISettings.hotbar_scale
	_saved_hud = UISettings.hud_scale
	if _hint != null:
		_hint.text = "Ajuste para visualizar. Salvar confirma; Voltar desfaz."
	_refresh()


func cancel_changes() -> void:
	UISettings.preview_scales(_saved_hotbar, _saved_hud)
	_refresh()


func _restore_preview_defaults() -> void:
	UISettings.preview_scales(UISettings.DEFAULT_HOTBAR_SCALE, UISettings.DEFAULT_HUD_SCALE)
	_refresh()


func _on_hotbar_changed(value: float) -> void:
	UISettings.preview_scales(value, UISettings.hud_scale)


func _on_hud_changed(value: float) -> void:
	UISettings.preview_scales(UISettings.hotbar_scale, value)


func _save_changes() -> void:
	UISettings.commit_preview()
	_saved_hotbar = UISettings.hotbar_scale
	_saved_hud = UISettings.hud_scale
	_hint.text = "Preferencias de interface salvas."


func _refresh() -> void:
	if _hotbar_slider == null or _hud_slider == null:
		return
	_hotbar_slider.set_value_no_signal(UISettings.hotbar_scale)
	_hud_slider.set_value_no_signal(UISettings.hud_scale)
	_hotbar_value.text = "%d%%" % roundi(UISettings.hotbar_scale * 100.0)
	_hud_value.text = "%d%%" % roundi(UISettings.hud_scale * 100.0)
