extends Node
## Central event bus for decoupled communication between systems
## All major gameplay events are signaled through this singleton

# ============================================================================
# GAMEPLAY SIGNALS
# ============================================================================

## Emitted when a shift begins
@warning_ignore("unused_signal")
signal shift_started(shift_number: int)

## Emitted when a shift ends with results
@warning_ignore("unused_signal")
signal shift_ended(results: Dictionary)

## Emitted when a task is completed
@warning_ignore("unused_signal")
signal task_completed(task_id: String)

## Emitted when a customer arrives at the plaza
@warning_ignore("unused_signal")
signal customer_arrived(customer_data: Dictionary)

## Emitted when a motel guest checks in
@warning_ignore("unused_signal")
signal guest_checked_in(guest_data: Dictionary, room_number: int)

## Emitted when a guest checks out
@warning_ignore("unused_signal")
signal guest_checked_out(room_number: int)

## Emitted when a transaction is completed at register
@warning_ignore("unused_signal")
signal transaction_completed(amount: float, items: Array)

## Emitted when a fuel pump is activated
@warning_ignore("unused_signal")
signal pump_activated(pump_id: int)

## Emitted when a fuel pump completes
@warning_ignore("unused_signal")
signal pump_completed(pump_id: int, amount: float)

# ============================================================================
# HORROR SIGNALS
# ============================================================================

## Emitted when a horror event is triggered
@warning_ignore("unused_signal")
signal horror_event_triggered(event_id: String, intensity: int)

## Emitted when a power zone fails
@warning_ignore("unused_signal")
signal power_zone_failed(zone_name: String)

## Emitted when power is restored to a zone
@warning_ignore("unused_signal")
signal power_zone_restored(zone_name: String)

## Emitted when a power zone state changes
@warning_ignore("unused_signal")
signal power_zone_changed(zone_name: String, is_active: bool)

## Emitted when a complete power outage occurs
@warning_ignore("unused_signal")
signal power_outage()

## Emitted when an anomaly is detected
@warning_ignore("unused_signal")
signal anomaly_detected(type: String, location: Vector3)

## Emitted when CCTV shows a contradiction
@warning_ignore("unused_signal")
signal cctv_anomaly(camera_id: int, description: String)

## Emitted when radio interference occurs
@warning_ignore("unused_signal")
signal radio_interference(message: String)

# ============================================================================
# PLAYER SIGNALS
# ============================================================================

## Emitted when player composure changes
@warning_ignore("unused_signal")
signal player_composure_changed(new_value: float)

## Emitted when player stress changes
@warning_ignore("unused_signal")
signal player_stress_changed(new_value: float)

## Emitted when player fatigue changes
@warning_ignore("unused_signal")
signal player_fatigue_changed(new_value: float)

## Emitted when player inventory changes
@warning_ignore("unused_signal")
signal inventory_changed(items: Array)

## Emitted when player interacts with object
@warning_ignore("unused_signal")
signal object_interacted(object_name: String)

# ============================================================================
# STORY SIGNALS
# ============================================================================

## Emitted when evidence is collected
@warning_ignore("unused_signal")
signal evidence_collected(evidence_id: String)

## Emitted when a story choice is made
@warning_ignore("unused_signal")
signal choice_made(choice_id: String, option: String)

## Emitted when a chapter advances
@warning_ignore("unused_signal")
signal chapter_advanced(chapter_number: int)

## Emitted when an ending is unlocked
@warning_ignore("unused_signal")
signal ending_unlocked(ending_type: String)

## Emitted when dialogue starts
@warning_ignore("unused_signal")
signal dialogue_started(character_name: String)

## Emitted when dialogue ends
@warning_ignore("unused_signal")
signal dialogue_ended()

# ============================================================================
# SYSTEM SIGNALS
# ============================================================================

## Emitted when weather changes
@warning_ignore("unused_signal")
signal weather_changed(weather_type: String, intensity: float)

## Emitted when time advances
@warning_ignore("unused_signal")
signal time_advanced(hours: int, minutes: int)

## Emitted when game is saved
@warning_ignore("unused_signal")
signal game_saved()

## Emitted when game is loaded
@warning_ignore("unused_signal")
signal game_loaded()

## Emitted when an upgrade is purchased
@warning_ignore("unused_signal")
signal upgrade_purchased(upgrade_id: String)

## Emitted when facility takes damage
@warning_ignore("unused_signal")
signal facility_damaged(damage_type: String, amount: float)

## Emitted when facility is repaired
@warning_ignore("unused_signal")
signal facility_repaired(repair_type: String)
