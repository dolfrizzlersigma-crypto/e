## EnvironmentBuilder - Procedural construction of the Exit 13 service plaza.
## Builds detailed CSG geometry with materials for all areas.
## Used by the main level scene to create the environment at runtime.
class_name EnvironmentBuilder
extends Node3D

## Material palette for consistent look across the plaza.
var mat_asphalt: StandardMaterial3D
var mat_concrete: StandardMaterial3D
var mat_linoleum: StandardMaterial3D
var mat_drywall: StandardMaterial3D
var mat_ceiling_tile: StandardMaterial3D
var mat_metal: StandardMaterial3D
var mat_wood: StandardMaterial3D
var mat_glass: StandardMaterial3D
var mat_brick: StandardMaterial3D
var mat_tile_white: StandardMaterial3D
var mat_tile_blue: StandardMaterial3D
var mat_carpet: StandardMaterial3D
var mat_motel_door: StandardMaterial3D
var mat_counter_top: StandardMaterial3D
var mat_shelf_metal: StandardMaterial3D
var mat_exterior_sign: StandardMaterial3D
var mat_pump_body: StandardMaterial3D
var mat_dirt: StandardMaterial3D
var mat_rust: StandardMaterial3D


func _ready() -> void:
	_create_materials()
	_build_ground_and_parking()
	_build_shop_building()
	_build_motel_building()
	_build_fuel_forecourt()
	_build_parking_lot()
	_build_dumpster_alley()
	_build_maintenance_shed()
	_build_basement_entrance()
	_build_exterior_sign()
	_build_road_and_highway()
	_build_props_and_details()


# =============================================================================
# MATERIAL CREATION
# =============================================================================

func _create_materials() -> void:
	mat_asphalt = _make_material(Color(0.08, 0.08, 0.09), 0.9, 0.1)
	mat_concrete = _make_material(Color(0.35, 0.34, 0.32), 0.85, 0.05)
	mat_linoleum = _make_material(Color(0.25, 0.22, 0.18), 0.6, 0.3)
	mat_drywall = _make_material(Color(0.75, 0.72, 0.68), 0.95, 0.02)
	mat_ceiling_tile = _make_material(Color(0.8, 0.78, 0.75), 0.9, 0.02)
	mat_metal = _make_material(Color(0.5, 0.5, 0.52), 0.3, 0.7)
	mat_wood = _make_material(Color(0.4, 0.28, 0.15), 0.7, 0.1)
	mat_glass = _make_material(Color(0.6, 0.7, 0.8, 0.3), 0.05, 0.9)
	mat_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_brick = _make_material(Color(0.45, 0.25, 0.18), 0.9, 0.05)
	mat_tile_white = _make_material(Color(0.85, 0.85, 0.82), 0.4, 0.5)
	mat_tile_blue = _make_material(Color(0.3, 0.4, 0.55), 0.4, 0.5)
	mat_carpet = _make_material(Color(0.2, 0.15, 0.12), 0.95, 0.02)
	mat_motel_door = _make_material(Color(0.3, 0.18, 0.1), 0.75, 0.08)
	mat_counter_top = _make_material(Color(0.35, 0.3, 0.28), 0.4, 0.4)
	mat_shelf_metal = _make_material(Color(0.55, 0.55, 0.55), 0.35, 0.6)
	mat_exterior_sign = _make_material(Color(0.15, 0.05, 0.02), 0.6, 0.1)
	mat_exterior_sign.emission_enabled = true
	mat_exterior_sign.emission = Color(1.0, 0.3, 0.15)
	mat_exterior_sign.emission_energy_multiplier = 2.0
	mat_pump_body = _make_material(Color(0.6, 0.58, 0.55), 0.4, 0.5)
	mat_dirt = _make_material(Color(0.2, 0.15, 0.1), 0.95, 0.02)
	mat_rust = _make_material(Color(0.4, 0.2, 0.1), 0.85, 0.05)


func _make_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	return mat


# =============================================================================
# GROUND AND PARKING
# =============================================================================

func _build_ground_and_parking() -> void:
	# Main asphalt ground plane
	var ground := _create_box("Ground", Vector3(120, 0.2, 120), Vector3(0, -0.1, 0), mat_asphalt)
	add_child(ground)

	# Concrete sidewalks around buildings
	var sidewalk_front := _create_box("SidewalkFront", Vector3(30, 0.15, 3), Vector3(0, 0.02, 7), mat_concrete)
	add_child(sidewalk_front)
	var sidewalk_side := _create_box("SidewalkSide", Vector3(3, 0.15, 20), Vector3(-13, 0.02, 0), mat_concrete)
	add_child(sidewalk_side)

	# Parking lot striping (raised white lines)
	for i in range(8):
		var stripe := _create_box("ParkingStripe%d" % i, Vector3(0.1, 0.02, 5), Vector3(-18 + i * 3, 0.05, 15), mat_concrete)
		add_child(stripe)

	# Curb stops
	for i in range(7):
		var curb := _create_box("CurbStop%d" % i, Vector3(1.5, 0.15, 0.2), Vector3(-16.5 + i * 3, 0.08, 12.5), mat_concrete)
		add_child(curb)


# =============================================================================
# SHOP BUILDING (Main convenience store)
# =============================================================================

