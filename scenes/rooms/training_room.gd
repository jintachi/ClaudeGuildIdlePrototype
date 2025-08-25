class_name TrainingRoom
extends BaseRoom

# Training Course Types
enum TrainingType {
	COMBAT_BASIC,
	COMBAT_ADVANCED,
	COMBAT_MASTER,
	SOCIAL_BASIC,
	SOCIAL_ADVANCED,
	SOCIAL_MASTER,
	GATHERING_BASIC,
	GATHERING_ADVANCED,
	GATHERING_MASTER,
	MAGIC_BASIC,
	MAGIC_ADVANCED,
	MAGIC_MASTER,
	STEALTH_BASIC,
	STEALTH_ADVANCED,
	STEALTH_MASTER
}

# Training Course Data Structure
class TrainingCourse:
	var id: String
	var name: String
	var description: String
	var training_type: TrainingType
	var difficulty: String  # "Basic", "Advanced", "Master"
	var cost_gold: int
	var cost_influence: int
	var cost_materials: int
	var potential_cost: int
	var success_rate: float
	var stat_focus: String  # "attack", "defense", "mana", etc.
	var substat_focus: String  # "gathering", "social", "stealth", etc.
	
	func _init(course_id: String, course_name: String, course_desc: String, 
			   type: TrainingType, diff: String, gold: int, influence: int, 
			   materials: int, potential: int, success: float, stat: String, substat: String):
		id = course_id
		name = course_name
		description = course_desc
		training_type = type
		difficulty = diff
		cost_gold = gold
		cost_influence = influence
		cost_materials = materials
		potential_cost = potential
		success_rate = success
		stat_focus = stat
		substat_focus = substat

# UI References
@export var character_grid: GridContainer
@export var course_list: VBoxContainer
@export var selected_character_panel: Panel
@export var course_details_panel: Panel
@export var reroll_button: Button
@export var start_training_button: Button
@export var potential_display: Label
@export var gold_display: Label
@export var influence_display: Label
@export var materials_display: Label

# Auto-assign UI references
@onready var _character_grid = $MainContainer/ContentContainer/LeftPanel/ScrollContainer/CharacterGrid
@onready var _course_list = $MainContainer/ContentContainer/MiddlePanel/ScrollContainer/CourseList
@onready var _selected_character_panel = $MainContainer/ContentContainer/LeftPanel/SelectedCharacterPanel
@onready var _course_details_panel = $MainContainer/ContentContainer/RightPanel/CourseDetailsPanel
@onready var _reroll_button = $MainContainer/ContentContainer/RightPanel/VBoxContainer/RerollButton
@onready var _start_training_button = $MainContainer/ContentContainer/RightPanel/VBoxContainer/StartTrainingButton

# Training System Variables
var available_courses: Array[TrainingCourse] = []
var selected_character: Character = null
var selected_course: TrainingCourse = null
var reroll_cost: int = 10
var reroll_count: int = 0
var max_reroll_cost: int = 100

# Course Templates
var course_templates = {
	TrainingType.COMBAT_BASIC: {
		"names": ["Basic Combat Training", "Weapon Fundamentals", "Combat Stance Practice"],
		"descriptions": ["Learn the basics of combat and weapon handling", "Master fundamental weapon techniques", "Practice proper combat stances and footwork"],
		"stat_focus": "attack_power",
		"substat_focus": "combat"
	},
	TrainingType.COMBAT_ADVANCED: {
		"names": ["Advanced Combat Techniques", "Weapon Mastery", "Tactical Combat"],
		"descriptions": ["Advanced combat techniques and strategies", "Master complex weapon combinations", "Learn tactical combat positioning"],
		"stat_focus": "attack_power",
		"substat_focus": "combat"
	},
	TrainingType.COMBAT_MASTER: {
		"names": ["Combat Mastery", "Weapon Legend", "Battle Tactics"],
		"descriptions": ["Master-level combat training", "Legendary weapon techniques", "Advanced battle tactics and strategy"],
		"stat_focus": "attack_power",
		"substat_focus": "combat"
	},
	TrainingType.SOCIAL_BASIC: {
		"names": ["Basic Diplomacy", "Conversation Skills", "Etiquette Training"],
		"descriptions": ["Learn basic diplomatic skills", "Improve conversation and communication", "Master proper etiquette"],
		"stat_focus": "mana",
		"substat_focus": "social"
	},
	TrainingType.SOCIAL_ADVANCED: {
		"names": ["Advanced Negotiation", "Leadership Skills", "Public Speaking"],
		"descriptions": ["Advanced negotiation techniques", "Develop leadership abilities", "Master public speaking"],
		"stat_focus": "mana",
		"substat_focus": "social"
	},
	TrainingType.SOCIAL_MASTER: {
		"names": ["Master Diplomacy", "Political Maneuvering", "Inspirational Leadership"],
		"descriptions": ["Master-level diplomatic skills", "Complex political maneuvering", "Inspirational leadership techniques"],
		"stat_focus": "mana",
		"substat_focus": "social"
	},
	TrainingType.GATHERING_BASIC: {
		"names": ["Basic Gathering", "Resource Identification", "Harvesting Techniques"],
		"descriptions": ["Learn basic resource gathering", "Identify valuable resources", "Master harvesting techniques"],
		"stat_focus": "luck",
		"substat_focus": "gathering"
	},
	TrainingType.GATHERING_ADVANCED: {
		"names": ["Advanced Gathering", "Rare Resource Location", "Efficient Harvesting"],
		"descriptions": ["Advanced gathering techniques", "Locate rare resources", "Maximize harvesting efficiency"],
		"stat_focus": "luck",
		"substat_focus": "gathering"
	},
	TrainingType.GATHERING_MASTER: {
		"names": ["Master Gathering", "Legendary Resource Finding", "Perfect Harvesting"],
		"descriptions": ["Master-level gathering skills", "Find legendary resources", "Perfect harvesting techniques"],
		"stat_focus": "luck",
		"substat_focus": "gathering"
	},
	TrainingType.MAGIC_BASIC: {
		"names": ["Basic Magic", "Spell Fundamentals", "Mana Control"],
		"descriptions": ["Learn basic magical techniques", "Master spell fundamentals", "Control mana flow"],
		"stat_focus": "spell_power",
		"substat_focus": "magic"
	},
	TrainingType.MAGIC_ADVANCED: {
		"names": ["Advanced Magic", "Complex Spells", "Mana Mastery"],
		"descriptions": ["Advanced magical techniques", "Cast complex spells", "Master mana manipulation"],
		"stat_focus": "spell_power",
		"substat_focus": "magic"
	},
	TrainingType.MAGIC_MASTER: {
		"names": ["Master Magic", "Legendary Spells", "Mana Legend"],
		"descriptions": ["Master-level magical techniques", "Cast legendary spells", "Legendary mana control"],
		"stat_focus": "spell_power",
		"substat_focus": "magic"
	},
	TrainingType.STEALTH_BASIC: {
		"names": ["Basic Stealth", "Silent Movement", "Shadow Techniques"],
		"descriptions": ["Learn basic stealth techniques", "Master silent movement", "Use shadow techniques"],
		"stat_focus": "movement_speed",
		"substat_focus": "stealth"
	},
	TrainingType.STEALTH_ADVANCED: {
		"names": ["Advanced Stealth", "Invisibility Techniques", "Silent Assassination"],
		"descriptions": ["Advanced stealth techniques", "Master invisibility", "Silent assassination methods"],
		"stat_focus": "movement_speed",
		"substat_focus": "stealth"
	},
	TrainingType.STEALTH_MASTER: {
		"names": ["Master Stealth", "Shadow Walking", "Perfect Invisibility"],
		"descriptions": ["Master-level stealth techniques", "Walk through shadows", "Perfect invisibility"],
		"stat_focus": "movement_speed",
		"substat_focus": "stealth"
	}
}

func _ready():
	super._ready()
	setup_ui_connections()
	generate_training_courses()
	update_ui_state()

func setup_ui_connections():
	# Assign auto-assigned references to export variables for compatibility
	character_grid = _character_grid
	course_list = _course_list
	selected_character_panel = _selected_character_panel
	course_details_panel = _course_details_panel
	reroll_button = _reroll_button
	start_training_button = _start_training_button
	
	# connected through editor - not needed
	## Connect button signals
	#if reroll_button:
		#reroll_button.pressed.connect(_on_reroll_button_pressed)
	#if start_training_button:
		#start_training_button.pressed.connect(_on_start_training_button_pressed)

func generate_training_courses():
	"""Generate 6 random training courses"""
	available_courses.clear()
	
	var course_types = TrainingType.values()
	var difficulties = ["Basic", "Advanced", "Master"]
	
	for i in range(6):
		var course_type = course_types[randi() % course_types.size()]
		var difficulty = difficulties[randi() % difficulties.size()]
		
		var template = course_templates[course_type]
		var course_name = template.names[randi() % template.names.size()]
		var course_desc = template.descriptions[randi() % template.descriptions.size()]
		
		# Calculate costs based on difficulty
		var base_gold = 5 if difficulty == "Basic" else 15 if difficulty == "Advanced" else 30
		var base_influence = 2 if difficulty == "Basic" else 5 if difficulty == "Advanced" else 10
		var base_materials = 1 if difficulty == "Basic" else 3 if difficulty == "Advanced" else 6
		var base_potential = 1 if difficulty == "Basic" else 2 if difficulty == "Advanced" else 3
		
		# Add some randomization to costs
		base_gold += randi_range(-2, 3)
		base_influence += randi_range(-1, 2)
		base_materials += randi_range(-1, 1)
		
		# Ensure minimum costs
		base_gold = max(1, base_gold)
		base_influence = max(0, base_influence)
		base_materials = max(0, base_materials)
		
		var success_rate = 0.8 if difficulty == "Basic" else 0.6 if difficulty == "Advanced" else 0.4
		
		var course = TrainingCourse.new(
			"course_%d" % i,
			course_name,
			course_desc,
			course_type,
			difficulty,
			base_gold,
			base_influence,
			base_materials,
			base_potential,
			success_rate,
			template.stat_focus,
			template.substat_focus
		)
		
		available_courses.append(course)
	
	update_course_list()

func update_course_list():
	"""Update the course list UI"""
	if not course_list:
		return
	
	# Clear existing course items
	for child in course_list.get_children():
		child.queue_free()
	
	# Ensure course list has proper sizing
	course_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	course_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Create course items
	for course in available_courses:
		var course_item = create_course_item(course)
		course_list.add_child(course_item)

func create_course_item(course: TrainingCourse) -> Panel:
	"""Create a UI panel for a training course"""
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 80)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)
	
	# Course header
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var name_label = Label.new()
	name_label.text = course.name
	name_label.add_theme_font_size_override("font_size", 16)
	header.add_child(name_label)
	
	var difficulty_label = Label.new()
	difficulty_label.text = course.difficulty
	difficulty_label.add_theme_font_size_override("font_size", 12)
	header.add_child(difficulty_label)
	
	# Course description
	var desc_label = Label.new()
	desc_label.text = course.description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	
	# Course costs
	var costs_container = HBoxContainer.new()
	vbox.add_child(costs_container)
	
	if course.cost_gold > 0:
		var gold_label = Label.new()
		gold_label.text = "Gold: %d" % course.cost_gold
		gold_label.add_theme_font_size_override("font_size", 10)
		costs_container.add_child(gold_label)
	
	if course.cost_influence > 0:
		var influence_label = Label.new()
		influence_label.text = "Influence: %d" % course.cost_influence
		influence_label.add_theme_font_size_override("font_size", 10)
		costs_container.add_child(influence_label)
	
	if course.cost_materials > 0:
		var materials_label = Label.new()
		materials_label.text = "Materials: %d" % course.cost_materials
		materials_label.add_theme_font_size_override("font_size", 10)
		costs_container.add_child(materials_label)
	
	var potential_label = Label.new()
	potential_label.text = "Potential: %d" % course.potential_cost
	potential_label.add_theme_font_size_override("font_size", 10)
	costs_container.add_child(potential_label)
	
	# Make panel clickable
	panel.gui_input.connect(_on_course_panel_gui_input.bind(course))
	
	return panel

