extends Node
## Audio management system
## Handles music, ambience, SFX, and spatial audio

# ============================================================================
# AUDIO PLAYERS
# ============================================================================

var music_player: AudioStreamPlayer
var ambience_players: Dictionary = {}
var sfx_pool: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE: int = 16

# ============================================================================
# CURRENT STATE
# ============================================================================

var current_ambience_zone: String = ""
var horror_intensity: float = 0.0
var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 1.0
var ambience_volume: float = 0.8

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	_setup_audio_players()
	_setup_audio_buses()
	print("AudioManager initialized")

func _setup_audio_players() -> void:
	"""Initialize audio players"""
	# Music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

	# SFX pool
	for i in range(SFX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_pool.append(player)

func _setup_audio_buses() -> void:
	"""Set up audio bus volumes"""
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("SFX", sfx_volume)
	_set_bus_volume("Ambience", ambience_volume)

# ============================================================================
# MUSIC
# ============================================================================

func play_music(music_path: String, fade_in: float = 1.0) -> void:
	"""Play music with optional fade in"""
	var stream = load(music_path)
	if stream == null:
		push_error("Failed to load music: %s" % music_path)
		return

	if fade_in > 0.0:
		music_player.volume_db = -80
		music_player.stream = stream
		music_player.play()

		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", 0.0, fade_in)
	else:
		music_player.stream = stream
		music_player.volume_db = 0.0
		music_player.play()

func stop_music(fade_out: float = 1.0) -> void:
	"""Stop music with optional fade out"""
	if not music_player.playing:
		return

	if fade_out > 0.0:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, fade_out)
		tween.tween_callback(music_player.stop)
	else:
		music_player.stop()

# ============================================================================
# SFX
# ============================================================================

func play_sfx(sound_name: String, position: Vector3 = Vector3.ZERO, pitch_variation: float = 0.0) -> void:
	"""Play a sound effect"""
	var sound_path = "res://assets/audio/effects/" + sound_name + ".ogg"

	# Check if file exists (in real implementation)
	# For now, just attempt to load
	var stream = load(sound_path) if ResourceLoader.exists(sound_path) else null
	if stream == null:
		# Fallback or skip
		return

	var player = _get_available_sfx_player()
	if player == null:
		return

	player.stream = stream
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.play()

func _get_available_sfx_player() -> AudioStreamPlayer:
	"""Get an available SFX player from the pool"""
	for player in sfx_pool:
		if not player.playing:
			return player
	return sfx_pool[0] # Reuse first player if all busy

# ============================================================================
# AMBIENCE
# ============================================================================

func set_ambience_zone(zone_name: String) -> void:
	"""Change the current ambience zone"""
	if current_ambience_zone == zone_name:
		return

	current_ambience_zone = zone_name
	_update_ambience()

func _update_ambience() -> void:
	"""Update ambience based on current zone"""
	# Implementation would load and play ambience for the zone
	# For now, just log
	print("Ambience zone changed to: %s" % current_ambience_zone)

# ============================================================================
# HORROR AUDIO
# ============================================================================

func adjust_horror_mix(intensity: float) -> void:
	"""Adjust audio mix based on horror intensity"""
	horror_intensity = clamp(intensity, 0.0, 1.0)

	# Increase ambience volume and add distortion at high intensity
	var ambience_boost = 1.0 + (horror_intensity * 0.3)
	_set_bus_volume("Ambience", ambience_volume * ambience_boost)

func play_horror_stinger(stinger_type: String) -> void:
	"""Play a horror stinger sound"""
	var stinger_path = "res://assets/audio/horror/stingers/" + stinger_type + ".ogg"
	play_sfx(stinger_path)

# ============================================================================
# RADIO/PHONE
# ============================================================================

func play_radio_call(audio_path: String) -> void:
	"""Play a radio call with appropriate filtering"""
	# Would apply radio filter effect
	play_sfx(audio_path)

func play_phone_ring() -> void:
	"""Play phone ring sound"""
	play_sfx("phone_ring")

# ============================================================================
# VOLUME CONTROL
# ============================================================================

func set_master_volume(volume: float) -> void:
	"""Set master volume (0.0 to 1.0)"""
	master_volume = clamp(volume, 0.0, 1.0)
	_set_bus_volume("Master", master_volume)

func set_music_volume(volume: float) -> void:
	"""Set music volume (0.0 to 1.0)"""
	music_volume = clamp(volume, 0.0, 1.0)
	_set_bus_volume("Music", music_volume)

func set_sfx_volume(volume: float) -> void:
	"""Set SFX volume (0.0 to 1.0)"""
	sfx_volume = clamp(volume, 0.0, 1.0)
	_set_bus_volume("SFX", sfx_volume)

func set_ambience_volume(volume: float) -> void:
	"""Set ambience volume (0.0 to 1.0)"""
	ambience_volume = clamp(volume, 0.0, 1.0)
	_set_bus_volume("Ambience", ambience_volume)

func _set_bus_volume(bus_name: String, volume: float) -> void:
	"""Set audio bus volume"""
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		var db = linear_to_db(volume)
		AudioServer.set_bus_volume_db(bus_idx, db)

# ============================================================================
# UTILITY
# ============================================================================

func linear_to_db(linear: float) -> float:
	"""Convert linear volume to decibels"""
	if linear <= 0.0:
		return -80.0
	return 20.0 * log(linear) / log(10.0)
