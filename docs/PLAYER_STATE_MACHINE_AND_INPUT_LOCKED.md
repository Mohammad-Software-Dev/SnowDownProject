# SNOWDOWN — PLAYER STATE MACHINE & INPUT/ACTION SPEC — LOCKED

Status: **LOCKED / AUTHORITATIVE TECHNICAL DIRECTION**

This document defines the player action-state rules, interrupt priorities, input semantics and implementation expectations Astra should follow unless explicitly revised.

## Core Principle

Snowdown should feel **responsive, physical and readable**.

The player should retain movement freedom during most interactions. Actions should compete mainly for the hands, not freeze the whole character.

Astra may implement the logic as layered state machines rather than one giant enum, but the externally visible behavior must preserve the rules below.

---

## Recommended State Architecture

Use **three cooperating layers** instead of one monolithic state enum.

### 1. Match State
- `MatchInactive`
- `MatchActive`

### 2. Locomotion State
- `Grounded`
- `Airborne`
- `Crouched`
- `Sliding`
- `OutOfBoundsRecovery`

### 3. Hand / Action State
- `HandsFree`
- `Packing`
- `ThrowCharging`
- `ThrowRecovering`
- `Catching`
- `HitReactingLight`
- `HitReactingStrong`

This layered model avoids false conflicts such as a player being unable to slide because they are charging, or unable to move because they are packing.

The legacy conceptual ActionState values remain valid externally:
`Active`, `Packing`, `ThrowCharging`, `ThrowRecovering`, `Catching`, `HitReacting`, `Sliding`, `MatchInactive`.

---

## MatchInactive

Player is not allowed to perform competitive actions.

Examples:
- pre-round countdown before control opens;
- results state;
- loading/transition;
- temporary server-controlled reset.

Allowed:
- camera look if appropriate;
- UI navigation;
- non-competitive presentation.

Blocked:
- movement that changes competitive position;
- packing;
- throwing;
- catching;
- scoring actions.

---

## HandsFree

Default action state.

Allowed:
- move;
- sprint;
- crouch;
- jump;
- slide;
- begin packing;
- begin throw charge if inventory > 0;
- begin catch;
- interact with eligible map objects if later added.

---

## Packing

Purpose: replenish one packed snowball from valid snow.

Prototype baseline:
- duration ~0.85 s;
- movement capped to ~60% of walk speed;
- sprint blocked;
- throw blocked;
- catch may interrupt;
- jump interrupts/cancels;
- hit interrupts/cancels;
- leaving valid snow source interrupts/cancels;
- manual release/cancel interrupts;
- successful completion increments authoritative inventory by 1 if capacity allows.

Packing should not root the player in place.

### Packing Entry Conditions
Require:
- MatchActive;
- HandsFree;
- inventory below capacity;
- valid packable snow source;
- grounded or otherwise explicitly allowed by config;
- not in strong hit reaction;
- not in throw recovery.

### Packing Completion
On valid completion:
- server emits `SnowballPacked`;
- inventory increments exactly once;
- transition to HandsFree.

### Packing Cancellation
No partial snowball reward unless future design explicitly adds one.

---

## ThrowCharging

Begins when the player holds the throw input and has at least one packed snowball.

Movement remains available.

Allowed:
- walking;
- crouching;
- jumping;
- sliding where legal;
- aim/look;
- release to throw;
- catch interrupt, according to priority rules below.

Restricted:
- sprint may remain allowed or be modestly reduced based on playtest; default should not fully root the player;
- packing blocked;
- starting a second throw blocked.

### Charge Timing
Prototype values remain data-driven:
- minimum useful release threshold ~0.08 s;
- normal strength ~0.65 s;
- max strength ~1.25 s;
- no additional strength beyond max;
- optional auto-release/cancel timeout remains provisional.

### Charge Cancellation
Default cancellation paths:
- entering MatchInactive;
- strong invalidation from server;
- beginning catch;
- out-of-bounds reset;
- optional manual cancel if input design exposes one.

