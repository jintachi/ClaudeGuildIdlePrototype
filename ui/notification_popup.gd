extends Panel

@export var display_time: float = 5.0

var _timer: float = 0.0
var _hovered: bool = false

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var label: Label = $Label

func _ready() -> void:
    _timer = display_time
    progress_bar.max_value = display_time
    progress_bar.value = display_time
    set_process(true)
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)

func set_text(text: String) -> void:
    label.text = text

func _process(delta: float) -> void:
    if not _hovered:
        _timer -= delta
        progress_bar.value = _timer
        if _timer <= 0:
            queue_free()

func _on_mouse_entered() -> void:
    _hovered = true
    _timer = display_time
    progress_bar.value = display_time

func _on_mouse_exited() -> void:
    _hovered = false
