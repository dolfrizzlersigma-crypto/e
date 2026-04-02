extends CharacterBody3D
## First-person player controller
## Handles movement, crouching, sprinting, and camera control

# ============================================================================
# MOVEMENT SETTINGS
# ============================================================================

@export_group("Movement")
@export var walk_speed: float = 3.0
@export var sprint_speed: float = 5.0
@export var crouch_speed: float = 1.5
@export var acceleration: float = 10.0
@export var friction: float = 10.0
@export var air_acceleration: float = 5.0

@export_group("Jump")
@export var jump_velocity: float = 4.5
@export var coyote_time: float = 0.1

@export_group("Crouch")
@export var crouch_height: float = 0.7
@export var stand_height: float = 2.0
@export var crouch_speed_multiplier: float = 0.5

@export_group("Head Bob")
@export var head_bob_enabled: bool = true
@export var head_bob_frequency: float = 2.0
@export var head_bob_amplitude: float = 0.05

# ============================================================================
# REFERENCES
# ============================================================================

@onready var camera: Camera3D = $Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var interaction_raycast: RayCast3D = $Camera3D/InteractionRayCast
@onready var flashlight: SpotLight3D = $Camera3D/Flashlight

# ============================================================================
# STATE VARIABLES
# ============================================================================

var is_sprinting: bool = false
var is_crouching: bool = false
var flashlight_on: bool = false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var time_since_grounded: float = 0.0
var head_bob_time: float = 0.0

# Player stats
var fatigue: float = 0.0
var stress: float = 0.0
var fatigue_modifier: float = 1.0

# Camera
var mouse_sensitivity: float = 0.002
var camera_rotation: Vector2 = Vector2.ZERO

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	print("PlayerController: Initializing...")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_setup_collision()
	flashlight.visible = false
	print("PlayerController: Ready")

func _setup_collision() -> void:
	"""Set up collision shape"""
	if collision_shape and collision_shape.shape:
		var shape = collision_shape.shape as CapsuleShape3D
		if shape:
			shape.height = stand_height

# ============================================================================
# INPUT
# ============================================================================

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_handle_mouse_look(event)

	if event.is_action_pressed("flashlight"):
		_toggle_flashlight()

func _handle_mouse_look(event: InputEventMouseMotion) -> void:
	"""Handle mouse look"""
	mouse_sensitivity = Settings.get_setting("mouse_sensitivity") * 0.002
	var invert_y = Settings.get_setting("invert_y")

	camera_rotation.x -= event.relative.y * mouse_sensitivity
	camera_rotation.y -= event.relative.x * mouse_sensitivity

	# Clamp vertical rotation
	camera_rotation.x = clamp(camera_rotation.x, -PI/2, PI/2)

	# Apply rotation
	camera.rotation.x = camera_rotation.x
	rotation.y = camera_rotation.y

# ============================================================================
# PHYSICS PROCESS
# ============================================================================

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_crouch(delta)
	_handle_sprint()
	_update_head_bob(delta)
	_apply_fatigue_effects()

func _handle_movement(delta: float) -> void:
	"""Handle player movement"""
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
		time_since_grounded += delta
	else:
		time_since_grounded = 0.0

	# Handle jump
	if Input.is_action_just_pressed("jump") and (is_on_floor() or time_since_grounded < coyote_time):
		velocity.y = jump_velocity

	# Get input direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Calculate target speed
	var target_speed = walk_speed
	if is_sprinting and not is_crouching:
		target_speed = sprint_speed
	elif is_crouching:
		target_speed = crouch_speed

	# Apply fatigue modifier
	target_speed *= fatigue_modifier

	# Apply acceleration/friction
	if direction:
		var accel = acceleration if is_on_floor() else air_acceleration
		velocity.x = move_toward(velocity.x, direction.x * target_speed, accel * delta)
		velocity.z = move_toward(velocity.z, direction.z * target_speed, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)

	move_and_slide()

func _handle_crouch(delta: float) -> void:
	"""Handle crouching"""
	var was_crouching = is_crouching
	is_crouching = Input.is_action_pressed("crouch")

	if is_crouching != was_crouching:
		_transition_crouch(delta)

func _transition_crouch(delta: float) -> void:
	"""Animate crouch transition"""
	var target_height = crouch_height if is_crouching else stand_height

	if collision_shape and collision_shape.shape:
		var shape = collision_shape.shape as CapsuleShape3D
		if shape:
			shape.height = lerp(shape.height, target_height, 10.0 * delta)

	# Adjust camera height
	var target_y = -0.3 if is_crouching else 0.0
	camera.position.y = lerp(camera.position.y, target_y, 10.0 * delta)

func _handle_sprint() -> void:
	"""Handle sprinting"""
	is_sprinting = Input.is_action_pressed("sprint") and velocity.length() > 0.1

	# Sprinting increases fatigue slowly
	if is_sprinting:
		_modify_fatigue(0.01)

# ============================================================================
# HEAD BOB
# ============================================================================

func _update_head_bob(delta: float) -> void:
	"""Update head bob animation"""
	if not head_bob_enabled or not Settings.get_setting("head_bob"):
		return

	if is_on_floor() and velocity.length() > 0.1:
		head_bob_time += delta * velocity.length() * head_bob_frequency

		var bob_offset = Vector3.ZERO
		bob_offset.y = sin(head_bob_time) * head_bob_amplitude
		bob_offset.x = cos(head_bob_time * 0.5) * head_bob_amplitude * 0.5

		camera.position.x = lerp(camera.position.x, bob_offset.x, 10.0 * delta)
		camera.position.z = lerp(camera.position.z, bob_offset.y, 10.0 * delta)
	else:
		head_bob_time = 0.0
		camera.position.x = lerp(camera.position.x, 0.0, 10.0 * delta)
		camera.position.z = lerp(camera.position.z, 0.0, 10.0 * delta)

# ============================================================================
# FLASHLIGHT
# ============================================================================

func _toggle_flashlight() -> void:
	"""Toggle flashlight on/off"""
	flashlight_on = !flashlight_on
	flashlight.visible = flashlight_on
	AudioManager.play_sfx("flashlight_click")

# ============================================================================
# PLAYER STATS
# ============================================================================

func _modify_fatigue(amount: float) -> void:
	"""Modify player fatigue"""
	fatigue = clamp(fatigue + amount, 0.0, 100.0)
	_update_fatigue_modifier()
	EventBus.player_fatigue_changed.emit(fatigue)

func _modify_stress(amount: float) -> void:
	"""Modify player stress"""
	stress = clamp(stress + amount, 0.0, 100.0)
	EventBus.player_stress_changed.emit(stress)

func _update_fatigue_modifier() -> void:
	"""Update movement speed based on fatigue"""
	# Fatigue reduces movement speed gradually
	fatigue_modifier = 1.0 - (fatigue / 100.0) * 0.3 # Max 30% reduction

func _apply_fatigue_effects() -> void:
	"""Apply visual effects based on fatigue"""
	if fatigue > 70.0:
		# Add camera shake or vignette at high fatigue
		pass

# ============================================================================
# UTILITY
# ============================================================================

func set_mouse_captured(captured: bool) -> void:
	"""Set mouse capture mode"""
	if captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func teleport(new_position: Vector3) -> void:
	"""Teleport player to a new position"""
	global_position = new_position
	velocity = Vector3.ZERO