If catch interrupts charge, no snowball is consumed until an actual authoritative throw occurs.

---

## Throw Release

On valid throw release:
1. local client may immediately play predicted hand animation/projectile;
2. send throw request to server with action sequence/timing/aim;
3. server validates state/inventory/charge;
4. server consumes one packed snowball;
5. server spawns authoritative projectile;
6. player enters ThrowRecovering.

A snowball is consumed **only once**, on authoritative accepted throw.

---

## ThrowRecovering

Short post-release hand recovery.

Prototype baseline: ~0.45 s.

Allowed:
- normal movement;
- crouch;
- jump;
- slide where legal;
- aim/look.

Blocked:
- new throw;
- packing;
- catch by default for the first prototype.

### Rationale
Catch cancellation during throw recovery could create unreadable zero-risk offense/defense chains. Keep it blocked initially.

If playtesting later proves this feels unfair, catch-cancel timing can be revisited.

At recovery end:
- transition to HandsFree.

---

## Catching

High-priority defensive action.

Prototype:
- visible animation around ~300 ms;
- perfect catch window ~120 ms;
- short recovery ~0.35 s after success/attempt.

Allowed:
- movement at reduced or normal speed depending feel;
- aim/look;
- crouch if animation supports it.

Blocked:
- throwing;
- packing;
- starting another catch until recovery.

### Catch Entry
Catch may begin from:
- HandsFree;
- Packing (cancels packing);
- ThrowCharging (cancels charge);
- Sliding if physically/visually compatible;
- grounded or airborne if animation/collider remains fair.

Catch should **not** begin from:
- ThrowRecovering in first prototype;
- MatchInactive;
- strong HitReacting state;
- OOB recovery.

### Catch Priority
Catch has higher priority than Packing and ThrowCharging because defense should remain reactive.

It does not have higher priority than authoritative hit resolution if the server determines the catch input was too late.

---

## HitReactingLight

Triggered by body hit.

Prototype baseline: ~0.30 s.

Goals:
- readable physical acknowledgment;
- preserve agency;
- no forced camera spin.

Allowed:
- limited movement;
- camera look.

Blocked or interrupted:
- packing cancels;
- throw charge cancels unless playtesting later prefers continuation;
- catch cancels/fails if authoritative hit has already won;
- sprint temporarily disabled.

At end:
- return to HandsFree or relevant locomotion state.

---

## HitReactingStrong

Triggered by head hit.

Prototype baseline: ~0.45 s.

Same philosophy as light reaction but slightly more disruptive/readable.

Allowed:
- camera look;
- limited movement.

Blocked:
- packing;
- throwing;
- catching;
- sprint.

Never turn this into a stun-lock system.

---

## Sliding

Sliding is primarily a locomotion state, not a hand-action state.

A player may be:
- Sliding + HandsFree;
- Sliding + ThrowCharging;
- Sliding + ThrowRecovering;
- Sliding + Catching, if animation/collider remains fair.

Prototype entry:
- grounded;
- speed above threshold;
- crouch/slide input;
- valid slope/surface conditions.

Slide should not automatically cancel throw charge.

Packing while sliding is **not allowed**.

---

## Jumping / Airborne Rules

Jumping is locomotion, not a hand-action state.

Allowed while:
- HandsFree;
- ThrowCharging;
- ThrowRecovering;
- Catching if animation remains fair.

Jumping cancels Packing.

No bunny-hop speed exploit.

Airborne catch remains **PROVISIONAL**:
- technically allowed if networking/hitbox remains understandable;
- disable if it creates unreadable animation or unfair catch volume.

---

## Crouch Rules

Crouch is locomotion posture.

Allowed in most hand states except where animation breaks.

Crouch must:
- update camera;
- update authoritative collider;
- update head/body hit regions consistently;
- never allow desynchronization between visible body and hitbox.

---

## Sprint Rules

Default allowed when:
- MatchActive;
- not Packing;
- not strong HitReacting;
- sufficient movement input.

ThrowCharging may allow sprint initially, but if that creates excessive run-and-gun behavior, tune movement multiplier rather than hard-rooting the player.

