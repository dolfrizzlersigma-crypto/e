## CashRegister - Handles customer transactions, pump authorization, and till management.
## The core work mechanic of the convenience store.
class_name CashRegister
extends Interactable

# --- Signals ---
signal transaction_started(customer_data: Dictionary)
signal transaction_completed(total: float)
signal transaction_cancelled()
signal pump_authorized(pump_number: int)
signal pump_denied(pump_number: int)
signal till_reconciled(difference: float)
signal suspicious_transaction(reason: String)

# --- Exported Properties ---
@export var register_open_sound: AudioStream = null
@export var register_close_sound: AudioStream = null
@export var receipt_print_sound: AudioStream = null

# --- State ---
var is_register_open: bool = false
var till_amount: float = 200.0  # Starting cash in register
var till_expected: float = 200.0  # What the till should have
var current_transaction: Dictionary = {}
var transaction_log: Array[Dictionary] = []
var _is_processing: bool = false

# --- Price List ---
var price_list: Dictionary = {
	"coffee_small": {"name": "Coffee (S)", "price": 2.50},
	"coffee_large": {"name": "Coffee (L)", "price": 3.75},
	"hot_dog": {"name": "Hot Dog", "price": 3.00},
	"sandwich": {"name": "Sandwich", "price": 5.50},
	"chips": {"name": "Chips", "price": 2.00},
	"soda": {"name": "Soda", "price": 1.75},
	"water": {"name": "Water Bottle", "price": 1.50},
	"candy_bar": {"name": "Candy Bar", "price": 1.25},
	"energy_drink": {"name": "Energy Drink", "price": 3.50},
	"cigarettes": {"name": "Cigarettes", "price": 8.00},
	"lighter": {"name": "Lighter", "price": 2.00},
	"map": {"name": "Road Map", "price": 4.00},
	"bandages": {"name": "Bandages", "price": 3.50},
	"aspirin": {"name": "Aspirin", "price": 4.50},
	"ice_bag": {"name": "Bag of Ice", "price": 3.00},
	"phone_charger": {"name": "Phone Charger", "price": 12.00},
	"nachos": {"name": "Nachos w/ Cheese", "price": 4.00},
	"slushie": {"name": "Slushie", "price": 2.50},
	"beef_jerky": {"name": "Beef Jerky", "price": 6.50},
	"donut": {"name": "Donut", "price": 1.75},
	"trail_mix": {"name": "Trail Mix", "price": 3.25},
	"gum": {"name": "Chewing Gum", "price": 1.50},
	"sunflower_seeds": {"name": "Sunflower Seeds", "price": 2.25},
	"corn_dog": {"name": "Corn Dog", "price": 2.75},
	"pizza_slice": {"name": "Pizza Slice", "price": 3.50},
	"coffee_creamer": {"name": "Bottle Creamer", "price": 3.00},
	"instant_noodles": {"name": "Instant Noodles", "price": 1.50},
	"frozen_burrito": {"name": "Frozen Burrito", "price": 2.50},
}

# Gas prices per gallon
var gas_price_regular: float = 3.89
var gas_price_premium: float = 4.49


func _ready() -> void:
	super._ready()
	interaction_prompt = "Use Register"
	add_to_group("register")


## Override interaction to open/use the register.
func _on_interact(_player: Node) -> void:
	if is_register_open:
		_close_register()
	else:
		_open_register()


## Start a new customer transaction.
func start_transaction(customer_data: Dictionary = {}) -> void:
	if _is_processing:
		return
	current_transaction = {
		"items": [],
		"subtotal": 0.0,
		"tax": 0.0,
		"total": 0.0,
		"customer": customer_data,
		"timestamp": GameManager.in_game_hour * 100 + GameManager.in_game_minute,
		"shift": GameManager.current_shift,
	}
	_is_processing = true
	transaction_started.emit(customer_data)


