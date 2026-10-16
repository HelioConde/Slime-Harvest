extends Node2D
## Obstaculos naturais removiveis, sem criar sprites ou sobrescrever o mapa.
const FX = preload("res://scripts/fx/hit_feedback.gd")
@export_range(1, 10, 1) var axe_hits_required: int = 2
@export var item_on_cut: StringName = &"twigs"
@export var persistent_id: String = ""
@export var persist_clearing: bool = true

var _hits := 0
var _key: String = ""
var _sprite: Sprite2D
var _busy := false


func _ready() -> void:
	_key = persistent_id if not persistent_id.is_empty() else str(get_path())
	if persist_clearing and ResourceBag.is_plant_collected(_key, 0):
		queue_free()
		return
	_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if _sprite == null:
		push_warning("ClearableObject: Sprite2D ausente.")
		return
	add_to_group("choppable_trees")


func contains_click(world_point: Vector2) -> bool:
	if _sprite == null or _sprite.texture == null:
		return false
	var pos: Vector2 = _sprite.to_local(world_point) - _sprite.offset
	var size: Vector2 = _sprite.texture.get_size()
	return Rect2(-size * 0.5, size).grow(3.0).has_point(pos)


func can_accept_axe_hit() -> bool:
	return not _busy and _sprite != null and not is_queued_for_deletion()


func take_axe_hit(_player: Node = null) -> bool:
	if not can_accept_axe_hit():
		return false
	_hits += 1
	FX.burst(get_parent() as Node2D, global_position + Vector2(0, -5), _sprite.texture, &"wood")
	FX.show_remaining(get_parent() as Node2D, global_position + Vector2(0, -12), axe_hits_required - _hits)
	if _hits >= axe_hits_required:
		if not ResourceBag.drop_plant(
			_key, item_on_cut, get_parent(), global_position, persist_clearing,
			scene_file_path, &"", 0
		):
			return false
		_busy = true
		queue_free()
		return true
	_busy = true
	var shake := create_tween()
	shake.tween_property(_sprite, "rotation", 0.10, 0.12)
	shake.tween_property(_sprite, "rotation", -0.08, 0.12)
	shake.tween_property(_sprite, "rotation", 0.0, 0.12)
	shake.finished.connect(func(): _busy = false)
	return true
