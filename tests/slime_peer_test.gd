extends Node
## Encontros espontaneos entre slimes, sem ataque ou dependencia de jogador.
const WANDER = preload("res://scripts/slimes/slime_wander.gd")
const NEEDS = preload("res://scripts/slimes/slime_needs.gd")

class PeerGuard extends Node2D:
    var player: Node2D = null
    func is_safe_ground(_world_point: Vector2) -> bool:
        return true
    func find_nearby_wild_slime(requester: Node2D, max_distance: float = 84.0) -> Node2D:
        var nearest: Node2D
        var best_distance: float = max_distance * max_distance
        for candidate in get_children():
            var slime := candidate as Node2D
            if slime == null or slime == requester or slime.is_queued_for_deletion():
                continue
            if not slime.has_method("get_survival_status"):
                continue
            if str(slime.get("life_state")) != "wandering" or float(slime.get("need_level")) <= NEEDS.SEEK_BELOW:
                continue
            var distance := requester.global_position.distance_squared_to(slime.global_position)
            if distance < best_distance:
                best_distance = distance
                nearest = slime
        return nearest

var guard: PeerGuard
var attack_events: Array[String] = []


func _ready() -> void:
    call_deferred("_run")


func _check(ok: bool, message: String) -> bool:
    if ok:
        print("PASS slime-peer: ", message)
        return true
    printerr("FAIL slime-peer: ", message)
    get_tree().quit(1)
    return false


func _slime(species: String, location: Vector2) -> CharacterBody2D:
    var slime := CharacterBody2D.new()
    slime.set_script(WANDER)
    slime.position = location
    slime.name = species
    slime.collision_layer = 0
    slime.collision_mask = 1
    slime.call("configure", guard, 24680, 28.0, species)
    slime.connect("wild_attack_hit", func(_species: String, _target: Node2D) -> void:
        attack_events.append("unexpected attack")
    )
    guard.add_child(slime)
    slime.set("_peer_check_left", 0.0)
    return slime


func _run() -> void:
    guard = PeerGuard.new()
    add_child(guard)
    var friendly := _slime("brotinho", Vector2(0, 0))
    var curious := _slime("terrinho", Vector2(48, 0))
    friendly.call("_tick_wild_peer", 0.1)
    if not _check(str(friendly.get("_peer_mode")) == "approach", "friendly slime approaches a peer"):
        return
    friendly.global_position = Vector2(22, 0)
    friendly.call("_tick_wild_peer", 0.1)
    if not _check(str(friendly.get("_peer_mode")) == "play", "nearby friendly slime plays instead of fighting"):
        return
    curious.call("_tick_wild_peer", 0.1)
    if not _check(str(curious.get("_peer_mode")) == "observe", "curious slime observes another slime"):
        return

    var aggressive := _slime("guardito", Vector2(30, 15))
    aggressive.call("_tick_wild_peer", 0.1)
    if not _check(str(aggressive.get("_peer_mode")) == "observe", "aggressive slime is nonviolent to other slimes"):
        return
    if not _check(str(aggressive.get("_social_mode")) == "none", "peer meeting never triggers player combat"):
        return

    var shy := _slime("riacho", Vector2(18, 12))
    shy.call("_tick_wild_peer", 0.1)
    var partner: Node2D = shy.get("_peer_partner") as Node2D
    if not _check(str(shy.get("_peer_mode")) == "give_space" and partner != null, "shy slime gives space"):
        return
    var before: float = shy.global_position.distance_to(partner.global_position)
    shy.call("_tick_wild_peer", 0.1)
    if not _check(shy.global_position.distance_to(partner.global_position) > before, "personal-space movement increases separation"):
        return

    shy.set("need_level", 48.0)
    if not _check(not bool(shy.call("_tick_wild_peer", 0.1)) and str(shy.get("_peer_mode")) == "none", "thirst interrupts social visits"):
        return
    friendly.set("need_level", 30.0)
    if not _check(not bool(friendly.call("_tick_wild_peer", 0.1)) and str(friendly.get("_peer_mode")) == "none", "critical needs outrank playing"):
        return

    aggressive.set("_peer_partner", curious)
    aggressive.set("_peer_mode", "observe")
    curious.queue_free()
    await get_tree().process_frame
    if not _check(not bool(aggressive.call("_tick_wild_peer", 0.1)) and str(aggressive.get("_peer_mode")) == "none", "deleted partner safely ends encounter"):
        return
    if not _check(attack_events.is_empty(), "zero slime-on-slime attacks"):
        return
    print("PASS slime-peer: play, curiosity, spacing, survival priority and nonviolence")
    get_tree().quit(0)
