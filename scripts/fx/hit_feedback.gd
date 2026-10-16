extends RefCounted
## Efeitos sem assets novos: recortes de 2-3 pixels das texturas originais e audio sintetico curto.


static func burst(world_parent: Node2D, where: Vector2, texture: Texture2D, material: StringName = &"wood") -> void:
	if world_parent == null:
		return
	if texture != null:
		var dims: Vector2 = texture.get_size()
		var tile: float = minf(3.0, maxf(1.0, minf(dims.x, dims.y) * 0.15))
		for i in range(4):
			var chip := Sprite2D.new()
			var fragment := AtlasTexture.new()
			fragment.atlas = texture
			var x: float = clampf(dims.x * (0.2 + float(i % 2) * 0.4), 0.0, dims.x - tile)
			var y: float = clampf(dims.y * (0.25 + float(i / 2) * 0.3), 0.0, dims.y - tile)
			fragment.region = Rect2(x, y, tile, tile)
			chip.texture = fragment
			chip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			world_parent.add_child(chip)
			chip.global_position = where
			chip.z_index = 30
			var drift := Vector2(float(i * 5 - 8), -float(7 + (i % 2) * 4))
			var tween: Tween = chip.create_tween()
			tween.set_parallel(true)
			tween.tween_property(chip, "position", chip.position + drift, 0.27).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(chip, "modulate:a", 0.0, 0.27)
			tween.chain().tween_callback(chip.queue_free)
	_play_sound(world_parent, where, material)


static func _play_sound(parent: Node2D, at: Vector2, material: StringName) -> void:
	# PCM gerado na memoria; nenhum audio/sprite novo adicionado aos assets.
	var sample_rate: int = 16000
	var count: int = 1100
	var raw := PackedByteArray()
	raw.resize(count * 2)
	var pitch: float = 185.0 if material == &"wood" else 450.0
	for i in range(count):
		var t: float = float(i) / float(sample_rate)
		var decay: float = pow(1.0 - float(i) / float(count), 2.7)
		var tone: float = sin(TAU * pitch * t) + 0.28 * sin(TAU * pitch * 2.3 * t)
		var sample: int = int(clampf(tone * decay * 0.2, -1.0, 1.0) * 32767.0)
		if sample < 0:
			sample += 65536
		raw[i * 2] = sample & 255
		raw[i * 2 + 1] = (sample >> 8) & 255
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = raw
	var audio := AudioStreamPlayer2D.new()
	audio.stream = wav
	audio.volume_db = -19.0
	parent.add_child(audio)
	audio.global_position = at
	audio.finished.connect(audio.queue_free)
	audio.play()


static func show_remaining(parent: Node2D, position_world: Vector2, remaining: int) -> void:
	if parent == null or remaining <= 0:
		return
	var popup := Label.new()
	popup.text = str(remaining)
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.add_theme_font_size_override("font_size", 9)
	popup.add_theme_color_override("font_color", Color(1.0, 0.94, 0.75))
	popup.add_theme_constant_override("outline_size", 2)
	popup.add_theme_color_override("font_outline_color", Color(0.2, 0.18, 0.13))
	popup.custom_minimum_size = Vector2(18, 14)
	parent.add_child(popup)
	popup.global_position = position_world - Vector2(9, 13)
	popup.z_index = 40
	var tween := popup.create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 9.0, 0.52)
	tween.tween_property(popup, "modulate:a", 0.0, 0.52)
	tween.chain().tween_callback(popup.queue_free)
