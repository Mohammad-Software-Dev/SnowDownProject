# SNOWDOWN — SNOWBALL PHYSICS & INTERACTION TECHNICAL SPEC — LOCKED

Status: **LOCKED / AUTHORITATIVE TECHNICAL DIRECTION**

This document defines how the canonical competitive snowball should behave technically. Exact tuning values remain data-driven unless explicitly marked locked.

## Core Identity

Snowballs are **physical, visible, arcing projectiles**.

They must never feel like reskinned bullets or hitscan weapons.

Skill comes from:
- aim;
- leading moving targets;
- judging range;
- understanding arc;
- choosing charge;
- movement;
- timing;
- catching.

There is no hidden random spread on a standard stationary throw.

---

## Canonical Projectile

The standard snowball is the baseline projectile for the entire first vertical slice.

Do not add special snowballs until the standard projectile is genuinely fun.

Conceptual runtime data:
- ProjectileId
- OwnerPlayerId
- TeamId
- SpawnServerTick / SpawnServerTime
- Position
- Velocity
- ChargeNormalized
- IsScoringActive
- HasImpacted
- PredictedSequenceId where relevant
- Lifetime
- Optional VariantId reserved for later

A projectile may produce **at most one terminal competitive result**.

---

## Physics Model

Use a deterministic-enough custom projectile step or tightly controlled Godot physics implementation rather than depending on unstable rigid-body behavior for competitive resolution.

Preferred model:
- explicit position/velocity integration each physics tick;
- gravity applied each step;
- optional drag applied through a controlled formula;
- swept collision query between previous and next position;
- authoritative simulation on server.

The projectile should behave like a thrown compact snowball, not like a fully simulated loose rigid body.

### Why
This provides:
- predictable gameplay;
- easier networking;
- easier rewind/history testing;
- reliable high-speed collision;
- simpler tuning;
- deterministic test cases.

---

## Gravity

Gravity scale must be independently configurable.

Goal:
- subtle arc at short range;
- obvious readable arc at medium/long range;
- enough drop that players must learn distance;
- never so exaggerated that the projectile looks floaty.

Start near world gravity and tune projectile-specific gravity scale from playtests.

Do not hard-code Godot's default world gravity as an untouchable design rule.

---

## Drag

Drag is optional but supported.

If used:
- keep it modest;
- apply consistently server/client;
- keep formula explicit and deterministic;
- do not create dramatic mid-flight slowing.

Drag should help the snowball feel physical, not unpredictable.

A first implementation may use zero drag if gravity + launch speed already feels good.

---

## Launch Speed

Prototype starting range remains approximately:
- low / quick throw: ~14 m/s;
- medium: ~20 m/s;
- maximum charge: ~26 m/s.

These values are **PROVISIONAL / DATA-DRIVEN**.

Charge-to-speed mapping should use a tunable curve, preferably easing so useful throws occupy a broad portion of the charge range.

Do not map charge linearly unless it feels best in testing.

---

## Charge Mapping

Conceptual mapping:

`charge_time -> normalized_charge -> launch_speed`

Prototype timings:
- minimum release threshold ~0.08 s;
- normal strength around ~0.65 s;
- maximum around ~1.25 s.

After max charge:
- power no longer increases;
- optional max-hold/auto-release remains configurable.

The server validates charge timing.

---

## Projectile Size

The visual snowball may be slightly larger than the gameplay collision sphere, but the difference must be small and consistent.

Use a simple spherical gameplay collider.

Benefits:
- predictable collision;
- easy sweep tests;
- readable fairness;
- no orientation-dependent hit volume.

Exact radius remains tunable.

Recommended prototype gameplay radius range:
- roughly 0.08–0.12 m.

Start near 0.10 m and playtest.

Do not enlarge collision excessively just to make hits easy.

---

## Collision Detection

Use **swept sphere / shape casting** from previous projectile position to proposed next position each server physics step.

Do not rely only on discrete overlap at the final position.

Required to prevent tunneling at maximum velocity.