func _build_shop_building() -> void:
	var shop := Node3D.new()
	shop.name = "ShopBuilding"
	add_child(shop)

	# Floor
	var floor_mesh := _create_box("Floor", Vector3(12, 0.15, 14), Vector3(0, 0.075, 0), mat_linoleum)
	shop.add_child(floor_mesh)

	# Walls
	var wall_back := _create_box("WallBack", Vector3(12, 3.2, 0.2), Vector3(0, 1.6, -7), mat_drywall)
	shop.add_child(wall_back)
	var wall_left := _create_box("WallLeft", Vector3(0.2, 3.2, 14), Vector3(-6, 1.6, 0), mat_drywall)
	shop.add_child(wall_left)
	var wall_right := _create_box("WallRight", Vector3(0.2, 3.2, 14), Vector3(6, 1.6, 0), mat_drywall)
	shop.add_child(wall_right)

	# Front wall with window opening
	var front_wall_left := _create_box("FrontWallLeft", Vector3(3, 3.2, 0.2), Vector3(-4.5, 1.6, 7), mat_drywall)
	shop.add_child(front_wall_left)
	var front_wall_right := _create_box("FrontWallRight", Vector3(3, 3.2, 0.2), Vector3(4.5, 1.6, 7), mat_drywall)
	shop.add_child(front_wall_right)
	var front_wall_top := _create_box("FrontWallTop", Vector3(6, 0.8, 0.2), Vector3(0, 2.8, 7), mat_drywall)
	shop.add_child(front_wall_top)

	# Glass storefront
	var glass_front := _create_box("GlassFront", Vector3(6, 2.4, 0.05), Vector3(0, 1.2, 7), mat_glass)
	shop.add_child(glass_front)

	# Ceiling
	var ceiling := _create_box("Ceiling", Vector3(12, 0.15, 14), Vector3(0, 3.2, 0), mat_ceiling_tile)
	shop.add_child(ceiling)

	# Counter area
	var counter := _create_box("CounterBase", Vector3(4, 1.0, 0.7), Vector3(3, 0.5, 4.5), mat_counter_top)
	shop.add_child(counter)
	var counter_back := _create_box("CounterBack", Vector3(4, 1.0, 0.5), Vector3(3, 0.5, 3.5), mat_wood)
	shop.add_child(counter_back)

	# Register on counter
	var register := _create_box("RegisterBody", Vector3(0.5, 0.35, 0.4), Vector3(3.5, 1.18, 4.3), mat_metal)
	shop.add_child(register)
	var register_screen := _create_box("RegisterScreen", Vector3(0.35, 0.25, 0.05), Vector3(3.5, 1.35, 4.05), _make_material(Color(0.1, 0.2, 0.1), 0.2, 0.3))
	shop.add_child(register_screen)

	# Shelving units (4 aisles)
	for i in range(4):
		var shelf := _create_shelf_unit("ShelfUnit%d" % i, Vector3(-3 + i * 2.2, 0, -1))
		shop.add_child(shelf)

	# Cooler wall (back wall, glass fronted)
	var cooler_back := _create_box("CoolerBack", Vector3(10, 2.5, 0.5), Vector3(0, 1.25, -6.5), mat_metal)
	shop.add_child(cooler_back)
	var cooler_glass := _create_box("CoolerGlass", Vector3(10, 2.2, 0.05), Vector3(0, 1.25, -6.2), mat_glass)
	shop.add_child(cooler_glass)

	# Coffee station
	var coffee_counter := _create_box("CoffeeCounter", Vector3(2, 0.9, 0.6), Vector3(-4.5, 0.45, 4), mat_counter_top)
	shop.add_child(coffee_counter)
	var coffee_machine := _create_box("CoffeeMachine", Vector3(0.4, 0.5, 0.35), Vector3(-4.5, 1.15, 4), mat_metal)
	shop.add_child(coffee_machine)

	# Hot food roller grill
	var grill := _create_box("RollerGrill", Vector3(0.6, 0.3, 0.4), Vector3(-3.8, 1.05, 4), mat_metal)
	shop.add_child(grill)

	# Hot dogs on the grill (small cylinders represented as thin boxes)
	for i in range(4):
		var hot_dog_color := Color(0.55, 0.25, 0.15)
		var hot_dog := _create_box("HotDog%d" % i, Vector3(0.04, 0.04, 0.25),
			Vector3(-3.95 + i * 0.1, 1.22, 4), _make_material(hot_dog_color, 0.8, 0.1))
		shop.add_child(hot_dog)

	# Coffee cups beside machine
	for i in range(3):
		var cup_color := Color(0.9, 0.9, 0.85)
		var cup := _create_box("CoffeeCup%d" % i, Vector3(0.06, 0.1, 0.06),
			Vector3(-4.2 + i * 0.15, 0.95, 4.2), _make_material(cup_color, 0.5, 0.2))
		shop.add_child(cup)

	# Condiment station next to coffee
	var condiment_tray := _create_box("CondimentTray", Vector3(0.5, 0.05, 0.2), Vector3(-4.5, 0.92, 4.35), mat_counter_top)
	shop.add_child(condiment_tray)
	# Sugar packets
	var sugar := _create_box("SugarPackets", Vector3(0.12, 0.08, 0.08),
		Vector3(-4.6, 0.98, 4.35), _make_material(Color(0.95, 0.95, 0.9), 0.9, 0.05))
	shop.add_child(sugar)
	# Creamer cups
	var creamer := _create_box("Creamer", Vector3(0.1, 0.06, 0.08),
		Vector3(-4.4, 0.98, 4.35), _make_material(Color(0.9, 0.85, 0.7), 0.9, 0.05))
	shop.add_child(creamer)

	# Slushie machine
	var slushie := _create_box("SlushieMachine", Vector3(0.35, 0.55, 0.3), Vector3(-3.2, 1.1, 4), mat_metal)
	shop.add_child(slushie)
	var slushie_bowl_blue := _create_box("SlushieBlue", Vector3(0.14, 0.25, 0.22),
		Vector3(-3.28, 1.2, 4), _make_material(Color(0.15, 0.3, 0.9, 0.6), 0.1, 0.8))
	slushie_bowl_blue.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shop.add_child(slushie_bowl_blue)
	var slushie_bowl_red := _create_box("SlushieRed", Vector3(0.14, 0.25, 0.22),
		Vector3(-3.12, 1.2, 4), _make_material(Color(0.85, 0.1, 0.15, 0.6), 0.1, 0.8))
	slushie_bowl_red.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shop.add_child(slushie_bowl_red)

	# Nacho/chip warmer
	var nacho_warmer := _create_box("NachoWarmer", Vector3(0.35, 0.3, 0.3), Vector3(-2.5, 1.05, 4),
		_make_material(Color(0.9, 0.75, 0.2), 0.5, 0.3))
	shop.add_child(nacho_warmer)
	var nacho_glass := _create_box("NachoGlass", Vector3(0.33, 0.28, 0.02),
		Vector3(-2.5, 1.05, 3.84), mat_glass)
	shop.add_child(nacho_glass)

	# Newspaper/magazine rack near entrance
	var mag_rack := _create_box("MagRack", Vector3(0.6, 1.2, 0.3), Vector3(3.5, 0.6, 5.5), mat_metal)
	shop.add_child(mag_rack)
	for i in range(3):
		var mag := _create_box("Magazine%d" % i, Vector3(0.18, 0.25, 0.02),
			Vector3(3.35 + i * 0.15, 0.9, 5.36), _make_material(
				Color(randf_range(0.4, 0.9), randf_range(0.2, 0.7), randf_range(0.2, 0.5)), 0.6, 0.1))
		shop.add_child(mag)

	# Stockroom door (back-left)
	_add_door_frame(shop, "StockroomDoor", Vector3(-5.5, 0, -5), 0.0)

	# Office door (back-right)
	_add_door_frame(shop, "OfficeDoor", Vector3(5.5, 0, -5), 180.0)

	# Lighting - fluorescent tubes
	for i in range(3):
		for j in range(2):
			var light := OmniLight3D.new()
			light.name = "ShopLight_%d_%d" % [i, j]
			light.position = Vector3(-3 + i * 3, 2.9, -3 + j * 5)
			light.light_color = Color(0.9, 0.95, 1.0)
			light.light_energy = 1.8
			light.omni_range = 6.0
			light.omni_attenuation = 1.5
			light.shadow_enabled = true
			light.add_to_group("shop_lights")
			shop.add_child(light)

	# Vending machine
	var vending := _create_box("VendingMachine", Vector3(0.8, 1.8, 0.7), Vector3(5.3, 0.9, 2), mat_metal)
	shop.add_child(vending)
	var vending_glass := _create_box("VendingGlass", Vector3(0.7, 1.2, 0.02), Vector3(5.3, 1.1, 1.63), mat_glass)
	shop.add_child(vending_glass)

	# Floor mat at entrance
	var floor_mat := _create_box("FloorMat", Vector3(2, 0.02, 1), Vector3(0, 0.16, 6), mat_dirt)
	shop.add_child(floor_mat)


