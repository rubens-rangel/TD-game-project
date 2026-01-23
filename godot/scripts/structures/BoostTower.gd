extends StructureBase
class_name BoostTower

# Classe para Boost Towers

var range: float = 9999.0  # Range global
var damage_boost: float = 0.2
var rate_boost: float = 0.2
var levels: Dictionary = {}

func _init(grid_pos: Vector2i = Vector2i.ZERO, world_pos: Vector2 = Vector2.ZERO).(grid_pos, world_pos):
	pass

func to_dict() -> Dictionary:
	var dict = super.to_dict()
	dict["range"] = range
	dict["damage_boost"] = damage_boost
	dict["rate_boost"] = rate_boost
	dict["levels"] = levels
	return dict

static func from_dict(data: Dictionary) -> BoostTower:
	var tower = BoostTower.new()
	# Copiar propriedades base
	if data.has("grid_x"):
		tower.grid_x = data["grid_x"]
	if data.has("grid_y"):
		tower.grid_y = data["grid_y"]
	if data.has("pos"):
		tower.pos = data["pos"]
	# Copiar propriedades específicas
	if data.has("range"):
		tower.range = data["range"]
	if data.has("damage_boost"):
		tower.damage_boost = data["damage_boost"]
	if data.has("rate_boost"):
		tower.rate_boost = data["rate_boost"]
	if data.has("levels"):
		tower.levels = data["levels"]
	return tower
