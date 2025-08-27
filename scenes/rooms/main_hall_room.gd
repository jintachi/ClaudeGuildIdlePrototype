class_name MainHallRoom
extends BaseRoom

const QuestCompletionPanel = preload("res://ui/components/QuestCompletionPanel.tscn")



# Main Hall specific UI elements
@export var active_quests_panel: VBoxContainer
@export var awaiting_completion_panel: VBoxContainer
@export var promotion_panel: VBoxContainer
#@export var quest_completion_panel: Panel

# Track quest panels for smooth updates
var active_quest_panels: Dictionary = {}  # quest_id -> panel
var awaiting_quest_panels: Dictionary = {}  # quest_id -> panel
var completed_quest_panels: Dictionary = {}  # quest_id -> panel

func _init():
	room_name = "Main Hall"
	room_description = "The central hub of your guild"
	is_unlocked = true

func setup_room_specific_ui():
	"""Setup main hall specific UI connections"""
	# Connect to guild manager signals for quest card movements
	if GuildManager:
		GuildManager.quest_card_moved.connect(_on_quest_card_moved)

func on_room_entered():
	"""Called when entering the main hall"""
	update_room_display()

func on_room_exited():
	"""Called when exiting the main hall"""
	# Remove quest cards from UI but don't destroy them
	for child in active_quests_panel.get_children():
		if child is VBoxContainer:  # Quest containers
			for grandchild in child.get_children():
				if grandchild is CompactQuestCard:
					child.remove_child(grandchild)
	
	if awaiting_completion_panel:
		for child in awaiting_completion_panel.get_children():
			if child is VBoxContainer:  # Quest containers
				for grandchild in child.get_children():
					if grandchild is CompactQuestCard:
						child.remove_child(grandchild)
	
	# Clean up tracking dictionaries
	active_quest_panels.clear()
	awaiting_quest_panels.clear()
	completed_quest_panels.clear()

	
func _process(delta: float):
	"""Update progress bars and time displays smoothly"""
	if not is_inside_tree():
		return
	
	# Update active quest progress bars
	update_active_quest_progress(delta)
	
	# Update awaiting completion time displays
	update_awaiting_completion_times(delta)

func update_room_display():
	"""Update the main hall display"""
	update_active_quests_display()
	update_awaiting_completion_display()
	update_promotion_display()

func update_active_quests_display():
	"""Update the active quests display"""
	if not active_quests_panel or not GuildManager:
		return
	
	# Clear existing displays and tracking
	for child in active_quests_panel.get_children():
		child.queue_free()
	active_quest_panels.clear()
	
	# Get active quest cards from GuildManager (properly unparented)
	var quest_cards = GuildManager.get_active_quest_cards()
	
	# Show only active quests
	for quest_card in quest_cards:
		if is_instance_valid(quest_card):
			
			# Create our quest panel container for the active quest
			var panel_container = create_active_panel_from_card(quest_card) as VBoxContainer
			
			# Add the container to the panel
			active_quests_panel.add_child(panel_container)
			active_quest_panels[quest_card.get_quest()] = panel_container
				

func create_active_panel_from_card(quest_card:CompactQuestCard) -> VBoxContainer:
	## MAIN PANEL ##
	var panel_vbox = VBoxContainer.new()
	panel_vbox.name = "Quest Card: " + quest_card.get_quest().quest_name
	panel_vbox.add_theme_constant_override("separation", 10)
	
	# Debug: Check if quest card is properly populated
	print("DEBUG: Creating panel for quest: " + quest_card.get_quest().quest_name)
	print("DEBUG: Quest card has quest: " + str(quest_card.get_quest() != null))
	print("DEBUG: Quest card has method populate_with_quest: " + str(quest_card.has_method("populate_with_quest")))
	
	# Status label
	var status_label = Label.new()
	status_label.text = "Quest: " + quest_card.get_quest().quest_name + " currently underway..."
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.add_theme_color_override("font_color", Color.GOLD)
	panel_vbox.add_child(status_label)
	
	# Party status
	var party_label = Label.new()
	var party_info = quest_card.get_quest().get_party_display_info()
	var party_text = "👥 "
	for member in party_info:
		party_text += "%s(%s) " % [member.name, member.class]
	party_label.text = party_text
	party_label.add_theme_font_size_override("font_size", 11)
	party_label.add_theme_color_override("font_color",Color.GREEN)
	panel_vbox.add_child(party_label)
	
	# Create a separate progress bar below the quest card
	var progress_container = create_quest_progress_bar(quest_card.get_quest())
	
	progress_container.set_script(load("res://ui/components/quest_progress_container.gd"))
	
	panel_vbox.add_child(progress_container)
		
	return panel_vbox
	

