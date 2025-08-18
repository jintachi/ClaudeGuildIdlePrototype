class_name Quest
extends Resource

enum QuestType {
	GATHERING,
	HUNTING_TRAPPING,
	DIPLOMACY,
	CARAVAN_GUARDING,
	ESCORTING,
	STEALTH,
	ODD_JOBS,
	EMERGENCY
}

enum QuestStatus {
	NOTSTARTED,
	INPROGRESS,
	COMPLETED,
	FAILED
}
enum QuestRank {
	F, E, D, C, B, A, S, SS, SSS
}

@export var quest_name: String
@export var quest_type: QuestType
@export var quest_rank: QuestRank
@export var description: String
@export var duration: float  # in seconds
@export var difficulty_modifier: float
@export var allow_partial_failure: bool = true

# Party requirements
@export var min_party_size: int = 1
@export var max_party_size: int = 5
@export var required_tank: bool = false
@export var required_healer: bool = false
@export var required_support: bool = false
@export var required_attacker: bool = false

# Stat requirements
@export var min_total_health: int = 0
@export var min_total_defense: int = 0
@export var min_total_attack_power: int = 0
@export var min_total_spell_power: int = 0
@export var min_substat_requirement: int = 0

# Rewards
@export var base_experience: int
@export var gold_reward: int
@export var influence_reward: int
@export var building_materials: int = 0
@export var armor_pieces: int = 0
@export var weapons: int = 0
@export var food: int = 0

# Quest state
@export var start_time: float = 0.0
@export var assigned_party: Array[Character] = []
@export var success_rate: float = 0.0
@export var individual_checks: Array[bool] = []
@export var active_quest_status = QuestStatus.NOTSTARTED

signal quest_completed(quest:Quest)

func _init():
	generate_random_quest()
	

static func create_quest(type: QuestType, rank: QuestRank) -> Quest:
	var quest = Quest.new()
	quest.quest_type = type
	quest.quest_rank = rank
	quest.generate_quest_from_template(type, rank)
	return quest

func generate_random_quest():
	var types = QuestType.values()
	var ranks = QuestRank.values()
	
	quest_type = types[randi() % types.size()]
	quest_rank = ranks[randi() % ranks.size()]
	generate_quest_from_template(quest_type, quest_rank)

func generate_quest_from_template(type: QuestType, rank: QuestRank):
	quest_type = type
	quest_rank = rank
	
	var rank_multiplier = get_rank_multiplier()
	var base_duration = get_base_duration_for_type()
	duration = base_duration * rank_multiplier
	difficulty_modifier = 1.0 + (rank * 0.15)  # Each rank adds 15% difficulty
	
	# Generate requirements based on type and rank
	generate_requirements()
	generate_rewards()
	generate_quest_details()

func get_rank_multiplier() -> float:
	match quest_rank:
		QuestRank.F: return 0.5
		QuestRank.E: return 0.7
		QuestRank.D: return 1.0
		QuestRank.C: return 1.5
		QuestRank.B: return 2.5
		QuestRank.A: return 4.0
		QuestRank.S: return 6.0
		QuestRank.SS: return 10.0
		QuestRank.SSS: return 15.0
		_: return 1.0

func get_base_duration_for_type() -> float:
	match quest_type:
		QuestType.GATHERING: return 30.0
		QuestType.HUNTING_TRAPPING: return 60.0
		QuestType.DIPLOMACY: return 45.0
		QuestType.CARAVAN_GUARDING: return 120.0
		QuestType.ESCORTING: return 90.0
		QuestType.STEALTH: return 75.0
		QuestType.ODD_JOBS: return 40.0
		QuestType.EMERGENCY: return 300.0
		_: return 60.0

