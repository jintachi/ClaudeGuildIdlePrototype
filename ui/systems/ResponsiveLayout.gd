class_name ResponsiveLayout
extends RefCounted

# NOTE: layout_mode assignments use integer values for compatibility
# These values match Godot's internal enum values used in .tscn files

## ResponsiveLayout System
## Converts absolute positioned UI elements to responsive layouts
## Provides utilities for responsive design patterns

# Reference design size (what the UI was designed for)
const REFERENCE_SIZE = Vector2(1920, 1080)

# Layout conversion modes
enum ConversionMode {
	PRESERVE_PROPORTIONS,  # Maintain exact proportional positions
	SNAP_TO_EDGES,        # Snap elements close to edges
	SMART_GRID,           # Use intelligent grid-based positioning
	CONTAINER_AWARE       # Consider parent container types
}

# Static utility functions for layout conversion
static func convert_absolute_to_responsive(control: Control, mode: ConversionMode = ConversionMode.SMART_GRID, reference_size: Vector2 = REFERENCE_SIZE):
	"""Convert a control from absolute positioning to responsive anchoring"""
	if not control or control.layout_mode != 0:
		return  # Skip if not absolute positioned
	
	var parent = control.get_parent()
	if not parent is Control:
		return  # Need a Control parent for anchoring
	
	var parent_control = parent as Control
	var parent_size = reference_size
	
	# Use actual parent size if available, fallback to reference
	if parent_control.size.x > 0 and parent_control.size.y > 0:
		parent_size = parent_control.size
	
	match mode:
		ConversionMode.PRESERVE_PROPORTIONS:
			_convert_proportional(control, parent_size)
		ConversionMode.SNAP_TO_EDGES:
			_convert_edge_snapped(control, parent_size)
		ConversionMode.SMART_GRID:
			_convert_smart_grid(control, parent_size)
		ConversionMode.CONTAINER_AWARE:
			_convert_container_aware(control, parent_size)

static func _convert_proportional(control: Control, parent_size: Vector2):
	"""Convert using exact proportional positioning"""
	var pos = control.position
	var size = control.size
	
	# Calculate proportional anchors
	var anchor_left = pos.x / parent_size.x
	var anchor_top = pos.y / parent_size.y
	var anchor_right = (pos.x + size.x) / parent_size.x
	var anchor_bottom = (pos.y + size.y) / parent_size.y
	
	# Apply anchoring
	control.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	control.anchor_left = clamp(anchor_left, 0.0, 1.0)
	control.anchor_top = clamp(anchor_top, 0.0, 1.0)
	control.anchor_right = clamp(anchor_right, 0.0, 1.0)
	control.anchor_bottom = clamp(anchor_bottom, 0.0, 1.0)
	
	# Clear offsets since we're using pure anchoring
	control.offset_left = 0
	control.offset_top = 0
	control.offset_right = 0
	control.offset_bottom = 0
	
	@warning_ignore_start("int_as_enum_without_cast", "int_as_enum_without_match")
	control.layout_mode = 1  # Anchors and offsets
	@warning_ignore_restore("int_as_enum_without_cast", "int_as_enum_without_match")

