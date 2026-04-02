extends Control
## Main menu controller

@onready var continue_button = $VBoxContainer/ContinueButton
@onready var endless_button = $VBoxContainer/EndlessButton

func _ready() -> void:
	# Ensure mouse is visible and not captured in menu
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Check if save exists
	if not SaveSystem.has_any_save():
		continue_button.disabled = true

	# Check if endless mode is unlocked
	# For now, always enable it
	endless_button.disabled = false

	print("Main menu ready")

func _on_new_game_pressed() -> void:
	print("New Game button pressed")
	GameManager.start_new_game(GameManager.GameMode.STORY)
	GameManager.change_state(GameManager.GameState.GAMEPLAY)

	# Load the game scene
	var error = get_tree().change_scene_to_file("res://scenes/gameplay/main_game.tscn")
	if error != OK:
		push_error("Failed to load main_game.tscn: Error code %d" % error)
		print("ERROR: Could not load game scene!")

func _on_continue_pressed() -> void:
	print("Continue button pressed")
	if SaveSystem.load_game(0):
		GameManager.change_state(GameManager.GameState.GAMEPLAY)

		# Load the game scene
		var error = get_tree().change_scene_to_file("res://scenes/gameplay/main_game.tscn")
		if error != OK:
			push_error("Failed to load main_game.tscn: Error code %d" % error)
			print("ERROR: Could not load game scene!")
	else:
		print("ERROR: Failed to load save game")

func _on_endless_pressed() -> void:
	print("Endless Mode button pressed")
	GameManager.start_new_game(GameManager.GameMode.ENDLESS)
	GameManager.change_state(GameManager.GameState.GAMEPLAY)

	# Load the game scene
	var error = get_tree().change_scene_to_file("res://scenes/gameplay/main_game.tscn")
	if error != OK:
		push_error("Failed to load main_game.tscn: Error code %d" % error)
		print("ERROR: Could not load game scene!")

func _on_settings_pressed() -> void:
	# Open settings menu
	get_tree().change_scene_to_file("res://scenes/ui/settings_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
