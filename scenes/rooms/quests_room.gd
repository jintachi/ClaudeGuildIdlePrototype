class_name QuestsRoom
extends BaseRoom

# Quests-specific UI elements
@export var available_quests_list: VBoxContainer
@export var start_quest_button: Button
@export var quest_info_label: Label
@export var stats_comparison_table: Control
@export var guild_roster_grid: GridContainer

# Quest and party state
var current_selected_quest: Quest = null
var current_party: Array[Character] = []

func _init():
	room_name = "Quests"
	room_description = "Accept and manage quests"
	is_unlocked = true

func setup_room_specific_ui():
	"""Setup quests-specific UI connections"""
	# Connect to guild manager signals for quest updates
	if GuildManager:
		GuildManager.quest_started.connect(_on_quest_started)
		GuildManager.quest_completed.connect(_on_quest_completed)
	
	# Connect UI buttons
	if start_quest_button:
		start_quest_button.pressed.connect(_on_start_quest_button_pressed)

func on_room_entered():
	"""Called when entering the quests room"""
	update_room_display()

func update_room_display():
	"""Update the quests display"""
	update_quests_display()

func update_quests_display():
	"""Update the quests display with all available quests"""
	# Clear existing displays
	for child in available_quests_list.get_children():
		child.queue_free()
	
	# Create panels for each available quest
	for quest in GuildManager.available_quests:
		var quest_panel = create_quest_panel(quest)
		available_quests_list.add_child(quest_panel)
	
	# Wait a frame for the panels to be added to the scene tree
	await get_tree().process_frame
	
	# Auto-select first quest or validate current selection
	auto_select_first_quest()
	
	# Restore visual states if a quest is currently selected
	if current_selected_quest:
		update_quest_panel_states(current_selected_quest)

func create_quest_panel(quest: Quest) -> Control:
	"""Create a quest panel for the quests display"""
	# Create a clickable button instead of a panel
	var panel_button = Button.new()
	panel_button.custom_minimum_size = Vector2(450, 210)
	panel_button.flat = true  # Remove default button styling
	
	# Set anchors and size flags
	panel_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Connect the click handler
	panel_button.pressed.connect(func(): select_quest(quest))
	
	# Store quest reference for later identification
	panel_button.set_meta("quest", quest)
	
	# Create a panel inside the button for styling
	var inner_panel = Panel.new()
	inner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let button handle clicks
	panel_button.add_child(inner_panel)
	inner_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var vbox = VBoxContainer.new()
	inner_panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 3)
	
	# Quest title
	var title_label = Label.new()
	title_label.text = quest.quest_name
	title_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = quest.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	
	# Requirements
	var req_label = Label.new()
	req_label.text = "Requirements: " + quest.get_requirements_text()
	req_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(req_label)
	
	# Rewards
	var reward_label = Label.new()
	reward_label.text = "Rewards: " + quest.get_rewards_text()
	vbox.add_child(reward_label)
	
	# Duration
	var duration_label = Label.new()
	var minutes = int(quest.duration / 60)
	var seconds = int(quest.duration) % 60
	duration_label.text = "Duration: %02d:%02d" % [minutes, seconds]
	vbox.add_child(duration_label)
	
	# Success chance (placeholder - will be updated when party is selected)
	var success_label = Label.new()
	success_label.text = "Success Chance: --"
	success_label.add_theme_color_override("font_color", Color.YELLOW)
	success_label.set_meta("success_label", true)  # Mark for easy updating
	success_label.visible = false  # Hidden by default, only shown on selected quest
	vbox.add_child(success_label)
	
	return panel_button

func select_quest(quest: Quest):
	"""Select a quest and update the display"""
	# If the same quest is clicked, do nothing (can't deselect, only switch to another)
	if current_selected_quest == quest:
		return
	
	# Update visual states
	update_quest_panel_states(quest)
	
	# Set the new selected quest
	current_selected_quest = quest
	current_party.clear()
	update_party_selection_display()

