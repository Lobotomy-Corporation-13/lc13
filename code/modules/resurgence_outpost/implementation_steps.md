# Resurgence Outpost - Implementation Steps

Each step is self-contained and can be tested independently. Complete and test each step before moving to the next.

---

## Step 1: Faith Event System

**Goal:** Create the core faith event datum that other systems will use.

**Files to create:**
- `code/datums/faith_event.dm`

**Implementation:**
```dm
/datum/faith_event
    var/description = ""
    var/faith_change = 0
    var/timeout = null          // null = permanent until cleared
    var/category = "generic"
    var/hidden = FALSE

/datum/faith_event/New(desc, change, time = null, cat = "generic")
    description = desc
    faith_change = change
    timeout = time
    category = cat
    if(timeout)
        addtimer(CALLBACK(src, PROC_REF(expire)), timeout)

/datum/faith_event/proc/expire()
    qdel(src)

// Specific event types
/datum/faith_event/clothing
    category = "clothing"

/datum/faith_event/shelter
    category = "shelter"

/datum/faith_event/community
    category = "community"

/datum/faith_event/monument
    category = "monument"
```

**Testing:**
1. Compile - should have no errors
2. No in-game testing needed yet (this is a data structure)

**Status:** [x] Complete

---

## Step 2: Update Resurgence Core Organ

**Goal:** Add faith event list and decay-based charge system to the existing core.

**Files to modify:**
- `code/modules/surgery/organs/resurgence_core.dm`

**Changes:**
1. Remove `charge_regen_rate`, add `charge_decay_rate`
2. Add `faith_events` list
3. Add procs: `add_faith_event()`, `clear_faith_event()`, `recalculate_faith()`, `get_faith_decay_modifier()`
4. Update `on_life()` to decay charge instead of regenerate

**Testing:**
1. Spawn a resurgence machine mob
2. Use "Check Core Status" action - should show charge and faith
3. Wait and verify charge decreases over time (not increases)
4. Verify faith level affects charge decay speed

**Status:** [x] Complete

---

## Step 3: Basic Crafted Components

**Goal:** Create the component items that will be used in crafting recipes.

**Files to create:**
- `code/modules/resurgence_outpost/components.dm`

**Implementation:**
```dm
// Base component
/obj/item/resurgence_component
    name = "component"
    desc = "A crafted component."
    icon = 'icons/obj/device.dmi'  // Use existing icon temporarily
    icon_state = "intm_circuit"    // Placeholder
    w_class = WEIGHT_CLASS_SMALL

// Tier 2 Components
/obj/item/resurgence_component/wooden_plank
    name = "wooden plank"
    desc = "A shaped wooden plank."
    icon_state = "wooden_plank"    // Will need sprite later

/obj/item/resurgence_component/metal_rod
    name = "metal rod"
    desc = "A sturdy metal rod."

/obj/item/resurgence_component/metal_plate
    name = "metal plate"
    desc = "A flat metal plate."

/obj/item/resurgence_component/rope
    name = "rope"
    desc = "Strong woven rope."

/obj/item/resurgence_component/leather_strip
    name = "leather strip"
    desc = "A strip of treated leather."

/obj/item/resurgence_component/glass_lens
    name = "glass lens"
    desc = "A polished glass lens."

// Nails as a stack
/obj/item/stack/resurgence_nails
    name = "nails"
    desc = "Metal nails for construction."
    singular_name = "nail"
    icon = 'icons/obj/stack_objects.dmi'
    icon_state = "sheet-silver"  // Placeholder
    max_amount = 50

// Tier 3 Components
/obj/item/resurgence_component/metal_frame
    name = "metal frame"
    desc = "A sturdy metal frame."
    w_class = WEIGHT_CLASS_NORMAL

/obj/item/resurgence_component/gear_assembly
    name = "gear assembly"
    desc = "Interlocking gears for machinery."

/obj/item/resurgence_component/reinforced_plate
    name = "reinforced plate"
    desc = "A heavy reinforced plate."
    w_class = WEIGHT_CLASS_NORMAL

/obj/item/resurgence_component/carved_ornament
    name = "carved ornament"
    desc = "An intricately carved piece."

/obj/item/resurgence_component/woven_tapestry
    name = "woven tapestry"
    desc = "A decorative tapestry."
    w_class = WEIGHT_CLASS_NORMAL
```

