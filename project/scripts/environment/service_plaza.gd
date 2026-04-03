## ServicePlaza - Main game level containing the entire Exit 13 service plaza.
## Manages all sub-areas, spawns, systems, and the shift loop.
extends Node3D

# --- Node References ---
@onready var player: PlayerController = $Player
@onready var hud: HUD = $HUD
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
	_enhance_environment_details()
	_apply_runtime_graphics_settings()

	# Set HUD player reference (deferred to ensure HUD's @onready nodes are ready)
	hud.call_deferred("set_player", player)

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
	cctv_system.add_to_group("cctv_system")
	power_grid.add_to_group("power_grid")
	_register_scene_light_groups()


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
	SettingsManager.settings_changed.connect(_on_settings_changed)

	# Power grid
	power_grid.zone_power_changed.connect(_on_zone_power_changed)
	power_grid.blackout_started.connect(_on_blackout_started)


func _collect_light_references() -> void:
	shop_lights.clear()
	exterior_lights.clear()
	motel_lights.clear()
	forecourt_lights.clear()

	# Collect all lights tagged by group
	for light in get_tree().get_nodes_in_group("shop_lights"):
		if light is Light3D:
			_remember_light_energy(light)
			shop_lights.append(light)
	for light in get_tree().get_nodes_in_group("exterior_lights"):
		if light is Light3D:
			_remember_light_energy(light)
			exterior_lights.append(light)
	for light in get_tree().get_nodes_in_group("motel_lights"):
		if light is Light3D:
			_remember_light_energy(light)
			motel_lights.append(light)
	for light in get_tree().get_nodes_in_group("forecourt_lights"):
		if light is Light3D:
			_remember_light_energy(light)
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


func _on_event_completed(_event_id: String) -> void:
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


func _on_delivery_arrived(_delivery_data: Dictionary) -> void:
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
	if not blackout_event.is_active():
		blackout_event.trigger(power_grid)


func _on_weather_changed(_weather: int) -> void:
	_update_environment_for_weather()


func _on_settings_changed(category: String) -> void:
	if category == "graphics":
		_apply_runtime_graphics_settings()


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
		var register := registers[0] as CashRegister
		if register == null:
			return
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
	var group_names := [zone_name + "_lights"]
	match zone_name:
		"fuel_forecourt":
			group_names.append("forecourt_lights")
		"motel_lobby":
			group_names.append("motel_lights")
		"motel_rooms":
			group_names.append("motel_room_lights")
		"exterior_signs":
			group_names.append("sign_lights")

	for group_name in group_names:
		for light in get_tree().get_nodes_in_group(group_name):
			if light is Light3D:
				light.visible = is_powered


func _update_environment_for_weather() -> void:
	# Adjust lighting based on weather
	var weather := WeatherManager.current_weather
	var env := get_node_or_null("Environment/WorldEnvironment")
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
			var base_energy := float(light.get_meta("base_light_energy", light.light_energy))
			light.light_energy = base_energy * exterior_dim


func _get_all_lights() -> Array[Light3D]:
	var lights: Array[Light3D] = []
	_find_lights(self, lights)
	return lights


func _find_lights(node: Node, result: Array[Light3D]) -> void:
	if node is Light3D:
		result.append(node)
	for child in node.get_children():
		_find_lights(child, result)


func _register_scene_light_groups() -> void:
	_register_light(get_node_or_null("Environment/ShopBuilding/ShopLight1"), ["shop_lights"])
	_register_light(get_node_or_null("Environment/ShopBuilding/ShopLight2"), ["shop_lights"])
	_register_light(get_node_or_null("Environment/ShopBuilding/ShopLight3"), ["shop_lights"])
	_register_light(get_node_or_null("Environment/MotelBuilding/MotelLight"), ["motel_lights", "motel_lobby_lights"])
	_register_light(get_node_or_null("Environment/FuelForecourt/CanopyLight"), ["forecourt_lights", "fuel_forecourt_lights", "exterior_lights"])
	_register_light(get_node_or_null("Environment/ParkingLot/ParkingLight"), ["parking_lot_lights", "exterior_lights"])
	_register_light(get_node_or_null("Environment/ExteriorSign/SignLight"), ["sign_lights", "exterior_signs_lights", "exterior_lights"])


