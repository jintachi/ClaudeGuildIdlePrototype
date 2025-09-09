class_name Navigation
extends HBoxContainer

## Navigation Component
## Reusable navigation panel that automatically connects to Guild Hall functions
## Handles context-aware button visibility (hides current tab button)

# Navigation buttons
@onready var main_hall_button: Button = $MainHallButton
@onready var roster_button: Button = $RosterButton
@onready var quests_button: Button = $QuestsButton
@onready var recruitment_button: Button = $RecruitmentButton
@onready var town_map_button: Button = $TownMapButton

# Dynamic navigation tracking
var dynamic_buttons: Dictionary = {}  # Store dynamically created buttons
var base_buttons: Array[String] = ["MainHallButton", "RosterButton", "QuestsButton", "RecruitmentButton", "TownMapButton"]

# Current tab context (set by parent)
var current_tab: String = ""

func _ready():
	"""Initialize navigation component"""
	# Connect navigation buttons
	setup_navigation_connections()
	
	# Connect to GuildManager signals
	setup_guild_manager_connections()
	
	# Update dynamic navigation based on unlocked rooms
	update_dynamic_navigation()
	
	# Apply current tab context
	update_button_visibility()

func setup_navigation_connections():
	"""Connect navigation buttons to GuildManager functions"""
	# Connect each button to its corresponding GuildManager function
	if main_hall_button:
		main_hall_button.pressed.connect(_on_main_hall_pressed)
	
	if roster_button:
		roster_button.pressed.connect(_on_roster_pressed)
	
	if quests_button:
		quests_button.pressed.connect(_on_quests_pressed)
	
	if recruitment_button:
		recruitment_button.pressed.connect(_on_recruitment_pressed)
	
	if town_map_button:
		town_map_button.pressed.connect(_on_town_map_pressed)
	
	print("Navigation: Connected to GuildManager functions")

func setup_guild_manager_connections():
	"""Connect to GuildManager signals for dynamic navigation updates"""
	# Connect to room unlocking events
	if SignalBus:
		SignalBus.room_unlocked.connect(_on_room_unlocked)
		print("Navigation: Connected to room_unlocked signal")

func _on_room_unlocked(room_name: String):
	"""Handle room unlocking events"""
	print("Navigation: Room unlocked: ", room_name)
	# Update dynamic navigation to include the new room
	update_dynamic_navigation()
	update_button_visibility()

# Navigation button handlers
func _on_main_hall_pressed():
	"""Handle main hall button press"""
	print("Navigation: Main Hall button pressed")
	if GuildManager:
		GuildManager.enter_room("Main Hall")
		print("Navigation: Called GuildManager.enter_room('Main Hall')")

func _on_roster_pressed():
	"""Handle roster button press"""
	print("Navigation: Roster button pressed")
	if GuildManager:
		GuildManager.enter_room("Roster")
		print("Navigation: Called GuildManager.enter_room('Roster')")

func _on_quests_pressed():
	"""Handle quests button press"""
	print("Navigation: Quests button pressed")
	print("Navigation: GuildManager reference: ", GuildManager)
	print("Navigation: Current room: ", GuildManager.get_current_room() if GuildManager else "null")
	if GuildManager:
		print("Navigation: About to call GuildManager.enter_room('Quests')")
		GuildManager.enter_room("Quests")
		print("Navigation: Called GuildManager.enter_room('Quests')")
	else:
		print("Navigation: GuildManager is null!")

func _on_recruitment_pressed():
	"""Handle recruitment button press"""
	print("Navigation: Recruitment button pressed")
	if GuildManager:
		GuildManager.enter_room("Recruitment")
		print("Navigation: Called GuildManager.enter_room('Recruitment')")

func _on_town_map_pressed():
	"""Handle town map button press"""
	print("Navigation: Town Map button pressed")
	# Emit signal to open town map instead of changing rooms
	if SignalBus:
		SignalBus.map_key_pressed.emit()
		print("Navigation: Emitted map_key_pressed signal")

func set_current_tab(tab_name: String):
	"""Set the current tab context to hide the corresponding button"""
	current_tab = tab_name.to_lower()
	update_button_visibility()

func set_current_room(room_name: String):
	"""Set the current room context for dynamic navigation"""
	# Convert room name to tab format
	var tab_name = room_name.to_lower().replace(" ", "_")
	set_current_tab(tab_name)