func _on_course_panel_gui_input(event: InputEvent, course: TrainingCourse):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_course(course)

func select_course(course: TrainingCourse):
	"""Select a training course"""
	selected_course = course
	update_course_details()
	update_selected_character_panel()  # Update to show course cost
	update_ui_state()

func update_course_details():
	"""Update the course details panel"""
	if not course_details_panel or not selected_course:
		return
	
	# Clear existing content
	for child in course_details_panel.get_children():
		child.queue_free()
	
	var vbox = VBoxContainer.new()
	course_details_panel.add_child(vbox)
	
	# Course name
	var name_label = Label.new()
	name_label.text = selected_course.name
	name_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(name_label)
	
	# Course description
	var desc_label = Label.new()
	desc_label.text = selected_course.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	
	# Success rate
	var success_label = Label.new()
	success_label.text = "Success Rate: %.0f%%" % (selected_course.success_rate * 100)
	vbox.add_child(success_label)
	
	# Focus areas
	var focus_label = Label.new()
	focus_label.text = "Focus: %s, %s" % [selected_course.stat_focus, selected_course.substat_focus]
	vbox.add_child(focus_label)
	
	# Compatibility info (if character is selected)
	if selected_character:
		var compatibility_bonus = calculate_compatibility_bonus(selected_character, selected_course)
		var compatibility_label = Label.new()
		compatibility_label.text = "Compatibility Bonus: +%d" % compatibility_bonus
		if compatibility_bonus > 0:
			compatibility_label.modulate = Color.GREEN
		vbox.add_child(compatibility_label)

func update_resource_displays():
	"""Update resource display labels - now handled in character panels"""
	# Resource displays are now shown in individual character panels
	# and in the selected character panel
	pass

func get_character_potential(character: Character) -> int:
	"""Get character's available training potential"""
	return character.get_available_potential()

func update_ui_state():
	"""Update UI state based on selections and resources"""
	if not start_training_button:
		return
	
	var can_start = selected_character != null and selected_course != null
	
	if can_start:
		# Check if character has enough potential
		var character_potential = get_character_potential(selected_character)
		can_start = can_start and character_potential >= selected_course.potential_cost
		
		# Check if guild has enough resources
		can_start = can_start and GuildManager.gold >= selected_course.cost_gold
		can_start = can_start and GuildManager.influence >= selected_course.cost_influence
		can_start = can_start and GuildManager.building_materials >= selected_course.cost_materials
	
	start_training_button.disabled = not can_start
	
	# Update reroll button
	if reroll_button:
		var can_reroll = GuildManager.gold >= reroll_cost
		reroll_button.disabled = not can_reroll
		reroll_button.text = "Reroll Courses (%d gold)" % reroll_cost

func _on_reroll_button_pressed():
	"""Reroll training courses"""
	if GuildManager.gold >= reroll_cost:
		GuildManager.gold -= reroll_cost
		reroll_count += 1
		reroll_cost = min(max_reroll_cost, 10 + (reroll_count * 5))
		
		generate_training_courses()
		update_ui_state()

func _on_start_training_button_pressed():
	"""Start training for selected character and course"""
	if not selected_character or not selected_course:
		return
	
	# Check resources again
	var character_potential = get_character_potential(selected_character)
	if character_potential < selected_course.potential_cost:
		return
	
	if GuildManager.gold < selected_course.cost_gold or \
	   GuildManager.influence < selected_course.cost_influence or \
	   GuildManager.building_materials < selected_course.cost_materials:
		return
	
	# Use character's potential
	if not selected_character.use_potential(selected_course.potential_cost):
		return
	
	# Deduct resources
	GuildManager.gold -= selected_course.cost_gold
	GuildManager.influence -= selected_course.cost_influence
	GuildManager.building_materials -= selected_course.cost_materials
	
	# Calculate training success
	var success = randf() < selected_course.success_rate
	
	# Apply training results
	if success:
		apply_training_success(selected_character, selected_course)
	else:
		apply_training_failure(selected_character, selected_course)
	
	# Reset reroll cost
	reroll_cost = 10
	reroll_count = 0
	
	# Regenerate courses
	generate_training_courses()
	
	# Update UI
	update_ui_state()
	update_character_grid()
	update_selected_character_panel()
	
	# Show training result notification
	show_training_result(success, selected_character, selected_course)

