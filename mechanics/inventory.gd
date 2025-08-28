class_name Inventory
extends RefCounted

# Inventory configuration
var total_slots: int = 10
var filled_slots: int = 0
var items: Array[InventoryItem] = []

# Room-specific item type filters
var room_item_filters: Dictionary = {
	"Main Hall": ["all"],
	"Roster": ["equipment", "consumables"],
	"Quests": ["quest_items", "consumables", "quest-specific-items"],
	"Recruitment": ["all"],
	"Training Room": ["consumables", "materials"],
	"Merchant's Guild": ["all"],
	"Blacksmith's Guild": ["equipment", "materials"],
	"Healer's Guild": ["consumables", "materials"]
}

func _init():
	"""Initialize the inventory"""
	items.resize(total_slots)
	for i in range(total_slots):
		items[i] = null

func add_item(item: InventoryItem) -> bool:
	"""Add an item to the inventory. Returns true if successful."""
	# Find first empty slot
	for i in range(items.size()):
		if items[i] == null:
			items[i] = item
			update_filled_slots()
			return true
	
	# If no empty slots, try to stack with existing items
	for i in range(items.size()):
		if items[i] != null and items[i].can_stack_with(item):
			items[i].quantity += item.quantity
			update_filled_slots()
			return true
	
	return false

func remove_item(slot_index: int, quantity: int = 1) -> InventoryItem:
	"""Remove an item from a specific slot. Returns the removed item."""
	if slot_index < 0 or slot_index >= items.size():
		return null
	
	var item = items[slot_index]
	if item == null:
		return null
	
	if quantity >= item.quantity:
		# Remove entire stack
		items[slot_index] = null
		update_filled_slots()
		return item
	else:
		# Remove partial stack
		var removed_item = item.duplicate()
		removed_item.quantity = quantity
		item.quantity -= quantity
		update_filled_slots()
		return removed_item

func move_item(from_slot: int, to_slot: int) -> bool:
	"""Move an item from one slot to another. Returns true if successful."""
	if from_slot < 0 or from_slot >= items.size() or to_slot < 0 or to_slot >= items.size():
		return false
	
	var from_item = items[from_slot]
	var to_item = items[to_slot]
	
	if from_item == null:
		return false
	
	# If destination is empty, just move the item
	if to_item == null:
		items[to_slot] = from_item
		items[from_slot] = null
		return true
	
	# If items can stack, combine them
	if from_item.can_stack_with(to_item):
		to_item.quantity += from_item.quantity
		items[from_slot] = null
		return true
	
	# If items can't stack, swap them
	items[from_slot] = to_item
	items[to_slot] = from_item
	return true

func get_items_for_room(room_name: String) -> Array[InventoryItem]:
	"""Get items filtered for a specific room"""
	var filtered_items: Array[InventoryItem] = []
	var allowed_types = room_item_filters.get(room_name, ["all"])
	
	for item in items:
		if item != null:
			if "all" in allowed_types or item.item_type in allowed_types:
				filtered_items.append(item)
	
	return filtered_items

func sort_items(sort_type: String) -> void:
	"""Sort items by the specified criteria"""
	match sort_type:
		"name_az":
			items.sort_custom(func(a, b): 
				if a == null and b == null: return false
				if a == null: return true
				if b == null: return false
				return a.item_name.to_lower() < b.item_name.to_lower()
			)
		"price_high_low":
			items.sort_custom(func(a, b): 
				if a == null and b == null: return false
				if a == null: return true
				if b == null: return false
				return a.base_value > b.base_value
			)

func upgrade_inventory() -> bool:
	"""Upgrade inventory capacity. Returns true if successful."""
	# TODO: Add cost checking logic here
	total_slots += 5
	items.resize(total_slots)
	for i in range(items.size() - 5, items.size()):
		items[i] = null
	return true

func update_filled_slots():
	"""Update the count of filled slots"""
	filled_slots = 0
	for item in items:
		if item != null:
			filled_slots += 1

func get_usage_percentage() -> float:
	"""Get the percentage of inventory used"""
	if total_slots == 0:
		return 0.0
	return float(filled_slots) / float(total_slots) * 100.0

func get_usage_color() -> Color:
	"""Get the color based on inventory usage"""
	var percentage = get_usage_percentage()
	var free_percentage = 100.0 - percentage
	
	if free_percentage > 60.0:
		return Color.WHITE
	elif free_percentage > 15.0:
		return Color.YELLOW
	else:
		return Color.RED

func save_data() -> Dictionary:
	"""Save inventory data for persistence"""
	var _save_data = {
		"total_slots": total_slots,
		"filled_slots": filled_slots,
		"items": []
	}
	
	for item in items:
		if item != null:
			_save_data["items"].append(item.save_data())
		else:
			_save_data["items"].append(null)
	
	return _save_data

func load_data(data: Dictionary):
	"""Load inventory data from persistence"""
	total_slots = data.get("total_slots", 10)
	filled_slots = data.get("filled_slots", 0)
	
	items.clear()
	items.resize(total_slots)
	
	var items_data = data.get("items", [])
	for i in range(items_data.size()):
		if items_data[i] != null:
			var item = InventoryItem.new()
			item.load_data(items_data[i])
			items[i] = item
		else:
			items[i] = null
