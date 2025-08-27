class_name RosterRoom
extends BaseRoom

# Roster-specific UI elements
@export var roster_list: VBoxContainer
@export var adventurer_inspection_panel: Control
@export var roster_inspection_panel: Control

# Character selection state
var selected_character: Character = null

func _init():
	room_name = "Roster"
	room_description = "Manage your guild members"
	is_unlocked = true

func setup_room_specific_ui():
	"""Setup roster-specific UI connections"""
	# Connect to guild manager signals for roster updates
	if GuildManager:
		GuildManager.character_recruited.connect(_on_character_recruited)
		GuildManager.quest_completed.connect(_on_quest_completed)

func on_room_entered():
	"""Called when entering the roster room"""
	update_room_display()
	
	# Show placeholder if no characters in roster
	if GuildManager.roster.is_empty():
		if roster_inspection_panel:
			roster_inspection_panel.visible = false

func _process(delta: float):
	"""Update injury recovery progress bars smoothly"""
	if not is_inside_tree():
		return
	
	update_injury_recovery_progress(delta)

func update_room_display():
	"""Update the roster display"""
	update_roster_display()

func update_roster_display():
	"""Update the roster display with all characters"""
	print("Updating roster display...")
	print("GuildManager.roster size: ", GuildManager.roster.size())
	
	# Clear existing displays
	for child in roster_list.get_children():
		child.queue_free()
	
	# Create panels for each character
	for character in GuildManager.roster:
		print("Creating panel for character: ", character.character_name)
		var char_panel = create_character_panel(character)
		roster_list.add_child(char_panel)
	
	# Auto-select first character if none selected
	if not selected_character and not GuildManager.roster.is_empty():
		select_adventurer(GuildManager.roster[0])

func create_character_panel(character: Character) -> Control:
	"""Create a character panel for the roster display"""
	# Create a clickable button instead of a panel
	var panel_button = Button.new()
	panel_button.custom_minimum_size = Vector2(400, 120)
	panel_button.flat = true  # Remove default button styling
	panel_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	
	# Store character reference for later identification
	panel_button.set_meta("character", character)
	
	# Connect the click handler
	panel_button.pressed.connect(func(): select_adventurer(character))
	
	# Create a panel inside the button for styling
	var inner_panel = Panel.new()
	inner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let button handle clicks
	
	# Safety check: make sure the panel doesn't already have a parent
	if inner_panel.get_parent():
		print("Warning: inner_panel already has a parent!")
		inner_panel.get_parent().remove_child(inner_panel)
	
	panel_button.add_child(inner_panel)
	inner_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var panel = inner_panel
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 3)
	
	# Name and class
	var name_label = Label.new()
	var stars = "★".repeat(character.quality)
	name_label.text = "%s (%s) %s [%s Rank]" % [
		character.character_name, character.get_class_name(), stars,
		character.get_rank_name()
	]
	name_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(name_label)
	
	# Experience bar
	var experience_bar_scene = preload("res://ui/components/ExperienceBar.tscn")
	var experience_bar = experience_bar_scene.instantiate()
	experience_bar.set_compact_mode(true)  # Use compact mode for character panels
	experience_bar.update_experience(character)
	vbox.add_child(experience_bar)
	
	# Stats
	var stats_label = Label.new()
	stats_label.text = "HP:%d DEF:%d ATK:%d SPL:%d MNA:%d SPD:%d LCK:%d" % [
		character.health, character.defense, character.attack_power,
		character.spell_power, character.mana, character.movement_speed, character.luck
	]
	vbox.add_child(stats_label)
	
	# Substats
	var substats_label = Label.new()
	var substat_text = "Skills: "
	var skills = []
	if character.gathering > 0: skills.append("Gathering:%d" % character.gathering)
	if character.hunting_trapping > 0: skills.append("Hunting:%d" % character.hunting_trapping)
	if character.diplomacy > 0: skills.append("Diplomacy:%d" % character.diplomacy)
	if character.caravan_guarding > 0: skills.append("Caravan:%d" % character.caravan_guarding)
	if character.escorting > 0: skills.append("Escort:%d" % character.escorting)
	if character.stealth > 0: skills.append("Stealth:%d" % character.stealth)
	if character.odd_jobs > 0: skills.append("OddJobs:%d" % character.odd_jobs)
	
	substats_label.text = substat_text + (", ".join(skills) if not skills.is_empty() else "None")
	vbox.add_child(substats_label)
	
	# Status section - create an HBox to hold status and injury recovery side by side
	var status_hbox = HBoxContainer.new()
	status_hbox.name = "Status"
	status_hbox.add_theme_constant_override("separation", 10)
	
	# Status label
	var status_label = Label.new()
	if character.is_injured():
		status_label.text = "INJURED"
		status_label.modulate = Color.RED
	elif character.promotion_quest_available:
		status_label.text = "READY FOR PROMOTION"
		status_label.modulate = Color.GREEN
	else:
		# Use the new status system
		status_label.text = character.get_status_name().to_upper()
		match character.character_status:
			Character.CharacterStatus.AVAILABLE:
				status_label.modulate = Color.WHITE
			Character.CharacterStatus.ON_QUEST:
				status_label.modulate = Color.YELLOW
			Character.CharacterStatus.WAITING_FOR_RESULTS:
				status_label.modulate = Color.CYAN
			Character.CharacterStatus.WAITING_TO_PROGRESS:
				status_label.modulate = Color.ORANGE
	
	status_hbox.add_child(status_label)
	
	# Add injury recovery container if injured
	if character.is_injured():
		var injury_container = create_injury_recovery_bar(character)
		status_hbox.add_child(injury_container)
	
	vbox.add_child(status_hbox)

	return panel_button

