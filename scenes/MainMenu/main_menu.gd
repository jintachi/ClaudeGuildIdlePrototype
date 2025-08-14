extends Node

@export var guild_hall : PackedScene = preload("res://scenes/WorldMap/GuildHall/Guild_Hall.tscn")

var save_file_path := "res://Save_Data/guild_save.json"

@export var new_game_button : Button 
@export var load_game_button : Button
@export var options_button : Button
@export var quit_button : Button

var warning_dialog : ConfirmationDialog = null

func _ready():
	# Check for save file
	if not FileAccess.file_exists(save_file_path):
		load_game_button.disabled = true
		load_game_button.modulate = Color(0.5, 0.5, 0.5)
	else:
		load_game_button.disabled = false
		load_game_button.modulate = Color(1, 1, 1)

	# Connect signals
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Add warning dialog for New Game
	warning_dialog = ConfirmationDialog.new()
	warning_dialog.dialog_text = "Starting a new game will overwrite your current save. Continue?"
	warning_dialog.get_ok_button().text = "Overwrite"
	warning_dialog.get_cancel_button().text = "Cancel"
	warning_dialog.confirmed.connect(_on_new_game_confirmed)
	add_child(warning_dialog)

func _on_new_game_pressed():
	
	if FileAccess.file_exists(save_file_path):
		warning_dialog.popup_centered()
	else:
		_start_new_game()

func _on_new_game_confirmed():
	# Overwrite save file by clearing it
	if Engine.has_singleton("SaveManager"):
		var save_manager = Engine.get_singleton("SaveManager")
		if save_manager.has_method("clear_save_file"):
			# You may need to pass a GuildManager instance here if required
			save_manager.clear_save_file(null)
	_start_new_game()

func _start_new_game():
	GameGlobalEvents.emit_signal("new_game",true)
	get_tree().change_scene_to_packed(guild_hall)

func _on_load_game_pressed():
	# Load save data before transitioning
	if Engine.has_singleton("SaveManager"):
		var save_manager = Engine.get_singleton("SaveManager")
		if save_manager.has_method("load_game"):
			# You may need to pass a GuildManager instance here if required
			save_manager.load_game(null)
	get_tree().change_scene_to_packed(guild_hall)

func _on_options_pressed():
	# Placeholder: Show a message or transition to options scene
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Options menu coming soon!"
	add_child(dialog)
	dialog.popup_centered()

func _on_quit_pressed():
	get_tree().quit()
