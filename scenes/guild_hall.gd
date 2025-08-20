class_name Main
extends Control

#region Setup and Initialization
# Guild Manager is now a global singleton

# UI Containers
@export var main_hall_container: Control
@export var roster_container: Control
@export var quests_container: Control
@export var recruitment_container: Control
@export var town_map_container: Control

# Main Hall Elements
@export var resources_display: Label
@export var active_quests_panel: VBoxContainer
@export var completed_quests_panel: VBoxContainer
@export var promotion_panel: VBoxContainer

# Navigation Buttons
@export var roster_button: Button
@export var quests_button: Button
@export var recruitment_button: Button
@export var town_map_button: Button


# Roster Tab Elements
@export var roster_list: VBoxContainer
@export var adventurer_inspection_panel: Control
@export var roster_inspection_panel: Control

# Quests Tab Elements
@export var available_quests_list: VBoxContainer
@export var party_selection_panel: Control
@export var party_list: VBoxContainer
@export var start_quest_button: Button
@export var quest_info_label: Label
@export var stats_comparison_table: Control
@export var assigned_members_panel: VBoxContainer

# Recruitment Tab Elements
@export var available_recruits_list: VBoxContainer
@export var refresh_recruits_button: Button
@export var recruit_button: Button
@export var current_resources_panel: VBoxContainer
@export var cost_panel: VBoxContainer
@export var projected_resources_panel: VBoxContainer
@export var selected_recruit_info_panel: VBoxContainer

# Save/Load Buttons
@export var scale_05_button: Button
@export var scale_075_button: Button
@export var scale_1_button: Button
@export var scale_15_button: Button
@export var scale_2_button: Button
@export var scale_3_button: Button
@export var save_button: Button
@export var load_button: Button
@export var new_game_button: Button



# Current state
var current_selected_quest: Quest = null
var current_party: Array[Character] = []
var current_selected_recruit: Character = null
var selected_recruit_panel: Control = null

# Viewport scaling (using direct scaling approach)
var current_scale_factor: float = 1.0

func _ready():
	# Setup viewport scaling first
	setup_viewport_scaling()
	
	setup_ui_connections()
	setup_signal_connections()
	
	# Initialize scale button states
	update_scale_button_states(get_tree().root.content_scale_factor)
	
	# Setup navigation contexts after UI is ready
	call_deferred("setup_navigation_contexts")
	
	show_main_hall()
	update_ui()
#endregion

#region Viewport Scaling Setup
func setup_viewport_scaling():
	"""Setup responsive viewport scaling for the Guild Hall"""
	# HYBRID APPROACH: Use ResponsiveLayout system + responsive containers
	# This combines the best of both automatic conversion and proper layout
	
	# Connect to viewport and resolution changes
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	if SignalBus:
		SignalBus.resolution_confirmed.connect(_on_resolution_confirmed)
		SignalBus.ui_scaling_changed.connect(_on_ui_scaling_changed)
	
	# Set up the Guild Hall to fill viewport properly
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Apply ResponsiveLayout system to convert remaining absolute elements
	call_deferred("apply_responsive_layout_system")
	
	print("Guild Hall: Responsive layout system setup completed")

func _on_viewport_size_changed():
	"""Handle viewport size changes"""
	# No scaling needed - using responsive layout now
	pass

func _on_resolution_confirmed(_resolution: Vector2i):
	"""Handle confirmed resolution changes"""
	# Responsive layout automatically handles resolution changes
	pass

func _on_ui_scaling_changed(_scale_factor: float, _ui_scale_factor: float):
	"""Handle UI scaling changes"""
	# Update theme scaling if needed
	if UIScalingManager:
		UIScalingManager.apply_scaling_to_current_scene()

func apply_responsive_layout_system():
	"""Apply the ResponsiveLayout system to convert absolute positioned elements"""
	print("Guild Hall: Applying ResponsiveLayout system...")
	
	# Load ResponsiveLayout class
	var responsive_layout_script = load("res://ui/systems/ResponsiveLayout.gd")
	
	# Convert the entire scene to responsive layout
	responsive_layout_script.convert_scene_to_responsive(self, responsive_layout_script.ConversionMode.SMART_GRID)
	
	# Optimize container structure for better responsive behavior
	responsive_layout_script.optimize_container_structure(self)
	
	# Apply any specific fixes for known problematic elements
	apply_specific_layout_fixes()
	
	print("Guild Hall: ResponsiveLayout system applied successfully")

func apply_specific_layout_fixes():
	"""Apply specific layout fixes for known issues"""
	# Fix ResourcesLabel if it's still absolutely positioned
	var resources_label = get_node_or_null("MainHall/MainHall_VBox/TopBar/ResourcesPanel/ResourcesLabel")
	if resources_label and resources_label.layout_mode == 0:
		# Convert to proper container child
		resources_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		resources_label.layout_mode = 1  # Anchors and offsets
		# Add some margin
		resources_label.offset_left = 10
		resources_label.offset_top = 5
		resources_label.offset_right = -10
		resources_label.offset_bottom = -5
		print("Fixed ResourcesLabel positioning")
	
	# Fix any SaveLoadPanel buttons if they're absolutely positioned
	fix_save_load_panel()
	
	# Fix quest tab layouts
	fix_quest_tab_layouts()

func fix_save_load_panel():
	"""Fix save/load panel layout"""
	var save_load_panel = get_node_or_null("MainHall/SaveLoadPanel")
	if save_load_panel:
		# Convert to HBoxContainer if not already
		if not save_load_panel is HBoxContainer:
			print("SaveLoadPanel is not an HBoxContainer, converting layout...")
			# Convert child buttons to use container layout
			for child in save_load_panel.get_children():
				if child is Control:
					child.layout_mode = 2  # Container
					child.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func fix_quest_tab_layouts():
	"""Fix quest tab responsive layouts"""
	var quest_container = get_node_or_null("QuestsTab")
	if quest_container:
		# Ensure scroll containers have proper minimum sizes
		var scroll_containers = quest_container.find_children("*", "ScrollContainer", true, false)
		for container in scroll_containers:
			if container.custom_minimum_size == Vector2.ZERO:
				# Set responsive minimum size
				container.custom_minimum_size = Vector2(300, 200)
				container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				container.size_flags_vertical = Control.SIZE_EXPAND_FILL

