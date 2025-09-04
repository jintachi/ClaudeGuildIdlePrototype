extends Node

#region Singleton Setup
static var instance: Node
#endregion

#region Drag Preview Management
var drag_preview_scene: PackedScene
var current_drag_preview: Control = null
#endregion

#region Signals
signal drag_preview_shown(item: InventoryItem)
signal drag_preview_hidden()
#endregion

func _ready():
	"""Initialize the drag preview manager"""
	instance = self
	
	# Load drag preview scene
	drag_preview_scene = preload("res://ui/components/DragPreview.tscn")

func show_drag_preview(item: InventoryItem, position: Vector2):
	"""Show drag preview for the given item"""
	if not item:
		return
	
	# Hide any existing drag preview
	hide_drag_preview()
	
	# Create new drag preview using UI Layer
	current_drag_preview = UILayerManager.add_overlay_to_layer(drag_preview_scene)
	
	# Set up the drag preview
	current_drag_preview.show_drag_preview(item, position)
	
	drag_preview_shown.emit(item)

func update_drag_preview_position(position: Vector2):
	"""Update the drag preview position"""
	if current_drag_preview:
		current_drag_preview.update_position(position)

func hide_drag_preview():
	"""Hide the current drag preview"""
	if current_drag_preview:
		UILayerManager.remove_from_layer(current_drag_preview)
		current_drag_preview = null
		drag_preview_hidden.emit()

func is_dragging() -> bool:
	"""Check if currently dragging"""
	return current_drag_preview != null

#region Static Helper Functions
static func show_item_drag_preview(item: InventoryItem, position: Vector2):
	"""Static helper to show drag preview"""
	if instance:
		instance.show_drag_preview(item, position)

static func update_drag_position(position: Vector2):
	"""Static helper to update drag position"""
	if instance:
		instance.update_drag_preview_position(position)

static func hide_item_drag_preview():
	"""Static helper to hide drag preview"""
	if instance:
		instance.hide_drag_preview()

static func is_currently_dragging() -> bool:
	"""Static helper to check if dragging"""
	if instance:
		return instance.is_dragging()
	return false
#endregion
