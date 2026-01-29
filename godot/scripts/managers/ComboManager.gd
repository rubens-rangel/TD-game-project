extends RefCounted
class_name ComboManager

# Sistema de Combos e Sinergias entre torres
# Detecta combinações específicas de torres e aplica bônus

# Tipos de combos disponíveis
enum ComboType {
	CERCA_ELETRICA,      # 2+ Shock Towers próximas
	CAMPO_DE_BATALHA,    # Slow Tower + AOE Tower próximas
	SNIPER_SPOTTER,      # Sniper Tower + Boost Tower
	MURALHA_DE_FOGO,     # 3+ Muralhas em linha + AOE Tower
	QUARTEL_FORTIFICADO  # Barracks + Healing Station próximos
}

# Estrutura de um combo ativo
# {type: ComboType, towers: Array, bonus: float, visual_effect: bool}
var active_combos: Array = []

# Distância máxima para considerar torres "próximas" (em pixels)
const COMBO_DETECTION_RANGE := 150.0

# Bônus de cada combo
const COMBO_BONUSES = {
	ComboType.CERCA_ELETRICA: 0.30,      # +30% dano
	ComboType.CAMPO_DE_BATALHA: 0.50,    # +50% dano AOE em inimigos lentos
	ComboType.SNIPER_SPOTTER: 1.0,       # +100% alcance, +25% dano crítico
	ComboType.MURALHA_DE_FOGO: 0.0,      # Explosão ao destruir muralha
	ComboType.QUARTEL_FORTIFICADO: 0.20  # +20% dano soldados, regeneração
}

func _init():
	pass

func check_tower_combos(towers: Array, slow_towers: Array, aoe_towers: Array, 
						sniper_towers: Array, shock_towers: Array, boost_towers: Array,
						anti_air_towers: Array, barracks: Array, healing_stations: Array, walls: Array) -> void:
	"""Verifica e atualiza todos os combos ativos baseado nas torres atuais"""
	active_combos.clear()
	
	# 1. Combo "Cerca Elétrica" - 2+ Shock Towers próximas
	_check_shock_tower_combo(shock_towers)
	
	# 2. Combo "Campo de Batalha" - Slow Tower + AOE Tower próximas
	_check_slow_aoe_combo(slow_towers, aoe_towers)
	
	# 3. Combo "Sniper Spotter" - Sniper Tower + Boost Tower
	_check_sniper_boost_combo(sniper_towers, boost_towers)
	
	# 4. Combo "Muralha de Fogo" - 3+ Muralhas em linha + AOE Tower
	_check_wall_fire_combo(walls, aoe_towers)
	
	# 5. Combo "Quartel Fortificado" - Barracks + Healing Station próximos
	_check_barracks_healing_combo(barracks, healing_stations)

func _check_shock_tower_combo(shock_towers: Array) -> void:
	"""Verifica combo de Cerca Elétrica"""
	if shock_towers.size() < 2:
		return
	
	# Verificar todas as combinações de 2+ torres próximas
	for i in range(shock_towers.size()):
		var tower1 = shock_towers[i]
		var nearby_shocks = []
		
		for j in range(shock_towers.size()):
			if i == j:
				continue
			var tower2 = shock_towers[j]
			var distance = tower1.pos.distance_to(tower2.pos)
			
			# Verificar se os alcances se sobrepõem
			var combined_range = tower1.range + tower2.range
			if distance < combined_range:
				if nearby_shocks.is_empty():
					nearby_shocks.append(tower1)
				if not nearby_shocks.has(tower2):
					nearby_shocks.append(tower2)
		
		# Se encontrou 2+ torres próximas, criar combo
		if nearby_shocks.size() >= 2:
			active_combos.append({
				"type": ComboType.CERCA_ELETRICA,
				"towers": nearby_shocks,
				"bonus": COMBO_BONUSES[ComboType.CERCA_ELETRICA],
				"visual_effect": true
			})
			break  # Apenas um combo deste tipo

func _check_slow_aoe_combo(slow_towers: Array, aoe_towers: Array) -> void:
	"""Verifica combo de Campo de Batalha"""
	for slow_tower in slow_towers:
		for aoe_tower in aoe_towers:
			var distance = slow_tower.pos.distance_to(aoe_tower.pos)
			if distance < COMBO_DETECTION_RANGE:
				active_combos.append({
					"type": ComboType.CAMPO_DE_BATALHA,
					"towers": [slow_tower, aoe_tower],
					"bonus": COMBO_BONUSES[ComboType.CAMPO_DE_BATALHA],
					"visual_effect": true
				})
				return  # Apenas um combo deste tipo

