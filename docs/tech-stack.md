# Tech stack

HeliStrike is a Godot game with no package manager, no third-party addons, and no runtime services. Everything ships in the engine or is generated in GDScript at runtime.

## Core technologies

| Piece | Choice | Where it shows up |
| --- | --- | --- |
| Engine | Godot 4.6 (UI footer cites 4.6.1) | `config/features` includes `"4.6"` |
| Language | GDScript, statically typed where it matters | `scripts/` |
| Renderer | Forward Plus | `config/features` includes `"Forward Plus"` |
| Physics | Jolt Physics, 3D | `project.godot` `[physics]` |
| Display | 1920×1080, `canvas_items` stretch, `expand` aspect | `[display]` |
| Anti-aliasing | MSAA 3D 2x, screen-space AA | `[rendering]` |
| Audio | Procedural `AudioStreamWAV`, 8-bit mono | `scripts/audio/sfx.gd` |
| Persistence | JSON via `FileAccess` and `JSON` | `user://HeliStrike_save.json`, `user://HeliStrike_settings.json` |
| Input | `InputMap` actions rebuilt from saved binding specs | `GameState` |

The project does not use C#, GDExtension, shaders written as `.gdshader` files, or imported game assets beyond `icon.svg`. Meshes are `BoxMesh`, `CylinderMesh`, `SphereMesh`, `PlaneMesh`, and `SurfaceTool` terrain. The sky is `ProceduralSkyMaterial`. Terrain shape comes from `FastNoiseLite`.

## Libraries

None. Do not add a dependency unless the engine cannot do the job. Godot built-ins used as the stand-in for a library layer:

- **Scene tree and groups** for finding the mission and living targets.
- **Signals** for crash, target destroyed, weapon fired, and controls closed.
- **`InputMap`** for rebindable actions. Default binds live in `GameState.default_bindings()`.
- **`CharacterBody3D`** with `MOTION_MODE_FLOATING` for the helicopter. It is not a rigid body.
- **`Area3D`** for projectiles. Hits are `body_entered` and `area_entered`, not raycasts.
- **`GPUParticles3D`** for explosions.
- **`Theme` overrides and `StyleBoxFlat`** through `ThemeUtil`, not a shared `.theme` resource.
- **`SystemFont`** (Menlo, Consolas, Courier New, monospace) instead of a bundled font file.

## Design patterns

**Autoload singletons.** `GameState` and `Sfx` are registered in `project.godot` and exist for the whole run. `GameState` is the only place that owns settings and the mission snapshot.

**Thin scenes, fat scripts.** Each `.tscn` is a root node plus one script. UI, terrain, aircraft, and effects are built in `_ready` or a `_build*` method. Preview helicopters (`HeliBuilder.build_model`) and flyable helicopters (`HeliBuilder.attach`) share airframe builders.

**Data catalog.** `HeliCatalog.spec()` returns a dictionary per airframe id. `HeliCatalog.apply()` copies combat and flight numbers onto a `Helicopter`. Adding an airframe means a new id in `IDS`, a `spec()` branch, and a matching builder path in `HeliBuilder`.

**Builder objects.** `WorldBuilder` and `HeliBuilder` are `RefCounted` and return or parent nodes. They are not in the tree.

**Memento save.** `Helicopter.to_save()` / `from_save()` plus `mission.gd` `_capture()` produce a plain dictionary. `GameState` keeps that dictionary in memory and optionally writes it as JSON. Win deletes the file. Settings are a separate document so a wiped mission does not wipe bindings.

**Groups as queries.** Lock-on scans group `ground_target`. Pause scans group `mission`. Do not walk the tree for those.

**Code-drawn HUD.** `Hud` uses `Control.draw` each frame. It reads the helicopter; it does not own flight state.

**Serialized input specs.** Bindings are not live `InputEvent` objects on disk. They are `{t, c}` dictionaries converted to `InputEventKey` or `InputEventMouseButton` when applied. A binding is unique: assigning a key clears it from every other slot.

## Conventions

- Files and functions are `snake_case`. Types declared with `class_name` are `PascalCase` (`Helicopter`, `GroundTarget`, `ThemeUtil`).
- Scene scripts that exist only as the root of one `.tscn` (`main_menu.gd`, `briefing.gd`, `hangar.gd`, `mission.gd`) omit `class_name`. Shared types that are constructed with `.new()` declare one.
- Constants for scene paths sit at the top of the script that changes to them (`const MISSION := "res://scenes/world/mission.tscn"`).
- Colors and control factories go through `ThemeUtil`. Do not invent a second palette in a screen script.
- User-facing labels are short, uppercase, and military (`"MISSION COMPLETE"`, `"COLLECTIVE UP"`).
- Physics layers are assigned as bit masks in code (`collision_layer = 2`). Names in `project.godot` document those bits. Keep them aligned.
- Nodes that must keep running while `get_tree().paused` is true set `PROCESS_MODE_ALWAYS` (pause layer, end screen, controls overlay, `GameState`). Projectiles stay `PROCESS_MODE_PAUSABLE`.
- Random audio samples use `randf()` with no fixed seed. Terrain noise is seeded (`17`) so the map matches the briefing layout.
- `.godot/`, `.DS_Store`, `*.tmp`, and `export_credentials.cfg` stay out of git.

## What this stack is not

There is no test runner, linter config, CI workflow, export preset, or environment-variable layer in the repo. Run and export steps are the Godot editor or the `godot` CLI. See [setup.md](setup.md).
