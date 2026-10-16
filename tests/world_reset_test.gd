extends Node
## Teste de reset de mapa usa somente um diretorio isolado em user://.
const SLOTS = preload("res://scripts/core/save_slots.gd")

func _ready() -> void:
	call_deferred("_run")

func _check(condition: bool, title: String) -> bool:
	if condition:
		print("PASS world-reset: ", title)
		return true
	printerr("FAIL world-reset: ", title)
	get_tree().quit(1)
	return false

func _write(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.close()
	return true

func _run() -> void:
	var path: String = "user://world_reset_test_%d/" % Time.get_ticks_usec()
	if not _check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path)) == OK, "sandbox created"):
		return
	var res_file: String = path + "slimekeepers_resources_v1.json"
	var house: String = path + "house_terrain_test.json"
	var hoe: String = path + "slimekeepers_world_hoeing_v1.json"
	var trees: String = path + "slimekeepers_felled_trees_v1.json"
	var calendar: String = path + "slimekeepers_calendar_v1.json"
	var equipment: String = path + "slimekeepers_equipment_v1.json"
	var original_resources := "{\"version\":1,\"counts\":{\"wood\":25},\"claimed\":{\"rock_12\":true},\"drops\":{\"d1\":{\"item\":\"trunk\"}},\"mining_levels\":{\"rock\":0},\"picked_plants\":{\"bush\":1}}"
	if not _check(_write(res_file, original_resources) and _write(house, "{\"floor\":[1]}") and _write(hoe, "{\"cells\":[1]}") and _write(trees, "{\"felled\":{\"t1\":true}}") and _write(calendar, "{\"day\":9}") and _write(equipment, "{\"equipped\":\"pickaxe\"}"), "initial world state populated"):
		return
	var slots: RefCounted = SLOTS.new(path)
	if not _check(bool(slots.call("initialize")), "legacy farm migrated"):
		return
	var slot_one: String = str(slots.call("slot_metadata", 1).get("snapshot", ""))
	if not _check(not slot_one.is_empty(), "legacy farm backed up"):
		return
	if not _check(bool(slots.call("create_new", "Testing", "QA")), "second slot created"):
		return
	var second_resource := "{\"version\":1,\"counts\":{\"wood\":9,\"stone\":4},\"claimed\":{\"bush\":true},\"drops\":{\"d2\":{\"item\":\"stone\"}},\"mining_levels\":{\"rock\":1},\"picked_plants\":{\"bush\":3}}"
	if not _check(_write(res_file, second_resource) and _write(house, "{\"farm\":2}") and _write(hoe, "{\"farm\":2}") and _write(trees, "{\"farm\":2}") and _write(calendar, "{\"day\":12}") and _write(equipment, "{\"equipped\":\"axe\"}"), "second slot has old map state"):
		return
	if not _check(bool(slots.call("reset_active_world")), "map state reset with backup"):
		return
	for file_path in [house, hoe, trees]:
		if not _check(not FileAccess.file_exists(file_path), "world-only file removed: " + file_path.get_file()):
			return
	var result: Variant = JSON.parse_string(FileAccess.get_file_as_string(res_file))
	if not _check(result is Dictionary and result.get("counts", {}).get("wood", 0) == 9 and result.get("counts", {}).get("stone", 0) == 4, "inventory counts preserved"):
		return
	for key in ["claimed", "drops", "mining_levels", "picked_plants"]:
		if not _check(result.get(key, {"bad":true}).is_empty(), "cleared world state: "+key):
			return
	if not _check(FileAccess.get_file_as_string(calendar) == "{\"day\":12}" and FileAccess.get_file_as_string(equipment) == "{\"equipped\":\"axe\"}", "calendar and equipment unchanged"):
		return
	var backup: String = str(slots.call("backup_path"))
	if not _check(not backup.is_empty() and FileAccess.file_exists(backup.path_join("house_terrain_test.json")) and FileAccess.get_file_as_string(backup.path_join("slimekeepers_resources_v1.json")) == second_resource, "full pre-reset backup exact"):
		return
	if not _check(slot_one == str(slots.call("slot_metadata", 1).get("snapshot", "")), "other slot metadata untouched"):
		return
	if not _check(bool(slots.call("activate", 1)), "switch to first farm after reset"):
		return
	if not _check(FileAccess.get_file_as_string(res_file) == original_resources and FileAccess.file_exists(house), "first farm never reset"):
		return
	# Falha de validacao nunca pode remover dados existentes.
	if not _check(bool(slots.call("activate", 2)), "switch back to reset farm"):
		return
	if not _check(_write(res_file, "{\"version\":999}"), "corrupt save prepared"):
		return
	if not _check(not bool(slots.call("reset_active_world")) and FileAccess.get_file_as_string(res_file) == "{\"version\":999}", "invalid inventory blocks reset with no loss"):
		return
	var autoload: Node = get_node_or_null("/root/WorldReset")
	if not _check(autoload != null and autoload.has_method("_reset_confirmed") and not bool(autoload.call("_is_world_open")), "F1 autoload only targets main World"):
		return
	print("PASS world-reset: safe backup, map cleared, inventory retained and other slot protected")
	get_tree().quit(0)
