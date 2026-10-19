extends SceneTree
var received: Array = []
var failures: int = 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var actor := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for name in [&"idle_down", &"pickup_slime_down", &"hold_slime_down", &"attack_down"]:
		frames.add_animation(name)
		frames.set_animation_loop(name, name in [&"idle_down", &"hold_slime_down"])
		for i in 6:
			var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
			image.fill(Color(0.1, 0.5, 0.2, 1))
			frames.add_frame(name, ImageTexture.create_from_image(image))
	actor.sprite_frames = frames
	root.add_child(actor)
	actor.play(&"idle_down")
	actor.set_frame_and_progress(2, 0.5)
	actor.speed_scale = 0.75
	var runner = load("res://action_sequencer.gd").new()
	root.add_child(runner)
	runner.bind(actor, {
		&"pickup_slime_down": {"validated": true, "interruptible": false, "events": [{"id": "attach", "frame": 2}, {"id": "lift", "frame": 4}]},
		&"hold_slime_down": {"validated": true, "interruptible": true, "lock_movement": false, "events": []},
		&"attack_down": {"validated": false, "events": [{"id": "hit", "frame": 3}]}
	})
	runner.action_event.connect(func(_a, e, _f, _p): received.append(e))
	check(not runner.request(&"walk", &"down"), "Must not take over locomotion")
	check(not runner.request(&"attack", &"down"), "Unvalidated action must be blocked")
	check(runner.request(&"pickup_slime", &"down"), "Pickup should start")
	check(runner.movement_locked(), "Pickup locks movement")
	check(not runner.request(&"hold_slime", &"down"), "Non-interruptible pickup must not overlap")
	actor.frame = 4
	check(received == [&"attach", &"lift"], "Skipped frames must dispatch all crossed events once")
	runner._on_frame()
	check(received.size() == 2, "Repeated frame must not duplicate events")
	check(not runner.cancel(), "Ordinary cancel must respect lock")
	actor.frame = 5
	actor.animation_finished.emit()
	check(runner.active == &"", "Finished action should clear state")
	check(actor.animation == &"idle_down" and actor.frame == 2 and is_equal_approx(actor.frame_progress, 0.5), "Restore previous locomotion phase")
	check(is_equal_approx(actor.speed_scale, 0.75), "Restore speed")
	check(runner.request(&"hold_slime", &"down"), "Hold should start")
	check(not runner.movement_locked(), "Hold allows movement according to spec")
	check(runner.cancel(), "Hold can be interrupted")
	check(received.size() == 2, "Cancellation must not synthesize impacts")
	runner.action_event.connect(func(_a, e, _f, _p):
		if e == &"attach": runner.cancel(true)
	)
	check(runner.request(&"pickup_slime", &"down"), "Second pickup starts")
	actor.frame = 4
	check(received == [&"attach", &"lift", &"attach"], "Cancellation inside callback suppresses remaining events")
	check(runner.active == &"", "Reentrant cancellation leaves runner idle")
	print("ACTION_SEQUENCER_TEST failures=", failures)
	quit(0 if failures == 0 else 1)
