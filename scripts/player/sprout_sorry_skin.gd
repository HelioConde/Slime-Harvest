extends RefCounted
## 8 direcoes x 3 poses (16x32). Usa somente o sprite licenciado instalado
## localmente. As ferramentas sao animacoes de postura aproximadas: a ferramenta
## visivel e um overlay separado em Player.gd, nao uma animacao deste pacote.
const ATLAS_PATH := "res://assets/Characters/sprout_sorry/free_character_spritesheet_by-cupnooble.png"
const FRAME_SIZE := Vector2i(16, 32)
# Ordem real das 8 colunas do spritesheet, conferida quadro a quadro.
# A atlas mostra o rosto para a DIREITA nas colunas 2/3 e para a
# ESQUERDA nas 5/6. Corrige a inversao constatada no jogo.
const DIRECTIONS := {
	"up_left": 7, "up": 1, "left": 6, "down_left": 5,
	"down": 4, "down_right": 3, "right": 2, "up_right": 0,
}
const TOOL_ACTIONS := ["axe", "pick", "hoe", "watering"]


## So controla a animacao visual, nao muda as quatro direcoes de ataque/colisao.
static func visual_direction(value: Vector2) -> String:
	if value.length_squared() <= 0.001:
		return "down"
	var direction := value.normalized()
	if absf(direction.x) < 0.38:
		return "up" if direction.y < 0.0 else "down"
	if absf(direction.y) < 0.38:
		return "left" if direction.x < 0.0 else "right"
	return ("up" if direction.y < 0.0 else "down") + ("_left" if direction.x < 0.0 else "_right")


static func available() -> bool:
	return ResourceLoader.exists(ATLAS_PATH)


static func from_installed_pack() -> SpriteFrames:
	if not available():
		return null
	return create_frames(load(ATLAS_PATH) as Texture2D)


static func create_frames(atlas: Texture2D) -> SpriteFrames:
	if atlas == null or atlas.get_width() != 128 or atlas.get_height() != 96:
		push_warning("Sprout Sorry: esperado atlas 128x96 com celulas 16x32.")
		return null
	var sprites := SpriteFrames.new()
	if sprites.has_animation(&"default"):
		sprites.remove_animation(&"default")
	for suffix in DIRECTIONS.keys():
		var col: int = int(DIRECTIONS[suffix])
		_add(sprites, atlas, "idle_" + suffix, col, [1], 3.0, true)
		_add(sprites, atlas, "walk_" + suffix, col, [0, 1, 2, 1], 8.0, true)
		_add(sprites, atlas, "run_" + suffix, col, [0, 1, 2, 1], 12.0, true)
		for tool in TOOL_ACTIONS:
			# Nao ha acao de ferramenta original: o corpo muda de postura,
			# enquanto o icone da ferramenta indica o uso no mundo.
			_add(sprites, atlas, tool + "_" + suffix, col, [1, 0, 1, 2], 8.0, false)
	return sprites


static func _add(sprites: SpriteFrames, atlas: Texture2D, name: String,
		column: int, rows: Array, fps: float, loop: bool) -> void:
	var id := StringName(name)
	sprites.add_animation(id)
	sprites.set_animation_speed(id, fps)
	sprites.set_animation_loop(id, loop)
	for row in rows:
		var piece := AtlasTexture.new()
		piece.atlas = atlas
		piece.region = Rect2(column * FRAME_SIZE.x, int(row) * FRAME_SIZE.y,
			FRAME_SIZE.x, FRAME_SIZE.y)
		piece.filter_clip = true
		sprites.add_frame(id, piece)
