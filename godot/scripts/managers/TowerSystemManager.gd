extends RefCounted
class_name TowerSystemManager

const SpatialHashManager = preload("res://scripts/managers/SpatialHashManager.gd")

# Gerencia a lógica de todas as torres do jogo
# Centraliza updates, targeting, e disparos de todas as torres

var game: Node2D  # Referência ao Game principal
var enemies: Array  # Referência ao array de inimigos
var effects_manager: EffectsManager  # Para efeitos visuais
var grid_manager: GridManager  # Para cálculos de posição
var spatial_hash_manager: SpatialHashManager = null  # Otimização de queries espaciais

# Arrays de torres (referências do Game.gd)
var towers: Array = []
var slow_towers: Array = []
var aoe_towers: Array = []
var sniper_towers: Array = []
var boost_towers: Array = []
var shock_towers: Array = []
var barracks: Array = []

# Boost towers afetam outras torres
var global_tower_damage_boost: float = 1.0

# Callbacks para ações (serão definidos no Game.gd)
var on_enemy_damaged: Callable  # (enemy_idx: int, damage: float, is_boss: bool)
var on_tower_fired: Callable  # (tower_type: String, tower_id: String)
var on_damage_dealt: Callable  # (tower_id: String, damage: float)

func _init(game_node: Node2D, enemies_arr: Array, effects_mgr: EffectsManager, grid_mgr: GridManager):
	game = game_node
	enemies = enemies_arr
	effects_manager = effects_mgr
	grid_manager = grid_mgr

# Define o SpatialHashManager (opcional - se não definido, usa busca linear)
func set_spatial_hash_manager(spatial_hash) -> void:
	if spatial_hash is SpatialHashManager:
		spatial_hash_manager = spatial_hash

# Define os arrays de torres
func set_tower_arrays(
	towers_arr: Array,
	slow_towers_arr: Array,
	aoe_towers_arr: Array,
	sniper_towers_arr: Array,
	boost_towers_arr: Array,
	shock_towers_arr: Array,
	barracks_arr: Array
) -> void:
	towers = towers_arr
	slow_towers = slow_towers_arr
	aoe_towers = aoe_towers_arr
	sniper_towers = sniper_towers_arr
	boost_towers = boost_towers_arr
	shock_towers = shock_towers_arr
	barracks = barracks_arr

# Atualiza todas as torres
func update_all_towers(delta: float) -> void:
	"""Atualiza todas as torres do jogo"""
	_update_normal_towers(delta)
	_update_slow_towers(delta)
	_update_aoe_towers(delta)
	_update_sniper_towers(delta)
	_update_shock_towers(delta)
	_update_boost_towers(delta)
	_update_barracks(delta)

# Encontra o inimigo mais próximo dentro do alcance
func find_closest_enemy_in_range(tower_pos: Vector2, range: float) -> int:
	"""Retorna o índice do inimigo mais próximo dentro do alcance, ou -1 se não houver"""
	var closest_idx = -1
	var closest_dist = range
	
	# Usar spatial hash se disponível (otimização)
	var candidates: Array = []
	if spatial_hash_manager != null:
		candidates = spatial_hash_manager.get_enemy_candidates_in_range(tower_pos, range)
	else:
		# Fallback: verificar todos os inimigos
		candidates = range(enemies.size())
	
	# Verificar candidatos (mesma lógica, apenas menos verificações)
	for i in candidates:
		if i < 0 or i >= enemies.size():
			continue
		var enemy = enemies[i]
		if enemy["hp"] <= 0 or enemy.get("reached", false):
			continue
		
		var dist = tower_pos.distance_to(enemy["pos"])
		if dist < closest_dist:
			closest_dist = dist
			closest_idx = i
	
	return closest_idx

# Encontra o boss mais próximo dentro do alcance
func find_boss_in_range(tower_pos: Vector2, range: float) -> int:
	"""Retorna o índice do boss mais próximo dentro do alcance, ou -1 se não houver"""
	var closest_idx = -1
	var closest_dist = range
	
	# Usar spatial hash se disponível (otimização)
	var candidates: Array = []
	if spatial_hash_manager != null:
		candidates = spatial_hash_manager.get_enemy_candidates_in_range(tower_pos, range)
	else:
		# Fallback: verificar todos os inimigos
		candidates = range(enemies.size())
	
	# Verificar candidatos (mesma lógica, apenas menos verificações)
	for i in candidates:
		if i < 0 or i >= enemies.size():
			continue
		var enemy = enemies[i]
		if enemy["hp"] <= 0 or enemy.get("reached", false):
			continue
		if not enemy.get("is_boss", false):
			continue
		
		var dist = tower_pos.distance_to(enemy["pos"])
		if dist < closest_dist:
			closest_dist = dist
			closest_idx = i
	
	return closest_idx

