class_name Character
extends Resource

#region Enums
enum CharacterClass {
	TANK,
	HEALER, 
	SUPPORT,
	ATTACKER
}

enum Quality {
	ONE_STAR = 1,
	TWO_STAR = 2,
	THREE_STAR = 3
}

enum Rank {
	F, E, D, C, B, A, S, SS, SSS
}

enum InjuryType {
	NONE,
	PHYSICAL_WOUND,
	MENTAL_TRAUMA,
	CURSED_AFFLICTION,
	EXHAUSTION,
	POISON
}
#endregion

#region Base Stats
@export var character_name: String
@export var character_class: CharacterClass
@export var quality: Quality
@export var rank: Rank = Rank.F
@export var level: int = 1
@export var experience: int = 0
#endregion

#region Core Stats
@export var health: int = 100
@export var defense: int = 10
@export var mana: int = 50
@export var spell_power: int = 10
@export var attack_power: int = 15
@export var movement_speed: int = 10
@export var luck: int = 5
#endregion

#region Sub-stats (Mission Specific Skills)
@export var gathering: int = 0
@export var hunting_trapping: int = 0
@export var diplomacy: int = 0
@export var caravan_guarding: int = 0
@export var escorting: int = 0
@export var stealth: int = 0
@export var odd_jobs: int = 0
#endregion

#region Status
@export var is_on_quest: bool = false
@export var injury_type: InjuryType = InjuryType.NONE
@export var injury_duration: float = 0.0
@export var injury_start_time: float = 0.0
#endregion

#region Personal Resources
@export var personal_gold: int = 0
#endregion

#region Promotion Tracking
@export var promotion_quest_available: bool = false
@export var promotion_quest_completed: bool = false
#endregion

#region Character History
@export var quests_completed: int = 0
@export var quests_failed: int = 0
@export var total_injuries_sustained: int = 0
@export var total_gold_earned: int = 0
@export var total_experience_earned: int = 0
@export var total_influence_earned: int = 0
@export var promotions_attempted: int = 0
@export var promotions_succeeded: int = 0
@export var promotions_failed: int = 0
@export var quest_history: Array[Dictionary] = []  # Store detailed quest history
@export var injury_history: Array[Dictionary] = []  # Store injury history
#endregion

#region Initialization
func _init(name: String = "", char_class: CharacterClass = CharacterClass.ATTACKER, char_quality: Quality = Quality.ONE_STAR):
	character_name = name if name != "" else generate_random_name()
	character_class = char_class
	quality = char_quality
	generate_base_stats()
	generate_random_substats()

func generate_random_name() -> String:
	var first_names = ["Aeliana", "Borin", "Caelen", "Dara", "Elowen", "Finn", "Gilda", "Hamon", "Iris", "Joren", "Kira", "Lael", "Mira", "Nolan", "Orin", "Piper", "Quinn", "Raven", "Sera", "Thane", "Uma", "Vex", "Wren", "Xara", "Yara", "Zephyr"]
	var last_names = ["Ironforge", "Swiftbow", "Goldleaf", "Stormwind", "Brightblade", "Shadowmere", "Frostborn", "Firehart", "Moonwhisper", "Starweaver", "Thornfield", "Wildwood", "Blackstone", "Silverstream", "Dragonbane", "Wolfheart", "Eagleeye", "Bearclaw", "Lionmane", "Foxglove"]
	return first_names[randi() % first_names.size()] + " " + last_names[randi() % last_names.size()]

func generate_base_stats():
	var base_multiplier = 1.0 + (quality - 1) * 0.1  # Quality bonus
	
	match character_class:
		CharacterClass.TANK:
			health = int(120 * base_multiplier)
			defense = int(20 * base_multiplier)
			mana = int(30 * base_multiplier)
			spell_power = int(5 * base_multiplier)
			attack_power = int(10 * base_multiplier)
			movement_speed = int(8 * base_multiplier)
			luck = int(8 * base_multiplier)
		CharacterClass.HEALER:
			health = int(80 * base_multiplier)
			defense = int(12 * base_multiplier)
			mana = int(100 * base_multiplier)
			spell_power = int(25 * base_multiplier)
			attack_power = int(8 * base_multiplier)
			movement_speed = int(12 * base_multiplier)
			luck = int(10 * base_multiplier)
		CharacterClass.SUPPORT:
			health = int(90 * base_multiplier)
			defense = int(15 * base_multiplier)
			mana = int(70 * base_multiplier)
			spell_power = int(18 * base_multiplier)
			attack_power = int(10 * base_multiplier)
			movement_speed = int(15 * base_multiplier)
			luck = int(12 * base_multiplier)
		CharacterClass.ATTACKER:
			health = int(100 * base_multiplier)
			defense = int(10 * base_multiplier)
			mana = int(40 * base_multiplier)
			spell_power = int(10 * base_multiplier)
			attack_power = int(25 * base_multiplier)
			movement_speed = int(18 * base_multiplier)
			luck = int(8 * base_multiplier)

