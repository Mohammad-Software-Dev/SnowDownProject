# Snowdown

Snowdown is a first-person competitive multiplayer snowball game built in Godot 4.x with GDScript.

The implementation follows the locked design and technical documents in `docs/`. The active vertical-slice direction is a server-authoritative 4v4 Team Snowdown match on Glacier Valley. Development starts by proving the offline movement/snowball toy, then networking, then the arena, then visual polish.

## Current development state

The active development PR currently contains the first four implementation iterations:

1. **M0 foundation** — project bootstrap, InputMap, typed balance Resources, TestArena, deterministic scenarios, debug overlay.
2. **Offline locomotion** — first-person look, walk/sprint/jump/crouch/slide, coyote time and jump buffering.
3. **Core snowball toy** — packable snow, 3-ball inventory, charge/release throws, visible arc projectile, swept collision, body/head scoring.
4. **Catch baseline** — active-only frontal catch validation, catch interruption/recovery, caught-ball inventory recovery, deterministic catch fixture, shared projectile math tests.

No production art, authoritative networking, progression, matchmaking, monetization, or backend systems are on the critical path yet.

## Run

Open the repository root in Godot 4.x and run the project. The entry scene is:

`res://scenes/bootstrap/bootstrap.tscn`

Useful launch arguments:

```text
--scenario=test_arena_origin
--scenario=movement_runway
--scenario=projectile_lane
--scenario=catch_lane
```

The `catch_lane` scenario launches an incoming deterministic practice snowball. Press Mouse2 during the short frontal catch window.

The bootstrap records `--server` as a headless/server runtime role, but authoritative networking is intentionally not implemented until the network milestone.

## Controls

- `WASD` — move
- Mouse — look
- `Shift` — sprint
- `Space` — jump
- `Ctrl` or `C` — crouch / slide
- `E` — hold to pack snow when standing near a snow patch
- Mouse1 — hold to charge, release to throw
- Mouse2 — catch
- `F1` — toggle debug overlay
- `R` — reset the active deterministic test scenario
- `Esc` — release/capture mouse

## Tests

When Godot is installed locally/CI:

```bash
godot --headless --path . -s tests/smoke/config_smoke.gd
godot --headless --path . -s tests/unit/snowball_math_test.gd
godot --headless --path . -s tests/unit/catch_validation_test.gd
```

The current execution environment used to author these commits does not include a Godot executable, so runtime parsing/playtesting remains an explicit verification gate before this work should merge.

## Architecture

The project follows the ownership boundaries described in `docs/docs_source_of_truth/20_GODOT_PROJECT_STRUCTURE.md`:

- `src/autoload` — minimal global bootstrap/config state
- `src/client` — client-only input/presentation/prediction
- `src/server` — headless authoritative systems
- `src/shared` — shared enums/math/data contracts
- `src/gameplay` — reusable competitive gameplay logic
- `src/network` — protocol/replication/reconciliation
- `src/ui` — presentation/UI only
- `src/world` — world/spawn/surface systems
- `src/debug` — development-only tooling
- `data` — tunable Resources; no scattered balance magic numbers
- `tests` — deterministic unit/integration/gameplay/network tests

## Authority principle

**Clients send intent. The server decides competitive outcomes.**

No client-authored score, hit classification, inventory grant, projectile authority, match phase, or competitive movement outcome will be accepted in networked play.