func _register_light(node: Node, groups: Array[String]) -> void:
	if node == null:
		return
	if not (node is Light3D):
		return
	var light := node as Light3D
	for group_name in groups:
		if not light.is_in_group(group_name):
			light.add_to_group(group_name)
	_remember_light_energy(light)


func _remember_light_energy(light: Light3D) -> void:
	if not light.has_meta("base_light_energy"):
		light.set_meta("base_light_energy", light.light_energy)


func _enhance_environment_details() -> void:
	var environment := get_node_or_null("Environment")
	if environment == null:
		return

	_apply_environment_materials()
	_add_storefront_details(environment)
	_add_motel_details(environment)
	_add_forecourt_details(environment)
	_add_parking_details(environment)
	_add_sign_details(environment)


func _apply_environment_materials() -> void:
	_apply_mesh_material("Environment/ShopBuilding/Counter/CounterMesh", _make_detail_material(Color(0.32, 0.26, 0.2), 0.55, 0.18))
	_apply_mesh_material("Environment/PhantomCar/CarBody", _make_detail_material(Color(0.12, 0.12, 0.16), 0.28, 0.7))


func _apply_mesh_material(node_path: String, material: StandardMaterial3D) -> void:
	var mesh := get_node_or_null(node_path)
	if mesh is MeshInstance3D:
		(mesh as MeshInstance3D).material_override = material


func _add_storefront_details(_environment: Node) -> void:
	var shop := get_node_or_null("Environment/ShopBuilding")
	if not (shop is Node3D):
		return
	var shop_node := shop as Node3D

	# Split storefront glass details to match door opening (gap for entrance)
	_create_detail_box(shop_node, "StorefrontGlassLeft", Vector3(2.0, 2.2, 0.05), Vector3(-1.9, 1.5, 5.88),
		_make_glass_material(Color(0.6, 0.72, 0.8, 0.22)), "high")
	_create_detail_box(shop_node, "StorefrontGlassRight", Vector3(2.0, 2.2, 0.05), Vector3(1.9, 1.5, 5.88),
		_make_glass_material(Color(0.6, 0.72, 0.8, 0.22)), "high")
	_create_detail_box(shop_node, "EntranceMat", Vector3(2.2, 0.03, 1.2), Vector3(0, 0.03, 5.0),
		_make_detail_material(Color(0.09, 0.09, 0.09), 0.98, 0.02))
	_create_detail_box(shop_node, "Awning", Vector3(7.5, 0.18, 1.6), Vector3(0, 3.3, 6.6),
		_make_detail_material(Color(0.14, 0.12, 0.13), 0.72, 0.15))
	_create_detail_box(shop_node, "AwningTrim", Vector3(7.3, 0.08, 0.08), Vector3(0, 3.15, 7.35),
		_make_detail_material(Color(0.8, 0.2, 0.16), 0.45, 0.35, Color(0.9, 0.2, 0.15), 0.7))

	for i in range(3):
		var rack_x := -2.8 + i * 2.4
		_create_detail_box(shop_node, "Aisle_%d" % i, Vector3(1.2, 1.4, 0.45), Vector3(rack_x, 0.7, 0.2),
			_make_detail_material(Color(0.35, 0.35, 0.36), 0.42, 0.65))
		for j in range(3):
			_create_detail_box(shop_node, "Product_%d_%d" % [i, j], Vector3(0.16, 0.22, 0.12),
				Vector3(rack_x - 0.28 + j * 0.28, 1.1, 0.12),
				_make_detail_material(Color(0.35 + 0.15 * j, 0.18 + 0.1 * i, 0.2 + 0.12 * j), 0.64, 0.08), "high")

	_create_detail_box(shop_node, "CoolerBank", Vector3(6.0, 2.2, 0.5), Vector3(0, 1.1, -5.5),
		_make_detail_material(Color(0.45, 0.47, 0.5), 0.36, 0.55))
	_create_detail_box(shop_node, "CoolerGlass", Vector3(5.8, 1.9, 0.04), Vector3(0, 1.1, -5.2),
		_make_glass_material(Color(0.68, 0.76, 0.82, 0.18)), "high")


