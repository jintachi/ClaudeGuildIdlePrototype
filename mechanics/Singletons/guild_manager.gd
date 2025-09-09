extends Node

## Random number generation uses Godot's built-in RandomNumberGenerator with proper seeding
@warning_ignore_start("unused_signal")
signal character_recruited(character: Character)
signal quest_started(quest: Quest)
signal quest_completed(quest: Quest)
signal emergency_quest_available(requirements: Dictionary)
signal transformation_unlocked(transformation_name: String)
signal game_data_loaded()
signal room_changed(from_room: String, to_room: String)
signal room_unlocked(room_name: String)
signal quest_cards_updated()
signal quest_card_moved(quest_card: CompactQuestCard, from_state: String, to_state: String)
@warning_ignore_restore("unused_signal")


# Guild Resources
@export var influence: int = 100
@export var gold: int = 50
@export var building_materials: int = 0
@export var armor_pieces: int = 0
@export var weapons: int = 0
@export var food: int = 20

# Guild State
var cur_scene : StringName # holder for the scene name
@export var roster: Array[Character] = []
@export var max_roster_size: int = 5
@export var available_recruits: Array[Character] = []
@export var recruit_rotation_timer: float = 0.0
@export var recruit_refresh_time: float = 300.0  # 5 minutes

# Quest Management
@export var completed_quests: Array[CompactQuestCard] = []
@export var emergency_quests: Array[CompactQuestCard] = []

# Quest Card Management
var available_quest_cards: Array[CompactQuestCard]  # Array of CompactQuestCard instances
var active_quest_cards: Array[CompactQuestCard]    # Array of CompactQuestCard instances
var awaiting_quest_cards: Array[CompactQuestCard]  # Array of CompactQuestCard instances

# Progression Tracking
@export var total_quests_completed: int = 0
@export var quests_completed_by_rank: Dictionary = {}
@export var transformations_unlocked: Dictionary = {"Roster Size": 5, "Healer's Guild": false, "Armory": false, "Market": false, "Training Ground's": false, "Library": false, "Workshop": false}

# Save System
@export var last_save_time: float = 0.0
@export var auto_save_interval: float = 600.0  # 10 minutes
@export var save_file_path: String = "res://Save_Data/guild_save.json"
@export var current_save_slot: int = 0  # 0, 1, or 2 for the three save slots

# Recruitment Settings
@export var recruitment_quality_modifier: float = 1.0
@export var max_available_recruits: int = 3
@export var recruit_stay_duration: float = 600.0  # 10 minutes

# Room Management System
var current_room: String = "Adventurer's Guild"
var previous_room: String = ""
var room_history: Array[String] = []
var max_history_size: int = 10
var available_rooms: Array[String] = ["Main Hall", "Roster", "Quests", "Recruitment", "Training Room", "Warehouse", "Merchant's Guild", "Blacksmith's Guild", "Healer's Guild"]
var unlocked_rooms: Array[String] = ["Main Hall", "Roster", "Quests", "Recruitment", "Training Room", "Merchant's Guild", "Blacksmith's Guild", "Healer's Guild"]
var cached_room_instances: Dictionary = {}  # Cache room instances to preserve state

# Cached resources
var quest_card_scene: PackedScene

# Inventory System - Now handled by InventoryManager singleton

func _ready():
	print("GuildManager: _ready() called")
	# Load cached resources
	quest_card_scene = load("res://ui/components/CompactQuestCard.tscn")
	
	# Connect to inventory changes to keep resources in sync
	if has_node("/root/InventoryManager"):
		var inventory_manager = get_node("/root/InventoryManager")
		inventory_manager.inventory_changed.connect(_on_inventory_changed)
	
	# Don't initialize anything yet - wait for game_ready signal
	# Only initialize quest completion tracking structure
	for rank in Quest.QuestRank.values():
		quests_completed_by_rank[rank] = 0
	print("GuildManager: _ready() completed - waiting for game initialization")

func _process(delta):
	# Only process if game is initialized
	if is_game_initialized:
		update_quest_timers(delta)
		update_recruitment_timer(delta)
		update_auto_save(delta)

# Game initialization state
var is_game_initialized: bool = false

func initialize_game():
	"""Initialize the game - called when game is ready to start"""
	print("GuildManager: initialize_game() called")
	SignalBus.game_loading_started.emit()
	
	# Initialize all game systems
	initialize_guild()
	check_warehouse_unlock()
	initialize_room_system()
	
	# Mark as initialized
	is_game_initialized = true
	
	# Emit game ready signal
	SignalBus.game_loading_completed.emit()
	SignalBus.game_ready.emit()
	print("GuildManager: Game initialization completed - game is ready!")
	check_for_transformations()

func initialize_guild():
	if roster.is_empty():
		# Start with one basic character
		var starter = Character.new("Guild Founder", Character.CharacterClass.ATTACKER, Character.Quality.TWO_STAR)
		add_character_to_roster(starter)
	
	if available_quest_cards.is_empty():
		generate_initial_quest_cards()
	
	if available_recruits.is_empty():
		generate_recruits()
	
	
	# Inventory system is now handled by InventoryManager singleton
	
	# Refresh quest cards to ensure they display correct data
	refresh_quest_cards()
	
	# Emit signal to notify UI that guild has been initialized (for new games)
	# Use call_deferred to ensure this happens after the scene is ready
	call_deferred("emit_signal", "game_data_loaded")

func generate_initial_quest_cards():
	# Generate some basic F and D rank quests to start
	for i in range(5):
		var quest_rank = Quest.QuestRank.F if i < 3 else Quest.QuestRank.D
		var quest_type = Quest.QuestType.values()[randi() % (Quest.QuestType.values().size() - 1)]  # Exclude EMERGENCY
		var quest = Quest.create_quest(quest_type, quest_rank)
		var quest_card = create_quest_card(quest)
		
		# Check for duplicates before adding
		if not is_quest_card_duplicate(quest_card, available_quest_cards):
			available_quest_cards.append(quest_card)
		else:
			print("GuildManager: Skipping duplicate quest in initial generation: ", quest.quest_name)


func create_quest_card(quest: Quest):
	"""Create a quest card for a given quest"""
	print("GuildManager: create_quest_card() called for quest: ", quest.quest_name if quest else "null")
	var quest_card = quest_card_scene.instantiate()
	
	# Check if the instantiated object is the correct type
	if not quest_card.has_method("populate_with_quest"):
		print("Error: CompactQuestCard scene did not instantiate correctly")
		return null
	
	# Populate with quest data
	quest_card.populate_with_quest(quest)
	print("GuildManager: Quest card created and populated: ", quest_card.get_quest().quest_name if quest_card.get_quest() else "null")
	
	return quest_card

func get_available_quest_cards() -> Array[CompactQuestCard]:
	"""Get all available quest cards (these are unparented)"""
	print("GuildManager: get_available_quest_cards() called")
	print("GuildManager: Available quest cards size: ", available_quest_cards.size())
	for i in range(available_quest_cards.size()):
		var quest_card = available_quest_cards[i]
		if is_instance_valid(quest_card) and quest_card.get_quest():
			print("GuildManager: Quest card ", i, ": ", quest_card.get_quest().quest_name)
		else:
			print("GuildManager: Quest card ", i, ": invalid or null quest")
	print("GuildManager: Returning ", available_quest_cards.size(), " quest cards")
	return available_quest_cards

func get_active_quest_cards() -> Array[CompactQuestCard]:
	"""Get all active quest cards (these are unparented)"""
	return active_quest_cards

func get_awaiting_quest_cards() -> Array[CompactQuestCard]:
	"""Get all awaiting completion quest cards (these are unparented)"""
	return awaiting_quest_cards

func refresh_quest_cards():
	"""Refresh all quest cards to ensure they display correct data"""
	# Refresh available quest cards
	for quest_card in available_quest_cards:
		if is_instance_valid(quest_card) and quest_card.get_quest():
			quest_card.populate_with_quest(quest_card.get_quest())
	
	# Refresh active quest cards
	for quest_card in active_quest_cards:
		if is_instance_valid(quest_card) and quest_card.get_quest():
			quest_card.populate_with_quest(quest_card.get_quest())
	
	# Refresh awaiting quest cards
	for quest_card in awaiting_quest_cards:
		if is_instance_valid(quest_card) and quest_card.get_quest():
			quest_card.populate_with_quest(quest_card.get_quest())
	
	# Emit signal to notify UI that quest cards have been updated
	quest_cards_updated.emit()

