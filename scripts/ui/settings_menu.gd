extends Control
## Settings menu controller

@onready var fullscreen_check = $Panel/VBoxContainer/TabContainer/Graphics/FullscreenCheck
@onready var vsync_check = $Panel/VBoxContainer/TabContainer/Graphics/VSyncCheck
@onready var msaa_slider = $Panel/VBoxContainer/TabContainer/Graphics/MSAASlider
@onready var shadow_quality_slider = $Panel/VBoxContainer/TabContainer/Graphics/ShadowQualitySlider
@onready var fps_counter_check = $Panel/VBoxContainer/TabContainer/Graphics/FPSCounterCheck

@onready var master_slider = $Panel/VBoxContainer/TabContainer/Audio/MasterSlider
@onready var music_slider = $Panel/VBoxContainer/TabContainer/Audio/MusicSlider
@onready var sfx_slider = $Panel/VBoxContainer/TabContainer/Audio/SFXSlider
@onready var ambience_slider = $Panel/VBoxContainer/TabContainer/Audio/AmbienceSlider

@onready var mouse_sens_slider = $Panel/VBoxContainer/TabContainer/Gameplay/MouseSensSlider
@onready var invert_y_check = $Panel/VBoxContainer/TabContainer/Gameplay/InvertYCheck
@onready var head_bob_check = $Panel/VBoxContainer/TabContainer/Gameplay/HeadBobCheck
@onready var camera_shake_check = $Panel/VBoxContainer/TabContainer/Gameplay/CameraShakeCheck
@onready var subtitles_check = $Panel/VBoxContainer/TabContainer/Gameplay/SubtitlesCheck

func _ready() -> void:
	_load_settings()

func _load_settings() -> void:
	"""Load current settings into UI"""
	fullscreen_check.button_pressed = Settings.get_setting("fullscreen")
	vsync_check.button_pressed = Settings.get_setting("vsync")
	msaa_slider.value = Settings.get_setting("msaa")
	shadow_quality_slider.value = Settings.get_setting("shadow_quality")
	fps_counter_check.button_pressed = Settings.get_setting("show_fps")

	master_slider.value = Settings.get_setting("master_volume")
	music_slider.value = Settings.get_setting("music_volume")
	sfx_slider.value = Settings.get_setting("sfx_volume")
	ambience_slider.value = Settings.get_setting("ambience_volume")

	mouse_sens_slider.value = Settings.get_setting("mouse_sensitivity")
	invert_y_check.button_pressed = Settings.get_setting("invert_y")
	head_bob_check.button_pressed = Settings.get_setting("head_bob")
	camera_shake_check.button_pressed = Settings.get_setting("camera_shake")
	subtitles_check.button_pressed = Settings.get_setting("subtitles")

# Graphics callbacks
func _on_fullscreen_toggled(enabled: bool) -> void:
	Settings.set_fullscreen(enabled)

func _on_vsync_toggled(enabled: bool) -> void:
	Settings.set_vsync(enabled)

func _on_msaa_changed(value: float) -> void:
	Settings.set_setting("msaa", int(value))

func _on_shadow_quality_changed(value: float) -> void:
	Settings.set_setting("shadow_quality", int(value))

func _on_fps_counter_toggled(enabled: bool) -> void:
	Settings.set_setting("show_fps", enabled)

# Audio callbacks
func _on_master_volume_changed(value: float) -> void:
	Settings.set_audio_volume("master", value)

func _on_music_volume_changed(value: float) -> void:
	Settings.set_audio_volume("music", value)

func _on_sfx_volume_changed(value: float) -> void:
	Settings.set_audio_volume("sfx", value)

func _on_ambience_volume_changed(value: float) -> void:
	Settings.set_audio_volume("ambience", value)

# Gameplay callbacks
func _on_mouse_sens_changed(value: float) -> void:
	Settings.set_mouse_sensitivity(value)

func _on_invert_y_toggled(enabled: bool) -> void:
	Settings.set_invert_y(enabled)

func _on_head_bob_toggled(enabled: bool) -> void:
	Settings.set_setting("head_bob", enabled)

func _on_camera_shake_toggled(enabled: bool) -> void:
	Settings.set_setting("camera_shake", enabled)

func _on_subtitles_toggled(enabled: bool) -> void:
	Settings.set_setting("subtitles", enabled)

# Button callbacks
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_apply_pressed() -> void:
	Settings.save_settings()
	Settings.apply_settings()
