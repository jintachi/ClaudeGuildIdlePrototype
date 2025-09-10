extends Node

# Core progression objectives that unlock systems and features
# These replace the old transformation system with a more systematic approach

#region Objective Categories
enum ObjectiveCategory {
	GUILD_EXPANSION,    # Roster size, facilities
	FACILITY_UNLOCK,    # New rooms and buildings
	SYSTEM_UNLOCK,      # New game mechanics
	ACHIEVEMENT,        # Milestone achievements
	STORY_PROGRESSION   # Main story objectives
}

enum ObjectiveStatus {
	LOCKED,      # Not yet available
	AVAILABLE,   # Requirements met, can be completed
	IN_PROGRESS, # Currently being worked on
	COMPLETED    # Finished
}
#endregion

#region Objective Data Structure
class ObjectiveData:
	var id: String
	var name: String
	var description: String
	var category: ObjectiveCategory
	var status: ObjectiveStatus = ObjectiveStatus.LOCKED
	var requirements: Dictionary = {}
	var rewards: Dictionary = {}
	var completion_time: float = 0.0
	var is_visible: bool = false  # Whether to show in UI
	
	func _init(obj_id: String, obj_name: String, obj_desc: String, obj_category: ObjectiveCategory):
		id = obj_id
		name = obj_name
		description = obj_desc
		category = obj_category
#endregion

#region Core Objectives Database
var objectives: Dictionary = {}

# Guild Expansion Objectives
var roster_expansion_1: ObjectiveData
var roster_expansion_2: ObjectiveData
var roster_expansion_3: ObjectiveData

# Facility Unlock Objectives
var training_grounds_unlock: ObjectiveData
var library_unlock: ObjectiveData
var workshop_unlock: ObjectiveData
var armory_unlock: ObjectiveData
var healers_guild_unlock: ObjectiveData
var market_unlock: ObjectiveData

# System Unlock Objectives
var equipment_system_unlock: ObjectiveData
var promotion_system_unlock: ObjectiveData
var quest_ranking_unlock: ObjectiveData
var character_training_unlock: ObjectiveData

# Achievement Objectives
var first_quest_completed: ObjectiveData
var first_character_promoted: ObjectiveData
var guild_reputation_milestone: ObjectiveData

# Story Progression Objectives
var guild_establishment: ObjectiveData
var first_major_threat: ObjectiveData
var regional_recognition: ObjectiveData
#endregion

#region Initialization
func _init():
	initialize_objectives()