func generate_requirements():
	var rank_multiplier = get_rank_multiplier()
	
	# Party size requirements
	min_party_size = 1
	#max_party_size = min(4, 1 + int(quest_rank / 2))
	
	# Class requirements based on quest type and rank
	match quest_type:
		QuestType.CARAVAN_GUARDING:
			if quest_rank >= QuestRank.C:
				required_tank = true
				min_party_size = 2
			if quest_rank >= QuestRank.B:
				required_healer = true
				min_party_size = 3
		QuestType.ESCORTING:
			allow_partial_failure = false  # No partial success for escort missions
			if quest_rank >= QuestRank.D:
				required_tank = true
			if quest_rank >= QuestRank.C:
				required_healer = true
				min_party_size = 2
		QuestType.STEALTH:
			max_party_size = 1  # Stealth missions prefer smaller groups
		QuestType.DIPLOMACY:
			if quest_rank >= QuestRank.B:
				required_support = true
	
	# Stat requirements
	min_total_health = int(50 * rank_multiplier * randf_range(0.8, 1.2))
	min_total_defense = int(20 * rank_multiplier * randf_range(0.8, 1.2))
	min_total_attack_power = int(30 * rank_multiplier * randf_range(0.8, 1.2))
	min_total_spell_power = int(15 * rank_multiplier * randf_range(0.8, 1.2))
	min_substat_requirement = int(quest_rank * randf_range(0.5, 1.5))

func generate_rewards():
	var rank_multiplier = get_rank_multiplier()
	
	base_experience = int(20 * rank_multiplier)
	gold_reward = int(15 * rank_multiplier * randf_range(0.8, 1.4))
	influence_reward = int(5 * rank_multiplier * randf_range(0.9, 1.1))
	
	# Random additional rewards
	if randf() < 0.3:
		building_materials = int(rank_multiplier * randf_range(1, 3))
	if randf() < 0.2:
		armor_pieces = int(rank_multiplier * randf_range(1, 2))
	if randf() < 0.2:
		weapons = int(rank_multiplier * randf_range(1, 2))
	if randf() < 0.4:
		food = int(rank_multiplier * randf_range(2, 5))

func generate_quest_details():
	var type_names = {
		QuestType.GATHERING: "Gathering",
		QuestType.HUNTING_TRAPPING: "Hunting",
		QuestType.DIPLOMACY: "Diplomacy",
		QuestType.CARAVAN_GUARDING: "Caravan Guard",
		QuestType.ESCORTING: "Escort",
		QuestType.STEALTH: "Stealth",
		QuestType.ODD_JOBS: "Odd Jobs",
		QuestType.EMERGENCY: "Emergency"
	}
	
	var rank_name = get_rank_name()
	var type_name = type_names.get(quest_type, "Unknown")
	
	quest_name = rank_name + "-Rank " + type_name + " Mission"
	
	var descriptions = get_quest_descriptions()
	description = descriptions[quest_type][randi() % descriptions[quest_type].size()]

func get_quest_descriptions() -> Dictionary:
	return {
		QuestType.GATHERING: [
			"Collect rare herbs from the Whispering Woods.",
			"Mine precious metals from the Crystal Caves.",
			"Harvest moonflowers under the full moon."
		],
		QuestType.HUNTING_TRAPPING: [
			"Hunt dire wolves threatening nearby villages.",
			"Trap rare creatures for the Royal Menagerie.",
			"Clear out goblin nests in the Deep Marsh."
		],
		QuestType.DIPLOMACY: [
			"Negotiate peace between feuding noble houses.",
			"Establish trade agreements with distant merchants.",
			"Resolve disputes at the border settlements."
		],
		QuestType.CARAVAN_GUARDING: [
			"Protect merchant caravan through bandit territory.",
			"Guard supply wagons to the frontier outpost.",
			"Escort trade goods across the mountain pass."
		],
		QuestType.ESCORTING: [
			"Safely escort a noble to the capital city.",
			"Guide pilgrims to the sacred temple.",
			"Protect a witness traveling to testify."
		],
		QuestType.STEALTH: [
			"Infiltrate the enemy fortress for intelligence.",
			"Steal back stolen artifacts from thieves.",
			"Gather information on suspicious activities."
		],
		QuestType.ODD_JOBS: [
			"Help rebuild the village after the storm.",
			"Deliver mysterious packages across town.",
			"Assist with various tasks around the guild."
		],
		QuestType.EMERGENCY: [
			"URGENT: Dragon sighted near the capital!",
			"EMERGENCY: Demon portal opened in the ruins!",
			"CRISIS: Ancient curse awakened in the temple!"
		]
	}

