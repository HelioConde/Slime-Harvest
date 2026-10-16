extends Control
## Menu de fazenda, com arte em camadas e fallback quando assets ainda nao foram importados.
## Multiplayer e saves multiplos nao estao ativos: preservar user:// legado.
const WORLD_SCENE := "res://scenes/world/World.tscn"
const WALLPAPER := "res://assets/ui/main_menu/vale_encantado.png"
const FARM_WALLPAPER := "res://assets/ui/main_menu/fazenda_wallpaper.png"
const ART_DIR := "res://assets/ui/main_menu/"
const LEGACY_SAVES := [
	"user://house_terrain_test.json",
	"user://slimekeepers_calendar_v1.json",
	"user://slimekeepers_resources_v1.json",
	"user://slimekeepers_world_hoeing_v1.json",
	"user://slimekeepers_felled_trees_v1.json",
]

const BUTTON_ART := {
	"Continuar": "continue",
	"Novo jogo": "new_game",
	"Carregar jogo": "load_game",
	"Multiplayer": "multiplayer",
	"Opções": "options",
	"Créditos": "credits",
	"Sair": "exit",
}
var _buttons: Dictionary = {}
var _overlay: ColorRect
var _overlay_card: PanelContainer
var _message: Label
var _dialog_return_focus: Control
var _popup_close_button: Button
var _has_farm_art: bool = false


func _ready() -> void:
	_has_farm_art = _texture("farm_logo.png") != null and _texture("farm_frame.png") != null
	_build_background()
	_build_panel()
	_build_popup()
	_update_save_buttons()
	(_buttons["Novo jogo"] as BaseButton).grab_focus()


func _texture(file_name: String) -> Texture2D:
	var resource_path: String = ART_DIR + file_name
	if not ResourceLoader.exists(resource_path):
		return null
	return load(resource_path) as Texture2D


func _add_image(name: String, tex: Texture2D, position_xy: Vector2, image_size: Vector2) -> TextureRect:
	var img := TextureRect.new()
	img.name = name
	img.position = position_xy
	img.size = image_size
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	img.texture = tex
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_SCALE
	img.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(img)
	return img


func _build_background() -> void:
	var fallback := ColorRect.new()
	fallback.name = "BackgroundFallback"
	fallback.color = Color("#315346")
	fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fallback)

	var image_path: String = FARM_WALLPAPER if ResourceLoader.exists(FARM_WALLPAPER) else WALLPAPER
	if ResourceLoader.exists(image_path):
		var photo := TextureRect.new()
		photo.name = "ValleyWallpaper"
		photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		photo.texture = load(image_path) as Texture2D
		photo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(photo)
	else:
		push_warning("MainMenu: wallpaper nao encontrado. Instale o pacote de sprites em assets/ui/main_menu/.")

	var shade := ColorRect.new()
	shade.name = "MenuShadow"
	shade.position = Vector2.ZERO
	shade.size = Vector2(246, 360)
	shade.color = Color(0.06, 0.12, 0.08, 0.22 if _has_farm_art else 0.78)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	# Camada reservada para os futuros slimes animados: nao embutir no wallpaper.
	var slimes := Control.new()
	slimes.name = "SlimeAnimationLayer"
	slimes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slimes.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(slimes)


func _build_panel() -> void:
	if _has_farm_art:
		_add_image("FarmMenuFrame", _texture("farm_frame.png"), Vector2(14, 82), Vector2(225, 275))
		_add_image("FarmMenuLogo", _texture("farm_logo.png"), Vector2(18, 6), Vector2(227, 81))
	else:
		_build_title_fallback()

	var root := Control.new()
	root.name = "MenuOptions"
	root.position = Vector2(30, 98)
	root.size = Vector2(208, 243)
	add_child(root)

	var actions := [
		["Continuar", Callable(self, "_on_continue")],
		["Novo jogo", Callable(self, "_on_new_game")],
		["Carregar jogo", Callable(self, "_on_load_game")],
		["Multiplayer", Callable(self, "_on_multiplayer")],
		["Opções", Callable(self, "_on_options")],
		["Sair", Callable(self, "_on_exit")],
	]
	for i in range(actions.size()):
		var entry: Array = actions[i]
		_make_button(root, str(entry[0]), entry[1], Vector2(0, float(i) * 36.0), Vector2(198, 33))
	var credits := _make_button(root, "Créditos", _on_credits, Vector2(19, 218), Vector2(160, 24))
	credits.tooltip_text = "Quem criou o jogo"
	var multi := _buttons["Multiplayer"] as BaseButton
	multi.disabled = true
	multi.tooltip_text = "Em breve: multiplayer sera adicionado sem misturar saves locais e de rede."

	if not _has_farm_art:
		var foot := Label.new()
		foot.name = "VersionLabel"
		foot.text = "Versao 0.1.0 • Multiplayer: em breve"
		foot.position = Vector2(16, 343)
		foot.size = Vector2(218, 16)
		foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		foot.add_theme_font_size_override("font_size", 9)
		foot.add_theme_color_override("font_color", Color("#fff0d3"))
		add_child(foot)


func _build_title_fallback() -> void:
	var title := Label.new()
	title.name = "GameTitle"
	title.text = "SLIMEKEEPERS"
	title.position = Vector2(13, 18)
	title.size = Vector2(232, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("#f4d48a"))
	title.add_theme_constant_override("outline_size", 3)
	title.add_theme_color_override("font_outline_color", Color("#291d13"))
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "—  LOST VALLEY  —"
	subtitle.position = Vector2(30, 61)
	subtitle.size = Vector2(200, 18)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color("#f4dfb7"))
	add_child(subtitle)


