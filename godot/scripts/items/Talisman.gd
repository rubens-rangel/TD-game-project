extends EquippableItem
class_name Talisman

# Talismã - tipo específico de item equipável
# Dá bônus permanentes para torres, base, vida, etc.

enum TalismanType {
	TOWER_DAMAGE,      # Aumenta dano das torres
	TOWER_CRIT_DAMAGE, # Aumenta dano de crítico das torres
	TOWER_FIRE_RATE,   # Aumenta cadência das torres
	TOWER_RANGE,       # Aumenta alcance das torres
	BASE_DAMAGE,       # Aumenta dano da base
	COIN_DROP,         # Aumenta chance de drop de moedas
	ENEMY_SLOW,        # Reduz velocidade dos inimigos
	CRITICAL_CHANCE,   # Aumenta chance de crítico
	# Adicionar mais tipos conforme necessário
}

var talisman_type: TalismanType
var bonus_value: float  # Valor do bônus (pode ser percentual ou absoluto dependendo do tipo)

func _init(p_id: String = "", p_name: String = "", p_description: String = "", p_type: TalismanType = TalismanType.TOWER_DAMAGE, p_rarity: EquippableItem.ItemRarity = EquippableItem.ItemRarity.COMMON, p_bonus_value: float = 0.0):
	super._init(p_id, p_name, p_description, ItemType.TALISMAN, p_rarity)
	talisman_type = p_type
	bonus_value = p_bonus_value
	_apply_talisman_effects()

# Aplica os efeitos baseados no tipo de talismã
func _apply_talisman_effects():
	match talisman_type:
		TalismanType.TOWER_DAMAGE:
			effects["tower_damage_boost"] = bonus_value
			if name.is_empty():
				name = "Talismã de Dano"
			description = "Aumenta o dano de todas as torres em %.1f%%" % (bonus_value * 100)
		TalismanType.TOWER_CRIT_DAMAGE:
			effects["tower_crit_damage_boost"] = bonus_value
			if name.is_empty():
				name = "Talismã de Dano Crítico"
			description = "Aumenta o dano de crítico das torres em %.1f%%" % (bonus_value * 100)
		TalismanType.TOWER_FIRE_RATE:
			effects["tower_fire_rate_boost"] = bonus_value
			if name.is_empty():
				name = "Talismã de Cadência"
			description = "Aumenta a cadência de todas as torres em %.1f%%" % (bonus_value * 100)
		TalismanType.TOWER_RANGE:
			effects["tower_range_boost"] = bonus_value
			if name.is_empty():
				name = "Talismã de Alcance"
			description = "Aumenta o alcance de todas as torres em %.1f%%" % (bonus_value * 100)
		TalismanType.BASE_DAMAGE:
			effects["base_damage_boost"] = bonus_value
			if name.is_empty():
				name = "Talismã de Dano da Base"
			description = "Aumenta o dano da base em %.1f%%" % (bonus_value * 100)
		TalismanType.COIN_DROP:
			effects["coin_drop_chance_boost"] = bonus_value
			if name.is_empty():
				name = "Talismã de Fortuna"
			description = "Aumenta a chance de drop de moedas em %.1f%%" % (bonus_value * 100)
		TalismanType.ENEMY_SLOW:
			effects["enemy_speed_reduction"] = bonus_value
			if name.is_empty():
				name = "Talismã de Lentidão"
			description = "Reduz a velocidade de todos os inimigos em %.1f%%" % (bonus_value * 100)
		TalismanType.CRITICAL_CHANCE:
			effects["critical_chance_boost"] = bonus_value
			if name.is_empty():
				name = "Talismã de Crítico"
			description = "Aumenta a chance de crítico em %.1f%%" % (bonus_value * 100)

# Cria um talismã aleatório baseado na raridade
static func create_random(rarity: EquippableItem.ItemRarity = EquippableItem.ItemRarity.COMMON) -> Talisman:
	var talisman_types = TalismanType.values()
	var random_type = talisman_types[randi() % talisman_types.size()]
	
	# Valores base por raridade - incrementais com escala de 1.5x entre cada nível
	# Cinza (COMMON) < Verde (UNCOMMON) < Azul (RARE) < Roxo (EPIC) < Laranja (LEGENDARY)
	var base_bonus: float
	match rarity:
		EquippableItem.ItemRarity.COMMON:  # Cinza - base
			base_bonus = randf_range(0.04, 0.06)  # 4-6%
		EquippableItem.ItemRarity.UNCOMMON:  # Verde - 1.5x do common
			base_bonus = randf_range(0.06, 0.09)  # 6-9% (1.5x)
		EquippableItem.ItemRarity.RARE:  # Azul - 1.5x do uncommon
			base_bonus = randf_range(0.09, 0.135)  # 9-13.5% (1.5x)
		EquippableItem.ItemRarity.EPIC:  # Roxo - 1.5x do rare
			base_bonus = randf_range(0.135, 0.20)  # 13.5-20% (1.5x)
		EquippableItem.ItemRarity.LEGENDARY:  # Laranja - 1.5x do epic
			base_bonus = randf_range(0.20, 0.30)  # 20-30% (1.5x)
	
	# Ajustar valores absolutos para tipos específicos (se necessário)
	# TOWER_RANGE usa valores percentuais como os outros, então não precisa ajuste especial
	
	# Criar talismã com todos os valores corretos desde o início
	var talisman_id = "talisman_%s_%d" % [TalismanType.keys()[random_type], randi() % 10000]
	var talisman = Talisman.new(talisman_id, "", "", random_type, rarity, base_bonus)
	
	return talisman

# Sobrescreve serialize para incluir dados específicos do talismã
func serialize() -> Dictionary:
	var data = super.serialize()
	data["talisman_type"] = talisman_type
	data["bonus_value"] = bonus_value
	return data

# Sobrescreve deserialize para incluir dados específicos do talismã
static func deserialize(data: Dictionary) -> Talisman:
	var talisman = Talisman.new()
	talisman.id = data.get("id", "")
	talisman.name = data.get("name", "")
	talisman.item_type = EquippableItem.ItemType.TALISMAN
	talisman.rarity = data.get("rarity", EquippableItem.ItemRarity.COMMON)
	talisman.icon_path = data.get("icon_path", "")
	var old_type = data.get("talisman_type", TalismanType.TOWER_DAMAGE)
	# Converter tipo antigo TOWER_RANGE (índice 1) para TOWER_CRIT_DAMAGE (compatibilidade com saves antigos)
	# Se for um número (índice do enum antigo), converter
	if typeof(old_type) == TYPE_INT:
		if old_type == 1:  # TOWER_RANGE era índice 1 no enum antigo
			old_type = TalismanType.TOWER_CRIT_DAMAGE
		elif old_type >= TalismanType.TOWER_CRIT_DAMAGE:  # Se o índice for >= 2, ajustar (TOWER_RANGE foi removido)
			# Os tipos após TOWER_RANGE precisam ser ajustados em -1
			old_type = old_type - 1
	talisman.talisman_type = old_type
	talisman.bonus_value = data.get("bonus_value", 0.0)
	# Aplicar efeitos para atualizar description e effects com valores corretos
	talisman._apply_talisman_effects()
	return talisman