static func _convert_edge_snapped(control: Control, parent_size: Vector2):
	"""Convert with edge snapping for elements near edges"""
	var pos = control.position
	var size = control.size
	var edge_threshold = 50.0  # Pixels from edge to consider "near edge"
	
	# Determine which edges the element is near
	var near_left = pos.x < edge_threshold
	var near_right = (parent_size.x - (pos.x + size.x)) < edge_threshold
	var near_top = pos.y < edge_threshold
	var near_bottom = (parent_size.y - (pos.y + size.y)) < edge_threshold
	
	# Choose appropriate anchoring based on edge proximity
	if near_left and near_top:
		control.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	elif near_right and near_top:
		control.set_anchors_preset(Control.PRESET_TOP_RIGHT, false)
	elif near_left and near_bottom:
		control.set_anchors_preset(Control.PRESET_BOTTOM_LEFT, false)
	elif near_right and near_bottom:
		control.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT, false)
	elif near_left:
		control.set_anchors_preset(Control.PRESET_LEFT_WIDE, false)
	elif near_right:
		control.set_anchors_preset(Control.PRESET_RIGHT_WIDE, false)
	elif near_top:
		control.set_anchors_preset(Control.PRESET_TOP_WIDE, false)
	elif near_bottom:
		control.set_anchors_preset(Control.PRESET_BOTTOM_WIDE, false)
	else:
		# Center element
		control.set_anchors_preset(Control.PRESET_CENTER, false)
	
	# Adjust offsets to maintain position
	var target_pos = pos
	var target_size = size
	_adjust_offsets_for_position(control, target_pos, target_size)
	
	@warning_ignore_start("int_as_enum_without_cast", "int_as_enum_without_match")
	control.layout_mode = 1  # Anchors and offsets
	@warning_ignore_restore("int_as_enum_without_cast", "int_as_enum_without_match")

static func _convert_smart_grid(control: Control, parent_size: Vector2):
	"""Convert using intelligent grid-based positioning"""
	var pos = control.position
	var size = control.size
	
	# Divide parent into a 12x12 grid for smart positioning
	var grid_cols = 12
	var grid_rows = 12
	var col_width = parent_size.x / grid_cols
	var row_height = parent_size.y / grid_rows
	
	# Find which grid cells this element occupies
	var start_col = int(pos.x / col_width)
	var start_row = int(pos.y / row_height)
	var end_col = int((pos.x + size.x) / col_width)
	var end_row = int((pos.y + size.y) / row_height)
	
	# Convert grid positions to anchors
	var anchor_left = float(start_col) / float(grid_cols)
	var anchor_top = float(start_row) / float(grid_rows)
	var anchor_right = float(end_col) / float(grid_cols)
	var anchor_bottom = float(end_row) / float(grid_rows)
	
	# Apply grid-based anchoring
	control.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	control.anchor_left = clamp(anchor_left, 0.0, 1.0)
	control.anchor_top = clamp(anchor_top, 0.0, 1.0)
	control.anchor_right = clamp(anchor_right, 0.0, 1.0)
	control.anchor_bottom = clamp(anchor_bottom, 0.0, 1.0)
	
	# Fine-tune with offsets if needed
	var expected_pos = Vector2(anchor_left * parent_size.x, anchor_top * parent_size.y)
	var expected_size = Vector2((anchor_right - anchor_left) * parent_size.x, (anchor_bottom - anchor_top) * parent_size.y)
	
	control.offset_left = pos.x - expected_pos.x
	control.offset_top = pos.y - expected_pos.y
	control.offset_right = (pos.x + size.x) - (expected_pos.x + expected_size.x)
	control.offset_bottom = (pos.y + size.y) - (expected_pos.y + expected_size.y)
	
	@warning_ignore_start("int_as_enum_without_cast", "int_as_enum_without_match")
	control.layout_mode = 1  # Anchors and offsets
	@warning_ignore_restore("int_as_enum_without_cast", "int_as_enum_without_match")

static func _convert_container_aware(control: Control, parent_size: Vector2):
	"""Convert based on parent container type"""
	var parent = control.get_parent()
	
	# Check parent type and use appropriate strategy
	if parent is VBoxContainer or parent is HBoxContainer:
		# For container parents, use size flags instead of anchoring
		@warning_ignore_start("int_as_enum_without_cast", "int_as_enum_without_match")
		control.layout_mode = 2  # Container
		@warning_ignore_restore("int_as_enum_without_cast", "int_as_enum_without_match")
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	elif parent is MarginContainer:
		# For margin containers, use full rect anchoring
		control.set_anchors_preset(Control.PRESET_FULL_RECT, false)
		@warning_ignore_start("int_as_enum_without_cast", "int_as_enum_without_match")
		control.layout_mode = 1  # Anchors and offsets
		@warning_ignore_restore("int_as_enum_without_cast", "int_as_enum_without_match")
	else:
		# For generic Control parents, use smart grid
		_convert_smart_grid(control, parent_size)

