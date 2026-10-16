extends CharacterBody2D
## IA ambiente, sem trabalhos ou ataques. Obstaculos na layer World bloqueiam movimento.
var wander_speed: float = 28.0
var radius_from_home: float = 145.0
var home: Vector2
var world_guard: Node
var _rng := RandomNumberGenerator.new()
var _walk_direction := Vector2.ZERO
var _decision_left := 0.0
var _moving := false
@onready var _sprite: AnimatedSprite2D = get_node_or_null("Visual/AnimatedSprite2D") as AnimatedSprite2D


func configure(guard: Node, seed_value: int, speed: float) -> void:
    world_guard = guard
    _rng.seed = seed_value
    wander_speed = speed


func _ready() -> void:
    home = global_position
    _decision_left = _rng.randf_range(0.2, 1.8)
    _set_animation(&"idle")


func _physics_process(delta: float) -> void:
    _decision_left -= delta
    if _decision_left <= 0.0:
        _choose_action()
    if not _moving:
        velocity = Vector2.ZERO
        return
    var target: Vector2 = global_position + _walk_direction * wander_speed * delta * 2.0
    if global_position.distance_to(home) > radius_from_home or not _can_walk(target):
        _moving = false
        velocity = Vector2.ZERO
        _decision_left = _rng.randf_range(0.3, 1.0)
        _set_animation(&"idle")
        return
    velocity = _walk_direction * wander_speed
    move_and_slide()
    if get_slide_collision_count() > 0:
        _moving = false
        _decision_left = _rng.randf_range(0.2, 0.7)
        velocity = Vector2.ZERO
        _set_animation(&"idle")
    elif _sprite != null:
        _sprite.flip_h = _walk_direction.x < -0.05


func _choose_action() -> void:
    _moving = _rng.randf() > 0.38
    if _moving:
        var angle: float = _rng.randf_range(-PI, PI)
        _walk_direction = Vector2.RIGHT.rotated(angle)
        if global_position.distance_to(home) > radius_from_home * 0.7:
            _walk_direction = (home - global_position).normalized().rotated(_rng.randf_range(-0.5, 0.5))
        _decision_left = _rng.randf_range(0.8, 2.2)
        _set_animation(&"move")
    else:
        _decision_left = _rng.randf_range(1.0, 3.1)
        _set_animation(&"idle")


func _can_walk(world_point: Vector2) -> bool:
    if not is_instance_valid(world_guard):
        return false
    return bool(world_guard.call("is_safe_ground", world_point))


func _set_animation(anim: StringName) -> void:
    if _sprite == null or _sprite.sprite_frames == null:
        return
    var chosen := anim if _sprite.sprite_frames.has_animation(anim) else &"idle"
    if _sprite.animation != chosen or not _sprite.is_playing():
        _sprite.play(chosen)
