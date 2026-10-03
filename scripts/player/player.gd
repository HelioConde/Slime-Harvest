extends CharacterBody2D
## Top-down controller. Origin is at the character's feet.
signal interaction_requested(target: Node)
signal tool_use_requested(origin: Vector2, direction: Vector2)

@export_range(1.0, 500.0) var walk_speed: float = 90.0
@export_range(1.0, 3.0) var run_multiplier: float = 1.6
@export_range(0.05, 2.0) var tool_cooldown: float = 0.3
@export var controls_enabled: bool = true

var facing: Vector2 = Vector2.DOWN
var _tool_remaining: float = 0.0

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var placeholder: Polygon2D = $Placeholder
@onready var interaction_ray: RayCast2D = $InteractionRay
@onready var tool_origin: Marker2D = $ToolOrigin

func _physics_process(delta: float) -> void:
	_tool_remaining = maxf(0.0, _tool_remaining - delta)
	var direction := Vector2.ZERO
	if controls_enabled:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var running := controls_enabled and Input.is_action_pressed("run")
	if direction != Vector2.ZERO:
		if absf(direction.x) > absf(direction.y):
			facing = Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
		else:
			facing = Vector2.DOWN if direction.y > 0.0 else Vector2.UP
	var speed := walk_speed * (run_multiplier if running else 1.0)
	velocity = direction * speed
	move_and_slide()
	interaction_ray.target_position = facing * 24.0
	tool_origin.position = facing * 16.0
	var moving := get_position_delta().length_squared() > 0.001
	_update_animation(moving, running)
	if not controls_enabled:
		return
	if Input.is_action_just_pressed("interact"):
		_interact()
	if Input.is_action_just_pressed("use_tool") and _tool_remaining <= 0.0:
		_tool_remaining = tool_cooldown
		tool_use_requested.emit(tool_origin.global_position, facing)

func _update_animation(moving: bool, running: bool) -> void:
	var suffix := "down"
	if facing == Vector2.UP:
		suffix = "up"
	elif facing == Vector2.LEFT:
		suffix = "left"
	elif facing == Vector2.RIGHT:
		suffix = "right"
	var state := "walk" if moving else "idle"
	var name_to_play := StringName(state + "_" + suffix)
	animation.flip_h = false
	# Optional running frames; otherwise speed up the walking animation.
	if moving and running and _has_frames(StringName("run_" + suffix)):
		name_to_play = StringName("run_" + suffix)
	if not _has_frames(name_to_play) and suffix == "left":
		name_to_play = StringName(state + "_right")
		animation.flip_h = true
	if not _has_frames(name_to_play):
		# Keep the walking pose when idle frames are not supplied.
		name_to_play = StringName("walk_" + suffix)
		if suffix == "left" and not _has_frames(name_to_play):
			name_to_play = &"walk_right"
			animation.flip_h = true
	if not _has_frames(name_to_play):
		animation.visible = false
		placeholder.visible = true
		return
	animation.visible = true
	placeholder.visible = false
	animation.speed_scale = run_multiplier if moving and running and not String(name_to_play).begins_with("run_") else 1.0
	if animation.animation != name_to_play:
		animation.play(name_to_play)
	elif moving or state == "idle" and String(name_to_play).begins_with("idle_"):
		if not animation.is_playing():
			animation.play()
	if not moving and String(name_to_play).begins_with("walk_"):
		animation.pause()
		animation.frame = 0

func _has_frames(animation_name: StringName) -> bool:
	var frames := animation.sprite_frames
	return frames != null and frames.has_animation(animation_name) and frames.get_frame_count(animation_name) > 0

func _interact() -> void:
	interaction_ray.force_raycast_update()
	var target := interaction_ray.get_collider() as Node
	if target == null:
		return
	interaction_requested.emit(target)
	if target.has_method("interact"):
		target.call("interact", self)

func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO
