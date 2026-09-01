extends RefCounted
class_name TileOccupancy

## Ocupação de tiles do labirinto (minas e muralhas). Mesma chave, dicionários diferentes.

static func key(tile: Vector2i) -> String:
	return "%d_%d" % [tile.x, tile.y]

static func is_occupied(tiles: Dictionary, tile: Vector2i) -> bool:
	return tiles.has(key(tile))

static func register(tiles: Dictionary, tile: Vector2i) -> void:
	tiles[key(tile)] = true

static func unregister(tiles: Dictionary, tile: Vector2i) -> void:
	var k := key(tile)
	if tiles.has(k):
		tiles.erase(k)

static func rebuild_from_structures(structures: Array) -> Dictionary:
	var tiles := {}
	for item in structures:
		if item == null:
			continue
		register(tiles, Vector2i(int(item.grid_x), int(item.grid_y)))
	return tiles
