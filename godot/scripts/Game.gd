extends Node2D

# Pré-carregar classes
const GridManager = preload("res://scripts/GridManager.gd")
const Pathfinder = preload("res://scripts/Pathfinder.gd")
const WaveManager = preload("res://scripts/WaveManager.gd")
const ProjectileManager = preload("res://scripts/ProjectileManager.gd")
const GameConstants = preload("res://scripts/Constants.gd")
const SaveManager = preload("res://scripts/managers/SaveManager.gd")
const AchievementManager = preload("res://scripts/managers/AchievementManager.gd")
const PerkManager = preload("res://scripts/managers/PerkManager.gd")

# Managers
var grid_manager: GridManager
var pathfinder: Pathfinder
var wave_manager: WaveManager
var projectile_manager: ProjectileManager
var achievement_manager: AchievementManager
var perk_manager: PerkManager

# Estatísticas para achievements
var total_kills: int = 0
var total_boss_kills: int = 0
var total_coins_collected: int = 0
var total_coins_spent: int = 0
var towers_built: int = 0
var tower_types_built: Dictionary = {}  # rastrear tipos de torres construídas
var perfect_waves: int = 0
var current_wave_base_hp_start: int = 0  # HP da base no início da onda
var first_play: bool = true
var skill_used: bool = false
var maxed_towers_count: int = 0  # Contador de torres maximizadas
var walls_built: int = 0  # Contador de muros construídos

# Efeitos de perks aplicados
var perk_effects: Dictionary = {}  # armazena efeitos dos perks
var coin_drop_chance: float = GameConstants.COIN_DROP_CHANCE  # chance de drop com perks aplicados

var grid_offset: Vector2  # offset para centralizar o grid na tela

var enemies: Array = []
var arrows: Array = []  # TODO: migrar para projectile_manager
var tower_bullets: Array = []  # TODO: migrar para projectile_manager
var aoe_effects: Array = []  # efeitos visuais de explosão AOE: {pos: Vector2, time: float, max_time: float}
var sniper_effects: Array = []  # efeitos visuais de tiro sniper: {start: Vector2, end: Vector2, time: float, max_time: float}
var aoe_cannon_projectiles: Array = []  # projéteis de canhão AOE: {pos: Vector2, target: Vector2, speed: float, radius: float}
var dropped_coins: Array = []  # moedas dropadas: {pos: Vector2, value: int, lifetime: float, max_lifetime: float, collected: bool}
var coin_collect_effects: Array = []  # efeitos visuais de coleta de moedas: {pos: Vector2, time: float, max_time: float, particles: Array}
var damage_numbers: Array = []  # indicadores de dano flutuantes: {pos: Vector2, value: float, time: float, max_time: float, is_crit: bool}
var enemy_death_animations: Array = []  # animações de morte: {pos: Vector2, time: float, max_time: float, scale: float, alpha: float}
var shock_effects: Array = []  # efeitos visuais de choque elétrico: {start: Vector2, end: Vector2, time: float, max_time: float}

var base_hp := 100
var paused := false
var game_over := false

# Flag para modo admin (testes/debug) - desabilitar em produção
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

var towers: Array = []
var barracks: Array = []  # quartéis - cada quartel: {grid_x: int, grid_y: int, pos: Vector2, soldier_spawn_cd: float, soldiers: Array}
var mines: Array = []  # minas: {grid_x: int, grid_y: int, pos: Vector2, damage: float, triggered: bool}
var slow_towers: Array = []  # slow towers: {grid_x: int, grid_y: int, pos: Vector2, range: float, slow_amount: float, cooldown: float, fire_rate: float}
var aoe_towers: Array = []  # AOE towers: {grid_x: int, grid_y: int, pos: Vector2, range: float, damage: float, aoe_radius: float, cooldown: float, fire_rate: float}
var sniper_towers: Array = []  # sniper towers: {grid_x: int, grid_y: int, pos: Vector2, range: float, damage: float, cooldown: float, fire_rate: float, pierce: int}
var boost_towers: Array = []  # boost towers: {grid_x: int, grid_y: int, pos: Vector2, range: float, damage_boost: float, rate_boost: float, levels: Dictionary}
var shock_towers: Array = []  # shock towers: {grid_x: int, grid_y: int, pos: Vector2, range: float, damage: float, chain_count: int, cooldown: float, fire_rate: float}
var walls: Array = []  # walls: {grid_x: int, grid_y: int, pos: Vector2, hp: float, max_hp: float}
var healing_stations: Array = []  # healing stations: {grid_x: int, grid_y: int, pos: Vector2, heal_rate: float, range: float}
# base_grid agora está em grid_manager
var preview_mouse_pos := Vector2.ZERO  # posição do mouse para preview
var soldiers: Array = []  # soldados: {pos: Vector2, target_enemy_idx: int, hold_time: float, max_hold_time: float, damage: float, hp: float, max_hp: float, radius: float}

# Constantes de upgrade agora em GameConstants
var tower_menu: PopupMenu
var tower_selected_index := -1
var placing_tower_dir := Vector2(1, 0)  # direção inicial ao colocar torre

# Constantes de barracks agora em GameConstants
var barracks_menu: PopupMenu
var barracks_selected_index := -1

# Menus de upgrade para sniper, AOE, Shock, Slow e Boost
var sniper_menu: PopupMenu
var sniper_selected_index := -1
var aoe_menu: PopupMenu
var aoe_selected_index := -1
var shock_menu: PopupMenu
var shock_selected_index := -1
var slow_menu: PopupMenu
var slow_selected_index := -1
var boost_menu: PopupMenu
var boost_selected_index := -1

# Drag and drop state
var dragging_tower := false
var dragged_tower_type := ""  # "tower", "slow_tower", "aoe_tower", "sniper_tower", "boost_tower", "shock_tower"
var dragged_tower_index := -1
var drag_start_pos: Vector2 = Vector2.ZERO
var drag_offset: Vector2 = Vector2.ZERO
var drag_current_pos: Vector2 = Vector2.ZERO

# enemy status effects
var enemy_effects: Dictionary = {}  # enemy_idx -> {freeze_time: float, fire_time: float, fire_damage: float}

# textures (opcionais)
var tex_hero: Texture2D
var tex_enemy_zombie: Texture2D
var tex_enemy_humanoid: Texture2D
var tex_enemy_robot: Texture2D
var tex_tent: Texture2D  # Base/tenda no centro
var tex_house: Texture2D
var tex_castle: Texture2D
var tex_grass: Texture2D
var tex_path: Texture2D  # Textura para o caminho (chão onde inimigos andam)
var tex_wall: Texture2D  # Textura para barreira/cerca (paredes do labirinto)
var tex_tower: Texture2D  # Torre normal
var tex_slow_tower: Texture2D  # Slow Tower
var tex_aoe_tower: Texture2D  # AOE Tower
var tex_sniper_tower: Texture2D  # Sniper Tower
var tex_boost_tower: Texture2D  # Boost Tower
var tex_shock_tower: Texture2D  # Shock Tower
var tex_barracks: Texture2D  # Quartel
var tex_mine: Texture2D  # Mina
var tex_wall_structure: Texture2D  # Muralha/barreira
var tex_healing_station: Texture2D  # Estação de cura
var tex_coin: Texture2D  # Moeda dropada

# Tela de carregamento
var loading_screen: Control
var loading_progress: float = 0.0
var is_loading: bool = true

# UI melhorada
var tower_shop_panel: Panel
var tower_buttons: Array = []
var tooltip_label: Label
var hovered_tower_button: Control = null
var music_muted: bool = false

# Menu de admin (testes/debug)
var admin_menu: PopupMenu
var admin_menu_button: Button

# Range indicator
var range_indicator: Line2D
const RANGE_INDICATOR_SEGMENTS := 64

# Boss alert
var boss_alert_label: Label
var boss_alert_timer: float = 0.0
var boss_alert_duration: float = 4.0
var boss_warning_sound: AudioStream
var boss_alert_player: AudioStreamPlayer

# Menu de pause
var pause_overlay: Control
var save_status_label: Label

# Skills system
var skills_panel: Panel
var skill_damage_boost_active: bool = false
var skill_damage_boost_time: float = 0.0
var skill_speed_boost_active: bool = false
var skill_speed_boost_time: float = 0.0
var skill_collect_coins_cooldown: float = 0.0
var skill_damage_boost_cooldown: float = 0.0
var skill_speed_boost_cooldown: float = 0.0
var skill_slow_all_cooldown: float = 0.0
var skill_slow_all_active: bool = false
var skill_slow_all_time: float = 0.0
var skill_buttons: Dictionary = {}  # Armazenar referências aos botões para atualizar cooldown

# Wave management agora em wave_manager
func _wave_factor() -> float:
	return wave_manager.wave_factor()

# upgrades overlay state
var choosing_upgrade := false
var benefit_applied := false
var upgrade_options := [
	{"label": "+1 Dano", "code": "DMG"},
	{"label": "+Cadência", "code": "FIRERATE"},
	{"label": "+1 Perfuração", "code": "PIERCE"},
]

# hero
var hero := {
	"x": 0.0, "y": 0.0, "cooldown": 0.0, "fire_rate": GameConstants.HERO_BASE_FIRE_RATE,
	"damage": GameConstants.HERO_BASE_DAMAGE, "pierce": 0, "range": 9999.0,
	"levels": { "DMG": 0, "FIRERATE": 0, "PIERCE": 0 }, "coins": GameConstants.HERO_START_COINS,
}

const HERO_HOME_MAX_LEVEL := 3
var hero_home_level: int = 1
var hero_home_coin_bonus: float = 0.0
var hero_home_panel_data: Dictionary = {}
var hero_home_upgrade_costs := {
	2: 1200,
	3: 3000
}

func _get_hero_home_texture_for_level(level: int) -> Texture2D:
	match level:
		2:
			return tex_house if tex_house != null else tex_tent
		3:
			return tex_castle if tex_castle != null else (tex_house if tex_house != null else tex_tent)
		_:
			return tex_tent

func _get_hero_home_upgrade_cost(level: int) -> int:
	return hero_home_upgrade_costs.get(level, 0)

func _get_hero_home_benefits_text(level: int) -> String:
	match level:
		1:
			return "Nível inicial. Proteção básica da tenda."
		2:
			return "• Dano do herói +1\n• Alcance +100\n• Vida da base +40\n• +5% chance de moedas"
		3:
			return "• Dano do herói +2\n• +1 perfuração\n• Cadência -0.05s\n• Vida da base +60\n• +5% chance de moedas"
		_:
			return "Nível máximo alcançado"

func _apply_hero_home_coin_bonus_from_scratch() -> void:
	coin_drop_chance += hero_home_coin_bonus
	coin_drop_chance = clamp(coin_drop_chance, 0.0, 1.0)

func _apply_hero_home_upgrade_effects(level: int) -> void:
	match level:
		2:
			hero["damage"] += 1
			hero["range"] += 100
			base_hp += 40
			hero_home_coin_bonus += 0.05
			coin_drop_chance = min(coin_drop_chance + 0.05, 1.0)
		3:
			hero["damage"] += 2
			hero["pierce"] += 1
			hero["fire_rate"] = max(0.1, hero["fire_rate"] - 0.05)
			base_hp += 60
			hero_home_coin_bonus += 0.05
			coin_drop_chance = min(coin_drop_chance + 0.05, 1.0)


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

func _ready() -> void:
	# Criar tela de carregamento primeiro
	_create_loading_screen()
	
	# Inicializar managers
	grid_manager = GridManager.new()
	pathfinder = Pathfinder.new(grid_manager.grid, grid_manager.center)
	wave_manager = WaveManager.new()
	projectile_manager = ProjectileManager.new()
	achievement_manager = AchievementManager.get_instance()
	perk_manager = PerkManager.get_instance()
	
	# Aplicar efeitos dos perks
	_apply_perk_effects()
	
	# Conectar signal do wave_manager
	wave_manager.wave_started.connect(_on_wave_started)
	
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
	
	# aguardar um frame para viewport atualizar
	await get_tree().process_frame
	
	# posição fixa: grid começa em X=0 (alinhado à esquerda) e Y=bar_height (logo abaixo da barra)
	grid_offset = Vector2(0.0, bar_height)
	position = grid_offset

	var p = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
	hero["x"] = p.x
	hero["y"] = p.y

	# Atualizar progresso de carregamento
	_update_loading_progress(0.1)
	
	# tentar carregar assets Kenney se existirem
	tex_hero = _try_load("res://assets/images/hero.png")
	_update_loading_progress(0.15)
	
	# Carregar e processar sprites dos monstros (remover fundo branco)
	tex_enemy_zombie = _load_and_process_texture("res://assets/images/enemy_zombie.png")
	_update_loading_progress(0.25)
	tex_enemy_humanoid = _load_and_process_texture("res://assets/images/enemy_humanoid.png")
	_update_loading_progress(0.35)
	tex_enemy_robot = _load_and_process_texture("res://assets/images/enemy_robot.png")
	_update_loading_progress(0.45)
	
	# Carregar e processar todas as texturas (remover fundo branco)
	tex_tent = _load_and_process_texture("res://assets/images/tent.png")
	tex_house = _load_and_process_texture("res://assets/images/house.png")
	tex_castle = _load_and_process_texture("res://assets/images/castle.png")
	if tex_tent != null:
		print("Tenda carregada: ", tex_tent.get_width(), "x", tex_tent.get_height())
	_update_loading_progress(0.55)
	
	tex_grass = _try_load("res://assets/images/grass.png")
	tex_path = _try_load("res://assets/images/path.png")  # Textura do caminho
	tex_wall = _try_load("res://assets/images/wall.png")  # Textura da barreira/cerca (terreno)
	_update_loading_progress(0.65)
	
	# Texturas das torres e estruturas - todas processadas para remover fundo branco
	print("=== Carregando texturas de torres ===")
	tex_tower = _load_and_process_texture("res://assets/images/tower.png")
	_update_loading_progress(0.70)
	tex_slow_tower = _load_and_process_texture("res://assets/images/slow_tower.png")
	_update_loading_progress(0.75)
	tex_aoe_tower = _load_and_process_texture("res://assets/images/aoe_tower.png")
	_update_loading_progress(0.80)
	tex_sniper_tower = _load_and_process_texture("res://assets/images/sniper_tower.png")
	_update_loading_progress(0.85)
	tex_boost_tower = _load_and_process_texture("res://assets/images/boost_tower.png")
	_update_loading_progress(0.87)
	tex_shock_tower = _load_and_process_texture("res://assets/images/shock_tower.jpg")
	_update_loading_progress(0.90)
	tex_barracks = _load_and_process_texture("res://assets/images/barracks.png")
	tex_mine = _load_and_process_texture("res://assets/images/mine.png")
	tex_wall_structure = _load_and_process_texture("res://assets/images/wall_structure.png")
	tex_healing_station = _load_and_process_texture("res://assets/images/healing_station.png")
	tex_coin = _load_and_process_texture("res://assets/images/coin.png")  # Carregar e processar moeda (remover fundo branco)
	_update_loading_progress(1.0)
	
	# Aguardar um pouco antes de esconder a tela de carregamento
	await get_tree().create_timer(0.3).timeout
	_hide_loading_screen()

	# wire UI
	var tb = $CanvasLayer/HUD/TopBar
	
	# Melhorar design da top bar
	var top_bar_style = StyleBoxFlat.new()
	top_bar_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	top_bar_style.border_color = Color(0.3, 0.3, 0.4)
	top_bar_style.border_width_left = 0
	top_bar_style.border_width_top = 0
	top_bar_style.border_width_right = 0
	top_bar_style.border_width_bottom = 2
	tb.add_theme_stylebox_override("panel", top_bar_style)
	
	# Melhorar labels
	var lbl_left = tb.get_node("LblLeft")
	lbl_left.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	lbl_left.add_theme_font_size_override("font_size", 16)
	
	var lbl_center = tb.get_node("LblCenter")
	lbl_center.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	lbl_center.add_theme_font_size_override("font_size", 18)
	
	var lbl_right = tb.get_node("LblRight")
	lbl_right.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	lbl_right.add_theme_font_size_override("font_size", 16)
	
	# Menu de Admin (apenas para testes/debug)
	_create_admin_menu(tb)
	
	# top bar fixa: posição X=0 (alinhada à esquerda) e Y=0 (topo), mesma largura do grid
	tb.position = Vector2(0.0, 0.0)
	tb.size = Vector2(grid_px_w, bar_height)
	
	# Remover botão de comprar antigo (não é mais necessário com o menu lateral)
	if tb.has_node("BuyMenuButton"):
		tb.get_node("BuyMenuButton").queue_free()
	
	# Adicionar botão para mutar música
	if not tb.has_node("BtnMuteMusic"):
		var btn_mute = Button.new()
		btn_mute.name = "BtnMuteMusic"
		btn_mute.text = "🔊"
		btn_mute.position = Vector2(810, 8)
		btn_mute.size = Vector2(40, 28)
		tb.add_child(btn_mute)
		
		# Estilizar botão de mute
		var mute_btn_style_normal = StyleBoxFlat.new()
		mute_btn_style_normal.bg_color = Color(0.2, 0.2, 0.3)
		mute_btn_style_normal.border_color = Color(0.4, 0.4, 0.5)
		mute_btn_style_normal.border_width_left = 1
		mute_btn_style_normal.border_width_top = 1
		mute_btn_style_normal.border_width_right = 1
		mute_btn_style_normal.border_width_bottom = 1
		btn_mute.add_theme_stylebox_override("normal", mute_btn_style_normal)
		
		var mute_btn_style_hover = StyleBoxFlat.new()
		mute_btn_style_hover.bg_color = Color(0.3, 0.3, 0.4)
		mute_btn_style_hover.border_color = Color(0.5, 0.5, 0.6)
		mute_btn_style_hover.border_width_left = 1
		mute_btn_style_hover.border_width_top = 1
		mute_btn_style_hover.border_width_right = 1
		mute_btn_style_hover.border_width_bottom = 1
		btn_mute.add_theme_stylebox_override("hover", mute_btn_style_hover)
		
		btn_mute.add_theme_font_size_override("font_size", 16)
		btn_mute.pressed.connect(_toggle_music)
	
	# remover botões antigos se existirem
	if tb.has_node("BtnBuyTower"):
		tb.get_node("BtnBuyTower").queue_free()
	if tb.has_node("BtnBuyBlock"):
		tb.get_node("BtnBuyBlock").queue_free()
	if tb.has_node("BtnBuyBarracks"):
		tb.get_node("BtnBuyBarracks").queue_free()
	
	# Criar UI melhorada - Menu lateral de torres
	_create_tower_shop_ui()
	
	# Criar menu de skills
	_create_skills_ui()
	_create_range_indicator()

	# criar PopupMenu para torres (deve estar em um Control)
	var menu_container = Control.new()
	menu_container.name = "TowerMenuContainer"
	menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tower_menu = PopupMenu.new()
	tower_menu.name = "TowerMenu"
	tower_menu.hide_on_checkable_item_selection = true
	tower_menu.add_item("Alcance +60", 1)
	tower_menu.add_item("Cadencias +", 2)
	tower_menu.add_item("+4 Direcoes", 3)
	tower_menu.add_item("Dano +0.5", 4)
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
	barracks_menu.hide_on_checkable_item_selection = true
	barracks_menu.add_item("Dano +0.2", 1)
	barracks_menu.add_item("Tempo Hold +1s", 2)
	barracks_menu.add_item("Spawn Rate -0.5s", 3)
	barracks_menu.add_item("Velocidade Projétil +20", 4)
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
	sniper_menu.hide_on_checkable_item_selection = true
	sniper_menu.add_item("Dano +2", 1)
	sniper_menu.add_item("Taxa de Tiro +", 2)
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
	aoe_menu.hide_on_checkable_item_selection = true
	aoe_menu.add_item("Dano +1", 1)
	aoe_menu.add_item("Taxa de Tiro +", 2)
	aoe_menu.add_item("Área +20", 3)
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
	shock_menu.hide_on_checkable_item_selection = true
	shock_menu.add_item("Dano +0.5", 1)
	shock_menu.add_item("Taxa de Tiro +", 2)
	shock_menu.add_item("Corrente +1", 3)
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
	slow_menu.hide_on_checkable_item_selection = true
	slow_menu.add_item("Alcance +30", 1)
	slow_menu.add_item("Slow +10%", 2)
	slow_menu.add_item("Duração +0.5s", 3)
	slow_menu.add_item("Taxa de Aplicação +", 4)
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
	boost_menu.hide_on_checkable_item_selection = true
	boost_menu.add_item("Alcance +30", 1)
	boost_menu.add_item("Boost Dano +10%", 2)
	boost_menu.add_item("Boost Cadência +5%", 3)
	boost_menu.id_pressed.connect(Callable(self, "_on_boost_menu_pressed"))
	boost_menu.popup_hide.connect(Callable(self, "_on_upgrade_menu_closed"))
	boost_menu_container.add_child(boost_menu)
	$CanvasLayer.add_child(boost_menu_container)

	var ov = $CanvasLayer/UpgradeOverlay
	ov.get_node("Panel/Btn1").pressed.connect(func(): _apply_benefit(0))
	ov.get_node("Panel/Btn2").pressed.connect(func(): _apply_benefit(1))
	ov.get_node("Panel/Btn3").pressed.connect(func(): _apply_benefit(2))
	ov.get_node("Panel/BtnResume").pressed.connect(func(): _resume_after_upgrade())

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

	# Carregar e tocar música de fundo do jogo
	var music_player = get_node_or_null("MusicPlayer")
	if music_player:
		var music = _try_load_music("res://assets/music/game_music.ogg")
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
			music_player.play()
			print("Game: Música de fundo iniciada")
		else:
			print("Game: Música de fundo não encontrada")
	
	_create_boss_alert_ui()
	_load_boss_warning_sound()
	
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

	# Atualizar timers das skills
	if skill_damage_boost_active:
		skill_damage_boost_time -= delta
		if skill_damage_boost_time <= 0.0:
			skill_damage_boost_active = false
			skill_damage_boost_time = 0.0
			print("Boost de Dano expirou!")
	
	if skill_speed_boost_active:
		skill_speed_boost_time -= delta
		if skill_speed_boost_time <= 0.0:
			skill_speed_boost_active = false
			skill_speed_boost_time = 0.0
			print("Boost de Velocidade expirou!")
	
	# Atualizar cooldowns das skills
	if skill_collect_coins_cooldown > 0.0:
		skill_collect_coins_cooldown -= delta
		skill_collect_coins_cooldown = max(0.0, skill_collect_coins_cooldown)
	
	if skill_damage_boost_cooldown > 0.0:
		skill_damage_boost_cooldown -= delta
		skill_damage_boost_cooldown = max(0.0, skill_damage_boost_cooldown)
	
	if skill_speed_boost_cooldown > 0.0:
		skill_speed_boost_cooldown -= delta
		skill_speed_boost_cooldown = max(0.0, skill_speed_boost_cooldown)
	
	if skill_slow_all_cooldown > 0.0:
		skill_slow_all_cooldown -= delta
		skill_slow_all_cooldown = max(0.0, skill_slow_all_cooldown)
	
	# Atualizar timer da skill de slow global
	if skill_slow_all_active:
		skill_slow_all_time -= delta
		if skill_slow_all_time <= 0.0:
			skill_slow_all_active = false
			skill_slow_all_time = 0.0
			print("Slow Global expirou!")
	
	# Atualizar UI das skills (cooldown visual)
	_update_skills_ui()

	# update
	for e in enemies:
		_enemy_update(e, delta)
	for a in arrows:
		_arrow_update(a, delta)
	for b in tower_bullets:
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
	
	# atualizar efeitos visuais
	var new_aoe_effects: Array = []
	for effect in aoe_effects:
		effect.time += delta
		if effect.time < effect.max_time:
			new_aoe_effects.append(effect)
	aoe_effects = new_aoe_effects
	
	var new_sniper_effects: Array = []
	for effect in sniper_effects:
		effect.time += delta
		if effect.time < effect.max_time:
			new_sniper_effects.append(effect)
	sniper_effects = new_sniper_effects
	
	# atualizar efeitos de coleta de moedas
	var new_coin_effects: Array = []
	for effect in coin_collect_effects:
		effect.time += delta
		# atualizar partículas
		var new_particles: Array = []
		for particle in effect.particles:
			particle.time += delta
			particle.pos += particle.vel * delta
			if particle.time < particle.max_time:
				new_particles.append(particle)
		effect.particles = new_particles
		if effect.time < effect.max_time or effect.particles.size() > 0:
			new_coin_effects.append(effect)
	coin_collect_effects = new_coin_effects
	
	# atualizar indicadores de dano flutuantes
	var new_damage_numbers: Array = []
	for dmg in damage_numbers:
		dmg.time += delta
		dmg.pos += dmg.velocity * delta
		dmg.velocity.y += 50.0 * delta  # gravidade leve
		if dmg.time < dmg.max_time:
			new_damage_numbers.append(dmg)
	damage_numbers = new_damage_numbers
	
	# atualizar animações de morte
	var new_death_animations: Array = []
	for anim in enemy_death_animations:
		anim.time += delta
		var progress = anim.time / anim.max_time
		anim.scale = 1.0 - progress  # encolhe
		anim.alpha = 1.0 - progress  # fade out
		if anim.time < anim.max_time:
			new_death_animations.append(anim)
	enemy_death_animations = new_death_animations
	
	# atualizar efeitos visuais de choque
	var new_shock_effects: Array = []
	for effect in shock_effects:
		effect.time += delta
		if effect.time < effect.max_time:
			new_shock_effects.append(effect)
	shock_effects = new_shock_effects
	
	# atualizar moedas dropadas
	var new_dropped_coins: Array = []
	for coin in dropped_coins:
		if coin.collected:
			continue
		coin.lifetime += delta
		if coin.lifetime < coin.max_lifetime:
			new_dropped_coins.append(coin)
	dropped_coins = new_dropped_coins
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
					base_hp = min(100.0, base_hp + hs.heal_amount)
			
			# garantir que upgrade_options tenha 3 elementos e embaralhar
			var pool := [
				{"label": "+1 Dano", "code": "DMG"},
				{"label": "+Cadência", "code": "FIRERATE"},
				{"label": "+1 Perfuração", "code": "PIERCE"},
			]
			pool.shuffle()
			upgrade_options = pool.slice(0, 3)
			# Auto-save quando a wave termina (antes do upgrade overlay)
			_auto_save_after_wave()
			choosing_upgrade = true
			benefit_applied = false
			$CanvasLayer/UpgradeOverlay.visible = true
			_update_upgrade_labels()
		else:
			wave_manager.time_to_next_wave = 0.0

	wave_manager.update_intermission(delta)
	if not choosing_upgrade and not wave_manager.spawning and enemies.is_empty():
		if wave_manager.should_start_wave():
			wave_manager.start_next_wave()

	if wave_manager.spawning:
		var should_spawn = wave_manager.update(delta)
		if should_spawn:
			var s = _random_spawn()
			if s != null:
				if wave_manager.is_boss_wave() and wave_manager.bosses_spawned_this_wave < 2:
					enemies.append(_enemy_new_boss(s.x, s.y))
				else:
					enemies.append(_enemy_new(s.x, s.y))

	# UI
	var tb = $CanvasLayer/HUD/TopBar
	var is_boss_wave := wave_manager.is_boss_wave()
	var wave_text = "Wave %d (CHEFE!)" % wave_manager.wave if is_boss_wave else "Wave %d" % wave_manager.wave
	tb.get_node("LblLeft").text = "%s  Inimigos %d" % [wave_text, enemies.size()]
	tb.get_node("LblCenter").text = "Moedas %d" % [int(hero["coins"])]
	tb.get_node("LblRight").text = "Vida %d" % [base_hp]
	
	# Atualizar UI melhorada - Menu lateral de torres
	_update_tower_shop_ui()

func _update_tower_shop_ui() -> void:
	if tower_shop_panel == null:
		return
	
	for tower_button_data in tower_buttons:
		var tower_info = tower_button_data.tower_info
		var current_count = tower_button_data.tower_info.array.size()
		var can_afford = hero["coins"] >= tower_info.cost
		var can_buy = can_afford and current_count < tower_info.max
		
		# Atualizar label de limite
		tower_button_data.limit_label.text = "%d/%d" % [current_count, tower_info.max]
		if current_count >= tower_info.max:
			tower_button_data.limit_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		else:
			tower_button_data.limit_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		
		# Atualizar cor do custo
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

func _input(event: InputEvent) -> void:
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
		if choosing_upgrade or placing_tower or placing_barracks or placing_mine or placing_slow_tower or placing_aoe_tower or placing_sniper_tower or placing_boost_tower or placing_shock_tower or placing_wall or placing_healing_station:
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
		
		# Continuar com lógica normal se não iniciou drag
		if not dragging_tower and not choosing_upgrade:
			# converter posição do mouse de tela para coordenadas do mundo do Node2D
			var screen_pos = event.position
			var world_pos = to_local(screen_pos)
			
			# verificar se clicou em uma moeda dropada
			var coin_collected = false
			var collected_coin_pos: Vector2 = Vector2.ZERO
			for coin in dropped_coins:
				if coin.collected:
					continue
				var dist = world_pos.distance_to(coin.pos)
				if dist < 20.0:  # raio de coleta da moeda (aumentado para facilitar coleta)
					hero["coins"] += coin.value
					collected_coin_pos = coin.pos
					coin.collected = true
					coin_collected = true
					# Rastrear achievements de moedas
					total_coins_collected += coin.value
					achievement_manager.increment_progress("collect_1000_coins", coin.value)
					achievement_manager.increment_progress("collect_10000_coins", coin.value)
					achievement_manager.increment_progress("collect_100000_coins", coin.value)
					achievement_manager.increment_progress("collect_1000000_coins", coin.value)
					
					# Verificar se tem 10000 ou 50000 moedas ao mesmo tempo
					if hero["coins"] >= 10000:
						achievement_manager.set_progress("hold_10000_coins", 1)
					if hero["coins"] >= 50000:
						achievement_manager.set_progress("hold_50000_coins", 1)
					# Criar efeito visual de coleta
					_create_coin_collect_effect(collected_coin_pos)
					# Tocar som de coleta de moeda
					_play_coin_sound()
					break
			
			if coin_collected:
				queue_redraw()
				return
			
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
			# tiro automático - removido tiro manual por clique
	
	# Detectar fim de drag (botão esquerdo solto)
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if dragging_tower:
			var world_pos = to_local(event.position)
			_end_drag_tower(world_pos)
			return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if not choosing_upgrade and not game_over:
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
			if placing_tower or placing_barracks or placing_mine or placing_slow_tower or placing_aoe_tower or placing_sniper_tower or placing_boost_tower or placing_shock_tower or placing_wall or placing_healing_station:
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
				queue_redraw()
				return
			# converter posição do mouse para coordenadas do mundo do Node2D
			var mouse_world_pos = to_local(event.position)
			var mouse_screen_pos = event.position  # para posicionar menus na tela
			# verificar torres primeiro
			var tower_idx := _find_tower_at(mouse_world_pos, 20.0)  # raio maior para facilitar detecção
			if tower_idx != -1:
				_open_tower_menu(tower_idx, mouse_screen_pos)
				return
			# verificar quartéis
			var barracks_idx := _find_barracks_at(mouse_world_pos, 20.0)
			if barracks_idx != -1:
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
			
			# Se clicou fora de qualquer torre, fechar menus e esconder range indicator
			_close_all_upgrade_menus()

