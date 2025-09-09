class_name WarehouseRoom
extends BaseRoom

# Warehouse-specific UI elements
@export var warehouse_stats_panel: VBoxContainer
@export var upgrade_button: Button
@export var capacity_label: Label
@export var usage_label: Label

# Inventory UI elements
@export var search_bar: LineEdit
@export var tab_container: TabContainer
@export var item_grid: GridContainer
@export var equipment_grid: GridContainer
@export var consumables_grid: GridContainer
@export var materials_grid: GridContainer
@export var key_items_grid: GridContainer
@export var valuables_grid: GridContainer

# Warehouse state
var warehouse_level: int = 1
var max_capacity: int = 50
var current_usage: int = 0

func _init():
	room_name = "Warehouse"
	room_description = "Store and manage your guild's items and equipment"
	is_unlocked = false  # Start locked - requires unlock
	unlock_requirement = "Complete 10 quests and have 1000 gold"

func setup_room_specific_ui():
	"""Setup warehouse-specific UI connections"""
	# Connect upgrade button
	if upgrade_button:
		upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	
	# Connect search bar
	if search_bar:
		search_bar.text_changed.connect(_on_search_text_changed)
	
	# Connect to inventory manager signals
	if InventoryManager:
		InventoryManager.item_added.connect(_on_item_added)
		InventoryManager.item_removed.connect(_on_item_removed)
	
	# Setup inventory UI
	setup_inventory_ui()

func setup_inventory_ui():
	"""Setup the inventory UI elements"""
	if not InventoryManager or not InventoryManager.inventory:
		return
	
	# Clear existing items
	clear_all_grids()
	
	# Populate inventory
	update_inventory_display()

func clear_all_grids():
	"""Clear all inventory grids"""
	var grids = [item_grid, equipment_grid, consumables_grid, materials_grid, key_items_grid, valuables_grid]
	for grid in grids:
		if grid:
			for child in grid.get_children():
				child.queue_free()

func update_inventory_display():
	"""Update the inventory display"""
	if not InventoryManager or not InventoryManager.inventory:
		return
	
	clear_all_grids()
	
	# Get search filter
	var search_text = search_bar.text.to_lower() if search_bar else ""
	
	# Populate all grids
	for item in InventoryManager.inventory.items:
		if item == null:
			continue
		
		# Apply search filter
		if search_text != "" and not item.item_name.to_lower().contains(search_text):
			continue
		
		# Create item slot
		var item_slot = create_item_slot(item)
		
		# Add to appropriate grid based on item type
		match item.item_type:
			"equipment":
				if equipment_grid:
					equipment_grid.add_child(item_slot)
			"consumables":
				if consumables_grid:
					consumables_grid.add_child(item_slot)
			"materials":
				if materials_grid:
					materials_grid.add_child(item_slot)
			"quest_items":
				if key_items_grid:
					key_items_grid.add_child(item_slot)
			"valuables":
				if valuables_grid:
					valuables_grid.add_child(item_slot)
		
		# Always add to "All Items" grid
		if item_grid:
			var all_items_slot = create_item_slot(item)
			item_grid.add_child(all_items_slot)

func create_item_slot(item: InventoryItem) -> Control:
	"""Create an item slot UI element"""
	var slot = Button.new()
	slot.custom_minimum_size = Vector2(64, 64)
	slot.text = item.item_name + "\n" + str(item.quantity)
	slot.tooltip_text = item.description
	
	# Connect right-click for context menu
	slot.gui_input.connect(_on_item_slot_gui_input.bind(item))
	
	return slot

func _on_item_slot_gui_input(event: InputEvent, item: InventoryItem):
	"""Handle item slot input events"""
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		# Show context menu
		if ContextMenuManager:
			ContextMenuManager.show_item_context_menu(item, event.global_position)

func _on_search_text_changed(_new_text: String):
	"""Handle search text changes"""
	update_inventory_display()

func on_room_entered():
	"""Called when entering the warehouse room"""
	update_warehouse_display()
	update_warehouse_stats()
	update_inventory_display()

func on_room_exited():
	"""Called when exiting the warehouse room"""
	# Save any changes if needed
	if has_unsaved_changes:
		save_warehouse_state()

