extends StructureBase
class_name Market


func _init(grid_pos: Vector2i = Vector2i.ZERO, world_pos: Vector2 = Vector2.ZERO):
	super._init(grid_pos, world_pos)

func to_dict() -> Dictionary:
	var dict = super.to_dict()
	return dict

static func from_dict(data: Dictionary) -> Market:
	var market = Market.new()

	if data.has("grid_x"):
		market.grid_x = data["grid_x"]
	if data.has("grid_y"):
		market.grid_y = data["grid_y"]
	if data.has("pos"):
		market.pos = data["pos"]
	return market
