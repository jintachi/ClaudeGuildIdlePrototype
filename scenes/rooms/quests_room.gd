class_name QuestsRoom
extends BaseRoom

# Quests-specific UI elements
@export var available_quests_list: VBoxContainer
@export var quest_details_panel: VBoxContainer
@export var start_quest_button: Button
@export var quest_inventory_button: Button
@export var quest_info_label: Label
@export var stats_comparison_table: VBoxContainer
@export var guild_roster_grid: GridContainer
@export var quest_card:PackedScene

# Quest inventory panel
var quest_inventory_panel: QuestInventoryPanel = null

# Quest and party state
var current_selected_quest_card: CompactQuestCard = null
var current_party: Array[Character] = []

# Local data cache
var local_quest_cards: Array[CompactQuestCard]
var local_available_characters: Array[Character]

func _init():
	room_name = "Quests"
	room_description = "Accept and manage quests"
	is_unlocked = true

func _ready():
	"""Called when the room is ready"""
	super._ready()
	
	print("QuestsRoom: _ready() called - Room instance: ", self)
	print("QuestsRoom: available_quests_list children: ", available_quests_list.get_child_count() if available_quests_list else "null")
	print("QuestsRoom: local_quest_cards size: ", local_quest_cards.size())
	print("QuestsRoom: local_available_characters size: ", local_available_characters.size())
	
	# Check if this is a reused room instance by looking for existing UI setup
	if available_quests_list and available_quests_list.get_child_count() > 0:
		print("QuestsRoom: Room instance reused (UI has children), refreshing data")
		call_deferred("on_room_entered")
	elif local_quest_cards.size() > 0 or local_available_characters.size() > 0:
		print("QuestsRoom: Room instance reused (local data exists), refreshing data")
		call_deferred("on_room_entered")

func setup_room_specific_ui():
	"""Setup quests-specific UI connections"""
	print("=== SETUP ROOM SPECIFIC UI ===")
	
	# Only refresh data if this is a new room instance (no existing data)
	if local_quest_cards.size() == 0 and local_available_characters.size() == 0:
		print("QuestsRoom: New room instance, refreshing data...")
		call_deferred("on_room_entered")
	else:
		print("QuestsRoom: Reused room instance, data already exists")
	
	print("Step 0a: available_quests_list export variable is null: ", available_quests_list == null)
	if available_quests_list:
		print("Step 0a1: available_quests_list name: ", available_quests_list.name)
		print("Step 0a2: available_quests_list class: ", available_quests_list.get_class())
	
	print("Step 0b: guild_roster_grid export variable is null: ", guild_roster_grid == null)
	if guild_roster_grid:
		print("Step 0b1: guild_roster_grid name: ", guild_roster_grid.name)
		print("Step 0b2: guild_roster_grid class: ", guild_roster_grid.get_class())
	
	# Find UI containers by name if export variables are not assigned
	if not available_quests_list:
		print("Step 0c: ERROR - available_quests_list is null, trying fallback lookup")
		available_quests_list = find_child_by_name_recursive("AvailableQuestsVBox")
		print("Step 0d: Fallback lookup result: ", available_quests_list != null)
		if available_quests_list:
			print("Step 0e: available_quests_list name: ", available_quests_list.name)
			print("Step 0f: available_quests_list class: ", available_quests_list.get_class())
		else:
			print("Step 0e: ERROR - Could not find AvailableQuestsVBox even with fallback")
	
	if not guild_roster_grid:
		print("Step 0g: ERROR - guild_roster_grid is null, trying fallback lookup")
		guild_roster_grid = find_child_by_name_recursive("GuildRosterGrid")
		print("Step 0h: Fallback lookup result: ", guild_roster_grid != null)
		if guild_roster_grid:
			print("Step 0i: guild_roster_grid name: ", guild_roster_grid.name)
			print("Step 0j: guild_roster_grid class: ", guild_roster_grid.get_class())
		else:
			print("Step 0i: ERROR - Could not find GuildRosterGrid even with fallback")
	
	print("Step 0k: DataAccessLayer signals will be connected in on_room_entered()")
	# Signal connections are now handled in on_room_entered() to prevent duplicates
	
	# Connect to guild manager signals for quest updates
	if GuildManager:
		GuildManager.quest_completed.connect(_on_quest_completed)
		SignalBus.quest_card_selected.connect(_on_quest_card_selected)
	
	# Connect to character status change signals
	if SignalBus:
		SignalBus.character_status_changed.connect(_on_character_status_changed)
	
	# Connect UI buttons
	if start_quest_button:
		start_quest_button.pressed.connect(_on_start_quest_button_pressed)
	if quest_inventory_button:
		quest_inventory_button.pressed.connect(_on_quest_inventory_button_pressed)

