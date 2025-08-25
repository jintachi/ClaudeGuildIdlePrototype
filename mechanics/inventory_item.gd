class_name InventoryItem
extends RefCounted

# Item properties
var item_id: String
var item_name: String
var item_description: String
var item_type: String  # "equipment", "consumables", "materials", "quest_items"
var base_value: int
var quantity: int = 1
var max_stack_size: int = 99
var icon_path: String = ""

# Equipment-specific properties
var equipment_slot: String = ""  # "weapon", "armor", "helmet", "accessory"
var stat_bonuses: Dictionary = {}

# Item rarity
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
var rarity: Rarity = Rarity.COMMON

func _init(id: String = "", name: String = "", description: String = "", type: String = "materials"):
	item_id = id
	item_name = name
	item_description = description
	item_type = type

func can_stack_with(other_item: InventoryItem) -> bool:
	"""Check if this item can stack with another item"""
	if other_item == null:
		return false
	
	return (item_id == other_item.item_id and 
			item_type == other_item.item_type and
			quantity + other_item.quantity <= max_stack_size)

func duplicate() -> InventoryItem:
	"""Create a duplicate of this item"""
	var new_item = InventoryItem.new(item_id, item_name, item_description, item_type)
	new_item.base_value = base_value
	new_item.quantity = quantity
	new_item.max_stack_size = max_stack_size
	new_item.icon_path = icon_path
	new_item.equipment_slot = equipment_slot
	new_item.stat_bonuses = stat_bonuses.duplicate()
	new_item.rarity = rarity
	return new_item

func get_rarity_color() -> Color:
	"""Get the color associated with this item's rarity"""
	match rarity:
		Rarity.COMMON:
			return Color.WHITE
		Rarity.UNCOMMON:
			return Color.GREEN
		Rarity.RARE:
			return Color.BLUE
		Rarity.EPIC:
			return Color.PURPLE
		Rarity.LEGENDARY:
			return Color.ORANGE
		_:
			return Color.WHITE

func get_total_value() -> int:
	"""Get the total value of this item stack"""
	return base_value * quantity

func get_display_name() -> String:
	"""Get the display name with quantity if applicable"""
	if quantity > 1:
		return "%s (x%d)" % [item_name, quantity]
	return item_name

func save_data() -> Dictionary:
	"""Save item data for persistence"""
	return {
		"item_id": item_id,
		"item_name": item_name,
		"item_description": item_description,
		"item_type": item_type,
		"base_value": base_value,
		"quantity": quantity,
		"max_stack_size": max_stack_size,
		"icon_path": icon_path,
		"equipment_slot": equipment_slot,
		"stat_bonuses": stat_bonuses,
		"rarity": rarity
	}

func load_data(data: Dictionary):
	"""Load item data from persistence"""
	item_id = data.get("item_id", "")
	item_name = data.get("item_name", "")
	item_description = data.get("item_description", "")
	item_type = data.get("item_type", "materials")
	base_value = data.get("base_value", 0)
	quantity = data.get("quantity", 1)
	max_stack_size = data.get("max_stack_size", 99)
	icon_path = data.get("icon_path", "")
	equipment_slot = data.get("equipment_slot", "")
	stat_bonuses = data.get("stat_bonuses", {})
	rarity = data.get("rarity", Rarity.COMMON)