func update_quest_panel_states(selected_quest: Quest):
	"""Update visual states of all quest panels"""
	# Find all quest panels and update their states
	for child in available_quests_list.get_children():
		if child.has_meta("quest"):
			var quest = child.get_meta("quest")
			var inner_panel = child.get_child(0)  # The Panel inside the Button
			
			if inner_panel is Panel:
				var vbox = inner_panel.get_child(0)  # The VBoxContainer
				
				# Use theme-based selection method
				if quest == selected_quest:
					# Selected state: use the "selected" theme variation
					inner_panel.add_theme_stylebox_override("panel", get_theme_stylebox("selected", "QuestPanel"))
					
					# Show success chance label for selected quest
					for vbox_child in vbox.get_children():
						if vbox_child.has_meta("success_label"):
							vbox_child.visible = true
							break
				else:
					# Unselected state: use the default "panel" theme variation
					inner_panel.add_theme_stylebox_override("panel", get_theme_stylebox("panel", "QuestPanel"))
					
					# Hide success chance label for unselected quests
					for vbox_child in vbox.get_children():
						if vbox_child.has_meta("success_label"):
							vbox_child.visible = false
							break

func auto_select_first_quest():
	"""Auto-select the first available quest if none is currently selected"""
	if not current_selected_quest and not GuildManager.available_quests.is_empty():
		var first_quest = GuildManager.available_quests[0]
		select_quest(first_quest)
	elif current_selected_quest:
		# Ensure the currently selected quest is still in the available list
		var quest_still_available = false
		for quest in GuildManager.available_quests:
			if quest == current_selected_quest:
				quest_still_available = true
				break
		
		# If current quest is no longer available, select first available quest
		if not quest_still_available and not GuildManager.available_quests.is_empty():
			var first_quest = GuildManager.available_quests[0]
			select_quest(first_quest)
		elif not quest_still_available:
			# No quests available, clear selection
			current_selected_quest = null

func reset_quest_tab_to_default():
	"""Reset the quest tab to its default state with no quest selected"""
	# Clear current selections
	current_selected_quest = null
	current_party.clear()
		
	# Clear quest info display
	if quest_info_label:
		quest_info_label.text = "Select a quest to view details"
	
	# Reset stats comparison table to show "Select a quest first"
	if stats_comparison_table and stats_comparison_table.has_method("clear_data"):
		stats_comparison_table.clear_data()
	
	# Clear party list
	for child in guild_roster_grid.get_children():
		child.queue_free()

func update_party_selection_display():
	"""Update the party selection display"""
	if not current_selected_quest:
		return
	
	# Make single call to get available characters
	var available_chars = GuildManager.get_available_characters()
	
	# Update the grid display and stats comparison
	update_available_characters_display(available_chars)
	update_stats_comparison_table()
	update_start_quest_button_state()
	
	# Update success chance display for all quest panels
	update_quest_success_chances()

func update_stats_comparison_table():
	"""Update the stats comparison table with quest requirements and current party stats"""
	if not stats_comparison_table or not current_selected_quest:
		return
	
	# Get quest requirements
	var quest_requirements = get_quest_stat_requirements()
	
	# Get current party stats
	var party_stats = get_current_party_total_stats()
	
	# Update the table
	if stats_comparison_table.has_method("update_quest_requirements"):
		stats_comparison_table.update_quest_requirements(quest_requirements)
	if stats_comparison_table.has_method("update_party_stats"):
		stats_comparison_table.update_party_stats(party_stats)

func update_quest_success_chances():
	"""Update the success chance display only for the selected quest based on current party"""
	if not current_selected_quest:
		return
		
	# Find the selected quest panel and update its success chance label
	for child in available_quests_list.get_children():
		if child.has_meta("quest") and child.get_meta("quest") == current_selected_quest:
			var inner_panel = child.get_child(0)  # The Panel inside the Button
			
			if inner_panel is Panel:
				var vbox = inner_panel.get_child(0)  # The VBoxContainer
				
				# Find the success label
				for vbox_child in vbox.get_children():
					if vbox_child.has_meta("success_label"):
						# Make sure the label is visible for the selected quest
						vbox_child.visible = true
						
						var success_chance = current_selected_quest.get_suggested_success_chance(current_party)
						var success_percentage = int(success_chance * 100)
						
						# Color code the success chance
						var color = Color.WHITE
						if success_percentage >= 80:
							color = Color.GREEN
						elif success_percentage >= 60:
							color = Color.YELLOW
						elif success_percentage >= 40:
							color = Color.ORANGE
						else:
							color = Color.RED
						
						vbox_child.text = "Success Chance: %d%%" % success_percentage
						vbox_child.add_theme_color_override("font_color", color)
						break
			break  # Found the selected quest, no need to continue searching

