extends Node2D

# Pré-carregar classes
const GridManager = preload("res://scripts/GridManager.gd")
const Pathfinder = preload("res://scripts/Pathfinder.gd")
const WaveManager = preload("res://scripts/WaveManager.gd")
const ProjectileManager = preload("res://scripts/ProjectileManager.gd")
const GameConstants = preload("res://scripts/Constants.gd")

# Managers
var grid_manager: GridManager
var pathfinder: Pathfinder
var wave_manager: WaveManager
var projectile_manager: ProjectileManager

var grid_offset: Vector2  # offset para centralizar o grid na tela

var enemies: Array = []
var arrows: Array = []  # TODO: migrar para projectile_manager
var tower_bullets: Array = []  # TODO: migrar para projectile_manager
var aoe_effects: Array = []  # efeitos visuais de explosão AOE: {pos: Vector2, time: float, max_time: float}
var sniper_effects: Array = []  # efeitos visuais de tiro sniper: {start: Vector2, end: Vector2, time: float, max_time: float}

var base_hp := 100
var paused := false
var game_over := false
var placing_tower := false
var placing_barracks := false
var placing_mine := false
var placing_slow_tower := false
var placing_aoe_tower := false
var placing_sniper_tower := false
var placing_boost_tower := false
var placing_wall := false
var placing_healing_station := false

var towers: Array = []
var barracks: Array = []  # quartéis - cada quartel: {grid_x: int, grid_y: int, pos: Vector2, soldier_spawn_cd: float, soldiers: Array}
var mines: Array = []  # minas: {grid_x: int, grid_y: int, pos: Vector2, damage: float, triggered: bool}
var slow_towers: Array = []  # slow towers: {grid_x: int, grid_y: int, pos: Vector2, range: float, slow_amount: float, cooldown: float, fire_rate: float}
var aoe_towers: Array = []  # AOE towers: {grid_x: int, grid_y: int, pos: Vector2, range: float, damage: float, aoe_radius: float, cooldown: float, fire_rate: float}
var sniper_towers: Array = []  # sniper towers: {grid_x: int, grid_y: int, pos: Vector2, range: float, damage: float, cooldown: float, fire_rate: float, pierce: int}
var boost_towers: Array = []  # boost towers: {grid_x: int, grid_y: int, pos: Vector2, range: float, damage_boost: float, rate_boost: float}
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

# enemy status effects
var enemy_effects: Dictionary = {}  # enemy_idx -> {freeze_time: float, fire_time: float, fire_damage: float}

# textures (opcionais)
var tex_hero: Texture2D
var tex_enemy_zombie: Texture2D
var tex_enemy_humanoid: Texture2D
var tex_enemy_robot: Texture2D
var tex_tent: Texture2D
var tex_grass: Texture2D
var tex_path: Texture2D  # Textura para o caminho (chão onde inimigos andam)
var tex_wall: Texture2D  # Textura para barreira/cerca (paredes do labirinto)

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

