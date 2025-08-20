class_name StatsComparisonTable
extends VBoxContainer

## StatsComparisonTable Component
## Displays quest requirements vs current party stats in a table format
## Shows all comparable stats with visual indicators for pass/fail

@onready var stats_container: VBoxContainer = $StatsContainer

# Color coding for status
const COLOR_PASS = Color.GREEN
const COLOR_FAIL = Color.RED
const COLOR_NEUTRAL = Color.WHITE

# All trackable stats from Character class
var all_stats = [
	# Core Combat Stats
	{"key": "health", "display": "HP", "category": "core"},
	{"key": "defense", "display": "Def", "category": "core"},
	{"key": "mana", "display": "Mana", "category": "core"},
	{"key": "spell_power", "display": "Spell Power", "category": "core"},
	{"key": "attack_power", "display": "Attack", "category": "core"},
	{"key": "movement_speed", "display": "Speed", "category": "core"},
	{"key": "luck", "display": "Luck", "category": "core"},
	
	# Class Requirements
	{"key": "required_tank", "display": "Tank Required", "category": "class"},
	{"key": "required_healer", "display": "Healer Required", "category": "class"},
	{"key": "required_support", "display": "Support Required", "category": "class"},
	{"key": "required_attacker", "display": "Attacker Required", "category": "class"},
	
	# Mission-Specific Skills
	{"key": "gathering", "display": "Gathering", "category": "substat"},
	{"key": "hunting_trapping", "display": "Hunting", "category": "substat"},
	{"key": "diplomacy", "display": "Diplomacy", "category": "substat"},
	{"key": "caravan_guarding", "display": "Guarding", "category": "substat"},
	{"key": "escorting", "display": "Escorting", "category": "substat"},
	{"key": "stealth", "display": "Stealth", "category": "substat"},
	{"key": "odd_jobs", "display": "Odd Jobs", "category": "substat"}
]

# Current data
var quest_requirements: Dictionary = {}
var party_stats: Dictionary = {}

func _ready():
	"""Initialize the stats comparison table"""
	setup_table_structure()

func setup_table_structure():
	"""Create the table structure with all stats"""
	# Clear any existing rows
	for child in stats_container.get_children():
		child.queue_free()
	
	# Wait a frame for cleanup
	await get_tree().process_frame
	
	# Create rows for all stats
	for stat_info in all_stats:
		create_stat_row(stat_info)

func create_stat_row(stat_info: Dictionary) -> HBoxContainer:
	"""Create a single stat row"""
	var row = HBoxContainer.new()
	row.name = stat_info.key + "_row"
	stats_container.add_child(row)
	
	# Stat name
	var stat_label = Label.new()
	stat_label.custom_minimum_size = Vector2(120, 0)
	stat_label.text = stat_info.display
	stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(stat_label)
	
	# Separator
	var sep1 = VSeparator.new()
	row.add_child(sep1)
	
	# Required value
	var required_label = Label.new()
	required_label.name = "required"
	required_label.custom_minimum_size = Vector2(80, 0)
	required_label.text = "-"
	required_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(required_label)
	
	# Separator
	var sep2 = VSeparator.new()
	row.add_child(sep2)
	
	# Current value
	var current_label = Label.new()
	current_label.name = "current"
	current_label.custom_minimum_size = Vector2(80, 0)
	current_label.text = "-"
	current_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(current_label)
	
	# Separator
	var sep3 = VSeparator.new()
	row.add_child(sep3)
	
	# Status indicator
	var status_label = Label.new()
	status_label.name = "status"
	status_label.custom_minimum_size = Vector2(60, 0)
	status_label.text = "-"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(status_label)
	
	return row

func update_quest_requirements(requirements: Dictionary):
	"""Update the quest requirements"""
	quest_requirements = requirements
	refresh_table()

func update_party_stats(stats: Dictionary):
	"""Update the current party stats"""
	party_stats = stats
	refresh_table()

func refresh_table():
	"""Refresh all stat rows with current data"""
	# If no quest requirements, show default message
	if quest_requirements.is_empty():
		show_default_message()
		return
	
	# Otherwise, clear any default message and show stat rows
	for child in stats_container.get_children():
		if child is Label and child.text == "Select a quest first":
			child.queue_free()
	
	for stat_info in all_stats:
		update_stat_row(stat_info)

