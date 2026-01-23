extends RefCounted
class_name StructureBase

# Classe base para todas as estruturas do jogo
# Encapsula propriedades comuns e métodos auxiliares

var grid_x: int = 0
var grid_y: int = 0
var pos: Vector2 = Vector2.ZERO

func _init(grid_pos: Vector2i = Vector2i.ZERO, world_pos: Vector2 = Vector2.ZERO):
	grid_x = grid_pos.x
	grid_y = grid_pos.y
	pos = world_pos

# Converte para Dictionary (compatibilidade com código existente)
func to_dict() -> Dictionary:
	return {
		"grid_x": grid_x,
		"grid_y": grid_y,
		"pos": pos
	}

# Cria a partir de um Dictionary (compatibilidade com código existente)
static func from_dict(data: Dictionary) -> StructureBase:
	var structure = StructureBase.new()
	if data.has("grid_x"):
		structure.grid_x = data["grid_x"]
	if data.has("grid_y"):
		structure.grid_y = data["grid_y"]
	if data.has("pos"):
		structure.pos = data["pos"]
	return structure
