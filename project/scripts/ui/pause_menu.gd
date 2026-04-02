## PauseMenu - Pause screen with resume, save, load, settings, and quit options.
extends Control

@onready var resume_btn: Button = $Panel/VBox/ResumeButton
@onready var save_btn: Button = $Panel/VBox/SaveButton
@onready var load_btn: Button = $Panel/VBox/LoadButton
@onready var settings_btn: Button = $Panel/VBox/SettingsButton
@onready var quit_btn: Button = $Panel/VBox/QuitToMenuButton


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	resume_btn.pressed.connect(_on_resume)
	save_btn.pressed.connect(_on_save)
	load_btn.pressed.connect(_on_load)
	settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit_to_menu)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if visible:
			_on_resume()
		else:
			_show_pause()


func _show_pause() -> void:
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	GameManager.current_state = GameManager.GameState.PAUSED


func _on_resume() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false
	GameManager.current_state = GameManager.GameState.PLAYING


func _on_save() -> void:
	SaveManager.save_game(1)
	DialogueManager.show_subtitle("", "Game saved.")


func _on_load() -> void:
	if SaveManager.has_save(1):
		SaveManager.load_game(1)
		_on_resume()


func _on_settings() -> void:
	pass  # Settings submenu placeholder


func _on_quit_to_menu() -> void:
	get_tree().paused = false
	GameManager.current_state = GameManager.GameState.MENU
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
