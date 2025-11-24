extends RefCounted
class_name GameConstants

# Grid
const TILE_SIZE := 28
const GRID_COLS := 33
const GRID_ROWS := 33

# Base
const BASE_SIZE_TILES := 7
const BASE_GRID_SIZE := 15

# Costs
const TOWER_COST := 10
const BARRACKS_COST := 20
const MINE_COST := 15
const SLOW_TOWER_COST := 25
const AOE_TOWER_COST := 30
const SNIPER_TOWER_COST := 70
const BOOST_TOWER_COST := 35
const SHOCK_TOWER_COST := 40
const WALL_COST := 10
const HEALING_STATION_COST := 50

# Sizes
const TOWER_SIZE_GRID := 3
const BARRACKS_SIZE_GRID := 3
const MINE_SIZE_GRID := 1
const SLOW_TOWER_SIZE_GRID := 3
const AOE_TOWER_SIZE_GRID := 3
const SNIPER_TOWER_SIZE_GRID := 3
const BOOST_TOWER_SIZE_GRID := 3
const SHOCK_TOWER_SIZE_GRID := 3
const WALL_SIZE_GRID := 1
const HEALING_STATION_SIZE_GRID := 3

# Limits
const MAX_TOWERS := 8
const MAX_BARRACKS := 2
const MAX_MINES := 10
const MAX_SLOW_TOWERS := 6
const MAX_AOE_TOWERS := 5
const MAX_SNIPER_TOWERS := 2
const MAX_BOOST_TOWERS := 4
const MAX_SHOCK_TOWERS := 4
const MAX_WALLS := 15
const MAX_HEALING_STATIONS := 2

# Tower upgrades
const TOWER_RANGE_COST := 8
const TOWER_RATE_COST := 8
const TOWER_DIRS_COST := 12
const TOWER_DMG_COST := 10
const TOWER_FREEZE_COST := 25
const TOWER_FIRE_COST := 25

# Barracks upgrades
const BARRACKS_DMG_COST := 15
const BARRACKS_HOLD_COST := 12
const BARRACKS_SPAWN_RATE_COST := 20
const BARRACKS_PROJECTILE_SPEED_COST := 18

# Sniper tower upgrades
const SNIPER_DMG_COST := 30
const SNIPER_RATE_COST := 12

# AOE tower upgrades
const AOE_DMG_COST := 15
const AOE_RATE_COST := 12
const AOE_AREA_COST := 20

# Shock tower upgrades
const SHOCK_DMG_COST := 15
const SHOCK_RATE_COST := 12
const SHOCK_CHAIN_COST := 20

# Waves
const WAVE_SCALE := 1.1
const INTERMISSION := 2.0

# Enemy stats
const ENEMY_BASE_SPEED := 30.0
const BOSS_SPEED_MULTIPLIER := 0.8
const ENEMY_BASE_HP := 2
const BOSS_BASE_HP := 50
const BOSS_REWARD_MULTIPLIER := 20
const NORMAL_REWARD := 2

# Hero
const HERO_START_COINS := 100
const HERO_BASE_FIRE_RATE := 0.35
const HERO_BASE_DAMAGE := 1

# Coin drops
const COIN_DROP_CHANCE := 0.3  # 30% de chance de dropar moeda
const COIN_MIN_VALUE := 5
const COIN_MAX_VALUE := 20
const COIN_LIFETIME := 10.0  # tempo que a moeda fica no chão antes de desaparecer

