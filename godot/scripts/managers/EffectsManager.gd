extends RefCounted
class_name EffectsManager

const MAX_AOE_EFFECTS := 20
const MAX_SNIPER_EFFECTS := 12
const MAX_COIN_EFFECTS := 16
const COIN_PARTICLE_COUNT := 6

var aoe_effects: Array = []
var sniper_effects: Array = []
var coin_collect_effects: Array = []

func create_aoe_effect(pos: Vector2, radius: float, duration: float = 0.3) -> void:
	if aoe_effects.size() >= MAX_AOE_EFFECTS:
		aoe_effects.remove_at(0)
	aoe_effects.append({
		"pos": pos,
		"time": 0.0,
		"max_time": duration,
		"radius": radius
	})

func create_sniper_effect(start: Vector2, end: Vector2, duration: float = 0.15) -> void:
	if sniper_effects.size() >= MAX_SNIPER_EFFECTS:
		sniper_effects.remove_at(0)
	sniper_effects.append({
		"start": start,
		"end": end,
		"time": 0.0,
		"max_time": duration
	})

func create_coin_collect_effect(pos: Vector2) -> void:
	if coin_collect_effects.size() >= MAX_COIN_EFFECTS:
		coin_collect_effects.remove_at(0)
	var effect = {
		"pos": pos,
		"time": 0.0,
		"max_time": 0.5,
		"particles": []
	}
	for i in range(COIN_PARTICLE_COUNT):
		var angle = (TAU / COIN_PARTICLE_COUNT) * i
		var speed = randf_range(80.0, 150.0)
		var vel = Vector2(cos(angle), sin(angle)) * speed
		effect.particles.append({
			"pos": pos,
			"vel": vel,
			"time": 0.0,
			"max_time": randf_range(0.3, 0.6)
		})
	coin_collect_effects.append(effect)

func update_effects(delta: float) -> void:
	_compact_timed_effects(aoe_effects, delta)
	_compact_timed_effects(sniper_effects, delta)
	_update_coin_effects(delta)

func _compact_timed_effects(effects: Array, delta: float) -> void:
	var i := 0
	while i < effects.size():
		effects[i].time += delta
		if effects[i].time >= effects[i].max_time:
			effects[i] = effects[effects.size() - 1]
			effects.pop_back()
		else:
			i += 1

func _update_coin_effects(delta: float) -> void:
	var i := 0
	while i < coin_collect_effects.size():
		var effect = coin_collect_effects[i]
		effect.time += delta
		var p := 0
		var particles: Array = effect.particles
		while p < particles.size():
			particles[p].time += delta
			particles[p].pos += particles[p].vel * delta
			if particles[p].time >= particles[p].max_time:
				particles[p] = particles[particles.size() - 1]
				particles.pop_back()
			else:
				p += 1
		if effect.time >= effect.max_time and particles.is_empty():
			coin_collect_effects[i] = coin_collect_effects[coin_collect_effects.size() - 1]
			coin_collect_effects.pop_back()
		else:
			i += 1

func get_aoe_effects() -> Array:
	return aoe_effects

func get_sniper_effects() -> Array:
	return sniper_effects

func get_coin_collect_effects() -> Array:
	return coin_collect_effects