func _draw() -> void:
	# Não desenhar se ainda estiver carregando
	if is_loading:
		return
	
	# verificar se grid foi inicializado
	if grid_manager.grid.is_empty() or grid_manager.grid.size() < GameConstants.GRID_ROWS:
		return
	
	# fundo - desenhar ocupando exatamente o tamanho do grid (mais escuro)
	var map_width := float(GameConstants.GRID_COLS * GameConstants.TILE_SIZE)
	var map_height := float(GameConstants.GRID_ROWS * GameConstants.TILE_SIZE)
	draw_rect(Rect2(0, 0, map_width, map_height), Color(0.02, 0.03, 0.05))
	
	# Overlay escuro para escurecer ainda mais a tela (aumentado para escurecer mais)
	draw_rect(Rect2(0, 0, map_width, map_height), Color(0.0, 0.0, 0.0, 0.7))
	# draw grid - alinhado perfeitamente aos tiles
	for r in range(GameConstants.GRID_ROWS):
		if grid_manager.grid.size() <= r or grid_manager.grid[r].size() < GameConstants.GRID_COLS:
			continue
		for c in range(GameConstants.GRID_COLS):
			var tile_x := float(c * GameConstants.TILE_SIZE)
			var tile_y := float(r * GameConstants.TILE_SIZE)
			var tile_rect := Rect2(tile_x, tile_y, GameConstants.TILE_SIZE, GameConstants.TILE_SIZE)
			
			if grid_manager.grid[r][c] == 0:  # Caminho (chão)
				if tex_path != null:
					# Usar textura do caminho
					draw_texture_rect(tex_path, tile_rect, false)
				elif tex_grass != null:
					# Fallback para grama antiga
					draw_texture_rect(tex_grass, tile_rect, true)
				else:
					# Cor padrão do chão (mais escura)
					draw_rect(tile_rect, Color(0.12,0.13,0.16))
			else:  # Barreira/cerca (parede)
				if tex_wall != null:
					# Usar textura da barreira
					draw_texture_rect(tex_wall, tile_rect, false)
				else:
					# Cor padrão da parede (mais escura)
					draw_rect(tile_rect, Color(0.20,0.22,0.28))
	
	# Camada escura por cima do labirinto para escurecer
	draw_rect(Rect2(0, 0, map_width, map_height), Color(0.0, 0.0, 0.0, 0.4))
	
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
	draw_rect(base_rect, Color(0.2,0.24,0.28,0.6))  # transparência moderada
	
	# desenhar grid da base com transparência - alinhado perfeitamente aos tiles
	var grid_size_px: float = base_width_px / float(GameConstants.BASE_GRID_SIZE)
	var base_left: float = base_left_px
	var base_top: float = base_top_px
	var base_right: float = base_left_px + base_width_px
	var base_bottom: float = base_top_px + base_height_px
	
	for gy in range(GameConstants.BASE_GRID_SIZE + 1):
		var y = base_top + float(gy) * grid_size_px
		draw_line(Vector2(base_left, y), Vector2(base_right, y), Color(0.3,0.32,0.36,0.5), 1.0)
	for gx in range(GameConstants.BASE_GRID_SIZE + 1):
		var x = base_left + float(gx) * grid_size_px
		draw_line(Vector2(x, base_top), Vector2(x, base_bottom), Color(0.3,0.32,0.36,0.5), 1.0)
	
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
	# enemies
	for e in enemies:
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
		# Selecionar sprite baseado na wave
		if wave_manager.wave >= 11 and tex_enemy_robot != null:
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
			
			# Aplicar efeitos visuais através de modulate
			var modulate_color = Color.WHITE
			
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
			
			# Desenhar sprite
			draw_texture_rect(enemy_tex, Rect2(pos, size), false, modulate_color)
			
			# Desenhar borda especial para boss
			if is_boss:
				var border_rect = Rect2(pos - Vector2(2, 2), size + Vector2(4, 4))
				draw_rect(border_rect, Color(0.8, 0.2, 0.8, 0.8), false, 3.0)  # borda roxa
		else:
			var enemy_color = Color(0.9,0.35,0.35)
			
			# chefe tem cor diferente (roxo/vermelho escuro)
			if is_boss:
				enemy_color = Color(0.8,0.2,0.8)  # roxo para chefe
			elif enemy_idx >= 0 and enemy_effects.has(enemy_idx):
				var effects = enemy_effects[enemy_idx]
				if effects.freeze_time > 0.0:
					enemy_color = Color(0.5,0.7,1.0)  # azul quando congelado
				elif effects.fire_time > 0.0:
					enemy_color = Color(1.0,0.5,0.2)  # laranja quando em chamas
			
			var enemy_radius = e.get("radius", 9)
			draw_circle(e["pos"], enemy_radius, enemy_color)
			
			# desenhar borda mais grossa para chefe
			if is_boss:
				draw_circle(e["pos"], enemy_radius, Color(0.5,0.1,0.5), false, 3.0)  # borda roxa grossa
	# arrows
	for a in arrows:
		draw_circle(a["pos"], 2, Color(0.83,0.90,1.0))
	for b in tower_bullets:
		draw_circle(b["pos"], 2, Color(0.95,0.85,0.45))
	# projéteis de canhão AOE (bolas pretas)
	for proj in aoe_cannon_projectiles:
		draw_circle(proj.pos, 6, Color(0.0, 0.0, 0.0))  # bola preta
		draw_circle(proj.pos, 6, Color(0.2, 0.2, 0.2), false, 1.0)  # borda escura
	# efeitos visuais AOE (explosões)
	for effect in aoe_effects:
		var alpha = 1.0 - (effect.time / effect.max_time)
		var radius = effect.radius * (effect.time / effect.max_time)
		draw_circle(effect.pos, radius, Color(1.0, 0.5, 0.0, alpha * 0.6))
		draw_circle(effect.pos, radius, Color(1.0, 0.8, 0.0, alpha), false, 2.0)
	# efeitos visuais Sniper (linhas de tiro)
	for effect in sniper_effects:
		var alpha = 1.0 - (effect.time / effect.max_time)
		draw_line(effect.start, effect.end, Color(1.0, 1.0, 0.0, alpha), 3.0)
	# efeitos visuais de choque elétrico (raios/trovões)
	for effect in shock_effects:
		var alpha = 1.0 - (effect.time / effect.max_time)
		var progress = effect.time / effect.max_time
		# Desenhar linha principal (azul brilhante)
		draw_line(effect.start, effect.end, Color(0.5, 0.8, 1.0, alpha), 4.0)
		# Desenhar linha interna mais brilhante (branco/azul claro)
		draw_line(effect.start, effect.end, Color(1.0, 1.0, 1.0, alpha * 0.8), 2.0)
		# Adicionar "zigzag" para parecer um raio
		var segments = 8
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
		
		match dragged_tower_type:
			"tower":
				preview_size = grid_size_px * GameConstants.TOWER_SIZE_GRID
				preview_tex = tex_tower
			"slow_tower":
				preview_size = grid_size_px * GameConstants.SLOW_TOWER_SIZE_GRID
				preview_tex = tex_slow_tower
			"aoe_tower":
				preview_size = grid_size_px * GameConstants.AOE_TOWER_SIZE_GRID
				preview_tex = tex_aoe_tower
			"sniper_tower":
				preview_size = grid_size_px * GameConstants.SNIPER_TOWER_SIZE_GRID
				preview_tex = tex_sniper_tower
			"boost_tower":
				preview_size = grid_size_px * GameConstants.BOOST_TOWER_SIZE_GRID
				preview_tex = tex_boost_tower
			"shock_tower":
				preview_size = grid_size_px * GameConstants.SHOCK_TOWER_SIZE_GRID
				preview_tex = tex_shock_tower
		
		# Verificar se a posição é válida
		var grid_coord = grid_manager.world_to_base_grid(preview_pos)
		var can_place = false
		if grid_manager.is_inside_base_point(preview_pos):
			match dragged_tower_type:
				"tower":
					can_place = grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, GameConstants.TOWER_SIZE_GRID, 1)
				"slow_tower":
					can_place = grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, GameConstants.SLOW_TOWER_SIZE_GRID, 5)
				"aoe_tower":
					can_place = grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, GameConstants.AOE_TOWER_SIZE_GRID, 6)
				"sniper_tower":
					can_place = grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, GameConstants.SNIPER_TOWER_SIZE_GRID, 7)
				"boost_tower":
					can_place = grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, GameConstants.BOOST_TOWER_SIZE_GRID, 8)
				"shock_tower":
					can_place = grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, GameConstants.SHOCK_TOWER_SIZE_GRID, 9)
		
		var preview_rect = Rect2(preview_pos.x - preview_size/2, preview_pos.y - preview_size/2, preview_size, preview_size)
		if can_place:
			# Posição válida - verde semi-transparente
			if preview_tex != null:
				draw_texture_rect(preview_tex, preview_rect, false, Color(1, 1, 1, 0.7))
			else:
				draw_rect(preview_rect, Color(0.7, 0.9, 0.7, 0.7))
			draw_rect(preview_rect, Color(0.5, 0.8, 0.5), false, 2.0)
		else:
			# Posição inválida - vermelho semi-transparente
			if preview_tex != null:
				draw_texture_rect(preview_tex, preview_rect, false, Color(1, 0.3, 0.3, 0.7))
			else:
				draw_rect(preview_rect, Color(0.9, 0.3, 0.3, 0.7))
			draw_rect(preview_rect, Color(0.8, 0.2, 0.2), false, 2.0)
	
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
	for br in barracks:
		var barracks_size := grid_size_px * GameConstants.BARRACKS_SIZE_GRID
		var br_rect := Rect2(br.pos.x - barracks_size/2, br.pos.y - barracks_size/2, barracks_size, barracks_size)
		if tex_barracks != null:
			draw_texture_rect(tex_barracks, br_rect, false)
		else:
			draw_rect(br_rect, Color(0.4,0.5,0.6))
			draw_rect(br_rect, Color(0.3,0.4,0.5), false, 2.0)  # borda
	# minas
	for m in mines:
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
	# walls
	for w in walls:
		if w.hp > 0:
			var wall_size := grid_size_px * GameConstants.WALL_SIZE_GRID
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
	# healing stations
	for hs in healing_stations:
		var hs_size := grid_size_px * GameConstants.HEALING_STATION_SIZE_GRID
		var hs_rect := Rect2(hs.pos.x - hs_size/2, hs.pos.y - hs_size/2, hs_size, hs_size)
		if tex_healing_station != null:
			draw_texture_rect(tex_healing_station, hs_rect, false)
		else:
			draw_rect(hs_rect, Color(0.2,0.8,0.4))
			draw_rect(hs_rect, Color(0.1,0.6,0.3), false, 2.0)
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
	if placing_tower or placing_barracks or placing_mine or placing_slow_tower or placing_aoe_tower or placing_sniper_tower or placing_boost_tower or placing_shock_tower or placing_wall or placing_healing_station:
		if grid_manager.is_inside_base_point(preview_mouse_pos):
			var preview_grid_coord = grid_manager.world_to_base_grid(preview_mouse_pos)
			var preview_world_pos = grid_manager.base_grid_to_world(preview_grid_coord.x, preview_grid_coord.y)
			
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
			elif placing_mine:
				var can_place = grid_manager.can_place_in_grid(preview_grid_coord.x, preview_grid_coord.y, GameConstants.MINE_SIZE_GRID, 4) and not _is_on_path(preview_mouse_pos) and not _is_in_center_area(preview_mouse_pos)
				if can_place:
					if tex_mine != null:
						var mine_size = 16.0
						var mine_rect = Rect2(preview_world_pos.x - mine_size/2, preview_world_pos.y - mine_size/2, mine_size, mine_size)
						draw_texture_rect(tex_mine, mine_rect, false, Color(1, 1, 1, 0.5))
					else:
						draw_circle(preview_world_pos, 8, Color(0.8,0.2,0.2,0.5))
					draw_circle(preview_world_pos, 8, Color(0.5,0.1,0.1), false, 2.0)
				else:
					if tex_mine != null:
						var mine_size = 16.0
						var mine_rect = Rect2(preview_world_pos.x - mine_size/2, preview_world_pos.y - mine_size/2, mine_size, mine_size)
						draw_texture_rect(tex_mine, mine_rect, false, Color(1, 0.3, 0.3, 0.5))
					else:
						draw_circle(preview_world_pos, 8, Color(0.9,0.3,0.3,0.5))
					draw_circle(preview_world_pos, 8, Color(0.8,0.2,0.2), false, 2.0)
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
			elif placing_wall:
				var can_place = grid_manager.can_place_in_grid(preview_grid_coord.x, preview_grid_coord.y, GameConstants.WALL_SIZE_GRID, 9) and not _is_on_path(preview_mouse_pos) and not _is_in_center_area(preview_mouse_pos)
				if can_place:
					var preview_size := grid_size_px * GameConstants.WALL_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					if tex_wall_structure != null:
						draw_texture_rect(tex_wall_structure, preview_rect, false, Color(1, 1, 1, 0.5))
					else:
						draw_rect(preview_rect, Color(0.6,0.4,0.2,0.5))
					draw_rect(preview_rect, Color(0.4,0.3,0.2), false, 2.0)
				else:
					var preview_size := grid_size_px * GameConstants.WALL_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					if tex_wall_structure != null:
						draw_texture_rect(tex_wall_structure, preview_rect, false, Color(1, 0.3, 0.3, 0.5))
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
	if upgrade_options.size() >= 1:
		ov.get_node("Panel/Btn1").text = upgrade_options[0]["label"]
	if upgrade_options.size() >= 2:
		ov.get_node("Panel/Btn2").text = upgrade_options[1]["label"]
	if upgrade_options.size() >= 3:
		ov.get_node("Panel/Btn3").text = upgrade_options[2]["label"]

func _apply_benefit(i: int) -> void:
	if benefit_applied:
		return
	if upgrade_options.is_empty() or i < 0 or i >= upgrade_options.size():
		return
	var code: String = upgrade_options[i]["code"]
	match code:
		"DMG":
			hero["levels"]["DMG"] += 1
			hero["damage"] += 1
		"FIRERATE":
			hero["levels"]["FIRERATE"] += 1
			hero["fire_rate"] = max(0.1, hero["fire_rate"] - 0.05)
		"PIERCE":
			hero["levels"]["PIERCE"] += 1
			hero["pierce"] += 1
	benefit_applied = true

