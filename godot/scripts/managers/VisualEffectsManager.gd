extends RefCounted
class_name VisualEffectsManager

const GameConstants = preload("res://scripts/Constants.gd")
const ObjectPoolManager = preload("res://scripts/managers/ObjectPoolManager.gd")

const MAX_DAMAGE_NUMBERS := 40
const MAX_DEATH_ANIMS := 20
const MAX_SHOCK_EFFECTS := 16

var game: Node2D
var effects_manager: EffectsManager
var object_pool_manager: ObjectPoolManager

var damage_numbers: Array = []
var enemy_death_animations: Array = []
var shock_effects: Array = []

func _init(game_node: Node2D, effects_mgr: EffectsManager, pool_mgr: ObjectPoolManager = null):
	game = game_node
	effects_manager = effects_mgr
	object_pool_manager = pool_mgr

func create_damage_number(pos: Vector2, damage: float, is_crit: bool = false, color: Color = Color.WHITE) -> void:
	if damage_numbers.size() >= MAX_DAMAGE_NUMBERS:
		return
	var damage_num: Dictionary
	if object_pool_manager:
		damage_num = object_pool_manager.get_damage_number()
		if damage_num.is_empty():
			damage_num = {}
	else:
		damage_num = {}

	damage_num["pos"] = pos + Vector2(randf_range(-10, 10), randf_range(-5, 5))
	damage_num["value"] = damage
	damage_num["time"] = 0.0
	damage_num["max_time"] = GameConstants.EFFECT_DAMAGE_NUMBER_DURATION
	damage_num["is_crit"] = is_crit
	damage_num["color"] = color if color != Color.WHITE else (Color(1.0, 0.8, 0.2) if is_crit else Color(1.0, 0.3, 0.3))
	damage_num["velocity"] = Vector2(randf_range(-30, 30), -50.0)
	damage_numbers.append(damage_num)

func create_death_animation(pos: Vector2) -> void:
	if enemy_death_animations.size() >= MAX_DEATH_ANIMS:
		return
	var anim: Dictionary
	if object_pool_manager:
		anim = object_pool_manager.get_enemy_death_animation()
		if anim.is_empty():
			anim = {}
	else:
		anim = {}

	anim["pos"] = pos
	anim["time"] = 0.0
	anim["max_time"] = GameConstants.EFFECT_DEATH_ANIMATION_DURATION
	anim["scale"] = 1.0
	anim["alpha"] = 1.0
	enemy_death_animations.append(anim)

func create_shock_effect(start_pos: Vector2, end_pos: Vector2) -> void:
	if shock_effects.size() >= MAX_SHOCK_EFFECTS:
		return
	var effect: Dictionary
	if object_pool_manager:
		effect = object_pool_manager.get_shock_effect()
		if effect.is_empty():
			effect = {}
	else:
		effect = {}

	effect["start"] = start_pos
	effect["end"] = end_pos
	effect["time"] = 0.0
	effect["max_time"] = 0.2
	shock_effects.append(effect)

func update_effects(delta: float) -> void:
	_update_damage_numbers(delta)
	_update_death_animations(delta)
	_update_shock_effects(delta)

func _update_damage_numbers(delta: float) -> void:
	var i := 0
	while i < damage_numbers.size():
		var dmg = damage_numbers[i]
		dmg["time"] += delta
		dmg["pos"] += dmg["velocity"] * delta
		if dmg["time"] >= dmg["max_time"]:
			if object_pool_manager:
				object_pool_manager.return_damage_number(dmg)
			damage_numbers[i] = damage_numbers[damage_numbers.size() - 1]
			damage_numbers.pop_back()
		else:
			i += 1

func _update_death_animations(delta: float) -> void:
	var i := 0
	while i < enemy_death_animations.size():
		var anim = enemy_death_animations[i]
		anim["time"] += delta
		var progress = anim["time"] / anim["max_time"]
		anim["scale"] = 1.0 + progress * 0.5
		anim["alpha"] = 1.0 - progress
		if anim["time"] >= anim["max_time"]:
			if object_pool_manager:
				object_pool_manager.return_enemy_death_animation(anim)
			enemy_death_animations[i] = enemy_death_animations[enemy_death_animations.size() - 1]
			enemy_death_animations.pop_back()
		else:
			i += 1

func _update_shock_effects(delta: float) -> void:
	var i := 0
	while i < shock_effects.size():
		var effect = shock_effects[i]
		effect["time"] += delta
		if effect["time"] >= effect["max_time"]:
			if object_pool_manager:
				object_pool_manager.return_shock_effect(effect)
			shock_effects[i] = shock_effects[shock_effects.size() - 1]
			shock_effects.pop_back()
		else:
			i += 1

func get_damage_numbers() -> Array:
	return damage_numbers

func get_death_animations() -> Array:
	return enemy_death_animations

func get_shock_effects() -> Array:
	return shock_effects
