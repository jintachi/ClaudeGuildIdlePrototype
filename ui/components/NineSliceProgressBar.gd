extends ProgressBar
class_name NineSliceProgressBar

const UI_ATLAS = preload("res://ui/systems/UIAtlas.gd")

@export var use_nine_slice: bool = true
@export var segment_width: int = 8  # Width of start/end segments

var background_start: AtlasTexture
var background_middle: AtlasTexture
var background_end: AtlasTexture
var fill_start: AtlasTexture
var fill_middle: AtlasTexture
var fill_end: AtlasTexture

func _ready():
	UI_ATLAS.initialize()
	_setup_textures()
	_apply_styling()

func _setup_textures():
	# Get the 9-slice textures
	background_start = UI_ATLAS.get_atlas_texture("progress_bar_bg_start")
	background_middle = UI_ATLAS.get_atlas_texture("progress_bar_bg_middle")
	background_end = UI_ATLAS.get_atlas_texture("progress_bar_bg_end")
	
	fill_start = UI_ATLAS.get_atlas_texture("progress_bar_fill_start")
	fill_middle = UI_ATLAS.get_atlas_texture("progress_bar_fill_middle")
	fill_end = UI_ATLAS.get_atlas_texture("progress_bar_fill_end")

func _apply_styling():
	if not use_nine_slice:
		# Use simple styling for non-nine-slice mode
		var simple_bg_style = UI_ATLAS.create_stylebox_with_atlas("progress_bar_bg", 0, 0)
		var simple_fill_style = UI_ATLAS.create_stylebox_with_atlas("progress_bar_fill", 0, 0)
		
		add_theme_stylebox_override("background", simple_bg_style)
		add_theme_stylebox_override("fill", simple_fill_style)
		return
	
	# Create 9-slice background style
	var bg_style = StyleBoxTexture.new()
	bg_style.texture = background_middle  # Use middle as base texture
	bg_style.texture_margin_left = segment_width
	bg_style.texture_margin_top = 0
	bg_style.texture_margin_right = segment_width
	bg_style.texture_margin_bottom = 0
	
	# Create 9-slice fill style
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
	if not use_nine_slice or not background_start or not fill_start:
		return
	
	# Draw background with 9-slice
	_draw_nine_slice_background()
	
	# Draw fill with 9-slice
	_draw_nine_slice_fill()

func _draw_nine_slice_background():
	var bar_width = size.x
	var bar_height = size.y
	
	# Draw start segment (flip horizontally to mirror the end segment)
	draw_texture_rect(background_start, Rect2(0, 0, segment_width, bar_height), true)
	
	# Draw middle segment (stretched)
	var middle_width = bar_width - (2 * segment_width)
	if middle_width > 0:
		draw_texture_rect(background_middle, Rect2(segment_width, 0, middle_width, bar_height), false)
	
	# Draw end segment
	draw_texture_rect(background_end, Rect2(bar_width - segment_width, 0, segment_width, bar_height), false)

func _draw_nine_slice_fill():
	var fill_width = (value / max_value) * (size.x - 4)  # Subtract 4px total (2px on each end)
	var bar_height = size.y
	
	if fill_width <= 0:
		return
	
	# Calculate how much of each segment to draw
	var remaining_width = fill_width
	
	# Draw start segment (if we have enough width) - flip horizontally to mirror the end segment
	if remaining_width >= segment_width:
		draw_texture_rect(fill_start, Rect2(2, 0, segment_width, bar_height), true)  # Add 2px margin from left
		remaining_width -= segment_width
	else:
		# Partial start segment
		draw_texture_rect_region(fill_start, Rect2(2, 0, remaining_width, bar_height), Rect2(0, 0, remaining_width, bar_height))
		return
	
	# Draw middle segments
	var middle_x = segment_width + 2  # Add 2px margin from left
	while remaining_width >= 80:  # Full middle segment width
		draw_texture_rect(fill_middle, Rect2(middle_x, 0, 80, bar_height), false)
		middle_x += 80
		remaining_width -= 80
	
	# Draw partial middle segment if needed
	if remaining_width > 0:
		draw_texture_rect_region(fill_middle, Rect2(middle_x, 0, remaining_width, bar_height), Rect2(0, 0, remaining_width, bar_height))
		middle_x += remaining_width
		remaining_width = 0
	
	# Draw end segment if we have enough width
	if fill_width >= size.x - segment_width - 4:  # Account for margins
		draw_texture_rect(fill_end, Rect2(size.x - segment_width - 2, 0, segment_width, bar_height), false)  # Subtract 2px margin from right

# Set the segment width
func set_segment_width(width: int):
	segment_width = width
	queue_redraw()

# Toggle nine-slice mode
func set_nine_slice_mode(enabled: bool):
	use_nine_slice = enabled
	_apply_styling()
	queue_redraw()

# Update progress with nine-slice rendering
func update_progress(new_value: float):
	value = new_value
	if use_nine_slice:
		queue_redraw()
