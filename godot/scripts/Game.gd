extends Node2D

const TILE_SIZE := 28
const GRID_COLS := 34
const GRID_ROWS := 34

var grid := [] # 0 floor, 1 wall
var center := Vector2i(GRID_COLS/2, GRID_ROWS/2)

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
const TOWER_SIZE_GRID := 2  # torre ocupa 2x2 tiles do grid
const BLOCK_SIZE_GRID := 3  # bloco ocupa 3x3 tiles do grid
var placing_tower := false
var placing_block := false
var towers: Array = []
var blocks: Array = []  # blocos de bloqueio - cada bloco: {grid_x: int, grid_y: int}
var base_grid: Array = []  # grid 15x15: 0=vazio, 1=torre, 2=bloco
var preview_mouse_pos := Vector2.ZERO  # posição do mouse para preview

# tower upgrade system
const TOWER_RANGE_COST := 8
const TOWER_RATE_COST := 8
const TOWER_DIRS_COST := 12
const TOWER_DMG_COST := 10
var tower_menu: PopupMenu
var tower_selected_index := -1
var placing_tower_dir := Vector2(1, 0)  # direção inicial ao colocar torre

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

# wave scaling
const WAVE_SCALE := 1.08  # reduzido ainda mais para crescimento mais lento
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
	var win_w := int(GRID_COLS * TILE_SIZE)
	var win_h := int(GRID_ROWS * TILE_SIZE + 52)  # grid + top bar
	DisplayServer.window_set_size(Vector2i(win_w, win_h))

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
	
	# garantir que os botões existam na TopBar
	if not tb.has_node("BtnBuyTower"):
		var btn_tower = Button.new()
		btn_tower.name = "BtnBuyTower"
		tb.add_child(btn_tower)
		btn_tower.position = Vector2(810, 8)
		btn_tower.size = Vector2(130, 28)
		btn_tower.text = "Comprar Torre (%d)" % TOWER_COST
		btn_tower.pressed.connect(_on_buy_tower)
	else:
		tb.get_node("BtnBuyTower").pressed.connect(_on_buy_tower)
	
	if not tb.has_node("BtnBuyBlock"):
		var btn_block = Button.new()
		btn_block.name = "BtnBuyBlock"
		tb.add_child(btn_block)
		btn_block.position = Vector2(950, 8)
		btn_block.size = Vector2(130, 28)
		btn_block.text = "Comprar Bloco (%d)" % BLOCK_COST
		btn_block.pressed.connect(_on_buy_block)
	else:
		tb.get_node("BtnBuyBlock").pressed.connect(_on_buy_block)

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
	tower_menu.id_pressed.connect(Callable(self, "_on_tower_menu_pressed"))
	menu_container.add_child(tower_menu)
	$CanvasLayer.add_child(menu_container)
	# top bar alinhada à esquerda e com largura do grid
	var grid_px_w: float = GRID_COLS * TILE_SIZE
	tb.position = Vector2(0, 0)
	tb.size = Vector2(grid_px_w, 44)

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
	# remover inimigos mortos/que chegaram na base
	var alive: Array = []
	for e in enemies:
		if e["hp"] > 0 and not e["reached"]:
			alive.append(e)
	enemies = alive

	# waves
	if not spawning and enemies.is_empty() and not choosing_upgrade:
		if wave > 0:
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
			var base: int = 6
			var plus_each: int = max(0, wave - 1)
			var bonus_five: int = 3 * int(floor(max(0, wave - 1) / 5))
			to_spawn = base + plus_each + bonus_five
			spawn_rate = max(0.12, 0.5 - wave * 0.02)
			spawn_cd = 0.0
			spawning = true

	if spawning:
		spawn_cd -= delta
		if spawn_cd <= 0.0 and to_spawn > 0:
			spawn_cd = spawn_rate
			to_spawn -= 1
			var s = _random_spawn()
			if s != null:
				enemies.append(_enemy_new(s.x, s.y))
		if to_spawn == 0:
			spawning = false
			time_to_next_wave = intermission

	# UI
	var tb = $CanvasLayer/HUD/TopBar
	tb.get_node("LblLeft").text = "Wave %d  Inimigos %d" % [wave, enemies.size()]
	tb.get_node("LblCenter").text = "Moedas %d" % [int(hero["coins"])]
	tb.get_node("LblRight").text = "Vida %d" % [base_hp]
	
	# atualizar botões na TopBar
	if tb.has_node("BtnBuyTower"):
		var btn: Button = tb.get_node("BtnBuyTower")
		btn.text = "Comprar Torre (%d)" % TOWER_COST
		btn.disabled = hero["coins"] < TOWER_COST and not placing_tower
		btn.visible = true
	if tb.has_node("BtnBuyBlock"):
		var btn_block: Button = tb.get_node("BtnBuyBlock")
		btn_block.text = "Comprar Bloco (%d)" % BLOCK_COST
		btn_block.disabled = hero["coins"] < BLOCK_COST and not placing_block
		btn_block.visible = true

	queue_redraw()

