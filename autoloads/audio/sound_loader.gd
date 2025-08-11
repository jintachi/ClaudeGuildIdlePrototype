class_name SoundLoader

#region Loaders
## Loads all audio types via their respective loading methods
func load_audio() -> void:
	load_ost()
	load_sfx()
	load_ui()
	load_ambient()

## Loads OSTs into MusicManager
func load_ost() -> void:
	# Add OST loads here in format (int: [preload(song_path), end_of_loop (-1 for no looping)]
	# Ex:
	#		0: [preload("res://assets/audio/ost/theme.wav"), 356]
	var song_list : Dictionary[int, Array] = {}
	
	for song in song_list.values():
		song.get(0).resource_name = grab_name(song.get(0).resource_path)
		MusicManager.add_ost(song.get(0), song.get(1))

## Loads SFX into the SFX BUS of SoundManager
func load_sfx() -> void:
	# Add SFX loads here in format: preload(sfx_path)
	var sfx_list : Array[AudioStream] = []
	
	for sfx in sfx_list:
		sfx.resource_name = grab_name(sfx.resource_path)
		SoundManager.add_sound(sfx)

## Loads UI SFX into the UI BUS of SoundManager
func load_ui() -> void:
	# Add UI loads here in format: preload(ui_sfx_path)
	var ui_list : Array[AudioStream] = []
	
	for ui in ui_list:
		ui.resource_name = grab_name(ui.resource_path)
		SoundManager.add_sound(ui)

## Loads Ambient SFX into the Ambient BUS of SoundManager
func load_ambient() -> void:
	# Add Ambient loads here in format: preload(ambient_sfx_path)
	var ambient_list : Array[AudioStream] = []
	
	for ambient in ambient_list:
		ambient.resource_name = grab_name(ambient.resource_path)
		SoundManager.add_sound(ambient)
#endregion

#region Helpers
## A helper function to quickly grab the actual name of the song file by inserting its [param path].
func grab_name(path: String) -> String:
	return path.split("/")[path.split("/").size() - 1].split(".")[0]
#endregion
