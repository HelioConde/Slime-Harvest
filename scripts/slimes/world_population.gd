extends Node2D
## Uma unidade de cada especie do bestiario na fazenda. Sem sobrescrever mapas ou saves.
const MANIFEST := "res://assets/slimes/bestiary/bestiario.json"
const WANDER_SCRIPT = preload("res://scripts/slimes/slime_wander.gd")
const NEEDS = preload("res://scripts/slimes/slime_needs.gd")
const MIN_DISTANCE_FROM_PLAYER := 64.0
@onready var grass: TileMapLayer = get_node_or_null("../Map/grass2") as TileMapLayer
@onready var water: TileMapLayer = get_node_or_null("../Map/water") as TileMapLayer
@onready var player: Node2D = get_node_or_null("../Player") as Node2D
var _rng := RandomNumberGenerator.new()
var _occupied: Array[Vector2] = []
var _water_sites: Array[Vector2] = []
var _grass_sites: Array[Vector2] = []
var _navigation: AStarGrid2D



func _ready() -> void:
    _rng.randomize()
    if grass == null or player == null:
        push_error("SlimePopulation: grass2 ou Player nao encontrado no World.")
        return
    var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
    if not manifest is Dictionary or not manifest.get("species") is Array:
        push_error("SlimePopulation: bestiario invalido.")
        return
    _prepare_habitats()
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
        var slime_id: String = str(entry.get("id", ""))
        var profile: Dictionary = NEEDS.for_species(slime_id)
        var spawn: Vector2 = _find_spawn(candidates, str(profile.get("need", "")))
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
        slime.call("configure", self, _rng.randi(), _rng.randf_range(18.0, 34.0), slime_id)
        add_child(slime)
        _occupied.append(spawn)
        count += 1
    print("SlimePopulation: %d/%d slimes criados no mundo." % [count, (manifest["species"] as Array).size()])


func _find_spawn(cells: Array[Vector2i], habitat: String = "") -> Vector2:
    for separation in [38.0, 25.0, 14.0]:
        for attempt in range(320):
            var cell: Vector2i = cells[_rng.randi_range(0, cells.size() - 1)]
            var point: Vector2 = grass.to_global(grass.map_to_local(cell))
            if point.distance_to(player.global_position) < MIN_DISTANCE_FROM_PLAYER:
                continue
            if not is_safe_ground(point):
                continue
            if habitat == "water" and not _near_water(point, 90.0):
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

## Os recursos ambientais sao consultados apenas nas buscas periodicas.
## Todo alvo e uma celula caminhavel do grass2, nunca dentro de agua/obstaculo.
func _prepare_habitats() -> void:
    _water_sites.clear()
    _grass_sites.clear()
    var used := grass.get_used_cells()
    var land: Dictionary = {}
    for cell in used:
        if grass.get_cell_source_id(cell) == -1:
            continue
        if water != null and water.get_cell_source_id(cell) != -1:
            continue
        land[cell] = true
        if posmod(cell.x * 11 + cell.y * 17, 7) == 0:
            var point: Vector2 = grass.to_global(grass.map_to_local(cell))
            if is_safe_ground(point):
                _grass_sites.append(point)
    if water != null:
        var seen: Dictionary = {}
        for cell in water.get_used_cells():
            for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
                var land_cell: Vector2i = cell + direction
                if not land.has(land_cell) or seen.has(land_cell):
                    continue
                seen[land_cell] = true
                var shore_point: Vector2 = grass.to_global(grass.map_to_local(land_cell))
                if is_safe_ground(shore_point):
                    _water_sites.append(shore_point)
    _build_navigation()


