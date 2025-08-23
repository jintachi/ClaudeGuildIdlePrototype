class_name TownMap
extends Control

## Town Map Scene
## Unique travel scene that can be opened with M keybind
## Allows travel to any room from anywhere in the game

# Adventurer's Guild buttons
@export var main_hall_button: Button
@export var roster_button: Button
@export var quests_button: Button
@export var recruitment_button: Button

# External Guild buttons
@export var merchants_guild_button: Button
@export var blacksmiths_guild_button: Button
@export var healers_guild_button: Button

# Close button
@onready var close_button: Button = $Background/MapContainer/CloseButton

# Track if map is currently open
var is_map_open: bool = false

func _ready():
	"""Initialize the town map"""
	setup_button_connections()
	setup_input_handling()
	
	# Ensure this node can process input even when other nodes might be paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Start hidden
	visible = false
	is_map_open = false

func setup_button_connections():
	"""Connect all travel buttons to their respective functions"""
	# Adventurer's Guild buttons
	if main_hall_button:
		main_hall_button.pressed.connect(_on_main_hall_travel)
	
	if roster_button:
		roster_button.pressed.connect(_on_roster_travel)
	
	if quests_button:
		quests_button.pressed.connect(_on_quests_travel)
	
	if recruitment_button:
		recruitment_button.pressed.connect(_on_recruitment_travel)
	
	# External Guild buttons
	if merchants_guild_button:
		merchants_guild_button.pressed.connect(_on_merchants_guild_travel)
	
	if blacksmiths_guild_button:
		blacksmiths_guild_button.pressed.connect(_on_blacksmiths_guild_travel)
	
	if healers_guild_button:
		healers_guild_button.pressed.connect(_on_healers_guild_travel)
	
	if close_button:
		close_button.pressed.connect(_on_close_map)

func setup_input_handling():
	"""Setup input handling for M key and ESC key"""
	# Connect to input manager if available
	if InputManager:
		InputManager.map_key_pressed.connect(_on_map_key_pressed)

func _input(event):
	"""Handle input events for map opening/closing"""
	if not event is InputEventKey or not event.pressed:
		return
	
	# M key to open/close map
	if event.keycode == KEY_M:
		_toggle_map()
		get_viewport().set_input_as_handled()
	
	# ESC key to close map
	if event.keycode == KEY_ESCAPE and is_map_open:
		_close_map()
		get_viewport().set_input_as_handled()

func _on_map_key_pressed():
	"""Handle map key press from InputManager"""
	_toggle_map()

func _toggle_map():
	"""Toggle the map open/closed"""
	if is_map_open:
		_close_map()
	else:
		_open_map()

func _open_map():
	"""Open the town map"""
	if not _can_open_map():
		return
	
	visible = true
	is_map_open = true
	
	# Don't pause the game - just show as overlay
	# The z_index = 100 in the scene will keep it on top
	
	print("Town Map opened")

func _close_map():
	"""Close the town map"""
	visible = false
	is_map_open = false
	
	# No need to unpause since we're not pausing anymore
	
	print("Town Map closed")

func _can_open_map() -> bool:
	"""Check if the map can be opened (game must be initialized)"""
	# Check if game is properly initialized
	if not GuildManager:
		print("Cannot open map: GuildManager not available")
		return false
	
	# Check if we're in a proper game state
	if GuildManager.get_current_room() == "":
		print("Cannot open map: No current room (game not started)")
		return false
	
	return true

# Travel button handlers
func _on_main_hall_travel():
	"""Travel to Main Hall"""
	_travel_to_room("Main Hall")

func _on_roster_travel():
	"""Travel to Roster"""
	_travel_to_room("Roster")

func _on_quests_travel():
	"""Travel to Quests"""
	_travel_to_room("Quests")

func _on_recruitment_travel():
	"""Travel to Recruitment"""
	_travel_to_room("Recruitment")

func _on_merchants_guild_travel():
	"""Travel to Merchant's Guild"""
	_travel_to_room("Merchant's Guild")

func _on_blacksmiths_guild_travel():
	"""Travel to Blacksmith's Guild"""
	_travel_to_room("Blacksmith's Guild")

func _on_healers_guild_travel():
	"""Travel to Healer's Guild"""
	_travel_to_room("Healer's Guild")

func _on_close_map():
	"""Handle close button press"""
	_close_map()

func _travel_to_room(room_name: String):
	"""Travel to the specified room"""
	if not GuildManager:
		print("Cannot travel: GuildManager not available")
		return
	
	# Travel to the room
	var success = GuildManager.enter_room(room_name)
	
	if success:
		print("Traveled to: ", room_name)
		# Close the map after successful travel
		_close_map()
	else:
		print("Failed to travel to: ", room_name)

# Public interface for external control
func open_map():
	"""Public method to open the map"""
	_open_map()

func close_map():
	"""Public method to close the map"""
	_close_map()

func is_open() -> bool:
	"""Check if the map is currently open"""
	return is_map_open
