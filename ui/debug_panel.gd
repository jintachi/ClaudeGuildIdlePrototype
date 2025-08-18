extends Panel

var scene_name: String = "DEBUG"

@export var debug_recruit_hub : VBoxContainer
@export var debug_resources : VBoxContainer
@export var debug_quest_hub : VBoxContainer
@export var debug_guild_roster :VBoxContainer

func set_scene_name(name: String) -> void:
	scene_name = name
	_update_debug_tools_visibility()

func _ready() -> void:
	_debug_sync_resource_fields()
	_update_debug_tools_visibility()

func _update_debug_tools_visibility() -> void:
	# Hide all debug sections by default
	debug_recruit_hub.visible = false
	debug_resources.visible = false
	debug_quest_hub.visible = false
	debug_guild_roster.visible = false

	match scene_name:
		"Guild Hall":
			debug_resources.visible = true
			_debug_sync_resource_fields()
		"Guild Roster":
			debug_guild_roster.visible = true
			debug_resources.visible = true
			_debug_sync_resource_fields()
		"Recruitment Hub":
			debug_recruit_hub.visible = true
			debug_resources.visible = true
			_debug_sync_resource_fields()
		"Quest Hub":
			debug_quest_hub.visible = true
			#_debug_populate_rank_and_type_options()
		_:
			pass # Show nothing or a default

func _debug_sync_resource_fields():
	if not is_instance_valid(GuildManager):
		return	
	$VBox/DebugResources/ResourcesGrid/InfluenceEdit.text = str(GuildManager.influence)
	$VBox/DebugResources/ResourcesGrid/GoldEdit.text = str(GuildManager.gold)
	$VBox/DebugResources/ResourcesGrid/FoodEdit.text = str(GuildManager.food)
	$VBox/DebugResources/ResourcesGrid/MaterialsEdit.text = str(GuildManager.building_materials)
	$VBox/DebugResources/ResourcesGrid/ArmorEdit.text = str(GuildManager.armor_pieces)
	$VBox/DebugResources/ResourcesGrid/WeaponsEdit.text = str(GuildManager.weapons)
