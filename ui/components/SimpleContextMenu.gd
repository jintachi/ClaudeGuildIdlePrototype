class_name SimpleContextMenu
extends VBoxContainer

#region Signals
signal menu_item_selected(item_id: String, data: Dictionary)
signal menu_closed()
#endregion

#region Menu Data
var menu_data: Dictionary = {}
var menu_visible: bool = false
#endregion

func _ready():
	"""Initialize the simple context menu"""
	# Hide by default
	visible = false
	# Set up mouse filter to capture clicks
	mouse_filter = Control.MOUSE_FILTER_STOP

func _input(event: InputEvent):
	"""Handle input events"""
	if menu_visible and event is InputEventMouseButton:
		if event.pressed:
			# Handle both left and right clicks
			if event.button_index == MOUSE_BUTTON_LEFT:
				# Check if left click is outside the menu
				var mouse_pos = get_global_mouse_position()
				var menu_rect = get_global_rect()
				if not menu_rect.has_point(mouse_pos):
					hide_menu()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				# Right click anywhere should close the menu
				hide_menu()

func show_character_context_menu(character: Character, menu_position: Vector2):
	"""Show context menu for a character"""
	
	menu_data.clear()
	
	print("Creating simple context menu for character: ", character.character_name)
	
	var item_id = 0
	
	# Equipment menu item
	var equipment_button = create_menu_button("View Equipment", item_id)
	menu_data[item_id] = {"id": "equipment", "data": {"character": character}}
	add_child(equipment_button)
	item_id += 1
	
	# Stats menu item
	var stats_button = create_menu_button("View Stats", item_id)
	menu_data[item_id] = {"id": "stats", "data": {"character": character}}
	add_child(stats_button)
	item_id += 1
	
	# Training menu item (if available)
	if character.character_status == Character.CharacterStatus.AVAILABLE:
		var training_button = create_menu_button("Send to Training", item_id)
		menu_data[item_id] = {"id": "training", "data": {"character": character}}
		add_child(training_button)
		item_id += 1
		print("Added training menu item")
	else:
		print("Training menu item NOT added - character status: ", character.character_status)
	
	# Promotion menu item (if available)
	if character.promotion_quest_available:
		var promotion_button = create_menu_button("Start Promotion Quest", item_id)
		menu_data[item_id] = {"id": "promotion", "data": {"character": character}}
		add_child(promotion_button)
		item_id += 1
		print("Added promotion menu item")
	else:
		print("Promotion menu item NOT added - promotion_quest_available: ", character.promotion_quest_available)
	
	print("Total menu items created: ", get_child_count())
	
	# Position the menu
	global_position = menu_position
	
	# Ensure menu stays on screen
	clamp_to_screen()
	
	# Show the menu
	visible = true
	menu_visible = true
	print("Simple context menu is now visible: ", visible)

func create_menu_button(text: String, item_id: int) -> Button:
	"""Create a menu button"""
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(150, 32)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Set button style
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.25, 0.9)
	style_box.border_width_left = 1
	style_box.border_width_top = 1
	style_box.border_width_right = 1
	style_box.border_width_bottom = 1
	style_box.border_color = Color(0.4, 0.4, 0.5, 0.8)
	style_box.corner_radius_top_left = 2
	style_box.corner_radius_top_right = 2
	style_box.corner_radius_bottom_right = 2
	style_box.corner_radius_bottom_left = 2
	
	button.add_theme_stylebox_override("normal", style_box)
	
	# Hover style
	var hover_style = style_box.duplicate()
	hover_style.bg_color = Color(0.3, 0.3, 0.35, 0.9)
	button.add_theme_stylebox_override("hover", hover_style)
	
	# Pressed style
	var pressed_style = style_box.duplicate()
	pressed_style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	button.add_theme_stylebox_override("pressed", pressed_style)
	
	# Connect button signal
	button.pressed.connect(_on_button_pressed.bind(item_id))
	
	return button

func _on_button_pressed(item_id: int):
	"""Handle button press"""
	if item_id in menu_data:
		var item_data = menu_data[item_id]
		var id = item_data.get("id", "")
		var data = item_data.get("data", {})
		
		print("SimpleContextMenu button pressed - item_id: ", id, " data: ", data)
		menu_item_selected.emit(id, data)
		hide_menu()
	else:
		print("ERROR: Menu item ID not found: ", item_id)

func hide_menu():
	"""Hide the context menu"""
	visible = false
	menu_visible = false
	menu_closed.emit()
	print("Simple context menu hidden")

func clamp_to_screen():
	"""Ensure the menu stays within screen bounds"""
	var viewport_size = get_viewport().size
	var menu_size = size
	
	# Clamp X position
	if global_position.x + menu_size.x > viewport_size.x:
		global_position.x = viewport_size.x - menu_size.x - 10
	
	if global_position.x < 0:
		global_position.x = 10
	
	# Clamp Y position
	if global_position.y + menu_size.y > viewport_size.y:
		global_position.y = viewport_size.y - menu_size.y - 10
	
	if global_position.y < 0:
		global_position.y = 10
