extends Node
## Opt-in action layer. Does not replace Player, locomotion or its tool impact logic.
signal action_started(action: StringName)
signal action_event(action: StringName, event: StringName, frame: int, payload: Dictionary)
signal action_ended(action: StringName, cancelled: bool)

var sprite: AnimatedSprite2D
var definitions: Dictionary = {}
var active: StringName = &""
var _spec: Dictionary = {}
var _last_frame: int = -1
var _previous: StringName
var _previous_frame: int
var _previous_progress: float
var _previous_speed: float
var _previous_playing: bool
var _generation: int = 0

func bind(target: AnimatedSprite2D, validated_definitions: Dictionary) -> void:
	if sprite != null:
		if sprite.frame_changed.is_connected(_on_frame): sprite.frame_changed.disconnect(_on_frame)
		if sprite.animation_finished.is_connected(_on_finished): sprite.animation_finished.disconnect(_on_finished)
		if active != &"": cancel(true)
	sprite = target
	definitions = validated_definitions.duplicate(true)
	sprite.frame_changed.connect(_on_frame)
	sprite.animation_finished.connect(_on_finished)

func request(action: StringName, direction: StringName, payload: Dictionary = {}) -> bool:
	# Approved locomotion remains exclusively owned by the existing controller.
	if action in [&"idle", &"walk", &"run"] or sprite == null: return false
	var key := StringName(String(action) + "_" + String(direction))
	if not definitions.has(key) or not sprite.sprite_frames.has_animation(key): return false
	var spec: Dictionary = definitions[key]
	if not bool(spec.get("validated", false)): return false
	var count := sprite.sprite_frames.get_frame_count(key)
	for event in spec.get("events", []):
		if not event.has("frame") or event.frame == null or int(event.frame) < 0 or int(event.frame) >= count: return false
	if active != &"" and not cancel(): return false
	_previous = sprite.animation
	_previous_frame = sprite.frame
	_previous_progress = sprite.frame_progress
	_previous_speed = sprite.speed_scale
	_previous_playing = sprite.is_playing()
	active = action
	_generation += 1
	var generation := _generation
	_spec = spec.duplicate(true)
	_spec["payload"] = payload.duplicate(true)
	_spec["animation"] = key
	_last_frame = -1
	sprite.speed_scale = 1.0
	action_started.emit(active)
	if generation != _generation: return false
	sprite.stop()
	sprite.play(key)
	sprite.set_frame_and_progress(0, 0.0)
	_on_frame()
	return true

func movement_locked() -> bool:
	return active != &"" and bool(_spec.get("lock_movement", true))

func cancel(force: bool = false) -> bool:
	if active == &"": return true
	if not force and not bool(_spec.get("interruptible", false)): return false
	_finish(true)
	return true

func _on_frame() -> void:
	if active == &"" or sprite.animation != _spec.get("animation"): return
	var current := sprite.frame
	var generation := _generation
	if current < _last_frame:
		# Events repeat only on explicitly looping actions, never on backward seeks.
		if bool(_spec.get("repeat_events", false)) and sprite.sprite_frames.get_animation_loop(sprite.animation):
			_last_frame = -1
		else: return
	for event in _spec.get("events", []):
		var event_frame := int(event.frame)
		if event_frame > _last_frame and event_frame <= current:
			_last_frame = event_frame
			action_event.emit(active, StringName(event.id), event_frame, _spec.payload)
			if generation != _generation: return
	_last_frame = current

func _on_finished() -> void:
	if active != &"" and sprite.animation == _spec.get("animation"):
		_on_frame()
		_finish(false)

func _finish(cancelled: bool) -> void:
	var ended := active
	_generation += 1
	active = &""
	_spec = {}
	sprite.stop()
	sprite.speed_scale = _previous_speed
	if sprite.sprite_frames.has_animation(_previous):
		sprite.play(_previous)
		sprite.set_frame_and_progress(_previous_frame, _previous_progress)
		if not _previous_playing: sprite.pause()
	action_ended.emit(ended, cancelled)
