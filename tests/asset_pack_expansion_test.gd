extends Node
## Regressao sem distribuir sprites: mapeamento 8-way, 19 packs e recompensa.
const SKIN = preload("res://scripts/player/sprout_sorry_skin.gd")
const GALLERY = preload("res://scripts/ui/asset_pack_gallery.gd")
const PROPS = preload("res://scripts/world/reward_prop.gd")
const ANIMALS = preload("res://scripts/world/pack_animals.gd")
const SOURCE := "expansion:ci:single_reward"
var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS expansion: ", label)
	else:
		_failed = true
		printerr("FAIL expansion: ", label)


func _run() -> void:
	_check(GALLERY.ENTRIES.size() == 19, "gallery lists 19 source packs")
	_check(ANIMALS.SPECIES.size() == 6, "six peaceful animal visitors configured")
	_check(PROPS.CHEST.contains("treasure_chests") and PROPS.POT.contains("breakable_pots"),
		"chests and pots use locally installed sprites")
	var image := Image.create_empty(128, 96, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture := ImageTexture.create_from_image(image)
	var frames: SpriteFrames = SKIN.create_frames(texture)
	_check(frames != null and frames.has_animation(&"walk_left") and frames.has_animation(&"walk_right"),
		"Sprout eight-direction walking still available")
	if frames != null:
		var left: AtlasTexture = frames.get_frame_texture(&"walk_left", 0) as AtlasTexture
		var right: AtlasTexture = frames.get_frame_texture(&"walk_right", 0) as AtlasTexture
		_check(left != null and right != null and left.region.position.x == 6 * 16 and right.region.position.x == 2 * 16,
			"Sprout left/right atlas columns corrected")
		_check(int(SKIN.DIRECTIONS["down_left"]) == 5 and int(SKIN.DIRECTIONS["down_right"]) == 3,
			"lower diagonals also match horizontal direction")

	# Recompensa e progresso do mundo sao salvos no MESMO arquivo ResourceBag.
	var existing_counts: Dictionary = ResourceBag.get_all_counts()
	var existing_claims: Dictionary = (ResourceBag.get("_claimed") as Dictionary).duplicate(true)
	var amount: int = ResourceBag.get_count(&"wood")
	_check(not ResourceBag.claim_world_reward("invalid:key", &"wood", 1),
		"untrusted prefix cannot claim a world reward")
	_check(ResourceBag.claim_world_reward(SOURCE, &"wood", 3),
		"first chest claim credits wood")
	_check(not ResourceBag.claim_world_reward(SOURCE, &"wood", 3),
		"opening same chest twice cannot duplicate loot")
	_check(ResourceBag.get_count(&"wood") == amount + 3, "resource credited exactly once")
	ResourceBag.reload_session_state()
	_check(ResourceBag.world_reward_claimed(SOURCE) and ResourceBag.get_count(&"wood") == amount + 3,
		"reward survives file reload without duplication")
	ResourceBag.set("_counts", existing_counts)
	ResourceBag.set("_claimed", existing_claims)
	ResourceBag.save_session_state()

	var sample_world := load("res://scenes/world/World.tscn") as PackedScene
	_check(sample_world != null, "main map still loads")
	if sample_world != null:
		var scene := sample_world.instantiate()
		add_child(scene)
		_check(scene.has_node("Actors/Map/PackAnimalVisitors"), "main world contains peaceful animal system")
		_check(scene.has_node("Actors/Map/PackRewardProps"), "main world contains optional reward props")
		scene.queue_free()
	await get_tree().process_frame
	print("PASS expansion: complete" if not _failed else "FAIL expansion")
	get_tree().quit(1 if _failed else 1 if _failed else 0)
