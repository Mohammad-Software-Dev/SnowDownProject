# Snowdown — Player Movement

## Goal
Movement must support dodging, peeking, flanking, sliding, and readable prediction without becoming a hyper-mobile arena shooter.

## Baseline movement values
All values are **PROVISIONAL** and must live in editable gameplay configuration.

| Parameter | Default |
|---|---:|
| Walk speed | 5.0 m/s |
| Sprint speed | 7.5 m/s |
| Crouch speed | 2.75 m/s |
| Ground acceleration | 24 m/s² |
| Ground deceleration | 30 m/s² |
| Air control factor | 0.35 |
| Jump apex height | ~1.1 m |
| Jump cooldown | none beyond natural landing |
| Crouch transition | 0.15 s |

## Sprint
**PROVISIONAL:** Sprint is available while moving mostly forward and not during strong hit reaction. Sprint does not consume stamina in the first prototype. Packing reduces speed and prevents sprinting.

## Jump
Jump exists for terrain traversal and dodging. Repeated bunny hopping should not be optimal. Preserve momentum but reduce air control enough that airborne movement is more predictable than grounded movement.

## Crouch
Crouch lowers the head target, supports snowbank cover, and reduces movement speed. Crouching must update hitboxes and camera height consistently on server and client.

## Sliding
**PROVISIONAL:** Slide can begin when grounded, sprinting at ≥6.5 m/s, and pressing crouch. Initial flat-ground slide target: 0.8 s. Downhill slopes may extend velocity; uphill terrain should shorten it. Sliding is interruptible by jump only if playtesting confirms it is readable and not exploitable.

## Camera
**LOCKED:** Camera motion must never intentionally simulate pain or violent impact. Hit feedback may add a small positional bump and snow overlay, but no forced large rotation. FOV changes should be subtle.

**PROVISIONAL:**
- default horizontal/engine-equivalent FOV target: configurable, player-adjustable;
- sprint FOV increase: small, ≤5° equivalent;
- no weapon viewmodel; visible hands/mitten animation is optional for prototype and desirable for production.

## Collision
Player capsules should not allow stacking or entering geometry. Players may softly push/separate rather than hard-block narrow spaces if this improves social readability. Final player-vs-player collision policy is **TBD**.

## Spawn protection
Because players do not die normally, spawn protection is only relevant at initial spawn or late join. **PROVISIONAL:** 2 seconds of non-scoring protection that ends immediately if the protected player throws.

## Movement exploits to prevent
- infinite speed gain from repeated slide-jumps;
- crouch spam that desynchronizes head hitbox;
- slope launching beyond intended traversal;
- packing while sprinting at full speed;
- clipping through snowbanks/roofs;
- hiding the head hitbox inside camera-inaccessible geometry.
