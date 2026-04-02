extends Node
## Save/Load system for game persistence
## Handles save files, autosave, and data serialization

const SAVE_DIR = "user://saves/"
const SAVE_EXTENSION = ".sav"
const AUTOSAVE_INTERVAL = 300.0 # 5 minutes
const MAX_SAVE_SLOTS = 5

var autosave_timer: float = 0.0
var autosave_enabled: bool = true

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	_ensure_save_directory()
	print("SaveSystem initialized")

func _process(delta: float) -> void:
	if autosave_enabled and GameManager.current_state == GameManager.GameState.GAMEPLAY:
		autosave_timer += delta
		if autosave_timer >= AUTOSAVE_INTERVAL:
			autosave()
			autosave_timer = 0.0

# ============================================================================
# SAVE OPERATIONS
# ============================================================================

func save_game(slot: int = 0) -> bool:
	"""Save the current game state to a slot"""
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		push_error("Invalid save slot: %d" % slot)
		return false

	var save_data = _collect_save_data()
	var file_path = _get_save_path(slot)

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file: %s" % file_path)
		return false

	var json_string = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()

	print("Game saved to slot %d" % slot)
	EventBus.game_saved.emit()
	return true

func load_game(slot: int = 0) -> bool:
	"""Load a game from a save slot"""
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		push_error("Invalid save slot: %d" % slot)
		return false

	var file_path = _get_save_path(slot)
	if not FileAccess.file_exists(file_path):
		push_error("Save file does not exist: %s" % file_path)
		return false

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open save file: %s" % file_path)
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("Failed to parse save file")
		return false

	var save_data = json.data
	_apply_save_data(save_data)

	print("Game loaded from slot %d" % slot)
	EventBus.game_loaded.emit()
	return true

func delete_save(slot: int) -> bool:
	"""Delete a save file"""
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		return false

	var file_path = _get_save_path(slot)
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
		print("Save slot %d deleted" % slot)
		return true
	return false

func autosave() -> void:
	"""Perform an autosave"""
	if save_game(0):
		print("Autosaved")

# ============================================================================
# SAVE DATA COLLECTION
# ============================================================================

func _collect_save_data() -> Dictionary:
	"""Collect all data that needs to be saved"""
	return {
		"version": "1.0.0",
		"timestamp": Time.get_unix_time_from_system(),

		# Game state
		"current_chapter": GameManager.current_chapter,
		"current_shift": GameManager.current_shift,
		"current_mode": GameManager.current_mode,
		"story_flags": GameManager.story_flags,
		"ending_conditions": GameManager.ending_conditions,
		"completed_shifts": GameManager.completed_shifts,
		"unlocked_endings": GameManager.unlocked_endings,

		# Player state (will be populated by player controller)
		"player_position": Vector3.ZERO,
		"player_rotation": Vector3.ZERO,
		"player_stats": {
			"fatigue": 0.0,
			"stress": 0.0,
			"composure": 100.0,
			"reputation": 50.0
		},

		# Inventory
		"inventory_items": [],
		"equipped_item": "",

		# Facility state
		"facility_upgrades": [],
		"power_state": {},
		"room_occupancy": {},
		"facility_condition": 100.0,

		# Financial
		"cash_on_hand": 500.0,
		"total_earnings": 0.0,
		"total_expenses": 0.0,

		# Evidence & Story
		"collected_documents": [],
		"cctv_evidence": [],
		"audio_logs_found": [],

		# Endless mode (if applicable)
		"endless_high_score": 0,
		"endless_unlocks": []
	}

func _apply_save_data(save_data: Dictionary) -> void:
	"""Apply loaded save data to game state"""
	# Game state
	GameManager.current_chapter = save_data.get("current_chapter", 1)
	GameManager.current_shift = save_data.get("current_shift", 1)
	GameManager.current_mode = save_data.get("current_mode", GameManager.GameMode.STORY)
	GameManager.story_flags = save_data.get("story_flags", {})
	GameManager.ending_conditions = save_data.get("ending_conditions", {})
	GameManager.completed_shifts = save_data.get("completed_shifts", [])
	GameManager.unlocked_endings = save_data.get("unlocked_endings", [])

	# Other systems will retrieve their data from the save_data dictionary
	# when they initialize

# ============================================================================
# SAVE INFO
# ============================================================================

func get_save_info(slot: int) -> Dictionary:
	"""Get information about a save file without loading it"""
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		return {}

	var file_path = _get_save_path(slot)
	if not FileAccess.file_exists(file_path):
		return {}

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_string) != OK:
		return {}

	var save_data = json.data
	return {
		"exists": true,
		"timestamp": save_data.get("timestamp", 0),
		"chapter": save_data.get("current_chapter", 1),
		"shift": save_data.get("current_shift", 1),
		"mode": save_data.get("current_mode", 0)
	}

func has_any_save() -> bool:
	"""Check if any save files exist"""
	for i in range(MAX_SAVE_SLOTS):
		if FileAccess.file_exists(_get_save_path(i)):
			return true
	return false

# ============================================================================
# UTILITY
# ============================================================================

func _ensure_save_directory() -> void:
	"""Create save directory if it doesn't exist"""
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func _get_save_path(slot: int) -> String:
	"""Get the file path for a save slot"""
	return SAVE_DIR + "save_" + str(slot) + SAVE_EXTENSION
