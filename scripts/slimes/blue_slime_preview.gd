extends Node2D
## Visualizador isolado. Nao adiciona logica de jogo ao slime.
const ANIMATIONS: Array[String] = ["idle","idle_feliz","piscar","saltar_mover","aterrissar","seguir_jogador","procurar_planta","preparar_rega","regar","regar_area","recarregar_agua","cansado","dormir","acordar","comemorar","receber_carinho","atacar_jato_agua","irritado","acertado_recuo","derrotado_dissipar"]
const LABELS: Array[String] = ["Idle","Idle feliz","Piscar","Saltar / mover","Aterrissar","Seguir jogador","Procurar planta","Preparar rega","Regar","Regar em área","Recarregar água","Cansado","Dormir","Acordar","Comemorar","Receber carinho","Atacar com jato de água","Irritado","Acertado / recuo","Derrotado / dissipar"]
@onready var sprite: AnimatedSprite2D = $Slime/AnimatedSprite2D
var pause_button: Button

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("172e40"))
	var hud := CanvasLayer.new()
	add_child(hud)
	var panel := VBoxContainer.new()
	panel.position = Vector2(16, 12)
	hud.add_child(panel)
	var title := Label.new()
	title.text = "Slime azul - 20 animacoes"
	panel.add_child(title)
	var controls := HBoxContainer.new()
	panel.add_child(controls)
	var picker := OptionButton.new()
	for label in LABELS:
		picker.add_item(label)
	controls.add_child(picker)
	picker.item_selected.connect(_select_animation)
	pause_button = Button.new()
	pause_button.text = "Pausar"
	pause_button.pressed.connect(_toggle_pause)
	controls.add_child(pause_button)
	var restart := Button.new()
	restart.text = "Reiniciar"
	restart.pressed.connect(func() -> void:
		sprite.stop()
		sprite.play()
		pause_button.text = "Pausar")
	controls.add_child(restart)
	var hint := Label.new()
	hint.text = "Escolha uma animacao. Acoes unicas param no ultimo quadro."
	panel.add_child(hint)

func _select_animation(index: int) -> void:
	sprite.stop()
	sprite.play(StringName(ANIMATIONS[index]))
	pause_button.text = "Pausar"

func _toggle_pause() -> void:
	if sprite.is_playing():
		sprite.pause()
		pause_button.text = "Reproduzir"
	else:
		sprite.play()
		pause_button.text = "Pausar"
