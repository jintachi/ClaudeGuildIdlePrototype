class_name RoomManager
extends Node

# Room management system
signal room_changed(from_room: String, to_room: String)
signal room_unlocked(room_name: String)

# Room registry
var registered_rooms: Dictionary = {}
var current_room: BaseRoom = null
var previous_room: BaseRoom = null

# Room navigation history
var room_history: Array[String] = []
var max_history_size: int = 10

func _ready():
	# Register default rooms
	register_default_rooms()

func register_default_rooms():
	"""Register the default rooms available in the guild"""
	# These will be populated when rooms are created
	pass

func register_room(room: BaseRoom):
	"""Register a room with the room manager"""
	if room and room.room_name:
		registered_rooms[room.room_name] = room
		room.room_entered.connect(_on_room_entered)
		room.room_exited.connect(_on_room_exited)
		print("Room registered: ", room.room_name)

func unregister_room(room_name: String):
	"""Unregister a room from the manager"""
	if registered_rooms.has(room_name):
		var room = registered_rooms[room_name]
		if room.room_entered.is_connected(_on_room_entered):
			room.room_entered.disconnect(_on_room_entered)
		if room.room_exited.is_connected(_on_room_exited):
			room.room_exited.disconnect(_on_room_exited)
		registered_rooms.erase(room_name)

func enter_room(room_name: String) -> bool:
	"""Enter a specific room"""
	if not registered_rooms.has(room_name):
		print("Room not found: ", room_name)
		return false
	
	var room = registered_rooms[room_name]
	if not room.can_enter_room():
		print("Cannot enter room: ", room_name)
		return false
	
	# Exit current room if any
	if current_room:
		current_room.exit_room()
		previous_room = current_room
	
	# Enter new room
	current_room = room
	room.enter_room()
	
	# Update history
	add_to_history(room_name)
	
	room_changed.emit(previous_room.room_name if previous_room else "", room_name)
	return true

func return_to_main_hall():
	"""Return to the main hall"""
	enter_room("Main Hall")

func go_back():
	"""Go back to the previous room in history"""
	if room_history.size() > 1:
		room_history.pop_back()  # Remove current room
		var previous_room_name = room_history[-1]
		enter_room(previous_room_name)

func add_to_history(room_name: String):
	"""Add room to navigation history"""
	room_history.append(room_name)
	if room_history.size() > max_history_size:
		room_history.pop_front()

func get_available_rooms() -> Array[Dictionary]:
	"""Get list of available rooms for navigation"""
	var available_rooms: Array[Dictionary] = []
	
	for room in registered_rooms.values():
		if room.can_enter_room():
			available_rooms.append(room.get_room_info())
	
	return available_rooms

func get_room_by_name(room_name: String) -> BaseRoom:
	"""Get a room by name"""
	return registered_rooms.get(room_name, null)

func unlock_room(room_name: String):
	"""Unlock a room"""
	if registered_rooms.has(room_name):
		var room = registered_rooms[room_name]
		room.is_unlocked = true
		room_unlocked.emit(room_name)

func save_all_room_states():
	"""Save state for all rooms"""
	for room in registered_rooms.values():
		room.save_room_state()

func load_all_room_states():
	"""Load state for all rooms"""
	for room in registered_rooms.values():
		room.load_room_state()

func _on_room_entered(room_name: String):
	"""Handle room entry"""
	print("Entered room: ", room_name)

func _on_room_exited(room_name: String):
	"""Handle room exit"""
	print("Exited room: ", room_name)

func get_current_room() -> BaseRoom:
	"""Get the currently active room"""
	return current_room

func get_room_history() -> Array[String]:
	"""Get the room navigation history"""
	return room_history.duplicate()
