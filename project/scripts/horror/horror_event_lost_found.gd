## HorrorEventLostAndFound - The lost-and-found box fills with items from Mile 87.
## A creeping horror event that builds over multiple observations.
class_name HorrorEventLostAndFound
extends Node

var is_active: bool = false
var items_revealed: int = 0

var _pileup_items: Array[String] = [
	"A child's shoe, slightly scorched",
	"A cracked pair of glasses with prescription lenses",
	"A wedding ring engraved 'Always - 1987'",
	"Car keys for a vehicle not in the lot",
	"A hospital bracelet: 'Martinez, R. - Admitted 10/13'",
	"A wallet with an expired license - photo matches a current guest",
	"A cassette tape labeled 'Highway Drive Mix'",
	"A gas station receipt from Exit 13 dated three years ago",
	"A dispatch radio, still warm",
	"A name badge: 'Mara Velez - Emergency Dispatch'",
]


func trigger() -> void:
	is_active = true
	items_revealed = 0

	DialogueManager.show_subtitle("", "[The lost-and-found box behind the counter feels heavier than before]")
	GameManager.stress += 5.0

	# Reveal items over time
	_reveal_next_item()


func _reveal_next_item() -> void:
	if items_revealed >= _pileup_items.size() or not is_active:
		_end_event()
		return

	var item := _pileup_items[items_revealed]
	items_revealed += 1

	DialogueManager.show_subtitle("", "[In the box: %s]" % item)
	GameManager.stress += 3.0

	# Last item is the most disturbing
	if items_revealed == _pileup_items.size():
		GameManager.stress += 15.0
		GameManager.composure -= 15.0
		GameManager.add_evidence("lost_found_dispatch_radio")
		GameManager.set_story_flag("lost_found_complete")

		var timer := get_tree().create_timer(5.0)
		timer.timeout.connect(func():
			DialogueManager.show_subtitle("Mara", "That's my old name badge. From dispatch. How is this here?")
			_end_event()
		)
		return

	# Reveal more based on player proximity (simplified: time-based)
	var delay := randf_range(15.0, 30.0)
	var timer := get_tree().create_timer(delay)
	timer.timeout.connect(_reveal_next_item)


func _end_event() -> void:
	is_active = false
	EventDirector.horror_intensity += 0.2
