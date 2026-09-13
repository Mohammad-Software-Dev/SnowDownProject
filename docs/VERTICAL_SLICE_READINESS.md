# Snowdown Vertical Slice Readiness

Status: **M14 automated hardening green; manual/art-dependent gates remain**

This file records what is actually proven for the Glacier Valley 4v4 vertical slice. It is intentionally conservative: a headless CI pass proves deterministic logic and network behavior, but it does not prove subjective game feel, rendered visual quality, frame pacing on target hardware, or first-time-player comprehension.

## Automated gates currently green

The main verification command is:

```bash
tools/scripts/run_headless_tests.sh
```

The GitHub `Godot verify` workflow uses Godot 4.7.2 stable and currently proves:

- project parse/import and headless boot;
- typed gameplay/map configuration loads;
- keyboard/mouse and locked controller action mappings exist;
- controller right-stick shaping and tunable look speed/deadzone;
- reversible gameplay-input suppression for the local pause menu;
- deterministic projectile trajectory math;
- deterministic catch geometry/approach validation;
- first-person and third-person presentation-state coverage;
- shared winter-character palette/readability invariants;
- Glacier Valley footprint, required scenario anchors, spawn symmetry and snow-access invariants;
- Glacier Valley visual-pass placement invariants that keep backdrop/presentation geometry out of competitive collision;
- dedicated-server startup and client connection;
- server-owned inventory/throw/projectile/hit/catch paths;
- bounded catch rewind under the maintained latency/jitter/loss matrix through 200 ms latency and 5% packet loss;
- match waiting → countdown → Active → Sudden Snow → results → clean round-2 reset;
- scoring rejection outside active phases;
- score immutability after Results begins, protecting against late match-end scoring events;
- deterministic projectile cleanup on match phase transitions through the match coordinator;
- live owner disconnect after one authoritative throw, server survival/peer cleanup and successful replacement-client rejoin;
- real eight-client 4v4 scale smoke;
- network telemetry collection used by the controlled playtest harness.

## User-facing hardening now present

- normal launch opens Host / Join / Offline Practice instead of requiring debug arguments;
- Host launches a local headless authoritative server and connects the host client;
- Join accepts direct `host:port` endpoints;
- connection failure/server disconnect surfaces a recovery panel with retry/restart and Return to Menu;
- pause/settings works from Esc or controller Menu/Start;
- network pause is local-only and does not stop authoritative simulation;
- offline practice is actually paused while its menu is open;
- gameplay actions are suppressed while the pause menu is open and restored exactly on resume;
- live settings include mouse look, controller look, 3D render scale and VSync;
- README now describes the current friends-playtest flow and verification path.

## Manual gates still required before calling the slice externally evaluation-ready

These cannot be honestly closed by the current headless environment:

1. **Graphical smoke on the target desktop build** — launch menu, Host, Join, Offline Practice, pause/settings, recovery screen, results and round restart must all be visually inspected.
2. **Real keyboard/mouse feel pass** — movement, slide, pack, charge/throw and catch timing must be judged at normal frame rate with real input hardware.
3. **Real controller feel pass** — right-stick sensitivity/deadzone, triggers, face buttons, scoreboard and pause navigation must be played on at least one supported controller.
4. **Visibility/art pass** — Glacier Arch dominance, river readability, deep-cyan cave readability, warm outpost contrast, snow-source readability and remote-player silhouettes must be checked in rendered gameplay, not inferred from procedural placement tests.
5. **Performance pass** — test at 100%, 80% and 60% 3D render scale, with VSync on/off where appropriate, and record representative frame-time behavior on at least one target-class GPU/CPU.
6. **Real 4v4 human playtest** — the eight-client harness proves scale/stability, not congestion, engagement quality, side advantage, snow-source decision quality or subjective fun.
7. **Direct-connect network reality check** — test at least one LAN friend join and, if internet play is intended for the evaluation, one real routed/firewall/NAT setup.
8. **First-time-player comprehension** — a tester who has not read the design docs should be able to host/join, find snow, pack, throw, catch, read score/time and understand Results without debug UI.
9. **Final production character decision** — the current FP/TP winter humans are procedural replaceable placeholders; M13's final realistic production human/clothing mesh remains outstanding.
10. **Rights manifest check before external asset import** — M12/M13 additions in this implementation pass are authored procedural/code-based presentation rather than imported third-party production art. Any later external production asset must be recorded in the locked ownership/license manifest before shipping it.

Audio remains explicitly deferred under the current slice direction; if external testers consistently fail to understand actions without it, add temporary feedback rather than silently changing the locked scope.

## Current readiness interpretation

The slice is **automation-ready for a controlled graphical playtest**, not yet certified as a polished external-evaluation build.

The next evidence should come from an actual graphical friends session, not another speculative gameplay-system expansion. Findings from that session should prioritize, in order:

1. critical crashes/session failures;
2. authority/desync/exploit problems;
3. control/readability/comprehension failures;
4. map visibility/congestion issues;
5. performance/frame-pacing issues;
6. movement/throw/catch tuning;
7. visual polish and production-asset replacement.

Do not compensate for a bad Glacier Valley sightline or route with fundamental snowball-physics changes before verifying the geometry problem first.
