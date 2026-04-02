## NPC Customer - Represents a customer NPC that visits the service plaza.
## Handles movement, dialogue, purchasing, and motel check-in behavior.
class_name NPCCustomer
extends CharacterBody3D

# --- Signals ---
signal customer_arrived(customer_data: Dictionary)
signal customer_served()
signal customer_left()
signal customer_complained(reason: String)

# --- Exported Properties ---
@export var move_speed: float = 2.0
@export var wait_patience: float = 60.0  # Seconds before leaving/complaining

# --- State ---
var customer_data: Dictionary = {}
var current_state: CustomerState = CustomerState.ARRIVING
var wait_timer: float = 0.0
var target_position: Vector3 = Vector3.ZERO
var has_been_served: bool = false
var is_anomaly: bool = false

enum CustomerState { ARRIVING, WAITING, BEING_SERVED, LEAVING, IDLE }


func _ready() -> void:
	add_to_group("customers")
	add_to_group("npcs")
	collision_layer = 8  # Layer 4 (NPCs)


func _physics_process(delta: float) -> void:
	match current_state:
		CustomerState.ARRIVING:
			_move_toward_target(delta)
		CustomerState.WAITING:
			_update_waiting(delta)
		CustomerState.LEAVING:
			_move_toward_target(delta)
		_:
			pass


## Initialize this customer with data from ShiftManager.
func setup(data: Dictionary) -> void:
	customer_data = data
	is_anomaly = data.get("is_anomaly", false)
	customer_arrived.emit(customer_data)


## Set destination and start moving.
func go_to(pos: Vector3) -> void:
	target_position = pos
	current_state = CustomerState.ARRIVING


## Called when the customer reaches the counter.
func arrive_at_counter() -> void:
	current_state = CustomerState.WAITING
	wait_timer = wait_patience
	# Start dialogue
	var dialogue_text: String = customer_data.get("dialogue", "...")
	DialogueManager.show_subtitle(customer_data.get("name", "Customer"), dialogue_text)


## Serve this customer (process their items).
func serve() -> void:
	has_been_served = true
	current_state = CustomerState.BEING_SERVED
	customer_served.emit()

	# After being served, leave after a short delay
	get_tree().create_timer(3.0).timeout.connect(func():
		leave()
	)


## Make the customer leave.
func leave() -> void:
	current_state = CustomerState.LEAVING
	# Set target to exit point
	target_position = Vector3(0, 0, 50)  # Off-screen
	customer_left.emit()

	# Destroy after reaching exit
	get_tree().create_timer(15.0).timeout.connect(func():
		queue_free()
	)


## Get the items this customer wants to purchase.
func get_purchase_items() -> Array:
	return customer_data.get("items", [])


## Check if this customer wants a motel room.
func wants_room() -> bool:
	return customer_data.get("wants_room", false)


## Interact with this NPC.
func interact(player: Node) -> void:
	if current_state == CustomerState.WAITING and not has_been_served:
		# Show full dialogue
		var name_str: String = customer_data.get("name", "Customer")
		var dialogue_text: String = customer_data.get("dialogue", "...")
		DialogueManager.show_subtitle(name_str, dialogue_text)

		# If anomaly customer, trigger special behavior
		if is_anomaly:
			_handle_anomaly_interaction(player)


func set_highlighted(highlighted: bool) -> void:
	# Visual feedback for NPC highlighting
	pass


# --- Private ---

func _move_toward_target(delta: float) -> void:
	var direction := (target_position - global_position).normalized()
	direction.y = 0
	if global_position.distance_to(target_position) > 1.0:
		velocity = direction * move_speed
	else:
		velocity = Vector3.ZERO
		if current_state == CustomerState.ARRIVING:
			arrive_at_counter()
		elif current_state == CustomerState.LEAVING:
			queue_free()
	move_and_slide()


func _update_waiting(delta: float) -> void:
	wait_timer -= delta
	if wait_timer <= 0.0 and not has_been_served:
		# Customer gets impatient
		customer_complained.emit("Waited too long")
		GameManager.reputation -= 3.0
		leave()


func _handle_anomaly_interaction(player: Node) -> void:
	GameManager.stress += 10.0
	# Check for specific anomaly types
	if customer_data.get("dialogue", "").find("room 4") >= 0:
		GameManager.collect_evidence("anomaly_room4_request_shift_%d" % GameManager.current_shift)
	elif customer_data.get("dialogue", "").find("mile 87") >= 0:
		GameManager.collect_evidence("anomaly_mile87_mention_shift_%d" % GameManager.current_shift)
