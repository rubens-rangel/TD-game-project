extends RefCounted
class_name SaveManager

const MAX_SLOTS = 10
const AUTO_SAVE_SLOT = "autosave"

const DEFAULT_TOWER_LEVELS = {"RANGE": 0, "RATE": 0, "DIRS": 0, "DMG": 0, "FREEZE": 0, "FIRE": 0}
const DEFAULT_SLOW_LEVELS = {"RANGE": 0, "AMOUNT": 0, "DURATION": 0, "RATE": 0}
const DEFAULT_AOE_LEVELS = {"DMG": 0, "RATE": 0, "AREA": 0}
const DEFAULT_SNIPER_LEVELS = {"DMG": 0, "RATE": 0}
const DEFAULT_BOOST_LEVELS = {"RANGE": 0, "DMG": 0, "RATE": 0}
const DEFAULT_SHOCK_LEVELS = {"DMG": 0, "RATE": 0, "CHAIN": 0}
const DEFAULT_BARRACKS_LEVELS = {"HOLD": 0, "DMG": 0, "SPAWN_RATE": 0, "PROJECTILE_SPEED": 0}

# Obter caminho do arquivo de save para um slot
static func get_slot_path(slot_name: String) -> String:
	return "user://save_slot_%s.json" % slot_name

# Salvar o estado completo do jogo em um slot específico
static func save_game(game_instance: Node2D, slot_name: String = "slot1") -> bool:
	var save_data = {}
	
	# Dados básicos do jogo
	save_data["base_hp"] = game_instance.base_hp
	save_data["coins"] = game_instance.hero["coins"]
	save_data["wave"] = game_instance.wave_manager.wave
	save_data["time_to_next_wave"] = game_instance.wave_manager.time_to_next_wave
	save_data["spawning"] = game_instance.wave_manager.spawning
	save_data["to_spawn"] = game_instance.wave_manager.to_spawn
	
	# Estado do herói
	save_data["hero"] = {
		"x": game_instance.hero["x"],
		"y": game_instance.hero["y"],
		"damage": game_instance.hero["damage"],
		"fire_rate": game_instance.hero["fire_rate"],
		"pierce": game_instance.hero["pierce"],
		"range": game_instance.hero["range"],
		"levels": game_instance.hero["levels"].duplicate()
	}
	save_data["hero_home"] = {
		"level": game_instance.hero_home_level,
		"coin_bonus": game_instance.hero_home_coin_bonus
	}
	
	# Torres
	save_data["towers"] = _serialize_towers(game_instance.towers)
	save_data["slow_towers"] = _serialize_slow_towers(game_instance.slow_towers)
	save_data["aoe_towers"] = _serialize_aoe_towers(game_instance.aoe_towers)
	save_data["sniper_towers"] = _serialize_sniper_towers(game_instance.sniper_towers)
	save_data["boost_towers"] = _serialize_boost_towers(game_instance.boost_towers)
	save_data["shock_towers"] = _serialize_shock_towers(game_instance.shock_towers)
	
	# Outras estruturas
	save_data["barracks"] = _serialize_barracks(game_instance.barracks)
	save_data["mines"] = _serialize_mines(game_instance.mines)
	save_data["walls"] = _serialize_walls(game_instance.walls)
	save_data["healing_stations"] = _serialize_healing_stations(game_instance.healing_stations)
	
	# Timestamp
	save_data["timestamp"] = Time.get_unix_time_from_system()
	save_data["save_time"] = Time.get_datetime_string_from_system()
	save_data["slot_name"] = slot_name
	save_data["is_autosave"] = (slot_name == AUTO_SAVE_SLOT)
	
	# Salvar arquivo
	var file_path = get_slot_path(slot_name)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		print("Erro ao salvar jogo: não foi possível criar arquivo em ", file_path)
		return false
	
	var json_string = JSON.stringify(save_data)
	file.store_string(json_string)
	file.close()
	
	print("Jogo salvo com sucesso no slot: ", slot_name)
	return true

# Auto-save (sempre salva no slot autosave)
static func auto_save(game_instance: Node2D) -> bool:
	return save_game(game_instance, AUTO_SAVE_SLOT)

