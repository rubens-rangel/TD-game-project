extends RefCounted
class_name SpecialCurrencyManager

# Gerencia moedas especiais (Esmeraldas e Diamantes)

var emeralds: int = 0
var diamonds: int = 0

# Estatísticas
var total_emeralds_earned: int = 0
var total_diamonds_earned: int = 0
var total_emeralds_spent: int = 0
var total_diamonds_spent: int = 0

func _init():
	load_currency_data()

func add_emeralds(amount: int, source: String = "unknown"):
	"""Adiciona esmeraldas"""
	emeralds += amount
	total_emeralds_earned += amount
	save_currency_data()
	print("+%d Esmeraldas (de %s). Total: %d" % [amount, source, emeralds])

func add_diamonds(amount: int, source: String = "unknown"):
	"""Adiciona diamantes"""
	diamonds += amount
	total_diamonds_earned += amount
	save_currency_data()
	print("+%d Diamantes (de %s). Total: %d" % [amount, source, diamonds])

func spend_emeralds(amount: int) -> bool:
	"""Gasta esmeraldas. Retorna true se conseguiu gastar"""
	if emeralds >= amount:
		emeralds -= amount
		total_emeralds_spent += amount
		save_currency_data()
		return true
	return false

func spend_diamonds(amount: int) -> bool:
	"""Gasta diamantes. Retorna true se conseguiu gastar"""
	if diamonds >= amount:
		diamonds -= amount
		total_diamonds_spent += amount
		save_currency_data()
		return true
	return false

func has_emeralds(amount: int) -> bool:
	"""Verifica se tem esmeraldas suficientes"""
	return emeralds >= amount

func has_diamonds(amount: int) -> bool:
	"""Verifica se tem diamantes suficientes"""
	return diamonds >= amount

func get_currency_info() -> Dictionary:
	"""Retorna informações sobre as moedas"""
	return {
		"emeralds": emeralds,
		"diamonds": diamonds,
		"total_emeralds_earned": total_emeralds_earned,
		"total_diamonds_earned": total_diamonds_earned,
		"total_emeralds_spent": total_emeralds_spent,
		"total_diamonds_spent": total_diamonds_spent
	}

func save_currency_data():
	"""Salva dados de moedas especiais"""
	var config = ConfigFile.new()
	var config_path = "user://special_currency.cfg"
	
	# Carregar dados existentes se houver
	config.load(config_path)
	
	# Salvar dados
	config.set_value("currency", "emeralds", emeralds)
	config.set_value("currency", "diamonds", diamonds)
	config.set_value("stats", "total_emeralds_earned", total_emeralds_earned)
	config.set_value("stats", "total_diamonds_earned", total_diamonds_earned)
	config.set_value("stats", "total_emeralds_spent", total_emeralds_spent)
	config.set_value("stats", "total_diamonds_spent", total_diamonds_spent)
	
	# Salvar arquivo
	config.save(config_path)

func load_currency_data():
	"""Carrega dados de moedas especiais"""
	var config = ConfigFile.new()
	var config_path = "user://special_currency.cfg"
	
	if config.load(config_path) == OK:
		emeralds = config.get_value("currency", "emeralds", 0)
		diamonds = config.get_value("currency", "diamonds", 0)
		total_emeralds_earned = config.get_value("stats", "total_emeralds_earned", 0)
		total_diamonds_earned = config.get_value("stats", "total_diamonds_earned", 0)
		total_emeralds_spent = config.get_value("stats", "total_emeralds_spent", 0)
		total_diamonds_spent = config.get_value("stats", "total_diamonds_spent", 0)
	else:
		# Valores padrão
		emeralds = 0
		diamonds = 0
		total_emeralds_earned = 0
		total_diamonds_earned = 0
		total_emeralds_spent = 0
		total_diamonds_spent = 0

func should_drop_emerald(current_wave: int) -> bool:
	"""Verifica se deve dropar esmeralda baseado na wave"""
	if current_wave < GameConstants.EMERALD_DROP_START_WAVE:
		return false
	return randf() < GameConstants.EMERALD_DROP_CHANCE

func should_drop_diamond(current_wave: int) -> bool:
	"""Verifica se deve dropar diamante baseado na wave"""
	if current_wave < GameConstants.DIAMOND_DROP_START_WAVE:
		return false
	return randf() < GameConstants.DIAMOND_DROP_CHANCE

func is_special_boss_wave(wave: int) -> bool:
	"""Verifica se é uma wave de boss especial (dá esmeralda garantida)"""
	return wave > 0 and wave % GameConstants.BOSS_EMERALD_REWARD_WAVE == 0

