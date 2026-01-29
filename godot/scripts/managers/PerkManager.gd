extends RefCounted
class_name PerkManager

# Sistema de Perks (Melhorias Persistentes)
# Perks são melhorias que persistem entre sessões e são compradas com pontos de achievements

const PERKS_FILE = "user://perks.json"

# Categorias de perks
enum Category {
	STARTING,    # Melhorias no início do jogo
	ECONOMY,     # Melhorias econômicas
	COMBAT,      # Melhorias de combate
	DEFENSE,     # Melhorias de defesa
	PROGRESSION  # Melhorias de progressão
}

# Definir todos os perks disponíveis
static var ALL_PERKS: Dictionary = {
	# === STARTING ===
	"starting_coins_1": {
		"name": "Moedas Iniciais +50",
		"description": "Comece cada partida com 50 moedas extras",
		"category": Category.STARTING,
		"cost": 50,
		"max_level": 5,
		"icon": "💰",
		"effect": "starting_coins",
		"effect_value": 50
	},
	"starting_coins_2": {
		"name": "Moedas Iniciais +100",
		"description": "Comece cada partida com 100 moedas extras",
		"category": Category.STARTING,
		"cost": 100,
		"max_level": 1,
		"icon": "💎",
		"effect": "starting_coins",
		"effect_value": 100,
		"requires": "starting_coins_1"
	},
	"starting_hp_boost": {
		"name": "Vida Extra",
		"description": "Base começa com +20 HP",
		"category": Category.STARTING,
		"cost": 75,
		"max_level": 3,
		"icon": "❤️",
		"effect": "starting_hp",
		"effect_value": 20
	},
	
	# === ECONOMY ===
	"coin_drop_chance": {
		"name": "Sorte do Tesouro",
		"description": "+2.5% de chance de inimigos droparem moedas por nível",
		"category": Category.ECONOMY,
		"cost": 80,
		"max_level": 4,
		"icon": "🍀",
		"effect": "coin_drop_chance",
		"effect_value": 0.025  # 2.5% por nível (máximo 10% com 4 níveis)
	},
	"coin_value_boost": {
		"name": "Moedas Valiosas",
		"description": "Moedas valem +2 a +5",
		"category": Category.ECONOMY,
		"cost": 100,
		"max_level": 3,
		"icon": "💵",
		"effect": "coin_value",
		"effect_value": 2
	},
	"tower_cost_reduction": {
		"name": "Desconto de Construção",
		"description": "-10% no custo de todas as torres",
		"category": Category.ECONOMY,
		"cost": 150,
		"max_level": 2,
		"icon": "🏗️",
		"effect": "tower_cost_reduction",
		"effect_value": 0.10
	},
	"coin_magnetism": {
		"name": "Magnetismo de Moedas e Itens",
		"description": "Coleta moedas e itens automaticamente ao passar o mouse sobre eles",
		"category": Category.ECONOMY,
		"cost": 300,
		"max_level": 1,
		"icon": "🧲",
		"effect": "coin_magnetism",
		"effect_value": 1.0
	},
	
	# === COMBAT ===
	"hero_damage_boost": {
		"name": "Herói Forte",
		"description": "+10% de dano do herói",
		"category": Category.COMBAT,
		"cost": 100,
		"max_level": 5,
		"icon": "⚔️",
		"effect": "hero_damage",
		"effect_value": 0.10
	},
	"hero_fire_rate_boost": {
		"name": "Herói Rápido",
		"description": "+10% de velocidade de tiro do herói",
		"category": Category.COMBAT,
		"cost": 100,
		"max_level": 5,
		"icon": "🎯",
		"effect": "hero_fire_rate",
		"effect_value": 0.10
	},
	"tower_damage_boost": {
		"name": "Torres Poderosas",
		"description": "+5% de dano de todas as torres",
		"category": Category.COMBAT,
		"cost": 120,
		"max_level": 4,
		"icon": "🏰",
		"effect": "tower_damage",
		"effect_value": 0.05
	},
	
	# === DEFENSE ===
	"wall_durability": {
		"name": "Muros Reforçados",
		"description": "+20% de HP dos muros",
		"category": Category.DEFENSE,
		"cost": 90,
		"max_level": 3,
		"icon": "🧱",
		"effect": "wall_hp",
		"effect_value": 0.20
	},
	"tower_range_boost": {
		"name": "Alcance Estendido",
		"description": "+10% de alcance de todas as torres",
		"category": Category.DEFENSE,
		"cost": 150,
		"max_level": 3,
		"icon": "📡",
		"effect": "tower_range",
		"effect_value": 0.10
	},
	
	# === PROGRESSION ===
	"wave_reward_boost": {
		"name": "Recompensas Generosas",
		"description": "+15% de moedas ao completar waves",
		"category": Category.PROGRESSION,
		"cost": 120,
		"max_level": 4,
		"icon": "💸",
		"effect": "wave_reward",
		"effect_value": 0.15
	},
	"boss_reward_boost": {
		"name": "Caçador de Bosses",
		"description": "+20% de moedas ao derrotar bosses",
		"category": Category.PROGRESSION,
		"cost": 150,
		"max_level": 3,
		"icon": "👑",
		"effect": "boss_reward",
		"effect_value": 0.20
	},
	"enemy_reward_boost": {
		"name": "Saqueador",
		"description": "+10% de moedas ao derrotar inimigos",
		"category": Category.PROGRESSION,
		"cost": 100,
		"max_level": 5,
		"icon": "💰",
		"effect": "enemy_reward",
		"effect_value": 0.10
	},
	"wave_scale_reduction": {
		"name": "Dificuldade Reduzida",
		"description": "-2% na escala de dificuldade das waves",
		"category": Category.PROGRESSION,
		"cost": 200,
		"max_level": 3,
		"icon": "📉",
		"effect": "wave_scale_reduction",
		"effect_value": 0.02
	},
	"perfect_wave_bonus": {
		"name": "Perfeição Recompensada",
		"description": "+50% de bônus ao completar waves perfeitas",
		"category": Category.PROGRESSION,
		"cost": 180,
		"max_level": 2,
		"icon": "⭐",
		"effect": "perfect_wave_bonus",
		"effect_value": 0.50
	},
	"special_wave_bonus": {
		"name": "Ondas Especiais",
		"description": "+25% de recompensas em waves especiais",
		"category": Category.PROGRESSION,
		"cost": 160,
		"max_level": 2,
		"icon": "✨",
		"effect": "special_wave_bonus",
		"effect_value": 0.25
	},
	"early_wave_boost": {
		"name": "Começo Forte",
		"description": "+30% de recompensas nas primeiras 20 waves",
		"category": Category.PROGRESSION,
		"cost": 140,
		"max_level": 1,
		"icon": "🚀",
		"effect": "early_wave_boost",
		"effect_value": 0.30
	},
	"talisman_drop_boost": {
		"name": "Sorte de Talismãs",
		"description": "+50% de chance de inimigos droparem talismãs",
		"category": Category.PROGRESSION,
		"cost": 250,
		"max_level": 2,
		"icon": "🔮",
		"effect": "talisman_drop",
		"effect_value": 0.50
	}
}

