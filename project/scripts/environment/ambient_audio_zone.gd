## AmbientAudioZone - Triggers ambient audio when the player enters a zone.
## Attach to Area3D nodes to define audio regions.
class_name AmbientAudioZone
extends Area3D

# --- Exported Properties ---
@export var ambient_stream: AudioStream = null
@export var volume_db: float = -10.0
@export var fade_time: float = 1.5
@export var zone_name: String = "unnamed"

# --- Audio ---
var _audio_player: AudioStreamPlayer3D = null
var _is_player_inside: bool = false


func _ready() -> void:
	# Create audio player
	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.stream = ambient_stream
	_audio_player.volume_db = -80.0  # Start silent
	_audio_player.autoplay = false
	_audio_player.max_distance = 30.0
	_audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	add_child(_audio_player)

	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	add_to_group("audio_zones")


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body is CharacterBody3D:
		_is_player_inside = true
		_fade_in()


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") or body is CharacterBody3D:
		_is_player_inside = false
		_fade_out()


func _fade_in() -> void:
	if ambient_stream == null:
		return
	if not _audio_player.playing:
		_audio_player.play()
	var tween := create_tween()
	tween.tween_property(_audio_player, "volume_db", volume_db, fade_time)


func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(_audio_player, "volume_db", -80.0, fade_time)
	tween.tween_callback(func():
		if not _is_player_inside:
			_audio_player.stop()
	)
