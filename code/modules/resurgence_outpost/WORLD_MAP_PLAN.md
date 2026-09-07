# World Map & Expedition System Implementation Plan

## Overview
A Rimworld-style square grid world map with procedural generation, faction locations, travel corridors, skill-check events, and physical faction hub areas.

## User Requirements Summary
- **Square grid world map** - Randomly generated with terrain zones
- **Factions on map** - All 5 trading factions placed strategically
- **Path planning** - Click-to-set waypoints, route visualization
- **Walking corridor travel** - Physical procedural corridors players walk through
- **Travel events** - Skill-check encounters during travel (pass/fail outcomes)
- **Group travel** - Multiple players travel together, outpost continues for others
- **Faction hubs** - Physical areas with NPCs for enhanced trading

---

## Implementation Progress

### Phase 1: World Map Core
- [x] Create `_world_map.dm` with terrain defines
- [x] Implement `/datum/world_tile`
- [x] Implement `/datum/world_map_manager` with generation
- [x] Create map viewing console (`map_console.dm`)
- [x] Create `ResurgenceWorldMap.js` TGUI interface
- [x] Add files to DME
- [x] Add location data to factions (`world_x`, `world_y`)

### Phase 2: Expedition Framework
- [x] Create `_expeditions.dm` with state defines
- [x] Implement `/datum/expedition_party`
- [x] Create expedition map device (`expedition_map_device.dm`)
- [x] Implement route planning (A* pathfinding in world_map_manager)
- [x] Create departure/return landmarks

### Phase 3: Travel Corridors
- [x] Create corridor area definitions (`corridor/corridor_areas.dm`)
- [x] Create single reusable corridor (14×80 tiles)
- [x] Implement corridor manager (`corridor/corridor_manager.dm`)
- [x] Implement corridor turfs with terrain transformation (`corridor/corridor_turfs.dm`)
- [x] Implement party teleport to corridor
- [x] Create start/event/end landmarks (`corridor/corridor_landmarks.dm`)
- [x] Implement screen fade transitions between terrain legs
- [x] Test end-to-end travel

### Phase 4: Travel Events
- [x] Create `/datum/travel_event` base with multi-choice system (`events/travel_event.dm`)
- [x] Implement `/datum/event_choice` for individual choices with different skills/outcomes
- [x] Implement invisible barrier system (spawns on event landmark crossing)
- [x] Implement skill check system (formula: 50 + (skill - difficulty) * 5, clamped 5-95%)
- [x] Create 14 events across categories:
  - [x] 6 scavenge events (`events/events_scavenge.dm`)
  - [x] 8 hazard events (`events/events_hazard.dm`)
- [x] Each event has 2-3 choices with different skill types (Mining/Cooking/Crafting)
- [x] HTML popup interface for event interaction
- [ ] Combat events (future)
- [ ] Social events (future)
- [ ] Balance difficulty/rewards (ongoing)

### Phase 5: Faction Hubs
- [x] Create faction hub area definitions (`faction_hubs/faction_hub_areas.dm`)
- [x] Create faction hub controller datum (`faction_hubs/faction_hub_controller.dm`)
- [x] Create faction trader NPC (`faction_hubs/faction_trader_npc.dm`)
- [x] Create hub landmarks - spawn, exit, trader spawn (`faction_hubs/faction_hub_landmarks.dm`)
- [x] Implement hub arrival via expedition corridor manager
- [x] Create map creation guide (`faction_hubs/MAP_CREATION_GUIDE.md`)
- [ ] Create 5 faction hub map templates (.dmm files) - **Needs mapping**
- [ ] Create `FactionHubTrading.js` TGUI interface (currently using HTML popup)
- [ ] Add hub-exclusive items to factions
- [ ] Integrate credit system with hub trading

### Phase 6: Faction Caravans
- [ ] Create `/datum/faction_caravan` datum
- [ ] Implement caravan spawning system
- [ ] Implement caravan movement on world map
- [ ] Create caravan encounter event type
- [ ] Create caravan trading UI
- [ ] Implement attack/steal/ignore options
- [ ] Add Insurgence patrol hostile variant
- [ ] Add caravan markers to world map UI

### Phase 7: Polish
- [ ] Add fog of war discovery on expedition
- [ ] Add expedition status HUD
- [ ] Sound effects and visual feedback
- [ ] Balance and testing

---

## File Structure

### New Directories
```
code/modules/resurgence_outpost/world_map/
code/modules/resurgence_outpost/expeditions/
code/modules/resurgence_outpost/expeditions/corridor/
code/modules/resurgence_outpost/expeditions/events/
code/modules/resurgence_outpost/expeditions/faction_hubs/
code/modules/resurgence_outpost/expeditions/caravans/
_maps/templates/resurgence/faction_hubs/
_maps/templates/resurgence/corridor_segments/
```

### Core Files to Create