func initialize_objectives():
	"""Initialize all objectives with their requirements and rewards"""
	
	# Guild Expansion Objectives
	roster_expansion_1 = ObjectiveData.new(
		"roster_expansion_1",
		"Expand Guild Quarters",
		"Increase your guild's capacity to accommodate more members",
		ObjectiveCategory.GUILD_EXPANSION
	)
	roster_expansion_1.requirements = {
		"roster_size": 5,
		"quests_completed": 10,
		"d_rank_members": 2,
		"d_rank_quests": 5
	}
	roster_expansion_1.rewards = {
		"max_roster_size": 10,
		"influence": 25
	}
	roster_expansion_1.is_visible = true
	
	roster_expansion_2 = ObjectiveData.new(
		"roster_expansion_2",
		"Major Guild Expansion",
		"Further expand your guild to accommodate elite members",
		ObjectiveCategory.GUILD_EXPANSION
	)
	roster_expansion_2.requirements = {
		"roster_size": 10,
		"quests_completed": 50,
		"c_rank_members": 3,
		"c_rank_quests": 15
	}
	roster_expansion_2.rewards = {
		"max_roster_size": 20,
		"influence": 100
	}
	roster_expansion_2.is_visible = false  # Hidden until roster_expansion_1 is completed
	
	roster_expansion_3 = ObjectiveData.new(
		"roster_expansion_3",
		"Elite Guild Headquarters",
		"Transform your guild into a major regional power",
		ObjectiveCategory.GUILD_EXPANSION
	)
	roster_expansion_3.requirements = {
		"roster_size": 20,
		"quests_completed": 150,
		"b_rank_members": 5,
		"b_rank_quests": 30
	}
	roster_expansion_3.rewards = {
		"max_roster_size": 50,
		"influence": 500
	}
	roster_expansion_3.is_visible = false
	
	# Facility Unlock Objectives
	training_grounds_unlock = ObjectiveData.new(
		"training_grounds_unlock",
		"Establish Training Grounds",
		"Build facilities to train and improve your characters",
		ObjectiveCategory.FACILITY_UNLOCK
	)
	training_grounds_unlock.requirements = {
		"roster_size": 3,
		"quests_completed": 5,
		"influence": 25
	}
	training_grounds_unlock.rewards = {
		"unlock_room": "Training Grounds",
		"influence": 10
	}
	training_grounds_unlock.is_visible = true
	
	library_unlock = ObjectiveData.new(
		"library_unlock",
		"Build Library",
		"Construct a library for research and skill development",
		ObjectiveCategory.FACILITY_UNLOCK
	)
	library_unlock.requirements = {
		"roster_size": 5,
		"quests_completed": 20,
		"influence": 50
	}
	library_unlock.rewards = {
		"unlock_room": "Library",
		"influence": 25
	}
	library_unlock.is_visible = true
	
	workshop_unlock = ObjectiveData.new(
		"workshop_unlock",
		"Construct Workshop",
		"Build a workshop for crafting and equipment enhancement",
		ObjectiveCategory.FACILITY_UNLOCK
	)
	workshop_unlock.requirements = {
		"roster_size": 8,
		"quests_completed": 40,
		"influence": 100
	}
	workshop_unlock.rewards = {
		"unlock_room": "Workshop",
		"influence": 50
	}
	workshop_unlock.is_visible = true
	
	armory_unlock = ObjectiveData.new(
		"armory_unlock",
		"Establish Armory",
		"Build an armory to manage equipment and gear",
		ObjectiveCategory.FACILITY_UNLOCK
	)
	armory_unlock.requirements = {
		"roster_size": 4,
		"quests_completed": 15,
		"influence": 25
	}
	armory_unlock.rewards = {
		"unlock_room": "Armory",
		"influence": 15
	}
	armory_unlock.is_visible = true
	
	healers_guild_unlock = ObjectiveData.new(
		"healers_guild_unlock",
		"Establish Healer's Guild",
		"Build connections with healers to treat injured characters",
		ObjectiveCategory.FACILITY_UNLOCK
	)
	healers_guild_unlock.requirements = {
		"roster_size": 6,
		"quests_completed": 25,
		"influence": 75,
		"injured_characters": 3  # Must have had injured characters
	}
	healers_guild_unlock.rewards = {
		"unlock_room": "Healer's Guild",
		"influence": 30
	}
	healers_guild_unlock.is_visible = true
	
	market_unlock = ObjectiveData.new(
		"market_unlock",
		"Establish Market Connections",
		"Build trade relationships for buying and selling goods",
		ObjectiveCategory.FACILITY_UNLOCK
	)
	market_unlock.requirements = {
		"roster_size": 7,
		"quests_completed": 30,
		"influence": 60,
		"gold_earned": 500
	}
	market_unlock.rewards = {
		"unlock_room": "Market",
		"influence": 40
	}
	market_unlock.is_visible = true
	
	# System Unlock Objectives
	equipment_system_unlock = ObjectiveData.new(
		"equipment_system_unlock",
		"Equipment System",
		"Unlock the ability to equip gear on characters",
		ObjectiveCategory.SYSTEM_UNLOCK
	)
	equipment_system_unlock.requirements = {
		"roster_size": 3,
		"quests_completed": 8
	}
	equipment_system_unlock.rewards = {
		"unlock_system": "equipment",
		"influence": 20
	}
	equipment_system_unlock.is_visible = true
	
	promotion_system_unlock = ObjectiveData.new(
		"promotion_system_unlock",
		"Character Promotion",
		"Unlock the ability to promote characters to higher ranks",
		ObjectiveCategory.SYSTEM_UNLOCK
	)
	promotion_system_unlock.requirements = {
		"roster_size": 4,
		"quests_completed": 12,
		"characters_level_5": 2
	}
	promotion_system_unlock.rewards = {
		"unlock_system": "promotion",
		"influence": 25
	}
	promotion_system_unlock.is_visible = true
	
	# Achievement Objectives
	first_quest_completed = ObjectiveData.new(
		"first_quest_completed",
		"First Quest",
		"Complete your first quest as a guild",
		ObjectiveCategory.ACHIEVEMENT
	)
	first_quest_completed.requirements = {
		"quests_completed": 1
	}
	first_quest_completed.rewards = {
		"influence": 5,
		"gold": 10
	}
	first_quest_completed.is_visible = true
	
	first_character_promoted = ObjectiveData.new(
		"first_character_promoted",
		"First Promotion",
		"Promote your first character to a higher rank",
		ObjectiveCategory.ACHIEVEMENT
	)
	first_character_promoted.requirements = {
		"promotions_completed": 1
	}
	first_character_promoted.rewards = {
		"influence": 15,
		"gold": 25
	}
	first_character_promoted.is_visible = true
	
	# Story Progression Objectives
	guild_establishment = ObjectiveData.new(
		"guild_establishment",
		"Guild Establishment",
		"Successfully establish your guild and complete initial setup",
		ObjectiveCategory.STORY_PROGRESSION
	)
	guild_establishment.requirements = {
		"roster_size": 1,
		"quests_completed": 1
	}
	guild_establishment.rewards = {
		"influence": 10,
		"unlock_system": "basic_guild_management"
	}
	guild_establishment.is_visible = true
	
	# Store all objectives in the dictionary
	objectives = {
		"roster_expansion_1": roster_expansion_1,
		"roster_expansion_2": roster_expansion_2,
		"roster_expansion_3": roster_expansion_3,
		"training_grounds_unlock": training_grounds_unlock,
		"library_unlock": library_unlock,
		"workshop_unlock": workshop_unlock,
		"armory_unlock": armory_unlock,
		"healers_guild_unlock": healers_guild_unlock,
		"market_unlock": market_unlock,
		"equipment_system_unlock": equipment_system_unlock,
		"promotion_system_unlock": promotion_system_unlock,
		"first_quest_completed": first_quest_completed,
		"first_character_promoted": first_character_promoted,
		"guild_establishment": guild_establishment
	}

