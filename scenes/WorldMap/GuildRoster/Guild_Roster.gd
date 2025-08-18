class_name GuildRoster
extends Node

signal back_pressed


@export var scene_name : StringName = "Guild Roster"
@export var roster_list : VBoxContainer
@export var roster: Array[Character] = []


func _ready():
	$BackButton.pressed.connect(_on_back_pressed)
	roster = GuildManager.current_roster
	GameGlobalEvents.scene_transition.connect(update_roster_display)

#TODO : Update the Roster Display Properly to display members actively on quests.  Once a quest is complete, make the character available again.  Also display current Injuries on the characters.  Update panel sizes as wellsq
func update_roster_display(current_scene_name:StringName,_scene_obj:Node):
	if current_scene_name != "Guild Roster" : return
	
	# Clear existing panels first
	for child in roster_list.get_children():
		child.queue_free()
	
	for character in roster:
		var char_panel = create_character_panel(character)
		roster_list.add_child(char_panel)

func _on_back_pressed():
	emit_signal("back_pressed")
	GameGlobalEvents.scene_transition.emit(GuildManager.previous_scene_before_map,GuildManager.previous_scene_node)

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
	panel.custom_minimum_size = Vector2(450, 140)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Use theme-managed margins - no manual overrides needed
	var margin_container = MarginContainer.new()
	panel.add_child(margin_container)
	margin_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var vbox = VBoxContainer.new()
	margin_container.add_child(vbox)
	
	# Name and class - use theme font size with override for emphasis
	var name_label = Label.new()
	var stars = "★".repeat(character.quality)
	name_label.text = "%s (%s) %s - Level %d [%s Rank]" % [
		character.character_name, character.get_class_name(), stars,
		character.level, character.get_rank_name()
	]
	name_label.add_theme_font_size_override("font_size", 12)  # Header size override
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.clip_contents = true
	vbox.add_child(name_label)
	
	# Stats - use default theme font size
	var stats_label = Label.new()
	stats_label.text = "HP:%d DEF:%d ATK:%d SPL:%d MNA:%d SPD:%d LCK:%d" % [
		character.health, character.defense, character.attack_power,
		character.spell_power, character.mana, character.movement_speed, character.luck
	]
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_label.clip_contents = true
	vbox.add_child(stats_label)
	
	# Substats - smaller font for details
	var substats_label = Label.new()
	var skills = []
	if character.gathering > 0: skills.append("Gathering:%d" % character.gathering)
	if character.hunting_trapping > 0: skills.append("Hunting:%d" % character.hunting_trapping)
	if character.diplomacy > 0: skills.append("Diplomacy:%d" % character.diplomacy)
	if character.caravan_guarding > 0: skills.append("Caravan:%d" % character.caravan_guarding)
	if character.escorting > 0: skills.append("Escort:%d" % character.escorting)
	if character.stealth > 0: skills.append("Stealth:%d" % character.stealth)
	if character.odd_jobs > 0: skills.append("OddJobs:%d" % character.odd_jobs)
	
	substats_label.text = "Skills: " + (", ".join(skills) if not skills.is_empty() else "None")
	substats_label.add_theme_font_size_override("font_size", 9)  # Small detail font
	substats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	substats_label.clip_contents = true
	vbox.add_child(substats_label)
	
	# Status - use default theme font size
	var status_label = Label.new()
	if character.is_injured():
		var injury_duration = character.get_injury_duration()
		var injury_minutes:int = injury_duration / 60
		var injury_seconds:float = injury_duration - (injury_minutes * 60)
		var display_inj = "%d:%02.0f" % [injury_minutes, injury_seconds]
		status_label.text = "INJURED - %s (%s)" % [get_injury_name(character.injury_type), display_inj]
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
	
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.clip_contents = true
	vbox.add_child(status_label)
	
	return panel

func add_character(character: Character, max_roster_size: int) -> bool:
	if roster.size() >= max_roster_size:
		return false
	roster.append(character)
	emit_signal("character_recruited", character)
	return true
