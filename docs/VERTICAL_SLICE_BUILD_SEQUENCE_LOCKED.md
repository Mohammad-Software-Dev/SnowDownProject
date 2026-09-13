# SNOWDOWN — VERTICAL SLICE BUILD SEQUENCE — LOCKED

Status: **LOCKED / AUTHORITATIVE IMPLEMENTATION ORDER**

Purpose: tell Astra exactly what to build, in what order, and what must be proven before moving forward.

## Vertical Slice Goal

Deliver one polished, repeatable **4v4 Team Snowdown match on Glacier Valley** that proves:

- movement feels good;
- packing/throwing/catching is fun;
- snowballs are readable physical projectiles;
- body/head hits are fair;
- server-authoritative multiplayer works;
- Map 01 creates good engagements;
- first-person hands make the snow interaction tactile;
- realistic winter characters and the frozen-world direction can support the gameplay;
- the game remains debuggable and testable.

The vertical slice is **not** the full game.

---

# Global Build Rules

1. Keep the project runnable after every milestone.
2. Graybox before production art.
3. Offline simulation before networking complexity.
4. Dedicated-server authority before public-facing polish.
5. Instrument systems before tuning them.
6. Prefer placeholders over blocking on missing art.
7. Every milestone ends with a reproducible test.
8. Do not silently change locked design decisions.
9. If a locked requirement is technically harmful, document the issue and propose a change rather than improvising.
10. Do not begin later-game systems while a foundational milestone is unstable.

---

# M0 — PROJECT FOUNDATION

## Build
- Godot 4.x project boots cleanly.
- Establish repository structure.
- InputMap actions from locked input spec.
- Central gameplay configuration/resources.
- Debug/development flag.
- Logging utilities.
- Test-scene framework.
- Client vs headless/server startup detection.
- Basic CI/smoke-test command where practical.

## Required project areas
- gameplay
- player
- projectile
- map
- network
- UI
- VFX
- assets
- tests/debug

## Definition of Done
- Project opens with no critical errors.
- Game can launch into a test scene.
- Headless mode can boot without graphics-dependent crash.
- Input actions exist.
- Tunable gameplay values are centralized rather than scattered.
- One command/path can run a smoke test.

## Do Not Build Yet
- matchmaking;
- backend accounts;
- final art;
- progression;
- cosmetics;
- audio pipeline.

---

# M1 — OFFLINE MOVEMENT SANDBOX

## Build
Single-player test arena with:
- WASD/controller movement;
- camera look;
- sprint;
- crouch;
- jump;
- slide;
- slopes;
- frozen-river/low-friction test strip;
- out-of-bounds reset;
- player collision/head/body debug shapes.

## Instrument
- current speed;
- grounded state;
- slope angle;
- locomotion state;
- slide state;
- OOB state.

## Test Geometry
Include:
- flat snow;
- incline;
- decline;
- stairs/steps if relevant;
- ice strip;
- waist cover;
- head-height cover;
- low ceiling;
- drop/OOB pit.

## Definition of Done
- Movement feels responsive at target scale.
- No obvious bunny-hop/runaway slide exploit.
- Crouch updates collider and head/body regions correctly.
- Sliding starts/stops predictably.
- Ice is clearly distinguishable in behavior.
- OOB recovery is fast and safe.
- No animation/root-motion dependency is required.

## Gate
Do not network movement until offline controller behavior is stable enough to test repeatedly.

---

# M2 — OFFLINE SNOWBALL CORE LOOP

## Build
- snowball inventory;
- valid packable snow regions;
- pack action;
- charge;
- throw;
- explicit projectile integration;
- gravity/optional drag;
- swept-sphere collision;
- world impacts;
- body/head hit classification;
- projectile lifetime;
- debug trajectory;
- near-wall throw safety.

## Required loop
**find snow → pack → aim → charge → throw → impact → replenish**

## Definition of Done
- One pack completion grants exactly one snowball.
- Throw consumes exactly one.
- Projectile visibly arcs.
- Maximum-speed throws do not tunnel through normal targets.
- Head/body classification is deterministic.
- World impact immediately disables scoring.
- Camera aim + hand-origin logic does not shoot through nearby walls.
- Fixed trajectory tests pass within tolerance.

