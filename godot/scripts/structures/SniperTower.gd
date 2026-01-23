extends StructureBase
class_name SniperTower

# Classe para Sniper Towers

var range: float = 200.0
var base_range: float = 200.0
var damage: float = 8.0
var cooldown: float = 0.0
var fire_rate: float = 8.0
var pierce: int = 1
var target_mode: int = 0  # 0 = Boss, 1 = Mais próximo ao centro
var levels: Dictionary = {}

func _init(grid_pos: Vector2i = Vector2i.ZERO, world_pos: Vector2 = Vector2.ZERO):
	super._init(grid_pos, world_pos)

func to_dict() -> Dictionary:
	var dict = super.to_dict()
	dict["range"] = range
	dict["base_range"] = base_range
	dict["damage"] = damage
	dict["cooldown"] = cooldown
	dict["fire_rate"] = fire_rate
	dict["pierce"] = pierce
	dict["target_mode"] = target_mode
	dict["levels"] = levels
	return dict

static func from_dict(data: Dictionary) -> SniperTower:
	var tower = SniperTower.new()
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
	if data.has("cooldown"):
		tower.cooldown = data["cooldown"]
	if data.has("fire_rate"):
		tower.fire_rate = data["fire_rate"]
	if data.has("pierce"):
		tower.pierce = data["pierce"]
	if data.has("target_mode"):
		tower.target_mode = data["target_mode"]
	if data.has("levels"):
		tower.levels = data["levels"]
	return tower
