extends Node2D
## Reproduz a queda uma unica vez e instancia o toco ao terminar.

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
    var parent_node := get_parent()
    if parent_node != null:
        var stump := STUMP_SCENE.instantiate() as Node2D
        if stump != null:
            parent_node.add_child(stump)
            stump.global_transform = global_transform
            stump.z_index = z_index
            stump.name = name + "_Stump"
    queue_free()