func _resume_after_upgrade() -> void:
	if not benefit_applied:
		return
	$CanvasLayer/UpgradeOverlay.visible = false
	choosing_upgrade = false
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

func _bfs_path(from_c: int, from_r: int) -> Array:
	# Limpar cache periodicamente para evitar caminhos inválidos em waves altas
	# (a cada 10 waves ou quando há muitos inimigos)
	if wave_manager.wave > 0 and (wave_manager.wave % 10 == 0 or enemies.size() > 50):
		pathfinder.invalidate_cache()
	
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

func _enemy_new(col: int, row: int) -> Dictionary:
	var pos = grid_manager.tile_center(col, row)
	var initial_hp := GameConstants.ENEMY_BASE_HP  # HP suficiente para 2 ataques iniciais
	var f := _wave_factor()
	var hp := int(max(1, round(initial_hp * f)))
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
	# Limitar velocidade máxima para evitar bugs em waves muito altas
	var base_speed = GameConstants.ENEMY_BASE_SPEED * f
	var max_speed = 200.0  # Velocidade máxima
	if base_speed > max_speed:
		base_speed = max_speed
	var e = { pos = pos, speed = base_speed, base_speed = base_speed, hp = hp, max_hp = hp, radius = 9, path = path_copy, path_index = 0, reached = false, idx = enemy_idx, is_boss = false }
	enemy_effects[enemy_idx] = {"slow_time": 0.0, "slow_amount": 0.0, "freeze_time": 0.0, "fire_time": 0.0, "fire_damage": 0.0}
	return e

func _enemy_new_boss(col: int, row: int) -> Dictionary:
	var pos = grid_manager.tile_center(col, row)
	var initial_hp := GameConstants.BOSS_BASE_HP  # chefe tem muito mais HP (equivalente a 25 hits iniciais)
	var f := _wave_factor()
	var hp := int(max(1, round(initial_hp * f)))
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
	var max_speed = 200.0  # Velocidade máxima
	if base_speed > max_speed:
		base_speed = max_speed
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
	# Velocidade máxima de 200 pixels/segundo (ajustável)
	var max_speed = 200.0
	if e["speed"] > max_speed:
		e["speed"] = max_speed
		e["base_speed"] = min(e["base_speed"], max_speed)
	
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
				$CanvasLayer/GameOverOverlay.visible = true
				$CanvasLayer/GameOverOverlay/Panel/LblWave.text = "Wave %d" % wave_manager.wave
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
				$CanvasLayer/GameOverOverlay.visible = true
				$CanvasLayer/GameOverOverlay/Panel/LblWave.text = "Wave %d" % wave_manager.wave
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
			$CanvasLayer/GameOverOverlay.visible = true
			$CanvasLayer/GameOverOverlay/Panel/LblWave.text = "Wave %d" % wave_manager.wave
		return
	
	var v2 = targ - e["pos"]
	var d2 = max(v2.length(), 0.0001)
	
	# Calcular distância de movimento baseada na velocidade
	var move_dist = e["speed"] * dt
	
	# Ajustar threshold de proximidade baseado na velocidade (maior velocidade = maior threshold)
	var proximity_threshold = max(2.0, move_dist * 1.5)
	
	# Se está muito próximo do alvo, avançar para o próximo ponto
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
				$CanvasLayer/GameOverOverlay.visible = true
				$CanvasLayer/GameOverOverlay/Panel/LblWave.text = "Wave %d" % wave_manager.wave
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
				$CanvasLayer/GameOverOverlay.visible = true
				$CanvasLayer/GameOverOverlay/Panel/LblWave.text = "Wave %d" % wave_manager.wave
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
				$CanvasLayer/GameOverOverlay.visible = true
				$CanvasLayer/GameOverOverlay/Panel/LblWave.text = "Wave %d" % wave_manager.wave
			return

func _arrow_new(x: float, y: float, target: Vector2) -> Dictionary:
	var dir = (target - Vector2(x,y))
	var d = max(dir.length(), 0.0001)
	# aplicar skill de boost de dano no herói
	var hero_damage = hero["damage"]
	if skill_damage_boost_active:
		hero_damage *= GameConstants.SKILL_DAMAGE_BOOST_MULTIPLIER
	
	var a = { "pos": Vector2(x,y), "vel": dir/d * 260.0, "life": 2.0, "radius": 2, "damage": hero_damage, "pierce": hero["pierce"] }
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
				var old_hp = e["hp"]
				e["hp"] -= a["damage"]
				# Criar indicador de dano
				_create_damage_number(e["pos"], a["damage"], false)
				if e["hp"] <= 0:
					e["hp"] = 0
					e["dying"] = true
					e["dying_time"] = 0.0
					# Criar animação de morte
					_create_death_animation(e["pos"])
					var is_boss = e.get("is_boss", false)
					# chefe dá 20x mais moedas (40 vs 2)
					hero["coins"] += GameConstants.BOSS_REWARD_MULTIPLIER * GameConstants.NORMAL_REWARD if is_boss else GameConstants.NORMAL_REWARD
					# chance de dropar moeda
					_try_drop_coin(e["pos"])
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
				var old_hp = e["hp"]
				e["hp"] -= b["damage"]
				# Criar indicador de dano
				_create_damage_number(e["pos"], b["damage"], false)
				if e["hp"] <= 0:
					e["hp"] = 0
					e["dying"] = true
					e["dying_time"] = 0.0
					# Criar animação de morte
					_create_death_animation(e["pos"])
					var is_boss = e.get("is_boss", false)
					# chefe dá 20x mais moedas (40 vs 2)
					hero["coins"] += GameConstants.BOSS_REWARD_MULTIPLIER * GameConstants.NORMAL_REWARD if is_boss else GameConstants.NORMAL_REWARD
					# chance de dropar moeda
					_try_drop_coin(e["pos"])
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
	
	drag_start_pos = tower_pos
	drag_offset = mouse_pos - tower_pos
	drag_current_pos = mouse_pos
	queue_redraw()

func _end_drag_tower(mouse_pos: Vector2) -> void:
	if not dragging_tower:
		return
	
	var new_pos = mouse_pos - drag_offset
	
	# Tentar mover a torre
	var moved = false
	match dragged_tower_type:
		"tower":
			moved = _try_move_tower(dragged_tower_index, new_pos)
		"slow_tower":
			moved = _try_move_slow_tower(dragged_tower_index, new_pos)
		"aoe_tower":
			moved = _try_move_aoe_tower(dragged_tower_index, new_pos)
		"sniper_tower":
			moved = _try_move_sniper_tower(dragged_tower_index, new_pos)
		"boost_tower":
			moved = _try_move_boost_tower(dragged_tower_index, new_pos)
		"shock_tower":
			moved = _try_move_shock_tower(dragged_tower_index, new_pos)
	
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
	var can_range: bool = hero["coins"] >= GameConstants.TOWER_RANGE_COST
	var can_rate: bool = hero["coins"] >= GameConstants.TOWER_RATE_COST and t.fire_rate > 0.12
	var can_dirs: bool = hero["coins"] >= GameConstants.TOWER_DIRS_COST and dirs_count < 4
	var can_dmg: bool = hero["coins"] >= GameConstants.TOWER_DMG_COST
	var can_freeze: bool = hero["coins"] >= GameConstants.TOWER_FREEZE_COST and not t.get("has_freeze", false)
	var can_fire: bool = hero["coins"] >= GameConstants.TOWER_FIRE_COST and not t.get("has_fire", false)
	
	tower_menu.set_item_text(0, "Alcance +60 (%d)" % GameConstants.TOWER_RANGE_COST)
	tower_menu.set_item_text(1, "Cadencias + (%d)" % GameConstants.TOWER_RATE_COST)
	tower_menu.set_item_text(2, "+4 Direcoes (%d)" % GameConstants.TOWER_DIRS_COST)
	tower_menu.set_item_text(3, "Dano +0.5 (%d)" % GameConstants.TOWER_DMG_COST)
	tower_menu.set_item_text(4, "Congelamento (%d)" % GameConstants.TOWER_FREEZE_COST)
	tower_menu.set_item_text(5, "Fogo (%d)" % GameConstants.TOWER_FIRE_COST)
	tower_menu.set_item_disabled(0, not can_range)
	tower_menu.set_item_disabled(1, not can_rate)
	tower_menu.set_item_disabled(2, not can_dirs)
	tower_menu.set_item_disabled(3, not can_dmg)
	tower_menu.set_item_disabled(4, not can_freeze)
	tower_menu.set_item_disabled(5, not can_fire)
	tower_menu.position = screen_pos
	tower_menu.popup()

func _on_tower_menu_pressed(id: int) -> void:
	if tower_selected_index < 0 or tower_selected_index >= towers.size():
		return
	var t = towers[tower_selected_index]
	match id:
		1:  # Alcance
			if hero["coins"] >= GameConstants.TOWER_RANGE_COST:
				t.range += 60.0
				t.levels["RANGE"] += 1
				hero["coins"] -= GameConstants.TOWER_RANGE_COST
		2:  # Cadência (reduz tempo entre tiros)
			if hero["coins"] >= GameConstants.TOWER_RATE_COST and t.fire_rate > 0.12:
				t.fire_rate = max(0.1, t.fire_rate - 0.05)
				t.levels["RATE"] += 1
				hero["coins"] -= GameConstants.TOWER_RATE_COST
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
		4:  # Dano
			if hero["coins"] >= GameConstants.TOWER_DMG_COST:
				t.damage += 0.5
				t.levels["DMG"] += 1
				hero["coins"] -= GameConstants.TOWER_DMG_COST
		5:  # Congelamento
			if hero["coins"] >= GameConstants.TOWER_FREEZE_COST and not t.get("has_freeze", false):
				t["has_freeze"] = true
				t.levels["FREEZE"] = 1
				hero["coins"] -= GameConstants.TOWER_FREEZE_COST
		6:  # Fogo
			if hero["coins"] >= GameConstants.TOWER_FIRE_COST and not t.get("has_fire", false):
				t["has_fire"] = true
				t.levels["FIRE"] = 1
				hero["coins"] -= GameConstants.TOWER_FIRE_COST
	towers[tower_selected_index] = t
	_hide_range_indicator()
	tower_selected_index = -1

func _try_shoot(target: Vector2) -> void:
	if hero["cooldown"] > 0.0:
		return
	arrows.append(_arrow_new(hero["x"], hero["y"], target))
	hero["cooldown"] = hero["fire_rate"]

func _calculate_leading_target(enemy: Dictionary, hero_pos: Vector2) -> Vector2:
	# Calcular posição futura do inimigo para melhorar precisão do tiro
	var enemy_pos = enemy["pos"]
	var distance = hero_pos.distance_to(enemy_pos)
	
	# Velocidade da flecha
	var arrow_speed = 260.0
	
	# Tempo que a flecha leva para chegar na posição atual do inimigo
	var time_to_reach = distance / arrow_speed
	
	# Calcular direção do movimento do inimigo
	var enemy_velocity = Vector2.ZERO
	if enemy.has("path") and enemy.has("path_index") and enemy["path_index"] < enemy["path"].size():
		var target_point = enemy["path"][enemy["path_index"]]
		var dir_to_target = (target_point - enemy_pos)
		if dir_to_target.length() > 0.1:
			enemy_velocity = dir_to_target.normalized() * enemy.get("speed", GameConstants.ENEMY_BASE_SPEED)
	else:
		# Se não tem path, calcular direção para a base
		var base_center = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
		var dir_to_base = (base_center - enemy_pos)
		if dir_to_base.length() > 0.1:
			enemy_velocity = dir_to_base.normalized() * enemy.get("speed", GameConstants.ENEMY_BASE_SPEED)
	
	# Calcular posição futura do inimigo
	var predicted_pos = enemy_pos + enemy_velocity * time_to_reach * 0.8  # 0.8 é um fator de ajuste para não exagerar
	
	return predicted_pos

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
	admin_menu.id_pressed.connect(_on_admin_menu_pressed)
	menu_container.add_child(admin_menu)
	
	# Criar botão que abre o menu
	admin_menu_button = Button.new()
	admin_menu_button.name = "BtnAdmin"
	admin_menu_button.text = "Admin"
	admin_menu_button.position = Vector2(600, 8)
	admin_menu_button.size = Vector2(100, 28)
	
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

func _on_upgrade_hero_home() -> void:
	if hero_home_level >= HERO_HOME_MAX_LEVEL:
		return
	var next_level = hero_home_level + 1
	var cost = _get_hero_home_upgrade_cost(next_level)
	if cost <= 0:
		return
	if hero["coins"] < cost:
		return
	hero["coins"] -= cost
	_track_coin_spent(cost)
	hero_home_level = next_level
	_apply_hero_home_upgrade_effects(next_level)
	_update_hero_home_panel_ui()
	queue_redraw()

func _on_wave_started(wave_number: int, is_boss_wave: bool):
	if ((wave_number + 1) % 5) == 0:
		_show_boss_warning("ALERTA! Boss chegando na próxima wave!")
	
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
	if hero["coins"] < GameConstants.TOWER_COST:
		return
	if towers.size() >= GameConstants.MAX_TOWERS:
		return  # limite de torres atingido
	placing_tower = true
	placing_barracks = false

# Blocos removidos - substituídos por Muralhas

func _on_buy_barracks() -> void:
	if placing_barracks:
		return
	if hero["coins"] < GameConstants.BARRACKS_COST:
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
	var can_dmg: bool = hero["coins"] >= GameConstants.BARRACKS_DMG_COST
	var can_hold: bool = hero["coins"] >= GameConstants.BARRACKS_HOLD_COST
	var can_spawn_rate: bool = hero["coins"] >= GameConstants.BARRACKS_SPAWN_RATE_COST and b.soldier_spawn_rate > 1.0
	var can_projectile_speed: bool = hero["coins"] >= GameConstants.BARRACKS_PROJECTILE_SPEED_COST
	
	barracks_menu.set_item_text(0, "Dano +0.2 (%d)" % GameConstants.BARRACKS_DMG_COST)
	barracks_menu.set_item_text(1, "Tempo Hold +1s (%d)" % GameConstants.BARRACKS_HOLD_COST)
	barracks_menu.set_item_text(2, "Spawn Rate -0.5s (%d) [%.1fs]" % [GameConstants.BARRACKS_SPAWN_RATE_COST, b.soldier_spawn_rate])
	barracks_menu.set_item_text(3, "Velocidade Projétil +20 (%d) [%.0f]" % [GameConstants.BARRACKS_PROJECTILE_SPEED_COST, b.projectile_speed])
	barracks_menu.set_item_disabled(0, not can_dmg)
	barracks_menu.set_item_disabled(1, not can_hold)
	barracks_menu.set_item_disabled(2, not can_spawn_rate)
	barracks_menu.set_item_disabled(3, not can_projectile_speed)
	barracks_menu.position = screen_pos
	barracks_menu.popup()

