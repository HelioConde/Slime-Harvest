extends Control
## Menu leve: nunca instancia o World atras da interface.
## Multiplayer futuro reservado, sem fingir que existe rede/salas.
const WORLD_SCENE := "res://scenes/world/World.tscn"
const WALLPAPER := "res://assets/ui/main_menu/vale_encantado.jpg"
const LEGACY_SAVES := [
	"user://house_terrain_test.json",
	"user://slimekeepers_calendar_v1.json",
	"user://slimekeepers_resources_v1.json",
	"user://slimekeepers_world_hoeing_v1.json",
	"user://slimekeepers_felled_trees_v1.json",
]

var _buttons: Dictionary = {}
var _panel: PanelContainer
var _overlay: ColorRect
var _overlay_card: PanelContainer
var _message: Label


func _ready() -> void:
	_build_background()
	_build_panel()
	_build_popup()
	_update_save_buttons()
	(_buttons["Novo jogo"] as Button).grab_focus()


func _build_background() -> void:
	var background := ColorRect.new()
	background.name = "BackgroundFallback"
	background.color = Color("#315346")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	if ResourceLoader.exists(WALLPAPER):
		var photo := TextureRect.new()
		photo.name = "ValleyWallpaper"
		photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		photo.texture = load(WALLPAPER) as Texture2D
		add_child(photo)
	else:
		push_warning("MainMenu: wallpaper indisponivel; importe vale_encantado.jpg na pasta assets/ui/main_menu.")

	var shade := ColorRect.new()
	shade.name = "MenuShadow"
	shade.anchor_bottom = 1.0
	shade.offset_left = 0.0
	shade.offset_right = 242.0
	shade.offset_top = 0.0
	shade.offset_bottom = 0.0
	shade.color = Color(0.06, 0.13, 0.11, 0.78)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)


func _build_panel() -> void:
	var root := VBoxContainer.new()
	root.name = "MenuOptions"
	root.position = Vector2(13, 12)
	root.size = Vector2(214, 336)
	root.add_theme_constant_override("separation", 5)
	add_child(root)

	var brand := Label.new()
	brand.name = "GameTitle"
	brand.text = "SLIMEKEEPERS"
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand.add_theme_font_size_override("font_size", 26)
	brand.add_theme_color_override("font_color", Color("#f4d48a"))
	brand.add_theme_constant_override("outline_size", 4)
	brand.add_theme_color_override("font_outline_color", Color("#2c2013"))
	root.add_child(brand)
	var subtitle := Label.new()
	subtitle.text = "—  LOST VALLEY  —"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color("#efe3c3"))
	root.add_child(subtitle)
	root.add_child(HSeparator.new())

	_make_button(root, "Continuar", _on_continue)
	_make_button(root, "Novo jogo", _on_new_game)
	_make_button(root, "Carregar jogo", _on_load_game)
	var multi := _make_button(root, "Multiplayer", _on_multiplayer)
	multi.disabled = true
	multi.tooltip_text = "Em breve. O jogo sera preparado para multiplayer futuramente."
	_make_button(root, "Opções", _on_options)
	_make_button(root, "Créditos", _on_credits)
	_make_button(root, "Sair", _on_exit)

	var foot := Label.new()
	foot.text = "Versao 0.1.0   •   Multiplayer: em breve"
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_font_size_override("font_size", 8)
	foot.add_theme_color_override("font_color", Color("#dfd7be"))
	root.add_child(foot)


func _make_button(parent: VBoxContainer, label: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = label.replace(" ", "")
	button.text = label
	button.custom_minimum_size = Vector2(206, 31)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color("#f8ebcc"))
	button.add_theme_color_override("font_disabled_color", Color("#9aa09a"))
	button.add_theme_color_override("font_hover_color", Color("#ffe6a4"))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, _wood_style(state))
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
	style.content_margin_left = 8
	style.content_margin_right = 8
	return style


func _has_legacy_save() -> bool:
	for path in LEGACY_SAVES:
		if FileAccess.file_exists(path):
			return true
	return false


func _update_save_buttons() -> void:
	var has_save := _has_legacy_save()
	(_buttons["Continuar"] as Button).disabled = not has_save
	(_buttons["Carregar jogo"] as Button).disabled = not has_save
	if has_save:
		(_buttons["Continuar"] as Button).tooltip_text = "Abrir o mundo com o salvamento atual."
		(_buttons["Novo jogo"] as Button).tooltip_text = "Salvamento existente: protege dados contra substituicao."
	else:
		(_buttons["Novo jogo"] as Button).tooltip_text = "Iniciar sua primeira partida."


func _on_continue() -> void:
	if not _has_legacy_save():
		return
	_enter_world()


func _on_new_game() -> void:
	if _has_legacy_save():
		_show_message("Ja existe uma partida local. Novo jogo ficara bloqueado ate criarmos saves separados. Use Continuar para proteger sua fazenda.")
	else:
		_enter_world()


func _on_load_game() -> void:
	if not _has_legacy_save():
		return
	_show_message("Partida local existente. Use CONTINUAR para carregar. Os 3 espacos independentes serao habilitados junto ao gerenciador de saves.")


func _on_multiplayer() -> void:
	_show_message("Multiplayer ainda em desenvolvimento.")


func _on_options() -> void:
	_show_message("Video: Alt+Enter alterna tela cheia. Som e controles personalizados serao adicionados aqui. A jogabilidade continua com as teclas atuais.")


func _on_credits() -> void:
	_show_message("Slimekeepers: Lost Valley\nJogo independente em desenvolvimento no Godot.\nArte do menu baseada no wallpaper original do projeto.")


func _on_exit() -> void:
	get_tree().quit()


func _enter_world() -> void:
	var result: Error = get_tree().change_scene_to_file(WORLD_SCENE)
	if result != OK:
		_show_message("Nao foi possivel abrir o mundo (%d)." % result)


func _build_popup() -> void:
	_overlay = ColorRect.new()
	_overlay.name = "PopupOverlay"
	_overlay.color = Color(0, 0, 0, 0.65)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.visible = false
	add_child(_overlay)
	_overlay_card = PanelContainer.new()
	_overlay_card.name = "Dialog"
	_overlay_card.set_anchors_preset(Control.PRESET_CENTER)
	_overlay_card.position = Vector2(168, 110)
	_overlay_card.size = Vector2(304, 140)
	_overlay_card.add_theme_stylebox_override("panel", _wood_style("normal"))
	_overlay.add_child(_overlay_card)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	_overlay_card.add_child(content)
	_message = Label.new()
	_message.custom_minimum_size = Vector2(285, 88)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.add_theme_font_size_override("font_size", 11)
	_message.add_theme_color_override("font_color", Color("#fff1d5"))
	content.add_child(_message)
	var back := Button.new()
	back.text = "Voltar"
	back.pressed.connect(_dismiss_popup)
	content.add_child(back)


func _show_message(message: String) -> void:
	_message.text = message
	_overlay.visible = true


func _dismiss_popup() -> void:
	_overlay.visible = false
	(_buttons["Novo jogo"] as Button).grab_focus()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and _overlay.visible:
		_dismiss_popup()
		get_viewport().set_input_as_handled()
