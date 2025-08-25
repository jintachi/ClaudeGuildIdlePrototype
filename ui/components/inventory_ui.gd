class_name InventoryUI
extends Control

# UI References
@export var inventory_grid: GridContainer
@export var description_text: RichTextLabel
@export var use_button: Button
@export var equip_button: Button
@export var drop_button: Button
@export var sort_button: Button
@export var price_sort_button: Button
@export var upgrade_button: Button
@export var close_button: Button

# State
var current_room: String = ""
var selected_item: InventoryItem = null
var selected_slot: int = -1
var drag_item: InventoryItem = null
var drag_slot: int = -1
var is_dragging: bool = false

# Inventory instance (set by GuildManager)
var inventory: Inventory = null

func _ready():
	"""Initialize the inventory UI"""
	setup_ui_connections()
	create_inventory_slots()
	update_display()

func setup_ui_connections():
	"""Setup button connections"""
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	if sort_button:
		sort_button.pressed.connect(_on_sort_button_pressed)
	if price_sort_button:
		price_sort_button.pressed.connect(_on_price_sort_button_pressed)
	if upgrade_button:
		upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	if use_button:
		use_button.pressed.connect(_on_use_button_pressed)
	if equip_button:
		equip_button.pressed.connect(_on_equip_button_pressed)
	if drop_button:
		drop_button.pressed.connect(_on_drop_button_pressed)

func create_inventory_slots():
	"""Create the inventory slot buttons"""
	if not inventory_grid:
		return
	
	# Clear existing slots
	for child in inventory_grid.get_children():
		child.queue_free()
	
	# Create slots based on inventory size
	var total_slots = inventory.total_slots if inventory else 10
	for i in range(total_slots):
		var slot_button = create_slot_button(i)
		inventory_grid.add_child(slot_button)

func create_slot_button(slot_index: int) -> Button:
	"""Create a single inventory slot button"""
	var button = Button.new()
	button.custom_minimum_size = Vector2(60, 60)
	button.flat = true
	button.name = "Slot_%d" % slot_index
	
	# Store slot index
	button.set_meta("slot_index", slot_index)
	
	# Connect signals for drag and drop
	button.gui_input.connect(func(event): _on_slot_gui_input(event, slot_index))
	
	return button

func display_inventory(room_name: String) -> Control:
	"""Display inventory for a specific room. Returns the UI element."""
	current_room = room_name
	update_display()
	return self

func update_display():
	"""Update the inventory display"""
	if not inventory:
		return
	
	# Update slot buttons
	update_slot_display()
	
	# Update selected item display
	update_item_description()
	
	# Update action buttons
	update_action_buttons()

func update_slot_display():
	"""Update the display of all inventory slots"""
	if not inventory_grid:
		return
	
	for i in range(inventory_grid.get_child_count()):
		var slot_button = inventory_grid.get_child(i)
		if slot_button is Button:
			update_slot_button(slot_button, i)

func update_slot_button(button: Button, slot_index: int):
	"""Update a single slot button"""
	if not inventory:
		return
	
	var item = inventory.items[slot_index] if slot_index < inventory.items.size() else null
	
	# Clear existing children
	for child in button.get_children():
		child.queue_free()
	
	if item != null:
		# Create item display
		var item_container = VBoxContainer.new()
		item_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.add_child(item_container)
		
		# Item icon (placeholder)
		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(40, 40)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = item.get_rarity_color()
		item_container.add_child(icon)
		
		# Item name
		var name_label = Label.new()
		name_label.text = item.item_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 8)
		name_label.modulate = item.get_rarity_color()
		item_container.add_child(name_label)
		
		# Quantity (if more than 1)
		if item.quantity > 1:
			var quantity_label = Label.new()
			quantity_label.text = "x%d" % item.quantity
			quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			quantity_label.add_theme_font_size_override("font_size", 8)
			item_container.add_child(quantity_label)
		
		# Store item reference
		button.set_meta("item", item)
	else:
		# Empty slot
		button.set_meta("item", null)
	
	# Update button appearance
	if slot_index == selected_slot:
		button.modulate = Color.YELLOW
	else:
		button.modulate = Color.WHITE

func update_item_description():
	"""Update the item description panel"""
	if not description_text:
		return
	
	if selected_item != null:
		var description = "[b]%s[/b]\n" % selected_item.item_name
		description += "[color=gray]%s[/color]\n\n" % selected_item.item_description
		description += "Type: %s\n" % selected_item.item_type.capitalize()
		description += "Value: %d gold\n" % selected_item.base_value
		description += "Quantity: %d\n" % selected_item.quantity
		
		if selected_item.stat_bonuses.size() > 0:
			description += "\n[b]Stat Bonuses:[/b]\n"
			for stat in selected_item.stat_bonuses:
				description += "%s: +%d\n" % [stat.capitalize(), selected_item.stat_bonuses[stat]]
		
		description_text.text = description
	else:
		description_text.text = "Select an item to view its description."

func update_action_buttons():
	"""Update the action buttons based on selected item"""
	if not selected_item:
		use_button.disabled = true
		equip_button.disabled = true
		drop_button.disabled = true
		return
	
	# Enable drop button for any item
	drop_button.disabled = false
	
	# Enable use button for consumables
	use_button.disabled = selected_item.item_type != "consumables"
	
	# Enable equip button for equipment
	equip_button.disabled = selected_item.item_type != "equipment"

func _on_slot_gui_input(event: InputEvent, slot_index: int):
	"""Handle input events for inventory slots"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start drag
				if selected_item and not is_dragging:
					start_drag(selected_item, selected_slot)
				# Select item
				else:
					select_slot(slot_index)
			else:
				# End drag
				if is_dragging:
					end_drag(slot_index)

func start_drag(item: InventoryItem, slot_index: int):
	"""Start dragging an item"""
	drag_item = item
	drag_slot = slot_index
	is_dragging = true
	# TODO: Create drag preview

func end_drag(target_slot: int):
	"""End dragging and move item"""
	if is_dragging and inventory:
		inventory.move_item(drag_slot, target_slot)
		update_display()
	
	is_dragging = false
	drag_item = null
	drag_slot = -1

func select_slot(slot_index: int):
	"""Select an inventory slot"""
	selected_slot = slot_index
	if inventory and slot_index < inventory.items.size():
		selected_item = inventory.items[slot_index]
	else:
		selected_item = null
	
	update_display()

# Button event handlers
func _on_close_button_pressed():
	"""Close the inventory UI"""
	visible = false

func _on_sort_button_pressed():
	"""Sort items alphabetically"""
	if inventory:
		inventory.sort_items("name_az")
		update_display()

func _on_price_sort_button_pressed():
	"""Sort items by price (high to low)"""
	if inventory:
		inventory.sort_items("price_high_low")
		update_display()

func _on_upgrade_button_pressed():
	"""Upgrade inventory capacity"""
	if inventory and inventory.upgrade_inventory():
		create_inventory_slots()
		update_display()

func _on_use_button_pressed():
	"""Use the selected item"""
	if selected_item and selected_item.item_type == "consumables":
		# TODO: Implement item usage
		print("Using item: ", selected_item.item_name)

func _on_equip_button_pressed():
	"""Equip the selected item"""
	if selected_item and selected_item.item_type == "equipment":
		# TODO: Implement equipment system
		print("Equipping item: ", selected_item.item_name)

func _on_drop_button_pressed():
	"""Drop the selected item"""
	if selected_item and inventory:
		inventory.remove_item(selected_slot)
		selected_item = null
		selected_slot = -1
		update_display()
