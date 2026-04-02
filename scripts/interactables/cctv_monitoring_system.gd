extends Node3D
class_name CCTVMonitoringSystem

## ====================================================================================
## CCTV SECURITY MONITORING SYSTEM
## ====================================================================================
## Multi-camera surveillance system with recording, playback, and anomaly detection
## Supports 16 camera feeds, motion detection, and horror event integration
## ====================================================================================

signal camera_switched(camera_id: int)
signal motion_detected(camera_id: int, location: Vector3)
signal anomaly_detected(camera_id: int, anomaly_type: String)
signal recording_started(camera_id: int)
signal recording_stopped(camera_id: int)
signal playback_started(timestamp: float)
signal system_error(error_message: String)

# ====================================================================================
# CONFIGURATION
# ====================================================================================

const MAX_CAMERAS = 16
const RECORDING_BUFFER_SECONDS = 3600  # 1 hour loop
const MOTION_SENSITIVITY = 0.5
const ANOMALY_CHECK_INTERVAL = 2.0
const MAX_RECORDED_ANOMALIES = 100

# ====================================================================================
# CAMERA DATA
# ====================================================================================

enum CameraState {
	OFFLINE,
	ONLINE,
	RECORDING,
	PLAYBACK,
	ERROR,
	STATIC
}

enum CameraLocation {
	STORE_FRONT,
	STORE_INTERIOR_1,
	STORE_INTERIOR_2,
	STORE_BACK_ROOM,
	CASH_REGISTER,
	PARKING_LOT_FRONT,
	PARKING_LOT_SIDE,
	FUEL_FORECOURT_1,
	FUEL_FORECOURT_2,
	MOTEL_LOBBY,
	MOTEL_HALLWAY_1,
	MOTEL_HALLWAY_2,
	MOTEL_EXTERIOR,
	PERIMETER_NORTH,
	PERIMETER_SOUTH,
	BACK_ALLEY
}

class CameraData:
	var camera_id: int
	var camera_name: String
	var location: CameraLocation
	var state: CameraState = CameraState.ONLINE
	var is_recording: bool = false
	var motion_detected: bool = false
	var last_motion_time: float = 0.0
	var anomaly_detected: bool = false
	var anomaly_type: String = ""
	var signal_quality: float = 1.0  # 0.0 to 1.0
	var pan_angle: float = 0.0
	var tilt_angle: float = 0.0
	var zoom_level: float = 1.0
	var night_vision_enabled: bool = true
	var motion_recording_enabled: bool = true
	var viewport: SubViewport
	var camera_3d: Camera3D
	var recorded_footage: Array[Dictionary] = []

	func reset() -> void:
		motion_detected = false
		anomaly_detected = false
		anomaly_type = ""
		pan_angle = 0.0
		tilt_angle = 0.0
		zoom_level = 1.0

var cameras: Array[CameraData] = []
var current_viewing_camera: int = 0
var split_screen_mode: bool = false
var split_screen_cameras: Array[int] = [0, 1, 2, 3]
var recording_all: bool = true
var anomaly_log: Array[Dictionary] = []

# ====================================================================================
# UI COMPONENTS
# ====================================================================================

@export var main_display: SubViewport
@export var display_label: Label
@export var camera_list_container: VBoxContainer
@export var anomaly_alert_panel: Panel
@export var recording_indicator: ColorRect
@export var timestamp_label: Label

# ====================================================================================
# INITIALIZATION
# ====================================================================================

func _ready() -> void:
	_initialize_camera_system()
	_setup_camera_viewports()
	print("CCTVMonitoringSystem: Initialized %d cameras" % MAX_CAMERAS)

