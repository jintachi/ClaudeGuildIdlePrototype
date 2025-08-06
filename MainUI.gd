class_name MainUI
extends Control

@onready var guild_manager: GuildManager = $GuildManager

# UI Containers
@onready var main_hall_container: Control = $MainHall
@onready var roster_container: Control = $RosterTab
@onready var quests_container: Control = $QuestsTab
@onready var recruitment_container: Control = $RecruitmentTab
@onready var town_map_container: Control = $TownMap

# Main Hall Elements
@onready var resources_display: Label = $MainHall/ResourcesPanel/ResourcesLabel
@onready var active_quests_panel: VBoxContainer = $MainHall/ActiveQuestsPanel/ScrollContainer/VBoxContainer
@onready var promotion_panel: VBoxContainer = $MainHall/PromotionPanel/ScrollContainer/VBoxContainer

# Navigation Buttons
@onready var roster_button: Button = $MainHall/NavigationPanel/RosterButton
@onready var quests_button: Button = $MainHall/NavigationPanel/QuestsButton
@onready var recruitment_button: Button = $MainHall/NavigationPanel/RecruitmentButton
@onready var town_map_button: Button = $MainHall/NavigationPanel/TownMapButton

# Tab Navigation
@onready var back_to_hall_roster: Button = $RosterTab/BackButton
@onready var back_to_hall_quests: Button = $QuestsTab/BackButton
@onready var back_to_hall_recruitment: Button = $RecruitmentTab/BackButton
@onready var back_to_hall_town: Button = $TownMap/BackButton

# Roster Tab Elements
@onready var roster_list: VBoxContainer = $RosterTab/ScrollContainer/VBoxContainer

# Quests Tab Elements
@onready var available_quests_list: VBoxContainer = $QuestsTab/AvailableQuests/ScrollContainer/VBoxContainer
@onready var party_selection_panel: Control = $QuestsTab/PartySelection
@onready var party_list: VBoxContainer = $QuestsTab/PartySelection/ScrollContainer/VBoxContainer
@onready var start_quest_button: Button = $QuestsTab/PartySelection/StartQuestButton
@onready var quest_info_label: Label = $QuestsTab/PartySelection/QuestInfoLabel

# Recruitment Tab Elements
@onready var available_recruits_list: VBoxContainer = $RecruitmentTab/ScrollContainer/VBoxContainer
@onready var refresh_recruits_button: Button = $RecruitmentTab/RefreshButton

# Save/Load Buttons
@onready var save_button: Button = $MainHall/SaveLoadPanel/SaveButton
@onready var load_button: Button = $MainHall/SaveLoadPanel/LoadButton
@onready var new_game_button: Button = $MainHall/SaveLoadPanel/NewGameButton

# Current state
var current_selected_quest: Quest = null
var current_party: Array[Character] = []

func _ready():
	setup_ui_connections()
	show_main_hall()
	update_ui()
	
	# Connect to guild manager signals
	guild_manager.character_recruited.connect(_on_character_recruited)
	guild_manager.quest_started.connect(_on_quest_started)
	guild_manager.quest_completed.connect(_on_quest_completed)
	guild_manager.emergency_quest_available.connect(_on_emergency_quest_available)

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
	
	# Save/Load
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)

func _process(_delta):
	update_active_quests_display()

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
	party_selection_panel.visible = false
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

func update_resources_display():
	var resources = guild_manager.get_guild_status_summary().resources
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
	
	for quest in guild_manager.active_quests:
		var quest_panel = create_active_quest_panel(quest)
		active_quests_panel.add_child(quest_panel)

func create_active_quest_panel(quest: Quest) -> Control:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(300, 100)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	
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
	var seconds = int(time_remaining % 60)
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

func update_promotion_display():
	# Clear existing displays
	for child in promotion_panel.get_children():
		child.queue_free()
	
	var characters_needing_promotion = guild_manager.get_characters_needing_promotion()
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
	guild_manager.available_quests.append(promotion_quest)
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

func update_roster_display():
	# Clear existing displays
	for child in roster_list.get_children():
		child.queue_free()
	
	for character in guild_manager.roster:
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
		status_label.text = "INJURED - %s" % get_injury_name(character.injury_type)
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

func update_quests_display():
	# Clear existing displays
	for child in available_quests_list.get_children():
		child.queue_free()
	
	for quest in guild_manager.available_quests:
		var quest_panel = create_quest_panel(quest)
		available_quests_list.add_child(quest_panel)

func create_quest_panel(quest: Quest) -> Control:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(450, 150)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
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
	
	# Select button
	var select_button = Button.new()
	select_button.text = "Select Quest"
	select_button.pressed.connect(func(): select_quest(quest))
	vbox.add_child(select_button)
	
	return panel

func select_quest(quest: Quest):
	current_selected_quest = quest
	current_party.clear()
	party_selection_panel.visible = true
	update_party_selection_display()

func update_party_selection_display():
	if not current_selected_quest:
		return
	
	# Clear existing party display
	for child in party_list.get_children():
		child.queue_free()
	
	quest_info_label.text = "Selected: %s\n%s" % [current_selected_quest.quest_name, current_selected_quest.get_requirements_text()]
	
	# Show available characters
	var available_chars = guild_manager.get_available_characters()
	for character in available_chars:
		var char_panel = create_party_selection_panel(character)
		party_list.add_child(char_panel)
	
	# Show current party
	var party_label = Label.new()
	party_label.text = "\n--- CURRENT PARTY ---"
	party_label.add_theme_font_size_override("font_size", 12)
	party_list.add_child(party_label)
	
	for character in current_party:
		var party_member_panel = create_party_member_panel(character)
		party_list.add_child(party_member_panel)
	
	# Update start button
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
		update_party_selection_display()

