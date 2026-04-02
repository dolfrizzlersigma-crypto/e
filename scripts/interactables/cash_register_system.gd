extends Node3D
class_name CashRegisterSystem

## ====================================================================================
## CASH REGISTER SYSTEM - PROFESSIONAL POINT OF SALE
## ====================================================================================
## Realistic cash register with scanning, payment processing, receipt printing
## Handles transactions, refunds, voids, and shift reconciliation
## ====================================================================================

signal transaction_started
signal item_scanned(item_data: Dictionary)
signal transaction_completed(transaction_data: Dictionary)
signal transaction_cancelled
signal drawer_opened
signal drawer_closed
signal receipt_printed(receipt_data: String)
signal payment_processed(amount: float, method: String)

# ====================================================================================
# CONFIGURATION
# ====================================================================================

const MAX_TRANSACTION_ITEMS = 100
const DRAWER_OPEN_DURATION = 1.5
const RECEIPT_PRINT_SPEED = 0.05
const SCAN_BEEP_DURATION = 0.1

# ====================================================================================
# STATE
# ====================================================================================

enum RegisterState {
	IDLE,
	TRANSACTION_ACTIVE,
	AWAITING_PAYMENT,
	PROCESSING_PAYMENT,
	PRINTING_RECEIPT,
	DRAWER_OPEN,
	ERROR,
	LOCKED
}

var current_state: RegisterState = RegisterState.IDLE
var current_transaction: Dictionary = {}
var transaction_history: Array[Dictionary] = []
var shift_totals: Dictionary = {}
var drawer_cash_amount: float = 200.0  # Starting cash
var is_drawer_open: bool = false

# ====================================================================================
# TRANSACTION DATA
# ====================================================================================

var scanned_items: Array[Dictionary] = []
var transaction_subtotal: float = 0.0
var transaction_tax: float = 0.0
var transaction_total: float = 0.0
var amount_tendered: float = 0.0
var change_due: float = 0.0

# Tax configuration
const TAX_RATE: float = 0.0825  # 8.25% sales tax

# ====================================================================================
# AUDIO VISUAL
# ====================================================================================

@onready var scan_beep_player: AudioStreamPlayer3D
@onready var drawer_open_sound: AudioStreamPlayer3D
@onready var receipt_printer_sound: AudioStreamPlayer3D
@onready var error_sound: AudioStreamPlayer3D
@onready var display_screen: Label3D
@onready var customer_display: Label3D

# ====================================================================================
# INITIALIZATION
# ====================================================================================

func _ready() -> void:
	_initialize_register()
	_initialize_shift_totals()
	_update_displays()
	print("CashRegisterSystem: Initialized")

func _initialize_register() -> void:
	current_state = RegisterState.IDLE
	current_transaction = {}
	scanned_items.clear()
	_reset_transaction_values()

func _initialize_shift_totals() -> void:
	shift_totals = {
		"total_sales": 0.0,
		"total_tax": 0.0,
		"transaction_count": 0,
		"cash_payments": 0.0,
		"card_payments": 0.0,
		"refunds": 0.0,
		"voids": 0,
		"drawer_opens": 0,
		"shift_start_time": Time.get_ticks_msec(),
		"starting_cash": drawer_cash_amount
	}

func _reset_transaction_values() -> void:
	scanned_items.clear()
	transaction_subtotal = 0.0
	transaction_tax = 0.0
	transaction_total = 0.0
	amount_tendered = 0.0
	change_due = 0.0

# ====================================================================================
# TRANSACTION MANAGEMENT
# ====================================================================================

func start_new_transaction() -> bool:
	if current_state != RegisterState.IDLE:
		push_warning("Cannot start transaction - register not idle")
		return false

	current_state = RegisterState.TRANSACTION_ACTIVE
	_reset_transaction_values()

	current_transaction = {
		"id": _generate_transaction_id(),
		"timestamp": Time.get_unix_time_from_system(),
		"items": [],
		"clerk_id": "001",  # TODO: Get from employee system
		"register_number": "01"
	}

	transaction_started.emit()
	_update_displays()
	print("Transaction started: %s" % current_transaction.id)
	return true

