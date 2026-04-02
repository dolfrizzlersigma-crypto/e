## HorrorEventFlickeringLights - Scripted horror event: lights flicker across the plaza.
## Manipulates light nodes and power grid to create tension.
class_name HorrorEventFlickeringLights
extends Node

@export var flicker_duration: float = 15.0
@export var flicker_intensity: float = 0.5
@export var affected_zone: String = "shop"

var _timer: float = 0.0
var _is_active: bool = false
var _affected_lights: Array[Light3D] = []
var _original_energies: Array[float] = []


## Trigger this horror event.
func trigger(lights: Array[Light3D] = []) -> void:
	_affected_lights = lights
	_original_energies.clear()
	for light in _affected_lights:
		_original_energies.append(light.light_energy)

	_is_active = true
	_timer = flicker_duration

	GameManager.stress += 5.0
	DialogueManager.show_subtitle("", "[The lights begin to flicker]")


func _process(delta: float) -> void:
	if not _is_active:
		return

	_timer -= delta
	if _timer <= 0.0:
		_end_event()
		return

	# Random flickering pattern
	for i in range(_affected_lights.size()):
		var light := _affected_lights[i]
		if light and is_instance_valid(light):
			if randf() < flicker_intensity * delta * 10:
				light.light_energy = randf_range(0.0, _original_energies[i] * 1.5)
			else:
				light.light_energy = lerpf(
					light.light_energy,
					_original_energies[i],
					delta * 3.0
				)


func _end_event() -> void:
	_is_active = false
	# Restore all lights
	for i in range(_affected_lights.size()):
		if _affected_lights[i] and is_instance_valid(_affected_lights[i]):
			_affected_lights[i].light_energy = _original_energies[i]
	_affected_lights.clear()
	_original_energies.clear()
	EventDirector.complete_event("flickering_lights")
