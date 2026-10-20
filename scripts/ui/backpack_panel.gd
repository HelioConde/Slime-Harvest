extends CanvasLayer
## Mochila leve: mostra ferramentas e recursos reais, sem criar contadores paralelos.
## Abre com I; usa sprites originais existentes e o tema Sprout opcional.
const UI_THEME = preload("res://scripts/ui/sprout_ui.gd")
const ITEM_ATLAS: Texture2D = preload("res://assets/Objects/Items/tools-n-meterial-items.png")
const FLOWER_ATLAS: Texture2D = preload("res://assets/Objects/Mushrooms, Flowers, Stones.png")

const IDS: Array[StringName] = [
	&"watering_can", &"axe", &"hoe", &"pickaxe", &"branch", &"wood",
	&"trunk", &"twigs", &"plank", &"large_stone",
]
const NAMES := {
	"watering_can": "Regador", "axe": "Machado", "hoe": "Enxada",
	"pickaxe": "Picareta", "branch": "Galhos", "wood": "Madeira",
	"trunk": "Troncos", "twigs": "Gravetos", "plank": "Tabuas",
	"large_stone": "Pedras", "small_stone": "Pedra pequena",
	"processed_stone": "Pedra tratada", "flower_blue": "Flor azul",
	"flower_pink": "Flor rosa", "flower_yellow": "Flor amarela",
}
const FLOWERS := {
	"flower_blue": Rect2(176, 64, 16, 16),
	"flower_pink": Rect2(112, 48, 16, 16),
	"flower_yellow": Rect2(112, 64, 16, 16),
}

var _player: Node
var _layer: Control
var _panel: PanelContainer
var _grid: GridContainer
var _summary: Label
var _was_enabled: bool = true
var _opened: bool = false


func _ready() -> void:
	layer = 42
	_player = get_parent()
	_build()
	ResourceBag.amount_changed.connect(_on_resource_changed)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_I:
		toggle()
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_ESCAPE and _opened:
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if _opened:
		_opened = false
		_layer.hide()
		if is_instance_valid(_player) and _player.has_method("set_controls_enabled"):
			_player.call("set_controls_enabled", _was_enabled)
		return
	if not is_instance_valid(_player) or not bool(_player.get("controls_enabled")):
		return
	_was_enabled = bool(_player.get("controls_enabled"))
	_player.call("set_controls_enabled", false)
	_opened = true
	_refresh()
	_layer.show()


func _build() -> void:
	_layer = Control.new()
	_layer.name = "BackpackOverlay"
	_layer.visible = false
	_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_layer)
	var shade := ColorRect.new()
	shade.name = "BackpackShade"
	shade.color = Color(0, 0, 0, 0.66)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	_layer.add_child(center)
	_panel = PanelContainer.new()
	_panel.name = "BackpackWindow"
	_panel.custom_minimum_size = Vector2(446, 280)
	var style: StyleBox = UI_THEME.get_style(&"panel", &"Panel")
	if style == null:
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color("#23382d")
		normal.border_color = Color("#dbb876")
		normal.set_border_width_all(2)
		normal.set_corner_radius_all(8)
		style = normal
	_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_panel)
	var padding := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		padding.add_theme_constant_override("margin_" + side, 12)
	_panel.add_child(padding)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	padding.add_child(column)
	var title_bar := HBoxContainer.new()
	column.add_child(title_bar)
	var title := Label.new()
	title.text = "MOCHILA"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", _text_color())
	title_bar.add_child(title)
	var close := Button.new()
	close.name = "CloseBackpack"
	close.text = "Fechar (I)"
	close.pressed.connect(toggle)
	title_bar.add_child(close)
	_summary = Label.new()
	_summary.name = "InventorySummary"
	_summary.add_theme_font_size_override("font_size", 11)
	_summary.add_theme_color_override("font_color", _text_color())
	column.add_child(_summary)
	var scroll := ScrollContainer.new()
	scroll.name = "InventoryScroll"
	scroll.custom_minimum_size = Vector2(416, 182)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	_grid = GridContainer.new()
	_grid.name = "ItemGrid"
	_grid.columns = 5
	_grid.add_theme_constant_override("h_separation", 5)
	_grid.add_theme_constant_override("v_separation", 5)
	scroll.add_child(_grid)
	var footer := Label.new()
	footer.text = "Ferramentas: 1-4 | Coletar: aproximar ou clicar"
	footer.add_theme_font_size_override("font_size", 10)
	footer.add_theme_color_override("font_color", _text_color())
	column.add_child(footer)


func _text_color() -> Color:
	return Color("#34251a") if UI_THEME.get_theme() != null else Color("#fff0d0")


func _on_resource_changed(_item_id: StringName, _total: int) -> void:
	if _opened:
		_refresh()


func _refresh() -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	var crops: Node = _player.get_node_or_null("../Map/WorldCrops") if is_instance_valid(_player) else null
	if crops != null:
		_summary.text = "Sementes: %d  |  Colheitas: %d  |  I: fechar" % [
			int(crops.call("get_seed_count")), int(crops.call("get_harvest_count")),
		]
	else:
		_summary.text = "Materiais coletados | I: fechar"
	for index in range(4):
		_add_cell(String(IDS[index]), -1, _atlas_icon(index))
	var counts: Dictionary = ResourceBag.get_all_counts()
	var listed: Dictionary = {}
	for index in range(4, IDS.size()):
		var key: String = String(IDS[index])
		listed[key] = true
		if int(counts.get(key, 0)) > 0:
			_add_cell(key, int(counts[key]), _atlas_icon(index))
	var other_keys: Array = counts.keys()
	other_keys.sort()
	for key in other_keys:
		var id: String = str(key)
		if listed.has(id) or int(counts[id]) <= 0:
			continue
		var icon: Texture2D
		if FLOWERS.has(id):
			var atlas := AtlasTexture.new()
			atlas.atlas = FLOWER_ATLAS
			atlas.region = FLOWERS[id]
			atlas.filter_clip = true
			icon = atlas
		_add_cell(id, int(counts[id]), icon)


func _atlas_icon(index: int) -> Texture2D:
	var texture := AtlasTexture.new()
	texture.atlas = ITEM_ATLAS
	texture.region = Rect2((index % 4) * 16, (index / 4) * 16, 16, 16)
	texture.filter_clip = true
	return texture


func _add_cell(item_id: String, count: int, texture: Texture2D) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(76, 70)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#355445")
	style.border_color = Color("#b4a071")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	card.add_theme_stylebox_override("panel", style)
	card.tooltip_text = NAMES.get(item_id, item_id.replace("_", " ").capitalize())
	_grid.add_child(card)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 0)
	card.add_child(stack)
	if texture != null:
		var image := TextureRect.new()
		image.texture = texture
		image.custom_minimum_size = Vector2(25, 30)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		stack.add_child(image)
	else:
		var generic := Label.new()
		generic.text = "✦"
		generic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stack.add_child(generic)
	var name_label := Label.new()
	name_label.text = str(NAMES.get(item_id, item_id.replace("_", " ").capitalize())).substr(0, 13)
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", Color("#fff1dc"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(name_label)
	var count_label := Label.new()
	count_label.text = "Ferramenta" if count == -1 else "x%d" % count
	count_label.add_theme_font_size_override("font_size", 9)
	count_label.add_theme_color_override("font_color", Color("#f2d795"))
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(count_label)
