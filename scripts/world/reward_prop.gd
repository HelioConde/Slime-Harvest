extends StaticBody2D
## Bau ou vaso opcional. E abre/quebra uma vez; colecoes e saves nunca se duplicam.
@export var prop_id: String = ""
@export_enum("chest", "pot") var kind: String = "chest"
@export var reward_item: StringName = &"wood"
@export_range(1, 12, 1) var reward_amount: int = 2

const CHEST := "res://assets/expansion_packs/treasure_chests/treasure chests.png"
const POT := "res://assets/expansion_packs/breakable_pots/breakable pots.png"
var _image: Sprite2D
var _shape: CollisionShape2D
var _hint: Label


func _ready() -> void:
	if prop_id.is_empty():
		push_error("RewardProp: ID nao configurado")
		return
	var filename: String = CHEST if kind == "chest" else POT
	if not ResourceLoader.exists(filename):
		queue_free()
		return
	_image = Sprite2D.new()
	_image.name = "Sprite2D"
	_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_image.z_index = 4
	add_child(_image)
	_shape = CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(13, 14)
	_shape.shape = rectangle
	add_child(_shape)
	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 9)
	_hint.add_theme_color_override("font_color", Color("#fce3a8"))
	_hint.add_theme_constant_override("outline_size", 2)
	_hint.add_theme_color_override("font_outline_color", Color("#243024"))
	_hint.position = Vector2(-20, -34)
	_hint.visible = false
	add_child(_hint)
	_refresh_visual()


func _refresh_visual() -> void:
	var claimed: bool = ResourceBag.world_reward_claimed(prop_id)
	if kind == "pot" and claimed:
		_image.visible = false
		_shape.set_deferred("disabled", true)
		return
	var path: String = CHEST if kind == "chest" else POT
	var atlas := AtlasTexture.new()
	atlas.atlas = load(path) as Texture2D
	atlas.region = Rect2(0, 32 if claimed else 0, 16, 24) if kind == "chest" else Rect2(0, 0, 16, 16)
	atlas.filter_clip = true
	_image.texture = atlas
	_image.visible = true
	_shape.set_deferred("disabled", false)


func interact(player: Node) -> void:
	if ResourceBag.world_reward_claimed(prop_id):
		_feedback("Este bau ja foi aberto." if kind == "chest" else "Vaso ja recolhido.")
		return
	if player is Node2D and global_position.distance_to((player as Node2D).global_position) > 36:
		return
	if ResourceBag.claim_world_reward(prop_id, reward_item, reward_amount):
		_feedback(("Bau aberto" if kind == "chest" else "Vaso quebrado") +
			": +%d %s" % [reward_amount, String(reward_item)])
		_refresh_visual()


func _feedback(message: String) -> void:
	if not is_instance_valid(_hint):
		return
	_hint.text = message
	_hint.visible = true
	get_tree().create_timer(2.0).timeout.connect(func() -> void:
		if is_instance_valid(_hint):
			_hint.visible = false
	)
