extends Node
## Main game state manager
## Handles game modes, progression, and global state

# ============================================================================
# ENUMS
# ============================================================================

enum GameState {
	MENU,
	GAMEPLAY,
	APARTMENT,
	PAUSED,
	ENDING,
	LOADING
}

enum GameMode {
	STORY,
	ENDLESS,
	STREAMER
}

# ============================================================================
# STATE VARIABLES
# ============================================================================

var current_state: GameState = GameState.MENU
var current_mode: GameMode = GameMode.STORY
var current_chapter: int = 1
var current_shift: int = 1
var is_first_launch: bool = true

# ============================================================================
# STORY PROGRESSION
# ============================================================================

var story_flags: Dictionary = {}
var completed_shifts: Array = []
var unlocked_endings: Array = []

# ============================================================================
# ENDING TRACKING
# ============================================================================

var ending_conditions: Dictionary = {
	"guests_helped": 0,
	"guests_exploited": 0,
	"evidence_collected": [],
	"composure_breakdowns": 0,
	"trust_owner": 0,
	"trust_radio": 0,
	"trust_police": 0,
	"total_profit": 0.0,
	"investigations_completed": 0
}

# ============================================================================
# SIGNALS
# ============================================================================

signal game_state_changed(new_state: GameState)
signal chapter_completed(chapter_num: int)
signal mode_changed(new_mode: GameMode)

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	print("GameManager initialized")
	_check_first_launch()

# ============================================================================
# STATE MANAGEMENT
# ============================================================================

func change_state(new_state: GameState) -> void:
	"""Change the current game state"""
	if current_state == new_state:
		return

	var old_state = current_state
	current_state = new_state
	print("Game state changed: %s -> %s" % [GameState.keys()[old_state], GameState.keys()[new_state]])
	game_state_changed.emit(new_state)

func change_mode(new_mode: GameMode) -> void:
	"""Change the current game mode"""
	if current_mode == new_mode:
		return

	current_mode = new_mode
	print("Game mode changed to: %s" % GameMode.keys()[new_mode])
	mode_changed.emit(new_mode)

# ============================================================================
# PROGRESSION
# ============================================================================

func advance_chapter() -> void:
	"""Advance to the next chapter"""
	current_chapter += 1
	print("Advanced to Chapter %d" % current_chapter)
	EventBus.chapter_advanced.emit(current_chapter)
	chapter_completed.emit(current_chapter - 1)

func advance_shift() -> void:
	"""Advance to the next shift"""
	current_shift += 1
	completed_shifts.append(current_shift - 1)
	print("Advanced to Shift %d" % current_shift)

func complete_shift(results: Dictionary) -> void:
	"""Mark a shift as completed with results"""
	completed_shifts.append(current_shift)
	_update_ending_conditions(results)
	EventBus.shift_ended.emit(results)

# ============================================================================
# STORY FLAGS
# ============================================================================

func set_story_flag(flag_name: String, value: Variant) -> void:
	"""Set a story flag"""
	story_flags[flag_name] = value
	print("Story flag set: %s = %s" % [flag_name, str(value)])

func get_story_flag(flag_name: String, default_value: Variant = false) -> Variant:
	"""Get a story flag value"""
	return story_flags.get(flag_name, default_value)

func has_story_flag(flag_name: String) -> bool:
	"""Check if a story flag exists and is true"""
	return story_flags.get(flag_name, false) == true

# ============================================================================
# ENDING CONDITIONS
# ============================================================================

func _update_ending_conditions(shift_results: Dictionary) -> void:
	"""Update ending conditions based on shift results"""
	if shift_results.has("guests_helped"):
		ending_conditions["guests_helped"] += shift_results["guests_helped"]
	if shift_results.has("guests_exploited"):
		ending_conditions["guests_exploited"] += shift_results["guests_exploited"]
	if shift_results.has("profit"):
		ending_conditions["total_profit"] += shift_results["profit"]

func calculate_ending() -> String:
	"""Calculate which ending the player should receive"""
	var helped = ending_conditions["guests_helped"]
	var exploited = ending_conditions["guests_exploited"]
	var evidence_count = ending_conditions["evidence_collected"].size()
	var composure_breaks = ending_conditions["composure_breakdowns"]
	var profit = ending_conditions["total_profit"]

	# Ending A: RELEASE (help majority, collect evidence, maintain composure)
	if helped > exploited and evidence_count >= 15 and composure_breaks <= 2:
		return "RELEASE"

	# Ending B: CORRUPTION (exploit guests, maximize profit, ally with owner)
	elif exploited > helped and profit > 10000.0 and ending_conditions["trust_owner"] > 5:
		return "CORRUPTION"

	# Ending C: ESCAPE (moderate balance, incomplete evidence, flee)
	elif composure_breaks >= 3 and evidence_count < 10:
		return "ESCAPE"

	# Ending D: CYCLE (complete breakdown, trust radio voice)
	elif composure_breaks >= 5 and ending_conditions["trust_radio"] > 5:
		return "CYCLE"

	# Default to ESCAPE if no other conditions met
	return "ESCAPE"

func unlock_ending(ending_type: String) -> void:
	"""Unlock an ending"""
	if ending_type not in unlocked_endings:
		unlocked_endings.append(ending_type)
		EventBus.ending_unlocked.emit(ending_type)
		print("Ending unlocked: %s" % ending_type)

# ============================================================================
# UTILITY
# ============================================================================

func _check_first_launch() -> void:
	"""Check if this is the first time launching the game"""
	if SaveSystem.has_any_save():
		is_first_launch = false

func start_new_game(mode: GameMode = GameMode.STORY) -> void:
	"""Start a new game"""
	current_mode = mode
	current_chapter = 1
	current_shift = 1
	story_flags.clear()
	completed_shifts.clear()
	ending_conditions = {
		"guests_helped": 0,
		"guests_exploited": 0,
		"evidence_collected": [],
		"composure_breakdowns": 0,
		"trust_owner": 0,
		"trust_radio": 0,
		"trust_police": 0,
		"total_profit": 0.0,
		"investigations_completed": 0
	}
	print("Starting new game in %s mode" % GameMode.keys()[mode])

func get_chapter_name(chapter: int) -> String:
	"""Get the name of a chapter"""
	match chapter:
		1: return "ORIENTATION"
		2: return "PATTERNS"
		3: return "RECOGNITION"
		4: return "INVESTIGATION"
		5: return "CONVERGENCE"
		_: return "UNKNOWN"
