extends Node
## Horror Event Implementation
## Contains actual horror events with full logic

# ============================================================================
# EVENT IMPLEMENTATIONS
# ============================================================================

class_name HorrorEvents

# Event 01: Phantom Customer
static func event_phantom_customer(context: Dictionary) -> void:
	"""Customer appears when player isn't looking, disappears when they look back"""
	var player = context.get("player")
	var spawn_point = context.get("spawn_point", Vector3.ZERO)

	if not player:
		return

	# Spawn customer behind player
	var customer_scene = load("res://scenes/npcs/customer.tscn")
	var phantom = customer_scene.instantiate()
	phantom.position = spawn_point
	phantom.name = "PhantomCustomer"

	context.get("world").add_child(phantom)

	# Make customer disappear if player looks at it
	await _watch_for_player_look(player, phantom)

	if is_instance_valid(phantom):
		phantom.queue_free()

	EventBus.horror_event_completed.emit("phantom_customer")

# Event 02: Lights Flicker
static func event_lights_flicker(context: Dictionary) -> void:
	"""All lights flicker ominously for 30 seconds"""
	var world = context.get("world")
	var lights = _find_all_lights(world)

	for i in range(15): # Flicker 15 times
		# Turn lights off
		for light in lights:
			if is_instance_valid(light):
				light.visible = false

		await context.get("tree").create_timer(randf_range(0.1, 0.3)).timeout

		# Turn lights on
		for light in lights:
			if is_instance_valid(light):
				light.visible = true

		await context.get("tree").create_timer(randf_range(0.2, 0.5)).timeout

	EventBus.horror_event_completed.emit("lights_flicker")

# Event 03: Mysterious Phone Call
static func event_phone_call(context: Dictionary) -> void:
	"""Phone rings at the register, plays eerie message"""
	var register = context.get("register")

	if not register:
		return

	# Play phone ring sound
	AudioManager.play_sfx("phone_ring", register.global_position)

	# Wait for player to be near register
	var player = context.get("player")
	await _wait_for_player_proximity(player, register.global_position, 3.0)

	# Play creepy message
	var messages = [
		"They're watching you...",
		"Room 4 is waiting...",
		"You shouldn't be here...",
		"Check the cameras...",
		"Don't trust the customers..."
	]

	EventBus.dialogue_triggered.emit({
		"speaker": "Unknown Caller",
		"text": messages.pick_random(),
		"voice": "distorted"
	})

	EventBus.horror_event_completed.emit("phone_call")

# Event 04: Room 4 Knocking
static func event_room_4_knocking(context: Dictionary) -> void:
	"""Loud knocking from inside boarded-up Room 4"""
	var room_4_door = context.get("room_4_door")

	if not room_4_door:
		return

	# Play knocking sounds
	for i in range(12):
		AudioManager.play_sfx("door_knock_heavy", room_4_door.global_position)
		await context.get("tree").create_timer(randf_range(0.5, 2.0)).timeout

	# Final loud bang
	AudioManager.play_sfx("door_bang", room_4_door.global_position)

	# Trigger camera glitch
	EventBus.anomaly_detected.emit("room_4_activity", room_4_door.global_position)

	EventBus.horror_event_completed.emit("room_4_knocking")

# Event 05: Shadow Figure
static func event_shadow_figure(context: Dictionary) -> void:
	"""Dark humanoid figure appears in periphery, disappears when looked at"""
	var player = context.get("player")
	var spawn_positions = context.get("shadow_spawns", [])

	if spawn_positions.is_empty():
		return

	var spawn_pos = spawn_positions.pick_random()

	# Create shadow figure
	var shadow = _create_shadow_figure()
	shadow.position = spawn_pos
	context.get("world").add_child(shadow)

	# Make it disappear after 10 seconds or if player gets close
	var timer = 0.0
	while timer < 10.0:
		await context.get("tree").process_frame
		timer += context.get("tree").root.get_process_delta_time()

		if is_instance_valid(player) and is_instance_valid(shadow):
			var distance = player.global_position.distance_to(shadow.global_position)
			if distance < 5.0:
				break

	if is_instance_valid(shadow):
		shadow.queue_free()

	EventBus.horror_event_completed.emit("shadow_figure")

# Event 06: Time Loop
static func event_time_loop(context: Dictionary) -> void:
	"""Time suddenly jumps backward, events repeat"""
	var shift_manager = context.get("shift_manager")

	if not shift_manager:
		return

	var original_time = shift_manager.current_time

	# Jump time back 30 minutes
	shift_manager.current_time -= 0.5

	# Visual glitch effect
	EventBus.screen_glitch.emit(2.0)

	# Show notification
	EventBus.anomaly_detected.emit("time_anomaly", Vector3.ZERO)

	# Wait 5 seconds
	await context.get("tree").create_timer(5.0).timeout

	EventBus.horror_event_completed.emit("time_loop")

