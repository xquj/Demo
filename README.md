# Gloomtable (Godot 4.x Card Battle Slice)

## How to Run
1. Open the project in **Godot 4.x**.
2. Press **Play**. The main menu button launches the tabletop match scene.

## Current Features
- Full 4-lane tabletop battle loop with turns, draw/play/combat/resolution phases.
- 18 original cards (12 units, 6 spells) defined in `data/cards.json`.
- Blood and bone cost systems with sacrifices and bone generation on death.
- Data-driven sigil system with 4 original abilities.
- Enemy AI that draws, plays, and fights.
- Camera state machine using Tween transitions.
- Procedural shaders for wood and paper, plus SVG UI and card art assets.

## Known Limitations
- Card placement uses automatic sacrifices (no manual selection UI yet).
- Visual polish is minimal; card art uses silhouettes and placeholder ink shapes.
- No sound effects or music.

## Expansion Ideas
- Manual sacrifice selection UX.
- More sigils, cards, and deck-building.
- Additional animations and sound design.
- Multi-stage encounters and narrative progression.
