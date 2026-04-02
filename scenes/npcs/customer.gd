extends CharacterBody3D
## Customer NPC with AI behavior
## Navigates to register, makes purchase, and leaves

# ============================================================================
# CONFIGURATION
# ============================================================================

const MOVE_SPEED: float = 2.0
const ROTATION_SPEED: float = 3.0

# ============================================================================
# STATE
# ============================================================================

enum State {
	WALKING_TO_REGISTER,
	AT_REGISTER,
	WAITING_FOR_SERVICE,
	LEAVING,
	EXITED
}

var current_state: State = State.WALKING_TO_REGISTER
var target_position: Vector3 = Vector3.ZERO
var exit_point: Vector3 = Vector3.ZERO

# Customer appearance randomization
var customer_type: int = 0
var is_suspicious: bool = false

# ============================================================================
# SIGNALS
# ============================================================================

signal customer_left
signal transaction_completed(amount: float)

# ============================================================================
# REFERENCES
# ============================================================================

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var interaction_timer: Timer = $InteractionTimer

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	# Randomize appearance
	_randomize_appearance()

	# Find register location
	_find_register_location()

	# Setup navigation
	if navigation_agent:
		navigation_agent.path_desired_distance = 0.5
		navigation_agent.target_desired_distance = 0.5
		navigation_agent.target_position = target_position

	# Setup interaction timer
	if interaction_timer:
		interaction_timer.timeout.connect(_on_interaction_complete)

func _randomize_appearance() -> void:
	"""Randomize customer appearance"""
	customer_type = randi() % 5

	# 10% chance of suspicious customer
	is_suspicious = randf() < 0.1

	# Random color for greybox
	if mesh_instance and mesh_instance.mesh is CapsuleMesh:
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(randf(), randf(), randf())
		mesh_instance.material_override = material

func _find_register_location() -> void:
	"""Find the cash register in the scene"""
	var register = get_node_or_null("/root/MainGame/Plaza/ConvenienceStore/CashRegister")

	if register:
		target_position = register.global_position + Vector3(0, 0, 2.0) # Stand in front

# ============================================================================
# AI BEHAVIOR
# ============================================================================

func _physics_process(delta: float) -> void:
	match current_state:
		State.WALKING_TO_REGISTER:
			_walk_to_target(delta)
		State.AT_REGISTER:
			_at_register()
		State.WAITING_FOR_SERVICE:
			# Just wait
			pass
		State.LEAVING:
			_walk_to_exit(delta)
		State.EXITED:
			pass

func _walk_to_target(delta: float) -> void:
	"""Navigate to register"""
	if not navigation_agent:
		return

	if navigation_agent.is_navigation_finished():
		_arrive_at_register()
		return

	var next_position = navigation_agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()

	# Rotate towards target
	if direction.length() > 0.01:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, ROTATION_SPEED * delta)

	# Move
	velocity = direction * MOVE_SPEED
	move_and_slide()

func _arrive_at_register() -> void:
	"""Customer arrived at register"""
	current_state = State.AT_REGISTER
	velocity = Vector3.ZERO

func _at_register() -> void:
	"""Customer is at register, start transaction"""
	current_state = State.WAITING_FOR_SERVICE

	# Simulate transaction after random delay
	var transaction_time = randf_range(2.0, 5.0)
	interaction_timer.start(transaction_time)

func _on_interaction_complete() -> void:
	"""Transaction complete, customer leaves"""
	# Generate transaction amount
	var amount = randf_range(5.0, 50.0)
	transaction_completed.emit(amount)

	# Start leaving
	current_state = State.LEAVING

	if navigation_agent and exit_point != Vector3.ZERO:
		navigation_agent.target_position = exit_point

func _walk_to_exit(delta: float) -> void:
	"""Navigate to exit"""
	if not navigation_agent:
		_exit_complete()
		return

	if navigation_agent.is_navigation_finished():
		_exit_complete()
		return

	var next_position = navigation_agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()

	# Rotate towards exit
	if direction.length() > 0.01:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, ROTATION_SPEED * delta)

	# Move
	velocity = direction * MOVE_SPEED
	move_and_slide()

func _exit_complete() -> void:
	"""Customer has left"""
	current_state = State.EXITED
	customer_left.emit()

# ============================================================================
# PUBLIC API
# ============================================================================

func get_customer_type() -> int:
	return customer_type

func is_customer_suspicious() -> bool:
	return is_suspicious
