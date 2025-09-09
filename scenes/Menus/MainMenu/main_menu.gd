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
	# Show save slot selection for new game
	_show_save_slot_selection("new")

func _on_load_game_pressed():
	# Show save slot selection for loading
	_show_save_slot_selection("load")

func _initialize_new_game():
	# Initialize the GuildManager with new game settings
	# This will reset all resources and create starter content
	if GuildManager:
		GuildManager.clear_save_file()  # Clear any existing save data
		GuildManager.initialize_game()  # Initialize new game
		print("New game initialized!")
	else:
		print("Warning: GuildManager not available")

func _show_save_slot_selection(action: String):
	"""Show the save slot selection screen"""
	var save_slot_scene = preload("res://scenes/Menus/MainMenu/SaveSlotSelection.tscn")
	var save_slot_instance = save_slot_scene.instantiate()
	
	# Store the intended action and connect to slot selection signal
	save_slot_instance.intended_action = action
	save_slot_instance.slot_selected.connect(_on_slot_selected)
	
	# Add to scene tree
	add_child(save_slot_instance)
	
	# Hide main menu buttons
	$VBoxContainer.visible = false

func _on_slot_selected(slot: int, action: String):
	"""Handle slot selection from save slot screen"""
	if action == "load":
		_load_game_from_slot(slot)
	elif action == "new":
		_initialize_new_game_in_slot(slot)
	
	# Remove save slot selection screen
	for child in get_children():
		if child.has_method("refresh_slot_info"):  # Save slot selection screen
			child.queue_free()
	
	# Show main menu buttons again
	$VBoxContainer.visible = true

func _load_game_from_slot(slot: int):
	"""Load game from a specific slot"""
	if GuildManager:
		GuildManager.load_game_from_slot(slot)
		print("Game loaded from slot ", slot)
		# Initialize the game after loading
		GuildManager.initialize_game()
		# Load the Guild Hall scene
		get_tree().change_scene_to_file("res://scenes/Guild_Hall.tscn")
	else:
		print("Warning: GuildManager not available")

func _initialize_new_game_in_slot(slot: int):
	"""Initialize a new game in a specific slot"""
	if GuildManager:
		GuildManager.current_save_slot = slot
		GuildManager.clear_save_file()  # Clear the selected slot
		GuildManager.initialize_game()  # Initialize new game
		print("New game initialized in slot ", slot)
		# Load the Guild Hall scene
		get_tree().change_scene_to_file("res://scenes/Guild_Hall.tscn")
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
