extends Node
## Recursos reais, alteracoes do mundo e drops aguardando coleta.

signal amount_changed(item_id: StringName, total: int)
signal item_collected(item_id: StringName, amount: int)
signal coins_changed(total: int)

const SAVE_PATH := "user://slimekeepers_resources_v1.json"
const DROP_SCENE: PackedScene = preload("res://scenes/items/ResourceDrop.tscn")
## Precos fixos de teste; somente flores podem ser vendidas.
const SALE_PRICES := {"flower_blue": 5, "flower_pink": 7, "flower_yellow": 9}

var _counts: Dictionary = {}
var _coins: int = 0
var _drops: Dictionary = {}
var _claimed: Dictionary = {}
var _mining_levels: Dictionary = {}
var _picked_plants: Dictionary = {}
var _active_scene: Node


func _ready() -> void:
	_load_state()


func _process(_delta: float) -> void:
	var scene: Node = get_tree().current_scene
	if scene == null or scene == _active_scene:
		return
	_active_scene = scene
	for drop_key in _drops.keys():
		var record: Dictionary = _drops[drop_key]
		if str(record.get("scene", "")) != scene.scene_file_path:
			continue
		_make_drop(
			scene,
			Vector2(float(record.get("x", 0.0)), float(record.get("y", 0.0))),
			StringName(str(record.get("item", "trunk"))),
			str(drop_key), true,
			str(record.get("art_scene", "")),
			StringName(str(record.get("art_animation", "")))
		)


func get_count(item_id: StringName) -> int:
	return maxi(0, int(_counts.get(String(item_id), 0)))


## Visao somente-leitura para a mochila; sem duplicar o estado persistido.
func get_all_counts() -> Dictionary:
	return _counts.duplicate(true)


func get_coins() -> int:
	return _coins


func get_sell_price(item_id: StringName) -> int:
	return int(SALE_PRICES.get(String(item_id), 0))


## Venda atomica: remocao de flores e credito das moedas no mesmo save.
## Retorna valor ganho; zero indica quantidade/preco invalido.
func sell_item(item_id: StringName, amount: int = 1) -> int:
	var price: int = get_sell_price(item_id)
	if price <= 0 or amount <= 0 or amount > get_count(item_id):
		return 0
	var payout: int = price * amount
	if payout > 1000000000 or _coins > 1000000000 - payout:
		return 0
	var key: String = String(item_id)
	_counts[key] = get_count(item_id) - amount
	_coins += payout
	_save_state()
	amount_changed.emit(item_id, get_count(item_id))
	coins_changed.emit(_coins)
	return payout


func spend_coins(cost: int) -> bool:
	if cost <= 0 or cost > _coins:
		return false
	_coins -= cost
	_save_state()
	coins_changed.emit(_coins)
	return true


func add_item(item_id: StringName, amount: int = 1) -> void:
	if amount <= 0:
		return
	var key: String = String(item_id)
	_counts[key] = get_count(item_id) + amount
	_save_state()
	amount_changed.emit(item_id, get_count(item_id))
	item_collected.emit(item_id, amount)


func spawn_drop(
	parent: Node, position_world: Vector2, item_id: StringName,
	source_key: String, persistent: bool = true,
	art_scene: String = "", art_animation: StringName = &""
) -> void:
	if parent == null:
		return
	if persistent:
		if _claimed.has(source_key) or _drops.has(source_key):
			return
		var scene: Node = get_tree().current_scene
		var scene_path: String = scene.scene_file_path if scene != null else ""
		_drops[source_key] = {
			"scene": scene_path,
			"item": String(item_id),
			"x": position_world.x, "y": position_world.y,
			"art_scene": art_scene, "art_animation": String(art_animation)
		}
		_save_state()
	_make_drop(parent, position_world, item_id, source_key, persistent, art_scene, art_animation)


func _make_drop(
	parent: Node, position_world: Vector2, item_id: StringName, source_key: String,
	persistent: bool, art_scene: String = "", art_animation: StringName = &""
) -> void:
	var drop: Node2D = DROP_SCENE.instantiate() as Node2D
	if drop == null:
		return
	drop.set("item_id", item_id)
	drop.set("source_key", source_key)
	drop.set("persist_drop", persistent)
	drop.set("art_scene", art_scene)
	drop.set("art_animation", art_animation)
	parent.add_child(drop)
	drop.global_position = position_world
	drop.z_index = 11