func _create_shelf_unit(shelf_name: String, pos: Vector3) -> Node3D:
	var unit := Node3D.new()
	unit.name = shelf_name
	unit.position = pos

	# Shelf frame
	var frame_left := _create_box("FrameLeft", Vector3(0.05, 1.8, 0.5), Vector3(-0.5, 0.9, 0), mat_shelf_metal)
	unit.add_child(frame_left)
	var frame_right := _create_box("FrameRight", Vector3(0.05, 1.8, 0.5), Vector3(0.5, 0.9, 0), mat_shelf_metal)
	unit.add_child(frame_right)

	# Shelves (4 levels)
	for i in range(4):
		var shelf := _create_box("Shelf%d" % i, Vector3(1.0, 0.03, 0.5), Vector3(0, 0.3 + i * 0.45, 0), mat_shelf_metal)
		unit.add_child(shelf)

		# Products on shelves (colored boxes)
		for j in range(3):
			var product_color := Color(randf_range(0.3, 0.8), randf_range(0.2, 0.7), randf_range(0.1, 0.6))
			var product := _create_box("Product_%d_%d" % [i, j], Vector3(0.15, 0.2, 0.1),
				Vector3(-0.3 + j * 0.3, 0.42 + i * 0.45, 0), _make_material(product_color, 0.7, 0.05))
			unit.add_child(product)

	return unit


# =============================================================================
# MOTEL BUILDING
# =============================================================================

