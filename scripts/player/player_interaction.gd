extends Node3D
## Player interaction system
## Handles raycast detection and interaction with objects

# ============================================================================
# SETTINGS
# ============================================================================

@export var interaction_range: float = 2.5
@export var interaction_layer: int = 4 # Interactables layer

# ============================================================================
# REFERENCES
# ============================================================================

@onready var raycast: RayCast3D = $../InteractionRayCast
@onready var prompt_ui: Label = get_node_or_null("/root/MainGame/UI/HUD/InteractionPrompt")

# ============================================================================
# STATE
# ============================================================================

var current_interactable: BaseInteractable = null
var is_interacting: bool = false

# ============================================================================
# PROCESS
# ============================================================================

func _ready() -> void:
	if raycast:
		raycast.target_position = Vector3(0, 0, -interaction_range)
		raycast.collision_mask = 1 << (interaction_layer - 1)

func _process(_delta: float) -> void:
	_check_for_interactable()
	_update_interaction_prompt()

	if Input.is_action_just_pressed("interact") and not is_interacting:
		_try_interact()

# ============================================================================
# INTERACTION DETECTION
# ============================================================================

func _check_for_interactable() -> void:
	"""Check if raycast is hitting an interactable object"""
	if not raycast or not raycast.is_colliding():
		current_interactable = null
		return

	var collider = raycast.get_collider()
	if collider and collider is BaseInteractable:
		if collider.can_interact():
			current_interactable = collider
		else:
			current_interactable = null
	else:
		# Check if collider has an interactable parent
		var parent = collider.get_parent() if collider else null
		if parent and parent is BaseInteractable and parent.can_interact():
			current_interactable = parent
		else:
			current_interactable = null

# ============================================================================
# INTERACTION
# ============================================================================

func _try_interact() -> void:
	"""Attempt to interact with current interactable"""
	if current_interactable:
		is_interacting = true
		await current_interactable.interact()
		is_interacting = false

		EventBus.object_interacted.emit(current_interactable.name)

# ============================================================================
# UI UPDATE
# ============================================================================

func _update_interaction_prompt() -> void:
	"""Update the interaction prompt UI"""
	if not prompt_ui:
		return

	if current_interactable:
		prompt_ui.text = "[E] " + current_interactable.interaction_prompt
		prompt_ui.visible = true
	else:
		prompt_ui.visible = false

# ============================================================================
# PUBLIC API
# ============================================================================

func force_interact_with(interactable: BaseInteractable) -> void:
	"""Force interaction with a specific object"""
	if interactable and interactable.can_interact():
		await interactable.interact()
