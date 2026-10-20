extends Node
## Validates installed paths with synthetic PNGs generated only for CI.
const SKINS = preload("res://scripts/player/player_skins.gd")
const SPROUT = preload("res://scripts/player/sprout_sorry_skin.gd")
const THEME = preload("res://scripts/ui/sprout_ui.gd")
const SETTINGS = preload("res://scripts/ui/world_settings_menu.gd")
var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		print("PASS sprout-asset: ", message)
	else:
		_failed = true
		printerr("FAIL sprout-asset: ", message)


func _run() -> void:
	_check(SPROUT.available(), "Sprout Sorry sprite discovered in expected project folder")
	var sprite := AnimatedSprite2D.new()
	add_child(sprite)
	_check(SKINS.apply(sprite, "sprout_sorry"), "applies Sprout Sorry avatar")
	_check(sprite.scale == SKINS.SPROUT_SCALE and sprite.position == SKINS.SPROUT_POSITION,
		"character uses 16x32 Sprout sizing and foot anchor")
	_check(sprite.sprite_frames != null and sprite.sprite_frames.get_animation_names().size() == 56,
		"real texture loaded into all 56 directional animations")
	_check(THEME.has_inventory_atlas(), "Sprout UI inventory texture found")
	var slot: StyleBoxTexture = THEME.inventory_slot_style(&"normal") as StyleBoxTexture
	_check(slot != null and slot.texture != null, "hotbar uses PNG-backed Sprout slots")
	var heart: Texture2D = THEME.inventory_heart(true)
	_check(heart != null and heart.get_width() == 16, "health HUD uses inventory hearts")
	var settings := SETTINGS.new() as CanvasLayer
	add_child(settings)
	var picker := settings.find_child("AppearancePicker", true, false) as OptionButton
	_check(picker != null and picker.item_count == 3,
		"settings can select Sprout Sorry on an existing save")
	settings.queue_free()
	sprite.queue_free()
	print("PASS sprout-asset: complete" if not _failed else "FAIL sprout-asset")
	get_tree().quit(1 if _failed else 0)
