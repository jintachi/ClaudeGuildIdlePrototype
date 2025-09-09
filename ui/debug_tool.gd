extends Control

## Debug Tool for modifying in-game stats
## Press F1 to toggle the debug tool

@export var debug_panel: Panel
@export var stats_container: VBoxContainer
@export var close_button: Button

var stat_controls: Dictionary = {}
var debug_visible: bool = false

func _ready():
	# Initially hide the debug tool
	debug_panel.visible = false
	
	# Connect buttons
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	# Connect action buttons
	var save_button = get_node("Panel/MainContainer/ButtonContainer/SaveButton")
	var load_button = get_node("Panel/MainContainer/ButtonContainer/LoadButton")
	var reset_button = get_node("Panel/MainContainer/ButtonContainer/ResetButton")
	
	if save_button:
		save_button.pressed.connect(_on_save_pressed)
	if load_button:
		load_button.pressed.connect(_on_load_pressed)
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)
	
	# Create stat controls
	create_stat_controls()

func _input(event):
	if event.is_action_pressed("debug_tool"):
		toggle_debug_tool()
	elif event.is_action_pressed("ui_cancel") and debug_visible:
		# Only handle ESC when debug tool is visible to avoid conflicts
		toggle_debug_tool()
		get_viewport().set_input_as_handled()


func create_stat_controls():
	"""Create controls for all game stats"""
	# Guild Resources
	create_section_header("Guild Resources")
	create_stat_control("influence", "Influence", 0, 999999)
	create_stat_control("gold", "Gold", 0, 999999)
	create_stat_control("building_materials", "Building Materials", 0, 999999)
	create_stat_control("armor_pieces", "Armor Pieces", 0, 999999)
	create_stat_control("weapons", "Weapons", 0, 999999)
	create_stat_control("food", "Food", 0, 999999)
	
	# Guild Settings
	create_section_header("Guild Settings")
	create_stat_control("max_roster_size", "Max Roster Size", 1, 20)
	create_stat_control("recruitment_quality_modifier", "Recruitment Quality Modifier", 0.1, 5.0, 0.1)
	
	# Progression
	create_section_header("Progression")
	create_stat_control("total_quests_completed", "Total Quests Completed", 0, 9999)
	
	# Transformations
	create_section_header("Transformations")
	create_bool_control("healers_guild", "Healer's Guild")
	create_bool_control("armory", "Armory")
	create_bool_control("market", "Market")
	create_bool_control("training_grounds", "Training Grounds")
	create_bool_control("library", "Library")
	create_bool_control("workshop", "Workshop")
	
	# Character Management
	create_section_header("Character Management")
	create_action_button("Add Random Character", _on_add_random_character)
	create_action_button("Add 5 Characters", _on_add_5_characters)
	create_action_button("Add 10 Characters", _on_add_10_characters)
	create_action_button("Clear All Characters", _on_clear_characters)
	
	# Quick Actions
	create_section_header("Quick Actions")
	create_action_button("Give 500 of All Resources", _on_give_500_resources)
	create_action_button("Give 10000 of All Resources", _on_give_10000_resources)
	create_action_button("Unlock All Buildings", _on_unlock_all_buildings)
	create_action_button("Complete 10 Quests", _on_complete_10_quests)

func create_section_header(text: String):
	"""Create a section header"""
	var header = Label.new()
	header.text = text
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", Color.YELLOW)
	stats_container.add_child(header)

func create_stat_control(stat_name: String, display_name: String, min_val: float, max_val: float, step: float = 1.0):
	"""Create a control for a numeric stat"""
	var container = HBoxContainer.new()
	stats_container.add_child(container)
	
	var label = Label.new()
	label.text = display_name + ":"
	label.custom_minimum_size = Vector2(200, 0)
	container.add_child(label)
	
	var spin_box = SpinBox.new()
	spin_box.min_value = min_val
	spin_box.max_value = max_val
	spin_box.step = step
	spin_box.value = get_stat_value(stat_name)
	spin_box.value_changed.connect(_on_stat_changed.bind(stat_name))
	spin_box.custom_minimum_size = Vector2(100, 0)
	container.add_child(spin_box)
	
	stat_controls[stat_name] = spin_box