func update_button_visibility():
	"""Update button appearance based on current tab - all buttons visible, selected button flattened and disabled"""
	# Reset all buttons to normal state
	if main_hall_button:
		main_hall_button.visible = true
		main_hall_button.flat = false
		main_hall_button.disabled = false
	if roster_button:
		roster_button.visible = true
		roster_button.flat = false
		roster_button.disabled = false
	if quests_button:
		quests_button.visible = true
		quests_button.flat = false
		quests_button.disabled = false
	if recruitment_button:
		recruitment_button.visible = true
		recruitment_button.flat = false
		recruitment_button.disabled = false
	if town_map_button:
		town_map_button.visible = true
		town_map_button.flat = false
		town_map_button.disabled = false
	
	# Update dynamic buttons
	update_dynamic_button_visibility()
	
	# Set the current tab button to flattened and disabled (pressed appearance)
	match current_tab:
		"main_hall", "mainhall":
			if main_hall_button:
				main_hall_button.flat = true
				main_hall_button.disabled = true
		"roster":
			if roster_button:
				roster_button.flat = true
				roster_button.disabled = true
		"quests", "quest":
			if quests_button:
				quests_button.flat = true
				quests_button.disabled = true
		"recruitment", "recruit":
			if recruitment_button:
				recruitment_button.flat = true
				recruitment_button.disabled = true
		"town_map", "townmap":
			if town_map_button:
				town_map_button.flat = true
				town_map_button.disabled = true

# Utility functions for external control
func show_all_buttons():
	"""Show all navigation buttons in normal state"""
	current_tab = ""
	update_button_visibility()

func set_button_flat(button_name: String, is_flat: bool = true):
	"""Set a specific button to flattened state"""
	match button_name.to_lower():
		"main_hall", "mainhall":
			if main_hall_button:
				main_hall_button.flat = is_flat
		"roster":
			if roster_button:
				roster_button.flat = is_flat
		"quests":
			if quests_button:
				quests_button.flat = is_flat
		"recruitment":
			if recruitment_button:
				recruitment_button.flat = is_flat
		"town_map", "townmap":
			if town_map_button:
				town_map_button.flat = is_flat

# hide_button function removed - use set_button_flat instead for better control

func get_button_count() -> int:
	"""Get the number of visible buttons"""
	var count = 0
	if main_hall_button and main_hall_button.visible:
		count += 1
	if roster_button and roster_button.visible:
		count += 1
	if quests_button and quests_button.visible:
		count += 1
	if recruitment_button and recruitment_button.visible:
		count += 1
	if town_map_button and town_map_button.visible:
		count += 1
	
	# Add dynamic buttons
	for button in dynamic_buttons.values():
		if button and button.visible:
			count += 1
	
	return count

#region Dynamic Navigation System
func update_dynamic_navigation():
	"""Update navigation buttons based on unlocked rooms"""
	if not GuildManager:
		return
	
	var unlocked_rooms = GuildManager.get_unlocked_rooms()
	
	# Check for rooms that need navigation buttons
	for room_name in unlocked_rooms:
		var button_name = get_button_name_for_room(room_name)
		
		# Skip base buttons that already exist
		if base_buttons.has(button_name):
			continue
		
		# Create button if it doesn't exist
		if not dynamic_buttons.has(room_name):
			create_navigation_button(room_name, button_name)

func get_button_name_for_room(room_name: String) -> String:
	"""Convert room name to button name format"""
	return room_name.replace(" ", "") + "Button"

func create_navigation_button(room_name: String, button_name: String):
	"""Create a new navigation button for an unlocked room"""
	var button = Button.new()
	button.name = button_name
	button.text = room_name
	button.layout_mode = Control.LayoutPreset.PRESET_FULL_RECT
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Connect the button
	button.pressed.connect(_on_dynamic_button_pressed.bind(room_name))
	
	# Add to the navigation container
	add_child(button)
	
	# Store reference
	dynamic_buttons[room_name] = button
	
	print("Navigation: Created dynamic button for room: ", room_name)

func _on_dynamic_button_pressed(room_name: String):
	"""Handle dynamic button press"""
	print("Navigation: Dynamic button pressed for room: ", room_name)
	if GuildManager:
		GuildManager.enter_room(room_name)
		print("Navigation: Called GuildManager.enter_room('", room_name, "')")

func update_dynamic_button_visibility():
	"""Update visibility of dynamic buttons based on current tab"""
	for room_name in dynamic_buttons:
		var button = dynamic_buttons[room_name]
		if button:
			button.visible = true
			button.flat = false
			button.disabled = false
			
			# Set current tab button to flattened and disabled
			if current_tab == room_name.to_lower().replace(" ", "_"):
				button.flat = true
				button.disabled = true

func remove_dynamic_button(room_name: String):
	"""Remove a dynamic navigation button"""
	if dynamic_buttons.has(room_name):
		var button = dynamic_buttons[room_name]
		if button:
			button.queue_free()
		dynamic_buttons.erase(room_name)
		print("Navigation: Removed dynamic button for room: ", room_name)

func refresh_dynamic_navigation():
	"""Refresh all dynamic navigation buttons"""
	# Remove all dynamic buttons
	for room_name in dynamic_buttons.keys():
		remove_dynamic_button(room_name)
	
	# Recreate based on current unlocked rooms
	update_dynamic_navigation()
	
	# Update visibility
	update_dynamic_button_visibility()
#endregion