func find_child_by_name_recursive(target_name: String) -> Node:
	"""Find a child node by name recursively"""
	print("  Searching for '", target_name, "' in node '", name, "' (", get_class(), ")")
	
	if name == target_name:
		print("  FOUND: '", target_name, "' at current node")
		return self
	
	for child in get_children():
		print("  Checking child: '", child.name, "' (", child.get_class(), ")")
		var result = child.find_child_by_name_recursive(target_name)
		if result:
			print("  FOUND: '", target_name, "' in child '", child.name, "'")
			return result
	
	print("  NOT FOUND: '", target_name, "' in node '", name, "'")
	return null

func on_room_entered():
	"""Called when entering the quests room"""
	print("=== QUESTS ROOM ENTERED ===")
	
	# Ensure signal connections are established before requesting data
	print("Step 1: Ensuring DataAccessLayer signal connections")
	if DataAccessLayer:
		# Check if signals are connected
		var quest_connections = DataAccessLayer.available_quest_cards_received.get_connections()
		var char_connections = DataAccessLayer.available_characters_received.get_connections()
		print("Step 1a: Quest signal connections: ", quest_connections.size())
		print("Step 1b: Character signal connections: ", char_connections.size())
		
		# Safely disconnect and reconnect to prevent duplicates
		print("Step 1c: Safely disconnecting quest signal")
		if quest_connections.size() > 0:
			DataAccessLayer.available_quest_cards_received.disconnect(_on_available_quest_cards_received)
		print("Step 1d: Connecting quest signal")
		DataAccessLayer.available_quest_cards_received.connect(_on_available_quest_cards_received)
		
		print("Step 1e: Safely disconnecting character signal")
		if char_connections.size() > 0:
			DataAccessLayer.available_characters_received.disconnect(_on_available_characters_received)
		print("Step 1f: Connecting character signal")
		DataAccessLayer.available_characters_received.connect(_on_available_characters_received)
	else:
		print("Step 1a: ERROR - DataAccessLayer is null!")
	
	print("Step 2: Emitting request_available_quest_cards signal")
	# Request data through signals instead of direct access
	SignalBus.request_available_quest_cards.emit()
	print("Step 3: Emitting request_available_characters signal")
	SignalBus.request_available_characters.emit()
	
	print("Step 4: Calling update_room_display()")
	update_room_display()

func on_room_exited():
	"""Called when exiting the quests room"""
	print("QuestsRoom: Room exited - clearing UI")
	## Remove quest cards from UI but don't destroy them
	#for child in available_quests_list.get_children():
		#if child is CompactQuestCard:
			#available_quests_list.remove_child(child)
	
	# Clear selection
	current_selected_quest_card = null
	current_party.clear()
	print("QuestsRoom: Room exit complete - local_quest_cards size: ", local_quest_cards.size())

func update_room_display():
	"""Update the quests display"""
	print("Step 4: update_room_display() called")
	print("Step 4a: current_selected_quest_card is null: ", current_selected_quest_card == null)
	print("Step 4b: local_quest_cards size: ", local_quest_cards.size())
	
	update_quests_display()
	
	# If no quest is selected but we have quest cards, select the first one
	if not current_selected_quest_card and not local_quest_cards.is_empty():
		current_selected_quest_card = local_quest_cards[0]
		print("Step 4c: Auto-selected first quest card: ", current_selected_quest_card)
		
		# Update the quest details display for the selected card
		update_quest_details_display(current_selected_quest_card)
		
		## grab our available characters, and select the first one
		#var temp_pty = DataAccessLayer.get_available_characters()
		#
		#if temp_pty.size() != 0 :
			#current_party.append(temp_pty[0])
		update_party_selection_display()
		#else :
			#return
	# Clear quest details if no quest is selected and no quest cards available
	elif not current_selected_quest_card and quest_details_panel:
		UIUtilities.clear_container(quest_details_panel)
		
		# Add placeholder text using UIUtilities
		var placeholder = UIUtilities.create_placeholder_label("Select a quest to view details")
		quest_details_panel.add_child(placeholder)

