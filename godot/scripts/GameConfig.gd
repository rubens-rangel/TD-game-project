extends Node
## Configuração de jogo em tempo de execução.
## Modo normal: usa sempre os valores de GameConstants.
## Modo personalizado: usa _config (cópia dos defaults + overrides da UI).

const GameConstants = preload("res://scripts/Constants.gd")

var use_custom: bool = false
var _config: Dictionary = {}
var _defaults: Dictionary = {}

func _ready() -> void:
	_build_defaults()

func _build_defaults() -> void:
	_defaults["TILE_SIZE"] = GameConstants.TILE_SIZE
	_defaults["GRID_COLS"] = GameConstants.GRID_COLS
	_defaults["GRID_ROWS"] = GameConstants.GRID_ROWS
	_defaults["BASE_SIZE_TILES"] = GameConstants.BASE_SIZE_TILES
	_defaults["BASE_GRID_SIZE"] = GameConstants.BASE_GRID_SIZE
	_defaults["TOWER_COST"] = GameConstants.TOWER_COST
	_defaults["BARRACKS_COST"] = GameConstants.BARRACKS_COST
	_defaults["MINE_COST"] = GameConstants.MINE_COST
	_defaults["SLOW_TOWER_COST"] = GameConstants.SLOW_TOWER_COST
	_defaults["AOE_TOWER_COST"] = GameConstants.AOE_TOWER_COST
	_defaults["SNIPER_TOWER_COST"] = GameConstants.SNIPER_TOWER_COST
	_defaults["BOOST_TOWER_COST"] = GameConstants.BOOST_TOWER_COST
	_defaults["SHOCK_TOWER_COST"] = GameConstants.SHOCK_TOWER_COST
	_defaults["ANTI_AIR_TOWER_COST"] = GameConstants.ANTI_AIR_TOWER_COST
	_defaults["WALL_COST"] = GameConstants.WALL_COST
	_defaults["HEALING_STATION_COST"] = GameConstants.HEALING_STATION_COST
	_defaults["MARKET_COST_EMERALDS"] = GameConstants.MARKET_COST_EMERALDS
	_defaults["BOOST_TOWER_RANGE"] = GameConstants.BOOST_TOWER_RANGE
	_defaults["UNLOCK_WAVE_TOWER"] = GameConstants.UNLOCK_WAVE_TOWER
	_defaults["UNLOCK_WAVE_BARRACKS"] = GameConstants.UNLOCK_WAVE_BARRACKS
	_defaults["UNLOCK_WAVE_MINE"] = GameConstants.UNLOCK_WAVE_MINE
	_defaults["UNLOCK_WAVE_AOE"] = GameConstants.UNLOCK_WAVE_AOE
	_defaults["UNLOCK_WAVE_WALL"] = GameConstants.UNLOCK_WAVE_WALL
	_defaults["UNLOCK_WAVE_SHOCK"] = GameConstants.UNLOCK_WAVE_SHOCK
	_defaults["UNLOCK_WAVE_SNIPER"] = GameConstants.UNLOCK_WAVE_SNIPER
	_defaults["UNLOCK_WAVE_BOOST"] = GameConstants.UNLOCK_WAVE_BOOST
	_defaults["UNLOCK_WAVE_HEALING_STATION"] = GameConstants.UNLOCK_WAVE_HEALING_STATION
	_defaults["UNLOCK_WAVE_SLOW"] = GameConstants.UNLOCK_WAVE_SLOW
	_defaults["UNLOCK_WAVE_ANTI_AIR"] = GameConstants.UNLOCK_WAVE_ANTI_AIR
	_defaults["UNLOCK_WAVE_MARKET"] = GameConstants.UNLOCK_WAVE_MARKET
	_defaults["MINE_DAMAGE"] = GameConstants.MINE_DAMAGE
	_defaults["MINE_TRIGGER_RADIUS"] = GameConstants.MINE_TRIGGER_RADIUS
	_defaults["MINE_EXPLOSION_RADIUS"] = GameConstants.MINE_EXPLOSION_RADIUS
	_defaults["MINE_SLOW_DURATION"] = GameConstants.MINE_SLOW_DURATION
	_defaults["MINE_SLOW_AMOUNT"] = GameConstants.MINE_SLOW_AMOUNT
	_defaults["MINE_UPGRADE_DAMAGE_COST"] = GameConstants.MINE_UPGRADE_DAMAGE_COST
	_defaults["MINE_UPGRADE_DAMAGE_AMOUNT"] = GameConstants.MINE_UPGRADE_DAMAGE_AMOUNT
	_defaults["MINE_UPGRADE_DAMAGE_MAX_LEVEL"] = GameConstants.MINE_UPGRADE_DAMAGE_MAX_LEVEL
	_defaults["MINE_UPGRADE_RADIUS_COST"] = GameConstants.MINE_UPGRADE_RADIUS_COST
	_defaults["MINE_UPGRADE_RADIUS_AMOUNT"] = GameConstants.MINE_UPGRADE_RADIUS_AMOUNT
	_defaults["MINE_UPGRADE_RADIUS_MAX_LEVEL"] = GameConstants.MINE_UPGRADE_RADIUS_MAX_LEVEL
	_defaults["TOWER_SIZE_GRID"] = GameConstants.TOWER_SIZE_GRID
	_defaults["BARRACKS_SIZE_GRID"] = GameConstants.BARRACKS_SIZE_GRID
	_defaults["MINE_SIZE_GRID"] = GameConstants.MINE_SIZE_GRID
	_defaults["SLOW_TOWER_SIZE_GRID"] = GameConstants.SLOW_TOWER_SIZE_GRID
	_defaults["AOE_TOWER_SIZE_GRID"] = GameConstants.AOE_TOWER_SIZE_GRID
	_defaults["SNIPER_TOWER_SIZE_GRID"] = GameConstants.SNIPER_TOWER_SIZE_GRID
	_defaults["BOOST_TOWER_SIZE_GRID"] = GameConstants.BOOST_TOWER_SIZE_GRID
	_defaults["SHOCK_TOWER_SIZE_GRID"] = GameConstants.SHOCK_TOWER_SIZE_GRID
	_defaults["ANTI_AIR_TOWER_SIZE_GRID"] = GameConstants.ANTI_AIR_TOWER_SIZE_GRID
	_defaults["WALL_SIZE_GRID"] = GameConstants.WALL_SIZE_GRID
	_defaults["HEALING_STATION_SIZE_GRID"] = GameConstants.HEALING_STATION_SIZE_GRID
	_defaults["MARKET_SIZE_GRID"] = GameConstants.MARKET_SIZE_GRID
	_defaults["MAX_TOWERS"] = GameConstants.MAX_TOWERS
	_defaults["MAX_BARRACKS"] = GameConstants.MAX_BARRACKS
	_defaults["MAX_MINES"] = GameConstants.MAX_MINES
	_defaults["MAX_SLOW_TOWERS"] = GameConstants.MAX_SLOW_TOWERS
	_defaults["MAX_AOE_TOWERS"] = GameConstants.MAX_AOE_TOWERS
	_defaults["MAX_SNIPER_TOWERS"] = GameConstants.MAX_SNIPER_TOWERS
	_defaults["MAX_BOOST_TOWERS"] = GameConstants.MAX_BOOST_TOWERS
	_defaults["MAX_SHOCK_TOWERS"] = GameConstants.MAX_SHOCK_TOWERS
	_defaults["MAX_ANTI_AIR_TOWERS"] = GameConstants.MAX_ANTI_AIR_TOWERS
	_defaults["MAX_WALLS"] = GameConstants.MAX_WALLS
	_defaults["MAX_HEALING_STATIONS"] = GameConstants.MAX_HEALING_STATIONS
	_defaults["MAX_MARKETS"] = GameConstants.MAX_MARKETS
	_defaults["TOWER_RANGE_COST"] = GameConstants.TOWER_RANGE_COST
	_defaults["TOWER_RATE_COST"] = GameConstants.TOWER_RATE_COST
	_defaults["TOWER_DIRS_COST"] = GameConstants.TOWER_DIRS_COST
	_defaults["TOWER_DMG_COST"] = GameConstants.TOWER_DMG_COST
	_defaults["TOWER_FREEZE_COST"] = GameConstants.TOWER_FREEZE_COST
	_defaults["TOWER_FIRE_COST"] = GameConstants.TOWER_FIRE_COST
	_defaults["TOWER_FREEZE_DURATION"] = GameConstants.TOWER_FREEZE_DURATION
	_defaults["TOWER_FREEZE_SLOW_PERCENT"] = GameConstants.TOWER_FREEZE_SLOW_PERCENT
	_defaults["TOWER_FIRE_DAMAGE_MULTIPLIER"] = GameConstants.TOWER_FIRE_DAMAGE_MULTIPLIER
	_defaults["TOWER_FIRE_DURATION"] = GameConstants.TOWER_FIRE_DURATION
	_defaults["TOWER_DMG_UPGRADE_AMOUNT"] = GameConstants.TOWER_DMG_UPGRADE_AMOUNT
	_defaults["BARRACKS_DMG_COST"] = GameConstants.BARRACKS_DMG_COST
	_defaults["BARRACKS_HOLD_COST"] = GameConstants.BARRACKS_HOLD_COST
	_defaults["BARRACKS_SPAWN_RATE_COST"] = GameConstants.BARRACKS_SPAWN_RATE_COST
	_defaults["BARRACKS_PROJECTILE_SPEED_COST"] = GameConstants.BARRACKS_PROJECTILE_SPEED_COST
	_defaults["SNIPER_DMG_COST"] = GameConstants.SNIPER_DMG_COST
	_defaults["SNIPER_RATE_COST"] = GameConstants.SNIPER_RATE_COST
	_defaults["AOE_DMG_COST"] = GameConstants.AOE_DMG_COST
	_defaults["AOE_RATE_COST"] = GameConstants.AOE_RATE_COST
	_defaults["AOE_AREA_COST"] = GameConstants.AOE_AREA_COST
	_defaults["AOE_AREA_COST_MULTIPLIER"] = GameConstants.AOE_AREA_COST_MULTIPLIER
	_defaults["SHOCK_DMG_COST"] = GameConstants.SHOCK_DMG_COST
	_defaults["SHOCK_RATE_COST"] = GameConstants.SHOCK_RATE_COST
	_defaults["SHOCK_CHAIN_COST"] = GameConstants.SHOCK_CHAIN_COST
	_defaults["SHOCK_CHAIN_COST_MULTIPLIER"] = GameConstants.SHOCK_CHAIN_COST_MULTIPLIER
	_defaults["SLOW_RANGE_COST"] = GameConstants.SLOW_RANGE_COST
	_defaults["SLOW_AMOUNT_COST"] = GameConstants.SLOW_AMOUNT_COST
	_defaults["SLOW_DURATION_COST"] = GameConstants.SLOW_DURATION_COST
	_defaults["SLOW_RATE_COST"] = GameConstants.SLOW_RATE_COST
	_defaults["BOOST_DMG_COST"] = GameConstants.BOOST_DMG_COST
	_defaults["BOOST_RATE_COST"] = GameConstants.BOOST_RATE_COST
	_defaults["ANTI_AIR_DMG_COST"] = GameConstants.ANTI_AIR_DMG_COST
	_defaults["ANTI_AIR_RATE_COST"] = GameConstants.ANTI_AIR_RATE_COST
	_defaults["ANTI_AIR_RANGE_COST"] = GameConstants.ANTI_AIR_RANGE_COST
	_defaults["ANTI_AIR_MISSILE_COUNT_COST"] = GameConstants.ANTI_AIR_MISSILE_COUNT_COST
	_defaults["ANTI_AIR_EXPLOSION_COST"] = GameConstants.ANTI_AIR_EXPLOSION_COST
	_defaults["ANTI_AIR_CHAIN_COST"] = GameConstants.ANTI_AIR_CHAIN_COST
	_defaults["ANTI_AIR_MISSILE_EMERALD_COST"] = GameConstants.ANTI_AIR_MISSILE_EMERALD_COST
	_defaults["ANTI_AIR_EXPLOSION_EMERALD_COST"] = GameConstants.ANTI_AIR_EXPLOSION_EMERALD_COST
	_defaults["WAVE_SCALE"] = GameConstants.WAVE_SCALE
	_defaults["INTERMISSION"] = GameConstants.INTERMISSION
	_defaults["REWARD_SCALE"] = GameConstants.REWARD_SCALE
	_defaults["REWARD_SCALE_SOFT_CAP"] = GameConstants.REWARD_SCALE_SOFT_CAP
	_defaults["REWARD_SCALE_AFTER_CAP"] = GameConstants.REWARD_SCALE_AFTER_CAP
	_defaults["UPGRADE_COST_MULTIPLIER"] = GameConstants.UPGRADE_COST_MULTIPLIER
	_defaults["WAVE_COMPLETION_BONUS_BASE"] = GameConstants.WAVE_COMPLETION_BONUS_BASE
	_defaults["WAVE_COMPLETION_BONUS_PER_WAVE"] = GameConstants.WAVE_COMPLETION_BONUS_PER_WAVE
	_defaults["WAVE_COMPLETION_BONUS_MAX"] = GameConstants.WAVE_COMPLETION_BONUS_MAX
	_defaults["HERO_START_COINS"] = GameConstants.HERO_START_COINS
	_defaults["HERO_BASE_FIRE_RATE"] = GameConstants.HERO_BASE_FIRE_RATE
	_defaults["HERO_BASE_DAMAGE"] = GameConstants.HERO_BASE_DAMAGE
	_defaults["TOWER_BASE_DAMAGE"] = GameConstants.TOWER_BASE_DAMAGE
	_defaults["COIN_DROP_CHANCE"] = GameConstants.COIN_DROP_CHANCE
	_defaults["COIN_MIN_VALUE"] = GameConstants.COIN_MIN_VALUE
	_defaults["COIN_MAX_VALUE"] = GameConstants.COIN_MAX_VALUE
	_defaults["COIN_LIFETIME"] = GameConstants.COIN_LIFETIME
	_defaults["TALISMAN_DROP_CHANCE"] = GameConstants.TALISMAN_DROP_CHANCE
	_defaults["TALISMAN_LIFETIME"] = GameConstants.TALISMAN_LIFETIME
	_defaults["TALISMAN_COLLECT_RADIUS"] = GameConstants.TALISMAN_COLLECT_RADIUS
	_defaults["SKILL_COLLECT_COINS_COST"] = GameConstants.SKILL_COLLECT_COINS_COST
	_defaults["SKILL_DAMAGE_BOOST_COST"] = GameConstants.SKILL_DAMAGE_BOOST_COST
	_defaults["SKILL_SPEED_BOOST_COST"] = GameConstants.SKILL_SPEED_BOOST_COST
	_defaults["SKILL_SLOW_ALL_COST"] = GameConstants.SKILL_SLOW_ALL_COST
	_defaults["SKILL_DAMAGE_BOOST_DURATION"] = GameConstants.SKILL_DAMAGE_BOOST_DURATION
	_defaults["SKILL_SPEED_BOOST_DURATION"] = GameConstants.SKILL_SPEED_BOOST_DURATION
	_defaults["SKILL_SLOW_ALL_DURATION"] = GameConstants.SKILL_SLOW_ALL_DURATION
	_defaults["SKILL_SLOW_ALL_AMOUNT"] = GameConstants.SKILL_SLOW_ALL_AMOUNT
	_defaults["SKILL_DAMAGE_BOOST_MULTIPLIER"] = GameConstants.SKILL_DAMAGE_BOOST_MULTIPLIER
	_defaults["SKILL_SPEED_BOOST_MULTIPLIER"] = GameConstants.SKILL_SPEED_BOOST_MULTIPLIER
	_defaults["SKILL_COLLECT_COINS_COOLDOWN"] = GameConstants.SKILL_COLLECT_COINS_COOLDOWN
	_defaults["SKILL_DAMAGE_BOOST_COOLDOWN"] = GameConstants.SKILL_DAMAGE_BOOST_COOLDOWN
	_defaults["SKILL_SPEED_BOOST_COOLDOWN"] = GameConstants.SKILL_SPEED_BOOST_COOLDOWN
	_defaults["SKILL_SLOW_ALL_COOLDOWN"] = GameConstants.SKILL_SLOW_ALL_COOLDOWN
	_defaults["SKILL_MAGNETISM_COOLDOWN"] = GameConstants.SKILL_MAGNETISM_COOLDOWN
	_defaults["SKILL_MAGNETISM_DURATION"] = GameConstants.SKILL_MAGNETISM_DURATION
	_defaults["COIN_MAGNETISM_RANGE"] = GameConstants.COIN_MAGNETISM_RANGE
	_defaults["HERO_ARROW_SPEED"] = GameConstants.HERO_ARROW_SPEED
	_defaults["HERO_BASE_HP"] = GameConstants.HERO_BASE_HP
	_defaults["HERO_HOME_MAX_LEVEL"] = GameConstants.HERO_HOME_MAX_LEVEL
	_defaults["HERO_HOME_UPGRADE_COST_LEVEL_2"] = GameConstants.HERO_HOME_UPGRADE_COST_LEVEL_2
	_defaults["HERO_HOME_UPGRADE_COST_LEVEL_3"] = GameConstants.HERO_HOME_UPGRADE_COST_LEVEL_3
	_defaults["HERO_HOME_UPGRADE_COST_LEVEL_4"] = GameConstants.HERO_HOME_UPGRADE_COST_LEVEL_4
	_defaults["HERO_CRIT_MULTIPLIER_BASE"] = GameConstants.HERO_CRIT_MULTIPLIER_BASE
	_defaults["TOWER_CRIT_CHANCE_BASE"] = GameConstants.TOWER_CRIT_CHANCE_BASE
	_defaults["TOWER_CRIT_MULTIPLIER_BASE"] = GameConstants.TOWER_CRIT_MULTIPLIER_BASE
	_defaults["HERO_RANGE_MAX"] = GameConstants.HERO_RANGE_MAX
	_defaults["WALL_COST_1ST"] = GameConstants.WALL_COST_1ST
	_defaults["WALL_COST_2ND"] = GameConstants.WALL_COST_2ND
	_defaults["WALL_COST_3RD"] = GameConstants.WALL_COST_3RD
	_defaults["WALL_COST_4TH"] = GameConstants.WALL_COST_4TH
	_defaults["WALL_BASE_HP"] = GameConstants.WALL_BASE_HP
	_defaults["WALL_DAMAGE_RADIUS"] = GameConstants.WALL_DAMAGE_RADIUS
	_defaults["WALL_DAMAGE_PER_SECOND"] = GameConstants.WALL_DAMAGE_PER_SECOND
	_defaults["WALL_BOSS_DAMAGE_MULTIPLIER"] = GameConstants.WALL_BOSS_DAMAGE_MULTIPLIER
	_defaults["WALL_UPGRADE_HP_COST"] = GameConstants.WALL_UPGRADE_HP_COST
	_defaults["WALL_UPGRADE_HP_AMOUNT"] = GameConstants.WALL_UPGRADE_HP_AMOUNT
	_defaults["WALL_MAX_UPGRADES"] = GameConstants.WALL_MAX_UPGRADES
	_defaults["TOWER_COST_SCALE_PER_WAVE"] = GameConstants.TOWER_COST_SCALE_PER_WAVE
	_defaults["TOWER_MIN_FIRE_RATE"] = GameConstants.TOWER_MIN_FIRE_RATE
	_defaults["SNIPER_MIN_FIRE_RATE"] = GameConstants.SNIPER_MIN_FIRE_RATE
	_defaults["AOE_MIN_FIRE_RATE"] = GameConstants.AOE_MIN_FIRE_RATE
	_defaults["SHOCK_MIN_FIRE_RATE"] = GameConstants.SHOCK_MIN_FIRE_RATE
	_defaults["ANTI_AIR_MIN_FIRE_RATE"] = GameConstants.ANTI_AIR_MIN_FIRE_RATE
	_defaults["HERO_MIN_FIRE_RATE"] = GameConstants.HERO_MIN_FIRE_RATE
	_defaults["BONUS_MIN_FIRE_RATE"] = GameConstants.BONUS_MIN_FIRE_RATE
	_defaults["SHOCK_MAX_CHAIN_COUNT"] = GameConstants.SHOCK_MAX_CHAIN_COUNT
	_defaults["AOE_MAX_RADIUS"] = GameConstants.AOE_MAX_RADIUS
	_defaults["ANTI_AIR_MAX_RANGE"] = GameConstants.ANTI_AIR_MAX_RANGE
	_defaults["TOWER_FIRE_RATE_REDUCTION"] = GameConstants.TOWER_FIRE_RATE_REDUCTION
	_defaults["SNIPER_FIRE_RATE_REDUCTION"] = GameConstants.SNIPER_FIRE_RATE_REDUCTION
	_defaults["AOE_FIRE_RATE_REDUCTION"] = GameConstants.AOE_FIRE_RATE_REDUCTION
	_defaults["SHOCK_FIRE_RATE_REDUCTION"] = GameConstants.SHOCK_FIRE_RATE_REDUCTION
	_defaults["ANTI_AIR_FIRE_RATE_REDUCTION"] = GameConstants.ANTI_AIR_FIRE_RATE_REDUCTION
	_defaults["HERO_FIRE_RATE_REDUCTION"] = GameConstants.HERO_FIRE_RATE_REDUCTION
	_defaults["BASE_MAX_HP"] = GameConstants.BASE_MAX_HP
	_defaults["QUEST_DAILY_COUNT"] = GameConstants.QUEST_DAILY_COUNT
	_defaults["QUEST_WEEKLY_COUNT"] = GameConstants.QUEST_WEEKLY_COUNT
	_defaults["QUEST_MONTHLY_COUNT"] = GameConstants.QUEST_MONTHLY_COUNT
	_defaults["QUEST_REWARD_DAILY_POINTS"] = GameConstants.QUEST_REWARD_DAILY_POINTS
	_defaults["QUEST_REWARD_WEEKLY_POINTS"] = GameConstants.QUEST_REWARD_WEEKLY_POINTS
	_defaults["QUEST_REWARD_MONTHLY_POINTS"] = GameConstants.QUEST_REWARD_MONTHLY_POINTS
	_defaults["QUEST_REWARD_MONTHLY_DIAMONDS"] = GameConstants.QUEST_REWARD_MONTHLY_DIAMONDS
	_defaults["EMERALD_VALUE_IN_COINS"] = GameConstants.EMERALD_VALUE_IN_COINS
	_defaults["EMERALD_DROP_START_WAVE"] = GameConstants.EMERALD_DROP_START_WAVE
	_defaults["EMERALD_DROP_CHANCE"] = GameConstants.EMERALD_DROP_CHANCE
	_defaults["DIAMOND_DROP_START_WAVE"] = GameConstants.DIAMOND_DROP_START_WAVE
	_defaults["DIAMOND_DROP_CHANCE"] = GameConstants.DIAMOND_DROP_CHANCE
	_defaults["BOSS_EMERALD_REWARD_WAVE"] = GameConstants.BOSS_EMERALD_REWARD_WAVE
	_defaults["BOSS_EMERALD_REWARD_COUNT"] = GameConstants.BOSS_EMERALD_REWARD_COUNT
	_defaults["TOWER_UPGRADE_EMERALD_BASE_COST"] = GameConstants.TOWER_UPGRADE_EMERALD_BASE_COST
	_defaults["TOWER_UPGRADE_EMERALD_SCALE"] = GameConstants.TOWER_UPGRADE_EMERALD_SCALE
	_defaults["PRESTIGE_COST_REWARD_MULTIPLIER"] = GameConstants.PRESTIGE_COST_REWARD_MULTIPLIER
	_defaults["PRESTIGE_COST_BASE_HP_BOOST"] = GameConstants.PRESTIGE_COST_BASE_HP_BOOST
	_defaults["PRESTIGE_COST_HERO_DAMAGE_BOOST"] = GameConstants.PRESTIGE_COST_HERO_DAMAGE_BOOST
	_defaults["PRESTIGE_COST_COIN_DROP_BOOST"] = GameConstants.PRESTIGE_COST_COIN_DROP_BOOST
	_defaults["PRESTIGE_COST_STARTING_COINS_BOOST"] = GameConstants.PRESTIGE_COST_STARTING_COINS_BOOST
	_defaults["BARRACKS_INITIAL_SPAWN_RATE"] = GameConstants.BARRACKS_INITIAL_SPAWN_RATE
	_defaults["BARRACKS_MIN_SPAWN_RATE"] = GameConstants.BARRACKS_MIN_SPAWN_RATE
	_defaults["BARRACKS_SPAWN_RATE_REDUCTION"] = GameConstants.BARRACKS_SPAWN_RATE_REDUCTION
	_defaults["BARRACKS_INITIAL_HOLD_TIME"] = GameConstants.BARRACKS_INITIAL_HOLD_TIME
	_defaults["BARRACKS_HOLD_TIME_INCREASE"] = GameConstants.BARRACKS_HOLD_TIME_INCREASE
	_defaults["BARRACKS_MAX_HOLD_TIME"] = GameConstants.BARRACKS_MAX_HOLD_TIME
	_defaults["BARRACKS_INITIAL_SOLDIER_DAMAGE"] = GameConstants.BARRACKS_INITIAL_SOLDIER_DAMAGE
	_defaults["BARRACKS_INITIAL_PROJECTILE_SPEED"] = GameConstants.BARRACKS_INITIAL_PROJECTILE_SPEED
	_defaults["BARRACKS_PROJECTILE_SPEED_INCREASE"] = GameConstants.BARRACKS_PROJECTILE_SPEED_INCREASE
	_defaults["BARRACKS_SOLDIER_DAMAGE_INCREASE"] = GameConstants.BARRACKS_SOLDIER_DAMAGE_INCREASE
	_defaults["SPECIAL_WAVE_INTERVAL"] = GameConstants.SPECIAL_WAVE_INTERVAL
	_defaults["SPECIAL_WAVE_ALERT_DURATION"] = GameConstants.SPECIAL_WAVE_ALERT_DURATION
	_defaults["SPECIAL_WAVE_ALERT_FADE_OUT_START"] = GameConstants.SPECIAL_WAVE_ALERT_FADE_OUT_START
	_defaults["BOSS_ALERT_DURATION"] = GameConstants.BOSS_ALERT_DURATION
	_defaults["WEATHER_CHANGE_INTERVAL"] = GameConstants.WEATHER_CHANGE_INTERVAL
	_defaults["WEATHER_DURATION_WAVES"] = GameConstants.WEATHER_DURATION_WAVES
	_defaults["WEATHER_RAIN_TOWER_DAMAGE_REDUCTION"] = GameConstants.WEATHER_RAIN_TOWER_DAMAGE_REDUCTION
	_defaults["WEATHER_RAIN_TOWER_RANGE_REDUCTION"] = GameConstants.WEATHER_RAIN_TOWER_RANGE_REDUCTION
	_defaults["WEATHER_HEAT_ENEMY_SPEED_BOOST"] = GameConstants.WEATHER_HEAT_ENEMY_SPEED_BOOST
	_defaults["WEATHER_HEAT_ENEMY_HP_BOOST"] = GameConstants.WEATHER_HEAT_ENEMY_HP_BOOST
	_defaults["WEATHER_FOG_VISIBILITY_REDUCTION"] = GameConstants.WEATHER_FOG_VISIBILITY_REDUCTION
	_defaults["WEATHER_NIGHT_VISIBILITY_REDUCTION"] = GameConstants.WEATHER_NIGHT_VISIBILITY_REDUCTION
	_defaults["WEATHER_NIGHT_ENEMY_SPEED_BOOST"] = GameConstants.WEATHER_NIGHT_ENEMY_SPEED_BOOST
	_defaults["MARKET_ITEM_HEAL_FULL"] = GameConstants.MARKET_ITEM_HEAL_FULL
	_defaults["MARKET_ITEM_TOWER_DAMAGE_BOOST"] = GameConstants.MARKET_ITEM_TOWER_DAMAGE_BOOST
	_defaults["MARKET_ITEM_HERO_DAMAGE_BOOST"] = GameConstants.MARKET_ITEM_HERO_DAMAGE_BOOST
	_defaults["MARKET_ITEM_EXTRA_LIFE"] = GameConstants.MARKET_ITEM_EXTRA_LIFE
	_defaults["MARKET_ITEM_HERO_FIRERATE_UPGRADE"] = GameConstants.MARKET_ITEM_HERO_FIRERATE_UPGRADE
	_defaults["MARKET_ITEM_HERO_DUAL_CANNON"] = GameConstants.MARKET_ITEM_HERO_DUAL_CANNON

func start_normal_mode() -> void:
	use_custom = false
	_config.clear()

func start_custom_mode() -> void:
	use_custom = true
	_config = _defaults.duplicate(true)

func set_override(key: StringName, value: Variant) -> void:
	if use_custom:
		_config[key] = value

func get_default(key: StringName) -> Variant:
	return _defaults.get(key, null)

func get_value(key: StringName) -> Variant:
	if use_custom and _config.has(key):
		return _config[key]
	if _defaults.has(key):
		return _defaults[key]
	return null

func get_int(key: StringName) -> int:
	return int(get_value(key))

func get_float(key: StringName) -> float:
	return float(get_value(key))
