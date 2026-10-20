extends Node2D
## Plantio, rega e colheita no World. Nao altera a pintura original do TileMap.
## Save separado por slot; o solo arado e controlado por WorldHoeing.
signal farm_changed

const SAVE_PATH := "user://slimekeepers_world_crops_v1.json"
const DAYS_PER_STAGE := 3
const START_SEEDS := 12
const SEED_PRICE := 3
const FLOWER_NAMES := ["Azul", "Rosa", "Amarela"]
const FLOWER_SCENES := [
	preload("res://scenes/objects/flowers/flower_blue.tscn"),
	preload("res://scenes/objects/flowers/flower_pink.tscn"),
	preload("res://scenes/objects/flowers/flower_yellow.tscn"),
]
const CROP_ITEMS: Array[StringName] = [&"flower_blue", &"flower_pink", &"flower_yellow"]

@export var tilled_soil_path: NodePath
@export var save_path: String = SAVE_PATH
@onready var soil: TileMapLayer = get_node_or_null(tilled_soil_path) as TileMapLayer

var _crops: Dictionary = {}
var _visuals: Dictionary = {}
var seeds: int = START_SEEDS
var harvests: int = 0
var selected_variety: int = 0


func _ready() -> void:
	if soil == null or not soil.has_method("is_tilled"):
		push_error("WorldCrops: TilledSoil nao configurado.")
		return
	_load()
	GameCalendar.day_changed.connect(_on_day_changed)
	_refresh_visuals()


func get_seed_count() -> int:
	return seeds


func get_selected_variety() -> int:
	return selected_variety


func get_selected_seed_name() -> String:
	return FLOWER_NAMES[selected_variety]


func select_variety(variety: int) -> bool:
	if variety < 0 or variety >= FLOWER_SCENES.size():
		return false
	if selected_variety == variety:
		return true
	selected_variety = variety
	_save()
	farm_changed.emit()
	return true


func buy_seeds(amount: int = 1) -> bool:
	# Valida antes de debitar: nenhuma compra parcial ou credito gratuito.
	if amount <= 0 or amount > 99 or seeds > 99999 - amount:
		return false
	if not ResourceBag.spend_coins(SEED_PRICE * amount):
		return false
	seeds += amount
	_save()
	farm_changed.emit()
	return true


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.keycode != KEY_Q:
		return
	var player: Node = get_node_or_null("../../Player")
	if player != null and not bool(player.get("controls_enabled")):
		return
	select_variety((selected_variety + 1) % FLOWER_SCENES.size())
	get_viewport().set_input_as_handled()


func get_harvest_count() -> int:
	return harvests


func get_crop(cell: Vector2i) -> Dictionary:
	return (_crops.get(cell, {}) as Dictionary).duplicate(true)


func try_hoe(cell: Vector2i) -> String:
	if soil == null or not soil.call("is_tilled", cell):
		return "Prepare o solo antes de plantar."
	var record: Dictionary = _crops.get(cell, {})
	if record.is_empty():
		if seeds <= 0:
			return "Sem sementes. Colha flores para recuperar sementes."
		var variety: int = selected_variety
		record = {
			"variety": variety, "watered": false, "stage": 0,
			"growth_days": 0, "last_day": GameCalendar.day,
		}
		_crops[cell] = record
		seeds -= 1
		_save()
		_refresh_visuals()
		farm_changed.emit()
		return "Semente plantada! Regue com a ferramenta 1."
	var variety: int = clampi(int(record.get("variety", 0)), 0, CROP_ITEMS.size() - 1)
	if int(record.get("stage", 0)) < _max_stage(cell):
		return "Ainda crescendo. Regue e aguarde alguns dias."
	# A flor foi cultivada, portanto creditar ao inventario e devolver semente.
	# Nenhum drop e gerado para impedir recompensas duplicadas ao recarregar.
	_crops.erase(cell)
	harvests += 1
	seeds += 1
	_save()
	_refresh_visuals()
	ResourceBag.add_item(CROP_ITEMS[variety], 1)
	farm_changed.emit()
	return "Colhido! Flor na mochila e uma semente recuperada."


func try_water(cell: Vector2i) -> String:
	if soil == null or not soil.call("is_tilled", cell):
		return "Prepare a terra com enxada (3) antes de regar."
	var record: Dictionary = _crops.get(cell, {})
	if record.is_empty():
		return "Plante uma semente com a enxada (3)."
	if bool(record.get("watered", false)):
		return "Esta planta ja esta regada."
	record["watered"] = true
	record["last_day"] = GameCalendar.day
	_crops[cell] = record
	_save()
	farm_changed.emit()
	return "Planta regada! Cresce uma fase a cada 3 dias."


