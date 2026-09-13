# Snowdown — Testing & Acceptance Criteria

## Core prototype acceptance
A prototype is playable when 4–8 remote players can complete repeated 5-minute rounds without manual server intervention and the following pass.

## Movement
- Player can walk, sprint, jump, crouch and return to standing.
- Movement cannot exceed configured speed envelopes under normal input.
- Crouch updates camera and hitbox together.
- Slide, if enabled, starts only under configured conditions and cannot create infinite acceleration.

## Inventory/packing
- Inventory never exceeds capacity.
- Packing only succeeds on valid snow source.
- Completing pack consumes correct time and adds exactly one snowball.
- Cancellation does not duplicate inventory.

## Throwing
- Throw cannot begin with zero inventory.
- Successful throw consumes exactly one snowball.
- Charge maps into configured launch speed.
- One projectile can never score twice.
- World impact cannot later become a player hit.

## Hit resolution
- Clear head impact produces exactly one head-hit event.
- Clear torso/limb impact produces exactly one body-hit event.
- Head wins defined overlap ambiguity.
- Cosmetic meshes do not change score hit regions.
- Server, not client, finalizes the result.

## Scoring
- Body and head scores match config.
- Victim penalty is applied once and score does not go below zero.
- Round-end snapshot cannot change after finalization.
- Tie-break ordering matches spec.

## Catch
- Eligible projectile during valid catch window is caught and does not score a hit.
- Late/early catch fails normally.
- Catch cannot create inventory above capacity.
- Catch spam cannot bypass recovery/cooldown.

## Multiplayer
- Party members are not split by normal matchmaking.
- Full instance does not exceed player cap.
- Join-in-progress obeys remaining-time rule.
- Disconnect/reconnect does not duplicate player or score.
- Match clock is server-owned.

## Experience tests
Playtesters should be able to answer “yes” to most:
- I can see snowballs coming often enough to react.
- I understand why I was hit.
- Head hits feel more rewarding than body hits.
- Missing still provides useful information.
- I can find snow without stopping the match flow.
- I spend little/no time waiting after being hit.
- Movement feels evasive but opponents remain predictable enough to lead.
- Playing with friends keeps us together.

## Performance targets
Exact platform targets are **TBD**. Establish frame-rate, server tick, bandwidth, memory, and projectile-count budgets before production lock.
