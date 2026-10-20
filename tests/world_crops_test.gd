extends Node
## Teste de sementes, rega, dias, colheita, save e mochila isolados do World.
const SOIL = preload("res://tests/mock_tilled_soil.gd")
const CROPS = preload("res://scripts/world/world_crops.gd")
const BAG = preload("res://scripts/ui/backpack_panel.gd")
const FILE := "user://slimekeepers_test_world_crops.json"

var _failed := false


func _ready() -> void:
	call_deferred("_run")


func _check(value: bool, message: String) -> void:
	if value:
		print("PASS world-crops: ", message)
	else:
		_failed = true
		printerr("FAIL world-crops: ", message)


func _run() -> void:
	if FileAccess.file_exists(FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE))
	var ground := SOIL.new() as TileMapLayer
	ground.name = "MockSoil"
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(16, 16)
	ground.tile_set = tiles
	add_child(ground)
	var crops := CROPS.new() as Node2D
	crops.name = "WorldCrops"
	crops.set("tilled_soil_path", NodePath("../MockSoil"))
	crops.set("save_path", FILE)
	add_child(crops)
	var cell := Vector2i(3, 4)
	_check(str(crops.call("try_hoe", cell)).contains("Prepare"), "no planting outside prepared soil")
	ground.set("allowed", {cell: true})
	_check(bool(crops.call("select_variety", 1)), "chooses pink seeds")
	_check(not bool(crops.call("select_variety", 5)), "rejects invalid variety")
	_check(str(crops.call("try_hoe", cell)).contains("plantada"), "hoe plants on tilled cell")
	_check(int(crops.call("get_crop", cell).get("variety", -1)) == 1, "plant uses selected seed, not cell coordinates")
	_check(int(crops.call("get_seed_count")) == 11, "seed stock decremented once")
	_check(str(crops.call("try_hoe", cell)).contains("crescendo"), "no early harvest")
	_check(str(crops.call("try_water", cell)).contains("regada"), "watering changes persistent crop")
	_check(str(crops.call("try_water", cell)).contains("ja esta"), "cannot water twice")
	var start_day: int = GameCalendar.day
	crops.call("_on_day_changed", start_day + 3)
	_check(int(crops.call("get_crop", cell).get("stage", -1)) == 1, "stage one after three days")
	crops.call("_on_day_changed", start_day + 9)
	_check(int(crops.call("get_crop", cell).get("stage", -1)) == 3, "fully grown at nine days")
	_check(FileAccess.file_exists(FILE), "persistent crops saved to separate JSON")
	var before: Dictionary = ResourceBag.get_all_counts()
	var old_wallet: int = ResourceBag.get_coins()
	var flower_id: StringName = &"flower_pink"
	var original: int = ResourceBag.get_count(flower_id)
	_check(str(crops.call("try_hoe", cell)).contains("Colhido"), "mature flower harvested")
	_check(int(crops.call("get_seed_count")) == 12, "harvest returns one seed")
	_check(int(crops.call("get_harvest_count")) == 1, "harvest progress tracked")
	_check(ResourceBag.get_count(flower_id) == original + 1, "flower credited once to ResourceBag")
	_check(str(crops.call("try_hoe", cell)).contains("plantada"), "same tile can be replanted")
	_check(ResourceBag.get_count(flower_id) == original + 1, "no duplicate reward for replanting")
	_check(ResourceBag.sell_item(&"trunk", 1) == 0, "materials cannot be sold as flowers")
	_check(ResourceBag.sell_item(flower_id, 0) == 0, "zero-quantity sale rejected")
	_check(ResourceBag.sell_item(flower_id, 100000) == 0, "over-selling rejected")
	_check(ResourceBag.sell_item(flower_id, 1) == 7, "pink flower sells for seven coins")
	_check(ResourceBag.get_count(flower_id) == original, "sold flower removed from same inventory")
	_check(ResourceBag.get_coins() == old_wallet + 7, "wallet credited once")
	_check(not bool(crops.call("buy_seeds", 0)), "zero-quantity purchase rejected")
	_check(not bool(crops.call("buy_seeds", 100)), "oversized purchase rejected")
	_check(bool(crops.call("buy_seeds", 1)), "buy one seed with three coins")
	_check(int(crops.call("get_seed_count")) == 12, "purchased seed added")
	_check(ResourceBag.get_coins() == old_wallet + 4, "wallet charged exactly once")
	# Restaurar ResourceBag antes de sair para nao modificar um save real.
	ResourceBag.set("_counts", before)
	ResourceBag.set("_coins", old_wallet)
	ResourceBag.save_session_state()
	var saved: String = FileAccess.get_file_as_string(FILE)
	_check(saved.contains("\"version\":1"), "versioned farming save")
	crops.queue_free()
	await get_tree().process_frame
	var restored := CROPS.new() as Node2D
	restored.name = "WorldCropsRestored"
	restored.set("tilled_soil_path", NodePath("../MockSoil"))
	restored.set("save_path", FILE)
	add_child(restored)
	_check(int(restored.call("get_seed_count")) == 12, "purchased seed amount reloads")
	_check(int(restored.call("get_selected_variety")) == 1, "selected seed remains in save")
	_check(not restored.call("get_crop", cell).is_empty(), "crop reloads in same cell")
	var bag := BAG.new() as CanvasLayer
	# Construir a grade tambem sem instanciar Player nem tocar nos saves.
	add_child(bag)
	_check(bag.get_node_or_null("BackpackOverlay") != null, "backpack interface exists")
	_check(bag.get_node_or_null("BackpackOverlay/Center/BackpackWindow") == null or bag.get("_coins_label") != null, "wallet UI built")
	bag.queue_free()
	restored.queue_free()
	await get_tree().process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE))
	print("PASS world-crops: end" if not _failed else "FAIL world-crops")
	get_tree().quit(1 if _failed else 0)
