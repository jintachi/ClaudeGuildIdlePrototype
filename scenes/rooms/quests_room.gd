class_name QuestsRoom
extends BaseRoom



# Quests-specific UI elements
@export var available_quests_list: VBoxContainer
@export var quest_details_panel: VBoxContainer
@export var start_quest_button: Button
@export var quest_info_label: Label
@export var stats_comparison_table: VBoxContainer
@export var guild_roster_grid: GridContainer
@export var quest_card:PackedScene


# Quest and party state
var current_selected_quest_card: CompactQuestCard = null
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
		GuildManager.quest_card_moved.connect(_on_quest_card_moved)
		SignalBus.quest_card_selected.connect(_on_quest_card_selected)
	
	# Connect UI buttons
	if start_quest_button:
		start_quest_button.pressed.connect(_on_start_quest_button_pressed)

func on_room_entered():
	"""Called when entering the quests room"""
	update_room_display()

func on_room_exited():
	"""Called when exiting the quests room"""
	# Remove quest cards from UI but don't destroy them
	for child in available_quests_list.get_children():
		if child is CompactQuestCard:
			available_quests_list.remove_child(child)
	
	# Clear selection
	current_selected_quest_card = null
	current_party.clear()

func update_room_display():
	"""Update the quests display"""
	print("we're updating the quest display")
	update_quests_display()
	
	# Clear quest details if no quest is selected
	if not current_selected_quest_card and quest_details_panel:
		for child in quest_details_panel.get_children():
			child.queue_free()
		
		# Add placeholder text
		var placeholder = Label.new()
		placeholder.text = "Select a quest to view details"
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		placeholder.add_theme_color_override("font_color", Color.GRAY)
		quest_details_panel.add_child(placeholder)

func update_quests_display():
	"""Update the quests display with all available quests"""
	print("DEBUG: update_quests_display() called")
	
	var quest_cards = GuildManager.get_available_quest_cards()
	print("DEBUG: Got " + str(quest_cards.size()) + " quest cards from GuildManager")
	
	for quest_card in quest_cards:
		
		if not available_quests_list.get_children().has(quest_card) :
			print("DEBUG: Adding quest card to UI: " + str(quest_card))
			available_quests_list.add_child(quest_card)
			print("DEBUG: Added quest card to UI: " + str(quest_card))
		else : print("DEBUG: Card already added to list, skipping~")
	
	# Wait a frame for the panels to be added to the scene tree
	await get_tree().process_frame
	
	if current_selected_quest_card:
		update_quest_panel_states(current_selected_quest_card)
	else : current_selected_quest_card = GuildManager.get_available_quest_cards()[0]
	