func _on_barracks_menu_pressed(id: int) -> void:
	if barracks_selected_index < 0 or barracks_selected_index >= barracks.size():
		return
	var b = barracks[barracks_selected_index]
	match id:
		1:  # Dano
			if hero["coins"] >= GameConstants.BARRACKS_DMG_COST:
				b.damage += 0.2
				b.levels["DMG"] += 1
				hero["coins"] -= GameConstants.BARRACKS_DMG_COST
		2:  # Tempo Hold
			if hero["coins"] >= GameConstants.BARRACKS_HOLD_COST:
				b.hold_time += 1.0
				b.levels["HOLD"] += 1
				hero["coins"] -= GameConstants.BARRACKS_HOLD_COST
		3:  # Spawn Rate
			if hero["coins"] >= GameConstants.BARRACKS_SPAWN_RATE_COST and b.soldier_spawn_rate > 1.0:
				b.soldier_spawn_rate = max(1.0, b.soldier_spawn_rate - 0.5)
				b.levels["SPAWN_RATE"] += 1
				hero["coins"] -= GameConstants.BARRACKS_SPAWN_RATE_COST
		4:  # Velocidade Projétil
			if hero["coins"] >= GameConstants.BARRACKS_PROJECTILE_SPEED_COST:
				b.projectile_speed += 20.0
				b.levels["PROJECTILE_SPEED"] += 1
				hero["coins"] -= GameConstants.BARRACKS_PROJECTILE_SPEED_COST
	barracks[barracks_selected_index] = b
	barracks_selected_index = -1

func _open_sniper_menu(idx: int, screen_pos: Vector2) -> void:
	if sniper_menu == null:
		return
	sniper_selected_index = idx
	var s = sniper_towers[idx]
	_show_range_indicator(s.pos, s.range, Color(1.0, 0.4, 0.4, 0.65))
	var can_dmg: bool = hero["coins"] >= GameConstants.SNIPER_DMG_COST
	var can_rate: bool = hero["coins"] >= GameConstants.SNIPER_RATE_COST and s.fire_rate > 1.0
	
	sniper_menu.set_item_text(0, "Dano +2 (%d)" % GameConstants.SNIPER_DMG_COST)
	sniper_menu.set_item_text(1, "Taxa de Tiro + (%d) [%.1fs]" % [GameConstants.SNIPER_RATE_COST, s.fire_rate])
	var target_mode = s.get("target_mode", 0)
	sniper_menu.set_item_text(3, "Alvo: Boss" + (" ✓" if target_mode == 0 else ""))
	sniper_menu.set_item_text(4, "Alvo: Mais Próximo ao Centro" + (" ✓" if target_mode == 1 else ""))
	sniper_menu.set_item_disabled(0, not can_dmg)
	sniper_menu.set_item_disabled(1, not can_rate)
	sniper_menu.position = screen_pos
	sniper_menu.popup()

func _on_sniper_menu_pressed(id: int) -> void:
	if sniper_selected_index < 0 or sniper_selected_index >= sniper_towers.size():
		return
	var s = sniper_towers[sniper_selected_index]
	match id:
		1:  # Dano
			if hero["coins"] >= GameConstants.SNIPER_DMG_COST:
				s.damage += 2.0
				s.levels["DMG"] += 1
				hero["coins"] -= GameConstants.SNIPER_DMG_COST
		2:  # Taxa de Tiro
			if hero["coins"] >= GameConstants.SNIPER_RATE_COST and s.fire_rate > 1.0:
				s.fire_rate = max(1.0, s.fire_rate - 0.5)
				s.levels["RATE"] += 1
				hero["coins"] -= GameConstants.SNIPER_RATE_COST
		3:  # Alvo: Boss
			s["target_mode"] = 0
		4:  # Alvo: Mais Próximo ao Centro
			s["target_mode"] = 1
	sniper_towers[sniper_selected_index] = s
	_hide_range_indicator()
	sniper_selected_index = -1

func _open_aoe_menu(idx: int, screen_pos: Vector2) -> void:
	if aoe_menu == null:
		return
	aoe_selected_index = idx
	var a = aoe_towers[idx]
	_show_range_indicator(a.pos, a.range, Color(1.0, 0.8, 0.3, 0.65))
	var can_dmg: bool = hero["coins"] >= GameConstants.AOE_DMG_COST
	var can_rate: bool = hero["coins"] >= GameConstants.AOE_RATE_COST and a.fire_rate > 0.5
	var can_area: bool = hero["coins"] >= GameConstants.AOE_AREA_COST
	
	aoe_menu.set_item_text(0, "Dano +1 (%d)" % GameConstants.AOE_DMG_COST)
	aoe_menu.set_item_text(1, "Taxa de Tiro + (%d) [%.1fs]" % [GameConstants.AOE_RATE_COST, a.fire_rate])
	aoe_menu.set_item_text(2, "Área +20 (%d) [%.0f]" % [GameConstants.AOE_AREA_COST, a.aoe_radius])
	aoe_menu.set_item_disabled(0, not can_dmg)
	aoe_menu.set_item_disabled(1, not can_rate)
	aoe_menu.set_item_disabled(2, not can_area)
	aoe_menu.position = screen_pos
	aoe_menu.popup()

func _on_aoe_menu_pressed(id: int) -> void:
	if aoe_selected_index < 0 or aoe_selected_index >= aoe_towers.size():
		return
	var a = aoe_towers[aoe_selected_index]
	match id:
		1:  # Dano
			if hero["coins"] >= GameConstants.AOE_DMG_COST:
				a.damage += 1.0
				a.levels["DMG"] += 1
				hero["coins"] -= GameConstants.AOE_DMG_COST
		2:  # Taxa de Tiro
			if hero["coins"] >= GameConstants.AOE_RATE_COST and a.fire_rate > 0.5:
				a.fire_rate = max(0.5, a.fire_rate - 0.3)
				a.levels["RATE"] += 1
				hero["coins"] -= GameConstants.AOE_RATE_COST
		3:  # Área
			if hero["coins"] >= GameConstants.AOE_AREA_COST:
				a.aoe_radius += 20.0
				a.levels["AREA"] += 1
				hero["coins"] -= GameConstants.AOE_AREA_COST
	aoe_towers[aoe_selected_index] = a
	_hide_range_indicator()
	aoe_selected_index = -1

func _open_shock_menu(idx: int, screen_pos: Vector2) -> void:
	if shock_menu == null:
		return
	shock_selected_index = idx
	var s = shock_towers[idx]
	_show_range_indicator(s.pos, s.range, Color(0.9, 0.5, 1.0, 0.65))
	var can_dmg: bool = hero["coins"] >= GameConstants.SHOCK_DMG_COST
	var can_rate: bool = hero["coins"] >= GameConstants.SHOCK_RATE_COST and s.fire_rate > 0.5
	var can_chain: bool = hero["coins"] >= GameConstants.SHOCK_CHAIN_COST
	
	shock_menu.set_item_text(0, "Dano +0.5 (%d)" % GameConstants.SHOCK_DMG_COST)
	shock_menu.set_item_text(1, "Taxa de Tiro + (%d) [%.1fs]" % [GameConstants.SHOCK_RATE_COST, s.fire_rate])
	shock_menu.set_item_text(2, "Corrente +1 (%d) [%d]" % [GameConstants.SHOCK_CHAIN_COST, s.chain_count])
	shock_menu.set_item_disabled(0, not can_dmg)
	shock_menu.set_item_disabled(1, not can_rate)
	shock_menu.set_item_disabled(2, not can_chain)
	shock_menu.position = screen_pos
	shock_menu.popup()

func _on_shock_menu_pressed(id: int) -> void:
	if shock_selected_index < 0 or shock_selected_index >= shock_towers.size():
		return
	var s = shock_towers[shock_selected_index]
	match id:
		1:  # Dano
			if hero["coins"] >= GameConstants.SHOCK_DMG_COST:
				s.damage += 0.5
				s.levels["DMG"] += 1
				hero["coins"] -= GameConstants.SHOCK_DMG_COST
		2:  # Taxa de Tiro
			if hero["coins"] >= GameConstants.SHOCK_RATE_COST and s.fire_rate > 0.5:
				s.fire_rate = max(0.5, s.fire_rate - 0.2)
				s.levels["RATE"] += 1
				hero["coins"] -= GameConstants.SHOCK_RATE_COST
		3:  # Corrente
			if hero["coins"] >= GameConstants.SHOCK_CHAIN_COST:
				s.chain_count += 1
				s.levels["CHAIN"] += 1
				hero["coins"] -= GameConstants.SHOCK_CHAIN_COST
	shock_towers[shock_selected_index] = s
	_hide_range_indicator()
	shock_selected_index = -1

func _open_slow_menu(idx: int, screen_pos: Vector2) -> void:
	if slow_menu == null:
		return
	slow_selected_index = idx
	var s = slow_towers[idx]
	_show_range_indicator(s.pos, s.range, Color(0.4, 1.0, 0.8, 0.65))
	var can_range: bool = hero["coins"] >= GameConstants.SLOW_RANGE_COST
	var can_amount: bool = hero["coins"] >= GameConstants.SLOW_AMOUNT_COST and s.slow_amount < 0.9
	var can_duration: bool = hero["coins"] >= GameConstants.SLOW_DURATION_COST
	var can_rate: bool = hero["coins"] >= GameConstants.SLOW_RATE_COST and s.fire_rate > 0.2
	
	slow_menu.set_item_text(0, "Alcance +30 (%d) [%.0f]" % [GameConstants.SLOW_RANGE_COST, s.range])
	slow_menu.set_item_text(1, "Slow +10%% (%d) [%.0f%%]" % [GameConstants.SLOW_AMOUNT_COST, s.slow_amount * 100])
	slow_menu.set_item_text(2, "Duração +0.5s (%d) [%.1fs]" % [GameConstants.SLOW_DURATION_COST, s.slow_duration])
	slow_menu.set_item_text(3, "Taxa de Aplicação + (%d) [%.1fs]" % [GameConstants.SLOW_RATE_COST, s.fire_rate])
	slow_menu.set_item_disabled(0, not can_range)
	slow_menu.set_item_disabled(1, not can_amount)
	slow_menu.set_item_disabled(2, not can_duration)
	slow_menu.set_item_disabled(3, not can_rate)
	slow_menu.position = screen_pos
	slow_menu.popup()

func _on_slow_menu_pressed(id: int) -> void:
	if slow_selected_index < 0 or slow_selected_index >= slow_towers.size():
		return
	var s = slow_towers[slow_selected_index]
	match id:
		1:  # Alcance
			if hero["coins"] >= GameConstants.SLOW_RANGE_COST:
				s.range += 30.0
				s.levels["RANGE"] += 1
				hero["coins"] -= GameConstants.SLOW_RANGE_COST
		2:  # Slow Amount
			if hero["coins"] >= GameConstants.SLOW_AMOUNT_COST and s.slow_amount < 0.9:
				s.slow_amount = min(0.9, s.slow_amount + 0.1)
				s.levels["AMOUNT"] += 1
				hero["coins"] -= GameConstants.SLOW_AMOUNT_COST
		3:  # Duração
			if hero["coins"] >= GameConstants.SLOW_DURATION_COST:
				s.slow_duration += 0.5
				s.levels["DURATION"] += 1
				hero["coins"] -= GameConstants.SLOW_DURATION_COST
		4:  # Taxa de Aplicação
			if hero["coins"] >= GameConstants.SLOW_RATE_COST and s.fire_rate > 0.2:
				s.fire_rate = max(0.2, s.fire_rate - 0.1)
				s.levels["RATE"] += 1
				hero["coins"] -= GameConstants.SLOW_RATE_COST
	slow_towers[slow_selected_index] = s
	_hide_range_indicator()
	slow_selected_index = -1

func _open_boost_menu(idx: int, screen_pos: Vector2) -> void:
	if boost_menu == null:
		return
	boost_selected_index = idx
	var b = boost_towers[idx]
	_show_range_indicator(b.pos, b.range, Color(0.6, 0.9, 0.4, 0.65))
	var can_range: bool = hero["coins"] >= GameConstants.BOOST_RANGE_COST
	var can_dmg: bool = hero["coins"] >= GameConstants.BOOST_DMG_COST
	var can_rate: bool = hero["coins"] >= GameConstants.BOOST_RATE_COST
	
	boost_menu.set_item_text(0, "Alcance +30 (%d) [%.0f]" % [GameConstants.BOOST_RANGE_COST, b.range])
	boost_menu.set_item_text(1, "Boost Dano +10%% (%d) [%.0f%%]" % [GameConstants.BOOST_DMG_COST, b.damage_boost * 100])
	boost_menu.set_item_text(2, "Boost Cadência +5%% (%d) [%.0f%%]" % [GameConstants.BOOST_RATE_COST, b.rate_boost * 100])
	boost_menu.set_item_disabled(0, not can_range)
	boost_menu.set_item_disabled(1, not can_dmg)
	boost_menu.set_item_disabled(2, not can_rate)
	boost_menu.position = screen_pos
	boost_menu.popup()

func _on_boost_menu_pressed(id: int) -> void:
	if boost_selected_index < 0 or boost_selected_index >= boost_towers.size():
		return
	var b = boost_towers[boost_selected_index]
	match id:
		1:  # Alcance
			if hero["coins"] >= GameConstants.BOOST_RANGE_COST:
				b.range += 30.0
				b.levels["RANGE"] += 1
				hero["coins"] -= GameConstants.BOOST_RANGE_COST
		2:  # Boost Dano
			if hero["coins"] >= GameConstants.BOOST_DMG_COST:
				b.damage_boost += 0.1
				b.levels["DMG"] += 1
				hero["coins"] -= GameConstants.BOOST_DMG_COST
		3:  # Boost Cadência
			if hero["coins"] >= GameConstants.BOOST_RATE_COST:
				b.rate_boost += 0.05
				b.levels["RATE"] += 1
				hero["coins"] -= GameConstants.BOOST_RATE_COST
	boost_towers[boost_selected_index] = b
	_hide_range_indicator()
	boost_selected_index = -1

func _is_inside_base_point(p: Vector2) -> bool:
	return grid_manager.is_inside_base_point(p)

func _try_place_tower(pos: Vector2) -> void:
	# verificar moedas
	if hero["coins"] < GameConstants.TOWER_COST:
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
	var tower_world_pos = grid_manager.base_grid_to_world(grid_coord.x, grid_coord.y)
	
	# calcular direção baseada na posição relativa ao centro da base
	var bc = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
	var dir_vec = (tower_world_pos - bc).normalized()
	if dir_vec.length() < 0.1:
		dir_vec = Vector2(1, 0)  # padrão: direita
	
	towers.append({
		"pos": tower_world_pos,
		"grid_x": grid_coord.x,
		"grid_y": grid_coord.y,
		"cooldown": 0.0,
		"fire_rate": 1.5,
		"range": 260.0,
		"dirs": [dir_vec],
		"damage": 0.5,
		"levels": { "RANGE": 0, "RATE": 0, "DIRS": 0, "DMG": 0 }
	})
	hero["coins"] -= GameConstants.TOWER_COST
	_track_coin_spent(GameConstants.TOWER_COST)
	_track_tower_built("tower")
	placing_tower = false

# Blocos removidos - substituídos por Muralhas