**Testing:**
1. Compile - no errors
2. Spawn each component via admin panel
3. Verify they can be picked up, dropped, stored in containers

**Status:** [x] Complete

---

## Step 4: Crafting Table Structure

**Goal:** Create a basic crafting table that can craft Tier 2 components.

**Files to create:**
- `code/modules/resurgence_outpost/structures/crafting_table.dm`

**Implementation:**
- Clickable structure with radial menu or TGUI
- Recipes for Tier 2 components and floor tiles
- `do_after()` for crafting time
- Checks player inventory for materials

**Key Recipes:**
| Output | Input |
|--------|-------|
| 1 Wooden Plank | 2 Wood |
| 1 Metal Rod | 1 Metal Sheet |
| 1 Metal Plate | 2 Metal Sheets |
| 1 Rope | 3 Cloth |
| 10 Nails | 1 Metal Sheet |
| 4 Wood Floor Tiles | 1 Wood |
| 4 Carpet Tiles | 2 Cloth |

**Testing:**
1. Spawn crafting table and wood sheets
2. Click table, select "Wooden Plank"
3. Verify wood is consumed and plank is created
4. Test all Tier 2 component recipes
5. Test floor tile recipes

**Status:** [x] Complete

---

## Step 5: Forge Structure

**Goal:** Create forge for smelting ore and crafting Tier 3 components.

**Files to create:**
- `code/modules/resurgence_outpost/structures/forge.dm`

**Implementation:**
- Similar to crafting table but for metalworking
- Smelting recipes (ore → metal)
- Tier 3 component recipes

**Key Recipes:**
| Output | Input |
|--------|-------|
| 1 Metal Sheet | 2 Iron Ore |
| 1 Glass Sheet | 2 Sand |
| 1 Metal Frame | 4 Metal Rods + 2 Metal Plates |
| 1 Gear Assembly | 3 Metal Sheets |
| 1 Reinforced Plate | 2 Metal Plates + 1 Plasteel |

**Testing:**
1. Spawn forge and iron ore
2. Smelt ore into metal sheets
3. Craft Tier 3 components from Tier 2 components

**Status:** [x] Complete

---

## Step 6: Loom Structure (Basic Cloth Processing)

**Goal:** Create loom for processing fiber into cloth.

**Files to create:**
- `code/modules/resurgence_outpost/structures/loom.dm`

**Implementation:**
- Process plant fiber into cloth
- Recipe: 3 Plant Fiber → 1 Cloth

**Testing:**
1. Spawn loom and plant fiber
2. Process fiber into cloth
3. Verify cloth can be used in crafting table recipes

**Status:** [x] Complete

---

## Step 7: Blueprint Planner Tool

**Goal:** Create the handheld tool for placing construction blueprints.

**Files to create:**
- `code/modules/resurgence_outpost/blueprints/blueprint_planner.dm`
- `code/modules/resurgence_outpost/blueprints/blueprint_base.dm`

**Implementation:**
- Radial menu with categories (Construction, Storage, Production, Decor)
- Click ground to place transparent blueprint ghost
- Alt-click to rotate, right-click to remove

**Testing:**
1. Spawn blueprint planner
2. Click in hand to open menu
3. Select a structure, click ground
4. Verify transparent blue ghost appears
5. Test rotation and removal

**Status:** [ ] Not Started / [ ] In Progress / [ ] Complete

---

## Step 8: Blueprint Construction System

**Goal:** Allow blueprints to accept materials and become structures.

**Files to create:**
- `code/modules/resurgence_outpost/blueprints/blueprint_types.dm`

**Implementation:**
- Base `/obj/structure/blueprint` with material tracking
- Subtypes for each buildable structure
- `attackby()` to accept materials
- `do_after()` construction when complete

**Start with these blueprints:**
- Wood Wall (5 wood → wall turf)
- Storage Chest (10 wood → chest)
- Crafting Table (15 wood → crafting table)

**Testing:**
1. Place wood wall blueprint
2. Hit with wood sheets until complete
3. Verify wall appears and blueprint disappears
4. Test chest and crafting table blueprints

**Status:** [ ] Not Started / [ ] In Progress / [ ] Complete

---

