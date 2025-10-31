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
const BASE_SIZE_TILES := 5 # lado ímpar, amplia área da base para colocar torres
const TOWER_COST := 10
var placing_tower := false
var towers: Array = [] # {pos: Vector2, cooldown: float, fire_rate: 0.5}

# tower upgrade system
const TOWER_RANGE_COST := 8
const TOWER_RATE_COST := 8
const TOWER_DIRS_COST := 12
var tower_menu: PopupMenu
var tower_selected_index := -1

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
const WAVE_SCALE := 1.2
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
	"levels": { "DMG": 0, "FIRERATE": 0, "PIERCE": 0 }, "coins": 0,
}

func _try_load(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _ready() -> void:
	# ajustar tamanho da janela para caber grid + barra superior
	var win_w := int(GRID_COLS * TILE_SIZE)
	var win_h := int(GRID_ROWS * TILE_SIZE + 52)
	DisplayServer.window_set_size(Vector2i(win_w, win_h))

	grid = _generate_maze()
	var p = _tile_center(center.x, center.y)
	hero["x"] = p.x
	hero["y"] = p.y

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
	if tb.has_node("BtnBuyTower"):
		tb.get_node("BtnBuyTower").pressed.connect(_on_buy_tower)

	# criar PopupMenu para torres
	tower_menu = PopupMenu.new()
	tower_menu.name = "TowerMenu"
	tower_menu.hide_on_checkable_item_selection = true
	tower_menu.add_item("Alcance +60", 1)
	tower_menu.add_item("Cadência +", 2)
	tower_menu.add_item("Direções 8", 3)
	tower_menu.id_pressed.connect(Callable(self, "_on_tower_menu_pressed"))
	$CanvasLayer.add_child(tower_menu)
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
	if tb.has_node("BtnBuyTower"):
		var btn: Button = tb.get_node("BtnBuyTower")
		btn.text = "Comprar Torre (%d)" % TOWER_COST
		btn.disabled = hero["coins"] < TOWER_COST and not placing_tower

	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not choosing_upgrade:
			var pos = event.position
			if placing_tower:
				_try_place_tower(pos)
			else:
				_try_shoot(Vector2(pos.x, pos.y))
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if not choosing_upgrade:
			var pos = event.position
			var idx := _find_tower_at(pos, 14.0)
			if idx != -1:
				_open_tower_menu(idx, pos)
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
	# base
	var bc = _tile_center(center.x, center.y)
	var base_px := BASE_SIZE_TILES * TILE_SIZE
	var base_rect := Rect2(bc.x - base_px/2, bc.y - base_px/2, base_px, base_px)
	draw_rect(base_rect, Color(0.2,0.24,0.28))
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
	# towers
	for t in towers:
		var r := Rect2(t.pos.x-6, t.pos.y-6, 12, 12)
		draw_rect(r, Color(0.7,0.7,0.8))
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
	var rings := 6
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

func _is_walkable(c: int, r: int) -> bool:
	return r >= 0 and r < GRID_ROWS and c >= 0 and c < GRID_COLS and grid[r][c] == 0

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
	tower_selected_index = idx
	var can_range: bool = hero["coins"] >= TOWER_RANGE_COST
	var can_rate: bool = hero["coins"] >= TOWER_RATE_COST and towers[idx].fire_rate > 0.12
	var can_dirs: bool = hero["coins"] >= TOWER_DIRS_COST and int(towers[idx].dirs) < 8
	tower_menu.set_item_text(0, "Alcance +60 (%d)" % TOWER_RANGE_COST)
	tower_menu.set_item_text(1, "Cadência + (%d)" % TOWER_RATE_COST)
	tower_menu.set_item_text(2, "Direções 8 (%d)" % TOWER_DIRS_COST)
	tower_menu.set_item_disabled(0, not can_range)
	tower_menu.set_item_disabled(1, not can_rate)
	tower_menu.set_item_disabled(2, not can_dirs)
	tower_menu.position = screen_pos
	tower_menu.popup()

func _on_tower_menu_pressed(id: int) -> void:
	if tower_selected_index < 0 or tower_selected_index >= towers.size():
		return
	var t = towers[tower_selected_index]
	match id:
		1:
			if hero["coins"] >= TOWER_RANGE_COST:
				t.range += 60.0
				t.levels["RANGE"] += 1
				hero["coins"] -= TOWER_RANGE_COST
		2:
			if hero["coins"] >= TOWER_RATE_COST and t.fire_rate > 0.12:
				t.fire_rate = max(0.1, t.fire_rate - 0.05)
				t.levels["RATE"] += 1
				hero["coins"] -= TOWER_RATE_COST
		3:
			if hero["coins"] >= TOWER_DIRS_COST and int(t.dirs) < 8:
				t.dirs = 8
				t.levels["DIRS"] += 1
				hero["coins"] -= TOWER_DIRS_COST
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

func _is_inside_base_point(p: Vector2) -> bool:
	var bc = _tile_center(center.x, center.y)
	var half := (BASE_SIZE_TILES * TILE_SIZE) / 2.0
	return abs(p.x - bc.x) <= half - 2 and abs(p.y - bc.y) <= half - 2

func _try_place_tower(pos: Vector2) -> void:
	if not _is_inside_base_point(pos):
		placing_tower = false
		return
	for t in towers:
		if t.pos.distance_to(pos) < 16.0:
			placing_tower = false
			return
	towers.append({
		"pos": pos,
		"cooldown": 0.0,
		"fire_rate": 0.5,
		"range": 260.0,
		"dirs": 4,
		"levels": { "RANGE": 0, "RATE": 0, "DIRS": 0 }
	})
	hero["coins"] -= TOWER_COST
	placing_tower = false

func _physics_process(delta: float) -> void:
	hero["cooldown"] = max(0.0, hero["cooldown"] - delta)
	# torres: 1 tiro por direção a cada 0.5s
	for t in towers:
		t.cooldown = max(0.0, t.cooldown - delta)
		if t.cooldown <= 0.0:
			_tower_fire_cross(t)
			t.cooldown = t.fire_rate

func _tower_fire_cross(tower: Dictionary) -> void:
	var speed := 260.0
	var dirs := [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1)]
	if int(tower.get("dirs", 4)) >= 8:
		dirs += [Vector2(1,1).normalized(), Vector2(1,-1).normalized(), Vector2(-1,1).normalized(), Vector2(-1,-1).normalized()]
	var life := float(tower.get("range", 260.0)) / speed
	for d in dirs:
		var b = { "pos": tower.pos, "vel": d * speed, "life": life, "radius": 2, "damage": 1, "pierce": 0 }
		tower_bullets.append(b)

func _on_game_over_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")

func _on_game_over_restart() -> void:
	get_tree().reload_current_scene()
