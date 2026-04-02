## SettingsMenu - Full settings UI with tabs for Graphics, Audio, Controls, and Accessibility.
extends Control

# --- Tab References ---
@onready var tab_container: TabContainer = $Panel/TabContainer

# --- Graphics ---
@onready var fullscreen_check: CheckBox = $Panel/TabContainer/Graphics/VBox/FullscreenCheck
@onready var vsync_check: CheckBox = $Panel/TabContainer/Graphics/VBox/VsyncCheck
@onready var resolution_slider: HSlider = $Panel/TabContainer/Graphics/VBox/ResolutionSlider
@onready var resolution_label: Label = $Panel/TabContainer/Graphics/VBox/ResolutionLabel
@onready var msaa_option: OptionButton = $Panel/TabContainer/Graphics/VBox/MSAAOption
@onready var shadow_option: OptionButton = $Panel/TabContainer/Graphics/VBox/ShadowOption
@onready var ssao_check: CheckBox = $Panel/TabContainer/Graphics/VBox/SSAOCheck
@onready var fog_check: CheckBox = $Panel/TabContainer/Graphics/VBox/FogCheck
@onready var glow_check: CheckBox = $Panel/TabContainer/Graphics/VBox/GlowCheck
@onready var fov_slider: HSlider = $Panel/TabContainer/Graphics/VBox/FOVSlider
@onready var fov_label: Label = $Panel/TabContainer/Graphics/VBox/FOVLabel
@onready var brightness_slider: HSlider = $Panel/TabContainer/Graphics/VBox/BrightnessSlider

# --- Audio ---
@onready var master_slider: HSlider = $Panel/TabContainer/Audio/VBox/MasterSlider
@onready var sfx_slider: HSlider = $Panel/TabContainer/Audio/VBox/SFXSlider
@onready var music_slider: HSlider = $Panel/TabContainer/Audio/VBox/MusicSlider
@onready var ambience_slider: HSlider = $Panel/TabContainer/Audio/VBox/AmbienceSlider
@onready var voice_slider: HSlider = $Panel/TabContainer/Audio/VBox/VoiceSlider
@onready var subtitles_check: CheckBox = $Panel/TabContainer/Audio/VBox/SubtitlesCheck
@onready var subtitle_size_option: OptionButton = $Panel/TabContainer/Audio/VBox/SubtitleSizeOption

# --- Controls ---
@onready var sensitivity_slider: HSlider = $Panel/TabContainer/Controls/VBox/SensitivitySlider
@onready var sensitivity_label: Label = $Panel/TabContainer/Controls/VBox/SensitivityLabel
@onready var invert_y_check: CheckBox = $Panel/TabContainer/Controls/VBox/InvertYCheck
@onready var toggle_sprint_check: CheckBox = $Panel/TabContainer/Controls/VBox/ToggleSprintCheck
@onready var toggle_crouch_check: CheckBox = $Panel/TabContainer/Controls/VBox/ToggleCrouchCheck
@onready var headbob_slider: HSlider = $Panel/TabContainer/Controls/VBox/HeadbobSlider

# --- Accessibility ---
@onready var difficulty_option: OptionButton = $Panel/TabContainer/Accessibility/VBox/DifficultyOption
@onready var reduce_flash_check: CheckBox = $Panel/TabContainer/Accessibility/VBox/ReduceFlashCheck
@onready var shake_slider: HSlider = $Panel/TabContainer/Accessibility/VBox/ShakeSlider
@onready var large_text_check: CheckBox = $Panel/TabContainer/Accessibility/VBox/LargeTextCheck
@onready var contrast_check: CheckBox = $Panel/TabContainer/Accessibility/VBox/ContrastCheck
@onready var colorblind_option: OptionButton = $Panel/TabContainer/Accessibility/VBox/ColorblindOption

# --- Buttons ---
@onready var apply_btn: Button = $Panel/Buttons/ApplyButton
@onready var reset_btn: Button = $Panel/Buttons/ResetButton
@onready var back_btn: Button = $Panel/Buttons/BackButton


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Connect buttons
	apply_btn.pressed.connect(_on_apply)
	reset_btn.pressed.connect(_on_reset)
	back_btn.pressed.connect(_on_back)

	# Load current settings into UI
	_load_from_settings()

	# Connect sliders for live labels
	if resolution_slider:
		resolution_slider.value_changed.connect(func(val): resolution_label.text = "%.0f%%" % (val * 100))
	if fov_slider:
		fov_slider.value_changed.connect(func(val): fov_label.text = "%.0f" % val + "°")
	if sensitivity_slider:
		sensitivity_slider.value_changed.connect(func(val): sensitivity_label.text = "%.4f" % val)


## Show the settings menu.
func show_menu() -> void:
	_load_from_settings()
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


## Hide the settings menu.
func hide_menu() -> void:
	visible = false


