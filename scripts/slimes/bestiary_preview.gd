extends Node2D
## Catálogo visual isolado. Não instancia criaturas na fazenda.
var species: Array = []
var selected_species: int = 0
var current_slime: Node2D
var sprite: AnimatedSprite2D
var animation_picker: OptionButton
var species_picker: OptionButton
var pause_button: Button
var status_label: Label
var job_label: Label
var frame_slider: HSlider
var flip_button: CheckButton
var animation_names: Array[StringName] = []
var changing_slider := false

func _ready() -> void:
	var document: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/slimes/bestiary/bestiario.json"))
	if not document is Dictionary or not document.has("species"):
		push_error("Bestiário: manifesto inválido.")
		return
	species = document["species"]
	RenderingServer.set_default_clear_color(Color("172f42"))
	var hud := CanvasLayer.new()
	add_child(hud)
	var panel := VBoxContainer.new()
	panel.position = Vector2(16, 10)
	panel.add_theme_constant_override("separation", 5)
	hud.add_child(panel)
	var title := Label.new()
	title.text = "Bestiário — 32 slimes"
	panel.add_child(title)
	var pickers := HBoxContainer.new()
	panel.add_child(pickers)
	species_picker = OptionButton.new()
	species_picker.custom_minimum_size.x = 190
	for index in range(species.size()):
		species_picker.add_item("%02d. %s" % [index + 1, species[index]["name"]])
	pickers.add_child(species_picker)
	animation_picker = OptionButton.new()
	animation_picker.custom_minimum_size.x = 260
	pickers.add_child(animation_picker)
	job_label = Label.new()
	panel.add_child(job_label)
	var controls := HBoxContainer.new()
	panel.add_child(controls)
	pause_button = Button.new()
	pause_button.text = "Pausar"
	pause_button.pressed.connect(_toggle_pause)
	controls.add_child(pause_button)
	var restart := Button.new()
	restart.text = "Reiniciar"
	restart.pressed.connect(_restart)
	controls.add_child(restart)
	flip_button = CheckButton.new()
	flip_button.text = "Espelhar"
	flip_button.toggled.connect(_flip)
	controls.add_child(flip_button)
	frame_slider = HSlider.new()
	frame_slider.min_value = 0
	frame_slider.max_value = 11
	frame_slider.step = 1
	frame_slider.custom_minimum_size.x = 150
	frame_slider.value_changed.connect(_seek)
	controls.add_child(frame_slider)
	status_label = Label.new()
	status_label.position = Vector2(16, 326)
	hud.add_child(status_label)
	species_picker.item_selected.connect(_select_species)
	animation_picker.item_selected.connect(_select_animation)
	_select_species(0)

func _select_species(index: int) -> void:
	species_picker.select(index)
	var previous: StringName = sprite.animation if is_instance_valid(sprite) else &"idle"
	if is_instance_valid(current_slime):
		remove_child(current_slime)
		current_slime.queue_free()
	selected_species = index
	var packed := load(String(species[index]["scene"])) as PackedScene
	if packed == null:
		push_error("Bestiário: cena não encontrada.")
		return
	current_slime = packed.instantiate() as Node2D
	current_slime.position = Vector2(320, 308)
	current_slime.scale = Vector2(-3 if flip_button.button_pressed else 3, 3)
	add_child(current_slime)
	sprite = current_slime.get_node("AnimatedSprite2D") as AnimatedSprite2D
	animation_picker.clear()
	animation_names.clear()
	var selection := 0
	var entries: Array = species[index]["animations"]
	for i in range(entries.size()):
		var entry: Dictionary = entries[i]
		animation_names.append(StringName(entry["name"]))
		animation_picker.add_item(String(entry["label"]))
		if animation_names[i] == previous:
			selection = i
	animation_picker.select(selection)
	job_label.text = "%s • %d animações" % [species[index]["profession"], entries.size()]
	_select_animation(selection)

func _select_animation(index: int) -> void:
	animation_picker.select(index)
	if not is_instance_valid(sprite):
		return
	sprite.stop()
	sprite.play(animation_names[index])

func _toggle_pause() -> void:
	if not is_instance_valid(sprite):
		return
	if sprite.is_playing():
		sprite.pause()
	else:
		sprite.play()

func _restart() -> void:
	if is_instance_valid(sprite):
		sprite.stop()
		sprite.play()

func _flip(enabled: bool) -> void:
	if is_instance_valid(current_slime):
		current_slime.scale.x = -3 if enabled else 3

func _seek(value: float) -> void:
	if changing_slider or not is_instance_valid(sprite):
		return
	sprite.pause()
	sprite.set_frame_and_progress(int(value), 0.0)

func _process(_delta: float) -> void:
	if not is_instance_valid(sprite):
		return
	changing_slider = true
	frame_slider.value = sprite.frame
	changing_slider = false
	pause_button.text = "Pausar" if sprite.is_playing() else "Reproduzir"
	var loops := sprite.sprite_frames.get_animation_loop(sprite.animation)
	status_label.text = "%s  •  quadro %02d/12  •  %s" % [sprite.animation, sprite.frame + 1, "contínua" if loops else "uma vez"]
