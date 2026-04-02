## EventDirector - Controls horror events, pacing, and randomized encounters.
## Manages event scheduling, intensity curves, and horror categories.
extends Node

# --- Signals ---
signal event_triggered(event_data: Dictionary)
signal event_completed(event_id: String)
signal horror_intensity_changed(level: float)

# --- Enums ---
enum HorrorCategory {
	ENVIRONMENTAL_DISTORTION,
	CUSTOMER_ANOMALY,
	CCTV_CONTRADICTION,
	FALSE_CALL,
	ROOM_IMPOSSIBILITY,
	POWER_MANIPULATION,
	HIGHWAY_APPARITION,
	SCRIPTED_SET_PIECE,
}

# --- State ---
var horror_intensity: float = 0.0  # 0.0 = calm, 1.0 = maximum terror
var events_this_shift: Array[Dictionary] = []
var cooldown_timer: float = 0.0
var time_since_last_event: float = 0.0
var active_events: Array[Dictionary] = []

# --- Configuration ---
const MIN_EVENT_INTERVAL: float = 30.0  # Minimum seconds between events
const MAX_EVENT_INTERVAL: float = 120.0  # Maximum seconds between events
const INTENSITY_DECAY_RATE: float = 0.02  # Per second
const INTENSITY_BUILD_RATE: float = 0.005  # Per second (ambient dread)
const CLIP_WORTHY_INTERVAL: float = 360.0  # Target: ~every 6 minutes

# --- Event Registry ---
# Each event is a dictionary with: id, category, intensity_min, intensity_max,
# weight, shift_min, requires_flags, script_path, one_shot
var _event_pool: Array[Dictionary] = []
var _scripted_queue: Array[Dictionary] = []


func _ready() -> void:
	_register_default_events()


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	time_since_last_event += delta
	cooldown_timer = maxf(cooldown_timer - delta, 0.0)

	# Ambient intensity build
	horror_intensity = clampf(
		horror_intensity + INTENSITY_BUILD_RATE * delta,
		0.0, 1.0
	)

	# Check if we should trigger an event
	if cooldown_timer <= 0.0 and _should_trigger_event():
		_try_trigger_event()

	# Process active events
	_process_active_events(delta)


## Called by GameManager when shift phase changes.
func on_phase_changed(phase: GameManager.ShiftPhase) -> void:
	match phase:
		GameManager.ShiftPhase.MID_NIGHT:
			horror_intensity = maxf(horror_intensity, 0.3)
		GameManager.ShiftPhase.LATE_NIGHT:
			horror_intensity = maxf(horror_intensity, 0.5)
		GameManager.ShiftPhase.DAWN:
			# Intensity drops at dawn but one last scare possible
			horror_intensity *= 0.6


## Register a custom event into the pool.
func register_event(event_data: Dictionary) -> void:
	_event_pool.append(event_data)


## Queue a scripted event to trigger at the next opportunity.
func queue_scripted_event(event_data: Dictionary) -> void:
	_scripted_queue.append(event_data)


## Force-trigger a specific event immediately.
func trigger_event(event_data: Dictionary) -> void:
	event_data["start_time"] = Time.get_ticks_msec() / 1000.0
	active_events.append(event_data)
	events_this_shift.append(event_data)
	time_since_last_event = 0.0
	cooldown_timer = MIN_EVENT_INTERVAL
	# Increase horror intensity based on event
	var intensity_boost: float = event_data.get("intensity_boost", 0.15)
	horror_intensity = clampf(horror_intensity + intensity_boost, 0.0, 1.0)
	horror_intensity_changed.emit(horror_intensity)
	event_triggered.emit(event_data)


## Complete an active event.
func complete_event(event_id: String) -> void:
	for i in range(active_events.size() - 1, -1, -1):
		if active_events[i].get("id") == event_id:
			active_events.remove_at(i)
			break
	# Decay intensity after event resolves
	horror_intensity = clampf(horror_intensity - 0.1, 0.0, 1.0)
	horror_intensity_changed.emit(horror_intensity)
	event_completed.emit(event_id)


## Reset for a new shift.
func reset_for_shift() -> void:
	events_this_shift.clear()
	active_events.clear()
	horror_intensity = 0.0
	cooldown_timer = 60.0  # Grace period at shift start
	time_since_last_event = 0.0


# --- Private ---

