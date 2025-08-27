class_name BlacksmithsGuildRoom
extends BaseRoom

## Blacksmith's Guild Room
## Handles equipment crafting, repair, and upgrades

# UI elements
@export var crafting_panel: VBoxContainer
@export var repair_panel: VBoxContainer
@export var materials_panel: VBoxContainer
@export var forge_status: Label

# Mock data for craftable items
var craftable_items = [
	{"name": "Steel Sword", "type": "weapon", "materials": ["Iron Ore: 3", "Coal: 2"], "cost": 75, "description": "A sharp steel blade"},
	{"name": "Chain Mail", "type": "armor", "materials": ["Iron Ore: 5", "Coal: 3"], "cost": 100, "description": "Flexible metal armor"},
	{"name": "Iron Shield", "type": "shield", "materials": ["Iron Ore: 2", "Wood: 1"], "cost": 50, "description": "Sturdy defensive equipment"},
	{"name": "Steel Dagger", "type": "weapon", "materials": ["Iron Ore: 1", "Coal: 1"], "cost": 30, "description": "Quick and precise weapon"}
]

# Mock damaged equipment for repair
var damaged_equipment = [
	{"name": "Damaged Sword", "repair_cost": 25, "condition": "Dull", "description": "Needs sharpening"},
	{"name": "Broken Shield", "repair_cost": 40, "condition": "Cracked", "description": "Handle needs replacement"},
	{"name": "Worn Armor", "repair_cost": 60, "condition": "Torn", "description": "Multiple tears in leather"}
]

# Available materials and upgrades
var materials_and_upgrades = [
	{"name": "Iron Ore", "type": "material", "stock": 10, "price": 5, "description": "Basic smithing material"},
	{"name": "Coal", "type": "material", "stock": 15, "price": 3, "description": "Fuel for the forge"},
	{"name": "Weapon Sharpening", "type": "upgrade", "cost": 20, "description": "Increase weapon damage"},
	{"name": "Armor Reinforcement", "type": "upgrade", "cost": 35, "description": "Increase armor protection"}
]

var forge_busy_until: float = 0.0

func _init():
	room_name = "Blacksmith's Guild"
	room_description = "Craft weapons and armor, repair equipment"
	is_unlocked = true

func setup_room_specific_ui():
	"""Setup blacksmith guild specific UI connections"""
	# This room is currently a placeholder
	pass

func on_room_entered():
	"""Called when entering the blacksmith's guild"""
	update_room_display()

func update_room_display():
	"""Update the blacksmith's guild display"""
	update_forge_status()
	update_crafting_display()
	update_repair_display()
	update_materials_display()

func update_forge_status():
	"""Update the forge status display"""
	if not forge_status:
		return
	
	var current_time = Time.get_time_dict_from_system()
	var current_timestamp = current_time.hour * 3600 + current_time.minute * 60 + current_time.second
	
	if forge_busy_until > current_timestamp:
		var remaining = forge_busy_until - current_timestamp
		forge_status.text = "Forge: Busy (%d min)" % (remaining / 60)
		forge_status.add_theme_color_override("font_color", Color.RED)
	else:
		forge_status.text = "Forge: Ready"
		forge_status.add_theme_color_override("font_color", Color.GREEN)

func update_crafting_display():
	"""Update the crafting items display"""
	if not crafting_panel:
		return
	
	# Clear existing items
	for child in crafting_panel.get_children():
		child.queue_free()
	
	# Add craftable items
	for item in craftable_items:
		var item_panel = create_crafting_item_panel(item)
		crafting_panel.add_child(item_panel)

func update_repair_display():
	"""Update the repair items display"""
	if not repair_panel:
		return
	
	# Clear existing items
	for child in repair_panel.get_children():
		child.queue_free()
	
	# Add damaged equipment
	for equipment in damaged_equipment:
		var equipment_panel = create_repair_item_panel(equipment)
		repair_panel.add_child(equipment_panel)

