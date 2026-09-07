# Faction Hub Map Creation Guide

This guide explains how to create map files (.dmm) for faction trading hubs.

## Overview

Each faction hub is a small, self-contained area where players can trade with faction NPCs. When an expedition arrives at a faction's world map location, players are teleported to that faction's hub area.

## Recommended Dimensions

| Hub Size | Dimensions | Use Case |
|----------|------------|----------|
| Small | 10×10 | Simple trading posts |
| Medium | 15×15 | Standard faction hubs (recommended) |
| Large | 20×20 | Major settlements with multiple areas |

**Recommended: 15×15 tiles** - Enough space for atmosphere without being too large.

## Required Elements

Every faction hub map MUST contain these landmarks:

### 1. Spawn Point (Required)
```
/obj/effect/landmark/faction_hub_spawn/[faction_id]
```
- Place at the hub entrance
- Players teleport here when arriving
- One per map

### 2. Exit Point (Required)
```
/obj/effect/landmark/faction_hub_exit/[faction_id]
```
- Place near the entrance/exit area
- Opens departure menu when stepped on
- One per map (can have multiple if needed)

### 3. Trader Spawn (Required)
```
/obj/effect/landmark/faction_trader_spawn/[faction_id]
```
- Place where the trader NPC should stand
- Spawns the appropriate faction trader on Initialize
- One per map

### 4. Area Definition (Required)
The entire map should use the appropriate faction area:
```
/area/resurgence/faction_hub/[faction_id]
```
You can use sub-areas for different rooms:
- `/area/resurgence/faction_hub/[faction_id]/entrance`
- `/area/resurgence/faction_hub/[faction_id]/market`
- etc.

## Available Landmarks by Faction

### Resurgence Clan Village
```dm
/obj/effect/landmark/faction_hub_spawn/resurgence_clan
/obj/effect/landmark/faction_hub_exit/resurgence_clan
/obj/effect/landmark/faction_trader_spawn/resurgence_clan
/area/resurgence/faction_hub/resurgence_clan
```

### Jiajia-ren Village
```dm
/obj/effect/landmark/faction_hub_spawn/jiajia_ren
/obj/effect/landmark/faction_hub_exit/jiajia_ren
/obj/effect/landmark/faction_trader_spawn/jiajia_ren
/area/resurgence/faction_hub/jiajia_ren
```

### Santata's Gift Factory
```dm
/obj/effect/landmark/faction_hub_spawn/santata_factory
/obj/effect/landmark/faction_hub_exit/santata_factory
/obj/effect/landmark/faction_trader_spawn/santata_factory
/area/resurgence/faction_hub/santata_factory
```

### Cloud Town
```dm
/obj/effect/landmark/faction_hub_spawn/cloud_town
/obj/effect/landmark/faction_hub_exit/cloud_town
/obj/effect/landmark/faction_trader_spawn/cloud_town
/area/resurgence/faction_hub/cloud_town
```

### Insurgence Clan (Hostile)
```dm
/obj/effect/landmark/faction_hub_spawn/insurgence_clan
/obj/effect/landmark/faction_hub_exit/insurgence_clan
// No trader spawn - this is a hostile zone!
/area/resurgence/faction_hub/insurgence_clan
```

## Map Layout Guidelines

### Basic Layout Template (15×15)
```
WWWWWWWWWWWWWWW
W.............W
W.............W
W....TTT......W    T = Trader area
W....TTT......W
W.............W
W.............W
W.............W
W.............W
W......D......W    D = Decorations
W.............W
W.............W
W..E.....S....W    E = Exit, S = Spawn
W.............W
WWWWWWWWWWWWWWW
```

### Entrance Design
- Spawn point should be near the entrance
- Exit point near (but not on) spawn point
- Clear path from spawn to trader

### Trading Area
- Trader should be easily visible
- Provide space around trader for multiple players
- Consider adding decorative elements:
  - Market stalls
  - Goods displays
  - Faction-themed props

### Theme Guidelines by Faction

#### Resurgence Clan Village
- **Theme**: Rustic, ancestral, natural
- **Turfs**: Grass, dirt, wooden floors
- **Objects**: Tents, campfires, woven baskets, vines
- **Colors**: Greens, browns, earth tones
- **Lighting**: Warm, natural light

#### Jiajia-ren Village
- **Theme**: Bird-folk nest, colorful, elevated
- **Turfs**: Wood platforms, nest materials
- **Objects**: Feathers, shiny objects, perches, colorful fabrics
- **Colors**: Bright colors, golds, purples
- **Lighting**: Dappled sunlight through canopy