func _initialize_camera_system() -> void:
	# Initialize all cameras
	var camera_configs = [
		{"name": "Store Front", "location": CameraLocation.STORE_FRONT},
		{"name": "Store Interior 1", "location": CameraLocation.STORE_INTERIOR_1},
		{"name": "Store Interior 2", "location": CameraLocation.STORE_INTERIOR_2},
		{"name": "Back Room", "location": CameraLocation.STORE_BACK_ROOM},
		{"name": "Cash Register", "location": CameraLocation.CASH_REGISTER},
		{"name": "Parking Front", "location": CameraLocation.PARKING_LOT_FRONT},
		{"name": "Parking Side", "location": CameraLocation.PARKING_LOT_SIDE},
		{"name": "Fuel Pump 1-4", "location": CameraLocation.FUEL_FORECOURT_1},
		{"name": "Fuel Pump 5-8", "location": CameraLocation.FUEL_FORECOURT_2},
		{"name": "Motel Lobby", "location": CameraLocation.MOTEL_LOBBY},
		{"name": "Motel Hall 1", "location": CameraLocation.MOTEL_HALLWAY_1},
		{"name": "Motel Hall 2", "location": CameraLocation.MOTEL_HALLWAY_2},
		{"name": "Motel Exterior", "location": CameraLocation.MOTEL_EXTERIOR},
		{"name": "Perimeter North", "location": CameraLocation.PERIMETER_NORTH},
		{"name": "Perimeter South", "location": CameraLocation.PERIMETER_SOUTH},
		{"name": "Back Alley", "location": CameraLocation.BACK_ALLEY}
	]

	for i in range(MAX_CAMERAS):
		var cam = CameraData.new()
		cam.camera_id = i
		if i < camera_configs.size():
			cam.camera_name = camera_configs[i].name
			cam.location = camera_configs[i].location
		else:
			cam.camera_name = "Camera %d" % (i + 1)
			cam.location = CameraLocation.STORE_INTERIOR_1
		cam.state = CameraState.ONLINE
		cam.is_recording = recording_all
		cameras.append(cam)

func _setup_camera_viewports() -> void:
	for cam in cameras:
		# Create viewport for each camera
		var viewport = SubViewport.new()
		viewport.size = Vector2(320, 240)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		cam.viewport = viewport

		# Create Camera3D node
		var camera_node = Camera3D.new()
		camera_node.fov = 75.0
		cam.camera_3d = camera_node
		viewport.add_child(camera_node)

func _process(delta: float) -> void:
	_update_camera_feeds(delta)
	_check_for_anomalies()
	_update_ui()

# ====================================================================================
# CAMERA SWITCHING & VIEWING
# ====================================================================================

func switch_to_camera(camera_id: int) -> bool:
	if camera_id < 0 or camera_id >= cameras.size():
		push_warning("Invalid camera ID: %d" % camera_id)
		return false

	var cam = cameras[camera_id]
	if cam.state == CameraState.OFFLINE or cam.state == CameraState.ERROR:
		push_warning("Camera %d is not available" % camera_id)
		_play_static_effect()
		return false

	current_viewing_camera = camera_id
	split_screen_mode = false

	camera_switched.emit(camera_id)
	print("Switched to Camera %d: %s" % [camera_id, cam.camera_name])
	return true

func set_split_screen_mode(camera_ids: Array[int]) -> bool:
	if camera_ids.size() < 2 or camera_ids.size() > 4:
		push_warning("Split screen requires 2-4 cameras")
		return false

	split_screen_cameras = camera_ids
	split_screen_mode = true
	print("Split screen mode enabled: %s" % str(camera_ids))
	return true

func exit_split_screen_mode() -> void:
	split_screen_mode = false
	switch_to_camera(current_viewing_camera)

func next_camera() -> void:
	var next_id = (current_viewing_camera + 1) % cameras.size()
	switch_to_camera(next_id)

func previous_camera() -> void:
	var prev_id = (current_viewing_camera - 1 + cameras.size()) % cameras.size()
	switch_to_camera(prev_id)

# ====================================================================================
# CAMERA CONTROLS
# ====================================================================================

func pan_camera(camera_id: int, angle_delta: float) -> void:
	var cam = _get_camera(camera_id)
	if not cam:
		return

	cam.pan_angle = clamp(cam.pan_angle + angle_delta, -90.0, 90.0)
	if cam.camera_3d:
		cam.camera_3d.rotation_degrees.y = cam.pan_angle

