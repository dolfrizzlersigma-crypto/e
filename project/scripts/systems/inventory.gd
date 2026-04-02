## Inventory - Player inventory system for carrying items.
## Manages item slots, item data, and usage.
class_name Inventory
extends Node

# --- Signals ---
signal item_added(item_data: Dictionary)
signal item_removed(item_id: String)
signal item_used(item_id: String)
signal inventory_full()

# --- Configuration ---
@export var max_slots: int = 12

# --- State ---
var items: Array[Dictionary] = []

# Item format:
# {
#   "id": "room_key_3",
#   "name": "Room 3 Key",
#   "description": "Brass key for motel room 3",
#   "icon": "res://assets/textures/ui/items/key.png",
#   "stackable": false,
#   "quantity": 1,
#   "category": "key",  # key, supply, tool, evidence, consumable
#   "usable": true,
#   "metadata": {},  # Extra data (room number, etc.)
# }


## Add an item to inventory. Returns true if successful.
func add_item(item_data: Dictionary) -> bool:
	# Try to stack with existing item
	if item_data.get("stackable", false):
		for existing in items:
			if existing["id"] == item_data["id"]:
				existing["quantity"] = existing.get("quantity", 1) + item_data.get("quantity", 1)
				item_added.emit(item_data)
				return true

	# Check capacity
	if items.size() >= max_slots:
		inventory_full.emit()
		return false

	# Add new item
	var new_item := item_data.duplicate(true)
	if not new_item.has("quantity"):
		new_item["quantity"] = 1
	items.append(new_item)
	item_added.emit(new_item)
	return true


## Remove an item by ID. Returns the removed item data or empty dict.
func remove_item(item_id: String, quantity: int = 1) -> Dictionary:
	for i in range(items.size()):
		if items[i]["id"] == item_id:
			var item := items[i]
			if item.get("stackable", false) and item["quantity"] > quantity:
				item["quantity"] -= quantity
				var removed := item.duplicate()
				removed["quantity"] = quantity
				item_removed.emit(item_id)
				return removed
			else:
				items.remove_at(i)
				item_removed.emit(item_id)
				return item
	return {}


## Check if inventory contains an item.
func has_item(item_id: String) -> bool:
	for item in items:
		if item["id"] == item_id:
			return true
	return false


## Get an item's data without removing it.
func get_item(item_id: String) -> Dictionary:
	for item in items:
		if item["id"] == item_id:
			return item
	return {}


## Get all items of a specific category.
func get_items_by_category(category: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in items:
		if item.get("category", "") == category:
			result.append(item)
	return result


## Use a consumable item.
func use_item(item_id: String) -> bool:
	var item := get_item(item_id)
	if item.is_empty():
		return false
	if not item.get("usable", false):
		return false

	# Apply item effects
	_apply_item_effect(item)
	item_used.emit(item_id)

	# Remove consumables after use
	if item.get("category") == "consumable":
		remove_item(item_id)

	return true


## Get the number of filled slots.
func get_used_slots() -> int:
	return items.size()


## Check if inventory is full.
func is_full() -> bool:
	return items.size() >= max_slots


## Clear all items.
func clear() -> void:
	items.clear()


## Get save data.
func get_save_data() -> Array:
	return items.duplicate(true)


## Load save data.
func load_save_data(data: Array) -> void:
	items.clear()
	for item in data:
		items.append(item)


# --- Private ---

func _apply_item_effect(item: Dictionary) -> void:
	var metadata: Dictionary = item.get("metadata", {})
	match item.get("id", ""):
		"coffee_cup":
			GameManager.fatigue = maxf(GameManager.fatigue - 15.0, 0.0)
			DialogueManager.show_subtitle("Mara", "That helps.")
		"energy_bar":
			GameManager.fatigue = maxf(GameManager.fatigue - 8.0, 0.0)
		"cigarette":
			GameManager.stress = maxf(GameManager.stress - 10.0, 0.0)
			GameManager.fatigue += 2.0
		_:
			if metadata.has("fatigue_reduction"):
				GameManager.fatigue = maxf(GameManager.fatigue - metadata["fatigue_reduction"], 0.0)
			if metadata.has("stress_reduction"):
				GameManager.stress = maxf(GameManager.stress - metadata["stress_reduction"], 0.0)