func generate_recruits():
	available_recruits.clear()
	
	for i in range(max_available_recruits):
		var character = generate_random_recruit()
		available_recruits.append(character)

func generate_random_recruit() -> Character:
	var classes = Character.CharacterClass.values()
	var char_class = classes[randi() % classes.size()]
	
	# Apply recruitment quality modifier
	var quality_roll: float = randf()
	var _quality := Character.Quality.ONE_STAR
	
	if quality_roll < 0.1 * recruitment_quality_modifier:
		_quality = Character.Quality.THREE_STAR
	elif quality_roll < 0.3 * recruitment_quality_modifier:
		_quality = Character.Quality.TWO_STAR
	else:
		_quality = Character.Quality.ONE_STAR
	
	return Character.new("", char_class, _quality)

func add_character_to_roster(character: Character) -> bool:
	if roster.size() >= max_roster_size:
		return false
	
	roster.append(character)
	character_recruited.emit(character)
	return true

func recruit_character(_character: Character) -> Dictionary:
	var result = {"success": false, "message": ""}
	
	if not _character in available_recruits:
		result.message = "Character not available for recruitment"
		return result
	
	if roster.size() >= max_roster_size:
		result.message = "Roster is full"
		return result
	
	var cost = _character.get_recruitment_cost()
	if not can_afford_cost(cost):
		result.message = "Cannot afford recruitment cost"
		return result
	
	# Pay the cost
	spend_resources(cost)
	
	# Add to roster
	add_character_to_roster(_character)
	available_recruits.erase(_character)
	
	result.success = true
	result.message = "Successfully recruited " + _character.character_name
	return result

func can_afford_cost(cost: Dictionary) -> bool:
	return (influence >= cost.get("influence", 0) and
			gold >= cost.get("gold", 0) and
			food >= cost.get("food", 0) and
			armor_pieces >= cost.get("armor", 0) and
			weapons >= cost.get("weapons", 0))

func spend_resources(cost: Dictionary):
	influence -= cost.get("influence", 0)
	gold -= cost.get("gold", 0)
	food -= cost.get("food", 0)
	armor_pieces -= cost.get("armor", 0)
	weapons -= cost.get("weapons", 0)

func add_resources(resources: Dictionary):
	influence += resources.get("influence", 0)
	gold += resources.get("gold", 0)
	building_materials += resources.get("building_materials", 0)
	armor_pieces += resources.get("armor", 0)
	weapons += resources.get("weapons", 0)
	food += resources.get("food", 0)

func start_quest(quest_card: CompactQuestCard, party: Array[Character]) -> Dictionary:
	var result = {"success": false, "message": ""}
	
	if not quest_card in available_quest_cards:
		result.message = "Quest not available"
		return result
	
	var assignment_check = quest_card.get_quest().can_assign_party(party)
	if not assignment_check.can_assign:
		result.message = "Party requirements not met: " + str(assignment_check.reasons)
		return result
	
	# Pay upkeep costs
	var total_upkeep = 0
	for character in party:
		total_upkeep += character.get_upkeep_cost()
	
	if food < total_upkeep:
		result.message = "Not enough food for party upkeep"
		return result
	
	food -= total_upkeep
	
	# Start the quest
	print("AVAILABLE_QUESTS: GuildManager.start_quest() - calling quest.start_quest()")
	if quest_card.get_quest().start_quest(party):
		print("AVAILABLE_QUESTS: Quest started successfully, moving from available to active")
		print("AVAILABLE_QUESTS: Available quest cards before removal: ", available_quest_cards.size())
		
		# Move quest from available to active
		print("AVAILABLE_QUESTS: Removing quest card from available_quest_cards: ", quest_card.get_quest().quest_name)
		print("AVAILABLE_QUESTS: Available quest cards before removal: ", available_quest_cards.size())
		available_quest_cards.erase(quest_card)
		print("AVAILABLE_QUESTS: Available quest cards after removal: ", available_quest_cards.size())
		print("AVAILABLE_QUESTS: Adding quest card to active_quest_cards: ", quest_card.get_quest().quest_name)
		active_quest_cards.append(quest_card)
		print("AVAILABLE_QUESTS: Active quest cards after addition: ", active_quest_cards.size())
		
		print("AVAILABLE_QUESTS: Available quest cards after removal: ", available_quest_cards.size())
		
		# Generate a replacement quest to maintain quest availability
		print("AVAILABLE_QUESTS: Generating replacement quest")
		generate_replacement_quest_card(quest_card.get_quest().quest_rank)
		
		print("AVAILABLE_QUESTS: Available quest cards after replacement generation: ", available_quest_cards.size())
		
		quest_card.set_active_party_roster(quest_card.get_quest())
		print("AVAILABLE_QUESTS: Available quest cards before save_game(): ", available_quest_cards.size())
		save_game()  # Save when starting quest
		print("AVAILABLE_QUESTS: Available quest cards after save_game(): ", available_quest_cards.size())
		
		result.success = true
		result.message = "Quest started successfully"
	else:
		result.message = "Failed to start quest"
	
	return result

func find_quest_card_by_quest(quest: Quest, card_array: Array):
	"""Find a quest card by its associated quest"""
	for card in card_array:
		if card.quest_card == quest:
			return card
	return null

func update_quest_timers(_delta: float):
	if current_room == "Main Hall":
		var completed_this_frame : Array[CompactQuestCard] = []
		
		for card in active_quest_cards:
			if card == null : return
			elif card.get_quest().update_quest_progress():
				print("GuildManager: Quest completed during timer update: ", card.get_quest().quest_name)
				completed_this_frame.append(card)
		
		for card in completed_this_frame:
			complete_quest(card)

func complete_quest(quest_card: CompactQuestCard):
	print("AVAILABLE_QUESTS: Quest completed, moving from active to awaiting")
	print("AVAILABLE_QUESTS: Quest name: ", quest_card.get_quest().quest_name)
	
	# Check if quest is already in awaiting array to prevent duplicates
	if quest_card in awaiting_quest_cards:
		print("GuildManager: Quest already in awaiting array, skipping duplicate")
		return
	
	# Move quest card from active to awaiting
	print("GuildManager: Moving quest from active to awaiting: ", quest_card.get_quest().quest_name)
	print("GuildManager: Active quest cards before removal: ", active_quest_cards.size())
	active_quest_cards.erase(quest_card)
	print("GuildManager: Active quest cards after removal: ", active_quest_cards.size())
	print("GuildManager: Awaiting quest cards before addition: ", awaiting_quest_cards.size())
	awaiting_quest_cards.append(quest_card)
	print("GuildManager: Awaiting quest cards after addition: ", awaiting_quest_cards.size())
	print("AVAILABLE_QUESTS: Available quests after removal: ", available_quest_cards.size())
	print("AVAILABLE_QUESTS: Active quests after removal: ", active_quest_cards.size())
	print("AVAILABLE_QUESTS: Awaiting quests after addition: ", awaiting_quest_cards.size())
	# Remove from current parent to allow reparenting
	if quest_card.get_parent():
		quest_card.get_parent().remove_child(quest_card)
	
	# Generate replacement quest BEFORE saving
	print("AVAILABLE_QUESTS: Generating replacement quest when quest completes")
	generate_replacement_quest_card(quest_card.get_quest().quest_rank)
	
	# Emit signal for awaiting completion
	quest_completed.emit(quest_card.get_quest())
	quest_card_moved.emit(quest_card, "active", "awaiting")
	
	# Save game when quest moves to awaiting completion (now with replacement quest)
	save_game()

