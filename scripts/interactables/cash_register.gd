extends BaseInteractable
## Cash register system for customer transactions

# ============================================================================
# STATE
# ============================================================================

var current_customer: Node = null
var scanned_items: Array = []
var transaction_total: float = 0.0
var till_balance: float = 200.0 # Starting cash
var is_transaction_active: bool = false

# ============================================================================
# REFERENCES
# ============================================================================

@onready var register_screen: Control = $RegisterScreen if has_node("RegisterScreen") else null

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	super._ready()
	interaction_prompt = "Use Register"

# ============================================================================
# INTERACTION
# ============================================================================

func _on_interact() -> void:
	_open_register_interface()

func _open_register_interface() -> void:
	"""Open the cash register UI"""
	if is_transaction_active:
		return

	# Show register UI
	if register_screen:
		register_screen.visible = true

	# Capture mouse for UI
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _close_register_interface() -> void:
	"""Close the register UI"""
	if register_screen:
		register_screen.visible = false

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# ============================================================================
# TRANSACTION
# ============================================================================

func start_transaction(customer: Node) -> void:
	"""Start a new transaction"""
	current_customer = customer
	scanned_items.clear()
	transaction_total = 0.0
	is_transaction_active = true

func scan_item(item_id: String, price: float) -> void:
	"""Scan an item"""
	scanned_items.append({"id": item_id, "price": price})
	transaction_total += price

	AudioManager.play_sfx("register_beep", global_position)

	_update_register_display()

func complete_transaction(payment_amount: float) -> bool:
	"""Complete the transaction"""
	if payment_amount < transaction_total:
		AudioManager.play_sfx("register_error", global_position)
		return false

	var change = payment_amount - transaction_total
	till_balance += transaction_total

	AudioManager.play_sfx("register_drawer", global_position)
	_print_receipt()

	EventBus.transaction_completed.emit(transaction_total, scanned_items)

	is_transaction_active = false
	scanned_items.clear()
	transaction_total = 0.0
	current_customer = null

	return true

func _print_receipt() -> void:
	"""Print a receipt"""
	AudioManager.play_sfx("receipt_printer", global_position)

	# Receipt could be a physical object that spawns
	# Or triggers story events (receipt for wrong customer, etc.)

# ============================================================================
# TILL MANAGEMENT
# ============================================================================

func deposit_cash(amount: float) -> void:
	"""Deposit cash into register"""
	till_balance += amount

func withdraw_cash(amount: float) -> bool:
	"""Withdraw cash from register"""
	if till_balance >= amount:
		till_balance -= amount
		return true
	return false

func reconcile_till() -> Dictionary:
	"""Reconcile till at end of shift"""
	var expected = 200.0 # Would calculate based on transactions
	var actual = till_balance
	var difference = actual - expected

	return {
		"expected": expected,
		"actual": actual,
		"difference": difference
	}

# ============================================================================
# UI
# ============================================================================

func _update_register_display() -> void:
	"""Update register screen display"""
	# Would update UI elements
	pass
