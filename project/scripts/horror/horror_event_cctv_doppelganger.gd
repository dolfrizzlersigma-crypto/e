## HorrorEventCCTVDoppelganger - Shows the player's doppelganger on CCTV.
## One of the most unsettling events - the CCTV shows Mara behind the counter
## while the player is standing elsewhere.
class_name HorrorEventCCTVDoppelganger
extends Node

var is_active: bool = false
var duration: float = 20.0
var elapsed: float = 0.0
var _affected_camera_id: int = -1


func trigger() -> void:
	is_active = true
	elapsed = 0.0

	# Find the shop counter camera
	var cctv := _get_cctv_system()
	if cctv == null:
		_fallback_trigger()
		return

	# Corrupt a camera feed to show doppelganger
	_affected_camera_id = 0  # Camera 0 = shop counter
	cctv.inject_anomaly(_affected_camera_id, "doppelganger")

	GameManager.stress += 15.0
	GameManager.composure -= 10.0
	EventDirector.horror_intensity += 0.3

	DialogueManager.show_subtitle("", "[The security monitor flickers. You see yourself standing behind the counter.]")

	# Schedule follow-up
	var timer := get_tree().create_timer(5.0)
	timer.timeout.connect(_doppelganger_update)


func _process(delta: float) -> void:
	if not is_active:
		return

	elapsed += delta
	if elapsed >= duration:
		_end_event()


func _doppelganger_update() -> void:
	if not is_active:
		return

	DialogueManager.show_subtitle("Mara", "That's... that's me. On the camera. But I'm standing right here.")

	GameManager.stress += 10.0

	# Second update after more time
	var timer := get_tree().create_timer(8.0)
	timer.timeout.connect(func():
		if is_active:
			DialogueManager.show_subtitle("", "[The figure on the monitor slowly turns to look at the camera.]")
			GameManager.stress += 15.0
			GameManager.composure -= 15.0
	)


func _end_event() -> void:
	is_active = false

	# Clear the anomaly
	var cctv := _get_cctv_system()
	if cctv and _affected_camera_id >= 0:
		cctv.clear_anomaly(_affected_camera_id)

	DialogueManager.show_subtitle("", "[The monitor returns to normal. The counter is empty.]")


func _fallback_trigger() -> void:
	# If no CCTV system available, still create the horror through dialogue
	DialogueManager.show_subtitle("", "[You catch your reflection in the dark store window. It doesn't move when you do.]")
	GameManager.stress += 12.0
	GameManager.composure -= 8.0

	var timer := get_tree().create_timer(5.0)
	timer.timeout.connect(func():
		DialogueManager.show_subtitle("Mara", "...Did my reflection just—")
		var timer2 := get_tree().create_timer(3.0)
		timer2.timeout.connect(func():
			DialogueManager.show_subtitle("", "[The reflection is normal now. Probably.]")
			is_active = false
		)
	)


func _get_cctv_system() -> Node:
	var systems := get_tree().get_nodes_in_group("cctv_system")
	return systems[0] if systems.size() > 0 else null
