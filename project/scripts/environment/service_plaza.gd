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

# New horror events
var cctv_doppelganger_event: HorrorEventCCTVDoppelganger
var room4_event: HorrorEventRoom4
var radio_voice_event: HorrorEventRadioVoice
var lost_found_event: HorrorEventLostAndFound
var mass_arrival_event: HorrorEventMassArrival

# New systems
var environment_builder: EnvironmentBuilder
var spatial_audio: SpatialAudioManager
var footstep_system: FootstepSystem
var optimization: OptimizationManager
var endless_mode: EndlessMode
var streamer_mode: StreamerMode

# Environment references
var shop_lights: Array[Light3D] = []
var exterior_lights: Array[Light3D] = []
var motel_lights: Array[Light3D] = []
var forecourt_lights: Array[Light3D] = []


func _ready() -> void:
	_build_environment()
	_create_new_systems()
	_setup_systems()
	_connect_signals()
	_collect_light_references()

	# Set HUD player reference
	hud.set_player(player)

	# Setup new systems with player reference
	spatial_audio.setup(player)
	footstep_system.setup(player)
	optimization.setup(player)

	# Start the shift
	shift_manager.start_shift()


## Build the detailed 3D environment using the EnvironmentBuilder.
func _build_environment() -> void:
	environment_builder = EnvironmentBuilder.new()
	environment_builder.name = "EnvironmentBuilder"
	add_child(environment_builder)


## Create and add new system nodes.
func _create_new_systems() -> void:
	# Horror events
	cctv_doppelganger_event = HorrorEventCCTVDoppelganger.new()
	cctv_doppelganger_event.name = "CCTVDoppelgangerEvent"
	$Events.add_child(cctv_doppelganger_event)

	room4_event = HorrorEventRoom4.new()
	room4_event.name = "Room4Event"
	$Events.add_child(room4_event)

	radio_voice_event = HorrorEventRadioVoice.new()
	radio_voice_event.name = "RadioVoiceEvent"
	$Events.add_child(radio_voice_event)

	lost_found_event = HorrorEventLostAndFound.new()
	lost_found_event.name = "LostFoundEvent"
	$Events.add_child(lost_found_event)

	mass_arrival_event = HorrorEventMassArrival.new()
	mass_arrival_event.name = "MassArrivalEvent"
	$Events.add_child(mass_arrival_event)

	# Systems
	spatial_audio = SpatialAudioManager.new()
	spatial_audio.name = "SpatialAudio"
	add_child(spatial_audio)

	footstep_system = FootstepSystem.new()
	footstep_system.name = "FootstepSystem"
	add_child(footstep_system)

	optimization = OptimizationManager.new()
	optimization.name = "OptimizationManager"
	add_child(optimization)

	endless_mode = EndlessMode.new()
	endless_mode.name = "EndlessMode"
	$Systems.add_child(endless_mode)

	streamer_mode = StreamerMode.new()
	streamer_mode.name = "StreamerMode"
	$Systems.add_child(streamer_mode)


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
	for light in get_tree().get_nodes_in_group("motel_lights"):
		if light is Light3D:
			motel_lights.append(light)
	for light in get_tree().get_nodes_in_group("forecourt_lights"):
		if light is Light3D:
			forecourt_lights.append(light)


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
			cctv_doppelganger_event.trigger()
		"room4_opens":
			room4_event.trigger()
		"radio_voices", "radio_full_broadcast", "child_radio_voice":
			radio_voice_event.trigger()
		"lost_found_pileup":
			lost_found_event.trigger()
		"mass_arrival":
			mass_arrival_event.trigger()
		"phantom_footsteps":
			_play_phantom_footsteps()
		"cold_spot":
			_trigger_cold_spot()
		"false_emergency_call":
			_trigger_false_call()
		"distant_headlights":
			_trigger_distant_headlights()
		"key_rearrangement":
			_trigger_key_rearrangement()
		"vending_personal_items":
			_trigger_vending_anomaly()
		"storm_warning_past":
			_trigger_storm_warning_past()
		"locked_stall":
			_trigger_locked_stall()
		"guest_wrong_room":
			_trigger_wrong_room()
		"repeat_customer":
			_trigger_repeat_customer()


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


func _trigger_key_rearrangement() -> void:
	DialogueManager.show_subtitle("", "[The motel key tags on the board have rearranged themselves. Room 4's hook now has a key.]")
	GameManager.stress += 12.0
	GameManager.composure -= 5.0
	GameManager.set_story_flag("keys_moved")


func _trigger_vending_anomaly() -> void:
	var items: Array[String] = ["a hospital bracelet", "a car key with dried mud", "a child's drawing of a highway", "a gas station receipt dated years ago"]
	var item: String = items[randi() % items.size()]
	DialogueManager.show_subtitle("", "[The vending machine dispenses %s instead of a snack]" % item)
	GameManager.stress += 10.0
	GameManager.composure -= 8.0


func _trigger_storm_warning_past() -> void:
	DialogueManager.show_subtitle("Radio", "Storm warning for Highway 13 corridor. Multi-vehicle pileup reported at Mile 87. Emergency services en route.")
	var timer := get_tree().create_timer(4.0)
	timer.timeout.connect(func():
		DialogueManager.show_subtitle("Mara", "That warning... it's describing weather that already happened. Three years ago.")
		GameManager.stress += 8.0
	)


func _trigger_locked_stall() -> void:
	DialogueManager.show_subtitle("", "[The third bathroom stall is locked from the inside. No one is in there.]")
	GameManager.stress += 6.0
	var timer := get_tree().create_timer(5.0)
	timer.timeout.connect(func():
		DialogueManager.show_subtitle("", "[A faucet turns on by itself, then stops.]")
		GameManager.stress += 4.0
	)


func _trigger_wrong_room() -> void:
	var room := randi_range(1, 6)
	DialogueManager.show_subtitle("Guest", "Excuse me, I think I'm in the wrong room. This isn't what Room %d looked like last time." % room)
	GameManager.stress += 5.0


func _trigger_repeat_customer() -> void:
	DialogueManager.show_subtitle("", "[A customer approaches the counter. They look exactly like someone who left an hour ago.]")
	DialogueManager.show_subtitle("Customer", "Twenty on pump two and a coffee. ...Didn't I just say that?")
	GameManager.stress += 8.0
	GameManager.composure -= 3.0


func _update_zone_lights(zone_name: String, is_powered: bool) -> void:
	# Toggle lights by zone group
	var group_name := zone_name + "_lights"
	for light in get_tree().get_nodes_in_group(group_name):
		if light is Light3D:
			light.visible = is_powered


func _update_environment_for_weather() -> void:
	# Adjust lighting based on weather
	var weather := WeatherManager.current_weather
	var env := get_node_or_null("WorldEnvironment")
	if env == null:
		return

	# Dim exterior lights during storms
	var exterior_dim := 1.0
	match weather:
		WeatherManager.WeatherType.FOG:
			exterior_dim = 0.6
		WeatherManager.WeatherType.HEAVY_RAIN:
			exterior_dim = 0.7
		WeatherManager.WeatherType.STORM:
			exterior_dim = 0.5
		WeatherManager.WeatherType.DUST:
			exterior_dim = 0.8

	for light in exterior_lights:
		if is_instance_valid(light):
			light.light_energy = light.light_energy * exterior_dim


func _get_all_lights() -> Array[Light3D]:
	var lights: Array[Light3D] = []
	_find_lights(self, lights)
	return lights


func _find_lights(node: Node, result: Array[Light3D]) -> void:
	if node is Light3D:
		result.append(node)
	for child in node.get_children():
		_find_lights(child, result)
