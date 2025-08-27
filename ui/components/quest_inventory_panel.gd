class_name QuestInventoryPanel
extends Control

# UI References
@export var inventory_column: VBoxContainer
@export var party_inventory_column: VBoxContainer
@export var close_button: Button

# Internal references
var inventory_grid: GridContainer
var party_inventory_grid: GridContainer
var total_cost_label: Label
var confirm_button: Button

# State
var current_quest: Quest = null
var party_inventory: Array[InventoryItem] = []
var inventory: Inventory = null

# Signals
signal items_confirmed(items: Array[InventoryItem], total_cost: int)
signal panel_closed()

func _ready():
	"""Initialize the quest inventory panel"""
	setup_ui_references()
	setup_ui_connections()
	update_display()

func setup_ui_references():
	"""Setup references to UI elements"""
	if inventory_column:
		var scroll = inventory_column.get_node_or_null("InventoryScroll")
		if scroll:
			inventory_grid = scroll.get_node_or_null("InventoryGrid")
	
	if party_inventory_column:
		var scroll = party_inventory_column.get_node_or_null("PartyInventoryScroll")
		if scroll:
			party_inventory_grid = scroll.get_node_or_null("PartyInventoryGrid")
	
	# Find footer elements
	var footer = get_node_or_null("MainContainer/Footer")
	if footer:
		total_cost_label = footer.get_node_or_null("TotalCostLabel")
		confirm_button = footer.get_node_or_null("ConfirmButton")

func setup_ui_connections():
	"""Setup button connections"""
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_button_pressed)

func setup_for_quest(quest: Quest, guild_inventory: Inventory):
	"""Setup the panel for a specific quest"""
	current_quest = quest
	inventory = guild_inventory
	party_inventory.clear()
	update_display()

func update_display():
	"""Update the inventory display"""
	update_inventory_column()
	update_party_inventory_column()
	update_total_cost()

func update_inventory_column():
	"""Update the inventory column with available items"""
	if not inventory_grid or not inventory:
		return
	
	# Clear existing items
	for child in inventory_grid.get_children():
		child.queue_free()
	
	# Get quest-appropriate items
	var quest_items = inventory.get_items_for_room("Quests")
	
	# Create item buttons
	for item in quest_items:
		if item != null:
			var item_button = create_item_button(item, false)
			inventory_grid.add_child(item_button)

func update_party_inventory_column():
	"""Update the party inventory column with selected items"""
	if not party_inventory_grid:
		return
	
	# Clear existing items
	for child in party_inventory_grid.get_children():
		child.queue_free()
	
	# Create item buttons for party inventory
	for item in party_inventory:
		var item_button = create_item_button(item, true)
		party_inventory_grid.add_child(item_button)

func create_item_button(item: InventoryItem, is_party_inventory: bool) -> Button:
	"""Create a button for an inventory item"""
	var button = Button.new()
	button.custom_minimum_size = Vector2(80, 60)
	button.flat = true
	button.name = "Item_%s" % item.item_id
	
	# Create item display
	var item_container = VBoxContainer.new()
	item_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(item_container)
	
	# Item name
	var name_label = Label.new()
	name_label.text = item.item_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 8)
	name_label.modulate = item.get_rarity_color()
	item_container.add_child(name_label)
	
	# Item cost
	var cost_label = Label.new()
	cost_label.text = "%dg" % item.base_value
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 8)
	item_container.add_child(cost_label)
	
	# Quantity (if more than 1)
	if item.quantity > 1:
		var quantity_label = Label.new()
		quantity_label.text = "x%d" % item.quantity
		quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		quantity_label.add_theme_font_size_override("font_size", 8)
		item_container.add_child(quantity_label)
	
	# Store item reference
	button.set_meta("item", item)
	button.set_meta("is_party_inventory", is_party_inventory)
	
	# Connect click handler
	button.pressed.connect(func(): _on_item_button_pressed(button))
	
	return button

func _on_item_button_pressed(button: Button):
	"""Handle item button press"""
	var item = button.get_meta("item")
	var is_party_inventory = button.get_meta("is_party_inventory")
	
	if is_party_inventory:
		# Remove from party inventory
		remove_from_party_inventory(item)
	else:
		# Add to party inventory
		add_to_party_inventory(item)
	
	update_display()

func add_to_party_inventory(item: InventoryItem):
	"""Add an item to the party inventory"""
	# Check if item is already in party inventory
	for party_item in party_inventory:
		if party_item.item_id == item.item_id:
			party_item.quantity += 1
			return
	
	# Add new item to party inventory
	var new_item = item.duplicate()
	new_item.quantity = 1
	party_inventory.append(new_item)

func remove_from_party_inventory(item: InventoryItem):
	"""Remove an item from the party inventory"""
	for i in range(party_inventory.size()):
		var party_item = party_inventory[i]
		if party_item.item_id == item.item_id:
			party_item.quantity -= 1
			if party_item.quantity <= 0:
				party_inventory.remove_at(i)
			return

func update_total_cost():
	"""Update the total cost display"""
	if not total_cost_label:
		return
	
	var total_cost = 0
	for item in party_inventory:
		total_cost += item.base_value * item.quantity
	
	total_cost_label.text = "Total Cost: %dg" % total_cost

func get_total_cost() -> int:
	"""Get the total cost of party inventory"""
	var total_cost = 0
	for item in party_inventory:
		total_cost += item.base_value * item.quantity
	return total_cost

func get_party_inventory() -> Array[InventoryItem]:
	"""Get the current party inventory"""
	return party_inventory.duplicate()

# Button event handlers
func _on_close_button_pressed():
	"""Close the quest inventory panel"""
	visible = false
	panel_closed.emit()

func _on_confirm_button_pressed():
	"""Confirm the selected items"""
	var total_cost = get_total_cost()
	items_confirmed.emit(party_inventory, total_cost)
	visible = false