| File | Purpose | Status |
|------|---------|--------|
| `world_map/_world_map.dm` | Global defines, terrain types | ✅ Done |
| `world_map/world_map_manager.dm` | Singleton manager, generation, state | ✅ Done |
| `world_map/world_tile.dm` | Tile datum with terrain properties | ✅ Done |
| `world_map/map_console.dm` | Physical console to view/interact with map | ✅ Done |
| `expeditions/_expeditions.dm` | Expedition state defines | ✅ Done |
| `expeditions/expedition_party.dm` | Party datum tracking members/route | ✅ Done |
| `expeditions/expedition_map_device.dm` | Handheld map device for expedition control | ✅ Done |
| `expeditions/corridor/corridor_areas.dm` | Corridor area definitions | ✅ Done |
| `expeditions/corridor/corridor_manager.dm` | Corridor state and transitions | ✅ Done |
| `expeditions/corridor/corridor_turfs.dm` | Terrain-transforming floor/wall turfs | ✅ Done |
| `expeditions/corridor/corridor_landmarks.dm` | Start/event/end landmark triggers | ✅ Done |
| `expeditions/events/travel_event.dm` | Base event with multi-choice skill checks | ✅ Done |
| `expeditions/events/events_scavenge.dm` | 6 scavenge events (3 choices each) | ✅ Done |
| `expeditions/events/events_hazard.dm` | 8 hazard events (3 choices each) | ✅ Done |
| `expeditions/events/events_combat.dm` | Combat encounter events | ❌ Planned |
| `expeditions/events/events_social.dm` | NPC interaction events | ❌ Planned |
| `expeditions/faction_hubs/faction_hub_areas.dm` | Hub area definitions | ✅ Done |
| `expeditions/faction_hubs/faction_hub_controller.dm` | Hub controller datum | ✅ Done |
| `expeditions/faction_hubs/faction_hub_landmarks.dm` | Spawn/exit/trader landmarks | ✅ Done |
| `expeditions/faction_hubs/faction_trader_npc.dm` | Trader NPC mob | ✅ Done |
| `expeditions/faction_hubs/MAP_CREATION_GUIDE.md` | Map creation documentation | ✅ Done |
| `expeditions/caravans/caravan_base.dm` | Faction caravan datum | ❌ Planned |
| `expeditions/caravans/caravan_manager.dm` | Caravan spawning and movement | ❌ Planned |
| `expeditions/caravans/caravan_encounter.dm` | Caravan encounter event | ❌ Planned |
| `expeditions/caravans/caravan_guards.dm` | Caravan guard mobs | ❌ Planned |
| `tgui/.../ResurgenceWorldMap.js` | World map TGUI interface | ✅ Done |
| `tgui/.../ExpeditionSignup.js` | Party formation UI | ❌ Planned |
| `tgui/.../FactionHubTrading.js` | Enhanced hub trading UI | ❌ Planned |
| `tgui/.../CaravanTrading.js` | Mobile caravan trading UI | ❌ Planned |

### Existing Files to Modify

| File | Changes |
|------|---------|
| `trading/factions.dm` | Add `world_x`, `world_y`, `hub_discount`, `hub_exclusive_stock` |
| `trading/_trading.dm` | Initialize faction world positions |

---

## Key Data Structures

### World Tile
```dm
/datum/world_tile
	var/x_coord, y_coord
	var/terrain_type = TERRAIN_PLAINS  // plains, forest, mountain, desert, swamp, ruins
	var/travel_cost = 1.0              // Movement cost multiplier
	var/event_chance_mod = 1.0         // Event spawn chance
	var/faction_id = null              // If faction location
	var/discovered = FALSE             // Fog of war
	var/tile_color = "#4a7c3f"         // UI display color
```

### Terrain Types & Properties
| Terrain | Travel Cost | Event Mod | Color |
|---------|-------------|-----------|-------|
| Plains | 1.0 | 1.0 | #4a7c3f (green) |
| Forest | 1.3 | 1.2 | #2d5a27 (dark green) |
| Mountain | 2.0 | 0.8 | #8b8b8b (gray) |
| Desert | 1.5 | 1.0 | #c2b280 (tan) |
| Ruins | 1.2 | 2.0 | #6b5b4f (brown) |
| Outpost | 0 | 0 | #3366cc (blue) |
| Faction | 0 | 0 | #cc9933 (gold) |

### Expedition Party
```dm
/datum/expedition_party
	var/expedition_id
	var/state = EXPEDITION_FORMING  // forming, departing, traveling, at_destination, returning, complete
	var/list/mob/living/members
	var/mob/living/leader
	var/datum/world_tile/destination
	var/datum/world_tile/current_tile
	var/list/datum/world_tile/route
	var/route_index = 0
```

### Event Choice (Implemented)
```dm
/datum/event_choice
	var/name = "Do Something"           // Display name
	var/desc = "Attempt to do something." // Description
	var/skill_type = EVENT_SKILL_NONE   // mining, cooking, crafting, or none
	var/difficulty = 5                  // 1-20 scale
	var/pass_credits = 0                // Credits on success
	var/list/pass_items = list()        // Items spawned on success
	var/pass_message = "Success!"       // Message on success
	var/fail_damage = 0                 // Damage on failure
	var/fail_damage_type = BRUTE        // BRUTE, BURN, TOX, OXY
	var/fail_message = "You failed."    // Message on failure
	var/auto_success = FALSE            // Skip skill check
	var/one_attempt = TRUE              // One try per player
```

### Travel Event (Implemented)
```dm
/datum/travel_event
	var/name = "Unknown Event"
	var/desc = "Something blocks your path."
	var/category = EVENT_CATEGORY_SCAVENGE  // scavenge, hazard, combat, social
	var/weight = 50                     // Spawn weight (higher = more common)
	var/list/valid_terrains             // Which terrain types allow this event
	var/list/datum/event_choice/choices = list()  // Available choices
	var/global_fail_damage = 0          // Damage if ALL players fail ALL choices
	var/global_fail_message = "Everyone failed."
```

---

## World Map Generation Algorithm

1. **Initialize** 15x15 grid of world tiles
2. **Place outpost** at center (7,7), mark discovered
3. **Generate terrain** using Perlin-like noise:
   - High elevation -> Mountains
   - Low elevation + high moisture -> Swamp
   - Low moisture -> Desert
   - High moisture -> Forest
   - Default -> Plains
   - 5% random -> Ruins
4. **Place factions** with constraints:
   - Min 3 tiles from outpost
   - Max 6 tiles from outpost
   - Min 3 tiles between factions
5. **Link adjacent tiles** for pathfinding
6. **Discover** 2-tile radius around outpost

---

## Travel Corridor System

### Architecture: Single Reusable Corridor

Instead of dynamically loading map templates or procedurally generating corridors at runtime, we use a **single pre-built corridor area** that is always loaded with the outpost map. This approach:
- Avoids runtime map loading complexity
- Eliminates memory issues from multiple loaded templates
- Allows easy iteration on corridor design
- Provides consistent corridor layout

### Corridor Layout (Pre-built)