# Keep old functions for compatibility but mark as deprecated
func apply_viewport_aware_scaling():
	"""DEPRECATED: Using ResponsiveLayout system instead"""
	print("Warning: apply_viewport_aware_scaling is deprecated, using ResponsiveLayout system")

func apply_direct_scaling():
	"""DEPRECATED: Using ResponsiveLayout system instead"""
	print("Warning: apply_direct_scaling is deprecated, using ResponsiveLayout system")

func convert_to_responsive_layout():
	"""Convert hardcoded UI positions to responsive layout"""
	# This function will be called to convert the existing hardcoded
	# layout to a more responsive one
	
	call_deferred("apply_responsive_transforms")

func apply_responsive_transforms():
	"""Apply responsive transformations to UI elements"""
	# Get viewport size for calculations
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Apply responsive adjustments to main containers
	adjust_main_hall_layout(viewport_size)
	adjust_quest_tab_layout(viewport_size)
	adjust_recruitment_tab_layout(viewport_size)
	
	# Force UI update
	update_ui()

func adjust_main_hall_layout(viewport_size: Vector2):
	"""Adjust main hall layout for responsiveness"""
	if not main_hall_container:
		return
	
	# Find child elements that need responsive adjustment
	for child in main_hall_container.get_children():
		adjust_control_layout(child, viewport_size)

func adjust_quest_tab_layout(viewport_size: Vector2):
	"""Adjust quest tab layout for responsiveness"""
	if not quests_container:
		return
		
	# Quest tab already uses VBoxContainer/HBoxContainer which is more responsive
	# Just ensure scroll containers have proper minimum sizes
	var scroll_containers = find_children("*", "ScrollContainer", true, false)
	for container in scroll_containers:
		if container.get_parent() == quests_container:
			# Ensure minimum size based on viewport
			var min_width = viewport_size.x * 0.3  # 30% of viewport width
			var min_height = viewport_size.y * 0.4  # 40% of viewport height
			container.custom_minimum_size = Vector2(min_width, min_height)

func adjust_recruitment_tab_layout(viewport_size: Vector2):
	"""Adjust recruitment tab layout for responsiveness"""
	if not recruitment_container:
		return
		
	# Similar to quest tab, ensure proper minimum sizes
	var scroll_containers = find_children("*", "ScrollContainer", true, false)
	for container in scroll_containers:
		if container.get_parent() == recruitment_container:
			var min_width = viewport_size.x * 0.25
			var min_height = viewport_size.y * 0.35
			container.custom_minimum_size = Vector2(min_width, min_height)

func adjust_control_layout(control: Control, viewport_size: Vector2):
	"""Adjust individual control layout"""
	if not control:
		return
	
	# Convert absolute positioning to relative where possible
	if control.position != Vector2.ZERO and control.layout_mode == 0:
		# Try to convert to anchored positioning
		var relative_x = control.position.x / 1920.0  # Original design width
		var relative_y = control.position.y / 1080.0  # Original design height
		
		# Set anchors based on relative position
		if relative_x < 0.33:  # Left third
			control.anchor_left = 0.0
			control.anchor_right = 0.0
		elif relative_x > 0.67:  # Right third
			control.anchor_left = 1.0
			control.anchor_right = 1.0
		else:  # Center third
			control.anchor_left = 0.5
			control.anchor_right = 0.5
		
		if relative_y < 0.33:  # Top third
			control.anchor_top = 0.0
			control.anchor_bottom = 0.0
		elif relative_y > 0.67:  # Bottom third
			control.anchor_top = 1.0
			control.anchor_bottom = 1.0
		else:  # Middle third
			control.anchor_top = 0.5
			control.anchor_bottom = 0.5
	
	# Recursively adjust children
	for child in control.get_children():
		if child is Control:
			adjust_control_layout(child, viewport_size)
#endregion

#region UI Utilities
func setup_ui_connections():
	# Navigation
	roster_button.pressed.connect(show_roster_tab)
	quests_button.pressed.connect(show_quests_tab)
	recruitment_button.pressed.connect(show_recruitment_tab)
	town_map_button.pressed.connect(show_town_map)
	
	# Quests
	start_quest_button.pressed.connect(_on_start_quest_pressed)
	
	# Recruitment
	refresh_recruits_button.pressed.connect(_on_refresh_recruits_pressed)
	recruit_button.pressed.connect(_on_recruit_selected_character)
	
	# UI Scaling
	scale_05_button.pressed.connect(_on_scale_05_pressed)
	scale_075_button.pressed.connect(_on_scale_075_pressed)
	scale_1_button.pressed.connect(_on_scale_1_pressed)
	scale_15_button.pressed.connect(_on_scale_15_pressed)
	scale_2_button.pressed.connect(_on_scale_2_pressed)
	scale_3_button.pressed.connect(_on_scale_3_pressed)
	
	# Save/Load
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	


func setup_signal_connections():
	# Connect to SignalBus signals
	SignalBus.character_recruited.connect(_on_character_recruited)
	SignalBus.quest_started.connect(_on_quest_started)
	SignalBus.quest_completed.connect(_on_quest_completed)
	SignalBus.emergency_quest_available.connect(_on_emergency_quest_available)
	
	# Connect to GuildManager signals
	GuildManager.character_recruited.connect(_on_guild_manager_character_recruited)
	GuildManager.quest_started.connect(_on_guild_manager_quest_started)
	GuildManager.quest_completed.connect(_on_guild_manager_quest_completed)
	GuildManager.emergency_quest_available.connect(_on_guild_manager_emergency_quest)
	
	# Connect to SignalBus signals
	SignalBus.character_injured.connect(_on_character_injured)



func _process(_delta):
	update_active_quests_display()

