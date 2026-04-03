## SettingsManager - Handles game settings for graphics, audio, controls, and accessibility.
## Persists settings to a config file.
extends Node

# --- Signals ---
signal settings_changed(category: String)

# --- Constants ---
const SETTINGS_PATH := "user://settings.cfg"

# --- Graphics Settings ---
var graphics_preset: int = 1  # 0=low, 1=balanced, 2=high
var resolution_scale: float = 1.0  # 0.5 to 1.0
var fullscreen: bool = false
var vsync: bool = true
var msaa_level: int = 2  # 0=off, 2=2x, 4=4x
var shadow_quality: int = 2  # 0=off, 1=low, 2=medium, 3=high
var ssao_enabled: bool = true
var ssil_enabled: bool = true
var volumetric_fog: bool = true
var glow_enabled: bool = true
var fov: float = 75.0
var gamma: float = 1.0
var brightness: float = 1.0

# --- Audio Settings ---
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 0.8
var ambience_volume: float = 1.0
var voice_volume: float = 1.0
var radio_volume: float = 0.9
var subtitles_enabled: bool = true
var subtitle_size: int = 1  # 0=small, 1=medium, 2=large

# --- Controls ---
var mouse_sensitivity: float = 0.002
var invert_y: bool = false
var toggle_sprint: bool = false
var toggle_crouch: bool = true
var headbob_intensity: float = 1.0

# --- Accessibility ---
var colorblind_mode: int = 0  # 0=off, 1=protanopia, 2=deuteranopia, 3=tritanopia
var reduce_flashing: bool = false
var screen_shake_intensity: float = 1.0
var horror_intensity_override: float = -1.0  # -1 = use default
var large_text: bool = false
var high_contrast_ui: bool = false

# --- Difficulty ---
var difficulty: int = 1  # 0=relaxed, 1=normal, 2=hard
var customer_patience_mult: float = 1.0
var horror_frequency_mult: float = 1.0
var economic_difficulty: float = 1.0


func _ready() -> void:
	load_settings()


## Apply all current settings to the engine.
func apply_all() -> void:
	apply_graphics()
	apply_audio()
	apply_controls()
	apply_accessibility()
	apply_difficulty()


## Apply graphics settings.
func apply_graphics() -> void:
	# Fullscreen
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	# VSync
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	# Resolution scaling
	get_viewport().scaling_3d_scale = resolution_scale

	# MSAA
	match msaa_level:
		0: get_viewport().msaa_3d = Viewport.MSAA_DISABLED
		2: get_viewport().msaa_3d = Viewport.MSAA_2X
		4: get_viewport().msaa_3d = Viewport.MSAA_4X

	settings_changed.emit("graphics")


func set_graphics_preset(preset: int) -> void:
	graphics_preset = clampi(preset, 0, 2)

	match graphics_preset:
		0:
			resolution_scale = 0.65
			vsync = false
			msaa_level = 0
			shadow_quality = 0
			ssao_enabled = false
			ssil_enabled = false
			volumetric_fog = false
			glow_enabled = false
		1:
			resolution_scale = 0.85
			vsync = true
			msaa_level = 0
			shadow_quality = 1
			ssao_enabled = false
			ssil_enabled = false
			volumetric_fog = false
			glow_enabled = true
		2:
			resolution_scale = 1.0
			vsync = true
			msaa_level = 2
			shadow_quality = 2
			ssao_enabled = true
			ssil_enabled = true
			volumetric_fog = true
			glow_enabled = true


## Apply audio settings.
func apply_audio() -> void:
	_set_bus_volume("Master", master_volume)
	if AudioServer.get_bus_index("SFX") >= 0:
		_set_bus_volume("SFX", sfx_volume)
	if AudioServer.get_bus_index("Music") >= 0:
		_set_bus_volume("Music", music_volume)
	if AudioServer.get_bus_index("Ambience") >= 0:
		_set_bus_volume("Ambience", ambience_volume)
	if AudioServer.get_bus_index("Voice") >= 0:
		_set_bus_volume("Voice", voice_volume)
	if AudioServer.get_bus_index("Radio") >= 0:
		_set_bus_volume("Radio", radio_volume)

	settings_changed.emit("audio")


## Apply control settings.
func apply_controls() -> void:
	# Applied by PlayerController reading these values
	settings_changed.emit("controls")


## Apply accessibility settings.
func apply_accessibility() -> void:
	settings_changed.emit("accessibility")


## Apply difficulty settings.
func apply_difficulty() -> void:
	match difficulty:
		0:  # Relaxed
			customer_patience_mult = 1.5
			horror_frequency_mult = 0.5
			economic_difficulty = 0.7
		1:  # Normal
			customer_patience_mult = 1.0
			horror_frequency_mult = 1.0
			economic_difficulty = 1.0
		2:  # Hard
			customer_patience_mult = 0.7
			horror_frequency_mult = 1.5
			economic_difficulty = 1.3
	settings_changed.emit("difficulty")


