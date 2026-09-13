# SNOWDOWN — REALISM ART DIRECTION — LOCKED

Status: LOCKED for the current realism pass.

## Core visual target

Snowdown should read as **grounded winter realism inside a cinematic glacial world**.

The game is not aiming for cartoon rendering, toy-like materials, flat-color blockout presentation, or exaggerated fantasy armor. The environment may use large, memorable glacial silhouettes and cinematic composition, but every surface, light source, character material, and prop should feel materially believable.

The intended blend is:

- realistic snow, ice, rock, fabric, wood, and metal response;
- physically restrained winter lighting and atmospheric perspective;
- large readable glacier formations and landmarks;
- modern human winter clothing and gear;
- minimal competitive HUD;
- original world design that does not copy recognizable copyrighted environments, characters, props, compositions, or branding.

## Reference use

Reference modern snow-world games for lessons in material response, terrain layering, contact with snow, winter atmosphere, visibility, and believable structures. Reference cinematic glacial animation for scale, silhouette readability, cave drama, and memorable frozen landmarks.

References are directional only. Do not recreate a recognizable Ice Age formation, film shot, game location, prop design, character costume, logo, or composition. Snowdown must remain original. No external reference can override Snowdown's locked gameplay readability, human-scale competitive spaces, or original Glacier Valley identity.

## Realism hierarchy

When visual choices conflict, prioritize in this order:

1. Competitive readability.
2. Material believability.
3. Natural silhouette and scale.
4. Lighting realism.
5. Atmospheric depth.
6. Surface microdetail.
7. Decorative detail.

Realism must never hide players, snow sources, route entrances, projectiles, or scoring feedback.

## Material rules

### Snow

Snow is not pure white. It should contain subtle blue-gray shadow variation, soft macro breakup, fine normal detail, high roughness, and localized compression/readability differences. Fresh powder should appear softer and brighter than packed route snow.

Use snow buildup to explain the world: drifts collect against cover, roofs, walls, rocks, and outpost structures. Avoid uniform snow blankets with perfectly clean edges.

### Ice

Ice should not read as flat cyan plastic. It needs depth variation, darker blue-green mass, pale trapped-air/frost areas, micro-normal breakup, clearcoat/specular response, and occasional reflective streaks/cracks. The frozen river should feel smoother and wetter than glacial walls.

### Rock

Rock should be darker, rough, stratified, and visually support snow accumulation. Large rock surfaces need macro variation and small-scale normal detail so they do not read as solid-color boxes.

### Wood and metal

Outpost materials should feel weathered and cold. Wood remains matte and fibrous; metal should have restrained metallic response, dark oxidation, and localized specular highlights. Team color is an accent, not the entire structure.

### Clothing and gloves

Winter clothing should read as insulated fabric, not colored plastic. Sleeves, jackets, gloves, boots, scarves, and headwear should use restrained roughness and material breakup. Team identity is carried by controlled panels/cuffs/markings rather than full-body saturation.

## Lighting rules

Use a believable cold daylight setup:

- one dominant directional sun;
- cold sky fill;
- strong but readable contact shadows;
- subtle indirect light;
- warm practical lights only at human-built outposts;
- deeper cyan/blue bounce inside ice caves;
- restrained exposure with ACES tonemapping;
- no neon glow except subtle practical-light bloom.

Snow should stay bright without clipping to featureless white. Ice should retain darker depth. Rock should anchor contrast.

## Atmosphere rules

Atmosphere should communicate cold air and scale without obscuring gameplay:

- distance fog/haze;
- subtle low-altitude density variation;
- sparse wind-driven snow particles;
- stronger aerial perspective on distant glacier silhouettes;
- no constant heavy blizzard unless explicitly used as a later gameplay/weather event.

## Geometry and silhouette rules

Competitive collision may remain simple and stable, but the visible shell should hide obvious blockout forms.

Use visual-only geometry to add:

- irregular glacier faces;
- snow cornices and drifts;
- rock shelves and talus-like breakup;
- broken ice slabs;
- icicles and cave frost;
- outpost beams, braces, roofs, crates, poles, lanterns, and snow caps;
- natural transitions around route edges.

Do not alter gameplay cover dimensions or route widths merely for visual interest without a gameplay review.

## Glacier Valley identity

### Center / Glacier Arch

The Arch is the hero landmark. It should feel massive, naturally fractured, partially translucent/icy in material response, and readable from both spawns. Preserve the gameplay opening beneath it.

### Frozen River

The river is the fast exposed lane. It should be visually smoother, darker, more reflective, and more fracture-rich than surrounding snow. Use trapped-air streaks and frost near the edges.

### Ice Cave

The cave should feel colder, denser, and more enclosed. Use rough rock/ice mass, cyan bounce, hanging frost/icicles, and darker depth. Avoid decorative crystal-fantasy styling.

### High Shelf

The shelf should feel wind-scoured and exposed. Use thinner snow, darker rock, sharper shadowing, and fewer soft drifts.

### Team Outposts

Outposts should feel temporary, practical, and human: timber/metal construction, warm lanterns, snow accumulation, crates, bracing, and restrained team accents.

## First-person presentation

First-person arms are a hero asset. Until final production assets are available, the procedural rig must still aim for believable proportions and materials:

- tapered insulated sleeves;
- visible cuffs/seams/panels;
- recognizable palms, knuckles, thumbs, and fingers;
- matte textile and rubber/leather-like glove response;
- irregular packed snowball surface;
- restrained camera bob/sway driven by gameplay state.

Do not use weapon-like oversized viewmodel proportions.

## Third-person presentation

The procedural mannequin remains a placeholder, but must preserve realistic human proportions, winter clothing language, team readability, and independent competitive hitboxes. Final production mesh replacement must not require gameplay or network architecture changes.

## Performance target

Visual realism is allowed to use Forward+ desktop features, but the vertical slice must remain scalable. Expensive effects should have graceful fallbacks through render scale/settings. Prefer localized screen-space effects, material detail, and visual-only shells over architecture that couples simulation to rendering.

## Forbidden shortcuts

Do not:

- copy recognizable film/game environments or shots;
- ship reference images as textures;
- use unlicensed marketplace assets;
- make ice neon blue plastic;
- make snow pure white with no detail;
- solve realism only with bloom/fog;
- alter authoritative collision to match decorative shell details;
- hide gameplay readability behind cinematic effects;
- present procedural placeholders as final production art.

## Current implementation objective

The current realism pass should improve, in order:

1. PBR surface breakup for snow, ice, rock, wood, fabric, gloves, and packed snowballs.
2. Forward+ contact lighting: SSAO, SSIL, restrained SSR, fog, ACES exposure.
3. Wind-driven snow atmosphere.
4. Glacier Valley visual-shell breakup and accumulation cues.
5. Outpost structural detail and snow caps.
6. First-person material realism.
7. Third-person placeholder material realism.

Final photorealistic human/environment asset replacement remains a later production-art task and must stay decoupled from gameplay logic.