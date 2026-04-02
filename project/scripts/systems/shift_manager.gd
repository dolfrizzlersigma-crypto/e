## ShiftManager - Controls the shift lifecycle from clock-in to reconciliation.
## Orchestrates objectives, events, customers, and shift transitions.
class_name ShiftManager
extends Node

# --- Signals ---
signal shift_phase_changed(phase: String)
signal customer_spawned(customer_data: Dictionary)
signal delivery_arrived(delivery_data: Dictionary)
signal shift_summary_ready(summary: Dictionary)

# --- State ---
var is_shift_active: bool = false
var customer_spawn_timer: float = 0.0
var delivery_timer: float = 0.0
var shift_events_triggered: int = 0

# --- Configuration ---
const BASE_CUSTOMER_INTERVAL: float = 45.0  # Base seconds between customers
const MIN_CUSTOMER_INTERVAL: float = 20.0
const DELIVERY_TIME: float = 240.0  # Delivery arrives mid-shift

# --- Customer templates ---
var _customer_templates: Array[Dictionary] = [
	{
		"type": "traveler",
		"names": ["Dave Mitchell", "Karen Webb", "Tony Briggs", "Lisa Huang", "Marcus Cole", "Jenny Park", "Omar Davis"],
		"items": [["coffee_large", "chips"], ["gas"], ["coffee_small", "hot_dog"], ["water", "map"], ["slushie", "nachos"], ["energy_drink", "beef_jerky"], ["gas", "donut", "coffee_large"]],
		"dialogue": [
			"Long drive. Just need some coffee.",
			"Fill up pump 2, please.",
			"How far is the next town?",
			"Is that storm coming this way?",
			"Do you have nachos? I could really go for nachos.",
			"What flavors of slushie you got?",
			"I'll take whatever's on the grill.",
		],
	},
	{
		"type": "trucker",
		"names": ["Big Jim", "Red", "Dolores", "Hank Weaver", "Sal Gutierrez"],
		"items": [["coffee_large", "sandwich", "energy_drink"], ["gas", "cigarettes"], ["corn_dog", "coffee_large", "chips"], ["hot_dog", "hot_dog", "soda"], ["frozen_burrito", "energy_drink"]],
		"dialogue": [
			"Usual. Large coffee, sandwich.",
			"Need to fill up the rig.",
			"Radio's been weird tonight. You hearing it too?",
			"Something on the road back there. Couldn't tell what.",
			"Two hot dogs and a soda. Been driving since noon.",
			"Got any of those frozen burritos? They hit different at 3 AM.",
		],
	},
	{
		"type": "motel_guest",
		"names": ["Mr. Reeves", "The Calhouns", "Sandra Bell", "J. Whitmore", "Erin Park"],
		"items": [],
		"dialogue": [
			"Do you have a room for the night?",
			"We need to stop. My kids are exhausted.",
			"Just one night. Earliest checkout possible.",
			"Is room 4 available? I stayed there before.",
		],
		"wants_room": true,
	},
	{
		"type": "local",
		"names": ["Deputy Hale", "Mrs. Pacheco", "Zeke", "Ranger Owens", "Coach Burke"],
		"items": [["coffee_small"], ["cigarettes", "lighter"], ["soda", "candy_bar"], ["pizza_slice", "soda"], ["trail_mix", "water"], ["gum", "sunflower_seeds"]],
		"dialogue": [
			"Quiet night?",
			"Seen anything odd out here?",
			"How long you been working nights?",
			"You know the history of this place, right?",
			"Just grabbing a slice. Pizza still warm?",
			"The usual trail mix and water. Long patrol ahead.",
		],
	},
	{
		"type": "late_night",
		"names": ["College Kid", "The Jogger", "Night Owl", "Insomnia Guy"],
		"items": [["energy_drink", "energy_drink", "gum"], ["water", "trail_mix"], ["coffee_large", "donut", "donut"], ["instant_noodles", "soda"]],
		"dialogue": [
			"Dude, do you have like, three energy drinks?",
			"Just finished my run. Water, please.",
			"Can't sleep. Might as well have coffee and donuts.",
			"Is your microwave working? I need to heat these noodles.",
		],
	},
]


func _process(delta: float) -> void:
	if not is_shift_active:
		return
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	_update_customer_spawns(delta)
	_update_delivery(delta)


## Begin a new shift.
func start_shift() -> void:
	is_shift_active = true
	shift_events_triggered = 0
	customer_spawn_timer = 30.0  # Grace period
	delivery_timer = DELIVERY_TIME

	# Generate objectives for this shift
	ObjectiveManager.generate_shift_objectives(GameManager.current_shift)
	EventDirector.reset_for_shift()

	GameManager.begin_shift()
	shift_phase_changed.emit("pre_shift")


