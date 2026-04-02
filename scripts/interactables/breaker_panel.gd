extends BaseInteractable
## Electrical breaker panel
## Controls power to different zones of the plaza

# ============================================================================
# CONFIGURATION
# ============================================================================

var power_zones: Dictionary = {
	"store_lights": {"active": true, "label": "Store Lights"},
	"motel_lights": {"active": true, "label": "Motel Exterior"},
	"gas_pumps": {"active": true, "label": "Gas Pumps"},
	"parking_lot": {"active": true, "label": "Parking Lights"},
	"back_area": {"active": true, "label": "Back Area"},
	"security_cameras": {"active": true, "label": "Security System"}
}

# ============================================================================
# STATE
# ============================================================================

var panel_open: bool = false
var main_breaker_active: bool = true

# ============================================================================
# REFERENCES
# ============================================================================

@onready var power_grid = get_node_or_null("/root/PowerGrid")

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	super._ready()
	interaction_prompt = "Access Breaker Panel"

	# Listen for power events
	EventBus.power_outage.connect(_on_power_outage)

# ============================================================================
# INTERACTION
# ============================================================================

func interact() -> void:
	"""Open breaker panel UI"""
	panel_open = true

	# Show panel UI
	var ui = _create_panel_ui()
	if ui:
		get_tree().root.add_child(ui)

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	await _wait_for_panel_close()

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	panel_open = false

func _wait_for_panel_close() -> void:
	"""Wait for panel to be closed"""
	while panel_open:
		await get_tree().process_frame

# ============================================================================
# BREAKER PANEL UI
# ============================================================================

func _create_panel_ui() -> Control:
	"""Create breaker panel interface"""
	var ui = Control.new()
	ui.name = "BreakerPanelUI"
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Background
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(500, 600)
	panel.position = Vector2(-250, -300)
	ui.add_child(panel)

	# Title
	var title = Label.new()
	title.text = "ELECTRICAL PANEL"
	title.position = Vector2(20, 20)
	title.add_theme_font_size_override("font_size", 26)
	panel.add_child(title)

	# Main breaker
	var main_label = Label.new()
	main_label.text = "MAIN BREAKER"
	main_label.position = Vector2(20, 70)
	main_label.add_theme_font_size_override("font_size", 20)
	panel.add_child(main_label)

	var main_button = Button.new()
	main_button.name = "MainBreaker"
	main_button.text = "ON" if main_breaker_active else "OFF"
	main_button.position = Vector2(250, 65)
	main_button.size = Vector2(220, 40)
	main_button.pressed.connect(_on_main_breaker_toggled)
	_update_breaker_button_style(main_button, main_breaker_active)
	panel.add_child(main_button)

	# Individual breakers
	var y_pos = 130
	var breaker_index = 0

	for zone_id in power_zones:
		var zone = power_zones[zone_id]

		var zone_label = Label.new()
		zone_label.text = zone["label"]
		zone_label.position = Vector2(40, y_pos + 5)
		zone_label.add_theme_font_size_override("font_size", 18)
		panel.add_child(zone_label)

		var zone_button = Button.new()
		zone_button.name = "Breaker_" + zone_id
		zone_button.text = "ON" if zone["active"] else "OFF"
		zone_button.position = Vector2(270, y_pos)
		zone_button.size = Vector2(200, 35)
		zone_button.pressed.connect(_on_zone_breaker_toggled.bind(zone_id))
		zone_button.disabled = not main_breaker_active
		_update_breaker_button_style(zone_button, zone["active"])
		panel.add_child(zone_button)

		y_pos += 50
		breaker_index += 1

	# Warning label
	var warning = Label.new()
	warning.text = "WARNING: Turning off critical systems\nmay affect safety and operations"
	warning.position = Vector2(20, 500)
	warning.size = Vector2(460, 60)
	warning.add_theme_font_size_override("font_size", 14)
	warning.add_theme_color_override("font_color", Color(1, 0.8, 0))
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD
	panel.add_child(warning)

	# Close button
	var close_button = Button.new()
	close_button.text = "CLOSE"
	close_button.position = Vector2(20, 545)
	close_button.size = Vector2(460, 40)
	close_button.pressed.connect(_on_panel_close)
	panel.add_child(close_button)

	return ui

