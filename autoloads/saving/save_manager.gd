extends Node

# TODO: Personalize save system for Moonlit Cafe

#region Variables
var max_save_amount : int = 5 ## The maximum amount of saves allowed
#endregion

#region Built-Ins
func _ready() -> void:
	pass
#endregion

#region Public Methods
## Saves the game to a file "savegame.save", requires that nodes in saveable group have the save() function
## else those nodes will be skipped in the saving process.
func save_game() -> void:
	var save_file : FileAccess = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	var save_nodes : Array[Node] = get_tree().get_nodes_in_group(&"saveable")
	
	for node in save_nodes:
		if node.scene_file_path.is_empty():
			push_warning("Saveable node '%s' is not an instanced scene, skipped" % node.name)
			continue
		
		if !node.has_method("save"):
			print("Saveable node '%s' is missing a save() function, skipped" % node.name)
			continue
		
		var node_data = node.call("save")
		var json_string = JSON.stringify(node_data)
		
		save_file.store_line(json_string)

# Saves
# Run 
# Active Run
# Battle Save
# TODO: Actually implement the above

func load_game() -> void:
	if not FileAccess.file_exists("user://savegame.save"):
		return
	
	var save_nodes = get_tree().get_nodes_in_group("saveable")
	for i in save_nodes:
		i.queue_free()
	
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: %s in %s at line %s" % [json.get_error_message(), json_string, json.get_error_line()])
			continue
		
		var node_data = json.data
		
		var new_object = load(node_data["filename"]).instantiate()
		get_node(node_data["parent"]).add_child(new_object)
		
		for i in node_data.keys():
			if i == "filename" or i == "parent":
				continue
			new_object.set(i, node_data[i])
#endregion
