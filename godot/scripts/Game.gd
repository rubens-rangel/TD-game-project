extends Node2D

const GridManager = preload("res://scripts/GridManager.gd")
const Pathfinder = preload("res://scripts/Pathfinder.gd")
const WaveManager = preload("res://scripts/WaveManager.gd")
const ProjectileManager = preload("res://scripts/ProjectileManager.gd")
const GameConstants = preload("res://scripts/Constants.gd")
const SaveManager = preload("res://scripts/managers/SaveManager.gd")
const AchievementManager = preload("res://scripts/managers/AchievementManager.gd")
const PerkManager = preload("res://scripts/managers/PerkManager.gd")
const ResourceManager = preload("res://scripts/managers/ResourceManager.gd")
const EffectsManager = preload("res://scripts/managers/EffectsManager.gd")
const CoinManager = preload("res://scripts/managers/CoinManager.gd")
const RewardCalculator = preload("res://scripts/managers/RewardCalculator.gd")
const UIHelper = preload("res://scripts/helpers/UIHelper.gd")
const HeroManager = preload("res://scripts/managers/HeroManager.gd")
const SkillsManager = preload("res://scripts/managers/SkillsManager.gd")
const PlacementManager = preload("res://scripts/managers/PlacementManager.gd")
const TowerSystemManager = preload("res://scripts/managers/TowerSystemManager.gd")
const VisualEffectsManager = preload("res://scripts/managers/VisualEffectsManager.gd")
const UIManager = preload("res://scripts/managers/UIManager.gd")
const ItemManager = preload("res://scripts/managers/ItemManager.gd")
const Talisman = preload("res://scripts/items/Talisman.gd")
const SpecialCurrencyManager = preload("res://scripts/managers/SpecialCurrencyManager.gd")
const PrestigeShop = preload("res://scripts/managers/PrestigeShop.gd")
const QuestManager = preload("res://scripts/managers/QuestManager.gd")
const WeatherManager = preload("res://scripts/managers/WeatherManager.gd")
const ObjectPoolManager = preload("res://scripts/managers/ObjectPoolManager.gd")
const CullingManager = preload("res://scripts/managers/CullingManager.gd")
const ThreadManager = preload("res://scripts/managers/ThreadManager.gd")
const ComboManager = preload("res://scripts/managers/ComboManager.gd")
const NotificationManager = preload("res://scripts/managers/NotificationManager.gd")
const Market = preload("res://scripts/structures/Market.gd")

const HERO_ARROW_SPEED := GameConstants.HERO_ARROW_SPEED

var grid_manager: GridManager
var pathfinder: Pathfinder
var wave_manager: WaveManager
var projectile_manager: ProjectileManager
var achievement_manager: AchievementManager
var perk_manager: PerkManager
var resource_manager: ResourceManager
var effects_manager: EffectsManager
var coin_manager: CoinManager
var reward_calculator: RewardCalculator
var hero_manager: HeroManager
var skills_manager: SkillsManager
var placement_manager: PlacementManager
var tower_system_manager: TowerSystemManager
var visual_effects_manager: VisualEffectsManager
var ui_manager: UIManager
var item_manager: ItemManager
var special_currency_manager: SpecialCurrencyManager
var prestige_shop: PrestigeShop
var quest_manager: QuestManager
var weather_manager: WeatherManager
var object_pool_manager: ObjectPoolManager
var culling_manager: CullingManager
var thread_manager: ThreadManager
var combo_manager: ComboManager
var notification_manager: NotificationManager

var total_kills: int = 0
var total_boss_kills: int = 0
var total_coins_collected: int = 0
var total_coins_spent: int = 0
var towers_built: int = 0
var tower_types_built: Dictionary = {}
var perfect_waves: int = 0
var current_wave_base_hp_start: int = 0
var first_play: bool = true
var skill_used: bool = false
var maxed_towers_count: int = 0
var walls_built: int = 0
var global_tower_damage_boost: float = 1.0
var global_tower_range_boost: float = 1.0
var tower_damage_boost_waves_remaining: int = 0  # Waves restantes do buff de dano de torres
var hero_damage_boost_waves_remaining: int = 0  # Waves restantes do buff de dano do herói
var heal_full_uses_remaining: int = 2  # Usos restantes da cura completa

var perk_effects: Dictionary = {}
var coin_drop_chance: float = GameConstants.COIN_DROP_CHANCE

var grid_offset: Vector2

var enemies: Array = []
var arrows: Array = []
var tower_bullets: Array = []
var aoe_effects: Array = []
var sniper_effects: Array = []
var aoe_cannon_projectiles: Array = []
var dropped_coins: Array = []
var coin_collect_effects: Array = []
var dropped_talismans: Array = []
var damage_numbers: Array = []
var enemy_death_animations: Array = []
var shock_effects: Array = []

var base_hp := GameConstants.HERO_BASE_HP
var base_hp_base := GameConstants.HERO_BASE_HP
var base_hp_max := GameConstants.HERO_BASE_HP
var paused := false
var game_over := false
var diamond_150_given: bool = false
var game_time: float = 0.0
var game_time_start: float = 0.0

var isAdmin: bool = true
var placing_tower := false
var placing_barracks := false
var placing_mine := false
var placing_slow_tower := false
var placing_aoe_tower := false
var placing_sniper_tower := false
var placing_boost_tower := false
var placing_shock_tower := false
var placing_wall := false
var placing_healing_station := false
var placing_market := false

var towers: Array = []
var barracks: Array = []
var mines: Array = []
var mine_tiles: Dictionary = {}
var wall_tiles: Dictionary = {}
var slow_towers: Array = []
var aoe_towers: Array = []
var sniper_towers: Array = []
var boost_towers: Array = []
var shock_towers: Array = []
var walls: Array = []
var wall_hp_multiplier: float = 1.0
var healing_stations: Array = []
var markets: Array = []

var mine_damage_level: int = 0
var mine_radius_level: int = 0
var preview_mouse_pos := Vector2.ZERO
var soldiers: Array = []

var tower_menu: PopupMenu
var tower_selected_index := -1
var keep_menu_open := false
var placing_tower_dir := Vector2(1, 0)

var barracks_menu: PopupMenu
var barracks_selected_index := -1
var keep_barracks_menu_open := false

var sniper_menu: PopupMenu
var sniper_selected_index := -1
var keep_sniper_menu_open := false
var aoe_menu: PopupMenu
var aoe_selected_index := -1
var keep_aoe_menu_open := false
var shock_menu: PopupMenu
var shock_selected_index := -1
var keep_shock_menu_open := false
var slow_menu: PopupMenu
var slow_selected_index := -1
var keep_slow_menu_open := false
var boost_menu: PopupMenu
var boost_selected_index := -1
var keep_boost_menu_open := false
var wall_menu: PopupMenu
var wall_selected_index := -1
var keep_wall_menu_open := false
var market_menu: PopupMenu
var market_selected_index := -1
var keep_market_menu_open := false

var dragging_tower := false
var dragged_tower_type := ""
var dragged_tower_index := -1
var drag_start_pos: Vector2 = Vector2.ZERO
var drag_offset: Vector2 = Vector2.ZERO
var drag_current_pos: Vector2 = Vector2.ZERO

var enemy_effects: Dictionary = {}
var tex_hero: Texture2D
var tex_enemy_zombie: Texture2D
var tex_enemy_zombie_gordo: Texture2D
var tex_enemy_zombie_corredor: Texture2D
var tex_enemy_humanoid: Texture2D
var tex_enemy_robot: Texture2D
var tex_enemy_alien: Texture2D
var tex_enemy_boss: Texture2D
var tex_tent: Texture2D
var tex_house: Texture2D
var tex_castle: Texture2D
var tex_castle2: Texture2D
var tex_grass: Texture2D
var tex_path: Texture2D
var tex_wall: Texture2D
var tex_tower: Texture2D
var tex_slow_tower: Texture2D
var tex_aoe_tower: Texture2D
var tex_sniper_tower: Texture2D
var tex_boost_tower: Texture2D
var tex_shock_tower: Texture2D
var tex_barracks: Texture2D
var tex_mine: Texture2D
var tex_wall_structure: Texture2D
var tex_healing_station: Texture2D
var tex_market: Texture2D
var tex_coin: Texture2D
var tex_talisman: Texture2D
var tex_game_over: Texture2D

var loading_screen: Control
var loading_progress: float = 0.0
var is_loading: bool = true

var tower_shop_panel: Panel
var tower_buttons: Array = []
var tooltip_label: Label
var hovered_tower_button: Control = null
var music_muted: bool = false
var music_volume: float = -7.0
var music_volume_slider: HSlider = null
var tower_shop_collapsed: bool = false
var skills_panel_collapsed: bool = false
var tower_shop_toggle_button: Button
var skills_panel_toggle_button: Button

var game_tooltip: Control
var tooltip_text: String = ""
var tooltip_timer: float = 0.0

var admin_menu: PopupMenu
var admin_menu_button: Button

var range_indicator: Line2D

var boss_alert_label: Label
var boss_alert_timer: float = 0.0
var boss_alert_duration: float = GameConstants.BOSS_ALERT_DURATION
var boss_warning_sound: AudioStream
var boss_alert_player: AudioStreamPlayer
var coin_sound_players: Array = []

var special_wave_alert_label: Label
var special_wave_alert_timer: float = 0.0
var current_special_wave_type: WaveManager.SpecialWaveType = WaveManager.SpecialWaveType.NONE
var special_wave_coin_multiplier: float = 1.0
var perfect_wave_bonus_given: bool = false

var weather_overlay: ColorRect
var weather_clouds: Array = []
var weather_rain_particles: Array = []
var weather_snow_particles: Array = []
var weather_alert_label: Label
var weather_alert_timer: float = 0.0
var weather_effects_active: bool = false

var emerald_label: Label
var diamond_label: Label

var pause_overlay: Control
var save_status_label: Label

# Cache para otimização de FPS
var _cached_map_width: float = 0.0
var _cached_map_height: float = 0.0
var _cached_grid_size_px: float = 0.0
var _ui_update_timer: float = 0.0
var _ui_update_interval: float = 0.1  # Atualizar UI a cada 100ms ao invés de todo frame

# Cache de valores pré-calculados
var _cached_tile_size: float = float(GameConstants.TILE_SIZE)
var _cached_base_half_size: int = int(GameConstants.BASE_SIZE_TILES / 2)
var _cached_base_grid_size: int = GameConstants.BASE_GRID_SIZE

var skills_panel: Panel
var skill_buttons: Dictionary = {}

var tower_dps_data: Dictionary = {}
var dps_menu_panel: Panel = null
var dps_menu_visible: bool = false

func _wave_factor() -> float:
	return wave_manager.wave_factor()

func get_effective_tower_range(base_range: float) -> float:
	if weather_manager:
		return base_range * weather_manager.get_tower_range_multiplier()
	return base_range

func get_effective_tower_damage(base_damage: float) -> float:
	if weather_manager:
		return base_damage * weather_manager.get_tower_damage_multiplier()
	return base_damage

func get_enemy_reward() -> int:
	var base_reward = reward_calculator.get_enemy_reward()
	if current_special_wave_type == WaveManager.SpecialWaveType.DOUBLE_COINS:
		return int(base_reward * 2.0)
	return int(base_reward * special_wave_coin_multiplier)

func get_boss_reward() -> int:
	var base_reward = reward_calculator.get_boss_reward()
	if current_special_wave_type == WaveManager.SpecialWaveType.DOUBLE_COINS:
		return int(base_reward * 2.0)
	return int(base_reward * special_wave_coin_multiplier)

# Calcula custo progressivo de upgrade
func get_upgrade_cost(base_cost: int, current_level: int) -> int:
	"""Calcula custo de upgrade com escala progressiva"""
	return RewardCalculator.get_upgrade_cost(base_cost, current_level)

# Calcula bonus de completion de wave
func get_wave_completion_bonus() -> int:
	"""Calcula bonus de moedas por completar uma wave (com cap máximo)"""
	var base_bonus = reward_calculator.get_wave_completion_bonus()
	# Aplicar multiplicador de wave especial (exceto PERFECT_WAVE que tem bônus próprio)
	if current_special_wave_type != WaveManager.SpecialWaveType.NONE and current_special_wave_type != WaveManager.SpecialWaveType.PERFECT_WAVE:
		return int(base_bonus * special_wave_coin_multiplier)
	return base_bonus

# Calcula custo de torre escalado com wave
func get_tower_cost(base_cost: int) -> int:
	"""Calcula custo de torre baseado na wave atual"""
	return reward_calculator.get_tower_cost(base_cost)

# Calcula custo acumulativo de muralha (escalado com wave)
func get_wall_cost() -> int:
	"""Calcula custo de muralha baseado no número de muralhas já construídas (acumulativo) e wave atual"""
	return reward_calculator.get_wall_cost(walls.size())

# Calcula custo de upgrade de torre com esmeraldas (escalado)
func get_tower_upgrade_emerald_cost(upgrade_type: String, current_level: int) -> int:
	"""Calcula custo em esmeraldas para upgrade de torre (escalado)"""
	var base_cost = GameConstants.TOWER_UPGRADE_EMERALD_BASE_COST
	var scale = GameConstants.TOWER_UPGRADE_EMERALD_SCALE
	# Custo escalado: base * (scale ^ level)
	return int(base_cost * pow(scale, current_level))

# Funções para calcular valores de minas com upgrades globais
func get_mine_damage() -> float:
	"""Retorna o dano das minas considerando upgrades globais"""
	return GameConstants.MINE_DAMAGE + (mine_damage_level * GameConstants.MINE_UPGRADE_DAMAGE_AMOUNT)

func get_mine_explosion_radius() -> float:
	"""Retorna o raio de explosão das minas considerando upgrades globais"""
	return GameConstants.MINE_EXPLOSION_RADIUS + (mine_radius_level * GameConstants.MINE_UPGRADE_RADIUS_AMOUNT)

func get_mine_upgrade_damage_cost() -> int:
	"""Retorna o custo do próximo upgrade de dano de minas"""
	return get_upgrade_cost(GameConstants.MINE_UPGRADE_DAMAGE_COST, mine_damage_level)

func get_mine_upgrade_radius_cost() -> int:
	"""Retorna o custo do próximo upgrade de raio de minas"""
	return get_upgrade_cost(GameConstants.MINE_UPGRADE_RADIUS_COST, mine_radius_level)

func upgrade_mine_damage() -> bool:
	"""Compra upgrade de dano de minas. Retorna true se bem-sucedido"""
	if mine_damage_level >= GameConstants.MINE_UPGRADE_DAMAGE_MAX_LEVEL:
		return false
	var cost = get_mine_upgrade_damage_cost()
	if hero["coins"] < cost:
		return false
	hero["coins"] -= cost
	_track_coin_spent(cost)
	mine_damage_level += 1
	_update_all_mines_stats()  # Atualizar todas as minas existentes
	return true

func upgrade_mine_radius() -> bool:
	"""Compra upgrade de raio de minas. Retorna true se bem-sucedido"""
	if mine_radius_level >= GameConstants.MINE_UPGRADE_RADIUS_MAX_LEVEL:
		return false
	var cost = get_mine_upgrade_radius_cost()
	if hero["coins"] < cost:
		return false
	hero["coins"] -= cost
	_track_coin_spent(cost)
	mine_radius_level += 1
	_update_all_mines_stats()  # Atualizar todas as minas existentes
	return true

func _update_all_mines_stats() -> void:
	"""Atualiza as estatísticas de todas as minas existentes com os novos valores de upgrade"""
	for i in range(mines.size()):
		if not mines[i].triggered:
			mines[i]["damage"] = get_mine_damage()
			mines[i]["explosion_radius"] = get_mine_explosion_radius()

# upgrades overlay state
var choosing_upgrade := false
var benefit_applied := false
var selected_benefit_index := -1  # Índice do benefício selecionado (mas não aplicado ainda)
var auto_choose_benefits := false  # Se true, escolhe benefício aleatório automaticamente sem pausar
var upgrade_options := [
	{"label": "Dano", "code": "DMG", "max_level": 30, "description": "Aumenta o dano dos tiros (+1 por nível)"},
	{"label": "Velocidade", "code": "FIRERATE", "max_level": 20, "description": "Reduz o tempo entre tiros (cadência mais rápida)"},
	{"label": "Perfuração", "code": "PIERCE", "max_level": 3, "description": "Permite acertar múltiplos inimigos (1, 2 ou 3)"},
	{"label": "Chance Crítico", "code": "CRIT_CHANCE", "max_level": 10, "description": "Aumenta chance de crítico (2% por nível, máx 20%)"},
	{"label": "Dano Crítico", "code": "CRIT_DMG", "max_level": 10, "description": "Aumenta multiplicador de dano crítico (+0.2 por nível)"},
]

# hero
var hero := {
	"x": 0.0, "y": 0.0, "cooldown": 0.0, "fire_rate": GameConstants.HERO_BASE_FIRE_RATE,
	"damage": GameConstants.HERO_BASE_DAMAGE, "pierce": 0, "range": 9999.0,
	"levels": { "DMG": 0, "FIRERATE": 0, "PIERCE": 0, "CRIT_CHANCE": 0, "CRIT_DMG": 0 }, 
	"coins": GameConstants.HERO_START_COINS,
	"crit_chance": 0.0,  # Chance de crítico (0.0 a 1.0)
	"crit_multiplier": 2.0,  # Multiplicador de dano crítico
}

# Valores base para recalcular bônus (sem modificadores permanentes)
var hero_damage_base: float = GameConstants.HERO_BASE_DAMAGE
var hero_fire_rate_base: float = GameConstants.HERO_BASE_FIRE_RATE
var hero_crit_chance_base: float = 0.0
var global_tower_damage_boost_base: float = 1.0  # Base sem bônus permanentes
var coin_drop_chance_base: float = GameConstants.COIN_DROP_CHANCE

const HERO_HOME_MAX_LEVEL := 4
var hero_home_level: int = 1
var hero_home_panel_data: Dictionary = {}
var hero_home_upgrade_costs := {
	2: 1200,
	3: 3000,
	4: 12000
}

func _get_hero_home_texture_for_level(level: int) -> Texture2D:
	"""Delegado para HeroManager"""
	if hero_manager:
		return hero_manager.get_hero_home_texture_for_level(level)
	# Fallback se hero_manager não estiver disponível
	match level:
		2:
			return tex_house if tex_house != null else tex_tent
		3:
			return tex_castle if tex_castle != null else (tex_house if tex_house != null else tex_tent)
		4:
			return tex_castle2 if tex_castle2 != null else (tex_castle if tex_castle != null else (tex_house if tex_house != null else tex_tent))
		_:
			return tex_tent

func _get_hero_home_upgrade_cost(level: int) -> int:
	"""Delegado para HeroManager - inclui aumento baseado na wave atual"""
	var current_wave = 0
	if wave_manager:
		current_wave = wave_manager.wave
	
	# Resetar flag de diamante da wave 150 para nova partida
	diamond_150_given = false
	
	if hero_manager:
		return hero_manager.get_hero_home_upgrade_cost(level, current_wave)
	
	# Fallback: aplicar aumento manualmente se hero_manager não estiver disponível
	var base_cost = hero_home_upgrade_costs.get(level, 0)
	if base_cost <= 0:
		return 0
	var wave_multiplier = 1.0 + (current_wave * 0.01)
	return int(base_cost * wave_multiplier)

func _get_hero_home_benefits_text(level: int) -> String:
	"""Delegado para HeroManager"""
	if hero_manager:
		return hero_manager.get_hero_home_benefits_text(level)
	# Fallback
	match level:
		1:
			return "Nível inicial. Proteção básica da tenda."
		2:
			return "• Dano Global das Torres +10%\n• Alcance +100\n• HP da base +40"
		3:
			return "• Dano Global das Torres +10%\n• +1 perfuração\n• Cadência -0.05s\n• HP da base +60"
		4:
			return "• Dano Global das Torres +15%\n• Dano do Herói +15%\n• Cadência -0.08s\n• Alcance +150\n• HP da base +100"
		_:
			return "Nível máximo alcançado"

func _apply_hero_home_upgrade_effects(level: int) -> void:
	"""Delegado para HeroManager"""
	if hero_manager:
		var changes = hero_manager.apply_hero_home_upgrade(level)
		# Aplicar mudanças no jogo
		global_tower_damage_boost = hero_manager.global_tower_damage_boost
		var old_base_hp = base_hp
		base_hp = hero_manager.base_hp
		# Atualizar HP máximo com a diferença
		var hp_increase = base_hp - old_base_hp
		if hp_increase > 0:
			base_hp_max += hp_increase
		hero_home_level = hero_manager.hero_home_level
		
		# Aplicar mudanças no herói (range, pierce, fire_rate)
		if changes.has("range") and changes["range"] > 0:
			hero["range"] += changes["range"]
		if changes.has("pierce") and changes["pierce"] > 0:
			hero["pierce"] += changes["pierce"]
		if changes.has("fire_rate") and changes["fire_rate"] < 0:
			hero["fire_rate"] = max(GameConstants.HERO_MIN_FIRE_RATE, hero["fire_rate"] + changes["fire_rate"])
		
		# Atualizar boost global nas torres
		if tower_system_manager:
			tower_system_manager.set_global_damage_boost(global_tower_damage_boost)
		return
	# Fallback (código antigo)
	match level:
		2:
			global_tower_damage_boost *= 1.10
			hero["range"] += 100
			base_hp += 40
			base_hp_max += 40  # Atualizar HP máximo também
		3:
			global_tower_damage_boost *= 1.10
			hero["pierce"] += 1
			hero["fire_rate"] = max(GameConstants.HERO_MIN_FIRE_RATE, hero["fire_rate"] - GameConstants.HERO_FIRE_RATE_REDUCTION)
			base_hp += 60
			base_hp_max += 60  # Atualizar HP máximo também
		4:
			global_tower_damage_boost *= 1.15
			hero["damage"] *= 1.15  # +15% dano do herói
			hero["fire_rate"] = max(GameConstants.HERO_MIN_FIRE_RATE, hero["fire_rate"] - 0.08)
			hero["range"] += 150
			base_hp += GameConstants.HERO_BASE_HP
			base_hp_max += GameConstants.HERO_BASE_HP


func _try_load(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _try_load_music(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _load_and_process_texture(image_path: String) -> Texture2D:
	# Carregar textura e processar para remover fundo branco
	var texture = _try_load(image_path)
	if texture != null:
		print("Processando textura: ", image_path)
		texture = _process_white_to_transparent(texture, image_path)
		print("Textura processada com sucesso: ", image_path)
	else:
		print("Textura não encontrada: ", image_path)
	return texture

func _process_white_to_transparent(texture: Texture2D, image_path: String) -> Texture2D:
	# Converter fundo branco em transparência
	var image: Image = null
	
	# Tentar obter a imagem da textura
	if texture.has_method("get_image"):
		image = texture.get_image()
	
	# Se não conseguir, carregar diretamente do arquivo
	if image == null:
		if ResourceLoader.exists(image_path):
			image = Image.new()
			var error = image.load(image_path)
			if error != OK:
				print("Erro ao carregar imagem ", image_path, ": ", error)
				return texture
	
	if image == null:
		return texture
	
	# Converter para RGBA se necessário
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	
	# Processar cada pixel para converter branco em transparência
	# No Godot 4, não é necessário usar lock()/unlock()
	# Threshold mais agressivo para remover mais brancos
	var threshold = 0.85  # 217/255 - muito mais agressivo, remove tons claros também
	if "slow_tower" in image_path:
		threshold = 0.82  # 209/255 - para slow_tower (já está funcionando bem)
	elif "tower.png" in image_path:
		threshold = 0.78  # 199/255 - ainda mais agressivo para tower normal (remover pontos brancos)
	
	var pixels_changed = 0
	var total_pixels = image.get_width() * image.get_height()
	
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel = image.get_pixel(x, y)
			# Se o pixel for branco ou quase branco (threshold), tornar transparente
			# Verificar também se o pixel já é transparente (alpha baixo)
			var is_white = pixel.r >= threshold and pixel.g >= threshold and pixel.b >= threshold
			var is_transparent = pixel.a < 0.1
			
			# Verificar também tons de cinza claros (pode ajudar com slow_tower)
			var brightness = (pixel.r + pixel.g + pixel.b) / 3.0
			var is_bright = brightness >= threshold
			
			if is_white or is_transparent or is_bright:
				# Tornar completamente transparente (alpha = 0)
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, 0.0))
				pixels_changed += 1
	
	var percent_changed = (float(pixels_changed) / float(total_pixels)) * 100.0
	print("Pixels alterados em ", image_path, ": ", pixels_changed, " de ", total_pixels, " (", "%.1f" % percent_changed, "%)")
	
	# Criar nova textura a partir da imagem processada
	var new_texture = ImageTexture.create_from_image(image)
	return new_texture

func _exit_tree() -> void:
	"""Limpa threads e recursos ao sair"""
	if thread_manager:
		thread_manager.cleanup()

func _ready() -> void:
	# Criar tela de carregamento primeiro
	_create_loading_screen()
	
	grid_manager = GridManager.new()
	pathfinder = Pathfinder.new(grid_manager.grid, grid_manager.center)
	wave_manager = WaveManager.new()
	projectile_manager = ProjectileManager.new()
	achievement_manager = AchievementManager.get_instance()
	perk_manager = PerkManager.get_instance()
	
	# Inicializar RewardCalculator
	reward_calculator = RewardCalculator.new(wave_manager)
	
	# Inicializar SkillsManager
	skills_manager = SkillsManager.new(self)
	
	# Inicializar PlacementManager
	placement_manager = PlacementManager.new(self, grid_manager)
	placement_manager.set_structure_arrays(
		towers, barracks, mines, slow_towers, aoe_towers,
		sniper_towers, boost_towers, shock_towers, walls, healing_stations
	)
	
	# Inicializar TowerSystemManager (será configurado depois que effects_manager for criado)
	
	# Inicializar VisualEffectsManager (será configurado depois que effects_manager for criado)
	
	# Inicializar UIManager
	ui_manager = UIManager.new(self)
	ui_manager.initialize()
	
	# Inicializar ItemManager
	item_manager = ItemManager.new()
	# Conectar sinais para aplicar bônus dinamicamente quando talismãs são equipados/desequipados
	if item_manager:
		item_manager.item_equipped.connect(_on_item_equipped)
		item_manager.item_unequipped.connect(_on_item_unequipped)
	
	# Inicializar SpecialCurrencyManager e PrestigeShop
	special_currency_manager = SpecialCurrencyManager.new()
	quest_manager = QuestManager.new()
	prestige_shop = PrestigeShop.new()
	weather_manager = WeatherManager.new()
	object_pool_manager = ObjectPoolManager.new()
	culling_manager = CullingManager.new()
	thread_manager = ThreadManager.new()
	combo_manager = ComboManager.new()
	notification_manager = NotificationManager.new()
	
	# Inicializar culling manager com tamanho da viewport
	var viewport = get_viewport()
	if viewport:
		culling_manager.update_viewport_size(viewport.get_visible_rect().size)
	
	# Carregar recompensas pendentes de quests (do Menu)
	_load_pending_quest_rewards()
	
	# Inicializar contador de tempo
	game_time = 0.0
	game_time_start = Time.get_ticks_msec() / 1000.0
	
	# Armazenar valores base antes de aplicar bônus
	# Nota: Esses valores são definidos no início do arquivo, mas garantimos que estão corretos aqui
	hero_damage_base = GameConstants.HERO_BASE_DAMAGE
	hero_fire_rate_base = GameConstants.HERO_BASE_FIRE_RATE
	hero_crit_chance_base = 0.0
	base_hp_base = GameConstants.HERO_BASE_HP
	global_tower_damage_boost_base = 1.0
	coin_drop_chance_base = GameConstants.COIN_DROP_CHANCE
	
	# Resetar valores para base antes de aplicar bônus
	hero["damage"] = hero_damage_base
	hero["fire_rate"] = hero_fire_rate_base
	hero["crit_chance"] = hero_crit_chance_base
	base_hp = base_hp_base
	global_tower_damage_boost = global_tower_damage_boost_base
	global_tower_range_boost = 1.0  # Resetar boost de alcance
	coin_drop_chance = coin_drop_chance_base
	game_time = 0.0  # Resetar tempo de jogo
	game_time_start = Time.get_ticks_msec() / 1000.0
	
	# Limpar pools ao resetar
	if object_pool_manager:
		object_pool_manager.clear_all_pools()
	
	# Aplicar bônus de prestígio
	_apply_prestige_bonuses()
	
	_apply_perk_effects()
	
	# Aplicar bônus de talismãs equipados
	_apply_talisman_bonuses()
	
	# Garantir que base_hp_max está sincronizado com base_hp após todos os bônus
	# (base_hp já contém todos os bônus aplicados, então base_hp_max deve ser igual ou maior)
	base_hp_max = max(base_hp_max, base_hp)  # Usar max para garantir que nunca seja menor
	# Garantir que base_hp atual não excede o máximo
	base_hp = min(base_hp, base_hp_max)
	
	# Atualizar HP máximo de todas as muralhas existentes (incluindo as carregadas de save)
	_update_all_walls_max_hp()
	
	# Inicializar multiplicador de HP das muralhas
	wall_hp_multiplier = 1.0
	
	# Carregar configurações de áudio
	_load_music_settings()
	_load_user_preferences()
	
	# Conectar signal do wave_manager
	wave_manager.wave_started.connect(_on_wave_started)
	# Sistema de waves especiais
	
	# Achievement: primeira partida
	if first_play:
		achievement_manager.increment_progress("first_play")
		first_play = false
	
	# ajustar tamanho da janela para caber grid + barra superior
	var bar_height: float = 44.0
	var grid_px_w: float = GameConstants.GRID_COLS * GameConstants.TILE_SIZE
	var grid_px_h: float = GameConstants.GRID_ROWS * GameConstants.TILE_SIZE
	var win_w := int(grid_px_w)
	var win_h := int(grid_px_h + bar_height)  # grid + top bar
	DisplayServer.window_set_size(Vector2i(win_w, win_h))
	
	# Configurar modo tela cheia (pode ser ativado com F11)
	# Por padrão inicia em janela, mas pode alternar
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	# Tornar HUD responsiva - usar call_deferred para garantir que viewport esteja pronto
	call_deferred("_adjust_hud_to_screen_size")
	
	# Ajustar painéis da loja e skills - usar call_deferred para garantir que viewport esteja pronto
	call_deferred("_adjust_shop_and_skills_panels")
	
	# aguardar um frame para viewport atualizar
	await get_tree().process_frame
	
	# posição fixa: grid começa em X=0 (alinhado à esquerda) e Y=bar_height (logo abaixo da barra)
	grid_offset = Vector2(0.0, bar_height)
	position = grid_offset

	var p = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
	hero["x"] = p.x
	hero["y"] = p.y

	resource_manager = ResourceManager.new()
	effects_manager = EffectsManager.new()
	coin_manager = CoinManager.new(effects_manager)
	
	resource_manager.loading_progress_updated.connect(_on_resource_loading_progress)
	coin_manager.coin_collected.connect(_on_coin_collected)
	
	_update_loading_progress(0.1)
	resource_manager.load_all_textures()
	
	tex_hero = _try_load("res://assets/images/hero.png")
	tex_enemy_zombie = resource_manager.get_texture("enemy_zombie")
	tex_enemy_zombie_gordo = resource_manager.get_texture("enemy_zombie_gordo")
	tex_enemy_zombie_corredor = resource_manager.get_texture("enemy_zombie_corredor")
	tex_enemy_humanoid = resource_manager.get_texture("enemy_humanoid")
	tex_enemy_robot = resource_manager.get_texture("enemy_robot")
	tex_enemy_alien = resource_manager.get_texture("enemy_alien")
	tex_enemy_boss = resource_manager.get_texture("enemy_boss")
	tex_tent = resource_manager.get_texture("tent")
	tex_house = resource_manager.get_texture("house")
	tex_castle = resource_manager.get_texture("castle")
	tex_castle2 = resource_manager.get_texture("Caste2")  # Castelo nível 4
	
	# Inicializar managers que dependem de texturas e effects_manager
	# Inicializar HeroManager (após texturas carregadas)
	hero_manager = HeroManager.new(base_hp)
	hero_manager.set_textures(tex_tent, tex_house, tex_castle, tex_castle2)
	hero_manager.hero = hero  # Usar o mesmo dicionário do herói
	hero_manager.hero_home_level = hero_home_level
	hero_manager.global_tower_damage_boost = global_tower_damage_boost
	
	# Inicializar TowerSystemManager (após effects_manager criado)
	tower_system_manager = TowerSystemManager.new(self, enemies, effects_manager, grid_manager)
	tower_system_manager.set_tower_arrays(
		towers, slow_towers, aoe_towers, sniper_towers,
		boost_towers, shock_towers, barracks
	)
	tower_system_manager.set_global_damage_boost(global_tower_damage_boost)
	
	# Inicializar VisualEffectsManager (após effects_manager criado)
	visual_effects_manager = VisualEffectsManager.new(self, effects_manager)
	tex_grass = resource_manager.get_texture("grass")
	tex_path = resource_manager.get_texture("path")
	tex_wall = resource_manager.get_texture("wall")
	tex_tower = resource_manager.get_texture("tower")
	tex_slow_tower = resource_manager.get_texture("slow_tower")
	tex_aoe_tower = resource_manager.get_texture("aoe_tower")
	tex_sniper_tower = resource_manager.get_texture("sniper_tower")
	tex_boost_tower = resource_manager.get_texture("boost_tower")
	tex_shock_tower = resource_manager.get_texture("shock_tower")
	tex_barracks = resource_manager.get_texture("barracks")
	tex_mine = resource_manager.get_texture("mine")
	tex_wall_structure = resource_manager.get_texture("wall_structure")
	tex_healing_station = resource_manager.get_texture("healing_station")
	tex_market = resource_manager.get_texture("market")
	tex_coin = resource_manager.get_texture("coin")
	tex_talisman = resource_manager.get_texture("talism")
	tex_game_over = resource_manager.get_texture("game_over")
	
	# Aguardar um pouco antes de esconder a tela de carregamento
	await get_tree().create_timer(0.3).timeout
	_hide_loading_screen()

	# wire UI
	var tb = $CanvasLayer/HUD/TopBar
	
	# Melhorar design da top bar (usar StyleBox pré-carregado)
	var top_bar_style = resource_manager.get_style_box("top_bar")
	if top_bar_style:
		tb.add_theme_stylebox_override("panel", top_bar_style)
	
	# Estilizar BottomBar (usar StyleBox pré-carregado)
	var bottom_bar = $CanvasLayer/HUD.get_node_or_null("BottomBar")
	if bottom_bar:
		var bottom_bar_style = resource_manager.get_style_box("bottom_bar")
		if bottom_bar_style:
			bottom_bar.add_theme_stylebox_override("panel", bottom_bar_style)
		
		# Estilizar labels da BottomBar (usar cores pré-carregadas)
		var time_label = bottom_bar.get_node_or_null("LblTime")
		if time_label:
			time_label.add_theme_color_override("font_color", resource_manager.get_color("ui_text_blue"))
			time_label.add_theme_font_size_override("font_size", 14)
		
		var enemies_label = bottom_bar.get_node_or_null("LblEnemies")
		if enemies_label:
			enemies_label.add_theme_color_override("font_color", resource_manager.get_color("ui_text_red"))
			enemies_label.add_theme_font_size_override("font_size", 14)
		
		var fps_label = bottom_bar.get_node_or_null("LblFPS")
		if fps_label:
			fps_label.add_theme_color_override("font_color", resource_manager.get_color("ui_text_green"))
			fps_label.add_theme_font_size_override("font_size", 14)
	
	# Melhorar labels
	var lbl_left = tb.get_node("LblLeft")
	lbl_left.add_theme_color_override("font_color", resource_manager.get_color("ui_text"))
	lbl_left.add_theme_font_size_override("font_size", 16)
	# Reduzir espaço - ajustar posição do LblCenter mais próximo
	lbl_left.offset_left = 12
	
	var lbl_center = tb.get_node("LblCenter")
	lbl_center.add_theme_color_override("font_color", resource_manager.get_color("ui_text_gold"))
	lbl_center.add_theme_font_size_override("font_size", 18)
	# Aumentar espaço entre Inimigos e Moedas
	lbl_center.offset_left = 250

	var lbl_right = tb.get_node("LblRight")
	lbl_right.add_theme_color_override("font_color", resource_manager.get_color("ui_text_red"))
	lbl_right.add_theme_font_size_override("font_size", 20)  # Aumentar tamanho de 16 para 20
	# Posicionar Vida após diamantes (diamantes está em 430, então colocar em 500)
	lbl_right.offset_left = 500
	
	# Criar labels para moedas especiais
	_create_special_currency_labels(tb)
	
	# Criar botão de Quests (amarelo) no HUD
	# Botão de Quests removido - agora está no menu inicial
	
	# Menu de Admin (apenas para testes/debug)
	_create_admin_menu(tb)
	
	# Aguardar um frame para garantir que todos os botões foram criados
	await get_tree().process_frame
	# Reposicionar todos os botões da direita para garantir ordem correta
	# Comentado para permitir ajustes manuais - descomente se precisar reposicionar automaticamente
	# _reposition_right_side_buttons(tb)
	
	# top bar fixa: usar anchors para ocupar toda a largura da tela
	# A configuração será feita pela função _adjust_hud_to_screen_size() que já foi chamada antes
	# Mas vamos garantir que os anchors estejam configurados aqui também
	tb.layout_mode = 1  # Usar layout com anchors
	tb.set_anchors_preset(Control.PRESET_TOP_WIDE)
	tb.offset_left = 0.0
	tb.offset_right = 0.0
	tb.offset_top = 0.0
	tb.offset_bottom = 44.0
	
	# Remover botão de comprar antigo (não é mais necessário com o menu lateral)
	if tb.has_node("BuyMenuButton"):
		tb.get_node("BuyMenuButton").queue_free()
	
	# Remover botão de mute se existir
	if tb.has_node("BtnMuteMusic"):
		tb.get_node("BtnMuteMusic").queue_free()
	
	# Adicionar slider de volume (usar anchors para posicionamento responsivo)
	if not tb.has_node("MusicVolumeSlider"):
		var volume_container = HBoxContainer.new()
		volume_container.name = "MusicVolumeContainer"
		volume_container.layout_mode = 1  # Usar layout com anchors
		volume_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		# Volume: 130px de largura fixa, bem posicionado
		# Ordem (da direita para esquerda): DPS, Auto Benefício, Quests, Admin, Volume
		volume_container.offset_left = -580  # Posição ajustada
		volume_container.offset_top = 8
		volume_container.offset_right = -450  # 130px de largura fixa
		volume_container.offset_bottom = 36
		volume_container.custom_minimum_size = Vector2(130, 28)
		
		var volume_label = Label.new()
		volume_label.text = "🔊"
		volume_label.custom_minimum_size = Vector2(25, 28)
		volume_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		volume_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		volume_container.add_child(volume_label)
		
		var volume_slider = HSlider.new()
		volume_slider.name = "MusicVolumeSlider"
		volume_slider.custom_minimum_size = Vector2(100, 28)  # Tamanho fixo único
		volume_slider.min_value = -60.0  # Mínimo: muito baixo
		volume_slider.max_value = 0.0    # Máximo: volume normal
		volume_slider.value = music_volume
		volume_slider.step = 1.0
		volume_slider.value_changed.connect(_on_music_volume_changed)
		volume_container.add_child(volume_slider)
		
		tb.add_child(volume_container)
		music_volume_slider = volume_slider
	
	# remover botões antigos se existirem
	if tb.has_node("BtnBuyTower"):
		tb.get_node("BtnBuyTower").queue_free()
	if tb.has_node("BtnBuyBlock"):
		tb.get_node("BtnBuyBlock").queue_free()
	if tb.has_node("BtnBuyBarracks"):
		tb.get_node("BtnBuyBarracks").queue_free()
	
	# Criar UI melhorada - Menu lateral de torres
	_create_tower_shop_ui()
	
	# Criar tooltip global para elementos do jogo
	_create_game_tooltip()
	
	# Criar menu de skills
	_create_skills_ui()
	
	# Criar botão de DPS no TopBar
	_create_dps_button()
	
	# Ajustar painéis após criação
	_adjust_shop_and_skills_panels()
	_create_range_indicator()

	# criar PopupMenu para torres (deve estar em um Control)
	var menu_container = Control.new()
	menu_container.name = "TowerMenuContainer"
	menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tower_menu = PopupMenu.new()
	tower_menu.name = "TowerMenu"
	tower_menu.hide_on_checkable_item_selection = false  # Não fechar automaticamente
	# Alcance
	tower_menu.add_item("Alcance +60 (💰 Moedas)", 1)
	tower_menu.add_item("Alcance +60 (🟢 Esmeraldas)", 11)
	tower_menu.add_separator()
	# Cadência
	tower_menu.add_item("Cadência + (💰 Moedas)", 2)
	tower_menu.add_item("Cadência + (🟢 Esmeraldas)", 12)
	tower_menu.add_separator()
	# Direções
	tower_menu.add_item("+4 Direções", 3)
	tower_menu.add_separator()
	# Dano
	tower_menu.add_item("Dano +0.5 (💰 Moedas)", 4)
	tower_menu.add_item("Dano +0.5 (🟢 Esmeraldas)", 14)
	tower_menu.add_separator()
	# Efeitos especiais
	tower_menu.add_item("Congelamento", 5)
	tower_menu.add_item("Fogo", 6)
	tower_menu.id_pressed.connect(Callable(self, "_on_tower_menu_pressed"))
	tower_menu.popup_hide.connect(Callable(self, "_on_upgrade_menu_closed"))
	menu_container.add_child(tower_menu)
	$CanvasLayer.add_child(menu_container)
	
	# criar PopupMenu para quartéis
	var barracks_menu_container = Control.new()
	barracks_menu_container.name = "BarracksMenuContainer"
	barracks_menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	barracks_menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barracks_menu = PopupMenu.new()
	barracks_menu.name = "BarracksMenu"
	barracks_menu.hide_on_checkable_item_selection = false  # Não fechar automaticamente
	barracks_menu.add_item("Dano +0.2 (💰 Moedas)", 1)
	barracks_menu.add_item("Dano +0.2 (🟢 Esmeraldas)", 10)
	barracks_menu.add_separator()
	barracks_menu.add_item("Tempo Hold +1s (💰 Moedas)", 2)
	barracks_menu.add_item("Tempo Hold +1s (🟢 Esmeraldas)", 11)
	barracks_menu.add_separator()
	barracks_menu.add_item("Spawn Rate -0.5s (💰 Moedas)", 3)
	barracks_menu.add_item("Spawn Rate -0.5s (🟢 Esmeraldas)", 12)
	barracks_menu.add_separator()
	barracks_menu.add_item("Velocidade Projétil +20 (💰 Moedas)", 4)
	barracks_menu.add_item("Velocidade Projétil +20 (🟢 Esmeraldas)", 13)
	barracks_menu.id_pressed.connect(Callable(self, "_on_barracks_menu_pressed"))
	barracks_menu.popup_hide.connect(Callable(self, "_on_upgrade_menu_closed"))
	barracks_menu_container.add_child(barracks_menu)
	$CanvasLayer.add_child(barracks_menu_container)
	
	# criar PopupMenu para sniper towers
	var sniper_menu_container = Control.new()
	sniper_menu_container.name = "SniperMenuContainer"
	sniper_menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	sniper_menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sniper_menu = PopupMenu.new()
	sniper_menu.name = "SniperMenu"
	sniper_menu.hide_on_checkable_item_selection = false  # Não fechar automaticamente
	sniper_menu.add_item("Dano +2 (💰 Moedas)", 1)
	sniper_menu.add_item("Dano +2 (🟢 Esmeraldas)", 10)
	sniper_menu.add_separator()
	sniper_menu.add_item("Taxa de Tiro + (💰 Moedas)", 2)
	sniper_menu.add_item("Taxa de Tiro + (🟢 Esmeraldas)", 11)
	sniper_menu.add_separator()
	sniper_menu.add_item("Alvo: Boss", 3)
	sniper_menu.add_item("Alvo: Mais Próximo ao Centro", 4)
	sniper_menu.id_pressed.connect(Callable(self, "_on_sniper_menu_pressed"))
	sniper_menu.popup_hide.connect(Callable(self, "_on_upgrade_menu_closed"))
	sniper_menu_container.add_child(sniper_menu)
	$CanvasLayer.add_child(sniper_menu_container)
	
	# criar PopupMenu para AOE towers
	var aoe_menu_container = Control.new()
	aoe_menu_container.name = "AOEMenuContainer"
	aoe_menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	aoe_menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aoe_menu = PopupMenu.new()
	aoe_menu.name = "AOEMenu"
	aoe_menu.hide_on_checkable_item_selection = false  # Não fechar automaticamente
	aoe_menu.add_item("Dano +1 (💰 Moedas)", 1)
	aoe_menu.add_item("Dano +1 (🟢 Esmeraldas)", 10)
	aoe_menu.add_separator()
	aoe_menu.add_item("Taxa de Tiro + (💰 Moedas)", 2)
	aoe_menu.add_item("Taxa de Tiro + (🟢 Esmeraldas)", 11)
	aoe_menu.add_separator()
	aoe_menu.add_item("Área +20 (💰 Moedas)", 3)
	aoe_menu.add_item("Área +20 (🟢 Esmeraldas)", 12)
	aoe_menu.id_pressed.connect(Callable(self, "_on_aoe_menu_pressed"))
	aoe_menu.popup_hide.connect(Callable(self, "_on_upgrade_menu_closed"))
	aoe_menu_container.add_child(aoe_menu)
	$CanvasLayer.add_child(aoe_menu_container)
	
	# criar PopupMenu para Shock towers
	var shock_menu_container = Control.new()
	shock_menu_container.name = "ShockMenuContainer"
	shock_menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	shock_menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shock_menu = PopupMenu.new()
	shock_menu.name = "ShockMenu"
	shock_menu.hide_on_checkable_item_selection = false  # Não fechar automaticamente
	shock_menu.add_item("Dano +0.5 (💰 Moedas)", 1)
	shock_menu.add_item("Dano +0.5 (🟢 Esmeraldas)", 10)
	shock_menu.add_separator()
	shock_menu.add_item("Taxa de Tiro + (💰 Moedas)", 2)
	shock_menu.add_item("Taxa de Tiro + (🟢 Esmeraldas)", 11)
	shock_menu.add_separator()
	shock_menu.add_item("Corrente +1 (💰 Moedas)", 3)
	shock_menu.add_item("Corrente +1 (🟢 Esmeraldas)", 12)
	shock_menu.id_pressed.connect(Callable(self, "_on_shock_menu_pressed"))
	shock_menu.popup_hide.connect(Callable(self, "_on_upgrade_menu_closed"))
	shock_menu_container.add_child(shock_menu)
	$CanvasLayer.add_child(shock_menu_container)
	
	# criar PopupMenu para Slow towers
	var slow_menu_container = Control.new()
	slow_menu_container.name = "SlowMenuContainer"
	slow_menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	slow_menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slow_menu = PopupMenu.new()
	slow_menu.name = "SlowMenu"
	slow_menu.hide_on_checkable_item_selection = false  # Não fechar automaticamente
	slow_menu.add_item("Alcance +30 (💰 Moedas)", 1)
	slow_menu.add_item("Alcance +30 (🟢 Esmeraldas)", 10)
	slow_menu.add_separator()
	slow_menu.add_item("Slow x1.05 (💰 Moedas)", 2)
	slow_menu.add_item("Slow x1.05 (🟢 Esmeraldas)", 11)
	# Removido duração - funciona enquanto está dentro da área
	# Removido completamente "Taxa de Aplicação" (era id 4) - não faz sentido
	slow_menu.id_pressed.connect(Callable(self, "_on_slow_menu_pressed"))
	slow_menu.popup_hide.connect(Callable(self, "_on_upgrade_menu_closed"))
	slow_menu_container.add_child(slow_menu)
	$CanvasLayer.add_child(slow_menu_container)
	
	# criar PopupMenu para Boost towers
	var boost_menu_container = Control.new()
	boost_menu_container.name = "BoostMenuContainer"
	boost_menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	boost_menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boost_menu = PopupMenu.new()
	boost_menu.name = "BoostMenu"
	boost_menu.hide_on_checkable_item_selection = false  # Não fechar automaticamente
	boost_menu.add_item("Boost Dano +10% (💰 Moedas)", 1)
	boost_menu.add_item("Boost Dano +10% (🟢 Esmeraldas)", 10)
	boost_menu.add_separator()
	boost_menu.add_item("Boost Cadência +5% (💰 Moedas)", 2)
	boost_menu.add_item("Boost Cadência +5% (🟢 Esmeraldas)", 11)
	# Removido upgrade de alcance - range é global (9999)
	boost_menu.id_pressed.connect(Callable(self, "_on_boost_menu_pressed"))
	boost_menu.popup_hide.connect(Callable(self, "_on_upgrade_menu_closed"))
	boost_menu_container.add_child(boost_menu)
	$CanvasLayer.add_child(boost_menu_container)
	
	# Criar container para menu de muralhas
	var wall_menu_container = Control.new()
	wall_menu_container.name = "WallMenuContainer"
	wall_menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	wall_menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wall_menu = PopupMenu.new()
	wall_menu.name = "WallMenu"
	wall_menu.hide_on_checkable_item_selection = false
	wall_menu.add_item("Reforçar HP +25 (💰 Moedas)", 1)
	wall_menu.add_item("Reparar (💰 Moedas)", 2)
	wall_menu.id_pressed.connect(Callable(self, "_on_wall_menu_pressed"))
	wall_menu.popup_hide.connect(Callable(self, "_on_upgrade_menu_closed"))
	wall_menu_container.add_child(wall_menu)
	$CanvasLayer.add_child(wall_menu_container)

	var ov = $CanvasLayer/UpgradeOverlay
	ov.get_node("Panel/Btn1").pressed.connect(func(): _apply_benefit(0))
	ov.get_node("Panel/Btn2").pressed.connect(func(): _apply_benefit(1))
	ov.get_node("Panel/Btn3").pressed.connect(func(): _apply_benefit(2))
	ov.get_node("Panel/Btn4").pressed.connect(func(): _apply_benefit(3))
	ov.get_node("Panel/BtnResume").pressed.connect(func(): _resume_after_upgrade())
	
	# Conectar botão de auto benefício
	if tb.has_node("BtnAutoBenefit"):
		var btn_auto = tb.get_node("BtnAutoBenefit")
		btn_auto.pressed.connect(_toggle_auto_benefit)
		# Aplicar hover effects e cor azul
		const ButtonHoverHelper = preload("res://scripts/helpers/ButtonHoverHelper.gd")
		ButtonHoverHelper.setup_button_hover(btn_auto)
		_update_auto_benefit_button()

	# wire Pause overlay
	pause_overlay = $CanvasLayer/PauseOverlay
	pause_overlay.get_node("Panel/BtnResume").pressed.connect(_on_pause_resume)
	pause_overlay.get_node("Panel/BtnSave").pressed.connect(_on_pause_save)
	pause_overlay.get_node("Panel/BtnLoad").pressed.connect(_on_pause_load)
	pause_overlay.get_node("Panel/BtnMenuMain").pressed.connect(_on_pause_menu)
	pause_overlay.get_node("Panel/BtnQuit").pressed.connect(_on_pause_quit)
	save_status_label = pause_overlay.get_node("Panel/SaveStatusLabel")
	pause_overlay.visible = false

	# wire Game Over overlay
	if has_node("CanvasLayer/GameOverOverlay"):
		var go = $CanvasLayer/GameOverOverlay
		go.get_node("Panel/BtnMenu").pressed.connect(_on_game_over_menu)
		go.get_node("Panel/BtnRestart").pressed.connect(_on_game_over_restart)
		go.visible = false
		
		# Adicionar camada preta para cobrir o labirinto e a loja
		var black_overlay = ColorRect.new()
		black_overlay.name = "BlackOverlay"
		black_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		black_overlay.color = Color(0, 0, 0, 1.0)  # Preto opaco
		black_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Não bloquear cliques
		go.add_child(black_overlay)
		
		# Adicionar imagem de fundo do Game Over (tela toda, sem cortar)
		var bg_texture_rect = TextureRect.new()
		bg_texture_rect.name = "BackgroundImage"
		bg_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED  # Manter proporção, centralizar, não cortar
		bg_texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		bg_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Não bloquear cliques
		go.add_child(bg_texture_rect)
		
		# Ordem: BlackOverlay (fundo) -> BackgroundImage (meio) -> Panel (frente)
		go.move_child(black_overlay, 0)  # Camada preta atrás de tudo
		go.move_child(bg_texture_rect, 1)  # Imagem do Game Over no meio
		
		# Ocultar o título "Fim de Jogo" (a imagem já tem)
		if go.has_node("Panel/Title"):
			go.get_node("Panel/Title").visible = false
		
		# Melhorar estilo do Panel
		var panel = go.get_node("Panel")
		# Adicionar estilo ao Panel com bordas arredondadas e sombra
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.1, 0.1, 0.15, 0.85)  # Fundo escuro semi-transparente
		style_box.border_color = Color(0.0, 0.2, 0.4, 1.0)  # Borda azul marinho
		style_box.border_width_left = 3
		style_box.border_width_top = 3
		style_box.border_width_right = 3
		style_box.border_width_bottom = 3
		style_box.corner_radius_top_left = 10
		style_box.corner_radius_top_right = 10
		style_box.corner_radius_bottom_left = 10
		style_box.corner_radius_bottom_right = 10
		style_box.shadow_color = Color(0, 0, 0, 0.5)
		style_box.shadow_size = 8
		style_box.shadow_offset = Vector2(4, 4)
		panel.add_theme_stylebox_override("panel", style_box)
		
		# Melhorar estilo dos botões
		var btn_restart = go.get_node("Panel/BtnRestart")
		var btn_menu = go.get_node("Panel/BtnMenu")
		
		# Usar StyleBoxes pré-carregados
		var btn_style = resource_manager.get_style_box("button_normal")
		var btn_hover_style = resource_manager.get_style_box("button_hover")
		
		if btn_style:
			btn_restart.add_theme_stylebox_override("normal", btn_style)
			btn_menu.add_theme_stylebox_override("normal", btn_style)
		if btn_hover_style:
			btn_restart.add_theme_stylebox_override("hover", btn_hover_style)
			btn_menu.add_theme_stylebox_override("hover", btn_hover_style)
		
		# Melhorar estilo do label de onda
		var lbl_wave = go.get_node("Panel/LblWave")
		lbl_wave.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7, 1.0))  # Cor dourada
		lbl_wave.add_theme_font_size_override("font_size", 18)

	# Carregar e tocar música de fundo do jogo (usar pré-carregado se disponível)
	var music_player = get_node_or_null("MusicPlayer")
	if music_player:
		var music = resource_manager.get_audio_stream("game_music")
		if music == null:
			music = _try_load_music("res://assets/music/game_music.ogg")
			if music == null:
				# Tentar formato alternativo
				music = _try_load_music("res://assets/music/game_music.mp3")
			if music == null:
				# Se não houver música específica do jogo, tentar música do menu
				music = _try_load_music("res://assets/music/menu_music.ogg")
				if music == null:
					music = _try_load_music("res://assets/music/menu_music.mp3")
		if music != null:
			# Configurar loop se for AudioStreamOggVorbis ou AudioStreamMP3
			if music is AudioStreamOggVorbis:
				music.loop = true
			elif music is AudioStreamMP3:
				music.loop = true
			music_player.stream = music
			music_player.volume_db = music_volume  # Aplicar volume configurado
			music_player.play()
			print("Game: Música de fundo iniciada")
		else:
			print("Game: Música de fundo não encontrada")
	
	_create_boss_alert_ui()
	_load_boss_warning_sound()
	_create_special_wave_alert_ui()
	_create_weather_ui()
	
	# Verificar se há um slot para carregar (vindo do menu)
	var load_slot = get_tree().get_meta("load_slot", "")
	if load_slot != "":
		get_tree().remove_meta("load_slot")
		if SaveManager.has_save(load_slot) and SaveManager.load_game(self, load_slot):
			print("Jogo carregado do slot: ", load_slot)
			_apply_loaded_game_state()
	
	set_process(true)
	set_physics_process(true)

func _process(delta: float) -> void:
	# Atualizar tooltips (sempre, mesmo quando pausado)
	_update_game_tooltip(delta)
	
	if paused or game_over:
		return

	# Garantir que o range indicator só esteja visível quando um menu de upgrade estiver aberto
	# Verificar a cada frame para garantir que seja escondido imediatamente quando o menu fechar
	if range_indicator and range_indicator.visible:
		if not _is_any_upgrade_menu_visible():
			_hide_range_indicator()
			# Resetar índices selecionados também
			tower_selected_index = -1
			sniper_selected_index = -1
			aoe_selected_index = -1
			shock_selected_index = -1
			slow_selected_index = -1
			boost_selected_index = -1
			barracks_selected_index = -1

	if boss_alert_timer > 0.0:
		boss_alert_timer -= delta
		if boss_alert_timer <= 0.0 and boss_alert_label:
			boss_alert_label.visible = false
		
		# Atualizar timer de alerta de wave especial com fade out
		# Primeiro, verificar se ainda há wave especial ativa - se não, esconder imediatamente
		if current_special_wave_type == WaveManager.SpecialWaveType.NONE:
			if special_wave_alert_label and special_wave_alert_label.visible:
				special_wave_alert_label.visible = false
				special_wave_alert_timer = 0.0
		elif special_wave_alert_timer > 0.0:
			special_wave_alert_timer -= delta
			if special_wave_alert_label and special_wave_alert_label.visible:
				if special_wave_alert_timer <= GameConstants.SPECIAL_WAVE_ALERT_FADE_OUT_START:
					# Iniciar fade out gradual (quando timer <= 1.0s)
					var fade_time = GameConstants.SPECIAL_WAVE_ALERT_FADE_OUT_START
					var fade_progress = special_wave_alert_timer / fade_time  # De 1.0 (1.0s) a 0.0 (0s)
					fade_progress = clamp(fade_progress, 0.0, 1.0)
					# Aplicar alpha baseado no progresso do fade
					var base_color = Color(1.0, 0.8, 0.2)  # Cor base dourada
					var new_color = Color(base_color.r, base_color.g, base_color.b, fade_progress)
					special_wave_alert_label.add_theme_color_override("font_color", new_color)
					var outline_alpha = 0.9 * fade_progress
					special_wave_alert_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, outline_alpha))
				else:
					# Totalmente visível (quando timer > 1.0s)
					var current_color = special_wave_alert_label.get_theme_color("font_color")
					if current_color.a < 1.0:
						special_wave_alert_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
						special_wave_alert_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		if special_wave_alert_timer <= 0.0 and special_wave_alert_label:
			special_wave_alert_label.visible = false
			# Resetar alpha para próxima vez
			special_wave_alert_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
			special_wave_alert_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		
		# Atualizar timer de alerta de clima
		if weather_alert_timer > 0.0:
			weather_alert_timer -= delta
		if weather_alert_timer <= 0.0 and weather_alert_label:
			weather_alert_label.visible = false
		
		# Atualizar efeitos visuais do clima
		_update_weather_visuals(delta)

	# Atualizar skills usando SkillsManager
	if skills_manager:
		skills_manager.update_skills(delta)
	
	if skills_manager and skills_manager.is_magnetism_active() and coin_manager:
		var mouse_screen_pos = get_viewport().get_mouse_position()
		var world_pos = to_local(mouse_screen_pos)
		var coin_value = coin_manager.try_collect_coin(world_pos)
		_try_collect_talisman(world_pos)
		if coin_value > 0:
			var achievement_batch_timer = get_meta("achievement_batch_timer", 0.0)
			achievement_batch_timer += delta
			if achievement_batch_timer >= 0.2:
				achievement_manager.increment_progress("collect_1000_coins", coin_value)
				achievement_manager.increment_progress("collect_10000_coins", coin_value)
				achievement_manager.increment_progress("collect_100000_coins", coin_value)
				achievement_manager.increment_progress("collect_1000000_coins", coin_value)
				if hero["coins"] >= 10000:
					achievement_manager.set_progress("hold_10000_coins", 1)
				if hero["coins"] >= 50000:
					achievement_manager.set_progress("hold_50000_coins", 1)
				achievement_batch_timer = 0.0
			set_meta("achievement_batch_timer", achievement_batch_timer)
			_play_coin_sound()
			var redraw_timer = get_meta("redraw_throttle", 0.0)
			redraw_timer += delta
			if redraw_timer >= 0.05:
				queue_redraw()
				redraw_timer = 0.0
			set_meta("redraw_throttle", redraw_timer)
	
	# Otimizar atualização de UI (usar variável de classe ao invés de meta)
	_ui_update_timer += delta
	if _ui_update_timer >= _ui_update_interval:
		_update_skills_ui()
		_update_bottom_bar()
		# Atualizar UI da loja de torres com throttle (menos frequente - a cada 200ms)
		if _ui_update_timer >= 0.2:
			_update_tower_shop_ui()
			_ui_update_timer = 0.0
		else:
			_ui_update_timer -= _ui_update_interval
	
	# Processar resultados de pathfinding da thread (otimização de FPS)
	if thread_manager:
		thread_manager.process_pathfinding_results()
	
	var dps_update_timer = get_meta("dps_update_timer", 0.0)
	dps_update_timer += delta
	if dps_update_timer >= 0.5:
		_update_tower_dps(delta)
		dps_update_timer = 0.0
	set_meta("dps_update_timer", dps_update_timer)
	
	if combo_manager:
		var combo_check_timer = get_meta("combo_check_timer", 0.0)
		combo_check_timer += delta
		if combo_check_timer >= 0.5:
			_check_tower_combos()
			combo_check_timer = 0.0
		set_meta("combo_check_timer", combo_check_timer)
	
	if notification_manager:
		notification_manager.update_notifications(delta)
	
	if not paused and not game_over:
		game_time += delta
		var achievement_check_timer = get_meta("achievement_check_timer", 0.0)
		achievement_check_timer += delta
		if achievement_check_timer >= 1.0:
			_check_time_achievements()
			achievement_check_timer = 0.0
		set_meta("achievement_check_timer", achievement_check_timer)

	var camera_pos = Vector2.ZERO
	var culling_update_timer = get_meta("culling_update_timer", 0.0)
	culling_update_timer += delta
	if culling_manager and culling_update_timer >= 0.2:
		var viewport = get_viewport()
		if viewport:
			culling_manager.update_viewport_size(viewport.get_visible_rect().size)
		culling_update_timer = 0.0
	set_meta("culling_update_timer", culling_update_timer)
	
	for e in enemies:
		if not culling_manager or culling_manager.should_update_logic(e["pos"], camera_pos):
			_enemy_update(e, delta)
	
	for a in arrows:
		if not culling_manager or culling_manager.is_visible(a["pos"], camera_pos):
			_arrow_update(a, delta)
	for b in tower_bullets:
		if not culling_manager or culling_manager.is_visible(b["pos"], camera_pos):
			_arrow_update(b, delta)
	_handle_collisions()
	# filtrar setas vivas
	var new_arrows: Array = []
	for a in arrows:
		if a["life"] > 0.0:
			new_arrows.append(a)
	arrows = new_arrows
	var new_tb: Array = []
	for b in tower_bullets:
		if b["life"] > 0.0:
			new_tb.append(b)
	tower_bullets = new_tb
	
	if effects_manager:
		effects_manager.update_effects(delta)
		aoe_effects = effects_manager.get_aoe_effects()
		sniper_effects = effects_manager.get_sniper_effects()
		coin_collect_effects = effects_manager.get_coin_collect_effects()
	
	# atualizar efeitos visuais usando VisualEffectsManager
	if visual_effects_manager:
		visual_effects_manager.update_effects(delta)
		# Sincronizar arrays locais com o manager (para desenho)
		damage_numbers = visual_effects_manager.get_damage_numbers()
		enemy_death_animations = visual_effects_manager.get_death_animations()
		shock_effects = visual_effects_manager.get_shock_effects()
	else:
		# Fallback (código antigo)
		var new_damage_numbers: Array = []
		for dmg in damage_numbers:
			dmg.time += delta
			dmg.pos += dmg.velocity * delta
			dmg.velocity.y += 50.0 * delta
			if dmg.time < dmg.max_time:
				new_damage_numbers.append(dmg)
		damage_numbers = new_damage_numbers
		
		var new_death_animations: Array = []
		for anim in enemy_death_animations:
			anim.time += delta
			var progress = anim.time / anim.max_time
			anim.scale = 1.0 - progress
			anim.alpha = 1.0 - progress
			if anim.time < anim.max_time:
				new_death_animations.append(anim)
		enemy_death_animations = new_death_animations
		
		var new_shock_effects: Array = []
		for effect in shock_effects:
			effect.time += delta
			if effect.time < effect.max_time:
				new_shock_effects.append(effect)
		shock_effects = new_shock_effects
	
	if coin_manager:
		coin_manager.update_coins(delta)
		dropped_coins = coin_manager.get_dropped_coins()
	
	# Atualizar talismãs dropados
	_update_dropped_talismans(delta)
	# remover inimigos mortos/que chegaram na base e limpar efeitos
	var alive: Array = []
	var new_enemy_effects: Dictionary = {}
	var enemy_idx_map: Dictionary = {}  # mapear índice antigo -> novo
	
	for i in range(enemies.size()):
		var e = enemies[i]
		var is_dying = e.get("dying", false)
		if is_dying:
			# Inimigo está morrendo, atualizar tempo
			e["dying_time"] = e.get("dying_time", 0.0) + delta
			if e["dying_time"] < 0.5:  # manter durante animação
				alive.append(e)  # manter visível durante animação
				var new_idx = alive.size() - 1
				e["idx"] = new_idx
				enemy_idx_map[i] = new_idx
			# remover efeitos quando animação terminar
			if enemy_effects.has(i):
				enemy_effects.erase(i)
		elif e["hp"] > 0 and not e["reached"]:
			var new_idx = alive.size()
			alive.append(e)
			# atualizar índice do inimigo
			e["idx"] = new_idx
			enemy_idx_map[i] = new_idx
			# manter efeitos se existirem
			if enemy_effects.has(i):
				new_enemy_effects[new_idx] = enemy_effects[i]
		else:
			# remover efeitos de inimigos mortos
			if enemy_effects.has(i):
				enemy_effects.erase(i)
	enemies = alive
	enemy_effects = new_enemy_effects
	
	# atualizar índices dos soldados quando inimigos são removidos
	for s in soldiers:
		if s.hp > 0 and s.target_enemy_idx >= 0:
			# verificar se o índice do inimigo ainda é válido
			if enemy_idx_map.has(s.target_enemy_idx):
				# atualizar para o novo índice
				s.target_enemy_idx = enemy_idx_map[s.target_enemy_idx]
			elif s.target_enemy_idx >= enemies.size():
				# índice inválido, resetar para procurar novo
				s.target_enemy_idx = -1
	
	# atualizar quartéis e soldados
	# Nota: TowerSystemManager ainda não implementa completamente as torres,
	# então chamamos as funções reais diretamente do Game.gd
	_update_barracks(delta)
	_update_soldiers(delta)

	# waves
	if not wave_manager.spawning and enemies.is_empty() and not choosing_upgrade:
		if wave_manager.wave > 0:
			# Aplicar cura das healing stations no final da wave
			for hs in healing_stations:
				var base_center = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
				var dist_to_base = hs.pos.distance_to(base_center)
				if dist_to_base <= hs.range:
					# Garantir que base_hp_max está atualizado (pode ter mudado durante a wave)
					# Recalcular se necessário
					if base_hp_max < base_hp:
						base_hp_max = base_hp  # Corrigir inconsistência
					# Aplicar cura respeitando o limite máximo
					var new_hp = base_hp + hs.heal_amount
					base_hp = min(base_hp_max, new_hp)
			
			# Decrementar buffs temporários ao completar wave
			if tower_damage_boost_waves_remaining > 0:
				tower_damage_boost_waves_remaining -= 1
				if tower_damage_boost_waves_remaining <= 0:
					global_tower_damage_boost = 1.0
					if notification_manager:
						notification_manager.show_notification("Buff de Dano Torres expirou!", 3.0, NotificationManager.NotificationPosition.TOP_CENTER, Color(0.8, 0.2, 0.2))
			
			if hero_damage_boost_waves_remaining > 0:
				hero_damage_boost_waves_remaining -= 1
				if hero_damage_boost_waves_remaining <= 0:
					# Remover boost do herói (será implementado)
					if notification_manager:
						notification_manager.show_notification("Buff de Dano Herói expirou!", 3.0, NotificationManager.NotificationPosition.TOP_CENTER, Color(0.8, 0.2, 0.2))
			
			# garantir que upgrade_options tenha 3 elementos e embaralhar
			# Usar pool do HeroManager se disponível
			var pool := []
			if hero_manager:
				pool = hero_manager.upgrade_options.duplicate()
			else:
				# Fallback
				pool = [
					{"label": "Dano", "code": "DMG", "max_level": 30, "description": "Aumenta o dano dos tiros (+1 por nível)"},
					{"label": "Velocidade", "code": "FIRERATE", "max_level": 20, "description": "Reduz o tempo entre tiros (cadência mais rápida)"},
					{"label": "Perfuração", "code": "PIERCE", "max_level": 3, "description": "Permite acertar múltiplos inimigos (1, 2 ou 3)"},
					{"label": "Chance Crítico", "code": "CRIT_CHANCE", "max_level": 10, "description": "Aumenta chance de crítico (2% por nível, máx 20%)"},
					{"label": "Dano Crítico", "code": "CRIT_DMG", "max_level": 10, "description": "Aumenta multiplicador de dano crítico (+0.2 por nível)"},
				]
			# Filtrar apenas upgrades que não atingiram o limite
			var available_upgrades = []
			for upgrade in pool:
				var current_level = hero["levels"].get(upgrade["code"], 0)
				if current_level < upgrade["max_level"]:
					available_upgrades.append(upgrade)
			
			# Se não houver upgrades disponíveis, permitir continuar sem mostrar overlay
			if available_upgrades.is_empty():
				# Não há upgrades disponíveis - permitir continuar diretamente
				# Auto-save quando a wave termina
				_auto_save_after_wave()
				# Bonus por completar wave
				var wave_bonus = get_wave_completion_bonus()
				hero["coins"] += wave_bonus
				_track_coin_collected(wave_bonus)
				# Atualizar progresso de quests
				if quest_manager:
					quest_manager.update_quest_progress(GameConstants.QuestType.COMPLETE_WAVES, 1)
					quest_manager.update_quest_progress(GameConstants.QuestType.REACH_WAVE, 1)
				# Dar diamante garantido ao passar do nível 150 (apenas uma vez por run)
				if wave_manager.wave == 150 and special_currency_manager and not diamond_150_given:
					special_currency_manager.add_diamonds(1, "wave_150_milestone")
					diamond_150_given = true
					print("💎 Diamante obtido por alcançar a wave 150!")
				# Continuar para próxima wave sem mostrar overlay
				wave_manager.start_next_wave()
			else:
				# Há upgrades disponíveis
				available_upgrades.shuffle()
				# Mostrar apenas 3 upgrades aleatórios (ou menos se não houver)
				upgrade_options = available_upgrades.slice(0, min(3, available_upgrades.size()))
				# Auto-save quando a wave termina (antes do upgrade overlay)
				_auto_save_after_wave()
				# Bonus por completar wave
				var wave_bonus = get_wave_completion_bonus()
				hero["coins"] += wave_bonus
				_track_coin_collected(wave_bonus)
				# Atualizar progresso de quests
				if quest_manager:
					quest_manager.update_quest_progress(GameConstants.QuestType.COMPLETE_WAVES, 1)
					quest_manager.update_quest_progress(GameConstants.QuestType.REACH_WAVE, 1)
				# Dar diamante garantido ao passar do nível 150 (apenas uma vez por run)
				if wave_manager.wave == 150 and special_currency_manager and not diamond_150_given:
					special_currency_manager.add_diamonds(1, "wave_150_milestone")
					diamond_150_given = true
					print("💎 Diamante obtido por alcançar a wave 150!")
				
				# Se auto_choose_benefits estiver ativo, escolher automaticamente
				if auto_choose_benefits:
					# Escolher um benefício aleatório dos disponíveis
					var random_index = randi() % upgrade_options.size()
					selected_benefit_index = random_index
					benefit_applied = true
					# Aplicar o benefício diretamente
					_apply_selected_benefit()
					# Continuar para próxima wave sem mostrar overlay
					choosing_upgrade = false
					benefit_applied = false
					selected_benefit_index = -1
					wave_manager.start_next_wave()
				else:
					# Mostrar overlay para escolha manual
					choosing_upgrade = true
					# Resetar seleção anterior
					benefit_applied = false
					selected_benefit_index = -1
					$CanvasLayer/UpgradeOverlay.visible = true
					_update_upgrade_labels()
		else:
			wave_manager.time_to_next_wave = 0.0

	wave_manager.update_intermission(delta)
	if not choosing_upgrade and not wave_manager.spawning and enemies.is_empty():
		# Verificar bônus de wave perfeita quando a wave termina
		if current_special_wave_type == WaveManager.SpecialWaveType.PERFECT_WAVE:
			_check_perfect_wave_bonus()
		if wave_manager.should_start_wave():
			wave_manager.start_next_wave()

	if wave_manager.spawning:
		var should_spawn = wave_manager.update(delta)
		if should_spawn:
			var s = _random_spawn()
			if s != null:
				# Boss Rush: spawnar apenas bosses
				if current_special_wave_type == WaveManager.SpecialWaveType.BOSS_RUSH:
					# Spawnar mais bosses durante Boss Rush (4 ao invés de 2)
					if wave_manager.bosses_spawned_this_wave < 4:
						enemies.append(_enemy_new_boss(s.x, s.y))
				elif wave_manager.is_boss_wave() and wave_manager.bosses_spawned_this_wave < 2:
					enemies.append(_enemy_new_boss(s.x, s.y))
				else:
					# Escolher tipo de inimigo baseado na wave (sistema padronizado)
					var enemy_type = _get_random_enemy_type_for_wave()
					enemies.append(_enemy_new(s.x, s.y, enemy_type))

	# UI - TopBar (apenas informações essenciais)
	var tb = $CanvasLayer/HUD/TopBar
	var is_boss_wave := wave_manager.is_boss_wave()
	var wave_text = "Onda %d (CHEFE!)" % wave_manager.wave if is_boss_wave else "Onda %d" % wave_manager.wave
	# Adicionar indicação de wave especial
	if current_special_wave_type != WaveManager.SpecialWaveType.NONE:
		var special_icon = wave_manager.get_special_wave_name().split(" ")[0]  # Pegar o emoji
		wave_text = "%s %s" % [special_icon, wave_text]
	var weather_text = ""
	if weather_manager and weather_manager.current_weather != WeatherManager.WeatherType.NONE:
		weather_text = "  " + weather_manager.get_weather_name()
	tb.get_node("LblLeft").text = "%s%s" % [wave_text, weather_text]
	tb.get_node("LblCenter").text = "💰 %d" % [int(hero["coins"])]
	var lbl_right = tb.get_node_or_null("LblRight")
	if lbl_right:
		lbl_right.text = "❤️ %d" % [base_hp]
		lbl_right.visible = true  # Garantir que sempre esteja visível
		# Garantir que o texto seja atualizado mesmo se o label estiver escondido
		if not lbl_right.visible:
			lbl_right.show()
	
	# UI - BottomBar (informações secundárias)
	_update_bottom_bar()
	
	# Atualizar labels de moedas especiais
	_update_special_currency_labels()
	
	# Remover slider de vida se existir (não é mais necessário)
	var life_slider = tb.get_node_or_null("LifeSlider")
	if life_slider:
		life_slider.queue_free()
	
	# Atualizar UI melhorada - Menu lateral de torres
	_update_tower_shop_ui()
	
func _update_tower_shop_ui() -> void:
	# Atualizar botões de upgrade de minas
	_update_mine_upgrade_buttons()
	if tower_shop_panel == null:
		return
	
	for tower_button_data in tower_buttons:
		var tower_info = tower_button_data.tower_info
		var array_name: String = tower_info.get("array_name", "")
		var array_ref: Array = _get_structure_array(array_name)
		if array_ref.is_empty() and tower_info.has("array"):
			array_ref = tower_info.array
		var current_count = array_ref.size()
		
		# Atualizar custo do Constants (caso tenha sido alterado)
		var current_cost = tower_info.cost
		# Atualizar custo dinamicamente do Constants baseado no nome (com escala de wave)
		match tower_info.name:
			"Torre Básica":
				current_cost = get_tower_cost(GameConstants.TOWER_COST)
			"Quartel":
				current_cost = get_tower_cost(GameConstants.BARRACKS_COST)
			"Mina":
				current_cost = GameConstants.MINE_COST  # Minas não escalam
			"Torre de Congelamento":
				current_cost = get_tower_cost(GameConstants.SLOW_TOWER_COST)
			"Canhão":
				current_cost = get_tower_cost(GameConstants.AOE_TOWER_COST)
			"Torre Sniper":
				current_cost = get_tower_cost(GameConstants.SNIPER_TOWER_COST)
			"Altar de Melhoria":
				current_cost = get_tower_cost(GameConstants.BOOST_TOWER_COST)
			"Torre de Choque":
				current_cost = get_tower_cost(GameConstants.SHOCK_TOWER_COST)
			"Muralha":
				current_cost = get_wall_cost()
			"Estação de Cura":
				current_cost = GameConstants.HEALING_STATION_COST
			"Mercado de Esmeraldas":
				current_cost = GameConstants.MARKET_COST_EMERALDS  # Custo em esmeraldas, não escalona
		
		# Atualizar o custo no tower_info para uso posterior
		tower_info.cost = current_cost
		
		# Verificar se pode comprar (moedas ou esmeraldas)
		var can_afford = false
		if tower_info.has("cost_type") and tower_info.cost_type == "emeralds":
			var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}
			can_afford = currency_info.emeralds >= current_cost
		else:
			can_afford = hero["coins"] >= current_cost
		
		var can_buy = can_afford and current_count < tower_info.max
		
		# Atualizar label de limite
		tower_button_data.limit_label.text = "%d/%d" % [current_count, tower_info.max]
		if current_count >= tower_info.max:
			tower_button_data.limit_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		else:
			tower_button_data.limit_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		
		# Atualizar texto do custo (moedas ou esmeraldas)
		if tower_info.has("cost_type") and tower_info.cost_type == "emeralds":
			tower_button_data.cost_label.text = "🟢 %d esmeraldas" % current_cost
			if can_afford:
				tower_button_data.cost_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.3))  # Verde para esmeraldas
			else:
				tower_button_data.cost_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))  # Vermelho se não pode comprar
		else:
			tower_button_data.cost_label.text = "%d moedas" % current_cost
			if can_afford:
				tower_button_data.cost_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
			else:
				tower_button_data.cost_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		
		# Atualizar estado do botão
		tower_button_data.buy_button.disabled = not can_buy
		
		# Atualizar estilo do botão
		var btn_style = StyleBoxFlat.new()
		if can_buy:
			btn_style.bg_color = Color(0.2, 0.6, 0.2)
			btn_style.border_color = Color(0.3, 0.7, 0.3)
		else:
			btn_style.bg_color = Color(0.3, 0.3, 0.3)
			btn_style.border_color = Color(0.4, 0.4, 0.4)
		btn_style.border_width_left = 1
		btn_style.border_width_top = 1
		btn_style.border_width_right = 1
		btn_style.border_width_bottom = 1
		tower_button_data.buy_button.add_theme_stylebox_override("normal", btn_style)
	
	_update_hero_home_panel_ui()

func _update_hero_home_panel_ui() -> void:
	if hero_home_panel_data.is_empty():
		return
	var icon: TextureRect = hero_home_panel_data.get("icon", null)
	if icon != null:
		icon.texture = _get_hero_home_texture_for_level(hero_home_level)
	var level_label: Label = hero_home_panel_data.get("level_label", null)
	if level_label == null:
		return
	level_label.text = "Nível atual: %d/%d" % [hero_home_level, HERO_HOME_MAX_LEVEL]
	var cost_label: Label = hero_home_panel_data.get("cost_label", null)
	var benefit_label: Label = hero_home_panel_data.get("benefit_label", null)
	var button: Button = hero_home_panel_data.get("button", null)
	if cost_label == null or benefit_label == null or button == null:
		return
	if hero_home_level >= HERO_HOME_MAX_LEVEL:
		cost_label.text = "Custo: --"
		benefit_label.text = "Bônus ativos:\n%s" % _get_hero_home_benefits_text(hero_home_level)
		button.text = "Máximo"
		button.disabled = true
	else:
		var next_level = hero_home_level + 1
		var cost = _get_hero_home_upgrade_cost(next_level)
		cost_label.text = "Custo: %d" % cost
		benefit_label.text = "Próximo nível:\n%s" % _get_hero_home_benefits_text(next_level)
		button.text = "Evoluir para Nível %d" % next_level
		button.disabled = hero["coins"] < cost

	queue_redraw()

func _get_structure_array(array_name: String) -> Array:
	match array_name:
		"towers":
			return towers
		"barracks":
			return barracks
		"mines":
			return mines
		"slow_towers":
			return slow_towers
		"aoe_towers":
			return aoe_towers
		"sniper_towers":
			return sniper_towers
		"boost_towers":
			return boost_towers
		"shock_towers":
			return shock_towers
		"walls":
			return walls
		"healing_stations":
			return healing_stations
		"markets":
			return markets
		_:
			return []

func _input(event: InputEvent) -> void:
	# Hotkeys para skills (1, 2, 3, 4, 5) - apenas quando o jogo não está pausado
	if event is InputEventKey and event.pressed and not event.echo:
		if not paused and not game_over and not choosing_upgrade:
			match event.keycode:
				KEY_1:
					_on_skill_collect_coins()
					get_viewport().set_input_as_handled()
				KEY_2:
					_on_skill_damage_boost()
					get_viewport().set_input_as_handled()
				KEY_3:
					_on_skill_speed_boost()
					get_viewport().set_input_as_handled()
				KEY_4:
					_on_skill_slow_all()
					get_viewport().set_input_as_handled()
				KEY_5:
					_on_skill_magnetism()
					get_viewport().set_input_as_handled()
	
	# Alternar tela cheia com F11
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		var mode = DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()
		return
	
	# Pausar/despausar com ESC
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if game_over:
			return
		if choosing_upgrade:
			return  # Não pausar durante escolha de upgrade
		if paused:
			_unpause_game()
		else:
			_pause_game()
		get_viewport().set_input_as_handled()
		return
	
	# atualizar posição do mouse para preview
	if event is InputEventMouseMotion:
		preview_mouse_pos = to_local(event.position)
		# Se estiver arrastando uma torre, atualizar posição
		if dragging_tower:
			drag_current_pos = preview_mouse_pos
			queue_redraw()
		else:
			queue_redraw()
	
	# Detectar início de drag (botão esquerdo pressionado)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Não iniciar drag se estiver colocando algo ou escolhendo upgrade
		if choosing_upgrade or placing_tower or placing_barracks or placing_mine or placing_slow_tower or placing_aoe_tower or placing_sniper_tower or placing_boost_tower or placing_shock_tower or placing_wall or placing_healing_station or placing_market:
			pass  # Continuar com lógica normal de colocação
		else:
			# Verificar se clicou em uma torre para arrastar
			var world_pos = to_local(event.position)
			var tower_idx := _find_tower_at(world_pos, 20.0)
			if tower_idx != -1:
				_start_drag_tower("tower", tower_idx, world_pos)
				return
			
			var slow_idx := _find_slow_tower_at(world_pos, 20.0)
			if slow_idx != -1:
				_start_drag_tower("slow_tower", slow_idx, world_pos)
				return
			
			var aoe_idx := _find_aoe_tower_at(world_pos, 20.0)
			if aoe_idx != -1:
				_start_drag_tower("aoe_tower", aoe_idx, world_pos)
				return
			
			var sniper_idx := _find_sniper_tower_at(world_pos, 20.0)
			if sniper_idx != -1:
				_start_drag_tower("sniper_tower", sniper_idx, world_pos)
				return
			
			var boost_idx := _find_boost_tower_at(world_pos, 20.0)
			if boost_idx != -1:
				_start_drag_tower("boost_tower", boost_idx, world_pos)
				return
			
			var shock_idx := _find_shock_tower_at(world_pos, 20.0)
			if shock_idx != -1:
				_start_drag_tower("shock_tower", shock_idx, world_pos)
				return
			
			var mine_idx := _find_mine_at(world_pos, 12.0)
			if mine_idx != -1:
				_start_drag_tower("mine", mine_idx, world_pos)
				return
			
			var wall_idx := _find_wall_at(world_pos, 15.0)
			if wall_idx != -1:
				# Mostrar menu de upgrade de muralha ao invés de arrastar
				_show_wall_menu(wall_idx, world_pos)
				return
			
			var barracks_idx := _find_barracks_at(world_pos, 20.0)
			if barracks_idx != -1:
				_start_drag_tower("barracks", barracks_idx, world_pos)
				return
		
		# Continuar com lógica normal se não iniciou drag
		if not dragging_tower and not choosing_upgrade:
			# converter posição do mouse de tela para coordenadas do mundo do Node2D
			var screen_pos = event.position
			var world_pos = to_local(screen_pos)
			
			if coin_manager:
				var coin_value = coin_manager.try_collect_coin(world_pos)
				_try_collect_talisman(world_pos)
				if coin_value > 0:
					achievement_manager.increment_progress("collect_1000_coins", coin_value)
					achievement_manager.increment_progress("collect_10000_coins", coin_value)
					achievement_manager.increment_progress("collect_100000_coins", coin_value)
					achievement_manager.increment_progress("collect_1000000_coins", coin_value)
					if hero["coins"] >= 10000:
						achievement_manager.set_progress("hold_10000_coins", 1)
					if hero["coins"] >= 50000:
						achievement_manager.set_progress("hold_50000_coins", 1)
					_play_coin_sound()
					queue_redraw()
					return
			
			# Usar PlacementManager se disponível (ainda em desenvolvimento)
			# Por enquanto, manter código antigo
			if placing_tower:
				_try_place_tower(world_pos)
			elif placing_barracks:
				_try_place_barracks(world_pos)
			elif placing_mine:
				_try_place_mine(world_pos)
			elif placing_slow_tower:
				_try_place_slow_tower(world_pos)
			elif placing_aoe_tower:
				_try_place_aoe_tower(world_pos)
			elif placing_sniper_tower:
				_try_place_sniper_tower(world_pos)
			elif placing_boost_tower:
				_try_place_boost_tower(world_pos)
			elif placing_shock_tower:
				_try_place_shock_tower(world_pos)
			elif placing_wall:
				_try_place_wall(world_pos)
			elif placing_healing_station:
				_try_place_healing_station(world_pos)
			elif placing_market:
				_try_place_market(world_pos)
			# tiro automático - removido tiro manual por clique
	
	# Detectar fim de drag (botão esquerdo solto)
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if dragging_tower:
			var world_pos = to_local(event.position)
			var mouse_screen_pos = event.position
			# Se não moveu muito (menos de 5 pixels), considerar como clique e abrir menu para mercado
			if dragged_tower_type == "market" and drag_start_pos.distance_to(world_pos) < 5.0:
				dragging_tower = false
				dragged_tower_type = ""
				var market_idx = dragged_tower_index
				dragged_tower_index = -1
				drag_start_pos = Vector2.ZERO
				drag_offset = Vector2.ZERO
				drag_current_pos = Vector2.ZERO
				queue_redraw()
				if market_idx >= 0 and market_idx < markets.size():
					_open_market_menu(market_idx, mouse_screen_pos)
				return
			# Atualizar drag_current_pos com a posição final do mouse antes de finalizar
			# Isso garante que o preview e a colocação final usem exatamente a mesma posição
			drag_current_pos = world_pos
			_end_drag_tower(world_pos)
			return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if not choosing_upgrade and not game_over:
			# Fechar menus de upgrade ao clicar fora (botão direito)
			if tower_menu and tower_menu.visible:
				tower_menu.hide()
				_hide_range_indicator()
				tower_selected_index = -1
			if sniper_menu and sniper_menu.visible:
				sniper_menu.hide()
				_hide_range_indicator()
				sniper_selected_index = -1
			if aoe_menu and aoe_menu.visible:
				aoe_menu.hide()
				_hide_range_indicator()
				aoe_selected_index = -1
			if slow_menu and slow_menu.visible:
				slow_menu.hide()
				_hide_range_indicator()
				slow_selected_index = -1
			if boost_menu and boost_menu.visible:
				boost_menu.hide()
				_hide_range_indicator()
				boost_selected_index = -1
			if shock_menu and shock_menu.visible:
				shock_menu.hide()
				_hide_range_indicator()
				shock_selected_index = -1
			if barracks_menu and barracks_menu.visible:
				barracks_menu.hide()
				_hide_range_indicator()
				barracks_selected_index = -1
			if market_menu and market_menu.visible:
				market_menu.hide()
				market_selected_index = -1
			
			# Cancelar drag se estiver arrastando
			if dragging_tower:
				# Restaurar posição original (grid já foi restaurado)
				dragging_tower = false
				dragged_tower_type = ""
				dragged_tower_index = -1
				drag_start_pos = Vector2.ZERO
				drag_offset = Vector2.ZERO
				drag_current_pos = Vector2.ZERO
				queue_redraw()
				return
			# cancelar colocação com botão direito
			if placing_tower or placing_barracks or placing_mine or placing_slow_tower or placing_aoe_tower or placing_sniper_tower or placing_boost_tower or placing_shock_tower or placing_wall or placing_healing_station or placing_market:
				placing_tower = false
				placing_barracks = false
				placing_mine = false
				placing_slow_tower = false
				placing_aoe_tower = false
				placing_sniper_tower = false
				placing_boost_tower = false
				placing_shock_tower = false
				placing_wall = false
				placing_healing_station = false
				placing_market = false
				queue_redraw()
				return
			# converter posição do mouse para coordenadas do mundo do Node2D
			var mouse_world_pos = to_local(event.position)
			var mouse_screen_pos = event.position  # para posicionar menus na tela
			
			# Abrir menu do mercado com botão direito
			var right_click_market_idx := _find_market_at(mouse_world_pos, 30.0)
			if right_click_market_idx != -1:
				_open_market_menu(right_click_market_idx, mouse_screen_pos)
				return
			# verificar torres primeiro
			var tower_idx := _find_tower_at(mouse_world_pos, 20.0)  # raio maior para facilitar detecção
			if tower_idx != -1:
				_open_tower_menu(tower_idx, mouse_screen_pos)
				return
			# verificar quartéis (só abre menu se não estiver arrastando)
			var barracks_idx := _find_barracks_at(mouse_world_pos, 20.0)
			if barracks_idx != -1 and not dragging_tower:
				_open_barracks_menu(barracks_idx, mouse_screen_pos)
				return
			# verificar sniper towers
			var sniper_idx := _find_sniper_tower_at(mouse_world_pos, 20.0)
			if sniper_idx != -1:
				_open_sniper_menu(sniper_idx, mouse_screen_pos)
				return
			# verificar AOE towers
			var aoe_idx := _find_aoe_tower_at(mouse_world_pos, 20.0)
			if aoe_idx != -1:
				_open_aoe_menu(aoe_idx, mouse_screen_pos)
				return
			# verificar Shock towers
			var shock_idx := _find_shock_tower_at(mouse_world_pos, 20.0)
			if shock_idx != -1:
				_open_shock_menu(shock_idx, mouse_screen_pos)
				return
			# verificar Slow towers
			var slow_idx := _find_slow_tower_at(mouse_world_pos, 20.0)
			if slow_idx != -1:
				_open_slow_menu(slow_idx, mouse_screen_pos)
				return
			# verificar Boost towers
			var boost_idx := _find_boost_tower_at(mouse_world_pos, 20.0)
			if boost_idx != -1:
				_open_boost_menu(boost_idx, mouse_screen_pos)
				return
			# verificar Markets (clique esquerdo para arrastar)
			var market_idx := _find_market_at(mouse_world_pos, 30.0)
			if market_idx != -1:
				if not dragging_tower:
					_start_drag_tower("market", market_idx, mouse_world_pos)
				return
			
			# Se clicou fora de qualquer torre, fechar menus e esconder range indicator
			_close_all_upgrade_menus()

func _draw() -> void:
	# Não desenhar se ainda estiver carregando
	if is_loading:
		return
	
	# verificar se grid foi inicializado
	if grid_manager.grid.is_empty() or grid_manager.grid.size() < GameConstants.GRID_ROWS:
		return
	
	# Usar cache para map_width e map_height (calculados apenas uma vez)
	if _cached_map_width == 0.0 or _cached_map_height == 0.0:
		_cached_map_width = float(GameConstants.GRID_COLS * GameConstants.TILE_SIZE)
		_cached_map_height = float(GameConstants.GRID_ROWS * GameConstants.TILE_SIZE)
	var map_width := _cached_map_width
	var map_height := _cached_map_height
	draw_rect(Rect2(0, 0, map_width, map_height), Color(0.05, 0.06, 0.08))
	draw_rect(Rect2(0, 0, map_width, map_height), Color(0.0, 0.0, 0.0, 0.4))
	
	for r in range(GameConstants.GRID_ROWS):
		if grid_manager.grid.size() <= r or grid_manager.grid[r].size() < GameConstants.GRID_COLS:
			continue
		for c in range(GameConstants.GRID_COLS):
			var tile_x := float(c * GameConstants.TILE_SIZE)
			var tile_y := float(r * GameConstants.TILE_SIZE)
			var tile_rect := Rect2(tile_x, tile_y, GameConstants.TILE_SIZE, GameConstants.TILE_SIZE)
			
			if grid_manager.grid[r][c] == 0:
				if tex_path != null:
					draw_texture_rect(tex_path, tile_rect, false)
				elif tex_grass != null:
					draw_texture_rect(tex_grass, tile_rect, true)
				else:
					var path_color = Color(0.16, 0.14, 0.12)
					draw_rect(tile_rect, path_color)
					draw_rect(tile_rect, Color(0.20, 0.18, 0.16), false, 1.0)
			else:
				if tex_wall != null:
					draw_texture_rect(tex_wall, tile_rect, false)
				else:
					var wall_base = Color(0.24, 0.22, 0.20)
					var wall_shadow = Color(0.16, 0.14, 0.12)
					draw_rect(tile_rect, wall_base)
					draw_rect(Rect2(tile_x + 1, tile_y + 1, GameConstants.TILE_SIZE - 2, GameConstants.TILE_SIZE - 2), wall_shadow)
					draw_rect(tile_rect, Color(0.28, 0.26, 0.24), false, 1.5)
	
	# Overlay escuro sobre o labirinto (22% de opacidade)
	draw_rect(Rect2(0, 0, map_width, map_height), Color(0.0, 0.0, 0.0, 0.22))
	
	# Desenhar efeitos climáticos (chuva, neve, nuvens) - antes dos monstros
	_draw_weather_effects()
	
	# base com transparência moderada - usar coordenadas exatas do grid
	var base_half_size = int(GameConstants.BASE_SIZE_TILES / 2)  # 3
	var base_start_col = grid_manager.center.x - base_half_size  # 14
	var base_start_row = grid_manager.center.y - base_half_size  # 14
	
	# Converter coordenadas do grid para pixels exatos
	var base_left_px = float(base_start_col) * GameConstants.TILE_SIZE
	var base_top_px = float(base_start_row) * GameConstants.TILE_SIZE
	var base_width_px = float(GameConstants.BASE_SIZE_TILES) * GameConstants.TILE_SIZE
	var base_height_px = float(GameConstants.BASE_SIZE_TILES) * GameConstants.TILE_SIZE
	
	var base_rect := Rect2(base_left_px, base_top_px, base_width_px, base_height_px)
	var base_color = Color(0.28, 0.32, 0.38, 0.5)
	var base_glow = Color(0.38, 0.42, 0.48, 0.5)
	draw_rect(base_rect, base_color)
	draw_rect(base_rect, base_glow, false, 2.0)
	
	# desenhar grid da base com transparência - alinhado perfeitamente aos tiles
	# Cache grid_size_px (calculado apenas uma vez)
	if _cached_grid_size_px == 0.0:
		_cached_grid_size_px = base_width_px / float(GameConstants.BASE_GRID_SIZE)
	var grid_size_px: float = _cached_grid_size_px
	var base_left: float = base_left_px
	var base_top: float = base_top_px
	var base_right: float = base_left_px + base_width_px
	var base_bottom: float = base_top_px + base_height_px
	
	var grid_color = Color(0.4, 0.42, 0.45, 0.4)
	for gy in range(GameConstants.BASE_GRID_SIZE + 1):
		var y = base_top + float(gy) * grid_size_px
		draw_line(Vector2(base_left, y), Vector2(base_right, y), grid_color, 0.5)
	for gx in range(GameConstants.BASE_GRID_SIZE + 1):
		var x = base_left + float(gx) * grid_size_px
		draw_line(Vector2(x, base_top), Vector2(x, base_bottom), grid_color, 0.5)
	
	# Desenhar base/casa do herói ocupando bloco 3x3 (84px se tile=28)
	var bc = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
	var hero_block_pixels = float(GameConstants.TILE_SIZE) * 1.5
	var hero_texture = _get_hero_home_texture_for_level(hero_home_level)
	if hero_texture != null:
		var hero_rect = Rect2(
			bc.x - hero_block_pixels * 0.5,
			bc.y - hero_block_pixels * 0.5,
			hero_block_pixels,
			hero_block_pixels
		)
		draw_texture_rect(hero_texture, hero_rect, false)
	else:
		var half = hero_block_pixels / 2.0
		draw_rect(Rect2(bc.x - half, bc.y - half, hero_block_pixels, hero_block_pixels), Color(0.9,0.7,0.2))
	# enemies (com culling)
	var camera_pos = Vector2.ZERO  # Posição da câmera
	for e in enemies:
		# Aplicar culling: renderizar apenas se estiver visível
		if culling_manager and not culling_manager.should_render(e["pos"], camera_pos):
			continue
		
		# barra de vida melhorada (não mostrar se está morrendo)
		var is_dying = e.get("dying", false)
		var is_boss: bool = e.get("is_boss", false)
		if not is_dying:
			var max_hp: int = int(e.get("max_hp", 2))
			var hp_ratio: float = clamp(float(e["hp"]) / float(max_hp), 0.0, 1.0)
			var bar_width: int = 28 if is_boss else 20  # barra maior
			var bar_height: int = 4 if is_boss else 3
			var bx: int = int(e["pos"].x) - int(bar_width / 2)
			var by: int = int(e["pos"].y) - 16  # mais acima
			
			# Fundo da barra
			draw_rect(Rect2(bx - 1, by - 1, bar_width + 2, bar_height + 2), Color(0.0, 0.0, 0.0, 0.5))  # sombra
			draw_rect(Rect2(bx, by, bar_width, bar_height), Color(0.2, 0.2, 0.2))  # fundo escuro
			
			# Barra de HP (mudança de cor baseada no HP)
			var hp_color: Color
			if hp_ratio > 0.6:
				hp_color = Color(0.2, 0.8, 0.2)  # verde quando saudável
			elif hp_ratio > 0.3:
				hp_color = Color(0.9, 0.7, 0.2)  # amarelo quando médio
			else:
				hp_color = Color(0.9, 0.2, 0.2)  # vermelho quando baixo
			
			if is_boss:
				hp_color = Color(0.9, 0.2, 0.9)  # roxo para chefe
			
			draw_rect(Rect2(bx, by, int(bar_width * hp_ratio), bar_height), hp_color)
			
			# Borda da barra
			draw_rect(Rect2(bx, by, bar_width, bar_height), Color(1.0, 1.0, 1.0, 0.3), false, 1.0)
		# corpo - desenhar sprite do monstro
		var enemy_idx = e.get("idx", -1)
		var enemy_tex: Texture2D = tex_enemy_zombie
		
		# Se for boss, usar textura do boss
		if is_boss and tex_enemy_boss != null:
			enemy_tex = tex_enemy_boss
		else:
			# Selecionar sprite baseado no tipo do inimigo (sistema padronizado)
			var enemy_type = e.get("enemy_type", GameConstants.EnemyType.ZOMBIE)
			match enemy_type:
				GameConstants.EnemyType.ZOMBIE:
					enemy_tex = tex_enemy_zombie if tex_enemy_zombie != null else enemy_tex
				GameConstants.EnemyType.ZOMBIE_GORDO:
					enemy_tex = tex_enemy_zombie_gordo if tex_enemy_zombie_gordo != null else tex_enemy_zombie
				GameConstants.EnemyType.ZOMBIE_CORREDOR:
					enemy_tex = tex_enemy_zombie_corredor if tex_enemy_zombie_corredor != null else tex_enemy_zombie
				GameConstants.EnemyType.HUMANOID:
					enemy_tex = tex_enemy_humanoid if tex_enemy_humanoid != null else enemy_tex
				GameConstants.EnemyType.ROBOT:
					enemy_tex = tex_enemy_robot if tex_enemy_robot != null else enemy_tex
				GameConstants.EnemyType.ALIEN:
					enemy_tex = tex_enemy_alien if tex_enemy_alien != null else enemy_tex
				_:
					# Fallback: usar seleção baseada em wave (compatibilidade com saves antigos)
					if wave_manager.wave >= 50 and tex_enemy_alien != null:
						enemy_tex = tex_enemy_alien
					elif wave_manager.wave >= 11 and tex_enemy_robot != null:
						enemy_tex = tex_enemy_robot
					elif wave_manager.wave >= 6 and tex_enemy_humanoid != null:
						enemy_tex = tex_enemy_humanoid
					elif tex_enemy_zombie != null:
						enemy_tex = tex_enemy_zombie
		
		if enemy_tex != null:
			# Tamanho maior para bosses, tamanho normal para outros
			var enemy_size_multiplier = 1.5 if is_boss else 1.2
			var size := Vector2(GameConstants.TILE_SIZE * enemy_size_multiplier, GameConstants.TILE_SIZE * enemy_size_multiplier)
			var pos: Vector2 = e["pos"] - size/2
			
			# Desenhar sombra abaixo do sprite (antes do sprite para ficar atrás)
			var shadow_offset = Vector2(0, size.y * 0.25)  # Offset para baixo (reduzido, mais próximo)
			var shadow_pos = e["pos"] + shadow_offset
			var shadow_radius = size.x * 0.28  # Raio da sombra reduzido em 20% (0.35 * 0.8)
			var shadow_color = Color(0.0, 0.0, 0.0, 0.3)  # Preto com 30% de opacidade
			draw_circle(shadow_pos, shadow_radius, shadow_color)
			
			# Aplicar efeitos visuais através de modulate
			var modulate_color = Color.WHITE
			
			# Efeito de noite: reduzir brilho e contraste dos monstros (torná-los mais difíceis de ver)
			if weather_manager and weather_manager.is_night():
				modulate_color = Color(0.5, 0.5, 0.6, 0.8)  # Escurecido mas com maior opacidade (80% ao invés de 60%)
			
			if is_dying:
				# Aplicar animação de morte (fade e shrink)
				var dying_progress = e.get("dying_time", 0.0) / 0.5
				modulate_color.a = 1.0 - dying_progress
				size *= (1.0 - dying_progress * 0.5)  # encolhe até 50%
				pos = e["pos"] - size/2  # recentralizar após mudança de tamanho
			elif enemy_idx >= 0 and enemy_effects.has(enemy_idx):
				var effects = enemy_effects[enemy_idx]
				if effects.freeze_time > 0.0:
					modulate_color = Color(0.7, 0.9, 1.2, 1.0)  # azul claro quando congelado
				elif effects.fire_time > 0.0:
					modulate_color = Color(1.2, 0.7, 0.5, 1.0)  # laranja quando em chamas
			
			# Desenhar sprite com direção
			var tex_size = enemy_tex.get_size()
			# Verificar se é sprite sheet (2x2 grid = 128x128 ou similar)
			# Se a textura for grande o suficiente, assumir que é sprite sheet
			if tex_size.x >= 128 and tex_size.y >= 128:
				# Sprite sheet 2x2: cada quadro é metade da textura
				var frame_size = tex_size / 2.0
				var direction = _get_enemy_direction(e)
				var src_rect: Rect2
				
				# Calcular região do sprite sheet baseada na direção
				# Grid 2x2: Layout pode variar, ajustando mapeamento baseado no feedback
				# Se cima→baixo e esquerda→direita, o sprite sheet pode ter layout diferente
				# Tentando mapeamento corrigido: up e down trocados, left e right trocados
				match direction:
					"up":
						# Se "up" mostra baixo, então up deve pegar a posição de baixo no sprite
						src_rect = Rect2(frame_size.x, frame_size.y, frame_size.x, frame_size.y)  # Posição de BAIXO no sprite
					"down":
						# Se "down" mostra cima, então down deve pegar a posição de cima no sprite
						src_rect = Rect2(0, 0, frame_size.x, frame_size.y)  # Posição de CIMA no sprite
					"left":
						# Corrigido: left deve pegar a posição de ESQUERDA no sprite
						src_rect = Rect2(0, frame_size.y, frame_size.x, frame_size.y)  # Posição de ESQUERDA no sprite
					"right":
						# Corrigido: right deve pegar a posição de DIREITA no sprite
						src_rect = Rect2(frame_size.x, 0, frame_size.x, frame_size.y)  # Posição de DIREITA no sprite
					_:
						src_rect = Rect2(0, 0, frame_size.x, frame_size.y)  # Default: cima
				
				# Desenhar região específica do sprite sheet
				draw_texture_rect_region(enemy_tex, Rect2(pos, size), src_rect, modulate_color)
			else:
				# Textura normal (não é sprite sheet), desenhar inteira
				draw_texture_rect(enemy_tex, Rect2(pos, size), false, modulate_color)
			
			# Desenhar borda especial para boss
			if is_boss:
				var border_rect = Rect2(pos - Vector2(2, 2), size + Vector2(4, 4))
				draw_rect(border_rect, Color(0.8, 0.2, 0.8, 0.8), false, 3.0)  # borda roxa
		else:
			var enemy_color = Color(0.9,0.35,0.35)
			
			# Efeito de noite: reduzir brilho e contraste dos monstros (torná-los mais difíceis de ver)
			if weather_manager and weather_manager.is_night():
				enemy_color = Color(0.4, 0.4, 0.45, 0.8)  # Escurecido mas com maior opacidade (80% ao invés de 60%)
			
			# chefe tem cor diferente (roxo/vermelho escuro)
			if is_boss:
				enemy_color = Color(0.8,0.2,0.8)  # roxo para chefe
				# Aplicar efeito de noite também em bosses (mas menos intenso)
				if weather_manager and weather_manager.is_night():
					enemy_color = Color(0.5, 0.15, 0.5, 0.85)  # Boss um pouco mais visível (opacidade aumentada)
			if not is_boss and enemy_idx >= 0 and enemy_effects.has(enemy_idx):
				var effects = enemy_effects[enemy_idx]
				if effects.freeze_time > 0.0:
					enemy_color = Color(0.5,0.7,1.0)  # azul quando congelado
				elif effects.fire_time > 0.0:
					enemy_color = Color(1.0,0.5,0.2)  # laranja quando em chamas
			
			var enemy_radius = e.get("radius", 9)
			
			# Desenhar sombra abaixo do círculo (antes do círculo para ficar atrás)
			var shadow_offset = Vector2(0, enemy_radius * 0.4)  # Offset para baixo (reduzido, mais próximo)
			var shadow_pos = e["pos"] + shadow_offset
			var shadow_radius = enemy_radius * 0.50  # Raio da sombra reduzido em 20% (0.6 * 0.8)
			var shadow_color = Color(0.0, 0.0, 0.0, 0.25)  # Preto com 30% de opacidade
			draw_circle(shadow_pos, shadow_radius, shadow_color)
			
			draw_circle(e["pos"], enemy_radius, enemy_color)
			
			# desenhar borda mais grossa para chefe
			if is_boss:
				draw_circle(e["pos"], enemy_radius, Color(0.5,0.1,0.5), false, 3.0)  # borda roxa grossa
	
	# Desenhar overlay de noite DEPOIS dos monstros (para ficar por cima deles)
	if weather_manager and weather_manager.is_night():
		# Usar map_width e map_height já declaradas no início da função _draw()
		# Overlay escuro azulado sobre todo o labirinto incluindo o topo (60% de opacidade)
		draw_rect(Rect2(0, 0, map_width, map_height), Color(0.05, 0.05, 0.15, 0.6))
	
	# arrows (com culling)
	for a in arrows:
		if not culling_manager or culling_manager.should_render(a["pos"], camera_pos):
			draw_circle(a["pos"], 2, Color(0.83,0.90,1.0))
	for b in tower_bullets:
		if not culling_manager or culling_manager.should_render(b["pos"], camera_pos):
			draw_circle(b["pos"], 2, Color(0.95,0.85,0.45))
	# projéteis de canhão AOE (bolas pretas) (com culling)
	for proj in aoe_cannon_projectiles:
		if not culling_manager or culling_manager.should_render(proj.pos, camera_pos):
			draw_circle(proj.pos, 6, Color(0.0, 0.0, 0.0))  # bola preta
			draw_circle(proj.pos, 6, Color(0.2, 0.2, 0.2), false, 1.0)  # borda escura
	# efeitos visuais AOE (explosões) (com culling e LOD)
	for effect in aoe_effects:
		if not culling_manager or culling_manager.should_render(effect.pos, camera_pos):
			var lod_level = culling_manager.get_lod_level(effect.pos, camera_pos) if culling_manager else 0
			var alpha = 1.0 - (effect.time / effect.max_time)
			var radius = effect.radius * (effect.time / effect.max_time)
			# Aplicar LOD: reduzir detalhes em objetos distantes
			if lod_level <= 2:  # Renderizar apenas se não estiver muito distante
				draw_circle(effect.pos, radius, Color(1.0, 0.5, 0.0, alpha * 0.6))
				if lod_level <= 1:  # Borda apenas se estiver próximo
					draw_circle(effect.pos, radius, Color(1.0, 0.8, 0.0, alpha), false, 2.0)
	# efeitos visuais Sniper (linhas de tiro) (com culling)
	for effect in sniper_effects:
		if not culling_manager or culling_manager.should_render(effect.start, camera_pos):
			var alpha = 1.0 - (effect.time / effect.max_time)
			draw_line(effect.start, effect.end, Color(1.0, 1.0, 0.0, alpha), 3.0)
	# efeitos visuais de choque elétrico (raios/trovões) (com culling)
	for effect in shock_effects:
		if not culling_manager or culling_manager.should_render(effect.start, camera_pos):
			var lod_level = culling_manager.get_lod_level(effect.start, camera_pos) if culling_manager else 0
			var alpha = 1.0 - (effect.time / effect.max_time)
			var progress = effect.time / effect.max_time
			# Desenhar linha principal (azul brilhante)
			draw_line(effect.start, effect.end, Color(0.5, 0.8, 1.0, alpha), 4.0)
			# Desenhar linha interna mais brilhante (branco/azul claro) apenas se próximo
			if lod_level <= 1:
				draw_line(effect.start, effect.end, Color(1.0, 1.0, 1.0, alpha * 0.8), 2.0)
			# Adicionar "zigzag" para parecer um raio (apenas se próximo)
			if lod_level <= 1:
				var segments = 8 if lod_level == 0 else 4  # Menos segmentos se distante
				var dir = (effect.end - effect.start).normalized()
				var perp = Vector2(-dir.y, dir.x)
				for i in range(segments):
					var t1 = float(i) / float(segments)
					var t2 = float(i + 1) / float(segments)
					var p1 = effect.start.lerp(effect.end, t1)
					var p2 = effect.start.lerp(effect.end, t2)
					# Adicionar pequeno desvio aleatório para parecer um raio
					var offset1 = perp * randf_range(-3.0, 3.0) * (1.0 - progress)
					var offset2 = perp * randf_range(-3.0, 3.0) * (1.0 - progress)
					draw_line(p1 + offset1, p2 + offset2, Color(0.7, 0.9, 1.0, alpha * 0.6), 2.0)
	# Desenhar torre sendo arrastada (preview durante drag)
	if dragging_tower:
		var preview_pos = drag_current_pos - drag_offset
		var preview_size: float
		var preview_tex: Texture2D
		var tower_size_grid: int = 3
		
		match dragged_tower_type:
			"tower":
				preview_size = grid_size_px * GameConstants.TOWER_SIZE_GRID
				preview_tex = tex_tower
				tower_size_grid = GameConstants.TOWER_SIZE_GRID
			"slow_tower":
				preview_size = grid_size_px * GameConstants.SLOW_TOWER_SIZE_GRID
				preview_tex = tex_slow_tower
				tower_size_grid = GameConstants.SLOW_TOWER_SIZE_GRID
			"aoe_tower":
				preview_size = grid_size_px * GameConstants.AOE_TOWER_SIZE_GRID
				preview_tex = tex_aoe_tower
				tower_size_grid = GameConstants.AOE_TOWER_SIZE_GRID
			"sniper_tower":
				preview_size = grid_size_px * GameConstants.SNIPER_TOWER_SIZE_GRID
				preview_tex = tex_sniper_tower
				tower_size_grid = GameConstants.SNIPER_TOWER_SIZE_GRID
			"boost_tower":
				preview_size = grid_size_px * GameConstants.BOOST_TOWER_SIZE_GRID
				preview_tex = tex_boost_tower
				tower_size_grid = GameConstants.BOOST_TOWER_SIZE_GRID
			"shock_tower":
				preview_size = grid_size_px * GameConstants.SHOCK_TOWER_SIZE_GRID
				preview_tex = tex_shock_tower
				tower_size_grid = GameConstants.SHOCK_TOWER_SIZE_GRID
			"barracks":
				preview_size = grid_size_px * GameConstants.BARRACKS_SIZE_GRID
				preview_tex = tex_barracks
				tower_size_grid = GameConstants.BARRACKS_SIZE_GRID
			"market":
				preview_size = grid_size_px * GameConstants.MARKET_SIZE_GRID
				preview_tex = tex_market
				tower_size_grid = GameConstants.MARKET_SIZE_GRID
			"mine":
				preview_size = 16.0
				preview_tex = tex_mine
		
		# Verificar se a posição é válida usando a mesma lógica de snap do _end_drag_tower
		var can_place = false
		var snapped_preview_pos = preview_pos
		
		if dragged_tower_type == "mine":
			# Lógica especial para minas (fora da base)
			var tile = _world_to_tile_coords(preview_pos)
			can_place = _is_tile_within_bounds(tile) and _is_walkable_tile(tile) and not grid_manager.is_inside_base_point(preview_pos) and not _is_in_center_area(preview_pos) and not _is_mine_tile_occupied(tile)
		elif grid_manager.is_inside_base_point(preview_pos):
			# Usar a mesma função auxiliar que _end_drag_tower usa para garantir consistência
			var snap_result = _calculate_tower_snap(preview_pos, tower_size_grid)
			var grid_coord = snap_result["grid_coord"]
			snapped_preview_pos = snap_result["snapped_world_pos"]
			
			# Criar área a ignorar (posição antiga da torre) e validar
			var ignore_area: Rect2i = Rect2i()
			var item_type: int = 1
			
			match dragged_tower_type:
				"tower":
					if dragged_tower_index >= 0 and dragged_tower_index < towers.size():
						var old_tower = towers[dragged_tower_index]
						ignore_area = Rect2i(old_tower.grid_x, old_tower.grid_y, GameConstants.TOWER_SIZE_GRID, GameConstants.TOWER_SIZE_GRID)
					item_type = 1
					can_place = grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, GameConstants.TOWER_SIZE_GRID, item_type, ignore_area)
				"slow_tower":
					if dragged_tower_index >= 0 and dragged_tower_index < slow_towers.size():
						var old_tower = slow_towers[dragged_tower_index]
						ignore_area = Rect2i(old_tower.grid_x, old_tower.grid_y, GameConstants.SLOW_TOWER_SIZE_GRID, GameConstants.SLOW_TOWER_SIZE_GRID)
					item_type = 5
					can_place = grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, GameConstants.SLOW_TOWER_SIZE_GRID, item_type, ignore_area)
				"aoe_tower":
					if dragged_tower_index >= 0 and dragged_tower_index < aoe_towers.size():
						var old_tower = aoe_towers[dragged_tower_index]
						ignore_area = Rect2i(old_tower.grid_x, old_tower.grid_y, GameConstants.AOE_TOWER_SIZE_GRID, GameConstants.AOE_TOWER_SIZE_GRID)
					item_type = 6
					can_place = grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, GameConstants.AOE_TOWER_SIZE_GRID, item_type, ignore_area)
				"sniper_tower":
					if dragged_tower_index >= 0 and dragged_tower_index < sniper_towers.size():
						var old_tower = sniper_towers[dragged_tower_index]
						ignore_area = Rect2i(old_tower.grid_x, old_tower.grid_y, GameConstants.SNIPER_TOWER_SIZE_GRID, GameConstants.SNIPER_TOWER_SIZE_GRID)
					item_type = 7
					can_place = grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, GameConstants.SNIPER_TOWER_SIZE_GRID, item_type, ignore_area)
				"boost_tower":
					if dragged_tower_index >= 0 and dragged_tower_index < boost_towers.size():
						var old_tower = boost_towers[dragged_tower_index]
						ignore_area = Rect2i(old_tower.grid_x, old_tower.grid_y, GameConstants.BOOST_TOWER_SIZE_GRID, GameConstants.BOOST_TOWER_SIZE_GRID)
					item_type = 8
					can_place = grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, GameConstants.BOOST_TOWER_SIZE_GRID, item_type, ignore_area)
				"shock_tower":
					if dragged_tower_index >= 0 and dragged_tower_index < shock_towers.size():
						var old_tower = shock_towers[dragged_tower_index]
						ignore_area = Rect2i(old_tower.grid_x, old_tower.grid_y, GameConstants.SHOCK_TOWER_SIZE_GRID, GameConstants.SHOCK_TOWER_SIZE_GRID)
					item_type = 9
					can_place = grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, GameConstants.SHOCK_TOWER_SIZE_GRID, item_type, ignore_area)
				"barracks":
					if dragged_tower_index >= 0 and dragged_tower_index < barracks.size():
						var old_barracks = barracks[dragged_tower_index]
						ignore_area = Rect2i(old_barracks.grid_x, old_barracks.grid_y, GameConstants.BARRACKS_SIZE_GRID, GameConstants.BARRACKS_SIZE_GRID)
					item_type = 3
					can_place = grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, GameConstants.BARRACKS_SIZE_GRID, item_type, ignore_area)
				"market":
					if dragged_tower_index >= 0 and dragged_tower_index < markets.size():
						var old_market = markets[dragged_tower_index]
						ignore_area = Rect2i(old_market.grid_x, old_market.grid_y, GameConstants.MARKET_SIZE_GRID, GameConstants.MARKET_SIZE_GRID)
					item_type = 11
					can_place = grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, GameConstants.MARKET_SIZE_GRID, item_type, ignore_area)
		
		# Não renderizar preview para minas aqui (já tem renderização separada)
		# Quartel agora usa o mesmo sistema de preview que as outras torres
		if dragged_tower_type != "mine":
			# Para mercado, usar preview sem borda verde
			if dragged_tower_type == "market":
				var preview_rect = Rect2(snapped_preview_pos.x - preview_size/2, snapped_preview_pos.y - preview_size/2, preview_size, preview_size)
				if can_place:
					if preview_tex != null:
						draw_texture_rect(preview_tex, preview_rect, false, Color(1, 1, 1, 0.7))
					else:
						draw_rect(preview_rect, resource_manager.get_color("preview_valid"))
				else:
					if preview_tex != null:
						draw_texture_rect(preview_tex, preview_rect, false, Color(1, 0.3, 0.3, 0.7))
					else:
						draw_rect(preview_rect, resource_manager.get_color("preview_invalid"))
			else:
				# Usar posição snapped para preview visual
				var preview_rect = Rect2(snapped_preview_pos.x - preview_size/2, snapped_preview_pos.y - preview_size/2, preview_size, preview_size)
				if can_place:
					# Posição válida - usar cores pré-carregadas
					if preview_tex != null:
						draw_texture_rect(preview_tex, preview_rect, false, Color(1, 1, 1, 0.7))
					else:
						draw_rect(preview_rect, resource_manager.get_color("preview_valid"))
					draw_rect(preview_rect, resource_manager.get_color("preview_border_valid"), false, 2.0)
				else:
					# Posição inválida - usar cores pré-carregadas
					if preview_tex != null:
						draw_texture_rect(preview_tex, preview_rect, false, Color(1, 0.3, 0.3, 0.7))
					else:
						draw_rect(preview_rect, resource_manager.get_color("preview_invalid"))
					draw_rect(preview_rect, resource_manager.get_color("preview_border_invalid"), false, 2.0)
	
	# towers (3x3 no grid)
	for i in range(towers.size()):
		# Não desenhar a torre que está sendo arrastada
		if dragging_tower and dragged_tower_type == "tower" and i == dragged_tower_index:
			continue
		var t = towers[i]
		var tower_size := grid_size_px * GameConstants.TOWER_SIZE_GRID
		var r := Rect2(t.pos.x - tower_size/2, t.pos.y - tower_size/2, tower_size, tower_size)
		if tex_tower != null:
			draw_texture_rect(tex_tower, r, false)
		else:
			draw_rect(r, Color(0.7,0.7,0.8))
			draw_rect(r, Color(0.5,0.5,0.6), false, 2.0)  # borda
	# barracks (3x3 no grid)
	for i in range(barracks.size()):
		# Não desenhar o quartel que está sendo arrastado
		if dragging_tower and dragged_tower_type == "barracks" and i == dragged_tower_index:
			continue
		var br = barracks[i]
		var barracks_size := grid_size_px * GameConstants.BARRACKS_SIZE_GRID
		var br_rect := Rect2(br.pos.x - barracks_size/2, br.pos.y - barracks_size/2, barracks_size, barracks_size)
		if tex_barracks != null:
			draw_texture_rect(tex_barracks, br_rect, false)
		else:
			draw_rect(br_rect, Color(0.4,0.5,0.6))
			draw_rect(br_rect, Color(0.3,0.4,0.5), false, 2.0)  # borda
	# minas
	for i in range(mines.size()):
		# Não desenhar a mina que está sendo arrastada
		if dragging_tower and dragged_tower_type == "mine" and i == dragged_tower_index:
			continue
		var m = mines[i]
		if not m.triggered:
			if tex_mine != null:
				var mine_size = 16.0
				var mine_rect = Rect2(m.pos.x - mine_size/2, m.pos.y - mine_size/2, mine_size, mine_size)
				draw_texture_rect(tex_mine, mine_rect, false)
			else:
				draw_circle(m.pos, 8, Color(0.8,0.2,0.2))
				draw_circle(m.pos, 8, Color(0.5,0.1,0.1), false, 2.0)
	# slow towers
	for i in range(slow_towers.size()):
		if dragging_tower and dragged_tower_type == "slow_tower" and i == dragged_tower_index:
			continue
		var st = slow_towers[i]
		var st_size := grid_size_px * GameConstants.SLOW_TOWER_SIZE_GRID
		var st_rect := Rect2(st.pos.x - st_size/2, st.pos.y - st_size/2, st_size, st_size)
		if tex_slow_tower != null:
			draw_texture_rect(tex_slow_tower, st_rect, false)
		else:
			draw_rect(st_rect, Color(0.5,0.7,0.9))
			draw_rect(st_rect, Color(0.3,0.5,0.7), false, 2.0)
	# AOE towers
	for i in range(aoe_towers.size()):
		if dragging_tower and dragged_tower_type == "aoe_tower" and i == dragged_tower_index:
			continue
		var aoe = aoe_towers[i]
		var aoe_size := grid_size_px * GameConstants.AOE_TOWER_SIZE_GRID
		var aoe_rect := Rect2(aoe.pos.x - aoe_size/2, aoe.pos.y - aoe_size/2, aoe_size, aoe_size)
		if tex_aoe_tower != null:
			draw_texture_rect(tex_aoe_tower, aoe_rect, false)
		else:
			draw_rect(aoe_rect, Color(0.9,0.5,0.2))
			draw_rect(aoe_rect, Color(0.7,0.3,0.1), false, 2.0)
	# sniper towers
	for i in range(sniper_towers.size()):
		if dragging_tower and dragged_tower_type == "sniper_tower" and i == dragged_tower_index:
			continue
		var sniper = sniper_towers[i]
		var sniper_size := grid_size_px * GameConstants.SNIPER_TOWER_SIZE_GRID
		var sniper_rect := Rect2(sniper.pos.x - sniper_size/2, sniper.pos.y - sniper_size/2, sniper_size, sniper_size)
		if tex_sniper_tower != null:
			draw_texture_rect(tex_sniper_tower, sniper_rect, false)
		else:
			draw_rect(sniper_rect, Color(0.3,0.3,0.3))
			draw_rect(sniper_rect, Color(0.1,0.1,0.1), false, 2.0)
	# boost towers
	for i in range(boost_towers.size()):
		if dragging_tower and dragged_tower_type == "boost_tower" and i == dragged_tower_index:
			continue
		var boost = boost_towers[i]
		var boost_size := grid_size_px * GameConstants.BOOST_TOWER_SIZE_GRID
		var boost_rect := Rect2(boost.pos.x - boost_size/2, boost.pos.y - boost_size/2, boost_size, boost_size)
		if tex_boost_tower != null:
			draw_texture_rect(tex_boost_tower, boost_rect, false)
		else:
			draw_rect(boost_rect, Color(0.8,0.8,0.2))
			draw_rect(boost_rect, Color(0.6,0.6,0.1), false, 2.0)
	# shock towers
	for i in range(shock_towers.size()):
		if dragging_tower and dragged_tower_type == "shock_tower" and i == dragged_tower_index:
			continue
		var shock = shock_towers[i]
		var shock_size := grid_size_px * GameConstants.SHOCK_TOWER_SIZE_GRID
		var shock_rect := Rect2(shock.pos.x - shock_size/2, shock.pos.y - shock_size/2, shock_size, shock_size)
		if tex_shock_tower != null:
			draw_texture_rect(tex_shock_tower, shock_rect, false)
		else:
			draw_rect(shock_rect, Color(0.5,0.3,0.9))  # roxo para torre de choque
			draw_rect(shock_rect, Color(0.4,0.2,0.8), false, 2.0)
	for i in range(walls.size()):
		if dragging_tower and dragged_tower_type == "wall" and i == dragged_tower_index:
			continue
		var w = walls[i]
		if w.hp > 0:
			var wall_size: float
			if grid_manager.is_inside_base_point(w.pos):
				wall_size = grid_size_px * GameConstants.WALL_SIZE_GRID
			else:
				wall_size = float(GameConstants.TILE_SIZE) * 1.1
			var wall_rect := Rect2(w.pos.x - wall_size/2, w.pos.y - wall_size/2, wall_size, wall_size)
			if tex_wall_structure != null:
				# Aplicar transparência baseada no HP
				var hp_ratio = w.hp / w.max_hp
				var alpha = 0.5 + (hp_ratio * 0.5)  # 0.5 a 1.0
				draw_texture_rect(tex_wall_structure, wall_rect, false, Color(1, 1, 1, alpha))
			else:
				var hp_ratio = w.hp / w.max_hp
				var wall_color = Color(0.6,0.4,0.2) * hp_ratio + Color(0.3,0.2,0.1) * (1.0 - hp_ratio)
				draw_rect(wall_rect, wall_color)
				draw_rect(wall_rect, Color(0.4,0.3,0.2), false, 2.0)
	
	# Desenhar mina sendo arrastada (fora do match principal)
	if dragging_tower and dragged_tower_type == "mine" and dragged_tower_index >= 0 and dragged_tower_index < mines.size():
		var m = mines[dragged_tower_index]
		var mine_size = 16.0
		var drag_pos = drag_current_pos - drag_offset
		var tile = _world_to_tile_coords(drag_pos)
		var can_place = _is_tile_within_bounds(tile) and _is_walkable_tile(tile) and not grid_manager.is_inside_base_point(drag_pos) and not _is_in_center_area(drag_pos) and not _is_mine_tile_occupied(tile)
		var mine_rect := Rect2(drag_pos.x - mine_size/2, drag_pos.y - mine_size/2, mine_size, mine_size)
		if can_place:
			if tex_mine != null:
				draw_texture_rect(tex_mine, mine_rect, false, Color(1, 1, 1, 0.7))
			else:
				draw_circle(drag_pos, 8, Color(0.7, 0.9, 0.7, 0.7))
			draw_rect(mine_rect, Color(0.5, 0.8, 0.5), false, 2.0)
		else:
			if tex_mine != null:
				draw_texture_rect(tex_mine, mine_rect, false, Color(1, 0.3, 0.3, 0.7))
			else:
				draw_circle(drag_pos, 8, Color(0.9, 0.3, 0.3, 0.7))
			draw_rect(mine_rect, Color(0.8, 0.2, 0.2), false, 2.0)
	
	# Desenhar muralha sendo arrastada
	if dragging_tower and dragged_tower_type == "wall" and dragged_tower_index >= 0 and dragged_tower_index < walls.size():
		var w = walls[dragged_tower_index]
		var wall_size = float(GameConstants.TILE_SIZE) * 1.1
		var drag_pos = drag_current_pos - drag_offset
		var wall_rect := Rect2(drag_pos.x - wall_size/2, drag_pos.y - wall_size/2, wall_size, wall_size)
		if tex_wall_structure != null:
			draw_texture_rect(tex_wall_structure, wall_rect, false, Color(1, 1, 1, 0.7))
		else:
			draw_rect(wall_rect, Color(0.6,0.4,0.2,0.7))
			draw_rect(wall_rect, Color(0.4,0.3,0.2), false, 2.0)
	
	# Quartel agora usa o mesmo sistema de preview que as outras torres (renderizado acima no bloco geral)
	# Removido código duplicado de preview do quartel
	
	# healing stations
	for hs in healing_stations:
		var hs_size := grid_size_px * GameConstants.HEALING_STATION_SIZE_GRID
		var hs_rect := Rect2(hs.pos.x - hs_size/2, hs.pos.y - hs_size/2, hs_size, hs_size)
		if tex_healing_station != null:
			draw_texture_rect(tex_healing_station, hs_rect, false)
		else:
			draw_rect(hs_rect, Color(0.2,0.8,0.4))
	
	# markets
	for i in range(markets.size()):
		# Não desenhar o mercado que está sendo arrastado
		if dragging_tower and dragged_tower_type == "market" and i == dragged_tower_index:
			continue
		var m = markets[i]
		var m_size := grid_size_px * GameConstants.MARKET_SIZE_GRID
		var m_rect := Rect2(m.pos.x - m_size/2, m.pos.y - m_size/2, m_size, m_size)
		if tex_market != null:
			draw_texture_rect(tex_market, m_rect, false)
		else:
			draw_rect(m_rect, Color(0.2,0.8,0.2))
	
	# soldados
	for s in soldiers:
		if s.hp > 0:
			var soldier_color = Color(0.2,0.6,0.9) if not s.holding else Color(0.9,0.6,0.2)
			draw_circle(s.pos, s.radius, soldier_color)
			draw_circle(s.pos, s.radius, Color(0.1,0.3,0.5), false, 1.0)  # borda
	
	# moedas dropadas
	for coin in dropped_coins:
		if coin.collected:
			continue
		# calcular transparência baseada no tempo de vida (piscar quando está prestes a desaparecer)
		var lifetime_ratio = coin.lifetime / coin.max_lifetime
		var alpha = 1.0
		if lifetime_ratio > 0.7:  # últimos 30% do tempo de vida
			var fade_ratio = (lifetime_ratio - 0.7) / 0.3
			alpha = 1.0 - fade_ratio * 0.5  # fade até 50% de transparência
		
		if tex_coin != null:
			var coin_size = 32.0  # tamanho aumentado em 2x (de 16 para 32)
			var coin_rect = Rect2(coin.pos.x - coin_size/2, coin.pos.y - coin_size/2, coin_size, coin_size)
			draw_texture_rect(tex_coin, coin_rect, false, Color(1, 1, 1, alpha))
		else:
			# fallback: desenhar círculo dourado (tamanho aumentado em 2x)
			draw_circle(coin.pos, 16, Color(0.9, 0.8, 0.2, alpha))
			draw_circle(coin.pos, 16, Color(0.7, 0.6, 0.1, alpha), false, 2.0)
			# desenhar símbolo de moeda ($) no centro
			# Nota: Godot não tem draw_text simples, então vamos apenas desenhar um círculo menor no centro
			draw_circle(coin.pos, 8, Color(1.0, 0.9, 0.3, alpha))
	
	# talismãs dropados
	for talisman_drop in dropped_talismans:
		if talisman_drop.collected:
			continue
		# calcular transparência baseada no tempo de vida
		var lifetime_ratio = talisman_drop.lifetime / talisman_drop.max_lifetime
		var alpha = 1.0
		if lifetime_ratio > 0.8:  # últimos 20% do tempo de vida
			var fade_ratio = (lifetime_ratio - 0.8) / 0.2
			alpha = 1.0 - fade_ratio * 0.5  # fade até 50% de transparência
		
		var talisman = talisman_drop.talisman
		var rarity_color = talisman.get_rarity_color()
		var talisman_size = 50.0
		
		# Desenhar círculo de fundo com cor da raridade
		draw_circle(talisman_drop.pos, talisman_size/2, Color(rarity_color.r, rarity_color.g, rarity_color.b, alpha * 0.3))
		draw_circle(talisman_drop.pos, talisman_size/2, rarity_color, false, 3.0)
		
		# Desenhar imagem do talismã
		if tex_talisman != null:
			var talisman_rect = Rect2(talisman_drop.pos.x - talisman_size/2, talisman_drop.pos.y - talisman_size/2, talisman_size, talisman_size)
			draw_texture_rect(tex_talisman, talisman_rect, false, Color(1, 1, 1, alpha))
		else:
			# Fallback: círculo colorido
			draw_circle(talisman_drop.pos, talisman_size/4, Color(rarity_color.r, rarity_color.g, rarity_color.b, alpha))
	
	# efeitos de coleta de moedas (amarelo/dourado)
	for effect in coin_collect_effects:
		var progress = effect.time / effect.max_time
		var alpha = 1.0 - progress
		
		# Desenhar círculo brilhante central (amarelo/dourado)
		var base_radius = 20.0 * (1.0 + progress * 2.0)  # cresce com o tempo
		draw_circle(effect.pos, base_radius, Color(1.0, 0.9, 0.2, alpha * 0.4))
		draw_circle(effect.pos, base_radius, Color(1.0, 0.85, 0.0, alpha * 0.6), false, 2.0)
		
		# Desenhar círculo interno brilhante
		var inner_radius = 10.0 * (1.0 + progress)
		draw_circle(effect.pos, inner_radius, Color(1.0, 1.0, 0.5, alpha * 0.8))
		
		# Desenhar partículas (estrelas/brilhos)
		for particle in effect.particles:
			var particle_alpha = 1.0 - (particle.time / particle.max_time)
			var particle_size = 4.0 * (1.0 - particle.time / particle.max_time)
			# Desenhar pequena estrela/brilho
			draw_circle(particle.pos, particle_size, Color(1.0, 0.95, 0.3, particle_alpha))
			draw_circle(particle.pos, particle_size * 0.5, Color(1.0, 1.0, 0.8, particle_alpha))
	
	# indicadores de dano flutuantes
	for dmg in damage_numbers:
		var progress = dmg.time / dmg.max_time
		var alpha = 1.0 - progress
		var y_offset = progress * 30.0  # move para cima
		var pos = dmg.pos + Vector2(0, -y_offset)
		var scale = 1.0 + (progress * 0.5) if dmg.is_crit else 1.0
		var color = dmg.color
		color.a = alpha
		
		# Desenhar número de dano (simulado com círculo e texto visual)
		var size = 12.0 * scale
		if dmg.is_crit:
			# Efeito especial para crítico
			draw_circle(pos, size * 1.5, Color(1.0, 0.9, 0.0, alpha * 0.3))
			draw_circle(pos, size, Color(1.0, 0.8, 0.2, alpha))
		else:
			draw_circle(pos, size * 0.8, color)
		
		# Desenhar valor aproximado (usando círculos para simular números)
		# Para valores maiores, desenhar círculos maiores
		var value_size = clamp(dmg.value / 5.0, 0.5, 2.0)
		draw_circle(pos, size * value_size * 0.6, Color(1.0, 1.0, 1.0, alpha))
	
	# animações de morte
	for anim in enemy_death_animations:
		var alpha = anim.alpha
		var scale = anim.scale
		# Desenhar efeito de morte (círculo que encolhe e desaparece)
		draw_circle(anim.pos, 15.0 * scale, Color(0.8, 0.2, 0.2, alpha))
		draw_circle(anim.pos, 10.0 * scale, Color(1.0, 0.5, 0.0, alpha * 0.7))
		# Partículas de morte
		for i in range(8):
			var angle = (TAU / 8.0) * i
			var dist = 20.0 * (1.0 - scale)
			var particle_pos = anim.pos + Vector2(cos(angle), sin(angle)) * dist
			draw_circle(particle_pos, 3.0 * scale, Color(1.0, 0.7, 0.0, alpha))
	
	# preview de colocação
	if placing_tower or placing_barracks or placing_mine or placing_slow_tower or placing_aoe_tower or placing_sniper_tower or placing_boost_tower or placing_shock_tower or placing_wall or placing_healing_station or placing_market:
		if grid_manager.is_inside_base_point(preview_mouse_pos):
			var preview_grid_coord = grid_manager.world_to_base_grid(preview_mouse_pos)
			# Usar tamanho padrão de 3 para preview (maioria das torres)
			var preview_world_pos = grid_manager.base_grid_to_world(preview_grid_coord.x, preview_grid_coord.y, 3)
			
			if placing_tower:
				if grid_manager.can_place_in_grid(preview_grid_coord.x, preview_grid_coord.y, GameConstants.TOWER_SIZE_GRID, 1):
					var preview_size := grid_size_px * GameConstants.TOWER_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					if tex_tower != null:
						draw_texture_rect(tex_tower, preview_rect, false, Color(1, 1, 1, 0.5))
					else:
						draw_rect(preview_rect, Color(0.7,0.9,0.7,0.5))  # verde semi-transparente
					draw_rect(preview_rect, Color(0.5,0.8,0.5), false, 2.0)  # borda verde
				else:
					var preview_size := grid_size_px * GameConstants.TOWER_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					if tex_tower != null:
						draw_texture_rect(tex_tower, preview_rect, false, Color(1, 0.3, 0.3, 0.5))
					else:
						draw_rect(preview_rect, Color(0.9,0.3,0.3,0.5))  # vermelho semi-transparente
					draw_rect(preview_rect, Color(0.8,0.2,0.2), false, 2.0)  # borda vermelha
			
			elif placing_barracks:
				if grid_manager.can_place_in_grid(preview_grid_coord.x, preview_grid_coord.y, GameConstants.BARRACKS_SIZE_GRID, 3):
					var preview_size := grid_size_px * GameConstants.BARRACKS_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					if tex_barracks != null:
						draw_texture_rect(tex_barracks, preview_rect, false, Color(1, 1, 1, 0.5))
					else:
						draw_rect(preview_rect, Color(0.7,0.9,0.7,0.5))
					draw_rect(preview_rect, Color(0.5,0.8,0.5), false, 2.0)
				else:
					var preview_size := grid_size_px * GameConstants.BARRACKS_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					if tex_barracks != null:
						draw_texture_rect(tex_barracks, preview_rect, false, Color(1, 0.3, 0.3, 0.5))
					else:
						draw_rect(preview_rect, Color(0.9,0.3,0.3,0.5))
					draw_rect(preview_rect, Color(0.8,0.2,0.2), false, 2.0)
			
			elif placing_slow_tower:
				if grid_manager.can_place_in_grid(preview_grid_coord.x, preview_grid_coord.y, GameConstants.SLOW_TOWER_SIZE_GRID, 5):
					var preview_size := grid_size_px * GameConstants.SLOW_TOWER_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					if tex_slow_tower != null:
						draw_texture_rect(tex_slow_tower, preview_rect, false, Color(1, 1, 1, 0.5))
					else:
						draw_rect(preview_rect, Color(0.5,0.7,0.9,0.5))
					draw_rect(preview_rect, Color(0.3,0.5,0.7), false, 2.0)
				else:
					var preview_size := grid_size_px * GameConstants.SLOW_TOWER_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					if tex_slow_tower != null:
						draw_texture_rect(tex_slow_tower, preview_rect, false, Color(1, 0.3, 0.3, 0.5))
					else:
						draw_rect(preview_rect, Color(0.9,0.3,0.3,0.5))
					draw_rect(preview_rect, Color(0.8,0.2,0.2), false, 2.0)
			
			elif placing_aoe_tower:
				if grid_manager.can_place_in_grid(preview_grid_coord.x, preview_grid_coord.y, GameConstants.AOE_TOWER_SIZE_GRID, 6):
					var preview_size := grid_size_px * GameConstants.AOE_TOWER_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					if tex_aoe_tower != null:
						draw_texture_rect(tex_aoe_tower, preview_rect, false, Color(1, 1, 1, 0.5))
					else:
						draw_rect(preview_rect, Color(0.9,0.5,0.2,0.5))
					draw_rect(preview_rect, Color(0.7,0.3,0.1), false, 2.0)
				else:
					var preview_size := grid_size_px * GameConstants.AOE_TOWER_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					if tex_aoe_tower != null:
						draw_texture_rect(tex_aoe_tower, preview_rect, false, Color(1, 0.3, 0.3, 0.5))
					else:
						draw_rect(preview_rect, Color(0.9,0.3,0.3,0.5))
					draw_rect(preview_rect, Color(0.8,0.2,0.2), false, 2.0)
			
			elif placing_sniper_tower:
				if grid_manager.can_place_in_grid(preview_grid_coord.x, preview_grid_coord.y, GameConstants.SNIPER_TOWER_SIZE_GRID, 7):
					var preview_size := grid_size_px * GameConstants.SNIPER_TOWER_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					if tex_sniper_tower != null:
						draw_texture_rect(tex_sniper_tower, preview_rect, false, Color(1, 1, 1, 0.5))
					else:
						draw_rect(preview_rect, Color(0.3,0.3,0.3,0.5))
					draw_rect(preview_rect, Color(0.1,0.1,0.1), false, 2.0)
				else:
					var preview_size := grid_size_px * GameConstants.SNIPER_TOWER_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					if tex_sniper_tower != null:
						draw_texture_rect(tex_sniper_tower, preview_rect, false, Color(1, 0.3, 0.3, 0.5))
					else:
						draw_rect(preview_rect, Color(0.9,0.3,0.3,0.5))
					draw_rect(preview_rect, Color(0.8,0.2,0.2), false, 2.0)
			
			elif placing_boost_tower:
				if grid_manager.can_place_in_grid(preview_grid_coord.x, preview_grid_coord.y, GameConstants.BOOST_TOWER_SIZE_GRID, 8):
					var preview_size := grid_size_px * GameConstants.BOOST_TOWER_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					if tex_boost_tower != null:
						draw_texture_rect(tex_boost_tower, preview_rect, false, Color(1, 1, 1, 0.5))
					else:
						draw_rect(preview_rect, Color(0.8,0.8,0.2,0.5))
					draw_rect(preview_rect, Color(0.6,0.6,0.1), false, 2.0)
				else:
					var preview_size := grid_size_px * GameConstants.BOOST_TOWER_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					if tex_boost_tower != null:
						draw_texture_rect(tex_boost_tower, preview_rect, false, Color(1, 0.3, 0.3, 0.5))
					else:
						draw_rect(preview_rect, Color(0.9,0.3,0.3,0.5))
					draw_rect(preview_rect, Color(0.8,0.2,0.2), false, 2.0)
			
			elif placing_shock_tower:
				if grid_manager.can_place_in_grid(preview_grid_coord.x, preview_grid_coord.y, GameConstants.SHOCK_TOWER_SIZE_GRID, 9):
					var preview_size := grid_size_px * GameConstants.SHOCK_TOWER_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					if tex_shock_tower != null:
						draw_texture_rect(tex_shock_tower, preview_rect, false, Color(1, 1, 1, 0.5))
					else:
						draw_rect(preview_rect, Color(0.5,0.3,0.9,0.5))  # roxo para torre de choque
					draw_rect(preview_rect, Color(0.4,0.2,0.8), false, 2.0)
				else:
					var preview_size := grid_size_px * GameConstants.SHOCK_TOWER_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					if tex_shock_tower != null:
						draw_texture_rect(tex_shock_tower, preview_rect, false, Color(1, 0.3, 0.3, 0.5))
					else:
						draw_rect(preview_rect, Color(0.9,0.3,0.3,0.5))
					draw_rect(preview_rect, Color(0.8,0.2,0.2), false, 2.0)
			
			elif placing_healing_station:
				if grid_manager.can_place_in_grid(preview_grid_coord.x, preview_grid_coord.y, GameConstants.HEALING_STATION_SIZE_GRID, 10):
					var preview_size := grid_size_px * GameConstants.HEALING_STATION_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					if tex_healing_station != null:
						draw_texture_rect(tex_healing_station, preview_rect, false, Color(1, 1, 1, 0.5))
					else:
						draw_rect(preview_rect, Color(0.2,0.8,0.4,0.5))
					draw_rect(preview_rect, Color(0.1,0.6,0.3), false, 2.0)
				else:
					var preview_size := grid_size_px * GameConstants.HEALING_STATION_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					if tex_healing_station != null:
						draw_texture_rect(tex_healing_station, preview_rect, false, Color(1, 0.3, 0.3, 0.5))
					else:
						draw_rect(preview_rect, Color(0.9,0.3,0.3,0.5))
					draw_rect(preview_rect, Color(0.8,0.2,0.2), false, 2.0)
			
			elif placing_market:
				var market_preview_world_pos = grid_manager.base_grid_to_world(preview_grid_coord.x, preview_grid_coord.y, GameConstants.MARKET_SIZE_GRID)
				if grid_manager.can_place_in_grid(preview_grid_coord.x, preview_grid_coord.y, GameConstants.MARKET_SIZE_GRID, 11):
					var preview_size := grid_size_px * GameConstants.MARKET_SIZE_GRID
					var preview_rect := Rect2(market_preview_world_pos.x - preview_size/2, market_preview_world_pos.y - preview_size/2, preview_size, preview_size)
					if tex_market != null:
						draw_texture_rect(tex_market, preview_rect, false, Color(1, 1, 1, 0.5))
					else:
						draw_rect(preview_rect, Color(0.2,0.8,0.2,0.5))
				else:
					var preview_size := grid_size_px * GameConstants.MARKET_SIZE_GRID
					var preview_rect := Rect2(market_preview_world_pos.x - preview_size/2, market_preview_world_pos.y - preview_size/2, preview_size, preview_size)
					if tex_market != null:
						draw_texture_rect(tex_market, preview_rect, false, Color(1, 0.3, 0.3, 0.5))
					else:
						draw_rect(preview_rect, Color(0.9,0.3,0.3,0.5))
		
		if placing_mine:
			var tile = _world_to_tile_coords(preview_mouse_pos)
			var preview_pos = grid_manager.tile_center(clamp(tile.x, 0, GameConstants.GRID_COLS - 1), clamp(tile.y, 0, GameConstants.GRID_ROWS - 1))
			var can_place = _is_tile_within_bounds(tile) and _is_walkable_tile(tile) and not grid_manager.is_inside_base_point(preview_mouse_pos) and not _is_in_center_area(preview_mouse_pos) and not _is_mine_tile_occupied(tile)
			var mine_size = 16.0
			var mine_rect = Rect2(preview_pos.x - mine_size/2, preview_pos.y - mine_size/2, mine_size, mine_size)
			if can_place:
				if tex_mine != null:
					draw_texture_rect(tex_mine, mine_rect, false, Color(1, 1, 1, 0.5))
				else:
					draw_circle(preview_pos, 8, Color(0.8,0.2,0.2,0.5))
				draw_circle(preview_pos, 10, Color(0.5,0.1,0.1,0.3), false, 2.0)
			else:
				if tex_mine != null:
					draw_texture_rect(tex_mine, mine_rect, false, Color(1, 0.3, 0.3, 0.5))
				else:
					draw_circle(preview_pos, 8, Color(0.9,0.3,0.3,0.5))
				draw_circle(preview_pos, 10, Color(0.8,0.2,0.2), false, 2.0)
	
		if placing_wall:
			var tile = _world_to_tile_coords(preview_mouse_pos)
			var preview_pos = grid_manager.tile_center(clamp(tile.x, 0, GameConstants.GRID_COLS - 1), clamp(tile.y, 0, GameConstants.GRID_ROWS - 1))
			var can_place = _is_on_path(preview_mouse_pos) and not grid_manager.is_inside_base_point(preview_mouse_pos) and not _is_wall_tile_occupied(tile)
			var wall_size = 30.8
			var wall_rect = Rect2(preview_pos.x - wall_size/2, preview_pos.y - wall_size/2, wall_size, wall_size)
			if can_place:
				if tex_wall_structure != null:
					draw_texture_rect(tex_wall_structure, wall_rect, false, Color(1, 1, 1, 0.5))
				else:
					draw_rect(wall_rect, Color(0.6,0.4,0.2,0.5))
				draw_rect(Rect2(preview_pos.x - wall_size/2 - 2, preview_pos.y - wall_size/2 - 2, wall_size + 4, wall_size + 4), Color(0.5,0.3,0.2,0.3), false, 2.0)
			else:
				if tex_wall_structure != null:
					draw_texture_rect(tex_wall_structure, wall_rect, false, Color(1, 0.3, 0.3, 0.5))
				else:
					draw_rect(wall_rect, Color(0.9,0.3,0.3,0.5))
				draw_rect(Rect2(preview_pos.x - wall_size/2 - 2, preview_pos.y - wall_size/2 - 2, wall_size + 4, wall_size + 4), Color(0.8,0.2,0.2), false, 2.0)
	
	# mostrar alcance da torre selecionada
	if tower_selected_index >= 0 and tower_selected_index < towers.size():
		var tt = towers[tower_selected_index]
		draw_circle(tt.pos, tt.range, Color(0.3,0.6,1.0,0.15))
	
	# mostrar range de efeito da slow tower selecionada
	if slow_selected_index >= 0 and slow_selected_index < slow_towers.size():
		var st = slow_towers[slow_selected_index]
		# Círculo preenchido para mostrar o range de efeito (onde afeta inimigos)
		draw_circle(st.pos, st.range, Color(0.4, 1.0, 0.8, 0.2))
	
	# mostrar range de efeito da boost tower selecionada
	if boost_selected_index >= 0 and boost_selected_index < boost_towers.size():
		var bt = boost_towers[boost_selected_index]
		# Círculo preenchido para mostrar o range de efeito (onde afeta outras torres)
		draw_circle(bt.pos, bt.range, Color(0.6, 0.9, 0.4, 0.2))
	# hero removido - a tenda é o herói

func _update_upgrade_labels() -> void:
	var ov = $CanvasLayer/UpgradeOverlay
	
	# Criar fundo escuro se não existir
	if not ov.has_node("DarkBackground"):
		var dark_bg = ColorRect.new()
		dark_bg.name = "DarkBackground"
		dark_bg.color = Color(0, 0, 0, 0.7)
		dark_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		dark_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE  # não bloquear clique nos botões
		ov.add_child(dark_bg)
		dark_bg.z_index = -1
	
	# Estilizar o painel principal (seguindo estilo do tower_shop_panel)
	var panel = ov.get_node("Panel") as Panel
	if panel:
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.15, 0.15, 0.2, 0.95)  # Similar ao tower shop
		panel_style.border_color = Color(0.3, 0.3, 0.4)  # Borda mais sutil
		panel_style.border_width_left = 2
		panel_style.border_width_top = 2
		panel_style.border_width_right = 2
		panel_style.border_width_bottom = 2
		panel.add_theme_stylebox_override("panel", panel_style)
	
	# Atualizar título
	var title = ov.get_node("Panel/Title") as Label
	if title:
		title.text = "Escolha um Benefício"
		title.add_theme_font_size_override("font_size", 22)
		title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))  # Dourado consistente
	
	# Ajustar tamanho do painel baseado no número de upgrades (mantendo centralizado)
	if panel:
		var num_upgrades = upgrade_options.size()
		var panel_height = 100 + (num_upgrades * 60) + 50  # Título + botões + resume
		var panel_width = 500.0  # Largura fixa
		# Ajustar offsets para manter centralizado (anchors já estão em 0.5, 0.5 na cena)
		panel.offset_left = -panel_width / 2
		panel.offset_top = -panel_height / 2
		panel.offset_right = panel_width / 2
		panel.offset_bottom = panel_height / 2
	
	# Atualizar botão Resume
	var resume_btn = ov.get_node("Panel/BtnResume") as Button
	if resume_btn:
		resume_btn.text = "Continuar"
		# Se não há upgrades disponíveis, sempre habilitar o botão
		# Se há upgrades, habilitar apenas se um foi selecionado
		var should_enable = upgrade_options.is_empty() or benefit_applied
		resume_btn.disabled = not should_enable
		# Posicionar o botão Resume abaixo de todos os botões de upgrade
		var resume_y = 60 + (upgrade_options.size() * 60) + 10
		resume_btn.position = Vector2(180, resume_y)
		var resume_style = StyleBoxFlat.new()
		if should_enable:
			resume_style.bg_color = Color(0.2, 0.6, 0.2, 0.9)
			resume_style.border_color = Color(0.3, 0.8, 0.3)
		else:
			resume_style.bg_color = Color(0.3, 0.3, 0.3, 0.5)
			resume_style.border_color = Color(0.5, 0.5, 0.5, 0.5)
		resume_style.border_width_left = 2
		resume_style.border_width_top = 2
		resume_style.border_width_right = 2
		resume_style.border_width_bottom = 2
		resume_btn.add_theme_stylebox_override("normal", resume_style)
		var resume_hover = resume_style.duplicate()
		if should_enable:
			resume_hover.bg_color = Color(0.3, 0.7, 0.3, 0.9)
		else:
			resume_hover.bg_color = Color(0.4, 0.4, 0.4, 0.9)
		resume_btn.add_theme_stylebox_override("hover", resume_hover)
	
	# Criar botões dinamicamente se necessário (suporta até 10 botões)
	if not panel:
		return  # Se não há painel, não pode continuar
	# Iterar sobre todos os upgrades disponíveis
	for i in range(upgrade_options.size()):
		var btn_name = "Btn" + str(i + 1)
		var btn = panel.get_node_or_null(btn_name) as Button
		
		# Criar botão se não existir
		if btn == null and i < upgrade_options.size():
			btn = Button.new()
			btn.name = btn_name
			panel.add_child(btn)
			# Posicionar botão (60px de altura cada, começando em y=60, com 10px de espaçamento)
			btn.position = Vector2(30, 60 + i * 60)
			btn.size = Vector2(440, 50)
			btn.pressed.connect(func(): _apply_benefit(i))
		
		if btn and i < upgrade_options.size():
			var upgrade = upgrade_options[i]
			var code = upgrade["code"]
			var current_level = hero["levels"].get(code, 0)
			var max_level = upgrade.get("max_level", 999)
			var description = upgrade.get("description", "")
			
			# Texto do botão com nível atual
			btn.text = "%s (Nível %d/%d)" % [upgrade["label"], current_level, max_level]
			btn.tooltip_text = description
			
			# Verificar se atingiu o limite
			if current_level >= max_level:
				btn.disabled = true
				btn.text = "%s (MÁXIMO)" % upgrade["label"]
				# Estilo para botão desabilitado
				var disabled_style = StyleBoxFlat.new()
				disabled_style.bg_color = Color(0.3, 0.3, 0.3, 0.5)
				disabled_style.border_color = Color(0.5, 0.5, 0.5, 0.5)
				disabled_style.border_width_left = 2
				disabled_style.border_width_top = 2
				disabled_style.border_width_right = 2
				disabled_style.border_width_bottom = 2
				btn.add_theme_stylebox_override("disabled", disabled_style)
			else:
				# Botões devem estar habilitados inicialmente, só desabilitar DEPOIS de selecionar
				btn.disabled = false
				
				# Estilos coloridos para cada tipo de upgrade (mais sutis e consistentes)
				var btn_style = StyleBoxFlat.new()
				match code:
					"DMG":
						btn_style.bg_color = Color(0.3, 0.15, 0.15, 0.9)
						btn_style.border_color = Color(0.6, 0.3, 0.3)
					"FIRERATE":
						btn_style.bg_color = Color(0.15, 0.25, 0.35, 0.9)
						btn_style.border_color = Color(0.3, 0.5, 0.7)
					"PIERCE":
						btn_style.bg_color = Color(0.3, 0.15, 0.35, 0.9)
						btn_style.border_color = Color(0.5, 0.3, 0.7)
					"CRIT_CHANCE":
						btn_style.bg_color = Color(0.35, 0.3, 0.15, 0.9)
						btn_style.border_color = Color(0.7, 0.6, 0.3)
					"CRIT_DMG":
						btn_style.bg_color = Color(0.4, 0.25, 0.1, 0.9)
						btn_style.border_color = Color(0.8, 0.5, 0.2)
					_:
						btn_style.bg_color = Color(0.25, 0.25, 0.25, 0.9)
						btn_style.border_color = Color(0.4, 0.4, 0.4)
				
				btn_style.border_width_left = 2
				btn_style.border_width_top = 2
				btn_style.border_width_right = 2
				btn_style.border_width_bottom = 2
				btn.add_theme_stylebox_override("normal", btn_style)
				
				# Estilo hover (mais claro)
				var hover_style = btn_style.duplicate()
				hover_style.bg_color = hover_style.bg_color.lightened(0.15)
				btn.add_theme_stylebox_override("hover", hover_style)
				
				# Estilo pressed
				var pressed_style = btn_style.duplicate()
				pressed_style.bg_color = pressed_style.bg_color.darkened(0.1)
				btn.add_theme_stylebox_override("pressed", pressed_style)
				
				# Fonte maior para melhor legibilidade
				btn.add_theme_font_size_override("font_size", 16)
				btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
				btn.visible = true
	
	# Esconder botões extras que não são necessários (acima do número de upgrades)
	for i in range(upgrade_options.size(), 10):
		var btn_name = "Btn" + str(i + 1)
		var btn = panel.get_node_or_null(btn_name) as Button
		if btn:
			btn.visible = false

func _apply_benefit(i: int) -> void:
	# Permite selecionar ou trocar o benefício antes de confirmar
	if upgrade_options.is_empty() or i < 0 or i >= upgrade_options.size():
		return
	
	var upgrade = upgrade_options[i]
	var code: String = upgrade["code"]
	var current_level = hero["levels"].get(code, 0)
	var max_level = upgrade.get("max_level", 999)
	
	# Verificar se atingiu o limite
	if current_level >= max_level:
		return
	
	# Armazenar seleção (não aplicar ainda)
	selected_benefit_index = i
	benefit_applied = true  # Marcar que há uma seleção (permite continuar)
	
	# Atualizar visual dos botões - permitir trocar seleção
	var ov = $CanvasLayer/UpgradeOverlay
	for j in range(upgrade_options.size()):
		var btn = ov.get_node("Panel/Btn" + str(j + 1)) as Button
		if btn:
			var btn_upgrade = upgrade_options[j]
			var btn_code = btn_upgrade["code"]
			var btn_current_level = hero["levels"].get(btn_code, 0)
			var btn_max_level = btn_upgrade.get("max_level", 999)
			
			if btn_current_level >= btn_max_level:
				# Mantém desabilitado se já está no máximo
				btn.disabled = true
				btn.text = "%s (MÁXIMO)" % btn_upgrade["label"]
			elif j == i:
				# Destacar o botão selecionado (mas ainda habilitado para permitir trocar)
				btn.text = "%s (Nível %d/%d) ✓ Selecionado" % [btn_upgrade["label"], btn_current_level, btn_max_level]
				btn.disabled = false
				
				# Estilo de selecionado
				var selected_style = StyleBoxFlat.new()
				selected_style.bg_color = Color(0.2, 0.4, 0.2, 0.9)
				selected_style.border_color = Color(0.3, 0.8, 0.3)
				selected_style.border_width_left = 3
				selected_style.border_width_top = 3
				selected_style.border_width_right = 3
				selected_style.border_width_bottom = 3
				btn.add_theme_stylebox_override("normal", selected_style)
				
				var hover_style = selected_style.duplicate()
				hover_style.bg_color = Color(0.3, 0.5, 0.3, 0.9)
				btn.add_theme_stylebox_override("hover", hover_style)
			else:
				# Outros botões permanecem habilitados para permitir trocar
				btn.disabled = false
				btn.text = "%s (Nível %d/%d)" % [btn_upgrade["label"], btn_current_level, btn_max_level]
				
				# Restaurar estilo normal
				var btn_style = StyleBoxFlat.new()
				match btn_code:
					"DMG":
						btn_style.bg_color = Color(0.3, 0.15, 0.15, 0.9)
						btn_style.border_color = Color(0.6, 0.3, 0.3)
					"FIRERATE":
						btn_style.bg_color = Color(0.15, 0.25, 0.35, 0.9)
						btn_style.border_color = Color(0.3, 0.5, 0.7)
					"PIERCE":
						btn_style.bg_color = Color(0.3, 0.15, 0.35, 0.9)
						btn_style.border_color = Color(0.5, 0.3, 0.7)
					"CRIT_CHANCE":
						btn_style.bg_color = Color(0.35, 0.3, 0.15, 0.9)
						btn_style.border_color = Color(0.7, 0.6, 0.3)
					"CRIT_DMG":
						btn_style.bg_color = Color(0.4, 0.25, 0.1, 0.9)
						btn_style.border_color = Color(0.8, 0.5, 0.2)
					_:
						btn_style.bg_color = Color(0.25, 0.25, 0.25, 0.9)
						btn_style.border_color = Color(0.4, 0.4, 0.4)
				
				btn_style.border_width_left = 2
				btn_style.border_width_top = 2
				btn_style.border_width_right = 2
				btn_style.border_width_bottom = 2
				btn.add_theme_stylebox_override("normal", btn_style)
				
				var hover_style = btn_style.duplicate()
				hover_style.bg_color = hover_style.bg_color.lightened(0.15)
				btn.add_theme_stylebox_override("hover", hover_style)
	
	# Habilitar botão de continuar
	var resume_btn = ov.get_node("Panel/BtnResume") as Button
	if resume_btn:
		# Se não há upgrades disponíveis, sempre habilitar o botão
		# Se há upgrades, habilitar apenas se um foi selecionado
		var should_enable = upgrade_options.is_empty() or benefit_applied
		resume_btn.disabled = not should_enable
		
		var resume_style = StyleBoxFlat.new()
		if should_enable:
			resume_style.bg_color = Color(0.2, 0.6, 0.2, 0.9)
			resume_style.border_color = Color(0.3, 0.8, 0.3)
		else:
			resume_style.bg_color = Color(0.3, 0.3, 0.3, 0.9)
			resume_style.border_color = Color(0.4, 0.4, 0.4)
		resume_style.border_width_left = 2
		resume_style.border_width_top = 2
		resume_style.border_width_right = 2
		resume_style.border_width_bottom = 2
		resume_btn.add_theme_stylebox_override("normal", resume_style)
		var resume_hover = resume_style.duplicate()
		if should_enable:
			resume_hover.bg_color = Color(0.3, 0.7, 0.3, 0.9)
		else:
			resume_hover.bg_color = Color(0.4, 0.4, 0.4, 0.9)
		resume_btn.add_theme_stylebox_override("hover", resume_hover)

func _apply_selected_benefit() -> void:
	# Aplicar o benefício selecionado
	if upgrade_options.is_empty() or selected_benefit_index < 0 or selected_benefit_index >= upgrade_options.size():
		return
	
	var upgrade = upgrade_options[selected_benefit_index]
	var code: String = upgrade["code"]
	var current_level = hero["levels"].get(code, 0)
	var max_level = upgrade.get("max_level", 999)
	
	# Verificar se atingiu o limite
	if current_level < max_level:
		# Aplicar upgrade usando HeroManager
		if hero_manager:
			hero_manager.apply_upgrade(code)
		else:
			# Fallback (código antigo)
			match code:
				"DMG":
					hero["levels"]["DMG"] += 1
					hero["damage"] += 1
				"FIRERATE":
					hero["levels"]["FIRERATE"] += 1
					hero["fire_rate"] = max(GameConstants.HERO_MIN_FIRE_RATE, hero["fire_rate"] - GameConstants.HERO_FIRE_RATE_REDUCTION)
				"PIERCE":
					hero["levels"]["PIERCE"] += 1
					hero["pierce"] += 1
				"CRIT_CHANCE":
					hero["levels"]["CRIT_CHANCE"] += 1
					hero["crit_chance"] = min(0.20, hero["crit_chance"] + 0.02)
				"CRIT_DMG":
					hero["levels"]["CRIT_DMG"] += 1
					hero["crit_multiplier"] += 0.2

func _resume_after_upgrade() -> void:
	# Se não há upgrades disponíveis, permitir continuar sem aplicar benefício
	if upgrade_options.is_empty():
		# Resetar estado e continuar
		$CanvasLayer/UpgradeOverlay.visible = false
		choosing_upgrade = false
		benefit_applied = false
		selected_benefit_index = -1
		wave_manager.start_next_wave()
		return
	
	# Se há upgrades mas nenhum foi selecionado, não pode continuar
	if not benefit_applied or selected_benefit_index < 0:
		return
	
	# Aplicar o benefício selecionado
	_apply_selected_benefit()
	
	# Resetar estado
	$CanvasLayer/UpgradeOverlay.visible = false
	choosing_upgrade = false
	benefit_applied = false
	selected_benefit_index = -1
	# start next wave now
	wave_manager.start_next_wave()

# Funções antigas removidas - agora estão nos managers:
# _generate_maze() -> GridManager._generate_maze()
# _tile_center() -> grid_manager.tile_center()
# _world_to_base_grid() -> grid_manager.world_to_base_grid()
# _base_grid_to_world() -> grid_manager.base_grid_to_world()
# _can_place_in_grid() -> grid_manager.can_place_in_grid()
# _set_grid_area() -> grid_manager.set_grid_area()
# _clear_grid_area() -> grid_manager.clear_grid_area()

func _is_walkable(c: int, r: int) -> bool:
	return pathfinder.is_walkable(c, r, grid_manager.base_grid)

func _bfs_path(from_c: int, from_r: int, consider_walls: bool = false) -> Array:
	if wave_manager.wave > 0 and (wave_manager.wave % 10 == 0 or enemies.size() > 50):
		pathfinder.invalidate_cache()
	
	# Apenas considerar muralhas se especificado (após colisão)
	if consider_walls:
		pathfinder.set_wall_tiles(wall_tiles)
	else:
		pathfinder.set_wall_tiles({})  # Caminho inicial não considera muralhas
	var path = pathfinder.find_path(from_c, from_r, grid_manager.base_grid)
	
	# Validar o caminho retornado
	if path.is_empty():
		# Tentar novamente sem cache
		pathfinder.invalidate_cache()
		path = pathfinder.find_path(from_c, from_r, grid_manager.base_grid)
	
	var pts := []
	for t in path:
		# Validar que cada ponto do caminho é válido
		if t.x >= 0 and t.x < GameConstants.GRID_COLS and t.y >= 0 and t.y < GameConstants.GRID_ROWS:
			pts.append(grid_manager.tile_center(t.x, t.y))
		else:
			# Se encontrar um ponto inválido, parar e retornar o que temos
			break
	
	# Se ainda não temos pontos válidos, retornar caminho direto
	if pts.is_empty():
		var base_center = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
		var start_pos = grid_manager.tile_center(from_c, from_r)
		pts = [start_pos, base_center]
	
	return pts

func _random_spawn():
	# Coletar células válidas nas bordas (chão e walkable)
	var cells: Array = []
	var right_col = GameConstants.GRID_COLS - 2
	var bottom_row = GameConstants.GRID_ROWS - 2
	
	# Borda superior (linha 1)
	for c in range(1, GameConstants.GRID_COLS-1):
		if grid_manager.grid.size() > 1 and grid_manager.grid[1].size() > c and grid_manager.grid[1][c] == 0 and _is_walkable(c, 1):
			cells.append(Vector2i(c, 1))
	# Borda inferior (linha GRID_ROWS-2)
	for c in range(1, GameConstants.GRID_COLS-1):
		if grid_manager.grid.size() > bottom_row and grid_manager.grid[bottom_row].size() > c and grid_manager.grid[bottom_row][c] == 0 and _is_walkable(c, bottom_row):
			cells.append(Vector2i(c, bottom_row))
	# Borda esquerda (coluna 1)
	for r in range(1, GameConstants.GRID_ROWS-1):
		if grid_manager.grid.size() > r and grid_manager.grid[r].size() > 1 and grid_manager.grid[r][1] == 0 and _is_walkable(1, r):
			cells.append(Vector2i(1, r))
	# Borda direita (coluna GRID_COLS-2)
	for r in range(1, GameConstants.GRID_ROWS-1):
		if grid_manager.grid.size() > r and grid_manager.grid[r].size() > right_col and grid_manager.grid[r][right_col] == 0 and _is_walkable(right_col, r):
			cells.append(Vector2i(right_col, r))
	
	if cells.is_empty():
		# Fallback: tentar encontrar qualquer célula válida nas bordas (sem verificar walkable)
		for c in range(1, GameConstants.GRID_COLS-1):
			if grid_manager.grid.size() > 1 and grid_manager.grid[1].size() > c and grid_manager.grid[1][c] == 0:
				cells.append(Vector2i(c, 1))
		for c in range(1, GameConstants.GRID_COLS-1):
			if grid_manager.grid.size() > bottom_row and grid_manager.grid[bottom_row].size() > c and grid_manager.grid[bottom_row][c] == 0:
				cells.append(Vector2i(c, bottom_row))
		for r in range(1, GameConstants.GRID_ROWS-1):
			if grid_manager.grid.size() > r and grid_manager.grid[r].size() > 1 and grid_manager.grid[r][1] == 0:
				cells.append(Vector2i(1, r))
		for r in range(1, GameConstants.GRID_ROWS-1):
			if grid_manager.grid.size() > r and grid_manager.grid[r].size() > right_col and grid_manager.grid[r][right_col] == 0:
				cells.append(Vector2i(right_col, r))
	
	if cells.is_empty():
		print("Erro: Nenhuma célula de spawn válida encontrada!")
		return null
	
	# Escolher uma célula aleatória
	cells.shuffle()
	var selected = cells[randi() % cells.size()]
	
	# Verificar se o caminho é válido antes de retornar
	var test_path = _bfs_path(selected.x, selected.y)
	if test_path.is_empty():
		# Tentar outra célula se esta não tem caminho válido
		for i in range(min(5, cells.size())):  # Tentar até 5 células
			selected = cells[i]
			test_path = _bfs_path(selected.x, selected.y)
			if not test_path.is_empty():
				break
	
	return selected

func _get_random_enemy_type_for_wave() -> GameConstants.EnemyType:
	"""Retorna um tipo de inimigo aleatório baseado na wave atual (sistema padronizado)"""
	var current_wave = wave_manager.wave if wave_manager else 1
	var available_types = GameConstants.get_available_enemy_types(current_wave)
	
	if available_types.is_empty():
		return GameConstants.EnemyType.ZOMBIE  # Fallback
	
	# Escolher aleatoriamente entre os tipos disponíveis
	return available_types[randi() % available_types.size()]

func _enemy_new(col: int, row: int, enemy_type: GameConstants.EnemyType = GameConstants.EnemyType.ZOMBIE) -> Dictionary:
	"""Cria um novo inimigo do tipo especificado (sistema padronizado)"""
	var pos = grid_manager.tile_center(col, row)
	
	# Obter configuração do tipo de inimigo
	var config = GameConstants.get_enemy_type_config(enemy_type)
	
	# Calcular HP base com multiplicador do tipo
	var hp_multiplier: float = config.get("hp_multiplier", 1.0)
	var initial_hp: float = GameConstants.ENEMY_BASE_HP * hp_multiplier
	var f := _wave_factor()
	var hp := int(max(1, round(initial_hp * f)))
	
	# Aplicar modificadores de wave especial
	if current_special_wave_type == WaveManager.SpecialWaveType.HELL_WAVE:
		hp = int(hp * 0.5)  # 50% menos HP
		hp = max(1, hp)  # Garantir pelo menos 1 HP
	
	var enemy_idx = enemies.size()
	# Calcular caminho único para cada inimigo (criar cópia para evitar compartilhamento)
	var path = _bfs_path(col, row)
	# Verificar se o caminho é válido
	if path.is_empty() or path.size() == 0:
		# Se não há caminho válido, usar movimento direto
		# Criar um caminho simples direto para o centro (fallback)
		var base_center = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
		path = [pos, base_center]  # Incluir posição inicial para garantir movimento
	# Criar uma cópia do path para este inimigo específico e validar pontos
	var path_copy = []
	for p in path:
		if p is Vector2:
			path_copy.append(p)
	# Garantir que sempre há pelo menos um ponto no caminho
	if path_copy.is_empty():
		var base_center = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
		path_copy = [pos, base_center]
	
	# Calcular velocidade base com multiplicador do tipo
	var speed_multiplier: float = config.get("speed_multiplier", 1.0)
	var base_speed: float = GameConstants.ENEMY_BASE_SPEED * f * speed_multiplier
	
	# Aplicar modificadores de velocidade de wave especial
	if current_special_wave_type == WaveManager.SpecialWaveType.MAX_SPEED:
		base_speed *= 1.5  # 50% mais rápido
	elif current_special_wave_type == WaveManager.SpecialWaveType.HELL_WAVE:
		base_speed *= 2.0  # 2x velocidade
	
	# Aplicar modificadores de clima
	if weather_manager:
		base_speed *= weather_manager.get_enemy_speed_multiplier()
		hp = int(hp * weather_manager.get_enemy_hp_multiplier())
	
	# Aplicar cap de velocidade específico do tipo (padrão é 1.0, corredor tem 1.15)
	var max_speed_for_type = GameConstants.ENEMY_MAX_SPEED * config.get("max_speed_multiplier", 1.0)
	if base_speed > max_speed_for_type:
		base_speed = max_speed_for_type
	
	# Criar dicionário do inimigo com tipo
	var e = {
		"pos": pos,
		"speed": base_speed,
		"base_speed": base_speed,
		"hp": hp,
		"max_hp": hp,
		"radius": 9,
		"path": path_copy,
		"path_index": 0,
		"reached": false,
		"idx": enemy_idx,
		"is_boss": false,
		"enemy_type": enemy_type  # Armazenar tipo para renderização
	}
	enemy_effects[enemy_idx] = {"slow_time": 0.0, "slow_amount": 0.0, "freeze_time": 0.0, "fire_time": 0.0, "fire_damage": 0.0}
	return e

func _enemy_new_boss(col: int, row: int) -> Dictionary:
	var pos = grid_manager.tile_center(col, row)
	var initial_hp := GameConstants.BOSS_BASE_HP  # chefe tem muito mais HP (equivalente a 25 hits iniciais)
	var f := _wave_factor()
	var hp := int(max(1, round(initial_hp * f)))
	
	# Aplicar modificadores de wave especial (bosses não são afetados por HELL_WAVE da mesma forma)
	if current_special_wave_type == WaveManager.SpecialWaveType.HELL_WAVE:
		hp = int(hp * 0.75)  # Bosses perdem menos HP (25% menos ao invés de 50%)
		hp = max(1, hp)
	
	var enemy_idx = enemies.size()
	# Calcular caminho único para cada inimigo (não usar cache compartilhado)
	var path = _bfs_path(col, row)
	# Verificar se o caminho é válido
	if path.is_empty() or path.size() == 0:
		# Se não há caminho válido, usar movimento direto
		# Criar um caminho simples direto para o centro (fallback)
		var base_center = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
		path = [pos, base_center]  # Incluir posição inicial para garantir movimento
	# Criar uma cópia do path para este inimigo específico e validar pontos
	var path_copy = []
	for p in path:
		if p is Vector2:
			path_copy.append(p)
	# Garantir que sempre há pelo menos um ponto no caminho
	if path_copy.is_empty():
		var base_center = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
		path_copy = [pos, base_center]
	# Limitar velocidade máxima para evitar bugs em waves muito altas
	var base_speed = GameConstants.ENEMY_BASE_SPEED * f * GameConstants.BOSS_SPEED_MULTIPLIER
	
	# Aplicar modificadores de velocidade de wave especial
	if current_special_wave_type == WaveManager.SpecialWaveType.MAX_SPEED:
		base_speed *= 1.5  # 50% mais rápido
	elif current_special_wave_type == WaveManager.SpecialWaveType.HELL_WAVE:
		base_speed *= 1.5  # Bosses não ficam tão rápidos (1.5x ao invés de 2x)
	
	# Aplicar modificadores de clima
	if weather_manager:
		base_speed *= weather_manager.get_enemy_speed_multiplier()
		hp = int(hp * weather_manager.get_enemy_hp_multiplier())
	
	if base_speed > GameConstants.ENEMY_MAX_SPEED:
		base_speed = GameConstants.ENEMY_MAX_SPEED
	var e = { pos = pos, speed = base_speed, base_speed = base_speed, hp = hp, max_hp = hp, radius = 12, path = path_copy, path_index = 0, reached = false, idx = enemy_idx, is_boss = true }
	enemy_effects[enemy_idx] = {"slow_time": 0.0, "slow_amount": 0.0, "freeze_time": 0.0, "fire_time": 0.0, "fire_damage": 0.0}
	return e

func _enemy_update(e: Dictionary, dt: float) -> void:
	if e["reached"] or e["hp"] <= 0:
		return
	
	var enemy_idx = e.get("idx", -1)
	if enemy_idx >= 0:
		# Garantir que o Dictionary de efeitos existe e tem todas as propriedades necessárias
		if not enemy_effects.has(enemy_idx):
			enemy_effects[enemy_idx] = { "slow_time": 0.0, "slow_amount": 0.0, "freeze_time": 0.0, "fire_time": 0.0, "fire_damage": 0.0 }
		
		var effects = enemy_effects[enemy_idx]
		
		# Garantir que todas as propriedades existem
		if not effects.has("slow_time"):
			effects["slow_time"] = 0.0
		if not effects.has("slow_amount"):
			effects["slow_amount"] = 0.0
		if not effects.has("freeze_time"):
			effects["freeze_time"] = 0.0
		
		# aplicar congelamento (reduz velocidade)
		if effects.get("freeze_time", 0.0) > 0.0:
			effects["freeze_time"] = effects.get("freeze_time", 0.0) - dt
			e["speed"] = e["base_speed"] * 0.3  # reduz velocidade em 70%
		# aplicar slow (reduz velocidade)
		elif effects.get("slow_time", 0.0) > 0.0:
			effects["slow_time"] = effects.get("slow_time", 0.0) - dt
			var slow_amount = effects.get("slow_amount", 0.0)
			var slow_mult = 1.0 - slow_amount  # slow_amount é a porcentagem de redução (0.5 = 50%)
			e["speed"] = e["base_speed"] * slow_mult
		else:
			e["speed"] = e["base_speed"]
		
		# aplicar dano de fogo
		if effects.fire_time > 0.0:
			effects.fire_time -= dt
			var fire_damage = effects.fire_damage * dt
			e["hp"] -= fire_damage
			# Criar indicador de dano ocasionalmente para não poluir a tela (a cada 0.5s)
			if not e.has("last_fire_damage_time"):
				e["last_fire_damage_time"] = 0.0
			e["last_fire_damage_time"] += dt
			if e["last_fire_damage_time"] >= 0.5:
				_create_damage_number(e["pos"], fire_damage * 10.0, false, Color(1.0, 0.5, 0.0))  # laranja para fogo
				e["last_fire_damage_time"] = 0.0
			if e["hp"] <= 0:
				e["hp"] = 0
				e["dying"] = true
				e["dying_time"] = 0.0
				_create_death_animation(e["pos"])
				return
	
	# Limitar velocidade máxima para evitar bugs em waves muito altas
	if e["speed"] > GameConstants.ENEMY_MAX_SPEED:
		e["speed"] = GameConstants.ENEMY_MAX_SPEED
		e["base_speed"] = min(e["base_speed"], GameConstants.ENEMY_MAX_SPEED)
	
	# Verificar se o path está vazio ou inválido
	if not e.has("path") or e["path"].is_empty():
		# Se não há caminho, mover diretamente para o centro
		var basep = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
		var v = basep - e["pos"]
		var d = max(v.length(), 0.0001)
		if d < 8.0:  # Aumentado de 4.0 para 8.0 para garantir detecção
			e["reached"] = true
			var is_boss = e.get("is_boss", false)
			# chefe causa mais dano na base
			var damage_to_base = 15 if is_boss else 5
			base_hp = max(0, base_hp - damage_to_base)
			if base_hp <= 0 and not game_over:
				game_over = true
				paused = true
				_show_game_over_screen()
			return
		# Limitar movimento para não ultrapassar o alvo
		var move_dist = e["speed"] * dt
		if move_dist > d:
			move_dist = d
		e["pos"] += v.normalized() * move_dist
		return
	
	# Garantir que path_index existe e é válido
	if not e.has("path_index"):
		e["path_index"] = 0
	
	if e["path_index"] < 0:
		e["path_index"] = 0
	
	if e["path_index"] >= e["path"].size():
		# Chegou ao fim do caminho, mover diretamente para o centro
		var basep = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
		var v = basep - e["pos"]
		var d = max(v.length(), 0.0001)
		if d < 8.0:  # Aumentado de 4.0 para 8.0 para garantir detecção
			e["reached"] = true
			var is_boss = e.get("is_boss", false)
			# chefe causa mais dano na base
			var damage_to_base = 15 if is_boss else 5
			base_hp = max(0, base_hp - damage_to_base)
			if base_hp <= 0 and not game_over:
				game_over = true
				paused = true
				_show_game_over_screen()
			return
		# Limitar movimento para não ultrapassar o alvo
		var move_dist = e["speed"] * dt
		if move_dist > d:
			move_dist = d
		e["pos"] += v.normalized() * move_dist
		return
	
	# Validar que o índice é válido antes de acessar
	if e["path_index"] < 0 or e["path_index"] >= e["path"].size():
		e["path_index"] = 0
	
	var targ: Vector2 = e["path"][e["path_index"]]
	
	# Validar que o alvo é válido
	if targ == null or not targ is Vector2:
		# Alvo inválido, usar movimento direto
		var basep = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
		var v = basep - e["pos"]
		var move_dist = e["speed"] * dt
		var d = max(v.length(), 0.0001)
		if move_dist > d:
			move_dist = d
		e["pos"] += v.normalized() * move_dist
		return
	
	# Verificar se está próximo do centro ANTES de seguir o caminho
	# Isso garante que inimigos causem dano mesmo se o último ponto do caminho não for exatamente o centro
	var basep = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
	var dist_to_center = e["pos"].distance_to(basep)
	if dist_to_center < 8.0:  # Aumentado de 4.0 para 8.0 para garantir detecção
		e["reached"] = true
		var is_boss = e.get("is_boss", false)
		# chefe causa mais dano na base
		var damage_to_base = 15 if is_boss else 5
		base_hp = max(0, base_hp - damage_to_base)
		if base_hp <= 0 and not game_over:
			game_over = true
			paused = true
			_show_game_over_screen()
		return
	
	# Verificar colisão com muralhas
	var enemy_tile = _world_to_tile_coords(e["pos"])
	var wall_detection_radius = GameConstants.WALL_DAMAGE_RADIUS + 10.0  # Raio maior para detectar muralha antes de chegar perto
	var hit_wall = null
	var hit_wall_idx = -1
	var closest_wall_dist = 9999.0
	
	# Encontrar a muralha mais próxima no caminho do inimigo
	for i in range(walls.size()):
		var w = walls[i]
		if w.hp > 0 and not grid_manager.is_inside_base_point(w.pos):
			var dist_to_wall = e["pos"].distance_to(w.pos)
			# Verificar se a muralha está à frente do inimigo (no caminho)
			if dist_to_wall < wall_detection_radius and dist_to_wall < closest_wall_dist:
				# Verificar se a muralha está no caminho do inimigo
				var to_wall = w.pos - e["pos"]
				var to_target = targ - e["pos"]
				# Se a muralha está na direção geral do movimento, considerar como bloqueio
				if to_target.length() > 0.01:
					var dot = to_wall.normalized().dot(to_target.normalized())
					# Se está na mesma direção geral (ângulo < 90 graus) ou muito próxima
					if dot > -0.3 or dist_to_wall < GameConstants.WALL_DAMAGE_RADIUS:
						hit_wall = w
						hit_wall_idx = i
						closest_wall_dist = dist_to_wall
	
	if hit_wall != null:
		# Inimigo encontrou muralha - mover em direção à muralha e ATACAR
		# O dano será aplicado em _update_walls() baseado na proximidade (WALL_DAMAGE_RADIUS)
		# Não recalcular caminho - o inimigo deve bater na muralha até ela ser destruída
		var to_wall = hit_wall.pos - e["pos"]
		var dist_to_wall = to_wall.length()
		
		# Se já está dentro do raio de dano, parar e atacar
		if dist_to_wall < GameConstants.WALL_DAMAGE_RADIUS:
			# Parar o movimento - o dano será aplicado em _update_walls()
			return
		
		# Caso contrário, mover em direção à muralha até estar dentro do raio de dano
		var move_dist = e["speed"] * dt
		var dir_to_wall = to_wall.normalized()
		var target_dist = GameConstants.WALL_DAMAGE_RADIUS - 2.0  # Parar um pouco antes do raio de dano
		
		if dist_to_wall - move_dist <= target_dist:
			# Chegou perto o suficiente - posicionar exatamente no raio de dano
			e["pos"] = hit_wall.pos - dir_to_wall * target_dist
		else:
			# Continuar se movendo em direção à muralha
			e["pos"] += dir_to_wall * move_dist
		
		# Não seguir o caminho normal - focar na muralha
		return
	
	var v2 = targ - e["pos"]
	var d2 = max(v2.length(), 0.0001)
	
	var move_dist = e["speed"] * dt
	var proximity_threshold = max(2.0, move_dist * 1.5)
	
	if d2 < proximity_threshold:
		# Mover para exatamente o ponto do caminho antes de avançar
		e["pos"] = targ
		e["path_index"] += 1
		# Verificar novamente se chegou ao centro após avançar
		dist_to_center = e["pos"].distance_to(basep)
		if dist_to_center < 8.0:
			e["reached"] = true
			var is_boss = e.get("is_boss", false)
			var damage_to_base = 15 if is_boss else 5
			base_hp = max(0, base_hp - damage_to_base)
			if base_hp <= 0 and not game_over:
				game_over = true
				paused = true
				_show_game_over_screen()
			return
		# Garantir que não ultrapasse o tamanho do array
		if e["path_index"] >= e["path"].size():
			e["path_index"] = e["path"].size() - 1
		return
	
	# Limitar movimento para não ultrapassar o alvo
	if move_dist > d2:
		move_dist = d2
		e["pos"] = targ  # Mover exatamente para o alvo
		e["path_index"] += 1
		# Verificar novamente se chegou ao centro após avançar
		dist_to_center = e["pos"].distance_to(basep)
		if dist_to_center < 8.0:
			e["reached"] = true
			var is_boss = e.get("is_boss", false)
			var damage_to_base = 15 if is_boss else 5
			base_hp = max(0, base_hp - damage_to_base)
			if base_hp <= 0 and not game_over:
				game_over = true
				paused = true
				_show_game_over_screen()
			return
		if e["path_index"] >= e["path"].size():
			e["path_index"] = e["path"].size() - 1
	else:
		# Mover em direção ao alvo
		e["pos"] += v2.normalized() * move_dist
		# Verificar se chegou ao centro após mover
		dist_to_center = e["pos"].distance_to(basep)
		if dist_to_center < 8.0:
			e["reached"] = true
			var is_boss = e.get("is_boss", false)
			var damage_to_base = 15 if is_boss else 5
			base_hp = max(0, base_hp - damage_to_base)
			if base_hp <= 0 and not game_over:
				game_over = true
				paused = true
				_show_game_over_screen()
			return

func _arrow_new(x: float, y: float, target: Vector2) -> Dictionary:
	var dir = (target - Vector2(x,y))
	var d = max(dir.length(), 0.0001)
	# aplicar skill de boost de dano no herói
	var hero_damage = hero["damage"]
	if skills_manager:
		hero_damage *= skills_manager.get_damage_multiplier()
	
	# Velocidade da flecha (fixa)
	var arrow_speed = HERO_ARROW_SPEED
	
	# Verificar crítico
	var is_crit = randf() < hero.get("crit_chance", 0.0)
	if is_crit:
		hero_damage *= hero.get("crit_multiplier", 2.0)
	
	var a = { 
		"pos": Vector2(x,y), 
		"vel": dir/d * arrow_speed, 
		"life": 2.0, 
		"radius": 2, 
		"damage": hero_damage, 
		"pierce": hero["pierce"],
		"is_crit": is_crit
	}
	return a

func _arrow_update(a: Dictionary, dt: float) -> void:
	a["pos"] += a["vel"] * dt
	a["life"] -= dt

func _handle_collisions() -> void:
	for a in arrows:
		if a["life"] <= 0.0:
			continue
		for e in enemies:
			if e["hp"] <= 0 or e["reached"]:
				continue
			if a["pos"].distance_to(e["pos"]) < (a["radius"] + e["radius"]):
				var damage = a["damage"]
				e["hp"] -= damage
				# Criar indicador de dano (amarelo se crítico)
				_create_damage_number(e["pos"], damage, a.get("is_crit", false))
				if e["hp"] <= 0:
					e["hp"] = 0
					e["dying"] = true
					e["dying_time"] = 0.0
					# Criar animação de morte
					_create_death_animation(e["pos"])
					var is_boss = e.get("is_boss", false)
					# chefe dá 20x mais moedas (recompensas escaladas com wave)
					hero["coins"] += get_boss_reward() if is_boss else get_enemy_reward()
					# chance de dropar moeda
					_try_drop_coin(e["pos"])
					_try_drop_talisman(e["pos"])
					# Chance de dropar moedas especiais (waves altas)
					_try_drop_special_currency(e["pos"], is_boss)
					# Rastrear achievements de kills
					_track_enemy_kill(is_boss)
				if a["pierce"] > 0:
					a["pierce"] -= 1
				else:
					a["life"] = 0.0

	for b in tower_bullets:
		if b["life"] <= 0.0:
			continue
		for e in enemies:
			if e["hp"] <= 0 or e["reached"]:
				continue
			if b["pos"].distance_to(e["pos"]) < (b["radius"] + e["radius"]):
				var damage_dealt = b["damage"]
				e["hp"] -= damage_dealt
				
				# Rastrear dano para DPS
				if b.has("tower_id"):
					var tower_id = b["tower_id"]
					if tower_dps_data.has(tower_id):
						tower_dps_data[tower_id]["damage_dealt"] += damage_dealt
				
				# Criar indicador de dano
				_create_damage_number(e["pos"], damage_dealt, false)
				if e["hp"] <= 0:
					e["hp"] = 0
					e["dying"] = true
					e["dying_time"] = 0.0
					# Criar animação de morte
					_create_death_animation(e["pos"])
					var is_boss = e.get("is_boss", false)
					# chefe dá 20x mais moedas (recompensas escaladas com wave)
					hero["coins"] += get_boss_reward() if is_boss else get_enemy_reward()
					# chance de dropar moeda
					_try_drop_coin(e["pos"])
					_try_drop_talisman(e["pos"])
					# Chance de dropar moedas especiais (waves altas)
					_try_drop_special_currency(e["pos"], is_boss)
					# Rastrear achievements de kills
					_track_enemy_kill(is_boss)
				
				# aplicar efeitos de status
				var enemy_idx = e.get("idx", -1)
				if enemy_idx >= 0 and enemy_effects.has(enemy_idx):
					var effects = enemy_effects[enemy_idx]
					if b.get("has_freeze", false):
						effects.freeze_time = max(effects.freeze_time, 3.0)  # congela por 3 segundos
					if b.get("has_fire", false):
						effects.fire_time = max(effects.fire_time, 4.0)  # queima por 4 segundos
						effects.fire_damage = max(effects.fire_damage, b["damage"] * 0.2)  # 20% do dano por segundo
				
				b["life"] = 0.0

func _find_tower_at(p: Vector2, r: float) -> int:
	for i in range(towers.size()):
		if towers[i].pos.distance_to(p) <= r:
			return i
	return -1

func _find_market_at(p: Vector2, r: float) -> int:
	for i in range(markets.size()):
		var m = markets[i]
		if p.distance_to(m.pos) <= r:
			return i
	return -1

func _find_barracks_at(p: Vector2, r: float) -> int:
	for i in range(barracks.size()):
		if barracks[i].pos.distance_to(p) <= r:
			return i
	return -1

func _find_sniper_tower_at(p: Vector2, r: float) -> int:
	for i in range(sniper_towers.size()):
		if sniper_towers[i].pos.distance_to(p) <= r:
			return i
	return -1

func _find_aoe_tower_at(p: Vector2, r: float) -> int:
	for i in range(aoe_towers.size()):
		if aoe_towers[i].pos.distance_to(p) <= r:
			return i
	return -1

func _find_shock_tower_at(p: Vector2, r: float) -> int:
	for i in range(shock_towers.size()):
		if shock_towers[i].pos.distance_to(p) <= r:
			return i
	return -1

func _find_slow_tower_at(p: Vector2, r: float) -> int:
	for i in range(slow_towers.size()):
		if slow_towers[i].pos.distance_to(p) <= r:
			return i
	return -1

func _find_boost_tower_at(p: Vector2, r: float) -> int:
	for i in range(boost_towers.size()):
		if boost_towers[i].pos.distance_to(p) <= r:
			return i
	return -1

func _start_drag_tower(tower_type: String, tower_idx: int, mouse_pos: Vector2) -> void:
	dragging_tower = true
	dragged_tower_type = tower_type
	dragged_tower_index = tower_idx
	
	# Obter posição atual da torre
	var tower_pos: Vector2
	match tower_type:
		"tower":
			tower_pos = towers[tower_idx].pos
		"slow_tower":
			tower_pos = slow_towers[tower_idx].pos
		"aoe_tower":
			tower_pos = aoe_towers[tower_idx].pos
		"sniper_tower":
			tower_pos = sniper_towers[tower_idx].pos
		"boost_tower":
			tower_pos = boost_towers[tower_idx].pos
		"shock_tower":
			tower_pos = shock_towers[tower_idx].pos
		"mine":
			tower_pos = mines[tower_idx].pos
		"wall":
			tower_pos = walls[tower_idx].pos
		"barracks":
			tower_pos = barracks[tower_idx].pos
		"market":
			tower_pos = markets[tower_idx].pos
	
	drag_start_pos = tower_pos
	drag_offset = mouse_pos - tower_pos
	drag_current_pos = mouse_pos
	queue_redraw()

# Função auxiliar para calcular snap de torre (usada tanto no preview quanto no _end_drag_tower)
# IMPORTANTE: Usa a mesma lógica do posicionamento inicial (_try_place_tower)
func _calculate_tower_snap(tower_center_pos: Vector2, tower_size: int) -> Dictionary:
	"""Calcula a posição snapped de uma torre baseada na posição do centro.
	Retorna um Dictionary com: {grid_coord: Vector2i, snapped_world_pos: Vector2, can_place: bool, ignore_area: Rect2i}
	
	Esta função usa EXATAMENTE a mesma lógica do posicionamento inicial:
	1. world_to_base_grid() para converter posição do mundo para grid (usa floor)
	2. base_grid_to_world() para converter grid de volta para posição do mundo (centro)
	"""
	var result = {
		"grid_coord": Vector2i(0, 0),
		"snapped_world_pos": Vector2.ZERO,
		"can_place": false,
		"ignore_area": Rect2i()
	}
	
	# Verificar se está dentro da área da base
	if not grid_manager.is_inside_base_point(tower_center_pos):
		return result
	
	# Usar EXATAMENTE a mesma lógica do posicionamento inicial
	# world_to_base_grid usa floor e retorna o canto superior esquerdo da célula do grid
	var grid_coord = grid_manager.world_to_base_grid(tower_center_pos)
	
	# Verificar se a torre cabe no grid (considerando o tamanho)
	# grid_coord é o canto superior esquerdo, então precisamos verificar se grid_coord + size cabe
	if grid_coord.x + tower_size > GameConstants.BASE_GRID_SIZE:
		grid_coord.x = GameConstants.BASE_GRID_SIZE - tower_size
	if grid_coord.y + tower_size > GameConstants.BASE_GRID_SIZE:
		grid_coord.y = GameConstants.BASE_GRID_SIZE - tower_size
	
	# Garantir que não seja negativo
	grid_coord.x = max(0, grid_coord.x)
	grid_coord.y = max(0, grid_coord.y)
	
	# Converter de volta para posição do mundo (centro da torre)
	# Isso usa EXATAMENTE a mesma função que _try_place_tower usa
	var snapped_world_pos = grid_manager.base_grid_to_world(grid_coord.x, grid_coord.y, tower_size)
	
	result["grid_coord"] = grid_coord
	result["snapped_world_pos"] = snapped_world_pos
	return result

func _end_drag_tower(mouse_pos: Vector2) -> void:
	if not dragging_tower:
		return
	
	# Usar drag_current_pos ao invés de mouse_pos para garantir que use exatamente a mesma posição do preview
	# Isso garante que a torre seja colocada exatamente onde o preview mostra
	# IMPORTANTE: Usar exatamente a mesma lógica do preview
	var tower_center_pos = drag_current_pos - drag_offset
	
	# Determinar tamanho baseado no tipo de torre sendo arrastada
	var tower_size = 3  # padrão
	match dragged_tower_type:
		"tower":
			tower_size = GameConstants.TOWER_SIZE_GRID
		"slow_tower":
			tower_size = GameConstants.SLOW_TOWER_SIZE_GRID
		"aoe_tower":
			tower_size = GameConstants.AOE_TOWER_SIZE_GRID
		"sniper_tower":
			tower_size = GameConstants.SNIPER_TOWER_SIZE_GRID
		"boost_tower":
			tower_size = GameConstants.BOOST_TOWER_SIZE_GRID
		"shock_tower":
			tower_size = GameConstants.SHOCK_TOWER_SIZE_GRID
		"barracks":
			tower_size = GameConstants.BARRACKS_SIZE_GRID
		"market":
			tower_size = GameConstants.MARKET_SIZE_GRID
	
	# Usar função auxiliar para calcular snap - EXATAMENTE a mesma função usada no preview
	var snap_result = _calculate_tower_snap(tower_center_pos, tower_size)
	var grid_coord = snap_result["grid_coord"]
	var snapped_world_pos = snap_result["snapped_world_pos"]
	
	# Garantir que estamos usando exatamente a mesma posição que o preview mostrou
	# Se o snap não funcionou, não tentar mover
	if snapped_world_pos == Vector2.ZERO:
		# Se não está dentro da base, não fazer nada
		if not grid_manager.is_inside_base_point(tower_center_pos):
			dragging_tower = false
			dragged_tower_type = ""
			dragged_tower_index = -1
			drag_start_pos = Vector2.ZERO
			drag_offset = Vector2.ZERO
			drag_current_pos = Vector2.ZERO
			queue_redraw()
			return
		# Se está dentro da base mas snap falhou, tentar usar a posição original
		# (não deveria acontecer, mas por segurança)
		snapped_world_pos = tower_center_pos
	
	# Tentar mover a torre usando o grid_coord calculado (não recalcular!)
	# Isso garante que usamos exatamente o mesmo grid_coord que o preview mostrou
	var moved = false
	match dragged_tower_type:
		"tower":
			moved = _try_move_tower_to_grid(dragged_tower_index, grid_coord)
		"slow_tower":
			moved = _try_move_slow_tower_to_grid(dragged_tower_index, grid_coord)
		"aoe_tower":
			moved = _try_move_aoe_tower_to_grid(dragged_tower_index, grid_coord)
		"sniper_tower":
			moved = _try_move_sniper_tower_to_grid(dragged_tower_index, grid_coord)
		"boost_tower":
			moved = _try_move_boost_tower_to_grid(dragged_tower_index, grid_coord)
		"shock_tower":
			moved = _try_move_shock_tower_to_grid(dragged_tower_index, grid_coord)
		"mine":
			# Para minas, não fazer snap (elas ficam em posições livres)
			# Usar a posição do mouse diretamente (sem snap)
			moved = _try_move_mine(dragged_tower_index, tower_center_pos)
		"wall":
			# Para walls, fazer snap para tile coordinates
			var wall_tile = _world_to_tile_coords(tower_center_pos)
			var wall_world_pos = Vector2(wall_tile.x * GameConstants.TILE_SIZE, wall_tile.y * GameConstants.TILE_SIZE)
			moved = _try_move_wall(dragged_tower_index, wall_world_pos)
		"barracks":
			moved = _try_move_barracks_to_grid(dragged_tower_index, grid_coord)
		"market":
			moved = _try_move_market_to_grid(dragged_tower_index, grid_coord)
	
	# Se não conseguiu mover, restaurar grid na posição original
	if not moved:
		# Restaurar grid na posição original (já foi restaurado nas funções _try_move_*)
		pass
	
	# Limpar estado de drag
	dragging_tower = false
	dragged_tower_type = ""
	dragged_tower_index = -1
	drag_start_pos = Vector2.ZERO
	drag_offset = Vector2.ZERO
	drag_current_pos = Vector2.ZERO
	queue_redraw()

func _open_tower_menu(idx: int, screen_pos: Vector2) -> void:
	if tower_menu == null:
		return
	tower_selected_index = idx
	var t = towers[idx]
	_show_range_indicator(t.pos, t.range, Color(0.3, 0.7, 1.0, 0.65))
	var dirs_count: int = t.dirs.size()
	
	# Calcular custos progressivos
	var range_level = t.levels.get("RANGE", 0)
	var rate_level = t.levels.get("RATE", 0)
	var dmg_level = t.levels.get("DMG", 0)
	# Custo progressivo mais caro para alcance (multiplicador maior)
	var range_cost = int(GameConstants.TOWER_RANGE_COST * pow(1.5, range_level))  # 1.5x por nível ao invés de 1.2x
	var rate_cost = get_upgrade_cost(GameConstants.TOWER_RATE_COST, rate_level)
	var dirs_cost = GameConstants.TOWER_DIRS_COST  # One-time upgrade
	var dmg_cost = get_upgrade_cost(GameConstants.TOWER_DMG_COST, dmg_level)
	var freeze_cost = GameConstants.TOWER_FREEZE_COST  # One-time upgrade
	var fire_cost = GameConstants.TOWER_FIRE_COST  # One-time upgrade
	
	# Custos em esmeraldas (escalados)
	var range_emerald_cost = get_tower_upgrade_emerald_cost("RANGE", range_level)
	var rate_emerald_cost = get_tower_upgrade_emerald_cost("RATE", rate_level)
	var dmg_emerald_cost = get_tower_upgrade_emerald_cost("DMG", dmg_level)
	
	# Verificar se tem esmeraldas suficientes
	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}
	var has_emeralds = currency_info.emeralds > 0
	
	# Limite de alcance baseado no tamanho do mapa (diagonal do centro até o canto mais distante)
	var map_width = float(GameConstants.GRID_COLS * GameConstants.TILE_SIZE)
	var map_height = float(GameConstants.GRID_ROWS * GameConstants.TILE_SIZE)
	var max_range = sqrt(map_width * map_width + map_height * map_height) * 0.5  # Metade da diagonal
	var can_range: bool = hero["coins"] >= range_cost and t.range < max_range
	var can_rate: bool = hero["coins"] >= rate_cost and t.fire_rate > GameConstants.TOWER_MIN_FIRE_RATE
	var can_dirs: bool = hero["coins"] >= dirs_cost and dirs_count < 4
	var can_dmg: bool = hero["coins"] >= dmg_cost
	var can_freeze: bool = hero["coins"] >= freeze_cost and not t.get("has_freeze", false)
	var can_fire: bool = hero["coins"] >= fire_cost and not t.get("has_fire", false)
	
	# Verificar upgrades com esmeraldas
	var can_range_emerald: bool = currency_info.emeralds >= range_emerald_cost and t.range < max_range
	var can_rate_emerald: bool = currency_info.emeralds >= rate_emerald_cost and t.fire_rate > GameConstants.TOWER_MIN_FIRE_RATE
	var can_dmg_emerald: bool = currency_info.emeralds >= dmg_emerald_cost
	
	# Atualizar textos dos itens do menu
	# Estrutura do menu: 0=Alcance💰, 1=Alcance💎, 2=Separador, 3=Cadência💰, 4=Cadência💎, 5=Separador, 6=Direções, 7=Separador, 8=Dano💰, 9=Dano💎, 10=Separador, 11=Congelamento, 12=Fogo
	tower_menu.set_item_text(0, "Alcance +60 (💰 %d moedas)" % range_cost)
	tower_menu.set_item_text(1, "Alcance +60 (🟢 %d esmeraldas)" % range_emerald_cost)
	tower_menu.set_item_text(3, "Cadência + (💰 %d moedas)" % rate_cost)
	tower_menu.set_item_text(4, "Cadência + (🟢 %d esmeraldas)" % rate_emerald_cost)
	tower_menu.set_item_text(6, "+4 Direções (💰 %d moedas)" % dirs_cost)
	tower_menu.set_item_text(8, "Dano +0.5 (💰 %d moedas)" % dmg_cost)
	tower_menu.set_item_text(9, "Dano +0.5 (🟢 %d esmeraldas)" % dmg_emerald_cost)
	tower_menu.set_item_text(11, "Congelamento (💰 %d moedas)" % freeze_cost)
	tower_menu.set_item_text(12, "Fogo (💰 %d moedas)" % fire_cost)
	
	# Desabilitar itens se não tiver recursos suficientes
	tower_menu.set_item_disabled(0, not can_range)  # Alcance com moedas
	tower_menu.set_item_disabled(1, not can_range_emerald)  # Alcance com esmeraldas
	tower_menu.set_item_disabled(3, not can_rate)  # Cadência com moedas
	tower_menu.set_item_disabled(4, not can_rate_emerald)  # Cadência com esmeraldas
	tower_menu.set_item_disabled(6, not can_dirs)  # Direções
	tower_menu.set_item_disabled(8, not can_dmg)  # Dano com moedas
	tower_menu.set_item_disabled(9, not can_dmg_emerald)  # Dano com esmeraldas
	tower_menu.set_item_disabled(11, not can_freeze)  # Congelamento
	tower_menu.set_item_disabled(12, not can_fire)  # Fogo
	tower_menu.position = screen_pos
	tower_menu.popup()

func _on_tower_menu_pressed(id: int) -> void:
	if tower_selected_index < 0 or tower_selected_index >= towers.size():
		return
	var t = towers[tower_selected_index]
	
	# Calcular custos progressivos
	var range_level = t.levels.get("RANGE", 0)
	var rate_level = t.levels.get("RATE", 0)
	var dmg_level = t.levels.get("DMG", 0)
	
	# Verificar esmeraldas disponíveis
	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}
	
	match id:
		1:  # Alcance com moedas
			var cost = int(GameConstants.TOWER_RANGE_COST * pow(1.5, range_level))
			var map_width = float(GameConstants.GRID_COLS * GameConstants.TILE_SIZE)
			var map_height = float(GameConstants.GRID_ROWS * GameConstants.TILE_SIZE)
			var max_range = sqrt(map_width * map_width + map_height * map_height) * 0.5
			if hero["coins"] >= cost and t.range < max_range:
				t.range += 60.0
				t.range = min(t.range, max_range)
				t.levels["RANGE"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
				# Atualizar progresso de quests
				if quest_manager:
					quest_manager.update_quest_progress(GameConstants.QuestType.UPGRADE_TOWERS, 1)
		11:  # Alcance com esmeraldas
			var emerald_cost = get_tower_upgrade_emerald_cost("RANGE", range_level)
			var map_width = float(GameConstants.GRID_COLS * GameConstants.TILE_SIZE)
			var map_height = float(GameConstants.GRID_ROWS * GameConstants.TILE_SIZE)
			var max_range = sqrt(map_width * map_width + map_height * map_height) * 0.5
			if currency_info.emeralds >= emerald_cost and t.range < max_range:
				special_currency_manager.spend_emeralds(emerald_cost)
				t.range += 60.0
				t.range = min(t.range, max_range)
				t.levels["RANGE"] += 1
				_update_special_currency_labels()
				# Atualizar progresso de quests
				if quest_manager:
					quest_manager.update_quest_progress(GameConstants.QuestType.UPGRADE_TOWERS, 1)
		2:  # Cadência com moedas
			var cost = get_upgrade_cost(GameConstants.TOWER_RATE_COST, rate_level)
			if hero["coins"] >= cost and t.fire_rate > GameConstants.TOWER_MIN_FIRE_RATE:
				t.fire_rate = max(GameConstants.TOWER_MIN_FIRE_RATE, t.fire_rate - GameConstants.TOWER_FIRE_RATE_REDUCTION)
				t.levels["RATE"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
				# Atualizar progresso de quests
				if quest_manager:
					quest_manager.update_quest_progress(GameConstants.QuestType.UPGRADE_TOWERS, 1)
		12:  # Cadência com esmeraldas
			var emerald_cost = get_tower_upgrade_emerald_cost("RATE", rate_level)
			if currency_info.emeralds >= emerald_cost and t.fire_rate > GameConstants.TOWER_MIN_FIRE_RATE:
				special_currency_manager.spend_emeralds(emerald_cost)
				t.fire_rate = max(GameConstants.TOWER_MIN_FIRE_RATE, t.fire_rate - GameConstants.TOWER_FIRE_RATE_REDUCTION)
				t.levels["RATE"] += 1
				_update_special_currency_labels()
				# Atualizar progresso de quests
				if quest_manager:
					quest_manager.update_quest_progress(GameConstants.QuestType.UPGRADE_TOWERS, 1)
		3:  # +4 Direções
			if hero["coins"] >= GameConstants.TOWER_DIRS_COST and t.dirs.size() < 4:
				# adiciona 4 direções cardinais se ainda não tem
				var cardinals := [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1)]
				var new_dirs: Array = []
				for d in cardinals:
					var found := false
					for existing in t.dirs:
						if existing.distance_to(d) < 0.1:
							found = true
							break
					if not found:
						new_dirs.append(d)
				t.dirs = t.dirs + new_dirs
				t.levels["DIRS"] += 1
				hero["coins"] -= GameConstants.TOWER_DIRS_COST
				_track_coin_spent(GameConstants.TOWER_DIRS_COST)
		4:  # Dano com moedas
			var cost = get_upgrade_cost(GameConstants.TOWER_DMG_COST, dmg_level)
			if hero["coins"] >= cost:
				t.damage += 0.5
				t.levels["DMG"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
				# Atualizar progresso de quests
				if quest_manager:
					quest_manager.update_quest_progress(GameConstants.QuestType.UPGRADE_TOWERS, 1)
		14:  # Dano com esmeraldas
			var emerald_cost = get_tower_upgrade_emerald_cost("DMG", dmg_level)
			if currency_info.emeralds >= emerald_cost:
				special_currency_manager.spend_emeralds(emerald_cost)
				t.damage += 0.5
				t.levels["DMG"] += 1
				_update_special_currency_labels()
				# Atualizar progresso de quests
				if quest_manager:
					quest_manager.update_quest_progress(GameConstants.QuestType.UPGRADE_TOWERS, 1)
		5:  # Congelamento
			if hero["coins"] >= GameConstants.TOWER_FREEZE_COST and not t.get("has_freeze", false):
				t["has_freeze"] = true
				t.levels["FREEZE"] = 1
				hero["coins"] -= GameConstants.TOWER_FREEZE_COST
				_track_coin_spent(GameConstants.TOWER_FREEZE_COST)
		6:  # Fogo
			if hero["coins"] >= GameConstants.TOWER_FIRE_COST and not t.get("has_fire", false):
				t["has_fire"] = true
				t.levels["FIRE"] = 1
				hero["coins"] -= GameConstants.TOWER_FIRE_COST
				_track_coin_spent(GameConstants.TOWER_FIRE_COST)
	towers[tower_selected_index] = t
	
	# Guardar a posição do menu antes que ele feche para reabri-lo
	var saved_menu_pos = tower_menu.position if tower_menu else Vector2.ZERO
	
	# Reabrir o menu imediatamente após o upgrade com valores atualizados
	keep_menu_open = true
	_reopen_tower_menu_immediately(saved_menu_pos)

func _reopen_tower_menu_immediately(menu_pos: Vector2) -> void:
	"""Reabre o menu de torre na mesma posição após um upgrade"""
	if not keep_menu_open:
		return
	if tower_selected_index < 0 or tower_selected_index >= towers.size():
		keep_menu_open = false
		return
	if choosing_upgrade or game_over:
		keep_menu_open = false
		return
	
	# Usar call_deferred para garantir que o menu tenha fechado primeiro
	call_deferred("_actually_reopen_tower_menu", menu_pos)

func _actually_reopen_tower_menu(menu_pos: Vector2) -> void:
	"""Reabre efetivamente o menu após o fechamento"""
	if not keep_menu_open:
		return
	if tower_selected_index < 0 or tower_selected_index >= towers.size():
		keep_menu_open = false
		return
	if choosing_upgrade or game_over:
		keep_menu_open = false
		return
	
	# Reabrir o menu na mesma posição
	_open_tower_menu(tower_selected_index, menu_pos)
	keep_menu_open = false

func _try_shoot(target: Vector2) -> void:
	if hero["cooldown"] > 0.0:
		return
	arrows.append(_arrow_new(hero["x"], hero["y"], target))
	hero["cooldown"] = hero["fire_rate"]

func _calculate_leading_target(enemy: Dictionary, hero_pos: Vector2) -> Vector2:
	var enemy_pos: Vector2 = enemy["pos"]
	var enemy_velocity = _get_enemy_velocity(enemy)
	var predicted = enemy_pos
	for i in range(2):
		var to_pred = predicted - hero_pos
		var travel_time = to_pred.length() / HERO_ARROW_SPEED
		predicted = enemy_pos + enemy_velocity * travel_time
	
	if randf() < 0.30:
		var miss_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		if miss_dir.length() > 0.001:
			miss_dir = miss_dir.normalized()
			var miss_distance = GameConstants.TILE_SIZE * randf_range(1.2, 2.5)  # Aumentado desvio aleatório
			predicted += miss_dir * miss_distance
	
	return predicted

func _get_enemy_velocity(enemy: Dictionary) -> Vector2:
	var speed = enemy.get("speed", GameConstants.ENEMY_BASE_SPEED)
	if speed <= 0.0:
		return Vector2.ZERO
	if enemy.has("path") and enemy.has("path_index"):
		var idx: int = enemy["path_index"]
		var path: Array = enemy["path"]
		if idx < path.size():
			var target_point = path[idx]
			if target_point is Vector2:
				var dir = (target_point - enemy["pos"])
				if dir.length() > 0.01:
					return dir.normalized() * speed
	var base_center = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
	var to_base = base_center - enemy["pos"]
	if to_base.length() > 0.01:
		return to_base.normalized() * speed
	return Vector2.ZERO

# Retorna a direção do inimigo como string: "up", "down", "left", "right"
func _get_enemy_direction(enemy: Dictionary) -> String:
	var velocity = _get_enemy_velocity(enemy)
	if velocity.length() < 0.01:
		return "down"  # direção padrão
	
	var dir = velocity.normalized()
	var angle = atan2(dir.y, dir.x)
	
	# Converter ângulo para direção cardinal
	# -45 a 45 graus = direita (→)
	# 45 a 135 graus = baixo (↓)
	# 135 a 225 ou -135 a -180 = esquerda (←)
	# -135 a -45 graus = cima (↑)
	
	if angle >= -PI/4 and angle < PI/4:
		return "right"
	elif angle >= PI/4 and angle < 3*PI/4:
		return "down"
	elif angle >= 3*PI/4 or angle < -3*PI/4:
		return "left"
	else:  # -3*PI/4 a -PI/4
		return "up"

func _find_mine_at(world_pos: Vector2, radius: float = 12.0) -> int:
	for i in range(mines.size()):
		var tile = Vector2i(int(mines[i].grid_x), int(mines[i].grid_y))
		var tile_center = grid_manager.tile_center(tile.x, tile.y)
		if world_pos.distance_to(tile_center) <= radius:
			return i
	return -1

func _find_wall_at(world_pos: Vector2, radius: float = 15.0) -> int:
	for i in range(walls.size()):
		if walls[i].hp > 0:
			if world_pos.distance_to(walls[i].pos) <= radius:
				return i
	return -1

func _create_special_currency_labels(tb: Panel) -> void:
	"""Cria labels para mostrar esmeraldas e diamantes no HUD"""
	# Verificar se já existem
	if tb.has_node("LblEmeralds") and tb.has_node("LblDiamonds"):
		emerald_label = tb.get_node("LblEmeralds")
		diamond_label = tb.get_node("LblDiamonds")
		return
	
	# Criar label de Esmeraldas (mesmo tamanho e espaçamento maior)
	emerald_label = Label.new()
	emerald_label.name = "LblEmeralds"
	emerald_label.text = "🟢 0"
	emerald_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.3))  # Verde
	emerald_label.add_theme_font_size_override("font_size", 18)  # Mesmo tamanho que moedas
	emerald_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	# Posicionar após moedas com maior espaçamento (💰 X ocupa ~80px, então colocar em 340 com espaçamento de 90px)
	emerald_label.layout_mode = 0  # Usar layout absoluto
	emerald_label.offset_left = 340
	emerald_label.offset_top = 10
	tb.add_child(emerald_label)
	
	# Criar label de Diamantes (mesmo tamanho e espaçamento maior)
	diamond_label = Label.new()
	diamond_label.name = "LblDiamonds"
	diamond_label.text = "💎 0"
	diamond_label.add_theme_color_override("font_color", Color(0.4, 0.6, 1.0))  # Azul brilhante
	diamond_label.add_theme_font_size_override("font_size", 18)  # Mesmo tamanho que moedas
	diamond_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	# Posicionar após esmeraldas com maior espaçamento (mesmo espaçamento de 90px)
	diamond_label.layout_mode = 0  # Usar layout absoluto
	diamond_label.offset_left = 430
	diamond_label.offset_top = 10
	tb.add_child(diamond_label)

func _update_special_currency_labels() -> void:
	"""Atualiza os labels de moedas especiais"""
	if not special_currency_manager:
		return
	
	var tb = $CanvasLayer/HUD/TopBar
	if not tb:
		return
	
	# Garantir que os labels existam
	if not tb.has_node("LblEmeralds") or not tb.has_node("LblDiamonds"):
		_create_special_currency_labels(tb)
	
	# Obter referências aos labels se não existirem
	if not emerald_label or not diamond_label:
		if tb.has_node("LblEmeralds"):
			emerald_label = tb.get_node("LblEmeralds")
		if tb.has_node("LblDiamonds"):
			diamond_label = tb.get_node("LblDiamonds")
	
	# Atualizar valores
	var currency_info = special_currency_manager.get_currency_info()
	
	if emerald_label:
		emerald_label.text = "🟢 %d" % currency_info.emeralds
	
	if diamond_label:
		diamond_label.text = "💎 %d" % currency_info.diamonds

# Funções de quests removidas - agora estão no Menu.gd

func _create_admin_menu(tb: Panel) -> void:
	# Criar menu de admin apenas se isAdmin estiver ativado
	if not isAdmin:
		# Esconder botão Kill All se existir
		if tb.has_node("BtnKillAll"):
			tb.get_node("BtnKillAll").visible = false
		return
	
	# Esconder botão Kill All antigo
	if tb.has_node("BtnKillAll"):
		tb.get_node("BtnKillAll").visible = false
	
	# Remover botão +10 Waves antigo se existir
	if tb.has_node("BtnJumpWave10"):
		tb.get_node("BtnJumpWave10").queue_free()
	
	# Criar container para o menu de admin
	var menu_container = Control.new()
	menu_container.name = "AdminMenuContainer"
	menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tb.add_child(menu_container)
	
	# Criar PopupMenu para admin
	admin_menu = PopupMenu.new()
	admin_menu.name = "AdminMenu"
	admin_menu.add_item("Kill All", 1)
	admin_menu.add_item("+10 Waves", 2)
	admin_menu.add_item("+100 Moedas", 3)
	admin_menu.add_item("+1000 Moedas", 4)
	admin_menu.add_item("+100 Esmeraldas", 5)
	admin_menu.id_pressed.connect(_on_admin_menu_pressed)
	menu_container.add_child(admin_menu)
	
	# Criar botão que abre o menu (posicionar após mutar/volume)
	admin_menu_button = Button.new()
	admin_menu_button.name = "BtnAdmin"
	admin_menu_button.text = "Admin"  # Mantém "Admin" (termo técnico)
	admin_menu_button.layout_mode = 1  # Usar layout com anchors
	admin_menu_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	# Admin: 100px de largura, após Volume (que termina em -400), com 10px de espaçamento
	admin_menu_button.offset_left = -410  # 10px após Volume
	admin_menu_button.offset_top = 8
	admin_menu_button.offset_right = -310  # 100px de largura, terminar 10px antes de Quests
	admin_menu_button.offset_bottom = 36
	
	# Estilizar botão admin
	var admin_btn_style_normal = StyleBoxFlat.new()
	admin_btn_style_normal.bg_color = Color(0.4, 0.2, 0.6)
	admin_btn_style_normal.border_color = Color(0.6, 0.3, 0.8)
	admin_btn_style_normal.border_width_left = 1
	admin_btn_style_normal.border_width_top = 1
	admin_btn_style_normal.border_width_right = 1
	admin_btn_style_normal.border_width_bottom = 1
	admin_menu_button.add_theme_stylebox_override("normal", admin_btn_style_normal)
	
	var admin_btn_style_hover = StyleBoxFlat.new()
	admin_btn_style_hover.bg_color = Color(0.5, 0.3, 0.7)
	admin_btn_style_hover.border_color = Color(0.7, 0.4, 0.9)
	admin_btn_style_hover.border_width_left = 1
	admin_btn_style_hover.border_width_top = 1
	admin_btn_style_hover.border_width_right = 1
	admin_btn_style_hover.border_width_bottom = 1
	admin_menu_button.add_theme_stylebox_override("hover", admin_btn_style_hover)
	
	admin_menu_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	admin_menu_button.add_theme_font_size_override("font_size", 12)
	
	admin_menu_button.pressed.connect(_on_admin_button_pressed)
	tb.add_child(admin_menu_button)

func _on_admin_button_pressed() -> void:
	# Abrir menu de admin na posição do botão
	var screen_pos = admin_menu_button.global_position + Vector2(0, admin_menu_button.size.y)
	admin_menu.position = screen_pos
	admin_menu.popup()

func _on_admin_menu_pressed(id: int) -> void:
	match id:
		1:  # Kill All
			enemies.clear()
			print("Admin: Todos os inimigos foram eliminados")
		2:  # +10 Waves
			_jump_10_waves()
		3:  # +100 Moedas
			_add_100_coins()
		4:  # +1000 Moedas
			_add_1000_coins()
		5:  # +100 Esmeraldas
			_add_100_emeralds()

func _jump_10_waves() -> void:
	# Pular 10 waves a partir da wave atual
	var current_wave = wave_manager.wave
	wave_manager.jump_to_wave(current_wave + 10)
	enemies.clear()
	choosing_upgrade = false
	benefit_applied = false
	$CanvasLayer/UpgradeOverlay.visible = false
	print("Admin: Pulou 10 waves (agora na wave %d)" % wave_manager.wave)

func _add_100_coins() -> void:
	# Adicionar 100 moedas ao jogador
	hero["coins"] += 100
	print("Admin: +100 moedas adicionadas (total: %d)" % hero["coins"])

func _add_1000_coins() -> void:
	# Adicionar 1000 moedas ao jogador
	hero["coins"] += 1000
	print("Admin: +1000 moedas adicionadas (total: %d)" % hero["coins"])

func _add_100_emeralds() -> void:
	# Adicionar 100 esmeraldas ao jogador
	if special_currency_manager:
		special_currency_manager.add_emeralds(100)
		print("Admin: +100 esmeraldas adicionadas")
		if notification_manager:
			notification_manager.show_notification("+100 Esmeraldas!", 3.0, NotificationManager.NotificationPosition.TOP_CENTER, Color(0.2, 0.8, 0.3))

# Variáveis de reset de perks removidas - agora no Menu.gd

# Funções de reset de perks removidas - agora estão no Menu.gd dentro do diálogo de perks

func _on_upgrade_hero_home() -> void:
	if hero_home_level >= HERO_HOME_MAX_LEVEL:
		print("Hero home já está no nível máximo: ", hero_home_level)
		return
	var next_level = hero_home_level + 1
	var cost = _get_hero_home_upgrade_cost(next_level)
	if cost <= 0:
		print("Custo inválido para nível ", next_level, ": ", cost)
		return
	if hero["coins"] < cost:
		print("Moedas insuficientes. Tem: ", hero["coins"], ", precisa: ", cost)
		return
	print("Upgrading hero home de nível ", hero_home_level, " para ", next_level, " com custo ", cost)
	hero["coins"] -= cost
	_track_coin_spent(cost)
	hero_home_level = next_level
	# Atualizar hero_manager ANTES de aplicar efeitos
	if hero_manager:
		hero_manager.hero_home_level = next_level
	_apply_hero_home_upgrade_effects(next_level)
	_update_hero_home_panel_ui()
	_update_tower_shop_ui()  # Atualizar UI da loja também
	queue_redraw()

func _on_wave_started(wave_number: int, _is_boss_wave: bool, special_wave_type: WaveManager.SpecialWaveType):
	# Resetar dados de DPS da wave anterior
	for tower_id in tower_dps_data.keys():
		if tower_dps_data[tower_id].has("wave_damage"):
			tower_dps_data[tower_id]["wave_damage"][wave_number - 1] = tower_dps_data[tower_id].get("damage_dealt", 0.0)
		tower_dps_data[tower_id]["damage_dealt"] = 0.0
		tower_dps_data[tower_id]["shots"] = 0
	if ((wave_number + 1) % 5) == 0:
		_show_boss_warning("ALERTA! Boss chegando na próxima wave!")
	
	# Sistema de waves especiais
	var previous_special_wave_type = current_special_wave_type
	current_special_wave_type = special_wave_type
	perfect_wave_bonus_given = false
	
	# Sistema de clima
	if weather_manager:
		var old_weather = weather_manager.current_weather
		var weather_changed = weather_manager.update_weather(wave_number)
		# Mostrar aviso apenas quando o clima muda para um novo tipo (não quando expira ou permanece o mesmo)
		if weather_changed and weather_manager.current_weather != WeatherManager.WeatherType.NONE and weather_manager.current_weather != old_weather:
			_show_weather_alert(wave_number)
		_apply_weather_effects()
	
	# Gerenciar alerta de wave especial
	if special_wave_type == WaveManager.SpecialWaveType.NONE and previous_special_wave_type != WaveManager.SpecialWaveType.NONE:
		# Wave especial terminou - esconder alerta imediatamente
		if special_wave_alert_label:
			special_wave_alert_label.visible = false
			special_wave_alert_timer = 0.0
		special_wave_coin_multiplier = 1.0
	elif special_wave_type != WaveManager.SpecialWaveType.NONE and special_wave_type != previous_special_wave_type:
		# Nova wave especial iniciou - mostrar alerta
		_show_special_wave_alert(wave_number, special_wave_type)
		# Aplicar multiplicador de moedas baseado no tipo de wave
		match special_wave_type:
			WaveManager.SpecialWaveType.NIGHT_HORDE:
				special_wave_coin_multiplier = 1.5
			WaveManager.SpecialWaveType.DOUBLE_COINS:
				special_wave_coin_multiplier = 2.0
			WaveManager.SpecialWaveType.MAX_SPEED:
				special_wave_coin_multiplier = 2.0
			WaveManager.SpecialWaveType.BOSS_RUSH:
				special_wave_coin_multiplier = 3.0
			WaveManager.SpecialWaveType.PERFECT_WAVE:
				special_wave_coin_multiplier = 1.0  # Bônus será dado se completar sem perder HP
			WaveManager.SpecialWaveType.HELL_WAVE:
				special_wave_coin_multiplier = 1.5
			_:
				special_wave_coin_multiplier = 1.0
	elif special_wave_type == WaveManager.SpecialWaveType.NONE:
		# Wave normal (sem wave especial anterior) - garantir que alerta está escondido
		if special_wave_alert_label and special_wave_alert_label.visible:
			special_wave_alert_label.visible = false
			special_wave_alert_timer = 0.0
		special_wave_coin_multiplier = 1.0
	else:
		special_wave_coin_multiplier = 1.0
	
	# Rastrear HP da base no início da onda para achievement de onda perfeita
	current_wave_base_hp_start = base_hp
	
	# Rastrear achievements de ondas
	achievement_manager.set_progress("wave_10", wave_number)
	achievement_manager.set_progress("wave_25", wave_number)
	achievement_manager.set_progress("wave_50", wave_number)
	achievement_manager.set_progress("wave_100", wave_number)
	achievement_manager.set_progress("wave_200", wave_number)
	achievement_manager.set_progress("wave_500", wave_number)

func _on_buy_tower() -> void:
	if placing_tower:
		return
	var tower_cost_check = get_tower_cost(GameConstants.TOWER_COST)
	if hero["coins"] < tower_cost_check:
		return
	if towers.size() >= GameConstants.MAX_TOWERS:
		return  # limite de torres atingido
	placing_tower = true
	placing_barracks = false

# Blocos removidos - substituídos por Muralhas

func _on_buy_barracks() -> void:
	if placing_barracks:
		return
	var barracks_cost_check = get_tower_cost(GameConstants.BARRACKS_COST)
	if hero["coins"] < barracks_cost_check:
		return
	if barracks.size() >= GameConstants.MAX_BARRACKS:
		return  # limite de quartéis atingido
	placing_barracks = true
	placing_tower = false

func _on_buy_menu_pressed(id: int) -> void:
	match id:
		1:  # Torre
			_on_buy_tower()
		2:  # Quartel
			_on_buy_barracks()
		3:  # Mina
			_on_buy_mine()
		4:  # Slow Tower
			_on_buy_slow_tower()
		5:  # AOE Tower
			_on_buy_aoe_tower()
		6:  # Sniper Tower
			_on_buy_sniper_tower()
		7:  # Boost Tower
			_on_buy_boost_tower()
		8:  # Shock Tower
			_on_buy_shock_tower()
		9:  # Muralha
			_on_buy_wall()
		10:  # Healing Station
			_on_buy_healing_station()

func _open_barracks_menu(idx: int, screen_pos: Vector2) -> void:
	if barracks_menu == null:
		return
	barracks_selected_index = idx
	var b = barracks[idx]
	
	# Calcular custos progressivos
	var dmg_level = b.levels.get("DMG", 0)
	var hold_level = b.levels.get("HOLD", 0)
	var spawn_rate_level = b.levels.get("SPAWN_RATE", 0)
	var projectile_speed_level = b.levels.get("PROJECTILE_SPEED", 0)
	var dmg_cost = get_upgrade_cost(GameConstants.BARRACKS_DMG_COST, dmg_level)
	var hold_cost = get_upgrade_cost(GameConstants.BARRACKS_HOLD_COST, hold_level)
	var spawn_rate_cost = get_upgrade_cost(GameConstants.BARRACKS_SPAWN_RATE_COST, spawn_rate_level)
	var projectile_speed_cost = get_upgrade_cost(GameConstants.BARRACKS_PROJECTILE_SPEED_COST, projectile_speed_level)
	
	# Custos em esmeraldas (escalados)
	var dmg_emerald_cost = get_tower_upgrade_emerald_cost("DMG", dmg_level)
	var hold_emerald_cost = get_tower_upgrade_emerald_cost("HOLD", hold_level)
	var spawn_rate_emerald_cost = get_tower_upgrade_emerald_cost("RATE", spawn_rate_level)
	var projectile_speed_emerald_cost = get_tower_upgrade_emerald_cost("SPEED", projectile_speed_level)
	
	# Verificar se tem esmeraldas suficientes
	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}
	
	var can_dmg: bool = hero["coins"] >= dmg_cost
	var can_hold: bool = hero["coins"] >= hold_cost
	var can_spawn_rate: bool = hero["coins"] >= spawn_rate_cost and b.soldier_spawn_rate > GameConstants.BARRACKS_MIN_SPAWN_RATE
	var can_projectile_speed: bool = hero["coins"] >= projectile_speed_cost
	var can_dmg_emerald: bool = currency_info.emeralds >= dmg_emerald_cost
	var can_hold_emerald: bool = currency_info.emeralds >= hold_emerald_cost
	var can_spawn_rate_emerald: bool = currency_info.emeralds >= spawn_rate_emerald_cost and b.soldier_spawn_rate > GameConstants.BARRACKS_MIN_SPAWN_RATE
	var can_projectile_speed_emerald: bool = currency_info.emeralds >= projectile_speed_emerald_cost
	
	# Atualizar textos dos itens do menu
	barracks_menu.set_item_text(0, "Dano +0.2 (💰 %d moedas)" % dmg_cost)
	barracks_menu.set_item_text(1, "Dano +0.2 (🟢 %d esmeraldas)" % dmg_emerald_cost)
	barracks_menu.set_item_text(3, "Tempo Hold +%.1fs (💰 %d moedas)" % [GameConstants.BARRACKS_HOLD_TIME_INCREASE, hold_cost])
	barracks_menu.set_item_text(4, "Tempo Hold +%.1fs (🟢 %d esmeraldas)" % [GameConstants.BARRACKS_HOLD_TIME_INCREASE, hold_emerald_cost])
	barracks_menu.set_item_text(6, "Spawn Rate -0.5s (💰 %d moedas) [%.1fs]" % [spawn_rate_cost, b.soldier_spawn_rate])
	barracks_menu.set_item_text(7, "Spawn Rate -0.5s (🟢 %d esmeraldas) [%.1fs]" % [spawn_rate_emerald_cost, b.soldier_spawn_rate])
	barracks_menu.set_item_text(9, "Velocidade Projétil +20 (💰 %d moedas) [%.0f]" % [projectile_speed_cost, b.projectile_speed])
	barracks_menu.set_item_text(10, "Velocidade Projétil +20 (🟢 %d esmeraldas) [%.0f]" % [projectile_speed_emerald_cost, b.projectile_speed])
	barracks_menu.set_item_disabled(0, not can_dmg)
	barracks_menu.set_item_disabled(1, not can_dmg_emerald)
	barracks_menu.set_item_disabled(3, not can_hold)
	barracks_menu.set_item_disabled(4, not can_hold_emerald)
	barracks_menu.set_item_disabled(6, not can_spawn_rate)
	barracks_menu.set_item_disabled(7, not can_spawn_rate_emerald)
	barracks_menu.set_item_disabled(9, not can_projectile_speed)
	barracks_menu.set_item_disabled(10, not can_projectile_speed_emerald)
	barracks_menu.position = screen_pos
	barracks_menu.popup()

func _on_barracks_menu_pressed(id: int) -> void:
	if barracks_selected_index < 0 or barracks_selected_index >= barracks.size():
		return
	var b = barracks[barracks_selected_index]
	var dmg_level = b.levels.get("DMG", 0)
	var hold_level = b.levels.get("HOLD", 0)
	var spawn_rate_level = b.levels.get("SPAWN_RATE", 0)
	var projectile_speed_level = b.levels.get("PROJECTILE_SPEED", 0)
	
	# Verificar esmeraldas disponíveis
	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}
	
	match id:
		1:  # Dano com moedas
			var cost = get_upgrade_cost(GameConstants.BARRACKS_DMG_COST, dmg_level)
			if hero["coins"] >= cost:
				b.damage += GameConstants.BARRACKS_SOLDIER_DAMAGE_INCREASE
				b.levels["DMG"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		10:  # Dano com esmeraldas
			var emerald_cost = get_tower_upgrade_emerald_cost("DMG", dmg_level)
			if currency_info.emeralds >= emerald_cost:
				special_currency_manager.spend_emeralds(emerald_cost)
				b.damage += GameConstants.BARRACKS_SOLDIER_DAMAGE_INCREASE
				b.levels["DMG"] += 1
				_update_special_currency_labels()
				# Atualizar progresso de quests
				if quest_manager:
					quest_manager.update_quest_progress(GameConstants.QuestType.UPGRADE_TOWERS, 1)
		2:  # Tempo Hold com moedas
			var cost = get_upgrade_cost(GameConstants.BARRACKS_HOLD_COST, hold_level)
			if hero["coins"] >= cost:
				b.hold_time += GameConstants.BARRACKS_HOLD_TIME_INCREASE
				b.levels["HOLD"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		11:  # Tempo Hold com esmeraldas
			var emerald_cost = get_tower_upgrade_emerald_cost("HOLD", hold_level)
			if currency_info.emeralds >= emerald_cost:
				special_currency_manager.spend_emeralds(emerald_cost)
				b.hold_time += GameConstants.BARRACKS_HOLD_TIME_INCREASE
				b.levels["HOLD"] += 1
				_update_special_currency_labels()
		3:  # Spawn Rate com moedas
			var cost = get_upgrade_cost(GameConstants.BARRACKS_SPAWN_RATE_COST, spawn_rate_level)
			if hero["coins"] >= cost and b.soldier_spawn_rate > GameConstants.BARRACKS_MIN_SPAWN_RATE:
				b.soldier_spawn_rate = max(GameConstants.BARRACKS_MIN_SPAWN_RATE, b.soldier_spawn_rate - GameConstants.BARRACKS_SPAWN_RATE_REDUCTION)
				b.levels["SPAWN_RATE"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		12:  # Spawn Rate com esmeraldas
			var emerald_cost = get_tower_upgrade_emerald_cost("RATE", spawn_rate_level)
			if currency_info.emeralds >= emerald_cost and b.soldier_spawn_rate > GameConstants.BARRACKS_MIN_SPAWN_RATE:
				special_currency_manager.spend_emeralds(emerald_cost)
				b.soldier_spawn_rate = max(GameConstants.BARRACKS_MIN_SPAWN_RATE, b.soldier_spawn_rate - GameConstants.BARRACKS_SPAWN_RATE_REDUCTION)
				b.levels["SPAWN_RATE"] += 1
				_update_special_currency_labels()
		4:  # Velocidade Projétil com moedas
			var cost = get_upgrade_cost(GameConstants.BARRACKS_PROJECTILE_SPEED_COST, projectile_speed_level)
			if hero["coins"] >= cost:
				b.projectile_speed += GameConstants.BARRACKS_PROJECTILE_SPEED_INCREASE
				b.levels["PROJECTILE_SPEED"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		13:  # Velocidade Projétil com esmeraldas
			var emerald_cost = get_tower_upgrade_emerald_cost("SPEED", projectile_speed_level)
			if currency_info.emeralds >= emerald_cost:
				special_currency_manager.spend_emeralds(emerald_cost)
				b.projectile_speed += GameConstants.BARRACKS_PROJECTILE_SPEED_INCREASE
				b.levels["PROJECTILE_SPEED"] += 1
				_update_special_currency_labels()
	barracks[barracks_selected_index] = b
	
	# Guardar a posição do menu antes que ele feche para reabri-lo
	var saved_menu_pos = barracks_menu.position if barracks_menu else Vector2.ZERO
	
	# Reabrir o menu imediatamente após o upgrade com valores atualizados
	keep_barracks_menu_open = true
	_reopen_barracks_menu_immediately(saved_menu_pos)

func _reopen_barracks_menu_immediately(menu_pos: Vector2) -> void:
	"""Reabre o menu de quartel na mesma posição após um upgrade"""
	if not keep_barracks_menu_open:
		return
	if barracks_selected_index < 0 or barracks_selected_index >= barracks.size():
		keep_barracks_menu_open = false
		return
	if choosing_upgrade or game_over:
		keep_barracks_menu_open = false
		return
	
	# Usar call_deferred para garantir que o menu tenha fechado primeiro
	call_deferred("_actually_reopen_barracks_menu", menu_pos)

func _actually_reopen_barracks_menu(menu_pos: Vector2) -> void:
	"""Reabre efetivamente o menu quartel após o fechamento"""
	if not keep_barracks_menu_open:
		return
	if barracks_selected_index < 0 or barracks_selected_index >= barracks.size():
		keep_barracks_menu_open = false
		return
	if choosing_upgrade or game_over:
		keep_barracks_menu_open = false
		return
	
	# Reabrir o menu na mesma posição
	_open_barracks_menu(barracks_selected_index, menu_pos)
	keep_barracks_menu_open = false

func _open_sniper_menu(idx: int, screen_pos: Vector2) -> void:
	if sniper_menu == null:
		return
	sniper_selected_index = idx
	var s = sniper_towers[idx]
	_show_range_indicator(s.pos, s.range, Color(1.0, 0.4, 0.4, 0.65))
	
	# Calcular custos progressivos
	var dmg_level = s.levels.get("DMG", 0)
	var rate_level = s.levels.get("RATE", 0)
	var dmg_cost = get_upgrade_cost(GameConstants.SNIPER_DMG_COST, dmg_level)
	var rate_cost = get_upgrade_cost(GameConstants.SNIPER_RATE_COST, rate_level)
	
	# Custos em esmeraldas (escalados)
	var dmg_emerald_cost = get_tower_upgrade_emerald_cost("DMG", dmg_level)
	var rate_emerald_cost = get_tower_upgrade_emerald_cost("RATE", rate_level)
	
	# Verificar se tem esmeraldas suficientes
	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}
	
	var can_dmg: bool = hero["coins"] >= dmg_cost
	var can_rate: bool = hero["coins"] >= rate_cost and s.fire_rate > GameConstants.SNIPER_MIN_FIRE_RATE
	var can_dmg_emerald: bool = currency_info.emeralds >= dmg_emerald_cost
	var can_rate_emerald: bool = currency_info.emeralds >= rate_emerald_cost and s.fire_rate > GameConstants.SNIPER_MIN_FIRE_RATE
	
	sniper_menu.set_item_text(0, "Dano +2 (💰 %d moedas)" % dmg_cost)
	sniper_menu.set_item_text(1, "Dano +2 (🟢 %d esmeraldas)" % dmg_emerald_cost)
	sniper_menu.set_item_text(3, "Taxa de Tiro + (💰 %d moedas) [%.1fs]" % [rate_cost, s.fire_rate])
	sniper_menu.set_item_text(4, "Taxa de Tiro + (🟢 %d esmeraldas) [%.1fs]" % [rate_emerald_cost, s.fire_rate])
	var target_mode = s.get("target_mode", 0)
	sniper_menu.set_item_text(6, "Alvo: Boss" + (" ✓" if target_mode == 0 else ""))
	sniper_menu.set_item_text(7, "Alvo: Mais Próximo ao Centro" + (" ✓" if target_mode == 1 else ""))
	sniper_menu.set_item_disabled(0, not can_dmg)
	sniper_menu.set_item_disabled(1, not can_dmg_emerald)
	sniper_menu.set_item_disabled(3, not can_rate)
	sniper_menu.set_item_disabled(4, not can_rate_emerald)
	sniper_menu.position = screen_pos
	sniper_menu.popup()

func _on_sniper_menu_pressed(id: int) -> void:
	if sniper_selected_index < 0 or sniper_selected_index >= sniper_towers.size():
		return
	var s = sniper_towers[sniper_selected_index]
	var dmg_level = s.levels.get("DMG", 0)
	var rate_level = s.levels.get("RATE", 0)
	
	# Verificar esmeraldas disponíveis
	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}
	
	match id:
		1:  # Dano com moedas
			var cost = get_upgrade_cost(GameConstants.SNIPER_DMG_COST, dmg_level)
			if hero["coins"] >= cost:
				s.damage += 2.0
				s.levels["DMG"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		10:  # Dano com esmeraldas
			var emerald_cost = get_tower_upgrade_emerald_cost("DMG", dmg_level)
			if currency_info.emeralds >= emerald_cost:
				special_currency_manager.spend_emeralds(emerald_cost)
				s.damage += 2.0
				s.levels["DMG"] += 1
				_update_special_currency_labels()
		2:  # Taxa de Tiro com moedas
			var cost = get_upgrade_cost(GameConstants.SNIPER_RATE_COST, rate_level)
			if hero["coins"] >= cost and s.fire_rate > GameConstants.SNIPER_MIN_FIRE_RATE:
				s.fire_rate = max(GameConstants.SNIPER_MIN_FIRE_RATE, s.fire_rate - GameConstants.SNIPER_FIRE_RATE_REDUCTION)
				s.levels["RATE"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		11:  # Taxa de Tiro com esmeraldas
			var emerald_cost = get_tower_upgrade_emerald_cost("RATE", rate_level)
			if currency_info.emeralds >= emerald_cost and s.fire_rate > GameConstants.SNIPER_MIN_FIRE_RATE:
				special_currency_manager.spend_emeralds(emerald_cost)
				s.fire_rate = max(GameConstants.SNIPER_MIN_FIRE_RATE, s.fire_rate - GameConstants.SNIPER_FIRE_RATE_REDUCTION)
				s.levels["RATE"] += 1
				_update_special_currency_labels()
		3:  # Alvo: Boss
			s["target_mode"] = 0
		4:  # Alvo: Mais Próximo ao Centro
			s["target_mode"] = 1
	sniper_towers[sniper_selected_index] = s
	
	# Guardar a posição do menu antes que ele feche para reabri-lo
	var saved_menu_pos = sniper_menu.position if sniper_menu else Vector2.ZERO
	
	# Reabrir o menu imediatamente após o upgrade com valores atualizados
	keep_sniper_menu_open = true
	_reopen_sniper_menu_immediately(saved_menu_pos)

func _reopen_sniper_menu_immediately(menu_pos: Vector2) -> void:
	"""Reabre o menu de sniper na mesma posição após um upgrade"""
	if not keep_sniper_menu_open:
		return
	if sniper_selected_index < 0 or sniper_selected_index >= sniper_towers.size():
		keep_sniper_menu_open = false
		return
	if choosing_upgrade or game_over:
		keep_sniper_menu_open = false
		return
	
	# Usar call_deferred para garantir que o menu tenha fechado primeiro
	call_deferred("_actually_reopen_sniper_menu", menu_pos)

func _actually_reopen_sniper_menu(menu_pos: Vector2) -> void:
	"""Reabre efetivamente o menu sniper após o fechamento"""
	if not keep_sniper_menu_open:
		return
	if sniper_selected_index < 0 or sniper_selected_index >= sniper_towers.size():
		keep_sniper_menu_open = false
		return
	if choosing_upgrade or game_over:
		keep_sniper_menu_open = false
		return
	
	# Reabrir o menu na mesma posição
	_open_sniper_menu(sniper_selected_index, menu_pos)
	keep_sniper_menu_open = false

func _open_aoe_menu(idx: int, screen_pos: Vector2) -> void:
	if aoe_menu == null:
		return
	aoe_selected_index = idx
	var a = aoe_towers[idx]
	_show_range_indicator(a.pos, a.range, Color(1.0, 0.8, 0.3, 0.65))
	
	# Calcular custos progressivos
	var dmg_level = a.levels.get("DMG", 0)
	var rate_level = a.levels.get("RATE", 0)
	var area_level = a.levels.get("AREA", 0)
	var dmg_cost = get_upgrade_cost(GameConstants.AOE_DMG_COST, dmg_level)
	var rate_cost = get_upgrade_cost(GameConstants.AOE_RATE_COST, rate_level)
	var area_cost = get_upgrade_cost(GameConstants.AOE_AREA_COST, area_level)
	
	# Custos em esmeraldas (escalados)
	var dmg_emerald_cost = get_tower_upgrade_emerald_cost("DMG", dmg_level)
	var rate_emerald_cost = get_tower_upgrade_emerald_cost("RATE", rate_level)
	var area_emerald_cost = get_tower_upgrade_emerald_cost("AREA", area_level)
	
	# Verificar se tem esmeraldas suficientes
	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}
	
	var can_dmg: bool = hero["coins"] >= dmg_cost
	var can_rate: bool = hero["coins"] >= rate_cost and a.fire_rate > GameConstants.AOE_MIN_FIRE_RATE
	var can_area: bool = hero["coins"] >= area_cost and a.aoe_radius < GameConstants.AOE_MAX_RADIUS
	var can_dmg_emerald: bool = currency_info.emeralds >= dmg_emerald_cost
	var can_rate_emerald: bool = currency_info.emeralds >= rate_emerald_cost and a.fire_rate > GameConstants.AOE_MIN_FIRE_RATE
	var can_area_emerald: bool = currency_info.emeralds >= area_emerald_cost and a.aoe_radius < GameConstants.AOE_MAX_RADIUS
	
	aoe_menu.set_item_text(0, "Dano +1 (💰 %d moedas)" % dmg_cost)
	aoe_menu.set_item_text(1, "Dano +1 (🟢 %d esmeraldas)" % dmg_emerald_cost)
	aoe_menu.set_item_text(3, "Taxa de Tiro + (💰 %d moedas) [%.1fs]" % [rate_cost, a.fire_rate])
	aoe_menu.set_item_text(4, "Taxa de Tiro + (🟢 %d esmeraldas) [%.1fs]" % [rate_emerald_cost, a.fire_rate])
	aoe_menu.set_item_text(6, "Área +20 (💰 %d moedas) [%.0f]" % [area_cost, a.aoe_radius])
	aoe_menu.set_item_text(7, "Área +20 (🟢 %d esmeraldas) [%.0f]" % [area_emerald_cost, a.aoe_radius])
	aoe_menu.set_item_disabled(0, not can_dmg)
	aoe_menu.set_item_disabled(1, not can_dmg_emerald)
	aoe_menu.set_item_disabled(3, not can_rate)
	aoe_menu.set_item_disabled(4, not can_rate_emerald)
	aoe_menu.set_item_disabled(6, not can_area)
	aoe_menu.set_item_disabled(7, not can_area_emerald)
	aoe_menu.position = screen_pos
	aoe_menu.popup()

func _on_aoe_menu_pressed(id: int) -> void:
	if aoe_selected_index < 0 or aoe_selected_index >= aoe_towers.size():
		return
	var a = aoe_towers[aoe_selected_index]
	var dmg_level = a.levels.get("DMG", 0)
	var rate_level = a.levels.get("RATE", 0)
	var area_level = a.levels.get("AREA", 0)
	
	# Verificar esmeraldas disponíveis
	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}
	
	match id:
		1:  # Dano com moedas
			var cost = get_upgrade_cost(GameConstants.AOE_DMG_COST, dmg_level)
			if hero["coins"] >= cost:
				a.damage += 1.0
				a.levels["DMG"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		10:  # Dano com esmeraldas
			var emerald_cost = get_tower_upgrade_emerald_cost("DMG", dmg_level)
			if currency_info.emeralds >= emerald_cost:
				special_currency_manager.spend_emeralds(emerald_cost)
				a.damage += 1.0
				a.levels["DMG"] += 1
				_update_special_currency_labels()
		2:  # Taxa de Tiro com moedas
			var cost = get_upgrade_cost(GameConstants.AOE_RATE_COST, rate_level)
			if hero["coins"] >= cost and a.fire_rate > GameConstants.AOE_MIN_FIRE_RATE:
				a.fire_rate = max(GameConstants.AOE_MIN_FIRE_RATE, a.fire_rate - GameConstants.AOE_FIRE_RATE_REDUCTION)
				a.levels["RATE"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		11:  # Taxa de Tiro com esmeraldas
			var emerald_cost = get_tower_upgrade_emerald_cost("RATE", rate_level)
			if currency_info.emeralds >= emerald_cost and a.fire_rate > GameConstants.AOE_MIN_FIRE_RATE:
				special_currency_manager.spend_emeralds(emerald_cost)
				a.fire_rate = max(GameConstants.AOE_MIN_FIRE_RATE, a.fire_rate - GameConstants.AOE_FIRE_RATE_REDUCTION)
				a.levels["RATE"] += 1
				_update_special_currency_labels()
		3:  # Área com moedas
			var cost = get_upgrade_cost(GameConstants.AOE_AREA_COST, area_level)
			if hero["coins"] >= cost and a.aoe_radius < GameConstants.AOE_MAX_RADIUS:
				a.aoe_radius = min(GameConstants.AOE_MAX_RADIUS, a.aoe_radius + 20.0)
				a.levels["AREA"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		12:  # Área com esmeraldas
			var emerald_cost = get_tower_upgrade_emerald_cost("AREA", area_level)
			if currency_info.emeralds >= emerald_cost and a.aoe_radius < GameConstants.AOE_MAX_RADIUS:
				special_currency_manager.spend_emeralds(emerald_cost)
				a.aoe_radius = min(GameConstants.AOE_MAX_RADIUS, a.aoe_radius + 20.0)
				a.levels["AREA"] += 1
				_update_special_currency_labels()
	aoe_towers[aoe_selected_index] = a
	
	# Guardar a posição do menu antes que ele feche para reabri-lo
	var saved_menu_pos = aoe_menu.position if aoe_menu else Vector2.ZERO
	
	# Reabrir o menu imediatamente após o upgrade com valores atualizados
	keep_aoe_menu_open = true
	_reopen_aoe_menu_immediately(saved_menu_pos)

func _reopen_aoe_menu_immediately(menu_pos: Vector2) -> void:
	"""Reabre o menu de AOE na mesma posição após um upgrade"""
	if not keep_aoe_menu_open:
		return
	if aoe_selected_index < 0 or aoe_selected_index >= aoe_towers.size():
		keep_aoe_menu_open = false
		return
	if choosing_upgrade or game_over:
		keep_aoe_menu_open = false
		return
	
	# Usar call_deferred para garantir que o menu tenha fechado primeiro
	call_deferred("_actually_reopen_aoe_menu", menu_pos)

func _actually_reopen_aoe_menu(menu_pos: Vector2) -> void:
	"""Reabre efetivamente o menu AOE após o fechamento"""
	if not keep_aoe_menu_open:
		return
	if aoe_selected_index < 0 or aoe_selected_index >= aoe_towers.size():
		keep_aoe_menu_open = false
		return
	if choosing_upgrade or game_over:
		keep_aoe_menu_open = false
		return
	
	# Reabrir o menu na mesma posição
	_open_aoe_menu(aoe_selected_index, menu_pos)
	keep_aoe_menu_open = false

func _open_shock_menu(idx: int, screen_pos: Vector2) -> void:
	if shock_menu == null:
		return
	shock_selected_index = idx
	var s = shock_towers[idx]
	_show_range_indicator(s.pos, s.range, Color(0.9, 0.5, 1.0, 0.65))
	
	# Calcular custos progressivos
	var dmg_level = s.levels.get("DMG", 0)
	var rate_level = s.levels.get("RATE", 0)
	var chain_level = s.levels.get("CHAIN", 0)
	var dmg_cost = get_upgrade_cost(GameConstants.SHOCK_DMG_COST, dmg_level)
	var rate_cost = get_upgrade_cost(GameConstants.SHOCK_RATE_COST, rate_level)
	# Aplicar multiplicador especial para upgrade de chain (mais caro)
	var base_chain_cost = GameConstants.SHOCK_CHAIN_COST
	var chain_cost = int(base_chain_cost * pow(GameConstants.SHOCK_CHAIN_COST_MULTIPLIER, chain_level))
	
	# Custos em esmeraldas (escalados)
	var dmg_emerald_cost = get_tower_upgrade_emerald_cost("DMG", dmg_level)
	var rate_emerald_cost = get_tower_upgrade_emerald_cost("RATE", rate_level)
	var chain_emerald_cost = get_tower_upgrade_emerald_cost("CHAIN", chain_level)
	
	# Verificar se tem esmeraldas suficientes
	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}
	
	var can_dmg: bool = hero["coins"] >= dmg_cost
	var can_rate: bool = hero["coins"] >= rate_cost and s.fire_rate > GameConstants.SHOCK_MIN_FIRE_RATE
	var can_chain: bool = hero["coins"] >= chain_cost and s.chain_count < GameConstants.SHOCK_MAX_CHAIN_COUNT
	var can_dmg_emerald: bool = currency_info.emeralds >= dmg_emerald_cost
	var can_rate_emerald: bool = currency_info.emeralds >= rate_emerald_cost and s.fire_rate > GameConstants.SHOCK_MIN_FIRE_RATE
	var can_chain_emerald: bool = currency_info.emeralds >= chain_emerald_cost and s.chain_count < GameConstants.SHOCK_MAX_CHAIN_COUNT
	
	shock_menu.set_item_text(0, "Dano +0.5 (💰 %d moedas)" % dmg_cost)
	shock_menu.set_item_text(1, "Dano +0.5 (🟢 %d esmeraldas)" % dmg_emerald_cost)
	shock_menu.set_item_text(3, "Taxa de Tiro + (💰 %d moedas) [%.1fs]" % [rate_cost, s.fire_rate])
	shock_menu.set_item_text(4, "Taxa de Tiro + (🟢 %d esmeraldas) [%.1fs]" % [rate_emerald_cost, s.fire_rate])
	shock_menu.set_item_text(6, "Corrente +1 (💰 %d moedas) [%d]" % [chain_cost, s.chain_count])
	shock_menu.set_item_text(7, "Corrente +1 (🟢 %d esmeraldas) [%d]" % [chain_emerald_cost, s.chain_count])
	shock_menu.set_item_disabled(0, not can_dmg)
	shock_menu.set_item_disabled(1, not can_dmg_emerald)
	shock_menu.set_item_disabled(3, not can_rate)
	shock_menu.set_item_disabled(4, not can_rate_emerald)
	shock_menu.set_item_disabled(6, not can_chain)
	shock_menu.set_item_disabled(7, not can_chain_emerald)
	shock_menu.position = screen_pos
	shock_menu.popup()

func _on_shock_menu_pressed(id: int) -> void:
	if shock_selected_index < 0 or shock_selected_index >= shock_towers.size():
		return
	var s = shock_towers[shock_selected_index]
	var dmg_level = s.levels.get("DMG", 0)
	var rate_level = s.levels.get("RATE", 0)
	var chain_level = s.levels.get("CHAIN", 0)
	
	# Verificar esmeraldas disponíveis
	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}
	
	match id:
		1:  # Dano com moedas
			var cost = get_upgrade_cost(GameConstants.SHOCK_DMG_COST, dmg_level)
			if hero["coins"] >= cost:
				s.damage += 0.5
				s.levels["DMG"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		10:  # Dano com esmeraldas
			var emerald_cost = get_tower_upgrade_emerald_cost("DMG", dmg_level)
			if currency_info.emeralds >= emerald_cost:
				special_currency_manager.spend_emeralds(emerald_cost)
				s.damage += 0.5
				s.levels["DMG"] += 1
				_update_special_currency_labels()
		2:  # Taxa de Tiro com moedas
			var cost = get_upgrade_cost(GameConstants.SHOCK_RATE_COST, rate_level)
			if hero["coins"] >= cost and s.fire_rate > GameConstants.SHOCK_MIN_FIRE_RATE:
				s.fire_rate = max(GameConstants.SHOCK_MIN_FIRE_RATE, s.fire_rate - GameConstants.SHOCK_FIRE_RATE_REDUCTION)
				s.levels["RATE"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		11:  # Taxa de Tiro com esmeraldas
			var emerald_cost = get_tower_upgrade_emerald_cost("RATE", rate_level)
			if currency_info.emeralds >= emerald_cost and s.fire_rate > GameConstants.SHOCK_MIN_FIRE_RATE:
				special_currency_manager.spend_emeralds(emerald_cost)
				s.fire_rate = max(GameConstants.SHOCK_MIN_FIRE_RATE, s.fire_rate - GameConstants.SHOCK_FIRE_RATE_REDUCTION)
				s.levels["RATE"] += 1
				_update_special_currency_labels()
		3:  # Corrente com moedas
			# Aplicar multiplicador especial para upgrade de chain (mais caro)
			var base_chain_cost = GameConstants.SHOCK_CHAIN_COST
			var cost = int(base_chain_cost * pow(GameConstants.SHOCK_CHAIN_COST_MULTIPLIER, chain_level))
			if hero["coins"] >= cost and s.chain_count < GameConstants.SHOCK_MAX_CHAIN_COUNT:
				s.chain_count = min(GameConstants.SHOCK_MAX_CHAIN_COUNT, s.chain_count + 1)
				s.levels["CHAIN"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		12:  # Corrente com esmeraldas
			var emerald_cost = get_tower_upgrade_emerald_cost("CHAIN", chain_level)
			if currency_info.emeralds >= emerald_cost and s.chain_count < GameConstants.SHOCK_MAX_CHAIN_COUNT:
				special_currency_manager.spend_emeralds(emerald_cost)
				s.chain_count = min(GameConstants.SHOCK_MAX_CHAIN_COUNT, s.chain_count + 1)
				s.levels["CHAIN"] += 1
				_update_special_currency_labels()
	shock_towers[shock_selected_index] = s
	
	# Guardar a posição do menu antes que ele feche para reabri-lo
	var saved_menu_pos = shock_menu.position if shock_menu else Vector2.ZERO
	
	# Reabrir o menu imediatamente após o upgrade com valores atualizados
	keep_shock_menu_open = true
	_reopen_shock_menu_immediately(saved_menu_pos)

func _reopen_shock_menu_immediately(menu_pos: Vector2) -> void:
	"""Reabre o menu de shock na mesma posição após um upgrade"""
	if not keep_shock_menu_open:
		return
	if shock_selected_index < 0 or shock_selected_index >= shock_towers.size():
		keep_shock_menu_open = false
		return
	if choosing_upgrade or game_over:
		keep_shock_menu_open = false
		return
	
	# Usar call_deferred para garantir que o menu tenha fechado primeiro
	call_deferred("_actually_reopen_shock_menu", menu_pos)

func _actually_reopen_shock_menu(menu_pos: Vector2) -> void:
	"""Reabre efetivamente o menu shock após o fechamento"""
	if not keep_shock_menu_open:
		return
	if shock_selected_index < 0 or shock_selected_index >= shock_towers.size():
		keep_shock_menu_open = false
		return
	if choosing_upgrade or game_over:
		keep_shock_menu_open = false
		return
	
	# Reabrir o menu na mesma posição
	_open_shock_menu(shock_selected_index, menu_pos)
	keep_shock_menu_open = false

func _open_slow_menu(idx: int, screen_pos: Vector2) -> void:
	if slow_menu == null:
		return
	slow_selected_index = idx
	var s = slow_towers[idx]
	_show_range_indicator(s.pos, s.range, Color(0.4, 1.0, 0.8, 0.65))
	
	# Calcular custos progressivos (sem RATE e sem DURATION - removidos)
	var range_level = s.levels.get("RANGE", 0)
	var amount_level = s.levels.get("AMOUNT", 0)
	var range_cost = get_upgrade_cost(GameConstants.SLOW_RANGE_COST, range_level)
	var amount_cost = get_upgrade_cost(GameConstants.SLOW_AMOUNT_COST, amount_level)
	
	# Custos em esmeraldas (escalados)
	var range_emerald_cost = get_tower_upgrade_emerald_cost("RANGE", range_level)
	var amount_emerald_cost = get_tower_upgrade_emerald_cost("AMOUNT", amount_level)
	
	# Verificar se tem esmeraldas suficientes
	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}
	
	var can_range: bool = hero["coins"] >= range_cost and s.range < 250.0  # Máximo 250
	var can_amount: bool = hero["coins"] >= amount_cost and s.slow_amount < 0.5  # Máximo 50%
	var can_range_emerald: bool = currency_info.emeralds >= range_emerald_cost and s.range < 250.0
	var can_amount_emerald: bool = currency_info.emeralds >= amount_emerald_cost and s.slow_amount < 0.5
	
	# Atualizar itens (alcance e slow com opções de moedas e esmeraldas)
	slow_menu.set_item_text(0, "Alcance +30 (💰 %d moedas) [%.0f/222250]" % [range_cost, s.range])
	slow_menu.set_item_text(1, "Alcance +30 (🟢 %d esmeraldas) [%.0f/250]" % [range_emerald_cost, s.range])
	slow_menu.set_item_text(3, "Slow x1.05 (💰 %d moedas) [%.0f%%/50%%]" % [amount_cost, s.slow_amount * 100])
	slow_menu.set_item_text(4, "Slow x1.05 (🟢 %d esmeraldas) [%.0f%%/50%%]" % [amount_emerald_cost, s.slow_amount * 100])
	slow_menu.set_item_disabled(0, not can_range)
	slow_menu.set_item_disabled(1, not can_range_emerald)
	slow_menu.set_item_disabled(3, not can_amount)
	slow_menu.set_item_disabled(4, not can_amount_emerald)
	slow_menu.position = screen_pos
	slow_menu.popup()

func _on_slow_menu_pressed(id: int) -> void:
	if slow_selected_index < 0 or slow_selected_index >= slow_towers.size():
		return
	var s = slow_towers[slow_selected_index]
	var range_level = s.levels.get("RANGE", 0)
	var amount_level = s.levels.get("AMOUNT", 0)
	# RATE e DURATION removidos - não fazem mais sentido
	
	# Verificar esmeraldas disponíveis
	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}
	
	match id:
		1:  # Alcance com moedas - aumenta apenas o range (máximo 250)
			var cost = get_upgrade_cost(GameConstants.SLOW_RANGE_COST, range_level)
			if hero["coins"] >= cost and s.range < 250.0:
				s.range = min(250.0, s.range + 30.0)  # Aumenta o alcance em 30, máximo 250
				s.levels["RANGE"] = s.levels.get("RANGE", 0) + 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		10:  # Alcance com esmeraldas
			var emerald_cost = get_tower_upgrade_emerald_cost("RANGE", range_level)
			if currency_info.emeralds >= emerald_cost and s.range < 250.0:
				special_currency_manager.spend_emeralds(emerald_cost)
				s.range = min(250.0, s.range + 30.0)
				s.levels["RANGE"] = s.levels.get("RANGE", 0) + 1
				_update_special_currency_labels()
		2:  # Slow Amount com moedas - multiplicativo (x1.05 por upgrade, máximo 50%)
			var cost = get_upgrade_cost(GameConstants.SLOW_AMOUNT_COST, amount_level)
			if hero["coins"] >= cost and s.slow_amount < 0.5:  # Máximo 50%
				# Multiplicativo: multiplica por 1.05 (5% mais lento por upgrade)
				s.slow_amount = min(0.5, s.slow_amount * 1.05)
				s.levels["AMOUNT"] = s.levels.get("AMOUNT", 0) + 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		11:  # Slow Amount com esmeraldas
			var emerald_cost = get_tower_upgrade_emerald_cost("AMOUNT", amount_level)
			if currency_info.emeralds >= emerald_cost and s.slow_amount < 0.5:
				special_currency_manager.spend_emeralds(emerald_cost)
				s.slow_amount = min(0.5, s.slow_amount * 1.05)
				s.levels["AMOUNT"] = s.levels.get("AMOUNT", 0) + 1
				_update_special_currency_labels()
		# Removido upgrade de Duração (id 3) - funciona enquanto está dentro da área
		# Removido upgrade de Taxa de Aplicação (id 4)
	slow_towers[slow_selected_index] = s
	
	# Guardar a posição do menu antes que ele feche para reabri-lo
	var saved_menu_pos = slow_menu.position if slow_menu else Vector2.ZERO
	
	# Reabrir o menu imediatamente após o upgrade com valores atualizados
	keep_slow_menu_open = true
	_reopen_slow_menu_immediately(saved_menu_pos)

func _reopen_slow_menu_immediately(menu_pos: Vector2) -> void:
	"""Reabre o menu de slow na mesma posição após um upgrade"""
	if not keep_slow_menu_open:
		return
	if slow_selected_index < 0 or slow_selected_index >= slow_towers.size():
		keep_slow_menu_open = false
		return
	if choosing_upgrade or game_over:
		keep_slow_menu_open = false
		return
	
	# Usar call_deferred para garantir que o menu tenha fechado primeiro
	call_deferred("_actually_reopen_slow_menu", menu_pos)

func _actually_reopen_slow_menu(menu_pos: Vector2) -> void:
	"""Reabre efetivamente o menu slow após o fechamento"""
	if not keep_slow_menu_open:
		return
	if slow_selected_index < 0 or slow_selected_index >= slow_towers.size():
		keep_slow_menu_open = false
		return
	if choosing_upgrade or game_over:
		keep_slow_menu_open = false
		return
	
	# Reabrir o menu na mesma posição
	_open_slow_menu(slow_selected_index, menu_pos)
	keep_slow_menu_open = false

func _open_boost_menu(idx: int, screen_pos: Vector2) -> void:
	if boost_menu == null:
		return
	boost_selected_index = idx
	var b = boost_towers[idx]
	# Boost tower tem range global, não precisa mostrar range indicator
	# _show_range_indicator(b.pos, b.range, Color(0.6, 0.9, 0.4, 0.65))
	
	# Calcular custos progressivos (sem range - range é global)
	var dmg_level = b.levels.get("DMG", 0)
	var rate_level = b.levels.get("RATE", 0)
	# Custo de dano com multiplicador maior (1.25x por nível ao invés de 1.15x padrão)
	var dmg_cost = int(GameConstants.BOOST_DMG_COST * pow(1.25, dmg_level))
	var rate_cost = get_upgrade_cost(GameConstants.BOOST_RATE_COST, rate_level)
	
	# Custos em esmeraldas (escalados)
	var dmg_emerald_cost = get_tower_upgrade_emerald_cost("DMG", dmg_level)
	var rate_emerald_cost = get_tower_upgrade_emerald_cost("RATE", rate_level)
	
	# Verificar se tem esmeraldas suficientes
	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}
	
	var can_dmg: bool = hero["coins"] >= dmg_cost and b.damage_boost < 1.0  # Máximo 100%
	var can_rate: bool = hero["coins"] >= rate_cost and b.rate_boost < 1.0  # Máximo 100%
	var can_dmg_emerald: bool = currency_info.emeralds >= dmg_emerald_cost and b.damage_boost < 1.0
	var can_rate_emerald: bool = currency_info.emeralds >= rate_emerald_cost and b.rate_boost < 1.0
	
	# Apenas dano e cadência (sem alcance)
	boost_menu.set_item_text(0, "Boost Dano +5%% (💰 %d moedas) [%.0f%%]" % [dmg_cost, b.damage_boost * 100])
	boost_menu.set_item_text(1, "Boost Dano +5%% (🟢 %d esmeraldas) [%.0f%%]" % [dmg_emerald_cost, b.damage_boost * 100])
	boost_menu.set_item_text(3, "Boost Cadência +5%% (💰 %d moedas) [%.0f%%]" % [rate_cost, b.rate_boost * 100])
	boost_menu.set_item_text(4, "Boost Cadência +5%% (🟢 %d esmeraldas) [%.0f%%]" % [rate_emerald_cost, b.rate_boost * 100])
	boost_menu.set_item_disabled(0, not can_dmg)
	boost_menu.set_item_disabled(1, not can_dmg_emerald)
	boost_menu.set_item_disabled(3, not can_rate)
	boost_menu.set_item_disabled(4, not can_rate_emerald)
	boost_menu.position = screen_pos
	boost_menu.popup()

func _on_boost_menu_pressed(id: int) -> void:
	if boost_selected_index < 0 or boost_selected_index >= boost_towers.size():
		return
	var b = boost_towers[boost_selected_index]
	var dmg_level = b.levels.get("DMG", 0)
	var rate_level = b.levels.get("RATE", 0)
	
	# Verificar esmeraldas disponíveis
	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}
	
	match id:
		1:  # Boost Dano com moedas
			# Custo com multiplicador maior (1.25x por nível)
			var cost = int(GameConstants.BOOST_DMG_COST * pow(1.25, dmg_level))
			if hero["coins"] >= cost and b.damage_boost < 1.0:  # Máximo 100%
				b.damage_boost = min(1.0, b.damage_boost + 0.05)  # Limite máximo de 100%
				b.levels["DMG"] = b.levels.get("DMG", 0) + 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		10:  # Boost Dano com esmeraldas
			var emerald_cost = get_tower_upgrade_emerald_cost("DMG", dmg_level)
			if currency_info.emeralds >= emerald_cost and b.damage_boost < 1.0:
				special_currency_manager.spend_emeralds(emerald_cost)
				b.damage_boost = min(1.0, b.damage_boost + 0.05)
				b.levels["DMG"] = b.levels.get("DMG", 0) + 1
				_update_special_currency_labels()
		2:  # Boost Cadência com moedas
			var cost = get_upgrade_cost(GameConstants.BOOST_RATE_COST, rate_level)
			if hero["coins"] >= cost and b.rate_boost < 1.0:  # Máximo 100%
				b.rate_boost = min(1.0, b.rate_boost + 0.05)  # Mantém +5%
				b.levels["RATE"] = b.levels.get("RATE", 0) + 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		11:  # Boost Cadência com esmeraldas
			var emerald_cost = get_tower_upgrade_emerald_cost("RATE", rate_level)
			if currency_info.emeralds >= emerald_cost and b.rate_boost < 1.0:
				special_currency_manager.spend_emeralds(emerald_cost)
				b.rate_boost = min(1.0, b.rate_boost + 0.05)
				b.levels["RATE"] = b.levels.get("RATE", 0) + 1
				_update_special_currency_labels()
	boost_towers[boost_selected_index] = b
	
	# Guardar a posição do menu antes que ele feche para reabri-lo
	var saved_menu_pos = boost_menu.position if boost_menu else Vector2.ZERO
	
	# Reabrir o menu imediatamente após o upgrade com valores atualizados
	keep_boost_menu_open = true
	_reopen_boost_menu_immediately(saved_menu_pos)

func _reopen_boost_menu_immediately(menu_pos: Vector2) -> void:
	"""Reabre o menu de boost na mesma posição após um upgrade"""
	if not keep_boost_menu_open:
		return
	if boost_selected_index < 0 or boost_selected_index >= boost_towers.size():
		keep_boost_menu_open = false
		return
	if choosing_upgrade or game_over:
		keep_boost_menu_open = false
		return
	
	# Usar call_deferred para garantir que o menu tenha fechado primeiro
	call_deferred("_actually_reopen_boost_menu", menu_pos)

func _actually_reopen_boost_menu(menu_pos: Vector2) -> void:
	"""Reabre efetivamente o menu boost após o fechamento"""
	if not keep_boost_menu_open:
		return
	if boost_selected_index < 0 or boost_selected_index >= boost_towers.size():
		keep_boost_menu_open = false
		return
	if choosing_upgrade or game_over:
		keep_boost_menu_open = false
		return
	
	# Reabrir o menu na mesma posição
	_open_boost_menu(boost_selected_index, menu_pos)
	keep_boost_menu_open = false

func _is_inside_base_point(p: Vector2) -> bool:
	return grid_manager.is_inside_base_point(p)

func _try_place_tower(pos: Vector2) -> void:
	# verificar moedas (com custo escalado por wave)
	var tower_cost = get_tower_cost(GameConstants.TOWER_COST)
	if hero["coins"] < tower_cost:
		placing_tower = false
		return
	
	# verificar limite
	if towers.size() >= GameConstants.MAX_TOWERS:
		placing_tower = false
		return
	
	if not _is_inside_base_point(pos):
		placing_tower = false
		return
	
	# converter para coordenadas do grid
	var grid_coord = grid_manager.world_to_base_grid(pos)
	
	# verificar se pode colocar torre 2x2
	if not grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, GameConstants.TOWER_SIZE_GRID, 1):
		placing_tower = false
		return
	
	# marcar área no grid
	grid_manager.set_grid_area(grid_coord.x, grid_coord.y, GameConstants.TOWER_SIZE_GRID, 1)
	pathfinder.invalidate_cache()  # invalidar cache quando grid muda
	
	# calcular posição central da torre
	var tower_world_pos = grid_manager.base_grid_to_world(grid_coord.x, grid_coord.y, GameConstants.TOWER_SIZE_GRID)
	
	# calcular direção baseada na posição relativa ao centro da base
	var bc = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
	var dir_vec = (tower_world_pos - bc).normalized()
	if dir_vec.length() < 0.1:
		dir_vec = Vector2(1, 0)  # padrão: direita
	
	var base_range = 260.0
	towers.append({
		"pos": tower_world_pos,
		"grid_x": grid_coord.x,
		"grid_y": grid_coord.y,
		"cooldown": 0.0,
		"fire_rate": 1.5,
		"range": base_range * global_tower_range_boost,
		"base_range": base_range,  # Guardar range base para recalcular quando boost mudar
		"dirs": [dir_vec],
		"damage": GameConstants.TOWER_BASE_DAMAGE,
		"levels": { "RANGE": 0, "RATE": 0, "DIRS": 0, "DMG": 0 }
	})
	hero["coins"] -= tower_cost
	_track_coin_spent(tower_cost)
	_track_tower_built("tower")
	placing_tower = false

# Blocos removidos - substituídos por Muralhas

func _try_place_barracks(pos: Vector2) -> void:
	# verificar moedas (com custo escalado por wave)
	var barracks_cost = get_tower_cost(GameConstants.BARRACKS_COST)
	if hero["coins"] < barracks_cost:
		placing_barracks = false
		return
	
	# verificar limite
	if barracks.size() >= GameConstants.MAX_BARRACKS:
		placing_barracks = false
		return
	
	if not _is_inside_base_point(pos):
		placing_barracks = false
		return
	
	# converter para coordenadas do grid
	var grid_coord = grid_manager.world_to_base_grid(pos)
	
	# verificar se pode colocar quartel 2x2
	if not grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, GameConstants.BARRACKS_SIZE_GRID, 3):
		placing_barracks = false
		return
	
	# marcar área no grid
	grid_manager.set_grid_area(grid_coord.x, grid_coord.y, GameConstants.BARRACKS_SIZE_GRID, 3)
	pathfinder.invalidate_cache()  # invalidar cache quando grid muda
	
	# calcular posição central do quartel
	var barracks_world_pos = grid_manager.base_grid_to_world(grid_coord.x, grid_coord.y, GameConstants.BARRACKS_SIZE_GRID)
	
	var initial_spawn_rate = GameConstants.BARRACKS_INITIAL_SPAWN_RATE
	barracks.append({
		"pos": barracks_world_pos,
		"grid_x": grid_coord.x,
		"grid_y": grid_coord.y,
		"soldier_spawn_cd": initial_spawn_rate,  # inicializar com o tempo de spawn para não spawnar imediatamente
		"soldier_spawn_rate": initial_spawn_rate,
		"soldiers": [],
		"hold_time": GameConstants.BARRACKS_INITIAL_HOLD_TIME,
		"damage": GameConstants.BARRACKS_INITIAL_SOLDIER_DAMAGE,
		"projectile_speed": GameConstants.BARRACKS_INITIAL_PROJECTILE_SPEED,
		"levels": { "HOLD": 0, "DMG": 0, "SPAWN_RATE": 0, "PROJECTILE_SPEED": 0 }
	})
	hero["coins"] -= barracks_cost
	_track_coin_spent(barracks_cost)
	_track_coin_spent(GameConstants.BARRACKS_COST)
	_track_tower_built("barracks")
	placing_barracks = false

# ========== NOVAS TORRES ==========

func _on_buy_mine() -> void:
	if placing_mine:
		return
	if hero["coins"] < GameConstants.MINE_COST:
		return
	if mines.size() >= GameConstants.MAX_MINES:
		return
	placing_mine = true
	placing_tower = false
	placing_barracks = false
	placing_slow_tower = false
	placing_aoe_tower = false
	placing_sniper_tower = false
	placing_boost_tower = false
	placing_wall = false
	placing_healing_station = false

func _is_on_path(world_pos: Vector2) -> bool:
	# Converter posição do mundo para coordenadas do grid principal
	var tile_col = int(floor(world_pos.x / GameConstants.TILE_SIZE))
	var tile_row = int(floor(world_pos.y / GameConstants.TILE_SIZE))
	
	# Verificar se está dentro dos limites do grid
	if tile_row < 0 or tile_row >= GameConstants.GRID_ROWS or tile_col < 0 or tile_col >= GameConstants.GRID_COLS:
		return false
	
	# Verificar se está em um caminho (grid[r][c] == 0)
	if grid_manager.grid.size() > tile_row and grid_manager.grid[tile_row].size() > tile_col:
		return grid_manager.grid[tile_row][tile_col] == 0
	return false

func _is_in_center_area(world_pos: Vector2) -> bool:
	# Verificar se está muito próximo do centro (dentro de 2 tiles do centro)
	var center_pos = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
	var dist = world_pos.distance_to(center_pos)
	var center_radius = GameConstants.TILE_SIZE * 2.0  # 2 tiles de raio
	return dist < center_radius

func _world_to_tile_coords(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / GameConstants.TILE_SIZE)),
		int(floor(world_pos.y / GameConstants.TILE_SIZE))
	)

func _is_tile_within_bounds(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.x < GameConstants.GRID_COLS and tile.y >= 0 and tile.y < GameConstants.GRID_ROWS

func _is_walkable_tile(tile: Vector2i) -> bool:
	if not _is_tile_within_bounds(tile):
		return false
	if grid_manager.grid.size() <= tile.y or grid_manager.grid[tile.y].size() <= tile.x:
		return false
	return grid_manager.grid[tile.y][tile.x] == 0

func _mine_tile_key(tile: Vector2i) -> String:
	return "%d_%d" % [tile.x, tile.y]

func _is_mine_tile_occupied(tile: Vector2i) -> bool:
	return mine_tiles.has(_mine_tile_key(tile))

func _register_mine_tile(tile: Vector2i) -> void:
	mine_tiles[_mine_tile_key(tile)] = true

func _unregister_mine_tile(tile: Vector2i) -> void:
	var key = _mine_tile_key(tile)
	if mine_tiles.has(key):
		mine_tiles.erase(key)

func _wall_tile_key(tile: Vector2i) -> String:
	return "%d_%d" % [tile.x, tile.y]

func _is_wall_tile_occupied(tile: Vector2i) -> bool:
	return wall_tiles.has(_wall_tile_key(tile))

func _register_wall_tile(tile: Vector2i) -> void:
	wall_tiles[_wall_tile_key(tile)] = true

func _unregister_wall_tile(tile: Vector2i) -> void:
	var key = _wall_tile_key(tile)
	if wall_tiles.has(key):
		wall_tiles.erase(key)


func _rebuild_mine_tiles() -> void:
	mine_tiles.clear()
	for mine in mines:
		if mine is Dictionary and mine.has("grid_x") and mine.has("grid_y"):
			var tile = Vector2i(int(mine["grid_x"]), int(mine["grid_y"]))
			mine_tiles[_mine_tile_key(tile)] = true

func _try_place_mine(pos: Vector2) -> void:
	if hero["coins"] < GameConstants.MINE_COST:
		placing_mine = false
		return
	if mines.size() >= GameConstants.MAX_MINES:
		placing_mine = false
		return
	
	# Mina deve ficar no labirinto (fora da base) e em tiles caminháveis
	if grid_manager.is_inside_base_point(pos):
		placing_mine = false
		return
	
	var tile = _world_to_tile_coords(pos)
	if not _is_walkable_tile(tile):
		placing_mine = false
		return
	if _is_in_center_area(pos):
		placing_mine = false
		return
	if _is_mine_tile_occupied(tile):
		placing_mine = false
		return
	
	var mine_world_pos = grid_manager.tile_center(tile.x, tile.y)
	mines.append({
		"pos": mine_world_pos,
		"grid_x": tile.x,
		"grid_y": tile.y,
		"damage": get_mine_damage(),
		"explosion_radius": get_mine_explosion_radius(),
		"slow_duration": GameConstants.MINE_SLOW_DURATION,
		"slow_amount": GameConstants.MINE_SLOW_AMOUNT,
		"trigger_radius": GameConstants.MINE_TRIGGER_RADIUS,
		"triggered": false
	})
	_register_mine_tile(tile)
	hero["coins"] -= GameConstants.MINE_COST
	placing_mine = false

func _on_buy_slow_tower() -> void:
	if placing_slow_tower:
		return
	var slow_cost_check = get_tower_cost(GameConstants.SLOW_TOWER_COST)
	if hero["coins"] < slow_cost_check:
		return
	if slow_towers.size() >= GameConstants.MAX_SLOW_TOWERS:
		return
	placing_slow_tower = true
	placing_tower = false
	placing_barracks = false
	placing_mine = false
	placing_aoe_tower = false
	placing_sniper_tower = false
	placing_boost_tower = false
	placing_wall = false
	placing_healing_station = false

func _try_place_slow_tower(pos: Vector2) -> void:
	var slow_cost = get_tower_cost(GameConstants.SLOW_TOWER_COST)
	if hero["coins"] < slow_cost:
		placing_slow_tower = false
		return
	if slow_towers.size() >= GameConstants.MAX_SLOW_TOWERS:
		placing_slow_tower = false
		return
	if not grid_manager.is_inside_base_point(pos):
		placing_slow_tower = false
		return
	var grid_coord = grid_manager.world_to_base_grid(pos)
	if not grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, GameConstants.SLOW_TOWER_SIZE_GRID, 5):
		placing_slow_tower = false
		return
	grid_manager.set_grid_area(grid_coord.x, grid_coord.y, GameConstants.SLOW_TOWER_SIZE_GRID, 5)
	pathfinder.invalidate_cache()
	var tower_world_pos = grid_manager.base_grid_to_world(grid_coord.x, grid_coord.y, GameConstants.SLOW_TOWER_SIZE_GRID)
	var slow_base_range = 200.0
	slow_towers.append({
		"pos": tower_world_pos,
		"grid_x": grid_coord.x,
		"grid_y": grid_coord.y,
		"range": slow_base_range * global_tower_range_boost,
		"base_range": slow_base_range,
		"slow_amount": 0.2,  # Valor inicial 20% (pode aumentar até 40% com upgrades)
		"slow_duration": 1.0,
		"cooldown": 0.0,
		"fire_rate": 0.5,
		"levels": {"RANGE": 0, "AMOUNT": 0, "DURATION": 0, "RATE": 0}
	})
	hero["coins"] -= slow_cost
	_track_coin_spent(slow_cost)
	_track_tower_built("slow_tower")
	placing_slow_tower = false

func _on_buy_aoe_tower() -> void:
	if placing_aoe_tower:
		return
	var aoe_cost_check = get_tower_cost(GameConstants.AOE_TOWER_COST)
	if hero["coins"] < aoe_cost_check:
		return
	if aoe_towers.size() >= GameConstants.MAX_AOE_TOWERS:
		return
	placing_aoe_tower = true
	placing_tower = false
	placing_barracks = false
	placing_mine = false
	placing_slow_tower = false
	placing_sniper_tower = false
	placing_boost_tower = false
	placing_wall = false
	placing_healing_station = false

func _try_place_aoe_tower(pos: Vector2) -> void:
	var aoe_cost = get_tower_cost(GameConstants.AOE_TOWER_COST)
	if hero["coins"] < aoe_cost:
		placing_aoe_tower = false
		return
	if aoe_towers.size() >= GameConstants.MAX_AOE_TOWERS:
		placing_aoe_tower = false
		return
	if not grid_manager.is_inside_base_point(pos):
		placing_aoe_tower = false
		return
	var grid_coord = grid_manager.world_to_base_grid(pos)
	if not grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, GameConstants.AOE_TOWER_SIZE_GRID, 6):
		placing_aoe_tower = false
		return
	grid_manager.set_grid_area(grid_coord.x, grid_coord.y, GameConstants.AOE_TOWER_SIZE_GRID, 6)
	pathfinder.invalidate_cache()
	var tower_world_pos = grid_manager.base_grid_to_world(grid_coord.x, grid_coord.y, GameConstants.AOE_TOWER_SIZE_GRID)
	var aoe_base_range = 180.0
	aoe_towers.append({
		"pos": tower_world_pos,
		"grid_x": grid_coord.x,
		"grid_y": grid_coord.y,
		"range": aoe_base_range * global_tower_range_boost,
		"base_range": aoe_base_range,
		"damage": 2.0,
		"aoe_radius": 60.0,
		"cooldown": 0.0,
		"fire_rate": 2.0,
		"levels": { "DMG": 0, "RATE": 0, "AREA": 0 }
	})
	hero["coins"] -= aoe_cost
	_track_coin_spent(aoe_cost)
	_track_tower_built("aoe_tower")
	placing_aoe_tower = false

func _on_buy_sniper_tower() -> void:
	if placing_sniper_tower:
		return
	var sniper_cost_check = get_tower_cost(GameConstants.SNIPER_TOWER_COST)
	if hero["coins"] < sniper_cost_check:
		return
	if sniper_towers.size() >= GameConstants.MAX_SNIPER_TOWERS:
		return
	placing_sniper_tower = true
	placing_tower = false
	placing_barracks = false
	placing_mine = false
	placing_slow_tower = false
	placing_aoe_tower = false
	placing_boost_tower = false
	placing_wall = false
	placing_healing_station = false

func _try_place_sniper_tower(pos: Vector2) -> void:
	var sniper_cost = get_tower_cost(GameConstants.SNIPER_TOWER_COST)
	if hero["coins"] < sniper_cost:
		placing_sniper_tower = false
		return
	if sniper_towers.size() >= GameConstants.MAX_SNIPER_TOWERS:
		placing_sniper_tower = false
		return
	if not grid_manager.is_inside_base_point(pos):
		placing_sniper_tower = false
		return
	var grid_coord = grid_manager.world_to_base_grid(pos)
	if not grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, GameConstants.SNIPER_TOWER_SIZE_GRID, 7):
		placing_sniper_tower = false
		return
	grid_manager.set_grid_area(grid_coord.x, grid_coord.y, GameConstants.SNIPER_TOWER_SIZE_GRID, 7)
	pathfinder.invalidate_cache()
	var tower_world_pos = grid_manager.base_grid_to_world(grid_coord.x, grid_coord.y, GameConstants.SNIPER_TOWER_SIZE_GRID)
	var sniper_base_range = 400.0
	sniper_towers.append({
		"pos": tower_world_pos,
		"grid_x": grid_coord.x,
		"grid_y": grid_coord.y,
		"range": sniper_base_range * global_tower_range_boost,
		"base_range": sniper_base_range,
		"damage": 8.0,  # Aumentado de 5.0 para 8.0
		"cooldown": 0.0,
		"fire_rate": 8.0,  # Reduzido de 15.0 para 8.0 para melhor correlação com dano e outras torres
		"pierce": 1,
		"target_mode": 0,  # 0 = Boss, 1 = Mais próximo ao centro
		"levels": { "DMG": 0, "RATE": 0 }
	})
	hero["coins"] -= sniper_cost
	_track_coin_spent(sniper_cost)
	_track_tower_built("sniper_tower")
	placing_sniper_tower = false

func _on_buy_boost_tower() -> void:
	if placing_boost_tower:
		return
	var boost_cost_check = get_tower_cost(GameConstants.BOOST_TOWER_COST)
	if hero["coins"] < boost_cost_check:
		return
	if boost_towers.size() >= GameConstants.MAX_BOOST_TOWERS:
		return
	placing_boost_tower = true
	placing_tower = false
	placing_barracks = false
	placing_mine = false
	placing_slow_tower = false
	placing_aoe_tower = false
	placing_sniper_tower = false
	placing_wall = false
	placing_healing_station = false

func _try_place_boost_tower(pos: Vector2) -> void:
	var boost_cost = get_tower_cost(GameConstants.BOOST_TOWER_COST)
	if hero["coins"] < boost_cost:
		placing_boost_tower = false
		return
	if boost_towers.size() >= GameConstants.MAX_BOOST_TOWERS:
		placing_boost_tower = false
		return
	if not grid_manager.is_inside_base_point(pos):
		placing_boost_tower = false
		return
	var grid_coord = grid_manager.world_to_base_grid(pos)
	if not grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, GameConstants.BOOST_TOWER_SIZE_GRID, 8):
		placing_boost_tower = false
		return
	grid_manager.set_grid_area(grid_coord.x, grid_coord.y, GameConstants.BOOST_TOWER_SIZE_GRID, 8)
	pathfinder.invalidate_cache()
	var tower_world_pos = grid_manager.base_grid_to_world(grid_coord.x, grid_coord.y, GameConstants.BOOST_TOWER_SIZE_GRID)
	boost_towers.append({
		"pos": tower_world_pos,
		"grid_x": grid_coord.x,
		"grid_y": grid_coord.y,
		"range": 9999.0,  # Range global - não precisa de upgrade de alcance
		"damage_boost": 0.2,  # Reduzido de 0.5 para 0.2 (20%)
		"rate_boost": 0.2,  # Reduzido de 0.3 para 0.2 (20%)
		"levels": {"DMG": 0, "RATE": 0}  # Removido RANGE - range é global
	})
	hero["coins"] -= boost_cost
	_track_coin_spent(boost_cost)
	_track_tower_built("boost_tower")
	placing_boost_tower = false

func _on_buy_shock_tower() -> void:
	if placing_shock_tower:
		return
	var shock_cost_check = get_tower_cost(GameConstants.SHOCK_TOWER_COST)
	if hero["coins"] < shock_cost_check:
		return
	if shock_towers.size() >= GameConstants.MAX_SHOCK_TOWERS:
		return
	placing_shock_tower = true
	placing_tower = false
	placing_barracks = false
	placing_mine = false
	placing_slow_tower = false
	placing_aoe_tower = false
	placing_sniper_tower = false
	placing_boost_tower = false
	placing_wall = false
	placing_healing_station = false

func _try_place_shock_tower(pos: Vector2) -> void:
	var shock_cost = get_tower_cost(GameConstants.SHOCK_TOWER_COST)
	if hero["coins"] < shock_cost:
		placing_shock_tower = false
		return
	if shock_towers.size() >= GameConstants.MAX_SHOCK_TOWERS:
		placing_shock_tower = false
		return
	if not grid_manager.is_inside_base_point(pos):
		placing_shock_tower = false
		return
	var grid_coord = grid_manager.world_to_base_grid(pos)
	if not grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, GameConstants.SHOCK_TOWER_SIZE_GRID, 9):
		placing_shock_tower = false
		return
	grid_manager.set_grid_area(grid_coord.x, grid_coord.y, GameConstants.SHOCK_TOWER_SIZE_GRID, 9)
	pathfinder.invalidate_cache()
	var tower_world_pos = grid_manager.base_grid_to_world(grid_coord.x, grid_coord.y, GameConstants.SHOCK_TOWER_SIZE_GRID)
	var shock_base_range = 200.0
	shock_towers.append({
		"pos": tower_world_pos,
		"grid_x": grid_coord.x,
		"grid_y": grid_coord.y,
		"range": shock_base_range * global_tower_range_boost,
		"base_range": shock_base_range,
		"damage": 1.5,
		"chain_count": 3,  # número de inimigos que o choque pode atingir
		"cooldown": 0.0,
		"fire_rate": 1.5,
		"levels": { "DMG": 0, "RATE": 0, "CHAIN": 0 }
	})
	hero["coins"] -= shock_cost
	_track_coin_spent(shock_cost)
	_track_tower_built("shock_tower")
	placing_shock_tower = false

func _on_buy_wall() -> void:
	if placing_wall:
		return
	var wall_cost = get_wall_cost()
	if hero["coins"] < wall_cost:
		return
	if walls.size() >= GameConstants.MAX_WALLS:
		return
	placing_wall = true
	placing_tower = false
	placing_barracks = false
	placing_mine = false
	placing_slow_tower = false
	placing_aoe_tower = false
	placing_sniper_tower = false
	placing_boost_tower = false
	placing_healing_station = false

func _try_place_wall(pos: Vector2) -> void:
	var wall_cost = get_wall_cost()
	if hero["coins"] < wall_cost:
		placing_wall = false
		return
	if walls.size() >= GameConstants.MAX_WALLS:
		placing_wall = false
		return
	
	# Muralha deve ficar no labirinto (fora da base) e em tiles caminháveis
	if grid_manager.is_inside_base_point(pos):
		placing_wall = false
		return
	
	# Muralha deve ser colocada nos caminhos (paths)
	if not _is_on_path(pos):
		placing_wall = false
		return
	
	var tile = _world_to_tile_coords(pos)
	if _is_wall_tile_occupied(tile):
		placing_wall = false
		return
	
	var wall_world_pos = grid_manager.tile_center(tile.x, tile.y)
	var base_hp = GameConstants.WALL_BASE_HP * wall_hp_multiplier
	walls.append({
		"pos": wall_world_pos,
		"grid_x": tile.x,
		"grid_y": tile.y,
		"hp": base_hp,
		"max_hp": base_hp,
		"upgrades": {"hp_level": 0}  # Nível de upgrade de HP
	})
	_register_wall_tile(tile)
	# Registrar no grid manager também (tipo 9 = wall)
	grid_manager.set_grid_area(tile.x, tile.y, GameConstants.WALL_SIZE_GRID, 9)
	pathfinder.invalidate_cache()
	pathfinder.set_wall_tiles(wall_tiles)  # Atualizar wall_tiles no pathfinder
	# NÃO recalcular caminhos aqui - deixar inimigos encontrarem a muralha e atacarem
	hero["coins"] -= wall_cost
	_track_coin_spent(wall_cost)
	_track_wall_built()
	placing_wall = false

func _recalculate_all_enemy_paths() -> void:
	"""Recalcula o caminho de todos os inimigos vivos quando o grid muda (ex: muralha colocada)"""
	pathfinder.set_wall_tiles(wall_tiles)
	for enemy in enemies:
		if enemy.has("pos") and not enemy.get("reached", false) and enemy.get("hp", 0) > 0:
			var enemy_tile = _world_to_tile_coords(enemy["pos"])
			var new_path = pathfinder.find_path(enemy_tile.x, enemy_tile.y, grid_manager.base_grid)
			if not new_path.is_empty():
				var pts = []
				for t in new_path:
					if t.x >= 0 and t.x < GameConstants.GRID_COLS and t.y >= 0 and t.y < GameConstants.GRID_ROWS:
						pts.append(grid_manager.tile_center(t.x, t.y))
				if not pts.is_empty():
					enemy["path"] = pts
					enemy["path_index"] = 0

func _try_move_wall(wall_idx: int, new_pos: Vector2) -> bool:
	if wall_idx < 0 or wall_idx >= walls.size():
		return false
	
	var wall = walls[wall_idx]
	
	# Limpar tile na posição antiga
	var old_tile = Vector2i(wall.grid_x, wall.grid_y)
	_unregister_wall_tile(old_tile)
	grid_manager.clear_grid_area(wall.grid_x, wall.grid_y, GameConstants.WALL_SIZE_GRID)
	
	# Verificar nova posição
	if grid_manager.is_inside_base_point(new_pos):
		# Restaurar tile antigo
		_register_wall_tile(old_tile)
		grid_manager.set_grid_area(wall.grid_x, wall.grid_y, GameConstants.WALL_SIZE_GRID, 9)
		return false
	
	# Muralha deve ser colocada nos caminhos (paths)
	if not _is_on_path(new_pos):
		# Restaurar tile antigo
		_register_wall_tile(old_tile)
		grid_manager.set_grid_area(wall.grid_x, wall.grid_y, GameConstants.WALL_SIZE_GRID, 9)
		return false
	
	var new_tile = _world_to_tile_coords(new_pos)
	if _is_wall_tile_occupied(new_tile):
		# Restaurar tile antigo
		_register_wall_tile(old_tile)
		grid_manager.set_grid_area(wall.grid_x, wall.grid_y, GameConstants.WALL_SIZE_GRID, 9)
		return false
	
	# Atualizar posição da muralha
	var new_world_pos = grid_manager.tile_center(new_tile.x, new_tile.y)
	wall.pos = new_world_pos
	wall.grid_x = new_tile.x
	wall.grid_y = new_tile.y
	_register_wall_tile(new_tile)
	# Registrar no grid manager na nova posição
	grid_manager.set_grid_area(new_tile.x, new_tile.y, GameConstants.WALL_SIZE_GRID, 9)
	pathfinder.invalidate_cache()
	pathfinder.set_wall_tiles(wall_tiles)  # Atualizar wall_tiles no pathfinder
	_recalculate_all_enemy_paths()  # Recalcular caminhos de todos os inimigos
	return true

func _try_move_mine(mine_idx: int, new_pos: Vector2) -> bool:
	if mine_idx < 0 or mine_idx >= mines.size():
		return false
	
	var mine = mines[mine_idx]
	
	# Limpar tile na posição antiga
	var old_tile = Vector2i(int(mine.grid_x), int(mine.grid_y))
	_unregister_mine_tile(old_tile)
	
	# Verificar nova posição
	# Mina deve ficar no labirinto (fora da base) e em tiles caminháveis
	if grid_manager.is_inside_base_point(new_pos):
		# Restaurar tile antigo
		_register_mine_tile(old_tile)
		return false
	
	var new_tile = _world_to_tile_coords(new_pos)
	if not _is_walkable_tile(new_tile):
		# Restaurar tile antigo
		_register_mine_tile(old_tile)
		return false
	
	if _is_in_center_area(new_pos):
		# Restaurar tile antigo
		_register_mine_tile(old_tile)
		return false
	
	if _is_mine_tile_occupied(new_tile):
		# Restaurar tile antigo
		_register_mine_tile(old_tile)
		return false
	
	# Atualizar posição da mina
	var new_world_pos = grid_manager.tile_center(new_tile.x, new_tile.y)
	mine.pos = new_world_pos
	mine.grid_x = new_tile.x
	mine.grid_y = new_tile.y
	_register_mine_tile(new_tile)
	
	mines[mine_idx] = mine
	return true

# Função auxiliar para mover torre usando grid_coord diretamente (evita recalcular e causar diferenças)
func _try_move_tower_to_grid(tower_idx: int, new_grid_coord: Vector2i) -> bool:
	if tower_idx < 0 or tower_idx >= towers.size():
		return false
	
	var tower = towers[tower_idx]
	
	# Se a nova posição é a mesma da antiga, não precisa fazer nada
	if new_grid_coord.x == tower.grid_x and new_grid_coord.y == tower.grid_y:
		return true
	
	# Criar área a ignorar (posição antiga da torre)
	var ignore_area = Rect2i(tower.grid_x, tower.grid_y, GameConstants.TOWER_SIZE_GRID, GameConstants.TOWER_SIZE_GRID)
	
	# Verificar se pode colocar na nova posição (ignorando a posição antiga)
	if not grid_manager.can_place_in_grid(new_grid_coord.x, new_grid_coord.y, GameConstants.TOWER_SIZE_GRID, 1, ignore_area):
		return false
	
	# Limpar grid na posição antiga (após confirmar que a nova posição é válida)
	grid_manager.clear_grid_area(tower.grid_x, tower.grid_y, GameConstants.TOWER_SIZE_GRID)
	
	# Atualizar grid na nova posição
	grid_manager.set_grid_area(new_grid_coord.x, new_grid_coord.y, GameConstants.TOWER_SIZE_GRID, 1)
	pathfinder.invalidate_cache()
	
	# Atualizar posição da torre usando EXATAMENTE a mesma função do posicionamento inicial
	var new_world_pos = grid_manager.base_grid_to_world(new_grid_coord.x, new_grid_coord.y, GameConstants.TOWER_SIZE_GRID)
	tower.pos = new_world_pos
	tower.grid_x = new_grid_coord.x
	tower.grid_y = new_grid_coord.y
	
	towers[tower_idx] = tower
	return true

func _try_move_tower(tower_idx: int, new_pos: Vector2) -> bool:
	# Esta função é mantida para compatibilidade, mas agora converte para grid_coord primeiro
	if tower_idx < 0 or tower_idx >= towers.size():
		return false
	
	# Verificar nova posição primeiro (antes de limpar a antiga)
	if not grid_manager.is_inside_base_point(new_pos):
		return false
	
	var new_grid_coord = grid_manager.world_to_base_grid(new_pos)
	return _try_move_tower_to_grid(tower_idx, new_grid_coord)

func _try_move_slow_tower_to_grid(tower_idx: int, new_grid_coord: Vector2i) -> bool:
	if tower_idx < 0 or tower_idx >= slow_towers.size():
		return false
	
	var tower = slow_towers[tower_idx]
	
	# Se a nova posição é a mesma da antiga, não precisa fazer nada
	if new_grid_coord.x == tower.grid_x and new_grid_coord.y == tower.grid_y:
		return true
	
	# Criar área a ignorar (posição antiga da torre)
	var ignore_area = Rect2i(tower.grid_x, tower.grid_y, GameConstants.SLOW_TOWER_SIZE_GRID, GameConstants.SLOW_TOWER_SIZE_GRID)
	
	# Verificar se pode colocar na nova posição (ignorando a posição antiga)
	if not grid_manager.can_place_in_grid(new_grid_coord.x, new_grid_coord.y, GameConstants.SLOW_TOWER_SIZE_GRID, 5, ignore_area):
		return false
	
	# Limpar grid na posição antiga (após confirmar que a nova posição é válida)
	grid_manager.clear_grid_area(tower.grid_x, tower.grid_y, GameConstants.SLOW_TOWER_SIZE_GRID)
	
	# Atualizar grid na nova posição
	grid_manager.set_grid_area(new_grid_coord.x, new_grid_coord.y, GameConstants.SLOW_TOWER_SIZE_GRID, 5)
	pathfinder.invalidate_cache()
	
	var new_world_pos = grid_manager.base_grid_to_world(new_grid_coord.x, new_grid_coord.y, GameConstants.SLOW_TOWER_SIZE_GRID)
	tower.pos = new_world_pos
	tower.grid_x = new_grid_coord.x
	tower.grid_y = new_grid_coord.y
	
	slow_towers[tower_idx] = tower
	return true

func _try_move_slow_tower(tower_idx: int, new_pos: Vector2) -> bool:
	if tower_idx < 0 or tower_idx >= slow_towers.size():
		return false
	if not grid_manager.is_inside_base_point(new_pos):
		return false
	var new_grid_coord = grid_manager.world_to_base_grid(new_pos)
	return _try_move_slow_tower_to_grid(tower_idx, new_grid_coord)

func _try_move_aoe_tower_to_grid(tower_idx: int, new_grid_coord: Vector2i) -> bool:
	if tower_idx < 0 or tower_idx >= aoe_towers.size():
		return false
	
	var tower = aoe_towers[tower_idx]
	
	if new_grid_coord.x == tower.grid_x and new_grid_coord.y == tower.grid_y:
		return true
	
	var ignore_area = Rect2i(tower.grid_x, tower.grid_y, GameConstants.AOE_TOWER_SIZE_GRID, GameConstants.AOE_TOWER_SIZE_GRID)
	
	if not grid_manager.can_place_in_grid(new_grid_coord.x, new_grid_coord.y, GameConstants.AOE_TOWER_SIZE_GRID, 6, ignore_area):
		return false
	
	grid_manager.clear_grid_area(tower.grid_x, tower.grid_y, GameConstants.AOE_TOWER_SIZE_GRID)
	grid_manager.set_grid_area(new_grid_coord.x, new_grid_coord.y, GameConstants.AOE_TOWER_SIZE_GRID, 6)
	pathfinder.invalidate_cache()
	
	var new_world_pos = grid_manager.base_grid_to_world(new_grid_coord.x, new_grid_coord.y, GameConstants.AOE_TOWER_SIZE_GRID)
	tower.pos = new_world_pos
	tower.grid_x = new_grid_coord.x
	tower.grid_y = new_grid_coord.y
	
	aoe_towers[tower_idx] = tower
	return true

func _try_move_aoe_tower(tower_idx: int, new_pos: Vector2) -> bool:
	if tower_idx < 0 or tower_idx >= aoe_towers.size():
		return false
	if not grid_manager.is_inside_base_point(new_pos):
		return false
	var new_grid_coord = grid_manager.world_to_base_grid(new_pos)
	return _try_move_aoe_tower_to_grid(tower_idx, new_grid_coord)

func _try_move_sniper_tower_to_grid(tower_idx: int, new_grid_coord: Vector2i) -> bool:
	if tower_idx < 0 or tower_idx >= sniper_towers.size():
		return false
	
	var tower = sniper_towers[tower_idx]
	
	if new_grid_coord.x == tower.grid_x and new_grid_coord.y == tower.grid_y:
		return true
	
	var ignore_area = Rect2i(tower.grid_x, tower.grid_y, GameConstants.SNIPER_TOWER_SIZE_GRID, GameConstants.SNIPER_TOWER_SIZE_GRID)
	
	if not grid_manager.can_place_in_grid(new_grid_coord.x, new_grid_coord.y, GameConstants.SNIPER_TOWER_SIZE_GRID, 7, ignore_area):
		return false
	
	grid_manager.clear_grid_area(tower.grid_x, tower.grid_y, GameConstants.SNIPER_TOWER_SIZE_GRID)
	grid_manager.set_grid_area(new_grid_coord.x, new_grid_coord.y, GameConstants.SNIPER_TOWER_SIZE_GRID, 7)
	pathfinder.invalidate_cache()
	
	var new_world_pos = grid_manager.base_grid_to_world(new_grid_coord.x, new_grid_coord.y, GameConstants.SNIPER_TOWER_SIZE_GRID)
	tower.pos = new_world_pos
	tower.grid_x = new_grid_coord.x
	tower.grid_y = new_grid_coord.y
	
	sniper_towers[tower_idx] = tower
	return true

func _try_move_sniper_tower(tower_idx: int, new_pos: Vector2) -> bool:
	if tower_idx < 0 or tower_idx >= sniper_towers.size():
		return false
	if not grid_manager.is_inside_base_point(new_pos):
		return false
	var new_grid_coord = grid_manager.world_to_base_grid(new_pos)
	return _try_move_sniper_tower_to_grid(tower_idx, new_grid_coord)

func _try_move_boost_tower_to_grid(tower_idx: int, new_grid_coord: Vector2i) -> bool:
	if tower_idx < 0 or tower_idx >= boost_towers.size():
		return false
	
	var tower = boost_towers[tower_idx]
	
	if new_grid_coord.x == tower.grid_x and new_grid_coord.y == tower.grid_y:
		return true
	
	var ignore_area = Rect2i(tower.grid_x, tower.grid_y, GameConstants.BOOST_TOWER_SIZE_GRID, GameConstants.BOOST_TOWER_SIZE_GRID)
	
	if not grid_manager.can_place_in_grid(new_grid_coord.x, new_grid_coord.y, GameConstants.BOOST_TOWER_SIZE_GRID, 8, ignore_area):
		return false
	
	grid_manager.clear_grid_area(tower.grid_x, tower.grid_y, GameConstants.BOOST_TOWER_SIZE_GRID)
	grid_manager.set_grid_area(new_grid_coord.x, new_grid_coord.y, GameConstants.BOOST_TOWER_SIZE_GRID, 8)
	pathfinder.invalidate_cache()
	
	var new_world_pos = grid_manager.base_grid_to_world(new_grid_coord.x, new_grid_coord.y, GameConstants.BOOST_TOWER_SIZE_GRID)
	tower.pos = new_world_pos
	tower.grid_x = new_grid_coord.x
	tower.grid_y = new_grid_coord.y
	
	boost_towers[tower_idx] = tower
	return true

func _try_move_boost_tower(tower_idx: int, new_pos: Vector2) -> bool:
	if tower_idx < 0 or tower_idx >= boost_towers.size():
		return false
	if not grid_manager.is_inside_base_point(new_pos):
		return false
	var new_grid_coord = grid_manager.world_to_base_grid(new_pos)
	return _try_move_boost_tower_to_grid(tower_idx, new_grid_coord)

func _try_move_shock_tower_to_grid(tower_idx: int, new_grid_coord: Vector2i) -> bool:
	if tower_idx < 0 or tower_idx >= shock_towers.size():
		return false
	
	var tower = shock_towers[tower_idx]
	
	if new_grid_coord.x == tower.grid_x and new_grid_coord.y == tower.grid_y:
		return true
	
	var ignore_area = Rect2i(tower.grid_x, tower.grid_y, GameConstants.SHOCK_TOWER_SIZE_GRID, GameConstants.SHOCK_TOWER_SIZE_GRID)
	
	if not grid_manager.can_place_in_grid(new_grid_coord.x, new_grid_coord.y, GameConstants.SHOCK_TOWER_SIZE_GRID, 9, ignore_area):
		return false
	
	grid_manager.clear_grid_area(tower.grid_x, tower.grid_y, GameConstants.SHOCK_TOWER_SIZE_GRID)
	grid_manager.set_grid_area(new_grid_coord.x, new_grid_coord.y, GameConstants.SHOCK_TOWER_SIZE_GRID, 9)
	pathfinder.invalidate_cache()
	
	var new_world_pos = grid_manager.base_grid_to_world(new_grid_coord.x, new_grid_coord.y, GameConstants.SHOCK_TOWER_SIZE_GRID)
	tower.pos = new_world_pos
	tower.grid_x = new_grid_coord.x
	tower.grid_y = new_grid_coord.y
	
	shock_towers[tower_idx] = tower
	return true

func _try_move_shock_tower(tower_idx: int, new_pos: Vector2) -> bool:
	if tower_idx < 0 or tower_idx >= shock_towers.size():
		return false
	if not grid_manager.is_inside_base_point(new_pos):
		return false
	var new_grid_coord = grid_manager.world_to_base_grid(new_pos)
	return _try_move_shock_tower_to_grid(tower_idx, new_grid_coord)

func _try_move_barracks_to_grid(barracks_idx: int, new_grid_coord: Vector2i) -> bool:
	if barracks_idx < 0 or barracks_idx >= barracks.size():
		return false
	
	var b = barracks[barracks_idx]
	
	if new_grid_coord.x == b.grid_x and new_grid_coord.y == b.grid_y:
		return true
	
	var ignore_area = Rect2i(b.grid_x, b.grid_y, GameConstants.BARRACKS_SIZE_GRID, GameConstants.BARRACKS_SIZE_GRID)
	
	if not grid_manager.can_place_in_grid(new_grid_coord.x, new_grid_coord.y, GameConstants.BARRACKS_SIZE_GRID, 3, ignore_area):
		return false
	
	grid_manager.clear_grid_area(b.grid_x, b.grid_y, GameConstants.BARRACKS_SIZE_GRID)
	grid_manager.set_grid_area(new_grid_coord.x, new_grid_coord.y, GameConstants.BARRACKS_SIZE_GRID, 3)
	pathfinder.invalidate_cache()
	
	var new_world_pos = grid_manager.base_grid_to_world(new_grid_coord.x, new_grid_coord.y, GameConstants.BARRACKS_SIZE_GRID)
	b.pos = new_world_pos
	b.grid_x = new_grid_coord.x
	b.grid_y = new_grid_coord.y
	
	barracks[barracks_idx] = b
	return true

func _try_move_barracks(barracks_idx: int, new_pos: Vector2) -> bool:
	if barracks_idx < 0 or barracks_idx >= barracks.size():
		return false
	if not grid_manager.is_inside_base_point(new_pos):
		return false
	var new_grid_coord = grid_manager.world_to_base_grid(new_pos)
	return _try_move_barracks_to_grid(barracks_idx, new_grid_coord)

func _try_move_market_to_grid(market_idx: int, new_grid_coord: Vector2i) -> bool:
	if market_idx < 0 or market_idx >= markets.size():
		return false
	
	var m = markets[market_idx]
	
	if new_grid_coord.x == m.grid_x and new_grid_coord.y == m.grid_y:
		return true
	
	var ignore_area = Rect2i(m.grid_x, m.grid_y, GameConstants.MARKET_SIZE_GRID, GameConstants.MARKET_SIZE_GRID)
	
	if not grid_manager.can_place_in_grid(new_grid_coord.x, new_grid_coord.y, GameConstants.MARKET_SIZE_GRID, 11, ignore_area):
		return false
	
	grid_manager.clear_grid_area(m.grid_x, m.grid_y, GameConstants.MARKET_SIZE_GRID)
	grid_manager.set_grid_area(new_grid_coord.x, new_grid_coord.y, GameConstants.MARKET_SIZE_GRID, 11)
	pathfinder.invalidate_cache()
	
	var new_world_pos = grid_manager.base_grid_to_world(new_grid_coord.x, new_grid_coord.y, GameConstants.MARKET_SIZE_GRID)
	m.pos = new_world_pos
	m.grid_x = new_grid_coord.x
	m.grid_y = new_grid_coord.y
	
	markets[market_idx] = m
	return true

func _on_buy_healing_station() -> void:
	if placing_healing_station:
		return
	if hero["coins"] < GameConstants.HEALING_STATION_COST:
		return
	if healing_stations.size() >= GameConstants.MAX_HEALING_STATIONS:
		return
	placing_healing_station = true
	placing_tower = false
	placing_barracks = false
	placing_mine = false
	placing_slow_tower = false
	placing_aoe_tower = false
	placing_sniper_tower = false
	placing_boost_tower = false
	placing_wall = false
	placing_market = false

func _try_place_healing_station(pos: Vector2) -> void:
	if hero["coins"] < GameConstants.HEALING_STATION_COST:
		placing_healing_station = false
		return
	if healing_stations.size() >= GameConstants.MAX_HEALING_STATIONS:
		placing_healing_station = false
		return
	if not grid_manager.is_inside_base_point(pos):
		placing_healing_station = false
		return
	var grid_coord = grid_manager.world_to_base_grid(pos)
	if not grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, GameConstants.HEALING_STATION_SIZE_GRID, 10):
		placing_healing_station = false
		return
	grid_manager.set_grid_area(grid_coord.x, grid_coord.y, GameConstants.HEALING_STATION_SIZE_GRID, 10)
	pathfinder.invalidate_cache()
	var station_world_pos = grid_manager.base_grid_to_world(grid_coord.x, grid_coord.y)
	healing_stations.append({
		"pos": station_world_pos,
		"grid_x": grid_coord.x,
		"grid_y": grid_coord.y,
		"heal_amount": 5.0,  # cura 5 HP no final da wave
		"range": 100.0
	})
	hero["coins"] -= GameConstants.HEALING_STATION_COST
	placing_healing_station = false

func _on_buy_market() -> void:
	if placing_market:
		return
	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}
	if currency_info.emeralds < GameConstants.MARKET_COST_EMERALDS:
		return
	if markets.size() >= GameConstants.MAX_MARKETS:
		return
	placing_market = true
	placing_tower = false
	placing_barracks = false
	placing_mine = false
	placing_slow_tower = false
	placing_aoe_tower = false
	placing_sniper_tower = false
	placing_boost_tower = false
	placing_shock_tower = false
	placing_wall = false
	placing_healing_station = false

func _try_place_market(pos: Vector2) -> void:
	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}
	if currency_info.emeralds < GameConstants.MARKET_COST_EMERALDS:
		placing_market = false
		return
	if markets.size() >= GameConstants.MAX_MARKETS:
		placing_market = false
		return
	if not grid_manager.is_inside_base_point(pos):
		placing_market = false
		return
	var grid_coord = grid_manager.world_to_base_grid(pos)
	if not grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, GameConstants.MARKET_SIZE_GRID, 11):
		placing_market = false
		return
	grid_manager.set_grid_area(grid_coord.x, grid_coord.y, GameConstants.MARKET_SIZE_GRID, 11)
	pathfinder.invalidate_cache()
	var market_world_pos = grid_manager.base_grid_to_world(grid_coord.x, grid_coord.y, GameConstants.MARKET_SIZE_GRID)
	var new_market = Market.new(grid_coord, market_world_pos)
	markets.append(new_market)
	if special_currency_manager:
		special_currency_manager.spend_emeralds(GameConstants.MARKET_COST_EMERALDS)
	placing_market = false

func _open_market_menu(idx: int, screen_pos: Vector2) -> void:
	if market_menu == null:
		market_menu = PopupMenu.new()
		market_menu.id_pressed.connect(_on_market_menu_selected)
		add_child(market_menu)
	
	market_selected_index = idx
	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}
	var has_emeralds = currency_info.emeralds > 0
	
	market_menu.clear()
	# Cura Completa (2 usos)
	var heal_text = "Cura Completa (🟢 %d esmeraldas)" % GameConstants.MARKET_ITEM_HEAL_FULL
	if heal_full_uses_remaining <= 0:
		heal_text += " [Sem usos]"
	else:
		heal_text += " [%d usos restantes]" % heal_full_uses_remaining
	market_menu.add_item(heal_text)
	market_menu.set_item_disabled(0, currency_info.emeralds < GameConstants.MARKET_ITEM_HEAL_FULL or heal_full_uses_remaining <= 0)
	
	market_menu.add_separator()
	
	# Buffs temporários (não cumulativos)
	var tower_boost_text = "+20%% Dano Torres (5 waves) (🟢 %d esmeraldas)" % GameConstants.MARKET_ITEM_TOWER_DAMAGE_BOOST
	if tower_damage_boost_waves_remaining > 0:
		tower_boost_text += " [%d waves restantes]" % tower_damage_boost_waves_remaining
	market_menu.add_item(tower_boost_text)
	market_menu.set_item_disabled(1, currency_info.emeralds < GameConstants.MARKET_ITEM_TOWER_DAMAGE_BOOST or tower_damage_boost_waves_remaining > 0)
	
	var hero_boost_text = "+30%% Dano Herói (5 waves) (🟢 %d esmeraldas)" % GameConstants.MARKET_ITEM_HERO_DAMAGE_BOOST
	if hero_damage_boost_waves_remaining > 0:
		hero_boost_text += " [%d waves restantes]" % hero_damage_boost_waves_remaining
	market_menu.add_item(hero_boost_text)
	market_menu.set_item_disabled(2, currency_info.emeralds < GameConstants.MARKET_ITEM_HERO_DAMAGE_BOOST or hero_damage_boost_waves_remaining > 0)
	
	market_menu.add_separator()
	
	market_menu.add_item("+1 Vida Extra (🟢 %d esmeraldas)" % GameConstants.MARKET_ITEM_EXTRA_LIFE)
	market_menu.set_item_disabled(4, currency_info.emeralds < GameConstants.MARKET_ITEM_EXTRA_LIFE)
	
	market_menu.add_separator()
	market_menu.add_item("Fechar")
	
	market_menu.position = screen_pos
	market_menu.popup()

func _on_market_menu_selected(id: int) -> void:
	if market_selected_index < 0 or market_selected_index >= markets.size():
		return
	
	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}
	
	match id:
		0:  # Cura Completa
			if currency_info.emeralds >= GameConstants.MARKET_ITEM_HEAL_FULL and heal_full_uses_remaining > 0:
				special_currency_manager.spend_emeralds(GameConstants.MARKET_ITEM_HEAL_FULL)
				base_hp = base_hp_max
				heal_full_uses_remaining -= 1
				if notification_manager:
					notification_manager.show_notification("Herói curado completamente! (%d usos restantes)" % heal_full_uses_remaining, 3.0, NotificationManager.NotificationPosition.TOP_CENTER, Color(0.2, 0.8, 0.3))
		1:  # Boost Dano Torres
			if currency_info.emeralds >= GameConstants.MARKET_ITEM_TOWER_DAMAGE_BOOST and tower_damage_boost_waves_remaining <= 0:
				special_currency_manager.spend_emeralds(GameConstants.MARKET_ITEM_TOWER_DAMAGE_BOOST)
				global_tower_damage_boost = 1.2  # +20%
				tower_damage_boost_waves_remaining = 5
				if notification_manager:
					notification_manager.show_notification("+20%% Dano Torres por 5 waves!", 3.0, NotificationManager.NotificationPosition.TOP_CENTER, Color(0.8, 0.2, 0.8))
		2:  # Boost Dano Herói
			if currency_info.emeralds >= GameConstants.MARKET_ITEM_HERO_DAMAGE_BOOST and hero_damage_boost_waves_remaining <= 0:
				special_currency_manager.spend_emeralds(GameConstants.MARKET_ITEM_HERO_DAMAGE_BOOST)
				# Aplicar boost no herói (será implementado)
				hero_damage_boost_waves_remaining = 5
				if notification_manager:
					notification_manager.show_notification("+30%% Dano Herói por 5 waves!", 3.0, NotificationManager.NotificationPosition.TOP_CENTER, Color(0.8, 0.2, 0.8))
		4:  # Vida Extra
			if currency_info.emeralds >= GameConstants.MARKET_ITEM_EXTRA_LIFE:
				special_currency_manager.spend_emeralds(GameConstants.MARKET_ITEM_EXTRA_LIFE)
				base_hp_max += 50
				base_hp += 50
				if notification_manager:
					notification_manager.show_notification("+50 HP Máximo!", 3.0, NotificationManager.NotificationPosition.TOP_CENTER, Color(0.2, 0.8, 0.3))
	
	keep_market_menu_open = false
	market_menu.hide()

func _physics_process(delta: float) -> void:
	# aplicar skill de boost de velocidade no herói
	var hero_rate_multiplier = 1.0
	if skills_manager:
		hero_rate_multiplier = skills_manager.get_speed_multiplier()
	
	hero["cooldown"] = max(0.0, hero["cooldown"] - delta * hero_rate_multiplier)
	
	# tiro automático do herói - procura inimigo mais próximo e atira quando cooldown estiver pronto
	if hero["cooldown"] <= 0.0 and not paused and not game_over:
		var closest_enemy = null
		var closest_dist = hero["range"]  # usar o alcance do herói como limite
		
		for e in enemies:
			if e["hp"] <= 0 or e["reached"]:
				continue
			var dist = Vector2(hero["x"], hero["y"]).distance_to(e["pos"])
			if dist < closest_dist:
				closest_dist = dist
				closest_enemy = e
		
		if closest_enemy != null:
			var hero_pos = Vector2(hero["x"], hero["y"])
			var predicted_target = _calculate_leading_target(closest_enemy, hero_pos)
			_try_shoot(predicted_target)
	
	# torres: 1 tiro por direção no intervalo configurado (fire_rate)
	for t in towers:
		# aplicar boost de rate de boost towers próximos
		var rate_multiplier = 1.0
		for boost in boost_towers:
			var dist = t.pos.distance_to(boost.pos)
			if dist <= boost.range:
				rate_multiplier += boost.rate_boost
		
		# aplicar skill de boost de velocidade
		if skills_manager:
			rate_multiplier *= skills_manager.get_speed_multiplier()
		
		var effective_fire_rate = t.fire_rate / rate_multiplier
		# Garantir que o effective_fire_rate nunca seja menor que o limite mínimo
		effective_fire_rate = max(GameConstants.TOWER_MIN_FIRE_RATE, effective_fire_rate)
		t.cooldown = max(0.0, t.cooldown - delta * rate_multiplier)
		if t.cooldown <= 0.0:
			_tower_fire_cross(t)
			t.cooldown = effective_fire_rate
	
	# atualizar novas torres (apenas se não estiver pausado)
	if not paused and not game_over:
		# Nota: TowerSystemManager ainda não implementa completamente as torres,
		# então usamos as implementações reais do Game.gd
		_update_mines(delta)
		_update_slow_towers(delta)
		_update_aoe_towers(delta)
		_update_sniper_towers(delta)
		_update_shock_towers(delta)
		_update_boost_towers(delta)
		_update_walls(delta)
		_update_healing_stations(delta)

func _tower_fire_cross(tower: Dictionary) -> void:
	var speed := 260.0
	var dirs: Array = tower.get("dirs", [Vector2(1, 0)])
	var tower_damage: float = tower.get("damage", GameConstants.TOWER_BASE_DAMAGE) * global_tower_damage_boost
	var has_freeze: bool = tower.get("has_freeze", false)
	var has_fire: bool = tower.get("has_fire", false)
	
	# aplicar boost de boost towers próximos
	var damage_multiplier = 1.0
	for boost in boost_towers:
		var dist = tower.pos.distance_to(boost.pos)
		if dist <= boost.range:
			damage_multiplier += boost.damage_boost
	
	# aplicar skill de boost de dano
	if skills_manager:
		damage_multiplier *= skills_manager.get_damage_multiplier()
	
	# Aplicar multiplicador de clima
	if weather_manager:
		damage_multiplier *= weather_manager.get_tower_damage_multiplier()
	
	tower_damage *= damage_multiplier
	var tower_range = tower.get("range", 260.0)
	# Aplicar multiplicador de alcance do clima
	if weather_manager:
		tower_range *= weather_manager.get_tower_range_multiplier()
	var life := float(tower_range) / speed
	
	# Rastrear DPS da torre
	var tower_id = _get_tower_id(tower, "tower")
	if not tower_dps_data.has(tower_id):
		tower_dps_data[tower_id] = {
			"dps": 0.0,
			"damage_dealt": 0.0,
			"shots": 0,
			"wave_damage": {},
			"tower_type": "tower",
			"pos": tower.pos
		}
	tower_dps_data[tower_id]["shots"] += dirs.size()
	
	for d in dirs:
		var b = { "pos": tower.pos, "vel": d * speed, "life": life, "radius": 2, "damage": tower_damage, "pierce": 0, "has_freeze": has_freeze, "has_fire": has_fire, "tower_id": tower_id }
		tower_bullets.append(b)

func _update_barracks(delta: float) -> void:
	for b in barracks:
		# sincronizar lista de soldados do quartel com lista global (remover mortos)
		var valid_soldiers: Array = []
		for s in b.soldiers:
			var found = false
			for global_s in soldiers:
				if global_s == s and global_s.hp > 0:
					found = true
					valid_soldiers.append(s)
					break
			# se não encontrou mas o soldado ainda tem HP, manter
			if not found and s.hp > 0:
				valid_soldiers.append(s)
		b.soldiers = valid_soldiers
		
		b.soldier_spawn_cd -= delta
		# spawnar soldados sempre que o cooldown acabar (sem limite de quantidade)
		# não depende de ter inimigos presentes
		if b.soldier_spawn_cd <= 0.0:
			# encontrar inimigo mais próximo (se existir)
			var closest_enemy_idx = -1
			var closest_dist = 9999.0
			for i in range(enemies.size()):
				var e = enemies[i]
				if e["hp"] <= 0 or e["reached"]:
					continue
				var dist = b.pos.distance_to(e["pos"])
				if dist < closest_dist:
					closest_dist = dist
					closest_enemy_idx = i
			
			# criar soldado mesmo se não houver inimigo (ele vai procurar depois)
			if closest_enemy_idx < 0:
				closest_enemy_idx = -1  # soldado vai procurar quando houver inimigos
			
			# criar soldado com stats atualizados do quartel
			var soldier = {
				"pos": b.pos,
				"target_enemy_idx": closest_enemy_idx,
				"hold_time": 0.0,
				"max_hold_time": b.hold_time,  # usar valor atualizado do quartel
				"damage": b.damage,  # usar valor atualizado do quartel
				"hp": 10.0,
				"max_hp": 10.0,
				"radius": 6.0,
				"speed": b.projectile_speed,  # usar velocidade do quartel
				"holding": false
			}
			b.soldiers.append(soldier)
			soldiers.append(soldier)
			b.soldier_spawn_cd = b.soldier_spawn_rate

# ========== FUNÇÕES DE ATUALIZAÇÃO DAS NOVAS TORRES ==========

func _update_mines(_delta: float) -> void:
	var mines_to_remove: Array = []
	for i in range(mines.size()):
		var m = mines[i]
		if m.triggered:
			mines_to_remove.append(i)
			continue
		var trigger_radius = m.get("trigger_radius", GameConstants.MINE_TRIGGER_RADIUS)
		# verificar se algum inimigo passou pela mina
		for e in enemies:
			if e["hp"] <= 0 or e["reached"]:
				continue
			var dist = m.pos.distance_to(e["pos"])
			if dist <= trigger_radius:
				m.triggered = true
				_detonate_mine(m)
				mines_to_remove.append(i)
				break
	# remover minas ativadas (em ordem reversa para não quebrar índices)
	mines_to_remove.reverse()
	for idx in mines_to_remove:
		if idx < mines.size():
			var tile = Vector2i(int(mines[idx].grid_x), int(mines[idx].grid_y))
			_unregister_mine_tile(tile)
			mines.remove_at(idx)

func _detonate_mine(mine: Dictionary) -> void:
	# Usar valores da mina (já incluem upgrades) ou calcular se não existir
	var explosion_damage = mine.get("damage", get_mine_damage())
	var explosion_radius = mine.get("explosion_radius", get_mine_explosion_radius())
	var slow_duration = mine.get("slow_duration", GameConstants.MINE_SLOW_DURATION)
	var slow_amount = mine.get("slow_amount", GameConstants.MINE_SLOW_AMOUNT)
	
	if effects_manager:
		effects_manager.create_aoe_effect(mine.pos, explosion_radius, 0.35)
	
	for e in enemies:
		if e["hp"] <= 0 or e["reached"]:
			continue
		var dist = mine.pos.distance_to(e["pos"])
		if dist <= explosion_radius:
			e["hp"] -= explosion_damage
			_create_damage_number(e["pos"], explosion_damage, false)
			var enemy_idx = e.get("idx", -1)
			if enemy_idx >= 0:
				if not enemy_effects.has(enemy_idx):
					enemy_effects[enemy_idx] = { "slow_time": 0.0, "slow_amount": 0.0, "freeze_time": 0.0, "fire_time": 0.0, "fire_damage": 0.0 }
				enemy_effects[enemy_idx].slow_time = max(enemy_effects[enemy_idx].get("slow_time", 0.0), slow_duration)
				enemy_effects[enemy_idx].slow_amount = max(enemy_effects[enemy_idx].get("slow_amount", 0.0), slow_amount)
			if e["hp"] <= 0:
				e["hp"] = 0
				e["dying"] = true
				e["dying_time"] = 0.0
				_create_death_animation(e["pos"])
				var is_boss = e.get("is_boss", false)
				hero["coins"] += get_boss_reward() if is_boss else get_enemy_reward()
				_try_drop_coin(e["pos"])
				_track_enemy_kill(is_boss)

func _update_slow_towers(_delta: float) -> void:
	for st in slow_towers:
		# aplicar skill de boost de velocidade
		var slow_rate_multiplier = 1.0
		if skills_manager:
			slow_rate_multiplier = skills_manager.get_speed_multiplier()
		
		# Aplicar slow continuamente enquanto o inimigo está dentro do alcance (sem cooldown)
		for e in enemies:
			if e["hp"] <= 0 or e["reached"]:
				continue
			var dist = st.pos.distance_to(e["pos"])
			if dist <= st.range:
				var enemy_idx = e.get("idx", -1)
				if enemy_idx >= 0:
					if not enemy_effects.has(enemy_idx):
						enemy_effects[enemy_idx] = { "slow_time": 0.0, "slow_amount": 0.0, "freeze_time": 0.0, "fire_time": 0.0 }
					# Slow funciona enquanto está dentro da área (sem duração)
					enemy_effects[enemy_idx].slow_time = 999999.0  # Valor alto para durar enquanto estiver na área
					enemy_effects[enemy_idx].slow_amount = st.slow_amount

func _update_aoe_towers(delta: float) -> void:
	if paused or game_over:
		return
	for aoe in aoe_towers:
		# aplicar boost de rate de boost towers próximos
		var aoe_rate_multiplier = 1.0
		for boost in boost_towers:
			var dist = aoe.pos.distance_to(boost.pos)
			if dist <= boost.range:
				aoe_rate_multiplier += boost.rate_boost
		
		# aplicar skill de boost de velocidade
		if skills_manager:
			aoe_rate_multiplier *= skills_manager.get_speed_multiplier()
		
		# Calcular effective_fire_rate respeitando o mínimo
		var effective_fire_rate = aoe.fire_rate / aoe_rate_multiplier
		effective_fire_rate = max(GameConstants.AOE_MIN_FIRE_RATE, effective_fire_rate)
		
		aoe.cooldown = max(0.0, aoe.cooldown - delta * aoe_rate_multiplier)
		if aoe.cooldown <= 0.0:
			# encontrar inimigo mais próximo
			var closest_enemy = null
			var effective_range = get_effective_tower_range(aoe.range)
			var closest_dist = effective_range + 1.0  # +1 para garantir que encontre o mais próximo
			for e in enemies:
				if e["hp"] <= 0 or e["reached"]:
					continue
				var dist = aoe.pos.distance_to(e["pos"])
				if dist <= effective_range and dist < closest_dist:
					closest_dist = dist
					closest_enemy = e
			if closest_enemy != null:
				# criar projétil de canhão (bola preta) até o alvo
				var cannon_speed = 200.0
				# aplicar bônus globais de dano
				var aoe_damage = aoe.damage * global_tower_damage_boost
				
				# aplicar boost de dano de boost towers próximos
				var damage_multiplier = 1.0
				for boost in boost_towers:
					var dist = aoe.pos.distance_to(boost.pos)
					if dist <= boost.range:
						damage_multiplier += boost.damage_boost
				aoe_damage *= damage_multiplier
				
				# aplicar skill de boost de dano
				if skills_manager:
					aoe_damage *= skills_manager.get_damage_multiplier()
				
				# Aplicar multiplicador de clima
				aoe_damage = get_effective_tower_damage(aoe_damage)
				
				aoe_cannon_projectiles.append({
					"pos": aoe.pos,
					"target": closest_enemy["pos"],
					"speed": cannon_speed,
					"radius": aoe.aoe_radius,
					"damage": aoe_damage,
					"aoe_tower": aoe
				})
				# resetar cooldown apenas se encontrou alvo (usar effective_fire_rate)
				aoe.cooldown = effective_fire_rate
			else:
				# se não encontrou alvo, manter cooldown em 0 para tentar novamente no próximo frame
				aoe.cooldown = 0.0
	
	# atualizar projéteis de canhão AOE
	var new_cannon_projectiles: Array = []
	for proj in aoe_cannon_projectiles:
		var dir = (proj.target - proj.pos).normalized()
		var dist_to_target = proj.pos.distance_to(proj.target)
		var move_dist = proj.speed * delta
		
		if move_dist >= dist_to_target:
			# projétil chegou ao alvo - criar explosão
			if effects_manager:
				effects_manager.create_aoe_effect(proj.target, proj.radius, 0.3)
			# Rastrear DPS da AOE tower
			var aoe_tower = proj.get("aoe_tower", null)
			var aoe_id = ""
			if aoe_tower != null:
				aoe_id = _get_tower_id(aoe_tower, "aoe")
				if not tower_dps_data.has(aoe_id):
					tower_dps_data[aoe_id] = {
						"dps": 0.0,
						"damage_dealt": 0.0,
						"shots": 0,
						"wave_damage": {},
						"tower_type": "aoe",
						"pos": aoe_tower.pos
					}
				tower_dps_data[aoe_id]["shots"] += 1
			
			# causar dano em área
			for e in enemies:
				if e["hp"] <= 0 or e["reached"]:
					continue
				var dist = proj.target.distance_to(e["pos"])
				if dist <= proj.radius:
					var damage_dealt = proj.damage
					e["hp"] -= damage_dealt
					
					# Rastrear dano para DPS
					if aoe_id != "" and tower_dps_data.has(aoe_id):
						tower_dps_data[aoe_id]["damage_dealt"] += damage_dealt
					
					_create_damage_number(e["pos"], damage_dealt, false)
					if e["hp"] <= 0:
						e["hp"] = 0
						e["dying"] = true
						e["dying_time"] = 0.0
						_create_death_animation(e["pos"])
						var is_boss = e.get("is_boss", false)
						hero["coins"] += get_boss_reward() if is_boss else get_enemy_reward()
						# chance de dropar moeda
						_try_drop_coin(e["pos"])
						_try_drop_talisman(e["pos"])
						# Rastrear achievements de kills
						_track_enemy_kill(is_boss)
		else:
			# mover projétil em direção ao alvo
			proj.pos += dir * move_dist
			new_cannon_projectiles.append(proj)
	aoe_cannon_projectiles = new_cannon_projectiles

func _update_sniper_towers(delta: float) -> void:
	if paused or game_over:
		return
	for sniper in sniper_towers:
		# aplicar boost de rate de boost towers próximos
		var sniper_rate_multiplier = 1.0
		for boost in boost_towers:
			var dist = sniper.pos.distance_to(boost.pos)
			if dist <= boost.range:
				sniper_rate_multiplier += boost.rate_boost
		
		# aplicar skill de boost de velocidade
		if skills_manager:
			sniper_rate_multiplier *= skills_manager.get_speed_multiplier()
		
		# Calcular effective_fire_rate respeitando o mínimo
		var effective_fire_rate = sniper.fire_rate / sniper_rate_multiplier
		effective_fire_rate = max(GameConstants.SNIPER_MIN_FIRE_RATE, effective_fire_rate)
		
		sniper.cooldown = max(0.0, sniper.cooldown - delta * sniper_rate_multiplier)
		if sniper.cooldown <= 0.0:
			var target_mode = sniper.get("target_mode", 0)  # 0 = Prioridade Boss, 1 = Mais próximo ao centro
			var target_enemy = null
			var target_dist = -1.0
			var base_center = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
			
			if target_mode == 0:
				# Modo Prioridade Boss: primeiro procura boss, se não encontrar, procura mais próximo ao centro
				var boss_found = false
				for e in enemies:
					if e["hp"] <= 0 or e["reached"]:
						continue
					if e.get("is_boss", false):
						var dist = sniper.pos.distance_to(e["pos"])
						if dist <= sniper.range:
							target_enemy = e
							boss_found = true
							break
				# Se não encontrou boss, procurar mais próximo ao centro
				if not boss_found:
					var closest_to_center = INF
					for e in enemies:
						if e["hp"] <= 0 or e["reached"]:
							continue
						var dist_to_sniper = sniper.pos.distance_to(e["pos"])
						if dist_to_sniper <= sniper.range:
							var dist_to_center = e["pos"].distance_to(base_center)
							if dist_to_center < closest_to_center:
								target_enemy = e
								closest_to_center = dist_to_center
								target_dist = dist_to_sniper
			else:
				# Modo Mais Próximo ao Centro: procurar inimigo mais próximo ao centro da base
				var closest_to_center = INF
				for e in enemies:
					if e["hp"] <= 0 or e["reached"]:
						continue
					var dist_to_sniper = sniper.pos.distance_to(e["pos"])
					var effective_range = get_effective_tower_range(sniper.range)
					if dist_to_sniper <= effective_range:
						var dist_to_center = e["pos"].distance_to(base_center)
						if dist_to_center < closest_to_center:
							target_enemy = e
							closest_to_center = dist_to_center
							target_dist = dist_to_sniper
			if target_enemy != null:
				# criar efeito visual de linha de tiro
				var dir = (target_enemy["pos"] - sniper.pos).normalized()
				var hit_pos = target_enemy["pos"]
				if effects_manager:
					effects_manager.create_sniper_effect(sniper.pos, hit_pos, 0.15)
				# causar dano com pierce - ordenar inimigos por distância ao longo da linha
				var enemies_in_line: Array = []
				for e in enemies:
					if e["hp"] <= 0 or e["reached"]:
						continue
					var dist_to_line = abs((e["pos"] - hit_pos).cross(dir))
					if dist_to_line < 20.0:  # dentro da linha de tiro
						var dist_along_line = (e["pos"] - sniper.pos).dot(dir)
						if dist_along_line > 0:  # à frente da torre
							enemies_in_line.append({"enemy": e, "dist": dist_along_line})
				# ordenar por distância
				enemies_in_line.sort_custom(func(a, b): return a.dist < b.dist)
				# aplicar bônus globais de dano
				var sniper_damage = sniper.damage * global_tower_damage_boost
				
				# aplicar boost de dano de boost towers próximos
				var damage_multiplier = 1.0
				for boost in boost_towers:
					var dist = sniper.pos.distance_to(boost.pos)
					if dist <= boost.range:
						damage_multiplier += boost.damage_boost
				sniper_damage *= damage_multiplier
				
				# aplicar skill de boost de dano
				if skills_manager:
					sniper_damage *= skills_manager.get_damage_multiplier()
				
				# Aplicar multiplicador de clima (depois de todos os outros multiplicadores)
				sniper_damage = get_effective_tower_damage(sniper_damage)
				
				# causar dano nos primeiros (pierce + 1) inimigos
				var pierce_count = sniper.pierce + 1  # pierce=1 significa atinge 2 inimigos
				# Rastrear DPS da sniper tower
				var sniper_id = _get_tower_id(sniper, "sniper")
				if not tower_dps_data.has(sniper_id):
					tower_dps_data[sniper_id] = {
						"dps": 0.0,
						"damage_dealt": 0.0,
						"shots": 0,
						"wave_damage": {},
						"tower_type": "sniper",
						"pos": sniper.pos
					}
				tower_dps_data[sniper_id]["shots"] += 1
				
				for i in range(min(pierce_count, enemies_in_line.size())):
					var e = enemies_in_line[i].enemy
					e["hp"] -= sniper_damage
					
					# Rastrear dano para DPS
					if tower_dps_data.has(sniper_id):
						tower_dps_data[sniper_id]["damage_dealt"] += sniper_damage
					
					_create_damage_number(e["pos"], sniper_damage, true)  # crítico para sniper
					if e["hp"] <= 0:
						e["hp"] = 0
						e["dying"] = true
						e["dying_time"] = 0.0
						_create_death_animation(e["pos"])
						var is_boss = e.get("is_boss", false)
						hero["coins"] += get_boss_reward() if is_boss else get_enemy_reward()
						# chance de dropar moeda
						_try_drop_coin(e["pos"])
						_try_drop_talisman(e["pos"])
						# Rastrear achievements de kills
						_track_enemy_kill(is_boss)
				# resetar cooldown apenas se encontrou alvo (usar effective_fire_rate)
				sniper.cooldown = effective_fire_rate
			else:
				# se não encontrou alvo, manter cooldown em 0 para tentar novamente no próximo frame
				sniper.cooldown = 0.0

func _update_boost_towers(_delta: float) -> void:
	# boost towers não precisam de atualização - o efeito é aplicado quando torres atiram
	pass

func _check_tower_combos() -> void:
	"""Verifica e atualiza combos de torres usando o ComboManager"""
	if not combo_manager:
		return
	
	combo_manager.check_tower_combos(
		towers,
		slow_towers,
		aoe_towers,
		sniper_towers,
		shock_towers,
		boost_towers,
		barracks,
		healing_stations,
		walls
	)

func _update_shock_towers(delta: float) -> void:
	for shock in shock_towers:
		# aplicar boost de rate de boost towers próximos
		var shock_rate_multiplier = 1.0
		for boost in boost_towers:
			var dist = shock.pos.distance_to(boost.pos)
			if dist <= boost.range:
				shock_rate_multiplier += boost.rate_boost
		
		# aplicar skill de boost de velocidade
		if skills_manager:
			shock_rate_multiplier *= skills_manager.get_speed_multiplier()
		
		# Calcular effective_fire_rate respeitando o mínimo
		var effective_fire_rate = shock.fire_rate / shock_rate_multiplier
		effective_fire_rate = max(GameConstants.SHOCK_MIN_FIRE_RATE, effective_fire_rate)
		
		shock.cooldown = max(0.0, shock.cooldown - delta * shock_rate_multiplier)
		if shock.cooldown <= 0.0:
			# Encontrar inimigo mais próximo
			var closest_enemy = null
			var effective_range = get_effective_tower_range(shock.range)
			var closest_dist = effective_range
			for e in enemies:
				if e["hp"] <= 0 or e["reached"] or e.get("dying", false):
					continue
				var dist = shock.pos.distance_to(e["pos"])
				if dist < closest_dist:
					closest_dist = dist
					closest_enemy = e
			
			if closest_enemy != null:
				# Aplicar choque em cadeia
				var chain_targets = [closest_enemy]
				var chain_count = shock.chain_count
				var last_target = closest_enemy
				
				# Encontrar próximos alvos para a cadeia
				for i in range(chain_count - 1):
					var next_target = null
					var next_dist = 100.0  # distância máxima entre alvos na cadeia
					for e in enemies:
						if e["hp"] <= 0 or e["reached"] or e.get("dying", false):
							continue
						if e in chain_targets:
							continue
						var dist = last_target["pos"].distance_to(e["pos"])
						if dist < next_dist:
							next_dist = dist
							next_target = e
					
					if next_target != null:
						chain_targets.append(next_target)
						last_target = next_target
					else:
						break
				
				# aplicar bônus globais de dano
				var shock_damage = shock.damage * global_tower_damage_boost
				# aplicar boost de dano de boost towers próximos
				var damage_multiplier = 1.0
				for boost in boost_towers:
					var dist = shock.pos.distance_to(boost.pos)
					if dist <= boost.range:
						damage_multiplier += boost.damage_boost
				shock_damage *= damage_multiplier
				
				# aplicar skill de boost de dano
				if skills_manager:
					shock_damage *= skills_manager.get_damage_multiplier()
				
				# Aplicar multiplicador de clima (depois de todos os outros multiplicadores)
				shock_damage = get_effective_tower_damage(shock_damage)
				
				# Rastrear DPS da shock tower
				var shock_id = _get_tower_id(shock, "shock")
				if not tower_dps_data.has(shock_id):
					tower_dps_data[shock_id] = {
						"dps": 0.0,
						"damage_dealt": 0.0,
						"shots": 0,
						"wave_damage": {},
						"tower_type": "shock",
						"pos": shock.pos
					}
				tower_dps_data[shock_id]["shots"] += 1
				
				# Aplicar dano a todos os alvos da cadeia
				for target in chain_targets:
					var damage_dealt = shock_damage
					target["hp"] -= damage_dealt
					
					# Rastrear dano para DPS
					if tower_dps_data.has(shock_id):
						tower_dps_data[shock_id]["damage_dealt"] += damage_dealt
					
					_create_damage_number(target["pos"], damage_dealt, false, Color(0.5, 0.8, 1.0))  # azul para choque
					if target["hp"] <= 0:
						target["hp"] = 0
						target["dying"] = true
						target["dying_time"] = 0.0
						_create_death_animation(target["pos"])
						var is_boss = target.get("is_boss", false)
						hero["coins"] += get_boss_reward() if is_boss else get_enemy_reward()
						_try_drop_coin(target["pos"])
						# Rastrear achievements de kills
						_track_enemy_kill(is_boss)
				
				# Criar efeito visual de choque (linhas entre alvos)
				if chain_targets.size() > 1:
					# Criar linha da torre até o primeiro inimigo
					_create_shock_effect(shock.pos, chain_targets[0]["pos"])
					# Criar linhas entre os inimigos
					for i in range(chain_targets.size() - 1):
						var start_pos = chain_targets[i]["pos"]
						var end_pos = chain_targets[i + 1]["pos"]
						_create_shock_effect(start_pos, end_pos)
				else:
					# Apenas um alvo, criar linha da torre até ele
					_create_shock_effect(shock.pos, chain_targets[0]["pos"])
				
				# resetar cooldown (usar effective_fire_rate)
				shock.cooldown = effective_fire_rate

func _create_shock_effect(start_pos: Vector2, end_pos: Vector2) -> void:
	# Criar efeito visual de choque elétrico (raio/trovão)
	var shock_effect = {
		"start": start_pos,
		"end": end_pos,
		"time": 0.0,
		"max_time": 0.15  # efeito rápido como um raio
	}
	# Usar VisualEffectsManager se disponível
	if visual_effects_manager:
		visual_effects_manager.create_shock_effect(start_pos, end_pos)
	else:
		shock_effects.append(shock_effect)

func _update_all_walls_max_hp() -> void:
	"""Atualiza o HP máximo de todas as muralhas baseado no multiplicador atual"""
	for w in walls:
		if w.has("upgrades"):
			var base_hp = GameConstants.WALL_BASE_HP * wall_hp_multiplier
			var upgrade_hp = w.upgrades.get("hp_level", 0) * GameConstants.WALL_UPGRADE_HP_AMOUNT
			var new_max_hp = base_hp + upgrade_hp
			var hp_ratio = w.hp / w.max_hp if w.max_hp > 0 else 1.0
			w.max_hp = new_max_hp
			w.hp = min(w.hp, new_max_hp)  # Manter proporção de HP se possível
			# Se a muralha estava destruída mas agora tem HP máximo maior, restaurar um pouco
			if w.hp <= 0 and new_max_hp > 0:
				w.hp = new_max_hp * 0.1  # Restaurar 10% do HP máximo

func _update_walls(delta: float) -> void:
	"""Atualiza muralhas: aplica dano de inimigos próximos e remove destruídas"""
	var walls_to_remove: Array = []
	var needs_path_recalc = false
	
	for i in range(walls.size()):
		var w = walls[i]
		if w.hp <= 0:
			walls_to_remove.append(i)
			needs_path_recalc = true
			continue
		
		# Verificar inimigos próximos causando dano
		for e in enemies:
			if e["hp"] <= 0 or e.get("reached", false):
				continue
			
			var dist = w.pos.distance_to(e["pos"])
			if dist < GameConstants.WALL_DAMAGE_RADIUS:
				# Calcular dano baseado no tipo de inimigo
				var damage_per_second = GameConstants.WALL_DAMAGE_PER_SECOND
				if e.get("is_boss", false):
					damage_per_second *= GameConstants.WALL_BOSS_DAMAGE_MULTIPLIER
				
				# Aplicar dano
				w.hp -= damage_per_second * delta
				
				# Criar efeito visual de dano (opcional - apenas ocasionalmente para não poluir a tela)
				if randf() < 0.05:  # 5% chance por frame para mostrar número de dano
					_create_damage_number(w.pos, damage_per_second * delta, false)
				
				if w.hp <= 0:
					# Muralha destruída
					if grid_manager.is_inside_base_point(w.pos):
						grid_manager.clear_grid_area(w.grid_x, w.grid_y, GameConstants.WALL_SIZE_GRID)
					else:
						var wall_tile = Vector2i(w.grid_x, w.grid_y)
						_unregister_wall_tile(wall_tile)
					pathfinder.invalidate_cache()
					walls_to_remove.append(i)
					needs_path_recalc = true
					break
	
	# Remover muralhas destruídas (em ordem reversa para manter índices corretos)
	walls_to_remove.reverse()
	for idx in walls_to_remove:
		if idx < walls.size():
			walls.remove_at(idx)
	
	# Recalcular caminhos apenas se necessário (otimização)
	if needs_path_recalc:
		pathfinder.set_wall_tiles(wall_tiles)
		_recalculate_all_enemy_paths()

func _update_healing_stations(_delta: float) -> void:
	# Healing stations não precisam de atualização contínua
	# A cura será aplicada no final da wave
	pass

func _update_soldiers(delta: float) -> void:
	var alive_soldiers: Array = []
	for s in soldiers:
		if s.hp <= 0:
			continue
		
		# encontrar inimigo pelo índice antigo ou procurar novo
		var target_enemy = null
		if s.target_enemy_idx >= 0 and s.target_enemy_idx < enemies.size():
			var enemy = enemies[s.target_enemy_idx]
			if enemy["hp"] > 0 and not enemy["reached"]:
				target_enemy = enemy
		
		if target_enemy == null:
			# procurar novo alvo
			s.target_enemy_idx = -1
			var closest_enemy_idx = -1
			var closest_dist = 9999.0
			for i in range(enemies.size()):
				var e = enemies[i]
				if e["hp"] <= 0 or e["reached"]:
					continue
				var dist = s.pos.distance_to(e["pos"])
				if dist < closest_dist:
					closest_dist = dist
					closest_enemy_idx = i
			if closest_enemy_idx >= 0:
				s.target_enemy_idx = closest_enemy_idx
				target_enemy = enemies[closest_enemy_idx]
			else:
				# não há inimigos, mas manter soldado vivo para quando aparecerem
				alive_soldiers.append(s)
				continue
		
		var dist_to_enemy = s.pos.distance_to(target_enemy["pos"])
		
		if not s.holding:
			# mover em direção ao inimigo
			if dist_to_enemy > s.radius + target_enemy["radius"]:
				var dir = (target_enemy["pos"] - s.pos).normalized()
				s.pos += dir * s.speed * delta
			else:
				# começou a segurar o inimigo
				s.holding = true
				s.hold_time = 0.0
		
		if s.holding:
			# verificar se o inimigo ainda existe e é válido antes de causar dano
			if target_enemy == null or target_enemy["hp"] <= 0 or target_enemy["reached"]:
				# inimigo não existe mais ou já foi morto - parar de segurar
				s.holding = false
				s.target_enemy_idx = -1
				alive_soldiers.append(s)
				continue
			
			s.hold_time += delta
			# aplicar dano ao inimigo enquanto segura
			var soldier_damage = s.damage * delta
			target_enemy["hp"] -= soldier_damage
			# Criar indicador de dano ocasionalmente (a cada 0.3s)
			if not s.has("last_damage_time"):
				s["last_damage_time"] = 0.0
			s["last_damage_time"] += delta
			if s["last_damage_time"] >= 0.3:
				_create_damage_number(target_enemy["pos"], soldier_damage * 3.0, false)
				s["last_damage_time"] = 0.0
			if target_enemy["hp"] <= 0:
				_create_death_animation(target_enemy["pos"])
				var is_boss = target_enemy.get("is_boss", false)
				# chefe dá 20x mais moedas (recompensas escaladas com wave)
				hero["coins"] += get_boss_reward() if is_boss else get_enemy_reward()
				# chance de dropar moeda
				_try_drop_coin(target_enemy["pos"])
				# Rastrear achievements de kills
				_track_enemy_kill(is_boss)
			
			# manter soldado na posição do inimigo
			s.pos = target_enemy["pos"]
			
			# verificar se acabou o tempo de segurar
			if s.hold_time >= s.max_hold_time:
				s.hp = 0  # soldado morre após segurar
		
		alive_soldiers.append(s)
	
	soldiers = alive_soldiers
	
	# limpar soldados mortos dos quartéis - sincronizar com lista global
	for b in barracks:
		var alive_barracks_soldiers: Array = []
		for s in b.soldiers:
			# verificar se o soldado ainda está na lista global de soldados vivos
			var found_in_global = false
			for global_s in soldiers:
				if global_s == s and global_s.hp > 0:
					found_in_global = true
					alive_barracks_soldiers.append(s)
					break
			# se não está na lista global mas ainda tem HP, manter
			if not found_in_global and s.hp > 0:
				alive_barracks_soldiers.append(s)
		b.soldiers = alive_barracks_soldiers

func _show_game_over_screen() -> void:
	"""Mostra a tela de Game Over com a imagem de fundo"""
	if has_node("CanvasLayer/GameOverOverlay"):
		var go = $CanvasLayer/GameOverOverlay
		go.visible = true
		go.get_node("Panel/LblWave").text = "Onda %d" % wave_manager.wave
		
		# Atualizar imagem de fundo se existir (tela toda, sem cortar)
		if has_node("CanvasLayer/GameOverOverlay/BackgroundImage") and tex_game_over != null:
			var bg = go.get_node("BackgroundImage")
			bg.texture = tex_game_over
			# Garantir que a imagem inteira fique visível sem cortar
			var viewport_size = get_viewport().get_visible_rect().size
			bg.set_anchors_preset(Control.PRESET_FULL_RECT)
			bg.size = viewport_size
			bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED  # Não cortar a imagem
		
		# Ajustar posição do Panel para ficar mais centralizado e maior
		var panel = go.get_node("Panel")
		var viewport_size = get_viewport().get_visible_rect().size
		var panel_width = 500
		var panel_height = 200
		panel.position = Vector2(
			(viewport_size.x - panel_width) / 2,
			viewport_size.y * 0.65  # Mais para baixo para não cobrir a imagem
		)
		panel.size = Vector2(panel_width, panel_height)
		
		# Ajustar posições dos elementos dentro do Panel
		var lbl_wave = go.get_node("Panel/LblWave")
		lbl_wave.position = Vector2((panel_width - 400) / 2, 30)
		lbl_wave.size = Vector2(400, 40)
		
		var btn_restart = go.get_node("Panel/BtnRestart")
		var btn_menu = go.get_node("Panel/BtnMenu")
		var btn_width = 200
		var btn_height = 45
		var btn_spacing = 30
		var total_btn_width = btn_width * 2 + btn_spacing
		var btn_start_x = (panel_width - total_btn_width) / 2
		
		btn_restart.position = Vector2(btn_start_x, 100)
		btn_restart.size = Vector2(btn_width, btn_height)
		
		btn_menu.position = Vector2(btn_start_x + btn_width + btn_spacing, 100)
		btn_menu.size = Vector2(btn_width, btn_height)

func _on_game_over_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")

func _on_game_over_restart() -> void:
	get_tree().reload_current_scene()

# ==================== FUNÇÕES DE PAUSE/SAVE/LOAD ====================

func _pause_game() -> void:
	paused = true
	pause_overlay.visible = true
	get_tree().paused = false  # Não usar pause do tree para permitir UI funcionar

func _unpause_game() -> void:
	paused = false
	pause_overlay.visible = false
	save_status_label.visible = false

func _on_pause_resume() -> void:
	_unpause_game()

func _on_pause_save() -> void:
	_show_save_slot_dialog()

func _show_save_slot_dialog() -> void:
	# Criar diálogo de seleção de slot para salvar
	var dialog = Window.new()
	dialog.title = "Salvar Jogo"
	dialog.size = Vector2(520, 450)
	dialog.min_size = Vector2(500, 400)
	dialog.always_on_top = true
	dialog.transient = true
	
	# Container principal
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	
	# ScrollContainer para lista de slots
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(480, 300)
	
	var slot_list = VBoxContainer.new()
	slot_list.add_theme_constant_override("separation", 5)
	scroll.add_child(slot_list)
	vbox.add_child(scroll)
	
	# Criar botões para slots (1 a MAX_SLOTS)
	for i in range(1, SaveManager.MAX_SLOTS + 1):
		var slot_name = "slot%d" % i
		var slot_info = SaveManager.get_save_info(slot_name)
		var has_save = not slot_info.is_empty()
		
		var slot_button = Button.new()
		slot_button.custom_minimum_size = Vector2(460, 60)
		slot_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		var button_text = "Posição %d" % i
		if has_save:
			var wave = slot_info.get("wave", 0)
			var coins = slot_info.get("coins", 0)
			var save_time = slot_info.get("save_time", "Desconhecido")
			button_text = "Posição %d (Onda: %d | Moedas: %d)\n%s" % [i, wave, coins, save_time]
		else:
			button_text = "Posição %d (Vazio)" % i
		
		slot_button.text = button_text
		
		# Estilizar botão
		var slot_style = StyleBoxFlat.new()
		if has_save:
			slot_style.bg_color = Color(0.25, 0.3, 0.35, 1.0)
		else:
			slot_style.bg_color = Color(0.2, 0.2, 0.25, 1.0)
		slot_style.corner_radius_top_left = 5
		slot_style.corner_radius_top_right = 5
		slot_style.corner_radius_bottom_left = 5
		slot_style.corner_radius_bottom_right = 5
		slot_style.border_width_left = 1
		slot_style.border_width_top = 1
		slot_style.border_width_right = 1
		slot_style.border_width_bottom = 1
		slot_style.border_color = Color(0.4, 0.5, 0.6, 1.0)
		slot_button.add_theme_stylebox_override("normal", slot_style)
		
		var slot_hover_style = slot_style.duplicate()
		slot_hover_style.bg_color = Color(0.35, 0.4, 0.45, 1.0)
		slot_button.add_theme_stylebox_override("hover", slot_hover_style)
		
		# Conectar sinal
		slot_button.pressed.connect(func(): _save_to_slot(slot_name, dialog))
		
		slot_list.add_child(slot_button)
	
	# Botão cancelar
	var cancel_button = Button.new()
	cancel_button.text = "Cancelar"
	cancel_button.custom_minimum_size = Vector2(480, 40)
	cancel_button.pressed.connect(func(): dialog.queue_free())
	vbox.add_child(cancel_button)
	
	dialog.add_child(vbox)
	get_tree().root.add_child(dialog)
	
	# Ajustar layout do vbox
	await get_tree().process_frame
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.set_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Centralizar janela
	var screen_size = DisplayServer.screen_get_size()
	var window_size = dialog.size
	dialog.position = (screen_size - window_size) / 2
	dialog.show()

func _save_to_slot(slot_name: String, dialog: Window) -> void:
	if SaveManager.save_game(self, slot_name):
		save_status_label.text = "Jogo salvo com sucesso no %s!" % slot_name
		save_status_label.modulate = Color(0.2, 1.0, 0.2)  # Verde
		# Achievement: salvar jogo
		achievement_manager.increment_progress("save_game")
		save_status_label.visible = true
		dialog.queue_free()
		await get_tree().create_timer(2.0).timeout
		save_status_label.visible = false
	else:
		save_status_label.text = "Erro ao salvar jogo!"
		save_status_label.modulate = Color(1.0, 0.2, 0.2)  # Vermelho
		save_status_label.visible = true
		dialog.queue_free()
		await get_tree().create_timer(2.0).timeout
		save_status_label.visible = false

func _on_pause_load() -> void:
	_show_load_slot_dialog()

func _show_load_slot_dialog() -> void:
	# Criar diálogo de seleção de slot para carregar
	var dialog = Window.new()
	dialog.title = "Carregar Jogo"
	dialog.size = Vector2(520, 450)
	dialog.min_size = Vector2(500, 400)
	dialog.always_on_top = true
	dialog.transient = true
	
	# Container principal
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	
	# ScrollContainer para lista de slots
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(480, 300)
	
	var slot_list = VBoxContainer.new()
	slot_list.add_theme_constant_override("separation", 5)
	scroll.add_child(slot_list)
	vbox.add_child(scroll)
	
	# Obter slots disponíveis
	var available_slots = SaveManager.list_available_slots()
	
	if available_slots.is_empty():
		var no_saves_label = Label.new()
		no_saves_label.text = "Nenhum save encontrado!"
		no_saves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_list.add_child(no_saves_label)
	else:
		# Criar botão para cada slot disponível
		for slot_info in available_slots:
			var slot_button = Button.new()
			slot_button.custom_minimum_size = Vector2(460, 60)
			slot_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			
			var slot_name = slot_info.get("slot_name", "Desconhecido")
			var wave = slot_info.get("wave", 0)
			var coins = slot_info.get("coins", 0)
			var base_hp = slot_info.get("base_hp", GameConstants.HERO_BASE_HP)
			var save_time = slot_info.get("save_time", "Desconhecido")
			var is_autosave = slot_info.get("is_autosave", false)
			
			# Formatar nome do slot
			var display_name = ""
			if is_autosave:
				display_name = "Salvamento Automático"
			elif slot_name.begins_with("slot"):
				var slot_num = slot_name.substr(4)
				display_name = "Slot %s" % slot_num
			else:
				display_name = slot_name
			
			# Texto do botão
			var button_text = "%s\nOnda: %d | Moedas: %d | Vida: %d\n%s" % [display_name, wave, coins, base_hp, save_time]
			slot_button.text = button_text
			
			# Estilizar botão
			var slot_style = StyleBoxFlat.new()
			slot_style.bg_color = Color(0.25, 0.3, 0.35, 1.0)
			slot_style.corner_radius_top_left = 5
			slot_style.corner_radius_top_right = 5
			slot_style.corner_radius_bottom_left = 5
			slot_style.corner_radius_bottom_right = 5
			slot_style.border_width_left = 1
			slot_style.border_width_top = 1
			slot_style.border_width_right = 1
			slot_style.border_width_bottom = 1
			slot_style.border_color = Color(0.4, 0.5, 0.6, 1.0)
			slot_button.add_theme_stylebox_override("normal", slot_style)
			
			var slot_hover_style = slot_style.duplicate()
			slot_hover_style.bg_color = Color(0.35, 0.4, 0.45, 1.0)
			slot_button.add_theme_stylebox_override("hover", slot_hover_style)
			
			# Conectar sinal
			slot_button.pressed.connect(func(): _load_from_slot(slot_name, dialog))
			
			slot_list.add_child(slot_button)
	
	# Botão cancelar
	var cancel_button = Button.new()
	cancel_button.text = "Cancelar"
	cancel_button.custom_minimum_size = Vector2(480, 40)
	cancel_button.pressed.connect(func(): dialog.queue_free())
	vbox.add_child(cancel_button)
	
	dialog.add_child(vbox)
	get_tree().root.add_child(dialog)
	
	# Ajustar layout do vbox
	await get_tree().process_frame
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.set_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Centralizar janela
	var screen_size = DisplayServer.screen_get_size()
	var window_size = dialog.size
	dialog.position = (screen_size - window_size) / 2
	dialog.show()

func _load_from_slot(slot_name: String, dialog: Window) -> void:
	if SaveManager.has_save(slot_name):
		if SaveManager.load_game(self, slot_name):
			_apply_loaded_game_state()
			save_status_label.text = "Jogo carregado com sucesso do %s!" % slot_name
			save_status_label.modulate = Color(0.2, 1.0, 0.2)  # Verde
			save_status_label.visible = true
			dialog.queue_free()
			_unpause_game()
			await get_tree().create_timer(2.0).timeout
			save_status_label.visible = false
		else:
			save_status_label.text = "Erro ao carregar jogo!"
			save_status_label.modulate = Color(1.0, 0.2, 0.2)  # Vermelho
			save_status_label.visible = true
			dialog.queue_free()
			await get_tree().create_timer(2.0).timeout
			save_status_label.visible = false
	else:
		save_status_label.text = "Posição não encontrada!"
		save_status_label.modulate = Color(1.0, 0.8, 0.2)  # Amarelo
		save_status_label.visible = true
		dialog.queue_free()
		await get_tree().create_timer(2.0).timeout
		save_status_label.visible = false

func _on_pause_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")

func _on_pause_quit() -> void:
	get_tree().quit()

# Auto-save após cada wave
func _auto_save_after_wave() -> void:
	SaveManager.auto_save(self)
	print("Auto-save realizado após wave ", wave_manager.wave)

func _apply_loaded_game_state() -> void:
	_rebuild_base_grid_from_structures()
	_rebuild_mine_tiles()
	pathfinder.invalidate_cache()
	_reset_build_and_selection_state()

func _rebuild_base_grid_from_structures() -> void:
	if grid_manager == null:
		return
	grid_manager.reset_base_grid()
	_occupy_structures_in_grid(towers, GameConstants.TOWER_SIZE_GRID, 1)
	_occupy_structures_in_grid(barracks, GameConstants.BARRACKS_SIZE_GRID, 3)
	_occupy_structures_in_grid(slow_towers, GameConstants.SLOW_TOWER_SIZE_GRID, 5)
	_occupy_structures_in_grid(aoe_towers, GameConstants.AOE_TOWER_SIZE_GRID, 6)
	_occupy_structures_in_grid(sniper_towers, GameConstants.SNIPER_TOWER_SIZE_GRID, 7)
	_occupy_structures_in_grid(boost_towers, GameConstants.BOOST_TOWER_SIZE_GRID, 8)
	_occupy_structures_in_grid(shock_towers, GameConstants.SHOCK_TOWER_SIZE_GRID, 9)
	_occupy_structures_in_grid(walls, GameConstants.WALL_SIZE_GRID, 9)
	_occupy_structures_in_grid(healing_stations, GameConstants.HEALING_STATION_SIZE_GRID, 10)

func _occupy_structures_in_grid(structures: Array, size: int, item_type: int) -> void:
	for data in structures:
		if data is Dictionary and data.has("grid_x") and data.has("grid_y"):
			var gx = int(data["grid_x"])
			var gy = int(data["grid_y"])
			grid_manager.set_grid_area(gx, gy, size, item_type)

func _reset_build_and_selection_state() -> void:
	placing_tower = false
	placing_barracks = false
	placing_mine = false
	placing_slow_tower = false
	placing_aoe_tower = false
	placing_sniper_tower = false
	placing_boost_tower = false
	placing_shock_tower = false
	placing_wall = false
	placing_healing_station = false
	dragging_tower = false
	tower_selected_index = -1
	barracks_selected_index = -1
	sniper_selected_index = -1
	aoe_selected_index = -1
	shock_selected_index = -1
	slow_selected_index = -1
	boost_selected_index = -1
	if tower_menu:
		tower_menu.hide()
	if barracks_menu:
		barracks_menu.hide()
	if sniper_menu:
		sniper_menu.hide()
	if aoe_menu:
		aoe_menu.hide()
	if shock_menu:
		shock_menu.hide()
	if slow_menu:
		slow_menu.hide()
	if boost_menu:
		boost_menu.hide()
	_hide_range_indicator()

func _try_drop_coin(pos: Vector2) -> void:
	if coin_manager:
		coin_manager.try_drop_coin(pos)

func _try_drop_special_currency(pos: Vector2, is_boss: bool) -> void:
	"""Tenta dropar moedas especiais (esmeraldas/diamantes) em waves altas"""
	if not special_currency_manager or not wave_manager:
		return
	
	var current_wave = wave_manager.wave
	
	# Bosses especiais (a cada 25 waves) dão esmeralda garantida
	if is_boss and special_currency_manager.is_special_boss_wave(current_wave):
		special_currency_manager.add_emeralds(GameConstants.BOSS_EMERALD_REWARD_COUNT, "boss_special")
		_create_special_currency_notification(pos, "emerald", GameConstants.BOSS_EMERALD_REWARD_COUNT)
		return
	
	# Drops aleatórios em waves altas
	if special_currency_manager.should_drop_emerald(current_wave):
		special_currency_manager.add_emeralds(1, "enemy_drop")
		_create_special_currency_notification(pos, "emerald", 1)
	
	if special_currency_manager.should_drop_diamond(current_wave):
		special_currency_manager.add_diamonds(1, "enemy_drop")
		_create_special_currency_notification(pos, "diamond", 1)

func _create_special_currency_notification(pos: Vector2, currency_type: String, amount: int) -> void:
	"""Cria notificação visual de moeda especial coletada"""
	# Por enquanto, apenas print. Pode ser expandido com efeitos visuais
	var icon = "🟢" if currency_type == "emerald" else "💎"
	print("%s +%d %s" % [icon, amount, currency_type])

func _load_pending_quest_rewards() -> void:
	"""Carrega e aplica recompensas pendentes de quests do Menu"""
	if not special_currency_manager:
		return
	
	var config = ConfigFile.new()
	var config_path = "user://pending_quest_rewards.cfg"
	
	if config.load(config_path) == OK:
		var pending_emeralds = config.get_value("rewards", "emeralds", 0)
		var pending_diamonds = config.get_value("rewards", "diamonds", 0)
		
		if pending_emeralds > 0:
			special_currency_manager.add_emeralds(pending_emeralds, "quest")
		if pending_diamonds > 0:
			special_currency_manager.add_diamonds(pending_diamonds, "quest")
		
		# Limpar arquivo após aplicar
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("pending_quest_rewards.cfg")

func _apply_prestige_bonuses() -> void:
	"""Aplica bônus permanentes de prestígio"""
	if not prestige_shop:
		return
	
	# Resetar valores para base antes de aplicar bônus
	hero["damage"] = hero_damage_base
	hero["fire_rate"] = hero_fire_rate_base
	hero["crit_chance"] = hero_crit_chance_base
	base_hp = base_hp_base
	base_hp_max = base_hp_base  # Resetar HP máximo também
	global_tower_damage_boost = global_tower_damage_boost_base
	coin_drop_chance = coin_drop_chance_base
	
	# Aplicar bônus de moedas iniciais
	var start_coins_bonus = prestige_shop.get_start_coins_bonus()
	if start_coins_bonus > 0:
		hero["coins"] += start_coins_bonus
	
	# Aplicar bônus de dano do herói
	var hero_damage_bonus = prestige_shop.get_hero_damage_bonus()
	if hero_damage_bonus > 0:
		hero["damage"] *= (1.0 + hero_damage_bonus)
	
	# Aplicar bônus de velocidade de tiro
	var hero_firerate_bonus = prestige_shop.get_hero_firerate_bonus()
	if hero_firerate_bonus > 0:
		hero["fire_rate"] *= (1.0 - hero_firerate_bonus)  # Reduz fire_rate = mais rápido
		hero["fire_rate"] = max(0.1, hero["fire_rate"])  # Limitar mínimo
	
	# Aplicar bônus de HP da base
	var base_hp_bonus = prestige_shop.get_base_hp_bonus()
	if base_hp_bonus > 0:
		base_hp += base_hp_bonus
		base_hp_max += base_hp_bonus
	
	# Aplicar boost de HP da base
	var base_hp_boost = prestige_shop.get_base_hp_boost()
	if base_hp_boost > 0:
		base_hp += base_hp_boost
		base_hp_max += base_hp_boost
	
	# Aplicar boost de dano do herói
	var hero_damage_boost = prestige_shop.get_hero_damage_boost()
	if hero_damage_boost > 0:
		hero["damage"] *= (1.0 + hero_damage_boost)
	
	# Aplicar boost de chance de drop de moedas
	var coin_drop_boost = prestige_shop.get_coin_drop_boost()
	if coin_drop_boost > 0:
		coin_drop_chance += coin_drop_boost
		coin_drop_chance = min(coin_drop_chance, 1.0)
	
	# Aplicar boost de moedas iniciais
	var starting_coins_boost = prestige_shop.get_starting_coins_boost()
	if starting_coins_boost > 0:
		hero["coins"] += starting_coins_boost
	
	# Aplicar multiplicador de recompensas (será usado no RewardCalculator)
	var reward_mult = prestige_shop.get_reward_multiplier()
	if reward_mult > 1.0:
		global_tower_damage_boost *= reward_mult  # Aplicar multiplicador global
	
	# Aplicar bônus de prestígio acumulado
	var prestige_bonus = prestige_shop.get_prestige_bonus()
	if prestige_bonus.coins_multiplier > 1.0:
		# Multiplicador será aplicado nas recompensas
		pass  # Pode ser aplicado no RewardCalculator

func _try_drop_talisman(pos: Vector2) -> void:
	"""Tenta dropar um talismã na posição especificada"""
	if not item_manager:
		return
	
	# Verificar chance de drop
	var drop_chance = GameConstants.TALISMAN_DROP_CHANCE
	if randf() < drop_chance:
		# Determinar raridade (raridade aumenta conforme o valor do roll)
		# Distribuição: Common (50%) > Uncommon (30%) > Rare (15%) > Epic (4%) > Legendary (1%)
		var rarity_roll = randf()
		var rarity: EquippableItem.ItemRarity
		if rarity_roll < 0.50:  # 50% - Common (mais comum)
			rarity = EquippableItem.ItemRarity.COMMON
		elif rarity_roll < 0.80:  # 30% - Uncommon
			rarity = EquippableItem.ItemRarity.UNCOMMON
		elif rarity_roll < 0.95:  # 15% - Rare
			rarity = EquippableItem.ItemRarity.RARE
		elif rarity_roll < 0.99:  # 4% - Epic (raro)
			rarity = EquippableItem.ItemRarity.EPIC
		else:  # 1% - Legendary (muito raro)
			rarity = EquippableItem.ItemRarity.LEGENDARY
		
		# Criar talismã aleatório
		var talisman = Talisman.create_random(rarity)
		
		# Adicionar como drop visual (não direto ao inventário)
		dropped_talismans.append({
			"pos": pos,
			"talisman": talisman,
			"lifetime": 0.0,
			"max_lifetime": GameConstants.TALISMAN_LIFETIME,
			"collected": false
		})

func _update_dropped_talismans(delta: float) -> void:
	"""Atualiza talismãs dropados (lifetime e coleta)"""
	var new_talismans: Array = []
	for talisman_drop in dropped_talismans:
		if talisman_drop.collected:
			continue
		talisman_drop.lifetime += delta
		if talisman_drop.lifetime < talisman_drop.max_lifetime:
			new_talismans.append(talisman_drop)
	dropped_talismans = new_talismans

func _try_collect_talisman(world_pos: Vector2) -> bool:
	"""Tenta coletar um talismã próximo à posição do mundo. Retorna true se coletou."""
	if not item_manager:
		return false
	
	for talisman_drop in dropped_talismans:
		if talisman_drop.collected:
			continue
		
		var dist = world_pos.distance_to(talisman_drop.pos)
		if dist < GameConstants.TALISMAN_COLLECT_RADIUS:
			talisman_drop.collected = true
			# Adicionar ao inventário
			item_manager.add_item(talisman_drop.talisman)
			# Criar efeito visual de coleta
			if effects_manager:
				effects_manager.create_coin_collect_effect(talisman_drop.pos)
			return true
	
	return false

func _create_loading_screen() -> void:
	# Criar tela de carregamento
	loading_screen = Control.new()
	loading_screen.name = "LoadingScreen"
	loading_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Fundo escuro
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.1, 1.0)
	loading_screen.add_child(bg)
	
	# Container central - usando CenterContainer para centralizar automaticamente
	var outer_center = CenterContainer.new()
	outer_center.name = "OuterCenterContainer"
	outer_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_screen.add_child(outer_center)
	
	var center_container = VBoxContainer.new()
	center_container.name = "CenterContainer"
	center_container.add_theme_constant_override("separation", 20)
	outer_center.add_child(center_container)
	
	# Label de carregamento
	var loading_label = Label.new()
	loading_label.name = "LoadingLabel"
	loading_label.text = "Carregando..."
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.add_theme_font_size_override("font_size", 32)
	loading_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	center_container.add_child(loading_label)
	
	# Barra de progresso (simulada com Label)
	var progress_label = Label.new()
	progress_label.name = "ProgressLabel"
	progress_label.text = "0%"
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 24)
	progress_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	center_container.add_child(progress_label)
	
	# Barra de progresso visual
	var progress_bar_bg = ColorRect.new()
	progress_bar_bg.name = "ProgressBarBG"
	progress_bar_bg.custom_minimum_size = Vector2(400, 20)
	progress_bar_bg.color = Color(0.2, 0.2, 0.3, 1.0)
	center_container.add_child(progress_bar_bg)
	
	var progress_bar = ColorRect.new()
	progress_bar.name = "ProgressBar"
	progress_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	progress_bar.anchor_left = 0.0
	progress_bar.anchor_right = 0.0
	progress_bar.offset_right = 0.0
	progress_bar.color = Color(1.0, 0.9, 0.2, 1.0)  # Amarelo/dourado
	progress_bar_bg.add_child(progress_bar)
	
	# Adicionar ao CanvasLayer
	$CanvasLayer.add_child(loading_screen)
	loading_screen.z_index = 1000  # Garantir que fique por cima de tudo

func _update_loading_progress(progress: float) -> void:
	loading_progress = progress
	if loading_screen != null:
		var progress_label = loading_screen.get_node_or_null("OuterCenterContainer/CenterContainer/ProgressLabel")
		var progress_bar = loading_screen.get_node_or_null("OuterCenterContainer/CenterContainer/ProgressBarBG/ProgressBar")
		
		if progress_label:
			progress_label.text = "%d%%" % int(progress * 100)
		
		if progress_bar:
			progress_bar.anchor_right = progress
			progress_bar.offset_right = 0
	
	# Forçar atualização visual
	if loading_screen:
		loading_screen.queue_redraw()
	
	# Aguardar um frame para atualizar visualmente
	await get_tree().process_frame

func _hide_loading_screen() -> void:
	if loading_screen != null:
		is_loading = false
		# Fade out suave
		var tween = create_tween()
		tween.tween_property(loading_screen, "modulate:a", 0.0, 0.3)
		await tween.finished
		loading_screen.queue_free()
		loading_screen = null

func _create_coin_collect_effect(pos: Vector2) -> void:
	if effects_manager:
		effects_manager.create_coin_collect_effect(pos)

func _play_coin_sound() -> void:
	# Tocar som de coleta de moeda usando pool de players para evitar sobreposição
	# Usar som pré-carregado do ResourceManager
	var coin_sound = resource_manager.get_audio_stream("coin_collect")
	if coin_sound == null:
		# Fallback para carregamento dinâmico se não foi pré-carregado
		coin_sound = _try_load_music("res://assets/sounds/coin_collect.ogg")
		if coin_sound == null:
			coin_sound = _try_load_music("res://assets/sounds/coin_collect.mp3")
		if coin_sound == null:
			coin_sound = _try_load_music("res://assets/sounds/coin_collect.wav")
		if coin_sound == null:
			return  # Sem som disponível
	
	# Encontrar um player disponível ou criar um novo
	var available_player: AudioStreamPlayer = null
	for player in coin_sound_players:
		if not player.playing:
			available_player = player
			break
	
	# Se não houver player disponível e ainda não atingiu o limite, criar um novo
	if available_player == null and coin_sound_players.size() < GameConstants.UI_MAX_COIN_SOUND_PLAYERS:
		available_player = AudioStreamPlayer.new()
		available_player.name = "CoinSoundPlayer_%d" % coin_sound_players.size()
		available_player.volume_db = 0.0
		add_child(available_player)
		coin_sound_players.append(available_player)
	
	# Se encontrou um player disponível, tocar o som
	if available_player != null:
		available_player.stream = coin_sound
		available_player.play()

func _create_damage_number(pos: Vector2, damage: float, is_crit: bool = false, color: Color = Color.WHITE) -> void:
	# Criar indicador de dano flutuante
	var damage_num = {
		"pos": pos + Vector2(randf_range(-10, 10), randf_range(-5, 5)),  # pequeno offset aleatório
		"value": damage,
		"time": 0.0,
		"max_time": 1.0,  # 1 segundo de duração
		"is_crit": is_crit,
		"color": color if color != Color.WHITE else (Color(1.0, 0.8, 0.2) if is_crit else Color(1.0, 0.3, 0.3)),
		"velocity": Vector2(randf_range(-30, 30), -50.0)  # movimento para cima com pequeno desvio horizontal
	}
	# Usar VisualEffectsManager se disponível
	if visual_effects_manager:
		visual_effects_manager.create_damage_number(pos, damage, is_crit, color)
	else:
		damage_numbers.append(damage_num)

func _create_tower_shop_ui() -> void:
	# Criar painel lateral para loja de torres
	var canvas = $CanvasLayer
	var hud = canvas.get_node("HUD")
	
	# Remover menu antigo se existir
	if hud.has_node("TowerShopPanel"):
		hud.get_node("TowerShopPanel").queue_free()
	
	# Criar painel lateral
	tower_shop_panel = Panel.new()
	tower_shop_panel.name = "TowerShopPanel"
	tower_shop_panel.z_index = 0  # Garantir que fique atrás da HUD
	hud.add_child(tower_shop_panel)
	
	# Configurar posição e tamanho do painel (lado direito da tela)
	var screen_width = get_viewport().get_visible_rect().size.x
	var screen_height = get_viewport().get_visible_rect().size.y
	var panel_width = 380.0  # largura ligeiramente maior para acomodar o card do herói
	var hero_card_height = 100
	var panel_height = screen_height - 44.0
	tower_shop_panel.position = Vector2(screen_width - panel_width, 44.0)
	tower_shop_panel.size = Vector2(panel_width, panel_height)
	
	# Estilizar o painel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	style_box.border_color = Color(0.3, 0.3, 0.4)
	style_box.border_width_left = 2
	style_box.border_width_top = 0
	style_box.border_width_right = 0
	style_box.border_width_bottom = 0
	tower_shop_panel.add_theme_stylebox_override("panel", style_box)
	
	# Container para título com botão de toggle
	var title_container = HBoxContainer.new()
	title_container.name = "TitleContainer"
	title_container.position = Vector2(10, 10)
	title_container.size = Vector2(panel_width - 20, 30)
	tower_shop_panel.add_child(title_container)
	
	# Título do painel
	var title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "LOJA DE TORRES"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_container.add_child(title_label)
	
	# Botão de toggle para colapsar/expandir (melhorado e estilizado)
	tower_shop_toggle_button = Button.new()
	tower_shop_toggle_button.name = "ToggleButton"
	tower_shop_toggle_button.text = "►"  # Quando expandido, mostra seta para direita (colapsar)
	tower_shop_toggle_button.custom_minimum_size = Vector2(22, 22)  # Menor para caber melhor
	tower_shop_toggle_button.pressed.connect(_toggle_tower_shop)
	var toggle_style = StyleBoxFlat.new()
	toggle_style.bg_color = Color(0.2, 0.4, 0.6, 0.9)  # Azul mais bonito
	toggle_style.border_color = Color(0.3, 0.5, 0.7, 1.0)
	toggle_style.border_width_left = 2
	toggle_style.border_width_top = 2
	toggle_style.border_width_right = 2
	toggle_style.border_width_bottom = 2
	toggle_style.corner_radius_top_left = 4
	toggle_style.corner_radius_top_right = 4
	toggle_style.corner_radius_bottom_left = 4
	toggle_style.corner_radius_bottom_right = 4
	var toggle_hover_style = StyleBoxFlat.new()
	toggle_hover_style.bg_color = Color(0.3, 0.5, 0.7, 0.95)
	toggle_hover_style.border_color = Color(0.4, 0.6, 0.8, 1.0)
	toggle_hover_style.border_width_left = 2
	toggle_hover_style.border_width_top = 2
	toggle_hover_style.border_width_right = 2
	toggle_hover_style.border_width_bottom = 2
	toggle_hover_style.corner_radius_top_left = 4
	toggle_hover_style.corner_radius_top_right = 4
	toggle_hover_style.corner_radius_bottom_left = 4
	toggle_hover_style.corner_radius_bottom_right = 4
	tower_shop_toggle_button.add_theme_stylebox_override("normal", toggle_style)
	tower_shop_toggle_button.add_theme_stylebox_override("hover", toggle_hover_style)
	tower_shop_toggle_button.add_theme_font_size_override("font_size", 14)
	tower_shop_toggle_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	title_container.add_child(tower_shop_toggle_button)
	
	# Container para botões de torres (sem scroll - tamanho fixo para mostrar tudo)
	var scroll = ScrollContainer.new()
	scroll.name = "TowerScroll"
	scroll.position = Vector2(10, 45)
	scroll.size = Vector2(panel_width - 20, panel_height - 45)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tower_shop_panel.add_child(scroll)
	
	# Armazenar referência para poder esconder/mostrar
	tower_shop_panel.set_meta("scroll_container", scroll)
	
	var vbox = VBoxContainer.new()
	vbox.name = "TowerButtonsContainer"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 5)
	scroll.add_child(vbox)
	
	# Card da base/Herói
	_create_hero_home_card(vbox, hero_card_height)
	
	# Lista de torres com informações (Mina movida para o final)
	var tower_data = [
		{"name": "Torre Básica", "cost": GameConstants.TOWER_COST, "icon": tex_tower, "func": "_on_buy_tower", "max": GameConstants.MAX_TOWERS, "array_name": "towers"},
		{"name": "Quartel", "cost": GameConstants.BARRACKS_COST, "icon": tex_barracks, "func": "_on_buy_barracks", "max": GameConstants.MAX_BARRACKS, "array_name": "barracks"},
		{"name": "Torre de Congelamento", "cost": GameConstants.SLOW_TOWER_COST, "icon": tex_slow_tower, "func": "_on_buy_slow_tower", "max": GameConstants.MAX_SLOW_TOWERS, "array_name": "slow_towers"},
		{"name": "Canhão", "cost": GameConstants.AOE_TOWER_COST, "icon": tex_aoe_tower, "func": "_on_buy_aoe_tower", "max": GameConstants.MAX_AOE_TOWERS, "array_name": "aoe_towers"},
		{"name": "Torre Sniper", "cost": GameConstants.SNIPER_TOWER_COST, "icon": tex_sniper_tower, "func": "_on_buy_sniper_tower", "max": GameConstants.MAX_SNIPER_TOWERS, "array_name": "sniper_towers"},
		{"name": "Altar de Melhoria", "cost": GameConstants.BOOST_TOWER_COST, "icon": tex_boost_tower, "func": "_on_buy_boost_tower", "max": GameConstants.MAX_BOOST_TOWERS, "array_name": "boost_towers"},
		{"name": "Torre de Choque", "cost": GameConstants.SHOCK_TOWER_COST, "icon": tex_shock_tower, "func": "_on_buy_shock_tower", "max": GameConstants.MAX_SHOCK_TOWERS, "array_name": "shock_towers"},
		{"name": "Muralha", "cost": 100, "icon": tex_wall_structure, "func": "_on_buy_wall", "max": GameConstants.MAX_WALLS, "array_name": "walls"},  # Custo será atualizado dinamicamente por get_wall_cost()
		{"name": "Estação de Cura", "cost": GameConstants.HEALING_STATION_COST, "icon": tex_healing_station, "func": "_on_buy_healing_station", "max": GameConstants.MAX_HEALING_STATIONS, "array_name": "healing_stations"},
		{"name": "Mina", "cost": GameConstants.MINE_COST, "icon": tex_mine, "func": "_on_buy_mine", "max": GameConstants.MAX_MINES, "array_name": "mines"},
		{"name": "Mercado de Esmeraldas", "cost": GameConstants.MARKET_COST_EMERALDS, "icon": tex_market, "func": "_on_buy_market", "max": GameConstants.MAX_MARKETS, "array_name": "markets", "cost_type": "emeralds"},
	]
	
	# Criar botões para cada torre
	for tower_info in tower_data:
		var btn_container = PanelContainer.new()
		btn_container.custom_minimum_size = Vector2(panel_width - 20, 80)
		
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.2, 0.2, 0.25, 0.8)
		btn_style.border_color = Color(0.4, 0.4, 0.5)
		btn_style.border_width_left = 1
		btn_style.border_width_top = 1
		btn_style.border_width_right = 1
		btn_style.border_width_bottom = 1
		btn_container.add_theme_stylebox_override("panel", btn_style)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 5)
		btn_container.add_child(hbox)
		
		# Ícone da torre
		var icon_texture = TextureRect.new()
		icon_texture.custom_minimum_size = Vector2(45, 45)
		icon_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_texture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		if tower_info.icon != null:
			icon_texture.texture = tower_info.icon
		hbox.add_child(icon_texture)
		
		# Container para texto
		var text_container = VBoxContainer.new()
		text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(text_container)
		
		# Nome da torre
		var name_label = Label.new()
		name_label.text = tower_info.name
		name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		name_label.add_theme_font_size_override("font_size", 14)
		text_container.add_child(name_label)
		
		# Custo e limite
		var cost_label = Label.new()
		cost_label.name = "CostLabel"
		if tower_info.has("cost_type") and tower_info.cost_type == "emeralds":
			cost_label.text = "🟢 %d esmeraldas" % tower_info.cost
			cost_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.3))  # Verde para esmeraldas
		else:
			cost_label.text = "%d moedas" % tower_info.cost
			cost_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		cost_label.add_theme_font_size_override("font_size", 12)
		text_container.add_child(cost_label)
		
		var limit_label = Label.new()
		limit_label.name = "LimitLabel"
		limit_label.text = "0/%d" % tower_info.max
		limit_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		limit_label.add_theme_font_size_override("font_size", 11)
		text_container.add_child(limit_label)
		
		# Botão de compra
		var buy_btn = Button.new()
		buy_btn.name = "BuyButton"
		buy_btn.text = "Comprar"
		buy_btn.custom_minimum_size = Vector2(75, 35)
		buy_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
		buy_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		buy_btn.pressed.connect(Callable(self, tower_info.func))
		
		# Estilizar botão
		var btn_style_normal = StyleBoxFlat.new()
		btn_style_normal.bg_color = Color(0.2, 0.6, 0.2)
		btn_style_normal.border_color = Color(0.3, 0.7, 0.3)
		btn_style_normal.border_width_left = 1
		btn_style_normal.border_width_top = 1
		btn_style_normal.border_width_right = 1
		btn_style_normal.border_width_bottom = 1
		buy_btn.add_theme_stylebox_override("normal", btn_style_normal)
		
		var btn_style_hover = StyleBoxFlat.new()
		btn_style_hover.bg_color = Color(0.3, 0.7, 0.3)
		btn_style_hover.border_color = Color(0.4, 0.8, 0.4)
		btn_style_hover.border_width_left = 1
		btn_style_hover.border_width_top = 1
		btn_style_hover.border_width_right = 1
		btn_style_hover.border_width_bottom = 1
		buy_btn.add_theme_stylebox_override("hover", btn_style_hover)
		
		var btn_style_pressed = StyleBoxFlat.new()
		btn_style_pressed.bg_color = Color(0.1, 0.5, 0.1)
		btn_style_pressed.border_color = Color(0.2, 0.6, 0.2)
		btn_style_pressed.border_width_left = 1
		btn_style_pressed.border_width_top = 1
		btn_style_pressed.border_width_right = 1
		btn_style_pressed.border_width_bottom = 1
		buy_btn.add_theme_stylebox_override("pressed", btn_style_pressed)
		
		buy_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		buy_btn.add_theme_font_size_override("font_size", 12)
		
		# Adicionar tooltip ao botão
		var shop_tooltip = _get_shop_tooltip_text(tower_info.name)
		buy_btn.tooltip_text = shop_tooltip
		
		# Conectar eventos de mouse para tooltip customizado
		buy_btn.mouse_entered.connect(func(): _on_shop_button_hover(tower_info.name))
		buy_btn.mouse_exited.connect(func(): _on_shop_button_unhover())
		
		hbox.add_child(buy_btn)
		
		# Armazenar referências para atualização
		var tower_button_data = {
			"container": btn_container,
			"cost_label": cost_label,
			"limit_label": limit_label,
			"buy_button": buy_btn,
			"tower_info": tower_info
		}
		tower_buttons.append(tower_button_data)
		
		vbox.add_child(btn_container)
		
		# Adicionar upgrades de minas logo após o card de mina
		if tower_info.name == "Mina":
			_create_mine_upgrade_buttons(vbox, panel_width)
	
	# Criar tooltip
	tooltip_label = Label.new()
	tooltip_label.name = "TooltipLabel"
	tooltip_label.visible = false
	tooltip_label.position = Vector2(10, 10)
	tooltip_label.custom_minimum_size = Vector2(250, 120)  # Aumentado de 180x100 para 250x120
	tooltip_label.size = Vector2(250, 120)
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var tooltip_style = StyleBoxFlat.new()
	tooltip_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	tooltip_style.border_color = Color(0.5, 0.5, 0.7)
	tooltip_style.border_width_left = 2
	tooltip_style.border_width_top = 2
	tooltip_style.border_width_right = 2
	tooltip_style.border_width_bottom = 2
	tooltip_label.add_theme_stylebox_override("normal", tooltip_style)
	tooltip_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	tower_shop_panel.add_child(tooltip_label)

func _create_game_tooltip() -> void:
	# Criar tooltip global no CanvasLayer
	var canvas = $CanvasLayer
	game_tooltip = Control.new()
	game_tooltip.name = "GameTooltip"
	game_tooltip.visible = false
	game_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(game_tooltip)
	
	# Painel de fundo
	var tooltip_panel = Panel.new()
	tooltip_panel.name = "Panel"
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	panel_style.border_color = Color(0.5, 0.5, 0.7)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	tooltip_panel.add_theme_stylebox_override("panel", panel_style)
	game_tooltip.add_child(tooltip_panel)
	
	# Label de texto
	var tooltip_text_label = Label.new()
	tooltip_text_label.name = "TooltipText"
	tooltip_text_label.text = ""
	tooltip_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_text_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	tooltip_text_label.add_theme_font_size_override("font_size", 12)
	tooltip_text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	tooltip_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	tooltip_panel.add_child(tooltip_text_label)
	
	# Configurar layout - aumentar tamanho do tooltip
	tooltip_panel.custom_minimum_size = Vector2(280, 0)  # Largura mínima maior, altura automática
	tooltip_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Usar anchors para preencher o painel com padding
	tooltip_text_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	tooltip_text_label.offset_left = 10
	tooltip_text_label.offset_top = 10
	tooltip_text_label.offset_right = -10
	tooltip_text_label.offset_bottom = -10

func _create_hero_home_card(vbox: VBoxContainer, card_height: float) -> void:
	hero_home_panel_data = {}
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(tower_shop_panel.size.x - 20, card_height)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.25, 0.22, 0.28, 0.9)
	panel_style.border_color = Color(0.6, 0.5, 0.8)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", panel_style)
	vbox.add_child(panel)
	
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(content)
	
	var title = Label.new()
	title.text = "Base do Herói"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.4))
	content.add_child(title)
	
	var info_hbox = HBoxContainer.new()
	info_hbox.add_theme_constant_override("separation", 10)
	content.add_child(info_hbox)
	
	var hero_icon_size = 45.0  # mesmo padrão dos ícones das torres
	var icon_wrapper = Control.new()
	icon_wrapper.custom_minimum_size = Vector2(hero_icon_size, hero_icon_size)
	icon_wrapper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info_hbox.add_child(icon_wrapper)
	
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(hero_icon_size, hero_icon_size)
	icon.size = Vector2(hero_icon_size, hero_icon_size)
	icon.ignore_texture_size = true
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_wrapper.add_child(icon)
	
	var text_box = VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_hbox.add_child(text_box)
	
	var level_label = Label.new()
	level_label.add_theme_font_size_override("font_size", 14)
	text_box.add_child(level_label)
	
	var benefit_label = Label.new()
	benefit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	benefit_label.add_theme_font_size_override("font_size", 12)
	benefit_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
	text_box.add_child(benefit_label)
	
	var cost_label = Label.new()
	cost_label.add_theme_font_size_override("font_size", 12)
	cost_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	text_box.add_child(cost_label)
	
	var button = Button.new()
	button.text = "Evoluir"
	button.custom_minimum_size = Vector2(120, 36)
	button.pressed.connect(_on_upgrade_hero_home)
	info_hbox.add_child(button)
	
	hero_home_panel_data = {
		"panel": panel,
		"icon": icon,
		"level_label": level_label,
		"benefit_label": benefit_label,
		"cost_label": cost_label,
		"button": button
	}
	
	_update_hero_home_panel_ui()

func _create_skills_ui() -> void:
	# Criar painel lateral para skills (lado esquerdo)
	var canvas = $CanvasLayer
	var hud = canvas.get_node("HUD")
	
	# Remover menu antigo se existir
	if hud.has_node("SkillsPanel"):
		hud.get_node("SkillsPanel").queue_free()
	
	# Criar painel lateral
	skills_panel = Panel.new()
	skills_panel.name = "SkillsPanel"
	skills_panel.z_index = 0  # Garantir que fique atrás da HUD
	hud.add_child(skills_panel)
	
	# Configurar posição e tamanho do painel (lado direito, à esquerda da loja de torres)
	var screen_width = get_viewport().get_visible_rect().size.x
	var screen_height = get_viewport().get_visible_rect().size.y
	var panel_width = 390.0  # Largura aumentada para melhor visualização
	# Calcular altura necessária: pode ocupar até o final da tela
	var panel_height = screen_height - 44.0  # Altura total disponível (tela - top bar)
	# Posicionar no lado direito, à esquerda do painel de torres
	# Pegar a largura atual do menu de torres dinamicamente
	var tower_panel_width = 350.0  # Deve corresponder à largura do tower_shop_panel (linha 4651)
	if tower_shop_panel != null:
		tower_panel_width = tower_shop_panel.size.x
	# Garantir que não sobreponha: posição = largura_tela - largura_torre - largura_skills - margem
	var margin = 5.0  # Margem entre os painéis
	skills_panel.position = Vector2(screen_width - tower_panel_width - panel_width - margin, 44.0)
	skills_panel.size = Vector2(panel_width, panel_height)
	
	# Estilizar o painel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	style_box.border_color = Color(0.3, 0.3, 0.4)
	style_box.border_width_left = 0
	style_box.border_width_top = 0
	style_box.border_width_right = 2
	style_box.border_width_bottom = 0
	skills_panel.add_theme_stylebox_override("panel", style_box)
	
	# Container para título com botão de toggle
	var title_container = HBoxContainer.new()
	title_container.name = "TitleContainer"
	title_container.position = Vector2(10, 10)
	title_container.size = Vector2(panel_width - 20, 35)
	skills_panel.add_child(title_container)
	
	# Título do painel
	var title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "SKILLS"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_container.add_child(title_label)
	
	# Botão de toggle para colapsar/expandir (melhorado e estilizado)
	skills_panel_toggle_button = Button.new()
	skills_panel_toggle_button.name = "ToggleButton"
	skills_panel_toggle_button.text = "◄"  # Quando expandido, mostra seta para esquerda (colapsar)
	skills_panel_toggle_button.custom_minimum_size = Vector2(22, 22)  # Menor para caber melhor
	skills_panel_toggle_button.pressed.connect(_toggle_skills_panel)
	var toggle_style = StyleBoxFlat.new()
	toggle_style.bg_color = Color(0.2, 0.5, 0.7, 0.9)  # Azul ciano mais bonito
	toggle_style.border_color = Color(0.3, 0.6, 0.8, 1.0)
	toggle_style.border_width_left = 2
	toggle_style.border_width_top = 2
	toggle_style.border_width_right = 2
	toggle_style.border_width_bottom = 2
	toggle_style.corner_radius_top_left = 4
	toggle_style.corner_radius_top_right = 4
	toggle_style.corner_radius_bottom_left = 4
	toggle_style.corner_radius_bottom_right = 4
	var toggle_hover_style = StyleBoxFlat.new()
	toggle_hover_style.bg_color = Color(0.3, 0.6, 0.8, 0.95)
	toggle_hover_style.border_color = Color(0.4, 0.7, 0.9, 1.0)
	toggle_hover_style.border_width_left = 2
	toggle_hover_style.border_width_top = 2
	toggle_hover_style.border_width_right = 2
	toggle_hover_style.border_width_bottom = 2
	toggle_hover_style.corner_radius_top_left = 4
	toggle_hover_style.corner_radius_top_right = 4
	toggle_hover_style.corner_radius_bottom_left = 4
	toggle_hover_style.corner_radius_bottom_right = 4
	skills_panel_toggle_button.add_theme_stylebox_override("normal", toggle_style)
	skills_panel_toggle_button.add_theme_stylebox_override("hover", toggle_hover_style)
	skills_panel_toggle_button.add_theme_font_size_override("font_size", 14)
	skills_panel_toggle_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	title_container.add_child(skills_panel_toggle_button)
	
	# Container para botões de skills
	var vbox = VBoxContainer.new()
	vbox.name = "SkillsButtonsContainer"
	vbox.position = Vector2(10, 50)
	vbox.size = Vector2(panel_width - 20, panel_height - 50)
	vbox.add_theme_constant_override("separation", 10)
	skills_panel.add_child(vbox)
	
	# Armazenar referência para poder esconder/mostrar
	skills_panel.set_meta("skills_container", vbox)
	
	# Skill 1: Coletar todas as moedas
	var skill1_container = PanelContainer.new()
	skill1_container.custom_minimum_size = Vector2(panel_width - 20, 85)
	var skill1_style = StyleBoxFlat.new()
	skill1_style.bg_color = Color(0.2, 0.2, 0.25, 0.8)
	skill1_style.border_color = Color(0.4, 0.4, 0.5)
	skill1_style.border_width_left = 1
	skill1_style.border_width_top = 1
	skill1_style.border_width_right = 1
	skill1_style.border_width_bottom = 1
	skill1_container.add_theme_stylebox_override("panel", skill1_style)
	
	var skill1_hbox = HBoxContainer.new()
	skill1_hbox.add_theme_constant_override("separation", 5)
	skill1_container.add_child(skill1_hbox)
	
	# Ícone da moeda
	var coin_icon_container = Control.new()
	coin_icon_container.custom_minimum_size = Vector2(50, 50)
	coin_icon_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	coin_icon_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var coin_icon = TextureRect.new()
	coin_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	coin_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if tex_coin != null:
		coin_icon.texture = tex_coin
	coin_icon_container.add_child(coin_icon)
	skill1_hbox.add_child(coin_icon_container)
	
	# Texto da skill
	var skill1_text = VBoxContainer.new()
	skill1_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill1_hbox.add_child(skill1_text)
	
	var skill1_name = Label.new()
	skill1_name.text = "Coletar Moedas [1]"
	skill1_name.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	skill1_name.add_theme_font_size_override("font_size", 14)
	skill1_text.add_child(skill1_name)
	
	var skill1_desc = Label.new()
	skill1_desc.name = "Skill1Desc"
	skill1_desc.text = "Coleta todas as moedas do mapa"
	skill1_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	skill1_desc.add_theme_font_size_override("font_size", 11)
	skill1_text.add_child(skill1_desc)
	
	# Label de cooldown base
	var skill1_cooldown_base_label = Label.new()
	skill1_cooldown_base_label.name = "Skill1CooldownBase"
	skill1_cooldown_base_label.text = "CD: %.0fs" % GameConstants.SKILL_COLLECT_COINS_COOLDOWN
	skill1_cooldown_base_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	skill1_cooldown_base_label.add_theme_font_size_override("font_size", 10)
	skill1_text.add_child(skill1_cooldown_base_label)
	
	# Label de cooldown ativo
	var skill1_cooldown_label = Label.new()
	skill1_cooldown_label.name = "Skill1Cooldown"
	skill1_cooldown_label.text = ""
	skill1_cooldown_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	skill1_cooldown_label.add_theme_font_size_override("font_size", 11)
	skill1_text.add_child(skill1_cooldown_label)
	
	# Botão
	var skill1_btn = Button.new()
	skill1_btn.name = "Skill1Button"
	skill1_btn.text = "Usar"
	skill1_btn.custom_minimum_size = Vector2(60, 35)
	skill1_btn.pressed.connect(_on_skill_collect_coins)
	skill_buttons["collect_coins"] = {"button": skill1_btn, "cooldown_label": skill1_cooldown_label, "cooldown_base_label": skill1_cooldown_base_label}
	var btn1_style = StyleBoxFlat.new()
	btn1_style.bg_color = Color(0.2, 0.6, 0.2)
	btn1_style.border_color = Color(0.3, 0.7, 0.3)
	btn1_style.border_width_left = 1
	btn1_style.border_width_top = 1
	btn1_style.border_width_right = 1
	btn1_style.border_width_bottom = 1
	skill1_btn.add_theme_stylebox_override("normal", btn1_style)
	skill1_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	skill1_btn.add_theme_font_size_override("font_size", 12)
	skill1_hbox.add_child(skill1_btn)
	
	vbox.add_child(skill1_container)
	
	# Skill 2: Boost de Dano
	var skill2_container = PanelContainer.new()
	skill2_container.custom_minimum_size = Vector2(panel_width - 20, 85)
	var skill2_style = StyleBoxFlat.new()
	skill2_style.bg_color = Color(0.2, 0.2, 0.25, 0.8)
	skill2_style.border_color = Color(0.4, 0.4, 0.5)
	skill2_style.border_width_left = 1
	skill2_style.border_width_top = 1
	skill2_style.border_width_right = 1
	skill2_style.border_width_bottom = 1
	skill2_container.add_theme_stylebox_override("panel", skill2_style)
	
	var skill2_hbox = HBoxContainer.new()
	skill2_hbox.add_theme_constant_override("separation", 5)
	skill2_container.add_child(skill2_hbox)
	
	# Ícone (usar um Label com símbolo)
	var skill2_icon = Label.new()
	skill2_icon.text = "⚔"
	skill2_icon.custom_minimum_size = Vector2(50, 50)
	skill2_icon.add_theme_font_size_override("font_size", 32)
	skill2_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill2_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	skill2_hbox.add_child(skill2_icon)
	
	# Texto da skill
	var skill2_text = VBoxContainer.new()
	skill2_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill2_hbox.add_child(skill2_text)
	
	var skill2_name = Label.new()
	skill2_name.text = "Boost de Dano [2]"
	skill2_name.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	skill2_name.add_theme_font_size_override("font_size", 14)
	skill2_text.add_child(skill2_name)
	
	var skill2_desc = Label.new()
	skill2_desc.name = "Skill2Desc"
	skill2_desc.text = "+50%% dano por %.0fs" % GameConstants.SKILL_DAMAGE_BOOST_DURATION
	skill2_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	skill2_desc.add_theme_font_size_override("font_size", 11)
	skill2_text.add_child(skill2_desc)
	
	# Label de cooldown base
	var skill2_cooldown_base_label = Label.new()
	skill2_cooldown_base_label.name = "Skill2CooldownBase"
	skill2_cooldown_base_label.text = "CD: %.0fs" % GameConstants.SKILL_DAMAGE_BOOST_COOLDOWN
	skill2_cooldown_base_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	skill2_cooldown_base_label.add_theme_font_size_override("font_size", 10)
	skill2_text.add_child(skill2_cooldown_base_label)
	
	# Label de cooldown ativo
	var skill2_cooldown_label = Label.new()
	skill2_cooldown_label.name = "Skill2Cooldown"
	skill2_cooldown_label.text = ""
	skill2_cooldown_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	skill2_cooldown_label.add_theme_font_size_override("font_size", 11)
	skill2_text.add_child(skill2_cooldown_label)
	
	# Botão
	var skill2_btn = Button.new()
	skill2_btn.name = "Skill2Button"
	skill2_btn.text = "Usar"
	skill2_btn.custom_minimum_size = Vector2(60, 35)
	skill2_btn.pressed.connect(_on_skill_damage_boost)
	skill_buttons["damage_boost"] = {"button": skill2_btn, "cooldown_label": skill2_cooldown_label, "cooldown_base_label": skill2_cooldown_base_label}
	var btn2_style = StyleBoxFlat.new()
	btn2_style.bg_color = Color(0.6, 0.2, 0.2)
	btn2_style.border_color = Color(0.7, 0.3, 0.3)
	btn2_style.border_width_left = 1
	btn2_style.border_width_top = 1
	btn2_style.border_width_right = 1
	btn2_style.border_width_bottom = 1
	skill2_btn.add_theme_stylebox_override("normal", btn2_style)
	skill2_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	skill2_btn.add_theme_font_size_override("font_size", 12)
	skill2_hbox.add_child(skill2_btn)
	
	vbox.add_child(skill2_container)
	
	# Skill 3: Boost de Velocidade
	var skill3_container = PanelContainer.new()
	skill3_container.custom_minimum_size = Vector2(panel_width - 20, 85)
	var skill3_style = StyleBoxFlat.new()
	skill3_style.bg_color = Color(0.2, 0.2, 0.25, 0.8)
	skill3_style.border_color = Color(0.4, 0.4, 0.5)
	skill3_style.border_width_left = 1
	skill3_style.border_width_top = 1
	skill3_style.border_width_right = 1
	skill3_style.border_width_bottom = 1
	skill3_container.add_theme_stylebox_override("panel", skill3_style)
	
	var skill3_hbox = HBoxContainer.new()
	skill3_hbox.add_theme_constant_override("separation", 5)
	skill3_container.add_child(skill3_hbox)
	
	# Ícone (usar um Label com símbolo)
	var skill3_icon = Label.new()
	skill3_icon.text = "⚡"
	skill3_icon.custom_minimum_size = Vector2(50, 50)
	skill3_icon.add_theme_font_size_override("font_size", 32)
	skill3_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill3_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	skill3_hbox.add_child(skill3_icon)
	
	# Texto da skill
	var skill3_text = VBoxContainer.new()
	skill3_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill3_hbox.add_child(skill3_text)
	
	var skill3_name = Label.new()
	skill3_name.text = "Boost de Velocidade [3]"
	skill3_name.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	skill3_name.add_theme_font_size_override("font_size", 14)
	skill3_text.add_child(skill3_name)
	
	var skill3_desc = Label.new()
	skill3_desc.name = "Skill3Desc"
	skill3_desc.text = "+30%% velocidade por %.0fs" % GameConstants.SKILL_SPEED_BOOST_DURATION
	skill3_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	skill3_desc.add_theme_font_size_override("font_size", 11)
	skill3_text.add_child(skill3_desc)
	
	# Label de cooldown base
	var skill3_cooldown_base_label = Label.new()
	skill3_cooldown_base_label.name = "Skill3CooldownBase"
	skill3_cooldown_base_label.text = "CD: %.0fs" % GameConstants.SKILL_SPEED_BOOST_COOLDOWN
	skill3_cooldown_base_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	skill3_cooldown_base_label.add_theme_font_size_override("font_size", 10)
	skill3_text.add_child(skill3_cooldown_base_label)
	
	# Label de cooldown ativo
	var skill3_cooldown_label = Label.new()
	skill3_cooldown_label.name = "Skill3Cooldown"
	skill3_cooldown_label.text = ""
	skill3_cooldown_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	skill3_cooldown_label.add_theme_font_size_override("font_size", 11)
	skill3_text.add_child(skill3_cooldown_label)
	
	# Botão
	var skill3_btn = Button.new()
	skill3_btn.name = "Skill3Button"
	skill3_btn.text = "Usar"
	skill3_btn.custom_minimum_size = Vector2(60, 35)
	skill3_btn.pressed.connect(_on_skill_speed_boost)
	skill_buttons["speed_boost"] = {"button": skill3_btn, "cooldown_label": skill3_cooldown_label, "cooldown_base_label": skill3_cooldown_base_label}
	var btn3_style = StyleBoxFlat.new()
	btn3_style.bg_color = Color(0.2, 0.2, 0.6)
	btn3_style.border_color = Color(0.3, 0.3, 0.7)
	btn3_style.border_width_left = 1
	btn3_style.border_width_top = 1
	btn3_style.border_width_right = 1
	btn3_style.border_width_bottom = 1
	skill3_btn.add_theme_stylebox_override("normal", btn3_style)
	skill3_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	skill3_btn.add_theme_font_size_override("font_size", 12)
	skill3_hbox.add_child(skill3_btn)
	
	vbox.add_child(skill3_container)
	
	# Skill 4: Slow Global
	var skill4_container = PanelContainer.new()
	skill4_container.custom_minimum_size = Vector2(panel_width - 20, 85)
	var skill4_style = StyleBoxFlat.new()
	skill4_style.bg_color = Color(0.2, 0.2, 0.25, 0.8)
	skill4_style.border_color = Color(0.4, 0.4, 0.5)
	skill4_style.border_width_left = 1
	skill4_style.border_width_top = 1
	skill4_style.border_width_right = 1
	skill4_style.border_width_bottom = 1
	skill4_container.add_theme_stylebox_override("panel", skill4_style)
	
	var skill4_hbox = HBoxContainer.new()
	skill4_hbox.add_theme_constant_override("separation", 5)
	skill4_container.add_child(skill4_hbox)
	
	# Ícone (usar um Label com símbolo)
	var skill4_icon = Label.new()
	skill4_icon.text = "❄"
	skill4_icon.custom_minimum_size = Vector2(50, 50)
	skill4_icon.add_theme_font_size_override("font_size", 32)
	skill4_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill4_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	skill4_hbox.add_child(skill4_icon)
	
	# Texto da skill
	var skill4_text = VBoxContainer.new()
	skill4_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill4_hbox.add_child(skill4_text)
	
	var skill4_name = Label.new()
	skill4_name.text = "Slow Global [4]"
	skill4_name.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	skill4_name.add_theme_font_size_override("font_size", 14)
	skill4_text.add_child(skill4_name)
	
	var skill4_desc = Label.new()
	skill4_desc.name = "Skill4Desc"
	skill4_desc.text = "Reduz velocidade de todos os inimigos por %.0fs" % GameConstants.SKILL_SLOW_ALL_DURATION
	skill4_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	skill4_desc.add_theme_font_size_override("font_size", 11)
	skill4_text.add_child(skill4_desc)
	
	# Label de cooldown base
	var skill4_cooldown_base_label = Label.new()
	skill4_cooldown_base_label.name = "Skill4CooldownBase"
	skill4_cooldown_base_label.text = "CD: %.0fs" % GameConstants.SKILL_SLOW_ALL_COOLDOWN
	skill4_cooldown_base_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	skill4_cooldown_base_label.add_theme_font_size_override("font_size", 10)
	skill4_text.add_child(skill4_cooldown_base_label)
	
	# Label de cooldown ativo
	var skill4_cooldown_label = Label.new()
	skill4_cooldown_label.name = "Skill4Cooldown"
	skill4_cooldown_label.text = ""
	skill4_cooldown_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	skill4_cooldown_label.add_theme_font_size_override("font_size", 11)
	skill4_text.add_child(skill4_cooldown_label)
	
	# Botão
	var skill4_btn = Button.new()
	skill4_btn.name = "Skill4Button"
	skill4_btn.text = "Usar"
	skill4_btn.custom_minimum_size = Vector2(60, 35)
	skill4_btn.pressed.connect(_on_skill_slow_all)
	skill_buttons["slow_all"] = {"button": skill4_btn, "cooldown_label": skill4_cooldown_label, "cooldown_base_label": skill4_cooldown_base_label}
	var btn4_style = StyleBoxFlat.new()
	btn4_style.bg_color = Color(0.2, 0.4, 0.6)
	btn4_style.border_color = Color(0.3, 0.5, 0.7)
	btn4_style.border_width_left = 1
	btn4_style.border_width_top = 1
	btn4_style.border_width_right = 1
	btn4_style.border_width_bottom = 1
	skill4_btn.add_theme_stylebox_override("normal", btn4_style)
	skill4_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	skill4_btn.add_theme_font_size_override("font_size", 12)
	skill4_hbox.add_child(skill4_btn)
	
	vbox.add_child(skill4_container)
	
	# Skill 5: Magnetismo de Moedas
	var skill5_container = PanelContainer.new()
	skill5_container.custom_minimum_size = Vector2(panel_width - 20, 85)
	var skill5_style = StyleBoxFlat.new()
	skill5_style.bg_color = Color(0.2, 0.2, 0.25, 0.8)
	skill5_style.border_color = Color(0.4, 0.4, 0.5)
	skill5_style.border_width_left = 1
	skill5_style.border_width_top = 1
	skill5_style.border_width_right = 1
	skill5_style.border_width_bottom = 1
	skill5_container.add_theme_stylebox_override("panel", skill5_style)
	
	var skill5_hbox = HBoxContainer.new()
	skill5_hbox.add_theme_constant_override("separation", 5)
	skill5_container.add_child(skill5_hbox)
	
	# Ícone (usar um Label com símbolo)
	var skill5_icon = Label.new()
	skill5_icon.text = "🧲"
	skill5_icon.custom_minimum_size = Vector2(50, 50)
	skill5_icon.add_theme_font_size_override("font_size", 32)
	skill5_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill5_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	skill5_hbox.add_child(skill5_icon)
	
	# Texto da skill
	var skill5_text = VBoxContainer.new()
	skill5_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill5_hbox.add_child(skill5_text)
	
	var skill5_name = Label.new()
	skill5_name.text = "Magnetismo de Moedas [5]"
	skill5_name.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	skill5_name.add_theme_font_size_override("font_size", 14)
	skill5_text.add_child(skill5_name)
	
	var skill5_desc = Label.new()
	skill5_desc.name = "Skill5Desc"
	skill5_desc.text = "Coleta moedas automaticamente\nao passar o mouse por %.0fs" % GameConstants.SKILL_MAGNETISM_DURATION
	skill5_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skill5_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	skill5_desc.add_theme_font_size_override("font_size", 11)
	skill5_text.add_child(skill5_desc)
	
	# Label de cooldown base
	var skill5_cooldown_base_label = Label.new()
	skill5_cooldown_base_label.name = "Skill5CooldownBase"
	skill5_cooldown_base_label.text = "CD: %.0fs" % GameConstants.SKILL_MAGNETISM_COOLDOWN
	skill5_cooldown_base_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	skill5_cooldown_base_label.add_theme_font_size_override("font_size", 10)
	skill5_text.add_child(skill5_cooldown_base_label)
	
	# Label de cooldown ativo
	var skill5_cooldown_label = Label.new()
	skill5_cooldown_label.name = "Skill5Cooldown"
	skill5_cooldown_label.text = ""
	skill5_cooldown_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	skill5_cooldown_label.add_theme_font_size_override("font_size", 11)
	skill5_text.add_child(skill5_cooldown_label)
	
	# Botão
	var skill5_btn = Button.new()
	skill5_btn.name = "Skill5Button"
	skill5_btn.text = "Usar"
	skill5_btn.custom_minimum_size = Vector2(60, 35)
	skill5_btn.pressed.connect(_on_skill_magnetism)
	skill_buttons["magnetism"] = {"button": skill5_btn, "cooldown_label": skill5_cooldown_label, "cooldown_base_label": skill5_cooldown_base_label}
	var btn5_style = StyleBoxFlat.new()
	btn5_style.bg_color = Color(0.4, 0.2, 0.6)
	btn5_style.border_color = Color(0.5, 0.3, 0.7)
	btn5_style.border_width_left = 1
	btn5_style.border_width_top = 1
	btn5_style.border_width_right = 1
	btn5_style.border_width_bottom = 1
	skill5_btn.add_theme_stylebox_override("normal", btn5_style)
	skill5_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	skill5_btn.add_theme_font_size_override("font_size", 12)
	skill5_hbox.add_child(skill5_btn)
	
	vbox.add_child(skill5_container)
	
	# Botão para abrir inventário de talismãs
	var talisman_btn = Button.new()
	talisman_btn.name = "TalismanButton"
	talisman_btn.text = "Talismãs"
	talisman_btn.custom_minimum_size = Vector2(100, 40)
	talisman_btn.pressed.connect(_toggle_talisman_inventory)
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.3, 0.2, 0.5)
	btn_style.border_color = Color(0.5, 0.4, 0.7)
	btn_style.border_width_left = 1
	btn_style.border_width_top = 1
	btn_style.border_width_right = 1
	btn_style.border_width_bottom = 1
	talisman_btn.add_theme_stylebox_override("normal", btn_style)
	talisman_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	talisman_btn.add_theme_font_size_override("font_size", 12)
	vbox.add_child(talisman_btn)
	
	_create_talisman_inventory_ui()

func _create_talisman_inventory_ui() -> void:
	# Criar painel de inventário de talismãs
	var canvas = $CanvasLayer
	var hud = canvas.get_node("HUD")
	
	if hud.has_node("TalismanInventoryPanel"):
		hud.get_node("TalismanInventoryPanel").queue_free()
	
	var panel = Panel.new()
	panel.name = "TalismanInventoryPanel"
	panel.visible = false
	panel.z_index = 100
	hud.add_child(panel)
	
	var screen_width = get_viewport().get_visible_rect().size.x
	var _screen_height = get_viewport().get_visible_rect().size.y
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.position = Vector2(screen_width/2 - 300, 60)
	panel.size = Vector2(600, 500)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_color = Color(0.3, 0.3, 0.4)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", style)
	
	# Container principal com margens
	var main_margin = MarginContainer.new()
	main_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_margin.add_theme_constant_override("margin_left", 15)
	main_margin.add_theme_constant_override("margin_right", 15)
	main_margin.add_theme_constant_override("margin_top", 15)
	main_margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(main_margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	main_margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "Talismãs"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.custom_minimum_size = Vector2(100, 30)
	close_btn.pressed.connect(_toggle_talisman_inventory)
	vbox.add_child(close_btn)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	# Container interno do scroll com margem
	var scroll_margin = MarginContainer.new()
	scroll_margin.add_theme_constant_override("margin_left", 10)
	scroll_margin.add_theme_constant_override("margin_right", 10)
	scroll_margin.add_theme_constant_override("margin_top", 10)
	scroll_margin.add_theme_constant_override("margin_bottom", 10)
	scroll.add_child(scroll_margin)
	
	var inventory_vbox = VBoxContainer.new()
	inventory_vbox.add_theme_constant_override("separation", 8)
	scroll_margin.add_child(inventory_vbox)
	
	# Armazenar referências para atualização
	talisman_inventory_panel = panel
	talisman_inventory_container = inventory_vbox
	_update_talisman_inventory_ui()

var talisman_inventory_panel: Panel = null
var talisman_inventory_container: VBoxContainer = null
var talisman_inventory_visible: bool = false

func _toggle_talisman_inventory() -> void:
	if talisman_inventory_panel:
		talisman_inventory_visible = not talisman_inventory_visible
		talisman_inventory_panel.visible = talisman_inventory_visible
		if talisman_inventory_visible:
			_update_talisman_inventory_ui()

func _update_talisman_inventory_ui() -> void:
	if not talisman_inventory_container or not item_manager:
		return
	
	# Limpar container
	for child in talisman_inventory_container.get_children():
		child.queue_free()
	
	# Mostrar itens equipados
	var equipped_label = Label.new()
	equipped_label.text = "Equipados:"
	equipped_label.add_theme_font_size_override("font_size", 16)
	equipped_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	equipped_label.add_theme_constant_override("margin_top", 5)
	talisman_inventory_container.add_child(equipped_label)
	
	if item_manager.equipped_items.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Nenhum talismã equipado"
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		empty_label.add_theme_constant_override("margin_left", 10)
		talisman_inventory_container.add_child(empty_label)
	else:
		for item in item_manager.equipped_items:
			# Garantir que a descrição está atualizada antes de criar a UI
			if item is Talisman:
				var talisman: Talisman = item
				talisman._apply_talisman_effects()
			_create_talisman_item_ui(item, true)
	
	# Separador
	var separator = HSeparator.new()
	separator.add_theme_constant_override("margin_top", 10)
	separator.add_theme_constant_override("margin_bottom", 10)
	talisman_inventory_container.add_child(separator)
	
	# Mostrar inventário
	var inventory_label = Label.new()
	inventory_label.text = "Inventário:"
	inventory_label.add_theme_font_size_override("font_size", 16)
	inventory_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	inventory_label.add_theme_constant_override("margin_top", 5)
	talisman_inventory_container.add_child(inventory_label)
	
	if item_manager.inventory.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Inventário vazio"
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		empty_label.add_theme_constant_override("margin_left", 10)
		talisman_inventory_container.add_child(empty_label)
	else:
		for item in item_manager.inventory:
			# Garantir que a descrição está atualizada antes de criar a UI
			if item is Talisman:
				var talisman: Talisman = item
				talisman._apply_talisman_effects()
			_create_talisman_item_ui(item, false)

func _create_talisman_item_ui(item: EquippableItem, is_equipped: bool) -> void:
	var item_container = PanelContainer.new()
	var item_style = StyleBoxFlat.new()
	var rarity_color = item.get_rarity_color()
	item_style.bg_color = Color(rarity_color.r * 0.2, rarity_color.g * 0.2, rarity_color.b * 0.2, 0.8)
	item_style.border_color = rarity_color
	item_style.border_width_left = 2
	item_style.border_width_top = 2
	item_style.border_width_right = 2
	item_style.border_width_bottom = 2
	item_container.add_theme_stylebox_override("panel", item_style)
	item_container.custom_minimum_size = Vector2(0, 90)
	
	# Container interno com margem
	var item_margin = MarginContainer.new()
	item_margin.add_theme_constant_override("margin_left", 10)
	item_margin.add_theme_constant_override("margin_right", 10)
	item_margin.add_theme_constant_override("margin_top", 8)
	item_margin.add_theme_constant_override("margin_bottom", 8)
	item_container.add_child(item_margin)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	item_margin.add_child(hbox)
	
	# Ícone do talismã
	var icon_container = Control.new()
	icon_container.custom_minimum_size = Vector2(70, 70)
	icon_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(icon_container)
	
	# Fundo com cor da raridade
	var icon_bg = ColorRect.new()
	icon_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_bg.color = Color(rarity_color.r * 0.3, rarity_color.g * 0.3, rarity_color.b * 0.3, 0.8)
	icon_container.add_child(icon_bg)
	
	# Borda com cor da raridade
	var icon_border = Panel.new()
	icon_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	var border_style = StyleBoxFlat.new()
	border_style.bg_color = Color(0, 0, 0, 0)
	border_style.border_color = rarity_color
	border_style.border_width_left = 2
	border_style.border_width_top = 2
	border_style.border_width_right = 2
	border_style.border_width_bottom = 2
	icon_border.add_theme_stylebox_override("panel", border_style)
	icon_container.add_child(icon_border)
	
	# Imagem do talismã
	if tex_talisman != null:
		var icon_texture = TextureRect.new()
		icon_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_texture.texture = tex_talisman
		icon_container.add_child(icon_texture)
	
	# Informações
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(vbox)
	
	var name_label = Label.new()
	name_label.text = item.name
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", rarity_color)
	vbox.add_child(name_label)
	
	var desc_label = Label.new()
	# Se for um talismã, usar a descrição atualizada com o valor correto
	if item is Talisman:
		var talisman: Talisman = item
		# Forçar atualização da descrição antes de exibir
		talisman._apply_talisman_effects()
		desc_label.text = talisman.description
	else:
		desc_label.text = item.description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)
	
	# Botões de ação
	var btn_container = VBoxContainer.new()
	btn_container.add_theme_constant_override("separation", 5)
	btn_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(btn_container)
	
	# Botão equipar/desequipar
	var btn = Button.new()
	if is_equipped:
		btn.text = "Desequipar"
		btn.pressed.connect(func(): item_manager.unequip_item(item); _update_talisman_inventory_ui())
	else:
		btn.text = "Equipar"
		btn.pressed.connect(func(): item_manager.equip_item(item); _update_talisman_inventory_ui())
	btn.custom_minimum_size = Vector2(90, 35)
	btn_container.add_child(btn)
	
	# Botão vender (apenas para talismãs não equipados)
	if not is_equipped and item is Talisman:
		var sell_price = get_talisman_sell_price(item)
		var sell_btn = Button.new()
		sell_btn.text = "Vender\n🟢 %d" % sell_price
		sell_btn.custom_minimum_size = Vector2(90, 35)
		sell_btn.pressed.connect(func(): _sell_talisman(item); _update_talisman_inventory_ui())
		btn_container.add_child(sell_btn)
	
	talisman_inventory_container.add_child(item_container)

func get_talisman_sell_price(talisman: Talisman) -> int:
	"""Retorna o preço de venda de um talismã baseado na sua raridade"""
	match talisman.rarity:
		EquippableItem.ItemRarity.COMMON:
			return GameConstants.TALISMAN_SELL_PRICE_COMMON
		EquippableItem.ItemRarity.UNCOMMON:
			return GameConstants.TALISMAN_SELL_PRICE_UNCOMMON
		EquippableItem.ItemRarity.RARE:
			return GameConstants.TALISMAN_SELL_PRICE_RARE
		EquippableItem.ItemRarity.EPIC:
			return GameConstants.TALISMAN_SELL_PRICE_EPIC
		EquippableItem.ItemRarity.LEGENDARY:
			return GameConstants.TALISMAN_SELL_PRICE_LEGENDARY
		_:
			return GameConstants.TALISMAN_SELL_PRICE_COMMON

func _sell_talisman(talisman: Talisman) -> void:
	"""Vende um talismã por esmeraldas"""
	if not item_manager or not special_currency_manager:
		return
	
	# Verificar se o talismã está no inventário (não pode vender equipados)
	if talisman in item_manager.equipped_items:
		print("Não é possível vender talismãs equipados")
		return
	
	if not talisman in item_manager.inventory:
		print("Talismã não encontrado no inventário")
		return
	
	# Remover do inventário
	item_manager.inventory.erase(talisman)
	
	# Adicionar esmeraldas
	var sell_price = get_talisman_sell_price(talisman)
	special_currency_manager.add_emeralds(sell_price, "talisman_sell")
	
	# Atualizar UI
	_update_special_currency_labels()
	print("Talismã vendido por %d esmeraldas" % sell_price)

func _create_range_indicator() -> void:
	if range_indicator and range_indicator.is_inside_tree():
		range_indicator.queue_free()
	range_indicator = Line2D.new()
	range_indicator.name = "RangeIndicator"
	range_indicator.width = 2.5
	range_indicator.default_color = Color(0.3, 0.7, 1.0, 0.65)
	range_indicator.antialiased = true
	range_indicator.visible = false
	range_indicator.z_index = 200
	add_child(range_indicator)

func _set_range_indicator_points(radius: float) -> void:
	if range_indicator == null:
		return
	var pts := PackedVector2Array()
	for i in range(GameConstants.UI_RANGE_INDICATOR_SEGMENTS + 1):
		var angle = TAU * float(i) / float(GameConstants.UI_RANGE_INDICATOR_SEGMENTS)
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	range_indicator.points = pts

func _is_any_upgrade_menu_visible() -> bool:
	return (tower_menu and tower_menu.is_visible()) or \
		   (sniper_menu and sniper_menu.is_visible()) or \
		   (aoe_menu and aoe_menu.is_visible()) or \
		   (shock_menu and shock_menu.is_visible()) or \
		   (slow_menu and slow_menu.is_visible()) or \
		   (boost_menu and boost_menu.is_visible()) or \
		   (barracks_menu and barracks_menu.is_visible())

func _show_range_indicator(world_pos: Vector2, radius: float, color: Color = Color(0.3, 0.7, 1.0, 0.65)) -> void:
	if radius <= 0.0:
		_hide_range_indicator()
		return
	# Mostrar range indicator quando menu está aberto OU quando hover sobre torre
	if range_indicator == null or not range_indicator.is_inside_tree():
		_create_range_indicator()
	range_indicator.position = world_pos
	range_indicator.default_color = color
	_set_range_indicator_points(radius)
	range_indicator.visible = true

func _hide_range_indicator() -> void:
	if range_indicator:
		range_indicator.visible = false

func _close_all_upgrade_menus() -> void:
	# Fechar todos os menus
	if tower_menu:
		tower_menu.hide()
	if sniper_menu:
		sniper_menu.hide()
	if aoe_menu:
		aoe_menu.hide()
	if shock_menu:
		shock_menu.hide()
	if slow_menu:
		slow_menu.hide()
	if boost_menu:
		boost_menu.hide()
	if barracks_menu:
		barracks_menu.hide()
	# Esconder range indicator
	_hide_range_indicator()
	# Resetar índices selecionados
	tower_selected_index = -1
	sniper_selected_index = -1
	aoe_selected_index = -1
	shock_selected_index = -1
	slow_selected_index = -1
	boost_selected_index = -1
	barracks_selected_index = -1

func _on_upgrade_menu_closed() -> void:
	# Verificar qual menu está fechando e se deve ser mantido aberto
	if keep_menu_open:
		keep_menu_open = false
		return
	if keep_barracks_menu_open:
		keep_barracks_menu_open = false
		return
	if keep_sniper_menu_open:
		keep_sniper_menu_open = false
		return
	if keep_aoe_menu_open:
		keep_aoe_menu_open = false
		return
	if keep_shock_menu_open:
		keep_shock_menu_open = false
		return
	if keep_slow_menu_open:
		keep_slow_menu_open = false
		return
	if keep_boost_menu_open:
		keep_boost_menu_open = false
		return
	if keep_wall_menu_open:
		keep_wall_menu_open = false
		return
	_hide_range_indicator()

func _on_skill_collect_coins() -> void:
	# Atualizar progresso de quests
	if quest_manager:
		quest_manager.update_quest_progress(GameConstants.QuestType.USE_SKILLS, 1)
	if not skills_manager:
		return
	
	if not skills_manager.activate_collect_coins():
		return  # Cooldown ativo ou falha na ativação
	
	# Achievement: usar skill
	if not skills_manager.skill_used:
		achievement_manager.increment_progress("collect_skill")
		skills_manager.skill_used = true
	
	var total_collected = 0
	if coin_manager:
		for coin in coin_manager.get_dropped_coins():
			if not coin.collected:
				var value = coin.value
				coin.collected = true
				hero["coins"] += value
				total_collected += value
				_play_coin_sound()
	
	if total_collected > 0:
		print("Coletadas %d moedas!" % total_collected)

func _on_skill_slow_all() -> void:
	# Atualizar progresso de quests
	if quest_manager:
		quest_manager.update_quest_progress(GameConstants.QuestType.USE_SKILLS, 1)
	if not skills_manager:
		return
	
	if not skills_manager.activate_slow_all():
		return  # Cooldown ativo ou já está ativo
	
	# Aplicar slow em todos os inimigos através do sistema de efeitos
	for i in range(enemies.size()):
		var e = enemies[i]
		var enemy_idx = e.get("idx", i)
		if not enemy_effects.has(enemy_idx):
			enemy_effects[enemy_idx] = { "slow_time": 0.0, "slow_amount": 0.0, "freeze_time": 0.0, "fire_time": 0.0 }
		# Aplicar slow global (sobrescreve outros slows temporariamente)
		enemy_effects[enemy_idx].slow_time = GameConstants.SKILL_SLOW_ALL_DURATION
		enemy_effects[enemy_idx].slow_amount = GameConstants.SKILL_SLOW_ALL_AMOUNT
	
	print("Slow Global ativado por %.0f segundos!" % GameConstants.SKILL_SLOW_ALL_DURATION)

func _on_skill_damage_boost() -> void:
	# Atualizar progresso de quests
	if quest_manager:
		quest_manager.update_quest_progress(GameConstants.QuestType.USE_SKILLS, 1)
	if not skills_manager:
		return
	
	if skills_manager.activate_damage_boost():
		print("Boost de Dano ativado por %.0f segundos!" % GameConstants.SKILL_DAMAGE_BOOST_DURATION)

func _on_skill_speed_boost() -> void:
	if not skills_manager:
		return
	
	if skills_manager.activate_speed_boost():
		print("Boost de Velocidade ativado por %.0f segundos!" % GameConstants.SKILL_SPEED_BOOST_DURATION)

func _on_skill_magnetism() -> void:
	if not skills_manager:
		return
	
	if skills_manager.activate_magnetism():
		print("Magnetismo de Moedas ativado por %.0f segundos!" % GameConstants.SKILL_MAGNETISM_DURATION)

func _update_skills_ui() -> void:
	if not skills_panel:
		return
	
	if not skills_manager:
		return
	
	# Atualizar Skill 1: Coletar Moedas
	if skill_buttons.has("collect_coins"):
		var btn_data = skill_buttons["collect_coins"]
		var btn = btn_data.button
		var cooldown_label = btn_data.cooldown_label
		
		var cooldown = skills_manager.get_cooldown("collect_coins")
		if cooldown > 0.0:
			btn.disabled = true
			cooldown_label.text = "Cooldown: %.1fs" % cooldown
			var btn_style = StyleBoxFlat.new()
			btn_style.bg_color = Color(0.3, 0.3, 0.3)
			btn_style.border_color = Color(0.5, 0.5, 0.5)
			btn_style.border_width_left = 1
			btn_style.border_width_top = 1
			btn_style.border_width_right = 1
			btn_style.border_width_bottom = 1
			btn.add_theme_stylebox_override("normal", btn_style)
		else:
			btn.disabled = false
			cooldown_label.text = ""
			var btn_style = StyleBoxFlat.new()
			btn_style.bg_color = Color(0.2, 0.6, 0.2)
			btn_style.border_color = Color(0.3, 0.7, 0.3)
			btn_style.border_width_left = 1
			btn_style.border_width_top = 1
			btn_style.border_width_right = 1
			btn_style.border_width_bottom = 1
			btn.add_theme_stylebox_override("normal", btn_style)
	
	# Atualizar Skill 2: Boost de Dano
	if skill_buttons.has("damage_boost"):
		var btn_data = skill_buttons["damage_boost"]
		var btn = btn_data.button
		var cooldown_label = btn_data.cooldown_label
		
		var cooldown = skills_manager.get_cooldown("damage_boost")
		var active_time = skills_manager.get_active_time("damage_boost")
		if cooldown > 0.0 or skills_manager.is_skill_active("damage_boost"):
			btn.disabled = true
			if skills_manager.is_skill_active("damage_boost"):
				cooldown_label.text = "Ativo: %.1fs" % active_time
			else:
				cooldown_label.text = "Cooldown: %.1fs" % cooldown
			var btn_style = StyleBoxFlat.new()
			btn_style.bg_color = Color(0.3, 0.3, 0.3)
			btn_style.border_color = Color(0.5, 0.5, 0.5)
			btn_style.border_width_left = 1
			btn_style.border_width_top = 1
			btn_style.border_width_right = 1
			btn_style.border_width_bottom = 1
			btn.add_theme_stylebox_override("normal", btn_style)
		else:
			btn.disabled = false
			cooldown_label.text = ""
			var btn_style = StyleBoxFlat.new()
			btn_style.bg_color = Color(0.6, 0.2, 0.2)
			btn_style.border_color = Color(0.7, 0.3, 0.3)
			btn_style.border_width_left = 1
			btn_style.border_width_top = 1
			btn_style.border_width_right = 1
			btn_style.border_width_bottom = 1
			btn.add_theme_stylebox_override("normal", btn_style)
	
	# Atualizar Skill 3: Boost de Velocidade
	if skill_buttons.has("speed_boost"):
		var btn_data = skill_buttons["speed_boost"]
		var btn = btn_data.button
		var cooldown_label = btn_data.cooldown_label
		
		var cooldown = skills_manager.get_cooldown("speed_boost")
		var active_time = skills_manager.get_active_time("speed_boost")
		if cooldown > 0.0 or skills_manager.is_skill_active("speed_boost"):
			btn.disabled = true
			if skills_manager.is_skill_active("speed_boost"):
				cooldown_label.text = "Ativo: %.1fs" % active_time
			else:
				cooldown_label.text = "Cooldown: %.1fs" % cooldown
			var btn_style = StyleBoxFlat.new()
			btn_style.bg_color = Color(0.3, 0.3, 0.3)
			btn_style.border_color = Color(0.5, 0.5, 0.5)
			btn_style.border_width_left = 1
			btn_style.border_width_top = 1
			btn_style.border_width_right = 1
			btn_style.border_width_bottom = 1
			btn.add_theme_stylebox_override("normal", btn_style)
		else:
			btn.disabled = false
			cooldown_label.text = ""
			var btn_style = StyleBoxFlat.new()
			btn_style.bg_color = Color(0.2, 0.2, 0.6)
			btn_style.border_color = Color(0.3, 0.3, 0.7)
			btn_style.border_width_left = 1
			btn_style.border_width_top = 1
			btn_style.border_width_right = 1
			btn_style.border_width_bottom = 1
			btn.add_theme_stylebox_override("normal", btn_style)
	
	# Atualizar Skill 4: Slow Global
	if skill_buttons.has("slow_all"):
		var btn_data = skill_buttons["slow_all"]
		var btn = btn_data.button
		var cooldown_label = btn_data.cooldown_label
		
		var cooldown = skills_manager.get_cooldown("slow_all")
		var active_time = skills_manager.get_active_time("slow_all")
		if cooldown > 0.0 or skills_manager.is_skill_active("slow_all"):
			btn.disabled = true
			if skills_manager.is_skill_active("slow_all"):
				cooldown_label.text = "Ativo: %.1fs" % active_time
			else:
				cooldown_label.text = "Cooldown: %.1fs" % cooldown
			var btn_style = StyleBoxFlat.new()
			btn_style.bg_color = Color(0.3, 0.3, 0.3)
			btn_style.border_color = Color(0.5, 0.5, 0.5)
			btn_style.border_width_left = 1
			btn_style.border_width_top = 1
			btn_style.border_width_right = 1
			btn_style.border_width_bottom = 1
			btn.add_theme_stylebox_override("normal", btn_style)
		else:
			btn.disabled = false
			cooldown_label.text = ""
			var btn_style = StyleBoxFlat.new()
			btn_style.bg_color = Color(0.2, 0.4, 0.6)
			btn_style.border_color = Color(0.3, 0.5, 0.7)
			btn_style.border_width_left = 1
			btn_style.border_width_top = 1
			btn_style.border_width_right = 1
			btn_style.border_width_bottom = 1
			btn.add_theme_stylebox_override("normal", btn_style)
	
	# Atualizar Skill 5: Magnetismo de Moedas
	if skill_buttons.has("magnetism"):
		var btn_data = skill_buttons["magnetism"]
		var btn = btn_data.button
		var cooldown_label = btn_data.cooldown_label
		
		# Se tem o perk permanente, desabilitar a skill
		if skills_manager.has_coin_magnetism_perk:
			btn.disabled = true
			cooldown_label.text = "Perk Ativo"
			var btn_style = StyleBoxFlat.new()
			btn_style.bg_color = Color(0.2, 0.5, 0.2)
			btn_style.border_color = Color(0.3, 0.7, 0.3)
			btn_style.border_width_left = 1
			btn_style.border_width_top = 1
			btn_style.border_width_right = 1
			btn_style.border_width_bottom = 1
			btn.add_theme_stylebox_override("normal", btn_style)
		else:
			var cooldown = skills_manager.get_cooldown("magnetism")
			var active_time = skills_manager.get_active_time("magnetism")
			if cooldown > 0.0 or skills_manager.is_skill_active("magnetism"):
				btn.disabled = true
				if skills_manager.is_skill_active("magnetism"):
					cooldown_label.text = "Ativo: %.1fs" % active_time
				else:
					cooldown_label.text = "Cooldown: %.1fs" % cooldown
				var btn_style = StyleBoxFlat.new()
				btn_style.bg_color = Color(0.3, 0.3, 0.3)
				btn_style.border_color = Color(0.5, 0.5, 0.5)
				btn_style.border_width_left = 1
				btn_style.border_width_top = 1
				btn_style.border_width_right = 1
				btn_style.border_width_bottom = 1
				btn.add_theme_stylebox_override("normal", btn_style)
			else:
				btn.disabled = false
				cooldown_label.text = ""
				var btn_style = StyleBoxFlat.new()
				btn_style.bg_color = Color(0.2, 0.4, 0.6)
				btn_style.border_color = Color(0.3, 0.5, 0.7)
				btn_style.border_width_left = 1
				btn_style.border_width_top = 1
				btn_style.border_width_right = 1
				btn_style.border_width_bottom = 1
				btn.add_theme_stylebox_override("normal", btn_style)

func _create_dps_button() -> void:
	"""Cria o botão para abrir/fechar o menu de DPS no TopBar"""
	var tb = $CanvasLayer/HUD/TopBar
	if tb == null:
		return
	
	# Verificar se o botão já existe
	if tb.has_node("BtnDPS"):
		return
	
	var btn_dps = Button.new()
	btn_dps.name = "BtnDPS"
	btn_dps.text = "DPS"
	btn_dps.custom_minimum_size = Vector2(60, 28)
	# Posicionar usando anchors para ser responsivo (canto superior direito)
	# Ordem: Mute, Volume, Admin, Quests, Auto Benefício, DPS
	# DPS: 60px de largura, mais à direita (primeiro da direita para esquerda)
	btn_dps.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn_dps.offset_left = -60  # 60px de largura
	btn_dps.offset_top = 8
	btn_dps.offset_right = 0  # Borda direita
	btn_dps.offset_bottom = 36
	btn_dps.pressed.connect(_toggle_dps_menu)
	
	# Estilo do botão
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.3, 0.3, 0.5, 1.0)
	btn_style.border_color = Color(0.4, 0.4, 0.6)
	btn_style.border_width_left = 1
	btn_style.border_width_top = 1
	btn_style.border_width_right = 1
	btn_style.border_width_bottom = 1
	btn_dps.add_theme_stylebox_override("normal", btn_style)
	
	var btn_hover_style = btn_style.duplicate()
	btn_hover_style.bg_color = Color(0.4, 0.4, 0.6, 1.0)
	btn_dps.add_theme_stylebox_override("hover", btn_hover_style)
	
	btn_dps.add_theme_font_size_override("font_size", 12)
	btn_dps.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	tb.add_child(btn_dps)

func _create_boss_alert_ui() -> void:
	var canvas = $CanvasLayer
	if boss_alert_label and boss_alert_label.is_inside_tree():
		boss_alert_label.queue_free()
	var alert_label = Label.new()
	alert_label.name = "BossAlertLabel"
	alert_label.text = ""
	alert_label.visible = false
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	alert_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	alert_label.add_theme_font_size_override("font_size", 36)
	alert_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))
	alert_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	alert_label.add_theme_constant_override("outline_size", 3)
	alert_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	alert_label.size = Vector2(800, 140)
	alert_label.position = Vector2(-alert_label.size.x * 0.5, -alert_label.size.y * 0.5 + 100)  # Abaixo do centro
	canvas.add_child(alert_label)
	boss_alert_label = alert_label
	
	if boss_alert_player == null:
		boss_alert_player = AudioStreamPlayer.new()
		boss_alert_player.name = "BossAlertPlayer"
		add_child(boss_alert_player)

func _load_boss_warning_sound() -> void:
	boss_warning_sound = _try_load_music("res://assets/sounds/aproaching.wav")
	if boss_warning_sound == null:
		boss_warning_sound = _try_load_music("res://assets/sounds/approaching.wav")

func _show_boss_warning(message: String) -> void:
	if boss_alert_label == null:
		return
	# Esconder outros avisos temporariamente para evitar sobreposição
	if weather_alert_label and weather_alert_label.visible:
		weather_alert_timer = 0.0  # Forçar fechamento
		weather_alert_label.visible = false
	# Wave especial pode permanecer visível, mas o boss alert fica abaixo do centro
	boss_alert_label.text = message
	boss_alert_label.visible = true
	boss_alert_timer = boss_alert_duration
	_play_boss_warning_sound()

func _play_boss_warning_sound() -> void:
	if boss_warning_sound == null:
		return
	if boss_alert_player == null:
		boss_alert_player = AudioStreamPlayer.new()
		boss_alert_player.name = "BossAlertPlayer"
		add_child(boss_alert_player)
	boss_alert_player.stream = boss_warning_sound
	boss_alert_player.play()

func _create_special_wave_alert_ui() -> void:
	var canvas = $CanvasLayer
	if special_wave_alert_label and special_wave_alert_label.is_inside_tree():
		special_wave_alert_label.queue_free()
	var alert_label = Label.new()
	alert_label.name = "SpecialWaveAlertLabel"
	alert_label.text = ""
	alert_label.visible = false
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	alert_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	alert_label.add_theme_font_size_override("font_size", 42)
	alert_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))  # Dourado
	alert_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	alert_label.add_theme_constant_override("outline_size", 4)
	alert_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	alert_label.size = Vector2(900, 180)
	alert_label.position = Vector2(-alert_label.size.x * 0.5, -alert_label.size.y * 0.5)  # Centro da tela
	canvas.add_child(alert_label)
	special_wave_alert_label = alert_label

func _show_special_wave_alert(wave_number: int, _special_wave_type: WaveManager.SpecialWaveType) -> void:
	if special_wave_alert_label == null:
		return
	
	# Não mostrar se já está visível (evitar repetição)
	if special_wave_alert_label.visible and special_wave_alert_timer > 0.0:
		return
	
	# Esconder outros avisos temporariamente para evitar sobreposição
	if weather_alert_label and weather_alert_label.visible:
		weather_alert_timer = 0.0  # Forçar fechamento
		weather_alert_label.visible = false
	# Boss alert pode permanecer, mas wave especial tem prioridade visual
	var wave_name = wave_manager.get_special_wave_name()
	var wave_desc = wave_manager.get_special_wave_description()
	special_wave_alert_label.text = "%s\nWave %d Especial!\n%s" % [wave_name, wave_number, wave_desc]
	# Resetar alpha para totalmente visível
	special_wave_alert_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	special_wave_alert_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	special_wave_alert_label.visible = true
	special_wave_alert_timer = GameConstants.SPECIAL_WAVE_ALERT_DURATION

func _check_perfect_wave_bonus() -> void:
	"""Verifica se completou wave perfeita e dá bônus"""
	if current_special_wave_type == WaveManager.SpecialWaveType.PERFECT_WAVE and not perfect_wave_bonus_given:
		# Verificar se não perdeu HP durante a wave
		if base_hp >= current_wave_base_hp_start:
			perfect_wave_bonus_given = true
			# Dar bônus especial: moedas + esmeraldas
			var bonus_coins = get_wave_completion_bonus() * 3  # 3x o bônus normal
			hero["coins"] += bonus_coins
			if special_currency_manager:
				special_currency_manager.add_emeralds(5, "perfect_wave")
			# Mostrar mensagem
			_show_special_wave_alert(wave_manager.wave, WaveManager.SpecialWaveType.PERFECT_WAVE)
			special_wave_alert_timer = GameConstants.SPECIAL_WAVE_ALERT_DURATION  # Usar duração padrão com fade out
			special_wave_alert_label.text = "🎯 WAVE PERFEITA!\n+%d Moedas\n+5 Esmeraldas" % bonus_coins

func _create_weather_ui() -> void:
	"""Cria a UI para eventos climáticos"""
	var canvas = $CanvasLayer
	# Criar label de alerta de clima
	if weather_alert_label and weather_alert_label.is_inside_tree():
		weather_alert_label.queue_free()
	var alert_label = Label.new()
	alert_label.name = "WeatherAlertLabel"
	alert_label.text = ""
	alert_label.visible = false
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	alert_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	alert_label.add_theme_font_size_override("font_size", 32)  # Reduzido de 36
	alert_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0, 0.85))  # Azul claro com opacidade
	alert_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))  # Outline com opacidade reduzida
	alert_label.add_theme_constant_override("outline_size", 3)
	alert_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)  # Mudado para topo
	alert_label.size = Vector2(800, 80)  # Reduzido altura
	alert_label.position = Vector2(-alert_label.size.x * 0.5, 60)  # Posicionado no topo do labirinto, abaixo da barra
	canvas.add_child(alert_label)
	weather_alert_label = alert_label
	
	# Criar overlay para noite (escurecimento apenas do labirinto)
	if weather_overlay and weather_overlay.is_inside_tree():
		weather_overlay.queue_free()
	var overlay = ColorRect.new()
	overlay.name = "WeatherOverlay"
	overlay.color = Color(0, 0, 0, 0)  # Inicialmente transparente
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Não bloquear cliques
	# Posicionar sobre o labirinto (não tela inteira)
	var bar_height: float = 44.0
	var map_width := float(GameConstants.GRID_COLS * GameConstants.TILE_SIZE)
	var map_height := float(GameConstants.GRID_ROWS * GameConstants.TILE_SIZE)
	overlay.position = Vector2(0, bar_height)  # Abaixo da barra
	overlay.size = Vector2(map_width, map_height)  # Tamanho do labirinto
	canvas.add_child(overlay)
	weather_overlay = overlay

func _show_weather_alert(_wave_number: int) -> void:
	"""Mostra alerta de mudança de clima"""
	if weather_alert_label == null or weather_manager == null:
		return
	
	# Não mostrar se já está visível (evitar repetição)
	if weather_alert_label.visible and weather_alert_timer > 0.0:
		return
	
	# Esconder outros avisos temporariamente para evitar sobreposição
	if boss_alert_label and boss_alert_label.visible:
		boss_alert_timer = 0.0  # Forçar fechamento
		boss_alert_label.visible = false
	if special_wave_alert_label and special_wave_alert_label.visible:
		# Não fechar wave especial, mas ajustar posição
		pass
	
	var weather_name = weather_manager.get_weather_name()
	var weather_desc = weather_manager.get_weather_description()
	if weather_name != "":
		weather_alert_label.text = "%s\nClima: %s" % [weather_name, weather_desc]
		weather_alert_label.visible = true
		weather_alert_timer = 8.0  # Mostrar por 8 segundos

func _apply_weather_effects() -> void:
	"""Aplica efeitos visuais do clima"""
	if weather_manager == null:
		return
	
	# Atualizar overlay de noite (apenas no labirinto)
	if weather_overlay:
		# Garantir que o overlay está posicionado corretamente sobre o labirinto
		var bar_height: float = 44.0
		var map_width := float(GameConstants.GRID_COLS * GameConstants.TILE_SIZE)
		var map_height := float(GameConstants.GRID_ROWS * GameConstants.TILE_SIZE)
		weather_overlay.position = Vector2(0, bar_height)
		weather_overlay.size = Vector2(map_width, map_height)
		
		# Overlay de noite agora é desenhado diretamente na função _draw() após os monstros
		# Manter transparente aqui (não usar mais o ColorRect para overlay de noite)
		weather_overlay.color = Color(0, 0, 0, 0)
	
	# Inicializar partículas de chuva (apenas sobre o labirinto)
	if weather_manager.is_rainy():
		if weather_rain_particles.is_empty():
			# Criar partículas de chuva apenas sobre o labirinto
			var bar_height: float = 44.0
			var map_width := float(GameConstants.GRID_COLS * GameConstants.TILE_SIZE)
			var map_height := float(GameConstants.GRID_ROWS * GameConstants.TILE_SIZE)
			for i in range(250):  # Mais partículas para efeito mais denso
				weather_rain_particles.append({
					"pos": Vector2(randf() * map_width, bar_height + randf() * map_height),
					"speed": 350.0 + randf() * 250.0,  # Mais rápido
					"length": 15.0 + randf() * 25.0  # Mais longo
				})
	else:
		weather_rain_particles.clear()
	
	# Inicializar nuvens para névoa (apenas sobre o labirinto)
	if weather_manager.has_visibility_reduction():
		if weather_clouds.is_empty():
			# Criar nuvens apenas sobre o labirinto
			var bar_height: float = 44.0
			var map_width := float(GameConstants.GRID_COLS * GameConstants.TILE_SIZE)
			var map_height := float(GameConstants.GRID_ROWS * GameConstants.TILE_SIZE)
			for i in range(40):  # Mais nuvens para efeito mais denso
				weather_clouds.append({
					"pos": Vector2(randf() * map_width, bar_height + randf() * map_height),
					"size": 60.0 + randf() * 120.0,  # Nuvens maiores
					"alpha": 0.35 + randf() * 0.35,  # Mais opacas
					"speed": 15.0 + randf() * 25.0
				})
	else:
		weather_clouds.clear()
	
	# Inicializar partículas de neve
	if weather_manager.is_snowy():
		if weather_snow_particles.is_empty():
			# Criar partículas de neve apenas sobre o labirinto
			var bar_height: float = 44.0
			var map_width := float(GameConstants.GRID_COLS * GameConstants.TILE_SIZE)
			var map_height := float(GameConstants.GRID_ROWS * GameConstants.TILE_SIZE)
			for i in range(150):  # Flocos de neve
				weather_snow_particles.append({
					"pos": Vector2(randf() * map_width, bar_height + randf() * map_height),
					"speed_y": 30.0 + randf() * 50.0,  # Velocidade vertical (lenta)
					"speed_x": -10.0 + randf() * 20.0,  # Movimento horizontal (deriva)
					"size": 2.0 + randf() * 4.0,  # Tamanho do floco
					"rotation": randf() * PI * 2.0,  # Rotação inicial
					"rotation_speed": -2.0 + randf() * 4.0  # Velocidade de rotação
				})
	else:
		weather_snow_particles.clear()

func _update_weather_visuals(delta: float) -> void:
	"""Atualiza efeitos visuais do clima"""
	if weather_manager == null:
		return
	
	# Atualizar partículas de chuva (apenas sobre o labirinto)
	if weather_manager.is_rainy():
		var bar_height: float = 44.0
		var map_width := float(GameConstants.GRID_COLS * GameConstants.TILE_SIZE)
		var map_height := float(GameConstants.GRID_ROWS * GameConstants.TILE_SIZE)
		var labirinto_bottom = bar_height + map_height
		for i in range(weather_rain_particles.size()):
			var p = weather_rain_particles[i]
			p.pos.y += p.speed * delta
			# Reposicionar quando sair do labirinto
			if p.pos.y > labirinto_bottom:
				p.pos.y = bar_height - p.length
				p.pos.x = randf() * map_width
	else:
		weather_rain_particles.clear()
	
	# Atualizar nuvens (apenas sobre o labirinto)
	if weather_manager.has_visibility_reduction():
		var bar_height: float = 44.0
		var map_width := float(GameConstants.GRID_COLS * GameConstants.TILE_SIZE)
		var map_height := float(GameConstants.GRID_ROWS * GameConstants.TILE_SIZE)
		for i in range(weather_clouds.size()):
			var c = weather_clouds[i]
			c.pos.x += c.speed * delta
			# Reposicionar quando sair do labirinto
			if c.pos.x > map_width:
				c.pos.x = -c.size
				c.pos.y = bar_height + randf() * map_height
	
	# Atualizar partículas de neve (apenas sobre o labirinto)
	if weather_manager.is_snowy():
		var bar_height: float = 44.0
		var map_width := float(GameConstants.GRID_COLS * GameConstants.TILE_SIZE)
		var map_height := float(GameConstants.GRID_ROWS * GameConstants.TILE_SIZE)
		var labirinto_bottom = bar_height + map_height
		for i in range(weather_snow_particles.size()):
			var s = weather_snow_particles[i]
			# Movimento vertical (queda)
			s.pos.y += s.speed_y * delta
			# Movimento horizontal (deriva)
			s.pos.x += s.speed_x * delta
			# Rotação
			s.rotation += s.rotation_speed * delta
			# Reposicionar quando sair do labirinto
			if s.pos.y > labirinto_bottom:
				s.pos.y = bar_height - 10.0
				s.pos.x = randf() * map_width
			# Reposicionar horizontalmente se sair das bordas
			if s.pos.x < 0:
				s.pos.x = map_width
			elif s.pos.x > map_width:
				s.pos.x = 0

func _draw_weather_effects() -> void:
	"""Desenha efeitos visuais do clima (apenas sobre o labirinto)"""
	if weather_manager == null:
		return
	
	# Obter limites do labirinto
	var map_width := float(GameConstants.GRID_COLS * GameConstants.TILE_SIZE)
	var map_height := float(GameConstants.GRID_ROWS * GameConstants.TILE_SIZE)
	
	# Função auxiliar para verificar se uma posição está dentro do labirinto
	var is_inside_maze = func(pos: Vector2, margin: float = 0.0) -> bool:
		return pos.x >= -margin and pos.x <= map_width + margin and \
			   pos.y >= -margin and pos.y <= map_height + margin
	
	# Desenhar partículas de chuva (mais visíveis) - apenas dentro do labirinto
	if weather_manager.is_rainy():
		for p in weather_rain_particles:
			# Verificar se a partícula está dentro do labirinto
			if not is_inside_maze.call(p.pos, 10.0):  # Margem de 10px para partículas próximas à borda
				continue
			var end_pos = p.pos + Vector2(0, p.length)
			# Verificar se o ponto final também está dentro
			if not is_inside_maze.call(end_pos, 10.0):
				# Clamp o ponto final para dentro do labirinto
				end_pos.y = clamp(end_pos.y, 0.0, map_height)
			# Chuva mais visível e com leve brilho
			draw_line(p.pos, end_pos, Color(0.6, 0.8, 1.0, 0.7), 1.5)  # Mais opaco e mais grosso
			# Adicionar leve brilho
			draw_line(p.pos, end_pos, Color(0.8, 0.9, 1.0, 0.3), 0.5)
	
	# Desenhar nuvens (névoa) - melhoradas, apenas dentro do labirinto
	if weather_manager.has_visibility_reduction():
		for c in weather_clouds:
			# Verificar se a nuvem está dentro do labirinto (com margem para nuvens grandes)
			var cloud_margin = c.size * 1.2  # Margem maior para nuvens grandes
			if not is_inside_maze.call(c.pos, cloud_margin):
				continue
			# Desenhar nuvem com gradiente (múltiplos círculos sobrepostos)
			var cloud_color = Color(0.6, 0.6, 0.65, c.alpha)
			# Círculo principal
			draw_circle(c.pos, c.size, cloud_color)
			# Círculos menores para dar profundidade (apenas se estiverem dentro)
			var offset1 = c.pos + Vector2(-c.size * 0.3, -c.size * 0.2)
			var offset2 = c.pos + Vector2(c.size * 0.3, -c.size * 0.2)
			if is_inside_maze.call(offset1, c.size * 0.6):
				draw_circle(offset1, c.size * 0.6, Color(0.65, 0.65, 0.7, c.alpha * 0.8))
			if is_inside_maze.call(offset2, c.size * 0.6):
				draw_circle(offset2, c.size * 0.6, Color(0.65, 0.65, 0.7, c.alpha * 0.8))
	
	# Desenhar partículas de neve (flocos) - apenas dentro do labirinto
	if weather_manager.is_snowy():
		for s in weather_snow_particles:
			# Verificar se o floco está dentro do labirinto
			if not is_inside_maze.call(s.pos, s.size):
				continue
			# Desenhar floco de neve (estrela simples rotacionada)
			var snow_color = Color(1.0, 1.0, 1.0, 0.8)  # Branco com opacidade
			# Desenhar floco como pequeno círculo com linhas (estrela simples)
			draw_circle(s.pos, s.size, snow_color)
			# Adicionar linhas para parecer mais com floco de neve
			var dir1 = Vector2(cos(s.rotation), sin(s.rotation)) * s.size
			var dir2 = Vector2(cos(s.rotation + PI/3), sin(s.rotation + PI/3)) * s.size
			var dir3 = Vector2(cos(s.rotation + 2*PI/3), sin(s.rotation + 2*PI/3)) * s.size
			draw_line(s.pos - dir1, s.pos + dir1, snow_color, 1.0)
			draw_line(s.pos - dir2, s.pos + dir2, snow_color, 1.0)
			draw_line(s.pos - dir3, s.pos + dir3, snow_color, 1.0)

# Função _toggle_music removida - agora o volume é controlado apenas pelo slider

func _toggle_auto_benefit() -> void:
	"""Alterna entre escolha manual e automática de benefícios"""
	auto_choose_benefits = not auto_choose_benefits
	_save_user_preferences()
	_update_auto_benefit_button()

func _update_auto_benefit_button() -> void:
	"""Atualiza o texto e estilo do botão de auto benefício"""
	var tb = $CanvasLayer/HUD/TopBar
	if not tb.has_node("BtnAutoBenefit"):
		return
	
	var btn = tb.get_node("BtnAutoBenefit")
	
	# Ajustar texto baseado no tamanho da tela
	var screen_width = get_viewport().get_visible_rect().size.x
	var short_text = screen_width < 1200
	
	if auto_choose_benefits:
		btn.text = "Auto: ON" if short_text else "Auto Benefício: ON"
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.3, 0.6, 0.9)  # Azul quando ON
		style.border_color = Color(0.2, 0.5, 0.8)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		btn.add_theme_stylebox_override("normal", style)
		var hover_style = style.duplicate()
		hover_style.bg_color = Color(0.2, 0.4, 0.7, 0.9)  # Azul mais claro no hover
		btn.add_theme_stylebox_override("hover", hover_style)
	else:
		btn.text = "Auto: OFF" if short_text else "Auto Benefício: OFF"
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.2, 0.4, 0.9)  # Azul escuro quando OFF
		style.border_color = Color(0.2, 0.3, 0.5)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		btn.add_theme_stylebox_override("normal", style)
		var hover_style = style.duplicate()
		hover_style.bg_color = Color(0.15, 0.25, 0.5, 0.9)  # Azul um pouco mais claro no hover
		btn.add_theme_stylebox_override("hover", hover_style)
	
	# Reposicionar todos os botões após atualizar o texto (apenas Auto Benefício)
	if tb.has_node("BtnAutoBenefit"):
		var btn_auto = tb.get_node("BtnAutoBenefit")
		btn_auto.layout_mode = 1
		btn_auto.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		btn_auto.offset_left = -240
		btn_auto.offset_top = 8
		btn_auto.offset_right = -90
		btn_auto.offset_bottom = 36

func _reposition_right_side_buttons(tb: Panel) -> void:
	"""Reposiciona todos os botões da direita da HUD com espaçamento correto"""
	# Ordem (da direita para esquerda): DPS, Auto Benefício, Quests, Admin, Volume
	# Todos com 10px de espaçamento entre eles
	# Adicionar 20px de margem à direita para evitar corte
	
	# 1. DPS (mais à direita, com margem de 20px)
	if tb.has_node("BtnDPS"):
		var btn_dps = tb.get_node("BtnDPS")
		btn_dps.layout_mode = 1
		btn_dps.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		btn_dps.offset_left = -80  # 60px de largura + 20px de margem
		btn_dps.offset_top = 8
		btn_dps.offset_right = -20  # 20px de margem à direita
		btn_dps.offset_bottom = 36
	
	# 2. Auto Benefício (150px para texto completo)
	if tb.has_node("BtnAutoBenefit"):
		var btn_auto = tb.get_node("BtnAutoBenefit")
		btn_auto.layout_mode = 1
		btn_auto.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		btn_auto.offset_left = -350  # 10px após Admin (Quests removido)
		btn_auto.offset_top = 8
		btn_auto.offset_right = -200  # 10px antes de DPS
		btn_auto.offset_bottom = 36
	
	# 3. Quests removido - agora está no menu inicial
	
	# 4. Admin (100px)
	if tb.has_node("BtnAdmin"):
		var btn_admin = tb.get_node("BtnAdmin")
		btn_admin.layout_mode = 1
		btn_admin.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		btn_admin.offset_left = -460  # 10px após Volume
		btn_admin.offset_top = 8
		btn_admin.offset_right = -360  # 100px de largura, 10px antes de Quests
		btn_admin.offset_bottom = 36
	
	# 5. Volume (130px fixo)
	if tb.has_node("MusicVolumeContainer"):
		var volume_container = tb.get_node("MusicVolumeContainer")
		volume_container.layout_mode = 1
		volume_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		volume_container.offset_left = -580  # Posição ajustada
		volume_container.offset_top = 8
		volume_container.offset_right = -450  # 130px de largura fixa, 10px antes de Admin
		volume_container.offset_bottom = 36

func _on_music_volume_changed(value: float) -> void:
	music_volume = value
	var music_player = get_node_or_null("MusicPlayer")
	if music_player and not music_muted:
		music_player.volume_db = music_volume
	
	# Salvar preferência
	_save_music_settings()

func _save_user_preferences() -> void:
	"""Salva preferências do usuário (incluindo auto benefício)"""
	var config = ConfigFile.new()
	config.set_value("game", "auto_choose_benefits", auto_choose_benefits)
	var config_path = "user://user_preferences.cfg"
	config.save(config_path)

func _load_user_preferences() -> void:
	"""Carrega preferências do usuário"""
	var config = ConfigFile.new()
	var config_path = "user://user_preferences.cfg"
	var err = config.load(config_path)
	if err == OK:
		auto_choose_benefits = config.get_value("game", "auto_choose_benefits", false)

func _save_music_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "music_muted", music_muted)
	var config_path = "user://audio_settings.cfg"
	config.save(config_path)

func _load_music_settings() -> void:
	var config = ConfigFile.new()
	var config_path = "user://audio_settings.cfg"
	var err = config.load(config_path)
	if err == OK:
		music_volume = config.get_value("audio", "music_volume", -7.0)
		music_muted = config.get_value("audio", "music_muted", false)
		
		# Atualizar slider se existir
		var tb = $CanvasLayer/HUD/TopBar
		if tb:
			var container = tb.get_node_or_null("MusicVolumeContainer")
			if container:
				var slider = container.get_node_or_null("MusicVolumeSlider")
				if slider:
					slider.value = music_volume
					music_volume_slider = slider

func _create_death_animation(pos: Vector2) -> void:
	# Criar animação de morte (fade out e shrink)
	var death_anim = {
		"pos": pos,
		"time": 0.0,
		"max_time": 0.5,  # meio segundo de animação
		"scale": 1.0,
		"alpha": 1.0
	}
	# Usar VisualEffectsManager se disponível
	if visual_effects_manager:
		visual_effects_manager.create_death_animation(pos)
	else:
		enemy_death_animations.append(death_anim)

# ========== ACHIEVEMENTS TRACKING ==========

func _track_enemy_kill(is_boss: bool) -> void:
	total_kills += 1
	
	# Rastrear achievements de kills
	achievement_manager.increment_progress("first_kill")
	achievement_manager.increment_progress("kill_100")
	achievement_manager.increment_progress("kill_1000")
	achievement_manager.increment_progress("kill_10000")
	achievement_manager.increment_progress("kill_50000")
	
	# Atualizar progresso de quests
	if quest_manager:
		quest_manager.update_quest_progress(GameConstants.QuestType.KILL_ENEMIES, 1)
	
	# Rastrear kills de boss
	if is_boss:
		total_boss_kills += 1
		achievement_manager.increment_progress("boss_kill")
		achievement_manager.increment_progress("boss_kill_10")
		achievement_manager.increment_progress("boss_kill_50")
		achievement_manager.increment_progress("boss_kill_100")
		
		# Atualizar progresso de quests de boss
		if quest_manager:
			quest_manager.update_quest_progress(GameConstants.QuestType.KILL_BOSSES, 1)

func _check_time_achievements() -> void:
	"""Verifica e atualiza achievements relacionados ao tempo de jogo"""
	if not achievement_manager:
		return
	
	var time_seconds = int(game_time)
	
	# Verificar cada achievement de tempo
	achievement_manager.set_progress("play_time_5min", time_seconds)
	achievement_manager.set_progress("play_time_15min", time_seconds)
	achievement_manager.set_progress("play_time_30min", time_seconds)
	achievement_manager.set_progress("play_time_1hour", time_seconds)
	achievement_manager.set_progress("play_time_2hours", time_seconds)
	achievement_manager.set_progress("play_time_5hours", time_seconds)

func _track_tower_built(tower_type: String) -> void:
	towers_built += 1
	tower_types_built[tower_type] = true
	
	# Rastrear achievements de torres
	achievement_manager.increment_progress("build_10_towers")
	achievement_manager.increment_progress("build_50_towers")
	achievement_manager.increment_progress("build_100_towers")
	
	# Atualizar progresso de quests
	if quest_manager:
		quest_manager.update_quest_progress(GameConstants.QuestType.BUILD_TOWERS, 1)
	
	# Verificar se construiu todos os tipos
	var all_types = ["tower", "slow_tower", "aoe_tower", "sniper_tower", "boost_tower", "shock_tower", "barracks"]
	var built_count = 0
	for type in all_types:
		if tower_types_built.has(type):
			built_count += 1
	achievement_manager.set_progress("build_all_tower_types", built_count)
	
	# Verificar se construiu todos os tipos de estruturas em uma partida
	if built_count >= 7:
		achievement_manager.set_progress("all_tower_types_one_game", 1)

func _track_coin_spent(amount: int) -> void:
	total_coins_spent += amount
	achievement_manager.increment_progress("spend_5000_coins", amount)
	achievement_manager.increment_progress("spend_100000_coins", amount)
	
	# Atualizar progresso de quests
	if quest_manager:
		quest_manager.update_quest_progress(GameConstants.QuestType.SPEND_COINS, amount)

func _track_wall_built() -> void:
	walls_built += 1
	achievement_manager.set_progress("build_5_walls", walls_built)
	achievement_manager.set_progress("build_50_walls", walls_built)

func _check_perfect_wave() -> void:
	# Verificar se a onda foi completada sem perder vida na base
	if base_hp >= current_wave_base_hp_start:
		perfect_waves += 1
		achievement_manager.increment_progress("perfect_wave")
		achievement_manager.set_progress("perfect_wave_10", perfect_waves)
		achievement_manager.set_progress("perfect_wave_50", perfect_waves)
		achievement_manager.set_progress("perfect_wave_100", perfect_waves)
		
		# Atualizar progresso de quests
		if quest_manager:
			quest_manager.update_quest_progress(GameConstants.QuestType.PERFECT_WAVES, 1)
		
		# Verificar se sobreviveu 100 waves sem dano
		if perfect_waves >= 100:
			achievement_manager.set_progress("survive_100_waves_no_damage", 100)

func _apply_perk_effects() -> void:
	var effects = perk_manager.apply_perk_effects(self)
	perk_effects = effects
	
	# Aplicar efeitos de perks (sobre valores já modificados por prestígio)
	if effects.has("starting_coins"):
		hero["coins"] += int(effects["starting_coins"])
	
	if effects.has("starting_hp"):
		var hp_bonus = int(effects["starting_hp"])
		base_hp += hp_bonus
		base_hp_max += hp_bonus  # Atualizar HP máximo também
	
	# Aplicar chance de drop de moeda (sobre valor já modificado por prestígio)
	if effects.has("coin_drop_chance"):
		coin_drop_chance += effects["coin_drop_chance"]
		# Limitar a 100% (embora não deva chegar lá)
		coin_drop_chance = min(coin_drop_chance, 1.0)
	
	# Aplicar bônus de dano do herói (multiplicador sobre valor já modificado)
	if effects.has("hero_damage"):
		var boost = effects["hero_damage"]
		hero["damage"] *= (1.0 + boost)
	
	# Aplicar bônus de velocidade de tiro do herói (multiplicador - reduz fire_rate)
	if effects.has("hero_fire_rate"):
		var boost = effects["hero_fire_rate"]
		hero["fire_rate"] *= (1.0 - boost)  # Reduz fire_rate = mais rápido
		hero["fire_rate"] = max(0.1, hero["fire_rate"])  # Limitar mínimo
	
	# Aplicar bônus de dano das torres (multiplicador global sobre valor já modificado)
	if effects.has("tower_damage"):
		var boost = effects["tower_damage"]
		global_tower_damage_boost *= (1.0 + boost)
	
	# Aplicar bônus de alcance das torres (será aplicado quando torres forem criadas/atualizadas)
	# Armazenado em perk_effects para uso posterior
	
	# Aplicar bônus de durabilidade das muralhas (multiplicador)
	if effects.has("wall_hp"):
		var boost = effects["wall_hp"]
		wall_hp_multiplier *= (1.0 + boost)
		# Atualizar HP máximo de todas as muralhas existentes
		_update_all_walls_max_hp()
	
	# Verificar se tem perk de magnetismo permanente
	var has_perk = effects.has("coin_magnetism") and effects["coin_magnetism"] > 0
	if skills_manager:
		skills_manager.set_coin_magnetism_perk(has_perk)

func _apply_talisman_bonuses() -> void:
	"""Aplica bônus permanentes de talismãs equipados (sobre valores já modificados por prestígio e perks)"""
	if not item_manager:
		return
	
	var talisman_effects = item_manager.get_all_effects()
	
	# Aplicar bônus de dano das torres (multiplicador sobre valor já modificado)
	if talisman_effects.has("tower_damage_boost"):
		var boost = talisman_effects["tower_damage_boost"]
		global_tower_damage_boost *= (1.0 + boost)
	
	# Aplicar bônus de alcance das torres (multiplicador sobre valor já modificado)
	if talisman_effects.has("tower_range_boost"):
		var boost = talisman_effects["tower_range_boost"]
		global_tower_range_boost *= (1.0 + boost)
		# Aplicar boost em todas as torres existentes
		_apply_range_boost_to_all_towers()
	
	# Aplicar bônus de dano da base (multiplicador no dano do herói sobre valor já modificado)
	if talisman_effects.has("base_damage_boost"):
		var boost = talisman_effects["base_damage_boost"]
		hero["damage"] *= (1.0 + boost)
	
	# Aplicar bônus de chance de drop de moedas (aditivo sobre valor já modificado)
	if talisman_effects.has("coin_drop_chance_boost"):
		var boost = talisman_effects["coin_drop_chance_boost"]
		coin_drop_chance += boost
		coin_drop_chance = min(coin_drop_chance, 1.0)
	
	# Aplicar bônus de chance de crítico (aditivo sobre valor já modificado)
	if talisman_effects.has("critical_chance_boost"):
		var boost = talisman_effects["critical_chance_boost"]
		hero["crit_chance"] += boost
		hero["crit_chance"] = min(hero["crit_chance"], 1.0)
	
	# Aplicar bônus de dano crítico das torres (multiplicador sobre valor já modificado)
	if talisman_effects.has("tower_crit_damage_boost"):
		var boost = talisman_effects["tower_crit_damage_boost"]
		# Armazenar em perk_effects para uso nas torres
		if not perk_effects.has("tower_crit_damage_multiplier"):
			perk_effects["tower_crit_damage_multiplier"] = 1.0
		perk_effects["tower_crit_damage_multiplier"] += boost
	
	# Nota: Bônus de cadência das torres será aplicado dinamicamente
	# quando as torres calculam fire_rate

func _apply_range_boost_to_all_towers() -> void:
	"""Aplica o boost de alcance global a todas as torres existentes"""
	# Aplicar em torres normais
	for t in towers:
		var base_range = t.get("base_range", 260.0)
		if base_range == 0:
			base_range = 260.0  # Fallback se não tiver base_range
		t["base_range"] = base_range
		t["range"] = base_range * global_tower_range_boost
	
	# Aplicar em slow towers
	for st in slow_towers:
		var base_range = st.get("base_range", 200.0)
		if base_range == 0:
			base_range = 200.0
		st["base_range"] = base_range
		st["range"] = base_range * global_tower_range_boost
	
	# Aplicar em AOE towers
	for aoe in aoe_towers:
		var base_range = aoe.get("base_range", 180.0)
		if base_range == 0:
			base_range = 180.0
		aoe["base_range"] = base_range
		aoe["range"] = base_range * global_tower_range_boost
	
	# Aplicar em sniper towers
	for sniper in sniper_towers:
		var base_range = sniper.get("base_range", 400.0)
		if base_range == 0:
			base_range = 400.0
		sniper["base_range"] = base_range
		sniper["range"] = base_range * global_tower_range_boost
	
	# Aplicar em boost towers
	for boost in boost_towers:
		var base_range = boost.get("base_range", 150.0)
		if base_range == 0:
			base_range = 150.0
		boost["base_range"] = base_range
		boost["range"] = base_range * global_tower_range_boost
	
	# Aplicar em shock towers
	for shock in shock_towers:
		var base_range = shock.get("base_range", 200.0)
		if base_range == 0:
			base_range = 200.0
		shock["base_range"] = base_range
		shock["range"] = base_range * global_tower_range_boost

func _recalculate_all_bonuses() -> void:
	"""Recalcula todos os bônus do zero (usado quando talismãs são equipados/desequipados)"""
	# Resetar valores para base
	hero["damage"] = hero_damage_base
	hero["fire_rate"] = hero_fire_rate_base
	hero["crit_chance"] = hero_crit_chance_base
	base_hp = base_hp_base
	base_hp_max = base_hp_base  # Resetar HP máximo também
	global_tower_damage_boost = global_tower_damage_boost_base
	global_tower_range_boost = 1.0  # Resetar multiplicador de alcance das torres
	coin_drop_chance = coin_drop_chance_base
	wall_hp_multiplier = 1.0  # Resetar multiplicador de HP das muralhas
	
	# Reaplicar todos os bônus na ordem correta
	_apply_prestige_bonuses()
	_apply_perk_effects()
	_apply_talisman_bonuses()
	
	# Garantir que base_hp_max está sincronizado com base_hp após todos os bônus
	# base_hp_max deve ser igual ao base_hp atual (que inclui todos os bônus)
	base_hp_max = max(base_hp_max, base_hp)  # Usar max para garantir que nunca seja menor
	# Garantir que base_hp atual não excede o máximo
	base_hp = min(base_hp, base_hp_max)
	
	# Atualizar HP máximo de todas as muralhas existentes
	_update_all_walls_max_hp()
	
	# Atualizar boost global nas torres
	if tower_system_manager:
		tower_system_manager.set_global_damage_boost(global_tower_damage_boost)

func _on_item_equipped(_item: EquippableItem) -> void:
	"""Chamado quando um item é equipado - recalcula todos os bônus"""
	_recalculate_all_bonuses()

func _on_item_unequipped(_item: EquippableItem) -> void:
	"""Chamado quando um item é desequipado - recalcula todos os bônus"""
	_recalculate_all_bonuses()
	
func _on_resource_loading_progress(progress: float) -> void:
	_update_loading_progress(progress)

func _on_coin_collected(value: int) -> void:
	hero["coins"] += value
	total_coins_collected += value

func _track_coin_collected(value: int) -> void:
	total_coins_collected += value
	
	# Atualizar progresso de quests
	if quest_manager:
		quest_manager.update_quest_progress(GameConstants.QuestType.COLLECT_COINS, value)

func _update_game_tooltip(delta: float) -> void:
	if game_tooltip == null:
		return
	
	var tooltip_text_label = game_tooltip.get_node("Panel/TooltipText") as Label
	if tooltip_text_label == null:
		return
	
	# Não mostrar tooltip durante colocação de estruturas ou drag
	if placing_tower or placing_barracks or placing_mine or placing_slow_tower or placing_aoe_tower or placing_sniper_tower or placing_boost_tower or placing_shock_tower or placing_wall or placing_healing_station or dragging_tower:
		game_tooltip.visible = false
		tooltip_timer = 0.0
		return
	
	# Obter posição do mouse no mundo
	var mouse_pos = preview_mouse_pos
	var tooltip_info = _get_tooltip_for_position(mouse_pos)
	
	if tooltip_info != "":
		tooltip_timer += delta
		if tooltip_timer >= GameConstants.UI_TOOLTIP_DELAY:
			tooltip_text_label.text = tooltip_info
			game_tooltip.visible = true
			
			# Posicionar tooltip próximo ao mouse
			var viewport = get_viewport()
			var screen_mouse = viewport.get_mouse_position()
			
			# Atualizar texto do tooltip
			tooltip_text_label.text = tooltip_info
			
			# Calcular tamanho dinâmico baseado no conteúdo
			# Estimar tamanho necessário baseado no número de linhas e caracteres
			var lines = tooltip_info.split("\n")
			var max_line_length = 0
			for line in lines:
				if line.length() > max_line_length:
					max_line_length = line.length()
			
			# Tamanho mínimo e máximo do tooltip
			var min_width = 280.0
			var min_height = 80.0
			var max_width = 450.0
			var max_height = 350.0
			
			# Estimar largura baseada no número de caracteres (aproximadamente 8 pixels por caractere)
			var estimated_width = max_line_length * 8.0 + 40.0  # 40 pixels de padding
			var estimated_height = lines.size() * 20.0 + 30.0  # 20 pixels por linha + padding
			
			# Calcular tamanho final com padding
			var tooltip_size = Vector2(
				clamp(estimated_width, min_width, max_width),
				clamp(estimated_height, min_height, max_height)
			)
			
			var offset = Vector2(15, 15)  # Offset menor para ficar mais próximo
			
			# Ajustar posição para não sair da tela
			var tooltip_pos = screen_mouse + offset
			if tooltip_pos.x + tooltip_size.x > viewport.get_visible_rect().size.x:
				tooltip_pos.x = screen_mouse.x - tooltip_size.x - offset.x
			if tooltip_pos.y + tooltip_size.y > viewport.get_visible_rect().size.y:
				tooltip_pos.y = screen_mouse.y - tooltip_size.y - offset.y
			
			game_tooltip.position = tooltip_pos
			game_tooltip.size = tooltip_size
			var panel = game_tooltip.get_node("Panel") as Panel
			if panel:
				panel.size = tooltip_size
				# Garantir que o painel use o tamanho correto
				panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			# Garantir que o label de texto esteja configurado corretamente
			if tooltip_text_label:
				tooltip_text_label.set_anchors_preset(Control.PRESET_FULL_RECT)
				tooltip_text_label.offset_left = 10
				tooltip_text_label.offset_top = 10
				tooltip_text_label.offset_right = -10
				tooltip_text_label.offset_bottom = -10
				tooltip_text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
				tooltip_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		else:
			game_tooltip.visible = false
	else:
		tooltip_timer = 0.0
		game_tooltip.visible = false

func _get_tooltip_for_position(world_pos: Vector2) -> String:
	# Verificar torres
	for i in range(towers.size()):
		var t = towers[i]
		if world_pos.distance_to(t.pos) < 25.0:
			return _get_tower_tooltip(t)
	
	# Verificar slow towers
	for i in range(slow_towers.size()):
		var st = slow_towers[i]
		if world_pos.distance_to(st.pos) < 25.0:
			return _get_slow_tower_tooltip(st)
	
	# Verificar AOE towers
	for i in range(aoe_towers.size()):
		var aoe = aoe_towers[i]
		if world_pos.distance_to(aoe.pos) < 25.0:
			return _get_aoe_tower_tooltip(aoe)
	
	# Verificar sniper towers
	for i in range(sniper_towers.size()):
		var sniper = sniper_towers[i]
		if world_pos.distance_to(sniper.pos) < 25.0:
			return _get_sniper_tower_tooltip(sniper)
	
	# Verificar boost towers
	for i in range(boost_towers.size()):
		var boost = boost_towers[i]
		if world_pos.distance_to(boost.pos) < 25.0:
			return _get_boost_tower_tooltip(boost)
	
	# Verificar shock towers
	for i in range(shock_towers.size()):
		var shock = shock_towers[i]
		if world_pos.distance_to(shock.pos) < 25.0:
			return _get_shock_tower_tooltip(shock)
	
	# Verificar barracks
	for i in range(barracks.size()):
		var b = barracks[i]
		if world_pos.distance_to(b.pos) < 25.0:
			return _get_barracks_tooltip(b)
	
	# Verificar muralhas
	for i in range(walls.size()):
		var w = walls[i]
		if w.hp > 0 and world_pos.distance_to(w.pos) < 20.0:
			return _get_wall_tooltip(w)
	
	# Verificar minas
	for i in range(mines.size()):
		var m = mines[i]
		if world_pos.distance_to(m.pos) < 15.0:
			return _get_mine_tooltip(m)
	
	# Verificar estações de cura
	for i in range(healing_stations.size()):
		var hs = healing_stations[i]
		if world_pos.distance_to(hs.pos) < 25.0:
			return _get_healing_station_tooltip(hs)
	
	return ""

func _get_tower_tooltip(t: Dictionary) -> String:
	var dmg = t.get("damage", 1.0)
	var rate = t.get("fire_rate", 1.0)
	var range_val = t.get("range", 100.0)
	var dirs_value = t.get("dirs", 1)
	# dirs pode ser um array ou um número
	var dirs_count = dirs_value.size() if dirs_value is Array else (dirs_value if dirs_value is int else 1)
	return "Torre Básica\n\nDano: %.1f\nCadência: %.1fs\nAlcance: %.0f\nDireções: %d" % [dmg, rate, range_val, dirs_count]

func _get_slow_tower_tooltip(st: Dictionary) -> String:
	var slow_amount = st.get("slow_amount", 0.0) * 100
	var range_val = st.get("range", 100.0)
	return "Torre Lenta\n\nRedução: %.0f%%\nAlcance: %.0f" % [slow_amount, range_val]

func _get_aoe_tower_tooltip(aoe: Dictionary) -> String:
	var dmg = aoe.get("damage", 1)
	var aoe_radius = aoe.get("aoe_radius", 50.0)
	var range_val = aoe.get("range", 100.0)
	return "Torre AOE\n\nDano: %d\nRaio AOE: %.0f\nAlcance: %.0f" % [dmg, aoe_radius, range_val]

func _get_sniper_tower_tooltip(sniper: Dictionary) -> String:
	var dmg = sniper.get("damage", 1)
	var rate = sniper.get("fire_rate", 20.0)
	var range_val = sniper.get("range", 100.0)
	var pierce = sniper.get("pierce", 1)
	var target_mode = sniper.get("target_mode", 0)
	var target_text = "Boss" if target_mode == 0 else "Mais Próximo"
	return "Torre Sniper\n\nDano: %d\nCadência: %.1fs\nAlcance: %.0f\nPerfuração: %d\nAlvo: %s" % [dmg, rate, range_val, pierce, target_text]

func _get_boost_tower_tooltip(boost: Dictionary) -> String:
	var dmg_boost = boost.get("damage_boost", 0.0) * 100
	var rate_boost = boost.get("rate_boost", 0.0) * 100
	var range_val = boost.get("range", 100.0)
	return "Torre Boost\n\nDano: +%.0f%%\nCadência: +%.0f%%\nAlcance: %.0f" % [dmg_boost, rate_boost, range_val]

func _get_shock_tower_tooltip(shock: Dictionary) -> String:
	var dmg = shock.get("damage", 1)
	var chain = shock.get("chain_count", 1)
	var range_val = shock.get("range", 100.0)
	return "Torre Choque\n\nDano: %d\nCorrentes: %d\nAlcance: %.0f" % [dmg, chain, range_val]

func _get_barracks_tooltip(b: Dictionary) -> String:
	var soldiers_count = b.get("soldiers", []).size()
	var dmg = b.get("damage", 1)
	return "Quartel\n\nSoldados: %d\nDano: %d" % [soldiers_count, dmg]

func _show_wall_menu(wall_idx: int, _world_pos: Vector2) -> void:
	"""Mostra menu de upgrade de muralha"""
	if wall_idx < 0 or wall_idx >= walls.size():
		return
	
	wall_selected_index = wall_idx
	var w = walls[wall_idx]
	var upgrades = w.get("upgrades", {})
	var hp_level = upgrades.get("hp_level", 0)
	
	# Atualizar textos do menu
	# Custo de upgrade escalado com wave
	var base_upgrade_cost = get_upgrade_cost(GameConstants.WALL_UPGRADE_HP_COST, hp_level)
	var wave_scale = pow(GameConstants.TOWER_COST_SCALE_PER_WAVE, max(0, wave_manager.wave - 1))
	var upgrade_cost = int(base_upgrade_cost * wave_scale)
	var repair_cost = int((w.max_hp - w.hp) * 0.5)  # Custo de reparo: 0.5 moedas por HP
	
	wall_menu.set_item_text(0, "Reforçar HP +25 (💰 %d moedas)" % upgrade_cost)
	wall_menu.set_item_text(1, "Reparar (💰 %d moedas)" % repair_cost)
	
	# Desabilitar itens se não tiver recursos ou já estiver no máximo
	var can_upgrade = hp_level < GameConstants.WALL_MAX_UPGRADES and hero["coins"] >= upgrade_cost
	var can_repair = w.hp < w.max_hp and hero["coins"] >= repair_cost
	
	wall_menu.set_item_disabled(0, not can_upgrade)
	wall_menu.set_item_disabled(1, not can_repair)
	
	# Mostrar menu na posição do mouse
	var screen_pos = get_viewport().get_mouse_position()
	wall_menu.position = screen_pos
	wall_menu.popup()

func _on_wall_menu_pressed(id: int) -> void:
	"""Handler para seleção de item no menu de muralha"""
	if wall_selected_index < 0 or wall_selected_index >= walls.size():
		return
	
	var w = walls[wall_selected_index]
	var upgrades = w.get("upgrades", {})
	var hp_level = upgrades.get("hp_level", 0)
	
	match id:
		1:  # Reforçar HP
			# Custo de upgrade escalado com wave
			var base_upgrade_cost = get_upgrade_cost(GameConstants.WALL_UPGRADE_HP_COST, hp_level)
			var wave_scale = pow(GameConstants.TOWER_COST_SCALE_PER_WAVE, max(0, wave_manager.wave - 1))
			var upgrade_cost = int(base_upgrade_cost * wave_scale)
			if hp_level < GameConstants.WALL_MAX_UPGRADES and hero["coins"] >= upgrade_cost:
				# Aplicar upgrade
				var hp_increase = GameConstants.WALL_UPGRADE_HP_AMOUNT
				var hp_ratio = w.hp / w.max_hp if w.max_hp > 0 else 1.0
				w.max_hp += hp_increase
				w.hp = w.max_hp * hp_ratio  # Manter proporção de HP
				upgrades["hp_level"] = hp_level + 1
				w["upgrades"] = upgrades
				hero["coins"] -= upgrade_cost
				_track_coin_spent(upgrade_cost)
				walls[wall_selected_index] = w
		2:  # Reparar
			var repair_cost = int((w.max_hp - w.hp) * 0.5)
			if w.hp < w.max_hp and hero["coins"] >= repair_cost:
				w.hp = w.max_hp
				hero["coins"] -= repair_cost
				_track_coin_spent(repair_cost)
				walls[wall_selected_index] = w
	
	# Reabrir menu com valores atualizados se necessário
	keep_wall_menu_open = true
	var screen_pos = get_viewport().get_mouse_position()
	call_deferred("_show_wall_menu", wall_selected_index, screen_pos)

func _get_wall_tooltip(w: Dictionary) -> String:
	var hp = w.get("hp", 0.0)
	var max_hp = w.get("max_hp", GameConstants.WALL_BASE_HP)
	var hp_percent = int((hp / max_hp) * 100) if max_hp > 0 else 0
	var upgrades = w.get("upgrades", {})
	var hp_level = upgrades.get("hp_level", 0)
	var tooltip = "Muralha\n\nVida: %d/%d (%d%%)" % [int(hp), int(max_hp), hp_percent]
	if hp_level > 0:
		tooltip += "\nUpgrades HP: Nível %d" % hp_level
	return tooltip

func _get_mine_tooltip(m: Dictionary) -> String:
	var dmg = m.get("damage", 75.0)
	var triggered = m.get("triggered", false)
	var status = "Ativa" if not triggered else "Explodida"
	return "Mina\n\nDano: %d\nStatus: %s" % [int(dmg), status]

func _get_healing_station_tooltip(hs: Dictionary) -> String:
	var heal_amount = hs.get("heal_amount", 5.0)
	var range_val = hs.get("range", 100.0)
	return "Estação de Cura\n\nCura: %.0f por round\nAlcance: %.0f" % [heal_amount, range_val]

func _create_mine_upgrade_buttons(vbox: VBoxContainer, panel_width: float) -> void:
	"""Cria botões de upgrade global para minas na loja (em dropdown colapsável)"""
	# Container principal para o dropdown
	var dropdown_container = VBoxContainer.new()
	dropdown_container.add_theme_constant_override("separation", 0)
	
	# Botão para expandir/colapsar upgrades
	var toggle_button = Button.new()
	toggle_button.name = "MineUpgradeToggle"
	toggle_button.custom_minimum_size = Vector2(panel_width - 20, 35)
	toggle_button.text = "▼ Upgrades de Minas (Global)"
	toggle_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var toggle_style = StyleBoxFlat.new()
	toggle_style.bg_color = Color(0.25, 0.25, 0.3, 0.9)
	toggle_style.border_color = Color(0.4, 0.4, 0.5)
	toggle_style.border_width_left = 1
	toggle_style.border_width_top = 1
	toggle_style.border_width_right = 1
	toggle_style.border_width_bottom = 1
	toggle_style.corner_radius_top_left = 4
	toggle_style.corner_radius_top_right = 4
	toggle_style.corner_radius_bottom_left = 4
	toggle_style.corner_radius_bottom_right = 4
	toggle_button.add_theme_stylebox_override("normal", toggle_style)
	toggle_button.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	toggle_button.add_theme_font_size_override("font_size", 12)
	dropdown_container.add_child(toggle_button)
	
	# Container para upgrades (inicialmente visível)
	var upgrade_container = VBoxContainer.new()
	upgrade_container.name = "MineUpgradeContent"
	upgrade_container.add_theme_constant_override("separation", 5)
	upgrade_container.visible = true
	
	# Upgrade de Dano
	var damage_upgrade_panel = PanelContainer.new()
	damage_upgrade_panel.custom_minimum_size = Vector2(panel_width - 20, 60)
	var damage_style = StyleBoxFlat.new()
	damage_style.bg_color = Color(0.25, 0.2, 0.15, 0.8)
	damage_style.border_color = Color(0.5, 0.4, 0.3)
	damage_style.border_width_left = 1
	damage_style.border_width_top = 1
	damage_style.border_width_right = 1
	damage_style.border_width_bottom = 1
	damage_upgrade_panel.add_theme_stylebox_override("panel", damage_style)
	
	var damage_hbox = HBoxContainer.new()
	damage_hbox.add_theme_constant_override("separation", 8)
	damage_upgrade_panel.add_child(damage_hbox)
	
	var damage_vbox = VBoxContainer.new()
	damage_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	damage_hbox.add_child(damage_vbox)
	
	var damage_name_label = Label.new()
	damage_name_label.name = "DamageNameLabel"
	damage_name_label.text = "Dano +%d (Nível %d/%d)" % [GameConstants.MINE_UPGRADE_DAMAGE_AMOUNT, mine_damage_level, GameConstants.MINE_UPGRADE_DAMAGE_MAX_LEVEL]
	damage_name_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.5))
	damage_name_label.add_theme_font_size_override("font_size", 12)
	damage_vbox.add_child(damage_name_label)
	
	var damage_cost_label = Label.new()
	damage_cost_label.name = "DamageCostLabel"
	var damage_cost = get_mine_upgrade_damage_cost()
	damage_cost_label.text = "💰 %d moedas" % damage_cost
	damage_cost_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	damage_cost_label.add_theme_font_size_override("font_size", 11)
	damage_vbox.add_child(damage_cost_label)
	
	var damage_btn = Button.new()
	damage_btn.name = "DamageUpgradeButton"
	damage_btn.text = "Upgrade"
	damage_btn.custom_minimum_size = Vector2(70, 40)
	damage_btn.pressed.connect(_on_upgrade_mine_damage)
	var damage_btn_style = StyleBoxFlat.new()
	damage_btn_style.bg_color = Color(0.6, 0.3, 0.2)
	damage_btn_style.border_color = Color(0.8, 0.4, 0.3)
	damage_btn_style.border_width_left = 1
	damage_btn_style.border_width_top = 1
	damage_btn_style.border_width_right = 1
	damage_btn_style.border_width_bottom = 1
	damage_btn.add_theme_stylebox_override("normal", damage_btn_style)
	damage_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	damage_btn.add_theme_font_size_override("font_size", 11)
	damage_hbox.add_child(damage_btn)
	
	upgrade_container.add_child(damage_upgrade_panel)
	
	# Upgrade de Raio
	var radius_upgrade_panel = PanelContainer.new()
	radius_upgrade_panel.custom_minimum_size = Vector2(panel_width - 20, 60)
	var radius_style = StyleBoxFlat.new()
	radius_style.bg_color = Color(0.2, 0.25, 0.15, 0.8)
	radius_style.border_color = Color(0.4, 0.5, 0.3)
	radius_style.border_width_left = 1
	radius_style.border_width_top = 1
	radius_style.border_width_right = 1
	radius_style.border_width_bottom = 1
	radius_upgrade_panel.add_theme_stylebox_override("panel", radius_style)
	
	var radius_hbox = HBoxContainer.new()
	radius_hbox.add_theme_constant_override("separation", 8)
	radius_upgrade_panel.add_child(radius_hbox)
	
	var radius_vbox = VBoxContainer.new()
	radius_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	radius_hbox.add_child(radius_vbox)
	
	var radius_name_label = Label.new()
	radius_name_label.name = "RadiusNameLabel"
	radius_name_label.text = "Raio +%.0f (Nível %d/%d)" % [GameConstants.MINE_UPGRADE_RADIUS_AMOUNT, mine_radius_level, GameConstants.MINE_UPGRADE_RADIUS_MAX_LEVEL]
	radius_name_label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
	radius_name_label.add_theme_font_size_override("font_size", 12)
	radius_vbox.add_child(radius_name_label)
	
	var radius_cost_label = Label.new()
	radius_cost_label.name = "RadiusCostLabel"
	var radius_cost = get_mine_upgrade_radius_cost()
	radius_cost_label.text = "💰 %d moedas" % radius_cost
	radius_cost_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	radius_cost_label.add_theme_font_size_override("font_size", 11)
	radius_vbox.add_child(radius_cost_label)
	
	var radius_btn = Button.new()
	radius_btn.name = "RadiusUpgradeButton"
	radius_btn.text = "Upgrade"
	radius_btn.custom_minimum_size = Vector2(70, 40)
	radius_btn.pressed.connect(_on_upgrade_mine_radius)
	var radius_btn_style = StyleBoxFlat.new()
	radius_btn_style.bg_color = Color(0.2, 0.6, 0.3)
	radius_btn_style.border_color = Color(0.3, 0.7, 0.4)
	radius_btn_style.border_width_left = 1
	radius_btn_style.border_width_top = 1
	radius_btn_style.border_width_right = 1
	radius_btn_style.border_width_bottom = 1
	radius_btn.add_theme_stylebox_override("normal", radius_btn_style)
	radius_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	radius_btn.add_theme_font_size_override("font_size", 11)
	radius_hbox.add_child(radius_btn)
	
	upgrade_container.add_child(radius_upgrade_panel)
	
	# Adicionar container de upgrades ao dropdown
	dropdown_container.add_child(upgrade_container)
	
	# Conectar botão toggle - usar meta para armazenar estado
	toggle_button.set_meta("is_expanded", true)
	toggle_button.pressed.connect(func():
		var is_expanded = toggle_button.get_meta("is_expanded", true)
		is_expanded = not is_expanded
		toggle_button.set_meta("is_expanded", is_expanded)
		upgrade_container.visible = is_expanded
		toggle_button.text = "▼ Upgrades de Minas (Global)" if is_expanded else "▶ Upgrades de Minas (Global)"
	)
	
	# Armazenar referências para atualização
	tower_shop_panel.set_meta("mine_upgrade_container", upgrade_container)
	tower_shop_panel.set_meta("mine_upgrade_toggle", toggle_button)
	
	vbox.add_child(dropdown_container)

func _on_upgrade_mine_damage() -> void:
	"""Handler para upgrade de dano de minas"""
	if upgrade_mine_damage():
		_update_mine_upgrade_buttons()
		_update_tower_shop_ui()

func _on_upgrade_mine_radius() -> void:
	"""Handler para upgrade de raio de minas"""
	if upgrade_mine_radius():
		_update_mine_upgrade_buttons()
		_update_tower_shop_ui()

func _update_mine_upgrade_buttons() -> void:
	"""Atualiza os textos dos botões de upgrade de minas"""
	if not tower_shop_panel or not tower_shop_panel.has_meta("mine_upgrade_container"):
		return
	
	var container = tower_shop_panel.get_meta("mine_upgrade_container")
	if not container:
		return
	
	# Atualizar label de dano
	var damage_panel = container.get_child(0)  # Índice 0 é o painel de dano (primeiro filho)
	if damage_panel:
		var damage_hbox = damage_panel.get_child(0)
		if damage_hbox:
			var damage_vbox = damage_hbox.get_child(0)
			if damage_vbox:
				var damage_name_label = damage_vbox.get_node("DamageNameLabel")
				if damage_name_label:
					damage_name_label.text = "Dano +%d (Nível %d/%d)" % [GameConstants.MINE_UPGRADE_DAMAGE_AMOUNT, mine_damage_level, GameConstants.MINE_UPGRADE_DAMAGE_MAX_LEVEL]
				var damage_cost_label = damage_vbox.get_node("DamageCostLabel")
				if damage_cost_label:
					var cost = get_mine_upgrade_damage_cost()
					damage_cost_label.text = "💰 %d moedas" % cost
					if mine_damage_level >= GameConstants.MINE_UPGRADE_DAMAGE_MAX_LEVEL:
						damage_cost_label.text = "MAX"
						damage_cost_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
				var damage_btn = damage_hbox.get_child(1)
				if damage_btn:
					damage_btn.disabled = mine_damage_level >= GameConstants.MINE_UPGRADE_DAMAGE_MAX_LEVEL or hero["coins"] < get_mine_upgrade_damage_cost()
	
	# Atualizar label de raio
	var radius_panel = container.get_child(1)  # Índice 1 é o painel de raio (segundo filho)
	if radius_panel:
		var radius_hbox = radius_panel.get_child(0)
		if radius_hbox:
			var radius_vbox = radius_hbox.get_child(0)
			if radius_vbox:
				var radius_name_label = radius_vbox.get_node("RadiusNameLabel")
				if radius_name_label:
					radius_name_label.text = "Raio +%.0f (Nível %d/%d)" % [GameConstants.MINE_UPGRADE_RADIUS_AMOUNT, mine_radius_level, GameConstants.MINE_UPGRADE_RADIUS_MAX_LEVEL]
				var radius_cost_label = radius_vbox.get_node("RadiusCostLabel")
				if radius_cost_label:
					var cost = get_mine_upgrade_radius_cost()
					radius_cost_label.text = "💰 %d moedas" % cost
					if mine_radius_level >= GameConstants.MINE_UPGRADE_RADIUS_MAX_LEVEL:
						radius_cost_label.text = "MAX"
						radius_cost_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
				var radius_btn = radius_hbox.get_child(1)
				if radius_btn:
					radius_btn.disabled = mine_radius_level >= GameConstants.MINE_UPGRADE_RADIUS_MAX_LEVEL or hero["coins"] < get_mine_upgrade_radius_cost()

func _get_shop_tooltip_text(tower_name: String) -> String:
	match tower_name:
		"Torre Básica":
			return "Torre básica de defesa. Atira em inimigos próximos com dano moderado."
		"Quartel":
			return "Produz soldados que atacam inimigos automaticamente. Soldados perseguem inimigos."
		"Mina":
			return "Explode quando inimigos se aproximam, causando dano alto e reduzindo velocidade."
		"Torre de Congelamento":
			return "Reduz a velocidade dos inimigos em sua área de efeito."
		"Canhão":
			return "Causa dano em área, afetando múltiplos inimigos simultaneamente."
		"Torre Sniper":
			return "Torre de longo alcance com alta precisão. Pode focar em bosses ou inimigos próximos ao centro."
		"Altar de Melhoria":
			return "Aumenta o dano e cadência de outras torres próximas."
		"Torre de Choque":
			return "Atira raios elétricos que saltam entre múltiplos inimigos."
		"Muralha":
			return "Bloqueia caminhos. Inimigos precisam recalcular rota ao encontrar uma muralha. Explode se bloquear todos os caminhos."
		"Estação de Cura":
			return "Cura a base em 5 HP por round quando está dentro do alcance."
		_:
			return ""

func _on_shop_button_hover(tower_name: String) -> void:
	if tooltip_label == null:
		return
	var shop_tooltip_text = _get_shop_tooltip_text(tower_name)
	if shop_tooltip_text != "":
		tooltip_label.text = shop_tooltip_text
		tooltip_label.visible = true

func _on_shop_button_unhover() -> void:
	if tooltip_label:
		tooltip_label.visible = false

# ========== HUD RESPONSIVA E TELA CHEIA ==========

func _adjust_hud_to_screen_size() -> void:
	"""Ajusta a HUD para ser responsiva ao tamanho da tela"""
	var viewport = get_viewport()
	if viewport == null:
		return
	
	var screen_size = viewport.get_visible_rect().size
	
	# Ajustar o HUD para ocupar toda a largura
	var hud = $CanvasLayer/HUD
	if hud:
		hud.layout_mode = 1  # Layout com anchors
		hud.set_anchors_preset(Control.PRESET_FULL_RECT)
		hud.offset_left = 0.0
		hud.offset_right = 0.0
		hud.offset_top = 0.0
		hud.offset_bottom = 0.0
	
	# Ajustar BottomBar
	var bottom_bar = $CanvasLayer/HUD.get_node_or_null("BottomBar")
	if bottom_bar:
		bottom_bar.layout_mode = 1
		bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		bottom_bar.offset_left = 0.0
		bottom_bar.offset_right = 0.0
		bottom_bar.offset_top = -40.0
		bottom_bar.offset_bottom = 0.0
	
	var tb = $CanvasLayer/HUD/TopBar
	if tb == null:
		return
	
	# Garantir que a TopBar fique acima dos painéis (onde está o label de vida)
	tb.z_index = 100
	
	# Ajustar TopBar para usar toda a largura da tela (sem margens laterais)
	tb.layout_mode = 1  # Layout com anchors
	tb.set_anchors_preset(Control.PRESET_TOP_WIDE)
	tb.offset_left = 0.0
	tb.offset_right = 0.0
	tb.offset_top = 0.0
	tb.offset_bottom = 44.0
	
	# Ajustar labels usando anchors - garantir que sejam configurados mesmo em telas pequenas
	var lbl_left = tb.get_node_or_null("LblLeft")
	var lbl_center = tb.get_node_or_null("LblCenter")  # Moeda
	var lbl_right = tb.get_node_or_null("LblRight")  # Vida
	
	# Organizar elementos da TopBar de forma responsiva
	# Usar porcentagens da largura da tela para melhor adaptação
	var screen_width = screen_size.x
	var spacing = 15.0  # Espaçamento entre elementos
	
	# 1. LblLeft (Onda/Clima) - à esquerda, largura adaptável
	if lbl_left:
		lbl_left.layout_mode = 1
		lbl_left.anchor_left = 0.0
		lbl_left.anchor_top = 0.0
		lbl_left.anchor_right = 0.0
		lbl_left.anchor_bottom = 0.0
		lbl_left.offset_left = 12
		lbl_left.offset_right = min(250.0, screen_width * 0.15)  # Máximo 15% da tela ou 250px
		lbl_left.offset_top = 10
		lbl_left.offset_bottom = 34
	
	# 2. Moeda (LblCenter) - após LblLeft, posição relativa
	if lbl_center:
		var left_end = lbl_left.offset_right if lbl_left else 250.0
		lbl_center.layout_mode = 1
		lbl_center.anchor_left = 0.0
		lbl_center.anchor_top = 0.0
		lbl_center.anchor_right = 0.0
		lbl_center.anchor_bottom = 0.0
		lbl_center.offset_left = left_end + spacing
		lbl_center.offset_right = left_end + spacing + 120.0  # Largura fixa de 120px
		lbl_center.offset_top = 10
		lbl_center.offset_bottom = 34
	
	# 3. Vida (LblRight) - após Moeda
	if lbl_right:
		var center_end = lbl_center.offset_right if lbl_center else 370.0
		lbl_right.layout_mode = 1
		lbl_right.anchor_left = 0.0
		lbl_right.anchor_top = 0.0
		lbl_right.anchor_right = 0.0
		lbl_right.anchor_bottom = 0.0
		lbl_right.offset_left = center_end + spacing
		lbl_right.offset_right = center_end + spacing + 100.0  # Largura fixa de 100px
		lbl_right.offset_top = 10
		lbl_right.offset_bottom = 34
		lbl_right.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl_right.visible = true
		lbl_right.z_index = 10
		lbl_right.text = "❤️ %d" % [base_hp]
	
	# 4. Slider de Volume - após Vida, mas pode ser escondido em telas pequenas
	var volume_container = tb.get_node_or_null("MusicVolumeContainer")
	if volume_container:
		var vida_end = lbl_right.offset_right if lbl_right else 470.0
		volume_container.layout_mode = 1
		volume_container.anchor_left = 0.0
		volume_container.anchor_top = 0.0
		volume_container.anchor_right = 0.0
		volume_container.anchor_bottom = 0.0
		# Esconder slider se tela muito pequena
		if screen_width < 1000:
			volume_container.visible = false
		else:
			volume_container.visible = true
			volume_container.offset_left = vida_end + spacing
			volume_container.offset_right = vida_end + spacing + 130.0
			volume_container.offset_top = 8
			volume_container.offset_bottom = 36
	
	# 5. Menu Admin - após Slider de Volume (ou após Vida se slider escondido)
	var admin_btn = tb.get_node_or_null("BtnAdmin")
	if admin_btn:
		var prev_end = volume_container.offset_right if volume_container and volume_container.visible else (lbl_right.offset_right if lbl_right else 470.0)
		admin_btn.layout_mode = 1
		admin_btn.anchor_left = 0.0
		admin_btn.anchor_top = 0.0
		admin_btn.anchor_right = 0.0
		admin_btn.anchor_bottom = 0.0
		# Esconder menu admin se tela muito pequena
		if screen_width < 1200:
			admin_btn.visible = false
		else:
			admin_btn.visible = true
			admin_btn.offset_left = prev_end + spacing
			admin_btn.offset_right = prev_end + spacing + 220.0
			admin_btn.offset_top = 8
			admin_btn.offset_bottom = 36
	
	# 7. Botão DPS - por último, à direita
	var btn_dps = tb.get_node_or_null("BtnDPS")
	if btn_dps:
		btn_dps.layout_mode = 1
		btn_dps.anchor_left = 1.0  # Ancorar à direita
		btn_dps.anchor_top = 0.0
		btn_dps.anchor_right = 1.0
		btn_dps.anchor_bottom = 0.0
		btn_dps.offset_left = -70  # Largura do botão (negativo)
		btn_dps.offset_right = -12  # Margem direita
		btn_dps.offset_top = 8
		btn_dps.offset_bottom = 36

func _update_bottom_bar() -> void:
	"""Atualiza a HUD inferior com informações secundárias"""
	var hud = $CanvasLayer/HUD
	if not hud:
		return
	
	var bottom_bar = hud.get_node_or_null("BottomBar")
	if not bottom_bar:
		return
	
	# Atualizar tempo de jogo
	var time_label = bottom_bar.get_node_or_null("LblTime")
	if time_label:
		var minutes = int(game_time / 60.0)
		var seconds = int(game_time) % 60
		time_label.text = "Tempo: %02d:%02d" % [minutes, seconds]
	
	# Atualizar contador de inimigos
	var enemies_label = bottom_bar.get_node_or_null("LblEnemies")
	if enemies_label:
		enemies_label.text = "Inimigos: %d" % enemies.size()
	
	# Atualizar FPS
	var fps_label = bottom_bar.get_node_or_null("LblFPS")
	if fps_label:
		var fps = Engine.get_frames_per_second()
		fps_label.text = "FPS: %d" % fps
	
	# Atualizar buffs temporários no TopBar
	var top_bar = hud.get_node_or_null("TopBar")
	if top_bar:
		var buff_label = top_bar.get_node_or_null("LblBuffs")
		if not buff_label:
			buff_label = Label.new()
			buff_label.name = "LblBuffs"
			buff_label.add_theme_font_size_override("font_size", 12)
			buff_label.offset_left = 600
			buff_label.offset_top = 10
			top_bar.add_child(buff_label)
		
		var buff_text = ""
		if tower_damage_boost_waves_remaining > 0:
			buff_text += "⚔️ +20%% Torres (%d waves) " % tower_damage_boost_waves_remaining
		if hero_damage_boost_waves_remaining > 0:
			buff_text += "🗡️ +30%% Herói (%d waves) " % hero_damage_boost_waves_remaining
		
		if buff_text.is_empty():
			buff_label.visible = false
		else:
			buff_label.visible = true
			buff_label.text = buff_text.strip_edges()
			buff_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.8))

func _on_viewport_size_changed() -> void:
	"""Chamado quando o tamanho da viewport muda (incluindo tela cheia)"""
	_adjust_hud_to_screen_size()
	_adjust_shop_and_skills_panels()
	# Garantir que o label de vida esteja sempre visível após ajustes
	var tb = $CanvasLayer/HUD/TopBar
	if tb:
		var lbl_right = tb.get_node_or_null("LblRight")
		if lbl_right:
			lbl_right.visible = true
			lbl_right.text = "❤️ %d" % [base_hp]
			lbl_right.z_index = 10
		# Atualizar botão Auto Benefício para ajustar texto em telas menores
		_update_auto_benefit_button()

# ========== FUNÇÕES DE COLAPSO E AJUSTE DE PAINÉIS ==========

func _toggle_tower_shop() -> void:
	"""Alterna o estado de colapso da loja de torres"""
	tower_shop_collapsed = !tower_shop_collapsed
	_update_tower_shop_collapse()
	_adjust_shop_and_skills_panels()

func _toggle_skills_panel() -> void:
	"""Alterna o estado de colapso do painel de skills"""
	skills_panel_collapsed = !skills_panel_collapsed
	_update_skills_panel_collapse()
	_adjust_shop_and_skills_panels()

func _update_tower_shop_collapse() -> void:
	"""Atualiza a UI da loja baseado no estado de colapso"""
	if tower_shop_panel == null:
		return
	
	var scroll = tower_shop_panel.get_node_or_null("TowerScroll")
	if scroll != null:
		scroll.visible = !tower_shop_collapsed
	
	# Esconder tooltip quando colapsado
	if tooltip_label != null:
		tooltip_label.visible = false
	
	# Garantir que o título e o botão sempre estejam visíveis
	var title_container = tower_shop_panel.get_node_or_null("TitleContainer")
	if title_container != null:
		title_container.visible = true
		
		# Ajustar título quando colapsado
		var title_label = title_container.get_node_or_null("TitleLabel")
		if title_label != null:
			if tower_shop_collapsed:
				title_label.text = "LOJA"
				title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				title_label.add_theme_font_size_override("font_size", 14)  # Fonte menor quando colapsado
			else:
				title_label.text = "LOJA DE TORRES"
				title_label.add_theme_font_size_override("font_size", 18)  # Fonte normal quando expandido
				title_label.text = "LOJA DE TORRES"
				title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	if tower_shop_toggle_button != null:
		tower_shop_toggle_button.visible = true
		tower_shop_toggle_button.text = "◄" if tower_shop_collapsed else "►"  # Corrigido: quando colapsado mostra seta esquerda (expandir)

func _update_skills_panel_collapse() -> void:
	"""Atualiza a UI do painel de skills baseado no estado de colapso"""
	if skills_panel == null:
		return
	
	var vbox = skills_panel.get_node_or_null("SkillsButtonsContainer")
	if vbox != null:
		vbox.visible = !skills_panel_collapsed
	
	# Garantir que o título e o botão sempre estejam visíveis
	var title_container = skills_panel.get_node_or_null("TitleContainer")
	if title_container != null:
		title_container.visible = true
		# Ajustar tamanho da fonte quando colapsado
		var title_label = title_container.get_node_or_null("TitleLabel")
		if title_label != null:
			if skills_panel_collapsed:
				title_label.add_theme_font_size_override("font_size", 14)  # Fonte menor quando colapsado
			else:
				title_label.add_theme_font_size_override("font_size", 18)  # Fonte normal quando expandido
	
	if skills_panel_toggle_button != null:
		skills_panel_toggle_button.visible = true
		skills_panel_toggle_button.text = "►" if skills_panel_collapsed else "◄"  # Corrigido: quando colapsado mostra seta direita (expandir)

func _adjust_shop_and_skills_panels() -> void:
	"""Ajusta os painéis da loja e skills para serem responsivos ao tamanho da tela"""
	var viewport = get_viewport()
	if viewport == null:
		return
	
	var screen_width = viewport.get_visible_rect().size.x
	var screen_height = viewport.get_visible_rect().size.y
	var min_screen_width = 1710.0  # Tamanho mínimo onde os painéis cabem sem sobrepor
	
	# Ajustar loja de torres primeiro
	if tower_shop_panel != null:
		var panel_width_expanded = 380.0
		var panel_width = panel_width_expanded if not tower_shop_collapsed else 80.0  # Aumentado para 80px para caber título e botão
		var panel_height = screen_height - 44.0
		
		# Se a tela for muito pequena, reduzir largura quando expandido
		if screen_width < min_screen_width and not tower_shop_collapsed:
			panel_width = min(panel_width, screen_width * 0.25)
		
		# Garantir que não cubra o label de vida (que está em x=500 até ~650)
		# O painel deve começar depois da HUD
		var hud_safe_zone = 700.0  # Zona segura da HUD
		var x_pos = screen_width - panel_width
		
		# Se o painel colapsado está cobrindo a HUD, movê-lo para fora da tela (mas ainda clicável)
		if tower_shop_collapsed and x_pos < hud_safe_zone:
			# Em telas muito pequenas, colocar o painel mais à direita mesmo que cubra parcialmente
			# Mas sempre manter o título e botão visíveis
			x_pos = max(650.0, screen_width - panel_width)
		
		tower_shop_panel.position = Vector2(x_pos, 44.0)
		tower_shop_panel.size = Vector2(panel_width, panel_height)
		
		# Ajustar container do título
		var title_container = tower_shop_panel.get_node_or_null("TitleContainer")
		if title_container != null:
			if tower_shop_collapsed:
				title_container.size = Vector2(panel_width - 10, 30)
			else:
				title_container.size = Vector2(panel_width - 20, 30)
			title_container.position = Vector2(10, 10)
		
		# Ajustar scroll container para o novo tamanho do painel
		var scroll = tower_shop_panel.get_node_or_null("TowerScroll")
		if scroll != null:
			scroll.position = Vector2(10, 45)
			scroll.size = Vector2(panel_width - 20, panel_height - 45)
		
		# Atualizar conteúdo visível
		_update_tower_shop_collapse()
	
	# Garantir que o label de vida esteja sempre visível após ajuste dos painéis
	var tb = $CanvasLayer/HUD/TopBar
	if tb:
		var lbl_right = tb.get_node_or_null("LblRight")
		if lbl_right:
			lbl_right.visible = true
			lbl_right.z_index = 10
			lbl_right.text = "❤️ %d" % [base_hp]
	
	# Ajustar painel de skills (precisa considerar largura da loja)
	if skills_panel != null:
		var panel_width_expanded = 390.0
		var panel_width = panel_width_expanded if not skills_panel_collapsed else 80.0  # Aumentado para 80px
		var panel_height = screen_height - 44.0
		var tower_panel_width = 80.0  # Largura mínima quando colapsado
		
		if tower_shop_panel != null:
			tower_panel_width = tower_shop_panel.size.x
		
		# Se a tela for muito pequena, reduzir largura quando expandido
		if screen_width < min_screen_width and not skills_panel_collapsed:
			var available_width = screen_width - tower_panel_width - 100
			panel_width = min(panel_width, max(available_width * 0.3, 250.0))
		
		var margin = 5.0
		var hud_safe_zone = 700.0  # Zona segura da HUD
		var x_pos = screen_width - tower_panel_width - panel_width - margin
		
		# Se o painel colapsado está cobrindo a HUD, ajustar posição
		if skills_panel_collapsed and x_pos < hud_safe_zone:
			x_pos = max(600.0, screen_width - tower_panel_width - panel_width - margin)
		
		# Garantir que não fique fora da tela
		if x_pos < 0:
			x_pos = 0
			if not skills_panel_collapsed:
				panel_width = max(250.0, screen_width - tower_panel_width - margin - 10)
		
		skills_panel.position = Vector2(x_pos, 44.0)
		skills_panel.size = Vector2(panel_width, panel_height)
		
		# Ajustar container do título
		var title_container = skills_panel.get_node_or_null("TitleContainer")
		if title_container != null:
			if skills_panel_collapsed:
				title_container.size = Vector2(panel_width - 10, 35)
			else:
				title_container.size = Vector2(panel_width - 20, 35)
			title_container.position = Vector2(10, 10)
		
		# Ajustar container de skills se existir
		var skills_container = skills_panel.get_node_or_null("SkillsButtonsContainer")
		if skills_container != null:
			skills_container.position = Vector2(10, 50)
			skills_container.size = Vector2(panel_width - 20, panel_height - 50)
		
		# Atualizar conteúdo visível
		_update_skills_panel_collapse()

# ========== SISTEMA DE DPS DAS TORRES ==========

func _get_tower_id(tower: Dictionary, tower_type: String) -> String:
	"""Gera um ID único para uma torre baseado em sua posição e tipo"""
	return "%s_%d_%d" % [tower_type, int(tower.pos.x), int(tower.pos.y)]

func _calculate_tower_dps(tower: Dictionary, _tower_type: String) -> float:
	"""Calcula o DPS teórico de uma torre baseado em dano e fire_rate"""
	var damage = tower.get("damage", GameConstants.TOWER_BASE_DAMAGE)
	var fire_rate = tower.get("fire_rate", 1.5)
	var dirs_count = tower.get("dirs", [Vector2(1, 0)]).size()
	
	# Aplicar multiplicadores globais
	damage *= global_tower_damage_boost
	
	# Aplicar boost de boost towers próximos
	var damage_multiplier = 1.0
	var rate_multiplier = 1.0
	for boost in boost_towers:
		var dist = tower.pos.distance_to(boost.pos)
		if dist <= boost.range:
			damage_multiplier += boost.damage_boost
			rate_multiplier += boost.rate_boost
	
	# Aplicar skill de boost de dano
	if skills_manager:
		damage_multiplier *= skills_manager.get_damage_multiplier()
	
	# Aplicar skill de boost de velocidade
	if skills_manager:
		rate_multiplier *= skills_manager.get_speed_multiplier()
	
	damage *= damage_multiplier
	var effective_fire_rate = fire_rate / rate_multiplier
	
	# DPS = (dano * direções) / fire_rate
	if effective_fire_rate > 0:
		return (damage * dirs_count) / effective_fire_rate
	return 0.0

func _calculate_sniper_dps(sniper: Dictionary) -> float:
	"""Calcula o DPS teórico de uma sniper tower"""
	var damage = sniper.get("damage", 2.0)
	var fire_rate = sniper.get("fire_rate", 2.0)
	
	# Aplicar multiplicadores globais
	damage *= global_tower_damage_boost
	
	# Aplicar boost de boost towers próximos
	var damage_multiplier = 1.0
	var rate_multiplier = 1.0
	for boost in boost_towers:
		var dist = sniper.pos.distance_to(boost.pos)
		if dist <= boost.range:
			damage_multiplier += boost.damage_boost
			rate_multiplier += boost.rate_boost
	
	# Aplicar skill de boost de dano
	if skills_manager:
		damage_multiplier *= skills_manager.get_damage_multiplier()
	
	# Aplicar skill de boost de velocidade
	if skills_manager:
		rate_multiplier *= skills_manager.get_speed_multiplier()
	
	damage *= damage_multiplier
	var effective_fire_rate = fire_rate / rate_multiplier
	
	# DPS = dano / fire_rate (pierce não afeta DPS, apenas permite acertar múltiplos inimigos)
	if effective_fire_rate > 0:
		return damage / effective_fire_rate
	return 0.0

func _calculate_aoe_dps(aoe: Dictionary) -> float:
	"""Calcula o DPS teórico de uma AOE tower"""
	var damage = aoe.get("damage", 1.0)
	var fire_rate = aoe.get("fire_rate", 1.5)
	
	# Aplicar multiplicadores globais
	damage *= global_tower_damage_boost
	
	# Aplicar boost de boost towers próximos
	var damage_multiplier = 1.0
	var rate_multiplier = 1.0
	for boost in boost_towers:
		var dist = aoe.pos.distance_to(boost.pos)
		if dist <= boost.range:
			damage_multiplier += boost.damage_boost
			rate_multiplier += boost.rate_boost
	
	# Aplicar skill de boost de dano
	if skills_manager:
		damage_multiplier *= skills_manager.get_damage_multiplier()
	
	# Aplicar skill de boost de velocidade
	if skills_manager:
		rate_multiplier *= skills_manager.get_speed_multiplier()
	
	damage *= damage_multiplier
	var effective_fire_rate = fire_rate / rate_multiplier
	
	# DPS = dano / fire_rate (AOE pode acertar múltiplos inimigos, mas DPS é por tiro)
	if effective_fire_rate > 0:
		return damage / effective_fire_rate
	return 0.0

func _calculate_shock_dps(shock: Dictionary) -> float:
	"""Calcula o DPS teórico de uma shock tower"""
	var damage = shock.get("damage", GameConstants.TOWER_BASE_DAMAGE)
	var fire_rate = shock.get("fire_rate", 1.0)
	var chain_count = shock.get("chain_count", 1)
	
	# Aplicar multiplicadores globais
	damage *= global_tower_damage_boost
	
	# Aplicar boost de boost towers próximos
	var damage_multiplier = 1.0
	var rate_multiplier = 1.0
	for boost in boost_towers:
		var dist = shock.pos.distance_to(boost.pos)
		if dist <= boost.range:
			damage_multiplier += boost.damage_boost
			rate_multiplier += boost.rate_boost
	
	# Aplicar skill de boost de dano
	if skills_manager:
		damage_multiplier *= skills_manager.get_damage_multiplier()
	
	# Aplicar skill de boost de velocidade
	if skills_manager:
		rate_multiplier *= skills_manager.get_speed_multiplier()
	
	damage *= damage_multiplier
	var effective_fire_rate = fire_rate / rate_multiplier
	
	# DPS = (dano * chain_count) / fire_rate (cada corrente causa dano)
	if effective_fire_rate > 0:
		return (damage * chain_count) / effective_fire_rate
	return 0.0

func _calculate_barracks_dps(barracks_item: Dictionary) -> float:
	"""Calcula o DPS teórico de um quartel baseado nos soldados"""
	var soldier_damage = barracks_item.get("damage", 1.0)
	var soldier_spawn_rate = barracks_item.get("soldier_spawn_rate", 3.0)
	var hold_time = barracks_item.get("hold_time", GameConstants.BARRACKS_INITIAL_HOLD_TIME)
	
	# Aplicar multiplicadores globais
	soldier_damage *= global_tower_damage_boost
	
	# Aplicar boost de boost towers próximos
	var damage_multiplier = 1.0
	for boost in boost_towers:
		var dist = barracks_item.pos.distance_to(boost.pos)
		if dist <= boost.range:
			damage_multiplier += boost.damage_boost
	
	# Aplicar skill de boost de dano
	if skills_manager:
		damage_multiplier *= skills_manager.get_damage_multiplier()
	
	soldier_damage *= damage_multiplier
	
	# Calcular quantos soldados podem estar ativos simultaneamente
	# Assumindo que cada soldado vive pelo menos hold_time segundos
	# e que novos soldados são spawnados a cada soldier_spawn_rate segundos
	# O número máximo de soldados ativos é aproximadamente hold_time / soldier_spawn_rate
	var max_active_soldiers = max(1.0, hold_time / soldier_spawn_rate)
	
	# DPS = dano por soldado * número de soldados ativos
	# Cada soldado causa dano continuamente enquanto segura um inimigo
	return soldier_damage * max_active_soldiers

func _update_tower_dps(_delta: float) -> void:
	"""Atualiza o DPS calculado de todas as torres"""
	
	# Atualizar DPS das torres normais
	for i in range(towers.size()):
		var tower = towers[i]
		var tower_id = _get_tower_id(tower, "tower")
		if not tower_dps_data.has(tower_id):
			tower_dps_data[tower_id] = {
				"dps": 0.0,
				"damage_dealt": 0.0,
				"shots": 0,
				"wave_damage": {},
				"tower_type": "tower",
				"pos": tower.pos
			}
		tower_dps_data[tower_id]["dps"] = _calculate_tower_dps(tower, "tower")
		tower_dps_data[tower_id]["tower_type"] = "tower"
		tower_dps_data[tower_id]["pos"] = tower.pos
	
	# Atualizar DPS das sniper towers
	for i in range(sniper_towers.size()):
		var sniper = sniper_towers[i]
		var tower_id = _get_tower_id(sniper, "sniper")
		if not tower_dps_data.has(tower_id):
			tower_dps_data[tower_id] = {
				"dps": 0.0,
				"damage_dealt": 0.0,
				"shots": 0,
				"wave_damage": {},
				"tower_type": "sniper",
				"pos": sniper.pos
			}
		tower_dps_data[tower_id]["dps"] = _calculate_sniper_dps(sniper)
		tower_dps_data[tower_id]["tower_type"] = "sniper"
		tower_dps_data[tower_id]["pos"] = sniper.pos
	
	# Atualizar DPS das AOE towers
	for i in range(aoe_towers.size()):
		var aoe = aoe_towers[i]
		var tower_id = _get_tower_id(aoe, "aoe")
		if not tower_dps_data.has(tower_id):
			tower_dps_data[tower_id] = {
				"dps": 0.0,
				"damage_dealt": 0.0,
				"shots": 0,
				"wave_damage": {},
				"tower_type": "aoe",
				"pos": aoe.pos
			}
		tower_dps_data[tower_id]["dps"] = _calculate_aoe_dps(aoe)
		tower_dps_data[tower_id]["tower_type"] = "aoe"
		tower_dps_data[tower_id]["pos"] = aoe.pos
	
	# Atualizar DPS das shock towers
	for i in range(shock_towers.size()):
		var shock = shock_towers[i]
		var tower_id = _get_tower_id(shock, "shock")
		if not tower_dps_data.has(tower_id):
			tower_dps_data[tower_id] = {
				"dps": 0.0,
				"damage_dealt": 0.0,
				"shots": 0,
				"wave_damage": {},
				"tower_type": "shock",
				"pos": shock.pos
			}
		tower_dps_data[tower_id]["dps"] = _calculate_shock_dps(shock)
		tower_dps_data[tower_id]["tower_type"] = "shock"
		tower_dps_data[tower_id]["pos"] = shock.pos
	
	# Remover dados de torres que não existem mais
	var valid_ids = []
	for tower in towers:
		valid_ids.append(_get_tower_id(tower, "tower"))
	for sniper in sniper_towers:
		valid_ids.append(_get_tower_id(sniper, "sniper"))
	for aoe in aoe_towers:
		valid_ids.append(_get_tower_id(aoe, "aoe"))
	for shock in shock_towers:
		valid_ids.append(_get_tower_id(shock, "shock"))
	
	var ids_to_remove = []
	for tower_id in tower_dps_data.keys():
		if not valid_ids.has(tower_id):
			ids_to_remove.append(tower_id)
	for id in ids_to_remove:
		tower_dps_data.erase(id)

func _create_dps_menu() -> void:
	"""Cria o menu de DPS das torres"""
	if dps_menu_panel != null and dps_menu_panel.is_inside_tree():
		return
	
	var canvas = $CanvasLayer
	if canvas == null:
		return
	
	# Criar painel de DPS
	dps_menu_panel = Panel.new()
	dps_menu_panel.name = "DPSMenuPanel"
	dps_menu_panel.custom_minimum_size = Vector2(350, 400)
	dps_menu_panel.position = Vector2(50, 100)
	dps_menu_panel.visible = false
	dps_menu_panel.z_index = 50
	
	# Estilo do painel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	panel_style.border_color = Color(0.4, 0.4, 0.5)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	dps_menu_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Container principal
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 5)
	
	# Título
	var title_hbox = HBoxContainer.new()
	var title_label = Label.new()
	title_label.text = "DPS das Torres"
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hbox.add_child(title_label)
	
	# Botão fechar
	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(30, 30)
	close_btn.pressed.connect(func(): _toggle_dps_menu())
	title_hbox.add_child(close_btn)
	
	main_vbox.add_child(title_hbox)
	
	# ScrollContainer para lista de torres
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(330, 350)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	# Container com padding à esquerda
	var scroll_content = MarginContainer.new()
	scroll_content.add_theme_constant_override("margin_left", 10)
	scroll_content.add_theme_constant_override("margin_right", 10)
	scroll_content.add_theme_constant_override("margin_top", 5)
	scroll_content.add_theme_constant_override("margin_bottom", 5)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.name = "DPSContent"
	content_vbox.add_theme_constant_override("separation", 5)
	scroll_content.add_child(content_vbox)
	scroll.add_child(scroll_content)
	
	main_vbox.add_child(scroll)
	
	dps_menu_panel.add_child(main_vbox)
	canvas.add_child(dps_menu_panel)

func _update_dps_menu() -> void:
	"""Atualiza o conteúdo do menu de DPS"""
	if dps_menu_panel == null or not dps_menu_panel.is_inside_tree():
		print("DPS Menu: dps_menu_panel é null ou não está na árvore")
		return
	
	# DPSContent está dentro de ScrollContainer que está dentro de main_vbox
	var main_vbox = dps_menu_panel.get_child(0) if dps_menu_panel.get_child_count() > 0 else null
	if main_vbox == null:
		print("DPS Menu: ERRO - main_vbox não encontrado!")
		return
	
	var scroll = null
	for child in main_vbox.get_children():
		if child is ScrollContainer:
			scroll = child
			break
	
	if scroll == null:
		print("DPS Menu: ERRO - ScrollContainer não encontrado!")
		return
	
	# DPSContent agora está dentro de um MarginContainer dentro do ScrollContainer
	var content_vbox = null
	if scroll.get_child_count() > 0:
		var margin_container = scroll.get_child(0)
		if margin_container is MarginContainer:
			# Procurar DPSContent dentro do MarginContainer
			content_vbox = margin_container.get_node_or_null("DPSContent")
			if content_vbox == null and margin_container.get_child_count() > 0:
				content_vbox = margin_container.get_child(0)
				if content_vbox.name != "DPSContent":
					content_vbox.name = "DPSContent"
	
	if content_vbox == null:
		print("DPS Menu: ERRO - DPSContent não encontrado!")
		return
	
	# Limpar conteúdo anterior
	for child in content_vbox.get_children():
		child.queue_free()
	
	# Garantir que todas as torres existentes estejam no tower_dps_data
	# e recalcular DPS para todas elas
	for tower in towers:
		var tower_id = _get_tower_id(tower, "tower")
		if not tower_dps_data.has(tower_id):
			tower_dps_data[tower_id] = {
				"dps": 0.0,
				"damage_dealt": 0.0,
				"shots": 0,
				"wave_damage": {},
				"tower_type": "tower",
				"pos": tower.pos
			}
		var calculated_dps = _calculate_tower_dps(tower, "tower")
		tower_dps_data[tower_id]["dps"] = calculated_dps
		tower_dps_data[tower_id]["tower_type"] = "tower"
		tower_dps_data[tower_id]["pos"] = tower.pos
		# Debug: verificar se o dano está atualizado
		var tower_damage = tower.get("damage", GameConstants.TOWER_BASE_DAMAGE)
		if calculated_dps > 0:
			print("Torre DPS: damage=%.2f, fire_rate=%.2f, dirs=%d, dps_calculado=%.2f" % [tower_damage, tower.get("fire_rate", 1.5), tower.get("dirs", []).size(), calculated_dps])
	
	for sniper in sniper_towers:
		var tower_id = _get_tower_id(sniper, "sniper")
		if not tower_dps_data.has(tower_id):
			tower_dps_data[tower_id] = {
				"dps": 0.0,
				"damage_dealt": 0.0,
				"shots": 0,
				"wave_damage": {},
				"tower_type": "sniper",
				"pos": sniper.pos
			}
		tower_dps_data[tower_id]["dps"] = _calculate_sniper_dps(sniper)
		tower_dps_data[tower_id]["tower_type"] = "sniper"
		tower_dps_data[tower_id]["pos"] = sniper.pos
	
	for aoe in aoe_towers:
		var tower_id = _get_tower_id(aoe, "aoe")
		if not tower_dps_data.has(tower_id):
			tower_dps_data[tower_id] = {
				"dps": 0.0,
				"damage_dealt": 0.0,
				"shots": 0,
				"wave_damage": {},
				"tower_type": "aoe",
				"pos": aoe.pos
			}
		tower_dps_data[tower_id]["dps"] = _calculate_aoe_dps(aoe)
		tower_dps_data[tower_id]["tower_type"] = "aoe"
		tower_dps_data[tower_id]["pos"] = aoe.pos
	
	for shock in shock_towers:
		var tower_id = _get_tower_id(shock, "shock")
		if not tower_dps_data.has(tower_id):
			tower_dps_data[tower_id] = {
				"dps": 0.0,
				"damage_dealt": 0.0,
				"shots": 0,
				"wave_damage": {},
				"tower_type": "shock",
				"pos": shock.pos
			}
		tower_dps_data[tower_id]["dps"] = _calculate_shock_dps(shock)
		tower_dps_data[tower_id]["tower_type"] = "shock"
		tower_dps_data[tower_id]["pos"] = shock.pos
	
	# Atualizar DPS dos quartéis
	for barracks_item in barracks:
		var barracks_id = _get_tower_id(barracks_item, "barracks")
		if not tower_dps_data.has(barracks_id):
			tower_dps_data[barracks_id] = {
				"dps": 0.0,
				"damage_dealt": 0.0,
				"shots": 0,
				"wave_damage": {},
				"tower_type": "barracks",
				"pos": barracks_item.pos
			}
		tower_dps_data[barracks_id]["dps"] = _calculate_barracks_dps(barracks_item)
		tower_dps_data[barracks_id]["tower_type"] = "barracks"
		tower_dps_data[barracks_id]["pos"] = barracks_item.pos
	
	# Agrupar torres por tipo e calcular totais
	var grouped_towers: Dictionary = {}  # {tower_type: {total_dps: float, total_wave_damage: float, count: int}}
	var type_names = {
		"tower": "Torre",
		"sniper": "Sniper",
		"aoe": "AOE",
		"shock": "Shock",
		"barracks": "Quartel"
	}
	
	# Obter a wave atual e a última wave (wave anterior)
	var current_wave = wave_manager.wave if wave_manager else 0
	var last_wave = current_wave - 1 if current_wave > 0 else 0
	
	# Agrupar todas as torres por tipo
	for tower_id in tower_dps_data.keys():
		var data = tower_dps_data[tower_id]
		var tower_type = data.get("tower_type", "unknown")
		var dps_value = data.get("dps", 0.0)
		
		# Inicializar grupo se não existir
		if not grouped_towers.has(tower_type):
			grouped_towers[tower_type] = {
				"total_dps": 0.0,
				"total_wave_damage": 0.0,
				"count": 0
			}
		
		# Somar DPS
		grouped_towers[tower_type]["total_dps"] += dps_value
		grouped_towers[tower_type]["count"] += 1
		
		# Somar dano da última wave
		var wave_damage = 0.0
		if data.has("wave_damage"):
			wave_damage = data["wave_damage"].get(last_wave, 0.0)
		grouped_towers[tower_type]["total_wave_damage"] += wave_damage
	
	# Criar lista ordenada por tipo (ordem fixa)
	var type_order = ["tower", "sniper", "aoe", "shock", "barracks"]
	var sorted_groups = []
	for tower_type in type_order:
		if grouped_towers.has(tower_type):
			sorted_groups.append({
				"type": tower_type,
				"name": type_names.get(tower_type, tower_type),
				"total_dps": grouped_towers[tower_type]["total_dps"],
				"total_wave_damage": grouped_towers[tower_type]["total_wave_damage"],
				"count": grouped_towers[tower_type]["count"]
			})
	
	# Criar painéis para cada tipo de torre agrupado
	for group_info in sorted_groups:
		var tower_panel = Panel.new()
		tower_panel.custom_minimum_size = Vector2(310, 70)
		
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.2, 0.2, 0.25, 0.9)
		panel_style.border_color = Color(0.4, 0.4, 0.5)
		panel_style.border_width_left = 1
		panel_style.border_width_top = 1
		panel_style.border_width_right = 1
		panel_style.border_width_bottom = 1
		panel_style.corner_radius_top_left = 4
		panel_style.corner_radius_top_right = 4
		panel_style.corner_radius_bottom_left = 4
		panel_style.corner_radius_bottom_right = 4
		tower_panel.add_theme_stylebox_override("panel", panel_style)
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		tower_panel.add_child(margin)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		margin.add_child(hbox)
		
		# Tipo da torre com quantidade
		var type_label = Label.new()
		var count_text = " (%d)" % group_info.count if group_info.count > 1 else ""
		type_label.text = group_info.name + count_text
		type_label.custom_minimum_size = Vector2(80, 0)
		type_label.add_theme_font_size_override("font_size", 13)
		type_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
		hbox.add_child(type_label)
		
		# Informações de DPS
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 4)
		
		# DPS total
		var dps_label = Label.new()
		var dps_display = group_info.total_dps
		if dps_display < 0.01:
			dps_display = 0.0
		dps_label.text = "DPS Total: %.1f" % dps_display
		dps_label.add_theme_font_size_override("font_size", 14)
		dps_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
		info_vbox.add_child(dps_label)
		
		# Dano da última wave
		var damage_label = Label.new()
		var wave_damage_display = group_info.total_wave_damage
		if last_wave > 0:
			damage_label.text = "Dano Wave %d: %.0f" % [last_wave, wave_damage_display]
		else:
			damage_label.text = "Dano Wave: 0 (aguardando primeira wave)"
		damage_label.add_theme_font_size_override("font_size", 12)
		damage_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		info_vbox.add_child(damage_label)
		
		hbox.add_child(info_vbox)
		content_vbox.add_child(tower_panel)
	
	# Se não há torres, mostrar mensagem
	if sorted_groups.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Nenhuma torre construída"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		content_vbox.add_child(empty_label)

func _toggle_dps_menu() -> void:
	"""Abre/fecha o menu de DPS"""
	if dps_menu_panel == null:
		_create_dps_menu()
	
	if dps_menu_panel == null:
		return
	
	dps_menu_visible = !dps_menu_visible
	dps_menu_panel.visible = dps_menu_visible
	
	if dps_menu_visible:
		_update_dps_menu()
		# Criar timer para atualizar periodicamente
		if not has_node("DPSUpdateTimer"):
			var timer = Timer.new()
			timer.name = "DPSUpdateTimer"
			timer.wait_time = 0.5
			timer.timeout.connect(_update_dps_menu)
			timer.autostart = true
			add_child(timer)
		else:
			var timer = get_node("DPSUpdateTimer")
			timer.start()
	else:
		# Parar timer quando fechar
		if has_node("DPSUpdateTimer"):
			var timer = get_node("DPSUpdateTimer")
			timer.stop()
