extends RefCounted
class_name ProjectileManager

# Object pooling para melhor performance
var arrow_pool: Array = []
var active_arrows: Array = []
var max_pool_size: int = 100

func create_arrow(from: Vector2, to: Vector2, damage: float, pierce: int = 0) -> Dictionary:
	var arrow: Dictionary
	if arrow_pool.size() > 0:
		arrow = arrow_pool.pop_back()
	else:
		arrow = {}
	
	arrow["pos"] = from
	arrow["target"] = to
	arrow["damage"] = damage
	arrow["pierce"] = pierce
	arrow["life"] = 2.0
	arrow["radius"] = 4.0
	arrow["speed"] = 600.0
	
	var dir = (to - from).normalized()
	arrow["vel"] = dir * arrow["speed"]
	
	active_arrows.append(arrow)
	return arrow

func update_arrows(delta: float):
	var i = 0
	while i < active_arrows.size():
		var a = active_arrows[i]
		a["life"] -= delta
		if a["life"] <= 0.0:
			_recycle_arrow(a, i)
			continue
		
		a["pos"] += a["vel"] * delta
		i += 1

func _recycle_arrow(arrow: Dictionary, index: int):
	active_arrows.remove_at(index)
	if arrow_pool.size() < max_pool_size:
		arrow_pool.append(arrow)

func get_active_arrows() -> Array:
	return active_arrows

func clear_all():
	for arrow in active_arrows:
		if arrow_pool.size() < max_pool_size:
			arrow_pool.append(arrow)
	active_arrows.clear()

