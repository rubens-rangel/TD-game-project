extends RefCounted
class_name PlacementManager

# Gerencia a colocação de estruturas no jogo
# Valida posições, gerencia drag and drop, e controla estados de colocação

var game: Node2D  # Referência ao Game principal
var grid_manager: GridManager  # Referência ao GridManager

# Estado de colocação
enum PlacementType {
	NONE,
	TOWER,
	BARRACKS,
	MINE,
	SLOW_TOWER,
	AOE_TOWER,
	SNIPER_TOWER,
	BOOST_TOWER,
	SHOCK_TOWER,
	WALL,
	HEALING_STATION
}

var current_placement_type: PlacementType = PlacementType.NONE
var placing_tower_dir: Vector2 = Vector2(1, 0)  # Direção inicial ao colocar torre

# Drag and drop state
var dragging: bool = false
var dragged_type: String = ""
var dragged_index: int = -1
var drag_start_pos: Vector2 = Vector2.ZERO
var drag_offset: Vector2 = Vector2.ZERO
var drag_current_pos: Vector2 = Vector2.ZERO

# Arrays de estruturas (referências do Game.gd)
var towers: Array
var barracks: Array
var mines: Array
var slow_towers: Array
var aoe_towers: Array
var sniper_towers: Array
var boost_towers: Array
var shock_towers: Array
var walls: Array
var healing_stations: Array

# Tiles ocupados
var mine_tiles: Dictionary = {}  # "col_row" -> true
var wall_tiles: Dictionary = {}  # "col_row" -> true

func _init(game_node: Node2D, grid_mgr: GridManager):
	game = game_node
	grid_manager = grid_mgr

# Define os arrays de estruturas
func set_structure_arrays(
	towers_arr: Array,
	barracks_arr: Array,
	mines_arr: Array,
	slow_towers_arr: Array,
	aoe_towers_arr: Array,
	sniper_towers_arr: Array,
	boost_towers_arr: Array,
	shock_towers_arr: Array,
	walls_arr: Array,
	healing_stations_arr: Array
) -> void:
	towers = towers_arr
	barracks = barracks_arr
	mines = mines_arr
	slow_towers = slow_towers_arr
	aoe_towers = aoe_towers_arr
	sniper_towers = sniper_towers_arr
	boost_towers = boost_towers_arr
	shock_towers = shock_towers_arr
	walls = walls_arr
	healing_stations = healing_stations_arr

# Inicia o modo de colocação
func start_placement(type: PlacementType) -> void:
	current_placement_type = type

# Cancela o modo de colocação
func cancel_placement() -> void:
	current_placement_type = PlacementType.NONE

# Verifica se está em modo de colocação
func is_placing() -> bool:
	return current_placement_type != PlacementType.NONE

# Verifica se está colocando um tipo específico
func is_placing_type(type: PlacementType) -> bool:
	return current_placement_type == type

# Converte posição do mundo para coordenadas de grid
func world_to_grid(world_pos: Vector2) -> Vector2i:
	if not grid_manager:
		return Vector2i(-1, -1)
	return grid_manager.world_to_grid(world_pos)

# Converte coordenadas de grid para posição do mundo
func grid_to_world(grid_x: int, grid_y: int) -> Vector2:
	if not grid_manager:
		return Vector2.ZERO
	return grid_manager.tile_center(grid_x, grid_y)

# Verifica se uma posição de grid é válida para colocação
func is_valid_placement(grid_x: int, grid_y: int, structure_type: PlacementType) -> bool:
	if not grid_manager:
		return false
	
	# Verificar se está dentro dos limites do grid
	if not grid_manager.is_valid_tile(grid_x, grid_y):
		return false
	
	# Verificar se não está na base
	if grid_manager.is_base_tile(grid_x, grid_y):
		return false
	
	# Verificar se não está em um caminho (para torres e estruturas grandes)
	var size = get_structure_size(structure_type)
	if size > 1:
		for dx in range(size):
			for dy in range(size):
				var check_x = grid_x + dx
				var check_y = grid_y + dy
				if grid_manager.is_walkable(check_x, check_y):
					return false
	
	# Verificar se não está ocupado por outra estrutura
	if is_tile_occupied(grid_x, grid_y, structure_type):
		return false
	
	return true