func _update_breaker_button_style(button: Button, is_on: bool) -> void:
	"""Update breaker button visual style"""
	if is_on:
		button.modulate = Color(0.5, 1.0, 0.5)
	else:
		button.modulate = Color(1.0, 0.5, 0.5)

# ============================================================================
# BREAKER CONTROLS
# ============================================================================

func _on_main_breaker_toggled() -> void:
	"""Toggle main breaker"""
	main_breaker_active = !main_breaker_active

	# Update UI
	var ui = get_tree().root.get_node_or_null("BreakerPanelUI")
	if ui:
		var main_button = ui.get_node_or_null("Panel/MainBreaker")
		if main_button:
			main_button.text = "ON" if main_breaker_active else "OFF"
			_update_breaker_button_style(main_button, main_breaker_active)

		# Disable/enable zone breakers
		for zone_id in power_zones:
			var zone_button = ui.get_node_or_null("Panel/Breaker_" + zone_id)
			if zone_button:
				zone_button.disabled = not main_breaker_active

	# If turning off main, turn off all zones
	if not main_breaker_active:
		for zone_id in power_zones:
			power_zones[zone_id]["active"] = false
			_apply_zone_power(zone_id, false)

	# Trigger event
	if main_breaker_active:
		EventBus.power_restored.emit()
	else:
		EventBus.power_outage.emit()

	AudioManager.play_sfx("breaker_switch", global_position)

func _on_zone_breaker_toggled(zone_id: String) -> void:
	"""Toggle individual zone breaker"""
	if not main_breaker_active:
		return

	power_zones[zone_id]["active"] = !power_zones[zone_id]["active"]

	# Update UI button
	var ui = get_tree().root.get_node_or_null("BreakerPanelUI")
	if ui:
		var button = ui.get_node_or_null("Panel/Breaker_" + zone_id)
		if button:
			button.text = "ON" if power_zones[zone_id]["active"] else "OFF"
			_update_breaker_button_style(button, power_zones[zone_id]["active"])

	# Apply power change
	_apply_zone_power(zone_id, power_zones[zone_id]["active"])

	AudioManager.play_sfx("breaker_switch", global_position)

func _on_panel_close() -> void:
	"""Close the panel"""
	var ui = get_tree().root.get_node_or_null("BreakerPanelUI")
	if ui:
		ui.queue_free()

	panel_open = false

# ============================================================================
# POWER MANAGEMENT
# ============================================================================

func _apply_zone_power(zone_id: String, powered: bool) -> void:
	"""Apply power state to zone"""
	if power_grid:
		power_grid.set_zone_power(zone_id, powered)

	# Emit zone-specific event
	EventBus.power_zone_changed.emit(zone_id, powered)

	# Special handling for critical zones
	if zone_id == "security_cameras" and not powered:
		EventBus.anomaly_detected.emit("cameras_disabled", global_position)

func _on_power_outage() -> void:
	"""Handle external power outage"""
	main_breaker_active = false

	for zone_id in power_zones:
		power_zones[zone_id]["active"] = false

# ============================================================================
# PUBLIC API
# ============================================================================

func is_zone_powered(zone_id: String) -> bool:
	"""Check if zone has power"""
	return main_breaker_active and power_zones.get(zone_id, {}).get("active", false)

func force_zone_power(zone_id: String, powered: bool) -> void:
	"""Force a zone's power state (for horror events)"""
	if power_zones.has(zone_id):
		power_zones[zone_id]["active"] = powered
		_apply_zone_power(zone_id, powered)
