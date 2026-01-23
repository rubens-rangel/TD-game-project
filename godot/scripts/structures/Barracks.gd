extends StructureBase
class_name Barracks

# Classe para Barracks (quartéis)

var soldier_spawn_cd: float = 0.0
var soldiers: Array = []
var levels: Dictionary = {}

func _init(grid_pos: Vector2i = Vector2i.ZERO, world_pos: Vector2 = Vector2.ZERO):
	super._init(grid_pos, world_pos)

func to_dict() -> Dictionary:
	var dict = super.to_dict()
	dict["soldier_spawn_cd"] = soldier_spawn_cd
	dict["soldiers"] = soldiers
	dict["levels"] = levels
	return dict

static func from_dict(data: Dictionary) -> Barracks:
	var barrack = Barracks.new()
	# Copiar propriedades base
	if data.has("grid_x"):
		barrack.grid_x = data["grid_x"]
	if data.has("grid_y"):
		barrack.grid_y = data["grid_y"]
	if data.has("pos"):
		barrack.pos = data["pos"]
	# Copiar propriedades específicas
	if data.has("soldier_spawn_cd"):
		barrack.soldier_spawn_cd = data["soldier_spawn_cd"]
	if data.has("soldiers"):
		barrack.soldiers = data["soldiers"]
	if data.has("levels"):
		barrack.levels = data["levels"]
	return barrack
