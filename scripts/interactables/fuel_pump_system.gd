extends Node3D
class_name FuelPumpSystem

## ====================================================================================
## FUEL PUMP AUTHORIZATION & MANAGEMENT SYSTEM
## ====================================================================================
## Controls fuel dispensing, payment authorization, and pump status
## Handles pre-pay, pay-at-pump, and pump monitoring
## ====================================================================================

signal pump_authorized(pump_id: int, amount: float)
signal pump_activated(pump_id: int)
signal pump_stopped(pump_id: int, fuel_dispensed: float)
signal transaction_completed(pump_id: int, transaction_data: Dictionary)
signal pump_error(pump_id: int, error_message: String)
signal emergency_stop_activated()

# ====================================================================================
# CONFIGURATION
# ====================================================================================

const MAX_PUMPS = 8
const MAX_AUTHORIZATION_AMOUNT = 200.0
const FUEL_FLOW_RATE = 10.0  # Gallons per minute
const PRICE_PER_GALLON_REGULAR = 3.49
const PRICE_PER_GALLON_PLUS = 3.79
const PRICE_PER_GALLON_PREMIUM = 4.09
const PRICE_PER_GALLON_DIESEL = 3.99

# ====================================================================================
# PUMP STATES
# ====================================================================================

enum PumpState {
	OFFLINE,
	IDLE,
	AWAITING_AUTHORIZATION,
	AUTHORIZED,
	DISPENSING,
	STOPPED,
	ERROR,
	EMERGENCY_STOP
}

enum FuelGrade {
	REGULAR_87,
	PLUS_89,
	PREMIUM_91,
	DIESEL
}

# ====================================================================================
# PUMP DATA
# ====================================================================================

class PumpData:
	var pump_id: int
	var state: PumpState = PumpState.IDLE
	var fuel_grade: FuelGrade = FuelGrade.REGULAR_87
	var authorized_amount: float = 0.0
	var dispensed_gallons: float = 0.0
	var dispensed_cost: float = 0.0
	var customer_prepay: bool = false
	var payment_method: String = ""
	var transaction_start_time: float = 0.0
	var current_flow_rate: float = 0.0
	var error_message: String = ""
	var last_transaction: Dictionary = {}

	func reset() -> void:
		state = PumpState.IDLE
		fuel_grade = FuelGrade.REGULAR_87
		authorized_amount = 0.0
		dispensed_gallons = 0.0
		dispensed_cost = 0.0
		customer_prepay = false
		payment_method = ""
		transaction_start_time = 0.0
		current_flow_rate = 0.0
		error_message = ""

var pumps: Array[PumpData] = []
var total_fuel_dispensed_today: float = 0.0
var total_revenue_today: float = 0.0
var transaction_count_today: int = 0

# ====================================================================================
# VISUAL COMPONENTS
# ====================================================================================

@export var pump_displays: Array[Label3D] = []
@export var pump_lights: Array[OmniLight3D] = []
@export var authorization_terminal: Node3D

# ====================================================================================
# INITIALIZATION
# ====================================================================================

func _ready() -> void:
	_initialize_pumps()
	print("FuelPumpSystem: Initialized %d pumps" % MAX_PUMPS)

func _initialize_pumps() -> void:
	for i in range(MAX_PUMPS):
		var pump = PumpData.new()
		pump.pump_id = i + 1
		pump.state = PumpState.IDLE
		pumps.append(pump)

func _process(delta: float) -> void:
	for pump in pumps:
		if pump.state == PumpState.DISPENSING:
			_update_fuel_dispensing(pump, delta)
		_update_pump_display(pump)
		_update_pump_lights(pump)

# ====================================================================================
# AUTHORIZATION
# ====================================================================================

func authorize_pump(pump_id: int, amount: float, prepay: bool = true, payment_method: String = "CASH") -> bool:
	var pump = _get_pump(pump_id)
	if not pump:
		push_warning("Invalid pump ID: %d" % pump_id)
		return false

	if pump.state != PumpState.IDLE and pump.state != PumpState.AWAITING_AUTHORIZATION:
		push_warning("Pump %d is not ready for authorization (state: %s)" % [pump_id, PumpState.keys()[pump.state]])
		return false

	if amount <= 0 or amount > MAX_AUTHORIZATION_AMOUNT:
		push_warning("Invalid authorization amount: $%.2f" % amount)
		return false

	pump.authorized_amount = amount
	pump.customer_prepay = prepay
	pump.payment_method = payment_method
	pump.state = PumpState.AUTHORIZED
	pump.dispensed_gallons = 0.0
	pump.dispensed_cost = 0.0
	pump.error_message = ""

	pump_authorized.emit(pump_id, amount)
	print("Pump %d authorized for $%.2f (%s)" % [pump_id, amount, payment_method])
	return true

