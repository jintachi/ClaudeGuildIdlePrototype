extends Node

#region Signals
signal menu_shown()
signal menu_hidden()
#endregion

#region Preloads
const AdventurerInspectionPanel = preload("res://ui/components/AdventurerInspectionPanel.tscn")
#endregion

#region Singleton Setup
static var instance: Node
#endregion

#region Context Menu System
var context_menu_scene: PackedScene
var current_menu: Control = null  # Changed from ContextMenu to Control since ContextMenu class doesn't exist yet
#endregion

func _ready():
	"""Initialize the context menu manager"""
	instance = self
	
	# Load simple context menu scene (using VBoxContainer with buttons)
	context_menu_scene = preload("res://ui/components/SimpleContextMenu.tscn")
	
	# Set up global input handling
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent):
	"""Handle global input events"""
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT and current_menu:
			# Right click anywhere should close any open context menu
			print("Global right click detected - closing context menu")
			hide_context_menu()

func show_character_context_menu(character: Character, position: Vector2):
	"""Show context menu for a character"""
	var menu_items:Array[Dictionary]
	
	print("Creating context menu for character: ", character.character_name)
	print("Character status: ", character.character_status)
	print("Promotion quest available: ", character.promotion_quest_available)
	
	# Equipment menu item
	menu_items.append({
		"id": "equipment",
		"text": "View Equipment",
		"data": {"character": character}
	})
	print("Added equipment menu item")
	
	# Stats menu item
	menu_items.append({
		"id": "stats", 
		"text": "View Stats",
		"data": {"character": character}
	})
	print("Added stats menu item")
	
	# Training menu item (if available)
	if character.character_status == Character.CharacterStatus.AVAILABLE:
		menu_items.append({
			"id": "training",
			"text": "Send to Training",
			"data": {"character": character}
		})
		print("Added training menu item")
	else:
		print("Training menu item NOT added - character status: ", character.character_status)
	
	# Promotion menu item (if available)
	if character.promotion_quest_available:
		menu_items.append({
			"id": "promotion",
			"text": "Start Promotion Quest",
			"data": {"character": character}
		})
		print("Added promotion menu item")
	else:
		print("Promotion menu item NOT added - promotion_quest_available: ", character.promotion_quest_available)
	
	print("Total menu items created: ", menu_items.size())
	
	# Show the context menu
	show_context_menu(menu_items, position)

func show_item_context_menu(item: InventoryItem, position: Vector2):
	"""Show context menu for an inventory item"""
	var menu_items = ContextMenu.create_item_context_menu(item)
	show_context_menu(menu_items, position)

func show_context_menu(items: Array[Dictionary], position: Vector2):
	"""Show a context menu with the given items at the specified position"""
	print("ContextMenuManager.show_context_menu called with ", items.size(), " items at position: ", position)
	
	# Check if we have any items
	if items.is_empty():
		print("ERROR: No items provided to context menu")
		return
	
	# Hide any existing menu first
	if current_menu:
		print("Hiding existing context menu before creating new one...")
		hide_context_menu()
	
	# Create context menu programmatically
	print("Creating context menu programmatically...")
	var character = items[0].get("data", {}).get("character")
	if not character:
		print("ERROR: No character found in first menu item")
		return
		
	current_menu = create_context_menu_programmatically(character, position)
	print("Context menu created: ", current_menu != null)
	
	if current_menu:
		# Add to the UI layer instead of directly to scene
		# Since we're creating the menu programmatically, we need to add it directly to the UI layer
		var ui_layer = UILayerManager.get_layer()
		if ui_layer:
			ui_layer.add_child(current_menu)
		else:
			# Fallback to scene tree if UI layer not available
			get_tree().current_scene.add_child(current_menu)
		menu_shown.emit()
		print("Context menu shown and signal emitted")
	else:
		print("Failed to create context menu!")

func hide_context_menu():
	"""Hide the current context menu"""
	if current_menu:
		print("Hiding simple context menu...")
		# Remove from UI layer and cleanup
		UILayerManager.remove_from_layer(current_menu)
		current_menu.queue_free()
		current_menu = null
		menu_hidden.emit()
		print("Simple context menu hidden successfully")

func create_context_menu_programmatically(character: Character, position: Vector2) -> Control:
	"""Create a context menu programmatically without using scene files"""
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(150, 50)
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	container.global_position = position
	container.visible = true
	
	# Store character data
	container.set_meta("character", character)
	
	# Create buttons
	var equipment_button = create_menu_button("View Equipment", "equipment", character)
	var stats_button = create_menu_button("View Stats", "stats", character)
	
	container.add_child(equipment_button)
	container.add_child(stats_button)
	
	# Add training button if character is available
	if character.character_status == Character.CharacterStatus.AVAILABLE:
		var training_button = create_menu_button("Send to Training", "training", character)
		container.add_child(training_button)
		print("Added training menu item")
	else:
		print("Training menu item NOT added - character status: ", character.character_status)
	
	# Add promotion button if available
	if character.promotion_quest_available:
		var promotion_button = create_menu_button("Start Promotion Quest", "promotion", character)
		container.add_child(promotion_button)
		print("Added promotion menu item")
	else:
		print("Promotion menu item NOT added - promotion_quest_available: ", character.promotion_quest_available)
	
	print("Total menu items created: ", container.get_child_count())
	
	return container