func _should_trigger_event() -> bool:
	# More likely to trigger as time passes without an event
	var urgency := time_since_last_event / CLIP_WORTHY_INTERVAL
	var chance := urgency * 0.1 * (0.5 + horror_intensity * 0.5)
	return randf() < chance


func _try_trigger_event() -> void:
	# Priority: scripted queue first
	if _scripted_queue.size() > 0:
		var event := _scripted_queue.pop_front()
		trigger_event(event)
		return

	# Filter eligible events from the pool
	var eligible: Array[Dictionary] = []
	for event in _event_pool:
		if _is_event_eligible(event):
			eligible.append(event)

	if eligible.is_empty():
		return

	# Weighted random selection
	var total_weight: float = 0.0
	for event in eligible:
		total_weight += event.get("weight", 1.0)

	var roll := randf() * total_weight
	var cumulative: float = 0.0
	for event in eligible:
		cumulative += event.get("weight", 1.0)
		if roll <= cumulative:
			trigger_event(event.duplicate(true))
			return


func _is_event_eligible(event: Dictionary) -> bool:
	# Check shift minimum
	if GameManager.current_shift < event.get("shift_min", 1):
		return false
	# Check intensity range
	var intensity_min: float = event.get("intensity_min", 0.0)
	var intensity_max: float = event.get("intensity_max", 1.0)
	if horror_intensity < intensity_min or horror_intensity > intensity_max:
		return false
	# Check required flags
	var required_flags: Array = event.get("requires_flags", [])
	for flag in required_flags:
		if not GameManager.get_story_flag(flag):
			return false
	# Check one-shot events
	if event.get("one_shot", false):
		for past_event in events_this_shift:
			if past_event.get("id") == event.get("id"):
				return false
	return true


func _process_active_events(delta: float) -> void:
	var current_time: float = Time.get_ticks_msec() / 1000.0
	for i in range(active_events.size() - 1, -1, -1):
		var event := active_events[i]
		var duration: float = event.get("duration", 30.0)
		var elapsed: float = current_time - event.get("start_time", current_time)
		if elapsed >= duration:
			complete_event(event.get("id", "unknown"))