## Step 9: Basic Structures (Walls, Chests)

**Goal:** Create the actual structures that blueprints build.

**Files to create:**
- `code/modules/resurgence_outpost/structures/walls.dm`
- `code/modules/resurgence_outpost/structures/storage.dm`

**Implementation:**
- Wood wall turf (or structure if turf is complex)
- Storage chest (based on `/obj/structure/closet`)
- Crate and barrel variants

**Testing:**
1. Build structures via blueprints
2. Open/close chest, store items
3. Verify wall blocks movement

**Status:** [ ] Not Started / [ ] In Progress / [ ] Complete

---

## Step 10: Room Detection System

**Goal:** Detect enclosed spaces for room designation.

**Files to create:**
- `code/modules/resurgence_outpost/rooms/room_detection.dm`

**Implementation:**
- Flood-fill algorithm to find enclosed turfs
- Stop at walls/closed turfs
- Return null if space opens to outdoors
- Max size limit (100 tiles)

**Testing:**
1. Build a 4-wall enclosure with a floor
2. Call detection proc from inside
3. Verify it returns the enclosed turfs
4. Test with gap in wall - should return null
5. Test with very large space - should return null

**Status:** [ ] Not Started / [ ] In Progress / [ ] Complete

---

## Step 11: Room Designator Tool

**Goal:** Allow players to create room areas.

**Files to create:**
- `code/modules/resurgence_outpost/rooms/room_designator.dm`
- `code/modules/resurgence_outpost/rooms/room_areas.dm`

**Implementation:**
- Handheld tool
- Uses room detection from Step 10
- Scans structures to determine room type
- Creates new area with appropriate modifiers

**Testing:**
1. Build enclosed space with crafting table inside
2. Use room designator
3. Verify Workshop area is created
4. Check area has correct faith_modifier (0.75)

**Status:** [ ] Not Started / [ ] In Progress / [ ] Complete

---

## Step 12: Production Speed Modifier

**Goal:** Make crafting take 3x longer outside workshops.

**Files to modify:**
- `code/modules/resurgence_outpost/structures/crafting_table.dm`
- `code/modules/resurgence_outpost/structures/forge.dm`
- `code/modules/resurgence_outpost/structures/loom.dm`

**Implementation:**
- Add `get_craft_time()` proc that checks area type
- Multiply time by 3 if not in Workshop

**Testing:**
1. Place crafting table outdoors, time a craft
2. Designate workshop around it
3. Time same craft - should be 3x faster

**Status:** [ ] Not Started / [ ] In Progress / [ ] Complete

---

## Step 13: Faith Clothing Component

**Goal:** Create component that adds faith bonus to any clothing.

**Files to create:**
- `code/modules/resurgence_outpost/clothing/faith_clothing_component.dm`

**Implementation:**
- Component that attaches to clothing items
- Registers signals for equip/unequip
- Adds/removes faith events on core

**Testing:**
1. Spawn a robe, manually add component with +5 faith
2. Equip robe on resurgence machine
3. Check core - should show +5 faith from clothing
4. Unequip - faith should return to normal

**Status:** [x] Complete

---

## Step 14: Loom Outfit Crafting

**Goal:** Allow loom to craft faith-boosting outfits.

**Files to modify:**
- `code/modules/resurgence_outpost/structures/loom.dm`

**Implementation:**
- Add outfit recipes using existing clothing types
- Create clothing item
- Attach faith component with appropriate bonus
- Rename to "clan-woven [name]"

**Testing:**
1. Craft White Robe at loom (8 cloth)
2. Verify "clan-woven white robe" is created
3. Equip on machine, verify +3 faith bonus
4. Test Bishop's Robes requiring woven tapestry

**Status:** [x] Complete

---

## Step 15: Wooden Spear

**Goal:** Create basic melee weapon with durability.

**Files to create:**
- `code/modules/resurgence_outpost/weapons/spear.dm`

**Implementation:**
- 2-tile reach melee weapon
- Durability that decreases on hit
- Breaks when durability reaches 0
- Examine shows condition

**Testing:**
1. Spawn wooden spear
2. Attack enemy from 2 tiles away - should hit
3. Check durability decreases
4. Use until broken

**Status:** [ ] Not Started / [ ] In Progress / [ ] Complete

---

## Step 16: Sling and Stones