func _input(event: InputEvent) -> void:
	# atualizar posição do mouse para preview
	if event is InputEventMouseMotion:
		preview_mouse_pos = event.position
		queue_redraw()
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not choosing_upgrade:
			var pos = event.position
			if placing_tower:
				_try_place_tower(pos)
			elif placing_block:
				_try_place_block(pos)
			else:
				_try_shoot(Vector2(pos.x, pos.y))
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if not choosing_upgrade and not game_over:
			# cancelar colocação com botão direito
			if placing_tower or placing_block:
				placing_tower = false
				placing_block = false
				queue_redraw()
				return
			# usar coordenadas da tela diretamente (já que o Node2D está na origem)
			var mouse_pos = event.position
			var idx := _find_tower_at(mouse_pos, 20.0)  # raio maior para facilitar detecção
			if idx != -1:
				_open_tower_menu(idx, mouse_pos)
				return

func _draw() -> void:
	# fundo
	draw_rect(Rect2(0, 0, GRID_COLS*TILE_SIZE, GRID_ROWS*TILE_SIZE), Color(0.08, 0.09, 0.12))
	# draw grid
	for r in range(GRID_ROWS):
		for c in range(GRID_COLS):
			if grid[r][c] == 0 and tex_grass != null:
				draw_texture_rect(tex_grass, Rect2(c*TILE_SIZE, r*TILE_SIZE, TILE_SIZE, TILE_SIZE), true)
			else:
				var col = Color(0.18,0.19,0.23) if grid[r][c] == 0 else Color(0.29,0.32,0.40)
				draw_rect(Rect2(c*TILE_SIZE, r*TILE_SIZE, TILE_SIZE, TILE_SIZE), col)
	# base com transparência moderada
	var bc = _tile_center(center.x, center.y)
	var base_px := BASE_SIZE_TILES * TILE_SIZE
	var base_rect := Rect2(bc.x - base_px/2, bc.y - base_px/2, base_px, base_px)
	draw_rect(base_rect, Color(0.2,0.24,0.28,0.6))  # transparência moderada
	
	# desenhar grid da base com transparência
	var grid_size_px := BASE_SIZE_TILES * TILE_SIZE / BASE_GRID_SIZE
	for gy in range(BASE_GRID_SIZE + 1):
		var y = bc.y - base_px/2 + gy * grid_size_px
		draw_line(Vector2(bc.x - base_px/2, y), Vector2(bc.x + base_px/2, y), Color(0.3,0.32,0.36,0.5), 1.0)
	for gx in range(BASE_GRID_SIZE + 1):
		var x = bc.x - base_px/2 + gx * grid_size_px
		draw_line(Vector2(x, bc.y - base_px/2), Vector2(x, bc.y + base_px/2), Color(0.3,0.32,0.36,0.5), 1.0)
	
	if tex_tent != null:
		var s := Vector2(TILE_SIZE*1.6, TILE_SIZE*1.3)
		var pos := Vector2(bc.x - s.x/2, bc.y - s.y/2)
		draw_texture_rect(tex_tent, Rect2(pos, s), false)
	else:
		draw_rect(Rect2(bc.x- (TILE_SIZE)/2, bc.y- (TILE_SIZE)/2, TILE_SIZE, TILE_SIZE), Color(0.9,0.7,0.2))
	# enemies
	for e in enemies:
		# barra de vida
		var max_hp: int = int(e.get("max_hp", 2))
		var hp_ratio: float = clamp(float(e["hp"]) / float(max_hp), 0.0, 1.0)
		var bx := int(e["pos"].x) - 8
		var by := int(e["pos"].y) - 12
		draw_rect(Rect2(bx, by, 16, 3), Color(0.14,0.15,0.18))
		draw_rect(Rect2(bx, by, int(16*hp_ratio), 3), Color(0.78,0.32,0.32))
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
			draw_circle(e["pos"], e.get("radius", 9), Color(0.9,0.35,0.35))
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
	
	# preview de colocação
	if placing_tower or placing_block:
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
	ov.get_node("Panel/Btn1").text = upgrade_options[0]["label"]
	ov.get_node("Panel/Btn2").text = upgrade_options[1]["label"]
	ov.get_node("Panel/Btn3").text = upgrade_options[2]["label"]