# Verifica se um tile está ocupado
func is_tile_occupied(grid_x: int, grid_y: int, exclude_type: PlacementType = PlacementType.NONE) -> bool:
	var key = "%d_%d" % [grid_x, grid_y]
	
	# Verificar minas
	if exclude_type != PlacementType.MINE and mine_tiles.has(key):
		return true
	
	# Verificar muros
	if exclude_type != PlacementType.WALL and wall_tiles.has(key):
		return true
	
	# Verificar outras estruturas (torres, quartéis, etc.)
	var size = 3  # Tamanho padrão para torres
	for dx in range(size):
		for dy in range(size):
			var check_x = grid_x - dx
			var check_y = grid_y - dy
			var check_key = "%d_%d" % [check_x, check_y]
			
			# Verificar se alguma estrutura grande está ocupando este tile
			if _has_structure_at(check_x, check_y, exclude_type):
				return true
	
	return false

# Verifica se há uma estrutura em uma posição específica
func _has_structure_at(grid_x: int, grid_y: int, exclude_type: PlacementType) -> bool:
	# Verificar torres normais
	if exclude_type != PlacementType.TOWER:
		for tower in towers:
			if tower.grid_x == grid_x and tower.grid_y == grid_y:
				return true
	
	# Verificar quartéis
	if exclude_type != PlacementType.BARRACKS:
		for barrack in barracks:
			if barrack.grid_x == grid_x and barrack.grid_y == grid_y:
				return true
	
	# Verificar outras torres (similar para slow, aoe, sniper, boost, shock)
	# ... (implementar para cada tipo)
	
	return false

# Retorna o tamanho em tiles de uma estrutura
func get_structure_size(structure_type: PlacementType) -> int:
	match structure_type:
		PlacementType.TOWER, PlacementType.BARRACKS, PlacementType.SLOW_TOWER, \
		PlacementType.AOE_TOWER, PlacementType.SNIPER_TOWER, PlacementType.BOOST_TOWER, \
		PlacementType.SHOCK_TOWER, PlacementType.HEALING_STATION:
			return GameConstants.TOWER_SIZE_GRID
		PlacementType.MINE, PlacementType.WALL:
			return GameConstants.MINE_SIZE_GRID
		_:
			return 1

# Encontra uma estrutura em uma posição do mundo
func find_structure_at(world_pos: Vector2, radius: float = 20.0) -> Dictionary:
	"""Retorna {type: PlacementType, index: int} ou {type: PlacementType.NONE} se não encontrou"""
	var structures = [
		{"type": PlacementType.TOWER, "array": towers},
		{"type": PlacementType.BARRACKS, "array": barracks},
		{"type": PlacementType.SLOW_TOWER, "array": slow_towers},
		{"type": PlacementType.AOE_TOWER, "array": aoe_towers},
		{"type": PlacementType.SNIPER_TOWER, "array": sniper_towers},
		{"type": PlacementType.BOOST_TOWER, "array": boost_towers},
		{"type": PlacementType.SHOCK_TOWER, "array": shock_towers},
	]
	
	for struct_data in structures:
		for i in range(struct_data.array.size()):
			var struct = struct_data.array[i]
			if struct.has("pos"):
				var dist = world_pos.distance_to(struct.pos)
				if dist <= radius:
					return {"type": struct_data.type, "index": i}
	
	return {"type": PlacementType.NONE, "index": -1}

# Marca um tile como ocupado
func mark_tile_occupied(grid_x: int, grid_y: int, structure_type: PlacementType) -> void:
	var key = "%d_%d" % [grid_x, grid_y]
	
	match structure_type:
		PlacementType.MINE:
			mine_tiles[key] = true
		PlacementType.WALL:
			wall_tiles[key] = true

# Remove marcação de tile ocupado
func unmark_tile_occupied(grid_x: int, grid_y: int, structure_type: PlacementType) -> void:
	var key = "%d_%d" % [grid_x, grid_y]
	
	match structure_type:
		PlacementType.MINE:
			mine_tiles.erase(key)
		PlacementType.WALL:
			wall_tiles.erase(key)

# Inicia drag and drop
func start_drag(type: String, index: int, start_pos: Vector2) -> void:
	dragging = true
	dragged_type = type
	dragged_index = index
	drag_start_pos = start_pos
	drag_offset = Vector2.ZERO

# Atualiza posição do drag
func update_drag(current_pos: Vector2) -> void:
	if dragging:
		drag_current_pos = current_pos
		drag_offset = current_pos - drag_start_pos

# Finaliza drag and drop
func end_drag() -> Dictionary:
	var result = {
		"dragging": dragging,
		"type": dragged_type,
		"index": dragged_index,
		"start_pos": drag_start_pos,
		"current_pos": drag_current_pos
	}
	
	dragging = false
	dragged_type = ""
	dragged_index = -1
	drag_start_pos = Vector2.ZERO
	drag_current_pos = Vector2.ZERO
	drag_offset = Vector2.ZERO
	
	return result

# Verifica se está arrastando
func is_dragging() -> bool:
	return dragging
