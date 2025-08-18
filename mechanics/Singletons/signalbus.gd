extends Node

## Centralized Signal Bus
## Contains all signals organized by functional areas

@warning_ignore_start("unused_signal")

#region Main Menu Signals
signal new_game
signal load_game
signal quit_game
#endregion

#region Guild Hall Signals
signal guild_hall_loaded
signal update_ui_requested
signal scene_changed(scene_name: StringName)
#endregion

#region Character Management Signals
signal character_recruited(character: Character)
signal character_promoted(character: Character)
signal character_injured(character: Character)
signal character_healed(character: Character)
#endregion

#region Quest Management Signals
signal quest_started(quest: Quest)
signal quest_completed(quest: Quest)
signal quest_failed(quest: Quest)
signal emergency_quest_available(requirements: Dictionary)
signal party_assembled(party: Array[Character])
#endregion

#region Resource Management Signals
signal resources_updated(resources: Dictionary)
signal resource_spent(cost: Dictionary)
signal resource_gained(rewards: Dictionary)
#endregion

#region Recruitment Signals
signal recruits_refreshed
signal recruit_selected(character: Character)
signal recruitment_cost_checked(character: Character, can_afford: bool)
#endregion

#region Save/Load Signals
signal game_saved
signal game_loaded
signal save_file_cleared
signal auto_save_triggered
#endregion

#region UI Interaction Signals
signal button_pressed(button_name: String)
signal dialog_confirmed(dialog_type: String)
signal scene_transition_requested(scene_path: String)
#endregion

@warning_ignore_restore("unused_signal")