The corridor is a permanent area containing **6 terrain sections** arranged linearly:

```
[OUTPOST PORTAL] -> [PLAINS] -> [FOREST] -> [MOUNTAIN] -> [DESERT] -> [RUINS] -> [DESTINATION PORTAL]
                    ~15 tiles   ~15 tiles   ~15 tiles     ~15 tiles   ~15 tiles
```

Each terrain section:
- Has its own distinct visual theming (turfs, decorations)
- Is approximately 15 tiles long (horizontal walk)
- Has a fixed event barrier trigger point at the halfway mark
- Connects seamlessly to adjacent sections

### Travel Time Scaling

Instead of dynamically changing corridor length, we control **how far players need to walk** based on terrain:

**Corridor Length = Base Length (50 tiles) × Travel Cost**

*Note: Players walk ~2.5 tiles/second, so base 50 tiles = ~20 seconds of walking*

| Terrain | Travel Cost | Corridor Length | Walk Time (approx) |
|---------|-------------|-----------------|-------------------|
| Plains | 1.0 | 50 tiles | ~20 seconds |
| Forest | 1.3 | 65 tiles | ~26 seconds |
| Desert | 1.5 | 75 tiles | ~30 seconds |
| Ruins | 1.2 | 60 tiles | ~24 seconds |
| Mountain | 2.0 | 100 tiles | ~40 seconds |

The destination portal spawns at the calculated distance, not at a fixed point.

**Total Trip Example**: Outpost → Forest → Mountain → Faction Hub
- Forest section: 65 tiles (~26 sec)
- Mountain section: 100 tiles (~40 sec)
- **Total: 165 tiles (~66 seconds)** plus event resolution time

### Screen Fade Transition System

When players traverse different terrain types along their route, we use **screen fades** to hide the visual transition:

#### Transition Flow
```
Player reaches TRANSITION ZONE (last 2 tiles of current section)
    ↓
Screen begins FADE TO BLACK (0.5 sec)
    ↓
At full black: Player teleported to START of next terrain section
    ↓
Screen FADES FROM BLACK (0.5 sec)
    ↓
Player continues walking in new terrain
```

#### Implementation
```dm
/proc/expedition_screen_fade(mob/living/user, callback)
	// Fade to black using client.color matrix
	animate(user.client, color = list(0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,1), time = 5)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(expedition_fade_callback), user, callback), 5)

/proc/expedition_fade_callback(mob/living/user, callback)
	// Execute the teleport/transition
	if(callback)
		callback.Invoke()
	// Fade back in
	animate(user.client, color = null, time = 5)
```

#### Transition Trigger
```dm
/obj/effect/corridor_transition_zone
	name = "path continues"
	density = FALSE
	invisibility = INVISIBILITY_ABSTRACT
	var/next_terrain_type
	var/turf/destination_turf

/obj/effect/corridor_transition_zone/Crossed(atom/movable/AM)
	if(isliving(AM) && !transitioning)
		initiate_transition(AM)
```

### How It Works (Full Flow)

1. **Route Planning**: Party selects destination on world map, A* calculates tile path
2. **Departure**: Party teleported to corridor start (outpost portal)
3. **Terrain Matching**: System reads first tile in route, teleports party to that terrain section
4. **Walking**: Players walk through corridor (~10-20 tiles based on terrain)
5. **Event Check**: At halfway point, invisible barrier + random event (if triggered)
6. **Section Complete**: Reaching transition zone triggers fade
7. **Next Section**: After fade, players appear in next terrain type from route
8. **Repeat**: Continue until destination reached
9. **Arrival**: Final teleport to faction hub or return portal

### Corridor Area Definition
```dm
/area/resurgence/expedition_corridor
	name = "Expedition Corridor"
	icon_state = "yellow"
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY

/area/resurgence/expedition_corridor/plains
	name = "Expedition Corridor - Plains"

/area/resurgence/expedition_corridor/forest
	name = "Expedition Corridor - Forest"

/area/resurgence/expedition_corridor/mountain
	name = "Expedition Corridor - Mountain"

/area/resurgence/expedition_corridor/desert
	name = "Expedition Corridor - Desert"

/area/resurgence/expedition_corridor/ruins
	name = "Expedition Corridor - Ruins"
```

### Corridor Map File

**File**: `_maps/resurgence/expedition_corridor.dmm`

A single reusable corridor that transforms based on the current world tile:
- **Dimensions**: 14 tiles wide × 80 tiles tall = **1,120 turfs**
- Loaded with the main outpost map
- All turfs update appearance before players enter

---

## Single Corridor Loop System

### Core Concept

One corridor serves ALL terrain types. Before players enter, every turf transforms to match the world tile they're traversing:

```
      START (Y=1)
         ↓
   [==============]  14 tiles wide
   [              ]
   [   WALKING    ]
   [    AREA      ]
   [              ]
   [==============]  ← Y=40: EVENT LANDMARK (halfway)
   [              ]     Blocks passage until event complete
   [   WALKING    ]
   [    AREA      ]
   [              ]
   [==============]  ← Y=80: END LANDMARK
         ↓              When enough players arrive:
   TRANSITION:          1. Screen fade to black
   - Teleport all       2. Teleport players to Y=1
     players to start   3. Teleport floor items to start
   - Teleport items     4. Update all turfs to next terrain
   - Update terrain     5. Screen fade in
   - Loop continues     6. Continue walking
```

### Corridor Layout (14×80)

