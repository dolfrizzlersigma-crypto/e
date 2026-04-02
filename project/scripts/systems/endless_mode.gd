## EndlessMode - Procedural shift generation for infinite replayability.
## Generates randomized customers, events, weather, and objectives each shift.
class_name EndlessMode
extends Node

# --- Signals ---
signal endless_shift_started(shift_number: int)
signal high_score_achieved(score: int)
signal difficulty_increased(new_level: int)

# --- State ---
var is_active: bool = false
var endless_shift_number: int = 0
var total_score: int = 0
var difficulty_level: int = 1
var best_score: int = 0

# --- Scoring ---
var shift_score: int = 0
var customer_bonus: int = 0
var efficiency_bonus: int = 0
var horror_survival_bonus: int = 0
var no_complaint_bonus: int = 0

# --- Configuration ---
const BASE_CUSTOMERS_PER_SHIFT: int = 5
const CUSTOMER_INCREASE_PER_LEVEL: int = 2
const BASE_HORROR_INTENSITY: float = 0.1
const HORROR_INCREASE_PER_LEVEL: float = 0.08
const DIFFICULTY_INCREASE_INTERVAL: int = 3  # Every 3 shifts
const MAX_DIFFICULTY: int = 20

# --- Procedural Generation ---
var _weather_pool: Array = [
	WeatherManager.WeatherType.CLEAR,
	WeatherManager.WeatherType.OVERCAST,
	WeatherManager.WeatherType.FOG,
	WeatherManager.WeatherType.LIGHT_RAIN,
	WeatherManager.WeatherType.HEAVY_RAIN,
	WeatherManager.WeatherType.STORM,
	WeatherManager.WeatherType.DUST,
]

var _shift_modifier_pool: Array[Dictionary] = [
	{"name": "Busy Night", "customer_mult": 1.5, "revenue_mult": 1.0, "horror_mult": 0.8},
	{"name": "Dead Quiet", "customer_mult": 0.5, "revenue_mult": 1.0, "horror_mult": 1.5},
	{"name": "Storm Warning", "customer_mult": 0.7, "revenue_mult": 1.2, "horror_mult": 1.3},
	{"name": "Double Pay", "customer_mult": 1.0, "revenue_mult": 2.0, "horror_mult": 1.0},
	{"name": "Power Problems", "customer_mult": 0.8, "revenue_mult": 1.0, "horror_mult": 1.5},
	{"name": "Full Moon", "customer_mult": 1.2, "revenue_mult": 1.0, "horror_mult": 2.0},
	{"name": "Highway Closure", "customer_mult": 2.0, "revenue_mult": 0.8, "horror_mult": 0.5},
	{"name": "Inspection Night", "customer_mult": 1.0, "revenue_mult": 1.0, "horror_mult": 0.3},
	{"name": "Fog Bank", "customer_mult": 0.6, "revenue_mult": 1.0, "horror_mult": 1.8},
	{"name": "Long Weekend", "customer_mult": 1.8, "revenue_mult": 1.3, "horror_mult": 1.0},
]

var _current_modifier: Dictionary = {}


func _ready() -> void:
	GameManager.shift_ended.connect(_on_shift_ended)


## Start endless mode.
func start() -> void:
	is_active = true
	endless_shift_number = 0
	total_score = 0
	difficulty_level = 1
	_load_best_score()
	start_next_shift()


## Generate and start the next endless shift.
func start_next_shift() -> void:
	endless_shift_number += 1

	# Increase difficulty every N shifts
	if endless_shift_number % DIFFICULTY_INCREASE_INTERVAL == 0 and difficulty_level < MAX_DIFFICULTY:
		difficulty_level += 1
		difficulty_increased.emit(difficulty_level)

	# Select random modifier
	_current_modifier = _shift_modifier_pool[randi() % _shift_modifier_pool.size()]

	# Generate weather
	_generate_weather()

	# Generate objectives
	_generate_objectives()

	# Configure horror intensity
	_configure_horror()

	# Reset shift scores
	shift_score = 0
	customer_bonus = 0
	efficiency_bonus = 0
	horror_survival_bonus = 0
	no_complaint_bonus = 0

	# Start the shift
	GameManager.begin_shift()
	endless_shift_started.emit(endless_shift_number)

	# Show shift info
	var modifier_name: String = _current_modifier.get("name", "Normal")
	DialogueManager.show_subtitle("SHIFT REPORT",
		"Endless Shift %d | Difficulty %d | %s" % [endless_shift_number, difficulty_level, modifier_name])


