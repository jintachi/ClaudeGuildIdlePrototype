## The Guild Manager - now also containing global game state
extends Node

#region Global Variables (merged from GameGlobal)
var active_scene : StringName
var scene_node : Node
var previous_scene_before_map : StringName = ""
var previous_scene_node : Node
var current_roster : Array[Character]
var current_recruit_list : Array[Character]
var project_theme : Theme = preload("res://Assets/Themes/theme.tres")
#endregion

@warning_ignore_start("unused_signal")

#region Local Signals
signal character_recruited(character: Character)
signal quest_started(quest: Quest)
signal quest_completed(quest: Quest)
signal emergency_quest_available(requirements: Dictionary)
signal transformation_unlocked(transformation_name: String)
#endregion

@warning_ignore_restore("unused_signal")


#region Export Vars
# Guild Resources
@export var influence: int = 100
@export var gold: int = 50
@export var building_materials: int = 0
@export var armor_pieces: int = 0
@export var weapons: int = 0
@export var food: int = 20

# Guild Components
var recruitment_hub:RecruitersHub
var quest_board:QuestHub
var guild_roster:GuildRoster
var guild_hall:GuildHall
var world_map:WorldMap

# Quest Management
@export var available_quests: Array[Quest] = []
@export var active_quests: Array[Quest] = []
@export var completed_quests: Array[Quest] = []
@export var emergency_quests: Array[Quest] = []

# Progression Tracking
@export var total_quests_completed: int = 0
@export var quests_completed_by_rank: Dictionary = {}
@export var transformations_unlocked: Dictionary = {"Roster Size"=5,"Healer's Guild"=false,"Armory"=false,"Market"=false,"Training Ground's"=false,"Library"=false,"Workshop"=false}

#endregion

func _ready():
	# Initialize global state (merged from GameGlobal)
	#var sound_loader = SoundLoader.new()
	#sound_loader.load_audio()
	#sound_loader = null
	# GameGlobalEvents.scene_transition.connect(_listen_to_scene_change)
	GameGlobalEvents.new_game.connect(initialize_guild)
	
func _process(delta):
	if is_instance_valid(recruitment_hub):
		recruitment_hub.update_recruitment_timer(delta)
		update_quest_timers(delta)
		check_for_transformations()
		SaveManager.update_auto_save(delta, self)

func initialize_guild(new_game:bool):
	if !new_game:
		# LOAD STUFf	
		# TODO : Load save data from initialized data
		print("Load Data Now...")
	else :
		if guild_roster == null :
			print("Initialized")
			world_map = WorldMap.new()
			recruitment_hub = RecruitersHub.new()
			quest_board = QuestHub.new()
			guild_roster = GuildRoster.new()
			guild_hall = GuildHall.new()
			
			var starter = Character.new("Guild Founder", Character.CharacterClass.ATTACKER, Character.Quality.TWO_STAR)
			current_roster.append(starter)
			
			GameGlobalEvents.generate_recruits.emit()
	
			GameGlobalEvents.game_loaded.emit()
			
			if available_quests.is_empty():
				quest_board.generate_initial_quests()

			# Initialize quest completion tracking
			for rank in Quest.QuestRank.values():
				quests_completed_by_rank[rank] = 0

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

func get_available_characters() -> Array[Character]:
	if is_instance_valid(guild_roster) : 
		return guild_roster.roster.filter(func(c): return c.can_go_on_quest())
	else : return []

func get_characters_needing_promotion() -> Array[Character]:
	if !is_instance_valid(guild_roster) : return []
	return guild_roster.roster.filter(func(c): return c.promotion_quest_available)

func check_for_transformations():
	# Check if we meet requirements for transformation unlocks
	if is_instance_valid(guild_roster) :
		var current_roster_size = guild_roster.roster.size()
		var _high_rank_count = guild_roster.roster.filter(func(c): return c.rank >= Character.Rank.D).size()
	
		# First transformation: Roster expansion
		if not "roster_expansion_1" in transformations_unlocked:
			if current_roster_size >= 5 and total_quests_completed >= 10:
				var d_rank_members = guild_roster.roster.filter(func(c): return c.rank >= Character.Rank.D).size()
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
			guild_roster.max_roster_size = 10
			transformations_unlocked["Roster Size"] = 10
			transformation_unlocked.emit("Roster Expansion")
	
func get_guild_status_summary() -> Dictionary:
	return {
		"active_quests_count": active_quests.size(),
		"available_characters": get_available_characters().size(),
		#"total_characters": guild_roster.roster.size(),
		"characters_needing_promotion": get_characters_needing_promotion().size(),
		#"available_recruits": guild_roster.available_recruits.size(),
		"resources": {
			"influence": influence,
			"gold": gold,
			"food": food,
			"building_materials": building_materials,
			"armor": armor_pieces,
			"weapons": weapons
		}
	} 

func _on_quest_completed(quest: Quest):
	print("Quest completed: ", quest.quest_name)
	quest.active_quest_status = quest.QuestStatus.COMPLETED
	for member in quest.assigned_party :
		member.is_on_quest=false
	GameGlobalEvents.emit_signal("quest_completed",quest)

#region Global Helper Functions (merged from GameGlobal)
func delay(time: float) -> void:
	await get_tree().create_timer(time).timeout

func get_time() -> float: # get time in seconds
	return Time.get_unix_time_from_system()

func _set_prev_scene() -> void:
	previous_scene_before_map = active_scene
	previous_scene_node = scene_node

func _listen_to_scene_change(next_scene: StringName, scene_obj: Node) -> void:
	_set_prev_scene()
	active_scene = next_scene
	scene_node = scene_obj
#endregion