```
X:  1    2    3    4    5    6    7    8    9   10   11   12   13   14
   +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
80 |WALL|WALL|WALL|WALL|WALL|END |END |END |END |WALL|WALL|WALL|WALL|WALL| ← End landmark
   +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
79 |WALL|PATH|PATH|PATH|PATH|PATH|PATH|PATH|PATH|PATH|PATH|PATH|PATH|WALL|
   +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
   |    |    |    |    |    |    |    |    |    |    |    |    |    |    |
   |    |    |  ... 38 rows of walking space ...                   |    |
   |    |    |    |    |    |    |    |    |    |    |    |    |    |    |
   +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
40 |WALL|PATH|PATH|PATH|EVNT|EVNT|EVNT|EVNT|EVNT|EVNT|PATH|PATH|PATH|WALL| ← Event landmark
   +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
   |    |    |    |    |    |    |    |    |    |    |    |    |    |    |
   |    |    |  ... 38 rows of walking space ...                   |    |
   |    |    |    |    |    |    |    |    |    |    |    |    |    |    |
   +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
 2 |WALL|PATH|PATH|PATH|PATH|PATH|PATH|PATH|PATH|PATH|PATH|PATH|PATH|WALL|
   +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
 1 |WALL|WALL|WALL|WALL|WALL|STRT|STRT|STRT|STRT|WALL|WALL|WALL|WALL|WALL| ← Start landmark
   +----+----+----+----+----+----+----+----+----+----+----+----+----+----+

STRT = Start landmark (where players spawn/teleport to)
EVNT = Event landmark (triggers event, blocks until resolved)
END  = End landmark (triggers transition when enough players arrive)
PATH = Walking floor (transforms per terrain)
WALL = Boundary walls (also transform per terrain)
```

### Turf Transformation

All corridor turfs can change their appearance:

```dm
/turf/open/floor/expedition
	name = "path"
	icon = 'icons/turf/floors/expedition.dmi'
	icon_state = "plains"
	/// Current terrain type
	var/current_terrain = TERRAIN_PLAINS

/turf/open/floor/expedition/proc/set_terrain(terrain_type)
	current_terrain = terrain_type
	switch(terrain_type)
		if(TERRAIN_PLAINS)
			icon_state = "plains"
			name = "grassy path"
		if(TERRAIN_FOREST)
			icon_state = "forest"
			name = "forest floor"
		if(TERRAIN_MOUNTAIN)
			icon_state = "mountain"
			name = "rocky trail"
		if(TERRAIN_DESERT)
			icon_state = "desert"
			name = "sandy path"
		if(TERRAIN_RUINS)
			icon_state = "ruins"
			name = "crumbled stone"

/turf/closed/wall/expedition
	name = "barrier"
	icon = 'icons/turf/walls/expedition.dmi'
	icon_state = "wall_plains"
	var/current_terrain = TERRAIN_PLAINS

/turf/closed/wall/expedition/proc/set_terrain(terrain_type)
	current_terrain = terrain_type
	switch(terrain_type)
		if(TERRAIN_PLAINS)
			icon_state = "wall_plains"
			name = "hillside"
		if(TERRAIN_FOREST)
			icon_state = "wall_forest"
			name = "dense trees"
		if(TERRAIN_MOUNTAIN)
			icon_state = "wall_mountain"
			name = "cliff face"
		if(TERRAIN_DESERT)
			icon_state = "wall_desert"
			name = "sand dune"
		if(TERRAIN_RUINS)
			icon_state = "wall_ruins"
			name = "ruined wall"
```

### Corridor Manager

```dm
/datum/expedition_corridor_manager
	/// The expedition party using this corridor
	var/datum/expedition_party/expedition
	/// Current index in the route
	var/route_index = 0
	/// List of all floor turfs in corridor
	var/list/floor_turfs = list()
	/// List of all wall turfs in corridor
	var/list/wall_turfs = list()
	/// Reference to event landmark
	var/obj/effect/landmark/expedition_event/event_landmark
	/// Reference to end landmark
	var/obj/effect/landmark/expedition_end/end_landmark
	/// Reference to start landmark
	var/obj/effect/landmark/expedition_start/start_landmark
	/// Whether event has been triggered this leg
	var/event_triggered = FALSE
	/// Whether event has been completed this leg
	var/event_completed = FALSE
	/// Players who have reached the end landmark
	var/list/players_at_end = list()

/datum/expedition_corridor_manager/proc/initialize_corridor()
	// Find all turfs in the corridor area
	for(var/turf/T in get_area_turfs(/area/resurgence/expedition_corridor))
		if(istype(T, /turf/open/floor/expedition))
			floor_turfs += T
		else if(istype(T, /turf/closed/wall/expedition))
			wall_turfs += T

	// Find landmarks
	event_landmark = locate(/obj/effect/landmark/expedition_event)
	end_landmark = locate(/obj/effect/landmark/expedition_end)
	start_landmark = locate(/obj/effect/landmark/expedition_start)

/datum/expedition_corridor_manager/proc/prepare_for_terrain(terrain_type)
	// Update all floor turfs
	for(var/turf/open/floor/expedition/T in floor_turfs)
		T.set_terrain(terrain_type)

	// Update all wall turfs
	for(var/turf/closed/wall/expedition/T in wall_turfs)
		T.set_terrain(terrain_type)

	// Clear and spawn decorations
	update_decorations(terrain_type)

	// Reset event state
	event_triggered = FALSE
	event_completed = FALSE
	players_at_end = list()

	// Unblock event landmark
	event_landmark.unblock()
```

### Decoration System

```dm
GLOBAL_LIST_INIT(expedition_decorations, list(
	TERRAIN_PLAINS = list(/obj/structure/flora/grass/expedition, /obj/structure/flora/rock/small),
	TERRAIN_FOREST = list(/obj/structure/flora/tree/expedition, /obj/structure/flora/bush/expedition),
	TERRAIN_MOUNTAIN = list(/obj/structure/flora/rock/large, /obj/structure/flora/rock/boulder),
	TERRAIN_DESERT = list(/obj/structure/flora/cactus, /obj/structure/flora/dead_bush),
	TERRAIN_RUINS = list(/obj/structure/ruins/pillar, /obj/structure/ruins/debris)
))

/datum/expedition_corridor_manager/proc/update_decorations(terrain_type)
	// Remove existing decorations
	for(var/turf/T in floor_turfs)
		for(var/obj/structure/flora/F in T)
			qdel(F)
		for(var/obj/structure/ruins/R in T)
			qdel(R)

	// Spawn new decorations (avoid blocking walking path)
	var/list/deco_types = GLOB.expedition_decorations[terrain_type]
	if(!deco_types)
		return

	for(var/turf/open/floor/expedition/T in floor_turfs)
		// Only decorate edge tiles (X = 2-3 or X = 12-13)
		if(T.x <= 3 || T.x >= 12)
			if(prob(20))
				var/deco_type = pick(deco_types)
				new deco_type(T)
```

