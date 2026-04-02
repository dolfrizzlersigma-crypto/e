## DoorSystem - Handles doors, locks, and key-based access throughout the plaza.
## Supports locked/unlocked states, key requirements, and horror lock manipulation.
class_name DoorSystem
extends Interactable

# --- Signals ---
signal door_opened(door_id: String)
signal door_closed(door_id: String)
signal door_locked(door_id: String)
signal door_unlocked(door_id: String)
signal access_denied(door_id: String, reason: String)

# --- Exported Properties ---
@export var door_id: String = "door_unnamed"
@export var is_locked: bool = false
@export var required_key: String = ""  # Key item ID needed to unlock
@export var auto_close_delay: float = 5.0  # 0 = no auto close
@export var is_one_way: bool = false

@export_group("Audio")
@export var open_sound: AudioStream = null
@export var close_sound: AudioStream = null
@export var lock_sound: AudioStream = null
@export var rattle_sound: AudioStream = null  # Trying locked door

@export_group("Animation")
@export var open_angle: float = 90.0
@export var open_speed: float = 2.0

# --- State ---
var is_open: bool = false
var _auto_close_timer: float = 0.0
var _target_rotation: float = 0.0
var _initial_rotation: float = 0.0


func _ready() -> void:
	super._ready()
	_initial_rotation = rotation_degrees.y
	interaction_prompt = "Open" if not is_locked else "Locked"
	collision_layer = 16  # Layer 5 (Doors)
	add_to_group("doors")


func _process(delta: float) -> void:
	# Smooth door rotation
	if absf(rotation_degrees.y - _target_rotation) > 0.5:
		rotation_degrees.y = lerpf(rotation_degrees.y, _target_rotation, open_speed * delta)

	# Auto-close timer
	if is_open and auto_close_delay > 0:
		_auto_close_timer -= delta
		if _auto_close_timer <= 0:
			close_door()


## Override interaction.
func _on_interact(player: Node) -> void:
	if is_locked:
		_try_unlock(player)
		return

	if is_open:
		close_door()
	else:
		open_door(player)


## Open the door.
func open_door(player: Node = null) -> void:
	if is_open or is_locked:
		return

	is_open = true
	_auto_close_timer = auto_close_delay

	# Determine open direction based on player position
	var open_dir := 1.0
	if player:
		var to_player := player.global_position - global_position
		var door_forward := global_transform.basis.z
		if to_player.dot(door_forward) < 0:
			open_dir = -1.0

	_target_rotation = _initial_rotation + open_angle * open_dir
	interaction_prompt = "Close"

	if open_sound:
		AudioManager.play_sfx(open_sound)

	door_opened.emit(door_id)


## Close the door.
func close_door() -> void:
	if not is_open:
		return

	is_open = false
	_target_rotation = _initial_rotation
	interaction_prompt = "Open" if not is_locked else "Locked"

	if close_sound:
		AudioManager.play_sfx(close_sound)

	door_closed.emit(door_id)


## Lock the door.
func lock() -> void:
	is_locked = true
	if is_open:
		close_door()
	interaction_prompt = "Locked"
	if lock_sound:
		AudioManager.play_sfx(lock_sound)
	door_locked.emit(door_id)


## Unlock the door.
func unlock() -> void:
	is_locked = false
	interaction_prompt = "Open"
	if lock_sound:
		AudioManager.play_sfx(lock_sound)
	door_unlocked.emit(door_id)


# --- Private ---

func _try_unlock(player: Node) -> void:
	if required_key == "":
		# No key required, just locked for story reasons
		access_denied.emit(door_id, "This door is locked.")
		if rattle_sound:
			AudioManager.play_sfx(rattle_sound)
		DialogueManager.show_subtitle("Mara", "Locked. I can't get through.")
		return

	# Check if player has the required key
	if _player_has_item(player, required_key):
		unlock()
		open_door(player)
		DialogueManager.show_subtitle("Mara", "Got it.")
	else:
		access_denied.emit(door_id, "Requires: " + required_key)
		if rattle_sound:
			AudioManager.play_sfx(rattle_sound)
		DialogueManager.show_subtitle("Mara", "I need the right key for this.")