**Goal:** Create basic ranged weapon with ammunition.

**Files to create:**
- `code/modules/resurgence_outpost/weapons/sling.dm`
- `code/modules/resurgence_outpost/weapons/ammo.dm`

**Implementation:**
- Sling weapon that uses stone ammo
- Load with stones via attackby
- Click target to fire projectile
- Fire delay between shots

**Testing:**
1. Spawn sling and sling stones
2. Load sling with stones
3. Click distant target to fire
4. Verify projectile hits and damages
5. Verify fire delay works

**Status:** [ ] Not Started / [ ] In Progress / [ ] Complete

---

## Step 17: Crossbow

**Goal:** Create advanced ranged weapon with cocking mechanic.

**Files to modify:**
- `code/modules/resurgence_outpost/weapons/ranged.dm` (or new file)

**Implementation:**
- Must be cocked before firing (click in hand)
- Load bolts via attackby
- Higher damage than sling

**Testing:**
1. Spawn crossbow and wooden bolts
2. Try to fire uncocked - should fail
3. Cock crossbow (click in hand)
4. Load bolt, fire at target
5. Verify damage is higher than sling

**Status:** [ ] Not Started / [ ] In Progress / [ ] Complete

---

## Step 18: Weapon Crafting Recipes

**Goal:** Add weapon recipes to crafting stations.

**Files to modify:**
- `code/modules/resurgence_outpost/structures/crafting_table.dm`
- `code/modules/resurgence_outpost/structures/forge.dm`

**Recipes:**
| Station | Output | Input |
|---------|--------|-------|
| Crafting Table | Wooden Spear | 3 Wood + 1 Stone |
| Crafting Table | Sling | 2 Leather Strip + 1 Rope |
| Crafting Table | 5 Wooden Bolts | 2 Wood |
| Forge | Metal Spear | 2 Wooden Plank + 1 Metal Rod + 1 Leather Strip |
| Forge | Crossbow | 3 Wooden Plank + 2 Metal Rod + 1 Gear Assembly + 2 Rope |
| Forge | 10 Metal Shot | 1 Metal Sheet |
| Forge | 5 Metal Bolts | 1 Wood + 1 Metal Rod |

**Testing:**
1. Craft each weapon at appropriate station
2. Verify all material costs are correct
3. Test crafted weapons work properly

**Status:** [ ] Not Started / [ ] In Progress / [ ] Complete

---

## Step 19: Monument of Hope

**Goal:** Create the central monument structure.

**Files to create:**
- `code/modules/resurgence_outpost/structures/monument.dm`

**Implementation:**
- 4-stage structure
- Accepts specific components per stage
- Tracks progress, announces stage completion
- Victory announcement on stage 4

**Testing:**
1. Spawn monument (stage 0)
2. Add required components for stage 1
3. Verify stage advances and announcement plays
4. Complete all 4 stages
5. Verify victory message

**Status:** [ ] Not Started / [ ] In Progress / [ ] Complete

---

## Step 20: Resource Gathering - Trees

**Goal:** Create choppable trees that drop wood.

**Files to create:**
- `code/modules/resurgence_outpost/resources/trees.dm`

**Implementation:**
- Tree structure with health
- Hit with axe/hatchet to chop
- Drops wood when felled
- Becomes stump, can regrow

**Testing:**
1. Spawn tree and hatchet
2. Chop tree repeatedly
3. Verify wood drops
4. Verify stump remains
5. Wait for regrowth (or speed up timer)

**Status:** [ ] Not Started / [ ] In Progress / [ ] Complete

---

## Step 21: Resource Gathering - Mining

**Goal:** Create mineable ore deposits.

**Files to create:**
- `code/modules/resurgence_outpost/resources/mining.dm`

**Implementation:**
- Rock turf or structure containing ore
- Hit with pickaxe to mine
- Drops ore when destroyed

**Testing:**
1. Spawn ore deposit and pickaxe
2. Mine deposit
3. Verify ore drops
4. Smelt ore at forge

**Status:** [ ] Not Started / [ ] In Progress / [ ] Complete

---

## Step 22: Resource Gathering - Fiber Plants

**Goal:** Create harvestable plants for cloth production.

**Files to create:**
- `code/modules/resurgence_outpost/resources/plants.dm`

