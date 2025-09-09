extends Control

#region Variables
var current_character: Character = null
#endregion

#region Node References
# Main UI Elements
@export var character_name_label: Label
@export var tab_container: TabContainer
@export var close_button: Button

# Statistics Tab - Basic Information
@export var class_info_label: Label

# Statistics Tab - Core Stats
@export var health_stat_label: Label
@export var defense_stat_label: Label
@export var mana_stat_label: Label
@export var spell_power_stat_label: Label
@export var attack_power_stat_label: Label
@export var movement_speed_stat_label: Label
@export var luck_stat_label: Label

# Statistics Tab - Sub-stats
@export var gathering_stat_label: Label
@export var hunting_stat_label: Label
@export var diplomacy_stat_label: Label
@export var caravan_stat_label: Label
@export var escort_stat_label: Label
@export var stealth_stat_label: Label
@export var odd_jobs_stat_label: Label

#region History Tab
# History Tab - Quest History
@export var quests_completed_label: Label
@export var quests_failed_label: Label
@export var success_rate_label: Label

# History Tab - Rewards History
@export var total_gold_label: Label
@export var total_experience_label: Label
@export var total_influence_label: Label

# History Tab - Injury History
@export var total_injuries_label: Label

# History Tab - Promotion History
@export var promotions_attempted_label: Label
@export var promotions_succeeded_label: Label
@export var promotions_failed_label: Label
#endregion

#region Equipment Tab

@export var equipment_vbox : VBoxContainer
@export var equipment_grid : GridContainer
@export var equipment_stats_container : VBoxContainer
@export var equipment_stats_label : Label
@export var equipment_stats_list : RichTextLabel

#endregion
#endregion

#region Initialization
func _ready():
	hide()  # Start hidden
	
	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	
	# Create equipment slots
	create_equipment_slots()
#endregion

#region Public Functions
func inspect_character(character: Character):
	"""Display the inspection panel for a specific character"""
	current_character = character
	update_display()
	show()
#endregion

#region Display Update Functions
func update_display():
	"""Update all display elements with current character data"""
	if not current_character:
		return
	
	# Update name
	character_name_label.text = current_character.character_name
	
	# Update all sections
	update_basic_info()
	update_statistics()
	update_history()
	update_equipment_display()
	update_equipment_stats()

func update_basic_info():
	"""Update basic character information"""
	var stars = "★".repeat(current_character.quality)
	class_info_label.text = "Class: %s | Quality: %s | Rank: %s" % [
		current_character.get_class_name(),
		stars,
		current_character.get_rank_name()
	]

func update_statistics():
	"""Update all statistics displays"""
	# Core stats
	health_stat_label.text = "Health: %d" % current_character.health
	defense_stat_label.text = "Defense: %d" % current_character.defense
	mana_stat_label.text = "Mana: %d" % current_character.mana
	spell_power_stat_label.text = "Spell Power: %d" % current_character.spell_power
	attack_power_stat_label.text = "Attack Power: %d" % current_character.attack_power
	movement_speed_stat_label.text = "Movement Speed: %d" % current_character.movement_speed
	luck_stat_label.text = "Luck: %d" % current_character.luck
	
	# Sub-stats
	gathering_stat_label.text = "Gathering: %d" % current_character.gathering
	hunting_stat_label.text = "Hunting & Trapping: %d" % current_character.hunting_trapping
	diplomacy_stat_label.text = "Diplomacy: %d" % current_character.diplomacy
	caravan_stat_label.text = "Caravan Guarding: %d" % current_character.caravan_guarding
	escort_stat_label.text = "Escorting: %d" % current_character.escorting
	stealth_stat_label.text = "Stealth: %d" % current_character.stealth
	odd_jobs_stat_label.text = "Odd Jobs: %d" % current_character.odd_jobs

func update_history():
	"""Update all history displays"""
	# Quest history
	quests_completed_label.text = "Quests Completed: %d" % current_character.quests_completed
	quests_failed_label.text = "Quests Failed: %d" % current_character.quests_failed
	
	var total_quests = current_character.quests_completed + current_character.quests_failed
	var success_rate = 0
	if total_quests > 0:
		success_rate = int((float(current_character.quests_completed) / float(total_quests)) * 100)
	success_rate_label.text = "Success Rate: %d%%" % success_rate
	
	# Rewards history
	total_gold_label.text = "Total Gold Earned: %d" % current_character.total_gold_earned
	total_experience_label.text = "Total Experience Earned: %d" % current_character.total_experience_earned
	total_influence_label.text = "Total Influence Earned: %d" % current_character.total_influence_earned
	
	# Injury history
	total_injuries_label.text = "Total Injuries Sustained: %d" % current_character.total_injuries_sustained
	
	# Promotion history
	promotions_attempted_label.text = "Promotions Attempted: %d" % current_character.promotions_attempted
	promotions_succeeded_label.text = "Promotions Succeeded: %d" % current_character.promotions_succeeded
	promotions_failed_label.text = "Promotions Failed: %d" % current_character.promotions_failed
#endregion

