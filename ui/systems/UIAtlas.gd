extends RefCounted
class_name UIAtlas

# Atlas texture reference
static var atlas_texture: Texture2D

# Atlas regions - these will be defined based on your specifications
static var regions: Dictionary = {}

# Initialize the atlas system
static func initialize():
	if not atlas_texture:
		atlas_texture = preload("res://assets/ui_assets/ProgressBars.png")
		_setup_regions()

# Setup atlas regions - you can help define these sections
static func _setup_regions():
	# Progress bar regions from bar_and_fill.png (96x22 each cell)
	# Format: Rect2(x, y, width, height)
	
	# Background bar segments (first cell: 0,0 to 95,21)
	regions["progress_bar_bg_start"] = Rect2(2, 0, 8, 22)    # Left end (8px)
	regions["progress_bar_bg_middle"] = Rect2(8, 0, 80, 22)  # Middle section (80px, stretchable)
	regions["progress_bar_bg_end"] = Rect2(86, 0, 8, 22)     # Right end (8px)
	
	# Fill segments (second cell: 96,0 to 191,21)
	regions["progress_bar_fill_start"] = Rect2(99, 0, 8, 22)    # Left end (8px)
	regions["progress_bar_fill_middle"] = Rect2(104, 0, 80, 22) # Middle section (80px, stretchable)
	regions["progress_bar_fill_end"] = Rect2(181, 0, 8, 22)     # Right end (8px)
	
	# Complete background and fill for convenience
	regions["progress_bar_bg"] = Rect2(0, 0, 96, 22)   # Complete background
	regions["progress_bar_fill"] = Rect2(96, 0, 96, 22) # Complete fill
	
	# Default experience bar regions
	regions["experience_bar_bg"] = Rect2(0, 0, 96, 22)   # Background
	regions["experience_bar_fill"] = Rect2(96, 0, 96, 22) # Fill
	
	# Buttons - different states
	regions["button_normal"] = Rect2(32, 0, 64, 16)  # Normal button state
	regions["button_hover"] = Rect2(32, 16, 64, 16)  # Hover button state
	regions["button_pressed"] = Rect2(32, 32, 64, 16)  # Pressed button state
	regions["button_disabled"] = Rect2(32, 48, 64, 16)  # Disabled button state
	
	# Panels and containers
	regions["panel_bg"] = Rect2(96, 0, 128, 64)  # Panel background
	regions["panel_header"] = Rect2(96, 64, 128, 16)  # Panel header
	regions["panel_corner"] = Rect2(224, 0, 16, 16)  # Panel corner decoration
	
	# Icons and decorative elements
	regions["icon_quest"] = Rect2(0, 64, 16, 16)  # Quest icon
	regions["icon_character"] = Rect2(16, 64, 16, 16)  # Character icon
	regions["icon_inventory"] = Rect2(32, 64, 16, 16)  # Inventory icon
	regions["icon_gear"] = Rect2(48, 64, 16, 16)  # Settings/gear icon
	regions["icon_sword"] = Rect2(0, 80, 16, 16)  # Combat/sword icon
	regions["icon_shield"] = Rect2(16, 80, 16, 16)  # Defense/shield icon
	regions["icon_magic"] = Rect2(32, 80, 16, 16)  # Magic/spell icon
	
	# Borders and frames
	regions["border_thin"] = Rect2(240, 0, 8, 8)  # Thin border texture
	regions["border_medium"] = Rect2(240, 8, 12, 12)  # Medium border texture
	regions["border_thick"] = Rect2(240, 20, 16, 16)  # Thick border texture
	
	# Backgrounds and fills
	regions["bg_dark"] = Rect2(0, 96, 32, 32)  # Dark background
	regions["bg_medium"] = Rect2(32, 96, 32, 32)  # Medium background
	regions["bg_light"] = Rect2(64, 96, 32, 32)  # Light background

# Get an atlas texture for a specific region
static func get_atlas_texture(region_name: String) -> AtlasTexture:
	if not atlas_texture:
		initialize()
	
	if not regions.has(region_name):
		push_error("Region '%s' not found in UIAtlas" % region_name)
		return null
	
	var atlas_tex = AtlasTexture.new()
	atlas_tex.atlas = atlas_texture
	atlas_tex.region = regions[region_name]
	
	return atlas_tex

# Update a region definition
static func set_region(region_name: String, rect: Rect2):
	regions[region_name] = rect

# Get all available region names
static func get_region_names() -> Array:
	return regions.keys()

# Create a StyleBoxTexture with atlas texture
static func create_stylebox_with_atlas(region_name: String, border_width: int = 0, corner_radius: int = 0) -> StyleBoxTexture:
	var style = StyleBoxTexture.new()
	
	# Set the atlas texture
	var atlas_tex = get_atlas_texture(region_name)
	if atlas_tex:
		style.texture = atlas_tex
	
	# Set texture margins for 9-slice if needed
	if border_width > 0:
		style.texture_margin_left = border_width
		style.texture_margin_top = border_width
		style.texture_margin_right = border_width
		style.texture_margin_bottom = border_width
	
	return style