Potential collision classes:
- PlayerHead
- PlayerBody
- CatchVolume
- WorldSolid
- SnowballProjectile if projectile-vs-projectile is enabled
- OutOfBounds / KillPlane

Collision layers/masks should make these categories explicit.

---

## Hit Resolution Priority

For a single simulation step, resolve terminal outcomes deterministically.

Recommended priority:

1. Valid Catch
2. PlayerHeadHit
3. PlayerBodyHit
4. SnowballVsSnowball
5. WorldImpact
6. Continue flight

However, historical timing matters: a catch only wins if the authoritative catch window is valid at the relevant compensated time.

If head and body overlap on the same player during the same authoritative sweep:
- **HeadHit wins.**

A projectile becomes non-scoring immediately after its terminal outcome.

---

## Throw Origin

The player aims with the camera, but the snowball visually leaves the throwing hand.

This creates a camera/hand mismatch that must be solved deliberately.

### Authoritative Aim Target
1. Build an aim ray from the camera/crosshair.
2. Find a target point along the aim ray:
   - first valid world/player obstruction, or
   - a configurable far aim distance if nothing is hit.
3. Determine the physical launch origin near the throwing hand / character throw socket.
4. Compute launch direction from launch origin toward the selected target point.

This produces:
- crosshair-consistent aiming;
- believable hand origin;
- fewer near-wall shots clipping incorrectly.

The server must independently reconstruct or validate the plausible throw origin/direction using authoritative player state and submitted aim orientation.

---

## Near-Wall Throw Safety

Before spawning:
- sweep from player/hand launch origin through a small initial path;
- if the hand is inside or behind nearby geometry, move the authoritative spawn point to a safe valid point or reject/redirect cleanly.

Never allow players to throw through walls because the camera can see around a corner while the hand/body cannot.

Crosshair ray visibility alone is insufficient.

---

## Self-Collision

The projectile must ignore its owner character briefly or until it clears the owner's collision volume.

Preferred:
- explicit owner collision exception;
- restore normal collision only if future reflected/bounced variants require it.

The standard snowball should never immediately hit its thrower due to launch overlap.

---

## Player Collision

Use separate authoritative head/body gameplay hit regions.

### Head
- distinct sphere/capsule/simple collider attached to head rig region;
- stable competitive size;
- unaffected by hats/hair/cosmetics.

### Body
- one or more simple shapes covering remaining valid body;
- avoid overly detailed skeletal collision that creates inconsistent tiny gaps.

Gameplay hitboxes should follow the character accurately enough for fairness but remain intentionally simple.

---

## Catch Volume

The catch volume is not a permanent passive shield.

It is active only during server-validated catch timing.

Requirements:
- positioned around reachable hand/front-body area;
- frontal-angle requirement;
- approaching-velocity requirement;
- limited active time;
- server-authoritative.

A snowball behind the player or moving away must not be catchable merely because it overlaps a large trigger.

Exact dimensions/angle remain tunable.

---

## Catch Approach Test

A valid catch should evaluate at minimum:
- projectile inside/through catch volume during valid window;
- projectile velocity is generally toward player;
- projectile approach direction lies inside configured frontal cone;
- player is in legal Catching state;
- projectile still scoring-active;
- projectile not already terminally resolved.

Where lag compensation is enabled, evaluate against bounded historical state.

---

## World Surface Response

Standard snowballs do **not** ricochet competitively in V1.

On world collision:
1. projectile scoring state ends;
2. authoritative projectile terminates;
3. emit surface-specific impact event;
4. visual debris/powder may continue cosmetically.

### Snow Ground
- soft puff;
- little/no bounce;
- no scoring after impact.

### Ice
- tighter breakup;
- cosmetic fragments may skid;
- canonical projectile does not continue as a scoring ricochet.

### Rock / Wood / Structure
- flatten/break;
- short-lived snow residue/decal;
- no scoring bounce.

This keeps hit logic readable.

---

## Snowball-vs-Snowball

**PROVISIONAL FEATURE, architecture supported.**

