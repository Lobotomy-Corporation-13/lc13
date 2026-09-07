# Caravan Encounter Map Creation Guide

This guide explains how to create a caravan encounter map for the Resurgence Outpost expedition system.

## Overview

Caravan encounter maps are special z-levels that load dynamically when players encounter a caravan on the world map. The terrain appearance automatically updates to match the terrain type where the caravan was found.

### Encounter Behavior

Caravan encounters function as "mini-hubs" where players physically explore the area:

**Non-Hostile Caravans** (Resurgence Clan, Jiajia-ren, Santata Factory, Cloud Town):
- Players teleport into the caravan encounter area
- **Passive guards** are present but won't attack unless provoked
- **Trader NPC** is present - click to open the TGUI trading interface
- Walk to the exit landmark to leave when done

**Hostile Caravans** (Insurgence Clan Patrols):
- Players teleport into the caravan encounter area
- **Hostile guards** spawn and attack immediately
- No trader NPC (combat only)
- Defeating all guards drops loot, then players can exit

**Guard Provocation**: If players attack a passive guard, ALL nearby guards become hostile and a reputation penalty is applied with that faction.

## Required File Location

```
_maps/map_files/Resurgence/caravan_encounter.dmm
```

This path is defined in `code/modules/resurgence_outpost/expeditions/caravans/_caravans.dm`:
```dm
#define CARAVAN_ENCOUNTER_MAP "_maps/map_files/Resurgence/caravan_encounter.dmm"
```

## Map Format (DMM)

BYOND maps use the DMM format. The file consists of two sections:

### 1. Tile Definitions

At the top of the file, define tile keys (single letters or short strings) that map to turf/object combinations:

```dm
"a" = (
/turf/closed/wall/caravan_encounter,
/area/resurgence/caravan_encounter)
"f" = (
/turf/open/floor/caravan_encounter,
/area/resurgence/caravan_encounter)
```

### 2. Map Grid

Below the definitions, specify the map layout using coordinates:

```dm
(1,1,1) = {"
a
a
a
"}
(2,1,1) = {"
a
f
a
"}
```

The format is `(x,y,z)` where:
- **x**: Column (west to east)
- **y**: Row (south to north, bottom to top in the grid)
- **z**: Z-level (always 1 for single-level maps)

## Required Elements

### 1. Area

All tiles must be in the caravan encounter area:

```dm
/area/resurgence/caravan_encounter
```

### 2. Floor Turfs

Use the terrain-adaptive floor turf for walkable areas:

```dm
/turf/open/floor/caravan_encounter
```

This turf automatically changes appearance based on terrain type:
- Plains: Grass
- Forest: Dark grass with leaves
- Mountain: Rocky ground
- Desert: Sand
- Ruins: Cracked stone
- Snow: Snow-covered ground

#### Edge Floor Turf (with Decor)

For the edges of the map, use the edge variant that spawns terrain-appropriate decor:

```dm
/turf/open/floor/caravan_encounter/edge
```

This turf has a 60% chance to spawn decor objects when terrain changes:
- **Plains**: Grass, rock piles, bushes
- **Forest**: Dead trees, bushes, rock piles, grass
- **Mountain**: Rocks, rock piles, mushrooms
- **Desert**: Rock piles, rocks, cacti
- **Ruins**: Rock piles, wood debris
- **Snow**: Icy rocks, rock piles, pine trees

When players return to the caravan on a different tile, all old decor is automatically removed and new terrain-appropriate decor spawns.

### 3. Wall Turfs

Use the terrain-adaptive wall turf for boundaries:

```dm
/turf/closed/wall/caravan_encounter
```

This turf also adapts to terrain:
- Plains: Grassy hillside
- Forest: Dense treeline
- Mountain: Cliff face
- Desert: Sand dune
- Ruins: Collapsed wall
- Snow: Frozen cliff

### 4. Required Landmarks

You MUST include these landmarks for the encounter system to function:

#### Player Spawn Point (Required)
```dm
/obj/effect/landmark/caravan_spawn
```
Where players teleport when the encounter starts.

