extends RefCounted
## O Sprout Sorry e o protagonista padrao das novas fazendas.
## Os antigos personagens seguem disponiveis para saves legados.
const MALE_FRAMES: SpriteFrames = preload("res://assets/Characters/animation/player_masculino_frames.tres")
const FEMALE_FRAMES: SpriteFrames = preload("res://assets/Characters/animation/player_feminino_frames.tres")
const SPROUT_SORRY = preload("res://scripts/player/sprout_sorry_skin.gd")

const VISUAL_SCALE := Vector2(0.16, 0.16)
const VISUAL_POSITION := Vector2(0, -18)
const SPROUT_SCALE := Vector2.ONE
const SPROUT_POSITION := Vector2(0, -16)


static func sprout_ready() -> bool:
	return SPROUT_SORRY.available()


static func apply(sprite: AnimatedSprite2D, appearance: String) -> bool:
	if sprite == null:
		return false
	var frames: SpriteFrames
	var sprout: bool = appearance == "sprout_sorry"
	if sprout:
		frames = SPROUT_SORRY.from_installed_pack()
		if frames == null:
			# Fallback seguro para CI e para quem ainda nao instalou o pack.
			frames = MALE_FRAMES
			sprout = false
	elif appearance == "feminino":
		frames = FEMALE_FRAMES
	else:
		frames = MALE_FRAMES
	if frames == null:
		return false
	sprite.stop()
	sprite.sprite_frames = frames
	sprite.animation = &"idle_down"
	sprite.position = SPROUT_POSITION if sprout else VISUAL_POSITION
	sprite.scale = SPROUT_SCALE if sprout else VISUAL_SCALE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.play(&"idle_down")
	return true
