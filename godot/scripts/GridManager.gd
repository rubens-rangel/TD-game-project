extends RefCounted
class_name GridManager

const GameConstants = preload("res://scripts/Constants.gd")

var grid: Array = []
var base_grid: Array = []
var center: Vector2i

func _init():
	center = Vector2i(int(GameConstants.GRID_COLS / 2), int(GameConstants.GRID_ROWS / 2))
	grid = _generate_maze()
	_init_base_grid()

func _init_base_grid():
	base_grid = []
	for gy in range(GameConstants.BASE_GRID_SIZE):
		base_grid.append([])
		for gx in range(GameConstants.BASE_GRID_SIZE):
			base_grid[gy].append(0)

func _generate_maze() -> Array:
	var g := []
	# Inicializar tudo como chão (0)
	for r in range(GameConstants.GRID_ROWS):
		g.append([])
		for c in range(GameConstants.GRID_COLS):
			g[r].append(0)
	
	# Criar bordas externas (paredes)
	for c in range(GameConstants.GRID_COLS):
		g[0][c] = 1
		g[GameConstants.GRID_ROWS-1][c] = 1
	for r in range(GameConstants.GRID_ROWS):
		g[r][0] = 1
		g[r][GameConstants.GRID_COLS-1] = 1
	
	var base_start_col = center.x - int(GameConstants.BASE_SIZE_TILES / 2)
	var base_end_col = center.x + int(GameConstants.BASE_SIZE_TILES / 2)
	var base_start_row = center.y - int(GameConstants.BASE_SIZE_TILES / 2)
	var base_end_row = center.y + int(GameConstants.BASE_SIZE_TILES / 2)
	
	# Limpar área central
	for r in range(base_start_row, base_end_row + 1):
		for c in range(base_start_col, base_end_col + 1):
			if r >= 0 and r < GameConstants.GRID_ROWS and c >= 0 and c < GameConstants.GRID_COLS:
				g[r][c] = 0
	
	# Criar anéis concêntricos
	var rings := 8
	var gap_size := 2
	var first_ring_distance = int(GameConstants.BASE_SIZE_TILES / 2) + 1
	
	for ring_idx in range(1, rings + 1):
		var ring_dist = first_ring_distance + (ring_idx - 1) * 2
		var top_row = center.y - ring_dist
		var bottom_row = center.y + ring_dist
		var left_col = center.x - ring_dist
		var right_col = center.x + ring_dist
		
		if top_row < 1 or bottom_row >= GameConstants.GRID_ROWS - 1 or left_col < 1 or right_col >= GameConstants.GRID_COLS - 1:
			continue
		
		# Criar paredes do anel
		for col in range(left_col, right_col + 1):
			if top_row >= 0 and top_row < GameConstants.GRID_ROWS and col >= 0 and col < GameConstants.GRID_COLS:
				g[top_row][col] = 1
			if bottom_row >= 0 and bottom_row < GameConstants.GRID_ROWS and col >= 0 and col < GameConstants.GRID_COLS:
				g[bottom_row][col] = 1
		
		for row in range(top_row, bottom_row + 1):
			if row >= 0 and row < GameConstants.GRID_ROWS and left_col >= 0 and left_col < GameConstants.GRID_COLS:
				g[row][left_col] = 1
			if row >= 0 and row < GameConstants.GRID_ROWS and right_col >= 0 and right_col < GameConstants.GRID_COLS:
				g[row][right_col] = 1
		
		# Criar aberturas
		var gap_start = center.x - gap_size
		var gap_end = center.x + gap_size
		var gap_start_r = center.y - gap_size
		var gap_end_r = center.y + gap_size
		
		gap_start = max(gap_start, left_col)
		gap_end = min(gap_end, right_col)
		gap_start_r = max(gap_start_r, top_row)
		gap_end_r = min(gap_end_r, bottom_row)
		
		if ring_idx == 1:
			# Primeiro anel: apenas 2 entradas (esquerda e direita)
			for row in range(gap_start_r, gap_end_r + 1):
				if row >= 0 and row < GameConstants.GRID_ROWS and left_col >= 0 and left_col < GameConstants.GRID_COLS:
					g[row][left_col] = 0
				if row >= 0 and row < GameConstants.GRID_ROWS and right_col >= 0 and right_col < GameConstants.GRID_COLS:
					g[row][right_col] = 0
		elif ring_idx % 2 == 0:
			# Anéis pares: aberturas horizontais
			for col in range(gap_start, gap_end + 1):
				if col >= 0 and col < GameConstants.GRID_COLS:
					if top_row >= 0 and top_row < GameConstants.GRID_ROWS:
						g[top_row][col] = 0
					if bottom_row >= 0 and bottom_row < GameConstants.GRID_ROWS:
						g[bottom_row][col] = 0
		else:
			# Anéis ímpares: aberturas verticais
			for row in range(gap_start_r, gap_end_r + 1):
				if row >= 0 and row < GameConstants.GRID_ROWS:
					if left_col >= 0 and left_col < GameConstants.GRID_COLS:
						g[row][left_col] = 0
					if right_col >= 0 and right_col < GameConstants.GRID_COLS:
						g[row][right_col] = 0
	
	return g

