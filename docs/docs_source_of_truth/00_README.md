# Snowdown — Source of Truth

**Document status:** Canonical project specification  
**Purpose:** Human-readable and AI-readable reference for designing, implementing, testing, and extending Snowdown.  
**Rule:** If another document, chat, prototype, or code comment conflicts with this folder, this folder wins unless a later decision is explicitly recorded in `18_DECISIONS_OPEN_QUESTIONS.md`.

## How to use this specification
Snowdown is expected to be built with substantial AI assistance. Therefore the documentation must remove ambiguity rather than rely on tribal knowledge.

Every implementation agent should:
1. Read this file first.
2. Read `01_GAME_VISION.md`, `02_CORE_GAMEPLAY.md`, and `15_AI_BUILD_REFERENCE.md` before making gameplay changes.
3. Read the system-specific document before changing that system.
4. Treat **LOCKED** decisions as requirements.
5. Treat **PROVISIONAL** values as current defaults that should be implemented as configurable data, not hard-coded assumptions.
6. Treat **TBD** items as unresolved. Do not silently invent a permanent design. If a prototype requires a value, choose a temporary value, expose it as configuration, and record it in the decision log.
7. Preserve the game's non-lethal, playful identity. Do not import shooter conventions automatically.

## Decision labels
- **LOCKED** — intentional product decision. Change only through an explicit design decision.
- **PROVISIONAL** — current target/default. Implement it, but keep it tunable.
- **TBD** — not decided. Do not present it as settled.
- **OUT OF SCOPE (V1)** — deliberately excluded from the first production target.

## Canonical document map
- `01_GAME_VISION.md` — identity, audience, design pillars, non-goals.
- `02_CORE_GAMEPLAY.md` — complete moment-to-moment loop and core rules.
- `03_PLAYER_MOVEMENT.md` — locomotion, camera, dodge philosophy, collision rules.
- `04_SNOWBALL_SYSTEM.md` — inventory, packing, charge, projectile behavior, catches, impacts.
- `05_SCORING_AND_MATCH_RULES.md` — scoring, hit consequences, rounds, placements, ties.
- `06_MULTIPLAYER_PARTIES_SESSIONS.md` — matchmaking, parties, join friend, private worlds, server lifecycle.
- `07_GAME_MODES.md` — mode rules and mode-specific victory logic.
- `08_MAP_AND_LEVEL_DESIGN.md` — map metrics, cover, routes, spawn rules, snow sources.
- `09_PROGRESSION_REWARDS_COSMETICS.md` — fair progression and reward economy principles.
- `10_UI_UX_AUDIO_FEEDBACK.md` — HUD, menus, accessibility, audiovisual feedback.
- `11_ART_DIRECTION_WORLD.md` — characters, environments, visual language, tone.
- `12_TECHNICAL_ARCHITECTURE.md` — system boundaries, server/client ownership, save/config strategy.
- `13_NETWORKING_AND_ANTICHEAT.md` — authoritative simulation, replication, validation, abuse prevention.
- `14_DATA_MODELS_AND_STATE.md` — canonical gameplay entities, states, event names, configuration schema.
- `15_AI_BUILD_REFERENCE.md` — implementation instructions specifically for AI coding agents.
- `16_TESTING_ACCEPTANCE_CRITERIA.md` — functional and experiential tests.
- `17_ROADMAP_AND_MILESTONES.md` — prototype-to-production sequence.
- `18_DECISIONS_OPEN_QUESTIONS.md` — changelog, unresolved design questions, rejected alternatives.
- `19_GLOSSARY.md` — canonical vocabulary.

## Current product definition
**LOCKED:** Snowdown is a first-person, 3D, multiplayer snowball-fighting game focused on projectile prediction, movement, dodging, awareness, social play, and playful competition. Players do not kill one another and do not use health/death as the main gameplay loop. Public play is round-based. Friends can party together and stay together across rounds.

## Source-of-truth maintenance rule
Any meaningful change to gameplay must update:
1. the relevant system document,
2. `18_DECISIONS_OPEN_QUESTIONS.md`, and
3. tests/acceptance criteria when behavior changes.

Do not let code become the only place where a rule exists.