# Carregar jogo de um slot específico
static func load_game(game_instance: Node2D, slot_name: String = "slot1") -> bool:
	var file_path = get_slot_path(slot_name)
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("Nenhum save encontrado no slot: ", slot_name)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		print("Erro ao parsear JSON do save: ", error)
		return false
	
	var save_data = json.data
	return _apply_save_data(game_instance, save_data)

# Carregar auto-save (conveniência)
static func load_autosave(game_instance: Node2D) -> bool:
	return load_game(game_instance, AUTO_SAVE_SLOT)

# Verificar se existe save em um slot
static func has_save(slot_name: String = "slot1") -> bool:
	return FileAccess.file_exists(get_slot_path(slot_name))

# Verificar se existe auto-save
static func has_autosave() -> bool:
	return has_save(AUTO_SAVE_SLOT)

# Obter informações do save de um slot (sem carregar)
static func get_save_info(slot_name: String = "slot1") -> Dictionary:
	if not has_save(slot_name):
		return {}
	
	var file_path = get_slot_path(slot_name)
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		return {}
	
	var save_data = json.data
	return {
		"slot_name": slot_name,
		"wave": save_data.get("wave", 0),
		"coins": save_data.get("coins", 0),
		"base_hp": save_data.get("base_hp", 100),
		"timestamp": save_data.get("timestamp", 0),
		"save_time": save_data.get("save_time", "Desconhecido"),
		"is_autosave": save_data.get("is_autosave", false)
	}

# Listar todos os slots disponíveis
static func list_available_slots() -> Array:
	var slots = []
	
	# Verificar slot de autosave
	if has_autosave():
		var info = get_save_info(AUTO_SAVE_SLOT)
		info["slot_name"] = AUTO_SAVE_SLOT
		slots.append(info)
	
	# Verificar slots numerados (1 a MAX_SLOTS)
	for i in range(1, MAX_SLOTS + 1):
		var slot_name = "slot%d" % i
		if has_save(slot_name):
			var info = get_save_info(slot_name)
			info["slot_name"] = slot_name
			slots.append(info)
	
	# Ordenar por timestamp (mais recente primeiro)
	slots.sort_custom(func(a, b): return a.get("timestamp", 0) > b.get("timestamp", 0))
	
	return slots

# Deletar um slot
static func delete_slot(slot_name: String) -> bool:
	var file_path = get_slot_path(slot_name)
	if not FileAccess.file_exists(file_path):
		return false
	
	DirAccess.remove_absolute(file_path)
	print("Slot deletado: ", slot_name)
	return true

