class_name MainHallRoom
extends BaseRoom

# Main Hall specific UI elements
@export var resources_display: Label
@export var active_quests_panel: VBoxContainer
@export var awaiting_completion_panel: VBoxContainer
@export var completed_quests_panel: VBoxContainer
@export var promotion_panel: VBoxContainer

# Navigation buttons for other rooms
@export var roster_button: Button
@export var quests_button: Button
@export var recruitment_button: Button
@export var town_map_button: Button

# Save/Load buttons
@export var scale_05_button: Button
@export var scale_075_button: Button
@export var scale_1_button: Button
@export var scale_15_button: Button
@export var scale_2_button: Button
@export var scale_3_button: Button
@export var save_button: Button
@export var load_button: Button
@export var new_game_button: Button

func _init():
	room_name = "Main Hall"
	room_description = "The central hub of your guild"
	is_unlocked = true

func setup_room_specific_ui():
	"""Setup main hall specific UI connections"""
	setup_navigation_buttons()
	setup_save_load_buttons()
	setup_ui_scaling_buttons()

func setup_navigation_buttons():
	"""Setup navigation button connections"""
	if roster_button:
		roster_button.pressed.connect(_on_roster_button_pressed)
	if quests_button:
		quests_button.pressed.connect(_on_quests_button_pressed)
	if recruitment_button:
		recruitment_button.pressed.connect(_on_recruitment_button_pressed)
	if town_map_button:
		town_map_button.pressed.connect(_on_town_map_button_pressed)

func setup_save_load_buttons():
	"""Setup save/load button connections"""
	if save_button:
		save_button.pressed.connect(_on_save_button_pressed)
	if load_button:
		load_button.pressed.connect(_on_load_button_pressed)
	if new_game_button:
		new_game_button.pressed.connect(_on_new_game_button_pressed)

func setup_ui_scaling_buttons():
	"""Setup UI scaling button connections"""
	if scale_05_button:
		scale_05_button.pressed.connect(_on_scale_button_pressed.bind(0.5))
	if scale_075_button:
		scale_075_button.pressed.connect(_on_scale_button_pressed.bind(0.75))
	if scale_1_button:
		scale_1_button.pressed.connect(_on_scale_button_pressed.bind(1.0))
	if scale_15_button:
		scale_15_button.pressed.connect(_on_scale_button_pressed.bind(1.5))
	if scale_2_button:
		scale_2_button.pressed.connect(_on_scale_button_pressed.bind(2.0))
	if scale_3_button:
		scale_3_button.pressed.connect(_on_scale_button_pressed.bind(3.0))

func on_room_entered():
	"""Called when entering the main hall"""
	update_room_display()
	update_scale_button_states(get_tree().root.content_scale_factor)

func update_room_display():
	"""Update the main hall display"""
	update_resources_display()
	update_active_quests_display()
	update_awaiting_completion_display()
	update_completed_quests_display()
	update_promotion_display()

func update_resources_display():
	"""Update the resources display"""
	if not resources_display or not GuildManager:
		return
	
	var resources = GuildManager.get_guild_status_summary().resources
	resources_display.text = "Influence: %d | Gold: %d | Food: %d | Materials: %d | Armor: %d | Weapons: %d" % [
		resources.influence, resources.gold, resources.food, 
		resources.building_materials, resources.armor, resources.weapons
	]

func update_active_quests_display():
	"""Update the active quests display"""
	if not active_quests_panel or not GuildManager:
		return
	
	# Clear existing displays
	var scroll_container = active_quests_panel.get_child(1) if active_quests_panel.get_child_count() > 1 else null
	if scroll_container and scroll_container.get_child_count() > 0:
		var active_container = scroll_container.get_child(0)
		if active_container:
			for child in active_container.get_children():
				child.queue_free()
			
			# Show only active quests
			for quest in GuildManager.active_quests:
				var quest_panel = create_active_quest_panel(quest)
				active_container.add_child(quest_panel)

func update_awaiting_completion_display():
	"""Update the awaiting completion quests display"""
	if not awaiting_completion_panel or not GuildManager:
		return
	
	# Clear existing displays
	var scroll_container = awaiting_completion_panel.get_child(1) if awaiting_completion_panel.get_child_count() > 1 else null
	if scroll_container and scroll_container.get_child_count() > 0:
		var awaiting_container = scroll_container.get_child(0)
		if awaiting_container:
			for child in awaiting_container.get_children():
				child.queue_free()
			
			# Show quests awaiting completion
			for quest in GuildManager.awaiting_completion_quests:
				var quest_panel = create_awaiting_completion_panel(quest)
				awaiting_container.add_child(quest_panel)

func update_completed_quests_display():
	"""Update the completed quests display"""
	if not completed_quests_panel or not GuildManager:
		return
	
	# Clear existing completed quest panels
	var scroll_container = completed_quests_panel.get_child(1) if completed_quests_panel.get_child_count() > 1 else null
	if scroll_container and scroll_container.get_child_count() > 0:
		var completed_container = scroll_container.get_child(0)
		if completed_container:
			for child in completed_container.get_children():
				child.queue_free()
			
			# Show recent completed quests (last 5)
			var recent_completed = GuildManager.completed_quests.slice(-5)
			for quest in recent_completed:
				var quest_panel = create_completed_quest_panel(quest)
				completed_container.add_child(quest_panel)