func _try_place_barracks(pos: Vector2) -> void:
	# verificar moedas
	if hero["coins"] < GameConstants.BARRACKS_COST:
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
	var barracks_world_pos = grid_manager.base_grid_to_world(grid_coord.x, grid_coord.y)
	
	var initial_spawn_rate = 3.0  # spawna soldado a cada 3 segundos
	barracks.append({
		"pos": barracks_world_pos,
		"grid_x": grid_coord.x,
		"grid_y": grid_coord.y,
		"soldier_spawn_cd": initial_spawn_rate,  # inicializar com o tempo de spawn para não spawnar imediatamente
		"soldier_spawn_rate": initial_spawn_rate,
		"soldiers": [],
		"hold_time": 2.0,  # tempo que soldado segura monstro
		"damage": 0.3,  # dano por segundo do soldado
		"projectile_speed": 80.0,  # velocidade do projetil do soldado
		"levels": { "HOLD": 0, "DMG": 0, "SPAWN_RATE": 0, "PROJECTILE_SPEED": 0 }
	})
	hero["coins"] -= GameConstants.BARRACKS_COST
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

func _try_place_mine(pos: Vector2) -> void:
	if hero["coins"] < GameConstants.MINE_COST:
		placing_mine = false
		return
	if mines.size() >= GameConstants.MAX_MINES:
		placing_mine = false
		return
	if not grid_manager.is_inside_base_point(pos):
		placing_mine = false
		return
	
	# Verificar se está em um caminho (não permitir)
	if _is_on_path(pos):
		placing_mine = false
		return
	
	# Verificar se está no centro (não permitir)
	if _is_in_center_area(pos):
		placing_mine = false
		return
	
	var grid_coord = grid_manager.world_to_base_grid(pos)
	if not grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, GameConstants.MINE_SIZE_GRID, 4):
		placing_mine = false
		return
	grid_manager.set_grid_area(grid_coord.x, grid_coord.y, GameConstants.MINE_SIZE_GRID, 4)
	pathfinder.invalidate_cache()
	var mine_world_pos = grid_manager.base_grid_to_world(grid_coord.x, grid_coord.y)
	mines.append({
		"pos": mine_world_pos,
		"grid_x": grid_coord.x,
		"grid_y": grid_coord.y,
		"damage": 5.0,
		"triggered": false
	})
	hero["coins"] -= GameConstants.MINE_COST
	placing_mine = false

func _on_buy_slow_tower() -> void:
	if placing_slow_tower:
		return
	if hero["coins"] < GameConstants.SLOW_TOWER_COST:
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
	if hero["coins"] < GameConstants.SLOW_TOWER_COST:
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
	var tower_world_pos = grid_manager.base_grid_to_world(grid_coord.x, grid_coord.y)
	slow_towers.append({
		"pos": tower_world_pos,
		"grid_x": grid_coord.x,
		"grid_y": grid_coord.y,
		"range": 200.0,
		"slow_amount": 0.5,
		"slow_duration": 1.0,
		"cooldown": 0.0,
		"fire_rate": 0.5,
		"levels": {"RANGE": 0, "AMOUNT": 0, "DURATION": 0, "RATE": 0}
	})
	hero["coins"] -= GameConstants.SLOW_TOWER_COST
	_track_coin_spent(GameConstants.SLOW_TOWER_COST)
	_track_tower_built("slow_tower")
	placing_slow_tower = false

func _on_buy_aoe_tower() -> void:
	if placing_aoe_tower:
		return
	if hero["coins"] < GameConstants.AOE_TOWER_COST:
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
	if hero["coins"] < GameConstants.AOE_TOWER_COST:
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
	var tower_world_pos = grid_manager.base_grid_to_world(grid_coord.x, grid_coord.y)
	aoe_towers.append({
		"pos": tower_world_pos,
		"grid_x": grid_coord.x,
		"grid_y": grid_coord.y,
		"range": 180.0,
		"damage": 2.0,
		"aoe_radius": 60.0,
		"cooldown": 0.0,
		"fire_rate": 2.0,
		"levels": { "DMG": 0, "RATE": 0, "AREA": 0 }
	})
	hero["coins"] -= GameConstants.AOE_TOWER_COST
	_track_coin_spent(GameConstants.AOE_TOWER_COST)
	_track_tower_built("aoe_tower")
	placing_aoe_tower = false

func _on_buy_sniper_tower() -> void:
	if placing_sniper_tower:
		return
	if hero["coins"] < GameConstants.SNIPER_TOWER_COST:
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
	if hero["coins"] < GameConstants.SNIPER_TOWER_COST:
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
	var tower_world_pos = grid_manager.base_grid_to_world(grid_coord.x, grid_coord.y)
	sniper_towers.append({
		"pos": tower_world_pos,
		"grid_x": grid_coord.x,
		"grid_y": grid_coord.y,
		"range": 400.0,
		"damage": 5.0,
		"cooldown": 0.0,
		"fire_rate": 5.0,  # cooldown aumentado de 3.0 para 5.0 segundos
		"pierce": 1,
		"target_mode": 0,  # 0 = Boss, 1 = Mais próximo ao centro
		"levels": { "DMG": 0, "RATE": 0 }
	})
	hero["coins"] -= GameConstants.SNIPER_TOWER_COST
	_track_coin_spent(GameConstants.SNIPER_TOWER_COST)
	_track_tower_built("sniper_tower")
	placing_sniper_tower = false

func _on_buy_boost_tower() -> void:
	if placing_boost_tower:
		return
	if hero["coins"] < GameConstants.BOOST_TOWER_COST:
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
	if hero["coins"] < GameConstants.BOOST_TOWER_COST:
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
	var tower_world_pos = grid_manager.base_grid_to_world(grid_coord.x, grid_coord.y)
	boost_towers.append({
		"pos": tower_world_pos,
		"grid_x": grid_coord.x,
		"grid_y": grid_coord.y,
		"range": 150.0,
		"damage_boost": 0.5,
		"rate_boost": 0.3,
		"levels": {"RANGE": 0, "DMG": 0, "RATE": 0}
	})
	hero["coins"] -= GameConstants.BOOST_TOWER_COST
	_track_coin_spent(GameConstants.BOOST_TOWER_COST)
	_track_tower_built("boost_tower")
	placing_boost_tower = false

func _on_buy_shock_tower() -> void:
	if placing_shock_tower:
		return
	if hero["coins"] < GameConstants.SHOCK_TOWER_COST:
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
	if hero["coins"] < GameConstants.SHOCK_TOWER_COST:
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
	var tower_world_pos = grid_manager.base_grid_to_world(grid_coord.x, grid_coord.y)
	shock_towers.append({
		"pos": tower_world_pos,
		"grid_x": grid_coord.x,
		"grid_y": grid_coord.y,
		"range": 200.0,
		"damage": 1.5,
		"chain_count": 3,  # número de inimigos que o choque pode atingir
		"cooldown": 0.0,
		"fire_rate": 1.5,
		"levels": { "DMG": 0, "RATE": 0, "CHAIN": 0 }
	})
	hero["coins"] -= GameConstants.SHOCK_TOWER_COST
	_track_coin_spent(GameConstants.SHOCK_TOWER_COST)
	_track_tower_built("shock_tower")
	placing_shock_tower = false

func _on_buy_wall() -> void:
	if placing_wall:
		return
	if hero["coins"] < GameConstants.WALL_COST:
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
	if hero["coins"] < GameConstants.WALL_COST:
		placing_wall = false
		return
	if walls.size() >= GameConstants.MAX_WALLS:
		placing_wall = false
		return
	if not grid_manager.is_inside_base_point(pos):
		placing_wall = false
		return
	
	# Verificar se está em um caminho (não permitir)
	if _is_on_path(pos):
		placing_wall = false
		return
	
	# Verificar se está no centro (não permitir)
	if _is_in_center_area(pos):
		placing_wall = false
		return
	
	var grid_coord = grid_manager.world_to_base_grid(pos)
	if not grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, GameConstants.WALL_SIZE_GRID, 9):
		placing_wall = false
		return
	grid_manager.set_grid_area(grid_coord.x, grid_coord.y, GameConstants.WALL_SIZE_GRID, 9)
	pathfinder.invalidate_cache()
	var wall_world_pos = grid_manager.base_grid_to_world(grid_coord.x, grid_coord.y)
	walls.append({
		"pos": wall_world_pos,
		"grid_x": grid_coord.x,
		"grid_y": grid_coord.y,
		"hp": 20.0,
		"max_hp": 20.0
	})
	hero["coins"] -= GameConstants.WALL_COST
	_track_wall_built()
	placing_wall = false

func _try_move_tower(tower_idx: int, new_pos: Vector2) -> bool:
	if tower_idx < 0 or tower_idx >= towers.size():
		return false
	
	var tower = towers[tower_idx]
	
	# Limpar grid na posição antiga
	grid_manager.clear_grid_area(tower.grid_x, tower.grid_y, GameConstants.TOWER_SIZE_GRID)
	
	# Verificar nova posição
	if not grid_manager.is_inside_base_point(new_pos):
		# Restaurar grid antigo
		grid_manager.set_grid_area(tower.grid_x, tower.grid_y, GameConstants.TOWER_SIZE_GRID, 1)
		return false
	
	var new_grid_coord = grid_manager.world_to_base_grid(new_pos)
	if not grid_manager.can_place_in_grid(new_grid_coord.x, new_grid_coord.y, GameConstants.TOWER_SIZE_GRID, 1):
		# Restaurar grid antigo
		grid_manager.set_grid_area(tower.grid_x, tower.grid_y, GameConstants.TOWER_SIZE_GRID, 1)
		return false
	
	# Atualizar grid na nova posição
	grid_manager.set_grid_area(new_grid_coord.x, new_grid_coord.y, GameConstants.TOWER_SIZE_GRID, 1)
	pathfinder.invalidate_cache()
	
	# Atualizar posição da torre
	var new_world_pos = grid_manager.base_grid_to_world(new_grid_coord.x, new_grid_coord.y)
	tower.pos = new_world_pos
	tower.grid_x = new_grid_coord.x
	tower.grid_y = new_grid_coord.y
	
	towers[tower_idx] = tower
	return true

func _try_move_slow_tower(tower_idx: int, new_pos: Vector2) -> bool:
	if tower_idx < 0 or tower_idx >= slow_towers.size():
		return false
	
	var tower = slow_towers[tower_idx]
	grid_manager.clear_grid_area(tower.grid_x, tower.grid_y, GameConstants.SLOW_TOWER_SIZE_GRID)
	
	if not grid_manager.is_inside_base_point(new_pos):
		grid_manager.set_grid_area(tower.grid_x, tower.grid_y, GameConstants.SLOW_TOWER_SIZE_GRID, 5)
		return false
	
	var new_grid_coord = grid_manager.world_to_base_grid(new_pos)
	if not grid_manager.can_place_in_grid(new_grid_coord.x, new_grid_coord.y, GameConstants.SLOW_TOWER_SIZE_GRID, 5):
		grid_manager.set_grid_area(tower.grid_x, tower.grid_y, GameConstants.SLOW_TOWER_SIZE_GRID, 5)
		return false
	
	grid_manager.set_grid_area(new_grid_coord.x, new_grid_coord.y, GameConstants.SLOW_TOWER_SIZE_GRID, 5)
	pathfinder.invalidate_cache()
	
	var new_world_pos = grid_manager.base_grid_to_world(new_grid_coord.x, new_grid_coord.y)
	tower.pos = new_world_pos
	tower.grid_x = new_grid_coord.x
	tower.grid_y = new_grid_coord.y
	
	slow_towers[tower_idx] = tower
	return true

func _try_move_aoe_tower(tower_idx: int, new_pos: Vector2) -> bool:
	if tower_idx < 0 or tower_idx >= aoe_towers.size():
		return false
	
	var tower = aoe_towers[tower_idx]
	grid_manager.clear_grid_area(tower.grid_x, tower.grid_y, GameConstants.AOE_TOWER_SIZE_GRID)
	
	if not grid_manager.is_inside_base_point(new_pos):
		grid_manager.set_grid_area(tower.grid_x, tower.grid_y, GameConstants.AOE_TOWER_SIZE_GRID, 6)
		return false
	
	var new_grid_coord = grid_manager.world_to_base_grid(new_pos)
	if not grid_manager.can_place_in_grid(new_grid_coord.x, new_grid_coord.y, GameConstants.AOE_TOWER_SIZE_GRID, 6):
		grid_manager.set_grid_area(tower.grid_x, tower.grid_y, GameConstants.AOE_TOWER_SIZE_GRID, 6)
		return false
	
	grid_manager.set_grid_area(new_grid_coord.x, new_grid_coord.y, GameConstants.AOE_TOWER_SIZE_GRID, 6)
	pathfinder.invalidate_cache()
	
	var new_world_pos = grid_manager.base_grid_to_world(new_grid_coord.x, new_grid_coord.y)
	tower.pos = new_world_pos
	tower.grid_x = new_grid_coord.x
	tower.grid_y = new_grid_coord.y
	
	aoe_towers[tower_idx] = tower
	return true

func _try_move_sniper_tower(tower_idx: int, new_pos: Vector2) -> bool:
	if tower_idx < 0 or tower_idx >= sniper_towers.size():
		return false
	
	var tower = sniper_towers[tower_idx]
	grid_manager.clear_grid_area(tower.grid_x, tower.grid_y, GameConstants.SNIPER_TOWER_SIZE_GRID)
	
	if not grid_manager.is_inside_base_point(new_pos):
		grid_manager.set_grid_area(tower.grid_x, tower.grid_y, GameConstants.SNIPER_TOWER_SIZE_GRID, 7)
		return false
	
	var new_grid_coord = grid_manager.world_to_base_grid(new_pos)
	if not grid_manager.can_place_in_grid(new_grid_coord.x, new_grid_coord.y, GameConstants.SNIPER_TOWER_SIZE_GRID, 7):
		grid_manager.set_grid_area(tower.grid_x, tower.grid_y, GameConstants.SNIPER_TOWER_SIZE_GRID, 7)
		return false
	
	grid_manager.set_grid_area(new_grid_coord.x, new_grid_coord.y, GameConstants.SNIPER_TOWER_SIZE_GRID, 7)
	pathfinder.invalidate_cache()
	
	var new_world_pos = grid_manager.base_grid_to_world(new_grid_coord.x, new_grid_coord.y)
	tower.pos = new_world_pos
	tower.grid_x = new_grid_coord.x
	tower.grid_y = new_grid_coord.y
	
	sniper_towers[tower_idx] = tower
	return true

func _try_move_boost_tower(tower_idx: int, new_pos: Vector2) -> bool:
	if tower_idx < 0 or tower_idx >= boost_towers.size():
		return false
	
	var tower = boost_towers[tower_idx]
	grid_manager.clear_grid_area(tower.grid_x, tower.grid_y, GameConstants.BOOST_TOWER_SIZE_GRID)
	
	if not grid_manager.is_inside_base_point(new_pos):
		grid_manager.set_grid_area(tower.grid_x, tower.grid_y, GameConstants.BOOST_TOWER_SIZE_GRID, 8)
		return false
	
	var new_grid_coord = grid_manager.world_to_base_grid(new_pos)
	if not grid_manager.can_place_in_grid(new_grid_coord.x, new_grid_coord.y, GameConstants.BOOST_TOWER_SIZE_GRID, 8):
		grid_manager.set_grid_area(tower.grid_x, tower.grid_y, GameConstants.BOOST_TOWER_SIZE_GRID, 8)
		return false
	
	grid_manager.set_grid_area(new_grid_coord.x, new_grid_coord.y, GameConstants.BOOST_TOWER_SIZE_GRID, 8)
	pathfinder.invalidate_cache()
	
	var new_world_pos = grid_manager.base_grid_to_world(new_grid_coord.x, new_grid_coord.y)
	tower.pos = new_world_pos
	tower.grid_x = new_grid_coord.x
	tower.grid_y = new_grid_coord.y
	
	boost_towers[tower_idx] = tower
	return true