func update_warehouse_display():
	"""Update the warehouse inventory display"""
	if InventoryManager:
		update_inventory_display()

func update_warehouse_stats():
	"""Update warehouse statistics display"""
	if not InventoryManager or not InventoryManager.inventory:
		return
	
	var inventory = InventoryManager.inventory
	current_usage = inventory.filled_slots
	max_capacity = inventory.total_slots
	
	# Update capacity label
	if capacity_label:
		capacity_label.text = "Capacity: %d / %d" % [current_usage, max_capacity]
	
	# Update usage label with color coding
	if usage_label:
		var usage_percentage = float(current_usage) / float(max_capacity) * 100.0
		usage_label.text = "Usage: %.1f%%" % usage_percentage
		
		# Color code based on usage
		if usage_percentage > 90:
			usage_label.modulate = Color.RED
		elif usage_percentage > 70:
			usage_label.modulate = Color.YELLOW
		else:
			usage_label.modulate = Color.WHITE
	
	# Update upgrade button
	if upgrade_button:
		var upgrade_cost = calculate_upgrade_cost()
		upgrade_button.text = "Upgrade Warehouse (%d gold)" % upgrade_cost
		upgrade_button.disabled = not can_upgrade_warehouse()

func calculate_upgrade_cost() -> int:
	"""Calculate the cost to upgrade the warehouse"""
	# Base cost increases with level
	return 500 + (warehouse_level * 250)

func can_upgrade_warehouse() -> bool:
	"""Check if warehouse can be upgraded"""
	if not GuildManager:
		return false
	
	var upgrade_cost = calculate_upgrade_cost()
	var current_gold = GuildManager.get_guild_status_summary().resources.gold
	
	return current_gold >= upgrade_cost

func _on_upgrade_button_pressed():
	"""Handle warehouse upgrade button press"""
	if not can_upgrade_warehouse():
		print("Cannot upgrade warehouse - insufficient funds")
		return
	
	var upgrade_cost = calculate_upgrade_cost()
	
	# Deduct gold
	GuildManager.get_guild_status_summary().resources.gold -= upgrade_cost
	
	# Upgrade warehouse
	warehouse_level += 1
	max_capacity += 10  # Add 10 slots per upgrade
	
	# Update inventory capacity
	if InventoryManager and InventoryManager.inventory:
		InventoryManager.inventory.total_slots = max_capacity
		InventoryManager.inventory.items.resize(max_capacity)
	
	# Update display
	update_warehouse_stats()
	update_warehouse_display()
	
	# Show upgrade notification
	# TODO: Add notification system integration
	print("Warehouse upgraded to level %d!" % warehouse_level)
	
	print("Warehouse upgraded to level %d, new capacity: %d" % [warehouse_level, max_capacity])

func _on_item_added(_item: InventoryItem):
	"""Handle item being added to inventory"""
	update_warehouse_stats()
	has_unsaved_changes = true

func _on_item_removed(_item: InventoryItem):
	"""Handle item being removed from inventory"""
	update_warehouse_stats()
	has_unsaved_changes = true

func save_warehouse_state():
	"""Save warehouse state"""
	# This would save warehouse level, capacity, etc.
	# For now, just mark as saved
	has_unsaved_changes = false

func get_warehouse_info() -> Dictionary:
	"""Get warehouse information for display"""
	return {
		"level": warehouse_level,
		"capacity": max_capacity,
		"usage": current_usage,
		"upgrade_cost": calculate_upgrade_cost(),
		"can_upgrade": can_upgrade_warehouse()
	}

#region Static Helper Functions
static func check_unlock_requirements() -> bool:
	"""Check if warehouse unlock requirements are met"""
	if not GuildManager:
		return false
	
	var guild_status = GuildManager.get_guild_status_summary()
	var completed_quests = GuildManager.get_completed_quest_count()
	
	# Require 10 completed quests and 1000 gold
	return completed_quests >= 10 and guild_status.resources.gold >= 1000

static func get_unlock_description() -> String:
	"""Get description of unlock requirements"""
	return "Complete 10 quests and have 1000 gold to unlock the Warehouse"
#endregion
