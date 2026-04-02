## MotelSystem - Manages motel room booking, guest tracking, and room states.
## Handles check-in, check-out, room assignment, and occupancy anomalies.
class_name MotelSystem
extends Node

# --- Signals ---
signal guest_checked_in(room_number: int, guest_data: Dictionary)
signal guest_checked_out(room_number: int)
signal room_state_changed(room_number: int, new_state: RoomState)
signal occupancy_anomaly(room_number: int, description: String)
signal complaint_received(room_number: int, complaint: String)

# --- Enums ---
enum RoomState { VACANT, OCCUPIED, RESERVED, CLEANING, OUT_OF_ORDER, BOARDED_UP }

# --- Constants ---
const TOTAL_ROOMS: int = 6
const ROOM_RATE: float = 45.0
const LATE_CHECKOUT_FEE: float = 15.0

# --- State ---
var rooms: Dictionary = {}  # room_number -> room_data
var guest_log: Array[Dictionary] = []
var complaints: Array[Dictionary] = []


func _ready() -> void:
	_initialize_rooms()


## Initialize all rooms to default state.
func _initialize_rooms() -> void:
	for i in range(1, TOTAL_ROOMS + 1):
		rooms[i] = {
			"number": i,
			"state": RoomState.VACANT,
			"guest": {},
			"check_in_time": -1,
			"key_issued": false,
			"needs_cleaning": false,
			"condition": 100.0,
			"notes": "",
		}
	# Room 4 is boarded up (story element)
	rooms[4]["state"] = RoomState.BOARDED_UP
	rooms[4]["notes"] = "Closed since incident. Do not enter."


## Check in a guest to a room. Returns room number or -1 if failed.
func check_in_guest(guest_data: Dictionary, preferred_room: int = -1) -> int:
	var room_number := preferred_room

	# If no preference or preferred room unavailable, find an open one
	if room_number < 0 or not _is_room_available(room_number):
		room_number = _find_available_room()

	if room_number < 0:
		DialogueManager.show_subtitle("Mara", "Sorry, we're full up tonight.")
		return -1

	# Validate the guest isn't asking for Room 4 (horror hook)
	if preferred_room == 4:
		occupancy_anomaly.emit(4, "Guest requested boarded-up room")
		GameManager.stress += 5.0
		DialogueManager.show_subtitle("Mara", "Room 4 isn't... available. Let me find you another.")

	# Process check-in
	var room: Dictionary = rooms[room_number]
	room["state"] = RoomState.OCCUPIED
	room["guest"] = guest_data.duplicate()
	room["check_in_time"] = GameManager.in_game_hour * 100 + GameManager.in_game_minute
	room["key_issued"] = true
	room["needs_cleaning"] = false

	# Log the check-in
	var log_entry := {
		"type": "check_in",
		"room": room_number,
		"guest_name": guest_data.get("name", "Unknown"),
		"guest_id": guest_data.get("id", ""),
		"time": room["check_in_time"],
		"shift": GameManager.current_shift,
		"rate": ROOM_RATE,
	}
	guest_log.append(log_entry)
	GameManager.shift_revenue += ROOM_RATE

	guest_checked_in.emit(room_number, guest_data)
	room_state_changed.emit(room_number, RoomState.OCCUPIED)

	return room_number


## Check out a guest from a room.
func check_out_guest(room_number: int) -> Dictionary:
	if not rooms.has(room_number):
		return {}

	var room: Dictionary = rooms[room_number]
	if room["state"] != RoomState.OCCUPIED:
		return {}

	var guest_data: Dictionary = room["guest"].duplicate()

	# Log the check-out
	guest_log.append({
		"type": "check_out",
		"room": room_number,
		"guest_name": guest_data.get("name", "Unknown"),
		"time": GameManager.in_game_hour * 100 + GameManager.in_game_minute,
		"shift": GameManager.current_shift,
	})

	# Reset room
	room["state"] = RoomState.CLEANING
	room["guest"] = {}
	room["key_issued"] = false
	room["needs_cleaning"] = true
	room["check_in_time"] = -1

	guest_checked_out.emit(room_number)
	room_state_changed.emit(room_number, RoomState.CLEANING)

	return guest_data


