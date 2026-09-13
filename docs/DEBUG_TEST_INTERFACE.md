# Snowdown — Debug & Test Interface Contract

Astra must be able to inspect and reproduce gameplay states without manually replaying a long session.

## Required development-only debug state
Expose or display at minimum:
- build/config version;
- client/server/listen role;
- peer/player IDs;
- player transform/velocity;
- grounded/jump/crouch/sprint/slide state;
- packed snowball count;
- current packing progress;
- current throw charge;
- active projectile count;
- each debug projectile ID/owner/position/velocity/age;
- last hit classification and scoring event;
- current score;
- current match phase and authoritative timer;
- network RTT/packet-loss simulation once networking exists.

## Required deterministic scenarios
Create easy launch/warp paths for:
- movement_basic;
- sprint_slide;
- pack_and_throw;
- short_body_hit;
- long_body_hit;
- head_hit;
- moving_target_lead;
- catch_window (when implemented);
- two_client_throw;
- latency_100ms (network phase);
- packet_loss_low (network phase).

Scenarios should use stable spawn positions and known target distances so changes can be compared.

## Verification philosophy
For a bug or gameplay complaint:
1. reproduce it;
2. inspect state/metrics;
3. identify likely root cause;
4. make the smallest robust fix;
5. rerun the same scenario;
6. report before/after evidence.

Never treat static code inspection as proof that a gameplay change works.
