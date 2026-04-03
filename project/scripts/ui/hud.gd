## HUD - Heads-up display showing time, objectives, subtitles, and interaction prompts.
## Implements immersive stat effects (distortion, heartbeat indicators).
class_name HUD
extends CanvasLayer

# --- Node References ---
@onready var root_control: Control = $Control
@onready var time_label: Label = $Control/TopBar/TimeLabel
@onready var shift_label: Label = $Control/TopBar/ShiftLabel
@onready var weather_label: Label = $Control/TopBar/WeatherLabel
@onready var cash_label: Label = $Control/TopBar/CashLabel
@onready var interaction_prompt: Label = $Control/InteractionPrompt
@onready var subtitle_panel: PanelContainer = $Control/SubtitlePanel
@onready var subtitle_label: RichTextLabel = $Control/SubtitlePanel/SubtitleLabel
@onready var objective_list: VBoxContainer = $Control/ObjectivePanel/ObjectiveList
@onready var choice_panel: VBoxContainer = $Control/ChoicePanel

# --- State ---
var _subtitle_timer: float = 0.0
var _player_ref: PlayerController = null


func _ready() -> void:
	# Connect to dialogue system
	DialogueManager.line_displayed.connect(_on_dialogue_line)
	DialogueManager.choice_presented.connect(_on_choices_presented)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

	# Connect to objective system
	ObjectiveManager.objective_added.connect(_on_objective_added)
	ObjectiveManager.objective_completed.connect(_on_objective_completed)
	ObjectiveManager.objective_failed.connect(_on_objective_failed)

	# Connect to game state
	GameManager.money_changed.connect(_on_money_changed)

	# Connect to weather
	WeatherManager.weather_changed.connect(_on_weather_changed)
	WeatherManager.storm_warning_issued.connect(_on_storm_warning)


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	_update_time_display()
	_update_interaction_prompt()
	_update_subtitle_timer(delta)
	_update_immersive_effects(delta)


## Set the player reference for interaction prompt updates.
func set_player(player: PlayerController) -> void:
	_player_ref = player


# --- UI Update Methods ---

func _update_time_display() -> void:
	var hour := GameManager.in_game_hour
	var minute := GameManager.in_game_minute
	var period := "AM" if hour < 12 else "PM"
	var display_hour := hour % 12
	if display_hour == 0:
		display_hour = 12
	time_label.text = "%d:%02d %s" % [display_hour, minute, period]
	shift_label.text = "Shift %d" % GameManager.current_shift


func _update_interaction_prompt() -> void:
	if _player_ref and _player_ref.looking_at:
		var target = _player_ref.looking_at
		if target.has_method("get_prompt"):
			var prompt_text: String = target.get_prompt()
			if prompt_text != "":
				interaction_prompt.text = "[E] " + prompt_text
				interaction_prompt.visible = true
				return
	interaction_prompt.visible = false


func _update_subtitle_timer(delta: float) -> void:
	if _subtitle_timer > 0:
		_subtitle_timer -= delta
		if _subtitle_timer <= 0:
			subtitle_panel.visible = false


func _update_immersive_effects(_delta: float) -> void:
	# Composure loss causes HUD distortion
	if GameManager.composure < 40.0:
		var distort := (40.0 - GameManager.composure) / 40.0
		root_control.modulate = Color(1.0, 1.0 - distort * 0.1, 1.0 - distort * 0.1)
	else:
		root_control.modulate = Color.WHITE

	# Low electrical stability causes flicker effect on HUD
	if GameManager.electrical_stability < 30.0:
		if randf() < 0.05:
			root_control.visible = false
			get_tree().create_timer(0.1).timeout.connect(func(): root_control.visible = true)


# --- Signal Handlers ---

func _on_dialogue_line(speaker: String, text: String) -> void:
	if text == "":
		subtitle_panel.visible = false
		return

	var formatted := ""
	if speaker != "":
		formatted = "[b]%s:[/b] %s" % [speaker, text]
	else:
		formatted = "[i]%s[/i]" % text

	subtitle_label.text = formatted
	subtitle_panel.visible = true
	_subtitle_timer = maxf(text.length() / 20.0, 3.0)


func _on_choices_presented(choices: Array[Dictionary]) -> void:
	# Clear old choices
	for child in choice_panel.get_children():
		child.queue_free()

	# Create choice buttons
	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = "%d. %s" % [i + 1, choice.get("text", "...")]
		var idx := i
		btn.pressed.connect(func(): _on_choice_selected(idx))
		choice_panel.add_child(btn)

	choice_panel.visible = true


func _on_choice_selected(index: int) -> void:
	choice_panel.visible = false
	DialogueManager.select_choice(index)


func _on_dialogue_ended(_dialogue_id: String) -> void:
	choice_panel.visible = false


func _on_objective_added(objective: Dictionary) -> void:
	_refresh_objective_list()


func _on_objective_completed(_objective_id: String) -> void:
	_refresh_objective_list()


func _on_objective_failed(_objective_id: String) -> void:
	_refresh_objective_list()


func _on_money_changed(amount: float) -> void:
	cash_label.text = "$%.2f" % amount


func _on_weather_changed(_weather: int) -> void:
	weather_label.text = WeatherManager.get_weather_description().split(".")[0]


func _on_storm_warning(description: String) -> void:
	_on_dialogue_line("WEATHER ALERT", description)


func _refresh_objective_list() -> void:
	# Clear old objectives
	for child in objective_list.get_children():
		child.queue_free()

	# Add current objectives
	var objectives := ObjectiveManager.get_visible_objectives()
	for obj in objectives:
		var label := Label.new()
		var prefix := "[ ] " if obj["progress"] < obj["target"] else "[X] "
		label.text = prefix + obj["title"]
		if obj.get("type") == "optional":
			label.modulate = Color(0.7, 0.7, 0.7)
		objective_list.add_child(label)
