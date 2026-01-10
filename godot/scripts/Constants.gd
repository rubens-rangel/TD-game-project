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
const SHOCK_TOWER_COST := 48  # Aumentado em 20% (de 40 para 48)
const WALL_COST := 50
const HEALING_STATION_COST := 50

const MINE_DAMAGE := 15.0  # Dano base
const MINE_TRIGGER_RADIUS := 18.0
const MINE_EXPLOSION_RADIUS := 60.0  # Raio base de explosão
const MINE_SLOW_DURATION := 1.5
const MINE_SLOW_AMOUNT := 0.4

# Mine Upgrades (globais)
const MINE_UPGRADE_DAMAGE_COST := 50  # Custo base para upgrade de dano
const MINE_UPGRADE_DAMAGE_AMOUNT := 10.0  # Dano adicionado por nível
const MINE_UPGRADE_DAMAGE_MAX_LEVEL := 20  # Máximo de níveis de dano

const MINE_UPGRADE_RADIUS_COST := 40  # Custo base para upgrade de raio
const MINE_UPGRADE_RADIUS_AMOUNT := 8.0  # Raio adicionado por nível
const MINE_UPGRADE_RADIUS_MAX_LEVEL := 15  # Máximo de níveis de raio

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
const WAVE_SCALE := 1.045  # Reduzido de 1.06 para 1.04 - crescimento mais suave
const INTERMISSION := 12.0  # Aumentado de 5.0 para 8.0 para dar mais tempo entre waves

# Enemy stats
const ENEMY_BASE_SPEED := 38.0  # Aumentado de 30.0 para 38.0 (~27% mais rápido)
const ENEMY_MAX_SPEED := 210.0  # Velocidade máxima dos inimigos (limite para evitar bugs em waves muito altas)
const BOSS_SPEED_MULTIPLIER := 0.5
const ENEMY_BASE_HP := 3  # Aumentado de 2 para 3 para aumentar dificuldade inicial
const BOSS_BASE_HP := 23  # Reduzido de 35 para 28 (~20% menos) para melhor balanceamento
const BOSS_REWARD_MULTIPLIER := 20
const NORMAL_REWARD := 2

# Balanceamento: Escala de recompensas e upgrades
const REWARD_SCALE := 1.03  # Recompensas crescem 2% por wave (reduzido de 1.05 para balancear níveis altos)
const REWARD_SCALE_SOFT_CAP := 50  # A partir da wave 30, a escala diminui ainda mais
const REWARD_SCALE_AFTER_CAP := 1.02  # Após o soft cap, cresce apenas 2% por wave
const UPGRADE_COST_MULTIPLIER := 1.20  # Upgrades ficam 15% mais caros por nível (aumentado de 1.12)
const WAVE_COMPLETION_BONUS_BASE := 10
const WAVE_COMPLETION_BONUS_PER_WAVE := 1  # Reduzido de 2 para 1 (crescimento mais lento)
const WAVE_COMPLETION_BONUS_MAX := 100  # Cap máximo de bônus por wave (evita valores muito altos)

# Hero
const HERO_START_COINS := 0
const HERO_BASE_FIRE_RATE := 1.0 
const HERO_BASE_DAMAGE := 0.9  

# Coin drops
const COIN_DROP_CHANCE := 0.12  
const COIN_MIN_VALUE := 3
const COIN_MAX_VALUE := 20
const COIN_LIFETIME := 15.0  # tempo que a moeda fica no chão antes de desaparecer

# Item drops (Talismãs, etc.)
const TALISMAN_DROP_CHANCE := 0.005  # 0,5% de chance de dropar talismã 
const TALISMAN_LIFETIME := 60.0  # tempo que o talismã fica no chão antes de desaparecer (60 segundos)
const TALISMAN_COLLECT_RADIUS := 25.0  # raio de coleta do talismã (maior que moedas)

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
const SKILL_MAGNETISM_COOLDOWN := 60.0  # segundos de cooldown
const SKILL_MAGNETISM_DURATION := 30.0  # segundos de duração
const COIN_MAGNETISM_RANGE := 20.0  # Raio de coleta automática de moedas

# Hero
const HERO_ARROW_SPEED := 260.0
const HERO_BASE_HP := 100
const HERO_HOME_MAX_LEVEL := 4
const HERO_HOME_UPGRADE_COST_LEVEL_2 := 1500
const HERO_HOME_UPGRADE_COST_LEVEL_3 := 5500
const HERO_HOME_UPGRADE_COST_LEVEL_4 := 12500  
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
const EFFECT_DEATH_ANIMATION_DURATION := 0.6

# Wall Costs (acumulativo)
const WALL_COST_1ST := 100
const WALL_COST_2ND := 300
const WALL_COST_3RD := 600
const WALL_COST_4TH := 1000

