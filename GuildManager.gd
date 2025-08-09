class_name GuildManager
extends Node

## TODO: Any instance of RAND should be removed, replace all RANDs with a single SEED that is generated when NEW GAME is pressed.  That SEED should be saved and used by everything inside the game that requires a RAND

signal character_recruited(character: Character)
signal quest_started(quest: Quest)
signal quest_completed(quest: Quest)
signal emergency_quest_available(requirements: Dictionary)
signal transformation_unlocked(transformation_name: String)

# Guild Resources
@export var influence: int = 100
@export var gold: int = 50
@export var building_materials: int = 0
@export var armor_pieces: int = 0
@export var weapons: int = 0
@export var food: int = 20

# Guild State
@export var roster: Array[Character] = []
@export var max_roster_size: int = 5
@export var available_recruits: Array[Character] = []
@export var recruit_rotation_timer: float = 0.0
@export var recruit_refresh_time: float = 300.0  # 5 minutes

# Quest Management
@export var available_quests: Array[Quest] = []
@export var active_quests: Array[Quest] = []
@export var completed_quests: Array[Quest] = []
@export var emergency_quests: Array[Quest] = []

# Progression Tracking
@export var total_quests_completed: int = 0
@export var quests_completed_by_rank: Dictionary = {}
@export var transformations_unlocked: Dictionary = {"Roster Size"=5,"Healer's Guild"=false,"Armory"=false,"Market"=false,"Training Ground's"=false,"Library"=false,"Workshop"=false}

# Save System
@export var last_save_time: float = 0.0
@export var auto_save_interval: float = 600.0  # 10 minutes
@export var save_file_path: String = "res://Save_Data/guild_save.json"

# Recruitment Settings
@export var recruitment_quality_modifier: float = 1.0
@export var max_available_recruits: int = 3
@export var recruit_stay_duration: float = 600.0  # 10 minutes

func _ready():
	#load_game()
	initialize_guild()
	
	# Initialize quest completion tracking
	for rank in Quest.QuestRank.values():
		quests_completed_by_rank[rank] = 0

func _process(delta):
	update_quest_timers(delta)
	update_recruitment_timer(delta)
	update_auto_save(delta)
	check_for_transformations()

func initialize_guild():
	if roster.is_empty():
		# Start with one basic character
		var starter = Character.new("Guild Founder", Character.CharacterClass.ATTACKER, Character.Quality.TWO_STAR)
		add_character_to_roster(starter)
	
	if available_quests.is_empty():
		generate_initial_quests()
	
	if available_recruits.is_empty():
		generate_recruits()

func generate_initial_quests():
	# Generate some basic F and D rank quests to start
	for i in range(5):
		var quest_rank = Quest.QuestRank.F if i < 3 else Quest.QuestRank.D
		var quest_type = Quest.QuestType.values()[randi() % (Quest.QuestType.values().size() - 1)]  # Exclude EMERGENCY
		var quest = Quest.create_quest(quest_type, quest_rank)
		available_quests.append(quest)

func generate_recruits():
	available_recruits.clear()
	
	for i in range(max_available_recruits):
		var character = generate_random_recruit()
		available_recruits.append(character)

func generate_random_recruit() -> Character:
	var classes = Character.CharacterClass.values()
	var char_class = classes[randi() % classes.size()]
	
	# Apply recruitment quality modifier
	var quality_roll = randf()
	var quality: Character.Quality
	
	if quality_roll < 0.1 * recruitment_quality_modifier:
		quality = Character.Quality.THREE_STAR
	elif quality_roll < 0.3 * recruitment_quality_modifier:
		quality = Character.Quality.TWO_STAR
	else:
		quality = Character.Quality.ONE_STAR
	
	return Character.new("", char_class, quality)

func add_character_to_roster(character: Character) -> bool:
	if roster.size() >= max_roster_size:
		return false
	
	roster.append(character)
	character_recruited.emit(character)
	return true

