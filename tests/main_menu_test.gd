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
	if not _assert(main.get_node_or_null("MenuOptions/NovoJogo") is Button, "Novo jogo exists"):
		return
	if not _assert(main.get_node_or_null("MenuOptions/Multiplayer") is Button and main.get_node("MenuOptions/Multiplayer").disabled, "future multiplayer disabled safely"):
		return
	if not _assert(main.get_node_or_null("MenuOptions/Carregarjogo") is Button, "load game button exists"):
		return
	if not _assert(main.get("WALLPAPER") == "res://assets/ui/main_menu/vale_encantado.png", "wallpaper reference stable"):
		return
	if not _assert(load("res://scripts/items/tool_inventory.gd").HOTBAR_IDS[3] == &"pickaxe", "slot 4 is the pickaxe"):
		return
	if not _assert(load("res://scripts/ui/tool_hotbar.gd").SLOT_IDS[3] == &"pickaxe", "hotbar label matches inventory slot 4"):
		return
	var atlas := load("res://assets/Objects/Items/tools-n-meterial-items.png") as Texture2D
	if not _assert(atlas != null and atlas.get_width() == 64 and atlas.get_height() == 64, "uploaded tool atlas is valid 64x64 RGBA image"):
		return
	if not _assert(main.has_method("_has_legacy_save") and main.has_method("_enter_world"), "existing save migration path remains available"):
		return
	print("PASS menu: functional safe entry point, future multiplayer and fourth-slot pickaxe")
	get_tree().quit(0)
