## This is where all the main and common signals are located, otherwise referred to as a SignalBus
@warning_ignore_start("unused_signal")
extends Node
#region Quest
signal quest_completed(quest:Quest)
#endregion
#region Scene Transition
signal new_game
signal game_loaded
signal scene_transition(to:StringName,scene_obj:Node)
#endregion
#region Roster Related
signal generate_recruits
signal generate_random_recruit
signal rotate_recruits
signal character_recruited
#endregion
#region Resources
signal spend_resources(resources:Dictionary)
signal add_resources(resources:Dictionary)
#endregion
#region UI
signal update_ui
#endregion
@warning_ignore_restore("unused_signal")
