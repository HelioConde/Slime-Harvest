extends Node
## Compatibilidade v1/v2: estados finais e golpes parciais (v3).
const SAVE_PATH := "user://slimekeepers_felled_trees_v1.json"
var _felled: Dictionary = {}
var _cleared_stumps: Dictionary = {}
var _tree_hits: Dictionary = {}
var _stump_hits: Dictionary = {}


func _ready() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary or int(data.get("version", 0)) not in [1, 2, 3]:
		return
	for field in ["felled", "cleared_stumps", "tree_hits", "stump_hits"]:
		var records = data.get(field, {})
		if records is Dictionary:
			match field:
				"felled": _felled = records
				"cleared_stumps": _cleared_stumps = records
				"tree_hits": _tree_hits = records
				"stump_hits": _stump_hits = records


func is_felled(tree_id: String) -> bool:
	return not tree_id.is_empty() and bool(_felled.get(tree_id, false))


func mark_felled(tree_id: String) -> void:
	if tree_id.is_empty():
		return
	_felled[tree_id] = true
	_tree_hits.erase(tree_id)
	_save()


func is_stump_cleared(tree_id: String) -> bool:
	return not tree_id.is_empty() and bool(_cleared_stumps.get(tree_id, false))


func mark_stump_cleared(tree_id: String) -> void:
	if tree_id.is_empty():
		return
	_cleared_stumps[tree_id] = true
	_stump_hits.erase(tree_id)
	_save()


func get_tree_hits(tree_id: String) -> int:
	return maxi(0, int(_tree_hits.get(tree_id, 0)))


func get_stump_hits(tree_id: String) -> int:
	return maxi(0, int(_stump_hits.get(tree_id, 0)))


func save_tree_hits(tree_id: String, hits: int) -> void:
	if tree_id.is_empty() or is_felled(tree_id):
		return
	_tree_hits[tree_id] = maxi(0, hits)
	_save()


func save_stump_hits(tree_id: String, hits: int) -> void:
	if tree_id.is_empty() or is_stump_cleared(tree_id):
		return
	_stump_hits[tree_id] = maxi(0, hits)
	_save()


func reset_felled(tree_id: String) -> void:
	var changed: bool = false
	for group in [_felled, _cleared_stumps, _tree_hits, _stump_hits]:
		changed = group.erase(tree_id) or changed
	if changed:
		_save()


func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("TreePersistence: nao foi possivel salvar.")
		return
	file.store_string(JSON.stringify({
		"version": 3, "felled": _felled, "cleared_stumps": _cleared_stumps,
		"tree_hits": _tree_hits, "stump_hits": _stump_hits
	}))