func setup_navigation_contexts():
	"""Setup navigation context for each tab"""
	# Set current tab context for each Navigation instance
	var roster_nav = get_node_or_null("RosterTab/RosterVbox/TopBar/Navigation")
	if roster_nav and roster_nav.has_method("set_current_tab"):
		roster_nav.set_current_tab("roster")
	
	var quests_nav = get_node_or_null("QuestsTab/VBoxContainer/TopBar/Navigation")
	if quests_nav and quests_nav.has_method("set_current_tab"):
		quests_nav.set_current_tab("quests")
	
	var recruitment_nav = get_node_or_null("RecruitmentTab/VBoxContainer/TopBar/Navigation")
	if recruitment_nav and recruitment_nav.has_method("set_current_tab"):
		recruitment_nav.set_current_tab("recruitment")
	
	var townmap_nav = get_node_or_null("TownMap/TownMapVbox/TopBar/Navigation")
	if townmap_nav and townmap_nav.has_method("set_current_tab"):
		townmap_nav.set_current_tab("town_map")
#endregion

#region Navigation
func show_main_hall():
	hide_all_tabs()
	main_hall_container.visible = true
	update_main_hall_display()

func show_roster_tab():
	hide_all_tabs()
	roster_container.visible = true
	update_roster_display()
	
	# Show placeholder if no characters in roster
	if GuildManager.roster.is_empty():
		if roster_inspection_panel:
			roster_inspection_panel.visible = false

func show_quests_tab():
	hide_all_tabs()
	quests_container.visible = true
	update_quests_display()
	
	# Always refresh party selection display when switching to quests tab
	# This ensures newly recruited characters are shown
	if current_selected_quest:
		update_party_selection_display()

func show_recruitment_tab():
	hide_all_tabs()
	recruitment_container.visible = true
	update_recruitment_display()

func show_town_map():
	hide_all_tabs()
	town_map_container.visible = true
	update_town_map_display()

func hide_all_tabs():
	main_hall_container.visible = false
	roster_container.visible = false
	quests_container.visible = false
	recruitment_container.visible = false
	town_map_container.visible = false

func update_ui():
	update_resources_display()
	update_main_hall_display()
#endregion

#region Main Hall
func update_resources_display():
	var resources = GuildManager.get_guild_status_summary().resources
	resources_display.text = "Influence: %d | Gold: %d | Food: %d | Materials: %d | Armor: %d | Weapons: %d" % [
		resources.influence, resources.gold, resources.food, 
		resources.building_materials, resources.armor, resources.weapons
	]

func update_main_hall_display():
	update_resources_display()
	update_active_quests_display()
	update_completed_quests_display()
	update_promotion_display()

func update_active_quests_display():
	# Clear existing displays
	for child in active_quests_panel.get_children():
		child.queue_free()
	
	for quest in GuildManager.active_quests:
		var quest_panel = create_active_quest_panel(quest)
		active_quests_panel.add_child(quest_panel)

func create_active_quest_panel(quest: Quest) -> Control:
	
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(300, 150)	
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	
	
	# Quest title
	var title = Label.new()
	title.text = quest.quest_name
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)
	
	# Progress bar
	var progress_bar = ProgressBar.new()
	progress_bar.max_value = 100
	progress_bar.value = quest.get_progress_percentage()
	vbox.add_child(progress_bar)
	
	# Time remaining
	var time_label = Label.new()
	var time_remaining = quest.get_time_remaining()
	var minutes = int(time_remaining / 60)
	var seconds = int(time_remaining) % 60
	time_label.text = "Time remaining: %02d:%02d" % [minutes, seconds]
	vbox.add_child(time_label)
	
	# Party status
	var party_info = quest.get_party_display_info()
	var party_label = Label.new()
	var party_text = "Party: "
	for member in party_info:
		party_text += "%s(%s)%s " % [member.name, member.class, member.status]
	party_label.text = party_text
	vbox.add_child(party_label)
	
	# Add completion button if quest is completed
	if quest.active_quest_status == Quest.QuestStatus.COMPLETED:
		var complete_button = Button.new()
		complete_button.text = "Quest Complete: Accept Results"
		complete_button.add_theme_color_override("font_color", Color.GREEN)
		complete_button.pressed.connect(_on_accept_quest_results.bind(quest))
		vbox.add_child(complete_button)
	
	return panel
#endregion

#region Guild Master's Room
func update_promotion_display():
	# Clear existing displays
	for child in promotion_panel.get_children():
		child.queue_free()
	
	var characters_needing_promotion = GuildManager.get_characters_needing_promotion()
	for character in characters_needing_promotion:
		var promo_panel = create_promotion_panel(character)
		promotion_panel.add_child(promo_panel)

func update_completed_quests_display():
	"""Update the completed quests display in main hall"""
	# Clear existing completed quest panels
	var scroll_container = completed_quests_panel.get_child(1)  # Get the ScrollContainer
	if scroll_container and scroll_container.get_child_count() > 0:
		var completed_container = scroll_container.get_child(0)  # Get the VBoxContainer
		if completed_container:
			for child in completed_container.get_children():
				child.queue_free()
			
			# Display all completed quests
			for quest in GuildManager.completed_quests:
				var quest_panel = create_completed_quest_panel(quest)
				completed_container.add_child(quest_panel)

func create_completed_quest_panel(quest: Quest) -> Control:
	"""Create a panel displaying completed quest information"""
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(300, 200)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	
	# Quest name
	var quest_name_label = Label.new()
	quest_name_label.text = "Quest Completed: " + quest.quest_name
	quest_name_label.add_theme_font_size_override("font_size", 14)
	quest_name_label.add_theme_color_override("font_color", Color.GREEN)
	vbox.add_child(quest_name_label)
	
	# Quest members
	var party_names = []
	for character in quest.assigned_party:
		party_names.append(character.character_name)
	
	var members_label = Label.new()
	members_label.text = "Quest Members: " + ", ".join(party_names)
	members_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(members_label)
	
	# Check for injuries at completion time
	var injured_members = []
	var completion_injuries = quest.get_completion_injuries()
	for character in quest.assigned_party:
		var injury_type = completion_injuries.get(character.character_name, Character.InjuryType.NONE)
		if injury_type != Character.InjuryType.NONE:
			var injury_name = get_injury_name(injury_type)
			injured_members.append("%s: %s" % [character.character_name, injury_name])
	
	if not injured_members.is_empty():
		var injuries_label = Label.new()
		injuries_label.text = "Injuries Sustained: " + ", ".join(injured_members)
		injuries_label.add_theme_color_override("font_color", Color.ORANGE)
		injuries_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(injuries_label)
	
	# Rewards
	var rewards_label = Label.new()
	rewards_label.text = "Quest Completion Reward Earned: " + quest.get_rewards_text()
	rewards_label.add_theme_color_override("font_color", Color.YELLOW)
	rewards_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(rewards_label)
	
	return panel

