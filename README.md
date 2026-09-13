# Snowdown

Snowdown is a first-person competitive multiplayer snowball game built in Godot 4.x with GDScript. The active vertical slice is a server-authoritative **4v4 Team Snowdown** match on **Glacier Valley**.

The implementation follows the locked design and technical documents in `docs/`. Clients predict presentation and movement for responsiveness, while the dedicated server owns competitive movement truth, inventory, throws, catches, hit results, score, timer, match phase and round resets.

## Current vertical-slice state

The development branch now includes the core M0–M13 slice and is in M14 hardening/polish:

- responsive first-person movement with sprint, crouch, jump, slide and fast ice;
- pack → charge → physical throw → impact → replenish loop;
- authoritative catches with bounded latency compensation;
- server-owned inventory, projectiles, body/head hits and scoring;
- Glacier Valley with river, cave, shelf, outposts, cover rhythm and distributed snow sources;
- waiting/countdown/Active/Sudden Snow/results/restart match flow;
- 4v4 controlled scale coverage and network telemetry;
- minimal competitive HUD, feedback and scoreboard;
- procedural FP action presentation and state-driven TP remote presentation;
- first visual-identity pass for Glacier Valley;
- replaceable procedural winter-character presentation with shared FP/TP clothing language;
- keyboard/mouse and controller defaults;
- in-game pause/settings overlay;
- Host/Join/Offline Practice front end plus connection-failure recovery/retry.

The procedural character/environment presentation is intentionally production-replaceable. A final realistic production human/clothing mesh and broader final-art polish are still outstanding. Audio remains deferred under the current vertical-slice direction.

## Run the project

Open the repository root in Godot 4.x and run the project. The entry scene is:

`res://scenes/bootstrap/bootstrap.tscn`

A normal graphical launch opens the Snowdown session menu with:

- **HOST MATCH** — starts a local headless authoritative server and joins it from the same client;
- **JOIN MATCH** — direct-connects to a host using `host:port`;
- **OFFLINE PRACTICE** — launches Glacier Valley without networking;
- **QUIT**.

The default network port is UDP **7000**.

### Friends playtest

For players on the same LAN:

1. One player launches Snowdown and selects **HOST MATCH**.
2. The host shares the computer's LAN address and selected UDP port, for example `192.168.1.25:7000`.
3. Other players enter that endpoint under **JOIN MATCH**.
4. If a connection drops, the client receives a recovery panel with **Retry Connection** / **Restart Host** and **Return to Menu**.

For play across the public internet, the host's selected UDP port must be reachable through the host's firewall/router. Snowdown currently uses direct connection; matchmaking/NAT-traversal backend work is intentionally outside this vertical slice.

### Command-line launch

Dedicated authoritative server:

```bash
godot --headless --path . -- --server --world=glacier_valley --port=7000
```

Client direct-connect:

```bash
godot --path . -- --connect=127.0.0.1 --port=7000
```

Useful deterministic development entry points still include:

```text
--scenario=test_arena_origin
--scenario=movement_runway
--scenario=projectile_lane
--scenario=catch_lane
--scenario=map01_center_arch
--scenario=map01_frozen_river
--scenario=map01_high_shelf
--scenario=map01_snow_source_test
--scenario=map01_out_of_bounds
```

## Controls

### Keyboard / mouse

- `WASD` — move
- Mouse — look / aim
- `Shift` — hold sprint
- `Space` — jump
- `Ctrl` or `C` — crouch / slide
- `E` — hold to pack snow in a valid snow source
- Mouse1 — hold to charge, release to throw
- Mouse2 — catch
- `Tab` — scoreboard
- `Esc` — pause/settings
- `F1` — debug overlay
- `R` — reset the active deterministic test scenario in development fixtures

### Controller

- Left Stick — move
- Right Stick — look / aim
- Right Trigger — hold to charge, release to throw
- Left Trigger — catch
- South face button — jump
- East face button — crouch / slide
- West face button — pack / interact
- Left Stick Click — sprint
- View / Back — scoreboard
- Menu / Start — pause/settings

The pause menu exposes live mouse-look and controller-look sensitivity controls. Offline Practice pauses the local simulation. In a network match, opening the local menu suppresses that client's gameplay inputs but **does not pause the authoritative server or other players**.

## Verification

The main verification path is:

```bash
tools/scripts/run_headless_tests.sh
```

Set `GODOT_BIN` if `godot` is not on `PATH`:

```bash
GODOT_BIN=/path/to/godot tools/scripts/run_headless_tests.sh
```

The GitHub verification workflow currently exercises project parse/import plus deterministic gameplay/network gates including:

- configuration/input smoke;
- snowball trajectory and catch validation;
- match-state/race invariants and repeated round reset;
- FP/TP presentation state coverage;
- controller mapping and pause input suppression;
- Glacier Valley layout/visual-spec invariants;
- headless server and client startup;
- authoritative throw/catch under latency, jitter and packet loss presets through 200 ms / 5% loss;
- disconnect with live authoritative projectile state followed by replacement-client rejoin;
- server-owned match loop through Sudden Snow/results/round 2;
- real eight-client 4v4 scale smoke.

CI is currently pinned to Godot **4.7.2 stable**.

## Architecture

The project follows the ownership boundaries described in `docs/docs_source_of_truth/20_GODOT_PROJECT_STRUCTURE.md`:

- `src/autoload` — minimal global bootstrap/config state
- `src/client` — client-only input/presentation/prediction
- `src/server` — headless authoritative systems
- `src/shared` — shared math/data contracts and tunable Resources
- `src/gameplay` — reusable competitive gameplay logic
- `src/network` — protocol, authority, replication and reconciliation
- `src/ui` — presentation/UI only
- `src/world` — world, spawn and surface systems
- `src/debug` — development-only tooling
- `data` — tunable Resources; no scattered balance magic numbers
- `tests` — deterministic unit/integration/gameplay/network gates

## Authority principle

**Clients send intent. The server decides competitive outcomes.**

A client cannot author its own score, hit classification, inventory grant, authoritative projectile, match phase or competitive movement result.
