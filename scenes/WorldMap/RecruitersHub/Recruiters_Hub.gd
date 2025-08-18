class_name RecruitersHub
extends Node

@export var scene_name : StringName = "Recruiter's Hub"
@export var back_button : Button
@export var recruit_rotation_timer: float = 0.0

@export var max_roster_size: int = 5
@export var recruit_refresh_time: float = 5 # 5 seconds for testing
@export var max_offline_rotations: int = 3 

# Recruitment Settings
@export var recruitment_quality_modifier: float = 1.0
@export var max_available_recruits: int = 3
@export var recruit_stay_duration: float = 60 # 5 Minutes

@export var scroll_con : ScrollContainer
@export var recruit_container : VBoxContainer  # The container inside the scroll container

# Track displayed recruits for dynamic management
var displayed_recruit_panels: Dictionary = {}  # Character -> Panel mapping

signal back_pressed

func _ready():
	connect_signals()
	#setup_recruit_container()
	#
	## Generate recruits if none exist
	#if GuildManager.current_recruit_list.is_empty():
		#print("No recruits found, generating...")
		#generate_recruits()
	#
	## Try to display recruits
	#call_deferred("update_ui")

func update_ui() -> void:
	create_recruit_panel()

func connect_signals() -> void :
	back_button.pressed.connect(_on_back_pressed)
	GameGlobalEvents.generate_random_recruit.connect(generate_random_recruit)
	GameGlobalEvents.generate_recruits.connect(generate_recruits)

func setup_recruit_container():
	print("=== Setting up recruit container ===")
	print("recruit_container valid: ", is_instance_valid(recruit_container))
	print("scroll_con valid: ", is_instance_valid(scroll_con))
	
	# Try to find the container automatically if not assigned
	if not is_instance_valid(recruit_container):
		print("Attempting to auto-find recruit container...")
		if is_instance_valid(scroll_con):
			var children = scroll_con.get_children()
			print("ScrollContainer children: ", children.size())
			for child in children:
				print("Child: ", child, " Type: ", child.get_class())
				if child is VBoxContainer:
					recruit_container = child
					print("Auto-assigned recruit_container: ", recruit_container)
					break
		
		# If still no container found, create one
		if not is_instance_valid(recruit_container):
			print("No VBoxContainer found, creating one...")
			if is_instance_valid(scroll_con):
				recruit_container = VBoxContainer.new()
				recruit_container.name = "RecruitList"
				scroll_con.add_child(recruit_container)
				print("Created and added new VBoxContainer: ", recruit_container)
			else:
				print("ERROR: No scroll_con found! Cannot create recruit container.")
	else:
		print("recruit_container already assigned: ", recruit_container)
	
func _on_back_pressed():
	emit_signal("back_pressed")
	GuildManager.previous_scene_before_map = scene_name
	GameGlobalEvents.scene_transition.emit(scene_name,self)

func update_recruitment_timer(delta: float):
	
	recruit_rotation_timer += delta	
	if recruit_rotation_timer >= recruit_refresh_time:
		var recruit_names = []
		for recruit in GuildManager.current_recruit_list:
			recruit_names.append(recruit.character_name)
		print("Current rec_timer: %f, Current ref_timer: %f, Current Recruit Names: %s" % 
			[recruit_rotation_timer, recruit_refresh_time, str(recruit_names)])
		#rotate_recruits()
		recruit_rotation_timer = 0.0
		update_ui()

func rotate_recruits():
	
	# Remove recruits who've stayed too long, add new ones
	var recruits_to_remove = []
	for recruit in GuildManager.current_recruit_list:
		if RNG.wrapper.randf() < 0.3:  # 30% chance each recruit leaves
			recruits_to_remove.append(recruit)
		
	for recruit in recruits_to_remove:
		GuildManager.current_recruit_list.erase(recruit)
	
	# Fill up to max recruits
	while GuildManager.current_recruit_list.size() < max_available_recruits:
		GuildManager.current_recruit_list.append(generate_random_recruit())
		
	

