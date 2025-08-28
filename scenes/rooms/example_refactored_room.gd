class_name ExampleRefactoredRoom
extends BaseRoom

## Example refactored room demonstrating the new data handling patterns
## This shows how rooms should be structured with the new system

# UI elements
@export var roster_container: VBoxContainer
@export var resources_panel: Control
@export var quest_container: VBoxContainer

# Data access layer reference
var data_layer: DataAccessLayer

# Local data cache
var local_roster: Array[Character] = []
var local_resources: Dictionary = {}
var local_quest_cards: Array = []

func _ready():
	# Get reference to data access layer
	data_layer = get_node("/root/DataAccessLayer")
	#setup_signal_connections()

func setup_room_specific_ui():
	"""Setup room-specific UI connections"""
	# Connect to data access layer signals
	if data_layer:
		data_layer.roster_data_received.connect(_on_roster_data_received)
		data_layer.guild_resources_received.connect(_on_resources_received)
		data_layer.available_quest_cards_received.connect(_on_quest_cards_received)
	
	# Connect to UI utilities for consistent styling
	UIUtilities.clear_container(roster_container)
	UIUtilities.clear_container(quest_container)

func on_room_entered():
	"""Called when entering the room"""
	# Request data through signals instead of direct access
	SignalBus.request_roster_data.emit()
	SignalBus.request_guild_resources.emit()
	SignalBus.request_available_quest_cards.emit()
	
	update_room_display()

func update_room_display():
	"""Update the room display using local cached data"""
	update_roster_display()
	update_resources_display()
	update_quest_display()

func update_roster_display():
	"""Update roster display using UI utilities"""
	UIUtilities.clear_container(roster_container)
	
	if local_roster.is_empty():
		var placeholder = UIUtilities.create_placeholder_label("No characters in roster")
		roster_container.add_child(placeholder)
		return
	
	for character in local_roster:
		var character_panel = UIUtilities.create_character_panel(character, "roster")
		roster_container.add_child(character_panel)
		
		# Connect click handler
		if character_panel is Button:
			character_panel.pressed.connect(func(): select_character(character))

func update_resources_display():
	"""Update resources display using UI utilities"""
	#if resources_panel:
		#UIUtilities.update_resource_display(resources_panel, local_resources)

func update_quest_display():
	"""Update quest display using UI utilities"""
	UIUtilities.clear_container(quest_container)
	
	if local_quest_cards.is_empty():
		var placeholder = UIUtilities.create_placeholder_label("No quests available")
		quest_container.add_child(placeholder)
		return
	
	#for quest_card in local_quest_cards:
		#var quest_panel = UIUtilities.create_quest_panel(quest_card, "available")
		#quest_container.add_child(quest_panel)

# Signal handlers for data updates
func _on_roster_data_received(roster: Array[Character]):
	"""Handle roster data received from data access layer"""
	local_roster = roster
	update_roster_display()

func _on_resources_received(resources: Dictionary):
	"""Handle resources data received from data access layer"""
	local_resources = resources
	update_resources_display()

func _on_quest_cards_received(quest_cards: Array):
	"""Handle quest cards data received from data access layer"""
	local_quest_cards = quest_cards
	update_quest_display()

# Character selection
func select_character(character: Character):
	"""Handle character selection"""
	# Request detailed character data through signal
	SignalBus.request_character_display_data.emit(character)
	
	# Show character details panel
	show_character_details(character)

func show_character_details(character: Character):
	"""Show detailed character information"""
	# Create detailed character panel using UI utilities
	var details_panel = UIUtilities.create_character_panel(character, "inspection")
	
	# Add to UI (implementation depends on specific UI structure)
	# This would typically be added to a details container

# Quest management
func start_quest(quest_card: CompactQuestCard, party: Array[Character]):
	"""Start a quest using GuildManager through signals"""
	# Validate quest party through signal
	SignalBus.request_quest_validation.emit(quest_card.get_quest(), party)
	
	# If validation passes, start the quest
	# This would be handled by the validation response signal

# Resource management
func check_can_afford(cost: Dictionary) -> bool:
	"""Check if guild can afford a cost through signals"""
	SignalBus.request_can_afford_check.emit(cost)
	# Return value would be handled by the response signal
	return false  # Placeholder

func calculate_cost_impact(cost: Dictionary) -> Dictionary:
	"""Calculate cost impact through signals"""
	SignalBus.request_cost_calculation.emit(cost)
	# Return value would be handled by the response signal
	return {}  # Placeholder

# Utility methods
func get_character_by_name(name: String) -> Character:
	"""Get character by name using data access layer"""
	return data_layer.get_character_by_name(name)

func get_characters_by_class(character_class: Character.CharacterClass) -> Array[Character]:
	"""Get characters by class using data access layer"""
	return data_layer.get_characters_by_class(character_class)

func get_characters_by_status(status: Character.CharacterStatus) -> Array[Character]:
	"""Get characters by status using data access layer"""
	return data_layer.get_characters_by_status(status)

# Example of how to handle data updates
func refresh_data():
	"""Refresh all data by invalidating cache and requesting fresh data"""
	data_layer.invalidate_cache()
	
	# Request fresh data
	SignalBus.request_roster_data.emit()
	SignalBus.request_guild_resources.emit()
	SignalBus.request_available_quest_cards.emit()

# Example of how to handle user actions
func on_recruit_button_pressed():
	"""Handle recruit button press"""
	# Request available recruits through signal
	SignalBus.request_available_recruits.emit()

func on_refresh_button_pressed():
	"""Handle refresh button press"""
	# Request recruit refresh through signal
	SignalBus.request_recruit_refresh.emit()

# Example of how to handle quest actions
func on_quest_selected(quest_card: CompactQuestCard):
	"""Handle quest selection"""
	# Request quest display data through signal
	SignalBus.request_quest_display_data.emit(quest_card.get_quest())

func on_start_quest_pressed(quest_card: CompactQuestCard, party: Array[Character]):
	"""Handle start quest button press"""
	# Validate and start quest through signals
	SignalBus.request_quest_validation.emit(quest_card.get_quest(), party)
