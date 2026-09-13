# Snowdown — Astra Build Plan

## Phase 0 — Repository bootstrap
- Create Godot 4 project using the structure defined in `docs_source_of_truth/20_GODOT_PROJECT_STRUCTURE.md`.
- Add Git/Git LFS files and ignores.
- Create data-driven balance Resources.
- Create TestArena and debug overlay/state inspector.
- Add a test runner/addon only if it materially improves repeatability and is appropriate for the chosen Godot version.

Exit condition: project opens cleanly, headless launch path is planned, and test/debug entry points exist.

## Phase 1 — Offline Feel Prototype
Implement only what is needed to validate core feel:
- first-person camera;
- movement;
- jump/sprint/slide/crouch where specified;
- snow source interaction;
- packing/inventory;
- throw charging;
- physical projectile arc;
- body/head target hitboxes;
- scoring feedback;
- non-lethal hit reaction;
- fast reset;
- deterministic test scenarios.

Exit condition: one person can play a small arena and the throw/movement loop is enjoyable enough to justify multiplayer.

## Phase 2 — Local Authoritative Multiplayer
- headless server mode;
- two local clients;
- authoritative spawn/movement validation;
- server-authoritative inventory and throw requests;
- replicated projectiles;
- server hit classification;
- authoritative score;
- round lifecycle and scoreboard;
- prediction/interpolation/reconciliation where needed.

Exit condition: two clients can complete repeated rounds without score/hit authority being trusted to clients.

## Phase 3 — Internet Friends Test
- 4–8 players;
- host/join path;
- reconnect/leave handling;
- latency simulation and tuning;
- basic lobby/session discovery or direct-connect solution;
- profiling and telemetry.

Exit condition: remote friends can play repeated sessions with acceptable responsiveness and clear failure handling.

## Phase 4 — Alpha Foundation
- first production-quality map pass;
- results flow;
- settings/accessibility baseline;
- party continuity planning/implementation;
- crash/error logging;
- external test packaging.

## Work-unit rule
Each task should leave the project runnable. Prefer one vertical feature with verification over several partially integrated systems.
