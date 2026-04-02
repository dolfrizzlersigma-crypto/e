extends Node3D
## Customer spawning system
## Manages NPC customer spawning, despawning, and flow control

# ============================================================================
# CONFIGURATION
# ============================================================================

const CUSTOMER_SCENE = preload("res://scenes/npcs/customer.tscn")

@export var min_spawn_interval: float = 30.0 # 30 seconds
@export var max_spawn_interval: float = 120.0 # 2 minutes
@export var max_active_customers: int = 5
@export var spawn_enabled: bool = true

# ============================================================================
# SPAWN POINTS
# ============================================================================

@onready var spawn_points: Array = []
@onready var despawn_points: Array = []

# ============================================================================
# STATE
# ============================================================================

var active_customers: Array = []
var spawn_timer: float = 0.0
var next_spawn_time: float = 60.0

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	_collect_spawn_points()
	_schedule_next_spawn()

	# Listen for shift events
	EventBus.shift_started.connect(_on_shift_started)
	EventBus.shift_ended.connect(_on_shift_ended)

func _collect_spawn_points() -> void:
	"""Find all spawn and despawn markers in the scene"""
	var spawn_parent = get_node_or_null("../SpawnPoints")
	var despawn_parent = get_node_or_null("../DespawnPoints")

	if spawn_parent:
		for child in spawn_parent.get_children():
			if child is Marker3D or child is Node3D:
				spawn_points.append(child)

	if despawn_parent:
		for child in despawn_parent.get_children():
			if child is Marker3D or child is Node3D:
				despawn_points.append(child)

	# If no spawn points found, create defaults
	if spawn_points.is_empty():
		push_warning("No spawn points found, creating default")

# ============================================================================
# SPAWNING
# ============================================================================

func _process(delta: float) -> void:
	if not spawn_enabled:
		return

	spawn_timer += delta

	if spawn_timer >= next_spawn_time:
		_try_spawn_customer()
		_schedule_next_spawn()
		spawn_timer = 0.0

func _schedule_next_spawn() -> void:
	"""Schedule the next customer spawn"""
	next_spawn_time = randf_range(min_spawn_interval, max_spawn_interval)

func _try_spawn_customer() -> void:
	"""Attempt to spawn a new customer"""
	# Don't spawn if at max capacity
	if active_customers.size() >= max_active_customers:
		return

	# Don't spawn if no spawn points
	if spawn_points.is_empty():
		return

	# Pick random spawn point
	var spawn_point = spawn_points.pick_random()

	# Create customer instance
	var customer = CUSTOMER_SCENE.instantiate()
	customer.position = spawn_point.global_position

	# Add to scene
	get_parent().add_child(customer)
	active_customers.append(customer)

	# Connect to customer signals
	customer.customer_left.connect(_on_customer_left.bind(customer))
	customer.transaction_completed.connect(_on_customer_transaction.bind(customer))

	# Assign despawn point
	if not despawn_points.is_empty():
		customer.exit_point = despawn_points.pick_random().global_position

	print("Customer spawned at ", spawn_point.name)

# ============================================================================
# CUSTOMER MANAGEMENT
# ============================================================================

func _on_customer_left(customer: Node) -> void:
	"""Handle customer leaving"""
	if customer in active_customers:
		active_customers.erase(customer)
	customer.queue_free()

func _on_customer_transaction(amount: float, customer: Node) -> void:
	"""Handle customer completing transaction"""
	EventBus.transaction_completed.emit(amount, [])

# ============================================================================
# SHIFT MANAGEMENT
# ============================================================================

func _on_shift_started(shift_number: int) -> void:
	"""Enable spawning when shift starts"""
	spawn_enabled = true
	_schedule_next_spawn()
	spawn_timer = 0.0

func _on_shift_ended(results: Dictionary) -> void:
	"""Stop spawning and clear customers when shift ends"""
	spawn_enabled = false

	# Remove all active customers
	for customer in active_customers:
		if is_instance_valid(customer):
			customer.queue_free()

	active_customers.clear()

# ============================================================================
# PUBLIC API
# ============================================================================

func force_spawn_customer() -> void:
	"""Force spawn a customer immediately"""
	_try_spawn_customer()

func get_customer_count() -> int:
	"""Get number of active customers"""
	return active_customers.size()

func set_spawn_rate(min_time: float, max_time: float) -> void:
	"""Adjust spawn rate"""
	min_spawn_interval = min_time
	max_spawn_interval = max_time
