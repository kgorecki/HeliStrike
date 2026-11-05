# Setup

HeliStrike runs entirely in the Godot editor or the Godot binary. There is no `npm`, Python, or C++ build.

## Requirements

- **Godot 4.6.1**, official build, with the Forward Plus renderer and Jolt Physics. The project feature tag is `4.6`. The main menu footer reads `GODOT 4.6.1`.
- A desktop OS. The window defaults to 1920×1080 and can switch to fullscreen from the settings panel.
- No GPU feature flags beyond what Forward Plus needs (Vulkan, Metal, or D3D12). Do not switch the project to the Compatibility renderer without retesting lighting, glow, and SSAO.

Download Godot from [https://godotengine.org/download](https://godotengine.org/download) and install the standard editor binary. On macOS that is `Godot.app`.

## Environment variables

None. The game does not read `OS.get_environment` and does not ship a `.env` file. Settings and saves go to Godot’s `user://` folder, which is chosen by the engine from the project name `HeliStrike`.

| OS | Settings and save directory |
| --- | --- |
| macOS | `~/Library/Application Support/Godot/app_userdata/HeliStrike/` |
| Linux | `~/.local/share/godot/app_userdata/HeliStrike/` |
| Windows | `%APPDATA%\Godot\app_userdata\HeliStrike\` |

Files inside that directory:

- `HeliStrike_settings.json` — mouse, fullscreen, bindings, selected aircraft. Written on each settings change and each rebind.
- `HeliStrike_save.json` — mission snapshot. Written from the main menu or the pause menu. Removed when the mission is completed.

## Open the project

1. Start Godot.
2. Import or open the folder that contains `project.godot` (`HeliStrike/`).
3. Wait for the first import. Godot writes `.godot/`. That directory is gitignored.

From a terminal, if `godot` is on `PATH`:

```bash
godot --path . --editor
```

On macOS, if you only have the app bundle:

```bash
open -a Godot --args --path "$PWD" --editor
```

## Run

In the editor, press **F5** or click **Play**. The main scene is `res://scenes/ui/main_menu.tscn`.

From a terminal, in the project root:

```bash
godot --path .
```

Quit from the main menu, or stop the process. There is no separate server to start.

A one-shot boot check that exits after the first frames:

```bash
godot --path . --quit-after 2
```

## Play loop to verify a build

1. **New Game** opens the briefing.
2. **Select Aircraft**, then **Launch** (the hangar start control) loads the mission at the FOB pad.
3. **Esc** pauses. **Save Game** writes `HeliStrike_save.json`.
4. Abort to the menu. **Continue** should put you back in the mission with the same target damage and aircraft state.
5. **Settings** on the menu should persist mouse steering, invert Y, sensitivity, and fullscreen across restarts.

Default flight binds, before any rebind: **W / S** collective, **arrows** cyclic, **A / D** yaw, **mouse** cyclic when mouse steering is on, **Space or left mouse** cannon, **F or right mouse** missile, **C** camera, **Esc** pause. Rebinding is on the pause menu under **Controls**.

## Export

No `export_presets.cfg` is committed. To ship a build:

1. Install Godot’s export templates for the same 4.6.x version (**Editor → Manage Export Templates**).
2. **Project → Export…**, add a preset for the target OS, and export.
3. Keep signing keys and `export_credentials.cfg` out of git. That filename is already in `.gitignore`.

There is no project script, Makefile, or CI job that exports a binary.

## Editor notes

- Scripts are the source of truth. The four scenes only attach their root script. Changing a screen means editing the matching `.gd` file.
- Global class names (`Helicopter`, `Hud`, `WorldBuilder`, and the rest) come from `class_name`. If a class is missing after a rename, use **Project → Reload Current Project** so `.godot/global_script_class_cache.cfg` refreshes.
- Jolt is selected under **Project → Project Settings → Physics → 3D → Physics Engine**. Leaving that on Godot Physics changes collision feel. Keep Jolt unless you are intentionally comparing engines.
- Audio and meshes are generated in code, so a clean checkout has no asset import step beyond `icon.svg`.
