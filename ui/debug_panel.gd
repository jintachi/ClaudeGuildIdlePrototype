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

#func _debug_populate_rank_and_type_options():
#
	#if not is_instance_valid(dbg_rank_option) or not is_instance_valid(dbg_type_option):
		#return
#
	## Ranks
	#dbg_rank_option.clear()
	#for rank_name in Quest.QuestRank.keys():
		#dbg_rank_option.add_item(rank_name)
	## Types (add "Random" at index 0)
	#dbg_type_option.clear()
	#dbg_type_option.add_item("Random")
	#for type_name in Quest.QuestType.keys():
		#dbg_type_option.add_item(type_name)
#
#func _on_debug_apply_resources():
	#var resources := {
		#"influence": int(dbg_influence_edit.text.to_int()),
		#"gold": int(dbg_gold_edit.text.to_int()),
		#"food": int(dbg_food_edit.text.to_int()),
		#"building_materials": int(dbg_materials_edit.text.to_int()),
		#"armor": int(dbg_armor_edit.text.to_int()),
		#"weapons": int(dbg_weapons_edit.text.to_int()),
	#}
	#GuildManager.debug_set_resources(resources)
#
#
#func _on_debug_free_refresh_recruits():
	#GuildManager.debug_generate_recruits()
	#update_recruitment_display()
#
#func _on_debug_generate_quest():
	#var selected_rank_index := dbg_rank_option.get_selected_id()
	#if selected_rank_index < 0:
		#selected_rank_index = 0
	## Type index: 0 is Random, else map by name
	#var selected_type_idx := dbg_type_option.get_selected()
	#var type_id := -1
	#if selected_type_idx > 0:
		#var type_name := dbg_type_option.get_item_text(selected_type_idx)
		#var keys := Quest.QuestType.keys()
		#for i in range(keys.size()):
			#if keys[i] == type_name:
				#type_id = i
				#break
	#var quest := GuildManager.debug_generate_quest(selected_rank_index, type_id)
	#print("Generated quest:", quest.quest_name)
