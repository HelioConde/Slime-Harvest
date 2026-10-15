extends Node
## Um item ativo por vez; atalhos de 1 a 0. A picareta permanece no atalho P.

signal tool_changed(tool_id: StringName)

const SAVE_PATH := "user://slimekeepers_equipment_v1.json"
const HOTBAR_IDS: Array[StringName] = [
	&"watering_can", &"axe", &"hoe", &"grass_drop", &"branch",
	&"wood", &"trunk", &"twigs", &"plank", &"large_stone"
]
const TOOL_IDS: Array[StringName] = [&"watering_can", &"axe", &"hoe", &"pickaxe"]

var equipped_tool: StringName = &"axe"
var _items: Dictionary = {}


func _ready() -> void:
	for item_id in HOTBAR_IDS + [&"pickaxe"]:
		var accessory := Node.new()
		accessory.name = "Item_" + String(item_id)
		add_child(accessory)
		accessory.add_to_group("accessory_" + String(item_id))
		_items[item_id] = accessory
	_load_equipped()
	equip(equipped_tool)


func equip_slot(slot: int) -> void:
	if slot >= 0 and slot < HOTBAR_IDS.size():
		equip(HOTBAR_IDS[slot])


func equip(item_id: StringName) -> void:
	if not _items.has(item_id):
		push_warning("ToolInventory: item desconhecido: " + String(item_id))
		return
	if _items.has(equipped_tool):
		(_items[equipped_tool] as Node).remove_from_group("equipped_accessory")
	var owner_player: Node = get_parent()
	if owner_player != null:
		for old_id in _items.keys():
			owner_player.remove_from_group("equipped_" + String(old_id))
	equipped_tool = item_id
	(_items[item_id] as Node).add_to_group("equipped_accessory")
	if owner_player != null:
		owner_player.add_to_group("equipped_" + String(item_id))
	tool_changed.emit(item_id)
	_save_equipped()


func get_equipped_tool() -> StringName:
	return equipped_tool


func is_usable_tool(item_id: StringName) -> bool:
	return TOOL_IDS.has(item_id)


func _load_equipped() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not parsed is Dictionary:
		return
	var saved := StringName(str(parsed.get("equipped", "axe")))
	if _items.has(saved):
		equipped_tool = saved


func _save_equipped() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"version": 1, "equipped": String(equipped_tool)}))
