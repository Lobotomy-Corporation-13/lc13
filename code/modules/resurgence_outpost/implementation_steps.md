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

**Faith Event Design Guidelines:**

Faith event amounts should be balanced based on their duration:

| Event Duration | Faith Change | Examples |
|----------------|--------------|----------|
| Permanent/Long (>30 sec) | ≤ ±1 per tick | Room bonuses, worn clothing, nearby community |
| Short/Temporary (<30 sec) | Higher amounts | Eating meals (+5 to +18), contributing to monument (+15) |

**Rationale:**
- Long-duration events tick continuously, so small values (≤1) accumulate over time without overwhelming the system
- Short-duration events need larger values to have meaningful impact before expiring
- This prevents permanent bonuses from trivializing faith management while allowing impactful temporary boosts

**Testing:**
1. Compile - should have no errors
2. No in-game testing needed yet (this is a data structure)

**Status:** [x] Complete

---

## Step 2: Update Resurgence Core Organ

**Goal:** Faith-only resource system (charge system disabled but preserved).

**Files to modify:**
- `code/modules/surgery/organs/resurgence_core.dm`

**Changes:**
1. Faith is the only active resource
2. Charge system code commented out (preserved for potential future use)
3. Faith events system active
4. EMPs drain faith instead of charge
5. Work requires minimum 5 faith

**Testing:**
1. Spawn a resurgence machine mob
2. Use "Check Core Status" action - should show faith level
3. Verify faith changes over time based on events
4. Verify low faith (< 20) applies movement penalty

**Status:** [x] Complete (Updated to faith-only system)

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

**Status:** [x] Complete

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

**Status:** [x] Complete

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

**Status:** [x] Complete

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

**Status:** [x] Complete

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

**Status:** [x] Complete

---

## Step 12: Production Speed Modifier

**Goal:** Make crafting take 3x longer outside workshops, with portable variants that work anywhere.

**Files modified:**
- `code/modules/resurgence_outpost/structures/crafting_table.dm`
- `code/modules/resurgence_outpost/structures/forge.dm`
- `code/modules/resurgence_outpost/structures/loom.dm`

**Implementation:**
- Added `requires_workshop` variable (default TRUE) and `outdoor_penalty` (default 3x)
- Added `get_work_time()` proc that checks workshop status via `is_in_workshop()`
- Added `is_at_reduced_efficiency()` proc for UI feedback
- Examine text shows workshop status and efficiency
- Work session uses `get_work_time()` instead of fixed `WORK_SESSION_TIME`
- Created portable variants that don't require workshops:
  - `/obj/structure/resurgence_crafting_table/portable`
  - `/obj/structure/resurgence_crafting_table/forge/portable`
  - `/obj/structure/resurgence_crafting_table/loom/portable`

**Testing:**
1. Place crafting table outdoors, time a craft - should show "3x slower" warning
2. Designate workshop around it
3. Time same craft - should be 3x faster, shows "full speed" message
4. Place portable crafting table outdoors - should work at full speed

**Status:** [x] Complete

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

## Step 15: Room Ownership System

**Goal:** Allow players to claim rooms as their personal space.

**Files to create:**
- `code/modules/resurgence_outpost/rooms/room_ownership.dm`

**Implementation:**
- Add `owner_ckey` variable to room areas
- Add "Claim Room" option to room designator or separate claim marker item
- Only one room per player
- Track ownership in persistence system
- Faith events:
  - "Homeless" (-10 faith) if player has no claimed room
  - "Has Personal Room" (+5 faith) if player has a claimed room

**Key Logic:**
```dm
// On player spawn/load
/proc/check_room_ownership(mob/living/carbon/human/H)
    var/ckey = H.ckey
    // Check if this ckey owns any room
    for(var/area/resurgence_outpost/room/R in GLOB.resurgence_rooms)
        if(R.owner_ckey == ckey)
            // Has a room - add positive faith event
            add_faith_event(H, "room_ownership", "Has personal room", +5)
            return
    // No room - add negative faith event
    add_faith_event(H, "room_ownership", "Homeless", -10)
```

