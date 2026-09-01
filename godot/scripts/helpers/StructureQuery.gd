extends RefCounted
class_name StructureQuery

## Busca o índice de uma estrutura pela posição no mundo.

static func find_at(structures: Array, p: Vector2, r: float) -> int:
	if structures.is_empty() or r <= 0.0:
		return -1
	var r_sq := r * r
	for i in range(structures.size()):
		var item = structures[i]
		if item == null:
			continue
		var item_pos: Vector2 = item.pos
		if item_pos.distance_squared_to(p) <= r_sq:
			return i
	return -1
