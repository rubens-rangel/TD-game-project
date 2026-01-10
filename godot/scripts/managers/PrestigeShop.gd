extends RefCounted
class_name PrestigeShop

# Loja de melhorias permanentes usando moedas especiais

# Níveis de melhorias compradas
var start_coins_level: int = 0
var coin_drop_level: int = 0
var hero_damage_level: int = 0
var hero_firerate_level: int = 0
var base_hp_level: int = 0
var special_tower_unlocked: bool = false

# Melhorias com diamantes
var prestige_resets: int = 0  # Quantas vezes fez prestígio
var tower_upgrade_all: bool = false
var special_modes_unlocked: Array = []  # Lista de modos especiais desbloqueados
var reward_multiplier_level: int = 0  # Nível do multiplicador de recompensas
var legendary_tower_unlocked: bool = false
var base_hp_boost_level: int = 0  # Nível de boost de HP da base
var hero_damage_boost_level: int = 0  # Nível de boost de dano do herói
var coin_drop_boost_level: int = 0  # Nível de boost de chance de drop de moedas
var starting_coins_boost_level: int = 0  # Nível de boost de moedas iniciais

func _init():
	load_prestige_data()

# ========== MELHORIAS COM ESMERALDAS ==========

func purchase_start_coins(currency_manager: SpecialCurrencyManager) -> bool:
	"""Compra nível de moedas iniciais"""
	if start_coins_level >= GameConstants.PRESTIGE_MAX_START_COINS_LEVEL:
		return false
	
	var cost = GameConstants.PRESTIGE_COST_START_COINS_LEVEL
	if currency_manager.spend_emeralds(cost):
		start_coins_level += 1
		save_prestige_data()
		return true
	return false

func purchase_coin_drop(currency_manager: SpecialCurrencyManager) -> bool:
	"""Compra nível de chance de drop de moedas"""
	if coin_drop_level >= GameConstants.PRESTIGE_MAX_COIN_DROP_LEVEL:
		return false
	
	var cost = GameConstants.PRESTIGE_COST_COIN_DROP_LEVEL
	if currency_manager.spend_emeralds(cost):
		coin_drop_level += 1
		save_prestige_data()
		return true
	return false

func purchase_hero_damage(currency_manager: SpecialCurrencyManager) -> bool:
	"""Compra nível de dano do herói"""
	if hero_damage_level >= GameConstants.PRESTIGE_MAX_HERO_DAMAGE_LEVEL:
		return false
	
	var cost = GameConstants.PRESTIGE_COST_HERO_DAMAGE_LEVEL
	if currency_manager.spend_emeralds(cost):
		hero_damage_level += 1
		save_prestige_data()
		return true
	return false

func purchase_hero_firerate(currency_manager: SpecialCurrencyManager) -> bool:
	"""Compra nível de velocidade de tiro do herói"""
	if hero_firerate_level >= GameConstants.PRESTIGE_MAX_HERO_FIRERATE_LEVEL:
		return false
	
	var cost = GameConstants.PRESTIGE_COST_HERO_FIRERATE_LEVEL
	if currency_manager.spend_emeralds(cost):
		hero_firerate_level += 1
		save_prestige_data()
		return true
	return false

func purchase_base_hp(currency_manager: SpecialCurrencyManager) -> bool:
	"""Compra nível de HP da base"""
	if base_hp_level >= GameConstants.PRESTIGE_MAX_BASE_HP_LEVEL:
		return false
	
	var cost = GameConstants.PRESTIGE_COST_BASE_HP_LEVEL
	if currency_manager.spend_emeralds(cost):
		base_hp_level += 1
		save_prestige_data()
		return true
	return false

func purchase_special_tower(currency_manager: SpecialCurrencyManager) -> bool:
	"""Desbloqueia torre especial"""
	if special_tower_unlocked:
		return false
	
	var cost = GameConstants.PRESTIGE_COST_SPECIAL_TOWER
	if currency_manager.spend_emeralds(cost):
		special_tower_unlocked = true
		save_prestige_data()
		return true
	return false

# ========== MELHORIAS COM DIAMANTES ==========

func purchase_prestige_reset(currency_manager: SpecialCurrencyManager) -> bool:
	"""Compra reset de prestígio (permite resetar progresso com bônus)"""
	var cost = GameConstants.PRESTIGE_COST_PRESTIGE_RESET
	if currency_manager.spend_diamonds(cost):
		prestige_resets += 1
		save_prestige_data()
		return true
	return false

func purchase_tower_upgrade_all(currency_manager: SpecialCurrencyManager) -> bool:
	"""Compra upgrade permanente de todas as torres"""
	if tower_upgrade_all:
		return false
	
	var cost = GameConstants.PRESTIGE_COST_TOWER_UPGRADE_ALL
	if currency_manager.spend_diamonds(cost):
		tower_upgrade_all = true
		save_prestige_data()
		return true
	return false