func create_injury_recovery_bar(character: Character) -> Control:
	"""Create an injury recovery progress bar container for a character"""
	var recovery_container = HBoxContainer.new()
	recovery_container.name = "InjuryRecoveryContainer"
	recovery_container.add_theme_constant_override("separation", 10)
	
	# Injury type label
	var injury_type_label = Label.new()
	injury_type_label.name = "InjuryTypeLabel"
	var injury_name = get_injury_name(character.injury_type)
	injury_type_label.text = "Injury Type: %s" % injury_name
	injury_type_label.add_theme_font_size_override("font_size", 10)
	injury_type_label.add_theme_color_override("font_color", Color.RED)
	recovery_container.add_child(injury_type_label)
	
	# Recovery time label
	var time_label = Label.new()
	time_label.name = "RecoveryTimeLabel"
	var time_remaining = character.get_injury_duration()
	var minutes = int(time_remaining / 60)
	var seconds = int(time_remaining) % 60
	time_label.text = "Recovery Time: %02d:%02d" % [minutes, seconds]
	time_label.add_theme_font_size_override("font_size", 10)
	time_label.add_theme_color_override("font_color", Color.RED)
	recovery_container.add_child(time_label)
	
	# Recovery progress bar
	var progress_bar = ProgressBar.new()
	progress_bar.name = "RecoveryProgressBar"
	progress_bar.max_value = 100
	var injury_duration = character.injury_duration
	var progress_percentage = 0.0
	
	if injury_duration > 0:
		progress_percentage = ((injury_duration - time_remaining) / injury_duration) * 100.0
	
	progress_bar.value = progress_percentage
	progress_bar.custom_minimum_size = Vector2(150, 15)
	recovery_container.add_child(progress_bar)
	
	# Set the script for the container
	recovery_container.set_script(load("res://ui/components/injury_recovery_container.gd"))
	
	return recovery_container

func get_injury_name(injury_type: Character.InjuryType) -> String:
	"""Get the display name for an injury type"""
	match injury_type:
		Character.InjuryType.PHYSICAL_WOUND: return "Physical Wound"
		Character.InjuryType.MENTAL_TRAUMA: return "Mental Trauma"
		Character.InjuryType.CURSED_AFFLICTION: return "Cursed"
		Character.InjuryType.EXHAUSTION: return "Exhausted"
		Character.InjuryType.POISON: return "Poisoned"
		_: return "Unknown"

func select_adventurer(character: Character):
	"""Select an adventurer and show their inspection panel"""
	selected_character = character
	
	# Update visual states of all character panels
	update_character_panel_states(character)
	
	if roster_inspection_panel and roster_inspection_panel.has_method("inspect_character"):
		roster_inspection_panel.visible = true
		roster_inspection_panel.inspect_character(character)
	elif adventurer_inspection_panel and adventurer_inspection_panel.has_method("inspect_character"):
		adventurer_inspection_panel.visible = true
		adventurer_inspection_panel.inspect_character(character)

