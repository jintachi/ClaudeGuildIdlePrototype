extends Node

#region Singleton Setup
static var instance: Node
#endregion

#region UI Layer Management
var ui_layer: CanvasLayer = null
var ui_layer_scene: PackedScene
#endregion

#region Signals
signal ui_layer_initialized()
signal ui_element_registered(element: Control, type: String)
signal ui_element_unregistered(element: Control, type: String)
#endregion

func _ready():
	"""Initialize the UI Layer Manager"""
	instance = self
	
	# Load UI Layer scene
	ui_layer_scene = preload("res://ui/UILayer.tscn")
	
	# Initialize UI Layer
	initialize_ui_layer()

func initialize_ui_layer():
	"""Initialize the UI Layer in the scene tree"""
	if ui_layer:
		return  # Already initialized
	
	# Create UI Layer
	ui_layer = ui_layer_scene.instantiate()
	get_tree().root.call_deferred("add_child",ui_layer)
	
	# Connect to UI Layer signals
	ui_layer.ui_element_added.connect(_on_ui_element_added)
	ui_layer.ui_element_removed.connect(_on_ui_element_removed)
	ui_layer.ui_layer_ready.connect(_on_ui_layer_ready)
	
	ui_layer_initialized.emit()

func _on_ui_layer_ready():
	"""Handle UI Layer ready signal"""
	print("UI Layer initialized and ready")

func _on_ui_element_added(element: Control, type: String):
	"""Handle UI element added signal"""
	ui_element_registered.emit(element, type)

func _on_ui_element_removed(element: Control, type: String):
	"""Handle UI element removed signal"""
	ui_element_unregistered.emit(element, type)

#region UI Element Management
func add_tooltip(tooltip_scene: PackedScene) -> Control:
	"""Add a tooltip to the UI layer"""
	if not ui_layer:
		initialize_ui_layer()
	
	var tooltip = tooltip_scene.instantiate()
	return ui_layer.add_tooltip(tooltip)

func add_context_menu(menu_scene: PackedScene):
	"""Add a context menu to the UI layer"""
	if not ui_layer:
		initialize_ui_layer()
	
	var menu = menu_scene.instantiate()
	return ui_layer.add_context_menu(menu)

func add_modal(modal_scene: PackedScene) -> Control:
	"""Add a modal dialog to the UI layer"""
	print("UILayerManager.add_modal called - ui_layer: ", ui_layer != null)
	if not ui_layer:
		print("Initializing UI layer...")
		initialize_ui_layer()
	
	var modal = modal_scene.instantiate()
	print("Modal instantiated: ", modal != null)
	var result = ui_layer.add_modal(modal)
	print("UI layer add_modal result: ", result != null)
	return result

func add_overlay(overlay_scene: PackedScene) -> Control:
	"""Add an overlay to the UI layer"""
	if not ui_layer:
		initialize_ui_layer()
	
	var overlay = overlay_scene.instantiate()
	return ui_layer.add_overlay(overlay)

func add_notification(notification_scene: PackedScene) -> Control:
	"""Add a notification to the UI layer"""
	if not ui_layer:
		initialize_ui_layer()
	
	var notification_control = notification_scene.instantiate()
	return ui_layer.add_notification(notification_control)

func remove_ui_element(element: Control):
	"""Remove a UI element from the UI layer"""
	if not ui_layer:
		return
	
	# Determine element type and remove accordingly
	if ui_layer.active_tooltips.has(element):
		ui_layer.remove_tooltip(element)
	elif ui_layer.active_context_menus.has(element):
		ui_layer.remove_context_menu(element)
	elif ui_layer.active_modals.has(element):
		ui_layer.remove_modal(element)
	elif ui_layer.active_overlays.has(element):
		ui_layer.remove_overlay(element)
	elif ui_layer.active_notifications.has(element):
		ui_layer.remove_notification(element)

func clear_all_ui_elements():
	"""Clear all UI elements from the UI layer"""
	if ui_layer:
		ui_layer.clear_all_ui_elements()

func get_ui_layer() -> CanvasLayer:
	"""Get the UI Layer instance"""
	if not ui_layer:
		initialize_ui_layer()
	return ui_layer
#endregion

#region Static Helper Functions
static func add_tooltip_to_layer(tooltip_scene: PackedScene) -> Control:
	"""Static helper to add tooltip to UI layer"""
	if instance:
		return instance.add_tooltip(tooltip_scene)
	return null

static func add_context_menu_to_layer(menu_scene: PackedScene) -> Control:
	"""Static helper to add context menu to UI layer"""
	if instance:
		var menu_instance = menu_scene.instantiate()
		return instance.add_context_menu(menu_instance)
	return null

static func add_modal_to_layer(modal_scene: PackedScene) -> Control:
	"""Static helper to add modal to UI layer"""
	print("UILayerManager.add_modal_to_layer called - instance: ", instance != null)
	if instance:
		var result = instance.add_modal(modal_scene)
		print("UILayerManager.add_modal result: ", result != null)
		return result
	print("UILayerManager instance is null!")
	return null

static func add_overlay_to_layer(overlay_scene: PackedScene) -> Control:
	"""Static helper to add overlay to UI layer"""
	if instance:
		return instance.add_overlay(overlay_scene)
	return null

static func add_notification_to_layer(notification_scene: PackedScene) -> Control:
	"""Static helper to add notification to UI layer"""
	if instance:
		return instance.add_notification(notification_scene)
	return null

static func remove_from_layer(element: Control):
	"""Static helper to remove element from UI layer"""
	if instance:
		instance.remove_ui_element(element)

static func clear_layer():
	"""Static helper to clear all UI elements from layer"""
	if instance:
		instance.clear_all_ui_elements()

static func get_layer() -> CanvasLayer:
	"""Static helper to get UI layer"""
	if instance:
		return instance.get_ui_layer()
	return null
#endregion
