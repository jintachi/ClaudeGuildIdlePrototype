extends HBoxContainer

func update_injury_recovery(character: Character):
	"""Update the injury recovery progress bar and time display for a character"""
	# Update progress bar
	var progress_bar = get_node_or_null("RecoveryProgressBar")
	if progress_bar:
		var injury_duration = character.injury_duration
		var time_remaining = character.get_injury_duration()
		var progress_percentage = 0.0
		
		if injury_duration > 0:
			progress_percentage = ((injury_duration - time_remaining) / injury_duration) * 100.0
		
		progress_bar.value = progress_percentage
	
	# Update injury type label
	var injury_type_label = get_node_or_null("InjuryTypeLabel")
	if injury_type_label:
		var injury_name = get_injury_name(character.injury_type)
		injury_type_label.text = "Injury Type: %s" % injury_name
	
	# Update time label
	var time_label = get_node_or_null("RecoveryTimeLabel")
	if time_label:
		var time_remaining = character.get_injury_duration()
		var minutes = int(time_remaining / 60.0)
		var seconds = int(time_remaining) % 60
		time_label.text = "Recovery Time: %02d:%02d" % [minutes, seconds]

func get_injury_name(injury_type: Character.InjuryType) -> String:
	"""Get the display name for an injury type"""
	match injury_type:
		Character.InjuryType.PHYSICAL_WOUND: return "Physical Wound"
		Character.InjuryType.MENTAL_TRAUMA: return "Mental Trauma"
		Character.InjuryType.CURSED_AFFLICTION: return "Cursed"
		Character.InjuryType.EXHAUSTION: return "Exhausted"
		Character.InjuryType.POISON: return "Poisoned"
		_: return "Unknown"
