extends RefCounted
class_name GridManager

const HERO_AREA_SIZE := 3

var grid: Array = []
var base_grid: Array = []
var center: Vector2i
var hero_area_rect: Rect2i = Rect2i()

func _cfg() -> Node:
	return Engine.get_main_loop().root.get_node("GameConfig")

func _init():
	center = Vector2i(int(_cfg().get_int("GRID_COLS") / 2), int(_cfg().get_int("GRID_ROWS") / 2))
	grid = _generate_maze()
	_init_base_grid()

func _init_base_grid():
	base_grid = []
	var base_grid_size: int = _cfg().get_int("BASE_GRID_SIZE")
	for gy in range(base_grid_size):
		base_grid.append([])
		for gx in range(base_grid_size):
			base_grid[gy].append(0)
	_mark_hero_area()

func _mark_hero_area():
	var base_grid_size: int = _cfg().get_int("BASE_GRID_SIZE")
	var hero_center = Vector2i(int(base_grid_size / 2), int(base_grid_size / 2))
	var half: int = HERO_AREA_SIZE / 2
	var start = Vector2i(hero_center.x - half, hero_center.y - half)
	var size = Vector2i(HERO_AREA_SIZE, HERO_AREA_SIZE)
	hero_area_rect = Rect2i(start, size)
	for y in range(hero_area_rect.position.y, hero_area_rect.position.y + hero_area_rect.size.y):
		for x in range(hero_area_rect.position.x, hero_area_rect.position.x + hero_area_rect.size.x):
			if y >= 0 and y < base_grid_size and x >= 0 and x < base_grid_size:
				base_grid[y][x] = -1

func _generate_maze() -> Array:
	var g := []
	var grid_rows: int = _cfg().get_int("GRID_ROWS")
	var grid_cols: int = _cfg().get_int("GRID_COLS")
	var base_size_tiles: int = _cfg().get_int("BASE_SIZE_TILES")

	for r in range(grid_rows):
		g.append([])
		for c in range(grid_cols):
			g[r].append(0)

	for c in range(grid_cols):
		g[0][c] = 1
		g[grid_rows - 1][c] = 1
	for r in range(grid_rows):
		g[r][0] = 1
		g[r][grid_cols - 1] = 1

	var base_start_col = center.x - int(base_size_tiles / 2)
	var base_end_col = center.x + int(base_size_tiles / 2)
	var base_start_row = center.y - int(base_size_tiles / 2)
	var base_end_row = center.y + int(base_size_tiles / 2)

	for r in range(base_start_row, base_end_row + 1):
		for c in range(base_start_col, base_end_col + 1):
			if r >= 0 and r < grid_rows and c >= 0 and c < grid_cols:
				g[r][c] = 0

	var rings := 8
	var gap_size := 2
	var first_ring_distance = int(base_size_tiles / 2) + 1

	for ring_idx in range(1, rings + 1):
		var ring_dist = first_ring_distance + (ring_idx - 1) * 2
		var top_row = center.y - ring_dist
		var bottom_row = center.y + ring_dist
		var left_col = center.x - ring_dist
		var right_col = center.x + ring_dist

		if top_row < 1 or bottom_row >= grid_rows - 1 or left_col < 1 or right_col >= grid_cols - 1:
			continue

		for col in range(left_col, right_col + 1):
			if top_row >= 0 and top_row < grid_rows and col >= 0 and col < grid_cols:
				g[top_row][col] = 1
			if bottom_row >= 0 and bottom_row < grid_rows and col >= 0 and col < grid_cols:
				g[bottom_row][col] = 1

		for row in range(top_row, bottom_row + 1):
			if row >= 0 and row < grid_rows and left_col >= 0 and left_col < grid_cols:
				g[row][left_col] = 1
			if row >= 0 and row < grid_rows and right_col >= 0 and right_col < grid_cols:
				g[row][right_col] = 1

		var gap_start = center.x - gap_size
		var gap_end = center.x + gap_size
		var gap_start_r = center.y - gap_size
		var gap_end_r = center.y + gap_size

		gap_start = max(gap_start, left_col)
		gap_end = min(gap_end, right_col)
		gap_start_r = max(gap_start_r, top_row)
		gap_end_r = min(gap_end_r, bottom_row)

		if ring_idx == 1:
			for row in range(gap_start_r, gap_end_r + 1):
				if row >= 0 and row < grid_rows and left_col >= 0 and left_col < grid_cols:
					g[row][left_col] = 0
				if row >= 0 and row < grid_rows and right_col >= 0 and right_col < grid_cols:
					g[row][right_col] = 0
		elif ring_idx % 2 == 0:
			for col in range(gap_start, gap_end + 1):
				if col >= 0 and col < grid_cols:
					if top_row >= 0 and top_row < grid_rows:
						g[top_row][col] = 0
					if bottom_row >= 0 and bottom_row < grid_rows:
						g[bottom_row][col] = 0
		else:
			for row in range(gap_start_r, gap_end_r + 1):
				if row >= 0 and row < grid_rows:
					if left_col >= 0 and left_col < grid_cols:
						g[row][left_col] = 0
					if right_col >= 0 and right_col < grid_cols:
						g[row][right_col] = 0

	return g

