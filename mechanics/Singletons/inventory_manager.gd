extends Node

## InventoryManager - Centralized inventory management system
## Provides singleton access to inventory functionality across all rooms
## Integrates with GuildManager for resource management and save/load

@warning_ignore_start("unused_signal")
signal inventory_changed()
signal item_added(item: InventoryItem, slot_index: int)
signal item_removed(item: InventoryItem, slot_index: int)
signal item_moved(item: InventoryItem, from_slot: int, to_slot: int)
signal inventory_upgraded(new_capacity: int)
# room_inventory_context_changed signal removed - no longer needed
@warning_ignore_restore("unused_signal")

# No longer need to preload warehouse inventory scene - it's built into WarehouseRoom

# Inventory configuration
@export var default_capacity: int = 20
@export var max_capacity: int = 100
@export var upgrade_cost_base: int = 100
@export var upgrade_cost_multiplier: float = 1.5

# Core inventory data
var inventory: Inventory

# inventory_ui removed - inventory display is now handled by WarehouseRoom


# Item database for centralized item definitions
var item_database: Dictionary = {}


func _ready():
	"""Initialize the inventory manager"""
	initialize_item_database()
	
	# Connect to game_ready signal to initialize game-dependent systems
	if SignalBus:
		SignalBus.game_ready.connect(_on_game_ready)
	
	# Connect to GuildManager signals if available
	if GuildManager and not GuildManager.room_changed.is_connected(_on_room_changed):
		GuildManager.room_changed.connect(_on_room_changed)

func _on_game_ready():
	"""Called when the game is fully initialized and ready"""
	print("InventoryManager: Game is ready, initializing inventory systems")
	initialize_inventory()

func initialize_inventory():
	"""Initialize the main inventory system"""
	inventory = Inventory.new()
	inventory.total_slots = default_capacity
	
	# Inventory display is now handled by WarehouseRoom
	
	# Add some test items for development
	add_test_items()

func initialize_item_database():
	"""Initialize the item database with predefined items"""
	# Consumables
	item_database["health_potion"] = {
		"name": "Health Potion",
		"description": "Restores 50 HP to a character",
		"type": "consumables",
		"base_value": 25,
		"value": 25,
		"max_stack": 99,
		"rarity": InventoryItem.Rarity.COMMON,
		"tags": ["consumable", "alchemy", "vendor", "healing"],
		"effects": {"heal": 50},
		"base_charges": 1
	}
	
	item_database["mana_potion"] = {
		"name": "Mana Potion", 
		"description": "Restores 30 MP to a character",
		"type": "consumables",
		"base_value": 20,
		"value": 20,
		"max_stack": 99,
		"rarity": InventoryItem.Rarity.COMMON,
		"tags": ["consumable", "alchemy", "vendor", "mana"],
		"effects": {"mana_restore": 30},
		"base_charges": 1
	}
	
	item_database["antidote"] = {
		"name": "Antidote",
		"description": "Cures poison and other ailments",
		"type": "consumables", 
		"base_value": 15,
		"value": 15,
		"max_stack": 50,
		"rarity": InventoryItem.Rarity.COMMON,
		"tags": ["consumable", "alchemy", "vendor", "cure"],
		"effects": {"cure_poison": true},
		"base_charges": 1
	}
	
	# Equipment
	item_database["iron_sword"] = {
		"name": "Iron Sword",
		"description": "A basic iron sword with decent attack power",
		"type": "equipment",
		"base_value": 100,
		"value": 100,
		"max_stack": 1,
		"rarity": InventoryItem.Rarity.COMMON,
		"equipment_slot": "mainhand",
		"tags": ["equipment", "weapon", "vendor", "crafting"],
		"stat_bonuses": {"attack_power": 10},
		"requirements": {"level": 1},
		"base_charges": 1
	}
	
	item_database["leather_armor"] = {
		"name": "Leather Armor",
		"description": "Basic leather armor providing modest protection",
		"type": "equipment",
		"base_value": 75,
		"value": 75,
		"max_stack": 1,
		"rarity": InventoryItem.Rarity.COMMON,
		"equipment_slot": "chest",
		"tags": ["equipment", "armor", "vendor", "crafting"],
		"stat_bonuses": {"defense": 8},
		"requirements": {"level": 1},
		"base_charges": 1
	}
	
	# Quest Items
	item_database["promotion_scroll"] = {
		"name": "Promotion Scroll",
		"description": "Required for character rank-up quests",
		"type": "quest_items",
		"base_value": 50,
		"value": 50,
		"max_stack": 10,
		"rarity": InventoryItem.Rarity.UNCOMMON,
		"tags": ["quest_item", "promotion", "vendor"],
		"quest_requirements": ["promotion_quest"],
		"base_charges": 1
	}
	
	# Materials
	item_database["iron_ore"] = {
		"name": "Iron Ore",
		"description": "Raw iron ore for crafting",
		"type": "materials",
		"base_value": 5,
		"value": 5,
		"max_stack": 99,
		"rarity": InventoryItem.Rarity.COMMON,
		"tags": ["material", "ore", "crafting", "vendor"],
		"crafting_uses": ["weapon_crafting", "armor_crafting"],
		"base_charges": 1
	}

# Room context initialization no longer needed

#region Core Inventory Operations

func add_item(item_id: String, quantity: int = 1) -> bool:
	"""Add an item to inventory by ID"""
	if not item_database.has(item_id):
		print("Warning: Item ID '%s' not found in database" % item_id)
		return false
	
	var item_data = item_database[item_id]
	var item = create_item_from_data(item_id, item_data, quantity)
	return add_item_direct(item)