func _add_motel_details(_environment: Node) -> void:
	var motel := get_node_or_null("Environment/MotelBuilding")
	if not (motel is Node3D):
		return
	var motel_node := motel as Node3D

	_create_detail_box(motel_node, "MotelDesk", Vector3(2.4, 1.0, 0.7), Vector3(-1.8, 0.5, 1.5),
		_make_detail_material(Color(0.28, 0.22, 0.18), 0.7, 0.1))
	_create_detail_box(motel_node, "MotelLampShade", Vector3(0.4, 0.35, 0.4), Vector3(-1.8, 1.5, 1.3),
		_make_detail_material(Color(0.82, 0.72, 0.5), 0.85, 0.02, Color(1.0, 0.8, 0.45), 1.3), "high")
	_create_detail_box(motel_node, "HallRunner", Vector3(1.4, 0.02, 7.0), Vector3(0, 0.02, 0),
		_make_detail_material(Color(0.26, 0.08, 0.06), 0.95, 0.02))


func _add_forecourt_details(_environment: Node) -> void:
	var forecourt := get_node_or_null("Environment/FuelForecourt")
	if not (forecourt is Node3D):
		return
	var forecourt_node := forecourt as Node3D

	_create_detail_box(forecourt_node, "CanopyRoof", Vector3(9.0, 0.22, 5.5), Vector3(0, 4.4, 0),
		_make_detail_material(Color(0.2, 0.2, 0.22), 0.55, 0.45))
	for x in [-2.8, 2.8]:
		for z in [-1.4, 1.4]:
			_create_detail_box(forecourt_node, "CanopyColumn_%s_%s" % [str(x), str(z)], Vector3(0.22, 4.2, 0.22), Vector3(x, 2.1, z),
				_make_detail_material(Color(0.62, 0.62, 0.62), 0.42, 0.62))

	for pump_index in range(2):
		var pump_z := -0.9 + pump_index * 1.8
		_create_detail_box(forecourt_node, "PumpBody_%d" % pump_index, Vector3(1.0, 1.6, 0.7), Vector3(0, 0.8, pump_z),
			_make_detail_material(Color(0.74, 0.74, 0.72), 0.34, 0.52))
		_create_detail_box(forecourt_node, "PumpScreen_%d" % pump_index, Vector3(0.35, 0.24, 0.03), Vector3(0, 1.2, pump_z + 0.36),
			_make_detail_material(Color(0.08, 0.18, 0.12), 0.24, 0.28, Color(0.1, 0.5, 0.35), 0.5))

	_create_detail_box(forecourt_node, "OilSpill", Vector3(2.3, 0.01, 1.3), Vector3(0.8, 0.01, 1.9),
		_make_detail_material(Color(0.05, 0.05, 0.06), 0.98, 0.01))


