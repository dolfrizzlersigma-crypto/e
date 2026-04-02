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
	# Show booking UI

func _close_booking_interface() -> void:
	"""Close the booking interface"""
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	booking_interface_open = false

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
