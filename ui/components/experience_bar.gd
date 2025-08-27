extends VBoxContainer

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
	
	# Color coding based on progress
	if progress_percentage >= 100.0:
		# Ready to level up - golden color with pulsing effect
		progress_bar.modulate = Color(1.0, 0.8, 0.0)
		level_label.text = "Level %d (Ready to Level Up!)" % level
	elif progress_percentage >= 75.0:
		# Close to leveling - green color
		progress_bar.modulate = Color(0.2, 1.0, 0.2)
	elif progress_percentage >= 50.0:
		# Halfway there - blue color
		progress_bar.modulate = Color(0.2, 0.6, 1.0)
	elif progress_percentage >= 25.0:
		# Quarter progress - orange color
		progress_bar.modulate = Color(1.0, 0.6, 0.2)
	else:
		# Just started - red color
		progress_bar.modulate = Color(1.0, 0.3, 0.3)

func set_compact_mode(enabled: bool = true):
	"""Enable compact mode for smaller panels"""
	if enabled:
		# Hide experience label in compact mode, keep only level and progress bar
		experience_label.visible = false
		progress_bar.custom_minimum_size.y = 12
	else:
		experience_label.visible = true
		progress_bar.custom_minimum_size.y = 16
