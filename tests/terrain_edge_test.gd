extends Node
## Conferir a malha fisica do litoral gerada dos pixels dos sprites originais.


func _ready() -> void:
	call_deferred("_run")


func _check(ok: bool, description: String) -> bool:
	if ok:
		print("PASS terrain-edge: ", description)
		return true
	printerr("FAIL terrain-edge: ", description)
	get_tree().quit(1)
	return false


func _intersects_edge(point: Vector2, edge: StaticBody2D) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = point
	query.collision_mask = 1
	query.collide_with_bodies = true
	for hit in edge.get_world_2d().direct_space_state.intersect_point(query, 48):
		if hit.get("collider") == edge:
			return true
	return false


func _run() -> void:
	var world := load("res://scenes/world/World.tscn").instantiate() as Node2D
	add_child(world)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var edge: StaticBody2D = world.get_node("Actors/Map/TerrainEdgeCollision") as StaticBody2D
	var water: TileMapLayer = world.get_node("Actors/Map/water") as TileMapLayer
	var grass: TileMapLayer = world.get_node("Actors/Map/grass2") as TileMapLayer
	var shore: TileMapLayer = world.get_node("Actors/Map/soil_water") as TileMapLayer
	if not _check(edge != null and water != null and grass != null and shore != null,
		"terrain collision uses the three original map tile layers"):
		return
	if not _check(edge.collision_layer == 1 and edge.collision_mask == 2,
		"collision blocks the player's physics layer"):
		return
	# A camada water do World pode estar totalmente coberta pelo grass2:
	# agua escondida nao deve gerar parede invisivel sob um piso caminhavel.
	var original_colliders: int = int(edge.call("collision_rectangle_count"))
	var original_pixels: int = int(edge.call("blocked_pixel_count"))
	if not _check((original_colliders == 0) == (original_pixels == 0),
		"only visible water contributes to shoreline collision"):
		return
	# Expor temporariamente uma celula de agua, apenas na cena de teste.
	# Isso garante que o gerador funcione mesmo quando o mapa atual
	# nao possui nenhum pixel de agua descoberto.
	var exposed_cell: Vector2i = water.get_used_cells()[0]
	var grass_id: int = grass.get_cell_source_id(exposed_cell)
	var grass_atlas: Vector2i = grass.get_cell_atlas_coords(exposed_cell)
	var grass_alternative: int = grass.get_cell_alternative_tile(exposed_cell)
	var soil_id: int = shore.get_cell_source_id(exposed_cell)
	var soil_atlas: Vector2i = shore.get_cell_atlas_coords(exposed_cell)
	var soil_alternative: int = shore.get_cell_alternative_tile(exposed_cell)
	grass.erase_cell(exposed_cell)
	shore.erase_cell(exposed_cell)
	edge.call("rebuild_collision")
	await get_tree().physics_frame
	if not _check(edge.call("collision_rectangle_count") > 0 and edge.call("blocked_pixel_count") > 0,
		"uncovered water builds physical shoreline rectangles"):
		return

	var collision_found: bool = false
	for child in edge.get_children():
		var shape := child as CollisionShape2D
		if shape == null:
			continue
		var point: Vector2 = shape.global_position
		if _intersects_edge(point, edge):
			collision_found = true
			break
	if not _check(collision_found, "collision geometry actually blocks exposed water points"):
		return

	# Repor os tiles pintados: o teste nao modifica a cena salva.
	if grass_id != -1:
		grass.set_cell(exposed_cell, grass_id, grass_atlas, grass_alternative)
	if soil_id != -1:
		shore.set_cell(exposed_cell, soil_id, soil_atlas, soil_alternative)
	edge.call("rebuild_collision")
	await get_tree().physics_frame
	if not _check(int(edge.call("collision_rectangle_count")) == original_colliders and
		int(edge.call("blocked_pixel_count")) == original_pixels,
		"restoring upper tiles restores the original water exposure"):
		return

	var land_found: bool = false
	var land_unblocked: bool = false
	var tile_size: Vector2i = water.tile_set.tile_size
	for cell in water.get_used_cells():
		if grass.get_cell_source_id(cell) == -1 and shore.get_cell_source_id(cell) == -1:
			continue
		var origin: Vector2 = water.to_global(water.map_to_local(cell) - Vector2(tile_size) * 0.5)
		for y in range(2, tile_size.y - 2, 2):
			for x in range(2, tile_size.x - 2, 2):
				var pixel: Vector2i = cell * tile_size + Vector2i(x, y)
				if not bool(edge.call("_is_water_pixel", pixel)):
					land_found = true
					if not _intersects_edge(origin + Vector2(x, y) + Vector2(0.5, 0.5), edge):
						land_unblocked = true
						break
			if land_unblocked:
				break
		if land_unblocked:
			break
	if not _check(land_found and land_unblocked,
		"opaque grass and soil sprites are still walkable above water"):
		return

	var saved_water: int = water.get_used_cells().size()
	var before_grass: int = grass.get_used_cells().size()
	edge.call("rebuild_collision")
	await get_tree().physics_frame
	if not _check(int(edge.call("collision_rectangle_count")) == original_colliders and
		int(edge.call("blocked_pixel_count")) == original_pixels,
		"colliders can be rebuilt consistently from the same TileSet"):
		return
	if not _check(water.get_used_cells().size() == saved_water and grass.get_used_cells().size() == before_grass,
		"collision generation never repaints original tiles"):
		return
	print("PASS terrain-edge: precise spritesheet shoreline physics without blocking solid land")
	get_tree().quit(0)
