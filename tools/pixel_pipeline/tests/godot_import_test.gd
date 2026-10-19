extends SceneTree

func _initialize() -> void:
	var resource := load("res://frames.tres") as SpriteFrames
	if resource == null:
		push_error("SpriteFrames não carregou")
		quit(1)
		return
	var names := resource.get_animation_names()
	assert(names.size() == 1)
	var name := names[0]
	var count := resource.get_frame_count(name)
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://metadata.json"))
	assert(count == int(metadata.frame_count))
	assert(is_equal_approx(resource.get_animation_speed(name), float(metadata.fps)))
	assert(resource.get_animation_loop(name) == bool(metadata.get("loop", true)))
	for i in count:
		var texture := resource.get_frame_texture(name, i)
		assert(texture.get_width() == 64 and texture.get_height() == 64)
		if metadata.has("durations"):
			assert(is_equal_approx(resource.get_frame_duration(name, i), float(metadata.durations[i])))
	var scene := load("res://Preview.tscn") as PackedScene
	assert(scene != null)
	var sprite := scene.instantiate() as AnimatedSprite2D
	assert(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)
	sprite.free()
	print("PIXEL_PIPELINE_IMPORT_OK: ", name, " / ", count)
	quit(0)