func _build_motel_building() -> void:
	var motel := Node3D.new()
	motel.name = "MotelBuilding"
	motel.position = Vector3(15, 0, -5)
	add_child(motel)

	# Motel is an L-shaped building
	# Lobby section
	var lobby_floor := _create_box("LobbyFloor", Vector3(6, 0.15, 6), Vector3(0, 0.075, 0), mat_carpet)
	motel.add_child(lobby_floor)
	var lobby_back := _create_box("LobbyWallBack", Vector3(6, 3.0, 0.2), Vector3(0, 1.5, -3), mat_drywall)
	motel.add_child(lobby_back)
	var lobby_left := _create_box("LobbyWallLeft", Vector3(0.2, 3.0, 6), Vector3(-3, 1.5, 0), mat_drywall)
	motel.add_child(lobby_left)
	var lobby_right := _create_box("LobbyWallRight", Vector3(0.2, 3.0, 6), Vector3(3, 1.5, 0), mat_drywall)
	motel.add_child(lobby_right)
	var lobby_front_l := _create_box("LobbyFrontL", Vector3(1.5, 3.0, 0.2), Vector3(-2.25, 1.5, 3), mat_drywall)
	motel.add_child(lobby_front_l)
	var lobby_front_r := _create_box("LobbyFrontR", Vector3(1.5, 3.0, 0.2), Vector3(2.25, 1.5, 3), mat_drywall)
	motel.add_child(lobby_front_r)
	var lobby_ceiling := _create_box("LobbyCeiling", Vector3(6, 0.15, 6), Vector3(0, 3.0, 0), mat_ceiling_tile)
	motel.add_child(lobby_ceiling)

	# Lobby front desk
	var front_desk := _create_box("FrontDesk", Vector3(2.5, 1.1, 0.6), Vector3(0, 0.55, 1), mat_wood)
	motel.add_child(front_desk)
	var key_board := _create_box("KeyBoard", Vector3(1.0, 0.8, 0.05), Vector3(-2.8, 1.5, -2.8), mat_wood)
	motel.add_child(key_board)

	# Key hooks on board
	for i in range(6):
		var hook := _create_box("KeyHook%d" % (i + 1), Vector3(0.08, 0.08, 0.04),
			Vector3(-2.8 + float(i % 3) * 0.35, 1.7 - float(i / 3) * 0.3, -2.75), mat_metal)
		motel.add_child(hook)

	# Lobby light
	var lobby_light := OmniLight3D.new()
	lobby_light.name = "LobbyLight"
	lobby_light.position = Vector3(0, 2.7, 0)
	lobby_light.light_color = Color(1.0, 0.85, 0.6)
	lobby_light.light_energy = 1.5
	lobby_light.omni_range = 8.0
	lobby_light.shadow_enabled = true
	lobby_light.add_to_group("motel_lights")
	motel.add_child(lobby_light)

	# Room hallway
	var hallway_floor := _create_box("HallwayFloor", Vector3(20, 0.15, 2.5), Vector3(7, 0.075, -3.5), mat_carpet)
	motel.add_child(hallway_floor)
	var hallway_back := _create_box("HallwayWallBack", Vector3(20, 3.0, 0.2), Vector3(7, 1.5, -4.75), mat_drywall)
	motel.add_child(hallway_back)
	var hallway_front := _create_box("HallwayWallFront", Vector3(20, 3.0, 0.2), Vector3(7, 1.5, -2.25), mat_drywall)
	motel.add_child(hallway_front)
	var hallway_ceiling := _create_box("HallwayCeiling", Vector3(20, 0.15, 2.5), Vector3(7, 3.0, -3.5), mat_ceiling_tile)
	motel.add_child(hallway_ceiling)

	# Hallway lights (flickering fluorescent feel)
	for i in range(4):
		var h_light := OmniLight3D.new()
		h_light.name = "HallwayLight%d" % i
		h_light.position = Vector3(-1 + i * 5, 2.7, -3.5)
		h_light.light_color = Color(0.9, 0.92, 1.0)
		h_light.light_energy = 1.0
		h_light.omni_range = 5.0
		h_light.shadow_enabled = i == 0  # Only first has shadow for performance
		h_light.add_to_group("motel_lights")
		motel.add_child(h_light)

	# 6 Guest room doors along hallway
	for i in range(6):
		var door_x := -1 + i * 3.3
		var door := _create_box("RoomDoor%d" % (i + 1), Vector3(0.9, 2.2, 0.08),
			Vector3(door_x, 1.1, -4.6), mat_motel_door)
		motel.add_child(door)

		# Room number
		var number_plate := _create_box("RoomNumber%d" % (i + 1), Vector3(0.15, 0.1, 0.02),
			Vector3(door_x + 0.35, 1.8, -4.55), mat_metal)
		motel.add_child(number_plate)

		# Room 4 special - boarded up
		if i == 3:
			for b in range(3):
				var board := _create_box("Board%d_%d" % [i, b], Vector3(1.0, 0.12, 0.04),
					Vector3(door_x, 0.6 + b * 0.7, -4.52), mat_wood)
				motel.add_child(board)

	# Guest rooms (simple interior visible through door)
	for i in range(6):
		var room := Node3D.new()
		room.name = "Room%d" % (i + 1)
		room.position = Vector3(-1 + i * 3.3, 0, -7.5)
		motel.add_child(room)

		# Room floor
		var r_floor := _create_box("RFloor", Vector3(3, 0.15, 3), Vector3(0, 0.075, 0), mat_carpet)
		room.add_child(r_floor)
		# Bed
		var bed_frame := _create_box("BedFrame", Vector3(1.5, 0.4, 2), Vector3(0, 0.2, -0.5), mat_wood)
		room.add_child(bed_frame)
		var mattress := _create_box("Mattress", Vector3(1.4, 0.2, 1.9), Vector3(0, 0.5, -0.5), _make_material(Color(0.8, 0.78, 0.7), 0.9, 0.0))
		room.add_child(mattress)
		# Nightstand
		var nightstand := _create_box("Nightstand", Vector3(0.4, 0.5, 0.4), Vector3(1.0, 0.25, -1), mat_wood)
		room.add_child(nightstand)
		# Room light
		var r_light := OmniLight3D.new()
		r_light.name = "RoomLight"
		r_light.position = Vector3(0, 2.5, 0)
		r_light.light_color = Color(1.0, 0.9, 0.7)
		r_light.light_energy = 0.8
		r_light.omni_range = 4.0
		r_light.add_to_group("motel_room_lights")
		room.add_child(r_light)


# =============================================================================
# BATHROOMS
# =============================================================================

func _build_bathrooms(parent: Node3D, pos: Vector3) -> void:
	var bathroom := Node3D.new()
	bathroom.name = "Bathrooms"
	bathroom.position = pos
	parent.add_child(bathroom)

	# Floor
	var b_floor := _create_box("BathFloor", Vector3(4, 0.15, 5), Vector3(0, 0.075, 0), mat_tile_white)
	bathroom.add_child(b_floor)
	# Walls
	var b_back := _create_box("BathWallBack", Vector3(4, 3.0, 0.2), Vector3(0, 1.5, -2.5), mat_tile_blue)
	bathroom.add_child(b_back)
	var b_left := _create_box("BathWallLeft", Vector3(0.2, 3.0, 5), Vector3(-2, 1.5, 0), mat_tile_blue)
	bathroom.add_child(b_left)
	var b_right := _create_box("BathWallRight", Vector3(0.2, 3.0, 5), Vector3(2, 1.5, 0), mat_tile_blue)
	bathroom.add_child(b_right)

	# Stalls (3)
	for i in range(3):
		var stall_wall := _create_box("StallWall%d" % i, Vector3(0.05, 1.8, 1.2),
			Vector3(-1.2 + i * 1.2, 0.9, -1.5), mat_metal)
		bathroom.add_child(stall_wall)
		var stall_door := _create_box("StallDoor%d" % i, Vector3(0.7, 1.6, 0.05),
			Vector3(-0.6 + i * 1.2, 0.8, -0.9), mat_metal)
		bathroom.add_child(stall_door)

	# Sinks
	for i in range(2):
		var sink := _create_box("Sink%d" % i, Vector3(0.5, 0.15, 0.4),
			Vector3(-0.5 + i * 1.0, 0.85, 2), mat_tile_white)
		bathroom.add_child(sink)

	# Mirror
	var mirror := _create_box("Mirror", Vector3(2, 1.0, 0.05), Vector3(0, 1.6, 2.3), mat_glass)
	bathroom.add_child(mirror)

	# Bathroom light
	var b_light := OmniLight3D.new()
	b_light.name = "BathLight"
	b_light.position = Vector3(0, 2.7, 0)
	b_light.light_color = Color(0.95, 0.98, 1.0)
	b_light.light_energy = 2.0
	b_light.omni_range = 5.0
	b_light.add_to_group("shop_lights")
	bathroom.add_child(b_light)


