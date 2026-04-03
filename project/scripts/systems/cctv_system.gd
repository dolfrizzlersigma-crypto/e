## CCTVSystem - Security camera monitor system.
## Manages camera feeds, recording, anomaly detection, and evidence collection.
class_name CCTVSystem
extends Node

# --- Signals ---
signal camera_switched(camera_index: int)
signal anomaly_detected(camera_index: int, description: String)
signal evidence_captured(evidence_id: String)
signal feed_corrupted(camera_index: int)
signal feed_restored(camera_index: int)

# --- State ---
var cameras: Array[Dictionary] = []
var active_camera_index: int = 0
var is_monitor_active: bool = false
var recorded_anomalies: Array[Dictionary] = []

# --- Configuration ---
const MAX_CAMERAS: int = 8
const ANOMALY_DETECTION_RANGE: float = 0.7  # Horror intensity threshold
const CORRUPTION_DURATION: float = 10.0


func _ready() -> void:
	add_to_group("cctv")
	add_to_group("cctv_system")
	_initialize_cameras()


## Initialize camera definitions.
func _initialize_cameras() -> void:
	cameras = [
		{
			"id": 0,
			"name": "CAM 1 - Shop Counter",
			"location": "shop",
			"active": true,
			"corrupted": false,
			"has_night_vision": false,
			"corruption_timer": 0.0,
		},
		{
			"id": 1,
			"name": "CAM 2 - Shop Aisles",
			"location": "shop_aisles",
			"active": true,
			"corrupted": false,
			"has_night_vision": false,
			"corruption_timer": 0.0,
		},
		{
			"id": 2,
			"name": "CAM 3 - Motel Lobby",
			"location": "motel_lobby",
			"active": true,
			"corrupted": false,
			"has_night_vision": false,
			"corruption_timer": 0.0,
		},
		{
			"id": 3,
			"name": "CAM 4 - Motel Hallway",
			"location": "motel_hallway",
			"active": true,
			"corrupted": false,
			"has_night_vision": false,
			"corruption_timer": 0.0,
		},
		{
			"id": 4,
			"name": "CAM 5 - Fuel Pumps",
			"location": "fuel_forecourt",
			"active": true,
			"corrupted": false,
			"has_night_vision": false,
			"corruption_timer": 0.0,
		},
		{
			"id": 5,
			"name": "CAM 6 - Parking Lot",
			"location": "parking_lot",
			"active": true,
			"corrupted": false,
			"has_night_vision": false,
			"corruption_timer": 0.0,
		},
		{
			"id": 6,
			"name": "CAM 7 - Dumpster Alley",
			"location": "dumpster_alley",
			"active": false,  # Requires upgrade
			"corrupted": false,
			"has_night_vision": false,
			"corruption_timer": 0.0,
		},
		{
			"id": 7,
			"name": "CAM 8 - Basement Entry",
			"location": "basement",
			"active": false,  # Requires upgrade
			"corrupted": false,
			"has_night_vision": false,
			"corruption_timer": 0.0,
		},
	]

	# Apply upgrades
	if GameManager.has_upgrade("better_cameras"):
		for cam in cameras:
			cam["has_night_vision"] = true
			cam["active"] = true


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	# Update corruption timers
	for cam in cameras:
		if cam["corrupted"]:
			cam["corruption_timer"] -= delta
			if cam["corruption_timer"] <= 0.0:
				cam["corrupted"] = false
				feed_restored.emit(cam["id"])


## Switch to a specific camera feed.
func switch_camera(index: int) -> void:
	if index < 0 or index >= cameras.size():
		return
	if not cameras[index]["active"]:
		return

	active_camera_index = index
	camera_switched.emit(index)


## Cycle to the next active camera.
func next_camera() -> void:
	var start := active_camera_index
	for i in range(1, cameras.size()):
		var idx := (start + i) % cameras.size()
		if cameras[idx]["active"]:
			switch_camera(idx)
			return


## Cycle to the previous active camera.
func prev_camera() -> void:
	var start := active_camera_index
	for i in range(1, cameras.size()):
		var idx := (start - i + cameras.size()) % cameras.size()
		if cameras[idx]["active"]:
			switch_camera(idx)
			return


## Corrupt a camera feed (horror event).
func corrupt_feed(camera_index: int, duration: float = CORRUPTION_DURATION) -> void:
	if camera_index < 0 or camera_index >= cameras.size():
		return
	cameras[camera_index]["corrupted"] = true
	cameras[camera_index]["corruption_timer"] = duration
	feed_corrupted.emit(camera_index)


## Detect an anomaly on a camera (phantom car, doppelganger, etc.).
func trigger_anomaly(camera_index: int, anomaly_type: String, description: String) -> void:
	var anomaly := {
		"camera": camera_index,
		"type": anomaly_type,
		"description": description,
		"time": GameManager.in_game_hour * 100 + GameManager.in_game_minute,
		"shift": GameManager.current_shift,
	}
	recorded_anomalies.append(anomaly)
	anomaly_detected.emit(camera_index, description)

	# Evidence collection
	var evidence_id := "cctv_%s_%d" % [anomaly_type, GameManager.current_shift]
	GameManager.collect_evidence(evidence_id)
	evidence_captured.emit(evidence_id)

	# Increase stress if player is watching
	if is_monitor_active and active_camera_index == camera_index:
		GameManager.stress += 10.0
		GameManager.composure -= 3.0


## Backward-compatible helper for horror events.
func inject_anomaly(camera_index: int, anomaly_type: String) -> void:
	var description := "Unidentified anomaly detected"
	match anomaly_type:
		"doppelganger":
			description = "Figure resembling you is standing behind the counter"
		"phantom_car":
			description = "Vehicle visible on camera but absent from lot"
	trigger_anomaly(camera_index, anomaly_type, description)


## Clear an active anomaly from a camera feed.
func clear_anomaly(camera_index: int) -> void:
	if camera_index < 0 or camera_index >= cameras.size():
		return
	cameras[camera_index]["corrupted"] = false
	cameras[camera_index]["corruption_timer"] = 0.0
	feed_restored.emit(camera_index)


## Show the doppelganger event (Mara visible on camera while player is elsewhere).
func trigger_doppelganger_event() -> void:
	# Find the shop counter camera
	var counter_cam := 0
	trigger_anomaly(counter_cam, "doppelganger",
		"Figure resembling you is standing behind the counter")
	GameManager.stress += 20.0
	GameManager.composure -= 10.0
	DialogueManager.show_subtitle("Mara", "That's... that's me. But I'm right here.")


## Show phantom car event on parking lot camera.
func trigger_phantom_car_event() -> void:
	var parking_cam := 5
	trigger_anomaly(parking_cam, "phantom_car",
		"Vehicle visible on camera but absent from lot")
	GameManager.stress += 8.0


## Get the current camera data.
func get_active_camera() -> Dictionary:
	if active_camera_index < cameras.size():
		return cameras[active_camera_index]
	return {}


## Get all camera statuses for the monitor UI.
func get_all_camera_status() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for cam in cameras:
		result.append({
			"id": cam["id"],
			"name": cam["name"],
			"active": cam["active"],
			"corrupted": cam["corrupted"],
			"has_night_vision": cam["has_night_vision"],
		})
	return result


## Toggle monitor on/off.
func toggle_monitor() -> void:
	is_monitor_active = not is_monitor_active
