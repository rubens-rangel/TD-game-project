extends RefCounted
class_name SkillsManager


var game: Node2D

var skill_damage_boost_active: bool = false
var skill_damage_boost_time: float = 0.0
var skill_damage_boost_cooldown: float = 0.0

var skill_speed_boost_active: bool = false
var skill_speed_boost_time: float = 0.0
var skill_speed_boost_cooldown: float = 0.0

var skill_slow_all_active: bool = false
var skill_slow_all_time: float = 0.0
var skill_slow_all_cooldown: float = 0.0

var skill_collect_coins_cooldown: float = 0.0

var skill_magnetism_active: bool = false
var skill_magnetism_time: float = 0.0
var skill_magnetism_cooldown: float = 0.0

var has_coin_magnetism_perk: bool = false
var cooldown_reduction: float = 0.0
var skill_used: bool = false

func set_cooldown_reduction(amount: float) -> void:
	cooldown_reduction = max(0.0, amount)

var on_damage_boost_activated: Callable
var on_speed_boost_activated: Callable
var on_slow_all_activated: Callable
var on_collect_coins_activated: Callable
var on_magnetism_activated: Callable

func _init(game_node: Node2D):
	game = game_node

func update_skills(delta: float) -> void:
	_update_damage_boost(delta)
	_update_speed_boost(delta)
	_update_slow_all(delta)
	_update_cooldowns(delta)
	_update_magnetism(delta)

func _update_damage_boost(delta: float) -> void:
	if skill_damage_boost_active:
		skill_damage_boost_time -= delta
		if skill_damage_boost_time <= 0.0:
			skill_damage_boost_active = false
			skill_damage_boost_time = 0.0

func _update_speed_boost(delta: float) -> void:
	if skill_speed_boost_active:
		skill_speed_boost_time -= delta
		if skill_speed_boost_time <= 0.0:
			skill_speed_boost_active = false
			skill_speed_boost_time = 0.0

func _update_slow_all(delta: float) -> void:
	if skill_slow_all_active:
		skill_slow_all_time -= delta
		if skill_slow_all_time <= 0.0:
			skill_slow_all_active = false
			skill_slow_all_time = 0.0

func _update_magnetism(delta: float) -> void:
	if skill_magnetism_active:
		skill_magnetism_time -= delta
		if skill_magnetism_time <= 0.0:
			skill_magnetism_active = false
			skill_magnetism_time = 0.0

func _update_cooldowns(delta: float) -> void:
	var cd_delta: float = delta * (1.0 + cooldown_reduction)
	if skill_collect_coins_cooldown > 0.0:
		skill_collect_coins_cooldown -= cd_delta
		skill_collect_coins_cooldown = max(0.0, skill_collect_coins_cooldown)

	if skill_damage_boost_cooldown > 0.0:
		skill_damage_boost_cooldown -= cd_delta
		skill_damage_boost_cooldown = max(0.0, skill_damage_boost_cooldown)

	if skill_speed_boost_cooldown > 0.0:
		skill_speed_boost_cooldown -= cd_delta
		skill_speed_boost_cooldown = max(0.0, skill_speed_boost_cooldown)

	if skill_slow_all_cooldown > 0.0:
		skill_slow_all_cooldown -= cd_delta
		skill_slow_all_cooldown = max(0.0, skill_slow_all_cooldown)

	if skill_magnetism_cooldown > 0.0:
		skill_magnetism_cooldown -= cd_delta
		skill_magnetism_cooldown = max(0.0, skill_magnetism_cooldown)

func activate_damage_boost() -> bool:
	"""Ativa a skill de boost de dano. Retorna true se ativada com sucesso."""
	if skill_damage_boost_cooldown > 0.0:
		return false
	if skill_damage_boost_active:
		return false

	skill_damage_boost_active = true
	skill_damage_boost_time = GameConstants.SKILL_DAMAGE_BOOST_DURATION
	skill_damage_boost_cooldown = GameConstants.SKILL_DAMAGE_BOOST_COOLDOWN
	skill_used = true

	if on_damage_boost_activated.is_valid():
		on_damage_boost_activated.call()

	return true

func activate_speed_boost() -> bool:
	"""Ativa a skill de boost de velocidade. Retorna true se ativada com sucesso."""
	if skill_speed_boost_cooldown > 0.0:
		return false
	if skill_speed_boost_active:
		return false

	skill_speed_boost_active = true
	skill_speed_boost_time = GameConstants.SKILL_SPEED_BOOST_DURATION
	skill_speed_boost_cooldown = GameConstants.SKILL_SPEED_BOOST_COOLDOWN
	skill_used = true

	if on_speed_boost_activated.is_valid():
		on_speed_boost_activated.call()

	return true

