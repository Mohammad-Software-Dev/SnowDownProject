# AGENTS.md — Snowdown

## Authority order
1. Explicit user instruction in the current task.
2. `docs_source_of_truth/` canonical specification.
3. This file and other root implementation guides.
4. Current code behavior.

If code and canonical docs conflict, do not assume code is newer. Check the decision log.

## Core product rules
- First-person 3D competitive multiplayer snowball game.
- Non-lethal: no normal health/death/kill loop.
- Physical projectiles with visible travel time and arc; never convert core throws to hitscan.
- Competitive outcomes are server authoritative.
- Persistent progression must not provide permanent raw combat-stat advantages.
- Friends/parties and continuity are first-class later, but core feel comes first.

## Working style
- Read before editing.
- Prefer the smallest change that satisfies acceptance criteria.
- Keep every PROVISIONAL value tunable/config-driven.
- Never silently convert TBD into permanent design.
- Avoid unrelated refactors.
- Keep simulation, presentation, networking, persistence, and UI separated.
- Prefer composition over deep inheritance.
- Keep server/headless code free of rendering dependencies.
- Use typed GDScript where practical.
- Use Godot Input Map actions, not raw key checks.

## Verification
After meaningful changes:
- parse/load the project;
- run unit/integration tests that exist;
- run the relevant gameplay test scene;
- inspect debug state;
- capture evidence for visual changes when possible;
- report exactly what was and was not executed.

## Multiplayer/security invariants
Client sends intent. Server decides outcomes.
Client must never authoritatively decide:
- score;
- hit/head-hit classification;
- projectile existence;
- inventory grants;
- match phase;
- spawn choice;
- competitive movement outcome.

## Data and events
Keep balance in Resources/config data. Prefer explicit domain events such as:
`SnowballPacked`, `SnowballThrown`, `SnowballCaught`, `PlayerBodyHit`, `PlayerHeadHit`, `ScoreChanged`, `RoundStarted`, `RoundEnded`.

## Debuggability requirement
Create development-only debug tools for:
- player state;
- movement state;
- inventory/pack state;
- throw charge;
- projectile IDs/position/velocity/owner;
- hit classification;
- score;
- match phase/timer;
- network role/peer IDs;
- latency simulation when networking begins.

Provide deterministic test scenarios so a coding agent can jump directly into important states without replaying long setup sequences.

## Performance
Measure before optimizing. Do not trade gameplay correctness or server authority for premature performance tricks.

## Git
Keep commits small and descriptive. Do not commit generated builds. Use Git LFS for large binary assets.
