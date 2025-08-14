extends GuildManager

# TODO: Personalize save system for Moonlit Cafe

#region Variables
@export var last_save_time: float = 0.0
@export var auto_save_interval: float = 600.0  # 10 minutes
@export var save_file_path: String = "res://Save_Data/guild_save.json"
#endregion

#region Built-Ins
func _ready() -> void:
	pass
#endregion

#region Public Methods
## Centralized save entry-point. Accepts the GuildManager instance to persist.
func save_game(gm: GuildManager) -> void:
	var save_data := {
		"influence": gm.influence,
		"gold": gm.gold,
		"building_materials": gm.building_materials,
		"armor_pieces": gm.armor_pieces,
		"weapons": gm.weapons,
		"food": gm.food,
		"roster": serialize_characters(gm.roster),
		"max_roster_size": gm.max_roster_size,
		"available_recruits": serialize_characters(gm.available_recruits),
		"available_quests": serialize_quests(gm.available_quests),
		"active_quests": serialize_quests(gm.active_quests),
		"completed_quests": serialize_quests(gm.completed_quests),
		"emergency_quests": serialize_quests(gm.emergency_quests),
		"total_quests_completed": gm.total_quests_completed,
		"quests_completed_by_rank": gm.quests_completed_by_rank,
		"transformations_unlocked": gm.transformations_unlocked,
		"recruitment_quality_modifier": gm.recruitment_quality_modifier,
		"timestamp": Time.get_unix_time_from_system(),
		"rng_seed": RNG.wrapper.get_seed(),
		"rng_state": RNG.wrapper.get_state()
	}

	var file := FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		
## Loads game state into the provided GuildManager instance.
func load_game(gm: GuildManager) -> void:
	if not FileAccess.file_exists(save_file_path):
		return

	var file := FileAccess.open(save_file_path, FileAccess.READ)
	if not file:
		return
		
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		return
	
	var save_data: Dictionary = json.data
	
	# Load resources
	gm.influence = save_data.get("influence", 100)
	gm.gold = save_data.get("gold", 50)
	gm.building_materials = save_data.get("building_materials", 0)
	gm.armor_pieces = save_data.get("armor_pieces", 0)
	gm.weapons = save_data.get("weapons", 0)
	gm.food = save_data.get("food", 20)
	
	# Load roster and other data
	gm.max_roster_size = save_data.get("max_roster_size", 5)
	gm.roster = deserialize_characters(save_data.get("roster", []))
	gm.available_recruits = deserialize_characters(save_data.get("available_recruits", []))
	gm.available_quests = deserialize_quests(save_data.get("available_quests", []))
	gm.active_quests = deserialize_quests(save_data.get("active_quests", []))
	gm.completed_quests = deserialize_quests(save_data.get("completed_quests", []))
	gm.emergency_quests = deserialize_quests(save_data.get("emergency_quests", []))
	gm.total_quests_completed = save_data.get("total_quests_completed", 0)
	gm.quests_completed_by_rank = save_data.get("quests_completed_by_rank", {})
	gm.transformations_unlocked = save_data.get("transformations_unlocked", {})
	gm.recruitment_quality_modifier = save_data.get("recruitment_quality_modifier", 1.0)

	# Restore RNG
	var saved_seed: int = int(save_data.get("rng_seed", 0))
	var saved_state: int = int(save_data.get("rng_state", 0))
	if saved_seed != 0:
		RNG.wrapper.set_seed(saved_seed)
	if saved_state != 0:
		RNG.wrapper.set_state(saved_state)
	
	# Handle offline progress for time-based systems
	handle_offline_progress(gm,save_data.get("timestamp", Time.get_unix_time_from_system()))

## Centralized auto-save timer; call from game loop with the GuildManager reference.
func update_auto_save(delta: float, gm: GuildManager) -> void:
	last_save_time += delta
	if last_save_time >= auto_save_interval:
		save_game(gm)
		last_save_time = 0.0

## Deletes save file and resets GuildManager to initial state.
func clear_save_file(gm: GuildManager) -> void:
	if FileAccess.file_exists(save_file_path):
		DirAccess.remove_absolute(save_file_path)

	# Reset guild state
	gm.influence = 100
	gm.gold = 50
	gm.building_materials = 0
	gm.armor_pieces = 0
	gm.weapons = 0
	gm.food = 20
	gm.roster.clear()
	gm.max_roster_size = 5
	gm.available_recruits.clear()
	gm.available_quests.clear()
	gm.active_quests.clear()
	gm.completed_quests.clear()
	gm.emergency_quests.clear()
	gm.total_quests_completed = 0
	gm.quests_completed_by_rank.clear()
	gm.transformations_unlocked.clear()
	gm.recruitment_quality_modifier = 1.0

	# New run -> new RNG seed
	RNG.wrapper.randomize_with_new_seed()
	# Update recruitment rotation
	
func handle_offline_progress(gm:GuildManager,last_save_timestamp: float):
	var current_time = Time.get_unix_time_from_system()
	var offline_seconds = current_time - last_save_timestamp
	
	if offline_seconds <= 0:
		return
	
	# Update quest progress for active quests
	var completed_offline = []
	for quest in gm.active_quests:
		quest.start_time -= offline_seconds  # Simulate time passage
		if quest.get_time_remaining() <= 0:
			quest.complete_quest()
			completed_offline.append(quest)
	
	for quest in completed_offline:
		GameGlobalEvents.emit_signal("quest_completed",quest)
		
	var rotations_missed = int(offline_seconds / gm.recruitment_hub.recruit_refresh_time)
	for i in range(min(rotations_missed, gm.recruitment_hub.max_offline_rotations)):  # Limit to 3 rotations max
		GameGlobalEvents.emit_signal("rotate_recruits")
#endregion

#region Serialization Helpers
func serialize_characters(characters: Array[Character]) -> Array:
	var serialized: Array = []
	for character in characters:
		serialized.append(character_to_dict(character))
	return serialized

func deserialize_characters(data: Array) -> Array[Character]:
	var characters: Array[Character] = []
	for char_data in data:
		characters.append(dict_to_character(char_data))
	return characters

func serialize_quests(quests: Array[Quest]) -> Array:
	var serialized: Array = []
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
	var character := Character.new()
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
		"active_quest_status": quest.active_quest_status,
		"success_rate": quest.success_rate,
	}

func dict_to_quest(data: Dictionary) -> Quest:
	var quest := Quest.new()
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
	return quest
#endregion
