extends CharacterBody2D
## Vida selvagem: descanso, procura de recursos, absorcao e risco de dissipacao.
## Slimes selvagens nao executam tarefas de fazenda e nao usam o inventario.
signal wild_slime_died(species_id: String, at_position: Vector2)
signal wild_reaction(species_id: String, reaction: String)
signal wild_attack_hit(species_id: String, target: Node2D)
const NEEDS = preload("res://scripts/slimes/slime_needs.gd")
const TEMPERAMENTS = preload("res://scripts/slimes/slime_temperaments.gd")

var wander_speed: float = 28.0
var radius_from_home: float = 145.0
var home: Vector2
var world_guard: Node
var species_id: String = ""
var need_type: String = "grass"
var need_level: float = NEEDS.START_RESERVE
var life_state: String = "wandering"
var temperament: String = "curious"

var _profile: Dictionary = {}
var _social_profile: Dictionary = {}
var _social_mode: String = "none"
var _social_timer: float = 0.0
var _awareness_left: float = 0.0
var _attack_cooldown_left: float = 0.0
var _social_cooldown_left: float = 0.0
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
    _social_profile = TEMPERAMENTS.for_species(species_id)
    temperament = str(_social_profile["temperament"])


func _ready() -> void:
    if _profile.is_empty():
        _profile = NEEDS.for_species(species_id)
        need_type = str(_profile.get("need", "grass"))
    if _social_profile.is_empty():
        _social_profile = TEMPERAMENTS.for_species(species_id)
        temperament = str(_social_profile["temperament"])
    _awareness_left = _rng.randf_range(0.1, TEMPERAMENTS.SOCIAL_CHECK_SECONDS)
    home = global_position
    _last_position = global_position
    _decision_left = _rng.randf_range(0.2, 1.8)
    _search_left = _rng.randf_range(2.0, float(_profile["search_interval"]))
    _set_animation(&"idle")


func _physics_process(delta: float) -> void:
    if life_state == "dead":
        return
    _attack_cooldown_left = maxf(0.0, _attack_cooldown_left - delta)
    _social_cooldown_left = maxf(0.0, _social_cooldown_left - delta)
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

    if _tick_wild_social(delta):
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
        _stop_seeking(true)
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
        _stop_seeking(true)


func _begin_absorbing() -> void:
    if not _resource_still_available() or not _can_walk(global_position):
        _stop_seeking()
        return
    life_state = "absorbing"
    _moving = false
    velocity = Vector2.ZERO
    _absorb_left = float(_profile["absorb_seconds"])
    _set_animation(StringName(str(_profile.get("absorb", "happy"))))


func _finish_absorbing() -> void:
    if not _resource_still_available():
        _stop_seeking()
        return
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


func _stop_seeking(blocked_route: bool = false) -> void:
    if blocked_route and is_instance_valid(world_guard) and world_guard.has_method("invalidate_navigation"):
        world_guard.call("invalidate_navigation")
    _moving = false
    velocity = Vector2.ZERO
    life_state = "wandering"
    _path.clear()
    _decision_left = _rng.randf_range(0.3, 0.8)
    # Permite tentar outra rota na proxima verificacao.
    _search_left = minf(_search_left, 3.0)
    _set_animation(&"idle")


func _resource_still_available() -> bool:
    if not is_instance_valid(world_guard):
        return false
    if not world_guard.has_method("is_need_resource_available"):
        # Preserve lightweight previews which use mock habitat providers.
        return true
    return bool(world_guard.call("is_need_resource_available", need_type, _goal))


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
        "reserve": need_level, "state": life_state, "target": _goal,
        "temperament": temperament, "reaction": _social_mode}


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


## As reacoes sociais nao substituem o ciclo de hidratar, alimentar e descansar.
## Prioriza sobrevivencia quando a reserva esta criticamente baixa.
func _wild_player() -> Node2D:
    if not is_instance_valid(world_guard):
        return null
    return world_guard.get("player") as Node2D


func _clear_social() -> void:
    _social_mode = "none"
    _social_timer = 0.0
    _moving = false
    velocity = Vector2.ZERO
    _decision_left = _rng.randf_range(0.45, 1.2)
    if life_state != "dead":
        _set_animation(&"idle")


func _start_social(mode: String, animation_name: StringName) -> void:
    _social_mode = mode
    _moving = false
    velocity = Vector2.ZERO
    wild_reaction.emit(species_id, mode)
    _set_animation(animation_name)


