class_name ContextMenu
extends Panel

#region Signals
signal menu_item_selected(item_id: String, data: Dictionary)
signal menu_closed()
#endregion


#region Menu Data
var menu_items: Array[Dictionary] = []
var menu_visible: bool = false
#endregion

#region UI References
@onready var menu_items_container: VBoxContainer = $VBoxContainer/MenuItems
#endregion

func _ready():
	"""Initialize the context menu"""
	# Hide by default
	visible = false
	# Set up mouse filter to capture clicks
	mouse_filter = Control.MOUSE_FILTER_STOP
	print("ContextMenu called - mouse_filter set to: ", mouse_filter)

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

func show_menu(items: Array[Dictionary], menu_position: Vector2):
	"""Show the context menu with the given items at the specified position"""
	# Set up mouse filter to capture clicks
	mouse_filter = Control.MOUSE_FILTER_STOP
	print("ContextMenu called - mouse_filter set to: ", mouse_filter)

	await get_tree().process_frame

	print("ContextMenu.show_menu called with ", items.size(), " items")
	menu_items = items
	clear_menu_items()
	create_menu_items()

	# Position the menu
	global_position = menu_position

	# Ensure menu stays on screen
	clamp_to_screen()

	# Show the menu
	visible = true
	menu_visible = true

	print("ContextMenu is now visible: ", visible)

func hide_menu():
	"""Hide the context menu"""
	visible = false
	menu_visible = false
	# Set up mouse filter to capture clicks
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	print("ContextMenu called - mouse_filter set to: ", mouse_filter)
	menu_closed.emit()

func clear_menu_items():
	"""Clear all menu items"""
	for child in menu_items_container.get_children():
		child.queue_free()

func create_menu_items():
	"""Create menu items from the menu_items array"""
	print("ContextMenu.create_menu_items called with ", menu_items.size(), " items")
	for item in menu_items:
		print("Creating button for item: ", item.get("text", "Unknown"))
		var button = create_menu_button(item)
		menu_items_container.add_child(button)
		print("Button added to container")
	print("All menu items created")

func create_menu_button(item_data: Dictionary) -> Button:
	"""Create a menu button for the given item data"""
	var button = Button.new()
	button.text = item_data.get("text", "Menu Item")
	button.custom_minimum_size = Vector2(150, 32)  # Slightly larger for better clickability
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Ensure buttons fill the container width
	print("Created button: ", button.text, " with mouse_filter: ", button.mouse_filter)

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
	
	# Connect button signal with error handling
	print("Connecting button signal for: ", item_data.get("text", "Unknown"))
	var connection_result = button.pressed.connect(_on_menu_button_pressed.bind(item_data))
	if connection_result != OK:
		print("ERROR: Failed to connect button signal for: ", button.text)
	else:
		print("Button signal connected successfully")
	
	return button

func _on_menu_button_pressed(item_data: Dictionary):
	"""Handle menu button press"""
	var item_id = item_data.get("id", "")
	var data = item_data.get("data", {})
	
	print("ContextMenu button pressed - item_id: ", item_id, " data: ", data)
	menu_item_selected.emit(item_id, data)
	hide_menu()

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

#region Static Helper Functions
static func create_character_context_menu(character: Character) -> Array[Dictionary]:
	"""Create context menu items for a character"""
	var items = []
	
	# Equipment menu item
	items.append({
		"id": "equipment",
		"text": "View Equipment",
		"data": {"character": character}
	})
	
	# Stats menu item
	items.append({
		"id": "stats",
		"text": "View Stats",
		"data": {"character": character}
	})
	
	# Training menu item (if available)
	if character.training_potential > 0:
		items.append({
			"id": "training",
			"text": "Training (%d potential)" % character.training_potential,
			"data": {"character": character}
		})
	
	# Promotion menu item (if available)
	if character.promotion_quest_available:
		items.append({
			"id": "promotion",
			"text": "Promotion Quest",
			"data": {"character": character}
		})
	
	return items

static func create_item_context_menu(item: InventoryItem) -> Array[Dictionary]:
	"""Create context menu items for an inventory item"""
	var items = []
	
	# Use item (for consumables)
	if item.item_type == "consumables":
		items.append({
			"id": "use",
			"text": "Use Item",
			"data": {"item": item}
		})
	
	# Equip item (for equipment) - show "Equip To..." option
	if item.item_type == "equipment":
		items.append({
			"id": "equip_to",
			"text": "Equip To...",
			"data": {"item": item}
		})
	
	# Sell item (if sellable)
	if item.is_sellable:
		items.append({
			"id": "sell",
			"text": "Sell Item (%d gold)" % item.get_effective_value(),
			"data": {"item": item}
		})
	
	# Drop item (if droppable)
	if item.is_droppable:
		items.append({
			"id": "drop",
			"text": "Drop Item",
			"data": {"item": item}
		})
	
	# View details (for quest items and valuables)
	if item.item_type in ["quest_items", "valuables"]:
		items.append({
			"id": "view_details",
			"text": "View Details",
			"data": {"item": item}
		})
	
	return items
#endregion
