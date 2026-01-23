extends RefCounted
class_name WaveManager

const GameConstants = preload("res://scripts/Constants.gd")

enum SpecialWaveType {
	NONE,
	NIGHT_HORDE,      # Mais inimigos
	DOUBLE_COINS,     # 2x moedas
	MAX_SPEED,        # Inimigos rápidos
	BOSS_RUSH,        # Apenas bosses
	PERFECT_WAVE,     # Bônus por completar sem perder HP
	HELL_WAVE         # HP baixo, velocidade alta
}

signal wave_started(wave_number: int, is_boss_wave: bool, special_wave_type: SpecialWaveType)
signal wave_ended()

var wave: int = 0
var intermission: float = GameConstants.INTERMISSION
var time_to_next_wave: float = GameConstants.INTERMISSION
var spawning: bool = false
var to_spawn: int = 0
var spawn_cd: float = 0.0
var spawn_rate: float = 0.35
var bosses_spawned_this_wave: int = 0
var special_wave_type: SpecialWaveType = SpecialWaveType.NONE

func _init():
	time_to_next_wave = intermission

func is_boss_wave() -> bool:
	return wave % 5 == 0

func wave_factor() -> float:
	var base_scale: float
	if wave <= 25:
		base_scale = 1.06
	elif wave <= 50:
		base_scale = 1.04
	else:
		base_scale = GameConstants.WAVE_SCALE
	
	# Aplicar escala progressiva
	if wave <= 1:
		return 1.0
	elif wave <= 25:
		return pow(base_scale, max(0, wave - 1))
	elif wave <= 50:
		var factor_25 = pow(1.06, 24)
		return factor_25 * pow(base_scale, max(0, wave - 25))
	else:
		var factor_25 = pow(1.06, 24)
		var factor_50 = factor_25 * pow(1.04, 25)
		return factor_50 * pow(base_scale, max(0, wave - 50))

func start_next_wave():
	wave += 1
	bosses_spawned_this_wave = 0
	
	# Determinar se é uma wave especial
	special_wave_type = _determine_special_wave_type()
	
	var is_boss = is_boss_wave()
	var base: int = 6
	var plus_each: int = max(0, wave - 1)
	var bonus_five: int = 3 * int(floor(max(0, wave - 1) / 5))
	to_spawn = base + plus_each + bonus_five
	
	# Aplicar modificadores de wave especial
	if special_wave_type == SpecialWaveType.NIGHT_HORDE:
		to_spawn = int(to_spawn * 2.0)  # 2x mais inimigos
	elif special_wave_type == SpecialWaveType.BOSS_RUSH:
		to_spawn = 0  # Não spawnar inimigos normais, apenas bosses
		is_boss = true  # Forçar comportamento de boss wave
	
	spawn_rate = max(0.12, 0.5 - wave * 0.02)
	spawn_cd = 0.0
	spawning = true
	
	wave_started.emit(wave, is_boss, special_wave_type)

func update(delta: float) -> bool:
	# retorna true se deve spawnar um inimigo
	if not spawning:
		return false
	
	spawn_cd -= delta
	if spawn_cd <= 0.0:
		# Boss Rush: spawnar apenas bosses
		if special_wave_type == SpecialWaveType.BOSS_RUSH:
			if bosses_spawned_this_wave < 4:  # Mais bosses durante Boss Rush
				spawn_cd = spawn_rate
				bosses_spawned_this_wave += 1
				return true  # spawn boss
			else:
				spawning = false
				time_to_next_wave = intermission
				return false
		
		var should_spawn_boss = is_boss_wave() and bosses_spawned_this_wave < 2
		var has_more_to_spawn = to_spawn > 0 or should_spawn_boss
		
		if has_more_to_spawn:
			if should_spawn_boss:
				spawn_cd = spawn_rate
				bosses_spawned_this_wave += 1
				return true  # spawn boss
			elif to_spawn > 0:
				spawn_cd = spawn_rate
				to_spawn -= 1
				return true  # spawn normal
	
	if to_spawn == 0 and not (is_boss_wave() and bosses_spawned_this_wave < 2) and special_wave_type != SpecialWaveType.BOSS_RUSH:
		spawning = false
		time_to_next_wave = intermission
	
	return false

func should_start_wave() -> bool:
	return time_to_next_wave <= 0.0

func update_intermission(delta: float):
	if not spawning:
		time_to_next_wave -= delta

func reset():
	wave = 0
	bosses_spawned_this_wave = 0
	spawning = false
	to_spawn = 0
	time_to_next_wave = intermission
	special_wave_type = SpecialWaveType.NONE

func jump_to_wave(target_wave: int):
	wave = target_wave - 1
	bosses_spawned_this_wave = 0
	spawning = false
	to_spawn = 0
	time_to_next_wave = 0.0
	special_wave_type = SpecialWaveType.NONE

func _determine_special_wave_type() -> SpecialWaveType:
	"""Determina se a wave atual é especial e qual tipo"""
	# Waves especiais aparecem a cada SPECIAL_WAVE_INTERVAL waves
	if wave % GameConstants.SPECIAL_WAVE_INTERVAL == 0 and wave > 0:
		# Escolher tipo aleatório de wave especial
		# Evitar PERFECT_WAVE se já foi recentemente
		var available_types = [
			SpecialWaveType.NIGHT_HORDE,
			SpecialWaveType.DOUBLE_COINS,
			SpecialWaveType.MAX_SPEED,
			SpecialWaveType.BOSS_RUSH,
			SpecialWaveType.PERFECT_WAVE,
			SpecialWaveType.HELL_WAVE
		]
		return available_types[randi() % available_types.size()]
	return SpecialWaveType.NONE

func is_special_wave() -> bool:
	"""Retorna true se a wave atual é especial"""
	return special_wave_type != SpecialWaveType.NONE

func get_special_wave_name() -> String:
	"""Retorna o nome da wave especial"""
	match special_wave_type:
		SpecialWaveType.NIGHT_HORDE:
			return "🌙 HORDA NOTURNA"
		SpecialWaveType.DOUBLE_COINS:
			return "💰 MOEDAS DUPLAS"
		SpecialWaveType.MAX_SPEED:
			return "⚡ VELOCIDADE MÁXIMA"
		SpecialWaveType.BOSS_RUSH:
			return "🛡️ BOSS RUSH"
		SpecialWaveType.PERFECT_WAVE:
			return "🎯 WAVE PERFEITA"
		SpecialWaveType.HELL_WAVE:
			return "🔥 ONDA DO INFERNO"
		_:
			return ""

func get_special_wave_description() -> String:
	"""Retorna a descrição da wave especial"""
	match special_wave_type:
		SpecialWaveType.NIGHT_HORDE:
			return "2x mais inimigos • 1.5x recompensas"
		SpecialWaveType.DOUBLE_COINS:
			return "Todos os inimigos dão 2x moedas"
		SpecialWaveType.MAX_SPEED:
			return "Inimigos 50% mais rápidos • 2x recompensas"
		SpecialWaveType.BOSS_RUSH:
			return "Apenas bosses • Recompensas massivas"
		SpecialWaveType.PERFECT_WAVE:
			return "Complete sem perder HP para bônus especial"
		SpecialWaveType.HELL_WAVE:
			return "Inimigos com 50% menos HP mas 2x velocidade"
		_:
			return ""

