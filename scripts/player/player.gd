extends CharacterBody2D
## Personagem e equipamentos, com hotbar e categorias por acessorio.

signal interaction_requested(target: Node)
signal tool_use_requested(origin: Vector2, direction: Vector2)
signal tool_action_requested(tool_id: StringName, world_position: Vector2)

const INVENTORY_SCRIPT = preload("res://scripts/items/tool_inventory.gd")
const HOTBAR_SCENE: PackedScene = preload("res://scenes/ui/ToolHotbar.tscn")

@export_range(1.0, 500.0) var walk_speed: float = 90.0
@export_range(1.0, 3.0) var run_multiplier: float = 1.6
@export_range(0.05, 2.0) var tool_cooldown: float = 0.3
@export var controls_enabled: bool = true
@export_range(16.0, 96.0, 1.0) var tool_reach: float = 60.0
@export_range(0.5, 3.0, 0.05) var tool_animation_speed: float = 1.65

var facing: Vector2 = Vector2.DOWN
var _tool_remaining: float = 0.0
var _action_animating: bool = false
var _equipment: Node
var _hotbar: Control

@onready var animation: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
@onready var placeholder: Polygon2D = get_node_or_null("Placeholder") as Polygon2D
@onready var interaction_ray: RayCast2D = $InteractionRay
@onready var tool_origin: Marker2D = $ToolOrigin


func _ready() -> void:
	if animation == null:
		push_error("Player: mantenha AnimatedSprite2D como filho direto.")
		set_physics_process(false)
		return
	animation.animation_finished.connect(_on_action_animation_finished)
	_equipment = INVENTORY_SCRIPT.new()
	_equipment.name = "ToolInventory"
	_equipment.connect("tool_changed", Callable(self, "_on_tool_changed"))
	add_child(_equipment)
	var hud_layer := CanvasLayer.new()
	hud_layer.name = "EquipmentHUD"
	hud_layer.layer = 13
	add_child(hud_layer)
	_hotbar = HOTBAR_SCENE.instantiate() as Control
	hud_layer.add_child(_hotbar)
	_hotbar.connect("tool_selected", Callable(self, "_on_hotbar_selection"))
	_hotbar.call("set_selected_tool", _current_tool())


func _current_tool() -> StringName:
	if _equipment == null:
		return &"axe"
	return StringName(_equipment.call("get_equipped_tool"))


func _on_hotbar_selection(tool_id: StringName) -> void:
	if controls_enabled and not _action_animating and _equipment != null:
		_equipment.call("equip", tool_id)


func _on_tool_changed(tool_id: StringName) -> void:
	if _hotbar != null:
		_hotbar.call("set_selected_tool", tool_id)


func _input(event: InputEvent) -> void:
	if not controls_enabled or _action_animating or _equipment == null:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.ctrl_pressed or key.alt_pressed:
		return
	if key.keycode == KEY_P:
		# Picareta mantida para mineracao futura; nao ocupa um dos dez slots.
		_equipment.call("equip", &"pickaxe")
		return
	var slot: int = -1
	match key.keycode:
		KEY_1: slot = 0
		KEY_2: slot = 1
		KEY_3: slot = 2
		KEY_4: slot = 3
		KEY_5: slot = 4
		KEY_6: slot = 5
		KEY_7: slot = 6
		KEY_8: slot = 7
		KEY_9: slot = 8
		KEY_0: slot = 9
	if slot >= 0:
		_equipment.call("equip_slot", slot)


