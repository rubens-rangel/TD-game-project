extends RefCounted
class_name RewardCalculator


const EnemyConstants = preload("res://scripts/EnemyConstants.gd")

var wave_manager: WaveManager

func _cfg() -> Node:
	return Engine.get_main_loop().root.get_node("GameConfig")

func _init(wave_mgr: WaveManager):
	wave_manager = wave_mgr

func get_enemy_reward() -> int:
	"""Calcula recompensa de inimigo normal baseada na wave atual"""
	var wave = wave_manager.wave
	var scale: float = 1.0
	var soft_cap: int = _cfg().get_int("REWARD_SCALE_SOFT_CAP")
	var reward_scale: float = _cfg().get_float("REWARD_SCALE")
	var reward_scale_after: float = _cfg().get_float("REWARD_SCALE_AFTER_CAP")

	if wave <= 1:
		scale = 1.0
	elif wave <= soft_cap:
		scale = pow(reward_scale, wave - 1)
	else:
		var base_scale = pow(reward_scale, soft_cap - 1)
		var extra_waves = wave - soft_cap
		scale = base_scale * pow(reward_scale_after, extra_waves)

	return int(EnemyConstants.NORMAL_REWARD * scale)

func get_boss_reward() -> int:
	"""Calcula recompensa de boss baseada na wave atual"""
	return get_enemy_reward() * EnemyConstants.BOSS_REWARD_MULTIPLIER

func get_wave_completion_bonus() -> int:
	"""Calcula bonus de moedas por completar uma wave (com cap máximo)"""
	var bonus = _cfg().get_int("WAVE_COMPLETION_BONUS_BASE") + (wave_manager.wave * _cfg().get_int("WAVE_COMPLETION_BONUS_PER_WAVE"))
	return min(bonus, _cfg().get_int("WAVE_COMPLETION_BONUS_MAX"))

static func _static_cfg() -> Node:
	return Engine.get_main_loop().root.get_node("GameConfig")

static func get_upgrade_cost(base_cost: int, current_level: int) -> int:
	"""Calcula custo de upgrade com escala progressiva"""
	return int(base_cost * pow(_static_cfg().get_float("UPGRADE_COST_MULTIPLIER"), current_level))

func get_tower_cost(base_cost: int) -> int:
	"""Calcula custo de torre baseado na wave atual"""
	var wave_scale = pow(_cfg().get_float("TOWER_COST_SCALE_PER_WAVE"), max(0, wave_manager.wave - 1))
	return int(base_cost * wave_scale)

func get_wall_cost(current_wall_count: int) -> int:
	"""Calcula custo de muralha baseado no número de muralhas já construídas (acumulativo) e wave atual"""
	var base_cost: int
	match current_wall_count:
		0:
			base_cost = _cfg().get_int("WALL_COST_1ST")
		1:
			base_cost = _cfg().get_int("WALL_COST_2ND")
		2:
			base_cost = _cfg().get_int("WALL_COST_3RD")
		3:
			base_cost = _cfg().get_int("WALL_COST_4TH")
		_:
			base_cost = _cfg().get_int("WALL_COST_4TH")

	var wave_scale = pow(_cfg().get_float("TOWER_COST_SCALE_PER_WAVE"), max(0, wave_manager.wave - 1))
	return int(base_cost * wave_scale)
