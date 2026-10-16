extends Control
## Menu de fazenda, com arte em camadas e fallback quando assets ainda nao foram importados.
## Multiplayer e saves multiplos nao estao ativos: preservar user:// legado.
const WORLD_SCENE := "res://scenes/world/World.tscn"
const SLOTS_SCRIPT = preload("res://scripts/core/save_slots.gd")
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
var _slots: RefCounted
var _slots_ok: bool = false
var _choices: VBoxContainer
var _farm_input: LineEdit
var _player_input: LineEdit
var _popup_fields: VBoxContainer
var _new_game_replaces: bool = false


func _ready() -> void:
	_slots = SLOTS_SCRIPT.new()
	_slots_ok = bool(_slots.call("initialize"))
	_has_farm_art = _texture("farm_logo.png") != null and _texture("farm_frame.png") != null
	_build_background()
	_build_panel()
	_build_popup()
	_update_save_buttons()
	if not _slots_ok:
		_show_message(str(_slots.get("error_message")))
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
		decorated.mouse_entered.connect(_highlight_sprite.bind(decorated, true))
		decorated.mouse_exited.connect(_highlight_sprite.bind(decorated, false))
		decorated.focus_entered.connect(_highlight_sprite.bind(decorated, true))
		decorated.focus_exited.connect(_highlight_sprite.bind(decorated, false))
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


func _highlight_sprite(button: TextureButton, selected: bool) -> void:
	if not is_instance_valid(button) or button.disabled:
		return
	if selected:
		# Brilho real por cima do sprite, mesmo quando o PNG hover se parece com o normal.
		button.self_modulate = Color(1.28, 1.19, 1.03, 1.0)
	else:
		button.self_modulate = Color.WHITE


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
	return _slots_ok and bool(_slots.call("has_save"))


func _update_save_buttons() -> void:
	var has_save: bool = _has_legacy_save()
	(_buttons["Continuar"] as BaseButton).disabled = not has_save
	(_buttons["Carregar jogo"] as BaseButton).disabled = not has_save
	(_buttons["Novo jogo"] as BaseButton).disabled = not _slots_ok
	if has_save:
		(_buttons["Continuar"] as BaseButton).tooltip_text = "Abrir a ultima partida ativa."
		(_buttons["Novo jogo"] as BaseButton).tooltip_text = "Criar outra fazenda ou substituir a atual com backup."
	else:
		(_buttons["Novo jogo"] as BaseButton).tooltip_text = "Comece uma nova aventura."


func _on_continue() -> void:
	if _has_legacy_save():
		_enter_world()


func _on_new_game() -> void:
	if not _slots_ok:
		_show_message("Os saves nao puderam ser verificados. Nenhuma partida sera alterada.")
		return
	if not _has_legacy_save():
		_show_new_game_form(false)
		return
	var free: int = int(_slots.call("first_free_slot"))
	var active: int = int(_slots.call("active_slot"))
	var actions: Array[Dictionary] = []
	if free > 0:
		actions.append({"label": "Criar outra partida (espaco %d)" % free, "call": Callable(self, "_show_new_game_form").bind(false)})
	else:
		actions.append({"label": "Todos os 3 espacos estao ocupados", "disabled": true})
	actions.append({"label": "Substituir partida atual (espaco %d)" % active, "call": Callable(self, "_show_new_game_form").bind(true)})
	_show_actions("Novo jogo", "O que deseja fazer? Sua fazenda atual sera mantida se criar outro espaco.", actions)


func _show_new_game_form(replace: bool) -> void:
	_new_game_replaces = replace
	_show_actions("Nova fazenda", "Informe os nomes da fazenda e do personagem.", [
		{"label": "Confirmar nomes", "call": Callable(self, "_confirm_new_game_form")}
	])
	_popup_fields.visible = true
	var farm_label := Label.new()
	farm_label.text = "Nome da fazenda"
	_popup_fields.add_child(farm_label)
	_farm_input = LineEdit.new()
	_farm_input.name = "FarmName"
	_farm_input.max_length = 32
	_farm_input.text = "Minha fazenda"
	_farm_input.placeholder_text = "Nome da fazenda"
	_popup_fields.add_child(_farm_input)
	var player_label := Label.new()
	player_label.text = "Nome do personagem"
	_popup_fields.add_child(player_label)
	_player_input = LineEdit.new()
	_player_input.name = "CharacterName"
	_player_input.max_length = 32
	_player_input.text = "Aventureiro"
	_player_input.placeholder_text = "Nome do personagem"
	_popup_fields.add_child(_player_input)
	_farm_input.grab_focus()
	_farm_input.select_all()


func _confirm_new_game_form() -> void:
	var farm: String = _farm_input.text.strip_edges()
	var player: String = _player_input.text.strip_edges()
	if farm.is_empty() or player.is_empty():
		_show_message("Preencha o nome da fazenda e o nome do personagem.")
		return
	if _new_game_replaces:
		_show_actions("Confirmar substituicao",
			"Substituir a fazenda atual por \"%s\"?\nUm backup separado sera criado ANTES de iniciar. Os demais espacos nao serao modificados." % farm,
			[{"label": "Sim, substituir com backup", "call": Callable(self, "_start_new_game").bind(farm, player, true)},
			{"label": "Nao, voltar", "call": Callable(self, "_on_new_game")}])
	else:
		_start_new_game(farm, player, false)