func create_bool_control(stat_name: String, display_name: String):
	"""Create a control for a boolean stat"""
	var container = HBoxContainer.new()
	stats_container.add_child(container)
	
	var label = Label.new()
	label.text = display_name + ":"
	label.custom_minimum_size = Vector2(200, 0)
	container.add_child(label)
	
	var check_box = CheckBox.new()
	check_box.button_pressed = get_bool_stat_value(stat_name)
	check_box.toggled.connect(_on_bool_stat_changed.bind(stat_name))
	container.add_child(check_box)
	
	stat_controls[stat_name] = check_box

func create_action_button(text: String, callback: Callable):
	"""Create an action button"""
	var button = Button.new()
	button.text = text
	button.pressed.connect(callback)
	stats_container.add_child(button)

func get_stat_value(stat_name: String) -> float:
	"""Get the current value of a stat from GuildManager"""
	if not GuildManager:
		return 0.0
	
	match stat_name:
		"influence":
			return GuildManager.influence
		"gold":
			return GuildManager.gold
		"building_materials":
			return GuildManager.building_materials
		"armor_pieces":
			return GuildManager.armor_pieces
		"weapons":
			return GuildManager.weapons
		"food":
			return GuildManager.food
		"max_roster_size":
			return GuildManager.max_roster_size
		"recruitment_quality_modifier":
			return GuildManager.recruitment_quality_modifier
		"total_quests_completed":
			return GuildManager.total_quests_completed
		_:
			return 0.0

func get_bool_stat_value(stat_name: String) -> bool:
	"""Get the current value of a boolean stat from GuildManager"""
	if not GuildManager:
		return false
	
	match stat_name:
		"healers_guild":
			return GuildManager.transformations_unlocked.get("Healer's Guild", false)
		"armory":
			return GuildManager.transformations_unlocked.get("Armory", false)
		"market":
			return GuildManager.transformations_unlocked.get("Market", false)
		"training_grounds":
			return GuildManager.transformations_unlocked.get("Training Ground's", false)
		"library":
			return GuildManager.transformations_unlocked.get("Library", false)
		"workshop":
			return GuildManager.transformations_unlocked.get("Workshop", false)
		_:
			return false

func set_stat_value(stat_name: String, value: float):
	"""Set the value of a stat in GuildManager"""
	if not GuildManager:
		return
	
	match stat_name:
		"influence":
			GuildManager.influence = int(value)
		"gold":
			GuildManager.gold = int(value)
		"building_materials":
			GuildManager.building_materials = int(value)
		"armor_pieces":
			GuildManager.armor_pieces = int(value)
		"weapons":
			GuildManager.weapons = int(value)
		"food":
			GuildManager.food = int(value)
		"max_roster_size":
			GuildManager.max_roster_size = int(value)
		"recruitment_quality_modifier":
			GuildManager.recruitment_quality_modifier = value
		"total_quests_completed":
			GuildManager.total_quests_completed = int(value)

func set_bool_stat_value(stat_name: String, value: bool):
	"""Set the value of a boolean stat in GuildManager"""
	if not GuildManager:
		return
	
	match stat_name:
		"healers_guild":
			GuildManager.transformations_unlocked["Healer's Guild"] = value
		"armory":
			GuildManager.transformations_unlocked["Armory"] = value
		"market":
			GuildManager.transformations_unlocked["Market"] = value
		"training_grounds":
			GuildManager.transformations_unlocked["Training Ground's"] = value
		"library":
			GuildManager.transformations_unlocked["Library"] = value
		"workshop":
			GuildManager.transformations_unlocked["Workshop"] = value

func toggle_debug_tool():
	"""Toggle the debug tool visibility"""
	debug_visible = !debug_visible
	debug_panel.visible = debug_visible
	
	if debug_visible:
		refresh_all_values()

func refresh_all_values():
	"""Refresh all control values from current game state"""
	for stat_name in stat_controls:
		var control = stat_controls[stat_name]
		if control is SpinBox:
			control.value = get_stat_value(stat_name)
		elif control is CheckBox:
			control.button_pressed = get_bool_stat_value(stat_name)

