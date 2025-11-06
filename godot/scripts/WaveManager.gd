extends RefCounted
class_name WaveManager

const GameConstants = preload("res://scripts/Constants.gd")

signal wave_started(wave_number: int, is_boss_wave: bool)
signal wave_ended()

var wave: int = 0
var intermission: float = GameConstants.INTERMISSION
var time_to_next_wave: float = GameConstants.INTERMISSION
var spawning: bool = false
var to_spawn: int = 0
var spawn_cd: float = 0.0
var spawn_rate: float = 0.35
var bosses_spawned_this_wave: int = 0

func _init():
	time_to_next_wave = intermission

func is_boss_wave() -> bool:
	return wave % 5 == 0

func wave_factor() -> float:
	return pow(GameConstants.WAVE_SCALE, max(0, wave - 1))

func start_next_wave():
	wave += 1
	bosses_spawned_this_wave = 0
	
	var is_boss = is_boss_wave()
	var base: int = 6
	var plus_each: int = max(0, wave - 1)
	var bonus_five: int = 3 * int(floor(max(0, wave - 1) / 5))
	to_spawn = base + plus_each + bonus_five
	spawn_rate = max(0.12, 0.5 - wave * 0.02)
	spawn_cd = 0.0
	spawning = true
	
	wave_started.emit(wave, is_boss)

func update(delta: float) -> bool:
	# retorna true se deve spawnar um inimigo
	if not spawning:
		return false
	
	spawn_cd -= delta
	if spawn_cd <= 0.0:
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
	
	if to_spawn == 0 and not (is_boss_wave() and bosses_spawned_this_wave < 2):
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

func jump_to_wave(target_wave: int):
	wave = target_wave - 1
	bosses_spawned_this_wave = 0
	spawning = false
	to_spawn = 0
	time_to_next_wave = 0.0

