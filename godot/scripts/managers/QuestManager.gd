extends RefCounted
class_name QuestManager

# Sistema de Quests - Gerencia quests diárias, semanais e mensais

enum QuestStatus {
	INACTIVE,  # Quest não está ativa
	ACTIVE,  # Quest ativa e em progresso
	COMPLETED,  # Quest completada mas não reivindicada
	CLAIMED  # Quest reivindicada
}

var daily_quests: Array = []  # Quests diárias
var weekly_quests: Array = []  # Quests semanais
var monthly_quests: Array = []  # Quests mensais

var last_daily_refresh: Dictionary = {}  # {year, month, day}
var last_weekly_refresh: Dictionary = {}  # {year, month, day, week}
var last_monthly_refresh: Dictionary = {}  # {year, month}

# Templates de quests (podem ser expandidos)
var quest_templates: Dictionary = {
	GameConstants.QuestType.KILL_ENEMIES: {
		"name": "Caçador de Monstros",
		"description": "Mate {target} inimigos",
		"icon": "⚔️"
	},
	GameConstants.QuestType.KILL_BOSSES: {
		"name": "Matador de Chefes",
		"description": "Mate {target} bosses",
		"icon": "👑"
	},
	GameConstants.QuestType.COMPLETE_WAVES: {
		"name": "Sobrevivente",
		"description": "Complete {target} waves",
		"icon": "🌊"
	},
	GameConstants.QuestType.COLLECT_COINS: {
		"name": "Colecionador",
		"description": "Colete {target} moedas",
		"icon": "💰"
	},
	GameConstants.QuestType.BUILD_TOWERS: {
		"name": "Construtor",
		"description": "Construa {target} torres",
		"icon": "🏗️"
	},
	GameConstants.QuestType.USE_SKILLS: {
		"name": "Habilidoso",
		"description": "Use {target} skills",
		"icon": "✨"
	},
	GameConstants.QuestType.PERFECT_WAVES: {
		"name": "Perfeito",
		"description": "Complete {target} waves sem perder HP da base",
		"icon": "⭐"
	},
	GameConstants.QuestType.REACH_WAVE: {
		"name": "Desafiador",
		"description": "Alcance a wave {target}",
		"icon": "🎯"
	},
	GameConstants.QuestType.SPEND_COINS: {
		"name": "Gastador",
		"description": "Gaste {target} moedas",
		"icon": "💸"
	},
	GameConstants.QuestType.UPGRADE_TOWERS: {
		"name": "Melhorador",
		"description": "Faça {target} upgrades de torres",
		"icon": "⬆️"
	}
}

func _init():
	load_quest_data()
	check_and_refresh_quests()

func load_quest_data():
	"""Carrega dados de quests salvos (se existirem)"""
	var config = ConfigFile.new()
	var config_path = "user://quests.cfg"
	
	if config.load(config_path) == OK:
		# Carregar quests diárias
		var daily_count = config.get_value("quests", "daily_count", 0)
		daily_quests.clear()
		for i in range(daily_count):
			var quest_data = config.get_value("daily_quests", "quest_%d" % i, {})
			if not quest_data.is_empty():
				daily_quests.append(quest_data)
		
		# Carregar quests semanais
		var weekly_count = config.get_value("quests", "weekly_count", 0)
		weekly_quests.clear()
		for i in range(weekly_count):
			var quest_data = config.get_value("weekly_quests", "quest_%d" % i, {})
			if not quest_data.is_empty():
				weekly_quests.append(quest_data)
		
		# Carregar quests mensais
		var monthly_count = config.get_value("quests", "monthly_count", 0)
		monthly_quests.clear()
		for i in range(monthly_count):
			var quest_data = config.get_value("monthly_quests", "quest_%d" % i, {})
			if not quest_data.is_empty():
				monthly_quests.append(quest_data)
		
		# Carregar timestamps de refresh
		last_daily_refresh = config.get_value("refresh", "last_daily", {})
		last_weekly_refresh = config.get_value("refresh", "last_weekly", {})
		last_monthly_refresh = config.get_value("refresh", "last_monthly", {})