static func _adjust_offsets_for_position(control: Control, target_pos: Vector2, target_size: Vector2):
	"""Adjust offsets to maintain target position and size"""
	# This is a simplified version - you might need more complex logic
	# depending on the anchor configuration
	control.offset_left = target_pos.x
	control.offset_top = target_pos.y
	control.offset_right = target_pos.x + target_size.x
	control.offset_bottom = target_pos.y + target_size.y

# Batch conversion functions
static func convert_scene_to_responsive(scene_root: Control, mode: ConversionMode = ConversionMode.SMART_GRID):
	"""Convert an entire scene tree to responsive layout"""
	if not scene_root:
		return
	
	print("Converting scene to responsive layout: ", scene_root.name)
	_convert_recursive(scene_root, mode)

static func _convert_recursive(node: Node, mode: ConversionMode):
	"""Recursively convert all Control nodes in a tree"""
	if node is Control:
		convert_absolute_to_responsive(node as Control, mode)
	
	# Process children
	for child in node.get_children():
		_convert_recursive(child, mode)

# Layout optimization functions
static func optimize_container_structure(control: Control):
	"""Optimize container structure for better responsive behavior"""
	# Convert groups of absolutely positioned elements to containers
	var children = []
	for child in control.get_children():
		if child is Control:
			children.append(child)
	
	if children.size() > 1:
		# Analyze if children would benefit from being in a container
		var should_containerize = _analyze_containerization_benefit(children)
		if should_containerize:
			_create_optimal_container_structure(control, children)

static func _analyze_containerization_benefit(controls: Array) -> bool:
	"""Analyze if controls would benefit from containerization"""
	if controls.size() < 2:
		return false
	
	# Check if controls are aligned horizontally or vertically
	var horizontal_alignment = _check_horizontal_alignment(controls)
	var vertical_alignment = _check_vertical_alignment(controls)
	
	return horizontal_alignment or vertical_alignment

static func _check_horizontal_alignment(controls: Array) -> bool:
	"""Check if controls are roughly horizontally aligned"""
	if controls.size() < 2:
		return false
	
	var avg_y = 0.0
	for control in controls:
		avg_y += control.position.y
	avg_y /= controls.size()
	
	var tolerance = 20.0  # pixels
	for control in controls:
		if abs(control.position.y - avg_y) > tolerance:
			return false
	
	return true

static func _check_vertical_alignment(controls: Array) -> bool:
	"""Check if controls are roughly vertically aligned"""
	if controls.size() < 2:
		return false
	
	var avg_x = 0.0
	for control in controls:
		avg_x += control.position.x
	avg_x /= controls.size()
	
	var tolerance = 20.0  # pixels
	for control in controls:
		if abs(control.position.x - avg_x) > tolerance:
			return false
	
	return true

static func _create_optimal_container_structure(_parent: Control, children: Array):
	"""Create optimal container structure for grouped controls"""
	# This is a placeholder for more complex containerization logic
	# In a full implementation, you'd create HBoxContainer or VBoxContainer
	# and reparent the aligned children to these containers
	print("Would create container structure for ", children.size(), " aligned controls")

# Utility functions
static func get_responsive_info(control: Control) -> Dictionary:
	"""Get information about a control's responsive properties"""
	return {
		"layout_mode": control.layout_mode,
		"anchors": [control.anchor_left, control.anchor_top, control.anchor_right, control.anchor_bottom],
		"offsets": [control.offset_left, control.offset_top, control.offset_right, control.offset_bottom],
		"size_flags": [control.size_flags_horizontal, control.size_flags_vertical],
		"is_responsive": control.layout_mode != 0
	}
