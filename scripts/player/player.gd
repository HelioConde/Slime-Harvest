extends CharacterBody2D
## Personagem e equipamentos, com hotbar e categorias por acessorio.

signal interaction_requested(target: Node)
signal tool_use_requested(origin: Vector2, direction: Vector2)
signal tool_action_requested(tool_id: StringName, world_position: Vector2)
signal wild_health_changed(current: int, maximum: int)
signal wild_player_respawned()

const PLAYER_SKINS = preload("res://scripts/player/player_skins.gd")
const TOOL_ATLAS = preload("res://assets/Objects/Items/tools-n-meterial-items.png")
const MOTION_ALIGNMENT = preload("res://scripts/player/player_motion_alignment.gd")
const SAVE_SLOTS = preload("res://scripts/core/save_slots.gd")
const INVENTORY_SCRIPT = preload("res://scripts/items/tool_inventory.gd")
const HOTBAR_SCENE: PackedScene = preload("res://scenes/ui/ToolHotbar.tscn")

@export_range(1.0, 500.0) var walk_speed: float = 90.0
@export_range(1.0, 3.0) var run_multiplier: float = 1.6
@export_range(100.0, 2000.0, 10.0) var move_acceleration: float = 680.0
@export_range(100.0, 2200.0, 10.0) var move_deceleration: float = 950.0
@export_range(0.05, 2.0) var tool_cooldown: float = 0.3
@export var controls_enabled: bool = true
@export_range(16.0, 96.0, 1.0) var tool_reach: float = 60.0
@export_range(0.5, 3.0, 0.05) var tool_animation_speed: float = 1.65

@export_range(1, 20, 1) var wild_max_health: int = 5
var wild_health: int = 5
var _wild_invulnerable: float = 0.0
var _wild_impulse := Vector2.ZERO
var _wild_spawn := Vector2.ZERO
var _wild_health_display: Label
var facing: Vector2 = Vector2.DOWN
var _tool_remaining: float = 0.0
var _action_animating: bool = false
var _equipment: Node
var _hotbar: Control
var _queued_target: Node2D
var _queued_tool: StringName = &""
var _queued_position: Vector2 = Vector2.ZERO
var _impact_applied: bool = true
var _impact_frame: int = 1
var _hotbar_index: int = 1
var _player_appearance: String = "masculino"
var _using_sprout_skin: bool = false
var _tool_visual: Sprite2D
## Suaviza mudancas dos offsets dos sprites sem alterar o CharacterBody2D.
var _anchor_current := Vector2.ZERO
var _anchor_target := Vector2.ZERO
var _anchor_initialized: bool = false
var _was_moving: bool = false

@onready var animation: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
@onready var placeholder: Polygon2D = get_node_or_null("Placeholder") as Polygon2D
@onready var interaction_ray: RayCast2D = $InteractionRay
@onready var tool_origin: Marker2D = $ToolOrigin


func _ready() -> void:
	_wild_spawn = global_position
	wild_health = wild_max_health
	if animation == null:
		push_error("Player: mantenha AnimatedSprite2D como filho direto.")
		set_physics_process(false)
		return
	_apply_selected_appearance()
	_create_tool_visual()
	add_to_group("resource_collectors")
	animation.animation_finished.connect(_on_action_animation_finished)
	animation.frame_changed.connect(_on_tool_frame_changed)
	animation.frame_changed.connect(_sync_sprite_anchor)
	_sync_sprite_anchor()
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
	_build_wild_health_hud(hud_layer)


func _current_tool() -> StringName:
	if _equipment == null:
		return &"axe"
	return StringName(_equipment.call("get_equipped_tool"))


func _on_hotbar_selection(tool_id: StringName) -> void:
	if controls_enabled and not _action_animating and _equipment != null:
		if _hotbar != null:
			for i in range(10):
				if StringName(_hotbar.call("get_slot_item", i)) == tool_id:
					_hotbar_index = i
					break
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
		# Atalho P mantido por compatibilidade; o slot principal agora e 4.
		_hotbar_index = 3
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
		_hotbar_index = slot
		_equipment.call("equip_slot", slot)


