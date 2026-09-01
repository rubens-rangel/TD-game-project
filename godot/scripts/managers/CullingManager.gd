extends RefCounted
class_name CullingManager


var viewport_size: Vector2 = Vector2.ZERO
var cull_margin: float = 100.0
var lod_distance_near: float = 500.0
var lod_distance_far: float = 1000.0

func _init():
	pass

func update_viewport_size(size: Vector2) -> void:
	"""Atualiza o tamanho da viewport para cálculos de culling"""
	viewport_size = size

func is_visible(pos: Vector2, camera_pos: Vector2 = Vector2.ZERO) -> bool:
	"""Verifica se uma posição está visível na tela"""
	var screen_pos = pos - camera_pos
	return screen_pos.x >= -cull_margin and screen_pos.x <= viewport_size.x + cull_margin and \
		   screen_pos.y >= -cull_margin and screen_pos.y <= viewport_size.y + cull_margin

func get_lod_level(pos: Vector2, camera_pos: Vector2 = Vector2.ZERO) -> int:
	"""Retorna o nível de LOD baseado na distância da câmera
	0 = Alto detalhe (próximo)
	1 = Médio detalhe
	2 = Baixo detalhe (distante)
	3 = Muito baixo detalhe (muito distante)"""
	var distance = pos.distance_to(camera_pos)
	if distance < lod_distance_near:
		return 0
	elif distance < lod_distance_far:
		return 1
	elif distance < lod_distance_far * 1.5:
		return 2
	else:
		return 3

func should_update_logic(pos: Vector2, camera_pos: Vector2 = Vector2.ZERO) -> bool:
	"""Determina se a lógica de um objeto deve ser atualizada
	Objetos muito distantes podem ter lógica simplificada"""
	var distance = pos.distance_to(camera_pos)
	return distance < lod_distance_far * 2.0

func should_render(pos: Vector2, camera_pos: Vector2 = Vector2.ZERO) -> bool:
	"""Determina se um objeto deve ser renderizado"""
	return is_visible(pos, camera_pos)