func cancel_authorization(pump_id: int) -> bool:
	var pump = _get_pump(pump_id)
	if not pump:
		return false

	if pump.state != PumpState.AUTHORIZED:
		return false

	pump.reset()
	print("Pump %d authorization cancelled" % pump_id)
	return true

# ====================================================================================
# FUEL DISPENSING
# ====================================================================================

func start_dispensing(pump_id: int, fuel_grade: FuelGrade) -> bool:
	var pump = _get_pump(pump_id)
	if not pump:
		return false

	if pump.state != PumpState.AUTHORIZED:
		push_warning("Pump %d not authorized" % pump_id)
		_set_pump_error(pump, "Not Authorized")
		return false

	pump.state = PumpState.DISPENSING
	pump.fuel_grade = fuel_grade
	pump.transaction_start_time = Time.get_ticks_msec() / 1000.0
	pump.current_flow_rate = FUEL_FLOW_RATE

	pump_activated.emit(pump_id)
	print("Pump %d dispensing started - Grade: %s" % [pump_id, FuelGrade.keys()[fuel_grade]])
	return true

func stop_dispensing(pump_id: int) -> bool:
	var pump = _get_pump(pump_id)
	if not pump:
		return false

	if pump.state != PumpState.DISPENSING:
		return false

	pump.state = PumpState.STOPPED
	pump.current_flow_rate = 0.0

	# Create transaction record
	var transaction = _create_transaction_record(pump)
	pump.last_transaction = transaction

	# Update totals
	total_fuel_dispensed_today += pump.dispensed_gallons
	total_revenue_today += pump.dispensed_cost
	transaction_count_today += 1

	pump_stopped.emit(pump_id, pump.dispensed_gallons)
	transaction_completed.emit(pump_id, transaction)

	print("Pump %d stopped - Dispensed: %.2f gal, Cost: $%.2f" % [pump_id, pump.dispensed_gallons, pump.dispensed_cost])
	return true

func _update_fuel_dispensing(pump: PumpData, delta: float) -> void:
	var gallons_this_frame = (pump.current_flow_rate / 60.0) * delta
	var price_per_gallon = _get_price_for_grade(pump.fuel_grade)
	var cost_this_frame = gallons_this_frame * price_per_gallon

	# Check if we've reached authorization limit
	if pump.customer_prepay and (pump.dispensed_cost + cost_this_frame >= pump.authorized_amount):
		var remaining_amount = pump.authorized_amount - pump.dispensed_cost
		gallons_this_frame = remaining_amount / price_per_gallon
		cost_this_frame = remaining_amount

		pump.dispensed_gallons += gallons_this_frame
		pump.dispensed_cost += cost_this_frame

		# Auto-stop when limit reached
		stop_dispensing(pump.pump_id)
		return

	pump.dispensed_gallons += gallons_this_frame
	pump.dispensed_cost += cost_this_frame

func emergency_stop_all() -> void:
	for pump in pumps:
		pump.state = PumpState.EMERGENCY_STOP
		pump.current_flow_rate = 0.0

	emergency_stop_activated.emit()
	print("EMERGENCY STOP ACTIVATED - All pumps disabled")

# ====================================================================================
# PRICING
# ====================================================================================

func _get_price_for_grade(grade: FuelGrade) -> float:
	match grade:
		FuelGrade.REGULAR_87:
			return PRICE_PER_GALLON_REGULAR
		FuelGrade.PLUS_89:
			return PRICE_PER_GALLON_PLUS
		FuelGrade.PREMIUM_91:
			return PRICE_PER_GALLON_PREMIUM
		FuelGrade.DIESEL:
			return PRICE_PER_GALLON_DIESEL
	return PRICE_PER_GALLON_REGULAR

func set_fuel_price(grade: FuelGrade, new_price: float) -> void:
	# In a real implementation, this would update price variables
	print("Price updated for %s: $%.2f/gal" % [FuelGrade.keys()[grade], new_price])

