## GameManager - Central game state singleton.
## Manages game mode, shift state, player stats, and global flags.
extends Node

# --- Signals ---
signal game_state_changed(new_state: GameState)
signal shift_started(shift_number: int)
signal shift_ended(shift_number: int)
signal stat_changed(stat_name: String, old_value: float, new_value: float)
signal money_changed(amount: float)
signal reputation_changed(value: float)
signal game_over(ending_id: String)

# --- Enums ---
enum GameState { MENU, PLAYING, PAUSED, CUTSCENE, SHIFT_END, GAME_OVER }
enum GameMode { STORY, ENDLESS, STREAMER }
enum ShiftPhase { PRE_SHIFT, EARLY_NIGHT, MID_NIGHT, LATE_NIGHT, DAWN, POST_SHIFT }

# --- Constants ---
const SHIFT_DURATION_SECONDS: float = 480.0  # 8 minutes real-time = 1 shift (8 hours in-game)
const TIME_SCALE: float = 60.0  # 1 real second = 1 in-game minute
const MAX_STAT: float = 100.0

# --- Player Stats ---
var fatigue: float = 0.0:
	set(value):
		var old = fatigue
		fatigue = clampf(value, 0.0, MAX_STAT)
		if old != fatigue:
			stat_changed.emit("fatigue", old, fatigue)
var stress: float = 0.0:
	set(value):
		var old = stress
		stress = clampf(value, 0.0, MAX_STAT)
		if old != stress:
			stat_changed.emit("stress", old, stress)
var composure: float = MAX_STAT:
	set(value):
		var old = composure
		composure = clampf(value, 0.0, MAX_STAT)
		if old != composure:
			stat_changed.emit("composure", old, composure)

# --- Economy ---
var cash: float = 50.0:
	set(value):
		var old = cash
		cash = maxf(value, 0.0)
		if old != cash:
			money_changed.emit(cash)
var reputation: float = 50.0:
	set(value):
		var old = reputation
		reputation = clampf(value, 0.0, MAX_STAT)
		if old != reputation:
			reputation_changed.emit(reputation)

# --- Facility ---
var facility_condition: float = 50.0
var electrical_stability: float = MAX_STAT
var security_level: float = 50.0

# --- Game State ---
var current_state: GameState = GameState.MENU:
	set(value):
		current_state = value
		game_state_changed.emit(current_state)
var current_mode: GameMode = GameMode.STORY
var current_shift: int = 1
var current_shift_phase: ShiftPhase = ShiftPhase.PRE_SHIFT
var shift_time_elapsed: float = 0.0
var in_game_hour: int = 22  # Shift starts at 10 PM
var in_game_minute: int = 0

# --- Story Progress ---
var story_chapter: int = 1
var story_flags: Dictionary = {}
var choice_history: Array[Dictionary] = []
var collected_evidence: Array[String] = []
var ending_scores: Dictionary = {
	"truth": 0,
	"profit": 0,
	"composure": 0,
	"trust_owner": 0,
	"trust_police": 0,
	"trust_radio": 0,
	"guest_protection": 0,
}

# --- Upgrade Tracking ---
var purchased_upgrades: Array[String] = []

# --- Shift Tracking ---
var shift_customers_served: int = 0
var shift_incidents: Array[Dictionary] = []
var shift_revenue: float = 0.0
var shift_expenses: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if current_state != GameState.PLAYING:
		return
	_update_shift_time(delta)
	_update_passive_stats(delta)


## Start a new game in the specified mode.
func start_new_game(mode: GameMode) -> void:
	current_mode = mode
	current_shift = 1
	_reset_stats()
	_reset_story()
	current_state = GameState.PLAYING
	shift_started.emit(current_shift)


## Begin a new shift.
func begin_shift() -> void:
	shift_time_elapsed = 0.0
	in_game_hour = 22
	in_game_minute = 0
	current_shift_phase = ShiftPhase.PRE_SHIFT
	shift_customers_served = 0
	shift_incidents.clear()
	shift_revenue = 0.0
	shift_expenses = 0.0
	current_state = GameState.PLAYING
	shift_started.emit(current_shift)


## End the current shift and transition to post-shift.
func end_shift() -> void:
	current_shift_phase = ShiftPhase.POST_SHIFT
	current_state = GameState.SHIFT_END
	shift_ended.emit(current_shift)
	current_shift += 1


## Record a player choice for ending calculation.
func record_choice(choice_id: String, category: String, weight: float = 1.0) -> void:
	choice_history.append({
		"id": choice_id,
		"category": category,
		"weight": weight,
		"shift": current_shift,
	})
	if ending_scores.has(category):
		ending_scores[category] += weight


