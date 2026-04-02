## StreamerMode - Phase 2 viewer interaction system.
## Provides an event API for external integrations (Twitch, YouTube, etc.)
## Viewers can trigger events, vote on weather, and influence gameplay.
class_name StreamerMode
extends Node

# --- Signals ---
signal viewer_event_triggered(event_type: String, data: Dictionary)
signal vote_started(vote_id: String, options: Array[String])
signal vote_ended(vote_id: String, winner: String)
signal command_received(command: String, viewer: String)

# --- State ---
var is_active: bool = false
var _is_connected: bool = false
var event_queue: Array[Dictionary] = []
var active_vote: Dictionary = {}
var vote_timer: float = 0.0
var cooldown_timers: Dictionary = {}  # event_type -> remaining cooldown
var viewer_credits: Dictionary = {}  # viewer_name -> credits

# --- Configuration ---
const VOTE_DURATION: float = 30.0
const EVENT_COOLDOWN: float = 60.0
const MAX_QUEUE_SIZE: int = 10
const DEFAULT_CREDITS: int = 3

# --- Event Definitions (what viewers can trigger) ---
var _viewer_events: Dictionary = {
	"customer_surge": {
		"name": "Customer Surge",
		"description": "5 customers arrive at once",
		"cost": 2,
		"cooldown": 120.0,
	},
	"power_cut": {
		"name": "Power Cut",
		"description": "All lights go out for 30 seconds",
		"cost": 3,
		"cooldown": 180.0,
	},
	"fake_reservation": {
		"name": "Fake Reservation",
		"description": "A phantom guest tries to check in",
		"cost": 1,
		"cooldown": 90.0,
	},
	"weather_change": {
		"name": "Weather Anomaly",
		"description": "Force a sudden weather change",
		"cost": 2,
		"cooldown": 120.0,
	},
	"pump_malfunction": {
		"name": "Pump Malfunction",
		"description": "A fuel pump starts acting up",
		"cost": 1,
		"cooldown": 90.0,
	},
	"suspicious_caller": {
		"name": "Suspicious Caller",
		"description": "A strange call comes through the radio",
		"cost": 1,
		"cooldown": 60.0,
	},
	"blackout_vote": {
		"name": "Blackout Vote",
		"description": "Starts a vote for full plaza blackout",
		"cost": 0,
		"cooldown": 300.0,
	},
	"help_mara": {
		"name": "Help Mara",
		"description": "Reduce Mara's stress and fatigue",
		"cost": 2,
		"cooldown": 120.0,
	},
	"speed_boost": {
		"name": "Speed Boost",
		"description": "Coffee machine works extra fast this shift",
		"cost": 1,
		"cooldown": 180.0,
	},
	"ghost_customer": {
		"name": "Ghost Customer",
		"description": "An anomaly customer appears",
		"cost": 3,
		"cooldown": 150.0,
	},
}

# --- Vote Templates ---
var _vote_templates: Dictionary = {
	"weather_vote": {
		"question": "What weather should hit Exit 13?",
		"options": ["Storm", "Fog", "Clear", "Dust"],
		"duration": 30.0,
	},
	"blackout_vote": {
		"question": "Should the power go out?",
		"options": ["Yes - Blackout!", "No - Keep the lights on"],
		"duration": 20.0,
	},
	"difficulty_vote": {
		"question": "Next shift difficulty?",
		"options": ["Easy Night", "Normal", "Nightmare"],
		"duration": 25.0,
	},
}


func _ready() -> void:
	set_process(false)  # Only process when active


func _process(delta: float) -> void:
	if not is_active:
		return

	# Update cooldowns
	for event_type in cooldown_timers.keys():
		cooldown_timers[event_type] -= delta
		if cooldown_timers[event_type] <= 0:
			cooldown_timers.erase(event_type)

	# Process vote
	if not active_vote.is_empty():
		vote_timer -= delta
		if vote_timer <= 0:
			_resolve_vote()

	# Process event queue
	if event_queue.size() > 0 and GameManager.current_state == GameManager.GameState.PLAYING:
		var next_event: Dictionary = event_queue.pop_front()
		_execute_viewer_event(next_event)


## Activate streamer mode.
func activate() -> void:
	is_active = true
	set_process(true)
	DialogueManager.show_subtitle("STREAMER MODE", "Viewer interaction enabled!")


## Deactivate streamer mode.
func deactivate() -> void:
	is_active = false
	set_process(false)
	event_queue.clear()
	active_vote.clear()


## Process an incoming viewer command.
## Called by the integration layer (HTTP server, WebSocket, etc.)
func process_command(viewer_name: String, command: String, args: Array = []) -> Dictionary:
	if not is_active:
		return {"success": false, "message": "Streamer mode is not active"}

	command_received.emit(command, viewer_name)

	match command:
		"trigger":
			if args.size() < 1:
				return {"success": false, "message": "Specify an event type"}
			return _try_queue_event(viewer_name, args[0])

		"vote":
			if args.size() < 1:
				return {"success": false, "message": "Specify a vote template"}
			return _start_vote(args[0])

		"cast_vote":
			if args.size() < 1:
				return {"success": false, "message": "Specify your vote option"}
			return _cast_vote(viewer_name, args[0])

		"status":
			return _get_status()

		"help":
			return _get_help()

		"credits":
			return {"success": true, "credits": _get_viewer_credits(viewer_name)}

		_:
			return {"success": false, "message": "Unknown command: " + command}


