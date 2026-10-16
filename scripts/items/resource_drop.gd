extends Node2D
## Drop fisico: fica no chao, depois e atraido e coletado pelo jogador proximo.

@export var item_id: StringName = &"trunk"
@export var source_key: String = ""
@export var persist_drop: bool = true
@export var art_scene: String = ""
@export var art_animation: StringName = &""

@export_range(16.0, 192.0, 1.0) var magnet_radius: float = 72.0
@export_range(4.0, 32.0, 1.0) var pickup_radius: float = 12.0
@export_range(30.0, 480.0, 1.0) var magnet_speed: float = 185.0
@export_range(0.0, 2.0, 0.05) var pickup_delay: float = 0.30

const ICONS: Texture2D = preload("res://assets/Objects/Items/tools-n-meterial-items.png")
const ICON_INDEX := {"trunk": 6, "large_stone": 9, "wood": 5, "twigs": 7, "plank": 8}

var _sprite: Sprite2D
var _picked := false
var _age: float = 0.0
var _pull_speed: float = 0.0


func _ready() -> void:
	add_to_group("world_drops")
	_sprite = Sprite2D.new()
	_sprite.name = "DropIcon"
	_sprite.position = Vector2(0, -7)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.texture = _get_visual_texture()
	add_child(_sprite)
	# Entrada fisica simples com a textura existente: salta, pousa e depois flutua.
	_sprite.position.y = -7.0
	var landing: Tween = create_tween()
	landing.tween_property(_sprite, "position:y", -17.0, 0.13).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	landing.tween_property(_sprite, "position:y", -7.0, 0.20).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	landing.tween_callback(_begin_bobbing)


func _begin_bobbing() -> void:
	if _picked:
		return
	var bob: Tween = create_tween()
	bob.set_loops()
	bob.tween_property(_sprite, "position:y", -9.0, 0.55).set_trans(Tween.TRANS_SINE)
	bob.tween_property(_sprite, "position:y", -7.0, 0.55).set_trans(Tween.TRANS_SINE)


func _physics_process(delta: float) -> void:
	if _picked:
		return
	_age += delta
	if _age < pickup_delay:
		return
	var closest: Node2D = null
	var distance: float = magnet_radius
	for candidate in get_tree().get_nodes_in_group("resource_collectors"):
		var player := candidate as Node2D
		if player == null or not is_instance_valid(player):
			continue
		var measured: float = global_position.distance_to(player.global_position)
		if measured < distance and _has_clear_path(player):
			closest = player
			distance = measured
	if closest == null:
		_pull_speed = 0.0
		return
	if distance <= pickup_radius:
		pickup(closest)
		return
	var target: Vector2 = closest.global_position + Vector2(0, -4)
	var proximity: float = 1.0 - distance / magnet_radius
	_pull_speed = move_toward(_pull_speed, magnet_speed, magnet_speed * 5.0 * delta)
	var speed: float = _pull_speed * (0.55 + proximity)
	global_position = global_position.move_toward(target, speed * delta)
	if global_position.distance_to(closest.global_position) <= pickup_radius:
		pickup(closest)


func _has_clear_path(player: Node2D) -> bool:
	# Bloquear magnetismo atraves de muros, arvores e objetos no layer World (1).
	# Ignora o corpo do coletor para nao bloquear o proprio destino.
	var excluded: Array[RID] = []
	var body := player as CollisionObject2D
	if body != null:
		excluded.append(body.get_rid())
	var query := PhysicsRayQueryParameters2D.create(
		global_position, player.global_position, 1, excluded
	)
	var obstruction: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	return obstruction.is_empty()


func _get_visual_texture() -> Texture2D:
	# Flores/cogumelos devem mostrar a propria arte, inclusive apos carregar um save.
	var scene_path: String = art_scene
	if scene_path.is_empty():
		var id: String = String(item_id)
		if id.begins_with("flower_"):
			scene_path = "res://scenes/objects/flowers/" + id + ".tscn"
		elif id.begins_with("mushroom_"):
			scene_path = "res://scenes/objects/mushrooms/" + id + ".tscn"
	if not scene_path.is_empty() and ResourceLoader.exists(scene_path):
		var packed := load(scene_path) as PackedScene
		if packed != null:
			var preview: Node = packed.instantiate()
			var animated: AnimatedSprite2D = preview.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
			if animated != null and animated.sprite_frames != null:
				var frames: SpriteFrames = animated.sprite_frames
				var selected: StringName = art_animation
				if selected == &"" or not frames.has_animation(selected):
					var highest: int = 0
					for name in frames.get_animation_names():
						var label: String = String(name)
						if label.begins_with("level") and label.trim_prefix("level").is_valid_int():
							var number: int = label.trim_prefix("level").to_int()
							if number > highest:
								highest = number
								selected = name
				if frames.has_animation(selected) and frames.get_frame_count(selected) > 0:
					var graphic: Texture2D = frames.get_frame_texture(selected, 0)
					preview.free()
					return graphic
			preview.free()
	var atlas := AtlasTexture.new()
	atlas.atlas = ICONS
	var index: int = int(ICON_INDEX.get(String(item_id), 9))
	atlas.region = Rect2((index % 4) * 16, (index / 4) * 16, 16, 16)
	atlas.filter_clip = true
	return atlas


func contains_click(world_point: Vector2) -> bool:
	return Rect2(Vector2(-10, -21), Vector2(20, 24)).has_point(to_local(world_point))


func pickup(_player: Node = null) -> bool:
	if _picked:
		return false
	if not ResourceBag.collect_drop(source_key, item_id, persist_drop):
		return false
	_picked = true
	queue_free()
	return true
