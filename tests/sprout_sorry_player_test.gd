extends Node
## Testa a composicao dos quadros sem enviar arte de terceiros ao CI.
const SORRY = preload("res://scripts/player/sprout_sorry_skin.gd")
const SKINS = preload("res://scripts/player/player_skins.gd")
const TOOL_FX = preload("res://scripts/player/sprout_tool_fx.gd")


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
		ok = _check(frames.get_animation_names().size() == 56, "56 animacoes para oito direcoes") and ok
		for direction in ["up_left", "up", "left", "down_left", "down", "down_right", "right", "up_right"]:
			for action in ["idle", "walk", "run", "axe", "pick", "hoe", "watering"]:
				var animation_id: StringName = StringName(action + "_" + direction)
				ok = _check(frames.has_animation(animation_id), str(animation_id)) and ok
				if frames.has_animation(animation_id):
					var count: int = frames.get_frame_count(animation_id)
					ok = _check(count == (1 if action == "idle" else 4), "%s tem quadros corretos" % animation_id) and ok
					var fragment := frames.get_frame_texture(animation_id, 0) as AtlasTexture
					ok = _check(fragment != null and fragment.region.size == Vector2(16, 32) and fragment.region.position.x == int(SORRY.DIRECTIONS[direction]) * 16,
						"%s usa atlas 16x32" % animation_id) and ok
		ok = _check(not frames.get_animation_loop(&"axe_down"), "golpe nao repete") and ok
		ok = _check(frames.get_animation_loop(&"walk_down"), "andar repete") and ok


	ok = _check(SORRY.visual_direction(Vector2.UP) == "up", "cima usa coluna 1") and ok
	ok = _check(SORRY.visual_direction(Vector2.DOWN) == "down", "baixo usa coluna 4") and ok
	ok = _check(SORRY.visual_direction(Vector2.LEFT) == "left", "esquerda usa coluna 2") and ok
	ok = _check(SORRY.visual_direction(Vector2.RIGHT) == "right", "direita usa coluna 6") and ok
	ok = _check(SORRY.visual_direction(Vector2(-1, -1)) == "up_left", "diagonal superior esquerda") and ok
	ok = _check(SORRY.visual_direction(Vector2(1, -1)) == "up_right", "diagonal superior direita") and ok
	ok = _check(SORRY.visual_direction(Vector2(-1, 1)) == "down_left", "diagonal inferior esquerda") and ok
	ok = _check(SORRY.visual_direction(Vector2(1, 1)) == "down_right", "diagonal inferior direita") and ok

	# Provar que o overlay acompanha o quadro e some quando termina.
	var fx := TOOL_FX.new() as Node2D
	add_child(fx)
	fx.call("start_action", &"axe", "up")
	var icon := fx.get_node_or_null("ToolIcon") as Sprite2D
	ok = _check(fx.visible and icon != null and icon.texture != null, "machado visivel") and ok
	ok = _check(fx.z_index == -1, "ferramenta fica atras quando olha para cima") and ok
	fx.call("set_action_progress", 0.38)
	ok = _check(icon.rotation > 0.0 and icon.position.y < 0.0, "machado acompanha o arco de impacto") and ok
	fx.call("stop_action")
	ok = _check(not fx.visible, "efeito desaparece ao finalizar") and ok
	fx.call("start_action", &"watering_can", "right")
	ok = _check(fx.visible and fx.z_index == 1, "regador a frente na lateral") and ok
	fx.call("start_action", &"branch", "right")
	ok = _check(not fx.visible, "materiais nao ativam ferramentas") and ok
	fx.queue_free()

	# Mesmo sem instalar sprites o protagonista classico ainda pode aparecer.
	var sprite := AnimatedSprite2D.new()
	add_child(sprite)
	ok = _check(SKINS.apply(sprite, "masculino"), "skin masculino legado continua") and ok
	ok = _check(SKINS.apply(sprite, "feminino"), "skin feminino legado continua") and ok
	ok = _check(SKINS.apply(sprite, "sprout_sorry"), "Sprout Sorry com fallback seguro") and ok
	sprite.queue_free()
	print("PASS Sprout Sorry: fim" if ok else "FAIL Sprout Sorry")
	get_tree().quit(0 if ok else 1)