**Testing:**
1. Spawn as machine without a room, verify -10 faith "Homeless" event
2. Claim a room, verify faith event changes to +5 "Has Personal Room"
3. Verify room persists across rounds for that ckey
4. Verify another player cannot claim the same room

**Status:** [x] Complete

---

## Step 16: Room Quality (Beauty) System

**Goal:** Make room quality affect faith based on furniture beauty ratings and room size.

**Files to create:**
- `code/modules/resurgence_outpost/rooms/room_quality.dm`

**Files to reference:**
- `code/datums/components/beauty.dm`

**Implementation:**
- All furniture built via blueprints or crafting tables gets a beauty rating
- Room calculates total beauty of all furniture inside
- Beauty affects faith:
  - Positive beauty: Passive faith gain over time while in room
  - Negative beauty: Passive faith loss over time while in room
- Process() checks player location and applies faith modifier
- **Cramped Room Penalty:** Rooms with ≤10 free tiles OR width/height <3 tiles get "Cramped" debuff

**Beauty Ratings (examples):**
| Item | Base Beauty |
|------|-------------|
| Basic Wooden Chair | +2 |
| Wooden Table | +3 |
| Storage Chest | +1 |
| Bed | +5 |
| Lantern Post | +4 |
| Banner Stand | +6 |
| Small Statue | +10 |
| Carpet Floor | +1 per tile |
| Bare Floor | 0 |
| Rubble/Debris | -5 |

**Room Quality Levels:**
| Total Beauty | Level | Faith Effect |
|--------------|-------|--------------|
| 50+ | Luxurious | +0.5 faith/min |
| 30-49 | Comfortable | +0.3 faith/min |
| 10-29 | Adequate | +0.1 faith/min |
| 0-9 | Bare | No effect |
| -1 to -19 | Shabby | -0.1 faith/min |
| -20 or less | Squalid | -0.3 faith/min |

**Cramped Room Penalty:**
| Condition | Effect |
|-----------|--------|
| ≤10 free tiles | -5 faith event "Cramped Room" |
| Width or height <3 tiles | -5 faith event "Cramped Room" |
| Both conditions | -8 faith event "Very Cramped" |

**Common Room Eating Bonus:**
- Eating food in a Common Room grants +1 quality tier to the meal's faith effect
- Encourages communal dining rather than eating alone outdoors
- Common Room detected by having seating (chairs) and tables

**Testing:**
1. Build empty room, check beauty = 0, no faith effect
2. Add furniture, verify beauty increases
3. Stay in comfortable room, verify faith slowly increases
4. Add debris/garbage to room, verify beauty decreases
5. Stay in squalid room, verify faith slowly decreases
6. Build tiny 2x3 room, verify "Cramped Room" debuff appears
7. Build narrow 2x10 room, verify cramped debuff for width <3
8. Build 3x3 room (9 tiles), verify cramped debuff for ≤10 tiles
9. Build 4x4 room (16 tiles), verify no cramped debuff
10. Eat food outside, note faith bonus
11. Eat same quality food in Common Room, verify +1 quality tier bonus

**Status:** [x] Complete

---

## Step 17: Character Stats System

**Goal:** Add Rimworld-style stats that affect gameplay.

**Files to create:**
- `code/modules/resurgence_outpost/stats/character_stats.dm`
- `code/modules/resurgence_outpost/stats/stat_leveling.dm`

**Implementation:**
- Stats stored on the resurgence_core organ
- Three core stats:
  1. **Construction** - Affects blueprint building speed and beauty of built structures
  2. **Crafting** - Affects crafting speed and beauty of crafted items
  3. **Gathering** - Affects resource gathering speed and yield amount
- Stats range from 1-20
- Stats saved per ckey in persistence

