extends RefCounted
class_name NotificationManager


var notifications: Array = []

enum NotificationPosition {
	TOP_CENTER,
	TOP_LEFT,
	TOP_RIGHT,
	CENTER,
	BOTTOM_CENTER
}

func _init():
	pass

func show_notification(text: String, duration: float = 3.0, position: NotificationPosition = NotificationPosition.TOP_CENTER, color: Color = Color.WHITE) -> void:
	"""Adiciona uma nova notificação"""
	var notification = {
		"text": text,
		"duration": duration,
		"time": 0.0,
		"color": color,
		"position": position,
		"alpha": 1.0
	}
	notifications.append(notification)

func show_achievement_notification(achievement_name: String) -> void:
	"""Notificação especial para achievements"""
	show_notification("🏆 Conquista: %s" % achievement_name, 4.0, NotificationPosition.TOP_CENTER, Color(1.0, 0.9, 0.3))

func show_warning(text: String) -> void:
	"""Notificação de aviso (cor vermelha)"""
	show_notification(text, 3.0, NotificationPosition.TOP_CENTER, Color(1.0, 0.3, 0.3))

func show_success(text: String) -> void:
	"""Notificação de sucesso (cor verde)"""
	show_notification(text, 2.5, NotificationPosition.TOP_CENTER, Color(0.3, 1.0, 0.3))

func update_notifications(delta: float) -> void:
	"""Atualiza todas as notificações"""
	var i := 0
	while i < notifications.size():
		var notification = notifications[i]
		notification.time += delta
		var fade_start = notification.duration - 0.5
		if notification.time > fade_start:
			var fade_progress = (notification.time - fade_start) / 0.5
			notification.alpha = 1.0 - fade_progress
		if notification.time >= notification.duration:
			notifications[i] = notifications[notifications.size() - 1]
			notifications.pop_back()
		else:
			i += 1

func get_notifications() -> Array:
	"""Retorna lista de notificações ativas"""
	return notifications

func clear_all() -> void:
	"""Limpa todas as notificações"""
	notifications.clear()
