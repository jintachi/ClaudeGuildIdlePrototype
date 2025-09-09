extends Node

## Centralized Signal Bus
## Contains all signals organized by functional areas

@warning_ignore_start("unused_signal")

#region Game State Signals
signal game_ready()  # Emitted when game is fully initialized and ready to play
signal game_loading_started()  # Emitted when game loading begins
signal game_loading_completed()  # Emitted when game loading is finished
#endregion

#region Guild Hall Signals
# Guild hall signals removed - were unused
signal room_unlocked(room_name:String)
#endregion

#region Character Management Signals
signal character_recruited(character: Character)
signal character_promoted(character: Character)
signal character_injured(character: Character)
signal character_status_changed(character: Character)

# Character data request signals
signal request_roster_data
signal request_available_characters
signal request_characters_needing_promotion
signal request_injured_characters
signal request_character_display_data(character: Character)
signal request_recruit_display_data(character: Character)
#endregion

#region Quest Management Signals
signal quest_started(quest: Quest)
signal quest_completed(quest: Quest)
signal quest_finalized(quest: Quest)
signal quest_card_selected(card:CompactQuestCard)
signal emergency_quest_available(requirements: Dictionary)

# Quest data request signals
signal request_available_quest_cards
signal request_active_quest_cards
signal request_awaiting_quest_cards
signal request_quest_display_data(quest: Quest)
signal request_quest_validation(quest: Quest, party: Array[Character])
#endregion

#region Resource Management Signals
# Resource data request signals
signal request_guild_resources
signal request_guild_status_summary
signal request_resource_display_data
signal request_cost_calculation(cost: Dictionary)
signal request_can_afford_check(cost: Dictionary)
#endregion

#region Recruitment Signals
# Recruitment data request signals
signal request_available_recruits
signal request_recruitment_cost(character: Character)
signal request_recruit_refresh
#endregion

#region Save/Load Signals
signal game_saved
signal game_loaded
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
signal ui_scale_changed
#endregion

#region Input Management Signals
signal keybinding_changed(action_name: String, binding)
signal keybindings_reset
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
