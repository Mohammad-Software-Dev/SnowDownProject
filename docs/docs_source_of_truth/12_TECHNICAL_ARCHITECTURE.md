# Snowdown — Technical Architecture

## Engine
**TBD:** Unity, Unreal, Godot, or another engine has not been canonically selected. All gameplay rules in this spec are engine-agnostic.

AI agents must not rewrite design requirements to match an engine limitation without documenting the trade-off.

## Architecture principles
1. Server-authoritative competitive outcomes.
2. Data-driven tuning values.
3. Clear separation of simulation, presentation, networking, persistence, and UI.
4. Deterministic-enough event ordering for scoring even if full physics is not deterministic.
5. No client trust for score, inventory grants, hit validation, or match placement.

## Suggested system boundaries
- `PlayerMovementSystem`
- `PlayerActionStateMachine`
- `SnowballInventorySystem`
- `SnowPackingSystem`
- `ThrowChargeSystem`
- `SnowballProjectileSystem`
- `CatchSystem`
- `HitResolutionSystem`
- `ScoringSystem`
- `MatchStateSystem`
- `SpawnSystem`
- `Party/Matchmaking integration`
- `CosmeticLoadoutSystem`
- `UIFeedbackSystem`
- `AudioFeedbackSystem`
- `TelemetrySystem`

Names are conceptual, not required class names.

## Configuration
All values tagged PROVISIONAL should live in data assets/config files/server tunables. Do not scatter constants through code.

Configuration should be versioned. A match should know which gameplay config version it used so telemetry can be compared correctly.

## Persistence
Persistent account data should include identifiers, progression, unlocks, cosmetics, settings, challenge progress, and social metadata required by the chosen backend. Match score and projectile entities are transient and must not be written as durable account truth.

## Event-driven gameplay
Prefer explicit domain events such as `SnowballThrown`, `SnowballCaught`, `PlayerBodyHit`, `PlayerHeadHit`, `ScoreChanged`, `RoundStarted`, `RoundEnded`. This improves testing, telemetry, replay/debugging, and AI code comprehension.

## Time ownership
Server owns authoritative round clock. Clients render a synchronized representation and may smooth small corrections.

## Save/version migrations
Persistent schemas require version fields and migration strategy before production. Do not assume serialized object layouts remain stable forever.

## Observability
Server logs should support correlation by match ID, player ID (privacy-safe internal identifier), projectile/event ID, config version, and timestamp.