# =============================================================================
# FUEL FORECOURT
# =============================================================================

func _build_fuel_forecourt() -> void:
	var forecourt := Node3D.new()
	forecourt.name = "FuelForecourt"
	forecourt.position = Vector3(0, 0, 18)
	add_child(forecourt)

	# Canopy structure
	var canopy_roof := _create_box("CanopyRoof", Vector3(14, 0.15, 8), Vector3(0, 4.5, 0), mat_metal)
	forecourt.add_child(canopy_roof)

	# Canopy support columns (4)
	for i in range(2):
		for j in range(2):
			var col := _create_box("CanopyColumn_%d_%d" % [i, j], Vector3(0.3, 4.5, 0.3),
				Vector3(-5 + i * 10, 2.25, -3 + j * 6), mat_metal)
			forecourt.add_child(col)

	# Pump islands (2 islands, 2 pumps each = 4 pumps)
	for i in range(2):
		var island := _create_box("PumpIsland%d" % i, Vector3(1.0, 0.2, 5), Vector3(-3 + i * 6, 0.1, 0), mat_concrete)
		forecourt.add_child(island)

		for j in range(2):
			var pump := _create_fuel_pump("Pump%d" % (i * 2 + j + 1),
				Vector3(-3 + i * 6, 0.2, -1.5 + j * 3))
			forecourt.add_child(pump)

	# Canopy lights (bright sodium vapor)
	for i in range(3):
		for j in range(2):
			var c_light := OmniLight3D.new()
			c_light.name = "CanopyLight_%d_%d" % [i, j]
			c_light.position = Vector3(-4 + i * 4, 4.3, -2 + j * 4)
			c_light.light_color = Color(1.0, 0.85, 0.55)
			c_light.light_energy = 3.0
			c_light.omni_range = 10.0
			c_light.omni_attenuation = 1.2
			c_light.shadow_enabled = i == 1 and j == 0  # One shadow for performance
			c_light.add_to_group("forecourt_lights")
			c_light.add_to_group("exterior_lights")
			forecourt.add_child(c_light)

	# Bollards around islands
	for i in range(4):
		var bollard := _create_box("Bollard%d" % i, Vector3(0.15, 0.8, 0.15),
			Vector3(-4.5 + i * 3, 0.4, 3.5), _make_material(Color(0.8, 0.7, 0.0), 0.6, 0.3))
		forecourt.add_child(bollard)


func _create_fuel_pump(pump_name: String, pos: Vector3) -> Node3D:
	var pump := Node3D.new()
	pump.name = pump_name
	pump.position = pos

	var body := _create_box("Body", Vector3(0.5, 1.4, 0.35), Vector3(0, 0.7, 0), mat_pump_body)
	pump.add_child(body)
	var screen := _create_box("Screen", Vector3(0.35, 0.2, 0.02), Vector3(0, 1.2, 0.18), _make_material(Color(0.05, 0.15, 0.05), 0.3, 0.2))
	pump.add_child(screen)
	var nozzle_holder := _create_box("NozzleHolder", Vector3(0.12, 0.3, 0.08), Vector3(0.25, 0.9, 0.18), mat_metal)
	pump.add_child(nozzle_holder)
	var hose := _create_box("Hose", Vector3(0.04, 0.04, 0.8), Vector3(0.25, 0.75, 0.5), _make_material(Color(0.1, 0.1, 0.1), 0.8, 0.1))
	pump.add_child(hose)

	return pump


# =============================================================================
# PARKING LOT
# =============================================================================

func _build_parking_lot() -> void:
	var parking := Node3D.new()
	parking.name = "ParkingLot"
	parking.position = Vector3(-18, 0, 10)
	add_child(parking)

	# Lamp posts (sodium vapor)
	for i in range(3):
		var post := _create_box("LampPost%d" % i, Vector3(0.12, 5, 0.12), Vector3(i * 8, 2.5, 0), mat_metal)
		parking.add_child(post)
		var lamp_arm := _create_box("LampArm%d" % i, Vector3(1.0, 0.08, 0.08), Vector3(i * 8 + 0.5, 5, 0), mat_metal)
		parking.add_child(lamp_arm)

		var p_light := OmniLight3D.new()
		p_light.name = "ParkingLight%d" % i
		p_light.position = Vector3(i * 8 + 1, 4.8, 0)
		p_light.light_color = Color(1.0, 0.7, 0.3)
		p_light.light_energy = 2.5
		p_light.omni_range = 15.0
		p_light.omni_attenuation = 1.5
		p_light.shadow_enabled = i == 1
		p_light.add_to_group("parking_lights")
		p_light.add_to_group("exterior_lights")
		parking.add_child(p_light)

	# Parked vehicles (placeholder boxes)
	var car_colors := [Color(0.15, 0.15, 0.2), Color(0.5, 0.1, 0.1), Color(0.3, 0.35, 0.4)]
	for i in range(3):
		if randf() > 0.4:  # Not all spots filled
			var car := _create_box("ParkedCar%d" % i, Vector3(1.8, 1.3, 4.2),
				Vector3(i * 3, 0.65, 3), _make_material(car_colors[i], 0.3, 0.6))
			parking.add_child(car)


# =============================================================================
# DUMPSTER ALLEY
# =============================================================================

