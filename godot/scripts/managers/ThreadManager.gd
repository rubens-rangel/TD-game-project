extends RefCounted
class_name ThreadManager

# Sistema de processamento em batches para cálculos pesados
# Usa processamento distribuído em frames para não travar a thread principal

# Flags para controlar threading
var use_threading: bool = true
var max_batch_size: int = 10  # Reduzido drasticamente para melhor performance
var pathfinding_queue: Array = []  # Fila de pathfinding pendente
var processing_pathfinding: bool = false

func _init():
	pass

func queue_pathfinding(pathfinder: Pathfinder, from_c: int, from_r: int, base_grid: Array, callback: Callable) -> void:
	"""Adiciona um cálculo de pathfinding à fila para processamento assíncrono"""
	if not use_threading:
		# Fallback síncrono
		var path = pathfinder.find_path(from_c, from_r, base_grid)
		callback.call(path)
		return
	
	pathfinding_queue.append({
		"pathfinder": pathfinder,
		"from_c": from_c,
		"from_r": from_r,
		"base_grid": base_grid,
		"callback": callback
	})

func process_pathfinding_batch() -> void:
	"""Processa um batch de pathfinding pendente (chamar no _process) - otimizado"""
	if pathfinding_queue.is_empty() or processing_pathfinding:
		return
	
	processing_pathfinding = true
	var processed = 0
	
	# Processar em batches menores para não travar
	while not pathfinding_queue.is_empty() and processed < max_batch_size:
		var task = pathfinding_queue.pop_front()
		# Usar call_deferred para distribuir processamento ao longo de vários frames
		call_deferred("_process_single_pathfinding", task)
		processed += 1
	
	processing_pathfinding = false

func _process_single_pathfinding(task: Dictionary) -> void:
	"""Processa uma única tarefa de pathfinding"""
	var path = task.pathfinder.find_path(task.from_c, task.from_r, task.base_grid)
	task.callback.call(path)

func calculate_enemy_updates_batch(enemies: Array, delta: float, update_func: Callable, start_idx: int = 0) -> int:
	"""Atualiza um batch de inimigos e retorna o próximo índice"""
	if not use_threading:
		# Processar todos de uma vez
		for i in range(enemies.size()):
			update_func.call(enemies[i], delta)
		return enemies.size()
	
	var end_idx = min(start_idx + max_batch_size, enemies.size())
	for i in range(start_idx, end_idx):
		if i < enemies.size():
			update_func.call(enemies[i], delta)
	
	return end_idx

func clear_pathfinding_queue() -> void:
	"""Limpa a fila de pathfinding pendente"""
	pathfinding_queue.clear()
	processing_pathfinding = false

func get_queue_size() -> int:
	"""Retorna o tamanho da fila de pathfinding"""
	return pathfinding_queue.size()