func _on_day_changed(new_day: int) -> void:
	var changed := false
	for cell in _crops.keys():
		var record: Dictionary = _crops[cell]
		if not bool(record.get("watered", false)):
			continue
		var passed: int = maxi(0, new_day - int(record.get("last_day", new_day)))
		if passed == 0:
			continue
		record["growth_days"] = maxi(0, int(record.get("growth_days", 0))) + passed
		record["last_day"] = new_day
		record["stage"] = mini(3, int(record["growth_days"]) / DAYS_PER_STAGE)
		_crops[cell] = record
		changed = true
	if changed:
		_save()
		_refresh_visuals(true)
		farm_changed.emit()


func _max_stage(cell: Vector2i) -> int:
	var crop: Node2D = _visuals.get(cell) as Node2D
	if is_instance_valid(crop) and crop.has_method("get_max_level"):
		return maxi(1, int(crop.call("get_max_level")) - 1)
	return 3


func _refresh_visuals(animate: bool = false) -> void:
	for cell in _visuals.keys():
		if _crops.has(cell):
			continue
		var previous: Node2D = _visuals[cell] as Node2D
		_visuals.erase(cell)
		if is_instance_valid(previous):
			previous.queue_free()
	for cell in _crops.keys():
		var record: Dictionary = _crops[cell]
		var visual: Node2D = _visuals.get(cell) as Node2D
		if not is_instance_valid(visual):
			var variety: int = clampi(int(record.get("variety", 0)), 0, FLOWER_SCENES.size() - 1)
			visual = FLOWER_SCENES[variety].instantiate() as Node2D
			visual.set("use_calendar", false)
			visual.set("persist_pickup", false)
			visual.name = "Crop_%d_%d" % [cell.x, cell.y]
			add_child(visual)
			visual.global_position = soil.to_global(soil.map_to_local(cell))
			_visuals[cell] = visual
		if visual.has_method("set_growth_level"):
			visual.call("set_growth_level", mini(int(record.get("stage", 0)) + 1, _max_stage(cell) + 1), animate)


func _load() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not data is Dictionary or int(data.get("version", 0)) != 1:
		push_warning("WorldCrops: save invalido ignorado.")
		return
	seeds = clampi(int(data.get("seeds", START_SEEDS)), 0, 99999)
	harvests = maxi(0, int(data.get("harvests", 0)))
	selected_variety = clampi(int(data.get("selected_variety", 0)), 0, FLOWER_SCENES.size() - 1)
	var entries: Variant = data.get("crops", [])
	if not entries is Array:
		return
	for entry in entries:
		if not entry is Dictionary:
			continue
		var x: Variant = entry.get("x")
		var y: Variant = entry.get("y")
		if not (x is float or x is int) or not (y is float or y is int):
			continue
		if not is_finite(float(x)) or not is_finite(float(y)):
			continue
		if float(x) != floorf(float(x)) or float(y) != floorf(float(y)):
			continue
		var cell := Vector2i(int(x), int(y))
		if absi(cell.x) > 4096 or absi(cell.y) > 4096:
			continue
		if not bool(soil.call("is_tilled", cell)):
			continue
		_crops[cell] = {
			"variety": clampi(int(entry.get("variety", 0)), 0, CROP_ITEMS.size() - 1),
			"watered": bool(entry.get("watered", false)),
			"stage": clampi(int(entry.get("stage", 0)), 0, 3),
			"growth_days": maxi(0, int(entry.get("growth_days", 0))),
			"last_day": clampi(int(entry.get("last_day", GameCalendar.day)), 1, GameCalendar.day),
		}


func _save() -> void:
	var records: Array[Dictionary] = []
	for cell in _crops.keys():
		var crop: Dictionary = _crops[cell]
		records.append({
			"x": cell.x, "y": cell.y,
			"variety": int(crop["variety"]),
			"watered": bool(crop["watered"]),
			"stage": int(crop["stage"]),
			"growth_days": int(crop["growth_days"]),
			"last_day": int(crop["last_day"]),
		})
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_warning("WorldCrops: nao foi possivel salvar os cultivos.")
		return
	file.store_string(JSON.stringify({
		"version": 1, "seeds": seeds, "harvests": harvests,
		"selected_variety": selected_variety, "crops": records,
	}))


func _exit_tree() -> void:
	if soil != null:
		_save()
