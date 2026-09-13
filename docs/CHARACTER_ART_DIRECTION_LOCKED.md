# Snowdown — Character Art Direction (LOCKED)

Status: LOCKED by user.

## Core direction
Snowdown players are believable, realistic human beings in functional modern winter clothing. Do not use cartoon anatomy, oversized heads/hands/boots, chibi proportions, hero-shooter anatomy, fantasy species, or exaggerated body proportions.

Target visual balance:
- Human anatomy/proportions: realistic.
- Faces: realistic and diverse, but optimized for robust real-time rendering rather than uncanny hyper-photorealism.
- Clothing/materials: realistic modern winter/snow-sports garments and physically believable layering.
- Animation: grounded human locomotion and throwing mechanics; playful exaggeration is allowed primarily in snow impacts/reactions, not anatomy.
- Gameplay/VFX: may be more expressive than the characters themselves.

## Character identity
Characters should look like ordinary/athletic young-to-middle-aged adults who plausibly participate in an intense recreational snowball fight in an extraordinary frozen world. They are not soldiers, superheroes, survival-horror characters, or professional snowboard avatars.

Use clothing and accessories for personality rather than distorted anatomy:
- technical winter jackets / puffers / shells;
- snow pants;
- insulated boots;
- realistic gloves or mittens;
- beanies, hoods, scarves, goggles, earmuffs;
- restrained backpacks/accessories only where they do not harm competitive silhouette/readability.

## Color/readability
Realism must not sacrifice multiplayer readability. Use believable but distinct jacket/pant/accessory color blocking so players remain readable against white/blue snow and ice. Avoid white-on-white camouflage and military camouflage as the default visual language.

## First-person priority
Hands/arms are a hero asset because the core verbs are pack, hold, charge, throw, and catch.
First-person gloves and sleeves must have:
- realistic scale and anatomy;
- high-quality fabric/material response;
- believable finger/wrist motion;
- tactile snow contact/compression;
- readable silhouettes throughout throw/catch animations.

Build first-person arms separately where necessary to preserve camera/FOV quality, while maintaining visual consistency with the third-person character.

## Third-person priority
Other players must read immediately at gameplay distance. Preserve natural human proportions while using clothing silhouette, color blocking, animation poses, and accessories to improve recognition.

## Tone
The realism should make the playful snow combat feel more tactile and surprising. Snow impacts, powder, stumbles, snow sticking to clothing, shaking snow off, scarves reacting, etc. may be expressive and humorous while remaining physically grounded.

## Reference lessons
Use realistic AAA winter-character work to study anatomy, cloth layering, snow accumulation, skin/hair/eyes, and real-time materials. The Last of Us Part I winter costume work is a useful production-quality reference for believable winter clothing and procedural snow, but Snowdown must NOT copy its characters, gritty survival tone, grime, violence, or muted post-apocalyptic palette.

Use real winter-sports/outdoor photography for garment construction, fit, layering, gloves, goggles, boots, and color combinations. References define principles, not assets to copy or redistribute.

## Explicitly avoid
- cartoon/chibi anatomy;
- oversized hands/heads/feet as a style;
- Pixar-like character proportions;
- Fortnite/Overwatch-like hero proportions;
- anime facial styling;
- tactical/military character identity;
- survival-horror grime/gore;
- mandatory skis/snowboards;
- fantasy armor;
- photorealism that cannot be supported consistently by animation, hair, eyes, faces and performance budgets.

## Relationship to environment
LOCKED contrast:
- Characters: grounded realistic humans.
- Clothing: believable modern winter gear with strong readable color.
- Environment: extraordinary stylized/fantastical frozen wilderness as defined in ENVIRONMENT_ART_DIRECTION_LOCKED.md.
- Snow/VFX: tactile, readable and somewhat more exaggerated/playful than the human rendering.

This contrast is intentional and is part of Snowdown's identity.

## Prototype scope
Do not build a large character creator for the vertical slice. Start with a small number of representative, production-minded character setups sufficient to test scale, first-person hands, third-person readability, animation, snow interaction, and networking. Keep customization architecture modular for later expansion.
