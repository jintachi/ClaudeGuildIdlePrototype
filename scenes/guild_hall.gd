class_name Main
extends Control

#region Setup and Initialization
# UI Containers for room display
@export var room_container: Control
@export var navigation_panel: Control

# Navigation buttons
@export var main_hall_button: Button
@export var roster_button: Button
@export var quests_button: Button
@export var recruitment_button: Button

# UI Scaling controls (kept for compatibility)
@export var scale_05_button: Button
@export var scale_075_button: Button
@export var scale_1_button: Button
@export var scale_15_button: Button
@export var scale_2_button: Button
@export var scale_3_button: Button
@export var save_button: Button
@export var load_button: Button
@export var new_game_button: Button

# Current state
var current_scale_factor: float = 1.0

func _ready():
	# Setup viewport scaling first
	setup_viewport_scaling()
	
	setup_ui_connections()
	setup_signal_connections()
	
	# Initialize scale button states
	update_scale_button_states(get_tree().root.content_scale_factor)
	
	# Ensure recruits are generated
	if GuildManager.available_recruits.is_empty():
		GuildManager.generate_recruits()
	
	# Start with main hall room
	GuildManager.enter_room("Main Hall")
	update_ui()
	
	# Set initial navigation context to main hall
	call_deferred("update_all_navigation_contexts", "main_hall")
#endregion

#region Viewport Scaling Setup
func setup_viewport_scaling():
	"""Setup responsive viewport scaling for the Guild Hall"""
	# HYBRID APPROACH: Use ResponsiveLayout system + responsive containers
	# This combines the best of both automatic conversion and proper layout
	
	# Connect to viewport and resolution changes
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	# Apply responsive layout to the main container
	apply_responsive_layout()

func apply_responsive_layout():
	"""Apply responsive layout to the guild hall"""
	# Load ResponsiveLayout class if available
	var responsive_layout_script = load("res://ui/systems/ResponsiveLayout.gd")
	if responsive_layout_script:
		responsive_layout_script.convert_scene_to_responsive(self, responsive_layout_script.ConversionMode.SMART_GRID)

func _on_viewport_size_changed():
	"""Handle viewport size changes"""
	# Update responsive layout when viewport changes
	apply_responsive_layout()

func _on_ui_scale_changed(new_scale: float):
	"""Handle UI scale changes from SignalBus"""
	update_scale_button_states(new_scale)
#endregion

#region UI Setup and Connections
func setup_ui_connections():
	"""Setup UI button connections"""
	# Navigation buttons
	if main_hall_button:
		main_hall_button.pressed.connect(_on_main_hall_pressed)
	if roster_button:
		roster_button.pressed.connect(_on_roster_pressed)
	if quests_button:
		quests_button.pressed.connect(_on_quests_pressed)
	if recruitment_button:
		recruitment_button.pressed.connect(_on_recruitment_pressed)
	
	# UI Scaling buttons
	if scale_05_button:
		scale_05_button.pressed.connect(_on_scale_05_pressed)
	if scale_075_button:
		scale_075_button.pressed.connect(_on_scale_075_pressed)
	if scale_1_button:
		scale_1_button.pressed.connect(_on_scale_1_pressed)
	if scale_15_button:
		scale_15_button.pressed.connect(_on_scale_15_pressed)
	if scale_2_button:
		scale_2_button.pressed.connect(_on_scale_2_pressed)
	if scale_3_button:
		scale_3_button.pressed.connect(_on_scale_3_pressed)
	
	# Save/Load buttons
	if save_button:
		save_button.pressed.connect(_on_save_pressed)
	if load_button:
		load_button.pressed.connect(_on_load_pressed)
	if new_game_button:
		new_game_button.pressed.connect(_on_new_game_pressed)

func setup_signal_connections():
	"""Setup signal connections for the guild hall"""
	# Connect to guild manager signals
	if GuildManager:
		GuildManager.quest_completed.connect(_on_quest_completed)
		GuildManager.emergency_quest_available.connect(_on_emergency_quest_available)
		GuildManager.character_recruited.connect(_on_character_recruited)
		GuildManager.room_changed.connect(_on_room_changed)
		GuildManager.room_unlocked.connect(_on_room_unlocked)
	
	# Connect to signal bus
	if SignalBus:
		SignalBus.quest_started.connect(_on_quest_started)
		SignalBus.character_promoted.connect(_on_character_promoted)
		SignalBus.ui_scale_changed.connect(_on_ui_scale_changed)
#endregion

#region UI Update Functions
func update_ui():
	"""Update the main UI display"""
	# Update current room display based on GuildManager's current room
	update_room_display()
	
	# Update navigation context
	update_all_navigation_contexts(get_current_room_context())

func update_room_display():
	"""Update the room display based on current room"""
	var current_room = GuildManager.get_current_room()
	
	# Clear the room container
	for child in room_container.get_children():
		child.queue_free()
	
	# Create and add the appropriate room content
	match current_room:
		"Main Hall":
			create_main_hall_content()
		"Roster":
			create_roster_content()
		"Quests":
			create_quests_content()
		"Recruitment":
			create_recruitment_content()

