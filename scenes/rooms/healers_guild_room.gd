class_name HealersGuildRoom
extends BaseRoom

## Healer's Guild Room
## Handles character healing, resurrection, and healing magic training

# UI elements
@export var injured_characters_panel: VBoxContainer
@export var healing_services_panel: VBoxContainer
@export var training_panel: VBoxContainer
@export var temple_status: Label

# Mock injured characters
var injured_characters = [
	{"name": "Wounded Warrior", "injury": "Sword Wound", "severity": "Moderate", "heal_cost": 50, "heal_time": 120},
	{"name": "Burned Mage", "injury": "Fire Burns", "severity": "Severe", "heal_cost": 75, "heal_time": 180},
	{"name": "Poisoned Rogue", "injury": "Toxic Poisoning", "severity": "Mild", "heal_cost": 30, "heal_time": 90}
]

# Available healing services
var healing_services = [
	{"name": "Basic Healing", "cost": 25, "description": "Heal minor wounds and restore health"},
	{"name": "Disease Cure", "cost": 40, "description": "Remove diseases and infections"},
	{"name": "Poison Antidote", "cost": 35, "description": "Neutralize toxins and poisons"},
	{"name": "Resurrection", "cost": 200, "description": "Bring back fallen guild members"},
	{"name": "Mental Restoration", "cost": 60, "description": "Heal mental trauma and curses"}
]

# Healing training options
var training_options = [
	{"name": "First Aid Training", "cost": 100, "duration": 300, "description": "Learn basic healing techniques"},
	{"name": "Herbalism Study", "cost": 150, "duration": 450, "description": "Master the art of healing herbs"},
	{"name": "Divine Magic", "cost": 200, "duration": 600, "description": "Channel divine healing powers"},
	{"name": "Restoration Mastery", "cost": 250, "duration": 750, "description": "Become an expert healer"}
]

var temple_blessing_until: float = 0.0

func _init():
	room_name = "Healer's Guild"
	room_description = "Heal injuries, cure ailments, and learn restoration magic"
	is_unlocked = true

func setup_room_specific_ui():
	"""Setup healer's guild specific UI connections"""
	# This room is currently a placeholder
	pass

func on_room_entered():
	"""Called when entering the healer's guild"""
	update_room_display()

func update_room_display():
	"""Update the healer's guild display"""
	update_temple_status()
	update_injured_characters_display()
	update_healing_services_display()
	update_training_display()

func update_temple_status():
	"""Update the temple blessing status"""
	if not temple_status:
		return
	
	var current_time = Time.get_time_dict_from_system()
	var current_timestamp = current_time.hour * 3600 + current_time.minute * 60 + current_time.second
	
	if temple_blessing_until > current_timestamp:
		var remaining = temple_blessing_until - current_timestamp
		temple_status.text = "Temple: Blessed (%d min)" % (remaining / 60)
		temple_status.add_theme_color_override("font_color", Color.GOLD)
	else:
		temple_status.text = "Temple: Ready for Blessing"
		temple_status.add_theme_color_override("font_color", Color.WHITE)

func update_injured_characters_display():
	"""Update the injured characters display"""
	if not injured_characters_panel:
		return
	
	# Clear existing characters
	for child in injured_characters_panel.get_children():
		child.queue_free()
	
	if injured_characters.is_empty():
		var no_injured_label = Label.new()
		no_injured_label.text = "No injured guild members"
		no_injured_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_injured_label.add_theme_color_override("font_color", Color.GREEN)
		injured_characters_panel.add_child(no_injured_label)
	else:
		# Add injured characters
		for character in injured_characters:
			var character_panel = create_injured_character_panel(character)
			injured_characters_panel.add_child(character_panel)

func update_healing_services_display():
	"""Update the healing services display"""
	if not healing_services_panel:
		return
	
	# Clear existing services
	for child in healing_services_panel.get_children():
		child.queue_free()
	
	# Add healing services
	for service in healing_services:
		var service_panel = create_healing_service_panel(service)
		healing_services_panel.add_child(service_panel)

func update_training_display():
	"""Update the healing training display"""
	if not training_panel:
		return
	
	# Clear existing training options
	for child in training_panel.get_children():
		child.queue_free()
	
	# Add training options
	for training in training_options:
		var training_panel_widget = create_training_panel(training)
		training_panel.add_child(training_panel_widget)

func create_injured_character_panel(character: Dictionary) -> Control:
	"""Create a panel for an injured character"""
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(250, 120)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	
	# Character header with name and cost
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var name_label = Label.new()
	name_label.text = character.name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	
	var cost_label = Label.new()
	cost_label.text = "%d gold" % character.heal_cost
	cost_label.add_theme_color_override("font_color", Color.YELLOW)
	header.add_child(cost_label)
	
	# Injury details
	var injury_label = Label.new()
	injury_label.text = "Injury: " + character.injury
	injury_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(injury_label)
	
	var severity_label = Label.new()
	severity_label.text = "Severity: " + character.severity
	match character.severity:
		"Mild":
			severity_label.add_theme_color_override("font_color", Color.YELLOW)
		"Moderate":
			severity_label.add_theme_color_override("font_color", Color.ORANGE)
		"Severe":
			severity_label.add_theme_color_override("font_color", Color.RED)
	vbox.add_child(severity_label)
	
	# Heal time
	var time_label = Label.new()
	time_label.text = "Healing time: %d minutes" % (character.heal_time / 60)
	time_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(time_label)
	
	# Heal button
	var heal_button = Button.new()
	heal_button.text = "Begin Healing"
	heal_button.pressed.connect(_on_heal_character.bind(character))
	vbox.add_child(heal_button)
	
	return panel

func create_healing_service_panel(service: Dictionary) -> Control:
	"""Create a panel for a healing service"""
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(250, 80)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	
	# Service header with name and cost
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var name_label = Label.new()
	name_label.text = service.name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	
	var cost_label = Label.new()
	cost_label.text = "%d gold" % service.cost
	cost_label.add_theme_color_override("font_color", Color.YELLOW)
	header.add_child(cost_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = service.description
	desc_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(desc_label)
	
	# Purchase button
	var purchase_button = Button.new()
	purchase_button.text = "Purchase Service"
	purchase_button.pressed.connect(_on_purchase_service.bind(service))
	vbox.add_child(purchase_button)
	
	return panel

func create_training_panel(training: Dictionary) -> Control:
	"""Create a panel for healing training"""
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(250, 100)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	
	# Training header with name and cost
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var name_label = Label.new()
	name_label.text = training.name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	
	var cost_label = Label.new()
	cost_label.text = "%d gold" % training.cost
	cost_label.add_theme_color_override("font_color", Color.YELLOW)
	header.add_child(cost_label)
	
	# Duration
	var duration_label = Label.new()
	duration_label.text = "Duration: %d minutes" % (training.duration / 60)
	duration_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(duration_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = training.description
	desc_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(desc_label)
	
	# Start training button
	var start_button = Button.new()
	start_button.text = "Start Training"
	start_button.pressed.connect(_on_start_training.bind(training))
	vbox.add_child(start_button)
	
	return panel

func _on_heal_character(character: Dictionary):
	"""Handle healing a character"""
	print("Starting healing for: ", character.name)
	# TODO: Implement actual healing logic
	# Check gold, start healing process with time delay

func _on_purchase_service(service: Dictionary):
	"""Handle purchasing a healing service"""
	print("Purchasing service: ", service.name)
	# TODO: Implement service purchasing logic

func _on_start_training(training: Dictionary):
	"""Handle starting healing training"""
	print("Starting training: ", training.name)
	# TODO: Implement training system
	# Check gold, start training with time delay
