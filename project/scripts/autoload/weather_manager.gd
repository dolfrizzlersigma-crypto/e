## WeatherManager - Dynamic weather system affecting gameplay and atmosphere.
## Controls rain, fog, wind, storms, and environmental effects.
extends Node

# --- Signals ---
signal weather_changed(new_weather: WeatherType)
signal storm_warning_issued(description: String)
signal blackout_triggered()
signal visibility_changed(level: float)

# --- Enums ---
enum WeatherType { CLEAR, OVERCAST, FOG, LIGHT_RAIN, HEAVY_RAIN, STORM, DUST }

# --- State ---
var current_weather: WeatherType = WeatherType.CLEAR:
	set(value):
		if current_weather != value:
			current_weather = value
			_apply_weather_effects()
			weather_changed.emit(current_weather)

var wind_strength: float = 0.0  # 0.0 to 1.0
var rain_intensity: float = 0.0  # 0.0 to 1.0
var fog_density: float = 0.0  # 0.0 to 1.0
var visibility: float = 1.0  # 0.0 = blind, 1.0 = perfect
var temperature: float = 15.0  # Celsius, affects comfort
var weather_change_timer: float = 0.0
var storm_active: bool = false

# --- Configuration ---
const MIN_WEATHER_DURATION: float = 60.0
const MAX_WEATHER_DURATION: float = 240.0
const STORM_BLACKOUT_CHANCE: float = 0.3

# Weather transition probabilities per current weather
var _transition_weights: Dictionary = {
	WeatherType.CLEAR: {WeatherType.CLEAR: 3, WeatherType.OVERCAST: 2, WeatherType.FOG: 1},
	WeatherType.OVERCAST: {WeatherType.CLEAR: 1, WeatherType.OVERCAST: 2, WeatherType.LIGHT_RAIN: 2, WeatherType.FOG: 1},
	WeatherType.FOG: {WeatherType.CLEAR: 1, WeatherType.OVERCAST: 2, WeatherType.FOG: 3},
	WeatherType.LIGHT_RAIN: {WeatherType.OVERCAST: 1, WeatherType.LIGHT_RAIN: 2, WeatherType.HEAVY_RAIN: 2},
	WeatherType.HEAVY_RAIN: {WeatherType.LIGHT_RAIN: 2, WeatherType.HEAVY_RAIN: 2, WeatherType.STORM: 1},
	WeatherType.STORM: {WeatherType.HEAVY_RAIN: 3, WeatherType.STORM: 1, WeatherType.OVERCAST: 1},
	WeatherType.DUST: {WeatherType.CLEAR: 2, WeatherType.DUST: 2, WeatherType.OVERCAST: 1},
}


func _ready() -> void:
	_randomize_initial_weather()


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	weather_change_timer -= delta
	if weather_change_timer <= 0.0:
		_transition_weather()
		weather_change_timer = randf_range(MIN_WEATHER_DURATION, MAX_WEATHER_DURATION)

	_update_environmental_values(delta)


## Force a specific weather state (for scripted events).
func set_weather(weather: WeatherType) -> void:
	current_weather = weather
	weather_change_timer = randf_range(MIN_WEATHER_DURATION, MAX_WEATHER_DURATION)


## Issue a storm warning (can be real or false).
func issue_storm_warning(description: String, is_real: bool = true) -> void:
	storm_warning_issued.emit(description)
	if is_real and current_weather != WeatherType.STORM:
		# Schedule actual storm
		weather_change_timer = randf_range(30.0, 90.0)
		current_weather = WeatherType.HEAVY_RAIN


## Get weather description for UI/radio.
func get_weather_description() -> String:
	match current_weather:
		WeatherType.CLEAR:
			return "Clear skies. Stars visible."
		WeatherType.OVERCAST:
			return "Overcast. Low cloud cover."
		WeatherType.FOG:
			return "Dense fog. Visibility reduced."
		WeatherType.LIGHT_RAIN:
			return "Light rain. Roads wet."
		WeatherType.HEAVY_RAIN:
			return "Heavy rain. Poor visibility."
		WeatherType.STORM:
			return "Severe storm. Exercise caution."
		WeatherType.DUST:
			return "Dust advisory. Winds from the south."
		_:
			return "Weather conditions unknown."