Catching may reduce speed but should not automatically freeze the player.

---

## Input Priority

When multiple inputs occur in the same frame/tick, resolve in this conceptual priority:

1. `MatchInactive / forced reset`
2. authoritative `HitReacting`
3. `Catch`
4. `ThrowRelease`
5. `ThrowChargeStart`
6. `Jump`
7. `Slide/Crouch`
8. `Pack`
9. `Sprint`
10. normal movement/look

This is a behavior priority, not necessarily literal code order.

Important exceptions:
- a valid throw release already accepted by the authoritative server cannot be retroactively canceled by a later same-tick catch request;
- server timestamp/order decides close races;
- catch vs hit race must resolve deterministically.

---

## Input Buffering

Use short input buffering only where it improves responsiveness without enabling automation-like chaining.

Recommended prototype buffers:
- jump buffer: ~80–120 ms;
- catch buffer: **none or extremely small** initially;
- throw start buffer after recovery: ~50–100 ms;
- pack buffer: none required.

Catch timing should remain skill-based; avoid generous buffering that effectively enlarges the perfect-catch window.

All values remain data-driven.

---

## Input Bindings — Keyboard / Mouse

Recommended defaults:

- Move: `WASD`
- Look/Aim: Mouse
- Throw / Charge: `Mouse1`
- Catch: `Mouse2`
- Jump: `Space`
- Sprint: `Left Shift`
- Crouch / Slide: `Left Ctrl` or `C`
- Pack Snow / Interact: `E`
- Scoreboard: `Tab`
- Pause/Menu: `Esc`

Do not overload Throw and Catch onto the same button.

Pack/Interact may later separate if contextual ambiguity becomes a problem.

---

## Input Bindings — Controller

Recommended conceptual mapping:

- Move: Left Stick
- Look: Right Stick
- Throw / Charge: Right Trigger
- Catch: Left Trigger
- Jump: South face button
- Crouch / Slide: East face button
- Pack / Interact: West face button
- Sprint: Left Stick Click
- Scoreboard: View/Select equivalent
- Pause: Menu/Start equivalent

Controller mapping must remain fully remappable later.

---

## Hold vs Toggle

Prototype defaults:
- Sprint: hold;
- Crouch: hold or toggle configurable later;
- Throw charge: hold and release;
- Pack: hold;
- Scoreboard: hold;
- Catch: press;
- Slide: press crouch while sprinting/eligible.

Avoid hidden mode switches.

---

## Action Legality Matrix

### HandsFree
- Move: YES
- Sprint: YES
- Jump: YES
- Slide: YES
- Pack: YES
- Throw: YES
- Catch: YES

### Packing
- Move: LIMITED
- Sprint: NO
- Jump: CANCELS
- Slide: NO
- Pack: CONTINUE
- Throw: NO
- Catch: INTERRUPTS

### ThrowCharging
- Move: YES
- Sprint: YES / TUNABLE
- Jump: YES
- Slide: YES
- Pack: NO
- ThrowRelease: YES
- Catch: INTERRUPTS

### ThrowRecovering
- Move: YES
- Sprint: YES
- Jump: YES
- Slide: YES
- Pack: NO
- Throw: NO
- Catch: NO (prototype)

### Catching
- Move: YES / possibly reduced
- Sprint: NO or reduced
- Jump: PROVISIONAL
- Slide: PROVISIONAL
- Pack: NO
- Throw: NO
- Catch: NO until recovery

### HitReacting
- Move: LIMITED
- Sprint: NO
- Jump: NO by default
- Slide: NO
- Pack: NO
- Throw: NO
- Catch: NO

### MatchInactive
- Competitive actions: NO

---

## Server Authority

The client may predict presentation, but server owns final action legality.

Server validates:
- current action state;
- cooldowns;
- inventory;
- movement envelope;
- valid snow source;
- catch timing;
- throw timing;
- match phase;
- spawn protection interactions.

A client cannot force a state transition by sending the resulting state directly.