func update_quest_details_display(card:CompactQuestCard):
	"""Update the detailed quest view in the middle panel"""
	if not quest_details_panel or not current_selected_quest_card or not card:
		return
	
	# Clear existing content
	for child in quest_details_panel.get_children():
		child.queue_free()
	
	var quest = current_selected_quest_card.get_quest()
	
	# Create detailed quest view
	var vbox = VBoxContainer.new()
	quest_details_panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	
	# Quest header
	var header_container = HBoxContainer.new()
	vbox.add_child(header_container)
	
	var rank_label = Label.new()
	rank_label.text = "[%s]" % quest.get_rank_name()
	rank_label.add_theme_font_size_override("font_size", 16)
	rank_label.add_theme_color_override("font_color", Color.WHITE)
	header_container.add_child(rank_label)
	
	var title_label = Label.new()
	title_label.text = quest.quest_name
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_container.add_child(title_label)
	
	# Separator
	var separator1 = HSeparator.new()
	vbox.add_child(separator1)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = quest.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(desc_label)
	
	# Separator
	var separator2 = HSeparator.new()
	vbox.add_child(separator2)
	
	# Key metrics
	var metrics_container = VBoxContainer.new()
	vbox.add_child(metrics_container)
	
	# Duration
	var duration_label = Label.new()
	var minutes = int(quest.duration / 60)
	var seconds = int(quest.duration) % 60
	duration_label.text = "⏱️ Duration: %d minutes %d seconds" % [minutes, seconds]
	duration_label.add_theme_font_size_override("font_size", 12)
	metrics_container.add_child(duration_label)
	
	# Party size
	var party_label = Label.new()
	party_label.text = "👥 Party Size: %d-%d members" % [quest.min_party_size, quest.max_party_size]
	party_label.add_theme_font_size_override("font_size", 12)
	metrics_container.add_child(party_label)
	
	# Separator
	var separator3 = HSeparator.new()
	vbox.add_child(separator3)
	
	# Class requirements
	var class_req_label = Label.new()
	class_req_label.text = "🛡️ Class Requirements:"
	class_req_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(class_req_label)
	
	var class_req_container = VBoxContainer.new()
	vbox.add_child(class_req_container)
	class_req_container.add_theme_constant_override("separation", 2)
	
	if quest.required_tank:
		class_req_container.add_child(create_requirement_item("Tank: Required"))
	else:
		class_req_container.add_child(create_requirement_item("Tank: Optional"))
	
	if quest.required_healer:
		class_req_container.add_child(create_requirement_item("Healer: Required"))
	else:
		class_req_container.add_child(create_requirement_item("Healer: Optional"))
	
	if quest.required_support:
		class_req_container.add_child(create_requirement_item("Support: Required"))
	else:
		class_req_container.add_child(create_requirement_item("Support: Optional"))
	
	if quest.required_attacker:
		class_req_container.add_child(create_requirement_item("Attacker: Required"))
	else:
		class_req_container.add_child(create_requirement_item("Attacker: Optional"))
	
	# Separator
	var separator4 = HSeparator.new()
	vbox.add_child(separator4)
	
	# Stat requirements
	var stat_req_label = Label.new()
	stat_req_label.text = "📊 Stat Requirements:"
	stat_req_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(stat_req_label)
	
	var stat_req_container = VBoxContainer.new()
	vbox.add_child(stat_req_container)
	stat_req_container.add_theme_constant_override("separation", 2)
	
	if quest.min_total_health > 0:
		stat_req_container.add_child(create_requirement_item("Total Health: %d+" % quest.min_total_health))
	if quest.min_total_defense > 0:
		stat_req_container.add_child(create_requirement_item("Total Defense: %d+" % quest.min_total_defense))
	if quest.min_total_attack_power > 0:
		stat_req_container.add_child(create_requirement_item("Total Attack Power: %d+" % quest.min_total_attack_power))
	if quest.min_total_spell_power > 0:
		stat_req_container.add_child(create_requirement_item("Total Spell Power: %d+" % quest.min_total_spell_power))
	if quest.min_substat_requirement > 0:
		stat_req_container.add_child(create_requirement_item("%s Skill: %d+" % [quest.get_substat_name_for_quest_type().capitalize(), quest.min_substat_requirement]))
	
	if stat_req_container.get_child_count() == 0:
		stat_req_container.add_child(create_requirement_item("No stat requirements"))
	
	# Separator
	var separator5 = HSeparator.new()
	vbox.add_child(separator5)
	
	# Rewards
	var rewards_label = Label.new()
	rewards_label.text = "💰 Rewards:"
	rewards_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(rewards_label)
	
	var rewards_container = VBoxContainer.new()
	vbox.add_child(rewards_container)
	rewards_container.add_theme_constant_override("separation", 2)
	
	rewards_container.add_child(create_requirement_item("Experience: %d XP" % quest.base_experience))
	rewards_container.add_child(create_requirement_item("Gold: %d" % quest.gold_reward))
	rewards_container.add_child(create_requirement_item("Influence: %d" % quest.influence_reward))
	
	if quest.building_materials > 0:
		rewards_container.add_child(create_requirement_item("Building Materials: %d" % quest.building_materials))
	if quest.armor_pieces > 0:
		rewards_container.add_child(create_requirement_item("Armor Pieces: %d" % quest.armor_pieces))
	if quest.weapons > 0:
		rewards_container.add_child(create_requirement_item("Weapons: %d" % quest.weapons))
	if quest.food > 0:
		rewards_container.add_child(create_requirement_item("Food: %d" % quest.food))

func create_requirement_item(text: String) -> Label:
	"""Create a requirement item label"""
	var label = Label.new()
	label.text = "  • " + text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	return label

func update_quest_panel_states(selected_card: CompactQuestCard):
	"""Update visual states of all quest panels"""
	# Find all quest panels and update their states
	for child in available_quests_list.get_children():
		if child.has_method("set_selected") and child.has_method("set_success_rate"):
			var quest_card = child
			var quest = quest_card.get_quest()
			
			# Set selection state using the component's method
			quest_card.set_selected(quest == selected_card.get_quest())
			
			# Show/hide success rate based on selection
			if quest == selected_card.get_quest():
				# Calculate and show success rate for selected quest
				quest.calculate_success_rate()
				
				var success_rate = quest.success_rate
				quest_card.set_success_rate(success_rate)
			else:
				# Hide success rate for unselected quests
				quest_card.set_success_rate(-1)

