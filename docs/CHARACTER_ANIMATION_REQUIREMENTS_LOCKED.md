# SNOWDOWN — CHARACTER ANIMATION REQUIREMENTS — LOCKED

Status: **LOCKED / AUTHORITATIVE ANIMATION DIRECTION**

Vertical-slice target: **26 core animation requirements**.

Astra should use blending, additive animation, retargeting, procedural aim/look, and IK so these do not become 26 completely separate bespoke clips.

## Core philosophy

Snowdown characters are realistic humans. Animation should be physically believable, athletic, readable, and slightly snappier than pure simulation where gameplay requires it.

**Gameplay timing owns the animation, not the other way around.**

Animations must obey `PLAYER_STATE_MACHINE_AND_INPUT_LOCKED.md`. Gameplay must never wait for a cinematic animation to finish.

## Rig baseline

Use a standard humanoid skeleton with:
- root/pelvis/spine/neck/head;
- clavicles, arms, hands, finger support suitable for gloves;
- legs, feet, toes where practical;
- optional twist bones;
- hand IK targets;
- foot IK targets;
- optional look/aim target.

Cosmetics must not require unique skeleton topology.

## Third-person locomotion — 8 requirements

1. **Idle** — neutral, alert winter posture.
2. **Directional locomotion blend** — forward/back/strafe/diagonals.
3. **Sprint** — athletic, non-military running posture.
4. **Crouch idle** — aligned with real gameplay hitboxes.
5. **Crouch locomotion** — directional where practical.
6. **Jump start** — short, responsive takeoff.
7. **Airborne/fall** — rising/apex/falling presentation.
8. **Landing** — brief, non-locking recovery.

## Sliding — 2 requirements

9. **Slide enter/core slide** — signature low stance; compatible with upper-body overlays where possible.
10. **Slide exit** — short recovery to normal locomotion.

Jump-from-slide may reuse jump animation initially.

## Third-person snowball actions — 6 requirements

11. **Pack snowball** — gather, compress, rotate/compress, ready.
12. **Hold/ready pose** — snowball held naturally; preferably additive.
13. **Throw charge** — progressive wind-up driven by normalized charge.
14. **Throw release** — realistic athletic overhand throw; release marker must align with projectile spawn.
15. **Catch** — fast frontal catch motion; success/fail may share base clip.
16. **Catch recovery** — short return-to-ready; may be part of #15.

Upper-body layering is preferred so these can coexist with locomotion where the state machine permits.

## Third-person hit reactions — 2 requirements

17. **Body hit** — brief readable recoil; no ragdoll; baseline around 0.30 s.
18. **Head hit** — stronger but short reaction; no spin/fall; baseline around 0.45 s.

Directional reaction variants are polish, not required initially.

## First-person hands/arms — 7 requirements

19. **FP idle/locomotion** — subtle hands/arms presentation; no weapon-like bob.
20. **FP pack snowball** — hero animation: gather, compress, rotate, compress, form ball.
21. **FP hold/ready** — ball visible without blocking the center view.
22. **FP charge** — progressive wind-up driven by normalized charge.
23. **FP throw release** — hero throw with precise release marker and fast recovery.
24. **FP catch** — hands snap into catch volume and absorb momentum.
25. **FP hit reaction** — subtle hand/camera-space reaction; body/head may vary intensity.

## Utility — 1 requirement

26. **Match-ready transition** — short neutral ready transition. May reuse idle if unnecessary.

Podium, emotes, victory animations, social idles, dances, and cinematics are not required for the vertical slice.

## Layering architecture

Use four conceptual layers:

### Base locomotion
Idle, move, sprint, crouch, airborne, slide.

### Upper-body action
Pack, hold, charge, throw, catch.

### Reaction/additive
Body hit, head hit, subtle recoil.

### Procedural
Aim/look offsets, hand IK, foot IK, slope alignment, snowball attachment, small first-person motion.

Do **not** author unique whole-body clips for every combination such as sprint+charge, slide+throw, crouch+catch, or jump+throw.

## Aim/look

Use spine/neck additive aim offsets and limited shoulder correction. When camera rotation exceeds believable torso twist, rotate the character body through gameplay/controller logic.

