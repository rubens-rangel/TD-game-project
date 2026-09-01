extends RefCounted
class_name EquippableItem


enum ItemType {
	TALISMAN,

}

enum ItemRarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

var id: String
var name: String
var description: String
var item_type: ItemType
var rarity: ItemRarity
var icon_path: String = ""

var effects: Dictionary = {}

func _init(p_id: String = "", p_name: String = "", p_description: String = "", p_type: ItemType = ItemType.TALISMAN, p_rarity: ItemRarity = ItemRarity.COMMON):
	id = p_id
	name = p_name
	description = p_description
	item_type = p_type
	rarity = p_rarity
	effects = {}

func apply_effects() -> Dictionary:
	"""Retorna um Dictionary com os efeitos a serem aplicados"""
	return effects.duplicate()

func remove_effects() -> Dictionary:
	"""Retorna um Dictionary com os efeitos a serem removidos (valores negativos)"""
	var remove_effects_dict = {}
	for key in effects:
		if effects[key] is float or effects[key] is int:
			remove_effects_dict[key] = -effects[key]
		else:
			remove_effects_dict[key] = effects[key]
	return remove_effects_dict

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

func get_rarity_color() -> Color:
	match rarity:
		ItemRarity.COMMON:
			return Color(0.7, 0.7, 0.7)
		ItemRarity.UNCOMMON:
			return Color(0.2, 0.8, 0.2)
		ItemRarity.RARE:
			return Color(0.2, 0.4, 0.9)
		ItemRarity.EPIC:
			return Color(0.7, 0.2, 0.9)
		ItemRarity.LEGENDARY:
			return Color(0.9, 0.6, 0.1)
		_:
			return Color.WHITE











