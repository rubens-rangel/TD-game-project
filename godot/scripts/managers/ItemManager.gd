extends RefCounted
class_name ItemManager

# Gerencia itens equipáveis (Talismãs, etc.)
# Mantém inventário e aplica efeitos dos itens equipados

const Talisman = preload("res://scripts/items/Talisman.gd")
const EquippableItem = preload("res://scripts/items/EquippableItem.gd")

var equipped_items: Array = []  # Array de EquippableItem equipados
var inventory: Array = []  # Array de EquippableItem no inventário (não equipados)

# Efeitos acumulados de todos os itens equipados
var total_effects: Dictionary = {}

signal item_equipped(item: EquippableItem)
signal item_unequipped(item: EquippableItem)
signal item_added_to_inventory(item: EquippableItem)

func _init():
	total_effects = {}

# Adiciona um item ao inventário
func add_item(item: EquippableItem) -> void:
	inventory.append(item)
	item_added_to_inventory.emit(item)

# Equipa um item (move do inventário para equipados)
# IMPORTANTE: Apenas um talismã pode estar equipado por vez
func equip_item(item: EquippableItem) -> bool:
	if item in equipped_items:
		return false  # Já está equipado
	
	# Se é um talismã, desequipar qualquer talismã já equipado
	if item.item_type == EquippableItem.ItemType.TALISMAN:
		# Remover todos os talismãs equipados (deve haver apenas um, mas por segurança)
		var talismans_to_unequip = []
		for equipped_item in equipped_items:
			if equipped_item.item_type == EquippableItem.ItemType.TALISMAN:
				talismans_to_unequip.append(equipped_item)
		
		for talisman in talismans_to_unequip:
			equipped_items.erase(talisman)
			inventory.append(talisman)
	
	# Remove do inventário se estiver lá
	if item in inventory:
		inventory.erase(item)
	
	equipped_items.append(item)
	_update_total_effects()
	item_equipped.emit(item)
	return true

# Desequipa um item (move para o inventário)
func unequip_item(item: EquippableItem) -> bool:
	if not item in equipped_items:
		return false  # Não está equipado
	
	equipped_items.erase(item)
	inventory.append(item)
	_update_total_effects()
	item_unequipped.emit(item)
	return true

# Remove um item completamente (do inventário ou equipados)
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

# Atualiza os efeitos totais baseados nos itens equipados
func _update_total_effects() -> void:
	total_effects.clear()
	
	for item in equipped_items:
		var item_effects = item.apply_effects()
		for key in item_effects:
			if key in total_effects:
				# Soma valores numéricos, mantém outros tipos
				if item_effects[key] is float or item_effects[key] is int:
					total_effects[key] = total_effects[key] + item_effects[key]
				else:
					total_effects[key] = item_effects[key]
			else:
				total_effects[key] = item_effects[key]

# Obtém um efeito específico (retorna 0 se não existir)
func get_effect(effect_name: String, default_value = 0.0):
	return total_effects.get(effect_name, default_value)

# Obtém todos os efeitos
func get_all_effects() -> Dictionary:
	return total_effects.duplicate()

# Serializa o estado do manager para salvamento
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

# Deserializa o estado do manager do salvamento
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

# Deserializa um item baseado no tipo
func _deserialize_item(data: Dictionary) -> EquippableItem:
	var item_type = data.get("item_type", EquippableItem.ItemType.TALISMAN)
	
	match item_type:
		EquippableItem.ItemType.TALISMAN:
			return Talisman.deserialize(data)
		_:
			return EquippableItem.deserialize(data)