## Add an item to the current transaction.
func scan_item(item_id: String, quantity: int = 1) -> float:
	if not _is_processing:
		return 0.0

	var item_data: Dictionary = price_list.get(item_id, {})
	if item_data.is_empty():
		return 0.0

	var line_total: float = item_data["price"] * quantity
	current_transaction["items"].append({
		"id": item_id,
		"name": item_data["name"],
		"price": item_data["price"],
		"quantity": quantity,
		"line_total": line_total,
	})
	current_transaction["subtotal"] += line_total
	current_transaction["tax"] = current_transaction["subtotal"] * 0.07
	current_transaction["total"] = current_transaction["subtotal"] + current_transaction["tax"]

	return current_transaction["total"]


## Complete the current transaction.
func complete_transaction(payment_amount: float) -> Dictionary:
	if not _is_processing:
		return {}

	var total: float = current_transaction["total"]
	var change: float = payment_amount - total

	if change < 0:
		DialogueManager.show_subtitle("Mara", "That's not enough.")
		return {}

	# Update till
	till_amount += total
	till_expected += total

	# Check for suspicious amounts
	if total > 50.0:
		suspicious_transaction.emit("Large cash transaction: $%.2f" % total)

	current_transaction["payment"] = payment_amount
	current_transaction["change"] = change
	current_transaction["completed"] = true

	# Log the transaction
	transaction_log.append(current_transaction.duplicate(true))
	GameManager.shift_revenue += total
	GameManager.shift_customers_served += 1

	if receipt_print_sound:
		AudioManager.play_sfx(receipt_print_sound)

	var result := current_transaction.duplicate(true)
	transaction_completed.emit(total)

	# Reset
	current_transaction.clear()
	_is_processing = false

	return result


## Cancel the current transaction.
func cancel_transaction() -> void:
	current_transaction.clear()
	_is_processing = false
	transaction_cancelled.emit()


## Authorize a fuel pump for a customer.
func authorize_pump(pump_number: int, prepay_amount: float = 0.0) -> bool:
	if pump_number < 1 or pump_number > 4:
		pump_denied.emit(pump_number)
		return false

	# Track the authorization
	var auth_data := {
		"pump": pump_number,
		"prepay": prepay_amount,
		"timestamp": GameManager.in_game_hour * 100 + GameManager.in_game_minute,
		"authorized": true,
	}
	transaction_log.append(auth_data)

	if prepay_amount > 0:
		till_amount += prepay_amount
		till_expected += prepay_amount
		GameManager.shift_revenue += prepay_amount

	pump_authorized.emit(pump_number)
	return true


## Reconcile the till at end of shift.
func reconcile_till() -> Dictionary:
	var difference := till_amount - till_expected
	var result := {
		"actual": till_amount,
		"expected": till_expected,
		"difference": difference,
		"transactions": transaction_log.size(),
		"total_revenue": GameManager.shift_revenue,
	}

	# Small discrepancies are normal, large ones affect reputation
	if absf(difference) > 5.0:
		GameManager.reputation -= 5.0
		DialogueManager.show_subtitle("Mara", "The till is off by $%.2f. That's not good." % difference)
	elif absf(difference) < 0.50:
		GameManager.reputation += 2.0
		DialogueManager.show_subtitle("Mara", "Till balanced. Clean shift.")

	till_reconciled.emit(difference)
	return result


## Get the current transaction total.
func get_current_total() -> float:
	return current_transaction.get("total", 0.0)


## Get today's revenue.
func get_shift_revenue() -> float:
	var total: float = 0.0
	for transaction in transaction_log:
		total += transaction.get("total", 0.0)
		total += transaction.get("prepay", 0.0)
	return total


# --- Private ---

func _open_register() -> void:
	is_register_open = true
	if register_open_sound:
		AudioManager.play_sfx(register_open_sound)


func _close_register() -> void:
	is_register_open = false
	if register_close_sound:
		AudioManager.play_sfx(register_close_sound)
