extends Node
## Regressao da enxada no mundo principal: grama, objetos, casa fixa e persistencia.

var _failed := false


func _ready() -> void:
	call_deferred("_run")


func _check(valid: bool, label: String) -> bool:
	if valid:
		print("PASS world-hoe: ", label)
	else:
		_failed = true
		printerr("FAIL world-hoe: ", label)
	return valid


func _run() -> void:
	var world: Node2D = load("res://scenes/world/World.tscn").instantiate() as Node2D
	add_child(world)
	await get_tree().process_frame
	await get_tree().physics_frame
	var map: Node2D = world.get_node("Actors/Map") as Node2D
	var grass: TileMapLayer = map.get_node("grass2") as TileMapLayer
	var hoe: TileMapLayer = map.get_node("TilledSoil") as TileMapLayer
	var water: TileMapLayer = map.get_node("water") as TileMapLayer
	var house: Node2D = map.get_node("HouseBuilder") as Node2D
	var player: CharacterBody2D = world.get_node("Actors/Player") as CharacterBody2D

	if not _check(grass != null and hoe != null and house != null, "world reuses the painted ground and house"):
		get_tree().quit(1)
		return
	if not _check(hoe.tile_set == grass.tile_set, "tilled soil uses the existing world tileset"):
		get_tree().quit(1)
		return
	var free_cells: Array[Vector2i] = []
	for green_cell in grass.get_used_cells():
		var point: Vector2 = grass.to_global(grass.map_to_local(green_cell))
		var hoe_cell: Vector2i = hoe.local_to_map(hoe.to_local(point))
		if hoe.call("rejection_reason", hoe_cell) == "":
			free_cells.append(hoe_cell)
		if free_cells.size() >= 4:
			break
	if not _check(free_cells.size() >= 4, "four unoccupied green cells can be prepared"):
		get_tree().quit(1)
		return

	var chosen: Vector2i = free_cells[0]
	var center: Vector2 = hoe.to_global(hoe.map_to_local(chosen))
	var grass_cell: Vector2i = grass.local_to_map(grass.to_local(center))
	var original_source: int = grass.get_cell_source_id(grass_cell)
	player.global_position = center + Vector2(0, 22)
	player.call("_on_hotbar_selection", &"hoe")
	if not _check(bool(player.call("_use_non_axe", center)), "player can swing hoe onto green ground"):
		get_tree().quit(1)
		return
	if not _check(not bool(hoe.call("is_tilled", chosen)), "hoe does not paint before animation impact"):
		get_tree().quit(1)
		return
	await get_tree().create_timer(0.85).timeout
	if not _check(bool(hoe.call("is_tilled", chosen)), "hoe creates persistent tillage after impact"):
		get_tree().quit(1)
		return
	if not _check(hoe.get_cell_source_id(chosen) != -1, "the existing tilled dirt atlas is painted"):
		get_tree().quit(1)
		return
	if not _check(grass.get_cell_source_id(grass_cell) == original_source, "original grass tile painting stays unchanged"):
		get_tree().quit(1)
		return
	if not _check(hoe.call("try_till", center) != "", "repeated tillage is rejected"):
		get_tree().quit(1)
		return

	var object_cell: Vector2i = free_cells[1]
	var object_center: Vector2 = hoe.to_global(hoe.map_to_local(object_cell))
	var flower: Node2D = load("res://scenes/objects/flowers/flower_pink.tscn").instantiate() as Node2D
	flower.set("start_fully_grown", true)
	flower.set("persist_pickup", false)
	map.add_child(flower)
	flower.global_position = object_center
	await get_tree().process_frame
	if not _check(hoe.call("rejection_reason", object_cell) == "Remova ou colete o objeto antes de arar.", "flower prevents tilling occupied cell"):
		get_tree().quit(1)
		return
	var flower_before: int = ResourceBag.get_count(&"flower_pink")
	if not _check(bool(flower.call("pick_by_click", player)), "flower can be removed first, leaving a ground drop"):
		get_tree().quit(1)
		return
	if not _check(ResourceBag.get_count(&"flower_pink") == flower_before, "removing flower does not instantly credit bag"):
		get_tree().quit(1)
		return
	# Soltar o drop nao autoriza arar em cima do item: recolha-o primeiro.
	if not _check(hoe.call("rejection_reason", object_cell) != "", "unc ollected drop still blocks hoe"):
		get_tree().quit(1)
		return
	for candidate in get_tree().get_nodes_in_group("world_drops"):
		if candidate.get("item_id") == &"flower_pink":
			candidate.call("pickup", player)
	await get_tree().process_frame
	if not _check(hoe.call("rejection_reason", object_cell) == "", "collecting item frees soil for tilling"):
		get_tree().quit(1)
		return

	if not water.get_used_cells().is_empty():
		var water_point: Vector2 = water.to_global(water.map_to_local(water.get_used_cells()[0]))
		if not _check(hoe.call("rejection_reason", hoe.local_to_map(hoe.to_local(water_point))) != "", "water cannot be tilled"):
			get_tree().quit(1)
			return

	var house_cell: Vector2i = free_cells[2]
	var house_center: Vector2 = hoe.to_global(hoe.map_to_local(house_cell))
	var floor_layer: TileMapLayer = house.get("floor_layer") as TileMapLayer
	var house_anchor: Vector2i = floor_layer.local_to_map(floor_layer.to_local(house_center))
	var footprint: Dictionary = house.get("footprint")
	footprint[house_anchor] = true
	house.set("_initial_anchor", house_anchor)
	house.call("_rebuild")
	await get_tree().physics_frame
	if not _check(bool(house.call("is_world_point_protected", house_center, 3)), "house protects its footprint plus safety margin"):
		get_tree().quit(1)
		return
	if not _check(hoe.call("rejection_reason", house_cell) == "Muito perto da casa inicial.", "hoe cannot alter terrain near the original house"):
		get_tree().quit(1)
		return
	if not _check(String(house.call("_removal_reason", house_anchor, house_anchor)).contains("casa inicial"), "original house anchor cannot be demolished"):
		get_tree().quit(1)
		return
	house.call("_remember")
	footprint.erase(house_anchor)
	house.call("_undo")
	if not _check(house.get("footprint").has(house_anchor), "undo cannot relocate initial house"):
		get_tree().quit(1)
		return
	# Deixar o save de teste e o mapa apenas em memoria; nenhum mundo principal e sobrescrito.
	if not _check(FileAccess.file_exists("user://slimekeepers_world_hoeing_v1.json"), "prepared soil is saved to a separate file"):
		get_tree().quit(1)
		return
	hoe.set("_prepared", {})
	hoe.clear()
	hoe.call("_load_cells")
	if not _check(bool(hoe.call("is_tilled", chosen)), "saved ground can be restored from JSON"):
		get_tree().quit(1)
		return
	print("PASS world-hoe: green-ground tilling, occupied cells, fixed house, save and load")
	get_tree().quit(1 if _failed else 0)
