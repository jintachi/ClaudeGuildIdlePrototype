class_name QuestHub
extends Node

signal back_pressed

# Current Selected Quest State
var current_selected_quest: Quest = null
var current_party: Array[Character] = []

@export var scene_name : StringName = "Quest Hub"
@export var available_quest_list : VBoxContainer
@export var party_selection_panel : Panel
@export var quest_info_label : Label
@export var start_quest_button : Button
@export var party_list : HBoxContainer

@export var selected_quest:VBoxContainer

func _ready():
	$BackButton.pressed.connect(_on_back_pressed)

func _on_back_pressed():
	emit_signal("back_pressed")
	GuildManager.previous_scene_before_map = get_tree().current_scene.scene_file_path
	get_tree().change_scene_to_file("res://scenes/WorldMap/World_Map.tscn")

func update_quests_display():
	# Clear existing displays
	for child in available_quest_list.get_children():
		child.queue_free()
	
	for quest in GuildManager.available_quests:
		var quest_panel = create_quest_panel(quest)
		available_quest_list.add_child(quest_panel)

func generate_initial_quests():
	# Generate some basic F
	for i in range(5):
		var quest_rank = Quest.QuestRank.F
		var quest_type = Quest.QuestType.values()[RNG.wrapper.randi() % (Quest.QuestType.values().size() - 1)]  # Exclude EMERGENCY
		var quest = Quest.create_quest(quest_type, quest_rank)
		GuildManager.available_quests.append(quest)
		

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
	var available_chars = GuildManager.get_available_characters()
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

func create_party_selection_panel(character: Character) -> HBoxContainer:
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
		update_party_selection_display()

func remove_from_party(character: Character):
	current_party.erase(character)
	update_party_selection_display()

func _on_quest_started(quest: Quest):
	print("Quest started: ", quest.quest_name)
	current_selected_quest = null
	current_party.clear()
	party_selection_panel.visible = false
