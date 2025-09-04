extends HBoxContainer

func update_progress(quest: Quest):
	"""Update the progress bar and time display for a quest"""
	# Update progress bar
	var progress_bar = get_node_or_null("ProgressBar")
	if progress_bar:
		progress_bar.value = quest.get_progress_percentage()
	
	# Update time label
	var time_label = get_node_or_null("TimeLabel")
	if time_label:
		var time_remaining = quest.get_time_remaining()
		var minutes = int(time_remaining / 60.0)
		var seconds = int(time_remaining) % 60
		time_label.text = "⏱️ %02d:%02d" % [minutes, seconds]