func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled or _action_animating or _equipment == null:
		return
	var click := event as InputEventMouseButton
	if click == null or not click.pressed:
		return
	if click.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var step: int = -1 if click.button_index == MOUSE_BUTTON_WHEEL_UP else 1
		_hotbar_index = posmod(_hotbar_index + step, 10)
		_equipment.call("equip_slot", _hotbar_index)
		get_viewport().set_input_as_handled()
		return
	if click.button_index != MOUSE_BUTTON_LEFT:
		return
	var cursor: Vector2 = get_global_mouse_position()
	# Coleta independente da arma (inclusive quando os itens 4-0 estiverem ativos).
	if _try_collect_click(cursor):
		get_viewport().set_input_as_handled()
		return
	var current: StringName = _current_tool()
	if current == &"axe":
		var tree: Node2D = _find_clicked("choppable_trees", cursor)
		if tree != null and _attempt_axe_hit(tree):
			get_viewport().set_input_as_handled()
	elif current == &"pickaxe":
		var rock: Node2D = _find_clicked("mineable_rocks", cursor)
		if rock != null and _attempt_pickaxe_hit(rock):
			get_viewport().set_input_as_handled()
	elif global_position.distance_to(cursor) <= tool_reach and _use_non_axe(cursor):
		get_viewport().set_input_as_handled()


func _find_clicked(group_name: String, cursor: Vector2) -> Node2D:
	var best: Node2D = null
	var best_distance: float = INF
	for candidate in get_tree().get_nodes_in_group(group_name):
		var node := candidate as Node2D
		if node == null or not node.has_method("contains_click"):
			continue
		if global_position.distance_to(node.global_position) > tool_reach:
			continue
		if not bool(node.call("contains_click", cursor)):
			continue
		var score: float = cursor.distance_squared_to(node.global_position)
		if score < best_distance:
			best_distance = score
			best = node
	return best


func _try_collect_click(cursor: Vector2) -> bool:
	for group_name in ["world_drops", "pickable_plants"]:
		var target: Node2D = _find_clicked(group_name, cursor)
		if target == null:
			continue
		if target.has_method("pickup"):
			return bool(target.call("pickup", self))
		if target.has_method("pick_by_click"):
			return bool(target.call("pick_by_click", self))
	return false


func _physics_process(delta: float) -> void:
	_wild_invulnerable = maxf(0.0, _wild_invulnerable - delta)
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
	var desired: Vector2 = direction * walk_speed * (run_multiplier if running else 1.0)
	if not controls_enabled or _action_animating:
		velocity = Vector2.ZERO
	else:
		var rate: float = move_acceleration if direction != Vector2.ZERO else move_deceleration
		velocity = velocity.move_toward(desired, rate * delta)
	velocity += _wild_impulse
	_wild_impulse = _wild_impulse.move_toward(Vector2.ZERO, 500.0 * delta)
	move_and_slide()
	interaction_ray.target_position = facing * 24.0
	tool_origin.position = facing * 16.0
	# Ignorar micromovimentos e oscilações ao parar.
	var distance_moved: float = get_position_delta().length()
	var moving: bool = direction.length_squared() > 0.01 and velocity.length() >= (7.0 if _was_moving else 13.0) and distance_moved > 0.07
	_was_moving = moving
	_update_animation(moving, running)
	_update_visual_anchor(delta)
	if not controls_enabled or _action_animating:
		return
	if Input.is_action_just_pressed("interact"):
		_interact()
	if Input.is_action_just_pressed("use_tool") and _tool_remaining <= 0.0:
		if _current_tool() == &"axe":
			_try_axe_hit()
		elif _current_tool() == &"pickaxe":
			_try_pickaxe_hit()
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
	if not bool(target.call("can_accept_axe_hit")):
		return false
	return _start_target_action(tree, &"axe")