func get_quest_stat_requirements() -> Dictionary:
	"""Extract stat requirements from the current quest"""
	if not current_selected_quest:
		return {}
	
	var requirements = {}
	
	# Core stats
	if current_selected_quest.min_total_health > 0:
		requirements["health"] = current_selected_quest.min_total_health
	if current_selected_quest.min_total_defense > 0:
		requirements["defense"] = current_selected_quest.min_total_defense
	if current_selected_quest.min_total_attack_power > 0:
		requirements["attack_power"] = current_selected_quest.min_total_attack_power
	if current_selected_quest.min_total_spell_power > 0:
		requirements["spell_power"] = current_selected_quest.min_total_spell_power
	
	# Class requirements (use 1 for true, 0 for false)
	if current_selected_quest.required_tank:
		requirements["required_tank"] = 1
	if current_selected_quest.required_healer:
		requirements["required_healer"] = 1
	if current_selected_quest.required_support:
		requirements["required_support"] = 1
	if current_selected_quest.required_attacker:
		requirements["required_attacker"] = 1
	
	# Sub-stats from quest type
	if current_selected_quest.min_substat_requirement > 0:
		match current_selected_quest.quest_type:
			Quest.QuestType.GATHERING:
				requirements["gathering"] = current_selected_quest.min_substat_requirement
			Quest.QuestType.HUNTING_TRAPPING:
				requirements["hunting_trapping"] = current_selected_quest.min_substat_requirement
			Quest.QuestType.DIPLOMACY:
				requirements["diplomacy"] = current_selected_quest.min_substat_requirement
			Quest.QuestType.CARAVAN_GUARDING:
				requirements["caravan_guarding"] = current_selected_quest.min_substat_requirement
			Quest.QuestType.ESCORTING:
				requirements["escorting"] = current_selected_quest.min_substat_requirement
			Quest.QuestType.STEALTH:
				requirements["stealth"] = current_selected_quest.min_substat_requirement
			Quest.QuestType.ODD_JOBS:
				requirements["odd_jobs"] = current_selected_quest.min_substat_requirement
	
	return requirements

func get_current_party_total_stats() -> Dictionary:
	"""Calculate total stats for the current party"""
	var total_stats = {}
	
	# Initialize all stats to 0
	var stat_keys = ["health", "defense", "mana", "spell_power", "attack_power", "movement_speed", "luck",
					 "gathering", "hunting_trapping", "diplomacy", "caravan_guarding", "escorting", "stealth", "odd_jobs"]
	
	for stat in stat_keys:
		total_stats[stat] = 0
	
	# Initialize class coverage to 0 (no classes available)
	total_stats["required_tank"] = 0
	total_stats["required_healer"] = 0
	total_stats["required_support"] = 0
	total_stats["required_attacker"] = 0
	
	if current_party.is_empty():
		return total_stats
	
	# Initialize class coverage
	var has_tank = false
	var has_healer = false
	var has_support = false
	var has_attacker = false
	
	# Sum stats from all party members
	for character in current_party:
		if character:
			var char_stats = character.get_effective_stats()
			
			# Add core stats
			total_stats["health"] += char_stats.get("health", 0)
			total_stats["defense"] += char_stats.get("defense", 0)
			total_stats["mana"] += char_stats.get("mana", 0)
			total_stats["spell_power"] += char_stats.get("spell_power", 0)
			total_stats["attack_power"] += char_stats.get("attack_power", 0)
			total_stats["movement_speed"] += char_stats.get("movement_speed", 0)
			total_stats["luck"] += char_stats.get("luck", 0)
			
			# Add sub-stats directly from character
			total_stats["gathering"] += character.gathering
			total_stats["hunting_trapping"] += character.hunting_trapping
			total_stats["diplomacy"] += character.diplomacy
			total_stats["caravan_guarding"] += character.caravan_guarding
			total_stats["escorting"] += character.escorting
			total_stats["stealth"] += character.stealth
			total_stats["odd_jobs"] += character.odd_jobs
			
			# Check class coverage
			match character.character_class:
				Character.CharacterClass.TANK:
					has_tank = true
				Character.CharacterClass.HEALER:
					has_healer = true
				Character.CharacterClass.SUPPORT:
					has_support = true
				Character.CharacterClass.ATTACKER:
					has_attacker = true
	
	# Add class coverage (1 if we have the class, 0 if not)
	total_stats["required_tank"] = 1 if has_tank else 0
	total_stats["required_healer"] = 1 if has_healer else 0
	total_stats["required_support"] = 1 if has_support else 0
	total_stats["required_attacker"] = 1 if has_attacker else 0
	
	return total_stats

