extends Node2D
## Cena de referencia de especies frutiferas, sem modificar o World.tscn.

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#70955c"))
	var player: CharacterBody2D = $Player as CharacterBody2D
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.zoom = Vector2(1.25, 1.25)