## Itens de cenario abertos/vasos quebrados: marcador + recompensa no mesmo
## save do slot atual, sem permitir coletar duas vezes apos carregar.
func world_reward_claimed(source_key: String) -> bool:
	return _claimed.has(source_key)


func claim_world_reward(source_key: String, item_id: StringName, amount: int = 1) -> bool:
	if not source_key.begins_with("expansion:") or _claimed.has(source_key):
		return false
	if amount < 1 or amount > 50:
		return false
	var key: String = String(item_id)
	_claimed[source_key] = true
	_counts[key] = get_count(item_id) + amount
	_save_state()
	amount_changed.emit(item_id, get_count(item_id))
	item_collected.emit(item_id, amount)
	return true


func collect_drop(source_key: String, item_id: StringName, persistent: bool) -> bool:
	if persistent:
		if _claimed.has(source_key) or not _drops.has(source_key):
			return false
		_claimed[source_key] = true
		_drops.erase(source_key)
	add_item(item_id, 1)
	return true


func is_plant_collected(plant_key: String, regrow_days: int = 0) -> bool:
	if not _picked_plants.has(plant_key):
		return false
	var recorded = _picked_plants[plant_key]
	if recorded is bool:
		if not recorded:
			return false
		# Migrar saves anteriores que continham apenas true/false.
		recorded = GameCalendar.day
		_picked_plants[plant_key] = recorded
		_save_state()
	if regrow_days > 0 and GameCalendar.day - int(recorded) >= regrow_days:
		_picked_plants.erase(plant_key)
		_save_state()
		return false
	return true


func drop_plant(
	plant_key: String, item_id: StringName, parent: Node,
	position_world: Vector2, persistent: bool,
	art_scene: String = "", art_animation: StringName = &"",
	regrow_days: int = 6
) -> bool:
	# Clicar transforma a planta em um drop no chao. Nunca creditar o inventario aqui.
	if parent == null:
		return false
	var drop_key: String = plant_key + ":plant_drop:" + str(GameCalendar.day)
	if persistent:
		if is_plant_collected(plant_key, regrow_days) or _claimed.has(drop_key) or _drops.has(drop_key):
			return false
		_picked_plants[plant_key] = GameCalendar.day
	spawn_drop(parent, position_world, item_id, drop_key, persistent, art_scene, art_animation)
	if persistent:
		_save_state()
	return true


func rock_level(rock_key: String, original_level: int) -> int:
	return clampi(int(_mining_levels.get(rock_key, original_level)), 0, original_level)


func save_rock_level(rock_key: String, level: int) -> void:
	_mining_levels[rock_key] = maxi(level, 0)
	_save_state()


func save_session_state() -> void:
	_save_state()


func reload_session_state() -> void:
	_counts.clear()
	_drops.clear()
	_claimed.clear()
	_mining_levels.clear()
	_picked_plants.clear()
	_coins = 0
	_active_scene = null
	_load_state()
	for item_id in _counts.keys():
		amount_changed.emit(StringName(str(item_id)), get_count(StringName(str(item_id))))
	coins_changed.emit(_coins)


func _load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary or int(data.get("version", 0)) != 1:
		push_warning("ResourceBag: save invalido.")
		return
	_coins = clampi(int(data.get("coins", 0)), 0, 1000000000)
	for pair in [["counts", "_counts"], ["drops", "_drops"], ["claimed", "_claimed"], ["mining_levels", "_mining_levels"], ["picked_plants", "_picked_plants"]]:
		var value = data.get(pair[0], {})
		if value is Dictionary:
			match pair[0]:
				"counts": _counts = value
				"drops": _drops = value
				"claimed": _claimed = value
				"mining_levels": _mining_levels = value
				"picked_plants": _picked_plants = value


func _save_state() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("ResourceBag: falha ao salvar recursos.")
		return
	file.store_string(JSON.stringify({"version": 1, "coins": _coins, "counts": _counts, "drops": _drops, "claimed": _claimed, "mining_levels": _mining_levels, "picked_plants": _picked_plants}))
