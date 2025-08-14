class_name RecruitersHub
extends GuildManager

@export var back_button : Button
@export var recruit_rotation_timer: float = 0.0
@export var available_recruits: Array[Character] = []

@export var max_roster_size: int = 5
@export var recruit_refresh_time: float = 60 # 1 Minute
@export var max_offline_rotations: int = 3 

# Recruitment Settings
@export var recruitment_quality_modifier: float = 1.0
@export var max_available_recruits: int = 3
@export var recruit_stay_duration: float = 300 # 5 Minutes

signal back_pressed

func _ready():
	available_recruits = GameGlobal.current_recruit_list
	connect_signals()

func connect_signals() -> void :
	back_button.pressed.connect(_on_back_pressed)
	GuildManager.character_recruited.connect(_on_character_recruited)
	GameGlobalEvents.generate_random_recruit.connect(generate_random_recruit)
	GameGlobalEvents.generate_recruits.connect(generate_recruits)

func _on_back_pressed():
	emit_signal("back_pressed")
	get_tree().change_scene_to_file("res://scenes/WorldMap/World_Map.tscn")

func update_recruitment_timer(delta: float):
	
	recruit_rotation_timer += delta
	
	if recruit_rotation_timer >= recruit_refresh_time:
		rotate_recruits(GameGlobal.gm)
		recruit_rotation_timer = 0.0

func rotate_recruits(gm:GuildManager):
	
	# Remove recruits who've stayed too long, add new ones
	var recruits_to_remove = []
	for recruit in available_recruits:
		if RNG.wrapper.randf() < 0.3:  # 30% chance each recruit leaves
			recruits_to_remove.append(recruit)
		
	for recruit in recruits_to_remove:
		available_recruits.erase(recruit)
	
	# Fill up to max recruits
	while available_recruits.size() < max_available_recruits:
		gm.current_recruit_list.append(GameGlobalEvents.emit_signal("generate_random_recruit"))

func force_recruit_refresh() -> Dictionary:
	var cost = {"influence": 10}
	if not GameGlobal.gm.can_afford_cost(cost):
		return {"success": false, "message": "Cannot afford refresh cost"}
	
	GameGlobal.gm.spend_resources(cost)
	GameGlobal.gm.generate_recruits()
	return {"success": true, "message": "Recruits refreshed"}


func generate_recruits():
	
	GameGlobal.gm.available_recruits.clear()
	
	for i in range(max_available_recruits):
		var character = generate_random_recruit()
		available_recruits.append(character)

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

func add_character_to_roster(character: Character) -> bool:
	if GameGlobal.gm.roster.size() >= GameGlobal.gm.max_roster_size:
		return false
	
	GameGlobal.gm.roster.append(character)
	GameGlobalEvents.emit_signal("character_recruited")
	return true

func recruit_character(character: Character,gm:GuildManager) -> Dictionary:
	var result = {"success": false, "message": ""}
	
	if not character in available_recruits:
		result.message = "Character not available for recruitment"
		return result
	
	if gm.roster.size() >= gm.max_roster_size:
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
	available_recruits.erase(character)
	
	result.success = true
	result.message = "Successfully recruited " + character.character_name
	return result

func can_afford_cost(cost: Dictionary) -> bool:
	return (GameGlobal.gm.influence >= cost.get("influence", 0) and
			GameGlobal.gm.gold >= cost.get("gold", 0) and
			GameGlobal.gm.food >= cost.get("food", 0) and
			GameGlobal.gm.armor_pieces >= cost.get("armor", 0) and
			GameGlobal.gm.weapons >= cost.get("weapons", 0))


#func update_recruitment_display():
	## Clear existing displays
	#for child in available_recruits_list.get_children():
		#child.queue_free()
	#
	#for recruit in GuildManager.available_recruits:
		#var recruit_panel = create_recruit_panel(recruit)
		#available_recruits_list.add_child(recruit_panel)

func create_recruit_panel(recruit: Character) -> Control:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(400, 100)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Character info
	var name_label = Label.new()
	var stars = "★".repeat(recruit.quality)
	name_label.text = "%s (%s) %s" % [recruit.character_name, recruit.get_class_name(), stars]
	vbox.add_child(name_label)
	
	# Stats summary
	var stats_label = Label.new()
	stats_label.text = "HP:%d DEF:%d ATK:%d SPL:%d" % [recruit.health, recruit.defense, recruit.attack_power, recruit.spell_power]
	vbox.add_child(stats_label)
	
	# Cost and recruit button
	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)
	
	var cost = recruit.get_recruitment_cost()
	var cost_label = Label.new()
	cost_label.text = "Cost: %d Influence, %d Gold" % [cost.influence, cost.gold]
	if cost.food > 0: cost_label.text += ", %d Food" % cost.food
	if cost.armor > 0: cost_label.text += ", %d Armor" % cost.armor
	if cost.weapons > 0: cost_label.text += ", %d Weapons" % cost.weapons
	hbox.add_child(cost_label)
	
	var recruit_button = Button.new()
	recruit_button.text = "Recruit"
	recruit_button.disabled = not GuildManager.can_afford_cost(cost) or GuildManager.roster.size() >= GuildManager.max_roster_size
	#recruit_button.pressed.connect(func(): _on_recruit_character(recruit))
	hbox.add_child(recruit_button)
	
	return panel


# Signal handlers
func _on_character_recruited(character: Character):
	print("Character recruited: ", character.character_name)
	#update_ui()