## Mark a room as cleaned and ready.
func mark_room_cleaned(room_number: int) -> void:
	if not rooms.has(room_number):
		return
	var room: Dictionary = rooms[room_number]
	if room["state"] == RoomState.CLEANING:
		room["state"] = RoomState.VACANT
		room["needs_cleaning"] = false
		room_state_changed.emit(room_number, RoomState.VACANT)
		GameManager.reputation += 1.0


## Get the occupancy board data for UI display.
func get_occupancy_board() -> Array[Dictionary]:
	var board: Array[Dictionary] = []
	for room_num in rooms:
		var room: Dictionary = rooms[room_num]
		board.append({
			"number": room_num,
			"state": room["state"],
			"state_name": _get_state_name(room["state"]),
			"guest_name": room["guest"].get("name", ""),
			"needs_cleaning": room["needs_cleaning"],
		})
	return board


## Get the number of available rooms.
func get_available_room_count() -> int:
	var count := 0
	for room_num in rooms:
		if _is_room_available(room_num):
			count += 1
	return count


## Get the number of occupied rooms.
func get_occupied_room_count() -> int:
	var count := 0
	for room_num in rooms:
		if rooms[room_num]["state"] == RoomState.OCCUPIED:
			count += 1
	return count


## Register a guest complaint.
func register_complaint(room_number: int, complaint: String) -> void:
	complaints.append({
		"room": room_number,
		"complaint": complaint,
		"time": GameManager.in_game_hour * 100 + GameManager.in_game_minute,
		"shift": GameManager.current_shift,
	})
	GameManager.reputation -= 2.0
	complaint_received.emit(room_number, complaint)


## Trigger a room anomaly (horror event).
func trigger_room_anomaly(room_number: int, anomaly_type: String) -> void:
	match anomaly_type:
		"phantom_occupant":
			# Room shows as occupied but guest doesn't exist
			if rooms.has(room_number) and rooms[room_number]["state"] == RoomState.VACANT:
				rooms[room_number]["state"] = RoomState.OCCUPIED
				rooms[room_number]["guest"] = {"name": "???", "id": "phantom"}
				occupancy_anomaly.emit(room_number, "Room occupied by unknown guest")
		"key_swap":
			# Keys show wrong room numbers
			occupancy_anomaly.emit(room_number, "Key tag shows wrong room number")
		"impossible_booking":
			# Guest asks for non-existent room number
			occupancy_anomaly.emit(room_number, "Guest requested room %d - room does not exist" % room_number)
		"double_booking":
			# Two guests assigned to same room
			occupancy_anomaly.emit(room_number, "Double booking detected")


## Get save data.
func get_save_data() -> Dictionary:
	return {
		"rooms": rooms.duplicate(true),
		"guest_log": guest_log.duplicate(true),
		"complaints": complaints.duplicate(true),
	}


## Load save data.
func load_save_data(data: Dictionary) -> void:
	if data.has("rooms"):
		rooms = data["rooms"]
	if data.has("guest_log"):
		guest_log.assign(data["guest_log"])
	if data.has("complaints"):
		complaints.assign(data["complaints"])


# --- Private ---

func _is_room_available(room_number: int) -> bool:
	if not rooms.has(room_number):
		return false
	return rooms[room_number]["state"] == RoomState.VACANT


func _find_available_room() -> int:
	# Prefer lower-numbered rooms first
	for i in range(1, TOTAL_ROOMS + 1):
		if _is_room_available(i):
			return i
	return -1


func _get_state_name(state: RoomState) -> String:
	match state:
		RoomState.VACANT:
			return "Vacant"
		RoomState.OCCUPIED:
			return "Occupied"
		RoomState.RESERVED:
			return "Reserved"
		RoomState.CLEANING:
			return "Cleaning"
		RoomState.OUT_OF_ORDER:
			return "Out of Order"
		RoomState.BOARDED_UP:
			return "Closed"
		_:
			return "Unknown"
