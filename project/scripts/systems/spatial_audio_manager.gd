## SpatialAudioManager - Manages all spatial audio zones and environmental sounds.
## Creates procedural ambient audio for the plaza environment.
class_name SpatialAudioManager
extends Node3D

# --- Audio Zone Definitions ---
var _zones: Array[Dictionary] = []
var _active_players: Dictionary = {}  # zone_id -> AudioStreamPlayer3D
var _player_ref: Node3D = null

# --- Procedural Audio Generators ---
var _transformer_hum: AudioStreamPlayer3D
var _fluorescent_buzz: AudioStreamPlayer3D
var _highway_drone: AudioStreamPlayer3D
var _wind_ambient: AudioStreamPlayer3D
var _rain_ambient: AudioStreamPlayer3D
var _cricket_ambient: AudioStreamPlayer3D


func _ready() -> void:
	_define_zones()
	_create_ambient_generators()


## Setup with player reference for distance calculations.
func setup(player: Node3D) -> void:
	_player_ref = player


func _process(delta: float) -> void:
	if _player_ref == null or GameManager.current_state != GameManager.GameState.PLAYING:
		return

	_update_zone_volumes()
	_update_weather_audio(delta)
	_update_ambient_generators(delta)


## Define all audio zones in the plaza.
func _define_zones() -> void:
	_zones = [
		{
			"id": "shop_interior",
			"position": Vector3(0, 1.5, 0),
			"radius": 10.0,
			"sounds": ["fluorescent_hum", "cooler_compressor"],
			"volume_base": -10.0,
		},
		{
			"id": "motel_lobby",
			"position": Vector3(15, 1.5, -5),
			"radius": 6.0,
			"sounds": ["clock_tick", "ac_rattle"],
			"volume_base": -15.0,
		},
		{
			"id": "motel_hallway",
			"position": Vector3(22, 1.5, -8),
			"radius": 12.0,
			"sounds": ["silence_deep", "distant_tv"],
			"volume_base": -20.0,
		},
		{
			"id": "fuel_forecourt",
			"position": Vector3(0, 2, 18),
			"radius": 12.0,
			"sounds": ["wind_light", "pump_clicks"],
			"volume_base": -8.0,
		},
		{
			"id": "parking_lot",
			"position": Vector3(-18, 1, 10),
			"radius": 15.0,
			"sounds": ["wind_medium", "gravel_crunch"],
			"volume_base": -6.0,
		},
		{
			"id": "utility_corridor",
			"position": Vector3(7, 1.5, -2),
			"radius": 4.0,
			"sounds": ["electrical_hum", "pipe_drip"],
			"volume_base": -12.0,
		},
		{
			"id": "basement",
			"position": Vector3(8, -1, -12),
			"radius": 5.0,
			"sounds": ["deep_silence", "water_drip"],
			"volume_base": -18.0,
		},
		{
			"id": "dumpster_alley",
			"position": Vector3(-9, 1, -8),
			"radius": 5.0,
			"sounds": ["wind_alley", "metal_creak"],
			"volume_base": -10.0,
		},
		{
			"id": "bathroom",
			"position": Vector3(-9, 1, 2),
			"radius": 4.0,
			"sounds": ["drip_echo", "vent_hiss"],
			"volume_base": -14.0,
		},
	]


## Create persistent ambient audio generators using procedural audio.
func _create_ambient_generators() -> void:
	# Transformer hum (constant low frequency)
	_transformer_hum = _create_tone_player("TransformerHum", Vector3(6, 3, 7), 60.0, -15.0)
	add_child(_transformer_hum)
	_transformer_hum.play()

	# Fluorescent buzz (interior)
	_fluorescent_buzz = _create_tone_player("FluorescentBuzz", Vector3(0, 2.8, 0), 120.0, -20.0)
	add_child(_fluorescent_buzz)
	_fluorescent_buzz.play()

	# Highway drone (distant traffic)
	_highway_drone = _create_noise_player("HighwayDrone", Vector3(0, 2, 60), -18.0)
	add_child(_highway_drone)
	_highway_drone.play()

	# Wind (varies with weather)
	_wind_ambient = _create_noise_player("WindAmbient", Vector3(0, 3, 15), -25.0)
	add_child(_wind_ambient)
	_wind_ambient.play()

	# Rain (weather-dependent)
	_rain_ambient = _create_noise_player("RainAmbient", Vector3(0, 5, 0), -40.0)
	add_child(_rain_ambient)
	_rain_ambient.play()

	# Crickets (clear nights)
	_cricket_ambient = _create_tone_player("CricketAmbient", Vector3(-10, 1, 20), 4000.0, -25.0)
	add_child(_cricket_ambient)
	_cricket_ambient.play()


