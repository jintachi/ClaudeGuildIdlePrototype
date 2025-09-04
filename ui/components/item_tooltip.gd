class_name ItemTooltip
extends Panel

#region UI References
@onready var item_icon: TextureRect = $VBoxContainer/HeaderContainer/ItemIcon
@onready var item_name: Label = $VBoxContainer/HeaderContainer/TitleContainer/ItemName
@onready var item_type: Label = $VBoxContainer/HeaderContainer/TitleContainer/ItemType
@onready var description: RichTextLabel = $VBoxContainer/DescriptionContainer/Description
@onready var stats_list: RichTextLabel = $VBoxContainer/StatsContainer/StatsList
@onready var requirements_list: RichTextLabel = $VBoxContainer/RequirementsContainer/RequirementsList
@onready var value_label: Label = $VBoxContainer/FooterContainer/ValueLabel
@onready var charges_label: Label = $VBoxContainer/FooterContainer/ChargesLabel
#endregion

#region Tooltip Data
var current_item: InventoryItem = null
var tooltip_width: int = 300
var tooltip_height: int = 200
#endregion

func _ready():
	"""Initialize the tooltip"""
	# Set initial size
	custom_minimum_size = Vector2(tooltip_width, tooltip_height)
	
	# Hide by default
	visible = false
	
	# Set up mouse filter to not interfere with other UI
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func show_tooltip(item: InventoryItem, tooltip_position: Vector2 = Vector2.ZERO):
	"""Show tooltip for the given item"""
	if not item:
		hide_tooltip()
		return
	
	current_item = item
	update_tooltip_content()
	
	# Position the tooltip
	if tooltip_position != Vector2.ZERO:
		global_position = tooltip_position
	else:
		# Default position near mouse
		global_position = get_global_mouse_position() + Vector2(10, 10)
	
	# Ensure tooltip stays on screen
	clamp_to_screen()
	
	visible = true

func hide_tooltip():
	"""Hide the tooltip"""
	visible = false
	current_item = null

func update_tooltip_content():
	"""Update all tooltip content based on current item"""
	if not current_item:
		return
	
	# Update header
	update_header()
	
	# Update description
	update_description()
	
	# Update stats
	update_stats()
	
	# Update requirements
	update_requirements()
	
	# Update footer
	update_footer()
	
	# Adjust size to fit content
	fit_content()

func update_header():
	"""Update the tooltip header with item name, type, and icon"""
	# Item name with rarity color
	var rarity_color = current_item.get_rarity_color()
	var name_text = "[color=#%s]%s[/color]" % [rarity_color.to_html(false), current_item.get_display_name()]
	item_name.text = name_text
	
	# Item type
	var type_text = current_item.item_type.capitalize()
	if current_item.enhancement_level > 0:
		type_text += " (+%d)" % current_item.enhancement_level
	item_type.text = type_text
	
	# Item icon (if available)
	if current_item.icon_path and current_item.icon_path != "":
		var texture = load(current_item.icon_path)
		if texture:
			item_icon.texture = texture
			item_icon.visible = true
		else:
			item_icon.visible = false
	else:
		item_icon.visible = false

func update_description():
	"""Update the item description"""
	var desc_text = current_item.item_description
	
	# Add enhancement info if applicable
	if current_item.enhancement_level > 0:
		desc_text += "\n\n[color=#FFD700]Enhanced to level %d[/color]" % current_item.enhancement_level
	
	description.text = desc_text

func update_stats():
	"""Update the stats section"""
	var stats_text = ""
	
	# Equipment stats
	if current_item.item_type == "equipment" and current_item.stat_bonuses.size() > 0:
		for stat in current_item.stat_bonuses:
			var value = current_item.stat_bonuses[stat]
			var stat_name = stat.replace("_", " ").capitalize()
			
			if value > 0:
				stats_text += "[color=#90EE90]+%d %s[/color]\n" % [value, stat_name]
			elif value < 0:
				stats_text += "[color=#FFB6C1]%d %s[/color]\n" % [value, stat_name]
	
	# Consumable effects
	if current_item.item_type == "consumables" and current_item.has_meta("effects"):
		var effects = current_item.get_meta("effects")
		for effect in effects:
			var effect_name = effect.replace("_", " ").capitalize()
			var effect_value = effects[effect]
			stats_text += "[color=#87CEEB]%s: %s[/color]\n" % [effect_name, str(effect_value)]
	
	# Durability for equipment
	if current_item.item_type == "equipment" and current_item.max_durability > 0:
		var durability_percent = current_item.get_durability_percentage()
		var durability_color = "#90EE90" if durability_percent > 50 else "#FFB6C1" if durability_percent > 25 else "#FF6B6B"
		stats_text += "[color=%s]Durability: %d/%d[/color]\n" % [durability_color, current_item.durability, current_item.max_durability]
	
	if stats_text == "":
		stats_text = "[color=#888888]No special stats[/color]"
	
	stats_list.text = stats_text

func update_requirements():
	"""Update the requirements section"""
	var req_text = ""
	
	# Level requirement
	if current_item.level_requirement > 0:
		req_text += "[color=#FFD700]Level: %d[/color]\n" % current_item.level_requirement
	
	# Class requirement
	if current_item.class_requirement != "":
		req_text += "[color=#FFD700]Class: %s[/color]\n" % current_item.class_requirement.capitalize()
	
	# Rank requirement
	if current_item.rank_requirement != "":
		req_text += "[color=#FFD700]Rank: %s[/color]\n" % current_item.rank_requirement.capitalize()
	
	# Equipment slot info
	if current_item.item_type == "equipment" and current_item.equipment_slot != "":
		var slot_name = current_item.equipment_slot.replace("_", " ").capitalize()
		req_text += "[color=#87CEEB]Slot: %s[/color]\n" % slot_name
	
	if req_text == "":
		req_text = "[color=#888888]No requirements[/color]"
	
	requirements_list.text = req_text

func update_footer():
	"""Update the footer with value and charges"""
	# Value
	var value = current_item.get_effective_value()
	value_label.text = "Value: %d" % value
	
	# Charges
	var charge_display = current_item.get_charge_display()
	if charge_display != "":
		charges_label.text = "Charges: %s" % charge_display
		charges_label.visible = true
	else:
		charges_label.visible = false

func fit_content():
	"""Adjust tooltip size to fit content"""
	# Calculate required size based on content
	var required_height = 0
	
	# Estimate height based on text content and components
	required_height += 60  # Header (icon + name + type)
	required_height += 40  # Description (estimated)
	required_height += 60  # Stats section (estimated)
	required_height += 40  # Requirements section (estimated)
	required_height += 30  # Footer (value + charges)
	required_height += 20  # Padding
	
	# Set size
	custom_minimum_size = Vector2(tooltip_width, max(tooltip_height, required_height))

func clamp_to_screen():
	"""Ensure tooltip stays within screen bounds"""
	var viewport_size = get_viewport().size
	var tooltip_size = size
	
	# Clamp X position
	if global_position.x + tooltip_size.x > viewport_size.x:
		global_position.x = viewport_size.x - tooltip_size.x - 10
	
	if global_position.x < 0:
		global_position.x = 10
	
	# Clamp Y position
	if global_position.y + tooltip_size.y > viewport_size.y:
		global_position.y = viewport_size.y - tooltip_size.y - 10
	
	if global_position.y < 0:
		global_position.y = 10

func set_tooltip_size(width: int, height: int):
	"""Set custom tooltip size"""
	tooltip_width = width
	tooltip_height = height
	custom_minimum_size = Vector2(tooltip_width, tooltip_height)
