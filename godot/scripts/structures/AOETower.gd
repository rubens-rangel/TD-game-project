extends StructureBase
class_name AOETower

# Classe para AOE Towers

var range: float = 100.0
var base_range: float = 100.0
var damage: float = 2.0
var aoe_radius: float = 60.0
var cooldown: float = 0.0
var fire_rate: float = 2.0
var levels: Dictionary = {}

func _init(grid_pos: Vector2i = Vector2i.ZERO, world_pos: Vector2 = Vector2.ZERO).(grid_pos, world_pos):
	pass

func to_dict() -> Dictionary:
	var dict = super.to_dict()
	dict["range"] = range
	dict["base_range"] = base_range
	dict["damage"] = damage
	dict["aoe_radius"] = aoe_radius
	dict["cooldown"] = cooldown
	dict["fire_rate"] = fire_rate
	dict["levels"] = levels
	return dict

static func from_dict(data: Dictionary) -> AOETower:
	var tower = AOETower.new()
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
	if data.has("aoe_radius"):
		tower.aoe_radius = data["aoe_radius"]
	if data.has("cooldown"):
		tower.cooldown = data["cooldown"]
	if data.has("fire_rate"):
		tower.fire_rate = data["fire_rate"]
	if data.has("levels"):
		tower.levels = data["levels"]
	return tower
