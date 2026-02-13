# Repository Guidelines

## Project Structure & Module Organization
This repository is a Godot 4.6 project.

- `project.godot`: main project configuration and plugin enablement.
- `scenes/`: scene files (`.tscn`) organized by feature (`card/`, `desk/`, `player/`, `camera/`).
- `scripts/`: GDScript code, grouped by domain (`card/`, `systems/`, `Entity/`, `state/`, `core/`, `Utils/`).
- `data/cards/cards.json`: data-driven card definitions consumed by `CardFactory`.
- `textrue/`: image assets and imports.
- `addons/godot_mcp/`: MCP plugin code; treat as third-party plugin area unless intentionally modifying tooling.

## Build, Test, and Development Commands
Use Godot CLI from repo root (`D:\Project\Demo`):

- `godot4 --editor --path .`
Opens the editor with this project.
- `godot4 --path .`
Runs the game using `run/main_scene` from `project.godot`.
- `godot4 --headless --path . --quit`
Quick startup smoke check for CI/local validation.

If your binary is named differently, replace `godot4` with your local executable.

## Coding Style & Naming Conventions
- GDScript uses tabs for indentation (match existing files).
- Use `class_name` for reusable types and explicit type hints (`var x: Type`).
- File names: `snake_case.gd`; scene names: `snake_case.tscn`.
- Constants: `UPPER_SNAKE_CASE`; methods/variables: `snake_case`.
- Keep feature logic in domain folders (`scripts/systems`, `scripts/card`) instead of monolithic scripts.

## Testing Guidelines
There is no dedicated test framework in-tree yet.

- Add focused smoke checks for major changes with `--headless --quit`.
- Validate scene/script wiring by opening edited scenes in the editor and running the main scene.
- For new logic-heavy modules, add small reproducible debug entry points or assertions where appropriate.

## Commit & Pull Request Guidelines
Recent history mixes short fixes (for example `小BUG`) and Conventional Commit style (`feat:`, `refactor:`, `fix(p0):`).

- Preferred commit format: `type(scope): short imperative summary`.
- Keep one logical change per commit.
- PRs should include:
  - What changed and why.
  - Affected scenes/scripts (for example `scenes/desk/desk_root.tscn`, `scripts/systems/battle_flow.gd`).
  - Validation notes (commands run, smoke-test result).
  - Screenshots/GIFs for visible UI or scene changes.
