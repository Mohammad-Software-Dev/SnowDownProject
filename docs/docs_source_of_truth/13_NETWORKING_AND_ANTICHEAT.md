# Snowdown — Networking & Anti-Cheat

## Authority model
**LOCKED:** Dedicated/authoritative server is preferred for public competitive matches. The client requests actions; server validates and owns final gameplay truth.

## Client prediction
Movement should use standard client prediction/reconciliation suitable for the chosen engine. Throw animation and projectile presentation may be predicted locally for responsiveness, but score is only granted after authoritative validation.

## Projectile networking
Recommended model:
- client sends throw request with input timestamp, charge state, aim orientation, and local action sequence;
- server validates inventory, action state, charge duration bounds, and plausible orientation/timing;
- server spawns authoritative projectile;
- clients receive projectile replication/interpolation;
- shooter may render a predicted projectile and reconcile to server projectile.

## Hit registration
**LOCKED:** server decides catch/head/body/world outcome.

**TBD:** exact lag compensation. If rewind is implemented, cap rewind window and validate historical player state to avoid extreme high-ping advantage.

## Server validation
At minimum validate:
- movement speed/acceleration envelopes;
- teleport distance;
- throw rate and charge timing;
- snowball inventory;
- pack completion and valid snow source;
- catch rate/window;
- impossible aim transforms where applicable;
- score changes only from server events.

## Anti-cheat philosophy
Do not overbuild anti-cheat in the first prototype, but architecture must not require trusting the client. Instrument suspicious events so patterns can be detected later.

## Network degradation
The game should remain readable under moderate latency. If latency becomes severe:
- show connection quality;
- do not fake confirmed hits indefinitely;
- reconcile predicted hit feedback cleanly;
- avoid long client-side state that the server can invalidate.

## Disconnect behavior
Server removes or neutralizes disconnected avatars promptly. Reconnect rules live in multiplayer spec.

## Abuse/griefing considerations
- rate-limit chat/pings if implemented;
- party kick/host controls in private rooms;
- no teammate scoring by friendly hits by default;
- prevent repeated spawn targeting via safe spawn selection/protection.
