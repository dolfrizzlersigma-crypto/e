## ServicePlaza - Main game level containing the entire Exit 13 service plaza.
## Manages all sub-areas, spawns, systems, and the shift loop.
extends Node3D

# --- Node References ---
@onready var player: CharacterBody3D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var shift_manager: ShiftManager = $Systems/ShiftManager
@onready var motel_system: MotelSystem = $Systems/MotelSystem
@onready var power_grid: PowerGrid = $Systems/PowerGrid
@onready var cctv_system: CCTVSystem = $Systems/CCTVSystem

# Horror events
@onready var flicker_event: HorrorEventFlickeringLights = $Events/FlickerEvent
@onready var phantom_car_event: HorrorEventPhantomCar = $Events/PhantomCarEvent
@onready var receipt_event: HorrorEventReceiptPrediction = $Events/ReceiptEvent
@onready var blackout_event: HorrorEventProgressiveBlackout = $Events/BlackoutEvent

# Environment references
var shop_lights: Array[Light3D] = []
var exterior_lights: Array[Light3D] = []


func _ready() -> void:
	_setup_systems()
	_connect_signals()
	_collect_light_references()

	# Set HUD player reference
	hud.set_player(player)

	# Start the shift
	shift_manager.start_shift()


func _setup_systems() -> void:
	shift_manager.add_to_group("shift_manager")
	cctv_system.add_to_group("cctv")


func _connect_signals() -> void:
	# Event director triggers
	EventDirector.event_triggered.connect(_on_event_triggered)
	EventDirector.event_completed.connect(_on_event_completed)

	# Shift manager
	shift_manager.customer_spawned.connect(_on_customer_spawned)
	shift_manager.delivery_arrived.connect(_on_delivery_arrived)
	shift_manager.shift_summary_ready.connect(_on_shift_summary)

	# Weather effects
	WeatherManager.blackout_triggered.connect(_on_weather_blackout)
	WeatherManager.weather_changed.connect(_on_weather_changed)

	# Power grid
	power_grid.zone_power_changed.connect(_on_zone_power_changed)
	power_grid.blackout_started.connect(_on_blackout_started)


func _collect_light_references() -> void:
	# Collect all lights tagged by group
	for light in get_tree().get_nodes_in_group("shop_lights"):
		if light is Light3D:
			shop_lights.append(light)
	for light in get_tree().get_nodes_in_group("exterior_lights"):
		if light is Light3D:
			exterior_lights.append(light)


# --- Event Handlers ---

func _on_event_triggered(event_data: Dictionary) -> void:
	var event_id: String = event_data.get("id", "")
	match event_id:
		"flickering_lights":
			var lights := shop_lights if shop_lights.size() > 0 else _get_all_lights()
			flicker_event.trigger(lights)
		"cctv_phantom_car":
			var phantom_car := get_node_or_null("Environment/PhantomCar")
			if phantom_car:
				phantom_car_event.trigger(phantom_car, player)
		"receipt_prediction":
			receipt_event.trigger()
		"zone_blackout":
			blackout_event.trigger(power_grid)
		"cctv_doppelganger":
			cctv_system.trigger_doppelganger_event()
		"phantom_footsteps":
			_play_phantom_footsteps()
		"cold_spot":
			_trigger_cold_spot()
		"false_emergency_call":
			_trigger_false_call()
		"distant_headlights":
			_trigger_distant_headlights()


func _on_event_completed(event_id: String) -> void:
	# Post-event cleanup or story progression
	pass


func _on_customer_spawned(customer_data: Dictionary) -> void:
	# In a full implementation, this would instantiate an NPC scene
	# For the vertical slice, we handle it through dialogue
	var name_str: String = customer_data.get("name", "Customer")
	var dialogue: String = customer_data.get("dialogue", "...")

	if customer_data.get("is_anomaly", false):
		GameManager.stress += 5.0

	DialogueManager.show_subtitle(name_str, dialogue)

	# Auto-process simple purchases for now
	if customer_data.get("items", []).size() > 0:
		_auto_process_customer(customer_data)
	elif customer_data.get("wants_room", false):
		_handle_room_request(customer_data)


func _on_delivery_arrived(delivery_data: Dictionary) -> void:
	DialogueManager.show_subtitle("", "[A delivery truck pulls up outside]")


func _on_shift_summary(summary: Dictionary) -> void:
	# Display shift summary
	var summary_text := "Shift %d Complete\n" % summary["shift_number"]
	summary_text += "Customers: %d\n" % summary["customers_served"]
	summary_text += "Revenue: $%.2f\n" % summary["revenue"]
	summary_text += "Incidents: %d\n" % summary["incidents"]
	DialogueManager.show_subtitle("SHIFT REPORT", summary_text)

	# Auto-save
	SaveManager.save_game(SaveManager.AUTOSAVE_SLOT)

	# Return to menu or start next shift
	get_tree().create_timer(8.0).timeout.connect(func():
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)


func _on_weather_blackout() -> void:
	if not blackout_event._is_active:
		blackout_event.trigger(power_grid)


func _on_weather_changed(_weather: int) -> void:
	_update_environment_for_weather()


func _on_zone_power_changed(zone_name: String, is_powered: bool) -> void:
	# Update lights in the zone
	_update_zone_lights(zone_name, is_powered)


func _on_blackout_started() -> void:
	GameManager.stress += 10.0
	DialogueManager.show_subtitle("", "[All lights go out]")


# --- Helper Methods ---

func _auto_process_customer(customer_data: Dictionary) -> void:
	# Find the register and process items
	var registers := get_tree().get_nodes_in_group("register")
	if registers.size() > 0:
		var register: CashRegister = registers[0]
		register.start_transaction(customer_data)
		for item_id in customer_data.get("items", []):
			if item_id == "gas":
				register.authorize_pump(randi_range(1, 4), randf_range(20.0, 60.0))
			else:
				register.scan_item(item_id)
		var total := register.get_current_total()
		register.complete_transaction(total + randf_range(0, 5.0))


func _handle_room_request(customer_data: Dictionary) -> void:
	var room := motel_system.check_in_guest(customer_data)
	if room > 0:
		DialogueManager.show_subtitle("Mara", "Room %d. Here's your key." % room)
	else:
		DialogueManager.show_subtitle("Mara", "Sorry, no rooms available tonight.")


func _play_phantom_footsteps() -> void:
	DialogueManager.show_subtitle("", "[Footsteps echo from the empty hallway]")
	GameManager.stress += 8.0


func _trigger_cold_spot() -> void:
	DialogueManager.show_subtitle("Mara", "...it just got really cold in here.")
	GameManager.stress += 3.0


func _trigger_false_call() -> void:
	DialogueManager.show_subtitle("Radio", "...dispatch, we have a vehicle at mile 87... requesting assistance...")
	GameManager.stress += 7.0
	GameManager.collect_evidence("false_call_shift_%d" % GameManager.current_shift)


func _trigger_distant_headlights() -> void:
	DialogueManager.show_subtitle("", "[Headlights appear on the highway... but they never get closer]")
	GameManager.stress += 4.0


func _get_all_lights() -> Array[Light3D]:
	var lights: Array[Light3D] = []
	_find_lights(self, lights)
	return lights


func _find_lights(node: Node, result: Array[Light3D]) -> void:
	if node is Light3D:
		result.append(node)
	for child in node.get_children():
		_find_lights(child, result)


func _update_zone_lights(_zone_name: String, _is_powered: bool) -> void:
	# In full implementation, toggle lights per zone
	pass


func _update_environment_for_weather() -> void:
	# In full implementation, adjust environmental effects
	pass
