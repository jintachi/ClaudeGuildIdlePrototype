extends Node

#region Tooltip System
var tooltip_scene: PackedScene
var current_tooltip: Control = null
var tooltip_delay: float = 0.5  # Delay before showing tooltip
var tooltip_timer: float = 0.0
var is_hovering: bool = false
var hover_target: Control = null
var hover_item: InventoryItem = null
#endregion

#region Signals
signal tooltip_shown(item: InventoryItem)
signal tooltip_hidden()
#endregion

func _ready():
	"""Initialize the tooltip manager"""

	
	# Load tooltip scene
	tooltip_scene = preload("res://ui/components/ItemTooltip.tscn")
	
	# Add tooltip to scene tree
	create_tooltip()

func _process(delta):
	"""Handle tooltip timing"""
	if is_hovering and hover_item:
		tooltip_timer += delta
		if tooltip_timer >= tooltip_delay and not current_tooltip.visible:
			show_tooltip(hover_item, hover_target)

func create_tooltip():
	"""Create and add tooltip to UI layer"""
	if current_tooltip:
		UILayerManager.remove_from_layer(current_tooltip)
	
	current_tooltip = UILayerManager.add_tooltip_to_layer(tooltip_scene)

func show_tooltip(item: InventoryItem, target_control: Control = null):
	"""Show tooltip for the given item"""
	if not current_tooltip or not item:
		return
	
	# Prevent showing tooltip if already visible for the same item
	if current_tooltip.visible and current_tooltip.current_item == item:
		return
	
	# Calculate position
	var position = Vector2.ZERO
	if target_control:
		# Position relative to the target control
		var target_rect = target_control.get_global_rect()
		position = Vector2(target_rect.position.x + target_rect.size.x + 5, target_rect.position.y)
	else:
		# Position near mouse
		position = get_viewport().get_mouse_position() + Vector2(10, 10)
	
	current_tooltip.show_tooltip(item, position)
	tooltip_shown.emit(item)

func hide_tooltip():
	"""Hide the current tooltip"""
	if current_tooltip:
		current_tooltip.hide_tooltip()
	tooltip_hidden.emit()

func start_hover(item: InventoryItem, target_control: Control = null):
	"""Start hovering over an item (for delayed tooltip)"""
	hover_item = item
	hover_target = target_control
	is_hovering = true
	tooltip_timer = 0.0

func stop_hover():
	"""Stop hovering (hide tooltip immediately)"""
	is_hovering = false
	hover_item = null
	hover_target = null
	tooltip_timer = 0.0
	hide_tooltip()

func set_tooltip_delay(delay: float):
	"""Set the delay before showing tooltip"""
	tooltip_delay = max(0.0, delay)

func set_tooltip_size(width: int, height: int):
	"""Set custom tooltip size"""
	if current_tooltip:
		current_tooltip.set_tooltip_size(width, height)

#region Static Helper Functions
func show_item_tooltip(item: InventoryItem, target_control: Control = null):
	"""Static helper to show item tooltip"""
	if self:
		self.show_tooltip(item, target_control)

func hide_item_tooltip():
	"""Static helper to hide item tooltip"""
	if self:
		self.hide_tooltip()

func start_item_hover(item: InventoryItem, target_control: Control = null):
	"""Static helper to start item hover"""
	if self:
		self.start_hover(item, target_control)

func stop_item_hover():
	"""Static helper to stop item hover"""
	if self:
		self.stop_hover()
#endregion
