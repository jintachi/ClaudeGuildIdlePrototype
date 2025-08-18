extends CanvasLayer

@export var ui_main_hub : Control

@export var quick_links: Node
@export var notifications: Node
@export var debug_panel: Node
@export var guild_hall_ui: Control
@export var guild_roster_ui: Control
@export var recruitment_ui: Control
@export var quest_hub_ui: Control
@export var blacksmiths_guild_ui: Control
@export var merchants_guild_ui: Control
@export var recreation_ui: Control
@export var inn_ui: Control
@export var healers_guild_ui: Control

var notifications_paused := false
var gameplay_scenes := [
	"Guild Hall", "Guild Roster", "Recruiter's Hub", "Quest Hub", "Blacksmith's Guild", "Merchant's Guild", "Recreation", "Inn", "Healer's Guild", "Quick Links"
]

var scene_panels := {}

func _ready():
	visible = false
	scene_panels = {
		"Guild Hall": guild_hall_ui,
		"Guild Roster": guild_roster_ui,
		"Recruiter's Hub": recruitment_ui,
		"Quest Hub": quest_hub_ui,
		"Blacksmith's Guild": blacksmiths_guild_ui,
		"Merchant's Guild": merchants_guild_ui,
		"Recreation": recreation_ui,
		"Inn": inn_ui,
		"Healer's Guild": healers_guild_ui,
	}
	GameGlobalEvents.scene_transition.connect(_on_scene_transition)
	GameGlobalEvents.game_loaded.connect(_on_game_start)

func _on_game_start():
	print("got signal, main screen turn on")
	visible = true
	_hide_all_scene_panels()
	quick_links.create_quick_links()

func _on_scene_transition(scene_name: StringName,scene_obj:Node):
	_hide_all_scene_panels()
	if scene_name in gameplay_scenes:
		quick_links.visible = true
		debug_panel.visible = true
		notifications.visible = not notifications_paused
		if scene_panels.has(scene_name):
			scene_panels[scene_name].visible = true
	else:
		quick_links.visible = false
		debug_panel.visible = false
		notifications.visible = false

func _hide_all_scene_panels():
	for panel in scene_panels.values():
		panel.visible = false

func toggle_notifications_paused():
	notifications_paused = !notifications_paused
	if notifications_paused:
		notifications.visible = false
	else:
		var current_scene = GuildManager.active_scene
		if current_scene in gameplay_scenes:
			notifications.visible = true
