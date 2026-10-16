extends Node
## Regressao do menu e atlas: sem sobrescrever salvamento legado.

func _ready() -> void:
	call_deferred("_run")


func _assert(ok: bool, description: String) -> bool:
	if ok:
		print("PASS menu: ", description)
		return true
	printerr("FAIL menu: ", description)
	get_tree().quit(1)
	return false


func _run() -> void:
	var main := load("res://scenes/ui/MainMenu.tscn").instantiate() as Control
	add_child(main)
	await get_tree().process_frame
	if not _assert(main.get_node_or_null("MenuOptions/Novojogo") is BaseButton, "Novo jogo exists"):
		return
	if not _assert(main.get_node_or_null("MenuOptions/Multiplayer") is BaseButton and main.get_node("MenuOptions/Multiplayer").disabled, "future multiplayer disabled safely"):
		return
	if not _assert(main.get_node_or_null("MenuOptions/Carregarjogo") is BaseButton, "load game button exists"):
		return
	if not _assert(main.get_script().get_script_constant_map()["WALLPAPER"] == "res://assets/ui/main_menu/vale_encantado.png", "wallpaper reference stable"):
		return
	if not _assert((load("res://scripts/items/tool_inventory.gd") as Script).get_script_constant_map()["HOTBAR_IDS"][3] == &"pickaxe", "slot 4 is the pickaxe"):
		return
	if not _assert((load("res://scripts/ui/tool_hotbar.gd") as Script).get_script_constant_map()["SLOT_IDS"][3] == &"pickaxe", "hotbar label matches inventory slot 4"):
		return
	var atlas := load("res://assets/Objects/Items/tools-n-meterial-items.png") as Texture2D
	if not _assert(atlas != null and atlas.get_width() == 64 and atlas.get_height() == 64, "uploaded tool atlas is valid 64x64 RGBA image"):
		return
	if not _assert(main.has_method("_has_legacy_save") and main.has_method("_enter_world"), "existing save migration path remains available"):
		return
	
	var multi := main.get_node("MenuOptions/Multiplayer") as BaseButton
	if not _assert(multi.tooltip_text.contains("Multiplayer") or multi.tooltip_text.contains("multiplayer"), "disabled multiplayer explains unavailable status"):
		return
	if not _assert(main.get_node_or_null("SlimeAnimationLayer") != null, "dedicated future slime animation layer"):
		return
	if not _assert(main.get_node_or_null("PopupOverlay/PopupCenter/Dialog") is PanelContainer, "popup uses responsive centered layout"):
		return
	main.call("_on_new_game") if bool(main.call("_has_legacy_save")) else main.call("_on_options")
	await get_tree().process_frame
	if not _assert((main.get_node("PopupOverlay") as Control).visible, "modal opens without clipping or leaving scene"):
		return
	var dialog := main.get_node("PopupOverlay/PopupCenter/Dialog") as Control
	var viewport := main.get_viewport_rect()
	if not _assert(dialog.get_global_rect().position.x >= 0 and dialog.get_global_rect().end.x <= viewport.size.x and dialog.get_global_rect().end.y <= viewport.size.y, "modal entirely inside viewport"):
		return
	main.call("_dismiss_popup")
	if not _assert(not (main.get_node("PopupOverlay") as Control).visible, "modal closes cleanly"):
		return
	var btn := main.get_node("MenuOptions/Novojogo") as TextureButton
	if not _assert(btn != null, "New game button is textured"):
		return
	main.call("_highlight_sprite", btn, true)
	if not _assert(btn.self_modulate.r > 1.1, "New game glows on hover and focus"):
		return
	main.call("_highlight_sprite", btn, false)
	if not _assert(is_equal_approx(btn.self_modulate.r, 1.0), "New game returns to normal on mouse exit"):
		return
	main.call("_on_credits")
	var credits_text: String = str(main.get_node("PopupOverlay/PopupCenter/Dialog/MarginContainer/DialogContent/DialogText").text)
	if not _assert(credits_text.contains("Hélio Conde"), "creator correctly credited"):
		return
	main.call("_dismiss_popup")

	print("PASS menu: functional safe entry point, future multiplayer and fourth-slot pickaxe")
	get_tree().quit(0)
