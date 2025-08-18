class_name Main
extends Control

#region Setup and Initialization
# Guild Manager is now a global singleton

# UI Containers
@export var main_hall_container: Control
@export var roster_container: Control
@export var quests_container: Control
@export var recruitment_container: Control
@export var town_map_container: Control

# Main Hall Elements
@export var resources_display: Label
@export var active_quests_panel: VBoxContainer
@export var promotion_panel: VBoxContainer

# Navigation Buttons
@export var roster_button: Button
@export var quests_button: Button
@export var recruitment_button: Button
@export var town_map_button: Button

# Tab Navigation
@export var back_to_hall_roster: Button
@export var back_to_hall_quests: Button
@export var back_to_hall_recruitment: Button
@export var back_to_hall_town: Button

# Roster Tab Elements
@export var roster_list: VBoxContainer

# Quests Tab Elements
@export var available_quests_list: VBoxContainer
@export var party_selection_panel: Control
@export var party_list: VBoxContainer
@export var start_quest_button: Button
@export var quest_info_label: Label
@export var quest_requirements_panel: HBoxContainer
@export var current_party_stats_panel: HBoxContainer
@export var assigned_members_panel: VBoxContainer

# Recruitment Tab Elements
@export var available_recruits_list: VBoxContainer
@export var refresh_recruits_button: Button
@export var recruit_button: Button
@export var current_resources_panel: VBoxContainer
@export var cost_panel: VBoxContainer
@export var projected_resources_panel: VBoxContainer
@export var selected_recruit_info_panel: VBoxContainer

# Save/Load Buttons
@export var save_button: Button
@export var load_button: Button
@export var new_game_button: Button

# Current state
var current_selected_quest: Quest = null
var current_party: Array[Character] = []
var current_selected_recruit: Character = null
var selected_recruit_panel: Control = null

func _ready():
	setup_ui_connections()
	setup_signal_connections()
	show_main_hall()
	update_ui()
#endregion

#region UI Utilities
func setup_ui_connections():
	# Navigation
	roster_button.pressed.connect(show_roster_tab)
	quests_button.pressed.connect(show_quests_tab)
	recruitment_button.pressed.connect(show_recruitment_tab)
	town_map_button.pressed.connect(show_town_map)
	
	back_to_hall_roster.pressed.connect(show_main_hall)
	back_to_hall_quests.pressed.connect(show_main_hall)
	back_to_hall_recruitment.pressed.connect(show_main_hall)
	back_to_hall_town.pressed.connect(show_main_hall)
	
	# Quests
	start_quest_button.pressed.connect(_on_start_quest_pressed)
	
	# Recruitment
	refresh_recruits_button.pressed.connect(_on_refresh_recruits_pressed)
	recruit_button.pressed.connect(_on_recruit_selected_character)
	
	# Save/Load
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)

func setup_signal_connections():
	# Connect to SignalBus signals
	SignalBus.character_recruited.connect(_on_character_recruited)
	SignalBus.quest_started.connect(_on_quest_started)
	SignalBus.quest_completed.connect(_on_quest_completed)
	SignalBus.emergency_quest_available.connect(_on_emergency_quest_available)
	
	# Connect to GuildManager signals
	GuildManager.character_recruited.connect(_on_guild_manager_character_recruited)
	GuildManager.quest_started.connect(_on_guild_manager_quest_started)
	GuildManager.quest_completed.connect(_on_guild_manager_quest_completed)
	GuildManager.emergency_quest_available.connect(_on_guild_manager_emergency_quest)

func _process(_delta):
	update_active_quests_display()
#endregion

#region Navigation
func show_main_hall():
	hide_all_tabs()
	main_hall_container.visible = true
	update_main_hall_display()

func show_roster_tab():
	hide_all_tabs()
	roster_container.visible = true
	update_roster_display()

func show_quests_tab():
	hide_all_tabs()
	quests_container.visible = true
	party_selection_panel.visible = true
	update_quests_display()

func show_recruitment_tab():
	hide_all_tabs()
	recruitment_container.visible = true
	update_recruitment_display()

func show_town_map():
	hide_all_tabs()
	town_map_container.visible = true
	update_town_map_display()

func hide_all_tabs():
	main_hall_container.visible = false
	roster_container.visible = false
	quests_container.visible = false
	recruitment_container.visible = false
	town_map_container.visible = false

func update_ui():
	update_resources_display()
	update_main_hall_display()
