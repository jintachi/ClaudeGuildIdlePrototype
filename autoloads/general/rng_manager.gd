class_name RNGManager
extends Node

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var seed: int = 0
var state: int = 0

func _ready() -> void:
	if seed == 0:
		randomize_with_new_seed()

func set_seed(new_seed: int) -> void:
	seed = new_seed
	rng.seed = new_seed
	state = rng.state

func set_state(new_state: int) -> void:
	state = new_state
	rng.state = new_state

func get_seed() -> int:
	return seed

func get_state() -> int:
	return state

func randomize_with_new_seed() -> void:
	# Use system time to derive a seed
	var generated_seed: int = int(Time.get_unix_time_from_system() * 1000) ^ hash("MoonlitCafe")
	set_seed(generated_seed)

# Wrapper methods ensuring centralized deterministic randomness
func randf() -> float:
	var v := rng.randf()
	state = rng.state
	return v

func randi() -> int:
	var v := rng.randi()
	state = rng.state
	return v

func randf_range(min_value: float, max_value: float) -> float:
	var v := rng.randf_range(min_value, max_value)
	state = rng.state
	return v

func randi_range(min_value: int, max_value: int) -> int:
	var v := rng.randi_range(min_value, max_value)
	state = rng.state
	return v

func chance(probability: float) -> bool:
	return randf() < probability

func choose(array: Array):
	if array.is_empty():
		return null
	var index := randi_range(0, array.size() - 1)
	return array[index]

func shuffle_in_place(array: Array) -> void:
	# Fisher-Yates shuffle using this RNG
	for i in range(array.size() - 1, 0, -1):
		var j: int = randi_range(0, i)
		var tmp = array[i]
		array[i] = array[j]
		array[j] = tmp
