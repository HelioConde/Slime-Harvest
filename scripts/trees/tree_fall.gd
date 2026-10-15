extends Node2D
## Terminou falling: solta um tronco e deixa um toco com tres golpes.

@export var source_tree_id: String = ""
@export var persist_stump: bool = true

const STUMP_SCENE: PackedScene = preload("res://scenes/objects/stumps/stump.tscn")
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var _completed := false


func _ready() -> void:
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