#endregion

#region Objective Management
func check_objective_requirements(objective_id: String, guild_data: Dictionary) -> bool:
	"""Check if an objective's requirements are met"""
	var objective = objectives.get(objective_id)
	if not objective:
		return false
	
	var requirements = objective.requirements
	for requirement in requirements.keys():
		var required_value = requirements[requirement]
		var current_value = guild_data.get(requirement, 0)
		
		if current_value < required_value:
			return false
	
	return true

func update_objective_status(objective_id: String, guild_data: Dictionary):
	"""Update the status of an objective based on current guild state"""
	var objective = objectives.get(objective_id)
	if not objective:
		return
	
	# Don't update if already completed
	if objective.status == ObjectiveStatus.COMPLETED:
		return
	
	# Check if requirements are met
	if check_objective_requirements(objective_id, guild_data):
		if objective.status == ObjectiveStatus.LOCKED:
			objective.status = ObjectiveStatus.AVAILABLE
	else:
		if objective.status == ObjectiveStatus.AVAILABLE:
			objective.status = ObjectiveStatus.LOCKED

func complete_objective(objective_id: String) -> bool:
	"""Mark an objective as completed and return rewards"""
	var objective = objectives.get(objective_id)
	if not objective or objective.status != ObjectiveStatus.AVAILABLE:
		return false
	
	objective.status = ObjectiveStatus.COMPLETED
	objective.completion_time = Time.get_unix_time_from_system()
	
	# Unlock dependent objectives
	unlock_dependent_objectives(objective_id)
	
	return true

func unlock_dependent_objectives(completed_objective_id: String):
	"""Unlock objectives that depend on the completed objective"""
	match completed_objective_id:
		"roster_expansion_1":
			roster_expansion_2.is_visible = true
		"roster_expansion_2":
			roster_expansion_3.is_visible = true
		"equipment_system_unlock":
			armory_unlock.is_visible = true
		"promotion_system_unlock":
			first_character_promoted.is_visible = true

func get_available_objectives() -> Array[ObjectiveData]:
	"""Get all objectives that are available for completion"""
	var available: Array[ObjectiveData] = []
	for objective in objectives.values():
		if objective.status == ObjectiveStatus.AVAILABLE and objective.is_visible:
			available.append(objective)
	return available

func get_visible_objectives() -> Array[ObjectiveData]:
	"""Get all objectives that should be shown in the UI"""
	var visible: Array[ObjectiveData] = []
	for objective in objectives.values():
		if objective.is_visible:
			visible.append(objective)
	return visible

func get_completed_objectives() -> Array[ObjectiveData]:
	"""Get all completed objectives"""
	var completed: Array[ObjectiveData] = []
	for objective in objectives.values():
		if objective.status == ObjectiveStatus.COMPLETED:
			completed.append(objective)
	return completed

func get_objective_by_id(objective_id: String) -> ObjectiveData:
	"""Get a specific objective by its ID"""
	return objectives.get(objective_id, null)

func is_objective_completed(objective_id: String) -> bool:
	"""Check if a specific objective is completed"""
	var objective = objectives.get(objective_id)
	return objective != null and objective.status == ObjectiveStatus.COMPLETED

func is_system_unlocked(system_name: String) -> bool:
	"""Check if a specific system is unlocked through objectives"""
	for objective in objectives.values():
		if objective.status == ObjectiveStatus.COMPLETED:
			var rewards = objective.rewards
			if rewards.has("unlock_system") and rewards.unlock_system == system_name:
				return true
		elif objective.status == ObjectiveStatus.AVAILABLE:
			var rewards = objective.rewards
			if rewards.has("unlock_system") and rewards.unlock_system == system_name:
				return true
	return false

func is_room_unlocked(room_name: String) -> bool:
	"""Check if a specific room is unlocked through objectives"""
	for objective in objectives.values():
		if objective.status == ObjectiveStatus.COMPLETED:
			var rewards = objective.rewards
			if rewards.has("unlock_room") and rewards.unlock_room == room_name:
				return true
	return false

#endregion

#region Serialization
func serialize() -> Dictionary:
	"""Serialize objectives data for saving"""
	var data = {}
	for objective_id in objectives.keys():
		var objective = objectives[objective_id]
		data[objective_id] = {
			"status": objective.status,
			"completion_time": objective.completion_time,
			"is_visible": objective.is_visible
		}
	return data

func deserialize(data: Dictionary):
	"""Deserialize objectives data from save"""
	for objective_id in data.keys():
		var objective = objectives.get(objective_id)
		if objective:
			var obj_data = data[objective_id]
			objective.status = obj_data.get("status", ObjectiveStatus.LOCKED)
			objective.completion_time = obj_data.get("completion_time", 0.0)
			objective.is_visible = obj_data.get("is_visible", false)
#endregion
