extends RefCounted
class_name HeroManager

# Gerencia a lógica do herói e seus upgrades
# Centraliza todas as operações relacionadas ao herói

var hero: Dictionary
var hero_home_level: int = 1
var global_tower_damage_boost: float = 1.0
var base_hp: int

# Texturas do hero home
var tex_tent: Texture2D
var tex_house: Texture2D
var tex_castle: Texture2D

# Hero home upgrade costs
var hero_home_upgrade_costs := {
	2: GameConstants.HERO_HOME_UPGRADE_COST_LEVEL_2,
	3: GameConstants.HERO_HOME_UPGRADE_COST_LEVEL_3
}

# Upgrade options disponíveis
var upgrade_options := [
	{"label": "Dano", "code": "DMG", "max_level": 30, "description": "Aumenta o dano dos tiros (+1 por nível)"},
	{"label": "Velocidade", "code": "FIRERATE", "max_level": 20, "description": "Reduz o tempo entre tiros (cadência mais rápida)"},
	{"label": "Perfuração", "code": "PIERCE", "max_level": 3, "description": "Permite acertar múltiplos inimigos (1, 2 ou 3)"},
	{"label": "Chance Crítico", "code": "CRIT_CHANCE", "max_level": 10, "description": "Aumenta chance de crítico (2% por nível, máx 20%)"},
	{"label": "Dano Crítico", "code": "CRIT_DMG", "max_level": 10, "description": "Aumenta multiplicador de dano crítico (+0.2 por nível)"},
]

func _init(base_hp_ref: int):
	base_hp = base_hp_ref
	_initialize_hero()

func _initialize_hero() -> void:
	"""Inicializa o herói com valores padrão"""
	hero = {
		"x": 0.0, 
		"y": 0.0, 
		"cooldown": 0.0, 
		"fire_rate": GameConstants.HERO_BASE_FIRE_RATE,
		"damage": GameConstants.HERO_BASE_DAMAGE, 
		"pierce": 0, 
		"range": GameConstants.HERO_RANGE_MAX,
		"levels": { 
			"DMG": 0, 
			"FIRERATE": 0, 
			"PIERCE": 0, 
			"CRIT_CHANCE": 0, 
			"CRIT_DMG": 0 
		}, 
		"coins": GameConstants.HERO_START_COINS,
		"crit_chance": 0.0,
		"crit_multiplier": GameConstants.HERO_CRIT_MULTIPLIER_BASE
	}

func set_textures(tent: Texture2D, house: Texture2D, castle: Texture2D) -> void:
	"""Define as texturas do hero home"""
	tex_tent = tent
	tex_house = house
	tex_castle = castle

func get_hero_home_texture_for_level(level: int) -> Texture2D:
	"""Retorna a textura apropriada para o nível do hero home"""
	match level:
		2:
			return tex_house if tex_house != null else tex_tent
		3:
			return tex_castle if tex_castle != null else (tex_house if tex_house != null else tex_tent)
		_:
			return tex_tent

func get_hero_home_upgrade_cost(level: int) -> int:
	"""Retorna o custo de upgrade do hero home para o nível especificado"""
	return hero_home_upgrade_costs.get(level, 0)

func get_hero_home_benefits_text(level: int) -> String:
	"""Retorna o texto descritivo dos benefícios do hero home para o nível especificado"""
	match level:
		1:
			return "Nível inicial. Proteção básica da tenda."
		2:
			return "• Dano Global das Torres +10%\n• Alcance +100\n• Vida da base +40"
		3:
			return "• Dano Global das Torres +10%\n• +1 perfuração\n• Cadência -0.05s\n• Vida da base +60"
		_:
			return "Nível máximo alcançado"

func apply_hero_home_upgrade(level: int) -> Dictionary:
	"""
	Aplica os efeitos de upgrade do hero home
	Retorna um Dictionary com as mudanças: {"global_tower_damage_boost": float, "range": int, "pierce": int, "fire_rate": float, "base_hp": int}
	"""
	var changes := {
		"global_tower_damage_boost": 0.0,
		"range": 0,
		"pierce": 0,
		"fire_rate": 0.0,
		"base_hp": 0
	}
	
	match level:
		2:
			global_tower_damage_boost *= 1.10  # +10% dano global para todas as torres
			hero["range"] += 100
			base_hp += 40
			changes["global_tower_damage_boost"] = 0.10
			changes["range"] = 100
			changes["base_hp"] = 40
		3:
			global_tower_damage_boost *= 1.10  # +10% dano global para todas as torres (acumulativo)
			hero["pierce"] += 1
			hero["fire_rate"] = max(0.1, hero["fire_rate"] - 0.03)
			base_hp += 60
			changes["global_tower_damage_boost"] = 0.10
			changes["pierce"] = 1
			changes["fire_rate"] = -0.03
			changes["base_hp"] = 60
	
	hero_home_level = level
	return changes

func can_upgrade_hero_home() -> bool:
	"""Verifica se o hero home pode ser upgradeado"""
	return hero_home_level < GameConstants.HERO_HOME_MAX_LEVEL

func get_upgrade_option(code: String) -> Dictionary:
	"""Retorna a opção de upgrade pelo código"""
	for option in upgrade_options:
		if option["code"] == code:
			return option
	return {}

func get_upgrade_level(code: String) -> int:
	"""Retorna o nível atual de um upgrade"""
	return hero["levels"].get(code, 0)

func can_upgrade(code: String) -> bool:
	"""Verifica se um upgrade pode ser aplicado"""
	var option = get_upgrade_option(code)
	if option.is_empty():
		return false
	var current_level = get_upgrade_level(code)
	return current_level < option["max_level"]

func get_upgrade_cost(base_cost: int, code: String) -> int:
	"""Calcula o custo de um upgrade"""
	var current_level = get_upgrade_level(code)
	return RewardCalculator.get_upgrade_cost(base_cost, current_level)

func apply_upgrade(code: String) -> bool:
	"""
	Aplica um upgrade ao herói
	Retorna true se o upgrade foi aplicado com sucesso
	"""
	if not can_upgrade(code):
		return false
	
	var option = get_upgrade_option(code)
	var current_level = get_upgrade_level(code)
	
	match code:
		"DMG":
			hero["damage"] += 1.0
		"FIRERATE":
			hero["fire_rate"] = max(0.1, hero["fire_rate"] - 0.05)
		"PIERCE":
			hero["pierce"] += 1
		"CRIT_CHANCE":
			hero["crit_chance"] = min(0.2, hero["crit_chance"] + 0.02)
		"CRIT_DMG":
			hero["crit_multiplier"] += 0.2
	
	hero["levels"][code] = current_level + 1
	return true

func add_coins(amount: int) -> void:
	"""Adiciona moedas ao herói"""
	hero["coins"] += amount

func spend_coins(amount: int) -> bool:
	"""
	Gasta moedas do herói
	Retorna true se conseguiu gastar, false se não tinha moedas suficientes
	"""
	if hero["coins"] >= amount:
		hero["coins"] -= amount
		return true
	return false

func get_coins() -> int:
	"""Retorna a quantidade de moedas do herói"""
	return hero["coins"]

func set_position(x: float, y: float) -> void:
	"""Define a posição do herói"""
	hero["x"] = x
	hero["y"] = y

func get_position() -> Vector2:
	"""Retorna a posição do herói"""
	return Vector2(hero["x"], hero["y"])