func activate_slow_all() -> bool:
	"""Ativa a skill de slow global. Retorna true se ativada com sucesso."""
	if skill_slow_all_cooldown > 0.0:
		return false
	if skill_slow_all_active:
		return false

	skill_slow_all_active = true
	skill_slow_all_time = GameConstants.SKILL_SLOW_ALL_DURATION
	skill_slow_all_cooldown = GameConstants.SKILL_SLOW_ALL_COOLDOWN
	skill_used = true

	if on_slow_all_activated.is_valid():
		on_slow_all_activated.call()

	return true

func activate_collect_coins() -> bool:
	"""Ativa a skill de coletar moedas. Retorna true se ativada com sucesso."""
	if skill_collect_coins_cooldown > 0.0:
		return false

	skill_collect_coins_cooldown = GameConstants.SKILL_COLLECT_COINS_COOLDOWN
	skill_used = true

	if on_collect_coins_activated.is_valid():
		on_collect_coins_activated.call()

	return true

func activate_magnetism() -> bool:
	"""Ativa a skill de magnetismo. Retorna true se ativada com sucesso."""
	if has_coin_magnetism_perk:
		return false
	if skill_magnetism_cooldown > 0.0:
		return false
	if skill_magnetism_active:
		return false

	skill_magnetism_active = true
	skill_magnetism_time = GameConstants.SKILL_MAGNETISM_DURATION
	skill_magnetism_cooldown = GameConstants.SKILL_MAGNETISM_COOLDOWN
	skill_used = true

	if on_magnetism_activated.is_valid():
		on_magnetism_activated.call()

	return true

func is_skill_available(skill_name: String) -> bool:
	match skill_name:
		"damage_boost":
			return skill_damage_boost_cooldown <= 0.0 and not skill_damage_boost_active
		"speed_boost":
			return skill_speed_boost_cooldown <= 0.0 and not skill_speed_boost_active
		"slow_all":
			return skill_slow_all_cooldown <= 0.0 and not skill_slow_all_active
		"collect_coins":
			return skill_collect_coins_cooldown <= 0.0
		"magnetism":
			return not has_coin_magnetism_perk and skill_magnetism_cooldown <= 0.0 and not skill_magnetism_active
		_:
			return false

func get_cooldown(skill_name: String) -> float:
	match skill_name:
		"damage_boost":
			return skill_damage_boost_cooldown
		"speed_boost":
			return skill_speed_boost_cooldown
		"slow_all":
			return skill_slow_all_cooldown
		"collect_coins":
			return skill_collect_coins_cooldown
		"magnetism":
			return skill_magnetism_cooldown
		_:
			return 0.0

func get_active_time(skill_name: String) -> float:
	match skill_name:
		"damage_boost":
			return skill_damage_boost_time if skill_damage_boost_active else 0.0
		"speed_boost":
			return skill_speed_boost_time if skill_speed_boost_active else 0.0
		"slow_all":
			return skill_slow_all_time if skill_slow_all_active else 0.0
		"magnetism":
			return skill_magnetism_time if skill_magnetism_active else 0.0
		_:
			return 0.0

func is_skill_active(skill_name: String) -> bool:
	match skill_name:
		"damage_boost":
			return skill_damage_boost_active
		"speed_boost":
			return skill_speed_boost_active
		"slow_all":
			return skill_slow_all_active
		"magnetism":
			return skill_magnetism_active or has_coin_magnetism_perk
		_:
			return false

func set_coin_magnetism_perk(has_perk: bool) -> void:
	has_coin_magnetism_perk = has_perk
	if has_perk:

		skill_magnetism_active = false
		skill_magnetism_time = 0.0

func get_damage_multiplier() -> float:
	if skill_damage_boost_active:
		return GameConstants.SKILL_DAMAGE_BOOST_MULTIPLIER
	return 1.0

func get_speed_multiplier() -> float:
	if skill_speed_boost_active:
		return GameConstants.SKILL_SPEED_BOOST_MULTIPLIER
	return 1.0

func get_slow_multiplier() -> float:
	if skill_slow_all_active:
		return GameConstants.SKILL_SLOW_ALL_AMOUNT
	return 1.0

func is_magnetism_active() -> bool:
	return skill_magnetism_active or has_coin_magnetism_perk

