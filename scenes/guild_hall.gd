class_name Main
extends Control

#region Setup and Initialization
# UI Containers for room display
@export var room_container: Control
@export var navigation_panel: Control
@export var resources_display: Label
@export var inventory_button: Button

# Town Map reference
@export var town_map: Control

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
	
	# Refresh navigation to include any unlocked rooms
	if navigation_panel and navigation_panel.has_method("refresh_dynamic_navigation"):
		navigation_panel.refresh_dynamic_navigation()
	
	# Set initial navigation context to main hall
	call_deferred("update_navigation_context", "main_hall")
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
		# Apply to the main guild hall
		responsive_layout_script.convert_scene_to_responsive(self, responsive_layout_script.ConversionMode.SMART_GRID)
		
		# Specifically apply to room container to ensure all rooms are properly scaled
		if room_container:
			responsive_layout_script.convert_scene_to_responsive(room_container, responsive_layout_script.ConversionMode.SMART_GRID)
			
			# Apply to all child rooms in the container
			for child in room_container.get_children():
				apply_responsive_layout_to_room(child)

func apply_responsive_layout_to_room(room_instance: Node):
	"""Apply responsive layout to a specific room instance"""
	var responsive_layout_script = load("res://ui/systems/ResponsiveLayout.gd")
	if responsive_layout_script and room_instance is Control:
		responsive_layout_script.convert_scene_to_responsive(room_instance, responsive_layout_script.ConversionMode.SMART_GRID)

func _on_viewport_size_changed():
	"""Handle viewport size changes"""
	# Update responsive layout when viewport changes
	apply_responsive_layout()

func _on_ui_scale_changed(new_scale: float):
	"""Handle UI scale changes from SignalBus"""
	update_scale_button_states(new_scale)
	
	# Reapply responsive layout to room container when UI scale changes
	call_deferred("apply_responsive_layout")
#endregion

#region UI Setup and Connections
func setup_ui_connections():
	"""Setup UI button connections"""
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
	
	# Inventory button
	if inventory_button:
		inventory_button.pressed.connect(_on_inventory_button_pressed)

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
		SignalBus.map_key_pressed.connect(_on_map_key_pressed)
	
	# Connect to custom room manager signals
	if get_node_or_null("/root/CustomRoomCreator"):
		get_node("/root/CustomRoomCreator").custom_room_discovered.connect(_on_custom_room_discovered)
#endregion

#region UI Update Functions
func update_ui():
	"""Update the main UI display"""
	# Update current room display based on GuildManager's current room
	update_room_display()
	
	# Update resource display
	update_resource_display()
	
	# Update navigation context
	update_navigation_context(get_current_room_context())

func update_resource_display():
	"""Update the resource display"""
	if not resources_display or not GuildManager:
		return
	
	var resources = GuildManager.get_guild_status_summary().resources
	var inventory = GuildManager.get_inventory()
	
	var inventory_text = ""
	if inventory:
		inventory_text = " | Inventory: %d/%d" % [inventory.filled_slots, inventory.total_slots]
	
	resources_display.text = "Resources: Influence: %d | Gold: %d | Food: %d | Materials: %d | Armor: %d | Weapons: %d%s" % [
		resources.influence, resources.gold, resources.food, 
		resources.building_materials, resources.armor, resources.weapons, inventory_text
	]
	
	# Update inventory button color based on usage
	if inventory_button and inventory:
		inventory_button.modulate = inventory.get_usage_color()

func update_room_display():
	"""Update the room display based on current room"""
	var current_room = GuildManager.get_current_room()
	
	# Call on_room_exited() on current room before clearing
	for child in room_container.get_children():
		if child is BaseRoom and child.has_method("on_room_exited"):
			child.on_room_exited()
	
	# Clear the room container
	for child in room_container.get_children():
		child.queue_free()
	
	# Check if it's a custom room first
	var custom_room_creator = get_node_or_null("/root/CustomRoomCreator")
	if custom_room_creator and custom_room_creator.is_custom_room(current_room):
		var room_instance = custom_room_creator.create_custom_room(current_room)
		if room_instance:
			room_container.add_child(room_instance)
			if room_instance is BaseRoom:
				room_instance.enter_room()
		else:
			print("Failed to create custom room: ", current_room)
		return
	
	# Load and instantiate the appropriate built-in room scene
	var room_scene_path = ""
	match current_room:
		"Main Hall":
			room_scene_path = "res://scenes/rooms/MainHallRoom.tscn"
		"Roster":
			room_scene_path = "res://scenes/rooms/RosterRoom.tscn"
		"Quests":
			room_scene_path = "res://scenes/rooms/QuestsRoom.tscn"
		"Recruitment":
			room_scene_path = "res://scenes/rooms/RecruitmentRoom.tscn"
		"Training Room":
			room_scene_path = "res://scenes/rooms/TrainingRoom.tscn"
		"Merchant's Guild":
			room_scene_path = "res://scenes/rooms/MerchantsGuildRoom.tscn"
		"Blacksmith's Guild":
			room_scene_path = "res://scenes/rooms/BlacksmithsGuildRoom.tscn"
		"Healer's Guild":
			room_scene_path = "res://scenes/rooms/HealersGuildRoom.tscn"
	
	if room_scene_path and ResourceLoader.exists(room_scene_path):
		var room_scene = load(room_scene_path)
		var room_instance = room_scene.instantiate()
		room_container.add_child(room_instance)
		
		# Apply responsive layout to the new room
		apply_responsive_layout_to_room(room_instance)
		
		# Enter the room
		if room_instance is BaseRoom:
			room_instance.enter_room()
	else:
		print("Room scene not found: ", room_scene_path)

