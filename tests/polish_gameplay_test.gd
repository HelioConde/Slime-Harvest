extends Node
## Valida refinamentos reais, sem alterar arquivos de sprite.

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _check(condition: bool, label: String) -> bool:
	if condition:
		print("PASS polish: ", label)
	else:
		_failed = true
		printerr("FAIL polish: ", label)
	return condition


func _run() -> void:
	var demo: Node2D = load("res://scenes/trees/TreeChopDemo.tscn").instantiate() as Node2D
	add_child(demo)
	await get_tree().process_frame
	var player: CharacterBody2D = demo.get_node("Player") as CharacterBody2D
	var apple: Node2D = demo.get_node("AppleTree") as Node2D

	# Dano deve acontecer no quadro de impacto, nao no clique.
	player.global_position = apple.global_position + Vector2(0, 25)
	player.call("_on_hotbar_selection", &"axe")
	if not _check(bool(player.call("_attempt_axe_hit", apple)), "player starts axe action"):
		get_tree().quit(1)
		return
	if not _check(int(apple.get("_hits")) == 0, "axe contact is deferred to sprite frame"):
		get_tree().quit(1)
		return
	await get_tree().create_timer(0.75).timeout
	if not _check(int(apple.get("_hits")) == 1, "one actual hit at impact frame"):
		get_tree().quit(1)
		return

	# Salvar machadadas intermediarias e restaurar apos recarregar a cena.
	var tree_key: String = "test-polish-tree-progress"
	TreePersistence.reset_felled(tree_key)
	var tree_scene: PackedScene = load("res://scenes/objects/trees/tree_apple.tscn")
	var temporary: Node2D = tree_scene.instantiate() as Node2D
	temporary.set("persistent_id", tree_key)
	temporary.set("persist_felling", true)
	demo.add_child(temporary)
	for i in range(2):
		if not _check(bool(temporary.call("take_axe_hit")), "persistent tree hit"):
			get_tree().quit(1)
			return
		temporary.call("_complete_sway")
	temporary.queue_free()
	await get_tree().process_frame
	var reloaded: Node2D = tree_scene.instantiate() as Node2D
	reloaded.set("persistent_id", tree_key)
	reloaded.set("persist_felling", true)
	demo.add_child(reloaded)
	if not _check(int(reloaded.call("hits_remaining")) == 3, "tree partial hits restored"):
		get_tree().quit(1)
		return
	reloaded.queue_free()
	TreePersistence.reset_felled(tree_key)

	var stump_key: String = "test-polish-stump-progress"
	TreePersistence.reset_felled(stump_key)
	var stump_scene: PackedScene = load("res://scenes/objects/stumps/stump.tscn")
	var stump: Node2D = stump_scene.instantiate() as Node2D
	stump.set("source_tree_id", stump_key)
	demo.add_child(stump)
	if not _check(bool(stump.call("take_axe_hit")), "persistent stump hit"):
		get_tree().quit(1)
		return
	await get_tree().create_timer(0.38).timeout
	stump.queue_free()
	await get_tree().process_frame
	var restored_stump: Node2D = stump_scene.instantiate() as Node2D
	restored_stump.set("source_tree_id", stump_key)
	demo.add_child(restored_stump)
	if not _check(int(restored_stump.call("hits_remaining")) == 2, "stump partial hits restored"):
		get_tree().quit(1)
		return
	restored_stump.queue_free()
	TreePersistence.reset_felled(stump_key)

	# Pedras pequenas usam o icone de pedra pequena que ja existe no atlas.
	var small_rock: Node = demo.get_node("Scenery/RockWestSmall")
	if not _check(StringName(small_rock.get("drop_item_id")) == &"small_stone", "small rock has distinct existing atlas material"):
		get_tree().quit(1)
		return

	# Objeto entre item e jogador interrompe a atracao.
	player.global_position = Vector2(950, 900)
	var wall := StaticBody2D.new()
	wall.name = "MagnetWall"
	wall.collision_layer = 1
	wall.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 32)
	shape.shape = rect
	wall.add_child(shape)
	demo.add_child(wall)
	wall.global_position = Vector2(930, 900)
	ResourceBag.spawn_drop(demo, Vector2(910, 900), &"trunk", "test-polish-wall", false)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var pickup: Node2D = null
	for candidate in get_tree().get_nodes_in_group("world_drops"):
		if candidate.get("source_key") == "test-polish-wall":
			pickup = candidate as Node2D
	if not _check(pickup != null, "temporary drop spawned"):
		get_tree().quit(1)
		return
	if not _check(not bool(pickup.call("_has_clear_path", player)), "magnet blocked by world collision"):
		get_tree().quit(1)
		return
	var previous: int = ResourceBag.get_count(&"trunk")
	await get_tree().create_timer(0.5).timeout
	if not _check(ResourceBag.get_count(&"trunk") == previous, "blocked item not automatically credited"):
		get_tree().quit(1)
		return
	wall.queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not _check(bool(pickup.call("_has_clear_path", player)), "magnet unlocked after removing wall"):
		get_tree().quit(1)
		return
	await get_tree().create_timer(0.85).timeout
	if not _check(ResourceBag.get_count(&"trunk") == previous + 1, "item flies to player when path is clear"):
		get_tree().quit(1)
		return

	# Reaparecimento apos um dia simulado: sprite original e inventario separados.
	var original_day: int = GameCalendar.day
	var respawn_key: String = "test-polish-regrow-" + str(original_day)
	var drop_key: String = respawn_key + ":plant_drop:" + str(original_day)
	ResourceBag._picked_plants.erase(respawn_key)
	ResourceBag._drops.erase(drop_key)
	ResourceBag._claimed.erase(drop_key)
	var flower_scene: PackedScene = load("res://scenes/objects/flowers/flower_blue.tscn")
	var regrowing: Node2D = flower_scene.instantiate() as Node2D
	regrowing.set("persistent_id", respawn_key)
	regrowing.set("start_fully_grown", true)
	regrowing.set("regrow_days", 1)
	demo.add_child(regrowing)
	regrowing.global_position = Vector2(1080, 1080)
	player.global_position = Vector2(1200, 1200)
	if not _check(bool(regrowing.call("pick_by_click", player)), "harvest makes floor drop without direct inventory credit"):
		get_tree().quit(1)
		return
	if not _check(not bool(regrowing.call("can_pick")) and not regrowing.get_node("AnimatedSprite2D").visible, "plant hidden after harvest"):
		get_tree().quit(1)
		return
	GameCalendar.advance_days(1)
	if not _check(bool(regrowing.call("can_pick")) and regrowing.get_node("AnimatedSprite2D").visible, "harvested plant regrows after chosen day interval"):
		get_tree().quit(1)
		return
	regrowing.queue_free()
	for node in get_tree().get_nodes_in_group("world_drops"):
		if node.get("source_key") == drop_key:
			node.queue_free()
	ResourceBag._picked_plants.erase(respawn_key)
	ResourceBag._drops.erase(drop_key)
	ResourceBag._claimed.erase(drop_key)
	ResourceBag.call("_save_state")
	GameCalendar.day = original_day
	GameCalendar.call("_save_calendar")

	print("PASS polish: animation timing, persistence, resource variants and collision")
	get_tree().quit(1 if _failed else 0)