# Wall Stats
const WALL_BASE_HP := 50.0  # HP base das muralhas (aumentado de 20 para 50)
const WALL_DAMAGE_RADIUS := 25.0  # Raio para inimigos causarem dano na muralha
const WALL_DAMAGE_PER_SECOND := 1.0  # Dano por segundo quando inimigo está próximo (aumentado de 0.5)
const WALL_BOSS_DAMAGE_MULTIPLIER := 2.0  # Bosses causam 2x mais dano
const WALL_UPGRADE_HP_COST := 75  # Custo para upgrade de HP (aumentado de 30 para 75)
const WALL_UPGRADE_HP_AMOUNT := 25.0  # Quantidade de HP adicionada por upgrade
const WALL_MAX_UPGRADES := 5  # Máximo de upgrades de HP

# Tower Cost Scaling
const TOWER_COST_SCALE_PER_WAVE := 1.02  # 2% por wave

# Tower Fire Rate Limits (minimum fire rate - towers can't shoot faster than this)
const TOWER_MIN_FIRE_RATE := 0.4  # Limite mínimo de fire_rate para torres básicas (em segundos)
const SNIPER_MIN_FIRE_RATE := 1.5  # Limite mínimo de fire_rate para sniper towers (em segundos)
const AOE_MIN_FIRE_RATE := 1.0  # Limite mínimo de fire_rate para AOE towers (em segundos)
const SHOCK_MIN_FIRE_RATE := 0.8 # Limite mínimo de fire_rate para shock towers (em segundos)
const HERO_MIN_FIRE_RATE := 0.1  # Limite mínimo de fire_rate para o herói (em segundos)

# Tower Upgrade Maximums
const SHOCK_MAX_CHAIN_COUNT := 15  # Máximo de corrente para shock towers
const AOE_MAX_RADIUS := 250.0  # Máximo de raio AOE (reduzido de ~320 para 250)

# Tower Fire Rate Upgrade Reductions (quanto reduz por upgrade)
const TOWER_FIRE_RATE_REDUCTION := 0.05  # Redução de fire_rate por upgrade de torre básica
const SNIPER_FIRE_RATE_REDUCTION := 0.5  # Redução de fire_rate por upgrade de sniper
const AOE_FIRE_RATE_REDUCTION := 0.3  # Redução de fire_rate por upgrade de AOE
const SHOCK_FIRE_RATE_REDUCTION := 0.2  # Redução de fire_rate por upgrade de shock
const HERO_FIRE_RATE_REDUCTION := 0.03  # Redução de fire_rate por upgrade do herói

# Base HP
const BASE_MAX_HP := 100.0  # Limite máximo de HP da base (usado por healing stations)


# Quest System
const QUEST_DAILY_COUNT := 3  # Número de quests diárias ativas
const QUEST_WEEKLY_COUNT := 2  # Número de quests semanais ativas
const QUEST_MONTHLY_COUNT := 1  # Número de quests mensais ativas
const QUEST_REFRESH_HOUR := 0  # Hora do dia para refresh (0 = meia-noite)

# Quest Types
enum QuestType {
	KILL_ENEMIES,  # Matar X inimigos
	KILL_BOSSES,  # Matar X bosses
	COMPLETE_WAVES,  # Completar X waves
	COLLECT_COINS,  # Coletar X moedas
	BUILD_TOWERS,  # Construir X torres
	USE_SKILLS,  # Usar X skills
	PERFECT_WAVES,  # Completar X waves sem perder HP da base
	REACH_WAVE,  # Alcançar wave X
	SPEND_COINS,  # Gastar X moedas
	UPGRADE_TOWERS  # Fazer X upgrades de torres
}

# Quest Rewards (base, pode escalar)
const QUEST_REWARD_DAILY_COINS := 50  # Recompensa base de moedas para quests diárias
const QUEST_REWARD_WEEKLY_COINS := 100  # Recompensa base de moedas para quests semanais (reduzido de 200)
const QUEST_REWARD_MONTHLY_COINS := 500  # Recompensa base de moedas para quests mensais (reduzido de 1000)

# Special Currency Rewards (Moedas Especiais)
# Esmeraldas removidas das quests - não faz sentido ter esmeraldas como recompensa
const QUEST_REWARD_MONTHLY_DIAMONDS := 1  # Diamantes dados em quests mensais

