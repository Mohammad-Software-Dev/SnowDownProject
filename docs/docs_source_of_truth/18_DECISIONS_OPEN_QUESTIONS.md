# Snowdown — Decisions & Open Questions

## Decision log
### D-001 — Game name
**LOCKED:** Snowdown.

### D-002 — Core genre
**LOCKED:** First-person 3D competitive multiplayer snowball game.

### D-003 — Lethality
**LOCKED:** No normal health/death/kill loop. Hits cause score and short reaction consequences.

### D-004 — Public world model
**LOCKED:** Capped server instances with round-based public matches, not one infinitely growing world.

### D-005 — Friends
**LOCKED:** Parties and join-friend are first-class. Party continuity should preserve friends between rounds.

### D-006 — Progression fairness
**LOCKED:** Persistent progression does not grant permanent raw combat-stat advantages.

### D-007 — Projectile model
**LOCKED:** Snowballs are physical projectiles with travel time and arc; not hitscan.

### D-008 — Hit value
**LOCKED direction:** Head hits are worth meaningfully more than body hits. Current numeric values (+25/+10) are PROVISIONAL.

### D-009 — Source of truth
**LOCKED:** This Drive folder is the canonical design/build reference. AI agents should not invent conflicting mechanics.

## High-priority open questions
1. Engine choice: Unity, Unreal, Godot, other?
2. Target platforms: Windows first? consoles? macOS? mobile excluded?
3. Exact server tick rate and network stack.
4. Final movement values after playtest.
5. Final projectile gravity/drag/velocity curve.
6. Catch window/angle and whether catches score points.
7. Whether a hit drops a packed snowball; currently not locked.
8. Whether player-vs-player bodies collide or softly overlap/separate.
9. Whether charge can be held indefinitely; prototype default may auto-release/cancel after 3 s.
10. Exact late-join podium eligibility.
11. Ranked mode requirements and party restrictions.
12. Monetization/business model.
13. Account system/backend provider.
14. Voice/text chat scope and moderation.
15. Accessibility target set for launch.
16. Exact platform/content rating targets.
17. Whether approximate throw arc assistance exists.
18. How much snow deformation ships in V1.
19. Whether sidegrade throw styles ship in public competitive queues.
20. Max public FFA/team player counts after map/network tests.

## Rejected/avoided directions
- permanent throw-range upgrades;
- permanent firing/packing-rate upgrades;
- permanent movement-speed upgrades;
- lethal weapons or hard “ice ball” damage escalation;
- unlimited public-world population;
- long death/respawn downtime as a core loop.

## Change protocol
New decisions should receive the next `D-###` identifier with date, status, reasoning, and affected files. If a locked decision is reversed, record both the old and new decision rather than deleting history.
