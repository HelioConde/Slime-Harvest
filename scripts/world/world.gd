extends Node2D
## First farm layout. Drawing can be replaced by tiles without changing collisions.
const MAP_SIZE := Vector2(1280, 960)
const POND := Rect2(864, 224, 224, 160)
const FIELD := Rect2(320, 416, 320, 224)
const TREES: Array[Vector2] = [
	Vector2(128, 144), Vector2(224, 128), Vector2(368, 160),
	Vector2(688, 128), Vector2(800, 160), Vector2(1152, 160),
	Vector2(112, 400), Vector2(144, 640), Vector2(240, 784),
	Vector2(752, 736), Vector2(1040, 704), Vector2(1152, 816)
]
const ROCKS: Array[Vector2] = [
	Vector2(208, 320), Vector2(736, 352), Vector2(816, 560),
	Vector2(928, 640), Vector2(432, 768)
]

func _ready() -> void:
	_add_block(Rect2(-32, -32, 1344, 32))
	_add_block(Rect2(-32, 960, 1344, 32))
	_add_block(Rect2(-32, 0, 32, 960))
	_add_block(Rect2(1280, 0, 32, 960))
	_add_block(POND)
	for point in TREES:
		_add_block(Rect2(point - Vector2(7, 6), Vector2(14, 12)))
	for point in ROCKS:
		_add_block(Rect2(point - Vector2(10, 6), Vector2(20, 12)))
	queue_redraw()

func _add_block(bounds: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 2
	body.position = bounds.get_center()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = bounds.size
	collider.shape = shape
	body.add_child(collider)
	add_child(body)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color("#71974b"))
	var random := RandomNumberGenerator.new()
	random.seed = 43821
	for index in range(900):
		var point := Vector2(random.randf_range(16, 1264), random.randf_range(16, 944))
		draw_rect(Rect2(point, Vector2(2, 3)), Color("#628740"))
	draw_rect(Rect2(624, 32, 48, 896), Color("#bfaa72"))
	draw_rect(Rect2(176, 288, 720, 48), Color("#bfaa72"))
	draw_rect(FIELD.grow(8), Color("#a48b59"))
	draw_rect(FIELD, Color("#775438"))
	for row in range(7):
		for column in range(10):
			var cell := FIELD.position + Vector2(column * 32, row * 32)
			draw_rect(Rect2(cell + Vector2(3, 9), Vector2(26, 3)), Color("#63452f"))
			draw_rect(Rect2(cell + Vector2(3, 21), Vector2(26, 3)), Color("#63452f"))
	draw_rect(POND.grow(8), Color("#c8b982"))
	draw_rect(POND, Color("#4f91a1"))
	for row in range(5):
		draw_line(POND.position + Vector2(16, 16 + row * 28),
			POND.position + Vector2(200, 16 + row * 28), Color("#72b3be"), 2)
	draw_rect(Rect2(0, 0, 1280, 16), Color("#425e32"))
	draw_rect(Rect2(0, 944, 1280, 16), Color("#425e32"))
	draw_rect(Rect2(0, 0, 16, 960), Color("#425e32"))
	draw_rect(Rect2(1264, 0, 16, 960), Color("#425e32"))
