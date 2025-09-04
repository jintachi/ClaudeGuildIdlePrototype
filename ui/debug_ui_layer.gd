extends Node

#region Debug UI Layer System
func _ready():
	"""Debug the UI Layer system"""
	print("=== UI Layer System Debug ===")
	
	# Wait a frame for autoloads to initialize
	await get_tree().process_frame
	
	# Test 1: Check if UILayerManager is available
	print("Test 1: Checking UILayerManager availability...")
	if UILayerManager:
		print("✓ UILayerManager is available")
		print("  - Instance: ", UILayerManager.instance)
		print("  - UI Layer: ", UILayerManager.ui_layer)
	else:
		print("✗ UILayerManager is not available")
		return
	
	# Test 2: Check if DragPreviewManager is available
	print("\nTest 2: Checking DragPreviewManager availability...")
	if DragPreviewManager:
		print("✓ DragPreviewManager is available")
		print("  - Instance: ", DragPreviewManager.instance)
	else:
		print("✗ DragPreviewManager is not available")
	
	# Test 3: Check if UI Layer is initialized
	print("\nTest 3: Checking UI Layer initialization...")
	if UILayerManager.ui_layer:
		print("✓ UI Layer is initialized")
		print("  - Layer: ", UILayerManager.ui_layer)
		print("  - Children: ", UILayerManager.ui_layer.get_children())
	else:
		print("✗ UI Layer is not initialized")
	
	# Test 4: Check UI Layer containers
	print("\nTest 4: Checking UI Layer containers...")
	if UILayerManager.ui_layer:
		var ui_elements = UILayerManager.ui_layer.get_node("UIElements")
		if ui_elements:
			print("✓ UIElements container found")
			for child in ui_elements.get_children():
				print("  - Container: ", child.name, " (z_index: ", child.z_index, ")")
		else:
			print("✗ UIElements container not found")
	
	# Test 5: Test adding a simple UI element
	print("\nTest 5: Testing UI element addition...")
	test_add_ui_element()
	
	print("\n=== Debug Complete ===")

func test_add_ui_element():
	"""Test adding a simple UI element"""
	# Create a simple test control
	var test_control = Control.new()
	test_control.custom_minimum_size = Vector2(100, 50)
	test_control.modulate = Color(1, 0, 0, 0.5)  # Semi-transparent red
	
	var label = Label.new()
	label.text = "Test UI Element"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	test_control.add_child(label)
	
	# Pack into a scene
	var test_scene = PackedScene.new()
	test_scene.pack(test_control)
	
	# Add to UI layer
	var added_element = UILayerManager.add_overlay_to_layer(test_scene)
	if added_element:
		print("✓ Successfully added test UI element")
		print("  - Element: ", added_element)
		print("  - Parent: ", added_element.get_parent())
		
		# Remove after 3 seconds
		await get_tree().create_timer(3.0).timeout
		UILayerManager.remove_from_layer(added_element)
		print("✓ Test UI element removed")
	else:
		print("✗ Failed to add test UI element")
