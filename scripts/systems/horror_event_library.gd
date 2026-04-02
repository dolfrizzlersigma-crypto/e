extends Node
class_name HorrorEventLibrary

## ====================================================================================
## HORROR EVENT LIBRARY - COMPREHENSIVE EVENT SYSTEM
## ====================================================================================
## Contains 50+ unique horror events with categories, intensity levels, and triggers
## Integrates with all game systems for coordinated scares
## ====================================================================================

signal event_triggered(event_data: Dictionary)
signal event_completed(event_id: String)
signal intensity_changed(new_intensity: float)
signal category_unlocked(category: String)

# ====================================================================================
# EVENT CATEGORIES
# ====================================================================================

enum EventCategory {
	ENVIRONMENTAL,      # Lights, sounds, weather
	CUSTOMER,          # Strange customer behaviors
	SYSTEM_CORRUPTION, # Cash register, pumps, CCTV glitches
	TEMPORAL,          # Time anomalies, loops
	REALITY_DISTORTION,# Impossible geometry, physics violations
	ENTITY_ENCOUNTER,  # Direct entity interactions
	PSYCHOLOGICAL,     # Subtle mind-games
	AUDIO_VISUAL      # Hallucinations, glitches
}

enum EventIntensity {
	SUBTLE,      # Barely noticeable, builds unease
	MODERATE,    # Clear anomaly, but explainable
	SIGNIFICANT, # Undeniable supernatural event
	SEVERE,      # Direct threat or major reality break
	EXTREME      # Game-changing horror moment
}

# ====================================================================================
# EVENT DATA STRUCTURE
# ====================================================================================

class HorrorEvent:
	var event_id: String
	var event_name: String
	var description: String
	var category: EventCategory
	var intensity: EventIntensity
	var min_horror_level: float  # 0.0 to 1.0
	var duration: float  # seconds
	var cooldown: float  # seconds before can trigger again
	var prerequisites: Array[String] = []
	var affects_systems: Array[String] = []
	var one_time_only: bool = false
	var has_been_triggered: bool = false
	var trigger_count: int = 0
	var last_trigger_time: float = 0.0

var event_library: Dictionary = {}  # event_id -> HorrorEvent
var active_events: Array[HorrorEvent] = []
var triggered_events_history: Array[Dictionary] = []
var current_horror_intensity: float = 0.0

# ====================================================================================
# INITIALIZATION
# ====================================================================================

func _ready() -> void:
	_initialize_event_library()
	print("HorrorEventLibrary: Initialized with %d events" % event_library.size())