func _on_quest_card_selected(card: CompactQuestCard):
	"""Handle when a quest card is selected"""
	print("DEBUG: _on_quest_card_selected() called with card: " + str(card))
	
	if card:
		print("Quest Card Selected: " + str(card))
		
		# Update selection state
		current_selected_quest_card = card
		
		# Update visual states for all quest cards
		for quest_card in GuildManager.get_available_quest_cards():
			quest_card.set_selected(quest_card == card)
		
		# Update displays
		update_quest_details_display(card)
		update_party_selection_display()

	else:
		print("DEBUG: No quest card provided")

func reset_quest_tab_to_default():
	"""Reset the quest tab to its default state with no quest selected"""
	# Clear current selections
	current_selected_quest_card = GuildManager.get_available_quest_cards()[0]
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
	if not current_selected_quest_card:
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
	if not stats_comparison_table or not current_selected_quest_card:
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
	"""Update success chance displays for all quest panels"""
	if not current_selected_quest_card:
		return
		
	# Update success chances for all quest cards
	for child in available_quests_list.get_children():
		if child.has_method("set_success_rate"):
			var quest_card = child
			var quest = quest_card.get_quest()
			
			if quest == current_selected_quest_card.get_quest():
				# Calculate success chance for selected quest with current party
				var success_chance = quest.get_suggested_success_chance(current_party)
				quest_card.set_success_rate(success_chance)
			else:
				# Hide success rate for unselected quests
				quest_card.set_success_rate(-1)

func get_quest_stat_requirements() -> Dictionary:
	"""Extract stat requirements from the current quest"""
	if not current_selected_quest_card:
		return {}
	
	var quest = current_selected_quest_card.get_quest()
	
	var requirements = {}
	
	# Core stats
	if quest.min_total_health > 0:
		requirements["health"] = quest.min_total_health
	if quest.min_total_defense > 0:
		requirements["defense"] = quest.min_total_defense
	if quest.min_total_attack_power > 0:
		requirements["attack_power"] = quest.min_total_attack_power
	if quest.min_total_spell_power > 0:
		requirements["spell_power"] = quest.min_total_spell_power
	
	# Class requirements (use 1 for true, 0 for false)
	if quest.required_tank:
		requirements["required_tank"] = 1
	if quest.required_healer:
		requirements["required_healer"] = 1
	if quest.required_support:
		requirements["required_support"] = 1
	if quest.required_attacker:
		requirements["required_attacker"] = 1
	
	# Sub-stats from quest type
	if quest.min_substat_requirement > 0:
		match quest.quest_type:
			Quest.QuestType.GATHERING:
				requirements["gathering"] = quest.min_substat_requirement
			Quest.QuestType.HUNTING_TRAPPING:
				requirements["hunting_trapping"] = quest.min_substat_requirement
			Quest.QuestType.DIPLOMACY:
				requirements["diplomacy"] = quest.min_substat_requirement
			Quest.QuestType.CARAVAN_GUARDING:
				requirements["caravan_guarding"] = quest.min_substat_requirement
			Quest.QuestType.ESCORTING:
				requirements["escorting"] = quest.min_substat_requirement
			Quest.QuestType.STEALTH:
				requirements["stealth"] = quest.min_substat_requirement
			Quest.QuestType.ODD_JOBS:
				requirements["odd_jobs"] = quest.min_substat_requirement
	
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
	if not current_selected_quest_card:
		return
	
	var quest = current_selected_quest_card.get_quest()
	var assignment_check = quest.can_assign_party(current_party)
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
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Load character portrait based on class and gender
	var portrait_path = character.portrait_path
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
		if current_selected_quest_card and current_party.size() < current_selected_quest_card.get_quest().max_party_size:
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

func _on_quest_card_moved(quest: Quest, from_state: String, to_state: String):
	"""Handle when a quest card is moved between states"""
	# If a quest card is moved from available to active, remove it from this room's display
	if from_state == "available":
		# Find and remove the quest card from available quests list
		for child in available_quests_list.get_children():
			if child is CompactQuestCard and child.get_quest() == quest:
				available_quests_list.remove_child(child)
				break
		
		# Clear selection if the moved quest was selected
		if current_selected_quest_card and current_selected_quest_card.get_quest() == quest:
			current_selected_quest_card = null
			reset_quest_tab_to_default()
	
	# If a new replacement quest was added, we'll get that through update_room_display

func _on_start_quest_button_pressed():
	"""Handle start quest button press"""
	if current_selected_quest_card and not current_party.is_empty():
		var quest_result = GuildManager.start_quest(current_selected_quest_card, current_party)
		if quest_result.success:
			# Reset to default state after starting quest
			reset_quest_tab_to_default()
			# Update the display to show replacement quest
			update_room_display()

func save_room_state():
	"""Save quests room state"""
	# Save current quest selection and party
	pass  # TODO: Implement if needed

func load_room_state():
	"""Load quests room state"""
	# Restore quest selection and party if available
	pass  # TODO: Implement if needed
