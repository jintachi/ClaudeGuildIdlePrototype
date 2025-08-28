extends ProgressBar
class_name ThreeSliceTestProgressBar

const UIAtlas = preload("res://ui/systems/UIAtlas.gd")

@export var use_three_slice: bool = true
@export var segment_width: int = 8  # Width of start/end segments

# Test region coordinates - you can edit these in the inspector
@export var bg_start_region: Rect2 = Rect2(0, 0, 8, 22)
@export var bg_middle_region: Rect2 = Rect2(8, 0, 80, 22)
@export var bg_end_region: Rect2 = Rect2(88, 0, 8, 22)
@export var fill_start_region: Rect2 = Rect2(96, 0, 8, 22)
@export var fill_middle_region: Rect2 = Rect2(104, 0, 80, 22)
@export var fill_end_region: Rect2 = Rect2(184, 0, 8, 22)

var background_start: AtlasTexture
var background_middle: AtlasTexture
var background_end: AtlasTexture
var fill_start: AtlasTexture
var fill_middle: AtlasTexture
var fill_end: AtlasTexture

# UI Controls
var control_panel: Panel
var bg_start_x: SpinBox
var bg_start_y: SpinBox
var bg_start_w: SpinBox
var bg_start_h: SpinBox
var bg_middle_x: SpinBox
var bg_middle_y: SpinBox
var bg_middle_w: SpinBox
var bg_middle_h: SpinBox
var bg_end_x: SpinBox
var bg_end_y: SpinBox
var bg_end_w: SpinBox
var bg_end_h: SpinBox
var fill_start_x: SpinBox
var fill_start_y: SpinBox
var fill_start_w: SpinBox
var fill_start_h: SpinBox
var fill_middle_x: SpinBox
var fill_middle_y: SpinBox
var fill_middle_w: SpinBox
var fill_middle_h: SpinBox
var fill_end_x: SpinBox
var fill_end_y: SpinBox
var fill_end_w: SpinBox
var fill_end_h: SpinBox

func _ready():
	UIAtlas.initialize()
	_setup_textures()
	_apply_styling()
	_create_control_panel()

func _setup_textures():
	# Create atlas textures using the test regions
	background_start = _create_atlas_texture(bg_start_region)
	background_middle = _create_atlas_texture(bg_middle_region)
	background_end = _create_atlas_texture(bg_end_region)
	
	fill_start = _create_atlas_texture(fill_start_region)
	fill_middle = _create_atlas_texture(fill_middle_region)
	fill_end = _create_atlas_texture(fill_end_region)

func _create_atlas_texture(region: Rect2) -> AtlasTexture:
	var atlas_tex = AtlasTexture.new()
	atlas_tex.atlas = UIAtlas.atlas_texture
	atlas_tex.region = region
	return atlas_tex

func _create_control_panel():
	# Create main panel
	control_panel = Panel.new()
	control_panel.custom_minimum_size = Vector2(400, 600)
	control_panel.position = Vector2(10, 30)
	
	# Create main container
	var main_container = VBoxContainer.new()
	main_container.custom_minimum_size = Vector2(380, 580)
	main_container.position = Vector2(10, 10)
	control_panel.add_child(main_container)
	
	# Title
	var title = Label.new()
	title.text = "Region Controls"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(title)
	
	# Background regions section
	var bg_section = _create_region_section("Background Regions", "bg")
	main_container.add_child(bg_section)
	
	# Fill regions section
	var fill_section = _create_region_section("Fill Regions", "fill")
	main_container.add_child(fill_section)
	
	# Apply button
	var apply_button = Button.new()
	apply_button.text = "Apply Changes"
	apply_button.custom_minimum_size = Vector2(0, 30)
	apply_button.pressed.connect(_on_apply_changes)
	main_container.add_child(apply_button)
	
	# Add panel to scene
	get_parent().add_child.call_deferred(control_panel)
	
	# Now that all controls are created, set their initial values
	call_deferred("_update_control_values")

