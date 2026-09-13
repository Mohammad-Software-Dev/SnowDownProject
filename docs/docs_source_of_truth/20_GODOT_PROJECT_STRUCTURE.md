# Snowdown — Godot Project Structure

Status: **PROVISIONAL BASELINE**  
Purpose: Canonical project organization for implementing Snowdown in Godot 4 with GDScript.

This document defines how the Snowdown Godot project should be structured. AI coding agents and human contributors should follow this structure unless a deliberate architecture decision is recorded in `18_DECISIONS_OPEN_QUESTIONS.md`.

## 1. Technology Baseline

- Engine: Godot 4.x
- Language: GDScript
- Initial target: Windows desktop
- Planned secondary targets: macOS and Linux
- Mobile targets: Android/iOS later, only after desktop gameplay is proven
- Networking model: authoritative client/server
- Production match hosting: headless dedicated Godot server
- Prototype hosting: listen server is allowed for development and private testing
- Source control: Git + Git LFS for large binary assets
- Documentation: Markdown files in the Snowdown Drive folder are the source of truth

Core rule: **the client requests actions; the server decides outcomes.**

The client must never be authoritative for scores, hits, inventory, projectile existence, match state, or competitive movement outcomes.

---

## 2. Top-Level Repository Layout

```text
snowdown/
├── README.md
├── project.godot
├── icon.svg
│
├── docs/
│   └── README.md
│
├── src/
│   ├── autoload/
│   ├── client/
│   ├── server/
│   ├── shared/
│   ├── gameplay/
│   ├── network/
│   ├── ui/
│   ├── world/
│   └── debug/
│
├── scenes/
│   ├── bootstrap/
│   ├── menus/
│   ├── gameplay/
│   ├── players/
│   ├── projectiles/
│   ├── world/
│   └── ui/
│
├── assets/
│   ├── characters/
│   ├── environment/
│   ├── snowballs/
│   ├── materials/
│   ├── textures/
│   ├── models/
│   ├── animations/
│   ├── audio/
│   ├── vfx/
│   ├── fonts/
│   └── icons/
│
├── data/
│   ├── balance/
│   ├── game_modes/
│   ├── maps/
│   ├── cosmetics/
│   └── localization/
│
├── tests/
│   ├── unit/
│   ├── integration/
│   ├── network/
│   └── gameplay/
│
├── tools/
│   ├── editor/
│   └── scripts/
│
└── builds/
    └── .gitkeep
```

`builds/` should normally be ignored by Git except for `.gitkeep`.

---

## 3. Source-Code Responsibilities

### `src/autoload/`

Only globally required systems belong here.

Recommended autoloads:

```text
App.gd
GameConfig.gd
Network.gd
SceneRouter.gd
AudioManager.gd
```

Do not turn every manager into an autoload. Global state should be kept minimal.

### `src/client/`

Client-only behavior:

- local input collection
- camera control
- local prediction
- interpolation of remote players
- presentation state
- client-side VFX/audio triggers
- settings
- client UI coordination

The client may predict for responsiveness, but predicted state is never the final authority.

### `src/server/`

Server-only behavior:

- authoritative player state
- projectile spawning
- projectile simulation or validation
- hit resolution
- scoring
- match lifecycle
- inventory validation
- anti-cheat validation
- party/session admission rules
- spawn selection

Server code must be able to run in headless mode without rendering dependencies.

### `src/shared/`

Code that must behave identically on client and server:

- enums
- immutable data structures
- message schemas
- math helpers
- gameplay constants that are not secret
- validation helpers
- shared identifiers

Shared code must not depend on cameras, visual nodes, UI, or platform-specific APIs.

### `src/gameplay/`

Reusable gameplay systems independent of presentation:

```text
movement/
snowballs/
hits/
scoring/
inventory/
catching/
match/
```

Gameplay logic should be decomposed into small components rather than one giant Player script.

### `src/network/`

All networking-specific code:

```text
protocol/
rpc/
replication/
prediction/
interpolation/
reconciliation/
sessions/
```

Do not scatter RPC declarations arbitrarily throughout unrelated scripts when a dedicated network component is appropriate.

### `src/ui/`

UI controllers and view-model-like logic.

UI should read game state and issue player intentions. It must not contain authoritative gameplay rules.

### `src/world/`

World-level systems:

