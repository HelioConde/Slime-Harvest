extends Node
## Compatibilidade com save v1: arvores derrubadas e tocos removidos (v2).

const SAVE_PATH := "user://slimekeepers_felled_trees_v1.json"
var _felled: Dictionary = {}
var _cleared_stumps: Dictionary = {}


func _ready() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary:
		return
	if int(data.get("version", 0)) not in [1, 2]:
		return
	var records = data.get("felled", {})
	if records is Dictionary:
		_felled = records
	var cleared = data.get("cleared_stumps", {})
	if cleared is Dictionary:
		_cleared_stumps = cleared


func is_felled(tree_id: String) -> bool:
	return not tree_id.is_empty() and bool(_felled.get(tree_id, false))


func mark_felled(tree_id: String) -> void:
	if tree_id.is_empty() or is_felled(tree_id):
		return
	_felled[tree_id] = true
	_save()


func is_stump_cleared(tree_id: String) -> bool:
	return not tree_id.is_empty() and bool(_cleared_stumps.get(tree_id, false))


func mark_stump_cleared(tree_id: String) -> void:
	if tree_id.is_empty() or is_stump_cleared(tree_id):
		return
	_cleared_stumps[tree_id] = true
	_save()


func reset_felled(tree_id: String) -> void:
	var changed: bool = _felled.erase(tree_id)
	changed = _cleared_stumps.erase(tree_id) or changed
	if changed:
		_save()


func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("TreePersistence: nao foi possivel salvar.")
		return
	file.store_string(JSON.stringify({"version": 2, "felled": _felled, "cleared_stumps": _cleared_stumps}))
