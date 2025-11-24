extends RefCounted
class_name PlacementManager

const GameConstants = preload("res://scripts/Constants.gd")

var grid_manager: GridManager
var pathfinder: Pathfinder

var placing_type: String = ""  # "tower", "barracks", "mine", etc.
var preview_mouse_pos: Vector2 = Vector2.ZERO

func _init(p_grid_manager: GridManager, p_pathfinder: Pathfinder):
	grid_manager = p_grid_manager
	pathfinder = p_pathfinder

func start_placing(type: String) -> void:
	placing_type = type

func stop_placing() -> void:
	placing_type = ""

func is_placing() -> bool:
	return placing_type != ""

func can_place_at(world_pos: Vector2) -> bool:
	if not grid_manager.is_inside_base_point(world_pos):
		return false
	
	# Verificar se está em caminho (para minas e barreiras)
	if placing_type == "mine" or placing_type == "wall":
		if _is_on_path(world_pos):
			return false
		if _is_in_center_area(world_pos):
			return false
	
	var grid_coord = grid_manager.world_to_base_grid(world_pos)
	var size = _get_size_for_type(placing_type)
	var item_type = _get_item_type_for_type(placing_type)
	
	return grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, size, item_type)

func _is_on_path(world_pos: Vector2) -> bool:
	var tile_col = int(floor(world_pos.x / GameConstants.TILE_SIZE))
	var tile_row = int(floor(world_pos.y / GameConstants.TILE_SIZE))
	
	if tile_row < 0 or tile_row >= GameConstants.GRID_ROWS or tile_col < 0 or tile_col >= GameConstants.GRID_COLS:
		return false
	
	if grid_manager.grid.size() > tile_row and grid_manager.grid[tile_row].size() > tile_col:
		return grid_manager.grid[tile_row][tile_col] == 0
	return false

func _is_in_center_area(world_pos: Vector2) -> bool:
	var center_pos = grid_manager.tile_center(grid_manager.center.x, grid_manager.center.y)
	var dist = world_pos.distance_to(center_pos)
	var center_radius = GameConstants.TILE_SIZE * 2.0
	return dist < center_radius

func _get_size_for_type(type: String) -> int:
	match type:
		"tower": return GameConstants.TOWER_SIZE_GRID
		"barracks": return GameConstants.BARRACKS_SIZE_GRID
		"mine": return GameConstants.MINE_SIZE_GRID
		"slow_tower": return GameConstants.SLOW_TOWER_SIZE_GRID
		"aoe_tower": return GameConstants.AOE_TOWER_SIZE_GRID
		"sniper_tower": return GameConstants.SNIPER_TOWER_SIZE_GRID
		"boost_tower": return GameConstants.BOOST_TOWER_SIZE_GRID
		"wall": return GameConstants.WALL_SIZE_GRID
		"healing_station": return GameConstants.HEALING_STATION_SIZE_GRID
		_: return 1

func _get_item_type_for_type(type: String) -> int:
	match type:
		"tower": return 1
		"barracks": return 3
		"mine": return 4
		"slow_tower": return 5
		"aoe_tower": return 6
		"sniper_tower": return 7
		"boost_tower": return 8
		"wall": return 9
		"healing_station": return 10
		_: return 0

func place_structure(world_pos: Vector2) -> Dictionary:
	if not can_place_at(world_pos):
		return {}
	
	var grid_coord = grid_manager.world_to_base_grid(world_pos)
	var size = _get_size_for_type(placing_type)
	var item_type = _get_item_type_for_type(placing_type)
	
	grid_manager.set_grid_area(grid_coord.x, grid_coord.y, size, item_type)
	pathfinder.invalidate_cache()
	
	var structure_pos = grid_manager.base_grid_to_world(grid_coord.x, grid_coord.y)
	
	return {
		"type": placing_type,
		"pos": structure_pos,
		"grid_x": grid_coord.x,
		"grid_y": grid_coord.y
	}


