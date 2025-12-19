extends RefCounted
class_name EquippableItem

# Classe base para itens equipáveis (Talismãs, etc.)
# Permite criar diferentes tipos de itens equipáveis no futuro

enum ItemType {
	TALISMAN,
	# Adicionar mais tipos no futuro: RING, AMULET, etc.
}

enum ItemRarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

var id: String  # ID único do item
var name: String  # Nome do item
var description: String  # Descrição do item
var item_type: ItemType  # Tipo do item
var rarity: ItemRarity  # Raridade do item
var icon_path: String = ""  # Caminho para o ícone (opcional)

# Efeitos do item (Dictionary com diferentes modificadores)
# Exemplo: {"tower_damage_boost": 0.1, "base_hp_boost": 20, etc.}
var effects: Dictionary = {}

func _init(p_id: String = "", p_name: String = "", p_description: String = "", p_type: ItemType = ItemType.TALISMAN, p_rarity: ItemRarity = ItemRarity.COMMON):
	id = p_id
	name = p_name
	description = p_description
	item_type = p_type
	rarity = p_rarity
	effects = {}

# Aplica os efeitos do item (deve ser sobrescrito por classes filhas)
func apply_effects() -> Dictionary:
	"""Retorna um Dictionary com os efeitos a serem aplicados"""
	return effects.duplicate()

# Remove os efeitos do item (para quando desequipar)
func remove_effects() -> Dictionary:
	"""Retorna um Dictionary com os efeitos a serem removidos (valores negativos)"""
	var remove_effects_dict = {}
	for key in effects:
		if effects[key] is float or effects[key] is int:
			remove_effects_dict[key] = -effects[key]
		else:
			remove_effects_dict[key] = effects[key]
	return remove_effects_dict

# Serializa o item para salvamento
func serialize() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"item_type": item_type,
		"rarity": rarity,
		"icon_path": icon_path,
		"effects": effects
	}

# Deserializa o item do salvamento
static func deserialize(data: Dictionary) -> EquippableItem:
	var item = EquippableItem.new()
	item.id = data.get("id", "")
	item.name = data.get("name", "")
	item.description = data.get("description", "")
	item.item_type = data.get("item_type", ItemType.TALISMAN)
	item.rarity = data.get("rarity", ItemRarity.COMMON)
	item.icon_path = data.get("icon_path", "")
	item.effects = data.get("effects", {})
	return item

# Retorna a cor baseada na raridade
func get_rarity_color() -> Color:
	match rarity:
		ItemRarity.COMMON:
			return Color(0.7, 0.7, 0.7)  # Cinza
		ItemRarity.UNCOMMON:
			return Color(0.2, 0.8, 0.2)  # Verde
		ItemRarity.RARE:
			return Color(0.2, 0.4, 0.9)  # Azul
		ItemRarity.EPIC:
			return Color(0.7, 0.2, 0.9)  # Roxo
		ItemRarity.LEGENDARY:
			return Color(0.9, 0.6, 0.1)  # Laranja/Dourado
		_:
			return Color.WHITE







