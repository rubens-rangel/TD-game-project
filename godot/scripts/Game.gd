extends Node2D

var _cached_cfg_node: Node = null

func _cfg() -> Node:
	if _cached_cfg_node == null:
		_cached_cfg_node = get_node("/root/GameConfig")
	return _cached_cfg_node

func _set_placing_flag(type_id: String, value: bool) -> void:
	if value:
		placing_type = type_id
	elif placing_type == type_id:
		placing_type = ""

func _is_placing() -> bool:
	return not placing_type.is_empty()

func _clear_placing() -> void:
	placing_type = ""

func _clear_drag_state() -> void:
	dragging_tower = false
	dragged_tower_type = ""
	dragged_tower_index = -1
	drag_start_pos = Vector2.ZERO
	drag_offset = Vector2.ZERO
	drag_current_pos = Vector2.ZERO

func _emerald_count() -> int:
	if special_currency_manager:
		return int(special_currency_manager.get_currency_info().emeralds)
	return 0

func _get_structure_cost(type_id: String) -> int:
	var def := StructureCatalog.get_def(type_id)
	if def.is_empty():
		return 0
	match def.get("cost_mode", StructureCatalog.COST_RAW):
		StructureCatalog.COST_TOWER:
			return get_tower_cost(_cfg().get_int(def.cost_key))
		StructureCatalog.COST_WALL:
			return get_wall_cost()
		_:
			return _cfg().get_int(def.cost_key)

func _can_afford_structure(type_id: String) -> bool:
	var def := StructureCatalog.get_def(type_id)
	var cost := _get_structure_cost(type_id)
	if def.get("currency", StructureCatalog.CURRENCY_COINS) == StructureCatalog.CURRENCY_EMERALDS:
		return _emerald_count() >= cost
	return hero["coins"] >= cost

func _spend_structure_cost(type_id: String) -> void:
	var def := StructureCatalog.get_def(type_id)
	var cost := _get_structure_cost(type_id)
	if def.get("currency", StructureCatalog.CURRENCY_COINS) == StructureCatalog.CURRENCY_EMERALDS:
		if special_currency_manager:
			special_currency_manager.spend_emeralds(cost)
		return
	hero["coins"] -= cost
	if def.get("track_coins", false):
		_track_coin_spent(cost)

func _get_structure_texture(type_id: String) -> Texture2D:
	var def := StructureCatalog.get_def(type_id)
	var var_name: String = def.get("texture_var", "")
	if var_name.is_empty():
		return null
	return get(var_name)

func _factory_context(type_id: String, world_pos: Vector2 = Vector2.ZERO) -> Dictionary:
	var ctx := {
		"range_boost": global_tower_range_boost,
		"tower_base_damage": _cfg().get_float("TOWER_BASE_DAMAGE"),
		"barracks_spawn_rate": _cfg().get_float("BARRACKS_INITIAL_SPAWN_RATE"),
		"barracks_hold_time": _cfg().get_float("BARRACKS_INITIAL_HOLD_TIME"),
		"barracks_damage": _cfg().get_float("BARRACKS_INITIAL_SOLDIER_DAMAGE"),
		"barracks_projectile_speed": _cfg().get_float("BARRACKS_INITIAL_PROJECTILE_SPEED"),
		"mine_damage": get_mine_damage(),
		"mine_explosion_radius": get_mine_explosion_radius(),
		"mine_slow_duration": _cfg().get_float("MINE_SLOW_DURATION"),
		"mine_slow_amount": _cfg().get_float("MINE_SLOW_AMOUNT"),
		"mine_trigger_radius": _cfg().get_float("MINE_TRIGGER_RADIUS"),
		"wall_hp": _cfg().get_float("WALL_BASE_HP") * wall_hp_multiplier,
	}
	if type_id == "tower":
		var bc = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
		var dir_vec = (world_pos - bc).normalized()
		if dir_vec.length() < 0.1:
			dir_vec = Vector2(1, 0)
		ctx["dir_vec"] = dir_vec
	return ctx

func _begin_placing(type_id: String) -> void:
	if placing_type == type_id:
		return
	var def := StructureCatalog.get_def(type_id)
	if def.is_empty():
		return
	if not _is_structure_unlocked(type_id):
		_toast_locked_until_wave(_structure_unlock_wave(type_id))
		return
	var arr: Array = _get_structure_array(def.array)
	if _buy_blocked(_can_afford_structure(type_id), arr.size() >= _cfg().get_int(def.max_key)):
		return
	placing_type = type_id

func _try_place_structure(type_id: String, pos: Vector2) -> void:
	var def := StructureCatalog.get_def(type_id)
	if def.is_empty():
		_clear_placing()
		return
	match def.get("placement", StructureCatalog.PLACEMENT_BASE):
		StructureCatalog.PLACEMENT_WALKABLE:
			_try_place_mine(pos)
		StructureCatalog.PLACEMENT_PATH:
			_try_place_wall(pos)
		_:
			_try_place_base_structure(type_id, pos)

func _try_place_base_structure(type_id: String, pos: Vector2) -> void:
	var def := StructureCatalog.get_def(type_id)
	var arr: Array = _get_structure_array(def.array)
	if not _can_afford_structure(type_id) or arr.size() >= _cfg().get_int(def.max_key):
		_clear_placing()
		return
	var size: int = _cfg().get_int(def.size_key)
	var grid_type: int = int(def.grid_type)
	if not grid_manager.is_inside_base_point(pos):
		_toast_invalid_placement()
		return
	var grid_coord: Vector2i = grid_manager.world_to_base_grid(pos)
	if not grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, size, grid_type):
		_toast_invalid_placement()
		return
	var world_pos: Vector2 = StructurePlacement.occupy(grid_manager, pathfinder, grid_coord, size, grid_type)
	var created = StructureFactory.create(type_id, world_pos, grid_coord, _factory_context(type_id, world_pos))
	if created is Dictionary and def.get("currency", "") == StructureCatalog.CURRENCY_COINS:
		created["coins_invested"] = _get_structure_cost(type_id)
	arr.append(created)
	_spend_structure_cost(type_id)
	if def.get("track_built", false):
		_track_tower_built(type_id)
	_clear_placing()

func _try_move_structure_to_grid(type_id: String, idx: int, new_grid_coord: Vector2i) -> bool:
	var def := StructureCatalog.get_def(type_id)
	if def.is_empty():
		return false
	var arr: Array = _get_structure_array(def.array)
	if idx < 0 or idx >= arr.size():
		return false
	var size: int = _cfg().get_int(def.size_key)
	var moved := StructurePlacement.try_move(grid_manager, pathfinder, arr[idx], new_grid_coord, size, int(def.grid_type))
	if moved:
		arr[idx] = arr[idx]
	return moved

func _try_move_structure(type_id: String, idx: int, new_pos: Vector2, require_inside_base: bool = true) -> bool:
	var def := StructureCatalog.get_def(type_id)
	if def.is_empty():
		return false
	var arr: Array = _get_structure_array(def.array)
	if idx < 0 or idx >= arr.size():
		return false
	if require_inside_base and not grid_manager.is_inside_base_point(new_pos):
		return false
	return _try_move_structure_to_grid(type_id, idx, grid_manager.world_to_base_grid(new_pos))

func _find_structure_at(array_name: String, p: Vector2, r: float) -> int:
	return StructureQuery.find_at(_get_structure_array(array_name), p, r)

func _get_max_tower_range() -> float:
	var map_width = float(_cfg().get_int("GRID_COLS") * _cfg().get_int("TILE_SIZE"))
	var map_height = float(_cfg().get_int("GRID_ROWS") * _cfg().get_int("TILE_SIZE"))
	return sqrt(map_width * map_width + map_height * map_height) * 0.5

const ButtonHoverHelper = preload("res://scripts/helpers/ButtonHoverHelper.gd")
const GridManager = preload("res://scripts/GridManager.gd")
const Pathfinder = preload("res://scripts/Pathfinder.gd")
const WaveManager = preload("res://scripts/WaveManager.gd")
const GameConstants = preload("res://scripts/Constants.gd")
const EnemyConstants = preload("res://scripts/EnemyConstants.gd")
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
const VisualEffectsManager = preload("res://scripts/managers/VisualEffectsManager.gd")
const ItemManager = preload("res://scripts/managers/ItemManager.gd")
const Talisman = preload("res://scripts/items/Talisman.gd")
const SpecialCurrencyManager = preload("res://scripts/managers/SpecialCurrencyManager.gd")
const PrestigeShop = preload("res://scripts/managers/PrestigeShop.gd")
const QuestManager = preload("res://scripts/managers/QuestManager.gd")
const WeatherManager = preload("res://scripts/managers/WeatherManager.gd")
const ObjectPoolManager = preload("res://scripts/managers/ObjectPoolManager.gd")
const CullingManager = preload("res://scripts/managers/CullingManager.gd")
const ComboManager = preload("res://scripts/managers/ComboManager.gd")
const NotificationManager = preload("res://scripts/managers/NotificationManager.gd")
const Market = preload("res://scripts/structures/Market.gd")
const SpatialHashManager = preload("res://scripts/managers/SpatialHashManager.gd")
const ToastOverlayScript = preload("res://scripts/ui/ToastOverlay.gd")
const StructureInspectPanelScript = preload("res://scripts/ui/StructureInspectPanel.gd")
const SettingsDialogScript = preload("res://scripts/ui/SettingsDialog.gd")
const TutorialOverlayScript = preload("res://scripts/ui/TutorialOverlay.gd")
const PauseOverlayControllerScript = preload("res://scripts/ui/PauseOverlayController.gd")
const UXSettings = preload("res://scripts/ui/UXSettings.gd")
const StructureCatalog = preload("res://scripts/systems/StructureCatalog.gd")
const StructureFactory = preload("res://scripts/systems/StructureFactory.gd")
const StructurePlacement = preload("res://scripts/systems/StructurePlacement.gd")
const StructureQuery = preload("res://scripts/helpers/StructureQuery.gd")
const TileOccupancy = preload("res://scripts/helpers/TileOccupancy.gd")
const PopupMenuHelper = preload("res://scripts/helpers/PopupMenuHelper.gd")

const HERO_ARROW_SPEED := 260.0  # default; override via GameConfig in custom mode
const COLLISION_LOOKUP_RADIUS := 100.0  # usado em colisões com spatial hash (se aplicado)

var grid_manager: GridManager
var pathfinder: Pathfinder
var wave_manager: WaveManager
var achievement_manager: AchievementManager
var perk_manager: PerkManager
var resource_manager: ResourceManager
var effects_manager: EffectsManager
var coin_manager: CoinManager
var reward_calculator: RewardCalculator
var hero_manager: HeroManager
var skills_manager: SkillsManager
var visual_effects_manager: VisualEffectsManager
var item_manager: ItemManager
var special_currency_manager: SpecialCurrencyManager
var prestige_shop: PrestigeShop
var quest_manager: QuestManager
var weather_manager: WeatherManager
var object_pool_manager: ObjectPoolManager
var culling_manager: CullingManager
var combo_manager: ComboManager
var notification_manager: NotificationManager
var spatial_hash_manager: SpatialHashManager
var toast_overlay: CanvasLayer
var inspect_panel: PanelContainer
var inspect_structure_type: String = ""
var inspect_structure_index: int = -1
var show_fps_enabled: bool = true

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
var tower_damage_boost_waves_remaining: int = 0
var hero_damage_boost_waves_remaining: int = 0
var heal_full_uses_remaining: int = 2
var hero_firerate_upgrade: bool = false
var hero_dual_cannon: bool = false

var perk_effects: Dictionary = {}
var coin_drop_chance: float = 0.12  # set from GameConfig in _ready

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

var base_hp := 100  # set from GameConfig in _ready
var base_hp_base := 100
var base_hp_max := 100
var paused := false
var game_over := false
var diamond_150_given: bool = false
var game_time: float = 0.0
var game_time_start: float = 0.0

var isAdmin: bool = true
var placing_type: String = ""
var placing_tower: bool:
	get:
		return placing_type == "tower"
	set(value):
		_set_placing_flag("tower", value)
var placing_barracks: bool:
	get:
		return placing_type == "barracks"
	set(value):
		_set_placing_flag("barracks", value)
var placing_mine: bool:
	get:
		return placing_type == "mine"
	set(value):
		_set_placing_flag("mine", value)
var placing_slow_tower: bool:
	get:
		return placing_type == "slow_tower"
	set(value):
		_set_placing_flag("slow_tower", value)
var placing_aoe_tower: bool:
	get:
		return placing_type == "aoe_tower"
	set(value):
		_set_placing_flag("aoe_tower", value)
var placing_sniper_tower: bool:
	get:
		return placing_type == "sniper_tower"
	set(value):
		_set_placing_flag("sniper_tower", value)
var placing_boost_tower: bool:
	get:
		return placing_type == "boost_tower"
	set(value):
		_set_placing_flag("boost_tower", value)
var placing_shock_tower: bool:
	get:
		return placing_type == "shock_tower"
	set(value):
		_set_placing_flag("shock_tower", value)
var placing_anti_air_tower: bool:
	get:
		return placing_type == "anti_air_tower"
	set(value):
		_set_placing_flag("anti_air_tower", value)
var placing_wall: bool:
	get:
		return placing_type == "wall"
	set(value):
		_set_placing_flag("wall", value)
var placing_healing_station: bool:
	get:
		return placing_type == "healing_station"
	set(value):
		_set_placing_flag("healing_station", value)
var placing_market: bool:
	get:
		return placing_type == "market"
	set(value):
		_set_placing_flag("market", value)

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
var anti_air_towers: Array = []
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
var anti_air_menu: PopupMenu
var anti_air_selected_index := -1
var keep_anti_air_menu_open := false
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
var tex_alien_voador: Texture2D
var tex_enemy_boss_zombie: Texture2D
var tex_enemy_boss_alien: Texture2D
var tex_enemy_boss_mecanoide: Texture2D
var tex_mecanoide_bipede: Texture2D
var tex_mecanoide_lagartas: Texture2D
var tex_mecanoide_drone: Texture2D
var tex_mecanoide_regenerado: Texture2D
var tex_boss_aura: Texture2D
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
var tex_anti_air_tower: Texture2D
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
var tower_shop_collapsed: bool = true
var skills_panel_collapsed: bool = true
var tower_shop_toggle_button: Button
var skills_panel_toggle_button: Button

var game_tooltip: Control
var tooltip_text: String = ""
var tooltip_timer: float = 0.0

var admin_menu: PopupMenu
var admin_menu_button: Button

var base_hp_progress_bar: ProgressBar = null

var range_indicator: Line2D

var boss_alert_label: Label
var boss_alert_timer: float = 0.0
var boss_alert_duration: float = 4.0  # set from GameConfig in _ready
var boss_warning_sound: AudioStream
var boss_alert_player: AudioStreamPlayer
var coin_sound_players: Array = []

var special_wave_alert_label: Label
var special_wave_alert_timer: float = 0.0
var current_special_wave_type: WaveManager.SpecialWaveType = WaveManager.SpecialWaveType.NONE
var special_wave_coin_multiplier: float = 1.0
var perfect_wave_bonus_given: bool = false

var game_background_layer: CanvasLayer = null
var game_background_texture: TextureRect = null
var game_background_dim: ColorRect = null

var weather_overlay: ColorRect
var weather_clouds: Array = []
var weather_rain_particles: Array = []
var weather_snow_particles: Array = []
var weather_wind_particles: Array = []
var weather_alert_label: Label
var weather_alert_timer: float = 0.0
var weather_effects_active: bool = false

var emerald_label: Label
var diamond_label: Label

var pause_overlay: Control
var save_status_label: Label

var _cached_map_width: float = 0.0
var _cached_map_height: float = 0.0
var _cached_grid_size_px: float = 0.0
var _ui_update_timer: float = 0.0
var _ui_update_interval: float = 0.1

var _cached_tile_size: float = 28.0  # set from GameConfig in _ready
var _cached_base_half_size: int = 3
var _cached_base_grid_size: int = 15
var _static_map_texture: ImageTexture = null

var skills_panel: Panel
var skill_buttons: Dictionary = {}

var tower_dps_data: Dictionary = {}
var dps_menu_panel: Panel = null
var dps_menu_visible: bool = false

func _wave_factor() -> float:
	var factor = wave_manager.wave_factor()

	if perk_effects.has("wave_scale_reduction"):


		var reduction = perk_effects["wave_scale_reduction"]



		factor *= (1.0 - reduction)
	return factor

func get_effective_tower_range(base_range: float) -> float:
	if weather_manager:
		return base_range * weather_manager.get_tower_range_multiplier()
	return base_range

func get_effective_tower_damage(base_damage: float) -> float:
	if weather_manager:
		return base_damage * weather_manager.get_tower_damage_multiplier()
	return base_damage

func _weather_shot_hits() -> bool:
	if weather_manager == null:
		return true
	var accuracy: float = weather_manager.get_tower_accuracy_multiplier()
	if accuracy >= 1.0:
		return true
	return randf() <= accuracy

func _shop_wave() -> int:
	if wave_manager == null:
		return 1
	return maxi(wave_manager.wave, 1)

func _structure_unlock_wave(type_id: String) -> int:
	var def := StructureCatalog.get_def(type_id)
	var key: String = str(def.get("unlock_wave_key", ""))
	if key.is_empty():
		return 1
	return _cfg().get_int(key)

func _is_structure_unlocked(type_id: String) -> bool:
	return _shop_wave() >= _structure_unlock_wave(type_id)

## Chance de crítico das torres: base + bônus dos talismãs (acumula com talismã de crítico).
func _get_tower_crit_chance() -> float:
	var chance: float = _cfg().get_float("TOWER_CRIT_CHANCE_BASE")
	if item_manager:
		var effects = item_manager.get_all_effects()
		if effects.has("critical_chance_boost"):
			chance += effects["critical_chance_boost"]
	return minf(chance, 1.0)

## Multiplicador de dano crítico das torres: base * bônus dos talismãs (acumula com talismã de dano crítico).
func _get_tower_crit_multiplier() -> float:
	var mult: float = _cfg().get_float("TOWER_CRIT_MULTIPLIER_BASE")
	var perk_mult: float = perk_effects.get("tower_crit_damage_multiplier", 1.0)
	return mult * perk_mult

func _boost_aura_effect_mult() -> float:
	if prestige_shop:
		return prestige_shop.get_boost_aura_effect_multiplier()
	return 1.0

func _is_in_boost_range(tower_pos: Vector2, boost: Dictionary) -> bool:
	var r: float = float(boost.get("range", 0.0))
	if prestige_shop:
		r *= prestige_shop.get_boost_aura_range_multiplier()
	return tower_pos.distance_squared_to(boost.pos) <= r * r

func _boost_rate_bonus(tower_pos: Vector2) -> float:
	var bonus := 0.0
	var aura := _boost_aura_effect_mult()
	for boost in boost_towers:
		if _is_in_boost_range(tower_pos, boost):
			bonus += float(boost.get("rate_boost", 0.0)) * aura
	return bonus

func _boost_damage_bonus(tower_pos: Vector2) -> float:
	var bonus := 0.0
	var aura := _boost_aura_effect_mult()
	for boost in boost_towers:
		if _is_in_boost_range(tower_pos, boost):
			bonus += float(boost.get("damage_boost", 0.0)) * aura
	return bonus

func _combo_bonus_for(tower_pos: Vector2, tower_type: String) -> Dictionary:
	if combo_manager:
		return combo_manager.get_combo_bonus_for_tower(tower_pos, tower_type)
	return {"damage_multiplier": 1.0, "range_multiplier": 1.0, "crit_bonus": 0.0, "special_effect": ""}

func _apply_combo_hit_effects(enemy: Dictionary, special_effect: String, source_damage: float) -> void:
	if special_effect.is_empty():
		return
	var enemy_idx: int = int(enemy.get("idx", -1))
	if enemy_idx < 0:
		return
	if not enemy_effects.has(enemy_idx):
		enemy_effects[enemy_idx] = {"slow_time": 0.0, "slow_amount": 0.0, "freeze_time": 0.0, "fire_time": 0.0, "fire_damage": 0.0}
	var effects: Dictionary = enemy_effects[enemy_idx]
	if special_effect == "slow_bonus":
		effects.slow_time = max(float(effects.get("slow_time", 0.0)), 2.0)
		effects.slow_amount = max(float(effects.get("slow_amount", 0.0)), 0.25)
	elif special_effect == "wall_fire":
		effects.fire_time = max(float(effects.get("fire_time", 0.0)), _cfg().get_float("TOWER_FIRE_DURATION"))
		effects.fire_damage = max(float(effects.get("fire_damage", 0.0)), source_damage * _cfg().get_float("TOWER_FIRE_DAMAGE_MULTIPLIER"))

func get_enemy_reward() -> int:
	var base_reward = reward_calculator.get_enemy_reward()
	var multiplier = special_wave_coin_multiplier


	if perk_effects.has("enemy_reward"):
		multiplier *= (1.0 + perk_effects["enemy_reward"])


	if perk_effects.has("early_wave_boost") and wave_manager and wave_manager.wave <= 20:
		multiplier *= (1.0 + perk_effects["early_wave_boost"])

	if current_special_wave_type == WaveManager.SpecialWaveType.DOUBLE_COINS:
		return int(base_reward * 2.0 * multiplier)
	return int(base_reward * multiplier)

func get_boss_reward() -> int:
	var base_reward = reward_calculator.get_boss_reward()
	var multiplier = special_wave_coin_multiplier


	if perk_effects.has("boss_reward"):
		multiplier *= (1.0 + perk_effects["boss_reward"])


	if perk_effects.has("early_wave_boost") and wave_manager and wave_manager.wave <= 20:
		multiplier *= (1.0 + perk_effects["early_wave_boost"])

	if current_special_wave_type == WaveManager.SpecialWaveType.DOUBLE_COINS:
		return int(base_reward * 2.0 * multiplier)
	return int(base_reward * multiplier)

func get_upgrade_cost(base_cost: int, current_level: int) -> int:
	"""Calcula custo de upgrade com escala progressiva"""
	return RewardCalculator.get_upgrade_cost(base_cost, current_level)

func get_wave_completion_bonus() -> int:
	"""Calcula bonus de moedas por completar uma wave (com cap máximo)"""
	var base_bonus = reward_calculator.get_wave_completion_bonus()
	var multiplier = 1.0


	if perk_effects.has("wave_reward"):
		multiplier *= (1.0 + perk_effects["wave_reward"])


	if perk_effects.has("perfect_wave_bonus") and perfect_wave_bonus_given:
		multiplier *= (1.0 + perk_effects["perfect_wave_bonus"])


	if perk_effects.has("special_wave_bonus") and current_special_wave_type != WaveManager.SpecialWaveType.NONE:
		multiplier *= (1.0 + perk_effects["special_wave_bonus"])


	if perk_effects.has("early_wave_boost") and wave_manager and wave_manager.wave <= 20:
		multiplier *= (1.0 + perk_effects["early_wave_boost"])


	if current_special_wave_type != WaveManager.SpecialWaveType.NONE and current_special_wave_type != WaveManager.SpecialWaveType.PERFECT_WAVE:
		multiplier *= special_wave_coin_multiplier

	return int(base_bonus * multiplier)

func _grant_wave_completion_rewards() -> void:
	var wave_bonus = get_wave_completion_bonus()
	hero["coins"] += wave_bonus
	_track_coin_collected(wave_bonus)

	if quest_manager:
		quest_manager.update_quest_progress(GameConstants.QuestType.COMPLETE_WAVES, 1)
		quest_manager.update_quest_progress(GameConstants.QuestType.REACH_WAVE, 1)

	if wave_manager.wave == 150 and special_currency_manager and not diamond_150_given:
		special_currency_manager.add_diamonds(1, "wave_150_milestone")
		diamond_150_given = true
		print("Diamante obtido por alcançar a wave 150!")

	var upgrade_text := ""
	if hero_manager:
		var next_upgrade = hero_manager.get_next_fixed_upgrade()
		if not next_upgrade.is_empty():
			var code: String = next_upgrade["code"]
			if hero_manager.apply_upgrade(code):
				upgrade_text = hero_manager.get_upgrade_gain_text(code)

	var toast_text = "+%d moedas" % wave_bonus
	if not upgrade_text.is_empty():
		toast_text += " | " + upgrade_text
	_notify_success(toast_text)

	_auto_save_after_wave()

func get_tower_cost(base_cost: int) -> int:
	"""Calcula custo de torre baseado na wave atual"""
	var cost: int = reward_calculator.get_tower_cost(base_cost)
	if perk_effects.has("tower_cost_reduction"):
		cost = int(float(cost) * (1.0 - perk_effects["tower_cost_reduction"]))
	return max(1, cost)

func _setup_toast_overlay() -> void:
	if toast_overlay != null:
		return
	toast_overlay = ToastOverlayScript.new()
	toast_overlay.name = "ToastOverlay"
	add_child(toast_overlay)
	toast_overlay.setup(notification_manager)

func _setup_inspect_panel() -> void:
	if inspect_panel != null:
		return
	var hud = $CanvasLayer/HUD
	inspect_panel = StructureInspectPanelScript.new()
	inspect_panel.name = "StructureInspectPanel"
	inspect_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	hud.add_child(inspect_panel)
	inspect_panel.upgrade_chosen.connect(_on_inspect_upgrade_chosen)
	inspect_panel.sell_confirmed.connect(_on_inspect_sell_confirmed)
	inspect_panel.closed.connect(_on_inspect_closed)

func _notify_warning(text: String) -> void:
	if notification_manager:
		notification_manager.show_warning(text)

func _notify_success(text: String) -> void:
	if notification_manager:
		notification_manager.show_success(text)

func _on_achievement_unlocked(achievement_name: String) -> void:
	if notification_manager:
		notification_manager.show_achievement_notification(achievement_name)

func _toast_cannot_afford() -> void:
	_notify_warning("Moedas insuficientes")

func _toast_at_build_limit() -> void:
	_notify_warning("Limite de construções atingido")

func _toast_invalid_placement() -> void:
	_notify_warning("Não dá para colocar aqui")

func _toast_skill_cooldown() -> void:
	_notify_warning("Skill em recarga")

func _toast_locked_until_wave(wave_number: int) -> void:
	_notify_warning("Desbloqueia na onda %d" % wave_number)

func _buy_blocked(can_afford: bool, at_max: bool) -> bool:
	if not can_afford:
		_toast_cannot_afford()
		return true
	if at_max:
		_toast_at_build_limit()
		return true
	return false

func _present_inspect(data: Dictionary) -> void:
	if inspect_panel == null:
		_setup_inspect_panel()
	inspect_structure_type = str(data.get("type", ""))
	inspect_structure_index = int(data.get("index", -1))
	var range_pos: Vector2 = data.get("range_pos", Vector2.ZERO)
	var range_val: float = float(data.get("range", 0.0))
	if range_val > 0.0:
		_show_range_indicator(range_pos, range_val)
	inspect_panel.present(data)

func _present_from_popup(menu: PopupMenu, title: String, stats: String, range_pos: Vector2, range_val: float, structure_type: String, idx: int, screen_pos: Vector2) -> void:
	if menu == null:
		return
	var upgrades: Array = []
	for i in range(menu.item_count):
		if menu.is_item_separator(i):
			continue
		var item_text := String(menu.get_item_text(i))
		if item_text.strip_edges().is_empty():
			continue
		upgrades.append({
			"id": menu.get_item_id(i),
			"text": item_text,
			"enabled": not menu.is_item_disabled(i)
		})
	_present_inspect({
		"title": title,
		"stats": stats,
		"upgrades": upgrades,
		"sell_refund": _sell_refund_amount(structure_type, idx),
		"can_sell": true,
		"type": structure_type,
		"index": idx,
		"screen_pos": screen_pos,
		"range_pos": range_pos,
		"range": range_val
	})

func _inspect_screen_pos() -> Vector2:
	if inspect_panel and inspect_panel.visible:
		return inspect_panel.position
	return get_viewport().get_mouse_position()

func _on_inspect_upgrade_chosen(id: int) -> void:
	match inspect_structure_type:
		"tower":
			_on_tower_menu_pressed(id)
		"barracks":
			_on_barracks_menu_pressed(id)
		"sniper":
			_on_sniper_menu_pressed(id)
		"aoe":
			_on_aoe_menu_pressed(id)
		"anti_air":
			_on_anti_air_menu_pressed(id)
		"shock":
			_on_shock_menu_pressed(id)
		"slow":
			_on_slow_menu_pressed(id)
		"boost":
			_on_boost_menu_pressed(id)
		"wall":
			_on_wall_menu_pressed(id)

func _on_inspect_sell_confirmed() -> void:
	_sell_structure(inspect_structure_type, inspect_structure_index)

func _on_inspect_closed() -> void:
	_hide_range_indicator()
	inspect_structure_type = ""
	inspect_structure_index = -1

func _hide_inspect_panel() -> void:
	if inspect_panel and inspect_panel.visible:
		inspect_panel.hide_panel()

func _is_pointer_on_inspect_panel(screen_pos: Vector2) -> bool:
	if inspect_panel == null or not inspect_panel.visible:
		return false
	return inspect_panel.get_global_rect().has_point(screen_pos)

func _is_pointer_on_blocking_ui(screen_pos: Vector2) -> bool:
	if _is_pointer_on_inspect_panel(screen_pos):
		return true
	var hovered := get_viewport().gui_get_hovered_control()
	return hovered is BaseButton

func _open_inspect_for_type(structure_type: String, idx: int, screen_pos: Vector2) -> void:
	match structure_type:
		"tower":
			_open_tower_menu(idx, screen_pos)
		"slow_tower":
			_open_slow_menu(idx, screen_pos)
		"aoe_tower":
			_open_aoe_menu(idx, screen_pos)
		"sniper_tower":
			_open_sniper_menu(idx, screen_pos)
		"boost_tower":
			_open_boost_menu(idx, screen_pos)
		"shock_tower":
			_open_shock_menu(idx, screen_pos)
		"anti_air_tower":
			_open_anti_air_menu(idx, screen_pos)
		"barracks":
			_open_barracks_menu(idx, screen_pos)
		"wall":
			_show_wall_menu(idx, Vector2.ZERO)
		"market":
			_open_market_menu(idx, screen_pos)
		"mine":
			_present_inspect({
				"title": "Mina",
				"stats": "Explode ao contato com inimigos.",
				"upgrades": [],
				"sell_refund": _sell_refund_amount("mine", idx),
				"can_sell": true,
				"type": "mine",
				"index": idx,
				"screen_pos": screen_pos,
				"range": 0.0
			})
		"healing_station":
			_present_inspect({
				"title": "Estação de Cura",
				"stats": "Regenera a vida da base periodicamente.",
				"upgrades": [],
				"sell_refund": _sell_refund_amount("healing_station", idx),
				"can_sell": true,
				"type": "healing_station",
				"index": idx,
				"screen_pos": screen_pos,
				"range": 0.0
			})

func _current_structure_buy_cost(structure_type: String) -> int:
	match structure_type:
		"tower":
			return get_tower_cost(_cfg().get_int("TOWER_COST"))
		"barracks":
			return get_tower_cost(_cfg().get_int("BARRACKS_COST"))
		"slow", "slow_tower":
			return get_tower_cost(_cfg().get_int("SLOW_TOWER_COST"))
		"aoe", "aoe_tower":
			return get_tower_cost(_cfg().get_int("AOE_TOWER_COST"))
		"sniper", "sniper_tower":
			return get_tower_cost(_cfg().get_int("SNIPER_TOWER_COST"))
		"boost", "boost_tower":
			return get_tower_cost(_cfg().get_int("BOOST_TOWER_COST"))
		"shock", "shock_tower":
			return get_tower_cost(_cfg().get_int("SHOCK_TOWER_COST"))
		"anti_air", "anti_air_tower":
			return get_tower_cost(_cfg().get_int("ANTI_AIR_TOWER_COST"))
		"wall":
			return get_wall_cost()
		"mine":
			return _cfg().get_int("MINE_COST")
		"healing_station":
			return _cfg().get_int("HEALING_STATION_COST")
		"market":
			return 0
	return 0

func _structure_array_and_item(structure_type: String, idx: int) -> Dictionary:
	var arr: Array = []
	match structure_type:
		"tower":
			arr = towers
		"barracks":
			arr = barracks
		"slow", "slow_tower":
			arr = slow_towers
		"aoe", "aoe_tower":
			arr = aoe_towers
		"sniper", "sniper_tower":
			arr = sniper_towers
		"boost", "boost_tower":
			arr = boost_towers
		"shock", "shock_tower":
			arr = shock_towers
		"anti_air", "anti_air_tower":
			arr = anti_air_towers
		"wall":
			arr = walls
		"mine":
			arr = mines
		"healing_station":
			arr = healing_stations
		"market":
			arr = markets
	if idx < 0 or idx >= arr.size():
		return {}
	return {"array": arr, "item": arr[idx]}

func _estimate_upgrade_coins(structure: Dictionary) -> int:
	var invested := int(structure.get("coins_invested", 0))
	if invested > 0:
		return invested
	return 0

func _sell_refund_amount(structure_type: String, idx: int) -> int:
	var info := _structure_array_and_item(structure_type, idx)
	if info.is_empty():
		return 0
	var buy_cost := _current_structure_buy_cost(structure_type)
	var item: Dictionary = info.item
	var invested := _estimate_upgrade_coins(item)
	if invested <= 0:
		invested = buy_cost
	var upgrade_part := maxi(0, invested - buy_cost)
	return int(buy_cost * 0.5 + upgrade_part * 0.5)

func _sell_structure(structure_type: String, idx: int) -> void:
	var info := _structure_array_and_item(structure_type, idx)
	if info.is_empty():
		return
	var refund := _sell_refund_amount(structure_type, idx)
	var item: Dictionary = info.item
	var size_key := ""
	match structure_type:
		"tower":
			size_key = "TOWER_SIZE_GRID"
		"barracks":
			size_key = "BARRACKS_SIZE_GRID"
		"slow", "slow_tower":
			size_key = "SLOW_TOWER_SIZE_GRID"
		"aoe", "aoe_tower":
			size_key = "AOE_TOWER_SIZE_GRID"
		"sniper", "sniper_tower":
			size_key = "SNIPER_TOWER_SIZE_GRID"
		"boost", "boost_tower":
			size_key = "BOOST_TOWER_SIZE_GRID"
		"shock", "shock_tower":
			size_key = "SHOCK_TOWER_SIZE_GRID"
		"anti_air", "anti_air_tower":
			size_key = "ANTI_AIR_TOWER_SIZE_GRID"
		"healing_station":
			size_key = "HEALING_STATION_SIZE_GRID"
		"market":
			size_key = "MARKET_SIZE_GRID"
		"wall":
			size_key = "WALL_SIZE_GRID"
	if item.has("grid_x") and item.has("grid_y") and size_key != "":
		grid_manager.clear_grid_area(int(item.grid_x), int(item.grid_y), _cfg().get_int(size_key))
	if structure_type == "mine" and item.has("grid_x"):
		_unregister_mine_tile(Vector2i(int(item.grid_x), int(item.grid_y)))
	if structure_type == "wall" and item.has("grid_x"):
		_unregister_wall_tile(Vector2i(int(item.grid_x), int(item.grid_y)))
		pathfinder.set_wall_tiles(wall_tiles)
	info.array.remove_at(idx)
	pathfinder.invalidate_cache()
	hero["coins"] += refund
	_hide_inspect_panel()
	_notify_success("Vendido: +%d moedas" % refund)
	queue_redraw()

func _show_settings_dialog() -> void:
	var dlg := SettingsDialogScript.new(music_volume)
	dlg.music_volume_changed.connect(_on_music_volume_changed)
	dlg.settings_changed.connect(_on_ux_settings_changed)
	add_child(dlg)
	dlg.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_ux_settings_changed() -> void:
	show_fps_enabled = UXSettings.show_fps()
	_update_bottom_bar()

func _show_tutorial(force: bool = false) -> void:
	if not force and UXSettings.is_tutorial_done():
		return
	if has_node("TutorialOverlay"):
		return
	var overlay := TutorialOverlayScript.new()
	overlay.name = "TutorialOverlay"
	add_child(overlay)

func _add_coins_invested(structure: Dictionary, amount: int) -> void:
	structure["coins_invested"] = int(structure.get("coins_invested", 0)) + amount

func _get_bonus_fire_rate_multiplier() -> float:
	var mult: float = 1.0 + perk_effects.get("tower_fire_rate", 0.0)
	if item_manager:
		var effects = item_manager.get_all_effects()
		mult += effects.get("tower_fire_rate_boost", 0.0)
	return mult

func _calc_effective_fire_rate(base_fire_rate: float, rate_multiplier: float) -> float:
	return max(_cfg().get_float("BONUS_MIN_FIRE_RATE"), base_fire_rate / rate_multiplier)

func _clamp_hero_fire_rate_from_bonus(fire_rate: float) -> float:
	return max(_cfg().get_float("BONUS_MIN_FIRE_RATE"), fire_rate)

func get_wall_cost() -> int:
	"""Calcula custo de muralha baseado no número de muralhas já construídas (acumulativo) e wave atual"""
	return reward_calculator.get_wall_cost(walls.size())

func get_tower_upgrade_emerald_cost(upgrade_type: String, current_level: int) -> int:
	"""Calcula custo em esmeraldas para upgrade de torre (escalado)"""
	var base_cost = _cfg().get_int("TOWER_UPGRADE_EMERALD_BASE_COST")
	var scale = _cfg().get_float("TOWER_UPGRADE_EMERALD_SCALE")

	return int(base_cost * pow(scale, current_level))

func get_mine_damage() -> float:
	"""Retorna o dano das minas considerando upgrades globais"""
	var dmg: float = _cfg().get_float("MINE_DAMAGE") + (mine_damage_level * _cfg().get_float("MINE_UPGRADE_DAMAGE_AMOUNT"))
	if perk_effects.has("mine_damage"):
		dmg *= (1.0 + perk_effects["mine_damage"])
	return dmg

func get_mine_explosion_radius() -> float:
	"""Retorna o raio de explosão das minas considerando upgrades globais"""
	return _cfg().get_float("MINE_EXPLOSION_RADIUS") + (mine_radius_level * _cfg().get_float("MINE_UPGRADE_RADIUS_AMOUNT"))

func get_mine_upgrade_damage_cost() -> int:
	"""Retorna o custo do próximo upgrade de dano de minas"""
	return get_upgrade_cost(_cfg().get_int("MINE_UPGRADE_DAMAGE_COST"), mine_damage_level)

func get_mine_upgrade_radius_cost() -> int:
	"""Retorna o custo do próximo upgrade de raio de minas"""
	return get_upgrade_cost(_cfg().get_int("MINE_UPGRADE_RADIUS_COST"), mine_radius_level)

func upgrade_mine_damage() -> bool:
	"""Compra upgrade de dano de minas. Retorna true se bem-sucedido"""
	if mine_damage_level >= _cfg().get_int("MINE_UPGRADE_DAMAGE_MAX_LEVEL"):
		return false
	var cost = get_mine_upgrade_damage_cost()
	if hero["coins"] < cost:
		return false
	hero["coins"] -= cost
	_track_coin_spent(cost)
	mine_damage_level += 1
	_update_all_mines_stats()
	return true

func upgrade_mine_radius() -> bool:
	"""Compra upgrade de raio de minas. Retorna true se bem-sucedido"""
	if mine_radius_level >= _cfg().get_int("MINE_UPGRADE_RADIUS_MAX_LEVEL"):
		return false
	var cost = get_mine_upgrade_radius_cost()
	if hero["coins"] < cost:
		return false
	hero["coins"] -= cost
	_track_coin_spent(cost)
	mine_radius_level += 1
	_update_all_mines_stats()
	return true

func _update_all_mines_stats() -> void:
	"""Atualiza as estatísticas de todas as minas existentes com os novos valores de upgrade"""
	for i in range(mines.size()):
		if not mines[i].triggered:
			mines[i]["damage"] = get_mine_damage()
			mines[i]["explosion_radius"] = get_mine_explosion_radius()

var choosing_upgrade := false

var hero := {
	"x": 0.0, "y": 0.0, "cooldown": 0.0, "fire_rate": 1.0,
	"damage": 0.9, "pierce": 0, "range": 9999.0,
	"levels": { "DMG": 0, "FIRERATE": 0, "PIERCE": 0, "CRIT_CHANCE": 0, "CRIT_DMG": 0 },
	"coins": 0,
	"crit_chance": 0.0,
	"crit_multiplier": 2.0,
}

var hero_damage_base: float = 0.9
var hero_fire_rate_base: float = 1.0
var hero_crit_chance_base: float = 0.0
var global_tower_damage_boost_base: float = 1.0
var coin_drop_chance_base: float = 0.12

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


	diamond_150_given = false

	if hero_manager:
		return hero_manager.get_hero_home_upgrade_cost(level, current_wave)


	var base_cost = hero_home_upgrade_costs.get(level, 0)
	if base_cost <= 0:
		return 0
	var wave_multiplier = 1.0 + (current_wave * 0.01)
	return int(base_cost * wave_multiplier)

func _get_hero_home_benefits_text(level: int) -> String:
	"""Delegado para HeroManager"""
	if hero_manager:
		return hero_manager.get_hero_home_benefits_text(level)

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

		global_tower_damage_boost = hero_manager.global_tower_damage_boost
		var old_base_hp = base_hp
		base_hp = hero_manager.base_hp

		var hp_increase = base_hp - old_base_hp
		if hp_increase > 0:
			base_hp_max += hp_increase
		hero_home_level = hero_manager.hero_home_level


		if changes.has("range") and changes["range"] > 0:
			hero["range"] += changes["range"]
		if changes.has("pierce") and changes["pierce"] > 0:
			hero["pierce"] += changes["pierce"]
		if changes.has("fire_rate") and changes["fire_rate"] < 0:
			hero["fire_rate"] = _clamp_hero_fire_rate_from_bonus(hero["fire_rate"] + changes["fire_rate"])
		return

	match level:
		2:
			global_tower_damage_boost *= 1.10
			hero["range"] += 100
			base_hp += 40
			base_hp_max += 40
		3:
			global_tower_damage_boost *= 1.10
			hero["pierce"] += 1
			hero["fire_rate"] = _clamp_hero_fire_rate_from_bonus(hero["fire_rate"] - _cfg().get_float("HERO_FIRE_RATE_REDUCTION"))
			base_hp += 60
			base_hp_max += 60
		4:
			global_tower_damage_boost *= 1.15
			hero["damage"] *= 1.15
			hero["fire_rate"] = _clamp_hero_fire_rate_from_bonus(hero["fire_rate"] - 0.08)
			hero["range"] += 150
			base_hp += _cfg().get_float("HERO_BASE_HP")
			base_hp_max += _cfg().get_float("HERO_BASE_HP")


func _try_load_music(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path)
	return null



func _ready() -> void:

	_create_loading_screen()

	grid_manager = GridManager.new()
	pathfinder = Pathfinder.new(grid_manager.grid, grid_manager.center)
	wave_manager = WaveManager.new()
	achievement_manager = AchievementManager.get_instance()
	perk_manager = PerkManager.get_instance()


	reward_calculator = RewardCalculator.new(wave_manager)


	skills_manager = SkillsManager.new(self)

	item_manager = ItemManager.new()

	if item_manager:
		item_manager.item_equipped.connect(_on_item_equipped)
		item_manager.item_unequipped.connect(_on_item_unequipped)


	special_currency_manager = SpecialCurrencyManager.new()
	quest_manager = QuestManager.new()
	prestige_shop = PrestigeShop.new()
	weather_manager = WeatherManager.new()
	object_pool_manager = ObjectPoolManager.new()
	culling_manager = CullingManager.new()
	combo_manager = ComboManager.new()
	notification_manager = NotificationManager.new()
	_setup_toast_overlay()
	if achievement_manager and not achievement_manager.achievement_unlocked.is_connected(_on_achievement_unlocked):
		achievement_manager.achievement_unlocked.connect(_on_achievement_unlocked)


	var viewport = get_viewport()
	if viewport:
		culling_manager.update_viewport_size(viewport.get_visible_rect().size)


	_load_pending_quest_rewards()


	game_time = 0.0
	game_time_start = Time.get_ticks_msec() / 1000.0



	_cached_tile_size = float(_cfg().get_int("TILE_SIZE"))
	_cached_base_half_size = int(_cfg().get_int("BASE_SIZE_TILES") / 2)
	_cached_base_grid_size = _cfg().get_int("BASE_GRID_SIZE")
	boss_alert_duration = _cfg().get_float("BOSS_ALERT_DURATION")
	hero_damage_base = _cfg().get_float("HERO_BASE_DAMAGE")
	hero_fire_rate_base = _cfg().get_float("HERO_BASE_FIRE_RATE")
	hero_crit_chance_base = 0.0
	base_hp_base = _cfg().get_float("HERO_BASE_HP")
	base_hp_max = base_hp_base
	global_tower_damage_boost_base = 1.0
	coin_drop_chance_base = _cfg().get_float("COIN_DROP_CHANCE")


	hero["damage"] = hero_damage_base
	hero["fire_rate"] = hero_fire_rate_base
	hero["crit_chance"] = hero_crit_chance_base
	base_hp = base_hp_base
	global_tower_damage_boost = global_tower_damage_boost_base
	global_tower_range_boost = 1.0
	coin_drop_chance = coin_drop_chance_base
	game_time = 0.0
	game_time_start = Time.get_ticks_msec() / 1000.0


	if object_pool_manager:
		object_pool_manager.clear_all_pools()


	_apply_prestige_bonuses()

	_apply_perk_effects()


	_apply_talisman_bonuses()



	base_hp_max = max(base_hp_max, base_hp)

	base_hp = min(base_hp, base_hp_max)


	_update_all_walls_max_hp()


	wall_hp_multiplier = 1.0


	_load_music_settings()
	_load_user_preferences()


	wave_manager.wave_started.connect(_on_wave_started)



	if first_play:
		achievement_manager.increment_progress("first_play")
		first_play = false
	call_deferred("_show_tutorial")


	var bar_height: float = GameConstants.UI_TOP_BAR_HEIGHT
	var grid_px_w: float = _cfg().get_int("GRID_COLS") * _cfg().get_int("TILE_SIZE")
	var grid_px_h: float = _cfg().get_int("GRID_ROWS") * _cfg().get_int("TILE_SIZE")
	var win_w := int(grid_px_w)
	var win_h := int(grid_px_h + bar_height)
	DisplayServer.window_set_size(Vector2i(win_w, win_h))



	get_viewport().size_changed.connect(_on_viewport_size_changed)


	_create_game_background()


	call_deferred("_adjust_hud_to_screen_size")


	call_deferred("_adjust_shop_and_skills_panels")


	await get_tree().process_frame


	grid_offset = Vector2(0.0, bar_height)
	position = grid_offset

	var p = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
	hero["x"] = p.x
	hero["y"] = p.y

	resource_manager = ResourceManager.new()
	effects_manager = EffectsManager.new()
	coin_manager = CoinManager.new(effects_manager)
	if perk_effects.has("coin_value"):
		coin_manager.coin_value_bonus = int(perk_effects["coin_value"])

	resource_manager.loading_progress_updated.connect(_on_resource_loading_progress)
	coin_manager.coin_collected.connect(_on_coin_collected)

	_update_loading_progress(0.1)
	resource_manager.load_all_textures()

	tex_hero = resource_manager.load_texture("res://assets/images/hero.png", true, ResourceManager.MAX_SPRITE_SIZE)
	tex_enemy_zombie = resource_manager.get_texture("enemy_zombie")
	tex_enemy_zombie_gordo = resource_manager.get_texture("enemy_zombie_gordo")
	tex_enemy_zombie_corredor = resource_manager.get_texture("enemy_zombie_corredor")
	tex_enemy_humanoid = resource_manager.get_texture("enemy_humanoid")
	tex_enemy_robot = resource_manager.get_texture("enemy_robot")
	tex_enemy_alien = resource_manager.get_texture("enemy_alien")
	tex_alien_voador = resource_manager.get_texture("alien_voador")
	tex_enemy_boss_zombie = resource_manager.get_texture("enemy_boss_zombie")
	tex_enemy_boss_alien = resource_manager.get_texture("enemy_boss_alien")
	tex_enemy_boss_mecanoide = resource_manager.get_texture("mecanoide_boss1")
	tex_mecanoide_bipede = resource_manager.get_texture("mecanoide_bipede1")
	tex_mecanoide_lagartas = resource_manager.get_texture("mecanoide_lagartas1")
	tex_mecanoide_drone = resource_manager.get_texture("mecanoide_drone1")
	tex_mecanoide_regenerado = resource_manager.get_texture("mecanoide_regenerado1")
	tex_boss_aura = resource_manager.get_texture("boss_aura")
	tex_tent = resource_manager.get_texture("tent")
	tex_house = resource_manager.get_texture("house")
	tex_castle = resource_manager.get_texture("castle")
	tex_castle2 = resource_manager.get_texture("Caste2")



	hero_manager = HeroManager.new(base_hp)
	hero_manager.set_textures(tex_tent, tex_house, tex_castle, tex_castle2)
	hero_manager.hero = hero
	hero_manager.hero_home_level = hero_home_level
	hero_manager.global_tower_damage_boost = global_tower_damage_boost


	spatial_hash_manager = SpatialHashManager.new(enemies, 100.0)

	visual_effects_manager = VisualEffectsManager.new(self, effects_manager, object_pool_manager)
	tex_grass = resource_manager.get_texture("grass")
	tex_path = resource_manager.get_texture("path")
	tex_wall = resource_manager.get_texture("wall")
	tex_tower = resource_manager.get_texture("tower")
	tex_slow_tower = resource_manager.get_texture("slow_tower")
	tex_aoe_tower = resource_manager.get_texture("aoe_tower")
	tex_sniper_tower = resource_manager.get_texture("sniper_tower")
	tex_boost_tower = resource_manager.get_texture("boost_tower")
	tex_shock_tower = resource_manager.get_texture("shock_tower")
	tex_anti_air_tower = resource_manager.get_texture("anti_air_tower")
	tex_barracks = resource_manager.get_texture("barracks")
	tex_mine = resource_manager.get_texture("mine")
	tex_wall_structure = resource_manager.get_texture("wall_structure")
	tex_healing_station = resource_manager.get_texture("healing_station")
	tex_market = resource_manager.get_texture("market")
	tex_coin = resource_manager.get_texture("coin")
	tex_talisman = resource_manager.get_texture("talism")
	tex_game_over = resource_manager.get_texture("game_over")
	_build_static_map_texture()

	var tex_bg = resource_manager.load_texture("res://assets/images/game_background.png", false, ResourceManager.MAX_BG_SIZE)
	if tex_bg == null:
		tex_bg = resource_manager.load_texture("res://assets/images/menu_background.png", false, ResourceManager.MAX_BG_SIZE)
	if game_background_texture != null and tex_bg != null:
		game_background_texture.texture = tex_bg
		game_background_texture.visible = true


	await get_tree().create_timer(0.3).timeout
	_hide_loading_screen()


	var tb = $CanvasLayer/HUD/TopBar
	tb.add_theme_stylebox_override("panel", UIHelper.hud_bar_style(false))

	var bottom_bar = $CanvasLayer/HUD.get_node_or_null("BottomBar")
	if bottom_bar:
		bottom_bar.add_theme_stylebox_override("panel", UIHelper.hud_bar_style(true))
		for pair in [
			["LblTime", Color(0.82, 0.86, 1.0)],
			["LblEnemies", Color(1.0, 0.45, 0.42)],
			["LblFPS", Color(0.55, 0.9, 0.6)]
		]:
			var lbl = bottom_bar.get_node_or_null(pair[0])
			if lbl:
				lbl.add_theme_color_override("font_color", pair[1])
				lbl.add_theme_font_size_override("font_size", 15)
				lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
				lbl.add_theme_constant_override("outline_size", 3)
				lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var lbl_left = tb.get_node("LblLeft")
	lbl_left.add_theme_color_override("font_color", Color(0.95, 0.96, 1.0))
	lbl_left.add_theme_font_size_override("font_size", 15)
	lbl_left.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var lbl_center = tb.get_node("LblCenter")
	lbl_center.add_theme_color_override("font_color", Color(1.0, 0.9, 0.35))
	lbl_center.add_theme_font_size_override("font_size", 16)
	lbl_center.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var lbl_right = tb.get_node("LblRight")
	lbl_right.add_theme_color_override("font_color", Color(1.0, 0.42, 0.4))
	lbl_right.add_theme_font_size_override("font_size", 16)
	lbl_right.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Barra de vida da base (visual)
	base_hp_progress_bar = ProgressBar.new()
	base_hp_progress_bar.name = "BaseHPBar"
	base_hp_progress_bar.custom_minimum_size = Vector2(120, 16)
	base_hp_progress_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	base_hp_progress_bar.min_value = 0
	base_hp_progress_bar.max_value = max(1, base_hp_max)
	base_hp_progress_bar.value = base_hp
	base_hp_progress_bar.show_percentage = false
	UIHelper.apply_progress_bar_style(base_hp_progress_bar, Color(0.82, 0.24, 0.26, 1.0))
	tb.add_child(base_hp_progress_bar)


	_create_special_currency_labels(tb)
	_create_admin_menu(tb)
	_create_dps_button()

	await get_tree().process_frame

	_setup_top_bar_layout(tb)
	_setup_bottom_bar_layout(bottom_bar)

	tb.layout_mode = 1
	tb.set_anchors_preset(Control.PRESET_TOP_WIDE)
	tb.offset_left = 0.0
	tb.offset_right = 0.0
	tb.offset_top = 0.0
	tb.offset_bottom = GameConstants.UI_TOP_BAR_HEIGHT


	if tb.has_node("BuyMenuButton"):
		tb.get_node("BuyMenuButton").queue_free()


	if tb.has_node("BtnMuteMusic"):
		tb.get_node("BtnMuteMusic").queue_free()


	if tb.has_node("MusicVolumeContainer"):
		tb.get_node("MusicVolumeContainer").visible = false


	if tb.has_node("BtnBuyTower"):
		tb.get_node("BtnBuyTower").queue_free()
	if tb.has_node("BtnBuyBlock"):
		tb.get_node("BtnBuyBlock").queue_free()
	if tb.has_node("BtnBuyBarracks"):
		tb.get_node("BtnBuyBarracks").queue_free()


	_create_tower_shop_ui()
	_create_game_tooltip()
	_create_skills_ui()
	_setup_inspect_panel()
	tower_shop_collapsed = UXSettings.shop_start_collapsed()
	skills_panel_collapsed = tower_shop_collapsed
	_update_tower_shop_collapse()
	_update_skills_panel_collapse()
	_adjust_shop_and_skills_panels()
	_adjust_hud_to_screen_size()
	_create_range_indicator()


	var menu_container = Control.new()
	menu_container.name = "TowerMenuContainer"
	menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tower_menu = PopupMenu.new()
	tower_menu.name = "TowerMenu"
	tower_menu.hide_on_checkable_item_selection = false

	tower_menu.add_item("Alcance +60 (💰 Moedas)", 1)
	tower_menu.add_item("Alcance +60 (🟢 Esmeraldas)", 11)
	tower_menu.add_separator()

	tower_menu.add_item("Cadência + (💰 Moedas)", 2)
	tower_menu.add_item("Cadência + (🟢 Esmeraldas)", 12)
	tower_menu.add_separator()

	tower_menu.add_item("+4 Direções", 3)
	tower_menu.add_separator()

	tower_menu.add_item("Dano +0.5 (💰 Moedas)", 4)
	tower_menu.add_item("Dano +0.5 (🟢 Esmeraldas)", 14)
	tower_menu.add_separator()

	tower_menu.add_item("Congelamento", 5)
	tower_menu.add_item("Fogo", 6)
	tower_menu.id_pressed.connect(Callable(self, "_on_tower_menu_pressed"))
	tower_menu.popup_hide.connect(Callable(self, "_on_upgrade_menu_closed"))
	menu_container.add_child(tower_menu)
	$CanvasLayer.add_child(menu_container)


	var barracks_menu_container = Control.new()
	barracks_menu_container.name = "BarracksMenuContainer"
	barracks_menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	barracks_menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barracks_menu = PopupMenu.new()
	barracks_menu.name = "BarracksMenu"
	barracks_menu.hide_on_checkable_item_selection = false
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


	var sniper_menu_container = Control.new()
	sniper_menu_container.name = "SniperMenuContainer"
	sniper_menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	sniper_menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sniper_menu = PopupMenu.new()
	sniper_menu.name = "SniperMenu"
	sniper_menu.hide_on_checkable_item_selection = false
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


	var aoe_menu_container = Control.new()
	aoe_menu_container.name = "AOEMenuContainer"
	aoe_menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	aoe_menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aoe_menu = PopupMenu.new()
	aoe_menu.name = "AOEMenu"
	aoe_menu.hide_on_checkable_item_selection = false
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


	var shock_menu_container = Control.new()
	shock_menu_container.name = "ShockMenuContainer"
	shock_menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	shock_menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shock_menu = PopupMenu.new()
	shock_menu.name = "ShockMenu"
	shock_menu.hide_on_checkable_item_selection = false
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


	var anti_air_menu_container = Control.new()
	anti_air_menu_container.name = "AntiAirMenuContainer"
	anti_air_menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	anti_air_menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anti_air_menu = PopupMenu.new()
	anti_air_menu.name = "AntiAirMenu"
	anti_air_menu.hide_on_checkable_item_selection = false
	anti_air_menu.add_item("Dano +3 (💰 Moedas)", 1)
	anti_air_menu.add_item("Dano +3 (🟢 Esmeraldas)", 10)
	anti_air_menu.add_separator()
	anti_air_menu.add_item("Taxa de Tiro + (💰 Moedas)", 2)
	anti_air_menu.add_item("Taxa de Tiro + (🟢 Esmeraldas)", 11)
	anti_air_menu.add_separator()
	anti_air_menu.add_item("Alcance +10% (💰 Moedas)", 3)
	anti_air_menu.add_item("Alcance +10% (🟢 Esmeraldas)", 12)
	anti_air_menu.add_separator()
	anti_air_menu.add_item("Mísseis +1 (🟢 Esmeraldas)", 13)
	anti_air_menu.add_separator()
	anti_air_menu.add_item("Explosão em Área (🟢 Esmeraldas)", 14)
	anti_air_menu.add_separator()
	anti_air_menu.add_item("Corrente de Alvos +1 (💰 Moedas)", 6)
	anti_air_menu.add_item("Corrente de Alvos +1 (🟢 Esmeraldas)", 15)
	anti_air_menu.id_pressed.connect(Callable(self, "_on_anti_air_menu_pressed"))
	anti_air_menu.popup_hide.connect(Callable(self, "_on_upgrade_menu_closed"))
	anti_air_menu_container.add_child(anti_air_menu)
	$CanvasLayer.add_child(anti_air_menu_container)


	var slow_menu_container = Control.new()
	slow_menu_container.name = "SlowMenuContainer"
	slow_menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	slow_menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slow_menu = PopupMenu.new()
	slow_menu.name = "SlowMenu"
	slow_menu.hide_on_checkable_item_selection = false
	slow_menu.add_item("Alcance +30 (💰 Moedas)", 1)
	slow_menu.add_item("Alcance +30 (🟢 Esmeraldas)", 10)
	slow_menu.add_separator()
	slow_menu.add_item("Slow x1.05 (💰 Moedas)", 2)
	slow_menu.add_item("Slow x1.05 (🟢 Esmeraldas)", 11)


	slow_menu.id_pressed.connect(Callable(self, "_on_slow_menu_pressed"))
	slow_menu.popup_hide.connect(Callable(self, "_on_upgrade_menu_closed"))
	slow_menu_container.add_child(slow_menu)
	$CanvasLayer.add_child(slow_menu_container)


	var boost_menu_container = Control.new()
	boost_menu_container.name = "BoostMenuContainer"
	boost_menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	boost_menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boost_menu = PopupMenu.new()
	boost_menu.name = "BoostMenu"
	boost_menu.hide_on_checkable_item_selection = false
	boost_menu.add_item("Boost Dano +10% (💰 Moedas)", 1)
	boost_menu.add_item("Boost Dano +10% (🟢 Esmeraldas)", 10)
	boost_menu.add_separator()
	boost_menu.add_item("Boost Cadência +5% (💰 Moedas)", 2)
	boost_menu.add_item("Boost Cadência +5% (🟢 Esmeraldas)", 11)

	boost_menu.id_pressed.connect(Callable(self, "_on_boost_menu_pressed"))
	boost_menu.popup_hide.connect(Callable(self, "_on_upgrade_menu_closed"))
	boost_menu_container.add_child(boost_menu)
	$CanvasLayer.add_child(boost_menu_container)


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

	pause_overlay = $CanvasLayer/PauseOverlay
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.z_index = 120
	pause_overlay.set_script(PauseOverlayControllerScript)
	if not pause_overlay.is_connected("escape_pressed", _on_pause_resume):
		pause_overlay.connect("escape_pressed", _on_pause_resume)
	var pause_panel = pause_overlay.get_node("Panel")
	pause_panel.offset_left = -210
	pause_panel.offset_right = 210
	pause_panel.offset_top = -280
	pause_panel.offset_bottom = 280
	pause_panel.clip_contents = true
	pause_panel.add_theme_stylebox_override("panel", UIHelper.panel_style())
	_pause_btn("BtnResume").pressed.connect(_on_pause_resume)
	_pause_btn("BtnSave").pressed.connect(_on_pause_save)
	_pause_btn("BtnLoad").pressed.connect(_on_pause_load)
	_pause_btn("BtnMenuMain").pressed.connect(_on_pause_menu)
	_pause_btn("BtnQuit").pressed.connect(_on_pause_quit)
	_pause_btn("BtnOptions").pressed.connect(_show_settings_dialog)
	_pause_btn("BtnDPSPause").pressed.connect(_toggle_dps_menu)
	save_status_label = _pause_btn("SaveStatusLabel")
	_layout_pause_menu(pause_panel)
	pause_overlay.visible = false


	if has_node("CanvasLayer/GameOverOverlay"):
		var go = $CanvasLayer/GameOverOverlay
		go.get_node("Panel/BtnMenu").pressed.connect(_on_game_over_menu)
		go.get_node("Panel/BtnRestart").pressed.connect(_on_game_over_restart)
		go.visible = false


		var black_overlay = ColorRect.new()
		black_overlay.name = "BlackOverlay"
		black_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		black_overlay.color = Color(0, 0, 0, 1.0)
		black_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		go.add_child(black_overlay)


		var bg_texture_rect = TextureRect.new()
		bg_texture_rect.name = "BackgroundImage"
		bg_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bg_texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		bg_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		go.add_child(bg_texture_rect)


		go.move_child(black_overlay, 0)
		go.move_child(bg_texture_rect, 1)


		if go.has_node("Panel/Title"):
			go.get_node("Panel/Title").visible = false


		var panel = go.get_node("Panel")

		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.1, 0.1, 0.15, 0.85)
		style_box.border_color = Color(0.0, 0.2, 0.4, 1.0)
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


		var btn_restart = go.get_node("Panel/BtnRestart")
		var btn_menu = go.get_node("Panel/BtnMenu")

		var btn_style = resource_manager.get_style_box("button_normal") if resource_manager else null
		var btn_hover_style = resource_manager.get_style_box("button_hover") if resource_manager else null
		if btn_style == null:
			btn_style = StyleBoxFlat.new()
			btn_style.bg_color = Color(0.2, 0.4, 0.6, 0.9)
			btn_style.border_color = Color(0.4, 0.6, 0.8, 1.0)
			btn_style.set_border_width_all(2)
			btn_style.set_corner_radius_all(5)
		if btn_hover_style == null:
			btn_hover_style = StyleBoxFlat.new()
			btn_hover_style.bg_color = Color(0.3, 0.5, 0.7, 0.95)
			btn_hover_style.border_color = Color(0.5, 0.7, 0.9, 1.0)
			btn_hover_style.set_border_width_all(2)
			btn_hover_style.set_corner_radius_all(5)
		btn_restart.add_theme_stylebox_override("normal", btn_style)
		btn_menu.add_theme_stylebox_override("normal", btn_style)
		btn_restart.add_theme_stylebox_override("hover", btn_hover_style)
		btn_menu.add_theme_stylebox_override("hover", btn_hover_style)
		UIHelper.apply_button_theme(btn_restart, UIHelper.BTN_PRIMARY)
		UIHelper.apply_button_theme(btn_menu, UIHelper.BTN_SECONDARY)


		var lbl_wave = go.get_node("Panel/LblWave")
		lbl_wave.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7, 1.0))
		lbl_wave.add_theme_font_size_override("font_size", 18)


	var music_player = get_node_or_null("MusicPlayer")
	if music_player:
		var music = resource_manager.get_audio_stream("game_music")
		if music == null:
			music = _try_load_music("res://assets/music/game_music.ogg")
			if music == null:

				music = _try_load_music("res://assets/music/game_music.mp3")
			if music == null:

				music = _try_load_music("res://assets/music/menu_music.ogg")
				if music == null:
					music = _try_load_music("res://assets/music/menu_music.mp3")
		if music != null:

			if music is AudioStreamOggVorbis:
				music.loop = true
			elif music is AudioStreamMP3:
				music.loop = true
			music_player.stream = music
			music_player.volume_db = music_volume
			music_player.play()
			print("Game: Música de fundo iniciada")
		else:
			print("Game: Música de fundo não encontrada")

	_create_boss_alert_ui()
	_load_boss_warning_sound()
	_create_special_wave_alert_ui()
	_create_weather_ui()


	var load_slot = get_tree().get_meta("load_slot", "")
	if load_slot != "":
		get_tree().remove_meta("load_slot")
		if SaveManager.has_save(load_slot) and SaveManager.load_game(self, load_slot):
			print("Jogo carregado do slot: ", load_slot)
			_apply_loaded_game_state()

	set_process(true)
	set_physics_process(true)

func _process(delta: float) -> void:

	_update_game_tooltip(delta)

	if paused or game_over:
		return



	if range_indicator and range_indicator.visible:
		if not _is_any_upgrade_menu_visible():
			_hide_range_indicator()

			tower_selected_index = -1
			sniper_selected_index = -1
			aoe_selected_index = -1
			shock_selected_index = -1
			slow_selected_index = -1
			boost_selected_index = -1
			anti_air_selected_index = -1
			barracks_selected_index = -1

	if boss_alert_timer > 0.0:
		boss_alert_timer -= delta
		if boss_alert_timer <= 0.0 and boss_alert_label:
			boss_alert_label.visible = false



		if current_special_wave_type == WaveManager.SpecialWaveType.NONE:
			if special_wave_alert_label and special_wave_alert_label.visible:
				special_wave_alert_label.visible = false
				special_wave_alert_timer = 0.0
		elif special_wave_alert_timer > 0.0:
			special_wave_alert_timer -= delta
			if special_wave_alert_label and special_wave_alert_label.visible:
				if special_wave_alert_timer <= _cfg().get_float("SPECIAL_WAVE_ALERT_FADE_OUT_START"):

					var fade_time = _cfg().get_float("SPECIAL_WAVE_ALERT_FADE_OUT_START")
					var fade_progress = special_wave_alert_timer / fade_time
					fade_progress = clamp(fade_progress, 0.0, 1.0)

					var base_color = Color(1.0, 0.8, 0.2)
					var new_color = Color(base_color.r, base_color.g, base_color.b, fade_progress)
					special_wave_alert_label.add_theme_color_override("font_color", new_color)
					var outline_alpha = 0.9 * fade_progress
					special_wave_alert_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, outline_alpha))
				else:

					var current_color = special_wave_alert_label.get_theme_color("font_color")
					if current_color.a < 1.0:
						special_wave_alert_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
						special_wave_alert_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		if special_wave_alert_timer <= 0.0 and special_wave_alert_label:
			special_wave_alert_label.visible = false

			special_wave_alert_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
			special_wave_alert_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))


		if weather_alert_timer > 0.0:
			weather_alert_timer -= delta
		if weather_alert_timer <= 0.0 and weather_alert_label:
			weather_alert_label.visible = false


		_update_weather_visuals(delta)


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


	_ui_update_timer += delta
	if _ui_update_timer >= _ui_update_interval:
		_update_skills_ui()
		_update_bottom_bar()
		_update_hud_top_bar()

		if _ui_update_timer >= 0.2:
			_update_tower_shop_ui()
			_ui_update_timer = 0.0
		else:
			_ui_update_timer -= _ui_update_interval

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
	if spatial_hash_manager:
		spatial_hash_manager.update_grid()
	_handle_collisions()

	_recycle_dead_projectiles(arrows, "arrow")
	_recycle_dead_projectiles(tower_bullets, "bullet")

	if effects_manager:
		effects_manager.update_effects(delta)
		aoe_effects = effects_manager.get_aoe_effects()
		sniper_effects = effects_manager.get_sniper_effects()
		coin_collect_effects = effects_manager.get_coin_collect_effects()


	if visual_effects_manager:
		visual_effects_manager.update_effects(delta)

		damage_numbers = visual_effects_manager.get_damage_numbers()
		enemy_death_animations = visual_effects_manager.get_death_animations()
		shock_effects = visual_effects_manager.get_shock_effects()
	else:

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


	_update_dropped_talismans(delta)

	var enemy_idx_map: Dictionary = _compact_enemies(delta)


	for s in soldiers:
		if s.hp > 0 and s.target_enemy_idx >= 0:
			if not enemy_idx_map.is_empty():
				if enemy_idx_map.has(s.target_enemy_idx):
					s.target_enemy_idx = enemy_idx_map[s.target_enemy_idx]
				else:
					s.target_enemy_idx = -1
			elif enemies.is_empty():
				s.target_enemy_idx = -1




	_update_barracks(delta)
	_update_soldiers(delta)


	if not wave_manager.spawning and enemies.is_empty() and not choosing_upgrade:
		if wave_manager.wave > 0:

			var base_center = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
			var base_center_cached = base_center
			for hs in healing_stations:
				var dist_sq = hs.pos.distance_squared_to(base_center_cached)
				var range_sq = hs.range * hs.range
				if dist_sq <= range_sq:


					if base_hp_max < base_hp:
						base_hp_max = base_hp

					var new_hp = base_hp + hs.heal_amount
					base_hp = min(base_hp_max, new_hp)


			if tower_damage_boost_waves_remaining > 0:
				tower_damage_boost_waves_remaining -= 1
				if tower_damage_boost_waves_remaining <= 0:
					global_tower_damage_boost = 1.0
					if notification_manager:
						notification_manager.show_notification("Buff de Dano Torres expirou!", 3.0, NotificationManager.NotificationPosition.TOP_CENTER, Color(0.8, 0.2, 0.2))

			if hero_damage_boost_waves_remaining > 0:
				hero_damage_boost_waves_remaining -= 1
				if hero_damage_boost_waves_remaining <= 0:

					if notification_manager:
						notification_manager.show_notification("Buff de Dano Herói expirou!", 3.0, NotificationManager.NotificationPosition.TOP_CENTER, Color(0.8, 0.2, 0.2))



			_grant_wave_completion_rewards()
			wave_manager.start_next_wave()
		else:
			wave_manager.time_to_next_wave = 0.0

	wave_manager.update_intermission(delta)
	if not choosing_upgrade and not wave_manager.spawning and enemies.is_empty():

		if current_special_wave_type == WaveManager.SpecialWaveType.PERFECT_WAVE:
			_check_perfect_wave_bonus()
		if wave_manager.should_start_wave():
			wave_manager.start_next_wave()

	if wave_manager.spawning:
		var should_spawn = wave_manager.update(delta)
		if should_spawn:
			var s = _random_spawn()
			if s != null:

				if current_special_wave_type == WaveManager.SpecialWaveType.BOSS_RUSH:

					if wave_manager.bosses_spawned_this_wave < 4:
						enemies.append(_enemy_new_boss(s.x, s.y))
				elif wave_manager.is_boss_wave() and wave_manager.bosses_spawned_this_wave < 2:
					enemies.append(_enemy_new_boss(s.x, s.y))
				else:

					var enemy_type = _get_random_enemy_type_for_wave()
					enemies.append(_enemy_new(s.x, s.y, enemy_type))

	if not paused and not game_over and not is_loading:
		queue_redraw()

func _update_hud_top_bar() -> void:
	var tb = $CanvasLayer/HUD.get_node_or_null("TopBar")
	if tb == null or wave_manager == null:
		return
	var is_boss_wave := wave_manager.is_boss_wave()
	var wave_text = "Onda %d (CHEFE!)" % wave_manager.wave if is_boss_wave else "Onda %d" % wave_manager.wave
	if current_special_wave_type != WaveManager.SpecialWaveType.NONE:
		var special_icon = wave_manager.get_special_wave_name().split(" ")[0]
		wave_text = "%s %s" % [special_icon, wave_text]
	var weather_text = ""
	if weather_manager and weather_manager.current_weather != WeatherManager.WeatherType.NONE:
		weather_text = "  " + weather_manager.get_weather_name()
	var lbl_left = _hud_find(tb, "LblLeft")
	if lbl_left:
		lbl_left.text = "%s%s" % [wave_text, weather_text]
	var lbl_center = _hud_find(tb, "LblCenter")
	if lbl_center:
		lbl_center.text = "💰 %d" % [int(hero["coins"])]
	_update_base_hp_display()
	_update_special_currency_labels()

func _update_tower_shop_ui() -> void:

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


		var catalog_def := StructureCatalog.find_by_array(array_name)
		var current_cost = tower_info.cost
		if not catalog_def.is_empty():
			current_cost = _get_structure_cost(catalog_def.id)


		tower_info.cost = current_cost


		var can_afford = false
		if tower_info.has("cost_type") and tower_info.cost_type == "emeralds":
			var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}
			can_afford = currency_info.emeralds >= current_cost
		else:
			can_afford = hero["coins"] >= current_cost

		var catalog_id: String = str(tower_info.get("catalog_id", catalog_def.get("id", "")))
		var unlock_wave := _structure_unlock_wave(catalog_id) if not catalog_id.is_empty() else 1
		var is_unlocked := _is_structure_unlocked(catalog_id) if not catalog_id.is_empty() else true
		var can_buy = is_unlocked and can_afford and current_count < tower_info.max
		var buy_btn: Button = tower_button_data.buy_button
		var name_label: Label = tower_button_data.get("name_label", null)
		var icon_texture: TextureRect = tower_button_data.get("icon", null)

		if not is_unlocked:
			tower_button_data.container.add_theme_stylebox_override("panel", UIHelper.card_style(Color(0.32, 0.33, 0.38, 0.9), Color(0.16, 0.16, 0.19, 0.95)))
			if icon_texture:
				icon_texture.modulate = Color(0.38, 0.38, 0.42)
			if name_label:
				name_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.58))
			tower_button_data.cost_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.52))
			tower_button_data.limit_label.text = "Onda %d" % unlock_wave
			tower_button_data.limit_label.add_theme_color_override("font_color", Color(0.62, 0.62, 0.66))
			buy_btn.text = "Onda %d" % unlock_wave
			buy_btn.disabled = true
			buy_btn.tooltip_text = "Desbloqueia na onda %d" % unlock_wave
			UIHelper.apply_button_theme(buy_btn, UIHelper.BTN_DISABLED)
			buy_btn.add_theme_color_override("font_color", Color(0.55, 0.55, 0.58))
			buy_btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.55, 0.58))
		else:
			tower_button_data.container.add_theme_stylebox_override("panel", UIHelper.card_style())
			if icon_texture:
				icon_texture.modulate = Color.WHITE
			if name_label:
				name_label.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0))
			tower_button_data.limit_label.text = "%d/%d" % [current_count, tower_info.max]
			if current_count >= tower_info.max:
				tower_button_data.limit_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
			else:
				tower_button_data.limit_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			if tower_info.has("cost_type") and tower_info.cost_type == "emeralds":
				tower_button_data.cost_label.text = "🟢 %d esmeraldas" % current_cost
				tower_button_data.cost_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.3) if can_afford else Color(0.8, 0.3, 0.3))
			else:
				tower_button_data.cost_label.text = "%d moedas" % current_cost
				tower_button_data.cost_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3) if can_afford else Color(1.0, 0.3, 0.3))
			buy_btn.text = "Comprar"
			buy_btn.disabled = not can_buy
			buy_btn.tooltip_text = _get_shop_tooltip_text(tower_info.name)
			if can_buy:
				UIHelper.apply_success_button(buy_btn)
			else:
				UIHelper.apply_button_theme(buy_btn, UIHelper.BTN_DISABLED)
				buy_btn.add_theme_color_override("font_disabled_color", Color(0.7, 0.7, 0.72))

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
		"anti_air_towers":
			return anti_air_towers
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


	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		var mode = DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()
		return


	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if game_over:
			return
		if talisman_inventory_visible:
			_close_talisman_inventory()
			get_viewport().set_input_as_handled()
			return
		if inspect_panel and inspect_panel.visible:
			_hide_inspect_panel()
			get_viewport().set_input_as_handled()
			return
		if choosing_upgrade:
			return
		if paused:
			_unpause_game()
		else:
			_pause_game()
		get_viewport().set_input_as_handled()
		return


	if event is InputEventMouseMotion:
		preview_mouse_pos = to_local(event.position)
		if dragging_tower:
			drag_current_pos = preview_mouse_pos
			queue_redraw()
		elif _is_placing():
			queue_redraw()


	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_pointer_on_blocking_ui(event.position):
			if dragging_tower:
				_clear_drag_state()
				queue_redraw()
			return

		if choosing_upgrade or _is_placing():
			pass
		else:

			var world_pos = to_local(event.position)
			for type_id in StructureCatalog.DRAG_ORDER:
				var def = StructureCatalog.get_def(type_id)
				var radius := float(def.click_radius)
				var idx := -1
				if type_id == "wall":
					idx = _find_wall_at(world_pos, radius)
				elif type_id == "mine":
					idx = _find_mine_at(world_pos, radius)
				else:
					idx = _find_structure_at(def.array, world_pos, radius)
				if idx != -1:
					_start_drag_tower(type_id, idx, world_pos)
					return


		if not dragging_tower and not choosing_upgrade:

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



			if _is_placing():
				_try_place_structure(placing_type, world_pos)



	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if dragging_tower:
			var world_pos = to_local(event.position)
			var mouse_screen_pos = event.position

			if drag_start_pos.distance_to(world_pos) < 5.0:
				var click_type = dragged_tower_type
				var click_idx = dragged_tower_index
				dragging_tower = false
				dragged_tower_type = ""
				dragged_tower_index = -1
				drag_start_pos = Vector2.ZERO
				drag_offset = Vector2.ZERO
				drag_current_pos = Vector2.ZERO
				queue_redraw()
				_open_inspect_for_type(click_type, click_idx, mouse_screen_pos)
				return


			drag_current_pos = world_pos
			_end_drag_tower(world_pos)
			return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if not choosing_upgrade and not game_over:

			if tower_menu and tower_menu.visible:
				tower_menu.hide()
				_hide_range_indicator()
				tower_selected_index = -1
			_hide_inspect_panel()
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
			if anti_air_menu and anti_air_menu.visible:
				anti_air_menu.hide()
				_hide_range_indicator()
				anti_air_selected_index = -1
				keep_anti_air_menu_open = false
			if barracks_menu and barracks_menu.visible:
				barracks_menu.hide()
				_hide_range_indicator()
				barracks_selected_index = -1
			if market_menu and market_menu.visible:
				market_menu.hide()
				market_selected_index = -1
			if wall_menu and wall_menu.visible:
				wall_menu.hide()
				wall_selected_index = -1


			if dragging_tower:

				dragging_tower = false
				dragged_tower_type = ""
				dragged_tower_index = -1
				drag_start_pos = Vector2.ZERO
				drag_offset = Vector2.ZERO
				drag_current_pos = Vector2.ZERO
				queue_redraw()
				return

			if _is_placing():
				_clear_placing()
				queue_redraw()
				return

			var mouse_world_pos = to_local(event.position)
			var mouse_screen_pos = event.position


			var right_click_market_idx := _find_market_at(mouse_world_pos, 30.0)
			if right_click_market_idx != -1:
				_open_market_menu(right_click_market_idx, mouse_screen_pos)
				return

			var right_click_wall_idx := _find_wall_at(mouse_world_pos, 15.0)
			if right_click_wall_idx != -1:
				_show_wall_menu(right_click_wall_idx, mouse_world_pos)
				return

			var tower_idx := _find_tower_at(mouse_world_pos, 20.0)
			if tower_idx != -1:
				_open_tower_menu(tower_idx, mouse_screen_pos)
				return

			var barracks_idx := _find_barracks_at(mouse_world_pos, 20.0)
			if barracks_idx != -1 and not dragging_tower:
				_open_barracks_menu(barracks_idx, mouse_screen_pos)
				return

			var sniper_idx := _find_sniper_tower_at(mouse_world_pos, 20.0)
			if sniper_idx != -1:
				_open_sniper_menu(sniper_idx, mouse_screen_pos)
				return

			var aoe_idx := _find_aoe_tower_at(mouse_world_pos, 20.0)
			if aoe_idx != -1:
				_open_aoe_menu(aoe_idx, mouse_screen_pos)
				return

			var anti_air_idx := _find_anti_air_tower_at(mouse_world_pos, 20.0)
			if anti_air_idx != -1:
				_open_anti_air_menu(anti_air_idx, mouse_screen_pos)
				return

			var shock_idx := _find_shock_tower_at(mouse_world_pos, 20.0)
			if shock_idx != -1:
				_open_shock_menu(shock_idx, mouse_screen_pos)
				return

			var slow_idx := _find_slow_tower_at(mouse_world_pos, 20.0)
			if slow_idx != -1:
				_open_slow_menu(slow_idx, mouse_screen_pos)
				return

			var boost_idx := _find_boost_tower_at(mouse_world_pos, 20.0)
			if boost_idx != -1:
				_open_boost_menu(boost_idx, mouse_screen_pos)
				return

			var market_idx := _find_market_at(mouse_world_pos, 30.0)
			if market_idx != -1:
				if not dragging_tower:
					_start_drag_tower("market", market_idx, mouse_world_pos)
				return


			_close_all_upgrade_menus()


func _draw_placement_preview(grid_size_px: float) -> void:
	var def := StructureCatalog.get_def(placing_type)
	if def.is_empty():
		return
	var placement: String = def.get("placement", StructureCatalog.PLACEMENT_BASE)
	if placement == StructureCatalog.PLACEMENT_BASE:
		if not grid_manager.is_inside_base_point(preview_mouse_pos):
			return
		var preview_grid_coord = grid_manager.world_to_base_grid(preview_mouse_pos)
		var size: int = _cfg().get_int(def.size_key)
		var grid_type: int = int(def.grid_type)
		var preview_world_pos = grid_manager.base_grid_to_world(preview_grid_coord.x, preview_grid_coord.y, size)
		var can_place = grid_manager.can_place_in_grid(preview_grid_coord.x, preview_grid_coord.y, size, grid_type)
		var preview_size: float = grid_size_px * size
		var preview_rect := Rect2(preview_world_pos.x - preview_size / 2.0, preview_world_pos.y - preview_size / 2.0, preview_size, preview_size)
		var tex := _get_structure_texture(placing_type)
		if can_place:
			if tex != null:
				draw_texture_rect(tex, preview_rect, false, Color(1, 1, 1, 0.5))
			else:
				draw_rect(preview_rect, def.get("preview_ok", Color(0.7, 0.9, 0.7, 0.5)))
			draw_rect(preview_rect, def.get("preview_ok_border", Color(0.5, 0.8, 0.5)), false, 2.0)
		else:
			if tex != null:
				draw_texture_rect(tex, preview_rect, false, Color(1, 0.3, 0.3, 0.5))
			else:
				draw_rect(preview_rect, Color(0.9, 0.3, 0.3, 0.5))
			draw_rect(preview_rect, Color(0.8, 0.2, 0.2), false, 2.0)
		return
	var tile = _world_to_tile_coords(preview_mouse_pos)
	var preview_pos = grid_manager.tile_center(clamp(tile.x, 0, _cfg().get_int("GRID_COLS") - 1), clamp(tile.y, 0, _cfg().get_int("GRID_ROWS") - 1))
	var tex := _get_structure_texture(placing_type)
	if placement == StructureCatalog.PLACEMENT_WALKABLE:
		var can_place = _is_tile_within_bounds(tile) and _is_walkable_tile(tile) and not grid_manager.is_inside_base_point(preview_mouse_pos) and not _is_in_center_area(preview_mouse_pos) and not _is_mine_tile_occupied(tile)
		var mine_size = 16.0
		var mine_rect = Rect2(preview_pos.x - mine_size / 2.0, preview_pos.y - mine_size / 2.0, mine_size, mine_size)
		if can_place:
			if tex != null:
				draw_texture_rect(tex, mine_rect, false, Color(1, 1, 1, 0.5))
			else:
				draw_circle(preview_pos, 8, Color(0.8, 0.2, 0.2, 0.5))
			draw_circle(preview_pos, 10, Color(0.5, 0.1, 0.1, 0.3), false, 2.0)
		else:
			if tex != null:
				draw_texture_rect(tex, mine_rect, false, Color(1, 0.3, 0.3, 0.5))
			else:
				draw_circle(preview_pos, 8, Color(0.9, 0.3, 0.3, 0.5))
			draw_circle(preview_pos, 10, Color(0.8, 0.2, 0.2), false, 2.0)
		return
	if placement == StructureCatalog.PLACEMENT_PATH:
		var can_place = _is_on_path(preview_mouse_pos) and not grid_manager.is_inside_base_point(preview_mouse_pos) and not _is_wall_tile_occupied(tile)
		var wall_size = 30.8
		var wall_rect = Rect2(preview_pos.x - wall_size / 2.0, preview_pos.y - wall_size / 2.0, wall_size, wall_size)
		if can_place:
			if tex != null:
				draw_texture_rect(tex, wall_rect, false, Color(1, 1, 1, 0.5))
			else:
				draw_rect(wall_rect, Color(0.6, 0.4, 0.2, 0.5))
			draw_rect(Rect2(preview_pos.x - wall_size / 2.0 - 2, preview_pos.y - wall_size / 2.0 - 2, wall_size + 4, wall_size + 4), Color(0.5, 0.3, 0.2, 0.3), false, 2.0)
		else:
			if tex != null:
				draw_texture_rect(tex, wall_rect, false, Color(1, 0.3, 0.3, 0.5))
			else:
				draw_rect(wall_rect, Color(0.9, 0.3, 0.3, 0.5))
			draw_rect(Rect2(preview_pos.x - wall_size / 2.0 - 2, preview_pos.y - wall_size / 2.0 - 2, wall_size + 4, wall_size + 4), Color(0.8, 0.2, 0.2), false, 2.0)

func _draw() -> void:

	if is_loading:
		return


	if grid_manager.grid.is_empty() or grid_manager.grid.size() < _cfg().get_int("GRID_ROWS"):
		return


	if _cached_map_width == 0.0 or _cached_map_height == 0.0:
		_cached_map_width = float(_cfg().get_int("GRID_COLS") * _cfg().get_int("TILE_SIZE"))
		_cached_map_height = float(_cfg().get_int("GRID_ROWS") * _cfg().get_int("TILE_SIZE"))
	var map_width := _cached_map_width
	var map_height := _cached_map_height
	if _static_map_texture != null:
		draw_texture_rect(_static_map_texture, Rect2(0, 0, map_width, map_height), false)
	else:
		draw_rect(Rect2(0, 0, map_width, map_height), Color(0.05, 0.06, 0.08))
		draw_rect(Rect2(0, 0, map_width, map_height), Color(0.0, 0.0, 0.0, 0.4))
		for r in range(_cfg().get_int("GRID_ROWS")):
			if grid_manager.grid.size() <= r or grid_manager.grid[r].size() < _cfg().get_int("GRID_COLS"):
				continue
			for c in range(_cfg().get_int("GRID_COLS")):
				var tile_x := float(c * _cfg().get_int("TILE_SIZE"))
				var tile_y := float(r * _cfg().get_int("TILE_SIZE"))
				var tile_sz: int = _cfg().get_int("TILE_SIZE")
				var tile_rect := Rect2(tile_x, tile_y, tile_sz, tile_sz)
				if grid_manager.grid[r][c] == 0:
					if tex_path != null:
						draw_texture_rect(tex_path, tile_rect, false)
					elif tex_grass != null:
						draw_texture_rect(tex_grass, tile_rect, true)
					else:
						draw_rect(tile_rect, Color(0.16, 0.14, 0.12))
				elif tex_wall != null:
					draw_texture_rect(tex_wall, tile_rect, false)
				else:
					draw_rect(tile_rect, Color(0.24, 0.22, 0.20))
		draw_rect(Rect2(0, 0, map_width, map_height), Color(0.0, 0.0, 0.0, 0.22))

	if weather_manager and weather_manager.is_night():
		draw_rect(Rect2(0, 0, map_width, map_height), Color(0.04, 0.05, 0.12, 0.28))

	_draw_weather_effects()


	var base_half_size = int(_cfg().get_int("BASE_SIZE_TILES") / 2)
	var base_start_col = grid_manager.center.x - base_half_size
	var base_start_row = grid_manager.center.y - base_half_size
	var tile_sz_f := float(_cfg().get_int("TILE_SIZE"))
	var base_left_px = float(base_start_col) * tile_sz_f
	var base_top_px = float(base_start_row) * tile_sz_f
	var base_size_t: int = _cfg().get_int("BASE_SIZE_TILES")
	var base_width_px = float(base_size_t) * tile_sz_f
	var base_height_px = float(base_size_t) * tile_sz_f

	var base_rect := Rect2(base_left_px, base_top_px, base_width_px, base_height_px)
	var base_color = Color(0.28, 0.32, 0.38, 0.5)
	var base_glow = Color(0.38, 0.42, 0.48, 0.5)
	draw_rect(base_rect, base_color)
	draw_rect(base_rect, base_glow, false, 2.0)



	if _cached_grid_size_px == 0.0:
		_cached_grid_size_px = base_width_px / float(_cfg().get_int("BASE_GRID_SIZE"))
	var grid_size_px: float = _cached_grid_size_px
	var base_left: float = base_left_px
	var base_top: float = base_top_px
	var base_right: float = base_left_px + base_width_px
	var base_bottom: float = base_top_px + base_height_px

	var grid_color = Color(0.4, 0.42, 0.45, 0.4)
	for gy in range(_cfg().get_int("BASE_GRID_SIZE") + 1):
		var y = base_top + float(gy) * grid_size_px
		draw_line(Vector2(base_left, y), Vector2(base_right, y), grid_color, 0.5)
	for gx in range(_cfg().get_int("BASE_GRID_SIZE") + 1):
		var x = base_left + float(gx) * grid_size_px
		draw_line(Vector2(x, base_top), Vector2(x, base_bottom), grid_color, 0.5)


	var bc = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
	var hero_block_pixels = float(_cfg().get_int("TILE_SIZE")) * 1.5
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

	var camera_pos = Vector2.ZERO
	for e in enemies:

		if culling_manager and not culling_manager.should_render(e["pos"], camera_pos):
			continue


		var is_dying = e.get("dying", false)
		var is_boss: bool = e.get("is_boss", false)
		if not is_dying:
			var max_hp: int = int(e.get("max_hp", 2))
			var hp_ratio: float = clamp(float(e["hp"]) / float(max_hp), 0.0, 1.0)
			var bar_width: int = 28 if is_boss else 20
			var bar_height: int = 4 if is_boss else 3
			var bx: int = int(e["pos"].x) - int(bar_width / 2)
			var by: int = int(e["pos"].y) - 16


			draw_rect(Rect2(bx - 1, by - 1, bar_width + 2, bar_height + 2), Color(0.0, 0.0, 0.0, 0.5))
			draw_rect(Rect2(bx, by, bar_width, bar_height), Color(0.2, 0.2, 0.2))


			var hp_color: Color
			if hp_ratio > 0.6:
				hp_color = Color(0.2, 0.8, 0.2)
			elif hp_ratio > 0.3:
				hp_color = Color(0.9, 0.7, 0.2)
			else:
				hp_color = Color(0.9, 0.2, 0.2)

			if is_boss:
				hp_color = Color(0.9, 0.2, 0.9)

			draw_rect(Rect2(bx, by, int(bar_width * hp_ratio), bar_height), hp_color)


			draw_rect(Rect2(bx, by, bar_width, bar_height), Color(1.0, 1.0, 1.0, 0.3), false, 1.0)

		var enemy_idx = e.get("idx", -1)
		var enemy_tex: Texture2D = tex_enemy_zombie


		if is_boss:

			if wave_manager.wave >= 101 and tex_enemy_boss_mecanoide != null:
				enemy_tex = tex_enemy_boss_mecanoide
			elif wave_manager.wave >= 50 and tex_enemy_boss_alien != null:
				enemy_tex = tex_enemy_boss_alien
			elif tex_enemy_boss_zombie != null:
				enemy_tex = tex_enemy_boss_zombie
		else:

			var enemy_type = e.get("enemy_type", EnemyConstants.EnemyType.ZOMBIE)
			match enemy_type:
				EnemyConstants.EnemyType.ZOMBIE:
					enemy_tex = tex_enemy_zombie if tex_enemy_zombie != null else enemy_tex
				EnemyConstants.EnemyType.ZOMBIE_GORDO:
					enemy_tex = tex_enemy_zombie_gordo if tex_enemy_zombie_gordo != null else tex_enemy_zombie
				EnemyConstants.EnemyType.ZOMBIE_CORREDOR:
					enemy_tex = tex_enemy_zombie_corredor if tex_enemy_zombie_corredor != null else tex_enemy_zombie
				EnemyConstants.EnemyType.HUMANOID:
					enemy_tex = tex_enemy_humanoid if tex_enemy_humanoid != null else enemy_tex
				EnemyConstants.EnemyType.ROBOT:
					enemy_tex = tex_enemy_robot if tex_enemy_robot != null else enemy_tex
				EnemyConstants.EnemyType.ALIEN:
					enemy_tex = tex_enemy_alien if tex_enemy_alien != null else enemy_tex
				EnemyConstants.EnemyType.ALIEN_VOADOR:
					enemy_tex = tex_alien_voador if tex_alien_voador != null else tex_enemy_alien
				EnemyConstants.EnemyType.MECANOIDE_BIPEDE:
					enemy_tex = tex_mecanoide_bipede if tex_mecanoide_bipede != null else enemy_tex
				EnemyConstants.EnemyType.MECANOIDE_LAGARTAS:
					enemy_tex = tex_mecanoide_lagartas if tex_mecanoide_lagartas != null else enemy_tex
				EnemyConstants.EnemyType.MECANOIDE_DRONE:
					enemy_tex = tex_mecanoide_drone if tex_mecanoide_drone != null else tex_enemy_alien
				EnemyConstants.EnemyType.MECANOIDE_REGENERADOR:
					enemy_tex = tex_mecanoide_regenerado if tex_mecanoide_regenerado != null else enemy_tex
				EnemyConstants.EnemyType.MECANOIDE_BOSS:
					enemy_tex = tex_enemy_boss_mecanoide if tex_enemy_boss_mecanoide != null else enemy_tex
				_:

					if wave_manager.wave >= 101 and tex_mecanoide_bipede != null:
						enemy_tex = tex_mecanoide_bipede
					elif wave_manager.wave >= 50 and tex_enemy_alien != null:
						enemy_tex = tex_enemy_alien
					elif wave_manager.wave >= 11 and tex_enemy_robot != null:
						enemy_tex = tex_enemy_robot
					elif wave_manager.wave >= 6 and tex_enemy_humanoid != null:
						enemy_tex = tex_enemy_humanoid
					elif tex_enemy_zombie != null:
						enemy_tex = tex_enemy_zombie

		if enemy_tex != null:

			var enemy_size_multiplier = 1.5 if is_boss else 1.2
			var tile_sz_enemy := float(_cfg().get_int("TILE_SIZE"))
			var size := Vector2(tile_sz_enemy * enemy_size_multiplier, tile_sz_enemy * enemy_size_multiplier)
			var pos: Vector2 = e["pos"] - size/2

			var shadow_offset = Vector2(0, size.y * 0.25)
			var shadow_pos: Vector2 = e["pos"] + shadow_offset
			var shadow_radius: float = size.x * 0.28

			# Aura do boss: um pouco maior que a sombra, mesma posição (pés), boss desenhado por cima
			if is_boss and tex_boss_aura != null:
				var aura_tex_size: Vector2 = tex_boss_aura.get_size()
				if aura_tex_size.x > 0.0 and aura_tex_size.y > 0.0:
					# tamanho = diâmetro da sombra * multiplicador (aumente o número para área maior)
					var aura_diameter: float = shadow_radius * 2.0 * 1.5
					var aura_size: Vector2 = Vector2(aura_diameter, aura_diameter)
					# centralizada na mesma posição da sombra (pés do boss)
					var aura_pos: Vector2 = shadow_pos - aura_size * 0.5
					var aura_color: Color = Color(1.0, 1.0, 1.0, 0.95)
					draw_texture_rect(tex_boss_aura, Rect2(aura_pos, aura_size), false, aura_color)

			var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.3)
			draw_circle(shadow_pos, shadow_radius, shadow_color)


			var modulate_color = Color.WHITE


			if weather_manager and weather_manager.is_night():
				modulate_color = Color(0.5, 0.5, 0.6, 0.8)

			if is_dying:

				var dying_progress = e.get("dying_time", 0.0) / 0.5
				modulate_color.a = 1.0 - dying_progress
				size *= (1.0 - dying_progress * 0.5)
				pos = e["pos"] - size/2
			elif enemy_idx >= 0 and enemy_effects.has(enemy_idx):
				var effects = enemy_effects[enemy_idx]
				if effects.freeze_time > 0.0:
					modulate_color = Color(0.7, 0.9, 1.2, 1.0)
				elif effects.fire_time > 0.0:
					modulate_color = Color(1.2, 0.7, 0.5, 1.0)


			var tex_size = enemy_tex.get_size()


			if tex_size.x >= 128 and tex_size.y >= 128:

				var frame_size = tex_size / 2.0
				var direction = _get_enemy_direction(e)
				var src_rect: Rect2





				match direction:
					"up":

						src_rect = Rect2(frame_size.x, frame_size.y, frame_size.x, frame_size.y)
					"down":

						src_rect = Rect2(0, 0, frame_size.x, frame_size.y)
					"left":

						src_rect = Rect2(0, frame_size.y, frame_size.x, frame_size.y)
					"right":

						src_rect = Rect2(frame_size.x, 0, frame_size.x, frame_size.y)
					_:
						src_rect = Rect2(0, 0, frame_size.x, frame_size.y)


				draw_texture_rect_region(enemy_tex, Rect2(pos, size), src_rect, modulate_color)
			else:

				draw_texture_rect(enemy_tex, Rect2(pos, size), false, modulate_color)


			# retângulo rosa de destaque do boss removido (substituído pela aura)
		else:
			var enemy_color = Color(0.9,0.35,0.35)


			if weather_manager and weather_manager.is_night():
				enemy_color = Color(0.4, 0.4, 0.45, 0.8)


			if is_boss:
				enemy_color = Color(0.8,0.2,0.8)

				if weather_manager and weather_manager.is_night():
					enemy_color = Color(0.5, 0.15, 0.5, 0.85)
			if not is_boss and enemy_idx >= 0 and enemy_effects.has(enemy_idx):
				var effects = enemy_effects[enemy_idx]
				if effects.freeze_time > 0.0:
					enemy_color = Color(0.5,0.7,1.0)
				elif effects.fire_time > 0.0:
					enemy_color = Color(1.0,0.5,0.2)

			var enemy_radius = e.get("radius", 9)


			var shadow_offset = Vector2(0, enemy_radius * 0.4)
			var shadow_pos = e["pos"] + shadow_offset
			var shadow_radius = enemy_radius * 0.50
			var shadow_color = Color(0.0, 0.0, 0.0, 0.25)
			draw_circle(shadow_pos, shadow_radius, shadow_color)

			draw_circle(e["pos"], enemy_radius, enemy_color)


			if is_boss:
				draw_circle(e["pos"], enemy_radius, Color(0.5,0.1,0.5), false, 3.0)


	for a in arrows:
		if not culling_manager or culling_manager.should_render(a["pos"], camera_pos):
			draw_circle(a["pos"], 2, Color(0.83,0.90,1.0))
	for b in tower_bullets:
		if not culling_manager or culling_manager.should_render(b["pos"], camera_pos):

			if b.get("is_missile", false):
				draw_circle(b["pos"], 4, Color(1.0, 0.0, 0.0))
				draw_circle(b["pos"], 4, Color(1.0, 0.3, 0.3), false, 1.0)
			else:
				draw_circle(b["pos"], 2, Color(0.95,0.85,0.45))

	for proj in aoe_cannon_projectiles:
		if not culling_manager or culling_manager.should_render(proj.pos, camera_pos):
			draw_circle(proj.pos, 6, Color(0.0, 0.0, 0.0))
			draw_circle(proj.pos, 6, Color(0.2, 0.2, 0.2), false, 1.0)

	for effect in aoe_effects:
		if not culling_manager or culling_manager.should_render(effect.pos, camera_pos):
			var lod_level = culling_manager.get_lod_level(effect.pos, camera_pos) if culling_manager else 0
			var alpha = 1.0 - (effect.time / effect.max_time)
			var radius = effect.radius * (effect.time / effect.max_time)

			if lod_level <= 2:
				draw_circle(effect.pos, radius, Color(1.0, 0.5, 0.0, alpha * 0.6))
				if lod_level <= 1:
					draw_circle(effect.pos, radius, Color(1.0, 0.8, 0.0, alpha), false, 2.0)

	for effect in sniper_effects:
		if not culling_manager or culling_manager.should_render(effect.start, camera_pos):
			var alpha = 1.0 - (effect.time / effect.max_time)
			draw_line(effect.start, effect.end, Color(1.0, 1.0, 0.0, alpha), 3.0)

	for effect in shock_effects:
		if not culling_manager or culling_manager.should_render(effect.start, camera_pos):
			var lod_level = culling_manager.get_lod_level(effect.start, camera_pos) if culling_manager else 0
			var alpha = 1.0 - (effect.time / effect.max_time)
			var progress = effect.time / effect.max_time

			draw_line(effect.start, effect.end, Color(0.5, 0.8, 1.0, alpha), 4.0)

			if lod_level <= 1:
				draw_line(effect.start, effect.end, Color(1.0, 1.0, 1.0, alpha * 0.8), 2.0)

			if lod_level <= 1:
				var segments = 8 if lod_level == 0 else 4
				var dir = (effect.end - effect.start).normalized()
				var perp = Vector2(-dir.y, dir.x)
				for i in range(segments):
					var t1 = float(i) / float(segments)
					var t2 = float(i + 1) / float(segments)
					var p1 = effect.start.lerp(effect.end, t1)
					var p2 = effect.start.lerp(effect.end, t2)
					var jitter_scale: float = (1.0 - progress) * 3.0
					var offset1 = perp * sin(effect.time * 20.0 + float(i) * 1.7) * jitter_scale
					var offset2 = perp * sin(effect.time * 20.0 + float(i + 1) * 1.7) * jitter_scale
					draw_line(p1 + offset1, p2 + offset2, Color(0.7, 0.9, 1.0, alpha * 0.6), 2.0)

	if dragging_tower:
		var preview_pos = drag_current_pos - drag_offset
		var preview_size: float
		var preview_tex: Texture2D
		var tower_size_grid: int = 3

		match dragged_tower_type:
			"tower":
				preview_size = grid_size_px * _cfg().get_int("TOWER_SIZE_GRID")
				preview_tex = tex_tower
				tower_size_grid = _cfg().get_int("TOWER_SIZE_GRID")
			"slow_tower":
				preview_size = grid_size_px * _cfg().get_int("SLOW_TOWER_SIZE_GRID")
				preview_tex = tex_slow_tower
				tower_size_grid = _cfg().get_int("SLOW_TOWER_SIZE_GRID")
			"aoe_tower":
				preview_size = grid_size_px * _cfg().get_int("AOE_TOWER_SIZE_GRID")
				preview_tex = tex_aoe_tower
				tower_size_grid = _cfg().get_int("AOE_TOWER_SIZE_GRID")
			"sniper_tower":
				preview_size = grid_size_px * _cfg().get_int("SNIPER_TOWER_SIZE_GRID")
				preview_tex = tex_sniper_tower
				tower_size_grid = _cfg().get_int("SNIPER_TOWER_SIZE_GRID")
			"boost_tower":
				preview_size = grid_size_px * _cfg().get_int("BOOST_TOWER_SIZE_GRID")
				preview_tex = tex_boost_tower
				tower_size_grid = _cfg().get_int("BOOST_TOWER_SIZE_GRID")
			"shock_tower":
				preview_size = grid_size_px * _cfg().get_int("SHOCK_TOWER_SIZE_GRID")
				preview_tex = tex_shock_tower
				tower_size_grid = _cfg().get_int("SHOCK_TOWER_SIZE_GRID")
			"anti_air_tower":
				preview_size = grid_size_px * _cfg().get_int("ANTI_AIR_TOWER_SIZE_GRID")
				preview_tex = tex_anti_air_tower
				tower_size_grid = _cfg().get_int("ANTI_AIR_TOWER_SIZE_GRID")
			"barracks":
				preview_size = grid_size_px * _cfg().get_int("BARRACKS_SIZE_GRID")
				preview_tex = tex_barracks
				tower_size_grid = _cfg().get_int("BARRACKS_SIZE_GRID")
			"market":
				preview_size = grid_size_px * _cfg().get_int("MARKET_SIZE_GRID")
				preview_tex = tex_market
				tower_size_grid = _cfg().get_int("MARKET_SIZE_GRID")
			"healing_station":
				preview_size = grid_size_px * _cfg().get_int("HEALING_STATION_SIZE_GRID")
				preview_tex = tex_healing_station
				tower_size_grid = _cfg().get_int("HEALING_STATION_SIZE_GRID")
			"wall":
				preview_size = float(_cfg().get_int("TILE_SIZE")) * 1.1
				preview_tex = tex_wall_structure
				tower_size_grid = 1
			"mine":
				preview_size = 16.0
				preview_tex = tex_mine


		var can_place = false
		var snapped_preview_pos = preview_pos

		if dragged_tower_type == "mine":

			var tile = _world_to_tile_coords(preview_pos)
			can_place = _is_tile_within_bounds(tile) and _is_walkable_tile(tile) and not grid_manager.is_inside_base_point(preview_pos) and not _is_in_center_area(preview_pos) and not _is_mine_tile_occupied(tile)
		elif dragged_tower_type == "wall":

			var tile = _world_to_tile_coords(preview_pos)
			var wall_world_pos = grid_manager.tile_center(clamp(tile.x, 0, _cfg().get_int("GRID_COLS") - 1), clamp(tile.y, 0, _cfg().get_int("GRID_ROWS") - 1))
			snapped_preview_pos = wall_world_pos
			can_place = _is_on_path(wall_world_pos) and not grid_manager.is_inside_base_point(wall_world_pos) and not _is_wall_tile_occupied(tile)
		elif grid_manager.is_inside_base_point(preview_pos):

			var snap_result = _calculate_tower_snap(preview_pos, tower_size_grid)
			var grid_coord = snap_result["grid_coord"]
			snapped_preview_pos = snap_result["snapped_world_pos"]


			var ignore_area: Rect2i = Rect2i()
			var item_type: int = 1

			match dragged_tower_type:
				"tower":
					if dragged_tower_index >= 0 and dragged_tower_index < towers.size():
						var old_tower = towers[dragged_tower_index]
						ignore_area = Rect2i(old_tower.grid_x, old_tower.grid_y, _cfg().get_int("TOWER_SIZE_GRID"), _cfg().get_int("TOWER_SIZE_GRID"))
					item_type = 1
					can_place = grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, _cfg().get_int("TOWER_SIZE_GRID"), item_type, ignore_area)
				"slow_tower":
					if dragged_tower_index >= 0 and dragged_tower_index < slow_towers.size():
						var old_tower = slow_towers[dragged_tower_index]
						ignore_area = Rect2i(old_tower.grid_x, old_tower.grid_y, _cfg().get_int("SLOW_TOWER_SIZE_GRID"), _cfg().get_int("SLOW_TOWER_SIZE_GRID"))
					item_type = 5
					can_place = grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, _cfg().get_int("SLOW_TOWER_SIZE_GRID"), item_type, ignore_area)
				"aoe_tower":
					if dragged_tower_index >= 0 and dragged_tower_index < aoe_towers.size():
						var old_tower = aoe_towers[dragged_tower_index]
						ignore_area = Rect2i(old_tower.grid_x, old_tower.grid_y, _cfg().get_int("AOE_TOWER_SIZE_GRID"), _cfg().get_int("AOE_TOWER_SIZE_GRID"))
					item_type = 6
					can_place = grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, _cfg().get_int("AOE_TOWER_SIZE_GRID"), item_type, ignore_area)
				"sniper_tower":
					if dragged_tower_index >= 0 and dragged_tower_index < sniper_towers.size():
						var old_tower = sniper_towers[dragged_tower_index]
						ignore_area = Rect2i(old_tower.grid_x, old_tower.grid_y, _cfg().get_int("SNIPER_TOWER_SIZE_GRID"), _cfg().get_int("SNIPER_TOWER_SIZE_GRID"))
					item_type = 7
					can_place = grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, _cfg().get_int("SNIPER_TOWER_SIZE_GRID"), item_type, ignore_area)
				"boost_tower":
					if dragged_tower_index >= 0 and dragged_tower_index < boost_towers.size():
						var old_tower = boost_towers[dragged_tower_index]
						ignore_area = Rect2i(old_tower.grid_x, old_tower.grid_y, _cfg().get_int("BOOST_TOWER_SIZE_GRID"), _cfg().get_int("BOOST_TOWER_SIZE_GRID"))
					item_type = 8
					can_place = grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, _cfg().get_int("BOOST_TOWER_SIZE_GRID"), item_type, ignore_area)
				"shock_tower":
					if dragged_tower_index >= 0 and dragged_tower_index < shock_towers.size():
						var old_tower = shock_towers[dragged_tower_index]
						ignore_area = Rect2i(old_tower.grid_x, old_tower.grid_y, _cfg().get_int("SHOCK_TOWER_SIZE_GRID"), _cfg().get_int("SHOCK_TOWER_SIZE_GRID"))
					item_type = 9
					can_place = grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, _cfg().get_int("SHOCK_TOWER_SIZE_GRID"), item_type, ignore_area)
				"anti_air_tower":
					if dragged_tower_index >= 0 and dragged_tower_index < anti_air_towers.size():
						var old_tower = anti_air_towers[dragged_tower_index]
						ignore_area = Rect2i(old_tower.grid_x, old_tower.grid_y, _cfg().get_int("ANTI_AIR_TOWER_SIZE_GRID"), _cfg().get_int("ANTI_AIR_TOWER_SIZE_GRID"))
					item_type = 12
					can_place = grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, _cfg().get_int("ANTI_AIR_TOWER_SIZE_GRID"), item_type, ignore_area)
				"barracks":
					if dragged_tower_index >= 0 and dragged_tower_index < barracks.size():
						var old_barracks = barracks[dragged_tower_index]
						ignore_area = Rect2i(old_barracks.grid_x, old_barracks.grid_y, _cfg().get_int("BARRACKS_SIZE_GRID"), _cfg().get_int("BARRACKS_SIZE_GRID"))
					item_type = 3
					can_place = grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, _cfg().get_int("BARRACKS_SIZE_GRID"), item_type, ignore_area)
				"market":
					if dragged_tower_index >= 0 and dragged_tower_index < markets.size():
						var old_market = markets[dragged_tower_index]
						ignore_area = Rect2i(old_market.grid_x, old_market.grid_y, _cfg().get_int("MARKET_SIZE_GRID"), _cfg().get_int("MARKET_SIZE_GRID"))
					item_type = 11
					can_place = grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, _cfg().get_int("MARKET_SIZE_GRID"), item_type, ignore_area)
				"healing_station":
					if dragged_tower_index >= 0 and dragged_tower_index < healing_stations.size():
						var old_station = healing_stations[dragged_tower_index]
						ignore_area = Rect2i(old_station.grid_x, old_station.grid_y, _cfg().get_int("HEALING_STATION_SIZE_GRID"), _cfg().get_int("HEALING_STATION_SIZE_GRID"))
					item_type = 10
					can_place = grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, _cfg().get_int("HEALING_STATION_SIZE_GRID"), item_type, ignore_area)



		if dragged_tower_type != "mine" and dragged_tower_type != "wall":

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

				var preview_rect = Rect2(snapped_preview_pos.x - preview_size/2, snapped_preview_pos.y - preview_size/2, preview_size, preview_size)
				if can_place:

					if preview_tex != null:
						draw_texture_rect(preview_tex, preview_rect, false, Color(1, 1, 1, 0.7))
					else:
						draw_rect(preview_rect, resource_manager.get_color("preview_valid"))
					draw_rect(preview_rect, resource_manager.get_color("preview_border_valid"), false, 2.0)
				else:

					if preview_tex != null:
						draw_texture_rect(preview_tex, preview_rect, false, Color(1, 0.3, 0.3, 0.7))
					else:
						draw_rect(preview_rect, resource_manager.get_color("preview_invalid"))
					draw_rect(preview_rect, resource_manager.get_color("preview_border_invalid"), false, 2.0)


	for i in range(towers.size()):

		if dragging_tower and dragged_tower_type == "tower" and i == dragged_tower_index:
			continue
		var t = towers[i]
		var tower_size: float = grid_size_px * _cfg().get_int("TOWER_SIZE_GRID")
		var r := Rect2(t.pos.x - tower_size/2, t.pos.y - tower_size/2, tower_size, tower_size)
		if tex_tower != null:
			draw_texture_rect(tex_tower, r, false)
		else:
			draw_rect(r, Color(0.7,0.7,0.8))
			draw_rect(r, Color(0.5,0.5,0.6), false, 2.0)

	var barracks_size = barracks.size()
	for i in range(barracks_size):

		if dragging_tower and dragged_tower_type == "barracks" and i == dragged_tower_index:
			continue
		var br = barracks[i]
		var br_size: float = grid_size_px * _cfg().get_int("BARRACKS_SIZE_GRID")
		var br_rect := Rect2(br.pos.x - br_size/2, br.pos.y - br_size/2, br_size, br_size)
		if tex_barracks != null:
			draw_texture_rect(tex_barracks, br_rect, false)
		else:
			draw_rect(br_rect, Color(0.4,0.5,0.6))
			draw_rect(br_rect, Color(0.3,0.4,0.5), false, 2.0)

	for i in range(mines.size()):

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

	for i in range(slow_towers.size()):
		if dragging_tower and dragged_tower_type == "slow_tower" and i == dragged_tower_index:
			continue
		var st = slow_towers[i]
		var st_size: float = grid_size_px * _cfg().get_int("SLOW_TOWER_SIZE_GRID")
		var st_rect := Rect2(st.pos.x - st_size/2, st.pos.y - st_size/2, st_size, st_size)
		if tex_slow_tower != null:
			draw_texture_rect(tex_slow_tower, st_rect, false)
		else:
			draw_rect(st_rect, Color(0.5,0.7,0.9))
			draw_rect(st_rect, Color(0.3,0.5,0.7), false, 2.0)

	for i in range(aoe_towers.size()):
		if dragging_tower and dragged_tower_type == "aoe_tower" and i == dragged_tower_index:
			continue
		var aoe = aoe_towers[i]
		var aoe_size: float = grid_size_px * _cfg().get_int("AOE_TOWER_SIZE_GRID")
		var aoe_rect := Rect2(aoe.pos.x - aoe_size/2, aoe.pos.y - aoe_size/2, aoe_size, aoe_size)
		if tex_aoe_tower != null:
			draw_texture_rect(tex_aoe_tower, aoe_rect, false)
		else:
			draw_rect(aoe_rect, Color(0.9,0.5,0.2))
			draw_rect(aoe_rect, Color(0.7,0.3,0.1), false, 2.0)

	for i in range(sniper_towers.size()):
		if dragging_tower and dragged_tower_type == "sniper_tower" and i == dragged_tower_index:
			continue
		var sniper = sniper_towers[i]
		var sniper_size: float = grid_size_px * _cfg().get_int("SNIPER_TOWER_SIZE_GRID")
		var sniper_rect := Rect2(sniper.pos.x - sniper_size/2, sniper.pos.y - sniper_size/2, sniper_size, sniper_size)
		if tex_sniper_tower != null:
			draw_texture_rect(tex_sniper_tower, sniper_rect, false)


	for i in range(anti_air_towers.size()):
		if dragging_tower and dragged_tower_type == "anti_air_tower" and i == dragged_tower_index:
			continue
		var anti_air = anti_air_towers[i]
		var anti_air_size = grid_size_px * _cfg().get_int("ANTI_AIR_TOWER_SIZE_GRID")
		var anti_air_rect = Rect2(anti_air.pos.x - anti_air_size/2, anti_air.pos.y - anti_air_size/2, anti_air_size, anti_air_size)
		if tex_anti_air_tower != null:
			draw_texture_rect(tex_anti_air_tower, anti_air_rect, false)
		else:
			draw_rect(anti_air_rect, Color(0.2,0.6,0.9))
			draw_rect(anti_air_rect, Color(0.1,0.4,0.7), false, 2.0)

	for i in range(boost_towers.size()):
		if dragging_tower and dragged_tower_type == "boost_tower" and i == dragged_tower_index:
			continue
		var boost = boost_towers[i]
		var boost_size: float = grid_size_px * _cfg().get_int("BOOST_TOWER_SIZE_GRID")
		var boost_rect := Rect2(boost.pos.x - boost_size/2, boost.pos.y - boost_size/2, boost_size, boost_size)
		if tex_boost_tower != null:
			draw_texture_rect(tex_boost_tower, boost_rect, false)
		else:
			draw_rect(boost_rect, Color(0.8,0.8,0.2))
			draw_rect(boost_rect, Color(0.6,0.6,0.1), false, 2.0)

	for i in range(shock_towers.size()):
		if dragging_tower and dragged_tower_type == "shock_tower" and i == dragged_tower_index:
			continue
		var shock = shock_towers[i]
		var shock_size: float = grid_size_px * _cfg().get_int("SHOCK_TOWER_SIZE_GRID")
		var shock_rect := Rect2(shock.pos.x - shock_size/2, shock.pos.y - shock_size/2, shock_size, shock_size)
		if tex_shock_tower != null:
			draw_texture_rect(tex_shock_tower, shock_rect, false)
		else:
			draw_rect(shock_rect, Color(0.5,0.3,0.9))
			draw_rect(shock_rect, Color(0.4,0.2,0.8), false, 2.0)
	for i in range(walls.size()):
		if dragging_tower and dragged_tower_type == "wall" and i == dragged_tower_index:
			continue
		var w = walls[i]
		if w.hp > 0:
			var wall_size: float
			if grid_manager.is_inside_base_point(w.pos):
				wall_size = grid_size_px * _cfg().get_int("WALL_SIZE_GRID")
			else:
				wall_size = float(_cfg().get_int("TILE_SIZE")) * 1.1
			var wall_rect := Rect2(w.pos.x - wall_size/2, w.pos.y - wall_size/2, wall_size, wall_size)
			if tex_wall_structure != null:

				var hp_ratio = w.hp / w.max_hp
				var alpha = 0.5 + (hp_ratio * 0.5)
				draw_texture_rect(tex_wall_structure, wall_rect, false, Color(1, 1, 1, alpha))
			else:
				var hp_ratio = w.hp / w.max_hp
				var wall_color = Color(0.6,0.4,0.2) * hp_ratio + Color(0.3,0.2,0.1) * (1.0 - hp_ratio)
				draw_rect(wall_rect, wall_color)
				draw_rect(wall_rect, Color(0.4,0.3,0.2), false, 2.0)


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


	if dragging_tower and dragged_tower_type == "wall" and dragged_tower_index >= 0 and dragged_tower_index < walls.size():
		var w = walls[dragged_tower_index]
		var wall_size = float(_cfg().get_int("TILE_SIZE")) * 1.1
		var drag_pos = drag_current_pos - drag_offset
		var wall_rect := Rect2(drag_pos.x - wall_size/2, drag_pos.y - wall_size/2, wall_size, wall_size)
		if tex_wall_structure != null:
			draw_texture_rect(tex_wall_structure, wall_rect, false, Color(1, 1, 1, 0.7))
		else:
			draw_rect(wall_rect, Color(0.6,0.4,0.2,0.7))
			draw_rect(wall_rect, Color(0.4,0.3,0.2), false, 2.0)





	for i in range(healing_stations.size()):

		if dragging_tower and dragged_tower_type == "healing_station" and i == dragged_tower_index:
			continue
		var hs = healing_stations[i]
		var hs_size: float = grid_size_px * _cfg().get_int("HEALING_STATION_SIZE_GRID")
		var hs_rect := Rect2(hs.pos.x - hs_size/2, hs.pos.y - hs_size/2, hs_size, hs_size)
		if tex_healing_station != null:
			draw_texture_rect(tex_healing_station, hs_rect, false)
		else:
			draw_rect(hs_rect, Color(0.2,0.8,0.4))


	var markets_size = markets.size()
	for i in range(markets_size):

		if dragging_tower and dragged_tower_type == "market" and i == dragged_tower_index:
			continue
		var m = markets[i]
		var m_size: float = grid_size_px * _cfg().get_int("MARKET_SIZE_GRID")
		var m_rect := Rect2(m.pos.x - m_size/2, m.pos.y - m_size/2, m_size, m_size)
		if tex_market != null:
			draw_texture_rect(tex_market, m_rect, false)
		else:
			draw_rect(m_rect, Color(0.2,0.8,0.2))


	for s in soldiers:
		if s.hp > 0:
			var soldier_color = Color(0.2,0.6,0.9) if not s.holding else Color(0.9,0.6,0.2)
			draw_circle(s.pos, s.radius, soldier_color)
			draw_circle(s.pos, s.radius, Color(0.1,0.3,0.5), false, 1.0)


	for coin in dropped_coins:
		if coin.collected:
			continue

		var lifetime_ratio = coin.lifetime / coin.max_lifetime
		var alpha = 1.0
		if lifetime_ratio > 0.7:
			var fade_ratio = (lifetime_ratio - 0.7) / 0.3
			alpha = 1.0 - fade_ratio * 0.5

		if tex_coin != null:
			var coin_size = 32.0
			var coin_rect = Rect2(coin.pos.x - coin_size/2, coin.pos.y - coin_size/2, coin_size, coin_size)
			draw_texture_rect(tex_coin, coin_rect, false, Color(1, 1, 1, alpha))
		else:

			draw_circle(coin.pos, 16, Color(0.9, 0.8, 0.2, alpha))
			draw_circle(coin.pos, 16, Color(0.7, 0.6, 0.1, alpha), false, 2.0)


			draw_circle(coin.pos, 8, Color(1.0, 0.9, 0.3, alpha))


	for talisman_drop in dropped_talismans:
		if talisman_drop.collected:
			continue

		var lifetime_ratio = talisman_drop.lifetime / talisman_drop.max_lifetime
		var alpha = 1.0
		if lifetime_ratio > 0.8:
			var fade_ratio = (lifetime_ratio - 0.8) / 0.2
			alpha = 1.0 - fade_ratio * 0.5

		var talisman = talisman_drop.talisman
		var rarity_color = talisman.get_rarity_color()
		var talisman_size = 50.0


		draw_circle(talisman_drop.pos, talisman_size/2, Color(rarity_color.r, rarity_color.g, rarity_color.b, alpha * 0.3))
		draw_circle(talisman_drop.pos, talisman_size/2, rarity_color, false, 3.0)


		if tex_talisman != null:
			var talisman_rect = Rect2(talisman_drop.pos.x - talisman_size/2, talisman_drop.pos.y - talisman_size/2, talisman_size, talisman_size)
			draw_texture_rect(tex_talisman, talisman_rect, false, Color(1, 1, 1, alpha))
		else:

			draw_circle(talisman_drop.pos, talisman_size/4, Color(rarity_color.r, rarity_color.g, rarity_color.b, alpha))


	for effect in coin_collect_effects:
		var progress = effect.time / effect.max_time
		var alpha = 1.0 - progress


		var base_radius = 20.0 * (1.0 + progress * 2.0)
		draw_circle(effect.pos, base_radius, Color(1.0, 0.9, 0.2, alpha * 0.4))
		draw_circle(effect.pos, base_radius, Color(1.0, 0.85, 0.0, alpha * 0.6), false, 2.0)


		var inner_radius = 10.0 * (1.0 + progress)
		draw_circle(effect.pos, inner_radius, Color(1.0, 1.0, 0.5, alpha * 0.8))


		for particle in effect.particles:
			var particle_alpha = 1.0 - (particle.time / particle.max_time)
			var particle_size = 4.0 * (1.0 - particle.time / particle.max_time)

			draw_circle(particle.pos, particle_size, Color(1.0, 0.95, 0.3, particle_alpha))
			draw_circle(particle.pos, particle_size * 0.5, Color(1.0, 1.0, 0.8, particle_alpha))


	for dmg in damage_numbers:
		var progress = dmg.time / dmg.max_time
		var alpha = 1.0 - progress
		var y_offset = progress * 30.0
		var pos = dmg.pos + Vector2(0, -y_offset)
		var scale = 1.0 + (progress * 0.5) if dmg.is_crit else 1.0
		var color = dmg.color
		color.a = alpha


		var size = 12.0 * scale
		if dmg.is_crit:

			draw_circle(pos, size * 1.5, Color(1.0, 0.9, 0.0, alpha * 0.3))
			draw_circle(pos, size, Color(1.0, 0.8, 0.2, alpha))
		else:
			draw_circle(pos, size * 0.8, color)



		var value_size = clamp(dmg.value / 5.0, 0.5, 2.0)
		draw_circle(pos, size * value_size * 0.6, Color(1.0, 1.0, 1.0, alpha))


	for anim in enemy_death_animations:
		var alpha = anim.alpha
		var scale = anim.scale

		draw_circle(anim.pos, 15.0 * scale, Color(0.8, 0.2, 0.2, alpha))
		draw_circle(anim.pos, 10.0 * scale, Color(1.0, 0.5, 0.0, alpha * 0.7))

		for i in range(8):
			var angle = (TAU / 8.0) * i
			var dist = 20.0 * (1.0 - scale)
			var particle_pos = anim.pos + Vector2(cos(angle), sin(angle)) * dist
			draw_circle(particle_pos, 3.0 * scale, Color(1.0, 0.7, 0.0, alpha))


	if _is_placing():
		_draw_placement_preview(grid_size_px)


	if tower_selected_index >= 0 and tower_selected_index < towers.size():
		var tt = towers[tower_selected_index]
		draw_circle(tt.pos, tt.range, Color(0.3,0.6,1.0,0.15))


	if slow_selected_index >= 0 and slow_selected_index < slow_towers.size():
		var st = slow_towers[slow_selected_index]

		draw_circle(st.pos, st.range, Color(0.4, 1.0, 0.8, 0.2))


	if boost_selected_index >= 0 and boost_selected_index < boost_towers.size():
		var bt = boost_towers[boost_selected_index]

		draw_circle(bt.pos, bt.range, Color(0.6, 0.9, 0.4, 0.2))


func _is_walkable(c: int, r: int) -> bool:
	return pathfinder.is_walkable(c, r, grid_manager.base_grid)

func _bfs_path(from_c: int, from_r: int, consider_walls: bool = false) -> Array:
	if wave_manager.wave > 0 and (wave_manager.wave % 10 == 0 or enemies.size() > 50):
		pathfinder.invalidate_cache()


	if consider_walls:
		pathfinder.set_wall_tiles(wall_tiles)
	else:
		pathfinder.set_wall_tiles({})
	var path = pathfinder.find_path(from_c, from_r, grid_manager.base_grid)


	if path.is_empty():

		pathfinder.invalidate_cache()
		path = pathfinder.find_path(from_c, from_r, grid_manager.base_grid)

	var pts := []
	for t in path:

		if t.x >= 0 and t.x < _cfg().get_int("GRID_COLS") and t.y >= 0 and t.y < _cfg().get_int("GRID_ROWS"):
			pts.append(grid_manager.tile_center(t.x, t.y))
		else:

			break


	if pts.is_empty():
		var base_center = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
		var start_pos = grid_manager.tile_center(from_c, from_r)
		pts = [start_pos, base_center]

	return pts

func _random_spawn():

	var cells: Array = []
	var right_col = _cfg().get_int("GRID_COLS") - 2
	var bottom_row = _cfg().get_int("GRID_ROWS") - 2


	for c in range(1, _cfg().get_int("GRID_COLS")-1):
		if grid_manager.grid.size() > 1 and grid_manager.grid[1].size() > c and grid_manager.grid[1][c] == 0 and _is_walkable(c, 1):
			cells.append(Vector2i(c, 1))

	for c in range(1, _cfg().get_int("GRID_COLS")-1):
		if grid_manager.grid.size() > bottom_row and grid_manager.grid[bottom_row].size() > c and grid_manager.grid[bottom_row][c] == 0 and _is_walkable(c, bottom_row):
			cells.append(Vector2i(c, bottom_row))

	for r in range(1, _cfg().get_int("GRID_ROWS")-1):
		if grid_manager.grid.size() > r and grid_manager.grid[r].size() > 1 and grid_manager.grid[r][1] == 0 and _is_walkable(1, r):
			cells.append(Vector2i(1, r))

	for r in range(1, _cfg().get_int("GRID_ROWS")-1):
		if grid_manager.grid.size() > r and grid_manager.grid[r].size() > right_col and grid_manager.grid[r][right_col] == 0 and _is_walkable(right_col, r):
			cells.append(Vector2i(right_col, r))

	if cells.is_empty():

		for c in range(1, _cfg().get_int("GRID_COLS")-1):
			if grid_manager.grid.size() > 1 and grid_manager.grid[1].size() > c and grid_manager.grid[1][c] == 0:
				cells.append(Vector2i(c, 1))
		for c in range(1, _cfg().get_int("GRID_COLS")-1):
			if grid_manager.grid.size() > bottom_row and grid_manager.grid[bottom_row].size() > c and grid_manager.grid[bottom_row][c] == 0:
				cells.append(Vector2i(c, bottom_row))
		for r in range(1, _cfg().get_int("GRID_ROWS")-1):
			if grid_manager.grid.size() > r and grid_manager.grid[r].size() > 1 and grid_manager.grid[r][1] == 0:
				cells.append(Vector2i(1, r))
		for r in range(1, _cfg().get_int("GRID_ROWS")-1):
			if grid_manager.grid.size() > r and grid_manager.grid[r].size() > right_col and grid_manager.grid[r][right_col] == 0:
				cells.append(Vector2i(right_col, r))

	if cells.is_empty():
		print("Erro: Nenhuma célula de spawn válida encontrada!")
		return null


	cells.shuffle()
	var selected = cells[randi() % cells.size()]


	var test_path = _bfs_path(selected.x, selected.y)
	if test_path.is_empty():

		for i in range(min(5, cells.size())):
			selected = cells[i]
			test_path = _bfs_path(selected.x, selected.y)
			if not test_path.is_empty():
				break

	return selected

func _get_random_enemy_type_for_wave() -> EnemyConstants.EnemyType:
	"""Retorna um tipo de inimigo aleatório baseado na wave atual (sistema padronizado)"""
	var current_wave = wave_manager.wave if wave_manager else 1
	var available_types = EnemyConstants.get_available_enemy_types(current_wave)

	if available_types.is_empty():
		return EnemyConstants.EnemyType.ZOMBIE


	if EnemyConstants.EnemyType.ALIEN in available_types:
		var chance = randf()
		if chance < EnemyConstants.ALIEN_VOADOR_SPAWN_CHANCE:

			if EnemyConstants.EnemyType.ALIEN_VOADOR in available_types:
				return EnemyConstants.EnemyType.ALIEN_VOADOR


	return available_types[randi() % available_types.size()]

func _enemy_new(col: int, row: int, enemy_type: EnemyConstants.EnemyType = EnemyConstants.EnemyType.ZOMBIE) -> Dictionary:
	"""Cria um novo inimigo do tipo especificado (sistema padronizado)"""
	var pos = grid_manager.tile_center(col, row)


	var config = EnemyConstants.get_enemy_type_config(enemy_type)


	var hp_multiplier: float = config.get("hp_multiplier", 1.0)
	var initial_hp: float = EnemyConstants.ENEMY_BASE_HP * hp_multiplier
	var f := _wave_factor()
	var hp := int(max(1, round(initial_hp * f)))


	if current_special_wave_type == WaveManager.SpecialWaveType.HELL_WAVE:
		hp = int(hp * 0.5)
		hp = max(1, hp)

	var enemy_idx = enemies.size()

	var ignores_path: bool = config.get("ignores_path", false)
	var path_copy = []

	if ignores_path:

		var base_center = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
		path_copy = [pos, base_center]
	else:

		var path = _bfs_path(col, row)

		if path.is_empty() or path.size() == 0:


			var base_center = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
			path = [pos, base_center]

		for p in path:
			if p is Vector2:
				path_copy.append(p)

		if path_copy.is_empty():
			var base_center = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
			path_copy = [pos, base_center]


	var speed_multiplier: float = config.get("speed_multiplier", 1.0)
	var base_speed: float = EnemyConstants.ENEMY_BASE_SPEED * f * speed_multiplier


	if current_special_wave_type == WaveManager.SpecialWaveType.MAX_SPEED:
		base_speed *= 1.5
	elif current_special_wave_type == WaveManager.SpecialWaveType.HELL_WAVE:
		base_speed *= 2.0


	if weather_manager:
		base_speed *= weather_manager.get_enemy_speed_multiplier()
		hp = int(hp * weather_manager.get_enemy_hp_multiplier())


	var max_speed_for_type = EnemyConstants.ENEMY_MAX_SPEED * config.get("max_speed_multiplier", 1.0)
	if base_speed > max_speed_for_type:
		base_speed = max_speed_for_type


	var e = _acquire_pooled_dict("enemy")
	e["pos"] = pos
	e["speed"] = base_speed
	e["base_speed"] = base_speed
	e["hp"] = hp
	e["max_hp"] = hp
	e["radius"] = 9
	e["path"] = path_copy
	e["path_index"] = 0
	e["reached"] = false
	e["idx"] = enemy_idx
	e["is_boss"] = false
	e["enemy_type"] = enemy_type
	e["ignores_path"] = ignores_path
	e.erase("dying")
	e.erase("dying_time")
	enemy_effects[enemy_idx] = {"slow_time": 0.0, "slow_amount": 0.0, "freeze_time": 0.0, "fire_time": 0.0, "fire_damage": 0.0}
	return e

func _enemy_new_boss(col: int, row: int) -> Dictionary:
	var pos = grid_manager.tile_center(col, row)
	var initial_hp := EnemyConstants.BOSS_BASE_HP
	var f := _wave_factor()
	var hp := int(max(1, round(initial_hp * f)))


	if current_special_wave_type == WaveManager.SpecialWaveType.HELL_WAVE:
		hp = int(hp * 0.75)
		hp = max(1, hp)

	var enemy_idx = enemies.size()

	var path = _bfs_path(col, row)

	if path.is_empty() or path.size() == 0:


		var base_center = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
		path = [pos, base_center]

	var path_copy = []
	for p in path:
		if p is Vector2:
			path_copy.append(p)

	if path_copy.is_empty():
		var base_center = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
		path_copy = [pos, base_center]

	var base_speed = EnemyConstants.ENEMY_BASE_SPEED * f * EnemyConstants.BOSS_SPEED_MULTIPLIER


	if current_special_wave_type == WaveManager.SpecialWaveType.MAX_SPEED:
		base_speed *= 1.5
	elif current_special_wave_type == WaveManager.SpecialWaveType.HELL_WAVE:
		base_speed *= 1.5


	if weather_manager:
		base_speed *= weather_manager.get_enemy_speed_multiplier()
		hp = int(hp * weather_manager.get_enemy_hp_multiplier())

	if base_speed > EnemyConstants.ENEMY_MAX_SPEED:
		base_speed = EnemyConstants.ENEMY_MAX_SPEED
	var e = _acquire_pooled_dict("enemy")
	e["pos"] = pos
	e["speed"] = base_speed
	e["base_speed"] = base_speed
	e["hp"] = hp
	e["max_hp"] = hp
	e["radius"] = 12
	e["path"] = path_copy
	e["path_index"] = 0
	e["reached"] = false
	e["idx"] = enemy_idx
	e["is_boss"] = true
	e.erase("dying")
	e.erase("dying_time")
	e.erase("ignores_path")
	e.erase("enemy_type")
	enemy_effects[enemy_idx] = {"slow_time": 0.0, "slow_amount": 0.0, "freeze_time": 0.0, "fire_time": 0.0, "fire_damage": 0.0}
	return e

func _enemy_update(e: Dictionary, dt: float) -> void:
	if e["reached"] or e["hp"] <= 0:
		return


	var dist_to_center: float = 0.0

	var enemy_idx = e.get("idx", -1)
	if enemy_idx >= 0:

		if not enemy_effects.has(enemy_idx):
			enemy_effects[enemy_idx] = { "slow_time": 0.0, "slow_amount": 0.0, "freeze_time": 0.0, "fire_time": 0.0, "fire_damage": 0.0 }

		var effects = enemy_effects[enemy_idx]


		if not effects.has("slow_time"):
			effects["slow_time"] = 0.0
		if not effects.has("slow_amount"):
			effects["slow_amount"] = 0.0
		if not effects.has("freeze_time"):
			effects["freeze_time"] = 0.0


		if effects.get("freeze_time", 0.0) > 0.0:
			effects["freeze_time"] = effects.get("freeze_time", 0.0) - dt
			e["speed"] = e["base_speed"] * 0.3

		elif effects.get("slow_time", 0.0) > 0.0:
			effects["slow_time"] = effects.get("slow_time", 0.0) - dt
			var slow_amount = effects.get("slow_amount", 0.0)
			var slow_mult = 1.0 - slow_amount
			e["speed"] = e["base_speed"] * slow_mult
		else:
			e["speed"] = e["base_speed"]


		if effects.fire_time > 0.0:
			effects.fire_time -= dt
			var fire_damage = effects.fire_damage * dt
			e["hp"] -= fire_damage

			if not e.has("last_fire_damage_time"):
				e["last_fire_damage_time"] = 0.0
			e["last_fire_damage_time"] += dt
			if e["last_fire_damage_time"] >= 0.5:
				_create_damage_number(e["pos"], fire_damage * 10.0, false, Color(1.0, 0.5, 0.0))
				e["last_fire_damage_time"] = 0.0
			if e["hp"] <= 0:
				e["hp"] = 0
				e["dying"] = true
				e["dying_time"] = 0.0
				_create_death_animation(e["pos"])
				return

	if e.has("enemy_type"):
		var cfg = EnemyConstants.get_enemy_type_config(e["enemy_type"])
		var regen = cfg.get("regen_hp_per_second", 0.0)
		if regen > 0.0 and e["hp"] < e["max_hp"]:
			e["hp"] = min(e["max_hp"], e["hp"] + e["max_hp"] * regen * dt)

	if e["speed"] > EnemyConstants.ENEMY_MAX_SPEED:
		e["speed"] = EnemyConstants.ENEMY_MAX_SPEED
		e["base_speed"] = min(e["base_speed"], EnemyConstants.ENEMY_MAX_SPEED)


	var basep = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)


	if not e.has("path") or e["path"].is_empty():

		var v = basep - e["pos"]
		var d = max(v.length(), 0.0001)

		var dist_sq = e["pos"].distance_squared_to(basep)
		if dist_sq < 64.0:
			e["reached"] = true
			var is_boss = e.get("is_boss", false)

			var damage_to_base = 15 if is_boss else 5
			base_hp = max(0, base_hp - damage_to_base)
			if base_hp <= 0 and not game_over:
				game_over = true
				paused = true
				_show_game_over_screen()
			return

		var move_dist = e["speed"] * dt
		if move_dist > d:
			move_dist = d
		e["pos"] += v.normalized() * move_dist
		return


	if not e.has("path_index"):
		e["path_index"] = 0

	if e["path_index"] < 0:
		e["path_index"] = 0

	if e["path_index"] >= e["path"].size():

		var v = basep - e["pos"]
		var d = max(v.length(), 0.0001)

		var dist_sq = e["pos"].distance_squared_to(basep)
		if dist_sq < 64.0:
			e["reached"] = true
			var is_boss = e.get("is_boss", false)

			var damage_to_base = 15 if is_boss else 5
			base_hp = max(0, base_hp - damage_to_base)
			if base_hp <= 0 and not game_over:
				game_over = true
				paused = true
				_show_game_over_screen()
			return

		var move_dist = e["speed"] * dt
		if move_dist > d:
			move_dist = d
		e["pos"] += v.normalized() * move_dist
		return


	if e["path_index"] < 0 or e["path_index"] >= e["path"].size():
		e["path_index"] = 0

	var targ: Vector2 = e["path"][e["path_index"]]


	if targ == null or not targ is Vector2:

		var v = basep - e["pos"]
		var move_dist = e["speed"] * dt
		var d = max(v.length(), 0.0001)
		if move_dist > d:
			move_dist = d
		e["pos"] += v.normalized() * move_dist
		return




	var dist_sq_to_center = e["pos"].distance_squared_to(basep)
	if dist_sq_to_center < 64.0:
		e["reached"] = true
		var is_boss = e.get("is_boss", false)

		var damage_to_base = 15 if is_boss else 5
		base_hp = max(0, base_hp - damage_to_base)
		if base_hp <= 0 and not game_over:
			game_over = true
			paused = true
			_show_game_over_screen()
		return


	var enemy_tile = _world_to_tile_coords(e["pos"])
	var wall_detection_radius = _cfg().get_float("WALL_DAMAGE_RADIUS") + 10.0
	var hit_wall = null
	var hit_wall_idx = -1
	var closest_wall_dist = 9999.0


	var walls_size = walls.size()
	var wall_detection_radius_sq = wall_detection_radius * wall_detection_radius
	var wall_damage_radius_sq = _cfg().get_float("WALL_DAMAGE_RADIUS") * _cfg().get_float("WALL_DAMAGE_RADIUS")
	for i in range(walls_size):
		var w = walls[i]
		if w.hp > 0 and not grid_manager.is_inside_base_point(w.pos):
			var dist_sq_to_wall = e["pos"].distance_squared_to(w.pos)

			if dist_sq_to_wall < wall_detection_radius_sq and dist_sq_to_wall < closest_wall_dist * closest_wall_dist:

				var to_wall = w.pos - e["pos"]
				var to_target = targ - e["pos"]

				var to_target_len_sq = to_target.length_squared()
				if to_target_len_sq > 0.0001:
					var dot = to_wall.normalized().dot(to_target.normalized())

					if dot > -0.3 or dist_sq_to_wall < wall_damage_radius_sq:
						hit_wall = w
						hit_wall_idx = i
						closest_wall_dist = sqrt(dist_sq_to_wall)

	if hit_wall != null:



		var to_wall = hit_wall.pos - e["pos"]
		var dist_to_wall = to_wall.length()


		if dist_to_wall < _cfg().get_float("WALL_DAMAGE_RADIUS"):

			return


		var move_dist = e["speed"] * dt
		var dir_to_wall = to_wall.normalized()
		var target_dist = _cfg().get_float("WALL_DAMAGE_RADIUS") - 2.0

		if dist_to_wall - move_dist <= target_dist:

			e["pos"] = hit_wall.pos - dir_to_wall * target_dist
		else:

			e["pos"] += dir_to_wall * move_dist


		return

	var v2 = targ - e["pos"]
	var d2 = max(v2.length(), 0.0001)

	var move_dist = e["speed"] * dt
	var proximity_threshold = max(2.0, move_dist * 1.5)

	if d2 < proximity_threshold:

		e["pos"] = targ
		e["path_index"] += 1

		dist_sq_to_center = e["pos"].distance_squared_to(basep)
		if dist_sq_to_center < 64.0:
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
		return


	if move_dist > d2:
		move_dist = d2
		e["pos"] = targ
		e["path_index"] += 1

		dist_sq_to_center = e["pos"].distance_squared_to(basep)
		if dist_sq_to_center < 64.0:
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

		e["pos"] += v2.normalized() * move_dist

		dist_sq_to_center = e["pos"].distance_squared_to(basep)
		if dist_sq_to_center < 64.0:
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

	var hero_damage = hero["damage"]
	if skills_manager:
		hero_damage *= skills_manager.get_damage_multiplier()


	var arrow_speed = HERO_ARROW_SPEED


	# Crítico: apenas a base do herói pode causar (torres não têm mecânica de crítico)
	var is_crit = randf() < hero.get("crit_chance", 0.0)
	if is_crit:
		hero_damage *= hero.get("crit_multiplier", 2.0)

	var a = _acquire_pooled_dict("arrow")
	a["pos"] = Vector2(x,y)
	a["vel"] = dir/d * arrow_speed
	a["life"] = 2.0
	a["radius"] = 2
	a["damage"] = hero_damage
	a["pierce"] = hero["pierce"]
	a["is_crit"] = is_crit
	a.erase("is_missile")
	a.erase("target")
	return a

func _arrow_update(a: Dictionary, dt: float) -> void:

	if a.get("is_missile", false):
		var target = a.get("target", null)
		if target != null and target.has("pos") and target.get("hp", 0) > 0 and not target.get("reached", false):

			a["target_pos"] = target["pos"]

			var dir = (target["pos"] - a["pos"]).normalized()

			a["pos"] += dir * a["speed"] * dt

			if a["pos"].distance_squared_to(target["pos"]) < 100.0:

				var damage = a["damage"]
				var explosion_radius = a.get("explosion_radius", 0.0)
				var chain_targets = a.get("chain_targets", 1)
				var chain_count = a.get("chain_count", 0)


				target["hp"] -= damage


				if a.has("tower_id"):
					var tower_id = a["tower_id"]
					if tower_dps_data.has(tower_id):
						tower_dps_data[tower_id]["damage_dealt"] += damage

				_create_damage_number(target["pos"], damage, a.get("is_crit", false))


				if explosion_radius > 0.0:
					for e in enemies:
						if e == target or e["hp"] <= 0 or e["reached"]:
							continue

						var dist_sq = target["pos"].distance_squared_to(e["pos"])
						if dist_sq <= explosion_radius * explosion_radius:
							var area_damage = damage * 0.5
							e["hp"] -= area_damage
							if a.has("tower_id"):
								var tower_id = a["tower_id"]
								if tower_dps_data.has(tower_id):
									tower_dps_data[tower_id]["damage_dealt"] += area_damage
							_create_damage_number(e["pos"], area_damage, a.get("is_crit", false))
							if e["hp"] <= 0:
								e["hp"] = 0
								e["dying"] = true
								e["dying_time"] = 0.0
								_create_death_animation(e["pos"])
								var is_boss = e.get("is_boss", false)
								hero["coins"] += get_boss_reward() if is_boss else get_enemy_reward()
								_try_drop_coin(e["pos"])
								_try_drop_talisman(e["pos"])
								_track_enemy_kill(is_boss)


				if target["hp"] <= 0:
					target["hp"] = 0
					target["dying"] = true
					target["dying_time"] = 0.0
					_create_death_animation(target["pos"])
					var is_boss = target.get("is_boss", false)
					hero["coins"] += get_boss_reward() if is_boss else get_enemy_reward()
					_try_drop_coin(target["pos"])
					_try_drop_talisman(target["pos"])
					_track_enemy_kill(is_boss)


					if chain_count < chain_targets - 1:
						var next_target = null
						var closest_dist = 150.0
						for e in enemies:
							if e == target or e["hp"] <= 0 or e["reached"]:
								continue
							var enemy_type = e.get("enemy_type", EnemyConstants.EnemyType.ZOMBIE)
							if enemy_type != EnemyConstants.EnemyType.ALIEN_VOADOR and enemy_type != EnemyConstants.EnemyType.MECANOIDE_DRONE:
								continue

							var dist_sq = target["pos"].distance_squared_to(e["pos"])
							var closest_dist_sq = closest_dist * closest_dist
							if dist_sq < closest_dist_sq:
								var dist = sqrt(dist_sq)
								closest_dist = dist
								next_target = e

						if next_target != null:

							a["target"] = next_target
							a["target_pos"] = next_target["pos"]
							a["chain_count"] = chain_count + 1
							return


				a["life"] = 0.0
		else:

			a["life"] = 0.0
	else:

		a["pos"] += a["vel"] * dt
		a["life"] -= dt

func _recycle_dead_projectiles(list: Array, kind: String) -> void:
	var i := 0
	while i < list.size():
		if list[i]["life"] <= 0.0:
			if object_pool_manager:
				if kind == "arrow":
					object_pool_manager.return_arrow(list[i])
				else:
					object_pool_manager.return_tower_bullet(list[i])
			list[i] = list[list.size() - 1]
			list.pop_back()
		else:
			i += 1

func _compact_enemies(delta: float) -> Dictionary:
	var needs_compact := false
	for e in enemies:
		if e.get("dying", false):
			e["dying_time"] = e.get("dying_time", 0.0) + delta
			if e["dying_time"] >= 0.5:
				needs_compact = true
		elif e["hp"] <= 0 or e["reached"]:
			needs_compact = true
	if not needs_compact:
		return {}

	var alive: Array = []
	var new_enemy_effects: Dictionary = {}
	var enemy_idx_map: Dictionary = {}
	for i in range(enemies.size()):
		var e = enemies[i]
		var is_dying = e.get("dying", false)
		if is_dying:
			if e.get("dying_time", 0.0) < 0.5:
				var new_idx = alive.size()
				alive.append(e)
				e["idx"] = new_idx
				enemy_idx_map[i] = new_idx
			else:
				if object_pool_manager:
					object_pool_manager.return_enemy(e)
			if enemy_effects.has(i):
				enemy_effects.erase(i)
		elif e["hp"] > 0 and not e["reached"]:
			var new_idx = alive.size()
			alive.append(e)
			e["idx"] = new_idx
			enemy_idx_map[i] = new_idx
			if enemy_effects.has(i):
				new_enemy_effects[new_idx] = enemy_effects[i]
		else:
			if object_pool_manager:
				object_pool_manager.return_enemy(e)
			if enemy_effects.has(i):
				enemy_effects.erase(i)
	enemies = alive
	enemy_effects = new_enemy_effects
	if spatial_hash_manager:
		spatial_hash_manager.set_enemies_ref(enemies)
	return enemy_idx_map

func _acquire_pooled_dict(kind: String) -> Dictionary:
	if object_pool_manager:
		var d: Dictionary
		match kind:
			"arrow":
				d = object_pool_manager.get_arrow()
			"bullet":
				d = object_pool_manager.get_tower_bullet()
			"enemy":
				d = object_pool_manager.get_enemy()
			_:
				d = {}
		if not d.is_empty():
			return d
	return {}

func _range_int(n: int) -> Array:
	"""Retorna [0, 1, ..., n-1] para fallback quando spatial hash não é usado."""
	var a: Array = []
	for i in range(n):
		a.append(i)
	return a

func _get_enemy_indices_in_range(center: Vector2, range_radius: float) -> Array:
	if spatial_hash_manager:
		return spatial_hash_manager.get_enemy_candidates_in_range(center, range_radius)
	return _range_int(enemies.size())

func _build_static_map_texture() -> void:
	if grid_manager == null or grid_manager.grid.is_empty():
		return
	var cols: int = _cfg().get_int("GRID_COLS")
	var rows: int = _cfg().get_int("GRID_ROWS")
	var tile_sz: int = _cfg().get_int("TILE_SIZE")
	var map_w: int = cols * tile_sz
	var map_h: int = rows * tile_sz
	var img := Image.create(map_w, map_h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.05, 0.06, 0.08))
	var path_tile := _prepare_tile_image(tex_path, tile_sz, false)
	var grass_tile := _prepare_tile_image(tex_grass, tile_sz, true)
	var wall_tile := _prepare_tile_image(tex_wall, tile_sz, false)
	var darken := 0.468
	for r in range(rows):
		if grid_manager.grid.size() <= r:
			continue
		for c in range(cols):
			if grid_manager.grid[r].size() <= c:
				continue
			var dest := Vector2i(c * tile_sz, r * tile_sz)
			if grid_manager.grid[r][c] == 0:
				if path_tile != null:
					img.blit_rect(path_tile, Rect2i(0, 0, tile_sz, tile_sz), dest)
				elif grass_tile != null:
					img.blit_rect(grass_tile, Rect2i(0, 0, tile_sz, tile_sz), dest)
				else:
					_fill_image_rect(img, dest, Vector2i(tile_sz, tile_sz), Color(0.16, 0.14, 0.12))
			elif wall_tile != null:
				img.blit_rect(wall_tile, Rect2i(0, 0, tile_sz, tile_sz), dest)
			else:
				_fill_image_rect(img, dest, Vector2i(tile_sz, tile_sz), Color(0.24, 0.22, 0.20))
	_apply_image_darken_overlay(img, 1.0 - darken)
	_static_map_texture = ImageTexture.create_from_image(img)

func _prepare_tile_image(tex: Texture2D, tile_sz: int, tiled: bool) -> Image:
	if tex == null:
		return null
	var src_img := tex.get_image()
	if src_img == null or src_img.is_empty():
		return null
	if src_img.get_format() != Image.FORMAT_RGBA8:
		src_img.convert(Image.FORMAT_RGBA8)
	if tiled:
		var tiled_img := Image.create(tile_sz, tile_sz, false, Image.FORMAT_RGBA8)
		var sw: int = src_img.get_width()
		var sh: int = src_img.get_height()
		for dy in range(tile_sz):
			for dx in range(tile_sz):
				tiled_img.set_pixel(dx, dy, src_img.get_pixel(dx % sw, dy % sh))
		return tiled_img
	if src_img.get_width() != tile_sz or src_img.get_height() != tile_sz:
		src_img.resize(tile_sz, tile_sz, Image.INTERPOLATE_LANCZOS)
	return src_img

func _fill_image_rect(img: Image, dest: Vector2i, size: Vector2i, color: Color) -> void:
	img.fill_rect(Rect2i(dest, size), color)

func _apply_image_darken_overlay(img: Image, alpha: float) -> void:
	var factor := 1.0 - alpha
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	var data := img.get_data()
	var factor_i := factor
	for i in range(0, data.size(), 4):
		data[i] = int(data[i] * factor_i)
		data[i + 1] = int(data[i + 1] * factor_i)
		data[i + 2] = int(data[i + 2] * factor_i)
	img.set_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, data)

func _handle_collisions() -> void:
	# Otimização: usa spatial hash para só testar projéteis contra inimigos em células próximas (menos checks, mesmo resultado)
	for a in arrows:
		if a["life"] <= 0.0:
			continue
		var candidate_indices: Array = spatial_hash_manager.get_enemy_candidates_in_range(a["pos"], COLLISION_LOOKUP_RADIUS) if spatial_hash_manager else _range_int(enemies.size())
		for idx in candidate_indices:
			if a["life"] <= 0.0:
				break
			var i := int(idx)
			if i < 0 or i >= enemies.size():
				continue
			var e = enemies[i]
			if e["hp"] <= 0 or e["reached"]:
				continue

			var collision_radius = a["radius"] + e["radius"]
			if a["pos"].distance_squared_to(e["pos"]) < collision_radius * collision_radius:
				var damage = a["damage"]
				e["hp"] -= damage

				_create_damage_number(e["pos"], damage, a.get("is_crit", false))
				if e["hp"] <= 0:
					e["hp"] = 0
					e["dying"] = true
					e["dying_time"] = 0.0

					_create_death_animation(e["pos"])
					var is_boss = e.get("is_boss", false)

					hero["coins"] += get_boss_reward() if is_boss else get_enemy_reward()

					_try_drop_coin(e["pos"])
					_try_drop_talisman(e["pos"])

					_try_drop_special_currency(e["pos"], is_boss)

					_track_enemy_kill(is_boss)
				if a["pierce"] > 0:
					a["pierce"] -= 1
				else:
					a["life"] = 0.0

	for b in tower_bullets:
		if b["life"] <= 0.0:
			continue

		if b.get("is_missile", false):
			continue
		var candidate_indices: Array = spatial_hash_manager.get_enemy_candidates_in_range(b["pos"], COLLISION_LOOKUP_RADIUS) if spatial_hash_manager else _range_int(enemies.size())
		for idx in candidate_indices:
			var i := int(idx)
			if i < 0 or i >= enemies.size():
				continue
			var e = enemies[i]
			if e["hp"] <= 0 or e["reached"]:
				continue

			var collision_radius = b["radius"] + e["radius"]
			if b["pos"].distance_squared_to(e["pos"]) < collision_radius * collision_radius:
				var damage_dealt = b["damage"]
				e["hp"] -= damage_dealt


				if b.has("tower_id"):
					var tower_id = b["tower_id"]
					if tower_dps_data.has(tower_id):
						tower_dps_data[tower_id]["damage_dealt"] += damage_dealt


				_create_damage_number(e["pos"], damage_dealt, b.get("is_crit", false))
				if e["hp"] <= 0:
					e["hp"] = 0
					e["dying"] = true
					e["dying_time"] = 0.0

					_create_death_animation(e["pos"])
					var is_boss = e.get("is_boss", false)

					hero["coins"] += get_boss_reward() if is_boss else get_enemy_reward()

					_try_drop_coin(e["pos"])
					_try_drop_talisman(e["pos"])

					_try_drop_special_currency(e["pos"], is_boss)

					_track_enemy_kill(is_boss)


				var enemy_idx = e.get("idx", -1)
				if enemy_idx >= 0 and enemy_effects.has(enemy_idx):
					var effects = enemy_effects[enemy_idx]
					if b.get("has_freeze", false):
						effects.freeze_time = max(effects.freeze_time, _cfg().get_float("TOWER_FREEZE_DURATION"))
					if b.get("has_fire", false):
						effects.fire_time = max(effects.fire_time, _cfg().get_float("TOWER_FIRE_DURATION"))
						effects.fire_damage = max(effects.fire_damage, b["damage"] * _cfg().get_float("TOWER_FIRE_DAMAGE_MULTIPLIER"))

				b["life"] = 0.0
				break

func _find_tower_at(p: Vector2, r: float) -> int:
	return _find_structure_at("towers", p, r)

func _find_market_at(p: Vector2, r: float) -> int:
	return _find_structure_at("markets", p, r)

func _find_barracks_at(p: Vector2, r: float) -> int:
	return _find_structure_at("barracks", p, r)

func _find_healing_station_at(p: Vector2, r: float) -> int:
	return _find_structure_at("healing_stations", p, r)

func _find_sniper_tower_at(p: Vector2, r: float) -> int:
	return _find_structure_at("sniper_towers", p, r)

func _find_aoe_tower_at(p: Vector2, r: float) -> int:
	return _find_structure_at("aoe_towers", p, r)

func _find_shock_tower_at(p: Vector2, r: float) -> int:
	return _find_structure_at("shock_towers", p, r)

func _find_anti_air_tower_at(p: Vector2, r: float) -> int:
	return _find_structure_at("anti_air_towers", p, r)

func _find_slow_tower_at(p: Vector2, r: float) -> int:
	return _find_structure_at("slow_towers", p, r)

func _find_boost_tower_at(p: Vector2, r: float) -> int:
	return _find_structure_at("boost_towers", p, r)

func _start_drag_tower(tower_type: String, tower_idx: int, mouse_pos: Vector2) -> void:
	dragging_tower = true
	dragged_tower_type = tower_type
	dragged_tower_index = tower_idx


	var def := StructureCatalog.get_def(tower_type)
	var arr: Array = _get_structure_array(def.get("array", ""))
	var tower_pos: Vector2 = arr[tower_idx].pos

	drag_start_pos = mouse_pos
	drag_offset = mouse_pos - tower_pos
	drag_current_pos = mouse_pos
	queue_redraw()

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


	if not grid_manager.is_inside_base_point(tower_center_pos):
		return result



	var grid_coord = grid_manager.world_to_base_grid(tower_center_pos)



	if grid_coord.x + tower_size > _cfg().get_int("BASE_GRID_SIZE"):
		grid_coord.x = _cfg().get_int("BASE_GRID_SIZE") - tower_size
	if grid_coord.y + tower_size > _cfg().get_int("BASE_GRID_SIZE"):
		grid_coord.y = _cfg().get_int("BASE_GRID_SIZE") - tower_size


	grid_coord.x = max(0, grid_coord.x)
	grid_coord.y = max(0, grid_coord.y)



	var snapped_world_pos = grid_manager.base_grid_to_world(grid_coord.x, grid_coord.y, tower_size)

	result["grid_coord"] = grid_coord
	result["snapped_world_pos"] = snapped_world_pos
	return result

func _end_drag_tower(mouse_pos: Vector2) -> void:
	if not dragging_tower:
		return




	var tower_center_pos = drag_current_pos - drag_offset


	var drag_def := StructureCatalog.get_def(dragged_tower_type)
	var tower_size = 1
	if not drag_def.is_empty() and drag_def.get("placement", "") == StructureCatalog.PLACEMENT_BASE:
		tower_size = _cfg().get_int(drag_def.size_key)


	var snap_result = _calculate_tower_snap(tower_center_pos, tower_size)
	var grid_coord = snap_result["grid_coord"]
	var snapped_world_pos = snap_result["snapped_world_pos"]



	if snapped_world_pos == Vector2.ZERO:

		if not grid_manager.is_inside_base_point(tower_center_pos):
			_clear_drag_state()
			queue_redraw()
			return


		snapped_world_pos = tower_center_pos



	var moved = false
	if dragged_tower_type == "mine":
		moved = _try_move_mine(dragged_tower_index, tower_center_pos)
	elif dragged_tower_type == "wall":
		var wall_tile = _world_to_tile_coords(tower_center_pos)
		var wall_world_pos = Vector2(wall_tile.x * _cfg().get_int("TILE_SIZE"), wall_tile.y * _cfg().get_int("TILE_SIZE"))
		moved = _try_move_wall(dragged_tower_index, wall_world_pos)
	else:
		moved = _try_move_structure_to_grid(dragged_tower_type, dragged_tower_index, grid_coord)


	if not moved:

		pass


	_clear_drag_state()
	queue_redraw()

func _open_tower_menu(idx: int, screen_pos: Vector2) -> void:
	if tower_menu == null:
		return
	tower_selected_index = idx
	var t = towers[idx]
	_show_range_indicator(t.pos, t.range, Color(0.3, 0.7, 1.0, 0.65))
	var dirs_count: int = t.dirs.size()


	var range_level = t.levels.get("RANGE", 0)
	var rate_level = t.levels.get("RATE", 0)
	var dmg_level = t.levels.get("DMG", 0)

	var range_cost = int(_cfg().get_int("TOWER_RANGE_COST") * pow(1.5, range_level))
	var rate_cost = get_upgrade_cost(_cfg().get_int("TOWER_RATE_COST"), rate_level)
	var dirs_cost = _cfg().get_int("TOWER_DIRS_COST")
	var dmg_cost = get_upgrade_cost(_cfg().get_int("TOWER_DMG_COST"), dmg_level)
	var freeze_cost = _cfg().get_int("TOWER_FREEZE_COST")
	var fire_cost = _cfg().get_int("TOWER_FIRE_COST")


	var range_emerald_cost = get_tower_upgrade_emerald_cost("RANGE", range_level)
	var rate_emerald_cost = get_tower_upgrade_emerald_cost("RATE", rate_level)
	var dmg_emerald_cost = get_tower_upgrade_emerald_cost("DMG", dmg_level)


	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}
	var has_emeralds = currency_info.emeralds > 0


	var max_range = _get_max_tower_range()
	var can_range: bool = hero["coins"] >= range_cost and t.range < max_range
	var can_rate: bool = hero["coins"] >= rate_cost and t.fire_rate > _cfg().get_float("TOWER_MIN_FIRE_RATE")
	var can_dirs: bool = hero["coins"] >= dirs_cost and dirs_count < 4
	var can_dmg: bool = hero["coins"] >= dmg_cost
	var dmg_upgrade_amount: float = _cfg().get_float("TOWER_DMG_UPGRADE_AMOUNT")
	var can_freeze: bool = hero["coins"] >= freeze_cost and not t.get("has_freeze", false) and not t.get("has_fire", false)
	var can_fire: bool = hero["coins"] >= fire_cost and not t.get("has_fire", false) and not t.get("has_freeze", false)


	var can_range_emerald: bool = currency_info.emeralds >= range_emerald_cost and t.range < max_range
	var can_rate_emerald: bool = currency_info.emeralds >= rate_emerald_cost and t.fire_rate > _cfg().get_float("TOWER_MIN_FIRE_RATE")
	var can_dmg_emerald: bool = currency_info.emeralds >= dmg_emerald_cost



	tower_menu.set_item_text(0, "Alcance +60 (💰 %d moedas)" % range_cost)
	tower_menu.set_item_text(1, "Alcance +60 (🟢 %d esmeraldas)" % range_emerald_cost)
	tower_menu.set_item_text(3, "Cadência + (💰 %d moedas)" % rate_cost)
	tower_menu.set_item_text(4, "Cadência + (🟢 %d esmeraldas)" % rate_emerald_cost)
	tower_menu.set_item_text(6, "+4 Direções (💰 %d moedas)" % dirs_cost)
	tower_menu.set_item_text(8, "Dano +%.1f (💰 %d moedas)" % [dmg_upgrade_amount, dmg_cost])
	tower_menu.set_item_text(9, "Dano +%.1f (🟢 %d esmeraldas)" % [dmg_upgrade_amount, dmg_emerald_cost])
	tower_menu.set_item_text(11, "Congelamento (💰 %d moedas)" % freeze_cost)
	tower_menu.set_item_text(12, "Fogo (💰 %d moedas)" % fire_cost)


	tower_menu.set_item_disabled(0, not can_range)
	tower_menu.set_item_disabled(1, not can_range_emerald)
	tower_menu.set_item_disabled(3, not can_rate)
	tower_menu.set_item_disabled(4, not can_rate_emerald)
	tower_menu.set_item_disabled(6, not can_dirs)
	tower_menu.set_item_disabled(8, not can_dmg)
	tower_menu.set_item_disabled(9, not can_dmg_emerald)
	tower_menu.set_item_disabled(11, not can_freeze)
	tower_menu.set_item_disabled(12, not can_fire)
	_present_from_popup(tower_menu, "Torre Básica", "Dano %.1f · Cadência %.2f · Alcance %.0f · Direções %d" % [t.damage, t.fire_rate, t.range, dirs_count], t.pos, t.range, "tower", idx, screen_pos)

func _on_tower_menu_pressed(id: int) -> void:
	if tower_selected_index < 0 or tower_selected_index >= towers.size():
		return
	var t = towers[tower_selected_index]


	var range_level = t.levels.get("RANGE", 0)
	var rate_level = t.levels.get("RATE", 0)
	var dmg_level = t.levels.get("DMG", 0)


	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}

	match id:
		1:
			var cost = int(_cfg().get_int("TOWER_RANGE_COST") * pow(1.5, range_level))
			var max_range = _get_max_tower_range()
			if hero["coins"] >= cost and t.range < max_range:
				t.range += 60.0
				t.range = min(t.range, max_range)
				t.levels["RANGE"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)

				if quest_manager:
					quest_manager.update_quest_progress(GameConstants.QuestType.UPGRADE_TOWERS, 1)
		11:
			var emerald_cost = get_tower_upgrade_emerald_cost("RANGE", range_level)
			var max_range = _get_max_tower_range()
			if currency_info.emeralds >= emerald_cost and t.range < max_range:
				special_currency_manager.spend_emeralds(emerald_cost)
				t.range += 60.0
				t.range = min(t.range, max_range)
				t.levels["RANGE"] += 1
				_update_special_currency_labels()

				if quest_manager:
					quest_manager.update_quest_progress(GameConstants.QuestType.UPGRADE_TOWERS, 1)
		2:
			var cost = get_upgrade_cost(_cfg().get_int("TOWER_RATE_COST"), rate_level)
			if hero["coins"] >= cost and t.fire_rate > _cfg().get_float("TOWER_MIN_FIRE_RATE"):
				t.fire_rate = max(_cfg().get_float("TOWER_MIN_FIRE_RATE"), t.fire_rate - _cfg().get_float("TOWER_FIRE_RATE_REDUCTION"))
				t.levels["RATE"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)

				if quest_manager:
					quest_manager.update_quest_progress(GameConstants.QuestType.UPGRADE_TOWERS, 1)
		12:
			var emerald_cost = get_tower_upgrade_emerald_cost("RATE", rate_level)
			if currency_info.emeralds >= emerald_cost and t.fire_rate > _cfg().get_float("TOWER_MIN_FIRE_RATE"):
				special_currency_manager.spend_emeralds(emerald_cost)
				t.fire_rate = max(_cfg().get_float("TOWER_MIN_FIRE_RATE"), t.fire_rate - _cfg().get_float("TOWER_FIRE_RATE_REDUCTION"))
				t.levels["RATE"] += 1
				_update_special_currency_labels()

				if quest_manager:
					quest_manager.update_quest_progress(GameConstants.QuestType.UPGRADE_TOWERS, 1)
		3:
			if hero["coins"] >= _cfg().get_int("TOWER_DIRS_COST") and t.dirs.size() < 4:

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
				hero["coins"] -= _cfg().get_int("TOWER_DIRS_COST")
				_track_coin_spent(_cfg().get_int("TOWER_DIRS_COST"))
		4:
			var cost = get_upgrade_cost(_cfg().get_int("TOWER_DMG_COST"), dmg_level)
			if hero["coins"] >= cost:
				t.damage += _cfg().get_float("TOWER_DMG_UPGRADE_AMOUNT")
				t.levels["DMG"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)

				if quest_manager:
					quest_manager.update_quest_progress(GameConstants.QuestType.UPGRADE_TOWERS, 1)
		14:
			var emerald_cost = get_tower_upgrade_emerald_cost("DMG", dmg_level)
			if currency_info.emeralds >= emerald_cost:
				special_currency_manager.spend_emeralds(emerald_cost)
				t.damage += _cfg().get_float("TOWER_DMG_UPGRADE_AMOUNT")
				t.levels["DMG"] += 1
				_update_special_currency_labels()

				if quest_manager:
					quest_manager.update_quest_progress(GameConstants.QuestType.UPGRADE_TOWERS, 1)
		5:
			if hero["coins"] >= _cfg().get_int("TOWER_FREEZE_COST") and not t.get("has_freeze", false) and not t.get("has_fire", false):
				t["has_freeze"] = true
				t["has_fire"] = false
				t.levels["FREEZE"] = 1
				t.levels["FIRE"] = 0
				hero["coins"] -= _cfg().get_int("TOWER_FREEZE_COST")
				_track_coin_spent(_cfg().get_int("TOWER_FREEZE_COST"))
		6:
			if hero["coins"] >= _cfg().get_int("TOWER_FIRE_COST") and not t.get("has_fire", false) and not t.get("has_freeze", false):
				t["has_fire"] = true
				t["has_freeze"] = false
				t.levels["FIRE"] = 1
				t.levels["FREEZE"] = 0
				hero["coins"] -= _cfg().get_int("TOWER_FIRE_COST")
				_track_coin_spent(_cfg().get_int("TOWER_FIRE_COST"))
	towers[tower_selected_index] = t


	var saved_menu_pos = _inspect_screen_pos()


	keep_menu_open = true
	_reopen_tower_menu_immediately(saved_menu_pos)

func _reopen_tower_menu_immediately(menu_pos: Vector2) -> void:
	"""Reabre o menu de torre na mesma posicao apos um upgrade"""
	if not PopupMenuHelper.can_reopen(keep_menu_open, tower_selected_index, towers.size(), choosing_upgrade, game_over):
		keep_menu_open = false
		return
	call_deferred("_actually_reopen_tower_menu", menu_pos)

func _actually_reopen_tower_menu(menu_pos: Vector2) -> void:
	"""Reabre efetivamente o menu apos o fechamento"""
	if not PopupMenuHelper.can_reopen(keep_menu_open, tower_selected_index, towers.size(), choosing_upgrade, game_over):
		keep_menu_open = false
		return
	_open_tower_menu(tower_selected_index, menu_pos)
	keep_menu_open = false

func _try_shoot(target: Vector2) -> void:
	if hero["cooldown"] > 0.0:
		return
	arrows.append(_arrow_new(hero["x"], hero["y"], target))
	hero["cooldown"] += hero["fire_rate"]

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
			var miss_distance = _cfg().get_int("TILE_SIZE") * randf_range(1.2, 2.5)
			predicted += miss_dir * miss_distance

	return predicted

func _get_enemy_velocity(enemy: Dictionary) -> Vector2:
	var speed = enemy.get("speed", EnemyConstants.ENEMY_BASE_SPEED)
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

func _get_enemy_direction(enemy: Dictionary) -> String:
	var velocity = _get_enemy_velocity(enemy)
	if velocity.length() < 0.01:
		return "down"

	var dir = velocity.normalized()
	var angle = atan2(dir.y, dir.x)







	if angle >= -PI/4 and angle < PI/4:
		return "right"
	elif angle >= PI/4 and angle < 3*PI/4:
		return "down"
	elif angle >= 3*PI/4 or angle < -3*PI/4:
		return "left"
	else:
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
	if tb.find_child("LblEmeralds", true, false) and tb.find_child("LblDiamonds", true, false):
		emerald_label = tb.find_child("LblEmeralds", true, false)
		diamond_label = tb.find_child("LblDiamonds", true, false)
		return

	emerald_label = Label.new()
	emerald_label.name = "LblEmeralds"
	emerald_label.text = "🟢 0"
	emerald_label.add_theme_color_override("font_color", Color(0.35, 0.85, 0.45))
	emerald_label.add_theme_font_size_override("font_size", 16)
	emerald_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emerald_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tb.add_child(emerald_label)

	diamond_label = Label.new()
	diamond_label.name = "LblDiamonds"
	diamond_label.text = "💎 0"
	diamond_label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
	diamond_label.add_theme_font_size_override("font_size", 16)
	diamond_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	diamond_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tb.add_child(diamond_label)

func _update_special_currency_labels() -> void:
	"""Atualiza os labels de moedas especiais"""
	if not special_currency_manager:
		return

	var tb = $CanvasLayer/HUD/TopBar
	if not tb:
		return


	if not tb.find_child("LblEmeralds", true, false) or not tb.find_child("LblDiamonds", true, false):
		_create_special_currency_labels(tb)


	if not emerald_label or not diamond_label:
		if tb.has_node("LblEmeralds"):
			emerald_label = tb.get_node("LblEmeralds")
		if tb.has_node("LblDiamonds"):
			diamond_label = tb.get_node("LblDiamonds")


	var currency_info = special_currency_manager.get_currency_info()

	if emerald_label:
		emerald_label.text = "🟢 %d" % currency_info.emeralds

	if diamond_label:
		diamond_label.text = "💎 %d" % currency_info.diamonds


func _create_admin_menu(tb: Panel) -> void:

	if not isAdmin:

		if tb.has_node("BtnKillAll"):
			tb.get_node("BtnKillAll").visible = false
		return


	if tb.has_node("BtnKillAll"):
		tb.get_node("BtnKillAll").visible = false


	if tb.has_node("BtnJumpWave10"):
		tb.get_node("BtnJumpWave10").queue_free()


	var menu_container = Control.new()
	menu_container.name = "AdminMenuContainer"
	menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tb.add_child(menu_container)


	admin_menu = PopupMenu.new()
	admin_menu.name = "AdminMenu"
	admin_menu.add_item("Kill All", 1)
	admin_menu.add_item("+10 Waves", 2)
	admin_menu.add_item("+100 Moedas", 3)
	admin_menu.add_item("+1000 Moedas", 4)
	admin_menu.add_item("+100 Esmeraldas", 5)
	admin_menu.id_pressed.connect(_on_admin_menu_pressed)
	menu_container.add_child(admin_menu)


	admin_menu_button = Button.new()
	admin_menu_button.name = "BtnAdmin"
	admin_menu_button.text = "Admin"
	admin_menu_button.custom_minimum_size = Vector2(72, 32)
	admin_menu_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UIHelper.apply_accent_button(admin_menu_button, Color(0.38, 0.22, 0.52), Color(0.48, 0.3, 0.64))
	admin_menu_button.pressed.connect(_on_admin_button_pressed)
	tb.add_child(admin_menu_button)

func _on_admin_button_pressed() -> void:

	var screen_pos = admin_menu_button.global_position + Vector2(0, admin_menu_button.size.y)
	admin_menu.position = screen_pos
	admin_menu.popup()

func _on_admin_menu_pressed(id: int) -> void:
	match id:
		1:
			enemies.clear()
			print("Admin: Todos os inimigos foram eliminados")
		2:
			_jump_10_waves()
		3:
			_add_100_coins()
		4:
			_add_1000_coins()
		5:
			_add_100_emeralds()

func _jump_10_waves() -> void:

	var current_wave = wave_manager.wave
	wave_manager.jump_to_wave(current_wave + 10)
	enemies.clear()
	choosing_upgrade = false
	print("Admin: Pulou 10 waves (agora na wave %d)" % wave_manager.wave)

func _add_100_coins() -> void:

	hero["coins"] += 100
	print("Admin: +100 moedas adicionadas (total: %d)" % hero["coins"])

func _add_1000_coins() -> void:

	hero["coins"] += 1000
	print("Admin: +1000 moedas adicionadas (total: %d)" % hero["coins"])

func _add_100_emeralds() -> void:

	if special_currency_manager:
		special_currency_manager.add_emeralds(100)
		print("Admin: +100 esmeraldas adicionadas")
		if notification_manager:
			notification_manager.show_notification("+100 Esmeraldas!", 3.0, NotificationManager.NotificationPosition.TOP_CENTER, Color(0.2, 0.8, 0.3))



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

	if hero_manager:
		hero_manager.hero_home_level = next_level
	_apply_hero_home_upgrade_effects(next_level)
	_update_hero_home_panel_ui()
	_update_tower_shop_ui()
	queue_redraw()

func _on_wave_started(wave_number: int, _is_boss_wave: bool, special_wave_type: WaveManager.SpecialWaveType):
	if pathfinder:
		pathfinder.invalidate_cache()

	for tower_id in tower_dps_data.keys():
		if tower_dps_data[tower_id].has("wave_damage"):
			tower_dps_data[tower_id]["wave_damage"][wave_number - 1] = tower_dps_data[tower_id].get("damage_dealt", 0.0)
		tower_dps_data[tower_id]["damage_dealt"] = 0.0
		tower_dps_data[tower_id]["shots"] = 0
	if ((wave_number + 1) % 5) == 0:
		_show_boss_warning("ALERTA! Boss chegando na próxima wave!")


	var previous_special_wave_type = current_special_wave_type
	current_special_wave_type = special_wave_type
	perfect_wave_bonus_given = false


	if weather_manager:
		var old_weather = weather_manager.current_weather
		var weather_changed = weather_manager.update_weather(wave_number)

		if weather_changed and weather_manager.current_weather != WeatherManager.WeatherType.NONE and weather_manager.current_weather != old_weather:
			_show_weather_alert(wave_number)
		_apply_weather_effects()


	if special_wave_type == WaveManager.SpecialWaveType.NONE and previous_special_wave_type != WaveManager.SpecialWaveType.NONE:

		if special_wave_alert_label:
			special_wave_alert_label.visible = false
			special_wave_alert_timer = 0.0
		special_wave_coin_multiplier = 1.0
	elif special_wave_type != WaveManager.SpecialWaveType.NONE and special_wave_type != previous_special_wave_type:

		_show_special_wave_alert(wave_number, special_wave_type)

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
				special_wave_coin_multiplier = 1.0
			WaveManager.SpecialWaveType.HELL_WAVE:
				special_wave_coin_multiplier = 1.5
			_:
				special_wave_coin_multiplier = 1.0
	elif special_wave_type == WaveManager.SpecialWaveType.NONE:

		if special_wave_alert_label and special_wave_alert_label.visible:
			special_wave_alert_label.visible = false
			special_wave_alert_timer = 0.0
		special_wave_coin_multiplier = 1.0
	else:
		special_wave_coin_multiplier = 1.0


	current_wave_base_hp_start = base_hp


	achievement_manager.set_progress("wave_10", wave_number)
	achievement_manager.set_progress("wave_25", wave_number)
	achievement_manager.set_progress("wave_50", wave_number)
	achievement_manager.set_progress("wave_100", wave_number)
	achievement_manager.set_progress("wave_200", wave_number)
	achievement_manager.set_progress("wave_500", wave_number)


	if wave_number == 50:
		if notification_manager:
			notification_manager.show_notification("Na próxima wave terá monstros voadores!", 5.0, NotificationManager.NotificationPosition.TOP_CENTER, Color(1.0, 0.8, 0.2))

func _on_buy_tower() -> void:
	_begin_placing("tower")

func _on_buy_barracks() -> void:
	_begin_placing("barracks")

func _on_buy_menu_pressed(id: int) -> void:
	match id:
		1:
			_on_buy_tower()
		2:
			_on_buy_barracks()
		3:
			_on_buy_mine()
		4:
			_on_buy_slow_tower()
		5:
			_on_buy_aoe_tower()
		6:
			_on_buy_sniper_tower()
		7:
			_on_buy_boost_tower()
		8:
			_on_buy_shock_tower()
		9:
			_on_buy_wall()
		10:
			_on_buy_healing_station()

func _open_barracks_menu(idx: int, screen_pos: Vector2) -> void:
	if barracks_menu == null:
		return
	barracks_selected_index = idx
	var b = barracks[idx]


	var dmg_level = b.levels.get("DMG", 0)
	var hold_level = b.levels.get("HOLD", 0)
	var spawn_rate_level = b.levels.get("SPAWN_RATE", 0)
	var projectile_speed_level = b.levels.get("PROJECTILE_SPEED", 0)
	var dmg_cost = get_upgrade_cost(_cfg().get_int("BARRACKS_DMG_COST"), dmg_level)
	var hold_cost = get_upgrade_cost(_cfg().get_int("BARRACKS_HOLD_COST"), hold_level)
	var spawn_rate_cost = get_upgrade_cost(_cfg().get_int("BARRACKS_SPAWN_RATE_COST"), spawn_rate_level)
	var projectile_speed_cost = get_upgrade_cost(_cfg().get_int("BARRACKS_PROJECTILE_SPEED_COST"), projectile_speed_level)


	var dmg_emerald_cost = get_tower_upgrade_emerald_cost("DMG", dmg_level)
	var hold_emerald_cost = get_tower_upgrade_emerald_cost("HOLD", hold_level)
	var spawn_rate_emerald_cost = get_tower_upgrade_emerald_cost("RATE", spawn_rate_level)
	var projectile_speed_emerald_cost = get_tower_upgrade_emerald_cost("SPEED", projectile_speed_level)


	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}

	var can_dmg: bool = hero["coins"] >= dmg_cost
	var can_hold: bool = hero["coins"] >= hold_cost and b.hold_time < _cfg().get_float("BARRACKS_MAX_HOLD_TIME")
	var can_spawn_rate: bool = hero["coins"] >= spawn_rate_cost and b.soldier_spawn_rate > _cfg().get_float("BARRACKS_MIN_SPAWN_RATE")
	var can_projectile_speed: bool = hero["coins"] >= projectile_speed_cost
	var can_dmg_emerald: bool = currency_info.emeralds >= dmg_emerald_cost
	var can_hold_emerald: bool = currency_info.emeralds >= hold_emerald_cost and b.hold_time < _cfg().get_float("BARRACKS_MAX_HOLD_TIME")
	var can_spawn_rate_emerald: bool = currency_info.emeralds >= spawn_rate_emerald_cost and b.soldier_spawn_rate > _cfg().get_float("BARRACKS_MIN_SPAWN_RATE")
	var can_projectile_speed_emerald: bool = currency_info.emeralds >= projectile_speed_emerald_cost


	barracks_menu.set_item_text(0, "Dano +0.2 (💰 %d moedas)" % dmg_cost)
	barracks_menu.set_item_text(1, "Dano +0.2 (🟢 %d esmeraldas)" % dmg_emerald_cost)
	barracks_menu.set_item_text(3, "Tempo Hold +%.1fs (💰 %d moedas)" % [_cfg().get_float("BARRACKS_HOLD_TIME_INCREASE"), hold_cost])
	barracks_menu.set_item_text(4, "Tempo Hold +%.1fs (🟢 %d esmeraldas)" % [_cfg().get_float("BARRACKS_HOLD_TIME_INCREASE"), hold_emerald_cost])
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
	_present_from_popup(barracks_menu, "Quartel", "Dano %.1f · Hold %.1fs · Spawn %.1fs" % [b.damage, b.hold_time, b.soldier_spawn_rate], b.pos, 0.0, "barracks", idx, screen_pos)

func _on_barracks_menu_pressed(id: int) -> void:
	if barracks_selected_index < 0 or barracks_selected_index >= barracks.size():
		return
	var b = barracks[barracks_selected_index]
	var dmg_level = b.levels.get("DMG", 0)
	var hold_level = b.levels.get("HOLD", 0)
	var spawn_rate_level = b.levels.get("SPAWN_RATE", 0)
	var projectile_speed_level = b.levels.get("PROJECTILE_SPEED", 0)


	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}

	match id:
		1:
			var cost = get_upgrade_cost(_cfg().get_int("BARRACKS_DMG_COST"), dmg_level)
			if hero["coins"] >= cost:
				b.damage += _cfg().get_float("BARRACKS_SOLDIER_DAMAGE_INCREASE")
				b.levels["DMG"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		10:
			var emerald_cost = get_tower_upgrade_emerald_cost("DMG", dmg_level)
			if currency_info.emeralds >= emerald_cost:
				special_currency_manager.spend_emeralds(emerald_cost)
				b.damage += _cfg().get_float("BARRACKS_SOLDIER_DAMAGE_INCREASE")
				b.levels["DMG"] += 1
				_update_special_currency_labels()

				if quest_manager:
					quest_manager.update_quest_progress(GameConstants.QuestType.UPGRADE_TOWERS, 1)
		2:
			var cost = get_upgrade_cost(_cfg().get_int("BARRACKS_HOLD_COST"), hold_level)
			if hero["coins"] >= cost and b.hold_time < _cfg().get_float("BARRACKS_MAX_HOLD_TIME"):
				var new_hold_time = b.hold_time + _cfg().get_float("BARRACKS_HOLD_TIME_INCREASE")
				b.hold_time = min(new_hold_time, _cfg().get_float("BARRACKS_MAX_HOLD_TIME"))
				b.levels["HOLD"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		11:
			var emerald_cost = get_tower_upgrade_emerald_cost("HOLD", hold_level)
			if currency_info.emeralds >= emerald_cost and b.hold_time < _cfg().get_float("BARRACKS_MAX_HOLD_TIME"):
				special_currency_manager.spend_emeralds(emerald_cost)
				var new_hold_time = b.hold_time + _cfg().get_float("BARRACKS_HOLD_TIME_INCREASE")
				b.hold_time = min(new_hold_time, _cfg().get_float("BARRACKS_MAX_HOLD_TIME"))
				b.levels["HOLD"] += 1
				_update_special_currency_labels()
		3:
			var cost = get_upgrade_cost(_cfg().get_int("BARRACKS_SPAWN_RATE_COST"), spawn_rate_level)
			if hero["coins"] >= cost and b.soldier_spawn_rate > _cfg().get_float("BARRACKS_MIN_SPAWN_RATE"):
				b.soldier_spawn_rate = max(_cfg().get_float("BARRACKS_MIN_SPAWN_RATE"), b.soldier_spawn_rate - _cfg().get_float("BARRACKS_SPAWN_RATE_REDUCTION"))
				b.levels["SPAWN_RATE"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		12:
			var emerald_cost = get_tower_upgrade_emerald_cost("RATE", spawn_rate_level)
			if currency_info.emeralds >= emerald_cost and b.soldier_spawn_rate > _cfg().get_float("BARRACKS_MIN_SPAWN_RATE"):
				special_currency_manager.spend_emeralds(emerald_cost)
				b.soldier_spawn_rate = max(_cfg().get_float("BARRACKS_MIN_SPAWN_RATE"), b.soldier_spawn_rate - _cfg().get_float("BARRACKS_SPAWN_RATE_REDUCTION"))
				b.levels["SPAWN_RATE"] += 1
				_update_special_currency_labels()
		4:
			var cost = get_upgrade_cost(_cfg().get_int("BARRACKS_PROJECTILE_SPEED_COST"), projectile_speed_level)
			if hero["coins"] >= cost:
				b.projectile_speed += _cfg().get_float("BARRACKS_PROJECTILE_SPEED_INCREASE")
				b.levels["PROJECTILE_SPEED"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		13:
			var emerald_cost = get_tower_upgrade_emerald_cost("SPEED", projectile_speed_level)
			if currency_info.emeralds >= emerald_cost:
				special_currency_manager.spend_emeralds(emerald_cost)
				b.projectile_speed += _cfg().get_float("BARRACKS_PROJECTILE_SPEED_INCREASE")
				b.levels["PROJECTILE_SPEED"] += 1
				_update_special_currency_labels()
	barracks[barracks_selected_index] = b


	var saved_menu_pos = _inspect_screen_pos()


	keep_barracks_menu_open = true
	_reopen_barracks_menu_immediately(saved_menu_pos)

func _reopen_barracks_menu_immediately(menu_pos: Vector2) -> void:
	"""Reabre o menu de quartel na mesma posicao apos um upgrade"""
	if not PopupMenuHelper.can_reopen(keep_barracks_menu_open, barracks_selected_index, barracks.size(), choosing_upgrade, game_over):
		keep_barracks_menu_open = false
		return
	call_deferred("_actually_reopen_barracks_menu", menu_pos)

func _actually_reopen_barracks_menu(menu_pos: Vector2) -> void:
	"""Reabre efetivamente o menu barracks apos o fechamento"""
	if not PopupMenuHelper.can_reopen(keep_barracks_menu_open, barracks_selected_index, barracks.size(), choosing_upgrade, game_over):
		keep_barracks_menu_open = false
		return
	_open_barracks_menu(barracks_selected_index, menu_pos)
	keep_barracks_menu_open = false

func _open_sniper_menu(idx: int, screen_pos: Vector2) -> void:
	if sniper_menu == null:
		return
	sniper_selected_index = idx
	var s = sniper_towers[idx]
	_show_range_indicator(s.pos, s.range, Color(1.0, 0.4, 0.4, 0.65))


	var dmg_level = s.levels.get("DMG", 0)
	var rate_level = s.levels.get("RATE", 0)
	var dmg_cost = get_upgrade_cost(_cfg().get_int("SNIPER_DMG_COST"), dmg_level)
	var rate_cost = get_upgrade_cost(_cfg().get_int("SNIPER_RATE_COST"), rate_level)


	var dmg_emerald_cost = get_tower_upgrade_emerald_cost("DMG", dmg_level)
	var rate_emerald_cost = get_tower_upgrade_emerald_cost("RATE", rate_level)


	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}

	var can_dmg: bool = hero["coins"] >= dmg_cost
	var can_rate: bool = hero["coins"] >= rate_cost and s.fire_rate > _cfg().get_float("SNIPER_MIN_FIRE_RATE")
	var can_dmg_emerald: bool = currency_info.emeralds >= dmg_emerald_cost
	var can_rate_emerald: bool = currency_info.emeralds >= rate_emerald_cost and s.fire_rate > _cfg().get_float("SNIPER_MIN_FIRE_RATE")

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
	_present_from_popup(sniper_menu, "Torre Sniper", "Dano %.1f · Cadência %.2f · Alcance %.0f" % [s.damage, s.fire_rate, s.range], s.pos, s.range, "sniper", idx, screen_pos)

func _on_sniper_menu_pressed(id: int) -> void:
	if sniper_selected_index < 0 or sniper_selected_index >= sniper_towers.size():
		return
	var s = sniper_towers[sniper_selected_index]
	var dmg_level = s.levels.get("DMG", 0)
	var rate_level = s.levels.get("RATE", 0)


	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}

	match id:
		1:
			var cost = get_upgrade_cost(_cfg().get_int("SNIPER_DMG_COST"), dmg_level)
			if hero["coins"] >= cost:
				s.damage += 2.0
				s.levels["DMG"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		10:
			var emerald_cost = get_tower_upgrade_emerald_cost("DMG", dmg_level)
			if currency_info.emeralds >= emerald_cost:
				special_currency_manager.spend_emeralds(emerald_cost)
				s.damage += 2.0
				s.levels["DMG"] += 1
				_update_special_currency_labels()
		2:
			var cost = get_upgrade_cost(_cfg().get_int("SNIPER_RATE_COST"), rate_level)
			if hero["coins"] >= cost and s.fire_rate > _cfg().get_float("SNIPER_MIN_FIRE_RATE"):
				s.fire_rate = max(_cfg().get_float("SNIPER_MIN_FIRE_RATE"), s.fire_rate - _cfg().get_float("SNIPER_FIRE_RATE_REDUCTION"))
				s.levels["RATE"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		11:
			var emerald_cost = get_tower_upgrade_emerald_cost("RATE", rate_level)
			if currency_info.emeralds >= emerald_cost and s.fire_rate > _cfg().get_float("SNIPER_MIN_FIRE_RATE"):
				special_currency_manager.spend_emeralds(emerald_cost)
				s.fire_rate = max(_cfg().get_float("SNIPER_MIN_FIRE_RATE"), s.fire_rate - _cfg().get_float("SNIPER_FIRE_RATE_REDUCTION"))
				s.levels["RATE"] += 1
				_update_special_currency_labels()
		3:
			s["target_mode"] = 0
		4:
			s["target_mode"] = 1
	sniper_towers[sniper_selected_index] = s


	var saved_menu_pos = _inspect_screen_pos()


	keep_sniper_menu_open = true
	_reopen_sniper_menu_immediately(saved_menu_pos)

func _reopen_sniper_menu_immediately(menu_pos: Vector2) -> void:
	"""Reabre o menu sniper na mesma posicao apos um upgrade"""
	if not PopupMenuHelper.can_reopen(keep_sniper_menu_open, sniper_selected_index, sniper_towers.size(), choosing_upgrade, game_over):
		keep_sniper_menu_open = false
		return
	call_deferred("_actually_reopen_sniper_menu", menu_pos)

func _actually_reopen_sniper_menu(menu_pos: Vector2) -> void:
	"""Reabre efetivamente o menu sniper apos o fechamento"""
	if not PopupMenuHelper.can_reopen(keep_sniper_menu_open, sniper_selected_index, sniper_towers.size(), choosing_upgrade, game_over):
		keep_sniper_menu_open = false
		return
	_open_sniper_menu(sniper_selected_index, menu_pos)
	keep_sniper_menu_open = false

func _open_aoe_menu(idx: int, screen_pos: Vector2) -> void:
	if aoe_menu == null:
		return
	aoe_selected_index = idx
	var a = aoe_towers[idx]
	_show_range_indicator(a.pos, a.range, Color(1.0, 0.8, 0.3, 0.65))


	var dmg_level = a.levels.get("DMG", 0)
	var rate_level = a.levels.get("RATE", 0)
	var area_level = a.levels.get("AREA", 0)
	var dmg_cost = get_upgrade_cost(_cfg().get_int("AOE_DMG_COST"), dmg_level)
	var rate_cost = get_upgrade_cost(_cfg().get_int("AOE_RATE_COST"), rate_level)

	var area_cost = int(_cfg().get_int("AOE_AREA_COST") * pow(_cfg().get_float("AOE_AREA_COST_MULTIPLIER"), area_level))


	var dmg_emerald_cost = get_tower_upgrade_emerald_cost("DMG", dmg_level)
	var rate_emerald_cost = get_tower_upgrade_emerald_cost("RATE", rate_level)
	var area_emerald_cost = get_tower_upgrade_emerald_cost("AREA", area_level)


	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}

	var can_dmg: bool = hero["coins"] >= dmg_cost
	var can_rate: bool = hero["coins"] >= rate_cost and a.fire_rate > _cfg().get_float("AOE_MIN_FIRE_RATE")
	var can_area: bool = hero["coins"] >= area_cost and a.aoe_radius < _cfg().get_float("AOE_MAX_RADIUS")
	var can_dmg_emerald: bool = currency_info.emeralds >= dmg_emerald_cost
	var can_rate_emerald: bool = currency_info.emeralds >= rate_emerald_cost and a.fire_rate > _cfg().get_float("AOE_MIN_FIRE_RATE")
	var can_area_emerald: bool = currency_info.emeralds >= area_emerald_cost and a.aoe_radius < _cfg().get_float("AOE_MAX_RADIUS")

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
	_present_from_popup(aoe_menu, "Canhão", "Dano %.1f · Área %.0f · Alcance %.0f" % [a.damage, a.aoe_radius, a.range], a.pos, a.range, "aoe", idx, screen_pos)

func _on_aoe_menu_pressed(id: int) -> void:
	if aoe_selected_index < 0 or aoe_selected_index >= aoe_towers.size():
		return
	var a = aoe_towers[aoe_selected_index]
	var dmg_level = a.levels.get("DMG", 0)
	var rate_level = a.levels.get("RATE", 0)
	var area_level = a.levels.get("AREA", 0)


	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}

	match id:
		1:
			var cost = get_upgrade_cost(_cfg().get_int("AOE_DMG_COST"), dmg_level)
			if hero["coins"] >= cost:
				a.damage += 1.0
				a.levels["DMG"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		10:
			var emerald_cost = get_tower_upgrade_emerald_cost("DMG", dmg_level)
			if currency_info.emeralds >= emerald_cost:
				special_currency_manager.spend_emeralds(emerald_cost)
				a.damage += 1.0
				a.levels["DMG"] += 1
				_update_special_currency_labels()
		2:
			var cost = get_upgrade_cost(_cfg().get_int("AOE_RATE_COST"), rate_level)
			if hero["coins"] >= cost and a.fire_rate > _cfg().get_float("AOE_MIN_FIRE_RATE"):
				a.fire_rate = max(_cfg().get_float("AOE_MIN_FIRE_RATE"), a.fire_rate - _cfg().get_float("AOE_FIRE_RATE_REDUCTION"))
				a.levels["RATE"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		11:
			var emerald_cost = get_tower_upgrade_emerald_cost("RATE", rate_level)
			if currency_info.emeralds >= emerald_cost and a.fire_rate > _cfg().get_float("AOE_MIN_FIRE_RATE"):
				special_currency_manager.spend_emeralds(emerald_cost)
				a.fire_rate = max(_cfg().get_float("AOE_MIN_FIRE_RATE"), a.fire_rate - _cfg().get_float("AOE_FIRE_RATE_REDUCTION"))
				a.levels["RATE"] += 1
				_update_special_currency_labels()
		3:

			var cost = int(_cfg().get_int("AOE_AREA_COST") * pow(_cfg().get_float("AOE_AREA_COST_MULTIPLIER"), area_level))
			if hero["coins"] >= cost and a.aoe_radius < _cfg().get_float("AOE_MAX_RADIUS"):
				a.aoe_radius = min(_cfg().get_float("AOE_MAX_RADIUS"), a.aoe_radius + 20.0)
				a.levels["AREA"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		12:
			var emerald_cost = get_tower_upgrade_emerald_cost("AREA", area_level)
			if currency_info.emeralds >= emerald_cost and a.aoe_radius < _cfg().get_float("AOE_MAX_RADIUS"):
				special_currency_manager.spend_emeralds(emerald_cost)
				a.aoe_radius = min(_cfg().get_float("AOE_MAX_RADIUS"), a.aoe_radius + 20.0)
				a.levels["AREA"] += 1
				_update_special_currency_labels()
	aoe_towers[aoe_selected_index] = a


	var saved_menu_pos = _inspect_screen_pos()


	keep_aoe_menu_open = true
	_reopen_aoe_menu_immediately(saved_menu_pos)

func _reopen_aoe_menu_immediately(menu_pos: Vector2) -> void:
	"""Reabre o menu aoe na mesma posicao apos um upgrade"""
	if not PopupMenuHelper.can_reopen(keep_aoe_menu_open, aoe_selected_index, aoe_towers.size(), choosing_upgrade, game_over):
		keep_aoe_menu_open = false
		return
	call_deferred("_actually_reopen_aoe_menu", menu_pos)

func _actually_reopen_aoe_menu(menu_pos: Vector2) -> void:
	"""Reabre efetivamente o menu aoe apos o fechamento"""
	if not PopupMenuHelper.can_reopen(keep_aoe_menu_open, aoe_selected_index, aoe_towers.size(), choosing_upgrade, game_over):
		keep_aoe_menu_open = false
		return
	_open_aoe_menu(aoe_selected_index, menu_pos)
	keep_aoe_menu_open = false

func _open_anti_air_menu(idx: int, screen_pos: Vector2) -> void:
	if anti_air_menu == null:
		return
	anti_air_selected_index = idx
	var aa = anti_air_towers[idx]
	_show_range_indicator(aa.pos, aa.range, Color(0.2, 0.6, 0.9, 0.65))


	var dmg_level = aa.levels.get("DMG", 0)
	var rate_level = aa.levels.get("RATE", 0)
	var range_level = aa.levels.get("RANGE", 0)
	var missile_count_level = aa.levels.get("MISSILE_COUNT", 0)
	var explosion_level = aa.levels.get("EXPLOSION", 0)
	var chain_level = aa.levels.get("CHAIN", 0)

	var dmg_cost = get_upgrade_cost(_cfg().get_int("ANTI_AIR_DMG_COST"), dmg_level)
	var rate_cost = get_upgrade_cost(_cfg().get_int("ANTI_AIR_RATE_COST"), rate_level)
	var range_cost = get_upgrade_cost(_cfg().get_int("ANTI_AIR_RANGE_COST"), range_level)
	var chain_cost = get_upgrade_cost(_cfg().get_int("ANTI_AIR_CHAIN_COST"), chain_level)

	var dmg_emerald_cost = get_tower_upgrade_emerald_cost("DMG", dmg_level)
	var rate_emerald_cost = get_tower_upgrade_emerald_cost("RATE", rate_level)
	var range_emerald_cost = get_tower_upgrade_emerald_cost("RANGE", range_level)
	var chain_emerald_cost = get_tower_upgrade_emerald_cost("CHAIN", chain_level)
	var missile_emerald_cost = _cfg().get_int("ANTI_AIR_MISSILE_EMERALD_COST")
	var explosion_emerald_cost = _cfg().get_int("ANTI_AIR_EXPLOSION_EMERALD_COST")

	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}

	var anti_air_max_range = _cfg().get_float("ANTI_AIR_MAX_RANGE")
	var can_dmg: bool = hero["coins"] >= dmg_cost
	var can_rate: bool = hero["coins"] >= rate_cost and aa.fire_rate > _cfg().get_float("ANTI_AIR_MIN_FIRE_RATE")
	var aa_base_range: float = aa.get("base_range", 250.0)
	var can_range: bool = hero["coins"] >= range_cost and aa_base_range < anti_air_max_range
	var can_chain: bool = hero["coins"] >= chain_cost and aa.get("chain_targets", 1) < 3

	var can_dmg_emerald: bool = currency_info.emeralds >= dmg_emerald_cost
	var can_rate_emerald: bool = currency_info.emeralds >= rate_emerald_cost and aa.fire_rate > _cfg().get_float("ANTI_AIR_MIN_FIRE_RATE")
	var can_range_emerald: bool = currency_info.emeralds >= range_emerald_cost and aa_base_range < anti_air_max_range
	var can_missile_emerald: bool = currency_info.emeralds >= missile_emerald_cost and aa.get("missile_count", 3) < 4
	var can_explosion_emerald: bool = currency_info.emeralds >= explosion_emerald_cost and explosion_level == 0
	var can_chain_emerald: bool = currency_info.emeralds >= chain_emerald_cost and aa.get("chain_targets", 1) < 3

	anti_air_menu.set_item_text(0, "Dano +1.25 (💰 %d moedas) [%.1f]" % [dmg_cost, aa.damage])
	anti_air_menu.set_item_text(1, "Dano +1.25 (🟢 %d esmeraldas) [%.1f]" % [dmg_emerald_cost, aa.damage])
	anti_air_menu.set_item_text(3, "Taxa de Tiro + (💰 %d moedas) [%.1fs]" % [rate_cost, aa.fire_rate])
	anti_air_menu.set_item_text(4, "Taxa de Tiro + (🟢 %d esmeraldas) [%.1fs]" % [rate_emerald_cost, aa.fire_rate])
	anti_air_menu.set_item_text(6, "Alcance +10%% (💰 %d moedas) [%.0f]" % [range_cost, aa.range])
	anti_air_menu.set_item_text(7, "Alcance +10%% (🟢 %d esmeraldas) [%.0f]" % [range_emerald_cost, aa.range])
	anti_air_menu.set_item_text(9, "Mísseis +1 (🟢 %d esmeraldas) [%d]" % [missile_emerald_cost, aa.get("missile_count", 3)])
	anti_air_menu.set_item_text(11, "Explosão em Área (🟢 %d esmeraldas)" % explosion_emerald_cost + (" ✓" if explosion_level > 0 else ""))
	anti_air_menu.set_item_text(13, "Corrente de Alvos +1 (💰 %d moedas) [%d]" % [chain_cost, aa.get("chain_targets", 1)])
	anti_air_menu.set_item_text(14, "Corrente de Alvos +1 (🟢 %d esmeraldas) [%d]" % [chain_emerald_cost, aa.get("chain_targets", 1)])

	anti_air_menu.set_item_disabled(0, not can_dmg)
	anti_air_menu.set_item_disabled(1, not can_dmg_emerald)
	anti_air_menu.set_item_disabled(3, not can_rate)
	anti_air_menu.set_item_disabled(4, not can_rate_emerald)
	anti_air_menu.set_item_disabled(6, not can_range)
	anti_air_menu.set_item_disabled(7, not can_range_emerald)
	anti_air_menu.set_item_disabled(9, not can_missile_emerald)
	anti_air_menu.set_item_disabled(11, not can_explosion_emerald)
	anti_air_menu.set_item_disabled(13, not can_chain)
	anti_air_menu.set_item_disabled(14, not can_chain_emerald)

	anti_air_menu.position = screen_pos
	_present_from_popup(anti_air_menu, "Anti-Aéreo", "Dano %.1f · Mísseis %d · Alcance %.0f" % [aa.damage, aa.get("missile_count", 3), aa.range], aa.pos, aa.range, "anti_air", idx, screen_pos)

func _on_anti_air_menu_pressed(id: int) -> void:
	if anti_air_selected_index < 0 or anti_air_selected_index >= anti_air_towers.size():
		return
	var aa = anti_air_towers[anti_air_selected_index]
	var dmg_level = aa.levels.get("DMG", 0)
	var rate_level = aa.levels.get("RATE", 0)
	var range_level = aa.levels.get("RANGE", 0)
	var missile_count_level = aa.levels.get("MISSILE_COUNT", 0)
	var explosion_level = aa.levels.get("EXPLOSION", 0)
	var chain_level = aa.levels.get("CHAIN", 0)


	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}

	match id:
		1:
			var cost = get_upgrade_cost(_cfg().get_int("ANTI_AIR_DMG_COST"), dmg_level)
			if hero["coins"] >= cost:
				aa.damage += 1.25
				aa.levels["DMG"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		10:
			var emerald_cost = get_tower_upgrade_emerald_cost("DMG", dmg_level)
			if currency_info.emeralds >= emerald_cost:
				special_currency_manager.spend_emeralds(emerald_cost)
				aa.damage += 1.25
				aa.levels["DMG"] += 1
				_update_special_currency_labels()
		2:
			var cost = get_upgrade_cost(_cfg().get_int("ANTI_AIR_RATE_COST"), rate_level)
			if hero["coins"] >= cost and aa.fire_rate > _cfg().get_float("ANTI_AIR_MIN_FIRE_RATE"):
				aa.fire_rate = max(_cfg().get_float("ANTI_AIR_MIN_FIRE_RATE"), aa.fire_rate - _cfg().get_float("ANTI_AIR_FIRE_RATE_REDUCTION"))
				aa.levels["RATE"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		11:
			var emerald_cost = get_tower_upgrade_emerald_cost("RATE", rate_level)
			if currency_info.emeralds >= emerald_cost and aa.fire_rate > _cfg().get_float("ANTI_AIR_MIN_FIRE_RATE"):
				special_currency_manager.spend_emeralds(emerald_cost)
				aa.fire_rate = max(_cfg().get_float("ANTI_AIR_MIN_FIRE_RATE"), aa.fire_rate - _cfg().get_float("ANTI_AIR_FIRE_RATE_REDUCTION"))
				aa.levels["RATE"] += 1
				_update_special_currency_labels()
		3:
			var cost = get_upgrade_cost(_cfg().get_int("ANTI_AIR_RANGE_COST"), range_level)
			var anti_air_max_range = _cfg().get_float("ANTI_AIR_MAX_RANGE")
			if hero["coins"] >= cost and aa.get("base_range", 250.0) < anti_air_max_range:
				aa.base_range = min(aa.base_range * 1.1, anti_air_max_range)
				aa.range = aa.base_range * global_tower_range_boost
				aa.levels["RANGE"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		12:
			var emerald_cost = get_tower_upgrade_emerald_cost("RANGE", range_level)
			var anti_air_max_range = _cfg().get_float("ANTI_AIR_MAX_RANGE")
			if currency_info.emeralds >= emerald_cost and aa.get("base_range", 250.0) < anti_air_max_range:
				special_currency_manager.spend_emeralds(emerald_cost)
				aa.base_range = min(aa.base_range * 1.1, anti_air_max_range)
				aa.range = aa.base_range * global_tower_range_boost
				aa.levels["RANGE"] += 1
				_update_special_currency_labels()
		13:
			var emerald_cost = _cfg().get_int("ANTI_AIR_MISSILE_EMERALD_COST")
			if currency_info.emeralds >= emerald_cost and aa.get("missile_count", 3) < 4:
				special_currency_manager.spend_emeralds(emerald_cost)
				aa["missile_count"] = aa.get("missile_count", 3) + 1
				aa.levels["MISSILE_COUNT"] += 1
				_update_special_currency_labels()
		14:
			var emerald_cost = _cfg().get_int("ANTI_AIR_EXPLOSION_EMERALD_COST")
			if currency_info.emeralds >= emerald_cost and explosion_level == 0:
				special_currency_manager.spend_emeralds(emerald_cost)
				aa["explosion_radius"] = 30.0
				aa.levels["EXPLOSION"] += 1
				_update_special_currency_labels()
		6:
			var cost = get_upgrade_cost(_cfg().get_int("ANTI_AIR_CHAIN_COST"), chain_level)
			if hero["coins"] >= cost and aa.get("chain_targets", 1) < 3:
				aa["chain_targets"] = aa.get("chain_targets", 1) + 1
				aa.levels["CHAIN"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		15:
			var emerald_cost = get_tower_upgrade_emerald_cost("CHAIN", chain_level)
			if currency_info.emeralds >= emerald_cost and aa.get("chain_targets", 1) < 3:
				special_currency_manager.spend_emeralds(emerald_cost)
				aa["chain_targets"] = aa.get("chain_targets", 1) + 1
				aa.levels["CHAIN"] += 1
				_update_special_currency_labels()
	anti_air_towers[anti_air_selected_index] = aa


	var saved_menu_pos = _inspect_screen_pos()


	keep_anti_air_menu_open = true
	_reopen_anti_air_menu_immediately(saved_menu_pos)

func _reopen_anti_air_menu_immediately(menu_pos: Vector2) -> void:
	"""Reabre o menu antiaerea na mesma posicao apos um upgrade"""
	if not PopupMenuHelper.can_reopen(keep_anti_air_menu_open, anti_air_selected_index, anti_air_towers.size(), choosing_upgrade, game_over):
		keep_anti_air_menu_open = false
		return
	call_deferred("_actually_reopen_anti_air_menu", menu_pos)

func _actually_reopen_anti_air_menu(menu_pos: Vector2) -> void:
	"""Reabre efetivamente o menu antiaerea apos o fechamento"""
	if not PopupMenuHelper.can_reopen(keep_anti_air_menu_open, anti_air_selected_index, anti_air_towers.size(), choosing_upgrade, game_over):
		keep_anti_air_menu_open = false
		return
	_open_anti_air_menu(anti_air_selected_index, menu_pos)
	keep_anti_air_menu_open = false

func _open_shock_menu(idx: int, screen_pos: Vector2) -> void:
	if shock_menu == null:
		return
	shock_selected_index = idx
	var s = shock_towers[idx]
	_show_range_indicator(s.pos, s.range, Color(0.9, 0.5, 1.0, 0.65))


	var dmg_level = s.levels.get("DMG", 0)
	var rate_level = s.levels.get("RATE", 0)
	var chain_level = s.levels.get("CHAIN", 0)
	var dmg_cost = get_upgrade_cost(_cfg().get_int("SHOCK_DMG_COST"), dmg_level)
	var rate_cost = get_upgrade_cost(_cfg().get_int("SHOCK_RATE_COST"), rate_level)

	var base_chain_cost = _cfg().get_int("SHOCK_CHAIN_COST")
	var chain_cost = int(base_chain_cost * pow(_cfg().get_float("SHOCK_CHAIN_COST_MULTIPLIER"), chain_level))


	var dmg_emerald_cost = get_tower_upgrade_emerald_cost("DMG", dmg_level)
	var rate_emerald_cost = get_tower_upgrade_emerald_cost("RATE", rate_level)
	var chain_emerald_cost = get_tower_upgrade_emerald_cost("CHAIN", chain_level)


	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}

	var can_dmg: bool = hero["coins"] >= dmg_cost
	var can_rate: bool = hero["coins"] >= rate_cost and s.fire_rate > _cfg().get_float("SHOCK_MIN_FIRE_RATE")
	var can_chain: bool = hero["coins"] >= chain_cost and s.chain_count < _cfg().get_int("SHOCK_MAX_CHAIN_COUNT")
	var can_dmg_emerald: bool = currency_info.emeralds >= dmg_emerald_cost
	var can_rate_emerald: bool = currency_info.emeralds >= rate_emerald_cost and s.fire_rate > _cfg().get_float("SHOCK_MIN_FIRE_RATE")
	var can_chain_emerald: bool = currency_info.emeralds >= chain_emerald_cost and s.chain_count < _cfg().get_int("SHOCK_MAX_CHAIN_COUNT")

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
	_present_from_popup(shock_menu, "Torre de Choque", "Dano %.1f · Correntes %d · Alcance %.0f" % [s.damage, s.get("chain_count", 1), s.range], s.pos, s.range, "shock", idx, screen_pos)

func _on_shock_menu_pressed(id: int) -> void:
	if shock_selected_index < 0 or shock_selected_index >= shock_towers.size():
		return
	var s = shock_towers[shock_selected_index]
	var dmg_level = s.levels.get("DMG", 0)
	var rate_level = s.levels.get("RATE", 0)
	var chain_level = s.levels.get("CHAIN", 0)


	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}

	match id:
		1:
			var cost = get_upgrade_cost(_cfg().get_int("SHOCK_DMG_COST"), dmg_level)
			if hero["coins"] >= cost:
				s.damage += 0.5
				s.levels["DMG"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		10:
			var emerald_cost = get_tower_upgrade_emerald_cost("DMG", dmg_level)
			if currency_info.emeralds >= emerald_cost:
				special_currency_manager.spend_emeralds(emerald_cost)
				s.damage += 0.5
				s.levels["DMG"] += 1
				_update_special_currency_labels()
		2:
			var cost = get_upgrade_cost(_cfg().get_int("SHOCK_RATE_COST"), rate_level)
			if hero["coins"] >= cost and s.fire_rate > _cfg().get_float("SHOCK_MIN_FIRE_RATE"):
				s.fire_rate = max(_cfg().get_float("SHOCK_MIN_FIRE_RATE"), s.fire_rate - _cfg().get_float("SHOCK_FIRE_RATE_REDUCTION"))
				s.levels["RATE"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		11:
			var emerald_cost = get_tower_upgrade_emerald_cost("RATE", rate_level)
			if currency_info.emeralds >= emerald_cost and s.fire_rate > _cfg().get_float("SHOCK_MIN_FIRE_RATE"):
				special_currency_manager.spend_emeralds(emerald_cost)
				s.fire_rate = max(_cfg().get_float("SHOCK_MIN_FIRE_RATE"), s.fire_rate - _cfg().get_float("SHOCK_FIRE_RATE_REDUCTION"))
				s.levels["RATE"] += 1
				_update_special_currency_labels()
		3:

			var base_chain_cost = _cfg().get_int("SHOCK_CHAIN_COST")
			var cost = int(base_chain_cost * pow(_cfg().get_float("SHOCK_CHAIN_COST_MULTIPLIER"), chain_level))
			if hero["coins"] >= cost and s.chain_count < _cfg().get_int("SHOCK_MAX_CHAIN_COUNT"):
				s.chain_count = min(_cfg().get_int("SHOCK_MAX_CHAIN_COUNT"), s.chain_count + 1)
				s.levels["CHAIN"] += 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		12:
			var emerald_cost = get_tower_upgrade_emerald_cost("CHAIN", chain_level)
			if currency_info.emeralds >= emerald_cost and s.chain_count < _cfg().get_int("SHOCK_MAX_CHAIN_COUNT"):
				special_currency_manager.spend_emeralds(emerald_cost)
				s.chain_count = min(_cfg().get_int("SHOCK_MAX_CHAIN_COUNT"), s.chain_count + 1)
				s.levels["CHAIN"] += 1
				_update_special_currency_labels()
	shock_towers[shock_selected_index] = s


	var saved_menu_pos = shock_menu.position if shock_menu else Vector2.ZERO


	keep_shock_menu_open = true
	_reopen_shock_menu_immediately(saved_menu_pos)

func _reopen_shock_menu_immediately(menu_pos: Vector2) -> void:
	"""Reabre o menu shock na mesma posicao apos um upgrade"""
	if not PopupMenuHelper.can_reopen(keep_shock_menu_open, shock_selected_index, shock_towers.size(), choosing_upgrade, game_over):
		keep_shock_menu_open = false
		return
	call_deferred("_actually_reopen_shock_menu", menu_pos)

func _actually_reopen_shock_menu(menu_pos: Vector2) -> void:
	"""Reabre efetivamente o menu shock apos o fechamento"""
	if not PopupMenuHelper.can_reopen(keep_shock_menu_open, shock_selected_index, shock_towers.size(), choosing_upgrade, game_over):
		keep_shock_menu_open = false
		return
	_open_shock_menu(shock_selected_index, menu_pos)
	keep_shock_menu_open = false

func _open_slow_menu(idx: int, screen_pos: Vector2) -> void:
	if slow_menu == null:
		return
	slow_selected_index = idx
	var s = slow_towers[idx]
	_show_range_indicator(s.pos, s.range, Color(0.4, 1.0, 0.8, 0.65))


	var range_level = s.levels.get("RANGE", 0)
	var amount_level = s.levels.get("AMOUNT", 0)
	var range_cost = get_upgrade_cost(_cfg().get_int("SLOW_RANGE_COST"), range_level)
	var amount_cost = get_upgrade_cost(_cfg().get_int("SLOW_AMOUNT_COST"), amount_level)


	var range_emerald_cost = get_tower_upgrade_emerald_cost("RANGE", range_level)
	var amount_emerald_cost = get_tower_upgrade_emerald_cost("AMOUNT", amount_level)


	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}

	var can_range: bool = hero["coins"] >= range_cost and s.range < 250.0
	var can_amount: bool = hero["coins"] >= amount_cost and s.slow_amount < 0.5
	var can_range_emerald: bool = currency_info.emeralds >= range_emerald_cost and s.range < 250.0
	var can_amount_emerald: bool = currency_info.emeralds >= amount_emerald_cost and s.slow_amount < 0.5


	slow_menu.set_item_text(0, "Alcance +30 (💰 %d moedas) [%.0f/222250]" % [range_cost, s.range])
	slow_menu.set_item_text(1, "Alcance +30 (🟢 %d esmeraldas) [%.0f/250]" % [range_emerald_cost, s.range])
	slow_menu.set_item_text(3, "Slow x1.05 (💰 %d moedas) [%.0f%%/50%%]" % [amount_cost, s.slow_amount * 100])
	slow_menu.set_item_text(4, "Slow x1.05 (🟢 %d esmeraldas) [%.0f%%/50%%]" % [amount_emerald_cost, s.slow_amount * 100])
	slow_menu.set_item_disabled(0, not can_range)
	slow_menu.set_item_disabled(1, not can_range_emerald)
	slow_menu.set_item_disabled(3, not can_amount)
	slow_menu.set_item_disabled(4, not can_amount_emerald)
	slow_menu.position = screen_pos
	var slow_duration: float = float(s.get("slow_duration", 1.0))
	_present_from_popup(slow_menu, "Torre de Congelamento", "Slow %.0f%% · Duração %.1fs · Alcance %.0f" % [s.slow_amount * 100.0, slow_duration, s.range], s.pos, s.range, "slow", idx, screen_pos)

func _on_slow_menu_pressed(id: int) -> void:
	if slow_selected_index < 0 or slow_selected_index >= slow_towers.size():
		return
	var s = slow_towers[slow_selected_index]
	var range_level = s.levels.get("RANGE", 0)
	var amount_level = s.levels.get("AMOUNT", 0)



	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}

	match id:
		1:
			var cost = get_upgrade_cost(_cfg().get_int("SLOW_RANGE_COST"), range_level)
			if hero["coins"] >= cost and s.range < 250.0:
				s.range = min(250.0, s.range + 30.0)
				s.levels["RANGE"] = s.levels.get("RANGE", 0) + 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		10:
			var emerald_cost = get_tower_upgrade_emerald_cost("RANGE", range_level)
			if currency_info.emeralds >= emerald_cost and s.range < 250.0:
				special_currency_manager.spend_emeralds(emerald_cost)
				s.range = min(250.0, s.range + 30.0)
				s.levels["RANGE"] = s.levels.get("RANGE", 0) + 1
				_update_special_currency_labels()
		2:
			var cost = get_upgrade_cost(_cfg().get_int("SLOW_AMOUNT_COST"), amount_level)
			if hero["coins"] >= cost and s.slow_amount < 0.5:

				s.slow_amount = min(0.5, s.slow_amount * 1.05)
				s.levels["AMOUNT"] = s.levels.get("AMOUNT", 0) + 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		11:
			var emerald_cost = get_tower_upgrade_emerald_cost("AMOUNT", amount_level)
			if currency_info.emeralds >= emerald_cost and s.slow_amount < 0.5:
				special_currency_manager.spend_emeralds(emerald_cost)
				s.slow_amount = min(0.5, s.slow_amount * 1.05)
				s.levels["AMOUNT"] = s.levels.get("AMOUNT", 0) + 1
				_update_special_currency_labels()


	slow_towers[slow_selected_index] = s


	var saved_menu_pos = _inspect_screen_pos()


	keep_slow_menu_open = true
	_reopen_slow_menu_immediately(saved_menu_pos)

func _reopen_slow_menu_immediately(menu_pos: Vector2) -> void:
	"""Reabre o menu slow na mesma posicao apos um upgrade"""
	if not PopupMenuHelper.can_reopen(keep_slow_menu_open, slow_selected_index, slow_towers.size(), choosing_upgrade, game_over):
		keep_slow_menu_open = false
		return
	call_deferred("_actually_reopen_slow_menu", menu_pos)

func _actually_reopen_slow_menu(menu_pos: Vector2) -> void:
	"""Reabre efetivamente o menu slow apos o fechamento"""
	if not PopupMenuHelper.can_reopen(keep_slow_menu_open, slow_selected_index, slow_towers.size(), choosing_upgrade, game_over):
		keep_slow_menu_open = false
		return
	_open_slow_menu(slow_selected_index, menu_pos)
	keep_slow_menu_open = false

func _open_boost_menu(idx: int, screen_pos: Vector2) -> void:
	if boost_menu == null:
		return
	boost_selected_index = idx
	var b = boost_towers[idx]




	var dmg_level = b.levels.get("DMG", 0)
	var rate_level = b.levels.get("RATE", 0)

	var dmg_cost = int(_cfg().get_int("BOOST_DMG_COST") * pow(1.25, dmg_level))
	var rate_cost = get_upgrade_cost(_cfg().get_int("BOOST_RATE_COST"), rate_level)


	var dmg_emerald_cost = get_tower_upgrade_emerald_cost("DMG", dmg_level)
	var rate_emerald_cost = get_tower_upgrade_emerald_cost("RATE", rate_level)


	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}

	var can_dmg: bool = hero["coins"] >= dmg_cost and b.damage_boost < 1.0
	var can_rate: bool = hero["coins"] >= rate_cost and b.rate_boost < 1.0
	var can_dmg_emerald: bool = currency_info.emeralds >= dmg_emerald_cost and b.damage_boost < 1.0
	var can_rate_emerald: bool = currency_info.emeralds >= rate_emerald_cost and b.rate_boost < 1.0


	boost_menu.set_item_text(0, "Boost Dano +5%% (💰 %d moedas) [%.0f%%]" % [dmg_cost, b.damage_boost * 100])
	boost_menu.set_item_text(1, "Boost Dano +5%% (🟢 %d esmeraldas) [%.0f%%]" % [dmg_emerald_cost, b.damage_boost * 100])
	boost_menu.set_item_text(3, "Boost Cadência +5%% (💰 %d moedas) [%.0f%%]" % [rate_cost, b.rate_boost * 100])
	boost_menu.set_item_text(4, "Boost Cadência +5%% (🟢 %d esmeraldas) [%.0f%%]" % [rate_emerald_cost, b.rate_boost * 100])
	boost_menu.set_item_disabled(0, not can_dmg)
	boost_menu.set_item_disabled(1, not can_dmg_emerald)
	boost_menu.set_item_disabled(3, not can_rate)
	boost_menu.set_item_disabled(4, not can_rate_emerald)
	boost_menu.position = screen_pos
	_present_from_popup(boost_menu, "Altar de Melhoria", "Dano +%.0f%% · Cadência +%.0f%% · Alcance %.0f" % [b.get("damage_boost", 0.0) * 100.0, b.rate_boost * 100.0, b.range], b.pos, b.range, "boost", idx, screen_pos)

func _on_boost_menu_pressed(id: int) -> void:
	if boost_selected_index < 0 or boost_selected_index >= boost_towers.size():
		return
	var b = boost_towers[boost_selected_index]
	var dmg_level = b.levels.get("DMG", 0)
	var rate_level = b.levels.get("RATE", 0)


	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}

	match id:
		1:

			var cost = int(_cfg().get_int("BOOST_DMG_COST") * pow(1.25, dmg_level))
			if hero["coins"] >= cost and b.damage_boost < 1.0:
				b.damage_boost = min(1.0, b.damage_boost + 0.05)
				b.levels["DMG"] = b.levels.get("DMG", 0) + 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		10:
			var emerald_cost = get_tower_upgrade_emerald_cost("DMG", dmg_level)
			if currency_info.emeralds >= emerald_cost and b.damage_boost < 1.0:
				special_currency_manager.spend_emeralds(emerald_cost)
				b.damage_boost = min(1.0, b.damage_boost + 0.05)
				b.levels["DMG"] = b.levels.get("DMG", 0) + 1
				_update_special_currency_labels()
		2:
			var cost = get_upgrade_cost(_cfg().get_int("BOOST_RATE_COST"), rate_level)
			if hero["coins"] >= cost and b.rate_boost < 1.0:
				b.rate_boost = min(1.0, b.rate_boost + 0.05)
				b.levels["RATE"] = b.levels.get("RATE", 0) + 1
				hero["coins"] -= cost
				_track_coin_spent(cost)
		11:
			var emerald_cost = get_tower_upgrade_emerald_cost("RATE", rate_level)
			if currency_info.emeralds >= emerald_cost and b.rate_boost < 1.0:
				special_currency_manager.spend_emeralds(emerald_cost)
				b.rate_boost = min(1.0, b.rate_boost + 0.05)
				b.levels["RATE"] = b.levels.get("RATE", 0) + 1
				_update_special_currency_labels()
	boost_towers[boost_selected_index] = b


	var saved_menu_pos = _inspect_screen_pos()


	keep_boost_menu_open = true
	_reopen_boost_menu_immediately(saved_menu_pos)

func _reopen_boost_menu_immediately(menu_pos: Vector2) -> void:
	"""Reabre o menu boost na mesma posicao apos um upgrade"""
	if not PopupMenuHelper.can_reopen(keep_boost_menu_open, boost_selected_index, boost_towers.size(), choosing_upgrade, game_over):
		keep_boost_menu_open = false
		return
	call_deferred("_actually_reopen_boost_menu", menu_pos)

func _actually_reopen_boost_menu(menu_pos: Vector2) -> void:
	"""Reabre efetivamente o menu boost apos o fechamento"""
	if not PopupMenuHelper.can_reopen(keep_boost_menu_open, boost_selected_index, boost_towers.size(), choosing_upgrade, game_over):
		keep_boost_menu_open = false
		return
	_open_boost_menu(boost_selected_index, menu_pos)
	keep_boost_menu_open = false

func _is_inside_base_point(p: Vector2) -> bool:
	return grid_manager.is_inside_base_point(p)

func _try_place_tower(pos: Vector2) -> void:
	_try_place_base_structure("tower", pos)

func _try_place_barracks(pos: Vector2) -> void:
	_try_place_base_structure("barracks", pos)

func _on_buy_mine() -> void:
	_begin_placing("mine")

func _is_on_path(world_pos: Vector2) -> bool:

	var tile_col = int(floor(world_pos.x / _cfg().get_int("TILE_SIZE")))
	var tile_row = int(floor(world_pos.y / _cfg().get_int("TILE_SIZE")))


	if tile_row < 0 or tile_row >= _cfg().get_int("GRID_ROWS") or tile_col < 0 or tile_col >= _cfg().get_int("GRID_COLS"):
		return false


	if grid_manager.grid.size() > tile_row and grid_manager.grid[tile_row].size() > tile_col:
		return grid_manager.grid[tile_row][tile_col] == 0
	return false

func _is_in_center_area(world_pos: Vector2) -> bool:

	var center_pos = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
	var dist = world_pos.distance_to(center_pos)
	var center_radius = _cfg().get_int("TILE_SIZE") * 2.0
	return dist < center_radius

func _world_to_tile_coords(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / _cfg().get_int("TILE_SIZE"))),
		int(floor(world_pos.y / _cfg().get_int("TILE_SIZE")))
	)

func _is_tile_within_bounds(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.x < _cfg().get_int("GRID_COLS") and tile.y >= 0 and tile.y < _cfg().get_int("GRID_ROWS")

func _is_walkable_tile(tile: Vector2i) -> bool:
	if not _is_tile_within_bounds(tile):
		return false
	if grid_manager.grid.size() <= tile.y or grid_manager.grid[tile.y].size() <= tile.x:
		return false
	return grid_manager.grid[tile.y][tile.x] == 0

func _mine_tile_key(tile: Vector2i) -> String:
	return TileOccupancy.key(tile)

func _is_mine_tile_occupied(tile: Vector2i) -> bool:
	return TileOccupancy.is_occupied(mine_tiles, tile)

func _register_mine_tile(tile: Vector2i) -> void:
	TileOccupancy.register(mine_tiles, tile)

func _unregister_mine_tile(tile: Vector2i) -> void:
	TileOccupancy.unregister(mine_tiles, tile)

func _wall_tile_key(tile: Vector2i) -> String:
	return TileOccupancy.key(tile)

func _is_wall_tile_occupied(tile: Vector2i) -> bool:
	return TileOccupancy.is_occupied(wall_tiles, tile)

func _register_wall_tile(tile: Vector2i) -> void:
	TileOccupancy.register(wall_tiles, tile)

func _unregister_wall_tile(tile: Vector2i) -> void:
	TileOccupancy.unregister(wall_tiles, tile)


func _rebuild_mine_tiles() -> void:
	mine_tiles = TileOccupancy.rebuild_from_structures(mines)

func _try_place_mine(pos: Vector2) -> void:
	if not _can_afford_structure("mine") or mines.size() >= _cfg().get_int("MAX_MINES"):
		placing_mine = false
		return
	if grid_manager.is_inside_base_point(pos):
		_toast_invalid_placement()
		return
	var tile = _world_to_tile_coords(pos)
	if not _is_walkable_tile(tile) or _is_in_center_area(pos) or _is_mine_tile_occupied(tile):
		_toast_invalid_placement()
		return
	var mine_world_pos = grid_manager.tile_center(tile.x, tile.y)
	mines.append(StructureFactory.create("mine", mine_world_pos, tile, _factory_context("mine")))
	_register_mine_tile(tile)
	_spend_structure_cost("mine")
	placing_mine = false

func _on_buy_slow_tower() -> void:
	_begin_placing("slow_tower")

func _try_place_slow_tower(pos: Vector2) -> void:
	_try_place_base_structure("slow_tower", pos)

func _on_buy_aoe_tower() -> void:
	_begin_placing("aoe_tower")

func _try_place_aoe_tower(pos: Vector2) -> void:
	_try_place_base_structure("aoe_tower", pos)

func _on_buy_sniper_tower() -> void:
	_begin_placing("sniper_tower")

func _try_place_sniper_tower(pos: Vector2) -> void:
	_try_place_base_structure("sniper_tower", pos)

func _on_buy_anti_air_tower() -> void:
	_begin_placing("anti_air_tower")

func _try_place_anti_air_tower(pos: Vector2) -> void:
	_try_place_base_structure("anti_air_tower", pos)

func _on_buy_boost_tower() -> void:
	_begin_placing("boost_tower")

func _try_place_boost_tower(pos: Vector2) -> void:
	_try_place_base_structure("boost_tower", pos)

func _on_buy_shock_tower() -> void:
	_begin_placing("shock_tower")

func _try_place_shock_tower(pos: Vector2) -> void:
	_try_place_base_structure("shock_tower", pos)

func _on_buy_wall() -> void:
	_begin_placing("wall")

func _try_place_wall(pos: Vector2) -> void:
	if not _can_afford_structure("wall") or walls.size() >= _cfg().get_int("MAX_WALLS"):
		placing_wall = false
		return
	if grid_manager.is_inside_base_point(pos) or not _is_on_path(pos):
		_toast_invalid_placement()
		return
	var tile = _world_to_tile_coords(pos)
	if _is_wall_tile_occupied(tile):
		_toast_invalid_placement()
		return
	var wall_world_pos = grid_manager.tile_center(tile.x, tile.y)
	walls.append(StructureFactory.create("wall", wall_world_pos, tile, _factory_context("wall")))
	_register_wall_tile(tile)
	grid_manager.set_grid_area(tile.x, tile.y, _cfg().get_int("WALL_SIZE_GRID"), 9)
	pathfinder.invalidate_cache()
	pathfinder.set_wall_tiles(wall_tiles)
	_spend_structure_cost("wall")
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
					if t.x >= 0 and t.x < _cfg().get_int("GRID_COLS") and t.y >= 0 and t.y < _cfg().get_int("GRID_ROWS"):
						pts.append(grid_manager.tile_center(t.x, t.y))
				if not pts.is_empty():
					enemy["path"] = pts
					enemy["path_index"] = 0

func _try_move_wall(wall_idx: int, new_pos: Vector2) -> bool:
	if wall_idx < 0 or wall_idx >= walls.size():
		return false

	var wall = walls[wall_idx]


	var old_tile = Vector2i(wall.grid_x, wall.grid_y)
	_unregister_wall_tile(old_tile)
	grid_manager.clear_grid_area(wall.grid_x, wall.grid_y, _cfg().get_int("WALL_SIZE_GRID"))


	if grid_manager.is_inside_base_point(new_pos):

		_register_wall_tile(old_tile)
		grid_manager.set_grid_area(wall.grid_x, wall.grid_y, _cfg().get_int("WALL_SIZE_GRID"), 9)
		return false


	if not _is_on_path(new_pos):

		_register_wall_tile(old_tile)
		grid_manager.set_grid_area(wall.grid_x, wall.grid_y, _cfg().get_int("WALL_SIZE_GRID"), 9)
		return false

	var new_tile = _world_to_tile_coords(new_pos)
	if _is_wall_tile_occupied(new_tile):

		_register_wall_tile(old_tile)
		grid_manager.set_grid_area(wall.grid_x, wall.grid_y, _cfg().get_int("WALL_SIZE_GRID"), 9)
		return false


	var new_world_pos = grid_manager.tile_center(new_tile.x, new_tile.y)
	wall.pos = new_world_pos
	wall.grid_x = new_tile.x
	wall.grid_y = new_tile.y
	_register_wall_tile(new_tile)

	grid_manager.set_grid_area(new_tile.x, new_tile.y, _cfg().get_int("WALL_SIZE_GRID"), 9)
	pathfinder.invalidate_cache()
	pathfinder.set_wall_tiles(wall_tiles)
	_recalculate_all_enemy_paths()
	return true

func _try_move_mine(mine_idx: int, new_pos: Vector2) -> bool:
	if mine_idx < 0 or mine_idx >= mines.size():
		return false

	var mine = mines[mine_idx]


	var old_tile = Vector2i(int(mine.grid_x), int(mine.grid_y))
	_unregister_mine_tile(old_tile)



	if grid_manager.is_inside_base_point(new_pos):

		_register_mine_tile(old_tile)
		return false

	var new_tile = _world_to_tile_coords(new_pos)
	if not _is_walkable_tile(new_tile):

		_register_mine_tile(old_tile)
		return false

	if _is_in_center_area(new_pos):

		_register_mine_tile(old_tile)
		return false

	if _is_mine_tile_occupied(new_tile):

		_register_mine_tile(old_tile)
		return false


	var new_world_pos = grid_manager.tile_center(new_tile.x, new_tile.y)
	mine.pos = new_world_pos
	mine.grid_x = new_tile.x
	mine.grid_y = new_tile.y
	_register_mine_tile(new_tile)

	mines[mine_idx] = mine
	return true

func _try_move_tower_to_grid(tower_idx: int, new_grid_coord: Vector2i) -> bool:
	return _try_move_structure_to_grid("tower", tower_idx, new_grid_coord)

func _try_move_tower(tower_idx: int, new_pos: Vector2) -> bool:
	return _try_move_structure("tower", tower_idx, new_pos, true)

func _try_move_slow_tower_to_grid(tower_idx: int, new_grid_coord: Vector2i) -> bool:
	return _try_move_structure_to_grid("slow_tower", tower_idx, new_grid_coord)

func _try_move_slow_tower(tower_idx: int, new_pos: Vector2) -> bool:
	return _try_move_structure("slow_tower", tower_idx, new_pos, true)

func _try_move_aoe_tower_to_grid(tower_idx: int, new_grid_coord: Vector2i) -> bool:
	return _try_move_structure_to_grid("aoe_tower", tower_idx, new_grid_coord)

func _try_move_aoe_tower(tower_idx: int, new_pos: Vector2) -> bool:
	return _try_move_structure("aoe_tower", tower_idx, new_pos, true)

func _try_move_sniper_tower_to_grid(tower_idx: int, new_grid_coord: Vector2i) -> bool:
	return _try_move_structure_to_grid("sniper_tower", tower_idx, new_grid_coord)

func _try_move_sniper_tower(tower_idx: int, new_pos: Vector2) -> bool:
	return _try_move_structure("sniper_tower", tower_idx, new_pos, true)

func _try_move_boost_tower_to_grid(tower_idx: int, new_grid_coord: Vector2i) -> bool:
	return _try_move_structure_to_grid("boost_tower", tower_idx, new_grid_coord)

func _try_move_boost_tower(tower_idx: int, new_pos: Vector2) -> bool:
	return _try_move_structure("boost_tower", tower_idx, new_pos, true)

func _try_move_shock_tower_to_grid(tower_idx: int, new_grid_coord: Vector2i) -> bool:
	return _try_move_structure_to_grid("shock_tower", tower_idx, new_grid_coord)

func _try_move_shock_tower(tower_idx: int, new_pos: Vector2) -> bool:
	return _try_move_structure("shock_tower", tower_idx, new_pos, true)

func _try_move_anti_air_tower_to_grid(tower_idx: int, new_grid_coord: Vector2i) -> bool:
	return _try_move_structure_to_grid("anti_air_tower", tower_idx, new_grid_coord)

func _try_move_anti_air_tower(anti_air_idx: int, new_pos: Vector2) -> bool:
	return _try_move_structure("anti_air_tower", anti_air_idx, new_pos, false)

func _try_move_barracks_to_grid(barracks_idx: int, new_grid_coord: Vector2i) -> bool:
	return _try_move_structure_to_grid("barracks", barracks_idx, new_grid_coord)

func _try_move_barracks(barracks_idx: int, new_pos: Vector2) -> bool:
	return _try_move_structure("barracks", barracks_idx, new_pos, true)

func _try_move_market_to_grid(market_idx: int, new_grid_coord: Vector2i) -> bool:
	return _try_move_structure_to_grid("market", market_idx, new_grid_coord)

func _try_move_healing_station_to_grid(station_idx: int, new_grid_coord: Vector2i) -> bool:
	return _try_move_structure_to_grid("healing_station", station_idx, new_grid_coord)

func _on_buy_healing_station() -> void:
	_begin_placing("healing_station")

func _try_place_healing_station(pos: Vector2) -> void:
	_try_place_base_structure("healing_station", pos)

func _on_buy_market() -> void:
	_begin_placing("market")

func _try_place_market(pos: Vector2) -> void:
	_try_place_base_structure("market", pos)

func _open_market_menu(idx: int, screen_pos: Vector2) -> void:
	if market_menu == null:
		market_menu = PopupMenu.new()
		market_menu.id_pressed.connect(_on_market_menu_selected)
		add_child(market_menu)

	market_selected_index = idx
	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}
	var has_emeralds = currency_info.emeralds > 0

	market_menu.clear()

	var heal_text = "Cura Completa (🟢 %d esmeraldas)" % _cfg().get_int("MARKET_ITEM_HEAL_FULL")
	if heal_full_uses_remaining <= 0:
		heal_text += " [Sem usos]"
	else:
		heal_text += " [%d usos restantes]" % heal_full_uses_remaining
	market_menu.add_item(heal_text)
	market_menu.set_item_disabled(0, currency_info.emeralds < _cfg().get_int("MARKET_ITEM_HEAL_FULL") or heal_full_uses_remaining <= 0)

	market_menu.add_separator()


	var tower_boost_text = "+20%% Dano Torres (5 waves) (🟢 %d esmeraldas)" % _cfg().get_int("MARKET_ITEM_TOWER_DAMAGE_BOOST")
	if tower_damage_boost_waves_remaining > 0:
		tower_boost_text += " [%d waves restantes]" % tower_damage_boost_waves_remaining
	market_menu.add_item(tower_boost_text)
	market_menu.set_item_disabled(1, currency_info.emeralds < _cfg().get_int("MARKET_ITEM_TOWER_DAMAGE_BOOST") or tower_damage_boost_waves_remaining > 0)

	var hero_boost_text = "+30%% Dano Herói (5 waves) (🟢 %d esmeraldas)" % _cfg().get_int("MARKET_ITEM_HERO_DAMAGE_BOOST")
	if hero_damage_boost_waves_remaining > 0:
		hero_boost_text += " [%d waves restantes]" % hero_damage_boost_waves_remaining
	market_menu.add_item(hero_boost_text)
	market_menu.set_item_disabled(2, currency_info.emeralds < _cfg().get_int("MARKET_ITEM_HERO_DAMAGE_BOOST") or hero_damage_boost_waves_remaining > 0)

	market_menu.add_separator()

	market_menu.add_item("+5 HP Máximo (🟢 %d esmeraldas)" % _cfg().get_int("MARKET_ITEM_EXTRA_LIFE"))
	market_menu.set_item_disabled(3, currency_info.emeralds < _cfg().get_int("MARKET_ITEM_EXTRA_LIFE"))

	market_menu.add_separator()



	var firerate_text = "+100%% Velocidade de Tiro do Herói (🟢 %d esmeraldas)" % _cfg().get_int("MARKET_ITEM_HERO_FIRERATE_UPGRADE")
	if hero_firerate_upgrade:
		firerate_text += " [Comprado]"
	market_menu.add_item(firerate_text)
	market_menu.set_item_disabled(7, currency_info.emeralds < _cfg().get_int("MARKET_ITEM_HERO_FIRERATE_UPGRADE") or hero_firerate_upgrade)

	var dual_cannon_text = "Canhão Duplo do Herói (🟢 %d esmeraldas)" % _cfg().get_int("MARKET_ITEM_HERO_DUAL_CANNON")
	if hero_dual_cannon:
		dual_cannon_text += " [Comprado]"
	market_menu.add_item(dual_cannon_text)
	market_menu.set_item_disabled(8, currency_info.emeralds < _cfg().get_int("MARKET_ITEM_HERO_DUAL_CANNON") or hero_dual_cannon)

	market_menu.add_separator()
	market_menu.add_item("Fechar")

	market_menu.position = screen_pos
	market_menu.popup()

func _on_market_menu_selected(id: int) -> void:
	if market_selected_index < 0 or market_selected_index >= markets.size():
		return

	var currency_info = special_currency_manager.get_currency_info() if special_currency_manager else {"emeralds": 0}

	print("Market menu item selected: ID = ", id, ", Esmeraldas = ", currency_info.emeralds)

	match id:
		0:
			if currency_info.emeralds >= _cfg().get_int("MARKET_ITEM_HEAL_FULL") and heal_full_uses_remaining > 0:
				special_currency_manager.spend_emeralds(_cfg().get_int("MARKET_ITEM_HEAL_FULL"))



				if base_hp > base_hp_max:
					base_hp_max = base_hp

				if hero_manager and hero_manager.base_hp > base_hp_max:

					var market_bonus = base_hp_max - base_hp_base
					if market_bonus < 0:
						market_bonus = 0
					base_hp_max = hero_manager.base_hp + market_bonus

				base_hp = base_hp_max
				heal_full_uses_remaining -= 1
				if notification_manager:
					notification_manager.show_notification("Herói curado completamente! (%d usos restantes)" % heal_full_uses_remaining, 3.0, NotificationManager.NotificationPosition.TOP_CENTER, Color(0.2, 0.8, 0.3))
		1:
			if currency_info.emeralds >= _cfg().get_int("MARKET_ITEM_TOWER_DAMAGE_BOOST") and tower_damage_boost_waves_remaining <= 0:
				special_currency_manager.spend_emeralds(_cfg().get_int("MARKET_ITEM_TOWER_DAMAGE_BOOST"))
				global_tower_damage_boost = 1.2
				tower_damage_boost_waves_remaining = 5
				if notification_manager:
					notification_manager.show_notification("+20%% Dano Torres por 5 waves!", 3.0, NotificationManager.NotificationPosition.TOP_CENTER, Color(0.8, 0.2, 0.8))
		2:
			if currency_info.emeralds >= _cfg().get_int("MARKET_ITEM_HERO_DAMAGE_BOOST") and hero_damage_boost_waves_remaining <= 0:
				special_currency_manager.spend_emeralds(_cfg().get_int("MARKET_ITEM_HERO_DAMAGE_BOOST"))

				hero_damage_boost_waves_remaining = 5
				if notification_manager:
					notification_manager.show_notification("+30%% Dano Herói por 5 waves!", 3.0, NotificationManager.NotificationPosition.TOP_CENTER, Color(0.8, 0.2, 0.8))
		3:
			if currency_info.emeralds >= _cfg().get_int("MARKET_ITEM_EXTRA_LIFE"):
				special_currency_manager.spend_emeralds(_cfg().get_int("MARKET_ITEM_EXTRA_LIFE"))
				base_hp_max += 5
				base_hp += 5
				if notification_manager:
					notification_manager.show_notification("+5 HP Máximo!", 3.0, NotificationManager.NotificationPosition.TOP_CENTER, Color(0.2, 0.8, 0.3))
		7:
			print("Tentando comprar upgrade de velocidade de tiro. Esmeraldas: ", currency_info.emeralds, ", Custo: ", _cfg().get_int("MARKET_ITEM_HERO_FIRERATE_UPGRADE"), ", Já comprado: ", hero_firerate_upgrade)
			if currency_info.emeralds >= _cfg().get_int("MARKET_ITEM_HERO_FIRERATE_UPGRADE") and not hero_firerate_upgrade:
				special_currency_manager.spend_emeralds(_cfg().get_int("MARKET_ITEM_HERO_FIRERATE_UPGRADE"))
				hero_firerate_upgrade = true

				hero["fire_rate"] = hero["fire_rate"] * 0.5
				hero["fire_rate"] = _clamp_hero_fire_rate_from_bonus(hero["fire_rate"])
				print("Upgrade de velocidade de tiro comprado! Fire rate reduzido em 50% (velocidade +100%)")
				if notification_manager:
					notification_manager.show_notification("Velocidade de Tiro do Herói +100%! (Fire rate reduzido pela metade)", 3.0, NotificationManager.NotificationPosition.TOP_CENTER, Color(0.8, 0.8, 0.2))

				keep_market_menu_open = true
				call_deferred("_reopen_market_menu")
				return
			else:
				print("Não foi possível comprar upgrade de velocidade. Esmeraldas suficientes: ", currency_info.emeralds >= _cfg().get_int("MARKET_ITEM_HERO_FIRERATE_UPGRADE"), ", Já comprado: ", hero_firerate_upgrade)
		8:
			print("Tentando comprar canhão duplo. Esmeraldas: ", currency_info.emeralds, ", Custo: ", _cfg().get_int("MARKET_ITEM_HERO_DUAL_CANNON"), ", Já comprado: ", hero_dual_cannon)
			if currency_info.emeralds >= _cfg().get_int("MARKET_ITEM_HERO_DUAL_CANNON") and not hero_dual_cannon:
				special_currency_manager.spend_emeralds(_cfg().get_int("MARKET_ITEM_HERO_DUAL_CANNON"))
				hero_dual_cannon = true
				print("Canhão duplo comprado!")
				if notification_manager:
					notification_manager.show_notification("Canhão Duplo Desbloqueado! O herói agora atira dois projéteis!", 3.0, NotificationManager.NotificationPosition.TOP_CENTER, Color(0.8, 0.2, 0.8))

				keep_market_menu_open = true
				call_deferred("_reopen_market_menu")
				return
			else:
				print("Não foi possível comprar canhão duplo. Esmeraldas suficientes: ", currency_info.emeralds >= _cfg().get_int("MARKET_ITEM_HERO_DUAL_CANNON"), ", Já comprado: ", hero_dual_cannon)
		_:

			pass


	if id != 7 and id != 8:
		keep_market_menu_open = false
		if market_menu:
			market_menu.hide()

func _reopen_market_menu() -> void:
	"""Reabre o menu do Market após uma compra para atualizar a UI"""
	if market_selected_index >= 0 and market_selected_index < markets.size() and market_menu:
		var menu_pos_vec2i = market_menu.position
		var menu_pos = Vector2(menu_pos_vec2i) if menu_pos_vec2i != Vector2i.ZERO else Vector2(100, 100)
		_open_market_menu(market_selected_index, menu_pos)

func _physics_process(delta: float) -> void:
	# Grid do spatial hash já foi atualizado em _process; referência de inimigos está sincronizada após enemies = alive
	if spatial_hash_manager:
		spatial_hash_manager.update_grid()

	var hero_rate_multiplier = 1.0
	if skills_manager:
		hero_rate_multiplier = skills_manager.get_speed_multiplier()

	hero["cooldown"] = max(0.0, hero["cooldown"] - delta * hero_rate_multiplier)


	if hero["cooldown"] <= 0.0 and not paused and not game_over:
		var hero_pos = Vector2(hero["x"], hero["y"])
		var closest_enemy = null
		var second_closest_enemy = null
		var closest_dist = hero["range"]
		var second_closest_dist = hero["range"]

		# Otimização: só considera inimigos em células no alcance (spatial hash)
		var hero_range_sq = hero["range"] * hero["range"]
		var candidate_indices: Array = spatial_hash_manager.get_enemy_candidates_in_range(hero_pos, hero["range"]) if spatial_hash_manager else _range_int(enemies.size())
		for idx in candidate_indices:
			var i := int(idx)
			if i < 0 or i >= enemies.size():
				continue
			var e = enemies[i]
			if e["hp"] <= 0 or e["reached"]:
				continue

			var dist_sq = hero_pos.distance_squared_to(e["pos"])
			if dist_sq >= hero_range_sq:
				continue
			var dist = sqrt(dist_sq)
			if dist < closest_dist:

				second_closest_enemy = closest_enemy
				second_closest_dist = closest_dist

				closest_dist = dist
				closest_enemy = e
			elif dist < second_closest_dist and hero_dual_cannon:

				second_closest_dist = dist
				second_closest_enemy = e

		if closest_enemy != null:
			# Permite vários tiros no mesmo frame quando cooldown acumulou (ex.: FPS baixo ou ataque muito rápido)
			const max_hero_shots_per_frame := 8
			var shots_fired := 0
			while hero["cooldown"] <= 0.0 and shots_fired < max_hero_shots_per_frame:
				if _weather_shot_hits():
					var predicted_target = _calculate_leading_target(closest_enemy, hero_pos)
					_try_shoot(predicted_target)
				else:
					hero["cooldown"] += hero["fire_rate"]
				shots_fired += 1

			if hero_dual_cannon and second_closest_enemy != null and _weather_shot_hits():
				var predicted_target2 = _calculate_leading_target(second_closest_enemy, hero_pos)
				arrows.append(_arrow_new(hero["x"], hero["y"], predicted_target2))


	for t in towers:

		var rate_multiplier = 1.0 + _boost_rate_bonus(t.pos)
		if skills_manager:
			rate_multiplier *= skills_manager.get_speed_multiplier()
		rate_multiplier *= _get_bonus_fire_rate_multiplier()

		var effective_fire_rate = _calc_effective_fire_rate(t.fire_rate, rate_multiplier)
		t.cooldown = max(0.0, t.cooldown - delta * rate_multiplier)
		if t.cooldown <= 0.0:
			_tower_fire_cross(t)
			t.cooldown = effective_fire_rate


	if not paused and not game_over:


		_update_mines(delta)
		_update_slow_towers(delta)
		_update_aoe_towers(delta)
		_update_sniper_towers(delta)
		_update_anti_air_towers(delta)
		_update_shock_towers(delta)
		_update_walls(delta)

func _tower_fire_cross(tower: Dictionary) -> void:
	if not _weather_shot_hits():
		return
	var speed := 260.0
	var dirs: Array = tower.get("dirs", [Vector2(1, 0)])
	var tower_damage: float = tower.get("damage", _cfg().get_float("TOWER_BASE_DAMAGE")) * global_tower_damage_boost
	var has_freeze: bool = tower.get("has_freeze", false)
	var has_fire: bool = tower.get("has_fire", false)

	if prestige_shop and prestige_shop.has_tower_arrow_corrosive():
		has_fire = true


	var damage_multiplier = 1.0 + _boost_damage_bonus(tower.pos)
	if skills_manager:
		damage_multiplier *= skills_manager.get_damage_multiplier()


	if weather_manager:
		damage_multiplier *= weather_manager.get_tower_damage_multiplier()

	tower_damage *= damage_multiplier
	var tower_range = tower.get("range", 260.0)

	if weather_manager:
		tower_range *= weather_manager.get_tower_range_multiplier()
	var life := float(tower_range) / speed


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

	var tower_crit_chance := _get_tower_crit_chance()
	var tower_crit_mult := _get_tower_crit_multiplier()
	for d in dirs:
		var dmg = tower_damage
		var is_crit := randf() < tower_crit_chance
		if is_crit:
			dmg *= tower_crit_mult
		var b = _acquire_pooled_dict("bullet")
		b["pos"] = tower.pos
		b["vel"] = d * speed
		b["life"] = life
		b["radius"] = 2
		b["damage"] = dmg
		b["pierce"] = 0
		b["has_freeze"] = has_freeze
		b["has_fire"] = has_fire
		b["tower_id"] = tower_id
		b["is_crit"] = is_crit
		b["is_missile"] = false
		b.erase("target")
		tower_bullets.append(b)

func _update_barracks(delta: float) -> void:
	for b in barracks:

		var valid_soldiers: Array = []
		for s in b.soldiers:
			var found = false
			for global_s in soldiers:
				if global_s == s and global_s.hp > 0:
					found = true
					valid_soldiers.append(s)
					break

			if not found and s.hp > 0:
				valid_soldiers.append(s)
		b.soldiers = valid_soldiers

		var barracks_combo := _combo_bonus_for(b.pos, "barracks")
		for s in b.soldiers:
			s["combo_damage_mult"] = barracks_combo.damage_multiplier
			s["combo_regen"] = barracks_combo.special_effect == "regen"

		b.soldier_spawn_cd -= delta


		if b.soldier_spawn_cd <= 0.0:

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


			if closest_enemy_idx < 0:
				closest_enemy_idx = -1


			var soldier = {
				"pos": b.pos,
				"target_enemy_idx": closest_enemy_idx,
				"hold_time": 0.0,
				"max_hold_time": b.hold_time,
				"damage": b.damage,
				"hp": 10.0,
				"max_hp": 10.0,
				"radius": 6.0,
				"speed": b.projectile_speed,
				"holding": false,
				"combo_damage_mult": barracks_combo.damage_multiplier,
				"combo_regen": barracks_combo.special_effect == "regen"
			}
			b.soldiers.append(soldier)
			soldiers.append(soldier)
			b.soldier_spawn_cd = b.soldier_spawn_rate


func _update_mines(_delta: float) -> void:
	var mines_to_remove: Array = []
	for i in range(mines.size()):
		var m = mines[i]
		if m.triggered:
			mines_to_remove.append(i)
			continue
		var trigger_radius = m.get("trigger_radius", _cfg().get_float("MINE_TRIGGER_RADIUS"))
		var trigger_radius_sq: float = trigger_radius * trigger_radius
		var candidate_indices: Array = _get_enemy_indices_in_range(m.pos, trigger_radius)
		for idx in candidate_indices:
			var ei := int(idx)
			if ei < 0 or ei >= enemies.size():
				continue
			var e = enemies[ei]
			if e["hp"] <= 0 or e["reached"]:
				continue
			if m.pos.distance_squared_to(e["pos"]) <= trigger_radius_sq:
				m.triggered = true
				_detonate_mine(m)
				mines_to_remove.append(i)
				break

	mines_to_remove.reverse()
	for idx in mines_to_remove:
		if idx < mines.size():
			var tile = Vector2i(int(mines[idx].grid_x), int(mines[idx].grid_y))
			_unregister_mine_tile(tile)
			mines.remove_at(idx)

func _detonate_mine(mine: Dictionary) -> void:

	var explosion_damage = mine.get("damage", get_mine_damage())
	var explosion_radius = mine.get("explosion_radius", get_mine_explosion_radius())
	var slow_duration = mine.get("slow_duration", _cfg().get_float("MINE_SLOW_DURATION"))
	var slow_amount = mine.get("slow_amount", _cfg().get_float("MINE_SLOW_AMOUNT"))

	if effects_manager:
		effects_manager.create_aoe_effect(mine.pos, explosion_radius, 0.35)

	var explosion_radius_sq: float = explosion_radius * explosion_radius
	var blast_candidates: Array = _get_enemy_indices_in_range(mine.pos, explosion_radius)
	for idx in blast_candidates:
		var ei := int(idx)
		if ei < 0 or ei >= enemies.size():
			continue
		var e = enemies[ei]
		if e["hp"] <= 0 or e["reached"]:
			continue
		if mine.pos.distance_squared_to(e["pos"]) <= explosion_radius_sq:
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
		var range_sq: float = st.range * st.range
		var candidate_indices: Array = _get_enemy_indices_in_range(st.pos, st.range)
		for idx in candidate_indices:
			var i := int(idx)
			if i < 0 or i >= enemies.size():
				continue
			var e = enemies[i]
			if e["hp"] <= 0 or e["reached"]:
				continue
			if st.pos.distance_squared_to(e["pos"]) > range_sq:
				continue
			var enemy_idx = e.get("idx", -1)
			if enemy_idx < 0:
				continue
			if not enemy_effects.has(enemy_idx):
				enemy_effects[enemy_idx] = { "slow_time": 0.0, "slow_amount": 0.0, "freeze_time": 0.0, "fire_time": 0.0 }
			enemy_effects[enemy_idx].slow_time = 999999.0
			var slow_amount: float = st.slow_amount
			if prestige_shop and prestige_shop.has_slow_tower_frost():
				slow_amount = min(0.7, slow_amount + 0.1)
			enemy_effects[enemy_idx].slow_amount = slow_amount

func _update_aoe_towers(delta: float) -> void:
	if paused or game_over:
		return
	for aoe in aoe_towers:

		var aoe_rate_multiplier = 1.0 + _boost_rate_bonus(aoe.pos)
		if skills_manager:
			aoe_rate_multiplier *= skills_manager.get_speed_multiplier()
		aoe_rate_multiplier *= _get_bonus_fire_rate_multiplier()

		var effective_fire_rate = _calc_effective_fire_rate(aoe.fire_rate, aoe_rate_multiplier)

		aoe.cooldown = max(0.0, aoe.cooldown - delta * aoe_rate_multiplier)
		if aoe.cooldown <= 0.0:

			var closest_enemy = null
			var effective_range = get_effective_tower_range(aoe.range)
			var effective_range_sq: float = effective_range * effective_range
			var closest_dist_sq: float = effective_range_sq + 1.0
			var aoe_candidates: Array = _get_enemy_indices_in_range(aoe.pos, effective_range)
			for idx in aoe_candidates:
				var ei := int(idx)
				if ei < 0 or ei >= enemies.size():
					continue
				var e = enemies[ei]
				if e["hp"] <= 0 or e["reached"]:
					continue
				var dist_sq: float = aoe.pos.distance_squared_to(e["pos"])
				if dist_sq <= effective_range_sq and dist_sq < closest_dist_sq:
					closest_dist_sq = dist_sq
					closest_enemy = e
			if closest_enemy != null:
				if not _weather_shot_hits():
					aoe.cooldown = effective_fire_rate
					continue

				var cannon_speed = 200.0

				var aoe_damage = aoe.damage * global_tower_damage_boost


				var damage_multiplier = 1.0 + _boost_damage_bonus(aoe.pos)
				aoe_damage *= damage_multiplier


				if skills_manager:
					aoe_damage *= skills_manager.get_damage_multiplier()

				if prestige_shop and prestige_shop.has_aoe_tower_inferno():
					aoe_damage *= 1.25

				var combo_bonus := _combo_bonus_for(aoe.pos, "aoe_tower")
				aoe_damage *= combo_bonus.damage_multiplier

				aoe_damage = get_effective_tower_damage(aoe_damage)

				aoe_cannon_projectiles.append({
					"pos": aoe.pos,
					"target": closest_enemy["pos"],
					"speed": cannon_speed,
					"radius": aoe.aoe_radius,
					"damage": aoe_damage,
					"aoe_tower": aoe,
					"combo_special": str(combo_bonus.get("special_effect", ""))
				})

				aoe.cooldown = effective_fire_rate
			else:

				aoe.cooldown = 0.0


	var i := 0
	while i < aoe_cannon_projectiles.size():
		var proj = aoe_cannon_projectiles[i]
		var dir = (proj.target - proj.pos).normalized()
		var dist_to_target = proj.pos.distance_to(proj.target)
		var move_dist = proj.speed * delta

		if move_dist >= dist_to_target:

			if effects_manager:
				effects_manager.create_aoe_effect(proj.target, proj.radius, 0.3)

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


			var tower_crit_chance := _get_tower_crit_chance()
			var tower_crit_mult := _get_tower_crit_multiplier()
			var blast_radius_sq: float = proj.radius * proj.radius
			var blast_candidates: Array = _get_enemy_indices_in_range(proj.target, proj.radius)
			for idx in blast_candidates:
				var ei := int(idx)
				if ei < 0 or ei >= enemies.size():
					continue
				var e = enemies[ei]
				if e["hp"] <= 0 or e["reached"]:
					continue
				if proj.target.distance_squared_to(e["pos"]) > blast_radius_sq:
					continue
				var damage_dealt = proj.damage
				var is_crit := randf() < tower_crit_chance
				if is_crit:
					damage_dealt *= tower_crit_mult
				e["hp"] -= damage_dealt
				if aoe_id != "" and tower_dps_data.has(aoe_id):
					tower_dps_data[aoe_id]["damage_dealt"] += damage_dealt
				_create_damage_number(e["pos"], damage_dealt, is_crit)
				_apply_combo_hit_effects(e, str(proj.get("combo_special", "")), damage_dealt)
				if e["hp"] <= 0:
					e["hp"] = 0
					e["dying"] = true
					e["dying_time"] = 0.0
					_create_death_animation(e["pos"])
					var is_boss = e.get("is_boss", false)
					hero["coins"] += get_boss_reward() if is_boss else get_enemy_reward()
					_try_drop_coin(e["pos"])
					_try_drop_talisman(e["pos"])
					_track_enemy_kill(is_boss)
			aoe_cannon_projectiles[i] = aoe_cannon_projectiles[aoe_cannon_projectiles.size() - 1]
			aoe_cannon_projectiles.pop_back()
		else:
			proj.pos += dir * move_dist
			i += 1

func _update_sniper_towers(delta: float) -> void:
	if paused or game_over:
		return
	for sniper in sniper_towers:

		var sniper_rate_multiplier = 1.0 + _boost_rate_bonus(sniper.pos)
		if skills_manager:
			sniper_rate_multiplier *= skills_manager.get_speed_multiplier()
		sniper_rate_multiplier *= _get_bonus_fire_rate_multiplier()

		var effective_fire_rate = _calc_effective_fire_rate(sniper.fire_rate, sniper_rate_multiplier)

		sniper.cooldown = max(0.0, sniper.cooldown - delta * sniper_rate_multiplier)
		if sniper.cooldown <= 0.0:
			var target_mode = sniper.get("target_mode", 0)
			var target_enemy = null
			var target_dist = -1.0
			var base_center = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)

			var sniper_combo_range := _combo_bonus_for(sniper.pos, "sniper_tower")
			var sniper_range = get_effective_tower_range(sniper.range) if target_mode != 0 else sniper.range
			sniper_range *= sniper_combo_range.range_multiplier
			var sniper_range_sq: float = sniper_range * sniper_range
			var sniper_candidates: Array = _get_enemy_indices_in_range(sniper.pos, sniper_range)
			if target_mode == 0:
				var boss_found = false
				for idx in sniper_candidates:
					var ei := int(idx)
					if ei < 0 or ei >= enemies.size():
						continue
					var e = enemies[ei]
					if e["hp"] <= 0 or e["reached"]:
						continue
					if e.get("is_boss", false) and sniper.pos.distance_squared_to(e["pos"]) <= sniper_range_sq:
						target_enemy = e
						boss_found = true
						break
				if not boss_found:
					var closest_to_center = INF
					for idx in sniper_candidates:
						var ei := int(idx)
						if ei < 0 or ei >= enemies.size():
							continue
						var e = enemies[ei]
						if e["hp"] <= 0 or e["reached"]:
							continue
						var dist_to_sniper_sq: float = sniper.pos.distance_squared_to(e["pos"])
						if dist_to_sniper_sq <= sniper_range_sq:
							var dist_to_center = e["pos"].distance_to(base_center)
							if dist_to_center < closest_to_center:
								target_enemy = e
								closest_to_center = dist_to_center
								target_dist = sqrt(dist_to_sniper_sq)
			else:
				var closest_to_center = INF
				for idx in sniper_candidates:
					var ei := int(idx)
					if ei < 0 or ei >= enemies.size():
						continue
					var e = enemies[ei]
					if e["hp"] <= 0 or e["reached"]:
						continue
					var dist_to_sniper_sq: float = sniper.pos.distance_squared_to(e["pos"])
					if dist_to_sniper_sq <= sniper_range_sq:
						var dist_to_center = e["pos"].distance_to(base_center)
						if dist_to_center < closest_to_center:
							target_enemy = e
							closest_to_center = dist_to_center
							target_dist = sqrt(dist_to_sniper_sq)
			if target_enemy != null:
				if not _weather_shot_hits():
					sniper.cooldown = effective_fire_rate
					continue

				var dir = (target_enemy["pos"] - sniper.pos).normalized()
				var hit_pos = target_enemy["pos"]
				if effects_manager:
					effects_manager.create_sniper_effect(sniper.pos, hit_pos, 0.15)

				var enemies_in_line: Array = []
				for e in enemies:
					if e["hp"] <= 0 or e["reached"]:
						continue
					var dist_to_line = abs((e["pos"] - hit_pos).cross(dir))
					if dist_to_line < 20.0:
						var dist_along_line = (e["pos"] - sniper.pos).dot(dir)
						if dist_along_line > 0:
							enemies_in_line.append({"enemy": e, "dist": dist_along_line})

				enemies_in_line.sort_custom(func(a, b): return a.dist < b.dist)

				var sniper_damage = sniper.damage * global_tower_damage_boost


				var damage_multiplier = 1.0 + _boost_damage_bonus(sniper.pos)
				sniper_damage *= damage_multiplier


				if skills_manager:
					sniper_damage *= skills_manager.get_damage_multiplier()

				if prestige_shop and prestige_shop.has_sniper_tower_pierce():
					sniper_damage *= 1.25

				var sniper_combo := _combo_bonus_for(sniper.pos, "sniper_tower")
				sniper_damage *= sniper_combo.damage_multiplier

				sniper_damage = get_effective_tower_damage(sniper_damage)

				var pierce_bonus := 0
				if prestige_shop and prestige_shop.has_sniper_tower_pierce():
					pierce_bonus = 1

				var pierce_count = sniper.pierce + 1 + pierce_bonus

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

				var tower_crit_chance := minf(_get_tower_crit_chance() + sniper_combo.crit_bonus, 1.0)
				var tower_crit_mult := _get_tower_crit_multiplier()
				for i in range(min(pierce_count, enemies_in_line.size())):
					var e = enemies_in_line[i].enemy
					var damage_dealt = sniper_damage
					var is_crit := randf() < tower_crit_chance
					if is_crit:
						damage_dealt *= tower_crit_mult
					e["hp"] -= damage_dealt


					if tower_dps_data.has(sniper_id):
						tower_dps_data[sniper_id]["damage_dealt"] += damage_dealt

					_create_damage_number(e["pos"], damage_dealt, is_crit)
					if e["hp"] <= 0:
						e["hp"] = 0
						e["dying"] = true
						e["dying_time"] = 0.0
						_create_death_animation(e["pos"])
						var is_boss = e.get("is_boss", false)
						hero["coins"] += get_boss_reward() if is_boss else get_enemy_reward()

						_try_drop_coin(e["pos"])
						_try_drop_talisman(e["pos"])

						_track_enemy_kill(is_boss)

				sniper.cooldown = effective_fire_rate
			else:

				sniper.cooldown = 0.0

func _update_anti_air_towers(delta: float) -> void:
	if paused or game_over:
		return
	for anti_air in anti_air_towers:

		var anti_air_rate_multiplier = 1.0 + _boost_rate_bonus(anti_air.pos)
		if skills_manager:
			anti_air_rate_multiplier *= skills_manager.get_speed_multiplier()
		anti_air_rate_multiplier *= _get_bonus_fire_rate_multiplier()

		var effective_fire_rate = _calc_effective_fire_rate(anti_air.fire_rate, anti_air_rate_multiplier)

		anti_air.cooldown = max(0.0, anti_air.cooldown - delta * anti_air_rate_multiplier)
		if anti_air.cooldown <= 0.0:

			var closest_enemy = null
			var effective_range = get_effective_tower_range(anti_air.range)
			var closest_dist = effective_range + 1.0
			var closest_ground_dist = effective_range + 1.0
			var closest_ground_enemy = null
			var effective_range_sq: float = effective_range * effective_range
			var anti_air_candidates: Array = _get_enemy_indices_in_range(anti_air.pos, effective_range)

			for idx in anti_air_candidates:
				var ei := int(idx)
				if ei < 0 or ei >= enemies.size():
					continue
				var e = enemies[ei]
				if e["hp"] <= 0 or e["reached"] or e.get("dying", false):
					continue

				var enemy_type = e.get("enemy_type", EnemyConstants.EnemyType.ZOMBIE)
				var is_aerial = (enemy_type == EnemyConstants.EnemyType.ALIEN_VOADOR or enemy_type == EnemyConstants.EnemyType.MECANOIDE_DRONE)

				var dist_sq = anti_air.pos.distance_squared_to(e["pos"])

				if dist_sq > effective_range_sq:
					continue


				var dist = sqrt(dist_sq)


				if is_aerial:
					if dist < closest_dist:
						closest_dist = dist
						closest_enemy = e
				else:

					if dist < closest_ground_dist:
						closest_ground_dist = dist
						closest_ground_enemy = e


			if closest_enemy == null:
				closest_enemy = closest_ground_enemy
				closest_dist = closest_ground_dist

			if closest_enemy != null:
				if not _weather_shot_hits():
					anti_air.cooldown = effective_fire_rate
					continue

				var missiles_to_fire = anti_air.get("missile_count", 3)


				var enemy_type = closest_enemy.get("enemy_type", EnemyConstants.EnemyType.ZOMBIE)
				var is_aerial = (enemy_type == EnemyConstants.EnemyType.ALIEN_VOADOR or enemy_type == EnemyConstants.EnemyType.MECANOIDE_DRONE)


				var anti_air_damage = anti_air.damage * global_tower_damage_boost


				if not is_aerial:
					anti_air_damage *= 0.6


				var damage_multiplier = 1.0 + _boost_damage_bonus(anti_air.pos)
				anti_air_damage *= damage_multiplier


				if skills_manager:
					anti_air_damage *= skills_manager.get_damage_multiplier()


				anti_air_damage = get_effective_tower_damage(anti_air_damage)


				var anti_air_id = _get_tower_id(anti_air, "anti_air")
				if not tower_dps_data.has(anti_air_id):
					tower_dps_data[anti_air_id] = {
						"dps": 0.0,
						"damage_dealt": 0.0,
						"shots": 0,
						"wave_damage": {},
						"tower_type": "anti_air",
						"pos": anti_air.pos
					}
				tower_dps_data[anti_air_id]["shots"] += missiles_to_fire


				for i in range(missiles_to_fire):
					var target = closest_enemy

					if missiles_to_fire > 1 and i > 0:

						var next_target = null
						var next_dist = effective_range + 1.0
						var next_ground_dist = effective_range + 1.0
						var next_ground_target = null


						for e in enemies:

							var already_targeted = false
							for j in range(i):


								if e == closest_enemy:
									already_targeted = true
									break
							if already_targeted or e["hp"] <= 0 or e["reached"] or e.get("dying", false):
								continue

							var e_type = e.get("enemy_type", EnemyConstants.EnemyType.ZOMBIE)
							var e_is_aerial = (e_type == EnemyConstants.EnemyType.ALIEN_VOADOR or e_type == EnemyConstants.EnemyType.MECANOIDE_DRONE)

							var dist_sq = anti_air.pos.distance_squared_to(e["pos"])

							if dist_sq > effective_range_sq:
								continue

							var dist = sqrt(dist_sq)


							if e_is_aerial:
								if dist < next_dist:
									next_dist = dist
									next_target = e
							else:

								if dist < next_ground_dist:
									next_ground_dist = dist
									next_ground_target = e


						if next_target == null:
							next_target = next_ground_target
							next_dist = next_ground_dist

						if next_target != null:
							target = next_target


					var target_enemy_type = target.get("enemy_type", EnemyConstants.EnemyType.ZOMBIE)
					var target_is_aerial = (target_enemy_type == EnemyConstants.EnemyType.ALIEN_VOADOR or target_enemy_type == EnemyConstants.EnemyType.MECANOIDE_DRONE)
					var final_damage = anti_air_damage
					if not target_is_aerial:

						final_damage = anti_air_damage * 0.6


					var missile_speed = 300.0
					var max_life = 10.0
					var tower_crit_chance := _get_tower_crit_chance()
					var tower_crit_mult := _get_tower_crit_multiplier()
					var missile_damage = final_damage
					var missile_crit := randf() < tower_crit_chance
					if missile_crit:
						missile_damage *= tower_crit_mult
					var missile = _acquire_pooled_dict("bullet")
					missile["pos"] = anti_air.pos
					missile["target"] = target
					missile["target_pos"] = target["pos"]
					missile["speed"] = missile_speed
					missile["damage"] = missile_damage
					missile["explosion_radius"] = anti_air.get("explosion_radius", 0.0)
					missile["chain_targets"] = anti_air.get("chain_targets", 1)
					missile["chain_count"] = 0
					missile["is_missile"] = true
					missile["anti_air_tower"] = anti_air
					missile["tower_id"] = anti_air_id
					missile["life"] = max_life
					missile["radius"] = 5.0
					missile["is_crit"] = missile_crit
					tower_bullets.append(missile)


				anti_air.cooldown = effective_fire_rate
			else:

				anti_air.cooldown = 0.0

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
		anti_air_towers,
		barracks,
		healing_stations,
		walls
	)

func _update_shock_towers(delta: float) -> void:
	for shock in shock_towers:

		var shock_rate_multiplier = 1.0 + _boost_rate_bonus(shock.pos)
		if skills_manager:
			shock_rate_multiplier *= skills_manager.get_speed_multiplier()
		shock_rate_multiplier *= _get_bonus_fire_rate_multiplier()

		var effective_fire_rate = _calc_effective_fire_rate(shock.fire_rate, shock_rate_multiplier)

		shock.cooldown = max(0.0, shock.cooldown - delta * shock_rate_multiplier)
		if shock.cooldown <= 0.0:

			var closest_enemy = null
			var effective_range = get_effective_tower_range(shock.range)
			var effective_range_sq: float = effective_range * effective_range
			var closest_dist_sq: float = effective_range_sq
			var shock_candidates: Array = _get_enemy_indices_in_range(shock.pos, effective_range)
			for idx in shock_candidates:
				var ei := int(idx)
				if ei < 0 or ei >= enemies.size():
					continue
				var e = enemies[ei]
				if e["hp"] <= 0 or e["reached"] or e.get("dying", false):
					continue
				var dist_sq: float = shock.pos.distance_squared_to(e["pos"])
				if dist_sq < closest_dist_sq:
					closest_dist_sq = dist_sq
					closest_enemy = e

			if closest_enemy != null:
				if not _weather_shot_hits():
					shock.cooldown = effective_fire_rate
					continue

				var chain_targets = [closest_enemy]
				var chain_count = shock.chain_count
				if prestige_shop and prestige_shop.has_shock_tower_chain():
					chain_count += 2
				var last_target = closest_enemy
				const chain_link_range: float = 100.0
				var chain_link_range_sq: float = chain_link_range * chain_link_range

				for i in range(chain_count - 1):
					var next_target = null
					var next_dist_sq: float = chain_link_range_sq
					var chain_candidates: Array = _get_enemy_indices_in_range(last_target["pos"], chain_link_range)
					for cidx in chain_candidates:
						var ci := int(cidx)
						if ci < 0 or ci >= enemies.size():
							continue
						var e = enemies[ci]
						if e["hp"] <= 0 or e["reached"] or e.get("dying", false):
							continue
						if e in chain_targets:
							continue
						var dist_sq: float = last_target["pos"].distance_squared_to(e["pos"])
						if dist_sq < next_dist_sq:
							next_dist_sq = dist_sq
							next_target = e

					if next_target != null:
						chain_targets.append(next_target)
						last_target = next_target
					else:
						break


				var shock_damage = shock.damage * global_tower_damage_boost

				var damage_multiplier = 1.0 + _boost_damage_bonus(shock.pos)
				shock_damage *= damage_multiplier


				if skills_manager:
					shock_damage *= skills_manager.get_damage_multiplier()

				if prestige_shop and prestige_shop.has_shock_tower_chain():
					shock_damage *= 1.15

				shock_damage *= _combo_bonus_for(shock.pos, "shock_tower").damage_multiplier

				shock_damage = get_effective_tower_damage(shock_damage)


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


				var tower_crit_chance := _get_tower_crit_chance()
				var tower_crit_mult := _get_tower_crit_multiplier()
				for target in chain_targets:
					var damage_dealt = shock_damage
					var is_crit := randf() < tower_crit_chance
					if is_crit:
						damage_dealt *= tower_crit_mult
					target["hp"] -= damage_dealt


					if tower_dps_data.has(shock_id):
						tower_dps_data[shock_id]["damage_dealt"] += damage_dealt

					_create_damage_number(target["pos"], damage_dealt, is_crit, Color(0.5, 0.8, 1.0))
					if target["hp"] <= 0:
						target["hp"] = 0
						target["dying"] = true
						target["dying_time"] = 0.0
						_create_death_animation(target["pos"])
						var is_boss = target.get("is_boss", false)
						hero["coins"] += get_boss_reward() if is_boss else get_enemy_reward()
						_try_drop_coin(target["pos"])

						_track_enemy_kill(is_boss)


				if chain_targets.size() > 1:

					_create_shock_effect(shock.pos, chain_targets[0]["pos"])

					for i in range(chain_targets.size() - 1):
						var start_pos = chain_targets[i]["pos"]
						var end_pos = chain_targets[i + 1]["pos"]
						_create_shock_effect(start_pos, end_pos)
				else:

					_create_shock_effect(shock.pos, chain_targets[0]["pos"])


				shock.cooldown = effective_fire_rate

func _create_shock_effect(start_pos: Vector2, end_pos: Vector2) -> void:
	if visual_effects_manager:
		visual_effects_manager.create_shock_effect(start_pos, end_pos)
		return
	if shock_effects.size() >= 16:
		return
	shock_effects.append({
		"start": start_pos,
		"end": end_pos,
		"time": 0.0,
		"max_time": 0.15
	})

func _update_all_walls_max_hp() -> void:
	"""Atualiza o HP máximo de todas as muralhas baseado no multiplicador atual"""
	for w in walls:
		if w.has("upgrades"):
			var base_hp = _cfg().get_float("WALL_BASE_HP") * wall_hp_multiplier
			var upgrade_hp = w.upgrades.get("hp_level", 0) * _cfg().get_float("WALL_UPGRADE_HP_AMOUNT")
			var new_max_hp = base_hp + upgrade_hp
			var hp_ratio = w.hp / w.max_hp if w.max_hp > 0 else 1.0
			w.max_hp = new_max_hp
			w.hp = min(w.hp, new_max_hp)

			if w.hp <= 0 and new_max_hp > 0:
				w.hp = new_max_hp * 0.1

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

		if perk_effects.has("wall_regen") and w.hp < w.max_hp:
			w.hp = min(w.max_hp, w.hp + perk_effects["wall_regen"] * delta)

		for e in enemies:
			if e["hp"] <= 0 or e.get("reached", false):
				continue

			var dist = w.pos.distance_to(e["pos"])
			if dist < _cfg().get_float("WALL_DAMAGE_RADIUS"):

				var damage_per_second = _cfg().get_float("WALL_DAMAGE_PER_SECOND")
				if e.get("is_boss", false):
					damage_per_second *= _cfg().get_float("WALL_BOSS_DAMAGE_MULTIPLIER")


				w.hp -= damage_per_second * delta


				if randf() < 0.05:
					_create_damage_number(w.pos, damage_per_second * delta, false)

				if w.hp <= 0:

					if grid_manager.is_inside_base_point(w.pos):
						grid_manager.clear_grid_area(w.grid_x, w.grid_y, _cfg().get_int("WALL_SIZE_GRID"))
					else:
						var wall_tile = Vector2i(w.grid_x, w.grid_y)
						_unregister_wall_tile(wall_tile)
					pathfinder.invalidate_cache()
					walls_to_remove.append(i)
					needs_path_recalc = true
					break


	walls_to_remove.reverse()
	for idx in walls_to_remove:
		if idx < walls.size():
			walls.remove_at(idx)


	if needs_path_recalc:
		pathfinder.set_wall_tiles(wall_tiles)
		_recalculate_all_enemy_paths()

func _update_soldiers(delta: float) -> void:
	var alive_soldiers: Array = []
	for s in soldiers:
		if s.hp <= 0:
			continue

		if s.get("combo_regen", false):
			s.hp = min(float(s.get("max_hp", 10.0)), s.hp + 2.0 * delta)


		var target_enemy = null
		if s.target_enemy_idx >= 0 and s.target_enemy_idx < enemies.size():
			var enemy = enemies[s.target_enemy_idx]
			if enemy["hp"] > 0 and not enemy["reached"]:
				target_enemy = enemy

		if target_enemy == null:

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

				alive_soldiers.append(s)
				continue

		var dist_to_enemy = s.pos.distance_to(target_enemy["pos"])

		if not s.holding:

			if dist_to_enemy > s.radius + target_enemy["radius"]:
				var dir = (target_enemy["pos"] - s.pos).normalized()
				s.pos += dir * s.speed * delta
			else:

				s.holding = true
				s.hold_time = 0.0

		if s.holding:

			if target_enemy == null or target_enemy["hp"] <= 0 or target_enemy["reached"]:

				s.holding = false
				s.target_enemy_idx = -1
				alive_soldiers.append(s)
				continue

			s.hold_time += delta

			var soldier_damage = s.damage * delta
			if perk_effects.has("soldier_damage"):
				soldier_damage *= (1.0 + perk_effects["soldier_damage"])
			soldier_damage *= float(s.get("combo_damage_mult", 1.0))
			target_enemy["hp"] -= soldier_damage

			if not s.has("last_damage_time"):
				s["last_damage_time"] = 0.0
			s["last_damage_time"] += delta
			if s["last_damage_time"] >= 0.3:
				_create_damage_number(target_enemy["pos"], soldier_damage * 3.0, false)
				s["last_damage_time"] = 0.0
			if target_enemy["hp"] <= 0:
				_create_death_animation(target_enemy["pos"])
				var is_boss = target_enemy.get("is_boss", false)

				hero["coins"] += get_boss_reward() if is_boss else get_enemy_reward()

				_try_drop_coin(target_enemy["pos"])

				_track_enemy_kill(is_boss)


			s.pos = target_enemy["pos"]


			if s.hold_time >= s.max_hold_time:
				s.hp = 0

		alive_soldiers.append(s)

	soldiers = alive_soldiers


	for b in barracks:
		var alive_barracks_soldiers: Array = []
		for s in b.soldiers:

			var found_in_global = false
			for global_s in soldiers:
				if global_s == s and global_s.hp > 0:
					found_in_global = true
					alive_barracks_soldiers.append(s)
					break

			if not found_in_global and s.hp > 0:
				alive_barracks_soldiers.append(s)
		b.soldiers = alive_barracks_soldiers

func _show_game_over_screen() -> void:
	"""Mostra a tela de Game Over com a imagem de fundo"""
	if has_node("CanvasLayer/GameOverOverlay"):
		var go = $CanvasLayer/GameOverOverlay
		go.visible = true
		go.process_mode = Node.PROCESS_MODE_ALWAYS
		var minutes = int(game_time / 60.0)
		var seconds = int(game_time) % 60
		go.get_node("Panel/LblWave").text = "Onda %d  ·  Tempo %02d:%02d  ·  Abates %d" % [wave_manager.wave, minutes, seconds, total_kills]


		if has_node("CanvasLayer/GameOverOverlay/BackgroundImage") and tex_game_over != null:
			var bg = go.get_node("BackgroundImage")
			bg.texture = tex_game_over

			var viewport_size = get_viewport().get_visible_rect().size
			bg.set_anchors_preset(Control.PRESET_FULL_RECT)
			bg.size = viewport_size
			bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


		var panel = go.get_node("Panel")
		var viewport_size = get_viewport().get_visible_rect().size
		var panel_width = 500
		var panel_height = 240
		panel.position = Vector2(
			(viewport_size.x - panel_width) / 2,
			viewport_size.y * 0.65
		)
		panel.size = Vector2(panel_width, panel_height)


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


func _pause_game() -> void:
	paused = true
	pause_overlay.visible = true
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	if has_node("CanvasLayer"):
		$CanvasLayer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

func _unpause_game() -> void:
	paused = false
	pause_overlay.visible = false
	save_status_label.visible = false
	get_tree().paused = false

func _on_pause_resume() -> void:
	if talisman_inventory_visible:
		_close_talisman_inventory()
		return
	_unpause_game()

func _on_pause_save() -> void:
	_show_save_slot_dialog()

func _show_save_slot_dialog() -> void:

	var dialog = Window.new()
	dialog.title = "Salvar Jogo"
	dialog.size = Vector2(520, 450)
	dialog.min_size = Vector2(500, 400)
	dialog.always_on_top = true
	dialog.transient = true
	dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	UIHelper.apply_window_theme(dialog)


	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)


	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(480, 300)

	var slot_list = VBoxContainer.new()
	slot_list.add_theme_constant_override("separation", 5)
	scroll.add_child(slot_list)
	vbox.add_child(scroll)


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


		UIHelper.apply_button_theme(slot_button, UIHelper.BTN_SECONDARY)


		slot_button.pressed.connect(func(): _save_to_slot(slot_name, dialog))

		slot_list.add_child(slot_button)


	var cancel_button = Button.new()
	cancel_button.text = "Cancelar"
	cancel_button.custom_minimum_size = Vector2(480, 40)
	cancel_button.pressed.connect(func(): dialog.queue_free())
	UIHelper.apply_button_theme(cancel_button, UIHelper.BTN_SECONDARY)
	vbox.add_child(cancel_button)

	dialog.add_child(vbox)
	get_tree().root.add_child(dialog)


	await get_tree().process_frame
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.set_offsets_preset(Control.PRESET_FULL_RECT)


	var screen_size = DisplayServer.screen_get_size()
	var window_size = dialog.size
	dialog.position = (screen_size - window_size) / 2
	dialog.show()

func _save_to_slot(slot_name: String, dialog: Window) -> void:
	if SaveManager.save_game(self, slot_name):
		save_status_label.text = "Jogo salvo com sucesso no %s!" % slot_name
		save_status_label.modulate = Color(0.2, 1.0, 0.2)

		achievement_manager.increment_progress("save_game")
		save_status_label.visible = true
		dialog.queue_free()
		await get_tree().create_timer(2.0, true).timeout
		save_status_label.visible = false
	else:
		save_status_label.text = "Erro ao salvar jogo!"
		save_status_label.modulate = Color(1.0, 0.2, 0.2)
		save_status_label.visible = true
		dialog.queue_free()
		await get_tree().create_timer(2.0, true).timeout
		save_status_label.visible = false

func _on_pause_load() -> void:
	_show_load_slot_dialog()

func _show_load_slot_dialog() -> void:

	var dialog = Window.new()
	dialog.title = "Carregar Jogo"
	dialog.size = Vector2(520, 450)
	dialog.min_size = Vector2(500, 400)
	dialog.always_on_top = true
	dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	dialog.transient = true
	UIHelper.apply_window_theme(dialog)


	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)


	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(480, 300)

	var slot_list = VBoxContainer.new()
	slot_list.add_theme_constant_override("separation", 5)
	scroll.add_child(slot_list)
	vbox.add_child(scroll)


	var available_slots = SaveManager.list_available_slots()

	if available_slots.is_empty():
		var no_saves_label = Label.new()
		no_saves_label.text = "Nenhum save encontrado!"
		no_saves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_list.add_child(no_saves_label)
	else:

		for slot_info in available_slots:
			var slot_button = Button.new()
			slot_button.custom_minimum_size = Vector2(460, 60)
			slot_button.alignment = HORIZONTAL_ALIGNMENT_LEFT

			var slot_name = slot_info.get("slot_name", "Desconhecido")
			var wave = slot_info.get("wave", 0)
			var coins = slot_info.get("coins", 0)
			var base_hp = slot_info.get("base_hp", _cfg().get_float("HERO_BASE_HP"))
			var save_time = slot_info.get("save_time", "Desconhecido")
			var is_autosave = slot_info.get("is_autosave", false)


			var display_name = ""
			if is_autosave:
				display_name = "Salvamento Automático"
			elif slot_name.begins_with("slot"):
				var slot_num = slot_name.substr(4)
				display_name = "Slot %s" % slot_num
			else:
				display_name = slot_name


			var button_text = "%s\nOnda: %d | Moedas: %d | Vida: %d\n%s" % [display_name, wave, coins, base_hp, save_time]
			slot_button.text = button_text


			UIHelper.apply_button_theme(slot_button, UIHelper.BTN_SECONDARY)


			slot_button.pressed.connect(func(): _load_from_slot(slot_name, dialog))

			slot_list.add_child(slot_button)


	var cancel_button = Button.new()
	cancel_button.text = "Cancelar"
	cancel_button.custom_minimum_size = Vector2(480, 40)
	cancel_button.pressed.connect(func(): dialog.queue_free())
	UIHelper.apply_button_theme(cancel_button, UIHelper.BTN_SECONDARY)
	vbox.add_child(cancel_button)

	dialog.add_child(vbox)
	get_tree().root.add_child(dialog)


	await get_tree().process_frame
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.set_offsets_preset(Control.PRESET_FULL_RECT)


	var screen_size = DisplayServer.screen_get_size()
	var window_size = dialog.size
	dialog.position = (screen_size - window_size) / 2
	dialog.show()

func _load_from_slot(slot_name: String, dialog: Window) -> void:
	if SaveManager.has_save(slot_name):
		if SaveManager.load_game(self, slot_name):
			_apply_loaded_game_state()
			save_status_label.text = "Jogo carregado com sucesso do %s!" % slot_name
			save_status_label.modulate = Color(0.2, 1.0, 0.2)
			save_status_label.visible = true
			dialog.queue_free()
			_unpause_game()
			await get_tree().create_timer(2.0, true).timeout
			save_status_label.visible = false
		else:
			save_status_label.text = "Erro ao carregar jogo!"
			save_status_label.modulate = Color(1.0, 0.2, 0.2)
			save_status_label.visible = true
			dialog.queue_free()
			await get_tree().create_timer(2.0, true).timeout
			save_status_label.visible = false
	else:
		save_status_label.text = "Posição não encontrada!"
		save_status_label.modulate = Color(1.0, 0.8, 0.2)
		save_status_label.visible = true
		dialog.queue_free()
		await get_tree().create_timer(2.0, true).timeout
		save_status_label.visible = false

func _on_pause_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")

func _on_pause_quit() -> void:
	get_tree().paused = false
	get_tree().quit()

func _auto_save_after_wave() -> void:
	SaveManager.auto_save(self)
	print("Auto-save realizado após wave ", wave_manager.wave)

func _apply_loaded_game_state() -> void:
	_rebuild_base_grid_from_structures()
	_rebuild_mine_tiles()
	pathfinder.invalidate_cache()
	_reset_build_and_selection_state()
	for boost in boost_towers:
		var base_range: float = float(boost.get("base_range", _cfg().get_float("BOOST_TOWER_RANGE")))
		if base_range <= 0.0 or base_range >= 9999.0:
			base_range = _cfg().get_float("BOOST_TOWER_RANGE")
		boost["base_range"] = base_range
		boost["range"] = base_range * global_tower_range_boost
	_update_tower_shop_ui()

func _rebuild_base_grid_from_structures() -> void:
	if grid_manager == null:
		return
	grid_manager.reset_base_grid()
	for type_id in StructureCatalog.GRID_OCCUPANTS:
		var def := StructureCatalog.get_def(type_id)
		_occupy_structures_in_grid(_get_structure_array(def.array), _cfg().get_int(def.size_key), int(def.grid_type))

func _occupy_structures_in_grid(structures: Array, size: int, item_type: int) -> void:
	for data in structures:
		var gx: int
		var gy: int

		if data is Dictionary and data.has("grid_x") and data.has("grid_y"):
			gx = int(data["grid_x"])
			gy = int(data["grid_y"])
		elif data.has_method("get") or (data.has("grid_x") and data.has("grid_y")):

			gx = int(data.grid_x)
			gy = int(data.grid_y)
		else:
			continue
		grid_manager.set_grid_area(gx, gy, size, item_type)

func _reset_build_and_selection_state() -> void:
	_clear_placing()
	_clear_drag_state()
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


	if is_boss and special_currency_manager.is_special_boss_wave(current_wave):
		special_currency_manager.add_emeralds(GameConstants.BOSS_EMERALD_REWARD_COUNT, "boss_special")
		_create_special_currency_notification(pos, "emerald", GameConstants.BOSS_EMERALD_REWARD_COUNT)
		return


	if special_currency_manager.should_drop_emerald(current_wave):
		special_currency_manager.add_emeralds(1, "enemy_drop")
		_create_special_currency_notification(pos, "emerald", 1)

	if special_currency_manager.should_drop_diamond(current_wave):
		special_currency_manager.add_diamonds(1, "enemy_drop")
		_create_special_currency_notification(pos, "diamond", 1)

func _create_special_currency_notification(pos: Vector2, currency_type: String, amount: int) -> void:
	"""Cria notificação visual de moeda especial coletada"""

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


		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("pending_quest_rewards.cfg")

func _apply_prestige_bonuses() -> void:
	"""Aplica bônus permanentes de prestígio"""
	if not prestige_shop:
		return


	hero["damage"] = hero_damage_base
	hero["fire_rate"] = hero_fire_rate_base
	hero["crit_chance"] = hero_crit_chance_base
	base_hp = base_hp_base
	base_hp_max = base_hp_base
	global_tower_damage_boost = global_tower_damage_boost_base
	coin_drop_chance = coin_drop_chance_base

	var base_hp_boost = prestige_shop.get_base_hp_boost()
	if base_hp_boost > 0:
		base_hp += base_hp_boost
		base_hp_max += base_hp_boost


	var hero_damage_boost = prestige_shop.get_hero_damage_boost()
	if hero_damage_boost > 0:
		hero["damage"] *= (1.0 + hero_damage_boost)


	var coin_drop_boost = prestige_shop.get_coin_drop_boost()
	if coin_drop_boost > 0:
		coin_drop_chance += coin_drop_boost
		coin_drop_chance = min(coin_drop_chance, 1.0)


	var starting_coins_boost = prestige_shop.get_starting_coins_boost()
	if starting_coins_boost > 0:
		hero["coins"] += starting_coins_boost


	var reward_mult = prestige_shop.get_reward_multiplier()
	if reward_mult > 1.0:
		global_tower_damage_boost *= reward_mult

func _try_drop_talisman(pos: Vector2) -> void:
	"""Tenta dropar um talismã na posição especificada"""
	if not item_manager:
		return


	var drop_chance = GameConstants.TALISMAN_DROP_CHANCE

	if perk_effects.has("talisman_drop"):
		drop_chance *= (1.0 + perk_effects["talisman_drop"])
	if randf() < drop_chance:


		var rarity_roll = randf()
		var rarity: EquippableItem.ItemRarity
		if rarity_roll < 0.50:
			rarity = EquippableItem.ItemRarity.COMMON
		elif rarity_roll < 0.80:
			rarity = EquippableItem.ItemRarity.UNCOMMON
		elif rarity_roll < 0.95:
			rarity = EquippableItem.ItemRarity.RARE
		elif rarity_roll < 0.99:
			rarity = EquippableItem.ItemRarity.EPIC
		else:
			rarity = EquippableItem.ItemRarity.LEGENDARY


		var talisman = Talisman.create_random(rarity)


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

			item_manager.add_item(talisman_drop.talisman)

			if effects_manager:
				effects_manager.create_coin_collect_effect(talisman_drop.pos)
			return true

	return false

func _create_loading_screen() -> void:

	loading_screen = Control.new()
	loading_screen.name = "LoadingScreen"
	loading_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE


	var bg = ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.1, 1.0)
	loading_screen.add_child(bg)


	var outer_center = CenterContainer.new()
	outer_center.name = "OuterCenterContainer"
	outer_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_screen.add_child(outer_center)

	var center_container = VBoxContainer.new()
	center_container.name = "CenterContainer"
	center_container.add_theme_constant_override("separation", 20)
	outer_center.add_child(center_container)


	var loading_label = Label.new()
	loading_label.name = "LoadingLabel"
	loading_label.text = "Carregando..."
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.add_theme_font_size_override("font_size", 32)
	loading_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	center_container.add_child(loading_label)


	var progress_label = Label.new()
	progress_label.name = "ProgressLabel"
	progress_label.text = "0%"
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 24)
	progress_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	center_container.add_child(progress_label)


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
	progress_bar.color = Color(1.0, 0.9, 0.2, 1.0)
	progress_bar_bg.add_child(progress_bar)


	$CanvasLayer.add_child(loading_screen)
	loading_screen.z_index = 1000

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


	if loading_screen:
		loading_screen.queue_redraw()


	await get_tree().process_frame

func _hide_loading_screen() -> void:
	if loading_screen != null:
		is_loading = false

		var tween = create_tween()
		tween.tween_property(loading_screen, "modulate:a", 0.0, 0.3)
		await tween.finished
		loading_screen.queue_free()
		loading_screen = null

func _create_coin_collect_effect(pos: Vector2) -> void:
	if effects_manager:
		effects_manager.create_coin_collect_effect(pos)

func _play_coin_sound() -> void:


	var coin_sound = resource_manager.get_audio_stream("coin_collect")
	if coin_sound == null:

		coin_sound = _try_load_music("res://assets/sounds/coin_collect.ogg")
		if coin_sound == null:
			coin_sound = _try_load_music("res://assets/sounds/coin_collect.mp3")
		if coin_sound == null:
			coin_sound = _try_load_music("res://assets/sounds/coin_collect.wav")
		if coin_sound == null:
			return


	var available_player: AudioStreamPlayer = null
	for player in coin_sound_players:
		if not player.playing:
			available_player = player
			break


	if available_player == null and coin_sound_players.size() < GameConstants.UI_MAX_COIN_SOUND_PLAYERS:
		available_player = AudioStreamPlayer.new()
		available_player.name = "CoinSoundPlayer_%d" % coin_sound_players.size()
		available_player.volume_db = 0.0
		add_child(available_player)
		coin_sound_players.append(available_player)


	if available_player != null:
		available_player.stream = coin_sound
		available_player.play()

func _create_damage_number(pos: Vector2, damage: float, is_crit: bool = false, color: Color = Color.WHITE) -> void:
	if visual_effects_manager:
		visual_effects_manager.create_damage_number(pos, damage, is_crit, color)
		return
	if damage_numbers.size() >= 40:
		return
	damage_numbers.append({
		"pos": pos + Vector2(randf_range(-10, 10), randf_range(-5, 5)),
		"value": damage,
		"time": 0.0,
		"max_time": 1.0,
		"is_crit": is_crit,
		"color": color if color != Color.WHITE else (Color(1.0, 0.8, 0.2) if is_crit else Color(1.0, 0.3, 0.3)),
		"velocity": Vector2(randf_range(-30, 30), -50.0)
	})

func _create_tower_shop_ui() -> void:

	var canvas = $CanvasLayer
	var hud = canvas.get_node("HUD")


	if hud.has_node("TowerShopPanel"):
		hud.get_node("TowerShopPanel").queue_free()


	tower_shop_panel = Panel.new()
	tower_shop_panel.name = "TowerShopPanel"
	tower_shop_panel.z_index = 0
	hud.add_child(tower_shop_panel)


	var screen_width = get_viewport().get_visible_rect().size.x
	var screen_height = get_viewport().get_visible_rect().size.y
	var panel_width = 380.0
	var hero_card_height = 118
	var panel_height = screen_height - GameConstants.UI_TOP_BAR_HEIGHT
	tower_shop_panel.position = Vector2(screen_width - panel_width, GameConstants.UI_TOP_BAR_HEIGHT)
	tower_shop_panel.size = Vector2(panel_width, panel_height)
	tower_shop_panel.add_theme_stylebox_override("panel", UIHelper.side_panel_style())

	var content_margin = UIHelper.padded_margin(12, 12, 12, 12)
	content_margin.name = "ContentMargin"
	tower_shop_panel.add_child(content_margin)
	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.add_theme_constant_override("separation", 10)
	content_margin.add_child(main_vbox)

	var title_container = HBoxContainer.new()
	title_container.name = "TitleContainer"
	title_container.custom_minimum_size = Vector2(0, 32)
	main_vbox.add_child(title_container)

	var title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "LOJA DE TORRES"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.38))
	title_label.add_theme_font_size_override("font_size", 17)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_container.add_child(title_label)

	tower_shop_toggle_button = Button.new()
	tower_shop_toggle_button.name = "ToggleButton"
	tower_shop_toggle_button.text = "►"
	tower_shop_toggle_button.custom_minimum_size = Vector2(32, 28)
	tower_shop_toggle_button.pressed.connect(_toggle_tower_shop)
	tower_shop_toggle_button.tooltip_text = "Clique para recolher"
	UIHelper.apply_button_theme(tower_shop_toggle_button, UIHelper.BTN_PRIMARY)
	title_container.add_child(tower_shop_toggle_button)

	var scroll = ScrollContainer.new()
	scroll.name = "TowerScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll)

	tower_shop_panel.set_meta("scroll_container", scroll)

	var vbox = VBoxContainer.new()
	vbox.name = "TowerButtonsContainer"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)


	_create_hero_home_card(vbox, hero_card_height)


	var tower_data = [
		{"name": "Torre Básica", "catalog_id": "tower", "cost": _cfg().get_int("TOWER_COST"), "icon": tex_tower, "func": "_on_buy_tower", "max": _cfg().get_int("MAX_TOWERS"), "array_name": "towers"},
		{"name": "Quartel", "catalog_id": "barracks", "cost": _cfg().get_int("BARRACKS_COST"), "icon": tex_barracks, "func": "_on_buy_barracks", "max": _cfg().get_int("MAX_BARRACKS"), "array_name": "barracks"},
		{"name": "Mina", "catalog_id": "mine", "cost": _cfg().get_int("MINE_COST"), "icon": tex_mine, "func": "_on_buy_mine", "max": _cfg().get_int("MAX_MINES"), "array_name": "mines"},
		{"name": "Canhão", "catalog_id": "aoe_tower", "cost": _cfg().get_int("AOE_TOWER_COST"), "icon": tex_aoe_tower, "func": "_on_buy_aoe_tower", "max": _cfg().get_int("MAX_AOE_TOWERS"), "array_name": "aoe_towers"},
		{"name": "Muralha", "catalog_id": "wall", "cost": 100, "icon": tex_wall_structure, "func": "_on_buy_wall", "max": _cfg().get_int("MAX_WALLS"), "array_name": "walls"},
		{"name": "Torre de Choque", "catalog_id": "shock_tower", "cost": _cfg().get_int("SHOCK_TOWER_COST"), "icon": tex_shock_tower, "func": "_on_buy_shock_tower", "max": _cfg().get_int("MAX_SHOCK_TOWERS"), "array_name": "shock_towers"},
		{"name": "Torre Sniper", "catalog_id": "sniper_tower", "cost": _cfg().get_int("SNIPER_TOWER_COST"), "icon": tex_sniper_tower, "func": "_on_buy_sniper_tower", "max": _cfg().get_int("MAX_SNIPER_TOWERS"), "array_name": "sniper_towers"},
		{"name": "Altar de Melhoria", "catalog_id": "boost_tower", "cost": _cfg().get_int("BOOST_TOWER_COST"), "icon": tex_boost_tower, "func": "_on_buy_boost_tower", "max": _cfg().get_int("MAX_BOOST_TOWERS"), "array_name": "boost_towers"},
		{"name": "Estação de Cura", "catalog_id": "healing_station", "cost": _cfg().get_int("HEALING_STATION_COST"), "icon": tex_healing_station, "func": "_on_buy_healing_station", "max": _cfg().get_int("MAX_HEALING_STATIONS"), "array_name": "healing_stations"},
		{"name": "Torre de Congelamento", "catalog_id": "slow_tower", "cost": _cfg().get_int("SLOW_TOWER_COST"), "icon": tex_slow_tower, "func": "_on_buy_slow_tower", "max": _cfg().get_int("MAX_SLOW_TOWERS"), "array_name": "slow_towers"},
		{"name": "Torre Antiaérea", "catalog_id": "anti_air_tower", "cost": _cfg().get_int("ANTI_AIR_TOWER_COST"), "icon": tex_anti_air_tower, "func": "_on_buy_anti_air_tower", "max": _cfg().get_int("MAX_ANTI_AIR_TOWERS"), "array_name": "anti_air_towers"},
		{"name": "Mercado de Esmeraldas", "catalog_id": "market", "cost": _cfg().get_int("MARKET_COST_EMERALDS"), "icon": tex_market, "func": "_on_buy_market", "max": _cfg().get_int("MAX_MARKETS"), "array_name": "markets", "cost_type": "emeralds"},
	]


	for tower_info in tower_data:
		var btn_container = PanelContainer.new()
		btn_container.custom_minimum_size = Vector2(0, 78)
		btn_container.add_theme_stylebox_override("panel", UIHelper.card_style())

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		btn_container.add_child(hbox)

		var icon_texture = TextureRect.new()
		icon_texture.custom_minimum_size = Vector2(44, 44)
		icon_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_texture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon_texture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if tower_info.icon != null:
			icon_texture.texture = tower_info.icon
		hbox.add_child(icon_texture)

		var text_container = VBoxContainer.new()
		text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		text_container.add_theme_constant_override("separation", 2)
		hbox.add_child(text_container)

		var name_label = Label.new()
		name_label.text = tower_info.name
		name_label.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0))
		name_label.add_theme_font_size_override("font_size", 14)
		text_container.add_child(name_label)

		var cost_label = Label.new()
		cost_label.name = "CostLabel"
		if tower_info.has("cost_type") and tower_info.cost_type == "emeralds":
			cost_label.text = "🟢 %d esmeraldas" % tower_info.cost
			cost_label.add_theme_color_override("font_color", Color(0.35, 0.85, 0.45))
		else:
			cost_label.text = "%d moedas" % tower_info.cost
			cost_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.38))
		cost_label.add_theme_font_size_override("font_size", 12)
		text_container.add_child(cost_label)

		var limit_label = Label.new()
		limit_label.name = "LimitLabel"
		limit_label.text = "0/%d" % tower_info.max
		limit_label.add_theme_color_override("font_color", Color(0.72, 0.74, 0.82))
		limit_label.add_theme_font_size_override("font_size", 11)
		text_container.add_child(limit_label)

		var buy_btn = Button.new()
		buy_btn.name = "BuyButton"
		buy_btn.text = "Comprar"
		buy_btn.custom_minimum_size = Vector2(82, 36)
		buy_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
		buy_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		buy_btn.pressed.connect(Callable(self, tower_info.func))
		UIHelper.apply_success_button(buy_btn)

		var shop_tooltip = _get_shop_tooltip_text(tower_info.name)
		buy_btn.tooltip_text = shop_tooltip
		buy_btn.mouse_entered.connect(func(): _on_shop_button_hover(tower_info.name))
		buy_btn.mouse_exited.connect(func(): _on_shop_button_unhover())
		hbox.add_child(buy_btn)


		var tower_button_data = {
			"container": btn_container,
			"icon": icon_texture,
			"name_label": name_label,
			"cost_label": cost_label,
			"limit_label": limit_label,
			"buy_button": buy_btn,
			"tower_info": tower_info
		}
		tower_buttons.append(tower_button_data)

		vbox.add_child(btn_container)


		if tower_info.name == "Mina":
			_create_mine_upgrade_buttons(vbox, panel_width)


	tooltip_label = Label.new()
	tooltip_label.name = "TooltipLabel"
	tooltip_label.visible = false
	tooltip_label.position = Vector2(10, 10)
	tooltip_label.custom_minimum_size = Vector2(250, 120)
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
	_update_tower_shop_ui()

func _create_game_tooltip() -> void:

	var canvas = $CanvasLayer
	game_tooltip = Control.new()
	game_tooltip.name = "GameTooltip"
	game_tooltip.visible = false
	game_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(game_tooltip)


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


	var tooltip_text_label = Label.new()
	tooltip_text_label.name = "TooltipText"
	tooltip_text_label.text = ""
	tooltip_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_text_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	tooltip_text_label.add_theme_font_size_override("font_size", 12)
	tooltip_text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	tooltip_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	tooltip_panel.add_child(tooltip_text_label)


	tooltip_panel.custom_minimum_size = Vector2(280, 0)
	tooltip_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	tooltip_text_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	tooltip_text_label.offset_left = 10
	tooltip_text_label.offset_top = 10
	tooltip_text_label.offset_right = -10
	tooltip_text_label.offset_bottom = -10

func _create_hero_home_card(vbox: VBoxContainer, card_height: float) -> void:
	hero_home_panel_data = {}
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, max(118.0, card_height))
	panel.add_theme_stylebox_override("panel", UIHelper.hero_card_style())
	vbox.add_child(panel)

	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
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

	var hero_icon_size = 45.0
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
	button.custom_minimum_size = Vector2(118, 40)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(_on_upgrade_hero_home)
	UIHelper.apply_button_theme(button, UIHelper.BTN_PRIMARY)
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
	var canvas = $CanvasLayer
	var hud = canvas.get_node("HUD")
	if hud.has_node("SkillsPanel"):
		hud.get_node("SkillsPanel").queue_free()

	skills_panel = Panel.new()
	skills_panel.name = "SkillsPanel"
	skills_panel.z_index = 0
	hud.add_child(skills_panel)

	var screen_width = get_viewport().get_visible_rect().size.x
	var screen_height = get_viewport().get_visible_rect().size.y
	var panel_width = 390.0
	var panel_height = screen_height - GameConstants.UI_TOP_BAR_HEIGHT
	var tower_panel_width = 350.0
	if tower_shop_panel != null:
		tower_panel_width = tower_shop_panel.size.x
	var margin = GameConstants.UI_SIDE_PANEL_GAP
	skills_panel.position = Vector2(screen_width - tower_panel_width - panel_width - margin, GameConstants.UI_TOP_BAR_HEIGHT)
	skills_panel.size = Vector2(panel_width, panel_height)
	skills_panel.add_theme_stylebox_override("panel", UIHelper.side_panel_style())

	var content_margin = UIHelper.padded_margin(12, 12, 12, 12)
	content_margin.name = "ContentMargin"
	skills_panel.add_child(content_margin)
	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.add_theme_constant_override("separation", 10)
	content_margin.add_child(main_vbox)

	var title_container = HBoxContainer.new()
	title_container.name = "TitleContainer"
	title_container.custom_minimum_size = Vector2(0, 32)
	main_vbox.add_child(title_container)

	var title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "SKILLS"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_color_override("font_color", Color(0.55, 0.78, 1.0))
	title_label.add_theme_font_size_override("font_size", 17)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_container.add_child(title_label)

	skills_panel_toggle_button = Button.new()
	skills_panel_toggle_button.name = "ToggleButton"
	skills_panel_toggle_button.text = "►"
	skills_panel_toggle_button.custom_minimum_size = Vector2(32, 28)
	skills_panel_toggle_button.pressed.connect(_toggle_skills_panel)
	skills_panel_toggle_button.tooltip_text = "Clique para recolher"
	UIHelper.apply_button_theme(skills_panel_toggle_button, UIHelper.BTN_PRIMARY)
	title_container.add_child(skills_panel_toggle_button)

	var scroll = ScrollContainer.new()
	scroll.name = "SkillsScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.name = "SkillsButtonsContainer"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)
	skills_panel.set_meta("skills_container", vbox)

	_add_skill_card(vbox, {
		"key": "collect_coins",
		"title": "Coletar Moedas [1]",
		"desc": "Coleta todas as moedas do mapa",
		"cd": GameConstants.SKILL_COLLECT_COINS_COOLDOWN,
		"callback": _on_skill_collect_coins,
		"accent": Color(0.2, 0.46, 0.3),
		"icon_texture": tex_coin,
		"icon_text": ""
	})
	_add_skill_card(vbox, {
		"key": "damage_boost",
		"title": "Boost de Dano [2]",
		"desc": "+50%% dano por %.0fs" % GameConstants.SKILL_DAMAGE_BOOST_DURATION,
		"cd": GameConstants.SKILL_DAMAGE_BOOST_COOLDOWN,
		"callback": _on_skill_damage_boost,
		"accent": Color(0.5, 0.22, 0.24),
		"icon_text": "⚔"
	})
	_add_skill_card(vbox, {
		"key": "speed_boost",
		"title": "Boost de Velocidade [3]",
		"desc": "+30%% velocidade por %.0fs" % GameConstants.SKILL_SPEED_BOOST_DURATION,
		"cd": GameConstants.SKILL_SPEED_BOOST_COOLDOWN,
		"callback": _on_skill_speed_boost,
		"accent": Color(0.22, 0.32, 0.52),
		"icon_text": "⚡"
	})
	_add_skill_card(vbox, {
		"key": "slow_all",
		"title": "Slow Global [4]",
		"desc": "Reduz velocidade de todos os inimigos por %.0fs" % GameConstants.SKILL_SLOW_ALL_DURATION,
		"cd": GameConstants.SKILL_SLOW_ALL_COOLDOWN,
		"callback": _on_skill_slow_all,
		"accent": Color(0.2, 0.4, 0.5),
		"icon_text": "❄"
	})
	_add_skill_card(vbox, {
		"key": "magnetism",
		"title": "Magnetismo de Moedas [5]",
		"desc": "Coleta moedas automaticamente ao passar o mouse por %.0fs" % GameConstants.SKILL_MAGNETISM_DURATION,
		"cd": GameConstants.SKILL_MAGNETISM_COOLDOWN,
		"callback": _on_skill_magnetism,
		"accent": Color(0.36, 0.24, 0.5),
		"icon_text": "🧲"
	})

	var talisman_btn = Button.new()
	talisman_btn.name = "TalismanButton"
	talisman_btn.text = "Talismãs"
	talisman_btn.custom_minimum_size = Vector2(0, 42)
	talisman_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	talisman_btn.pressed.connect(_toggle_talisman_inventory)
	UIHelper.apply_accent_button(talisman_btn, Color(0.32, 0.24, 0.5), Color(0.4, 0.3, 0.6))
	vbox.add_child(talisman_btn)

	_create_talisman_inventory_ui()

func _add_skill_card(parent: VBoxContainer, cfg: Dictionary) -> void:
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(0, 88)
	container.add_theme_stylebox_override("panel", UIHelper.card_style())
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	container.add_child(hbox)

	if cfg.get("icon_texture", null) != null:
		var icon_wrap = Control.new()
		icon_wrap.custom_minimum_size = Vector2(48, 48)
		icon_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var icon = TextureRect.new()
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = cfg["icon_texture"]
		icon_wrap.add_child(icon)
		hbox.add_child(icon_wrap)
	else:
		var icon_lbl = Label.new()
		icon_lbl.text = str(cfg.get("icon_text", ""))
		icon_lbl.custom_minimum_size = Vector2(48, 48)
		icon_lbl.add_theme_font_size_override("font_size", 28)
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(icon_lbl)

	var text_box = VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 2)
	hbox.add_child(text_box)

	var name_lbl = Label.new()
	name_lbl.text = str(cfg.get("title", ""))
	name_lbl.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0))
	name_lbl.add_theme_font_size_override("font_size", 14)
	text_box.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = str(cfg.get("desc", ""))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_color_override("font_color", Color(0.72, 0.74, 0.82))
	desc_lbl.add_theme_font_size_override("font_size", 11)
	text_box.add_child(desc_lbl)

	var cd_base = Label.new()
	cd_base.text = "CD: %.0fs" % float(cfg.get("cd", 0.0))
	cd_base.add_theme_color_override("font_color", Color(0.78, 0.8, 0.88))
	cd_base.add_theme_font_size_override("font_size", 11)
	text_box.add_child(cd_base)

	var cd_lbl = Label.new()
	cd_lbl.text = ""
	cd_lbl.add_theme_color_override("font_color", Color(1.0, 0.55, 0.55))
	cd_lbl.add_theme_font_size_override("font_size", 11)
	text_box.add_child(cd_lbl)

	var btn = Button.new()
	btn.text = "Usar"
	btn.custom_minimum_size = Vector2(68, 36)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(cfg["callback"])
	UIHelper.apply_accent_button(btn, cfg["accent"])
	hbox.add_child(btn)

	skill_buttons[str(cfg["key"])] = {"button": btn, "cooldown_label": cd_lbl, "cooldown_base_label": cd_base}
	parent.add_child(container)

func _create_talisman_inventory_ui() -> void:
	if has_node("TalismanModalLayer"):
		get_node("TalismanModalLayer").queue_free()

	var layer := CanvasLayer.new()
	layer.name = "TalismanModalLayer"
	layer.layer = 40
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	var vbox := UIHelper.present_modal(layer, Vector2(600, 520))
	var overlay: Control = vbox.get_meta("modal_root")
	overlay.name = "TalismanInventoryOverlay"
	overlay.visible = false
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.gui_input.connect(_on_talisman_overlay_gui_input)

	var title = Label.new()
	title.text = "Talismãs"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.custom_minimum_size = Vector2(100, 36)
	close_btn.pressed.connect(_close_talisman_inventory)
	UIHelper.apply_button_theme(close_btn, UIHelper.BTN_SECONDARY)
	vbox.add_child(close_btn)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var scroll_margin = MarginContainer.new()
	scroll_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_margin.add_theme_constant_override("margin_left", 4)
	scroll_margin.add_theme_constant_override("margin_right", 4)
	scroll_margin.add_theme_constant_override("margin_top", 4)
	scroll_margin.add_theme_constant_override("margin_bottom", 4)
	scroll.add_child(scroll_margin)

	var inventory_vbox = VBoxContainer.new()
	inventory_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_vbox.add_theme_constant_override("separation", 8)
	scroll_margin.add_child(inventory_vbox)

	talisman_inventory_overlay = overlay
	talisman_inventory_panel = overlay
	talisman_inventory_container = inventory_vbox
	_update_talisman_inventory_ui()

var talisman_inventory_overlay: Control = null
var talisman_inventory_panel: Control = null
var talisman_inventory_container: VBoxContainer = null
var talisman_inventory_visible: bool = false

func _on_talisman_overlay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_talisman_inventory()
		get_viewport().set_input_as_handled()

func _open_talisman_inventory() -> void:
	if talisman_inventory_overlay == null:
		return
	talisman_inventory_visible = true
	talisman_inventory_overlay.visible = true
	_update_talisman_inventory_ui()

func _close_talisman_inventory() -> void:
	if talisman_inventory_overlay == null:
		return
	talisman_inventory_visible = false
	talisman_inventory_overlay.visible = false

func _toggle_talisman_inventory() -> void:
	if talisman_inventory_visible:
		_close_talisman_inventory()
	else:
		_open_talisman_inventory()

func _update_talisman_inventory_ui() -> void:
	if not talisman_inventory_container or not item_manager:
		return


	for child in talisman_inventory_container.get_children():
		child.queue_free()


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

			if item is Talisman:
				var talisman: Talisman = item
				talisman._apply_talisman_effects()
			_create_talisman_item_ui(item, true)


	var separator = HSeparator.new()
	separator.add_theme_constant_override("margin_top", 10)
	separator.add_theme_constant_override("margin_bottom", 10)
	talisman_inventory_container.add_child(separator)


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


	var item_margin = MarginContainer.new()
	item_margin.add_theme_constant_override("margin_left", 10)
	item_margin.add_theme_constant_override("margin_right", 10)
	item_margin.add_theme_constant_override("margin_top", 8)
	item_margin.add_theme_constant_override("margin_bottom", 8)
	item_container.add_child(item_margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	item_margin.add_child(hbox)


	var icon_container = Control.new()
	icon_container.custom_minimum_size = Vector2(70, 70)
	icon_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(icon_container)


	var icon_bg = ColorRect.new()
	icon_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_bg.color = Color(rarity_color.r * 0.3, rarity_color.g * 0.3, rarity_color.b * 0.3, 0.8)
	icon_container.add_child(icon_bg)


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


	if tex_talisman != null:
		var icon_texture = TextureRect.new()
		icon_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_texture.texture = tex_talisman
		icon_container.add_child(icon_texture)


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

	if item is Talisman:
		var talisman: Talisman = item

		talisman._apply_talisman_effects()
		desc_label.text = talisman.description
	else:
		desc_label.text = item.description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)


	var btn_container = VBoxContainer.new()
	btn_container.add_theme_constant_override("separation", 5)
	btn_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(btn_container)


	var captured_item = item  # captura por iteração para os lambdas não usarem sempre o último item
	var btn = Button.new()
	if is_equipped:
		btn.text = "Desequipar"
		btn.pressed.connect(func(): item_manager.unequip_item(captured_item); _update_talisman_inventory_ui())
	else:
		btn.text = "Equipar"
		btn.pressed.connect(func(): item_manager.equip_item(captured_item); _update_talisman_inventory_ui())
	btn.custom_minimum_size = Vector2(90, 35)
	btn_container.add_child(btn)


	if not is_equipped and item is Talisman:
		var sell_price = get_talisman_sell_price(item)
		var sell_btn = Button.new()
		sell_btn.text = "Vender\n🟢 %d" % sell_price
		sell_btn.custom_minimum_size = Vector2(90, 35)
		sell_btn.pressed.connect(func(): _sell_talisman(captured_item); _update_talisman_inventory_ui())
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


	var is_equipped = false
	for equipped_item in item_manager.equipped_items:
		if equipped_item is Talisman and equipped_item.id == talisman.id:
			is_equipped = true
			break

	if is_equipped:
		print("Não é possível vender talismãs equipados")
		return


	var found_in_inventory = false
	var talisman_to_remove = null


	if talisman in item_manager.inventory:
		found_in_inventory = true
		talisman_to_remove = talisman
	else:

		for inv_item in item_manager.inventory:
			if inv_item is Talisman and inv_item.id == talisman.id:
				found_in_inventory = true
				talisman_to_remove = inv_item
				break

	if not found_in_inventory:
		print("Talismã não encontrado no inventário")
		return


	item_manager.inventory.erase(talisman_to_remove)


	var sell_price = get_talisman_sell_price(talisman)
	special_currency_manager.add_emeralds(sell_price, "talisman_sell")


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
	if inspect_panel and inspect_panel.visible:
		return true
	return (tower_menu and tower_menu.is_visible()) or \
		   (sniper_menu and sniper_menu.is_visible()) or \
		   (aoe_menu and aoe_menu.is_visible()) or \
		   (shock_menu and shock_menu.is_visible()) or \
		   (slow_menu and slow_menu.is_visible()) or \
		   (boost_menu and boost_menu.is_visible()) or \
		   (anti_air_menu and anti_air_menu.is_visible()) or \
		   (barracks_menu and barracks_menu.is_visible()) or \
		   (wall_menu and wall_menu.is_visible())

func _show_range_indicator(world_pos: Vector2, radius: float, color: Color = Color(0.3, 0.7, 1.0, 0.65)) -> void:
	if radius <= 0.0:
		_hide_range_indicator()
		return

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
	_hide_inspect_panel()

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

	_hide_range_indicator()

	tower_selected_index = -1
	sniper_selected_index = -1
	aoe_selected_index = -1
	shock_selected_index = -1
	slow_selected_index = -1
	boost_selected_index = -1
	barracks_selected_index = -1

func _on_upgrade_menu_closed() -> void:

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

	if quest_manager:
		quest_manager.update_quest_progress(GameConstants.QuestType.USE_SKILLS, 1)
	if not skills_manager:
		return

	if not skills_manager.activate_collect_coins():
		_toast_skill_cooldown()
		return


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

	if quest_manager:
		quest_manager.update_quest_progress(GameConstants.QuestType.USE_SKILLS, 1)
	if not skills_manager:
		return

	if not skills_manager.activate_slow_all():
		_toast_skill_cooldown()
		return


	for i in range(enemies.size()):
		var e = enemies[i]
		var enemy_idx = e.get("idx", i)
		if not enemy_effects.has(enemy_idx):
			enemy_effects[enemy_idx] = { "slow_time": 0.0, "slow_amount": 0.0, "freeze_time": 0.0, "fire_time": 0.0 }

		enemy_effects[enemy_idx].slow_time = GameConstants.SKILL_SLOW_ALL_DURATION
		enemy_effects[enemy_idx].slow_amount = GameConstants.SKILL_SLOW_ALL_AMOUNT

	print("Slow Global ativado por %.0f segundos!" % GameConstants.SKILL_SLOW_ALL_DURATION)

func _on_skill_damage_boost() -> void:

	if quest_manager:
		quest_manager.update_quest_progress(GameConstants.QuestType.USE_SKILLS, 1)
	if not skills_manager:
		return

	if skills_manager.activate_damage_boost():
		print("Boost de Dano ativado por %.0f segundos!" % GameConstants.SKILL_DAMAGE_BOOST_DURATION)
	else:
		_toast_skill_cooldown()

func _on_skill_speed_boost() -> void:
	if not skills_manager:
		return

	if skills_manager.activate_speed_boost():
		print("Boost de Velocidade ativado por %.0f segundos!" % GameConstants.SKILL_SPEED_BOOST_DURATION)
	else:
		_toast_skill_cooldown()

func _on_skill_magnetism() -> void:
	if not skills_manager:
		return

	if skills_manager.activate_magnetism():
		print("Magnetismo de Moedas ativado por %.0f segundos!" % GameConstants.SKILL_MAGNETISM_DURATION)
	else:
		_toast_skill_cooldown()

func _update_skills_ui() -> void:
	if not skills_panel:
		return

	if not skills_manager:
		return


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


	if skill_buttons.has("magnetism"):
		var btn_data = skill_buttons["magnetism"]
		var btn = btn_data.button
		var cooldown_label = btn_data.cooldown_label


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


	if tb.find_child("BtnDPS", true, false):
		return

	var btn_dps = Button.new()
	btn_dps.name = "BtnDPS"
	btn_dps.text = "DPS"
	btn_dps.custom_minimum_size = Vector2(56, 32)
	btn_dps.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_dps.pressed.connect(_toggle_dps_menu)
	UIHelper.apply_button_theme(btn_dps, UIHelper.BTN_SECONDARY)
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
	alert_label.position = Vector2(-alert_label.size.x * 0.5, -alert_label.size.y * 0.5 + 100)
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

	if weather_alert_label and weather_alert_label.visible:
		weather_alert_timer = 0.0
		weather_alert_label.visible = false

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
	alert_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	alert_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	alert_label.add_theme_constant_override("outline_size", 4)
	alert_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	alert_label.size = Vector2(900, 180)
	alert_label.position = Vector2(-alert_label.size.x * 0.5, -alert_label.size.y * 0.5)
	canvas.add_child(alert_label)
	special_wave_alert_label = alert_label

func _show_special_wave_alert(wave_number: int, _special_wave_type: WaveManager.SpecialWaveType) -> void:
	if special_wave_alert_label == null:
		return


	if special_wave_alert_label.visible and special_wave_alert_timer > 0.0:
		return


	if weather_alert_label and weather_alert_label.visible:
		weather_alert_timer = 0.0
		weather_alert_label.visible = false

	var wave_name = wave_manager.get_special_wave_name()
	var wave_desc = wave_manager.get_special_wave_description()
	special_wave_alert_label.text = "%s\nWave %d Especial!\n%s" % [wave_name, wave_number, wave_desc]

	special_wave_alert_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	special_wave_alert_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	special_wave_alert_label.visible = true
	special_wave_alert_timer = GameConstants.SPECIAL_WAVE_ALERT_DURATION

func _check_perfect_wave_bonus() -> void:
	"""Verifica se completou wave perfeita e dá bônus"""
	if current_special_wave_type == WaveManager.SpecialWaveType.PERFECT_WAVE and not perfect_wave_bonus_given:

		if base_hp >= current_wave_base_hp_start:
			perfect_wave_bonus_given = true

			var bonus_coins = get_wave_completion_bonus() * 3
			hero["coins"] += bonus_coins
			if special_currency_manager:
				special_currency_manager.add_emeralds(5, "perfect_wave")

			_show_special_wave_alert(wave_manager.wave, WaveManager.SpecialWaveType.PERFECT_WAVE)
			special_wave_alert_timer = GameConstants.SPECIAL_WAVE_ALERT_DURATION
			special_wave_alert_label.text = "🎯 WAVE PERFEITA!\n+%d Moedas\n+5 Esmeraldas" % bonus_coins

func _create_weather_ui() -> void:
	"""Cria a UI para eventos climáticos"""
	var canvas = $CanvasLayer

	if weather_alert_label and weather_alert_label.is_inside_tree():
		weather_alert_label.queue_free()
	var alert_label = Label.new()
	alert_label.name = "WeatherAlertLabel"
	alert_label.text = ""
	alert_label.visible = false
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	alert_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	alert_label.add_theme_font_size_override("font_size", 32)
	alert_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0, 0.85))
	alert_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	alert_label.add_theme_constant_override("outline_size", 3)
	alert_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	alert_label.size = Vector2(800, 80)
	alert_label.position = Vector2(-alert_label.size.x * 0.5, 60)
	canvas.add_child(alert_label)
	weather_alert_label = alert_label


	if weather_overlay and weather_overlay.is_inside_tree():
		weather_overlay.queue_free()
	var overlay = ColorRect.new()
	overlay.name = "WeatherOverlay"
	overlay.color = Color(0, 0, 0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bar_height: float = GameConstants.UI_TOP_BAR_HEIGHT
	var map_width := float(_cfg().get_int("GRID_COLS") * _cfg().get_int("TILE_SIZE"))
	var map_height := float(_cfg().get_int("GRID_ROWS") * _cfg().get_int("TILE_SIZE"))
	overlay.position = Vector2(0, bar_height)
	overlay.size = Vector2(map_width, map_height)
	canvas.add_child(overlay)
	weather_overlay = overlay

func _show_weather_alert(_wave_number: int) -> void:
	"""Mostra alerta de mudança de clima"""
	if weather_alert_label == null or weather_manager == null:
		return


	if weather_alert_label.visible and weather_alert_timer > 0.0:
		return


	if boss_alert_label and boss_alert_label.visible:
		boss_alert_timer = 0.0
		boss_alert_label.visible = false
	if special_wave_alert_label and special_wave_alert_label.visible:

		pass

	var weather_name = weather_manager.get_weather_name()
	var weather_desc = weather_manager.get_weather_description()
	if weather_name != "":
		weather_alert_label.text = "%s\nClima: %s" % [weather_name, weather_desc]
		weather_alert_label.visible = true
		weather_alert_timer = 8.0

func _apply_weather_effects() -> void:
	"""Aplica efeitos visuais do clima"""
	if weather_manager == null:
		return


	if weather_overlay:

		var bar_height: float = GameConstants.UI_TOP_BAR_HEIGHT
		var map_width := float(_cfg().get_int("GRID_COLS") * _cfg().get_int("TILE_SIZE"))
		var map_height := float(_cfg().get_int("GRID_ROWS") * _cfg().get_int("TILE_SIZE"))
		weather_overlay.position = Vector2(0, bar_height)
		weather_overlay.size = Vector2(map_width, map_height)



		weather_overlay.color = Color(0, 0, 0, 0)


	if weather_manager.is_rainy():
		if weather_rain_particles.is_empty():

			var bar_height: float = GameConstants.UI_TOP_BAR_HEIGHT
			var map_width := float(_cfg().get_int("GRID_COLS") * _cfg().get_int("TILE_SIZE"))
			var map_height := float(_cfg().get_int("GRID_ROWS") * _cfg().get_int("TILE_SIZE"))
			for i in range(80):
				weather_rain_particles.append({
					"pos": Vector2(randf() * map_width, bar_height + randf() * map_height),
					"speed": 350.0 + randf() * 250.0,
					"length": 15.0 + randf() * 25.0
				})
	else:
		weather_rain_particles.clear()


	if weather_manager.is_foggy():
		if weather_clouds.is_empty():
			var map_width := float(_cfg().get_int("GRID_COLS") * _cfg().get_int("TILE_SIZE"))
			var map_height := float(_cfg().get_int("GRID_ROWS") * _cfg().get_int("TILE_SIZE"))
			for i in range(8):
				weather_clouds.append({
					"pos": Vector2(randf() * map_width, randf() * map_height),
					"size": 40.0 + randf() * 50.0,
					"alpha": 0.12 + randf() * 0.10,
					"speed": 12.0 + randf() * 18.0
				})
	else:
		weather_clouds.clear()


	if weather_manager.is_snowy():
		if weather_snow_particles.is_empty():

			var bar_height: float = GameConstants.UI_TOP_BAR_HEIGHT
			var map_width := float(_cfg().get_int("GRID_COLS") * _cfg().get_int("TILE_SIZE"))
			var map_height := float(_cfg().get_int("GRID_ROWS") * _cfg().get_int("TILE_SIZE"))
			for i in range(60):

				weather_snow_particles.append({
					"pos": Vector2(randf() * map_width, bar_height - 20.0 + randf() * (map_height + 40.0)),
					"speed_y": 30.0 + randf() * 50.0,
					"speed_x": -10.0 + randf() * 20.0,
					"size": 2.0 + randf() * 4.0,
					"rotation": randf() * PI * 2.0,
					"rotation_speed": -2.0 + randf() * 4.0
				})
	else:
		weather_snow_particles.clear()


	if weather_manager.is_windy():
		if weather_wind_particles.is_empty():

			var bar_height: float = GameConstants.UI_TOP_BAR_HEIGHT
			var map_width := float(_cfg().get_int("GRID_COLS") * _cfg().get_int("TILE_SIZE"))
			var map_height := float(_cfg().get_int("GRID_ROWS") * _cfg().get_int("TILE_SIZE"))
			for i in range(50):
				weather_wind_particles.append({
					"pos": Vector2(randf() * map_width, bar_height + randf() * map_height),
					"speed": 120.0 + randf() * 180.0,
					"length": 22.0 + randf() * 26.0,
					"alpha": 0.55 + randf() * 0.35
				})
	else:
		weather_wind_particles.clear()

func _update_weather_visuals(delta: float) -> void:
	"""Atualiza efeitos visuais do clima"""
	if weather_manager == null:
		return


	if weather_manager.is_rainy():
		var bar_height: float = GameConstants.UI_TOP_BAR_HEIGHT
		var map_width := float(_cfg().get_int("GRID_COLS") * _cfg().get_int("TILE_SIZE"))
		var map_height := float(_cfg().get_int("GRID_ROWS") * _cfg().get_int("TILE_SIZE"))
		var labirinto_bottom = bar_height + map_height
		for i in range(weather_rain_particles.size()):
			var p = weather_rain_particles[i]
			p.pos.y += p.speed * delta

			if p.pos.y > labirinto_bottom:
				p.pos.y = bar_height - p.length
				p.pos.x = randf() * map_width
	else:
		weather_rain_particles.clear()


	if weather_manager.is_foggy():
		var map_width := float(_cfg().get_int("GRID_COLS") * _cfg().get_int("TILE_SIZE"))
		var map_height := float(_cfg().get_int("GRID_ROWS") * _cfg().get_int("TILE_SIZE"))
		for i in range(weather_clouds.size()):
			var c = weather_clouds[i]
			c.pos.x += c.speed * delta

			if c.pos.x > map_width + c.size:
				c.pos.x = -c.size
				c.pos.y = randf() * map_height

			if c.pos.y < -c.size:
				c.pos.y = randf() * map_height
			elif c.pos.y > map_height + c.size:
				c.pos.y = randf() * map_height


	if weather_manager.is_snowy():
		var bar_height: float = GameConstants.UI_TOP_BAR_HEIGHT
		var map_width := float(_cfg().get_int("GRID_COLS") * _cfg().get_int("TILE_SIZE"))
		var map_height := float(_cfg().get_int("GRID_ROWS") * _cfg().get_int("TILE_SIZE"))
		var labirinto_bottom = bar_height + map_height
		for i in range(weather_snow_particles.size()):
			var s = weather_snow_particles[i]

			s.pos.y += s.speed_y * delta

			s.pos.x += s.speed_x * delta

			s.rotation += s.rotation_speed * delta

			if s.pos.y > labirinto_bottom:
				s.pos.y = bar_height - 10.0
				s.pos.x = randf() * map_width

			if s.pos.x < 0:
				s.pos.x = map_width
			elif s.pos.x > map_width:
				s.pos.x = 0


	if weather_manager.is_windy():
		var bar_height: float = GameConstants.UI_TOP_BAR_HEIGHT
		var map_width := float(_cfg().get_int("GRID_COLS") * _cfg().get_int("TILE_SIZE"))
		var map_height := float(_cfg().get_int("GRID_ROWS") * _cfg().get_int("TILE_SIZE"))
		var labirinto_bottom = bar_height + map_height
		for i in range(weather_wind_particles.size()):
			var w = weather_wind_particles[i]
			w.pos.x += w.speed * delta

			if w.pos.x > map_width + w.length:
				w.pos.x = -w.length
				w.pos.y = bar_height + randf() * map_height
				w.alpha = 0.55 + randf() * 0.35
	else:
		weather_wind_particles.clear()

func _draw_weather_effects() -> void:
	"""Desenha efeitos visuais do clima (apenas sobre o labirinto)"""
	if weather_manager == null:
		return


	var bar_height: float = GameConstants.UI_TOP_BAR_HEIGHT
	var map_width := float(_cfg().get_int("GRID_COLS") * _cfg().get_int("TILE_SIZE"))
	var map_height := float(_cfg().get_int("GRID_ROWS") * _cfg().get_int("TILE_SIZE"))



	var is_inside_maze = func(pos: Vector2, margin: float = 0.0) -> bool:
		return pos.x >= -margin and pos.x <= map_width + margin and \
			   pos.y >= bar_height - margin and pos.y <= bar_height + map_height + margin


	if weather_manager.is_rainy():
		for p in weather_rain_particles:

			if not is_inside_maze.call(p.pos, 10.0):
				continue
			var end_pos = p.pos + Vector2(0, p.length)

			if not is_inside_maze.call(end_pos, 10.0):

				end_pos.y = clamp(end_pos.y, 0.0, map_height)

			draw_line(p.pos, end_pos, Color(0.6, 0.8, 1.0, 0.7), 1.5)

			draw_line(p.pos, end_pos, Color(0.8, 0.9, 1.0, 0.3), 0.5)


	if weather_manager.is_foggy():
		for c in weather_clouds:
			if c.pos.x < -c.size or c.pos.x > map_width + c.size:
				continue
			if c.pos.y < -c.size or c.pos.y > map_height + c.size:
				continue
			var cloud_color = Color(0.72, 0.74, 0.80, c.alpha)
			draw_circle(c.pos, c.size, cloud_color)
			var offset1 = c.pos + Vector2(-c.size * 0.3, -c.size * 0.2)
			var offset2 = c.pos + Vector2(c.size * 0.3, -c.size * 0.2)
			draw_circle(offset1, c.size * 0.55, Color(0.75, 0.76, 0.82, c.alpha * 0.7))
			draw_circle(offset2, c.size * 0.55, Color(0.75, 0.76, 0.82, c.alpha * 0.7))


	if weather_manager.is_snowy():
		for s in weather_snow_particles:

			if not is_inside_maze.call(s.pos, s.size):
				continue

			var snow_color = Color(1.0, 1.0, 1.0, 0.8)

			draw_circle(s.pos, s.size, snow_color)

			var dir1 = Vector2(cos(s.rotation), sin(s.rotation)) * s.size
			var dir2 = Vector2(cos(s.rotation + PI/3), sin(s.rotation + PI/3)) * s.size
			var dir3 = Vector2(cos(s.rotation + 2*PI/3), sin(s.rotation + 2*PI/3)) * s.size
			draw_line(s.pos - dir1, s.pos + dir1, snow_color, 1.0)
			draw_line(s.pos - dir2, s.pos + dir2, snow_color, 1.0)
			draw_line(s.pos - dir3, s.pos + dir3, snow_color, 1.0)


	if weather_manager.is_windy():
		for w in weather_wind_particles:

			if not is_inside_maze.call(w.pos, w.length):
				continue
			var end_pos = w.pos + Vector2(w.length, 0)

			if not is_inside_maze.call(end_pos, w.length):

				end_pos.x = clamp(end_pos.x, 0.0, map_width)

			var wind_color = Color(0.75, 0.88, 1.0, w.alpha)
			draw_line(w.pos, end_pos, wind_color, 2.5)
			draw_line(w.pos, end_pos, Color(1.0, 1.0, 1.0, w.alpha * 0.4), 1.0)


func _reposition_right_side_buttons(tb: Panel) -> void:
	"""Reposiciona todos os botões da direita da HUD com espaçamento correto"""





	if tb.has_node("BtnDPS"):
		var btn_dps = tb.get_node("BtnDPS")
		btn_dps.layout_mode = 1
		btn_dps.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		btn_dps.offset_left = -80
		btn_dps.offset_top = 8
		btn_dps.offset_right = -20
		btn_dps.offset_bottom = 36


	if tb.has_node("BtnAdmin"):
		var btn_admin = tb.get_node("BtnAdmin")
		btn_admin.layout_mode = 1
		btn_admin.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		btn_admin.offset_left = -460
		btn_admin.offset_top = 8
		btn_admin.offset_right = -360
		btn_admin.offset_bottom = 36


	if tb.has_node("MusicVolumeContainer"):
		var volume_container = tb.get_node("MusicVolumeContainer")
		volume_container.layout_mode = 1
		volume_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		volume_container.offset_left = -580
		volume_container.offset_top = 8
		volume_container.offset_right = -450
		volume_container.offset_bottom = 36

func _on_music_volume_changed(value: float) -> void:
	music_volume = value
	var music_player = get_node_or_null("MusicPlayer")
	if music_player and not music_muted:
		music_player.volume_db = music_volume


	_save_music_settings()

func _load_user_preferences() -> void:
	"""Carrega preferências do usuário"""
	show_fps_enabled = UXSettings.show_fps()
	tower_shop_collapsed = UXSettings.shop_start_collapsed()
	skills_panel_collapsed = tower_shop_collapsed
	UXSettings.apply_saved_display()

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


		var tb = $CanvasLayer/HUD/TopBar
		if tb:
			var container = tb.get_node_or_null("MusicVolumeContainer")
			if container:
				var slider = container.get_node_or_null("MusicVolumeSlider")
				if slider:
					slider.value = music_volume
					music_volume_slider = slider

func _create_death_animation(pos: Vector2) -> void:
	if visual_effects_manager:
		visual_effects_manager.create_death_animation(pos)
		return
	if enemy_death_animations.size() >= 20:
		return
	enemy_death_animations.append({
		"pos": pos,
		"time": 0.0,
		"max_time": 0.5,
		"scale": 1.0,
		"alpha": 1.0
	})


func _track_enemy_kill(is_boss: bool) -> void:
	total_kills += 1


	achievement_manager.increment_progress("first_kill")
	achievement_manager.increment_progress("kill_100")
	achievement_manager.increment_progress("kill_1000")
	achievement_manager.increment_progress("kill_10000")
	achievement_manager.increment_progress("kill_50000")


	if quest_manager:
		quest_manager.update_quest_progress(GameConstants.QuestType.KILL_ENEMIES, 1)


	if is_boss:
		total_boss_kills += 1
		achievement_manager.increment_progress("boss_kill")
		achievement_manager.increment_progress("boss_kill_10")
		achievement_manager.increment_progress("boss_kill_50")
		achievement_manager.increment_progress("boss_kill_100")


		if quest_manager:
			quest_manager.update_quest_progress(GameConstants.QuestType.KILL_BOSSES, 1)

func _check_time_achievements() -> void:
	"""Verifica e atualiza achievements relacionados ao tempo de jogo"""
	if not achievement_manager:
		return

	var time_seconds = int(game_time)


	achievement_manager.set_progress("play_time_5min", time_seconds)
	achievement_manager.set_progress("play_time_15min", time_seconds)
	achievement_manager.set_progress("play_time_30min", time_seconds)
	achievement_manager.set_progress("play_time_1hour", time_seconds)
	achievement_manager.set_progress("play_time_2hours", time_seconds)
	achievement_manager.set_progress("play_time_5hours", time_seconds)

func _track_tower_built(tower_type: String) -> void:
	towers_built += 1
	tower_types_built[tower_type] = true


	achievement_manager.increment_progress("build_10_towers")
	achievement_manager.increment_progress("build_50_towers")
	achievement_manager.increment_progress("build_100_towers")


	if quest_manager:
		quest_manager.update_quest_progress(GameConstants.QuestType.BUILD_TOWERS, 1)


	var all_types = ["tower", "slow_tower", "aoe_tower", "sniper_tower", "boost_tower", "shock_tower", "barracks"]
	var built_count = 0
	for type in all_types:
		if tower_types_built.has(type):
			built_count += 1
	achievement_manager.set_progress("build_all_tower_types", built_count)


	if built_count >= 7:
		achievement_manager.set_progress("all_tower_types_one_game", 1)

func _track_coin_spent(amount: int) -> void:
	total_coins_spent += amount
	achievement_manager.increment_progress("spend_5000_coins", amount)
	achievement_manager.increment_progress("spend_100000_coins", amount)


	if quest_manager:
		quest_manager.update_quest_progress(GameConstants.QuestType.SPEND_COINS, amount)

func _track_wall_built() -> void:
	walls_built += 1
	achievement_manager.set_progress("build_5_walls", walls_built)
	achievement_manager.set_progress("build_50_walls", walls_built)

func _check_perfect_wave() -> void:

	if base_hp >= current_wave_base_hp_start:
		perfect_waves += 1
		achievement_manager.increment_progress("perfect_wave")
		achievement_manager.set_progress("perfect_wave_10", perfect_waves)
		achievement_manager.set_progress("perfect_wave_50", perfect_waves)
		achievement_manager.set_progress("perfect_wave_100", perfect_waves)


		if quest_manager:
			quest_manager.update_quest_progress(GameConstants.QuestType.PERFECT_WAVES, 1)


		if perfect_waves >= 100:
			achievement_manager.set_progress("survive_100_waves_no_damage", 100)

func _apply_perk_effects() -> void:
	var effects = perk_manager.apply_perk_effects(self)
	perk_effects = effects


	if effects.has("starting_coins"):
		hero["coins"] += int(effects["starting_coins"])

	if effects.has("starting_hp"):
		var hp_bonus = int(effects["starting_hp"])
		base_hp += hp_bonus
		base_hp_max += hp_bonus


	if effects.has("coin_drop_chance"):
		coin_drop_chance += effects["coin_drop_chance"]

		coin_drop_chance = min(coin_drop_chance, 1.0)


	if effects.has("hero_damage"):
		var boost = effects["hero_damage"]
		hero["damage"] *= (1.0 + boost)


	if effects.has("hero_fire_rate"):
		var boost = effects["hero_fire_rate"]
		hero["fire_rate"] *= (1.0 - boost)
		hero["fire_rate"] = _clamp_hero_fire_rate_from_bonus(hero["fire_rate"])


	if effects.has("tower_damage"):
		var boost = effects["tower_damage"]
		global_tower_damage_boost *= (1.0 + boost)

	if effects.has("tower_range"):
		global_tower_range_boost *= (1.0 + effects["tower_range"])

	if effects.has("hero_range"):
		hero["range"] += effects["hero_range"]

	if effects.has("hero_crit_chance"):
		hero["crit_chance"] += effects["hero_crit_chance"]
		hero["crit_chance"] = min(hero["crit_chance"], 1.0)

	if effects.has("skill_cooldown") and skills_manager:
		skills_manager.set_cooldown_reduction(effects["skill_cooldown"])

	if effects.has("coin_value") and coin_manager:
		coin_manager.coin_value_bonus = int(effects["coin_value"])



	if effects.has("wall_hp"):
		var boost = effects["wall_hp"]
		wall_hp_multiplier *= (1.0 + boost)

		_update_all_walls_max_hp()


	var has_perk = effects.has("coin_magnetism") and effects["coin_magnetism"] > 0
	if skills_manager:
		skills_manager.set_coin_magnetism_perk(has_perk)









func _apply_talisman_bonuses() -> void:
	"""Aplica bônus permanentes de talismãs equipados (sobre valores já modificados por prestígio e perks)"""
	if not item_manager:
		return

	var talisman_effects = item_manager.get_all_effects()


	if talisman_effects.has("tower_damage_boost"):
		var boost = talisman_effects["tower_damage_boost"]
		global_tower_damage_boost *= (1.0 + boost)


	if talisman_effects.has("tower_range_boost"):
		var boost = talisman_effects["tower_range_boost"]
		global_tower_range_boost *= (1.0 + boost)

		_apply_range_boost_to_all_towers()


	if talisman_effects.has("base_damage_boost"):
		var boost = talisman_effects["base_damage_boost"]
		hero["damage"] *= (1.0 + boost)


	if talisman_effects.has("coin_drop_chance_boost"):
		var boost = talisman_effects["coin_drop_chance_boost"]
		coin_drop_chance += boost
		coin_drop_chance = min(coin_drop_chance, 1.0)


	if talisman_effects.has("critical_chance_boost"):
		var boost = talisman_effects["critical_chance_boost"]
		hero["crit_chance"] += boost
		hero["crit_chance"] = min(hero["crit_chance"], 1.0)


	if talisman_effects.has("tower_crit_damage_boost"):
		var boost = talisman_effects["tower_crit_damage_boost"]

		if not perk_effects.has("tower_crit_damage_multiplier"):
			perk_effects["tower_crit_damage_multiplier"] = 1.0
		perk_effects["tower_crit_damage_multiplier"] += boost




func _apply_range_boost_to_all_towers() -> void:
	"""Aplica o boost de alcance global a todas as torres existentes"""

	for t in towers:
		var base_range = t.get("base_range", 260.0)
		if base_range == 0:
			base_range = 260.0
		t["base_range"] = base_range
		t["range"] = base_range * global_tower_range_boost


	for st in slow_towers:
		var base_range = st.get("base_range", 200.0)
		if base_range == 0:
			base_range = 200.0
		st["base_range"] = base_range
		st["range"] = base_range * global_tower_range_boost


	for aoe in aoe_towers:
		var base_range = aoe.get("base_range", 180.0)
		if base_range == 0:
			base_range = 180.0
		aoe["base_range"] = base_range
		aoe["range"] = base_range * global_tower_range_boost


	for sniper in sniper_towers:
		var base_range = sniper.get("base_range", 400.0)
		if base_range == 0:
			base_range = 400.0
		sniper["base_range"] = base_range
		sniper["range"] = base_range * global_tower_range_boost


	for anti_air in anti_air_towers:
		var base_range = anti_air.get("base_range", 250.0)
		if base_range == 0:
			base_range = 250.0
		anti_air["base_range"] = base_range
		anti_air["range"] = base_range * global_tower_range_boost


	for boost in boost_towers:
		var base_range = boost.get("base_range", _cfg().get_float("BOOST_TOWER_RANGE"))
		if base_range == 0 or base_range >= 9999.0:
			base_range = _cfg().get_float("BOOST_TOWER_RANGE")
		boost["base_range"] = base_range
		boost["range"] = base_range * global_tower_range_boost


	for shock in shock_towers:
		var base_range = shock.get("base_range", 200.0)
		if base_range == 0:
			base_range = 200.0
		shock["base_range"] = base_range
		shock["range"] = base_range * global_tower_range_boost

func _recalculate_all_bonuses() -> void:
	"""Recalcula todos os bônus do zero (usado quando talismãs são equipados/desequipados)"""

	hero["damage"] = hero_damage_base
	hero["fire_rate"] = hero_fire_rate_base
	hero["crit_chance"] = hero_crit_chance_base
	base_hp = base_hp_base
	base_hp_max = base_hp_base
	global_tower_damage_boost = global_tower_damage_boost_base
	global_tower_range_boost = 1.0
	coin_drop_chance = coin_drop_chance_base
	wall_hp_multiplier = 1.0
	if coin_manager:
		coin_manager.coin_value_bonus = 0
	if skills_manager:
		skills_manager.set_cooldown_reduction(0.0)


	_apply_prestige_bonuses()
	_apply_perk_effects()
	_apply_talisman_bonuses()



	base_hp_max = max(base_hp_max, base_hp)

	base_hp = min(base_hp, base_hp_max)


	_update_all_walls_max_hp()

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


	if quest_manager:
		quest_manager.update_quest_progress(GameConstants.QuestType.COLLECT_COINS, value)

func _update_game_tooltip(delta: float) -> void:
	if game_tooltip == null:
		return

	var tooltip_text_label = game_tooltip.get_node("Panel/TooltipText") as Label
	if tooltip_text_label == null:
		return


	if _is_placing() or dragging_tower:
		game_tooltip.visible = false
		tooltip_timer = 0.0
		return


	var mouse_pos = preview_mouse_pos
	var tooltip_info = _get_tooltip_for_position(mouse_pos)

	if tooltip_info != "":
		tooltip_timer += delta
		if tooltip_timer >= GameConstants.UI_TOOLTIP_DELAY:
			tooltip_text_label.text = tooltip_info
			game_tooltip.visible = true


			var viewport = get_viewport()
			var screen_mouse = viewport.get_mouse_position()


			tooltip_text_label.text = tooltip_info



			var lines = tooltip_info.split("\n")
			var max_line_length = 0
			for line in lines:
				if line.length() > max_line_length:
					max_line_length = line.length()


			var min_width = 280.0
			var min_height = 80.0
			var max_width = 450.0
			var max_height = 350.0


			var estimated_width = max_line_length * 8.0 + 40.0
			var estimated_height = lines.size() * 20.0 + 30.0


			var tooltip_size = Vector2(
				clamp(estimated_width, min_width, max_width),
				clamp(estimated_height, min_height, max_height)
			)

			var offset = Vector2(15, 15)


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

				panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

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

	for i in range(towers.size()):
		var t = towers[i]
		if world_pos.distance_to(t.pos) < 25.0:
			return _get_tower_tooltip(t)


	for i in range(slow_towers.size()):
		var st = slow_towers[i]
		if world_pos.distance_to(st.pos) < 25.0:
			return _get_slow_tower_tooltip(st)


	for i in range(aoe_towers.size()):
		var aoe = aoe_towers[i]
		if world_pos.distance_to(aoe.pos) < 25.0:
			return _get_aoe_tower_tooltip(aoe)


	for i in range(sniper_towers.size()):
		var sniper = sniper_towers[i]
		if world_pos.distance_to(sniper.pos) < 25.0:
			return _get_sniper_tower_tooltip(sniper)


	for i in range(boost_towers.size()):
		var boost = boost_towers[i]
		if world_pos.distance_to(boost.pos) < 25.0:
			return _get_boost_tower_tooltip(boost)


	for i in range(shock_towers.size()):
		var shock = shock_towers[i]
		if world_pos.distance_to(shock.pos) < 25.0:
			return _get_shock_tower_tooltip(shock)


	for i in range(barracks.size()):
		var b = barracks[i]
		if world_pos.distance_to(b.pos) < 25.0:
			return _get_barracks_tooltip(b)


	for i in range(walls.size()):
		var w = walls[i]
		if w.hp > 0 and world_pos.distance_to(w.pos) < 20.0:
			return _get_wall_tooltip(w)


	for i in range(mines.size()):
		var m = mines[i]
		if world_pos.distance_to(m.pos) < 15.0:
			return _get_mine_tooltip(m)


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
	var aura := _boost_aura_effect_mult()
	var dmg_boost = boost.get("damage_boost", 0.0) * 100.0 * aura
	var rate_boost = boost.get("rate_boost", 0.0) * 100.0 * aura
	var range_val = float(boost.get("range", 100.0))
	if prestige_shop:
		range_val *= prestige_shop.get_boost_aura_range_multiplier()
	var tooltip = "Torre Boost\n\nDano: +%.0f%%\nCadência: +%.0f%%\nAlcance: %.0f" % [dmg_boost, rate_boost, range_val]
	if aura > 1.0:
		tooltip += "\nAura Suprema ativa"
	return tooltip

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



	var base_upgrade_cost = get_upgrade_cost(_cfg().get_int("WALL_UPGRADE_HP_COST"), hp_level)
	var wave_scale = pow(_cfg().get_float("TOWER_COST_SCALE_PER_WAVE"), max(0, wave_manager.wave - 1))
	var upgrade_cost = int(base_upgrade_cost * wave_scale)
	var repair_cost = int((w.max_hp - w.hp) * 0.5)

	wall_menu.set_item_text(0, "Reforçar HP +25 (💰 %d moedas)" % upgrade_cost)
	wall_menu.set_item_text(1, "Reparar (💰 %d moedas)" % repair_cost)


	var can_upgrade = hp_level < _cfg().get_int("WALL_MAX_UPGRADES") and hero["coins"] >= upgrade_cost
	var can_repair = w.hp < w.max_hp and hero["coins"] >= repair_cost

	wall_menu.set_item_disabled(0, not can_upgrade)
	wall_menu.set_item_disabled(1, not can_repair)


	var screen_pos = get_viewport().get_mouse_position()

	if wall_menu.visible and wall_menu.has_meta("last_position"):
		screen_pos = wall_menu.get_meta("last_position")
	else:

		wall_menu.set_meta("last_position", screen_pos)

	wall_menu.position = screen_pos
	_present_from_popup(wall_menu, "Muralha", "HP %.0f / %.0f" % [w.hp, w.max_hp], w.pos, 0.0, "wall", wall_idx, screen_pos)

func _on_wall_menu_pressed(id: int) -> void:
	"""Handler para seleção de item no menu de muralha"""
	if wall_selected_index < 0 or wall_selected_index >= walls.size():
		return

	var w = walls[wall_selected_index]
	var upgrades = w.get("upgrades", {})
	var hp_level = upgrades.get("hp_level", 0)

	match id:
		1:

			var base_upgrade_cost = get_upgrade_cost(_cfg().get_int("WALL_UPGRADE_HP_COST"), hp_level)
			var wave_scale = pow(_cfg().get_float("TOWER_COST_SCALE_PER_WAVE"), max(0, wave_manager.wave - 1))
			var upgrade_cost = int(base_upgrade_cost * wave_scale)
			if hp_level < _cfg().get_int("WALL_MAX_UPGRADES") and hero["coins"] >= upgrade_cost:

				var hp_increase = _cfg().get_float("WALL_UPGRADE_HP_AMOUNT")
				var hp_ratio = w.hp / w.max_hp if w.max_hp > 0 else 1.0
				w.max_hp += hp_increase
				w.hp = w.max_hp * hp_ratio
				upgrades["hp_level"] = hp_level + 1
				w["upgrades"] = upgrades
				hero["coins"] -= upgrade_cost
				_track_coin_spent(upgrade_cost)
				walls[wall_selected_index] = w
		2:
			var repair_cost = int((w.max_hp - w.hp) * 0.5)
			if w.hp < w.max_hp and hero["coins"] >= repair_cost:
				w.hp = w.max_hp
				hero["coins"] -= repair_cost
				_track_coin_spent(repair_cost)
				walls[wall_selected_index] = w


	if keep_wall_menu_open:
		keep_wall_menu_open = false

		var saved_pos = wall_menu.get_meta("last_position", get_viewport().get_mouse_position())
		call_deferred("_show_wall_menu", wall_selected_index, Vector2.ZERO)

func _get_wall_tooltip(w: Dictionary) -> String:
	var hp = w.get("hp", 0.0)
	var max_hp = w.get("max_hp", _cfg().get_float("WALL_BASE_HP"))
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

	var dropdown_container = VBoxContainer.new()
	dropdown_container.add_theme_constant_override("separation", 0)


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


	var upgrade_container = VBoxContainer.new()
	upgrade_container.name = "MineUpgradeContent"
	upgrade_container.add_theme_constant_override("separation", 5)
	upgrade_container.visible = true


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


	dropdown_container.add_child(upgrade_container)


	toggle_button.set_meta("is_expanded", true)
	toggle_button.pressed.connect(func():
		var is_expanded = toggle_button.get_meta("is_expanded", true)
		is_expanded = not is_expanded
		toggle_button.set_meta("is_expanded", is_expanded)
		upgrade_container.visible = is_expanded
		toggle_button.text = "▼ Upgrades de Minas (Global)" if is_expanded else "▶ Upgrades de Minas (Global)"
	)


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


	var damage_panel = container.get_child(0)
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
					if mine_damage_level >= _cfg().get_int("MINE_UPGRADE_DAMAGE_MAX_LEVEL"):
						damage_cost_label.text = "MAX"
						damage_cost_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
				var damage_btn = damage_hbox.get_child(1)
				if damage_btn:
					damage_btn.disabled = mine_damage_level >= GameConstants.MINE_UPGRADE_DAMAGE_MAX_LEVEL or hero["coins"] < get_mine_upgrade_damage_cost()


	var radius_panel = container.get_child(1)
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
					if mine_radius_level >= _cfg().get_int("MINE_UPGRADE_RADIUS_MAX_LEVEL"):
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
		"Torre Antiaérea":
			return "Prioriza inimigos voadores. Causa menos dano em inimigos no chão."
		"Mercado de Esmeraldas":
			return "Loja de itens especiais pagos com esmeraldas."
		_:
			return ""

func _on_shop_button_hover(tower_name: String) -> void:
	if tooltip_label == null:
		return
	var shop_tooltip_text = _get_shop_tooltip_text(tower_name)
	for tower_button_data in tower_buttons:
		var info = tower_button_data.tower_info
		if str(info.get("name", "")) != tower_name:
			continue
		var catalog_id: String = str(info.get("catalog_id", ""))
		if not catalog_id.is_empty() and not _is_structure_unlocked(catalog_id):
			var unlock_wave := _structure_unlock_wave(catalog_id)
			var lock_line := "Desbloqueia na onda %d" % unlock_wave
			shop_tooltip_text = lock_line if shop_tooltip_text.is_empty() else "%s\n\n%s" % [lock_line, shop_tooltip_text]
		break
	if shop_tooltip_text != "":
		tooltip_label.text = shop_tooltip_text
		tooltip_label.visible = true

func _on_shop_button_unhover() -> void:
	if tooltip_label:
		tooltip_label.visible = false


func _create_game_background() -> void:
	"""Fundo do labirinto: imagem clipada na área do maze e escurecida."""
	if game_background_layer != null:
		return
	game_background_layer = CanvasLayer.new()
	game_background_layer.name = "GameBackgroundLayer"
	game_background_layer.layer = -1
	game_background_texture = TextureRect.new()
	game_background_texture.name = "GameBackgroundTexture"
	game_background_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	game_background_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	game_background_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_background_texture.clip_contents = true
	game_background_texture.visible = false
	game_background_dim = ColorRect.new()
	game_background_dim.name = "GameBackgroundDim"
	game_background_dim.color = Color(0.02, 0.03, 0.05, 0.55)
	game_background_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_background_layer.add_child(game_background_texture)
	game_background_layer.add_child(game_background_dim)
	add_child(game_background_layer)
	_layout_game_background()

func _layout_game_background() -> void:
	var bar_height: float = GameConstants.UI_TOP_BAR_HEIGHT
	var map_width := float(_cfg().get_int("GRID_COLS") * _cfg().get_int("TILE_SIZE"))
	var map_height := float(_cfg().get_int("GRID_ROWS") * _cfg().get_int("TILE_SIZE"))
	var maze_rect := Rect2(0.0, bar_height, map_width, map_height)
	if game_background_texture != null:
		game_background_texture.set_anchors_preset(Control.PRESET_TOP_LEFT)
		game_background_texture.position = maze_rect.position
		game_background_texture.size = maze_rect.size
	if game_background_dim != null:
		game_background_dim.set_anchors_preset(Control.PRESET_TOP_LEFT)
		game_background_dim.position = maze_rect.position
		game_background_dim.size = maze_rect.size

func _pause_btn(node_name: String) -> Node:
	if pause_overlay == null:
		return null
	return pause_overlay.find_child(node_name, true, false)

func _layout_pause_menu(_pause_panel: Panel) -> void:
	var title = _pause_btn("Title")
	if title:
		title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
		title.add_theme_font_size_override("font_size", 28)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var vbox = _pause_btn("VBox")
	if vbox is VBoxContainer:
		vbox.clip_contents = true
		vbox.add_theme_constant_override("separation", 12)
	var kinds := {
		"BtnResume": UIHelper.BTN_PRIMARY,
		"BtnQuit": UIHelper.BTN_DANGER
	}
	for child_name in ["BtnResume", "BtnOptions", "BtnDPSPause", "BtnSave", "BtnLoad", "BtnMenuMain", "BtnQuit"]:
		var node = _pause_btn(child_name)
		if node is Button:
			node.custom_minimum_size = Vector2(0, 44)
			node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			UIHelper.apply_button_theme(node, kinds.get(child_name, UIHelper.BTN_SECONDARY))
	var status = _pause_btn("SaveStatusLabel")
	if status:
		status.add_theme_font_size_override("font_size", 14)
		status.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _hud_find(root: Node, node_name: String) -> Node:
	if root == null:
		return null
	if root.name == node_name:
		return root
	return root.find_child(node_name, true, false)

func _hud_reparent(node: Node, new_parent: Node) -> void:
	if node == null or new_parent == null or node.get_parent() == new_parent:
		return
	if node.get_parent():
		node.get_parent().remove_child(node)
	new_parent.add_child(node)

func _hud_reset_for_box(ctrl: Control) -> void:
	ctrl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ctrl.anchor_left = 0
	ctrl.anchor_top = 0
	ctrl.anchor_right = 0
	ctrl.anchor_bottom = 0
	ctrl.offset_left = 0
	ctrl.offset_top = 0
	ctrl.offset_right = 0
	ctrl.offset_bottom = 0
	ctrl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ctrl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

func _setup_top_bar_layout(tb: Panel) -> void:
	if tb == null or tb.has_node("HudMargin"):
		return
	var margin := UIHelper.padded_margin(14, 8, 14, 8)
	margin.name = "HudMargin"
	var row := HBoxContainer.new()
	row.name = "HudRow"
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var stats := HBoxContainer.new()
	stats.name = "StatsRow"
	stats.add_theme_constant_override("separation", 14)
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.alignment = BoxContainer.ALIGNMENT_BEGIN
	var actions := HBoxContainer.new()
	actions.name = "ActionsRow"
	actions.add_theme_constant_override("separation", 8)
	actions.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(stats)
	row.add_child(actions)
	margin.add_child(row)
	tb.add_child(margin)

	for child_name in ["BtnKillAll", "BtnBuyTower", "BtnBuyBlock", "BtnBuyBarracks"]:
		var leftover = tb.get_node_or_null(child_name)
		if leftover:
			leftover.visible = false

	var hp_box := HBoxContainer.new()
	hp_box.name = "HpBox"
	hp_box.add_theme_constant_override("separation", 8)
	hp_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	for child_name in ["LblLeft", "LblCenter", "LblEmeralds", "LblDiamonds"]:
		var node = tb.get_node_or_null(child_name)
		if node is Control:
			_hud_reset_for_box(node)
			_hud_reparent(node, stats)

	var lbl_right = tb.get_node_or_null("LblRight")
	if lbl_right is Control:
		_hud_reset_for_box(lbl_right)
		_hud_reparent(lbl_right, hp_box)
	var hp_bar = tb.get_node_or_null("BaseHPBar")
	if hp_bar is Control:
		_hud_reset_for_box(hp_bar)
		hp_bar.custom_minimum_size = Vector2(120, 16)
		_hud_reparent(hp_bar, hp_box)
	stats.add_child(hp_box)

	var buff_label = tb.get_node_or_null("LblBuffs")
	if buff_label == null:
		buff_label = Label.new()
		buff_label.name = "LblBuffs"
		buff_label.add_theme_font_size_override("font_size", 13)
		buff_label.add_theme_color_override("font_color", Color(0.85, 0.55, 1.0))
		buff_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		buff_label.visible = false
	_hud_reset_for_box(buff_label)
	_hud_reparent(buff_label, stats)

	for child_name in ["BtnAdmin", "BtnDPS"]:
		var btn = tb.get_node_or_null(child_name)
		if btn is Control:
			_hud_reset_for_box(btn)
			btn.custom_minimum_size = Vector2(max(btn.custom_minimum_size.x, 56), 32)
			_hud_reparent(btn, actions)
			if btn is Button:
				if child_name == "BtnDPS":
					UIHelper.apply_button_theme(btn, UIHelper.BTN_SECONDARY)

func _setup_bottom_bar_layout(bottom_bar: Panel) -> void:
	if bottom_bar == null or bottom_bar.has_node("HudMargin"):
		return
	var margin := UIHelper.padded_margin(14, 8, 16, 8)
	margin.name = "HudMargin"
	var row := HBoxContainer.new()
	row.name = "StatusRow"
	row.add_theme_constant_override("separation", 18)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for child_name in ["LblTime", "LblEnemies", "LblFPS"]:
		var lbl = bottom_bar.get_node_or_null(child_name)
		if lbl is Control:
			_hud_reset_for_box(lbl)
			_hud_reparent(lbl, row)
	margin.add_child(row)
	bottom_bar.add_child(margin)

func _adjust_hud_to_screen_size() -> void:
	"""Ajusta a HUD para ser responsiva ao tamanho da tela"""
	var viewport = get_viewport()
	if viewport == null:
		return

	var screen_size = viewport.get_visible_rect().size

	_layout_game_background()

	var hud = $CanvasLayer/HUD
	if hud == null:
		return

	hud.layout_mode = 1
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.offset_left = 0.0
	hud.offset_right = 0.0
	hud.offset_top = 0.0
	hud.offset_bottom = 0.0
	hud.size = screen_size
	hud.position = Vector2.ZERO

	var maze_width := float(_cfg().get_int("GRID_COLS") * _cfg().get_int("TILE_SIZE"))
	var bottom_bar = hud.get_node_or_null("BottomBar")
	if bottom_bar:
		var bar_w = min(maze_width - 20.0, 430.0)
		if skills_panel and skills_panel.visible:
			bar_w = min(bar_w, max(220.0, skills_panel.position.x - 24.0))
		bottom_bar.layout_mode = 1
		bottom_bar.anchor_left = 0.0
		bottom_bar.anchor_top = 1.0
		bottom_bar.anchor_right = 0.0
		bottom_bar.anchor_bottom = 1.0
		bottom_bar.offset_left = 10.0
		bottom_bar.offset_right = 10.0 + bar_w
		bottom_bar.offset_top = -(GameConstants.UI_BOTTOM_BAR_HEIGHT + 10.0)
		bottom_bar.offset_bottom = -10.0
		bottom_bar.z_index = 20

	var tb = hud.get_node_or_null("TopBar")
	if tb == null:
		return
	tb.z_index = 100
	tb.layout_mode = 1
	tb.set_anchors_preset(Control.PRESET_TOP_WIDE)
	tb.offset_left = 0.0
	tb.offset_right = 0.0
	tb.offset_top = 0.0
	tb.offset_bottom = GameConstants.UI_TOP_BAR_HEIGHT
	_update_base_hp_display()

func _update_base_hp_display() -> void:
	"""Atualiza a barra de vida da base e o label no TopBar."""
	var tb = $CanvasLayer/HUD.get_node_or_null("TopBar")
	if not tb:
		return
	if base_hp_progress_bar != null:
		base_hp_progress_bar.max_value = max(1, base_hp_max)
		base_hp_progress_bar.value = base_hp
	var lbl_right = _hud_find(tb, "LblRight")
	if lbl_right:
		lbl_right.text = "❤️ %d" % [base_hp]
		lbl_right.visible = true

func _update_bottom_bar() -> void:
	"""Atualiza a HUD inferior com informações secundárias"""
	var hud = $CanvasLayer/HUD
	if not hud:
		return

	var bottom_bar = hud.get_node_or_null("BottomBar")
	if not bottom_bar:
		return

	var time_label = _hud_find(bottom_bar, "LblTime")
	if time_label:
		var minutes = int(game_time / 60.0)
		var seconds = int(game_time) % 60
		time_label.text = "Tempo: %02d:%02d" % [minutes, seconds]

	var enemies_label = _hud_find(bottom_bar, "LblEnemies")
	if enemies_label:
		enemies_label.text = "Inimigos: %d" % enemies.size()

	var fps_label = _hud_find(bottom_bar, "LblFPS")
	if fps_label:
		fps_label.visible = show_fps_enabled
		if show_fps_enabled:
			var fps = Engine.get_frames_per_second()
			fps_label.text = "FPS: %d" % fps

	var top_bar = hud.get_node_or_null("TopBar")
	if top_bar:
		var buff_label = _hud_find(top_bar, "LblBuffs")
		if buff_label == null:
			return
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
			buff_label.add_theme_color_override("font_color", Color(0.85, 0.55, 1.0))

func _on_viewport_size_changed() -> void:
	"""Chamado quando o tamanho da viewport muda (incluindo tela cheia)"""
	call_deferred("_adjust_hud_to_screen_size")
	call_deferred("_adjust_shop_and_skills_panels")
	var tb = $CanvasLayer/HUD.get_node_or_null("TopBar")
	if tb:
		_update_base_hp_display()


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
	var scroll = _hud_find(tower_shop_panel, "TowerScroll")
	if scroll != null:
		scroll.visible = !tower_shop_collapsed
	if tooltip_label != null:
		tooltip_label.visible = false
	var title_label = _hud_find(tower_shop_panel, "TitleLabel")
	if title_label != null:
		if tower_shop_collapsed:
			title_label.text = "LOJA"
			title_label.add_theme_font_size_override("font_size", 14)
		else:
			title_label.text = "LOJA DE TORRES"
			title_label.add_theme_font_size_override("font_size", 17)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if tower_shop_toggle_button != null:
		tower_shop_toggle_button.visible = true
		tower_shop_toggle_button.text = "◄" if tower_shop_collapsed else "►"
		tower_shop_toggle_button.tooltip_text = "Clique para expandir" if tower_shop_collapsed else "Clique para recolher"
	tower_shop_panel.add_theme_stylebox_override("panel", UIHelper.side_panel_style(tower_shop_collapsed))

func _update_skills_panel_collapse() -> void:
	"""Atualiza a UI do painel de skills baseado no estado de colapso"""
	if skills_panel == null:
		return
	var scroll = _hud_find(skills_panel, "SkillsScroll")
	if scroll != null:
		scroll.visible = !skills_panel_collapsed
	var title_label = _hud_find(skills_panel, "TitleLabel")
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 14 if skills_panel_collapsed else 17)
	if skills_panel_toggle_button != null:
		skills_panel_toggle_button.visible = true
		skills_panel_toggle_button.text = "◄" if skills_panel_collapsed else "►"
		skills_panel_toggle_button.tooltip_text = "Clique para expandir" if skills_panel_collapsed else "Clique para recolher"
	skills_panel.add_theme_stylebox_override("panel", UIHelper.side_panel_style(skills_panel_collapsed))

func _adjust_shop_and_skills_panels() -> void:
	"""Ajusta os painéis da loja e skills para serem responsivos ao tamanho da tela"""
	var viewport = get_viewport()
	if viewport == null:
		return
	var screen_width = viewport.get_visible_rect().size.x
	var screen_height = viewport.get_visible_rect().size.y
	var min_screen_width = 1710.0
	var top = GameConstants.UI_TOP_BAR_HEIGHT
	var gap = GameConstants.UI_SIDE_PANEL_GAP

	if tower_shop_panel != null:
		var panel_width = 380.0 if not tower_shop_collapsed else 96.0
		if screen_width < min_screen_width and not tower_shop_collapsed:
			panel_width = min(panel_width, screen_width * 0.25)
		var x_pos = screen_width - panel_width
		if tower_shop_collapsed and x_pos < 700.0:
			x_pos = max(650.0, screen_width - panel_width)
		tower_shop_panel.position = Vector2(x_pos, top)
		tower_shop_panel.size = Vector2(panel_width, screen_height - top)
		_update_tower_shop_collapse()

	_update_base_hp_display()

	if skills_panel != null:
		var panel_width = 390.0 if not skills_panel_collapsed else 96.0
		var tower_panel_width = tower_shop_panel.size.x if tower_shop_panel else 80.0
		if screen_width < min_screen_width and not skills_panel_collapsed:
			var available_width = screen_width - tower_panel_width - 100
			panel_width = min(panel_width, max(available_width * 0.3, 250.0))
		var x_pos = screen_width - tower_panel_width - panel_width - gap
		if skills_panel_collapsed and x_pos < 700.0:
			x_pos = max(600.0, screen_width - tower_panel_width - panel_width - gap)
		if x_pos < 0:
			x_pos = 0
			if not skills_panel_collapsed:
				panel_width = max(250.0, screen_width - tower_panel_width - gap - 10)
		skills_panel.position = Vector2(x_pos, top)
		skills_panel.size = Vector2(panel_width, screen_height - top)
		_update_skills_panel_collapse()

func _get_tower_id(tower: Dictionary, tower_type: String) -> String:
	"""Gera um ID único para uma torre baseado em sua posição e tipo"""
	return "%s_%d_%d" % [tower_type, int(tower.pos.x), int(tower.pos.y)]

func _calculate_tower_dps(tower: Dictionary, _tower_type: String) -> float:
	"""Calcula o DPS teórico de uma torre baseado em dano e fire_rate"""
	var damage = tower.get("damage", _cfg().get_float("TOWER_BASE_DAMAGE"))
	var fire_rate = tower.get("fire_rate", 1.5)
	var dirs_count = tower.get("dirs", [Vector2(1, 0)]).size()


	damage *= global_tower_damage_boost


	var damage_multiplier = 1.0 + _boost_damage_bonus(tower.pos)
	var rate_multiplier = 1.0 + _boost_rate_bonus(tower.pos)


	if skills_manager:
		damage_multiplier *= skills_manager.get_damage_multiplier()


	if skills_manager:
		rate_multiplier *= skills_manager.get_speed_multiplier()
	rate_multiplier *= _get_bonus_fire_rate_multiplier()

	damage *= damage_multiplier
	var effective_fire_rate = _calc_effective_fire_rate(fire_rate, rate_multiplier)


	if effective_fire_rate > 0:
		return (damage * dirs_count) / effective_fire_rate
	return 0.0

func _calculate_sniper_dps(sniper: Dictionary) -> float:
	"""Calcula o DPS teórico de uma sniper tower"""
	var damage = sniper.get("damage", 2.0)
	var fire_rate = sniper.get("fire_rate", 2.0)


	damage *= global_tower_damage_boost


	var damage_multiplier = 1.0 + _boost_damage_bonus(sniper.pos)
	var rate_multiplier = 1.0 + _boost_rate_bonus(sniper.pos)
	damage_multiplier *= _combo_bonus_for(sniper.pos, "sniper_tower").damage_multiplier


	if skills_manager:
		damage_multiplier *= skills_manager.get_damage_multiplier()


	if skills_manager:
		rate_multiplier *= skills_manager.get_speed_multiplier()
	rate_multiplier *= _get_bonus_fire_rate_multiplier()

	damage *= damage_multiplier
	var effective_fire_rate = _calc_effective_fire_rate(fire_rate, rate_multiplier)


	if effective_fire_rate > 0:
		return damage / effective_fire_rate
	return 0.0

func _calculate_aoe_dps(aoe: Dictionary) -> float:
	"""Calcula o DPS teórico de uma AOE tower"""
	var damage = aoe.get("damage", 1.0)
	var fire_rate = aoe.get("fire_rate", 1.5)


	damage *= global_tower_damage_boost


	var damage_multiplier = 1.0 + _boost_damage_bonus(aoe.pos)
	var rate_multiplier = 1.0 + _boost_rate_bonus(aoe.pos)
	damage_multiplier *= _combo_bonus_for(aoe.pos, "aoe_tower").damage_multiplier


	if skills_manager:
		damage_multiplier *= skills_manager.get_damage_multiplier()


	if skills_manager:
		rate_multiplier *= skills_manager.get_speed_multiplier()
	rate_multiplier *= _get_bonus_fire_rate_multiplier()

	damage *= damage_multiplier
	var effective_fire_rate = _calc_effective_fire_rate(fire_rate, rate_multiplier)


	if effective_fire_rate > 0:
		return damage / effective_fire_rate
	return 0.0

func _calculate_anti_air_dps(anti_air: Dictionary) -> float:
	"""Calcula o DPS teórico de uma anti-air tower"""
	var damage = anti_air.get("damage", 3.0)
	var fire_rate = anti_air.get("fire_rate", 2.5)
	var missile_count = anti_air.get("missile_count", 3)


	damage *= global_tower_damage_boost


	var damage_multiplier = 1.0 + _boost_damage_bonus(anti_air.pos)
	var rate_multiplier = 1.0 + _boost_rate_bonus(anti_air.pos)


	if skills_manager:
		damage_multiplier *= skills_manager.get_damage_multiplier()


	if skills_manager:
		rate_multiplier *= skills_manager.get_speed_multiplier()
	rate_multiplier *= _get_bonus_fire_rate_multiplier()

	damage *= damage_multiplier
	var effective_fire_rate = _calc_effective_fire_rate(fire_rate, rate_multiplier)


	if effective_fire_rate > 0:
		return (damage * missile_count) / effective_fire_rate
	return 0.0

func _calculate_shock_dps(shock: Dictionary) -> float:
	"""Calcula o DPS teórico de uma shock tower"""
	var damage = shock.get("damage", _cfg().get_float("TOWER_BASE_DAMAGE"))
	var fire_rate = shock.get("fire_rate", 1.0)
	var chain_count = shock.get("chain_count", 1)


	damage *= global_tower_damage_boost


	var damage_multiplier = 1.0 + _boost_damage_bonus(shock.pos)
	var rate_multiplier = 1.0 + _boost_rate_bonus(shock.pos)
	damage_multiplier *= _combo_bonus_for(shock.pos, "shock_tower").damage_multiplier


	if skills_manager:
		damage_multiplier *= skills_manager.get_damage_multiplier()


	if skills_manager:
		rate_multiplier *= skills_manager.get_speed_multiplier()
	rate_multiplier *= _get_bonus_fire_rate_multiplier()

	damage *= damage_multiplier
	var effective_fire_rate = _calc_effective_fire_rate(fire_rate, rate_multiplier)


	if effective_fire_rate > 0:
		return (damage * chain_count) / effective_fire_rate
	return 0.0

func _calculate_barracks_dps(barracks_item: Dictionary) -> float:
	"""Calcula o DPS teórico de um quartel baseado nos soldados"""
	var soldier_damage = barracks_item.get("damage", 1.0)
	var soldier_spawn_rate = barracks_item.get("soldier_spawn_rate", 3.0)
	var hold_time = barracks_item.get("hold_time", _cfg().get_float("BARRACKS_INITIAL_HOLD_TIME"))


	soldier_damage *= global_tower_damage_boost


	var damage_multiplier = 1.0 + _boost_damage_bonus(barracks_item.pos)
	damage_multiplier *= _combo_bonus_for(barracks_item.pos, "barracks").damage_multiplier


	if skills_manager:
		damage_multiplier *= skills_manager.get_damage_multiplier()

	soldier_damage *= damage_multiplier





	var max_active_soldiers = max(1.0, hold_time / soldier_spawn_rate)



	return soldier_damage * max_active_soldiers

func _update_tower_dps(_delta: float) -> void:
	"""Atualiza o DPS calculado de todas as torres"""


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


	var valid_ids = []
	for tower in towers:
		valid_ids.append(_get_tower_id(tower, "tower"))
	for sniper in sniper_towers:
		valid_ids.append(_get_tower_id(sniper, "sniper"))
	for aoe in aoe_towers:
		valid_ids.append(_get_tower_id(aoe, "aoe"))
	for shock in shock_towers:
		valid_ids.append(_get_tower_id(shock, "shock"))
	for anti_air in anti_air_towers:
		valid_ids.append(_get_tower_id(anti_air, "anti_air"))

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


	dps_menu_panel = Panel.new()
	dps_menu_panel.name = "DPSMenuPanel"
	dps_menu_panel.custom_minimum_size = Vector2(350, 400)
	dps_menu_panel.add_theme_stylebox_override("panel", UIHelper.panel_style())
	dps_menu_panel.position = Vector2(24, GameConstants.UI_TOP_BAR_HEIGHT + 16)
	dps_menu_panel.visible = false
	dps_menu_panel.z_index = 50


	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 5)


	var title_hbox = HBoxContainer.new()
	var title_label = Label.new()
	title_label.text = "DPS das Torres"
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hbox.add_child(title_label)


	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(36, 32)
	close_btn.pressed.connect(func(): _toggle_dps_menu())
	UIHelper.apply_button_theme(close_btn, UIHelper.BTN_SECONDARY)
	title_hbox.add_child(close_btn)

	main_vbox.add_child(title_hbox)


	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(330, 350)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED


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


	var content_vbox = null
	if scroll.get_child_count() > 0:
		var margin_container = scroll.get_child(0)
		if margin_container is MarginContainer:

			content_vbox = margin_container.get_node_or_null("DPSContent")
			if content_vbox == null and margin_container.get_child_count() > 0:
				content_vbox = margin_container.get_child(0)
				if content_vbox.name != "DPSContent":
					content_vbox.name = "DPSContent"

	if content_vbox == null:
		print("DPS Menu: ERRO - DPSContent não encontrado!")
		return


	for child in content_vbox.get_children():
		child.queue_free()



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

		var tower_damage = tower.get("damage", _cfg().get_float("TOWER_BASE_DAMAGE"))
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

	for anti_air in anti_air_towers:
		var tower_id = _get_tower_id(anti_air, "anti_air")
		if not tower_dps_data.has(tower_id):
			tower_dps_data[tower_id] = {
				"dps": 0.0,
				"damage_dealt": 0.0,
				"shots": 0,
				"wave_damage": {},
				"tower_type": "anti_air",
				"pos": anti_air.pos
			}
		tower_dps_data[tower_id]["dps"] = _calculate_anti_air_dps(anti_air)
		tower_dps_data[tower_id]["tower_type"] = "anti_air"
		tower_dps_data[tower_id]["pos"] = anti_air.pos


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


	var grouped_towers: Dictionary = {}
	var type_names = {
		"tower": "Torre",
		"sniper": "Sniper",
		"aoe": "AOE",
		"shock": "Shock",
		"anti_air": "Anti-Aérea",
		"barracks": "Quartel"
	}


	var current_wave = wave_manager.wave if wave_manager else 0
	var last_wave = current_wave - 1 if current_wave > 0 else 0


	for tower_id in tower_dps_data.keys():
		var data = tower_dps_data[tower_id]
		var tower_type = data.get("tower_type", "unknown")
		var dps_value = data.get("dps", 0.0)


		if not grouped_towers.has(tower_type):
			grouped_towers[tower_type] = {
				"total_dps": 0.0,
				"total_wave_damage": 0.0,
				"count": 0
			}


		grouped_towers[tower_type]["total_dps"] += dps_value
		grouped_towers[tower_type]["count"] += 1


		var wave_damage = 0.0
		if data.has("wave_damage"):
			wave_damage = data["wave_damage"].get(last_wave, 0.0)
		grouped_towers[tower_type]["total_wave_damage"] += wave_damage


	var type_order = ["tower", "sniper", "aoe", "shock", "anti_air", "barracks"]
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


		var type_label = Label.new()
		var count_text = " (%d)" % group_info.count if group_info.count > 1 else ""
		type_label.text = group_info.name + count_text
		type_label.custom_minimum_size = Vector2(80, 0)
		type_label.add_theme_font_size_override("font_size", 13)
		type_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
		hbox.add_child(type_label)


		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 4)


		var dps_label = Label.new()
		var dps_display = group_info.total_dps
		if dps_display < 0.01:
			dps_display = 0.0
		dps_label.text = "DPS Total: %.1f" % dps_display
		dps_label.add_theme_font_size_override("font_size", 14)
		dps_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
		info_vbox.add_child(dps_label)


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

		if has_node("DPSUpdateTimer"):
			var timer = get_node("DPSUpdateTimer")
			timer.stop()
