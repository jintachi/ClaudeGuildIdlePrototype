extends Control

#region Variables
var current_character: Character = null
#endregion

#region Node References
# Main UI Elements
@export var character_name_label: Label
@export var tab_container: TabContainer

# Statistics Tab - Basic Information
@export var class_info_label: Label
@export var level_info_label: Label

# Statistics Tab - Core Stats
@export var health_stat_label: Label
@export var defense_stat_label: Label
@export var mana_stat_label: Label
@export var spell_power_stat_label: Label
@export var attack_power_stat_label: Label
@export var movement_speed_stat_label: Label
@export var luck_stat_label: Label

# Statistics Tab - Sub-stats
@export var gathering_stat_label: Label
@export var hunting_stat_label: Label
@export var diplomacy_stat_label: Label
@export var caravan_stat_label: Label
@export var escort_stat_label: Label
@export var stealth_stat_label: Label
@export var odd_jobs_stat_label: Label

#region History Tab
# History Tab - Quest History
@export var quests_completed_label: Label
@export var quests_failed_label: Label
@export var success_rate_label: Label

# History Tab - Rewards History
@export var total_gold_label: Label
@export var total_experience_label: Label
@export var total_influence_label: Label

# History Tab - Injury History
@export var total_injuries_label: Label

# History Tab - Promotion History
@export var promotions_attempted_label: Label
@export var promotions_succeeded_label: Label
@export var promotions_failed_label: Label
#endregion

#region Equipment Tab

@export var equipment_vbox : VBoxContainer
@export var equipment_label : Label
@export var equipment_descrip : Label

#endregion
#endregion

#region Initialization
func _ready():
	hide()  # Start hidden
	
	# Apply color modulation to equipment placeholder elements
	equipment_label.modulate = Color(0.7, 0.7, 0.7)
	equipment_descrip.modulate = Color(0.6, 0.6, 0.6)
#endregion

#region Public Functions
func inspect_character(character: Character):
	"""Display the inspection panel for a specific character"""
	current_character = character
	update_display()
	show()
#endregion

#region Display Update Functions
func update_display():
	"""Update all display elements with current character data"""
	if not current_character:
		return
	
	# Update name
	character_name_label.text = current_character.character_name
	
	# Update all sections
	update_basic_info()
	update_statistics()
	update_history()

func update_basic_info():
	"""Update basic character information"""
	var stars = "★".repeat(current_character.quality)
	class_info_label.text = "Class: %s | Quality: %s | Rank: %s" % [
		current_character.get_class_name(),
		stars,
		current_character.get_rank_name()
	]
	
	var exp_needed = current_character.get_experience_needed_for_next_level()
	level_info_label.text = "Level: %d | Experience: %d/%d" % [
		current_character.level,
		current_character.experience,
		exp_needed
	]

func update_statistics():
	"""Update all statistics displays"""
	# Core stats
	health_stat_label.text = "Health: %d" % current_character.health
	defense_stat_label.text = "Defense: %d" % current_character.defense
	mana_stat_label.text = "Mana: %d" % current_character.mana
	spell_power_stat_label.text = "Spell Power: %d" % current_character.spell_power
	attack_power_stat_label.text = "Attack Power: %d" % current_character.attack_power
	movement_speed_stat_label.text = "Movement Speed: %d" % current_character.movement_speed
	luck_stat_label.text = "Luck: %d" % current_character.luck
	
	# Sub-stats
	gathering_stat_label.text = "Gathering: %d" % current_character.gathering
	hunting_stat_label.text = "Hunting & Trapping: %d" % current_character.hunting_trapping
	diplomacy_stat_label.text = "Diplomacy: %d" % current_character.diplomacy
	caravan_stat_label.text = "Caravan Guarding: %d" % current_character.caravan_guarding
	escort_stat_label.text = "Escorting: %d" % current_character.escorting
	stealth_stat_label.text = "Stealth: %d" % current_character.stealth
	odd_jobs_stat_label.text = "Odd Jobs: %d" % current_character.odd_jobs

func update_history():
	"""Update all history displays"""
	# Quest history
	quests_completed_label.text = "Quests Completed: %d" % current_character.quests_completed
	quests_failed_label.text = "Quests Failed: %d" % current_character.quests_failed
	
	var total_quests = current_character.quests_completed + current_character.quests_failed
	var success_rate = 0
	if total_quests > 0:
		success_rate = int((float(current_character.quests_completed) / float(total_quests)) * 100)
	success_rate_label.text = "Success Rate: %d%%" % success_rate
	
	# Rewards history
	total_gold_label.text = "Total Gold Earned: %d" % current_character.total_gold_earned
	total_experience_label.text = "Total Experience Earned: %d" % current_character.total_experience_earned
	total_influence_label.text = "Total Influence Earned: %d" % current_character.total_influence_earned
	
	# Injury history
	total_injuries_label.text = "Total Injuries Sustained: %d" % current_character.total_injuries_sustained
	
	# Promotion history
	promotions_attempted_label.text = "Promotions Attempted: %d" % current_character.promotions_attempted
	promotions_succeeded_label.text = "Promotions Succeeded: %d" % current_character.promotions_succeeded
	promotions_failed_label.text = "Promotions Failed: %d" % current_character.promotions_failed
#endregion
