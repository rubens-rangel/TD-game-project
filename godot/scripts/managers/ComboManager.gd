extends RefCounted
class_name ComboManager

# Sistema de Combos - Gerencia kill streaks e multiplicadores de recompensa

var current_combo: int = 0
var combo_timer: float = 0.0
var combo_multiplier: float = GameConstants.COMBO_MULTIPLIER_BASE
var best_combo: int = 0
var total_combo_kills: int = 0

func _init():
	reset_combo()

func reset_combo():
	"""Reseta o combo atual"""
	current_combo = 0
	combo_timer = 0.0
	combo_multiplier = GameConstants.COMBO_MULTIPLIER_BASE

func add_kill() -> Dictionary:
	"""
	Adiciona um kill ao combo
	Retorna: Dictionary com informações do combo atualizado
	"""
	current_combo += 1
	total_combo_kills += 1
	combo_timer = GameConstants.COMBO_TIMEOUT
	
	# Atualiza melhor combo
	if current_combo > best_combo:
		best_combo = current_combo
	
	# Calcula multiplicador (com cap máximo)
	var multiplier_increase = current_combo * GameConstants.COMBO_MULTIPLIER_PER_KILL
	combo_multiplier = min(
		GameConstants.COMBO_MULTIPLIER_BASE + multiplier_increase,
		GameConstants.COMBO_MAX_MULTIPLIER
	)
	
	# Calcula bônus de moedas
	var coin_bonus = current_combo * GameConstants.COMBO_COIN_BONUS_PER_KILL
	
	# Bônus extra em marcos (10, 20, 30, etc)
	var milestone_bonus = 0
	if current_combo > 0 and current_combo % 10 == 0:
		milestone_bonus = GameConstants.COMBO_MILESTONE_BONUS
	
	return {
		"combo": current_combo,
		"multiplier": combo_multiplier,
		"coin_bonus": coin_bonus,
		"milestone_bonus": milestone_bonus,
		"is_milestone": milestone_bonus > 0
	}

func update(delta: float) -> bool:
	"""
	Atualiza o timer do combo
	Retorna: true se o combo foi perdido, false caso contrário
	"""
	if current_combo > 0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			# Combo perdido
			var lost_combo = current_combo
			reset_combo()
			return true
	return false

func get_combo_info() -> Dictionary:
	"""Retorna informações atuais do combo"""
	return {
		"combo": current_combo,
		"multiplier": combo_multiplier,
		"timer": combo_timer,
		"best_combo": best_combo,
		"total_combo_kills": total_combo_kills,
		"is_active": current_combo >= GameConstants.COMBO_MIN_KILLS
	}

func apply_reward_multiplier(base_reward: int) -> int:
	"""
	Aplica o multiplicador de combo à recompensa base
	Retorna: Recompensa modificada
	"""
	if current_combo < GameConstants.COMBO_MIN_KILLS:
		return base_reward
	
	return int(base_reward * combo_multiplier)

func get_combo_text() -> String:
	"""Retorna texto formatado do combo atual"""
	if current_combo < GameConstants.COMBO_MIN_KILLS:
		return ""
	
	var multiplier_text = "x%.1f" % combo_multiplier
	return "COMBO x%d (%s)" % [current_combo, multiplier_text]