func add_item_direct(item: InventoryItem) -> bool:
	"""Add an InventoryItem directly to inventory"""
	if not inventory:
		return false
	
	var success = inventory.add_item(item)
	if success:
		inventory_changed.emit()
		# Find the slot where the item was added
		for i in range(inventory.items.size()):
			if inventory.items[i] == item:
				item_added.emit(item, i)
				break
	
	return success

func remove_item(slot_index: int, quantity: int = 1) -> InventoryItem:
	"""Remove an item from inventory"""
	if not inventory:
		return null
	
	var item = inventory.remove_item(slot_index, quantity)
	if item:
		inventory_changed.emit()
		item_removed.emit(item, slot_index)
	
	return item

func move_item(from_slot: int, to_slot: int) -> bool:
	"""Move an item between slots"""
	if not inventory:
		return false
	
	var success = inventory.move_item(from_slot, to_slot)
	if success:
		inventory_changed.emit()
		var item = inventory.items[to_slot]
		if item:
			item_moved.emit(item, from_slot, to_slot)
	
	return success

func get_item_at_slot(slot_index: int) -> InventoryItem:
	"""Get the item at a specific slot"""
	if not inventory or slot_index < 0 or slot_index >= inventory.items.size():
		return null
	return inventory.items[slot_index]

# get_items_for_room function removed - room filtering no longer needed

func get_items_by_tags(required_tags: Array[StringName]) -> Array[InventoryItem]:
	"""Get items that have any of the required tags"""
	if not inventory:
		return []
	
	var filtered_items: Array[InventoryItem] = []
	for item in inventory.items:
		if item != null and item.has_any_tag(required_tags):
			filtered_items.append(item)
	
	return filtered_items

func get_items_by_all_tags(required_tags: Array[StringName]) -> Array[InventoryItem]:
	"""Get items that have all of the required tags"""
	if not inventory:
		return []
	
	var filtered_items: Array[InventoryItem] = []
	for item in inventory.items:
		if item != null and item.has_all_tags(required_tags):
			filtered_items.append(item)
	
	return filtered_items

#endregion

# Room context management no longer needed - inventory is handled by WarehouseRoom

#region Item Creation and Management

func create_item_from_data(item_id: String, item_data: Dictionary, quantity: int = 1) -> InventoryItem:
	"""Create an InventoryItem from database data"""
	var item = InventoryItem.new(
		item_id,
		item_data.get("name", "Unknown Item"),
		item_data.get("description", ""),
		item_data.get("type", "materials")
	)
	
	item.base_value = item_data.get("base_value", 0)
	item.quantity = quantity
	item.max_stack_size = item_data.get("max_stack", 99)
	item.rarity = item_data.get("rarity", InventoryItem.Rarity.COMMON)
	item.equipment_slot = item_data.get("equipment_slot", "")
	item.stat_bonuses = item_data.get("stat_bonuses", {})
	item.value = item_data.get("value", item.base_value)
	item.base_charges = item_data.get("base_charges", 1)
	item.current_charges = item.base_charges
	
	# Set tags
	var tags_data = item_data.get("tags", [])
	for tag in tags_data:
		item.add_tag(tag)
	
	# Store additional data
	item.set_meta("effects", item_data.get("effects", {}))
	item.set_meta("requirements", item_data.get("requirements", {}))
	item.set_meta("crafting_uses", item_data.get("crafting_uses", []))
	item.set_meta("quest_requirements", item_data.get("quest_requirements", []))
	
	return item

func create_item(item_id: String, quantity: int = 1) -> InventoryItem:
	"""Create an item by ID"""
	if not item_database.has(item_id):
		return null
	
	var item_data = item_database[item_id]
	return create_item_from_data(item_id, item_data, quantity)

#endregion

#region Inventory Upgrades and Management

func can_upgrade_inventory() -> bool:
	"""Check if inventory can be upgraded"""
	if not inventory or not GuildManager:
		return false
	
	var upgrade_cost = get_upgrade_cost()
	return GuildManager.can_afford_cost(upgrade_cost) and inventory.total_slots < max_capacity

func get_upgrade_cost() -> Dictionary:
	"""Get the cost to upgrade inventory"""
	var current_capacity = inventory.total_slots if inventory else default_capacity
	var upgrade_level = (current_capacity - default_capacity) / 5.0
	var cost = int(upgrade_cost_base * pow(upgrade_cost_multiplier, upgrade_level))
	
	return {"gold": cost}

func upgrade_inventory() -> bool:
	"""Upgrade inventory capacity"""
	if not can_upgrade_inventory():
		return false
	
	var cost = get_upgrade_cost()
	GuildManager.spend_resources(cost)
	

	inventory.upgrade_inventory()
	
	inventory_upgraded.emit(inventory.total_slots)
	
	
	return true

#endregion

#region UI Integration
# UI integration is now handled directly by WarehouseRoom
# No separate inventory UI component needed
#endregion

#region Save/Load Integration

func save_inventory_data() -> Dictionary:
	"""Save inventory data for persistence"""
	if not inventory:
		return {}
	
	return {
		"inventory": inventory.save_data()
	}

func load_inventory_data(data: Dictionary):
	"""Load inventory data from persistence"""
	if not inventory:
		initialize_inventory()
	
	if data.has("inventory"):
		inventory.load_data(data["inventory"])
	

#endregion

#region Development and Testing

func add_test_items():
	"""Add test items for development"""
	if not inventory:
		return
	
	# Add some test items
	add_item("health_potion", 5)
	add_item("mana_potion", 3)
	add_item("antidote", 2)
	add_item("iron_sword", 1)
	add_item("leather_armor", 1)
	add_item("promotion_scroll", 1)
	add_item("iron_ore", 10)

#endregion

#region Signal Handlers

func _on_room_changed(_from_room: String, _to_room: String):
	"""Handle room changes from GuildManager"""
	
	pass

#endregion