func accept_quest_results(quest_card: CompactQuestCard):
	"""Accept quest results and finalize the quest"""
	print("AVAILABLE_QUESTS: Accept quest results called")
	print("AVAILABLE_QUESTS: Quest name: ", quest_card.get_quest().quest_name)
	print("AVAILABLE_QUESTS: Awaiting quests before removal: ", awaiting_quest_cards.size())
	
	# Store quest info before destroying the card
	var quest = quest_card.get_quest()
	var quest_rank = quest.quest_rank
	
	# Remove quest card from awaiting and clean it up
	if quest_card:
		awaiting_quest_cards.erase(quest_card)
		print("AVAILABLE_QUESTS: Awaiting quests after removal: ", awaiting_quest_cards.size())
		# Remove from current parent before cleanup
		if quest_card.get_parent():
			quest_card.get_parent().remove_child(quest_card)
		print("AVAILABLE_QUESTS: Quest card valid before queue_free: ", is_instance_valid(quest_card))
		if is_instance_valid(quest_card):
			quest_card.queue_free()
		print("AVAILABLE_QUESTS: Quest card valid after queue_free: ", is_instance_valid(quest_card))
	
	# Accept the quest results (this will apply rewards, injuries, and emit notifications)
	print("AVAILABLE_QUESTS: Calling quest.accept_quest_results()")
	quest.accept_quest_results()
	
	# Emit signal (replacement quest already generated in complete_quest)
	quest_card_moved.emit(null, "awaiting", "completed")
	
	# Add guild rewards (20% of gold goes to guild)
	var guild_gold = int(quest.gold_reward * 0.2)
	gold += guild_gold
	
	# Add other rewards
	var rewards = {
		"influence": quest.influence_reward,
		"building_materials": quest.building_materials,
		"armor": quest.armor_pieces,
		"weapons": quest.weapons,
		"food": quest.food
	}
	add_resources(rewards)
	
	# Update progression tracking
	total_quests_completed += 1
	quests_completed_by_rank[quest.quest_rank] = quests_completed_by_rank.get(quest.quest_rank, 0) + 1
	
	# Check for warehouse unlock after quest completion
	check_warehouse_unlock()
	
	# Emit finalization signal for notifications
	SignalBus.quest_finalized.emit(quest)
	
	# Save game after accepting results
	save_game()

func remove_completed_quest(quest: Quest):
	"""Remove a completed quest from the completed_quests list after rewards have been collected"""
	completed_quests.erase(quest)

func is_quest_card_duplicate(new_card: CompactQuestCard, existing_cards: Array[CompactQuestCard]) -> bool:
	"""Check if a quest card is a duplicate of an existing one"""
	if not new_card or not new_card.get_quest():
		return false
	
	var new_quest = new_card.get_quest()
	
	for existing_card in existing_cards:
		if is_instance_valid(existing_card) and existing_card.get_quest():
			var existing_quest = existing_card.get_quest()
			# Check if quests have the same unique ID
			if new_quest.quest_id == existing_quest.quest_id and new_quest.quest_id != "":
				return true
	
	return false

func cleanup_duplicate_quests():
	"""Remove duplicate quests from all quest arrays"""
	print("GuildManager: Cleaning up duplicate quests...")
	
	# Clean up awaiting quest cards
	var unique_awaiting : Array[CompactQuestCard]
	var seen_quests = {}
	for card in awaiting_quest_cards:
		if is_instance_valid(card) and card.get_quest():
			var quest = card.get_quest()
			var quest_key = quest.quest_id if quest.quest_id != "" else quest.quest_name + "_" + str(quest.quest_type)
			if not seen_quests.has(quest_key):
				seen_quests[quest_key] = true
				unique_awaiting.append(card)
			else:
				print("GuildManager: Removing duplicate awaiting quest: ", quest.quest_name)
	awaiting_quest_cards = unique_awaiting
	
	# Clean up available quest cards
	var unique_available : Array[CompactQuestCard] = []
	seen_quests.clear()
	for card in available_quest_cards:
		if is_instance_valid(card) and card.get_quest():
			var quest = card.get_quest()
			var quest_key = quest.quest_id if quest.quest_id != "" else quest.quest_name + "_" + str(quest.quest_type)
			if not seen_quests.has(quest_key):
				seen_quests[quest_key] = true
				unique_available.append(card)
			else:
				print("GuildManager: Removing duplicate available quest: ", quest.quest_name)
	available_quest_cards = unique_available
	
	# Clean up active quest cards
	var unique_active : Array[CompactQuestCard] = []
	seen_quests.clear()
	for card in active_quest_cards:
		if is_instance_valid(card) and card.get_quest():
			var quest = card.get_quest()
			var quest_key = quest.quest_id if quest.quest_id != "" else quest.quest_name + "_" + str(quest.quest_type)
			if not seen_quests.has(quest_key):
				seen_quests[quest_key] = true
				unique_active.append(card)
			else:
				print("GuildManager: Removing duplicate active quest: ", quest.quest_name)
	active_quest_cards = unique_active
	
	print("GuildManager: Duplicate cleanup completed")

func generate_replacement_quest_card(completed_rank: Quest.QuestRank):
	print("GuildManager: generate_replacement_quest_card() called for rank: ", completed_rank)
	print("GuildManager: Available quest cards before generation: ", available_quest_cards.size())
	
	# Generate a new quest of similar or slightly higher rank
	var new_rank = completed_rank
	if randf() < 0.1 and completed_rank < Quest.QuestRank.SSS:  # 10% chance for higher rank
		new_rank = Quest.QuestRank.values()[completed_rank + 1]
		print("GuildManager: Upgraded quest rank to: ", new_rank)
	
	var quest_type = Quest.QuestType.values()[randi() % (Quest.QuestType.values().size() - 1)]  # Exclude EMERGENCY
	print("GuildManager: Selected quest type: ", quest_type)
	var new_quest = Quest.create_quest(quest_type, new_rank)
	print("GuildManager: Created new quest: ", new_quest.quest_name if new_quest else "null")
	
	# Create quest card for the new quest
	var new_quest_card = create_quest_card(new_quest)
	print("GuildManager: Created quest card: ", new_quest_card if new_quest_card else "null")
	if new_quest_card:
		print("GuildManager: Quest card valid: ", is_instance_valid(new_quest_card))
		print("GuildManager: Quest card has quest: ", new_quest_card.get_quest() != null)
		
		# Check for duplicates before adding
		if not is_quest_card_duplicate(new_quest_card, available_quest_cards):
			print("GuildManager: Adding new quest card to available_quest_cards: ", new_quest_card.get_quest().quest_name)
			available_quest_cards.append(new_quest_card)
			print("GuildManager: Added quest card to available_quest_cards. Total available: ", available_quest_cards.size())
		else:
			print("GuildManager: Skipping duplicate quest card: ", new_quest_card.get_quest().quest_name)
	else:
		print("GuildManager: Failed to create quest card!")

func update_recruitment_timer(delta: float):
	recruit_rotation_timer += delta
	
	if recruit_rotation_timer >= recruit_refresh_time:
		rotate_recruits()
		recruit_rotation_timer = 0.0

func rotate_recruits():
	# Remove recruits who've stayed too long, add new ones
	var recruits_to_remove : Array[Character] = []
	for recruit in available_recruits:
		if randf() < 0.3:  # 30% chance each recruit leaves
			recruits_to_remove.append(recruit)
	
	for recruit in recruits_to_remove:
		available_recruits.erase(recruit)
	
	# Fill up to max recruits
	while available_recruits.size() < max_available_recruits:
		available_recruits.append(generate_random_recruit())

func force_recruit_refresh() -> Dictionary:
	var cost = {"influence": 10}
	if not can_afford_cost(cost):
		return {"success": false, "message": "Cannot afford refresh cost"}
	
	spend_resources(cost)
	generate_recruits()
	return {"success": true, "message": "Recruits refreshed"}

func get_available_characters() -> Array[Character]:
	# Return all characters, sorted with available ones first, then on quest, then injured
	var sorted_roster = roster.duplicate()
	sorted_roster.sort_custom(func(a, b): 
		# Available characters first (can go on quest)
		var a_available = a.can_go_on_quest()
		var b_available = b.can_go_on_quest()
		if a_available != b_available:
			return a_available > b_available
		
		# Among unavailable characters, on-quest characters come before injured ones
		if not a_available and not b_available:
			var a_on_quest = a.character_status == Character.CharacterStatus.ON_QUEST
			var b_on_quest = b.character_status == Character.CharacterStatus.ON_QUEST
			if a_on_quest != b_on_quest:
				return a_on_quest > b_on_quest
		
		# If same status, sort by name for consistency
		return a.character_name < b.character_name
	)
	return sorted_roster

func get_characters_needing_promotion() -> Array[Character]:
	return roster.filter(func(c): return c.promotion_quest_available)

