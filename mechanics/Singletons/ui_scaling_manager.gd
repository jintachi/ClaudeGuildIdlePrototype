extends Node

## UI Scaling Manager
## Handles automatic UI scaling based on resolution changes

# Base resolution for UI design (what the UI was designed for)
const BASE_RESOLUTION = Vector2i(1920, 1080)

# Current scaling factors
var scale_factor: float = 1.0
var ui_scale_factor: float = 1.0

# Scaling modes
enum ScalingMode {
	PIXEL_PERFECT,    # No scaling, maintains exact pixel sizes
	PROPORTIONAL,     # Scale proportionally to resolution
	SMART_SCALE,      # Intelligent scaling with breakpoints
	ADAPTIVE          # Different scaling for different UI elements
}

var current_scaling_mode: ScalingMode = ScalingMode.SMART_SCALE

# Scaling breakpoints for smart scaling
var scaling_breakpoints = {
	Vector2i(1280, 720): 0.75,    # 720p - smaller scale
	Vector2i(1366, 768): 0.8,     # Common laptop resolution
	Vector2i(1600, 900): 0.9,     # 900p
	Vector2i(1920, 1080): 1.0,    # 1080p - base scale
	Vector2i(2560, 1440): 1.25,   # 1440p - larger scale
	Vector2i(3840, 2160): 1.5     # 4K - much larger scale
}

func _ready():
	# Connect to resolution changes
	if SignalBus:
		SignalBus.resolution_changed.connect(_on_resolution_changed)
		SignalBus.resolution_confirmed.connect(_on_resolution_confirmed)
	
	# Apply initial scaling
	_update_scaling()

func _on_resolution_changed(resolution: Vector2i):
	"""Handle resolution change and update scaling"""
	_update_scaling_for_resolution(resolution)

func _on_resolution_confirmed(resolution: Vector2i):
	"""Handle confirmed resolution change"""
	_update_scaling_for_resolution(resolution)

func _update_scaling():
	"""Update scaling based on current resolution"""
	var current_resolution = get_current_resolution()
	_update_scaling_for_resolution(current_resolution)

func _update_scaling_for_resolution(resolution: Vector2i):
	"""Update scaling for a specific resolution"""
	var new_scale_factor = calculate_scale_factor(resolution)
	
	if abs(new_scale_factor - scale_factor) > 0.01:  # Only update if significant change
		scale_factor = new_scale_factor
		ui_scale_factor = calculate_ui_scale_factor(resolution)
		
		# Apply scaling to current scene
		apply_scaling_to_current_scene()
		
		# Emit signal for other systems
		if SignalBus:
			SignalBus.ui_scaling_changed.emit(scale_factor, ui_scale_factor)
		
		print("UI scaling updated - Scale: %.2f, UI Scale: %.2f" % [scale_factor, ui_scale_factor])

func calculate_scale_factor(resolution: Vector2i) -> float:
	"""Calculate the main scale factor based on resolution and mode"""
	match current_scaling_mode:
		ScalingMode.PIXEL_PERFECT:
			return 1.0
		
		ScalingMode.PROPORTIONAL:
			var width_ratio = float(resolution.x) / float(BASE_RESOLUTION.x)
			var height_ratio = float(resolution.y) / float(BASE_RESOLUTION.y)
			return min(width_ratio, height_ratio)
		
		ScalingMode.SMART_SCALE:
			return get_smart_scale_factor(resolution)
		
		ScalingMode.ADAPTIVE:
			return get_adaptive_scale_factor(resolution)
		
		_:
			return 1.0

func calculate_ui_scale_factor(resolution: Vector2i) -> float:
	"""Calculate UI-specific scale factor (for fonts, icons, etc.)"""
	# UI elements should scale more conservatively than layout
	var base_scale = calculate_scale_factor(resolution)
	
	# Apply curve to make UI scaling less aggressive
	if base_scale > 1.0:
		# For higher resolutions, scale UI less aggressively
		return 1.0 + (base_scale - 1.0) * 0.7
	else:
		# For lower resolutions, scale UI more aggressively to maintain readability
		return 1.0 + (base_scale - 1.0) * 1.2