func _try_pickaxe_hit() -> void:
	var nearest: Node2D = null
	var best_distance: float = tool_reach + 1.0
	for candidate in get_tree().get_nodes_in_group("mineable_rocks"):
		var rock := candidate as Node2D
		if rock == null or not bool(rock.call("can_accept_pickaxe_hit")):
			continue
		var offset: Vector2 = rock.global_position - global_position
		var distance: float = offset.length()
		if distance > tool_reach or distance < 0.01 or offset.normalized().dot(facing) < 0.4:
			continue
		if distance < best_distance:
			best_distance = distance
			nearest = rock
	if nearest != null:
		_attempt_pickaxe_hit(nearest)


func _attempt_pickaxe_hit(target: Node) -> bool:
	if target == null or _action_animating or _tool_remaining > 0.0 or _current_tool() != &"pickaxe":
		return false
	if not target.has_method("take_pickaxe_hit") or not target.has_method("can_accept_pickaxe_hit"):
		return false
	var rock := target as Node2D
	if rock == null or global_position.distance_to(rock.global_position) > tool_reach:
		return false
	if not bool(target.call("can_accept_pickaxe_hit")):
		return false
	return _start_target_action(rock, &"pickaxe")


func _start_target_action(target: Node2D, tool_id: StringName) -> bool:
	if _action_animating or not controls_enabled:
		return false
	_face_world_position(target.global_position)
	_queued_target = target
	_queued_tool = tool_id
	_queued_position = target.global_position
	_impact_applied = false
	_tool_remaining = tool_cooldown
	_play_tool_animation(tool_id)
	return true


func _on_tool_frame_changed() -> void:
	_update_tool_visual()
	if _action_animating and not _impact_applied and animation.frame >= _impact_frame:
		_apply_queued_impact()


func _apply_queued_impact() -> void:
	if _impact_applied:
		return
	_impact_applied = true
	var tool_id: StringName = _queued_tool
	var successful: bool = false
	if is_instance_valid(_queued_target):
		if global_position.distance_to(_queued_target.global_position) <= tool_reach:
			if tool_id == &"axe" and _queued_target.has_method("can_accept_axe_hit"):
				if bool(_queued_target.call("can_accept_axe_hit")):
					successful = bool(_queued_target.call("take_axe_hit", self))
			elif tool_id == &"pickaxe" and _queued_target.has_method("can_accept_pickaxe_hit"):
				if bool(_queued_target.call("can_accept_pickaxe_hit")):
					successful = bool(_queued_target.call("take_pickaxe_hit", self))
	elif tool_id in [&"hoe", &"watering_can"]:
		tool_action_requested.emit(tool_id, _queued_position)
	if successful:
		_camera_impact()


func _camera_impact() -> void:
	# Leve vibracao localizada, sem qualquer sprite ou imagem nova.
	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(camera, "offset", Vector2(0.65, -0.45), 0.045)
	tween.tween_property(camera, "offset", Vector2(-0.55, 0.3), 0.045)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.09)


func _use_non_axe(target_world: Vector2) -> bool:
	if _action_animating or _tool_remaining > 0.0 or not controls_enabled:
		return false
	if global_position.distance_to(target_world) > tool_reach:
		return false
	var tool_id: StringName = _current_tool()
	if tool_id not in [&"hoe", &"watering_can"]:
		# Recursos podem ser selecionados, mas nao sao ferramentas utilizaveis.
		return false
	_face_world_position(target_world)
	_queued_target = null
	_queued_tool = tool_id
	_queued_position = target_world
	_impact_applied = false
	_tool_remaining = tool_cooldown
	_play_tool_animation(tool_id)
	return true


func _face_world_position(target: Vector2) -> void:
	var towards := target - global_position
	if towards.length_squared() < 0.01:
		return
	if absf(towards.x) > absf(towards.y):
		facing = Vector2.RIGHT if towards.x > 0.0 else Vector2.LEFT
	else:
		facing = Vector2.DOWN if towards.y > 0.0 else Vector2.UP