func check_for_transformations():
	# Check if we meet requirements for transformation unlocks
	var current_roster_size = roster.size()
	var _high_rank_count = roster.filter(func(c): return c.rank >= Character.Rank.D).size()
	
	# First transformation: Roster expansion
	if not "roster_expansion_1" in transformations_unlocked:
		if current_roster_size >= 5 and total_quests_completed >= 10:
			var d_rank_members = roster.filter(func(c): return c.rank >= Character.Rank.D).size()
			var d_rank_quests = quests_completed_by_rank.get(Quest.QuestRank.D, 0)
			
			if d_rank_members >= 5 and d_rank_quests >= 10:
				create_emergency_quest("roster_expansion_1")

func create_emergency_quest(transformation_type: String):
	var requirements = get_transformation_requirements(transformation_type)
	emergency_quest_available.emit(requirements)
	
	# Create the actual emergency quest
	var emergency_quest = Quest.new()
	emergency_quest.quest_type = Quest.QuestType.EMERGENCY
	emergency_quest.quest_rank = Quest.QuestRank.S
	emergency_quest.quest_name = requirements.name
	emergency_quest.description = requirements.description
	emergency_quest.allow_partial_failure = false
	emergency_quest.min_party_size = requirements.min_party_size
	emergency_quest.required_tank = true
	emergency_quest.required_healer = true
	emergency_quest.duration = 600.0  # 10 minutes
	emergency_quest.difficulty_modifier = 2.0
	
	emergency_quests.append(emergency_quest)

func get_transformation_requirements(transformation_type: String) -> Dictionary:
	match transformation_type:
		"roster_expansion_1":
			return {
				"name": "EMERGENCY: Expand Guild Quarters",
				"description": "A sudden influx of potential recruits requires immediate expansion of guild facilities.",
				"min_party_size": 4,
				"unlock_description": "Increases roster size to 10 members"
			}
		_:
			return {}

func complete_transformation(transformation_type: String):
	match transformation_type:
		"roster_expansion_1":
			max_roster_size = 10
			transformations_unlocked["Roster Size"] = 10
			transformation_unlocked.emit("Roster Expansion")

func update_auto_save(delta: float):
	last_save_time += delta
	
	# Auto-save every 10 minutes of idle time (no active quests starting)
	if last_save_time >= auto_save_interval:
		save_game()
		last_save_time = 0.0

func save_game():
	print("GuildManager: save_game() called")
	print("GuildManager: Available quest cards before save: ", available_quest_cards.size())
	print("GuildManager: Active quest cards before save: ", active_quest_cards.size())
	print("GuildManager: Awaiting quest cards before save: ", awaiting_quest_cards.size())
	
	# Debug: Check each quest card in the array
	for i in range(available_quest_cards.size()):
		var quest_card = available_quest_cards[i]
		print("GuildManager: Quest card ", i, " valid: ", is_instance_valid(quest_card))
		if is_instance_valid(quest_card):
			print("GuildManager: Quest card ", i, " has quest: ", quest_card.get_quest() != null)
			if quest_card.get_quest():
				print("GuildManager: Quest card ", i, " quest name: ", quest_card.get_quest().quest_name)
	
	var save_data = {
		"influence": influence,
		"gold": gold,
		"building_materials": building_materials,
		"armor_pieces": armor_pieces,
		"weapons": weapons,
		"food": food,
		"roster": serialize_characters(roster),
		"max_roster_size": max_roster_size,
		"available_recruits": serialize_characters(available_recruits),
		"available_quest_cards": serialize_quests(available_quest_cards),
		"inventory_data": get_node("/root/InventoryManager").save_inventory_data() if has_node("/root/InventoryManager") else {},
		"active_quest_cards": serialize_quests(active_quest_cards),
		"awaiting_quest_cards": serialize_quests(awaiting_quest_cards),
		"completed_quests": serialize_quests(completed_quests),
		"emergency_quests": serialize_quests(emergency_quests),
		"total_quests_completed": total_quests_completed,
		"quests_completed_by_rank": quests_completed_by_rank,
		"transformations_unlocked": transformations_unlocked,
		"recruitment_quality_modifier": recruitment_quality_modifier,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	print("GuildManager: Serialized available quest cards: ", save_data["available_quest_cards"].size())
	
	# Load existing save file to preserve other slots
	var all_saves = load_all_save_slots()
	all_saves["slot_" + str(current_save_slot)] = save_data
	
	# Debug: Check if save_data can be serialized
	var json_string = JSON.stringify(all_saves)
	if json_string.is_empty():
		print("GuildManager: Error - Failed to serialize save data to JSON")
		return
	
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("GuildManager: Save file written successfully")
	else:
		print("GuildManager: Error - Failed to open save file for writing")
	
	print("GuildManager: Save completed. Available quest cards after save: ", available_quest_cards.size())

func save_game_to_slot(slot: int):
	"""Save game to a specific slot"""
	var original_slot = current_save_slot
	current_save_slot = slot
	save_game()
	current_save_slot = original_slot

func load_all_save_slots() -> Dictionary:
	"""Load all save slots from the save file"""
	var all_saves = {
		"slot_0": null,
		"slot_1": null,
		"slot_2": null
	}
	
	if not FileAccess.file_exists(save_file_path):
		return all_saves
	
	var file = FileAccess.open(save_file_path, FileAccess.READ)
	if not file:
		return all_saves
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		return all_saves
	
	var save_data = json.data
	
	# Check if this is an old format save file (migrate to new format)
	if not save_data.has("slot_0") and save_data.has("influence"):
		# This is an old format save, migrate it to slot 0
		all_saves["slot_0"] = save_data
		# Save the migrated format
		var file_write = FileAccess.open(save_file_path, FileAccess.WRITE)
		if file_write:
			file_write.store_string(JSON.stringify(all_saves))
			file_write.close()
		return all_saves
	
	# Load each slot if it exists
	for i in range(3):
		var slot_key = "slot_" + str(i)
		if save_data.has(slot_key) and save_data[slot_key] != null:
			all_saves[slot_key] = save_data[slot_key]
	
	return all_saves

func get_save_slot_info(slot: int) -> Dictionary:
	"""Get information about a save slot (exists, timestamp, etc.)"""
	var all_saves = load_all_save_slots()
	var slot_key = "slot_" + str(slot)
	
	if not all_saves.has(slot_key) or all_saves[slot_key] == null:
		return {"exists": false, "timestamp": 0, "influence": 0, "gold": 0, "roster_size": 0}
	
	var save_data = all_saves[slot_key]
	return {
		"exists": true,
		"timestamp": save_data.get("timestamp", 0),
		"influence": save_data.get("influence", 0),
		"gold": save_data.get("gold", 0),
		"roster_size": save_data.get("roster", []).size() if save_data.has("roster") else 0
	}

func delete_save_slot(slot: int):
	"""Delete a specific save slot"""
	var all_saves = load_all_save_slots()
	var slot_key = "slot_" + str(slot)
	all_saves[slot_key] = null
	
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(all_saves))
		file.close()

func load_game():
	"""Load game from the current save slot"""
	print("GuildManager: load_game() called")
	load_game_from_slot(current_save_slot)
	print("GuildManager: load_game() completed successfully")