#endregion

#region Main Hall
func update_resources_display():
	var resources = GuildManager.get_guild_status_summary().resources
	resources_display.text = "Influence: %d | Gold: %d | Food: %d | Materials: %d | Armor: %d | Weapons: %d" % [
		resources.influence, resources.gold, resources.food, 
		resources.building_materials, resources.armor, resources.weapons
	]

func update_main_hall_display():
	update_resources_display()
	update_active_quests_display()
	update_promotion_display()

func update_active_quests_display():
	# Clear existing displays
	for child in active_quests_panel.get_children():
		child.queue_free()
	
	for quest in GuildManager.active_quests:
		var quest_panel = create_active_quest_panel(quest)
		active_quests_panel.add_child(quest_panel)

func create_active_quest_panel(quest: Quest) -> Control:
	
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(300, 150)	
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	
	
	# Quest title
	var title = Label.new()
	title.text = quest.quest_name
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)
	
	# Progress bar
	var progress_bar = ProgressBar.new()
	progress_bar.max_value = 100
	progress_bar.value = quest.get_progress_percentage()
	vbox.add_child(progress_bar)
	
	# Time remaining
	var time_label = Label.new()
	var time_remaining = quest.get_time_remaining()
	var minutes = int(time_remaining / 60)
	var seconds = int(time_remaining) % 60
	time_label.text = "Time remaining: %02d:%02d" % [minutes, seconds]
	vbox.add_child(time_label)
	
	# Party status
	var party_info = quest.get_party_display_info()
	var party_label = Label.new()
	var party_text = "Party: "
	for member in party_info:
		party_text += "%s(%s)%s " % [member.name, member.class, member.status]
	party_label.text = party_text
	vbox.add_child(party_label)
	
	return panel
#endregion

#region Guild Master's Room
func update_promotion_display():
	# Clear existing displays
	for child in promotion_panel.get_children():
		child.queue_free()
	
	var characters_needing_promotion = GuildManager.get_characters_needing_promotion()
	for character in characters_needing_promotion:
		var promo_panel = create_promotion_panel(character)
		promotion_panel.add_child(promo_panel)

func create_promotion_panel(character: Character) -> Control:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(250, 60)
	
	var hbox = HBoxContainer.new()
	panel.add_child(hbox)
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var info = Label.new()
	info.text = "%s (%s) ready for promotion to %s" % [
		character.character_name, 
		character.get_class_name(),
		Character.Rank.keys()[character.rank + 1] if character.rank < Character.Rank.SSS else "MAX"
	]
	hbox.add_child(info)
	
	var promote_button = Button.new()
	promote_button.text = "Promote"
	promote_button.pressed.connect(func(): start_promotion_quest(character))
	hbox.add_child(promote_button)
	
	return panel

func start_promotion_quest(character: Character):
	# Create a promotion quest specific to the character
	var promotion_quest = create_promotion_quest_for_character(character)
	GuildManager.available_quests.append(promotion_quest)
	print("Promotion quest created for ", character.character_name)

func create_promotion_quest_for_character(character: Character) -> Quest:
	var quest = Quest.new()
	quest.quest_type = Quest.QuestType.EMERGENCY
	quest.quest_rank = Quest.QuestRank.values()[min(character.rank + 1, Quest.QuestRank.S)]
	quest.quest_name = "Promotion Quest: %s" % character.character_name
	quest.allow_partial_failure = false
	quest.min_party_size = 1
	quest.max_party_size = 1
	quest.duration = 120.0  # 2 minutes for promotion
	
	match character.character_class:
		Character.CharacterClass.ATTACKER:
			quest.description = "Defeat a powerful enemy solo to prove your combat prowess."
			quest.min_total_attack_power = character.attack_power
		Character.CharacterClass.TANK:
			quest.description = "Defend a location against overwhelming odds."
			quest.min_total_defense = character.defense
			quest.min_total_health = character.health
		Character.CharacterClass.HEALER:
			quest.description = "Save lives in a difficult medical emergency."
			quest.min_total_spell_power = character.spell_power
			quest.min_total_mana = character.mana
		Character.CharacterClass.SUPPORT:
			quest.description = "Complete a challenging diplomatic mission."
			quest.min_substat_requirement = character.diplomacy
	
	quest.base_experience = 100
	quest.gold_reward = 50
	quest.influence_reward = 25
	
	return quest
#endregion

