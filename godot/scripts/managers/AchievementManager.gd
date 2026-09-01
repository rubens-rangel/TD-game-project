extends RefCounted
class_name AchievementManager

signal achievement_unlocked(achievement_name: String)

const ACHIEVEMENTS_FILE = "user://achievements.json"

enum Category {
	COMBAT,
	ECONOMY,
	DEFENSE,
	PROGRESSION,
	SPECIAL
}

static var ALL_ACHIEVEMENTS: Dictionary = {

	"first_kill": {
		"name": "Primeiro Sangue",
		"description": "Mate seu primeiro inimigo",
		"category": Category.COMBAT,
		"max_progress": 1,
		"reward_points": 5,
		"icon": "⚔️"
	},
	"kill_100": {
		"name": "Caçador",
		"description": "Mate 100 inimigos",
		"category": Category.COMBAT,
		"max_progress": 100,
		"reward_points": 20,
		"icon": "🎯"
	},
	"kill_1000": {
		"name": "Exterminador",
		"description": "Mate 1000 inimigos",
		"category": Category.COMBAT,
		"max_progress": 1000,
		"reward_points": 50,
		"icon": "💀"
	},
	"kill_10000": {
		"name": "Lenda do Campo de Batalha",
		"description": "Mate 10000 inimigos",
		"category": Category.COMBAT,
		"max_progress": 10000,
		"reward_points": 200,
		"icon": "👑"
	},
	"boss_kill": {
		"name": "Gigante Abatido",
		"description": "Mate seu primeiro boss",
		"category": Category.COMBAT,
		"max_progress": 1,
		"reward_points": 30,
		"icon": "👹"
	},
	"boss_kill_10": {
		"name": "Caçador de Chefes",
		"description": "Mate 10 bosses",
		"category": Category.COMBAT,
		"max_progress": 10,
		"reward_points": 100,
		"icon": "🗡️"
	},
	"boss_kill_50": {
		"name": "Destruidor de Titãs",
		"description": "Mate 50 bosses",
		"category": Category.COMBAT,
		"max_progress": 50,
		"reward_points": 300,
		"icon": "⚔️"
	},
	"boss_kill_100": {
		"name": "Aniquilador de Deuses",
		"description": "Mate 100 bosses",
		"category": Category.COMBAT,
		"max_progress": 100,
		"reward_points": 500,
		"icon": "🔱"
	},
	"kill_50000": {
		"name": "Máquina de Guerra",
		"description": "Mate 50000 inimigos",
		"category": Category.COMBAT,
		"max_progress": 50000,
		"reward_points": 500,
		"icon": "⚙️"
	},


	"collect_1000_coins": {
		"name": "Acumulador",
		"description": "Colete 1000 moedas",
		"category": Category.ECONOMY,
		"max_progress": 1000,
		"reward_points": 15,
		"icon": "💰"
	},
	"collect_10000_coins": {
		"name": "Rico",
		"description": "Colete 10000 moedas",
		"category": Category.ECONOMY,
		"max_progress": 10000,
		"reward_points": 50,
		"icon": "💎"
	},
	"collect_100000_coins": {
		"name": "Magnata",
		"description": "Colete 100000 moedas",
		"category": Category.ECONOMY,
		"max_progress": 100000,
		"reward_points": 200,
		"icon": "🏆"
	},
	"spend_5000_coins": {
		"name": "Investidor",
		"description": "Gaste 5000 moedas em upgrades",
		"category": Category.ECONOMY,
		"max_progress": 5000,
		"reward_points": 25,
		"icon": "💳"
	},
	"collect_1000000_coins": {
		"name": "Bilionário",
		"description": "Colete 1000000 moedas",
		"category": Category.ECONOMY,
		"max_progress": 1000000,
		"reward_points": 500,
		"icon": "💵"
	},
	"spend_100000_coins": {
		"name": "Magnata Investidor",
		"description": "Gaste 100000 moedas em upgrades",
		"category": Category.ECONOMY,
		"max_progress": 100000,
		"reward_points": 300,
		"icon": "💸"
	},
	"hold_10000_coins": {
		"name": "Tesouro",
		"description": "Tenha 10000 moedas ao mesmo tempo",
		"category": Category.ECONOMY,
		"max_progress": 1,
		"reward_points": 100,
		"icon": "🏦"
	},
	"hold_50000_coins": {
		"name": "Banco Central",
		"description": "Tenha 50000 moedas ao mesmo tempo",
		"category": Category.ECONOMY,
		"max_progress": 1,
		"reward_points": 250,
		"icon": "🏛️"
	},


	"build_10_towers": {
		"name": "Arquiteto",
		"description": "Construa 10 torres",
		"category": Category.DEFENSE,
		"max_progress": 10,
		"reward_points": 20,
		"icon": "🏰"
	},
	"build_all_tower_types": {
		"name": "Mestre Construtor",
		"description": "Construa todos os tipos de torres",
		"category": Category.DEFENSE,
		"max_progress": 7,
		"reward_points": 40,
		"icon": "🏗️"
	},
	"upgrade_tower_max": {
		"name": "Perfeccionista",
		"description": "Maximize todas as melhorias de uma torre",
		"category": Category.DEFENSE,
		"max_progress": 1,
		"reward_points": 30,
		"icon": "⭐"
	},
	"build_5_walls": {
		"name": "Fortaleza",
		"description": "Construa 5 muros",
		"category": Category.DEFENSE,
		"max_progress": 5,
		"reward_points": 15,
		"icon": "🧱"
	},
	"build_50_towers": {
		"name": "Engenheiro Mestre",
		"description": "Construa 50 torres",
		"category": Category.DEFENSE,
		"max_progress": 50,
		"reward_points": 100,
		"icon": "🏛️"
	},
	"build_100_towers": {
		"name": "Construtor Épico",
		"description": "Construa 100 torres",
		"category": Category.DEFENSE,
		"max_progress": 100,
		"reward_points": 250,
		"icon": "🏗️"
	},
	"build_50_walls": {
		"name": "Muralha da China",
		"description": "Construa 50 muros",
		"category": Category.DEFENSE,
		"max_progress": 50,
		"reward_points": 150,
		"icon": "🛡️"
	},
	"upgrade_10_towers_max": {
		"name": "Mestre Perfeccionista",
		"description": "Maximize 10 torres diferentes",
		"category": Category.DEFENSE,
		"max_progress": 10,
		"reward_points": 200,
		"icon": "💎"
	},
	"build_all_structures": {
		"name": "Colecionador Completo",
		"description": "Construa todos os tipos de estruturas (torres, muros, quartéis, minas, etc)",
		"category": Category.DEFENSE,
		"max_progress": 1,
		"reward_points": 100,
		"icon": "🎯"
	},


	"wave_10": {
		"name": "Sobrevivente",
		"description": "Alcance a onda 10",
		"category": Category.PROGRESSION,
		"max_progress": 10,
		"reward_points": 25,
		"icon": "🌊"
	},
	"wave_25": {
		"name": "Veterano",
		"description": "Alcance a onda 25",
		"category": Category.PROGRESSION,
		"max_progress": 25,
		"reward_points": 50,
		"icon": "⚡"
	},
	"wave_50": {
		"name": "Lenda",
		"description": "Alcance a onda 50",
		"category": Category.PROGRESSION,
		"max_progress": 50,
		"reward_points": 100,
		"icon": "🌟"
	},
	"wave_100": {
		"name": "Imortal",
		"description": "Alcance a onda 100",
		"category": Category.PROGRESSION,
		"max_progress": 100,
		"reward_points": 300,
		"icon": "🔥"
	},
	"perfect_wave": {
		"name": "Perfeição",
		"description": "Complete uma onda sem perder vida na base",
		"category": Category.PROGRESSION,
		"max_progress": 1,
		"reward_points": 20,
		"icon": "✨"
	},
	"wave_200": {
		"name": "Deus da Guerra",
		"description": "Alcance a onda 200",
		"category": Category.PROGRESSION,
		"max_progress": 200,
		"reward_points": 500,
		"icon": "⚡"
	},
	"wave_500": {
		"name": "Transcendente",
		"description": "Alcance a onda 500",
		"category": Category.PROGRESSION,
		"max_progress": 500,
		"reward_points": 1000,
		"icon": "🌌"
	},
	"perfect_wave_10": {
		"name": "Mestre da Perfeição",
		"description": "Complete 10 waves perfeitas",
		"category": Category.PROGRESSION,
		"max_progress": 10,
		"reward_points": 150,
		"icon": "⭐"
	},
	"perfect_wave_50": {
		"name": "Perfeição Absoluta",
		"description": "Complete 50 waves perfeitas",
		"category": Category.PROGRESSION,
		"max_progress": 50,
		"reward_points": 400,
		"icon": "💫"
	},
	"perfect_wave_100": {
		"name": "Imaculado",
		"description": "Complete 100 waves perfeitas",
		"category": Category.PROGRESSION,
		"max_progress": 100,
		"reward_points": 600,
		"icon": "✨"
	},
	"survive_100_waves_no_damage": {
		"name": "Invencível",
		"description": "Sobreviva 100 waves sem perder vida na base",
		"category": Category.PROGRESSION,
		"max_progress": 100,
		"reward_points": 500,
		"icon": "🛡️"
	},
	"play_time_5min": {
		"name": "Iniciante",
		"description": "Jogue por 5 minutos",
		"category": Category.PROGRESSION,
		"max_progress": 300,
		"reward_points": 15,
		"icon": "⏱️"
	},
	"play_time_15min": {
		"name": "Persistente",
		"description": "Jogue por 15 minutos",
		"category": Category.PROGRESSION,
		"max_progress": 900,
		"reward_points": 30,
		"icon": "⏰"
	},
	"play_time_30min": {
		"name": "Dedicado",
		"description": "Jogue por 30 minutos",
		"category": Category.PROGRESSION,
		"max_progress": 1800,
		"reward_points": 50,
		"icon": "🕐"
	},
	"play_time_1hour": {
		"name": "Veterano do Tempo",
		"description": "Jogue por 1 hora",
		"category": Category.PROGRESSION,
		"max_progress": 3600,
		"reward_points": 100,
		"icon": "🕑"
	},
	"play_time_2hours": {
		"name": "Maratonista",
		"description": "Jogue por 2 horas",
		"category": Category.PROGRESSION,
		"max_progress": 7200,
		"reward_points": 200,
		"icon": "🕒"
	},
	"play_time_5hours": {
		"name": "Lenda do Tempo",
		"description": "Jogue por 5 horas",
		"category": Category.PROGRESSION,
		"max_progress": 18000,
		"reward_points": 500,
		"icon": "⏳"
	},


	"first_play": {
		"name": "Bem-vindo",
		"description": "Jogue sua primeira partida",
		"category": Category.SPECIAL,
		"max_progress": 1,
		"reward_points": 10,
		"icon": "👋"
	},
	"save_game": {
		"name": "Prevenção",
		"description": "Salve seu jogo pela primeira vez",
		"category": Category.SPECIAL,
		"max_progress": 1,
		"reward_points": 5,
		"icon": "💾"
	},
	"collect_skill": {
		"name": "Habilidade",
		"description": "Use uma skill pela primeira vez",
		"category": Category.SPECIAL,
		"max_progress": 1,
		"reward_points": 10,
		"icon": "🎮"
	},
	"unlock_all_achievements": {
		"name": "Conquistador Completo",
		"description": "Desbloqueie todos os achievements",
		"category": Category.SPECIAL,
		"max_progress": 1,
		"reward_points": 500,
		"icon": "🏅"
	},
	"no_towers_challenge": {
		"name": "Desafio do Herói",
		"description": "Complete uma partida sem construir torres (apenas hero)",
		"category": Category.SPECIAL,
		"max_progress": 1,
		"reward_points": 300,
		"icon": "🦸"
	},
	"no_damage_run": {
		"name": "Flawless Victory",
		"description": "Complete uma partida sem perder vida na base",
		"category": Category.SPECIAL,
		"max_progress": 1,
		"reward_points": 400,
		"icon": "💎"
	},
	"all_tower_types_one_game": {
		"name": "Arsenal Completo",
		"description": "Construa todos os tipos de torres em uma única partida",
		"category": Category.SPECIAL,
		"max_progress": 1,
		"reward_points": 150,
		"icon": "🎯"
	},
	"skill_only_wave": {
		"name": "Mestre das Habilidades",
		"description": "Complete uma wave usando apenas skills (sem torres)",
		"category": Category.SPECIAL,
		"max_progress": 1,
		"reward_points": 200,
		"icon": "🎮"
	},
	"speedrun_wave_25": {
		"name": "Velocista",
		"description": "Alcance a onda 25 em menos de 30 minutos",
		"category": Category.SPECIAL,
		"max_progress": 1,
		"reward_points": 250,
		"icon": "⚡"
	},
	"minimalist": {
		"name": "Minimalista",
		"description": "Complete a onda 20 usando no máximo 5 torres",
		"category": Category.SPECIAL,
		"max_progress": 1,
		"reward_points": 300,
		"icon": "🎨"
	},
	"pacifist": {
		"name": "Pacifista",
		"description": "Complete 10 waves sem matar nenhum inimigo (apenas defesa)",
		"category": Category.SPECIAL,
		"max_progress": 1,
		"reward_points": 350,
		"icon": "🕊️"
	},
	"tower_master": {
		"name": "Mestre das Torres",
		"description": "Tenha 20 torres maximizadas ao mesmo tempo",
		"category": Category.SPECIAL,
		"max_progress": 1,
		"reward_points": 400,
		"icon": "🏰"
	},
	"economy_master": {
		"name": "Mestre da Economia",
		"description": "Ganhe 50000 moedas em uma única partida",
		"category": Category.SPECIAL,
		"max_progress": 1,
		"reward_points": 300,
		"icon": "💼"
	}
}