**Implementation:**
- Plant structure that can be harvested
- Drops plant fiber
- Regrows after time

**Testing:**
1. Spawn fiber plant
2. Harvest by hand or with sickle
3. Verify fiber drops
4. Process fiber at loom
5. Use cloth in crafting

**Status:** [ ] Not Started / [ ] In Progress / [ ] Complete

---

## Step 23: Basic Tools

**Goal:** Create gathering tools (hatchet, pickaxe, shovel, sickle).

**Files to create:**
- `code/modules/resurgence_outpost/tools/gathering_tools.dm`

**Implementation:**
- Tools with durability
- Speed modifiers for gathering
- Can be crafted at crafting table

**Testing:**
1. Spawn each tool type
2. Use on appropriate resource
3. Verify durability decreases
4. Craft replacement tools

**Status:** [ ] Not Started / [ ] In Progress / [ ] Complete

---

## Step 24: Persistence - Save System

**Goal:** Save outpost state to DMM file at round end.

**Files to create:**
- `code/modules/resurgence_outpost/persistence/save.dm`

**Implementation:**
- Scan all tiles in outpost z-level
- Generate DMM format with object states
- Save to data folder
- Save metadata (day number, etc.) to JSON

**Testing:**
1. Build some structures
2. Trigger manual save
3. Verify DMM file is created
4. Open DMM in text editor, verify structure

**Status:** [ ] Not Started / [ ] In Progress / [ ] Complete

---

## Step 25: Persistence - Load System

**Goal:** Load saved outpost state at round start.

**Files to create:**
- `code/modules/resurgence_outpost/persistence/load.dm`

**Implementation:**
- Check for existing save file
- Load DMM if exists, else load base map
- Load metadata from JSON
- Announce day number

**Testing:**
1. Start round with no save - should load base map
2. Build structures, save, restart
3. Verify structures persist
4. Verify day counter increments

**Status:** [ ] Not Started / [ ] In Progress / [ ] Complete

---

## Step 26: Gamemode Shell

**Goal:** Create basic gamemode with round timer.

**Files to create:**
- `code/game/gamemodes/resurgence_outpost/resurgence_outpost.dm`

**Implementation:**
- 90-minute round timer
- Warnings at 15/5/1 minutes
- Trigger save on round end
- Victory condition (monument complete)

**Testing:**
1. Start gamemode
2. Verify timer appears
3. Complete monument - verify victory
4. Let timer run out - verify save triggers

**Status:** [ ] Not Started / [ ] In Progress / [ ] Complete

---

## Step 27: Map Creation

**Goal:** Create base outpost map.

**Files to create:**
- `_maps/resurgence_outpost/resurgence_outpost.dmm`

**Implementation:**
- Outdoor terrain with resources
- Starting area with basic supplies
- Monument spawn point
- Resource distribution

**Testing:**
1. Load map
2. Verify resources are present
3. Verify monument location
4. Play through resource gathering

**Status:** [ ] Not Started / [ ] In Progress / [ ] Complete

---

## Implementation Priority Order

**Phase 1 - Core Systems (Steps 1-3)**
- Faith events, core updates, components
- Foundation for everything else

**Phase 2 - Crafting Stations (Steps 4-6)**
- Crafting table, forge, loom
- Enables making things

**Phase 3 - Building System (Steps 7-9)**
- Blueprint planner and construction
- Enables base building

**Phase 4 - Room System (Steps 10-12)**
- Detection, designation, bonuses
- Adds strategic depth

**Phase 5 - Clothing (Steps 13-14)**
- Faith clothing system
- Loom outfit crafting

**Phase 6 - Weapons (Steps 15-18)**
- Spears, sling, crossbow
- Combat capability

**Phase 7 - Monument (Step 19)**
- Victory objective

**Phase 8 - Resource Gathering (Steps 20-23)**
- Trees, mining, plants, tools
- Self-sustaining gameplay

**Phase 9 - Persistence (Steps 24-25)**
- Save/load system
- Multi-round progression

**Phase 10 - Gamemode (Steps 26-27)**
- Full gamemode and map
- Complete experience

---

## Notes

- Each step can be tested in isolation using admin spawning
- Placeholder sprites are acceptable initially
- Focus on functionality before polish
- Update this document as steps are completed