#region Equipment Functions
func create_equipment_slots():
	"""Create equipment slots in the grid"""
	if not equipment_grid:
		return
	
	# Clear existing slots
	for child in equipment_grid.get_children():
		child.queue_free()
	
	# Equipment slot names and positions (matching Character class equipment_slots)
	var equipment_slots = [
		{"name": "head", "position": Vector2(1, 0)},
		{"name": "shoulder", "position": Vector2(0, 0)},
		{"name": "back", "position": Vector2(2, 0)},
		{"name": "chest", "position": Vector2(1, 1)},
		{"name": "hands", "position": Vector2(0, 1)},
		{"name": "legs", "position": Vector2(1, 2)},
		{"name": "feet", "position": Vector2(2, 1)},
		{"name": "mainhand", "position": Vector2(0, 2)},
		{"name": "offhand", "position": Vector2(2, 2)},
		{"name": "accessory", "position": Vector2(1, 3)}
	]
	
	# Create equipment slots
	for slot_data in equipment_slots:
		var slot = create_equipment_slot(slot_data.name)
		equipment_grid.add_child(slot)

func create_equipment_slot(slot_name: String) -> Control:
	"""Create an individual equipment slot"""
	var slot = Panel.new()
	slot.custom_minimum_size = Vector2(80, 80)
	slot.name = slot_name
	
	# Set slot style
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.25, 0.8)
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.4, 0.4, 0.5, 0.8)
	style_box.corner_radius_top_left = 4
	style_box.corner_radius_top_right = 4
	style_box.corner_radius_bottom_right = 4
	style_box.corner_radius_bottom_left = 4
	
	slot.add_theme_stylebox_override("panel", style_box)
	
	# Add slot label with user-friendly display name
	var label = Label.new()
	label.text = get_slot_display_name(slot_name)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	slot.add_child(label)
	
	# Store slot name as metadata
	slot.set_meta("slot_name", slot_name)
	
	return slot

func get_slot_display_name(slot_name: String) -> String:
	"""Get user-friendly display name for equipment slot"""
	match slot_name:
		"head": return "Head"
		"shoulder": return "Shoulder"
		"back": return "Back"
		"chest": return "Chest"
		"hands": return "Hands"
		"legs": return "Legs"
		"feet": return "Feet"
		"mainhand": return "Main Hand"
		"offhand": return "Off Hand"
		"accessory": return "Accessory"
		_: return slot_name.capitalize()

func update_equipment_display():
	"""Update the equipment display for the current character"""
	if not current_character or not equipment_grid:
		return
	
	# Update equipment slots with current character's equipment
	for slot in equipment_grid.get_children():
		var slot_name = slot.get_meta("slot_name", "")
		var equipped_item = current_character.get_equipped_item(slot_name)
		
		if equipped_item:
			# Show equipped item
			update_slot_with_item(slot, equipped_item)
		else:
			# Show empty slot
			update_slot_empty(slot)

func update_slot_with_item(slot: Control, item: InventoryItem):
	"""Update a slot to show an equipped item"""
	# Clear existing content
	for child in slot.get_children():
		child.queue_free()
	
	# Add item icon/name
	var label = Label.new()
	label.text = item.item_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0, 1.0))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	slot.add_child(label)

func update_slot_empty(slot: Control):
	"""Update a slot to show it's empty"""
	# Clear existing content
	for child in slot.get_children():
		child.queue_free()
	
	# Add empty slot label
	var label = Label.new()
	var slot_name = slot.get_meta("slot_name", "")
	label.text = get_slot_display_name(slot_name)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
	slot.add_child(label)

func update_equipment_stats():
	"""Update equipment bonus stats display"""
	if not current_character or not equipment_stats_list:
		return
	
	var stats_text = ""
	var has_bonuses = false
	
	# Get equipment bonuses (same as CharacterEquipmentPanel)
	var bonuses = current_character.equipment_bonuses
	var multipliers = current_character.equipment_multipliers
	
	# Display additive bonuses
	for stat_name in bonuses:
		var bonus = bonuses[stat_name]
		if bonus != 0:
			has_bonuses = true
			var color = get_stat_color(stat_name)
			var display_name = get_stat_display_name(stat_name)
			stats_text += "[color=%s]+%d %s[/color]\n" % [color, bonus, display_name]
	
	# Display multiplicative bonuses
	for stat_name in multipliers:
		var multiplier = multipliers[stat_name]
		if multiplier != 1.0:
			has_bonuses = true
			var color = get_stat_color(stat_name)
			var display_name = get_stat_display_name(stat_name)
			var percentage = (multiplier - 1.0) * 100.0
			stats_text += "[color=%s][x] %.1f%% %s[/color]\n" % [color, percentage, display_name]
	
	if not has_bonuses:
		stats_text = "[color=#888888]No equipment bonuses[/color]"
	
	equipment_stats_list.text = stats_text

func get_stat_color(stat_name: String) -> String:
	"""Get color for stat display"""
	match stat_name:
		"health": return "#00ff00"
		"defense": return "#0080ff"
		"attack_power": return "#ff0000"
		"spell_power": return "#8000ff"
		"mana": return "#0080ff"
		"movement_speed": return "#ffff00"
		"luck": return "#ff8000"
		_: return "#ffffff"

func get_stat_display_name(stat_name: String) -> String:
	"""Get display name for stat"""
	match stat_name:
		"health": return "Health"
		"defense": return "Defense"
		"attack_power": return "Attack Power"
		"spell_power": return "Spell Power"
		"mana": return "Mana"
		"movement_speed": return "Movement Speed"
		"luck": return "Luck"
		"gathering": return "Gathering"
		"hunting_trapping": return "Hunting & Trapping"
		"diplomacy": return "Diplomacy"
		"caravan_guarding": return "Caravan Guarding"
		"escorting": return "Escorting"
		"stealth": return "Stealth"
		"odd_jobs": return "Odd Jobs"
		_: return stat_name.capitalize()
#endregion

#region Event Handlers
func _on_close_button_pressed():
	"""Handle close button press"""
	UILayerManager.remove_from_layer(self)
#endregion
