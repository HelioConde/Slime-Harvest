extends RefCounted
## Carrega a UI Sprout Lands instalada localmente sem criar dependencia obrigatoria.
## O tema deve ser instalado com tools/install_sprout_ui.py; nao publique o atlas
## original no repositorio publico sem permissao de redistribuicao.
const THEME_PATH := "res://assets/ui/sprout_lands/sprout_theme.tres"
const INVENTORY_ATLAS := "res://assets/ui/sprout_lands/inventory_atlas.png"
const _SLOT_REGION := Rect2(227, 163, 46, 48)
const _SLOT_HOVER_REGION := Rect2(275, 163, 46, 48)
const _SLOT_PRESSED_REGION := Rect2(322, 163, 46, 48)


static func get_theme() -> Theme:
	if not ResourceLoader.exists(THEME_PATH):
		return null
	var loaded_theme := load(THEME_PATH) as Theme
	if loaded_theme != null:
		# O pack usa madeira clara: o texto padrao branco do Godot
		# perde contraste em botoes, labels e caixas de texto.
		loaded_theme.set_color(&"font_color", &"Button", Color("#3c2b21"))
		loaded_theme.set_color(&"font_hover_color", &"Button", Color("#292018"))
		loaded_theme.set_color(&"font_pressed_color", &"Button", Color("#292018"))
		loaded_theme.set_color(&"font_disabled_color", &"Button", Color("#796d60"))
		loaded_theme.set_color(&"font_color", &"Label", Color("#3c2b21"))
	return loaded_theme


static func get_style(style_name: StringName, type_name: StringName = &"Button") -> StyleBox:
	var loaded_theme: Theme = get_theme()
	if loaded_theme == null or not loaded_theme.has_stylebox(style_name, type_name):
		return null
	# Cada controle recebe sua propria instancia e pode modificar a aparencia.
	return loaded_theme.get_stylebox(style_name, type_name).duplicate() as StyleBox


static func apply(control: Control) -> bool:
	var loaded_theme: Theme = get_theme()
	if loaded_theme == null:
		return false
	control.theme = loaded_theme
	control.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return true


## Estes elementos sao os sprites reais de inventario e coracoes do Basic Pack,
## nao uma aproximacao com StyleBoxFlat. Sem o ZIP, permanecem opcionais.
static func has_inventory_atlas() -> bool:
	return ResourceLoader.exists(INVENTORY_ATLAS)


static func inventory_slot_style(state: StringName = &"normal") -> StyleBox:
	if not has_inventory_atlas():
		return null
	var atlas: Texture2D = load(INVENTORY_ATLAS) as Texture2D
	if atlas == null or atlas.get_width() < 368 or atlas.get_height() < 336:
		return null
	var region: Rect2 = _SLOT_REGION
	if state == &"hover":
		region = _SLOT_HOVER_REGION
	elif state == &"pressed":
		region = _SLOT_PRESSED_REGION
	var cropped := AtlasTexture.new()
	cropped.atlas = atlas
	cropped.region = region
	cropped.filter_clip = true
	var frame := StyleBoxTexture.new()
	frame.texture = cropped
	frame.texture_margin_left = 9.0
	frame.texture_margin_top = 9.0
	frame.texture_margin_right = 9.0
	frame.texture_margin_bottom = 9.0
	frame.content_margin_left = 3.0
	frame.content_margin_top = 3.0
	frame.content_margin_right = 3.0
	frame.content_margin_bottom = 3.0
	return frame


static func inventory_heart(filled: bool = true) -> Texture2D:
	if not has_inventory_atlas():
		return null
	var atlas: Texture2D = load(INVENTORY_ATLAS) as Texture2D
	if atlas == null or atlas.get_width() < 368 or atlas.get_height() < 336:
		return null
	var heart := AtlasTexture.new()
	heart.atlas = atlas
	heart.region = Rect2(0 if filled else 80, 0, 16, 16)
	heart.filter_clip = true
	return heart