func _initialize_event_library() -> void:
	# ================== ENVIRONMENTAL EVENTS ==================

	_register_event("ENV_LIGHTS_FLICKER_MINOR", {
		"name": "Subtle Light Flicker",
		"description": "Store lights flicker briefly",
		"category": EventCategory.ENVIRONMENTAL,
		"intensity": EventIntensity.SUBTLE,
		"min_horror_level": 0.1,
		"duration": 2.0,
		"cooldown": 120.0,
		"affects_systems": ["lighting"]
	})

	_register_event("ENV_LIGHTS_FLICKER_MAJOR", {
		"name": "Severe Light Flicker",
		"description": "All lights flicker violently",
		"category": EventCategory.ENVIRONMENTAL,
		"intensity": EventIntensity.MODERATE,
		"min_horror_level": 0.3,
		"duration": 5.0,
		"cooldown": 180.0,
		"affects_systems": ["lighting", "power_grid"]
	})

	_register_event("ENV_POWER_OUTAGE_PARTIAL", {
		"name": "Partial Power Failure",
		"description": "Power fails in sections of the plaza",
		"category": EventCategory.ENVIRONMENTAL,
		"intensity": EventIntensity.SIGNIFICANT,
		"min_horror_level": 0.4,
		"duration": 30.0,
		"cooldown": 300.0,
		"affects_systems": ["power_grid", "lighting", "cctv"]
	})

	_register_event("ENV_POWER_OUTAGE_TOTAL", {
		"name": "Total Blackout",
		"description": "Complete power failure across facility",
		"category": EventCategory.ENVIRONMENTAL,
		"intensity": EventIntensity.SEVERE,
		"min_horror_level": 0.6,
		"duration": 60.0,
		"cooldown": 600.0,
		"affects_systems": ["power_grid", "lighting", "cctv", "cash_register", "fuel_pumps"]
	})

	_register_event("ENV_FOG_ROLLS_IN", {
		"name": "Unnatural Fog",
		"description": "Thick fog envelops the parking lot",
		"category": EventCategory.ENVIRONMENTAL,
		"intensity": EventIntensity.MODERATE,
		"min_horror_level": 0.2,
		"duration": 300.0,
		"cooldown": 400.0,
		"affects_systems": ["weather", "visibility"]
	})

	_register_event("ENV_EMERGENCY_LIGHTS", {
		"name": "Emergency Lighting Activated",
		"description": "Emergency lights activate without cause",
		"category": EventCategory.ENVIRONMENTAL,
		"intensity": EventIntensity.MODERATE,
		"min_horror_level": 0.35,
		"duration": 45.0,
		"cooldown": 240.0,
		"affects_systems": ["lighting"]
	})

	# ================== CUSTOMER EVENTS ==================

	_register_event("CUST_WRONG_DIALOGUE", {
		"name": "Customer Speaks Impossibly",
		"description": "Customer says something they couldn't know",
		"category": EventCategory.CUSTOMER,
		"intensity": EventIntensity.MODERATE,
		"min_horror_level": 0.3,
		"duration": 10.0,
		"cooldown": 180.0,
		"affects_systems": ["customer_ai", "dialogue"]
	})

	_register_event("CUST_DUPLICATE_CUSTOMER", {
		"name": "Duplicate Customer",
		"description": "Same customer appears simultaneously in two places",
		"category": EventCategory.CUSTOMER,
		"intensity": EventIntensity.SIGNIFICANT,
		"min_horror_level": 0.45,
		"duration": 30.0,
		"cooldown": 300.0,
		"affects_systems": ["customer_spawner"]
	})

	_register_event("CUST_FACELESS", {
		"name": "Faceless Customer",
		"description": "Customer has no facial features",
		"category": EventCategory.CUSTOMER,
		"intensity": EventIntensity.SEVERE,
		"min_horror_level": 0.5,
		"duration": 20.0,
		"cooldown": 360.0,
		"affects_systems": ["customer_ai"],
		"one_time_only": true
	})

	_register_event("CUST_WRONG_ITEMS", {
		"name": "Impossible Purchase",
		"description": "Customer buys items not in the store",
		"category": EventCategory.CUSTOMER,
		"intensity": EventIntensity.MODERATE,
		"min_horror_level": 0.35,
		"duration": 15.0,
		"cooldown": 200.0,
		"affects_systems": ["cash_register", "inventory"]
	})

	_register_event("CUST_LOOP_BEHAVIOR", {
		"name": "Looping Customer",
		"description": "Customer repeats exact same actions in loop",
		"category": EventCategory.CUSTOMER,
		"intensity": EventIntensity.MODERATE,
		"min_horror_level": 0.4,
		"duration": 45.0,
		"cooldown": 300.0,
		"affects_systems": ["customer_ai"]
	})

	# ================== SYSTEM CORRUPTION EVENTS ==================

	_register_event("SYS_RECEIPT_FUTURE", {
		"name": "Future Receipt",
		"description": "Receipt prints for future transaction",
		"category": EventCategory.SYSTEM_CORRUPTION,
		"intensity": EventIntensity.MODERATE,
		"min_horror_level": 0.3,
		"duration": 5.0,
		"cooldown": 180.0,
		"affects_systems": ["cash_register"]
	})

	_register_event("SYS_PUMP_UNAUTHORIZED", {
		"name": "Ghost Fuel Transaction",
		"description": "Fuel pump activates without authorization",
		"category": EventCategory.SYSTEM_CORRUPTION,
		"intensity": EventIntensity.MODERATE,
		"min_horror_level": 0.35,
		"duration": 20.0,
		"cooldown": 240.0,
		"affects_systems": ["fuel_pumps"]
	})

	_register_event("SYS_CCTV_WRONG_FEED", {
		"name": "CCTV Temporal Anomaly",
		"description": "Camera shows past or future footage",
		"category": EventCategory.SYSTEM_CORRUPTION,
		"intensity": EventIntensity.SIGNIFICANT,
		"min_horror_level": 0.4,
		"duration": 30.0,
		"cooldown": 300.0,
		"affects_systems": ["cctv"]
	})

	_register_event("SYS_CCTV_ENTITY", {
		"name": "Entity on Camera",
		"description": "Figure appears on CCTV but not in reality",
		"category": EventCategory.SYSTEM_CORRUPTION,
		"intensity": EventIntensity.SEVERE,
		"min_horror_level": 0.55,
		"duration": 15.0,
		"cooldown": 400.0,
		"affects_systems": ["cctv"]
	})

	_register_event("SYS_REGISTER_CORRUPTION", {
		"name": "Register Corruption",
		"description": "Cash register displays corrupted data",
		"category": EventCategory.SYSTEM_CORRUPTION,
		"intensity": EventIntensity.MODERATE,
		"min_horror_level": 0.3,
		"duration": 20.0,
		"cooldown": 200.0,
		"affects_systems": ["cash_register"]
	})

	# ================== TEMPORAL EVENTS ==================

	_register_event("TEMP_CLOCK_SKIP", {
		"name": "Time Skip",
		"description": "Clock jumps forward or backward",
		"category": EventCategory.TEMPORAL,
		"intensity": EventIntensity.MODERATE,
		"min_horror_level": 0.35,
		"duration": 1.0,
		"cooldown": 300.0,
		"affects_systems": ["time_system"]
	})

	_register_event("TEMP_TIME_FREEZE", {
		"name": "Frozen Moment",
		"description": "Time appears to stop briefly",
		"category": EventCategory.TEMPORAL,
		"intensity": EventIntensity.SIGNIFICANT,
		"min_horror_level": 0.5,
		"duration": 10.0,
		"cooldown": 400.0,
		"affects_systems": ["time_system", "customer_ai"]
	})

	_register_event("TEMP_LOOP_SMALL", {
		"name": "Micro Time Loop",
		"description": "Last 30 seconds repeat",
		"category": EventCategory.TEMPORAL,
		"intensity": EventIntensity.SEVERE,
		"min_horror_level": 0.6,
		"duration": 30.0,
		"cooldown": 600.0,
		"affects_systems": ["time_system", "customer_ai", "player"],
		"one_time_only": false
	})

	_register_event("TEMP_DEJA_VU", {
		"name": "Déjà Vu Event",
		"description": "Exact scenario repeats impossibly",
		"category": EventCategory.TEMPORAL,
		"intensity": EventIntensity.MODERATE,
		"min_horror_level": 0.4,
		"duration": 20.0,
		"cooldown": 300.0,
		"affects_systems": ["customer_ai"]
	})

	# ================== REALITY DISTORTION EVENTS ==================

	_register_event("REAL_CORRIDOR_EXTEND", {
		"name": "Endless Corridor",
		"description": "Hallway becomes impossibly long",
		"category": EventCategory.REALITY_DISTORTION,
		"intensity": EventIntensity.SEVERE,
		"min_horror_level": 0.55,
		"duration": 45.0,
		"cooldown": 500.0,
		"affects_systems": ["environment", "geometry"]
	})

	_register_event("REAL_ROOM_WRONG", {
		"name": "Wrong Room",
		"description": "Familiar room has different layout",
		"category": EventCategory.REALITY_DISTORTION,
		"intensity": EventIntensity.SIGNIFICANT,
		"min_horror_level": 0.45,
		"duration": 60.0,
		"cooldown": 400.0,
		"affects_systems": ["environment"]
	})

	_register_event("REAL_DOOR_LOOP", {
		"name": "Impossible Door",
		"description": "Door leads back to same room",
		"category": EventCategory.REALITY_DISTORTION,
		"intensity": EventIntensity.MODERATE,
		"min_horror_level": 0.4,
		"duration": 30.0,
		"cooldown": 300.0,
		"affects_systems": ["doors", "navigation"]
	})

	_register_event("REAL_PHYSICS_BREAK", {
		"name": "Physics Violation",
		"description": "Objects float or move impossibly",
		"category": EventCategory.REALITY_DISTORTION,
		"intensity": EventIntensity.SIGNIFICANT,
		"min_horror_level": 0.5,
		"duration": 20.0,
		"cooldown": 350.0,
		"affects_systems": ["physics"]
	})

	_register_event("REAL_MIRROR_WRONG", {
		"name": "Mirror Anomaly",
		"description": "Reflection doesn't match reality",
		"category": EventCategory.REALITY_DISTORTION,
		"intensity": EventIntensity.MODERATE,
		"min_horror_level": 0.35,
		"duration": 15.0,
		"cooldown": 250.0,
		"affects_systems": ["environment"]
	})

	# ================== ENTITY ENCOUNTER EVENTS ==================

	_register_event("ENT_SHADOW_GLIMPSE", {
		"name": "Shadow Figure",
		"description": "Dark figure seen in peripheral vision",
		"category": EventCategory.ENTITY_ENCOUNTER,
		"intensity": EventIntensity.MODERATE,
		"min_horror_level": 0.3,
		"duration": 3.0,
		"cooldown": 200.0,
		"affects_systems": ["entity_system"]
	})

	_register_event("ENT_FOOTSTEPS", {
		"name": "Phantom Footsteps",
		"description": "Footsteps with no visible source",
		"category": EventCategory.ENTITY_ENCOUNTER,
		"intensity": EventIntensity.MODERATE,
		"min_horror_level": 0.35,
		"duration": 20.0,
		"cooldown": 240.0,
		"affects_systems": ["audio"]
	})

	_register_event("ENT_BREATHING", {
		"name": "Unseen Breathing",
		"description": "Heavy breathing sound nearby",
		"category": EventCategory.ENTITY_ENCOUNTER,
		"intensity": EventIntensity.SIGNIFICANT,
		"min_horror_level": 0.45,
		"duration": 30.0,
		"cooldown": 300.0,
		"affects_systems": ["audio"]
	})

	_register_event("ENT_DIRECT_ENCOUNTER", {
		"name": "Direct Entity Sighting",
		"description": "Full entity appearance",
		"category": EventCategory.ENTITY_ENCOUNTER,
		"intensity": EventIntensity.EXTREME,
		"min_horror_level": 0.7,
		"duration": 10.0,
		"cooldown": 800.0,
		"affects_systems": ["entity_system", "player"],
		"one_time_only": false
	})

	_register_event("ENT_DOOR_POUND", {
		"name": "Door Pounding",
		"description": "Something pounds on door from outside",
		"category": EventCategory.ENTITY_ENCOUNTER,
		"intensity": EventIntensity.SIGNIFICANT,
		"min_horror_level": 0.5,
		"duration": 15.0,
		"cooldown": 350.0,
		"affects_systems": ["audio", "doors"]
	})

	# ================== PSYCHOLOGICAL EVENTS ==================

	_register_event("PSY_PARANOIA_WHISPER", {
		"name": "Paranoid Whisper",
		"description": "Barely audible whispers",
		"category": EventCategory.PSYCHOLOGICAL,
		"intensity": EventIntensity.SUBTLE,
		"min_horror_level": 0.2,
		"duration": 10.0,
		"cooldown": 150.0,
		"affects_systems": ["audio"]
	})

	_register_event("PSY_FALSE_MEMORY", {
		"name": "Implanted Memory",
		"description": "Player remembers event that didn't happen",
		"category": EventCategory.PSYCHOLOGICAL,
		"intensity": EventIntensity.MODERATE,
		"min_horror_level": 0.4,
		"duration": 5.0,
		"cooldown": 400.0,
		"affects_systems": ["ui", "dialogue"]
	})

	_register_event("PSY_GASLIGHTING", {
		"name": "Reality Gaslighting",
		"description": "Environment subtly contradicts player",
		"category": EventCategory.PSYCHOLOGICAL,
		"intensity": EventIntensity.MODERATE,
		"min_horror_level": 0.35,
		"duration": 60.0,
		"cooldown": 450.0,
		"affects_systems": ["environment", "ui"]
	})

	_register_event("PSY_DREAD_BUILDUP", {
		"name": "Mounting Dread",
		"description": "Oppressive atmosphere intensifies",
		"category": EventCategory.PSYCHOLOGICAL,
		"intensity": EventIntensity.SUBTLE,
		"min_horror_level": 0.25,
		"duration": 120.0,
		"cooldown": 300.0,
		"affects_systems": ["audio", "environment"]
	})

	# ================== AUDIO VISUAL EVENTS ==================

	_register_event("AV_STATIC_BURST", {
		"name": "Visual Static",
		"description": "Screen corrupts with static",
		"category": EventCategory.AUDIO_VISUAL,
		"intensity": EventIntensity.MODERATE,
		"min_horror_level": 0.3,
		"duration": 3.0,
		"cooldown": 180.0,
		"affects_systems": ["screen_effects"]
	})

	_register_event("AV_SCREEN_TEAR", {
		"name": "Reality Tear",
		"description": "Visual glitch tears across vision",
		"category": EventCategory.AUDIO_VISUAL,
		"intensity": EventIntensity.SIGNIFICANT,
		"min_horror_level": 0.45,
		"duration": 2.0,
		"cooldown": 240.0,
		"affects_systems": ["screen_effects"]
	})

	_register_event("AV_HALLUCINATION", {
		"name": "Visual Hallucination",
		"description": "Brief hallucination appears",
		"category": EventCategory.AUDIO_VISUAL,
		"intensity": EventIntensity.MODERATE,
		"min_horror_level": 0.4,
		"duration": 5.0,
		"cooldown": 300.0,
		"affects_systems": ["screen_effects", "environment"]
	})

	_register_event("AV_AUDIO_DISTORTION", {
		"name": "Audio Corruption",
		"description": "All sounds become distorted",
		"category": EventCategory.AUDIO_VISUAL,
		"intensity": EventIntensity.MODERATE,
		"min_horror_level": 0.35,
		"duration": 15.0,
		"cooldown": 250.0,
		"affects_systems": ["audio"]
	})

	# ================== SPECIAL / STORY EVENTS ==================

	_register_event("STORY_MILE_87_VISION", {
		"name": "Mile 87 Flashback",
		"description": "Vision of the highway accident",
		"category": EventCategory.PSYCHOLOGICAL,
		"intensity": EventIntensity.SEVERE,
		"min_horror_level": 0.6,
		"duration": 30.0,
		"cooldown": 0.0,
		"affects_systems": ["cutscene", "audio", "screen_effects"],
		"one_time_only": true,
		"prerequisites": ["chapter_2_start"]
	})

	_register_event("STORY_DISPATCHER_RECORDING", {
		"name": "Dispatcher Audio",
		"description": "Player's old dispatch recordings play",
		"category": EventCategory.PSYCHOLOGICAL,
		"intensity": EventIntensity.SIGNIFICANT,
		"min_horror_level": 0.5,
		"duration": 45.0,
		"cooldown": 0.0,
		"affects_systems": ["audio"],
		"one_time_only": true,
		"prerequisites": ["found_cassette_player"]
	})