func tile_center(col: int, row: int) -> Vector2:
	var tile_size := float(_cfg().get_int("TILE_SIZE"))
	return Vector2(
		float(col) * tile_size + tile_size * 0.5,
		float(row) * tile_size + tile_size * 0.5
	)

func is_inside_base_point(p: Vector2) -> bool:
	var tile_size := float(_cfg().get_int("TILE_SIZE"))
	var base_half_size = int(_cfg().get_int("BASE_SIZE_TILES") / 2)
	var base_start_col = center.x - base_half_size
	var base_start_row = center.y - base_half_size
	var base_end_col = center.x + base_half_size
	var base_end_row = center.y + base_half_size

	var tile_col = int(floor(p.x / tile_size))
	var tile_row = int(floor(p.y / tile_size))

	return tile_col >= base_start_col and tile_col <= base_end_col and \
		   tile_row >= base_start_row and tile_row <= base_end_row

func world_to_base_grid(world_pos: Vector2) -> Vector2i:
	var tile_size := float(_cfg().get_int("TILE_SIZE"))
	var base_half_size = int(_cfg().get_int("BASE_SIZE_TILES") / 2)
	var base_start_col = center.x - base_half_size
	var base_start_row = center.y - base_half_size

	var tile_col = world_pos.x / tile_size
	var tile_row = world_pos.y / tile_size

	var relative_col = tile_col - float(base_start_col)
	var relative_row = tile_row - float(base_start_row)

	var base_size_tiles: float = float(_cfg().get_int("BASE_SIZE_TILES"))
	var base_grid_size: float = float(_cfg().get_int("BASE_GRID_SIZE"))
	var grid_size_tiles = base_size_tiles / base_grid_size

	var gx = int(floor(relative_col / grid_size_tiles))
	var gy = int(floor(relative_row / grid_size_tiles))

	var base_grid_size_i: int = _cfg().get_int("BASE_GRID_SIZE")
	gx = clamp(gx, 0, base_grid_size_i - 1)
	gy = clamp(gy, 0, base_grid_size_i - 1)
	return Vector2i(gx, gy)

func base_grid_to_world(grid_x: int, grid_y: int, size: int = 3) -> Vector2:
	var tile_size := float(_cfg().get_int("TILE_SIZE"))
	var base_half_size = int(_cfg().get_int("BASE_SIZE_TILES") / 2)
	var base_start_col = center.x - base_half_size
	var base_start_row = center.y - base_half_size

	var base_size_tiles: float = float(_cfg().get_int("BASE_SIZE_TILES"))
	var base_grid_size: float = float(_cfg().get_int("BASE_GRID_SIZE"))
	var grid_size_tiles = base_size_tiles / base_grid_size

	var center_offset = float(size) / 2.0
	var relative_col = (float(grid_x) + center_offset) * grid_size_tiles
	var relative_row = (float(grid_y) + center_offset) * grid_size_tiles

	var world_col_tiles = base_start_col + relative_col
	var world_row_tiles = base_start_row + relative_row

	return Vector2(
		world_col_tiles * tile_size,
		world_row_tiles * tile_size
	)

func can_place_in_grid(grid_x: int, grid_y: int, size: int, item_type: int, ignore_area: Rect2i = Rect2i()) -> bool:
	var base_grid_size: int = _cfg().get_int("BASE_GRID_SIZE")

	if grid_x < 0 or grid_y < 0:
		return false
	if grid_x + size > base_grid_size or grid_y + size > base_grid_size:
		return false

	for dy in range(size):
		for dx in range(size):
			var gx = grid_x + dx
			var gy = grid_y + dy

			if gx < 0 or gx >= base_grid_size or gy < 0 or gy >= base_grid_size:
				return false
			if base_grid.size() <= gy or base_grid[gy].size() <= gx:
				return false

			if ignore_area.size.x > 0 and ignore_area.size.y > 0 and ignore_area.has_point(Vector2i(gx, gy)):
				continue

			var cell_value = base_grid[gy][gx]

			if cell_value != 0:
				return false
	return true

func set_grid_area(grid_x: int, grid_y: int, size: int, item_type: int):
	var base_grid_size: int = _cfg().get_int("BASE_GRID_SIZE")
	for dy in range(size):
		for dx in range(size):
			var gx = grid_x + dx
			var gy = grid_y + dy
			if gx >= 0 and gx < base_grid_size and gy >= 0 and gy < base_grid_size:
				if base_grid.size() > gy and base_grid[gy].size() > gx:
					base_grid[gy][gx] = item_type

func clear_grid_area(grid_x: int, grid_y: int, size: int):
	var base_grid_size: int = _cfg().get_int("BASE_GRID_SIZE")
	for dy in range(size):
		for dx in range(size):
			var gx = grid_x + dx
			var gy = grid_y + dy
			if gx >= 0 and gx < base_grid_size and gy >= 0 and gy < base_grid_size:
				if base_grid.size() > gy and base_grid[gy].size() > gx:
					base_grid[gy][gx] = 0

func reset_base_grid():
	_init_base_grid()
