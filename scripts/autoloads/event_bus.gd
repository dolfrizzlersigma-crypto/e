extends Node
## Central event bus for decoupled communication between systems
## All major gameplay events are signaled through this singleton

# ============================================================================
# GAMEPLAY SIGNALS
# ============================================================================

## Emitted when a shift begins
signal shift_started(shift_number: int)

## Emitted when a shift ends with results
signal shift_ended(results: Dictionary)

## Emitted when a task is completed
signal task_completed(task_id: String)

## Emitted when a customer arrives at the plaza
signal customer_arrived(customer_data: Dictionary)

## Emitted when a motel guest checks in
signal guest_checked_in(guest_data: Dictionary, room_number: int)

## Emitted when a guest checks out
signal guest_checked_out(room_number: int)

## Emitted when a transaction is completed at register
signal transaction_completed(amount: float, items: Array)

## Emitted when a fuel pump is activated
signal pump_activated(pump_id: int)

## Emitted when a fuel pump completes
signal pump_completed(pump_id: int, amount: float)

# ============================================================================
# HORROR SIGNALS
# ============================================================================

## Emitted when a horror event is triggered
signal horror_event_triggered(event_id: String, intensity: int)

## Emitted when a power zone fails
signal power_zone_failed(zone_name: String)

## Emitted when power is restored to a zone
signal power_zone_restored(zone_name: String)

## Emitted when an anomaly is detected
signal anomaly_detected(type: String, location: Vector3)

## Emitted when CCTV shows a contradiction
signal cctv_anomaly(camera_id: int, description: String)

## Emitted when radio interference occurs
signal radio_interference(message: String)

# ============================================================================
# PLAYER SIGNALS
# ============================================================================

## Emitted when player composure changes
signal player_composure_changed(new_value: float)

## Emitted when player stress changes
signal player_stress_changed(new_value: float)

## Emitted when player fatigue changes
signal player_fatigue_changed(new_value: float)

## Emitted when player inventory changes
signal inventory_changed(items: Array)

## Emitted when player interacts with object
signal object_interacted(object_name: String)

# ============================================================================
# STORY SIGNALS
# ============================================================================

## Emitted when evidence is collected
signal evidence_collected(evidence_id: String)

## Emitted when a story choice is made
signal choice_made(choice_id: String, option: String)

## Emitted when a chapter advances
signal chapter_advanced(chapter_number: int)

## Emitted when an ending is unlocked
signal ending_unlocked(ending_type: String)

## Emitted when dialogue starts
signal dialogue_started(character_name: String)

## Emitted when dialogue ends
signal dialogue_ended()

# ============================================================================
# SYSTEM SIGNALS
# ============================================================================

## Emitted when weather changes
signal weather_changed(weather_type: String, intensity: float)

## Emitted when time advances
signal time_advanced(hours: int, minutes: int)

## Emitted when game is saved
signal game_saved()

## Emitted when game is loaded
signal game_loaded()

## Emitted when an upgrade is purchased
signal upgrade_purchased(upgrade_id: String)

## Emitted when facility takes damage
signal facility_damaged(damage_type: String, amount: float)

## Emitted when facility is repaired
signal facility_repaired(repair_type: String)
