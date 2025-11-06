extends Node2D

const TILE_SIZE := 28
const GRID_COLS := 33
const GRID_ROWS := 33

var grid := [] # 0 floor, 1 wall
# Garantir centro exato: para grid 33x33, centro = (16, 16) - número ímpar garante simetria perfeita
var center := Vector2i(int(GRID_COLS / 2), int(GRID_ROWS / 2))
var grid_offset: Vector2  # offset para centralizar o grid na tela

var enemies: Array = []
var arrows: Array = []
var tower_bullets: Array = []

var base_hp := 100
var wave := 0
var paused := false
var game_over := false

# base / towers
const BASE_SIZE_TILES := 7 # aumentado de 5 para 7
const BASE_GRID_SIZE := 15  # grid 15x15 dentro da base
const TOWER_COST := 10
const BLOCK_COST := 5
const BARRACKS_COST := 20
const TOWER_SIZE_GRID := 2  # torre ocupa 2x2 tiles do grid
const BLOCK_SIZE_GRID := 3  # bloco ocupa 3x3 tiles do grid
const BARRACKS_SIZE_GRID := 2  # quartel ocupa 2x2 tiles do grid
const MAX_TOWERS := 8
const MAX_BLOCKS := 4
const MAX_BARRACKS := 2
var placing_tower := false
var placing_block := false
var placing_barracks := false
var towers: Array = []
var blocks: Array = []  # blocos de bloqueio - cada bloco: {grid_x: int, grid_y: int}
var barracks: Array = []  # quartéis - cada quartel: {grid_x: int, grid_y: int, pos: Vector2, soldier_spawn_cd: float, soldiers: Array}
var base_grid: Array = []  # grid 15x15: 0=vazio, 1=torre, 2=bloco, 3=quartel
var preview_mouse_pos := Vector2.ZERO  # posição do mouse para preview
var soldiers: Array = []  # soldados: {pos: Vector2, target_enemy_idx: int, hold_time: float, max_hold_time: float, damage: float, hp: float, max_hp: float, radius: float}

# tower upgrade system
const TOWER_RANGE_COST := 8
const TOWER_RATE_COST := 8
const TOWER_DIRS_COST := 12
const TOWER_DMG_COST := 10
const TOWER_FREEZE_COST := 25  # upgrade de congelamento
const TOWER_FIRE_COST := 25  # upgrade de fogo
var tower_menu: PopupMenu
var tower_selected_index := -1
var placing_tower_dir := Vector2(1, 0)  # direção inicial ao colocar torre

# barracks upgrade system
const BARRACKS_DMG_COST := 15  # aumentar dano
const BARRACKS_HOLD_COST := 12  # aumentar tempo de slow/hold
const BARRACKS_SOLDIERS_COST := 20  # aumentar quantidade de soldados
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

# waves
var intermission := 2.0
var time_to_next_wave := intermission
var spawning := false
var to_spawn := 0
var spawn_cd := 0.0
var spawn_rate := 0.35
var bosses_spawned_this_wave := 0  # rastrear quantos chefes foram spawnados na wave atual

# wave scaling
const WAVE_SCALE := 1.1  # escala de aumento de velocidade e HP
func _wave_factor() -> float:
	return pow(WAVE_SCALE, max(0, wave - 1))

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
	"x": 0.0, "y": 0.0, "cooldown": 0.0, "fire_rate": 0.35,
	"damage": 1, "pierce": 0, "range": 9999.0,
	"levels": { "DMG": 0, "FIRERATE": 0, "PIERCE": 0 }, "coins": 100,  # 100 moedas iniciais para teste
}