func create_promotion_panel(character: Character) -> Control:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(250, 60)
	
	var hbox = HBoxContainer.new()
	panel.add_child(hbox)
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var info = Label.new()
	info.text = "%s (%s) ready for promotion to %s" % [
		character.character_name, 
		character.get_class_name(),
		Character.Rank.keys()[character.rank + 1] if character.rank < Character.Rank.SSS else "MAX"
	]
	hbox.add_child(info)
	
	var promote_button = Button.new()
	promote_button.text = "Promote"
	promote_button.pressed.connect(func(): start_promotion_quest(character))
	hbox.add_child(promote_button)
	
	return panel

func start_promotion_quest(character: Character):
	# Create a promotion quest specific to the character
	var promotion_quest = create_promotion_quest_for_character(character)
	GuildManager.available_quests.append(promotion_quest)
	print("Promotion quest created for ", character.character_name)

func create_promotion_quest_for_character(character: Character) -> Quest:
	var quest = Quest.new()
	quest.quest_type = Quest.QuestType.EMERGENCY
	quest.quest_rank = Quest.QuestRank.values()[min(character.rank + 1, Quest.QuestRank.S)]
	quest.quest_name = "Promotion Quest: %s" % character.character_name
	quest.allow_partial_failure = false
	quest.min_party_size = 1
	quest.max_party_size = 1
	quest.duration = 120.0  # 2 minutes for promotion
	
	match character.character_class:
		Character.CharacterClass.ATTACKER:
			quest.description = "Defeat a powerful enemy solo to prove your combat prowess."
			quest.min_total_attack_power = character.attack_power
		Character.CharacterClass.TANK:
			quest.description = "Defend a location against overwhelming odds."
			quest.min_total_defense = character.defense
			quest.min_total_health = character.health
		Character.CharacterClass.HEALER:
			quest.description = "Save lives in a difficult medical emergency."
			quest.min_total_spell_power = character.spell_power
			quest.min_total_mana = character.mana
		Character.CharacterClass.SUPPORT:
			quest.description = "Complete a challenging diplomatic mission."
			quest.min_substat_requirement = character.diplomacy
	
	quest.base_experience = 100
	quest.gold_reward = 50
	quest.influence_reward = 25
	
	return quest
#endregion

#region Roster Counter
#TODO : Update the Roster Display Properly to display members actively on quests.  Once a quest is complete, make the character available again.  Also display current Injuries on the characters.  Update panel sizes as wellsq
func update_roster_display():
	print("Updating roster display...")
	print("GuildManager.roster size: ", GuildManager.roster.size())
	
	# Clear existing displays
	for child in roster_list.get_children():
		child.queue_free()
	
	var first = true
	for character in GuildManager.roster:
		print("Creating panel for character: ", character.character_name)
		var char_panel = create_character_panel(character)
		roster_list.add_child(char_panel)
		adventurer_inspection_panel.inspect_character(character)
		first = false
		
	

func create_character_panel(character: Character) -> Control:
	# Create a clickable button instead of a panel
	var panel_button = Button.new()
	panel_button.custom_minimum_size = Vector2(400, 120)
	panel_button.flat = true  # Remove default button styling
	
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
	name_label.text = "%s (%s) %s - Level %d [%s Rank]" % [
		character.character_name, character.get_class_name(), stars,
		character.level, character.get_rank_name()
	]
	name_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(name_label)
	
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
	
	# Status
	var status_label = Label.new()
	if character.is_injured():
		var injury_duration = character.get_injury_duration()
		var injury_minutes:int = injury_duration / 60
		var injury_seconds:float = injury_duration - (injury_minutes * 60)
		var display_inj = str(injury_minutes, ": ", injury_seconds)
		status_label.text = "INJURED - %s, %s" % [get_injury_name(character.injury_type), display_inj]
		status_label.modulate = Color.RED
	elif character.is_on_quest:
		status_label.text = "ON QUEST"
		status_label.modulate = Color.YELLOW
	elif character.promotion_quest_available:
		status_label.text = "READY FOR PROMOTION"
		status_label.modulate = Color.GREEN
	else:
		status_label.text = "AVAILABLE"
		status_label.modulate = Color.WHITE
	
	vbox.add_child(status_label)
	
	return panel_button

func get_injury_name(injury_type: Character.InjuryType) -> String:
	match injury_type:
		Character.InjuryType.PHYSICAL_WOUND: return "Physical Wound"
		Character.InjuryType.MENTAL_TRAUMA: return "Mental Trauma"
		Character.InjuryType.CURSED_AFFLICTION: return "Cursed"
		Character.InjuryType.EXHAUSTION: return "Exhausted"
		Character.InjuryType.POISON: return "Poisoned"
		_: return "Unknown"

func select_adventurer(character: Character):
	"""Select an adventurer and show their inspection panel"""
	# Update visual states of all character panels
	update_character_panel_states(character)
	
	if roster_inspection_panel and roster_inspection_panel.has_method("inspect_character"):
		roster_inspection_panel.visible = true
		roster_inspection_panel.inspect_character(character)

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
#endregion

#region Quest Counter
func update_quests_display():
	# Clear existing displays
	for child in available_quests_list.get_children():
		child.queue_free()
	
	for quest in GuildManager.available_quests:
		var quest_panel = create_quest_panel(quest)
		available_quests_list.add_child(quest_panel)
	
	# Wait a frame for the panels to be added to the scene tree
	await get_tree().process_frame
	
	# Auto-select first quest or validate current selection
	auto_select_first_quest()
	
	# Restore visual states if a quest is currently selected
	if current_selected_quest:
		update_quest_panel_states(current_selected_quest)

