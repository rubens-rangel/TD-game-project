extends RefCounted
class_name EnemyManager

const GameConstants = preload("res://scripts/Constants.gd")

var grid_manager: GridManager
var pathfinder: Pathfinder
var wave_manager: WaveManager
var base_hp: int
var game_over: bool
var paused: bool

var enemies: Array = []
var enemy_effects: Dictionary = {}  # enemy_idx -> {freeze_time: float, fire_time: float, fire_damage: float}

signal enemy_reached_base(damage: int, is_boss: bool)
signal game_over_reached()

func _init(p_grid_manager: GridManager, p_pathfinder: Pathfinder, p_wave_manager: WaveManager):
	grid_manager = p_grid_manager
	pathfinder = p_pathfinder
	wave_manager = p_wave_manager
	base_hp = 100
	game_over = false
	paused = false

func create_enemy(col: int, row: int, is_boss: bool = false) -> Dictionary:
	var pos = grid_manager.tile_center(col, row)
	var initial_hp = GameConstants.BOSS_BASE_HP if is_boss else GameConstants.ENEMY_BASE_HP
	var f = wave_manager.wave_factor()
	var hp = int(max(1, round(initial_hp * f)))
	var enemy_idx = enemies.size()
	
	# Calcular caminho
	var path = _calculate_path(col, row)
	
	# Limitar velocidade máxima
	var base_speed = GameConstants.ENEMY_BASE_SPEED * f
	if is_boss:
		base_speed *= GameConstants.BOSS_SPEED_MULTIPLIER
	var max_speed = 200.0
	if base_speed > max_speed:
		base_speed = max_speed
	
	var radius = 12 if is_boss else 9
	var enemy = {
		"pos": pos,
		"speed": base_speed,
		"base_speed": base_speed,
		"hp": hp,
		"max_hp": hp,
		"radius": radius,
		"path": path,
		"path_index": 0,
		"reached": false,
		"idx": enemy_idx,
		"is_boss": is_boss
	}
	
	enemy_effects[enemy_idx] = {
		"freeze_time": 0.0,
		"fire_time": 0.0,
		"fire_damage": 0.0
	}
	
	enemies.append(enemy)
	return enemy

func _calculate_path(col: int, row: int) -> Array:
	# Limpar cache periodicamente
	if wave_manager.wave > 0 and (wave_manager.wave % 10 == 0 or enemies.size() > 50):
		pathfinder.invalidate_cache()
	
	var path = pathfinder.find_path(col, row, grid_manager.base_grid)
	
	if path.is_empty():
		pathfinder.invalidate_cache()
		path = pathfinder.find_path(col, row, grid_manager.base_grid)
	
	var pts = []
	for t in path:
		if t.x >= 0 and t.x < GameConstants.GRID_COLS and t.y >= 0 and t.y < GameConstants.GRID_ROWS:
			pts.append(grid_manager.tile_center(t.x, t.y))
	
	if pts.is_empty():
		var base_center = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
		var start_pos = grid_manager.tile_center(col, row)
		pts = [start_pos, base_center]
	
	return pts

func update_enemy(enemy: Dictionary, dt: float) -> void:
	if enemy["reached"] or enemy["hp"] <= 0:
		return
	
	var enemy_idx = enemy.get("idx", -1)
	if enemy_idx >= 0 and enemy_effects.has(enemy_idx):
		_apply_status_effects(enemy, enemy_idx, dt)
	
	# Limitar velocidade máxima
	var max_speed = 200.0
	if enemy["speed"] > max_speed:
		enemy["speed"] = max_speed
		enemy["base_speed"] = min(enemy["base_speed"], max_speed)
	
	# Verificar chegada ao centro
	var basep = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
	var dist_to_center = enemy["pos"].distance_to(basep)
	if dist_to_center < 8.0:
		enemy["reached"] = true
		var is_boss = enemy.get("is_boss", false)
		var damage = 15 if is_boss else 5
		enemy_reached_base.emit(damage, is_boss)
		return
	
	# Verificar se o inimigo ignora o labirinto (ex: alien voador)
	var ignores_path: bool = enemy.get("ignores_path", false)
	
	# Mover inimigo
	if ignores_path:
		# Sempre usar movimento direto ao centro
		_move_direct_to_center(enemy, basep, dt)
		return
	
	if not enemy.has("path") or enemy["path"].is_empty():
		_move_direct_to_center(enemy, basep, dt)
		return
	
	if enemy["path_index"] >= enemy["path"].size():
		_move_direct_to_center(enemy, basep, dt)
		return
	
	# Seguir caminho
	_follow_path(enemy, dt)

func _apply_status_effects(enemy: Dictionary, enemy_idx: int, dt: float) -> void:
	var effects = enemy_effects[enemy_idx]
	
	if effects.freeze_time > 0.0:
		effects.freeze_time -= dt
		enemy["speed"] = enemy["base_speed"] * 0.3
	else:
		enemy["speed"] = enemy["base_speed"]
	
	if effects.fire_time > 0.0:
		effects.fire_time -= dt
		enemy["hp"] -= effects.fire_damage * dt
		if enemy["hp"] <= 0:
			enemy["hp"] = 0