func can_assign_party(party: Array[Character]) -> Dictionary:
	var result = {"can_assign": true, "reasons": []}
	
	# Check party size
	if party.size() < min_party_size:
		result.can_assign = false
		result.reasons.append("Need at least %d party members" % min_party_size)
	
	if party.size() > max_party_size:
		result.can_assign = false
		result.reasons.append("Maximum %d party members allowed" % max_party_size)
	
	# Check for required classes
	var has_tank = false
	var has_healer = false
	var has_support = false
	var has_attacker = false
	
	for character in party:
		if not character.can_go_on_quest():
			result.can_assign = false
			result.reasons.append("%s is not available" % character.character_name)
			continue
			
		match character.character_class:
			Character.CharacterClass.TANK: has_tank = true
			Character.CharacterClass.HEALER: has_healer = true
			Character.CharacterClass.SUPPORT: has_support = true
			Character.CharacterClass.ATTACKER: has_attacker = true
	
	if required_tank and not has_tank:
		result.can_assign = false
		result.reasons.append("Tank required")
	if required_healer and not has_healer:
		result.can_assign = false
		result.reasons.append("Healer required")
	if required_support and not has_support:
		result.can_assign = false
		result.reasons.append("Support required")
	if required_attacker and not has_attacker:
		result.can_assign = false
		result.reasons.append("Attacker required")
	
	# Check stat requirements
	var total_stats = calculate_party_stats(party)
	if total_stats.health < min_total_health:
		result.can_assign = false
		result.reasons.append("Need %d more Health" % (min_total_health - total_stats.health))
	if total_stats.defense < min_total_defense:
		result.can_assign = false
		result.reasons.append("Need %d more Defense" % (min_total_defense - total_stats.defense))
	if total_stats.attack_power < min_total_attack_power:
		result.can_assign = false
		result.reasons.append("Need %d more Attack Power" % (min_total_attack_power - total_stats.attack_power))
	if total_stats.spell_power < min_total_spell_power:
		result.can_assign = false
		result.reasons.append("Need %d more Spell Power" % (min_total_spell_power - total_stats.spell_power))
	
	# Check substat requirement
	var max_substat = get_party_max_substat(party)
	if max_substat < min_substat_requirement:
		result.can_assign = false
		result.reasons.append("Need %d more in relevant skill" % (min_substat_requirement - max_substat))
	
	return result

func calculate_party_stats(party: Array[Character]) -> Dictionary:
	var totals = {"health": 0, "defense": 0, "attack_power": 0, "spell_power": 0, "mana": 0, "movement_speed": 0, "luck": 0}
	
	for character in party:
		var stats = character.get_effective_stats()
		for stat in totals.keys():
			totals[stat] += stats[stat]
	
	return totals

func get_party_max_substat(party: Array[Character]) -> int:
	var max_substat = 0
	var substat_name = get_substat_name_for_quest_type()
	
	for character in party:
		var character_substat = character.get(substat_name)
		max_substat = max(max_substat, character_substat)
	
	return max_substat

func get_substat_name_for_quest_type() -> String:
	match quest_type:
		QuestType.GATHERING: return "gathering"
		QuestType.HUNTING_TRAPPING: return "hunting_trapping"
		QuestType.DIPLOMACY: return "diplomacy"
		QuestType.CARAVAN_GUARDING: return "caravan_guarding"
		QuestType.ESCORTING: return "escorting"
		QuestType.STEALTH: return "stealth"
		QuestType.ODD_JOBS: return "odd_jobs"
		_: return "gathering"

func start_quest(party: Array[Character]) -> bool:
	var assignment_check = can_assign_party(party)
	if not assignment_check.can_assign:
		return false
	
	assigned_party = party.duplicate()
	for character in assigned_party:
		character.is_on_quest = true
	
	self.active_quest_status = QuestStatus.INPROGRESS
	start_time = Time.get_unix_time_from_system()
	calculate_success_rate()
	
	return true

func calculate_success_rate():
	if assigned_party.is_empty():
		success_rate = 0.0
		return
	
	var party_stats = calculate_party_stats(assigned_party)
	var base_power = party_stats.health + party_stats.defense + party_stats.attack_power + party_stats.spell_power
	var required_power = min_total_health + min_total_defense + min_total_attack_power + min_total_spell_power
	
	# Apply class abilities and bonuses
	var party_modifiers = calculate_party_modifiers()
	
	# Base success rate from stat comparison
	var stat_ratio = float(base_power) / max(required_power, 1)
	var base_success = min(0.95, stat_ratio * 0.6)  # Cap at 95%, stats contribute 60% max
	
	# Apply difficulty modifier
	base_success /= difficulty_modifier
	
	# Apply party modifiers
	base_success += party_modifiers
	
	success_rate = max(0.05, min(0.95, base_success))  # Clamp between 5% and 95%

