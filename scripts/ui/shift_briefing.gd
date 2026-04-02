extends Control
## Shift briefing screen shown before shift starts
## Displays objectives, warnings, and story information

# ============================================================================
# STATE
# ============================================================================

signal briefing_complete

var shift_number: int = 1

# ============================================================================
# REFERENCES
# ============================================================================

@onready var shift_number_label: Label = $Panel/ShiftNumberLabel
@onready var objectives_list: RichTextLabel = $Panel/ObjectivesList
@onready var story_text: RichTextLabel = $Panel/StoryText
@onready var start_button: Button = $Panel/StartButton

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)

func display_briefing(shift_num: int) -> void:
	"""Display shift briefing"""
	shift_number = shift_num

	# Update shift number
	if shift_number_label:
		shift_number_label.text = "SHIFT %d BRIEFING" % shift_number

	# Display objectives
	_display_objectives()

	# Display story for this shift
	_display_story()

	# Show the screen
	show()

# ============================================================================
# CONTENT
# ============================================================================

func _display_objectives() -> void:
	"""Display shift objectives"""
	if not objectives_list:
		return

	var objectives_text = "[b]SHIFT OBJECTIVES:[/b]\n\n"

	# Standard objectives
	objectives_text += "• Serve at least 5 customers at the register\n"
	objectives_text += "• Check in 2 motel guests\n"
	objectives_text += "• Restock the convenience store\n"
	objectives_text += "• Clean the public restrooms\n"

	# Chapter-specific objectives
	match shift_number:
		2:
			objectives_text += "\n[color=yellow]• Check security cameras regularly[/color]\n"
		3:
			objectives_text += "\n[color=yellow]• Monitor power grid status[/color]\n"
			objectives_text += "\n[color=yellow]• Report any anomalies[/color]\n"
		4:
			objectives_text += "\n[color=orange]• Investigate Room 4 activity[/color]\n"
		5:
			objectives_text += "\n[color=red]• Survive until 6 AM[/color]\n"

	objectives_list.text = objectives_text

func _display_story() -> void:
	"""Display story text for this shift"""
	if not story_text:
		return

	var story_messages = {
		1: "Welcome to EXIT 13. Your shift runs from 10 PM to 6 AM. Keep the place running, serve customers, and don't ask questions about Room 4.\n\nIt's your first night. Keep it simple.",
		2: "You're back for night two. Some of the regulars might seem... off. Don't worry about it.\n\nOne of the previous night auditors left suddenly. No one knows why.",
		3: "There have been reports of electrical issues. The breaker panel is in the back if you need it.\n\nTry not to be alone in the dark.",
		4: "A guest is insisting they have a reservation for Room 4. You know that's impossible. Room 4 has been boarded up for years.\n\nDon't open that door.",
		5: "This is your last shift. Make it to morning and you're free.\n\nThey're all watching now."
	}

	story_text.text = story_messages.get(shift_number, "Another night at EXIT 13.")

# ============================================================================
# CONTROLS
# ============================================================================

func _on_start_button_pressed() -> void:
	"""Start the shift"""
	briefing_complete.emit()
	hide()
