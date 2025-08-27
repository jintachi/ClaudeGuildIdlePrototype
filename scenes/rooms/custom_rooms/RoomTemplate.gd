class_name RoomTemplate
extends Resource

# Room template configuration
@export var template_name: String = "Base Room Template"
@export var room_name: String = "Custom Room"
@export var room_description: String = "A custom room created from template"
@export var is_unlocked: bool = true

# UI structure configuration
@export var has_top_bar: bool = true
@export var has_header: bool = true
@export var has_left_panel: bool = true
@export var has_right_panel: bool = true
@export var has_bottom_panel: bool = true

# Panel labels
@export var header_label: String = "Room Header"
@export var left_panel_label: String = "Left Panel"
@export var right_panel_label: String = "Right Panel"
@export var action_button_text: String = "Action Button"

# Custom properties that can be overridden
@export var custom_properties: Dictionary = {}

# Script template to use (optional)
@export var script_template_path: String = "res://scenes/rooms/custom_rooms/BaseRoomTemplate.gd"

# Theme to apply
@export var theme_path: String = "res://theme.tres"

func get_room_info() -> Dictionary:
	"""Get room information for display"""
	return {
		"name": room_name,
		"description": room_description,
		"unlocked": is_unlocked,
		"template": template_name
	}

func create_room_instance() -> BaseRoom:
	"""Create a room instance from this template"""
	# Load the base room scene
	var base_room_scene = preload("res://scenes/rooms/custom_rooms/BaseRoomTemplate.tscn")
	var room_instance = base_room_scene.instantiate()
	
	if room_instance is BaseRoom:
		# Apply template properties
		room_instance.room_name = room_name
		room_instance.room_description = room_description
		room_instance.is_unlocked = is_unlocked
		
		# Apply custom properties
		for key in custom_properties:
			if room_instance.has_method("set_" + key):
				room_instance.call("set_" + key, custom_properties[key])
			elif key in room_instance:
				room_instance.set(key, custom_properties[key])
		
		# Update UI labels if they exist
		_update_ui_labels(room_instance)
		
		return room_instance
	
	return null

func _update_ui_labels(room_instance: BaseRoom):
	"""Update UI labels based on template configuration"""
	# Update header label
	var header_label_node = room_instance.get_node_or_null("RoomContainer/Header/HeaderLabel")
	if header_label_node and header_label_node is Label:
		header_label_node.text = header_label
	
	# Update left panel label
	var left_panel_label_node = room_instance.get_node_or_null("RoomContainer/MainContent/LeftPanel/LeftPanelLabel")
	if left_panel_label_node and left_panel_label_node is Label:
		left_panel_label_node.text = left_panel_label
	
	# Update right panel label
	var right_panel_label_node = room_instance.get_node_or_null("RoomContainer/MainContent/RightPanel/RightPanelLabel")
	if right_panel_label_node and right_panel_label_node is Label:
		right_panel_label_node.text = right_panel_label
	
	# Update action button text
	var action_button_node = room_instance.get_node_or_null("RoomContainer/BottomPanel/ActionButton")
	if action_button_node and action_button_node is Button:
		action_button_node.text = action_button_text
	
	# Update room title
	var room_title_node = room_instance.get_node_or_null("TopBar/RoomTitle")
	if room_title_node and room_title_node is Label:
		room_title_node.text = room_name