# Estado dos perks (níveis comprados)
var perks_state: Dictionary = {}

func _init():
	load_perks()

# Carregar perks do arquivo
func load_perks() -> void:
	if FileAccess.file_exists(PERKS_FILE):
		var file = FileAccess.open(PERKS_FILE, FileAccess.READ)
		if file != null:
			var json_string = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(json_string) == OK:
				perks_state = json.data.get("perks", {})
				_initialize_missing_perks()
				return
	
	# Se não existe arquivo, inicializar tudo
	_initialize_all_perks()

func _initialize_all_perks() -> void:
	perks_state = {}
	for perk_id in ALL_PERKS.keys():
		perks_state[perk_id] = {
			"level": 0,
			"purchased_at": 0
		}

func _initialize_missing_perks() -> void:
	for perk_id in ALL_PERKS.keys():
		if not perks_state.has(perk_id):
			perks_state[perk_id] = {
				"level": 0,
				"purchased_at": 0
			}

# Salvar perks
func save_perks() -> void:
	var save_data = {
		"perks": perks_state,
		"last_saved": Time.get_unix_time_from_system()
	}
	
	var file = FileAccess.open(PERKS_FILE, FileAccess.WRITE)
	if file != null:
		var json_string = JSON.stringify(save_data)
		file.store_string(json_string)
		file.close()
		print("Perks salvos com sucesso!")

