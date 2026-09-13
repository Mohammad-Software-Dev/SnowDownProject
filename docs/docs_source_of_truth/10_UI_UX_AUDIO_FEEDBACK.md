# Snowdown — UI, UX, Audio & Feedback

## HUD goals
Communicate only what supports decision-making. The player should primarily watch the world, not gauges.

## In-match HUD
**PROVISIONAL minimum:**
- centered aiming reticle;
- packed snowball count;
- current score;
- round timer;
- compact current placement;
- charge indicator while charging;
- contextual pack/catch prompts where useful;
- hit confirmation showing body/head and score gained;
- directional awareness feedback should come mainly from world audio/visuals rather than radar.

No health bar.

## Reticle
Reticle should not promise hitscan precision. It indicates launch direction, not exact future impact. Optional charge-dependent arc preview is **TBD**; if used, it should be short-range/approximate enough to preserve skill.

## Hit feedback
Attacker receives immediate local confirmation predicted for responsiveness, reconciled with server result. Server-confirmed feedback differentiates body vs head hit.

Victim feedback:
- snow overlay/splat;
- directional impact cue;
- short audio thump/plop;
- mild reaction animation;
- no blood/red damage vignette.

## Audio language
Important sounds must be distinct:
- pack snow;
- charge/wind-up cloth movement;
- throw release;
- projectile near-miss whoosh;
- body splat;
- head splat;
- catch;
- snowbank/world impact;
- footsteps on snow/wood/ice;
- round countdown/end.

## Announcer/text style
Preferred: “Head splat!”, “Nice catch!”, “On a roll!”, “Long toss!”, “Snowdown!”  
Avoid: “kill”, “enemy eliminated”, “fatal”, “damage dealt”.

## Menus
Core flow: Home → Party → Play/Mode → Matchmaking → Match → Results → Continue. Joining a friend should require few steps.

## Accessibility
**LOCKED product requirement; exact features PROVISIONAL:**
- remappable controls;
- mouse/controller sensitivity;
- FOV option within safe range;
- subtitle/caption support for announcer;
- color-independent head/body hit confirmation;
- screen-shake slider including 0;
- snow-splat opacity option;
- motion blur toggle;
- aim reticle customization basics;
- audio mix controls.

Do not make critical gameplay information depend on color alone.
