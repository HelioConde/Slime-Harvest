extends RefCounted
## Preserva todos os saves v1 existentes sem altera-los ate uma acao explicita do usuario.
## Um slot ativo usa os arquivos user:// originais; slots inativos usam snapshots completos.
## Cada mudanca cria uma nova pasta de backup imutavel para permitir recuperacao.
const MAX_SLOTS := 3
const DATA_FILES: Array[String] = [
	"house_terrain_test.json",
	"slimekeepers_calendar_v1.json",
	"slimekeepers_resources_v1.json",
	"slimekeepers_world_hoeing_v1.json",
	"slimekeepers_world_crops_v1.json",
	"slimekeepers_felled_trees_v1.json",
	"slimekeepers_equipment_v1.json",
	"slimekeepers_world_spawns_v1.json",
]
const PROGRESS_FILES: Array[String] = [
	"slimekeepers_world_spawns_v1.json",
	"house_terrain_test.json",
	"slimekeepers_calendar_v1.json",
	"slimekeepers_resources_v1.json",
	"slimekeepers_world_hoeing_v1.json",
	"slimekeepers_world_crops_v1.json",
	"slimekeepers_felled_trees_v1.json",
]

var root: String = "user://"
var error_message: String = ""
var _index: Dictionary = {}


func _init(data_root: String = "user://") -> void:
	root = data_root.trim_suffix("/") + "/"


func _new_index() -> Dictionary:
	return {"version": 1, "active": 0, "slots": {}, "last_backup": ""}


func _index_path() -> String:
	return root + "slimekeepers_slot_index_v1.json"


func _live_path(file: String) -> String:
	return root + file


func initialize() -> bool:
	error_message = ""
	if FileAccess.file_exists(_index_path()):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(_index_path()))
		if not data is Dictionary or int(data.get("version", 0)) != 1 or not data.get("slots") is Dictionary:
			error_message = "Indice de partidas invalido. Seus arquivos existentes foram preservados."
			return false
		_index = data
		return true
	_index = _new_index()
	if not _has_live_progress():
		return true
	var snapshot: String = _archive(_read_live(), 1, "legado")
	if snapshot.is_empty():
		return false
	_index["active"] = 1
	_index["slots"] = {"1": _metadata("Fazenda original", "Aventureiro", snapshot)}
	_index["last_backup"] = snapshot
	if not _write_index():
		error_message = "Nao foi possivel registrar o backup do save antigo."
		return false
	return true


func _has_live_progress() -> bool:
	for file in PROGRESS_FILES:
		if FileAccess.file_exists(_live_path(file)):
			return true
	return false


func has_save() -> bool:
	return int(_index.get("active", 0)) > 0 and _index.get("slots", {}).has(str(int(_index.get("active", 0))))


func active_slot() -> int:
	return int(_index.get("active", 0))


func first_free_slot() -> int:
	var records: Dictionary = _index.get("slots", {})
	for slot in range(1, MAX_SLOTS + 1):
		if not records.has(str(slot)):
			return slot
	return 0


func slot_metadata(slot: int) -> Dictionary:
	return (_index.get("slots", {}) as Dictionary).get(str(slot), {}).duplicate(true)


func list_slots() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for id in range(1, MAX_SLOTS + 1):
		var record: Dictionary = slot_metadata(id)
		if not record.is_empty():
			record["slot"] = id
			record["is_active"] = id == active_slot()
			results.append(record)
	return results


func backup_path() -> String:
	return str(_index.get("last_backup", ""))


func _metadata(farm_name: String, player_name: String, archive: String) -> Dictionary:
	return {
		"farm": farm_name.strip_edges().substr(0, 32),
		"player": player_name.strip_edges().substr(0, 32),
		"snapshot": archive,
		"created_unix": int(Time.get_unix_time_from_system()),
		"updated_unix": int(Time.get_unix_time_from_system()),
	}


func _read_live() -> Dictionary:
	var result: Dictionary = {}
	for file in DATA_FILES:
		var path: String = _live_path(file)
		if FileAccess.file_exists(path):
			result[file] = FileAccess.get_file_as_bytes(path)
	return result


