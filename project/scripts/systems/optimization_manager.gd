## OptimizationManager - Runtime performance optimization for the plaza environment.
## Handles LOD-like distance culling, light management, and draw call reduction.
class_name OptimizationManager
extends Node

# --- Configuration ---
@export var enable_distance_culling: bool = true
@export var cull_distance_interior: float = 25.0
@export var cull_distance_exterior: float = 60.0
@export var light_cull_distance: float = 30.0
@export var shadow_cull_distance: float = 15.0
@export var max_active_shadows: int = 4
@export var update_interval: float = 0.5  # Seconds between optimization passes

# --- State ---
var _player_ref: Node3D = null
var _all_lights: Array[Light3D] = []
var _all_meshes: Array[MeshInstance3D] = []
var _shadow_lights: Array[Light3D] = []
var _update_timer: float = 0.0
var _frame_count: int = 0

# --- Performance Tracking ---
var current_fps: float = 0.0
var active_light_count: int = 0
var active_mesh_count: int = 0
var shadow_count: int = 0


func _ready() -> void:
	# Collect all lights and meshes after scene is loaded
	call_deferred("_collect_scene_objects")


## Set player reference for distance calculations.
func setup(player: Node3D) -> void:
	_player_ref = player


func _process(delta: float) -> void:
	if _player_ref == null:
		return

	_frame_count += 1
	current_fps = Engine.get_frames_per_second()

	_update_timer -= delta
	if _update_timer <= 0:
		_update_timer = update_interval
		_optimize_pass()


## Collect all scene objects for optimization.
func _collect_scene_objects() -> void:
	_all_lights.clear()
	_all_meshes.clear()

	for node in _get_all_descendants(get_tree().root):
		if node is Light3D:
			_all_lights.append(node)
		elif node is MeshInstance3D:
			_all_meshes.append(node)


## Main optimization pass - called every update_interval seconds.
func _optimize_pass() -> void:
	if not enable_distance_culling:
		return

	var player_pos := _player_ref.global_position
	var is_indoor := _is_player_indoor(player_pos)

	_optimize_lights(player_pos, is_indoor)
	_optimize_meshes(player_pos, is_indoor)
	_adapt_quality()


## Optimize lights based on distance and importance.
func _optimize_lights(player_pos: Vector3, is_indoor: bool) -> void:
	var light_distances: Array[Dictionary] = []
	active_light_count = 0
	shadow_count = 0

	for light in _all_lights:
		if not is_instance_valid(light):
			continue

		var dist := player_pos.distance_to(light.global_position)
		var cull_dist := light_cull_distance

		# Exterior lights visible from further away
		if light.is_in_group("exterior_lights"):
			cull_dist = cull_distance_exterior if not is_indoor else light_cull_distance * 0.5

		# Enable/disable light based on distance
		if dist > cull_dist:
			light.visible = false
		else:
			light.visible = true
			active_light_count += 1
			light_distances.append({"light": light, "distance": dist})

	# Sort by distance and limit shadow casters
	light_distances.sort_custom(func(a, b): return a["distance"] < b["distance"])

	for i in range(light_distances.size()):
		var entry := light_distances[i]
		var light: Light3D = entry["light"]
		var dist: float = entry["distance"]

		if dist < shadow_cull_distance and shadow_count < max_active_shadows:
			light.shadow_enabled = true
			shadow_count += 1
		else:
			light.shadow_enabled = false


## Optimize mesh visibility based on distance.
func _optimize_meshes(player_pos: Vector3, is_indoor: bool) -> void:
	active_mesh_count = 0

	for mesh in _all_meshes:
		if not is_instance_valid(mesh):
			continue

		var dist := player_pos.distance_to(mesh.global_position)
		var cull_dist := cull_distance_interior if is_indoor else cull_distance_exterior

		# Small objects cull sooner
		if mesh.mesh:
			var aabb := mesh.mesh.get_aabb()
			var size := aabb.size.length()
			if size < 0.5:
				cull_dist *= 0.4  # Small props cull at 40% of normal distance
			elif size < 1.0:
				cull_dist *= 0.7

		if dist > cull_dist:
			mesh.visible = false
		else:
			mesh.visible = true
			active_mesh_count += 1


## Dynamically adjust quality settings based on frame rate.
func _adapt_quality() -> void:
	if current_fps < 30 and max_active_shadows > 2:
		max_active_shadows -= 1
	elif current_fps > 55 and max_active_shadows < 8:
		max_active_shadows += 1

	# Adjust update interval based on performance
	if current_fps < 25:
		update_interval = minf(update_interval + 0.1, 2.0)
	elif current_fps > 50:
		update_interval = maxf(update_interval - 0.05, 0.3)


## Determine if the player is indoors.
func _is_player_indoor(pos: Vector3) -> bool:
	# Simple heuristic based on known building bounds
	# Shop interior
	if pos.x > -6 and pos.x < 6 and pos.z > -7 and pos.z < 7 and pos.y < 3.5:
		return true
	# Motel lobby
	if pos.x > 12 and pos.x < 18 and pos.z > -8 and pos.z < 3:
		return true
	# Office
	if pos.x > 6 and pos.x < 12 and pos.z > -8 and pos.z < -4:
		return true
	# Bathroom
	if pos.x > -11 and pos.x < -7 and pos.z > 0 and pos.z < 5:
		return true
	# Basement
	if pos.y < -0.5:
		return true
	return false


## Get all descendants of a node recursively.
func _get_all_descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_get_all_descendants(child))
	return result


## Get performance stats for HUD display.
func get_perf_stats() -> Dictionary:
	return {
		"fps": current_fps,
		"active_lights": active_light_count,
		"shadow_casters": shadow_count,
		"active_meshes": active_mesh_count,
		"total_lights": _all_lights.size(),
		"total_meshes": _all_meshes.size(),
	}
