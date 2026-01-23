extends StructureBase
class_name Wall

# Classe para Walls (muralhas)

var hp: float = 100.0
var max_hp: float = 100.0
var upgrades: Dictionary = {}

func _init(grid_pos: Vector2i = Vector2i.ZERO, world_pos: Vector2 = Vector2.ZERO):
	super._init(grid_pos, world_pos)

func to_dict() -> Dictionary:
	var dict = super.to_dict()
	dict["hp"] = hp
	dict["max_hp"] = max_hp
	dict["upgrades"] = upgrades
	return dict

static func from_dict(data: Dictionary) -> Wall:
	var wall = Wall.new()
	# Copiar propriedades base
	if data.has("grid_x"):
		wall.grid_x = data["grid_x"]
	if data.has("grid_y"):
		wall.grid_y = data["grid_y"]
	if data.has("pos"):
		wall.pos = data["pos"]
	# Copiar propriedades específicas
	if data.has("hp"):
		wall.hp = data["hp"]
	if data.has("max_hp"):
		wall.max_hp = data["max_hp"]
	if data.has("upgrades"):
		wall.upgrades = data["upgrades"]
	return wall