func _try_move_shock_tower(tower_idx: int, new_pos: Vector2) -> bool:
	if tower_idx < 0 or tower_idx >= shock_towers.size():
		return false
	
	var tower = shock_towers[tower_idx]
	grid_manager.clear_grid_area(tower.grid_x, tower.grid_y, GameConstants.SHOCK_TOWER_SIZE_GRID)
	
	if not grid_manager.is_inside_base_point(new_pos):
		grid_manager.set_grid_area(tower.grid_x, tower.grid_y, GameConstants.SHOCK_TOWER_SIZE_GRID, 9)
		return false
	
	var new_grid_coord = grid_manager.world_to_base_grid(new_pos)
	if not grid_manager.can_place_in_grid(new_grid_coord.x, new_grid_coord.y, GameConstants.SHOCK_TOWER_SIZE_GRID, 9):
		grid_manager.set_grid_area(tower.grid_x, tower.grid_y, GameConstants.SHOCK_TOWER_SIZE_GRID, 9)
		return false
	
	grid_manager.set_grid_area(new_grid_coord.x, new_grid_coord.y, GameConstants.SHOCK_TOWER_SIZE_GRID, 9)
	pathfinder.invalidate_cache()
	
	var new_world_pos = grid_manager.base_grid_to_world(new_grid_coord.x, new_grid_coord.y)
	tower.pos = new_world_pos
	tower.grid_x = new_grid_coord.x
	tower.grid_y = new_grid_coord.y
	
	shock_towers[tower_idx] = tower
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

func _physics_process(delta: float) -> void:
	# aplicar skill de boost de velocidade no herói
	var hero_rate_multiplier = 1.0
	if skill_speed_boost_active:
		hero_rate_multiplier = GameConstants.SKILL_SPEED_BOOST_MULTIPLIER
	
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
		if skill_speed_boost_active:
			rate_multiplier *= GameConstants.SKILL_SPEED_BOOST_MULTIPLIER
		
		var effective_fire_rate = t.fire_rate / rate_multiplier
		t.cooldown = max(0.0, t.cooldown - delta)
		if t.cooldown <= 0.0:
			_tower_fire_cross(t)
			t.cooldown = effective_fire_rate
	
	# atualizar novas torres (apenas se não estiver pausado)
	if not paused and not game_over:
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
	var tower_damage: float = tower.get("damage", 0.5)
	var has_freeze: bool = tower.get("has_freeze", false)
	var has_fire: bool = tower.get("has_fire", false)
	
	# aplicar boost de boost towers próximos
	var damage_multiplier = 1.0
	var rate_multiplier = 1.0
	for boost in boost_towers:
		var dist = tower.pos.distance_to(boost.pos)
		if dist <= boost.range:
			damage_multiplier += boost.damage_boost
			rate_multiplier += boost.rate_boost
	
	# aplicar skill de boost de dano
	if skill_damage_boost_active:
		damage_multiplier *= GameConstants.SKILL_DAMAGE_BOOST_MULTIPLIER
	
	tower_damage *= damage_multiplier
	var life := float(tower.get("range", 260.0)) / speed
	for d in dirs:
		var b = { "pos": tower.pos, "vel": d * speed, "life": life, "radius": 2, "damage": tower_damage, "pierce": 0, "has_freeze": has_freeze, "has_fire": has_fire }
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

func _update_mines(delta: float) -> void:
	var mines_to_remove: Array = []
	for i in range(mines.size()):
		var m = mines[i]
		if m.triggered:
			mines_to_remove.append(i)
			continue
		# verificar se algum inimigo passou pela mina
		for e in enemies:
			if e["hp"] <= 0 or e["reached"]:
				continue
			var dist = m.pos.distance_to(e["pos"])
			if dist < 15.0:  # raio de ativação
				# ativar mina
				e["hp"] -= m.damage
				_create_damage_number(e["pos"], m.damage, false)
				if e["hp"] <= 0:
					e["hp"] = 0
					e["dying"] = true
					e["dying_time"] = 0.0
					_create_death_animation(e["pos"])
					hero["coins"] += GameConstants.NORMAL_REWARD
					# chance de dropar moeda
					_try_drop_coin(e["pos"])
					# Rastrear achievements de kills
					_track_enemy_kill(false)
				m.triggered = true
				mines_to_remove.append(i)
				break
	# remover minas ativadas (em ordem reversa para não quebrar índices)
	mines_to_remove.reverse()
	for idx in mines_to_remove:
		if idx < mines.size():
			grid_manager.clear_grid_area(mines[idx].grid_x, mines[idx].grid_y, GameConstants.MINE_SIZE_GRID)
			mines.remove_at(idx)

func _update_slow_towers(delta: float) -> void:
	for st in slow_towers:
		# aplicar skill de boost de velocidade
		var slow_rate_multiplier = 1.0
		if skill_speed_boost_active:
			slow_rate_multiplier = GameConstants.SKILL_SPEED_BOOST_MULTIPLIER
		
		st.cooldown = max(0.0, st.cooldown - delta * slow_rate_multiplier)
		if st.cooldown <= 0.0:
			# aplicar slow em todos os inimigos no alcance
			for e in enemies:
				if e["hp"] <= 0 or e["reached"]:
					continue
				var dist = st.pos.distance_to(e["pos"])
				if dist <= st.range:
					var enemy_idx = e.get("idx", -1)
					if enemy_idx >= 0:
						if not enemy_effects.has(enemy_idx):
							enemy_effects[enemy_idx] = { "slow_time": 0.0, "slow_amount": 0.0, "freeze_time": 0.0, "fire_time": 0.0 }
						enemy_effects[enemy_idx].slow_time = st.slow_duration  # usar duração configurável
						enemy_effects[enemy_idx].slow_amount = st.slow_amount
			st.cooldown = st.fire_rate

func _update_aoe_towers(delta: float) -> void:
	if paused or game_over:
		return
	for aoe in aoe_towers:
		# aplicar skill de boost de velocidade
		var aoe_rate_multiplier = 1.0
		if skill_speed_boost_active:
			aoe_rate_multiplier = GameConstants.SKILL_SPEED_BOOST_MULTIPLIER
		
		aoe.cooldown = max(0.0, aoe.cooldown - delta * aoe_rate_multiplier)
		if aoe.cooldown <= 0.0:
			# encontrar inimigo mais próximo
			var closest_enemy = null
			var closest_dist = aoe.range + 1.0  # +1 para garantir que encontre o mais próximo
			for e in enemies:
				if e["hp"] <= 0 or e["reached"]:
					continue
				var dist = aoe.pos.distance_to(e["pos"])
				if dist <= aoe.range and dist < closest_dist:
					closest_dist = dist
					closest_enemy = e
			if closest_enemy != null:
				# criar projétil de canhão (bola preta) até o alvo
				var cannon_speed = 200.0
				# aplicar skill de boost de dano
				var aoe_damage = aoe.damage
				if skill_damage_boost_active:
					aoe_damage *= GameConstants.SKILL_DAMAGE_BOOST_MULTIPLIER
				
				aoe_cannon_projectiles.append({
					"pos": aoe.pos,
					"target": closest_enemy["pos"],
					"speed": cannon_speed,
					"radius": aoe.aoe_radius,
					"damage": aoe_damage,
					"aoe_tower": aoe
				})
				# resetar cooldown apenas se encontrou alvo
				aoe.cooldown = aoe.fire_rate
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
			aoe_effects.append({
				"pos": proj.target,
				"time": 0.0,
				"max_time": 0.3,
				"radius": proj.radius
			})
			# causar dano em área
			for e in enemies:
				if e["hp"] <= 0 or e["reached"]:
					continue
				var dist = proj.target.distance_to(e["pos"])
				if dist <= proj.radius:
					e["hp"] -= proj.damage
					_create_damage_number(e["pos"], proj.damage, false)
					if e["hp"] <= 0:
						e["hp"] = 0
						e["dying"] = true
						e["dying_time"] = 0.0
						_create_death_animation(e["pos"])
						hero["coins"] += GameConstants.NORMAL_REWARD
						# chance de dropar moeda
						_try_drop_coin(e["pos"])
						# Rastrear achievements de kills
						_track_enemy_kill(false)
		else:
			# mover projétil em direção ao alvo
			proj.pos += dir * move_dist
			new_cannon_projectiles.append(proj)
	aoe_cannon_projectiles = new_cannon_projectiles

func _update_sniper_towers(delta: float) -> void:
	if paused or game_over:
		return
	for sniper in sniper_towers:
		sniper.cooldown = max(0.0, sniper.cooldown - delta)
		if sniper.cooldown <= 0.0:
			var target_mode = sniper.get("target_mode", 0)  # 0 = Boss, 1 = Mais próximo ao centro
			var target_enemy = null
			var target_dist = -1.0
			var base_center = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
			
			if target_mode == 0:
				# Modo Boss: procurar boss primeiro, se não encontrar, usar comportamento padrão (mais distante)
				var boss_found = false
				for e in enemies:
					if e["hp"] <= 0 or e["reached"]:
						continue
					if e.get("is_boss", false):
						var dist = sniper.pos.distance_to(e["pos"])
						if dist <= sniper.range:
							target_enemy = e
							target_dist = dist
							boss_found = true
							break
				
				# Se não encontrou boss, procurar inimigo mais distante (comportamento padrão)
				if not boss_found:
					for e in enemies:
						if e["hp"] <= 0 or e["reached"]:
							continue
						var dist = sniper.pos.distance_to(e["pos"])
						if dist <= sniper.range and dist > target_dist:
							target_enemy = e
							target_dist = dist
			else:
				# Modo Mais Próximo ao Centro: procurar inimigo mais próximo ao centro da base
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
			if target_enemy != null:
				# criar efeito visual de linha de tiro
				var dir = (target_enemy["pos"] - sniper.pos).normalized()
				var hit_pos = target_enemy["pos"]
				sniper_effects.append({
					"start": sniper.pos,
					"end": hit_pos,
					"time": 0.0,
					"max_time": 0.15
				})
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
				# aplicar skill de boost de dano
				var sniper_damage = sniper.damage
				if skill_damage_boost_active:
					sniper_damage *= GameConstants.SKILL_DAMAGE_BOOST_MULTIPLIER
				
				# causar dano nos primeiros (pierce + 1) inimigos
				var pierce_count = sniper.pierce + 1  # pierce=1 significa atinge 2 inimigos
				for i in range(min(pierce_count, enemies_in_line.size())):
					var e = enemies_in_line[i].enemy
					e["hp"] -= sniper_damage
					_create_damage_number(e["pos"], sniper_damage, true)  # crítico para sniper
					if e["hp"] <= 0:
						e["hp"] = 0
						e["dying"] = true
						e["dying_time"] = 0.0
						_create_death_animation(e["pos"])
						hero["coins"] += GameConstants.NORMAL_REWARD
						# chance de dropar moeda
						_try_drop_coin(e["pos"])
						# Rastrear achievements de kills
						_track_enemy_kill(false)
				# resetar cooldown apenas se encontrou alvo
				sniper.cooldown = sniper.fire_rate
			else:
				# se não encontrou alvo, manter cooldown em 0 para tentar novamente no próximo frame
				sniper.cooldown = 0.0

func _update_boost_towers(delta: float) -> void:
	# boost towers não precisam de atualização - o efeito é aplicado quando torres atiram
	pass

func _update_shock_towers(delta: float) -> void:
	for shock in shock_towers:
		shock.cooldown = max(0.0, shock.cooldown - delta)
		if shock.cooldown <= 0.0:
			# Encontrar inimigo mais próximo
			var closest_enemy = null
			var closest_dist = shock.range
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
				
				# aplicar skill de boost de dano
				var shock_damage = shock.damage
				if skill_damage_boost_active:
					shock_damage *= GameConstants.SKILL_DAMAGE_BOOST_MULTIPLIER
				
				# Aplicar dano a todos os alvos da cadeia
				for target in chain_targets:
					target["hp"] -= shock_damage
					_create_damage_number(target["pos"], shock_damage, false, Color(0.5, 0.8, 1.0))  # azul para choque
					if target["hp"] <= 0:
						target["hp"] = 0
						target["dying"] = true
						target["dying_time"] = 0.0
						_create_death_animation(target["pos"])
						var is_boss = target.get("is_boss", false)
						hero["coins"] += GameConstants.BOSS_REWARD_MULTIPLIER * GameConstants.NORMAL_REWARD if is_boss else GameConstants.NORMAL_REWARD
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
				
				shock.cooldown = shock.fire_rate

func _create_shock_effect(start_pos: Vector2, end_pos: Vector2) -> void:
	# Criar efeito visual de choque elétrico (raio/trovão)
	var shock_effect = {
		"start": start_pos,
		"end": end_pos,
		"time": 0.0,
		"max_time": 0.15  # efeito rápido como um raio
	}
	shock_effects.append(shock_effect)

func _update_walls(delta: float) -> void:
	# walls podem ser danificadas por inimigos que passam por perto
	var walls_to_remove: Array = []
	for i in range(walls.size()):
		var w = walls[i]
		if w.hp <= 0:
			walls_to_remove.append(i)
			continue
		for e in enemies:
			if e["hp"] <= 0 or e["reached"]:
				continue
			var dist = w.pos.distance_to(e["pos"])
			if dist < 20.0:  # inimigo próximo da parede
				w.hp -= 0.5 * delta  # dano por segundo
				if w.hp <= 0:
					grid_manager.clear_grid_area(w.grid_x, w.grid_y, GameConstants.WALL_SIZE_GRID)
					pathfinder.invalidate_cache()
					walls_to_remove.append(i)
					break
	# remover paredes destruídas
	walls_to_remove.reverse()
	for idx in walls_to_remove:
		if idx < walls.size():
			walls.remove_at(idx)

func _update_healing_stations(delta: float) -> void:
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
				# chefe dá 20x mais moedas (40 vs 2)
				hero["coins"] += 40 if is_boss else 2
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
		
		var button_text = "Slot %d" % i
		if has_save:
			var wave = slot_info.get("wave", 0)
			var coins = slot_info.get("coins", 0)
			var save_time = slot_info.get("save_time", "Desconhecido")
			button_text = "Slot %d (Wave: %d | Moedas: %d)\n%s" % [i, wave, coins, save_time]
		else:
			button_text = "Slot %d (Vazio)" % i
		
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
			var base_hp = slot_info.get("base_hp", 100)
			var save_time = slot_info.get("save_time", "Desconhecido")
			var is_autosave = slot_info.get("is_autosave", false)
			
			# Formatar nome do slot
			var display_name = ""
			if is_autosave:
				display_name = "Auto-save"
			elif slot_name.begins_with("slot"):
				var slot_num = slot_name.substr(4)
				display_name = "Slot %s" % slot_num
			else:
				display_name = slot_name
			
			# Texto do botão
			var button_text = "%s\nWave: %d | Moedas: %d | Vida: %d\n%s" % [display_name, wave, coins, base_hp, save_time]
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
		save_status_label.text = "Slot não encontrado!"
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
	pathfinder.invalidate_cache()
	_reset_build_and_selection_state()

