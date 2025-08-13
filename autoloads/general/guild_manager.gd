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
	SaveManager.update_auto_save(delta, self)
	check_for_transformations()

func initialize_guild():
	#if roster.is_empty():
		## Start with one basic character
		#var starter = Character.new("Guild Founder", Character.CharacterClass.ATTACKER, Character.Quality.TWO_STAR)
		#add_character_to_roster(starter)
	#
	if available_quests.is_empty():
		generate_initial_quests()
	
	if available_recruits.is_empty():
		generate_recruits()

func generate_initial_quests():
	# Generate some basic F and D rank quests to start
	for i in range(5):
		var quest_rank = Quest.QuestRank.F if i < 3 else Quest.QuestRank.D
		var quest_type = Quest.QuestType.values()[RNG.randi() % (Quest.QuestType.values().size() - 1)]  # Exclude EMERGENCY
		var quest = Quest.create_quest(quest_type, quest_rank)
		available_quests.append(quest)

func generate_recruits():
	available_recruits.clear()
	
	for i in range(max_available_recruits):
		var character = generate_random_recruit()
		available_recruits.append(character)

func generate_random_recruit() -> Character:
	var classes = Character.CharacterClass.values()
	var char_class = classes[RNG.randi() % classes.size()]
	
	# Apply recruitment quality modifier
	var quality_roll = RNG.randf()
	var quality: Character.Quality = Character.Quality.ONE_STAR
	
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
		SaveManager.save_game(self)  # Save when starting quest
		
		result.success = true
		result.message = "Quest started successfully"
	else:
		result.message = "Failed to start quest"
	
	return result

func update_quest_timers(_delta: float):
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
	if RNG.randf() < 0.2 and completed_rank < Quest.QuestRank.SSS:  # 20% chance for higher rank
		new_rank = Quest.QuestRank.values()[completed_rank + 1]
	
	var quest_type = Quest.QuestType.values()[RNG.randi() % (Quest.QuestType.values().size() - 1)]  # Exclude EMERGENCY
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
		if RNG.randf() < 0.3:  # 30% chance each recruit leaves
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

#region Debug Helpers
func debug_refresh_recruits() -> void:
	generate_recruits()
	recruit_rotation_timer = 0.0

func debug_reload_available_quests() -> void:
	available_quests.clear()
	generate_initial_quests()
#endregion

#region Debug: External Controls
## Sets guild resources directly for debugging.
func debug_set_resources(resources: Dictionary) -> void:
	influence = resources.get("influence", influence)
	gold = resources.get("gold", gold)
	food = resources.get("food", food)
	building_materials = resources.get("building_materials", building_materials)
	armor_pieces = resources.get("armor", armor_pieces)
	weapons = resources.get("weapons", weapons)

## Generates a single quest at a specified rank and optional type for debugging
func debug_generate_quest(rank: Quest.QuestRank, type_id: int = -1) -> Quest:
	var type_values: Array = Quest.QuestType.values()
	var quest_type: int
	if type_id >= 0 and type_id < type_values.size():
		quest_type = type_id
	else:
		# Default to a random non-emergency quest type if possible
		var non_emergency_count: int = max(1, type_values.size() - 1)
		quest_type = type_values[RNG.randi() % non_emergency_count]
	var quest := Quest.create_quest(quest_type, rank)
	available_quests.append(quest)
	return quest

## Regenerates the available recruit list immediately
func debug_generate_recruits() -> void:
	generate_recruits()
	recruit_rotation_timer = 0.0
#endregion

func get_available_characters() -> Array[Character]:
	return roster.filter(func(c): return c.can_go_on_quest())

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

## Auto-save logic moved to SaveManager


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