### Event Landmark

```dm
/obj/effect/landmark/expedition_event
	name = "event trigger"
	invisibility = INVISIBILITY_ABSTRACT
	/// Whether passage is blocked
	var/blocked = FALSE
	/// The blocking wall objects
	var/list/obj/structure/expedition_barrier/barriers = list()
	/// Parent corridor manager
	var/datum/expedition_corridor_manager/manager

/obj/effect/landmark/expedition_event/proc/trigger_event(mob/living/triggerer)
	if(manager.event_triggered)
		return

	manager.event_triggered = TRUE
	block_passage()

	// Pick and start a random event
	var/datum/travel_event/event = pick_event_for_terrain(manager.get_current_terrain())
	event.start(manager.expedition)

/obj/effect/landmark/expedition_event/proc/block_passage()
	blocked = TRUE
	// Spawn barrier walls across the corridor at Y+1
	for(var/x in 2 to 13)
		var/turf/T = locate(x, src.y + 1, src.z)
		var/obj/structure/expedition_barrier/B = new(T)
		barriers += B

/obj/effect/landmark/expedition_event/proc/unblock()
	blocked = FALSE
	for(var/obj/structure/expedition_barrier/B in barriers)
		qdel(B)
	barriers = list()

/obj/effect/landmark/expedition_event/Crossed(atom/movable/AM)
	if(!isliving(AM))
		return
	if(!manager.event_triggered)
		trigger_event(AM)
```

### End Landmark & Transition

```dm
/obj/effect/landmark/expedition_end
	name = "path continues"
	invisibility = INVISIBILITY_ABSTRACT
	/// Parent corridor manager
	var/datum/expedition_corridor_manager/manager
	/// Minimum players needed to trigger transition (percentage of party)
	var/required_ratio = 0.5

/obj/effect/landmark/expedition_end/Crossed(atom/movable/AM)
	if(!isliving(AM))
		return
	var/mob/living/L = AM
	if(!(L in manager.expedition.members))
		return

	manager.players_at_end |= L
	check_transition()

/obj/effect/landmark/expedition_end/proc/check_transition()
	var/living_members = 0
	for(var/mob/living/M in manager.expedition.members)
		if(M.stat != DEAD)
			living_members++

	var/needed = max(1, round(living_members * required_ratio))

	if(length(manager.players_at_end) >= needed)
		manager.begin_transition()

/datum/expedition_corridor_manager/proc/begin_transition()
	// Advance route
	route_index++

	// Check if we've reached destination
	if(route_index >= length(expedition.route))
		arrive_at_destination()
		return

	// Get next terrain
	var/datum/world_tile/next_tile = expedition.route[route_index + 1]
	var/next_terrain = next_tile.terrain_type

	// Fade out all players
	for(var/mob/living/M in expedition.members)
		animate(M.client, color = list(0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,1), time = 5)

	// Wait for fade
	addtimer(CALLBACK(src, PROC_REF(execute_transition), next_terrain), 5)

/datum/expedition_corridor_manager/proc/execute_transition(next_terrain)
	// Collect all items on floor
	var/list/floor_items = list()
	for(var/turf/T in floor_turfs)
		for(var/obj/item/I in T)
			floor_items += I

	// Get start position
	var/turf/start_turf = get_turf(start_landmark)

	// Teleport all players to start
	for(var/mob/living/M in expedition.members)
		M.forceMove(start_turf)

	// Teleport all items to start area
	for(var/obj/item/I in floor_items)
		I.forceMove(start_turf)

	// Update terrain
	prepare_for_terrain(next_terrain)

	// Fade back in
	for(var/mob/living/M in expedition.members)
		animate(M.client, color = null, time = 5)

	// Notify
	for(var/mob/living/M in expedition.members)
		to_chat(M, span_notice("You continue into [get_terrain_name(next_terrain)] territory..."))
```

### Travel Flow (Complete Example)

**Route**: Outpost → Forest → Mountain → Cloud Town

```
1. DEPARTURE
   - Party forms at outpost signup console
   - Leader clicks "Depart"
   - prepare_for_terrain(TERRAIN_FOREST) called
   - All corridor turfs become forest-themed
   - Players teleported to start landmark (Y=1)

2. WALKING (Y=1 to Y=40)
   - Players walk north through forest corridor
   - Decorations: trees, bushes along edges
   - Optional: Apply movement speed modifier for terrain

3. EVENT (Y=40)
   - First player crosses event landmark
   - Barrier walls spawn at Y=41
   - Random forest event triggers (e.g., "Wolf Pack Encounter")
   - Players must resolve event (combat/skill check)
   - On success: barriers removed, event_completed = TRUE

4. WALKING (Y=40 to Y=80)
   - Players continue north
   - Reach end landmark

5. TRANSITION
   - 50%+ of living players at end landmark
   - Screen fades to black (0.5 sec)
   - All players teleported to Y=1
   - All floor items teleported to Y=1
   - prepare_for_terrain(TERRAIN_MOUNTAIN) called
   - All turfs become mountain-themed
   - Screen fades in (0.5 sec)

6. WALKING (Y=1 to Y=40) - Mountain
   - Same as step 2, but mountain theme
   - Players move slower (mountain terrain penalty)

7. EVENT (Y=40) - Mountain
   - Different event pool (mountain events)
   - e.g., "Rockslide" skill check

8. WALKING (Y=40 to Y=80) - Mountain
   - Continue to end

9. ARRIVAL
   - route_index reaches end
   - arrive_at_destination() called
   - Players teleported to Cloud Town faction hub
   - Expedition complete!
```

