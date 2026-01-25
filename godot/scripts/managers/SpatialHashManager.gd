extends RefCounted
class_name SpatialHashManager

# Sistema de Spatial Hash para otimização de queries espaciais
# Divide o mapa em células e indexa objetos por célula para queries rápidas
# Mantém comportamento idêntico ao código original, apenas mais rápido

var cell_size: float = 100.0  # Tamanho da célula (ajustável)
var enemy_grid: Dictionary = {}  # {cell_key: [enemy_indices]}
var enemies_ref: Array  # Referência ao array de inimigos do Game

func _init(enemies_array: Array, p_cell_size: float = 100.0):
	enemies_ref = enemies_array
	cell_size = p_cell_size

# Converte posição para chave de célula
func _get_cell_key(pos: Vector2) -> String:
	var cell_x = int(pos.x / cell_size)
	var cell_y = int(pos.y / cell_size)
	return "%d,%d" % [cell_x, cell_y]

# Obtém células próximas baseado em posição e alcance
func _get_nearby_cells(center: Vector2, range: float) -> Array:
	var cells: Array = []
	var cell_x_min = int((center.x - range) / cell_size)
	var cell_x_max = int((center.x + range) / cell_size)
	var cell_y_min = int((center.y - range) / cell_size)
	var cell_y_max = int((center.y + range) / cell_size)
	
	for x in range(cell_x_min, cell_x_max + 1):
		for y in range(cell_y_min, cell_y_max + 1):
			cells.append("%d,%d" % [x, y])
	
	return cells

# Atualiza o grid espacial (chamar quando inimigos se movem ou são criados/removidos)
func update_grid() -> void:
	enemy_grid.clear()
	
	for i in range(enemies_ref.size()):
		var enemy = enemies_ref[i]
		if enemy == null:
			continue
		
		# Apenas indexar inimigos válidos
		if enemy.has("pos") and enemy.has("hp") and enemy["hp"] > 0 and not enemy.get("reached", false):
			var key = _get_cell_key(enemy["pos"])
			if not enemy_grid.has(key):
				enemy_grid[key] = []
			enemy_grid[key].append(i)

# Retorna índices de inimigos em células próximas (candidatos para verificação)
# AINDA PRECISA VERIFICAR DISTÂNCIA EXATA - apenas reduz o número de verificações
func get_enemy_candidates_in_range(center: Vector2, range: float) -> Array:
	var candidates: Array = []
	var nearby_cells = _get_nearby_cells(center, range)
	
	for cell_key in nearby_cells:
		if enemy_grid.has(cell_key):
			candidates.append_array(enemy_grid[cell_key])
	
	# Remover duplicatas (inimigo pode estar em múltiplas células se estiver na borda)
	var unique_candidates: Array = []
	var seen: Dictionary = {}
	for idx in candidates:
		if not seen.has(idx):
			seen[idx] = true
			unique_candidates.append(idx)
	
	return unique_candidates

# Limpa o grid (chamar quando necessário)
func clear() -> void:
	enemy_grid.clear()