**Stat Effects:**
| Stat | Level 1 Effect | Level 10 Effect | Level 20 Effect |
|------|----------------|-----------------|-----------------|
| Construction | 1.5x build time, -2 beauty | Normal | 0.5x build time, +5 beauty |
| Crafting | 1.5x craft time, -2 beauty | Normal | 0.5x craft time, +5 beauty |
| Gathering | 0.5x yield, 1.5x time | Normal | 1.5x yield, 0.5x time |

**Formula:**
```dm
// Speed modifier: 1.5 at level 1, 1.0 at level 10, 0.5 at level 20
var/speed_mod = 1.5 - (stat_level - 1) * (1.0 / 19)

// Yield modifier: 0.5 at level 1, 1.0 at level 10, 1.5 at level 20
var/yield_mod = 0.5 + (stat_level - 1) * (1.0 / 19)

// Beauty bonus: -2 at level 1, 0 at level 10, +5 at level 20
var/beauty_bonus = -2 + (stat_level - 1) * (7.0 / 19)
```

**Testing:**
1. Spawn with level 1 construction, verify building takes 1.5x normal time
2. Level up construction, verify speed improves
3. Build structure at level 20, verify +5 beauty bonus applied
4. Test all three stats affect their respective activities

**Status:** [x] Complete

---

## Step 18: Bed and Stat Leveling UI

**Goal:** Allow players to rest in beds to view and level up stats.

**Files to create:**
- `code/modules/resurgence_outpost/structures/bed.dm`
- `tgui/packages/tgui/interfaces/ResurgenceStats.tsx`

**Implementation:**
- Bed blueprint/structure
- Must be in player's owned room to use for stat leveling
- Clicking bed in owned room opens stat UI
- UI shows current stats and allows spending XP to level up
- XP earned by performing activities:
  - Building structures → Construction XP
  - Crafting items → Crafting XP
  - Gathering resources → Gathering XP

**XP Requirements:**
| Level | XP to Next Level |
|-------|------------------|
| 1→2 | 100 |
| 2→3 | 200 |
| 3→4 | 400 |
| ... | Doubles each level |
| 19→20 | 25600 |

