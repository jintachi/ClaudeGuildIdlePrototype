## Handles everything relating to normal sounds in the game.
extends Node

#region Signals
#signal finished_sound(sfx)
#endregion

#region Variables
var audio_players : Dictionary[Genum.BusID, Array]
var audio_group_count : int = 4
var sfx_pool : Dictionary[StringName, AudioStream] = {}
var ui_pool : Dictionary[StringName, AudioStream] = {}
var ambient_pool : Dictionary[StringName, AudioStream] = {}

var playing : Array[StringName]
#endregion

#region Built-Ins
func _ready() -> void:
	setup_audio_players()
#endregion

#region Setup Methods
## Sets up all the AudioPlayers for SFX, UI, and Ambient sounds with the count defined by [property audio_group_count].
func setup_audio_players() -> void:
	for genum in Genum.BusID.values():
		for i in range(audio_group_count):
			var player := AudioStreamPlayer.new()
			add_child(player)
			var bus_name : StringName = GenumHelper.BUS_NAME.get(genum)
			player.name = "AudioPlayer%s_Bus%s" % [i, bus_name]
			player.bus = bus_name
			if audio_players.has(genum):
				audio_players.get(genum).append(player)
			else:
				audio_players.set(genum, [player])
			
			player.finished.connect(_on_player_finished)

## Adds a sound to the correct pool based on [param bus].
func add_sound(sound: AudioStream, bus: Genum.BusID = Genum.BusID.SFX) -> void:
	match(bus):
		Genum.BusID.SFX:
			sfx_pool.set(sound.resource_name.split(".")[0], sound)
		Genum.BusID.UI:
			ui_pool.set(sound.resource_name.split(".")[0], sound)
		Genum.BusID.AMBIENT:
			ambient_pool.set(sound.resource_name.split(".")[0], sound)
		_:
			push_warning("There's no such bus to subscribe to")

## Removes a sound from their pool.
func remove_sound(sound: AudioStream, bus: Genum.BusID = Genum.BusID.SFX) -> void:
	if bus != Genum.BusID.SFX:
		match(bus):
			Genum.BusID.UI:
				ui_pool.erase(sound.resource_name.split(".")[0])
			Genum.BusID.AMBIENT:
				ambient_pool.erase(sound.resource_name.split(".")[0])
			_:
				push_warning("There's no such bus to unsubscribe from")
	else:
		for pool in [sfx_pool, ui_pool, ambient_pool]:
			var sound_name := sound.resource_name.split(".")[0]
			if pool.has(sound_name):
				pool.erase(sound_name)
				pass
		push_warning("Sound doesn't exist in any subscribed bus")
#endregion

#region Usage Methods
## Plays a sound as long as it exists within any pool.
func play_sound(sound_name: StringName) -> void:
	var sound := find_sound(sound_name)
	var player : AudioStreamPlayer
	if sound[1]:
		player = find_open_player(sound[1])
	
	if player:
		player.stream = sound[0]
		player.play()
		playing.append(sound_name)

## Helper to [method play_sound], but can be used on its own to find the [AudioStream, AudioBus] info
## for a particular sound.
func find_sound(sound_name: StringName) -> Array:
	var bus : Genum.BusID
	var sound : AudioStream
	if sfx_pool.has(sound_name):
		bus = Genum.BusID.SFX
		sound = sfx_pool.get(sound_name)
	elif ui_pool.has(sound_name):
		bus = Genum.BusID.UI
		sound = ui_pool.get(sound_name)
	elif ambient_pool.has(sound_name):
		bus = Genum.BusID.AMBIENT
		sound = ambient_pool.get(sound_name)
	
	return [sound, bus]

## Find the StringName for a given [param stream].
func find_sound_stringname(stream: AudioStream) -> StringName:
	if stream in sfx_pool.values():
		return sfx_pool.find_key(stream)
	elif stream in ui_pool.values():
		return ui_pool.find_key(stream)
	elif stream in ambient_pool.values():
		return ambient_pool.find_key(stream)
	
	push_warning("There is no stream '%s' found in any sound pool." % stream)
	return &""

## Finds the first open player in a specific pool defined by [param bus].
func find_open_player(bus: Genum.BusID) -> AudioStreamPlayer:
	var player_list = audio_players.get(bus)
	for player in player_list:
		if not player.playing:
			return player
	
	push_warning("There is no open player...")
	return null 
#endregion

#region Signal Callbacks
## Called when a player is finished to remove a sound from [property playing].
func _on_player_finished() -> void:
	for bus in audio_players:
		for player in audio_players.get(bus):
			if player.stream and not player.playing:
				playing.erase(find_sound_stringname(player.stream))
#endregion
