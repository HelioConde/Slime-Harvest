extends Control
## Laboratorio visual dos 19 ZIPs do usuario. Nunca modifica os saves.
## Sprites e tiles sao carregados somente se tiverem sido instalados localmente.
const SPROUT_UI = preload("res://scripts/ui/sprout_ui.gd")
const EXPANSION := "res://assets/expansion_packs/"
const ENTRIES: Array[Dictionary] = [
	{"name": "01 · Tiny Animals (64 animais)", "slug": "tiny_animals", "file": "Farm Animals/chicken.png", "info": "Animais 32x32; seis especies tambem visitam o World."},
	{"name": "02 · Mana Seed Character Demo", "slug": "mana_character", "file": "char_a_p1/1out/char_a_p1_1out_undi_v01.png", "info": "Base de personagem em camadas; opcao para NPCs futuros."},
	{"name": "03 · SuperRetroRanch Free Tier", "slug": "ranch", "file": "assets/crops/carrot/growth_basic/carrot_16x16_7frames.png", "info": "Culturas, roupas e tiles do Free Tier (sem previews Premium)."},
	{"name": "04 · PostApocalypse", "slug": "post_apocalypse", "file": "Objects/Barrel_blue_1.png", "info": "Decoracao para ruinas futuras. Uso comercial requer permissao/pagamento."},
	{"name": "05 · Char Free", "slug": "char_free", "file": "global.png", "info": "Personagem adicional de prototipagem; licenca nao identificada no ZIP."},
	{"name": "06 · Little Dreamyland", "slug": "dreamyland", "file": "Sprites/Characters/Bunny/IDLE/Bunny_Idle.png", "info": "NPC coelho, cultivos e cenarios. Apenas nao comercial no Free Pack."},
	{"name": "07 · Mana Seed inverno", "slug": "season_winter", "file": "seasonal sample (winter).png", "info": "Tiles de inverno, cachoeira e brilhos de agua."},
	{"name": "08 · Mana Seed fazendeiro", "slug": "mana_farmer", "file": "farmer base sheets/01body/fbas_1body_human_00.png", "info": "Amostra de personalizacao por camadas do fazendeiro."},
	{"name": "09 · Treasure Chests", "slug": "treasure_chests", "file": "treasure chests.png", "info": "Baus: exemplo interativo no World, uma recompensa por partida."},
	{"name": "10 · Mana Seed outono", "slug": "season_autumn", "file": "seasonal sample (autumn).png", "info": "Bioma sazonal outonal e detalhes de agua."},
	{"name": "11 · Mana Seed primavera", "slug": "season_spring", "file": "seasonal sample (spring).png", "info": "Bioma sazonal primaveril e detalhes de agua."},
	{"name": "12 · Mana Seed verao", "slug": "season_summer", "file": "seasonal sample (summer).png", "info": "Bioma sazonal de verao e detalhes de agua."},
	{"name": "13 · Gentle Forest", "slug": "gentle_forest", "file": "gentle sheets/gentle forest v01.png", "info": "Floresta alternativa; folhas de tiles e animacoes para mapa futuro."},
	{"name": "14 · Breakable Pots", "slug": "breakable_pots", "file": "breakable pots.png", "info": "Vasos quebraveis: exemplo interativo no World."},
	{"name": "15 · Sprout Lands Sprites", "path": "res://assets/sprout_lands/sprites/Objects/Basic Plants.png", "info": "Plantas, animais, mobiliario, edificios e tiles."},
	{"name": "16 · Sprout Lands UI Basic", "path": "res://assets/ui/sprout_lands/settings_menu.png", "info": "Paineis e botoes do HUD e menu."},
	{"name": "17 · Sprout Lands TileMap", "path": "res://addons/sprout_lands_tilemap/base/tilesets/sprout_lands_tile_set.tres", "info": "Plugin de TileMap e cenas base no editor. Opcional."},
	{"name": "18 · Sprout Lands UI plugin", "path": "res://addons/sprout_lands_ui/content/assets/Sprite sheet for Basic Pack.png", "info": "Plugin de tema Godot; nao necessita ativacao automatica."},
	{"name": "19 · Sprout Sorry", "path": "res://assets/Characters/sprout_sorry/free_character_spritesheet_by-cupnooble.png", "info": "Protagonista de 8 direcoes (corrigidas) e efeitos de ferramenta."},
]

var _picker: OptionButton
var _preview: TextureRect
var _description: Label
var _path_hint: Label
var _current: int = 0


func _ready() -> void:
	SPROUT_UI.apply(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	_display(0)


func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("#223428")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.name = "PackLibraryPanel"
	panel.custom_minimum_size = Vector2(475, 310)
	var sprout: StyleBox = SPROUT_UI.get_style(&"panel", &"Panel")
	if sprout != null:
		panel.add_theme_stylebox_override("panel", sprout)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var title := Label.new()
	title.text = "BIBLIOTECA DE ASSETS · 19 PACKS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 17)
	column.add_child(title)
	_picker = OptionButton.new()
	_picker.name = "AssetPackSelector"
	_picker.custom_minimum_size = Vector2(430, 28)
	for entry in ENTRIES:
		_picker.add_item(str(entry["name"]))
	_picker.item_selected.connect(_display)
	column.add_child(_picker)
	_preview = TextureRect.new()
	_preview.name = "AssetPreview"
	_preview.custom_minimum_size = Vector2(430, 114)
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	column.add_child(_preview)
	_description = Label.new()
	_description.name = "PackDescription"
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.add_theme_font_size_override("font_size", 11)
	column.add_child(_description)
	_path_hint = Label.new()
	_path_hint.name = "AssetStatus"
	_path_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_path_hint.add_theme_font_size_override("font_size", 9)
	column.add_child(_path_hint)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)
	for option in [{"label":"Anterior ←", "dir":-1}, {"label":"Proximo →", "dir":1}]:
		var button := Button.new()
		button.text = option["label"]
		button.pressed.connect(_step.bind(int(option["dir"])))
		row.add_child(button)
	var back := Button.new()
	back.name = "ReturnToMenu"
	back.text = "Voltar ao menu (Esc)"
	back.pressed.connect(_return_to_menu)
	row.add_child(back)


func _step(direction: int) -> void:
	_display(posmod(_current + direction, ENTRIES.size()))


func _display(index: int) -> void:
	_current = clampi(index, 0, ENTRIES.size() - 1)
	_picker.select(_current)
	var record: Dictionary = ENTRIES[_current]
	_description.text = str(record["info"])
	var resource_path: String = str(record.get("path", EXPANSION + str(record.get("slug", "")) + "/" + str(record.get("file", ""))))
	_preview.texture = null
	if resource_path.ends_with(".png") and ResourceLoader.exists(resource_path):
		_preview.texture = load(resource_path) as Texture2D
	elif resource_path.ends_with(".tres") and ResourceLoader.exists(resource_path):
		var tiles: Resource = load(resource_path)
		_path_hint.text = "Plugin instalado: " + resource_path if tiles != null else "Plugin nao importado."
		return
	_path_hint.text = "Importado: " + resource_path if _preview.texture != null else "Nao instalado (instale os 19 ZIPs): " + resource_path


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_LEFT:
			_step(-1)
			get_viewport().set_input_as_handled()
		KEY_RIGHT:
			_step(1)
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			_return_to_menu()
			get_viewport().set_input_as_handled()


func _return_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