func update_character_panel_states(selected_character: Character):
	"""Update visual states of all character panels"""
	# Find all character panels and update their states
	for child in roster_list.get_children():
		if child.has_meta("character"):
			var character = child.get_meta("character")
			var inner_panel = child.get_child(0)  # The Panel inside the Button
			
			if inner_panel is Panel:
				# Use theme-based selection method
				if character == selected_character:
					# Selected state: use the "selected" theme variation
					inner_panel.add_theme_stylebox_override("panel", get_theme_stylebox("selected", "CharacterPanel"))
				else:
					# Unselected state: use the default "panel" theme variation
					inner_panel.add_theme_stylebox_override("panel", get_theme_stylebox("panel", "CharacterPanel"))
				
				# Update experience bar if it exists
				update_character_panel_experience(child, character)

func update_character_panel_experience(panel_button: Control, character: Character):
	"""Update the experience bar in a character panel"""
	if not panel_button or not character:
		return
	
	# Find the experience bar in the panel
	var inner_panel = panel_button.get_child(0)
	if not inner_panel or not inner_panel is Panel:
		return
	
	var vbox = inner_panel.get_child(0)
	if not vbox or not vbox is VBoxContainer:
		return
	
	# Look for the experience bar (it should be the second child after the name label)
	if vbox.get_child_count() >= 2:
		var experience_bar = vbox.get_child(1)  # Experience bar is second child
		if experience_bar and experience_bar.has_method("update_experience"):
			experience_bar.update_experience(character)

func update_injury_recovery_progress(delta: float):
	"""Update injury recovery progress bars for all injured characters"""
	for child in roster_list.get_children():
		if child.has_meta("character"):
			var character = child.get_meta("character")
			if character and character.is_injured():
				# Find the injury recovery container in the new Status VBox structure
				var inner_panel = child.get_child(0)  # The Panel inside the Button
				if not inner_panel or not inner_panel is Panel:
					continue
				
				var main_vbox = inner_panel.get_child(0)  # Main VBoxContainer
				if not main_vbox or not main_vbox is VBoxContainer:
					continue
				
				# Find the Status HBox (should be the last child)
				var status_hbox = main_vbox.get_child(main_vbox.get_child_count() - 1)
				if not status_hbox or not status_hbox is HBoxContainer or status_hbox.name != "Status":
					continue
				
				# Look for the injury recovery container in the Status HBox
				for i in range(status_hbox.get_child_count()):
					var recovery_container = status_hbox.get_child(i)
					if recovery_container and recovery_container.has_method("update_injury_recovery"):
						recovery_container.update_injury_recovery(character)
						break

func refresh_all_character_panels():
	"""Refresh all character panels to update experience bars and other data"""
	for child in roster_list.get_children():
		if child.has_meta("character"):
			var character = child.get_meta("character")
			update_character_panel_experience(child, character)
			
			# Also refresh injury recovery progress if character is injured
			if character and character.is_injured():
				var inner_panel = child.get_child(0)
				if inner_panel and inner_panel is Panel:
					var vbox = inner_panel.get_child(0)
					if vbox and vbox is VBoxContainer:
						for i in range(vbox.get_child_count()):
							var recovery_container = vbox.get_child(i)
							if recovery_container and recovery_container.has_method("update_injury_recovery"):
								recovery_container.update_injury_recovery(character)
								break

func get_character_status_summary() -> Dictionary:
	"""Get a summary of character statuses for display"""
	return GuildManager.get_character_status_summary()

func get_roster_size_info() -> Dictionary:
	"""Get roster size information"""
	return {
		"current_size": GuildManager.roster.size(),
		"max_size": GuildManager.max_roster_size,
		"is_full": GuildManager.roster.size() >= GuildManager.max_roster_size
	}

# Signal handlers
func _on_character_recruited(character: Character):
	"""Handle when a new character is recruited"""
	update_room_display()

func _on_quest_completed(quest: Quest):
	"""Handle when a quest is completed"""
	# Refresh character panels to update status and experience
	refresh_all_character_panels()

func save_room_state():
	"""Save roster room state"""
	# Save selected character reference
	if selected_character:
		# Store character by name for persistence
		pass  # TODO: Implement if needed

func load_room_state():
	"""Load roster room state"""
	# Restore selected character if available
	pass  # TODO: Implement if needed