func tilt_camera(camera_id: int, angle_delta: float) -> void:
	var cam = _get_camera(camera_id)
	if not cam:
		return

	cam.tilt_angle = clamp(cam.tilt_angle + angle_delta, -45.0, 45.0)
	if cam.camera_3d:
		cam.camera_3d.rotation_degrees.x = cam.tilt_angle

func zoom_camera(camera_id: int, zoom_delta: float) -> void:
	var cam = _get_camera(camera_id)
	if not cam:
		return

	cam.zoom_level = clamp(cam.zoom_level + zoom_delta, 1.0, 4.0)
	if cam.camera_3d:
		cam.camera_3d.fov = 75.0 / cam.zoom_level

func reset_camera_position(camera_id: int) -> void:
	var cam = _get_camera(camera_id)
	if not cam:
		return

	cam.reset()
	if cam.camera_3d:
		cam.camera_3d.rotation_degrees = Vector3.ZERO
		cam.camera_3d.fov = 75.0

# ====================================================================================
# RECORDING & PLAYBACK
# ====================================================================================

func start_recording(camera_id: int) -> bool:
	var cam = _get_camera(camera_id)
	if not cam or cam.state != CameraState.ONLINE:
		return false

	cam.is_recording = true
	cam.state = CameraState.RECORDING

	recording_started.emit(camera_id)
	print("Recording started: Camera %d" % camera_id)
	return true

func stop_recording(camera_id: int) -> bool:
	var cam = _get_camera(camera_id)
	if not cam or not cam.is_recording:
		return false

	cam.is_recording = false
	cam.state = CameraState.ONLINE

	recording_stopped.emit(camera_id)
	print("Recording stopped: Camera %d" % camera_id)
	return true

func start_recording_all() -> void:
	recording_all = true
	for cam in cameras:
		if cam.state == CameraState.ONLINE:
			start_recording(cam.camera_id)
	print("Recording started on all cameras")

func stop_recording_all() -> void:
	recording_all = false
	for cam in cameras:
		if cam.is_recording:
			stop_recording(cam.camera_id)
	print("Recording stopped on all cameras")

func playback_footage(camera_id: int, seconds_ago: float) -> bool:
	var cam = _get_camera(camera_id)
	if not cam:
		return false

	cam.state = CameraState.PLAYBACK
	var timestamp = Time.get_unix_time_from_system() - seconds_ago

	playback_started.emit(timestamp)
	print("Playback started: Camera %d, %d seconds ago" % [camera_id, seconds_ago])

	# Simulated playback - in real implementation would load recorded frames
	await get_tree().create_timer(10.0).timeout
	cam.state = CameraState.ONLINE
	return true

# ====================================================================================
# MOTION DETECTION
# ====================================================================================

func _update_camera_feeds(delta: float) -> void:
	for cam in cameras:
		if cam.state == CameraState.RECORDING or cam.state == CameraState.ONLINE:
			_process_motion_detection(cam)

		# Simulate signal degradation
		if randf() < 0.001:  # 0.1% chance per frame
			_introduce_signal_interference(cam)

func _process_motion_detection(cam: CameraData) -> void:
	if not cam.motion_recording_enabled:
		return

	# Simulate motion detection
	# In real implementation, would analyze camera feed pixels
	if randf() < 0.02:  # 2% chance per frame to detect motion
		cam.motion_detected = true
		cam.last_motion_time = Time.get_ticks_msec() / 1000.0

		# Record motion event
		var motion_event = {
			"camera_id": cam.camera_id,
			"timestamp": Time.get_unix_time_from_system(),
			"location": _get_simulated_location(cam.location)
		}
		cam.recorded_footage.append(motion_event)

		motion_detected.emit(cam.camera_id, motion_event.location)

	# Clear motion flag after delay
	if cam.motion_detected and (Time.get_ticks_msec() / 1000.0 - cam.last_motion_time) > 2.0:
		cam.motion_detected = false

# ====================================================================================
# ANOMALY DETECTION (HORROR INTEGRATION)
# ====================================================================================

var _anomaly_check_timer: float = 0.0