func _register_default_events() -> void:
	# --- Environmental Distortion Events ---
	register_event({
		"id": "flickering_lights",
		"category": HorrorCategory.ENVIRONMENTAL_DISTORTION,
		"description": "Lights flicker across the plaza",
		"weight": 3.0,
		"intensity_min": 0.1,
		"intensity_max": 0.6,
		"intensity_boost": 0.1,
		"duration": 15.0,
		"shift_min": 1,
	})
	register_event({
		"id": "phantom_footsteps",
		"category": HorrorCategory.ENVIRONMENTAL_DISTORTION,
		"description": "Footsteps echo from empty hallway",
		"weight": 2.5,
		"intensity_min": 0.2,
		"intensity_max": 0.8,
		"intensity_boost": 0.15,
		"duration": 10.0,
		"shift_min": 1,
	})
	register_event({
		"id": "cold_spot",
		"category": HorrorCategory.ENVIRONMENTAL_DISTORTION,
		"description": "Temperature drops suddenly in one area",
		"weight": 2.0,
		"intensity_min": 0.0,
		"intensity_max": 0.5,
		"intensity_boost": 0.08,
		"duration": 20.0,
		"shift_min": 1,
	})

	# --- Customer Anomaly Events ---
	register_event({
		"id": "guest_wrong_room",
		"category": HorrorCategory.CUSTOMER_ANOMALY,
		"description": "Guest asks for a room that doesn't exist",
		"weight": 2.0,
		"intensity_min": 0.2,
		"intensity_max": 0.7,
		"intensity_boost": 0.2,
		"duration": 45.0,
		"shift_min": 2,
	})
	register_event({
		"id": "repeat_customer",
		"category": HorrorCategory.CUSTOMER_ANOMALY,
		"description": "The same customer returns but doesn't remember being here",
		"weight": 1.5,
		"intensity_min": 0.3,
		"intensity_max": 0.8,
		"intensity_boost": 0.2,
		"duration": 60.0,
		"shift_min": 2,
	})

	# --- CCTV Contradiction Events ---
	register_event({
		"id": "cctv_phantom_car",
		"category": HorrorCategory.CCTV_CONTRADICTION,
		"description": "Car visible on CCTV but not in the lot",
		"weight": 2.0,
		"intensity_min": 0.2,
		"intensity_max": 0.7,
		"intensity_boost": 0.15,
		"duration": 30.0,
		"shift_min": 1,
	})
	register_event({
		"id": "cctv_doppelganger",
		"category": HorrorCategory.CCTV_CONTRADICTION,
		"description": "CCTV shows Mara behind the counter while player is elsewhere",
		"weight": 1.0,
		"intensity_min": 0.5,
		"intensity_max": 1.0,
		"intensity_boost": 0.3,
		"duration": 20.0,
		"shift_min": 3,
		"one_shot": true,
	})

	# --- False Call Events ---
	register_event({
		"id": "false_emergency_call",
		"category": HorrorCategory.FALSE_CALL,
		"description": "Radio predicts a customer minutes before they arrive",
		"weight": 2.0,
		"intensity_min": 0.1,
		"intensity_max": 0.6,
		"intensity_boost": 0.12,
		"duration": 120.0,
		"shift_min": 1,
	})
	register_event({
		"id": "child_radio_voice",
		"category": HorrorCategory.FALSE_CALL,
		"description": "Child's voice on CB radio asking for roadside help",
		"weight": 1.0,
		"intensity_min": 0.4,
		"intensity_max": 0.9,
		"intensity_boost": 0.25,
		"duration": 30.0,
		"shift_min": 2,
		"one_shot": true,
	})

	# --- Room Impossibility Events ---
	register_event({
		"id": "locked_stall",
		"category": HorrorCategory.ROOM_IMPOSSIBILITY,
		"description": "Bathroom stall locked from inside but empty",
		"weight": 2.0,
		"intensity_min": 0.2,
		"intensity_max": 0.7,
		"intensity_boost": 0.15,
		"duration": 25.0,
		"shift_min": 1,
	})
	register_event({
		"id": "key_rearrangement",
		"category": HorrorCategory.ROOM_IMPOSSIBILITY,
		"description": "Motel room key tags rearrange themselves",
		"weight": 1.5,
		"intensity_min": 0.3,
		"intensity_max": 0.8,
		"intensity_boost": 0.18,
		"duration": 10.0,
		"shift_min": 2,
	})

	# --- Power Manipulation Events ---
	register_event({
		"id": "zone_blackout",
		"category": HorrorCategory.POWER_MANIPULATION,
		"description": "Power goes out one zone at a time",
		"weight": 1.5,
		"intensity_min": 0.3,
		"intensity_max": 0.9,
		"intensity_boost": 0.2,
		"duration": 45.0,
		"shift_min": 1,
	})

	# --- Highway Apparition Events ---
	register_event({
		"id": "distant_headlights",
		"category": HorrorCategory.HIGHWAY_APPARITION,
		"description": "Headlights visible on road for minutes without getting closer",
		"weight": 2.5,
		"intensity_min": 0.1,
		"intensity_max": 0.5,
		"intensity_boost": 0.1,
		"duration": 180.0,
		"shift_min": 1,
	})
	register_event({
		"id": "receipt_prediction",
		"category": HorrorCategory.CUSTOMER_ANOMALY,
		"description": "Receipt printer outputs order for someone who hasn't entered yet",
		"weight": 1.5,
		"intensity_min": 0.2,
		"intensity_max": 0.7,
		"intensity_boost": 0.2,
		"duration": 60.0,
		"shift_min": 2,
	})
	register_event({
		"id": "vending_personal_items",
		"category": HorrorCategory.ENVIRONMENTAL_DISTORTION,
		"description": "Vending machine dispenses personal objects instead of snacks",
		"weight": 1.0,
		"intensity_min": 0.4,
		"intensity_max": 0.9,
		"intensity_boost": 0.22,
		"duration": 15.0,
		"shift_min": 3,
	})
	register_event({
		"id": "storm_warning_past",
		"category": HorrorCategory.FALSE_CALL,
		"description": "Storm warning describes weather that already happened",
		"weight": 1.5,
		"intensity_min": 0.2,
		"intensity_max": 0.6,
		"intensity_boost": 0.12,
		"duration": 30.0,
		"shift_min": 2,
	})
	register_event({
		"id": "lost_found_pileup",
		"category": HorrorCategory.ENVIRONMENTAL_DISTORTION,
		"description": "Lost-and-found box fills with items from the Mile 87 pileup",
		"weight": 1.0,
		"intensity_min": 0.5,
		"intensity_max": 1.0,
		"intensity_boost": 0.25,
		"duration": 20.0,
		"shift_min": 4,
		"one_shot": true,
	})
