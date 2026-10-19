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
		var slider := controls.find_child("HotbarScale", true, false) as HSlider
		ok = _check(slider != null, "hotbar slider is available") and ok
		if slider != null:
			slider.value = 0.65
			ok = _check(is_equal_approx(UISettings.hotbar_scale, 0.65), "slider previews scale without committing") and ok
		var save := controls.find_child("SaveInterfaceScale", true, false) as Button
		ok = _check(save != null, "Save button is visible") and ok
		menu.call("_dismiss_popup")
		ok = _check(is_equal_approx(UISettings.hotbar_scale, _original_hotbar), "Cancel restores previous scale") and ok
		menu.call("_on_options")
		controls = menu.get_node_or_null("PopupOverlay/PopupCenter/Dialog/MarginContainer/DialogContent/FormFields/InterfaceScaleControls") as VBoxContainer
		var active_slider := controls.find_child("HotbarScale", true, false) as HSlider
		active_slider.value = 0.65
		var active_save := controls.find_child("SaveInterfaceScale", true, false) as Button
		active_save.pressed.emit()
		menu.call("_dismiss_popup")
		ok = _check(is_equal_approx(UISettings.hotbar_scale, 0.65), "Save keeps selected scale") and ok
	menu.queue_free()
	await get_tree().process_frame

	var bar := load("res://scenes/ui/ToolHotbar.tscn").instantiate() as Control
	add_child(bar)
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
	var hud_before_preview: float = UISettings.hud_scale
	var world_controls := world_options.find_child("InterfaceScaleControls", true, false) as VBoxContainer
	if world_controls != null:
		var hud_slider := world_controls.find_child("HUDScale", true, false) as HSlider
		if hud_slider != null:
			hud_slider.value = 0.60
			ok = _check(is_equal_approx(UISettings.hud_scale, 0.60), "world HUD previews scale") and ok
	world_options.call("_close_options")
	ok = _check(is_equal_approx(UISettings.hud_scale, hud_before_preview), "world Cancel restores saved scale") and ok
	ok = _check(not get_tree().paused, "closing options unpauses gameplay") and ok
	world_options.queue_free()
	await get_tree().process_frame

	UISettings.set_hotbar_scale(_original_hotbar)
	UISettings.set_hud_scale(_original_hud)
	ok = _check(is_equal_approx(UISettings.hotbar_scale, _original_hotbar) and is_equal_approx(UISettings.hud_scale, _original_hud), "previous settings restored") and ok
	print("PASS interface: hotbar, HUD, options and persistence" if ok else "FAIL interface: regression")
	get_tree().quit(0 if ok else 1)