func _create_region_section(title: String, prefix: String) -> VBoxContainer:
	var section = VBoxContainer.new()
	
	# Section title
	var section_title = Label.new()
	section_title.text = title
	section_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_child(section_title)
	
	# Create controls for start, middle, end
	var regions = ["start", "middle", "end"]
	for region in regions:
		var region_container = HBoxContainer.new()
		region_container.custom_minimum_size = Vector2(0, 25)
		
		# Region label
		var region_label = Label.new()
		region_label.text = region.capitalize()
		region_label.custom_minimum_size = Vector2(60, 0)
		region_container.add_child(region_label)
		
		# X, Y, W, H spinboxes
		var x_spin = SpinBox.new()
		x_spin.custom_minimum_size = Vector2(50, 0)
		x_spin.min_value = 0
		x_spin.max_value = 1000
		x_spin.step = 1
		region_container.add_child(x_spin)
		
		var y_spin = SpinBox.new()
		y_spin.custom_minimum_size = Vector2(50, 0)
		y_spin.min_value = 0
		y_spin.max_value = 1000
		y_spin.step = 1
		region_container.add_child(y_spin)
		
		var w_spin = SpinBox.new()
		w_spin.custom_minimum_size = Vector2(50, 0)
		w_spin.min_value = 1
		w_spin.max_value = 1000
		w_spin.step = 1
		region_container.add_child(w_spin)
		
		var h_spin = SpinBox.new()
		h_spin.custom_minimum_size = Vector2(50, 0)
		h_spin.min_value = 1
		h_spin.max_value = 1000
		h_spin.step = 1
		region_container.add_child(h_spin)
		
		# Store references
		if prefix == "bg":
			if region == "start":
				bg_start_x = x_spin
				bg_start_y = y_spin
				bg_start_w = w_spin
				bg_start_h = h_spin
			elif region == "middle":
				bg_middle_x = x_spin
				bg_middle_y = y_spin
				bg_middle_w = w_spin
				bg_middle_h = h_spin
			elif region == "end":
				bg_end_x = x_spin
				bg_end_y = y_spin
				bg_end_w = w_spin
				bg_end_h = h_spin
		else:  # fill
			if region == "start":
				fill_start_x = x_spin
				fill_start_y = y_spin
				fill_start_w = w_spin
				fill_start_h = h_spin
			elif region == "middle":
				fill_middle_x = x_spin
				fill_middle_y = y_spin
				fill_middle_w = w_spin
				fill_middle_h = h_spin
			elif region == "end":
				fill_end_x = x_spin
				fill_end_y = y_spin
				fill_end_w = w_spin
				fill_end_h = h_spin
		
		section.add_child(region_container)
	
	return section

func _update_control_values():
	# Check if controls are initialized
	if not bg_start_x or not fill_start_x:
		return
		
	# Background regions
	bg_start_x.value = bg_start_region.position.x
	bg_start_y.value = bg_start_region.position.y
	bg_start_w.value = bg_start_region.size.x
	bg_start_h.value = bg_start_region.size.y
	
	bg_middle_x.value = bg_middle_region.position.x
	bg_middle_y.value = bg_middle_region.position.y
	bg_middle_w.value = bg_middle_region.size.x
	bg_middle_h.value = bg_middle_region.size.y
	
	bg_end_x.value = bg_end_region.position.x
	bg_end_y.value = bg_end_region.position.y
	bg_end_w.value = bg_end_region.size.x
	bg_end_h.value = bg_end_region.size.y
	
	# Fill regions
	fill_start_x.value = fill_start_region.position.x
	fill_start_y.value = fill_start_region.position.y
	fill_start_w.value = fill_start_region.size.x
	fill_start_h.value = fill_start_region.size.y
	
	fill_middle_x.value = fill_middle_region.position.x
	fill_middle_y.value = fill_middle_region.position.y
	fill_middle_w.value = fill_middle_region.size.x
	fill_middle_h.value = fill_middle_region.size.y
	
	fill_end_x.value = fill_end_region.position.x
	fill_end_y.value = fill_end_region.position.y
	fill_end_w.value = fill_end_region.size.x
	fill_end_h.value = fill_end_region.size.y

func _on_apply_changes():
	# Check if controls are initialized
	if not bg_start_x or not fill_start_x:
		return
		
	# Update regions from UI values
	bg_start_region = Rect2(bg_start_x.value, bg_start_y.value, bg_start_w.value, bg_start_h.value)
	bg_middle_region = Rect2(bg_middle_x.value, bg_middle_y.value, bg_middle_w.value, bg_middle_h.value)
	bg_end_region = Rect2(bg_end_x.value, bg_end_y.value, bg_end_w.value, bg_end_h.value)
	
	fill_start_region = Rect2(fill_start_x.value, fill_start_y.value, fill_start_w.value, fill_start_h.value)
	fill_middle_region = Rect2(fill_middle_x.value, fill_middle_y.value, fill_middle_w.value, fill_middle_h.value)
	fill_end_region = Rect2(fill_end_x.value, fill_end_y.value, fill_end_w.value, fill_end_h.value)
	
	# Recreate textures and redraw
	_setup_textures()
	queue_redraw()