func calculate_party_modifiers() -> float:
	var modifiers = 0.0
	
	for character in assigned_party:
		# Class-specific bonuses (placeholder for future abilities)
		match character.character_class:
			Character.CharacterClass.ATTACKER:
				if character.rank >= Character.Rank.B:
					modifiers += 0.05  # "Remove Enemy" ability
			Character.CharacterClass.TANK:
				if character.rank >= Character.Rank.B:
					modifiers += 0.03  # "Damage Shield" ability
		
		# Substat bonus for relevant quest type
		var substat_name = get_substat_name_for_quest_type()
		var substat_value = character.get(substat_name)
		modifiers += substat_value * 0.01  # Each substat point adds 1%
	
	return modifiers

func update_quest_progress() -> bool:
	if active_quest_status == QuestStatus.FAILED:
		return false
	
	var current_time = Time.get_unix_time_from_system()
	var elapsed_time = current_time - start_time
	
	if elapsed_time >= duration:
		complete_quest()
		return true
	
	return false

func complete_quest():
	#if self.active_quest_status == QuestStatus.COMPLETED :
		#return
	
	# Perform individual success checks
	individual_checks.clear()
	var successful_members = 0
	
	for character in assigned_party:
		
		var individual_success = randf_range(0,1) # set chance to succeed to random for now COME BACK LATER TO FIX
		
		if individual_success > .6:
			successful_members += 1
			character.improve_substat_from_quest(get_substat_name_for_quest_type(), success_rate)
			individual_checks.append(true)
		else : 
			individual_checks.append(false)
		
		
	# Calculate final success rate and rewards
	var final_success_rate = float(successful_members) / assigned_party.size()
	
	# Check for quest failure conditions
	if not allow_partial_failure and final_success_rate < 1.0:
		final_success_rate = 0.0  # Complete failure for no-partial quests
	elif final_success_rate < 0.6:
		final_success_rate = 0.0  # Less than 60% counts as failure
		
	if final_success_rate > .6 and allow_partial_failure :
		self.active_quest_status = QuestStatus.COMPLETED
	else : 
		self.active_quest_status = QuestStatus.FAILED

	apply_rewards(final_success_rate)
	apply_injuries_on_failure(final_success_rate)
		

func apply_rewards(final_success_rate: float):
	var experience_per_member = int(base_experience * max(final_success_rate, 0.6 if final_success_rate > 0.0 else 0.0))
	var gold_per_member = int((gold_reward * 0.8) / assigned_party.size())  # 80% to party, 20% to guild
	
	for i in range(assigned_party.size()):
		var character = assigned_party[i]
		var member_success = individual_checks[i]
		
		if member_success:
			character.add_experience(experience_per_member)
			character.personal_gold += gold_per_member
		else:
			# Partial experience for failure (60% of success amount)
			character.add_experience(int(experience_per_member * 0.6))
			character.personal_gold += int(gold_per_member * 0.6)

func apply_injuries_on_failure(final_success_rate: float):
	if final_success_rate >= 0.5:
		return  # No injuries on success
	
	var injury_chance = 0.1 + (0.5 * (1.0 - final_success_rate))  # 30-70% chance based on failure severity
	
	for i in range(assigned_party.size()):
		var character = assigned_party[i]
		var member_failed = not individual_checks[i]
		
		if member_failed and randf() < injury_chance:
			apply_random_injury(character)

func apply_random_injury(character: Character):
	var injury_types = [
		Character.InjuryType.PHYSICAL_WOUND,
		Character.InjuryType.MENTAL_TRAUMA,
		Character.InjuryType.CURSED_AFFLICTION,
		Character.InjuryType.EXHAUSTION,
		Character.InjuryType.POISON
	]
	
	var injury_type = injury_types[randi() % injury_types.size()]
	var base_duration = get_base_injury_duration(injury_type)
	var rank_multiplier = 1.0 + (quest_rank * 0.1)  # Higher rank quests = longer injuries
	
	character.apply_injury(injury_type, base_duration * rank_multiplier)

