extends Control

@export var new_game : Button
@export var load_game : Button
@export var options : Button
@export var quit_game : Button

func _ready():
	# Assign button references if not set in editor
	if not new_game:
		new_game = $CenterContainer/VBoxContainer/NewGameButton
	if not load_game:
		load_game = $CenterContainer/VBoxContainer/LoadGameButton
	if not options:
		options = $CenterContainer/VBoxContainer/OptionsButton
	if not quit_game:
		quit_game = $CenterContainer/VBoxContainer/QuitGameButton
	
	# Connect button signals
	if new_game:
		new_game.pressed.connect(_on_new_game_pressed)
	if load_game:
		load_game.pressed.connect(_on_load_game_pressed)
	if options:
		options.pressed.connect(_on_options_pressed)
	if quit_game:
		quit_game.pressed.connect(_on_quit_game_pressed)

func _on_quit_game_pressed():
	# Show confirmation dialog before quitting
	var confirm_dialog = ConfirmationDialog.new()
	add_child(confirm_dialog)
	confirm_dialog.dialog_text = "Are you sure you want to quit the game?"
	confirm_dialog.title = "Quit Game"
	confirm_dialog.confirmed.connect(_quit_game)
	confirm_dialog.popup_centered()

func _on_new_game_pressed():
	# Initialize a new game with starter resources
	_initialize_new_game()
	# Load the Guild Hall scene
	get_tree().change_scene_to_file("res://scenes/Guild_Hall.tscn")

func _on_load_game_pressed():
	# Load existing game data and go to Guild Hall
	_load_existing_game()
	get_tree().change_scene_to_file("res://scenes/Guild_Hall.tscn")

func _initialize_new_game():
	# Initialize the GuildManager with new game settings
	# This will reset all resources and create starter content
	if GuildManager:
		GuildManager.clear_save_file()  # Clear any existing save data
		GuildManager.initialize_guild()  # Initialize new game
		print("New game initialized!")
	else:
		print("Warning: GuildManager not available")

func _load_existing_game():
	# Load existing game data through GuildManager
	if GuildManager:
		GuildManager.load_game()  # Load existing save file
		print("Game loaded!")
	else:
		print("Warning: GuildManager not available")

func _on_options_pressed():
	# Go to Options menu
	get_tree().change_scene_to_file("res://scenes/Menus/Options/Options_Menu.tscn")

func _quit_game():
	get_tree().quit()
