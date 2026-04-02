# EXIT 13: NIGHT AUDITOR

> *A first-person horror-management game for Godot 4*

You work the graveyard shift at a lonely highway service plaza called **Exit 13**. The highway keeps sending back people who should not still be traveling.

## Quick Start

1. Open the `project/` folder in Godot 4.2+
2. Run the project — Main Menu loads automatically
3. Click **New Game - Story Mode** to start your first shift

## Project Structure

```
project/
├── project.godot              # Engine config, input maps, autoloads
├── assets/                    # Audio, models, textures, fonts, shaders
├── data/
│   ├── dialogue/              # Story dialogue + complete 10-shift dialogue
│   ├── items/                 # Item database (16+ items)
│   ├── shifts/                # Complete shift data for all 10 shifts
│   └── story/                 # Story structure (6 chapters, 4 endings)
├── scenes/
│   ├── levels/service_plaza.tscn   # Main game level
│   ├── ui/                         # Main menu, HUD, pause menu, settings
│   └── characters/player.tscn     # First-person player
├── scripts/
│   ├── autoload/   # 9 singletons (GameManager, EventDirector, SaveManager, SettingsManager, etc.)
│   ├── player/     # First-person controller (sprint, crouch, lean, flashlight)
│   ├── systems/    # Cash register, motel, doors, power grid, CCTV, shift, inventory,
│   │               # footstep system, spatial audio, optimization, endless mode, streamer mode
│   ├── horror/     # 9 scripted horror events (flicker, phantom car, blackout, receipt,
│   │               # CCTV doppelganger, Room 4, radio voice, lost-and-found, mass arrival)
│   ├── npc/        # Customer NPC behavior
│   ├── environment/# Level orchestration, ambient audio zones, environment builder
│   └── ui/         # Menu, HUD, pause scripts
└── saves/
```

## Controls

| Key | Action | Key | Action |
|-----|--------|-----|--------|
| WASD | Move | E | Interact |
| Mouse | Look | F | Flashlight |
| Shift | Sprint | Tab | Inventory |
| Ctrl | Crouch | J | Journal |
| Q/R | Lean | Esc | Pause |
| LMB | Pick Up | G | Drop Item |

## Game Modes

- **Story Mode**: 10 shifts across 6 chapters with 4 endings
- **Endless Mode**: Infinite procedural shifts with upgrades
- **Streamer Mode**: (Phase 2) Viewer-triggered events

## Built With

[Godot Engine 4](https://godotengine.org/) — GDScript