func _try_load(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _try_load_music(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _ready() -> void:
	# Inicializar managers
	grid_manager = GridManager.new()
	pathfinder = Pathfinder.new(grid_manager.grid, grid_manager.center)
	wave_manager = WaveManager.new()
	projectile_manager = ProjectileManager.new()
	
	# Conectar signal do wave_manager
	wave_manager.wave_started.connect(_on_wave_started)
	
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

	# tentar carregar assets Kenney se existirem
	tex_hero = _try_load("res://assets/images/hero.png")
	tex_enemy_zombie = _try_load("res://assets/images/enemy_zombie.png")
	tex_enemy_humanoid = _try_load("res://assets/images/enemy_humanoid.png")
	tex_enemy_robot = _try_load("res://assets/images/enemy_robot.png")
	tex_tent = _try_load("res://assets/images/tent.png")
	tex_grass = _try_load("res://assets/images/grass.png")
	tex_path = _try_load("res://assets/images/path.png")  # Textura do caminho
	tex_wall = _try_load("res://assets/images/wall.png")  # Textura da barreira/cerca

	# wire UI
	var tb = $CanvasLayer/HUD/TopBar
	tb.get_node("BtnKillAll").pressed.connect(func(): enemies.clear())
	
	# botão para pular para wave 10 (debug)
	if not tb.has_node("BtnJumpWave10"):
		var btn_jump = Button.new()
		btn_jump.name = "BtnJumpWave10"
		btn_jump.text = "Wave 10"
		btn_jump.position = Vector2(600, 8)
		btn_jump.size = Vector2(90, 28)
		tb.add_child(btn_jump)
		btn_jump.pressed.connect(_jump_to_wave_10)
	
	# top bar fixa: posição X=0 (alinhada à esquerda) e Y=0 (topo), mesma largura do grid
	tb.position = Vector2(0.0, 0.0)
	tb.size = Vector2(grid_px_w, bar_height)
	
	# criar menu dropdown para compras
	var buy_menu: PopupMenu
	if not tb.has_node("BuyMenuButton"):
		var menu_btn = MenuButton.new()
		menu_btn.name = "BuyMenuButton"
		tb.add_child(menu_btn)
		menu_btn.position = Vector2(810, 8)
		menu_btn.size = Vector2(180, 28)
		menu_btn.text = "Comprar"
		buy_menu = menu_btn.get_popup()
		buy_menu.add_item("Torre (%d)" % GameConstants.TOWER_COST, 1)
		buy_menu.add_item("Quartel (%d)" % GameConstants.BARRACKS_COST, 2)
		buy_menu.add_item("Mina (%d)" % GameConstants.MINE_COST, 3)
		buy_menu.add_item("Slow Tower (%d)" % GameConstants.SLOW_TOWER_COST, 4)
		buy_menu.add_item("AOE Tower (%d)" % GameConstants.AOE_TOWER_COST, 5)
		buy_menu.add_item("Sniper Tower (%d)" % GameConstants.SNIPER_TOWER_COST, 6)
		buy_menu.add_item("Boost Tower (%d)" % GameConstants.BOOST_TOWER_COST, 7)
		buy_menu.add_item("Muralha (%d)" % GameConstants.WALL_COST, 8)
		buy_menu.add_item("Cura (%d)" % GameConstants.HEALING_STATION_COST, 9)
		buy_menu.id_pressed.connect(_on_buy_menu_pressed)
	else:
		var menu_btn = tb.get_node("BuyMenuButton")
		buy_menu = menu_btn.get_popup()
		if not buy_menu.id_pressed.is_connected(_on_buy_menu_pressed):
			buy_menu.id_pressed.connect(_on_buy_menu_pressed)
	
	# remover botões antigos se existirem
	if tb.has_node("BtnBuyTower"):
		tb.get_node("BtnBuyTower").queue_free()
	if tb.has_node("BtnBuyBlock"):
		tb.get_node("BtnBuyBlock").queue_free()
	if tb.has_node("BtnBuyBarracks"):
		tb.get_node("BtnBuyBarracks").queue_free()

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
	barracks_menu.add_item("+1 Soldado", 3)
	barracks_menu.id_pressed.connect(Callable(self, "_on_barracks_menu_pressed"))
	barracks_menu_container.add_child(barracks_menu)
	$CanvasLayer.add_child(barracks_menu_container)

	var ov = $CanvasLayer/UpgradeOverlay
	ov.get_node("Panel/Btn1").pressed.connect(func(): _apply_benefit(0))
	ov.get_node("Panel/Btn2").pressed.connect(func(): _apply_benefit(1))
	ov.get_node("Panel/Btn3").pressed.connect(func(): _apply_benefit(2))
	ov.get_node("Panel/BtnResume").pressed.connect(func(): _resume_after_upgrade())

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
	
	set_process(true)
	set_physics_process(true)

func _process(delta: float) -> void:
	if paused or game_over:
		return

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
	# remover inimigos mortos/que chegaram na base e limpar efeitos
	var alive: Array = []
	var new_enemy_effects: Dictionary = {}
	var enemy_idx_map: Dictionary = {}  # mapear índice antigo -> novo
	
	for i in range(enemies.size()):
		var e = enemies[i]
		if e["hp"] > 0 and not e["reached"]:
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
	
	# atualizar menu dropdown de compras
	if tb.has_node("BuyMenuButton"):
		var menu_btn = tb.get_node("BuyMenuButton")
		var buy_menu_popup = menu_btn.get_popup()
		buy_menu_popup.set_item_text(0, "Torre (%d) [%d/%d]" % [GameConstants.TOWER_COST, towers.size(), GameConstants.MAX_TOWERS])
		buy_menu_popup.set_item_text(1, "Quartel (%d) [%d/%d]" % [GameConstants.BARRACKS_COST, barracks.size(), GameConstants.MAX_BARRACKS])
		buy_menu_popup.set_item_text(2, "Mina (%d) [%d/%d]" % [GameConstants.MINE_COST, mines.size(), GameConstants.MAX_MINES])
		buy_menu_popup.set_item_text(3, "Slow Tower (%d) [%d/%d]" % [GameConstants.SLOW_TOWER_COST, slow_towers.size(), GameConstants.MAX_SLOW_TOWERS])
		buy_menu_popup.set_item_text(4, "AOE Tower (%d) [%d/%d]" % [GameConstants.AOE_TOWER_COST, aoe_towers.size(), GameConstants.MAX_AOE_TOWERS])
		buy_menu_popup.set_item_text(5, "Sniper Tower (%d) [%d/%d]" % [GameConstants.SNIPER_TOWER_COST, sniper_towers.size(), GameConstants.MAX_SNIPER_TOWERS])
		buy_menu_popup.set_item_text(6, "Boost Tower (%d) [%d/%d]" % [GameConstants.BOOST_TOWER_COST, boost_towers.size(), GameConstants.MAX_BOOST_TOWERS])
		buy_menu_popup.set_item_text(7, "Muralha (%d) [%d/%d]" % [GameConstants.WALL_COST, walls.size(), GameConstants.MAX_WALLS])
		buy_menu_popup.set_item_text(8, "Cura (%d) [%d/%d]" % [GameConstants.HEALING_STATION_COST, healing_stations.size(), GameConstants.MAX_HEALING_STATIONS])
		
		buy_menu_popup.set_item_disabled(0, hero["coins"] < GameConstants.TOWER_COST or towers.size() >= GameConstants.MAX_TOWERS)
		buy_menu_popup.set_item_disabled(1, hero["coins"] < GameConstants.BARRACKS_COST or barracks.size() >= GameConstants.MAX_BARRACKS)
		buy_menu_popup.set_item_disabled(2, hero["coins"] < GameConstants.MINE_COST or mines.size() >= GameConstants.MAX_MINES)
		buy_menu_popup.set_item_disabled(3, hero["coins"] < GameConstants.SLOW_TOWER_COST or slow_towers.size() >= GameConstants.MAX_SLOW_TOWERS)
		buy_menu_popup.set_item_disabled(4, hero["coins"] < GameConstants.AOE_TOWER_COST or aoe_towers.size() >= GameConstants.MAX_AOE_TOWERS)
		buy_menu_popup.set_item_disabled(5, hero["coins"] < GameConstants.SNIPER_TOWER_COST or sniper_towers.size() >= GameConstants.MAX_SNIPER_TOWERS)
		buy_menu_popup.set_item_disabled(6, hero["coins"] < GameConstants.BOOST_TOWER_COST or boost_towers.size() >= GameConstants.MAX_BOOST_TOWERS)
		buy_menu_popup.set_item_disabled(7, hero["coins"] < GameConstants.WALL_COST or walls.size() >= GameConstants.MAX_WALLS)
		buy_menu_popup.set_item_disabled(8, hero["coins"] < GameConstants.HEALING_STATION_COST or healing_stations.size() >= GameConstants.MAX_HEALING_STATIONS)

	queue_redraw()

func _input(event: InputEvent) -> void:
	# atualizar posição do mouse para preview
	if event is InputEventMouseMotion:
		preview_mouse_pos = to_local(event.position)
		queue_redraw()
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not choosing_upgrade:
			# converter posição do mouse de tela para coordenadas do mundo do Node2D
			var screen_pos = event.position
			var world_pos = to_local(screen_pos)
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
			elif placing_wall:
				_try_place_wall(world_pos)
			elif placing_healing_station:
				_try_place_healing_station(world_pos)
			# tiro automático - removido tiro manual por clique
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if not choosing_upgrade and not game_over:
			# cancelar colocação com botão direito
			if placing_tower or placing_barracks or placing_mine or placing_slow_tower or placing_aoe_tower or placing_sniper_tower or placing_boost_tower or placing_wall or placing_healing_station:
				placing_tower = false
				placing_barracks = false
				placing_mine = false
				placing_slow_tower = false
				placing_aoe_tower = false
				placing_sniper_tower = false
				placing_boost_tower = false
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

func _draw() -> void:
	# verificar se grid foi inicializado
	if grid_manager.grid.is_empty() or grid_manager.grid.size() < GameConstants.GRID_ROWS:
		return
	
	# fundo - desenhar ocupando exatamente o tamanho do grid
	var map_width := float(GameConstants.GRID_COLS * GameConstants.TILE_SIZE)
	var map_height := float(GameConstants.GRID_ROWS * GameConstants.TILE_SIZE)
	draw_rect(Rect2(0, 0, map_width, map_height), Color(0.08, 0.09, 0.12))
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
					# Cor padrão do chão
					draw_rect(tile_rect, Color(0.18,0.19,0.23))
			else:  # Barreira/cerca (parede)
				if tex_wall != null:
					# Usar textura da barreira
					draw_texture_rect(tex_wall, tile_rect, false)
				else:
					# Cor padrão da parede
					draw_rect(tile_rect, Color(0.29,0.32,0.40))
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
	
	# Desenhar tenda no centro exato
	var bc = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
	if tex_tent != null:
		var s := Vector2(GameConstants.TILE_SIZE*1.6, GameConstants.TILE_SIZE*1.3)
		var pos := Vector2(bc.x - s.x/2, bc.y - s.y/2)
		draw_texture_rect(tex_tent, Rect2(pos, s), false)
	else:
		var tent_half := float(GameConstants.TILE_SIZE) / 2.0
		draw_rect(Rect2(bc.x - tent_half, bc.y - tent_half, GameConstants.TILE_SIZE, GameConstants.TILE_SIZE), Color(0.9,0.7,0.2))
	# enemies
	for e in enemies:
		# barra de vida
		var max_hp: int = int(e.get("max_hp", 2))
		var hp_ratio: float = clamp(float(e["hp"]) / float(max_hp), 0.0, 1.0)
		var is_boss: bool = e.get("is_boss", false)
		var bar_width: int = 24 if is_boss else 16  # barra maior para chefe
		var bx: int = int(e["pos"].x) - int(bar_width / 2)
		var by: int = int(e["pos"].y) - 12
		draw_rect(Rect2(bx, by, bar_width, 3), Color(0.14,0.15,0.18))
		var hp_color = Color(0.9,0.2,0.9) if is_boss else Color(0.78,0.32,0.32)  # roxo para chefe
		draw_rect(Rect2(bx, by, int(bar_width*hp_ratio), 3), hp_color)
		# corpo
		var enemy_tex: Texture2D = tex_enemy_zombie
		if wave_manager.wave >= 6 and wave_manager.wave <= 10 and tex_enemy_humanoid != null:
			enemy_tex = tex_enemy_humanoid
		elif wave_manager.wave >= 11 and wave_manager.wave <= 15 and tex_enemy_robot != null:
			enemy_tex = tex_enemy_robot
		if enemy_tex != null:
			var size := Vector2(GameConstants.TILE_SIZE*1.1, GameConstants.TILE_SIZE*1.1)
			var pos: Vector2 = e["pos"] - size/2
			draw_texture_rect(enemy_tex, Rect2(pos, size), false)
		else:
			var enemy_color = Color(0.9,0.35,0.35)
			var enemy_idx = e.get("idx", -1)
			
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
	# towers (2x2 no grid)
	for t in towers:
		var tower_size := grid_size_px * GameConstants.TOWER_SIZE_GRID
		var r := Rect2(t.pos.x - tower_size/2, t.pos.y - tower_size/2, tower_size, tower_size)
		draw_rect(r, Color(0.7,0.7,0.8))
		draw_rect(r, Color(0.5,0.5,0.6), false, 2.0)  # borda
	# barracks (2x2 no grid)
	for br in barracks:
		var barracks_size := grid_size_px * GameConstants.BARRACKS_SIZE_GRID
		var br_rect := Rect2(br.pos.x - barracks_size/2, br.pos.y - barracks_size/2, barracks_size, barracks_size)
		draw_rect(br_rect, Color(0.4,0.5,0.6))
		draw_rect(br_rect, Color(0.3,0.4,0.5), false, 2.0)  # borda
	# minas
	for m in mines:
		if not m.triggered:
			draw_circle(m.pos, 8, Color(0.8,0.2,0.2))
			draw_circle(m.pos, 8, Color(0.5,0.1,0.1), false, 2.0)
	# slow towers
	for st in slow_towers:
		var st_size := grid_size_px * GameConstants.SLOW_TOWER_SIZE_GRID
		var st_rect := Rect2(st.pos.x - st_size/2, st.pos.y - st_size/2, st_size, st_size)
		draw_rect(st_rect, Color(0.5,0.7,0.9))
		draw_rect(st_rect, Color(0.3,0.5,0.7), false, 2.0)
	# AOE towers
	for aoe in aoe_towers:
		var aoe_size := grid_size_px * GameConstants.AOE_TOWER_SIZE_GRID
		var aoe_rect := Rect2(aoe.pos.x - aoe_size/2, aoe.pos.y - aoe_size/2, aoe_size, aoe_size)
		draw_rect(aoe_rect, Color(0.9,0.5,0.2))
		draw_rect(aoe_rect, Color(0.7,0.3,0.1), false, 2.0)
	# sniper towers
	for sniper in sniper_towers:
		var sniper_size := grid_size_px * GameConstants.SNIPER_TOWER_SIZE_GRID
		var sniper_rect := Rect2(sniper.pos.x - sniper_size/2, sniper.pos.y - sniper_size/2, sniper_size, sniper_size)
		draw_rect(sniper_rect, Color(0.3,0.3,0.3))
		draw_rect(sniper_rect, Color(0.1,0.1,0.1), false, 2.0)
	# boost towers
	for boost in boost_towers:
		var boost_size := grid_size_px * GameConstants.BOOST_TOWER_SIZE_GRID
		var boost_rect := Rect2(boost.pos.x - boost_size/2, boost.pos.y - boost_size/2, boost_size, boost_size)
		draw_rect(boost_rect, Color(0.8,0.8,0.2))
		draw_rect(boost_rect, Color(0.6,0.6,0.1), false, 2.0)
	# walls
	for w in walls:
		if w.hp > 0:
			var wall_size := grid_size_px * GameConstants.WALL_SIZE_GRID
			var wall_rect := Rect2(w.pos.x - wall_size/2, w.pos.y - wall_size/2, wall_size, wall_size)
			var hp_ratio = w.hp / w.max_hp
			var wall_color = Color(0.6,0.4,0.2) * hp_ratio + Color(0.3,0.2,0.1) * (1.0 - hp_ratio)
			draw_rect(wall_rect, wall_color)
			draw_rect(wall_rect, Color(0.4,0.3,0.2), false, 2.0)
	# healing stations
	for hs in healing_stations:
		var hs_size := grid_size_px * GameConstants.HEALING_STATION_SIZE_GRID
		var hs_rect := Rect2(hs.pos.x - hs_size/2, hs.pos.y - hs_size/2, hs_size, hs_size)
		draw_rect(hs_rect, Color(0.2,0.8,0.4))
		draw_rect(hs_rect, Color(0.1,0.6,0.3), false, 2.0)
	# soldados
	for s in soldiers:
		if s.hp > 0:
			var soldier_color = Color(0.2,0.6,0.9) if not s.holding else Color(0.9,0.6,0.2)
			draw_circle(s.pos, s.radius, soldier_color)
			draw_circle(s.pos, s.radius, Color(0.1,0.3,0.5), false, 1.0)  # borda
	
	# preview de colocação
	if placing_tower or placing_barracks or placing_mine or placing_slow_tower or placing_aoe_tower or placing_sniper_tower or placing_boost_tower or placing_wall or placing_healing_station:
		if grid_manager.is_inside_base_point(preview_mouse_pos):
			var preview_grid_coord = grid_manager.world_to_base_grid(preview_mouse_pos)
			var preview_world_pos = grid_manager.base_grid_to_world(preview_grid_coord.x, preview_grid_coord.y)
			
			if placing_tower:
				if grid_manager.can_place_in_grid(preview_grid_coord.x, preview_grid_coord.y, GameConstants.TOWER_SIZE_GRID, 1):
					var preview_size := grid_size_px * GameConstants.TOWER_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					draw_rect(preview_rect, Color(0.7,0.9,0.7,0.5))  # verde semi-transparente
					draw_rect(preview_rect, Color(0.5,0.8,0.5), false, 2.0)  # borda verde
				else:
					var preview_size := grid_size_px * GameConstants.TOWER_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					draw_rect(preview_rect, Color(0.9,0.3,0.3,0.5))  # vermelho semi-transparente
					draw_rect(preview_rect, Color(0.8,0.2,0.2), false, 2.0)  # borda vermelha
			
			elif placing_barracks:
				if grid_manager.can_place_in_grid(preview_grid_coord.x, preview_grid_coord.y, GameConstants.BARRACKS_SIZE_GRID, 3):
					var preview_size := grid_size_px * GameConstants.BARRACKS_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					draw_rect(preview_rect, Color(0.7,0.9,0.7,0.5))
					draw_rect(preview_rect, Color(0.5,0.8,0.5), false, 2.0)
				else:
					var preview_size := grid_size_px * GameConstants.BARRACKS_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					draw_rect(preview_rect, Color(0.9,0.3,0.3,0.5))
					draw_rect(preview_rect, Color(0.8,0.2,0.2), false, 2.0)
			elif placing_mine:
				if grid_manager.can_place_in_grid(preview_grid_coord.x, preview_grid_coord.y, GameConstants.MINE_SIZE_GRID, 4):
					draw_circle(preview_world_pos, 8, Color(0.8,0.2,0.2,0.5))
					draw_circle(preview_world_pos, 8, Color(0.5,0.1,0.1), false, 2.0)
				else:
					draw_circle(preview_world_pos, 8, Color(0.9,0.3,0.3,0.5))
					draw_circle(preview_world_pos, 8, Color(0.8,0.2,0.2), false, 2.0)
			elif placing_slow_tower:
				if grid_manager.can_place_in_grid(preview_grid_coord.x, preview_grid_coord.y, GameConstants.SLOW_TOWER_SIZE_GRID, 5):
					var preview_size := grid_size_px * GameConstants.SLOW_TOWER_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					draw_rect(preview_rect, Color(0.5,0.7,0.9,0.5))
					draw_rect(preview_rect, Color(0.3,0.5,0.7), false, 2.0)
				else:
					var preview_size := grid_size_px * GameConstants.SLOW_TOWER_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					draw_rect(preview_rect, Color(0.9,0.3,0.3,0.5))
					draw_rect(preview_rect, Color(0.8,0.2,0.2), false, 2.0)
			elif placing_aoe_tower:
				if grid_manager.can_place_in_grid(preview_grid_coord.x, preview_grid_coord.y, GameConstants.AOE_TOWER_SIZE_GRID, 6):
					var preview_size := grid_size_px * GameConstants.AOE_TOWER_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					draw_rect(preview_rect, Color(0.9,0.5,0.2,0.5))
					draw_rect(preview_rect, Color(0.7,0.3,0.1), false, 2.0)
				else:
					var preview_size := grid_size_px * GameConstants.AOE_TOWER_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					draw_rect(preview_rect, Color(0.9,0.3,0.3,0.5))
					draw_rect(preview_rect, Color(0.8,0.2,0.2), false, 2.0)
			elif placing_sniper_tower:
				if grid_manager.can_place_in_grid(preview_grid_coord.x, preview_grid_coord.y, GameConstants.SNIPER_TOWER_SIZE_GRID, 7):
					var preview_size := grid_size_px * GameConstants.SNIPER_TOWER_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					draw_rect(preview_rect, Color(0.3,0.3,0.3,0.5))
					draw_rect(preview_rect, Color(0.1,0.1,0.1), false, 2.0)
				else:
					var preview_size := grid_size_px * GameConstants.SNIPER_TOWER_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					draw_rect(preview_rect, Color(0.9,0.3,0.3,0.5))
					draw_rect(preview_rect, Color(0.8,0.2,0.2), false, 2.0)
			elif placing_boost_tower:
				if grid_manager.can_place_in_grid(preview_grid_coord.x, preview_grid_coord.y, GameConstants.BOOST_TOWER_SIZE_GRID, 8):
					var preview_size := grid_size_px * GameConstants.BOOST_TOWER_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					draw_rect(preview_rect, Color(0.8,0.8,0.2,0.5))
					draw_rect(preview_rect, Color(0.6,0.6,0.1), false, 2.0)
				else:
					var preview_size := grid_size_px * GameConstants.BOOST_TOWER_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					draw_rect(preview_rect, Color(0.9,0.3,0.3,0.5))
					draw_rect(preview_rect, Color(0.8,0.2,0.2), false, 2.0)
			elif placing_wall:
				if grid_manager.can_place_in_grid(preview_grid_coord.x, preview_grid_coord.y, GameConstants.WALL_SIZE_GRID, 9):
					var preview_size := grid_size_px * GameConstants.WALL_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					draw_rect(preview_rect, Color(0.6,0.4,0.2,0.5))
					draw_rect(preview_rect, Color(0.4,0.3,0.2), false, 2.0)
				else:
					var preview_size := grid_size_px * GameConstants.WALL_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					draw_rect(preview_rect, Color(0.9,0.3,0.3,0.5))
					draw_rect(preview_rect, Color(0.8,0.2,0.2), false, 2.0)
			elif placing_healing_station:
				if grid_manager.can_place_in_grid(preview_grid_coord.x, preview_grid_coord.y, GameConstants.HEALING_STATION_SIZE_GRID, 10):
					var preview_size := grid_size_px * GameConstants.HEALING_STATION_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					draw_rect(preview_rect, Color(0.2,0.8,0.4,0.5))
					draw_rect(preview_rect, Color(0.1,0.6,0.3), false, 2.0)
				else:
					var preview_size := grid_size_px * GameConstants.HEALING_STATION_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					draw_rect(preview_rect, Color(0.9,0.3,0.3,0.5))
					draw_rect(preview_rect, Color(0.8,0.2,0.2), false, 2.0)
	
	# mostrar alcance da torre selecionada
	if tower_selected_index >= 0 and tower_selected_index < towers.size():
		var tt = towers[tower_selected_index]
		draw_circle(tt.pos, tt.range, Color(0.3,0.6,1.0,0.15))
	# hero
	if tex_hero != null:
		var size_h := Vector2(GameConstants.TILE_SIZE*1.1, GameConstants.TILE_SIZE*1.1)
		var pos_h := Vector2(hero["x"], hero["y"]) - size_h/2
		draw_texture_rect(tex_hero, Rect2(pos_h, size_h), false)
	else:
		draw_circle(Vector2(hero["x"], hero["y"]), 7, Color(0.43,0.83,0.43))

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
	var path = pathfinder.find_path(from_c, from_r, grid_manager.base_grid)
	var pts := []
	for t in path:
		pts.append(grid_manager.tile_center(t.x, t.y))
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
		return null
	
	# Escolher uma célula aleatória
	cells.shuffle()
	return cells[randi() % cells.size()]

func _enemy_new(col: int, row: int) -> Dictionary:
	var pos = grid_manager.tile_center(col, row)
	var initial_hp := GameConstants.ENEMY_BASE_HP  # HP suficiente para 2 ataques iniciais
	var f := _wave_factor()
	var hp := int(max(1, round(initial_hp * f)))
	var enemy_idx = enemies.size()
	# Calcular caminho único para cada inimigo (criar cópia para evitar compartilhamento)
	var path = _bfs_path(col, row)
	# Criar uma cópia do path para este inimigo específico
	var path_copy = []
	for p in path:
		path_copy.append(p)
	var e = { pos = pos, speed = GameConstants.ENEMY_BASE_SPEED * f, base_speed = GameConstants.ENEMY_BASE_SPEED * f, hp = hp, max_hp = hp, radius = 9, path = path_copy, path_index = 0, reached = false, idx = enemy_idx, is_boss = false }
	enemy_effects[enemy_idx] = {freeze_time = 0.0, fire_time = 0.0, fire_damage = 0.0}
	return e

func _enemy_new_boss(col: int, row: int) -> Dictionary:
	var pos = grid_manager.tile_center(col, row)
	var initial_hp := GameConstants.BOSS_BASE_HP  # chefe tem muito mais HP (equivalente a 25 hits iniciais)
	var f := _wave_factor()
	var hp := int(max(1, round(initial_hp * f)))
	var enemy_idx = enemies.size()
	# Calcular caminho único para cada inimigo (não usar cache compartilhado)
	var path = _bfs_path(col, row)
	# Criar uma cópia do path para este inimigo específico
	var path_copy = []
	for p in path:
		path_copy.append(p)
	var e = { pos = pos, speed = GameConstants.ENEMY_BASE_SPEED * f * GameConstants.BOSS_SPEED_MULTIPLIER, base_speed = GameConstants.ENEMY_BASE_SPEED * f * GameConstants.BOSS_SPEED_MULTIPLIER, hp = hp, max_hp = hp, radius = 12, path = path_copy, path_index = 0, reached = false, idx = enemy_idx, is_boss = true }
	enemy_effects[enemy_idx] = {freeze_time = 0.0, fire_time = 0.0, fire_damage = 0.0}
	return e

func _enemy_update(e: Dictionary, dt: float) -> void:
	if e["reached"] or e["hp"] <= 0:
		return
	
	var enemy_idx = e.get("idx", -1)
	if enemy_idx >= 0 and enemy_effects.has(enemy_idx):
		var effects = enemy_effects[enemy_idx]
		# aplicar congelamento (reduz velocidade)
		if effects.freeze_time > 0.0:
			effects.freeze_time -= dt
			e["speed"] = e["base_speed"] * 0.3  # reduz velocidade em 70%
		else:
			e["speed"] = e["base_speed"]
		
		# aplicar dano de fogo
		if effects.fire_time > 0.0:
			effects.fire_time -= dt
			e["hp"] -= effects.fire_damage * dt
			if e["hp"] <= 0:
				e["hp"] = 0
				return
	
	if e["path_index"] >= e["path"].size():
		var basep = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
		var v = basep - e["pos"]
		var d = max(v.length(), 0.0001)
		if d < 4.0:
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
		e["pos"] += v.normalized() * e["speed"] * dt
		return
	var targ: Vector2 = e["path"][e["path_index"]]
	var v2 = targ - e["pos"]
	var d2 = max(v2.length(), 0.0001)
	if d2 < 2.0:
		e["path_index"] += 1
		return
	e["pos"] += v2.normalized() * e["speed"] * dt

func _arrow_new(x: float, y: float, target: Vector2) -> Dictionary:
	var dir = (target - Vector2(x,y))
	var d = max(dir.length(), 0.0001)
	var a = { "pos": Vector2(x,y), "vel": dir/d * 260.0, "life": 2.0, "radius": 2, "damage": hero["damage"], "pierce": hero["pierce"] }
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
				e["hp"] -= a["damage"]
				if e["hp"] <= 0:
					var is_boss = e.get("is_boss", false)
					# chefe dá 20x mais moedas (40 vs 2)
					hero["coins"] += GameConstants.BOSS_REWARD_MULTIPLIER * GameConstants.NORMAL_REWARD if is_boss else GameConstants.NORMAL_REWARD
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
				e["hp"] -= b["damage"]
				if e["hp"] <= 0:
					var is_boss = e.get("is_boss", false)
					# chefe dá 20x mais moedas (40 vs 2)
					hero["coins"] += GameConstants.BOSS_REWARD_MULTIPLIER * GameConstants.NORMAL_REWARD if is_boss else GameConstants.NORMAL_REWARD
				
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

func _open_tower_menu(idx: int, screen_pos: Vector2) -> void:
	if tower_menu == null:
		return
	tower_selected_index = idx
	var t = towers[idx]
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
	tower_selected_index = -1

func _try_shoot(target: Vector2) -> void:
	if hero["cooldown"] > 0.0:
		return
	arrows.append(_arrow_new(hero["x"], hero["y"], target))
	hero["cooldown"] = hero["fire_rate"]

func _jump_to_wave_10() -> void:
	wave_manager.jump_to_wave(10)
	enemies.clear()
	choosing_upgrade = false
	benefit_applied = false
	$CanvasLayer/UpgradeOverlay.visible = false

func _on_wave_started(wave_number: int, is_boss_wave: bool):
	pass

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
		8:  # Muralha
			_on_buy_wall()
		9:  # Healing Station
			_on_buy_healing_station()

func _open_barracks_menu(idx: int, screen_pos: Vector2) -> void:
	if barracks_menu == null:
		return
	barracks_selected_index = idx
	var b = barracks[idx]
	var can_dmg: bool = hero["coins"] >= GameConstants.BARRACKS_DMG_COST
	var can_hold: bool = hero["coins"] >= GameConstants.BARRACKS_HOLD_COST
	var can_soldiers: bool = hero["coins"] >= GameConstants.BARRACKS_SOLDIERS_COST and b.max_soldiers < 4  # máximo de 4 soldados
	
	barracks_menu.set_item_text(0, "Dano +0.2 (%d)" % GameConstants.BARRACKS_DMG_COST)
	barracks_menu.set_item_text(1, "Tempo Hold +1s (%d)" % GameConstants.BARRACKS_HOLD_COST)
	barracks_menu.set_item_text(2, "+1 Soldado (%d) [%d/4]" % [GameConstants.BARRACKS_SOLDIERS_COST, b.max_soldiers])
	barracks_menu.set_item_disabled(0, not can_dmg)
	barracks_menu.set_item_disabled(1, not can_hold)
	barracks_menu.set_item_disabled(2, not can_soldiers)
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
		3:  # +1 Soldado
			if hero["coins"] >= GameConstants.BARRACKS_SOLDIERS_COST and b.max_soldiers < 4:
				b.max_soldiers += 1
				b.levels["SOLDIERS"] += 1
				hero["coins"] -= GameConstants.BARRACKS_SOLDIERS_COST
	barracks[barracks_selected_index] = b
	barracks_selected_index = -1

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
	
	barracks.append({
		"pos": barracks_world_pos,
		"grid_x": grid_coord.x,
		"grid_y": grid_coord.y,
		"soldier_spawn_cd": 0.0,
		"soldier_spawn_rate": 3.0,  # spawna soldado a cada 3 segundos
		"max_soldiers": 2,  # máximo de 2 soldados por quartel
		"soldiers": [],
		"hold_time": 2.0,  # tempo que soldado segura monstro
		"damage": 0.3,  # dano por segundo do soldado
		"levels": { "HOLD": 0, "DMG": 0, "SOLDIERS": 0 }
	})
	hero["coins"] -= GameConstants.BARRACKS_COST
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
		"cooldown": 0.0,
		"fire_rate": 0.5
	})
	hero["coins"] -= GameConstants.SLOW_TOWER_COST
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
		"fire_rate": 2.0
	})
	hero["coins"] -= GameConstants.AOE_TOWER_COST
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
		"pierce": 1
	})
	hero["coins"] -= GameConstants.SNIPER_TOWER_COST
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
		"rate_boost": 0.3
	})
	hero["coins"] -= GameConstants.BOOST_TOWER_COST
	placing_boost_tower = false

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
	placing_wall = false

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
	hero["cooldown"] = max(0.0, hero["cooldown"] - delta)
	
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
			_try_shoot(closest_enemy["pos"])
	
	# torres: 1 tiro por direção no intervalo configurado (fire_rate)
	for t in towers:
		# aplicar boost de rate de boost towers próximos
		var rate_multiplier = 1.0
		for boost in boost_towers:
			var dist = t.pos.distance_to(boost.pos)
			if dist <= boost.range:
				rate_multiplier += boost.rate_boost
		
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
		# spawnar soldados sempre que o cooldown acabar e não tiver o máximo de soldados
		# não depende de ter inimigos presentes
		if b.soldier_spawn_cd <= 0.0 and b.soldiers.size() < b.max_soldiers:
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
				"speed": 80.0,
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
				if e["hp"] <= 0:
					hero["coins"] += GameConstants.NORMAL_REWARD
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
		st.cooldown = max(0.0, st.cooldown - delta)
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
						enemy_effects[enemy_idx].slow_time = 1.0  # slow dura 1 segundo
						enemy_effects[enemy_idx].slow_amount = st.slow_amount
			st.cooldown = st.fire_rate

