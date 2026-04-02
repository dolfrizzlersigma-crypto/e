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

	is_transaction_active = true

	# Create and show UI
	var ui = _create_register_ui()
	if ui:
		get_tree().root.add_child(ui)
		register_screen = ui
		register_screen.visible = true

	# Capture mouse for UI
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _close_register_interface() -> void:
	"""Close the register UI"""
	if register_screen:
		register_screen.queue_free()
		register_screen = null

	is_transaction_active = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _create_register_ui() -> Control:
	"""Create the cash register UI"""
	var ui = Control.new()
	ui.name = "CashRegisterUI"
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Background
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(600, 500)
	panel.position = Vector2(-300, -250)
	ui.add_child(panel)

	# Title
	var title = Label.new()
	title.text = "CASH REGISTER"
	title.position = Vector2(20, 20)
	title.add_theme_font_size_override("font_size", 28)
	panel.add_child(title)

	# Items list
	var items_label = Label.new()
	items_label.text = "SCANNED ITEMS:"
	items_label.position = Vector2(20, 70)
	items_label.add_theme_font_size_override("font_size", 18)
	panel.add_child(items_label)

	var items_list = ItemList.new()
	items_list.name = "ItemsList"
	items_list.position = Vector2(20, 100)
	items_list.size = Vector2(560, 200)
	panel.add_child(items_list)

	# Total display
	var total_label = Label.new()
	total_label.name = "TotalLabel"
	total_label.text = "TOTAL: $0.00"
	total_label.position = Vector2(20, 320)
	total_label.add_theme_font_size_override("font_size", 24)
	panel.add_child(total_label)

	# Quick add buttons
	var button_y = 370
	var item_buttons = [
		{"name": "Candy", "price": 1.99},
		{"name": "Soda", "price": 2.49},
		{"name": "Chips", "price": 3.99},
		{"name": "Coffee", "price": 4.99},
		{"name": "Sandwich", "price": 6.99},
		{"name": "Cigarettes", "price": 12.99}
	]

	for i in range(item_buttons.size()):
		var item_data = item_buttons[i]
		var btn = Button.new()
		btn.text = "%s ($%.2f)" % [item_data["name"], item_data["price"]]
		btn.position = Vector2(20 + (i % 3) * 190, button_y + int(i / 3) * 50)
		btn.size = Vector2(180, 40)
		btn.pressed.connect(_on_add_item.bind(item_data["name"], item_data["price"]))
		panel.add_child(btn)

	# Complete transaction button
	var complete_button = Button.new()
	complete_button.text = "COMPLETE TRANSACTION"
	complete_button.position = Vector2(20, 450)
	complete_button.size = Vector2(270, 40)
	complete_button.pressed.connect(_on_complete_transaction)
	panel.add_child(complete_button)

	# Close button
	var close_button = Button.new()
	close_button.text = "CLOSE"
	close_button.position = Vector2(310, 450)
	close_button.size = Vector2(270, 40)
	close_button.pressed.connect(_close_register_interface)
	panel.add_child(close_button)

	return ui

func _on_add_item(item_name: String, price: float) -> void:
	"""Add item to transaction"""
	scan_item(item_name, price)

func _on_complete_transaction() -> void:
	"""Complete the transaction"""
	if transaction_total > 0:
		# Assume customer pays exact amount
		complete_transaction(transaction_total)

	_close_register_interface()

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
	if not register_screen:
		return

	var items_list = register_screen.get_node_or_null("Panel/ItemsList")
	var total_label = register_screen.get_node_or_null("Panel/TotalLabel")

	if items_list:
		items_list.clear()
		for item in scanned_items:
			items_list.add_item("%s - $%.2f" % [item["id"], item["price"]])

	if total_label:
		total_label.text = "TOTAL: $%.2f" % transaction_total