func save_quest_data():
	"""Salva dados de quests"""
	var config = ConfigFile.new()
	var config_path = "user://quests.cfg"
	
	# Carregar dados existentes se houver
	config.load(config_path)
	
	# Salvar quests diárias
	config.set_value("quests", "daily_count", daily_quests.size())
	for i in range(daily_quests.size()):
		config.set_value("daily_quests", "quest_%d" % i, daily_quests[i])
	
	# Salvar quests semanais
	config.set_value("quests", "weekly_count", weekly_quests.size())
	for i in range(weekly_quests.size()):
		config.set_value("weekly_quests", "quest_%d" % i, weekly_quests[i])
	
	# Salvar quests mensais
	config.set_value("quests", "monthly_count", monthly_quests.size())
	for i in range(monthly_quests.size()):
		config.set_value("monthly_quests", "quest_%d" % i, monthly_quests[i])
	
	# Salvar timestamps de refresh
	config.set_value("refresh", "last_daily", last_daily_refresh)
	config.set_value("refresh", "last_weekly", last_weekly_refresh)
	config.set_value("refresh", "last_monthly", last_monthly_refresh)
	
	# Salvar arquivo
	config.save(config_path)

func get_current_date() -> Dictionary:
	"""Retorna data atual como Dictionary"""
	var time = Time.get_datetime_dict_from_system()
	return {
		"year": time.year,
		"month": time.month,
		"day": time.day,
		"week": get_week_number(time.year, time.month, time.day)
	}

func get_week_number(year: int, month: int, day: int) -> int:
	"""Calcula número da semana do ano (aproximado)"""
	# Calcula dia do ano
	var days_in_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	# Verifica ano bissexto
	if year % 4 == 0 and (year % 100 != 0 or year % 400 == 0):
		days_in_month[1] = 29
	
	var day_of_year = day
	for i in range(month - 1):
		day_of_year += days_in_month[i]
	
	# Calcula semana (aproximado: semana 1 começa no dia 1)
	var week = (day_of_year - 1) / 7 + 1
	return int(week)

func check_and_refresh_quests():
	"""Verifica e atualiza quests se necessário"""
	var current = get_current_date()
	
	# Verifica refresh diário
	if should_refresh_daily(current):
		refresh_daily_quests(current)
	
	# Verifica refresh semanal
	if should_refresh_weekly(current):
		refresh_weekly_quests(current)
	
	# Verifica refresh mensal
	if should_refresh_monthly(current):
		refresh_monthly_quests(current)

func should_refresh_daily(current: Dictionary) -> bool:
	"""Verifica se precisa refresh diário"""
	if last_daily_refresh.is_empty():
		return true
	
	return (current.year > last_daily_refresh.year or
			current.month > last_daily_refresh.month or
			current.day > last_daily_refresh.day)

func should_refresh_weekly(current: Dictionary) -> bool:
	"""Verifica se precisa refresh semanal"""
	if last_weekly_refresh.is_empty():
		return true
	
	var current_week = current.get("week", 0)
	var last_week = last_weekly_refresh.get("week", 0)
	
	return (current.year > last_weekly_refresh.year or
			current.month > last_weekly_refresh.month or
			current_week > last_week)

func should_refresh_monthly(current: Dictionary) -> bool:
	"""Verifica se precisa refresh mensal"""
	if last_monthly_refresh.is_empty():
		return true
	
	return (current.year > last_monthly_refresh.year or
			current.month > last_monthly_refresh.month)

func get_available_quest_types() -> Array:
	"""Retorna array com todos os tipos de quest disponíveis"""
	return [
		GameConstants.QuestType.KILL_ENEMIES,
		GameConstants.QuestType.KILL_BOSSES,
		GameConstants.QuestType.COMPLETE_WAVES,
		GameConstants.QuestType.COLLECT_COINS,
		GameConstants.QuestType.BUILD_TOWERS,
		GameConstants.QuestType.USE_SKILLS,
		GameConstants.QuestType.PERFECT_WAVES,
		GameConstants.QuestType.REACH_WAVE,
		GameConstants.QuestType.SPEND_COINS,
		GameConstants.QuestType.UPGRADE_TOWERS
	]