## Get save data.
func get_save_data() -> Dictionary:
	return {
		"weather": current_weather,
		"wind": wind_strength,
		"rain": rain_intensity,
		"fog": fog_density,
		"temperature": temperature,
		"timer": weather_change_timer,
	}


## Load save data.
func load_save_data(data: Dictionary) -> void:
	current_weather = data.get("weather", WeatherType.CLEAR)
	wind_strength = data.get("wind", 0.0)
	rain_intensity = data.get("rain", 0.0)
	fog_density = data.get("fog", 0.0)
	temperature = data.get("temperature", 15.0)
	weather_change_timer = data.get("timer", 120.0)


# --- Private ---

func _randomize_initial_weather() -> void:
	var options := [WeatherType.CLEAR, WeatherType.OVERCAST, WeatherType.FOG, WeatherType.LIGHT_RAIN]
	current_weather = options[randi() % options.size()]
	weather_change_timer = randf_range(MIN_WEATHER_DURATION, MAX_WEATHER_DURATION)


func _transition_weather() -> void:
	var weights: Dictionary = _transition_weights.get(current_weather, {})
	if weights.is_empty():
		return

	var total: float = 0.0
	for w in weights.values():
		total += w

	var roll := randf() * total
	var cumulative: float = 0.0
	for weather_type in weights:
		cumulative += weights[weather_type]
		if roll <= cumulative:
			current_weather = weather_type
			return


func _apply_weather_effects() -> void:
	match current_weather:
		WeatherType.CLEAR:
			rain_intensity = 0.0
			fog_density = 0.0
			wind_strength = randf_range(0.0, 0.1)
			visibility = 1.0
		WeatherType.OVERCAST:
			rain_intensity = 0.0
			fog_density = randf_range(0.0, 0.1)
			wind_strength = randf_range(0.05, 0.2)
			visibility = 0.9
		WeatherType.FOG:
			rain_intensity = 0.0
			fog_density = randf_range(0.5, 0.9)
			wind_strength = randf_range(0.0, 0.05)
			visibility = randf_range(0.2, 0.4)
		WeatherType.LIGHT_RAIN:
			rain_intensity = randf_range(0.2, 0.4)
			fog_density = randf_range(0.0, 0.2)
			wind_strength = randf_range(0.1, 0.3)
			visibility = 0.7
		WeatherType.HEAVY_RAIN:
			rain_intensity = randf_range(0.6, 0.9)
			fog_density = randf_range(0.1, 0.3)
			wind_strength = randf_range(0.3, 0.6)
			visibility = 0.4
		WeatherType.STORM:
			rain_intensity = randf_range(0.8, 1.0)
			fog_density = randf_range(0.2, 0.5)
			wind_strength = randf_range(0.7, 1.0)
			visibility = randf_range(0.1, 0.3)
			storm_active = true
			# Chance of blackout during storms
			if randf() < STORM_BLACKOUT_CHANCE:
				blackout_triggered.emit()
		WeatherType.DUST:
			rain_intensity = 0.0
			fog_density = randf_range(0.3, 0.6)
			wind_strength = randf_range(0.5, 0.8)
			visibility = randf_range(0.3, 0.5)

	if current_weather != WeatherType.STORM:
		storm_active = false

	visibility_changed.emit(visibility)


func _update_environmental_values(delta: float) -> void:
	# Smooth interpolation of visual values
	# Temperature shifts during storms
	if storm_active:
		temperature = lerpf(temperature, 5.0, delta * 0.1)
	else:
		temperature = lerpf(temperature, 15.0, delta * 0.05)
