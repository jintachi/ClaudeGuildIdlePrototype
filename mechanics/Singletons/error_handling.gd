extends Node

## Centralized error and popup handling for the Guild Hall
## Manages all dialog boxes, confirmations, and error messages

static func show_error_popup(message: String, parent: Node):
	var popup = AcceptDialog.new()
	parent.add_child(popup)
	popup.dialog_text = message
	popup.title = "Error"
	popup.popup_centered()

static func show_quest_completion_popup(quest: Quest, parent: Node):
	var popup = AcceptDialog.new()
	parent.add_child(popup)
	
	var party_info = quest.get_party_display_info()
	var success_count = 0
	var party_text = ""
	
	for member in party_info:
		party_text += "%s: %s\n" % [member.name, "SUCCESS" if member.status == "✓" else "FAILED"]
		if member.status == "✓":
			success_count += 1
	
	## TODO: Add a series of tabs or a cleaner display for which units got EXP, and any levelup gains, maybe a click-through series of tabs for each character.
	for _char in quest.assigned_party:
		_char.is_on_quest = false
	
	var success_rate = float(success_count) / party_info.size()
	var result_text = "QUEST COMPLETED!\n\n"
	result_text += quest.quest_name + "\n\n"
	result_text += "Party Results:\n" + party_text + "\n"
	result_text += "Overall Success: %.0f%%\n\n" % (success_rate * 100)
	result_text += "Rewards: " + quest.get_rewards_text()
	
	popup.dialog_text = result_text
	popup.title = "Quest Results"
	popup.popup_centered()

static func show_emergency_quest_popup(requirements: Dictionary, parent: Node):
	var popup = AcceptDialog.new()
	parent.add_child(popup)
	
	popup.dialog_text = "EMERGENCY QUEST AVAILABLE!\n\n" + requirements.name + "\n\n" + requirements.description + "\n\nReward: " + requirements.unlock_description
	popup.title = "Emergency Quest"
	popup.popup_centered()

static func show_new_game_confirmation(guild_manager: GuildManager, parent: Node):
	var confirm = ConfirmationDialog.new()
	parent.add_child(confirm)
	confirm.dialog_text = "Are you sure you want to start a new game? This will delete your current save file."
	confirm.title = "New Game"
	confirm.confirmed.connect(func(): 
		guild_manager.clear_save_file()
		parent.update_ui()
		print("New game started!")
	)
	confirm.popup_centered()