func generate_random_substats():
	# Randomly assign 1-3 substats to new recruits
	var substat_count = randi_range(1, 3)
	var available_substats = ["gathering", "hunting_trapping", "diplomacy", "caravan_guarding", "escorting", "stealth", "odd_jobs"]
	available_substats.shuffle()
	
	for i in range(substat_count):
		var substat = available_substats[i]
		var value = randi_range(1, 5)
		set(substat, value)

#endregion

#region Leveling and Progression
func level_up():
	level += 1
	experience = 0
	
	# Get class-based stat gain probabilities and amounts
	var stat_gains = calculate_level_up_stat_gains()
	
	# Apply the stat gains
	health += stat_gains.health
	defense += stat_gains.defense
	mana += stat_gains.mana
	spell_power += stat_gains.spell_power
	attack_power += stat_gains.attack_power
	movement_speed += stat_gains.movement_speed
	luck += stat_gains.luck
	
	# Emit signal for level up notification
	if SignalBus:
		SignalBus.character_leveled_up.emit(self, stat_gains)
	
	check_promotion_eligibility()

func calculate_level_up_stat_gains() -> Dictionary:
	"""Calculate stat gains for level up with class-based probabilities"""
	var gains = {
		"health": 0,
		"defense": 0,
		"mana": 0,
		"spell_power": 0,
		"attack_power": 0,
		"movement_speed": 0,
		"luck": 0
	}
	
	var quality_bonus = 1.0 + (quality - 1) * 0.1
	
	# Get class-specific stat gain configuration
	var class_config = get_class_stat_gain_config()
	
	# Roll for each stat
	for stat_name in gains.keys():
		var stat_config = class_config[stat_name]
		var gain = roll_stat_gain(stat_config, quality_bonus)
		gains[stat_name] = gain
	
	return gains

func roll_stat_gain(stat_config: Dictionary, quality_bonus: float) -> int:
	"""Roll for a single stat gain based on configuration"""
	var base_chance = stat_config.chance
	var base_amount = stat_config.amount
	
	# Apply quality bonus to chance (higher quality = better chances)
	var adjusted_chance = min(1.0, base_chance * quality_bonus)
	
	# Roll for gain
	if randf() < adjusted_chance:
		# Roll for amount (0 to base_amount)
		var gain_amount = randi_range(0, base_amount)
		# Apply quality bonus to amount
		return int(gain_amount * quality_bonus)
	
	return 0

func get_class_stat_gain_config() -> Dictionary:
	"""Get class-specific stat gain probabilities and amounts"""
	match character_class:
		CharacterClass.TANK:
			return {
				"health": {"chance": 0.8, "amount": 15},      # 80% chance for 0-15 HP
				"defense": {"chance": 0.7, "amount": 10},     # 70% chance for 0-10 DEF
				"mana": {"chance": 0.3, "amount": 5},         # 30% chance for 0-5 MANA
				"spell_power": {"chance": 0.2, "amount": 3},  # 20% chance for 0-3 SPL
				"attack_power": {"chance": 0.4, "amount": 8}, # 40% chance for 0-8 ATK
				"movement_speed": {"chance": 0.3, "amount": 5}, # 30% chance for 0-5 SPD
				"luck": {"chance": 0.4, "amount": 6}          # 40% chance for 0-6 LCK
			}
		CharacterClass.HEALER:
			return {
				"health": {"chance": 0.4, "amount": 8},       # 40% chance for 0-8 HP
				"defense": {"chance": 0.3, "amount": 6},      # 30% chance for 0-6 DEF
				"mana": {"chance": 0.8, "amount": 12},        # 80% chance for 0-12 MANA
				"spell_power": {"chance": 0.7, "amount": 10}, # 70% chance for 0-10 SPL
				"attack_power": {"chance": 0.2, "amount": 4}, # 20% chance for 0-4 ATK
				"movement_speed": {"chance": 0.4, "amount": 6}, # 40% chance for 0-6 SPD
				"luck": {"chance": 0.5, "amount": 7}          # 50% chance for 0-7 LCK
			}
		CharacterClass.SUPPORT:
			return {
				"health": {"chance": 0.5, "amount": 10},      # 50% chance for 0-10 HP
				"defense": {"chance": 0.4, "amount": 8},      # 40% chance for 0-8 DEF
				"mana": {"chance": 0.6, "amount": 10},        # 60% chance for 0-10 MANA
				"spell_power": {"chance": 0.6, "amount": 9},  # 60% chance for 0-9 SPL
				"attack_power": {"chance": 0.3, "amount": 6}, # 30% chance for 0-6 ATK
				"movement_speed": {"chance": 0.6, "amount": 8}, # 60% chance for 0-8 SPD
				"luck": {"chance": 0.7, "amount": 9}          # 70% chance for 0-9 LCK
			}
		CharacterClass.ATTACKER:
			return {
				"health": {"chance": 0.4, "amount": 10},      # 40% chance for 0-10 HP
				"defense": {"chance": 0.2, "amount": 5},      # 20% chance for 0-5 DEF
				"mana": {"chance": 0.3, "amount": 6},         # 30% chance for 0-6 MANA
				"spell_power": {"chance": 0.2, "amount": 5},  # 20% chance for 0-5 SPL
				"attack_power": {"chance": 0.8, "amount": 12}, # 80% chance for 0-12 ATK
				"movement_speed": {"chance": 0.6, "amount": 8}, # 60% chance for 0-8 SPD
				"luck": {"chance": 0.4, "amount": 6}          # 40% chance for 0-6 LCK
			}
		_:
			return {
				"health": {"chance": 0.5, "amount": 8},
				"defense": {"chance": 0.5, "amount": 6},
				"mana": {"chance": 0.5, "amount": 8},
				"spell_power": {"chance": 0.5, "amount": 6},
				"attack_power": {"chance": 0.5, "amount": 8},
				"movement_speed": {"chance": 0.5, "amount": 6},
				"luck": {"chance": 0.5, "amount": 6}
			}