func _create_tool_visual() -> void:
	_tool_visual = Sprite2D.new()
	_tool_visual.name = "ToolVisual"
	_tool_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_tool_visual.visible = false
	_tool_visual.z_index = 1
	add_child(_tool_visual)


func _show_tool_visual(tool_id: StringName, suffix: String) -> void:
	if not _using_sprout_skin or _tool_visual == null:
		return
	var icon_index: int = -1
	match tool_id:
		&"watering_can":
			icon_index = 0
		&"axe":
			icon_index = 1
		&"hoe":
			icon_index = 2
		&"pickaxe":
			icon_index = 3
	if icon_index == -1:
		return
	var icon := AtlasTexture.new()
	icon.atlas = TOOL_ATLAS
	icon.region = Rect2(icon_index * 16, 0, 16, 16)
	icon.filter_clip = true
	_tool_visual.texture = icon
	_tool_visual.flip_h = suffix == "left"
	_tool_visual.z_index = -1 if suffix == "up" else 1
	_tool_visual.visible = true
	_update_tool_visual()


func _update_tool_visual() -> void:
	if not _action_animating or not is_instance_valid(_tool_visual) or not _tool_visual.visible:
		return
	# Icones originais da hotbar simulam o golpe enquanto nao existe uma
	# folha oficial de bracos/ferramentas do personagem Sprout Sorry.
	var pose: int = mini(animation.frame, 3)
	var angles := [-0.70, -0.18, 0.42, 0.85]
	_tool_visual.rotation = float(angles[pose]) * (-1.0 if facing == Vector2.LEFT else 1.0)
	if facing == Vector2.UP:
		_tool_visual.position = Vector2(-7, -17)
	elif facing == Vector2.LEFT:
		_tool_visual.position = Vector2(-9, -7)
	elif facing == Vector2.RIGHT:
		_tool_visual.position = Vector2(9, -7)
	else:
		_tool_visual.position = Vector2(8, -5)


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
		_apply_queued_impact()
		return
	var frame_count: int = animation.sprite_frames.get_frame_count(tool_animation)
	_impact_frame = mini(frame_count - 1, maxi(1, floori(float(frame_count) * 0.45)))
	_action_animating = true
	animation.flip_h = false
	animation.speed_scale = tool_animation_speed
	animation.stop()
	animation.play(tool_animation)
	_show_tool_visual(tool_id, suffix)
	_sync_sprite_anchor()


func _on_action_animation_finished() -> void:
	if not _action_animating:
		return
	_apply_queued_impact()
	_queued_target = null
	_queued_tool = &""
	_action_animating = false
	if is_instance_valid(_tool_visual):
		_tool_visual.hide()
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
	var is_locomotion: bool = String(name_to_play).begins_with("walk_") or String(name_to_play).begins_with("run_")
	var target_speed: float = walk_speed * (run_multiplier if String(name_to_play).begins_with("run_") else 1.0)
	animation.speed_scale = clampf(velocity.length() / maxf(target_speed, 0.01), 0.5, 1.2) if moving and is_locomotion else 1.0
	if animation.animation != name_to_play:
		var previous: String = String(animation.animation)
		var preserve_step: bool = moving and is_locomotion and (previous.begins_with("walk_") or previous.begins_with("run_"))
		var previous_frame: int = animation.frame
		var previous_progress: float = animation.frame_progress
		var previous_count: int = animation.sprite_frames.get_frame_count(animation.animation)
		animation.play(name_to_play)
		if preserve_step and previous_count > 0:
			var next_frames: int = animation.sprite_frames.get_frame_count(name_to_play)
			# Preserva a fase proporcional (importante quando os ciclos tem duracoes diferentes).
			var normalized: float = (float(previous_frame) + previous_progress) / float(previous_count)
			var next_phase: float = normalized * float(next_frames)
			animation.set_frame_and_progress(clampi(floori(next_phase), 0, next_frames - 1), fposmod(next_phase, 1.0))
		_sync_sprite_anchor()
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

