extends Node3D
class_name BaseInteractable
## Base class for all interactable objects in the game

# ============================================================================
# CONFIGURATION
# ============================================================================

@export var interaction_prompt: String = "Interact"
@export var require_item: String = ""
@export var one_time_use: bool = false
@export var enabled: bool = true

# ============================================================================
# STATE
# ============================================================================

var has_been_used: bool = false
var is_highlighted: bool = false

# ============================================================================
# CORE METHODS
# ============================================================================

func can_interact() -> bool:
	"""Check if this object can currently be interacted with"""
	if not enabled:
		return false
	if one_time_use and has_been_used:
		return false
	if require_item != "" and not _player_has_required_item():
		return false
	return true

func interact() -> void:
	"""Called when player interacts with this object"""
	if not can_interact():
		return

	_on_interact()
	has_been_used = true

	AudioManager.play_sfx("interact_generic", global_position)

func _on_interact() -> void:
	"""Override this in derived classes"""
	pass

# ============================================================================
# HIGHLIGHTING
# ============================================================================

func set_highlighted(highlighted: bool) -> void:
	"""Set whether this object is highlighted"""
	if is_highlighted == highlighted:
		return

	is_highlighted = highlighted
	_update_highlight()

func _update_highlight() -> void:
	"""Update visual highlight - override in derived classes"""
	pass

# ============================================================================
# UTILITY
# ============================================================================

func _player_has_required_item() -> bool:
	"""Check if player has the required item"""
	# Would check player inventory
	return true

func disable() -> void:
	"""Disable this interactable"""
	enabled = false

func enable() -> void:
	"""Enable this interactable"""
	enabled = true
