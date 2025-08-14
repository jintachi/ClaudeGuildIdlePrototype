extends VBoxContainer

@export var map_btn : Button
@export var guild_hall : Button
@export var roster_btn : Button
@export var quests_btn : Button
@export var recruit_btn : Button


func _ready() -> void:
	init_display()	
	
func init_display() -> void:
	hide_buttons()
	
func hide_buttons () -> void:
	guild_hall.visible = false
	roster_btn.visible = false
	quests_btn.visible = false
	recruit_btn.visible = false
	
func show_buttons () -> void:
	guild_hall.visible = true
	quests_btn.visible = true
	roster_btn.visible = true
	recruit_btn.visible = true
	
func unflatten() -> void :
	guild_hall.flat = false
	roster_btn.flat = false
	quests_btn.flat = false
	recruit_btn.flat = false
	
func toggle_quick_travel() -> void:
	show_buttons()
	var cur_scene = GameGlobal.active_scene
	match cur_scene :
		"Guild Hall" : guild_hall.flat = true
		"Guild Roster" : roster_btn.flat = true
		"Quest Hub" : quests_btn.flat = true
		"Recruiter's Hub" : recruit_btn.flat = true
			