func purchase_special_mode(currency_manager: SpecialCurrencyManager, mode_id: String) -> bool:
	"""Desbloqueia modo especial"""
	if mode_id in special_modes_unlocked:
		return false
	
	var cost = GameConstants.PRESTIGE_COST_SPECIAL_MODE
	if currency_manager.spend_diamonds(cost):
		special_modes_unlocked.append(mode_id)
		save_prestige_data()
		return true
	return false

func purchase_reward_multiplier(currency_manager: SpecialCurrencyManager) -> bool:
	"""Compra nível de multiplicador de recompensas"""
	var cost = GameConstants.PRESTIGE_COST_REWARD_MULTIPLIER
	if currency_manager.spend_diamonds(cost):
		reward_multiplier_level += 1
		save_prestige_data()
		return true
	return false

func purchase_legendary_tower(currency_manager: SpecialCurrencyManager) -> bool:
	"""Desbloqueia torre lendária"""
	if legendary_tower_unlocked:
		return false
	
	var cost = GameConstants.PRESTIGE_COST_LEGENDARY_TOWER
	if currency_manager.spend_diamonds(cost):
		legendary_tower_unlocked = true
		save_prestige_data()
		return true
	return false

func purchase_base_hp_boost(currency_manager: SpecialCurrencyManager) -> bool:
	"""Compra nível de boost de HP da base"""
	var cost = GameConstants.PRESTIGE_COST_BASE_HP_BOOST
	if currency_manager.spend_diamonds(cost):
		base_hp_boost_level += 1
		save_prestige_data()
		return true
	return false

func purchase_hero_damage_boost(currency_manager: SpecialCurrencyManager) -> bool:
	"""Compra nível de boost de dano do herói"""
	var cost = GameConstants.PRESTIGE_COST_HERO_DAMAGE_BOOST
	if currency_manager.spend_diamonds(cost):
		hero_damage_boost_level += 1
		save_prestige_data()
		return true
	return false

func purchase_coin_drop_boost(currency_manager: SpecialCurrencyManager) -> bool:
	"""Compra nível de boost de chance de drop de moedas"""
	var cost = GameConstants.PRESTIGE_COST_COIN_DROP_BOOST
	if currency_manager.spend_diamonds(cost):
		coin_drop_boost_level += 1
		save_prestige_data()
		return true
	return false

func purchase_starting_coins_boost(currency_manager: SpecialCurrencyManager) -> bool:
	"""Compra nível de boost de moedas iniciais"""
	var cost = GameConstants.PRESTIGE_COST_STARTING_COINS_BOOST
	if currency_manager.spend_diamonds(cost):
		starting_coins_boost_level += 1
		save_prestige_data()
		return true
	return false

# ========== GETTERS DE BÔNUS ==========

func get_start_coins_bonus() -> int:
	"""Retorna bônus de moedas iniciais"""
	return start_coins_level * 20  # +20 moedas por nível

func get_coin_drop_bonus() -> float:
	"""Retorna bônus de chance de drop de moedas"""
	return coin_drop_level * 0.05  # +5% por nível

func get_hero_damage_bonus() -> float:
	"""Retorna bônus de dano do herói"""
	return hero_damage_level * 0.1  # +10% por nível

func get_hero_firerate_bonus() -> float:
	"""Retorna bônus de velocidade de tiro do herói"""
	return hero_firerate_level * 0.1  # +10% por nível

func get_base_hp_bonus() -> float:
	"""Retorna bônus de HP da base"""
	return base_hp_level * 10.0  # +10 HP por nível

func get_reward_multiplier() -> float:
	"""Retorna multiplicador de recompensas"""
	return 1.0 + (reward_multiplier_level * 0.1)  # +10% por nível

func get_base_hp_boost() -> float:
	"""Retorna boost de HP da base"""
	return base_hp_boost_level * 20.0  # +20 HP por nível

func get_hero_damage_boost() -> float:
	"""Retorna boost de dano do herói"""
	return hero_damage_boost_level * 0.15  # +15% por nível

func get_coin_drop_boost() -> float:
	"""Retorna boost de chance de drop de moedas"""
	return coin_drop_boost_level * 0.03  # +3% por nível

func get_starting_coins_boost() -> int:
	"""Retorna boost de moedas iniciais"""
	return starting_coins_boost_level * 50  # +50 moedas por nível

func get_prestige_bonus() -> Dictionary:
	"""Retorna bônus acumulado de prestígio"""
	return {
		"coins_multiplier": 1.0 + (prestige_resets * 0.05),  # +5% por reset
		"damage_multiplier": 1.0 + (prestige_resets * 0.02),  # +2% por reset
		"starting_wave": prestige_resets  # Começa na wave X após prestígio
	}

# ========== SAVE/LOAD ==========