func load_game_from_slot(slot: int):
	"""Load game from a specific save slot"""
	print("GuildManager: load_game_from_slot() called for slot: ", slot)
	
	var all_saves = load_all_save_slots()
	var slot_key = "slot_" + str(slot)
	
	if not all_saves.has(slot_key) or all_saves[slot_key] == null:
		print("No save data found in slot ", slot)
		return
	
	var save_data = all_saves[slot_key]
	print("GuildManager: Save data loaded successfully for slot: ", slot)
	
	# Load resources
	influence = save_data.get("influence", 100)
	gold = save_data.get("gold", 50)
	building_materials = save_data.get("building_materials", 0)
	armor_pieces = save_data.get("armor_pieces", 0)
	weapons = save_data.get("weapons", 0)
	food = save_data.get("food", 20)
	
	# Load roster and other data
	max_roster_size = save_data.get("max_roster_size", 5)
	
	# Load inventory data
	if save_data.has("inventory_data") and has_node("/root/InventoryManager"):
		get_node("/root/InventoryManager").load_inventory_data(save_data["inventory_data"])
	roster = deserialize_characters(save_data.get("roster", []))
	available_recruits = deserialize_characters(save_data.get("available_recruits", []))
	
	print("GuildManager: Loading available quest cards...")
	available_quest_cards = deserialize_quests(save_data.get("available_quest_cards", []))
	print("GuildManager: Available quest cards loaded: ", available_quest_cards.size())
	
	print("GuildManager: Loading active quest cards...")
	active_quest_cards = deserialize_quests(save_data.get("active_quest_cards", []))
	print("GuildManager: Active quest cards loaded: ", active_quest_cards.size())
	
	print("GuildManager: Loading awaiting quest cards...")
	awaiting_quest_cards = deserialize_quests(save_data.get("awaiting_quest_cards", []))
	print("GuildManager: Awaiting quest cards loaded: ", awaiting_quest_cards.size())
	
	print("GuildManager: Loading completed quests...")
	completed_quests = deserialize_quests(save_data.get("completed_quests", []))
	print("GuildManager: Completed quests loaded: ", completed_quests.size())
	
	print("GuildManager: Loading emergency quests...")
	emergency_quests = deserialize_quests(save_data.get("emergency_quests", []))
	print("GuildManager: Emergency quests loaded: ", emergency_quests.size())
	total_quests_completed = save_data.get("total_quests_completed", 0)
	quests_completed_by_rank = save_data.get("quests_completed_by_rank", {})
	transformations_unlocked = save_data.get("transformations_unlocked", ["none"])
	recruitment_quality_modifier = save_data.get("recruitment_quality_modifier", 1.0)
	
	# Set current save slot
	current_save_slot = slot
	
	# Handle offline progress for time-based systems
	handle_offline_progress(save_data.get("timestamp", Time.get_unix_time_from_system()))
	
	# Update resources from inventory materials
	update_resources_from_inventory()
	
	# Refresh quest cards to ensure they display correctly
	refresh_quest_cards()
	
	# Clean up any duplicate quests that might exist in save files
	cleanup_duplicate_quests()
	
	# Log final counts after loading
	print("GuildManager: Final counts after loading:")
	print("  - Available quest cards: ", available_quest_cards.size())
	print("  - Active quest cards: ", active_quest_cards.size())
	print("  - Awaiting quest cards: ", awaiting_quest_cards.size())
	print("  - Completed quests: ", completed_quests.size())
	print("  - Emergency quests: ", emergency_quests.size())
	
	# Emit signal to notify UI that game data has been loaded
	game_data_loaded.emit()
	
	# Set the active room to Main Hall after loading is complete
	print("GuildManager: Setting active room to Main Hall after loading")
	enter_room("Main Hall")

func handle_offline_progress(last_save_timestamp: float):
	var current_time = Time.get_unix_time_from_system()
	var offline_seconds = current_time - last_save_timestamp
	
	if offline_seconds <= 0:
		return
	
	# Update quest progress for active quests only
	var completed_offline : Array[CompactQuestCard] = []
	if active_quest_cards:
		for card in active_quest_cards:
			if is_instance_valid(card) and card.get_quest():
				var quest = card.get_quest()
				quest.start_time -= offline_seconds  # Simulate time passage
				if quest.get_time_remaining() <= 0:
					quest.complete_quest()
					completed_offline.append(card)
	
	for card in completed_offline:
		if is_instance_valid(card):
			complete_quest(card)
	
	# Update recruitment rotation
	var rotations_missed = int(offline_seconds / recruit_refresh_time)
	for i in range(min(rotations_missed, 3)):  # Limit to 3 rotations max
		rotate_recruits()

func serialize_characters(characters: Array[Character]) -> Array:
	var serialized = []
	for character in characters:
		serialized.append(character_to_dict(character))
	return serialized

func deserialize_characters(data: Array) -> Array[Character]:
	var characters: Array[Character] = []
	for char_data in data:
		characters.append(dict_to_character(char_data))
	return characters

func serialize_quests(quests: Array[CompactQuestCard]) -> Array:
	print("GuildManager: serialize_quests() called with ", quests.size(), " quests")
	var serialized = []
	for quest in quests:
		if is_instance_valid(quest) and quest.get_quest():
			serialized.append(quest_to_dict(quest))
		else:
			print("GuildManager: Skipping invalid quest card")
	print("GuildManager: serialize_quests() returning ", serialized.size(), " serialized quests")
	return serialized

func deserialize_quests(data: Array) -> Array[CompactQuestCard]:
	print("GuildManager: deserialize_quests() called with ", data.size(), " quests")
	var quest_cards : Array[CompactQuestCard] = []
	
	if not data or data.is_empty():
		print("GuildManager: No quest data to deserialize")
		return quest_cards
	
	for i in range(data.size()):
		var quest_card_data = data[i]
		print("GuildManager: Deserializing quest ", i, " of ", data.size())
		var quest_card = dict_to_quest(quest_card_data)
		if quest_card:
			quest_cards.append(quest_card)
			print("GuildManager: Successfully deserialized quest ", i)
		else:
			print("GuildManager: Failed to deserialize quest ", i, " - quest_card is null")
	
	print("GuildManager: deserialize_quests() returning ", quest_cards.size(), " quest cards")
	return quest_cards

func character_to_dict(character: Character) -> Dictionary:
	return {
		"character_name": character.character_name,
		"character_class": character.character_class,
		"quality": character.quality,
		"rank": character.rank,
		"level": character.level,
		"experience": character.experience,
		"health": character.health,
		"defense": character.defense,
		"mana": character.mana,
		"spell_power": character.spell_power,
		"attack_power": character.attack_power,
		"movement_speed": character.movement_speed,
		"luck": character.luck,
		"gathering": character.gathering,
		"hunting_trapping": character.hunting_trapping,
		"diplomacy": character.diplomacy,
		"caravan_guarding": character.caravan_guarding,
		"escorting": character.escorting,
		"stealth": character.stealth,
		"odd_jobs": character.odd_jobs,
		"character_status": character.character_status,
		"injury_type": character.injury_type,
		"injury_duration": character.injury_duration,
		"injury_start_time": character.injury_start_time,
		"personal_gold": character.personal_gold,
		"promotion_quest_available": character.promotion_quest_available,
		"promotion_quest_completed": character.promotion_quest_completed,
		"equipment_slots": serialize_equipment_slots(character.equipment_slots)
	}

func serialize_equipment_slots(equipment_slots: Dictionary) -> Dictionary:
	"""Serialize equipment slots to save data"""
	var serialized_slots = {}
	for slot_name in equipment_slots:
		var item = equipment_slots[slot_name]
		if item:
			serialized_slots[slot_name] = item.save_data()
		else:
			serialized_slots[slot_name] = null
	return serialized_slots

func deserialize_equipment_slots(data: Dictionary) -> Dictionary:
	"""Deserialize equipment slots from save data"""
	var equipment_slots = {}
	for slot_name in data:
		var item_data = data[slot_name]
		if item_data:
			var item = InventoryItem.new()
			item.load_data(item_data)
			equipment_slots[slot_name] = item
		else:
			equipment_slots[slot_name] = null
	return equipment_slots

func dict_to_character(data: Dictionary) -> Character:
	var character = Character.new()
	character.character_name = data.get("character_name", "")
	character.character_class = data.get("character_class", Character.CharacterClass.ATTACKER)
	character.quality = data.get("quality", Character.Quality.ONE_STAR)
	character.rank = data.get("rank", Character.Rank.F)
	character.level = data.get("level", 1)
	character.experience = data.get("experience", 0)
	character.health = data.get("health", 100)
	character.defense = data.get("defense", 10)
	character.mana = data.get("mana", 50)
	character.spell_power = data.get("spell_power", 10)
	character.attack_power = data.get("attack_power", 15)
	character.movement_speed = data.get("movement_speed", 10)
	character.luck = data.get("luck", 5)
	character.gathering = data.get("gathering", 0)
	character.hunting_trapping = data.get("hunting_trapping", 0)
	character.diplomacy = data.get("diplomacy", 0)
	character.caravan_guarding = data.get("caravan_guarding", 0)
	character.escorting = data.get("escorting", 0)
	character.stealth = data.get("stealth", 0)
	character.odd_jobs = data.get("odd_jobs", 0)
	character.character_status = data.get("character_status", Character.CharacterStatus.AVAILABLE)
	character.injury_type = data.get("injury_type", Character.InjuryType.NONE)
	character.injury_duration = data.get("injury_duration", 0.0)
	character.injury_start_time = data.get("injury_start_time", 0.0)
	character.personal_gold = data.get("personal_gold", 0)
	character.promotion_quest_available = data.get("promotion_quest_available", false)
	character.promotion_quest_completed = data.get("promotion_quest_completed", false)
	
	# Load equipment data
	if data.has("equipment_slots"):
		character.equipment_slots = deserialize_equipment_slots(data["equipment_slots"])
		character.recalculate_equipment_bonuses()
	
	return character

