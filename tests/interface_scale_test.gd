extends Node
## Regressao das preferencias da interface, sem alterar saves de fazenda.
var _original_hotbar: float
var _original_hud: float


func _ready() -> void:
	_original_hotbar = UISettings.hotbar_scale
	_original_hud = UISettings.hud_scale
	call_deferred("_run")


func _check(ok: bool, message: String) -> bool:
	if ok:
		print("PASS interface: ", message)
		return true
	printerr("FAIL interface: ", message)
	return false


func _run() -> void:
	var ok := true
	var menu := load("res://scenes/ui/MainMenu.tscn").instantiate() as Control
	add_child(menu)
	menu.call("_on_options")
	await get_tree().process_frame
	var controls := menu.get_node_or_null("PopupOverlay/PopupCenter/Dialog/MarginContainer/DialogContent/FormFields/InterfaceScaleControls") as VBoxContainer
	ok = _check(controls != null, "options exposes UI controls") and ok
	if controls != null:
		var slider := controls.get_node_or_null("HotbarScale") as HSlider
		ok = _check(slider != null, "hotbar slider is available") and ok
		if slider != null:
			slider.value = 0.65
			ok = _check(is_equal_approx(UISettings.hotbar_scale, 0.65), "slider changes global preference") and ok
	menu.queue_free()
	await get_tree().process_frame

	var bar := load("res://scenes/ui/ToolHotbar.tscn").instantiate() as Control
	add_child(bar)
	bar.size = Vector2(640, 360)
	await get_tree().process_frame
	var frame := bar.get_node_or_null("InventoryFrame") as PanelContainer
	ok = _check(frame != null, "hotbar has its frame") and ok
	if frame != null:
		ok = _check(is_equal_approx(frame.scale.x, 0.65), "hotbar updates physical scale") and ok
		ok = _check(frame.position.x >= 0.0 and frame.position.x + frame.size.x * frame.scale.x <= bar.size.x, "hotbar stays inside viewport") and ok
	UISettings.set_hud_scale(0.70)
	var day_chip := GameCalendar.get_node_or_null("CalendarHUD/CalendarChip") as PanelContainer
	ok = _check(day_chip != null and is_equal_approx(day_chip.scale.x, 0.70), "calendar HUD uses saved scale") and ok
	bar.queue_free()
	await get_tree().process_frame

	var world_options := load("res://scripts/ui/world_settings_menu.gd").new() as CanvasLayer
	add_child(world_options)
	await get_tree().process_frame
	ok = _check(world_options.get_node_or_null("WorldSettingsRoot/OpenSettings") is Button, "in-game settings button exists") and ok
	world_options.call("_open_options")
	ok = _check(get_tree().paused and world_options.get_node("WorldSettingsRoot/SettingsOverlay").visible, "in-game settings pause gameplay") and ok
	world_options.call("_close_options")
	ok = _check(not get_tree().paused, "closing options unpauses gameplay") and ok
	world_options.queue_free()
	await get_tree().process_frame

	UISettings.set_hotbar_scale(_original_hotbar)
	UISettings.set_hud_scale(_original_hud)
	ok = _check(UISettings.hotbar_scale == _original_hotbar and UISettings.hud_scale == _original_hud, "previous settings restored") and ok
	print("PASS interface: hotbar, HUD, options and persistence" if ok else "FAIL interface: regression")
	get_tree().quit(0 if ok else 1)