func force_recruit_refresh() -> Dictionary:
	var cost = {"influence": 10}
	if not can_afford_cost(cost):
		return {"success": false, "message": "Cannot afford refresh cost"}
	
	GuildManager.spend_resources(cost)
	generate_recruits()
	return {"success": true, "message": "Recruits refreshed"}


func generate_recruits():
	# Debug: Check if we have data and UI references
	print("=== Generate Recruits Called ===")
	print("Current recruit list size before clear: ", GuildManager.current_recruit_list.size())
	
	## Ensure we have a valid container before generating
	#setup_recruit_container()
	
	for i in range(max_available_recruits):
		var character = generate_random_recruit()
		GuildManager.current_recruit_list.append(character)
		
	print("=== Generate Recruits Finished ===")
	print("Current recruit list size after call: ", GuildManager.current_recruit_list.size())

func generate_random_recruit() -> Character:
	var classes = Character.CharacterClass.values()
	var char_class = classes[RNG.wrapper.randi() % classes.size()]
	
	# Apply recruitment quality modifier
	var quality_roll = RNG.wrapper.randf()
	var quality: Character.Quality = Character.Quality.ONE_STAR
	
	if quality_roll < 0.1 * recruitment_quality_modifier:
		quality = Character.Quality.THREE_STAR
	elif quality_roll < 0.3 * recruitment_quality_modifier:
		quality = Character.Quality.TWO_STAR
	else:
		quality = Character.Quality.ONE_STAR
	
	return Character.new("", char_class, quality)

func add_character_to_roster(character: Character):
	GuildManager.current_roster.append(character)
	print("Added %s to the Roster! Welcome to the Guild!" % character.character_name)

func recruit_character(character: Character) -> Dictionary:
	var result = {"success": false, "message": ""}
	
	if not character in GuildManager.current_recruit_list:
		result.message = "Character not available for recruitment"
		return result
	
	if GuildManager.guild_roster.roster.size() >= max_roster_size:
		result.message = "Roster is full"
		return result
	
	var cost = character.get_recruitment_cost()
	if not can_afford_cost(cost):
		result.message = "Cannot afford recruitment cost"
		return result
	
	# Pay the cost
	GameGlobalEvents.emit_signal("spend_resources",cost)
	
	# Add to roster
	add_character_to_roster(character)
	GuildManager.current_recruit_list.erase(character)
	
	result.success = true
	result.message = "Successfully recruited " + character.character_name
	return result

func can_afford_cost(cost: Dictionary) -> bool:
	return (GuildManager.influence >= cost.get("influence", 0) and
			GuildManager.gold >= cost.get("gold", 0) and
			GuildManager.food >= cost.get("food", 0) and
			GuildManager.armor_pieces >= cost.get("armor", 0) and
			GuildManager.weapons >= cost.get("weapons", 0))

func clear_panel() -> void:
	if is_instance_valid(recruit_container):
		for c in recruit_container.get_children():
			c.queue_free()
		displayed_recruit_panels.clear()
	return
	
func create_recruit_panel():
	print("=== create_recruit_panel called ===")
	print("available_recruits count: ", GuildManager.current_recruit_list.size())
	
	# Clear the panel
	clear_panel()
	
	# Use the new dynamic system
	for recruit in GuildManager.current_recruit_list:
		add_recruit_to_display(recruit)
	
	print("=== create_recruit_panel finished ===")