func get_base_injury_duration(injury_type: Character.InjuryType) -> float:
	match injury_type:
		Character.InjuryType.PHYSICAL_WOUND: return 300.0  # 5 minutes
		Character.InjuryType.MENTAL_TRAUMA: return 240.0   # 4 minutes
		Character.InjuryType.CURSED_AFFLICTION: return 480.0  # 8 minutes
		Character.InjuryType.EXHAUSTION: return 180.0      # 3 minutes
		Character.InjuryType.POISON: return 360.0          # 6 minutes
		_: return 300.0
		

func get_time_remaining() -> float:
	if not self.active_quest_status == QuestStatus.INPROGRESS:
		return 0.0
	
	var current_time = Time.get_unix_time_from_system()
	var elapsed_time = current_time - start_time
	return max(0.0, duration - elapsed_time)

func get_progress_percentage() -> float:
	if self.active_quest_status == QuestStatus.COMPLETED :
		
		return 100.0
	else :
		return 100 - (get_time_remaining()/duration)*100
	
	var current_time = Time.get_unix_time_from_system()
	var elapsed_time = current_time - start_time
	return min(100.0, (elapsed_time / duration) * 100.0)

func get_party_display_info() -> Array:
	var party_info = []
	for i in range(assigned_party.size()):
		var character = assigned_party[i]
		var status = "?"  # Unknown until completion
		
		if self.active_quest_status == QuestStatus.COMPLETED and i < individual_checks.size():
			status = "✓" if individual_checks[i] else "✗"
		
		party_info.append({
			"name": character.character_name,
			"class": character.get_class_name(),
			"status": status
		})
	
	return party_info

func get_rank_name() -> String:
	match quest_rank:
		QuestRank.F: return "F"
		QuestRank.E: return "E"
		QuestRank.D: return "D"
		QuestRank.C: return "C"
		QuestRank.B: return "B"
		QuestRank.A: return "A"
		QuestRank.S: return "S"
		QuestRank.SS: return "SS"
		QuestRank.SSS: return "SSS"
		_: return "?"

func get_type_name() -> String:
	match quest_type:
		QuestType.GATHERING: return "Gathering"
		QuestType.HUNTING_TRAPPING: return "Hunting"
		QuestType.DIPLOMACY: return "Diplomacy"
		QuestType.CARAVAN_GUARDING: return "Caravan Guard"
		QuestType.ESCORTING: return "Escort"
		QuestType.STEALTH: return "Stealth"
		QuestType.ODD_JOBS: return "Odd Jobs"
		QuestType.EMERGENCY: return "Emergency"
		_: return "Unknown"

func get_requirements_text() -> String:
	var req_text = []
	
	if min_party_size > 1:
		req_text.append("Min %d members" % min_party_size)
	if max_party_size < 4:
		req_text.append("Max %d members" % max_party_size)
	
	if required_tank:
		req_text.append("Tank Required")
	if required_healer:
		req_text.append("Healer Required")
	if required_support:
		req_text.append("Support Required")
	if required_attacker:
		req_text.append("Attacker Required")
	
	if min_total_health > 0:
		req_text.append("Health: %d+" % min_total_health)
	if min_total_defense > 0:
		req_text.append("Defense: %d+" % min_total_defense)
	if min_total_attack_power > 0:
		req_text.append("Attack: %d+" % min_total_attack_power)
	if min_total_spell_power > 0:
		req_text.append("Spell Power: %d+" % min_total_spell_power)
	if min_substat_requirement > 0:
		req_text.append("%s Skill: %d+" % [get_substat_name_for_quest_type().capitalize(), min_substat_requirement])
	
	return ", ".join(req_text) if not req_text.is_empty() else "No special requirements"

func get_rewards_text() -> String:
	var rewards_text = []
	
	rewards_text.append("%d XP" % base_experience)
	rewards_text.append("%d Gold" % gold_reward)
	rewards_text.append("%d Influence" % influence_reward)
	
	if building_materials > 0:
		rewards_text.append("%d Materials" % building_materials)
	if armor_pieces > 0:
		rewards_text.append("%d Armor" % armor_pieces)
	if weapons > 0:
		rewards_text.append("%d Weapons" % weapons)
	if food > 0:
		rewards_text.append("%d Food" % food)
	
	return ", ".join(rewards_text)
