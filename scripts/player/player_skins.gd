extends RefCounted
## As animacoes dos dois protagonistas estao disponiveis no editor em arquivos SpriteFrames.
const MALE_FRAMES: SpriteFrames = preload("res://assets/Characters/animation/player_masculino_frames.tres")
const FEMALE_FRAMES: SpriteFrames = preload("res://assets/Characters/animation/player_feminino_frames.tres")


static func apply(sprite: AnimatedSprite2D, appearance: String) -> bool:
	if sprite == null:
		return false
	var frames: SpriteFrames = FEMALE_FRAMES if appearance == "feminino" else MALE_FRAMES
	if frames == null:
		return false
	sprite.stop()
	sprite.sprite_frames = frames
	sprite.animation = &"idle_down"
	sprite.position = Vector2(0, -27)
	sprite.scale = Vector2(0.25, 0.25)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.play(&"idle_down")
	return true
