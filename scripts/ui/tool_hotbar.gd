extends Control
## Barra de inventario inferior, responsiva, com quatro acessorios clicaveis.

signal tool_selected(tool_id: StringName)

const ICON_SCRIPT = preload("res://scripts/ui/tool_icon.gd")
const TOOLS: Array[StringName] = [&"pickaxe", &"axe", &"hoe", &"watering_can"]
const NAMES := ["Picareta", "Machado", "Enxada", "Regador"]

var _selected: StringName = &"axe"
var _slots: Dictionary = {}
var _strip: HBoxContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_strip = HBoxContainer.new()
	_strip.name = "AccessorySlots"
	_strip.add_theme_constant_override("separation", 7)
	add_child(_strip)
	for index in range(TOOLS.size()):
		_create_slot(TOOLS[index], NAMES[index], index + 1)
	_layout_bar()
	_update_slots()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _strip != null:
		_layout_bar()


func _create_slot(tool_id: StringName, title: String, index: int) -> void:
	var button := Button.new()
	button.name = "Slot_" + String(tool_id)
	button.custom_minimum_size = Vector2(72, 77)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.tooltip_text = "%d - %s" % [index, title]
	button.add_to_group("accessory_" + String(tool_id))
	button.pressed.connect(_on_slot_pressed.bind(tool_id))
	_strip.add_child(button)
	_slots[tool_id] = button

	var inner := VBoxContainer.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 1)
	button.add_child(inner)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var icon: Control = ICON_SCRIPT.new()
	icon.set("tool_id", tool_id)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inner.add_child(icon)

	var label := Label.new()
	label.text = "%d  %s" % [index, title]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color("#f6f1d9"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(label)


func _layout_bar() -> void:
	if _strip == null:
		return
	var available := maxf(290.0, size.x - 16.0)
	var bar_width := minf(440.0, available)
	_strip.anchor_left = 0.5
	_strip.anchor_right = 0.5
	_strip.anchor_top = 1.0
	_strip.anchor_bottom = 1.0
	_strip.offset_left = -bar_width / 2.0
	_strip.offset_right = bar_width / 2.0
	_strip.offset_top = -87.0
	_strip.offset_bottom = -8.0
	var slot_width := (bar_width - 21.0) / 4.0
	for slot in _slots.values():
		(slot as Button).custom_minimum_size.x = slot_width


func set_selected_tool(tool_id: StringName) -> void:
	if not TOOLS.has(tool_id):
		return
	_selected = tool_id
	_update_slots()


func _on_slot_pressed(tool_id: StringName) -> void:
	tool_selected.emit(tool_id)


func _style(selected: bool, hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#43624e") if selected else Color("#25342f")
	if hovered:
		style.bg_color = Color("#527360") if selected else Color("#344a3d")
	style.border_color = Color("#f0d58c") if selected else Color("#718674")
	style.border_width_left = 3 if selected else 1
	style.border_width_right = 3 if selected else 1
	style.border_width_top = 3 if selected else 1
	style.border_width_bottom = 3 if selected else 1
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	return style


func _update_slots() -> void:
	for tool_id in _slots.keys():
		var button := _slots[tool_id] as Button
		var active := tool_id == _selected
		button.add_theme_stylebox_override("normal", _style(active, false))
		button.add_theme_stylebox_override("hover", _style(active, true))
		button.add_theme_stylebox_override("pressed", _style(active, true))
		button.add_theme_stylebox_override("disabled", _style(false, false))