func _rebuild_base_grid_from_structures() -> void:
	if grid_manager == null:
		return
	grid_manager.reset_base_grid()
	_occupy_structures_in_grid(towers, GameConstants.TOWER_SIZE_GRID, 1)
	_occupy_structures_in_grid(barracks, GameConstants.BARRACKS_SIZE_GRID, 3)
	_occupy_structures_in_grid(mines, GameConstants.MINE_SIZE_GRID, 4)
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
	# chance aleatória de dropar moeda (base + perks)
	if randf() < coin_drop_chance:
		var coin_value = randi_range(GameConstants.COIN_MIN_VALUE, GameConstants.COIN_MAX_VALUE)
		dropped_coins.append({
			"pos": pos,
			"value": coin_value,
			"lifetime": 0.0,
			"max_lifetime": GameConstants.COIN_LIFETIME,
			"collected": false
		})

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
	# Criar efeito visual de coleta de moeda (amarelo/dourado)
	var effect = {
		"pos": pos,
		"time": 0.0,
		"max_time": 0.5,  # duração do efeito em segundos
		"particles": []
	}
	
	# Criar partículas que voam para fora (estrelas/brilhos)
	var particle_count = 12
	for i in range(particle_count):
		var angle = (TAU / particle_count) * i  # distribuir uniformemente em círculo
		var speed = randf_range(80.0, 150.0)
		var vel = Vector2(cos(angle), sin(angle)) * speed
		var particle = {
			"pos": pos,
			"vel": vel,
			"time": 0.0,
			"max_time": randf_range(0.3, 0.6)
		}
		effect.particles.append(particle)
	
	coin_collect_effects.append(effect)

func _play_coin_sound() -> void:
	# Tocar som de coleta de moeda
	var sound_player = get_node_or_null("SoundEffectsPlayer")
	if sound_player:
		# Tentar carregar som da moeda (suporta múltiplos formatos)
		var coin_sound = _try_load_music("res://assets/sounds/coin_collect.ogg")
		if coin_sound == null:
			coin_sound = _try_load_music("res://assets/sounds/coin_collect.mp3")
		if coin_sound == null:
			coin_sound = _try_load_music("res://assets/sounds/coin_collect.wav")
		
		if coin_sound != null:
			sound_player.stream = coin_sound
			sound_player.play()
		# Se o som não existir, não faz nada (não mostra erro para não poluir o console)

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
	hud.add_child(tower_shop_panel)
	
	# Configurar posição e tamanho do painel (lado direito da tela)
	var screen_width = get_viewport().get_visible_rect().size.x
	var screen_height = get_viewport().get_visible_rect().size.y
	var panel_width = 350.0  # Aumentado para garantir espaço para o botão completo
	# Calcular altura necessária: card do herói + 10 torres * 80px + título 45px + espaçamento
	var hero_card_height = 100
	var total_items_height = hero_card_height + 10 * 80 + 20
	var required_height = total_items_height + 45  # +45 para o título
	var panel_height = max(screen_height - 44.0, required_height)  # altura mínima para caber tudo
	# Posicionar no lado direito (skills ficará à esquerda deste painel)
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
	
	# Título do painel
	var title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "LOJA DE TORRES"
	title_label.position = Vector2(10, 10)
	title_label.size = Vector2(panel_width - 20, 30)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tower_shop_panel.add_child(title_label)
	
	# Container para botões de torres (sem scroll - tamanho fixo para mostrar tudo)
	var vbox = VBoxContainer.new()
	vbox.name = "TowerButtonsContainer"
	vbox.position = Vector2(10, 45)
	vbox.size = Vector2(panel_width - 20, panel_height - 45)
	vbox.add_theme_constant_override("separation", 5)
	tower_shop_panel.add_child(vbox)
	
	# Card da base/Herói
	_create_hero_home_card(vbox, hero_card_height)
	
	# Lista de torres com informações
	var tower_data = [
		{"name": "Torre Básica", "cost": GameConstants.TOWER_COST, "icon": tex_tower, "func": "_on_buy_tower", "max": GameConstants.MAX_TOWERS, "array": towers},
		{"name": "Quartel", "cost": GameConstants.BARRACKS_COST, "icon": tex_barracks, "func": "_on_buy_barracks", "max": GameConstants.MAX_BARRACKS, "array": barracks},
		{"name": "Mina", "cost": GameConstants.MINE_COST, "icon": tex_mine, "func": "_on_buy_mine", "max": GameConstants.MAX_MINES, "array": mines},
		{"name": "Slow Tower", "cost": GameConstants.SLOW_TOWER_COST, "icon": tex_slow_tower, "func": "_on_buy_slow_tower", "max": GameConstants.MAX_SLOW_TOWERS, "array": slow_towers},
		{"name": "AOE Tower", "cost": GameConstants.AOE_TOWER_COST, "icon": tex_aoe_tower, "func": "_on_buy_aoe_tower", "max": GameConstants.MAX_AOE_TOWERS, "array": aoe_towers},
		{"name": "Sniper Tower", "cost": GameConstants.SNIPER_TOWER_COST, "icon": tex_sniper_tower, "func": "_on_buy_sniper_tower", "max": GameConstants.MAX_SNIPER_TOWERS, "array": sniper_towers},
		{"name": "Boost Tower", "cost": GameConstants.BOOST_TOWER_COST, "icon": tex_boost_tower, "func": "_on_buy_boost_tower", "max": GameConstants.MAX_BOOST_TOWERS, "array": boost_towers},
		{"name": "Shock Tower", "cost": GameConstants.SHOCK_TOWER_COST, "icon": tex_shock_tower, "func": "_on_buy_shock_tower", "max": GameConstants.MAX_SHOCK_TOWERS, "array": shock_towers},
		{"name": "Muralha", "cost": GameConstants.WALL_COST, "icon": tex_wall_structure, "func": "_on_buy_wall", "max": GameConstants.MAX_WALLS, "array": walls},
		{"name": "Estação de Cura", "cost": GameConstants.HEALING_STATION_COST, "icon": tex_healing_station, "func": "_on_buy_healing_station", "max": GameConstants.MAX_HEALING_STATIONS, "array": healing_stations},
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
	
	# Criar tooltip
	tooltip_label = Label.new()
	tooltip_label.name = "TooltipLabel"
	tooltip_label.visible = false
	tooltip_label.position = Vector2(10, 10)
	tooltip_label.size = Vector2(180, 100)
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
	
	# Título do painel
	var title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "SKILLS"
	title_label.position = Vector2(10, 10)
	title_label.size = Vector2(panel_width - 20, 35)
	title_label.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skills_panel.add_child(title_label)
	
	# Container para botões de skills
	var vbox = VBoxContainer.new()
	vbox.name = "SkillsButtonsContainer"
	vbox.position = Vector2(10, 50)
	vbox.size = Vector2(panel_width - 20, panel_height - 50)
	vbox.add_theme_constant_override("separation", 10)
	skills_panel.add_child(vbox)
	
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
	var coin_icon = TextureRect.new()
	coin_icon.custom_minimum_size = Vector2(50, 50)
	coin_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if tex_coin != null:
		coin_icon.texture = tex_coin
	skill1_hbox.add_child(coin_icon)
	
	# Texto da skill
	var skill1_text = VBoxContainer.new()
	skill1_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill1_hbox.add_child(skill1_text)
	
	var skill1_name = Label.new()
	skill1_name.text = "Coletar Moedas"
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
	skill2_name.text = "Boost de Dano"
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
	skill3_name.text = "Boost de Velocidade"
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
	skill4_name.text = "Slow Global"
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
	for i in range(RANGE_INDICATOR_SEGMENTS + 1):
		var angle = TAU * float(i) / float(RANGE_INDICATOR_SEGMENTS)
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
	# Só mostrar se algum menu de upgrade estiver aberto
	if not _is_any_upgrade_menu_visible():
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
	_hide_range_indicator()

func _on_skill_collect_coins() -> void:
	# Verificar cooldown
	if skill_collect_coins_cooldown > 0.0:
		return
	
	# Achievement: usar skill
	if not skill_used:
		achievement_manager.increment_progress("collect_skill")
		skill_used = true
	
	# Coletar todas as moedas do mapa
	var total_collected = 0
	for coin in dropped_coins:
		if not coin.collected:
			hero["coins"] += coin.value
			total_collected += coin.value
			coin.collected = true
			# Criar efeito visual de coleta
			_play_coin_sound()
	
	# Remover moedas coletadas
	var new_coins: Array = []
	for coin in dropped_coins:
		if not coin.collected:
			new_coins.append(coin)
	dropped_coins = new_coins
	
	# Ativar cooldown
	skill_collect_coins_cooldown = GameConstants.SKILL_COLLECT_COINS_COOLDOWN
	
	if total_collected > 0:
		print("Coletadas %d moedas!" % total_collected)

func _on_skill_slow_all() -> void:
	# Verificar cooldown
	if skill_slow_all_cooldown > 0.0:
		return
	if skill_slow_all_active:
		return  # Já está ativo
	
	skill_slow_all_active = true
	skill_slow_all_time = GameConstants.SKILL_SLOW_ALL_DURATION
	skill_slow_all_cooldown = GameConstants.SKILL_SLOW_ALL_COOLDOWN
	
	# Aplicar slow em todos os inimigos através do sistema de efeitos
	for i in range(enemies.size()):
		var e = enemies[i]
		var enemy_idx = e.get("idx", i)
		if not enemy_effects.has(enemy_idx):
			enemy_effects[enemy_idx] = { "slow_time": 0.0, "slow_amount": 0.0, "freeze_time": 0.0, "fire_time": 0.0 }
		# Aplicar slow global (sobrescreve outros slows temporariamente)
		enemy_effects[enemy_idx].slow_time = GameConstants.SKILL_SLOW_ALL_DURATION
		enemy_effects[enemy_idx].slow_amount = GameConstants.SKILL_SLOW_ALL_AMOUNT
	
	print("Slow Global ativado por %.0f segundos!" % skill_slow_all_time)

func _on_skill_damage_boost() -> void:
	# Verificar cooldown
	if skill_damage_boost_cooldown > 0.0:
		return
	if skill_damage_boost_active:
		return  # Já está ativo
	
	skill_damage_boost_active = true
	skill_damage_boost_time = GameConstants.SKILL_DAMAGE_BOOST_DURATION
	skill_damage_boost_cooldown = GameConstants.SKILL_DAMAGE_BOOST_COOLDOWN
	print("Boost de Dano ativado por %.0f segundos!" % skill_damage_boost_time)

func _on_skill_speed_boost() -> void:
	# Verificar cooldown
	if skill_speed_boost_cooldown > 0.0:
		return
	if skill_speed_boost_active:
		return  # Já está ativo
	
	skill_speed_boost_active = true
	skill_speed_boost_time = GameConstants.SKILL_SPEED_BOOST_DURATION
	skill_speed_boost_cooldown = GameConstants.SKILL_SPEED_BOOST_COOLDOWN
	print("Boost de Velocidade ativado por %.0f segundos!" % skill_speed_boost_time)

func _update_skills_ui() -> void:
	if not skills_panel:
		return
	
	# Atualizar Skill 1: Coletar Moedas
	if skill_buttons.has("collect_coins"):
		var btn_data = skill_buttons["collect_coins"]
		var btn = btn_data.button
		var cooldown_label = btn_data.cooldown_label
		
		if skill_collect_coins_cooldown > 0.0:
			btn.disabled = true
			cooldown_label.text = "Cooldown: %.1fs" % skill_collect_coins_cooldown
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
		
		if skill_damage_boost_cooldown > 0.0 or skill_damage_boost_active:
			btn.disabled = true
			if skill_damage_boost_active:
				cooldown_label.text = "Ativo: %.1fs" % skill_damage_boost_time
			else:
				cooldown_label.text = "Cooldown: %.1fs" % skill_damage_boost_cooldown
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
		
		if skill_speed_boost_cooldown > 0.0 or skill_speed_boost_active:
			btn.disabled = true
			if skill_speed_boost_active:
				cooldown_label.text = "Ativo: %.1fs" % skill_speed_boost_time
			else:
				cooldown_label.text = "Cooldown: %.1fs" % skill_speed_boost_cooldown
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
		
		if skill_slow_all_cooldown > 0.0 or skill_slow_all_active:
			btn.disabled = true
			if skill_slow_all_active:
				cooldown_label.text = "Ativo: %.1fs" % skill_slow_all_time
			else:
				cooldown_label.text = "Cooldown: %.1fs" % skill_slow_all_cooldown
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
	alert_label.position = Vector2(-alert_label.size.x * 0.5, -alert_label.size.y * 0.5)
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

func _toggle_music() -> void:
	music_muted = not music_muted
	var music_player = get_node_or_null("MusicPlayer")
	if music_player:
		if music_muted:
			music_player.volume_db = -80.0  # Muito baixo = mutado
		else:
			music_player.volume_db = -5.0  # Volume normal
	
	# Atualizar texto do botão
	var tb = $CanvasLayer/HUD/TopBar
	if tb.has_node("BtnMuteMusic"):
		var btn_mute = tb.get_node("BtnMuteMusic")
		btn_mute.text = "🔇" if music_muted else "🔊"

func _create_death_animation(pos: Vector2) -> void:
	# Criar animação de morte (fade out e shrink)
	var death_anim = {
		"pos": pos,
		"time": 0.0,
		"max_time": 0.5,  # meio segundo de animação
		"scale": 1.0,
		"alpha": 1.0
	}
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
	
	# Rastrear kills de boss
	if is_boss:
		total_boss_kills += 1
		achievement_manager.increment_progress("boss_kill")
		achievement_manager.increment_progress("boss_kill_10")
		achievement_manager.increment_progress("boss_kill_50")
		achievement_manager.increment_progress("boss_kill_100")

func _track_tower_built(tower_type: String) -> void:
	towers_built += 1
	tower_types_built[tower_type] = true
	
	# Rastrear achievements de torres
	achievement_manager.increment_progress("build_10_towers")
	achievement_manager.increment_progress("build_50_towers")
	achievement_manager.increment_progress("build_100_towers")
	
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
		
		# Verificar se sobreviveu 100 waves sem dano
		if perfect_waves >= 100:
			achievement_manager.set_progress("survive_100_waves_no_damage", 100)

func _apply_perk_effects() -> void:
	var effects = perk_manager.apply_perk_effects(self)
	perk_effects = effects
	
	# Aplicar efeitos de perks
	if effects.has("starting_coins"):
		hero["coins"] += int(effects["starting_coins"])
	
	if effects.has("starting_hp"):
		base_hp += int(effects["starting_hp"])
	
	# Aplicar chance de drop de moeda (base 10% + perks)
	coin_drop_chance = GameConstants.COIN_DROP_CHANCE
	if effects.has("coin_drop_chance"):
		coin_drop_chance += effects["coin_drop_chance"]
		# Limitar a 100% (embora não deva chegar lá)
		coin_drop_chance = min(coin_drop_chance, 1.0)
	_apply_hero_home_coin_bonus_from_scratch()
	
	# Outros efeitos serão aplicados durante o jogo conforme necessário
	# (coin_value, tower_cost_reduction, etc.)