func tile_center(col: int, row: int) -> Vector2:
	return Vector2(
		float(col) * GameConstants.TILE_SIZE + GameConstants.TILE_SIZE * 0.5,
		float(row) * GameConstants.TILE_SIZE + GameConstants.TILE_SIZE * 0.5
	)

func is_inside_base_point(p: Vector2) -> bool:
	var base_half_size = int(GameConstants.BASE_SIZE_TILES / 2)
	var base_start_col = center.x - base_half_size
	var base_start_row = center.y - base_half_size
	var base_end_col = center.x + base_half_size
	var base_end_row = center.y + base_half_size
	
	# Converter posição do mundo para coordenadas de tile
	var tile_col = int(floor(p.x / GameConstants.TILE_SIZE))
	var tile_row = int(floor(p.y / GameConstants.TILE_SIZE))
	
	# Verificar se está dentro da área da base (incluindo bordas)
	# Usar <= para incluir a última linha/coluna
	return tile_col >= base_start_col and tile_col <= base_end_col and \
		   tile_row >= base_start_row and tile_row <= base_end_row

func world_to_base_grid(world_pos: Vector2) -> Vector2i:
	var base_half_size = int(GameConstants.BASE_SIZE_TILES / 2)
	var base_start_col = center.x - base_half_size
	var base_start_row = center.y - base_half_size
	var base_end_col = center.x + base_half_size
	var base_end_row = center.y + base_half_size
	
	# Converter posição do mundo para coordenadas de tile do grid principal
	var tile_col = int(floor(world_pos.x / GameConstants.TILE_SIZE))
	var tile_row = int(floor(world_pos.y / GameConstants.TILE_SIZE))
	
	# Calcular posição relativa dentro da base (0 a BASE_SIZE_TILES)
	var relative_col = float(tile_col - base_start_col)
	var relative_row = float(tile_row - base_start_row)
	
	# Converter para coordenadas do grid interno (15x15)
	# grid_size_tiles = BASE_SIZE_TILES / BASE_GRID_SIZE = 7 / 15 = 0.466...
	var grid_size_tiles = float(GameConstants.BASE_SIZE_TILES) / float(GameConstants.BASE_GRID_SIZE)
	
	# Usar round ao invés de floor para melhor precisão, especialmente nas bordas
	var gx = int(round(relative_col / grid_size_tiles))
	var gy = int(round(relative_row / grid_size_tiles))
	
	# Clampar para os limites do grid (0 a 14)
	gx = clamp(gx, 0, GameConstants.BASE_GRID_SIZE - 1)
	gy = clamp(gy, 0, GameConstants.BASE_GRID_SIZE - 1)
	return Vector2i(gx, gy)

func base_grid_to_world(grid_x: int, grid_y: int) -> Vector2:
	var base_half_size = int(GameConstants.BASE_SIZE_TILES / 2)
	var base_start_col = center.x - base_half_size
	var base_start_row = center.y - base_half_size
	
	# Converter coordenadas do grid interno para posição relativa na base
	var grid_size_tiles = float(GameConstants.BASE_SIZE_TILES) / float(GameConstants.BASE_GRID_SIZE)
	
	# Calcular posição central da célula do grid
	var relative_col = (float(grid_x) + 0.5) * grid_size_tiles
	var relative_row = (float(grid_y) + 0.5) * grid_size_tiles
	
	# Converter para coordenadas absolutas de tile
	var world_col = base_start_col + relative_col
	var world_row = base_start_row + relative_row
	
	# Retornar centro do tile correspondente
	return tile_center(int(round(world_col)), int(round(world_row)))

func can_place_in_grid(grid_x: int, grid_y: int, size: int, item_type: int) -> bool:
	for dy in range(size):
		for dx in range(size):
			var gx = grid_x + dx
			var gy = grid_y + dy
			if gx < 0 or gx >= GameConstants.BASE_GRID_SIZE or gy < 0 or gy >= GameConstants.BASE_GRID_SIZE:
				return false
			if base_grid.size() <= gy or base_grid[gy].size() <= gx:
				return false
			var cell_value = base_grid[gy][gx]
			if cell_value != 0:
				return false
	return true

func set_grid_area(grid_x: int, grid_y: int, size: int, item_type: int):
	for dy in range(size):
		for dx in range(size):
			var gx = grid_x + dx
			var gy = grid_y + dy
			if gx >= 0 and gx < GameConstants.BASE_GRID_SIZE and gy >= 0 and gy < GameConstants.BASE_GRID_SIZE:
				if base_grid.size() > gy and base_grid[gy].size() > gx:
					base_grid[gy][gx] = item_type

func clear_grid_area(grid_x: int, grid_y: int, size: int):
	for dy in range(size):
		for dx in range(size):
			var gx = grid_x + dx
			var gy = grid_y + dy
			if gx >= 0 and gx < GameConstants.BASE_GRID_SIZE and gy >= 0 and gy < GameConstants.BASE_GRID_SIZE:
				if base_grid.size() > gy and base_grid[gy].size() > gx:
					base_grid[gy][gx] = 0