func _check_for_anomalies() -> void:
	_anomaly_check_timer += get_process_delta_time()

	if _anomaly_check_timer < ANOMALY_CHECK_INTERVAL:
		return

	_anomaly_check_timer = 0.0

	# Check each camera for anomalies
	for cam in cameras:
		if cam.state == CameraState.ONLINE or cam.state == CameraState.RECORDING:
			_detect_camera_anomaly(cam)

func _detect_camera_anomaly(cam: CameraData) -> void:
	# Simulate anomaly detection for horror events
	# In real implementation, would be triggered by game events

	if randf() < 0.001:  # Very rare anomalies
		var anomaly_types = [
			"FIGURE_DETECTED",
			"TEMPORAL_ANOMALY",
			"SIGNAL_CORRUPTION",
			"IMPOSSIBLE_GEOMETRY",
			"SHADOW_MOVEMENT",
			"CUSTOMER_DUPLICATION",
			"REALITY_GLITCH"
		]

		var anomaly = anomaly_types[randi() % anomaly_types.size()]
		_trigger_anomaly(cam, anomaly)

func _trigger_anomaly(cam: CameraData, anomaly_type: String) -> void:
	cam.anomaly_detected = true
	cam.anomaly_type = anomaly_type

	var anomaly_record = {
		"camera_id": cam.camera_id,
		"camera_name": cam.camera_name,
		"timestamp": Time.get_unix_time_from_system(),
		"anomaly_type": anomaly_type,
		"signal_quality": cam.signal_quality
	}

	anomaly_log.append(anomaly_record)

	# Limit anomaly log size
	if anomaly_log.size() > MAX_RECORDED_ANOMALIES:
		anomaly_log.pop_front()

	anomaly_detected.emit(cam.camera_id, anomaly_type)
	print("ANOMALY DETECTED: Camera %d - %s" % [cam.camera_id, anomaly_type])

	# Visual effects for anomaly
	match anomaly_type:
		"SIGNAL_CORRUPTION":
			_introduce_heavy_static(cam)
		"TEMPORAL_ANOMALY":
			_trigger_playback_glitch(cam)
		"REALITY_GLITCH":
			_trigger_reality_distortion(cam)

	# Auto-clear after delay
	await get_tree().create_timer(5.0).timeout
	cam.anomaly_detected = false
	cam.anomaly_type = ""

# ====================================================================================
# VISUAL EFFECTS
# ====================================================================================

func _introduce_signal_interference(cam: CameraData) -> void:
	cam.signal_quality = randf_range(0.5, 0.9)

	await get_tree().create_timer(randf_range(0.5, 2.0)).timeout
	cam.signal_quality = 1.0

func _introduce_heavy_static(cam: CameraData) -> void:
	cam.signal_quality = randf_range(0.1, 0.3)
	cam.state = CameraState.STATIC

	await get_tree().create_timer(randf_range(2.0, 5.0)).timeout
	cam.signal_quality = 1.0
	cam.state = CameraState.ONLINE

func _play_static_effect() -> void:
	# Display static on main monitor
	print("Displaying static effect")

func _trigger_playback_glitch(cam: CameraData) -> void:
	# Show previous footage mixed with current
	print("Playback glitch on Camera %d" % cam.camera_id)

func _trigger_reality_distortion(cam: CameraData) -> void:
	# Visual distortion effect
	print("Reality distortion on Camera %d" % cam.camera_id)

# ====================================================================================
# CAMERA STATUS
# ====================================================================================

func get_camera_status(camera_id: int) -> Dictionary:
	var cam = _get_camera(camera_id)
	if not cam:
		return {}

	return {
		"camera_id": cam.camera_id,
		"camera_name": cam.camera_name,
		"location": CameraLocation.keys()[cam.location],
		"state": CameraState.keys()[cam.state],
		"is_recording": cam.is_recording,
		"motion_detected": cam.motion_detected,
		"anomaly_detected": cam.anomaly_detected,
		"anomaly_type": cam.anomaly_type,
		"signal_quality": cam.signal_quality,
		"pan_angle": cam.pan_angle,
		"tilt_angle": cam.tilt_angle,
		"zoom_level": cam.zoom_level
	}

