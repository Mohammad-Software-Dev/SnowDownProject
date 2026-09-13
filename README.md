# Snowdown

Snowdown is a first-person competitive multiplayer snowball game built in Godot 4.x with GDScript.

The implementation follows the locked design and technical documents in `docs/`. The active vertical-slice direction is a server-authoritative 4v4 Team Snowdown match on Glacier Valley. Development starts by proving the offline movement/snowball toy, then networking, then the arena, then visual polish.

## Current development state

**Iteration 1 / M0 — Project Foundation**

Implemented foundation:
- Godot project bootstrap;
- canonical InputMap actions;
- typed, data-driven gameplay configuration Resources;
- graybox `TestArena`;
- deterministic debug scenario markers;
- development debug overlay;
- headless smoke-test entry point;
- Git/Git-LFS repository hygiene.

No production art, networking, progression, matchmaking, monetization, or backend systems are on the critical path yet.

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

The bootstrap records `--server` as a headless/server runtime role, but authoritative networking is intentionally not implemented until the network milestone.

## Development controls

- `F1` — toggle debug overlay
- `R` — reset the active deterministic test scenario

Gameplay controls are registered through Godot InputMap and will be exercised once the player controller lands.

## Smoke test

When Godot is installed locally/CI:

```bash
godot --headless --path . -s tests/smoke/config_smoke.gd
```

The smoke test checks that the core config resources load and canonical input actions exist.

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
