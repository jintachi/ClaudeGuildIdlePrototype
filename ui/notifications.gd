extends CanvasLayer

@onready var container: VBoxContainer = $VBoxContainer
@export var popup_scene: PackedScene = preload("res://ui/NotificationPopup.tscn")

func show_notification(text: String) -> void:
	var popup = popup_scene.instantiate()
	popup.set_text(text)
	container.add_child(popup)
