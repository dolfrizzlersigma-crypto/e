## MainMenu - Title screen with game mode selection and save loading.
extends Control

const SETTINGS_MENU_SCENE := preload("res://scenes/ui/settings_menu.tscn")

@onready var new_game_btn: Button = $VBox/NewGameButton
@onready var endless_btn: Button = $VBox/EndlessModeButton
@onready var load_btn: Button = $VBox/LoadGameButton
@onready var settings_btn: Button = $VBox/SettingsButton
@onready var quit_btn: Button = $VBox/QuitButton

var _settings_menu: Control = null


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	new_game_btn.pressed.connect(_on_new_game)
	endless_btn.pressed.connect(_on_endless_mode)
	load_btn.pressed.connect(_on_load_game)
	settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit)

	# Disable load if no saves exist
	load_btn.disabled = SaveManager.get_all_save_info().is_empty()

	_settings_menu = SETTINGS_MENU_SCENE.instantiate()
	add_child(_settings_menu)


func _on_new_game() -> void:
	GameManager.start_new_game(GameManager.GameMode.STORY)
	get_tree().change_scene_to_file("res://scenes/levels/service_plaza.tscn")


func _on_endless_mode() -> void:
	GameManager.start_new_game(GameManager.GameMode.ENDLESS)
	get_tree().change_scene_to_file("res://scenes/levels/service_plaza.tscn")


func _on_load_game() -> void:
	# Load most recent save
	var saves := SaveManager.get_all_save_info()
	if saves.size() > 0:
		var latest := saves[saves.size() - 1]
		SaveManager.load_game(latest["slot"])
		get_tree().change_scene_to_file("res://scenes/levels/service_plaza.tscn")


func _on_settings() -> void:
	if _settings_menu and _settings_menu.has_method("show_menu"):
		_settings_menu.show_menu()


func _on_quit() -> void:
	get_tree().quit()