## Create a procedural tone generator (sine wave).
func _create_tone_player(player_name: String, pos: Vector3, frequency: float, volume: float) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.name = player_name
	player.position = pos
	player.volume_db = volume
	player.max_distance = 30.0
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE

	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = 0.5
	player.stream = generator

	# Store frequency as metadata
	player.set_meta("frequency", frequency)
	player.set_meta("type", "tone")

	return player


## Create a procedural noise generator (filtered noise).
func _create_noise_player(player_name: String, pos: Vector3, volume: float) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.name = player_name
	player.position = pos
	player.volume_db = volume
	player.max_distance = 40.0
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE

	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = 0.5
	player.stream = generator

	player.set_meta("type", "noise")

	return player


## Update volumes based on player distance to zones.
func _update_zone_volumes() -> void:
	var player_pos := _player_ref.global_position

	for zone in _zones:
		var zone_pos: Vector3 = zone["position"]
		var radius: float = zone["radius"]
		var distance := player_pos.distance_to(zone_pos)
		var volume_factor := clampf(1.0 - (distance / radius), 0.0, 1.0)

		# Apply to zone-specific players if they exist
		var zone_id: String = zone["id"]
		if _active_players.has(zone_id):
			var player: AudioStreamPlayer3D = _active_players[zone_id]
			var target_db: float = zone["volume_base"] + (1.0 - volume_factor) * -20.0
			player.volume_db = lerpf(player.volume_db, target_db, 0.1)


## Update weather-dependent audio.
func _update_weather_audio(_delta: float) -> void:
	# Wind intensity based on weather
	var wind_volume := -25.0 + WeatherManager.wind_strength * 15.0
	_wind_ambient.volume_db = lerpf(_wind_ambient.volume_db, wind_volume, 0.05)

	# Rain intensity
	var rain_volume := -40.0
	if WeatherManager.rain_intensity > 0.1:
		rain_volume = -20.0 + WeatherManager.rain_intensity * 12.0
	_rain_ambient.volume_db = lerpf(_rain_ambient.volume_db, rain_volume, 0.05)

	# Crickets only on clear/overcast nights
	var cricket_volume := -25.0
	if WeatherManager.current_weather == WeatherManager.WeatherType.CLEAR:
		cricket_volume = -18.0
	elif WeatherManager.current_weather == WeatherManager.WeatherType.OVERCAST:
		cricket_volume = -22.0
	else:
		cricket_volume = -40.0
	_cricket_ambient.volume_db = lerpf(_cricket_ambient.volume_db, cricket_volume, 0.03)


## Fill procedural audio buffers each frame.
func _update_ambient_generators(_delta: float) -> void:
	_fill_tone_buffer(_transformer_hum)
	_fill_tone_buffer(_fluorescent_buzz)
	_fill_tone_buffer(_cricket_ambient)
	_fill_noise_buffer(_highway_drone)
	_fill_noise_buffer(_wind_ambient)
	_fill_noise_buffer(_rain_ambient)


## Fill a tone generator's buffer with sine wave data.
func _fill_tone_buffer(player: AudioStreamPlayer3D) -> void:
	if not player.playing or not player.has_stream_playback():
		return
	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback()
	var frequency: float = player.get_meta("frequency", 60.0)
	var mix_rate: float = 22050.0
	var frames_available := playback.get_frames_available()
	var phase: float = player.get_meta("phase", 0.0)

	for i in range(mini(frames_available, 512)):
		phase += frequency / mix_rate
		if phase > 1.0:
			phase -= 1.0
		var sample := sin(phase * TAU) * 0.3
		# Add slight harmonic variation
		sample += sin(phase * TAU * 2.0) * 0.05
		sample += randf_range(-0.02, 0.02)  # Tiny noise for realism
		playback.push_frame(Vector2(sample, sample))

	player.set_meta("phase", phase)


## Fill a noise generator's buffer with filtered noise.
func _fill_noise_buffer(player: AudioStreamPlayer3D) -> void:
	if not player.playing or not player.has_stream_playback():
		return
	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback()
	var frames_available := playback.get_frames_available()
	var prev_sample: float = player.get_meta("prev_sample", 0.0)

	for i in range(mini(frames_available, 512)):
		# Low-pass filtered noise (brown noise approximation)
		var white := randf_range(-1.0, 1.0)
		var sample := prev_sample * 0.98 + white * 0.02
		sample = clampf(sample, -1.0, 1.0)
		prev_sample = sample
		playback.push_frame(Vector2(sample * 0.2, sample * 0.2))

	player.set_meta("prev_sample", prev_sample)
