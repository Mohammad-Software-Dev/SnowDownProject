# Snowdown — Data Models & State

This document defines conceptual data shapes. Concrete serialization depends on engine/backend.

## Player runtime state
Required fields conceptually include:
- PlayerId
- TeamId/None
- Position/Rotation/Velocity
- ActionState
- PackedSnowballs
- Score
- HitStreak
- HeadHits
- BodyHits
- TimesHit
- CatchCount
- IsSpawnProtected
- IsConnected
- IsLateJoiner
- CosmeticLoadoutId/reference

## ActionState enum
Canonical conceptual values:
`Active`, `Packing`, `ThrowCharging`, `ThrowRecovering`, `Catching`, `HitReacting`, `Sliding`, `MatchInactive`.

Implementation may layer movement/action substates rather than use one enum, but externally visible transitions must preserve these rules.

## Snowball runtime state
- ProjectileId
- OwnerPlayerId
- SpawnTime
- Position
- Velocity
- ChargeNormalized
- IsScoringActive
- HasImpacted
- OptionalVariantId
- OptionalBounce/interaction history for trick-shot detection later

## Match state
- MatchId
- ModeId
- MapId
- ConfigVersion
- SessionState
- RoundStartServerTime
- RoundEndServerTime
- PlayerRoster
- ScoreboardSnapshot
- JoinPolicy

SessionState conceptual values: `Lobbying`, `Countdown`, `InMatch`, `Results`, `Transition`, `Shutdown`.

## Canonical gameplay events
- `RoundCountdownStarted`
- `RoundStarted`
- `PlayerJoinedMatch`
- `PlayerLeftMatch`
- `SnowballPacked`
- `ThrowChargeStarted`
- `SnowballThrown`
- `SnowballCaught`
- `SnowballWorldImpact`
- `PlayerBodyHit`
- `PlayerHeadHit`
- `HitStreakChanged`
- `ScoreChanged`
- `RoundEnded`
- `PlacementFinalized`

Each event should carry MatchId, server timestamp, involved entity IDs, and config version where useful.

## Gameplay configuration shape
At minimum group configuration by:
- movement;
- throwing/projectile;
- packing/inventory;
- catch;
- scoring;
- hit reaction;
- match timing;
- spawn protection;
- mode-specific rules.

## Invariants
- PackedSnowballs ∈ [0, capacity].
- Match score ≥ 0 for default mode.
- A projectile can produce at most one scoring hit.
- Only server-authorized events change score.
- Cosmetics cannot modify competitive collider dimensions.
- Player cannot be both Packing and ThrowCharging.
- After RoundEnded, gameplay events cannot modify final placement.