If enabled:
- authoritative projectile sweeps can test against other active projectiles;
- collision terminates both;
- server emits `SnowballCollision`;
- both become non-scoring immediately;
- clients play sharp powder/chunk burst.

This may become a high-skill interaction.

Do not let implementation complexity delay standard player/world collision.

Recommended implementation order:
1. leave disabled;
2. complete vertical slice;
3. enable in a test branch;
4. assess whether it is readable/fun.

---

## Projectile Lifetime

Prototype maximum lifetime: ~5 seconds.

Terminate immediately if:
- lifetime exceeded;
- outside valid world bounds;
- below kill plane;
- terminal collision occurred.

Lifetime remains data-driven.

---

## Rotation

Visual snowball may rotate/spin in flight.

Rotation is cosmetic only for a spherical standard projectile.

Do not make spin alter standard projectile trajectory during V1.

No Magnus effect in first prototype.

---

## Wind

No gameplay-affecting wind in the first competitive slice.

Environmental snow particles may suggest wind visually, but projectile trajectory must not secretly drift.

Weather must not introduce random competitive ballistics.

---

## Thrower Velocity Inheritance

Support configurable inherited player velocity.

Recommended prototype:
- inherit a modest, physically plausible portion of thrower's world velocity;
- vertical inheritance may be clamped/tuned separately.

This helps throws while sprinting/sliding feel physical.

However:
- inheritance must not make slide throws wildly overpowered;
- exact multiplier remains data-driven.

Recommended starting test:
- 0.5–1.0 horizontal velocity inheritance.

---

## Spawn Orientation / Aim During Movement

Aim is based primarily on camera orientation, not character mesh facing delay.

Server validates aim rotation rate/plausibility.

Throwing while:
- walking;
- jumping;
- crouching;
- sliding;
should remain supported according to player state spec.

No hidden accuracy penalty.

---

## Prediction

### Local Shooter
Client may:
- start throw animation immediately;
- spawn predicted visual snowball;
- integrate same projectile formula locally.

Prediction projectile is cosmetic until server confirmation.

### Reconciliation
Authoritative projectile spawn includes:
- authoritative projectile ID;
- predicted/action sequence ID;
- spawn time/tick;
- transform;
- velocity.

Client:
- matches prediction to authoritative object;
- merges/remaps without duplicate;
- smoothly corrects small error;
- snaps only when error exceeds safe threshold.

Never allow predicted impact to award score.

---

## Remote Projectile Presentation

Remote clients should interpolate or simulate from authoritative projectile state.

Because projectile motion is deterministic from:
- spawn position;
- velocity;
- gravity;
- drag;
it is preferable to replicate spawn + occasional corrections rather than full transforms every frame if testing proves this reliable.

Do not prematurely optimize bandwidth before correctness.

---

## Lag Compensation

The server remains final.

If rewind is used:
- store bounded history of player hitboxes/catch state;
- rewind only within configured cap;
- never rewind world geometry unless a later moving-world mechanic requires it;
- record rewind duration for debugging.

Projectile path remains authoritative.

Avoid client-side rewound score decisions.

---

## Friendly Fire

Standard default:
- teammate collisions may produce cosmetic impact if desired;
- no teammate scoring;
- no negative score from friendly hit.

Whether friendly players physically block projectiles remains **PROVISIONAL**.

Preferred first test:
- projectile collides with teammate and puffs harmlessly, terminating.

This preserves physical world consistency and prevents shooting through teammates.

If frustrating, test pass-through later.

---

## Spawn Protection Interaction

Protected players:
- cannot award score when hit;
- projectile behavior should still remain readable.

Recommended prototype:
- protected player collision may terminate projectile with harmless impact;
- protection ends when player throws/commits offensive action per match rules.

Do not allow protected players to intentionally body-block forever.

---

## Throw Preview

No full trajectory line by default.

The crosshair/charge UI may communicate strength, but players should learn projectile arc.

Optional tutorial-only trajectory assistance may be explored later.

Do not ship a permanent grenade-style arc prediction without explicit design change.

---

## Surface Tagging

World surfaces should expose a simple gameplay material category:

