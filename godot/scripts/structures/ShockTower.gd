extends StructureBase
class_name ShockTower

# Classe para Shock Towers

var range: float = 100.0
var base_range: float = 100.0
var damage: float = 1.5
var chain_count: int = 3
var cooldown: float = 0.0
var fire_rate: float = 1.5
var levels: Dictionary = {}

func _init(grid_pos: Vector2i = Vector2i.ZERO, world_pos: Vector2 = Vector2.ZERO):
	super._init(grid_pos, world_pos)

func to_dict() -> Dictionary:
	var dict = super.to_dict()
	dict["range"] = range
	dict["base_range"] = base_range
	dict["damage"] = damage
	dict["chain_count"] = chain_count
	dict["cooldown"] = cooldown
	dict["fire_rate"] = fire_rate
	dict["levels"] = levels
	return dict

static func from_dict(data: Dictionary) -> ShockTower:
	var tower = ShockTower.new()
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
	if data.has("damage"):
		tower.damage = data["damage"]
	if data.has("chain_count"):
		tower.chain_count = data["chain_count"]
	if data.has("cooldown"):
		tower.cooldown = data["cooldown"]
	if data.has("fire_rate"):
		tower.fire_rate = data["fire_rate"]
	if data.has("levels"):
		tower.levels = data["levels"]
	return tower