- map loading
- spawn points
- snow surfaces
- environmental interactions
- world reset
- match arena metadata

### `src/debug/`

Development-only tooling:

- network graphs
- projectile trajectory visualizer
- hitbox display
- latency simulation controls
- server-state inspection
- spawn debugging

Debug tools must be removable/disabled in release builds.

---

## 4. Scene Architecture

Recommended high-level scenes:

```text
scenes/bootstrap/Bootstrap.tscn
scenes/menus/MainMenu.tscn
scenes/menus/Lobby.tscn
scenes/gameplay/GameClient.tscn
scenes/gameplay/GameServer.tscn
scenes/players/Player.tscn
scenes/projectiles/Snowball.tscn
scenes/world/AlpineVillage.tscn
scenes/ui/HUD.tscn
scenes/ui/Scoreboard.tscn
```

### Bootstrap

`Bootstrap.tscn` is the executable entry scene.

Responsibilities:

1. Parse launch arguments.
2. Determine client vs dedicated-server mode.
3. Initialize configuration.
4. Initialize networking.
5. Route to the correct scene.

Example modes:

```text
snowdown.exe
snowdown.exe --server
snowdown.exe --server --port 7000
```

The dedicated server must not load gameplay cameras, HUDs, menus, or visual effects.

---

## 5. Player Scene

The player should be component-based.

Suggested tree:

```text
Player (CharacterBody3D)
├── CollisionShape3D
├── BodyHitbox
├── HeadHitbox
├── VisualRoot
│   ├── CharacterModel
│   └── AnimationTree
├── CameraPivot
│   └── Camera3D
├── ThrowOrigin
├── Components
│   ├── MovementComponent
│   ├── SnowballInventoryComponent
│   ├── ThrowComponent
│   ├── CatchComponent
│   ├── NetworkStateComponent
│   └── HitReactionComponent
└── Audio
```

Client-only nodes such as the local camera should be enabled only for the locally controlled player.

The server should care about authoritative collision/state nodes, not presentation nodes.

---

## 6. Snowball Scene

Suggested structure:

```text
Snowball (Node3D or CharacterBody3D)
├── CollisionShape3D
├── MeshInstance3D
├── Trail/VFX
└── Audio
```

Authoritative snowball state includes at minimum:

```text
projectile_id
owner_player_id
spawn_tick
position
velocity
active
```

A snowball may score at most once.

The server owns projectile creation and hit resolution.

The client may immediately display a predicted snowball for responsiveness, but it must reconcile with server confirmation.

---

## 7. Networking Rules

Godot's high-level multiplayer/RPC system may be used, but gameplay must follow these rules:

### Server authority

Server decides:

- valid movement state
- snowball inventory
- valid throw attempts
- projectile creation
- projectile trajectory used for scoring
- body/head hit classification
- catch success
- score changes
- streaks
- match start/end
- spawn points

### Client authority

Client owns only:

- raw input
- camera orientation presentation
- local graphics settings
- local UI state

### Network message principle

Prefer messages that represent **intent**, not claimed outcomes.

Good:

```text
request_throw(direction, charge_amount, client_tick)
```

Bad:

```text
report_headshot(target_id)
```

Good:

```text
request_catch(client_tick)
```

Bad:

```text
caught_projectile(projectile_id)
```

---

## 8. Match State Machine

Canonical match phases:

```text
BOOT
WAITING_FOR_PLAYERS
COUNTDOWN
PLAYING
ROUND_ENDING
RESULTS
RESETTING
```

Only the server changes authoritative match phase.

Clients receive replicated phase changes and update presentation accordingly.

---

## 9. Data-Driven Configuration

Balance values must not be scattered through scripts.

Use Godot Resources (`.tres`) or centralized typed configuration objects.

Suggested data files:

```text
data/balance/player_movement.tres
data/balance/snowball.tres
data/balance/scoring.tres
data/balance/match_rules.tres
```

Examples of configurable values:

```text
walk_speed
sprint_speed
jump_velocity
slide_speed
snowball_capacity
pack_duration
min_throw_speed
max_throw_speed
max_charge_duration
catch_window
body_hit_score
head_hit_score
hit_penalty
round_duration
```

Changing a balance value should normally require editing data, not gameplay code.

---

## 10. Input Map

Canonical desktop actions should use Godot Input Map names rather than hard-coded keys.