func apply_training_success(character: Character, course: TrainingCourse):
	"""Apply successful training results"""
	# Calculate character compatibility bonus
	var compatibility_bonus = calculate_compatibility_bonus(character, course)
	
	# Stat improvement
	var stat_gain = 1
	if course.difficulty == "Advanced":
		stat_gain = 2
	elif course.difficulty == "Master":
		stat_gain = 3
	
	# Apply compatibility bonus
	stat_gain += compatibility_bonus
	
	# Apply stat gain based on focus
	match course.stat_focus:
		"attack_power":
			character.attack_power += stat_gain
		"defense":
			character.defense += stat_gain
		"mana":
			character.mana += stat_gain
		"spell_power":
			character.spell_power += stat_gain
		"movement_speed":
			character.movement_speed += stat_gain
		"luck":
			character.luck += stat_gain
	
	# Substat improvement (10% chance, increased by compatibility)
	var substat_chance = 0.1 + (compatibility_bonus * 0.05)
	if randf() < substat_chance:
		match course.substat_focus:
			"gathering":
				character.gathering_substat += 1
			"social":
				character.social_substat += 1
			"stealth":
				character.stealth_substat += 1
			"combat":
				character.combat_substat += 1
			"magic":
				character.magic_substat += 1
	
	# Apply training fatigue (reduces potential temporarily)
	apply_training_fatigue(character, course)

func calculate_compatibility_bonus(character: Character, course: TrainingCourse) -> int:
	"""Calculate character compatibility bonus for training course"""
	var bonus = 0
	
	# Class-based bonuses
	match character.character_class:
		Character.CharacterClass.TANK:
			if course.stat_focus == "defense" or course.substat_focus == "combat":
				bonus += 1
		Character.CharacterClass.HEALER:
			if course.stat_focus == "mana" or course.stat_focus == "spell_power" or course.substat_focus == "magic":
				bonus += 1
		Character.CharacterClass.SUPPORT:
			if course.substat_focus == "social" or course.stat_focus == "mana":
				bonus += 1
		Character.CharacterClass.ATTACKER:
			if course.stat_focus == "attack_power" or course.substat_focus == "combat":
				bonus += 1
	
	# Quality-based bonuses
	if character.quality == Character.Quality.THREE_STAR:
		bonus += 1
	elif character.quality == Character.Quality.TWO_STAR:
		bonus += 0.5
	
	# Rank-based bonuses
	if character.rank >= Character.Rank.A:
		bonus += 1
	
	return int(bonus)

func apply_training_fatigue(character: Character, course: TrainingCourse):
	"""Apply training fatigue effects"""
	# Higher difficulty courses cause more fatigue
	var fatigue_amount = 1
	if course.difficulty == "Advanced":
		fatigue_amount = 2
	elif course.difficulty == "Master":
		fatigue_amount = 3
	
	# Reduce potential temporarily (can be restored with rest or special items)
	character.training_potential = max(0, character.training_potential - fatigue_amount)

func apply_training_failure(character: Character, course: TrainingCourse):
	"""Apply failed training results"""
	# Small stat gain even on failure (50% chance)
	if randf() < 0.5:
		var stat_gain = 1
		if course.difficulty == "Master":
			stat_gain = 2
		
		match course.stat_focus:
			"attack_power":
				character.base_attack_power += stat_gain
			"defense":
				character.base_defense += stat_gain
			"mana":
				character.base_mana += stat_gain
			"spell_power":
				character.base_spell_power += stat_gain
			"movement_speed":
				character.base_movement_speed += stat_gain
			"luck":
				character.base_luck += stat_gain

func show_training_result(success: bool, character: Character, course: TrainingCourse):
	"""Show training result notification"""
	var result_text = ""
	if success:
		result_text = "%s successfully completed %s!" % [character.character_name, course.name]
	else:
		result_text = "%s struggled with %s but learned something." % [character.character_name, course.name]
	
	# Emit signal for notification system
	if SignalBus:
		SignalBus.emit_signal("show_notification", result_text, 3.0)

