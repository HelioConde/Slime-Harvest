extends Node
## Regressao das especies frutiferas e das novas superficies com TileSet original.

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _check(yes: bool, label: String) -> bool:
	if yes:
		print("PASS fruit-terrain: ", label)
	else:
		_failed = true
		printerr("FAIL fruit-terrain: ", label)
	return yes


func _run() -> void:
	var tiles: TileSet = load("res://data/tilesets/world_tileset.tres")
	if not _check(tiles != null and tiles.get_terrain_sets_count() >= 18, "original TileSet has all terrain configurations"):
		get_tree().quit(1)
		return
	# Criar seis superficies temporarias na memoria; nenhuma cena World/Demo e necessaria.
	var gallery := Node2D.new()
	gallery.name = "Patches"
	add_child(gallery)
	var patch_script: Script = load("res://scripts/world/terrain_patch.gd") as Script
	var terrain_sets: Array[int] = [9, 3, 11, 5, 13, 17]
	var patches: Array[TileMapLayer] = []
	for chosen_set in terrain_sets:
		var patch := TileMapLayer.new()
		patch.set_script(patch_script)
		patch.tile_set = tiles
		patch.set("terrain_set_index", chosen_set)
		gallery.add_child(patch)
		patches.append(patch)
	await get_tree().process_frame
	if not _check(patches.size() == 6, "six temporary surfaces available"):
		get_tree().quit(1)
		return
	for patch in patches:
		if not _check(patch.tile_set == tiles and patch.get_used_cells().size() >= 40,
			"%s builds cells using shared original tileset" % patch.name):
			get_tree().quit(1)
			return
		var chosen: int = int(patch.get("terrain_set_index"))
		if not _check(tiles.get_terrains_count(chosen) > 0, "terrain set %d has configured transitions" % chosen):
			get_tree().quit(1)
			return

	# Pintura manual deve permanecer apos _ready da TileMapLayer.
	var manual := TileMapLayer.new()
	manual.set_script(patch_script)
	manual.tile_set = tiles
	manual.set("terrain_set_index", 9)
	manual.set_cell(Vector2i(0, 0), 30, Vector2i(1, 1))
	add_child(manual)
	if not _check(manual.get_used_cells().size() == 1, "manual tile painting is preserved"):
		get_tree().quit(1)
		return

	for species in ["apple", "orange", "peach", "pear"]:
		var source: PackedScene = load("res://scenes/objects/trees/tree_%s.tscn" % species)
		if not _check(source != null, "%s has its own scene" % species):
			get_tree().quit(1)
			return
		var tree := source.instantiate() as Node2D
		var tree_name: String = species.capitalize() + "Tree"
		tree.name = tree_name
		tree.set("persist_felling", false)
		add_child(tree)
		var sprite := tree.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if not _check(sprite != null and sprite.sprite_frames != null, "%s uses AnimatedSprite2D" % species):
			get_tree().quit(1)
			return
		for anim in [&"idle", &"growing", &"wind_swaying", &"falling"]:
			if not _check(sprite.sprite_frames.has_animation(anim), "%s provides %s" % [species, anim]):
				get_tree().quit(1)
				return
		if not _check(not sprite.sprite_frames.get_animation_loop(&"falling"), "%s fall animation is not looping" % species):
			get_tree().quit(1)
			return
		if not _check(sprite.sprite_frames.get_frame_count(&"falling") == 12, "%s has twelve original falling frames" % species):
			get_tree().quit(1)
			return
		for hit in range(5):
			if not _check(bool(tree.call("take_axe_hit")), "%s axe hit %d" % [species, hit + 1]):
				get_tree().quit(1)
				return
			tree.call("_complete_sway")
		var falling: Node = get_node_or_null(tree_name + "_Fall")
		if not _check(falling != null, "%s drops its own falling instance" % species):
			get_tree().quit(1)
			return
		var fallen_sprite: AnimatedSprite2D = falling.get_node("AnimatedSprite2D") as AnimatedSprite2D
		if not _check(fallen_sprite.sprite_frames == sprite.sprite_frames, "%s fall reuses its species-specific texture atlas" % species):
			get_tree().quit(1)
			return
		falling.call("_complete")
		await get_tree().process_frame
		var stump: Node = get_node_or_null(tree_name + "_Fall_Stump")
		if not _check(stump != null, "%s leaves a choppable stump" % species):
			get_tree().quit(1)
			return
		stump.queue_free()
	print("PASS fruit-terrain: all four fruit trees and six terrain patches validated")
	get_tree().quit(1 if _failed else 0)