# Event 07: Possessed Customer
static func event_possessed_customer(context: Dictionary) -> void:
	"""Customer behaves unnaturally, speaks in distorted voice"""
	var customers = context.get("active_customers", [])

	if customers.is_empty():
		return

	var possessed = customers.pick_random()

	if not is_instance_valid(possessed):
		return

	# Make customer stop and stare
	possessed.current_state = possessed.State.WAITING_FOR_SERVICE
	possessed.velocity = Vector3.ZERO

	# Rotate to face player
	var player = context.get("player")
	if player:
		var direction = (player.global_position - possessed.global_position).normalized()
		possessed.rotation.y = atan2(direction.x, direction.z)

	await context.get("tree").create_timer(3.0).timeout

	# Creepy dialogue
	EventBus.dialogue_triggered.emit({
		"speaker": "Customer",
		"text": "You look tired. Maybe you should rest... in Room 4.",
		"voice": "distorted"
	})

	await context.get("tree").create_timer(5.0).timeout

	# Customer leaves quickly
	if is_instance_valid(possessed):
		possessed.current_state = possessed.State.LEAVING

	EventBus.horror_event_completed.emit("possessed_customer")

# Event 08: Power Surge
static func event_power_surge(context: Dictionary) -> void:
	"""All electronics glitch, some systems fail"""
	var breaker_panel = context.get("breaker_panel")

	# Flicker all lights rapidly
	EventBus.power_outage.emit()

	await context.get("tree").create_timer(0.5).timeout

	EventBus.power_restored.emit()

	# Random breakers trip
	if breaker_panel:
		var zones = ["store_lights", "security_cameras", "parking_lot"]
		var zone_to_trip = zones.pick_random()
		breaker_panel.force_zone_power(zone_to_trip, false)

	# Glitch screens
	EventBus.screen_glitch.emit(3.0)

	EventBus.horror_event_completed.emit("power_surge")

# Event 09: Doppelganger Customer
static func event_doppelganger(context: Dictionary) -> void:
	"""Same customer checks in twice with slight differences"""
	var motel_booking = context.get("motel_booking")
	var customer_spawner = context.get("customer_spawner")

	if not motel_booking or not customer_spawner:
		return

	# Create first customer
	customer_spawner.force_spawn_customer()

	await context.get("tree").create_timer(30.0).timeout

	# Create identical customer with same name but wrong details
	customer_spawner.force_spawn_customer()

	# Trigger anomaly detection
	EventBus.anomaly_detected.emit("duplicate_customer", Vector3.ZERO)

	EventBus.horror_event_completed.emit("doppelganger")

# Event 10: Security Footage Playback
static func event_footage_playback(context: Dictionary) -> void:
	"""CCTV shows recording from the future or impossible event"""
	var cctv = context.get("cctv_monitor")

	if not cctv:
		return

	# Enable the Room 4 camera (should be impossible)
	cctv.enable_camera("cam_6")

	# Show notification
	EventBus.anomaly_detected.emit("impossible_camera_feed", Vector3.ZERO)

	# Disable after 15 seconds
	await context.get("tree").create_timer(15.0).timeout

	cctv.disable_camera("cam_6")

	EventBus.horror_event_completed.emit("footage_playback")

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

static func _watch_for_player_look(player: Node, target: Node) -> void:
	"""Wait for player to look at target"""
	var timeout = 30.0
	var timer = 0.0

	while timer < timeout:
		if not is_instance_valid(player) or not is_instance_valid(target):
			return

		# Check if player is looking at target
		var camera = player.get_node_or_null("Head/Camera3D")
		if camera:
			var direction_to_target = (target.global_position - camera.global_position).normalized()
			var camera_forward = -camera.global_transform.basis.z

			var dot = camera_forward.dot(direction_to_target)

			# Player is looking at target
			if dot > 0.7:
				return

		await player.get_tree().process_frame
		timer += player.get_tree().root.get_process_delta_time()

static func _wait_for_player_proximity(player: Node, position: Vector3, distance: float) -> void:
	"""Wait for player to get close to position"""
	var timeout = 60.0
	var timer = 0.0

	while timer < timeout:
		if not is_instance_valid(player):
			return

		var dist = player.global_position.distance_to(position)
		if dist <= distance:
			return

		await player.get_tree().process_frame
		timer += player.get_tree().root.get_process_delta_time()

static func _find_all_lights(world: Node) -> Array:
	"""Find all Light3D nodes in world"""
	var lights = []

	func find_lights_recursive(node: Node) -> void:
		if node is Light3D:
			lights.append(node)

		for child in node.get_children():
			find_lights_recursive(child)

	if world:
		find_lights_recursive(world)

	return lights

static func _create_shadow_figure() -> Node3D:
	"""Create a shadow figure entity"""
	var shadow = Node3D.new()
	shadow.name = "ShadowFigure"

	# Add mesh
	var mesh_instance = MeshInstance3D.new()
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.4
	capsule.height = 2.0
	mesh_instance.mesh = capsule

	# Dark material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.BLACK
	material.emission_enabled = true
	material.emission = Color(0.1, 0, 0.1)
	mesh_instance.material_override = material

	shadow.add_child(mesh_instance)

	return shadow