```text
move_forward
move_backward
move_left
move_right
jump
crouch
sprint
throw
pack_snowball
catch_snowball
scoreboard
pause
```

Mouse movement controls look direction.

No gameplay script should check raw key codes when an Input Map action exists.

Mobile input can later map virtual controls to the same actions.

---

## 11. Naming Conventions

### Files

Use `snake_case`:

```text
snowball_projectile.gd
player_movement.gd
match_state.gd
```

### Classes

Use `PascalCase` with `class_name` where globally useful:

```gdscript
class_name SnowballProjectile
```

Do not register every helper globally.

### Variables/functions

Use `snake_case`.

```text
current_score
throw_charge
spawn_snowball()
apply_hit()
```

### Signals

Use past-tense or event-style names:

```text
snowball_thrown
player_hit
score_changed
match_started
match_ended
```

### Constants

Use `UPPER_SNAKE_CASE`.

---

## 12. Script Design Rules

1. Prefer small components over giant scripts.
2. Prefer composition over deep inheritance trees.
3. Avoid gameplay logic inside UI scripts.
4. Avoid server logic that requires rendering nodes.
5. Avoid hard-coded balance numbers.
6. Avoid hidden singleton state when explicit ownership is possible.
7. Keep RPC/network boundaries obvious.
8. Type GDScript variables and function parameters whenever practical.
9. Validate external/network input.
10. Log unexpected authoritative-state violations.

Example:

```gdscript
func request_throw(direction: Vector3, charge: float) -> void:
    ...
```

is preferred over untyped equivalent code.

---

## 13. AI Coding Agent Rules

Before modifying Snowdown, an AI coding agent must:

1. Read `00_README.md` in the design repository.
2. Read this file.
3. Read every specification relevant to the requested system.
4. Identify whether each relevant rule is LOCKED, PROVISIONAL, TBD, or OUT OF SCOPE.
5. Never convert TBD behavior into permanent design silently.
6. Never weaken server authority for implementation convenience.
7. Keep balance values data-driven.
8. Avoid unrelated refactors unless required.
9. Add/update tests for behavior changes.
10. Report conflicts between code and specification instead of guessing which one is correct.

If implementation reveals a missing design decision, the correct response is to record/raise the ambiguity rather than invent a permanent rule.

---

## 14. Initial Implementation Order

### Milestone A — Offline Feel Prototype

```text
Bootstrap
TestArena
Player movement
First-person camera
Snowball packing
Charge-to-throw
Projectile arc
Body/head hitboxes
Basic hit feedback
```

No persistence, matchmaking, cosmetics, progression, or production backend.

### Milestone B — Local Multiplayer

```text
Headless server mode
2 connected clients
Authoritative player spawning
Network movement
Server-authoritative throws
Replicated projectiles
Server hit detection
Scoreboard
Round lifecycle
```

### Milestone C — Internet Friends Test

```text
4-8 players
Join/host flow
Reconnect handling
Basic lobby
Room/session discovery or direct connection
Latency testing
Prediction/interpolation improvements
```

### Milestone D — Alpha Foundation

```text
Alpine Village
Party continuity
Results flow
Settings
Polish pass
Crash/error logging
External test distribution
```

---

## 15. Things We Explicitly Do Not Build Yet

Until core multiplayer is fun and stable, do not prioritize:

- account system
- monetization
- cosmetic store
- ranked matchmaking
- clans
- battle pass
- mobile UI
- advanced snow deformation
- complex backend microservices
- cross-platform account linking
- massive map count
- dozens of snowball variants

These systems may exist later, but they must not delay validation of the core snowball fight.

---

## 16. Architectural Success Criteria

The structure is working if:

- a dedicated server can run without a GPU/UI
- two or more clients can join the same authoritative match
- gameplay rules are testable without relying on presentation
- balance numbers can be changed without rewriting systems
- an AI agent can locate the owning system quickly
- client/server responsibilities are obvious from the codebase
- no client can award itself a score or confirm its own hit
- presentation can change without rewriting authoritative game rules
- new platforms can map their input into the same gameplay actions

---

## 17. Current Decision

**PROVISIONAL:** Snowdown will be implemented in Godot 4 using GDScript, targeting Windows first and using an authoritative Godot headless server for multiplayer.

This becomes **LOCKED** after the first networked prototype demonstrates acceptable movement, throwing, hit registration, and development workflow.
