# Snowdown — Scoring & Match Rules

## Default public mode
**LOCKED:** The first canonical mode is timed Free-for-All.

**PROVISIONAL defaults:**
- player target: 8 (scale testing 4–12);
- round duration: 5:00;
- highest valid score at 0:00 wins;
- scores never fall below 0.

## Base scoring
| Event | Score |
|---|---:|
| Body hit | +10 attacker |
| Head hit | +25 attacker |
| Victim hit penalty | -3 victim |
| Successful catch | +3 catcher (PROVISIONAL) |

Catch score exists to reward skilled defense without outvaluing attack.

## Bonus scoring
Bonuses should be additive and capped so the main value still comes from landing hits.

**PROVISIONAL:**
- long-range hit ≥25 m: +5;
- very long-range hit ≥40 m: +10 instead of +5;
- airborne attacker bonus: +3;
- airborne target bonus: +3;
- bank/trick-shot bonus: **TBD**, only if detection is reliable;
- streak bonus: not active in prototype scoring; streak is initially feedback/prestige only.

Do not stack mutually exclusive distance bonuses.

## Streak
**PROVISIONAL:** A streak counts consecutive scoring hits without being hit. Missing does not end it; being hit ends it. This avoids encouraging only conservative accuracy. Streak thresholds may trigger announcements/cosmetic feedback at 3, 5, and 8 hits. No multiplicative score bonus in the first version.

## Tie breaking
At round end, rank by:
1. score;
2. head hits;
3. total successful hits;
4. fewer times hit;
5. if still tied, shared placement.

Do not extend casual rounds into sudden-death unless a specific mode requires it.

## Join-in-progress
**PROVISIONAL:** Casual players may join while ≥90 seconds remain. Late joiners can earn rewards but are marked “Joined Late.” They are eligible for podium only if they participated for at least 60% of the round. Exact threshold is tunable.

## AFK
**PROVISIONAL:** After 45 s without meaningful input, mark AFK; after 90 s, remove from public instance to free the slot. Private hosts may disable auto-removal.

## Hit reaction and score safety
A victim cannot be scored against multiple times by the same single projectile. Brief hit reaction does not grant invulnerability by default. Spawn protection is defined in movement rules.

## Match end
At 0:00:
- disable new scoring immediately;
- allow already-flying projectiles to become cosmetic only, or destroy them;
- freeze placement snapshot;
- transition to results/podium;
- reset transient world state before next round.

**LOCKED:** Final scoring must be server authoritative.
