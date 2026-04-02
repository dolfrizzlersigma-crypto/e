extends Control
## Pause menu controller

func _ready() -> void:
	visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause() -> void:
	"""Toggle pause state"""
	visible = !visible
	get_tree().paused = visible

	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_settings_pressed() -> void:
	# Open settings submenu
	get_tree().change_scene_to_file("res://scenes/ui/settings_menu.tscn")

func _on_save_pressed() -> void:
	SaveSystem.save_game(0)

	# Show confirmation
	var label = Label.new()
	label.text = "Game Saved!"
	label.position = Vector2(get_viewport_rect().size.x / 2 - 50, 50)
	add_child(label)

	await get_tree().create_timer(2.0).timeout
	label.queue_free()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