func get_class_level_modifiers() -> Dictionary:
	match character_class:
		CharacterClass.TANK:
			return {"health": 1.5, "defense": 2.0, "mana": 0.5, "spell_power": 0.3, "attack_power": 0.8, "movement_speed": 0.5, "luck": 1.0}
		CharacterClass.HEALER:
			return {"health": 1.0, "defense": 0.8, "mana": 2.0, "spell_power": 1.8, "attack_power": 0.4, "movement_speed": 1.0, "luck": 1.2}
		CharacterClass.SUPPORT:
			return {"health": 1.2, "defense": 1.0, "mana": 1.5, "spell_power": 1.3, "attack_power": 0.7, "movement_speed": 1.3, "luck": 1.5}
		CharacterClass.ATTACKER:
			return {"health": 1.0, "defense": 0.6, "mana": 0.8, "spell_power": 0.6, "attack_power": 1.8, "movement_speed": 1.4, "luck": 1.0}
		_:
			return {"health": 1.0, "defense": 1.0, "mana": 1.0, "spell_power": 1.0, "attack_power": 1.0, "movement_speed": 1.0, "luck": 1.0}

func improve_substat_from_quest(quest_type: String, success_rate: float):
	# Low chance to improve relevant substat based on quest type and success
	if randf() < 0.1 * success_rate:  # 10% base chance modified by success rate
		var current_value = get(quest_type)
		set(quest_type, current_value + 1)

func add_experience(amount: int):
	experience += amount
	total_experience_earned += amount  # Track total experience earned
	
	var exp_needed = get_experience_needed_for_next_level()
	while experience >= exp_needed:
		experience -= exp_needed
		level_up()
		exp_needed = get_experience_needed_for_next_level()

