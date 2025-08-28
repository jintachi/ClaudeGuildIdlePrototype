extends Node

## Data Access Layer
## Provides a clean interface for scenes to request data from GuildManager
## All data access should go through this layer instead of direct GuildManager access

# Response signals for data requests
signal roster_data_received(roster: Array[Character])
signal available_characters_received(characters: Array[Character])
signal characters_needing_promotion_received(characters: Array[Character])
signal injured_characters_received(characters: Array[Character])
signal character_display_data_received(character: Character, display_data: Dictionary)
signal recruit_display_data_received(character: Character, display_data: Dictionary)

signal available_quest_cards_received(quest_cards: Array)
signal active_quest_cards_received(quest_cards: Array)
signal awaiting_quest_cards_received(quest_cards: Array)
signal quest_display_data_received(quest: Quest, display_data: Dictionary)
signal quest_validation_received(quest: Quest, party: Array[Character], validation: Dictionary)

signal guild_resources_received(resources: Dictionary)
signal guild_status_summary_received(summary: Dictionary)
signal resource_display_data_received(display_data: Dictionary)
signal cost_calculation_received(cost: Dictionary, projected_resources: Dictionary)
signal can_afford_check_received(cost: Dictionary, can_afford: bool)

signal available_recruits_received(recruits: Array[Character])
signal recruitment_cost_received(character: Character, cost: Dictionary)
signal recruit_refresh_completed(result: Dictionary)

# Cached data to reduce signal overhead
var _cached_roster: Array[Character] = []
var _cached_available_characters: Array[Character] = []
var _cached_quest_cards: Array = []
var _cached_resources: Dictionary = {}
var _cache_timestamp = Time.get_unix_time_from_system()
var _cache_duration: float = 1.0  # Cache for 1 second

func _ready():
	print("DataAccessLayer: _ready() called")
	setup_signal_connections()
	print("DataAccessLayer: setup_signal_connections() completed")
	
	# Test direct access to GuildManager
	print("DataAccessLayer: Testing direct GuildManager access")
	var test_quest_cards = GuildManager.get_available_quest_cards()
	print("DataAccessLayer: Direct test - quest cards count: ", test_quest_cards.size())

func setup_signal_connections():
	"""Setup connections to GuildManager signals"""
	# Connect to GuildManager signals for data updates (cache invalidation)
	GuildManager.character_recruited.connect(_on_character_recruited)
	GuildManager.quest_started.connect(_on_quest_started)
	GuildManager.quest_completed.connect(_on_quest_completed)
	GuildManager.quest_card_moved.connect(_on_quest_card_moved)
	
	# Connect to SignalBus request signals
	SignalBus.request_roster_data.connect(_on_request_roster_data)
	SignalBus.request_available_characters.connect(_on_request_available_characters)
	SignalBus.request_characters_needing_promotion.connect(_on_request_characters_needing_promotion)
	SignalBus.request_injured_characters.connect(_on_request_injured_characters)
	SignalBus.request_character_display_data.connect(_on_request_character_display_data)
	SignalBus.request_recruit_display_data.connect(_on_request_recruit_display_data)
	
	SignalBus.request_available_quest_cards.connect(_on_request_available_quest_cards)
	SignalBus.request_active_quest_cards.connect(_on_request_active_quest_cards)
	SignalBus.request_awaiting_quest_cards.connect(_on_request_awaiting_quest_cards)
	SignalBus.request_quest_display_data.connect(_on_request_quest_display_data)
	SignalBus.request_quest_validation.connect(_on_request_quest_validation)
	
	SignalBus.request_guild_resources.connect(_on_request_guild_resources)
	SignalBus.request_guild_status_summary.connect(_on_request_guild_status_summary)
	SignalBus.request_resource_display_data.connect(_on_request_resource_display_data)
	SignalBus.request_cost_calculation.connect(_on_request_cost_calculation)
	SignalBus.request_can_afford_check.connect(_on_request_can_afford_check)
	
	SignalBus.request_available_recruits.connect(_on_request_available_recruits)
	SignalBus.request_recruitment_cost.connect(_on_request_recruitment_cost)
	SignalBus.request_recruit_refresh.connect(_on_request_recruit_refresh)

# Character data request handlers
func _on_request_roster_data():
	"""Handle roster data request - get data directly from GuildManager"""
	print("DataAccessLayer: _on_request_roster_data() called")
	var roster = GuildManager.roster
	print("DataAccessLayer: Got roster from GuildManager: ", roster.size())
	roster_data_received.emit(roster)
	_cached_roster = roster
	print("DataAccessLayer: Emitted roster to rooms")

func _on_request_available_characters():
	"""Handle available characters request - get data directly from GuildManager"""
	print("DataAccessLayer: _on_request_available_characters() called")
	var characters = GuildManager.get_available_characters()
	print("DataAccessLayer: Got available characters from GuildManager: ", characters.size())
	available_characters_received.emit(characters)
	_cached_available_characters = characters
	print("DataAccessLayer: Emitted available characters to rooms")

