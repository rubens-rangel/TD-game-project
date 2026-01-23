extends StructureBase
class_name SlowTower

# Classe para Slow Towers

var range: float = 100.0
var base_range: float = 100.0
var slow_amount: float = 0.2
var slow_duration: float = 1.0
var cooldown: float = 0.0
var fire_rate: float = 0.5
var levels: Dictionary = {}

func _init(grid_pos: Vector2i = Vector2i.ZERO, world_pos: Vector2 = Vector2.ZERO):
	super._init(grid_pos, world_pos)

func to_dict() -> Dictionary:
	var dict = super.to_dict()
	dict["range"] = range
	dict["base_range"] = base_range
	dict["slow_amount"] = slow_amount
	dict["slow_duration"] = slow_duration
	dict["cooldown"] = cooldown
	dict["fire_rate"] = fire_rate
	dict["levels"] = levels
	return dict

static func from_dict(data: Dictionary) -> SlowTower:
	var tower = SlowTower.new()
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
	if data.has("base_range"):
		tower.base_range = data["base_range"]
	if data.has("slow_amount"):
		tower.slow_amount = data["slow_amount"]
	if data.has("slow_duration"):
		tower.slow_duration = data["slow_duration"]
	if data.has("cooldown"):
		tower.cooldown = data["cooldown"]
	if data.has("fire_rate"):
		tower.fire_rate = data["fire_rate"]
	if data.has("levels"):
		tower.levels = data["levels"]
	return tower
