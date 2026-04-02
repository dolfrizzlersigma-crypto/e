extends Node
## Event Director - schedules and triggers horror events

# ============================================================================
# CONFIGURATION
# ============================================================================

const MIN_EVENT_INTERVAL: float = 180.0 # 3 minutes
const MAX_EVENT_INTERVAL: float = 420.0 # 7 minutes
const HORROR_INTENSITY_BASE: float = 0.2
const HORROR_INTENSITY_PER_CHAPTER: float = 0.15

# ============================================================================
# STATE
# ============================================================================

var event_library: Array = []
var active_events: Array = []
var event_cooldowns: Dictionary = {}
var horror_intensity: float = 0.2
var time_since_last_event: float = 0.0
var next_event_time: float = 300.0

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	print("EventDirector: Initializing...")
	_load_event_library()
	_calculate_horror_intensity()
	next_event_time = randf_range(MIN_EVENT_INTERVAL, MAX_EVENT_INTERVAL)
	print("EventDirector initialized")

func _load_event_library() -> void:
	"""Load all available horror events"""
	event_library = [
		{"id": "phantom_customer", "intensity": 2, "category": "entity", "cooldown": 600.0},
		{"id": "lights_flicker", "intensity": 1, "category": "environmental", "cooldown": 300.0},
		{"id": "phone_call", "intensity": 2, "category": "audio", "cooldown": 900.0},
		{"id": "room_4_knocking", "intensity": 3, "category": "room_4", "cooldown": 1200.0},
		{"id": "shadow_figure", "intensity": 3, "category": "entity", "cooldown": 900.0},
		{"id": "time_loop", "intensity": 4, "category": "reality", "cooldown": 1800.0},
		{"id": "possessed_customer", "intensity": 3, "category": "customer", "cooldown": 1200.0},
		{"id": "power_surge", "intensity": 2, "category": "power", "cooldown": 600.0},
		{"id": "doppelganger", "intensity": 4, "category": "customer", "cooldown": 1800.0},
		{"id": "footage_playback", "intensity": 3, "category": "cctv", "cooldown": 900.0}
	]

# ============================================================================
# PROCESS
# ============================================================================

func _process(delta: float) -> void:
	time_since_last_event += delta
	_update_cooldowns(delta)

	if time_since_last_event >= next_event_time:
		trigger_random_event()

func _update_cooldowns(delta: float) -> void:
	"""Update event cooldowns"""
	for event_id in event_cooldowns.keys():
		event_cooldowns[event_id] -= delta
		if event_cooldowns[event_id] <= 0:
			event_cooldowns.erase(event_id)

# ============================================================================
# EVENT TRIGGERING
# ============================================================================

func trigger_random_event() -> void:
	"""Trigger a random horror event"""
	var eligible_events = _get_eligible_events()

	if eligible_events.is_empty():
		return

	# Weight events by intensity
	var selected_event = _select_weighted_event(eligible_events)

	if selected_event:
		trigger_event(selected_event["id"])

func trigger_event(event_id: String) -> void:
	"""Trigger a specific event by ID"""
	var event = _get_event_by_id(event_id)
	if not event:
		return

	print("Triggering horror event: %s" % event_id)

	# Add cooldown
	event_cooldowns[event_id] = event.get("cooldown", 600.0)

	# Execute event
	_execute_event(event)

	# Update timing
	time_since_last_event = 0.0
	next_event_time = randf_range(MIN_EVENT_INTERVAL, MAX_EVENT_INTERVAL)

	# Emit signal
	EventBus.horror_event_triggered.emit(event_id, event.get("intensity", 1))

# ============================================================================
# EVENT EXECUTION
# ============================================================================

func _execute_event(event: Dictionary) -> void:
	"""Execute a horror event - placeholder implementation"""
	var event_id = event["id"]
	var category = event.get("category", "")

	print("Executing event: %s (category: %s)" % [event_id, category])

	# Basic event execution based on category
	match category:
		"environmental":
			_execute_environmental_event(event)
		"customer":
			_execute_customer_event(event)
		"cctv":
			_execute_cctv_event(event)
		"audio":
			_execute_audio_event(event)
		"power":
			_execute_power_event(event)
		"entity":
			_execute_entity_event(event)
		_:
			print("Unknown event category: %s" % category)

func _execute_environmental_event(event: Dictionary) -> void:
	"""Execute environmental distortion event"""
	print("Environmental event: %s" % event.get("id", ""))
	# Placeholder - would trigger environmental effects

func _execute_customer_event(event: Dictionary) -> void:
	"""Execute customer anomaly event"""
	print("Customer event: %s" % event.get("id", ""))
	# Placeholder - would spawn or modify customers

func _execute_cctv_event(event: Dictionary) -> void:
	"""Execute CCTV contradiction event"""
	print("CCTV event: %s" % event.get("id", ""))
	EventBus.cctv_anomaly.emit(randi() % 16, event.get("id", ""))

func _execute_audio_event(event: Dictionary) -> void:
	"""Execute audio/radio horror event"""
	print("Audio event: %s" % event.get("id", ""))
	EventBus.radio_interference.emit(event.get("id", ""))

func _execute_power_event(event: Dictionary) -> void:
	"""Execute power grid event"""
	print("Power event: %s" % event.get("id", ""))
	var zones = ["store", "motel", "exterior"]
	var random_zone = zones[randi() % zones.size()]
	EventBus.power_zone_failed.emit(random_zone)

func _execute_entity_event(event: Dictionary) -> void:
	"""Execute entity/creature event"""
	print("Entity event: %s" % event.get("id", ""))
	# Placeholder - would spawn entities

# ============================================================================
# EVENT LIBRARY
# ============================================================================

func _get_event_by_id(event_id: String) -> Dictionary:
	"""Get event by ID"""
	for event in event_library:
		if event["id"] == event_id:
			return event
	return {}

func _get_eligible_events() -> Array:
	"""Get events that can currently trigger"""
	var eligible = []

	for event in event_library:
		# Check cooldown
		if event_cooldowns.has(event["id"]) and event_cooldowns[event["id"]] > 0:
			continue

		# Check intensity vs horror level
		if event.get("intensity", 1) > horror_intensity * 5:
			continue

		eligible.append(event)

	return eligible

func _select_weighted_event(events: Array) -> Dictionary:
	"""Select event with intensity-based weighting"""
	if events.is_empty():
		return {}

	# Weight lower intensity events higher
	var total_weight = 0.0
	var weights = []

	for event in events:
		var intensity = event.get("intensity", 1)
		var weight = 6.0 - intensity # Inverse weighting
		weights.append(weight)
		total_weight += weight

	var roll = randf() * total_weight
	var cumulative = 0.0

	for i in range(events.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return events[i]

	return events[0]

# ============================================================================
# INTENSITY MANAGEMENT
# ============================================================================

func _calculate_horror_intensity() -> void:
	"""Calculate horror intensity based on chapter"""
	horror_intensity = HORROR_INTENSITY_BASE + (GameManager.current_chapter - 1) * HORROR_INTENSITY_PER_CHAPTER
	horror_intensity = clamp(horror_intensity, 0.0, 1.0)
	AudioManager.adjust_horror_mix(horror_intensity)

func set_horror_intensity(intensity: float) -> void:
	"""Manually set horror intensity"""
	horror_intensity = clamp(intensity, 0.0, 1.0)
	AudioManager.adjust_horror_mix(horror_intensity)