func scan_item(item_barcode: String) -> bool:
	if current_state != RegisterState.TRANSACTION_ACTIVE:
		push_warning("Cannot scan item - no active transaction")
		_play_error_sound()
		return false

	var item_data = _lookup_item_by_barcode(item_barcode)
	if item_data.is_empty():
		push_warning("Item not found: %s" % item_barcode)
		_play_error_sound()
		return false

	if scanned_items.size() >= MAX_TRANSACTION_ITEMS:
		push_warning("Transaction item limit reached")
		_play_error_sound()
		return false

	# Add item to transaction
	scanned_items.append(item_data)
	current_transaction.items.append(item_data)

	# Update totals
	_recalculate_totals()

	# Play scan sound and emit signal
	_play_scan_beep()
	item_scanned.emit(item_data)
	_update_displays()

	print("Item scanned: %s - $%.2f" % [item_data.name, item_data.price])
	return true

func void_last_item() -> bool:
	if current_state != RegisterState.TRANSACTION_ACTIVE:
		return false

	if scanned_items.is_empty():
		return false

	var removed_item = scanned_items.pop_back()
	current_transaction.items.pop_back()
	_recalculate_totals()
	_update_displays()

	print("Item voided: %s" % removed_item.name)
	return true

func void_transaction() -> bool:
	if current_state != RegisterState.TRANSACTION_ACTIVE and current_state != RegisterState.AWAITING_PAYMENT:
		return false

	shift_totals.voids += 1
	_reset_transaction_values()
	current_state = RegisterState.IDLE
	current_transaction.clear()

	transaction_cancelled.emit()
	_update_displays()
	print("Transaction voided")
	return true

# ====================================================================================
# PAYMENT PROCESSING
# ====================================================================================

func finish_transaction() -> bool:
	if current_state != RegisterState.TRANSACTION_ACTIVE:
		return false

	if scanned_items.is_empty():
		push_warning("Cannot finish empty transaction")
		return false

	current_state = RegisterState.AWAITING_PAYMENT
	_update_displays()
	print("Transaction total: $%.2f" % transaction_total)
	return true

func process_cash_payment(cash_amount: float) -> bool:
	if current_state != RegisterState.AWAITING_PAYMENT:
		return false

	amount_tendered = cash_amount

	if amount_tendered < transaction_total:
		push_warning("Insufficient payment")
		_play_error_sound()
		return false

	current_state = RegisterState.PROCESSING_PAYMENT
	change_due = amount_tendered - transaction_total

	# Update drawer and shift totals
	drawer_cash_amount += transaction_total
	shift_totals.cash_payments += transaction_total

	# Complete transaction
	await _complete_payment("CASH")
	return true

func process_card_payment(card_type: String = "CREDIT") -> bool:
	if current_state != RegisterState.AWAITING_PAYMENT:
		return false

	current_state = RegisterState.PROCESSING_PAYMENT
	amount_tendered = transaction_total
	change_due = 0.0

	# Simulate card processing delay
	await get_tree().create_timer(1.5).timeout

	# Update shift totals
	shift_totals.card_payments += transaction_total

	# Complete transaction
	await _complete_payment(card_type)
	return true

func _complete_payment(payment_method: String) -> void:
	# Record transaction
	current_transaction.subtotal = transaction_subtotal
	current_transaction.tax = transaction_tax
	current_transaction.total = transaction_total
	current_transaction.payment_method = payment_method
	current_transaction.amount_tendered = amount_tendered
	current_transaction.change_due = change_due
	current_transaction.completed_at = Time.get_unix_time_from_system()

	transaction_history.append(current_transaction.duplicate(true))

	# Update shift totals
	shift_totals.total_sales += transaction_total
	shift_totals.total_tax += transaction_tax
	shift_totals.transaction_count += 1

	# Emit payment processed signal
	payment_processed.emit(transaction_total, payment_method)

	# Print receipt
	await _print_receipt()

	# Open drawer for cash transactions
	if payment_method == "CASH":
		await _open_drawer()

	# Complete transaction
	transaction_completed.emit(current_transaction)
	current_state = RegisterState.IDLE
	_reset_transaction_values()
	_update_displays()

	print("Transaction completed: $%.2f via %s" % [transaction_total, payment_method])

# ====================================================================================
# RECEIPT PRINTING
# ====================================================================================

