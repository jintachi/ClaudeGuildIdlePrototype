class_name ViewportScaler
extends Control

## Viewport Scaler Component
## Automatically scales UI elements to fit within viewport bounds
## Add this as the root or high-level container for responsive scaling

# Reference viewport size (design target)
@export var reference_size: Vector2 = Vector2(1920, 1080)

# Scaling options
@export var scale_mode: ScaleMode = ScaleMode.SMART_FIT
@export var maintain_aspect_ratio: bool = true
@export var center_content: bool = true
@export var min_scale: float = 0.5
@export var max_scale: float = 3.0

enum ScaleMode {
	STRETCH,      # Stretch to fill viewport (may distort)
	FIT,          # Fit within viewport (maintains aspect ratio)
	SMART_FIT,    # Intelligent scaling based on content
	FILL,         # Fill viewport (may crop content)
	ADAPTIVE      # Adaptive scaling based on element types
}

var current_scale: float = 1.0
var viewport_size: Vector2
var scale_offset: Vector2

func _ready():
	# Set up the scaler
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Connect to viewport size changes
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	# Connect to UI scaling changes
	if SignalBus:
		SignalBus.ui_scaling_changed.connect(_on_ui_scaling_changed)
		SignalBus.resolution_confirmed.connect(_on_resolution_confirmed)
	
	# Initial scaling
	call_deferred("update_scaling")

func _on_viewport_size_changed():
	"""Handle viewport size changes"""
	update_scaling()

func _on_ui_scaling_changed(_scale_factor: float, _ui_scale_factor: float):
	"""Handle UI scaling manager changes"""
	update_scaling()

func _on_resolution_confirmed(_resolution: Vector2i):
	"""Handle confirmed resolution changes"""
	call_deferred("update_scaling")

func update_scaling():
	"""Update the scaling of this container and its children"""
	viewport_size = get_viewport().get_visible_rect().size
	
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		return # Viewport not ready yet
	
	# Calculate scale factor
	var new_scale = calculate_scale_factor()
	
	if abs(new_scale - current_scale) > 0.01:  # Only update if significant change
		current_scale = new_scale
		apply_scaling()
		
		print("ViewportScaler: Updated scale to %.2f for viewport %s" % [current_scale, viewport_size])

func calculate_scale_factor() -> float:
	"""Calculate the appropriate scale factor"""
	var width_ratio = viewport_size.x / reference_size.x
	var height_ratio = viewport_size.y / reference_size.y
	
	var scale_factor: float
	
	match scale_mode:
		ScaleMode.STRETCH:
			# Use average of both ratios (may distort)
			scale_factor = (width_ratio + height_ratio) / 2.0
		
		ScaleMode.FIT:
			# Use smaller ratio to fit within bounds
			scale_factor = min(width_ratio, height_ratio)
		
		ScaleMode.SMART_FIT:
			# Intelligent scaling based on content and aspect ratio
			scale_factor = get_smart_scale_factor(width_ratio, height_ratio)
		
		ScaleMode.FILL:
			# Use larger ratio to fill viewport
			scale_factor = max(width_ratio, height_ratio)
		
		ScaleMode.ADAPTIVE:
			# Adaptive scaling based on viewport characteristics
			scale_factor = get_adaptive_scale_factor(width_ratio, height_ratio)
		
		_:
			scale_factor = min(width_ratio, height_ratio)
	
	# Apply limits
	return clamp(scale_factor, min_scale, max_scale)

func get_smart_scale_factor(width_ratio: float, height_ratio: float) -> float:
	"""Get smart scale factor that considers content layout"""
	# For ultrawide monitors, prefer height-based scaling
	var aspect_ratio = viewport_size.x / viewport_size.y
	var reference_aspect = reference_size.x / reference_size.y
	
	if aspect_ratio > reference_aspect * 1.5:  # Ultrawide
		# Favor height scaling for ultrawide to maintain readability
		return height_ratio * 0.9  # Slightly reduce to ensure margins
	elif aspect_ratio < reference_aspect * 0.7:  # Tall/narrow
		# Favor width scaling for narrow screens
		return width_ratio * 0.9
	else:
		# Normal aspect ratio, use minimum to fit
		return min(width_ratio, height_ratio)