# Override BaseRoom methods
func setup_character_grid():
	"""Setup the character selection grid"""
	if not character_grid:
		return
	
	# Clear existing grid
	for child in character_grid.get_children():
		child.queue_free()
	
	# Ensure grid has proper sizing
	character_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Add character panels
	for character in GuildManager.roster:
		var character_panel = create_character_panel(character)
		character_grid.add_child(character_panel)

func create_character_panel(character: Character) -> Panel:
	"""Create a party selection panel for a character"""
	# Create a panel for the character in the grid - icon only design
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(48, 48)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Make panel clickable for selection
	var button = Button.new()
	button.flat = true
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(func(): select_character(character))
	panel.add_child(button)
	
	# Add character portrait
	var portrait = TextureRect.new()
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Load character portrait based on class and gender
	var portrait_path = character.portrait_path
	if ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path)
	else:
		# Use a default portrait or placeholder
		portrait.modulate = Color.GRAY
	
	button.add_child(portrait)
	
	# Store character reference
	panel.set_meta("character", character)
	
	return panel

func _on_character_panel_gui_input(event: InputEvent, character: Character):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_character(character)

func select_character(character: Character):
	"""Select a character for training"""
	selected_character = character
	update_selected_character_panel()
	update_ui_state()
	update_character_selection_visual()

func update_character_selection_visual():
	"""Update visual selection state of character panels"""
	if not character_grid:
		return
	
	for i in range(character_grid.get_child_count()):
		var panel = character_grid.get_child(i)
		var character = panel.get_meta("character", null)
		
		# Reset all panels to default state
		panel.modulate = Color.WHITE
		
		# Highlight selected character
		if selected_character and character == selected_character:
			panel.modulate = Color.YELLOW

func update_selected_character_panel():
	"""Update the selected character panel with character information"""
	if not selected_character_panel or not selected_character:
		return
	
	# Clear existing content
	for child in selected_character_panel.get_children():
		child.queue_free()
	
	var vbox = VBoxContainer.new()
	selected_character_panel.add_child(vbox)
	
	# Character name
	var name_label = Label.new()
	name_label.text = selected_character.character_name
	name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_label)
	
	# Character class and rank
	var info_label = Label.new()
	info_label.text = "%s %s" % [selected_character.get_class_name(), selected_character.get_rank_name()]
	info_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(info_label)
	
	# Potential display
	var potential_label = Label.new()
	var current_potential = get_character_potential(selected_character)
	var max_potential = selected_character.max_training_potential
	potential_label.text = "Training Potential: %d/%d" % [current_potential, max_potential]
	potential_label.add_theme_font_size_override("font_size", 12)
	
	# Color code potential
	if current_potential == 0:
		potential_label.modulate = Color.RED
	elif current_potential < max_potential * 0.5:
		potential_label.modulate = Color.ORANGE
	else:
		potential_label.modulate = Color.GREEN
	
	vbox.add_child(potential_label)
	
	# Resource costs (if course is selected)
	if selected_course:
		var costs_label = Label.new()
		costs_label.text = "Course Cost: %d potential" % selected_course.potential_cost
		costs_label.add_theme_font_size_override("font_size", 10)
		vbox.add_child(costs_label)

func update_character_grid():
	"""Update the character grid display"""
	setup_character_grid()
	update_character_selection_visual()

# Override BaseRoom abstract methods
func get_room_name() -> String:
	return "Training Room"

func get_room_description() -> String:
	return "Train your guild members to improve their stats and skills."

func on_room_entered():
	"""Called when entering the training room"""
	super.on_room_entered()
	setup_character_grid()
	update_ui_state()

func on_room_exited():
	"""Called when exiting the training room"""
	super.on_room_exited()
	selected_character = null
	selected_course = null

# Public methods for external use
func restore_character_potential(character: Character, amount: int = -1):
	"""Restore character's training potential (amount = -1 for full restore)"""
	if amount == -1:
		character.reset_potential()
	else:
		character.restore_potential(amount)
	
	# Update UI if this character is currently selected
	if selected_character == character:
		update_selected_character_panel()
		update_character_grid()
