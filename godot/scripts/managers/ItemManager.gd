extends RefCounted
class_name ItemManager


const Talisman = preload("res://scripts/items/Talisman.gd")
const EquippableItem = preload("res://scripts/items/EquippableItem.gd")

var equipped_items: Array = []
var inventory: Array = []

var total_effects: Dictionary = {}

signal item_equipped(item: EquippableItem)
signal item_unequipped(item: EquippableItem)
signal item_added_to_inventory(item: EquippableItem)

func _init():
	total_effects = {}

func add_item(item: EquippableItem) -> void:
	inventory.append(item)
	item_added_to_inventory.emit(item)

func equip_item(item: EquippableItem) -> bool:
	if item in equipped_items:
		return false


	if item.item_type == EquippableItem.ItemType.TALISMAN:

		var talismans_to_unequip = []
		for equipped_item in equipped_items:
			if equipped_item.item_type == EquippableItem.ItemType.TALISMAN:
				talismans_to_unequip.append(equipped_item)

		for talisman in talismans_to_unequip:
			equipped_items.erase(talisman)
			inventory.append(talisman)


	if item in inventory:
		inventory.erase(item)

	equipped_items.append(item)
	_update_total_effects()
	item_equipped.emit(item)
	return true

func unequip_item(item: EquippableItem) -> bool:
	if not item in equipped_items:
		return false

	equipped_items.erase(item)
	inventory.append(item)
	_update_total_effects()
	item_unequipped.emit(item)
	return true

func remove_item(item: EquippableItem) -> bool:
	var removed = false
	if item in equipped_items:
		equipped_items.erase(item)
		removed = true
	if item in inventory:
		inventory.erase(item)
		removed = true

	if removed:
		_update_total_effects()
	return removed

func _update_total_effects() -> void:
	total_effects.clear()

	for item in equipped_items:
		var item_effects = item.apply_effects()
		for key in item_effects:
			if key in total_effects:

				if item_effects[key] is float or item_effects[key] is int:
					total_effects[key] = total_effects[key] + item_effects[key]
				else:
					total_effects[key] = item_effects[key]
			else:
				total_effects[key] = item_effects[key]

func get_effect(effect_name: String, default_value = 0.0):
	return total_effects.get(effect_name, default_value)

func get_all_effects() -> Dictionary:
	return total_effects.duplicate()

func serialize() -> Dictionary:
	var equipped_data = []
	var inventory_data = []

	for item in equipped_items:
		equipped_data.append(item.serialize())

	for item in inventory:
		inventory_data.append(item.serialize())

	return {
		"equipped_items": equipped_data,
		"inventory": inventory_data
	}

func deserialize(data: Dictionary) -> void:
	equipped_items.clear()
	inventory.clear()

	var equipped_data = data.get("equipped_items", [])
	var inventory_data = data.get("inventory", [])

	for item_data in equipped_data:
		var item = _deserialize_item(item_data)
		if item:
			equipped_items.append(item)

	for item_data in inventory_data:
		var item = _deserialize_item(item_data)
		if item:
			inventory.append(item)

	_update_total_effects()

func _deserialize_item(data: Dictionary) -> EquippableItem:
	var item_type = data.get("item_type", EquippableItem.ItemType.TALISMAN)

	match item_type:
		EquippableItem.ItemType.TALISMAN:
			return Talisman.deserialize(data)
		_:
			return EquippableItem.deserialize(data)