func _try_load(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _ready() -> void:
	# ajustar tamanho da janela para caber grid + barra superior
	var bar_height: float = 44.0
	var grid_px_w: float = GRID_COLS * TILE_SIZE
	var grid_px_h: float = GRID_ROWS * TILE_SIZE
	var win_w := int(grid_px_w)
	var win_h := int(grid_px_h + bar_height)  # grid + top bar
	DisplayServer.window_set_size(Vector2i(win_w, win_h))
	
	# aguardar um frame para viewport atualizar
	await get_tree().process_frame
	
	# posição fixa: grid começa em X=0 (alinhado à esquerda) e Y=bar_height (logo abaixo da barra)
	# Como a janela tem exatamente o tamanho do grid, não precisa centralizar
	grid_offset = Vector2(0.0, bar_height)
	position = grid_offset

	grid = _generate_maze()
	var p = _tile_center(center.x, center.y)
	hero["x"] = p.x
	hero["y"] = p.y
	
	# inicializar grid da base (5x5)
	base_grid = []
	for gy in range(BASE_GRID_SIZE):
		base_grid.append([])
		for gx in range(BASE_GRID_SIZE):
			base_grid[gy].append(0)  # 0=vazio

	# tentar carregar assets Kenney se existirem
	tex_hero = _try_load("res://assets/images/hero.png")
	tex_enemy_zombie = _try_load("res://assets/images/enemy_zombie.png")
	tex_enemy_humanoid = _try_load("res://assets/images/enemy_humanoid.png")
	tex_enemy_robot = _try_load("res://assets/images/enemy_robot.png")
	tex_tent = _try_load("res://assets/images/tent.png")
	tex_grass = _try_load("res://assets/images/grass.png")

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
		buy_menu.add_item("Torre (%d)" % TOWER_COST, 1)
		buy_menu.add_item("Bloco (%d)" % BLOCK_COST, 2)
		buy_menu.add_item("Quartel (%d)" % BARRACKS_COST, 3)
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
	if not spawning and enemies.is_empty() and not choosing_upgrade:
		if wave > 0:
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
			time_to_next_wave = 0.0

	if not choosing_upgrade and not spawning and enemies.is_empty():
		time_to_next_wave -= delta
		if time_to_next_wave <= 0.0:
			wave += 1
			bosses_spawned_this_wave = 0  # resetar contador de chefes
			# verificar se é wave de chefe (waves 5, 10, 15, 20...)
			var is_boss_wave := (wave % 5 == 0)
			if is_boss_wave:
				# wave de chefe: spawnar 2 chefes + monstros normais
				var base: int = 6
				var plus_each: int = max(0, wave - 1)
				var bonus_five: int = 3 * int(floor(max(0, wave - 1) / 5))
				to_spawn = base + plus_each + bonus_five  # quantidade normal de monstros
				spawn_rate = max(0.12, 0.5 - wave * 0.02)
			else:
				# wave normal: apenas monstros normais
				var base: int = 6
				var plus_each: int = max(0, wave - 1)
				var bonus_five: int = 3 * int(floor(max(0, wave - 1) / 5))
				to_spawn = base + plus_each + bonus_five
				spawn_rate = max(0.12, 0.5 - wave * 0.02)
			spawn_cd = 0.0
			spawning = true

	if spawning:
		spawn_cd -= delta
		# verificar se é wave de chefe (waves 5, 10, 15, 20...)
		var is_boss_wave_current := (wave % 5 == 0)
		var should_spawn_boss := is_boss_wave_current and bosses_spawned_this_wave < 2
		
		# continuar spawnando se ainda temos inimigos para spawnar OU se ainda precisamos spawnar chefes
		var has_more_to_spawn := to_spawn > 0 or should_spawn_boss
		
		if spawn_cd <= 0.0 and has_more_to_spawn:
			# se precisamos spawnar chefe, tentar até conseguir (sem delay adicional)
			if should_spawn_boss:
				var s = _random_spawn()
				if s != null:
					enemies.append(_enemy_new_boss(s.x, s.y))
					bosses_spawned_this_wave += 1
					spawn_cd = spawn_rate  # resetar cooldown apenas após spawnar
			else:
				# spawnar monstro normal
				spawn_cd = spawn_rate
				var s = _random_spawn()
				if s != null:
					enemies.append(_enemy_new(s.x, s.y))
					to_spawn -= 1
		
		# parar de spawnar apenas quando não há mais inimigos E não há mais chefes para spawnar
		if to_spawn == 0 and not should_spawn_boss:
			spawning = false
			time_to_next_wave = intermission

	# UI
	var tb = $CanvasLayer/HUD/TopBar
	var is_boss_wave := (wave % 5 == 0)
	var wave_text = "Wave %d (CHEFE!)" % wave if is_boss_wave else "Wave %d" % wave
	tb.get_node("LblLeft").text = "%s  Inimigos %d" % [wave_text, enemies.size()]
	tb.get_node("LblCenter").text = "Moedas %d" % [int(hero["coins"])]
	tb.get_node("LblRight").text = "Vida %d" % [base_hp]
	
	# atualizar menu dropdown de compras
	if tb.has_node("BuyMenuButton"):
		var menu_btn = tb.get_node("BuyMenuButton")
		var buy_menu_popup = menu_btn.get_popup()
		buy_menu_popup.set_item_text(0, "Torre (%d) [%d/%d]" % [TOWER_COST, towers.size(), MAX_TOWERS])
		buy_menu_popup.set_item_text(1, "Bloco (%d) [%d/%d]" % [BLOCK_COST, blocks.size(), MAX_BLOCKS])
		buy_menu_popup.set_item_text(2, "Quartel (%d) [%d/%d]" % [BARRACKS_COST, barracks.size(), MAX_BARRACKS])
		buy_menu_popup.set_item_disabled(0, hero["coins"] < TOWER_COST or towers.size() >= MAX_TOWERS)
		buy_menu_popup.set_item_disabled(1, hero["coins"] < BLOCK_COST or blocks.size() >= MAX_BLOCKS)
		buy_menu_popup.set_item_disabled(2, hero["coins"] < BARRACKS_COST or barracks.size() >= MAX_BARRACKS)

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
			elif placing_block:
				_try_place_block(world_pos)
			elif placing_barracks:
				_try_place_barracks(world_pos)
			# tiro automático - removido tiro manual por clique
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if not choosing_upgrade and not game_over:
			# cancelar colocação com botão direito
			if placing_tower or placing_block or placing_barracks:
				placing_tower = false
				placing_block = false
				placing_barracks = false
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
	if grid.is_empty() or grid.size() < GRID_ROWS:
		return
	
	# fundo - desenhar ocupando exatamente o tamanho do grid
	var map_width := float(GRID_COLS * TILE_SIZE)
	var map_height := float(GRID_ROWS * TILE_SIZE)
	draw_rect(Rect2(0, 0, map_width, map_height), Color(0.08, 0.09, 0.12))
	# draw grid - alinhado perfeitamente aos tiles
	for r in range(GRID_ROWS):
		if grid.size() <= r or grid[r].size() < GRID_COLS:
			continue
		for c in range(GRID_COLS):
			var tile_x := float(c * TILE_SIZE)
			var tile_y := float(r * TILE_SIZE)
			if grid[r][c] == 0 and tex_grass != null:
				draw_texture_rect(tex_grass, Rect2(tile_x, tile_y, TILE_SIZE, TILE_SIZE), true)
			else:
				var col = Color(0.18,0.19,0.23) if grid[r][c] == 0 else Color(0.29,0.32,0.40)
				draw_rect(Rect2(tile_x, tile_y, TILE_SIZE, TILE_SIZE), col)
	# base com transparência moderada - usar coordenadas exatas do grid
	var base_half_size = int(BASE_SIZE_TILES / 2)  # 3
	var base_start_col = center.x - base_half_size  # 14
	var base_start_row = center.y - base_half_size  # 14
	
	# Converter coordenadas do grid para pixels exatos
	var base_left_px = float(base_start_col) * TILE_SIZE
	var base_top_px = float(base_start_row) * TILE_SIZE
	var base_width_px = float(BASE_SIZE_TILES) * TILE_SIZE
	var base_height_px = float(BASE_SIZE_TILES) * TILE_SIZE
	
	var base_rect := Rect2(base_left_px, base_top_px, base_width_px, base_height_px)
	draw_rect(base_rect, Color(0.2,0.24,0.28,0.6))  # transparência moderada
	
	# desenhar grid da base com transparência - alinhado perfeitamente aos tiles
	var grid_size_px: float = base_width_px / float(BASE_GRID_SIZE)
	var base_left: float = base_left_px
	var base_top: float = base_top_px
	var base_right: float = base_left_px + base_width_px
	var base_bottom: float = base_top_px + base_height_px
	
	for gy in range(BASE_GRID_SIZE + 1):
		var y = base_top + float(gy) * grid_size_px
		draw_line(Vector2(base_left, y), Vector2(base_right, y), Color(0.3,0.32,0.36,0.5), 1.0)
	for gx in range(BASE_GRID_SIZE + 1):
		var x = base_left + float(gx) * grid_size_px
		draw_line(Vector2(x, base_top), Vector2(x, base_bottom), Color(0.3,0.32,0.36,0.5), 1.0)
	
	# Desenhar tenda no centro exato
	var bc = _tile_center(center.x, center.y)
	if tex_tent != null:
		var s := Vector2(TILE_SIZE*1.6, TILE_SIZE*1.3)
		var pos := Vector2(bc.x - s.x/2, bc.y - s.y/2)
		draw_texture_rect(tex_tent, Rect2(pos, s), false)
	else:
		var tent_half := float(TILE_SIZE) / 2.0
		draw_rect(Rect2(bc.x - tent_half, bc.y - tent_half, TILE_SIZE, TILE_SIZE), Color(0.9,0.7,0.2))
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
		if wave >= 6 and wave <= 10 and tex_enemy_humanoid != null:
			enemy_tex = tex_enemy_humanoid
		elif wave >= 11 and wave <= 15 and tex_enemy_robot != null:
			enemy_tex = tex_enemy_robot
		if enemy_tex != null:
			var size := Vector2(TILE_SIZE*1.1, TILE_SIZE*1.1)
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
	# towers (2x2 no grid)
	for t in towers:
		var tower_size := grid_size_px * TOWER_SIZE_GRID
		var r := Rect2(t.pos.x - tower_size/2, t.pos.y - tower_size/2, tower_size, tower_size)
		draw_rect(r, Color(0.7,0.7,0.8))
		draw_rect(r, Color(0.5,0.5,0.6), false, 2.0)  # borda
	# blocks (3x3 no grid)
	for b in blocks:
		var block_size := grid_size_px * BLOCK_SIZE_GRID
		var br := Rect2(b.pos.x - block_size/2, b.pos.y - block_size/2, block_size, block_size)
		draw_rect(br, Color(0.5,0.3,0.2))
		draw_rect(br, Color(0.4,0.2,0.1), false, 2.0)  # borda
	# barracks (2x2 no grid)
	for br in barracks:
		var barracks_size := grid_size_px * BARRACKS_SIZE_GRID
		var br_rect := Rect2(br.pos.x - barracks_size/2, br.pos.y - barracks_size/2, barracks_size, barracks_size)
		draw_rect(br_rect, Color(0.4,0.5,0.6))
		draw_rect(br_rect, Color(0.3,0.4,0.5), false, 2.0)  # borda
	# soldados
	for s in soldiers:
		if s.hp > 0:
			var soldier_color = Color(0.2,0.6,0.9) if not s.holding else Color(0.9,0.6,0.2)
			draw_circle(s.pos, s.radius, soldier_color)
			draw_circle(s.pos, s.radius, Color(0.1,0.3,0.5), false, 1.0)  # borda
	
	# preview de colocação
	if placing_tower or placing_block or placing_barracks:
		if _is_inside_base_point(preview_mouse_pos):
			var preview_grid_coord = _world_to_base_grid(preview_mouse_pos)
			var preview_world_pos = _base_grid_to_world(preview_grid_coord.x, preview_grid_coord.y)
			
			if placing_tower:
				if _can_place_in_grid(preview_grid_coord.x, preview_grid_coord.y, TOWER_SIZE_GRID, 1):
					var preview_size := grid_size_px * TOWER_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					draw_rect(preview_rect, Color(0.7,0.9,0.7,0.5))  # verde semi-transparente
					draw_rect(preview_rect, Color(0.5,0.8,0.5), false, 2.0)  # borda verde
				else:
					var preview_size := grid_size_px * TOWER_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					draw_rect(preview_rect, Color(0.9,0.3,0.3,0.5))  # vermelho semi-transparente
					draw_rect(preview_rect, Color(0.8,0.2,0.2), false, 2.0)  # borda vermelha
			
			elif placing_block:
				if _can_place_in_grid(preview_grid_coord.x, preview_grid_coord.y, BLOCK_SIZE_GRID, 2):
					var preview_size := grid_size_px * BLOCK_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					draw_rect(preview_rect, Color(0.7,0.9,0.7,0.5))  # verde semi-transparente
					draw_rect(preview_rect, Color(0.5,0.8,0.5), false, 2.0)  # borda verde
				else:
					var preview_size := grid_size_px * BLOCK_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					draw_rect(preview_rect, Color(0.9,0.3,0.3,0.5))  # vermelho semi-transparente
					draw_rect(preview_rect, Color(0.8,0.2,0.2), false, 2.0)  # borda vermelha
			
			elif placing_barracks:
				if _can_place_in_grid(preview_grid_coord.x, preview_grid_coord.y, BARRACKS_SIZE_GRID, 3):
					var preview_size := grid_size_px * BARRACKS_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					draw_rect(preview_rect, Color(0.7,0.9,0.7,0.5))  # verde semi-transparente
					draw_rect(preview_rect, Color(0.5,0.8,0.5), false, 2.0)  # borda verde
				else:
					var preview_size := grid_size_px * BARRACKS_SIZE_GRID
					var preview_rect := Rect2(preview_world_pos.x - preview_size/2, preview_world_pos.y - preview_size/2, preview_size, preview_size)
					draw_rect(preview_rect, Color(0.9,0.3,0.3,0.5))  # vermelho semi-transparente
					draw_rect(preview_rect, Color(0.8,0.2,0.2), false, 2.0)  # borda vermelha
	
	# mostrar alcance da torre selecionada
	if tower_selected_index >= 0 and tower_selected_index < towers.size():
		var tt = towers[tower_selected_index]
		draw_circle(tt.pos, tt.range, Color(0.3,0.6,1.0,0.15))
	# hero
	if tex_hero != null:
		var size_h := Vector2(TILE_SIZE*1.1, TILE_SIZE*1.1)
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
	wave += 1
	var base: int = 6
	var plus_each: int = max(0, wave - 1)
	var bonus_five: int = 3 * int(floor(max(0, wave - 1) / 5))
	to_spawn = base + plus_each + bonus_five
	spawn_rate = max(0.12, 0.5 - wave * 0.02)
	spawn_cd = 0.0
	spawning = true
	time_to_next_wave = 0.0

func _generate_maze() -> Array:
	var g := []
	# Inicializar tudo como chão (0)
	for r in range(GRID_ROWS):
		g.append([])
		for c in range(GRID_COLS):
			g[r].append(0)
	
	# Criar bordas externas (paredes)
	for c in range(GRID_COLS):
		g[0][c] = 1
		g[GRID_ROWS-1][c] = 1
	for r in range(GRID_ROWS):
		g[r][0] = 1
		g[r][GRID_COLS-1] = 1
	
	# Verificar que o centro está correto: deve ser (16, 16) para grid 33x33
	# center.x e center.y devem ser exatamente 16 - número ímpar garante simetria perfeita
	
	# Calcular área central de forma matemática precisa
	# BASE_SIZE_TILES = 7, então área vai de center ± 3
	var base_start_col = center.x - int(BASE_SIZE_TILES / 2)  # 16 - 3 = 13
	var base_end_col = center.x + int(BASE_SIZE_TILES / 2)    # 16 + 3 = 19
	var base_start_row = center.y - int(BASE_SIZE_TILES / 2)  # 16 - 3 = 13
	var base_end_row = center.y + int(BASE_SIZE_TILES / 2)    # 16 + 3 = 19
	
	# Limpar área central PRIMEIRO (garante simetria)
	for r in range(base_start_row, base_end_row + 1):
		for c in range(base_start_col, base_end_col + 1):
			if r >= 0 and r < GRID_ROWS and c >= 0 and c < GRID_COLS:
				g[r][c] = 0
	
	# Criar anéis concêntricos começando logo após a área central
	var rings := 8
	var gap_size := 2
	
	# O primeiro anel começa imediatamente após a área central
	# Área central vai até center ± 3, então primeiro anel em center ± 4
	var first_ring_distance = int(BASE_SIZE_TILES / 2) + 1  # 3 + 1 = 4
	
	for ring_idx in range(1, rings + 1):
		# Distância do centro para este anel
		var ring_dist = first_ring_distance + (ring_idx - 1) * 2
		
		# Calcular limites do anel de forma simétrica
		var top_row = center.y - ring_dist
		var bottom_row = center.y + ring_dist
		var left_col = center.x - ring_dist
		var right_col = center.x + ring_dist
		
		# Verificar limites válidos
		if top_row < 1 or bottom_row >= GRID_ROWS - 1 or left_col < 1 or right_col >= GRID_COLS - 1:
			continue
		
		# Criar paredes do anel (todas as bordas)
		# Topo e fundo
		for col in range(left_col, right_col + 1):
			if top_row >= 0 and top_row < GRID_ROWS and col >= 0 and col < GRID_COLS:
				g[top_row][col] = 1
			if bottom_row >= 0 and bottom_row < GRID_ROWS and col >= 0 and col < GRID_COLS:
				g[bottom_row][col] = 1
		
		# Esquerda e direita
		for row in range(top_row, bottom_row + 1):
			if row >= 0 and row < GRID_ROWS and left_col >= 0 and left_col < GRID_COLS:
				g[row][left_col] = 1
			if row >= 0 and row < GRID_ROWS and right_col >= 0 and right_col < GRID_COLS:
				g[row][right_col] = 1
		
		# Criar aberturas simétricas - sempre centralizadas no centro exato
		var gap_start = center.x - gap_size
		var gap_end = center.x + gap_size
		var gap_start_r = center.y - gap_size
		var gap_end_r = center.y + gap_size
		
		# Garantir que os gaps estão dentro dos limites do anel
		gap_start = max(gap_start, left_col)
		gap_end = min(gap_end, right_col)
		gap_start_r = max(gap_start_r, top_row)
		gap_end_r = min(gap_end_r, bottom_row)
		
		if ring_idx == 1:
			# Primeiro anel: apenas 2 entradas (esquerda e direita) para manter simetria
			# Esquerda
			for row in range(gap_start_r, gap_end_r + 1):
				if row >= 0 and row < GRID_ROWS and left_col >= 0 and left_col < GRID_COLS:
					g[row][left_col] = 0
			# Direita
			for row in range(gap_start_r, gap_end_r + 1):
				if row >= 0 and row < GRID_ROWS and right_col >= 0 and right_col < GRID_COLS:
					g[row][right_col] = 0
		elif ring_idx % 2 == 0:
			# Anéis pares: aberturas horizontais (topo e fundo) - simétricas
			for col in range(gap_start, gap_end + 1):
				if col >= 0 and col < GRID_COLS:
					if top_row >= 0 and top_row < GRID_ROWS:
						g[top_row][col] = 0
					if bottom_row >= 0 and bottom_row < GRID_ROWS:
						g[bottom_row][col] = 0
		else:
			# Anéis ímpares: aberturas verticais (esquerda e direita) - simétricas
			for row in range(gap_start_r, gap_end_r + 1):
				if row >= 0 and row < GRID_ROWS:
					if left_col >= 0 and left_col < GRID_COLS:
						g[row][left_col] = 0
					if right_col >= 0 and right_col < GRID_COLS:
						g[row][right_col] = 0
	
	return g

func _tile_center(col: int, row: int) -> Vector2:
	# centro exato do tile, garantindo precisão
	return Vector2(float(col) * TILE_SIZE + TILE_SIZE / 2.0, float(row) * TILE_SIZE + TILE_SIZE / 2.0)

func _world_to_base_grid(world_pos: Vector2) -> Vector2i:
	# converte posição do mundo para coordenadas do grid da base
	# Usar as mesmas coordenadas exatas do grid do labirinto
	var base_half_size = int(BASE_SIZE_TILES / 2)
	var base_start_col = center.x - base_half_size  # 14
	var base_start_row = center.y - base_half_size   # 14
	
	# Converter posição do mundo para coordenadas de tile do grid principal
	var tile_col = int(floor(world_pos.x / TILE_SIZE))
	var tile_row = int(floor(world_pos.y / TILE_SIZE))
	
	# Calcular posição relativa dentro da base
	var relative_col = tile_col - base_start_col
	var relative_row = tile_row - base_start_row
	
	# Converter para coordenadas do grid interno (15x15)
	var grid_size_tiles = float(BASE_SIZE_TILES) / float(BASE_GRID_SIZE)
	var gx = int(floor(float(relative_col) / grid_size_tiles))
	var gy = int(floor(float(relative_row) / grid_size_tiles))
	
	# Clampar para os limites do grid
	gx = clamp(gx, 0, BASE_GRID_SIZE - 1)
	gy = clamp(gy, 0, BASE_GRID_SIZE - 1)
	return Vector2i(gx, gy)

func _base_grid_to_world(grid_x: int, grid_y: int) -> Vector2:
	# converte coordenadas do grid para posição do mundo (centro do tile do grid)
	# Usar as mesmas coordenadas exatas do grid do labirinto
	var base_half_size = int(BASE_SIZE_TILES / 2)
	var base_start_col = center.x - base_half_size  # 14
	var base_start_row = center.y - base_half_size  # 14
	
	# Converter coordenadas do grid interno para posição relativa na base
	var grid_size_tiles = float(BASE_SIZE_TILES) / float(BASE_GRID_SIZE)
	var relative_col = float(grid_x) * grid_size_tiles + grid_size_tiles / 2.0
	var relative_row = float(grid_y) * grid_size_tiles + grid_size_tiles / 2.0
	
	# Converter para coordenadas absolutas de tile e depois para pixel
	var tile_col = base_start_col + relative_col
	var tile_row = base_start_row + relative_row
	
	var world_x = float(tile_col) * TILE_SIZE + TILE_SIZE / 2.0
	var world_y = float(tile_row) * TILE_SIZE + TILE_SIZE / 2.0
	return Vector2(world_x, world_y)

func _can_place_in_grid(grid_x: int, grid_y: int, size: int, _item_type: int) -> bool:
	# verifica se pode colocar item do tamanho size nas coordenadas grid_x, grid_y
	# _item_type: 1=torre, 2=bloco, 3=quartel (não usado, mas mantido para compatibilidade)
	for dy in range(size):
		for dx in range(size):
			var gx = grid_x + dx
			var gy = grid_y + dy
			if gx < 0 or gx >= BASE_GRID_SIZE or gy < 0 or gy >= BASE_GRID_SIZE:
				return false
			# não pode colocar em área ocupada
			if base_grid.size() <= gy or base_grid[gy].size() <= gx:
				return false
			var cell_value = base_grid[gy][gx]
			if cell_value != 0:
				return false
	return true

func _set_grid_area(grid_x: int, grid_y: int, size: int, item_type: int) -> void:
	# marca área do grid como ocupada
	for dy in range(size):
		for dx in range(size):
			var gx = grid_x + dx
			var gy = grid_y + dy
			if gx >= 0 and gx < BASE_GRID_SIZE and gy >= 0 and gy < BASE_GRID_SIZE:
				if base_grid.size() > gy and base_grid[gy].size() > gx:
					base_grid[gy][gx] = item_type

func _clear_grid_area(grid_x: int, grid_y: int, size: int) -> void:
	# limpa área do grid
	for dy in range(size):
		for dx in range(size):
			var gx = grid_x + dx
			var gy = grid_y + dy
			if gx >= 0 and gx < BASE_GRID_SIZE and gy >= 0 and gy < BASE_GRID_SIZE:
				if base_grid.size() > gy and base_grid[gy].size() > gx:
					base_grid[gy][gx] = 0

func _is_walkable(c: int, r: int) -> bool:
	if not (r >= 0 and r < GRID_ROWS and c >= 0 and c < GRID_COLS and grid[r][c] == 0):
		return false
	# verificar se tem bloco nessa posição usando o grid
	var check_pos = _tile_center(c, r)
	var grid_coord = _world_to_base_grid(check_pos)
	if grid_coord.x >= 0 and grid_coord.x < BASE_GRID_SIZE and grid_coord.y >= 0 and grid_coord.y < BASE_GRID_SIZE:
		# verificar no grid da base
		if base_grid.size() > grid_coord.y and base_grid[grid_coord.y].size() > grid_coord.x:
			if base_grid[grid_coord.y][grid_coord.x] == 2:  # 2 = bloco
				return false
	return true

func _bfs_path(from_c: int, from_r: int) -> Array:
	var start = Vector2i(from_c, from_r)
	var goal = center
	var q: Array = [start]
	var visited := { start: true }
	var parent := {}
	var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	while not q.is_empty():
		var cur: Vector2i = q.pop_front()
		if cur == goal:
			break
		for d in dirs:
			var nc = cur.x + d.x
			var nr = cur.y + d.y
			var nk = Vector2i(nc, nr)
			if not _is_walkable(nc, nr):
				continue
			if visited.has(nk):
				continue
			visited[nk] = true
			parent[nk] = cur
			q.append(nk)
	if not visited.has(goal):
		return []
	var path := []
	var ck = goal
	while ck != start:
		path.append(ck)
		ck = parent.get(ck, start)
		if ck == start:
			break
	path.reverse()
	var pts := []
	for t in path:
		pts.append(_tile_center(t.x, t.y))
	return pts

func _random_spawn() -> Vector2i:
	var cells: Array = []
	# coletar células válidas nas bordas (chão e walkable)
	for c in range(1, GRID_COLS-1):
		if grid.size() > 1 and grid[1].size() > c and grid[1][c] == 0 and _is_walkable(c, 1):
			cells.append(Vector2i(c, 1))
		if grid.size() > GRID_ROWS-2 and grid[GRID_ROWS-2].size() > c and grid[GRID_ROWS-2][c] == 0 and _is_walkable(c, GRID_ROWS-2):
			cells.append(Vector2i(c, GRID_ROWS-2))
	for r in range(1, GRID_ROWS-1):
		if grid.size() > r and grid[r].size() > 1 and grid[r][1] == 0 and _is_walkable(1, r):
			cells.append(Vector2i(1, r))
		if grid.size() > r and grid[r].size() > GRID_COLS-2 and grid[r][GRID_COLS-2] == 0 and _is_walkable(GRID_COLS-2, r):
			cells.append(Vector2i(GRID_COLS-2, r))
	
	# validar pathfinding apenas para células selecionadas (otimização)
	var valid_cells: Array = []
	for cell in cells:
		var path = _bfs_path(cell.x, cell.y)
		if not path.is_empty():
			valid_cells.append(cell)
	
	if valid_cells.is_empty():
		# fallback: retornar posição próxima ao centro se não encontrar células válidas
		return Vector2i(center.x, 1)
	return valid_cells[randi() % valid_cells.size()]

func _enemy_new(col: int, row: int) -> Dictionary:
	var pos = _tile_center(col, row)
	var initial_hp := 2  # HP suficiente para 2 ataques iniciais
	var f := _wave_factor()
	var hp := int(max(1, round(initial_hp * f)))
	var enemy_idx = enemies.size()
	var e = { pos = pos, speed = 30.0 * f, base_speed = 30.0 * f, hp = hp, max_hp = hp, radius = 9, path = _bfs_path(col, row), path_index = 0, reached = false, idx = enemy_idx, is_boss = false }
	enemy_effects[enemy_idx] = {freeze_time = 0.0, fire_time = 0.0, fire_damage = 0.0}
	return e

func _enemy_new_boss(col: int, row: int) -> Dictionary:
	var pos = _tile_center(col, row)
	var initial_hp := 50  # chefe tem muito mais HP (equivalente a 25 hits iniciais)
	var f := _wave_factor()
	var hp := int(max(1, round(initial_hp * f)))
	var enemy_idx = enemies.size()
	var e = { pos = pos, speed = 30.0 * f * 0.8, base_speed = 30.0 * f * 0.8, hp = hp, max_hp = hp, radius = 12, path = _bfs_path(col, row), path_index = 0, reached = false, idx = enemy_idx, is_boss = true }
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
		var basep = _tile_center(center.x, center.y)
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
				$CanvasLayer/GameOverOverlay/Panel/LblWave.text = "Wave %d" % wave
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
					hero["coins"] += 40 if is_boss else 2
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
					hero["coins"] += 40 if is_boss else 2
				
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
	var can_range: bool = hero["coins"] >= TOWER_RANGE_COST
	var can_rate: bool = hero["coins"] >= TOWER_RATE_COST and t.fire_rate > 0.12
	var can_dirs: bool = hero["coins"] >= TOWER_DIRS_COST and dirs_count < 4
	var can_dmg: bool = hero["coins"] >= TOWER_DMG_COST
	var can_freeze: bool = hero["coins"] >= TOWER_FREEZE_COST and not t.get("has_freeze", false)
	var can_fire: bool = hero["coins"] >= TOWER_FIRE_COST and not t.get("has_fire", false)
	
	tower_menu.set_item_text(0, "Alcance +60 (%d)" % TOWER_RANGE_COST)
	tower_menu.set_item_text(1, "Cadencias + (%d)" % TOWER_RATE_COST)
	tower_menu.set_item_text(2, "+4 Direcoes (%d)" % TOWER_DIRS_COST)
	tower_menu.set_item_text(3, "Dano +0.5 (%d)" % TOWER_DMG_COST)
	tower_menu.set_item_text(4, "Congelamento (%d)" % TOWER_FREEZE_COST)
	tower_menu.set_item_text(5, "Fogo (%d)" % TOWER_FIRE_COST)
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
			if hero["coins"] >= TOWER_RANGE_COST:
				t.range += 60.0
				t.levels["RANGE"] += 1
				hero["coins"] -= TOWER_RANGE_COST
		2:  # Cadência (reduz tempo entre tiros)
			if hero["coins"] >= TOWER_RATE_COST and t.fire_rate > 0.12:
				t.fire_rate = max(0.1, t.fire_rate - 0.05)
				t.levels["RATE"] += 1
				hero["coins"] -= TOWER_RATE_COST
		3:  # +4 Direções
			if hero["coins"] >= TOWER_DIRS_COST and t.dirs.size() < 4:
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
				hero["coins"] -= TOWER_DIRS_COST
		4:  # Dano
			if hero["coins"] >= TOWER_DMG_COST:
				t.damage += 0.5
				t.levels["DMG"] += 1
				hero["coins"] -= TOWER_DMG_COST
		5:  # Congelamento
			if hero["coins"] >= TOWER_FREEZE_COST and not t.get("has_freeze", false):
				t["has_freeze"] = true
				t.levels["FREEZE"] = 1
				hero["coins"] -= TOWER_FREEZE_COST
		6:  # Fogo
			if hero["coins"] >= TOWER_FIRE_COST and not t.get("has_fire", false):
				t["has_fire"] = true
				t.levels["FIRE"] = 1
				hero["coins"] -= TOWER_FIRE_COST
	towers[tower_selected_index] = t
	tower_selected_index = -1

func _try_shoot(target: Vector2) -> void:
	if hero["cooldown"] > 0.0:
		return
	arrows.append(_arrow_new(hero["x"], hero["y"], target))
	hero["cooldown"] = hero["fire_rate"]

func _jump_to_wave_10() -> void:
	# pular para wave 10: definir wave para 9 e forçar início da próxima wave
	wave = 9
	bosses_spawned_this_wave = 0
	enemies.clear()
	choosing_upgrade = false
	benefit_applied = false
	$CanvasLayer/UpgradeOverlay.visible = false
	time_to_next_wave = 0.0
	spawning = false
	to_spawn = 0

func _on_buy_tower() -> void:
	if placing_tower:
		return
	if hero["coins"] < TOWER_COST:
		return
	if towers.size() >= MAX_TOWERS:
		return  # limite de torres atingido
	placing_tower = true
	placing_block = false
	placing_barracks = false

func _on_buy_block() -> void:
	if placing_block:
		return
	if hero["coins"] < BLOCK_COST:
		return
	if blocks.size() >= MAX_BLOCKS:
		return  # limite de blocos atingido
	placing_block = true
	placing_tower = false
	placing_barracks = false

func _on_buy_barracks() -> void:
	if placing_barracks:
		return
	if hero["coins"] < BARRACKS_COST:
		return
	if barracks.size() >= MAX_BARRACKS:
		return  # limite de quartéis atingido
	placing_barracks = true
	placing_tower = false
	placing_block = false

func _on_buy_menu_pressed(id: int) -> void:
	match id:
		1:  # Torre
			_on_buy_tower()
		2:  # Bloco
			_on_buy_block()
		3:  # Quartel
			_on_buy_barracks()

func _open_barracks_menu(idx: int, screen_pos: Vector2) -> void:
	if barracks_menu == null:
		return
	barracks_selected_index = idx
	var b = barracks[idx]
	var can_dmg: bool = hero["coins"] >= BARRACKS_DMG_COST
	var can_hold: bool = hero["coins"] >= BARRACKS_HOLD_COST
	var can_soldiers: bool = hero["coins"] >= BARRACKS_SOLDIERS_COST and b.max_soldiers < 4  # máximo de 4 soldados
	
	barracks_menu.set_item_text(0, "Dano +0.2 (%d)" % BARRACKS_DMG_COST)
	barracks_menu.set_item_text(1, "Tempo Hold +1s (%d)" % BARRACKS_HOLD_COST)
	barracks_menu.set_item_text(2, "+1 Soldado (%d) [%d/4]" % [BARRACKS_SOLDIERS_COST, b.max_soldiers])
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
			if hero["coins"] >= BARRACKS_DMG_COST:
				b.damage += 0.2
				b.levels["DMG"] += 1
				hero["coins"] -= BARRACKS_DMG_COST
		2:  # Tempo Hold
			if hero["coins"] >= BARRACKS_HOLD_COST:
				b.hold_time += 1.0
				b.levels["HOLD"] += 1
				hero["coins"] -= BARRACKS_HOLD_COST
		3:  # +1 Soldado
			if hero["coins"] >= BARRACKS_SOLDIERS_COST and b.max_soldiers < 4:
				b.max_soldiers += 1
				b.levels["SOLDIERS"] += 1
				hero["coins"] -= BARRACKS_SOLDIERS_COST
	barracks[barracks_selected_index] = b
	barracks_selected_index = -1

func _is_inside_base_point(p: Vector2) -> bool:
	# Usar as mesmas coordenadas exatas do grid do labirinto
	var base_half_size = int(BASE_SIZE_TILES / 2)
	var base_start_col = center.x - base_half_size
	var base_start_row = center.y - base_half_size
	var base_end_col = center.x + base_half_size
	var base_end_row = center.y + base_half_size
	
	# Converter posição do mundo para coordenadas de tile
	var tile_col = int(floor(p.x / TILE_SIZE))
	var tile_row = int(floor(p.y / TILE_SIZE))
	
	# Verificar se está dentro da área da base
	return tile_col >= base_start_col and tile_col <= base_end_col and \
		   tile_row >= base_start_row and tile_row <= base_end_row

func _try_place_tower(pos: Vector2) -> void:
	# verificar moedas
	if hero["coins"] < TOWER_COST:
		placing_tower = false
		return
	
	# verificar limite
	if towers.size() >= MAX_TOWERS:
		placing_tower = false
		return
	
	if not _is_inside_base_point(pos):
		placing_tower = false
		return
	
	# converter para coordenadas do grid
	var grid_coord = _world_to_base_grid(pos)
	
	# verificar se pode colocar torre 2x2
	if not _can_place_in_grid(grid_coord.x, grid_coord.y, TOWER_SIZE_GRID, 1):
		placing_tower = false
		return
	
	# marcar área no grid
	_set_grid_area(grid_coord.x, grid_coord.y, TOWER_SIZE_GRID, 1)
	
	# calcular posição central da torre
	var tower_world_pos = _base_grid_to_world(grid_coord.x, grid_coord.y)
	
	# calcular direção baseada na posição relativa ao centro da base
	var bc = _tile_center(center.x, center.y)
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
	hero["coins"] -= TOWER_COST
	placing_tower = false

func _try_place_block(pos: Vector2) -> void:
	# verificar moedas
	if hero["coins"] < BLOCK_COST:
		placing_block = false
		return
	
	# verificar limite
	if blocks.size() >= MAX_BLOCKS:
		placing_block = false
		return
	
	if not _is_inside_base_point(pos):
		placing_block = false
		return
	
	# converter para coordenadas do grid
	var grid_coord = _world_to_base_grid(pos)
	
	# marcar área no grid e adicionar à lista (sem validação de posição)
	_set_grid_area(grid_coord.x, grid_coord.y, BLOCK_SIZE_GRID, 2)
	var block_world_pos = _base_grid_to_world(grid_coord.x, grid_coord.y)
	blocks.append({
		"pos": block_world_pos,
		"grid_x": grid_coord.x,
		"grid_y": grid_coord.y
	})
	hero["coins"] -= BLOCK_COST
	placing_block = false

func _try_place_barracks(pos: Vector2) -> void:
	# verificar moedas
	if hero["coins"] < BARRACKS_COST:
		placing_barracks = false
		return
	
	# verificar limite
	if barracks.size() >= MAX_BARRACKS:
		placing_barracks = false
		return
	
	if not _is_inside_base_point(pos):
		placing_barracks = false
		return
	
	# converter para coordenadas do grid
	var grid_coord = _world_to_base_grid(pos)
	
	# verificar se pode colocar quartel 2x2
	if not _can_place_in_grid(grid_coord.x, grid_coord.y, BARRACKS_SIZE_GRID, 3):
		placing_barracks = false
		return
	
	# marcar área no grid
	_set_grid_area(grid_coord.x, grid_coord.y, BARRACKS_SIZE_GRID, 3)
	
	# calcular posição central do quartel
	var barracks_world_pos = _base_grid_to_world(grid_coord.x, grid_coord.y)
	
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
	hero["coins"] -= BARRACKS_COST
	placing_barracks = false

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
		t.cooldown = max(0.0, t.cooldown - delta)
		if t.cooldown <= 0.0:
			_tower_fire_cross(t)
			t.cooldown = t.fire_rate

func _tower_fire_cross(tower: Dictionary) -> void:
	var speed := 260.0
	var dirs: Array = tower.get("dirs", [Vector2(1, 0)])
	var tower_damage: float = tower.get("damage", 0.5)
	var has_freeze: bool = tower.get("has_freeze", false)
	var has_fire: bool = tower.get("has_fire", false)
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