func _on_stat_changed(stat_name: String, value: float):
	"""Handle stat value change"""
	set_stat_value(stat_name, value)
	print("Debug: Set ", stat_name, " to ", value)

func _on_bool_stat_changed(stat_name: String, value: bool):
	"""Handle boolean stat value change"""
	set_bool_stat_value(stat_name, value)
	print("Debug: Set ", stat_name, " to ", value)

func _on_close_pressed():
	"""Close the debug tool"""
	toggle_debug_tool()

func _on_save_pressed():
	"""Save the current game state"""
	if GuildManager:
		GuildManager.save_game()
		print("Debug: Game saved!")

func _on_load_pressed():
	"""Load the game state"""
	if GuildManager:
		GuildManager.load_game()
		refresh_all_values()
		print("Debug: Game loaded!")

func _on_reset_pressed():
	"""Reset all stats to default values"""
	if GuildManager:
		GuildManager.clear_save_file()
		GuildManager.initialize_game()
		refresh_all_values()
		print("Debug: Game reset to defaults!")

# Action button callbacks
func _on_add_random_character():
	"""Add a random character to the roster"""
	if GuildManager and GuildManager.roster.size() < GuildManager.max_roster_size:
		var character = GuildManager.generate_random_recruit()
		character.character_name = "Debug Character " + str(GuildManager.roster.size() + 1)
		GuildManager.add_character_to_roster(character)
		print("Debug: Added random character")

func _on_add_5_characters():
	"""Add 5 characters to the roster"""
	if GuildManager:
		for i in range(5):
			if GuildManager.roster.size() < GuildManager.max_roster_size:
				var character = GuildManager.generate_random_recruit()
				character.character_name = "Debug Character " + str(GuildManager.roster.size() + 1)
				character.quality = Character.Quality.TWO_STAR
				character.level = 3
				GuildManager.add_character_to_roster(character)
		print("Debug: Added 5 characters")

func _on_add_10_characters():
	"""Add 10 characters to the roster"""
	if GuildManager:
		# Temporarily increase roster size
		GuildManager.max_roster_size = 15
		
		for i in range(10):
			if GuildManager.roster.size() < GuildManager.max_roster_size:
				var character = GuildManager.generate_random_recruit()
				character.character_name = "Debug Character " + str(GuildManager.roster.size() + 1)
				character.quality = Character.Quality.THREE_STAR
				character.level = 5
				GuildManager.add_character_to_roster(character)
		
		# Set to 10 for the new roster size
		GuildManager.max_roster_size = 10
		print("Debug: Added 10 characters")

func _on_clear_characters():
	"""Clear all characters from the roster"""
	if GuildManager:
		GuildManager.roster.clear()
		print("Debug: Cleared all characters")

func _on_give_500_resources():
	"""Give 500 of all resources"""
	if GuildManager:
		GuildManager.influence += 500
		GuildManager.gold += 500
		GuildManager.building_materials += 500
		GuildManager.armor_pieces += 500
		GuildManager.weapons += 500
		GuildManager.food += 500
		refresh_all_values()
		print("Debug: Gave 500 of all resources")

func _on_give_10000_resources():
	"""Give 10000 of all resources"""
	if GuildManager:
		GuildManager.influence += 10000
		GuildManager.gold += 10000
		GuildManager.building_materials += 10000
		GuildManager.armor_pieces += 10000
		GuildManager.weapons += 10000
		GuildManager.food += 10000
		refresh_all_values()
		print("Debug: Gave 10000 of all resources")

func _on_unlock_all_buildings():
	"""Unlock all buildings"""
	if GuildManager:
		GuildManager.transformations_unlocked["Healer's Guild"] = true
		GuildManager.transformations_unlocked["Armory"] = true
		GuildManager.transformations_unlocked["Market"] = true
		GuildManager.transformations_unlocked["Training Ground's"] = true
		GuildManager.transformations_unlocked["Library"] = true
		GuildManager.transformations_unlocked["Workshop"] = true
		refresh_all_values()
		print("Debug: Unlocked all buildings")

func _on_complete_10_quests():
	"""Complete 10 quests"""
	if GuildManager:
		GuildManager.total_quests_completed += 10
		refresh_all_values()
		print("Debug: Completed 10 quests")
