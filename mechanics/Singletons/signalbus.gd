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
signal character_status_changed(character: Character)
#endregion

#region Quest Management Signals
signal quest_started(quest: Quest)
signal quest_completed(quest: Quest)
signal quest_finalized(quest: Quest)
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

#region Options Menu Signals
signal options_menu_opened
signal options_menu_closed
signal resolution_changed(resolution: Vector2i)
signal resolution_confirmation_needed(resolution: Vector2i)
signal resolution_confirmed(resolution: Vector2i)
signal resolution_reverted(resolution: Vector2i)
signal settings_applied
signal settings_reset_to_defaults
#endregion

#region UI Scaling Signals
signal ui_scaling_changed(scale_factor: float, ui_scale_factor: float)
signal scaling_mode_changed(mode: int)
signal ui_scale_changed
#endregion

#region Input Management Signals
signal keybinding_changed(action_name: String, binding)
signal keybindings_reset
signal action_executed(action_name: String)
signal scene_navigation_requested(from_scene: String, to_scene: String)
#endregion

#region Notification System Signals
signal notification_requested(type: String, title: String, message: String, icon: Texture2D)
signal quest_started_notification(quest_name: String)
signal quest_completed_notification(quest_name: String)
signal character_recruited_notification(character_name: String)
signal resource_gained_notification(resource_type: String, amount: int)
signal character_injured_notification(character_name: String, injury_type: String)
signal character_leveled_up(character: Character, stat_gains: Dictionary)
#endregion

@warning_ignore_restore("unused_signal")
