# Snowdown — Snowball System

## Standard snowball
The standard snowball is the canonical competitive projectile. Special variants may exist later, but the game must be fun with this projectile alone.

## Inventory
**PROVISIONAL:**
- carry capacity: 3;
- spawn inventory: 3;
- successful catch adds 1 if inventory has space;
- if inventory is full, a catch still prevents the hit but the caught snowball is discarded as a puff unless later playtesting prefers another behavior.

## Packing
Players replenish from surfaces tagged as valid snow sources.

**PROVISIONAL:**
- pack one snowball time: 0.85 s;
- packing is cancellable by releasing interaction, jumping, being hit, or beginning a catch;
- cancelled packing produces no snowball unless progress reaches completion;
- player moves at max 60% of walk speed while packing;
- cannot sprint or throw while packing.

## Throw charge
**PROVISIONAL:** charge is continuous from 0 to 1.
- minimum release threshold: 0.08 s;
- reaches normal strength at 0.65 s;
- reaches maximum strength at 1.25 s;
- holding beyond maximum does not increase power;
- maximum hold before auto-release/cancel: **TBD**; prototype may use 3.0 s.

## Projectile speed
**PROVISIONAL:** map normalized charge to launch speed using an ease-out curve:
- minimum useful speed: 14 m/s;
- standard (~0.5 charge): ~20 m/s;
- maximum: 26 m/s.

Gravity scale, drag, and size must be independently tunable. Initial target should create a clearly visible arc at medium/long range rather than bullet-like flight.

## Throw recovery
**PROVISIONAL:** 0.45 s from release until another throw can start. Recovery should include readable hand animation and prevent extreme spam.

## Aiming
No random accuracy cone for a stationary standard throw. Skill should come from projectile physics and player input, not hidden bloom. If movement penalties are ever added, they must be explicit and minimal.

## Collision and hit registration
**LOCKED:** The server is authoritative for final hit results.

Projectile outcomes: PlayerBodyHit, PlayerHeadHit, WorldImpact, Catch, Expired/OutOfBounds.

A projectile can score only once. On scoring/catch/world impact it becomes non-scoring immediately and transitions to an impact effect/despawn path.

## Head/body resolution
Head collider is a distinct scoring region attached to the character rig. Body region covers the remaining valid avatar. Cosmetic hats must not alter competitive hitbox size.

## Catch mechanic
**PROVISIONAL:**
- input opens a 120 ms “perfect catch” window inside a ~300 ms catch animation;
- only projectiles approaching from the front hemisphere and within hand/catch volume are eligible;
- a successful catch cancels hit registration and triggers catch event/feedback;
- catch has a short recovery (~0.35 s) to prevent spam;
- repeated catch input may have an additional cooldown if playtesting requires it.

The exact window and eligible angle are high-priority tuning variables.

## World impact
Snowballs should create a surface-appropriate splat/puff, positional sound, and optional decal. Decals are transient and reset between rounds.

## Projectile lifetime
**PROVISIONAL:** 5 s maximum lifetime or immediate despawn below world kill plane / outside arena bounds.

## Special snowballs
**OUT OF SCOPE (V1 prototype).** Later variants must be sidegrades/utility, not direct permanent power upgrades. Preferred themes: powder cloud, lob, comedic marking, large slow snowball. Avoid “ice ball” or damage escalation that undermines the non-lethal identity.
