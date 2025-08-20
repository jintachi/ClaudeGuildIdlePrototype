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

# Current tab context (set by parent)
var current_tab: String = ""

# Guild Hall reference (found automatically)
var guild_hall: Control = null

func _ready():
	"""Initialize navigation component"""
	# Find Guild Hall reference
	find_guild_hall()
	
	# Connect navigation buttons
	setup_navigation_connections()
	
	# Apply current tab context
	update_button_visibility()

func find_guild_hall():
	"""Find the Guild Hall scene in the tree"""
	# Look for Guild Hall in the scene tree
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.name == "Guild Hall":
		guild_hall = current_scene
		return
	
	# Alternative: search for a node with Guild Hall functions
	var root = get_tree().root
	for child in root.get_children():
		if child.has_method("show_main_hall"):
			guild_hall = child
			return
	
	print("Warning: Navigation - Could not find Guild Hall reference")

func setup_navigation_connections():
	"""Connect navigation buttons to Guild Hall functions"""
	if not guild_hall:
		print("Error: Navigation - No Guild Hall reference found")
		return
	
	# Connect each button to its corresponding function
	if main_hall_button and guild_hall.has_method("show_main_hall"):
		main_hall_button.pressed.connect(guild_hall.show_main_hall)
	
	if roster_button and guild_hall.has_method("show_roster_tab"):
		roster_button.pressed.connect(guild_hall.show_roster_tab)
	
	if quests_button and guild_hall.has_method("show_quests_tab"):
		quests_button.pressed.connect(guild_hall.show_quests_tab)
	
	if recruitment_button and guild_hall.has_method("show_recruitment_tab"):
		recruitment_button.pressed.connect(guild_hall.show_recruitment_tab)
	
	if town_map_button and guild_hall.has_method("show_town_map"):
		town_map_button.pressed.connect(guild_hall.show_town_map)
	
	print("Navigation: Connected to Guild Hall functions")

func set_current_tab(tab_name: String):
	"""Set the current tab context to hide the corresponding button"""
	current_tab = tab_name.to_lower()
	update_button_visibility()

func update_button_visibility():
	"""Update button visibility based on current tab"""
	# Show all buttons by default
	if main_hall_button:
		main_hall_button.visible = true
	if roster_button:
		roster_button.visible = true
	if quests_button:
		quests_button.visible = true
	if recruitment_button:
		recruitment_button.visible = true
	if town_map_button:
		town_map_button.visible = true
	
	# Hide the button for the current tab
	match current_tab:
		"main_hall", "mainhall":
			if main_hall_button:
				main_hall_button.visible = false
		"roster":
			if roster_button:
				roster_button.visible = false
		"quests", "quest":
			if quests_button:
				quests_button.visible = false
		"recruitment", "recruit":
			if recruitment_button:
				recruitment_button.visible = false
		"town_map", "townmap":
			if town_map_button:
				town_map_button.visible = false

# Utility functions for external control
func show_all_buttons():
	"""Show all navigation buttons"""
	current_tab = ""
	update_button_visibility()

func hide_button(button_name: String):
	"""Hide a specific button by name"""
	match button_name.to_lower():
		"main_hall", "mainhall":
			if main_hall_button:
				main_hall_button.visible = false
		"roster":
			if roster_button:
				roster_button.visible = false
		"quests":
			if quests_button:
				quests_button.visible = false
		"recruitment":
			if recruitment_button:
				recruitment_button.visible = false
		"town_map", "townmap":
			if town_map_button:
				town_map_button.visible = false

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
	return count
