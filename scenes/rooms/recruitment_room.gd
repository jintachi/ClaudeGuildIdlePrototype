class_name RecruitmentRoom
extends BaseRoom

# Recruitment-specific UI elements
@export var guild_roster_grid: GridContainer
@export var refresh_recruits_button: Button
@export var recruit_button: Button
@export var current_resources_panel: VBoxContainer
@export var cost_panel: VBoxContainer
@export var projected_resources_panel: VBoxContainer
@export var selected_recruit_info_panel: VBoxContainer

# Recruitment state
var current_selected_recruit: Character = null
var selected_recruit_panel: Control = null

func _init():
	room_name = "Recruitment"
	room_description = "Recruit new guild members"
	is_unlocked = true

func setup_room_specific_ui():
	"""Setup recruitment-specific UI connections"""
	# Connect to guild manager signals for recruitment updates
	if GuildManager:
		GuildManager.character_recruited.connect(_on_character_recruited)
	
	# Connect UI buttons
	if refresh_recruits_button:
		refresh_recruits_button.pressed.connect(_on_refresh_recruits_button_pressed)
	if recruit_button:
		recruit_button.pressed.connect(_on_recruit_button_pressed)

func on_room_entered():
	"""Called when entering the recruitment room"""
	update_room_display()

func update_room_display():
	"""Update the recruitment display"""
	update_recruitment_display()

func update_recruitment_display():
	"""Update the recruitment display with all available recruits"""
	# Clear existing displays
	for child in guild_roster_grid.get_children():
		child.queue_free()
	
	# Create panels for each available recruit
	for recruit in GuildManager.available_recruits:
		var recruit_panel = create_recruit_panel(recruit)
		guild_roster_grid.add_child(recruit_panel)
	
	# Initialize UI state
	current_selected_recruit = null
	selected_recruit_panel = null
	update_recruitment_right_panel()

func create_recruit_panel(recruit: Character) -> Control:
	"""Create a recruit panel for the recruitment display"""
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(400, 100)
	
	# Make panel clickable
	var button = Button.new()
	button.flat = true
	button.custom_minimum_size = Vector2(400, 100)
	panel.add_child(button)
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(func(): select_recruit(recruit, panel))
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Character info
	var name_label = Label.new()
	var stars = "★".repeat(recruit.quality)
	name_label.text = "%s (%s) %s" % [recruit.character_name, recruit.get_class_name(), stars]
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)
	
	# Stats summary
	var stats_label = Label.new()
	stats_label.text = "HP:%d DEF:%d ATK:%d SPL:%d" % [recruit.health, recruit.defense, recruit.attack_power, recruit.spell_power]
	stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(stats_label)
	
	# Experience bar for recruits (if they have experience)
	if recruit.experience > 0 or recruit.level > 1:
		var experience_bar_scene = preload("res://ui/components/ExperienceBar.tscn")
		var experience_bar = experience_bar_scene.instantiate()
		experience_bar.set_compact_mode(true)
		experience_bar.update_experience(recruit)
		experience_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(experience_bar)
	
	# Cost display
	var cost = recruit.get_recruitment_cost()
	var cost_label = Label.new()
	cost_label.text = "Cost: %d Influence, %d Gold" % [cost.influence, cost.gold]
	if cost.food > 0: cost_label.text += ", %d Food" % cost.food
	if cost.armor > 0: cost_label.text += ", %d Armor" % cost.armor
	if cost.weapons > 0: cost_label.text += ", %d Weapons" % cost.weapons
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(cost_label)
	
	return panel

func select_recruit(recruit: Character, panel: Control):
	"""Select a recruit and update the display"""
	# Deselect previous panel
	if selected_recruit_panel:
		selected_recruit_panel.modulate = Color.WHITE
	
	# Select new panel
	current_selected_recruit = recruit
	selected_recruit_panel = panel
	panel.modulate = Color(1.2, 1.2, 1.0)  # Light yellow highlight
	
	# Update right panel
	update_recruitment_right_panel()

func update_recruitment_right_panel():
	"""Update the recruitment right panel with current selection"""
	# Clear right panel children
	for child in current_resources_panel.get_children():
		child.queue_free()
	for child in projected_resources_panel.get_children():
		child.queue_free()
	for child in selected_recruit_info_panel.get_children():
		child.queue_free()
	for child in cost_panel.get_children():
		child.queue_free()
	
	# Update recruit button state
	if current_selected_recruit:
		var cost = current_selected_recruit.get_recruitment_cost()
		var can_afford = GuildManager.can_afford_cost(cost)
		var roster_full = GuildManager.roster.size() >= GuildManager.max_roster_size
		
		recruit_button.disabled = not can_afford or roster_full
		recruit_button.flat = false
		
		if roster_full:
			recruit_button.text = "Roster Full"
		elif not can_afford:
			recruit_button.text = "Cannot Afford"
		else:
			recruit_button.text = "Recruit " + current_selected_recruit.character_name
	else:
		recruit_button.disabled = true
		recruit_button.flat = true
		recruit_button.text = "Select a Recruit"
	
	# Display current resources
	update_current_resources_display(_get_resources())
	
	# Display projected resources if recruit selected
	if current_selected_recruit:
		update_projected_resources_display(_get_resources(), current_selected_recruit.get_recruitment_cost())
		update_cost_display(current_selected_recruit.get_recruitment_cost())
		update_selected_recruit_info_display()