func _build_dumpster_alley() -> void:
	var alley := Node3D.new()
	alley.name = "DumpsterAlley"
	alley.position = Vector3(-9, 0, -8)
	add_child(alley)

	# Fence walls
	var fence_back := _create_box("FenceBack", Vector3(6, 2.0, 0.1), Vector3(0, 1, -3), mat_metal)
	alley.add_child(fence_back)
	var fence_side := _create_box("FenceSide", Vector3(0.1, 2.0, 6), Vector3(-3, 1, 0), mat_metal)
	alley.add_child(fence_side)

	# Dumpsters (2)
	for i in range(2):
		var dumpster := _create_box("Dumpster%d" % i, Vector3(1.8, 1.2, 1.5),
			Vector3(-1.5 + i * 2.5, 0.6, -1), _make_material(Color(0.15, 0.3, 0.15), 0.7, 0.3))
		alley.add_child(dumpster)
		var lid := _create_box("DumpsterLid%d" % i, Vector3(1.8, 0.05, 0.8),
			Vector3(-1.5 + i * 2.5, 1.22, -0.6), mat_metal)
		alley.add_child(lid)

	# Trash bags
	for i in range(4):
		var bag := _create_box("TrashBag%d" % i, Vector3(0.4, 0.5, 0.35),
			Vector3(randf_range(-2, 2), 0.25, randf_range(0, 2)), _make_material(Color(0.05, 0.05, 0.05), 0.9, 0.0))
		alley.add_child(bag)

	# Dim light
	var alley_light := OmniLight3D.new()
	alley_light.name = "AlleyLight"
	alley_light.position = Vector3(0, 3, 0)
	alley_light.light_color = Color(0.8, 0.7, 0.5)
	alley_light.light_energy = 0.8
	alley_light.omni_range = 6.0
	alley_light.add_to_group("exterior_lights")
	alley.add_child(alley_light)


# =============================================================================
# MAINTENANCE SHED
# =============================================================================

func _build_maintenance_shed() -> void:
	var shed := Node3D.new()
	shed.name = "MaintenanceShed"
	shed.position = Vector3(-14, 0, -10)
	add_child(shed)

	# Simple shed structure
	var floor_slab := _create_box("ShedFloor", Vector3(4, 0.15, 4), Vector3(0, 0.075, 0), mat_concrete)
	shed.add_child(floor_slab)
	var wall_b := _create_box("ShedWallBack", Vector3(4, 2.5, 0.15), Vector3(0, 1.25, -2), mat_metal)
	shed.add_child(wall_b)
	var wall_l := _create_box("ShedWallLeft", Vector3(0.15, 2.5, 4), Vector3(-2, 1.25, 0), mat_metal)
	shed.add_child(wall_l)
	var wall_r := _create_box("ShedWallRight", Vector3(0.15, 2.5, 4), Vector3(2, 1.25, 0), mat_metal)
	shed.add_child(wall_r)
	var roof := _create_box("ShedRoof", Vector3(4.5, 0.1, 4.5), Vector3(0, 2.55, 0), mat_metal)
	shed.add_child(roof)

	# Generator inside
	var generator := _create_box("Generator", Vector3(1.2, 0.8, 0.8), Vector3(-0.5, 0.4, 0), _make_material(Color(0.2, 0.25, 0.2), 0.7, 0.4))
	shed.add_child(generator)

	# Tool rack
	var tool_rack := _create_box("ToolRack", Vector3(0.1, 1.5, 1.5), Vector3(-1.8, 0.75, -1), mat_wood)
	shed.add_child(tool_rack)

	# Workbench
	var workbench := _create_box("Workbench", Vector3(2, 0.9, 0.7), Vector3(0.5, 0.45, -1.5), mat_wood)
	shed.add_child(workbench)

	var shed_light := OmniLight3D.new()
	shed_light.name = "ShedLight"
	shed_light.position = Vector3(0, 2.3, 0)
	shed_light.light_color = Color(1.0, 0.9, 0.6)
	shed_light.light_energy = 1.0
	shed_light.omni_range = 5.0
	shed_light.add_to_group("exterior_lights")
	shed.add_child(shed_light)


# =============================================================================
# BASEMENT ENTRANCE
# =============================================================================

func _build_basement_entrance() -> void:
	var basement := Node3D.new()
	basement.name = "BasementEntrance"
	basement.position = Vector3(8, 0, -12)
	add_child(basement)

	# Storm shelter doors (angled)
	var door_frame := _create_box("BasementFrame", Vector3(2, 0.3, 2), Vector3(0, 0.15, 0), mat_concrete)
	basement.add_child(door_frame)
	var door_l := _create_box("BasementDoorL", Vector3(0.95, 0.08, 1.5), Vector3(-0.5, 0.5, 0), mat_metal)
	door_l.rotation_degrees.x = -30
	basement.add_child(door_l)
	var door_r := _create_box("BasementDoorR", Vector3(0.95, 0.08, 1.5), Vector3(0.5, 0.5, 0), mat_metal)
	door_r.rotation_degrees.x = -30
	basement.add_child(door_r)

	# Steps going down
	for i in range(5):
		var step := _create_box("Step%d" % i, Vector3(1.8, 0.2, 0.3), Vector3(0, -0.2 * i, -0.5 - i * 0.3), mat_concrete)
		basement.add_child(step)

	# Basement room below
	var b_floor := _create_box("BasementFloor", Vector3(6, 0.15, 6), Vector3(0, -2, -4), mat_concrete)
	basement.add_child(b_floor)
	var b_ceiling := _create_box("BasementCeiling", Vector3(6, 0.15, 6), Vector3(0, 0.5, -4), mat_concrete)
	basement.add_child(b_ceiling)
	var b_wall_b := _create_box("BasementWallBack", Vector3(6, 2.5, 0.2), Vector3(0, -0.75, -7), mat_concrete)
	basement.add_child(b_wall_b)
	var b_wall_l := _create_box("BasementWallLeft", Vector3(0.2, 2.5, 6), Vector3(-3, -0.75, -4), mat_concrete)
	basement.add_child(b_wall_l)
	var b_wall_r := _create_box("BasementWallRight", Vector3(0.2, 2.5, 6), Vector3(3, -0.75, -4), mat_concrete)
	basement.add_child(b_wall_r)

	# Archive shelves in basement
	for i in range(3):
		var archive_shelf := _create_box("ArchiveShelf%d" % i, Vector3(1.5, 1.8, 0.4),
			Vector3(-2 + i * 2, -1.1, -6.5), mat_wood)
		basement.add_child(archive_shelf)
		# File boxes on shelves
		for j in range(2):
			var box := _create_box("FileBox_%d_%d" % [i, j], Vector3(0.3, 0.25, 0.35),
				Vector3(-2 + i * 2 + (j - 0.5) * 0.4, -0.1 + j * 0.3, -6.5),
				_make_material(Color(0.6, 0.55, 0.4), 0.9, 0.0))
			basement.add_child(box)


