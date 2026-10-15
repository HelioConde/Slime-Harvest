extends Node
## Registra arvores derrubadas por ID para manter os tocos apos reiniciar.

const SAVE_PATH := "user://slimekeepers_felled_trees_v1.json"
var _felled: Dictionary = {}

func _ready() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
    if data is Dictionary and int(data.get("version", 0)) == 1:
        var records = data.get("felled", {})
        if records is Dictionary:
            _felled = records

func is_felled(tree_id: String) -> bool:
    return not tree_id.is_empty() and bool(_felled.get(tree_id, false))

func mark_felled(tree_id: String) -> void:
    if tree_id.is_empty() or is_felled(tree_id):
        return
    _felled[tree_id] = true
    _save()

func reset_felled(tree_id: String) -> void:
    if _felled.erase(tree_id):
        _save()

func _save() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_warning("TreePersistence: nao foi possivel salvar.")
        return
    file.store_string(JSON.stringify({"version": 1, "felled": _felled}))