func update_active_quest_progress(delta: float):
	"""Update progress bars for active quests smoothly"""
	var quests_to_remove = []
	
	for quest in active_quest_panels:
		var container = active_quest_panels[quest]
		if not is_instance_valid(container):
			quests_to_remove.append(quest)
			continue
		
		# Find the progress bar in the container (second child)
		var progress_container = container.get_child(2)  # Progress bar is second child
		if progress_container and progress_container.has_method("update_progress"):
			progress_container.update_progress(quest)
	
	# Clean up invalid quests
	for quest in quests_to_remove:
		active_quest_panels.erase(quest)

func create_quest_progress_bar(quest: Quest) -> Control:
	"""Create a progress bar container for a quest"""
	var progress_container = HBoxContainer.new()
	progress_container.name = "ProgressContainer"
	progress_container.add_theme_constant_override("separation", 10)
	
	# Progress bar
	var progress_bar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.max_value = 100
	progress_bar.value = quest.get_progress_percentage()
	progress_bar.custom_minimum_size = Vector2(150, 20)
	progress_container.add_child(progress_bar)
	
	# Time remaining
	var time_label = Label.new()
	time_label.name = "TimeLabel"
	var time_remaining = quest.get_time_remaining()
	var minutes = int(time_remaining / 60)
	var seconds = int(time_remaining) % 60
	time_label.text = "⏱️ %02d:%02d" % [minutes, seconds]
	time_label.add_theme_font_size_override("font_size", 11)
	progress_container.add_child(time_label)

	return progress_container

func create_quest_status_bar(quest: Quest) -> Control:
	"""Create a status bar container for awaiting completion quests"""
	var status_container = HBoxContainer.new()
	status_container.name = "StatusContainer"
	status_container.add_theme_constant_override("separation", 10)
	
	# Status label
	var status_label = Label.new()
	status_label.text = "✅ Quest Complete - Awaiting Results"
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color.GREEN)
	status_container.add_child(status_label)
	
	# Accept results button
	var complete_button = Button.new()
	complete_button.text = "Accept Results"
	complete_button.add_theme_color_override("font_color", Color.GREEN)
	complete_button.pressed.connect(_on_accept_quest_results.bind(quest))
	status_container.add_child(complete_button)
	
	# Party status
	var party_info = quest.get_party_display_info()
	var party_label = Label.new()
	var party_text = "👥 "
	for member in party_info:
		party_text += "%s(%s) " % [member.name, member.class]
	party_label.text = party_text
	party_label.add_theme_font_size_override("font_size", 10)
	party_label.add_theme_color_override("font_color", Color.LIGHT_BLUE)
	status_container.add_child(party_label)
	
	return status_container

func update_awaiting_completion_display():
	"""Update the awaiting completion quests display"""
	if not awaiting_completion_panel or not GuildManager:
		return
	
	# Clear existing displays and tracking
	for child in awaiting_completion_panel.get_children():
		child.queue_free()
	awaiting_quest_panels.clear()
	
	# Get awaiting quest cards from GuildManager (properly unparented)
	var quest_cards = GuildManager.get_awaiting_quest_cards()
	
	# Show quests awaiting completion using the new completion panel
	for quest_card in quest_cards:
		if is_instance_valid(quest_card):
			# Create the quest completion panel
			var completion_panel = QuestCompletionPanel.instantiate()
			
			# Connect the quest results accepted signal
			if completion_panel.has_signal("quest_results_accepted"):
				completion_panel.quest_results_accepted.connect(_on_quest_results_accepted)
			
			# Display the quest results
			completion_panel.display_quest_results(quest_card.get_quest())
			
			# Add the completion panel to the awaiting completion panel
			awaiting_completion_panel.add_child(completion_panel)
			awaiting_quest_panels[quest_card.get_quest()] = completion_panel