## Gate
Do not add special snowballs.

---

# M3 — CATCH + ACTION STATE MACHINE

## Build
- layered match/locomotion/hand state model;
- catch input;
- catch active window;
- frontal cone/approach test;
- catch success/fail;
- throw recovery;
- pack cancellation;
- hit reactions;
- action interrupt priority;
- basic input buffering.

## Required race tests
- catch vs body hit;
- catch vs head hit;
- throw release vs catch;
- pack completion vs hit;
- jump vs pack completion;
- hit during charge.

## Definition of Done
- Catch interrupts pack and charge where specified.
- Throw recovery prevents spam.
- One projectile cannot both hit and be caught.
- State interruptions never leave the player stuck.
- Body/head reactions are short and preserve agency.
- Race outcomes are deterministic.

---

# M4 — MAP 01 GRAYBOX: GLACIER VALLEY

## Build
Graybox only:
- two team outposts;
- Glacier Arch;
- Frozen River central/fast route;
- Ice Cave flank;
- Glacier Shelf/high route;
- low/mid/high elevation bands;
- natural-cover equivalents;
- distributed packable snow;
- boundaries/OOB.

## Scale targets
Start from locked provisional footprint and traversal targets.

## Test
Use direct debug entry points:
- team A spawn;
- team B spawn;
- center arch;
- river;
- both cave entries;
- high shelf;
- long-throw lane;
- snow-source test;
- OOB test.

## Definition of Done
- Both teams reach central combat in comparable time.
- At least two viable approaches per team.
- No direct spawn-to-spawn dominance.
- River is fast/exposed.
- Cave is viable but not mandatory.
- High ground has counters.
- Close/medium/long throws occur naturally.
- Most contested spaces have timely LOS breaks.
- Snow access supports decisions without becoming scarce frustration.

## Gate
Do not perform final glacier sculpt/material pass yet.

---

# M5 — HEADLESS SERVER + TWO-CLIENT MOVEMENT

## Build
- dedicated headless server startup;
- ENet/high-level multiplayer baseline;
- peer join/leave;
- server-owned player IDs/team state;
- input intent messages;
- local movement prediction;
- server movement authority;
- reconciliation;
- remote interpolation;
- RTT/clock estimate;
- network debug HUD.

## Definition of Done
- Dedicated server runs without rendering.
- Two clients connect reliably.
- Local movement feels immediate.
- Server rejects impossible movement.
- Prediction converges to server state.
- Remote player movement is readable.
- Disconnect cleans up safely.
- Reconciliation/debug counters are visible.

---

# M6 — AUTHORITATIVE NETWORKED SNOWBALLS

## Build
Server authority for:
- inventory;
- pack validation;
- charge validation;
- throw request;
- projectile IDs;
- projectile simulation;
- world impacts;
- body/head hits;
- score-changing events.

Client:
- predicted throw presentation;
- predicted projectile;
- projectile reconciliation.

## Definition of Done
- Client cannot grant itself inventory.
- Client cannot create authoritative extra projectiles.
- One accepted throw creates one server projectile.
- Prediction merges without visible duplicate under normal conditions.
- Client cannot submit arbitrary hit/score.
- Projectile scores at most once.
- Body/head results match server truth.

---

# M7 — AUTHORITATIVE CATCH + LAG TESTING

## Build
- server catch validation;
- bounded player-state history;
- bounded rewind for latency-sensitive validation;
- catch/hit deterministic ordering;
- simulated latency/jitter/loss presets.

## Test conditions
Approximate:
- baseline;
- 50 ms;
- 100 ms;
- 150 ms;
- 200 ms;
- 1–2% loss;
- ~5% loss;
- jitter.

## Definition of Done
- Catch remains understandable under moderate latency.
- No absurd long-latency rewind behavior.
- Hit/catch resolves once.
- Prediction recovers after corrections.
- No duplicate projectiles or scoring under packet loss.
- Rewind amount and validation result are inspectable.

