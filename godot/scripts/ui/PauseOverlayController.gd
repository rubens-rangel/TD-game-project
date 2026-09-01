extends Control

signal escape_pressed

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		escape_pressed.emit()
		get_viewport().set_input_as_handled()
