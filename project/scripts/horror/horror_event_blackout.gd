## HorrorEventProgressiveBlackout - Power fails zone by zone.
## Forces the player to navigate in darkness to the breaker room.
class_name HorrorEventProgressiveBlackout
extends Node

@export var zone_fail_interval: float = 8.0
@export var total_darkness_duration: float = 15.0

var _is_active: bool = false
var _phase: int = 0
var _timer: float = 0.0
var _power_grid: PowerGrid = null


## Trigger the progressive blackout event.
func trigger(power_grid: PowerGrid) -> void:
	_power_grid = power_grid
	_is_active = true
	_phase = 0
	_timer = zone_fail_interval

	DialogueManager.show_subtitle("", "[A distant storm siren wails]")
	GameManager.stress += 5.0
	_power_grid.trigger_progressive_blackout(zone_fail_interval)


func _process(delta: float) -> void:
	if not _is_active:
		return

	_timer -= delta

	match _phase:
		0:
			if GameManager.electrical_stability <= 0.0:
				_phase = 1
				_timer = total_darkness_duration
				DialogueManager.show_subtitle("Mara", "Everything is out. I need to get to the breaker room.")
				GameManager.stress += 15.0
				GameManager.composure -= 8.0
				ObjectiveManager.add_objective({
					"id": "fix_breakers",
					"title": "Reset the Breakers",
					"description": "Go to the utility room and reset the breaker panel",
					"type": "task",
					"time_limit": 120.0,
					"reward_reputation": 5.0,
					"penalty_reputation": 10.0,
				})
		1:
			if _timer <= 0.0:
				_phase = 2
				DialogueManager.show_subtitle("Mara", "Come on... where is the flashlight...")
		2:
			pass  # Waiting for player to reset breakers


## Called when the player resets the breakers.
func resolve() -> void:
	if not _is_active:
		return
	_is_active = false

	if _power_grid:
		_power_grid.restore_all_power()

	DialogueManager.show_subtitle("Mara", "Okay. Lights are back. That was not normal.")
	GameManager.stress += 3.0
	ObjectiveManager.complete_objective("fix_breakers")
	EventDirector.complete_event("zone_blackout")
