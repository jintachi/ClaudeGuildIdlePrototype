class_name MerchantsGuildRoom
extends BaseRoom

## Merchant's Guild Room
## Handles trading, shopping, and trade contracts

# UI elements
@export var shop_items_panel: VBoxContainer
@export var player_inventory_panel: VBoxContainer
@export var trade_contracts_panel: VBoxContainer
@export var gold_display: Label

# Mock data for shop items
var shop_items = [
	{"name": "Iron Sword", "type": "weapon", "price": 50, "description": "A sturdy iron sword"},
	{"name": "Leather Armor", "type": "armor", "price": 40, "description": "Basic leather protection"},
	{"name": "Health Potion", "type": "consumable", "price": 15, "description": "Restores health"},
	{"name": "Magic Scroll", "type": "consumable", "price": 25, "description": "Casts a magic spell"}
]

# Mock trade contracts
var trade_contracts = [
	{"name": "Grain Delivery", "reward": 100, "description": "Deliver grain to neighboring town"},
	{"name": "Rare Gems", "reward": 200, "description": "Find and deliver rare gemstones"},
	{"name": "Monster Parts", "reward": 150, "description": "Collect parts from defeated monsters"}
]

func _init():
	room_name = "Merchant's Guild"
	room_description = "Trade goods, buy equipment, and manage contracts"
	is_unlocked = true

func setup_room_specific_ui():
	"""Setup merchant guild specific UI connections"""
	# This room is currently a placeholder
	pass

func on_room_entered():
	"""Called when entering the merchant's guild"""
	update_room_display()

func update_room_display():
	"""Update the merchant's guild display"""
	update_gold_display()
	update_shop_items()
	update_inventory_display()
	update_trade_contracts()

func update_gold_display():
	"""Update the gold display"""
	if not gold_display or not GuildManager:
		return
	
	var resources = GuildManager.get_guild_status_summary().resources
	gold_display.text = "Gold: %d" % resources.gold

func update_shop_items():
	"""Update the shop items display"""
	if not shop_items_panel:
		return
	
	# Clear existing items
	for child in shop_items_panel.get_children():
		child.queue_free()
	
	# Add shop items
	for item in shop_items:
		var item_panel = create_shop_item_panel(item)
		shop_items_panel.add_child(item_panel)

func update_inventory_display():
	"""Update the guild inventory display"""
	if not player_inventory_panel:
		return
	
	# Clear existing items
	for child in player_inventory_panel.get_children():
		child.queue_free()
	
	# Placeholder inventory items
	var inventory_label = Label.new()
	inventory_label.text = "Inventory system coming soon..."
	inventory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_inventory_panel.add_child(inventory_label)

func update_trade_contracts():
	"""Update the trade contracts display"""
	if not trade_contracts_panel:
		return
	
	# Clear existing contracts
	for child in trade_contracts_panel.get_children():
		child.queue_free()
	
	# Add trade contracts
	for contract in trade_contracts:
		var contract_panel = create_contract_panel(contract)
		trade_contracts_panel.add_child(contract_panel)

func create_shop_item_panel(item: Dictionary) -> Control:
	"""Create a panel for a shop item"""
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(250, 80)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	
	# Item header with name and price
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var name_label = Label.new()
	name_label.text = item.name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	
	var price_label = Label.new()
	price_label.text = "%d gold" % item.price
	price_label.add_theme_color_override("font_color", Color.YELLOW)
	header.add_child(price_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = item.description
	desc_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(desc_label)
	
	# Buy button
	var buy_button = Button.new()
	buy_button.text = "Buy"
	buy_button.pressed.connect(_on_buy_item.bind(item))
	vbox.add_child(buy_button)
	
	return panel

func create_contract_panel(contract: Dictionary) -> Control:
	"""Create a panel for a trade contract"""
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(250, 100)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	
	# Contract header with name and reward
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var name_label = Label.new()
	name_label.text = contract.name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	
	var reward_label = Label.new()
	reward_label.text = "%d gold" % contract.reward
	reward_label.add_theme_color_override("font_color", Color.GREEN)
	header.add_child(reward_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = contract.description
	desc_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(desc_label)
	
	# Accept button
	var accept_button = Button.new()
	accept_button.text = "Accept Contract"
	accept_button.pressed.connect(_on_accept_contract.bind(contract))
	vbox.add_child(accept_button)
	
	return panel

func _on_buy_item(item: Dictionary):
	"""Handle buying an item"""
	print("Attempting to buy: ", item.name, " for ", item.price, " gold")
	# TODO: Implement actual purchasing logic
	# Check if player has enough gold
	# Deduct gold and add item to inventory

func _on_accept_contract(contract: Dictionary):
	"""Handle accepting a trade contract"""
	print("Accepting contract: ", contract.name)
	# TODO: Implement contract system
	# Add contract to active contracts
	# Remove from available contracts
