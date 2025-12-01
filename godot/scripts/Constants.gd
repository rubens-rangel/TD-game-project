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
const MINE_COST := 10
const SLOW_TOWER_COST := 80
const AOE_TOWER_COST := 30
const SNIPER_TOWER_COST := 70
const BOOST_TOWER_COST := 100  # Aumentado de 80 para 100
const SHOCK_TOWER_COST := 40
const WALL_COST := 50
const HEALING_STATION_COST := 50

const MINE_DAMAGE := 15.0  # Dano alto
const MINE_TRIGGER_RADIUS := 18.0
const MINE_EXPLOSION_RADIUS := 60.0
const MINE_SLOW_DURATION := 1.5
const MINE_SLOW_AMOUNT := 0.4

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
const MAX_TOWERS := 4
const MAX_BARRACKS := 2
const MAX_MINES := 8
const MAX_SLOW_TOWERS := 1
const MAX_AOE_TOWERS := 5
const MAX_SNIPER_TOWERS := 2
const MAX_BOOST_TOWERS := 1
const MAX_SHOCK_TOWERS := 4
const MAX_WALLS := 4
const MAX_HEALING_STATIONS := 2

# Tower upgrades
const TOWER_RANGE_COST := 15
const TOWER_RATE_COST := 10
const TOWER_DIRS_COST := 40
const TOWER_DMG_COST := 10
const TOWER_FREEZE_COST := 40  # Aumentado de 25 para 40
const TOWER_FIRE_COST := 40  # Aumentado de 25 para 40

# Barracks upgrades
const BARRACKS_DMG_COST := 15
const BARRACKS_HOLD_COST := 30
const BARRACKS_SPAWN_RATE_COST := 30  # Aumentado de 20 para 30 (50% mais caro)
const BARRACKS_PROJECTILE_SPEED_COST := 20

# Sniper tower upgrades
const SNIPER_DMG_COST := 30
const SNIPER_RATE_COST := 12

# AOE tower upgrades
const AOE_DMG_COST := 15
const AOE_RATE_COST := 20
const AOE_AREA_COST := 20

# Shock tower upgrades
const SHOCK_DMG_COST := 15
const SHOCK_RATE_COST := 25
const SHOCK_CHAIN_COST := 20

# Slow tower upgrades
const SLOW_RANGE_COST := 30  # Aumentado de 15 para 25 para balancear
const SLOW_AMOUNT_COST := 40
const SLOW_DURATION_COST := 20
const SLOW_RATE_COST := 15

# Boost tower upgrades
const BOOST_DMG_COST := 50  # Aumentado de 40 para 50
const BOOST_RATE_COST := 40  # Aumentado de 30 para 40

# Waves
const WAVE_SCALE := 1.04  # Reduzido de 1.06 para 1.04 - crescimento mais suave
const INTERMISSION := 8.0  # Aumentado de 5.0 para 8.0 para dar mais tempo entre waves

# Enemy stats
const ENEMY_BASE_SPEED := 38.0  # Aumentado de 30.0 para 38.0 (~27% mais rápido)
const BOSS_SPEED_MULTIPLIER := 0.5
const ENEMY_BASE_HP := 3  # Aumentado de 2 para 3 para aumentar dificuldade inicial
const BOSS_BASE_HP := 28  # Reduzido de 35 para 28 (~20% menos) para melhor balanceamento
const BOSS_REWARD_MULTIPLIER := 20
const NORMAL_REWARD := 2

# Balanceamento: Escala de recompensas e upgrades
const REWARD_SCALE := 1.03  # Recompensas crescem 2% por wave (reduzido de 1.05 para balancear níveis altos)
const REWARD_SCALE_SOFT_CAP := 50  # A partir da wave 30, a escala diminui ainda mais
const REWARD_SCALE_AFTER_CAP := 1.02  # Após o soft cap, cresce apenas 2% por wave
const UPGRADE_COST_MULTIPLIER := 1.15  # Upgrades ficam 15% mais caros por nível (aumentado de 1.12)
const WAVE_COMPLETION_BONUS_BASE := 10
const WAVE_COMPLETION_BONUS_PER_WAVE := 1  # Reduzido de 2 para 1 (crescimento mais lento)
const WAVE_COMPLETION_BONUS_MAX := 100  # Cap máximo de bônus por wave (evita valores muito altos)

