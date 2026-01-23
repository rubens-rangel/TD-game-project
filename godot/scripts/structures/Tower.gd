extends StructureBase
class_name Tower

# Classe para torres normais (cross pattern)

var cooldown: float = 0.0
var fire_rate: float = 1.5
var range: float = 100.0
var base_range: float = 100.0
var dirs: Array[Vector2] = []
var damage: float = 10.0
var levels: Dictionary = {}
var has_freeze: bool = false
var has_fire: bool = false

func _init(grid_pos: Vector2i = Vector2i.ZERO, world_pos: Vector2 = Vector2.ZERO).(grid_pos, world_pos):
	pass

func to_dict() -> Dictionary:
	var dict = super.to_dict()
	dict["cooldown"] = cooldown
	dict["fire_rate"] = fire_rate
	dict["range"] = range
	dict["base_range"] = base_range
	dict["dirs"] = dirs
	dict["damage"] = damage
	dict["levels"] = levels
	dict["has_freeze"] = has_freeze
	dict["has_fire"] = has_fire
	return dict

static func from_dict(data: Dictionary) -> Tower:
	var tower = Tower.new()
	# Copiar propriedades base
	if data.has("grid_x"):
		tower.grid_x = data["grid_x"]
	if data.has("grid_y"):
		tower.grid_y = data["grid_y"]
	if data.has("pos"):
		tower.pos = data["pos"]
	# Copiar propriedades específicas
	if data.has("cooldown"):
		tower.cooldown = data["cooldown"]
	if data.has("fire_rate"):
		tower.fire_rate = data["fire_rate"]
	if data.has("range"):
		tower.range = data["range"]
	if data.has("base_range"):
		tower.base_range = data["base_range"]
	if data.has("dirs"):
		tower.dirs = data["dirs"]
	if data.has("damage"):
		tower.damage = data["damage"]
	if data.has("levels"):
		tower.levels = data["levels"]
	if data.has("has_freeze"):
		tower.has_freeze = data["has_freeze"]
	if data.has("has_fire"):
		tower.has_fire = data["has_fire"]
	return tower
