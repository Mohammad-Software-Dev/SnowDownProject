# Snowdown — First-Person Hands & Snowball Direction — LOCKED

Status: **LOCKED**

This document defines the approved first-person hand/arm and core snowball visual/interaction direction. Astra should treat these principles as authoritative unless the user explicitly revises them.

## Core principle
Snowdown's first-person snow interaction should feel tactile, believable, physical, and satisfying. The player should feel that a snowball is actually gathered, compressed, held, thrown, caught, and broken apart—not spawned like ammunition.

## First-person hands and arms
- Target realistic human anatomy and proportions, consistent with the locked realistic character direction.
- Hands should be visible and expressive without occupying excessive screen space.
- Use believable winter gloves/mittens, sleeves, fabric transitions, and material response.
- First-person arms should visually correspond to the third-person character rather than using exaggerated FPS-only anatomy.
- Snow may visibly adhere to gloves/sleeves during interaction where practical.
- Hands/arms are hero assets because packing, holding, charging, throwing, and catching are core verbs.

## Packing interaction
A normal pack should visually communicate:
1. gather/scoop snow;
2. compress between hands;
3. rotate/reposition;
4. compress again;
5. transition to ready/hold.

The snow should visibly compact. Small crumbs/powder may fall away. Do not make a finished ball appear magically.

Prototype timing may begin around 0.7–1.0 seconds for a standard pack, but timing is **PROVISIONAL** and must remain data-driven and tunable for game feel.

## Snowball appearance
- Not a mathematically perfect white sphere.
- Slightly irregular handmade silhouette.
- Compacted core with subtle dents/compression marks.
- Loose powder/granular breakup around the surface where practical.
- Subtle rotation during flight.
- Must remain readable against snow-covered terrain.
- Use natural shading/value separation to preserve readability; do not solve readability by making the core projectile glow.
- A restrained powder wake at higher velocity may be tested if it improves tracking without visual clutter.

## Throwing
- Base the motion on believable human throwing biomechanics.
- Gameplay responsiveness may accelerate or clean up the motion, but it should not read like firing a weapon.
- Charge/throw readiness should be communicated through pose, hand tension, body motion, audio, and subtle presentation rather than firearm conventions.
- Physical projectile arc and visible travel remain mandatory.

## Catching
- Catch animation should feel physically plausible: hands meet and control the incoming snowball.
- Gameplay may use a forgiving/tunable catch window, but visual presentation should remain grounded.
- Do not rely on cartoon magnetism or obvious supernatural effects unless a later game mechanic explicitly requires them.

## Impact and breakup baseline
Impacts should begin from believable snow physics and then exaggerate only enough for competitive readability.

Target philosophy: roughly **60% believable breakup / 40% gameplay exaggeration**.

A typical hit may include:
- initial compression/deformation;
- snowball fragmentation;
- small chunks;
- fine powder burst;
- temporary snow residue on clothing/surfaces where feasible.

Head hits may use a larger/faster radial powder response than body hits so the classification is immediately readable.

Avoid:
- sparks;
- muzzle-flash language;
- bullet-impact language;
- explosive/fire effects;
- glowing core projectiles as the default;
- violent/lethal framing.

## Snow residue
Where technically and artistically practical, repeated interaction should leave subtle snow evidence:
- powder on gloves;
- snow on sleeves/clothing after impacts;
- surface splats/residue;
- small transient particles/chunks.

This should support tactile believability without becoming an expensive simulation requirement for the first vertical slice.

## Reference usage
Real-world photos of gloved hands packing snow are appropriate anatomy/material/interaction references. External copyrighted imagery is reference-only unless licensing explicitly permits production use. Do not copy protected character designs or artwork.

Useful reference concepts include:
- real gloves compressing fresh snow;
- compacted snow texture and irregular snowball silhouettes;
- real snowball breakup on impact;
- believable winter sleeve/glove construction;
- first-person hand placement that preserves gameplay visibility.

## Prototype priority
For Milestone A, prioritize in this order:
1. satisfying throw timing and physical projectile behavior;
2. clear first-person hold/charge/throw poses;
3. readable projectile in flight;
4. satisfying impact breakup;
5. basic packing animation;
6. snow residue and secondary polish.

Do not delay core gameplay validation for expensive hand-detail, cloth, residue, or snow-deformation systems.

## Identity statement
**Believable human hands physically making and throwing real-feeling snowballs, with just enough animation and snow-VFX exaggeration to make competitive play exceptionally readable and satisfying.**
