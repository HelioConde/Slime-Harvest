extends Node2D
## Automatic entrance using the existing six vertical-door frames.
@export var open_distance: float = 28.0
@export var close_distance: float = 40.0
@export var animation_duration: float = 0.3
var player: CharacterBody2D
var construction_mode: bool = false
var openness: float = 0.0
var wants_open: bool = false
var sprite: Sprite2D
var collider: CollisionShape2D

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = preload("res://assets/tilesets/Building parts/door animation sprites.png")
	sprite.region_enabled = true
	sprite.region_rect = Rect2(80, 0, 16, 16)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	var body: StaticBody2D = StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 2
	add_child(body)
	collider = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(12, 8)
	collider.shape = shape
	collider.position = Vector2(0, 4)
	body.add_child(collider)
	z_index = 6

func _process(delta: float) -> void:
	if not visible or player == null or not is_instance_valid(player):
		collider.set_deferred("disabled", true)
		return
	var distance: float = global_position.distance_to(player.global_position)
	if distance <= open_distance:
		wants_open = true
	elif distance >= maxf(close_distance, open_distance + 1.0):
		wants_open = false
	var target: float = 1.0 if wants_open else 0.0
	openness = move_toward(openness, target, delta / maxf(animation_duration, 0.01))
	# Sheet order is open -> closed. Reverse it for opening.
	var frame_index: int = 5 - clampi(roundi(openness * 5.0), 0, 5)
	sprite.region_rect = Rect2(frame_index * 16, 0, 16, 16)
	# Release before fully open; never close a collider over the player.
	collider.set_deferred("disabled", construction_mode or openness >= 0.6 or distance < 12.0)
