extends Control
## Main menu controller

@onready var continue_button = $VBoxContainer/ContinueButton
@onready var endless_button = $VBoxContainer/EndlessButton

func _ready() -> void:
	# Check if save exists
	if not SaveSystem.has_any_save():
		continue_button.disabled = true

	# Check if endless mode is unlocked
	# For now, always enable it
	endless_button.disabled = false

func _on_new_game_pressed() -> void:
	GameManager.start_new_game(GameManager.GameMode.STORY)
	GameManager.change_state(GameManager.GameState.GAMEPLAY)
	get_tree().change_scene_to_file("res://scenes/gameplay/main_game.tscn")

func _on_continue_pressed() -> void:
	if SaveSystem.load_game(0):
		GameManager.change_state(GameManager.GameState.GAMEPLAY)
		get_tree().change_scene_to_file("res://scenes/gameplay/main_game.tscn")

func _on_endless_pressed() -> void:
	GameManager.start_new_game(GameManager.GameMode.ENDLESS)
	GameManager.change_state(GameManager.GameState.GAMEPLAY)
	get_tree().change_scene_to_file("res://scenes/gameplay/main_game.tscn")

func _on_settings_pressed() -> void:
	# Open settings menu
	get_tree().change_scene_to_file("res://scenes/ui/settings_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
