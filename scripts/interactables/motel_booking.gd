extends BaseInteractable
## Motel booking computer system

# ============================================================================
# ROOM DATA
# ============================================================================

const MAX_ROOMS: int = 6
var room_occupancy: Dictionary = {
	1: null,
	2: null,
	3: null,
	# Room 4 is boarded up
	5: null,
	6: null
}

var room_4_boarded: bool = true

# ============================================================================
# STATE
# ============================================================================

var current_guest: Dictionary = {}
var booking_interface_open: bool = false

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	super._ready()
	interaction_prompt = "Check In Guest"

# ============================================================================
# INTERACTION
# ============================================================================

func _on_interact() -> void:
	_open_booking_interface()

func _open_booking_interface() -> void:
	"""Open the motel booking interface"""
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	booking_interface_open = true

	# Create and show booking UI
	var ui = _create_booking_ui()
	if ui:
		get_tree().root.add_child(ui)

func _close_booking_interface() -> void:
	"""Close the booking interface"""
	var ui = get_tree().root.get_node_or_null("MotelBookingUI")
	if ui:
		ui.queue_free()

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	booking_interface_open = false

func _create_booking_ui() -> Control:
	"""Create motel booking UI"""
	var ui = Control.new()
	ui.name = "MotelBookingUI"
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Background
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(700, 550)
	panel.position = Vector2(-350, -275)
	ui.add_child(panel)

	# Title
	var title = Label.new()
	title.text = "EXIT 13 MOTEL - CHECK IN SYSTEM"
	title.position = Vector2(20, 20)
	title.add_theme_font_size_override("font_size", 26)
	panel.add_child(title)

	# Room status display
	var status_label = Label.new()
	status_label.text = "ROOM STATUS:"
	status_label.position = Vector2(20, 70)
	status_label.add_theme_font_size_override("font_size", 20)
	panel.add_child(status_label)

	# Display each room
	var y_pos = 110
	for room_num in [1, 2, 3, 4, 5, 6]:
		var room_label = Label.new()
		var status = "AVAILABLE"
		var color = Color.GREEN

		if room_num == 4:
			status = "BOARDED UP"
			color = Color.RED
		elif is_room_occupied(room_num):
			status = "OCCUPIED"
			color = Color.YELLOW

		room_label.text = "Room %d: %s" % [room_num, status]
		room_label.position = Vector2(40, y_pos)
		room_label.add_theme_font_size_override("font_size", 18)
		room_label.modulate = color
		panel.add_child(room_label)

		y_pos += 35

	# Guest name input
	var name_label = Label.new()
	name_label.text = "Guest Name:"
	name_label.position = Vector2(20, 340)
	name_label.add_theme_font_size_override("font_size", 18)
	panel.add_child(name_label)

	var name_input = LineEdit.new()
	name_input.name = "GuestNameInput"
	name_input.position = Vector2(150, 335)
	name_input.size = Vector2(250, 35)
	name_input.placeholder_text = "Enter guest name"
	panel.add_child(name_input)

	# ID number input
	var id_label = Label.new()
	id_label.text = "ID Number:"
	id_label.position = Vector2(20, 390)
	id_label.add_theme_font_size_override("font_size", 18)
	panel.add_child(id_label)

	var id_input = LineEdit.new()
	id_input.name = "GuestIDInput"
	id_input.position = Vector2(150, 385)
	id_input.size = Vector2(250, 35)
	id_input.placeholder_text = "Enter ID number"
	panel.add_child(id_input)

	# Nights staying
	var nights_label = Label.new()
	nights_label.text = "Nights:"
	nights_label.position = Vector2(20, 440)
	nights_label.add_theme_font_size_override("font_size", 18)
	panel.add_child(nights_label)

	var nights_spin = SpinBox.new()
	nights_spin.name = "NightsSpinBox"
	nights_spin.position = Vector2(150, 435)
	nights_spin.size = Vector2(120, 35)
	nights_spin.min_value = 1
	nights_spin.max_value = 7
	nights_spin.value = 1
	panel.add_child(nights_spin)

	# Check in button
	var checkin_button = Button.new()
	checkin_button.text = "CHECK IN GUEST"
	checkin_button.position = Vector2(20, 490)
	checkin_button.size = Vector2(320, 45)
	checkin_button.pressed.connect(_on_checkin_button_pressed)
	panel.add_child(checkin_button)

	# Close button
	var close_button = Button.new()
	close_button.text = "CLOSE"
	close_button.position = Vector2(360, 490)
	close_button.size = Vector2(320, 45)
	close_button.pressed.connect(_close_booking_interface)
	panel.add_child(close_button)

	# Message label
	var message_label = Label.new()
	message_label.name = "MessageLabel"
	message_label.text = ""
	message_label.position = Vector2(420, 340)
	message_label.size = Vector2(260, 100)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	message_label.add_theme_font_size_override("font_size", 16)
	panel.add_child(message_label)

	return ui