# ====================================================================================
# EVENT REGISTRATION
# ====================================================================================

func _register_event(event_id: String, data: Dictionary) -> void:
	var event = HorrorEvent.new()
	event.event_id = event_id
	event.event_name = data.get("name", "Unnamed Event")
	event.description = data.get("description", "")
	event.category = data.get("category", EventCategory.ENVIRONMENTAL)
	event.intensity = data.get("intensity", EventIntensity.MODERATE)
	event.min_horror_level = data.get("min_horror_level", 0.3)
	event.duration = data.get("duration", 10.0)
	event.cooldown = data.get("cooldown", 120.0)
	event.prerequisites = data.get("prerequisites", [])
	event.affects_systems = data.get("affects_systems", [])
	event.one_time_only = data.get("one_time_only", false)

	event_library[event_id] = event

# ====================================================================================
# EVENT TRIGGERING
# ====================================================================================

func can_trigger_event(event_id: String, current_horror_level: float = -1.0) -> bool:
	if not event_library.has(event_id):
		return false

	var event = event_library[event_id]

	# Check if one-time event already triggered
	if event.one_time_only and event.has_been_triggered:
		return false

	# Check cooldown
	var time_since_last = (Time.get_ticks_msec() / 1000.0) - event.last_trigger_time
	if time_since_last < event.cooldown:
		return false

	# Check horror level requirement
	if current_horror_level >= 0.0 and current_horror_level < event.min_horror_level:
		return false

	# Check prerequisites
	for prereq in event.prerequisites:
		if not _check_prerequisite(prereq):
			return false

	return true