func update_stat_row(stat_info: Dictionary):
	"""Update a single stat row with current data"""
	var row = stats_container.get_node_or_null(stat_info.key + "_row")
	if not row:
		# Create the row if it doesn't exist
		row = create_stat_row(stat_info)
	
	var required_label = row.get_node("required")
	var current_label = row.get_node("current")
	var status_label = row.get_node("status")
	
	# Get values
	var required_value = quest_requirements.get(stat_info.key, 0)
	var current_value = party_stats.get(stat_info.key, 0)
	
	# Handle class requirements differently from numeric stats
	if stat_info.category == "class":
		# For class requirements, show Yes/No instead of numbers
		if required_value > 0:
			required_label.text = "Yes"
			required_label.modulate = COLOR_NEUTRAL
		else:
			required_label.text = "-"
			required_label.modulate = Color.GRAY
		
		if current_value > 0:
			current_label.text = "Yes"
		else:
			current_label.text = "No"
	else:
		# For numeric stats, show numbers
		if required_value > 0:
			required_label.text = str(required_value)
			required_label.modulate = COLOR_NEUTRAL
		else:
			required_label.text = "-"
			required_label.modulate = Color.GRAY
		
		if current_value > 0 or required_value > 0:
			current_label.text = str(current_value)
		else:
			current_label.text = "-"
	
	# Update status
	if required_value > 0:
		var meets_requirement = current_value >= required_value
		if meets_requirement:
			status_label.text = "✓"
			status_label.modulate = COLOR_PASS
			current_label.modulate = COLOR_PASS
		else:
			status_label.text = "✗"
			status_label.modulate = COLOR_FAIL
			current_label.modulate = COLOR_FAIL
	else:
		status_label.text = "-"
		status_label.modulate = Color.GRAY
		current_label.modulate = COLOR_NEUTRAL
	
	# Show core stats always, sub-stats only if relevant to quest or party has them
	var should_show = false
	if stat_info.category == "core":
		should_show = true  # Always show core stats
	elif stat_info.category == "substat":
		# Show sub-stats if they're required OR if party has points in them
		should_show = required_value > 0 or current_value > 0
	elif stat_info.category == "class":
		# Show class requirements if they exist
		should_show = required_value > 0
	
	row.visible = should_show

func clear_data():
	"""Clear all data and show default message"""
	quest_requirements.clear()
	party_stats.clear()
	show_default_message()

func show_default_message():
	"""Show 'Select a quest first' message when no quest is selected"""
	# Clear all existing stat rows
	for child in stats_container.get_children():
		child.queue_free()
	
	# Create a centered message label
	var message_label = Label.new()
	message_label.text = "Select a quest first"
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 16)
	message_label.modulate = Color(0.7, 0.7, 0.7)  # Slightly dimmed
	message_label.custom_minimum_size = Vector2(0, 100)  # Give it some height
	stats_container.add_child(message_label)

func get_overall_status() -> bool:
	"""Check if party meets all quest requirements"""
	for stat_info in all_stats:
		var required = quest_requirements.get(stat_info.key, 0)
		if required > 0:
			var current = party_stats.get(stat_info.key, 0)
			if current < required:
				return false
	return true

func get_missing_requirements() -> Array:
	"""Get list of requirements not met"""
	var missing = []
	for stat_info in all_stats:
		var required = quest_requirements.get(stat_info.key, 0)
		if required > 0:
			var current = party_stats.get(stat_info.key, 0)
			if current < required:
				missing.append({
					"stat": stat_info.display,
					"required": required,
					"current": current,
					"deficit": required - current
				})
	return missing

func get_requirements_summary() -> String:
	"""Get a text summary of requirements status"""
	var missing = get_missing_requirements()
	if missing.is_empty():
		return "All requirements met!"
	else:
		var summary = "Missing requirements:\n"
		for req in missing:
			summary += "• %s: %d/%d (need %d more)\n" % [req.stat, req.current, req.required, req.deficit]
		return summary.trim_suffix("\n")