#### Wagon Location (Required, Multiple Allowed)
```dm
/obj/effect/landmark/caravan_wagon
```
Where guards spawn for caravans. **One guard spawns per wagon landmark**, so place multiple wagon landmarks to have multiple guards. Guard behavior and strength varies by faction:

**Passive Guards** (non-hostile factions):
- Resurgence Clan: Weak guards (60 HP, 10-18 damage)
- Jiajia-ren: Medium guards (80 HP, 18-28 damage)
- Santata Factory: Strong guards (100 HP, 20-30 damage)
- Cloud Town: Medium guards (80 HP, 15-25 damage)

**Hostile Guards** (hostile factions):
- Insurgence Clan: Strong raiders (90 HP, 20-35 damage) - attack on sight

The first wagon landmark is also used as fallback trader spawn and loot drop location.

#### Exit Point (Required)
```dm
/obj/effect/landmark/caravan_exit
```
Where players can leave to return to the expedition corridor. When a player walks onto this landmark, a popup appears asking if they want to leave or stay. Players who leave are teleported back to the expedition corridor.

#### Trader Spawn Point (Optional)
```dm
/obj/effect/landmark/caravan_trader
```
Where the caravan trader NPC spawns for non-hostile caravans. If not present, the trader spawns at the wagon location. Place this near (but not on) the wagon for best visual effect.

## Example Map

Here's a minimal 15x15 caravan encounter map:

```dm
//MAP CONVERTED BY dmm2tgm.py THIS HEADER COMMENT PREVENTS RECONVERSION, DO NOT REMOVE
"a" = (
/turf/closed/wall/caravan_encounter,
/area/resurgence/caravan_encounter)
"d" = (
/turf/open/floor/caravan_encounter/edge,
/area/resurgence/caravan_encounter)
"e" = (
/obj/effect/landmark/caravan_exit,
/turf/open/floor/caravan_encounter,
/area/resurgence/caravan_encounter)
"f" = (
/turf/open/floor/caravan_encounter,
/area/resurgence/caravan_encounter)
"s" = (
/obj/effect/landmark/caravan_spawn,
/turf/open/floor/caravan_encounter,
/area/resurgence/caravan_encounter)
"t" = (
/obj/effect/landmark/caravan_trader,
/turf/open/floor/caravan_encounter,
/area/resurgence/caravan_encounter)
"w" = (
/obj/effect/landmark/caravan_wagon,
/turf/open/floor/caravan_encounter,
/area/resurgence/caravan_encounter)

(1,1,1) = {"
a
a
a
a
a
a
a
a
a
a
a
a
a
a
a
"}
(2,1,1) = {"
a
d
d
d
d
d
d
d
d
d
d
d
d
d
a
"}
(3,1,1) = {"
a
f
f
f
f
f
f
f
f
f
f
f
f
f
a
"}
(4,1,1) = {"
a
f
f
f
f
f
f
f
f
f
f
f
f
f
a
"}
(5,1,1) = {"
a
f
f
f
f
f
f
f
f
f
f
f
f
f
a
"}
(6,1,1) = {"
a
f
f
f
f
f
f
f
f
f
f
f
f
f
a
"}
(7,1,1) = {"
a
f
f
f
f
f
f
w
f
f
f
f
f
f
a
"}
(8,1,1) = {"
a
f
f
f
f
f
f
t
f
f
f
f
f
f
a
"}
(9,1,1) = {"
a
f
f
f
f
f
f
f
f
f
f
f
f
f
a
"}
(10,1,1) = {"
a
f
f
f
f
f
f
f
f
f
f
f
f
f
a
"}
(11,1,1) = {"
a
f
f
f
f
f
f
f
f
f
f
f
f
f
a
"}
(12,1,1) = {"
a
f
f
f
f
f
f
f
f
f
f
f
f
f
a
"}
(13,1,1) = {"
a
s
f
f
f
f
f
f
f
f
f
f
f
e
a
"}
(14,1,1) = {"
a
d
d
d
d
d
d
d
d
d
d
d
d
d
a
"}
(15,1,1) = {"
a
a
a
a
a
a
a
a
a
a
a
a
a
a
a
"}
```