## Save settings to config file.
func save_settings() -> void:
	var config := ConfigFile.new()

	# Graphics
	config.set_value("graphics", "graphics_preset", graphics_preset)
	config.set_value("graphics", "resolution_scale", resolution_scale)
	config.set_value("graphics", "fullscreen", fullscreen)
	config.set_value("graphics", "vsync", vsync)
	config.set_value("graphics", "msaa_level", msaa_level)
	config.set_value("graphics", "shadow_quality", shadow_quality)
	config.set_value("graphics", "ssao_enabled", ssao_enabled)
	config.set_value("graphics", "ssil_enabled", ssil_enabled)
	config.set_value("graphics", "volumetric_fog", volumetric_fog)
	config.set_value("graphics", "glow_enabled", glow_enabled)
	config.set_value("graphics", "fov", fov)
	config.set_value("graphics", "gamma", gamma)
	config.set_value("graphics", "brightness", brightness)

	# Audio
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "ambience_volume", ambience_volume)
	config.set_value("audio", "voice_volume", voice_volume)
	config.set_value("audio", "radio_volume", radio_volume)
	config.set_value("audio", "subtitles_enabled", subtitles_enabled)
	config.set_value("audio", "subtitle_size", subtitle_size)

	# Controls
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("controls", "invert_y", invert_y)
	config.set_value("controls", "toggle_sprint", toggle_sprint)
	config.set_value("controls", "toggle_crouch", toggle_crouch)
	config.set_value("controls", "headbob_intensity", headbob_intensity)

	# Accessibility
	config.set_value("accessibility", "colorblind_mode", colorblind_mode)
	config.set_value("accessibility", "reduce_flashing", reduce_flashing)
	config.set_value("accessibility", "screen_shake_intensity", screen_shake_intensity)
	config.set_value("accessibility", "horror_intensity_override", horror_intensity_override)
	config.set_value("accessibility", "large_text", large_text)
	config.set_value("accessibility", "high_contrast_ui", high_contrast_ui)

	# Difficulty
	config.set_value("difficulty", "difficulty", difficulty)

	config.save(SETTINGS_PATH)


## Load settings from config file.
func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		# Use defaults, save them
		save_settings()
		return

	# Graphics
	graphics_preset = config.get_value("graphics", "graphics_preset", 1)
	resolution_scale = config.get_value("graphics", "resolution_scale", 1.0)
	fullscreen = config.get_value("graphics", "fullscreen", false)
	vsync = config.get_value("graphics", "vsync", true)
	msaa_level = config.get_value("graphics", "msaa_level", 2)
	shadow_quality = config.get_value("graphics", "shadow_quality", 2)
	ssao_enabled = config.get_value("graphics", "ssao_enabled", true)
	ssil_enabled = config.get_value("graphics", "ssil_enabled", true)
	volumetric_fog = config.get_value("graphics", "volumetric_fog", true)
	glow_enabled = config.get_value("graphics", "glow_enabled", true)
	fov = config.get_value("graphics", "fov", 75.0)
	gamma = config.get_value("graphics", "gamma", 1.0)
	brightness = config.get_value("graphics", "brightness", 1.0)

	# Audio
	master_volume = config.get_value("audio", "master_volume", 1.0)
	sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
	music_volume = config.get_value("audio", "music_volume", 0.8)
	ambience_volume = config.get_value("audio", "ambience_volume", 1.0)
	voice_volume = config.get_value("audio", "voice_volume", 1.0)
	radio_volume = config.get_value("audio", "radio_volume", 0.9)
	subtitles_enabled = config.get_value("audio", "subtitles_enabled", true)
	subtitle_size = config.get_value("audio", "subtitle_size", 1)

	# Controls
	mouse_sensitivity = config.get_value("controls", "mouse_sensitivity", 0.002)
	invert_y = config.get_value("controls", "invert_y", false)
	toggle_sprint = config.get_value("controls", "toggle_sprint", false)
	toggle_crouch = config.get_value("controls", "toggle_crouch", true)
	headbob_intensity = config.get_value("controls", "headbob_intensity", 1.0)

	# Accessibility
	colorblind_mode = config.get_value("accessibility", "colorblind_mode", 0)
	reduce_flashing = config.get_value("accessibility", "reduce_flashing", false)
	screen_shake_intensity = config.get_value("accessibility", "screen_shake_intensity", 1.0)
	horror_intensity_override = config.get_value("accessibility", "horror_intensity_override", -1.0)
	large_text = config.get_value("accessibility", "large_text", false)
	high_contrast_ui = config.get_value("accessibility", "high_contrast_ui", false)

	# Difficulty
	difficulty = config.get_value("difficulty", "difficulty", 1)

	apply_all()


## Reset all settings to defaults.
func reset_to_defaults() -> void:
	resolution_scale = 1.0
	fullscreen = false
	graphics_preset = 1
	vsync = true
	msaa_level = 2
	shadow_quality = 2
	ssao_enabled = true
	ssil_enabled = true
	volumetric_fog = true
	glow_enabled = true
	fov = 75.0
	gamma = 1.0
	brightness = 1.0
	master_volume = 1.0
	sfx_volume = 1.0
	music_volume = 0.8
	ambience_volume = 1.0
	voice_volume = 1.0
	radio_volume = 0.9
	subtitles_enabled = true
	subtitle_size = 1
	mouse_sensitivity = 0.002
	invert_y = false
	toggle_sprint = false
	toggle_crouch = true
	headbob_intensity = 1.0
	colorblind_mode = 0
	reduce_flashing = false
	screen_shake_intensity = 1.0
	horror_intensity_override = -1.0
	large_text = false
	high_contrast_ui = false
	difficulty = 1
	save_settings()
	apply_all()


# --- Private ---

func _set_bus_volume(bus_name: String, linear_volume: float) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		var db := linear_to_db(linear_volume)
		AudioServer.set_bus_volume_db(bus_idx, db)