func create_main_hall_content():
	"""Create main hall content"""
	var main_hall = VBoxContainer.new()
	main_hall.name = "MainHallContent"
	
	# Add resources display
	var resources_label = Label.new()
	resources_label.text = "Influence: %d | Gold: %d | Food: %d | Materials: %d | Armor: %d | Weapons: %d" % [
		GuildManager.influence, GuildManager.gold, GuildManager.food,
		GuildManager.building_materials, GuildManager.armor_pieces, GuildManager.weapons
	]
	main_hall.add_child(resources_label)
	
	# Add quest panels
	var quest_panel = VBoxContainer.new()
	quest_panel.name = "QuestPanel"
	
	var active_quests_label = Label.new()
	active_quests_label.text = "Active Quests: %d" % GuildManager.active_quests.size()
	quest_panel.add_child(active_quests_label)
	
	var awaiting_quests_label = Label.new()
	awaiting_quests_label.text = "Awaiting Completion: %d" % GuildManager.awaiting_completion_quests.size()
	quest_panel.add_child(awaiting_quests_label)
	
	main_hall.add_child(quest_panel)
	
	room_container.add_child(main_hall)

func create_roster_content():
	"""Create roster content"""
	var roster_content = VBoxContainer.new()
	roster_content.name = "RosterContent"
	
	var roster_label = Label.new()
	roster_label.text = "Guild Roster (%d/%d)" % [GuildManager.roster.size(), GuildManager.max_roster_size]
	roster_content.add_child(roster_label)
	
	# Add character list
	for character in GuildManager.roster:
		var char_label = Label.new()
		char_label.text = "%s - Level %d %s" % [character.name, character.level, character.character_class]
		roster_content.add_child(char_label)
	
	room_container.add_child(roster_content)

func create_quests_content():
	"""Create quests content"""
	var quests_content = VBoxContainer.new()
	quests_content.name = "QuestsContent"
	
	var quests_label = Label.new()
	quests_label.text = "Available Quests: %d" % GuildManager.available_quests.size()
	quests_content.add_child(quests_label)
	
	# Add quest list
	for quest in GuildManager.available_quests:
		var quest_label = Label.new()
		quest_label.text = "%s (%s Rank)" % [quest.quest_name, quest.quest_rank]
		quests_content.add_child(quest_label)
	
	room_container.add_child(quests_content)

func create_recruitment_content():
	"""Create recruitment content"""
	var recruitment_content = VBoxContainer.new()
	recruitment_content.name = "RecruitmentContent"
	
	var recruitment_label = Label.new()
	recruitment_label.text = "Available Recruits: %d" % GuildManager.available_recruits.size()
	recruitment_content.add_child(recruitment_label)
	
	# Add recruit list
	for recruit in GuildManager.available_recruits:
		var recruit_label = Label.new()
		recruit_label.text = "%s - %s" % [recruit.name, recruit.character_class]
		recruitment_content.add_child(recruit_label)
	
	room_container.add_child(recruitment_content)

func get_current_room_context() -> String:
	"""Get the current room context for navigation"""
	var current_room = GuildManager.get_current_room()
	return current_room.to_lower().replace(" ", "_")

func update_all_navigation_contexts(context: String):
	"""Update all navigation components with the current context"""
	# Find all Navigation components and update their context
	var navigation_nodes = get_tree().get_nodes_in_group("navigation")
	for node in navigation_nodes:
		if node.has_method("update_navigation_context"):
			node.update_navigation_context(context)
#endregion

#region Navigation Handlers
func _on_main_hall_pressed():
	"""Handle main hall button press"""
	GuildManager.enter_room("Main Hall")

func _on_roster_pressed():
	"""Handle roster button press"""
	GuildManager.enter_room("Roster")

func _on_quests_pressed():
	"""Handle quests button press"""
	GuildManager.enter_room("Quests")

func _on_recruitment_pressed():
	"""Handle recruitment button press"""
	GuildManager.enter_room("Recruitment")
#endregion

#region Signal Handlers
func _on_room_changed(from_room: String, to_room: String):
	"""Handle room changes"""
	print("Room changed from %s to %s" % [from_room, to_room])
	update_ui()
	update_all_navigation_contexts(to_room.to_lower().replace(" ", "_"))

func _on_room_unlocked(room_name: String):
	"""Handle room unlocking"""
	print("Room unlocked: %s" % room_name)
	# Update navigation to show new room
	update_ui()

func _on_quest_started(quest: Quest):
	"""Handle quest started event"""
	print("Quest started: %s" % quest.quest_name)
	update_ui()

func _on_quest_completed(quest: Quest):
	"""Handle quest completed event"""
	print("Quest completed: %s" % quest.quest_name)
	update_ui()

func _on_character_promoted(character: Character):
	"""Handle character promotion event"""
	print("Character promoted: %s" % character.name)
	update_ui()