# =============================================================================
# EXTERIOR SIGN
# =============================================================================

func _build_exterior_sign() -> void:
	var sign_node := Node3D.new()
	sign_node.name = "ExteriorSign"
	sign_node.position = Vector3(0, 0, 30)
	add_child(sign_node)

	# Sign post
	var post := _create_box("SignPost", Vector3(0.3, 8, 0.3), Vector3(0, 4, 0), mat_metal)
	sign_node.add_child(post)

	# Sign board
	var board := _create_box("SignBoard", Vector3(4, 2.5, 0.15), Vector3(0, 7.5, 0), mat_exterior_sign)
	sign_node.add_child(board)

	# "EXIT 13" emissive text panel
	var text_panel := _create_box("TextPanel", Vector3(3.5, 1.5, 0.02), Vector3(0, 7.8, 0.1), mat_exterior_sign)
	sign_node.add_child(text_panel)

	# Sign illumination
	var sign_light := SpotLight3D.new()
	sign_light.name = "SignLight"
	sign_light.position = Vector3(0, 9, 1)
	sign_light.rotation_degrees.x = 30
	sign_light.light_color = Color(1.0, 0.4, 0.2)
	sign_light.light_energy = 4.0
	sign_light.spot_range = 12.0
	sign_light.spot_angle = 35.0
	sign_light.shadow_enabled = true
	sign_light.add_to_group("sign_lights")
	sign_light.add_to_group("exterior_lights")
	sign_node.add_child(sign_light)

	# Ground-level sign light (up-lighting)
	var ground_light := SpotLight3D.new()
	ground_light.name = "SignGroundLight"
	ground_light.position = Vector3(0, 0.5, 0.5)
	ground_light.rotation_degrees.x = -80
	ground_light.light_color = Color(1.0, 0.5, 0.25)
	ground_light.light_energy = 2.0
	ground_light.spot_range = 10.0
	ground_light.spot_angle = 40.0
	ground_light.add_to_group("sign_lights")
	ground_light.add_to_group("exterior_lights")
	sign_node.add_child(ground_light)


# =============================================================================
# ROAD AND HIGHWAY
# =============================================================================

func _build_road_and_highway() -> void:
	var road := Node3D.new()
	road.name = "Highway"
	add_child(road)

	# Main road surface
	var road_surface := _create_box("RoadSurface", Vector3(8, 0.1, 200), Vector3(0, -0.05, 50), mat_asphalt)
	road.add_child(road_surface)

	# Center line markings
	for i in range(20):
		var marking := _create_box("CenterLine%d" % i, Vector3(0.1, 0.02, 3),
			Vector3(0, 0.02, 5 + i * 10), _make_material(Color(0.9, 0.8, 0.2), 0.7, 0.1))
		road.add_child(marking)

	# Roadside reflectors
	for i in range(10):
		var reflector := _create_box("Reflector%d" % i, Vector3(0.05, 0.5, 0.05),
			Vector3(4.5, 0.25, 10 + i * 15), _make_material(Color(0.8, 0.3, 0.1), 0.3, 0.5))
		reflector.get_child(0) if reflector.get_child_count() > 0 else null
		road.add_child(reflector)

	# Distant highway glow (faked with lights)
	var highway_glow := OmniLight3D.new()
	highway_glow.name = "HighwayGlow"
	highway_glow.position = Vector3(0, 2, 80)
	highway_glow.light_color = Color(1.0, 0.8, 0.5)
	highway_glow.light_energy = 0.5
	highway_glow.omni_range = 30.0
	highway_glow.add_to_group("exterior_lights")
	road.add_child(highway_glow)


# =============================================================================
# PROPS AND DETAILS
# =============================================================================

