extends Node
## Weather system controller

# ============================================================================
# WEATHER TYPES
# ============================================================================

enum WeatherType {
	CLEAR,
	LIGHT_RAIN,
	HEAVY_RAIN,
	FOG,
	STORM,
	SNOW
}

# ============================================================================
# STATE
# ============================================================================

var current_weather: WeatherType = WeatherType.CLEAR
var weather_intensity: float = 0.0
var transition_speed: float = 0.5

# ============================================================================
# REFERENCES
# ============================================================================

var rain_particles: GPUParticles3D
var fog_environment: FogVolume
var wind_audio: AudioStreamPlayer3D

# ============================================================================
# PROCESS
# ============================================================================

func _process(delta: float) -> void:
	_update_weather_effects(delta)

# ============================================================================
# WEATHER CONTROL
# ============================================================================

func set_weather(weather_type: WeatherType, intensity: float = 1.0) -> void:
	"""Change the weather"""
	if current_weather == weather_type:
		return

	current_weather = weather_type
	weather_intensity = clamp(intensity, 0.0, 1.0)

	_apply_weather_effects()
	EventBus.weather_changed.emit(WeatherType.keys()[weather_type], intensity)

	print("Weather changed to: %s" % WeatherType.keys()[weather_type])

func _apply_weather_effects() -> void:
	"""Apply weather visual and audio effects"""
	match current_weather:
		WeatherType.CLEAR:
			_clear_weather()
		WeatherType.LIGHT_RAIN:
			_set_rain(0.3)
		WeatherType.HEAVY_RAIN:
			_set_rain(1.0)
		WeatherType.FOG:
			_set_fog(weather_intensity)
		WeatherType.STORM:
			_set_storm()
		WeatherType.SNOW:
			_set_snow()

func _clear_weather() -> void:
	"""Clear all weather effects"""
	if rain_particles:
		rain_particles.emitting = false
	if fog_environment:
		fog_environment.visible = false

func _set_rain(intensity: float) -> void:
	"""Set rain effects"""
	if rain_particles:
		rain_particles.emitting = true
		rain_particles.amount_ratio = intensity

	# Play rain sound
	AudioManager.play_sfx("rain_" + ("light" if intensity < 0.5 else "heavy"))

func _set_fog(intensity: float) -> void:
	"""Set fog effects"""
	if fog_environment:
		fog_environment.visible = true
		# Would adjust fog density

func _set_storm() -> void:
	"""Set storm effects"""
	_set_rain(1.0)

	# Play thunder occasionally
	_schedule_thunder()

func _set_snow() -> void:
	"""Set snow effects"""
	# Would activate snow particles
	pass

# ============================================================================
# SPECIAL EFFECTS
# ============================================================================

func _schedule_thunder() -> void:
	"""Schedule thunder strikes"""
	await get_tree().create_timer(randf_range(10.0, 30.0)).timeout

	if current_weather == WeatherType.STORM:
		_trigger_lightning()
		_schedule_thunder()

func _trigger_lightning() -> void:
	"""Trigger lightning flash and thunder"""
	# Flash screen
	# Play thunder sound
	AudioManager.play_sfx("thunder")

func _update_weather_effects(delta: float) -> void:
	"""Update weather effects smoothly"""
	# Smooth transitions between weather states
	pass

# ============================================================================
# HORROR INTEGRATION
# ============================================================================

func trigger_anomalous_weather() -> void:
	"""Trigger impossible weather (horror event)"""
	# Storm on clear night
	# Snow indoors
	# Etc.
	pass
