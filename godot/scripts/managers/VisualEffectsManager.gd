extends RefCounted
class_name VisualEffectsManager

const GameConstants = preload("res://scripts/Constants.gd")
const ObjectPoolManager = preload("res://scripts/managers/ObjectPoolManager.gd")

# Gerencia efeitos visuais do jogo
# Complementa o EffectsManager existente com funcionalidades adicionais

var game: Node2D  # Referência ao Game principal
var effects_manager: EffectsManager  # Referência ao EffectsManager existente
var object_pool_manager: ObjectPoolManager  # Pool manager para reutilização de objetos

# Arrays de efeitos visuais
var damage_numbers: Array = []
var enemy_death_animations: Array = []
var shock_effects: Array = []

func _init(game_node: Node2D, effects_mgr: EffectsManager, pool_mgr: ObjectPoolManager = null):
	game = game_node
	effects_manager = effects_mgr
	object_pool_manager = pool_mgr

# Cria um número de dano flutuante
func create_damage_number(pos: Vector2, damage: float, is_crit: bool = false, color: Color = Color.WHITE) -> void:
	"""Cria um indicador de dano flutuante usando object pooling"""
	var damage_num: Dictionary
	if object_pool_manager:
		damage_num = object_pool_manager.get_damage_number()
		if damage_num.is_empty():
			# Criar novo se pool está vazio
			damage_num = {}
	else:
		damage_num = {}
	
	# Configurar valores
	damage_num["pos"] = pos + Vector2(randf_range(-10, 10), randf_range(-5, 5))
	damage_num["value"] = damage
	damage_num["time"] = 0.0
	damage_num["max_time"] = GameConstants.EFFECT_DAMAGE_NUMBER_DURATION
	damage_num["is_crit"] = is_crit
	damage_num["color"] = color if color != Color.WHITE else (Color(1.0, 0.8, 0.2) if is_crit else Color(1.0, 0.3, 0.3))
	damage_num["velocity"] = Vector2(randf_range(-30, 30), -50.0)
	
	damage_numbers.append(damage_num)

# Cria uma animação de morte de inimigo
func create_death_animation(pos: Vector2) -> void:
	"""Cria uma animação visual quando um inimigo morre usando object pooling"""
	var anim: Dictionary
	if object_pool_manager:
		anim = object_pool_manager.get_enemy_death_animation()
		if anim.is_empty():
			anim = {}
	else:
		anim = {}
	
	# Configurar valores
	anim["pos"] = pos
	anim["time"] = 0.0
	anim["max_time"] = GameConstants.EFFECT_DEATH_ANIMATION_DURATION
	anim["scale"] = 1.0
	anim["alpha"] = 1.0
	
	enemy_death_animations.append(anim)

# Cria um efeito de choque elétrico
func create_shock_effect(start_pos: Vector2, end_pos: Vector2) -> void:
	"""Cria um efeito visual de choque elétrico entre duas posições usando object pooling"""
	var effect: Dictionary
	if object_pool_manager:
		effect = object_pool_manager.get_shock_effect()
		if effect.is_empty():
			effect = {}
	else:
		effect = {}
	
	# Configurar valores
	effect["start"] = start_pos
	effect["end"] = end_pos
	effect["time"] = 0.0
	effect["max_time"] = 0.2  # Efeito rápido
	
	shock_effects.append(effect)

# Atualiza todos os efeitos visuais
func update_effects(delta: float) -> void:
	"""Atualiza todos os efeitos visuais baseado no delta time"""
	_update_damage_numbers(delta)
	_update_death_animations(delta)
	_update_shock_effects(delta)

func _update_damage_numbers(delta: float) -> void:
	"""Atualiza os números de dano flutuantes e retorna objetos expirados ao pool"""
	var new_damage_numbers: Array = []
	for dmg in damage_numbers:
		dmg["time"] += delta
		dmg["pos"] += dmg["velocity"] * delta
		if dmg["time"] < dmg["max_time"]:
			new_damage_numbers.append(dmg)
		elif object_pool_manager:
			# Retornar ao pool quando expirar
			object_pool_manager.return_damage_number(dmg)
	damage_numbers = new_damage_numbers

func _update_death_animations(delta: float) -> void:
	"""Atualiza as animações de morte e retorna objetos expirados ao pool"""
	var new_death_animations: Array = []
	for anim in enemy_death_animations:
		anim["time"] += delta
		var progress = anim["time"] / anim["max_time"]
		anim["scale"] = 1.0 + progress * 0.5  # Cresce enquanto desaparece
		anim["alpha"] = 1.0 - progress  # Fade out
		if anim["time"] < anim["max_time"]:
			new_death_animations.append(anim)
		elif object_pool_manager:
			# Retornar ao pool quando expirar
			object_pool_manager.return_enemy_death_animation(anim)
	enemy_death_animations = new_death_animations

func _update_shock_effects(delta: float) -> void:
	"""Atualiza os efeitos de choque elétrico e retorna objetos expirados ao pool"""
	var new_shock_effects: Array = []
	for effect in shock_effects:
		effect["time"] += delta
		if effect["time"] < effect["max_time"]:
			new_shock_effects.append(effect)
		elif object_pool_manager:
			# Retornar ao pool quando expirar
			object_pool_manager.return_shock_effect(effect)
	shock_effects = new_shock_effects

# Desenha todos os efeitos visuais
func draw_effects() -> void:
	"""Desenha todos os efeitos visuais na tela"""
	if not game:
		return
	
	_draw_damage_numbers()
	_draw_death_animations()
	_draw_shock_effects()

func _draw_damage_numbers() -> void:
	"""Desenha os números de dano flutuantes"""
	for dmg in damage_numbers:
		var alpha = 1.0 - (dmg["time"] / dmg["max_time"])
		var color = dmg["color"]
		color.a = alpha
		
		var font_size = 20 if dmg["is_crit"] else 16
		var offset_y = -dmg["time"] * 50.0
		
		# Desenhar texto (será implementado no Game.gd _draw)
		# Por enquanto, apenas armazena os dados

func _draw_death_animations() -> void:
	"""Desenha as animações de morte"""
	for anim in enemy_death_animations:
		# Desenhar círculo expandindo e desaparecendo
		# Será implementado no Game.gd _draw
		pass

func _draw_shock_effects() -> void:
	"""Desenha os efeitos de choque elétrico"""
	for effect in shock_effects:
		# Desenhar linha elétrica entre start e end
		# Será implementado no Game.gd _draw
		pass

# Limpa todos os efeitos
func clear_all() -> void:
	"""Limpa todos os efeitos visuais"""
	damage_numbers.clear()
	enemy_death_animations.clear()
	shock_effects.clear()

# Getters para acesso aos arrays (para desenho no Game.gd)
func get_damage_numbers() -> Array:
	return damage_numbers

func get_death_animations() -> Array:
	return enemy_death_animations

func get_shock_effects() -> Array:
	return shock_effects


