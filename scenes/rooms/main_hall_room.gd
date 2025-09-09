class_name MainHallRoom
extends BaseRoom

# Main Hall specific UI elements



# Main Hall specific UI elements
@export var active_quests_panel: VBoxContainer
@export var awaiting_completion_panel: VBoxContainer
@export var promotion_panel: VBoxContainer
@export var quest_counter_panel: Panel
#@export var quest_completion_panel: Panel

# Track quest panels for smooth updates
var active_quest_panels: Dictionary = {}  # quest_id -> panel
var awaiting_quest_panels: Dictionary = {}  # quest_id -> panel
var completed_quest_panels: Dictionary = {}  # quest_id -> panel

# Guard to prevent multiple rapid calls
var is_updating_awaiting_display: bool = false
var is_updating_active_display: bool = false

# Quest counter labels
var available_quest_count_label: Label
var active_quest_count_label: Label
var awaiting_quest_count_label: Label

func _init():
	room_name = "Main Hall"
	room_description = "The central hub of your guild"
	is_unlocked = true

func setup_room_specific_ui():
	"""Setup main hall specific UI connections"""
	# Connect to guild manager signals for quest card movements
	if GuildManager:
		GuildManager.quest_card_moved.connect(_on_quest_card_moved)
	
	# Setup quest counters
	setup_quest_counters()

func setup_quest_counters():
	"""Setup quest counter labels and initial values"""
	if not quest_counter_panel:
		return
	
	# Get the counter labels from the scene
	var available_counter = quest_counter_panel.get_node("QuestCounterHBox/AvailableQuestCounter")
	var active_counter = quest_counter_panel.get_node("QuestCounterHBox/ActiveQuestCounter")
	var awaiting_counter = quest_counter_panel.get_node("QuestCounterHBox/AwaitingQuestCounter")
	
	if available_counter:
		available_quest_count_label = available_counter.get_node("AvailableQuestCount")
	if active_counter:
		active_quest_count_label = active_counter.get_node("ActiveQuestCount")
	if awaiting_counter:
		awaiting_quest_count_label = awaiting_counter.get_node("AwaitingQuestCount")
	
	# Update initial counts
	update_quest_counters()

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
	print("AVAILABLE_QUESTS: update_room_display() called")
	update_active_quests_display()
	update_awaiting_completion_display()
	update_promotion_display()
	update_quest_counters()

func update_active_quests_display():
	"""Update the active quests display"""
	if not active_quests_panel or not GuildManager:
		return
	
	# Guard against multiple rapid calls
	if is_updating_active_display:
		print("AVAILABLE_QUESTS: Already updating active display, skipping")
		return
	
	is_updating_active_display = true
	
	# Clear existing displays and tracking
	for child in active_quests_panel.get_children():
		active_quests_panel.remove_child(child)
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
	
	# Reset the guard flag
	is_updating_active_display = false

func create_active_panel_from_card(quest_card:CompactQuestCard) -> VBoxContainer:
	## MAIN PANEL ##
	var panel_vbox = VBoxContainer.new()
	panel_vbox.name = "Quest Card: " + quest_card.get_quest().quest_name
	panel_vbox.add_theme_constant_override("separation", 10)
	
	# Debug: Check if quest card is properly populated
	print("AVAILABLE_QUESTS: Creating panel for quest: " + quest_card.get_quest().quest_name)
	print("AVAILABLE_QUESTS: Quest card has quest: " + str(quest_card.get_quest() != null))
	print("AVAILABLE_QUESTS: Quest card has method populate_with_quest: " + str(quest_card.has_method("populate_with_quest")))
	
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
	