func _make_button(parent: Control, label: String, callback: Callable, at: Vector2, dimensions: Vector2) -> BaseButton:
	var code: String = str(BUTTON_ART[label])
	var normal: Texture2D = _texture("btn_" + code + ".png")
	var button: BaseButton
	if normal != null:
		var decorated := TextureButton.new()
		decorated.ignore_texture_size = true
		decorated.stretch_mode = TextureButton.STRETCH_SCALE
		decorated.texture_normal = normal
		decorated.texture_hover = _texture("btn_" + code + "_hover.png")
		decorated.texture_pressed = _texture("btn_" + code + "_pressed.png")
		decorated.texture_disabled = _texture("btn_" + code + "_disabled.png")
		decorated.texture_focused = _texture("btn_" + code + "_hover.png")
		button = decorated
	else:
		var simple := Button.new()
		simple.text = label
		simple.add_theme_font_size_override("font_size", 14)
		simple.add_theme_color_override("font_color", Color("#f8ebcc"))
		simple.add_theme_color_override("font_disabled_color", Color("#9aa09a"))
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			simple.add_theme_stylebox_override(state, _wood_style(state))
		button = simple
	button.name = label.replace(" ", "")
	button.position = at
	button.size = dimensions
	button.custom_minimum_size = dimensions
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = label
	button.pressed.connect(callback)
	parent.add_child(button)
	_buttons[label] = button
	return button


func _wood_style(state: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#6a4124")
	if state in ["hover", "focus"]:
		style.bg_color = Color("#335b3c")
	elif state == "pressed":
		style.bg_color = Color("#3a271b")
	elif state == "disabled":
		style.bg_color = Color("#343a36")
	style.border_color = Color("#e5bb6d") if state in ["hover", "focus"] else Color("#a87b43")
	style.set_border_width_all(2 if state in ["hover", "focus"] else 1)
	style.set_corner_radius_all(5)
	return style


func _has_legacy_save() -> bool:
	for path in LEGACY_SAVES:
		if FileAccess.file_exists(path):
			return true
	return false


func _update_save_buttons() -> void:
	var has_save: bool = _has_legacy_save()
	(_buttons["Continuar"] as BaseButton).disabled = not has_save
	(_buttons["Carregar jogo"] as BaseButton).disabled = not has_save
	if has_save:
		(_buttons["Continuar"] as BaseButton).tooltip_text = "Abrir o mundo com o salvamento atual."
		(_buttons["Novo jogo"] as BaseButton).tooltip_text = "Protegido: nao sobrescrever o salvamento existente."
	else:
		(_buttons["Novo jogo"] as BaseButton).tooltip_text = "Iniciar sua primeira partida."


func _on_continue() -> void:
	if _has_legacy_save():
		_enter_world()


func _on_new_game() -> void:
	if _has_legacy_save():
		_show_message("Ja existe uma partida local. Novo jogo esta protegido ate que existam saves independentes.\n\nUse Continuar para abrir sua fazenda atual.")
	else:
		_enter_world()


func _on_load_game() -> void:
	if _has_legacy_save():
		_show_message("Existe uma partida local. Use Continuar para carrega-la.\n\nOs tres espacos separados serao ativados junto do gerenciador de saves.")


func _on_multiplayer() -> void:
	_show_message("Multiplayer ainda nao esta disponivel.")


func _on_options() -> void:
	_show_message("Opcoes completas estao em desenvolvimento.\n\nPor enquanto, use as teclas configuradas no jogo.")


func _on_credits() -> void:
	_show_message("Slimekeepers: Lost Valley\nJogo independente feito com Godot.\n\nMenu de fazenda com sprites originais.")


func _on_exit() -> void:
	get_tree().quit()


func _enter_world() -> void:
	var result: Error = get_tree().change_scene_to_file(WORLD_SCENE)
	if result != OK:
		_show_message("Nao foi possivel abrir o mundo (erro %d)." % result)


func _build_popup() -> void:
	_overlay = ColorRect.new()
	_overlay.name = "PopupOverlay"
	_overlay.color = Color(0.0, 0.0, 0.0, 0.65)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	add_child(_overlay)

	var center := CenterContainer.new()
	center.name = "PopupCenter"
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)

	_overlay_card = PanelContainer.new()
	_overlay_card.name = "Dialog"
	_overlay_card.custom_minimum_size = Vector2(326, 160)
	_overlay_card.add_theme_stylebox_override("panel", _wood_style("normal"))
	center.add_child(_overlay_card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	_overlay_card.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	margin.add_child(content)

	_message = Label.new()
	_message.name = "DialogText"
	_message.custom_minimum_size = Vector2(292, 100)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.add_theme_font_size_override("font_size", 11)
	_message.add_theme_color_override("font_color", Color("#fff1d5"))
	content.add_child(_message)

	_popup_close_button = Button.new()
	_popup_close_button.name = "Back"
	_popup_close_button.text = "Voltar"
	_popup_close_button.custom_minimum_size = Vector2(0, 25)
	_popup_close_button.pressed.connect(_dismiss_popup)
	content.add_child(_popup_close_button)


func _show_message(message: String) -> void:
	_dialog_return_focus = get_viewport().gui_get_focus_owner()
	_message.text = message
	_overlay.visible = true
	_popup_close_button.grab_focus()


func _dismiss_popup() -> void:
	_overlay.visible = false
	if is_instance_valid(_dialog_return_focus):
		_dialog_return_focus.grab_focus()
	else:
		(_buttons["Novo jogo"] as BaseButton).grab_focus()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and _overlay.visible:
		_dismiss_popup()
		get_viewport().set_input_as_handled()