func create_quest_panel(quest: Quest) -> Control:
	# Create a clickable button instead of a panel
	var panel_button = Button.new()
	panel_button.custom_minimum_size = Vector2(450, 210)
	panel_button.flat = true  # Remove default button styling
	
	# Set anchors and size flags
	panel_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Connect the click handler
	panel_button.pressed.connect(func(): select_quest(quest))
	
	# Store quest reference for later identification
	panel_button.set_meta("quest", quest)
	
	# Create a panel inside the button for styling
	var inner_panel = Panel.new()
	inner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let button handle clicks
	panel_button.add_child(inner_panel)
	inner_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var vbox = VBoxContainer.new()
	inner_panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 3)
	
	# Quest title
	var title_label = Label.new()
	title_label.text = quest.quest_name
	title_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = quest.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	
	# Requirements
	var req_label = Label.new()
	req_label.text = "Requirements: " + quest.get_requirements_text()
	req_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(req_label)
	
	# Rewards
	var reward_label = Label.new()
	reward_label.text = "Rewards: " + quest.get_rewards_text()
	vbox.add_child(reward_label)
	
	# Duration
	var duration_label = Label.new()
	var minutes = int(quest.duration / 60)
	var seconds = int(quest.duration) % 60
	duration_label.text = "Duration: %02d:%02d" % [minutes, seconds]
	vbox.add_child(duration_label)
	
	return panel_button

func select_quest(quest: Quest):
	# If the same quest is clicked, do nothing (can't deselect, only switch to another)
	if current_selected_quest == quest:
		return
	
	# Update visual states
	update_quest_panel_states(quest)
	
	# Set the new selected quest
	current_selected_quest = quest
	current_party.clear()
	update_party_selection_display()

func update_quest_panel_states(selected_quest: Quest):
	"""Update visual states of all quest panels"""
	# Find all quest panels and update their states
	for child in available_quests_list.get_children():
		if child.has_meta("quest"):
			var quest = child.get_meta("quest")
			var inner_panel = child.get_child(0)  # The Panel inside the Button
			
			if inner_panel is Panel:
				# Use theme-based selection method
				if quest == selected_quest:
					# Selected state: use the "selected" theme variation
					inner_panel.add_theme_stylebox_override("panel", get_theme_stylebox("selected", "QuestPanel"))
				else:
					# Unselected state: use the default "panel" theme variation
					inner_panel.add_theme_stylebox_override("panel", get_theme_stylebox("panel", "QuestPanel"))



func auto_select_first_quest():
	"""Auto-select the first available quest if none is currently selected"""
	if not current_selected_quest and not GuildManager.available_quests.is_empty():
		var first_quest = GuildManager.available_quests[0]
		select_quest(first_quest)
	elif current_selected_quest:
		# Ensure the currently selected quest is still in the available list
		var quest_still_available = false
		for quest in GuildManager.available_quests:
			if quest == current_selected_quest:
				quest_still_available = true
				break
		
		# If current quest is no longer available, select first available quest
		if not quest_still_available and not GuildManager.available_quests.is_empty():
			var first_quest = GuildManager.available_quests[0]
			select_quest(first_quest)
		elif not quest_still_available:
			# No quests available, clear selection
			current_selected_quest = null

func reset_quest_tab_to_default():
	"""Reset the quest tab to its default state with no quest selected"""
	# Clear current selections
	current_selected_quest = null
	current_party.clear()
		
	# Clear quest info display
	quest_info_label.text = "Select a quest to view details"
	
	# Reset stats comparison table to show "Select a quest first"
	if stats_comparison_table and stats_comparison_table.has_method("clear_data"):
		stats_comparison_table.clear_data()
	
	# Clear party lists
	for child in party_list.get_children():
		child.queue_free()
	for child in assigned_members_panel.get_children():
		child.queue_free()

func update_party_selection_display():
	if not current_selected_quest:
		return
	
	# Make single call to get available characters
	var available_chars = GuildManager.get_available_characters()
	
	# Update party selection panel with optimized data flow
	update_party_selection_right_panel(available_chars)

func update_party_selection_right_panel(available_chars: Array):
	# Clear existing displays
	for child in party_list.get_children():
		child.queue_free()
	for child in assigned_members_panel.get_children():
		child.queue_free()
	
	# Update quest info
	quest_info_label.text = current_selected_quest.description
	
	# Update stats comparison table
	update_stats_comparison_table()
	
	# Display available characters
	update_available_characters_display(available_chars)
	
	# Display current party in dedicated panel
	update_assigned_members_display()
	
	# Update start button state
	update_start_quest_button_state()

func update_stats_comparison_table():
	"""Update the stats comparison table with quest requirements and current party stats"""
	if not stats_comparison_table or not current_selected_quest:
		return
	
	# Get quest requirements
	var quest_requirements = get_quest_stat_requirements()
	
	# Get current party stats
	var party_stats = get_current_party_total_stats()
	
	# Update the table
	if stats_comparison_table.has_method("update_quest_requirements"):
		stats_comparison_table.update_quest_requirements(quest_requirements)
	if stats_comparison_table.has_method("update_party_stats"):
		stats_comparison_table.update_party_stats(party_stats)