#region Roster Counter
#TODO : Update the Roster Display Properly to display members actively on quests.  Once a quest is complete, make the character available again.  Also display current Injuries on the characters.  Update panel sizes as wellsq
func update_roster_display():
	# Clear existing displays
	for child in roster_list.get_children():
		child.queue_free()
	
	for character in GuildManager.roster:
		var char_panel = create_character_panel(character)
		roster_list.add_child(char_panel)

func create_character_panel(character: Character) -> Control:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(400, 120)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 3)
	
	# Name and class
	var name_label = Label.new()
	var stars = "★".repeat(character.quality)
	name_label.text = "%s (%s) %s - Level %d [%s Rank]" % [
		character.character_name, character.get_class_name(), stars,
		character.level, character.get_rank_name()
	]
	name_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(name_label)
	
	# Stats
	var stats_label = Label.new()
	stats_label.text = "HP:%d DEF:%d ATK:%d SPL:%d MNA:%d SPD:%d LCK:%d" % [
		character.health, character.defense, character.attack_power,
		character.spell_power, character.mana, character.movement_speed, character.luck
	]
	vbox.add_child(stats_label)
	
	# Substats
	var substats_label = Label.new()
	var substat_text = "Skills: "
	var skills = []
	if character.gathering > 0: skills.append("Gathering:%d" % character.gathering)
	if character.hunting_trapping > 0: skills.append("Hunting:%d" % character.hunting_trapping)
	if character.diplomacy > 0: skills.append("Diplomacy:%d" % character.diplomacy)
	if character.caravan_guarding > 0: skills.append("Caravan:%d" % character.caravan_guarding)
	if character.escorting > 0: skills.append("Escort:%d" % character.escorting)
	if character.stealth > 0: skills.append("Stealth:%d" % character.stealth)
	if character.odd_jobs > 0: skills.append("OddJobs:%d" % character.odd_jobs)
	
	substats_label.text = substat_text + (", ".join(skills) if not skills.is_empty() else "None")
	vbox.add_child(substats_label)
	
	# Status
	var status_label = Label.new()
	if character.is_injured():
		var injury_duration = character.get_injury_duration()
		var injury_minutes:int = injury_duration / 60
		var injury_seconds:float = injury_duration - (injury_minutes * 60)
		var display_inj = str(injury_minutes, ": ", injury_seconds)
		status_label.text = "INJURED - %s, %s" % [get_injury_name(character.injury_type), display_inj]
		status_label.modulate = Color.RED
	elif character.is_on_quest:
		status_label.text = "ON QUEST"
		status_label.modulate = Color.YELLOW
	elif character.promotion_quest_available:
		status_label.text = "READY FOR PROMOTION"
		status_label.modulate = Color.GREEN
	else:
		status_label.text = "AVAILABLE"
		status_label.modulate = Color.WHITE
	
	vbox.add_child(status_label)
	
	return panel

func get_injury_name(injury_type: Character.InjuryType) -> String:
	match injury_type:
		Character.InjuryType.PHYSICAL_WOUND: return "Physical Wound"
		Character.InjuryType.MENTAL_TRAUMA: return "Mental Trauma"
		Character.InjuryType.CURSED_AFFLICTION: return "Cursed"
		Character.InjuryType.EXHAUSTION: return "Exhausted"
		Character.InjuryType.POISON: return "Poisoned"
		_: return "Unknown"
#endregion

#region Quest Counter
func update_quests_display():
	# Clear existing displays
	for child in available_quests_list.get_children():
		child.queue_free()
	
	for quest in GuildManager.available_quests:
		var quest_panel = create_quest_panel(quest)
		available_quests_list.add_child(quest_panel)

func create_quest_panel(quest: Quest) -> Control:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(450, 210)
	
	# Set anchors to full rect
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Or if in a container, set size flags
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 3)
	
	# Select button
	var select_button = Button.new()
	select_button.text = "Select Quest"
	select_button.pressed.connect(func(): select_quest(quest))
	vbox.add_child(select_button)
	
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
	
	return panel

func select_quest(quest: Quest):
	current_selected_quest = quest
	current_party.clear()
	update_party_selection_display()

func update_party_selection_display():
	if not current_selected_quest:
		return
	
	# Make single call to get available characters
	var available_chars = GuildManager.get_available_characters()
	
	# Update party selection panel with optimized data flow
	update_party_selection_right_panel(available_chars)

