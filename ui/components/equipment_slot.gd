class_name EquipmentSlot
extends Panel

#region Signals
signal slot_clicked(slot_name: String, item: InventoryItem)
signal slot_right_clicked(slot_name: String, item: InventoryItem)
signal item_dropped(slot_name: String, item: InventoryItem)
#endregion

#region UI References
@onready var slot_name_label: Label = $VBoxContainer/SlotName
@onready var item_container: Panel = $VBoxContainer/ItemContainer
@onready var item_icon: TextureRect = $VBoxContainer/ItemContainer/ItemIcon
@onready var empty_label: Label = $VBoxContainer/ItemContainer/EmptyLabel
@onready var rarity_border: Panel = $VBoxContainer/ItemContainer/RarityBorder
@onready var disabled_overlay: Panel = $VBoxContainer/ItemContainer/DisabledOverlay
#endregion

#region Slot Data
@export var slot_name: String = ""
@export var slot_display_name: String = ""
var current_item: InventoryItem = null
var is_disabled: bool = false
var parent_character: Character = null
#endregion

func _ready():
	"""Initialize the equipment slot"""
	# Connect mouse events
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Update display
	update_display()

func set_slot_info(slot_name_param: String, display_name: String):
	"""Set the slot name and display name"""
	slot_name = slot_name_param
	slot_display_name = display_name
	slot_name_label.text = display_name

func set_character(character: Character):
	"""Set the parent character for this slot"""
	parent_character = character
	update_display()

func set_item(item: InventoryItem):
	"""Set the item in this slot"""
	current_item = item
	update_display()

func get_item() -> InventoryItem:
	"""Get the current item in this slot"""
	return current_item

func clear_item():
	"""Clear the item from this slot"""
	current_item = null
	update_display()

func set_disabled(disabled: bool):
	"""Set whether this slot is disabled"""
	is_disabled = disabled
	update_display()

func update_display():
	"""Update the visual display of the slot"""
	# Update slot name
	if slot_display_name != "":
		slot_name_label.text = slot_display_name
	
	# Update disabled state
	disabled_overlay.visible = is_disabled
	
	if current_item and not is_disabled:
		# Show item
		empty_label.visible = false
		item_icon.visible = true
		
		# Set item icon
		if current_item.icon_path and current_item.icon_path != "":
			var texture = load(current_item.icon_path)
			if texture:
				item_icon.texture = texture
			else:
				item_icon.texture = null
		else:
			item_icon.texture = null
		
		# Update rarity border
		update_rarity_border()
		
	else:
		# Show empty slot
		empty_label.visible = true
		item_icon.visible = false
		rarity_border.visible = false

func update_rarity_border():
	"""Update the rarity border color"""
	if not current_item:
		rarity_border.visible = false
		return
	
	var rarity_color = current_item.get_rarity_color()
	if rarity_color != Color.WHITE:  # Only show border for non-common items
		rarity_border.visible = true
		# Create a simple border style
		var style_box = StyleBoxFlat.new()
		style_box.border_width_left = 2
		style_box.border_width_top = 2
		style_box.border_width_right = 2
		style_box.border_width_bottom = 2
		style_box.border_color = rarity_color
		style_box.bg_color = Color.TRANSPARENT
		rarity_border.add_theme_stylebox_override("panel", style_box)
	else:
		rarity_border.visible = false

func _on_gui_input(event: InputEvent):
	"""Handle GUI input events"""
	if is_disabled:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			slot_clicked.emit(slot_name, current_item)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			slot_right_clicked.emit(slot_name, current_item)

func _on_mouse_entered():
	"""Handle mouse entering the slot"""
	if current_item and has_node("/root/TooltipManager"):
		get_node("/root/TooltipManager").start_item_hover(current_item, self)

func _on_mouse_exited():
	"""Handle mouse exiting the slot"""
	if has_node("/root/TooltipManager"):
		get_node("/root/TooltipManager").stop_item_hover()

func _create_drag_preview() -> Control:
	"""Create a drag preview for this item"""
	var preview = Panel.new()
	preview.custom_minimum_size = Vector2(48, 48)
	
	var icon = TextureRect.new()
	icon.anchors_preset = Control.PRESET_FULL_RECT
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	if current_item and current_item.icon_path:
		var texture = load(current_item.icon_path)
		if texture:
			icon.texture = texture
	
	preview.add_child(icon)
	return preview

func can_drop_data(_position: Vector2, data) -> bool:
	"""Check if data can be dropped on this slot"""
	if is_disabled:
		return false
	
	# Allow dropping inventory items that match this slot
	if data is InventoryItem:
		return data.equipment_slot == slot_name
	return false

func drop_data(_position: Vector2, data):
	"""Handle dropping data on this slot"""
	if data is InventoryItem and data.equipment_slot == slot_name:
		item_dropped.emit(slot_name, data)

func get_drag_data(_position: Vector2):
	"""Get drag data for this slot"""
	if current_item and not is_disabled:
		# Set drag preview when dragging starts
		set_drag_preview(_create_drag_preview())
		return current_item
	return null
