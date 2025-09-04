class_name PopupContextMenu
extends PopupMenu

#region Signals
signal menu_item_selected(item_id: String, data: Dictionary)
signal menu_closed()
#endregion

#region Menu Data
var menu_data: Dictionary = {}
#endregion

func _ready():
	"""Initialize the popup context menu"""
	# Connect built-in signals
	id_pressed.connect(_on_id_pressed)
	popup_hide.connect(_on_popup_hide)
	
	# PopupMenu handles mouse filtering automatically

func show_character_context_menu(character: Character, menu_position: Vector2):
	"""Show context menu for a character"""
	clear()
	menu_data.clear()
	
	print("Creating popup context menu for character: ", character.character_name)
	
	var item_id = 0
	
	# Equipment menu item
	add_item("View Equipment", item_id)
	menu_data[item_id] = {"id": "equipment", "data": {"character": character}}
	item_id += 1
	
	# Stats menu item
	add_item("View Stats", item_id)
	menu_data[item_id] = {"id": "stats", "data": {"character": character}}
	item_id += 1
	
	# Training menu item (if available)
	if character.character_status == Character.CharacterStatus.AVAILABLE:
		add_item("Send to Training", item_id)
		menu_data[item_id] = {"id": "training", "data": {"character": character}}
		item_id += 1
		print("Added training menu item")
	else:
		print("Training menu item NOT added - character status: ", character.character_status)
	
	# Promotion menu item (if available)
	if character.promotion_quest_available:
		add_item("Start Promotion Quest", item_id)
		menu_data[item_id] = {"id": "promotion", "data": {"character": character}}
		item_id += 1
		print("Added promotion menu item")
	else:
		print("Promotion menu item NOT added - promotion_quest_available: ", character.promotion_quest_available)
	
	print("Total menu items created: ", get_item_count())
	
	# Show the popup at the specified position
	popup(Rect2i(menu_position, Vector2i(150, 100)))

func _on_id_pressed(id: int):
	"""Handle menu item selection"""
	if id in menu_data:
		var item_data = menu_data[id]
		var item_id = item_data.get("id", "")
		var data = item_data.get("data", {})
		
		print("PopupContextMenu item selected: ", item_id, " with data: ", data)
		menu_item_selected.emit(item_id, data)
	else:
		print("ERROR: Menu item ID not found: ", id)

func _on_popup_hide():
	"""Handle popup hide"""
	print("PopupContextMenu hidden")
	menu_closed.emit()

#region Static Helper Functions
# Static helper functions removed to avoid class_name reference issues
# Use the instance methods directly instead
#endregion