# Comprar ou melhorar um perk
func purchase_perk(perk_id: String, achievement_manager: AchievementManager) -> bool:
	if not ALL_PERKS.has(perk_id):
		print("Perk não encontrado: ", perk_id)
		return false
	
	var perk = ALL_PERKS[perk_id]
	var state = perks_state.get(perk_id, {"level": 0, "purchased_at": 0})
	
	# Verificar se já está no nível máximo
	if state.level >= perk.max_level:
		print("Perk já está no nível máximo!")
		return false
	
	# Verificar requisitos
	if perk.has("requires"):
		var required_perk = perk.requires
		var required_state = perks_state.get(required_perk, {"level": 0})
		if required_state.level < ALL_PERKS[required_perk].max_level:
			print("Requisito não atendido: ", required_perk)
			return false
	
	# Verificar se tem pontos suficientes
	var cost = perk.cost
	if achievement_manager.total_points < cost:
		print("Pontos insuficientes! Necessário: ", cost, ", Disponível: ", achievement_manager.total_points)
		return false
	
	# Comprar
	achievement_manager.total_points -= cost
	state.level += 1
	state.purchased_at = Time.get_unix_time_from_system()
	perks_state[perk_id] = state
	
	achievement_manager.save_achievements()
	save_perks()
	
	print("Perk comprado: ", perk.name, " (Nível ", state.level, "/", perk.max_level, ")")
	return true

# Obter nível de um perk
func get_perk_level(perk_id: String) -> int:
	if not perks_state.has(perk_id):
		return 0
	return perks_state[perk_id].level

# Verificar se perk está desbloqueado (nível > 0)
func is_perk_unlocked(perk_id: String) -> bool:
	return get_perk_level(perk_id) > 0

# Obter informações completas de um perk
func get_perk_info(perk_id: String) -> Dictionary:
	if not ALL_PERKS.has(perk_id):
		return {}
	
	var perk = ALL_PERKS[perk_id].duplicate()
	var state = perks_state.get(perk_id, {"level": 0, "purchased_at": 0})
	
	perk["level"] = state.level
	perk["purchased_at"] = state.purchased_at
	perk["id"] = perk_id
	perk["is_max_level"] = state.level >= perk.max_level
	
	return perk

# Obter todos os perks de uma categoria
func get_perks_by_category(category: Category) -> Array:
	var result = []
	for perk_id in ALL_PERKS.keys():
		var perk = ALL_PERKS[perk_id]
		if perk.category == category:
			result.append(get_perk_info(perk_id))
	return result

# Obter todos os perks
func get_all_perks() -> Array:
	var result = []
	for perk_id in ALL_PERKS.keys():
		result.append(get_perk_info(perk_id))
	return result

# Aplicar efeitos dos perks no jogo
func apply_perk_effects(game_instance: Node2D) -> Dictionary:
	var effects = {}
	
	for perk_id in perks_state.keys():
		var state = perks_state[perk_id]
		if state.level <= 0:
			continue
		
		if not ALL_PERKS.has(perk_id):
			continue
		
		var perk = ALL_PERKS[perk_id]
		var effect = perk.effect
		var effect_value = perk.effect_value * state.level
		
		if not effects.has(effect):
			effects[effect] = 0.0
		
		effects[effect] += effect_value
	
	return effects

# Resetar todos os perks e devolver pontos gastos
func reset_all_perks(achievement_manager: AchievementManager) -> int:
	# Calcular quantos pontos foram gastos em perks
	var total_spent = 0
	for perk_id in perks_state.keys():
		var state = perks_state[perk_id]
		if state.level > 0 and ALL_PERKS.has(perk_id):
			var perk = ALL_PERKS[perk_id]
			# Cada nível custa o mesmo valor (perk.cost)
			total_spent += perk.cost * state.level
	
	# Devolver pontos gastos
	if achievement_manager:
		achievement_manager.total_points += total_spent
		achievement_manager.save_achievements()
		print("Pontos devolvidos: ", total_spent)
	
	# Resetar perks
	perks_state = {}
	_initialize_all_perks()
	save_perks()
	print("Todos os perks foram resetados! Total de pontos devolvidos: ", total_spent)
	
	return total_spent

# Instância singleton
static var instance: PerkManager = null

static func get_instance() -> PerkManager:
	if instance == null:
		instance = PerkManager.new()
	return instance
