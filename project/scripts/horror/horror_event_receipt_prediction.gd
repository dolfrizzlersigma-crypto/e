## HorrorEventReceiptPrediction - The receipt printer outputs an order for someone not yet arrived.
## A customer matching the receipt appears minutes later.
class_name HorrorEventReceiptPrediction
extends Node

@export var prediction_lead_time: float = 120.0  # Seconds before customer arrives

var _is_active: bool = false
var _predicted_customer: Dictionary = {}
var _timer: float = 0.0
var _receipt_printed: bool = false


## Trigger the receipt prediction event.
func trigger() -> void:
	_is_active = true
	_receipt_printed = false
	_timer = prediction_lead_time

	# Generate the predicted customer
	_predicted_customer = {
		"name": ["Sarah Oakes", "Dale Vickers", "Fiona Grant", "Pete Nolan"][randi() % 4],
		"items": [["coffee_large", "aspirin"], ["gas", "water"], ["sandwich", "energy_drink"]][randi() % 3],
	}

	# Print the receipt
	_print_prediction_receipt()
	GameManager.stress += 8.0
	GameManager.collect_evidence("receipt_prediction_shift_%d" % GameManager.current_shift)


func _process(delta: float) -> void:
	if not _is_active:
		return

	_timer -= delta

	# When time is up, spawn the matching customer
	if _timer <= 0.0:
		_spawn_predicted_customer()
		_is_active = false
		EventDirector.complete_event("receipt_prediction")


func _print_prediction_receipt() -> void:
	var items_text := ""
	for item_id in _predicted_customer["items"]:
		items_text += "  " + item_id + "\n"

	var receipt_text := "--- EXIT 13 ---\n"
	receipt_text += "Customer: %s\n" % _predicted_customer["name"]
	receipt_text += "Items:\n%s" % items_text
	receipt_text += "Time: ???\n"
	receipt_text += "--- THANK YOU ---"

	DialogueManager.show_subtitle("", "[The receipt printer activates on its own]")
	# Short delay then show the receipt content
	get_tree().create_timer(2.0).timeout.connect(func():
		DialogueManager.show_subtitle("Mara",
			"This receipt... '%s'? Nobody ordered this. Nobody's even here." % _predicted_customer["name"])
	)
	_receipt_printed = true


func _spawn_predicted_customer() -> void:
	# Find shift manager and spawn the customer
	var shift_managers := get_tree().get_nodes_in_group("shift_manager")
	if shift_managers.size() > 0:
		var sm: ShiftManager = shift_managers[0]
		var customer := sm.spawn_customer()
		customer["name"] = _predicted_customer["name"]
		customer["items"] = _predicted_customer["items"]
		customer["is_predicted"] = true

	DialogueManager.show_subtitle("Mara",
		"Wait... that's the name from the receipt. %s just walked in." % _predicted_customer["name"])
	GameManager.stress += 12.0
	GameManager.composure -= 5.0
