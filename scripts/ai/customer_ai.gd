extends CharacterBody3D
## Customer AI behavior

# ============================================================================
# CUSTOMER DATA
# ============================================================================

var customer_data: Dictionary = {}
var is_anomaly: bool = false
var items_to_purchase: Array = []

# ============================================================================
# STATE
# ============================================================================

enum State {
	ENTERING,
	BROWSING,
	GOING_TO_REGISTER,
	WAITING_AT_REGISTER,
	LEAVING,
	IDLE
}

var current_state: State = State.ENTERING
var target_position: Vector3 = Vector3.ZERO
var movement_speed: float = 1.5

# ============================================================================
# NAVIGATION
# ============================================================================

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D if has_node("NavigationAgent3D") else null

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	_setup_customer()

func _setup_customer() -> void:
	"""Initialize customer with random behavior"""
	# Generate random items to purchase
	var item_count = randi() % 3 + 1
	for i in range(item_count):
		items_to_purchase.append({
			"id": "snack_chips",
			"price": 1.99
		})

	# Set initial state
	current_state = State.BROWSING

# ============================================================================
# PROCESS
# ============================================================================

func _physics_process(delta: float) -> void:
	_update_state(delta)
	_move_towards_target(delta)

func _update_state(delta: float) -> void:
	"""Update customer behavior based on current state"""
	match current_state:
		State.ENTERING:
			_state_entering()
		State.BROWSING:
			_state_browsing()
		State.GOING_TO_REGISTER:
			_state_going_to_register()
		State.WAITING_AT_REGISTER:
			_state_waiting_at_register()
		State.LEAVING:
			_state_leaving()

func _move_towards_target(delta: float) -> void:
	"""Move towards target position"""
	if navigation_agent and not navigation_agent.is_navigation_finished():
		var next_position = navigation_agent.get_next_path_position()
		var direction = (next_position - global_position).normalized()

		velocity = direction * movement_speed
		move_and_slide()

# ============================================================================
# STATE BEHAVIORS
# ============================================================================

func _state_entering() -> void:
	"""Customer entering the store"""
	# Navigate to a browsing position
	_set_random_browse_position()
	current_state = State.BROWSING

func _state_browsing() -> void:
	"""Customer browsing the store"""
	# Browse for a random amount of time
	await get_tree().create_timer(randf_range(5.0, 15.0)).timeout
	current_state = State.GOING_TO_REGISTER

func _state_going_to_register() -> void:
	"""Customer going to register"""
	_navigate_to_register()
	current_state = State.WAITING_AT_REGISTER

func _state_waiting_at_register() -> void:
	"""Customer waiting at register"""
	# Wait for cashier to process transaction
	# This would be triggered by the cash register system
	pass

func _state_leaving() -> void:
	"""Customer leaving the store"""
	_navigate_to_exit()
	await get_tree().create_timer(5.0).timeout
	queue_free()

# ============================================================================
# NAVIGATION HELPERS
# ============================================================================

func _set_random_browse_position() -> void:
	"""Set a random position in the browsing area"""
	target_position = Vector3(
		randf_range(-5.0, 5.0),
		global_position.y,
		randf_range(-5.0, 5.0)
	)

	if navigation_agent:
		navigation_agent.target_position = target_position

func _navigate_to_register() -> void:
	"""Navigate to the cash register"""
	# Find register position (would be set by level)
	target_position = Vector3(0, global_position.y, -5)

	if navigation_agent:
		navigation_agent.target_position = target_position

func _navigate_to_exit() -> void:
	"""Navigate to the exit"""
	target_position = Vector3(0, global_position.y, 10)

	if navigation_agent:
		navigation_agent.target_position = target_position

# ============================================================================
# PUBLIC API
# ============================================================================

func complete_transaction() -> void:
	"""Called when transaction is complete"""
	current_state = State.LEAVING

func set_anomaly(anomaly_type: String) -> void:
	"""Mark customer as anomalous"""
	is_anomaly = true
	customer_data["anomaly_type"] = anomaly_type

func get_items() -> Array:
	"""Get items customer wants to purchase"""
	return items_to_purchase
