extends RefCounted
class_name SpatialHashManager


var cell_size: float = 100.0
var enemy_grid: Dictionary = {}
var enemies_ref: Array

func _init(enemies_array: Array, p_cell_size: float = 100.0):
	enemies_ref = enemies_array
	cell_size = p_cell_size

func set_enemies_ref(arr: Array) -> void:
	"""Atualiza a referência do array de inimigos (chamar após reindexar, ex.: enemies = alive)."""
	enemies_ref = arr

func _get_cell_key(pos: Vector2) -> Vector2i:
	return Vector2i(int(pos.x / cell_size), int(pos.y / cell_size))

func _get_nearby_cells(center: Vector2, range: float) -> Array:
	var cells: Array = []
	var cell_x_min = int((center.x - range) / cell_size)
	var cell_x_max = int((center.x + range) / cell_size)
	var cell_y_min = int((center.y - range) / cell_size)
	var cell_y_max = int((center.y + range) / cell_size)

	for x in range(cell_x_min, cell_x_max + 1):
		for y in range(cell_y_min, cell_y_max + 1):
			cells.append(Vector2i(x, y))

	return cells

func update_grid() -> void:
	enemy_grid.clear()

	for i in range(enemies_ref.size()):
		var enemy = enemies_ref[i]
		if enemy == null:
			continue


		if enemy.has("pos") and enemy.has("hp") and enemy["hp"] > 0 and not enemy.get("reached", false):
			var key = _get_cell_key(enemy["pos"])
			if not enemy_grid.has(key):
				enemy_grid[key] = []
			enemy_grid[key].append(i)

func get_enemy_candidates_in_range(center: Vector2, range: float) -> Array:
	var candidates: Array = []
	var nearby_cells = _get_nearby_cells(center, range)

	for cell_key in nearby_cells:
		if enemy_grid.has(cell_key):
			candidates.append_array(enemy_grid[cell_key])

	return candidates

func clear() -> void:
	enemy_grid.clear()
