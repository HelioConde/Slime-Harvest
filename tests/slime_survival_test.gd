extends Node
## Teste do ciclo selvagem em uma instancia descartavel do mundo.
const NEEDS = preload("res://scripts/slimes/slime_needs.gd")


func _ready() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> bool:
	if ok:
		print("PASS slime-survival: ", message)
		return true
	printerr("FAIL slime-survival: ", message)
	get_tree().quit(1)
	return false


func _run() -> void:
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/slimes/bestiary/bestiario.json"))
	if not _check(manifest is Dictionary, "bestiary manifest exists"):
		return
	var profiles: Dictionary = NEEDS.PROFILE
	for species in manifest["species"]:
		var species_id: String = str(species["id"])
		if not _check(profiles.has(species_id), "biome needs defined for " + species_id):
			return
	if not _check(profiles.size() == (manifest["species"] as Array).size(), "all 32 wild species have a survival profile"):
		return
	var world := load("res://scenes/world/World.tscn").instantiate() as Node2D
	add_child(world)
	await get_tree().process_frame
	await get_tree().physics_frame
	var population := world.get_node("Actors/SlimePopulation") as Node2D
	if not _check(population.get_child_count() == 32, "all 32 species spawned"):
		return
	var water_sites: Array[Vector2] = population.get("_water_sites")
	if not _check(not water_sites.is_empty(), "shoreline provides water from grass2"):
		return
	# Cada uma das necessidades diferentes deve apontar para algo que exista no mapa.
	var unique_needs: Dictionary = {}
	for species in manifest["species"]:
		var slime_id: String = str(species["id"])
		var profile: Dictionary = NEEDS.for_species(slime_id)
		unique_needs[str(profile["need"])] = slime_id
	for kind in unique_needs:
		var representative: Node2D = population.get_node(str(unique_needs[kind])) as Node2D
		var site: Dictionary = population.call("find_need_target", str(kind), representative.global_position)
		if site.is_empty():
			var raw_sites: Array[Vector2] = population.call("_object_sites", str(kind).trim_suffix("s"))
			print("DIAGNOSTIC slime-survival: need=", kind, " candidate_sites=", raw_sites.size(), " representative=", representative.global_position)
		if not _check(not site.is_empty(), "habitat resource accessible: " + str(kind)):
			return
	var gota := population.get_node_or_null("gota") as CharacterBody2D
	if not _check(gota != null and gota.get("need_type") == "water", "Gota has water as essential need"):
		return
	gota.set("need_level", 50.0)
	gota.call("_try_find_food")
	var info: Dictionary = gota.call("get_survival_status")
	if not _check(info.get("state") == "seeking", "Gota actively seeks water when thirsty"):
		return
	if not _check(population.call("_near_water", info["target"], 20.0), "Gota targets safe land beside water"):
		return
	gota.global_position = info["target"]
	gota.call("_begin_absorbing")
	if not _check(str(gota.get("life_state")) == "absorbing", "Gota plays absorption near water"):
		return
	gota.call("_finish_absorbing")
	if not _check(is_equal_approx(float(gota.get("need_level")), 100.0), "Gota restores reserve from water"):
		return
	var terrinho := population.get_node("terrinho") as CharacterBody2D
	if not _check(terrinho.get("need_type") == "soil", "Terrinho seeks its own soil resource"):
		return
	var shade := population.get_node("gelito") as CharacterBody2D
	if not _check(shade.get("need_type") == "shade", "Gelito seeks shade rather than water"):
		return
	var dead_slime := population.get_node("chuvao") as CharacterBody2D
	dead_slime.set("need_level", 0.0)
	dead_slime.set("_unmet_seconds", NEEDS.EXHAUSTION_SECONDS - 0.1)
	dead_slime.call("_physics_process", 0.2)
	if not _check(dead_slime.get("life_state") == "dead", "wild slime can eventually perish if need unmet"):
		return
	world.queue_free()
	await get_tree().process_frame
	print("PASS slime-survival: species habitats, Gota hydration and wild exhaustion")
	get_tree().quit(0)
