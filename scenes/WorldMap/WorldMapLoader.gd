extends Control

@onready var progress_bar = $ProgressBar

func set_progress(value: float):
	progress_bar.value = value