func quest_to_dict(quest_card: CompactQuestCard) -> Dictionary:
	var quest = quest_card.get_quest()
	# Reduced verbosity - only print for debugging if needed
	# print("GuildManager: Serializing quest: " + quest.quest_name + " with assigned party size: " + str(quest.assigned_party.size()))
	
	# Ensure individual_checks is properly formatted for JSON serialization
	var individual_checks_serializable : Array[bool] = []
	for check in quest.individual_checks:
		individual_checks_serializable.append(bool(check))
	
	return {
		"quest_name": quest.quest_name,
		"quest_id": quest.quest_id,
		"quest_type": quest.quest_type,
		"quest_rank": quest.quest_rank,
		"description": quest.description,
		"duration": quest.duration,
		"difficulty_modifier": quest.difficulty_modifier,
		"allow_partial_failure": quest.allow_partial_failure,
		"min_party_size": quest.min_party_size,
		"max_party_size": quest.max_party_size,
		"required_tank": quest.required_tank,
		"required_healer": quest.required_healer,
		"required_support": quest.required_support,
		"required_attacker": quest.required_attacker,
		"min_total_health": quest.min_total_health,
		"min_total_defense": quest.min_total_defense,
		"min_total_attack_power": quest.min_total_attack_power,
		"min_total_spell_power": quest.min_total_spell_power,
		"min_substat_requirement": quest.min_substat_requirement,
		"base_experience": quest.base_experience,
		"gold_reward": quest.gold_reward,
		"influence_reward": quest.influence_reward,
		"building_materials": quest.building_materials,
		"armor_pieces": quest.armor_pieces,
		"weapons": quest.weapons,
		"food": quest.food,
		"start_time": quest.start_time,
		"assigned_party": serialize_characters(quest.assigned_party),
		"active_quest_status" : quest.active_quest_status,
		"success_rate": quest.success_rate,
		"final_success_rate": quest.final_success_rate,
		"individual_checks": individual_checks_serializable,
		"completion_injuries": quest.completion_injuries,
		"completion_level_ups": quest.completion_level_ups,
		"completion_stats": quest.completion_stats
	}

func fix_character_references(serialized_characters: Array) -> Array[Character]:
	"""Fix character references by finding the actual characters in the roster"""
	var fixed_party: Array[Character] = []
	
	print("GuildManager: fix_character_references() called with ", serialized_characters.size(), " characters")
	print("GuildManager: Current roster size: ", roster.size())
	
	for char_data in serialized_characters:
		# Find the character in the roster by name
		var found_character: Character = null
		for roster_char in roster:
			if roster_char.character_name == char_data.get("character_name", ""):
				found_character = roster_char
				break
		
		if found_character:
			fixed_party.append(found_character)
			print("GuildManager: Fixed character reference for: " + found_character.character_name)
		else:
			print("GuildManager: Warning - Could not find character in roster: " + char_data.get("character_name", ""))
	
	print("GuildManager: Fixed party size: ", fixed_party.size())
	return fixed_party

func dict_to_quest(data: Dictionary) -> CompactQuestCard:
	print("GuildManager: dict_to_quest() called with data: ", data.get("quest_name", "Unknown"))
	
	if not data or data.is_empty():
		print("GuildManager: Empty or null data in dict_to_quest")
		return null
	
	if not quest_card_scene:
		print("GuildManager: Quest card scene not loaded")
		return null
	
	var compact = quest_card_scene.instantiate()
	if not compact:
		print("GuildManager: Failed to instantiate CompactQuestCard")
		return null
	
	var quest = Quest.new()
	if not quest:
		print("GuildManager: Failed to create Quest instance")
		return null
	
	
	# Initialize the individual_checks array properly with a default false value
	quest.individual_checks.append(false)
	
	# Add error handling for missing or invalid data
	if not data.has("quest_name"):
		print("GuildManager: Error - Quest data missing quest_name")
		return null
	
	var assigned_party_size = data.get("assigned_party", []).size()
	print("GuildManager: Deserializing quest: " + data.get("quest_name", "") + " with assigned party size: " + str(assigned_party_size))
	if assigned_party_size > 0:
		print("GuildManager: *** QUEST WITH ASSIGNED PARTY FOUND ***")
		print("GuildManager: Quest status: " + str(data.get("active_quest_status", 0)))
		print("GuildManager: Assigned party data: " + str(data.get("assigned_party", [])))
	quest.quest_name = data.get("quest_name", "")
	quest.quest_id = data.get("quest_id", "")
	# Generate quest_id for backward compatibility if it doesn't exist
	if quest.quest_id == "":
		var timestamp = Time.get_unix_time_from_system()
		var random_id = randi() % 10000
		quest.quest_id = "quest_" + str(timestamp) + "_" + str(random_id)
	quest.quest_type = data.get("quest_type", Quest.QuestType.GATHERING)
	quest.quest_rank = data.get("quest_rank", Quest.QuestRank.F)
	quest.description = data.get("description", "")
	quest.duration = data.get("duration", 60.0)
	quest.difficulty_modifier = data.get("difficulty_modifier", 1.0)
	quest.allow_partial_failure = data.get("allow_partial_failure", true)
	quest.min_party_size = data.get("min_party_size", 1)
	quest.max_party_size = data.get("max_party_size", 4)
	quest.required_tank = data.get("required_tank", false)
	quest.required_healer = data.get("required_healer", false)
	quest.required_support = data.get("required_support", false)
	quest.required_attacker = data.get("required_attacker", false)
	quest.min_total_health = data.get("min_total_health", 0)
	quest.min_total_defense = data.get("min_total_defense", 0)
	quest.min_total_attack_power = data.get("min_total_attack_power", 0)
	quest.min_total_spell_power = data.get("min_total_spell_power", 0)
	quest.min_substat_requirement = data.get("min_substat_requirement", 0)
	quest.base_experience = data.get("base_experience", 20)
	quest.gold_reward = data.get("gold_reward", 15)
	quest.influence_reward = data.get("influence_reward", 5)
	quest.building_materials = data.get("building_materials", 0)
	quest.armor_pieces = data.get("armor_pieces", 0)
	quest.weapons = data.get("weapons", 0)
	quest.food = data.get("food", 0)
	quest.start_time = data.get("start_time", 0.0)
	
	# Fix character references for assigned party
	quest.assigned_party = fix_character_references(data.get("assigned_party", []))
	print("GuildManager: Quest assigned party size after fixing references: " + str(quest.assigned_party.size()))
	
	quest.active_quest_status = data.get("active_quest_status", Quest.QuestStatus.NOTSTARTED)
	quest.success_rate = data.get("success_rate", 0.0)
	quest.final_success_rate = data.get("final_success_rate", 0.0)
	# Convert individual_checks to proper Array[bool] type
	var raw_individual_checks = data.get("individual_checks", [])
	print("GuildManager: Raw individual_checks type: ", typeof(raw_individual_checks))
	print("GuildManager: Raw individual_checks value: ", raw_individual_checks)
	
	# Clear and populate the existing array instead of creating a new one
	quest.individual_checks.clear()
	if raw_individual_checks is Array:
		for check in raw_individual_checks:
			quest.individual_checks.append(bool(check))
		print("GuildManager: Populated individual_checks size: ", quest.individual_checks.size())
	else:
		print("GuildManager: Warning - individual_checks is not an Array, using default false value")
	
	# Ensure we always have at least one element
	if quest.individual_checks.is_empty():
		quest.individual_checks.append(false)
	
	quest.completion_injuries = data.get("completion_injuries", {})
	quest.completion_level_ups = data.get("completion_level_ups", {})
	quest.completion_stats = data.get("completion_stats", {})
	
	# Validate individual_checks array size matches assigned party size
	if quest.has_method("validate_individual_checks"):
		quest.validate_individual_checks()
	else:
		print("GuildManager: Warning - Quest does not have validate_individual_checks method")
	
	compact.populate_with_quest(quest)
	
	# Debug: Verify quest card was populated correctly
	print("AVAILABLE_QUESTS: Created quest card for: " + quest.quest_name)
	print("AVAILABLE_QUESTS: Quest card has quest: " + str(compact.get_quest() != null))
	
	return compact