## Get available events for display.
func get_available_events() -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for event_type in _viewer_events:
		var event: Dictionary = _viewer_events[event_type].duplicate()
		event["type"] = event_type
		event["on_cooldown"] = cooldown_timers.has(event_type)
		if event["on_cooldown"]:
			event["cooldown_remaining"] = cooldown_timers[event_type]
		available.append(event)
	return available


## HTTP endpoint handler for external integrations.
## Returns JSON response data.
func handle_api_request(_method: String, path: String, body: Dictionary) -> Dictionary:
	match path:
		"/api/streamer/events":
			return {"events": get_available_events()}
		"/api/streamer/command":
			var viewer: String = body.get("viewer", "anonymous")
			var cmd: String = body.get("command", "")
			var args: Array = body.get("args", [])
			return process_command(viewer, cmd, args)
		"/api/streamer/vote":
			if not active_vote.is_empty():
				return {"vote": active_vote, "time_remaining": vote_timer}
			return {"vote": null}
		"/api/streamer/status":
			return _get_status()
		_:
			return {"error": "Unknown endpoint"}


# --- Private ---

func _try_queue_event(viewer_name: String, event_type: String) -> Dictionary:
	if not _viewer_events.has(event_type):
		return {"success": false, "message": "Unknown event: " + event_type}

	if cooldown_timers.has(event_type):
		return {"success": false, "message": "Event on cooldown: %.0fs remaining" % cooldown_timers[event_type]}

	if event_queue.size() >= MAX_QUEUE_SIZE:
		return {"success": false, "message": "Event queue is full"}

	var event: Dictionary = _viewer_events[event_type]
	var cost: int = event.get("cost", 0)
	var credits := _get_viewer_credits(viewer_name)

	if credits < cost:
		return {"success": false, "message": "Not enough credits (%d/%d)" % [credits, cost]}

	# Deduct credits
	viewer_credits[viewer_name] = credits - cost

	# Queue the event
	event_queue.append({
		"type": event_type,
		"viewer": viewer_name,
		"data": event,
	})

	# Set cooldown
	cooldown_timers[event_type] = event.get("cooldown", EVENT_COOLDOWN)

	viewer_event_triggered.emit(event_type, {"viewer": viewer_name})
	return {"success": true, "message": "%s triggered by %s!" % [event["name"], viewer_name]}


func _execute_viewer_event(event_data: Dictionary) -> void:
	var event_type: String = event_data.get("type", "")
	var viewer: String = event_data.get("viewer", "anonymous")

	DialogueManager.show_subtitle("VIEWER EVENT", "%s triggered by %s" % [_viewer_events[event_type]["name"], viewer])

	match event_type:
		"customer_surge":
			# Spawn multiple customers at once
			var shift_managers := get_tree().get_nodes_in_group("shift_manager")
			if shift_managers.size() > 0:
				var sm: ShiftManager = shift_managers[0]
				for i in range(5):
					sm.spawn_customer()

		"power_cut":
			# Trigger a blackout via power grids if available
			var power_grids: Array = get_tree().get_nodes_in_group("power_grid")
			if power_grids.size() > 0:
				power_grids[0].trigger_blackout()
			else:
				EventDirector.trigger_event({
					"id": "zone_blackout",
					"category": EventDirector.HorrorCategory.POWER_MANIPULATION,
					"description": "Viewer-triggered blackout",
					"intensity_boost": 0.2,
					"duration": 30.0,
				})

		"fake_reservation":
			var shift_managers2 := get_tree().get_nodes_in_group("shift_manager")
			if shift_managers2.size() > 0:
				var sm: ShiftManager = shift_managers2[0]
				sm.spawn_anomaly_customer()

		"weather_change":
			var weathers := [
				WeatherManager.WeatherType.STORM,
				WeatherManager.WeatherType.FOG,
				WeatherManager.WeatherType.HEAVY_RAIN,
				WeatherManager.WeatherType.DUST,
			]
			WeatherManager.set_weather(weathers[randi() % weathers.size()])

		"pump_malfunction":
			DialogueManager.show_subtitle("", "[Pump 3 starts making strange noises]")
			GameManager.stress += 5.0

		"suspicious_caller":
			EventDirector.trigger_event({
				"id": "false_emergency_call",
				"category": EventDirector.HorrorCategory.FALSE_CALL,
				"description": "Viewer-triggered suspicious call",
				"intensity_boost": 0.15,
				"duration": 60.0,
			})

		"blackout_vote":
			_start_vote("blackout_vote")

		"help_mara":
			GameManager.stress = maxf(GameManager.stress - 20.0, 0.0)
			GameManager.fatigue = maxf(GameManager.fatigue - 15.0, 0.0)
			GameManager.composure = minf(GameManager.composure + 10.0, 100.0)
			DialogueManager.show_subtitle("Mara", "I feel... better somehow.")

		"speed_boost":
			DialogueManager.show_subtitle("", "[The coffee machine hums with unusual energy]")

		"ghost_customer":
			var shift_managers3 := get_tree().get_nodes_in_group("shift_manager")
			if shift_managers3.size() > 0:
				var sm: ShiftManager = shift_managers3[0]
				sm.spawn_anomaly_customer()
			GameManager.stress += 10.0


