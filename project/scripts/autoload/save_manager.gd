## SaveManager - Handles save/load operations with file I/O.
## Supports multiple save slots and autosave functionality.
extends Node

# --- Signals ---
signal save_completed(slot: int)
signal load_completed(slot: int)
signal save_failed(slot: int, error: String)
signal load_failed(slot: int, error: String)

# --- Constants ---
const SAVE_DIR := "user://saves/"
const SAVE_PREFIX := "exit13_save_"
const SAVE_EXTENSION := ".json"
const AUTOSAVE_SLOT := 0
const MAX_SLOTS := 5
const AUTOSAVE_INTERVAL := 120.0  # Seconds between autosaves

# --- State ---
var autosave_timer: float = 0.0
var autosave_enabled: bool = true


func _ready() -> void:
	_ensure_save_directory()


func _process(delta: float) -> void:
	if not autosave_enabled:
		return
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	autosave_timer += delta
	if autosave_timer >= AUTOSAVE_INTERVAL:
		autosave_timer = 0.0
		save_game(AUTOSAVE_SLOT)


## Save current game state to a slot.
func save_game(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		save_failed.emit(slot, "Invalid slot number")
		return false

	var save_data := {
		"timestamp": Time.get_datetime_string_from_system(),
		"game": GameManager.get_save_data(),
		"weather": WeatherManager.get_save_data(),
		"objectives": ObjectiveManager.get_save_data(),
		"upgrades": UpgradeManager.get_save_data(),
	}

	var path := _get_save_path(slot)
	var json_string := JSON.stringify(save_data, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var err_msg := "Failed to open save file: %s" % error_string(FileAccess.get_open_error())
		save_failed.emit(slot, err_msg)
		return false

	file.store_string(json_string)
	file.close()
	save_completed.emit(slot)
	return true


## Load game state from a slot.
func load_game(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		load_failed.emit(slot, "Invalid slot number")
		return false

	var path := _get_save_path(slot)
	if not FileAccess.file_exists(path):
		load_failed.emit(slot, "Save file not found")
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		var err_msg := "Failed to open save file: %s" % error_string(FileAccess.get_open_error())
		load_failed.emit(slot, err_msg)
		return false

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		load_failed.emit(slot, "Failed to parse save data")
		return false

	var save_data: Dictionary = json.data
	if not save_data.has("game"):
		load_failed.emit(slot, "Invalid save data format")
		return false

	# Restore all systems
	GameManager.load_save_data(save_data.get("game", {}))
	WeatherManager.load_save_data(save_data.get("weather", {}))
	ObjectiveManager.load_save_data(save_data.get("objectives", {}))
	UpgradeManager.load_save_data(save_data.get("upgrades", {}))

	load_completed.emit(slot)
	return true


## Check if a save slot has data.
func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_get_save_path(slot))


## Get metadata for a save slot without fully loading it.
func get_save_info(slot: int) -> Dictionary:
	var path := _get_save_path(slot)
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	file.close()

	var data: Dictionary = json.data
	return {
		"slot": slot,
		"timestamp": data.get("timestamp", "Unknown"),
		"shift": data.get("game", {}).get("shift", 0),
		"chapter": data.get("game", {}).get("chapter", 0),
		"mode": data.get("game", {}).get("mode", 0),
	}


## Delete a save slot.
func delete_save(slot: int) -> bool:
	var path := _get_save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		return true
	return false


## Get info for all save slots.
func get_all_save_info() -> Array[Dictionary]:
	var saves: Array[Dictionary] = []
	for i in MAX_SLOTS:
		var info := get_save_info(i)
		if not info.is_empty():
			saves.append(info)
	return saves


# --- Private ---

func _ensure_save_directory() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func _get_save_path(slot: int) -> String:
	return SAVE_DIR + SAVE_PREFIX + str(slot) + SAVE_EXTENSION