func update_quests_display():
	"""Update the quests display with all available quests"""
	print("Step 5: update_quests_display() called")
	print("Step 5a: available_quests_list is null: ", available_quests_list == null)
	print("Step 5b: local_quest_cards size: ", local_quest_cards.size())
	
	# Check if container is available
	if not available_quests_list:
		print("Step 5c: ERROR - available_quests_list is null, cannot update display")
		return
	
	print("Step 5d: available_quests_list found, clearing existing quest cards")
	# Clear existing quest cards
	print("Step 5e: Current children in available_quests_list: ", available_quests_list.get_child_count())
	for child in available_quests_list.get_children():
		if child is CompactQuestCard:
			print("Step 5f: Removing quest card: ", child)
			available_quests_list.remove_child(child)
	
	print("Step 5g: Adding quest cards from local cache")
	# Add quest cards from local cache
	
	
	
	for i in range(local_quest_cards.size()):
		var quest_card = local_quest_cards[i]
		print("Step 5h: Processing quest card ", i, ": ", quest_card)
		if quest_card:
			print("Step 5i: Adding quest card to UI: ", quest_card)
			available_quests_list.add_child(quest_card)
			print("Step 5j: Added quest card to UI. available_quests_list now has ", available_quests_list.get_child_count(), " children")
		else:
			print("Step 5k: Quest card is null, skipping")
	
	# Wait a frame for the panels to be added to the scene tree
	await get_tree().process_frame
	
	# Update visual states for all quest panels
	if current_selected_quest_card:
		update_quest_panel_states(current_selected_quest_card)
	elif current_selected_quest_card == null :
		current_selected_quest_card = available_quests_list.get_child(0)
		update_quest_panel_states(current_selected_quest_card)

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

# Signal handlers for data updates
func _on_available_quest_cards_received(quest_cards: Array):
	"""Handle available quest cards data received from data access layer"""
	print("=== SIGNAL HANDLER CALLED ===")
	print("Step 6: _on_available_quest_cards_received() called")
	print("Step 6a: Received quest_cards size: ", quest_cards.size())
	print("Step 6a1: Quest cards received after quest completion/update")
	
	# Debug: Print quest names to see what we're getting
	for i in range(quest_cards.size()):
		var card = quest_cards[i]
		if card and card.has_method("get_quest"):
			var quest = card.get_quest()
			print("Step 6a2: Quest ", i, ": ", quest.quest_name if quest else "null")
	
	# Prevent duplicate processing
	if local_quest_cards.size() == quest_cards.size():
		print("Step 6a1: Skipping duplicate data (same size)")
		return
	
	for i in range(quest_cards.size()):
		var card = quest_cards[i]
		print("Step 6b: Quest card ", i, ": ", card)
		if card and card.has_method("get_quest"):
			var quest = card.get_quest()
			print("Step 6c: Quest name: ", quest.quest_name if quest else "null")
	
	print("Step 6d: Storing quest cards in local_quest_cards")
	local_quest_cards = quest_cards
	print("Step 6e: local_quest_cards size after assignment: ", local_quest_cards.size())
	
	print("Step 6f: Calling update_quests_display()")
	update_quests_display()

func _on_available_characters_received(characters: Array[Character]):
	"""Handle available characters data received from data access layer"""
	local_available_characters = characters
	update_party_selection_display()

func update_roster_display():
	"""Update the roster display for party selection"""
	update_party_selection_display()

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
	print("AVAILABLE_QUESTS: Quest card selected in quests room: " + str(card.get_quest().quest_name if card and card.get_quest() else "null"))
	
	if card:
		print("Quest Card Selected: " + str(card))
		
		# Update selection state
		current_selected_quest_card = card
		
		# Update visual states for all quest cards
		for quest_card in local_quest_cards:
			quest_card.set_selected(quest_card == card)
		
		# Update displays
		update_quest_details_display(card)
		update_party_selection_display()

	else:
		print("AVAILABLE_QUESTS: No quest card provided")