func _start_vote(template_id: String) -> Dictionary:
	if not active_vote.is_empty():
		return {"success": false, "message": "A vote is already in progress"}

	if not _vote_templates.has(template_id):
		return {"success": false, "message": "Unknown vote template"}

	var template: Dictionary = _vote_templates[template_id]
	active_vote = {
		"id": template_id,
		"question": template["question"],
		"options": template["options"],
		"votes": {},  # viewer -> option_index
		"tallies": [],
	}
	for i in range(template["options"].size()):
		active_vote["tallies"].append(0)

	vote_timer = template.get("duration", VOTE_DURATION)
	vote_started.emit(template_id, template["options"])

	DialogueManager.show_subtitle("VOTE", template["question"])
	return {"success": true, "message": "Vote started!"}


func _cast_vote(viewer_name: String, option: String) -> Dictionary:
	if active_vote.is_empty():
		return {"success": false, "message": "No active vote"}

	# Find option index
	var option_index := -1
	for i in range(active_vote["options"].size()):
		if active_vote["options"][i].to_lower() == option.to_lower():
			option_index = i
			break
	# Try numeric
	if option_index < 0 and option.is_valid_int():
		option_index = option.to_int() - 1

	if option_index < 0 or option_index >= active_vote["options"].size():
		return {"success": false, "message": "Invalid option"}

	# Remove previous vote if exists
	if active_vote["votes"].has(viewer_name):
		var prev: int = active_vote["votes"][viewer_name]
		active_vote["tallies"][prev] -= 1

	active_vote["votes"][viewer_name] = option_index
	active_vote["tallies"][option_index] += 1

	return {"success": true, "message": "Vote cast for: " + active_vote["options"][option_index]}


func _resolve_vote() -> void:
	if active_vote.is_empty():
		return

	var tallies: Array = active_vote["tallies"]
	var max_votes := 0
	var winner_index := 0
	for i in range(tallies.size()):
		if tallies[i] > max_votes:
			max_votes = tallies[i]
			winner_index = i

	var winner: String = active_vote["options"][winner_index]
	var vote_id: String = active_vote["id"]

	DialogueManager.show_subtitle("VOTE RESULT", "Winner: %s (%d votes)" % [winner, max_votes])
	vote_ended.emit(vote_id, winner)

	# Apply vote result
	_apply_vote_result(vote_id, winner_index)

	active_vote.clear()


func _apply_vote_result(vote_id: String, winner_index: int) -> void:
	match vote_id:
		"weather_vote":
			var weather_map := [
				WeatherManager.WeatherType.STORM,
				WeatherManager.WeatherType.FOG,
				WeatherManager.WeatherType.CLEAR,
				WeatherManager.WeatherType.DUST,
			]
			if winner_index < weather_map.size():
				WeatherManager.set_weather(weather_map[winner_index])
		"blackout_vote":
			if winner_index == 0:  # Yes
				EventDirector.trigger_event({
					"id": "zone_blackout",
					"category": EventDirector.HorrorCategory.POWER_MANIPULATION,
					"description": "Viewer-voted blackout!",
					"intensity_boost": 0.25,
					"duration": 45.0,
				})
		"difficulty_vote":
			match winner_index:
				0:
					EventDirector.horror_intensity *= 0.5
				1:
					pass  # Normal
				2:
					EventDirector.horror_intensity = minf(EventDirector.horror_intensity + 0.3, 1.0)


func _get_viewer_credits(viewer_name: String) -> int:
	if not viewer_credits.has(viewer_name):
		viewer_credits[viewer_name] = DEFAULT_CREDITS
	return viewer_credits[viewer_name]


func _get_status() -> Dictionary:
	return {
		"active": is_active,
		"connected": _is_connected,
		"queue_size": event_queue.size(),
		"vote_active": not active_vote.is_empty(),
		"vote_timer": vote_timer if not active_vote.is_empty() else 0.0,
		"current_shift": GameManager.current_shift,
		"horror_intensity": EventDirector.horror_intensity,
		"cooldowns": cooldown_timers.duplicate(),
	}


func _get_help() -> Dictionary:
	var commands := {
		"trigger <event>": "Trigger a viewer event (costs credits)",
		"vote <template>": "Start a community vote",
		"cast_vote <option>": "Cast your vote in an active poll",
		"status": "Get current game status",
		"credits": "Check your credit balance",
		"help": "Show this help message",
	}
	var events_list := {}
	for event_type in _viewer_events:
		var e: Dictionary = _viewer_events[event_type]
		events_list[event_type] = "%s (%d credits)" % [e["name"], e["cost"]]
	return {"commands": commands, "events": events_list}