**UI Mockup:**
```
┌─────────────────────────────────────────────────────┐
│  CHARACTER STATS                                [X] │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Construction: 5 ████████░░░░░░░░░░░░ (320/400 XP)  │
│    Build Speed: 1.26x | Beauty Bonus: +0            │
│                                                     │
│  Crafting: 8 ██████████████░░░░░░░░ (1100/1600 XP)  │
│    Craft Speed: 1.08x | Beauty Bonus: +2            │
│                                                     │
│  Gathering: 3 ████░░░░░░░░░░░░░░░░░░ (80/200 XP)    │
│    Yield: 0.71x | Gather Speed: 1.37x               │
│                                                     │
│  ─────────────────────────────────────────────────  │
│  Resting in your room. Stats will be saved.         │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Testing:**
1. Build bed in owned room
2. Click bed, verify stat UI opens
3. Perform construction, verify Construction XP gained
4. Level up stat, verify effects apply
5. Verify stats persist after using bed

**Status:** [x] Complete

---

## Step 19: Persistence - Player Data

**Goal:** Save room ownership and character stats per ckey.

**Files to modify:**
- `code/modules/resurgence_outpost/persistence/save.dm`
- `code/modules/resurgence_outpost/persistence/load.dm`

**Files to create:**
- `code/modules/resurgence_outpost/persistence/player_data.dm`

**Implementation:**
- Save player data to JSON file when they use a bed
- Load player data when they spawn
- Data includes:
  - ckey
  - owned_room_id (reference to area)
  - construction_level, construction_xp
  - crafting_level, crafting_xp
  - gathering_level, gathering_xp

**Save File:**
`data/resurgence_outpost/players/[ckey].json`
```json
{
  "ckey": "exampleplayer",
  "owned_room_id": "room_15",
  "stats": {
    "construction": { "level": 5, "xp": 320 },
    "crafting": { "level": 8, "xp": 1100 },
    "gathering": { "level": 3, "xp": 80 }
  },
  "last_save": "2024-01-15 14:30:00"
}
```

**Testing:**
1. Create character, claim room, level up stats
2. Use bed to save
3. Restart round, verify room ownership persists
4. Verify stats persist at saved values
5. Test with multiple players, verify each has separate save

**Status:** [ ] Not Started / [ ] In Progress / [ ] Complete

---

## Step 20: Resource Gathering - Extended System

**Goal:** Implement time-based gathering with interruptible progress.

**Files to create:**
- `code/modules/resurgence_outpost/resources/trees.dm`
- `code/modules/resurgence_outpost/resources/mining.dm`
- `code/modules/resurgence_outpost/resources/gathering_base.dm`

**Implementation:**
- Gathering takes significant time (e.g., 2.5 minutes for chopping a tree)
- Progress is saved on the resource if interrupted
- Multiple players can contribute to same resource
- Gathering stats affect speed and yield
- **Minimum 5 charge required to gather** - cannot gather below 5 charge
- **Work drains faith directly** - each work increment reduces faith by 0.1 (not via events)

**Example - Tree Chopping:**
- Base time: 150 seconds (2.5 minutes)
- Base yield: 45 wood
- Work points needed: 300 (at 2 per second)
- Gathering stat modifies both speed and yield
- Faith drain: ~30 faith over full tree (300 work × 0.1)

**Faith Drain from Work:**
| Activity | Faith Drain per Work Point |
|----------|---------------------------|
| Gathering | -0.1 faith |
| Crafting | -0.1 faith |
| Cooking | -0.1 faith |
| Construction | -0.1 faith |

This creates a need for rest, good meals, and comfortable rooms to restore faith.

**Key Logic:**
```dm
#define FAITH_DRAIN_PER_WORK 0.1

/obj/structure/resurgence_tree
    var/work_points = 0
    var/work_needed = 300
    var/base_yield = 45

/obj/structure/resurgence_tree/attackby(obj/item/I, mob/user)
    if(!is_axe(I))
        return ..()

    // Check charge requirement
    var/obj/item/organ/resurgence_core/core = user.getorganslot(ORGAN_SLOT_HEART)
    if(!istype(core) || core.charge < 5)
        to_chat(user, span_warning("You're too exhausted to gather resources. You need at least 5 charge."))
        return

    start_gathering(user, I)

/obj/structure/resurgence_tree/proc/start_gathering(mob/user, obj/item/tool)
    var/gather_stat = get_gathering_stat(user)
    var/speed_mod = get_speed_modifier(gather_stat)
    var/work_per_tick = 2 / speed_mod  // Higher stat = more work per tick

    while(work_points < work_needed)
        // Check charge each tick
        var/obj/item/organ/resurgence_core/core = user.getorganslot(ORGAN_SLOT_HEART)
        if(!istype(core) || core.charge < 5)
            to_chat(user, span_warning("You're too exhausted to continue."))
            break

        if(!do_after(user, 1 SECONDS, src))
            to_chat(user, span_notice("You stop chopping. Progress: [round(work_points/work_needed*100)]%"))
            break

        work_points += work_per_tick
        // Award gathering XP
        award_gathering_xp(user, work_per_tick)
        // Drain faith directly (not via events)
        core.adjust_faith(-FAITH_DRAIN_PER_WORK * work_per_tick)

    if(work_points >= work_needed)
        complete_gathering(user)