func get_quest_stat_requirements() -> Dictionary:
	"""Extract stat requirements from the current quest"""
	if not current_selected_quest:
		return {}
	
	var requirements = {}
	
	# Core stats
	if current_selected_quest.min_total_health > 0:
		requirements["health"] = current_selected_quest.min_total_health
	if current_selected_quest.min_total_defense > 0:
		requirements["defense"] = current_selected_quest.min_total_defense
	if current_selected_quest.min_total_attack_power > 0:
		requirements["attack_power"] = current_selected_quest.min_total_attack_power
	if current_selected_quest.min_total_spell_power > 0:
		requirements["spell_power"] = current_selected_quest.min_total_spell_power
	
	# Class requirements (use 1 for true, 0 for false)
	if current_selected_quest.required_tank:
		requirements["required_tank"] = 1
	if current_selected_quest.required_healer:
		requirements["required_healer"] = 1
	if current_selected_quest.required_support:
		requirements["required_support"] = 1
	if current_selected_quest.required_attacker:
		requirements["required_attacker"] = 1
	
	# Sub-stats from quest type
	if current_selected_quest.min_substat_requirement > 0:
		match current_selected_quest.quest_type:
			Quest.QuestType.GATHERING:
				requirements["gathering"] = current_selected_quest.min_substat_requirement
			Quest.QuestType.HUNTING_TRAPPING:
				requirements["hunting_trapping"] = current_selected_quest.min_substat_requirement
			Quest.QuestType.DIPLOMACY:
				requirements["diplomacy"] = current_selected_quest.min_substat_requirement
			Quest.QuestType.CARAVAN_GUARDING:
				requirements["caravan_guarding"] = current_selected_quest.min_substat_requirement
			Quest.QuestType.ESCORTING:
				requirements["escorting"] = current_selected_quest.min_substat_requirement
			Quest.QuestType.STEALTH:
				requirements["stealth"] = current_selected_quest.min_substat_requirement
			Quest.QuestType.ODD_JOBS:
				requirements["odd_jobs"] = current_selected_quest.min_substat_requirement
	
	return requirements

func get_current_party_total_stats() -> Dictionary:
	"""Calculate total stats for the current party"""
	var total_stats = {}
	
	# Initialize all stats to 0
	var stat_keys = ["health", "defense", "mana", "spell_power", "attack_power", "movement_speed", "luck",
					 "gathering", "hunting_trapping", "diplomacy", "caravan_guarding", "escorting", "stealth", "odd_jobs"]
	
	for stat in stat_keys:
		total_stats[stat] = 0
	
	# Initialize class coverage to 0 (no classes available)
	total_stats["required_tank"] = 0
	total_stats["required_healer"] = 0
	total_stats["required_support"] = 0
	total_stats["required_attacker"] = 0
	
	if current_party.is_empty():
		return total_stats
	
	# Initialize class coverage
	var has_tank = false
	var has_healer = false
	var has_support = false
	var has_attacker = false
	
	# Sum stats from all party members
	for character in current_party:
		if character:
			var char_stats = character.get_effective_stats()
			
			# Add core stats
			total_stats["health"] += char_stats.get("health", 0)
			total_stats["defense"] += char_stats.get("defense", 0)
			total_stats["mana"] += char_stats.get("mana", 0)
			total_stats["spell_power"] += char_stats.get("spell_power", 0)
			total_stats["attack_power"] += char_stats.get("attack_power", 0)
			total_stats["movement_speed"] += char_stats.get("movement_speed", 0)
			total_stats["luck"] += char_stats.get("luck", 0)
			
			# Add sub-stats directly from character
			total_stats["gathering"] += character.gathering
			total_stats["hunting_trapping"] += character.hunting_trapping
			total_stats["diplomacy"] += character.diplomacy
			total_stats["caravan_guarding"] += character.caravan_guarding
			total_stats["escorting"] += character.escorting
			total_stats["stealth"] += character.stealth
			total_stats["odd_jobs"] += character.odd_jobs
			
			# Check class coverage
			match character.character_class:
				Character.CharacterClass.TANK:
					has_tank = true
				Character.CharacterClass.HEALER:
					has_healer = true
				Character.CharacterClass.SUPPORT:
					has_support = true
				Character.CharacterClass.ATTACKER:
					has_attacker = true
	
	# Add class coverage (1 if we have the class, 0 if not)
	total_stats["required_tank"] = 1 if has_tank else 0
	total_stats["required_healer"] = 1 if has_healer else 0
	total_stats["required_support"] = 1 if has_support else 0
	total_stats["required_attacker"] = 1 if has_attacker else 0
	
	return total_stats



func update_available_characters_display(available_chars: Array):
	for character in available_chars:
		var char_panel = create_party_selection_panel(character)
		party_list.add_child(char_panel)

func update_assigned_members_display():
	if current_party.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No members assigned yet"
		empty_label.modulate = Color.GRAY
		assigned_members_panel.add_child(empty_label)
	else:
		# Show current party stats summary
		var stats_summary = current_selected_quest.calculate_party_stats(current_party)
		var stats_label = Label.new()
		stats_label.text = "Party Total: HP:%d DEF:%d ATK:%d SPL:%d" % [
			stats_summary.health, stats_summary.defense, 
			stats_summary.attack_power, stats_summary.spell_power
		]
		stats_label.add_theme_font_size_override("font_size", 10)
		
		# Color code based on requirements
		var assignment_check = current_selected_quest.can_assign_party(current_party)
		stats_label.modulate = Color.GREEN if assignment_check.can_assign else Color.RED
		assigned_members_panel.add_child(stats_label)
		
		# Show individual party members
		for character in current_party:
			var party_member_panel = create_party_member_panel(character)
			assigned_members_panel.add_child(party_member_panel)

# Keep this for backwards compatibility with existing party list
func update_current_party_display():
	var party_label = Label.new()
	party_label.text = "\n--- CURRENT PARTY ---"
	party_label.add_theme_font_size_override("font_size", 12)
	party_list.add_child(party_label)
	
	if current_party.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No characters selected"
		empty_label.modulate = Color.GRAY
		party_list.add_child(empty_label)
	else:
		for character in current_party:
			var party_member_panel = create_party_member_panel(character)
			party_list.add_child(party_member_panel)

func update_start_quest_button_state():
	var assignment_check = current_selected_quest.can_assign_party(current_party)
	start_quest_button.disabled = not assignment_check.can_assign
	start_quest_button.text = "Start Quest" if assignment_check.can_assign else "Cannot Start: " + str(assignment_check.reasons[0] if not assignment_check.reasons.is_empty() else "Unknown")

func create_party_selection_panel(character: Character) -> Control:
	var hbox = HBoxContainer.new()
	
	var info_label = Label.new()
	info_label.text = "%s (%s) Lvl %d" % [character.character_name, character.get_class_name(), character.level]
	info_label.custom_minimum_size.x = 200
	hbox.add_child(info_label)
	
	var add_button = Button.new()
	add_button.text = "Add to Party"
	add_button.disabled = character in current_party or current_party.size() >= 4
	add_button.pressed.connect(func(): add_to_party(character))
	hbox.add_child(add_button)
	
	return hbox

