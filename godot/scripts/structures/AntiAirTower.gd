extends StructureBase
class_name AntiAirTower

# Classe para Anti-Air Towers (torres antiaéreas)
# Especializada em atacar apenas unidades aéreas

var range: float = 250.0
var base_range: float = 250.0
var damage: float = 15.0
var cooldown: float = 0.0
var fire_rate: float = 2.5
var missile_count: int = 1  # Número de mísseis disparados simultaneamente
var explosion_radius: float = 0.0  # Raio de explosão (0 = sem explosão)
var chain_targets: int = 1  # Número de alvos que o míssil pode perseguir
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
	dict["missile_count"] = missile_count
	dict["explosion_radius"] = explosion_radius
	dict["chain_targets"] = chain_targets
	dict["levels"] = levels
	return dict

static func from_dict(data: Dictionary) -> AntiAirTower:
	var tower = AntiAirTower.new()
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
	if data.has("missile_count"):
		tower.missile_count = data["missile_count"]
	if data.has("explosion_radius"):
		tower.explosion_radius = data["explosion_radius"]
	if data.has("chain_targets"):
		tower.chain_targets = data["chain_targets"]
	if data.has("levels"):
		tower.levels = data["levels"]
	return tower
