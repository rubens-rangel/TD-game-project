extends RefCounted
class_name PrestigeShop

# Apenas upgrades com diamantes. Esmeraldas são só in-game (não compram prestígio).

var prestige_resets: int = 0
var reward_multiplier_level: int = 0
var base_hp_boost_level: int = 0
var hero_damage_boost_level: int = 0
var coin_drop_boost_level: int = 0
var starting_coins_boost_level: int = 0
var tower_arrow_corrosive_unlocked: bool = false
var slow_tower_frost_unlocked: bool = false
var aoe_tower_inferno_unlocked: bool = false
var sniper_tower_pierce_unlocked: bool = false
var shock_tower_chain_unlocked: bool = false
var boost_tower_aura_unlocked: bool = false

func _init():
	load_prestige_data()

func purchase_reward_multiplier(currency_manager: SpecialCurrencyManager) -> bool:
	var cost = GameConstants.PRESTIGE_COST_REWARD_MULTIPLIER
	if currency_manager.spend_diamonds(cost):
		reward_multiplier_level += 1
		save_prestige_data()
		return true
	return false

func purchase_base_hp_boost(currency_manager: SpecialCurrencyManager) -> bool:
	var cost = GameConstants.PRESTIGE_COST_BASE_HP_BOOST
	if currency_manager.spend_diamonds(cost):
		base_hp_boost_level += 1
		save_prestige_data()
		return true
	return false

func purchase_hero_damage_boost(currency_manager: SpecialCurrencyManager) -> bool:
	var cost = GameConstants.PRESTIGE_COST_HERO_DAMAGE_BOOST
	if currency_manager.spend_diamonds(cost):
		hero_damage_boost_level += 1
		save_prestige_data()
		return true
	return false

func purchase_coin_drop_boost(currency_manager: SpecialCurrencyManager) -> bool:
	var cost = GameConstants.PRESTIGE_COST_COIN_DROP_BOOST
	if currency_manager.spend_diamonds(cost):
		coin_drop_boost_level += 1
		save_prestige_data()
		return true
	return false

func purchase_starting_coins_boost(currency_manager: SpecialCurrencyManager) -> bool:
	var cost = GameConstants.PRESTIGE_COST_STARTING_COINS_BOOST
	if currency_manager.spend_diamonds(cost):
		starting_coins_boost_level += 1
		save_prestige_data()
		return true
	return false

func purchase_tower_arrow_corrosive(currency_manager: SpecialCurrencyManager) -> bool:
	if tower_arrow_corrosive_unlocked:
		return false
	if currency_manager.spend_diamonds(GameConstants.PRESTIGE_COST_TOWER_ARROW_CORROSIVE):
		tower_arrow_corrosive_unlocked = true
		save_prestige_data()
		return true
	return false

func purchase_slow_tower_frost(currency_manager: SpecialCurrencyManager) -> bool:
	if slow_tower_frost_unlocked:
		return false
	if currency_manager.spend_diamonds(GameConstants.PRESTIGE_COST_SLOW_TOWER_FROST):
		slow_tower_frost_unlocked = true
		save_prestige_data()
		return true
	return false

func purchase_aoe_tower_inferno(currency_manager: SpecialCurrencyManager) -> bool:
	if aoe_tower_inferno_unlocked:
		return false
	if currency_manager.spend_diamonds(GameConstants.PRESTIGE_COST_AOE_TOWER_INFERNO):
		aoe_tower_inferno_unlocked = true
		save_prestige_data()
		return true
	return false

func purchase_sniper_tower_pierce(currency_manager: SpecialCurrencyManager) -> bool:
	if sniper_tower_pierce_unlocked:
		return false
	if currency_manager.spend_diamonds(GameConstants.PRESTIGE_COST_SNIPER_TOWER_PIERCE):
		sniper_tower_pierce_unlocked = true
		save_prestige_data()
		return true
	return false

func purchase_shock_tower_chain(currency_manager: SpecialCurrencyManager) -> bool:
	if shock_tower_chain_unlocked:
		return false
	if currency_manager.spend_diamonds(GameConstants.PRESTIGE_COST_SHOCK_TOWER_CHAIN):
		shock_tower_chain_unlocked = true
		save_prestige_data()
		return true
	return false

func purchase_boost_tower_aura(currency_manager: SpecialCurrencyManager) -> bool:
	if boost_tower_aura_unlocked:
		return false
	if currency_manager.spend_diamonds(GameConstants.PRESTIGE_COST_BOOST_TOWER_AURA):
		boost_tower_aura_unlocked = true
		save_prestige_data()
		return true
	return false

func get_reward_multiplier() -> float:
	return 1.0 + (reward_multiplier_level * 0.1)

func get_base_hp_boost() -> float:
	return base_hp_boost_level * 20.0

func get_hero_damage_boost() -> float:
	return hero_damage_boost_level * 0.15

