class_name QuestCompletionPanel
extends Panel

@export var text_edit: TextEdit
@export var accept_button: Button
@export var header_label: Label

var current_quest: Quest = null

func _ready():
	if accept_button:
		accept_button.pressed.connect(_on_accept_button_pressed)

func display_quest_results(quest: Quest):
	"""Display quest results in a simple text format"""
	current_quest = quest
	if not text_edit:
		return
	
	var result_text = ""
	
	# Quest header
	result_text += "[%s] Rank Quest: %s was completed " % [quest.get_rank_name(), quest.quest_name]
	
	# Success/failure status
	if quest.final_success_rate > 0.6:
		result_text += "successfully!"
	else:
		result_text += "with failure."
	
	result_text += "\n"
	
	# Check for level ups by comparing completion state with current state
	var leveled_up_characters = []
	var completion_level_ups = quest.get_completion_level_ups()
	
	# Add level up summary if any characters leveled up
	for character in quest.assigned_party:
		if completion_level_ups.has(character.character_name):
			var completion_data = completion_level_ups[character.character_name]
			if character.level > completion_data.level:
				leveled_up_characters.append({
					"character": character,
					"previous_level": completion_data.level,
					"current_level": character.level
				})
	
	if not leveled_up_characters.is_empty():
		var level_up_names = []
		for level_up_data in leveled_up_characters:
			level_up_names.append(level_up_data.character.character_name)
		result_text += "%s leveled up!\n" % ", ".join(level_up_names)
	
	result_text += "\n"
	
	# Check for injuries
	var injured_characters = []
	for character in quest.assigned_party:
		if character.is_injured():
			injured_characters.append(character)
	
	# Add level up information
	if not leveled_up_characters.is_empty():
		result_text += "Level Ups:\n"
		for level_up_data in leveled_up_characters:
			var character = level_up_data.character
			var previous_level = level_up_data.previous_level
			var current_level = level_up_data.current_level
			
			result_text += "%s is now level %d!\n" % [character.character_name, current_level]
			
			# Get current stats and completion stats for comparison
			var current_stats = character.get_current_stats()
			var completion_stats = quest.get_completion_stats()
			var previous_stats = completion_stats.get(character.character_name, {})
			
			# Display stat changes in the format requested
			if previous_stats.has("health"):
				var health_change = current_stats.health - previous_stats.health
				result_text += "HP:     %d -> %d (+%d)\n" % [previous_stats.health, current_stats.health, health_change]
			else:
				result_text += "HP:     %d\n" % current_stats.health
				
			if previous_stats.has("defense"):
				var defense_change = current_stats.defense - previous_stats.defense
				result_text += "DEF:   %d -> %d (+%d)\n" % [previous_stats.defense, current_stats.defense, defense_change]
			else:
				result_text += "DEF:   %d\n" % current_stats.defense
				
			if previous_stats.has("mana"):
				var mana_change = current_stats.mana - previous_stats.mana
				result_text += "MP:    %d -> %d (+%d)\n" % [previous_stats.mana, current_stats.mana, mana_change]
			else:
				result_text += "MP:    %d\n" % current_stats.mana
				
			if previous_stats.has("spell_power"):
				var spell_change = current_stats.spell_power - previous_stats.spell_power
				result_text += "SPL:   %d -> %d (+%d)\n" % [previous_stats.spell_power, current_stats.spell_power, spell_change]
			else:
				result_text += "SPL:   %d\n" % current_stats.spell_power
				
			if previous_stats.has("attack_power"):
				var attack_change = current_stats.attack_power - previous_stats.attack_power
				result_text += "ATK:   %d -> %d (+%d)\n" % [previous_stats.attack_power, current_stats.attack_power, attack_change]
			else:
				result_text += "ATK:   %d\n" % current_stats.attack_power
				
			if previous_stats.has("movement_speed"):
				var speed_change = current_stats.movement_speed - previous_stats.movement_speed
				result_text += "SPD:   %d -> %d (+%d)\n" % [previous_stats.movement_speed, current_stats.movement_speed, speed_change]
			else:
				result_text += "SPD:   %d\n" % current_stats.movement_speed
				
			if previous_stats.has("luck"):
				var luck_change = current_stats.luck - previous_stats.luck
				result_text += "LCK:   %d -> %d (+%d)\n" % [previous_stats.luck, current_stats.luck, luck_change]
			else:
				result_text += "LCK:   %d\n" % current_stats.luck
			result_text += "\n"
	
	# Add injury information
	if not injured_characters.is_empty():
		result_text += "Injuries:\n"
		for character in injured_characters:
			var injury_name = get_injury_name(character.injury_type)
			result_text += "  %s: %s\n" % [character.character_name, injury_name]
		result_text += "\n"
	
	# Add party member results
	result_text += "Party Results:\n"
	for i in range(quest.assigned_party.size()):
		var character = quest.assigned_party[i]
		var success = quest.individual_checks[i] if i < quest.individual_checks.size() else false
		var status = "✓ Success" if success else "✗ Failure"
		result_text += "  %s: %s\n" % [character.character_name, status]
	
	text_edit.text = result_text

func get_injury_name(injury_type: Character.InjuryType) -> String:
	"""Get the display name for an injury type"""
	match injury_type:
		Character.InjuryType.PHYSICAL_WOUND: return "Physical Wound"
		Character.InjuryType.MENTAL_TRAUMA: return "Mental Trauma"
		Character.InjuryType.CURSED_AFFLICTION: return "Cursed"
		Character.InjuryType.EXHAUSTION: return "Exhausted"
		Character.InjuryType.POISON: return "Poisoned"
		_: return "Unknown"

func _on_accept_button_pressed():
	"""Handle accepting quest results"""
	print("AVAILABLE_QUESTS: Quest completion panel accept button pressed")
	print("AVAILABLE_QUESTS: Current quest: ", current_quest.quest_name if current_quest else "null")
	if current_quest and GuildManager:
		# Find the quest card for this quest
		var quest_card: CompactQuestCard = null
		for card in GuildManager.get_awaiting_quest_cards():
			if card.get_quest() == current_quest:
				quest_card = card
				break
		
		if quest_card:
			print("AVAILABLE_QUESTS: Found quest card, calling GuildManager.accept_quest_results")
			GuildManager.accept_quest_results(quest_card)
			# Emit signal to notify parent that results were accepted
			print("AVAILABLE_QUESTS: Emitting quest_results_accepted signal")
			quest_results_accepted.emit(current_quest)
		else:
			print("AVAILABLE_QUESTS: Quest card not found in awaiting quests")
	else:
		print("AVAILABLE_QUESTS: Current quest or GuildManager is null")

signal quest_results_accepted(quest: Quest)
