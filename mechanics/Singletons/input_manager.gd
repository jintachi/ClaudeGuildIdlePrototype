extends Node

## Input Manager
## Centralized input handling and keybinding management system

# Default keybindings
var default_keybindings = {
	"options_menu": KEY_ESCAPE,
	"pause_game": KEY_SPACE,
	"quick_save": [KEY_CTRL, KEY_S],
	"quick_load": [KEY_CTRL, KEY_L],
	"toggle_fullscreen": KEY_F11,
	"screenshot": KEY_F12
}

# Current keybindings (loaded from settings)
var current_keybindings = {}

# Input actions mapping
var action_callbacks = {}

# Scene navigation tracking
var scene_stack: Array[String] = []
var current_options_source: String = ""

func _ready():
	load_keybindings()
	setup_default_actions()
	
	# Connect to SignalBus for settings changes
	if SignalBus:
		SignalBus.settings_applied.connect(_on_settings_applied)

func _input(event):
	# Handle global input events
	handle_global_input(event)

func handle_global_input(event):
	if event is InputEventKey and event.pressed:
		# Check for keybinding matches
		for action_name in current_keybindings:
			var binding = current_keybindings[action_name]
			
			if is_key_combination_pressed(event, binding):
				execute_action(action_name)
				get_viewport().set_input_as_handled()
				break

func is_key_combination_pressed(event: InputEventKey, binding) -> bool:
	if binding is Array:
		# Multi-key combination (e.g., Ctrl+S)
		if binding.size() != 2:
			return false
		
		var modifier = binding[0]
		var key = binding[1]
		
		# Check if modifier and key match
		var modifier_pressed = false
		match modifier:
			KEY_CTRL:
				modifier_pressed = event.ctrl_pressed
			KEY_ALT:
				modifier_pressed = event.alt_pressed
			KEY_SHIFT:
				modifier_pressed = event.shift_pressed
			KEY_META:
				modifier_pressed = event.meta_pressed
		
		return modifier_pressed and event.keycode == key
	else:
		# Single key
		return event.keycode == binding and not event.ctrl_pressed and not event.alt_pressed and not event.shift_pressed and not event.meta_pressed

func execute_action(action_name: String):
	if action_name in action_callbacks:
		var callback = action_callbacks[action_name]
		if callback.is_valid():
			callback.call()
	else:
		# Default actions
		match action_name:
			"options_menu":
				open_options_menu()
			"pause_game":
				toggle_pause()
			"quick_save":
				quick_save()
			"quick_load":
				quick_load()
			"toggle_fullscreen":
				toggle_fullscreen()
			"screenshot":
				take_screenshot()

func setup_default_actions():
	# Register default action callbacks with proper callable
	register_action("options_menu", _handle_options_menu_action)

func register_action(action_name: String, callback: Callable):
	"""Register a callback for a specific action"""
	action_callbacks[action_name] = callback

func unregister_action(action_name: String):
	"""Unregister a callback for an action"""
	if action_name in action_callbacks:
		action_callbacks.erase(action_name)

func load_keybindings():
	# Load from settings or use defaults
	if SettingsManager and "keybindings" in SettingsManager.settings_data:
		current_keybindings = SettingsManager.settings_data.keybindings.duplicate()
	else:
		current_keybindings = default_keybindings.duplicate()

func save_keybindings():
	# Save keybindings to settings
	if SettingsManager:
		if not "keybindings" in SettingsManager.settings_data:
			SettingsManager.settings_data["keybindings"] = {}
		SettingsManager.settings_data.keybindings = current_keybindings.duplicate()
		SettingsManager.save_settings()

func set_keybinding(action_name: String, binding):
	"""Set a new keybinding for an action"""
	current_keybindings[action_name] = binding
	save_keybindings()
	
	if SignalBus:
		SignalBus.keybinding_changed.emit(action_name, binding)

func get_keybinding(action_name: String):
	"""Get the current keybinding for an action"""
	return current_keybindings.get(action_name, null)

func get_keybinding_string(action_name: String) -> String:
	"""Get a human-readable string for a keybinding"""
	var binding = get_keybinding(action_name)
	if not binding:
		return "Unbound"
	
	if binding is Array:
		var modifier_name = ""
		var key_name = ""
		
		match binding[0]:
			KEY_CTRL: modifier_name = "Ctrl"
			KEY_ALT: modifier_name = "Alt"
			KEY_SHIFT: modifier_name = "Shift"
			KEY_META: modifier_name = "Meta"
		
		key_name = OS.get_keycode_string(binding[1])
		return modifier_name + "+" + key_name
	else:
		return OS.get_keycode_string(binding)

func reset_keybindings_to_defaults():
	"""Reset all keybindings to their defaults"""
	current_keybindings = default_keybindings.duplicate()
	save_keybindings()
	
	if SignalBus:
		SignalBus.keybindings_reset.emit()

