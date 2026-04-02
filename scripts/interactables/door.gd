extends BaseInteractable
## Door interactable with lock mechanics

# ============================================================================
# CONFIGURATION
# ============================================================================

@export var is_locked: bool = false
@export var required_key: String = ""
@export var open_angle: float = 90.0
@export var open_speed: float = 2.0

# ============================================================================
# STATE
# ============================================================================

enum DoorState { CLOSED, OPENING, OPEN, CLOSING }
var current_state: DoorState = DoorState.CLOSED
var is_open: bool = false
var original_rotation: float = 0.0

# ============================================================================
# REFERENCES
# ============================================================================

@onready var door_mesh: Node3D = $DoorMesh
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	super._ready()
	if door_mesh:
		original_rotation = door_mesh.rotation.y

	if is_locked:
		interaction_prompt = "Locked"
		require_item = required_key

# ============================================================================
# INTERACTION
# ============================================================================

func _on_interact() -> void:
	if is_locked and not _has_key():
		_try_locked()
		return

	if is_open:
		_close_door()
	else:
		_open_door()

func _open_door() -> void:
	"""Open the door"""
	if current_state != DoorState.CLOSED:
		return

	current_state = DoorState.OPENING
	is_open = true

	AudioManager.play_sfx("door_open", global_position)

	if animation_player and animation_player.has_animation("open"):
		animation_player.play("open")
		await animation_player.animation_finished
	else:
		await _animate_door_rotation(open_angle)

	current_state = DoorState.OPEN

func _close_door() -> void:
	"""Close the door"""
	if current_state != DoorState.OPEN:
		return

	current_state = DoorState.CLOSING
	is_open = false

	AudioManager.play_sfx("door_close", global_position)

	if animation_player and animation_player.has_animation("close"):
		animation_player.play("close")
		await animation_player.animation_finished
	else:
		await _animate_door_rotation(0.0)

	current_state = DoorState.CLOSED

func _animate_door_rotation(target_angle: float) -> void:
	"""Animate door rotation"""
	if not door_mesh:
		return

	var start_rotation = door_mesh.rotation.y
	var target_rotation = original_rotation + deg_to_rad(target_angle)
	var time = 0.0
	var duration = 1.0 / open_speed

	while time < duration:
		time += get_process_delta_time()
		var t = time / duration
		door_mesh.rotation.y = lerp_angle(start_rotation, target_rotation, t)
		await get_tree().process_frame

	door_mesh.rotation.y = target_rotation

func _try_locked() -> void:
	"""Called when trying to open a locked door"""
	AudioManager.play_sfx("door_locked", global_position)

	# Shake door slightly
	if door_mesh:
		var original_pos = door_mesh.position
		var tween = create_tween()
		tween.tween_property(door_mesh, "position:x", original_pos.x + 0.02, 0.05)
		tween.tween_property(door_mesh, "position:x", original_pos.x - 0.02, 0.05)
		tween.tween_property(door_mesh, "position:x", original_pos.x, 0.05)

# ============================================================================
# LOCK MANAGEMENT
# ============================================================================

func unlock(key: String = "") -> bool:
	"""Unlock the door"""
	if key == "" or key == required_key:
		is_locked = false
		interaction_prompt = "Open"
		AudioManager.play_sfx("door_unlock", global_position)
		return true
	return false

func lock() -> void:
	"""Lock the door"""
	is_locked = true
	interaction_prompt = "Locked"
	if is_open:
		_close_door()

func _has_key() -> bool:
	"""Check if player has the required key"""
	if required_key == "":
		return true
	# Would check player inventory for key
	return _player_has_required_item()
