# SNOWDOWN — IMPACT VFX AND FEEDBACK — LOCKED

Status: **LOCKED / AUTHORITATIVE ART & FEEDBACK DIRECTION**

This document defines the approved impact-feedback language for Snowdown. Astra should treat it as a design constraint unless the user explicitly revises it.

## Core Principle

Snowdown impacts are **realistic snow breakup with controlled exaggeration for competitive readability**.

Target balance:
- ~65% believable snow physics
- ~35% gameplay exaggeration

Snow itself is the spectacle. Do not translate firearm, lethal-combat, or generic shooter VFX language into snowball combat.

## Feedback Hierarchy

A successful event should communicate in this order:
1. Physical impact/reaction animation
2. Snow breakup / VFX
3. Sound
4. UI confirmation

UI confirms an event that already feels obvious; it should not compensate for unclear physical feedback.

## Body Hit

- Compact, weighty `THUMP`.
- Medium powder burst.
- Several readable snow clumps/fragments.
- Temporary snow residue on clothing.
- Short believable physical flinch/reaction.
- Preserve player control unless gameplay rules explicitly require otherwise.

## Head Hit

Use the same physical snow language as a body hit, but make recognition immediate:
- Larger/faster radial powder burst.
- Stronger head/upper-body reaction.
- Distinct audio signature.
- Clear but restrained UI confirmation.
- No cartoon explosion and no violent/lethal presentation.

## Near Miss

- Strong directional `WHOOSH`.
- Projectile/powder wake may assist perception at suitable speeds.
- Avoid excessive screen effects.
- Near misses should make dodging feel exciting and help the player infer projectile direction.

## Catch

Catching is a hero interaction and should feel nearly as satisfying as landing a hit:
- Sharp glove/snow contact.
- Small crumble/compression of snow.
- Hands visibly absorb momentum.
- Strong, immediate confirmation without magical/glowing effects.

## Surface Impacts

### Wood / Rock / Hard Wall
- Snowball compresses/flattens and breaks.
- Powder + compacted chunks.
- Short-lived snow splat/residue appropriate to material.

### Snow Ground
- Softer `PUFF`.
- Shallow powder plume.
- Minimal persistent splat.

### Ice
- Harder/crisper contact sound.
- Tighter breakup.
- Some fragments may slide/skitter along the surface.
- Keep behavior physically plausible and readable.

## Snowball-vs-Snowball

If supported by gameplay:
- Colliding snowballs disintegrate into a sharp burst of powder and clumps.
- Treat this as a high-skill, highly legible interaction.
- Do not add explosion/firearm language.

## Snow Residue

Where performance permits:
- Snow may remain briefly on jackets/gloves and suitable hard surfaces.
- Residue should reinforce impact location/material.
- It must not become expensive persistent simulation during early milestones.
- Prototype gameplay clarity first; polish accumulation later.

## Explicitly Forbidden Visual Language

Do not use:
- Blood or gore.
- Red blood-like screen splashes.
- Sparks as generic hit confirmation.
- Muzzle-flash-like effects.
- Fire/explosive fireballs.
- Metallic bullet-hit sounds.
- Generic firearm hit effects.
- Excessive glowing projectiles.
- Effects that imply lethal damage.

## Performance / Implementation Priority

During prototypes, implement the event taxonomy and readable feedback before expensive simulation.

Priority:
1. Distinct body/head/surface/catch/near-miss event hooks.
2. Clear placeholder VFX and audio.
3. Reaction animation.
4. Material-specific effects.
5. Snow residue.
6. Advanced particles/deformation only after gameplay is proven.

All effects should be tunable through data/config where practical. Astra must not hard-code final artistic values prematurely.

## Final Identity

**Believable humans + tactile snowballs + physically grounded snow breakup + controlled competitive exaggeration.**

Hits should be satisfying because snow has weight, breakup, sound, residue, and physical reaction—not because Snowdown imitates a shooter.