# ====================================================================================
# TRANSACTION RECORDS
# ====================================================================================

func _create_transaction_record(pump: PumpData) -> Dictionary:
	return {
		"pump_id": pump.pump_id,
		"timestamp": Time.get_unix_time_from_system(),
		"fuel_grade": FuelGrade.keys()[pump.fuel_grade],
		"gallons_dispensed": pump.dispensed_gallons,
		"price_per_gallon": _get_price_for_grade(pump.fuel_grade),
		"total_cost": pump.dispensed_cost,
		"payment_method": pump.payment_method,
		"prepay": pump.customer_prepay,
		"authorized_amount": pump.authorized_amount,
		"duration_seconds": (Time.get_ticks_msec() / 1000.0) - pump.transaction_start_time
	}

func get_transaction_history(pump_id: int = -1) -> Array[Dictionary]:
	var history: Array[Dictionary] = []

	if pump_id > 0:
		var pump = _get_pump(pump_id)
		if pump and not pump.last_transaction.is_empty():
			history.append(pump.last_transaction)
	else:
		for pump in pumps:
			if not pump.last_transaction.is_empty():
				history.append(pump.last_transaction)

	return history

# ====================================================================================
# PUMP STATUS & MONITORING
# ====================================================================================

func get_pump_status(pump_id: int) -> Dictionary:
	var pump = _get_pump(pump_id)
	if not pump:
		return {}

	return {
		"pump_id": pump.pump_id,
		"state": PumpState.keys()[pump.state],
		"fuel_grade": FuelGrade.keys()[pump.fuel_grade] if pump.state == PumpState.DISPENSING else "NONE",
		"authorized_amount": pump.authorized_amount,
		"dispensed_gallons": pump.dispensed_gallons,
		"dispensed_cost": pump.dispensed_cost,
		"payment_method": pump.payment_method,
		"error": pump.error_message
	}

func get_all_pump_statuses() -> Array[Dictionary]:
	var statuses: Array[Dictionary] = []
	for pump in pumps:
		statuses.append(get_pump_status(pump.pump_id))
	return statuses

func is_pump_available(pump_id: int) -> bool:
	var pump = _get_pump(pump_id)
	return pump != null and pump.state == PumpState.IDLE

func get_available_pumps() -> Array[int]:
	var available: Array[int] = []
	for pump in pumps:
		if pump.state == PumpState.IDLE:
			available.append(pump.pump_id)
	return available

# ====================================================================================
# ERROR HANDLING
# ====================================================================================

func _set_pump_error(pump: PumpData, error_msg: String) -> void:
	pump.state = PumpState.ERROR
	pump.error_message = error_msg
	pump.current_flow_rate = 0.0

	pump_error.emit(pump.pump_id, error_msg)
	print("Pump %d ERROR: %s" % [pump.pump_id, error_msg])

func clear_pump_error(pump_id: int) -> bool:
	var pump = _get_pump(pump_id)
	if not pump or pump.state != PumpState.ERROR:
		return false

	pump.reset()
	print("Pump %d error cleared" % pump_id)
	return true

# ====================================================================================
# RESET & MAINTENANCE
# ====================================================================================

func reset_pump(pump_id: int) -> bool:
	var pump = _get_pump(pump_id)
	if not pump:
		return false

	pump.reset()
	print("Pump %d reset" % pump_id)
	return true

func complete_transaction(pump_id: int) -> bool:
	"""Complete a stopped transaction and return pump to idle"""
	var pump = _get_pump(pump_id)
	if not pump or pump.state != PumpState.STOPPED:
		return false

	pump.reset()
	print("Pump %d transaction completed, returned to idle" % pump_id)
	return true

# ====================================================================================
# REPORTS
# ====================================================================================

func get_daily_report() -> Dictionary:
	return {
		"total_fuel_dispensed": total_fuel_dispensed_today,
		"total_revenue": total_revenue_today,
		"transaction_count": transaction_count_today,
		"average_transaction": total_revenue_today / max(transaction_count_today, 1),
		"pumps_online": _count_pumps_by_state(PumpState.IDLE) + _count_pumps_by_state(PumpState.AUTHORIZED) + _count_pumps_by_state(PumpState.DISPENSING),
		"pumps_offline": _count_pumps_by_state(PumpState.OFFLINE),
		"pumps_error": _count_pumps_by_state(PumpState.ERROR)
	}

