# Dev Notes (Initial Repository Reconnaissance)

## 1) Current Main Scene & Boot Flow
- **Main scene** is `res://node_2d.tscn`, configured via `project.godot` (`run/main_scene`).【F:project.godot†L10-L15】
- `node_2d.tscn` is a simple `Node2D` with a single `Button` that calls `_on_button_button_up` on click.【F:node_2d.tscn†L1-L10】
- The `_on_button_button_up` handler sets up `global.players`, assigns `global.current_state`, and switches to `res://node_3d.tscn` for gameplay.【F:scripts/node_2d.gd†L14-L19】

## 2) Existing Scripts (Card Logic, Globals, State Machines, etc.)
- **Global state singleton**: `scripts/global.gd` defines many static gameplay variables and a `GameState` enum (DEALING/SELECTING/WAITING/COMBOING/END).【F:scripts/global.gd†L2-L36】
- **Card entity + state machine**: `scripts/card/card_base.gd` is a `Sprite3D` with state machine logic and animation helpers. It references multiple card states under `scripts/card/states/`.【F:scripts/card/card_base.gd†L1-L58】
- **Card states** include `DealingState`, `SelectingState`, `ToWaitState`, `WaittingState`, `ToHeldState`, `HeldState` (plus base `State.gd`). They drive transitions and card movement/interaction in 3D space.【F:scripts/card/states/SelectingState.gd†L1-L52】【F:scripts/card/states/ToWaitState.gd†L1-L22】
- **Players**: `PlayerEntity` (base), `LocalPlayer`, and `MultiPlayer` are in `scripts/Entity/`. Player classes currently have minimal behavior and include hand/waiting groups, inventory, and stats.【F:scripts/Entity/player.gd†L1-L27】【F:scripts/Entity/local_player.gd†L1-L6】
- **Scene controller**: `scripts/node_3d.gd` orchestrates state transitions, deals cards from the `cards` node, and updates camera/desk animations via `AnimationUtils`.【F:scripts/node_3d.gd†L1-L121】
- **Input/interaction**: `scripts/interactive/end_watting_button.gd` and `end_combo_button.gd` allow phase transitions using `Area3D` mouse input on 3D buttons.【F:scripts/interactive/end_watting_button.gd†L14-L35】【F:scripts/interactive/end_combo_button.gd†L14-L22】
- **Camera movement**: `scripts/spring_arm_3d.gd` uses `AnimationUtils` to animate the SpringArm length/rotation (no Tween system yet).【F:scripts/spring_arm_3d.gd†L1-L16】

## 3) Scene Hierarchy Overview
- **Main menu** (`node_2d.tscn`):
  - `Node2d`
    - `Button` (starts the game and changes to `node_3d.tscn`).【F:node_2d.tscn†L1-L10】
- **Gameplay** (`node_3d.tscn`):
  - `Node3D`
    - `WorldEnvironment`, `DirectionalLight3D`
    - `MPlayer` (CharacterBody3D)
    - `LPlayer` (CharacterBody3D)
      - `SpringArm3D`
        - `Camera3D`
    - `cards` (Node with `Sprite3D` card prefabs)
    - `Scene3D`
      - `Desk` (MeshInstance3D)
        - `Interactive` (Node3D)
          - `EndWatting` (MeshInstance3D + Area3D)
          - `EndCombo` (MeshInstance3D + Area3D)
        - `deck` (Sprite3D)
        - plus labeled regions like `WaitArea1`, `HeldArea1` etc. referenced in `scripts/node_3d.gd`.【F:node_3d.tscn†L19-L146】【F:scripts/node_3d.gd†L13-L24】

## 4) Existing Input Systems
- **2D UI button** in the main menu uses `button_up` signal to start the game.【F:node_2d.tscn†L7-L10】
- **3D card hover/click** uses `Area3D` signals in `SelectingState` (`mouse_entered`/`mouse_exited`) and `InputEventMouseButton` in state handlers for card selection and placement.【F:scripts/card/states/SelectingState.gd†L10-L52】
- **3D phase buttons** (`EndWatting`, `EndCombo`) check `InputEventMouseButton` and `Area3D` hover to trigger phase changes.【F:scripts/interactive/end_watting_button.gd†L14-L35】【F:scripts/interactive/end_combo_button.gd†L14-L22】
- **Camera drag**: `scripts/l_player.gd` listens for middle mouse drag to adjust player movement deltas (camera motion).【F:scripts/l_player.gd†L14-L34】

## 5) Existing Shaders, Materials, or Visual Experiments
- The gameplay scene uses a `ShaderMaterial` subresource on the desk mesh, but there are **no custom shader files** in the repository yet (no `.gdshader` files found).【F:node_3d.tscn†L33-L37】
- Textures for cards and card backs are in `res://textrue/` and referenced directly by `Sprite3D` nodes in `node_3d.tscn`.【F:node_3d.tscn†L4-L14】【F:node_3d.tscn†L66-L77】
