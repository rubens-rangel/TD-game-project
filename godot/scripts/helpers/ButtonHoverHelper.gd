extends RefCounted
class_name ButtonHoverHelper

static func setup_button_hover(button: Button):
	if not button:
		return
	if not button.has_meta("original_scale"):
		button.set_meta("original_scale", button.scale)
	if not button.has_meta("hover_connected"):
		button.mouse_entered.connect(_on_mouse_entered.bind(button))
		button.mouse_exited.connect(_on_mouse_exited.bind(button))
		button.button_down.connect(_on_button_down.bind(button))
		button.button_up.connect(_on_button_up.bind(button))
		button.resized.connect(_center_pivot.bind(button))
		button.set_meta("hover_connected", true)
	_center_pivot(button)

static func _center_pivot(button: Button) -> void:
	if button:
		button.pivot_offset = button.size * 0.5

static func _kill_tween(button: Button) -> void:
	if button.has_meta("hover_tween"):
		var old = button.get_meta("hover_tween")
		if old is Tween:
			old.kill()

static func _tween_scale(button: Button, target: Vector2, duration: float) -> void:
	_center_pivot(button)
	_kill_tween(button)
	var tween := button.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(button, "scale", target, duration)
	button.set_meta("hover_tween", tween)

static func _on_mouse_entered(button: Button):
	if button.disabled:
		return
	button.modulate = Color(1.08, 1.08, 1.12, 1.0)

static func _on_mouse_exited(button: Button):
	if button.disabled:
		return
	button.modulate = Color.WHITE
	var original_scale: Vector2 = button.get_meta("original_scale", Vector2.ONE)
	_tween_scale(button, original_scale, GameConstants.BUTTON_HOVER_TRANSITION_TIME)

static func _on_button_down(button: Button):
	if button.disabled:
		return
	var original_scale: Vector2 = button.get_meta("original_scale", Vector2.ONE)
	_tween_scale(button, original_scale * GameConstants.BUTTON_PRESS_SCALE, GameConstants.BUTTON_PRESS_TRANSITION_TIME)

static func _on_button_up(button: Button):
	if button.disabled:
		return
	var original_scale: Vector2 = button.get_meta("original_scale", Vector2.ONE)
	_tween_scale(button, original_scale, GameConstants.BUTTON_PRESS_TRANSITION_TIME)
	if button.is_hovered():
		button.modulate = Color(1.08, 1.08, 1.12, 1.0)
	else:
		button.modulate = Color.WHITE

static func setup_multiple_buttons(buttons: Array):
	for button in buttons:
		if button is Button:
			setup_button_hover(button)
