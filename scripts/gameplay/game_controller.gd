extends Node3D
## Main game controller
## Manages HUD updates, FPS counter, and game flow

@onready var time_display = $UI/HUD/TimeDisplay
@onready var fps_counter = $UI/HUD/FPSCounter
@onready var objective_tracker = $UI/HUD/ObjectiveTracker
@onready var shift_manager = $Systems/ShiftManager

func _ready() -> void:
	# Connect to shift manager signals
	if shift_manager:
		shift_manager.shift_time_updated.connect(_on_time_updated)
		shift_manager.objective_added.connect(_on_objective_added)
		shift_manager.objective_completed.connect(_on_objective_completed)

	# Check FPS counter setting
	if Settings.get_setting("show_fps"):
		fps_counter.visible = true

	# Start the first shift
	if GameManager.current_mode == GameManager.GameMode.STORY:
		shift_manager.start_shift(GameManager.current_shift)

func _process(_delta: float) -> void:
	if fps_counter.visible:
		fps_counter.text = "FPS: %d" % Engine.get_frames_per_second()

func _on_time_updated(hours: int, minutes: int) -> void:
	"""Update time display"""
	if time_display:
		time_display.text = "%02d:%02d" % [hours, minutes]

func _on_objective_added(objective: Dictionary) -> void:
	"""Add objective to tracker"""
	var label = Label.new()
	label.name = objective["id"]
	label.text = "☐ %s (%d/%d)" % [objective["description"], objective["current"], objective["target"]]
	label.add_theme_font_size_override("font_size", 16)
	objective_tracker.add_child(label)

func _on_objective_completed(objective_id: String) -> void:
	"""Mark objective as completed"""
	var label = objective_tracker.get_node_or_null(objective_id)
	if label:
		label.queue_free()