func _build_props_and_details() -> void:
	# Build bathrooms attached to shop
	_build_bathrooms(self, Vector3(-9, 0, 2))

	# Utility corridor between shop and motel
	var corridor := Node3D.new()
	corridor.name = "UtilityCorridor"
	corridor.position = Vector3(7, 0, -2)
	add_child(corridor)

	var cor_floor := _create_box("CorridorFloor", Vector3(3, 0.15, 8), Vector3(0, 0.075, 0), mat_linoleum)
	corridor.add_child(cor_floor)
	var cor_wall_l := _create_box("CorridorWallL", Vector3(0.2, 3, 8), Vector3(-1.5, 1.5, 0), mat_drywall)
	corridor.add_child(cor_wall_l)
	var cor_wall_r := _create_box("CorridorWallR", Vector3(0.2, 3, 8), Vector3(1.5, 1.5, 0), mat_drywall)
	corridor.add_child(cor_wall_r)
	var cor_ceiling := _create_box("CorridorCeiling", Vector3(3, 0.15, 8), Vector3(0, 3, 0), mat_ceiling_tile)
	corridor.add_child(cor_ceiling)

	# Breaker panel in utility corridor
	var breaker_panel := _create_box("BreakerPanel", Vector3(0.6, 0.8, 0.1), Vector3(-1.3, 1.4, -2), mat_metal)
	corridor.add_child(breaker_panel)

	# Staff office
	var office := Node3D.new()
	office.name = "StaffOffice"
	office.position = Vector3(8, 0, -6)
	add_child(office)

	var off_floor := _create_box("OfficeFloor", Vector3(4, 0.15, 4), Vector3(0, 0.075, 0), mat_carpet)
	office.add_child(off_floor)
	var off_desk := _create_box("OfficeDesk", Vector3(1.5, 0.75, 0.7), Vector3(0, 0.375, -1.5), mat_wood)
	office.add_child(off_desk)
	var off_chair := _create_box("OfficeChair", Vector3(0.5, 0.8, 0.5), Vector3(0, 0.4, -0.5), _make_material(Color(0.15, 0.15, 0.15), 0.8, 0.1))
	office.add_child(off_chair)
	var filing_cabinet := _create_box("FilingCabinet", Vector3(0.5, 1.3, 0.5), Vector3(1.5, 0.65, -1.5), mat_metal)
	office.add_child(filing_cabinet)

	# Cassette player on desk
	var cassette_player := _create_box("CassettePlayer", Vector3(0.25, 0.08, 0.15), Vector3(-0.3, 0.8, -1.5), _make_material(Color(0.2, 0.18, 0.15), 0.7, 0.2))
	office.add_child(cassette_player)

	# Security monitor setup
	var monitor_desk := _create_box("MonitorDesk", Vector3(1.5, 0.75, 0.6), Vector3(-1.5, 0.375, -1.5), mat_wood)
	office.add_child(monitor_desk)
	var monitor := _create_box("SecurityMonitor", Vector3(0.8, 0.6, 0.1), Vector3(-1.5, 1.1, -1.65), _make_material(Color(0.05, 0.08, 0.05), 0.3, 0.3))
	office.add_child(monitor)

	var off_light := OmniLight3D.new()
	off_light.name = "OfficeLight"
	off_light.position = Vector3(0, 2.5, 0)
	off_light.light_color = Color(1.0, 0.9, 0.7)
	off_light.light_energy = 1.2
	off_light.omni_range = 5.0
	off_light.add_to_group("shop_lights")
	office.add_child(off_light)

	# Laundry room (near motel)
	var laundry := Node3D.new()
	laundry.name = "LaundryRoom"
	laundry.position = Vector3(20, 0, 0)
	add_child(laundry)

	var l_floor := _create_box("LaundryFloor", Vector3(3, 0.15, 3), Vector3(0, 0.075, 0), mat_tile_white)
	laundry.add_child(l_floor)
	# Washing machines
	for i in range(2):
		var washer := _create_box("Washer%d" % i, Vector3(0.7, 0.9, 0.7), Vector3(-0.5 + i * 1.2, 0.45, -1), mat_metal)
		laundry.add_child(washer)
	# Dryer
	var dryer := _create_box("Dryer", Vector3(0.7, 0.9, 0.7), Vector3(0.7, 0.45, -1), mat_metal)
	laundry.add_child(dryer)

	# Ice freezer area (outside shop)
	var ice_freezer := _create_box("IceFreezer", Vector3(1.2, 1.0, 0.8), Vector3(-7, 0.5, 6), mat_metal)
	add_child(ice_freezer)

	# Newspaper stands
	var news_stand := _create_box("NewspaperStand", Vector3(0.4, 1.0, 0.3), Vector3(-4, 0.5, 8), _make_material(Color(0.6, 0.1, 0.1), 0.7, 0.3))
	add_child(news_stand)

	# Bench outside shop
	var bench_seat := _create_box("BenchSeat", Vector3(1.5, 0.08, 0.4), Vector3(4, 0.45, 8.5), mat_wood)
	add_child(bench_seat)
	var bench_back := _create_box("BenchBack", Vector3(1.5, 0.6, 0.08), Vector3(4, 0.75, 8.7), mat_wood)
	add_child(bench_back)
	for i in range(2):
		var bench_leg := _create_box("BenchLeg%d" % i, Vector3(0.08, 0.45, 0.08), Vector3(3.4 + i * 1.2, 0.225, 8.5), mat_metal)
		add_child(bench_leg)

	# Propane tank cage
	var propane_cage := _create_box("PropaneCage", Vector3(1.0, 1.2, 0.8), Vector3(7, 0.6, 7), mat_metal)
	add_child(propane_cage)

	# Air/water station near pumps
	var air_station := _create_box("AirStation", Vector3(0.4, 1.2, 0.3), Vector3(8, 0.6, 15), mat_metal)
	add_child(air_station)

	# Roadside memorial (story element)
	var memorial := Node3D.new()
	memorial.name = "RoadsideMemorial"
	memorial.position = Vector3(5, 0, 28)
	add_child(memorial)

	var cross := _create_box("MemorialCross", Vector3(0.08, 0.6, 0.08), Vector3(0, 0.3, 0), mat_wood)
	memorial.add_child(cross)
	var cross_arm := _create_box("MemorialCrossArm", Vector3(0.4, 0.08, 0.08), Vector3(0, 0.45, 0), mat_wood)
	memorial.add_child(cross_arm)
	# Flowers
	var flowers := _create_box("Flowers", Vector3(0.3, 0.15, 0.2), Vector3(0.15, 0.08, 0.1), _make_material(Color(0.8, 0.2, 0.3), 0.8, 0.0))
	memorial.add_child(flowers)


# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

func _create_box(box_name: String, size: Vector3, pos: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = box_name
	mesh_instance.position = pos
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	box_mesh.material = material
	mesh_instance.mesh = box_mesh
	# Add static collision
	mesh_instance.create_trimesh_collision()
	return mesh_instance


func _add_door_frame(parent: Node3D, door_name: String, pos: Vector3, y_rot: float) -> void:
	var frame := Node3D.new()
	frame.name = door_name
	frame.position = pos
	frame.rotation_degrees.y = y_rot

	var frame_top := _create_box("FrameTop", Vector3(1.2, 0.1, 0.15), Vector3(0, 2.15, 0), mat_wood)
	frame.add_child(frame_top)
	var frame_left := _create_box("FrameLeft", Vector3(0.1, 2.1, 0.15), Vector3(-0.55, 1.05, 0), mat_wood)
	frame.add_child(frame_left)
	var frame_right := _create_box("FrameRight", Vector3(0.1, 2.1, 0.15), Vector3(0.55, 1.05, 0), mat_wood)
	frame.add_child(frame_right)
	var door_panel := _create_box("DoorPanel", Vector3(0.9, 2.05, 0.05), Vector3(0, 1.025, 0), mat_wood)
	frame.add_child(door_panel)

	# Door handle
	var handle := _create_box("Handle", Vector3(0.08, 0.03, 0.08), Vector3(0.35, 1.0, 0.05), mat_metal)
	frame.add_child(handle)

	parent.add_child(frame)
