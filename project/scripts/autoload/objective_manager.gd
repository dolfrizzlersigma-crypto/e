## ObjectiveManager - Tracks shift objectives, tasks, and story goals.
## Provides the task list that drives the gameplay loop.
extends Node

# --- Signals ---
signal objective_added(objective: Dictionary)
signal objective_completed(objective_id: String)
signal objective_failed(objective_id: String)
signal objective_updated(objective_id: String, progress: float)
signal all_objectives_complete()

# --- State ---
var active_objectives: Array[Dictionary] = []
var completed_objectives: Array[String] = []
var failed_objectives: Array[String] = []

# Objective format:
# {
#   "id": "restock_shelves",
#   "title": "Restock the shelves",
#   "description": "Place items from the stockroom onto empty shelf spaces",
#   "type": "task" | "story" | "optional" | "hidden",
#   "progress": 0.0,
#   "target": 1.0,
#   "time_limit": -1.0,  # -1 = no limit
#   "timer": 0.0,
#   "reward_cash": 0.0,
#   "reward_reputation": 0.0,
#   "penalty_reputation": 0.0,
# }


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	_update_timers(delta)


## Add a new objective.
func add_objective(data: Dictionary) -> void:
	# Ensure required fields
	if not data.has("id") or not data.has("title"):
		return
	# Don't add duplicates
	for obj in active_objectives:
		if obj["id"] == data["id"]:
			return

	var objective := {
		"id": data["id"],
		"title": data["title"],
		"description": data.get("description", ""),
		"type": data.get("type", "task"),
		"progress": data.get("progress", 0.0),
		"target": data.get("target", 1.0),
		"time_limit": data.get("time_limit", -1.0),
		"timer": 0.0,
		"reward_cash": data.get("reward_cash", 0.0),
		"reward_reputation": data.get("reward_reputation", 0.0),
		"penalty_reputation": data.get("penalty_reputation", 0.0),
	}
	active_objectives.append(objective)
	objective_added.emit(objective)


## Update progress on an objective.
func update_progress(objective_id: String, amount: float = 1.0) -> void:
	for obj in active_objectives:
		if obj["id"] == objective_id:
			obj["progress"] = minf(obj["progress"] + amount, obj["target"])
			objective_updated.emit(objective_id, obj["progress"] / obj["target"])
			if obj["progress"] >= obj["target"]:
				complete_objective(objective_id)
			return


## Complete an objective.
func complete_objective(objective_id: String) -> void:
	for i in range(active_objectives.size() - 1, -1, -1):
		if active_objectives[i]["id"] == objective_id:
			var obj := active_objectives[i]
			# Apply rewards
			if obj["reward_cash"] > 0:
				GameManager.cash += obj["reward_cash"]
			if obj["reward_reputation"] > 0:
				GameManager.reputation += obj["reward_reputation"]
			active_objectives.remove_at(i)
			completed_objectives.append(objective_id)
			objective_completed.emit(objective_id)
			# Check if all objectives are done
			if _all_required_complete():
				all_objectives_complete.emit()
			return


## Fail an objective.
func fail_objective(objective_id: String) -> void:
	for i in range(active_objectives.size() - 1, -1, -1):
		if active_objectives[i]["id"] == objective_id:
			var obj := active_objectives[i]
			if obj["penalty_reputation"] > 0:
				GameManager.reputation -= obj["penalty_reputation"]
			active_objectives.remove_at(i)
			failed_objectives.append(objective_id)
			objective_failed.emit(objective_id)
			return


## Check if an objective is active.
func is_objective_active(objective_id: String) -> bool:
	for obj in active_objectives:
		if obj["id"] == objective_id:
			return true
	return false


## Check if an objective has been completed.
func is_objective_completed(objective_id: String) -> bool:
	return objective_id in completed_objectives


## Get active objectives for UI display (excludes hidden).
func get_visible_objectives() -> Array[Dictionary]:
	var visible: Array[Dictionary] = []
	for obj in active_objectives:
		if obj["type"] != "hidden":
			visible.append(obj)
	return visible


## Clear all objectives for a new shift.
func clear_for_new_shift() -> void:
	active_objectives.clear()
	completed_objectives.clear()
	failed_objectives.clear()


## Generate standard shift objectives.
func generate_shift_objectives(shift_number: int) -> void:
	clear_for_new_shift()

	# Core objectives every shift
	add_objective({
		"id": "clock_in",
		"title": "Clock In",
		"description": "Use the time clock to start your shift",
		"type": "task",
		"reward_cash": 5.0,
	})
	add_objective({
		"id": "read_shift_notes",
		"title": "Read Shift Notes",
		"description": "Check the clipboard on the counter for tonight's notes",
		"type": "task",
	})
	add_objective({
		"id": "check_occupancy",
		"title": "Check Motel Occupancy",
		"description": "Review the room board behind the motel desk",
		"type": "task",
	})
	add_objective({
		"id": "verify_breakers",
		"title": "Verify Breaker Status",
		"description": "Check the breaker panel in the utility room",
		"type": "task",
	})
	add_objective({
		"id": "brew_coffee",
		"title": "Brew Coffee",
		"description": "Start the coffee machine for overnight customers",
		"type": "task",
		"reward_reputation": 2.0,
	})

	# Progressive objectives based on shift number
	if shift_number >= 2:
		add_objective({
			"id": "restock_shelves",
			"title": "Restock Shelves",
			"description": "Restock empty shelves from the stockroom",
			"type": "task",
			"target": 3.0,
			"reward_cash": 3.0,
			"reward_reputation": 3.0,
		})
	if shift_number >= 3:
		add_objective({
			"id": "clean_bathrooms",
			"title": "Clean Bathrooms",
			"description": "Clean the public restrooms",
			"type": "task",
			"reward_reputation": 5.0,
			"penalty_reputation": 3.0,
			"time_limit": 180.0,
		})

	# Shift-end objective (always present)
	add_objective({
		"id": "reconcile_till",
		"title": "Reconcile the Till",
		"description": "Count the register at the end of your shift",
		"type": "task",
	})


## Get save data.
func get_save_data() -> Dictionary:
	return {
		"active": active_objectives,
		"completed": completed_objectives,
		"failed": failed_objectives,
	}


## Load save data.
func load_save_data(data: Dictionary) -> void:
	active_objectives.assign(data.get("active", []))
	completed_objectives.assign(data.get("completed", []))
	failed_objectives.assign(data.get("failed", []))


# --- Private ---

func _update_timers(delta: float) -> void:
	for obj in active_objectives:
		if obj["time_limit"] > 0:
			obj["timer"] += delta
			if obj["timer"] >= obj["time_limit"]:
				fail_objective(obj["id"])


func _all_required_complete() -> bool:
	for obj in active_objectives:
		if obj["type"] == "task" or obj["type"] == "story":
			return false
	return true