func refresh_daily_quests(current: Dictionary):
	"""Gera novas quests diárias"""
	# Só limpar e gerar novas se realmente precisar refresh
	if should_refresh_daily(current):
		daily_quests.clear()
		
		for i in range(GameConstants.QUEST_DAILY_COUNT):
			var quest = generate_quest(get_available_quest_types(), "daily", i)
			if quest:
				daily_quests.append(quest)
		
		last_daily_refresh = current.duplicate()
		save_quest_data()

func refresh_weekly_quests(current: Dictionary):
	"""Gera novas quests semanais"""
	# Só limpar e gerar novas se realmente precisar refresh
	if should_refresh_weekly(current):
		weekly_quests.clear()
		
		for i in range(GameConstants.QUEST_WEEKLY_COUNT):
			var quest = generate_quest(get_available_quest_types(), "weekly", i)
			if quest:
				weekly_quests.append(quest)
		
		last_weekly_refresh = current.duplicate()
		save_quest_data()

func refresh_monthly_quests(current: Dictionary):
	"""Gera novas quests mensais"""
	# Só limpar e gerar novas se realmente precisar refresh
	if should_refresh_monthly(current):
		monthly_quests.clear()
		
		for i in range(GameConstants.QUEST_MONTHLY_COUNT):
			var quest = generate_quest(get_available_quest_types(), "monthly", i)
			if quest:
				monthly_quests.append(quest)
		
		last_monthly_refresh = {
			"year": current.year,
			"month": current.month
		}
		save_quest_data()

func generate_quest(available_types: Array, quest_period: String, index: int) -> Dictionary:
	"""Gera uma quest aleatória"""
	if available_types.is_empty():
		return {}
	
	# Seleciona tipo aleatório
	var random_index = randi() % available_types.size()
	var quest_type = available_types[random_index]
	var template = quest_templates.get(quest_type, {})
	
	if template.is_empty():
		return {}
	
	# Define target baseado no tipo e período
	var target = get_quest_target(quest_type, quest_period)
	var reward_data = get_quest_reward(quest_period)
	
	return {
		"id": "%s_%d_%d" % [quest_period, Time.get_unix_time_from_system(), index],
		"type": quest_type,
		"name": template.name,
		"description": template.description.format({"target": target}),
		"icon": template.icon,
		"target": target,
		"current": 0,
		"reward": reward_data.coins,
		"reward_emeralds": reward_data.emeralds,
		"reward_diamonds": reward_data.diamonds,
		"status": QuestStatus.ACTIVE,
		"period": quest_period
	}

func get_quest_target(quest_type: int, period: String) -> int:
	"""Retorna target da quest baseado no tipo e período"""
	var base_targets = {
		GameConstants.QuestType.KILL_ENEMIES: {"daily": 50, "weekly": 300, "monthly": 1500},
		GameConstants.QuestType.KILL_BOSSES: {"daily": 2, "weekly": 10, "monthly": 50},
		GameConstants.QuestType.COMPLETE_WAVES: {"daily": 5, "weekly": 25, "monthly": 100},
		GameConstants.QuestType.COLLECT_COINS: {"daily": 200, "weekly": 1500, "monthly": 8000},
		GameConstants.QuestType.BUILD_TOWERS: {"daily": 3, "weekly": 15, "monthly": 60},
		GameConstants.QuestType.USE_SKILLS: {"daily": 5, "weekly": 25, "monthly": 100},
		GameConstants.QuestType.PERFECT_WAVES: {"daily": 2, "weekly": 10, "monthly": 40},
		GameConstants.QuestType.REACH_WAVE: {"daily": 10, "weekly": 30, "monthly": 100},
		GameConstants.QuestType.SPEND_COINS: {"daily": 100, "weekly": 800, "monthly": 4000},
		GameConstants.QuestType.UPGRADE_TOWERS: {"daily": 5, "weekly": 25, "monthly": 100}
	}
	
	var targets = base_targets.get(quest_type, {})
	return targets.get(period, 10)

