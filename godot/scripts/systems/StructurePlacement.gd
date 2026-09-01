extends RefCounted
class_name StructurePlacement

## Coloca e move estruturas no grid da base. Todas as torres/edifícios da base
## usam esta lógica; minas e muralhas ficam no fluxo de tiles do caminho.

static func occupy(grid_manager, pathfinder, grid_coord: Vector2i, size: int, grid_type: int) -> Vector2:
	grid_manager.set_grid_area(grid_coord.x, grid_coord.y, size, grid_type)
	pathfinder.invalidate_cache()
	return grid_manager.base_grid_to_world(grid_coord.x, grid_coord.y, size)

static func can_place(grid_manager, pos: Vector2, size: int, grid_type: int) -> Dictionary:
	var result := {
		"ok": false,
		"grid_coord": Vector2i.ZERO,
		"world_pos": Vector2.ZERO,
	}
	if not grid_manager.is_inside_base_point(pos):
		return result
	var grid_coord: Vector2i = grid_manager.world_to_base_grid(pos)
	if not grid_manager.can_place_in_grid(grid_coord.x, grid_coord.y, size, grid_type):
		return result
	result.ok = true
	result.grid_coord = grid_coord
	result.world_pos = grid_manager.base_grid_to_world(grid_coord.x, grid_coord.y, size)
	return result

static func try_move(grid_manager, pathfinder, structure, new_grid_coord: Vector2i, size: int, grid_type: int) -> bool:
	if structure == null:
		return false
	var old_x: int = int(structure.grid_x)
	var old_y: int = int(structure.grid_y)
	if new_grid_coord.x == old_x and new_grid_coord.y == old_y:
		return true
	var ignore_area := Rect2i(old_x, old_y, size, size)
	if not grid_manager.can_place_in_grid(new_grid_coord.x, new_grid_coord.y, size, grid_type, ignore_area):
		return false
	grid_manager.clear_grid_area(old_x, old_y, size)
	grid_manager.set_grid_area(new_grid_coord.x, new_grid_coord.y, size, grid_type)
	pathfinder.invalidate_cache()
	structure.pos = grid_manager.base_grid_to_world(new_grid_coord.x, new_grid_coord.y, size)
	structure.grid_x = new_grid_coord.x
	structure.grid_y = new_grid_coord.y
	return true
