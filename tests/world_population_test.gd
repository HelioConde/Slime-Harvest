extends Node
## Regressao procedural isolada: nao toca nos saves reais das fazendas.
const WORLD := preload("res://scenes/world/World.tscn")
var sandbox_path: String


func _ready() -> void:
	call_deferred("_run")


func _check(ok: bool, description: String) -> bool:
	if ok:
		print("PASS population: ", description)
		return true
	printerr("FAIL population: ", description)
	get_tree().quit(1)
	return false


func _make_world() -> Node2D:
	var world := WORLD.instantiate() as Node2D
	var generator := world.get_node("Actors/Map/WorldPopulation") as Node2D
	generator.set("save_path", sandbox_path)
	add_child(world)
	return world


func _run() -> void:
	sandbox_path = "user://test_world_population_%d.json" % Time.get_ticks_usec()
	var world := _make_world()
	await get_tree().process_frame
	await get_tree().physics_frame
	var population := world.get_node("Actors/Map/WorldPopulation") as Node2D
	var grass := world.get_node("Actors/Map/grass2") as TileMapLayer
	var player := world.get_node("Actors/Player") as Node2D
	var house := world.get_node("Actors/Map/HouseBuilder") as Node2D
	if not _check(FileAccess.file_exists(sandbox_path), "layout saved separately from world progress"):
		return
	var first: Variant = JSON.parse_string(FileAccess.get_file_as_string(sandbox_path))
	if not _check(first is Dictionary and first.get("records") is Array, "layout JSON is valid"):
		return
	var records: Array = first["records"]
	if not _check(records.size() >= 20, "trees, flowers, logs, rocks and mushrooms have room"):
		return
	var kinds: Dictionary = {}
	var ids: Dictionary = {}
	for entry in records:
		var kind := str(entry["kind"])
		kinds[kind] = int(kinds.get(kind, 0)) + 1
		if not _check(not ids.has(str(entry["id"])), "unique ID " + str(entry["id"])):
			return
		ids[str(entry["id"])] = true
		var point := Vector2(float(entry["x"]), float(entry["y"]))
		var cell := grass.local_to_map(grass.to_local(point))
		if not _check(grass.get_cell_source_id(cell) >= 0, "item lives on grass2"):
			return
		if not _check(point.distance_to(player.global_position) >= 88.0, "spawn stays clear"):
			return
		if not _check(not bool(house.call("is_world_point_protected", point, 3)), "house remains clear"):
			return
	for kind in ["tree", "flower", "wood", "rock", "mushroom"]:
		if not _check(int(kinds.get(kind, 0)) > 0, "category spawned: " + kind):
			return
	var initial_count := population.get_child_count()
	if not _check(initial_count >= 20, "procedural scenes instantiated"):
		return
	world.queue_free()
	await get_tree().process_frame
	await get_tree().physics_frame
	var reloaded := _make_world()
	await get_tree().process_frame
	await get_tree().physics_frame
	var second: Variant = JSON.parse_string(FileAccess.get_file_as_string(sandbox_path))
	if not _check(second == first, "same farm loads exactly the same positions"):
		return
	var again := reloaded.get_node("Actors/Map/WorldPopulation") as Node2D
	if not _check(again.get_child_count() == initial_count, "object instances remain stable"):
		return
	reloaded.queue_free()
	await get_tree().process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(sandbox_path))
	print("PASS population: seeded layout, safe grass2 bounds and persistence")
	get_tree().quit(0)