func clear_save_file():
	"""Clear the current save slot to start fresh"""
	delete_save_slot(current_save_slot)
	
	# Reset all variables to initial state
	influence = 100
	gold = 50
	building_materials = 0
	armor_pieces = 0
	weapons = 0
	food = 20
	roster.clear()
	max_roster_size = 5
	available_recruits.clear()
	print("GuildManager: Clearing available_quest_cards array")
	available_quest_cards.clear()
	active_quest_cards.clear()
	awaiting_quest_cards.clear()
	completed_quests.clear()
	emergency_quests.clear()
	total_quests_completed = 0
	quests_completed_by_rank.clear()
	transformations_unlocked.clear()
	recruitment_quality_modifier = 1.0
	
	initialize_guild()

func get_guild_status_summary() -> Dictionary:
	return {
		"active_quest_cards_count": active_quest_cards.size(),
		"available_characters": get_available_characters().size(),
		"total_characters": roster.size(),
		"characters_needing_promotion": get_characters_needing_promotion().size(),
		"available_recruits": available_recruits.size(),
		"resources": {
			"influence": influence,
			"gold": gold,
			"food": food,
			"building_materials": building_materials,
			"armor": armor_pieces,
			"weapons": weapons
		}
	}

func make_characters_available():
	"""Make all characters with 'waiting to progress' or 'waiting for results' status available again"""
	for character in roster:
		if character.character_status == Character.CharacterStatus.WAITING_TO_PROGRESS or character.character_status == Character.CharacterStatus.WAITING_FOR_RESULTS:
			character.set_status(Character.CharacterStatus.AVAILABLE)

func update_resources_from_inventory():
	"""Update guild resources based on materials in inventory"""
	if not has_node("/root/InventoryManager"):
		print("GuildManager: InventoryManager not found, skipping resource update")
		return
	
	var inventory_manager = get_node("/root/InventoryManager")
	if not inventory_manager.inventory:
		print("GuildManager: Inventory not initialized, skipping resource update")
		return
	
	var inventory = inventory_manager.inventory
	var building_materials_count = 0
	
	# Count building materials from inventory
	for item in inventory.items:
		if item != null and item.item_type == "materials":
			# Check if this is a building material by looking at tags or item_id
			if item.has_tag("crafting") or item.item_id in ["iron_ore", "wood", "stone", "clay", "brick"]:
				building_materials_count += item.quantity
	
	# Update building materials resource
	building_materials = building_materials_count
	
	print("GuildManager: Updated building materials from inventory:")
	print("  - Building materials: ", building_materials)

func _on_inventory_changed():
	"""Handle inventory changes to keep resources in sync"""
	update_resources_from_inventory() 

#region UI Business Logic
# These methods handle UI-related business logic that was previously in guild_hall.gd

func get_quest_display_data(quest: Quest) -> Dictionary:
	"""Get formatted data for quest display panels"""
	return {
		"name": quest.quest_name,
		"progress_percentage": quest.get_progress_percentage(),
		"time_remaining": quest.get_time_remaining(),
		"party_info": quest.get_party_display_info(),
		"status": quest.active_quest_status,
		"completion_time": quest.get_completion_time_string(),
		"rewards": {
			"experience": quest.experience_reward,
			"gold": quest.gold_reward,
			"influence": quest.influence_reward
		}
	}

func get_character_display_data(character: Character) -> Dictionary:
	"""Get formatted data for character display panels"""
	return {
		"name": character.name,
		"class": character.character_class,
		"rank": character.rank,
		"level": character.level,
		"experience": character.experience,
		"experience_to_next": character.get_experience_to_next_level(),
		"status": character.character_status,
		"stats": {
			"health": character.health,
			"defense": character.defense,
			"attack_power": character.attack_power,
			"spell_power": character.spell_power,
			"gathering": character.gathering,
			"stealth": character.stealth,
			"diplomacy": character.diplomacy
		},
		"quality": character.quality,
		"is_injured": character.is_injured(),
		"is_available": character.character_status == Character.CharacterStatus.AVAILABLE
	}

func get_recruit_display_data(character: Character) -> Dictionary:
	"""Get formatted data for recruit display panels"""
	var base_data = get_character_display_data(character)
	base_data["recruitment_cost"] = character.get_recruitment_cost()
	base_data["projected_resources"] = calculate_cost(character.get_recruitment_cost())
	return base_data

func calculate_cost(recruit_cost:Dictionary) -> Dictionary:
	"""Calculate projected resources after recruitment cost"""
	var current_resources = {
		"influence": influence,
		"gold": gold,
		"food": food,
		"building_materials": building_materials,
		"armor": armor_pieces,
		"weapons": weapons
	}
	
	var temp_dict = current_resources.duplicate()
	
	# Subtract recruitment costs from current resources
	temp_dict["influence"] -= recruit_cost.get("influence", 0)
	temp_dict["gold"] -= recruit_cost.get("gold", 0)
	temp_dict["food"] -= recruit_cost.get("food", 0)
	temp_dict["armor"] -= recruit_cost.get("armor", 0)
	temp_dict["weapons"] -= recruit_cost.get("weapons", 0)
	
	return temp_dict

func get_available_rooms() -> Array[Dictionary]:
	"""Get list of available rooms based on guild state"""
	var rooms : Array[Dictionary] = []
	
	# Always available
	rooms.append({
		"name": "Main Hall",
		"description": "The central hub of your guild",
		"is_unlocked": true,
		"unlock_requirement": ""
	})
	
	rooms.append({
		"name": "Roster",
		"description": "Manage your guild members",
		"is_unlocked": true,
		"unlock_requirement": ""
	})
	
	rooms.append({
		"name": "Quests",
		"description": "Accept and manage quests",
		"is_unlocked": true,
		"unlock_requirement": ""
	})
	
	rooms.append({
		"name": "Recruitment",
		"description": "Recruit new guild members",
		"is_unlocked": true,
		"unlock_requirement": ""
	})
	
	# Unlockable rooms based on transformations
	if transformations_unlocked.get("Training Ground's", false):
		rooms.append({
			"name": "Training Grounds",
			"description": "Train and improve your characters",
			"is_unlocked": true,
			"unlock_requirement": "Complete 10 quests"
		})
	
	if transformations_unlocked.get("Library", false):
		rooms.append({
			"name": "Library",
			"description": "Research and skill development",
			"is_unlocked": true,
			"unlock_requirement": "Reach 50 influence"
		})
	
	if transformations_unlocked.get("Workshop", false):
		rooms.append({
			"name": "Workshop",
			"description": "Craft and enhance equipment",
			"is_unlocked": true,
			"unlock_requirement": "Reach 100 influence"
		})
	
	if transformations_unlocked.get("Armory", false):
		rooms.append({
			"name": "Armory",
			"description": "Manage equipment and gear",
			"is_unlocked": true,
			"unlock_requirement": "Reach 25 influence"
		})
	
	if transformations_unlocked.get("Healer's Guild", false):
		rooms.append({
			"name": "Healer's Guild",
			"description": "Heal injured characters",
			"is_unlocked": true,
			"unlock_requirement": "Have 3 injured characters"
		})
	
	return rooms

func get_ui_notification_data() -> Dictionary:
	"""Get data for UI notifications and alerts"""
	return {
		"quest_cards_awaiting_completion": awaiting_quest_cards.size(),
		"characters_needing_promotion": get_characters_needing_promotion().size(),
		"injured_characters": get_injured_characters().size(),
		"available_recruits": available_recruits.size(),
		"low_resources": get_low_resources_warnings()
	}

func get_low_resources_warnings() -> Array[String]:
	"""Get warnings for low resources"""
	var warnings : Array[String] = []
	
	if gold < 10:
		warnings.append("Low gold: %d" % gold)
	if food < 5:
		warnings.append("Low food: %d" % food)
	if influence < 5:
		warnings.append("Low influence: %d" % influence)
	
	return warnings

func get_injured_characters() -> Array[Character]:
	"""Get list of injured characters"""
	var injured : Array[Character] = []
	for character in roster:
		if character.is_injured():
			injured.append(character)
	return injured

func get_character_status_summary() -> Dictionary:
	"""Get summary of character statuses"""
	var summary = {
		"total": roster.size(),
		"available": 0,
		"on_quest": 0,
		"injured": 0,
		"waiting": 0
	}
	
	for character in roster:
		match character.character_status:
			Character.CharacterStatus.AVAILABLE:
				summary.available += 1
			Character.CharacterStatus.ON_QUEST:
				summary.on_quest += 1
			Character.CharacterStatus.WAITING_TO_PROGRESS, Character.CharacterStatus.WAITING_FOR_RESULTS:
				summary.waiting += 1
		
		if character.is_injured():
			summary.injured += 1
	
	return summary

