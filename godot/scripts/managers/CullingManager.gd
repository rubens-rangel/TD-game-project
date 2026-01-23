extends RefCounted
class_name CullingManager

# Sistema de Culling e LOD (Level of Detail) para otimização de performance
# Remove objetos fora da tela e reduz qualidade de objetos distantes

var viewport_size: Vector2 = Vector2.ZERO
var cull_margin: float = 100.0  # Margem extra para culling (evitar flickering)
var lod_distance_near: float = 500.0  # Distância para LOD próximo
var lod_distance_far: float = 1000.0  # Distância para LOD distante

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
		return 0  # Alto detalhe
	elif distance < lod_distance_far:
		return 1  # Médio detalhe
	elif distance < lod_distance_far * 1.5:
		return 2  # Baixo detalhe
	else:
		return 3  # Muito baixo detalhe

func should_update_logic(pos: Vector2, camera_pos: Vector2 = Vector2.ZERO) -> bool:
	"""Determina se a lógica de um objeto deve ser atualizada
	Objetos muito distantes podem ter lógica simplificada"""
	var distance = pos.distance_to(camera_pos)
	return distance < lod_distance_far * 2.0  # Atualizar lógica até 2x a distância LOD

func should_render(pos: Vector2, camera_pos: Vector2 = Vector2.ZERO) -> bool:
	"""Determina se um objeto deve ser renderizado"""
	return is_visible(pos, camera_pos)

func get_particle_count_for_lod(lod_level: int, base_count: int) -> int:
	"""Retorna o número de partículas baseado no LOD"""
	match lod_level:
		0:
			return base_count  # 100%
		1:
			return int(base_count * 0.7)  # 70%
		2:
			return int(base_count * 0.4)  # 40%
		3:
			return int(base_count * 0.2)  # 20%
		_:
			return base_count

func get_update_rate_for_lod(lod_level: int) -> float:
	"""Retorna a taxa de atualização baseada no LOD (para objetos distantes)"""
	match lod_level:
		0:
			return 1.0  # Atualizar todo frame
		1:
			return 0.5  # Atualizar a cada 2 frames
		2:
			return 0.25  # Atualizar a cada 4 frames
		3:
			return 0.1  # Atualizar a cada 10 frames
		_:
			return 1.0
