## HorrorEventRoom4 - The sealed room opens on its own.
## A major story-tied horror event that occurs in later shifts.
class_name HorrorEventRoom4
extends Node

var is_active: bool = false
var phase: int = 0
var elapsed: float = 0.0


func trigger() -> void:
	is_active = true
	phase = 0
	elapsed = 0.0

	EventDirector.horror_intensity += 0.25
	GameManager.stress += 10.0

	_phase_0_discovery()


func _process(delta: float) -> void:
	if not is_active:
		return
	elapsed += delta


func _phase_0_discovery() -> void:
	DialogueManager.show_subtitle("", "[A sound from the motel hallway. Wood cracking. Nails pulling free.]")

	var timer := get_tree().create_timer(4.0)
	timer.timeout.connect(_phase_1_approach)


func _phase_1_approach() -> void:
	phase = 1
	DialogueManager.show_subtitle("", "[The boards on Room 4 are on the floor. The door is ajar. A faint light glows from inside.]")
	GameManager.stress += 10.0

	var timer := get_tree().create_timer(6.0)
	timer.timeout.connect(_phase_2_interior)


func _phase_2_interior() -> void:
	phase = 2

	# Check if player is near motel
	DialogueManager.show_subtitle("Mara", "Room 4 is open. It shouldn't be open. It CAN'T be open.")

	var timer := get_tree().create_timer(5.0)
	timer.timeout.connect(_phase_3_reveal)


func _phase_3_reveal() -> void:
	phase = 3

	# What's inside depends on the shift
	var shift := GameManager.current_shift
	if shift >= 9:
		# Late game - the highway vision
		DialogueManager.show_subtitle("", "[Inside Room 4: not a room. A stretch of highway at night. Rain on asphalt. Headlights in the distance.]")
		GameManager.stress += 20.0
		GameManager.composure -= 20.0
		GameManager.set_story_flag("room4_highway_vision")
	elif shift >= 7:
		# Mid-late game - the guest ledger
		DialogueManager.show_subtitle("", "[Inside Room 4: a desk covered in guest ledgers. Decades of names. All the same names. Over and over.]")
		GameManager.stress += 15.0
		GameManager.collect_evidence("room4_ledgers")
	else:
		# Earlier - just cold and wrong
		DialogueManager.show_subtitle("", "[Inside Room 4: empty. Immaculately clean. As if someone just checked out. The bed is made. A key sits on the nightstand.]")
		GameManager.stress += 8.0

	var timer := get_tree().create_timer(8.0)
	timer.timeout.connect(_end_event)


func _end_event() -> void:
	is_active = false
	phase = 0

	DialogueManager.show_subtitle("", "[Room 4's door slowly swings shut. Click.]")
	GameManager.set_story_flag("room4_opened")