# Aplicar dados do save no jogo
static func _apply_save_data(game_instance: Node2D, save_data: Dictionary) -> bool:
	# Dados básicos
	game_instance.base_hp = save_data.get("base_hp", 100)
	game_instance.hero["coins"] = save_data.get("coins", 0)
	
	# Wave manager
	var wave = save_data.get("wave", 1)
	game_instance.wave_manager.jump_to_wave(wave)
	game_instance.wave_manager.time_to_next_wave = save_data.get("time_to_next_wave", 10.0)
	game_instance.wave_manager.spawning = save_data.get("spawning", false)
	game_instance.wave_manager.to_spawn = save_data.get("to_spawn", 0)
	
	# Herói
	var hero_data = save_data.get("hero", {})
	game_instance.hero["x"] = hero_data.get("x", 0.0)
	game_instance.hero["y"] = hero_data.get("y", 0.0)
	game_instance.hero["damage"] = hero_data.get("damage", 0.5)
	game_instance.hero["fire_rate"] = hero_data.get("fire_rate", 0.5)
	game_instance.hero["pierce"] = hero_data.get("pierce", 0)
	game_instance.hero["range"] = hero_data.get("range", 9999.0)
	game_instance.hero["levels"] = hero_data.get("levels", {"DMG": 0, "FIRERATE": 0, "PIERCE": 0})
	var hero_home_data = save_data.get("hero_home", {})
	game_instance.hero_home_level = hero_home_data.get("level", 1)
	game_instance.hero_home_coin_bonus = hero_home_data.get("coin_bonus", 0.0)
	game_instance._apply_hero_home_coin_bonus_from_scratch()
	
	# Limpar estruturas existentes
	game_instance.towers.clear()
	game_instance.slow_towers.clear()
	game_instance.aoe_towers.clear()
	game_instance.sniper_towers.clear()
	game_instance.boost_towers.clear()
	game_instance.shock_towers.clear()
	game_instance.barracks.clear()
	game_instance.mines.clear()
	game_instance.walls.clear()
	game_instance.healing_stations.clear()
	
	# Carregar estruturas
	game_instance.towers = _deserialize_towers(save_data.get("towers", []))
	game_instance.slow_towers = _deserialize_slow_towers(save_data.get("slow_towers", []))
	game_instance.aoe_towers = _deserialize_aoe_towers(save_data.get("aoe_towers", []))
	game_instance.sniper_towers = _deserialize_sniper_towers(save_data.get("sniper_towers", []))
	game_instance.boost_towers = _deserialize_boost_towers(save_data.get("boost_towers", []))
	game_instance.shock_towers = _deserialize_shock_towers(save_data.get("shock_towers", []))
	game_instance.barracks = _deserialize_barracks(save_data.get("barracks", []))
	game_instance.mines = _deserialize_mines(save_data.get("mines", []))
	game_instance.walls = _deserialize_walls(save_data.get("walls", []))
	game_instance.healing_stations = _deserialize_healing_stations(save_data.get("healing_stations", []))
	
	# Limpar inimigos e projéteis (não salvamos eles)
	game_instance.enemies.clear()
	game_instance.tower_bullets.clear()
	game_instance.arrows.clear()
	
	print("Jogo carregado com sucesso! Wave: ", wave)
	return true

# Funções de serialização para cada tipo de estrutura
static func _serialize_towers(towers: Array) -> Array:
	var result = []
	for t in towers:
		result.append({
			"grid_x": t.grid_x,
			"grid_y": t.grid_y,
			"pos_x": t.pos.x,
			"pos_y": t.pos.y,
			"damage": t.damage,
			"fire_rate": t.fire_rate,
			"range": t.range,
			"cooldown": t.cooldown,
			"dirs": _serialize_vector2_array(t.get("dirs", [Vector2(1, 0)])),
			"has_freeze": t.get("has_freeze", false),
			"has_fire": t.get("has_fire", false),
			"levels": t.get("levels", DEFAULT_TOWER_LEVELS).duplicate()
		})
	return result

static func _deserialize_towers(data: Array) -> Array:
	var result = []
	for t in data:
		var tower = {
			"grid_x": t.grid_x,
			"grid_y": t.grid_y,
			"pos": Vector2(t.pos_x, t.pos_y),
			"damage": t.damage,
			"fire_rate": t.fire_rate,
			"range": t.range,
			"cooldown": t.cooldown,
			"dirs": _deserialize_vector2_array(t.get("dirs", [])),
			"has_freeze": t.get("has_freeze", false),
			"has_fire": t.get("has_fire", false),
			"levels": _merge_levels(t.get("levels", {}), DEFAULT_TOWER_LEVELS)
		}
		result.append(tower)
	return result

static func _serialize_slow_towers(towers: Array) -> Array:
	var result = []
	for t in towers:
		result.append({
			"grid_x": t.grid_x,
			"grid_y": t.grid_y,
			"pos_x": t.pos.x,
			"pos_y": t.pos.y,
			"range": t.range,
			"slow_amount": t.slow_amount,
			"cooldown": t.cooldown,
			"fire_rate": t.fire_rate,
			"levels": t.get("levels", DEFAULT_SLOW_LEVELS).duplicate()
		})
	return result

static func _deserialize_slow_towers(data: Array) -> Array:
	var result = []
	for t in data:
		result.append({
			"grid_x": t.grid_x,
			"grid_y": t.grid_y,
			"pos": Vector2(t.pos_x, t.pos_y),
			"range": t.range,
			"slow_amount": t.slow_amount,
			"cooldown": t.cooldown,
			"fire_rate": t.fire_rate,
			"levels": _merge_levels(t.get("levels", {}), DEFAULT_SLOW_LEVELS)
		})
	return result

