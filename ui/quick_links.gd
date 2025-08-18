extends Control

@export var scene_name : StringName = "Quick Links"
@export var vbox : VBoxContainer


func create_quick_links():
	# Remove any existing container
	for child in vbox.get_children():
		child.queue_free()

	var current_scene = GuildManager.active_scene
	var world_map_scene = GuildManager.world_map
	if !is_instance_valid(GuildManager.world_map) : return
	for loc in world_map_scene.LOCATIONS:
		var btn = Button.new()
		if loc.unlocked and loc.scene != "":
			btn.text = loc.name
			btn.flat = false
			btn.disabled = false
		else:
			btn.text = "???"
			btn.flat = true
			btn.disabled = true
		# Disable all buttons if on the world map scene
		if current_scene == world_map_scene.scene_name:
			btn.disabled = true
		# Otherwise, enable only if not the current scene
		elif loc.name == current_scene:
			btn.flat = true
		elif loc.unlocked and loc.scene != "":
			btn.pressed.connect(_on_location_pressed.bind(loc.name,loc.scene))
		vbox.add_child(btn)

func _on_location_pressed(next_scene: StringName,scene_obj:Node):
	GameGlobalEvents.scene_transition.emit(next_scene,scene_obj)
	
	print("GameGlobalEvents.scene_transition.emit(next_scene): ", next_scene)
			