func update_promotion_display():
	"""Update the promotion display"""
	if not promotion_panel or not GuildManager:
		return
	
	# Clear existing displays
	for child in promotion_panel.get_children():
		child.queue_free()
	
	var characters_needing_promotion = GuildManager.get_characters_needing_promotion()
	for character in characters_needing_promotion:
		var promo_panel = create_promotion_panel(character)
		promotion_panel.add_child(promo_panel)

# Quest panel creation methods
func create_active_quest_panel(quest: Quest) -> Control:
	"""Create a panel for active quests"""
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

func create_awaiting_completion_panel(quest: Quest) -> Control:
	"""Create a panel for quests awaiting completion"""
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
	title.add_theme_color_override("font_color", Color.GREEN)
	vbox.add_child(title)
	
	# Status label
	var status_label = Label.new()
	status_label.text = "Quest Complete - Awaiting Results"
	status_label.add_theme_color_override("font_color", Color.GREEN)
	vbox.add_child(status_label)
	
	# Party status
	var party_info = quest.get_party_display_info()
	var party_label = Label.new()
	var party_text = "Party: "
	for member in party_info:
		party_text += "%s(%s)%s " % [member.name, member.class, member.status]
	party_label.text = party_text
	vbox.add_child(party_label)
	
	# Accept results button
	var complete_button = Button.new()
	complete_button.text = "Accept Results"
	complete_button.add_theme_color_override("font_color", Color.GREEN)
	complete_button.pressed.connect(_on_accept_quest_results.bind(quest))
	vbox.add_child(complete_button)
	
	return panel

func create_completed_quest_panel(quest: Quest) -> Control:
	"""Create a panel for completed quests"""
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(300, 120)	
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	
	# Quest title
	var title = Label.new()
	title.text = quest.quest_name
	title.add_theme_font_size_override("font_size", 12)
	vbox.add_child(title)
	
	# Completion info
	var completion_label = Label.new()
	completion_label.text = "Completed: %s" % quest.get_completion_time_string()
	vbox.add_child(completion_label)
	
	# Rewards summary
	var rewards_label = Label.new()
	rewards_label.text = "Rewards: %d XP, %d Gold" % [quest.experience_reward, quest.gold_reward]
	vbox.add_child(rewards_label)
	
	return panel

func create_promotion_panel(character: Character) -> Control:
	"""Create a panel for character promotion"""
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(250, 100)	
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	
	# Character name
	var name_label = Label.new()
	name_label.text = character.name
	vbox.add_child(name_label)
	
	# Current rank
	var rank_label = Label.new()
	rank_label.text = "Current Rank: %s" % character.rank
	vbox.add_child(rank_label)
	
	# Promote button
	var promote_button = Button.new()
	promote_button.text = "Promote"
	promote_button.pressed.connect(_on_promote_character.bind(character))
	vbox.add_child(promote_button)
	
	return panel

# Button event handlers
func _on_roster_button_pressed():
	"""Handle roster button press"""
	if RoomManager:
		RoomManager.enter_room("Roster")

func _on_quests_button_pressed():
	"""Handle quests button press"""
	if RoomManager:
		RoomManager.enter_room("Quests")

func _on_recruitment_button_pressed():
	"""Handle recruitment button press"""
	if RoomManager:
		RoomManager.enter_room("Recruitment")

func _on_town_map_button_pressed():
	"""Handle town map button press"""
	if RoomManager:
		RoomManager.enter_room("Town Map")

func _on_save_button_pressed():
	"""Handle save button press"""
	if GuildManager:
		GuildManager.save_game()

func _on_load_button_pressed():
	"""Handle load button press"""
	if GuildManager:
		GuildManager.load_game()

func _on_new_game_button_pressed():
	"""Handle new game button press"""
	if GuildManager:
		GuildManager.new_game()

func _on_scale_button_pressed(scale_factor: float):
	"""Handle UI scale button press"""
	if UIScalingManager:
		UIScalingManager.set_ui_scale(scale_factor)

func _on_accept_quest_results(quest: Quest):
	"""Handle accepting quest results"""
	if GuildManager:
		GuildManager.complete_quest(quest)
		update_room_display()

func _on_promote_character(character: Character):
	"""Handle character promotion"""
	if GuildManager:
		GuildManager.promote_character(character)
		update_room_display()

func update_scale_button_states(current_scale: float):
	"""Update the state of scale buttons"""
	var scale_buttons = [scale_05_button, scale_075_button, scale_1_button, scale_15_button, scale_2_button, scale_3_button]
	var scale_values = [0.5, 0.75, 1.0, 1.5, 2.0, 3.0]
	
	for i in range(scale_buttons.size()):
		if scale_buttons[i]:
			scale_buttons[i].button_pressed = (abs(current_scale - scale_values[i]) < 0.01)
