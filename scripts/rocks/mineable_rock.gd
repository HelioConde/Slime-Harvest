extends Node2D
## Cada golpe de picareta reduz um nivel e solta uma pedra no chao.
## Pedras com level1..levelN usam sprites reais; pedras estaticas encolhem.

@export var persistent_id: String = ""
@export var persist_mining: bool = true
@export_range(1, 12, 1) var static_hits: int = 3

var _sprite: AnimatedSprite2D
var _static_sprite: Sprite2D
var _max_level: int = 0
var _level: int = 0
var _save_key: String = ""
var _busy := false


func _ready() -> void:
	_save_key = persistent_id if not persistent_id.is_empty() else str(get_path())
	_sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_static_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if _sprite != null and _sprite.sprite_frames != null:
		for animation_name in _sprite.sprite_frames.get_animation_names():
			var text_name: String = String(animation_name)
			if text_name.begins_with("level") and text_name.trim_prefix("level").is_valid_int():
				_max_level = maxi(_max_level, text_name.trim_prefix("level").to_int())
	elif _static_sprite != null and _static_sprite.texture != null:
		_max_level = static_hits
	if _max_level <= 0:
		push_warning("MineableRock: sprite sem niveis de pedra.")
		return
	_level = ResourceBag.rock_level(_save_key, _max_level) if persist_mining else _max_level
	if _level <= 0:
		queue_free()
		return
	_update_visual()
	add_to_group("mineable_rocks")


func get_mining_level() -> int:
	return _level


func can_accept_pickaxe_hit() -> bool:
	return _max_level > 0 and _level > 0 and not _busy


func contains_click(world_point: Vector2) -> bool:
	var graphic: Node2D = _sprite if _sprite != null else _static_sprite
	if graphic == null:
		return false
	var texture: Texture2D
	var offset := Vector2.ZERO
	if _sprite != null:
		texture = _sprite.sprite_frames.get_frame_texture(_sprite.animation, 0)
		offset = _sprite.offset
	else:
		texture = _static_sprite.texture
		offset = _static_sprite.offset
	if texture == null:
		return false
	var size: Vector2 = texture.get_size()
	var local_point: Vector2 = graphic.to_local(world_point) - offset
	return Rect2(-size * 0.5, size).grow(4.0).has_point(local_point)


func take_pickaxe_hit(_player: Node = null) -> bool:
	if not can_accept_pickaxe_hit():
		return false
	_busy = true
	_level -= 1
	if persist_mining:
		ResourceBag.save_rock_level(_save_key, _level)
	var drop_key: String = _save_key + ":stone:" + str(_level)
	ResourceBag.spawn_drop(get_parent(), global_position + Vector2(10, -3), &"large_stone", drop_key, persist_mining)
	_update_visual()
	var graphic: Node2D = _sprite if _sprite != null else _static_sprite
	if graphic != null:
		graphic.modulate = Color(1.0, 0.76, 0.7, 1.0)
		var tween := create_tween()
		tween.tween_property(graphic, "modulate", Color.WHITE, 0.22)
		tween.finished.connect(_finish_hit)
	else:
		_finish_hit()
	return true


func _update_visual() -> void:
	if _sprite != null and _sprite.sprite_frames != null and _level > 0:
		var stage: StringName = StringName("level%d" % _level)
		if _sprite.sprite_frames.has_animation(stage):
			_sprite.stop()
			_sprite.animation = stage
			_sprite.frame = 0
	elif _static_sprite != null:
		var factor: float = maxf(0.2, float(_level) / float(_max_level))
		_static_sprite.scale = Vector2.ONE * factor


func _finish_hit() -> void:
	_busy = false
	if _level <= 0:
		queue_free()
