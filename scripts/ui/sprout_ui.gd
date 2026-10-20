extends RefCounted
## Carrega a UI Sprout Lands instalada localmente sem criar dependencia obrigatoria.
## O tema deve ser instalado com tools/install_sprout_ui.py; nao publique o atlas
## original no repositorio publico sem permissao de redistribuicao.
const THEME_PATH := "res://assets/ui/sprout_lands/sprout_theme.tres"


static func get_theme() -> Theme:
	if not ResourceLoader.exists(THEME_PATH):
		return null
	return load(THEME_PATH) as Theme


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