#### Santata's Gift Factory
- **Theme**: Industrial nightmare, assembly lines
- **Turfs**: Metal floors, grating
- **Objects**: Conveyor belts, machinery, steam vents, coal piles
- **Colors**: Reds, grays, industrial orange
- **Lighting**: Harsh industrial lighting, occasional red warning lights
- **Note**: Add ominous background elements but keep trading area accessible

#### Cloud Town
- **Theme**: Human settlement, farms, practical
- **Turfs**: Cobblestone, wooden floors, dirt paths
- **Objects**: Market stalls, farm equipment, barrels, crates
- **Colors**: Blues, tans, natural wood
- **Lighting**: Daylight, lanterns

#### Insurgence Clan (Special)
- **Theme**: Military camp, hostile territory
- **Turfs**: Dirt, rubble, fortifications
- **Objects**: Barricades, weapons racks, surveillance equipment
- **Colors**: Dark reds, grays, black
- **Lighting**: Dim, threatening
- **Note**: This is a COMBAT ZONE - include cover objects and enemies!

## Wall and Border Options

Use these turf types for map borders:

```dm
// Solid walls
/turf/closed/wall/mineral/wood        // Wooden walls
/turf/closed/wall/mineral/sandstone   // Stone walls
/turf/closed/wall/mineral/iron        // Metal walls

// Natural borders
/turf/closed/wall/rock                // Rock walls
/turf/closed/mineral                  // Natural cave walls

// Invisible barriers (for open-air maps)
/turf/closed/indestructible/invisible // Invisible walls
```

## Floor Options

```dm
// Natural floors
/turf/open/floor/grass               // Grassy areas
/turf/open/floor/dirt                // Dirt paths
/turf/open/misc/asteroid/basalt      // Rocky ground

// Constructed floors
/turf/open/floor/wood                // Wooden floors
/turf/open/floor/stone               // Stone floors
/turf/open/floor/iron                // Metal floors
/turf/open/floor/carpet              // Carpeted areas
```

## Example Map Checklist

Before finalizing your map, verify:

- [ ] Map uses correct faction area type
- [ ] Spawn point landmark placed at entrance
- [ ] Exit point landmark placed near entrance
- [ ] Trader spawn landmark placed in trading area
- [ ] Clear path from spawn to trader
- [ ] Map is enclosed (walls/borders on all sides)
- [ ] Theme matches faction identity
- [ ] Appropriate lighting for atmosphere
- [ ] No z-level transitions (single floor only)

## File Naming Convention

Save maps in: `_maps/templates/resurgence/faction_hubs/`

Naming pattern: `hub_[faction_id].dmm`

Examples:
- `hub_resurgence_clan.dmm`
- `hub_jiajia_ren.dmm`
- `hub_santata_factory.dmm`
- `hub_cloud_town.dmm`
- `hub_insurgence_clan.dmm`

## Loading the Map

Hub maps should be loaded on their own z-level. Add to map configuration:

```dm
// In the appropriate map config file
"map_path": "_maps/templates/resurgence/faction_hubs/hub_[faction_id].dmm"
```

Or load dynamically using the map loader subsystem.

## Testing Your Map

1. Load the map on a test server
2. Verify landmarks are detected (check server logs)
3. Test teleporting a player to the spawn point
4. Verify trader NPC spawns and is interactable
5. Test the exit point departure menu
6. Check for any pathing issues or blocked areas

## Additional Features (Optional)

### Decoration Objects
Add atmosphere with:
- Flora (trees, bushes, flowers)
- Furniture (tables, chairs, shelves)
- Light sources (lanterns, torches, lights)
- Faction-specific props

### NPCs (Future)
Space for additional NPCs:
- Quest givers
- Information NPCs
- Guards (for hostile factions)

### Special Areas (Future)
- Rest areas (healing)
- Storage (item storage during expeditions)
- Special vendors (hub-exclusive items)

---

## Quick Reference

| Element | Object Path | Required |
|---------|-------------|----------|
| Spawn Point | `/obj/effect/landmark/faction_hub_spawn/[faction]` | Yes |
| Exit Point | `/obj/effect/landmark/faction_hub_exit/[faction]` | Yes |
| Trader | `/obj/effect/landmark/faction_trader_spawn/[faction]` | Yes |
| Area | `/area/resurgence/faction_hub/[faction]` | Yes |

For questions or issues, check the faction hub code in:
`code/modules/resurgence_outpost/expeditions/faction_hubs/`
