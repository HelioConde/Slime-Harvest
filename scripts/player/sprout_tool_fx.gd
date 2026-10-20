extends Node2D
## Efeito visual de ferramenta para Sprout Sorry: segue o quadro da animacao,
## nao cria dano, nao modifica colisoes e nao depende de sprites de bracos.
## Usa os mesmos icones reais da hotbar, com rotacao, arco e efeito discreto.
const TOOL_ATLAS: Texture2D = preload("res://assets/Objects/Items/tools-n-meterial-items.png")
const ICON_INDEX := {
	&"watering_can": 0, &"axe": 1, &"hoe": 2, &"pickaxe": 3,
}
const WATER := Color("#75d6f3b0")
const DUST := Color("#e6c28e9c")
const FLASH := Color("#f6e9bd9c")

var _icon: Sprite2D
var _tool: StringName = &""
var _direction: String = "down"
var _progress: float = 0.0


func _ready() -> void:
	name = "SproutToolFX"
	visible = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon = Sprite2D.new()
	_icon.name = "ToolIcon"
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon.scale = Vector2(0.68, 0.68)
	add_child(_icon)


func start_action(tool_id: StringName, facing_name: String) -> void:
	if not ICON_INDEX.has(tool_id):
		stop_action()
		return
	_tool = tool_id
	_direction = facing_name
	var atlas_piece := AtlasTexture.new()
	atlas_piece.atlas = TOOL_ATLAS
	atlas_piece.region = Rect2(int(ICON_INDEX[tool_id]) * 16, 0, 16, 16)
	atlas_piece.filter_clip = true
	_icon.texture = atlas_piece
	_icon.flip_h = facing_name == "left"
	z_index = -1 if facing_name == "up" else 1
	visible = true
	set_action_progress(0.0)


func stop_action() -> void:
	visible = false
	_tool = &""
	_progress = 0.0
	queue_redraw()


func set_action_progress(value: float) -> void:
	if not visible or _icon == null:
		return
	_progress = clampf(value, 0.0, 1.0)
	var side: float = -1.0 if _direction == "left" else 1.0
	var base := Vector2(7, -11)
	match _direction:
		"up":
			base = Vector2(-7, -23)
		"left":
			base = Vector2(-8, -12)
		"right":
			base = Vector2(8, -12)
		_:
			base = Vector2(7, -11)
	var contact: float = _swing_progress(_progress)
	# Ferramentas pesadas giram em arco, enquanto regador inclina suavemente.
	if _tool == &"watering_can":
		_icon.rotation = (lerpf(-0.2, 0.65, contact)) * side
		_icon.position = base + Vector2(side * contact * 2.0, contact * 2.0)
	elif _tool == &"hoe":
		_icon.rotation = lerpf(-1.1, 0.75, contact) * side
		_icon.position = base + Vector2(side * contact * 3.0, contact * 4.0)
	else:
		_icon.rotation = lerpf(-1.45, 0.95, contact) * side
		_icon.position = base + Vector2(side * contact * 3.0, contact * 2.0)
	# Arco de contato e gotas seguem o mesmo timing da ferramenta real.
	queue_redraw()


static func _swing_progress(time: float) -> float:
	var phase: float = clampf(time, 0.0, 1.0)
	if phase < 0.20:
		return lerpf(0.0, 0.20, phase / 0.20)
	if phase < 0.46:
		var advance: float = (phase - 0.20) / 0.26
		return lerpf(0.20, 1.0, 1.0 - pow(1.0 - advance, 2.0))
	return lerpf(1.0, 0.45, (phase - 0.46) / 0.54)


func _draw() -> void:
	if not visible or _icon == null:
		return
	if _tool == &"watering_can" and _progress >= 0.25 and _progress <= 0.78:
		var sign: float = -1.0 if _direction == "left" else 1.0
		var origin: Vector2 = _icon.position + Vector2(5.0 * sign, 1.0)
		for i in range(3):
			var point := origin + Vector2(float(i) * 2.0 * sign, 4.0 + float(i % 2) * 3.0)
			draw_circle(point, 1.0, WATER)
	elif _tool in [&"axe", &"pickaxe", &"hoe"] and _progress >= 0.23 and _progress <= 0.48:
		var color: Color = DUST if _tool == &"hoe" else FLASH
		# Um arco curto, puramente decorativo; o impacto ainda vem do Player.
		var center: Vector2 = _icon.position + Vector2(0, -1)
		draw_arc(center, 8.0, -1.1, 0.35, 7, color, 1.5, false)