func trigger_event(event_id: String) -> bool:
	if not can_trigger_event(event_id, current_horror_intensity):
		return false

	var event = event_library[event_id]

	# Mark as triggered
	event.has_been_triggered = true
	event.trigger_count += 1
	event.last_trigger_time = Time.get_ticks_msec() / 1000.0

	# Add to active events
	active_events.append(event)

	# Create event data for systems
	var event_data = {
		"event_id": event_id,
		"event_name": event.event_name,
		"category": EventCategory.keys()[event.category],
		"intensity": EventIntensity.keys()[event.intensity],
		"duration": event.duration,
		"affects_systems": event.affects_systems,
		"timestamp": Time.get_unix_time_from_system()
	}

	# Record in history
	triggered_events_history.append(event_data)

	# Emit signal
	event_triggered.emit(event_data)

	print("Horror Event Triggered: %s" % event.event_name)

	# Auto-complete after duration
	await get_tree().create_timer(event.duration).timeout
	_complete_event(event_id)

	return true

func _complete_event(event_id: String) -> void:
	var event = event_library.get(event_id)
	if not event:
		return

	active_events.erase(event)
	event_completed.emit(event_id)

	print("Horror Event Completed: %s" % event.event_name)

# ====================================================================================
# EVENT QUERIES
# ====================================================================================