### Memory Efficiency

| Component | Count |
|-----------|-------|
| Floor turfs | 14 × 78 = 1,092 |
| Wall turfs | (14 × 2) = 28 |
| **Total** | **1,120 turfs** |

Compared to alternatives:
- Per-terrain corridors: 5 × 1,120 = 5,600 turfs
- This approach: **1,120 turfs (80% reduction)**

### Multi-Player Expedition Mechanics

When more than one player joins an expedition, special rules apply to keep the group together and handle events cooperatively.

#### Group Cohesion

**Transition Zones (Terrain Changes)**
- Transition only triggers when **all living party members** are in the transition zone
- A "Waiting for party..." message displays showing who hasn't arrived yet
- If a player is dead/incapacitated, they are automatically teleported with the group
- **Straggler Timer**: After 60 seconds of waiting, the transition triggers anyway
  - Stragglers are teleported to catch up
  - Prevents one AFK player from blocking the entire expedition

**Implementation**:
```dm
/obj/effect/corridor_transition_zone/proc/check_party_ready()
	var/list/missing = list()
	for(var/mob/living/M in expedition_party.members)
		if(M.stat == DEAD)
			continue  // Dead players auto-teleport
		if(!(M in players_in_zone))
			missing += M

	if(!length(missing))
		initiate_group_transition()
	else
		// Show waiting message
		for(var/mob/living/M in players_in_zone)
			to_chat(M, span_notice("Waiting for: [english_list(missing)]"))
```

#### Event Participation

**Event Barrier**
- Barrier blocks **all** party members, not just the first to arrive
- Event triggers when **any** party member touches the barrier
- All nearby party members are pulled into the event