func print_daily_report() -> void:
	var report = get_daily_report()
	print("\n========== FUEL PUMP DAILY REPORT ==========")
	print("Total Fuel Dispensed: %.2f gallons" % report.total_fuel_dispensed)
	print("Total Revenue: $%.2f" % report.total_revenue)
	print("Transaction Count: %d" % report.transaction_count)
	print("Average Transaction: $%.2f" % report.average_transaction)
	print("Pumps Online: %d/%d" % [report.pumps_online, MAX_PUMPS])
	print("Pumps in Error: %d" % report.pumps_error)
	print("===========================================\n")

func reset_daily_totals() -> void:
	total_fuel_dispensed_today = 0.0
	total_revenue_today = 0.0
	transaction_count_today = 0
	print("Daily totals reset")

# ====================================================================================
# DISPLAY UPDATES
# ====================================================================================

func _update_pump_display(pump: PumpData) -> void:
	var display_index = pump.pump_id - 1
	if display_index < 0 or display_index >= pump_displays.size():
		return

	var display = pump_displays[display_index]
	if not display:
		return

	match pump.state:
		PumpState.OFFLINE:
			display.text = "OFFLINE"
		PumpState.IDLE:
			display.text = "READY\nLift Handle"
		PumpState.AWAITING_AUTHORIZATION:
			display.text = "SEE CASHIER"
		PumpState.AUTHORIZED:
			display.text = "AUTHORIZED\n$%.2f" % pump.authorized_amount
		PumpState.DISPENSING:
			display.text = "%.2f GAL\n$%.2f" % [pump.dispensed_gallons, pump.dispensed_cost]
		PumpState.STOPPED:
			display.text = "COMPLETE\n$%.2f" % pump.dispensed_cost
		PumpState.ERROR:
			display.text = "ERROR\n%s" % pump.error_message
		PumpState.EMERGENCY_STOP:
			display.text = "EMERGENCY\nSTOP"

func _update_pump_lights(pump: PumpData) -> void:
	var light_index = pump.pump_id - 1
	if light_index < 0 or light_index >= pump_lights.size():
		return

	var light = pump_lights[light_index]
	if not light:
		return

	match pump.state:
		PumpState.OFFLINE:
			light.light_color = Color.DIM_GRAY
			light.light_energy = 0.5
		PumpState.IDLE:
			light.light_color = Color.GREEN
			light.light_energy = 2.0
		PumpState.AWAITING_AUTHORIZATION:
			light.light_color = Color.YELLOW
			light.light_energy = 2.5
		PumpState.AUTHORIZED:
			light.light_color = Color.CYAN
			light.light_energy = 3.0
		PumpState.DISPENSING:
			light.light_color = Color.BLUE
			light.light_energy = 3.5
		PumpState.STOPPED:
			light.light_color = Color.WHITE
			light.light_energy = 2.0
		PumpState.ERROR, PumpState.EMERGENCY_STOP:
			light.light_color = Color.RED
			light.light_energy = 4.0

# ====================================================================================
# UTILITIES
# ====================================================================================

func _get_pump(pump_id: int) -> PumpData:
	if pump_id < 1 or pump_id > pumps.size():
		return null
	return pumps[pump_id - 1]

func _count_pumps_by_state(state: PumpState) -> int:
	var count = 0
	for pump in pumps:
		if pump.state == state:
			count += 1
	return count

# ====================================================================================
# DEBUG
# ====================================================================================

func simulate_customer_fuel_up(pump_id: int, target_gallons: float = 10.0) -> void:
	"""Debug function to simulate a complete fuel transaction"""
	if not OS.is_debug_build():
		return

	var price_per_gal = PRICE_PER_GALLON_REGULAR
	var auth_amount = target_gallons * price_per_gal * 1.1  # 10% extra

	if authorize_pump(pump_id, auth_amount, true, "CASH"):
		await get_tree().create_timer(0.5).timeout
		if start_dispensing(pump_id, FuelGrade.REGULAR_87):
			# Wait for target gallons to be reached
			while true:
				await get_tree().create_timer(0.1).timeout
				var pump = _get_pump(pump_id)
				if pump.dispensed_gallons >= target_gallons or pump.state != PumpState.DISPENSING:
					break
			stop_dispensing(pump_id)
			await get_tree().create_timer(1.0).timeout
			complete_transaction(pump_id)