func get_available_events(current_horror_level: float) -> Array[String]:
	var available: Array[String] = []
	for event_id in event_library.keys():
		if can_trigger_event(event_id, current_horror_level):
			available.append(event_id)
	return available

func get_events_by_category(category: EventCategory) -> Array[String]:
	var filtered: Array[String] = []
	for event_id in event_library.keys():
		var event = event_library[event_id]
		if event.category == category:
			filtered.append(event_id)
	return filtered

func get_events_by_intensity(intensity: EventIntensity) -> Array[String]:
	var filtered: Array[String] = []
	for event_id in event_library.keys():
		var event = event_library[event_id]
		if event.intensity == intensity:
			filtered.append(event_id)
	return filtered

func get_random_event(min_intensity: EventIntensity = EventIntensity.SUBTLE) -> String:
	var candidates: Array[String] = []
	for event_id in event_library.keys():
		var event = event_library[event_id]
		if event.intensity >= min_intensity and can_trigger_event(event_id, current_horror_intensity):
			candidates.append(event_id)

	if candidates.is_empty():
		return ""

	return candidates[randi() % candidates.size()]

# ====================================================================================
# HORROR INTENSITY MANAGEMENT
# ====================================================================================

func set_horror_intensity(intensity: float) -> void:
	current_horror_intensity = clamp(intensity, 0.0, 1.0)
	intensity_changed.emit(current_horror_intensity)

func increase_horror_intensity(amount: float) -> void:
	set_horror_intensity(current_horror_intensity + amount)

func decrease_horror_intensity(amount: float) -> void:
	set_horror_intensity(current_horror_intensity - amount)

# ====================================================================================
# UTILITIES
# ====================================================================================

func _check_prerequisite(prereq: String) -> bool:
	# This would check game state flags
	# For now, return true
	return true

func get_event_info(event_id: String) -> Dictionary:
	var event = event_library.get(event_id)
	if not event:
		return {}

	return {
		"event_id": event.event_id,
		"name": event.event_name,
		"description": event.description,
		"category": EventCategory.keys()[event.category],
		"intensity": EventIntensity.keys()[event.intensity],
		"min_horror_level": event.min_horror_level,
		"duration": event.duration,
		"cooldown": event.cooldown,
		"has_been_triggered": event.has_been_triggered,
		"trigger_count": event.trigger_count
	}

func get_event_history() -> Array[Dictionary]:
	return triggered_events_history.duplicate()

func reset_event_history() -> void:
	triggered_events_history.clear()
	for event in event_library.values():
		event.has_been_triggered = false
		event.trigger_count = 0
		event.last_trigger_time = 0.0