func validate_quest_party(quest: Quest, party: Array[Character]) -> Dictionary:
	"""Validate if a party can take a quest"""
	var validation = {
		"is_valid": true,
		"errors": [],
		"warnings": [],
		"success_rate": 0.0
	}
	
	# Check party size
	if party.size() < quest.min_party_size:
		validation.is_valid = false
		validation.errors.append("Party too small (need %d, have %d)" % [quest.min_party_size, party.size()])
	
	if party.size() > quest.max_party_size:
		validation.is_valid = false
		validation.errors.append("Party too large (max %d, have %d)" % [quest.max_party_size, party.size()])
	
	# Check requirements
	if quest.required_tank and not has_class_in_party(party, Character.CharacterClass.TANK):
		validation.is_valid = false
		validation.errors.append("Quest requires a Tank")
	
	if quest.required_healer and not has_class_in_party(party, Character.CharacterClass.HEALER):
		validation.is_valid = false
		validation.errors.append("Quest requires a Healer")
	
	if quest.required_support and not has_class_in_party(party, Character.CharacterClass.SUPPORT):
		validation.is_valid = false
		validation.errors.append("Quest requires a Support")
	
	if quest.required_attacker and not has_class_in_party(party, Character.CharacterClass.ATTACKER):
		validation.is_valid = false
		validation.errors.append("Quest requires an Attacker")
	
	# Calculate success rate if valid
	if validation.is_valid:
		validation.success_rate = quest.calculate_success_rate()
		
		# Add warnings for low success rate
		if validation.success_rate < 0.3:
			validation.warnings.append("Very low success rate: %.1f%%" % (validation.success_rate * 100))
		elif validation.success_rate < 0.6:
			validation.warnings.append("Low success rate: %.1f%%" % (validation.success_rate * 100))
	
	return validation

func has_class_in_party(party: Array[Character], character_class: Character.CharacterClass) -> bool:
	"""Check if party has a character of the specified class"""
	for character in party:
		if character.character_class == character_class:
			return true
	return false

#endregion 

#region Room Management System
func initialize_room_system():
	"""Initialize the room management system"""
	room_history.append("Main Hall")
	print("Room system initialized")

func enter_room(room_name: String) -> bool:
	"""Enter a specific room"""
	print("GuildManager: enter_room() called for: ", room_name)
	print("GuildManager: enter_room() - Function entry point reached")
	print("GuildManager: enter_room() - About to check unlocked_rooms")
	print("GuildManager: Current room: ", current_room)
	print("GuildManager: Previous room: ", previous_room)
	print("GuildManager: Target room: ", room_name)
	
	if not unlocked_rooms.has(room_name):
		print("Room not unlocked: ", room_name)
		return false
	
	if not available_rooms.has(room_name):
		print("Room not available: ", room_name)
		return false
	
	# Exit current room
	if current_room != "":
		previous_room = current_room
		print("GuildManager: Set previous_room to: ", previous_room)
	
	# Enter new room
	current_room = room_name
	print("GuildManager: Set current_room to: ", current_room)
	
	# Update history
	add_to_room_history(room_name)
	print("GuildManager: Added to room history: ", room_name)
	
	# Emit room change signal
	print("GuildManager: About to emit room_changed signal from %s to %s" % [previous_room, room_name])
	room_changed.emit(previous_room, room_name)
	print("GuildManager: Emitted room_changed signal")
	print("Entered room: ", room_name)
	return true

func return_to_main_hall():
	"""Return to the main hall"""
	enter_room("Main Hall")

func go_back():
	"""Go back to the previous room in history"""
	if room_history.size() > 1:
		room_history.pop_back()  # Remove current room
		var previous_room_name = room_history[-1]
		enter_room(previous_room_name)

func add_to_room_history(room_name: String):
	"""Add room to navigation history"""
	room_history.append(room_name)
	if room_history.size() > max_history_size:
		room_history.pop_front()

func get_current_room() -> String:
	"""Get the currently active room"""
	return current_room

func get_room_history() -> Array[String]:
	"""Get the room navigation history"""
	return room_history.duplicate()

func get_unlocked_rooms() -> Array[String]:
	"""Get list of unlocked rooms"""
	return unlocked_rooms.duplicate()

func unlock_room(room_name: String):
	"""Unlock a room"""
	if not unlocked_rooms.has(room_name):
		unlocked_rooms.append(room_name)
		room_unlocked.emit(room_name)
		print("Room unlocked: ", room_name)

func get_completed_quest_count() -> int:
	"""Get the number of completed quests"""
	return completed_quests.size()

func check_warehouse_unlock():
	"""Check if warehouse should be unlocked"""
	if is_room_unlocked("Warehouse"):
		return  # Already unlocked
	
	# Check unlock requirements
	var guild_status = get_guild_status_summary()
	var completed_quest_count = get_completed_quest_count()
	
	# Require 10 completed quests and 1000 gold
	if completed_quest_count >= 10 and guild_status.resources.gold >= 1000:
		unlock_room("Warehouse")
		print("Warehouse unlocked! Requirements met: %d quests, %d gold" % [completed_quest_count, guild_status.resources.gold])
		
		# Show notification
		# TODO: Add notification system integration
		print("Warehouse unlocked! You can now store and manage your guild's items.")

func is_room_unlocked(room_name: String) -> bool:
	"""Check if a room is unlocked"""
	return unlocked_rooms.has(room_name)

func can_enter_room(room_name: String) -> bool:
	"""Check if a room can be entered"""
	return unlocked_rooms.has(room_name) and available_rooms.has(room_name)

func get_cached_room_instance(room_name: String):
	"""Get a cached room instance, creating it if it doesn't exist"""
	print("GuildManager: get_cached_room_instance() called for: ", room_name)
	print("GuildManager: Current cached instances: ", cached_room_instances.keys())
	
	if not cached_room_instances.has(room_name):
		print("GuildManager: Room not in cache, creating new instance")
		var room_instance = create_room_instance(room_name)
		if room_instance:
			cached_room_instances[room_name] = room_instance
			print("GuildManager: Created cached instance for room: ", room_name)
		else:
			print("GuildManager: Failed to create room instance for: ", room_name)
	else:
		print("GuildManager: Found cached instance for room: ", room_name)
	
	var result = cached_room_instances.get(room_name, null)
	print("GuildManager: Returning room instance: ", result)
	return result

func create_room_instance(room_name: String):
	"""Create a room instance for the given room name"""
	var room_scene_path = ""
	match room_name:
		"Main Hall":
			room_scene_path = "res://scenes/rooms/MainHallRoom.tscn"
		"Roster":
			room_scene_path = "res://scenes/rooms/RosterRoom.tscn"
		"Quests":
			room_scene_path = "res://scenes/rooms/QuestsRoom.tscn"
		"Recruitment":
			room_scene_path = "res://scenes/rooms/RecruitmentRoom.tscn"
		"Training Room":
			room_scene_path = "res://scenes/rooms/TrainingRoom.tscn"
		"Warehouse":
			room_scene_path = "res://scenes/rooms/WarehouseRoom.tscn"
		"Merchant's Guild":
			room_scene_path = "res://scenes/rooms/MerchantsGuildRoom.tscn"
		"Blacksmith's Guild":
			room_scene_path = "res://scenes/rooms/BlacksmithsGuildRoom.tscn"
		"Healer's Guild":
			room_scene_path = "res://scenes/rooms/HealersGuildRoom.tscn"
	
	if room_scene_path and ResourceLoader.exists(room_scene_path):
		var room_scene = load(room_scene_path)
		var room_instance = room_scene.instantiate()
		print("GuildManager: Created room instance for: ", room_name)
		return room_instance
	else:
		print("GuildManager: Room scene not found: ", room_scene_path)
		return null

func clear_room_cache():
	"""Clear all cached room instances (useful for memory management)"""
	for room_instance in cached_room_instances.values():
		if is_instance_valid(room_instance):
			room_instance.queue_free()
	cached_room_instances.clear()
	print("GuildManager: Cleared room cache")
#endregion 

#region Inventory System
# Inventory system is now handled by the InventoryManager singleton
# All inventory operations should go through InventoryManager
#endregion 
