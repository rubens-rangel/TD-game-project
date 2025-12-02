extends RefCounted
class_name RewardCalculator

# Calcula recompensas baseadas na wave atual
# Centraliza toda lógica de cálculo de recompensas

var wave_manager: WaveManager

func _init(wave_mgr: WaveManager):
	wave_manager = wave_mgr

# Calcula recompensa escalada de inimigo normal baseada na wave
func get_enemy_reward() -> int:
	"""Calcula recompensa de inimigo normal baseada na wave atual"""
	var wave = wave_manager.wave
	var scale: float = 1.0
	
	if wave <= 1:
		scale = 1.0
	elif wave <= GameConstants.REWARD_SCALE_SOFT_CAP:
		# Escala normal até a wave do soft cap
		scale = pow(GameConstants.REWARD_SCALE, wave - 1)
	else:
		# Após o soft cap, usar escala reduzida
		var base_scale = pow(GameConstants.REWARD_SCALE, GameConstants.REWARD_SCALE_SOFT_CAP - 1)
		var extra_waves = wave - GameConstants.REWARD_SCALE_SOFT_CAP
		scale = base_scale * pow(GameConstants.REWARD_SCALE_AFTER_CAP, extra_waves)
	
	return int(GameConstants.NORMAL_REWARD * scale)

# Calcula recompensa de boss baseada na wave
func get_boss_reward() -> int:
	"""Calcula recompensa de boss baseada na wave atual"""
	return get_enemy_reward() * GameConstants.BOSS_REWARD_MULTIPLIER

# Calcula bonus de completion de wave
func get_wave_completion_bonus() -> int:
	"""Calcula bonus de moedas por completar uma wave (com cap máximo)"""
	var bonus = GameConstants.WAVE_COMPLETION_BONUS_BASE + (wave_manager.wave * GameConstants.WAVE_COMPLETION_BONUS_PER_WAVE)
	return min(bonus, GameConstants.WAVE_COMPLETION_BONUS_MAX)

# Calcula custo progressivo de upgrade
static func get_upgrade_cost(base_cost: int, current_level: int) -> int:
	"""Calcula custo de upgrade com escala progressiva"""
	return int(base_cost * pow(GameConstants.UPGRADE_COST_MULTIPLIER, current_level))

# Calcula custo de torre escalado com wave
func get_tower_cost(base_cost: int) -> int:
	"""Calcula custo de torre baseado na wave atual"""
	var wave_scale = pow(GameConstants.TOWER_COST_SCALE_PER_WAVE, max(0, wave_manager.wave - 1))
	return int(base_cost * wave_scale)

# Calcula custo acumulativo de muralha
static func get_wall_cost(current_wall_count: int) -> int:
	"""Calcula custo de muralha baseado no número de muralhas já construídas (acumulativo)"""
	match current_wall_count:
		0:  # Primeira muralha
			return GameConstants.WALL_COST_1ST
		1:  # Segunda muralha
			return GameConstants.WALL_COST_2ND
		2:  # Terceira muralha
			return GameConstants.WALL_COST_3RD
		3:  # Quarta muralha (última)
			return GameConstants.WALL_COST_4TH
		_:  # Caso de segurança
			return GameConstants.WALL_COST_4TH


