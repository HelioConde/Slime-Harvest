extends Control
## Hotbar de dez espacos com os sprites reais do atlas 4x4 (16x16 por icone).
## Ordem: regador, machado, enxada, picareta, galho, madeira,
## tronco, gravetos, tabua, pedra grande, pedra processada, pedra pequena, grama.

signal tool_selected(tool_id: StringName)

const ATLAS: Texture2D = preload("res://assets/Objects/Items/tools-n-meterial-items.png")
const SPROUT_UI = preload("res://scripts/ui/sprout_ui.gd")
const COLUMN_COUNT: int = 4
const CELL: int = 16
const SLOT_IDS: Array[StringName] = [
	&"watering_can", &"axe", &"hoe", &"pickaxe", &"branch",
	&"wood", &"trunk", &"twigs", &"plank", &"large_stone"
]
const SLOT_NAMES: Array[String] = [
	"Regador", "Machado", "Enxada", "Picareta", "Galho",
	"Madeira", "Tronco", "Gravetos", "Tabua", "Pedra grande"
]

const PANEL_COLOR := Color("#162b24")
const PANEL_BORDER := Color("#c8a96d")
const SLOT_COLOR := Color("#213a31")
const SLOT_BORDER := Color("#537766")
const GOLD := Color("#f1d58e")
const BAR_MAX_WIDTH: float = 504.0
const BAR_SIDE_MARGIN: float = 12.0
const BAR_BOTTOM_MARGIN: float = 9.0
const PANEL_PADDING: float = 6.0
const SLOT_GAP: float = 3.0
const SLOT_HEIGHT: float = 46.0
const PANEL_HEIGHT: float = 58.0

var _selected: StringName = &"axe"
var _slots: Dictionary = {}
var _panel: PanelContainer
var _strip: HBoxContainer
var _selection_tween: Tween
var _pulse_button: Button
var _toast: Label
var _toast_tween: Tween
var _selection_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_panel()
	_build_toast()
	_build_selection_label()
	UISettings.ui_scale_changed.connect(_layout_bar)
	_layout_bar()
	_refresh_selection()
	_update_selection_label()
	ResourceBag.amount_changed.connect(_on_amount_changed)
	ResourceBag.item_collected.connect(_on_item_collected)
	for item_id in SLOT_IDS:
		_on_amount_changed(item_id, ResourceBag.get_count(item_id))


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
	frame_style.set_border_width_all(1)
	frame_style.border_width_top = 2
	frame_style.set_corner_radius_all(12)
	frame_style.shadow_color = Color(0.0, 0.0, 0.0, 0.25)
	frame_style.shadow_size = 3
	frame_style.content_margin_left = PANEL_PADDING
	frame_style.content_margin_right = PANEL_PADDING
	frame_style.content_margin_top = 5.0
	frame_style.content_margin_bottom = 5.0
	var sprout_frame: StyleBox = SPROUT_UI.get_style(&"panel", &"Panel")
	_panel.add_theme_stylebox_override("panel", sprout_frame if sprout_frame != null else frame_style)
	add_child(_panel)

	_strip = HBoxContainer.new()
	_strip.name = "TenSlots"
	_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_strip.add_theme_constant_override("separation", int(SLOT_GAP))
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
	if index >= 4:
		button.tooltip_text += " | quantidade coletada"
	button.add_to_group("hotbar_" + String(item_id))
	button.pressed.connect(_slot_pressed.bind(item_id))
	_strip.add_child(button)
	_slots[item_id] = button
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var owned := Label.new()
	owned.name = "OwnedCount"
	owned.visible = false
	owned.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	owned.offset_left = -23.0
	owned.offset_top = 1.0
	owned.offset_right = -3.0
	owned.offset_bottom = 13.0
	owned.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	owned.mouse_filter = Control.MOUSE_FILTER_IGNORE
	owned.add_theme_font_size_override("font_size", 8)
	owned.add_theme_color_override("font_color", GOLD)
	owned.add_theme_constant_override("outline_size", 2)
	owned.add_theme_color_override("font_outline_color", Color("#172620"))
	button.add_child(owned)

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
	image.custom_minimum_size = Vector2(0, 29)
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
	key_label.add_theme_font_size_override("font_size", 9)
	key_label.add_theme_color_override("font_color", Color("#dfebdc"))
	key_label.add_theme_constant_override("outline_size", 2)
	key_label.add_theme_color_override("font_outline_color", Color("#132720"))
	contents.add_child(key_label)


func _layout_bar() -> void:
	if _panel == null:
		return
	# Tudo em coordenadas do viewport: margem lateral consistente e area segura.
	# Os dez slots devem caber no viewport logico, mesmo em janelas menores.
	var usable: float = maxf(100.0, size.x - BAR_SIDE_MARGIN * 2.0)
	var requested_width: float = minf(BAR_MAX_WIDTH, usable)
	var slot_width: float = floorf((requested_width - PANEL_PADDING * 2.0 - SLOT_GAP * 9.0) / 10.0)
	slot_width = maxf(6.0, slot_width)
	var compact: bool = size.x < 480.0
	var slot_height: float = 39.0 if compact else SLOT_HEIGHT
	var bar_height: float = 51.0 if compact else PANEL_HEIGHT
	for item_id in SLOT_IDS:
		var button: Button = _slots[item_id] as Button
		button.custom_minimum_size = Vector2(slot_width, slot_height)
		var image: TextureRect = button.get_node("Content/ItemIcon") as TextureRect
		if image != null:
			image.custom_minimum_size.y = 23.0 if compact else 29.0
	var real_width: float = PANEL_PADDING * 2.0 + slot_width * 10.0 + SLOT_GAP * 9.0
	var ui_scale: float = UISettings.hotbar_scale
	_panel.custom_minimum_size = Vector2(real_width, bar_height)
	_panel.size = Vector2(real_width, bar_height)
	_panel.scale = Vector2.ONE * ui_scale
	# Centralize pela largura ja reduzida, sem mover a camera ou as hitboxes.
	_panel.position = Vector2(roundf((size.x - real_width * ui_scale) * 0.5), roundf(size.y - bar_height * ui_scale - BAR_BOTTOM_MARGIN))
	if _selection_label != null:
		_selection_label.scale = Vector2.ONE * ui_scale
		_selection_label.position = Vector2(_panel.position.x, _panel.position.y - 22.0 * ui_scale)
		_selection_label.size = Vector2(real_width, 18.0)
	if _toast != null:
		_toast.scale = Vector2.ONE * UISettings.hud_scale


