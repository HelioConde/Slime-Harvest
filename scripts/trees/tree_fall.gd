extends Node2D
## Terminou falling: solta um tronco e deixa um toco com tres golpes.

@export var source_tree_id: String = ""
@export var persist_stump: bool = true
var fall_frames: SpriteFrames
var fall_texture: Texture2D
var fall_offset: Vector2 = Vector2(0, -15.5)

const STUMP_SCENE: PackedScene = preload("res://scenes/objects/stumps/stump.tscn")
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var _completed := false


func _ready() -> void:
	if fall_texture != null:
		# Especies com Sprite2D estatico usam a arte que ja possuem.
		sprite.hide()
		var art := Sprite2D.new()
		art.texture = fall_texture
		art.position = fall_offset
		art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(art)
		var fall_tween := create_tween()
		fall_tween.set_parallel(true)
		fall_tween.tween_property(art, "rotation", 1.25, 0.72).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		fall_tween.tween_property(art, "position", fall_offset + Vector2(19, 11), 0.72)
		fall_tween.tween_property(art, "modulate:a", 0.0, 0.72).set_delay(0.30)
		fall_tween.chain().tween_callback(_complete)
		return
	if fall_frames != null and fall_frames.has_animation(&"falling"):
		sprite.sprite_frames = fall_frames
		sprite.position = fall_offset
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(&"falling"):
		push_error("TreeFall: animacao falling nao encontrada.")
		_complete()
		return
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play(&"falling")


func _on_animation_finished() -> void:
	if sprite.animation == &"falling":
		_complete()


func _complete() -> void:
	if _completed:
		return
	_completed = true
	var parent_node: Node = get_parent()
	if parent_node != null:
		var stump: Node2D = STUMP_SCENE.instantiate() as Node2D
		if stump != null:
			stump.set("source_tree_id", source_tree_id)
			stump.set("persist_stump", persist_stump)
			parent_node.add_child(stump)
			stump.global_transform = global_transform
			stump.z_index = z_index
			stump.name = name + "_Stump"
		ResourceBag.spawn_drop(parent_node, global_position + Vector2(-13, 0), &"trunk", source_tree_id + ":fall", persist_stump)
	queue_free()