func update_materials_display():
	"""Update the materials and upgrades display"""
	if not materials_panel:
		return
	
	# Clear existing items
	for child in materials_panel.get_children():
		child.queue_free()
	
	# Add materials and upgrades
	for mat_item in materials_and_upgrades:
		var material_panel = create_material_panel(mat_item)
		materials_panel.add_child(material_panel)

func create_crafting_item_panel(item: Dictionary) -> Control:
	"""Create a panel for a craftable item"""
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(250, 120)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 3)
	panel.add_child(vbox)
	
	# Item header with name and cost
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var name_label = Label.new()
	name_label.text = item.name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	
	var cost_label = Label.new()
	cost_label.text = "%d gold" % item.cost
	cost_label.add_theme_color_override("font_color", Color.YELLOW)
	header.add_child(cost_label)
	
	# Materials required
	var materials_label = Label.new()
	materials_label.text = "Materials: " + ", ".join(item.materials)
	materials_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(materials_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = item.description
	desc_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(desc_label)
	
	# Craft button
	var craft_button = Button.new()
	craft_button.text = "Craft"
	craft_button.pressed.connect(_on_craft_item.bind(item))
	vbox.add_child(craft_button)
	
	return panel

func create_repair_item_panel(equipment: Dictionary) -> Control:
	"""Create a panel for repairable equipment"""
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(250, 100)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	
	# Equipment header with name and cost
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var name_label = Label.new()
	name_label.text = equipment.name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	
	var cost_label = Label.new()
	cost_label.text = "%d gold" % equipment.repair_cost
	cost_label.add_theme_color_override("font_color", Color.YELLOW)
	header.add_child(cost_label)
	
	# Condition
	var condition_label = Label.new()
	condition_label.text = "Condition: " + equipment.condition
	condition_label.add_theme_color_override("font_color", Color.RED)
	vbox.add_child(condition_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = equipment.description
	desc_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(desc_label)
	
	# Repair button
	var repair_button = Button.new()
	repair_button.text = "Repair"
	repair_button.pressed.connect(_on_repair_equipment.bind(equipment))
	vbox.add_child(repair_button)
	
	return panel

func create_material_panel(mat_item: Dictionary) -> Control:
	"""Create a panel for materials and upgrades"""
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(250, 80)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	
	# Material header with name and price/cost
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var name_label = Label.new()
	name_label.text = mat_item.name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	
	var price_label = Label.new()
	if mat_item.type == "material":
		price_label.text = "%d gold (Stock: %d)" % [mat_item.price, mat_item.stock]
	else:
		price_label.text = "%d gold" % mat_item.cost
	price_label.add_theme_color_override("font_color", Color.YELLOW)
	header.add_child(price_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = mat_item.description
	desc_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(desc_label)
	
	# Action button
	var action_button = Button.new()
	if mat_item.type == "material":
		action_button.text = "Buy"
	else:
		action_button.text = "Apply Upgrade"
	action_button.pressed.connect(_on_material_action.bind(mat_item))
	vbox.add_child(action_button)
	
	return panel

func _on_craft_item(item: Dictionary):
	"""Handle crafting an item"""
	print("Attempting to craft: ", item.name)
	# TODO: Implement actual crafting logic
	# Check materials and gold
	# Start crafting process with time delay

func _on_repair_equipment(equipment: Dictionary):
	"""Handle repairing equipment"""
	print("Attempting to repair: ", equipment.name)
	# TODO: Implement actual repair logic
	# Check gold and start repair process

func _on_material_action(mat_item: Dictionary):
	"""Handle material purchase or upgrade application"""
	if mat_item.type == "material":
		print("Attempting to buy material: ", mat_item.name)
		# TODO: Implement material purchase
	else:
		print("Attempting to apply upgrade: ", mat_item.name)
		# TODO: Implement upgrade system