func reset_quest_tab_to_default():
	"""Reset the quest tab to its default state with no quest selected"""
	# Clear current selections
	current_party.clear()
	
	# Set first quest as selected if available
	if not local_quest_cards.is_empty():
		current_selected_quest_card = local_quest_cards[0]
		# Update displays for the selected quest
		update_quest_details_display(current_selected_quest_card)
		update_party_selection_display()
	else:
		current_selected_quest_card = null
		# Clear quest info display
		if quest_info_label:
			quest_info_label.text = "No quests available"
		
		# Reset stats comparison table to show "Select a quest first"
		if stats_comparison_table and stats_comparison_table.has_method("clear_data"):
			stats_comparison_table.clear_data()
		
		# Clear party list using UIUtilities
		UIUtilities.clear_container(guild_roster_grid)

func update_party_selection_display():
	"""Update the party selection display"""
	if not current_selected_quest_card:
		return
		
	# Update the grid display and stats comparison
	update_available_characters_display(local_available_characters)
	
	update_stats_comparison_table()
	update_start_quest_button_state()
	
	# Update success chance display for all quest panels
	update_quest_success_chances()

func update_stats_comparison_table():
	"""Update the stats comparison table with quest requirements and current party stats"""
	if current_selected_quest_card == null:
		return
	
	# Get quest requirements
	var quest_requirements = get_quest_stat_requirements()

	# Update the table
	if stats_comparison_table.has_method("update_quest_requirements"):
		stats_comparison_table.update_quest_requirements(quest_requirements)
	
	# leave if the current party is empty
	if current_party.size() == 0 :
		return
	# Get current party stats
	var party_stats = get_current_party_total_stats()
	if stats_comparison_table.has_method("update_party_stats"):
		stats_comparison_table.update_party_stats(party_stats)

func update_quest_success_chances():
	"""Update success chance displays for all quest panels"""
	if not current_selected_quest_card or current_party.size() == 0:
		return
		
	# Update success chances for all quest cards
	for child in available_quests_list.get_children():
		if child.has_method("set_success_rate"):
			var _quest_card = child
			var quest = _quest_card.get_quest()
			
			if quest == current_selected_quest_card.get_quest():
				# Calculate success chance for selected quest with current party
				var success_chance = quest.get_suggested_success_chance(current_party)
				_quest_card.set_success_rate(success_chance)
			else:
				# Hide success rate for unselected quests
				_quest_card.set_success_rate(-1)

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
	# Clear existing panels using UIUtilities
	UIUtilities.clear_container(guild_roster_grid)
	
	# Create new panels for each available character using UIUtilities
	for character in available_chars:
		var char_panel = UIUtilities.create_character_panel(character, "party_selection")
		guild_roster_grid.add_child(char_panel)
		
		# Connect click handler to the panel
		char_panel.gui_input.connect(func(event): _on_character_panel_input(event, character))
		
		# Store character reference
		char_panel.set_meta("character", character)
		
		# Update visual state
		update_party_selection_panel_state(char_panel, character)

func update_start_quest_button_state():
	"""Update the start quest button state based on current party and quest"""
	if not current_selected_quest_card:
		return
	
	var quest = current_selected_quest_card.get_quest()
	var assignment_check = quest.can_assign_party(current_party)
	start_quest_button.disabled = not assignment_check.can_assign
	start_quest_button.text = "Start Quest" if assignment_check.can_assign else "Cannot Start: " + str(assignment_check.reasons[0] if not assignment_check.reasons.is_empty() else "Unknown")
	
	# Enable inventory button when a quest is selected
	if quest_inventory_button:
		quest_inventory_button.disabled = current_selected_quest_card == null

# This function has been replaced by UIUtilities.create_character_panel(character, "party_selection")

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
	var button = panel.get_child(0) if panel.get_child_count() > 0 else null
	
	# Get character status and determine if character is available
	var character_status = get_character_status(character)
	var is_available = character_status == "available"
	
	# Update button disabled state based on availability
	if button and button is Button:
		button.disabled = not is_available
	
	# Update panel appearance based on selection state and status
	if is_in_party:
		panel.modulate = Color.GREEN
	else:
		# Apply status-based modulation
		match character_status:
			"injured":
				panel.modulate = Color.RED
			"on_quest":
				panel.modulate = Color.YELLOW
			"awaiting":
				panel.modulate = Color.BLUE
			_:
				panel.modulate = Color.WHITE