Clients send **intent**, not authority.

---

## Canonical Events

Use/retain these canonical events:
- `SnowballPacked`
- `ThrowChargeStarted`
- `SnowballThrown`
- `SnowballCaught`
- `PlayerBodyHit`
- `PlayerHeadHit`
- `HitStreakChanged`
- `ScoreChanged`

Recommended additional implementation events:
- `PackingStarted`
- `PackingCancelled`
- `ThrowChargeCancelled`
- `ThrowRecoveryStarted`
- `CatchStarted`
- `CatchFailed`
- `HitReactionStarted`
- `SlideStarted`
- `SlideEnded`

Events used for telemetry should include server timestamp/tick and involved IDs.

---

## State Invariants

Must always hold:
- cannot be Packing and ThrowCharging simultaneously;
- cannot consume more snowballs than inventory contains;
- ThrowRecovering cannot begin without an accepted throw;
- catch success and hit success cannot both resolve for the same projectile;
- one projectile produces at most one terminal competitive result;
- MatchInactive blocks competitive score-changing actions;
- cosmetics do not modify competitive hitbox size;
- local prediction cannot permanently diverge from authoritative action state.

---

## Race Conditions to Test

Astra must explicitly test:

1. Catch pressed on same tick as body hit.
2. Catch pressed on same tick as head hit.
3. Throw released same tick as catch input.
4. Hit received during Packing completion frame.
5. Hit received during ThrowCharging.
6. Jump during final Packing frame.
7. Slide entry while ThrowCharging.
8. Throw release during slide.
9. Catch during slide.
10. Round ends while projectile is in flight.
11. Round ends during Packing completion.
12. Disconnect during ThrowCharging.
13. Inventory reaches zero while prediction expects one remaining.
14. Multiple pack-complete events caused by retransmission.
15. Double catch requests from packet duplication/retry.

All outcomes must be deterministic and server-owned.

---

## Godot Input Implementation

Use Godot InputMap actions rather than hard-coded key checks.

Recommended action names:
- `move_forward`
- `move_back`
- `move_left`
- `move_right`
- `look`
- `jump`
- `sprint`
- `crouch_slide`
- `pack_interact`
- `throw_primary`
- `catch`
- `scoreboard`
- `pause`

Gameplay code should consume action abstractions, not physical keys/buttons.

This supports:
- remapping;
- controller;
- accessibility;
- automated testing.

---

## Data-Driven Configuration

Keep tunable:
- pack duration;
- pack movement multiplier;
- charge thresholds;
- throw recovery;
- catch active window;
- catch total animation/recovery;
- hit reaction durations;
- sprint multipliers during charge/catch;
- jump buffer;
- throw buffer;
- slide eligibility;
- action interrupt permissions where marked provisional.

Do not scatter these values across scripts.

---

## Implementation Priority

1. Layered state representation.
2. InputMap actions.
3. HandsFree ↔ Packing.
4. HandsFree ↔ ThrowCharging → ThrowRecovering.
5. Catch interrupt rules.
6. Hit reaction interrupt rules.
7. Slide coexistence with hand states.
8. Multiplayer authority/reconciliation.
9. Input buffering.
10. Animation polish.

---

## Vertical Slice Acceptance Criteria

The player-state/input system is ready when:

1. Every core action can be performed without ambiguous input.
2. Packing never duplicates inventory.
3. Throwing never consumes two snowballs.
4. Catch reliably interrupts Packing and ThrowCharging.
5. ThrowRecovering prevents immediate spam.
6. Hit reaction cannot create long stun-locks.
7. Sliding and throwing can coexist where intended.
8. Jump cancels Packing.
9. Server can reject illegal transitions cleanly.
10. Client recovers from rejected predicted action without getting stuck.
11. Keyboard/mouse and controller can perform all core actions.
12. All race-condition tests above produce deterministic outcomes.

## Final Feel Target

**The player should feel free to move, but committed in their hands.**

Snowdown should reward timing and decision-making without making the controls feel sticky, animation-locked or overly shooter-like.