func get_adaptive_scale_factor(width_ratio: float, height_ratio: float) -> float:
	"""Get adaptive scale factor based on screen characteristics"""
	var min_ratio = min(width_ratio, height_ratio)
	var _max_ratio = max(width_ratio, height_ratio)  # Reserved for future use
	
	# Use logarithmic scaling for better distribution
	if min_ratio > 1.0:
		# Upscaling: more conservative
		return 1.0 + (min_ratio - 1.0) * 0.7
	else:
		# Downscaling: more aggressive to maintain usability
		return min_ratio

func apply_scaling():
	"""Apply the calculated scaling to the container"""
	var scale_vector = Vector2(current_scale, current_scale)
	
	if maintain_aspect_ratio:
		# Apply uniform scaling
		set_scale(scale_vector)
	else:
		# Apply separate X/Y scaling (may distort)
		var width_scale = viewport_size.x / reference_size.x
		var height_scale = viewport_size.y / reference_size.y
		set_scale(Vector2(width_scale, height_scale))
	
	if center_content:
		# Center the scaled content
		var scaled_size = reference_size * current_scale
		scale_offset = (viewport_size - scaled_size) / 2.0
		set_position(scale_offset)
	
	# Only update font sizes and other properties that don't inherit transform
	# Children inherit the scale transform automatically, so don't scale them again
	update_children_fonts_only()

func update_children_fonts_only():
	"""Update only font properties of child elements (no size scaling to avoid multiplication)"""
	for child in get_children():
		update_child_fonts_only(child)

func update_child_fonts_only(node: Node):
	"""Update only font properties for a specific child node"""
	if node is Control:
		var control = node as Control
		
		# Only update font sizes, not minimum sizes (which would multiply with transform)
		update_control_fonts(control)
	
	# Recursively update children fonts only
	for child in node.get_children():
		update_child_fonts_only(child)

func update_children_scaling():
	"""Update scaling properties of child elements (DEPRECATED - use fonts_only to avoid multiplication)"""
	# This function is kept for compatibility but should not be used
	# when the ViewportScaler already applies transform scaling
	for child in get_children():
		update_child_scaling_safe(child)

func update_child_scaling_safe(node: Node):
	"""Safe scaling for child nodes that checks for existing scaling"""
	if node is Control:
		var control = node as Control
		
		# Only update fonts, not sizes to avoid multiplication
		update_control_fonts(control)
		
		# Only update minimum sizes if parent doesn't have scale transform
		if get_scale() == Vector2.ONE and control.custom_minimum_size != Vector2.ZERO:
			var base_min_size = control.get_meta("original_min_size", control.custom_minimum_size)
			control.set_meta("original_min_size", base_min_size)
			control.custom_minimum_size = base_min_size * current_scale
	
	# Recursively update children
	for child in node.get_children():
		update_child_scaling_safe(child)

func update_control_fonts(control: Control):
	"""Update font sizes for a control"""
	if control.has_theme_font_size_override("font_size"):
		var base_font_size = control.get_meta("original_font_size", control.get_theme_font_size("font_size"))
		control.set_meta("original_font_size", base_font_size)
		var new_font_size = int(base_font_size * current_scale)
		control.add_theme_font_size_override("font_size", new_font_size)

func get_current_scale() -> float:
	"""Get the current scale factor"""
	return current_scale

func get_scaled_size() -> Vector2:
	"""Get the size of content after scaling"""
	return reference_size * current_scale

func set_reference_size(new_size: Vector2):
	"""Set a new reference size and update scaling"""
	reference_size = new_size
	update_scaling()

# Utility functions for manual element positioning
func scale_position(pos: Vector2) -> Vector2:
	"""Scale a position value"""
	return pos * current_scale + scale_offset

func scale_size(size_vector: Vector2) -> Vector2:
	"""Scale a size value"""
	return size_vector * current_scale

func unscale_position(scaled_pos: Vector2) -> Vector2:
	"""Convert scaled position back to original coordinates"""
	return (scaled_pos - scale_offset) / current_scale
