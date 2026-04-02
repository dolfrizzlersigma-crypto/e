## HorrorEventRadioVoice - Plays dispatch recordings and supernatural radio messages.
## The radio becomes increasingly personal and revealing as the story progresses.
class_name HorrorEventRadioVoice
extends Node

var is_active: bool = false
var elapsed: float = 0.0
var duration: float = 30.0
var _message_queue: Array[Dictionary] = []
var _current_message_index: int = 0
var _message_timer: float = 0.0

# Radio messages categorized by shift progression
var _early_messages: Array[Dictionary] = [
	{"speaker": "Radio", "text": "[static] ...requesting assistance... vehicle... Mile 87... [static]", "delay": 3.0},
	{"speaker": "Radio", "text": "[static] ...road conditions deteriorating... all units... [static]", "delay": 5.0},
	{"speaker": "Radio", "text": "[static] ...nearest service... Exit 13... [static]", "delay": 4.0},
]

var _mid_messages: Array[Dictionary] = [
	{"speaker": "Radio", "text": "[static] ...eleven casualties confirmed... [static]", "delay": 3.0},
	{"speaker": "Radio", "text": "[static] ...some vehicles unrecovered... still searching... [static]", "delay": 5.0},
	{"speaker": "Radio", "text": "[clearer] Room 4 is ready. [static]", "delay": 4.0},
	{"speaker": "Radio", "text": "[static] ...dispatcher on duty... M. Velez... do you copy? [static]", "delay": 6.0},
]

var _late_messages: Array[Dictionary] = [
	{"speaker": "Radio Voice", "text": "Mara. You're listening.", "delay": 3.0},
	{"speaker": "Radio Voice", "text": "The highway remembers. Exit 13 remembers. Do you?", "delay": 5.0},
	{"speaker": "Radio Voice", "text": "Check the guest ledger. Count the names. Then count them again.", "delay": 5.0},
	{"speaker": "Radio Voice", "text": "They keep arriving because someone keeps the lights on.", "delay": 4.0},
	{"speaker": "Radio Voice", "text": "The question isn't whether they're real. The question is whether you are.", "delay": 6.0},
]

var _finale_messages: Array[Dictionary] = [
	{"speaker": "Radio Voice", "text": "It's almost over, Mara. One way or another.", "delay": 3.0},
	{"speaker": "Radio Voice", "text": "The loop can be broken. But someone has to walk into Room 4.", "delay": 5.0},
	{"speaker": "Radio Voice", "text": "Not through the door. Through the memory.", "delay": 4.0},
	{"speaker": "Radio Voice", "text": "You were there, Mara. At Mile 87. Not just on the radio.", "delay": 5.0},
	{"speaker": "Radio Voice", "text": "Remember.", "delay": 3.0},
]


func trigger() -> void:
	is_active = true
	elapsed = 0.0
	_current_message_index = 0
	_message_timer = 0.0

	# Select messages based on story progression
	var shift := GameManager.current_shift
	if shift <= 3:
		_message_queue = _early_messages.duplicate()
	elif shift <= 6:
		_message_queue = _mid_messages.duplicate()
	elif shift <= 8:
		_message_queue = _late_messages.duplicate()
	else:
		_message_queue = _finale_messages.duplicate()

	duration = 0.0
	for msg in _message_queue:
		duration += msg.get("delay", 4.0) + 3.0  # message display time + delay

	GameManager.stress += 8.0
	EventDirector.horror_intensity += 0.15

	# Start static
	DialogueManager.show_subtitle("", "[The radio crackles to life]")


func _process(delta: float) -> void:
	if not is_active:
		return

	elapsed += delta
	_message_timer -= delta

	if _message_timer <= 0 and _current_message_index < _message_queue.size():
		var msg := _message_queue[_current_message_index]
		DialogueManager.show_subtitle(msg["speaker"], msg["text"])
		_message_timer = msg.get("delay", 4.0) + 3.0
		_current_message_index += 1

		# Increase stress per message
		GameManager.stress += 3.0

	if _current_message_index >= _message_queue.size() and _message_timer <= 0:
		_end_event()


func _end_event() -> void:
	is_active = false
	DialogueManager.show_subtitle("", "[The radio falls silent]")
	GameManager.set_story_flag("radio_event_shift_%d" % GameManager.current_shift)
