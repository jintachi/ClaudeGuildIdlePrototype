extends Control

#region Drag Preview Management
var item_icon: TextureRect
var item_label: Label
var background: NinePatchRect
#endregion

func _ready():
	"""Initialize the drag preview"""
	# Get component references
	item_icon = $ItemIcon
	item_label = $ItemLabel
	background = $Background
	
	# Set up initial state
	visible = false
	modulate = Color(1, 1, 1, 0.7)  # Semi-transparent

func show_drag_preview(item: InventoryItem, pos: Vector2):
	"""Show drag preview for the given item"""
	if not item:
		return
	
	# Set item icon
	if item.icon_path and item.icon_path != "":
		var texture = load(item.icon_path)
		if texture:
			item_icon.texture = texture
			item_icon.visible = true
		else:
			item_icon.visible = false
	else:
		item_icon.visible = false
	
	# Set item name
	item_label.text = item.item_name
	item_label.modulate = item.get_rarity_color()
	
	# Position the preview
	global_position = pos - size / 2
	
	# Show the preview
	visible = true

func update_position(pos: Vector2):
	"""Update the drag preview position"""
	global_position = pos - size / 2

func hide_drag_preview():
	"""Hide the drag preview"""
	visible = false

func set_item(item: InventoryItem):
	"""Set the item for the drag preview"""
	if not item:
		return
	
	# Set item icon
	if item.icon_path and item.icon_path != "":
		var texture = load(item.icon_path)
		if texture:
			item_icon.texture = texture
			item_icon.visible = true
		else:
			item_icon.visible = false
	else:
		item_icon.visible = false
	
	# Set item name
	item_label.text = item.item_name
	item_label.modulate = item.get_rarity_color()

func set_preview_size(new_size: Vector2):
	"""Set the size of the drag preview"""
	custom_minimum_size = new_size
	size = new_size