func _update_aoe_towers(delta: float) -> void:
	if paused or game_over:
		return
	for aoe in aoe_towers:
		aoe.cooldown = max(0.0, aoe.cooldown - delta)
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
				# criar efeito visual de explosão
				aoe_effects.append({
					"pos": closest_enemy["pos"],
					"time": 0.0,
					"max_time": 0.3,
					"radius": aoe.aoe_radius
				})
				# causar dano em área
				for e in enemies:
					if e["hp"] <= 0 or e["reached"]:
						continue
					var dist = closest_enemy["pos"].distance_to(e["pos"])
					if dist <= aoe.aoe_radius:
						e["hp"] -= aoe.damage
						if e["hp"] <= 0:
							hero["coins"] += GameConstants.NORMAL_REWARD
				# resetar cooldown apenas se encontrou alvo
				aoe.cooldown = aoe.fire_rate
			else:
				# se não encontrou alvo, manter cooldown em 0 para tentar novamente no próximo frame
				aoe.cooldown = 0.0

func _update_sniper_towers(delta: float) -> void:
	if paused or game_over:
		return
	for sniper in sniper_towers:
		sniper.cooldown = max(0.0, sniper.cooldown - delta)
		if sniper.cooldown <= 0.0:
			# encontrar inimigo mais distante no alcance
			var target_enemy = null
			var target_dist = -1.0
			for e in enemies:
				if e["hp"] <= 0 or e["reached"]:
					continue
				var dist = sniper.pos.distance_to(e["pos"])
				if dist <= sniper.range and dist > target_dist:
					target_enemy = e
					target_dist = dist
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
				# causar dano nos primeiros (pierce + 1) inimigos
				var pierce_count = sniper.pierce + 1  # pierce=1 significa atinge 2 inimigos
				for i in range(min(pierce_count, enemies_in_line.size())):
					var e = enemies_in_line[i].enemy
					e["hp"] -= sniper.damage
					if e["hp"] <= 0:
						hero["coins"] += GameConstants.NORMAL_REWARD
				# resetar cooldown apenas se encontrou alvo
				sniper.cooldown = sniper.fire_rate
			else:
				# se não encontrou alvo, manter cooldown em 0 para tentar novamente no próximo frame
				sniper.cooldown = 0.0

func _update_boost_towers(delta: float) -> void:
	# boost towers não precisam de atualização - o efeito é aplicado quando torres atiram
	pass

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
			s.hold_time += delta
			# aplicar dano ao inimigo enquanto segura
			target_enemy["hp"] -= s.damage * delta
			if target_enemy["hp"] <= 0:
				var is_boss = target_enemy.get("is_boss", false)
				# chefe dá 20x mais moedas (40 vs 2)
				hero["coins"] += 40 if is_boss else 2
			
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
