## The actual Global containing all of the game's core information.
extends Node

#region Global Variables
var active_scene : StringName
var gm : GuildManager
var current_roster : Array[Character]
var current_recruit_list : Array[Character]
var avail_quest_list : Array[Quest]
#endregion

#region Built-Ins
func _ready() -> void:
	# Loading up sounds and then deleting the sound_loader as it's no longer necessary
	var sound_loader = SoundLoader.new()
	sound_loader.load_audio()
	sound_loader = null
	active_scene = "None"
	
	#var expression = Expression.new()
	#
	#var error = expression.parse("print(\"Hello World!\")")
	#if error != OK:
	#	print(expression.get_error_text())
	#	return
	#
	#var result = expression.execute()
#endregion

#region Helpers
func delay(time: float) -> void:
	await get_tree().create_timer(time).timeout

func get_time() -> float : # get time in seconds
	return Time.get_unix_time_from_system()
#endregion