func _add_parking_details(_environment: Node) -> void:
	var parking := get_node_or_null("Environment/ParkingLot")
	if not (parking is Node3D):
		return
	var parking_node := parking as Node3D

	for i in range(4):
		_create_detail_box(parking_node, "ParkingStripe_%d" % i, Vector3(0.18, 0.01, 3.2), Vector3(-4.5 + i * 3.0, 0.02, 1.0),
			_make_detail_material(Color(0.78, 0.78, 0.72), 0.88, 0.02))
		_create_detail_box(parking_node, "WheelStop_%d" % i, Vector3(1.2, 0.16, 0.35), Vector3(-4.5 + i * 3.0, 0.08, -1.0),
			_make_detail_material(Color(0.55, 0.55, 0.53), 0.9, 0.04))

	_create_detail_box(parking_node, "TrashClusterA", Vector3(0.32, 0.42, 0.28), Vector3(4.6, 0.2, 1.8),
		_make_detail_material(Color(0.07, 0.07, 0.07), 0.96, 0.0))
	_create_detail_box(parking_node, "TrashClusterB", Vector3(0.28, 0.36, 0.24), Vector3(5.0, 0.18, 1.45),
		_make_detail_material(Color(0.1, 0.09, 0.08), 0.96, 0.0))


func _add_sign_details(_environment: Node) -> void:
	var sign := get_node_or_null("Environment/ExteriorSign")
	if not (sign is Node3D):
		return
	var sign_node := sign as Node3D
	_create_detail_box(sign_node, "SignBoard", Vector3(4.6, 2.6, 0.18), Vector3(0, 0.8, 0),
		_make_detail_material(Color(0.12, 0.05, 0.03), 0.62, 0.16))
	_create_detail_box(sign_node, "SignFace", Vector3(4.1, 2.1, 0.04), Vector3(0, 0.8, 0.12),
		_make_detail_material(Color(0.7, 0.16, 0.12), 0.32, 0.2, Color(1.0, 0.28, 0.18), 2.5))
	_create_detail_box(sign_node, "SignPost", Vector3(0.35, 6.5, 0.35), Vector3(0, -1.25, 0),
		_make_detail_material(Color(0.42, 0.42, 0.44), 0.4, 0.7))

	# Sign glow light — simulates light spill from the neon sign
	var sign_glow := OmniLight3D.new()
	sign_glow.name = "SignGlow"
	sign_glow.position = Vector3(0, 0.8, 0.5)
	sign_glow.light_color = Color(1.0, 0.4, 0.2)
	sign_glow.light_energy = 3.5
	sign_glow.omni_range = 12.0
	sign_glow.omni_attenuation = 1.4
	sign_glow.shadow_enabled = false
	sign_glow.add_to_group("detail_high")
	sign_node.add_child(sign_glow)


func _create_detail_box(parent: Node3D, node_name: String, size: Vector3, position: Vector3, material: StandardMaterial3D, detail_tier: String = "medium") -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = position
	mesh.material_override = material
	mesh.add_to_group("detail_%s" % detail_tier)
	parent.add_child(mesh)
	return mesh


func _make_detail_material(color: Color, roughness: float, metallic: float, emission: Color = Color(0, 0, 0, 1), emission_energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = emission_energy
	return material


func _make_glass_material(color: Color) -> StandardMaterial3D:
	var material := _make_detail_material(color, 0.02, 0.9)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.specular = 1.0
	material.refraction_enabled = true
	material.refraction_scale = 0.02
	return material


func _apply_runtime_graphics_settings() -> void:
	var world_env := get_node_or_null("Environment/WorldEnvironment")
	if world_env is WorldEnvironment and (world_env as WorldEnvironment).environment != null:
		var env := (world_env as WorldEnvironment).environment
		env.ssao_enabled = SettingsManager.ssao_enabled
		env.ssil_enabled = SettingsManager.ssil_enabled
		env.glow_enabled = SettingsManager.glow_enabled
		env.fog_enabled = SettingsManager.volumetric_fog
		env.volumetric_fog_enabled = SettingsManager.volumetric_fog
		env.tonemap_exposure = clampf(SettingsManager.brightness, 0.5, 2.0)

	var show_high_detail := SettingsManager.graphics_preset >= 2
	for node in get_tree().get_nodes_in_group("detail_high"):
		if node is CanvasItem:
			(node as CanvasItem).visible = show_high_detail
		elif node is Node3D:
			(node as Node3D).visible = show_high_detail
