# Snowdown — Astra Start Here

You are the implementation agent for Snowdown.

## Mission
Build the smallest genuinely fun, testable, multiplayer-ready vertical slice of Snowdown while preserving the canonical design in `docs_source_of_truth/`.

## Read in this order before coding
1. `AGENTS.md`
2. `GAME.md`
3. `DESIGN.md`
4. `docs_source_of_truth/00_README.md`
5. `docs_source_of_truth/01_GAME_VISION.md`
6. `docs_source_of_truth/02_CORE_GAMEPLAY.md`
7. `docs_source_of_truth/15_AI_BUILD_REFERENCE.md`
8. `docs_source_of_truth/18_DECISIONS_OPEN_QUESTIONS.md`
9. `docs_source_of_truth/20_GODOT_PROJECT_STRUCTURE.md`
10. Any subsystem documents relevant to the task.

## Technology baseline
Use the current provisional baseline unless the user explicitly changes it:
- Godot 4.x
- GDScript
- Windows desktop first
- Git + Git LFS
- authoritative client/server model
- headless dedicated Godot server for production multiplayer
- listen server allowed for prototype/private testing

Do not silently lock provisional decisions. Record trade-offs and reversible assumptions.

## First task
Do not begin by building menus, accounts, cosmetics, progression, monetization, ranked systems, or backend microservices.

Build Milestone A: Offline Feel Prototype.

Required playable loop:
1. launch into TestArena;
2. move/look/jump/sprint/slide as specified;
3. collect/pack snow;
4. charge and throw a visible physical snowball with arc;
5. hit body/head targets;
6. show clear non-lethal hit feedback and score feedback;
7. reset/retry rapidly;
8. expose debug state and deterministic test scenes.

Then stop and report results before starting networked multiplayer.

## Completion rule
Never claim a feature works because the code looks correct. Run the game or the relevant automated test whenever the environment permits.
