extends Control

## Options Menu
## Handles display settings, audio settings, and other game preferences

@export var resolution_dropdown : OptionButton
@export var fullscreen_checkbox : CheckBox
@export var vsync_checkbox : CheckBox
@export var apply_button : Button
@export var reset_button : Button
@export var back_button : Button

var pending_changes = {}
var confirmation_dialog: AcceptDialog
var countdown_timer: Timer
var countdown_seconds: int = 10

func _ready():
	# Assign references if not set in editor
	if not resolution_dropdown:
		resolution_dropdown = $CenterContainer/VBoxContainer/SettingsContainer/DisplaySection/ResolutionContainer/ResolutionDropdown
	if not fullscreen_checkbox:
		fullscreen_checkbox = $CenterContainer/VBoxContainer/SettingsContainer/DisplaySection/FullscreenCheckbox
	if not vsync_checkbox:
		vsync_checkbox = $CenterContainer/VBoxContainer/SettingsContainer/DisplaySection/VsyncCheckbox
	if not apply_button:
		apply_button = $CenterContainer/VBoxContainer/ButtonContainer/ApplyButton
	if not reset_button:
		reset_button = $CenterContainer/VBoxContainer/ButtonContainer/ResetButton
	if not back_button:
		back_button = $CenterContainer/VBoxContainer/ButtonContainer/BackButton
	
	# Connect signals
	if resolution_dropdown:
		resolution_dropdown.item_selected.connect(_on_resolution_selected)
	if fullscreen_checkbox:
		fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	if vsync_checkbox:
		vsync_checkbox.toggled.connect(_on_vsync_toggled)
	if apply_button:
		apply_button.pressed.connect(_on_apply_pressed)
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	# Initialize UI
	_initialize_ui()
	
	# Setup confirmation dialog system
	_setup_confirmation_dialog()
	
	# Connect to SignalBus
	if SignalBus:
		SignalBus.options_menu_opened.emit()
		SignalBus.resolution_confirmation_needed.connect(_on_resolution_confirmation_needed)
		SignalBus.resolution_confirmed.connect(_on_resolution_confirmed)
		SignalBus.resolution_reverted.connect(_on_resolution_reverted)

func _initialize_ui():
	if not is_instance_valid(get_node_or_null("/root/SettingsManager")):
		print("Warning: SettingsManager not available")
		return
	
	var settings_manager = get_node("/root/SettingsManager")
	
	# Populate resolution dropdown
	if resolution_dropdown:
		resolution_dropdown.clear()
		var resolution_strings = settings_manager.get_resolution_strings()
		for i in range(resolution_strings.size()):
			resolution_dropdown.add_item(resolution_strings[i])
		
		# Set current resolution
		var current_index = settings_manager.get_current_resolution_index()
		if current_index >= 0:
			resolution_dropdown.selected = current_index
	
	# Set current settings
	if fullscreen_checkbox:
		fullscreen_checkbox.button_pressed = settings_manager.settings_data.display.fullscreen
	if vsync_checkbox:
		vsync_checkbox.button_pressed = settings_manager.settings_data.display.vsync
	
	# Clear pending changes
	pending_changes.clear()
	_update_apply_button()

func _on_resolution_selected(index: int):
	var settings_manager = get_node_or_null("/root/SettingsManager")
	if settings_manager and index < settings_manager.available_resolutions.size():
		pending_changes["resolution"] = settings_manager.available_resolutions[index]
		_update_apply_button()

func _on_fullscreen_toggled(pressed: bool):
	pending_changes["fullscreen"] = pressed
	_update_apply_button()

func _on_vsync_toggled(pressed: bool):
	pending_changes["vsync"] = pressed
	_update_apply_button()

func _on_apply_pressed():
	var settings_manager = get_node_or_null("/root/SettingsManager")
	if not settings_manager:
		return
	
	# Apply pending changes
	if "resolution" in pending_changes:
		settings_manager.apply_resolution(pending_changes["resolution"])
		if SignalBus:
			SignalBus.resolution_changed.emit(pending_changes["resolution"])
	
	if "fullscreen" in pending_changes:
		settings_manager.apply_fullscreen(pending_changes["fullscreen"])
	
	if "vsync" in pending_changes:
		settings_manager.apply_vsync(pending_changes["vsync"])
	
	# Clear pending changes and update UI
	pending_changes.clear()
	_update_apply_button()
	
	# Signal that settings were applied
	if SignalBus:
		SignalBus.settings_applied.emit()
	
	print("Settings applied successfully")

