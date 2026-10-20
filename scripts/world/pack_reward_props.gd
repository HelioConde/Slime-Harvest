extends Node2D
## Baus e vasos opcionais so aparecem em espacos de relva liberados.
const PROP = preload("res://scripts/world/reward_prop.gd")
@onready var grass: TileMapLayer = get_node_or_null("../grass2") as TileMapLayer
@onready var soil: TileMapLayer = get_node_or_null("../TilledSoil") as TileMapLayer
@onready var player: CharacterBody2D = get_node_or_null("../../Player") as CharacterBody2D

func _ready() -> void:
	if grass == null or soil == null or player == null:
		return
	var locations: Array[Vector2] = []
	for cell in grass.get_used_cells():
		var point: Vector2 = grass.to_global(grass.map_to_local(cell))
		var dist: float = point.distance_to(player.global_position)
		if dist < 100.0 or dist > 220.0:
			continue
		var target := soil.local_to_map(soil.to_local(point))
		if not str(soil.call("rejection_reason", target)).is_empty():
			continue
		if not locations.is_empty() and locations[0].distance_to(point) < 65.0:
			continue
		locations.append(point)
		if locations.size() == 2:
			break
	var available := [
		{"id": "expansion:chest:world1", "kind": "chest", "item": &"wood"},
		{"id": "expansion:pot:world1", "kind": "pot", "item": &"small_stone"},
	]
	for index in range(min(locations.size(), available.size())):
		var record: Dictionary = available[index]
		var atlas: String = PROP.CHEST if record["kind"] == "chest" else PROP.POT
		if not ResourceLoader.exists(atlas):
			continue
		var prop := PROP.new() as StaticBody2D
		prop.name = "Pack_" + String(record["kind"])
		prop.prop_id = String(record["id"])
		prop.kind = String(record["kind"])
		prop.reward_item = record["item"]
		prop.reward_amount = 3 if record["kind"] == "chest" else 2
		prop.position = to_local(locations[index])
		add_child(prop)