func create_party_member_panel(character: Character) -> Control:
	var hbox = HBoxContainer.new()
	
	hbox.size_flags_horizontal = Control.SIZE_EXPAND
	
	var info_label = Label.new()
	info_label.text = "%s (%s) Lvl %d" % [character.character_name, character.get_class_name(), character.level]
	info_label.custom_minimum_size.x = 200
	hbox.add_child(info_label)
	
	var remove_button = Button.new()
	remove_button.text = "Remove"
	remove_button.pressed.connect(func(): remove_from_party(character))
	hbox.add_child(remove_button)
	
	return hbox

func add_to_party(character: Character):
	if character not in current_party and current_party.size() < 4:
		current_party.append(character)
		# Use optimized update - get data once and pass it through
		var available_chars = GuildManager.get_available_characters()
		update_party_selection_right_panel(available_chars)

func remove_from_party(character: Character):
	current_party.erase(character)
	# Use optimized update - get data once and pass it through
	var available_chars = GuildManager.get_available_characters()
	update_party_selection_right_panel(available_chars)
#endregion

#region Recruitment Counter
func update_recruitment_display():
	# Clear existing displays
	for child in available_recruits_list.get_children():
		child.queue_free()
	
	for recruit in GuildManager.available_recruits:
		var recruit_panel = create_recruit_panel(recruit)
		available_recruits_list.add_child(recruit_panel)
	
	# Initialize UI state
	current_selected_recruit = null
	selected_recruit_panel = null
	update_recruitment_right_panel()

func create_recruit_panel(recruit: Character) -> Control:
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
	var title = Label.new()
	title.text = "Current Resources"
	title.add_theme_font_size_override("font_size", 14)
	current_resources_panel.add_child(title)
	
	for resource_name in resource_items:
		var label = Label.new()
		label.text = "%s: %s" % [resource_name, resource_items[resource_name]]
		current_resources_panel.add_child(label)

func update_cost_display(cost: Dictionary):
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


func _get_resources() -> Dictionary :
	var resources = GuildManager.get_guild_status_summary().resources
	return resources

#endregion

#region Town Map
func update_town_map_display():
	# Clear existing map content (but preserve the TownMapVbox structure)
	var town_map_content = town_map_container.get_node_or_null("TownMapVbox/TownMapContent")
	if town_map_content:
		for child in town_map_content.get_children():
			child.queue_free()
	
	# Create a simple 5x5 grid for town facilities
	var grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	
	if town_map_content:
		town_map_content.add_child(grid)
	else:
		# Fallback to old behavior if structure not found
		town_map_container.add_child(grid)
	
	var facilities = [
		{"name": "Guild Hall", "unlocked": true, "action": show_main_hall},
		{"name": "Roster", "unlocked": true, "action": show_roster_tab},
		{"name": "Quests", "unlocked": true, "action": show_quests_tab},
		{"name": "Recruitment", "unlocked": true, "action": show_recruitment_tab},
		{"name": "Healer's Guild", "unlocked": false, "action": null},
		{"name": "Armory", "unlocked": false, "action": null},
		{"name": "Market", "unlocked": false, "action": null},
		{"name": "Training Grounds", "unlocked": false, "action": null},
		{"name": "Library", "unlocked": false, "action": null},
		{"name": "Workshop", "unlocked": false, "action": null}
	]
	
	for i in range(25):
		var button = Button.new()
		button.custom_minimum_size = Vector2(80, 60)
		
		if i < facilities.size():
			var facility = facilities[i]
			button.text = facility.name
			button.disabled = not facility.unlocked
			if facility.action:
				button.pressed.connect(facility.action)
		else:
			button.text = "Empty"
			button.disabled = true
		
		grid.add_child(button)
#endregion

#region Signal Handlers
# SignalBus signal handlers
func _on_character_recruited(character: Character):
	print("SignalBus: Character recruited: ", character.character_name)
	update_ui()

func _on_quest_started(quest: Quest):
	print("SignalBus: Quest started: ", quest.quest_name)
	
	# Trigger notification
	SignalBus.quest_started_notification.emit(quest.quest_name)
	
	# Reset quest tab to default state
	reset_quest_tab_to_default()
	
	# Refresh available quests list
	update_quests_display()
	update_ui()

func _on_quest_completed(quest: Quest):
	print("SignalBus: Quest completed: ", quest.quest_name)
	
	# Trigger notification instead of immediate popup
	SignalBus.quest_completed_notification.emit(quest.quest_name)
	
	# Mark characters as no longer on quest but don't show results yet
	for character in quest.assigned_party:
		character.is_on_quest = false
	
	# Update UI to show completion button and completed quests display
	update_ui()
	update_completed_quests_display()

func _on_emergency_quest_available(requirements: Dictionary):
	_show_emergency_quest_popup(requirements)

# GuildManager signal handlers (relay to SignalBus)
func _on_guild_manager_character_recruited(character: Character):
	SignalBus.character_recruited.emit(character)

func _on_guild_manager_quest_started(quest: Quest):
	SignalBus.quest_started.emit(quest)

func _on_guild_manager_quest_completed(quest: Quest):
	SignalBus.quest_completed.emit(quest)

func _on_guild_manager_emergency_quest(requirements: Dictionary):
	SignalBus.emergency_quest_available.emit(requirements)

func _on_character_injured(character: Character):
	# Emit injury notification with character name and injury type
	var injury_name = get_injury_name(character.injury_type)
	SignalBus.character_injured_notification.emit(character.character_name, injury_name)

# Button signal handlers
func _on_start_quest_pressed():
	if current_selected_quest and not current_party.is_empty():
		var result = GuildManager.start_quest(current_selected_quest, current_party)
		if not result.success:
			_show_error_popup(result.message)

func _on_recruit_selected_character():
	if current_selected_recruit:
		var result = GuildManager.recruit_character(current_selected_recruit)
		if result.success:
			print(result.message)
			current_selected_recruit = null
			selected_recruit_panel = null
			update_recruitment_display()
		else:
			_show_error_popup(result.message)