---

# M8 — MATCH LOOP / TEAM SNOWDOWN

## Build
Server-owned:
- lobby/waiting;
- team assignment;
- spawn;
- countdown;
- Active;
- score;
- timer;
- Sudden Snow;
- results;
- reset/restart.

Implement spawn protection according to locked rules.

## Definition of Done
- Two teams can complete a full round.
- Score is server authoritative.
- Timer is server authoritative.
- Tie enters Sudden Snow.
- One valid next score resolves Sudden Snow.
- Round transition clears/resets required gameplay state.
- In-flight projectile behavior at round end is deterministic.
- Players cannot score during inactive phases.

---

# M9 — 4V4 LOCAL / CONTROLLED PLAYTEST

## Build/Test
- eight clients, bots, dummies, or controlled test harness where practical;
- 4v4 spawn/team logic;
- Map 01 full graybox;
- telemetry.

## Collect
- time to first engagement;
- throws/hits heatmaps;
- average throw distance;
- snow-source usage;
- cave/river usage;
- high-ground occupancy;
- congestion;
- OOB attempts;
- side win rate;
- catch frequency;
- head-hit lanes.

## Definition of Done
- Eight-player round can complete repeatedly.
- No severe congestion.
- No long dead periods.
- No single position dominates most engagements.
- Team side advantage is not obviously structural.
- Snow replenishment does not create one mandatory control point.
- Performance remains adequate for continued development.

## Critical Rule
Fix geometry/layout problems before changing fundamental snowball physics to compensate for a bad map.

---

# M10 — MINIMUM UI / FEEDBACK

## Build
- crosshair;
- charge indication;
- inventory/readiness;
- team score;
- timer;
- hit confirmation;
- head-hit distinction;
- catch confirmation;
- interaction prompt;
- scoreboard;
- countdown;
- results;
- connection/network warning;
- minimal settings/pause.

## VFX
Placeholder-to-good-quality:
- pack powder;
- body hit;
- head hit;
- snow impact;
- ice impact;
- hard-surface impact;
- catch crumble.

## Definition of Done
- Player understands core state without debug UI.
- Hit vs head hit is readable.
- Catch success is unmistakable.
- Snowball availability/packing is understandable.
- HUD remains minimal and does not obscure the environment.
- No competitive information depends solely on color.

Audio may remain deferred.

---

# M11 — ANIMATION INTEGRATION

## Build
Use placeholder coverage first, then improve hero actions.

Required system:
- base locomotion layer;
- upper-body action layer;
- additive reactions;
- procedural aim/look;
- FP rig;
- TP rig;
- animation markers;
- state-driven remote animation.

## Hero priority
1. FP pack
2. FP charge/throw
3. FP catch
4. TP throw
5. TP catch
6. slide

## Definition of Done
- Throw release visually aligns with server projectile spawn.
- Pack timing matches gameplay.
- Catch animation matches gameplay window.
- FP/TP depict same event.
- No root-motion gameplay drift.
- Interruptions do not stick animation state.
- Remote animation derives from replicated gameplay state.

---

# M12 — ART PASS 1: VISUAL IDENTITY

Only after graybox/network loop is healthy.

## Replace highest-value placeholders
- Glacier Arch;
- frozen river;
- ice cave;
- snowbanks;
- core glacier/rock kit;
- outpost kit;
- snow/ice/rock/wood materials;
- background mountains;
- exterior/cave/outpost lighting.

Use curated reference guide.

## Definition of Done
- Screenshot immediately reads as Snowdown's Glacier Valley.
- Glacier Arch is dominant but gameplay geometry remains unchanged in function.
- River reads as ice/movement route.
- Cave reads as deep cyan enclosed flank.
- Outposts provide warm human contrast.
- Player silhouettes remain readable.
- Competitive visibility is strong.

Do not add clutter that damages cover/sightline readability.

---

# M13 — CHARACTER / FIRST-PERSON HERO ART

## Integrate
- realistic base human;
- winter clothing;
- gloves;
- FP arms;
- basic face/hair;
- team distinction.

