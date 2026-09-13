# Snowdown — Map & Level Design

## Philosophy
Maps are winter playgrounds, not military arenas. They should create readable projectile lanes, cover, flank routes, vertical look-up moments, snow sources, and movement opportunities.

## Core ingredients
Use a mix of:
- waist/head-height snowbanks;
- cabins and corners;
- balconies/rooftops with counter-lines;
- trees and natural occluders;
- open plazas/ponds for risky long throws;
- slopes for sliding;
- indoor passages as temporary safety with limited/no snow packing;
- multiple valid snow sources.

## Prototype map: Alpine Village
**PROVISIONAL target footprint:** compact arena supporting 4–8 players first, then scale test to 12.

Landmarks:
- central village square;
- frozen pond/open long-range lane;
- clock tower landmark;
- 3–5 wooden cabins;
- reachable low rooftops;
- snowbank maze/cover cluster;
- playground or sled area;
- downhill slide route;
- narrow alley network;
- perimeter trees/rocks.

## Sightline rules
- Avoid one dominant position that can see most spawns and snow sources.
- Long sightlines should expose the thrower to flanks.
- Every elevated position needs at least two counters: alternate angle, approach route, or exposed silhouette.
- A player should rarely travel more than several seconds without access to cover.

## Snow source placement
Snow must be available often enough that inventory management creates rhythm, not frustration.

**PROVISIONAL:** from most combat zones, a valid packing surface should be reachable within ~4 seconds of normal movement. Indoor spaces may intentionally lack packable snow.

## Spawns
Because normal gameplay has no death respawn, spawns are used for round start and join-in-progress.

Spawn points must:
- avoid direct line-of-sight to active opponents where possible;
- have multiple exits;
- not place the player in deep traversal traps;
- provide nearby snow access;
- use server-side safety scoring when selecting among candidates.

## Boundaries
Prefer natural barriers, deep snow, fences, cliffs with safe invisible blockers, and architecture. Avoid obvious arbitrary invisible walls inside expected traversal space.

## Verticality
Vertical play is encouraged, but head visibility must remain readable. Do not create rooftop geometry where only a few pixels of a head collider are exposed while the thrower can attack freely.

## Metrics to collect
- heatmap of throws/hits;
- deaths are not applicable; collect “times hit” heatmap instead;
- average distance to snow source;
- time spent per region;
- dominant head-hit lanes;
- catch frequency by area;
- player congestion;
- out-of-bounds attempts.
