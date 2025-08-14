class_name Character
extends Resource

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

# Base Stats
@export var character_name: String
@export var character_class: CharacterClass
@export var quality: Quality
@export var rank: Rank = Rank.F
@export var level: int = 1
@export var experience: int = 0

# Core Stats
@export var health: int = 100
@export var defense: int = 10
@export var mana: int = 50
@export var spell_power: int = 10
@export var attack_power: int = 15
@export var movement_speed: int = 10
@export var luck: int = 5

# Sub-stats (Mission Specific Skills)
@export var gathering: int = 0
@export var hunting_trapping: int = 0
@export var diplomacy: int = 0
@export var caravan_guarding: int = 0
@export var escorting: int = 0
@export var stealth: int = 0
@export var odd_jobs: int = 0

# Status
@export var is_on_quest: bool = false
@export var injury_type: InjuryType = InjuryType.NONE
@export var injury_duration: float = 0.0
@export var injury_start_time: float = 0.0

# Personal gold earned from quests
@export var personal_gold: int = 0

# Promotion requirements tracking
@export var promotion_quest_available: bool = false
@export var promotion_quest_completed: bool = false

func _init(name: String = "", char_class: CharacterClass = CharacterClass.ATTACKER, char_quality: Quality = Quality.ONE_STAR):
	character_name = name if name != "" else generate_random_name()
	character_class = char_class
	quality = char_quality
	generate_base_stats()
	generate_random_substats()

func generate_random_name() -> String:
	var first_names = ["Aeliana", "Borin", "Caelen", "Dara", "Elowen", "Finn", "Gilda", "Hamon", "Iris", "Joren", "Kira", "Lael", "Mira", "Nolan", "Orin", "Piper", "Quinn", "Raven", "Sera", "Thane", "Uma", "Vex", "Wren", "Xara", "Yara", "Zephyr"]
	var last_names = ["Ironforge", "Swiftbow", "Goldleaf", "Stormwind", "Brightblade", "Shadowmere", "Frostborn", "Firehart", "Moonwhisper", "Starweaver", "Thornfield", "Wildwood", "Blackstone", "Silverstream", "Dragonbane", "Wolfheart", "Eagleeye", "Bearclaw", "Lionmane", "Foxglove"]
	return first_names[RNG.wrapper.randi() % first_names.size()] + " " + last_names[RNG.wrapper.randi() % last_names.size()]

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
	# Randomly assign 0-1 substats to new recruits
	var substat_count = RNG.wrapper.randi_range(0,1)
	var available_substats = ["gathering", "hunting_trapping", "diplomacy", "caravan_guarding", "escorting", "stealth", "odd_jobs"]
	available_substats.shuffle()
	
	for i in range(substat_count):
		var substat = available_substats[i]
		var value = RNG.wrapper.randi_range(1, 5)
		set(substat, value)

func level_up():
	level += 1
	experience = 0
	
	var quality_bonus = 1.0 + (quality - 1) * 0.1
	var class_modifiers = get_class_level_modifiers()
	
	# Apply stat increases with randomness
	health += RNG.wrapper.randi_range(int(3 * class_modifiers.health * quality_bonus), int(8 * class_modifiers.health * quality_bonus))
	defense += RNG.wrapper.randi_range(int(1 * class_modifiers.defense * quality_bonus), int(3 * class_modifiers.defense * quality_bonus))
	mana += RNG.wrapper.randi_range(int(2 * class_modifiers.mana * quality_bonus), int(6 * class_modifiers.mana * quality_bonus))
	spell_power += RNG.wrapper.randi_range(int(1 * class_modifiers.spell_power * quality_bonus), int(4 * class_modifiers.spell_power * quality_bonus))
	attack_power += RNG.wrapper.randi_range(int(1 * class_modifiers.attack_power * quality_bonus), int(4 * class_modifiers.attack_power * quality_bonus))
	movement_speed += RNG.wrapper.randi_range(int(0 * class_modifiers.movement_speed * quality_bonus), int(2 * class_modifiers.movement_speed * quality_bonus))
	luck += RNG.wrapper.randi_range(int(0 * class_modifiers.luck * quality_bonus), int(2 * class_modifiers.luck * quality_bonus))
	
	check_promotion_eligibility()

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
	if RNG.wrapper.randf() < 0.1 * success_rate:  # 10% base chance modified by success rate
		var current_value = get(quest_type)
		set(quest_type, current_value + 1)

func add_experience(amount: int):
	experience += amount
	var exp_needed = get_experience_needed_for_next_level()
	while experience >= exp_needed:
		experience -= exp_needed
		level_up()
		exp_needed = get_experience_needed_for_next_level()

func get_experience_needed_for_next_level() -> int:
	return level * 100 + (level - 1) * 50  # Scaling experience requirements

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
