class_name BaseRoomTemplate
extends BaseRoom

# Custom room-specific UI elements
# Add your exported variables here for UI elements
# Example:
# @export var custom_list: VBoxContainer
# @export var custom_button: Button
# @export var custom_label: Label

# Custom room state variables
# Add your room-specific variables here
# Example:
# var custom_data: Array = []
# var selected_item: CustomItem = null

func _init():
	# Set your room properties here
	room_name = "Custom Room"
	room_description = "A custom room template"
	is_unlocked = true

func setup_room_specific_ui():
	"""Setup custom room-specific UI connections"""
	# Connect to guild manager signals if needed
	if GuildManager:
		# Example connections:
		# GuildManager.some_signal.connect(_on_some_signal)
		pass
	
	# Connect your custom UI buttons
	# Example:
	# if custom_button:
	#     custom_button.pressed.connect(_on_custom_button_pressed)

func on_room_entered():
	"""Called when entering the custom room"""
	update_room_display()

func update_room_display():
	"""Update the custom room display"""
	# Implement your room-specific display logic here
	# Example:
	# update_custom_list()
	# update_custom_info()
	pass

# Add your custom methods here
# Example:
# func update_custom_list():
#     """Update the custom list display"""
#     pass
#
# func _on_custom_button_pressed():
#     """Handle custom button press"""
#     pass

func save_room_state():
	"""Save custom room state"""
	# Implement custom state saving if needed
	pass

func load_room_state():
	"""Load custom room state"""
	# Implement custom state loading if needed
	pass

