extends RefCounted
class_name CombatManager

var enemy_manager: EnemyManager
var hero: Dictionary

signal enemy_killed(enemy_pos: Vector2, is_boss: bool)

func _init(p_enemy_manager: EnemyManager, p_hero: Dictionary):
	enemy_manager = p_enemy_manager
	hero = p_hero

func check_projectile_collisions(projectiles: Array, projectile_type: String = "arrow") -> Array:
	var new_projectiles: Array = []
	var enemies = enemy_manager.enemies
	
	for proj in projectiles:
		if proj.get("life", 0.0) <= 0.0:
			continue
		
		var hit = false
		for enemy in enemies:
			if enemy["hp"] <= 0 or enemy["reached"]:
				continue
			
			var dist = proj["pos"].distance_to(enemy["pos"])
			var combined_radius = proj.get("radius", 2) + enemy.get("radius", 9)
			
			if dist < combined_radius:
				var damage = proj.get("damage", 1.0)
				enemy["hp"] -= damage
				
				if enemy["hp"] <= 0:
					var is_boss = enemy.get("is_boss", false)
					enemy_killed.emit(enemy["pos"], is_boss)
				
				# Aplicar efeitos de status
				if proj.get("has_freeze", false):
					enemy_manager.apply_status_effect(enemy["idx"], "freeze", 3.0)
				if proj.get("has_fire", false):
					var fire_damage = damage * 0.2
					enemy_manager.apply_status_effect(enemy["idx"], "fire", 4.0, fire_damage)
				
				# Verificar pierce
				var pierce = proj.get("pierce", 0)
				if pierce > 0:
					proj["pierce"] = pierce - 1
				else:
					proj["life"] = 0.0
					hit = true
					break
		
		if not hit and proj.get("life", 0.0) > 0.0:
			new_projectiles.append(proj)
	
	return new_projectiles

func check_aoe_damage(pos: Vector2, radius: float, damage: float) -> void:
	var enemies = enemy_manager.enemies
	for enemy in enemies:
		if enemy["hp"] <= 0 or enemy["reached"]:
			continue
		
		var dist = pos.distance_to(enemy["pos"])
		if dist <= radius:
			enemy["hp"] -= damage
			if enemy["hp"] <= 0:
				var is_boss = enemy.get("is_boss", false)
				enemy_killed.emit(enemy["pos"], is_boss)

func check_sniper_line_damage(start: Vector2, end: Vector2, damage: float, pierce: int) -> void:
	var enemies = enemy_manager.enemies
	var dir = (end - start).normalized()
	var enemies_in_line: Array = []
	
	for enemy in enemies:
		if enemy["hp"] <= 0 or enemy["reached"]:
			continue
		
		var dist_to_line = abs((enemy["pos"] - end).cross(dir))
		if dist_to_line < 20.0:
			var dist_along_line = (enemy["pos"] - start).dot(dir)
			if dist_along_line > 0:
				enemies_in_line.append({"enemy": enemy, "dist": dist_along_line})
	
	enemies_in_line.sort_custom(func(a, b): return a.dist < b.dist)
	
	var pierce_count = pierce + 1
	for i in range(min(pierce_count, enemies_in_line.size())):
		var e = enemies_in_line[i].enemy
		e["hp"] -= damage
		if e["hp"] <= 0:
			var is_boss = e.get("is_boss", false)
			enemy_killed.emit(e["pos"], is_boss)