func _on_request_characters_needing_promotion():
	"""Handle characters needing promotion request - get data directly from GuildManager"""
	print("DataAccessLayer: _on_request_characters_needing_promotion() called")
	var characters = GuildManager.get_characters_needing_promotion()
	characters_needing_promotion_received.emit(characters)

func _on_request_injured_characters():
	"""Handle injured characters request - get data directly from GuildManager"""
	print("DataAccessLayer: _on_request_injured_characters() called")
	var characters = GuildManager.get_injured_characters()
	injured_characters_received.emit(characters)

func _on_request_character_display_data(character: Character):
	"""Handle character display data request - get data directly from GuildManager"""
	print("DataAccessLayer: _on_request_character_display_data() called")
	var display_data = GuildManager.get_character_display_data(character)
	character_display_data_received.emit(character, display_data)

func _on_request_recruit_display_data(character: Character):
	"""Handle recruit display data request - get data directly from GuildManager"""
	print("DataAccessLayer: _on_request_recruit_display_data() called")
	var display_data = GuildManager.get_recruit_display_data(character)
	recruit_display_data_received.emit(character, display_data)

# Quest data request handlers
func _on_request_available_quest_cards():
	"""Handle available quest cards request - get data directly from GuildManager"""
	print("DataAccessLayer: _on_request_available_quest_cards() called")
	var quest_cards = GuildManager.get_available_quest_cards()
	print("DataAccessLayer: Got quest cards from GuildManager: ", quest_cards.size())
	for i in range(quest_cards.size()):
		var card = quest_cards[i]
		print("DataAccessLayer: Quest card ", i, ": ", card)
		if card and card.has_method("get_quest"):
			var quest = card.get_quest()
			print("DataAccessLayer: Quest name: ", quest.quest_name if quest else "null")
	
	print("DataAccessLayer: Emitting available_quest_cards_received signal")
	available_quest_cards_received.emit(quest_cards)
	_cached_quest_cards = quest_cards
	print("DataAccessLayer: Signal emitted, cached quest cards: ", _cached_quest_cards.size())

func _on_request_active_quest_cards():
	"""Handle active quest cards request - get data directly from GuildManager"""
	print("DataAccessLayer: _on_request_active_quest_cards() called")
	var quest_cards = GuildManager.get_active_quest_cards()
	active_quest_cards_received.emit(quest_cards)

func _on_request_awaiting_quest_cards():
	"""Handle awaiting quest cards request - get data directly from GuildManager"""
	print("DataAccessLayer: _on_request_awaiting_quest_cards() called")
	var quest_cards = GuildManager.get_awaiting_quest_cards()
	awaiting_quest_cards_received.emit(quest_cards)

func _on_request_quest_display_data(quest: Quest):
	"""Handle quest display data request - get data directly from GuildManager"""
	print("DataAccessLayer: _on_request_quest_display_data() called")
	var display_data = GuildManager.get_quest_display_data(quest)
	quest_display_data_received.emit(quest, display_data)

func _on_request_quest_validation(quest: Quest, party: Array[Character]):
	"""Handle quest validation request - get data directly from GuildManager"""
	print("DataAccessLayer: _on_request_quest_validation() called")
	var validation = GuildManager.validate_quest_party(quest, party)
	quest_validation_received.emit(quest, party, validation)

# Resource data request handlers
func _on_request_guild_resources():
	"""Handle guild resources request - get data directly from GuildManager"""
	print("DataAccessLayer: _on_request_guild_resources() called")
	var resources = {
		"influence": GuildManager.influence,
		"gold": GuildManager.gold,
		"food": GuildManager.food,
		"building_materials": GuildManager.building_materials,
		"armor_pieces": GuildManager.armor_pieces,
		"weapons": GuildManager.weapons
	}
	print("DataAccessLayer: Got resources from GuildManager")
	guild_resources_received.emit(resources)
	_cached_resources = resources
	print("DataAccessLayer: Emitted resources to rooms")

func _on_request_guild_status_summary():
	"""Handle guild status summary request - get data directly from GuildManager"""
	print("DataAccessLayer: _on_request_guild_status_summary() called")
	var summary = GuildManager.get_guild_status_summary()
	guild_status_summary_received.emit(summary)

func _on_request_resource_display_data():
	"""Handle resource display data request - get data directly from GuildManager"""
	print("DataAccessLayer: _on_request_resource_display_data() called")
	var display_data = GuildManager.get_ui_notification_data()
	resource_display_data_received.emit(display_data)

func _on_request_cost_calculation(cost: Dictionary):
	"""Handle cost calculation request - get data directly from GuildManager"""
	print("DataAccessLayer: _on_request_cost_calculation() called")
	var projected_resources = GuildManager.calculate_cost(cost)
	cost_calculation_received.emit(cost, projected_resources)