func get_slot_item(index: int) -> StringName:
	if index < 0 or index >= SLOT_IDS.size():
		return &""
	return SLOT_IDS[index]


func set_selected_tool(tool_id: StringName) -> void:
	var changed: bool = tool_id != _selected
	_selected = tool_id
	_refresh_selection()
	_update_selection_label()
	if changed:
		_animate_selection(tool_id)


func _animate_selection(tool_id: StringName) -> void:
	# Breve pulso visual sem alterar a escala dos icones pixel art.
	if is_instance_valid(_selection_tween):
		_selection_tween.kill()
	if is_instance_valid(_pulse_button):
		_pulse_button.modulate = Color.WHITE
	_pulse_button = _slots.get(tool_id) as Button
	if _pulse_button == null:
		return
	_pulse_button.modulate = Color(1.0, 0.91, 0.74, 1.0)
	_selection_tween = create_tween()
	_selection_tween.tween_property(_pulse_button, "modulate", Color.WHITE, 0.22).set_trans(Tween.TRANS_SINE)


func _slot_pressed(item_id: StringName) -> void:
	tool_selected.emit(item_id)


func _slot_style(active: bool, hover: bool = false) -> StyleBox:
	var sprout_slot: StyleBox = SPROUT_UI.inventory_slot_style(&"pressed" if active else (&"hover" if hover else &"normal"))
	if sprout_slot != null:
		return sprout_slot
	var sprout_state: StringName = &"hover" if active or hover else &"normal"
	var sprout_style: StyleBox = SPROUT_UI.get_style(sprout_state)
	if sprout_style != null:
		return sprout_style
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#365542") if active else SLOT_COLOR
	if hover:
		style.bg_color = Color("#436449") if active else Color("#2c483b")
	style.border_color = GOLD if active else SLOT_BORDER
	style.set_border_width_all(2 if active else 1)
	style.set_corner_radius_all(7)
	if active:
		style.shadow_color = Color(1.0, 0.77, 0.35, 0.22)
		style.shadow_size = 2
	return style


func _build_selection_label() -> void:
	_selection_label = Label.new()
	_selection_label.name = "SelectedItemName"
	_selection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_selection_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_selection_label.add_theme_font_size_override("font_size", 10)
	_selection_label.add_theme_color_override("font_color", GOLD)
	_selection_label.add_theme_constant_override("outline_size", 2)
	_selection_label.add_theme_color_override("font_outline_color", Color("#14271d"))
	add_child(_selection_label)


func _update_selection_label() -> void:
	if _selection_label == null:
		return
	if _selected == &"pickaxe":
		_selection_label.text = "4 | Picareta"
		return
	for i in range(SLOT_IDS.size()):
		if SLOT_IDS[i] == _selected:
			_selection_label.text = "%d | %s" % [(i + 1) % 10, SLOT_NAMES[i]]
			return
	_selection_label.text = ""


func _build_toast() -> void:
	_toast = Label.new()
	_toast.name = "LastPickup"
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.anchor_left = 0.5
	_toast.anchor_right = 0.5
	_toast.anchor_top = 1.0
	_toast.anchor_bottom = 1.0
	_toast.offset_left = -140.0
	_toast.offset_right = 140.0
	_toast.offset_top = -116.0
	_toast.offset_bottom = -92.0
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 11)
	_toast.add_theme_color_override("font_color", GOLD)
	_toast.add_theme_constant_override("outline_size", 3)
	_toast.add_theme_color_override("font_outline_color", Color("#193024"))
	_toast.modulate.a = 0.0
	add_child(_toast)


func _on_amount_changed(item_id: StringName, count: int) -> void:
	var button: Button = _slots.get(item_id) as Button
	if button == null:
		return
	var label: Label = button.get_node("OwnedCount") as Label
	label.visible = count > 0
	if count > 0:
		label.text = "999+" if count > 999 else str(count)


func _on_item_collected(item_id: StringName, amount: int) -> void:
	if _toast == null:
		return
	if is_instance_valid(_toast_tween):
		_toast_tween.kill()
	_toast.text = "+%d  %s" % [amount, String(item_id).replace("_", " ").capitalize()]
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(0.8)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.65)


func _refresh_selection() -> void:
	for item_id in SLOT_IDS:
		if not _slots.has(item_id):
			continue
		var button: Button = _slots[item_id] as Button
		var active: bool = item_id == _selected
		button.self_modulate = Color(1.18, 1.1, 0.86) if active and SPROUT_UI.get_theme() != null else Color.WHITE
		button.add_theme_stylebox_override("normal", _slot_style(active))
		button.add_theme_stylebox_override("hover", _slot_style(active, true))
		button.add_theme_stylebox_override("pressed", _slot_style(active, true))
		button.add_theme_stylebox_override("hover_pressed", _slot_style(active, true))