var achievements_state: Dictionary = {}
var total_points: int = 0

var last_save_time: float = 0.0
const SAVE_COOLDOWN: float = 5.0

func _init():
	load_achievements()

func load_achievements() -> void:
	if FileAccess.file_exists(ACHIEVEMENTS_FILE):
		var file = FileAccess.open(ACHIEVEMENTS_FILE, FileAccess.READ)
		if file != null:
			var json_string = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(json_string) == OK:
				achievements_state = json.data.get("achievements", {})
				total_points = json.data.get("total_points", 0)

				_initialize_missing_achievements()
				return


	_initialize_all_achievements()

func _initialize_all_achievements() -> void:
	achievements_state = {}
	for achievement_id in ALL_ACHIEVEMENTS.keys():
		achievements_state[achievement_id] = {
			"progress": 0,
			"unlocked": false,
			"unlocked_at": 0
		}
	total_points = 0

func _initialize_missing_achievements() -> void:
	for achievement_id in ALL_ACHIEVEMENTS.keys():
		if not achievements_state.has(achievement_id):
			achievements_state[achievement_id] = {
				"progress": 0,
				"unlocked": false,
				"unlocked_at": 0
			}

func save_achievements(force: bool = false) -> void:
	var current_time = Time.get_unix_time_from_system()


	if not force and (current_time - last_save_time) < SAVE_COOLDOWN:
		return

	last_save_time = current_time

	var save_data = {
		"achievements": achievements_state,
		"total_points": total_points,
		"last_saved": current_time
	}

	var file = FileAccess.open(ACHIEVEMENTS_FILE, FileAccess.WRITE)
	if file != null:
		var json_string = JSON.stringify(save_data)
		file.store_string(json_string)
		file.close()
		print("Achievements salvos com sucesso!")

