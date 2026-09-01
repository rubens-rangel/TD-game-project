extends RefCounted
class_name ObjectPoolManager


var arrow_pool: Array = []
var tower_bullet_pool: Array = []

var damage_number_pool: Array = []
var enemy_death_pool: Array = []
var shock_effect_pool: Array = []

var enemy_pool: Array = []

const MAX_ARROW_POOL_SIZE := 80
const MAX_TOWER_BULLET_POOL_SIZE := 80
const MAX_DAMAGE_NUMBER_POOL_SIZE := 40
const MAX_ENEMY_DEATH_POOL_SIZE := 20
const MAX_SHOCK_EFFECT_POOL_SIZE := 16
const MAX_ENEMY_POOL_SIZE := 120

func _init():
	pass


func get_arrow() -> Dictionary:
	"""Obtém uma flecha do pool ou cria nova se necessário"""
	if arrow_pool.size() > 0:
		return arrow_pool.pop_back()
	return {}

func return_arrow(arrow: Dictionary) -> void:
	"""Retorna uma flecha ao pool"""
	if arrow_pool.size() < MAX_ARROW_POOL_SIZE:
		arrow_pool.append(arrow)

func get_tower_bullet() -> Dictionary:
	"""Obtém um projétil de torre do pool ou cria novo se necessário"""
	if tower_bullet_pool.size() > 0:
		return tower_bullet_pool.pop_back()
	return {}

func return_tower_bullet(bullet: Dictionary) -> void:
	"""Retorna um projétil de torre ao pool"""
	if tower_bullet_pool.size() < MAX_TOWER_BULLET_POOL_SIZE:
		tower_bullet_pool.append(bullet)

func get_damage_number() -> Dictionary:
	"""Obtém um número de dano do pool ou cria novo se necessário"""
	if damage_number_pool.size() > 0:
		return damage_number_pool.pop_back()
	return {}

func return_damage_number(damage_num: Dictionary) -> void:
	"""Retorna um número de dano ao pool"""
	if damage_number_pool.size() < MAX_DAMAGE_NUMBER_POOL_SIZE:
		damage_number_pool.append(damage_num)

func get_enemy_death_animation() -> Dictionary:
	"""Obtém uma animação de morte do pool ou cria nova se necessário"""
	if enemy_death_pool.size() > 0:
		return enemy_death_pool.pop_back()
	return {}

func return_enemy_death_animation(animation: Dictionary) -> void:
	"""Retorna uma animação de morte ao pool"""
	if enemy_death_pool.size() < MAX_ENEMY_DEATH_POOL_SIZE:
		enemy_death_pool.append(animation)

func get_shock_effect() -> Dictionary:
	"""Obtém um efeito de choque do pool ou cria novo se necessário"""
	if shock_effect_pool.size() > 0:
		return shock_effect_pool.pop_back()
	return {}

func return_shock_effect(effect: Dictionary) -> void:
	"""Retorna um efeito de choque ao pool"""
	if shock_effect_pool.size() < MAX_SHOCK_EFFECT_POOL_SIZE:
		shock_effect_pool.append(effect)

func get_enemy() -> Dictionary:
	if enemy_pool.size() > 0:
		return enemy_pool.pop_back()
	return {}

func return_enemy(enemy: Dictionary) -> void:
	if enemy_pool.size() >= MAX_ENEMY_POOL_SIZE:
		return
	enemy["path"] = []
	enemy["hp"] = 0
	enemy["reached"] = false
	enemy.erase("dying")
	enemy.erase("dying_time")
	enemy_pool.append(enemy)


func clear_all_pools() -> void:
	"""Limpa todos os pools (útil ao resetar o jogo)"""
	arrow_pool.clear()
	tower_bullet_pool.clear()
	damage_number_pool.clear()
	enemy_death_pool.clear()
	shock_effect_pool.clear()
	enemy_pool.clear()
