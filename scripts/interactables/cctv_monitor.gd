extends BaseInteractable
## CCTV monitor system
## Allows viewing security camera feeds throughout the plaza

# ============================================================================
# CONFIGURATION
# ============================================================================

var camera_feeds: Dictionary = {
	"cam_1": {"name": "Store Interior", "active": true},
	"cam_2": {"name": "Parking Lot", "active": true},
	"cam_3": {"name": "Gas Pumps", "active": true},
	"cam_4": {"name": "Motel Exterior", "active": true},
	"cam_5": {"name": "Back Alley", "active": true},
	"cam_6": {"name": "Room 4 Door", "active": false} # Horror camera
}

# ============================================================================
# STATE
# ============================================================================

var monitor_open: bool = false
var current_camera: String = "cam_1"
var anomaly_detected: bool = false

# ============================================================================
# CAMERA OBJECTS
# ============================================================================

var camera_nodes: Dictionary = {}

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	super._ready()
	interaction_prompt = "View Security Cameras"

	# Find camera nodes in scene
	_find_camera_nodes()

	# Listen for power events
	EventBus.power_zone_changed.connect(_on_power_changed)

func _find_camera_nodes() -> void:
	"""Locate camera nodes in the scene"""
	# Cameras would be Camera3D nodes placed throughout the scene
	var cameras_parent = get_node_or_null("/root/MainGame/Cameras")

	if cameras_parent:
		for child in cameras_parent.get_children():
			if child is Camera3D:
				camera_nodes[child.name] = child

# ============================================================================
# INTERACTION
# ============================================================================

func interact() -> void:
	"""Open CCTV monitor UI"""
	monitor_open = true

	# Show monitor UI
	var ui = _create_monitor_ui()
	if ui:
		get_tree().root.add_child(ui)

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	await _wait_for_monitor_close()

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	monitor_open = false

func _wait_for_monitor_close() -> void:
	"""Wait for monitor to be closed"""
	while monitor_open:
		await get_tree().process_frame

# ============================================================================
# CCTV MONITOR UI
# ============================================================================

func _create_monitor_ui() -> Control:
	"""Create CCTV monitor interface"""
	var ui = Control.new()
	ui.name = "CCTVMonitorUI"
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Background
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(900, 650)
	panel.position = Vector2(-450, -325)
	ui.add_child(panel)

	# Title
	var title = Label.new()
	title.text = "SECURITY CAMERA SYSTEM"
	title.position = Vector2(20, 20)
	title.add_theme_font_size_override("font_size", 26)
	panel.add_child(title)

	# Camera feed display area
	var feed_panel = Panel.new()
	feed_panel.name = "FeedPanel"
	feed_panel.position = Vector2(20, 70)
	feed_panel.custom_minimum_size = Vector2(640, 480)
	panel.add_child(feed_panel)

	# Camera feed placeholder
	var feed_label = Label.new()
	feed_label.name = "FeedLabel"
	feed_label.text = "Camera Feed: " + camera_feeds[current_camera]["name"]
	feed_label.position = Vector2(10, 10)
	feed_label.size = Vector2(620, 460)
	feed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feed_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feed_label.add_theme_font_size_override("font_size", 24)
	feed_panel.add_child(feed_label)

	# Status indicator
	var status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "[RECORDING]"
	status_label.position = Vector2(500, 560)
	status_label.add_theme_color_override("font_color", Color.RED)
	panel.add_child(status_label)

	# Camera selection buttons
	var cam_y = 70
	for cam_id in camera_feeds:
		var cam_data = camera_feeds[cam_id]

		var cam_button = Button.new()
		cam_button.name = "CamButton_" + cam_id
		cam_button.text = cam_data["name"]
		cam_button.position = Vector2(680, cam_y)
		cam_button.size = Vector2(200, 40)
		cam_button.pressed.connect(_on_camera_selected.bind(cam_id))

		# Highlight current camera
		if cam_id == current_camera:
			cam_button.modulate = Color(0.5, 1.0, 0.5)

		# Disable if inactive
		if not cam_data["active"]:
			cam_button.disabled = true
			cam_button.text += " [OFFLINE]"

		panel.add_child(cam_button)
		cam_y += 50

	# Anomaly alert
	var alert_label = Label.new()
	alert_label.name = "AlertLabel"
	alert_label.text = ""
	alert_label.position = Vector2(680, 400)
	alert_label.size = Vector2(200, 100)
	alert_label.add_theme_font_size_override("font_size", 16)
	alert_label.add_theme_color_override("font_color", Color(1, 0.5, 0))
	alert_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	panel.add_child(alert_label)

	# Close button
	var close_button = Button.new()
	close_button.text = "CLOSE"
	close_button.position = Vector2(680, 590)
	close_button.size = Vector2(200, 45)
	close_button.pressed.connect(_on_monitor_close)
	panel.add_child(close_button)

	# Record button (for easter egg/achievement)
	var record_button = Button.new()
	record_button.text = "SAVE RECORDING"
	record_button.position = Vector2(680, 530)
	record_button.size = Vector2(200, 45)
	record_button.pressed.connect(_on_save_recording)
	panel.add_child(record_button)

	return ui