```

**Testing:**
1. Start chopping tree, interrupt partway, verify progress saved
2. Resume chopping, verify progress continues
3. Reduce charge below 5, verify cannot gather
4. Complete gathering, verify yield based on gathering stat
5. Test mining and other resource types similarly

**Status:** [X] Complete

---

## Step 21: Charge Requirement and Faith Drain for Crafting

**Goal:** Prevent crafting when charge is below 5, and drain faith during work.

**Files to modify:**
- `code/modules/resurgence_outpost/structures/crafting_table.dm`
- `code/modules/resurgence_outpost/structures/forge.dm`
- `code/modules/resurgence_outpost/structures/loom.dm`

**Implementation:**
- Check charge before starting any craft
- Stop auto-continue if charge drops below 5
- Display warning in UI when charge is low
- **Drain faith by 0.1 per work point** during crafting (same as gathering)

**Faith Drain Example:**
- Recipe with 20 total_work = 4 work sessions × 5 work per session
- Faith drain = 20 × 0.1 = -2 faith total

**Key Logic:**
```dm
// In continue_craft, after adding work points:
current_work += WORK_PER_SESSION
// Drain faith directly
var/obj/item/organ/resurgence_core/core = user.getorganslot(ORGAN_SLOT_HEART)
if(istype(core))
    core.adjust_faith(-FAITH_DRAIN_PER_WORK * WORK_PER_SESSION)
```

**Testing:**
1. Start crafting with full charge, verify works
2. Start crafting with charge < 5, verify blocked
3. Start batch craft, let charge drop below 5, verify stops
4. Craft item, verify faith decreases by ~0.1 per work point
5. Craft 20-work item, verify faith decreased by ~2

**Status:** [X] Complete

---

## Step 22: Cooking System

**Goal:** Allow players to cook meals that restore charge and provide faith bonuses.

**Files to create:**
- `code/modules/resurgence_outpost/structures/cooking_station.dm`
- `code/modules/resurgence_outpost/food/meal_component.dm`
- `code/modules/resurgence_outpost/food/recipes.dm`

**Implementation:**
- Cooking station structure (campfire, cooking pot, or stove)
- Uses same work-based crafting system as other stations
- Meals have a component storing quality and charge value
- When eaten:
  - Restore charge equal to meal's charge value
  - Add faith event based on meal quality
  - Faith events don't stack - highest quality takes priority
- Cooking stat (new stat) affects quality and speed

**Meal Quality Levels:**
| Quality | Faith Bonus | Duration |
|---------|-------------|----------|
| Awful | +0 | - |
| Poor | +2 | 5 min |
| Decent | +5 | 5 min |
| Good | +8 | 5 min |
| Excellent | +12 | 5 min |
| Masterwork | +18 | 5 min |

**Example Recipes:**
| Meal | Ingredients | Base Charge | Base Quality | Work |
|------|-------------|-------------|--------------|------|
| Roasted Meat | 1 Raw Meat | 15 | Decent | 10 |
| Grilled Vegetables | 2 Vegetables | 10 | Decent | 10 |
| Vegetable Stew | 2 Vegetables + 1 Water | 20 | Good | 20 |
| Meat Stew | 1 Raw Meat + 1 Vegetable + 1 Water | 25 | Good | 25 |
| Bread | 3 Wheat | 10 | Decent | 15 |
| Meat Pie | 1 Raw Meat + 2 Wheat | 30 | Good | 30 |
| Feast Plate | 2 Meat + 2 Vegetables + 1 Bread | 40 | Excellent | 50 |

**Quality Modifiers:**
- Cooking stat affects final quality (like Crafting stat for beauty)
- Cooking in proper Kitchen room: +1 quality tier
- Burnt/failed cook (interrupted early): -2 quality tiers

**Key Logic:**
```dm
/datum/component/resurgence_meal
    var/charge_value = 10
    var/quality = "decent"  // awful, poor, decent, good, excellent, masterwork
    var/faith_bonus = 5

/datum/component/resurgence_meal/proc/on_eat(mob/living/carbon/human/eater)
    var/obj/item/organ/resurgence_core/core = eater.getorganslot(ORGAN_SLOT_HEART)
    if(!istype(core))
        return

    // Restore charge
    core.adjust_charge(charge_value)
    to_chat(eater, span_notice("The meal restores [charge_value] charge."))

    // Add faith event (replaces lower quality meal events)
    var/datum/faith_event/meal/existing = core.get_faith_event_by_category("meal")
    if(existing && existing.faith_change >= faith_bonus)
        return  // Already have better meal event

    core.clear_faith_events_by_category("meal")
    core.add_faith_event(new /datum/faith_event/meal(quality, faith_bonus))