func _read_archive(folder: String) -> Dictionary:
	var result: Dictionary = {}
	for file in DATA_FILES:
		var path: String = folder.path_join(file)
		if FileAccess.file_exists(path):
			result[file] = FileAccess.get_file_as_bytes(path)
	return result


func _archive(files: Dictionary, slot: int, purpose: String) -> String:
	var folder: String = root + "slimekeepers_slot_snapshots/slot_%d_%s_%d" % [
		slot, purpose, Time.get_ticks_usec()
	]
	var absolute: String = ProjectSettings.globalize_path(folder)
	var err: Error = DirAccess.make_dir_recursive_absolute(absolute)
	if err != OK:
		error_message = "Falha ao criar pasta de backup (%d)." % err
		return ""
	for file in files.keys():
		if not _write_bytes(folder.path_join(str(file)), files[file]):
			error_message = "Falha ao copiar %s para backup. Nenhum arquivo original foi apagado." % file
			return ""
	return folder


func _write_bytes(path: String, bytes: PackedByteArray) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_buffer(bytes)
	file.flush()
	file.close()
	return true


func _restore_live(data: Dictionary) -> bool:
	# Caller guarda antes uma copia em memoria e um snapshot persistente.
	for name in DATA_FILES:
		var path: String = _live_path(name)
		if FileAccess.file_exists(path) and DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) != OK:
			error_message = "Nao foi possivel limpar %s." % name
			return false
	for name in data.keys():
		if not _write_bytes(_live_path(str(name)), data[name]):
			error_message = "Nao foi possivel restaurar %s." % name
			return false
	return true


func _write_index() -> bool:
	var file: FileAccess = FileAccess.open(_index_path(), FileAccess.WRITE)
	if file == null:
		error_message = "Nao foi possivel gravar o indice de partidas."
		return false
	file.store_string(JSON.stringify(_index, "\t"))
	file.flush()
	file.close()
	return true


func _capture_active_to_backup(live: Dictionary, purpose: String) -> String:
	var active: int = active_slot()
	if active == 0:
		return ""
	var snapshot: String = _archive(live, active, purpose)
	if snapshot.is_empty():
		return ""
	var slots: Dictionary = _index["slots"]
	var meta: Dictionary = slots.get(str(active), {})
	meta["snapshot"] = snapshot
	meta["updated_unix"] = int(Time.get_unix_time_from_system())
	slots[str(active)] = meta
	_index["last_backup"] = snapshot
	return snapshot


func create_new(farm_name: String, player_name: String, target_slot: int = 0, replace: bool = false) -> bool:
	error_message = ""
	if _index.is_empty() and not initialize():
		return false
	var slots: Dictionary = _index["slots"]
	var slot: int = active_slot() if replace else (target_slot if target_slot > 0 else first_free_slot())
	if slot < 1 or slot > MAX_SLOTS or (replace and not slots.has(str(slot))) or (not replace and slots.has(str(slot))):
		error_message = "Espaco indisponivel. Escolha uma partida existente para substituir."
		return false
	var previous: Dictionary = _read_live()
	var previous_index: Dictionary = _index.duplicate(true)
	if active_slot() > 0 and _capture_active_to_backup(previous, "antes_da_troca").is_empty():
		_index = previous_index
		return false
	if not _restore_live({}):
		_restore_live(previous)
		_index = previous_index
		return false
	_index["active"] = slot
	slots = _index["slots"]
	slots[str(slot)] = _metadata(farm_name if not farm_name.strip_edges().is_empty() else "Minha fazenda",
		player_name if not player_name.strip_edges().is_empty() else "Aventureiro", "")
	if not _write_index():
		_restore_live(previous)
		_index = previous_index
		_write_index()
		return false
	return true