func update_current_resources_display(resource_items: Dictionary):
	"""Update the current resources display"""
	var title = Label.new()
	title.text = "Current Resources"
	title.add_theme_font_size_override("font_size", 14)
	current_resources_panel.add_child(title)
	
	for resource_name in resource_items:
		var label = Label.new()
		label.text = "%s: %s" % [resource_name, resource_items[resource_name]]
		current_resources_panel.add_child(label)

func update_cost_display(cost: Dictionary):
	"""Update the cost display"""
	var title = Label.new()
	title.text = "Recruit Cost"
	title.add_theme_font_size_override("font_size", 14)
	cost_panel.add_child(title)
	
	for resource_name in cost:
		var cost_amount = cost[resource_name]
		var label = Label.new()
		label.text = "%s: %d" % [resource_name, cost_amount]
		cost_panel.add_child(label)

func update_projected_resources_display(resource_items: Dictionary, cost: Dictionary):
	"""Update the projected resources display"""
	var title = Label.new()
	title.text = "After Recruitment"
	title.add_theme_font_size_override("font_size", 14)
	projected_resources_panel.add_child(title)
	
	for resource_name in resource_items:
		var current_amount = resource_items[resource_name]
		var cost_amount = cost.get(resource_name, 0)
		var remaining = current_amount - cost_amount
		var label = Label.new()
		label.text = "%s: %d" % [resource_name, remaining]
		
		# Color red if insufficient
		if remaining < 0:
			label.modulate = Color.RED
		else:
			label.modulate = Color.WHITE
			
		projected_resources_panel.add_child(label)

func update_selected_recruit_info_display():
	"""Update the selected recruit info display"""
	if not current_selected_recruit:
		return
		
	var recruit = current_selected_recruit
	
	var title = Label.new()
	title.text = "Selected Recruit"
	title.add_theme_font_size_override("font_size", 14)
	selected_recruit_info_panel.add_child(title)
	
	# Name and class
	var name_label = Label.new()
	var stars = "★".repeat(recruit.quality)
	name_label.text = "%s (%s) %s" % [recruit.character_name, recruit.get_class_name(), stars]
	selected_recruit_info_panel.add_child(name_label)
	
	# Detailed stats
	var stats_label = Label.new()
	stats_label.text = "HP:%d DEF:%d ATK:%d SPL:%d\nMNA:%d SPD:%d LCK:%d" % [
		recruit.health, recruit.defense, recruit.attack_power,
		recruit.spell_power, recruit.mana, recruit.movement_speed, recruit.luck
	]
	selected_recruit_info_panel.add_child(stats_label)
	
	# Substats
	var substats_label = Label.new()
	var substat_text = "Skills:\n"
	var skills = []
	if recruit.gathering > 0: skills.append("Gathering: %d" % recruit.gathering)
	if recruit.hunting_trapping > 0: skills.append("Hunting: %d" % recruit.hunting_trapping)
	if recruit.diplomacy > 0: skills.append("Diplomacy: %d" % recruit.diplomacy)
	if recruit.caravan_guarding > 0: skills.append("Caravan: %d" % recruit.caravan_guarding)
	if recruit.escorting > 0: skills.append("Escort: %d" % recruit.escorting)
	if recruit.stealth > 0: skills.append("Stealth: %d" % recruit.stealth)
	if recruit.odd_jobs > 0: skills.append("Odd Jobs: %d" % recruit.odd_jobs)
	
	substats_label.text = substat_text + ("\n".join(skills) if not skills.is_empty() else "None")
	selected_recruit_info_panel.add_child(substats_label)

func _get_resources() -> Dictionary:
	"""Get current guild resources"""
	var resources = GuildManager.get_guild_status_summary().resources
	return resources

func get_recruitment_summary() -> Dictionary:
	"""Get recruitment summary information"""
	return {
		"available_recruits": GuildManager.available_recruits.size(),
		"roster_size": GuildManager.roster.size(),
		"max_roster_size": GuildManager.max_roster_size,
		"roster_full": GuildManager.roster.size() >= GuildManager.max_roster_size,
		"recruitment_quality_modifier": GuildManager.recruitment_quality_modifier
	}

# Signal handlers
func _on_character_recruited(character: Character):
	"""Handle when a character is recruited"""
	print("RecruitmentRoom: Character recruited: ", character.character_name)
	# Refresh recruitment display
	update_room_display()

func _on_refresh_recruits_button_pressed():
	"""Handle refresh recruits button press"""
	GuildManager.generate_recruits()
	update_room_display()

func _on_recruit_button_pressed():
	"""Handle recruit button press"""
	if current_selected_recruit:
		GuildManager.recruit_character(current_selected_recruit)
		# Clear selection after recruitment
		current_selected_recruit = null
		selected_recruit_panel = null
		update_room_display()

func save_room_state():
	"""Save recruitment room state"""
	# Save selected recruit reference
	if current_selected_recruit:
		# Store recruit by name for persistence
		pass  # TODO: Implement if needed

func load_room_state():
	"""Load recruitment room state"""
	# Restore selected recruit if available
	pass  # TODO: Implement if needed
