extends Node2D
## Uma unidade de cada especie do bestiario na fazenda. Sem sobrescrever mapas ou saves.
const MANIFEST := "res://assets/slimes/bestiary/bestiario.json"
const WANDER_SCRIPT = preload("res://scripts/slimes/slime_wander.gd")
const MIN_DISTANCE_FROM_PLAYER := 64.0
@onready var grass: TileMapLayer = get_node_or_null("../Map/grass2") as TileMapLayer
@onready var water: TileMapLayer = get_node_or_null("../Map/water") as TileMapLayer
@onready var player: Node2D = get_node_or_null("../Player") as Node2D
var _rng := RandomNumberGenerator.new()
var _occupied: Array[Vector2] = []


func _ready() -> void:
    _rng.randomize()
    if grass == null or player == null:
        push_error("SlimePopulation: grass2 ou Player nao encontrado no World.")
        return
    var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
    if not manifest is Dictionary or not manifest.get("species") is Array:
        push_error("SlimePopulation: bestiario invalido.")
        return
    var candidates: Array[Vector2i] = grass.get_used_cells()
    if candidates.is_empty():
        push_warning("SlimePopulation: gramado sem celulas; nenhum slime gerado.")
        return
    var count := 0
    for entry in manifest["species"]:
        if not entry is Dictionary:
            continue
        var scene_path: String = str(entry.get("scene", ""))
        if not ResourceLoader.exists(scene_path):
            push_warning("SlimePopulation: cena ausente: " + scene_path)
            continue
        var spawn: Vector2 = _find_spawn(candidates)
        if not is_finite(spawn.x):
            push_warning("SlimePopulation: nao existe espaco livre para " + str(entry.get("name", "?")))
            continue
        var packed := load(scene_path) as PackedScene
        if packed == null:
            continue
        var visual := packed.instantiate() as Node2D
        if visual == null:
            continue
        visual.name = "Visual"
        visual.scale = Vector2(0.66, 0.66)
        var slime := CharacterBody2D.new()
        slime.name = String(entry.get("id", "slime"))
        slime.collision_layer = 0
        slime.collision_mask = 1
        slime.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
        slime.set_script(WANDER_SCRIPT)
        var shape := CircleShape2D.new()
        shape.radius = 9.0
        var collision := CollisionShape2D.new()
        collision.name = "FeetCollision"
        collision.position = Vector2(0, -5)
        collision.shape = shape
        slime.add_child(collision)
        slime.add_child(visual)
        slime.position = spawn
        slime.call("configure", self, _rng.randi(), _rng.randf_range(18.0, 34.0))
        add_child(slime)
        _occupied.append(spawn)
        count += 1
    print("SlimePopulation: %d/%d slimes criados no mundo." % [count, (manifest["species"] as Array).size()])


func _find_spawn(cells: Array[Vector2i]) -> Vector2:
    for separation in [38.0, 25.0, 14.0]:
        for attempt in range(320):
            var cell: Vector2i = cells[_rng.randi_range(0, cells.size() - 1)]
            var point: Vector2 = grass.to_global(grass.map_to_local(cell))
            if point.distance_to(player.global_position) < MIN_DISTANCE_FROM_PLAYER:
                continue
            if not is_safe_ground(point):
                continue
            var far_enough := true
            for other in _occupied:
                if point.distance_to(other) < separation:
                    far_enough = false
                    break
            if far_enough:
                return point
    return Vector2(INF, INF)


func is_safe_ground(world_point: Vector2) -> bool:
    if grass == null:
        return false
    var cell: Vector2i = grass.local_to_map(grass.to_local(world_point))
    if grass.get_cell_source_id(cell) == -1:
        return false
    if water != null:
        var water_cell: Vector2i = water.local_to_map(water.to_local(world_point))
        if water.get_cell_source_id(water_cell) != -1:
            return false
    var shape := CircleShape2D.new()
    shape.radius = 8.0
    var query := PhysicsShapeQueryParameters2D.new()
    query.shape = shape
    query.transform = Transform2D(0.0, world_point + Vector2(0, -5))
    query.collision_mask = 1
    return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()
