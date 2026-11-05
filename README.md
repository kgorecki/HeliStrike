# HeliStrike

Military attack-helicopter flight game built in Godot 4.6. Lift from a forward arming point, fly a procedurally generated desert, and destroy every marked ground target in Operation Iron Hawk.

Three airframes are available from the hangar: the AH-64E Apache (4 pylons), the Bell 222 (3), and the AH-6 Little Bird (2). After the aircraft, you mount a store on each pylon. Stores are single missiles or rocket pods, with their own damage, range, and guidance. The flight model uses collective, cyclic, and pedals, with cockpit and chase cameras, a lock-on reticle, and a drawn HUD.

## Run

Install [Godot 4.6](https://godotengine.org/download) (4.6.1 matches the in-game footer). Open this folder in the editor and press **F5**, or from the project root:

```bash
godot --path .
```

The window opens at 1920×1080. Fullscreen, mouse steering, invert Y, and sensitivity are in **Settings** on the main menu. There are no environment variables and no extra build step.

Saves and settings are written under Godot’s user data folder for the project name `HeliStrike`:

| Platform | Path |
| --- | --- |
| macOS | `~/Library/Application Support/Godot/app_userdata/HeliStrike/` |
| Linux | `~/.local/share/godot/app_userdata/HeliStrike/` |
| Windows | `%APPDATA%\Godot\app_userdata\HeliStrike\` |

**Continue** resumes an in-memory mission or `HeliStrike_save.json`. Clearing every target deletes that save.

## Play

1. **New Game** opens the Operation Iron Hawk briefing.
2. **Select Aircraft** in the hangar. Left and right arrows cycle airframes.
3. **Select Ordnance** mounts one store on each pylon. Click a store to load the highlighted pylon, or use the arrows. **Launch** starts the mission.
4. Destroy the tanks, SAMs, radars, and the command bunker. Keys **1-4** select a pylon. Each trigger fires one round from that store. Guided missiles home after the reticle finishes locking. Hydra rockets are unguided and short-range. The cannon is for close targets.
5. **Esc** pauses. Save, rebind keys, or abort from that menu.

A hard landing with the collective low destroys the aircraft. Winning returns you to the main menu with the mission cleared.

## Default controls

Rebind any of these from the pause menu under **Controls**. Each action has two slots.

| Action | Default |
| --- | --- |
| Collective | W / S, or mouse wheel |
| Cyclic (pitch and roll) | Arrow keys. Mouse if mouse steering is on |
| Yaw | A / D |
| Cannon | Space or left mouse |
| Missile | F or right mouse. Fires one round from the selected pylon |
| Select pylon | 1-4, matching the pylon number |
| Camera | C |
| Pause | Esc |

## Project layout

Scenes are entry points. Gameplay, UI, terrain, and audio are built in GDScript.

```
scenes/ui/          Main menu, briefing, hangar
scenes/world/       Mission
scripts/helicopter/ Flight model, airframe meshes, aircraft stats
scripts/world/      Mission flow and terrain
scripts/weapons/    Cannon rounds and missiles
scripts/ui/         HUD, controls, theme
scripts/autoload/   GameState (saves, settings, bindings)
```

Meshes, the heightmap, and sound effects are generated at runtime. `icon.svg` is the only imported asset.

## Docs

- [Architecture](docs/architecture.md) — modules, scene flow, combat, and saves
- [Tech stack](docs/tech-stack.md) — engine choices and code patterns
- [Setup](docs/setup.md) — editor, CLI, user-data paths, and export