func update_party_selection_right_panel(available_chars: Array):
	# Clear existing displays
	for child in party_list.get_children():
		child.queue_free()
	for child in quest_requirements_panel.get_children():
		child.queue_free()
	for child in current_party_stats_panel.get_children():
		child.queue_free()
	for child in assigned_members_panel.get_children():
		child.queue_free()
	
	# Update quest info
	quest_info_label.text = current_selected_quest.description
	
	# Display quest requirements and current party stats comparison
	update_quest_requirements_display()
	update_current_party_stats_display()
	
	# Display available characters
	update_available_characters_display(available_chars)
	
	# Display current party in dedicated panel
	update_assigned_members_display()
	
	# Update start button state
	update_start_quest_button_state()

func update_quest_requirements_display():
	# Add title
	var title = Label.new()
	title.text = "Quest Requirements:"
	title.add_theme_font_size_override("font_size", 12)
	title.modulate = Color.YELLOW
	quest_requirements_panel.add_child(title)
	
	var sep = VSeparator.new()
	quest_requirements_panel.add_child(sep)
	
	# Add stat requirements
	var requirements = []
	if current_selected_quest.min_total_health > 0:
		requirements.append("HP: %d+" % current_selected_quest.min_total_health)
	if current_selected_quest.min_total_defense > 0:
		requirements.append("DEF: %d+" % current_selected_quest.min_total_defense)
	if current_selected_quest.min_total_attack_power > 0:
		requirements.append("ATK: %d+" % current_selected_quest.min_total_attack_power)
	if current_selected_quest.min_total_spell_power > 0:
		requirements.append("SPL: %d+" % current_selected_quest.min_total_spell_power)
	
	for req in requirements:
		var label = Label.new()
		label.text = req
		label.add_theme_font_size_override("font_size", 10)
		quest_requirements_panel.add_child(label)
		
		var separator = VSeparator.new()
		quest_requirements_panel.add_child(separator)
	
	# Add class requirements
	var class_requirements = []
	if current_selected_quest.required_tank:
		class_requirements.append({"text": "Tank", "color": Color.ORANGE})
	if current_selected_quest.required_healer:
		class_requirements.append({"text": "Healer", "color": Color.GREEN})
	if current_selected_quest.required_support:
		class_requirements.append({"text": "Support", "color": Color.BLUE})
	if current_selected_quest.required_attacker:
		class_requirements.append({"text": "Attacker", "color": Color.RED})
	
	for class_req in class_requirements:
		var label = Label.new()
		label.text = class_req.text
		label.modulate = class_req.color
		label.add_theme_font_size_override("font_size", 10)
		quest_requirements_panel.add_child(label)

func update_current_party_stats_display():
	# Add title
	var title = Label.new()
	title.text = "Current Party:"
	title.add_theme_font_size_override("font_size", 12)
	title.modulate = Color.CYAN
	current_party_stats_panel.add_child(title)
	
	var sep = VSeparator.new()
	current_party_stats_panel.add_child(sep)
	
	if current_party.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No members assigned"
		empty_label.modulate = Color.GRAY
		empty_label.add_theme_font_size_override("font_size", 10)
		current_party_stats_panel.add_child(empty_label)
		return
	
	# Get current party stats
	var party_stats = current_selected_quest.calculate_party_stats(current_party)
	
	# Show stat totals with color coding
	var stats = [
		{"name": "HP", "current": party_stats.health, "required": current_selected_quest.min_total_health},
		{"name": "DEF", "current": party_stats.defense, "required": current_selected_quest.min_total_defense},
		{"name": "ATK", "current": party_stats.attack_power, "required": current_selected_quest.min_total_attack_power},
		{"name": "SPL", "current": party_stats.spell_power, "required": current_selected_quest.min_total_spell_power}
	]
	
	for stat in stats:
		if stat.required > 0:  # Only show stats that are required
			var label = Label.new()
			label.text = "%s: %d" % [stat.name, stat.current]
			label.add_theme_font_size_override("font_size", 10)
			
			# Color code: Green if sufficient, Red if insufficient
			if stat.current >= stat.required:
				label.modulate = Color.GREEN
			else:
				label.modulate = Color.RED
			
			current_party_stats_panel.add_child(label)
			
			var separator = VSeparator.new()
			current_party_stats_panel.add_child(separator)
	
	# Show class coverage with color coding
	var has_tank = false
	var has_healer = false
	var has_support = false
	var has_attacker = false
	
	for character in current_party:
		match character.character_class:
			Character.CharacterClass.TANK: has_tank = true
			Character.CharacterClass.HEALER: has_healer = true
			Character.CharacterClass.SUPPORT: has_support = true
			Character.CharacterClass.ATTACKER: has_attacker = true
	
	var class_checks = [
		{"required": current_selected_quest.required_tank, "has": has_tank, "name": "Tank", "color": Color.ORANGE},
		{"required": current_selected_quest.required_healer, "has": has_healer, "name": "Healer", "color": Color.GREEN},
		{"required": current_selected_quest.required_support, "has": has_support, "name": "Support", "color": Color.BLUE},
		{"required": current_selected_quest.required_attacker, "has": has_attacker, "name": "Attacker", "color": Color.RED}
	]
	
	for class_check in class_checks:
		if class_check.required:
			var label = Label.new()
			label.text = class_check.name
			label.add_theme_font_size_override("font_size", 10)
			
			# Color: Bright if we have it, Red if missing
			if class_check.has:
				label.modulate = class_check.color
			else:
				label.modulate = Color.RED
				label.text += " MISSING"
			
			current_party_stats_panel.add_child(label)

