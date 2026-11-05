# Changelog

All notable changes to HeliStrike are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Ordnance screen after aircraft selection. Pylon count is 2 on the Defender, 3 on the Bell 222, and 4 on the Apache. Each pylon mounts one store: Hellfire, Spike-LR, Hydra 70, or APKWS, with its own round count, damage, range, and guidance.
- `CHANGELOG.md`, and a Cursor rule that requires each repo change to update it.
- `README.md` with how to run the game, the mission loop, default controls, and links to `docs/`.
- Cursor rules for Godot 4.6 stack boundaries and GDScript style (`.cursor/rules/`).
- `docs/architecture.md`, `docs/tech-stack.md`, and `docs/setup.md`.

### Fixed

- Flight HUD text uses a kept system font, so glyphs draw as letters instead of empty rectangles.
- Flight HUD shows live speed, altitude, the selected store, rounds left, and range to the tracked target. Altitude no longer sticks at 80 m once the aircraft climbs past the old 12 m ground ray.

### Changed

- Number keys 1-4 select the active pylon in flight, and each trigger fires one round, including rockets in a cluster.
- Renamed the project from heli-strike to HeliStrike: Godot project name, main menu title, save file names, and the project folder.
