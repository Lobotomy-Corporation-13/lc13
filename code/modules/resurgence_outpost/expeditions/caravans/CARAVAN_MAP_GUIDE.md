# Caravan Encounter Map Creation Guide

This guide explains how to create a caravan encounter map for the Resurgence Outpost expedition system.

## Overview

Caravan encounter maps are special z-levels that load dynamically when players encounter a caravan on the world map. The terrain appearance automatically updates to match the terrain type where the caravan was found.

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

You MUST include these three landmarks for the encounter system to function:

#### Player Spawn Point
```dm
/obj/effect/landmark/caravan_spawn
```
Where players teleport when the encounter starts.

#### Wagon Location
```dm
/obj/effect/landmark/caravan_wagon
```
Where the caravan wagon/cart spawns and guards patrol.

#### Exit Point
```dm
/obj/effect/landmark/caravan_exit
```
Where players can leave to return to the expedition corridor.

## Example Map

Here's a minimal 15x15 caravan encounter map:

```dm
//MAP CONVERTED BY dmm2tgm.py THIS HEADER COMMENT PREVENTS RECONVERSION, DO NOT REMOVE
"a" = (
/turf/closed/wall/caravan_encounter,
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
f
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

1. **Spawn Point Placement**: Place `caravan_spawn` near one edge, giving players room to assess the situation before engaging.

2. **Wagon Placement**: Place `caravan_wagon` in a central or slightly offset position. This is where:
   - The caravan's visual representation appears
   - Guards spawn and patrol
   - Loot drops after defeating guards

3. **Exit Placement**: Place `caravan_exit` in an accessible location, ideally opposite the spawn point or clearly visible.

4. **Cover**: Consider adding obstacles (rocks, trees, etc.) for tactical combat:
   ```dm
   /obj/structure/flora/rock/pile
   /obj/structure/flora/tree/dead
   ```

5. **Open Space**: Leave enough open floor around the wagon for guard spawning and combat movement.

## Adding Decorations

You can add static decorations that fit multiple terrain types:

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
- The exit landmark triggers the `return_to_corridor()` proc

### Guards Don't Spawn
- Ensure `/obj/effect/landmark/caravan_wagon` exists
- Guards spawn at the wagon location when the caravan is hostile

### Terrain Doesn't Update
- Verify all floor turfs are `/turf/open/floor/caravan_encounter`
- Verify all wall turfs are `/turf/closed/wall/caravan_encounter`
- Using other turf types will not respond to terrain changes

## Related Files

- `code/modules/resurgence_outpost/expeditions/caravans/_caravans.dm` - Caravan system defines
- `code/modules/resurgence_outpost/expeditions/caravans/caravan_encounter.dm` - Encounter turfs and controller
- `code/modules/resurgence_outpost/expeditions/caravans/caravan_manager.dm` - Caravan spawning and movement
- `_maps/map_files/Resurgence/travel_outskirts.dmm` - Reference for expedition corridor map format
