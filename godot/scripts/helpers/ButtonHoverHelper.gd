extends RefCounted
class_name ButtonHoverHelper

# Helper para adicionar hover effects em botões

static func setup_button_hover(button: Button):
	"""Configura hover effects em um botão"""
	if not button:
		return
	
	# Armazena escala original
	if not button.has_meta("original_scale"):
		button.set_meta("original_scale", button.scale)
	
	# Conecta sinais de hover (verifica se já não estão conectados)
	if not button.has_meta("hover_connected"):
		button.mouse_entered.connect(_on_mouse_entered.bind(button))
		button.mouse_exited.connect(_on_mouse_exited.bind(button))
		button.button_down.connect(_on_button_down.bind(button))
		button.button_up.connect(_on_button_up.bind(button))
		button.set_meta("hover_connected", true)

static func _on_mouse_entered(button: Button):
	"""Quando mouse entra no botão"""
	if button.disabled:
		return
	
	var original_scale = button.get_meta("original_scale", Vector2.ONE)
	var target_scale = original_scale * GameConstants.BUTTON_HOVER_SCALE
	
	# Animação suave de escala
	var tween = button.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "scale", target_scale, GameConstants.BUTTON_HOVER_TRANSITION_TIME)
	
	# Muda cor de fundo
	button.modulate = Color(1.1, 1.1, 1.1, 1.0)

static func _on_mouse_exited(button: Button):
	"""Quando mouse sai do botão"""
	if button.disabled:
		return
	
	var original_scale = button.get_meta("original_scale", Vector2.ONE)
	
	# Animação suave de volta
	var tween = button.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "scale", original_scale, GameConstants.BUTTON_HOVER_TRANSITION_TIME)
	
	# Volta cor original
	button.modulate = Color.WHITE

static func _on_button_down(button: Button):
	"""Quando botão é pressionado"""
	if button.disabled:
		return
	
	var original_scale = button.get_meta("original_scale", Vector2.ONE)
	var press_scale = original_scale * GameConstants.BUTTON_PRESS_SCALE
	
	# Animação rápida de press
	var tween = button.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	tween.tween_property(button, "scale", press_scale, GameConstants.BUTTON_PRESS_TRANSITION_TIME)

static func _on_button_up(button: Button):
	"""Quando botão é solto"""
	if button.disabled:
		return
	
	var original_scale = button.get_meta("original_scale", Vector2.ONE)
	var hover_scale = original_scale * GameConstants.BUTTON_HOVER_SCALE
	
	# Volta para escala de hover (se mouse ainda estiver sobre)
	if button.is_hovered():
		var tween = button.create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(button, "scale", hover_scale, GameConstants.BUTTON_PRESS_TRANSITION_TIME)
	else:
		var tween = button.create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(button, "scale", original_scale, GameConstants.BUTTON_PRESS_TRANSITION_TIME)

static func setup_multiple_buttons(buttons: Array):
	"""Configura hover effects em múltiplos botões"""
	for button in buttons:
		if button is Button:
			setup_button_hover(button)



