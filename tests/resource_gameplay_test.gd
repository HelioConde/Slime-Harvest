extends Node
## Regressao real no Godot: arvores, tocos, pedras e coleta manual.

var _failed := false


func _ready() -> void:
	call_deferred("_run")


func _check(value: bool, description: String) -> bool:
	if value:
		print("PASS gameplay: ", description)
		return true
	_failed = true
	printerr("FAIL gameplay: ", description)
	return false


func _run() -> void:
	var demo: Node2D = load("res://scenes/trees/TreeChopDemo.tscn").instantiate() as Node2D
	add_child(demo)
	await get_tree().process_frame

	var player: CharacterBody2D = demo.get_node("Player") as CharacterBody2D
	var tree: Node = demo.get_node("Tree")
	if not _check(player != null and tree != null, "player and tree exist"):
		get_tree().quit(1)
		return
	var sprite: AnimatedSprite2D = tree.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		sprite = tree.get_node_or_null("Sprite2D") as AnimatedSprite2D
	if not _check(sprite != null, "tree has animated sprite"):
		get_tree().quit(1)
		return
	if not _check(sprite.sprite_frames.get_frame_count(&"wind_swaying") == 6, "tree has six sway frames"):
		get_tree().quit(1)
		return
	for hit in range(5):
		if not _check(bool(tree.call("take_axe_hit", player)), "axe hit %d of 5" % (hit + 1)):
			get_tree().quit(1)
			return
		if not _check(not bool(tree.call("can_accept_axe_hit")), "sway blocks additional hit"):
			get_tree().quit(1)
			return
		tree.call("_complete_sway")
		if hit < 4 and not _check(bool(tree.call("can_accept_axe_hit")), "next hit unlocked after sway"):
			get_tree().quit(1)
			return
	await get_tree().process_frame
	var falling: Node = demo.get_node_or_null("Tree_Fall")
	if not _check(falling != null, "five blows trigger falling scene"):
		get_tree().quit(1)
		return
	falling.call("_complete")
	await get_tree().process_frame
	var stump: Node = demo.get_node_or_null("Tree_Fall_Stump")
	if not _check(stump != null, "fall leaves stump"):
		get_tree().quit(1)
		return
	var drops: Array[Node] = get_tree().get_nodes_in_group("world_drops")
	if not _check(drops.size() == 1, "fall drops one trunk"):
		get_tree().quit(1)
		return
	for hit in range(3):
		if not _check(bool(stump.call("take_axe_hit", player)), "stump hit %d of 3" % (hit + 1)):
			get_tree().quit(1)
			return
		await get_tree().create_timer(0.39).timeout
	if not _check(not is_instance_valid(stump), "stump disappears after third blow"):
		get_tree().quit(1)
		return
	drops = get_tree().get_nodes_in_group("world_drops")
	if not _check(drops.size() == 2, "stump drops second trunk"):
		get_tree().quit(1)
		return
	var before_trunks: int = ResourceBag.get_count(&"trunk")
	for drop in drops:
		drop.call("pickup", player)
	await get_tree().process_frame
	if not _check(ResourceBag.get_count(&"trunk") == before_trunks + 2, "two trunks enter saved inventory"):
		get_tree().quit(1)
		return

	var rock: Node = demo.get_node("Scenery/RockNorth")
	var start_level: int = int(rock.call("get_mining_level"))
	if not _check(start_level == 3, "large rock starts at level3"):
		get_tree().quit(1)
		return
	for hit in range(start_level):
		if not _check(bool(rock.call("take_pickaxe_hit", player)), "pickaxe rock hit %d" % (hit + 1)):
			get_tree().quit(1)
			return
		await get_tree().create_timer(0.26).timeout
		if hit < start_level - 1 and not _check(int(rock.call("get_mining_level")) == start_level - hit - 1, "rock stage decreases"):
			get_tree().quit(1)
			return
	if not _check(not is_instance_valid(rock), "rock disappears at level zero"):
		get_tree().quit(1)
		return
	var stone_drops: int = 0
	for drop in get_tree().get_nodes_in_group("world_drops"):
		if drop.get("item_id") == &"large_stone":
			stone_drops += 1
	if not _check(stone_drops == start_level, "one stone drops per pickaxe hit"):
		get_tree().quit(1)
		return

	var flower: Node2D = demo.get_node("Scenery/FlowerPinkWest") as Node2D
	player.global_position = flower.global_position + Vector2(0, 14)
	player.call("_on_hotbar_selection", &"watering_can")
	var before_flower: int = ResourceBag.get_count(&"flower_pink")
	if not _check(bool(player.call("_try_collect_click", flower.global_position)), "flower collected while watering can is equipped"):
		get_tree().quit(1)
		return
	await get_tree().process_frame
	if not _check(ResourceBag.get_count(&"flower_pink") == before_flower + 1, "flower enters inventory"):
		get_tree().quit(1)
		return

	var mushroom: Node2D = demo.get_node("Scenery/MushroomWest") as Node2D
	player.global_position = mushroom.global_position + Vector2(0, 14)
	player.call("_on_hotbar_selection", &"axe")
	var before_mushroom: int = ResourceBag.get_count(&"mushroom_red")
	if not _check(bool(player.call("_try_collect_click", mushroom.global_position)), "mushroom collected while axe equipped"):
		get_tree().quit(1)
		return
	if not _check(ResourceBag.get_count(&"mushroom_red") == before_mushroom + 1, "mushroom enters inventory"):
		get_tree().quit(1)
		return
	print("PASS: all resource gameplay tests completed.")
	get_tree().quit(1 if _failed else 0)