func _flush_runtime_saves() -> void:
	# Autoloads ainda guardam dados antigos em memoria. Gravar antes de arquivar.
	GameCalendar.save_session_state()
	ResourceBag.save_session_state()
	TreePersistence.save_session_state()


func _reload_runtime_saves() -> void:
	GameCalendar.reload_session_state()
	ResourceBag.reload_session_state()
	TreePersistence.reload_session_state()


func _start_new_game(farm: String, player: String, replace: bool) -> void:
	var previous_active: int = int(_slots.call("active_slot"))
	if previous_active > 0:
		_flush_runtime_saves()
	if not bool(_slots.call("create_new", farm, player, 0, replace)):
		_show_message("Nao foi possivel iniciar: %s\nSeus saves continuam protegidos." % str(_slots.get("error_message")))
		return
	_reload_runtime_saves()
	_overlay.visible = false
	_update_save_buttons()
	_enter_world()


func _on_load_game() -> void:
	if not _slots_ok:
		return
	var actions: Array[Dictionary] = []
	for slot_record in _slots.call("list_slots"):
		var slot: int = int(slot_record.get("slot", 0))
		var title: String = str(slot_record.get("farm", "Fazenda"))
		var owner: String = str(slot_record.get("player", "Aventureiro"))
		var active: bool = bool(slot_record.get("is_active", false))
		actions.append({
			"label": "Espaco %d: %s - %s%s" % [slot, title, owner, " (atual)" if active else ""],
			"call": Callable(self, "_activate_slot").bind(slot)
		})
	_show_actions("Carregar jogo", "Selecione a fazenda que deseja continuar.", actions)


func _activate_slot(slot: int) -> void:
	if slot != int(_slots.call("active_slot")):
		_flush_runtime_saves()
		if not bool(_slots.call("activate", slot)):
			_show_message("Falha ao carregar: %s\nNenhum save foi descartado." % str(_slots.get("error_message")))
			return
		_reload_runtime_saves()
	_overlay.visible = false
	_update_save_buttons()
	_enter_world()


func _on_multiplayer() -> void:
	_show_message("Multiplayer ainda nao esta disponivel.")


func _on_options() -> void:
	_show_message("Opcoes completas estao em desenvolvimento.\n\nPor enquanto, use as teclas configuradas no jogo.")


func _on_credits() -> void:
	_show_message("Slimekeepers: Lost Valley\nCriado por Helio Conde\n\nJogo independente feito com Godot.\nMenu de fazenda com arte original.")
	# UTF-8 mantido no credito visivel.
	_message.text = _message.text.replace("Helio", "Hélio")


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
	_overlay_card.custom_minimum_size = Vector2(326, 0)
	_overlay_card.add_theme_stylebox_override("panel", _wood_style("normal"))
	center.add_child(_overlay_card)

	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	_overlay_card.add_child(margin)
	var content := VBoxContainer.new()
	content.name = "DialogContent"
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)

	_message = Label.new()
	_message.name = "DialogText"
	_message.custom_minimum_size = Vector2(292, 60)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.add_theme_font_size_override("font_size", 11)
	_message.add_theme_color_override("font_color", Color("#fff1d5"))
	content.add_child(_message)

	_popup_fields = VBoxContainer.new()
	_popup_fields.name = "FormFields"
	_popup_fields.visible = false
	_popup_fields.add_theme_constant_override("separation", 2)
	content.add_child(_popup_fields)

	_choices = VBoxContainer.new()
	_choices.name = "Choices"
	_choices.add_theme_constant_override("separation", 4)
	content.add_child(_choices)

	_popup_close_button = Button.new()
	_popup_close_button.name = "Back"
	_popup_close_button.text = "Cancelar / Voltar"
	_popup_close_button.custom_minimum_size = Vector2(0, 24)
	_popup_close_button.pressed.connect(_dismiss_popup)
	content.add_child(_popup_close_button)


func _show_message(message: String) -> void:
	_show_actions("", message, [])


func _show_actions(_title: String, message: String, actions: Array[Dictionary]) -> void:
	if not _overlay.visible:
		_dialog_return_focus = get_viewport().gui_get_focus_owner()
	_message.text = message
	for child in _choices.get_children():
		_choices.remove_child(child)
		child.queue_free()
	for child in _popup_fields.get_children():
		_popup_fields.remove_child(child)
		child.queue_free()
	_popup_fields.visible = false
	var next_focus: Control = _popup_close_button
	for spec in actions:
		var item := Button.new()
		item.text = str(spec.get("label", "Continuar"))
		item.name = "Choice_" + str(_choices.get_child_count())
		item.custom_minimum_size = Vector2(0, 27)
		item.add_theme_font_size_override("font_size", 12)
		item.disabled = bool(spec.get("disabled", false))
		var handler: Callable = spec.get("call", Callable())
		if handler.is_valid():
			item.pressed.connect(handler)
		_choices.add_child(item)
		if next_focus == _popup_close_button and not item.disabled:
			next_focus = item
	_overlay.visible = true
	next_focus.grab_focus()


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