func recruit_character(character: Character) -> Dictionary:
	var result = {"success": false, "message": ""}
	
	if not character in available_recruits:
		result.message = "Character not available for recruitment"
		return result
	
	if roster.size() >= max_roster_size:
		result.message = "Roster is full"
		return result
	
	var cost = character.get_recruitment_cost()
	if not can_afford_cost(cost):
		result.message = "Cannot afford recruitment cost"
		return result
	
	# Pay the cost
	spend_resources(cost)
	
	# Add to roster
	add_character_to_roster(character)
	available_recruits.erase(character)
	
	result.success = true
	result.message = "Successfully recruited " + character.character_name
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

func start_quest(quest: Quest, party: Array[Character]) -> Dictionary:
	var result = {"success": false, "message": ""}
	
	if not quest in available_quests:
		result.message = "Quest not available"
		return result
	
	var assignment_check = quest.can_assign_party(party)
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
	if quest.start_quest(party):
		available_quests.erase(quest)
		active_quests.append(quest)
		quest_started.emit(quest)
		save_game()  # Save when starting quest
		
		result.success = true
		result.message = "Quest started successfully"
	else:
		result.message = "Failed to start quest"
	
	return result

func update_quest_timers(delta: float):
	var completed_this_frame = []
	
	for quest in active_quests:
		if quest.update_quest_progress():
			completed_this_frame.append(quest)
	
	for quest in completed_this_frame:
		complete_quest(quest)

func complete_quest(quest: Quest):
	active_quests.erase(quest)
	completed_quests.append(quest)
	
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
	
	#quest.active_quest_status = quest.QuestStatus.COMPLETED
	
	## TODO: Track down why this doesn't get emit.
	quest_completed.emit(quest)
	
	for adven in quest.assigned_party :
		adven.is_on_quest = false
	
	# Generate replacement quest
	generate_replacement_quest(quest.quest_rank)

func generate_replacement_quest(completed_rank: Quest.QuestRank):
	# Generate a new quest of similar or slightly higher rank
	var new_rank = completed_rank
	if randf() < 0.2 and completed_rank < Quest.QuestRank.SSS:  # 20% chance for higher rank
		new_rank = Quest.QuestRank.values()[completed_rank + 1]
	
	var quest_type = Quest.QuestType.values()[randi() % (Quest.QuestType.values().size() - 1)]  # Exclude EMERGENCY
	var new_quest = Quest.create_quest(quest_type, new_rank)
	available_quests.append(new_quest)

func update_recruitment_timer(delta: float):
	recruit_rotation_timer += delta
	
	if recruit_rotation_timer >= recruit_refresh_time:
		rotate_recruits()
		recruit_rotation_timer = 0.0

func rotate_recruits():
	# Remove recruits who've stayed too long, add new ones
	var recruits_to_remove = []
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
	return roster.filter(func(c): return c.can_go_on_quest())

func get_characters_needing_promotion() -> Array[Character]:
	return roster.filter(func(c): return c.promotion_quest_available)

func check_for_transformations():
	# Check if we meet requirements for transformation unlocks
	var current_roster_size = roster.size()
	var high_rank_count = roster.filter(func(c): return c.rank >= Character.Rank.D).size()
	
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
		"available_quests": serialize_quests(available_quests),
		"active_quests": serialize_quests(active_quests),
		"completed_quests": serialize_quests(completed_quests),
		"emergency_quests": serialize_quests(emergency_quests),
		"total_quests_completed": total_quests_completed,
		"quests_completed_by_rank": quests_completed_by_rank,
		"transformations_unlocked": transformations_unlocked,
		"recruitment_quality_modifier": recruitment_quality_modifier,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()

