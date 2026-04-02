## HorrorEventMassArrival - All guests from Mile 87 arrive simultaneously.
## A climactic horror event for the final shifts.
class_name HorrorEventMassArrival
extends Node

var is_active: bool = false
var arrival_count: int = 0
var max_arrivals: int = 11  # The number of casualties from Mile 87
var _arrival_timer: float = 0.0
var _arrival_interval: float = 8.0

var _ghost_guests: Array[Dictionary] = [
	{"name": "R. Martinez", "room": 1, "request": "Just need a room for the night. Long drive."},
	{"name": "L. Chen", "room": 2, "request": "Is Room 4 available? No? Fine. Anything."},
	{"name": "D. Okafor", "room": 3, "request": "My car broke down. Again. It keeps breaking down here."},
	{"name": "T. Walsh", "room": 5, "request": "I've been driving for... how long have I been driving?"},
	{"name": "K. Johansson", "room": 6, "request": "I think I've been here before. Everything looks familiar."},
	{"name": "M. Reyes", "room": -1, "request": "I don't need a room. I just need to use the phone. Do you have a phone?"},
	{"name": "S. Park", "room": -1, "request": "Twenty on pump three. And... what day is it? What year?"},
	{"name": "A. Volkov", "room": -1, "request": "Coffee. Black. I can't seem to stay awake. The road just keeps going."},
	{"name": "J. Baptiste", "room": -1, "request": "Have you seen my daughter? She was in the car. She was right behind me."},
	{"name": "F. Nakamura", "room": -1, "request": "I remember the exit sign. Exit 13. That's the last thing I remember."},
	{"name": "C. Torres", "room": -1, "request": "You're Mara, aren't you? You were on the radio that night. We heard your voice."},
]


func trigger() -> void:
	is_active = true
	arrival_count = 0
	_arrival_timer = 0.0

	GameManager.stress += 15.0
	EventDirector.horror_intensity = 0.9

	DialogueManager.show_subtitle("", "[Headlights. One pair after another. Lining up on the highway. All turning into Exit 13.]")

	var timer := get_tree().create_timer(5.0)
	timer.timeout.connect(_begin_arrivals)


func _process(delta: float) -> void:
	if not is_active:
		return

	_arrival_timer -= delta
	if _arrival_timer <= 0 and arrival_count < max_arrivals:
		_next_arrival()
		_arrival_timer = _arrival_interval


func _begin_arrivals() -> void:
	DialogueManager.show_subtitle("Mara", "They're all coming. All of them. All at once.")
	_arrival_timer = 0.0  # Trigger first arrival immediately


func _next_arrival() -> void:
	if arrival_count >= _ghost_guests.size():
		_end_event()
		return

	var guest := _ghost_guests[arrival_count]
	arrival_count += 1

	# Show arrival
	DialogueManager.show_subtitle(guest["name"], guest["request"])
	GameManager.stress += 5.0

	# The last guest is the most impactful
	if arrival_count == max_arrivals:
		GameManager.stress += 20.0
		GameManager.composure -= 25.0
		GameManager.set_story_flag("mass_arrival_complete")

		var timer := get_tree().create_timer(5.0)
		timer.timeout.connect(func():
			DialogueManager.show_subtitle("Mara", "Eleven. Eleven people. The same number as the pileup.")
			var timer2 := get_tree().create_timer(4.0)
			timer2.timeout.connect(func():
				DialogueManager.show_subtitle("Mara", "They know my name. They heard my voice on the radio when they... when it happened.")
				_end_event()
			)
		)


func _end_event() -> void:
	is_active = false
	GameManager.set_story_flag("mass_arrival_witnessed")
