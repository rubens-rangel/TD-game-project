extends RefCounted
class_name EnemyConstants

const ENEMY_BASE_SPEED := 38.0
const ENEMY_MAX_SPEED := 210.0
const BOSS_SPEED_MULTIPLIER := 0.5
const ENEMY_BASE_HP := 5
const BOSS_BASE_HP := 35
const BOSS_REWARD_MULTIPLIER := 20
const NORMAL_REWARD := 2

enum EnemyType {
	ZOMBIE,
	ZOMBIE_GORDO,
	ZOMBIE_CORREDOR,
	HUMANOID,
	ROBOT,
	ALIEN,
	ALIEN_VOADOR,
	MECANOIDE_BIPEDE,
	MECANOIDE_LAGARTAS,
	MECANOIDE_DRONE,
	MECANOIDE_REGENERADOR,
	MECANOIDE_BOSS
}

static func get_enemy_type_config(type: EnemyType) -> Dictionary:
	match type:
		EnemyType.ZOMBIE:
			return {
				"hp_multiplier": 1.0,
				"speed_multiplier": 1.0,
				"max_speed_multiplier": 1.0,
				"texture_name": "enemy_zombie",
				"min_wave": 1,
				"max_wave": 50
			}
		EnemyType.ZOMBIE_GORDO:
			return {
				"hp_multiplier": 1.5,
				"speed_multiplier": 0.75,
				"max_speed_multiplier": 1.0,
				"texture_name": "enemy_zombie_gordo",
				"min_wave": 1,
				"max_wave": 50
			}
		EnemyType.ZOMBIE_CORREDOR:
			return {
				"hp_multiplier": 0.5,
				"speed_multiplier": 1.4,
				"max_speed_multiplier": 1.15,
				"texture_name": "enemy_zombie_corredor",
				"min_wave": 1,
				"max_wave": 50
			}
		EnemyType.HUMANOID:
			return {
				"hp_multiplier": 1.0,
				"speed_multiplier": 1.0,
				"max_speed_multiplier": 1.0,
				"texture_name": "enemy_humanoid",
				"min_wave": 6,
				"max_wave": 10
			}
		EnemyType.ROBOT:
			return {
				"hp_multiplier": 1.0,
				"speed_multiplier": 1.0,
				"max_speed_multiplier": 1.0,
				"texture_name": "enemy_robot",
				"min_wave": 11,
				"max_wave": 49
			}
		EnemyType.ALIEN:
			return {
				"hp_multiplier": 1.0,
				"speed_multiplier": 1.0,
				"max_speed_multiplier": 1.0,
				"texture_name": "enemy_alien",
				"min_wave": 50,
				"max_wave": 100
			}
		EnemyType.ALIEN_VOADOR:
			return {
				"hp_multiplier": 0.3,
				"speed_multiplier": 1.0,
				"max_speed_multiplier": 1.0,
				"texture_name": "alien_voador",
				"min_wave": 51,
				"max_wave": 100,
				"ignores_path": true
			}
		EnemyType.MECANOIDE_BIPEDE:
			return {
				"hp_multiplier": 1.0,
				"speed_multiplier": 1.0,
				"max_speed_multiplier": 1.0,
				"texture_name": "mecanoide_bipede1",
				"min_wave": 101,
				"max_wave": 9999
			}
		EnemyType.MECANOIDE_LAGARTAS:
			return {
				"hp_multiplier": 0.8,
				"speed_multiplier": 1.35,
				"max_speed_multiplier": 1.15,
				"texture_name": "mecanoide_lagartas1",
				"min_wave": 101,
				"max_wave": 9999
			}
		EnemyType.MECANOIDE_DRONE:
			return {
				"hp_multiplier": 0.35,
				"speed_multiplier": 1.0,
				"max_speed_multiplier": 1.0,
				"texture_name": "mecanoide_drone1",
				"min_wave": 101,
				"max_wave": 9999,
				"ignores_path": true
			}
		EnemyType.MECANOIDE_REGENERADOR:
			return {
				"hp_multiplier": 1.2,
				"speed_multiplier": 0.9,
				"max_speed_multiplier": 1.0,
				"texture_name": "mecanoide_regenerado1",
				"min_wave": 101,
				"max_wave": 9999,
				"regen_hp_per_second": 0.02
			}
		EnemyType.MECANOIDE_BOSS:
			return {
				"hp_multiplier": 1.0,
				"speed_multiplier": 1.0,
				"max_speed_multiplier": 1.0,
				"texture_name": "mecanoide_boss1",
				"min_wave": 101,
				"max_wave": 9999
			}
		_:
			return {
				"hp_multiplier": 1.0,
				"speed_multiplier": 1.0,
				"max_speed_multiplier": 1.0,
				"texture_name": "enemy_zombie",
				"min_wave": 1,
				"max_wave": 9999
			}

static func get_available_enemy_types(wave: int) -> Array:
	var available_types = []
	for type in EnemyType.values():
		var config = get_enemy_type_config(type)
		if wave >= config.min_wave and wave <= config.max_wave:
			available_types.append(type)
	return available_types

const ALIEN_VOADOR_SPAWN_CHANCE := 0.10
