extends RefCounted
class_name StructureFactory

const GameConstants = preload("res://scripts/Constants.gd")
const Market = preload("res://scripts/structures/Market.gd")

## Cria o dicionário (ou objeto) inicial de cada estrutura. O Game só informa
## posição, grade e contexto de stats — a forma do dado fica num só lugar.

static func create(type_id: String, world_pos: Vector2, grid_coord: Vector2i, ctx: Dictionary) -> Variant:
	var range_boost: float = float(ctx.get("range_boost", 1.0))
	match type_id:
		"tower":
			var dir_vec: Vector2 = ctx.get("dir_vec", Vector2(1, 0))
			if dir_vec.length() < 0.1:
				dir_vec = Vector2(1, 0)
			var base_range := 260.0
			return {
				"pos": world_pos,
				"grid_x": grid_coord.x,
				"grid_y": grid_coord.y,
				"cooldown": 0.0,
				"fire_rate": 1.5,
				"range": base_range * range_boost,
				"base_range": base_range,
				"dirs": [dir_vec],
				"damage": float(ctx.get("tower_base_damage", 10.0)),
				"levels": {"RANGE": 0, "RATE": 0, "DIRS": 0, "DMG": 0},
			}
		"barracks":
			var spawn_rate: float = float(ctx.get("barracks_spawn_rate", 3.0))
			return {
				"pos": world_pos,
				"grid_x": grid_coord.x,
				"grid_y": grid_coord.y,
				"soldier_spawn_cd": spawn_rate,
				"soldier_spawn_rate": spawn_rate,
				"soldiers": [],
				"hold_time": float(ctx.get("barracks_hold_time", 1.0)),
				"damage": float(ctx.get("barracks_damage", 1.0)),
				"projectile_speed": float(ctx.get("barracks_projectile_speed", 80.0)),
				"levels": {"HOLD": 0, "DMG": 0, "SPAWN_RATE": 0, "PROJECTILE_SPEED": 0},
			}
		"slow_tower":
			var slow_base_range := 200.0
			return {
				"pos": world_pos,
				"grid_x": grid_coord.x,
				"grid_y": grid_coord.y,
				"range": slow_base_range * range_boost,
				"base_range": slow_base_range,
				"slow_amount": 0.2,
				"slow_duration": 1.0,
				"cooldown": 0.0,
				"fire_rate": 0.5,
				"levels": {"RANGE": 0, "AMOUNT": 0, "DURATION": 0, "RATE": 0},
			}
		"aoe_tower":
			var aoe_base_range := 180.0
			return {
				"pos": world_pos,
				"grid_x": grid_coord.x,
				"grid_y": grid_coord.y,
				"range": aoe_base_range * range_boost,
				"base_range": aoe_base_range,
				"damage": 2.0,
				"aoe_radius": 60.0,
				"cooldown": 0.0,
				"fire_rate": 2.0,
				"levels": {"DMG": 0, "RATE": 0, "AREA": 0},
			}
		"sniper_tower":
			var sniper_base_range := 400.0
			return {
				"pos": world_pos,
				"grid_x": grid_coord.x,
				"grid_y": grid_coord.y,
				"range": sniper_base_range * range_boost,
				"base_range": sniper_base_range,
				"damage": 3.0,
				"cooldown": 0.0,
				"fire_rate": 8.0,
				"pierce": 1,
				"target_mode": 0,
				"levels": {"DMG": 0, "RATE": 0},
			}
		"boost_tower":
			var boost_base_range := GameConstants.BOOST_TOWER_RANGE
			return {
				"pos": world_pos,
				"grid_x": grid_coord.x,
				"grid_y": grid_coord.y,
				"range": boost_base_range * range_boost,
				"base_range": boost_base_range,
				"damage_boost": 0.05,
				"rate_boost": 0.05,
				"levels": {"DMG": 0, "RATE": 0},
			}
		"shock_tower":
			var shock_base_range := 200.0
			return {
				"pos": world_pos,
				"grid_x": grid_coord.x,
				"grid_y": grid_coord.y,
				"range": shock_base_range * range_boost,
				"base_range": shock_base_range,
				"damage": 1.5,
				"chain_count": 3,
				"cooldown": 0.0,
				"fire_rate": 1.5,
				"levels": {"DMG": 0, "RATE": 0, "CHAIN": 0},
			}
		"anti_air_tower":
			var anti_air_base_range := 250.0
			return {
				"pos": world_pos,
				"grid_x": grid_coord.x,
				"grid_y": grid_coord.y,
				"range": anti_air_base_range * range_boost,
				"base_range": anti_air_base_range,
				"damage": 2.5,
				"cooldown": 0.0,
				"fire_rate": 2.5,
				"missile_count": 3,
				"explosion_radius": 0.0,
				"chain_targets": 1,
				"levels": {"DMG": 0, "RATE": 0, "RANGE": 0, "MISSILE_COUNT": 0, "EXPLOSION": 0, "CHAIN": 0},
			}
		"healing_station":
			return {
				"pos": world_pos,
				"grid_x": grid_coord.x,
				"grid_y": grid_coord.y,
				"heal_amount": 5.0,
				"range": 100.0,
			}
		"market":
			return Market.new(grid_coord, world_pos)
		"mine":
			return {
				"pos": world_pos,
				"grid_x": grid_coord.x,
				"grid_y": grid_coord.y,
				"damage": float(ctx.get("mine_damage", 5.0)),
				"explosion_radius": float(ctx.get("mine_explosion_radius", 60.0)),
				"slow_duration": float(ctx.get("mine_slow_duration", 1.5)),
				"slow_amount": float(ctx.get("mine_slow_amount", 0.4)),
				"trigger_radius": float(ctx.get("mine_trigger_radius", 18.0)),
				"triggered": false,
			}
		"wall":
			var hp: float = float(ctx.get("wall_hp", 20.0))
			return {
				"pos": world_pos,
				"grid_x": grid_coord.x,
				"grid_y": grid_coord.y,
				"hp": hp,
				"max_hp": hp,
				"upgrades": {"hp_level": 0},
			}
		_:
			return {
				"pos": world_pos,
				"grid_x": grid_coord.x,
				"grid_y": grid_coord.y,
			}
