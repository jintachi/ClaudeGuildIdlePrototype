class_name RNGManager
extends Node

var wrapper: RandomNumberGenerator = RandomNumberGenerator.new()
var state: int = 0

func _ready() -> void:
	if seed == null:
		randomize_with_new_seed()

func set_state(new_state: int) -> void:
	state = new_state
	wrapper.state = new_state

func get_state() -> int:
	return state

func randomize_with_new_seed() -> void:
	# Use system time to derive a seed
	wrapper.set_seed(hash("MoonlitCafe"))

func shuffle_in_place(array: Array) -> void:
	# Fisher-Yates shuffle using this RNG
	for i in range(array.size() - 1, 0, -1):
		var j: int = randi_range(0, i)
		var tmp = array[i]
		array[i] = array[j]
		array[j] = tmp
