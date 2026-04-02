extends Node
## Game settings manager
## Handles user preferences, graphics settings, and controls

# ============================================================================
# SETTINGS
# ============================================================================

var settings: Dictionary = {
	# Graphics
	"fullscreen": true,
	"vsync": true,
	"msaa": 2,
	"shadow_quality": 3,
	"texture_quality": 1.0,
	"render_scale": 1.0,
	"show_fps": false,

	# Audio
	"master_volume": 1.0,
	"music_volume": 0.7,
	"sfx_volume": 1.0,
	"ambience_volume": 0.8,

	# Gameplay
	"mouse_sensitivity": 1.0,
	"invert_y": false,
	"head_bob": true,
	"motion_blur": false,
	"camera_shake": true,
	"subtitles": true,

	# Accessibility
	"colorblind_mode": false,
	"screen_shake_intensity": 1.0,
	"text_size": 1.0
}

const SETTINGS_PATH = "user://settings.cfg"

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	load_settings()
	apply_settings()
	print("Settings initialized")

# ============================================================================
# SETTINGS MANAGEMENT
# ============================================================================

func save_settings() -> void:
	"""Save settings to file"""
	var config = ConfigFile.new()

	for key in settings:
		config.set_value("Settings", key, settings[key])

	var err = config.save(SETTINGS_PATH)
	if err != OK:
		push_error("Failed to save settings")
	else:
		print("Settings saved")

func load_settings() -> void:
	"""Load settings from file"""
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)

	if err != OK:
		print("No settings file found, using defaults")
		return

	for key in settings:
		if config.has_section_key("Settings", key):
			settings[key] = config.get_value("Settings", key)

	print("Settings loaded")

func apply_settings() -> void:
	"""Apply current settings to the game"""
	_apply_graphics_settings()
	_apply_audio_settings()
	_apply_input_settings()

# ============================================================================
# GRAPHICS SETTINGS
# ============================================================================

func _apply_graphics_settings() -> void:
	"""Apply graphics settings"""
	# Fullscreen
	if settings["fullscreen"]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	# VSync
	if settings["vsync"]:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	# MSAA
	var viewport = get_viewport()
	if viewport:
		match settings["msaa"]:
			0:
				viewport.msaa_3d = Viewport.MSAA_DISABLED
			1:
				viewport.msaa_3d = Viewport.MSAA_2X
			2:
				viewport.msaa_3d = Viewport.MSAA_4X
			3:
				viewport.msaa_3d = Viewport.MSAA_8X

func set_fullscreen(enabled: bool) -> void:
	"""Set fullscreen mode"""
	settings["fullscreen"] = enabled
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func set_vsync(enabled: bool) -> void:
	"""Set VSync"""
	settings["vsync"] = enabled
	if enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

# ============================================================================
# AUDIO SETTINGS
# ============================================================================

func _apply_audio_settings() -> void:
	"""Apply audio settings"""
	AudioManager.set_master_volume(settings["master_volume"])
	AudioManager.set_music_volume(settings["music_volume"])
	AudioManager.set_sfx_volume(settings["sfx_volume"])
	AudioManager.set_ambience_volume(settings["ambience_volume"])

func set_audio_volume(bus: String, volume: float) -> void:
	"""Set volume for an audio bus"""
	volume = clamp(volume, 0.0, 1.0)
	match bus:
		"master":
			settings["master_volume"] = volume
			AudioManager.set_master_volume(volume)
		"music":
			settings["music_volume"] = volume
			AudioManager.set_music_volume(volume)
		"sfx":
			settings["sfx_volume"] = volume
			AudioManager.set_sfx_volume(volume)
		"ambience":
			settings["ambience_volume"] = volume
			AudioManager.set_ambience_volume(volume)

# ============================================================================
# INPUT SETTINGS
# ============================================================================

func _apply_input_settings() -> void:
	"""Apply input settings"""
	# Mouse sensitivity will be read by player controller
	pass

func set_mouse_sensitivity(sensitivity: float) -> void:
	"""Set mouse sensitivity"""
	settings["mouse_sensitivity"] = clamp(sensitivity, 0.1, 3.0)

func set_invert_y(enabled: bool) -> void:
	"""Set Y-axis inversion"""
	settings["invert_y"] = enabled

# ============================================================================
# GETTERS
# ============================================================================

func get_setting(key: String) -> Variant:
	"""Get a setting value"""
	return settings.get(key, null)

func set_setting(key: String, value: Variant) -> void:
	"""Set a setting value"""
	settings[key] = value