func get_coin_drop_boost() -> float:
	return coin_drop_boost_level * 0.03

func get_starting_coins_boost() -> int:
	return starting_coins_boost_level * 50

func has_tower_arrow_corrosive() -> bool:
	return tower_arrow_corrosive_unlocked

func has_slow_tower_frost() -> bool:
	return slow_tower_frost_unlocked

func has_aoe_tower_inferno() -> bool:
	return aoe_tower_inferno_unlocked

func has_sniper_tower_pierce() -> bool:
	return sniper_tower_pierce_unlocked

func has_shock_tower_chain() -> bool:
	return shock_tower_chain_unlocked

func get_boost_aura_effect_multiplier() -> float:
	return 1.5 if boost_tower_aura_unlocked else 1.0

func get_boost_aura_range_multiplier() -> float:
	return 1.25 if boost_tower_aura_unlocked else 1.0

func has_boost_tower_aura() -> bool:
	return boost_tower_aura_unlocked

func save_prestige_data():
	var config = ConfigFile.new()
	var config_path = "user://prestige_shop.cfg"
	config.load(config_path)
	config.set_value("diamond_upgrades", "prestige_resets", prestige_resets)
	config.set_value("diamond_upgrades", "reward_multiplier_level", reward_multiplier_level)
	config.set_value("diamond_upgrades", "base_hp_boost_level", base_hp_boost_level)
	config.set_value("diamond_upgrades", "hero_damage_boost_level", hero_damage_boost_level)
	config.set_value("diamond_upgrades", "coin_drop_boost_level", coin_drop_boost_level)
	config.set_value("diamond_upgrades", "starting_coins_boost_level", starting_coins_boost_level)
	config.set_value("diamond_upgrades", "tower_arrow_corrosive_unlocked", tower_arrow_corrosive_unlocked)
	config.set_value("diamond_upgrades", "slow_tower_frost_unlocked", slow_tower_frost_unlocked)
	config.set_value("diamond_upgrades", "aoe_tower_inferno_unlocked", aoe_tower_inferno_unlocked)
	config.set_value("diamond_upgrades", "sniper_tower_pierce_unlocked", sniper_tower_pierce_unlocked)
	config.set_value("diamond_upgrades", "shock_tower_chain_unlocked", shock_tower_chain_unlocked)
	config.set_value("diamond_upgrades", "boost_tower_aura_unlocked", boost_tower_aura_unlocked)
	config.save(config_path)

func load_prestige_data():
	var config = ConfigFile.new()
	var config_path = "user://prestige_shop.cfg"
	if config.load(config_path) == OK:
		prestige_resets = config.get_value("diamond_upgrades", "prestige_resets", 0)
		reward_multiplier_level = config.get_value("diamond_upgrades", "reward_multiplier_level", 0)
		base_hp_boost_level = config.get_value("diamond_upgrades", "base_hp_boost_level", 0)
		hero_damage_boost_level = config.get_value("diamond_upgrades", "hero_damage_boost_level", 0)
		coin_drop_boost_level = config.get_value("diamond_upgrades", "coin_drop_boost_level", 0)
		starting_coins_boost_level = config.get_value("diamond_upgrades", "starting_coins_boost_level", 0)
		tower_arrow_corrosive_unlocked = config.get_value("diamond_upgrades", "tower_arrow_corrosive_unlocked", false)
		slow_tower_frost_unlocked = config.get_value("diamond_upgrades", "slow_tower_frost_unlocked", false)
		aoe_tower_inferno_unlocked = config.get_value("diamond_upgrades", "aoe_tower_inferno_unlocked", false)
		sniper_tower_pierce_unlocked = config.get_value("diamond_upgrades", "sniper_tower_pierce_unlocked", false)
		shock_tower_chain_unlocked = config.get_value("diamond_upgrades", "shock_tower_chain_unlocked", false)
		boost_tower_aura_unlocked = config.get_value("diamond_upgrades", "boost_tower_aura_unlocked", false)

func get_all_upgrades_info() -> Dictionary:
	return {
		"diamond_upgrades": {
			"prestige_resets": prestige_resets,
			"reward_multiplier": reward_multiplier_level,
			"base_hp_boost": base_hp_boost_level,
			"hero_damage_boost": hero_damage_boost_level,
			"coin_drop_boost": coin_drop_boost_level,
			"starting_coins_boost": starting_coins_boost_level,
			"tower_arrow_corrosive": tower_arrow_corrosive_unlocked,
			"slow_tower_frost": slow_tower_frost_unlocked,
			"aoe_tower_inferno": aoe_tower_inferno_unlocked,
			"sniper_tower_pierce": sniper_tower_pierce_unlocked,
			"shock_tower_chain": shock_tower_chain_unlocked,
			"boost_tower_aura": boost_tower_aura_unlocked
		}
	}