# Encontra o inimigo mais próximo ao centro da base
func find_enemy_closest_to_center(tower_pos: Vector2, range: float, base_center: Vector2) -> int:
	"""Retorna o índice do inimigo mais próximo ao centro da base dentro do alcance"""
	var closest_idx = -1
	var closest_dist_to_center = 9999.0
	
	# Usar spatial hash se disponível (otimização)
	var candidates: Array = []
	if spatial_hash_manager != null:
		candidates = spatial_hash_manager.get_enemy_candidates_in_range(tower_pos, range)
	else:
		# Fallback: verificar todos os inimigos
		candidates = range(enemies.size())
	
	# Verificar candidatos (mesma lógica, apenas menos verificações)
	for i in candidates:
		if i < 0 or i >= enemies.size():
			continue
		var enemy = enemies[i]
		if enemy["hp"] <= 0 or enemy.get("reached", false):
			continue
		
		var dist_to_tower = tower_pos.distance_to(enemy["pos"])
		if dist_to_tower > range:
			continue
		
		var dist_to_center = base_center.distance_to(enemy["pos"])
		if dist_to_center < closest_dist_to_center:
			closest_dist_to_center = dist_to_center
			closest_idx = i
	
	return closest_idx

# Calcula dano com multiplicadores
func calculate_damage(base_damage: float, tower_type: String = "") -> float:
	"""Calcula dano final considerando boosts globais e de boost towers"""
	var damage = base_damage * global_tower_damage_boost
	
	# Aplicar boost de boost towers próximas (será implementado se necessário)
	# Por enquanto, apenas o boost global
	
	return damage

# Aplica dano a um inimigo
func apply_damage_to_enemy(enemy_idx: int, damage: float, is_boss: bool = false) -> void:
	"""Aplica dano a um inimigo e chama callbacks"""
	if enemy_idx < 0 or enemy_idx >= enemies.size():
		return
	
	var enemy = enemies[enemy_idx]
	if enemy["hp"] <= 0:
		return
	
	enemy["hp"] -= damage
	
	if on_enemy_damaged.is_valid():
		on_enemy_damaged.call(enemy_idx, damage, is_boss)

# Atualiza torres normais
func _update_normal_towers(delta: float) -> void:
	"""Atualiza torres normais (cross pattern)"""
	for tower in towers:
		if not tower.has("cooldown"):
			continue
		
		tower.cooldown -= delta
		if tower.cooldown <= 0.0:
			_fire_normal_tower(tower)
			tower.cooldown = tower.fire_rate

# Dispara torre normal (cross pattern)
func _fire_normal_tower(tower: Dictionary) -> void:
	"""Faz a torre normal disparar em padrão cruz"""
	# Esta função será implementada no Game.gd ou delegada
	# Por enquanto, apenas estrutura
	if on_tower_fired.is_valid():
		on_tower_fired.call("tower", _get_tower_id(tower, "tower"))

# Atualiza slow towers
func _update_slow_towers(delta: float) -> void:
	"""Atualiza slow towers"""
	for tower in slow_towers:
		if not tower.has("cooldown"):
			continue
		
		tower.cooldown -= delta
		if tower.cooldown <= 0.0:
			_fire_slow_tower(tower)
			tower.cooldown = tower.fire_rate

# Dispara slow tower
func _fire_slow_tower(tower: Dictionary) -> void:
	"""Faz a slow tower aplicar slow em inimigos no alcance"""
	var enemy_idx = find_closest_enemy_in_range(tower.pos, tower.range)
	if enemy_idx >= 0:
		# Aplicar slow (será implementado no Game.gd)
		pass

# Atualiza AOE towers
func _update_aoe_towers(delta: float) -> void:
	"""Atualiza AOE towers"""
	for tower in aoe_towers:
		if not tower.has("cooldown"):
			continue
		
		tower.cooldown -= delta
		if tower.cooldown <= 0.0:
			_fire_aoe_tower(tower)
			tower.cooldown = tower.fire_rate