func _apply_benefit(i: int) -> void:
	if benefit_applied:
		return
	if i < 0 or i >= upgrade_options.size():
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
	for r in range(GRID_ROWS):
		g.append([])
		for c in range(GRID_COLS):
			g[r].append(0)
	for c in range(GRID_COLS):
		g[0][c] = 1
		g[GRID_ROWS-1][c] = 1
	for r in range(GRID_ROWS):
		g[r][0] = 1
		g[r][GRID_COLS-1] = 1
	var rings := 8  # aumentado de 6 para 8
	for k in range(2, rings*2+1, 2):
		var top = center.y - k
		var bottom = center.y + k
		var left = center.x - k
		var right = center.x + k
		if top <= 1 or left <= 1 or bottom >= GRID_ROWS-2 or right >= GRID_COLS-2:
			continue
		for c in range(left, right+1):
			g[top][c] = 1
			g[bottom][c] = 1
		for r in range(top, bottom+1):
			g[r][left] = 1
			g[r][right] = 1
		# criar duas aberturas por anel (lados opostos)
		var gap_size = 2
		var side_a = int(k/2) % 4
		var side_b = (side_a + 2) % 4
		for side in [side_a, side_b]:
			if side == 0:
				for c2 in range(center.x-gap_size, center.x+gap_size+1): g[top][c2] = 0
			elif side == 1:
				for r2 in range(center.y-gap_size, center.y+gap_size+1): g[r2][right] = 0
			elif side == 2:
				for c2 in range(center.x-gap_size, center.x+gap_size+1): g[bottom][c2] = 0
			else:
				for r2 in range(center.y-gap_size, center.y+gap_size+1): g[r2][left] = 0
	for r in range(center.y-1, center.y+2):
		for c in range(center.x-1, center.x+2):
			g[r][c] = 0
	return g

func _tile_center(col: int, row: int) -> Vector2:
	return Vector2(col*TILE_SIZE + TILE_SIZE/2.0, row*TILE_SIZE + TILE_SIZE/2.0)