func get_character_status(character: Character) -> String:
	"""Get the current status of a character"""
	# Check for injuries first (highest priority)
	if character.is_injured():
		return "injured"
	
	# Check for quest status
	if character.is_on_quest():
		return "on_quest"
	
	# Check for awaiting status (for future mechanics)
	if character.is_waiting_to_progress():
		return "awaiting"
	
	# Check for other status conditions
	match character.character_status:
		Character.CharacterStatus.WAITING_FOR_RESULTS:
			return "awaiting"
		Character.CharacterStatus.WAITING_TO_PROGRESS:
			return "awaiting"
		Character.CharacterStatus.ON_QUEST:
			return "on_quest"
		_:
			return "available"

func _on_character_status_changed(character: Character):
	"""Handle when a character's status changes - update only the specific character panel"""
	# Find and update the specific character panel without redrawing the entire scene
	for child in guild_roster_grid.get_children():
		if child.has_meta("character"):
			var panel_character = child.get_meta("character")
			if panel_character == character:
				update_party_selection_panel_state(child, character)
				break

func _on_quest_completed(quest: Quest):
	"""Handle when a quest is completed"""
	print("QuestsRoom: Quest completed: ", quest.quest_name)
	# Request fresh data
	# SignalBus.request_available_quest_cards.emit()
	# SignalBus.request_available_characters.emit()

func _on_start_quest_button_pressed():
	"""Handle start quest button press"""
	print("AVAILABLE_QUESTS: Quest Started button pressed")
	if current_selected_quest_card and not current_party.is_empty():
		print("AVAILABLE_QUESTS: Starting quest: ", current_selected_quest_card.get_quest().quest_name)
		print("AVAILABLE_QUESTS: Party size: ", current_party.size())
		# This should be handled through a signal, but for now use direct call
		var quest_result = GuildManager.start_quest(current_selected_quest_card, current_party)
		if quest_result.success:
			print("AVAILABLE_QUESTS: Quest started successfully")
			# Clear the current party selection
			current_party.clear()
			# Request fresh data to get any new quests that might have been generated
			SignalBus.request_available_quest_cards.emit()
			SignalBus.request_available_characters.emit()
			
			update_room_display()
			
			# reselect the first quest on the list
			current_selected_quest_card = local_quest_cards[0]
			
		else:
			print("AVAILABLE_QUESTS: Failed to start quest: ", quest_result.message)
	else:
		print("AVAILABLE_QUESTS: Cannot start quest - no quest selected or no party")

func _on_quest_inventory_button_pressed():
	"""Handle quest inventory button press"""
	if not current_selected_quest_card:
		return
	
	# Create quest inventory panel if it doesn't exist
	if not quest_inventory_panel:
		var quest_inventory_scene = preload("res://ui/components/QuestInventoryPanel.tscn")
		quest_inventory_panel = quest_inventory_scene.instantiate()
		quest_inventory_panel.items_confirmed.connect(_on_quest_items_confirmed)
		quest_inventory_panel.panel_closed.connect(_on_quest_inventory_panel_closed)
		add_child(quest_inventory_panel)
	
	# Setup the panel for the current quest
	var quest = current_selected_quest_card.get_quest()
	# Request inventory data through signal (this would need a new signal)
	# For now, use direct access but this should be refactored
	var inventory = GuildManager.get_inventory()
	quest_inventory_panel.setup_for_quest(quest, inventory)
	quest_inventory_panel.visible = true

func _on_quest_items_confirmed(items: Array[InventoryItem], total_cost: int):
	"""Handle when quest items are confirmed"""
	print("Quest items confirmed: ", items.size(), " items, total cost: ", total_cost)
	# TODO: Store the selected items for the quest
	# TODO: Update quest success rate based on items
	# TODO: Update quest cost display

func _on_quest_inventory_panel_closed():
	"""Handle when quest inventory panel is closed"""
	# Panel is already hidden, no additional cleanup needed
	pass

func save_room_state():
	"""Save quests room state"""
	# Save current quest selection and party
	pass  # TODO: Implement if needed

func load_room_state():
	"""Load quests room state"""
	# Restore quest selection and party if available
	pass  # TODO: Implement if needed

func _on_character_panel_input(event: InputEvent, character: Character):
	"""Handle input events on character panels"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		toggle_character_in_party(character)
