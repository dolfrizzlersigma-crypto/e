## DialogueManager - Handles subtitle display and dialogue sequences.
## Manages dialogue queues, speaker identification, and timed display.
extends Node

# --- Signals ---
signal dialogue_started(dialogue_id: String)
signal line_displayed(speaker: String, text: String)
signal dialogue_ended(dialogue_id: String)
signal choice_presented(choices: Array[Dictionary])
signal choice_made(choice_index: int, choice_data: Dictionary)

# --- State ---
var is_dialogue_active: bool = false
var current_dialogue_id: String = ""
var current_lines: Array[Dictionary] = []
var current_line_index: int = 0
var line_timer: float = 0.0
var waiting_for_choice: bool = false

# --- Configuration ---
const DEFAULT_LINE_DURATION: float = 4.0
const CHARS_PER_SECOND: float = 30.0


func _process(delta: float) -> void:
	if not is_dialogue_active or waiting_for_choice:
		return

	line_timer -= delta
	if line_timer <= 0.0:
		_advance_line()


## Start a dialogue sequence.
## lines format: [{"speaker": "Name", "text": "...", "duration": 3.0}, ...]
func start_dialogue(dialogue_id: String, lines: Array[Dictionary]) -> void:
	current_dialogue_id = dialogue_id
	current_lines = lines
	current_line_index = -1
	is_dialogue_active = true
	waiting_for_choice = false
	dialogue_started.emit(dialogue_id)
	_advance_line()


## Skip to the next line or end dialogue.
func advance() -> void:
	if waiting_for_choice:
		return
	if line_timer > 0.5:
		line_timer = 0.0  # Quick-skip current line
	else:
		_advance_line()


## Make a choice during a choice dialogue.
func select_choice(index: int) -> void:
	if not waiting_for_choice:
		return
	if index < 0:
		return

	var line := current_lines[current_line_index]
	var choices: Array = line.get("choices", [])
	if index >= choices.size():
		return

	var choice_data: Dictionary = choices[index]
	waiting_for_choice = false
	choice_made.emit(index, choice_data)

	# If choice has a consequence, record it
	if choice_data.has("story_flag"):
		GameManager.set_story_flag(choice_data["story_flag"], choice_data.get("flag_value", true))
	if choice_data.has("ending_category"):
		GameManager.record_choice(
			current_dialogue_id + "_choice_" + str(index),
			choice_data["ending_category"],
			choice_data.get("weight", 1.0)
		)

	# Continue to next line after choice
	_advance_line()


## End the current dialogue immediately.
func end_dialogue() -> void:
	is_dialogue_active = false
	waiting_for_choice = false
	var id := current_dialogue_id
	current_dialogue_id = ""
	current_lines.clear()
	current_line_index = 0
	dialogue_ended.emit(id)


## Create a simple subtitle (no full dialogue sequence).
func show_subtitle(speaker: String, text: String, duration: float = -1.0) -> void:
	if duration < 0:
		duration = maxf(text.length() / CHARS_PER_SECOND, 2.0)
	line_displayed.emit(speaker, text)
	# Auto-clear after duration
	get_tree().create_timer(duration).timeout.connect(func():
		if not is_dialogue_active:
			line_displayed.emit("", "")
	)


# --- Private ---

func _advance_line() -> void:
	current_line_index += 1
	if current_line_index >= current_lines.size():
		end_dialogue()
		return

	var line := current_lines[current_line_index]
	var speaker: String = line.get("speaker", "")
	var text: String = line.get("text", "")

	# Check if this is a choice line
	if line.has("choices"):
		waiting_for_choice = true
		line_displayed.emit(speaker, text)
		choice_presented.emit(line["choices"])
		return

	# Calculate duration
	var duration: float = line.get("duration", -1.0)
	if duration < 0:
		duration = maxf(text.length() / CHARS_PER_SECOND, DEFAULT_LINE_DURATION)

	line_timer = duration
	line_displayed.emit(speaker, text)