func get_quest_reward(period: String) -> Dictionary:
	"""Retorna recompensa baseada no período (moedas e diamantes apenas)"""
	match period:
		"daily":
			return {
				"coins": GameConstants.QUEST_REWARD_DAILY_COINS,
				"emeralds": 0,
				"diamonds": 0
			}
		"weekly":
			return {
				"coins": GameConstants.QUEST_REWARD_WEEKLY_COINS,
				"emeralds": 0,
				"diamonds": 0
			}
		"monthly":
			return {
				"coins": GameConstants.QUEST_REWARD_MONTHLY_COINS,
				"emeralds": 0,
				"diamonds": GameConstants.QUEST_REWARD_MONTHLY_DIAMONDS
			}
		_:
			return {
				"coins": 50,
				"emeralds": 0,
				"diamonds": 0
			}

func update_quest_progress(quest_type: int, amount: int = 1):
	"""Atualiza progresso de quests do tipo especificado"""
	update_quest_list(daily_quests, quest_type, amount)
	update_quest_list(weekly_quests, quest_type, amount)
	update_quest_list(monthly_quests, quest_type, amount)

func update_quest_list(quest_list: Array, quest_type: int, amount: int):
	"""Atualiza progresso em uma lista de quests"""
	var needs_save = false
	for quest in quest_list:
		if quest.type == quest_type and quest.status == QuestStatus.ACTIVE:
			var old_current = quest.current
			quest.current = min(quest.current + amount, quest.target)
			
			if quest.current >= quest.target:
				quest.status = QuestStatus.COMPLETED
			
			# Salvar se o progresso mudou
			if quest.current != old_current:
				needs_save = true
	
	if needs_save:
		save_quest_data()

func get_completed_quests() -> Array:
	"""Retorna todas as quests completadas"""
	var completed = []
	completed.append_array(get_completed_from_list(daily_quests))
	completed.append_array(get_completed_from_list(weekly_quests))
	completed.append_array(get_completed_from_list(monthly_quests))
	return completed

func get_completed_from_list(quest_list: Array) -> Array:
	"""Retorna quests completadas de uma lista"""
	var completed = []
	for quest in quest_list:
		if quest.status == QuestStatus.COMPLETED:
			completed.append(quest)
	return completed

func claim_quest(quest_id: String) -> Dictionary:
	"""Reivindica recompensa de uma quest"""
	var all_quests = daily_quests + weekly_quests + monthly_quests
	
	for quest in all_quests:
		if quest.id == quest_id and quest.status == QuestStatus.COMPLETED:
			quest.status = QuestStatus.CLAIMED
			save_quest_data()
			return {
				"success": true,
				"reward": quest.reward,
				"reward_emeralds": quest.get("reward_emeralds", 0),
				"reward_diamonds": quest.get("reward_diamonds", 0),
				"quest": quest
			}
	
	return {"success": false}

func get_all_active_quests() -> Dictionary:
	"""Retorna todas as quests ativas organizadas por tipo"""
	return {
		"daily": get_active_quests(daily_quests),
		"weekly": get_active_quests(weekly_quests),
		"monthly": get_active_quests(monthly_quests)
	}

func get_active_quests(quest_list: Array) -> Array:
	"""Retorna todas as quests (ativas, completadas e reivindicadas) para exibição"""
	var active = []
	for quest in quest_list:
		# Mostrar todas as quests, incluindo as reivindicadas
		if quest.status == QuestStatus.ACTIVE or quest.status == QuestStatus.COMPLETED or quest.status == QuestStatus.CLAIMED:
			active.append(quest)
	return active



