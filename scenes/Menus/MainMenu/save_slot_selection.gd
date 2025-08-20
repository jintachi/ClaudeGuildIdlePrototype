extends Control

signal slot_selected(slot: int, action: String)  # action: "load", "new", "delete"

var intended_action: String = "load"  # Set by main menu

@onready var slot_details = [
	$VBoxContainer/SlotContainer/Slot1/Slot1Info/Slot1Details,
	$VBoxContainer/SlotContainer/Slot2/Slot2Info/Slot2Details,
	$VBoxContainer/SlotContainer/Slot3/Slot3Info/Slot3Details
]

@onready var load_buttons = [
	$VBoxContainer/SlotContainer/Slot1/Slot1Buttons/Slot1LoadButton,
	$VBoxContainer/SlotContainer/Slot2/Slot2Buttons/Slot2LoadButton,
	$VBoxContainer/SlotContainer/Slot3/Slot3Buttons/Slot3LoadButton
]

@onready var new_buttons = [
	$VBoxContainer/SlotContainer/Slot1/Slot1Buttons/Slot1NewButton,
	$VBoxContainer/SlotContainer/Slot2/Slot2Buttons/Slot2NewButton,
	$VBoxContainer/SlotContainer/Slot3/Slot3Buttons/Slot3NewButton
]

@onready var delete_buttons = [
	$VBoxContainer/SlotContainer/Slot1/Slot1Buttons/Slot1DeleteButton,
	$VBoxContainer/SlotContainer/Slot2/Slot2Buttons/Slot2DeleteButton,
	$VBoxContainer/SlotContainer/Slot3/Slot3Buttons/Slot3DeleteButton
]

@onready var back_button = $VBoxContainer/BackButton

func _ready():
	# Connect button signals
	for i in range(3):
		load_buttons[i].pressed.connect(_on_load_button_pressed.bind(i))
		new_buttons[i].pressed.connect(_on_new_button_pressed.bind(i))
		delete_buttons[i].pressed.connect(_on_delete_button_pressed.bind(i))
	
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Configure UI based on intended action
	configure_ui_for_action()
	
	# Refresh slot information
	refresh_slot_info()

func refresh_slot_info():
	"""Update the display information for all save slots"""
	for i in range(3):
		var slot_info = GuildManager.get_save_slot_info(i)
		update_slot_display(i, slot_info)

func configure_ui_for_action():
	"""Configure the UI based on the intended action"""
	# Update title based on action
	var title_label = $VBoxContainer/TitleLabel
	if intended_action == "load":
		title_label.text = "Select Save Slot to Load"
		# For loading, only show load buttons for slots with data
		# Hide new game and delete buttons
		for i in range(3):
			new_buttons[i].visible = false
			delete_buttons[i].visible = false
	elif intended_action == "new":
		title_label.text = "Select Save Slot for New Game"
		# For new game, only show new game buttons
		# Hide load and delete buttons
		for i in range(3):
			load_buttons[i].visible = false
			delete_buttons[i].visible = false

func update_slot_display(slot: int, info: Dictionary):
	"""Update the display for a specific slot"""
	var details_label = slot_details[slot]
	var load_btn = load_buttons[slot]
	var new_btn = new_buttons[slot]
	var delete_btn = delete_buttons[slot]
	
	if info.exists:
		# Format the save information
		var date_string = Time.get_datetime_string_from_unix_time(info.timestamp)
		var details_text = "Influence: %d\nGold: %d\nMembers: %d\nSaved: %s" % [
			info.influence, info.gold, info.roster_size, date_string
		]
		details_label.text = details_text
		
		# Configure buttons based on intended action
		if intended_action == "load":
			load_btn.disabled = false
		elif intended_action == "new":
			new_btn.disabled = false
			delete_btn.disabled = false  # Allow delete for new game mode
	else:
		# Empty slot
		details_label.text = "Empty Slot"
		
		# Configure buttons based on intended action
		if intended_action == "load":
			load_btn.disabled = true
		elif intended_action == "new":
			new_btn.disabled = false
			delete_btn.disabled = true  # No need to delete empty slot

func _on_load_button_pressed(slot: int):
	"""Handle load button press for a slot"""
	slot_selected.emit(slot, "load")

func _on_new_button_pressed(slot: int):
	"""Handle new game button press for a slot"""
	# Check if slot has data and ask for confirmation
	var slot_info = GuildManager.get_save_slot_info(slot)
	if slot_info.exists:
		show_overwrite_confirmation(slot)
	else:
		slot_selected.emit(slot, "new")

func _on_delete_button_pressed(slot: int):
	"""Handle delete button press for a slot"""
	show_delete_confirmation(slot)

func _on_back_button_pressed():
	"""Return to main menu"""
	get_tree().change_scene_to_file("res://scenes/Menus/MainMenu/Main_Menu.tscn")

func show_overwrite_confirmation(slot: int):
	"""Show confirmation dialog for overwriting existing save"""
	var dialog = ConfirmationDialog.new()
	add_child(dialog)
	dialog.dialog_text = "This slot contains existing save data. Do you want to overwrite it with a new game?"
	dialog.title = "Overwrite Save"
	dialog.confirmed.connect(_on_overwrite_confirmed.bind(slot))
	dialog.canceled.connect(_on_dialog_closed.bind(dialog))
	dialog.popup_centered()

func show_delete_confirmation(slot: int):
	"""Show confirmation dialog for deleting save"""
	var dialog = ConfirmationDialog.new()
	add_child(dialog)
	dialog.dialog_text = "Are you sure you want to delete this save file? This action cannot be undone."
	dialog.title = "Delete Save"
	dialog.confirmed.connect(_on_delete_confirmed.bind(slot))
	dialog.canceled.connect(_on_dialog_closed.bind(dialog))
	dialog.popup_centered()

func _on_overwrite_confirmed(slot: int):
	"""Handle overwrite confirmation"""
	slot_selected.emit(slot, "new")

func _on_delete_confirmed(slot: int):
	"""Handle delete confirmation"""
	GuildManager.delete_save_slot(slot)
	refresh_slot_info()

func _on_dialog_closed(dialog: ConfirmationDialog):
	"""Clean up dialog when closed"""
	dialog.queue_free()
