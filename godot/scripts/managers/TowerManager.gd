extends RefCounted
class_name TowerManager

const GameConstants = preload("res://scripts/Constants.gd")

var towers: Array = []
var slow_towers: Array = []
var aoe_towers: Array = []
var sniper_towers: Array = []
var boost_towers: Array = []

signal tower_fired(tower_data: Dictionary, projectile: Dictionary)

func create_tower(pos: Vector2, grid_x: int, grid_y: int, dir_vec: Vector2) -> Dictionary:
	var tower = {
		"pos": pos,
		"grid_x": grid_x,
		"grid_y": grid_y,
		"cooldown": 0.0,
		"fire_rate": 1.5,
		"range": 260.0,
		"dirs": [dir_vec],
		"damage": 0.5,
		"levels": {"RANGE": 0, "RATE": 0, "DIRS": 0, "DMG": 0}
	}
	towers.append(tower)
	return tower

func create_slow_tower(pos: Vector2, grid_x: int, grid_y: int) -> Dictionary:
	var tower = {
		"pos": pos,
		"grid_x": grid_x,
		"grid_y": grid_y,
		"range": 200.0,
		"slow_amount": 0.2,  # Valor inicial 20% (pode aumentar até 40% com upgrades)
		"cooldown": 0.0,
		"fire_rate": 0.5
	}
	slow_towers.append(tower)
	return tower

func create_aoe_tower(pos: Vector2, grid_x: int, grid_y: int) -> Dictionary:
	var tower = {
		"pos": pos,
		"grid_x": grid_x,
		"grid_y": grid_y,
		"range": 180.0,
		"damage": 2.0,
		"aoe_radius": 60.0,
		"cooldown": 0.0,
		"fire_rate": 2.0,
		"levels": {"DMG": 0, "RATE": 0, "AREA": 0}
	}
	aoe_towers.append(tower)
	return tower

func create_sniper_tower(pos: Vector2, grid_x: int, grid_y: int) -> Dictionary:
	var tower = {
		"pos": pos,
		"grid_x": grid_x,
		"grid_y": grid_y,
		"range": 400.0,
		"damage": 5.0,
		"cooldown": 0.0,
		"fire_rate": 5.0,
		"pierce": 1,
		"levels": {"DMG": 0, "RATE": 0}
	}
	sniper_towers.append(tower)
	return tower

func create_boost_tower(pos: Vector2, grid_x: int, grid_y: int) -> Dictionary:
	var tower = {
		"pos": pos,
		"grid_x": grid_x,
		"grid_y": grid_y,
		"range": 150.0,
		"damage_boost": 0.5,
		"rate_boost": 0.3
	}
	boost_towers.append(tower)
	return tower

func update_towers(delta: float, enemies: Array, boost_towers_list: Array) -> void:
	_update_normal_towers(delta, boost_towers_list)
	_update_slow_towers(delta, enemies)
	_update_aoe_towers(delta, enemies)
	_update_sniper_towers(delta, enemies)

func _update_normal_towers(delta: float, boost_towers_list: Array) -> void:
	for tower in towers:
		var rate_multiplier = 1.0
		for boost in boost_towers_list:
			var dist = tower.pos.distance_to(boost.pos)
			if dist <= boost.range:
				rate_multiplier += boost.rate_boost
		
		var effective_fire_rate = tower.fire_rate / rate_multiplier
		tower.cooldown = max(0.0, tower.cooldown - delta)
		if tower.cooldown <= 0.0:
			_fire_tower(tower, boost_towers_list)
			tower.cooldown = effective_fire_rate

func _update_slow_towers(delta: float, enemies: Array) -> void:
	for st in slow_towers:
		st.cooldown = max(0.0, st.cooldown - delta)
		if st.cooldown <= 0.0:
			for enemy in enemies:
				if enemy["hp"] <= 0 or enemy["reached"]:
					continue
				var dist = st.pos.distance_to(enemy["pos"])
				if dist <= st.range:
					# Aplicar slow será feito pelo EnemyManager
					pass
			st.cooldown = st.fire_rate

func _update_aoe_towers(delta: float, enemies: Array) -> void:
	for aoe in aoe_towers:
		aoe.cooldown = max(0.0, aoe.cooldown - delta)
		if aoe.cooldown <= 0.0:
			var closest_enemy = null
			var closest_dist = aoe.range + 1.0
			for enemy in enemies:
				if enemy["hp"] <= 0 or enemy["reached"]:
					continue
				var dist = aoe.pos.distance_to(enemy["pos"])
				if dist <= aoe.range and dist < closest_dist:
					closest_dist = dist
					closest_enemy = enemy
			
			if closest_enemy != null:
				var cannon_speed = 200.0
				var projectile = {
					"pos": aoe.pos,
					"target": closest_enemy["pos"],
					"speed": cannon_speed,
					"radius": aoe.aoe_radius,
					"damage": aoe.damage
				}
				tower_fired.emit({"type": "aoe_cannon"}, projectile)
				aoe.cooldown = aoe.fire_rate

func _update_sniper_towers(delta: float, enemies: Array) -> void:
	for sniper in sniper_towers:
		sniper.cooldown = max(0.0, sniper.cooldown - delta)
		if sniper.cooldown <= 0.0:
			var target_enemy = null
			var target_dist = -1.0
			for enemy in enemies:
				if enemy["hp"] <= 0 or enemy["reached"]:
					continue
				var dist = sniper.pos.distance_to(enemy["pos"])
				if dist <= sniper.range and dist > target_dist:
					target_enemy = enemy
					target_dist = dist
			
			if target_enemy != null:
				var effect = {
					"start": sniper.pos,
					"end": target_enemy["pos"],
					"damage": sniper.damage,
					"pierce": sniper.pierce
				}
				tower_fired.emit({"type": "sniper"}, effect)
				sniper.cooldown = sniper.fire_rate

func _fire_tower(tower: Dictionary, boost_towers_list: Array) -> void:
	var speed = 260.0
	var dirs = tower.get("dirs", [Vector2(1, 0)])
	var tower_damage = tower.get("damage", 0.5)
	var has_freeze = tower.get("has_freeze", false)
	var has_fire = tower.get("has_fire", false)
	
	var damage_multiplier = 1.0
	for boost in boost_towers_list:
		var dist = tower.pos.distance_to(boost.pos)
		if dist <= boost.range:
			damage_multiplier += boost.damage_boost
	
	tower_damage *= damage_multiplier
	var life = float(tower.get("range", 260.0)) / speed
	
	for d in dirs:
		var projectile = {
			"pos": tower.pos,
			"vel": d * speed,
			"life": life,
			"radius": 2,
			"damage": tower_damage,
			"pierce": 0,
			"has_freeze": has_freeze,
			"has_fire": has_fire
		}
		tower_fired.emit({"type": "tower"}, projectile)

func get_towers() -> Array:
	return towers

func get_slow_towers() -> Array:
	return slow_towers

func get_aoe_towers() -> Array:
	return aoe_towers

func get_sniper_towers() -> Array:
	return sniper_towers

func get_boost_towers() -> Array:
	return boost_towers


