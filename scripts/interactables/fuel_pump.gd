extends BaseInteractable
## Fuel pump interactable
## Allows player to dispense fuel for customers

# ============================================================================
# CONFIGURATION
# ============================================================================

@export var pump_number: int = 1
@export var fuel_price_per_gallon: float = 3.99

# ============================================================================
# STATE
# ============================================================================

var is_active: bool = false
var current_customer: Node = null
var fuel_dispensed: float = 0.0

# ============================================================================
# UI
# ============================================================================

@onready var pump_ui: Control = null

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	super._ready()
	interaction_prompt = "Use Fuel Pump %d" % pump_number

# ============================================================================
# INTERACTION
# ============================================================================

func can_interact() -> bool:
	"""Override to check if pump is already active"""
	return super.can_interact() and not is_active

func interact() -> void:
	"""Open fuel pump UI"""
	is_active = true

	# Show pump UI
	_show_pump_ui()

	# Capture mouse for UI
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	await _wait_for_pump_completion()

	# Hide UI
	_hide_pump_ui()

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	is_active = false

# ============================================================================
# FUEL PUMP UI
# ============================================================================

func _show_pump_ui() -> void:
	"""Display fuel pump interface"""
	# Create UI if it doesn't exist
	if not pump_ui:
		pump_ui = _create_pump_ui()

	if pump_ui:
		pump_ui.visible = true

func _hide_pump_ui() -> void:
	"""Hide fuel pump interface"""
	if pump_ui:
		pump_ui.visible = false

func _create_pump_ui() -> Control:
	"""Create the fuel pump UI"""
	var ui = Control.new()
	ui.name = "FuelPumpUI"
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.visible = false

	# Background
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(400, 300)
	panel.position = Vector2(-200, -150)
	ui.add_child(panel)

	# Title
	var title = Label.new()
	title.text = "FUEL PUMP #%d" % pump_number
	title.position = Vector2(20, 20)
	title.add_theme_font_size_override("font_size", 24)
	panel.add_child(title)

	# Price display
	var price_label = Label.new()
	price_label.name = "PriceLabel"
	price_label.text = "$%.2f per gallon" % fuel_price_per_gallon
	price_label.position = Vector2(20, 60)
	price_label.add_theme_font_size_override("font_size", 18)
	panel.add_child(price_label)

	# Gallons dispensed
	var gallons_label = Label.new()
	gallons_label.name = "GallonsLabel"
	gallons_label.text = "Gallons: 0.00"
	gallons_label.position = Vector2(20, 100)
	gallons_label.add_theme_font_size_override("font_size", 20)
	panel.add_child(gallons_label)

	# Total cost
	var total_label = Label.new()
	total_label.name = "TotalLabel"
	total_label.text = "Total: $0.00"
	total_label.position = Vector2(20, 140)
	total_label.add_theme_font_size_override("font_size", 20)
	panel.add_child(total_label)

	# Dispense button
	var dispense_button = Button.new()
	dispense_button.name = "DispenseButton"
	dispense_button.text = "START PUMP"
	dispense_button.position = Vector2(20, 180)
	dispense_button.size = Vector2(160, 40)
	dispense_button.pressed.connect(_on_dispense_pressed)
	panel.add_child(dispense_button)

	# Complete button
	var complete_button = Button.new()
	complete_button.name = "CompleteButton"
	complete_button.text = "COMPLETE"
	complete_button.position = Vector2(200, 180)
	complete_button.size = Vector2(160, 40)
	complete_button.pressed.connect(_on_complete_pressed)
	panel.add_child(complete_button)

	# Close button
	var close_button = Button.new()
	close_button.text = "CLOSE"
	close_button.position = Vector2(20, 240)
	close_button.size = Vector2(360, 40)
	close_button.pressed.connect(_on_close_pressed)
	panel.add_child(close_button)

	# Add to scene
	get_tree().root.add_child(ui)

	return ui

# ============================================================================
# PUMP OPERATION
# ============================================================================

var is_pumping: bool = false
var pump_complete_signal: bool = false

func _wait_for_pump_completion() -> void:
	"""Wait for player to complete pumping"""
	pump_complete_signal = false

	while not pump_complete_signal:
		await get_tree().process_frame

func _process(delta: float) -> void:
	"""Update fuel dispensing"""
	if is_pumping:
		# Dispense fuel over time (1 gallon per second)
		fuel_dispensed += delta * 1.0

		# Update UI
		_update_pump_display()

		# Auto-stop at reasonable amount
		if fuel_dispensed >= 20.0:
			_stop_pumping()

func _update_pump_display() -> void:
	"""Update the pump UI display"""
	if not pump_ui:
		return

	var gallons_label = pump_ui.get_node_or_null("Panel/GallonsLabel")
	var total_label = pump_ui.get_node_or_null("Panel/TotalLabel")

	if gallons_label:
		gallons_label.text = "Gallons: %.2f" % fuel_dispensed

	if total_label:
		var total_cost = fuel_dispensed * fuel_price_per_gallon
		total_label.text = "Total: $%.2f" % total_cost

# ============================================================================
# UI CALLBACKS
# ============================================================================

func _on_dispense_pressed() -> void:
	"""Start/stop fuel dispensing"""
	if is_pumping:
		_stop_pumping()
	else:
		_start_pumping()

func _start_pumping() -> void:
	"""Begin dispensing fuel"""
	is_pumping = true
	fuel_dispensed = 0.0

	var button = pump_ui.get_node_or_null("Panel/DispenseButton")
	if button:
		button.text = "STOP PUMP"

func _stop_pumping() -> void:
	"""Stop dispensing fuel"""
	is_pumping = false

	var button = pump_ui.get_node_or_null("Panel/DispenseButton")
	if button:
		button.text = "START PUMP"

func _on_complete_pressed() -> void:
	"""Complete the transaction"""
	if fuel_dispensed > 0:
		var total_cost = fuel_dispensed * fuel_price_per_gallon
		EventBus.transaction_completed.emit(total_cost, ["fuel"])

		print("Fuel transaction: %.2f gallons for $%.2f" % [fuel_dispensed, total_cost])

	fuel_dispensed = 0.0
	is_pumping = false
	pump_complete_signal = true

func _on_close_pressed() -> void:
	"""Close without completing transaction"""
	fuel_dispensed = 0.0
	is_pumping = false
	pump_complete_signal = true

# ============================================================================
# PUBLIC API
# ============================================================================

func is_pump_active() -> bool:
	return is_active
