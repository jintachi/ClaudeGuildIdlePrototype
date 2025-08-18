class_name WorldMap
extends Control
@export var scene_name : StringName = "World Map"

var LOCATIONS = [
	{"name": "Guild Hall", "scene": GuildManager.guild_hall, "unlocked": true, "anchor_left": 0.15, "anchor_top": 0.7},
	{"name": "Guild Roster", "scene": GuildManager.guild_roster, "unlocked": true, "anchor_left": 0.25, "anchor_top": 0.5},
	{"name": "Recruiter's Hub", "scene": GuildManager.recruitment_hub, "unlocked": true, "anchor_left": 0.7, "anchor_top": 0.6},
	{"name": "Quest Hub", "scene": GuildManager.quest_board, "unlocked": true, "anchor_left": 0.5, "anchor_top": 0.3},
	{"name": "Blacksmiths Guild", "scene": "res://scenes/WorldMap/BlacksmithsGuild/Blacksmiths_Guild.tscn", "unlocked": true, "anchor_left": 0.1, "anchor_top": 0.2},
	{"name": "Merchants Guild", "scene": "res://scenes/WorldMap/MerchantsGuild/Merchants_Guild.tscn", "unlocked": true, "anchor_left": 0.35, "anchor_top": 0.8},
	{"name": "Recreation", "scene": "res://scenes/WorldMap/Recreation/Recreation.tscn", "unlocked": true, "anchor_left": 0.6, "anchor_top": 0.15},
	{"name": "Inn", "scene": "res://scenes/WorldMap/Inn/Inn.tscn", "unlocked": true, "anchor_left": 0.8, "anchor_top": 0.4},
	{"name": "Healer's Guild", "scene": "res://scenes/WorldMap/HealersGuild/Healers_Guild.tscn", "unlocked": true, "anchor_left": 0.8, "anchor_top": 0.2},
	{"name": "Restaurants", "scene": "", "unlocked": false, "anchor_left": 0.9, "anchor_top": 0.5},
	{"name": "Workshop", "scene": "", "unlocked": false, "anchor_left": 0.55, "anchor_top": 0.55},
	{"name": "Library", "scene": "", "unlocked": false, "anchor_left": 0.92, "anchor_top": 0.7},
	{"name": "Training Grounds", "scene": "", "unlocked": false, "anchor_left": 0.2, "anchor_top": 0.2},
	{"name": "Market", "scene": "", "unlocked": false, "anchor_left": 0.4, "anchor_top": 0.9},
	{"name": "Armory", "scene": "", "unlocked": false, "anchor_left": 0.6, "anchor_top": 0.9}
]

func _ready():
	if has_node("BackButton"):
		$BackButton.pressed.connect(_on_back_pressed)
	_create_location_buttons()

func _on_back_pressed():
	if GuildManager.previous_scene_before_map != "":
		GameGlobalEvents.scene_transition.emit(GuildManager.previous_scene_before_map,GuildManager.previous_scene_node)
	else:
		GameGlobalEvents.scene_transition.emit("Guild Hall",GuildManager.guild_hall)

func _create_location_buttons():
	for loc in LOCATIONS:
		var button = Button.new()
		button.text = loc.name
		button.disabled = not loc.unlocked
		button.anchor_left = loc.anchor_left
		button.anchor_top = loc.anchor_top
		button.anchor_right = loc.anchor_left
		button.anchor_bottom = loc.anchor_top
		button.offset_left = -60
		button.offset_top = -30
		button.offset_right = 60
		button.offset_bottom = 30
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if loc.unlocked and loc.scene != "":
			button.pressed.connect(_on_location_button_pressed.bind(loc.name,loc.scene))
		add_child(button)

func _on_location_button_pressed(scene_name: StringName,scene_obj:Node):
	GameGlobalEvents.scene_transition.emit(scene_name,scene_obj)
