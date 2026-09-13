# SNOWDOWN — HUD / UI DIRECTION — LOCKED

Status: **LOCKED / AUTHORITATIVE DIRECTION**

Astra should treat this document as the approved HUD philosophy unless explicitly revised.

## Core Principle

**When nothing important is happening, Snowdown should almost look HUD-less. When information matters, it appears where the player needs it, communicates clearly, then gets out of the way.**

The physical world, first-person hands, snowball state, animation, audio and impact VFX should communicate gameplay whenever possible. UI exists for information that cannot be inferred reliably from the scene.

## Persistent Match HUD

### Center
- Small, clean, configurable crosshair.
- No firearm-style reticle language.
- During throw charging, use restrained center feedback such as subtle expansion/contraction or a compact circular charge indicator.
- Do not use a large power meter unless playtesting proves necessary.

### Top Center
- Round/match timer.
- Team/player score appropriate to the active mode.
- Keep highly glanceable and visually compact.

### Snowball / Resource State
- Only show a persistent snowball count/resource indicator if the final mechanics require carrying multiple packed snowballs or managing a resource.
- If the player normally holds/prepares one snowball at a time and hand animation communicates state clearly, omit the counter.
- This specific decision remains **PROVISIONAL pending gameplay implementation/playtesting**.

## Temporary Feedback

Use short-lived center/near-center confirmation for events such as:
- Successful hit.
- Head hit.
- Catch.
- Score gain.
- High-skill snowball-vs-snowball interaction.
- Other important competitive moments.

Temporary UI should reinforce physical/audio/VFX feedback rather than replace it.

## World-Space Information

- Teammate identification should be clear.
- Important objectives/spawn/interaction locations may use restrained world-space markers.
- Avoid permanent enemy nameplates visible through geometry.
- Do not allow markers to overwhelm the environment.

## Interaction Prompts

- Context sensitive.
- Appear only when relevant.
- Prefer placement near the relevant interaction or a restrained lower/center region.
- Input-aware.
- Fade immediately when no longer needed.

Examples may include Pack Snow, Catch, Interact, or mode-specific actions, but wording and controls remain implementation-dependent.

## Scoreboard

- Available on demand and/or during round transitions.
- Do not permanently occupy significant screen space.
- Optimize for rapid comprehension.

## Minimap

**Do not implement a minimap by default for the vertical slice.**

The environment should provide orientation through strong landmarks, glacier formations, caves, outposts, routes and elevation.

Add a minimap later only if playtesting demonstrates a genuine navigation/readability problem that cannot be solved cleanly through level design.

## Visual Language

Because the world already contains extensive white/cyan/blue:
- Avoid making the entire UI icy blue.
- Favor neutral off-white, charcoal/navy and restrained translucent dark surfaces.
- Use a limited warm accent family for important information where appropriate.
- Maintain excellent contrast over both bright exterior snow and dark ice caves.
- Favor clean modern typography and simple geometry.
- Avoid decorative UI that competes with the world.

## Explicitly Avoid

- Military/tactical HUD styling.
- Ammo-magazine graphics unless a mechanic truly requires analogous information.
- Weapon silhouettes.
- Radar sweeps/tactical grids.
- Blood-style damage indicators.
- Generic shooter kill-feed terminology.
- Excessive screen-edge widgets.
- Constant popups.
- Large permanent ability bars unless future mechanics require them.
- UI that makes snowball combat feel like firearms with different graphics.

If an event feed exists, terminology should fit a competitive snowball game: hits, catches, scores, streaks and mode-specific events.

## Team / Competitive Readability

- Team identification must remain readable against white snow, blue ice, dark caves and warm structures.
- Never rely on color alone for critical states.
- Combine color with iconography, silhouette treatment, labels or other accessible cues where appropriate.
- Enemy/teammate readability must be validated through gameplay testing.

## Accessibility / Configuration Architecture

Design the UI system so it can support:
- HUD scale.
- Crosshair customization.
- UI opacity where appropriate.
- Color-blind-safe identification.
- Input-aware prompts.
- Keyboard/mouse and controller glyph switching.
- Readable text scaling.
- Future localization.

The first prototype does not need a complete settings suite, but Astra should avoid architectural choices that make these expensive to add later.

## Implementation Priority

1. Functional crosshair.
2. Match timer/score.
3. Essential hit/catch/score feedback.
4. Interaction prompts.
5. Team/world-space identification.
6. Scoreboard.
7. Accessibility/configuration hooks.
8. Visual polish/animation.
9. Additional HUD elements only when playtests justify them.

Do not spend vertical-slice time polishing menus while core snowball combat remains unproven.

## Final Identity

Snowdown UI is **quiet, modern, competitive and subordinate to the world**.

The player should remember the glacier, the opponent, the snowball flying toward them, the catch and the impact — not the HUD.