func increment_progress(achievement_id: String, amount: int = 1) -> bool:
	if not ALL_ACHIEVEMENTS.has(achievement_id):
		print("Achievement não encontrado: ", achievement_id)
		return false

	if not achievements_state.has(achievement_id):
		achievements_state[achievement_id] = {
			"progress": 0,
			"unlocked": false,
			"unlocked_at": 0
		}

	var state = achievements_state[achievement_id]
	if state.unlocked:
		return false

	var achievement = ALL_ACHIEVEMENTS[achievement_id]
	state.progress = min(state.progress + amount, achievement.max_progress)


	if state.progress >= achievement.max_progress and not state.unlocked:
		return _unlock_achievement(achievement_id, achievement, state)

	save_achievements()
	return false

func set_progress(achievement_id: String, value: int) -> bool:
	if not ALL_ACHIEVEMENTS.has(achievement_id):
		return false

	if not achievements_state.has(achievement_id):
		achievements_state[achievement_id] = {
			"progress": 0,
			"unlocked": false,
			"unlocked_at": 0
		}

	var state = achievements_state[achievement_id]
	if state.unlocked:
		return false

	var achievement = ALL_ACHIEVEMENTS[achievement_id]
	state.progress = min(value, achievement.max_progress)

	if state.progress >= achievement.max_progress and not state.unlocked:
		return _unlock_achievement(achievement_id, achievement, state)

	save_achievements()
	return false

