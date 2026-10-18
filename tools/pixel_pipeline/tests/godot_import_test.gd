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
	assert(count == 4 or count == 8)
	for i in count:
		var texture := resource.get_frame_texture(name, i)
		assert(texture.get_width() == 64 and texture.get_height() == 64)
	var scene := load("res://Preview.tscn") as PackedScene
	assert(scene != null)
	var sprite := scene.instantiate() as AnimatedSprite2D
	assert(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)
	sprite.free()
	print("PIXEL_PIPELINE_IMPORT_OK: ", name, " / ", count)
	quit(0)
