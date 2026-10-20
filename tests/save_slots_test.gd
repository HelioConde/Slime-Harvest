extends Node
## Teste isolado em user://test_slimekeepers_slots_*.
const SLOTS = preload("res://scripts/core/save_slots.gd")
var test_root: String

func _check(ok: bool, label_text: String) -> bool:
	if ok:
		print("PASS save-slots: ", label_text)
		return true
	printerr("FAIL save-slots: ", label_text)
	get_tree().quit(1)
	return false

func _ready() -> void:
	call_deferred("_run")

func _write(path: String, content: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(content)
	f.close()
	return true

func _run() -> void:
	test_root = "user://test_slimekeepers_slots_%d/" % Time.get_ticks_usec()
	if not _check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_root)) == OK, "sandbox directory created"):
		return
	var cal := test_root + "slimekeepers_calendar_v1.json"
	var res := test_root + "slimekeepers_resources_v1.json"
	var crops := test_root + "slimekeepers_world_crops_v1.json"
	if not _check(_write(cal, "{\"version\":1,\"day\":17}") and _write(res, "{\"version\":1,\"counts\":{\"wood\":42}}"), "legacy progress created in sandbox"):
		return
	var mgr: RefCounted = SLOTS.new(test_root)
	if not _check(bool(mgr.call("initialize")), "legacy migrated safely"):
		return
	if not _check(int(mgr.call("active_slot")) == 1 and int(mgr.call("first_free_slot")) == 2, "original slot 1, slot 2 free"):
		return
	if not _check(bool(mgr.call("create_new", "Vale Verde", "Lia")), "new independent farm created"):
		return
	if not _check(int(mgr.call("active_slot")) == 2 and not FileAccess.file_exists(cal) and not FileAccess.file_exists(crops), "new farm starts fresh"):
		return
	if not _check(_write(cal, "{\"version\":1,\"day\":2}") and _write(res, "{\"version\":1,\"counts\":{\"wood\":3}}"), "new farm stores its own progress"):
		return
	if not _check(_write(crops, "{\"version\":1,\"selected_variety\":2,\"seeds\":4,\"crops\":[]}"), "second farm saves seed selection"):
		return
	if not _check(bool(mgr.call("activate", 1)), "switches back to original farm"):
		return
	var old_cal: Variant = JSON.parse_string(FileAccess.get_file_as_string(cal))
	var old_res: Variant = JSON.parse_string(FileAccess.get_file_as_string(res))
	if not _check(old_cal is Dictionary and int(old_cal.get("day", 0)) == 17 and old_res is Dictionary and int(old_res.get("counts", {}).get("wood", 0)) == 42 and not FileAccess.file_exists(crops), "original progress restored exactly"):
		return
	if not _check(bool(mgr.call("activate", 2)), "switches back to second farm"):
		return
	var next_cal: Variant = JSON.parse_string(FileAccess.get_file_as_string(cal))
	var next_crops: Variant = JSON.parse_string(FileAccess.get_file_as_string(crops))
	if not _check(next_cal is Dictionary and int(next_cal.get("day", 0)) == 2 and next_crops is Dictionary and int(next_crops.get("selected_variety", -1)) == 2, "separate crop selection and farm progress intact"):
		return
	var first_snapshot: String = str(mgr.call("slot_metadata", 1).get("snapshot", ""))
	if not _check(bool(mgr.call("create_new", "Vila Nova", "Hélio", 0, true)), "explicit replace resets only active farm"):
		return
	if not _check(not FileAccess.file_exists(cal) and not FileAccess.file_exists(crops), "replaced farm has no old crops"):
		return
	var backup: String = str(mgr.call("backup_path"))
	if not _check(not backup.is_empty() and FileAccess.file_exists(backup.path_join("slimekeepers_calendar_v1.json")), "backup created before replacement"):
		return
	if not _check(str(mgr.call("slot_metadata", 1).get("snapshot", "")) == first_snapshot, "slot 1 untouched"):
		return
	if not _check(str(mgr.call("slot_metadata", 2).get("player", "")) == "Hélio", "new character name preserved"):
		return
	var restarted: RefCounted = SLOTS.new(test_root)
	if not _check(bool(restarted.call("initialize")) and int(restarted.call("active_slot")) == 2, "index persists on restart"):
		return
	print("PASS save-slots: legacy, isolation, switching, replace with backup and persistence")
	get_tree().quit(0)
