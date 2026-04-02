## HorrorEventPhantomCar - A car appears on CCTV/at the pump but vanishes when approached.
## Combines CCTV contradiction with environmental unease.
class_name HorrorEventPhantomCar
extends Node

@export var car_mesh: Node3D = null  # Reference to the phantom car mesh
@export var pump_number: int = 3
@export var appear_duration: float = 60.0
@export var approach_distance: float = 15.0  # Distance at which car vanishes

var _is_active: bool = false
var _timer: float = 0.0
var _player_ref: Node3D = null


## Trigger the phantom car event.
func trigger(car: Node3D, player: Node3D) -> void:
	if car == null:
		return

	car_mesh = car
	_player_ref = player
	_is_active = true
	_timer = appear_duration

	# Make car visible
	car_mesh.visible = true

	# Notify CCTV system
	var cctv := _find_cctv_system()
	if cctv:
		cctv.trigger_phantom_car_event()

	# Radio hint
	DialogueManager.show_subtitle("Radio", "...vehicle reported stalled at Exit 13... no registration on file...")
	GameManager.stress += 5.0


func _process(delta: float) -> void:
	if not _is_active:
		return

	_timer -= delta

	# Check if player is approaching
	if _player_ref and car_mesh:
		var distance := _player_ref.global_position.distance_to(car_mesh.global_position)
		if distance < approach_distance:
			_vanish_car()
			return

	# Subtle effects - headlights flicker
	if car_mesh and is_instance_valid(car_mesh):
		for child in car_mesh.get_children():
			if child is Light3D:
				child.light_energy = 1.0 + sin(Time.get_ticks_msec() * 0.003) * 0.3

	if _timer <= 0.0:
		_vanish_car()


func _vanish_car() -> void:
	_is_active = false
	if car_mesh and is_instance_valid(car_mesh):
		# Fade out effect
		var tween := create_tween()
		tween.tween_callback(func():
			car_mesh.visible = false
		).set_delay(0.1)

	GameManager.stress += 8.0
	GameManager.composure -= 3.0
	DialogueManager.show_subtitle("Mara", "It was just... there. Where did it go?")

	EventDirector.complete_event("cctv_phantom_car")


func _find_cctv_system() -> CCTVSystem:
	var nodes := get_tree().get_nodes_in_group("cctv")
	if nodes.size() > 0:
		return nodes[0] as CCTVSystem
	return null
