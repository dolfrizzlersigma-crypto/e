## PlayerController - First-person character controller with sprint, crouch, lean, and flashlight.
## Handles movement, camera, interaction raycasting, and immersive stat effects.
class_name PlayerController
extends CharacterBody3D

# --- Signals ---
signal interacted_with(target: Node)
signal item_picked_up(item: Node)
signal flashlight_toggled(is_on: bool)

# --- Exported Properties ---
@export_group("Movement")
@export var walk_speed: float = 3.5
@export var sprint_speed: float = 5.5
@export var crouch_speed: float = 1.8
@export var acceleration: float = 10.0
@export var deceleration: float = 12.0
@export var gravity_strength: float = 9.8

@export_group("Camera")
@export var mouse_sensitivity: float = 0.002
@export var max_pitch: float = 85.0
@export var lean_angle: float = 15.0
@export var lean_offset: float = 0.4
@export var lean_speed: float = 8.0

@export_group("Interaction")
@export var interact_distance: float = 2.5
@export var highlight_distance: float = 3.5

@export_group("Physical")
@export var standing_height: float = 1.7
@export var crouch_height: float = 1.0

# --- Node References ---
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight
@onready var interact_ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var crouch_check_ray: RayCast3D = $CrouchCheckRay

# --- State ---
var is_sprinting: bool = false
var is_crouching: bool = false
var is_flashlight_on: bool = false
var current_lean: float = 0.0  # -1.0 left, 0.0 center, 1.0 right
var target_lean: float = 0.0
var current_speed: float = 0.0
var looking_at: Node = null  # Currently highlighted interactable
var camera_shake_intensity: float = 0.0
var camera_shake_timer: float = 0.0
var base_fov: float = 75.0

# --- Head bob ---
var head_bob_timer: float = 0.0
var head_bob_amplitude: float = 0.02
var head_bob_frequency: float = 2.0

# --- Immersive effects ---
var fatigue_sway: float = 0.0
var stress_pulse: float = 0.0


func _ready() -> void:
	camera.current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	flashlight.visible = false
	interact_ray.target_position = Vector3(0, 0, -interact_distance)
	_apply_control_settings()
	if not SettingsManager.settings_changed.is_connected(_on_settings_changed):
		SettingsManager.settings_changed.connect(_on_settings_changed)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if GameManager.current_state == GameManager.GameState.PLAYING and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_handle_mouse_look(event)


func _unhandled_input(event: InputEvent) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	# Flashlight toggle
	if event.is_action_pressed("flashlight"):
		_toggle_flashlight()

	# Interact
	if event.is_action_pressed("interact"):
		_try_interact()

	# Crouch toggle
	if event.is_action_pressed("crouch"):
		_toggle_crouch()


func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	_handle_gravity(delta)
	_handle_movement(delta)
	_handle_sprint()
	_handle_lean(delta)
	_handle_head_bob(delta)
	_handle_camera_shake(delta)
	_handle_immersive_effects(delta)
	_update_interaction_highlight()

	move_and_slide()


## Apply a camera shake effect.
func apply_camera_shake(intensity: float, duration: float) -> void:
	camera_shake_intensity = intensity
	camera_shake_timer = duration


## Get the current movement speed factor (0.0 = standing still, 1.0 = full sprint).
func get_speed_factor() -> float:
	return velocity.length() / sprint_speed if sprint_speed > 0 else 0.0


# --- Private Methods ---

func _handle_mouse_look(event: InputEventMouseMotion) -> void:
	# Horizontal rotation (yaw)
	rotate_y(-event.relative.x * mouse_sensitivity)
	# Vertical rotation (pitch)
	var vertical_look := -event.relative.y * mouse_sensitivity
	if SettingsManager.invert_y:
		vertical_look *= -1.0
	head.rotate_x(vertical_look)
	head.rotation.x = clampf(head.rotation.x, deg_to_rad(-max_pitch), deg_to_rad(max_pitch))


func _handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity_strength * delta


func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Determine target speed
	var target_speed := walk_speed
	if is_sprinting and not is_crouching:
		target_speed = sprint_speed
	elif is_crouching:
		target_speed = crouch_speed

	# Apply fatigue penalty
	var fatigue_mult := 1.0 - (GameManager.fatigue / GameManager.MAX_STAT) * 0.3
	target_speed *= fatigue_mult

	if direction:
		velocity.x = lerpf(velocity.x, direction.x * target_speed, acceleration * delta)
		velocity.z = lerpf(velocity.z, direction.z * target_speed, acceleration * delta)
	else:
		velocity.x = lerpf(velocity.x, 0.0, deceleration * delta)
		velocity.z = lerpf(velocity.z, 0.0, deceleration * delta)

	current_speed = Vector2(velocity.x, velocity.z).length()


func _handle_sprint() -> void:
	is_sprinting = Input.is_action_pressed("sprint") and not is_crouching
	# Sprinting increases fatigue faster
	if is_sprinting and current_speed > walk_speed * 0.5:
		GameManager.fatigue += get_physics_process_delta_time() * 0.8