# Default action implementations
func _handle_options_menu_action():
	"""Handle the options menu action (ESC key)"""
	var current_scene = get_tree().current_scene
	
	# Enhanced scene detection for better reliability
	if not current_scene:
		print("Warning: No current scene available, trying alternative detection")
		current_scene = find_main_scene_node()
		
		if not current_scene:
			print("Error: Cannot find any scene node, falling back to main menu")
			open_options_menu("res://scenes/Menus/MainMenu/Main_Menu.tscn")
			return
	
	# Get current scene path safely
	var current_scene_path = ""
	if current_scene.scene_file_path:
		current_scene_path = current_scene.scene_file_path
	else:
		# Fallback: try to determine scene from node name or default
		print("Warning: Scene file path is null, using fallback detection")
		current_scene_path = get_fallback_scene_path(current_scene)
	
	print("ESC pressed - Current scene: ", current_scene_path)
	
	# If already in options, close options and return to previous scene
	if current_scene_path.ends_with("Options_Menu.tscn"):
		close_options_menu()
	else:
		# Open options menu and store current scene
		open_options_menu(current_scene_path)

func find_main_scene_node() -> Node:
	"""Try to find the main scene node when get_tree().current_scene fails"""
	# Look for common game scene names in the root
	var root = get_tree().root
	if not root:
		return null
	
	# Check direct children for known scene names
	for child in root.get_children():
		var node_name = child.name.to_lower()
		if "guild" in node_name or "hall" in node_name or "main" in node_name:
			return child
		
		# Also check if it has a scene file path
		if child.scene_file_path and not child.scene_file_path.is_empty():
			return child
	
	# If we can't find a main scene, return the last child (most likely to be the scene)
	if root.get_child_count() > 0:
		return root.get_child(root.get_child_count() - 1)
	
	return null

func open_options_menu(previous_scene_path: String = ""):
	"""Open the options menu from a specific scene"""
	print("Opening options menu from: ", previous_scene_path)
	
	# Determine the previous scene path
	if previous_scene_path.is_empty():
		var current_scene = get_tree().current_scene
		if current_scene and current_scene.scene_file_path:
			previous_scene_path = current_scene.scene_file_path
		else:
			previous_scene_path = get_fallback_scene_path(current_scene)
	
	# Store the source scene
	current_options_source = previous_scene_path
	
	# Add to scene stack for history
	if not scene_stack.has(previous_scene_path):
		scene_stack.push_back(previous_scene_path)
	
	# Emit signal for scene navigation
	if SignalBus:
		SignalBus.scene_navigation_requested.emit(previous_scene_path, "res://scenes/Menus/Options/Options_Menu.tscn")
	
	# Navigate to options menu
	get_tree().change_scene_to_file("res://scenes/Menus/Options/Options_Menu.tscn")

func close_options_menu():
	"""Close the options menu and return to previous scene"""
	var return_scene = current_options_source
	
	# Fallback to scene stack if current_options_source is empty
	if return_scene.is_empty() and not scene_stack.is_empty():
		return_scene = scene_stack.back()
	
	# Final fallback to main menu
	if return_scene.is_empty():
		return_scene = "res://scenes/Menus/MainMenu/Main_Menu.tscn"
		print("Warning: No previous scene found, returning to main menu")
	
	print("Closing options menu, returning to: ", return_scene)
	
	# Emit signal for scene navigation
	if SignalBus:
		SignalBus.scene_navigation_requested.emit("res://scenes/Menus/Options/Options_Menu.tscn", return_scene)
	
	# Clear the current source
	current_options_source = ""
	
	# Navigate back
	get_tree().change_scene_to_file(return_scene)

func get_fallback_scene_path(scene: Node) -> String:
	"""Get a fallback scene path when scene_file_path is null"""
	if not scene:
		return "res://scenes/Menus/MainMenu/Main_Menu.tscn"
	
	# Try to determine scene from node name patterns
	var scene_name = scene.name.to_lower()
	
	if "guild" in scene_name or "hall" in scene_name:
		return "res://scenes/Guild_Hall.tscn"
	elif "main" in scene_name or "menu" in scene_name:
		return "res://scenes/Menus/MainMenu/Main_Menu.tscn"
	else:
		# Default fallback
		return "res://scenes/Menus/MainMenu/Main_Menu.tscn"

func get_current_options_source() -> String:
	"""Get the scene that opened the current options menu"""
	return current_options_source

func clear_scene_history():
	"""Clear the scene navigation history"""
	scene_stack.clear()
	current_options_source = ""

func toggle_pause():
	"""Toggle game pause state"""
	get_tree().paused = !get_tree().paused
	print("Game paused: ", get_tree().paused)

func quick_save():
	"""Perform a quick save"""
	if GuildManager:
		GuildManager.save_game()
		if SignalBus:
			SignalBus.game_saved.emit()
		print("Quick save completed!")

func quick_load():
	"""Perform a quick load"""
	if GuildManager:
		GuildManager.load_game()
		if SignalBus:
			SignalBus.game_loaded.emit()
		print("Quick load completed!")

func toggle_fullscreen():
	"""Toggle fullscreen mode"""
	if SettingsManager:
		var is_fullscreen = SettingsManager.settings_data.display.fullscreen
		SettingsManager.apply_fullscreen(!is_fullscreen)
		SettingsManager.save_settings()

func take_screenshot():
	"""Take a screenshot"""
	var screenshot = get_viewport().get_texture().get_image()
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	var filename = "user://screenshot_" + timestamp + ".png"
	screenshot.save_png(filename)
	print("Screenshot saved: ", filename)

func _on_settings_applied():
	"""Reload keybindings when settings are applied"""
	load_keybindings()
