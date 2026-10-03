extends Node2D
## Y-sorted decoration; the base of each object is its sorting origin.
@export_enum("Tree", "Rock") var kind: int = 0

func _draw() -> void:
	draw_ellipse_shadow()
	if kind == 0:
		draw_rect(Rect2(-5, -22, 10, 24), Color("#705039"))
		draw_circle(Vector2(0, -32), 23, Color("#365d35"))
		draw_circle(Vector2(-10, -35), 15, Color("#456f3c"))
		draw_circle(Vector2(7, -43), 17, Color("#567f40"))
	else:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-12, 1), Vector2(-10, -10), Vector2(-3, -16),
			Vector2(8, -13), Vector2(13, -3), Vector2(10, 3)
		]), Color("#808781"))
		draw_line(Vector2(-5, -11), Vector2(5, -11), Color("#a5ada3"), 3)

func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2(0, 2), 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 15 if kind == 0 else 12, Color(0.15, 0.23, 0.12, 0.35))
	draw_set_transform(Vector2.ZERO)