# Dynamic recruit management functions
func add_recruit_to_display(recruit: Character):
	print("Adding recruit to display: ", recruit.character_name if recruit else "NULL")
	
	# Don't add if already displayed
	if recruit in displayed_recruit_panels:
		print("Recruit already displayed, skipping: ", recruit.character_name)
		return
	
	# Ensure container is setup
	if not is_instance_valid(recruit_container):
		print("recruit_container not valid, attempting setup...")
		setup_recruit_container()
		
	var panel = create_recruit_panel_for_character(recruit)
	print("Created panel for recruit: ", recruit.character_name)
	
	if is_instance_valid(recruit_container):
		recruit_container.add_child(panel)
		displayed_recruit_panels[recruit] = panel
		print("Added panel to recruit_container. Total panels: ", displayed_recruit_panels.size())
	else:
		print("Error: recruit_container STILL not valid after setup! recruit_container = ", recruit_container)

func remove_recruit_from_display(recruit: Character):
	if recruit in displayed_recruit_panels:
		var panel = displayed_recruit_panels[recruit]
		panel.queue_free()
		displayed_recruit_panels.erase(recruit)

func create_recruit_panel_for_character(recruit: Character) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(450, 140)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Use theme-managed margins - no manual overrides needed
	var margin_container = MarginContainer.new()
	panel.add_child(margin_container)
	margin_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var vbox = VBoxContainer.new()
	margin_container.add_child(vbox)
	
	# Character info - use theme font size with override for emphasis
	var name_label = Label.new()
	var stars = "★".repeat(recruit.quality)
	name_label.text = "%s (%s) %s - Level %d" % [recruit.character_name, recruit.get_class_name(), stars, recruit.level]
	name_label.add_theme_font_size_override("font_size", 12)  # Header size override
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.clip_contents = true
	vbox.add_child(name_label)
	
	# Stats summary - use default theme font size
	var stats_label = Label.new()
	stats_label.text = "HP:%d DEF:%d ATK:%d SPL:%d MNA:%d SPD:%d LCK:%d" % [
		recruit.health, recruit.defense, recruit.attack_power, recruit.spell_power,
		recruit.mana, recruit.movement_speed, recruit.luck
	]
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_label.clip_contents = true
	vbox.add_child(stats_label)
	
	# Cost and recruit button container - use theme separation
	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)
	
	# Cost information - smaller font for details
	var cost = recruit.get_recruitment_cost()
	var cost_label = Label.new()
	var cost_parts = []
	if cost.get("influence", 0) > 0: cost_parts.append("%d Influence" % cost.influence)
	if cost.get("gold", 0) > 0: cost_parts.append("%d Gold" % cost.gold)
	if cost.get("food", 0) > 0: cost_parts.append("%d Food" % cost.food)
	if cost.get("armor", 0) > 0: cost_parts.append("%d Armor" % cost.armor)
	if cost.get("weapons", 0) > 0: cost_parts.append("%d Weapons" % cost.weapons)
	
	cost_label.text = "Cost: " + (", ".join(cost_parts) if not cost_parts.is_empty() else "Free")
	cost_label.add_theme_font_size_override("font_size", 9)  # Small detail font
	cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cost_label.clip_contents = true
	cost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(cost_label)
	
	# Recruit button - use theme font size
	var recruit_button = Button.new()
	recruit_button.text = "Recruit"
	recruit_button.custom_minimum_size = Vector2(80, 25)
	#recruit_button.disabled = not can_afford_cost(cost) or GuildManager.guild_roster.roster.size() >= max_roster_size
	recruit_button.pressed.connect(func(): _on_recruit_character(recruit))
	recruit_button.z_index = 5
	hbox.add_child(recruit_button)
	
	return panel

func _on_recruit_character(character: Character):
	# Use the existing recruit_character function which handles all the logic
	var result = recruit_character(character)
	
	if result.success:
		# Add to GuildManager's current roster
		GuildManager.current_roster.append(character)
		
		# Remove from display immediately
		remove_recruit_from_display(character)
		
		# Emit the character recruited signal
		GameGlobalEvents.character_recruited.emit(character)
		
		print("Successfully recruited: ", character.character_name)
	else:
		print("Failed to recruit character: ", result.message)
