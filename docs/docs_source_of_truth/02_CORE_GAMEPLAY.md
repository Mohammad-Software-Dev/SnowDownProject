# Snowdown — Core Gameplay

## Core loop
1. Spawn into a snowy arena with a small starting supply of packed snowballs.
2. Scan the environment for players and incoming threats.
3. Move between cover and snow sources.
4. Choose whether to quick-toss or charge a stronger/farther throw.
5. Lead moving targets and account for projectile arc.
6. Land body or head hits to score.
7. Dodge, use cover, or attempt a timed catch against incoming snowballs.
8. Replenish snowballs by packing usable snow.
9. Build a score/streak through accurate play.
10. Continue until the round timer expires.

## Perspective
**LOCKED:** First-person is the primary gameplay perspective. Third-person may be used for podiums, spectating, emotes, social spaces, or accessibility experiments, but competitive default gameplay is first-person.

## Player state
A player is always in one of these broad states: Active, Packing, ThrowCharging, ThrowRecovering, Catching, HitReacting, Sliding, or MatchInactive. Detailed transitions are in `14_DATA_MODELS_AND_STATE.md`.

## No health/death loop
**LOCKED:** There is no traditional health bar, death, kill credit, or mandatory respawn after normal hits.

A hit causes score/event consequences and a short readable reaction, after which the same player continues.

## Hit zones
**PROVISIONAL:**
- Body hit base score: **+10**
- Head hit base score: **+25**
- Head has scoring priority if a projectile overlaps both zones during the same simulation step.

The head reward is intentionally significant but not so large that body hits become worthless.

## Hit consequences
**PROVISIONAL baseline:**
- Victim score: **-3** per registered hit, clamped so match score never drops below 0.
- Active hit streak ends.
- Body hit: 0.30 s light reaction.
- Head hit: 0.45 s stronger snow-splat reaction.
- No forced camera spin and no long control removal.

The score penalty exists to make defense matter, but the attack reward is much larger than the victim penalty to avoid negative-score spirals.

## Snowball availability
**PROVISIONAL:** Carry capacity is 3 packed standard snowballs. Players can pack replacements only from valid snow surfaces/sources. Inventory and packing create tactical rhythm and stop nonstop spam.

## Throwing
Snowballs are simulated projectiles. Throw strength is charge-based. Exact provisional values are in `04_SNOWBALL_SYSTEM.md`.

## Defense
Players defend through movement, cover, line-of-sight breaks, terrain, prediction, and a high-skill catch mechanic. There is no permanent shield stat or passive armor.

## Information game
The world should reveal useful clues:
- projectile flight;
- snowball impact marks;
- directional impact audio;
- near-miss whoosh;
- footsteps and snow crunch;
- packing audio;
- footprints/disturbed snow where technically viable.

## Interaction priority
**PROVISIONAL:** When inputs conflict, movement remains available unless the state explicitly blocks it. Packing and full charge reduce tactical freedom but should not freeze the player. Catching briefly occupies the hands and prevents throwing during its window.

## Skill expression
The intended skill stack is: awareness → positioning → movement → prediction → projectile control → timing → resource management → catch mastery → map mastery.