func update_awaiting_completion_times(delta: float):
	"""Update time displays for awaiting completion quests smoothly"""
	var quests_to_remove = []
	
	for quest in awaiting_quest_panels:
		var panel = awaiting_quest_panels[quest]
		if not is_instance_valid(panel):
			quests_to_remove.append(quest)
			continue
		
		# Update any time-related displays if needed
		# (Currently no time updates needed for awaiting completion quests)
		pass
	
	# Clean up invalid quests
	for quest in quests_to_remove:
		awaiting_quest_panels.erase(quest)

func update_promotion_display():
	"""Update the promotion display"""
	if not promotion_panel or not GuildManager:
		return
	
	var characters_needing_promotion = GuildManager.get_characters_needing_promotion()
	for character in characters_needing_promotion:
		var promo_panel = create_promotion_panel(character)
		promotion_panel.add_child(promo_panel)
		
		


func create_completed_quest_panel(quest_card: CompactQuestCard) -> Control:
	"""Create a panel for completed quests using the compact quest card"""
	
	var temp_card = quest_card
	
	# Check if the instantiated object is the correct type
	if not quest_card.has_method("populate_with_quest"):
		print("Error: CompactQuestCard scene did not instantiate correctly")
		return Control.new()  # Return empty control as fallback
	
	# Add completion information
	var completion_container = HBoxContainer.new()
	completion_container.add_theme_constant_override("separation", 10)
	
	# Completion status
	var completion_label = Label.new()
	var comp_time = temp_card.get_quest().start_time + temp_card.get_quest().duration
	completion_label.text = "✅ Completed: %s" % Time.get_time_string_from_unix_time(comp_time)
	completion_label.add_theme_font_size_override("font_size", 12)
	completion_label.add_theme_color_override("font_color", Color.GREEN)
	completion_container.add_child(completion_label)
	
	# Add completion container to the card
	var vbox = quest_card.get_node("InnerPanel/VBoxContainer")
	vbox.add_child(completion_container)
	
	return temp_card

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
func _on_accept_quest_results(quest: Quest):
	"""Handle accepting quest results"""
	if GuildManager:
		# Find the quest card for this quest
		var quest_card: CompactQuestCard = null
		for card in GuildManager.get_awaiting_quest_cards():
			if card.get_quest() == quest:
				quest_card = card
				break
		
		if quest_card:
			GuildManager.accept_quest_results(quest_card)
			update_room_display()

func _on_quest_results_accepted(quest: Quest):
	"""Handle quest results accepted from the completion panel"""
	if GuildManager:
		# Find the quest card for this quest
		var quest_card: CompactQuestCard = null
		for card in GuildManager.get_awaiting_quest_cards():
			if card.get_quest() == quest:
				quest_card = card
				break
		
		if quest_card:
			GuildManager.accept_quest_results(quest_card)
			update_room_display()

func _on_promote_character(character: Character):
	"""Handle character promotion"""
	if GuildManager:
		GuildManager.promote_character(character)
		update_room_display()

func _on_quest_card_moved(quest: Quest, from_state: String, to_state: String):
	"""Handle when a quest card is moved between states"""
	# When a quest card moves to active, add it to our active display
	if to_state == "active":
		update_active_quests_display()
	
	# When a quest card moves to awaiting, add it to our awaiting display
	elif to_state == "awaiting":
		update_awaiting_completion_display()
	
	# When a quest card moves from active/awaiting, remove it from those displays
	elif from_state == "active":
		update_active_quests_display()
	elif from_state == "awaiting":
		update_awaiting_completion_display()
