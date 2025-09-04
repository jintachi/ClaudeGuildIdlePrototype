extends CanvasLayer

#region UI Layer Management
var ui_elements: Control
var tooltips_container: Control
var context_menus_container: Control
var modals_container: Control
var overlays_container: Control
var notifications_container: Control

# UI element tracking
var active_tooltips: Array[Control] = []
var active_context_menus: Array = []
var active_modals: Array[Control] = []
var active_overlays: Array[Control] = []
var active_notifications: Array[Control] = []
#endregion

#region Signals
signal ui_element_added(element, type: String)
signal ui_element_removed(element, type: String)
signal ui_layer_ready()
#endregion

func _ready():
	"""Initialize the UI Layer"""
	# Get main container reference
	ui_elements = $UIElements
	
	# Create UI element containers programmatically
	create_ui_containers()
	
	ui_layer_ready.emit()

func create_ui_containers():
	"""Create all UI element containers"""
	# Create Tooltips container
	tooltips_container = create_container("Tooltips", 1000)
	
	# Create ContextMenus container
	context_menus_container = create_container("ContextMenus", 900)
	
	# Create Modals container
	modals_container = create_container("Modals", 800)
	
	# Create Overlays container
	overlays_container = create_container("Overlays", 700)
	
	# Create Notifications container
	notifications_container = create_container("Notifications", 600)

func create_container(container_name: String, z_index_value: int) -> Control:
	"""Create a UI container with the specified name and z_index"""
	var container = Control.new()
	container.name = container_name
	container.layout_mode = Control.PRESET_FULL_RECT
	container.anchors_preset = Control.PRESET_FULL_RECT
	container.anchor_right = 1.0
	container.anchor_bottom = 1.0
	container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	container.grow_vertical = Control.GROW_DIRECTION_BOTH
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.z_index = z_index_value
	
	ui_elements.add_child(container)
	return container

func add_tooltip(tooltip: Control) -> Control:
	"""Add a tooltip to the UI layer"""
	tooltips_container.add_child(tooltip)
	active_tooltips.append(tooltip)
	ui_element_added.emit(tooltip, "tooltip")
	return tooltip

func add_context_menu(menu):
	"""Add a context menu to the UI layer"""
	# Handle PopupMenu (which extends Window) differently from Control-based menus
	if menu is PopupMenu:
		# PopupMenu extends Window, so we add it as a child of the main scene
		# instead of trying to add it to a Control container
		get_tree().current_scene.add_child(menu)
		active_context_menus.append(menu)
		ui_element_added.emit(menu, "context_menu")
		return menu
	else:
		# Handle regular Control-based context menus
		context_menus_container.add_child(menu)
		active_context_menus.append(menu)
		ui_element_added.emit(menu, "context_menu")
		return menu

func add_modal(modal: Control) -> Control:
	"""Add a modal dialog to the UI layer"""
	modals_container.add_child(modal)
	active_modals.append(modal)
	ui_element_added.emit(modal, "modal")
	return modal

func add_overlay(overlay: Control) -> Control:
	"""Add an overlay to the UI layer"""
	overlays_container.add_child(overlay)
	active_overlays.append(overlay)
	ui_element_added.emit(overlay, "overlay")
	return overlay

func add_notification(notification_control: Control) -> Control:
	"""Add a notification to the UI layer"""
	notifications_container.add_child(notification_control)
	active_notifications.append(notification_control)
	ui_element_added.emit(notification_control, "notification")
	return notification_control

func remove_tooltip(tooltip: Control):
	"""Remove a tooltip from the UI layer"""
	if tooltip in active_tooltips:
		active_tooltips.erase(tooltip)
		tooltip.queue_free()
		ui_element_removed.emit(tooltip, "tooltip")

func remove_context_menu(menu):
	"""Remove a context menu from the UI layer"""
	if menu in active_context_menus:
		active_context_menus.erase(menu)
		menu.queue_free()
		ui_element_removed.emit(menu, "context_menu")

func remove_modal(modal: Control):
	"""Remove a modal from the UI layer"""
	if modal in active_modals:
		active_modals.erase(modal)
		modal.queue_free()
		ui_element_removed.emit(modal, "modal")

func remove_overlay(overlay: Control):
	"""Remove an overlay from the UI layer"""
	if overlay in active_overlays:
		active_overlays.erase(overlay)
		overlay.queue_free()
		ui_element_removed.emit(overlay, "overlay")

func remove_notification(notification_control: Control):
	"""Remove a notification from the UI layer"""
	if notification_control in active_notifications:
		active_notifications.erase(notification_control)
		notification_control.queue_free()
		ui_element_removed.emit(notification_control, "notification")

func clear_all_tooltips():
	"""Clear all active tooltips"""
	for tooltip in active_tooltips.duplicate():
		remove_tooltip(tooltip)

func clear_all_context_menus():
	"""Clear all active context menus"""
	for menu in active_context_menus.duplicate():
		remove_context_menu(menu)

func clear_all_modals():
	"""Clear all active modals"""
	for modal in active_modals.duplicate():
		remove_modal(modal)

func clear_all_overlays():
	"""Clear all active overlays"""
	for overlay in active_overlays.duplicate():
		remove_overlay(overlay)

func clear_all_notifications():
	"""Clear all active notifications"""
	for notification_control in active_notifications.duplicate():
		remove_notification(notification_control)

func clear_all_ui_elements():
	"""Clear all UI elements"""
	clear_all_tooltips()
	clear_all_context_menus()
	clear_all_modals()
	clear_all_overlays()
	clear_all_notifications()

func get_active_ui_count() -> Dictionary:
	"""Get count of active UI elements by type"""
	return {
		"tooltips": active_tooltips.size(),
		"context_menus": active_context_menus.size(),
		"modals": active_modals.size(),
		"overlays": active_overlays.size(),
		"notifications": active_notifications.size()
	}

func is_ui_element_active(element) -> bool:
	"""Check if a UI element is currently active"""
	return (element in active_tooltips or 
			element in active_context_menus or 
			element in active_modals or 
			element in active_overlays or 
			element in active_notifications)
