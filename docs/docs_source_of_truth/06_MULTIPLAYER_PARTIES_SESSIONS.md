# Snowdown — Multiplayer, Parties & Sessions

## Public session model
**LOCKED:** Public play uses capped server instances and round-based sessions. The world does not accept unlimited players.

A full instance rejects new match joins; matchmaking places additional players into another instance.

## Party
**LOCKED:** Friends can form a party before matchmaking. The matchmaker treats the party as one placement unit and does not split it in normal matchmaking.

**PROVISIONAL:** initial maximum party size = maximum team size for team queues and up to 8 for FFA/private play.

## Party continuity
Once grouped, party members remain grouped across results, map transitions, and new public matches until they leave, are kicked by party owner rules, or the party dissolves.

## Join friend
If a friend is in a joinable public session:
- if a slot exists and join-in-progress is allowed, join the same instance;
- if full, offer “Join Party / Wait for Next Round” rather than silently place the user elsewhere;
- if the friend's party would exceed mode capacity, explain why.

## Team assignment
**LOCKED:** Matchmaking should keep a party on the same team whenever the mode allows it. Competitive integrity may require party-size restrictions in ranked modes later.

## Private Snow Worlds
Private rooms are session-based social/custom-game spaces.

Host-configurable settings should eventually include map, mode, player cap, round duration, score target where applicable, team rules, join permissions, and special-snowball rules.

**PROVISIONAL:** visibility options = Invite Only, Friends, Public Custom.

## Reconnect
A disconnected player should have a **PROVISIONAL 90-second reservation** for their slot. Their avatar may be removed from active play immediately to avoid farming an idle body. Rejoin restores current round score/state where practical.

## Session lifecycle
Public instance states: Booting → Lobbying/Filling → Countdown → InMatch → Results → Transition → InMatch/Shutdown.

A public server may run several consecutive rounds for its current cohort. Matchmaking can backfill available slots between rounds and, when allowed, mid-round.

## Empty servers
When no players remain, the instance may shut down after a short grace period. There is no design requirement for public worlds to persist forever.

## Capacity
Player cap is mode/map-specific. Server software must enforce hard capacity. Never allow a client to spawn an extra player entity beyond capacity because a friend invite arrived late.

## Region and latency
**TBD:** final regional matchmaking policy. Prefer lowest-latency viable region while keeping parties together. The game must display poor-connection warnings rather than hide severe latency.

## Ranked
**OUT OF SCOPE (V1).** Ranked should not be implemented until base hit registration, matchmaking, anti-cheat, and scoring are stable.
