class_name UIUtilities
extends RefCounted

#region Character Panel Creation
static func create_character_panel(character: Character, context: String = "default") -> Panel:
	"""Create a character panel for display with right-click support"""
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(180, 120)
	
	# Store character reference and context for right-click handling
	panel.set_meta("character", character)
	panel.set_meta("context", context)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	
	# Enable right-click detection
	panel.gui_input.connect(_on_character_panel_gui_input.bind(panel))
	
	var hbox = HBoxContainer.new()
	panel.add_child(hbox)
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Add padding to prevent content from touching panel edges
	hbox.add_theme_constant_override("separation", 6)
	hbox.add_theme_constant_override("margin_left", 4)
	hbox.add_theme_constant_override("margin_right", 4)
	hbox.add_theme_constant_override("margin_top", 4)
	hbox.add_theme_constant_override("margin_bottom", 4)
	
	
	# Character portrait/icon
	var portrait_texture = character.get_portrait_texture()
	if portrait_texture:
		var portrait = TextureRect.new()
		portrait.texture = portrait_texture
		portrait.custom_minimum_size = Vector2(100, 100) # Constrain maximum size
		portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		portrait.clip_contents = true  # Prevent overflow
		hbox.add_child(portrait)
		
	
	# Character info container
	var vbox = VBoxContainer.new()
	hbox.add_child(vbox)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	
	
	# Character name
	var name_label = Label.new()
	name_label.text = character.character_name
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.clip_contents = true
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(name_label)
	
	# Character class and quality
	var details_label = Label.new()
	var quality_name = "★".repeat(character.quality)  # Convert quality enum to star display
	details_label.text = "%s - %s" % [character.get_class_name(), quality_name]
	details_label.add_theme_font_size_override("font_size", 10)
	details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_label.clip_contents = true
	details_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(details_label)
	
	# Character stats
	var stats_label = Label.new()
	stats_label.text = "ATK: %d | DEF: %d | SPD: %d" % [character.attack_power, character.defense, character.movement_speed]
	stats_label.add_theme_font_size_override("font_size", 9)
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_label.clip_contents = true
	stats_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(stats_label)
	
	return panel

static func _on_character_panel_gui_input(event: InputEvent, panel: Panel):
	"""Handle GUI input for character panels (right-click context menu)"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var character = panel.get_meta("character")
			var context = panel.get_meta("context")
			
			if character and ContextMenuManager:
				# Show context menu based on the context
				match context:
					"roster":
						ContextMenuManager.show_character_context_menu(character, event.global_position)
					"party_selection":
						ContextMenuManager.show_character_context_menu(character, event.global_position)
					"recruitment":
						ContextMenuManager.show_character_context_menu(character, event.global_position)
					_:
						ContextMenuManager.show_character_context_menu(character, event.global_position)

static func create_roster_character_panel(character: Character) -> Panel:
	"""Create a character panel specifically for roster display"""
	return create_character_panel(character, "roster")

static func create_recruitment_character_panel(character: Character) -> Panel:
	"""Create a character panel specifically for recruitment display"""
	return create_character_panel(character, "recruitment")

static func create_party_selection_character_panel(character: Character) -> Panel:
	"""Create a character panel specifically for party selection"""
	return create_character_panel(character, "party_selection")
#endregion

#region Resource Display Creation
static func create_resource_display(resource_name: String, amount: int, max_amount: int = -1) -> HBoxContainer:
	"""Create a resource display line"""
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	
	var name_label = Label.new()
	name_label.text = resource_name + ":"
	name_label.custom_minimum_size.x = 120
	container.add_child(name_label)
	
	var amount_label = Label.new()
	if max_amount > 0:
		amount_label.text = "%d/%d" % [amount, max_amount]
	else:
		amount_label.text = str(amount)
	container.add_child(amount_label)
	
	return container

static func create_guild_status_display(status_data: Dictionary) -> VBoxContainer:
	"""Create a guild status display panel"""
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	
	# Add resource displays
	for resource_name in status_data.keys():
		var amount = status_data[resource_name]
		var resource_display = create_resource_display(resource_name, amount)
		container.add_child(resource_display)
	
	return container
#endregion

#region Quest Panel Creation
static func create_quest_panel(quest: Quest) -> Panel:
	"""Create a quest panel for display"""
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(250, 120)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	
	# Quest header
	var header_container = HBoxContainer.new()
	vbox.add_child(header_container)
	
	var rank_label = Label.new()
	rank_label.text = "[%s]" % quest.get_rank_name()
	rank_label.add_theme_font_size_override("font_size", 12)
	header_container.add_child(rank_label)
	
	var title_label = Label.new()
	title_label.text = quest.quest_name
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_container.add_child(title_label)
	
	# Quest description
	var desc_label = Label.new()
	desc_label.text = quest.description
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	
	# Quest rewards
	var rewards_label = Label.new()
	rewards_label.text = "Rewards: %s" % quest.get_rewards_text()
	rewards_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(rewards_label)
	
	return panel
#endregion

#region Item Panel Creation
static func create_item_panel(item: InventoryItem) -> Panel:
	"""Create an item panel for display"""
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(150, 80)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	
	# Item name
	var name_label = Label.new()
	name_label.text = item.item_name
	name_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(name_label)
	
	# Item quantity
	var quantity_label = Label.new()
	quantity_label.text = "Quantity: %d" % item.quantity
	quantity_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(quantity_label)
	
	return panel
#endregion

#region Utility Functions
static func clear_container(container: Control):
	"""Clear all children from a container"""
	if not container:
		return
	
	for child in container.get_children():
		child.queue_free()

static func create_placeholder_label(text: String) -> Label:
	"""Create a placeholder label with standard styling"""
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.GRAY)
	label.add_theme_font_size_override("font_size", 14)
	return label

static func create_separator() -> HSeparator:
	"""Create a horizontal separator"""
	return HSeparator.new()

static func create_spacer(size: Vector2 = Vector2(10, 10)) -> Control:
	"""Create a spacer control"""
	var spacer = Control.new()
	spacer.custom_minimum_size = size
	return spacer

static func create_button(text: String, callback: Callable = Callable()) -> Button:
	"""Create a button with optional callback"""
	var button = Button.new()
	button.text = text
	if callback.is_valid():
		button.pressed.connect(callback)
	return button

static func create_progress_bar(current: float, max_value: float, text: String = "") -> ProgressBar:
	"""Create a progress bar with optional text"""
	var progress_bar = ProgressBar.new()
	progress_bar.max_value = max_value
	progress_bar.value = current
	if text != "":
		progress_bar.show_percentage = false
		progress_bar.text_over = text
	return progress_bar
#endregion