func get_smart_scale_factor(resolution: Vector2i) -> float:
	"""Get scale factor using smart breakpoints"""
	# Find exact match first
	if resolution in scaling_breakpoints:
		return scaling_breakpoints[resolution]
	
	# Find closest resolution for interpolation
	var closest_resolution = Vector2i(1920, 1080)
	var closest_distance = INF
	
	for breakpoint_res in scaling_breakpoints.keys():
		var distance = resolution.distance_to(Vector2(breakpoint_res))
		if distance < closest_distance:
			closest_distance = distance
			closest_resolution = breakpoint_res
	
	return scaling_breakpoints[closest_resolution]

func get_adaptive_scale_factor(resolution: Vector2i) -> float:
	"""Get adaptive scale factor based on screen density"""
	var width_ratio = float(resolution.x) / float(BASE_RESOLUTION.x)
	var height_ratio = float(resolution.y) / float(BASE_RESOLUTION.y)
	var area_ratio = (width_ratio * height_ratio)
	
	# Use logarithmic scaling for better distribution
	return 1.0 + log(area_ratio) * 0.3

func apply_scaling_to_current_scene():
	"""Apply scaling to the current scene"""
	var current_scene = get_tree().current_scene
	if current_scene:
		# Check if scene already has viewport scaling
		var viewport_scaler = find_viewport_scaler(current_scene)
		if viewport_scaler:
			# Update existing viewport scaler
			viewport_scaler.update_scaling()
		else:
			# Apply direct scaling to scene
			apply_scaling_to_node(current_scene)

func find_viewport_scaler(node: Node) -> ViewportScaler:
	"""Find a ViewportScaler in the node tree"""
	if node is ViewportScaler:
		return node as ViewportScaler
	
	for child in node.get_children():
		var scaler = find_viewport_scaler(child)
		if scaler:
			return scaler
	
	return null

func apply_scaling_to_node(node: Node):
	"""Recursively apply scaling to a node and its children"""
	if node is Control:
		apply_control_scaling(node)
	elif node is CanvasLayer:
		apply_canvas_layer_scaling(node)
	
	# Recursively apply to children
	for child in node.get_children():
		apply_scaling_to_node(child)

func apply_control_scaling(control: Control):
	"""Apply scaling to a Control node"""
	# Update theme scale if the control has a theme
	if control.theme:
		apply_theme_scaling(control.theme)
	
	# Scale font sizes
	scale_control_fonts(control)
	
	# Scale custom minimum sizes
	if control.custom_minimum_size != Vector2.ZERO:
		control.custom_minimum_size *= scale_factor
	
	# Handle specific control types
	if control is Panel or control is Button:
		scale_panel_margins(control)

func apply_canvas_layer_scaling(canvas_layer: CanvasLayer):
	"""Apply scaling to a CanvasLayer"""
	canvas_layer.scale = Vector2(scale_factor, scale_factor)

func apply_theme_scaling(theme: Theme):
	"""Apply scaling to theme elements"""
	# Scale font sizes
	var font_size = theme.get_font_size("font_size", "")
	if font_size > 0:
		theme.set_font_size("font_size", "", int(font_size * ui_scale_factor))
	
	# Scale various theme constants
	scale_theme_constants(theme)

func scale_theme_constants(theme: Theme):
	"""Scale theme constants like margins, separations, etc."""
	var types_to_scale = ["Button", "Panel", "VBoxContainer", "HBoxContainer", "MarginContainer"]
	var properties_to_scale = ["separation", "margin_left", "margin_right", "margin_top", "margin_bottom"]
	
	for type_name in types_to_scale:
		for property in properties_to_scale:
			if theme.has_constant(property, type_name):
				var original_value = theme.get_constant(property, type_name)
				theme.set_constant(property, type_name, int(original_value * scale_factor))

