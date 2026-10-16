extends Node2D
## Cada levelN representa uma imagem de uma fase; avanca a cada 3 dias de jogo.
## Funciona com 3, 4 ou mais fases sem alterar as texturas originais.

@export_range(1, 30, 1) var days_per_stage: int = 3
@export var use_calendar: bool = true
@export var persistent_id: String = ""
@export var start_fully_grown: bool = false
@export var persist_pickup: bool = true

var _collectible_item: StringName = &""
var _pickup_key: String = ""
var _picked_up: bool = false

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

var growth_level: int = 1
var planted_day: int = 1
var _max_level: int = 0
var _save_key: String = ""
var _growth_tween: Tween


func _ready() -> void:
    # Flores/cogumelos decorativos podem ser coletados com clique sem ferramenta.
    var source_name: String = scene_file_path.get_file().get_basename().to_lower()
    if source_name.is_empty():
        source_name = name.to_snake_case()
    if source_name.begins_with("flower_") or source_name.begins_with("mushroom_"):
        _collectible_item = StringName(source_name)
    _pickup_key = persistent_id if not persistent_id.is_empty() else str(get_path())
    if _collectible_item != &"" and use_calendar:
        if persist_pickup and ResourceBag.is_plant_collected(_pickup_key):
            _picked_up = true
            queue_free()
            return
        add_to_group("pickable_plants")
    if sprite == null or sprite.sprite_frames == null:
        push_warning("PlantGrowth: AnimatedSprite2D ausente ou vazio.")
        return
    for anim in sprite.sprite_frames.get_animation_names():
        var anim_name := String(anim)
        if anim_name.begins_with("level") and anim_name.trim_prefix("level").is_valid_int():
            _max_level = maxi(_max_level, anim_name.trim_prefix("level").to_int())
    if _max_level <= 0:
        push_warning("PlantGrowth: nenhuma animacao levelN encontrada.")
        return
    if start_fully_grown:
        set_growth_level(_max_level, false)
        return
    if use_calendar:
        _save_key = persistent_id if not persistent_id.is_empty() else str(get_path())
        planted_day = GameCalendar.get_or_create_planting_day(_save_key)
        GameCalendar.day_changed.connect(_on_day_changed)
        _refresh_from_calendar(false)
    else:
        set_growth_level(1, false)


func _on_day_changed(_new_day: int) -> void:
    _refresh_from_calendar(true)


func _refresh_from_calendar(animate: bool) -> void:
    var days_grown := maxi(0, GameCalendar.day - planted_day)
    var expected_level := mini(_max_level, 1 + floori(float(days_grown) / float(days_per_stage)))
    set_growth_level(expected_level, animate)


func set_growth_level(level: int, animate: bool = true) -> void:
    if sprite == null or _max_level <= 0:
        return
    var next_level := clampi(level, 1, _max_level)
    var changed := growth_level != next_level
    growth_level = next_level
    var animation_name := StringName("level%d" % growth_level)
    if not sprite.sprite_frames.has_animation(animation_name):
        return
    sprite.stop()
    sprite.animation = animation_name
    sprite.frame = 0
    if is_instance_valid(_growth_tween):
        _growth_tween.kill()
    sprite.scale = Vector2.ONE
    sprite.modulate.a = 1.0
    if animate and changed:
        sprite.scale = Vector2(0.8, 0.8)
        sprite.modulate.a = 0.7
        _growth_tween = create_tween()
        _growth_tween.set_parallel(true)
        _growth_tween.tween_property(sprite, "scale", Vector2(1.12, 1.12), 0.25).set_trans(Tween.TRANS_BACK)
        _growth_tween.tween_property(sprite, "modulate:a", 1.0, 0.25)
        _growth_tween.chain().tween_property(sprite, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_SINE)


func replant_today() -> void:
    if use_calendar and not start_fully_grown:
        planted_day = GameCalendar.replant(_save_key)
    set_growth_level(1, false)


func is_mature() -> bool:
    return _max_level > 0 and growth_level >= _max_level


func get_max_level() -> int:
    return _max_level


func can_pick() -> bool:
    return not _picked_up and use_calendar and _collectible_item != &"" and sprite != null


func contains_click(world_point: Vector2) -> bool:
    if not can_pick() or sprite.sprite_frames == null:
        return false
    var texture: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
    if texture == null:
        return false
    var size: Vector2 = texture.get_size()
    var hit_position: Vector2 = sprite.to_local(world_point) - sprite.offset
    return Rect2(-size * 0.5, size).grow(4.0).has_point(hit_position)


func pick_by_click(_player: Node = null) -> bool:
    if not can_pick():
        return false
    if not ResourceBag.drop_plant(
        _pickup_key, _collectible_item, get_parent(), global_position,
        persist_pickup, scene_file_path, sprite.animation
    ):
        return false
    _picked_up = true
    queue_free()
    return true
