extends Node

## Settings Manager
## Handles game settings including resolution, display mode, audio, etc.

const SETTINGS_FILE_PATH = "user://settings.cfg"

# Default settings
var settings_data = {
	"display": {
		"resolution": Vector2i(1920, 1080),
		"fullscreen": false,
		"vsync": true
	},
	"audio": {
		"master_volume": 1.0,
		"sfx_volume": 1.0,
		"music_volume": 1.0
	},
	"ui": {
		"scaling_mode": 2  # SMART_SCALE
	},
	"keybindings": {
		"options_menu": KEY_ESCAPE,
		"pause_game": KEY_SPACE,
		"quick_save": [KEY_CTRL, KEY_S],
		"quick_load": [KEY_CTRL, KEY_L],
		"toggle_fullscreen": KEY_F11,
		"screenshot": KEY_F12
	}
}

# Available resolutions
var available_resolutions = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160)
]

# Resolution confirmation variables
var previous_resolution: Vector2i
var confirmation_timer: Timer
var pending_resolution_change: bool = false

func _ready():
	load_settings()
	apply_settings()
	
	# Setup confirmation timer
	confirmation_timer = Timer.new()
	confirmation_timer.wait_time = 10.0
	confirmation_timer.one_shot = true
	confirmation_timer.timeout.connect(_on_confirmation_timeout)
	add_child(confirmation_timer)
	
	# Connect to SignalBus
	if SignalBus:
		SignalBus.resolution_changed.connect(_on_resolution_changed)
		SignalBus.settings_applied.connect(_on_settings_applied)
		SignalBus.settings_reset_to_defaults.connect(_on_settings_reset_to_defaults)

func load_settings():
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_FILE_PATH)
	
	if err != OK:
		print("Settings file not found, using defaults")
		save_settings()
		return
	
	# Load display settings
	if config.has_section("display"):
		settings_data.display.resolution = config.get_value("display", "resolution", Vector2i(1920, 1080))
		settings_data.display.fullscreen = config.get_value("display", "fullscreen", false)
		settings_data.display.vsync = config.get_value("display", "vsync", true)
	
	# Load audio settings
	if config.has_section("audio"):
		settings_data.audio.master_volume = config.get_value("audio", "master_volume", 1.0)
		settings_data.audio.sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
		settings_data.audio.music_volume = config.get_value("audio", "music_volume", 1.0)
	
	# Load UI settings
	if config.has_section("ui"):
		settings_data.ui.scaling_mode = config.get_value("ui", "scaling_mode", 2)
	
	# Load keybinding settings
	if config.has_section("keybindings"):
		for action in settings_data.keybindings.keys():
			settings_data.keybindings[action] = config.get_value("keybindings", action, settings_data.keybindings[action])

func save_settings():
	var config = ConfigFile.new()
	
	# Save display settings
	config.set_value("display", "resolution", settings_data.display.resolution)
	config.set_value("display", "fullscreen", settings_data.display.fullscreen)
	config.set_value("display", "vsync", settings_data.display.vsync)
	
	# Save audio settings
	config.set_value("audio", "master_volume", settings_data.audio.master_volume)
	config.set_value("audio", "sfx_volume", settings_data.audio.sfx_volume)
	config.set_value("audio", "music_volume", settings_data.audio.music_volume)
	
	# Save UI settings
	config.set_value("ui", "scaling_mode", settings_data.ui.scaling_mode)
	
	# Save keybinding settings
	for action in settings_data.keybindings.keys():
		config.set_value("keybindings", action, settings_data.keybindings[action])
	
	var err = config.save(SETTINGS_FILE_PATH)
	if err == OK:
		print("Settings saved successfully")
	else:
		print("Failed to save settings: ", err)

func apply_settings():
	# Apply display settings
	apply_resolution(settings_data.display.resolution)
	apply_fullscreen(settings_data.display.fullscreen)
	apply_vsync(settings_data.display.vsync)
	
	# Apply UI scaling settings
	if UIScalingManager:
		UIScalingManager.set_scaling_mode(settings_data.ui.scaling_mode)
	
	# Apply audio settings (would connect to audio buses if implemented)
	print("Applied settings: ", settings_data)

func apply_resolution(resolution: Vector2i, require_confirmation: bool = true):
	if resolution in available_resolutions:
		if require_confirmation and resolution != settings_data.display.resolution:
			# Store previous resolution for potential rollback
			previous_resolution = settings_data.display.resolution
			pending_resolution_change = true
			
			# Apply the new resolution temporarily
			get_window().size = resolution
			settings_data.display.resolution = resolution
			
			# Start confirmation timer
			confirmation_timer.start()
			
			# Signal that confirmation is needed
			if SignalBus:
				SignalBus.resolution_confirmation_needed.emit(resolution)
			
			print("Resolution changed to: ", resolution, " (awaiting confirmation)")
		else:
			# Direct application without confirmation
			get_window().size = resolution
			settings_data.display.resolution = resolution
			print("Resolution changed to: ", resolution)
	else:
		print("Invalid resolution: ", resolution)

func apply_fullscreen(enabled: bool):
	if enabled:
		get_window().mode = Window.MODE_FULLSCREEN
	else:
		get_window().mode = Window.MODE_WINDOWED
	settings_data.display.fullscreen = enabled

func apply_vsync(enabled: bool):
	if enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	settings_data.display.vsync = enabled

func get_resolution_strings() -> Array[String]:
	var strings: Array[String] = []
	for res in available_resolutions:
		strings.append(str(res.x) + " x " + str(res.y))
	return strings

func get_current_resolution_index() -> int:
	return available_resolutions.find(settings_data.display.resolution)

func _on_resolution_changed(resolution: Vector2i):
	apply_resolution(resolution)
	save_settings()

func _on_settings_applied():
	save_settings()

func _on_settings_reset_to_defaults():
	# Reset to default settings
	settings_data = {
		"display": {
			"resolution": Vector2i(1920, 1080),
			"fullscreen": false,
			"vsync": true
		},
		"audio": {
			"master_volume": 1.0,
			"sfx_volume": 1.0,
			"music_volume": 1.0
		},
		"ui": {
			"scaling_mode": 2
		},
		"keybindings": {
			"options_menu": KEY_ESCAPE,
			"pause_game": KEY_SPACE,
			"quick_save": [KEY_CTRL, KEY_S],
			"quick_load": [KEY_CTRL, KEY_L],
			"toggle_fullscreen": KEY_F11,
			"screenshot": KEY_F12
		}
	}
	apply_settings()
	save_settings()

func confirm_resolution_change():
	"""Confirm the current resolution change and save settings"""
	if pending_resolution_change:
		confirmation_timer.stop()
		pending_resolution_change = false
		save_settings()
		
		if SignalBus:
			SignalBus.resolution_confirmed.emit(settings_data.display.resolution)
		
		print("Resolution change confirmed: ", settings_data.display.resolution)

func revert_resolution_change():
	"""Revert to the previous resolution"""
	if pending_resolution_change:
		confirmation_timer.stop()
		pending_resolution_change = false
		
		# Revert to previous resolution
		get_window().size = previous_resolution
		settings_data.display.resolution = previous_resolution
		
		if SignalBus:
			SignalBus.resolution_reverted.emit(previous_resolution)
		
		print("Resolution reverted to: ", previous_resolution)

func _on_confirmation_timeout():
	"""Automatically revert resolution after timeout"""
	if pending_resolution_change:
		print("Resolution change timeout - reverting to previous resolution")
		revert_resolution_change()
