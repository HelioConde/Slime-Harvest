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


func _ready() -> void:
	_save_key = persistent_id if not persistent_id.is_empty() else str(get_path())
	if persist_felling and TreePersistence.is_felled(_save_key):
		_swap_to(STUMP_SCENE, "_Stump")
		return
	add_to_group("choppable_trees")
	_sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if _sprite == null:
		_sprite = get_node_or_null("Sprite2D") as AnimatedSprite2D
	if _sprite == null or _sprite.sprite_frames == null:
		push_warning("ChoppableTree: AnimatedSprite2D nao encontrado.")
		return
	_sprite.animation_finished.connect(_on_sway_finished)
	if _sprite.sprite_frames.has_animation(&"idle"):
		_sprite.play(&"idle")
	else:
		_sprite.stop()


func can_accept_axe_hit() -> bool:
	return not _swaying and not _falling and _sprite != null and (not persist_felling or not TreePersistence.is_felled(_save_key))


func contains_click(world_point: Vector2) -> bool:
	if _sprite == null or _sprite.sprite_frames == null:
		return false
	var frame_count := _sprite.sprite_frames.get_frame_count(_sprite.animation)
	if frame_count <= 0:
		return false
	var texture := _sprite.sprite_frames.get_frame_texture(
		_sprite.animation, clampi(_sprite.frame, 0, frame_count - 1)
	)
	if texture == null:
		return false
	var pos := _sprite.to_local(world_point) - _sprite.offset
	var size := texture.get_size()
	return Rect2(size * -0.5, size).grow(3.0).has_point(pos)


func take_axe_hit(_player: Node = null) -> bool:
	if not can_accept_axe_hit():
		return false
	if not _sprite.sprite_frames.has_animation(&"wind_swaying"):
		push_error("ChoppableTree: animacao wind_swaying ausente.")
		return false
	_hits += 1
	_swaying = true
	_sprite.stop()
	_sprite.frame = 0
	_sprite.play(&"wind_swaying")
	return true


func _on_sway_finished() -> void:
	if not _swaying or _sprite.animation != &"wind_swaying":
		return
	_swaying = false
	if _hits >= axe_hits_required:
		_falling = true
		if persist_felling:
			TreePersistence.mark_felled(_save_key)
		_swap_to(FALL_SCENE, "_Fall")
	elif _sprite.sprite_frames.has_animation(&"idle"):
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
