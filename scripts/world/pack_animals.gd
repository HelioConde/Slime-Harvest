extends Node2D
## Fauna decorativa do pack Tiny Animals: sem jaulas, combate nem captura.
## Os PNGs sao opcionais e nao fazem parte do repositorio Git publico.
const ANIMAL_ROOT := "res://assets/expansion_packs/tiny_animals/"
const SPECIES := [
	"Farm Animals/chicken.png",
	"Farm Animals/cow.png",
	"Farm Animals/sheep.png",
	"Forest Animals/fox.png",
	"Birds/duck.png",
	"Pets/cat.png",
]
const MAX_VISITORS := 6

@onready var ground: TileMapLayer = get_node_or_null("../grass2") as TileMapLayer
@onready var soil: TileMapLayer = get_node_or_null("../TilledSoil") as TileMapLayer
@onready var player: CharacterBody2D = get_node_or_null("../../Player") as CharacterBody2D
var _visitors: Array[Dictionary] = []
var _elapsed: float = 0.0


func _ready() -> void:
	if ground == null or soil == null or player == null:
		return
	var locations: Array[Vector2] = _safe_locations()
	for index in range(mini(locations.size(), min(SPECIES.size(), MAX_VISITORS))):
		var source: String = ANIMAL_ROOT + SPECIES[index]
		if not ResourceLoader.exists(source):
			continue
		var picture := load(source) as Texture2D
		if picture == null or picture.get_size() != Vector2(32, 32):
			continue
		var animal := Sprite2D.new()
		animal.name = "WildVisitor_%02d" % index
		animal.texture = picture
		animal.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		animal.scale = Vector2(0.8, 0.8)
		animal.position = locations[index]
		animal.z_index = 2
		add_child(animal)
		_visitors.append({"sprite": animal, "home": locations[index], "phase": float(index) * 1.71})


func _safe_locations() -> Array[Vector2]:
	var result: Array[Vector2] = []
	var origin: Vector2 = player.global_position
	for cell in ground.get_used_cells():
		var world_position: Vector2 = ground.to_global(ground.map_to_local(cell))
		var distance: float = origin.distance_to(world_position)
		if distance < 95.0 or distance > 260.0:
			continue
		var target: Vector2i = soil.local_to_map(soil.to_local(world_position))
		# Respeitar casas, terrenos ocupados e objetos do World.
		if not str(soil.call("rejection_reason", target)).is_empty():
			continue
		var spaced := true
		for other in result:
			if other.distance_to(world_position) < 45.0:
				spaced = false
				break
		if spaced:
			result.append(to_local(world_position))
			if result.size() >= MAX_VISITORS:
				break
	return result


func _process(delta: float) -> void:
	_elapsed += delta
	for entry in _visitors:
		var sprite: Sprite2D = entry["sprite"]
		if not is_instance_valid(sprite):
			continue
		var phase: float = _elapsed * 0.53 + float(entry["phase"])
		var home: Vector2 = entry["home"]
		# Passeio pequeno apenas visual; nao atravessa grandes distancias.
		sprite.position = home + Vector2(sin(phase) * 3.0, cos(phase * 1.2) * 2.0)
		sprite.flip_h = cos(phase) < 0.0
