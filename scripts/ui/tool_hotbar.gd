extends Control
## Hotbar de dez espacos com os sprites reais do atlas 4x3 (16x16 por icone).
## Ordem do atlas: regador, machado, enxada, grama, galho, madeira, tronco,
## gravetos, tabua, pedra grande, pedra processada, pedra pequena.

signal tool_selected(tool_id: StringName)

const ATLAS: Texture2D = preload("res://assets/Objects/Items/tools-n-meterial-items.png")
const COLUMN_COUNT: int = 4
const CELL: int = 16
const SLOT_IDS: Array[StringName] = [
	&"watering_can", &"axe", &"hoe", &"grass_drop", &"branch",
	&"wood", &"trunk", &"twigs", &"plank", &"large_stone"
]
const SLOT_NAMES: Array[String] = [
	"Regador", "Machado", "Enxada", "Grama", "Galho",
	"Madeira", "Tronco", "Gravetos", "Tabua", "Pedra grande"
]

const PANEL_COLOR := Color("#162b24")
const PANEL_BORDER := Color("#c8a96d")
const SLOT_COLOR := Color("#213a31")
const SLOT_BORDER := Color("#537766")
const GOLD := Color("#f1d58e")

var _selected: StringName = &"axe"
var _slots: Dictionary = {}
var _panel: PanelContainer
var _strip: HBoxContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_panel()
	_layout_bar()
	_refresh_selection()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _panel != null:
		_layout_bar()


func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.name = "InventoryFrame"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = PANEL_COLOR
	frame_style.border_color = PANEL_BORDER
	frame_style.set_border_width_all(2)
	frame_style.set_corner_radius_all(16)
	frame_style.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	frame_style.shadow_size = 7
	frame_style.content_margin_left = 8.0
	frame_style.content_margin_right = 8.0
	frame_style.content_margin_top = 7.0
	frame_style.content_margin_bottom = 7.0
	_panel.add_theme_stylebox_override("panel", frame_style)
	add_child(_panel)

	_strip = HBoxContainer.new()
	_strip.name = "TenSlots"
	_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_strip.add_theme_constant_override("separation", 4)
	_panel.add_child(_strip)

	for index in range(SLOT_IDS.size()):
		_make_slot(index)


func _make_slot(index: int) -> void:
	var item_id: StringName = SLOT_IDS[index]
	var button := Button.new()
	button.name = "Slot_%02d_%s" % [index + 1, String(item_id)]
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.tooltip_text = "%d - %s" % [index + 1, SLOT_NAMES[index]]
	if index >= 3:
		button.tooltip_text += " | recurso (coleta em desenvolvimento)"
	button.add_to_group("hotbar_" + String(item_id))
	button.pressed.connect(_slot_pressed.bind(item_id))
	_strip.add_child(button)
	_slots[item_id] = button
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var contents := VBoxContainer.new()
	contents.name = "Content"
	contents.alignment = BoxContainer.ALIGNMENT_CENTER
	contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_theme_constant_override("separation", 0)
	button.add_child(contents)
	contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var image := TextureRect.new()
	image.name = "ItemIcon"
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.custom_minimum_size = Vector2(34, 36)
	image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frame := AtlasTexture.new()
	frame.atlas = ATLAS
	var col: int = index % COLUMN_COUNT
	var row: int = index / COLUMN_COUNT
	frame.region = Rect2(col * CELL, row * CELL, CELL, CELL)
	frame.filter_clip = true
	image.texture = frame
	contents.add_child(image)

	var key_label := Label.new()
	key_label.name = "Shortcut"
	key_label.text = str((index + 1) % 10)
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key_label.add_theme_font_size_override("font_size", 10)
	key_label.add_theme_color_override("font_color", Color("#dfebdc"))
	key_label.add_theme_constant_override("outline_size", 2)
	key_label.add_theme_color_override("font_outline_color", Color("#132720"))
	contents.add_child(key_label)


func _layout_bar() -> void:
	if _panel == null:
		return
	var usable: float = maxf(230.0, size.x - 12.0)
	var width: float = minf(610.0, usable)
	var slot_width: float = (width - 16.0 - 9.0 * 4.0) / 10.0
	for item_id in SLOT_IDS:
		var button: Button = _slots[item_id] as Button
		button.custom_minimum_size = Vector2(slot_width, 57.0)
	_panel.custom_minimum_size = Vector2(width, 72.0)
	_panel.size = Vector2(width, 72.0)
	_panel.position = Vector2((size.x - width) * 0.5, size.y - 80.0)


func get_slot_item(index: int) -> StringName:
	if index < 0 or index >= SLOT_IDS.size():
		return &""
	return SLOT_IDS[index]


func set_selected_tool(tool_id: StringName) -> void:
	_selected = tool_id
	_refresh_selection()


func _slot_pressed(item_id: StringName) -> void:
	tool_selected.emit(item_id)


func _slot_style(active: bool, hover: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#385841") if active else SLOT_COLOR
	if hover:
		style.bg_color = Color("#4d6e51") if active else Color("#2f4d40")
	style.border_color = GOLD if active else SLOT_BORDER
	style.set_border_width_all(3 if active else 1)
	style.set_corner_radius_all(9)
	if active:
		style.shadow_color = Color(1.0, 0.78, 0.38, 0.48)
		style.shadow_size = 4
	return style


func _refresh_selection() -> void:
	for item_id in SLOT_IDS:
		if not _slots.has(item_id):
			continue
		var button: Button = _slots[item_id] as Button
		var active: bool = item_id == _selected
		button.add_theme_stylebox_override("normal", _slot_style(active))
		button.add_theme_stylebox_override("hover", _slot_style(active, true))
		button.add_theme_stylebox_override("pressed", _slot_style(active, true))
		button.add_theme_stylebox_override("hover_pressed", _slot_style(active, true))
