extends Control
## Shift results screen shown after shift ends
## Displays performance, earnings, and story progression

# ============================================================================
# STATE
# ============================================================================

signal results_acknowledged

var results_data: Dictionary = {}

# ============================================================================
# REFERENCES
# ============================================================================

@onready var shift_title: Label = $Panel/ShiftTitle
@onready var performance_stats: RichTextLabel = $Panel/PerformanceStats
@onready var objectives_completed: Label = $Panel/ObjectivesCompleted
@onready var total_earnings: Label = $Panel/TotalEarnings
@onready var anomalies_detected: Label = $Panel/AnomaliesDetected
@onready var story_notes: RichTextLabel = $Panel/StoryNotes
@onready var continue_button: Button = $Panel/ContinueButton

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	hide()

func display_results(results: Dictionary) -> void:
	"""Display shift results"""
	results_data = results

	# Update title
	if shift_title:
		shift_title.text = "SHIFT %d COMPLETE" % results.get("shift_number", 1)

	# Display performance stats
	_display_performance()

	# Display objectives
	_display_objectives_status()

	# Display earnings
	_display_earnings()

	# Display anomalies
	_display_anomalies()

	# Story progression
	_display_story_notes()

	# Show screen
	show()

# ============================================================================
# CONTENT DISPLAY
# ============================================================================

func _display_performance() -> void:
	"""Display performance statistics"""
	if not performance_stats:
		return

	var text = "[b]PERFORMANCE:[/b]\n\n"
	text += "Customers Served: %d\n" % results_data.get("customers_served", 0)
	text += "Guests Checked In: %d\n" % results_data.get("guests_checked_in", 0)
	text += "Incidents Handled: %d\n" % results_data.get("incidents", 0)

	performance_stats.text = text

func _display_objectives_status() -> void:
	"""Display objectives completion"""
	if not objectives_completed:
		return

	var completed = results_data.get("objectives_completed", 0)
	var failed = results_data.get("objectives_failed", 0)
	var total = completed + failed

	var percentage = 0.0
	if total > 0:
		percentage = (float(completed) / float(total)) * 100.0

	objectives_completed.text = "Objectives: %d/%d (%.0f%%)" % [completed, total, percentage]

	# Color code based on performance
	if percentage >= 80:
		objectives_completed.modulate = Color.GREEN
	elif percentage >= 50:
		objectives_completed.modulate = Color.YELLOW
	else:
		objectives_completed.modulate = Color.RED

func _display_earnings() -> void:
	"""Display total earnings"""
	if not total_earnings:
		return

	var earnings = results_data.get("revenue", 0.0)
	total_earnings.text = "Earnings: $%.2f" % earnings

func _display_anomalies() -> void:
	"""Display anomalies detected"""
	if not anomalies_detected:
		return

	var anomaly_count = results_data.get("anomalies", 0)

	if anomaly_count == 0:
		anomalies_detected.text = "Anomalies: None Detected"
		anomalies_detected.modulate = Color.GREEN
	else:
		anomalies_detected.text = "Anomalies: %d Detected" % anomaly_count
		anomalies_detected.modulate = Color.RED

func _display_story_notes() -> void:
	"""Display story progression notes"""
	if not story_notes:
		return

	var shift_num = results_data.get("shift_number", 1)

	var notes = {
		1: "[color=gray]That wasn't so bad. Just a quiet night at a rest stop.\n\nSomething felt off about Room 4 though...[/color]",
		2: "[color=gray]The customers were strange tonight. One of them knew your name.\n\nYou never told anyone your name.[/color]",
		3: "[color=gray]The lights keep flickering. The CCTV showed something that shouldn't be possible.\n\nYou're starting to understand why the last auditor quit.[/color]",
		4: "[color=orange]Someone was knocking from inside Room 4. But it's been boarded up for years.\n\nYou didn't open it. Good.[/color]",
		5: "[color=red]You made it. You survived all five shifts.\n\nBut EXIT 13 remembers you now.\n\n[b]THE END...?[/b][/color]"
	}

	story_notes.text = notes.get(shift_num, "[color=gray]Another shift complete.[/color]")

# ============================================================================
# CONTROLS
# ============================================================================

func _on_continue_pressed() -> void:
	"""Continue to next screen"""
	results_acknowledged.emit()

	# Advance chapter/shift
	GameManager.advance_chapter()

	# Return to main menu or start next shift
	if GameManager.current_shift >= 5:
		# Game complete - show ending
		GameManager.trigger_ending(GameManager.Ending.SURVIVOR)
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	else:
		# Next shift
		hide()
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