## Definition of Done
- Character reads as realistic human at normal gameplay distance.
- FP hands withstand close inspection.
- Gloves/clothing do not break animations.
- Cosmetics do not alter hitboxes.
- Team identification is readable without giant glowing outlines.
- FP and TP clothing language feels consistent.

---

# M14 — POLISHED VERTICAL SLICE

## Final pass
- tune movement;
- tune projectile charge/arc;
- tune catch;
- tune Map 01;
- polish VFX;
- polish UI;
- optimize;
- bug fix;
- improve lighting/materials;
- clean placeholder assets that remain visible;
- verify rights manifest.

Audio can still be deferred if explicitly desired, but temporary feedback may be necessary for usability tests.

## Required test matrix
- offline;
- headless server;
- 2 clients;
- 8 players/test clients;
- latency presets;
- packet loss;
- keyboard/mouse;
- controller;
- multiple graphics/performance settings where practical;
- repeated round reset;
- disconnect mid-action;
- OOB;
- match-end race cases.

## Definition of Done
The slice is ready for external evaluation when:

1. A new tester can join and understand the loop.
2. 4v4 matches complete reliably.
3. Movement feels responsive.
4. Packing/throwing/catching is satisfying.
5. Hits are readable and fair.
6. Network corrections are not routinely disruptive.
7. Glacier Valley produces varied engagements.
8. The visual identity is clearly Snowdown.
9. FP hands/snowball interaction feels like a hero feature.
10. No critical gameplay path requires debug commands.
11. No known exploit can trivially duplicate score/inventory/projectiles.
12. Project can be reproduced from repository + documented external assets.
13. External production assets have recorded rights/licenses.
14. Major remaining work is expansion/polish rather than repairing architecture.

---

# Explicitly After Vertical Slice

Do not place these on the critical path:

- additional maps;
- additional game modes beyond what is needed to prove core loop;
- ranked;
- progression;
- cosmetics store;
- battle pass;
- matchmaking backend;
- account platform;
- social/friends system;
- spectator/esports features;
- advanced replay system;
- special snowballs;
- dynamic blizzards;
- avalanches;
- deformable-snow simulation if expensive;
- wildlife;
- extensive facial animation;
- emotes;
- audio polish until user resumes it.

---

# Astra Execution Rule

For each milestone Astra should:

1. Read relevant locked specs.
2. State implementation plan briefly.
3. Implement the smallest complete version.
4. Add/maintain debug visibility.
5. Run deterministic tests.
6. Fix failures.
7. Record remaining known issues.
8. Keep project runnable.
9. Commit/checkpoint if repository workflow permits.
10. Move to next milestone only after Definition of Done is substantially met.

If blocked by a missing production asset, use a clearly labeled placeholder and continue.

If blocked by a genuine design contradiction, stop that affected decision, document the conflict, and request resolution rather than silently inventing a new rule.

---

# Recommended Read Order by Milestone

## M0–M3
- core gameplay/source-of-truth docs
- `PLAYER_STATE_MACHINE_AND_INPUT_LOCKED.md`
- `SNOWBALL_PHYSICS_AND_INTERACTION_TECHNICAL_SPEC_LOCKED.md`

## M4
- `MAP_01_GLACIER_VALLEY_LOCKED.md`
- environment direction

## M5–M8
- `MULTIPLAYER_NETWORK_ARCHITECTURE_LOCKED.md`
- player state spec
- snowball spec
- match rules

## M9
- map spec
- telemetry/debug docs

## M10
- HUD/UI direction
- impact/VFX direction

## M11
- `CHARACTER_ANIMATION_REQUIREMENTS_LOCKED.md`

## M12–M13
- `ASSET_MANIFEST_AND_OWNERSHIP_LOCKED.md`
- `REFERENCE_GUIDE_LOCKED.md`
- environment/character visual direction

---

# Final Principle

**Prove the toy. Prove the network. Prove the arena. Then make it beautiful.**

Astra should not optimize Snowdown for screenshots before it is fun, fair, network-stable and reproducible.