func _on_reset_pressed():
	# Show confirmation dialog
	var confirm_dialog = ConfirmationDialog.new()
	add_child(confirm_dialog)
	confirm_dialog.dialog_text = "Reset all settings to defaults?\nThis cannot be undone."
	confirm_dialog.title = "Reset Settings"
	confirm_dialog.confirmed.connect(_reset_to_defaults)
	confirm_dialog.popup_centered()

func _reset_to_defaults():
	if SignalBus:
		SignalBus.settings_reset_to_defaults.emit()
	
	# Reinitialize UI with default values
	_initialize_ui()
	print("Settings reset to defaults")

func _on_back_pressed():
	# Emit signal and return to previous scene
	if SignalBus:
		SignalBus.options_menu_closed.emit()
	
	# Use InputManager's robust scene navigation
	if InputManager:
		InputManager.close_options_menu()
	else:
		# Fallback if InputManager is not available
		get_tree().change_scene_to_file("res://scenes/Menus/MainMenu/Main_Menu.tscn")

func _update_apply_button():
	if apply_button:
		apply_button.disabled = pending_changes.is_empty()

func _setup_confirmation_dialog():
	# Create countdown timer
	countdown_timer = Timer.new()
	countdown_timer.wait_time = 1.0
	countdown_timer.timeout.connect(_on_countdown_tick)
	add_child(countdown_timer)

func _on_resolution_confirmation_needed(resolution: Vector2i):
	# Create confirmation dialog
	confirmation_dialog = AcceptDialog.new()
	add_child(confirmation_dialog)
	
	# Setup dialog properties
	confirmation_dialog.title = "Resolution Change"
	confirmation_dialog.dialog_hide_on_ok = false
	countdown_seconds = 10
	_update_confirmation_text(resolution)
	
	# Connect signals
	confirmation_dialog.close_requested.connect(_on_resolution_cancelled_by_user)
	
	# Add custom buttons
	confirmation_dialog.ok_button_text = "Keep Changes"
	confirmation_dialog.get_ok_button().connect("pressed",_on_confirmation_custom_action.bind("keep"))
	confirmation_dialog.add_button("Revert", true, "revert")
	
	# Start countdown and show dialog
	countdown_timer.start()
	confirmation_dialog.popup_centered()
	confirmation_dialog.grab_focus()

func _update_confirmation_text(resolution: Vector2i):
	if confirmation_dialog:
		confirmation_dialog.dialog_text = "Resolution changed to %d x %d.\n\nKeep these changes?\n\nReverting in %d seconds..." % [resolution.x, resolution.y, countdown_seconds]

func _on_countdown_tick():
	countdown_seconds -= 1
	if countdown_seconds <= 0:
		# Time's up - revert changes
		countdown_timer.stop()
		_close_confirmation_dialog()
		
		var settings_manager = get_node_or_null("/root/SettingsManager")
		if settings_manager:
			settings_manager.revert_resolution_change()
	else:
		# Update countdown text
		if confirmation_dialog:
			var current_resolution = Vector2i(0, 0)
			var settings_manager = get_node_or_null("/root/SettingsManager")
			if settings_manager:
				current_resolution = settings_manager.settings_data.display.resolution
			_update_confirmation_text(current_resolution)

func _on_confirmation_custom_action(action: String):
	countdown_timer.stop()
	
	var settings_manager = get_node_or_null("/root/SettingsManager")
	if not settings_manager:
		return
	
	if action == "keep":
		settings_manager.confirm_resolution_change()
	elif action == "revert":
		settings_manager.revert_resolution_change()
	
	_close_confirmation_dialog()

func _on_resolution_cancelled_by_user():
	countdown_timer.stop()
	var settings_manager = get_node_or_null("/root/SettingsManager")
	if settings_manager:
		settings_manager.revert_resolution_change()
	_close_confirmation_dialog()

func _on_resolution_confirmed(resolution: Vector2i):
	print("Resolution confirmed: ", resolution)
	_initialize_ui()  # Refresh UI to show confirmed settings

func _on_resolution_reverted(resolution: Vector2i):
	print("Resolution reverted to: ", resolution)
	_initialize_ui()  # Refresh UI to show reverted settings

func _close_confirmation_dialog():
	if confirmation_dialog:
		confirmation_dialog.queue_free()
		confirmation_dialog = null

func _input(_event):
	# Note: ESC key handling is now managed globally by InputManager
	# This ensures consistent behavior across all scenes
	# The InputManager will call close_options_menu() when ESC is pressed
	pass
