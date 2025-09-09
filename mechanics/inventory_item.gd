class_name InventoryItem
extends RefCounted

# Core Item Properties
var item_id: String
var item_name: String
var item_description: String
var item_type: String  # "equipment", "consumables", "materials", "quest_items", "valuables"
var base_value: int
var quantity: int = 1
var max_stack_size: int = 99
var icon_path: String = ""

# Equipment-specific properties
var equipment_slot: String = ""  # "weapon", "armor", "helmet", "accessory", "shield", "boots"
var stat_bonuses: Dictionary = {}
var durability: int = 100
var max_durability: int = 100

# Item rarity and quality
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
var rarity: Rarity = Rarity.COMMON

# Item requirements and restrictions
var level_requirement: int = 0
var class_requirement: String = ""  # "warrior", "mage", "rogue", "healer", etc.
var rank_requirement: String = ""   # "F", "E", "D", "C", "B", "A", "S", "SS", "SSS"

# Item effects and special properties
var effects: Dictionary = {}  # Runtime effects when used
var passive_effects: Dictionary = {}  # Always active effects
var cooldown_time: float = 0.0  # Cooldown between uses
var last_used_time: float = 0.0  # When this item was last used

# Item metadata
var is_quest_item: bool = false
var is_tradeable: bool = true
var is_droppable: bool = true
var is_sellable: bool = true
var vendor_price_multiplier: float = 0.5  # How much vendors pay for this item

# Crafting and enhancement
var crafting_materials: Array[String] = []  # Materials needed to craft this item
var enhancement_level: int = 0
var max_enhancement_level: int = 10
var enhancement_bonuses: Dictionary = {}  # Bonuses from enhancement

# Item tags for filtering and categorization (flexible tag system)
var tags: Array[StringName] = []  # e.g., ["consumable", "alchemy", "vendor", "crafting"]

# Item value for trading and economy
@export var value: int = 0  # Base cost for testing and trading

# Consumable charges system
var base_charges: int = 1  # Base number of charges (1 = single use, -1 = infinite)
var current_charges: int = 1  # Current remaining charges

func _init(id: String = "", name: String = "", description: String = "", type: String = "materials"):
	item_id = id
	item_name = name
	item_description = description
	item_type = type

func can_stack_with(other_item: InventoryItem) -> bool:
	"""Check if this item can stack with another item"""
	if other_item == null:
		return false
	
	# Items with charges cannot stack (they occupy unique slots)
	if base_charges != 1 or other_item.base_charges != 1:
		return false
	
	# Equipment and quest items generally don't stack
	if item_type in ["equipment", "quest_items"]:
		return false
	
	# Items can only stack if they have the same ID, type, and enhancement level
	return (item_id == other_item.item_id and 
			item_type == other_item.item_type and
			enhancement_level == other_item.enhancement_level and
			quantity + other_item.quantity <= max_stack_size)

func duplicate() -> InventoryItem:
	"""Create a duplicate of this item"""
	var new_item = InventoryItem.new(item_id, item_name, item_description, item_type)
	
	# Copy all properties
	new_item.base_value = base_value
	new_item.quantity = quantity
	new_item.max_stack_size = max_stack_size
	new_item.icon_path = icon_path
	new_item.equipment_slot = equipment_slot
	new_item.stat_bonuses = stat_bonuses.duplicate()
	new_item.rarity = rarity
	
	# Copy new properties
	new_item.durability = durability
	new_item.max_durability = max_durability
	new_item.level_requirement = level_requirement
	new_item.class_requirement = class_requirement
	new_item.rank_requirement = rank_requirement
	new_item.effects = effects.duplicate()
	new_item.passive_effects = passive_effects.duplicate()
	new_item.cooldown_time = cooldown_time
	new_item.last_used_time = last_used_time
	new_item.is_quest_item = is_quest_item
	new_item.is_tradeable = is_tradeable
	new_item.is_droppable = is_droppable
	new_item.is_sellable = is_sellable
	new_item.vendor_price_multiplier = vendor_price_multiplier
	new_item.crafting_materials = crafting_materials.duplicate()
	new_item.enhancement_level = enhancement_level
	new_item.max_enhancement_level = max_enhancement_level
	new_item.enhancement_bonuses = enhancement_bonuses.duplicate()
	new_item.tags = tags.duplicate()
	new_item.value = value
	new_item.base_charges = base_charges
	new_item.current_charges = current_charges
	
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
	var display_name = item_name
	
	# Add enhancement level if enhanced
	if enhancement_level > 0:
		display_name = "+%d %s" % [enhancement_level, display_name]
	
	# Add quantity if stackable
	if quantity > 1 and item_type not in ["equipment", "quest_items"]:
		display_name = "%s (x%d)" % [display_name, quantity]
	
	return display_name

func get_enhanced_value() -> int:
	"""Get the item value including enhancement bonuses"""
	var enhanced_value = base_value
	if enhancement_level > 0:
		enhanced_value = int(enhanced_value * (1.0 + (enhancement_level * 0.1)))
	return enhanced_value

func get_vendor_price() -> int:
	"""Get the price vendors will pay for this item"""
	return int(get_enhanced_value() * vendor_price_multiplier)

func can_use() -> bool:
	"""Check if this item can be used (not on cooldown)"""
	if cooldown_time <= 0.0:
		return true
	
	var current_time = Time.get_unix_time_from_system()
	return (current_time - last_used_time) >= cooldown_time