# Special Currency Drop Rates (em waves altas)
const EMERALD_DROP_START_WAVE := 50  # Wave a partir da qual esmeraldas podem dropar (reduzido de 100)
const EMERALD_DROP_CHANCE := 0.04  # 2% de chance de dropar esmeralda (aumentado de 1%)
const DIAMOND_DROP_START_WAVE := 150  # Wave a partir da qual diamantes podem dropar
const DIAMOND_DROP_CHANCE := 0.001  # 0.1% de chance de dropar diamante (wave 150+)
const BOSS_EMERALD_REWARD_WAVE := 25  # A cada X waves, boss dá esmeralda garantida
const BOSS_EMERALD_REWARD_COUNT := 20  # Quantidade de esmeraldas por boss especial

# Tower Upgrades with Emeralds (escalado)
const TOWER_UPGRADE_EMERALD_BASE_COST := 1  # Custo base em esmeraldas para upgrade de torre
const TOWER_UPGRADE_EMERALD_SCALE := 1.2  # Multiplicador escalado por nível (1.2x por nível - reduzido de 1.3 para ser mais acessível)

# Prestige Shop - Emerald Costs
const PRESTIGE_COST_START_COINS_LEVEL := 2  # Custo em esmeraldas por nível de moedas iniciais
const PRESTIGE_COST_COIN_DROP_LEVEL := 3  # Custo em esmeraldas por nível de chance de drop
const PRESTIGE_COST_HERO_DAMAGE_LEVEL := 5  # Custo em esmeraldas por nível de dano do herói
const PRESTIGE_COST_HERO_FIRERATE_LEVEL := 4  # Custo em esmeraldas por nível de velocidade de tiro
const PRESTIGE_COST_BASE_HP_LEVEL := 3  # Custo em esmeraldas por nível de HP da base
const PRESTIGE_COST_SPECIAL_TOWER := 10  # Custo em esmeraldas para desbloquear torre especial

# Prestige Shop - Diamond Costs (ordenados: 1, 2, 3, 5, 8, 10, 12, 15)
const PRESTIGE_COST_PRESTIGE_RESET := 5  # Custo em diamantes para resetar prestígio
const PRESTIGE_COST_SPECIAL_MODE := 1  # Modo Especial
const PRESTIGE_COST_TOWER_UPGRADE_ALL := 2  # Upgrade Permanente de Todas as Torres
const PRESTIGE_COST_REWARD_MULTIPLIER := 3  # Multiplicador de Recompensas (por nível)
const PRESTIGE_COST_LEGENDARY_TOWER := 5  # Torre Lendária
const PRESTIGE_COST_BASE_HP_BOOST := 8  # Boost de HP da Base
const PRESTIGE_COST_HERO_DAMAGE_BOOST := 10  # Boost de Dano do Herói
const PRESTIGE_COST_COIN_DROP_BOOST := 12  # Boost de Chance de Drop de Moedas
const PRESTIGE_COST_STARTING_COINS_BOOST := 15  # Boost de Moedas Iniciais

# Prestige Shop - Max Levels
const PRESTIGE_MAX_START_COINS_LEVEL := 5
const PRESTIGE_MAX_COIN_DROP_LEVEL := 3
const PRESTIGE_MAX_HERO_DAMAGE_LEVEL := 3
const PRESTIGE_MAX_HERO_FIRERATE_LEVEL := 3
const PRESTIGE_MAX_BASE_HP_LEVEL := 5

# Button Hover Effects
const BUTTON_HOVER_SCALE := 1.05  # Escala do botão ao fazer hover (5% maior)
const BUTTON_HOVER_TRANSITION_TIME := 0.15  # Tempo de transição do hover (em segundos)
const BUTTON_PRESS_SCALE := 0.95  # Escala do botão ao pressionar (5% menor)
const BUTTON_PRESS_TRANSITION_TIME := 0.1  # Tempo de transição do press (em segundos)

# Barracks (Quartéis)
const BARRACKS_INITIAL_SPAWN_RATE := 3.0  # Taxa inicial de spawn de soldados (em segundos)
const BARRACKS_MIN_SPAWN_RATE := 1.0  # Limite mínimo de spawn rate (em segundos)
const BARRACKS_SPAWN_RATE_REDUCTION := 0.5  # Redução de spawn rate por upgrade
const BARRACKS_INITIAL_HOLD_TIME := 1.0  # Tempo inicial que soldado segura monstro (em segundos)
const BARRACKS_HOLD_TIME_INCREASE := 0.5  # Aumento de hold time por upgrade
const BARRACKS_INITIAL_SOLDIER_DAMAGE := 0.4  # Dano por segundo do soldado inicial
const BARRACKS_INITIAL_PROJECTILE_SPEED := 80.0  # Velocidade inicial do projetil do soldado
const BARRACKS_PROJECTILE_SPEED_INCREASE := 20.0  # Aumento de velocidade do projetil por upgrade
const BARRACKS_SOLDIER_DAMAGE_INCREASE := 0.2  # Aumento de dano do soldado por upgrade
