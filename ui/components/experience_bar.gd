extends VBoxContainer

const UIAtlas = preload("res://ui/systems/UIAtlas.gd")
const NineSliceProgressBar = preload("res://ui/components/NineSliceProgressBar.gd")

#region Node References
@export var level_label: Label
@export var experience_label: Label
@export var progress_bar: ProgressBar
#endregion

#region Public Functions
func update_experience(character: Character):
	"""Update the experience bar with character data"""
	if not character:
		return
	
	UIAtlas.initialize()
	
	var current_exp = character.experience
	var exp_needed = character.get_experience_needed_for_next_level()
	var level = character.level
	
	# Update labels
	level_label.text = "Level %d" % level
	experience_label.text = "%d/%d XP" % [current_exp, exp_needed]
	
	# Update progress bar
	var progress_percentage = 0.0
	if exp_needed > 0:
		progress_percentage = (float(current_exp) / float(exp_needed)) * 100.0
	
	progress_bar.value = progress_percentage
	
	# Apply atlas-based styling if this is a regular ProgressBar
	if progress_bar is ProgressBar and not progress_bar is NineSliceProgressBar:
		_apply_atlas_styling_to_progress_bar(progress_bar, progress_percentage)
	
	# Color coding based on progress (for non-atlas bars) - REMOVED
	# if progress_percentage >= 100.0:
	# 	# Ready to level up - golden color with pulsing effect
	# 	progress_bar.modulate = Color(1.0, 0.8, 0.0)
	# 	level_label.text = "Level %d (Ready to Level Up!)" % level
	# elif progress_percentage >= 75.0:
	# 	# Close to leveling - green color
	# 	progress_bar.modulate = Color(0.2, 1.0, 0.2)
	# elif progress_percentage >= 50.0:
	# 	# Halfway there - blue color
	# 	progress_bar.modulate = Color(0.2, 0.6, 1.0)
	# elif progress_percentage >= 25.0:
	# 	# Quarter progress - orange color
	# 	progress_bar.modulate = Color(1.0, 0.6, 0.2)
	# else:
	# 	# Just started - red color
	# 	progress_bar.modulate = Color(1.0, 0.3, 0.3)
	
	# Keep the "Ready to Level Up!" text for 100% progress
	if progress_percentage >= 100.0:
		level_label.text = "Level %d (Ready to Level Up!)" % level

func _apply_atlas_styling_to_progress_bar(progress_bar: ProgressBar, progress_percentage: float):
	"""Apply atlas-based styling to the progress bar"""
	# Create background style with atlas texture
	var bg_style = UIAtlas.create_stylebox_with_atlas("experience_bar_bg", 0, 0)
	
	# Create fill style with atlas texture
	var fill_style = UIAtlas.create_stylebox_with_atlas("experience_bar_fill", 0, 0)
	
	# Apply styles to progress bar
	progress_bar.add_theme_stylebox_override("background", bg_style)
	progress_bar.add_theme_stylebox_override("fill", fill_style)

func set_compact_mode(enabled: bool = true):
	"""Enable compact mode for smaller panels"""
	if enabled:
		# Hide experience label in compact mode, keep only level and progress bar
		experience_label.visible = false
		progress_bar.custom_minimum_size.y = 12
	else:
		experience_label.visible = true
		progress_bar.custom_minimum_size.y = 16