func _print_receipt() -> void:
	current_state = RegisterState.PRINTING_RECEIPT

	var receipt_text = _generate_receipt_text()

	if receipt_printer_sound:
		receipt_printer_sound.play()

	# Simulate printing delay
	await get_tree().create_timer(RECEIPT_PRINT_SPEED * receipt_text.length() / 10.0).timeout

	receipt_printed.emit(receipt_text)
	print("Receipt printed")

func _generate_receipt_text() -> String:
	var receipt = ""
	receipt += "================================\n"
	receipt += "    EXIT 13 SERVICE PLAZA\n"
	receipt += "     NIGHT AUDITOR SHIFT\n"
	receipt += "================================\n"
	receipt += "Transaction: %s\n" % current_transaction.id
	receipt += "Date: %s\n" % Time.get_datetime_string_from_system()
	receipt += "Register: %s\n" % current_transaction.register_number
	receipt += "Clerk: %s\n" % current_transaction.clerk_id
	receipt += "--------------------------------\n"

	# Items
	for item in scanned_items:
		var item_line = "%-20s $%6.2f\n" % [item.name, item.price]
		receipt += item_line

	receipt += "--------------------------------\n"
	receipt += "%-20s $%6.2f\n" % ["SUBTOTAL:", transaction_subtotal]
	receipt += "%-20s $%6.2f\n" % ["TAX (%.1f%%):" % (TAX_RATE * 100), transaction_tax]
	receipt += "%-20s $%6.2f\n" % ["TOTAL:", transaction_total]
	receipt += "--------------------------------\n"
	receipt += "%-20s $%6.2f\n" % [current_transaction.payment_method + ":", amount_tendered]

	if change_due > 0:
		receipt += "%-20s $%6.2f\n" % ["CHANGE:", change_due]

	receipt += "================================\n"
	receipt += "   Thank you for stopping by!\n"
	receipt += "    Drive safely on Mile 87\n"
	receipt += "================================\n"

	return receipt

# ====================================================================================
# CASH DRAWER
# ====================================================================================

func _open_drawer() -> void:
	if is_drawer_open:
		return

	is_drawer_open = true
	shift_totals.drawer_opens += 1

	if drawer_open_sound:
		drawer_open_sound.play()

	drawer_opened.emit()
	print("Cash drawer opened - Contains: $%.2f" % drawer_cash_amount)

	# Auto-close after duration
	await get_tree().create_timer(DRAWER_OPEN_DURATION).timeout
	_close_drawer()

func _close_drawer() -> void:
	if not is_drawer_open:
		return

	is_drawer_open = false

	drawer_closed.emit()
	print("Cash drawer closed")

func manual_open_drawer() -> bool:
	"""Allow manual drawer opening for starting cash, deposits, etc."""
	if current_state != RegisterState.IDLE:
		return false

	await _open_drawer()
	return true

# ====================================================================================
# CALCULATIONS
# ====================================================================================

func _recalculate_totals() -> void:
	transaction_subtotal = 0.0

	for item in scanned_items:
		transaction_subtotal += item.price

	transaction_tax = transaction_subtotal * TAX_RATE
	transaction_total = transaction_subtotal + transaction_tax

# ====================================================================================
# ITEM LOOKUP
# ====================================================================================

func _lookup_item_by_barcode(barcode: String) -> Dictionary:
	# TODO: Connect to actual product database
	# For now, return sample data
	var sample_items = {
		"001": {"barcode": "001", "name": "Soda Can", "price": 1.99, "category": "Beverage"},
		"002": {"barcode": "002", "name": "Chips", "price": 2.49, "category": "Snacks"},
		"003": {"barcode": "003", "name": "Candy Bar", "price": 1.29, "category": "Candy"},
		"004": {"barcode": "004", "name": "Energy Drink", "price": 3.49, "category": "Beverage"},
		"005": {"barcode": "005", "name": "Gum", "price": 0.99, "category": "Candy"},
		"006": {"barcode": "006", "name": "Water Bottle", "price": 1.79, "category": "Beverage"},
		"007": {"barcode": "007", "name": "Beef Jerky", "price": 4.99, "category": "Snacks"},
		"008": {"barcode": "008", "name": "Coffee", "price": 2.29, "category": "Beverage"},
		"009": {"barcode": "009", "name": "Donut", "price": 1.49, "category": "Bakery"},
		"010": {"barcode": "010", "name": "Sandwich", "price": 5.99, "category": "Food"}
	}

	return sample_items.get(barcode, {})

