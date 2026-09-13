# Snowdown — AI Build Reference

## Purpose
This file is the operating manual for AI coding/design agents working on Snowdown.

## Required reading order
Before implementing a feature, read:
1. `00_README.md`
2. `01_GAME_VISION.md`
3. `02_CORE_GAMEPLAY.md`
4. this file
5. the relevant subsystem file
6. `18_DECISIONS_OPEN_QUESTIONS.md`

## Do not guess policy
When a requirement is absent:
- search this folder first;
- if still absent, mark the behavior as TBD;
- choose a reversible prototype default only if implementation cannot proceed without it;
- expose the default as configuration;
- record the assumption in the decision log.

Never silently invent monetization, progression power, health, death, weapons, ranking rules, classes, abilities, or special snowballs.

## Implementation priorities
Optimize in this order:
1. gameplay correctness;
2. network authority/security;
3. responsiveness/readability;
4. testability/configurability;
5. performance;
6. polish.

Do not sacrifice authoritative scoring for prettier prediction.

## Code expectations
- isolate gameplay constants in config/data;
- use explicit names from glossary where practical;
- avoid “damage”, “kill”, and “weapon” names in domain code when “hit”, “score”, and “snowball” are accurate;
- add automated tests for state transitions and scoring;
- log authoritative gameplay events;
- keep presentation effects separate from scoring logic;
- make head/body collider logic deterministic and testable;
- reject impossible client requests rather than correcting them into valid actions silently.

## Feature completion definition
A gameplay feature is not complete until:
- server/client ownership is clear;
- tunable values are configuration, not magic constants;
- happy path works;
- invalid state/input is handled;
- network replication is considered;
- accessibility impact is considered when relevant;
- telemetry/debug event exists if useful;
- acceptance criteria are updated/passed;
- source-of-truth doc is updated.

## Prototype guardrails
For the first prototype, do not spend major effort on:
- advanced progression;
- monetization;
- ranked matchmaking;
- many maps;
- advanced snow deformation;
- large cosmetic systems;
- special snowball catalog;
- social hub production polish.

The prototype must answer: **Is moving, predicting, dodging, packing, throwing, and landing snowballs on other human players genuinely fun?**

## Conflict resolution
If implementation and docs disagree, do not assume code is newer. Check `18_DECISIONS_OPEN_QUESTIONS.md`. If no explicit decision exists, docs remain canonical and code should be corrected or the discrepancy escalated for a design decision.
