extends RefCounted
class_name StructureManager

const GameConstants = preload("res://scripts/Constants.gd")

var barracks: Array = []
var mines: Array = []
var walls: Array = []
var healing_stations: Array = []
var soldiers: Array = []

signal mine_triggered(mine_pos: Vector2, damage: float)
signal wall_destroyed(wall_pos: Vector2)

func create_barracks(pos: Vector2, grid_x: int, grid_y: int) -> Dictionary:
	var barracks_data = {
		"pos": pos,
		"grid_x": grid_x,
		"grid_y": grid_y,
		"soldier_spawn_cd": 3.0,
		"soldier_spawn_rate": 3.0,
		"soldiers": [],
		"hold_time": GameConstants.BARRACKS_INITIAL_HOLD_TIME,
		"damage": GameConstants.BARRACKS_INITIAL_SOLDIER_DAMAGE,
		"projectile_speed": 80.0,
		"levels": {"HOLD": 0, "DMG": 0, "SPAWN_RATE": 0, "PROJECTILE_SPEED": 0}
	}
	barracks.append(barracks_data)
	return barracks_data

func create_mine(pos: Vector2, grid_x: int, grid_y: int) -> Dictionary:
	var mine = {
		"pos": pos,
		"grid_x": grid_x,
		"grid_y": grid_y,
		"damage": 5.0,
		"triggered": false
	}
	mines.append(mine)
	return mine

func create_wall(pos: Vector2, grid_x: int, grid_y: int) -> Dictionary:
	var wall = {
		"pos": pos,
		"grid_x": grid_x,
		"grid_y": grid_y,
		"hp": 20.0,
		"max_hp": 20.0
	}
	walls.append(wall)
	return wall

func create_healing_station(pos: Vector2, grid_x: int, grid_y: int) -> Dictionary:
	var station = {
		"pos": pos,
		"grid_x": grid_x,
		"grid_y": grid_y,
		"heal_amount": 5.0,
		"range": 100.0
	}
	healing_stations.append(station)
	return station

func update_structures(delta: float, enemies: Array, grid_manager: GridManager, pathfinder: Pathfinder) -> void:
	_update_barracks(delta, enemies)
	_update_mines(delta, enemies, grid_manager)
	_update_walls(delta, enemies, grid_manager, pathfinder)
	_update_soldiers(delta, enemies)

func _update_barracks(delta: float, enemies: Array) -> void:
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
				"holding": false
			}
			b.soldiers.append(soldier)
			soldiers.append(soldier)
			b.soldier_spawn_cd = b.soldier_spawn_rate

func _update_mines(delta: float, enemies: Array, grid_manager: GridManager) -> void:
	var mines_to_remove: Array = []
	for i in range(mines.size()):
		var m = mines[i]
		if m.triggered:
			mines_to_remove.append(i)
			continue
		
		for enemy in enemies:
			if enemy["hp"] <= 0 or enemy["reached"]:
				continue
			var dist = m.pos.distance_to(enemy["pos"])
			if dist < 15.0:
				enemy["hp"] -= m.damage
				m.triggered = true
				mine_triggered.emit(m.pos, m.damage)
				mines_to_remove.append(i)
				grid_manager.clear_grid_area(m.grid_x, m.grid_y, GameConstants.MINE_SIZE_GRID)
				break
	
	mines_to_remove.reverse()
	for idx in mines_to_remove:
		if idx < mines.size():
			mines.remove_at(idx)

func _update_walls(delta: float, enemies: Array, grid_manager: GridManager, pathfinder: Pathfinder) -> void:
	var walls_to_remove: Array = []
	for i in range(walls.size()):
		var w = walls[i]
		if w.hp <= 0:
			walls_to_remove.append(i)
			continue
		
		for enemy in enemies:
			if enemy["hp"] <= 0 or enemy["reached"]:
				continue
			var dist = w.pos.distance_to(enemy["pos"])
			if dist < 20.0:
				w.hp -= 0.5 * delta
				if w.hp <= 0:
					grid_manager.clear_grid_area(w.grid_x, w.grid_y, GameConstants.WALL_SIZE_GRID)
					pathfinder.invalidate_cache()
					wall_destroyed.emit(w.pos)
					walls_to_remove.append(i)
					break
	
	walls_to_remove.reverse()
	for idx in walls_to_remove:
		if idx < walls.size():
			walls.remove_at(idx)

func _update_soldiers(delta: float, enemies: Array) -> void:
	var alive_soldiers: Array = []
	for s in soldiers:
		if s.hp <= 0:
			continue
		
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
			target_enemy["hp"] -= s.damage * delta
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

func get_barracks() -> Array:
	return barracks

func get_mines() -> Array:
	return mines

func get_walls() -> Array:
	return walls

func get_healing_stations() -> Array:
	return healing_stations

func get_soldiers() -> Array:
	return soldiers

func apply_healing(base_center: Vector2) -> float:
	var total_heal = 0.0
	for hs in healing_stations:
		var dist_to_base = hs.pos.distance_to(base_center)
		if dist_to_base <= hs.range:
			total_heal += hs.heal_amount
	return total_heal