func _unlock_achievement(_achievement_id: String, achievement: Dictionary, state: Dictionary) -> bool:
	state.unlocked = true
	state.unlocked_at = Time.get_unix_time_from_system()
	total_points += achievement.reward_points
	save_achievements(true)
	print("Achievement desbloqueado: ", achievement.name, " (+", achievement.reward_points, " pontos)")
	achievement_unlocked.emit(str(achievement.name))
	return true

func is_unlocked(achievement_id: String) -> bool:
	if not achievements_state.has(achievement_id):
		return false
	return achievements_state[achievement_id].unlocked

func get_progress(achievement_id: String) -> int:
	if not achievements_state.has(achievement_id):
		return 0
	return achievements_state[achievement_id].progress

func get_achievement_info(achievement_id: String) -> Dictionary:
	if not ALL_ACHIEVEMENTS.has(achievement_id):
		return {}

	var achievement = ALL_ACHIEVEMENTS[achievement_id].duplicate()
	var state = achievements_state.get(achievement_id, {
		"progress": 0,
		"unlocked": false,
		"unlocked_at": 0
	})

	achievement["progress"] = state.progress
	achievement["unlocked"] = state.unlocked
	achievement["unlocked_at"] = state.unlocked_at
	achievement["id"] = achievement_id

	return achievement