## IK

Hand IK may help packing, catch presentation, and snowball holding.

Foot IK is desirable for Glacier Valley slopes, but it is polish-level for early graybox work.

Gameplay collision volumes must never depend on rendered fingertip positions.

## Root motion

**Do not use root motion for competitive locomotion.**

Movement remains controlled by gameplay/controller physics for networking, prediction, tuning, and slope consistency.

## Animation markers

Expose presentation markers such as:
- `pack_contact`
- `pack_complete_visual`
- `throw_release`
- `catch_window_visual_start`
- `catch_contact`
- `catch_recovery`
- `hit_peak`

These markers control presentation only. They never grant inventory, score, catch success, or projectile authority.

## First-person / third-person synchronization

Both rigs depict the same server-owned gameplay event.

For throws, server timing decides actual projectile release. For catches, server decides whether the ball was caught.

Do not let the first-person animation claim success before the authoritative result when this would visibly contradict gameplay.

## Cosmetic compatibility

Winter clothing must not break the action set.

Requirements:
- puffer jackets support shoulder range;
- gloves support pack/catch poses;
- scarves/hoods use simple secondary motion where appropriate;
- accessories cannot obstruct core hand actions.

Avoid cosmetics needing bespoke gameplay animation sets.

## Retargeting

Prefer:
- one canonical humanoid rig;
- standardized proportions;
- retargetable sources;
- procedural adjustments for body-size variation.

Do not make each cosmetic character a separate animation project.

## Placeholder policy

Astra may use licensed placeholder sources, simple procedural poses, temporary mannequins, or rough hand-keyed animations during gameplay milestones.

Placeholders must be replaceable and must respect locked timing/state behavior.

**Do not block core gameplay waiting for final realistic animation.**

## Must-have before first multiplayer playtest

Rough but functional coverage is enough for:
- idle/locomotion;
- sprint;
- jump/air/land;
- crouch;
- slide;
- pack;
- hold;
- charge;
- throw;
- catch;
- body hit;
- head hit;
- FP pack;
- FP charge/throw;
- FP catch.

## Production-quality priority

### Tier A — hero actions
1. FP pack
2. FP charge/throw
3. FP catch
4. TP throw
5. TP catch
6. slide

### Tier B — constantly visible
7. TP locomotion
8. sprint
9. crouch
10. jump/land
11. FP idle/movement
12. hold/ready

### Tier C — polish
13. body/head reactions
14. transitions
15. IK/secondary motion

## Facial animation

Vertical slice only needs subtle facial life:
- blink;
- basic eye/head look;
- neutral expression;
- optional simple exertion/reaction.

Detailed facial acting is not a blocker.

## Networking

Replicate gameplay state, not animation playback every frame.

Remote animation should derive from:
- authoritative velocity;
- grounded/airborne/sliding state;
- hand/action state;
- charge normalized;
- confirmed catch/hit events;
- aim orientation.

Animation is never competitive authority.

## Debug/test scene

Create an animation test scene or menu supporting:
- TP/FP toggle;
- trigger every core state;
- vary movement speed;
- vary charge 0→1;
- simulate body/head hit;
- catch success/fail;
- slide test;
- slow motion;
- loop clips;
- show state, blend weights, events, IK, and throw-release timing.

## Acceptance criteria

Animation integration is ready when:
1. Locomotion follows gameplay velocity immediately.
2. Root motion never overrides competitive movement.
3. Pack animation matches pack timing.
4. Throw release visually matches projectile spawn.
5. Charge pose clearly reflects charge progression.
6. Catch motion matches catch timing/volume.
7. Body/head reactions are distinct.
8. Slide can coexist with allowed upper-body actions.
9. FP hands do not excessively obscure view.
10. FP/TP actions represent the same server event.
11. Interruptions never leave the player stuck.
12. Remote animation derives from replicated state.
13. Placeholder clips can be swapped without rewriting gameplay logic.

## Final direction

Snowdown does not need hundreds of animations.

It needs a compact layered system where **packing, charging, throwing, catching, sliding, and first-person hands** receive the most polish.

Target: **26 core animation requirements**, placeholders early, hero-action quality later.
