extends Node
## Equipamento por categorias. Apenas um acessorio pode estar equipado.

signal tool_changed(tool_id: StringName)

const SAVE_PATH := "user://slimekeepers_equipment_v1.json"
const TOOL_IDS: Array[StringName] = [&"pickaxe", &"axe", &"hoe", &"watering_can"]

var equipped_tool: StringName = &"axe"
var _items: Dictionary = {}


func _ready() -> void:
	for tool_id in TOOL_IDS:
		var accessory := Node.new()
		accessory.name = "Accessory_" + String(tool_id)
		add_child(accessory)
		accessory.add_to_group("accessory_" + String(tool_id))
		_items[tool_id] = accessory
	_load_equipped()
	equip(equipped_tool)


func equip(tool_id: StringName) -> void:
	if not TOOL_IDS.has(tool_id):
		push_warning("ToolInventory: ferramenta desconhecida: " + str(tool_id))
		return
	if _items.has(equipped_tool):
		(_items[equipped_tool] as Node).remove_from_group("equipped_accessory")
	var owner_player := get_parent()
	if owner_player != null:
		for old_id in TOOL_IDS:
			owner_player.remove_from_group("equipped_" + String(old_id))
	equipped_tool = tool_id
	(_items[tool_id] as Node).add_to_group("equipped_accessory")
	if owner_player != null:
		owner_player.add_to_group("equipped_" + String(tool_id))
	tool_changed.emit(tool_id)
	_save_equipped()


func get_equipped_tool() -> StringName:
	return equipped_tool


func _load_equipped() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not parsed is Dictionary:
		return
	var saved := StringName(str(parsed.get("equipped", "axe")))
	if TOOL_IDS.has(saved):
		equipped_tool = saved


func _save_equipped() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"version": 1, "equipped": String(equipped_tool)}))
