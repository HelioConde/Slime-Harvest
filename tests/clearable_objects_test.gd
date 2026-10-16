extends Node
## Obstaculos naturais podem ser eliminados com machado antes de arar o terreno.


func _ready() -> void:
	call_deferred("_run")


func _check(value: bool, description: String) -> bool:
	if value:
		print("PASS clearable: ", description)
		return true
	printerr("FAIL clearable: ", description)
	get_tree().quit(1)
	return false


func _run() -> void:
	var base := Node2D.new()
	base.name = "TemporaryObjects"
	add_child(base)
	for specimen in [
		{"scene": "res://scenes/objects/bushes/bush_small.tscn", "hits": 2, "item": &"twigs"},
		{"scene": "res://scenes/objects/logs/log_large.tscn", "hits": 3, "item": &"wood"},
		{"scene": "res://scenes/objects/plants/sprout_01.tscn", "hits": 1, "item": &"grass"},
		{"scene": "res://scenes/objects/stumps/stump_flat.tscn", "hits": 2, "item": &"trunk"}
	]:
		var path: String = specimen["scene"]
		var item: StringName = specimen["item"]
		var count_before: int = ResourceBag.get_count(item)
		var packed: PackedScene = load(path)
		var obj: Node2D = packed.instantiate() as Node2D
		obj.set("persist_clearing", false)
		base.add_child(obj)
		if not _check(obj.is_in_group("choppable_trees"), path + " is choppable"):
			return
		for index in range(specimen["hits"]):
			if not _check(bool(obj.call("take_axe_hit")), path + " accepts axe hit"):
				return
			if index < specimen["hits"] - 1:
				await get_tree().create_timer(0.40).timeout
		await get_tree().process_frame
		if not _check(not is_instance_valid(obj), "object is removed after required strikes"):
			return
		var drop: Node2D = null
		for candidate in get_tree().get_nodes_in_group("world_drops"):
			if candidate.get("item_id") == item:
				drop = candidate as Node2D
				break
		if not _check(drop != null, "drop for " + String(item) + " appears on ground"):
			return
		if not _check(drop.get_node("DropIcon").texture != null, "drop reuses an existing texture"):
			return
		drop.call("pickup")
		if not _check(ResourceBag.get_count(item) == count_before + 1, "item reaches persistent inventory"):
			return

	var id: String = "test-clearable-static-persistent"
	ResourceBag._picked_plants.erase(id)
	ResourceBag.call("_save_state")
	var original: PackedScene = load("res://scenes/objects/bushes/bush_small.tscn")
	var bush: Node2D = original.instantiate() as Node2D
	bush.set("persistent_id", id)
	base.add_child(bush)
	bush.call("take_axe_hit")
	await get_tree().create_timer(0.4).timeout
	bush.call("take_axe_hit")
	await get_tree().process_frame
	var reloaded: Node2D = original.instantiate() as Node2D
	reloaded.set("persistent_id", id)
	base.add_child(reloaded)
	await get_tree().process_frame
	if not _check(not is_instance_valid(reloaded), "cleared bush remains absent after reload"):
		return
	ResourceBag._picked_plants.erase(id)
	ResourceBag.call("_save_state")
	for candidate in get_tree().get_nodes_in_group("world_drops"):
		if candidate.get("source_key") == id + ":plant_drop:" + str(GameCalendar.day):
			candidate.queue_free()
	print("PASS clearable: bushes logs sprouts and stumps can be cleared with original sprites")
	get_tree().quit(0)