func _on_emergency_quest_available(quest_data: Dictionary):
	"""Handle emergency quest available event"""
	print("Emergency quest available: %s" % quest_data.name)
	_show_emergency_quest_popup(quest_data)

func _on_character_recruited(character: Character):
	"""Handle character recruited event"""
	print("Character recruited: %s" % character.name)
	update_ui()
#endregion

#region Save/Load Functions
func _on_save_pressed():
	"""Handle save button press"""
	GuildManager.save_game()
	print("Game saved!")

func _on_load_pressed():
	"""Handle load button press"""
	GuildManager.load_game()
	update_ui()
	print("Game loaded!")

func _on_new_game_pressed():
	"""Handle new game button press"""
	_show_new_game_confirmation()
#endregion

#region UI Scaling Functions
func _on_scale_05_pressed():
	"""Set UI scale to 0.5"""
	get_tree().root.content_scale_factor = 0.5
	
	# Update UIScalingManager if available
	if UIScalingManager:
		UIScalingManager.set_scaling_mode(UIScalingManager.ScalingMode.PROPORTIONAL)
	
	print("UI Scale set to: 0.5")
	update_scale_button_states(0.5)

func _on_scale_075_pressed():
	"""Set UI scale to 0.75"""
	get_tree().root.content_scale_factor = 0.75
	
	# Update UIScalingManager if available
	if UIScalingManager:
		UIScalingManager.set_scaling_mode(UIScalingManager.ScalingMode.PROPORTIONAL)
	
	print("UI Scale set to: 0.75")
	update_scale_button_states(0.75)

func _on_scale_1_pressed():
	"""Set UI scale to 1.0"""
	get_tree().root.content_scale_factor = 1.0
	
	# Update UIScalingManager if available
	if UIScalingManager:
		UIScalingManager.set_scaling_mode(UIScalingManager.ScalingMode.PROPORTIONAL)
	
	print("UI Scale set to: 1.0")
	update_scale_button_states(1.0)

func _on_scale_15_pressed():
	"""Set UI scale to 1.5"""
	get_tree().root.content_scale_factor = 1.5
	
	# Update UIScalingManager if available
	if UIScalingManager:
		UIScalingManager.set_scaling_mode(UIScalingManager.ScalingMode.PROPORTIONAL)
	
	print("UI Scale set to: 1.5")
	update_scale_button_states(1.5)

func _on_scale_2_pressed():
	"""Set UI scale to 2.0"""
	get_tree().root.content_scale_factor = 2.0
	
	# Update UIScalingManager if available
	if UIScalingManager:
		UIScalingManager.set_scaling_mode(UIScalingManager.ScalingMode.PROPORTIONAL)
	
	print("UI Scale set to: 2.0")
	update_scale_button_states(2.0)

func _on_scale_3_pressed():
	"""Set UI scale to 3.0"""
	get_tree().root.content_scale_factor = 3.0
	
	# Update UIScalingManager if available
	if UIScalingManager:
		UIScalingManager.set_scaling_mode(UIScalingManager.ScalingMode.PROPORTIONAL)
	
	print("UI Scale set to: 3.0")
	update_scale_button_states(3.0)

func update_scale_button_states(current_scale: float):
	"""Update button states to show which scale is currently active"""
	# Reset all buttons to normal state
	scale_05_button.flat = false
	scale_075_button.flat = false
	scale_1_button.flat = false
	scale_15_button.flat = false
	scale_2_button.flat = false
	scale_3_button.flat = false
	
	# Set the current scale button to flat (pressed appearance)
	if abs(current_scale - 0.5) < 0.01:
		scale_05_button.flat = true
	elif abs(current_scale - 0.75) < 0.01:
		scale_075_button.flat = true
	elif abs(current_scale - 1.0) < 0.01:
		scale_1_button.flat = true
	elif abs(current_scale - 1.5) < 0.01:
		scale_15_button.flat = true
	elif abs(current_scale - 2.0) < 0.01:
		scale_2_button.flat = true
	elif abs(current_scale - 3.0) < 0.01:
		scale_3_button.flat = true
#endregion

#region Popup Functions
func _show_error_popup(message: String):
	var popup = AcceptDialog.new()
	add_child(popup)
	popup.dialog_text = message
	popup.title = "Error"
	popup.popup_centered()

func _show_emergency_quest_popup(requirements: Dictionary):
	var popup = AcceptDialog.new()
	add_child(popup)
	
	popup.dialog_text = "EMERGENCY QUEST AVAILABLE!\n\n" + requirements.name + "\n\n" + requirements.description + "\n\nReward: " + requirements.unlock_description
	popup.title = "Emergency Quest"
	popup.popup_centered()

func _show_new_game_confirmation():
	var confirm = ConfirmationDialog.new()
	add_child(confirm)
	confirm.dialog_text = "Are you sure you want to start a new game? This will delete your current save file."
	confirm.title = "New Game"
	confirm.confirmed.connect(func(): 
		GuildManager.clear_save_file()
		update_ui()
		print("New game started!")
	)
	confirm.popup_centered()
#endregion
