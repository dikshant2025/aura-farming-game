# Aura: Farming & Survival Game

A top-down farming and survival game built in **Godot 4.4** with **GDScript**. Till soil, plant and water crops, fish, hunt, chop trees and cook, all while managing your energy.

Built as a team project for a game development course at Jacksonville State University. **I wrote the game's code (GDScript).**

## Features
- **Farming:** a soil grid where each tile tracks tilling, watering and crop growth over time
- **Data-driven crops** loaded from `Data/crops.json` through a `GameDB` script, so you can add crops without changing code
- **Tools:** hoe, watering can and seeds, swapped with hotkeys 1–7
- **Fishing, hunting (wild critters), tree chopping and a cooking station**
- **Energy system:** energy drains passively over time, and actions cost energy
- **Day cycle** driven by a `TimeManager` autoload
- HUD that updates from `PlayerState` signals, plus background music and sound effects

## How the code is organized
| Script | What it does |
|---|---|
| `PlayerState.gd` (autoload) | Player stats and energy; emits `stats_changed` |
| `TimeManager.gd` (autoload) | Advances crop growth and energy drain every frame |
| `GameManager.gd` | Loads crop data, connects the HUD, starts music |
| `SoilGrid.gd` / `SoilTile.gd` / `Farm.gd` | The farm grid and each tile's growth state |
| `Hoe.gd`, `WateringCan.gd`, `Seeds.gd` | Tool actions |
| `FishSpot.gd`, `HuntSpot.gd`, `TreeSpot.gd`, `CookStation.gd` | Gathering and crafting interactions |

## Run it
1. Install [Godot 4.4](https://godotengine.org/download).
2. Clone this repo, open Godot, click **Import**, and select `project.godot`.
3. Press **F5**.
