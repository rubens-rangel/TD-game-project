extends RefCounted
class_name CoinManager

const GameConstants = preload("res://scripts/Constants.gd")

var dropped_coins: Array = []  # {pos: Vector2, value: int, lifetime: float, max_lifetime: float, collected: bool}
var effects_manager: EffectsManager

signal coin_collected(value: int)

func _init(p_effects_manager: EffectsManager):
	effects_manager = p_effects_manager

func try_drop_coin(pos: Vector2) -> void:
	if randf() < GameConstants.COIN_DROP_CHANCE:
		var coin_value = randi_range(GameConstants.COIN_MIN_VALUE, GameConstants.COIN_MAX_VALUE)
		dropped_coins.append({
			"pos": pos,
			"value": coin_value,
			"lifetime": 0.0,
			"max_lifetime": GameConstants.COIN_LIFETIME,
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
	var new_coins: Array = []
	for coin in dropped_coins:
		if coin.collected:
			continue
		coin.lifetime += delta
		if coin.lifetime < coin.max_lifetime:
			new_coins.append(coin)
	dropped_coins = new_coins

func get_dropped_coins() -> Array:
	return dropped_coins


