extends Node

# Import the RoomTemplate class
const ROOM_TEMPLATE = preload("res://scenes/rooms/custom_rooms/RoomTemplate.gd")

# Custom room creation system
signal custom_room_discovered(room_name: String, room_path: String)
signal custom_room_created(room_name: String, room_instance: BaseRoom)

# Custom room registry
var custom_room_templates: Dictionary = {}
var custom_room_paths: Dictionary = {}

# Path to custom rooms folder
const CUSTOM_ROOMS_PATH = "res://scenes/rooms/custom_rooms/"

## TODO: Work on room template implementation
#func _ready():
	# Discover custom room templates on startup
	#discover_custom_room_templates()

func discover_custom_room_templates():
	"""Discover all custom room templates in the custom_rooms folder"""
	var dir = DirAccess.open(CUSTOM_ROOMS_PATH)
	if not dir:
		print("Custom rooms directory not found: ", CUSTOM_ROOMS_PATH)
		return
	
	# Get all .res files in the custom_rooms directory
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".res") and not file_name.begins_with("BaseRoomTemplate"):
			var room_path = CUSTOM_ROOMS_PATH + file_name
			var room_name = file_name.get_basename()
			
			# Try to load the room template
			if ResourceLoader.exists(room_path):
				var room_template = load(room_path)
				if room_template is ROOM_TEMPLATE:
					custom_room_templates[room_name] = room_template
					custom_room_paths[room_name] = room_path
					custom_room_discovered.emit(room_name, room_path)
					print("Custom room template discovered: ", room_name, " at ", room_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

func create_custom_room(room_name: String) -> BaseRoom:
	"""Create a custom room instance from template"""
	if not custom_room_templates.has(room_name):
		print("Custom room template not found: ", room_name)
		return null
	
	var room_template = custom_room_templates[room_name]
	var room_instance = room_template.create_room_instance()
	
	if room_instance:
		custom_room_created.emit(room_name, room_instance)
		print("Custom room created: ", room_name)
		return room_instance
	else:
		print("Failed to create room instance from template: ", room_name)
	
	return null

func get_custom_room_template(room_name: String) -> ROOM_TEMPLATE:
	"""Get a custom room template by name"""
	return custom_room_templates.get(room_name, null)

func get_all_custom_room_names() -> Array[String]:
	"""Get all discovered custom room names"""
	return custom_room_templates.keys()

func get_all_custom_room_templates() -> Dictionary:
	"""Get all custom room templates"""
	return custom_room_templates.duplicate()

func refresh_custom_room_templates():
	"""Refresh the custom room template discovery"""
	custom_room_templates.clear()
	custom_room_paths.clear()
	discover_custom_room_templates()

func is_custom_room(room_name: String) -> bool:
	"""Check if a room name corresponds to a custom room"""
	return custom_room_templates.has(room_name)

func get_custom_room_info(room_name: String) -> Dictionary:
	"""Get information about a custom room"""
	if not custom_room_templates.has(room_name):
		return {}
	
	var room_template = custom_room_templates[room_name]
	return room_template.get_room_info()

func create_room_from_template(template_path: String, room_name: String) -> BaseRoom:
	"""Create a room from a specific template file"""
	if not ResourceLoader.exists(template_path):
		print("Template file not found: ", template_path)
		return null
	
	var room_template = load(template_path)
	if room_template is ROOM_TEMPLATE:
		# Temporarily override the room name
		var original_name = room_template.room_name
		room_template.room_name = room_name
		
		var room_instance = room_template.create_room_instance()
		
		# Restore original name
		room_template.room_name = original_name
		
		if room_instance:
			custom_room_created.emit(room_name, room_instance)
			print("Custom room created from template: ", room_name)
			return room_instance
	
	return null