func update_available_characters_display(available_chars: Array):
	for character in available_chars:
		var char_panel = create_party_selection_panel(character)
		party_list.add_child(char_panel)

func update_assigned_members_display():
	if current_party.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No members assigned yet"
		empty_label.modulate = Color.GRAY
		assigned_members_panel.add_child(empty_label)
	else:
		# Show current party stats summary
		var stats_summary = current_selected_quest.calculate_party_stats(current_party)
		var stats_label = Label.new()
		stats_label.text = "Party Total: HP:%d DEF:%d ATK:%d SPL:%d" % [
			stats_summary.health, stats_summary.defense, 
			stats_summary.attack_power, stats_summary.spell_power
		]
		stats_label.add_theme_font_size_override("font_size", 10)
		
		# Color code based on requirements
		var assignment_check = current_selected_quest.can_assign_party(current_party)
		stats_label.modulate = Color.GREEN if assignment_check.can_assign else Color.RED
		assigned_members_panel.add_child(stats_label)
		
		# Show individual party members
		for character in current_party:
			var party_member_panel = create_party_member_panel(character)
			assigned_members_panel.add_child(party_member_panel)

# Keep this for backwards compatibility with existing party list
func update_current_party_display():
	var party_label = Label.new()
	party_label.text = "\n--- CURRENT PARTY ---"
	party_label.add_theme_font_size_override("font_size", 12)
	party_list.add_child(party_label)
	
	if current_party.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No characters selected"
		empty_label.modulate = Color.GRAY
		party_list.add_child(empty_label)
	else:
		for character in current_party:
			var party_member_panel = create_party_member_panel(character)
			party_list.add_child(party_member_panel)

func update_start_quest_button_state():
	var assignment_check = current_selected_quest.can_assign_party(current_party)
	start_quest_button.disabled = not assignment_check.can_assign
	start_quest_button.text = "Start Quest" if assignment_check.can_assign else "Cannot Start: " + str(assignment_check.reasons[0] if not assignment_check.reasons.is_empty() else "Unknown")

func create_party_selection_panel(character: Character) -> Control:
	var hbox = HBoxContainer.new()
	
	var info_label = Label.new()
	info_label.text = "%s (%s) Lvl %d" % [character.character_name, character.get_class_name(), character.level]
	info_label.custom_minimum_size.x = 200
	hbox.add_child(info_label)
	
	var add_button = Button.new()
	add_button.text = "Add to Party"
	add_button.disabled = character in current_party or current_party.size() >= 4
	add_button.pressed.connect(func(): add_to_party(character))
	hbox.add_child(add_button)
	
	return hbox

func create_party_member_panel(character: Character) -> Control:
	var hbox = HBoxContainer.new()
	
	hbox.size_flags_horizontal = Control.SIZE_EXPAND
	
	var info_label = Label.new()
	info_label.text = "%s (%s) Lvl %d" % [character.character_name, character.get_class_name(), character.level]
	info_label.custom_minimum_size.x = 200
	hbox.add_child(info_label)
	
	var remove_button = Button.new()
	remove_button.text = "Remove"
	remove_button.pressed.connect(func(): remove_from_party(character))
	hbox.add_child(remove_button)
	
	return hbox