## Add evidence to the collection.
func collect_evidence(evidence_id: String) -> void:
	if evidence_id not in collected_evidence:
		collected_evidence.append(evidence_id)


## Check if an upgrade has been purchased.
func has_upgrade(upgrade_id: String) -> bool:
	return upgrade_id in purchased_upgrades


## Purchase an upgrade.
func purchase_upgrade(upgrade_id: String, cost: float) -> bool:
	if cash >= cost and upgrade_id not in purchased_upgrades:
		cash -= cost
		purchased_upgrades.append(upgrade_id)
		return true
	return false


## Set a story flag.
func set_story_flag(flag: String, value: Variant = true) -> void:
	story_flags[flag] = value


## Check a story flag.
func get_story_flag(flag: String, default_value: Variant = false) -> Variant:
	return story_flags.get(flag, default_value)


## Get the serializable game state for saving.
func get_save_data() -> Dictionary:
	return {
		"version": "0.1.0",
		"mode": current_mode,
		"shift": current_shift,
		"chapter": story_chapter,
		"fatigue": fatigue,
		"stress": stress,
		"composure": composure,
		"cash": cash,
		"reputation": reputation,
		"facility_condition": facility_condition,
		"electrical_stability": electrical_stability,
		"security_level": security_level,
		"story_flags": story_flags,
		"choice_history": choice_history,
		"collected_evidence": collected_evidence,
		"ending_scores": ending_scores,
		"purchased_upgrades": purchased_upgrades,
	}


## Load game state from save data.
func load_save_data(data: Dictionary) -> void:
	current_mode = data.get("mode", GameMode.STORY)
	current_shift = data.get("shift", 1)
	story_chapter = data.get("chapter", 1)
	fatigue = data.get("fatigue", 0.0)
	stress = data.get("stress", 0.0)
	composure = data.get("composure", MAX_STAT)
	cash = data.get("cash", 50.0)
	reputation = data.get("reputation", 50.0)
	facility_condition = data.get("facility_condition", 50.0)
	electrical_stability = data.get("electrical_stability", MAX_STAT)
	security_level = data.get("security_level", 50.0)
	story_flags = data.get("story_flags", {})
	choice_history.assign(data.get("choice_history", []))
	collected_evidence.assign(data.get("collected_evidence", []))
	ending_scores = data.get("ending_scores", ending_scores)
	purchased_upgrades.assign(data.get("purchased_upgrades", []))


# --- Private Methods ---

func _update_shift_time(delta: float) -> void:
	shift_time_elapsed += delta
	# Convert to in-game time
	var total_minutes: float = shift_time_elapsed * TIME_SCALE
	in_game_hour = 22 + int(total_minutes / 60.0)
	in_game_minute = int(fmod(total_minutes, 60.0))
	if in_game_hour >= 24:
		in_game_hour -= 24
	# Update shift phase
	var old_phase := current_shift_phase
	if total_minutes < 30:
		current_shift_phase = ShiftPhase.PRE_SHIFT
	elif total_minutes < 180:
		current_shift_phase = ShiftPhase.EARLY_NIGHT
	elif total_minutes < 300:
		current_shift_phase = ShiftPhase.MID_NIGHT
	elif total_minutes < 420:
		current_shift_phase = ShiftPhase.LATE_NIGHT
	elif total_minutes < 480:
		current_shift_phase = ShiftPhase.DAWN
	else:
		end_shift()
	if old_phase != current_shift_phase:
		EventDirector.on_phase_changed(current_shift_phase)


func _update_passive_stats(delta: float) -> void:
	# Fatigue slowly increases over the shift
	fatigue += delta * 0.3
	# Stress decays slowly if composure is high
	if composure > 60.0:
		stress -= delta * 0.05
	# Composure recovers very slowly
	if stress < 30.0:
		composure += delta * 0.02


func _reset_stats() -> void:
	fatigue = 0.0
	stress = 0.0
	composure = MAX_STAT
	cash = 50.0
	reputation = 50.0
	facility_condition = 50.0
	electrical_stability = MAX_STAT
	security_level = 50.0


func _reset_story() -> void:
	story_chapter = 1
	story_flags.clear()
	choice_history.clear()
	collected_evidence.clear()
	purchased_upgrades.clear()
	ending_scores = {
		"truth": 0,
		"profit": 0,
		"composure": 0,
		"trust_owner": 0,
		"trust_police": 0,
		"trust_radio": 0,
		"guest_protection": 0,
	}
