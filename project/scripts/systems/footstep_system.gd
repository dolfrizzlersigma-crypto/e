## FootstepSystem - Plays footstep sounds based on surface material.
## Detects floor type via raycast and plays appropriate audio.
class_name FootstepSystem
extends Node

# --- Signals ---
signal surface_changed(surface_type: String)

# --- Configuration ---
@export var step_interval_walk: float = 0.5
@export var step_interval_sprint: float = 0.35
@export var step_interval_crouch: float = 0.7

# --- State ---
var _step_timer: float = 0.0
var _current_surface: String = "concrete"
var _audio_player: AudioStreamPlayer3D = null
var _player_ref: PlayerController = null

# --- Procedural audio parameters per surface ---
var _surface_params: Dictionary = {
	"concrete": {"pitch_base": 0.8, "pitch_var": 0.1, "volume": -5.0},
	"linoleum": {"pitch_base": 1.0, "pitch_var": 0.08, "volume": -8.0},
	"carpet": {"pitch_base": 1.2, "pitch_var": 0.05, "volume": -12.0},
	"metal": {"pitch_base": 0.7, "pitch_var": 0.15, "volume": -3.0},
	"tile": {"pitch_base": 0.9, "pitch_var": 0.12, "volume": -4.0},
	"asphalt": {"pitch_base": 0.75, "pitch_var": 0.1, "volume": -6.0},
	"wood": {"pitch_base": 1.1, "pitch_var": 0.08, "volume": -7.0},
	"gravel": {"pitch_base": 0.6, "pitch_var": 0.2, "volume": -4.0},
	"dirt": {"pitch_base": 1.3, "pitch_var": 0.1, "volume": -10.0},
}


func _ready() -> void:
	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.max_distance = 20.0
	_audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	add_child(_audio_player)


## Initialize with a player reference.
func setup(player: PlayerController) -> void:
	_player_ref = player


func _process(delta: float) -> void:
	if _player_ref == null:
		return
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	# Determine movement state
	var speed := _player_ref.velocity.length()
	if speed < 0.5 or not _player_ref.is_on_floor():
		_step_timer = 0.0
		return

	# Determine step interval based on movement type
	var interval := step_interval_walk
	if _player_ref.is_sprinting:
		interval = step_interval_sprint
	elif _player_ref.is_crouching:
		interval = step_interval_crouch

	_step_timer += delta
	if _step_timer >= interval:
		_step_timer -= interval
		_detect_surface()
		_play_footstep()


## Detect what surface the player is standing on.
func _detect_surface() -> void:
	# Use floor collision info to determine surface
	if not _player_ref.is_on_floor():
		return

	# Simplified surface detection based on Y position and area
	var pos := _player_ref.global_position
	var new_surface := "concrete"

	# Interior shop area
	if pos.x > -6 and pos.x < 6 and pos.z > -7 and pos.z < 7:
		new_surface = "linoleum"
	# Motel lobby/hallway
	elif pos.x > 12 and pos.z < 0:
		new_surface = "carpet"
	# Bathroom
	elif pos.x < -7 and pos.z > 0 and pos.z < 5:
		new_surface = "tile"
	# Metal (maintenance shed, utility)
	elif pos.x < -12 and pos.z < -8:
		new_surface = "metal"
	# Basement
	elif pos.y < -0.5:
		new_surface = "concrete"
	# Outside asphalt
	elif pos.z > 8:
		new_surface = "asphalt"
	# Office
	elif pos.x > 6 and pos.z < -4:
		new_surface = "carpet"

	if new_surface != _current_surface:
		_current_surface = new_surface
		surface_changed.emit(_current_surface)


## Play a procedurally generated footstep sound.
func _play_footstep() -> void:
	var params: Dictionary = _surface_params.get(_current_surface, _surface_params["concrete"])

	# Generate a simple noise-based footstep using AudioStreamGenerator
	# For now, use pitch variation on a base click sound
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = 0.05

	_audio_player.stream = generator
	_audio_player.volume_db = params["volume"]
	_audio_player.pitch_scale = params["pitch_base"] + randf_range(-params["pitch_var"], params["pitch_var"])
	_audio_player.global_position = _player_ref.global_position
	_audio_player.play()

	# Fill with a short click/thud
	if _audio_player.has_stream_playback():
		var playback: AudioStreamGeneratorPlayback = _audio_player.get_stream_playback()
		if playback == null:
			return
		var frames := int(0.03 * 22050)  # 30ms footstep
		for i in range(frames):
			var t := float(i) / frames
			var envelope := (1.0 - t) * (1.0 - t)  # Quick decay
			var noise := randf_range(-1.0, 1.0) * envelope * 0.5
			# Add a thud component
			var thud := sin(t * 150.0) * envelope * 0.3
			playback.push_frame(Vector2(noise + thud, noise + thud))