func record_quest_completion(quest_name: String, success: bool, rewards: Dictionary):
	"""Record quest completion in character history"""
	var quest_record = {
		"quest_name": quest_name,
		"success": success,
		"rewards": rewards,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	quest_history.append(quest_record)
	
	if success:
		quests_completed += 1
		# Track rewards
		if rewards.has("gold"):
			total_gold_earned += rewards.gold
		if rewards.has("influence"):
			total_influence_earned += rewards.influence
	else:
		quests_failed += 1

func record_injury(injury_type: InjuryType, duration: float):
	"""Record injury in character history"""
	total_injuries_sustained += 1
	
	var injury_record = {
		"injury_type": injury_type,
		"duration": duration,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	injury_history.append(injury_record)

func record_promotion_attempt(success: bool):
	"""Record promotion attempt in character history"""
	promotions_attempted += 1
	if success:
		promotions_succeeded += 1
	else:
		promotions_failed += 1

func get_experience_needed_for_next_level() -> int:
	# Much more accessible experience requirements for exciting early progression
	match level:
		1: return 10   # Level 1 -> 2: Only 10 XP needed
		2: return 25   # Level 2 -> 3: 25 XP needed
		3: return 50   # Level 3 -> 4: 50 XP needed
		4: return 100  # Level 4 -> 5: 100 XP needed
		5: return 200  # Level 5 -> 6: 200 XP needed
		_: return level * 100 + (level - 1) * 50  # Original scaling for higher levels

#endregion

#region Promotion System
func check_promotion_eligibility():
	if level >= get_level_requirement_for_next_rank() and not promotion_quest_available:
		promotion_quest_available = true

func get_level_requirement_for_next_rank() -> int:
	match rank:
		Rank.F: return 5
		Rank.E: return 10
		Rank.D: return 15
		Rank.C: return 25
		Rank.B: return 40
		Rank.A: return 60
		_: return 100

func promote():
	if promotion_quest_completed:
		rank = Rank.values()[rank + 1] if rank < Rank.SSS else Rank.SSS
		promotion_quest_available = false
		promotion_quest_completed = false
		unlock_class_ability()

func unlock_class_ability():
	# Placeholder for class-specific abilities unlocked at promotion
	match character_class:
		CharacterClass.ATTACKER:
			if rank >= Rank.B:
				pass # Unlock "Remove Enemy" ability
		CharacterClass.TANK:
			if rank >= Rank.B:
				pass # Unlock "Damage Shield" ability
		# Add more class abilities later


#endregion

#region Injury System
func get_injury_duration() -> float :
	var cur_time =  Time.get_unix_time_from_system()
	var elapsed_time = cur_time - injury_start_time
	var duration_remaining = injury_duration - elapsed_time
	return duration_remaining

func apply_injury(injury: InjuryType, duration: float):
	injury_type = injury
	injury_duration = duration
	injury_start_time = Time.get_unix_time_from_system()
	is_on_quest = false  # Remove from any active quest
	
	# Record injury in history
	record_injury(injury, duration)

func heal_injury():
	injury_type = InjuryType.NONE
	injury_duration = 0.0
	injury_start_time = 0.0

func is_injured() -> bool:
	if injury_type == InjuryType.NONE:
		return false
	
	var current_time = Time.get_unix_time_from_system()
	var elapsed_time = current_time - injury_start_time
	
	if elapsed_time >= injury_duration:
		heal_injury()
		return false
	
	return true

#endregion

#region Utility Functions
func get_effective_stats() -> Dictionary:
	var stats = {
		"health": health,
		"defense": defense,
		"mana": mana,
		"spell_power": spell_power,
		"attack_power": attack_power,
		"movement_speed": movement_speed,
		"luck": luck
	}
	
	# Apply injury debuffs
	if is_injured():
		match injury_type:
			InjuryType.PHYSICAL_WOUND:
				stats.health = int(stats.health * 0.7)
				stats.attack_power = int(stats.attack_power * 0.8)
			InjuryType.MENTAL_TRAUMA:
				stats.mana = int(stats.mana * 0.6)
				stats.spell_power = int(stats.spell_power * 0.7)
			InjuryType.CURSED_AFFLICTION:
				stats.luck = int(stats.luck * 0.5)
			InjuryType.EXHAUSTION:
				stats.movement_speed = int(stats.movement_speed * 0.5)
			InjuryType.POISON:
				stats.health = int(stats.health * 0.8)
				stats.defense = int(stats.defense * 0.9)
	
	return stats

func get_recruitment_cost() -> Dictionary:
	var base_influence = 50 + (quality * 25) + (rank * 10)
	var base_gold = 20 + (quality * 10)
	
	return {
		"influence": base_influence,
		"gold": base_gold,
		"food": quality * 2,
		"building_materials": 0,
		"armor": 0 if quality == Quality.ONE_STAR else quality - 1,
		"weapons": 0 if quality == Quality.ONE_STAR else quality - 1
	}

func get_upkeep_cost() -> int:
	return 1 + (rank / 3)  # Food cost increases with rank

func can_go_on_quest() -> bool:
	return not is_on_quest and not is_injured()

func get_class_name() -> String:
	match character_class:
		CharacterClass.TANK: return "Tank"
		CharacterClass.HEALER: return "Healer"
		CharacterClass.SUPPORT: return "Support"
		CharacterClass.ATTACKER: return "Attacker"
		_: return "Unknown"

func get_rank_name() -> String:
	match rank:
		Rank.F: return "F"
		Rank.E: return "E"
		Rank.D: return "D"
		Rank.C: return "C"
		Rank.B: return "B"
		Rank.A: return "A"
		Rank.S: return "S"
		Rank.SS: return "SS"
		Rank.SSS: return "SSS"
		_: return "?"
#endregion
