extends Node
class_name PlayerInventory
## Player inventory system

# ============================================================================
# INVENTORY DATA
# ============================================================================

const MAX_SLOTS: int = 12
var items: Array = []
var equipped_item: String = ""

# ============================================================================
# SIGNALS
# ============================================================================

signal inventory_changed()
signal item_equipped(item_id: String)
signal item_used(item_id: String)

# ============================================================================
# ITEM MANAGEMENT
# ============================================================================

func add_item(item_id: String, quantity: int = 1) -> bool:
	"""Add an item to inventory"""
	# Check if item exists in database
	var item_data = _get_item_data(item_id)
	if item_data.is_empty():
		return false

	# Check if stackable and already exists
	if item_data.get("stackable", false):
		for item in items:
			if item["id"] == item_id:
				var max_stack = item_data.get("max_stack", 999)
				if item["quantity"] + quantity <= max_stack:
					item["quantity"] += quantity
					inventory_changed.emit()
					return true

	# Add as new item
	if items.size() < MAX_SLOTS:
		items.append({
			"id": item_id,
			"quantity": quantity
		})
		inventory_changed.emit()
		EventBus.inventory_changed.emit(items)
		return true

	return false

func remove_item(item_id: String, quantity: int = 1) -> bool:
	"""Remove an item from inventory"""
	for i in range(items.size()):
		if items[i]["id"] == item_id:
			items[i]["quantity"] -= quantity

			if items[i]["quantity"] <= 0:
				items.remove_at(i)

			inventory_changed.emit()
			EventBus.inventory_changed.emit(items)
			return true

	return false

func has_item(item_id: String, quantity: int = 1) -> bool:
	"""Check if player has an item"""
	for item in items:
		if item["id"] == item_id and item["quantity"] >= quantity:
			return true
	return false

func get_item_count(item_id: String) -> int:
	"""Get count of a specific item"""
	for item in items:
		if item["id"] == item_id:
			return item["quantity"]
	return 0

# ============================================================================
# EQUIPMENT
# ============================================================================

func equip_item(item_id: String) -> void:
	"""Equip an item"""
	if has_item(item_id):
		equipped_item = item_id
		item_equipped.emit(item_id)

func unequip() -> void:
	"""Unequip current item"""
	equipped_item = ""
	item_equipped.emit("")

# ============================================================================
# ITEM USAGE
# ============================================================================

func use_item(item_id: String) -> bool:
	"""Use a consumable item"""
	if not has_item(item_id):
		return false

	var item_data = _get_item_data(item_id)
	if item_data.get("category", "") != "consumable":
		return false

	# Apply item effect
	_apply_item_effect(item_data)

	# Remove from inventory
	remove_item(item_id, 1)

	item_used.emit(item_id)
	return true

func _apply_item_effect(item_data: Dictionary) -> void:
	"""Apply an item's effect"""
	var effect = item_data.get("effect", "")

	match effect:
		"reduce_fatigue":
			# Would reduce player fatigue
			pass
		"reduce_fatigue_strong":
			# Would reduce player fatigue more
			pass

# ============================================================================
# UTILITY
# ============================================================================

func _get_item_data(item_id: String) -> Dictionary:
	"""Get item data from database"""
	# Would load from product_database.json
	# For now, return basic data
	return {
		"id": item_id,
		"name": item_id,
		"category": "item",
		"stackable": true,
		"max_stack": 10
	}

func clear_inventory() -> void:
	"""Clear all items from inventory"""
	items.clear()
	equipped_item = ""
	inventory_changed.emit()

func get_all_items() -> Array:
	"""Get all items in inventory"""
	return items.duplicate()

func is_full() -> bool:
	"""Check if inventory is full"""
	return items.size() >= MAX_SLOTS
