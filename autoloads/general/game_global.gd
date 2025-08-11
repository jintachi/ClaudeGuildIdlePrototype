# Current feature worked on for Riley: Crafting, coding-in_progress

## The actual Global containing all of the game's core information.
extends Node

#region Built-Ins
func _ready() -> void:
	# Loading up sounds and then deleting the sound_loader as it's no longer necessary
	var sound_loader = SoundLoader.new()
	sound_loader.load_audio()
	sound_loader = null
	
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
#endregion