## Calculate end-of-shift score.
func calculate_shift_score() -> Dictionary:
	# Base score for completing the shift
	var base_score := 100 * difficulty_level

	# Customer service bonus
	customer_bonus = GameManager.shift_customers_served * 15

	# Revenue efficiency (compared to expected)
	var expected_revenue: float = 50.0 * difficulty_level
	var revenue_ratio := GameManager.shift_revenue / maxf(expected_revenue, 1.0)
	efficiency_bonus = int(revenue_ratio * 50)

	# Horror survival bonus (more points for higher horror survived)
	horror_survival_bonus = int(EventDirector.horror_intensity * 100)

	# No complaint bonus
	no_complaint_bonus = 50 if GameManager.reputation >= 50.0 else 0

	# Composure bonus
	var composure_bonus := int(GameManager.composure * 0.5)

	shift_score = base_score + customer_bonus + efficiency_bonus + horror_survival_bonus + no_complaint_bonus + composure_bonus
	total_score += shift_score

	# Check high score
	if total_score > best_score:
		best_score = total_score
		_save_best_score()
		high_score_achieved.emit(best_score)

	return {
		"shift_number": endless_shift_number,
		"difficulty": difficulty_level,
		"modifier": _current_modifier.get("name", "Normal"),
		"base_score": base_score,
		"customer_bonus": customer_bonus,
		"efficiency_bonus": efficiency_bonus,
		"horror_bonus": horror_survival_bonus,
		"complaint_bonus": no_complaint_bonus,
		"composure_bonus": composure_bonus,
		"shift_total": shift_score,
		"running_total": total_score,
		"best_score": best_score,
	}


## Get the current shift modifier description.
func get_modifier_description() -> String:
	if _current_modifier.is_empty():
		return "Normal shift"
	var name_str: String = _current_modifier.get("name", "Normal")
	var desc := name_str + " | "
	if _current_modifier.get("customer_mult", 1.0) > 1.2:
		desc += "More customers. "
	elif _current_modifier.get("customer_mult", 1.0) < 0.8:
		desc += "Fewer customers. "
	if _current_modifier.get("horror_mult", 1.0) > 1.3:
		desc += "Increased paranormal activity. "
	elif _current_modifier.get("horror_mult", 1.0) < 0.5:
		desc += "Quiet night. "
	if _current_modifier.get("revenue_mult", 1.0) > 1.5:
		desc += "Double pay! "
	return desc


# --- Private ---

func _generate_weather() -> void:
	# Higher difficulty = worse weather more likely
	var storm_chance := 0.05 + difficulty_level * 0.03
	if randf() < storm_chance:
		WeatherManager.set_weather(WeatherManager.WeatherType.STORM)
	elif randf() < storm_chance * 2:
		WeatherManager.set_weather(WeatherManager.WeatherType.HEAVY_RAIN)
	else:
		var weather := _weather_pool[randi() % _weather_pool.size()]
		WeatherManager.set_weather(weather)