func _check_sniper_boost_combo(sniper_towers: Array, boost_towers: Array) -> void:
	"""Verifica combo de Sniper Spotter"""
	for sniper_tower in sniper_towers:
		for boost_tower in boost_towers:
			var distance = sniper_tower.pos.distance_to(boost_tower.pos)
			# Verificar se sniper está dentro do alcance do boost tower
			if distance < boost_tower.range:
				active_combos.append({
					"type": ComboType.SNIPER_SPOTTER,
					"towers": [sniper_tower, boost_tower],
					"bonus": COMBO_BONUSES[ComboType.SNIPER_SPOTTER],
					"visual_effect": true
				})
				return  # Apenas um combo deste tipo

func _check_wall_fire_combo(walls: Array, aoe_towers: Array) -> void:
	"""Verifica combo de Muralha de Fogo"""
	if walls.size() < 3:
		return
	
	# Verificar se há 3+ muralhas em linha
	# Simplificado: verificar se há muralhas próximas em linha horizontal ou vertical
	for aoe_tower in aoe_towers:
		var nearby_walls = []
		for wall in walls:
			var distance = aoe_tower.pos.distance_to(wall.pos)
			if distance < COMBO_DETECTION_RANGE * 1.5:
				nearby_walls.append(wall)
		
		if nearby_walls.size() >= 3:
			active_combos.append({
				"type": ComboType.MURALHA_DE_FOGO,
				"towers": [aoe_tower] + nearby_walls,
				"bonus": COMBO_BONUSES[ComboType.MURALHA_DE_FOGO],
				"visual_effect": true
			})
			return  # Apenas um combo deste tipo

func _check_barracks_healing_combo(barracks: Array, healing_stations: Array) -> void:
	"""Verifica combo de Quartel Fortificado"""
	for barrack in barracks:
		for healing_station in healing_stations:
			var distance = barrack.pos.distance_to(healing_station.pos)
			if distance < COMBO_DETECTION_RANGE:
				active_combos.append({
					"type": ComboType.QUARTEL_FORTIFICADO,
					"towers": [barrack, healing_station],
					"bonus": COMBO_BONUSES[ComboType.QUARTEL_FORTIFICADO],
					"visual_effect": true
				})
				return  # Apenas um combo deste tipo

func get_combo_bonus_for_tower(tower_pos: Vector2, tower_type: String) -> Dictionary:
	"""Retorna bônus de combo aplicável a uma torre específica"""
	var bonus = {
		"damage_multiplier": 1.0,
		"range_multiplier": 1.0,
		"crit_bonus": 0.0,
		"special_effect": ""
	}
	
	for combo in active_combos:
		match combo.type:
			ComboType.CERCA_ELETRICA:
				# Verificar se esta torre está no combo
				for tower in combo.towers:
					if tower.pos.distance_to(tower_pos) < 10.0:  # Mesma torre
						bonus.damage_multiplier += combo.bonus
						break
			
			ComboType.CAMPO_DE_BATALHA:
				# AOE towers ganham bônus contra inimigos lentos
				if tower_type == "aoe_tower":
					for tower in combo.towers:
						if tower.pos.distance_to(tower_pos) < 10.0:
							bonus.special_effect = "slow_bonus"
							bonus.damage_multiplier += combo.bonus
							break
			
			ComboType.SNIPER_SPOTTER:
				# Sniper ganha alcance e crítico
				if tower_type == "sniper_tower":
					for tower in combo.towers:
						if tower.pos.distance_to(tower_pos) < 10.0:
							bonus.range_multiplier += combo.bonus  # +100% alcance
							bonus.crit_bonus += 0.25  # +25% crítico
							break
			
			ComboType.QUARTEL_FORTIFICADO:
				# Soldados ganham dano e regeneração
				if tower_type == "barracks":
					for tower in combo.towers:
						if tower.pos.distance_to(tower_pos) < 10.0:
							bonus.damage_multiplier += combo.bonus
							bonus.special_effect = "regen"
							break
	
	return bonus

func get_active_combos() -> Array:
	"""Retorna lista de combos ativos"""
	return active_combos.duplicate()

func get_combo_name(type: ComboType) -> String:
	"""Retorna nome do combo"""
	match type:
		ComboType.CERCA_ELETRICA:
			return "Cerca Elétrica"
		ComboType.CAMPO_DE_BATALHA:
			return "Campo de Batalha"
		ComboType.SNIPER_SPOTTER:
			return "Sniper Spotter"
		ComboType.MURALHA_DE_FOGO:
			return "Muralha de Fogo"
		ComboType.QUARTEL_FORTIFICADO:
			return "Quartel Fortificado"
		_:
			return "Combo Desconhecido"