func _on_checkin_button_pressed() -> void:
	"""Handle check-in button press"""
	var ui = get_tree().root.get_node_or_null("MotelBookingUI")
	if not ui:
		return

	var name_input = ui.get_node_or_null("Panel/GuestNameInput")
	var id_input = ui.get_node_or_null("Panel/GuestIDInput")
	var nights_spin = ui.get_node_or_null("Panel/NightsSpinBox")
	var message_label = ui.get_node_or_null("Panel/MessageLabel")

	# Validate inputs
	if not name_input or not id_input or not nights_spin:
		return

	var guest_name = name_input.text.strip_edges()
	var guest_id = id_input.text.strip_edges()
	var nights = int(nights_spin.value)

	if guest_name.is_empty():
		if message_label:
			message_label.text = "ERROR: Guest name required"
			message_label.modulate = Color.RED
		return

	if guest_id.is_empty():
		if message_label:
			message_label.text = "ERROR: ID number required"
			message_label.modulate = Color.RED
		return

	# Create guest data
	var guest_data = {
		"name": guest_name,
		"id": guest_id,
		"nights": nights
	}

	# Check in guest
	var room_number = check_in_guest(guest_data)

	if room_number == -1:
		if message_label:
			message_label.text = "ERROR: No rooms available"
			message_label.modulate = Color.RED
	else:
		if message_label:
			message_label.text = "SUCCESS!\n%s checked into Room %d" % [guest_name, room_number]
			message_label.modulate = Color.GREEN

		# Clear inputs
		name_input.text = ""
		id_input.text = ""

		# Wait then close
		await get_tree().create_timer(2.0).timeout
		_close_booking_interface()

# ============================================================================
# GUEST CHECK-IN
# ============================================================================

func check_in_guest(guest_data: Dictionary) -> int:
	"""Check in a guest and assign a room"""
	var available_room = _find_available_room()

	if available_room == -1:
		AudioManager.play_sfx("error_beep", global_position)
		return -1

	# Check for horror event: guest requests Room 4
	if guest_data.get("requested_room", 0) == 4:
		_trigger_room_4_request(guest_data)
		return -1

	room_occupancy[available_room] = guest_data
	guest_data["room_number"] = available_room
	guest_data["check_in_time"] = Time.get_ticks_msec()

	AudioManager.play_sfx("key_dispense", global_position)

	EventBus.guest_checked_in.emit(guest_data, available_room)

	return available_room

func check_out_guest(room_number: int) -> bool:
	"""Check out a guest"""
	if room_number < 1 or room_number > MAX_ROOMS:
		return false

	if room_occupancy.has(room_number) and room_occupancy[room_number] != null:
		room_occupancy[room_number] = null
		EventBus.guest_checked_out.emit(room_number)
		return true

	return false

# ============================================================================
# ROOM MANAGEMENT
# ============================================================================

func _find_available_room() -> int:
	"""Find an available room"""
	for room_num in room_occupancy:
		if room_occupancy[room_num] == null:
			return room_num
	return -1

func get_occupied_rooms() -> Array:
	"""Get list of occupied room numbers"""
	var occupied = []
	for room_num in room_occupancy:
		if room_occupancy[room_num] != null:
			occupied.append(room_num)
	return occupied

func get_guest_in_room(room_number: int) -> Dictionary:
	"""Get guest data for a specific room"""
	if room_occupancy.has(room_number):
		return room_occupancy.get(room_number, {})
	return {}

func is_room_occupied(room_number: int) -> bool:
	"""Check if a room is occupied"""
	return room_occupancy.get(room_number, null) != null

# ============================================================================
# HORROR EVENTS
# ============================================================================

func _trigger_room_4_request(guest_data: Dictionary) -> void:
	"""Trigger horror event when guest requests Room 4"""
	EventBus.horror_event_triggered.emit("room_4_request", 3)

	# Guest insists Room 4 exists and they have a reservation
	# This is a key story horror moment

func check_impossibility_events() -> void:
	"""Check for impossible room situations"""
	var occupied_count = get_occupied_rooms().size()

	# Horror event: More guests than rooms
	if occupied_count > 5: # Only 5 usable rooms
		EventBus.anomaly_detected.emit("too_many_guests", global_position)
