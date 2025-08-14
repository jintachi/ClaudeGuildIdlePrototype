class_name GuildRoster
extends GuildManager


signal back_pressed

@export var roster_list : VBoxContainer
@export var roster: Array[Character] = []


func _ready():
	$BackButton.pressed.connect(_on_back_pressed)

#TODO : Update the Roster Display Properly to display members actively on quests.  Once a quest is complete, make the character available again.  Also display current Injuries on the characters.  Update panel sizes as wellsq
func update_roster_display():
	# Clear existing displays
	for child in roster_list.get_children():
		child.queue_free()
	
	for character in GuildManager.roster:
		var char_panel = create_character_panel(character)
		roster_list.add_child(char_panel)

func _on_back_pressed():
	emit_signal("back_pressed")
	get_tree().change_scene_to_file("res://scenes/WorldMap/World_Map.tscn")

func get_injury_name(injury_type: Character.InjuryType) -> String:
	match injury_type:
		Character.InjuryType.PHYSICAL_WOUND: return "Physical Wound"
		Character.InjuryType.MENTAL_TRAUMA: return "Mental Trauma"
		Character.InjuryType.CURSED_AFFLICTION: return "Cursed"
		Character.InjuryType.EXHAUSTION: return "Exhausted"
		Character.InjuryType.POISON: return "Poisoned"
		_: return "Unknown"

func create_character_panel(character: Character):
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(400, 120)
	
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
	
	return panel