func scale_control_fonts(control: Control):
	"""Scale font sizes for a specific control"""
	# Handle different control types that might have custom font sizes
	if control.has_theme_font_size_override("font_size"):
		var current_size = control.get_theme_font_size("font_size")
		control.add_theme_font_size_override("font_size", int(current_size * ui_scale_factor))

func scale_panel_margins(_control: Control):
	"""Scale margins for panels and buttons"""
	# This would handle StyleBoxFlat margins if needed
	# TODO: Implement StyleBoxFlat margin scaling
	pass

func get_current_resolution() -> Vector2i:
	"""Get the current window resolution"""
	return get_window().size

func set_scaling_mode(mode: ScalingMode):
	"""Change the scaling mode"""
	if mode != current_scaling_mode:
		current_scaling_mode = mode
		_update_scaling()
		
		# Save to settings
		if SettingsManager:
			if not "ui" in SettingsManager.settings_data:
				SettingsManager.settings_data["ui"] = {}
			SettingsManager.settings_data.ui["scaling_mode"] = mode
			SettingsManager.save_settings()

func get_scale_factor() -> float:
	"""Get the current scale factor"""
	return scale_factor

func get_ui_scale_factor() -> float:
	"""Get the current UI scale factor"""
	return ui_scale_factor

func refresh_current_scene():
	"""Force refresh scaling for the current scene"""
	apply_scaling_to_current_scene()

# Utility functions for manual scaling
func scale_size(size: Vector2) -> Vector2:
	"""Scale a Vector2 size"""
	return size * scale_factor

func scale_position(pos: Vector2) -> Vector2:
	"""Scale a Vector2 position"""
	return pos * scale_factor

func scale_font_size(font_size: int) -> int:
	"""Scale a font size"""
	return int(font_size * ui_scale_factor)

func apply_global_theme_scaling():
	"""Apply scaling to the global theme"""
	var default_theme = ThemeDB.get_default_theme()
	if default_theme:
		apply_theme_scaling(default_theme)

func enhance_scene_scaling(scene: Node):
	"""Enhanced scaling for specific scene types"""
	# Special handling for Guild Hall and other game scenes
	if scene.name.to_lower().contains("guild"):
		apply_guild_hall_scaling(scene)
	else:
		apply_scaling_to_node(scene)

func apply_guild_hall_scaling(scene: Node):
	"""Special scaling for Guild Hall scene"""
	# Look for hardcoded positioning and convert to responsive
	for child in scene.get_children():
		if child is Control:
			fix_hardcoded_positioning(child)
	
	# Apply general scaling
	apply_scaling_to_node(scene)

func fix_hardcoded_positioning(control: Control):
	"""Fix hardcoded positioning in controls"""
	# Convert absolute positioning to anchored positioning where possible
	if control.layout_mode == 0 and control.position != Vector2.ZERO:
		var parent_size = Vector2(1920, 1080)  # Reference size
		if control.get_parent() is Control:
			parent_size = (control.get_parent() as Control).size
			if parent_size == Vector2.ZERO:
				parent_size = Vector2(1920, 1080)
		
		# Calculate relative position
		var relative_pos = control.position / parent_size
		
		# Set appropriate anchors based on position
		if relative_pos.x < 0.1:
			control.anchor_left = 0.0
			control.anchor_right = 0.0
		elif relative_pos.x > 0.9:
			control.anchor_left = 1.0
			control.anchor_right = 1.0
		else:
			control.anchor_left = relative_pos.x
			control.anchor_right = relative_pos.x
		
		if relative_pos.y < 0.1:
			control.anchor_top = 0.0
			control.anchor_bottom = 0.0
		elif relative_pos.y > 0.9:
			control.anchor_top = 1.0
			control.anchor_bottom = 1.0
		else:
			control.anchor_top = relative_pos.y
			control.anchor_bottom = relative_pos.y
	
	# Recursively fix children
	for child in control.get_children():
		if child is Control:
			fix_hardcoded_positioning(child)
