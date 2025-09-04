class_name InventoryItemSlot
extends Panel

#region Signals
signal item_clicked(item: InventoryItem, slot_index: int)
signal item_right_clicked(item: InventoryItem, slot_index: int)
signal item_dropped(item: InventoryItem, slot_index: int)
#endregion

#region UI References
@onready var item_icon: TextureRect = $ItemIcon
@onready var quantity_label: Label = $QuantityLabel
@onready var charges_label: Label = $ChargesLabel
@onready var rarity_border: Panel = $RarityBorder
@onready var empty_label: Label = $EmptyLabel
#endregion

#region Slot Data
var slot_index: int = -1
var current_item: InventoryItem = null
var is_drag_enabled: bool = true
#endregion

func _ready():
	"""Initialize the slot"""
	# Connect mouse events
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Set up drag and drop
	if is_drag_enabled:
		set_drag_preview(_create_drag_preview())

func set_slot_index(index: int):
	"""Set the slot index for this slot"""
	slot_index = index

func set_item(item: InventoryItem):
	"""Set the item displayed in this slot"""
	current_item = item
	update_display()

func get_item() -> InventoryItem:
	"""Get the current item in this slot"""
	return current_item

func clear_item():
	"""Clear the item from this slot"""
	current_item = null
	update_display()

func update_display():
	"""Update the visual display of the slot"""
	if current_item:
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
		
		# Update quantity display
		if current_item.quantity > 1:
			quantity_label.text = str(current_item.quantity)
			quantity_label.visible = true
		else:
			quantity_label.visible = false
		
		# Update charges display
		var charge_display = current_item.get_charge_display()
		if charge_display != "":
			charges_label.text = charge_display
			charges_label.visible = true
		else:
			charges_label.visible = false
		
		# Update rarity border
		update_rarity_border()
		
	else:
		# Show empty slot
		empty_label.visible = true
		item_icon.visible = false
		quantity_label.visible = false
		charges_label.visible = false
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
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			item_clicked.emit(current_item, slot_index)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			item_right_clicked.emit(current_item, slot_index)

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
	# Allow dropping inventory items
	return data is InventoryItem

func drop_data(_position: Vector2, data):
	"""Handle dropping data on this slot"""
	if data is InventoryItem:
		item_dropped.emit(data, slot_index)

func get_drag_data(_position: Vector2):
	"""Get drag data for this slot"""
	if current_item and is_drag_enabled:
		return current_item
	return null
