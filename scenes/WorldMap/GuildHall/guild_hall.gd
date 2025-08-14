class_name GuildHall
extends GuildManager

@export var _theme = load("res://Assets/Themes/theme.tres")
@export var scene_name : StringName
@export var resources_display : Label
@export var active_quests_panel : VBoxContainer
@export var promotion_panel : VBoxContainer


func _ready():
	
	#GameGlobalEvents.quest_completed.connect(_on_quest_completed)
	emergency_quest_available.connect(_on_emergency_quest_available)
	GameGlobalEvents.quest_completed.connect(show_quest_completion_popup)
	

#func setup_ui_connections():
	#
	#GameGlobalEvents.new_game.connect()


func _process(_delta):
	update_active_quests_display()

func update_ui():
	update_resources_display()
	update_main_hall_display()


func update_resources_display():
	var resources = get_guild_status_summary().resources
	resources_display.text = "Influence: %d | Gold: %d | Food: %d | Materials: %d | Armor: %d | Weapons: %d" % [
		resources.influence, resources.gold, resources.food, 
		resources.building_materials, resources.armor, resources.weapons
	]

func update_main_hall_display():
	update_resources_display()
	update_active_quests_display()
	update_promotion_display()

func update_active_quests_display():
	return
	## Clear existing displays
	#for child in active_quests_panel.get_children():
		#child.queue_free()
	#
	#for quest in GuildManager.active_quests:
		#var quest_panel = create_active_quest_panel(quest)
		#active_quests_panel.add_child(quest_panel)

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
	available_quests.append(promotion_quest)
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
	

## TODO: Change this section so that instead of a popup, the display of the quest progress changes to a "COMPLETE QUEST" Button, which then will pull up this pop up
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
	
	
	
	## TODO: Add a series of tabs or a cleaner display for which units got EXP, and any levelup gains, maybe a click-through series of tabs for each character.
	for _char in quest.assigned_party :
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

func _on_emergency_quest_available(requirements: Dictionary):
	var popup = AcceptDialog.new()
	add_child(popup)
	
	popup.dialog_text = "EMERGENCY QUEST AVAILABLE!\n\n" + requirements.name + "\n\n" + requirements.description + "\n\nReward: " + requirements.unlock_description
	popup.title = "Emergency Quest"
	popup.popup_centered()


func _on_save_pressed():
	SaveManager.save_game(GuildManager)
	print("Game saved!")


func _on_roster_button_pressed():
	_change_scene_with_loading("res://scenes/WorldMap/GuildRoster/Guild_Roster.tscn")

func _on_quests_button_pressed():
	_change_scene_with_loading("res://scenes/WorldMap/QuestBoard/Quest_Board.tscn")

func _on_recruitment_button_pressed():
	_change_scene_with_loading("res://scenes/WorldMap/RecruitersHub/Recruiters_Hub.tscn")

func _on_town_map_button_pressed():
	_change_scene_with_loading("res://scenes/WorldMap/World_Map.tscn")

func _change_scene_with_loading(target_scene_path: String):
	get_tree().change_scene_to_file("res://scenes/WorldMap/WorldMapLoader.tscn")
	await get_tree().process_frame
	# Simulate loading, or implement async loading here
	get_tree().change_scene_to_file(target_scene_path)
	