## End the current shift.
func end_shift() -> void:
	is_shift_active = false
	GameManager.end_shift()

	var summary := _generate_shift_summary()
	shift_summary_ready.emit(summary)


## Generate a random customer.
func spawn_customer() -> Dictionary:
	var template: Dictionary = _customer_templates[randi() % _customer_templates.size()]
	var names: Array = template["names"]
	var items_options: Array = template["items"]

	var customer := {
		"id": "customer_%d_%d" % [GameManager.current_shift, randi()],
		"name": names[randi() % names.size()],
		"type": template["type"],
		"items": [],
		"dialogue": "",
		"wants_room": template.get("wants_room", false),
		"arrived_at": GameManager.in_game_hour * 100 + GameManager.in_game_minute,
	}

	if items_options.size() > 0:
		customer["items"] = items_options[randi() % items_options.size()]

	var dialogues: Array = template["dialogue"]
	customer["dialogue"] = dialogues[randi() % dialogues.size()]

	customer_spawned.emit(customer)
	return customer


## Create a horror-variant customer (anomaly).
func spawn_anomaly_customer() -> Dictionary:
	var anomaly_names := ["Someone", "The Passenger", "A Woman", "Room 4 Guest", "The Driver"]
	var anomaly_dialogues := [
		"I've been here before. Don't you remember me?",
		"I need room 4. Specifically room 4.",
		"My car broke down at mile 87. Can I use the phone?",
		"What time is it? What year is it?",
		"Don't trust the radio tonight.",
		"The storm isn't real. Don't go outside.",
		"I left something in the lost and found. Years ago.",
	]

	var customer := {
		"id": "anomaly_%d_%d" % [GameManager.current_shift, randi()],
		"name": anomaly_names[randi() % anomaly_names.size()],
		"type": "anomaly",
		"items": [],
		"dialogue": anomaly_dialogues[randi() % anomaly_dialogues.size()],
		"wants_room": randf() > 0.5,
		"is_anomaly": true,
		"arrived_at": GameManager.in_game_hour * 100 + GameManager.in_game_minute,
	}

	customer_spawned.emit(customer)
	return customer


# --- Private ---

func _update_customer_spawns(delta: float) -> void:
	customer_spawn_timer -= delta
	if customer_spawn_timer <= 0.0:
		# Determine if this is a normal or anomaly customer
		var anomaly_chance := EventDirector.horror_intensity * 0.2
		if randf() < anomaly_chance and GameManager.current_shift >= 2:
			spawn_anomaly_customer()
		else:
			spawn_customer()

		# Calculate next spawn interval
		var interval := BASE_CUSTOMER_INTERVAL
		# More customers during early night, fewer at 3-4 AM
		match GameManager.current_shift_phase:
			GameManager.ShiftPhase.EARLY_NIGHT:
				interval *= 0.8
			GameManager.ShiftPhase.MID_NIGHT:
				interval *= 1.2
			GameManager.ShiftPhase.LATE_NIGHT:
				interval *= 1.5
			GameManager.ShiftPhase.DAWN:
				interval *= 0.9

		customer_spawn_timer = maxf(interval + randf_range(-10, 10), MIN_CUSTOMER_INTERVAL)


func _update_delivery(delta: float) -> void:
	if delivery_timer > 0:
		delivery_timer -= delta
		if delivery_timer <= 0:
			var delivery := {
				"type": "supply",
				"items": ["coffee_beans", "hot_dog_pack", "chip_box", "soda_case"],
				"invoice_amount": 35.0,
			}
			delivery_arrived.emit(delivery)
			# Add objective to process delivery
			ObjectiveManager.add_objective({
				"id": "process_delivery",
				"title": "Process Delivery",
				"description": "Sign for the delivery and restock from the boxes",
				"type": "task",
				"reward_cash": 5.0,
				"reward_reputation": 3.0,
				"time_limit": 120.0,
			})


func _generate_shift_summary() -> Dictionary:
	return {
		"shift_number": GameManager.current_shift,
		"customers_served": GameManager.shift_customers_served,
		"revenue": GameManager.shift_revenue,
		"expenses": GameManager.shift_expenses,
		"profit": GameManager.shift_revenue - GameManager.shift_expenses,
		"incidents": GameManager.shift_incidents.size(),
		"objectives_completed": ObjectiveManager.completed_objectives.size(),
		"objectives_failed": ObjectiveManager.failed_objectives.size(),
		"horror_events": EventDirector.events_this_shift.size(),
		"fatigue_end": GameManager.fatigue,
		"stress_end": GameManager.stress,
		"composure_end": GameManager.composure,
		"reputation": GameManager.reputation,
	}