func _on_refresh_recruits_pressed():
	var result = GuildManager.force_recruit_refresh()
	if result.success:
		print(result.message)
		update_recruitment_display()
	else:
		_show_error_popup(result.message)

func _on_save_pressed():
	GuildManager.save_game()
	SignalBus.game_saved.emit()
	print("Game saved!")

func _on_load_pressed():
	GuildManager.load_game()
	SignalBus.game_loaded.emit()
	update_ui()
	print("Game loaded!")

func _on_new_game_pressed():
	_show_new_game_confirmation()

# UI Scaling functions
func _on_scale_05_pressed():
	"""Set UI scale to 0.5"""
	get_tree().root.content_scale_factor = 0.5
	
	# Update UIScalingManager if available
	if UIScalingManager:
		UIScalingManager.set_scaling_mode(UIScalingManager.ScalingMode.PROPORTIONAL)
	
	print("UI Scale set to: 0.5")
	update_scale_button_states(0.5)

func _on_scale_075_pressed():
	"""Set UI scale to 0.75"""
	get_tree().root.content_scale_factor = 0.75
	
	# Update UIScalingManager if available
	if UIScalingManager:
		UIScalingManager.set_scaling_mode(UIScalingManager.ScalingMode.PROPORTIONAL)
	
	print("UI Scale set to: 0.75")
	update_scale_button_states(0.75)

func _on_scale_1_pressed():
	"""Set UI scale to 1.0"""
	get_tree().root.content_scale_factor = 1.0
	
	# Update UIScalingManager if available
	if UIScalingManager:
		UIScalingManager.set_scaling_mode(UIScalingManager.ScalingMode.PROPORTIONAL)
	
	print("UI Scale set to: 1.0")
	update_scale_button_states(1.0)

func _on_scale_15_pressed():
	"""Set UI scale to 1.5"""
	get_tree().root.content_scale_factor = 1.5
	
	# Update UIScalingManager if available
	if UIScalingManager:
		UIScalingManager.set_scaling_mode(UIScalingManager.ScalingMode.PROPORTIONAL)
	
	print("UI Scale set to: 1.5")
	update_scale_button_states(1.5)

func _on_scale_2_pressed():
	"""Set UI scale to 2.0"""
	get_tree().root.content_scale_factor = 2.0
	
	# Update UIScalingManager if available
	if UIScalingManager:
		UIScalingManager.set_scaling_mode(UIScalingManager.ScalingMode.PROPORTIONAL)
	
	print("UI Scale set to: 2.0")
	update_scale_button_states(2.0)

func _on_scale_3_pressed():
	"""Set UI scale to 3.0"""
	get_tree().root.content_scale_factor = 3.0
	
	# Update UIScalingManager if available
	if UIScalingManager:
		UIScalingManager.set_scaling_mode(UIScalingManager.ScalingMode.PROPORTIONAL)
	
	print("UI Scale set to: 3.0")
	update_scale_button_states(3.0)

func update_scale_button_states(current_scale: float):
	"""Update button states to show which scale is currently active"""
	# Reset all buttons to normal state
	scale_05_button.flat = false
	scale_075_button.flat = false
	scale_1_button.flat = false
	scale_15_button.flat = false
	scale_2_button.flat = false
	scale_3_button.flat = false
	
	# Set the current scale button to flat (pressed appearance)
	if abs(current_scale - 0.5) < 0.01:
		scale_05_button.flat = true
	elif abs(current_scale - 0.75) < 0.01:
		scale_075_button.flat = true
	elif abs(current_scale - 1.0) < 0.01:
		scale_1_button.flat = true
	elif abs(current_scale - 1.5) < 0.01:
		scale_15_button.flat = true
	elif abs(current_scale - 2.0) < 0.01:
		scale_2_button.flat = true
	elif abs(current_scale - 3.0) < 0.01:
		scale_3_button.flat = true



# Popup functions
func _show_error_popup(message: String):
	var popup = AcceptDialog.new()
	add_child(popup)
	popup.dialog_text = message
	popup.title = "Error"
	popup.popup_centered()

func _show_quest_completion_popup(quest: Quest):
	var popup = AcceptDialog.new()
	add_child(popup)
	
	var party_info = quest.get_party_display_info()
	var success_count = 0
	var party_text = ""
	
	for member in party_info:
		party_text += "%s: %s\n" % [member.name, "SUCCESS" if member.status == "✓" else "FAILED"]
		if member.status == "✓":
			success_count += 1
	
	for _char in quest.assigned_party:
		_char.is_on_quest = false
	
	var success_rate = float(success_count) / party_info.size()
	var result_text = "QUEST COMPLETED!\n\n"
	result_text += quest.quest_name + "\n\n"
	result_text += "Party Results:\n" + party_text + "\n"
	result_text += "Overall Success: %.0f%%\n\n" % (success_rate * 100)
	result_text += "Rewards: " + quest.get_rewards_text()
	
	popup.dialog_text = result_text
	popup.title = "Quest Results"
	popup.popup_centered()

func _show_emergency_quest_popup(requirements: Dictionary):
	var popup = AcceptDialog.new()
	add_child(popup)
	
	popup.dialog_text = "EMERGENCY QUEST AVAILABLE!\n\n" + requirements.name + "\n\n" + requirements.description + "\n\nReward: " + requirements.unlock_description
	popup.title = "Emergency Quest"
	popup.popup_centered()

func _on_accept_quest_results(quest: Quest):
	"""Handle when player clicks 'Accept Results' for a completed quest"""
	# Show the quest completion popup
	_show_quest_completion_popup(quest)
	
	# Remove quest from active quests
	GuildManager.remove_completed_quest(quest)
	
	# Update the active quests display
	update_active_quests_display()
	
	# Update the completed quests display
	update_completed_quests_display()

func _show_new_game_confirmation():
	var confirm = ConfirmationDialog.new()
	add_child(confirm)
	confirm.dialog_text = "Are you sure you want to start a new game? This will delete your current save file."
	confirm.title = "New Game"
	confirm.confirmed.connect(func(): 
		GuildManager.clear_save_file()
		update_ui()
		print("New game started!")
	)
	confirm.popup_centered()
#endregion