```

**Testing:**
1. Build cooking station
2. Cook raw meat, verify roasted meat is created with meal component
3. Eat meal, verify charge is restored
4. Verify faith event appears based on quality
5. Eat higher quality meal, verify faith event upgrades
6. Eat lower quality meal, verify faith event stays at higher level
7. Test cooking stat affects quality
8. Test Kitchen room bonus

**Status:** [ ] Not Started / [ ] In Progress / [ ] Complete

---

## Step 23: Cotton Plants

**Goal:** Create harvestable cotton plants for cloth production.

**Files created:**
- `code/modules/resurgence_outpost/resources/cotton.dm`

**Implementation:**
- Cotton plant structure with work-based harvesting
- Growth stage system (seedling → growing → maturing → harvest → dead)
- Uses icon states from `icons/obj/hydroponics/growing.dmi`:
  - cotton-grow1, cotton-grow2, cotton-grow3, cotton-harvest, cotton-dead
- Drops cotton sheets which can be processed at the loom
- Regular cotton plants regrow after harvest (1 minute per growth stage)
- Wild cotton plants die after harvest (non-renewable)
- Large cotton variant with more yield but slower growth
- Follows same work-based progress system as other gathering

**Variants:**
| Type | Base Yield | Work Needed | Growth Time | Regrows? |
|------|------------|-------------|-------------|----------|
| Regular | 5 | 60 | 1 min/stage | Yes |
| Wild | 3 | 40 | - | No (dies) |
| Large | 8 | 80 | 1.5 min/stage | Yes |

**Testing:**
1. Spawn cotton plant
2. Harvest by hand (no tool required)
3. Verify cotton drops
4. Check growth stage icons change correctly
5. Wait for regrowth, verify plant becomes harvestable again
6. Test wild cotton dies after harvest
7. Process cotton at loom
8. Use cloth in crafting

**Status:** [x] Complete

---

## Step 24: Basic Tools with Durability

**Goal:** Create gathering tools (hatchet, pickaxe, shovel).

**Files to create:**
- `code/modules/resurgence_outpost/tools/gathering_tools.dm`

**Implementation:**
- Tools with durability
- Speed modifiers for gathering
- Can be crafted at crafting table
- Note: Cotton is harvested by hand, no sickle needed

**Testing:**
1. Spawn each tool type
2. Use on appropriate resource
3. Verify durability decreases
4. Craft replacement tools

**Status:** [ ] Not Started / [ ] In Progress / [ ] Complete

---

## Step 25: Beauty System for Crafted Items

**Goal:** Apply beauty ratings to all crafted/built items.

**Files to modify:**
- `code/modules/resurgence_outpost/structures/crafting_table.dm`
- `code/modules/resurgence_outpost/blueprints/blueprint_base.dm`

**Implementation:**
- All recipes have base_beauty value
- When item is created, apply beauty component
- Beauty = base_beauty + crafter's stat bonus
- Examine shows beauty rating

**Testing:**
1. Craft item at level 1, verify beauty is base - 2
2. Craft same item at level 20, verify beauty is base + 5
3. Place items in room, verify room quality updates
4. Build via blueprint, verify builder's construction stat applies

**Status:** [ ] Not Started / [ ] In Progress / [ ] Complete

---

## Step 26: Persistence - Save System

**Goal:** Save outpost state to DMM file at round end.

**Files to create:**
- `code/modules/resurgence_outpost/persistence/save.dm`

**Implementation:**
- Scan all tiles in outpost z-level
- Generate DMM format with object states
- Save to data folder
- Save metadata (day number, etc.) to JSON
- Save room ownership data

**Testing:**
1. Build some structures
2. Trigger manual save
3. Verify DMM file is created
4. Open DMM in text editor, verify structure

**Status:** [ ] Not Started / [ ] In Progress / [ ] Complete

---

## Step 27: Persistence - Load System

**Goal:** Load saved outpost state at round start.

**Files to create:**
- `code/modules/resurgence_outpost/persistence/load.dm`

**Implementation:**
- Check for existing save file
- Load DMM if exists, else load base map
- Load metadata from JSON
- Announce day number
- Restore room ownership from saved data

**Testing:**
1. Start round with no save - should load base map
2. Build structures, save, restart
3. Verify structures persist
4. Verify day counter increments
5. Verify room ownership persists

**Status:** [ ] Not Started / [ ] In Progress / [ ] Complete

---

## Step 28: Gamemode Shell

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

## Step 29: Map Creation

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

## Step 30: Harvester Tool

**Goal:** Create automated harvesting tools that can gather resources while the player does other tasks.

**Files to create:**
- `code/modules/resurgence_outpost/tools/harvester.dm`

**Overview:**
Two variants of the Harvester tool:
1. **Simple Harvester** - Attaches to a single resource, harvests it, then drops to ground
2. **Advanced Harvester** - Stores faith, after finishing seeks nearby same-type resources (3 tile range)

**Simple Harvester Implementation:**
```dm
/obj/item/resurgence_harvester
    name = "harvester"
    desc = "A mechanical device that can be attached to resources to automatically harvest them."
    // Attach to: mining turfs, trees, cotton plants, farm plots
    // Faith cost: Depends on source type (based on work_needed of target)
    // Speed: Same as manual harvesting
    // Reusable: Yes (unlimited uses)
    // On destruction while working: Drops + partial faith refund