func add_to_party(character: Character):
	if character not in current_party and current_party.size() < 4:
		current_party.append(character)
		# Use optimized update - get data once and pass it through
		var available_chars = GuildManager.get_available_characters()
		update_party_selection_right_panel(available_chars)

func remove_from_party(character: Character):
	current_party.erase(character)
	# Use optimized update - get data once and pass it through
	var available_chars = GuildManager.get_available_characters()
	update_party_selection_right_panel(available_chars)
#endregion

#region Recruitment Counter
func update_recruitment_display():
	# Clear existing displays
	for child in available_recruits_list.get_children():
		child.queue_free()
	
	for recruit in GuildManager.available_recruits:
		var recruit_panel = create_recruit_panel(recruit)
		available_recruits_list.add_child(recruit_panel)
	
	# Initialize UI state
	current_selected_recruit = null
	selected_recruit_panel = null
	update_recruitment_right_panel()

func create_recruit_panel(recruit: Character) -> Control:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(400, 100)
	
	# Make panel clickable
	var button = Button.new()
	button.flat = true
	button.custom_minimum_size = Vector2(400, 100)
	panel.add_child(button)
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(func(): select_recruit(recruit, panel))
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Character info
	var name_label = Label.new()
	var stars = "★".repeat(recruit.quality)
	name_label.text = "%s (%s) %s" % [recruit.character_name, recruit.get_class_name(), stars]
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)
	
	# Stats summary
	var stats_label = Label.new()
	stats_label.text = "HP:%d DEF:%d ATK:%d SPL:%d" % [recruit.health, recruit.defense, recruit.attack_power, recruit.spell_power]
	stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(stats_label)
	
	# Cost display
	var cost = recruit.get_recruitment_cost()
	var cost_label = Label.new()
	cost_label.text = "Cost: %d Influence, %d Gold" % [cost.influence, cost.gold]
	if cost.food > 0: cost_label.text += ", %d Food" % cost.food
	if cost.armor > 0: cost_label.text += ", %d Armor" % cost.armor
	if cost.weapons > 0: cost_label.text += ", %d Weapons" % cost.weapons
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(cost_label)
	
	return panel

func select_recruit(recruit: Character, panel: Control):
	# Deselect previous panel
	if selected_recruit_panel:
		selected_recruit_panel.modulate = Color.WHITE
	
	# Select new panel
	current_selected_recruit = recruit
	selected_recruit_panel = panel
	panel.modulate = Color(1.2, 1.2, 1.0)  # Light yellow highlight
	
	# Update right panel
	update_recruitment_right_panel()

func update_recruitment_right_panel():
	# Clear right panel children
	for child in current_resources_panel.get_children():
		child.queue_free()
	for child in projected_resources_panel.get_children():
		child.queue_free()
	for child in selected_recruit_info_panel.get_children():
		child.queue_free()
	for child in cost_panel.get_children():
		child.queue_free()
	
	# Update recruit button state
	if current_selected_recruit:
		var cost = current_selected_recruit.get_recruitment_cost()
		var can_afford = GuildManager.can_afford_cost(cost)
		var roster_full = GuildManager.roster.size() >= GuildManager.max_roster_size
		
		recruit_button.disabled = not can_afford or roster_full
		recruit_button.flat = false
		
		if roster_full:
			recruit_button.text = "Roster Full"
		elif not can_afford:
			recruit_button.text = "Cannot Afford"
		else:
			recruit_button.text = "Recruit " + current_selected_recruit.character_name
	else:
		recruit_button.disabled = true
		recruit_button.flat = true
		recruit_button.text = "Select a Recruit"
	
	# Display current resources
	update_current_resources_display(_get_resources())
	
	# Display projected resources if recruit selected
	if current_selected_recruit:
		update_projected_resources_display(_get_resources(), current_selected_recruit.get_recruitment_cost())
		update_cost_display(current_selected_recruit.get_recruitment_cost())
		update_selected_recruit_info_display()

func update_current_resources_display(resource_items: Dictionary):
	var title = Label.new()
	title.text = "Current Resources"
	title.add_theme_font_size_override("font_size", 14)
	current_resources_panel.add_child(title)
	
	for resource_name in resource_items:
		var label = Label.new()
		label.text = "%s: %s" % [resource_name, resource_items[resource_name]]
		current_resources_panel.add_child(label)