func save_prestige_data():
	"""Salva dados de prestígio"""
	var config = ConfigFile.new()
	var config_path = "user://prestige_shop.cfg"
	
	config.load(config_path)
	
	# Salvar melhorias com esmeraldas
	config.set_value("emerald_upgrades", "start_coins_level", start_coins_level)
	config.set_value("emerald_upgrades", "coin_drop_level", coin_drop_level)
	config.set_value("emerald_upgrades", "hero_damage_level", hero_damage_level)
	config.set_value("emerald_upgrades", "hero_firerate_level", hero_firerate_level)
	config.set_value("emerald_upgrades", "base_hp_level", base_hp_level)
	config.set_value("emerald_upgrades", "special_tower_unlocked", special_tower_unlocked)
	
	# Salvar melhorias com diamantes
	config.set_value("diamond_upgrades", "prestige_resets", prestige_resets)
	config.set_value("diamond_upgrades", "tower_upgrade_all", tower_upgrade_all)
	config.set_value("diamond_upgrades", "special_modes_unlocked", special_modes_unlocked)
	config.set_value("diamond_upgrades", "reward_multiplier_level", reward_multiplier_level)
	config.set_value("diamond_upgrades", "legendary_tower_unlocked", legendary_tower_unlocked)
	config.set_value("diamond_upgrades", "base_hp_boost_level", base_hp_boost_level)
	config.set_value("diamond_upgrades", "hero_damage_boost_level", hero_damage_boost_level)
	config.set_value("diamond_upgrades", "coin_drop_boost_level", coin_drop_boost_level)
	config.set_value("diamond_upgrades", "starting_coins_boost_level", starting_coins_boost_level)
	
	config.save(config_path)

func load_prestige_data():
	"""Carrega dados de prestígio"""
	var config = ConfigFile.new()
	var config_path = "user://prestige_shop.cfg"
	
	if config.load(config_path) == OK:
		# Carregar melhorias com esmeraldas
		start_coins_level = config.get_value("emerald_upgrades", "start_coins_level", 0)
		coin_drop_level = config.get_value("emerald_upgrades", "coin_drop_level", 0)
		hero_damage_level = config.get_value("emerald_upgrades", "hero_damage_level", 0)
		hero_firerate_level = config.get_value("emerald_upgrades", "hero_firerate_level", 0)
		base_hp_level = config.get_value("emerald_upgrades", "base_hp_level", 0)
		special_tower_unlocked = config.get_value("emerald_upgrades", "special_tower_unlocked", false)
		
		# Carregar melhorias com diamantes
		prestige_resets = config.get_value("diamond_upgrades", "prestige_resets", 0)
		tower_upgrade_all = config.get_value("diamond_upgrades", "tower_upgrade_all", false)
		special_modes_unlocked = config.get_value("diamond_upgrades", "special_modes_unlocked", [])
		reward_multiplier_level = config.get_value("diamond_upgrades", "reward_multiplier_level", 0)
		legendary_tower_unlocked = config.get_value("diamond_upgrades", "legendary_tower_unlocked", false)
		base_hp_boost_level = config.get_value("diamond_upgrades", "base_hp_boost_level", 0)
		hero_damage_boost_level = config.get_value("diamond_upgrades", "hero_damage_boost_level", 0)
		coin_drop_boost_level = config.get_value("diamond_upgrades", "coin_drop_boost_level", 0)
		starting_coins_boost_level = config.get_value("diamond_upgrades", "starting_coins_boost_level", 0)
	else:
		# Valores padrão
		start_coins_level = 0
		coin_drop_level = 0
		hero_damage_level = 0
		hero_firerate_level = 0
		base_hp_level = 0
		special_tower_unlocked = false
		prestige_resets = 0
		tower_upgrade_all = false
		special_modes_unlocked = []
		reward_multiplier_level = 0
		legendary_tower_unlocked = false
		base_hp_boost_level = 0
		hero_damage_boost_level = 0
		coin_drop_boost_level = 0
		starting_coins_boost_level = 0

func get_all_upgrades_info() -> Dictionary:
	"""Retorna informações de todas as melhorias"""
	return {
		"emerald_upgrades": {
			"start_coins": {"level": start_coins_level, "max": GameConstants.PRESTIGE_MAX_START_COINS_LEVEL},
			"coin_drop": {"level": coin_drop_level, "max": GameConstants.PRESTIGE_MAX_COIN_DROP_LEVEL},
			"hero_damage": {"level": hero_damage_level, "max": GameConstants.PRESTIGE_MAX_HERO_DAMAGE_LEVEL},
			"hero_firerate": {"level": hero_firerate_level, "max": GameConstants.PRESTIGE_MAX_HERO_FIRERATE_LEVEL},
			"base_hp": {"level": base_hp_level, "max": GameConstants.PRESTIGE_MAX_BASE_HP_LEVEL},
			"special_tower": {"unlocked": special_tower_unlocked}
		},
		"diamond_upgrades": {
			"prestige_resets": prestige_resets,
			"tower_upgrade_all": tower_upgrade_all,
			"special_modes": special_modes_unlocked,
			"reward_multiplier": reward_multiplier_level,
			"legendary_tower": legendary_tower_unlocked,
			"base_hp_boost": base_hp_boost_level,
			"hero_damage_boost": hero_damage_boost_level,
			"coin_drop_boost": coin_drop_boost_level,
			"starting_coins_boost": starting_coins_boost_level
		}
	}

