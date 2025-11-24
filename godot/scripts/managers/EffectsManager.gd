extends RefCounted
class_name EffectsManager

var aoe_effects: Array = []  # {pos: Vector2, time: float, max_time: float, radius: float}
var sniper_effects: Array = []  # {start: Vector2, end: Vector2, time: float, max_time: float}
var coin_collect_effects: Array = []  # {pos: Vector2, time: float, max_time: float, particles: Array}

func create_aoe_effect(pos: Vector2, radius: float, duration: float = 0.3) -> void:
	aoe_effects.append({
		"pos": pos,
		"time": 0.0,
		"max_time": duration,
		"radius": radius
	})

func create_sniper_effect(start: Vector2, end: Vector2, duration: float = 0.15) -> void:
	sniper_effects.append({
		"start": start,
		"end": end,
		"time": 0.0,
		"max_time": duration
	})

func create_coin_collect_effect(pos: Vector2) -> void:
	var effect = {
		"pos": pos,
		"time": 0.0,
		"max_time": 0.5,
		"particles": []
	}
	
	var particle_count = 12
	for i in range(particle_count):
		var angle = (TAU / particle_count) * i
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
	_update_aoe_effects(delta)
	_update_sniper_effects(delta)
	_update_coin_effects(delta)

func _update_aoe_effects(delta: float) -> void:
	var new_effects: Array = []
	for effect in aoe_effects:
		effect.time += delta
		if effect.time < effect.max_time:
			new_effects.append(effect)
	aoe_effects = new_effects

func _update_sniper_effects(delta: float) -> void:
	var new_effects: Array = []
	for effect in sniper_effects:
		effect.time += delta
		if effect.time < effect.max_time:
			new_effects.append(effect)
	sniper_effects = new_effects

func _update_coin_effects(delta: float) -> void:
	var new_effects: Array = []
	for effect in coin_collect_effects:
		effect.time += delta
		var new_particles: Array = []
		for particle in effect.particles:
			particle.time += delta
			particle.pos += particle.vel * delta
			if particle.time < particle.max_time:
				new_particles.append(particle)
		effect.particles = new_particles
		if effect.time < effect.max_time or effect.particles.size() > 0:
			new_effects.append(effect)
	coin_collect_effects = new_effects

func get_aoe_effects() -> Array:
	return aoe_effects

func get_sniper_effects() -> Array:
	return sniper_effects

func get_coin_collect_effects() -> Array:
	return coin_collect_effects