# ====================================================================================
# DISPLAY UPDATES
# ====================================================================================

func _update_displays() -> void:
	if display_screen:
		match current_state:
			RegisterState.IDLE:
				display_screen.text = "READY\nWelcome"
			RegisterState.TRANSACTION_ACTIVE:
				display_screen.text = "TOTAL\n$%.2f" % transaction_total
			RegisterState.AWAITING_PAYMENT:
				display_screen.text = "AMOUNT DUE\n$%.2f" % transaction_total
			RegisterState.PROCESSING_PAYMENT:
				display_screen.text = "PROCESSING..."
			RegisterState.PRINTING_RECEIPT:
				display_screen.text = "PRINTING..."
			RegisterState.DRAWER_OPEN:
				display_screen.text = "DRAWER OPEN"
			RegisterState.ERROR:
				display_screen.text = "ERROR"
			RegisterState.LOCKED:
				display_screen.text = "LOCKED"

	if customer_display and current_state == RegisterState.TRANSACTION_ACTIVE:
		var last_item_text = ""
		if not scanned_items.is_empty():
			var last_item = scanned_items[-1]
			last_item_text = "%s\n$%.2f" % [last_item.name, last_item.price]
		customer_display.text = "TOTAL: $%.2f\n%s" % [transaction_total, last_item_text]

# ====================================================================================
# AUDIO
# ====================================================================================

func _play_scan_beep() -> void:
	if scan_beep_player:
		scan_beep_player.play()

func _play_error_sound() -> void:
	if error_sound:
		error_sound.play()

# ====================================================================================
# SHIFT MANAGEMENT
# ====================================================================================

func get_shift_report() -> Dictionary:
	var current_time = Time.get_ticks_msec()
	var shift_duration = (current_time - shift_totals.shift_start_time) / 1000.0  # seconds

	return {
		"duration_seconds": shift_duration,
		"starting_cash": shift_totals.starting_cash,
		"ending_cash": drawer_cash_amount,
		"total_sales": shift_totals.total_sales,
		"total_tax": shift_totals.total_tax,
		"transaction_count": shift_totals.transaction_count,
		"cash_payments": shift_totals.cash_payments,
		"card_payments": shift_totals.card_payments,
		"refunds": shift_totals.refunds,
		"voids": shift_totals.voids,
		"drawer_opens": shift_totals.drawer_opens,
		"expected_cash": shift_totals.starting_cash + shift_totals.cash_payments - shift_totals.refunds,
		"cash_variance": drawer_cash_amount - (shift_totals.starting_cash + shift_totals.cash_payments - shift_totals.refunds)
	}

func print_shift_report() -> void:
	var report = get_shift_report()
	print("\n========== SHIFT REPORT ==========")
	print("Duration: %.1f minutes" % (report.duration_seconds / 60.0))
	print("Transactions: %d" % report.transaction_count)
	print("Total Sales: $%.2f" % report.total_sales)
	print("Cash: $%.2f | Card: $%.2f" % [report.cash_payments, report.card_payments])
	print("Starting Cash: $%.2f" % report.starting_cash)
	print("Ending Cash: $%.2f" % report.ending_cash)
	print("Expected: $%.2f" % report.expected_cash)
	print("Variance: $%.2f" % report.cash_variance)
	print("===================================\n")

# ====================================================================================
# UTILITIES
# ====================================================================================

func _generate_transaction_id() -> String:
	var timestamp = Time.get_unix_time_from_system()
	var random_suffix = randi() % 1000
	return "TXN-%d-%03d" % [timestamp, random_suffix]

func get_state_name() -> String:
	return RegisterState.keys()[current_state]

# ====================================================================================
# DEBUG
# ====================================================================================

func _input(event: InputEvent) -> void:
	if OS.is_debug_build():
		if event.is_action_pressed("ui_accept"):  # Debug: quick scan
			if current_state == RegisterState.TRANSACTION_ACTIVE:
				scan_item("00%d" % (randi() % 10 + 1))