func _tick_wild_social(delta: float) -> bool:
    var player: Node2D = _wild_player()
    if player == null or not player.is_inside_tree():
        if _social_mode != "none":
            _clear_social()
        return false
    var distance: float = global_position.distance_to(player.global_position)
    var emergency: bool = need_level <= TEMPERAMENTS.LOW_RESERVE_OVERRIDE
    _awareness_left -= delta
    if _social_mode == "none":
        if _awareness_left > 0.0 or _social_cooldown_left > 0.0:
            return false
        _awareness_left = TEMPERAMENTS.SOCIAL_CHECK_SECONDS + _rng.randf_range(0.0, 0.12)
        if distance > float(_social_profile["notice"]):
            return false
        if life_state == "seeking" and emergency and temperament != "shy":
            return false
        if emergency and temperament != "shy":
            return false
        if not _can_see_player(player):
            return false
        match temperament:
            "shy":
                _start_social("flee", &"move")
                _social_timer = 2.5
            "friendly":
                _start_social("approach", &"move")
                _social_timer = 4.0
            "curious":
                _start_social("observe", StringName(str(_social_profile["reaction_animation"])))
                _social_timer = 2.0
            "territorial":
                if global_position.distance_to(home) < 83.0 and distance < 68.0 and _attack_cooldown_left <= 0.0:
                    _start_social("chase", &"move")
                    _social_timer = 3.5
            "aggressive":
                if _attack_cooldown_left <= 0.0:
                    _start_social("chase", &"move")
                    _social_timer = 4.0
        if _social_mode == "none":
            return false
        # Abandona qualquer busca de alimento interrompida.
        if life_state == "seeking":
            _path.clear()
            life_state = "wandering"
    if emergency and temperament != "shy" and _social_mode not in ["windup", "recover"]:
        _clear_social()
        return false
    if _social_mode in ["windup", "recover"]:
        _social_timer -= delta
        velocity = Vector2.ZERO
        if _social_timer <= 0.0:
            if _social_mode == "windup":
                _perform_wild_strike(player)
            else:
                _clear_social()
        return true

    if _social_mode == "flee":
        if distance >= float(_social_profile["notice"]) + 36.0:
            _social_cooldown_left = 3.0
            _clear_social()
            return false
        _social_timer -= delta
        if _social_timer <= 0.0:
            _social_cooldown_left = 2.0
            _clear_social()
            return false
        _move_social(global_position - player.global_position, delta, 1.4)
        return true

    if _social_mode == "approach":
        _social_timer -= delta
        if _social_timer <= 0.0 or distance > float(_social_profile["notice"]) + 36.0:
            _social_cooldown_left = 6.0
            _clear_social()
            return false
        if distance > 26.0:
            _move_social(player.global_position - global_position, delta, 0.85)
        else:
            _start_social("affection", &"happy")
            _social_timer = 2.2
            _show_heart()
        return true

    if _social_mode == "affection" or _social_mode == "observe":
        _social_timer -= delta
        velocity = Vector2.ZERO
        if distance > float(_social_profile["notice"]) + 45.0 or _social_timer <= 0.0:
            _social_cooldown_left = 6.0
            _clear_social()
            return false
        return true

    if _social_mode == "chase":
        _social_timer -= delta
        if _social_timer <= 0.0 or distance > float(_social_profile["notice"]) + 38.0:
            _social_cooldown_left = 2.5
            _clear_social()
            return false
        if temperament == "territorial" and global_position.distance_to(home) > 94.0:
            _social_cooldown_left = 3.0
            _clear_social()
            return false
        if not _can_see_player(player):
            _social_cooldown_left = 1.5
            _clear_social()
            return false
        var reach: float = float(_social_profile["reach"])
        if distance <= reach:
            _start_social("windup", &"attack_charge")
            _social_timer = float(_social_profile["windup"])
        else:
            _move_social(player.global_position - global_position, delta, 1.28)
        return true
    return false


func _move_social(direction: Vector2, delta: float, factor: float) -> void:
    if direction.length_squared() <= 1.0:
        velocity = Vector2.ZERO
        return
    var unit: Vector2 = direction.normalized()
    var speed: float = wander_speed * factor
    var next_point: Vector2 = global_position + unit * speed * delta * 2.0
    if not _can_walk(next_point):
        var left: Vector2 = unit.rotated(PI / 3.0)
        var right: Vector2 = unit.rotated(-PI / 3.0)
        if _can_walk(global_position + left * speed * delta * 2.0):
            unit = left
        elif _can_walk(global_position + right * speed * delta * 2.0):
            unit = right
        else:
            velocity = Vector2.ZERO
            return
    velocity = unit * speed
    move_and_slide()
    if _sprite != null:
        _sprite.flip_h = unit.x < -0.05
    _set_animation(&"move")


func _can_see_player(player: Node2D) -> bool:
    var direction: Vector2 = player.global_position - global_position
    if direction.length_squared() <= 1.0:
        return true
    var origin: Vector2 = global_position + Vector2(0, -6)
    var ray := PhysicsRayQueryParameters2D.create(origin, player.global_position + Vector2(0, -6), 1, [get_rid()])
    return get_world_2d().direct_space_state.intersect_ray(ray).is_empty()


func _perform_wild_strike(player: Node2D) -> void:
    _start_social("recover", StringName(str(_social_profile["attack_animation"])))
    _social_timer = TEMPERAMENTS.STRIKE_RECOVERY
    _attack_cooldown_left = float(_social_profile["attack_cooldown"])
    _social_cooldown_left = 2.0
    if not is_instance_valid(player) or not player.has_method("receive_wild_attack"):
        return
    if global_position.distance_to(player.global_position) > float(_social_profile["reach"]):
        return
    if not _can_see_player(player):
        return
    if bool(_social_profile["ranged"]):
        _show_attack_trace(player.global_position)
    if bool(player.call("receive_wild_attack", 1, global_position)):
        wild_attack_hit.emit(species_id, player)


func _show_heart() -> void:
    var heart := Label.new()
    heart.text = "♥"
    heart.position = Vector2(-5, -26)
    heart.add_theme_color_override("font_color", Color(1.0, 0.58, 0.72))
    heart.add_theme_font_size_override("font_size", 12)
    heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(heart)
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(heart, "position:y", -38.0, 1.1)
    tween.tween_property(heart, "modulate:a", 0.0, 1.1)
    tween.chain().tween_callback(heart.queue_free)


func _show_attack_trace(target_point: Vector2) -> void:
    var effect := Line2D.new()
    effect.width = 2.0
    effect.default_color = Color(0.3, 0.82, 1.0) if need_type == "water" else Color(1.0, 0.77, 0.35)
    effect.points = PackedVector2Array([Vector2(0, -8), to_local(target_point)])
    add_child(effect)
    var tween := create_tween()
    tween.tween_property(effect, "modulate:a", 0.0, 0.28)
    tween.tween_callback(effect.queue_free)