func _world_to_base_grid(world_pos: Vector2) -> Vector2i:
	# converte posição do mundo para coordenadas do grid da base
	var bc = _tile_center(center.x, center.y)
	var half_base := (BASE_SIZE_TILES * TILE_SIZE) / 2.0
	var relative = world_pos - bc
	var grid_size_px := BASE_SIZE_TILES * TILE_SIZE / BASE_GRID_SIZE
	# calcular coordenada do grid usando floor para pegar o tile correto
	var gx = int(floor((relative.x + half_base) / grid_size_px))
	var gy = int(floor((relative.y + half_base) / grid_size_px))
	gx = clamp(gx, 0, BASE_GRID_SIZE - 1)
	gy = clamp(gy, 0, BASE_GRID_SIZE - 1)
	return Vector2i(gx, gy)

func _base_grid_to_world(grid_x: int, grid_y: int) -> Vector2:
	# converte coordenadas do grid para posição do mundo (centro do tile do grid)
	var bc = _tile_center(center.x, center.y)
	var half_base := (BASE_SIZE_TILES * TILE_SIZE) / 2.0
	var grid_size_px := BASE_SIZE_TILES * TILE_SIZE / BASE_GRID_SIZE
	var world_x = bc.x - half_base + (grid_x + 0.5) * grid_size_px
	var world_y = bc.y - half_base + (grid_y + 0.5) * grid_size_px
	return Vector2(world_x, world_y)

func _can_place_in_grid(grid_x: int, grid_y: int, size: int, item_type: int) -> bool:
	# verifica se pode colocar item do tamanho size nas coordenadas grid_x, grid_y
	# item_type: 1=torre, 2=bloco
	for dy in range(size):
		for dx in range(size):
			var gx = grid_x + dx
			var gy = grid_y + dy
			if gx < 0 or gx >= BASE_GRID_SIZE or gy < 0 or gy >= BASE_GRID_SIZE:
				return false
			# não pode colocar em área ocupada (verificar primeiro antes das outras condições)
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
				base_grid[gy][gx] = item_type

func _clear_grid_area(grid_x: int, grid_y: int, size: int) -> void:
	# limpa área do grid
	for dy in range(size):
		for dx in range(size):
			var gx = grid_x + dx
			var gy = grid_y + dy
			if gx >= 0 and gx < BASE_GRID_SIZE and gy >= 0 and gy < BASE_GRID_SIZE:
				base_grid[gy][gx] = 0

func _is_walkable(c: int, r: int) -> bool:
	if not (r >= 0 and r < GRID_ROWS and c >= 0 and c < GRID_COLS and grid[r][c] == 0):
		return false
	# verificar se tem bloco nessa posição usando o grid
	var check_pos = _tile_center(c, r)
	var grid_coord = _world_to_base_grid(check_pos)
	if grid_coord.x >= 0 and grid_coord.x < BASE_GRID_SIZE and grid_coord.y >= 0 and grid_coord.y < BASE_GRID_SIZE:
		# verificar no grid da base
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
	for c in range(1, GRID_COLS-1):
		if grid[1][c] == 0: cells.append(Vector2i(c,1))
		if grid[GRID_ROWS-2][c] == 0: cells.append(Vector2i(c,GRID_ROWS-2))
	for r in range(1, GRID_ROWS-1):
		if grid[r][1] == 0: cells.append(Vector2i(1,r))
		if grid[r][GRID_COLS-2] == 0: cells.append(Vector2i(GRID_COLS-2,r))
	if cells.is_empty():
		return Vector2i(center.x, 1)
	return cells[randi() % cells.size()]

func _enemy_new(col: int, row: int) -> Dictionary:
	var pos = _tile_center(col, row)
	var base_hp := 2  # HP suficiente para 2 ataques iniciais
	var f := _wave_factor()
	var hp := int(max(1, round(base_hp * f)))
	var e = { pos = pos, speed = 45.0 * f, hp = hp, max_hp = hp, radius = 9, path = _bfs_path(col, row), path_index = 0, reached = false }
	return e