func update_cost_display(cost: Dictionary):
	var title = Label.new()
	title.text = "Recruit Cost"
	title.add_theme_font_size_override("font_size", 14)
	cost_panel.add_child(title)
	
	for resource_name in cost:
		var cost_amount = cost[resource_name]
		var label = Label.new()
		label.text = "%s: %d" % [resource_name, cost_amount]
		cost_panel.add_child(label)

func update_projected_resources_display(resource_items: Dictionary, cost: Dictionary):
	var title = Label.new()
	title.text = "After Recruitment"
	title.add_theme_font_size_override("font_size", 14)
	projected_resources_panel.add_child(title)
	
	for resource_name in resource_items:
		var current_amount = resource_items[resource_name]
		var cost_amount = cost.get(resource_name, 0)
		var remaining = current_amount - cost_amount
		var label = Label.new()
		label.text = "%s: %d" % [resource_name, remaining]
		
		# Color red if insufficient
		if remaining < 0:
			label.modulate = Color.RED
		else:
			label.modulate = Color.WHITE
			
		projected_resources_panel.add_child(label)

func update_selected_recruit_info_display():
	if not current_selected_recruit:
		return
		
	var recruit = current_selected_recruit
	
	var title = Label.new()
	title.text = "Selected Recruit"
	title.add_theme_font_size_override("font_size", 14)
	selected_recruit_info_panel.add_child(title)
	
	# Name and class
	var name_label = Label.new()
	var stars = "★".repeat(recruit.quality)
	name_label.text = "%s (%s) %s" % [recruit.character_name, recruit.get_class_name(), stars]
	selected_recruit_info_panel.add_child(name_label)
	
	# Detailed stats
	var stats_label = Label.new()
	stats_label.text = "HP:%d DEF:%d ATK:%d SPL:%d\nMNA:%d SPD:%d LCK:%d" % [
		recruit.health, recruit.defense, recruit.attack_power,
		recruit.spell_power, recruit.mana, recruit.movement_speed, recruit.luck
	]
	selected_recruit_info_panel.add_child(stats_label)
	
	# Substats
	var substats_label = Label.new()
	var substat_text = "Skills:\n"
	var skills = []
	if recruit.gathering > 0: skills.append("Gathering: %d" % recruit.gathering)
	if recruit.hunting_trapping > 0: skills.append("Hunting: %d" % recruit.hunting_trapping)
	if recruit.diplomacy > 0: skills.append("Diplomacy: %d" % recruit.diplomacy)
	if recruit.caravan_guarding > 0: skills.append("Caravan: %d" % recruit.caravan_guarding)
	if recruit.escorting > 0: skills.append("Escort: %d" % recruit.escorting)
	if recruit.stealth > 0: skills.append("Stealth: %d" % recruit.stealth)
	if recruit.odd_jobs > 0: skills.append("Odd Jobs: %d" % recruit.odd_jobs)
	
	substats_label.text = substat_text + ("\n".join(skills) if not skills.is_empty() else "None")
	selected_recruit_info_panel.add_child(substats_label)


func _get_resources() -> Dictionary :
	var resources = GuildManager.get_guild_status_summary().resources
	return resources

#endregion

#region Town Map
func update_town_map_display():
	# Clear existing map
	for child in town_map_container.get_children():
		if child != back_to_hall_town:
			child.queue_free()
	
	# Create a simple 5x5 grid for town facilities
	var grid = GridContainer.new()
	grid.columns = 5
	grid.position = Vector2(50, 50)
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	town_map_container.add_child(grid)
	
	var facilities = [
		{"name": "Guild Hall", "unlocked": true, "action": show_main_hall},
		{"name": "Roster", "unlocked": true, "action": show_roster_tab},
		{"name": "Quests", "unlocked": true, "action": show_quests_tab},
		{"name": "Recruitment", "unlocked": true, "action": show_recruitment_tab},
		{"name": "Healer's Guild", "unlocked": false, "action": null},
		{"name": "Armory", "unlocked": false, "action": null},
		{"name": "Market", "unlocked": false, "action": null},
		{"name": "Training Grounds", "unlocked": false, "action": null},
		{"name": "Library", "unlocked": false, "action": null},
		{"name": "Workshop", "unlocked": false, "action": null}
	]
	
	for i in range(25):
		var button = Button.new()
		button.custom_minimum_size = Vector2(80, 60)
		
		if i < facilities.size():
			var facility = facilities[i]
			button.text = facility.name
			button.disabled = not facility.unlocked
			if facility.action:
				button.pressed.connect(facility.action)
		else:
			button.text = "Empty"
			button.disabled = true
		
		grid.add_child(button)