func _apply_styling():
	if not use_three_slice:
		# Use simple styling for non-three-slice mode
		var bg_style = StyleBoxTexture.new()
		bg_style.texture = background_middle
		var fill_style = StyleBoxTexture.new()
		fill_style.texture = fill_middle
		
		add_theme_stylebox_override("background", bg_style)
		add_theme_stylebox_override("fill", fill_style)
		return
	
	# Create 3-slice background style
	var bg_style = StyleBoxTexture.new()
	bg_style.texture = background_middle  # Use middle as base texture
	bg_style.texture_margin_left = segment_width
	bg_style.texture_margin_top = 0
	bg_style.texture_margin_right = segment_width
	bg_style.texture_margin_bottom = 0
	
	# Create 3-slice fill style
	var fill_style = StyleBoxTexture.new()
	fill_style.texture = fill_middle  # Use middle as base texture
	fill_style.texture_margin_left = segment_width
	fill_style.texture_margin_top = 0
	fill_style.texture_margin_right = segment_width
	fill_style.texture_margin_bottom = 0
	
	# Apply styles 
	add_theme_stylebox_override("background", bg_style)
	add_theme_stylebox_override("fill", fill_style)

func _draw():
	if not use_three_slice or not background_start or not fill_start:
		return
	
	# Draw background with 3-slice
	_draw_three_slice_background()
	
	# Draw fill with 3-slice
	_draw_three_slice_fill()

func _draw_three_slice_background():
	var bar_width = size.x
	var bar_height = size.y
	
	# Draw start segment
	draw_texture_rect(background_start, Rect2(0, 0, segment_width, bar_height), false)
	
	# Draw middle segment (stretched)
	var middle_width = bar_width - (2 * segment_width)
	if middle_width > 0:
		draw_texture_rect(background_middle, Rect2(segment_width, 0, middle_width, bar_height), false)
	
	# Draw end segment
	draw_texture_rect(background_end, Rect2(bar_width - segment_width, 0, segment_width, bar_height), false)

func _draw_three_slice_fill():
	var fill_width = (value / max_value) * (size.x - 4)  # Subtract 4px total (2px on each end)
	var bar_height = size.y
	
	if fill_width <= 0:
		return
	
	# Calculate how much of each segment to draw
	var remaining_width = fill_width
	
	# Draw start segment (if we have enough width)
	if remaining_width >= segment_width:
		draw_texture_rect(fill_start, Rect2(2, 0, segment_width, bar_height), false)  # Add 2px margin from left
		remaining_width -= segment_width
	else:
		# Partial start segment
		draw_texture_rect_region(fill_start, Rect2(2, 0, remaining_width, bar_height), Rect2(0, 0, remaining_width, bar_height))
		return
	
	# Draw middle segments (repeating)
	var middle_x = segment_width + 2  # Add 2px margin from left
	var middle_segment_width = fill_middle_region.size.x
	
	while remaining_width >= middle_segment_width:
		draw_texture_rect(fill_middle, Rect2(middle_x, 0, middle_segment_width, bar_height), false)
		middle_x += middle_segment_width
		remaining_width -= middle_segment_width
	
	# Draw partial middle segment if needed
	if remaining_width > 0:
		draw_texture_rect_region(fill_middle, Rect2(middle_x, 0, remaining_width, bar_height), Rect2(0, 0, remaining_width, bar_height))
		middle_x += remaining_width
		remaining_width = 0
	
	# Draw end segment if we have enough width
	if fill_width >= size.x - segment_width - 4:  # Account for margins
		draw_texture_rect(fill_end, Rect2(size.x - segment_width - 2, 0, segment_width, bar_height), false)  # Subtract 2px margin from right

# Update regions and redraw
func update_regions():
	_setup_textures()
	queue_redraw()

# Set the segment width
func set_segment_width(width: int):
	segment_width = width
	queue_redraw()

# Toggle three-slice mode
func set_three_slice_mode(enabled: bool):
	use_three_slice = enabled
	_apply_styling()
	queue_redraw()

# Update progress with three-slice rendering
func update_progress(new_value: float):
	value = new_value
	if use_three_slice:
		queue_redraw()
