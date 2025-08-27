class_name BaseRoom
extends Control

# Base room functionality that all rooms inherit from
signal room_entered(room_name: String)
signal room_exited(room_name: String)

# Room properties
@export var room_name: String = "Base Room"
@export var room_description: String = "A basic room"
@export var room_icon: Texture2D
@export var is_unlocked: bool = true
@export var unlock_requirement: String = ""

# UI elements that all rooms should have
@export var room_container: Control
@export var back_button: Button
@export var room_title_label: Label

# Room state
var is_active: bool = false
var has_unsaved_changes: bool = false

func _ready():
	setup_base_room()
	call_deferred("setup_room_specific_ui")

func setup_base_room():
	"""Setup common room functionality"""
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	
	if room_title_label:
		room_title_label.text = room_name
	
	# Apply responsive layout
	apply_responsive_layout()

func setup_room_specific_ui():
	"""Override this in child classes to setup room-specific UI"""
	pass

func enter_room():
	"""Called when entering this room"""
	is_active = true
	room_entered.emit(room_name)
	on_room_entered()

func exit_room():
	"""Called when exiting this room"""
	is_active = false
	room_exited.emit(room_name)
	on_room_exited()

func on_room_entered():
	"""Override this in child classes for room-specific entry logic"""
	pass

func on_room_exited():
	"""Override this in child classes for room-specific exit logic"""
	pass

func update_room_display():
	"""Update the room's display - override in child classes"""
	pass

func _on_back_button_pressed():
	"""Handle back button press"""
	exit_room()
	# Signal to parent to return to main hall
	GuildManager.return_to_main_hall()

func apply_responsive_layout():
	"""Apply responsive layout to the room"""
	# Load ResponsiveLayout class if available
	var responsive_layout_script = load("res://ui/systems/ResponsiveLayout.gd")
	if responsive_layout_script:
		responsive_layout_script.convert_scene_to_responsive(self, responsive_layout_script.ConversionMode.SMART_GRID)

func can_enter_room() -> bool:
	"""Check if the room can be entered (unlocked, requirements met, etc.)"""
	return is_unlocked

func get_room_info() -> Dictionary:
	"""Get room information for display in navigation"""
	return {
		"name": room_name,
		"description": room_description,
		"icon": room_icon,
		"is_unlocked": is_unlocked,
		"unlock_requirement": unlock_requirement
	}

func save_room_state():
	"""Save room-specific state - override in child classes"""
	pass

func load_room_state():
	"""Load room-specific state - override in child classes"""
	pass