func load_game():
	if not FileAccess.file_exists(save_file_path):
		return
	
	var file = FileAccess.open(save_file_path, FileAccess.READ)
	if not file:
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		return
	
	var save_data = json.data
	
	# Load resources
	influence = save_data.get("influence", 100)
	gold = save_data.get("gold", 50)
	building_materials = save_data.get("building_materials", 0)
	armor_pieces = save_data.get("armor_pieces", 0)
	weapons = save_data.get("weapons", 0)
	food = save_data.get("food", 20)
	
	# Load roster and other data
	max_roster_size = save_data.get("max_roster_size", 5)
	roster = deserialize_characters(save_data.get("roster", []))
	available_recruits = deserialize_characters(save_data.get("available_recruits", []))
	available_quests = deserialize_quests(save_data.get("available_quests", []))
	active_quests = deserialize_quests(save_data.get("active_quests", []))
	completed_quests = deserialize_quests(save_data.get("completed_quests", []))
	emergency_quests = deserialize_quests(save_data.get("emergency_quests", []))
	total_quests_completed = save_data.get("total_quests_completed", 0)
	quests_completed_by_rank = save_data.get("quests_completed_by_rank", {})
	transformations_unlocked = save_data.get("transformations_unlocked", ["none"])
	recruitment_quality_modifier = save_data.get("recruitment_quality_modifier", 1.0)
	
	# Handle offline progress for time-based systems
	handle_offline_progress(save_data.get("timestamp", Time.get_unix_time_from_system()))

func handle_offline_progress(last_save_timestamp: float):
	var current_time = Time.get_unix_time_from_system()
	var offline_seconds = current_time - last_save_timestamp
	
	if offline_seconds <= 0:
		return
	
	# Update quest progress for active quests
	var completed_offline = []
	for quest in active_quests:
		quest.start_time -= offline_seconds  # Simulate time passage
		if quest.get_time_remaining() <= 0:
			quest.complete_quest()
			completed_offline.append(quest)
	
	for quest in completed_offline:
		complete_quest(quest)
	
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

func serialize_quests(quests: Array[Quest]) -> Array:
	var serialized = []
	for quest in quests:
		serialized.append(quest_to_dict(quest))
	return serialized

func deserialize_quests(data: Array) -> Array[Quest]:
	var quests: Array[Quest] = []
	for quest_data in data:
		quests.append(dict_to_quest(quest_data))
	return quests

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
		"is_on_quest": character.is_on_quest,
		"injury_type": character.injury_type,
		"injury_duration": character.injury_duration,
		"injury_start_time": character.injury_start_time,
		"personal_gold": character.personal_gold,
		"promotion_quest_available": character.promotion_quest_available,
		"promotion_quest_completed": character.promotion_quest_completed
	}

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
	character.is_on_quest = data.get("is_on_quest", false)
	character.injury_type = data.get("injury_type", Character.InjuryType.NONE)
	character.injury_duration = data.get("injury_duration", 0.0)
	character.injury_start_time = data.get("injury_start_time", 0.0)
	character.personal_gold = data.get("personal_gold", 0)
	character.promotion_quest_available = data.get("promotion_quest_available", false)
	character.promotion_quest_completed = data.get("promotion_quest_completed", false)
	return character

func quest_to_dict(quest: Quest) -> Dictionary:
	return {
		"quest_name": quest.quest_name,
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
		#"individual_checks": quest.individual_checks
	}

func dict_to_quest(data: Dictionary) -> Quest:
	var quest = Quest.new()
	quest.quest_name = data.get("quest_name", "")
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
	quest.assigned_party = deserialize_characters(data.get("assigned_party", []))
	quest.active_quest_status = data.get("active_quest_status", Quest.QuestStatus.NOTSTARTED)
	quest.success_rate = data.get("success_rate", 0.0)
	#quest.individual_checks = data.get("individual_checks", [])
	return quest

func clear_save_file():
	if FileAccess.file_exists(save_file_path):
		DirAccess.remove_absolute(save_file_path)
	
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
	available_quests.clear()
	active_quests.clear()
	completed_quests.clear()
	emergency_quests.clear()
	total_quests_completed = 0
	quests_completed_by_rank.clear()
	transformations_unlocked.clear()
	recruitment_quality_modifier = 1.0
	
	initialize_guild()

func get_guild_status_summary() -> Dictionary:
	return {
		"active_quests_count": active_quests.size(),
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