# Dispara AOE tower
func _fire_aoe_tower(tower: Dictionary) -> void:
	"""Faz a AOE tower disparar em área"""
	var enemy_idx = find_closest_enemy_in_range(tower.pos, tower.range)
	if enemy_idx >= 0:
		var target_pos = enemies[enemy_idx]["pos"]
		# Criar projétil AOE (será implementado no Game.gd)
		if on_tower_fired.is_valid():
			on_tower_fired.call("aoe", _get_tower_id(tower, "aoe"))

# Atualiza sniper towers
func _update_sniper_towers(delta: float) -> void:
	"""Atualiza sniper towers"""
	for tower in sniper_towers:
		if not tower.has("cooldown"):
			continue
		
		tower.cooldown -= delta
		if tower.cooldown <= 0.0:
			_fire_sniper_tower(tower)
			tower.cooldown = tower.fire_rate

# Dispara sniper tower (prioridade: boss primeiro, depois mais próximo ao centro)
func _fire_sniper_tower(tower: Dictionary) -> void:
	"""Faz a sniper tower disparar com prioridade em boss"""
	# Primeiro, procurar boss
	var base_center = Vector2.ZERO
	if grid_manager:
		var center_tile = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
		base_center = center_tile
	
	var enemy_idx = find_boss_in_range(tower.pos, tower.range)
	
	# Se não encontrou boss, procurar inimigo mais próximo ao centro
	if enemy_idx < 0 and grid_manager:
		enemy_idx = find_enemy_closest_to_center(tower.pos, tower.range, base_center)
	
	if enemy_idx >= 0:
		# Disparar (será implementado no Game.gd)
		if on_tower_fired.is_valid():
			on_tower_fired.call("sniper", _get_tower_id(tower, "sniper"))

# Atualiza shock towers
func _update_shock_towers(delta: float) -> void:
	"""Atualiza shock towers"""
	for tower in shock_towers:
		if not tower.has("cooldown"):
			continue
		
		tower.cooldown -= delta
		if tower.cooldown <= 0.0:
			_fire_shock_tower(tower)
			tower.cooldown = tower.fire_rate

# Dispara shock tower (chain lightning)
func _fire_shock_tower(tower: Dictionary) -> void:
	"""Faz a shock tower disparar raio em cadeia"""
	var enemy_idx = find_closest_enemy_in_range(tower.pos, tower.range)
	if enemy_idx >= 0:
		# Criar efeito de choque em cadeia (será implementado no Game.gd)
		if on_tower_fired.is_valid():
			on_tower_fired.call("shock", _get_tower_id(tower, "shock"))

# Atualiza boost towers (não disparam, apenas afetam outras torres)
func _update_boost_towers(delta: float) -> void:
	"""Boost towers não disparam, apenas afetam outras torres"""
	# Boost towers são passivas, não precisam de update
	pass

# Atualiza barracks
func _update_barracks(delta: float) -> void:
	"""Atualiza quartéis (spawn de soldados)"""
	for barrack in barracks:
		if not barrack.has("soldier_spawn_cd"):
			continue
		
		barrack.soldier_spawn_cd -= delta
		if barrack.soldier_spawn_cd <= 0.0:
			_spawn_soldier(barrack)
			barrack.soldier_spawn_cd = barrack.soldier_spawn_rate

# Spawna um soldado do quartel
func _spawn_soldier(barrack: Dictionary) -> void:
	"""Cria um soldado do quartel"""
	# Será implementado no Game.gd
	pass

# Gera ID único para uma torre
func _get_tower_id(tower: Dictionary, tower_type: String) -> String:
	"""Gera um ID único para uma torre baseado em sua posição e tipo"""
	if tower.has("grid_x") and tower.has("grid_y"):
		return "%s_%d_%d" % [tower_type, tower.grid_x, tower.grid_y]
	return "%s_%s" % [tower_type, str(tower.get("pos", Vector2.ZERO))]

# Define o boost global de dano
func set_global_damage_boost(boost: float) -> void:
	global_tower_damage_boost = boost

# Retorna o boost global de dano
func get_global_damage_boost() -> float:
	return global_tower_damage_boost