func activate(slot: int) -> bool:
	error_message = ""
	if slot == active_slot():
		return true
	if slot < 1 or slot > MAX_SLOTS:
		error_message = "Espaco de jogo invalido."
		return false
	var selected: Dictionary = slot_metadata(slot)
	if selected.is_empty():
		error_message = "Este espaco ainda esta vazio."
		return false
	var folder: String = str(selected.get("snapshot", ""))
	if folder.is_empty() or not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(folder)):
		error_message = "Backup da partida nao encontrado. Dados atuais preservados."
		return false
	var target_files: Dictionary = _read_archive(folder)
	if target_files.is_empty():
		error_message = "Backup vazio ou corrompido. Nenhum save foi modificado."
		return false
	var previous_files: Dictionary = _read_live()
	var previous_index: Dictionary = _index.duplicate(true)
	if active_slot() > 0 and _capture_active_to_backup(previous_files, "antes_da_troca").is_empty():
		_index = previous_index
		return false
	if not _restore_live(target_files):
		_restore_live(previous_files)
		_index = previous_index
		return false
	_index["active"] = slot
	if not _write_index():
		_restore_live(previous_files)
		_index = previous_index
		_write_index()
		return false
	return true


const WORLD_FILES: Array[String] = [
	"slimekeepers_world_spawns_v1.json",
	"house_terrain_test.json",
	"slimekeepers_world_hoeing_v1.json",
	"slimekeepers_world_crops_v1.json",
	"slimekeepers_felled_trees_v1.json",
]


func reset_active_world() -> bool:
	## Chamado APOS o mundo ser descarregado para nao recriar saves na saida de TileMap.
	## Reset apenas de mundo: preservar counts, calendario, equipamento e outras fazendas.
	error_message = ""
	if _index.is_empty() and not initialize():
		return false
	var original: Dictionary = _read_live()
	var next_data: Dictionary = original.duplicate(true)
	# Nunca apagar saves de recursos sem primeiro validar e isolar os itens.
	var resource_name := "slimekeepers_resources_v1.json"
	if original.has(resource_name):
		var data: Variant = JSON.parse_string((original[resource_name] as PackedByteArray).get_string_from_utf8())
		if not data is Dictionary or int(data.get("version", 0)) != 1 or not data.get("counts", {}) is Dictionary:
			error_message = "Inventario salvo invalido. Reset cancelado sem apagar arquivos."
			return false
		var empty_world_resources: Dictionary = {
			"version": 1,
			"coins": clampi(int(data.get("coins", 0)), 0, 1000000000),
			"counts": (data.get("counts", {}) as Dictionary).duplicate(true),
			"drops": {},
			"claimed": {},
			"mining_levels": {},
			"picked_plants": {},
		}
		next_data[resource_name] = JSON.stringify(empty_world_resources).to_utf8_buffer()
	for name in WORLD_FILES:
		next_data.erase(name)
	# Garantir snapshot completo antes de tocar qualquer arquivo.
	var previous_index: Dictionary = _index.duplicate(true)
	var active: int = active_slot()
	var backup: String = _archive(original, active, "antes_reset_mapa_f1")
	if backup.is_empty():
		return false
	if not _restore_live(next_data):
		# Rollback em caso de erro parcial; copia anterior permanece no snapshot.
		_restore_live(original)
		_index = previous_index
		return false
	_index["last_backup"] = backup
	if active > 0:
		var slots: Dictionary = _index.get("slots", {})
		var metadata: Dictionary = slots.get(str(active), {})
		if not metadata.is_empty():
			# Ponto de recuperacao antes do reset permanece separado ate a proxima troca de slot.
			metadata["snapshot"] = backup
			metadata["updated_unix"] = int(Time.get_unix_time_from_system())
			slots[str(active)] = metadata
	if not _write_index():
		_restore_live(original)
		_index = previous_index
		_write_index()
		return false
	return true

## Salva o avatar no indice, junto ao slot, sem alterar os arquivos da fazenda.
func set_active_appearance(appearance: String) -> bool:
	if not (appearance in ["sprout_sorry", "masculino", "feminino"]):
		error_message = "Aparencia de personagem invalida."
		return false
	var slot: int = active_slot()
	if slot <= 0:
		error_message = "Nenhum espaco de jogo ativo."
		return false
	var records: Dictionary = _index.get("slots", {})
	var record: Dictionary = records.get(str(slot), {})
	if record.is_empty():
		return false
	record["appearance"] = appearance
	records[str(slot)] = record
	return _write_index()