static func _serialize_aoe_towers(towers: Array) -> Array:
	var result = []
	for t in towers:
		result.append({
			"grid_x": t.grid_x,
			"grid_y": t.grid_y,
			"pos_x": t.pos.x,
			"pos_y": t.pos.y,
			"range": t.range,
			"damage": t.damage,
			"aoe_radius": t.aoe_radius,
			"cooldown": t.cooldown,
			"fire_rate": t.fire_rate,
			"levels": t.get("levels", DEFAULT_AOE_LEVELS).duplicate()
		})
	return result

static func _deserialize_aoe_towers(data: Array) -> Array:
	var result = []
	for t in data:
		result.append({
			"grid_x": t.grid_x,
			"grid_y": t.grid_y,
			"pos": Vector2(t.pos_x, t.pos_y),
			"range": t.range,
			"damage": t.damage,
			"aoe_radius": t.aoe_radius,
			"cooldown": t.cooldown,
			"fire_rate": t.fire_rate,
			"levels": _merge_levels(t.get("levels", {}), DEFAULT_AOE_LEVELS)
		})
	return result

static func _serialize_sniper_towers(towers: Array) -> Array:
	var result = []
	for t in towers:
		result.append({
			"grid_x": t.grid_x,
			"grid_y": t.grid_y,
			"pos_x": t.pos.x,
			"pos_y": t.pos.y,
			"range": t.range,
			"damage": t.damage,
			"cooldown": t.cooldown,
			"fire_rate": t.fire_rate,
			"pierce": t.pierce,
			"levels": t.get("levels", DEFAULT_SNIPER_LEVELS).duplicate()
		})
	return result

static func _deserialize_sniper_towers(data: Array) -> Array:
	var result = []
	for t in data:
		result.append({
			"grid_x": t.grid_x,
			"grid_y": t.grid_y,
			"pos": Vector2(t.pos_x, t.pos_y),
			"range": t.range,
			"damage": t.damage,
			"cooldown": t.cooldown,
			"fire_rate": t.fire_rate,
			"pierce": t.pierce,
			"levels": _merge_levels(t.get("levels", {}), DEFAULT_SNIPER_LEVELS)
		})
	return result

static func _serialize_boost_towers(towers: Array) -> Array:
	var result = []
	for t in towers:
		result.append({
			"grid_x": t.grid_x,
			"grid_y": t.grid_y,
			"pos_x": t.pos.x,
			"pos_y": t.pos.y,
			"range": t.range,
			"damage_boost": t.damage_boost,
			"rate_boost": t.rate_boost,
			"levels": _merge_levels(t.get("levels", {}), DEFAULT_BOOST_LEVELS)
		})
	return result

static func _deserialize_boost_towers(data: Array) -> Array:
	var result = []
	for t in data:
		result.append({
			"grid_x": t.grid_x,
			"grid_y": t.grid_y,
			"pos": Vector2(t.pos_x, t.pos_y),
			"range": t.range,
			"damage_boost": t.damage_boost,
			"rate_boost": t.rate_boost,
			"levels": _merge_levels(t.get("levels", {}), DEFAULT_BOOST_LEVELS)
		})
	return result

static func _serialize_shock_towers(towers: Array) -> Array:
	var result = []
	for t in towers:
		result.append({
			"grid_x": t.grid_x,
			"grid_y": t.grid_y,
			"pos_x": t.pos.x,
			"pos_y": t.pos.y,
			"range": t.range,
			"damage": t.damage,
			"chain_count": t.chain_count,
			"cooldown": t.cooldown,
			"fire_rate": t.fire_rate,
			"levels": _merge_levels(t.get("levels", {}), DEFAULT_SHOCK_LEVELS)
		})
	return result

static func _deserialize_shock_towers(data: Array) -> Array:
	var result = []
	for t in data:
		result.append({
			"grid_x": t.grid_x,
			"grid_y": t.grid_y,
			"pos": Vector2(t.pos_x, t.pos_y),
			"range": t.range,
			"damage": t.damage,
			"chain_count": t.chain_count,
			"cooldown": t.cooldown,
			"fire_rate": t.fire_rate,
			"levels": t.get("levels", {}).duplicate()
		})
	return result

