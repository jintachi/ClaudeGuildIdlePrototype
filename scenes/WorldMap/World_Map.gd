extends Control

func _ready():
	if has_node("BackButton"):
		$BackButton.pressed.connect(_on_back_pressed)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/WorldMap/GuildHall/Guild_Hall.tscn")

# Add methods for quick links to other facilities as needed



func update_town_map_display():
	# Clear existing map
	for child in GuildManager.town_map_container.get_children():
		if child != back_to_hall_town:
			child.queue_free()
	
	# Create a simple 5x5 grid for town facilities
	var grid = GridContainer.new()
	grid.columns = 5
	grid.position = Vector2(50, 50)
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	town_map_container.add_child(grid)
	
	var facilities = [
		{"name": "Guild Hall", "unlocked": true, "action": show_main_hall},
		{"name": "Roster", "unlocked": true, "action": show_roster_tab},
		{"name": "Quests", "unlocked": true, "action": show_quests_tab},
		{"name": "Recruitment", "unlocked": true, "action": show_recruitment_tab},
		{"name": "Healer's Guild", "unlocked": false, "action": null},
		{"name": "Armory", "unlocked": false, "action": null},
		{"name": "Market", "unlocked": false, "action": null},
		{"name": "Training Grounds", "unlocked": false, "action": null},
		{"name": "Library", "unlocked": false, "action": null},
		{"name": "Workshop", "unlocked": false, "action": null}
	]
	
	for i in range(25):
		var button = Button.new()
		button.custom_minimum_size = Vector2(80, 60)
		
		if i < facilities.size():
			var facility = facilities[i]
			button.text = facility.name
			button.disabled = not facility.unlocked
			if facility.action:
				button.pressed.connect(facility.action)
		else:
			button.text = "Empty"
			button.disabled = true
		
		grid.add_child(button)
