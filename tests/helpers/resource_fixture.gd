extends RefCounted
## Regressao dos recursos: constroi diretamente um mundo de teste sem cenas Demo/Preview.


static func _instance(path: String, name: String, position: Vector2) -> Node2D:
	var scene: PackedScene = load(path) as PackedScene
	assert(scene != null, "Test fixture resource not found: " + path)
	var node: Node2D = scene.instantiate() as Node2D
	assert(node != null)
	node.name = name
	node.position = position
	return node


static func create_test_world() -> Node2D:
	var root := Node2D.new()
	root.name = "ResourceTestWorld"
	root.y_sort_enabled = true
	var scenery := Node2D.new()
	scenery.name = "Scenery"
	scenery.z_index = -1
	root.add_child(scenery)

	var large_rock := _instance("res://scenes/objects/rocks/rock.tscn", "RockNorth", Vector2(158, 126))
	large_rock.set("persist_mining", false)
	scenery.add_child(large_rock)
	var small_rock := _instance("res://scenes/objects/rocks/rock_small.tscn", "RockWestSmall", Vector2(90, 267))
	small_rock.set("persist_mining", false)
	scenery.add_child(small_rock)
	var flower := _instance("res://scenes/objects/flowers/flower_pink.tscn", "FlowerPinkWest", Vector2(183, 233))
	flower.set("start_fully_grown", true)
	flower.set("persist_pickup", false)
	scenery.add_child(flower)
	var mushroom := _instance("res://scenes/objects/mushrooms/mushroom_red.tscn", "MushroomWest", Vector2(163, 286))
	mushroom.set("start_fully_grown", true)
	mushroom.set("persist_pickup", false)
	scenery.add_child(mushroom)

	var player := _instance("res://scenes/player/Player.tscn", "Player", Vector2(260, 220))
	player.z_index = 10
	root.add_child(player)
	var tree := _instance("res://scenes/objects/trees/tree.tscn", "Tree", Vector2(260, 170))
	tree.set("persist_felling", false)
	root.add_child(tree)
	var apple := _instance("res://scenes/objects/trees/tree_apple.tscn", "AppleTree", Vector2(355, 170))
	apple.set("persist_felling", false)
	root.add_child(apple)
	return root