func update_available_characters_display(available_chars: Array):
	"""Update the available characters display"""
	# Clear existing panels
	for child in guild_roster_grid.get_children():
		child.queue_free()
	
	# Create new panels for each available character
	for character in available_chars:
		var char_panel = create_party_selection_panel(character)
		guild_roster_grid.add_child(char_panel)

func update_start_quest_button_state():
	"""Update the start quest button state based on current party and quest"""
	if not current_selected_quest:
		return
	
	var assignment_check = current_selected_quest.can_assign_party(current_party)
	start_quest_button.disabled = not assignment_check.can_assign
	start_quest_button.text = "Start Quest" if assignment_check.can_assign else "Cannot Start: " + str(assignment_check.reasons[0] if not assignment_check.reasons.is_empty() else "Unknown")

func create_party_selection_panel(character: Character) -> Control:
	"""Create a party selection panel for a character"""
	# Create a panel for the character in the grid - icon only design
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(64, 64)
	
	# Make panel clickable for selection
	var button = Button.new()
	button.flat = true
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(func(): toggle_character_in_party(character))
	panel.add_child(button)
	
	# Add character portrait
	var portrait = TextureRect.new()
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.expand_mode = TextureRect.EXPAND_FILL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Load character portrait based on class and gender
	var portrait_path = character.get_portrait_path()
	if ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path)
	else:
		# Use a default portrait or placeholder
		portrait.modulate = Color.GRAY
	
	button.add_child(portrait)
	
	# Store character reference
	panel.set_meta("character", character)
	
	# Update visual state
	update_party_selection_panel_state(panel, character)
	
	return panel

func toggle_character_in_party(character: Character):
	"""Toggle a character in/out of the current party"""
	if current_party.has(character):
		current_party.erase(character)
	else:
		# Check if we can add this character
		if current_selected_quest and current_party.size() < current_selected_quest.max_party_size:
			current_party.append(character)
	
	# Update displays
	update_party_selection_display()
	update_party_selection_panel_states()

func update_party_selection_panel_states():
	"""Update visual states of all party selection panels"""
	for child in guild_roster_grid.get_children():
		if child.has_meta("character"):
			var character = child.get_meta("character")
			update_party_selection_panel_state(child, character)

func update_party_selection_panel_state(panel: Control, character: Character):
	"""Update the visual state of a party selection panel"""
	var is_in_party = current_party.has(character)
	
	# Update panel appearance based on selection state
	if is_in_party:
		panel.modulate = Color.GREEN
	else:
		panel.modulate = Color.WHITE

# Signal handlers
func _on_quest_started(quest: Quest):
	"""Handle when a quest is started"""
	# Refresh quest display
	update_room_display()

func _on_quest_completed(quest: Quest):
	"""Handle when a quest is completed"""
	# Refresh quest display
	update_room_display()

func _on_start_quest_button_pressed():
	"""Handle start quest button press"""
	if current_selected_quest and not current_party.is_empty():
		GuildManager.start_quest(current_selected_quest, current_party)
		# Reset to default state after starting quest
		reset_quest_tab_to_default()

func save_room_state():
	"""Save quests room state"""
	# Save current quest selection and party
	pass  # TODO: Implement if needed

func load_room_state():
	"""Load quests room state"""
	# Restore quest selection and party if available
	pass  # TODO: Implement if needed
