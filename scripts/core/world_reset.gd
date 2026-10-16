extends Node
## F1 no debug: reset seguro do mapa sem alterar World.tscn ou outros slots.
const SAVE_SLOTS = preload("res://scripts/core/save_slots.gd")
const WORLD_SCENE := "res://scenes/world/World.tscn"
var _overlay: ColorRect
var _message: Label
var _accept: Button
var _cancel: Button
var _player: Node
var _old_controls_enabled: bool = true
var _busy := false

func _ready() -> void:
	if not OS.is_debug_build():
		set_process_unhandled_key_input(false)
		return
	_build_prompt()

func _is_world_open() -> bool:
	var scene: Node = get_tree().current_scene
	return scene != null and scene.scene_file_path == WORLD_SCENE

func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_ESCAPE and _overlay != null and _overlay.visible:
		_hide_prompt()
		get_viewport().set_input_as_handled()
		return
	if key.keycode != KEY_F1 or not _is_world_open() or _busy:
		return
	if _overlay != null and not _overlay.visible:
		_show_prompt()
	get_viewport().set_input_as_handled()

func _build_prompt() -> void:
	var hud := CanvasLayer.new()
	hud.name = "WorldResetHUD"
	hud.layer = 100
	add_child(hud)
	_overlay = ColorRect.new()
	_overlay.name = "ResetOverlay"
	_overlay.color = Color(0.0, 0.0, 0.0, 0.73)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	hud.add_child(_overlay)
	var center := CenterContainer.new()
	center.name = "Center"
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.name = "ConfirmPanel"
	panel.custom_minimum_size = Vector2(345, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1c3227")
	style.border_color = Color("#c8a96d")
	style.set_border_width_all(2)
	style.set_corner_radius_all(9)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var padding := MarginContainer.new()
	padding.name = "Padding"
	padding.add_theme_constant_override("margin_left", 14)
	padding.add_theme_constant_override("margin_top", 14)
	padding.add_theme_constant_override("margin_right", 14)
	padding.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(padding)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 9)
	padding.add_child(column)
	var heading := Label.new()
	heading.text = "REINICIAR MAPA? (F1)"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 18)
	heading.add_theme_color_override("font_color", Color("#f1d58e"))
	column.add_child(heading)
	_message = Label.new()
	_message.name = "ResetDescription"
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.custom_minimum_size = Vector2(305, 96)
	_message.add_theme_font_size_override("font_size", 12)
	_message.add_theme_color_override("font_color", Color("#f9edda"))
	column.add_child(_message)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	column.add_child(buttons)
	_cancel = Button.new()
	_cancel.name = "Cancel"
	_cancel.text = "Cancelar (Esc)"
	_cancel.custom_minimum_size = Vector2(130, 30)
	_cancel.pressed.connect(_hide_prompt)
	buttons.add_child(_cancel)
	_accept = Button.new()
	_accept.name = "Confirm"
	_accept.text = "Confirmar reset"
	_accept.custom_minimum_size = Vector2(130, 30)
	_accept.pressed.connect(_reset_confirmed)
	buttons.add_child(_accept)

func _show_prompt() -> void:
	if not _is_world_open() or _busy:
		return
	_player = get_tree().current_scene.get_node_or_null("Actors/Player")
	if _player != null:
		_old_controls_enabled = bool(_player.get("controls_enabled"))
		_player.call("set_controls_enabled", false)
	_message.text = "Reinicia casa, solo arado, arvores, pedras, flores e objetos do mapa atual.\n\nMantem inventario, dia, equipamento e outras fazendas. Cria backup completo antes."
	_overlay.visible = true
	_accept.visible = true
	_cancel.text = "Cancelar (Esc)"
	_cancel.grab_focus()

func _hide_prompt() -> void:
	if _busy or _overlay == null:
		return
	_overlay.visible = false
	if is_instance_valid(_player) and _player.has_method("set_controls_enabled"):
		_player.call("set_controls_enabled", _old_controls_enabled)
	_player = null

func _reset_confirmed() -> void:
	if _busy or not _is_world_open():
		return
	_busy = true
	_accept.disabled = true
	_cancel.disabled = true
	_message.text = "Salvando backup e reiniciando mapa..."
	GameCalendar.save_session_state()
	ResourceBag.save_session_state()
	TreePersistence.save_session_state()
	# Descarregar antes: WorldHoeing salva ao sair e nao pode regravar estado antigo.
	var old_scene: Node = get_tree().current_scene
	get_tree().current_scene = null
	old_scene.queue_free()
	await get_tree().process_frame
	_player = null
	var saves: RefCounted = SAVE_SLOTS.new()
	var ok: bool = bool(saves.call("initialize"))
	if ok:
		ok = bool(saves.call("reset_active_world"))
	if ok:
		ResourceBag.reload_session_state()
		TreePersistence.reload_session_state()
		GameCalendar.reload_session_state()
	var reason: String = str(saves.get("error_message"))
	var result: Error = get_tree().change_scene_to_file(WORLD_SCENE)
	_busy = false
	_accept.disabled = false
	_cancel.disabled = false
	if result != OK:
		_message.text = "Nao foi possivel recarregar o World (%d)." % result
		_overlay.visible = true
		_accept.visible = false
		_cancel.text = "Fechar"
		return
	if ok:
		_overlay.visible = false
		print("PASS F1: mapa reiniciado; backup: ", saves.call("backup_path"))
	else:
		_message.text = "Reset cancelado: %s\n\nO mundo foi recarregado sem apagar o progresso." % reason
		_overlay.visible = true
		_accept.visible = false
		_cancel.text = "Fechar"