- `Snow`
- `Ice`
- `Rock`
- `Wood`
- `GenericHard`
- `OutOfBounds`

Impact event includes surface category so VFX/audio can select appropriate presentation.

Do not couple projectile gameplay code directly to specific art materials.

---

## Godot Implementation Recommendation

Preferred architecture:

`SnowballProjectile` as a gameplay node driven by explicit server simulation.

Possible node composition:
- Node3D root;
- MeshInstance3D (client/presentation only);
- optional Area3D/shape helper;
- debug collision visualization;
- gameplay script.

Do not require `RigidBody3D` as the authoritative competitive simulation.

Use Godot physics shape queries / direct space state for swept collision.

Keep authoritative physics code reusable in:
- server runtime;
- client prediction;
- automated trajectory tests.

---

## Shared Projectile Math

Put trajectory/integration math in one shared pure-function utility/resource where practical.

Conceptually:

`simulate_step(position, velocity, dt, config) -> next_position, next_velocity`

and

`charge_to_speed(normalized_charge, config) -> speed`

Benefits:
- client/server parity;
- deterministic tests;
- easier balancing;
- fewer prediction mismatches.

---

## Configuration

All projectile tuning should live in a central gameplay configuration resource/data object.

At minimum:
- radius;
- min/max launch speed;
- charge curve;
- gravity scale;
- drag;
- lifetime;
- velocity inheritance;
- collision masks;
- safe launch offset;
- catch dimensions;
- catch angle;
- max lag rewind;
- prediction reconciliation threshold.

Do not scatter magic numbers across scripts.

---

## Debug Visualization

Development mode should support toggles for:
- projectile collision sphere;
- swept path;
- velocity vector;
- predicted trajectory;
- authoritative trajectory;
- aim ray;
- camera target point;
- hand launch origin;
- safe adjusted launch origin;
- head/body hitboxes;
- catch volume/cone;
- lag-rewound hitbox;
- terminal collision point/normal;
- projectile ID and owner.

This is essential for Astra to diagnose "that should have hit" reports.

---

## Deterministic Test Fixtures

Create fixed tests with known starting transforms.

### Trajectory
- zero-drag low throw;
- medium charge;
- max charge;
- fixed gravity;
- expected position after known timestamps within tolerance.

### Collision
- direct body hit;
- direct head hit;
- sweep through thin obstacle;
- high-speed thin obstacle;
- near miss;
- head/body simultaneous overlap => head;
- world collision terminates projectile.

### Throw Origin
- player standing in open space;
- hand close to wall;
- camera peeking around wall while hand blocked;
- crouched under low geometry.

### Catch
- frontal valid catch;
- too early;
- too late;
- side angle invalid;
- rear invalid;
- projectile moving away invalid.

### Networking
- predicted vs authoritative same parameters;
- 100 ms delayed spawn reconciliation;
- correction after aim difference;
- duplicate authoritative packet does not duplicate projectile.

### Lifetime
- projectile terminates at max lifetime;
- kill-plane removal;
- bounds removal.

### Projectile-vs-Projectile
If enabled:
- two balls intersect same tick;
- both terminal exactly once;
- neither scores afterward.

---

## Acceptance Criteria

The snowball system is technically ready for the vertical slice when:

1. Projectile visibly arcs at meaningful ranges.
2. Identical config/input produces closely matching client/server paths.
3. No high-speed tunneling through normal map/player geometry.
4. Crosshair aim feels consistent with hand-origin throw.
5. Throwing beside walls cannot shoot through them.
6. Body/head resolution is deterministic.
7. Catch vs hit resolves once and consistently.
8. A projectile can never score twice.
9. World impacts always disable scoring immediately.
10. Prediction reconciles without duplicate visible snowballs.
11. All tuning values are centralized/data-driven.
12. Debug visualization can explain disputed collisions.

## Final Feel Target

A Snowdown snowball should feel like **a compact physical object you actually threw with your hand** — visible, learnable, arc-based and satisfying — while the implementation remains precise enough for competitive multiplayer.