func _load_from_settings() -> void:
	var sm := SettingsManager
	if fullscreen_check: fullscreen_check.button_pressed = sm.fullscreen
	if vsync_check: vsync_check.button_pressed = sm.vsync
	if resolution_slider: resolution_slider.value = sm.resolution_scale
	if msaa_option: msaa_option.selected = [0, 0, 1, 1, 2][mini(sm.msaa_level, 4)]
	if shadow_option: shadow_option.selected = sm.shadow_quality
	if ssao_check: ssao_check.button_pressed = sm.ssao_enabled
	if fog_check: fog_check.button_pressed = sm.volumetric_fog
	if glow_check: glow_check.button_pressed = sm.glow_enabled
	if fov_slider: fov_slider.value = sm.fov
	if brightness_slider: brightness_slider.value = sm.brightness

	if master_slider: master_slider.value = sm.master_volume
	if sfx_slider: sfx_slider.value = sm.sfx_volume
	if music_slider: music_slider.value = sm.music_volume
	if ambience_slider: ambience_slider.value = sm.ambience_volume
	if voice_slider: voice_slider.value = sm.voice_volume
	if subtitles_check: subtitles_check.button_pressed = sm.subtitles_enabled
	if subtitle_size_option: subtitle_size_option.selected = sm.subtitle_size

	if sensitivity_slider: sensitivity_slider.value = sm.mouse_sensitivity
	if invert_y_check: invert_y_check.button_pressed = sm.invert_y
	if toggle_sprint_check: toggle_sprint_check.button_pressed = sm.toggle_sprint
	if toggle_crouch_check: toggle_crouch_check.button_pressed = sm.toggle_crouch
	if headbob_slider: headbob_slider.value = sm.headbob_intensity

	if difficulty_option: difficulty_option.selected = sm.difficulty
	if reduce_flash_check: reduce_flash_check.button_pressed = sm.reduce_flashing
	if shake_slider: shake_slider.value = sm.screen_shake_intensity
	if large_text_check: large_text_check.button_pressed = sm.large_text
	if contrast_check: contrast_check.button_pressed = sm.high_contrast_ui
	if colorblind_option: colorblind_option.selected = sm.colorblind_mode


func _save_to_settings() -> void:
	var sm := SettingsManager

	# Graphics
	if fullscreen_check: sm.fullscreen = fullscreen_check.button_pressed
	if vsync_check: sm.vsync = vsync_check.button_pressed
	if resolution_slider: sm.resolution_scale = resolution_slider.value
	if msaa_option: sm.msaa_level = [0, 2, 4][mini(msaa_option.selected, 2)]
	if shadow_option: sm.shadow_quality = shadow_option.selected
	if ssao_check: sm.ssao_enabled = ssao_check.button_pressed
	if fog_check: sm.volumetric_fog = fog_check.button_pressed
	if glow_check: sm.glow_enabled = glow_check.button_pressed
	if fov_slider: sm.fov = fov_slider.value
	if brightness_slider: sm.brightness = brightness_slider.value

	# Audio
	if master_slider: sm.master_volume = master_slider.value
	if sfx_slider: sm.sfx_volume = sfx_slider.value
	if music_slider: sm.music_volume = music_slider.value
	if ambience_slider: sm.ambience_volume = ambience_slider.value
	if voice_slider: sm.voice_volume = voice_slider.value
	if subtitles_check: sm.subtitles_enabled = subtitles_check.button_pressed
	if subtitle_size_option: sm.subtitle_size = subtitle_size_option.selected

	# Controls
	if sensitivity_slider: sm.mouse_sensitivity = sensitivity_slider.value
	if invert_y_check: sm.invert_y = invert_y_check.button_pressed
	if toggle_sprint_check: sm.toggle_sprint = toggle_sprint_check.button_pressed
	if toggle_crouch_check: sm.toggle_crouch = toggle_crouch_check.button_pressed
	if headbob_slider: sm.headbob_intensity = headbob_slider.value

	# Accessibility
	if difficulty_option: sm.difficulty = difficulty_option.selected
	if reduce_flash_check: sm.reduce_flashing = reduce_flash_check.button_pressed
	if shake_slider: sm.screen_shake_intensity = shake_slider.value
	if large_text_check: sm.large_text = large_text_check.button_pressed
	if contrast_check: sm.high_contrast_ui = contrast_check.button_pressed
	if colorblind_option: sm.colorblind_mode = colorblind_option.selected

	sm.save_settings()
	sm.apply_all()


func _on_apply() -> void:
	_save_to_settings()
	DialogueManager.show_subtitle("", "Settings applied.")


func _on_reset() -> void:
	SettingsManager.reset_to_defaults()
	_load_from_settings()
	DialogueManager.show_subtitle("", "Settings reset to defaults.")


func _on_back() -> void:
	hide_menu()