func remove_from_party(character: Character):
	current_party.erase(character)
	update_party_selection_display()

func update_recruitment_display():
	# Clear existing displays
	for child in available_recruits_list.get_children():
		child.queue_free()
	
	for recruit in guild_manager.available_recruits:
		var recruit_panel = create_recruit_panel(recruit)
		available_recruits_list.add_child(recruit_panel)

func create_recruit_panel(recruit: Character) -> Control:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(400, 100)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Character info
	var name_label = Label.new()
	var stars = "★".repeat(recruit.quality)
	name_label.text = "%s (%s) %s" % [recruit.character_name, recruit.get_class_name(), stars]
	vbox.add_child(name_label)
	
	# Stats summary
	var stats_label = Label.new()
	stats_label.text = "HP:%d DEF:%d ATK:%d SPL:%d" % [recruit.health, recruit.defense, recruit.attack_power, recruit.spell_power]
	vbox.add_child(stats_label)
	
	# Cost and recruit button
	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)
	
	var cost = recruit.get_recruitment_cost()
	var cost_label = Label.new()
	cost_label.text = "Cost: %d Influence, %d Gold" % [cost.influence, cost.gold]
	if cost.food > 0: cost_label.text += ", %d Food" % cost.food
	if cost.armor > 0: cost_label.text += ", %d Armor" % cost.armor
	if cost.weapons > 0: cost_label.text += ", %d Weapons" % cost.weapons
	hbox.add_child(cost_label)
	
	var recruit_button = Button.new()
	recruit_button.text = "Recruit"
	recruit_button.disabled = not guild_manager.can_afford_cost(cost) or guild_manager.roster.size() >= guild_manager.max_roster_size
	recruit_button.pressed.connect(func(): _on_recruit_character(recruit))
	hbox.add_child(recruit_button)
	
	return panel

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

# Signal handlers
func _on_character_recruited(character: Character):
	print("Character recruited: ", character.character_name)
	update_ui()

func _on_quest_started(quest: Quest):
	print("Quest started: ", quest.quest_name)
	current_selected_quest = null
	current_party.clear()
	party_selection_panel.visible = false
	update_ui()

func _on_quest_completed(quest: Quest):
	print("Quest completed: ", quest.quest_name)
	# Show completion popup or notification
	show_quest_completion_popup(quest)
	update_ui()

func show_quest_completion_popup(quest: Quest):
	var popup = AcceptDialog.new()
	add_child(popup)
	
	var party_info = quest.get_party_display_info()
	var success_count = 0
	var party_text = ""
	
	for member in party_info:
		party_text += "%s: %s\n" % [member.name, "SUCCESS" if member.status == "✓" else "FAILED"]
		if member.status == "✓":
			success_count += 1
	
	var success_rate = float(success_count) / party_info.size()
	var result_text = "QUEST COMPLETED!\n\n"
	result_text += quest.quest_name + "\n\n"
	result_text += "Party Results:\n" + party_text + "\n"
	result_text += "Overall Success: %.0f%%\n\n" % (success_rate * 100)
	result_text += "Rewards: " + quest.get_rewards_text()
	
	popup.dialog_text = result_text
	popup.title = "Quest Results"
	popup.popup_centered()

func _on_emergency_quest_available(requirements: Dictionary):
	var popup = AcceptDialog.new()
	add_child(popup)
	
	popup.dialog_text = "EMERGENCY QUEST AVAILABLE!\n\n" + requirements.name + "\n\n" + requirements.description + "\n\nReward: " + requirements.unlock_description
	popup.title = "Emergency Quest"
	popup.popup_centered()

func _on_start_quest_pressed():
	if current_selected_quest and not current_party.is_empty():
		var result = guild_manager.start_quest(current_selected_quest, current_party)
		if not result.success:
			show_error_popup(result.message)

func _on_recruit_character(character: Character):
	var result = guild_manager.recruit_character(character)
	if result.success:
		print(result.message)
		update_recruitment_display()
	else:
		show_error_popup(result.message)

func _on_refresh_recruits_pressed():
	var result = guild_manager.force_recruit_refresh()
	if result.success:
		print(result.message)
		update_recruitment_display()
	else:
		show_error_popup(result.message)

func _on_save_pressed():
	guild_manager.save_game()
	print("Game saved!")

func _on_load_pressed():
	guild_manager.load_game()
	update_ui()
	print("Game loaded!")

func _on_new_game_pressed():
	var confirm = ConfirmationDialog.new()
	add_child(confirm)
	confirm.dialog_text = "Are you sure you want to start a new game? This will delete your current save file."
	confirm.title = "New Game"
	confirm.confirmed.connect(func(): 
		guild_manager.clear_save_file()
		update_ui()
		print("New game started!")
	)
	confirm.popup_centered()

func show_error_popup(message: String):
	var popup = AcceptDialog.new()
	add_child(popup)
	popup.dialog_text = message
	popup.title = "Error"
	popup.popup_centered()
	