#endregion

#region Signal Handlers
# SignalBus signal handlers
func _on_character_recruited(character: Character):
	print("SignalBus: Character recruited: ", character.character_name)
	update_ui()

func _on_quest_started(quest: Quest):
	print("SignalBus: Quest started: ", quest.quest_name)
	current_selected_quest = null
	current_party.clear()
	party_selection_panel.visible = false
	update_ui()

func _on_quest_completed(quest: Quest):
	print("SignalBus: Quest completed: ", quest.quest_name)
	_show_quest_completion_popup(quest)
	update_ui()

func _on_emergency_quest_available(requirements: Dictionary):
	_show_emergency_quest_popup(requirements)

# GuildManager signal handlers (relay to SignalBus)
func _on_guild_manager_character_recruited(character: Character):
	SignalBus.character_recruited.emit(character)

func _on_guild_manager_quest_started(quest: Quest):
	SignalBus.quest_started.emit(quest)

func _on_guild_manager_quest_completed(quest: Quest):
	SignalBus.quest_completed.emit(quest)

func _on_guild_manager_emergency_quest(requirements: Dictionary):
	SignalBus.emergency_quest_available.emit(requirements)

# Button signal handlers
func _on_start_quest_pressed():
	if current_selected_quest and not current_party.is_empty():
		var result = GuildManager.start_quest(current_selected_quest, current_party)
		if not result.success:
			_show_error_popup(result.message)

func _on_recruit_selected_character():
	if current_selected_recruit:
		var result = GuildManager.recruit_character(current_selected_recruit)
		if result.success:
			print(result.message)
			current_selected_recruit = null
			selected_recruit_panel = null
			update_recruitment_display()
		else:
			_show_error_popup(result.message)

func _on_refresh_recruits_pressed():
	var result = GuildManager.force_recruit_refresh()
	if result.success:
		print(result.message)
		update_recruitment_display()
	else:
		_show_error_popup(result.message)

func _on_save_pressed():
	GuildManager.save_game()
	SignalBus.game_saved.emit()
	print("Game saved!")

func _on_load_pressed():
	GuildManager.load_game()
	SignalBus.game_loaded.emit()
	update_ui()
	print("Game loaded!")

func _on_new_game_pressed():
	_show_new_game_confirmation()

# Popup functions
func _show_error_popup(message: String):
	var popup = AcceptDialog.new()
	add_child(popup)
	popup.dialog_text = message
	popup.title = "Error"
	popup.popup_centered()

func _show_quest_completion_popup(quest: Quest):
	var popup = AcceptDialog.new()
	add_child(popup)
	
	var party_info = quest.get_party_display_info()
	var success_count = 0
	var party_text = ""
	
	for member in party_info:
		party_text += "%s: %s\n" % [member.name, "SUCCESS" if member.status == "✓" else "FAILED"]
		if member.status == "✓":
			success_count += 1
	
	for _char in quest.assigned_party:
		_char.is_on_quest = false
	
	var success_rate = float(success_count) / party_info.size()
	var result_text = "QUEST COMPLETED!\n\n"
	result_text += quest.quest_name + "\n\n"
	result_text += "Party Results:\n" + party_text + "\n"
	result_text += "Overall Success: %.0f%%\n\n" % (success_rate * 100)
	result_text += "Rewards: " + quest.get_rewards_text()
	
	popup.dialog_text = result_text
	popup.title = "Quest Results"
	popup.popup_centered()

func _show_emergency_quest_popup(requirements: Dictionary):
	var popup = AcceptDialog.new()
	add_child(popup)
	
	popup.dialog_text = "EMERGENCY QUEST AVAILABLE!\n\n" + requirements.name + "\n\n" + requirements.description + "\n\nReward: " + requirements.unlock_description
	popup.title = "Emergency Quest"
	popup.popup_centered()

func _show_new_game_confirmation():
	var confirm = ConfirmationDialog.new()
	add_child(confirm)
	confirm.dialog_text = "Are you sure you want to start a new game? This will delete your current save file."
	confirm.title = "New Game"
	confirm.confirmed.connect(func(): 
		GuildManager.clear_save_file()
		update_ui()
		print("New game started!")
	)
	confirm.popup_centered()
#endregion
