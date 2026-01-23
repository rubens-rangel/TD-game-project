extends RefCounted
class_name ThreadManager

# Sistema de processamento em threads para cálculos pesados
# Usa threads reais do Godot para não travar a thread principal

# Flags para controlar threading
var use_threading: bool = true
var max_batch_size: int = 5  # Processar 5 por vez para não sobrecarregar
var pathfinding_queue: Array = []  # Fila de pathfinding pendente
var processing_pathfinding: bool = false
var pathfinding_thread: Thread = null
var pathfinding_mutex: Mutex = null
var pathfinding_results: Array = []  # Resultados prontos para processar na thread principal

func _init():
	pathfinding_mutex = Mutex.new()

func queue_pathfinding(pathfinder: Pathfinder, from_c: int, from_r: int, base_grid: Array, callback: Callable) -> void:
	"""Adiciona um cálculo de pathfinding à fila para processamento assíncrono"""
	if not use_threading:
		# Fallback síncrono
		var path = pathfinder.find_path(from_c, from_r, base_grid)
		callback.call(path)
		return
	
	pathfinding_mutex.lock()
	pathfinding_queue.append({
		"pathfinder": pathfinder,
		"from_c": from_c,
		"from_r": from_r,
		"base_grid": base_grid,
		"callback": callback,
		"id": pathfinding_queue.size()  # ID único para rastreamento
	})
	pathfinding_mutex.unlock()
	
	# Iniciar thread se não estiver rodando
	if pathfinding_thread == null or not pathfinding_thread.is_alive():
		_start_pathfinding_thread()

func _start_pathfinding_thread() -> void:
	"""Inicia a thread de pathfinding"""
	if pathfinding_thread != null and pathfinding_thread.is_alive():
		return
	
	pathfinding_thread = Thread.new()
	pathfinding_thread.start(_pathfinding_thread_worker)

func _pathfinding_thread_worker() -> void:
	"""Worker da thread de pathfinding - processa cálculos pesados em background"""
	while true:
		pathfinding_mutex.lock()
		if pathfinding_queue.is_empty():
			pathfinding_mutex.unlock()
			# Aguardar um pouco antes de verificar novamente
			OS.delay_msec(10)
			continue
		
		var processed = 0
		var batch: Array = []
		# Coletar batch de tarefas
		while not pathfinding_queue.is_empty() and processed < max_batch_size:
			batch.append(pathfinding_queue.pop_front())
			processed += 1
		pathfinding_mutex.unlock()
		
		# Processar batch na thread
		var results: Array = []
		for task in batch:
			var path = task.pathfinder.find_path(task.from_c, task.from_r, task.base_grid)
			results.append({
				"callback": task.callback,
				"path": path
			})
		
		# Adicionar resultados para processar na thread principal
		pathfinding_mutex.lock()
		pathfinding_results.append_array(results)
		pathfinding_mutex.unlock()

func process_pathfinding_results() -> void:
	"""Processa resultados de pathfinding na thread principal (chamar no _process)"""
	if pathfinding_results.is_empty():
		return
	
	pathfinding_mutex.lock()
	var results = pathfinding_results.duplicate()
	pathfinding_results.clear()
	pathfinding_mutex.unlock()
	
	# Executar callbacks na thread principal
	for result in results:
		result.callback.call(result.path)

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

func calculate_tower_dps_batch(towers_data: Array, calculate_func: Callable) -> Dictionary:
	"""Calcula DPS de um batch de torres (pode ser usado em thread)"""
	var results: Dictionary = {}
	for tower_data in towers_data:
		var tower_id = tower_data.get("id", "")
		var tower = tower_data.get("tower", null)
		var tower_type = tower_data.get("type", "")
		if tower != null:
			var dps = calculate_func.call(tower, tower_type)
			results[tower_id] = {
				"dps": dps,
				"tower_type": tower_type,
				"pos": tower.pos if tower.has("pos") else Vector2.ZERO
			}
	return results

func clear_pathfinding_queue() -> void:
	"""Limpa a fila de pathfinding pendente"""
	pathfinding_mutex.lock()
	pathfinding_queue.clear()
	pathfinding_results.clear()
	processing_pathfinding = false
	pathfinding_mutex.unlock()

func get_queue_size() -> int:
	"""Retorna o tamanho da fila de pathfinding"""
	pathfinding_mutex.lock()
	var size = pathfinding_queue.size()
	pathfinding_mutex.unlock()
	return size

func cleanup() -> void:
	"""Limpa threads e recursos (chamar ao finalizar)"""
	clear_pathfinding_queue()
	if pathfinding_thread != null and pathfinding_thread.is_alive():
		pathfinding_thread.wait_to_finish()
		pathfinding_thread = null