func _build_navigation() -> void:
    _navigation = AStarGrid2D.new()
    _navigation.region = grass.get_used_rect()
    _navigation.cell_size = Vector2(grass.tile_set.tile_size)
    _navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
    _navigation.update()
    var rect: Rect2i = _navigation.region
    for y in range(rect.position.y, rect.end.y):
        for x in range(rect.position.x, rect.end.x):
            var cell := Vector2i(x, y)
            if grass.get_cell_source_id(cell) == -1 or (water != null and water.get_cell_source_id(cell) != -1):
                _navigation.set_point_solid(cell)


func _near_water(point: Vector2, max_distance: float) -> bool:
    for shore in _water_sites:
        if point.distance_squared_to(shore) <= max_distance * max_distance:
            return true
    return false


func find_need_target(need: String, from_point: Vector2) -> Dictionary:
    var candidates: Array[Vector2] = []
    match need:
        "water":
            candidates = _water_sites.duplicate()
        "soil", "grass", "open_air", "sun":
            candidates = _grass_sites.duplicate()
        "trees", "shade":
            candidates = _object_sites("tree")
        "wood":
            candidates = _object_sites("wood")
        "rocks":
            candidates = _object_sites("rock")
        "flowers":
            candidates = _object_sites("flower")
        "plants":
            candidates = _object_sites("plant")
        "mushrooms":
            candidates = _object_sites("mushroom")
        _:
            return {}
    if candidates.is_empty():
        return {}
    candidates.sort_custom(func(a: Vector2, b: Vector2) -> bool:
        return from_point.distance_squared_to(a) < from_point.distance_squared_to(b)
    )
    # Testa alternativas quando a mais proxima estiver inacessivel.
    for i in range(mini(12, candidates.size())):
        var destination: Vector2 = candidates[i]
        var path: PackedVector2Array = get_ground_path(from_point, destination)
        if not path.is_empty():
            return {"point": destination, "path": path}
    return {}


func _object_sites(need: String) -> Array[Vector2]:
    var points: Array[Vector2] = []
    for item in get_tree().get_nodes_in_group("world_objects"):
        var obj := item as Node2D
        if obj == null or not obj.is_visible_in_tree() or obj.is_queued_for_deletion():
            continue
        var scene_path: String = obj.scene_file_path.to_lower()
        var title: String = str(obj.name).to_lower()
        var is_tree := "/trees/" in scene_path or title.begins_with("tree")
        var is_log := "/logs/" in scene_path or title.begins_with("log")
        var is_rock := "/rocks/" in scene_path or title.begins_with("rock")
        var is_flower := "/flowers/" in scene_path or title.begins_with("flower")
        var is_mushroom := "/mushrooms/" in scene_path or title.begins_with("mushroom")
        var is_plant := is_flower or "/plants/" in scene_path or "/fruit/" in scene_path
        var matched := false
        match need:
            "tree": matched = is_tree
            "wood": matched = is_tree or is_log
            "rock": matched = is_rock
            "flower": matched = is_flower
            "plant": matched = is_plant
            "mushroom": matched = is_mushroom
        if not matched:
            continue
        for offset in [Vector2(20, 0), Vector2(-20, 0), Vector2(0, 20), Vector2(0, -20)]:
            var point: Vector2 = obj.global_position + offset
            if is_safe_ground(point):
                points.append(point)
    return points


func get_ground_path(from_point: Vector2, destination: Vector2) -> PackedVector2Array:
    var result := PackedVector2Array()
    if _navigation == null:
        return result
    var start: Vector2i = grass.local_to_map(grass.to_local(from_point))
    var finish: Vector2i = grass.local_to_map(grass.to_local(destination))
    if not _navigation.is_in_boundsv(start) or not _navigation.is_in_boundsv(finish):
        return result
    if _navigation.is_point_solid(start) or _navigation.is_point_solid(finish):
        return result
    var ids: Array[Vector2i] = _navigation.get_id_path(start, finish)
    if ids.is_empty():
        return result
    for i in range(1, ids.size()):
        result.append(grass.to_global(grass.map_to_local(ids[i])))
    result.append(destination)
    return result