/obj/item/resurgence_harvester/proc/attach_to(atom/target, mob/user)
    // Validate target is harvestable
    // Calculate faith cost based on target's work_needed
    // Deduct faith from user's core
    // Begin automated harvesting process
    // When complete: detach and drop to ground

/obj/item/resurgence_harvester/proc/process_harvest()
    // Runs on a timer, adds work_points like manual harvesting
    // Same speed as player harvesting (GATHER_WORK_PER_TICK)
    // No faith drain during harvest (paid upfront)
```

**Advanced Harvester Implementation:**
```dm
/obj/item/resurgence_harvester/advanced
    name = "advanced harvester"
    desc = "An upgraded harvester that can store faith and automatically seek nearby resources."
    var/stored_faith = 0
    var/max_faith = 100
    var/search_range = 3  // tiles

/obj/item/resurgence_harvester/advanced/proc/load_faith(mob/user, amount)
    // Transfer faith from user to harvester storage

/obj/item/resurgence_harvester/advanced/proc/seek_next_target()
    // After completing current harvest:
    // Search within 3 tiles for same-type harvestable
    // Mining -> other mining turfs (same ore type)
    // Trees -> other trees
    // Cotton -> other cotton plants
    // Farm plots -> other plots in same zone
    // If found and has enough stored faith: move and attach
    // If not found or out of faith: drop to ground
