extends Node

#region Variable Definitions
var song_pool : Dictionary[StringName, Array] ## All available songs
var main_music_player : AudioStreamPlayer ## The main player, all functions reference this
var secondary_music_player : AudioStreamPlayer ## A second player used when crossfading
var current_song : StringName ## The current name of the song, same name used in [member song_pool]
var crossfade := false ## If MusicManager is currently crossfading or not
#endregion

#region Built-Ins
func _ready() -> void:
	setup_music_players()

func _process(_delta: float) -> void:
	if current_song != &"":
		if song_pool.get(current_song).get(1) != -1 and not crossfade:
			var current_pos = main_music_player.get_playback_position()
			if current_pos >= song_pool.get(current_song).get(1):
				main_music_player.seek(0)
#endregion

#region Setup Methods
## Called during _ready to set up the two music players
func setup_music_players() -> void:
	main_music_player = AudioStreamPlayer.new()
	main_music_player.bus = GenumHelper.BUS_NAME.get(Genum.BusID.OST)
	add_child(main_music_player)
	
	secondary_music_player = AudioStreamPlayer.new()
	secondary_music_player.bus = GenumHelper.BUS_NAME.get(Genum.BusID.OST)
	add_child(secondary_music_player)

## Method for adding an ost to [member song_pool]
func add_ost(stream: AudioStream, loop: int) -> void:
	print("added %s" % stream.resource_name)
	song_pool.set(stream.resource_name, [stream, loop])

## Method for removing an ost from [member song_pool]
func remove_ost(stream_name: StringName) -> void:
	if song_pool.has(stream_name):
		song_pool.erase(stream_name)
	else:
		push_warning("There is no stream by %s in song_pool" % stream_name)
#endregion

#region Usage Methods
## Used to play a song found within [member song_pool]. This is done by entering the [param song_name]
## and then optionally putting [param cross_over] if the ost should be crossed over the currently
## playing song.
func play_song(song_name: StringName, crossover: bool = false) -> void:
	if not song_pool.has(song_name):
		push_error("There's no song by the name %s in song_pool" % song_name)
	
	current_song = song_name
	if crossover:
		_crossover(song_name)
	else:
		main_music_player.stream = song_pool.get(song_name).get(0)
		main_music_player.play()

## Used to play specific [param sfx] referred to as "jingles" that dodge the currently playing ost.
## If there is currently something playing, [method _crossover] is immediately called.
func play_jingle(sfx: StringName) -> void:
	if main_music_player.playing:
		_crossover(sfx, true)
	else:
		SoundManager.play_sound(sfx)

## Used to stop the currently playing song
func stop_song() -> void:
	main_music_player.stop()
	current_song = &""
#endregion

#region Helper Methods
## Crosses between either the currently playing ost and into another ost, or if a jingle is used
## via [method play_jingle], will crossover by dodging the current ost. Needs [param sound_name] which
## is the ost or sfx name, but [param sfx_crossover] is only needed when using sfx.
func _crossover(sound_name: StringName, sfx_crossover := false) -> void:
	crossfade = true
	if sfx_crossover:
		_sfx_crossover(sound_name)
	else:
		_ost_crossover(sound_name)

## This is the ost specific crossover function, using [param song_name] to find the specific song to
## be crossed over
func _ost_crossover(song_name: StringName) -> void:
	# Add the song to the secondary music player and have it start at volume 0.
	secondary_music_player.stream = song_pool.get(song_name).get(0)
	secondary_music_player.volume_linear = 0
	secondary_music_player.play()
	
	# Create the crossover tween
	var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_SINE)
	tween.tween_property(main_music_player, "volume_linear", 0, 1.0)
	tween.parallel().tween_property(secondary_music_player, "volume_linear", 1, 1.0)
	
	await tween.finished
	# Move from secondary to main
	main_music_player.stream = secondary_music_player.stream
	main_music_player.volume_linear = 1
	secondary_music_player.volume_linear = 0
	main_music_player.play(secondary_music_player.get_playback_position())
	secondary_music_player.stop()
	secondary_music_player.stream = null
	
	crossfade = false

## SFX specific crossover used for "jingles" using a specific sfx by entering [param sfx_name].
func _sfx_crossover(sfx_name: StringName) -> void:
	# fade our main track, play our SFX, then fade back in
	main_music_player.volume_linear = 0
	SoundManager.play_sound(sfx_name)
	
	# Constantly checking when a sound finishes and when it's the used sound.
	while sfx_name in SoundManager.playing:
		await GameGlobal.delay(1)
		print(SoundManager.playing)
	
	# Tween the ost back in.
	var tween = get_tree().create_tween().bind_node(self)
	tween.tween_property(main_music_player, "volume_linear", 1, 1.0)
	await tween.finished
	
	crossfade = false
#endregion
