extends CharacterBody2D
## Vida selvagem: descanso, procura de recursos, absorcao e risco de dissipacao.
## Slimes selvagens nao executam tarefas de fazenda e nao usam o inventario.
signal wild_slime_died(species_id: String, at_position: Vector2)
const NEEDS = preload("res://scripts/slimes/slime_needs.gd")

var wander_speed: float = 28.0
var radius_from_home: float = 145.0
var home: Vector2
var world_guard: Node
var species_id: String = ""
var need_type: String = "grass"
var need_level: float = NEEDS.START_RESERVE
var life_state: String = "wandering"

var _profile: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _walk_direction := Vector2.ZERO
var _decision_left := 0.0
var _moving := false
var _search_left := 0.0
var _unmet_seconds := 0.0
var _goal: Vector2
var _path := PackedVector2Array()
var _path_index := 0
var _stuck_seconds := 0.0
var _absorb_left := 0.0
var _last_position := Vector2.ZERO
@onready var _sprite: AnimatedSprite2D = get_node_or_null("Visual/AnimatedSprite2D") as AnimatedSprite2D


func configure(guard: Node, seed_value: int, speed: float, slime_species: String = "") -> void:
    world_guard = guard
    _rng.seed = seed_value
    wander_speed = speed
    species_id = slime_species
    _profile = NEEDS.for_species(species_id)
    need_type = str(_profile.get("need", "grass"))


func _ready() -> void:
    if _profile.is_empty():
        _profile = NEEDS.for_species(species_id)
        need_type = str(_profile.get("need", "grass"))
    home = global_position
    _last_position = global_position
    _decision_left = _rng.randf_range(0.2, 1.8)
    _search_left = _rng.randf_range(2.0, float(_profile["search_interval"]))
    _set_animation(&"idle")


func _physics_process(delta: float) -> void:
    if life_state == "dead":
        return
    need_level = maxf(0.0, need_level - float(_profile["drain_per_second"]) * delta)
    if need_level <= 0.0:
        _unmet_seconds += delta
        _show_fatigue()
        if _unmet_seconds >= NEEDS.EXHAUSTION_SECONDS:
            _die()
            return
    else:
        _unmet_seconds = 0.0
        if _sprite != null:
            _sprite.modulate = Color.WHITE

    if life_state == "absorbing":
        velocity = Vector2.ZERO
        _absorb_left -= delta
        if _absorb_left <= 0.0:
            _finish_absorbing()
        return

    _search_left -= delta
    if need_level <= NEEDS.SEEK_BELOW and _search_left <= 0.0 and life_state != "seeking":
        _try_find_food()
        _search_left = float(_profile["search_interval"]) + _rng.randf_range(-2.0, 3.0)

    if life_state == "seeking":
        _follow_need_path(delta)
        return

    _decision_left -= delta
    if _decision_left <= 0.0:
        _choose_action()
    if not _moving:
        velocity = Vector2.ZERO
        return
    var target: Vector2 = global_position + _walk_direction * wander_speed * delta * 2.0
    if global_position.distance_to(home) > radius_from_home or not _can_walk(target):
        _stop_wandering()
        return
    velocity = _walk_direction * wander_speed
    move_and_slide()
    if get_slide_collision_count() > 0:
        _stop_wandering()
    elif _sprite != null:
        _sprite.flip_h = _walk_direction.x < -0.05


func _try_find_food() -> void:
    if not is_instance_valid(world_guard) or not world_guard.has_method("find_need_target"):
        return
    var destination: Dictionary = world_guard.call("find_need_target", need_type, global_position)
    if destination.is_empty():
        return
    var path: PackedVector2Array = destination.get("path", PackedVector2Array())
    if path.is_empty():
        return
    _goal = destination["point"]
    _path = path
    _path_index = 0
    _stuck_seconds = 0.0
    _last_position = global_position
    life_state = "seeking"
    _moving = true
    _set_animation(&"move")


func _follow_need_path(delta: float) -> void:
    if _path_index >= _path.size():
        if global_position.distance_to(_goal) <= 16.0 and _can_walk(_goal):
            _begin_absorbing()
        else:
            _stop_seeking()
        return
    var waypoint: Vector2 = _path[_path_index]
    var step: Vector2 = waypoint - global_position
    if step.length() <= 7.0:
        _path_index += 1
        if _path_index >= _path.size():
            if global_position.distance_to(_goal) <= 17.0:
                _begin_absorbing()
            else:
                _stop_seeking()
        return
    var direction: Vector2 = step.normalized()
    var next_point: Vector2 = global_position + direction * wander_speed * delta * 2.0
    if not _can_walk(next_point):
        _stop_seeking()
        return
    velocity = direction * wander_speed
    move_and_slide()
    if _sprite != null:
        _sprite.flip_h = direction.x < -0.05
    if get_slide_collision_count() > 0 or global_position.distance_to(_last_position) <= 0.25:
        _stuck_seconds += delta
    else:
        _stuck_seconds = 0.0
    _last_position = global_position
    if _stuck_seconds > 1.3:
        _stop_seeking()


func _begin_absorbing() -> void:
    if not _can_walk(global_position):
        _stop_seeking()
        return
    life_state = "absorbing"
    _moving = false
    velocity = Vector2.ZERO
    _absorb_left = float(_profile["absorb_seconds"])
    _set_animation(StringName(str(_profile.get("absorb", "happy"))))


func _finish_absorbing() -> void:
    need_level = NEEDS.REFILL_TO
    _unmet_seconds = 0.0
    if _sprite != null:
        _sprite.modulate = Color.WHITE
    if need_type == "water":
        # Gota/Riacho/Chuvao continuam vivendo na faixa da margem.
        home = _goal
        radius_from_home = 95.0
    life_state = "wandering"
    _path.clear()
    _decision_left = _rng.randf_range(0.8, 2.0)
    _search_left = float(_profile["search_interval"])
    _set_animation(&"happy")


func _stop_seeking() -> void:
    _moving = false
    velocity = Vector2.ZERO
    life_state = "wandering"
    _path.clear()
    _decision_left = _rng.randf_range(0.3, 0.8)
    # Permite tentar outra rota na proxima verificacao.
    _search_left = minf(_search_left, 3.0)
    _set_animation(&"idle")


func _show_fatigue() -> void:
    if _sprite == null:
        return
    _sprite.modulate = Color(1.0, 0.66, 0.66)
    if life_state == "wandering" and _decision_left <= 0.0:
        _set_animation(&"cansado")


func _die() -> void:
    life_state = "dead"
    velocity = Vector2.ZERO
    _moving = false
    wild_slime_died.emit(species_id, global_position)
    if _sprite != null:
        _set_animation(&"derrotado_dissipar")
        var tween := create_tween()
        tween.tween_property(self, "modulate:a", 0.0, 1.2)
        tween.finished.connect(queue_free)
    else:
        queue_free()


func get_survival_status() -> Dictionary:
    return {"species": species_id, "need": need_type,
        "reserve": need_level, "state": life_state, "target": _goal}


func _stop_wandering() -> void:
    _moving = false
    velocity = Vector2.ZERO
    _decision_left = _rng.randf_range(0.3, 1.0)
    _set_animation(&"idle")


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