**Skill Checks (Multi-Player)**
- Each player can attempt the skill check
- **First success** resolves the event for everyone
- If all players fail, the failure consequence applies to the whole group
- Some events may allow **combined skill** (sum of all players' skill levels)

**Combat Events**
- All party members participate in combat
- Event resolves when all enemies are defeated
- If party wipes, they respawn at outpost (expedition failed)

#### Party Separation Prevention

**Soft Walls**
- Invisible barriers prevent party members from getting too far ahead
- If a player is more than 30 tiles ahead of the slowest member, they hit a soft wall
- Message: "You should wait for your companions."

**Emergency Regroup**
- Party leader can use "Regroup" action (30 second cooldown)
- Teleports all party members to the leader's position
- Useful if someone gets stuck or lost

#### Player Disconnection

**Disconnect During Travel**
- Disconnected player's mob continues with the group (ghosted along)
- If they reconnect, they resume control
- If expedition completes while disconnected:
  - Their mob is returned to outpost
  - They get a message on reconnect about what happened

**Disconnect During Event**
- Their mob is treated as "incapacitated" for event purposes
- Other players must resolve the event without them
- Combat: Their mob stands still (can be killed)
- Skill check: They cannot contribute

#### Party Wipe

If all party members die during the expedition:
1. **Expedition Fails** - All progress lost
2. **Respawn at Outpost** - Players respawn at the outpost medbay
3. **Gear Loss** (Optional Setting):
   - Easy Mode: Keep all gear
   - Normal Mode: Lose carried loot, keep equipped gear
   - Hard Mode: Lose everything (must retrieve from corpse on next expedition)
4. **Reputation Penalty** - Small reputation loss with destination faction

---

## Event System (Implemented)

### Event Trigger Mechanic
Each corridor has an **invisible barrier wall** at the halfway point (Y=40):
1. When a player crosses the expedition_event landmark, barriers spawn at Y=41
2. Walking into/clicking a barrier opens an HTML popup with event choices
3. Players select a choice to attempt (each choice has different skill/difficulty)
4. Skill check is performed, pass/fail outcomes applied
5. First player to succeed resolves the event for everyone
6. If ALL players fail ALL choices, global fail penalty applied
7. Barriers removed, players can proceed to end landmark

### Event Barrier Implementation (Implemented)
```dm
/obj/structure/expedition_barrier
	name = "impassable obstacle"
	density = TRUE
	invisibility = INVISIBILITY_ABSTRACT  // Invisible but blocks movement
	alpha = 0
	var/datum/travel_event/current_event

/obj/structure/expedition_barrier/Bumped(atom/movable/AM)
	if(isliving(AM) && !resolved)
		interact_with_event(AM)  // Opens HTML popup
```

### Skill Check Formula (Implemented)
```
success_chance = 50 + (skill_level - difficulty) * 5
clamped to 5-95%

Example: Skill 7 vs Difficulty 5 = 50 + (7-5)*5 = 60% chance
Example: Skill 3 vs Difficulty 8 = 50 + (3-8)*5 = 25% chance
```

### Multi-Choice System (Implemented)
Each event has 2-3 choices with different approaches:
- **Different skill types**: Mining, Cooking, or Crafting per choice
- **Different difficulties**: Easy (3-5), Medium (5-7), Hard (7-9)
- **Different outcomes**: Credits, items, damage amounts vary
- **Safe options**: Some choices have `auto_success = TRUE`
- **One-attempt tracking**: Each player can only try each choice once
- **Flee option**: Take damage to mark all choices as attempted

### HTML Popup Interface (Implemented)
- Styled popup window (450x550) with dark theme
- Event title, category badge, and description
- Each choice shows:
  - Name and description
  - Skill badge (colored by type: Mining=brown, Cooking=green, Crafting=blue)
  - Difficulty rating
  - "Choose" button (or "Already Tried" if attempted)
- Flee button at bottom with damage warning
- Reopens when player bumps/clicks barrier again

### Event Categories & Implemented Events

**Scavenge (6 events implemented)**
| Event | Choices | Terrains |
|-------|---------|----------|
| Abandoned Cache | Disarm (Mining 7), Force (Crafting 5), Leave (Safe) | Plains, Desert, Ruins, Mountain |
| Overgrown Garden | Identify (Cooking 5), Track (Mining 6), Grab All (Cooking 8) | Plains, Forest |
| Scrap Pile | Careful (Crafting 6), Dig (Mining 5), Search Edges (Crafting 3) | Ruins, Desert, Plains |
| Forgotten Supply Drop | Hack (Crafting 8), Manual Release (Mining 6), Brute Force (Mining 4) | All terrains |
| Mushroom Patch | Identify (Cooking 6), Harvest Glowing (Cooking 9), Take Common (Safe) | Forest, Ruins |
| Mineral Vein | Careful (Mining 7), Smash (Crafting 5), Surface Only (Mining 3) | Mountain, Ruins |

**Hazard (8 events implemented)**
| Event | Choices | Terrains |
|-------|---------|----------|
| Quicksand Pit | Read Terrain (Mining 6), Sprint (Crafting 7), Go Around (Safe) | Desert, Forest |
| Toxic Spores | Burn (Cooking 7), Hold Breath (Mining 6), Alternate Route (Crafting 5) | Forest, Ruins |
| Unstable Cliff | Analyze (Crafting 7), Shore Up (Mining 8), Run For It (Mining 5) | Mountain, Ruins |
| Sandstorm | Dig Shelter (Mining 6), Find Cover (Cooking 5), Outrun (Crafting 8) | Desert |
| Flash Flood | High Ground (Mining 7), Anchor (Crafting 6), Swim (Cooking 8) | Plains, Forest |
| Poison Ivy | Identify Path (Cooking 5), Clear Path (Crafting 6), Push Through (Safe+damage) | Forest, Plains |
| Collapsing Structure | Shore Up (Crafting 7), Quick Nav (Mining 6), Go Around (Cooking 4) | Ruins |
| Heat Wave | Pace/Hydrate (Cooking 5), Seek Shade (Mining 5), Sprint (Crafting 7) | Desert |

**Combat (planned)**
- Wolf Pack, Bandit Ambush, Insect Swarm

**Social (planned)**
- Traveling Merchant, Lost Traveler, Faction Scout

---

## Faction Hub System

### Hub Features
- Small pre-built area (10x10 to 15x15)
- Faction trader NPC with enhanced trading
- Hub-exclusive items not available via comms console
- 10% price discount for in-person trading
- Unique visual theme per faction

### Faction Hubs (Based on factions.dm)

#### Resurgence Clan Village (Friendly - Starting Rep 75)
- **Theme**: Rustic ancestral camp, traditional architecture
- **Speaker**: The Historian (Elder)
- **Standard Stock**: Vines, fertilizer, faith fabrics (simple/advanced/elegant), durathread, basic seeds (wheat, potato, carrot), analysis skill books
- **Hub Exclusive**: Rare elegant faith fabrics, advanced analysis tomes, ancestral artifacts

#### Jiajia-ren Village (Neutral - Starting Rep 40)
- **Theme**: Bird-folk trading post with colorful feathers and shiny decorations
- **Speaker**: Chir-rik (Trader of the Flock)
- **Standard Stock**: Silver/gold ore and sheets, leather/hides, exotic fruit seeds (berry, apple, banana, orange, grape, watermelon, pineapple), various meats (chicken, bear, penguin, gondola), bacon
- **Hub Exclusive**: Rare gondola meat, unique feathered trinkets, high-quality precious metals

#### Santata's Gift Factory (Neutral - Starting Rep 50)
- **Theme**: Industrial nightmare, endless assembly lines, ominous chimneys
- **Speaker**: Dodoru (High-Ranking Factory Gnome)
- **Standard Stock**: Bulk metals/glass/rods, raw ores (iron, sand, rock), coal, plasteel, ash plating, metal tools (hatchets, pickaxes, shovels, crowbar, scythe), silver pickaxe, kitchen tools, crafting/mining skill books
- **Hub Exclusive**: Factory-grade plasteel, master craftsman tomes, mysterious "volunteer opportunities"

#### Cloud Town (Neutral - Starting Rep 40)
- **Theme**: Pastoral human settlement, farms and gardens
- **Speaker**: Domino (Seasoned Hunter)
- **Standard Stock**: THE SEED EMPORIUM (15-25 seed varieties!), leather/hides, cotton, durathread, cooking ingredients (flour, rice, eggs, enzyme, milk, soymilk, mayo), harvesting/cooking skill books
- **Hub Exclusive**: Rare seed varieties, secret family recipes, advanced cooking ingredients

#### Insurgence Clan (HOSTILE - Starting Rep 5, Max Rep 10)
- **Theme**: Hostile military encampment - **CANNOT BE VISITED PEACEFULLY**
- **Speaker**: ??? (Unknown - only static transmissions)
- **Behavior**: Does not trade. Sends raids against outpost.
- **Hub Access**: Traveling to Insurgence territory triggers an **ambush event** instead of a trading hub. Players must fight their way out or be captured.
- **Special**: If players somehow reach very high reputation (impossible normally), could unlock black market combat gear

---

## Faction Caravan System

### Overview
Factions periodically send caravans across the world map, traveling between locations. Players can encounter these caravans during their expeditions for trading opportunities - or hostile interactions.

### Caravan Behavior
- **Spawn**: Factions (except Insurgence) randomly spawn caravans from their home tile
- **Movement**: Caravans move slowly across the map (1 tile every 2-3 minutes)
- **Destinations**: Travel to random points, other faction hubs, or the player outpost
- **Visibility**: Shown on world map as moving icons (visible even in fog of war once spotted)
- **Despawn**: Disappear when reaching destination, or after set time limit

### Caravan Data Structure
```dm
/datum/faction_caravan
	var/caravan_id
	var/datum/trading_faction/owner_faction
	var/datum/world_tile/current_tile
	var/datum/world_tile/destination
	var/list/datum/world_tile/route
	var/route_index = 0
	var/list/stock              // Subset of faction's stock
	var/current_cash            // Limited cash for buying
	var/move_timer              // Time until next tile move
	var/stopped = FALSE         // TRUE if encountered by players
```

### Player Encounter
When a player expedition enters a tile containing a caravan (or vice versa):
1. The caravan **stops moving** on the world map
2. Players encounter the caravan in their travel corridor
3. A special **caravan encounter event** triggers at the barrier

### Caravan Encounter Options

#### Trade (Peaceful)
- Opens a mobile trading UI similar to faction hub
- Limited stock (subset of faction's normal inventory)
- Limited cash (caravan carries less than the full faction)
- **No discount** (unlike visiting the hub directly)
- Successful trade gives small reputation boost

#### Attack (Hostile)
- Initiates combat with caravan guards
- Guards scale based on faction (Factory has more guards than Clan)
- If players win:
  - Can loot caravan goods
  - **Major reputation loss** with that faction (-15 to -25)
  - Small reputation loss with other factions who hear about it (-5)
- If players lose/flee:
  - Caravan escapes, reports back
  - Reputation loss still applies

#### Steal (Risky)
- Skill check (crafting or mining) to pilfer goods unnoticed
- **Success**: Gain some items, no reputation loss, caravan continues
- **Failure**: Caught! Caravan becomes hostile, reputation loss (-10)
- Higher difficulty than combat but less reputation risk

#### Ignore
- Let caravan pass, continue on your way
- No reputation change

### Caravan Types by Faction

| Faction | Caravan Name | Guards | Stock Focus |
|---------|--------------|--------|-------------|
| Resurgence Clan | Clan Pilgrims | 2-3 weak | Faith fabrics, vines, seeds |
| Jiajia-ren | Flock Traders | 3-4 medium | Precious metals, meats, hides |
| Santata Factory | Gnome Convoy | 4-5 strong | Bulk materials, tools, coal |
| Cloud Town | Frontier Wagon | 3-4 medium | Seeds, cooking supplies, leather |
| Insurgence Clan | Raider Patrol | 5-6 strong | **ALWAYS HOSTILE** - attacks on sight |

### Insurgence Patrols
The Insurgence Clan sends **patrols** instead of trade caravans:
- Always hostile - no trade option
- Encountering one triggers immediate combat
- Defeating a patrol gives no reputation (they're already hostile)
- Patrols may be hunting for player expeditions specifically

### Spawn Frequency
- Each trading faction: ~10% chance per 5 minutes to spawn a caravan
- Maximum 1 active caravan per faction at a time
- Insurgence patrols: 15% chance, can have up to 2 active

### World Map Display
- Caravan icons show faction colors
- Moving caravans have animated indicator
- Stopped caravans (encountered) show different icon
- Players can see caravan routes if discovered

---

## TGUI Components

### ResurgenceWorldMap.js
- SVG-based grid (reuse GridCraftingStation.js patterns)
- Terrain tiles with colored backgrounds
- Faction markers with icons
- **Caravan markers** with faction colors and movement animation
- Route path visualization (SVG lines)
- Expedition party marker
- Fog of war overlay for undiscovered tiles
- Click-to-select destination
- Party panel showing members
- Depart button

### ExpeditionSignup.js
- Destination display
- Route preview
- Estimated travel time
- Party member list with join/leave buttons
- Leader designation
- Depart when ready button

### FactionHubTrading.js
- Similar to ResurgenceTrading.js
- Shows hub discount
- Hub-exclusive items section
- No comms console requirement

---

## Implementation Order

### Phase 1: World Map Core
1. Create `_world_map.dm` with terrain defines
2. Implement `/datum/world_tile`
3. Implement `/datum/world_map_manager` with generation
4. Add location data to factions
5. Create map viewing console
6. Create `ResurgenceWorldMap.js`

### Phase 2: Expedition Framework
1. Create `_expeditions.dm` with state defines
2. Implement `/datum/expedition_party`
3. Create signup console and TGUI
4. Implement route planning (A* pathfinding)
5. Create departure/return landmarks

### Phase 3: Travel Corridors
1. Create corridor area definitions
2. Create 6 terrain segment templates
3. Implement corridor generator
4. Implement party teleport to corridor
5. Create arrival triggers
6. Test end-to-end travel

### Phase 4: Travel Events
1. Create `/datum/travel_event` base
2. Implement skill check system
3. Create 15-20 events across categories
4. Implement event spawning during travel
5. Create encounter objects
6. Balance difficulty/rewards

### Phase 5: Faction Hubs
1. Create 5 faction hub map templates
2. Create faction trader NPC
3. Implement hub controller
4. Create `FactionHubTrading.js`
5. Add hub-exclusive items to factions
6. Implement hub arrival/departure

### Phase 6: Faction Caravans
1. Create `/datum/faction_caravan` datum
2. Implement caravan spawning system
3. Implement caravan movement on world map
4. Create caravan encounter event type
5. Create caravan trading UI (mobile version)
6. Implement attack/steal/ignore options
7. Add Insurgence patrol hostile variant
8. Add caravan markers to world map UI

### Phase 7: Polish
1. Add fog of war discovery
2. Add expedition status HUD
3. Sound effects and visual feedback
4. Balance and testing

---

## Integration Points

| Existing System | Integration |
|-----------------|-------------|
| `trading/factions.dm` | Add world coordinates, hub data |
| `stats/character_stats.dm` | Skill checks use existing stats |
| `raids/raider_component.dm` | Reuse pathfinding patterns |
| `events/event_base.dm` | Similar event structure |
| `GridCraftingStation.js` | Reuse SVG grid patterns |

---

## Critical Files Reference

- `code/modules/resurgence_outpost/trading/factions.dm` - Extend with location data
- `code/modules/resurgence_outpost/stats/character_stats.dm` - Skill check integration
- `code/modules/resurgence_outpost/raids/raider_component.dm` - Pathfinding patterns
- `tgui/packages/tgui/interfaces/GridCraftingStation.js` - SVG grid UI patterns
- `tgui/packages/tgui/interfaces/ResurgenceResearch.js` - Path visualization patterns