func _move_direct_to_center(enemy: Dictionary, basep: Vector2, dt: float) -> void:
	var v = basep - enemy["pos"]
	var d = max(v.length(), 0.0001)
	var move_dist = enemy["speed"] * dt
	if move_dist > d:
		move_dist = d
	enemy["pos"] += v.normalized() * move_dist

func _follow_path(enemy: Dictionary, dt: float) -> void:
	if not enemy.has("path_index"):
		enemy["path_index"] = 0
	
	if enemy["path_index"] < 0 or enemy["path_index"] >= enemy["path"].size():
		enemy["path_index"] = 0
	
	var targ: Vector2 = enemy["path"][enemy["path_index"]]
	if targ == null or not targ is Vector2:
		return
	
	var v2 = targ - enemy["pos"]
	var d2 = max(v2.length(), 0.0001)
	var move_dist = enemy["speed"] * dt
	var proximity_threshold = max(2.0, move_dist * 1.5)
	
	if d2 < proximity_threshold:
		enemy["pos"] = targ
		enemy["path_index"] += 1
		if enemy["path_index"] >= enemy["path"].size():
			enemy["path_index"] = enemy["path"].size() - 1
		return
	
	if move_dist > d2:
		move_dist = d2
		enemy["pos"] = targ
		enemy["path_index"] += 1
		if enemy["path_index"] >= enemy["path"].size():
			enemy["path_index"] = enemy["path"].size() - 1
	else:
		enemy["pos"] += v2.normalized() * move_dist

func find_spawn_position() -> Vector2i:
	var cells: Array = []
	var right_col = GameConstants.GRID_COLS - 2
	var bottom_row = GameConstants.GRID_ROWS - 2
	
	# Borda superior
	for c in range(1, GameConstants.GRID_COLS-1):
		if grid_manager.grid.size() > 1 and grid_manager.grid[1].size() > c:
			if grid_manager.grid[1][c] == 0 and _is_walkable(c, 1):
				cells.append(Vector2i(c, 1))
	
	# Borda inferior
	for c in range(1, GameConstants.GRID_COLS-1):
		if grid_manager.grid.size() > bottom_row and grid_manager.grid[bottom_row].size() > c:
			if grid_manager.grid[bottom_row][c] == 0 and _is_walkable(c, bottom_row):
				cells.append(Vector2i(c, bottom_row))
	
	# Borda esquerda
	for r in range(1, GameConstants.GRID_ROWS-1):
		if grid_manager.grid.size() > r and grid_manager.grid[r].size() > 1:
			if grid_manager.grid[r][1] == 0 and _is_walkable(1, r):
				cells.append(Vector2i(1, r))
	
	# Borda direita
	for r in range(1, GameConstants.GRID_ROWS-1):
		if grid_manager.grid.size() > r and grid_manager.grid[r].size() > right_col:
			if grid_manager.grid[r][right_col] == 0 and _is_walkable(right_col, r):
				cells.append(Vector2i(right_col, r))
	
	if cells.is_empty():
		# Fallback: qualquer célula válida
		for c in range(1, GameConstants.GRID_COLS-1):
			if grid_manager.grid.size() > 1 and grid_manager.grid[1].size() > c and grid_manager.grid[1][c] == 0:
				cells.append(Vector2i(c, 1))
	
	if cells.is_empty():
		return Vector2i(-1, -1)
	
	cells.shuffle()
	var selected = cells[randi() % cells.size()]
	
	# Validar caminho
	var test_path = pathfinder.find_path(selected.x, selected.y, grid_manager.base_grid)
	if test_path.is_empty():
		for i in range(min(5, cells.size())):
			selected = cells[i]
			test_path = pathfinder.find_path(selected.x, selected.y, grid_manager.base_grid)
			if not test_path.is_empty():
				break
	
	return selected

func _is_walkable(c: int, r: int) -> bool:
	return pathfinder.is_walkable(c, r, grid_manager.base_grid)

func remove_dead_enemies() -> Dictionary:
	var alive: Array = []
	var new_enemy_effects: Dictionary = {}
	var enemy_idx_map: Dictionary = {}
	
	for i in range(enemies.size()):
		var e = enemies[i]
		if e["hp"] > 0 and not e["reached"]:
			var new_idx = alive.size()
			alive.append(e)
			e["idx"] = new_idx
			enemy_idx_map[i] = new_idx
			if enemy_effects.has(i):
				new_enemy_effects[new_idx] = enemy_effects[i]
	
	enemies = alive
	enemy_effects = new_enemy_effects
	return enemy_idx_map

func apply_damage(enemy_idx: int, damage: float) -> void:
	if enemy_idx >= 0 and enemy_idx < enemies.size():
		enemies[enemy_idx]["hp"] -= damage

func apply_status_effect(enemy_idx: int, effect_type: String, duration: float, fire_damage: float = 0.0) -> void:
	if not enemy_effects.has(enemy_idx):
		enemy_effects[enemy_idx] = {"freeze_time": 0.0, "fire_time": 0.0, "fire_damage": 0.0}
	
	var effects = enemy_effects[enemy_idx]
	match effect_type:
		"freeze":
			effects.freeze_time = max(effects.freeze_time, duration)
		"fire":
			effects.fire_time = max(effects.fire_time, duration)
			if fire_damage > 0.0:
				effects.fire_damage = max(effects.fire_damage, fire_damage)

func clear_all() -> void:
	enemies.clear()
	enemy_effects.clear()

