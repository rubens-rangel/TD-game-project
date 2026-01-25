extends RefCounted
class_name EnemyConstants

# Constantes relacionadas a inimigos
# Este arquivo contém todas as configurações de inimigos, bosses e tipos de inimigos

# Enemy stats
const ENEMY_BASE_SPEED := 38.0
const ENEMY_MAX_SPEED := 210.0
const BOSS_SPEED_MULTIPLIER := 0.5
const ENEMY_BASE_HP := 4
const BOSS_BASE_HP := 28
const BOSS_REWARD_MULTIPLIER := 20
const NORMAL_REWARD := 2

# Tipos de inimigos (padronizado para facilitar adição de novos)
enum EnemyType {
	ZOMBIE,         # Zombie normal (waves iniciais)
	ZOMBIE_GORDO,   # Zombie gordo (waves iniciais, mais HP, menos velocidade)
	ZOMBIE_CORREDOR, # Zombie corredor (waves iniciais, menos HP, mais velocidade)
	HUMANOID,       # Humanoid (wave 6+)
	ROBOT,          # Robot (wave 11+)
	ALIEN,          # Alien (wave 50+)
	ALIEN_VOADOR    # Alien voador (wave 51+, ignora labirinto, 30% HP)
}

# Configuração de tipos de inimigos
# Formato: {hp_multiplier: float, speed_multiplier: float, max_speed_multiplier: float, texture_name: String, min_wave: int, max_wave: int}
static func get_enemy_type_config(type: EnemyType) -> Dictionary:
	match type:
		EnemyType.ZOMBIE:
			return {
				"hp_multiplier": 1.0,
				"speed_multiplier": 1.0,
				"max_speed_multiplier": 1.0,  # Cap de velocidade padrão
				"texture_name": "enemy_zombie",
				"min_wave": 1,
				"max_wave": 50  # Aparece até wave 50
			}
		EnemyType.ZOMBIE_GORDO:
			return {
				"hp_multiplier": 1.5,  # 50% mais HP
				"speed_multiplier": 0.75,  # 25% menos velocidade
				"max_speed_multiplier": 1.0,  # Cap de velocidade padrão
				"texture_name": "enemy_zombie_gordo",
				"min_wave": 1,
				"max_wave": 50  # Aparece até wave 50
			}
		EnemyType.ZOMBIE_CORREDOR:
			return {
				"hp_multiplier": 0.5,  # 50% menos HP (bem menos vida)
				"speed_multiplier": 1.4,  # 40% mais rápido
				"max_speed_multiplier": 1.15,  # Cap de velocidade 15% maior
				"texture_name": "enemy_zombie_corredor",
				"min_wave": 1,
				"max_wave": 50  # Aparece até wave 50
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
				"max_wave": 9999
			}
		EnemyType.ALIEN_VOADOR:
			return {
				"hp_multiplier": 0.3,  # 30% da vida do alien normal
				"speed_multiplier": 1.0,
				"max_speed_multiplier": 1.0,
				"texture_name": "alien_voador",
				"min_wave": 51,
				"max_wave": 9999,
				"ignores_path": true  # Flag para ignorar labirinto
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

# Obter tipos de inimigos disponíveis para uma wave específica
static func get_available_enemy_types(wave: int) -> Array:
	var available_types = []
	for type in EnemyType.values():
		var config = get_enemy_type_config(type)
		if wave >= config.min_wave and wave <= config.max_wave:
			available_types.append(type)
	return available_types

# Alien Voador Spawn Chance
const ALIEN_VOADOR_SPAWN_CHANCE := 0.10  # 10% de chance de spawnar alien voador ao invés de alien normal
