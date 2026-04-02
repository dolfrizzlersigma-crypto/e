## Interactable - Base class for all interactable objects in the game.
## Provides highlighting, interaction prompts, and base interaction logic.
class_name Interactable
extends StaticBody3D

# --- Signals ---
signal on_interacted(player: Node)
signal on_highlighted()
signal on_unhighlighted()

# --- Exported Properties ---
@export var interaction_prompt: String = "Interact"
@export var requires_item: String = ""  # Item ID required to interact
@export var is_enabled: bool = true
@export var interaction_sound: AudioStream = null
@export var one_shot: bool = false  # If true, can only be used once

# --- State ---
var _is_highlighted: bool = false
var _has_been_used: bool = false
var _original_materials: Dictionary = {}  # mesh_path -> material


func _ready() -> void:
	# Set collision layer to interactables
	collision_layer = 4  # Layer 3 (Interactables)
	collision_mask = 0
	add_to_group("interactables")


## Called when the player interacts with this object.
func interact(player: Node) -> void:
	if not is_enabled:
		return
	if one_shot and _has_been_used:
		return
	if requires_item != "" and not _player_has_item(player, requires_item):
		DialogueManager.show_subtitle("Mara", "I need something for this...")
		return

	_has_been_used = true

	if interaction_sound:
		AudioManager.play_sfx(interaction_sound)

	on_interacted.emit(player)
	_on_interact(player)


## Override this in subclasses for custom interaction behavior.
func _on_interact(_player: Node) -> void:
	pass


## Set the highlight state for this object.
func set_highlighted(highlighted: bool) -> void:
	if _is_highlighted == highlighted:
		return
	_is_highlighted = highlighted
	if highlighted:
		_apply_highlight()
		on_highlighted.emit()
	else:
		_remove_highlight()
		on_unhighlighted.emit()


## Get the interaction prompt text.
func get_prompt() -> String:
	if not is_enabled:
		return ""
	if one_shot and _has_been_used:
		return ""
	return interaction_prompt


# --- Private ---

func _apply_highlight() -> void:
	# Apply outline/emission to all mesh children
	for child in _get_mesh_instances():
		var mesh_instance: MeshInstance3D = child
		for i in mesh_instance.get_surface_override_material_count():
			var mat := mesh_instance.get_surface_override_material(i)
			if mat == null:
				mat = mesh_instance.mesh.surface_get_material(i)
			if mat and mat is StandardMaterial3D:
				var key := mesh_instance.get_path().get_concatenated_names() + str(i)
				if not _original_materials.has(key):
					_original_materials[key] = mat
				var highlight_mat: StandardMaterial3D = mat.duplicate()
				highlight_mat.emission_enabled = true
				highlight_mat.emission = Color(0.3, 0.4, 0.5)
				highlight_mat.emission_energy_multiplier = 0.3
				mesh_instance.set_surface_override_material(i, highlight_mat)


func _remove_highlight() -> void:
	for child in _get_mesh_instances():
		var mesh_instance: MeshInstance3D = child
		for i in mesh_instance.get_surface_override_material_count():
			var key := mesh_instance.get_path().get_concatenated_names() + str(i)
			if _original_materials.has(key):
				mesh_instance.set_surface_override_material(i, _original_materials[key])
	_original_materials.clear()


func _get_mesh_instances() -> Array[Node]:
	var meshes: Array[Node] = []
	_find_mesh_instances(self, meshes)
	return meshes


func _find_mesh_instances(node: Node, result: Array[Node]) -> void:
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		_find_mesh_instances(child, result)


func _player_has_item(player: Node, item_id: String) -> bool:
	if player.has_method("has_item"):
		return player.has_item(item_id)
	return false