## A escolha pertence ao slot ativo; partidas antigas recebem a opcao masculina.
func _apply_selected_appearance() -> void:
	var appearance := "masculino"
	var slots: RefCounted = SAVE_SLOTS.new()
	if bool(slots.call("initialize")):
		var active: int = int(slots.call("active_slot"))
		if active > 0:
			var metadata: Dictionary = slots.call("slot_metadata", active)
			appearance = str(metadata.get("appearance", "masculino"))
	_player_appearance = appearance
	if not PLAYER_SKINS.apply(animation, appearance):
		push_warning("Player: mantendo sprites antigos porque o novo pacote nao carregou.")
	_using_sprout_skin = appearance == "sprout_sorry" and animation.scale == PLAYER_SKINS.SPROUT_SCALE


## Mantem a colisao fixa; os sprites mudam a compensacao lateral em cada quadro.
func _sync_sprite_anchor() -> void:
	if animation == null or animation.sprite_frames == null:
		return
	_anchor_target = MOTION_ALIGNMENT.frame_offset(_player_appearance, animation.animation, animation.frame)
	if not _anchor_initialized:
		_anchor_current = _anchor_target
		_anchor_initialized = true
		animation.offset = _anchor_current


func _update_visual_anchor(delta: float) -> void:
	if animation == null or not _anchor_initialized:
		return
	# Corrige gradualmente os saltos na transicao de quadros e na virada do ciclo.
	_anchor_current = _anchor_current.lerp(_anchor_target, 1.0 - exp(-maxf(delta, 0.0) * 19.0))
	# Quadros ~222px em escala .25: quantizar para um pixel inteiro no mapa.
	animation.offset = Vector2(roundf(_anchor_current.x * 0.25) * 4.0, roundf(_anchor_current.y * 0.25) * 4.0)


## Combate selvagem provisório: protege o jogador sem alterar inventario/saves.
## O ciclo de cuidado/domesticacao fica fora deste escopo.
func receive_wild_attack(amount: int, source: Vector2) -> bool:
	if amount <= 0 or _wild_invulnerable > 0.0 or not is_inside_tree():
		return false
	wild_health = maxi(0, wild_health - amount)
	_wild_invulnerable = 1.2
	var away: Vector2 = global_position - source
	_wild_impulse = away.normalized() * 100.0 if away.length() > 0.1 else Vector2.DOWN * 100.0
	_refresh_wild_health_hud()
	wild_health_changed.emit(wild_health, wild_max_health)
	if animation != null:
		animation.modulate = Color(1.0, 0.45, 0.45)
		var flash := create_tween()
		flash.tween_property(animation, "modulate", Color.WHITE, 0.25)
	if wild_health <= 0:
		_wild_respawn()
	return true


func _wild_respawn() -> void:
	global_position = _wild_spawn
	velocity = Vector2.ZERO
	_wild_impulse = Vector2.ZERO
	wild_health = wild_max_health
	_wild_invulnerable = 4.0
	_refresh_wild_health_hud()
	wild_health_changed.emit(wild_health, wild_max_health)
	wild_player_respawned.emit()


func _build_wild_health_hud(layer: CanvasLayer) -> void:
	_wild_health_display = Label.new()
	_wild_health_display.name = "WildHealth"
	_wild_health_display.anchor_left = 1.0
	_wild_health_display.anchor_right = 1.0
	_wild_health_display.offset_left = -130.0
	_wild_health_display.offset_right = -42.0
	_wild_health_display.offset_top = 8.0
	_wild_health_display.offset_bottom = 34.0
	_wild_health_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_wild_health_display.add_theme_font_size_override("font_size", 13)
	_wild_health_display.add_theme_color_override("font_color", Color(1.0, 0.83, 0.77))
	_wild_health_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_wild_health_display)
	_refresh_wild_health_hud()


func _refresh_wild_health_hud() -> void:
	if is_instance_valid(_wild_health_display):
		_wild_health_display.text = "HP %d/%d" % [wild_health, wild_max_health]