# ============================================================================
# CAMERA CONTROLS
# ============================================================================

func _on_camera_selected(cam_id: String) -> void:
	"""Switch to selected camera"""
	if not camera_feeds[cam_id]["active"]:
		return

	current_camera = cam_id

	# Update UI
	var ui = get_tree().root.get_node_or_null("CCTVMonitorUI")
	if not ui:
		return

	# Update feed label
	var feed_label = ui.get_node_or_null("Panel/FeedPanel/FeedLabel")
	if feed_label:
		feed_label.text = "Camera Feed: " + camera_feeds[cam_id]["name"]

	# Update camera button highlights
	for other_cam_id in camera_feeds:
		var button = ui.get_node_or_null("Panel/CamButton_" + other_cam_id)
		if button:
			if other_cam_id == cam_id:
				button.modulate = Color(0.5, 1.0, 0.5)
			else:
				button.modulate = Color.WHITE

	# Check for horror events on this camera
	_check_camera_anomalies(cam_id)

	AudioManager.play_sfx("camera_switch", global_position)

func _check_camera_anomalies(cam_id: String) -> void:
	"""Check if camera is showing anomalies"""
	# Random chance of anomaly
	if randf() < 0.15:
		_trigger_camera_anomaly(cam_id)

	# Special check for Room 4 camera
	if cam_id == "cam_6" and camera_feeds[cam_id]["active"]:
		# Room 4 camera should NEVER be active
		EventBus.anomaly_detected.emit("room_4_camera_active", global_position)

func _trigger_camera_anomaly(cam_id: String) -> void:
	"""Display anomaly on camera"""
	var ui = get_tree().root.get_node_or_null("CCTVMonitorUI")
	if not ui:
		return

	var alert_label = ui.get_node_or_null("Panel/AlertLabel")
	if alert_label:
		var anomaly_messages = [
			"MOTION DETECTED",
			"UNIDENTIFIED FIGURE",
			"SIGNAL INTERFERENCE",
			"CAMERA MALFUNCTION",
			"PLAYBACK ERROR",
			"TIMESTAMP ANOMALY"
		]

		alert_label.text = "⚠ " + anomaly_messages.pick_random()
		anomaly_detected = true

		# Clear after delay
		await get_tree().create_timer(3.0).timeout
		if alert_label and is_instance_valid(alert_label):
			alert_label.text = ""
		anomaly_detected = false

func _on_save_recording() -> void:
	"""Save current camera recording (evidence system)"""
	var evidence_data = {
		"type": "camera_recording",
		"camera": current_camera,
		"timestamp": Time.get_ticks_msec(),
		"anomaly": anomaly_detected
	}

	EventBus.evidence_collected.emit(evidence_data)

	# Show confirmation
	var ui = get_tree().root.get_node_or_null("CCTVMonitorUI")
	if ui:
		var alert_label = ui.get_node_or_null("Panel/AlertLabel")
		if alert_label:
			alert_label.text = "✓ Recording saved to evidence log"
			alert_label.modulate = Color.GREEN

			await get_tree().create_timer(2.0).timeout
			if alert_label and is_instance_valid(alert_label):
				alert_label.text = ""
				alert_label.modulate = Color(1, 0.5, 0)

func _on_monitor_close() -> void:
	"""Close the monitor"""
	var ui = get_tree().root.get_node_or_null("CCTVMonitorUI")
	if ui:
		ui.queue_free()

	monitor_open = false

# ============================================================================
# POWER MANAGEMENT
# ============================================================================

func _on_power_changed(zone_id: String, powered: bool) -> void:
	"""Handle power changes to security system"""
	if zone_id == "security_cameras":
		for cam_id in camera_feeds:
			camera_feeds[cam_id]["active"] = powered

		# Update UI if open
		if monitor_open:
			_refresh_monitor_ui()

func _refresh_monitor_ui() -> void:
	"""Refresh monitor UI after power change"""
	var ui = get_tree().root.get_node_or_null("CCTVMonitorUI")
	if not ui:
		return

	# Update all camera buttons
	for cam_id in camera_feeds:
		var button = ui.get_node_or_null("Panel/CamButton_" + cam_id)
		if button:
			var cam_data = camera_feeds[cam_id]
			button.disabled = not cam_data["active"]

			if not cam_data["active"]:
				button.text = cam_data["name"] + " [OFFLINE]"
			else:
				button.text = cam_data["name"]

# ============================================================================
# PUBLIC API
# ============================================================================

func enable_camera(cam_id: String) -> void:
	"""Enable a specific camera (for horror events)"""
	if camera_feeds.has(cam_id):
		camera_feeds[cam_id]["active"] = true

func disable_camera(cam_id: String) -> void:
	"""Disable a specific camera"""
	if camera_feeds.has(cam_id):
		camera_feeds[cam_id]["active"] = false

func is_viewing_camera(cam_id: String) -> bool:
	"""Check if player is viewing specific camera"""
	return monitor_open and current_camera == cam_id
