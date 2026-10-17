extends Node
## IA social selvagem: aproximar, assustar, investir e atacar com telegráfico.
const BEHAVIOR = preload("res://scripts/slimes/slime_temperaments.gd")
const WANDER = preload("res://scripts/slimes/slime_wander.gd")
const PLAYER = preload("res://scenes/player/Player.tscn")

class WildGuard extends Node2D:
    var player: Node2D
    func is_safe_ground(_position: Vector2) -> bool:
        return true
    func find_need_target(_need: String, _from: Vector2) -> Dictionary:
        return {}

var _guard: WildGuard
var _player: CharacterBody2D


func _ready() -> void:
    call_deferred("_run")


func _check(ok: bool, message: String) -> bool:
    if ok:
        print("PASS wild-behavior: ", message)
        return true
    printerr("FAIL wild-behavior: ", message)
    get_tree().quit(1)
    return false


func _spawn_species(species_id: String, at: Vector2) -> CharacterBody2D:
    var slime := CharacterBody2D.new()
    slime.set_script(WANDER)
    slime.name = species_id
    slime.position = at
    slime.collision_layer = 0
    slime.collision_mask = 1
    slime.call("configure", _guard, 123456, 28.0, species_id)
    _guard.add_child(slime)
    return slime


func _run() -> void:
    var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/slimes/bestiary/bestiario.json"))
    if not _check(manifest is Dictionary, "bestiary exists"):
        return
    var categories: Dictionary = {}
    for entry in manifest["species"]:
        var id: String = str(entry["id"])
        if not _check(BEHAVIOR.TEMPERAMENTS.has(id), "temperament exists: " + id):
            return
        var mode: String = str(BEHAVIOR.for_species(id)["temperament"])
        categories[mode] = true
    if not _check(BEHAVIOR.TEMPERAMENTS.size() == 32 and categories.size() == 5, "all 32 species divided into five temperaments"):
        return

    _guard = WildGuard.new()
    add_child(_guard)
    _player = PLAYER.instantiate() as CharacterBody2D
    _player.position = Vector2(70, 0)
    _guard.player = _player
    _guard.add_child(_player)
    _player.call("set_controls_enabled", false)
    await get_tree().physics_frame

    var shy := _spawn_species("riacho", Vector2(0, 0))
    shy.call("_tick_wild_social", 0.4)
    if not _check(shy.get("_social_mode") == "flee", "shy Riacho runs when player approaches"):
        return
    var shy_before: float = shy.global_position.distance_to(_player.global_position)
    shy.call("_tick_wild_social", 0.08)
    if not _check(shy.global_position.distance_to(_player.global_position) > shy_before, "flee movement increases distance"):
        return
    shy.queue_free()
    await get_tree().process_frame

    var friendly := _spawn_species("brotinho", Vector2(0, 0))
    friendly.call("_tick_wild_social", 0.4)
    if not _check(friendly.get("_social_mode") == "approach", "friendly Brotinho seeks player"):
        return
    friendly.position = Vector2(49, 0)
    friendly.call("_tick_wild_social", 0.1)
    if not _check(friendly.get("_social_mode") == "affection", "Brotinho shows affection without capture"):
        return
    friendly.queue_free()
    await get_tree().process_frame

    var curious := _spawn_species("terrinho", Vector2(0, 0))
    curious.call("_tick_wild_social", 0.4)
    if not _check(curious.get("_social_mode") == "observe", "curious Terrinho observes player"):
        return
    curious.queue_free()
    await get_tree().process_frame

    _player.position = Vector2(21, 0)
    var aggressive := _spawn_species("guardito", Vector2(0, 0))
    aggressive.call("_tick_wild_social", 0.4)
    aggressive.call("_tick_wild_social", 0.1)
    if not _check(aggressive.get("_social_mode") == "windup", "guard slime telegraphs before strike"):
        return
    if not _check(_player.get("wild_health") == 5, "windup causes no premature damage"):
        return
    aggressive.call("_tick_wild_social", 0.86)
    if not _check(_player.get("wild_health") == 4, "nearby hit reduces player HP once"):
        return
    if not _check(aggressive.get("_social_mode") == "recover" and float(aggressive.get("_attack_cooldown_left")) > 0.0, "attack enters cooldown"):
        return
    aggressive.call("_tick_wild_social", 0.3)
    if not _check(_player.get("wild_health") == 4, "cooldown prevents repeated immediate hits"):
        return
    aggressive.queue_free()
    await get_tree().process_frame

    # Fugir de um golpe avisado deve impedir dano.
    _player.set("_wild_invulnerable", 0.0)
    var dodged := _spawn_species("guardito", Vector2.ZERO)
    dodged.call("_tick_wild_social", 0.4)
    dodged.call("_tick_wild_social", 0.1)
    _player.position = Vector2(170, 0)
    dodged.call("_tick_wild_social", 0.9)
    if not _check(_player.get("wild_health") == 4, "stepping out during windup prevents damage"):
        return
    dodged.queue_free()
    await get_tree().process_frame

    # Reservas criticas tem prioridade sobre hostilidade.
    _player.position = Vector2(21, 0)
    var hungry := _spawn_species("guardito", Vector2.ZERO)
    hungry.set("need_level", 20.0)
    hungry.call("_tick_wild_social", 0.4)
    if not _check(hungry.get("_social_mode") == "none", "critical hunger overrides aggressive chase"):
        return
    hungry.queue_free()
    await get_tree().process_frame

    # Um obstaculo da layer World impede percepcao/ataque atraves de parede.
    var wall := StaticBody2D.new()
    wall.collision_layer = 1
    wall.collision_mask = 0
    wall.position = Vector2(10, 0)
    var shape := CollisionShape2D.new()
    var rect := RectangleShape2D.new()
    rect.size = Vector2(5, 80)
    shape.shape = rect
    wall.add_child(shape)
    _guard.add_child(wall)
    await get_tree().physics_frame
    var blocked := _spawn_species("guardito", Vector2.ZERO)
    blocked.call("_tick_wild_social", 0.4)
    if not _check(blocked.get("_social_mode") == "none", "solid wall blocks hostile detection"):
        return
    blocked.queue_free()
    wall.queue_free()
    await get_tree().physics_frame

    _player.position = Vector2(45, 0)
    _player.set("_wild_invulnerable", 0.0)
    var water := _spawn_species("gota", Vector2.ZERO)
    water.call("_tick_wild_social", 0.4)
    water.call("_tick_wild_social", 0.1)
    if not _check(water.get("_social_mode") == "windup", "Gota defends its home range"):
        return
    if not _check(BEHAVIOR.for_species("gota")["attack_animation"] == &"disparar_jato", "Gota uses water jet sprites"):
        return
    water.call("_tick_wild_social", 0.86)
    if not _check(_player.get("wild_health") == 3, "ranged water attack applies damage"):
        return
    water.queue_free()
    await get_tree().process_frame

    _player.set("_wild_invulnerable", 0.0)
    _player.set("wild_health", 1)
    if not _check(bool(_player.call("receive_wild_attack", 1, Vector2.ZERO)), "player can receive final wild hit"):
        return
    if not _check(_player.get("wild_health") == 5 and _player.global_position == _player.get("_wild_spawn"), "player respawns safely, no save deletion"):
        return
    print("PASS wild-behavior: flee, observe, affection, charged hits, cooldown and safe respawn")
    get_tree().quit(0)
