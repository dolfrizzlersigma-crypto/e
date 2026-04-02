extends Node
## Shift management system
## Controls time progression, objectives, and shift flow

# ============================================================================
# CONFIGURATION
# ============================================================================

const SHIFT_START_HOUR: float = 22.0 # 10 PM
const SHIFT_END_HOUR: float = 6.0 # 6 AM
const TIME_SCALE: float = 60.0 # 1 real second = 60 game seconds

# ============================================================================
# STATE
# ============================================================================

var current_time: float = SHIFT_START_HOUR # 24-hour format
var shift_active: bool = false
var shift_number: int = 1
var time_paused: bool = false

# Objectives
var active_objectives: Array = []
var completed_objectives: Array = []
var failed_objectives: Array = []

# Shift statistics
var customers_served: int = 0
var guests_checked_in: int = 0
var incidents_handled: int = 0
var revenue_generated: float = 0.0

# ============================================================================
# SIGNALS
# ============================================================================

signal shift_time_updated(hours: int, minutes: int)
signal objective_added(objective: Dictionary)
signal objective_completed(objective_id: String)
signal shift_phase_changed(phase: String)

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	EventBus.transaction_completed.connect(_on_transaction_completed)
	EventBus.guest_checked_in.connect(_on_guest_checked_in)

# ============================================================================
# TIME PROGRESSION
# ============================================================================

func _process(delta: float) -> void:
	if not shift_active or time_paused:
		return

	_advance_time(delta)
	_check_shift_end()
	_check_shift_phases()

func _advance_time(delta: float) -> void:
	"""Advance game time"""
	var time_delta = (delta * TIME_SCALE) / 3600.0 # Convert to hours

	current_time += time_delta

	# Handle day wrap
	if current_time >= 24.0:
		current_time -= 24.0

	var hours = int(current_time)
	var minutes = int((current_time - hours) * 60.0)

	shift_time_updated.emit(hours, minutes)
	EventBus.time_advanced.emit(hours, minutes)

func _check_shift_end() -> void:
	"""Check if shift should end"""
	# Shift ends at 6 AM
	if current_time >= SHIFT_END_HOUR and current_time < SHIFT_START_HOUR:
		end_shift()

# ============================================================================
# SHIFT CONTROL
# ============================================================================

func start_shift(shift_num: int) -> void:
	"""Start a new shift"""
	shift_number = shift_num
	current_time = SHIFT_START_HOUR
	shift_active = true

	# Reset statistics
	customers_served = 0
	guests_checked_in = 0
	incidents_handled = 0
	revenue_generated = 0.0
	active_objectives.clear()
	completed_objectives.clear()
	failed_objectives.clear()

	_setup_shift_objectives()

	EventBus.shift_started.emit(shift_number)
	print("Shift %d started at %02d:00" % [shift_number, int(SHIFT_START_HOUR)])

func end_shift() -> void:
	"""End the current shift"""
	if not shift_active:
		return

	shift_active = false

	var results = _compile_shift_results()
	EventBus.shift_ended.emit(results)

	print("Shift %d ended" % shift_number)

func _compile_shift_results() -> Dictionary:
	"""Compile end-of-shift results"""
	return {
		"shift_number": shift_number,
		"customers_served": customers_served,
		"guests_checked_in": guests_checked_in,
		"revenue": revenue_generated,
		"objectives_completed": completed_objectives.size(),
		"objectives_failed": failed_objectives.size(),
		"incidents": incidents_handled
	}

# ============================================================================
# SHIFT PHASES
# ============================================================================

func _check_shift_phases() -> void:
	"""Check and trigger shift phase changes"""
	var hour = int(current_time)

	# Different phases affect horror intensity and events
	if hour == 0: # Midnight
		shift_phase_changed.emit("midnight")
	elif hour == 3: # Dead of night
		shift_phase_changed.emit("dead_hours")
	elif hour == 5: # Pre-dawn
		shift_phase_changed.emit("pre_dawn")

# ============================================================================
# OBJECTIVES
# ============================================================================

func _setup_shift_objectives() -> void:
	"""Set up objectives for the shift"""
	add_objective({
		"id": "serve_customers",
		"description": "Serve customers at the register",
		"target": 5,
		"current": 0
	})

	add_objective({
		"id": "check_in_guests",
		"description": "Check in motel guests",
		"target": 2,
		"current": 0
	})

	add_objective({
		"id": "restock_shelves",
		"description": "Restock convenience store",
		"target": 1,
		"current": 0
	})

	add_objective({
		"id": "clean_bathrooms",
		"description": "Clean public restrooms",
		"target": 1,
		"current": 0
	})

func add_objective(objective: Dictionary) -> void:
	"""Add a new objective"""
	active_objectives.append(objective)
	objective_added.emit(objective)

func update_objective_progress(objective_id: String, progress: int) -> void:
	"""Update objective progress"""
	for obj in active_objectives:
		if obj["id"] == objective_id:
			obj["current"] = progress
			if obj["current"] >= obj["target"]:
				complete_objective(objective_id)
			break

func complete_objective(objective_id: String) -> void:
	"""Mark an objective as completed"""
	for i in range(active_objectives.size()):
		if active_objectives[i]["id"] == objective_id:
			var obj = active_objectives.pop_at(i)
			completed_objectives.append(obj)
			objective_completed.emit(objective_id)
			EventBus.task_completed.emit(objective_id)
			break

# ============================================================================
# EVENT HANDLERS
# ============================================================================

func _on_transaction_completed(amount: float, _items: Array) -> void:
	"""Handle transaction completion"""
	customers_served += 1
	revenue_generated += amount
	update_objective_progress("serve_customers", customers_served)

func _on_guest_checked_in(_guest_data: Dictionary, _room_number: int) -> void:
	"""Handle guest check-in"""
	guests_checked_in += 1
	update_objective_progress("check_in_guests", guests_checked_in)

# ============================================================================
# UTILITY
# ============================================================================

func get_time_string() -> String:
	"""Get current time as formatted string"""
	var hours = int(current_time)
	var minutes = int((current_time - hours) * 60.0)
	return "%02d:%02d" % [hours, minutes]

func pause_time() -> void:
	"""Pause time progression"""
	time_paused = true

func resume_time() -> void:
	"""Resume time progression"""
	time_paused = false
