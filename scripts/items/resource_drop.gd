extends Node2D
## Recurso no chao: clique ou chegue perto para recolher uma unidade.

@export var item_id: StringName = &"trunk"
@export var source_key: String = ""
@export var persist_drop: bool = true

const ICONS: Texture2D = preload("res://assets/Objects/Items/tools-n-meterial-items.png")
const ICON_INDEX := {"trunk": 6, "large_stone": 9, "wood": 5, "twigs": 7, "plank": 8}

var _sprite: Sprite2D
var _picked := false


func _ready() -> void:
	add_to_group("world_drops")
	_sprite = Sprite2D.new()
	_sprite.name = "DropIcon"
	_sprite.position = Vector2(0, -7)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var atlas := AtlasTexture.new()
	atlas.atlas = ICONS
	var index: int = int(ICON_INDEX.get(String(item_id), 9))
	atlas.region = Rect2((index % 4) * 16, (index / 4) * 16, 16, 16)
	atlas.filter_clip = true
	_sprite.texture = atlas
	add_child(_sprite)
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(_sprite, "position:y", -10.0, 0.55).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_sprite, "position:y", -7.0, 0.55).set_trans(Tween.TRANS_SINE)


func contains_click(world_point: Vector2) -> bool:
	return Rect2(Vector2(-10, -21), Vector2(20, 24)).has_point(to_local(world_point))


func pickup(_player: Node = null) -> bool:
	if _picked:
		return false
	if not ResourceBag.collect_drop(source_key, item_id, persist_drop):
		return false
	_picked = true
	queue_free()
	return true
