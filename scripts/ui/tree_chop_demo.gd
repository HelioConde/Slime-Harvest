extends Node2D
## Controla apenas a cena de teste, sem modificar o zoom do mapa principal.

@onready var help_panel: PanelContainer = $InfoLayer/HelpPanel
@onready var help_button: Button = $InfoLayer/HelpToggle
@onready var demo_camera: Camera2D = $Player/Camera2D


func _ready() -> void:
	# Aumenta personagens e arvores na cena de teste sem aumentar a interface.
	demo_camera.zoom = Vector2(1.5, 1.5)
	help_panel.hide()
	help_button.pressed.connect(_toggle_help)


func _toggle_help() -> void:
	help_panel.visible = not help_panel.visible
	help_button.text = "×" if help_panel.visible else "?"
	help_button.tooltip_text = "Ocultar instrucoes" if help_panel.visible else "Mostrar instrucoes"