func get_current_room_context() -> String:
	"""Get the current room context for navigation"""
	var current_room = GuildManager.get_current_room()
	return current_room.to_lower().replace(" ", "_")

func update_navigation_context(context: String):
	"""Update the navigation component with the current context"""
	if navigation_panel and navigation_panel.has_method("set_current_room"):
		# Convert context back to room name format
		var room_name = context.replace("_", " ").capitalize()
		navigation_panel.set_current_room(room_name)
	elif navigation_panel and navigation_panel.has_method("set_current_tab"):
		navigation_panel.set_current_tab(context)
#endregion

#region Signal Handlers
func _on_room_changed(from_room: String, to_room: String):
	"""Handle room changes"""
	print("Room changed from %s to %s" % [from_room, to_room])
	update_ui()
	update_navigation_context(to_room.to_lower().replace(" ", "_"))
	
	# Refresh navigation to ensure all unlocked rooms are available
	if navigation_panel and navigation_panel.has_method("refresh_dynamic_navigation"):
		navigation_panel.refresh_dynamic_navigation()
	
	# Apply responsive layout to the new room after a short delay to ensure it's fully loaded
	call_deferred("apply_responsive_layout")

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
	print("Character recruited: %s" % character.character_name)
	update_ui()

func _on_custom_room_discovered(room_name: String, room_path: String):
	"""Handle custom room discovery"""
	print("Custom room discovered: ", room_name, " at ", room_path)
	# You can add custom room navigation buttons here if needed

func _on_map_key_pressed():
	"""Handle map key press"""
	if town_map and town_map.has_method("open_map"):
		town_map.open_map()
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
	
	# Refresh navigation to include any unlocked rooms from save
	if navigation_panel and navigation_panel.has_method("refresh_dynamic_navigation"):
		navigation_panel.refresh_dynamic_navigation()
	
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
	
	# Apply responsive layout to ensure proper scaling
	call_deferred("apply_responsive_layout")

func _on_scale_075_pressed():
	"""Set UI scale to 0.75"""
	get_tree().root.content_scale_factor = 0.75
	
	# Update UIScalingManager if available
	if UIScalingManager:
		UIScalingManager.set_scaling_mode(UIScalingManager.ScalingMode.PROPORTIONAL)
	
	print("UI Scale set to: 0.75")
	update_scale_button_states(0.75)
	
	# Apply responsive layout to ensure proper scaling
	call_deferred("apply_responsive_layout")

func _on_scale_1_pressed():
	"""Set UI scale to 1.0"""
	get_tree().root.content_scale_factor = 1.0
	
	# Update UIScalingManager if available
	if UIScalingManager:
		UIScalingManager.set_scaling_mode(UIScalingManager.ScalingMode.PROPORTIONAL)
	
	print("UI Scale set to: 1.0")
	update_scale_button_states(1.0)
	
	# Apply responsive layout to ensure proper scaling
	call_deferred("apply_responsive_layout")

func _on_scale_15_pressed():
	"""Set UI scale to 1.5"""
	get_tree().root.content_scale_factor = 1.5
	
	# Update UIScalingManager if available
	if UIScalingManager:
		UIScalingManager.set_scaling_mode(UIScalingManager.ScalingMode.PROPORTIONAL)
	
	print("UI Scale set to: 1.5")
	update_scale_button_states(1.5)
	
	# Apply responsive layout to ensure proper scaling
	call_deferred("apply_responsive_layout")

func _on_scale_2_pressed():
	"""Set UI scale to 2.0"""
	get_tree().root.content_scale_factor = 2.0
	
	# Update UIScalingManager if available
	if UIScalingManager:
		UIScalingManager.set_scaling_mode(UIScalingManager.ScalingMode.PROPORTIONAL)
	
	print("UI Scale set to: 2.0")
	update_scale_button_states(2.0)
	
	# Apply responsive layout to ensure proper scaling
	call_deferred("apply_responsive_layout")

func _on_scale_3_pressed():
	"""Set UI scale to 3.0"""
	get_tree().root.content_scale_factor = 3.0
	
	# Update UIScalingManager if available
	if UIScalingManager:
		UIScalingManager.set_scaling_mode(UIScalingManager.ScalingMode.PROPORTIONAL)
	
	print("UI Scale set to: 3.0")
	update_scale_button_states(3.0)
	
	# Apply responsive layout to ensure proper scaling
	call_deferred("apply_responsive_layout")

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

func _on_inventory_button_pressed():
	"""Handle inventory button press"""
	if not GuildManager or not GuildManager.get_inventory_ui():
		return
	
	var inventory_ui = GuildManager.get_inventory_ui()
	var current_room = GuildManager.get_current_room()
	
	# Check if inventory is already visible
	if inventory_ui.visible:
		inventory_ui.visible = false
		return
	
	# Check if we're in a room that already displays inventory
	var room_instance = get_current_room_instance()
	if room_instance and room_instance.has_method("has_inventory_display"):
		if room_instance.has_inventory_display():
			return  # Don't show inventory if room already has it
	
	# Show inventory for current room
	inventory_ui.display_inventory(current_room)
	inventory_ui.visible = true
	
	# Add inventory UI to scene if not already added
	if not inventory_ui.get_parent():
		add_child(inventory_ui)

func get_current_room_instance() -> Node:
	"""Get the current room instance"""
	if room_container and room_container.get_child_count() > 0:
		return room_container.get_child(0)
	return null
#endregion
