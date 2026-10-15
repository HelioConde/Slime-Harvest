extends StaticBody2D
## Cinco golpes validos; cada golpe reproduz os seis quadros wind_swaying inteiros.

@export_range(1, 20, 1) var axe_hits_required: int = 5
@export var persistent_id: String = ""
@export var persist_felling: bool = true

const FALL_SCENE: PackedScene = preload("res://scenes/objects/trees/tree_fall.tscn")
const STUMP_SCENE: PackedScene = preload("res://scenes/objects/stumps/stump.tscn")

var _hits: int = 0
var _swaying: bool = false
var _falling: bool = false
var _save_key: String = ""
var _sprite: AnimatedSprite2D
var _static_sprite: Sprite2D
var _static_sway_tween: Tween


func _ready() -> void:
	_save_key = persistent_id if not persistent_id.is_empty() else str(get_path())
	if persist_felling and TreePersistence.is_felled(_save_key):
		_swap_to(STUMP_SCENE, "_Stump")
		return
	add_to_group("choppable_trees")
	_sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if _sprite == null:
		_sprite = get_node_or_null("Sprite2D") as AnimatedSprite2D
	if _sprite == null:
		_static_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if _sprite != null and _sprite.sprite_frames != null:
		_sprite.animation_finished.connect(_on_sway_finished)
		if _sprite.sprite_frames.has_animation(&"idle"):
			_sprite.play(&"idle")
		else:
			_sprite.stop()
	elif _static_sprite == null:
		push_warning("ChoppableTree: sprite ausente; machado desativado.")


func can_accept_axe_hit() -> bool:
	return not _swaying and not _falling and (_static_sprite != null or (_sprite != null and _sprite.sprite_frames != null)) and (not persist_felling or not TreePersistence.is_felled(_save_key))


func contains_click(world_point: Vector2) -> bool:
	if _sprite != null and _sprite.sprite_frames != null:
		var count: int = _sprite.sprite_frames.get_frame_count(_sprite.animation)
		if count <= 0:
			return false
		var anim_texture: Texture2D = _sprite.sprite_frames.get_frame_texture(
			_sprite.animation, clampi(_sprite.frame, 0, count - 1)
		)
		if anim_texture == null:
			return false
		var point: Vector2 = _sprite.to_local(world_point) - _sprite.offset
		return Rect2(anim_texture.get_size() * -0.5, anim_texture.get_size()).grow(3.0).has_point(point)
	if _static_sprite != null and _static_sprite.texture != null:
		var tex: Texture2D = _static_sprite.texture
		var point: Vector2 = _static_sprite.to_local(world_point) - _static_sprite.offset
		return Rect2(tex.get_size() * -0.5, tex.get_size()).grow(3.0).has_point(point)
	return false


func take_axe_hit(_player: Node = null) -> bool:
	if not can_accept_axe_hit():
		return false
	if _sprite != null and not _sprite.sprite_frames.has_animation(&"wind_swaying"):
		push_warning("ChoppableTree: wind_swaying nao encontrada.")
		return false
	_hits += 1
	_swaying = true
	if _sprite != null:
		_sprite.stop()
		_sprite.frame = 0
		_sprite.play(&"wind_swaying")
	else:
		_animate_static_sway()
	return true


func _animate_static_sway() -> void:
	if _static_sprite == null:
		_swaying = false
		return
	if is_instance_valid(_static_sway_tween):
		_static_sway_tween.kill()
	_static_sprite.rotation = 0.0
	_static_sway_tween = create_tween()
	# Seis movimentos a 5 passos/s equivalem a 1,2 s de balanco.
	for angle in [0.05, -0.05, 0.04, -0.035, 0.02, 0.0]:
		_static_sway_tween.tween_property(_static_sprite, "rotation", angle, 0.2)
	_static_sway_tween.finished.connect(_on_static_sway_finished)


func _on_static_sway_finished() -> void:
	if _swaying and not _falling:
		_complete_sway()


func _on_sway_finished() -> void:
	if _swaying and _sprite != null and _sprite.animation == &"wind_swaying":
		_complete_sway()


func _complete_sway() -> void:
	_swaying = false
	if _static_sprite != null:
		_static_sprite.rotation = 0.0
	if _hits >= axe_hits_required:
		_falling = true
		if persist_felling:
			TreePersistence.mark_felled(_save_key)
		_swap_to(FALL_SCENE, "_Fall")
	elif _sprite != null and _sprite.sprite_frames.has_animation(&"idle"):
		_sprite.play(&"idle")


func _swap_to(scene: PackedScene, suffix: String) -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return
	var replacement := scene.instantiate() as Node2D
	if replacement == null:
		push_error("ChoppableTree: cena de substituicao invalida.")
		return
	parent_node.add_child(replacement)
	replacement.global_transform = global_transform
	replacement.z_index = z_index
	replacement.name = name + suffix
	queue_free()
