extends Node2D
## Laboratorio opcional de arte Sprout Lands: nao altera o mundo principal.
## O exemplo do addon e carregado apenas quando instalado localmente.
const SAMPLE_MAP := "res://addons/sprout_lands_tilemap/examples/scenes/harvest_hill_example.tscn"
const SPRITES_DIR := "res://assets/sprout_lands/sprites/"
const GALLERY: Array[Dictionary] = [
	{"title": "Personagem", "file": "Characters/Basic Charakter Spritesheet.png"},
	{"title": "Ferramentas", "file": "Characters/Tools.png"},
	{"title": "Galinhas", "file": "Characters/Free Chicken Sprites.png"},
	{"title": "Vacas", "file": "Characters/Free Cow Sprites.png"},
	{"title": "Ninho e ovos", "file": "Characters/Egg_And_Nest.png"},
	{"title": "Plantas", "file": "Objects/Basic Plants.png"},
	{"title": "Bioma da floresta", "file": "Objects/Basic Grass Biom things 1.png"},
	{"title": "Mobilia", "file": "Objects/Basic Furniture.png"},
	{"title": "Baus", "file": "Objects/Chest.png"},
	{"title": "Ponte", "file": "Objects/Wood Bridge.png"},
	{"title": "Caminhos", "file": "Objects/Paths.png"},
	{"title": "Grama", "file": "Tilesets/Grass.png"},
	{"title": "Cercas", "file": "Tilesets/Fences.png"},
	{"title": "Casas", "file": "Tilesets/Wooden House.png"},
	{"title": "Terreno arado", "file": "Tilesets/Tilled_Dirt_v2.png"},
	{"title": "Agua", "file": "Tilesets/Water.png"},
]
var _image: TextureRect
var _title: Label
var _status: Label
var _index: int = 0
var _overlay: Control


func _ready() -> void:
	var map_available := ResourceLoader.exists(SAMPLE_MAP)
	if map_available:
		var source := load(SAMPLE_MAP) as PackedScene
		if source != null:
			add_child(source.instantiate())
	var camera := Camera2D.new()
	camera.name = "GalleryCamera"
	camera.position = Vector2.ZERO
	camera.zoom = Vector2(1.3, 1.3)
	camera.enabled = true
	add_child(camera)
	_build_gallery(map_available)
	_display(0)


func _build_gallery(has_map: bool) -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "SproutGalleryHUD"
	add_child(canvas)
	_overlay = Control.new()
	_overlay.name = "GalleryPanelRoot"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_overlay)
	var panel := PanelContainer.new()
	panel.name = "GalleryPanel"
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -266.0
	panel.offset_right = -8.0
	panel.offset_top = 8.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(panel)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#293b32e6")
	background.border_color = Color("#d2aa6c")
	background.set_border_width_all(2)
	background.set_corner_radius_all(6)
	background.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", background)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	panel.add_child(stack)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_color_override("font_color", Color("#fce5b2"))
	stack.add_child(_title)
	_image = TextureRect.new()
	_image.name = "SpritePreview"
	_image.custom_minimum_size = Vector2(234, 145)
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stack.add_child(_image)
	var navigation := HBoxContainer.new()
	navigation.add_theme_constant_override("separation", 4)
	stack.add_child(navigation)
	var previous := Button.new()
	previous.text = "<"
	previous.custom_minimum_size.x = 30.0
	previous.pressed.connect(_change.bind(-1))
	navigation.add_child(previous)
	_status = Label.new()
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_color_override("font_color", Color("#fce5b2"))
	navigation.add_child(_status)
	var next := Button.new()
	next.text = ">"
	next.custom_minimum_size.x = 30.0
	next.pressed.connect(_change.bind(1))
	navigation.add_child(next)
	var help := Label.new()
	help.text = ("Mapa Sprout: OK" if has_map else "Instale os dois plugins e os packs") + " | TAB esconde"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_font_size_override("font_size", 10)
	help.add_theme_color_override("font_color", Color("#fce5b2"))
	stack.add_child(help)


func _change(step: int) -> void:
	_display(wrapi(_index + step, 0, GALLERY.size()))


func _display(next_index: int) -> void:
	_index = next_index
	var record: Dictionary = GALLERY[_index]
	_title.text = str(record["title"])
	_status.text = "%d / %d" % [_index + 1, GALLERY.size()]
	var sprite_path: String = SPRITES_DIR + str(record["file"])
	if ResourceLoader.exists(sprite_path):
		_image.texture = load(sprite_path) as Texture2D
	else:
		_image.texture = null
	if _image.texture == null:
		_title.text += " (pacote nao instalado)"


func _unhandled_key_input(event: InputEvent) -> void:
	var pressed := event as InputEventKey
	if pressed == null or not pressed.pressed or pressed.echo:
		return
	if pressed.keycode == KEY_TAB:
		_overlay.visible = not _overlay.visible
		get_viewport().set_input_as_handled()
	elif pressed.keycode == KEY_LEFT and _overlay.visible:
		_change(-1)
		get_viewport().set_input_as_handled()
	elif pressed.keycode == KEY_RIGHT and _overlay.visible:
		_change(1)
		get_viewport().set_input_as_handled()
