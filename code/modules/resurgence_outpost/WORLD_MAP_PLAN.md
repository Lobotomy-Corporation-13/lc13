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
- [ ] Create `_expeditions.dm` with state defines
- [ ] Implement `/datum/expedition_party`
- [ ] Create signup console and TGUI
- [ ] Implement route planning (A* pathfinding) - *partially done in world_map_manager*
- [ ] Create departure/return landmarks

### Phase 3: Travel Corridors
- [ ] Create corridor area definitions
- [ ] Create 6 terrain segment templates (.dmm files)
- [ ] Implement corridor generator
- [ ] Implement party teleport to corridor
- [ ] Create arrival triggers
- [ ] Test end-to-end travel

### Phase 4: Travel Events
- [ ] Create `/datum/travel_event` base
- [ ] Implement invisible barrier system
- [ ] Implement skill check system
- [ ] Create 15-20 events across categories
- [ ] Create encounter objects
- [ ] Balance difficulty/rewards

### Phase 5: Faction Hubs
- [ ] Create 5 faction hub map templates
- [ ] Create faction trader NPC
- [ ] Implement hub controller
- [ ] Create `FactionHubTrading.js`
- [ ] Add hub-exclusive items to factions
- [ ] Implement hub arrival/departure

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

| File | Purpose |
|------|---------|
| `world_map/_world_map.dm` | Global defines, terrain types |
| `world_map/world_map_manager.dm` | Singleton manager, generation, state |
| `world_map/world_tile.dm` | Tile datum with terrain properties |
| `world_map/world_generator.dm` | Procedural noise-based generation |
| `world_map/map_console.dm` | Physical console to view/interact with map |
| `expeditions/_expeditions.dm` | Expedition state defines |
| `expeditions/expedition_party.dm` | Party datum tracking members/route |
| `expeditions/expedition_signup.dm` | Sign-up console object |
| `expeditions/corridor/corridor_generator.dm` | Procedural corridor creation |
| `expeditions/corridor/corridor_tiles.dm` | Terrain tile objects for corridors |
| `expeditions/events/travel_event_base.dm` | Base event with skill checks |
| `expeditions/events/travel_events_*.dm` | Event types (combat, scavenge, etc.) |
| `expeditions/faction_hubs/faction_hub_base.dm` | Hub controller datum |
| `expeditions/faction_hubs/faction_trader_npc.dm` | Trader NPC mob |
| `expeditions/caravans/caravan_base.dm` | Faction caravan datum |
| `expeditions/caravans/caravan_manager.dm` | Caravan spawning and movement |
| `expeditions/caravans/caravan_encounter.dm` | Caravan encounter event |
| `expeditions/caravans/caravan_guards.dm` | Caravan guard mobs |
| `tgui/.../ResurgenceWorldMap.js` | World map TGUI interface |
| `tgui/.../ExpeditionSignup.js` | Party formation UI |
| `tgui/.../FactionHubTrading.js` | Enhanced hub trading UI |
| `tgui/.../CaravanTrading.js` | Mobile caravan trading UI |

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

### Travel Event
```dm
/datum/travel_event
	var/name, desc
	var/category  // combat, scavenge, navigation, social, hazard
	var/weight = 50
	var/skill_type  // crafting, mining, cooking, or null
	var/difficulty = 5  // 1-20
	var/list/valid_terrains
	// Pass rewards
	var/pass_credits, pass_reputation, list/pass_items
	// Fail penalties
	var/fail_damage, fail_debuff
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

A single `.dmm` file contains the entire corridor:
- `_maps/resurgence/expedition_corridor.dmm`
- Loaded with the main outpost map
- Contains all 5 terrain sections + portals
- Each section ~100 tiles long (to accommodate mountain's 2.0x cost)
- **Total corridor: ~500 tiles long × 7 tiles wide**
- Destination portal position is dynamically set based on terrain type

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

## Event System

### Event Trigger Mechanic
Each corridor segment has an **invisible barrier wall** placed at the halfway point:
1. When a player walks into the barrier, a random event is triggered
2. The barrier blocks further progress until the event is resolved
3. Players must deal with the event (skill check, combat, etc.) to proceed
4. Once resolved, the barrier disappears and the corridor exit becomes accessible
5. **The barrier resets each time players re-enter the corridor** (returning to outpost and departing again)

### Event Barrier Implementation
```dm
/obj/effect/expedition_barrier
	name = "something blocks your path"
	density = TRUE
	invisibility = INVISIBILITY_ABSTRACT
	var/datum/travel_event/current_event
	var/resolved = FALSE

/obj/effect/expedition_barrier/Bumped(atom/movable/AM)
	if(isliving(AM) && !resolved)
		trigger_event(AM)
```

### Skill Check Formula
```
success_chance = 50 + (skill_level - difficulty) * 5
clamped to 5-95%
```

### Event Categories & Examples

**Scavenge (40% weight)**
- Abandoned Cache (mining check) - Find supplies or trigger trap
- Overgrown Garden (cooking check) - Harvest plants or get poisoned
- Scrap Pile (crafting check) - Salvage materials or cut yourself

**Combat (25% weight)**
- Wolf Pack - Fight hostile wolves
- Bandit Ambush - Fight raiders (Insurgence scouts)
- Insect Swarm - Fight bugs

**Hazard (15% weight)**
- Quicksand (mining) - Escape or take damage
- Toxic Spores (cooking) - Resist poison or get debuffed
- Rockslide (crafting) - Dodge or take damage
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
