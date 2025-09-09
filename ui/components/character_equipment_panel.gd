class_name CharacterEquipmentPanel
extends Panel

#region Signals
signal panel_closed()
signal equipment_changed(character: Character)
#endregion

#region UI References
@onready var character_name_label: Label = $VBoxContainer/HeaderContainer/CharacterName
@onready var close_button: Button = $VBoxContainer/HeaderContainer/CloseButton
@onready var stats_list: RichTextLabel = $VBoxContainer/StatsContainer/StatsList
#endregion

#region Equipment Slots
var equipment_slots: Dictionary = {}
var current_character: Character = null
#endregion

func _ready():
	"""Initialize the equipment panel"""
	# Connect close button
	close_button.pressed.connect(_on_close_button_pressed)
	
	# Create equipment slots programmatically
	create_equipment_slots()
	
	# Connect slot signals
	connect_slot_signals()
	
	# Hide by default
	visible = false

func create_equipment_slots():
	"""Create equipment slots programmatically"""
	var container = $VBoxContainer/EquipmentContainer
	var equipment_slot_scene = preload("res://ui/components/EquipmentSlot.tscn")
	
	# Define all equipment slots
	var slot_definitions = [
		{"name": "head", "display": "Head"},
		{"name": "shoulder", "display": "Shoulder"},
		{"name": "back", "display": "Back"},
		{"name": "chest", "display": "Chest"},
		{"name": "hands", "display": "Hands"},
		{"name": "legs", "display": "Legs"},
		{"name": "feet", "display": "Feet"},
		{"name": "mainhand", "display": "Main Hand"},
		{"name": "offhand", "display": "Off Hand"},
		{"name": "accessory", "display": "Accessory"}
	]
	
	# Create each slot
	for slot_def in slot_definitions:
		var slot_instance = equipment_slot_scene.instantiate()
		slot_instance.slot_name = slot_def.name
		slot_instance.slot_display_name = slot_def.display
		container.add_child(slot_instance)
		equipment_slots[slot_def.name] = slot_instance

# collect_equipment_slots function removed - functionality moved to create_equipment_slots

func connect_slot_signals():
	"""Connect signals for all equipment slots"""
	for slot_name in equipment_slots:
		var slot = equipment_slots[slot_name]
		slot.slot_clicked.connect(_on_slot_clicked)
		slot.slot_right_clicked.connect(_on_slot_right_clicked)
		slot.item_dropped.connect(_on_item_dropped)

func show_equipment_panel(character: Character):
	"""Show the equipment panel for a character"""
	current_character = character
	character_name_label.text = character.character_name
	
	# Update all slots with character's equipment
	update_all_slots()
	
	# Update stats display
	update_stats_display()
	
	# Show the panel
	visible = true

func hide_equipment_panel():
	"""Hide the equipment panel"""
	visible = false
	current_character = null

func update_all_slots():
	"""Update all equipment slots with current character's equipment"""
	if not current_character:
		return
	
	for slot_name in equipment_slots:
		var slot = equipment_slots[slot_name]
		var item = current_character.get_equipped_item(slot_name)
		slot.set_item(item)
		slot.set_character(current_character)
		
		# Check if slot should be disabled (e.g., offhand when two-handed weapon)
		var is_disabled = not current_character.is_slot_available(slot_name)
		slot.set_disabled(is_disabled)

func update_stats_display():
	"""Update the equipment stats display"""
	if not current_character:
		stats_list.text = ""
		return
	
	var stats_text = ""
	
	# Get equipment bonuses
	var bonuses = current_character.equipment_bonuses
	var multipliers = current_character.equipment_multipliers
	
	# Display additive bonuses
	var has_bonuses = false
	for stat in bonuses:
		var bonus = bonuses[stat]
		if bonus != 0:
			has_bonuses = true
			var stat_name = stat.replace("_", " ").capitalize()
			var color = "#90EE90" if bonus > 0 else "#FFB6C1"
			stats_text += "[color=%s][+] %d %s[/color]\n" % [color, bonus, stat_name]
	
	# Display multiplicative bonuses
	for stat in multipliers:
		var multiplier = multipliers[stat]
		if multiplier != 1.0:
			has_bonuses = true
			var stat_name = stat.replace("_", " ").capitalize()
			var percentage = (multiplier - 1.0) * 100
			var color = "#90EE90" if percentage > 0 else "#FFB6C1"
			stats_text += "[color=%s][x] %.1f%% %s[/color]\n" % [color, percentage, stat_name]
	
	if not has_bonuses:
		stats_text = "[color=#888888]No equipment bonuses[/color]"
	
	stats_list.text = stats_text

func _on_close_button_pressed():
	"""Handle close button press"""
	hide_equipment_panel()
	panel_closed.emit()

func _on_slot_clicked(slot_name: String, item: InventoryItem):
	"""Handle slot click"""
	print("Clicked slot: ", slot_name, " with item: ", item.item_name if item else "Empty")
	
	# If there's an item, show unequip option
	if item:
		show_unequip_dialog(slot_name, item)

func _on_slot_right_clicked(slot_name: String, item: InventoryItem):
	"""Handle slot right click"""
	print("Right-clicked slot: ", slot_name, " with item: ", item.item_name if item else "Empty")
	
	# Show context menu
	show_slot_context_menu(slot_name, item)

func _on_item_dropped(slot_name: String, item: InventoryItem):
	"""Handle item drop on slot"""
	print("Dropped item: ", item.item_name, " on slot: ", slot_name)
	
	if current_character and item:
		# Try to equip the item
		var success = current_character.equip_item(item, slot_name)
		if success:
			# Update the slot display
			update_all_slots()
			update_stats_display()
			equipment_changed.emit(current_character)
			print("Successfully equipped: ", item.item_name)
		else:
			print("Failed to equip: ", item.item_name)

func show_unequip_dialog(slot_name: String, _item: InventoryItem):
	"""Show unequip confirmation dialog"""
	# This would show a confirmation dialog
	# For now, just unequip directly
	if current_character:
		var unequipped_item = current_character.unequip_item(slot_name)
		if unequipped_item:
			# Add item back to inventory
			if has_node("/root/InventoryManager"):
				get_node("/root/InventoryManager").add_item(unequipped_item)
			
			# Update display
			update_all_slots()
			update_stats_display()
			equipment_changed.emit(current_character)
			print("Unequipped: ", unequipped_item.item_name)

func show_slot_context_menu(slot_name: String, item: InventoryItem):
	"""Show context menu for slot"""
	# This would show a context menu with options like:
	# - Unequip (if item present)
	# - Show item details
	# - etc.
	print("Context menu for slot: ", slot_name)
	
	if item:
		show_unequip_dialog(slot_name, item)

#region Static Helper Functions
static func show_for_character(character: Character):
	"""Static helper to show equipment panel for a character"""
	print("CharacterEquipmentPanel.show_for_character called for: ", character.character_name)
	
	# Create and show equipment panel using UI Layer
	var panel_scene = preload("res://ui/components/CharacterEquipmentPanel.tscn")
	print("Panel scene loaded: ", panel_scene != null)
	
	var panel = UILayerManager.add_modal_to_layer(panel_scene) as CharacterEquipmentPanel
	print("Panel created: ", panel != null)
	
	if panel and panel is CharacterEquipmentPanel:
		print("Showing equipment panel for character: ", character.character_name)
		panel.show_equipment_panel(character)
	else:
		print("Failed to create CharacterEquipmentPanel - panel: ", panel, " is CharacterEquipmentPanel: ", panel is CharacterEquipmentPanel)
#endregion