func _enemy_update(e: Dictionary, dt: float) -> void:
	if e["reached"] or e["hp"] <= 0:
		return
	if e["path_index"] >= e["path"].size():
		var basep = _tile_center(center.x, center.y)
		var v = basep - e["pos"]
		var d = max(v.length(), 0.0001)
		if d < 4.0:
			e["reached"] = true
			base_hp = max(0, base_hp - 5)
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
					hero["coins"] += 2
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
					hero["coins"] += 2
				b["life"] = 0.0

func _find_tower_at(p: Vector2, r: float) -> int:
	for i in range(towers.size()):
		if towers[i].pos.distance_to(p) <= r:
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
	
	tower_menu.set_item_text(0, "Alcance +60 (%d)" % TOWER_RANGE_COST)
	tower_menu.set_item_text(1, "Cadência + (%d)" % TOWER_RATE_COST)
	tower_menu.set_item_text(2, "+4 Direções (%d)" % TOWER_DIRS_COST)
	tower_menu.set_item_text(3, "Dano +0.5 (%d)" % TOWER_DMG_COST)
	tower_menu.set_item_disabled(0, not can_range)
	tower_menu.set_item_disabled(1, not can_rate)
	tower_menu.set_item_disabled(2, not can_dirs)
	tower_menu.set_item_disabled(3, not can_dmg)
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
	towers[tower_selected_index] = t
	tower_selected_index = -1

func _try_shoot(target: Vector2) -> void:
	if hero["cooldown"] > 0.0:
		return
	arrows.append(_arrow_new(hero["x"], hero["y"], target))
	hero["cooldown"] = hero["fire_rate"]

func _on_buy_tower() -> void:
	if placing_tower:
		return
	if hero["coins"] < TOWER_COST:
		return
	placing_tower = true
	placing_block = false

func _on_buy_block() -> void:
	if placing_block:
		return
	if hero["coins"] < BLOCK_COST:
		return
	placing_block = true
	placing_tower = false

func _is_inside_base_point(p: Vector2) -> bool:
	var bc = _tile_center(center.x, center.y)
	var half := (BASE_SIZE_TILES * TILE_SIZE) / 2.0
	return abs(p.x - bc.x) <= half - 2 and abs(p.y - bc.y) <= half - 2

func _try_place_tower(pos: Vector2) -> void:
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
	if not _is_inside_base_point(pos):
		placing_block = false
		return
	
	# converter para coordenadas do grid
	var grid_coord = _world_to_base_grid(pos)
	
	# verificar se pode colocar bloco 3x3
	if not _can_place_in_grid(grid_coord.x, grid_coord.y, BLOCK_SIZE_GRID, 2):
		placing_block = false
		return
	
	# IMPORTANTE: validar se ainda existe caminho para a base ANTES de colocar
	# testar colocação temporária
	_set_grid_area(grid_coord.x, grid_coord.y, BLOCK_SIZE_GRID, 2)
	var test_spawn = _random_spawn()
	var test_path = _bfs_path(test_spawn.x, test_spawn.y)
	if test_path.is_empty():
		# se não há caminho, remover o bloco temporário
		_clear_grid_area(grid_coord.x, grid_coord.y, BLOCK_SIZE_GRID)
		placing_block = false
		return
	
	# se passou na validação, manter o bloco no grid e adicionar à lista
	var block_world_pos = _base_grid_to_world(grid_coord.x, grid_coord.y)
	blocks.append({
		"pos": block_world_pos,
		"grid_x": grid_coord.x,
		"grid_y": grid_coord.y
	})
	hero["coins"] -= BLOCK_COST
	placing_block = false

func _physics_process(delta: float) -> void:
	hero["cooldown"] = max(0.0, hero["cooldown"] - delta)
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
	var life := float(tower.get("range", 260.0)) / speed
	for d in dirs:
		var b = { "pos": tower.pos, "vel": d * speed, "life": life, "radius": 2, "damage": tower_damage, "pierce": 0 }
		tower_bullets.append(b)

func _on_game_over_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")

func _on_game_over_restart() -> void:
	get_tree().reload_current_scene()
