# SNOWDOWN — MATCH STRUCTURE & MODES — LOCKED

Status: **LOCKED / AUTHORITATIVE DIRECTION**

## Primary Competitive Mode

**Team Snowdown — 4v4**

This is the canonical first multiplayer mode and should define initial map scale, readability, networking priorities, scoring presentation and competitive pacing.

The first multiplayer slice should contain:
- one map;
- one mode;
- two teams of four;
- standard snowballs only;
- score-based competition;
- no classes;
- no abilities;
- no power-ups;
- no special snowballs;
- no complex objectives.

**One excellent 4v4 snowball fight is more valuable than five mediocre modes.**

## Win Condition

Highest team score when the match timer expires wins.

Normal hits do not eliminate players and do not create a death/respawn loop.

Body/head scoring follows the core gameplay specification. Exact point values remain tunable.

## Match Duration

Prototype target: **~6 minutes** of continuous play.

This is a starting value, not a permanent balance lock.

Match duration must be data-driven and easy to tune through playtesting.

## Match Flow

1. Players load/assemble.
2. Teams occupy opposite starting outposts/safe areas.
3. Short pre-match countdown.
4. Arena opens / match begins.
5. Continuous score-based snowball combat.
6. Clear final-seconds warning.
7. At zero:
   - higher score wins;
   - if tied, enter Sudden Snow.
8. Results/podium.
9. Rematch/return flow.

Avoid unnecessary downtime between these states.

## Sudden Snow

If regulation ends tied, enter **Sudden Snow**.

Prototype rule:
**the next valid scoring hit wins the match.**

Goals:
- immediate tension;
- simple to understand;
- thematic;
- no separate objective system required.

Exact overtime presentation, countdown and maximum duration remain provisional.

A future playtest may require safeguards against indefinite avoidance, but do not over-engineer this before testing.

## Catch Scoring

**Initial rule: catches do not directly award match points.**

A successful catch already:
- prevents an opponent's score;
- can provide possession/inventory advantage;
- creates a high-skill reversal.

This avoids encouraging defensive point farming.

Revisit only if playtesting shows catches need additional strategic reward.

## Spawning

Because normal hits do not eliminate players, standard respawn loops are unnecessary.

Spawning primarily applies to:
- match start;
- late join;
- exceptional reset/out-of-bounds recovery.

Teams begin from opposite warm outposts/safe areas with multiple exits into the arena where practical.

Prototype spawn protection:
- approximately 2 seconds;
- non-scoring protection;
- ends immediately if the protected player throws/initiates an offensive action.

Exact duration remains data-driven.

## Out of Bounds / Recovery

Falling outside valid arena space should not create a punitive shooter-style death sequence.

Use a quick, readable reset to a safe location with appropriate temporary protection. Exact score/streak consequences remain provisional and should discourage intentional abuse without creating excessive downtime.

## Team Identification

Two teams must remain instantly distinguishable against:
- white snow;
- blue ice;
- dark caves;
- warm outposts.

Do not rely on color alone. Use compatible combinations of clothing accents, UI markers, labels/iconography and other accessible cues.

## Friendly Fire

Prototype recommendation: **no scoring friendly fire**.

Teammate snowballs should not create exploitable score effects. Whether they physically collide, puff harmlessly or pass according to networking/game-feel needs remains provisional.

## Player Count

**Target: 4v4 (8 players).**

Do not initially optimize map/gameplay around very large player counts.

Reasons:
- individual throws remain meaningful;
- catches remain readable;
- less VFX/projectile clutter;
- stronger positional play;
- manageable networking scope;
- easier first-map design.

Architecture should avoid needless assumptions that make other team sizes impossible later.

## Secondary Mode

**FFA / Free-for-All** is the preferred second mode after Team Snowdown is proven fun.

FFA is useful for:
- rapid gameplay testing;
- casual play;
- individual skill practice;
- validating projectile/movement systems without team dependencies.

Do not let FFA requirements compromise the first 4v4 implementation.

## Explicitly Out of Scope for First Multiplayer Slice

- Ranked systems.
- Large playlists.
- 10v10+ battles.
- Classes/heroes.
- Character abilities.
- Permanent stat upgrades.
- Complex objective modes.
- Special snowballs.
- Power-ups.
- Battle royale rules.
- Progression-dependent competitive advantages.
- Elaborate tournament infrastructure.

These may be explored only after core 4v4 combat proves fun.

## Data-Driven / Provisional Values

Keep configurable:
- match duration;
- countdown duration;
- score values;
- victim penalties;
- spawn protection;
- overtime timing;
- team size where technically reasonable;
- score limit if later added;
- out-of-bounds consequences.

Do not bury these values in gameplay code.

## Vertical Slice Success Test

The first multiplayer slice should answer:

**Can eight players spend six minutes throwing, dodging, catching, packing and repositioning—and immediately want another match?**

If not, improve the core sport before adding modes or meta systems.
