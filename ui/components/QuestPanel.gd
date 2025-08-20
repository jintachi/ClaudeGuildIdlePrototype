class_name QuestPanel
extends Panel

## QuestPanel Component
## Custom panel for quest selection with theme-based visual states

func set_selected(selected: bool):
	"""Set the visual state of the quest panel"""
	if selected:
		# Use the "selected" theme variation
		add_theme_stylebox_override("panel", get_theme_stylebox("selected", "QuestPanel"))
	else:
		# Use the default "panel" theme variation
		add_theme_stylebox_override("panel", get_theme_stylebox("panel", "QuestPanel"))