func _on_request_can_afford_check(cost: Dictionary):
	"""Handle can afford check request - get data directly from GuildManager"""
	print("DataAccessLayer: _on_request_can_afford_check() called")
	var can_afford = GuildManager.can_afford_cost(cost)
	can_afford_check_received.emit(cost, can_afford)

# Recruitment data request handlers
func _on_request_available_recruits():
	"""Handle available recruits request - get data directly from GuildManager"""
	print("DataAccessLayer: _on_request_available_recruits() called")
	var recruits = GuildManager.available_recruits
	print("DataAccessLayer: Got recruits from GuildManager: ", recruits.size())
	available_recruits_received.emit(recruits)
	print("DataAccessLayer: Emitted recruits to rooms")

func _on_request_recruitment_cost(character: Character):
	"""Handle recruitment cost request - get data directly from GuildManager"""
	print("DataAccessLayer: _on_request_recruitment_cost() called")
	var cost = character.get_recruitment_cost()
	recruitment_cost_received.emit(character, cost)

func _on_request_recruit_refresh():
	"""Handle recruit refresh request - get data directly from GuildManager"""
	print("DataAccessLayer: _on_request_recruit_refresh() called")
	var result = GuildManager.force_recruit_refresh()
	recruit_refresh_completed.emit(result)

# Note: GuildManager response signal handlers removed - we now access data directly

# GuildManager signal handlers for cache invalidation
func _on_character_recruited(character: Character):
	"""Invalidate character-related caches when a character is recruited"""
	_cached_roster.clear()
	_cached_available_characters.clear()

func _on_quest_started(quest: Quest):
	"""Invalidate quest-related caches when a quest starts"""
	_cached_quest_cards.clear()

func _on_quest_completed(quest: Quest):
	"""Invalidate quest-related caches when a quest completes"""
	print("DataAccessLayer: Quest completed, clearing quest cache")
	_on_request_available_quest_cards()

func _on_quest_card_moved(quest_card: CompactQuestCard, from_state: String, to_state: String):
	"""Invalidate quest-related caches when quest cards move"""
	#_cached_quest_cards.clear()
	_on_request_available_quest_cards()

# Convenience methods for direct data access (with caching)
func get_roster() -> Array[Character]:
	"""Get roster data with caching"""
	if _cached_roster.is_empty() or _is_cache_expired():
		_on_request_roster_data()
		_cache_timestamp = Time.get_time_dict_from_system()["unix"]
	return _cached_roster

func get_available_characters() -> Array[Character]:
	"""Get available characters data with caching"""
	if _cached_available_characters.is_empty() or _is_cache_expired():
		_on_request_available_characters()
		_cache_timestamp = Time.get_unix_time_from_system()
	return _cached_available_characters

func get_available_quest_cards() -> Array[CompactQuestCard]:
	"""Get available quest cards data with caching"""
	if _cached_quest_cards.is_empty() or _is_cache_expired():
		_on_request_available_quest_cards()
		_cache_timestamp = Time.get_unix_time_from_system()
	return _cached_quest_cards

func get_guild_resources() -> Dictionary:
	"""Get guild resources data with caching"""
	if _cached_resources.is_empty() or _is_cache_expired():
		_on_request_guild_resources()
		_cache_timestamp = Time.get_unix_time_from_system()
	return _cached_resources

func _is_cache_expired() -> bool:
	"""Check if the cache has expired"""
	var current_time = Time.get_unix_time_from_system()
	return (current_time - _cache_timestamp) > _cache_duration

# Utility methods for common data operations
func get_character_by_name(name: String) -> Character:
	"""Get a character by name from the roster"""
	var roster = get_roster()
	for character in roster:
		if character.character_name == name:
			return character
	return null

func get_characters_by_class(character_class: Character.CharacterClass) -> Array[Character]:
	"""Get all characters of a specific class"""
	var roster = get_roster()
	var filtered_characters: Array[Character] = []
	for character in roster:
		if character.character_class == character_class:
			filtered_characters.append(character)
	return filtered_characters

func get_characters_by_status(status: Character.CharacterStatus) -> Array[Character]:
	"""Get all characters with a specific status"""
	var roster = get_roster()
	var filtered_characters: Array[Character] = []
	for character in roster:
		if character.character_status == status:
			filtered_characters.append(character)
	return filtered_characters

func get_quest_by_name(name: String) -> Quest:
	"""Get a quest by name from available quests"""
	var quest_cards = get_available_quest_cards()
	for quest_card in quest_cards:
		if quest_card.get_quest().quest_name == name:
			return quest_card.get_quest()
	return null

func invalidate_cache():
	"""Manually invalidate all cached data"""
	_cached_roster.clear()
	_cached_available_characters.clear()
	_cached_quest_cards.clear()
	_cached_resources.clear()
	_cache_timestamp = 0.0
