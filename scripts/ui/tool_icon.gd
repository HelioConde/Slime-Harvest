extends Control
## Icones vetoriais de picareta, machado, enxada e regador.

@export var tool_id: StringName = &"axe"

const METAL := Color("#d4e3da")
const WOOD := Color("#bc8655")
const WATER := Color("#73c9e4")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(66, 40)


func _draw() -> void:
	var delta := (size - Vector2(66, 40)) * 0.5
	match tool_id:
		&"pickaxe":
			draw_line(delta + Vector2(23, 34), delta + Vector2(41, 9), WOOD, 5.0, true)
			draw_line(delta + Vector2(17, 12), delta + Vector2(47, 12), METAL, 5.0, true)
			draw_line(delta + Vector2(17, 12), delta + Vector2(12, 18), METAL, 3.0, true)
			draw_line(delta + Vector2(47, 12), delta + Vector2(53, 18), METAL, 3.0, true)
		&"axe":
			draw_line(delta + Vector2(27, 35), delta + Vector2(36, 11), WOOD, 5.0, true)
			draw_colored_polygon(PackedVector2Array([
				delta + Vector2(31, 9), delta + Vector2(45, 7),
				delta + Vector2(51, 13), delta + Vector2(50, 27),
				delta + Vector2(38, 23), delta + Vector2(34, 18)
			]), METAL)
		&"hoe":
			draw_line(delta + Vector2(25, 34), delta + Vector2(42, 8), WOOD, 5.0, true)
			draw_line(delta + Vector2(28, 9), delta + Vector2(48, 9), METAL, 5.0, true)
			draw_line(delta + Vector2(28, 9), delta + Vector2(28, 19), METAL, 3.0, true)
		&"watering_can":
			draw_rect(Rect2(delta + Vector2(20, 19), Vector2(23, 16)), WATER)
			draw_line(delta + Vector2(39, 22), delta + Vector2(53, 17), WATER, 5.0, true)
			draw_line(delta + Vector2(53, 17), delta + Vector2(56, 21), WATER, 4.0, true)
			draw_arc(delta + Vector2(27, 19), 9.0, PI, TAU, 9, METAL, 3.0, true)
			draw_circle(delta + Vector2(54, 28), 2.1, WATER)
			draw_circle(delta + Vector2(59, 33), 1.6, WATER)