## Layout Guidelines

### Recommended Size
- Minimum: 15x15 tiles
- Recommended: 20x20 to 30x30 tiles
- Maximum: 50x50 tiles (larger maps may cause performance issues)

### Layout Tips

1. **Edge Turfs**: Use `/turf/open/floor/caravan_encounter/edge` around the perimeter of your walkable area (not against walls, but 1-2 tiles inward). This creates dynamic visual interest with terrain-appropriate decor.

2. **Spawn Point Placement**: Place `caravan_spawn` near one edge, giving players room to assess the situation before engaging.

3. **Wagon Placement**: Place `caravan_wagon` in a central or slightly offset position. This is where:
   - The caravan's visual representation appears
   - Guards spawn and patrol
   - Loot drops after defeating guards

4. **Exit Placement**: Place `caravan_exit` in an accessible location, ideally opposite the spawn point or clearly visible.

5. **Cover**: Consider adding obstacles (rocks, trees, etc.) for tactical combat:
   ```dm
   /obj/structure/flora/rock/pile
   /obj/structure/flora/tree/dead
   ```

6. **Open Space**: Leave enough open floor around the wagon for guard spawning and combat movement.

## Adding Decorations

**Recommended**: Use `/turf/open/floor/caravan_encounter/edge` turfs instead of static decorations. Edge turfs automatically spawn terrain-appropriate decor that updates when players encounter the caravan on different terrain types.

If you need static decorations that don't change, you can add them manually:

```dm
"r" = (
/obj/structure/flora/rock,
/turf/open/floor/caravan_encounter,
/area/resurgence/caravan_encounter)
"t" = (
/obj/structure/flora/tree/dead,
/turf/open/floor/caravan_encounter,
/area/resurgence/caravan_encounter)
```

Note: Decorations do NOT automatically change with terrain. For a consistent look across all terrains, use neutral objects like rocks or debris.

## Testing Your Map

1. **Compile**: Run the DM compiler to check for syntax errors
   ```
   dm.exe lobotomy-corp13.dme
   ```

2. **In-Game Testing**: Use the debug verb (if available) to trigger caravan encounters:
   ```
   /client/proc/debug_caravan_encounter
   ```

3. **Check Landmarks**: Verify all three required landmarks are found by checking the game logs.

4. **Test All Terrains**: If possible, test encounters on different terrain types to ensure the visual appearance updates correctly.

## Troubleshooting

### "No spawn point found" Error
- Ensure `/obj/effect/landmark/caravan_spawn` is placed on the map
- Verify the landmark is on `/turf/open/floor/caravan_encounter`, not a wall

### Players Can't Leave
- Ensure `/obj/effect/landmark/caravan_exit` exists
- The exit landmark shows a popup when players walk onto it
- Players must click "Continue Expedition" in the popup to leave

### Guards Don't Spawn
- Ensure at least one `/obj/effect/landmark/caravan_wagon` exists
- One guard spawns per wagon landmark for all caravans
- Hostile caravans (Insurgence) spawn aggressive guards
- Non-hostile caravans spawn passive guards that only attack if provoked
- Add more wagon landmarks to increase the number of guards

### Terrain Doesn't Update
- Verify all floor turfs are `/turf/open/floor/caravan_encounter`
- Verify all wall turfs are `/turf/closed/wall/caravan_encounter`
- Using other turf types will not respond to terrain changes

## Related Files

- `code/modules/resurgence_outpost/expeditions/caravans/_caravans.dm` - Caravan system defines
- `code/modules/resurgence_outpost/expeditions/caravans/caravan_encounter.dm` - Encounter turfs, landmarks, and controller
- `code/modules/resurgence_outpost/expeditions/caravans/caravan_trader_npc.dm` - Caravan trader NPC with TGUI interface
- `code/modules/resurgence_outpost/expeditions/caravans/caravan_manager.dm` - Caravan spawning and movement
- `_maps/map_files/Resurgence/travel_outskirts.dmm` - Reference for expedition corridor map format