func get_achievements_by_category(category: Category) -> Array:
	var result = []
	for achievement_id in ALL_ACHIEVEMENTS.keys():
		var achievement = ALL_ACHIEVEMENTS[achievement_id]
		if achievement.category == category:
			result.append(get_achievement_info(achievement_id))
	return result

func get_all_achievements() -> Array:
	var result = []
	for achievement_id in ALL_ACHIEVEMENTS.keys():
		result.append(get_achievement_info(achievement_id))
	return result

func add_points(amount: int) -> void:
	"""Adiciona pontos de melhoria (ex.: recompensa de quests)"""
	if amount <= 0:
		return
	total_points += amount
	save_achievements(true)
	print("Pontos de melhoria +%d (total: %d)" % [amount, total_points])

func get_stats() -> Dictionary:
	var total = ALL_ACHIEVEMENTS.size()
	var unlocked = 0
	for achievement_id in achievements_state.keys():
		if achievements_state[achievement_id].unlocked:
			unlocked += 1

	return {
		"total": total,
		"unlocked": unlocked,
		"locked": total - unlocked,
		"completion_percentage": (float(unlocked) / float(total)) * 100.0 if total > 0 else 0.0,
		"total_points": total_points
	}

func reset_all_achievements() -> void:
	achievements_state = {}
	total_points = 0
	_initialize_all_achievements()
	save_achievements()
	print("Todos os achievements foram resetados!")

static var instance: AchievementManager = null

static func get_instance() -> AchievementManager:
	if instance == null:
		instance = AchievementManager.new()
	return instance