static func _serialize_barracks(barracks: Array) -> Array:
	var result = []
	for b in barracks:
		result.append({
			"grid_x": b.grid_x,
			"grid_y": b.grid_y,
			"pos_x": b.pos.x,
			"pos_y": b.pos.y,
			"soldier_spawn_cd": b.soldier_spawn_cd,
			"soldier_spawn_rate": b.get("soldier_spawn_rate", 3.0),
			"damage": b.get("damage", b.get("soldier_damage", 0.5)),
			"hold_time": b.get("hold_time", b.get("soldier_hold_time", 1.0)),
			"projectile_speed": b.get("projectile_speed", 200.0),
			"levels": b.get("levels", DEFAULT_BARRACKS_LEVELS).duplicate()
		})
	return result

static func _deserialize_barracks(data: Array) -> Array:
	var result = []
	for b in data:
		var barracks_data = {
			"grid_x": b.grid_x,
			"grid_y": b.grid_y,
			"pos": Vector2(b.pos_x, b.pos_y),
			"soldier_spawn_cd": b.soldier_spawn_cd,
			"soldiers": [],
			"soldier_spawn_rate": b.get("soldier_spawn_rate", 3.0),
			"damage": b.get("damage", b.get("soldier_damage", 0.5)),
			"hold_time": b.get("hold_time", b.get("soldier_hold_time", 1.0)),
			"projectile_speed": b.get("projectile_speed", 200.0),
			"levels": _merge_levels(b.get("levels", {}), DEFAULT_BARRACKS_LEVELS)
		}
		result.append(barracks_data)
	return result

static func _serialize_mines(mines: Array) -> Array:
	var result = []
	for m in mines:
		result.append({
			"grid_x": m.grid_x,
			"grid_y": m.grid_y,
			"pos_x": m.pos.x,
			"pos_y": m.pos.y,
			"damage": m.damage,
			"triggered": m.triggered
		})
	return result

static func _deserialize_mines(data: Array) -> Array:
	var result = []
	for m in data:
		result.append({
			"grid_x": m.grid_x,
			"grid_y": m.grid_y,
			"pos": Vector2(m.pos_x, m.pos_y),
			"damage": m.damage,
			"triggered": m.triggered
		})
	return result

static func _serialize_walls(walls: Array) -> Array:
	var result = []
	for w in walls:
		result.append({
			"grid_x": w.grid_x,
			"grid_y": w.grid_y,
			"pos_x": w.pos.x,
			"pos_y": w.pos.y,
			"hp": w.hp,
			"max_hp": w.max_hp
		})
	return result

static func _deserialize_walls(data: Array) -> Array:
	var result = []
	for w in data:
		result.append({
			"grid_x": w.grid_x,
			"grid_y": w.grid_y,
			"pos": Vector2(w.pos_x, w.pos_y),
			"hp": w.hp,
			"max_hp": w.max_hp
		})
	return result

static func _serialize_healing_stations(stations: Array) -> Array:
	var result = []
	for s in stations:
		result.append({
			"grid_x": s.grid_x,
			"grid_y": s.grid_y,
			"pos_x": s.pos.x,
			"pos_y": s.pos.y,
			"heal_rate": s.heal_rate,
			"range": s.range
		})
	return result

static func _deserialize_healing_stations(data: Array) -> Array:
	var result = []
	for s in data:
		result.append({
			"grid_x": s.grid_x,
			"grid_y": s.grid_y,
			"pos": Vector2(s.pos_x, s.pos_y),
			"heal_rate": s.heal_rate,
			"range": s.range
		})
	return result

static func _serialize_vector2_array(vectors: Array) -> Array:
	var result = []
	for v in vectors:
		result.append({"x": v.x, "y": v.y})
	return result

static func _deserialize_vector2_array(data: Array) -> Array:
	var result = []
	for v in data:
		result.append(Vector2(v.x, v.y))
	return result

static func _merge_levels(source: Dictionary, defaults: Dictionary) -> Dictionary:
	var result = defaults.duplicate()
	for key in source.keys():
		result[key] = source[key]
	return result