# Hero
const HERO_START_COINS := 0
const HERO_BASE_FIRE_RATE := 1.0  # Aumentado de 0.8 para 1.0 (mais lento) para balancear
const HERO_BASE_DAMAGE := 0.8  # Reduzido de 1 para 0.8 para balancear dano da base

# Coin drops
const COIN_DROP_CHANCE := 0.10  # 10% de chance base de dropar moeda
const COIN_MIN_VALUE := 3
const COIN_MAX_VALUE := 20
const COIN_LIFETIME := 12.0  # tempo que a moeda fica no chão antes de desaparecer

# Skills
const SKILL_COLLECT_COINS_COST := 0  # Gratuita
const SKILL_DAMAGE_BOOST_COST := 0  # Gratuita (cooldown apenas)
const SKILL_SPEED_BOOST_COST := 0  # Gratuita (cooldown apenas)
const SKILL_SLOW_ALL_COST := 0  # Gratuita (cooldown apenas)
const SKILL_DAMAGE_BOOST_DURATION := 10.0  # segundos
const SKILL_SPEED_BOOST_DURATION := 8.0  # segundos
const SKILL_SLOW_ALL_DURATION := 5.0  # segundos
const SKILL_SLOW_ALL_AMOUNT := 0.5  # 50% de slow (velocidade reduzida pela metade)
const SKILL_DAMAGE_BOOST_MULTIPLIER := 1.5  # +50% de dano
const SKILL_SPEED_BOOST_MULTIPLIER := 1.3  # +30% de velocidade
const SKILL_COLLECT_COINS_COOLDOWN := 60.0  # segundos de cooldown
const SKILL_DAMAGE_BOOST_COOLDOWN := 60.0  # segundos de cooldown
const SKILL_SPEED_BOOST_COOLDOWN := 60.0  # segundos de cooldown
const SKILL_SLOW_ALL_COOLDOWN := 60.0  # segundos de cooldown
const SKILL_MAGNETISM_COOLDOWN := 45.0  # segundos de cooldown
const SKILL_MAGNETISM_DURATION := 30.0  # segundos de duração
const COIN_MAGNETISM_RANGE := 20.0  # Raio de coleta automática de moedas

# Hero
const HERO_ARROW_SPEED := 260.0
const HERO_BASE_HP := 100
const HERO_HOME_MAX_LEVEL := 3
const HERO_HOME_UPGRADE_COST_LEVEL_2 := 1200
const HERO_HOME_UPGRADE_COST_LEVEL_3 := 3000
const HERO_CRIT_MULTIPLIER_BASE := 2.0
const HERO_RANGE_MAX := 9999.0

# UI Colors
const COLOR_UI_WHITE := Color(1.0, 1.0, 1.0)
const COLOR_UI_GOLD := Color(1.0, 0.9, 0.3)
const COLOR_UI_RED := Color(1.0, 0.3, 0.3)
const COLOR_UI_GRAY := Color(0.7, 0.7, 0.7)
const COLOR_UI_DARK_BG := Color(0.1, 0.1, 0.15, 0.95)
const COLOR_UI_BORDER := Color(0.3, 0.3, 0.4)
const COLOR_UI_BUTTON_NORMAL := Color(0.2, 0.2, 0.3)
const COLOR_UI_BUTTON_HOVER := Color(0.3, 0.3, 0.4)

# UI Sizes
const UI_TOP_BAR_HEIGHT := 44.0
const UI_RANGE_INDICATOR_SEGMENTS := 64
const UI_MAX_COIN_SOUND_PLAYERS := 3

# Audio
const MUSIC_VOLUME_DEFAULT := -7.0

# Visual Effects
const EFFECT_DAMAGE_NUMBER_DURATION := 1.0
const EFFECT_COIN_COLLECT_DURATION := 0.5
const EFFECT_DEATH_ANIMATION_DURATION := 0.8

# Wall Costs (acumulativo)
const WALL_COST_1ST := 100
const WALL_COST_2ND := 300
const WALL_COST_3RD := 600
const WALL_COST_4TH := 1000

# Tower Cost Scaling
const TOWER_COST_SCALE_PER_WAVE := 1.02  # 2% por wave