```

**Faith Costs (based on target work_needed):**
| Target Type | Base Work | Faith Cost |
|-------------|-----------|------------|
| Mining (ore) | 30-50 | 3-5 |
| Tree | 40 | 4 |
| Cotton | 20 | 2 |
| Farm Plot | varies by yield | yield * 1 |

**Crafting Recipes:**
- Simple Harvester: 5 Metal + 3 Wood + 1 Rope (at Crafting Table)
- Advanced Harvester: 1 Simple Harvester + 5 Metal + 2 Silver (at Forge)

**Valid Targets:**
- `/turf/closed/mineral/resurgence` (mining)
- `/obj/structure/resurgence_tree` (trees)
- `/obj/structure/resurgence_cotton` (cotton)
- `/obj/structure/farm_plot` (farming)

**Behavior on Destruction:**
- If attacked/destroyed while harvesting
- Drops the harvester item
- Refunds remaining faith (proportional to work not completed)

**Testing:**
1. Craft Simple Harvester at crafting table
2. Attach to tree - verify faith is deducted
3. Wait for harvest completion - verify drops and item falls
4. Pick up and reuse on mining node
5. Craft Advanced Harvester at forge
6. Load faith into advanced harvester
7. Attach to mining node near other nodes
8. Verify it moves to next node after completing first
9. Attack harvester while working - verify drop + partial refund

**Status:** [X] Complete

---

## DEPRIORITIZED - Combat Features

The following steps are deprioritized to focus on basebuilding and living systems first. Implement after core living systems are complete.

### Step D1: Wooden Spear (DEPRIORITIZED)

**Goal:** Create basic melee weapon with durability.

**Files to create:**
- `code/modules/resurgence_outpost/weapons/spear.dm`

**Implementation:**
- 2-tile reach melee weapon
- Durability that decreases on hit
- Breaks when durability reaches 0
- Examine shows condition

**Status:** [ ] Deprioritized

---

### Step D2: Sling and Stones (DEPRIORITIZED)

**Goal:** Create basic ranged weapon with ammunition.

**Files to create:**
- `code/modules/resurgence_outpost/weapons/sling.dm`
- `code/modules/resurgence_outpost/weapons/ammo.dm`

**Status:** [ ] Deprioritized

---

### Step D3: Crossbow (DEPRIORITIZED)

**Goal:** Create advanced ranged weapon with cocking mechanic.

**Status:** [ ] Deprioritized

---

### Step D4: Weapon Crafting Recipes (DEPRIORITIZED)

**Goal:** Add weapon recipes to crafting stations.

**Status:** [ ] Deprioritized

---

### Step D5: Monument of Hope (DEPRIORITIZED)

**Goal:** Create the central monument structure.

**Note:** The monument is the victory condition but is deprioritized since it requires combat progression. Focus on living systems first.

**Status:** [ ] Deprioritized

---

## Implementation Priority Order

**Phase 1 - Core Systems (Steps 1-3)** ✓
- Faith events, core updates, components
- Foundation for everything else

**Phase 2 - Crafting Stations (Steps 4-6)** ✓
- Crafting table, forge, loom
- Enables making things

**Phase 3 - Building System (Steps 7-9)** ✓
- Blueprint planner and construction
- Enables base building

**Phase 4 - Room System (Steps 10-12)**
- Detection, designation, bonuses
- Adds strategic depth

**Phase 5 - Clothing (Steps 13-14)** ✓
- Faith clothing system
- Loom outfit crafting

**Phase 6 - Living Systems (Steps 15-19)** ← CURRENT PRIORITY
- Room Ownership (Step 15)
- Room Quality/Beauty (Step 16)
- Character Stats (Step 17)
- Bed & Stat Leveling (Step 18)
- Player Data Persistence (Step 19)

**Phase 7 - Resource & Survival (Steps 20-25, 30)**
- Extended gathering with progress saving (Step 20)
- Faith requirements (Step 21) - Updated: charge system disabled
- Cooking system for faith restoration (Step 22)
- Cotton plants for cloth production (Step 23) ✓
- Tools with durability (Step 24)
- Beauty for crafted items (Step 25)
- Harvester tool for automated gathering (Step 30)

**Phase 8 - Persistence (Steps 26-27)**
- Save/load system
- Multi-round progression

**Phase 9 - Gamemode (Steps 28-29)**
- Full gamemode and map
- Complete experience

**Phase 10 - Combat (Steps D1-D5)** ← DEPRIORITIZED
- Weapons (spears, sling, crossbow)
- Monument victory objective

---

## Notes

- Each step can be tested in isolation using admin spawning
- Placeholder sprites are acceptable initially
- Focus on functionality before polish
- Update this document as steps are completed
- Combat features can be added later once living systems are solid