func update_active_quest_progress(_delta: float):
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
	var progress_bar_scene = preload("res://ui/components/NineSliceProgressBar.tscn")
	var progress_bar = progress_bar_scene.instantiate()
	progress_bar.name = "ProgressBar"
	progress_bar.max_value = 100
	progress_bar.value = quest.get_progress_percentage()
	progress_bar.custom_minimum_size = Vector2(150, 22)
	progress_bar.use_nine_slice = true
	progress_bar.segment_width = 8
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
	print("AVAILABLE_QUESTS: update_awaiting_completion_display() called")
	if not awaiting_completion_panel or not GuildManager:
		print("AVAILABLE_QUESTS: awaiting_completion_panel or GuildManager is null")
		return
	
	# Guard against multiple rapid calls
	if is_updating_awaiting_display:
		print("AVAILABLE_QUESTS: Already updating awaiting display, skipping")
		return
	
	is_updating_awaiting_display = true
	
	# Clear existing displays and tracking
	for child in awaiting_completion_panel.get_children():
		awaiting_completion_panel.remove_child(child)
		child.queue_free()
	awaiting_quest_panels.clear()
	
	# Get awaiting quest cards from GuildManager (properly unparented)
	var quest_cards = GuildManager.get_awaiting_quest_cards()
	print("AVAILABLE_QUESTS: Got ", quest_cards.size(), " awaiting quest cards")
	
	# Show quests awaiting completion using quest cards with accept buttons
	for quest_card in quest_cards:
		if is_instance_valid(quest_card):
			print("AVAILABLE_QUESTS: Creating completion panel for quest: ", quest_card.get_quest().quest_name)
			
			# Create a container for the quest card and accept button
			var quest_container = VBoxContainer.new()
			quest_container.add_theme_constant_override("separation", 10)
			
			#reparent
			if quest_card.get_parent() == null :
				quest_container.add_child(quest_card)
			else :
				quest_card.reparent(quest_container)
		
			
			# Create accept results button
			var accept_button = Button.new()
			accept_button.text = "Accept Quest Results"
			accept_button.add_theme_color_override("font_color", Color.GREEN)
			accept_button.pressed.connect(_on_accept_quest_results.bind(quest_card.get_quest()))
			quest_container.add_child(accept_button)
			
			# Add the container to the awaiting completion panel
			awaiting_completion_panel.add_child(quest_container)
			awaiting_quest_panels[quest_card.get_quest()] = quest_container
		else:
			print("AVAILABLE_QUESTS: Quest card is not valid")
	
	# Reset the guard flag
	is_updating_awaiting_display = false

func update_awaiting_completion_times(_delta: float):
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
	print("AVAILABLE_QUESTS: Main hall _on_accept_quest_results called")
	print("AVAILABLE_QUESTS: Quest name: ", quest.quest_name)
	if GuildManager:
		# Find the quest card for this quest
		var quest_card: CompactQuestCard = null
		for card in GuildManager.get_awaiting_quest_cards():
			if card.get_quest() == quest:
				quest_card = card
				break
		
		if quest_card:
			print("AVAILABLE_QUESTS: Found quest card, calling GuildManager.accept_quest_results")
			GuildManager.accept_quest_results(quest_card)
			print("AVAILABLE_QUESTS: Calling update_room_display")
			update_room_display()
		else:
			print("AVAILABLE_QUESTS: Quest card not found in awaiting quests")
	else:
		print("AVAILABLE_QUESTS: GuildManager is null")



func _on_promote_character(character: Character):
	"""Handle character promotion"""
	if GuildManager:
		GuildManager.promote_character(character)
		update_room_display()

func _on_quest_card_moved(quest_card: CompactQuestCard, from_state: String, to_state: String):
	"""Handle when a quest card is moved between states"""
	print("AVAILABLE_QUESTS: Quest card moved from ", from_state, " to ", to_state)
	print("AVAILABLE_QUESTS: Quest name: ", quest_card.get_quest().quest_name if quest_card and quest_card.get_quest() else "null")
	
	# When a quest card moves to active, add it to our active display
	if to_state == "active":
		print("AVAILABLE_QUESTS: Updating active quests display")
		update_active_quests_display()
	
	# When a quest card moves to awaiting, add it to our awaiting display
	elif to_state == "awaiting":
		print("AVAILABLE_QUESTS: Updating awaiting completion display")
		update_awaiting_completion_display()
	
	# When a quest card moves from active/awaiting, remove it from those displays
	elif from_state == "active":
		print("AVAILABLE_QUESTS: Updating active quests display (removal)")
		update_active_quests_display()
	elif from_state == "awaiting":
		print("AVAILABLE_QUESTS: Updating awaiting completion display (removal)")
		update_awaiting_completion_display()
	
	# Update quest counters whenever a quest card moves
	update_quest_counters()

func update_quest_counters():
	"""Update the quest counter displays with current counts"""
	if not GuildManager:
		return
	
	# Get current counts from GuildManager
	var available_count = GuildManager.get_available_quest_cards().size()
	var active_count = GuildManager.get_active_quest_cards().size()
	var awaiting_count = GuildManager.get_awaiting_quest_cards().size()
	
	# Update the labels
	if available_quest_count_label:
		available_quest_count_label.text = str(available_count)
	if active_quest_count_label:
		active_quest_count_label.text = str(active_count)
	if awaiting_quest_count_label:
		awaiting_quest_count_label.text = str(awaiting_count)
