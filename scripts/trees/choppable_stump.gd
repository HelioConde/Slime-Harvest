extends StaticBody2D
## Toco restante de uma arvore: tres machadadas e mais um tronco.

@export_range(1, 20, 1) var axe_hits_required: int = 3
@export var source_tree_id: String = ""
@export var persist_stump: bool = true

var _hits: int = 0
var _busy := false
var _sprite: Sprite2D


func _ready() -> void:
	if source_tree_id.is_empty():
		source_tree_id = str(get_path())
	if persist_stump and TreePersistence.is_stump_cleared(source_tree_id):
		queue_free()
		return
	if persist_stump:
		_hits = mini(axe_hits_required - 1, TreePersistence.get_stump_hits(source_tree_id))
	_sprite = $Sprite2D as Sprite2D
	add_to_group("choppable_trees")


func hits_remaining() -> int:
	return maxi(0, axe_hits_required - _hits)


func can_accept_axe_hit() -> bool:
	return not _busy


func contains_click(world_point: Vector2) -> bool:
	if _sprite == null or _sprite.texture == null:
		return false
	var point: Vector2 = _sprite.to_local(world_point) - _sprite.offset
	var size: Vector2 = _sprite.texture.get_size()
	return Rect2(-size * 0.5, size).grow(4.0).has_point(point)


func take_axe_hit(_player: Node = null) -> bool:
	if not can_accept_axe_hit():
		return false
	_hits += 1
	if persist_stump and _hits < axe_hits_required:
		TreePersistence.save_stump_hits(source_tree_id, _hits)
	_busy = true
	var tween := create_tween()
	tween.tween_property(_sprite, "rotation", 0.08, 0.11)
	tween.tween_property(_sprite, "rotation", -0.08, 0.11)
	tween.tween_property(_sprite, "rotation", 0.0, 0.11)
	tween.finished.connect(_finish_hit)
	return true


func _finish_hit() -> void:
	_busy = false
	if _hits < axe_hits_required:
		return
	if persist_stump:
		TreePersistence.mark_stump_cleared(source_tree_id)
	ResourceBag.spawn_drop(get_parent(), global_position + Vector2(10, -4), &"trunk", source_tree_id + ":stump", persist_stump)
	queue_free()