func get_all_camera_statuses() -> Array[Dictionary]:
	var statuses: Array[Dictionary] = []
	for cam in cameras:
		statuses.append(get_camera_status(cam.camera_id))
	return statuses

func get_cameras_with_motion() -> Array[int]:
	var active: Array[int] = []
	for cam in cameras:
		if cam.motion_detected:
			active.append(cam.camera_id)
	return active

func get_cameras_with_anomalies() -> Array[int]:
	var anomalous: Array[int] = []
	for cam in cameras:
		if cam.anomaly_detected:
			anomalous.append(cam.camera_id)
	return anomalous

# ====================================================================================
# ANOMALY LOG
# ====================================================================================

func get_anomaly_log() -> Array[Dictionary]:
	return anomaly_log.duplicate()

func get_recent_anomalies(count: int = 10) -> Array[Dictionary]:
	var recent: Array[Dictionary] = []
	var start_index = max(0, anomaly_log.size() - count)
	for i in range(start_index, anomaly_log.size()):
		recent.append(anomaly_log[i])
	return recent

func clear_anomaly_log() -> void:
	anomaly_log.clear()
	print("Anomaly log cleared")

# ====================================================================================
# SYSTEM MANAGEMENT
# ====================================================================================

func set_camera_offline(camera_id: int) -> void:
	var cam = _get_camera(camera_id)
	if cam:
		cam.state = CameraState.OFFLINE
		print("Camera %d set offline" % camera_id)

func set_camera_online(camera_id: int) -> void:
	var cam = _get_camera(camera_id)
	if cam and cam.state == CameraState.OFFLINE:
		cam.state = CameraState.ONLINE
		print("Camera %d set online" % camera_id)

func reboot_camera(camera_id: int) -> void:
	var cam = _get_camera(camera_id)
	if not cam:
		return

	cam.state = CameraState.OFFLINE
	cam.reset()

	await get_tree().create_timer(3.0).timeout
	cam.state = CameraState.ONLINE
	cam.signal_quality = 1.0
	print("Camera %d rebooted" % camera_id)

func system_reboot() -> void:
	print("Rebooting CCTV system...")

	for cam in cameras:
		cam.state = CameraState.OFFLINE

	await get_tree().create_timer(5.0).timeout

	for cam in cameras:
		cam.state = CameraState.ONLINE
		cam.reset()

	print("CCTV system online")

# ====================================================================================
# UI UPDATES
# ====================================================================================

func _update_ui() -> void:
	if timestamp_label:
		timestamp_label.text = Time.get_datetime_string_from_system()

	if recording_indicator:
		recording_indicator.visible = recording_all

	if display_label:
		var cam = _get_camera(current_viewing_camera)
		if cam:
			display_label.text = "CAM %02d: %s" % [cam.camera_id + 1, cam.camera_name]

# ====================================================================================
# UTILITIES
# ====================================================================================

func _get_camera(camera_id: int) -> CameraData:
	if camera_id < 0 or camera_id >= cameras.size():
		return null
	return cameras[camera_id]

func _get_simulated_location(location: CameraLocation) -> Vector3:
	# Return simulated 3D location based on camera location
	match location:
		CameraLocation.STORE_FRONT:
			return Vector3(0, 1, -15)
		CameraLocation.FUEL_FORECOURT_1:
			return Vector3(-25, 1, 0)
		CameraLocation.MOTEL_LOBBY:
			return Vector3(25, 1, -5)
	return Vector3.ZERO

# ====================================================================================
# DEBUG
# ====================================================================================

func trigger_test_anomaly(camera_id: int) -> void:
	if not OS.is_debug_build():
		return

	var cam = _get_camera(camera_id)
	if cam:
		_trigger_anomaly(cam, "FIGURE_DETECTED")

func simulate_camera_failure(camera_id: int) -> void:
	if not OS.is_debug_build():
		return

	var cam = _get_camera(camera_id)
	if cam:
		cam.state = CameraState.ERROR
		system_error.emit("Camera %d hardware failure" % camera_id)
