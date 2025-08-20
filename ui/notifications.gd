extends Control

## Notification System
## Handles fade-in, display, and fade-out of various game notifications

@export var notification_container: VBoxContainer
@export var notification_scene: PackedScene

# Notification display settings
const FADE_IN_DURATION = 0.5
const DISPLAY_DURATION = 5.0
const FADE_OUT_DURATION = 0.5
const MAX_NOTIFICATIONS = 5

var active_notifications: Array[Control] = []

func _ready():
	# Set up the notification container if not assigned
	if not notification_container:
		notification_container = VBoxContainer.new()
		notification_container.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		notification_container.position = Vector2(120, 20)  # Offset from right edge
		notification_container.size = Vector2(300, 0)
		add_child(notification_container)
	
	# Connect to SignalBus signals
	SignalBus.quest_started_notification.connect(_on_quest_started_notification)
	SignalBus.quest_completed_notification.connect(_on_quest_completed_notification)
	SignalBus.character_recruited_notification.connect(_on_character_recruited_notification)
	SignalBus.resource_gained_notification.connect(_on_resource_gained_notification)
	SignalBus.character_injured_notification.connect(_on_character_injured_notification)
	SignalBus.character_leveled_up.connect(_on_character_leveled_up)
	SignalBus.notification_requested.connect(_on_notification_requested)

## Show a notification with specified type and message
func show_notification(type: String, title: String, message: String = "", icon: Texture2D = null):
	var notification_panel = _create_notification(type, title, message, icon)
	_add_notification(notification_panel)

## Create notification popup based on type
func _create_notification(type: String, title: String, message: String, icon: Texture2D) -> Control:
	return _create_notification_panel(type, title, message, icon)

## Add notification to container and manage lifecycle
func _add_notification(notif_panel: Control):
	# Remove oldest if at limit
	if active_notifications.size() >= MAX_NOTIFICATIONS:
		var oldest = active_notifications[0]
		_remove_notification(oldest, true)
	
	# Add to container and track
	notification_container.add_child(notif_panel)
	active_notifications.append(notif_panel)
	
	# Start the notification lifecycle
	_animate_notification(notif_panel)

## Handle notification animation lifecycle
func _animate_notification(notif_panel: Control):
	var tween = create_tween()
	
	# Start invisible
	notif_panel.modulate.a = 0.0
	
	# Fade in
	tween.tween_property(notif_panel, "modulate:a", 1.0, FADE_IN_DURATION)
	
	# Wait for display duration
	tween.tween_interval(DISPLAY_DURATION)
	
	# Fade out
	tween.tween_property(notif_panel, "modulate:a", 0.0, FADE_OUT_DURATION)
	
	# Remove when done
	tween.tween_callback(_remove_notification.bind(notif_panel, false))

## Remove notification from display
func _remove_notification(notif_panel: Control, immediate: bool = false):
	if notif_panel in active_notifications:
		active_notifications.erase(notif_panel)
	
	if immediate:
		notif_panel.queue_free()
	else:
		# Allow fade-out to complete before removal
		if notif_panel and is_instance_valid(notif_panel):
			notif_panel.queue_free()

## Quick notification functions for common types
func show_quest_started(quest_name: String):
	show_notification("quest_start", "Quest Started", "Party sent on: " + quest_name)

func show_quest_completed(quest_name: String):
	show_notification("quest_complete", "Quest Completed", quest_name + " has been completed!")

func show_character_recruited(character_name: String):
	show_notification("recruitment", "Character Recruited", character_name + " has joined your guild!")

func show_resource_gained(resource_type: String, amount: int):
	show_notification("resource", "Resources Gained", "+%d %s" % [amount, resource_type])

func show_character_injured(character_name: String, injury_type: String):
	show_notification("injury", "Character Injured", "%s has been injured: %s" % [character_name, injury_type])

func show_character_leveled_up(character_name: String, stat_gains: Dictionary):
	var stat_text = ""
	var gained_stats = []
	
	for stat_name in stat_gains.keys():
		var gain = stat_gains[stat_name]
		if gain > 0:
			gained_stats.append("%s +%d" % [stat_name.capitalize(), gain])
	
	if gained_stats.size() > 0:
		stat_text = "Gained: " + ", ".join(gained_stats)
	else:
		stat_text = "No stat gains this level"
	
	show_notification("level_up", "Level Up!", "%s leveled up! %s" % [character_name, stat_text])

func show_error(message: String):
	show_notification("error", "Error", message)

func show_info(title: String, message: String = ""):
	show_notification("info", title, message)

## Create notification popup based on type - returns a Panel with notification UI
func _create_notification_panel(type: String, title: String, message: String, icon: Texture2D) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(280, 80)
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)
	
	# Icon (optional)
	if icon:
		var icon_texture = TextureRect.new()
		icon_texture.texture = icon
		icon_texture.custom_minimum_size = Vector2(32, 32)
		icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(icon_texture)
	
	# Text content
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_font_override("font", ThemeDB.fallback_font)
	vbox.add_child(title_label)
	
	if message.length() > 0:
		var message_label = Label.new()
		message_label.text = message
		message_label.add_theme_font_size_override("font_size", 12)
		message_label.modulate = Color(0.8, 0.8, 0.8)
		message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(message_label)
	
	# Apply theme based on type
	match type:
		"quest_complete":
			panel.modulate = Color(0.7, 1.0, 0.7)  # Light green
		"quest_start":
			panel.modulate = Color(0.7, 0.7, 1.0)  # Light blue
		"recruitment":
			panel.modulate = Color(1.0, 1.0, 0.7)  # Light yellow
		"resource":
			panel.modulate = Color(0.9, 0.7, 1.0)  # Light purple
		"injury":
			panel.modulate = Color(1.0, 0.8, 0.6)  # Light orange
		"level_up":
			panel.modulate = Color(1.0, 0.9, 0.5)  # Golden yellow
		"error":
			panel.modulate = Color(1.0, 0.7, 0.7)  # Light red
		_:
			panel.modulate = Color(0.9, 0.9, 0.9)  # Light gray
	
	return panel

#region Signal Handlers
func _on_quest_started_notification(quest_name: String):
	show_quest_started(quest_name)

func _on_quest_completed_notification(quest_name: String):
	show_quest_completed(quest_name)

func _on_character_recruited_notification(character_name: String):
	show_character_recruited(character_name)

func _on_resource_gained_notification(resource_type: String, amount: int):
	show_resource_gained(resource_type, amount)

func _on_character_injured_notification(character_name: String, injury_type: String):
	show_character_injured(character_name, injury_type)

func _on_character_leveled_up(character: Character, stat_gains: Dictionary):
	show_character_leveled_up(character.character_name, stat_gains)

func _on_notification_requested(type: String, title: String, message: String, icon: Texture2D):
	show_notification(type, title, message, icon)
#endregion