func _generate_objectives() -> void:
	ObjectiveManager.clear_for_new_shift()

	# Always have basic objectives
	ObjectiveManager.add_objective({
		"id": "clock_in",
		"title": "Clock In",
		"description": "Start your shift",
		"type": "task",
		"reward_cash": 5.0 + difficulty_level * 2.0,
	})
	ObjectiveManager.add_objective({
		"id": "brew_coffee",
		"title": "Brew Coffee",
		"description": "Start the coffee machine",
		"type": "task",
		"reward_reputation": 2.0,
	})
	ObjectiveManager.add_objective({
		"id": "reconcile_till",
		"title": "Reconcile the Till",
		"description": "Balance the register at end of shift",
		"type": "task",
	})

	# Difficulty-scaled objectives
	if difficulty_level >= 2:
		ObjectiveManager.add_objective({
			"id": "restock_shelves",
			"title": "Restock Shelves",
			"description": "Restock %d shelf sections" % mini(difficulty_level, 6),
			"type": "task",
			"target": float(mini(difficulty_level, 6)),
			"reward_cash": 3.0 * difficulty_level,
			"reward_reputation": 3.0,
		})

	if difficulty_level >= 3:
		ObjectiveManager.add_objective({
			"id": "clean_bathrooms",
			"title": "Clean Bathrooms",
			"description": "Clean the public restrooms",
			"type": "task",
			"time_limit": maxf(180.0 - difficulty_level * 10, 60.0),
			"reward_reputation": 5.0,
			"penalty_reputation": 5.0,
		})

	if difficulty_level >= 5:
		ObjectiveManager.add_objective({
			"id": "process_delivery",
			"title": "Process Night Delivery",
			"description": "Handle the incoming supply delivery",
			"type": "task",
			"time_limit": 120.0,
			"reward_cash": 10.0,
			"reward_reputation": 3.0,
		})

	# Random bonus objective
	if randf() < 0.3 + difficulty_level * 0.05:
		var bonus_objectives := [
			{"id": "perfect_transactions", "title": "Perfect Transactions", "description": "Complete 3 transactions without errors", "target": 3.0, "reward_cash": 20.0},
			{"id": "all_rooms_clean", "title": "All Rooms Clean", "description": "Clean every checked-out room", "target": 2.0, "reward_reputation": 8.0},
			{"id": "no_complaints", "title": "Zero Complaints", "description": "End the shift with no customer complaints", "reward_reputation": 10.0},
			{"id": "investigate_anomaly", "title": "Investigate Anomaly", "description": "Investigate a paranormal occurrence", "reward_cash": 15.0},
		]
		var bonus := bonus_objectives[randi() % bonus_objectives.size()]
		bonus["type"] = "optional"
		ObjectiveManager.add_objective(bonus)


func _configure_horror() -> void:
	var base_intensity := BASE_HORROR_INTENSITY + difficulty_level * HORROR_INCREASE_PER_LEVEL
	var modifier_mult: float = _current_modifier.get("horror_mult", 1.0)
	EventDirector.horror_intensity = clampf(base_intensity * modifier_mult, 0.0, 0.8)
	EventDirector.reset_for_shift()

	# At higher difficulties, queue specific scary events
	if difficulty_level >= 5 and randf() < 0.4:
		EventDirector.queue_scripted_event({
			"id": "cctv_doppelganger",
			"category": EventDirector.HorrorCategory.CCTV_CONTRADICTION,
			"description": "CCTV shows you behind the counter while you're elsewhere",
			"intensity_boost": 0.3,
			"duration": 20.0,
		})

	if difficulty_level >= 8 and randf() < 0.3:
		EventDirector.queue_scripted_event({
			"id": "lost_found_pileup",
			"category": EventDirector.HorrorCategory.ENVIRONMENTAL_DISTORTION,
			"description": "The lost-and-found fills with items from Mile 87",
			"intensity_boost": 0.25,
			"duration": 20.0,
		})


func _on_shift_ended(_shift_num: int) -> void:
	if not is_active:
		return
	var results := calculate_shift_score()
	# Display results through dialogue
	var summary := "SHIFT %d COMPLETE\n" % results["shift_number"]
	summary += "Score: %d | Total: %d\n" % [results["shift_total"], results["running_total"]]
	summary += "Best: %d" % results["best_score"]
	DialogueManager.show_subtitle("ENDLESS MODE", summary)


func _load_best_score() -> void:
	var path := "user://saves/endless_best.json"
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			var json := JSON.new()
			if json.parse(file.get_as_text()) == OK:
				best_score = json.data.get("best_score", 0)
			file.close()


func _save_best_score() -> void:
	var path := "user://saves/endless_best.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"best_score": best_score}))
		file.close()
