extends StaticBody2D
## Apos tres golpes de machado: trocar por tree_fall e depois stump.

@export_range(1, 20, 1) var axe_hits_required: int = 3
@export var persistent_id: String = ""

const FALL_SCENE: PackedScene = preload("res://scenes/objects/trees/tree_fall.tscn")
const STUMP_SCENE: PackedScene = preload("res://scenes/objects/stumps/stump.tscn")

var _hits: int = 0
var _falling: bool = false
var _save_key: String = ""
var _sprite: AnimatedSprite2D
var _hit_tween: Tween

func _ready() -> void:
    _save_key = persistent_id if not persistent_id.is_empty() else str(get_path())
    if TreePersistence.is_felled(_save_key):
        _swap_to(STUMP_SCENE, "_Stump")
        return
    _sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
    if _sprite == null:
        _sprite = get_node_or_null("Sprite2D") as AnimatedSprite2D
    if _sprite != null and _sprite.sprite_frames != null:
        if _sprite.sprite_frames.has_animation(&"wind_swaying"):
            _sprite.play(&"wind_swaying")
        elif _sprite.sprite_frames.has_animation(&"idle"):
            _sprite.play(&"idle")

func take_axe_hit(_player: Node = null) -> void:
    if _falling or TreePersistence.is_felled(_save_key):
        return
    _hits += 1
    if _hits < axe_hits_required:
        _hit_feedback()
        return
    _falling = true
    TreePersistence.mark_felled(_save_key)
    _swap_to(FALL_SCENE, "_Fall")

func _hit_feedback() -> void:
    if _sprite == null:
        return
    if is_instance_valid(_hit_tween):
        _hit_tween.kill()
    _sprite.modulate = Color(1.0, 0.65, 0.60)
    _sprite.scale = Vector2(0.94, 1.04)
    _hit_tween = create_tween().set_parallel(true)
    _hit_tween.tween_property(_sprite, "modulate", Color.WHITE, 0.22)
    _hit_tween.tween_property(_sprite, "scale", Vector2.ONE, 0.22)

func _swap_to(scene: PackedScene, name_suffix: String) -> void:
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
    replacement.name = name + name_suffix
    queue_free()
