extends Node
## Testa a composicao dos quadros sem enviar arte de terceiros ao CI.
const SORRY = preload("res://scripts/player/sprout_sorry_skin.gd")
const SKINS = preload("res://scripts/player/player_skins.gd")


func _ready() -> void:
	call_deferred("_test")


func _check(condition: bool, name: String) -> bool:
	if condition:
		print("PASS Sprout Sorry: " + name)
	else:
		printerr("FAIL Sprout Sorry: " + name)
	return condition


func _test() -> void:
	var image := Image.create_empty(128, 96, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var atlas := ImageTexture.create_from_image(image)
	var frames: SpriteFrames = SORRY.create_frames(atlas)
	var ok := _check(frames != null, "atlas 128x96 gera SpriteFrames")
	if frames != null:
		ok = _check(frames.get_animation_names().size() == 28, "28 animacoes compativeis") and ok
		for direction in ["up", "down", "left", "right"]:
			for action in ["idle", "walk", "run", "axe", "pick", "hoe", "watering"]:
				var animation_id: StringName = StringName(action + "_" + direction)
				ok = _check(frames.has_animation(animation_id), str(animation_id)) and ok
				if frames.has_animation(animation_id):
					var count: int = frames.get_frame_count(animation_id)
					ok = _check(count == (1 if action == "idle" else 4), "%s tem quadros corretos" % animation_id) and ok
					var fragment := frames.get_frame_texture(animation_id, 0) as AtlasTexture
					ok = _check(fragment != null and fragment.region.size == Vector2(16, 32),
						"%s usa atlas 16x32" % animation_id) and ok
		ok = _check(not frames.get_animation_loop(&"axe_down"), "golpe nao repete") and ok
		ok = _check(frames.get_animation_loop(&"walk_down"), "andar repete") and ok

	# Mesmo sem instalar sprites o protagonista classico ainda pode aparecer.
	var sprite := AnimatedSprite2D.new()
	add_child(sprite)
	ok = _check(SKINS.apply(sprite, "masculino"), "skin masculino legado continua") and ok
	ok = _check(SKINS.apply(sprite, "feminino"), "skin feminino legado continua") and ok
	ok = _check(SKINS.apply(sprite, "sprout_sorry"), "Sprout Sorry com fallback seguro") and ok
	sprite.queue_free()
	print("PASS Sprout Sorry: fim" if ok else "FAIL Sprout Sorry")
	get_tree().quit(0 if ok else 1)