func create_menu_button(text: String, item_id: String, character: Character) -> Button:
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
	button.pressed.connect(_on_button_pressed.bind(item_id, character))
	
	return button

func _on_button_pressed(item_id: String, character: Character):
	"""Handle button press"""
	print("Context menu button pressed - item_id: ", item_id, " character: ", character.character_name)
	_on_menu_item_selected(item_id, {"character": character})
	hide_context_menu()

func _on_menu_item_selected(item_id: String, data: Dictionary):
	"""Handle menu item selection"""
	print("Context menu item selected: ", item_id, " with data: ", data)
	
	match item_id:
		"equipment":
			print("Handling equipment menu...")
			_handle_equipment_menu(data)
		"stats":
			print("Handling stats menu...")
			_handle_stats_menu(data)
		"training":
			print("Handling training menu...")
			_handle_training_menu(data)
		"promotion":
			print("Handling promotion menu...")
			_handle_promotion_menu(data)
		"use":
			_handle_use_item_menu(data)
		"equip_to":
			_handle_equip_to_menu(data)
		"sell":
			_handle_sell_item_menu(data)
		"drop":
			_handle_drop_item_menu(data)
		"view_details":
			_handle_view_details_menu(data)

func _on_menu_closed():
	"""Handle menu closed"""
	# Just clean up the reference - don't call hide_context_menu() again
	# as that would create an infinite loop since hide_context_menu() triggers this signal
	if current_menu:
		UILayerManager.remove_from_layer(current_menu)
		current_menu = null
		menu_hidden.emit()

func _handle_equipment_menu(data: Dictionary):
	"""Handle equipment menu selection"""
	var character = data.get("character")
	print("Equipment menu handler - character: ", character)
	if character:
		print("Attempting to show equipment panel for: ", character.character_name)
		# Show the character equipment panel
		CharacterEquipmentPanel.show_for_character(character)
		print("Equipment panel call completed")
	else:
		print("No character found in equipment menu data")

func _handle_stats_menu(data: Dictionary):
	"""Handle stats menu selection"""
	var character = data.get("character")
	if character:
		print("Showing stats for: ", character.character_name)
		# Show the character inspection panel
		var panel = UILayerManager.add_modal_to_layer(AdventurerInspectionPanel)
		if panel:
			# Set the character and show the panel
			panel.inspect_character(character)
			print("Stats panel shown for: ", character.character_name)
		else:
			print("ERROR: Failed to create stats panel")

func _handle_training_menu(data: Dictionary):
	"""Handle training menu selection"""
	var character = data.get("character")
	if character:
		print("Showing training for: ", character.character_name)
		# Navigate to the training room
		GuildManager.enter_room("Training Room")
		print("Navigated to training room for: ", character.character_name)

func _handle_promotion_menu(data: Dictionary):
	"""Handle promotion menu selection"""
	var character = data.get("character")
	if character:
		# Show promotion quest (placeholder)
		print("Showing promotion quest for: ", character.character_name)

func _handle_use_item_menu(data: Dictionary):
	"""Handle use item menu selection"""
	var item = data.get("item")
	if item:
		# Use the item (placeholder)
		print("Using item: ", item.item_name)

func _handle_equip_to_menu(data: Dictionary):
	"""Handle equip to menu selection"""
	var item = data.get("item")
	if item:
		# Show character selection for equipment (placeholder)
		print("Equip to character selection for: ", item.item_name)
		# TODO: Implement character selection UI

func _handle_sell_item_menu(data: Dictionary):
	"""Handle sell item menu selection"""
	var item = data.get("item")
	if item:
		# Sell the item (placeholder)
		print("Selling item: ", item.item_name)

func _handle_drop_item_menu(data: Dictionary):
	"""Handle drop item menu selection"""
	var item = data.get("item")
	if item:
		# Drop the item (placeholder)
		print("Dropping item: ", item.item_name)

func _handle_view_details_menu(data: Dictionary):
	"""Handle view details menu selection"""
	var item = data.get("item")
	if item:
		# Show detailed item information (placeholder)
		print("Viewing details for: ", item.item_name)

#region Static Helper Functions
static func show_character_menu(character: Character, position: Vector2):
	"""Static helper to show character context menu"""
	if instance:
		instance.show_character_context_menu(character, position)

static func show_item_menu(item: InventoryItem, position: Vector2):
	"""Static helper to show item context menu"""
	if instance:
		instance.show_item_context_menu(item, position)

static func hide_menu():
	"""Static helper to hide context menu"""
	if instance:
		instance.hide_context_menu()
#endregion
