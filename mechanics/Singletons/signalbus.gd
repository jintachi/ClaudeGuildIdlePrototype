extends Node

## Centralized Signal Bus
## Contains all signals organized by functional areas

@warning_ignore_start("unused_signal")

#region Main Menu Signals
# Main menu signals removed - were unused
#endregion

#region Guild Hall Signals
# Guild hall signals removed - were unused
#endregion

#region Character Management Signals
signal character_recruited(character: Character)
signal character_promoted(character: Character)
signal character_injured(character: Character)
# signal character_healed(character: Character) - removed, was unused
signal character_status_changed(character: Character)
#endregion

#region Quest Management Signals
signal quest_started(quest: Quest)
signal quest_completed(quest: Quest)
signal quest_finalized(quest: Quest)
signal quest_card_selected(card:CompactQuestCard)
signal emergency_quest_available(requirements: Dictionary)
# signal quest_failed(quest: Quest) - removed, was unused  
# signal party_assembled(party: Array[Character]) - removed, was unused
#endregion

#region Resource Management Signals
# Resource management signals removed - were unused
#endregion

#region Recruitment Signals
# Recruitment signals removed - were unused
#endregion

#region Save/Load Signals
signal game_saved
signal game_loaded
# signal save_file_cleared - removed, was unused
# signal auto_save_triggered - removed, was unused
#endregion

#region UI Interaction Signals
# UI interaction signals removed - were unused
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
# signal scaling_mode_changed(mode: int) - removed, was unused
signal ui_scale_changed
#endregion

#region Input Management Signals
signal keybinding_changed(action_name: String, binding)
signal keybindings_reset
# signal action_executed(action_name: String) - removed, was unused
# signal scene_navigation_requested(from_scene: String, to_scene: String) - removed, was unused
signal map_key_pressed
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