func _toggle_crouch() -> void:
	if is_crouching:
		# Check if we can stand up
		if crouch_check_ray and crouch_check_ray.is_colliding():
			return  # Blocked above
		is_crouching = false
	else:
		is_crouching = true
		is_sprinting = false

	# Adjust collision shape height
	var shape: CapsuleShape3D = collision_shape.shape as CapsuleShape3D
	if shape:
		var target_height := crouch_height if is_crouching else standing_height
		var tween := create_tween()
		tween.tween_property(shape, "height", target_height, 0.2)
		tween.parallel().tween_property(head, "position:y",
			target_height * 0.9 if not is_crouching else crouch_height * 0.9, 0.2)


func _handle_lean(delta: float) -> void:
	target_lean = 0.0
	if Input.is_action_pressed("lean_left"):
		target_lean = -1.0
	elif Input.is_action_pressed("lean_right"):
		target_lean = 1.0

	current_lean = lerpf(current_lean, target_lean, lean_speed * delta)

	# Apply lean rotation and offset
	camera.rotation.z = lerpf(camera.rotation.z, deg_to_rad(lean_angle * -current_lean), lean_speed * delta)
	camera.position.x = lerpf(camera.position.x, lean_offset * current_lean, lean_speed * delta)


func _handle_head_bob(delta: float) -> void:
	if not is_on_floor() or current_speed < 0.5:
		head_bob_timer = 0.0
		return

	var bob_freq := head_bob_frequency
	var bob_amp := head_bob_amplitude
	if is_sprinting:
		bob_freq *= 1.4
		bob_amp *= 1.5
	elif is_crouching:
		bob_freq *= 0.7
		bob_amp *= 0.5
	bob_amp *= SettingsManager.headbob_intensity

	head_bob_timer += delta * bob_freq * current_speed
	var bob_offset := sin(head_bob_timer * TAU) * bob_amp
	camera.position.y = lerpf(camera.position.y, bob_offset, 10.0 * delta)


func _handle_camera_shake(delta: float) -> void:
	if camera_shake_timer > 0:
		camera_shake_timer -= delta
		var shake := Vector2(
			randf_range(-1.0, 1.0) * camera_shake_intensity,
			randf_range(-1.0, 1.0) * camera_shake_intensity
		)
		camera.rotation.x += shake.y * delta
		camera.rotation.z += shake.x * delta
	else:
		camera_shake_intensity = 0.0


func _handle_immersive_effects(delta: float) -> void:
	# Fatigue causes subtle camera sway
	if GameManager.fatigue > 50.0:
		fatigue_sway += delta * 0.5
		var sway_amount := (GameManager.fatigue - 50.0) / 100.0 * 0.005
		camera.rotation.z += sin(fatigue_sway) * sway_amount

	# Stress causes subtle FOV pulse
	if GameManager.stress > 60.0:
		stress_pulse += delta * 2.0
		var pulse_amount := (GameManager.stress - 60.0) / 100.0 * 2.0
		camera.fov = lerpf(camera.fov, base_fov + sin(stress_pulse) * pulse_amount, 3.0 * delta)
	else:
		camera.fov = lerpf(camera.fov, base_fov, 3.0 * delta)


func _toggle_flashlight() -> void:
	is_flashlight_on = not is_flashlight_on
	flashlight.visible = is_flashlight_on
	flashlight_toggled.emit(is_flashlight_on)


func _try_interact() -> void:
	if interact_ray.is_colliding():
		var target := _find_interactable_target(interact_ray.get_collider())
		if target and target.has_method("interact"):
			target.interact(self)
			interacted_with.emit(target)


func _update_interaction_highlight() -> void:
	var new_target: Node = null

	if interact_ray.is_colliding():
		var collider := _find_interactable_target(interact_ray.get_collider())
		if collider and collider.has_method("interact"):
			var distance := global_position.distance_to(interact_ray.get_collision_point())
			if distance <= highlight_distance:
				new_target = collider

	if new_target != looking_at:
		# Remove highlight from old target
		if looking_at and looking_at.has_method("set_highlighted"):
			looking_at.set_highlighted(false)
		# Add highlight to new target
		if new_target and new_target.has_method("set_highlighted"):
			new_target.set_highlighted(true)
		looking_at = new_target


func _apply_control_settings() -> void:
	mouse_sensitivity = SettingsManager.mouse_sensitivity
	base_fov = SettingsManager.fov
	camera.fov = base_fov


func _find_interactable_target(collider: Object) -> Node:
	if not (collider is Node):
		return null

	var current: Node = collider as Node
	var current_scene := get_tree().current_scene
	var depth := 0
	while current and current != current_scene and depth < 8:
		if current.has_method("interact"):
			return current
		current = current.get_parent()
		depth += 1

	return null


func _on_settings_changed(category: String) -> void:
	if category == "controls" or category == "graphics":
		_apply_control_settings()
