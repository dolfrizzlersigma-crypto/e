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
├── data/                      # JSON data (items, shifts, story, dialogue)
├── scenes/
│   ├── levels/service_plaza.tscn   # Main game level
│   ├── ui/                         # Main menu, HUD, pause menu
│   └── characters/player.tscn     # First-person player
├── scripts/
│   ├── autoload/   # 8 singletons (GameManager, EventDirector, SaveManager, etc.)
│   ├── player/     # First-person controller (sprint, crouch, lean, flashlight)
│   ├── systems/    # Cash register, motel, doors, power grid, CCTV, shift, inventory
│   ├── horror/     # Scripted horror events (flicker, phantom car, blackout, receipt)
│   ├── npc/        # Customer NPC behavior
│   ├── environment/# Level orchestration, ambient audio zones
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
