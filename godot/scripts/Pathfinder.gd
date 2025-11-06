extends RefCounted
class_name Pathfinder

const GameConstants = preload("res://scripts/Constants.gd")

var grid: Array
var center: Vector2i
var path_cache: Dictionary = {}  # cache de caminhos: "x,y" -> Array[Vector2i]

func _init(p_grid: Array, p_center: Vector2i):
	grid = p_grid
	center = p_center

func is_walkable(c: int, r: int, base_grid: Array) -> bool:
	if not (r >= 0 and r < GameConstants.GRID_ROWS and c >= 0 and c < GameConstants.GRID_COLS):
		return false
	if grid[r][c] != 0:
		return false
	
	# verificar se tem bloco nessa posição usando o grid da base
	var check_pos = _tile_center(c, r)
	var grid_coord = _world_to_base_grid(check_pos)
	if grid_coord.x >= 0 and grid_coord.x < GameConstants.BASE_GRID_SIZE and grid_coord.y >= 0 and grid_coord.y < GameConstants.BASE_GRID_SIZE:
		if base_grid.size() > grid_coord.y and base_grid[grid_coord.y].size() > grid_coord.x:
			if base_grid[grid_coord.y][grid_coord.x] == 2:  # 2 = bloco
				return false
	return true

func _tile_center(col: int, row: int) -> Vector2:
	return Vector2(
		float(col) * GameConstants.TILE_SIZE + GameConstants.TILE_SIZE * 0.5,
		float(row) * GameConstants.TILE_SIZE + GameConstants.TILE_SIZE * 0.5
	)

func _world_to_base_grid(world_pos: Vector2) -> Vector2i:
	var base_half_size = int(GameConstants.BASE_SIZE_TILES / 2)
	var base_start_col = center.x - base_half_size
	var base_start_row = center.y - base_half_size
	
	var tile_col = int(floor(world_pos.x / GameConstants.TILE_SIZE))
	var tile_row = int(floor(world_pos.y / GameConstants.TILE_SIZE))
	
	var relative_col = tile_col - base_start_col
	var relative_row = tile_row - base_start_row
	
	var grid_size_tiles = float(GameConstants.BASE_SIZE_TILES) / float(GameConstants.BASE_GRID_SIZE)
	var gx = int(floor(float(relative_col) / grid_size_tiles))
	var gy = int(floor(float(relative_row) / grid_size_tiles))
	
	gx = clamp(gx, 0, GameConstants.BASE_GRID_SIZE - 1)
	gy = clamp(gy, 0, GameConstants.BASE_GRID_SIZE - 1)
	return Vector2i(gx, gy)

func find_path(from_c: int, from_r: int, base_grid: Array) -> Array:
	# Otimização: verificar cache primeiro (mais rápido)
	# O cache é invalidado quando blocos são colocados, então podemos confiar nele
	var cache_key = "%d,%d" % [from_c, from_r]
	if path_cache.has(cache_key):
		return path_cache[cache_key]
	
	var start = Vector2i(from_c, from_r)
	var goal = center
	
	# Verificar se o ponto inicial é válido
	if not is_walkable(from_c, from_r, base_grid):
		return []
	
	# Verificar se o goal é válido (deve ser sempre, mas vamos garantir)
	if not is_walkable(goal.x, goal.y, base_grid):
		# Se o centro não é walkable, tentar encontrar uma célula próxima válida
		var dirs = [Vector2i(0,0), Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
		for d in dirs:
			var test_goal = goal + d
			if is_walkable(test_goal.x, test_goal.y, base_grid):
				goal = test_goal
				break
	
	var q: Array = [start]
	var visited := { start: true }
	var parent := {}
	var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	
	while not q.is_empty():
		var cur: Vector2i = q.pop_front()
		if cur == goal:
			break
		for d in dirs:
			var nc = cur.x + d.x
			var nr = cur.y + d.y
			var nk = Vector2i(nc, nr)
			if not is_walkable(nc, nr, base_grid):
				continue
			if visited.has(nk):
				continue
			visited[nk] = true
			parent[nk] = cur
			q.append(nk)
	
	if not visited.has(goal):
		# Não cachear caminhos inválidos
		return []
	
	var path := []
	var ck = goal
	while ck != start:
		path.append(ck)
		ck = parent.get(ck, start)
		if ck == start:
			break
	path.reverse()
	
	# Cachear o caminho (cache é invalidado quando blocos são colocados)
	path_cache[cache_key] = path
	return path

func clear_cache():
	path_cache.clear()

func invalidate_cache():
	# limpar cache quando o grid muda (ex: bloco é colocado)
	path_cache.clear()