func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled or _action_animating or _equipment == null:
		return
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var cursor_world := get_global_mouse_position()
	if _current_tool() == &"axe":
		var best_tree: Node2D = null
		var best_distance := INF
		for node in get_tree().get_nodes_in_group("choppable_trees"):
			var tree := node as Node2D
			if tree == null or not tree.has_method("contains_click"):
				continue
			if global_position.distance_to(tree.global_position) > tool_reach:
				continue
			if not bool(tree.call("contains_click", cursor_world)):
				continue
			if not bool(tree.call("can_accept_axe_hit")):
				continue
			var distance_to_click := cursor_world.distance_squared_to(tree.global_position)
			if distance_to_click < best_distance:
				best_distance = distance_to_click
				best_tree = tree
		if best_tree != null and _attempt_axe_hit(best_tree):
			get_viewport().set_input_as_handled()
	elif global_position.distance_to(cursor_world) <= tool_reach:
		if _use_non_axe(cursor_world):
			get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	_tool_remaining = maxf(0.0, _tool_remaining - delta)
	var direction := Vector2.ZERO
	if controls_enabled and not _action_animating:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var running := controls_enabled and not _action_animating and Input.is_action_pressed("run")
	if direction != Vector2.ZERO:
		if absf(direction.x) > absf(direction.y):
			facing = Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
		else:
			facing = Vector2.DOWN if direction.y > 0.0 else Vector2.UP
	velocity = direction * walk_speed * (run_multiplier if running else 1.0)
	move_and_slide()
	interaction_ray.target_position = facing * 24.0
	tool_origin.position = facing * 16.0
	var moving := get_position_delta().length_squared() > 0.001
	_update_animation(moving, running)
	if not controls_enabled or _action_animating:
		return
	if Input.is_action_just_pressed("interact"):
		_interact()
	if Input.is_action_just_pressed("use_tool") and _tool_remaining <= 0.0:
		if _current_tool() == &"axe":
			_try_axe_hit()
		else:
			_use_non_axe(tool_origin.global_position + facing * 16.0)


func _try_axe_hit() -> void:
	var query := PhysicsRayQueryParameters2D.create(
		global_position, global_position + facing * tool_reach, 1, [get_rid()]
	)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	_attempt_axe_hit(hit.get("collider") as Node)


func _attempt_axe_hit(target: Node) -> bool:
	if target == null or _action_animating or _tool_remaining > 0.0 or _current_tool() != &"axe":
		return false
	if not target.has_method("take_axe_hit") or not target.has_method("can_accept_axe_hit"):
		return false
	var tree := target as Node2D
	if tree == null or global_position.distance_to(tree.global_position) > tool_reach:
		return false
	if not bool(target.call("can_accept_axe_hit")) or not bool(target.call("take_axe_hit", self)):
		return false
	_face_world_position(tree.global_position)
	_tool_remaining = tool_cooldown
	_play_tool_animation(&"axe")
	return true


func _use_non_axe(target_world: Vector2) -> bool:
	if _action_animating or _tool_remaining > 0.0 or not controls_enabled:
		return false
	if global_position.distance_to(target_world) > tool_reach:
		return false
	var tool_id: StringName = _current_tool()
	if tool_id not in [&"pickaxe", &"hoe", &"watering_can"]:
		# Recursos podem ser selecionados, mas nao sao ferramentas utilizaveis.
		return false
	_face_world_position(target_world)
	_tool_remaining = tool_cooldown
	_play_tool_animation(tool_id)
	tool_action_requested.emit(tool_id, target_world)
	return true


func _face_world_position(target: Vector2) -> void:
	var towards := target - global_position
	if towards.length_squared() < 0.01:
		return
	if absf(towards.x) > absf(towards.y):
		facing = Vector2.RIGHT if towards.x > 0.0 else Vector2.LEFT
	else:
		facing = Vector2.DOWN if towards.y > 0.0 else Vector2.UP


func _play_tool_animation(tool_id: StringName) -> void:
	var prefix := String(tool_id)
	if tool_id == &"pickaxe":
		prefix = "pick"
	elif tool_id == &"watering_can":
		prefix = "watering"
	var suffix := "down"
	if facing == Vector2.UP:
		suffix = "up"
	elif facing == Vector2.LEFT:
		suffix = "left"
	elif facing == Vector2.RIGHT:
		suffix = "right"
	var tool_animation := StringName(prefix + "_" + suffix)
	if not _has_frames(tool_animation):
		push_warning("Player: animacao de ferramenta ausente: " + str(tool_animation))
		return
	_action_animating = true
	animation.flip_h = false
	animation.speed_scale = tool_animation_speed
	animation.stop()
	animation.play(tool_animation)


func _on_action_animation_finished() -> void:
	if not _action_animating:
		return
	_action_animating = false
	animation.speed_scale = 1.0
	_update_animation(false, false)


func _update_animation(moving: bool, running: bool) -> void:
	if _action_animating:
		return
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
		if is_instance_valid(placeholder):
			placeholder.visible = true
		return
	animation.visible = true
	if is_instance_valid(placeholder):
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