func use_item() -> bool:
	"""Mark item as used and return true if successful"""
	if not can_use():
		return false
	
	last_used_time = Time.get_unix_time_from_system()
	return true

func meets_requirements(character: Character) -> bool:
	"""Check if a character meets the requirements to use this item"""
	if character == null:
		return false
	
	# Check level requirement
	if level_requirement > 0 and character.level < level_requirement:
		return false
	
	# Check class requirement (convert string to enum if needed)
	if class_requirement != "":
		var required_class = Character.CharacterClass.get(class_requirement.to_upper(), -1)
		if required_class != -1 and character.character_class != required_class:
			return false
	
	# Check rank requirement (convert string to enum if needed)
	if rank_requirement != "":
		var required_rank = Character.Rank.get(rank_requirement.to_upper(), -1)
		if required_rank != -1 and character.rank != required_rank:
			return false
	
	return true

func get_durability_percentage() -> float:
	"""Get the durability as a percentage"""
	if max_durability <= 0:
		return 100.0
	return float(durability) / float(max_durability) * 100.0

func is_broken() -> bool:
	"""Check if the item is broken (durability at 0)"""
	return durability <= 0

func repair_item(repair_amount: int = -1) -> bool:
	"""Repair the item. If repair_amount is -1, repair to full"""
	if repair_amount == -1:
		durability = max_durability
	else:
		durability = min(durability + repair_amount, max_durability)
	return true

func damage_item(damage_amount: int = 1) -> bool:
	"""Damage the item (reduce durability)"""
	durability = max(durability - damage_amount, 0)
	return is_broken()

func has_tag(tag: String) -> bool:
	"""Check if the item has a specific tag"""
	return tag in tags

func add_tag(tag: String):
	"""Add a tag to the item"""
	if not has_tag(tag):
		tags.append(tag)

func remove_tag(tag: String):
	"""Remove a tag from the item"""
	tags.erase(tag)

func has_any_tag(required_tags: Array[StringName]) -> bool:
	"""Check if the item has any of the required tags"""
	for tag in required_tags:
		if has_tag(tag):
			return true
	return false

func has_all_tags(required_tags: Array[StringName]) -> bool:
	"""Check if the item has all of the required tags"""
	for tag in required_tags:
		if not has_tag(tag):
			return false
	return true

func get_charge_display() -> String:
	"""Get the charge display string for UI"""
	if base_charges == 1:
		return ""  # Single use items don't display charges
	elif base_charges == -1:
		return ""  # Infinite use items don't display charges
	else:
		return "%d/%d" % [current_charges, base_charges]

func use_charge() -> bool:
	"""Use a charge from the item. Returns true if successful."""
	if base_charges == -1:
		return true  # Infinite charges
	elif current_charges > 0:
		current_charges -= 1
		return true
	return false

func restore_charges(amount: int = -1) -> bool:
	"""Restore charges to the item. If amount is -1, restore to full."""
	if base_charges == -1:
		return true  # Infinite charges
	elif amount == -1:
		current_charges = base_charges
		return true
	else:
		current_charges = min(base_charges, current_charges + amount)
		return true

func is_fully_charged() -> bool:
	"""Check if the item is fully charged"""
	return base_charges == -1 or current_charges >= base_charges

func get_effective_value() -> int:
	"""Get the effective value including enhancement bonuses"""
	if value > 0:
		return value
	return get_enhanced_value()

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
		"rarity": rarity,
		"durability": durability,
		"max_durability": max_durability,
		"level_requirement": level_requirement,
		"class_requirement": class_requirement,
		"rank_requirement": rank_requirement,
		"effects": effects,
		"passive_effects": passive_effects,
		"cooldown_time": cooldown_time,
		"last_used_time": last_used_time,
		"is_quest_item": is_quest_item,
		"is_tradeable": is_tradeable,
		"is_droppable": is_droppable,
		"is_sellable": is_sellable,
		"vendor_price_multiplier": vendor_price_multiplier,
		"crafting_materials": crafting_materials,
		"enhancement_level": enhancement_level,
		"max_enhancement_level": max_enhancement_level,
		"enhancement_bonuses": enhancement_bonuses,
		"tags": tags,
		"value": value,
		"base_charges": base_charges,
		"current_charges": current_charges
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
	
	# Load new properties with defaults
	durability = data.get("durability", 100)
	max_durability = data.get("max_durability", 100)
	level_requirement = data.get("level_requirement", 0)
	class_requirement = data.get("class_requirement", "")
	rank_requirement = data.get("rank_requirement", "")
	effects = data.get("effects", {})
	passive_effects = data.get("passive_effects", {})
	cooldown_time = data.get("cooldown_time", 0.0)
	last_used_time = data.get("last_used_time", 0.0)
	is_quest_item = data.get("is_quest_item", false)
	is_tradeable = data.get("is_tradeable", true)
	is_droppable = data.get("is_droppable", true)
	is_sellable = data.get("is_sellable", true)
	vendor_price_multiplier = data.get("vendor_price_multiplier", 0.5)
	var temp_crafting_materials = data.get("crafting_materials", [])
	for material in temp_crafting_materials:
		crafting_materials.append(material)
	enhancement_level = data.get("enhancement_level", 0)
	max_enhancement_level = data.get("max_enhancement_level", 10)
	enhancement_bonuses = data.get("enhancement_bonuses", {})
	var temp_tags = data.get("tags", [])
	for tag in temp_tags:
		tags.append(tag)
	value = data.get("value", 0)
	base_charges = data.get("base_charges", 1)
	current_charges = data.get("current_charges", 1)
