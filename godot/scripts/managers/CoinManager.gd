extends RefCounted
class_name CoinManager

var dropped_coins: Array = []
var effects_manager: EffectsManager
var coin_value_bonus: int = 0

signal coin_collected(value: int)

func _cfg() -> Node:
	return Engine.get_main_loop().root.get_node("GameConfig")

func _init(p_effects_manager: EffectsManager):
	effects_manager = p_effects_manager

func try_drop_coin(pos: Vector2) -> void:
	if randf() < _cfg().get_float("COIN_DROP_CHANCE"):
		var coin_value = randi_range(_cfg().get_int("COIN_MIN_VALUE"), _cfg().get_int("COIN_MAX_VALUE")) + coin_value_bonus
		dropped_coins.append({
			"pos": pos,
			"value": coin_value,
			"lifetime": 0.0,
			"max_lifetime": _cfg().get_float("COIN_LIFETIME"),
			"collected": false
		})

func try_collect_coin(world_pos: Vector2) -> int:
	for coin in dropped_coins:
		if coin.collected:
			continue

		var dist = world_pos.distance_to(coin.pos)
		if dist < 20.0:
			coin.collected = true
			effects_manager.create_coin_collect_effect(coin.pos)
			coin_collected.emit(coin.value)
			return coin.value

	return 0

func update_coins(delta: float) -> void:
	var i := 0
	while i < dropped_coins.size():
		var coin = dropped_coins[i]
		if coin.collected:
			dropped_coins[i] = dropped_coins[dropped_coins.size() - 1]
			dropped_coins.pop_back()
			continue
		coin.lifetime += delta
		if coin.lifetime >= coin.max_lifetime:
			dropped_coins[i] = dropped_coins[dropped_coins.size() - 1]
			dropped_coins.pop_back()
		else:
			i += 1

func get_dropped_coins() -> Array:
	return dropped_coins

