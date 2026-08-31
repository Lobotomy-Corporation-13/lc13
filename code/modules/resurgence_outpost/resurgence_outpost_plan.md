# Resurgence Outpost - Simplified Core Mechanics Plan

## Overview

Focus on basic survival building mechanics first. Players gather resources, build structures, complete building objectives, and export resources to the Historian's village.

---

## Faith & Charge System (Machine Resources)

Machines have two core resources managed by their resurgence_core organ.

**References (TGStation Mood System):**
- https://github.com/tgstation/tgstation/blob/master/code/datums/mood.dm
- https://github.com/tgstation/tgstation/blob/master/code/datums/mood_events/_mood_event.dm

### Faith (Mood-Based)
Faith is calculated from mood events, similar to TGStation's mood system.

**Structure:**
```dm
/datum/faith_event
    var/description          // Text shown to player
    var/faith_change         // How much this affects faith (-/+)
    var/timeout              // Duration before event expires (null = permanent until cleared)
    var/category             // Category key - only one event per category
    var/hidden = FALSE       // If true, not shown in faith check
```

**Faith Calculation:**
- Sum all active faith_event `faith_change` values
- Clamp result to 0-100
- Update faith level every life tick

**Faith Levels:**
| Range | Level | Effect |
|-------|-------|--------|
| 80-100 | Inspired | Charge decays 50% slower |
| 60-79 | Steady | Charge decays 25% slower |
| 40-59 | Neutral | Normal charge decay |
| 20-39 | Wavering | Charge decays 25% faster |
| 0-19 | Despairing | Charge decays 50% faster, movement penalty |

**Example Faith Events:**
| Event | Faith Change | Timeout | Category |
|-------|--------------|---------|----------|
| Objective completed | +1/5sec | 5 min | "objective_completion" |
| Near other machines | +5 | While nearby | "community" |
| Ate/recharged | +3 | 3 min | "sustenance" |
| Witnessed death | -20 | 10 min | "death" |
| Injured | -5 | Until healed | "injury" |
| In completed shelter | +5 | While inside | "shelter" |

**Faith Event Design Guidelines:**

Faith event amounts should be balanced based on their duration:

| Event Duration | Faith Change | Examples |
|----------------|--------------|----------|
| Permanent/Long (>30 sec) | ≤ ±1 per tick | Room bonuses, worn clothing, nearby community |
| Short/Temporary (<30 sec) | Higher amounts | Eating meals (+5 to +18), objective completion (+1/5sec for 5min) |

**Rationale:**
- Long-duration events tick continuously, so small values (≤1) accumulate over time without overwhelming the system
- Short-duration events need larger values to have meaningful impact before expiring
- This prevents permanent bonuses from trivializing faith management while allowing impactful temporary boosts

### Charge System (DISABLED)
The charge system has been disabled to simplify gameplay. Only faith is used as a resource.
The charge code is preserved (commented out) for potential future re-activation.

**Current system:**
- Faith is the only active resource
- Work (gathering, harvesting) requires minimum 5 faith
- EMPs drain faith instead of charge
- Low faith (< 20) applies movement penalty

### Updated Core Procs (Faith-Only)
```dm
/obj/item/organ/resurgence_core
    // Charge variables (DISABLED)
    // var/charge = 100
    // var/max_charge = 100
    // var/charge_decay_rate = 0.5

    var/faith = 50              // Current faith level
    var/max_faith = 100
    var/list/faith_events = list()  // category -> /datum/faith_event

/obj/item/organ/resurgence_core/proc/add_faith_event(category, datum/faith_event/event)
    // Replace existing event in same category
    if(faith_events[category])
        qdel(faith_events[category])
    faith_events[category] = event
    recalculate_faith_rate()

/obj/item/organ/resurgence_core/proc/clear_faith_event(category)
    if(faith_events[category])
        qdel(faith_events[category])
        faith_events -= category
    recalculate_faith_rate()

/obj/item/organ/resurgence_core/proc/adjust_faith(amount)
    faith = clamp(faith + amount, 0, max_faith)
```

---

## Core Resources (Use Existing SS13 Materials)

| Resource | Source | Use |
|----------|--------|-----|
| Iron Ore | Mining rocks | Smelt to metal sheets |
| Metal Sheets | Smelted iron | Walls, floors, structures |
| Wood | Trees/logs | Basic structures, fuel |
| Glass | Sand/smelting | Windows |
| Plasteel | Advanced crafting | Late-game structures |

No new resources needed - leverage existing `/obj/item/stack/sheet/` types.

---

## Resource Gathering

### Wood
**Source:** Trees scattered around the map

```dm
/obj/structure/flora/tree/resurgence
    name = "outskirts tree"
    desc = "A gnarled tree that has adapted to the harsh outskirts."
    icon_state = "tree_outskirts"
    var/wood_amount = 10        // Wood dropped when chopped
    var/chop_time = 40          // Deciseconds per chop
    var/health = 3              // Chops required to fell
```

**Gathering:**
1. Hit tree with hatchet/axe → `do_after()` chop animation
2. Each chop reduces `health` by 1
3. When `health` reaches 0 → tree falls, drops wood, becomes stump
4. Stumps can regrow over time (configurable, e.g., 10 minutes)

**Tools:**
| Tool | Chop Speed | Durability |
|------|------------|------------|
| Bare hands | Very slow (x3 time) | N/A |
| Stone Hatchet | Normal | 50 uses |
| Metal Axe | Fast (x0.5 time) | 150 uses |

### Iron/Metal
**Source:** Ore deposits in rock formations

```dm
/turf/closed/mineral/random/resurgence
    name = "rock face"
    desc = "A rocky outcropping. Might contain ore."
    var/ore_type = null         // Set on init
    var/ore_amount = 3          // Ore dropped when mined

/turf/closed/mineral/random/resurgence/iron
    ore_type = /obj/item/stack/ore/iron
    mineralChance = 100
```

**Gathering:**
1. Hit rock with pickaxe → mining animation
2. Rock breaks → drops ore + becomes open turf or rubble
3. Ore must be smelted at Forge to become metal sheets

**Smelting (at Forge):**
| Input | Output |
|-------|--------|
| 2 Iron Ore | 1 Metal Sheet |
| 1 Iron Ore + 1 Coal | 2 Metal Sheets (efficient) |

**Tools:**
| Tool | Mine Speed | Durability |
|------|------------|------------|
| Bare hands | Cannot mine | N/A |
| Stone Pickaxe | Slow | 30 uses |
| Metal Pickaxe | Normal | 100 uses |

### Glass
**Source:** Sand deposits + smelting

```dm
/obj/item/stack/ore/sand
    name = "sand"
    desc = "Coarse sand from the outskirts."
    icon_state = "ite_ore"  // Placeholder
    refined_type = /obj/item/stack/sheet/glass

/turf/open/floor/resurgence/sand
    name = "sandy ground"
    desc = "Loose sand covers the ground here."
    var/sand_remaining = 5
```

**Gathering:**
1. Use shovel on sandy ground → get sand pile
2. Each dig reduces `sand_remaining`
3. When depleted, turf becomes regular dirt (can regenerate)

**Smelting (at Forge):**
| Input | Output |
|-------|--------|
| 2 Sand | 1 Glass Sheet |

### Cloth
**Source:** Cotton → Loom processing

Cotton is obtained directly from cotton plants found in the world. No intermediate processing needed.

**Gathering:**
1. Harvest cotton plants by hand
2. Plants regrow after 5 minutes

**Processing (at Loom):**
| Input | Output |
|-------|--------|
| 3 Cotton | 1 Cloth |

### Resource Summary

| Resource | Raw Source | Processing | Station |
|----------|------------|------------|---------|
| Wood | Trees (chop) | None | - |
| Metal | Iron Ore (mine) | Smelt | Forge |
| Glass | Sand (dig) | Smelt | Forge |
| Cloth | Cotton Plants (harvest) | Weave | Loom |

### Starting Tools

Players spawn with basic tools or can craft them:

**Craftable Without Station:**
| Tool | Recipe | Use |
|------|--------|-----|
| Stone Hatchet | 2 wood + 1 stone | Chop trees |
| Stone Pickaxe | 2 wood + 2 stone | Mine ore |
| Shovel | 3 wood + 1 metal | Dig sand |

**Stone Source:**
- Small rocks scattered on ground (pick up)
- Breaking rubble/boulders

### Resource Regeneration

To prevent resource depletion over multi-day progression:

| Resource | Regeneration |
|----------|--------------|
| Trees | Stumps regrow in 10 min (configurable) |
| Ore | New deposits spawn at round start from base map |
| Sand | Sandy turfs regenerate 1 sand per 5 min |
| Cotton Plants | Regrow 5 min after harvest |

---

## Building System

There are three ways to build/craft items:

1. **Blueprints** - For anchored structures (walls, doors, stations). Place ghost → add materials → build.
2. **Crafting Table** - For portable items and decor. Select recipe → craft → pickup item.
3. **Floor Tiles** - For flooring. Craft tiles at table → place directly on ground.

### Blueprint Structures (Anchored, placed via Blueprint Planner)

**Construction:**
| Structure | Materials | Description |
|-----------|-----------|-------------|
| Wood Wall | 5 wood | Basic wall, blocks movement |
| Wood Door | 8 wood | Openable passage |
| Window | 4 wood + 2 glass | Wall with visibility |

**Storage:**
| Structure | Materials | Description |
|-----------|-----------|-------------|
| Storage Chest | 10 wood | Container for items |
| Crate | 8 wood | Larger container |
| Barrel | 6 wood | Stores liquids/bulk items |

**Production:**
| Structure | Materials | Description |
|-----------|-----------|-------------|
| Crafting Table | 15 wood | Basic crafting station |
| Research Table | 20 wood + 5 glass | Unlocks new blueprints |
| Forge | 25 metal + 10 wood | Metalworking station |
| Loom | 20 wood | Textile crafting |

**Decor (Anchored):**
| Structure | Materials | Description |
|-----------|-----------|-------------|
| Lantern Post | 5 wood + 3 glass | Standing light source, +2 faith |
| Banner Stand | 8 cloth + 2 wood | Anchored clan banner, +3 faith |

### Crafting Table Items (Portable, crafted as items)

**Floor Tiles** (place directly on ground after crafting):
| Item | Materials | Output | Description |
|------|-----------|--------|-------------|
| Wood Floor Tiles | 1 wood | 4 tiles | Uses `/obj/item/stack/tile/wood` |
| Carpet Tiles | 2 cloth | 4 tiles | Uses `/obj/item/stack/tile/carpet` |

**Decor Items** (portable, can be picked up and moved):
| Item | Materials | Description |
|------|-----------|-------------|
| Carving Block | 10 wood | Customizable statue, `/obj/structure/statue` |
| Canvas | 5 wood + 3 cloth | For painting, `/obj/item/canvas` |
| Easel | 8 wood | Holds canvas, `/obj/structure/easel` |
| Small Statue | 15 wood OR 15 metal | Decorative, +5 faith nearby |
| Lantern (handheld) | 3 wood + 2 glass | Portable light source |

**Reference:**
- Tiles: `code/game/objects/items/stacks/tiles/tile_types.dm`
- Statues: `code/game/objects/structures/statues.dm`
- Canvas/Easel: `code/game/objects/structures/artstuff.dm`

### Blueprint Planning Tool

A handheld tool that lets players plan construction by placing transparent "ghost" versions of structures.

**Tool:** `/obj/item/blueprint_planner`
```dm
/obj/item/blueprint_planner
    name = "blueprint planner"
    desc = "A planning tool for laying out construction blueprints."
    icon_state = "blueprint_tool"
    var/selected_structure = null  // Currently selected blueprint type
    var/selected_category = null   // Currently viewed category
```

**Usage:**
1. **Open UI**: Click tool in hand → opens category-based selection UI
2. **Select category**: Click a category tab (Construction, Decor, Production, Storage)
3. **Select structure**: Click a structure within the category
4. **Place blueprint**: Click on ground → places transparent blue ghost
5. **Rotate**: Alt-click blueprint to rotate
6. **Remove**: Right-click blueprint to remove (or hit with empty hand)
7. **Build**: Hit blueprint with required materials → starts construction

### Blueprint Categories

**Category Definitions:**
```dm
#define BLUEPRINT_CAT_CONSTRUCTION "Construction"
#define BLUEPRINT_CAT_STORAGE "Storage"
#define BLUEPRINT_CAT_PRODUCTION "Production"
#define BLUEPRINT_CAT_DECOR "Decor"

GLOBAL_LIST_INIT(blueprint_categories, list(
    BLUEPRINT_CAT_CONSTRUCTION = list(
        /obj/structure/blueprint/wood_wall,
        /obj/structure/blueprint/wood_door,
        /obj/structure/blueprint/window
    ),
    BLUEPRINT_CAT_STORAGE = list(
        /obj/structure/blueprint/chest,
        /obj/structure/blueprint/crate,
        /obj/structure/blueprint/barrel
    ),
    BLUEPRINT_CAT_PRODUCTION = list(
        /obj/structure/blueprint/crafting_table,
        /obj/structure/blueprint/research_table,
        /obj/structure/blueprint/forge,
        /obj/structure/blueprint/loom
    ),
    BLUEPRINT_CAT_DECOR = list(
        /obj/structure/blueprint/lantern_post,
        /obj/structure/blueprint/banner_stand
    )
))

// Note: Floors, carving blocks, canvases, and portable decor are crafted
// at the Crafting Table as items, not placed via blueprints.
```

### Blueprint Planner UI (TGUI)

**File:** `tgui/packages/tgui/interfaces/BlueprintPlanner.tsx`

```
┌─────────────────────────────────────────────────────┐
│  BLUEPRINT PLANNER                              [X] │
├─────────────────────────────────────────────────────┤
│  [Construction] [Storage] [Production] [Decor]      │  ← Category tabs
├─────────────────────────────────────────────────────┤
│                                                     │
│   ┌───────┐  ┌───────┐  ┌───────┐                  │
│   │ Wood  │  │ Wood  │  │Window │                  │
│   │ Wall  │  │ Door  │  │       │                  │
│   │  5🪵  │  │  8🪵  │  │ 4🪵2⬜│                  │  ← Structure icons
│   └───────┘  └───────┘  └───────┘                  │     with costs
│                                                     │
│   Selected: Wood Wall                               │
│   Cost: 5 Wood                                      │
│   Click on ground to place blueprint.               │
│                                                     │
│   Note: Floors are crafted as tiles at the          │
│   Crafting Table, then placed directly.             │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**UI Data Structure:**
```dm
/obj/item/blueprint_planner/ui_data(mob/user)
    var/list/data = list()
    data["categories"] = list()
    for(var/cat_name in GLOB.blueprint_categories)
        var/list/cat_data = list("name" = cat_name, "structures" = list())
        for(var/blueprint_type in GLOB.blueprint_categories[cat_name])
            var/obj/structure/blueprint/B = blueprint_type
            cat_data["structures"] += list(list(
                "name" = initial(B.name),
                "icon" = initial(B.icon_state),
                "type" = "[blueprint_type]",
                "materials" = get_material_list(B)
            ))
        data["categories"] += list(cat_data)
    data["selected"] = selected_structure ? "[selected_structure]" : null
    data["selected_category"] = selected_category
    return data

/obj/item/blueprint_planner/ui_act(action, params)
    . = ..()
    switch(action)
        if("select_category")
            selected_category = params["category"]
            return TRUE
        if("select_structure")
            selected_structure = text2path(params["type"])
            return TRUE
```

### Blueprint Structure (Ghost)

```dm
/obj/structure/blueprint
    name = "blueprint"
    desc = "A planned construction. Supply materials to build."
    icon_state = "blueprint_wall"
    anchored = TRUE
    density = FALSE           // Can walk through blueprints
    alpha = 128               // Semi-transparent
    color = "#4488ff"         // Blue tint

    var/list/required_materials = list()  // What's needed to build
    var/list/current_materials = list()   // What's been added
    var/build_result = null               // What gets created when complete
    var/build_time = 30                   // Deciseconds to build after materials supplied

/obj/structure/blueprint/examine(mob/user)
    . = ..()
    . += "Required materials:"
    for(var/mat_type in required_materials)
        var/needed = required_materials[mat_type]
        var/have = current_materials[mat_type] || 0
        var/obj/item/stack/S = mat_type
        . += "- [initial(S.name)]: [have]/[needed]"

/obj/structure/blueprint/attackby(obj/item/I, mob/user, params)
    if(istype(I, /obj/item/stack))
        var/obj/item/stack/S = I
        for(var/mat_type in required_materials)
            if(istype(S, mat_type))
                var/needed = required_materials[mat_type] - (current_materials[mat_type] || 0)
                if(needed > 0)
                    var/to_use = min(S.amount, needed)
                    S.use(to_use)
                    current_materials[mat_type] = (current_materials[mat_type] || 0) + to_use
                    to_chat(user, "<span class='notice'>You add [to_use] [S.singular_name] to the blueprint.</span>")
                    check_completion(user)
                    return
    ..()

/obj/structure/blueprint/proc/check_completion(mob/user)
    for(var/mat_type in required_materials)
        if((current_materials[mat_type] || 0) < required_materials[mat_type])
            return  // Not complete yet
    // All materials supplied - start building
    start_construction(user)

/obj/structure/blueprint/proc/start_construction(mob/user)
    to_chat(user, "<span class='notice'>You begin constructing the [name]...</span>")
    if(do_after(user, build_time, src))
        complete_construction()

/obj/structure/blueprint/proc/complete_construction()
    var/turf/T = get_turf(src)
    new build_result(T)
    playsound(T, 'sound/items/deconstruct.ogg', 50, TRUE)
    qdel(src)
```

### Blueprint Subtypes

**Important:** Blueprints are NOT subtypes of the objects they build. They are all subtypes of `/obj/structure/blueprint` with a `build_result` variable that points to the linked object type.

```dm
// All blueprints inherit from base blueprint structure
/obj/structure/blueprint
    // ... base vars defined above ...

// === CONSTRUCTION ===

// Wood Wall Blueprint
/obj/structure/blueprint/wood_wall
    name = "wood wall blueprint"
    icon_state = "blueprint_wall"
    required_materials = list(/obj/item/stack/sheet/mineral/wood = 5)
    build_result = /turf/closed/wall/resurgence/wood
    build_time = 50

// Wood Door Blueprint
/obj/structure/blueprint/wood_door
    name = "wood door blueprint"
    icon_state = "blueprint_door"
    required_materials = list(/obj/item/stack/sheet/mineral/wood = 8)
    build_result = /obj/machinery/door/resurgence/wood
    build_time = 60

// Window Blueprint
/obj/structure/blueprint/window
    name = "window blueprint"
    icon_state = "blueprint_window"
    required_materials = list(
        /obj/item/stack/sheet/mineral/wood = 4,
        /obj/item/stack/sheet/glass = 2
    )
    build_result = /obj/structure/window/resurgence
    build_time = 50

// === STORAGE ===

// Storage Chest Blueprint
/obj/structure/blueprint/chest
    name = "storage chest blueprint"
    icon_state = "blueprint_chest"
    required_materials = list(/obj/item/stack/sheet/mineral/wood = 10)
    build_result = /obj/structure/closet/crate/resurgence_chest
    build_time = 40

// Crate Blueprint
/obj/structure/blueprint/crate
    name = "crate blueprint"
    icon_state = "blueprint_crate"
    required_materials = list(/obj/item/stack/sheet/mineral/wood = 8)
    build_result = /obj/structure/closet/crate/resurgence_crate
    build_time = 35

// Barrel Blueprint
/obj/structure/blueprint/barrel
    name = "barrel blueprint"
    icon_state = "blueprint_barrel"
    required_materials = list(/obj/item/stack/sheet/mineral/wood = 6)
    build_result = /obj/structure/closet/crate/resurgence_barrel
    build_time = 30

// === PRODUCTION ===

// Crafting Table Blueprint
/obj/structure/blueprint/crafting_table
    name = "crafting table blueprint"
    icon_state = "blueprint_table"
    required_materials = list(/obj/item/stack/sheet/mineral/wood = 15)
    build_result = /obj/structure/resurgence_crafting_table
    build_time = 50

// Research Table Blueprint
/obj/structure/blueprint/research_table
    name = "research table blueprint"
    icon_state = "blueprint_research"
    required_materials = list(
        /obj/item/stack/sheet/mineral/wood = 20,
        /obj/item/stack/sheet/glass = 5
    )
    build_result = /obj/structure/resurgence_research_table
    build_time = 70

// Forge Blueprint
/obj/structure/blueprint/forge
    name = "forge blueprint"
    icon_state = "blueprint_forge"
    required_materials = list(
        /obj/item/stack/sheet/metal = 25,
        /obj/item/stack/sheet/mineral/wood = 10
    )
    build_result = /obj/structure/resurgence_forge
    build_time = 100

// Loom Blueprint
/obj/structure/blueprint/loom
    name = "loom blueprint"
    icon_state = "blueprint_loom"
    required_materials = list(/obj/item/stack/sheet/mineral/wood = 20)
    build_result = /obj/structure/resurgence_loom
    build_time = 60

// === DECOR (Anchored) ===

// Lantern Post Blueprint (anchored standing lantern)
/obj/structure/blueprint/lantern_post
    name = "lantern post blueprint"
    icon_state = "blueprint_lantern"
    required_materials = list(
        /obj/item/stack/sheet/mineral/wood = 5,
        /obj/item/stack/sheet/glass = 3
    )
    build_result = /obj/structure/resurgence_lantern_post
    build_time = 40

// Banner Stand Blueprint (anchored banner)
/obj/structure/blueprint/banner_stand
    name = "banner stand blueprint"
    icon_state = "blueprint_banner"
    required_materials = list(
        /obj/item/stack/sheet/cloth = 8,
        /obj/item/stack/sheet/mineral/wood = 2
    )
    build_result = /obj/structure/resurgence_banner_stand
    build_time = 45
```

### Crafting Table Recipes

The Crafting Table creates portable items and floor tiles:

```dm
/obj/structure/resurgence_crafting_table
    var/static/list/crafting_recipes = list(
        // Floor Tiles
        "Wood Floor Tiles" = list(
            "result" = /obj/item/stack/tile/wood,
            "result_amount" = 4,
            "materials" = list(/obj/item/stack/sheet/mineral/wood = 1),
            "time" = 20
        ),
        "Carpet Tiles" = list(
            "result" = /obj/item/stack/tile/carpet,
            "result_amount" = 4,
            "materials" = list(/obj/item/stack/sheet/cloth = 2),
            "time" = 25
        ),

        // Portable Decor
        "Carving Block" = list(
            "result" = /obj/structure/statue/dverg/dverg_carving_block,  // Or custom type
            "materials" = list(/obj/item/stack/sheet/mineral/wood = 10),
            "time" = 40
        ),
        "Canvas" = list(
            "result" = /obj/item/canvas,
            "materials" = list(
                /obj/item/stack/sheet/mineral/wood = 5,
                /obj/item/stack/sheet/cloth = 3
            ),
            "time" = 30
        ),
        "Easel" = list(
            "result" = /obj/structure/easel,
            "materials" = list(/obj/item/stack/sheet/mineral/wood = 8),
            "time" = 35
        ),
        "Small Wood Statue" = list(
            "result" = /obj/structure/statue/dverg/dverg_one,  // Placeholder
            "materials" = list(/obj/item/stack/sheet/mineral/wood = 15),
            "time" = 60
        ),
        "Handheld Lantern" = list(
            "result" = /obj/item/flashlight/lantern,
            "materials" = list(
                /obj/item/stack/sheet/mineral/wood = 3,
                /obj/item/stack/sheet/glass = 2
            ),
            "time" = 25
        )
    )
```

**Construction Flow:**
1. Blueprint placed (e.g., `/obj/structure/blueprint/wood_wall`)
2. Player hits with materials until `required_materials` satisfied
3. `do_after()` build timer completes
4. Blueprint calls `new build_result(get_turf(src))` to create the linked object
5. Blueprint `qdel()`s itself

### Radial Menu for Structure Selection

When clicking the blueprint planner in hand:
```dm
/obj/item/blueprint_planner/attack_self(mob/user)
    var/list/choices = list()
    for(var/struct_name in available_structures)
        var/obj/structure/blueprint/B = available_structures[struct_name]
        choices[struct_name] = image(icon = initial(B.icon), icon_state = initial(B.icon_state))

    var/choice = show_radial_menu(user, src, choices, radius = 36)
    if(choice)
        selected_structure = available_structures[choice]
        to_chat(user, "<span class='notice'>Selected: [choice]</span>")
```

---

## Global Objectives & Export System (Victory Condition)

The victory condition is a Global Objectives System where players complete building objectives, then export resources back to the Historian's main village.

### Phase 1 - Building Objectives

Players must complete these building objectives first:

| Objective | Requirement | Progress |
|-----------|-------------|----------|
| Living Quarters | Build 5 living quarters rooms | 0/5 |
| Workshop | Build 1 workshop room | 0/1 |
| Kitchen | Build 1 kitchen room | 0/1 |
| Farming Zones | Create 2+ farming zones with 6+ tiles each | 0/2 |
| Export Warehouse | Build 1 export warehouse room | 0/1 |

### Phase 2 - Export Objectives

After all building objectives are complete, export objectives unlock:

| Objective | Amount | Progress |
|-----------|--------|----------|
| Metal Sheets | 50 | 0/50 |
| Wood | 100 | 0/100 |
| Harvesters | 5 | 0/5 |
| Gold | 25 | 0/25 |
| Cloth | 30 | 0/30 |

### Viewing Objectives

Players view objectives by checking their Core (existing "Check Core Status" action).
Objectives are displayed grouped by category (Building vs Export).

### Export Warehouse Room

New room type requiring a Resources Recorder structure:
- Faith modifier: +20% (logistics bonus)
- Required to scan and export resources

### Resources Recorder Structure

Wall-mounted console for managing exports:
- Icon: `'icons/obj/machines/mining_machines.dmi'`, icon_state "console"
- Density: FALSE (no collision)
- Must be placed next to a wall (wall-adjacent placement)
- TGUI interface for scanning, selecting, and exporting

**Functions:**
1. "Scan Warehouse" - scans all closets in the Export Warehouse room
2. Shows list of detected exportable items with quantities
3. Checkboxes to select which crates/items to export
4. "Export Selected" - triggers fulton animation and adds to objective progress

### Objective Completion Effects

When an objective is completed:
1. Show global blurb to all players using `show_global_blurb()`
2. Give faith event to ALL resurgence machines for 5 minutes (+1 faith every 5 seconds)

### Fulton Export Animation

When exporting closets:
1. Spawn balloon effect at closet location
2. Animate closet rising (pixel_z) and fading (alpha)
3. Play sound effect
4. Delete closet and contents after animation
5. Add exported quantities to objective progress

### Victory

Game is won when all Phase 2 export objectives are completed

---

## File Structure (Minimal)

```
code/modules/resurgence_outpost/
    objectives/
        global_objectives.dm    # Objective datums and tracking
    structures/
        resources_recorder.dm   # Export console structure
    structures.dm               # Chest, workbench, shelter
    recipes.dm                  # Stack recipes for building

tgui/packages/tgui/interfaces/
    ResourcesRecorder.js        # Export console UI

code/game/gamemodes/resurgence_outpost/
    resurgence_outpost.dm       # Basic gamemode (later)
```

---

## Implementation Order

### Step 1: Storage Chest
Simple container structure.

### Step 2: Building Recipes
Add stack recipes to existing materials:
- Metal sheets � metal wall, metal floor
- Wood � wood wall, chest

### Step 3: Global Objectives & Export System
Objective tracking, Resources Recorder structure, and export mechanics. See implementation_steps.md Step 31.

### Step 4: Gamemode (Later)
Defer full gamemode until mechanics work. Test on existing maps first.

---

## Key Files to Reference

- `code/game/objects/items/stacks/sheets/sheet_types.dm` - Metal sheet recipes
- `code/game/objects/items/stacks/stack.dm` - Stack recipe system
- `code/game/objects/structures/crates_lockers/closets.dm` - Chest base

---

## Multi-Round Progression (Persistence)

Rounds last 1.5 hours (representing 1.5 days). At round end, the outpost state is saved and reloaded next time.

### Round Timer
- Round duration: 1.5 hours (90 minutes)
- Round ends automatically when timer expires
- Players are notified at 15 min, 5 min, and 1 min before end

### What Gets Saved
- All placed structures (walls, floors, chests, workbench, resources recorder)
- Contents of containers (chests, storage)
- Objective progress (building objectives completed, export totals)
- Structure positions (x, y, z coordinates)

### What Does NOT Get Saved
- Player inventories (players respawn fresh)
- Loose items on ground
- Player positions

### Save File Format - Full DMM Snapshot

**Files:**
- `data/resurgence_outpost/outpost_save.dmm` - Complete map state
- `data/resurgence_outpost/outpost_meta.json` - Metadata (day number, etc.)

**Reference:** `_maps/map_files/Event/city.dmm`

**DMM Format Structure:**
```
// Key definitions - unique tile compositions
"aa" = (
/obj/structure/resurgence_chest,
/turf/open/floor/resurgence/metal,
/area/resurgence_outpost)

"ab" = (
/turf/closed/wall/resurgence/metal,
/area/resurgence_outpost)

"ac" = (
/turf/open/floor/resurgence/dirt,
/area/resurgence_outpost)

// Grid section - 2-char keys per tile, one row per line
(1,1,1) = {"
acacacacabababac
acacaaacacababac
acacacacacacabab
...
"}
```

**Metadata File (JSON):**
```json
{
  "day": 3,
  "objective_phase": 2,
  "exported_totals": {"metal": 30, "wood": 75, "harvesters": 2, "gold": 10, "cloth": 15},
  "last_save": "2024-01-15 14:30:00"
}
```

**DMM Generation Process:**
1. Scan all tiles on the outpost z-level
2. For each tile, build a list of: objects + turf + area
3. Generate unique 2-char key for each unique combination
4. Build key definitions section
5. Build grid section using keys
6. Write to .dmm file

**Key Generation:**
```dm
// Use base-62 encoding for keys (a-z, A-Z, 0-9 = 62 chars)
// 2-char keys = 62^2 = 3844 unique combinations
// More than enough for any map
var/key_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
```

**Loading Process:**
1. Check if `outpost_save.dmm` exists
2. If yes: Load saved map instead of base map
3. If no: Load base map from `_maps/resurgence_outpost.dmm`
4. Load metadata from `outpost_meta.json`

**Container Contents:**
Objects with contents (chests, etc.) need special handling:
- Save contents as variable modifications in DMM format
- Example: `/obj/structure/resurgence_chest{contents = list(/obj/item/stack/sheet/metal{amount = 25})}`

**Advantages of Full DMM:**
- Native BYOND format - no custom parsing needed
- Can be viewed/edited in map editors (StrongDMM, FastDMM)
- Complete snapshot - no missing state
- Works with existing map loading infrastructure

### Implementation Pattern

**Saving (Round End):**
```dm
/proc/SaveOutpostMap()
    var/list/tile_keys = list()      // "aa" -> tile composition string
    var/list/key_lookup = list()     // tile composition -> "aa"
    var/key_index = 0
    var/list/grid_rows = list()

    // 1. Scan all tiles on outpost z-level
    for(var/y = 1 to world.maxy)
        var/row = ""
        for(var/x = 1 to world.maxx)
            var/turf/T = locate(x, y, OUTPOST_Z)
            var/composition = get_tile_composition(T)  // Returns DMM-format string

            // 2. Get or create key for this composition
            if(!key_lookup[composition])
                var/new_key = generate_key(key_index++)
                key_lookup[composition] = new_key
                tile_keys[new_key] = composition
            row += key_lookup[composition]
        grid_rows += row

    // 3. Write DMM file
    var/dmm_content = generate_dmm(tile_keys, grid_rows)
    text2file(dmm_content, "data/resurgence_outpost/outpost_save.dmm")

    // 4. Save metadata
    var/list/meta = list("day" = GLOB.outpost_day, "objective_phase" = GLOB.resurgence_objective_phase, "exported_totals" = GLOB.resurgence_exported_totals)
    text2file(json_encode(meta), "data/resurgence_outpost/outpost_meta.json")

/proc/get_tile_composition(turf/T)
    var/list/parts = list()
    for(var/obj/O in T)
        if(should_save_object(O))
            parts += get_object_dmm_string(O)
    parts += "[T.type]"
    parts += "[T.loc.type]"  // area
    return parts.Join(",")
```

**Loading (Round Start):**
```dm
/proc/LoadOutpostMap()
    // Check for existing save
    if(fexists("data/resurgence_outpost/outpost_save.dmm"))
        // Load saved map
        load_map("data/resurgence_outpost/outpost_save.dmm", OUTPOST_X, OUTPOST_Y, OUTPOST_Z)

        // Load metadata
        var/meta_json = file2text("data/resurgence_outpost/outpost_meta.json")
        var/list/meta = json_decode(meta_json)
        GLOB.outpost_day = meta["day"]
        // ... restore other state
    else
        // Load base map
        load_map("_maps/resurgence_outpost.dmm", OUTPOST_X, OUTPOST_Y, OUTPOST_Z)
        GLOB.outpost_day = 1
```

### New Day Announcement
When round starts with existing save:
> "Day [X] dawns on the Outpost. Your previous work remains."

When round starts fresh (no save or reset):
> "Day 1. The Resurgence Clan begins building a new outpost."

---

## File Structure (Updated)

```
code/modules/resurgence_outpost/
    # Objectives
    objectives/
        global_objectives.dm    # Objective datums and tracking

    # Building
    structures/
        resources_recorder.dm   # Export console structure
    structures.dm               # Chest, crate, barrel, tables, lantern, statues, etc.
    walls_floors.dm         # Wood wall, wood floor, window turfs
    doors.dm                # Wood door

    # Blueprints
    blueprint_planner.dm    # Blueprint planning tool + UI
    blueprints.dm           # Blueprint ghost structures (all categories)
    blueprint_categories.dm # Category definitions and global list

    # Resources
    trees.dm                # Choppable trees, stumps, regrowth
    mining.dm               # Ore deposits, rock faces
    gathering.dm            # Sand digging, cotton harvesting
    processing.dm           # Forge smelting, Loom weaving
    tools.dm                # Hatchet, pickaxe, shovel, sickle

    # Core
    persistence.dm          # Save/load outpost state (DMM format)

tgui/packages/tgui/interfaces/
    BlueprintPlanner.tsx    # Category-based blueprint selection UI

code/modules/surgery/organs/
    resurgence_core.dm  # Updated with new faith/charge system

code/datums/
    faith_event.dm      # Faith event datum (mood-like system)

code/datums/faith_events/
    generic_events.dm   # Common faith events (community, injury, etc.)
    outpost_events.dm   # Outpost-specific events (objective completion, shelter)

code/game/gamemodes/resurgence_outpost/
    resurgence_outpost.dm   # Gamemode with 1.5hr timer

_maps/
    resurgence_outpost.dmm  # Base map (starting state)

data/resurgence_outpost/
    outpost_save.dmm        # Full map snapshot (generated at round end)
    outpost_meta.json       # Day number, objective progress, etc.
```

---

## Crafted Components

Complex projects require intermediate components crafted from basic materials. This adds depth to crafting and makes advanced structures/items feel more earned.

### Component Tiers

**Tier 1 - Basic Materials** (gathered directly):
- Wood, Metal Sheets, Glass, Cloth, Stone

**Tier 2 - Simple Components** (crafted at Crafting Table):
| Component | Recipe | Used For |
|-----------|--------|----------|
| Wooden Plank | 2 Wood | Furniture, weapon handles |
| Metal Rod | 1 Metal Sheet | Weapon shafts, reinforcement |
| Metal Plate | 2 Metal Sheets | Armor, structural |
| Rope | 3 Cloth | Bindings, pulleys |
| Leather Strip | 2 Cloth | Grips, straps |
| Glass Lens | 2 Glass | Optics, lanterns |
| Nails | 1 Metal Sheet → 10 Nails | Construction |

**Tier 3 - Complex Components** (crafted at Forge or specialized station):
| Component | Recipe | Used For |
|-----------|--------|----------|
| Metal Frame | 4 Metal Rods + 2 Metal Plates | Large structures |
| Gear Assembly | 3 Metal Sheets (at Forge) | Machinery |
| Reinforced Plate | 2 Metal Plates + 1 Plasteel | Heavy armor, fortifications |
| Carved Ornament | 5 Wood + 1 Glass Lens | Decorative detailing |
| Woven Tapestry | 10 Cloth + 3 Rope | Decor, room decoration |

### Component Definitions

```dm
// Base component item
/obj/item/resurgence_component
    name = "component"
    desc = "A crafted component for construction."
    icon = 'icons/obj/resurgence/components.dmi'
    w_class = WEIGHT_CLASS_SMALL

// Tier 2 Components
/obj/item/resurgence_component/wooden_plank
    name = "wooden plank"
    desc = "A shaped wooden plank, ready for construction."
    icon_state = "wooden_plank"

/obj/item/resurgence_component/metal_rod
    name = "metal rod"
    desc = "A sturdy metal rod."
    icon_state = "metal_rod"

/obj/item/resurgence_component/metal_plate
    name = "metal plate"
    desc = "A flat metal plate for structural use."
    icon_state = "metal_plate"

/obj/item/resurgence_component/rope
    name = "rope"
    desc = "Strong woven rope."
    icon_state = "rope"

/obj/item/resurgence_component/leather_strip
    name = "leather strip"
    desc = "A strip of treated leather for grips and straps."
    icon_state = "leather_strip"

/obj/item/resurgence_component/glass_lens
    name = "glass lens"
    desc = "A polished glass lens."
    icon_state = "glass_lens"

/obj/item/stack/resurgence_nails
    name = "nails"
    desc = "Metal nails for construction."
    icon_state = "nails"
    singular_name = "nail"
    max_amount = 50

// Tier 3 Components
/obj/item/resurgence_component/metal_frame
    name = "metal frame"
    desc = "A sturdy metal frame for large construction projects."
    icon_state = "metal_frame"
    w_class = WEIGHT_CLASS_NORMAL

/obj/item/resurgence_component/gear_assembly
    name = "gear assembly"
    desc = "Interlocking gears for machinery."
    icon_state = "gear_assembly"

/obj/item/resurgence_component/reinforced_plate
    name = "reinforced plate"
    desc = "A heavy reinforced plate for critical structures."
    icon_state = "reinforced_plate"
    w_class = WEIGHT_CLASS_NORMAL

/obj/item/resurgence_component/carved_ornament
    name = "carved ornament"
    desc = "An intricately carved decorative piece."
    icon_state = "carved_ornament"

/obj/item/resurgence_component/woven_tapestry
    name = "woven tapestry"
    desc = "A large decorative tapestry depicting the clan's journey."
    icon_state = "woven_tapestry"
    w_class = WEIGHT_CLASS_NORMAL
```

### Export Objectives (Victory Condition)

The Monument of Hope victory condition has been replaced with the Global Objectives & Export System.
See the "Global Objectives & Export System" section above for details.

**Phase 1 - Building Objectives:**
- 5 Living Quarters rooms
- 1 Workshop room
- 1 Kitchen room
- 2+ Farming Zones (6+ tiles each)
- 1 Export Warehouse room

**Phase 2 - Export Objectives:**
- 50 Metal Sheets
- 100 Wood
- 5 Harvesters
- 25 Gold
- 30 Cloth

The Export Warehouse room requires a Resources Recorder structure for scanning and exporting resources.

---

## Room System (Dynamic Areas)

Machines can designate enclosed spaces as rooms, which provide bonuses based on their contents. Uses the existing area system as a base.

**Reference:** `code/game/objects/items/blueprints.dm`, `code/__HELPERS/areas.dm`

### Room Types

Room type is automatically determined by scanning structures inside:

| Room Type | Triggers | Faith Effect | Production Effect |
|-----------|----------|--------------|-------------------|
| **Workshop** | Contains Forge, Loom, or Crafting Table | -25% faith gain | Normal crafting speed |
| **Common Room** | Contains Decor, no production structures | +50% faith gain | N/A |
| **Storage Room** | Contains only Storage structures | +10% faith gain | N/A |
| **Shrine** | Contains Small Statue | +75% faith gain | N/A |
| **Basic Room** | Enclosed but no special structures | +25% faith gain (shelter bonus) | 3x crafting time |

**Key Rule:** Production structures (Forge, Loom, Crafting Table) take **3x longer** if not in a Workshop area.

### Room Designator Tool

```dm
/obj/item/room_designator
    name = "room designator"
    desc = "A tool for marking enclosed spaces as rooms. The room type is determined by its contents."
    icon = 'icons/obj/resurgence/tools.dmi'
    icon_state = "room_designator"

/obj/item/room_designator/attack_self(mob/user)
    // Check if user is in a valid enclosed space
    var/list/turfs = detect_enclosed_room(get_turf(user))
    if(!turfs)
        to_chat(user, "<span class='warning'>You must be in a fully enclosed space with walls on all sides.</span>")
        return

    if(turfs.len > ROOM_MAX_SIZE)
        to_chat(user, "<span class='warning'>This space is too large to designate as a room. Maximum [ROOM_MAX_SIZE] tiles.</span>")
        return

    // Scan for structures to determine room type
    var/room_type = determine_room_type(turfs)
    var/room_name = get_default_room_name(room_type)

    // Ask for custom name
    var/custom_name = stripped_input(user, "Name this room:", "Room Designation", room_name, MAX_NAME_LEN)
    if(!custom_name)
        return

    // Create the area
    create_resurgence_room(turfs, room_type, custom_name, user)
```

### Room Detection

```dm
#define ROOM_MAX_SIZE 100

// Detect enclosed room using flood fill, stopping at walls/doors
/proc/detect_enclosed_room(turf/origin)
    var/list/found_turfs = list()
    var/list/to_check = list(origin)
    var/list/checked = list()

    while(to_check.len && found_turfs.len <= ROOM_MAX_SIZE)
        var/turf/T = to_check[1]
        to_check -= T

        if(T in checked)
            continue
        checked += T

        // If this is a wall or closed turf, it's a boundary
        if(T.density || istype(T, /turf/closed))
            continue

        // If this is open space/outdoors, room is not enclosed
        if(istype(T, /turf/open/space) || istype(T.loc, /area/resurgence_outpost/outdoors))
            return null  // Not enclosed

        found_turfs += T

        // Check adjacent tiles (cardinal directions only)
        for(var/dir in GLOB.cardinals)
            var/turf/adjacent = get_step(T, dir)
            if(adjacent && !(adjacent in checked))
                to_check += adjacent

    if(found_turfs.len > ROOM_MAX_SIZE)
        return null  // Too big

    return found_turfs
```

### Room Type Determination

```dm
#define ROOM_TYPE_BASIC     "basic"
#define ROOM_TYPE_WORKSHOP  "workshop"
#define ROOM_TYPE_COMMON    "common"
#define ROOM_TYPE_STORAGE   "storage"
#define ROOM_TYPE_SHRINE    "shrine"

/proc/determine_room_type(list/turfs)
    var/has_production = FALSE
    var/has_decor = FALSE
    var/has_storage = FALSE
    var/has_shrine = FALSE

    for(var/turf/T in turfs)
        for(var/obj/structure/S in T)
            // Production structures
            if(istype(S, /obj/structure/resurgence_forge) || \
               istype(S, /obj/structure/resurgence_loom) || \
               istype(S, /obj/structure/resurgence_crafting_table))
                has_production = TRUE

            // Decor structures
            if(istype(S, /obj/structure/resurgence_lantern) || \
               istype(S, /obj/structure/resurgence_banner) || \
               istype(S, /obj/structure/resurgence_painting))
                has_decor = TRUE

            // Storage structures
            if(istype(S, /obj/structure/resurgence_chest) || \
               istype(S, /obj/structure/resurgence_crate) || \
               istype(S, /obj/structure/resurgence_barrel))
                has_storage = TRUE

            // Shrine structures
            if(istype(S, /obj/structure/resurgence_statue))
                has_shrine = TRUE

    // Priority: Shrine > Workshop > Common > Storage > Basic
    if(has_shrine)
        return ROOM_TYPE_SHRINE
    if(has_production)
        return ROOM_TYPE_WORKSHOP
    if(has_decor && !has_production)
        return ROOM_TYPE_COMMON
    if(has_storage && !has_production && !has_decor)
        return ROOM_TYPE_STORAGE
    return ROOM_TYPE_BASIC
```

### Resurgence Area Types

```dm
/area/resurgence_outpost
    name = "Resurgence Outpost"
    icon_state = "resurgence"
    has_gravity = TRUE
    requires_power = FALSE  // No power system for machines
    outdoors = TRUE

    var/room_type = null    // Set for designated rooms
    var/faith_modifier = 1.0  // Multiplier for faith gain in this area

/area/resurgence_outpost/outdoors
    name = "Outskirts"
    outdoors = TRUE
    faith_modifier = 1.0    // Neutral

/area/resurgence_outpost/room
    name = "Room"
    outdoors = FALSE
    room_type = ROOM_TYPE_BASIC
    faith_modifier = 1.25   // +25% base shelter bonus

/area/resurgence_outpost/room/workshop
    name = "Workshop"
    room_type = ROOM_TYPE_WORKSHOP
    faith_modifier = 0.75   // -25% (focused on work, less communal)
    icon_state = "resurgence_workshop"

/area/resurgence_outpost/room/common
    name = "Common Room"
    room_type = ROOM_TYPE_COMMON
    faith_modifier = 1.5    // +50% (community gathering)
    icon_state = "resurgence_common"

/area/resurgence_outpost/room/storage
    name = "Storage Room"
    room_type = ROOM_TYPE_STORAGE
    faith_modifier = 1.1    // +10%
    icon_state = "resurgence_storage"

/area/resurgence_outpost/room/shrine
    name = "Shrine"
    room_type = ROOM_TYPE_SHRINE
    faith_modifier = 1.75   // +75% (spiritual center)
    icon_state = "resurgence_shrine"
```

### Room Creation

```dm
/proc/create_resurgence_room(list/turfs, room_type, room_name, mob/creator)
    var/area/resurgence_outpost/room/new_area

    switch(room_type)
        if(ROOM_TYPE_WORKSHOP)
            new_area = new /area/resurgence_outpost/room/workshop
        if(ROOM_TYPE_COMMON)
            new_area = new /area/resurgence_outpost/room/common
        if(ROOM_TYPE_STORAGE)
            new_area = new /area/resurgence_outpost/room/storage
        if(ROOM_TYPE_SHRINE)
            new_area = new /area/resurgence_outpost/room/shrine
        else
            new_area = new /area/resurgence_outpost/room

    new_area.name = room_name
    new_area.setup(room_name)

    // Move all turfs to new area
    for(var/turf/T in turfs)
        var/area/old_area = T.loc
        new_area.contents += T
        T.change_area(old_area, new_area)

    new_area.reg_in_areas_in_z()

    to_chat(creator, "<span class='notice'>You have designated this space as '[room_name]' ([room_type]).</span>")
    announce_room_created(room_name, room_type)
    return new_area

/proc/announce_room_created(room_name, room_type)
    for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
        if(istype(H.dna?.species, /datum/species/resurgence_machine))
            to_chat(H, "<span class='notice'>A new [room_type] has been established: '[room_name]'.</span>")
```

### Production Speed Modifier

Production structures check their area for workshop status:

```dm
/obj/structure/resurgence_crafting_table
    var/base_craft_time = 30  // Base time in deciseconds

/obj/structure/resurgence_crafting_table/proc/get_craft_time()
    var/area/resurgence_outpost/room/R = get_area(src)
    if(!istype(R) || R.room_type != ROOM_TYPE_WORKSHOP)
        return base_craft_time * 3  // 3x slower outside workshop
    return base_craft_time

/obj/structure/resurgence_forge
    var/base_smelt_time = 50

/obj/structure/resurgence_forge/proc/get_smelt_time()
    var/area/resurgence_outpost/room/R = get_area(src)
    if(!istype(R) || R.room_type != ROOM_TYPE_WORKSHOP)
        return base_smelt_time * 3
    return base_smelt_time

/obj/structure/resurgence_loom
    var/base_weave_time = 40

/obj/structure/resurgence_loom/proc/get_weave_time()
    var/area/resurgence_outpost/room/R = get_area(src)
    if(!istype(R) || R.room_type != ROOM_TYPE_WORKSHOP)
        return base_weave_time * 3
    return base_weave_time
```

### Faith Modifier Integration

Update the faith event system to apply area modifiers:

```dm
/obj/item/organ/resurgence_core/proc/add_faith_event(category, datum/faith_event/event)
    // Apply area faith modifier
    var/area/resurgence_outpost/room/R = get_area(owner)
    if(istype(R))
        event.faith_change = event.faith_change * R.faith_modifier

    // Replace existing event in same category
    if(faith_events[category])
        qdel(faith_events[category])
    faith_events[category] = event
    recalculate_faith()
```

### Room Update on Structure Change

When structures are added/removed, the room type may need to update:

```dm
// Called when a structure is built or deconstructed in a room
/proc/check_room_type_change(turf/T)
    var/area/resurgence_outpost/room/R = get_area(T)
    if(!istype(R))
        return

    // Get all turfs in this area
    var/list/room_turfs = list()
    for(var/turf/room_turf in R.contents)
        room_turfs += room_turf

    // Determine new room type
    var/new_type = determine_room_type(room_turfs)

    if(new_type != R.room_type)
        // Room type has changed - notify and update
        var/old_type = R.room_type
        update_room_type(R, new_type)
        announce_room_type_change(R.name, old_type, new_type)

/proc/update_room_type(area/resurgence_outpost/room/R, new_type)
    R.room_type = new_type
    switch(new_type)
        if(ROOM_TYPE_WORKSHOP)
            R.faith_modifier = 0.75
        if(ROOM_TYPE_COMMON)
            R.faith_modifier = 1.5
        if(ROOM_TYPE_STORAGE)
            R.faith_modifier = 1.1
        if(ROOM_TYPE_SHRINE)
            R.faith_modifier = 1.75
        else
            R.faith_modifier = 1.25
```

### Room Summary

| Room Type | Faith Modifier | Crafting Speed | Triggered By |
|-----------|----------------|----------------|--------------|
| Outdoors | 1.0x (neutral) | 3x slower | Not enclosed |
| Basic Room | 1.25x (+25%) | 3x slower | Enclosed, no structures |
| Workshop | 0.75x (-25%) | Normal | Forge, Loom, or Crafting Table |
| Common Room | 1.5x (+50%) | N/A | Decor only, no production |
| Storage Room | 1.1x (+10%) | N/A | Storage only |
| Shrine | 1.75x (+75%) | N/A | Statue |

---

## Woven Outfits (Loom Crafting)

The Loom can weave cloth into outfits that provide passive faith bonuses when worn. Uses existing clothing sprites to avoid needing new art.

**Reference:** `code/modules/clothing/suits/chaplainsuits.dm`, `code/modules/clothing/suits/miscellaneous.dm`

### Outfit Types (Using Existing Sprites)

| Outfit | Base Type | Cloth Cost | Faith Bonus | Description |
|--------|-----------|------------|-------------|-------------|
| **White Robe** | `/obj/item/clothing/suit/chaplainsuit/whiterobe` | 8 | +3 | Simple cloth robe |
| **Monk's Habit** | `/obj/item/clothing/suit/hooded/chaplainsuit/monkhabit` | 10 | +4 | Hooded robe (with hood) |
| **Eastern Robes** | `/obj/item/clothing/suit/chaplainsuit/monkrobeeast` | 6 | +2 | Minimalist eastern style |
| **Poncho** | `/obj/item/clothing/suit/poncho` | 5 | +2 | Simple travel garment |
| **Owl Cloak** | `/obj/item/clothing/suit/toggle/owlwings` | 12 | +5 | Feathered ceremonial cloak |
| **Hastur's Robe** | `/obj/item/clothing/suit/hastur` | 15 + 1 Tapestry | +8 | Mystic elder garment |
| **Bishop's Robes** | `/obj/item/clothing/suit/chaplainsuit/bishoprobe` | 20 + 2 Tapestry | +10 | Grand ceremonial attire |
| **Apron** | `/obj/item/clothing/suit/apron` | 4 | +1, -10% craft | Work garment |
| **Nun Hood** | `/obj/item/clothing/head/nun_hood` | 4 | +2 | Head covering |
| **Black Beret** | `/obj/item/clothing/head/beret/black` | 3 | +1 | Simple head covering |
| **Ushanka** | `/obj/item/clothing/head/ushanka` | 5 | +2 | Warm hat |
| **Scarf** | `/obj/item/clothing/neck/scarf` | 3 | +1 | Neck accessory |
| **Black Gloves** | `/obj/item/clothing/gloves/color/black` | 3 | +1 | Hand coverings |

### Implementation

Instead of creating new clothing subtypes, we use a component system to add faith bonuses to existing clothing when crafted at the Loom:

```dm
// Component that adds faith bonus to any clothing item
/datum/component/faith_clothing
    var/faith_bonus = 0
    var/crafted_by_resurgence = TRUE

/datum/component/faith_clothing/Initialize(bonus = 0)
    if(!istype(parent, /obj/item/clothing))
        return COMPONENT_INCOMPATIBLE
    faith_bonus = bonus
    RegisterSignal(parent, COMSIG_ITEM_EQUIPPED, PROC_REF(on_equipped))
    RegisterSignal(parent, COMSIG_ITEM_DROPPED, PROC_REF(on_dropped))

/datum/component/faith_clothing/proc/on_equipped(datum/source, mob/user, slot)
    // Check if equipped in correct slot for this clothing type
    var/obj/item/clothing/C = parent
    if(!(C.slot_flags & slot))
        return
    apply_faith_bonus(user)

/datum/component/faith_clothing/proc/on_dropped(datum/source, mob/user)
    remove_faith_bonus(user)

/datum/component/faith_clothing/proc/apply_faith_bonus(mob/living/carbon/human/H)
    if(!istype(H))
        return
    var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
    if(!istype(core))
        return
    var/datum/faith_event/clothing/E = new
    var/obj/item/I = parent
    E.description = "Wearing [I.name]"
    E.faith_change = faith_bonus
    core.add_faith_event("clothing_[REF(parent)]", E)

/datum/component/faith_clothing/proc/remove_faith_bonus(mob/living/carbon/human/H)
    if(!istype(H))
        return
    var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
    if(!istype(core))
        return
    core.clear_faith_event("clothing_[REF(parent)]")

// Modify examine to show faith bonus
/datum/component/faith_clothing/RegisterWithParent()
    RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/component/faith_clothing/proc/on_examine(datum/source, mob/user, list/examine_list)
    examine_list += "<span class='notice'>This garment was crafted by the Resurgence Clan. (+[faith_bonus] faith)</span>"
```

### Loom Outfit Recipes

```dm
/obj/structure/resurgence_loom
    var/static/list/outfit_recipes = list(
        "White Robe" = list(
            "result" = /obj/item/clothing/suit/chaplainsuit/whiterobe,
            "materials" = list(/obj/item/stack/sheet/cloth = 8),
            "faith_bonus" = 3,
            "time" = 60
        ),
        "Monk's Habit" = list(
            "result" = /obj/item/clothing/suit/hooded/chaplainsuit/monkhabit,
            "materials" = list(/obj/item/stack/sheet/cloth = 10),
            "faith_bonus" = 4,
            "time" = 80
        ),
        "Eastern Robes" = list(
            "result" = /obj/item/clothing/suit/chaplainsuit/monkrobeeast,
            "materials" = list(/obj/item/stack/sheet/cloth = 6),
            "faith_bonus" = 2,
            "time" = 50
        ),
        "Poncho" = list(
            "result" = /obj/item/clothing/suit/poncho,
            "materials" = list(/obj/item/stack/sheet/cloth = 5),
            "faith_bonus" = 2,
            "time" = 40
        ),
        "Owl Cloak" = list(
            "result" = /obj/item/clothing/suit/toggle/owlwings,
            "materials" = list(/obj/item/stack/sheet/cloth = 12),
            "faith_bonus" = 5,
            "time" = 100
        ),
        "Hastur's Robe" = list(
            "result" = /obj/item/clothing/suit/hastur,
            "materials" = list(
                /obj/item/stack/sheet/cloth = 15,
                /obj/item/resurgence_component/woven_tapestry = 1
            ),
            "faith_bonus" = 8,
            "time" = 120
        ),
        "Bishop's Robes" = list(
            "result" = /obj/item/clothing/suit/chaplainsuit/bishoprobe,
            "materials" = list(
                /obj/item/stack/sheet/cloth = 20,
                /obj/item/resurgence_component/woven_tapestry = 2
            ),
            "faith_bonus" = 10,
            "time" = 150
        ),
        "Work Apron" = list(
            "result" = /obj/item/clothing/suit/apron,
            "materials" = list(/obj/item/stack/sheet/cloth = 4),
            "faith_bonus" = 1,
            "time" = 30,
            "craft_speed_bonus" = 0.9  // 10% faster crafting
        ),
        "Nun Hood" = list(
            "result" = /obj/item/clothing/head/nun_hood,
            "materials" = list(/obj/item/stack/sheet/cloth = 4),
            "faith_bonus" = 2,
            "time" = 30
        ),
        "Black Beret" = list(
            "result" = /obj/item/clothing/head/beret/black,
            "materials" = list(/obj/item/stack/sheet/cloth = 3),
            "faith_bonus" = 1,
            "time" = 25
        ),
        "Ushanka" = list(
            "result" = /obj/item/clothing/head/ushanka,
            "materials" = list(/obj/item/stack/sheet/cloth = 5),
            "faith_bonus" = 2,
            "time" = 40
        ),
        "Scarf" = list(
            "result" = /obj/item/clothing/neck/scarf,
            "materials" = list(/obj/item/stack/sheet/cloth = 3),
            "faith_bonus" = 1,
            "time" = 20
        ),
        "Black Gloves" = list(
            "result" = /obj/item/clothing/gloves/color/black,
            "materials" = list(/obj/item/stack/sheet/cloth = 3),
            "faith_bonus" = 1,
            "time" = 25
        )
    )
```

### Loom Crafting Process

```dm
/obj/structure/resurgence_loom/proc/start_weaving(mob/user, recipe_name)
    var/list/recipe = outfit_recipes[recipe_name]
    if(!recipe)
        return

    // Check materials
    if(!check_materials(user, recipe["materials"]))
        to_chat(user, "<span class='warning'>You don't have the required materials for [recipe_name].</span>")
        return

    // Consume materials
    consume_materials(user, recipe["materials"])

    // Get weave time (affected by workshop bonus)
    var/weave_time = get_weave_time(recipe["time"])

    to_chat(user, "<span class='notice'>You begin weaving [recipe_name]...</span>")
    if(!do_after(user, weave_time, src))
        to_chat(user, "<span class='warning'>You stop weaving.</span>")
        return

    // Create the outfit
    var/result_type = recipe["result"]
    var/obj/item/clothing/result = new result_type(get_turf(src))

    // Add faith bonus component
    var/faith_bonus = recipe["faith_bonus"]
    result.AddComponent(/datum/component/faith_clothing, faith_bonus)

    // Add craft speed bonus component if applicable
    if(recipe["craft_speed_bonus"])
        result.AddComponent(/datum/component/craft_speed_bonus, recipe["craft_speed_bonus"])

    // Rename to indicate clan crafting
    result.name = "clan-woven [result.name]"
    result.desc += " This garment was lovingly crafted by the Resurgence Clan."

    to_chat(user, "<span class='notice'>You finish weaving [result.name]!</span>")

    // Faith event for crafting
    add_crafting_faith_event(user)
```

### Work Apron Crafting Bonus

The Work Apron uses a separate component for craft speed:

```dm
/datum/component/craft_speed_bonus
    var/speed_multiplier = 1.0

/datum/component/craft_speed_bonus/Initialize(multiplier = 0.9)
    speed_multiplier = multiplier

// Production structures check for this component
/obj/structure/resurgence_crafting_table/proc/get_craft_time()
    var/area/resurgence_outpost/room/R = get_area(src)
    var/base_time = base_craft_time

    // Workshop penalty
    if(!istype(R) || R.room_type != ROOM_TYPE_WORKSHOP)
        base_time *= 3

    // Check if user is wearing apron with craft bonus
    var/mob/living/carbon/human/H = usr
    if(istype(H) && H.wear_suit)
        var/datum/component/craft_speed_bonus/bonus = H.wear_suit.GetComponent(/datum/component/craft_speed_bonus)
        if(bonus)
            base_time *= bonus.speed_multiplier

    return base_time
```

### Maximum Faith from Clothing

```dm
#define MAX_CLOTHING_FAITH_BONUS 15

/obj/item/organ/resurgence_core/proc/recalculate_faith()
    var/total = 50  // Base faith
    var/clothing_total = 0

    for(var/category in faith_events)
        var/datum/faith_event/event = faith_events[category]
        if(istype(event, /datum/faith_event/clothing))
            clothing_total += event.faith_change
        else
            total += event.faith_change

    // Cap clothing bonus
    clothing_total = min(clothing_total, MAX_CLOTHING_FAITH_BONUS)
    total += clothing_total

    faith = clamp(total, 0, max_faith)
```

### Outfit Summary

| Slot | Best Option | Faith | Notes |
|------|-------------|-------|-------|
| Suit | Bishop's Robes | +10 | Requires 2 Woven Tapestry |
| Suit (Alt) | Hastur's Robe | +8 | Requires 1 Woven Tapestry |
| Suit (Basic) | Owl Cloak | +5 | Just cloth |
| Head | Nun Hood / Ushanka | +2 | Simple coverings |
| Neck | Scarf | +1 | Accessory slot |
| Gloves | Black Gloves | +1 | Hand coverings |
| **Max Total** | | **+15** | Capped |

**Full Outfit Example:**
- Bishop's Robes (+10) + Nun Hood (+2) + Scarf (+1) + Black Gloves (+1) = **+14 faith**

---

## Weapons

### Melee Weapons

#### Wooden Spear
A basic hunting weapon made from wood.

```dm
/obj/item/resurgence_weapon/spear/wooden
    name = "wooden spear"
    desc = "A sharpened wooden spear. Simple but effective."
    icon_state = "wooden_spear"
    force = 15
    throwforce = 20
    throw_speed = 4
    reach = 2                    // Can attack 2 tiles away
    attack_verb = list("stabbed", "poked", "jabbed")
    w_class = WEIGHT_CLASS_BULKY

    var/durability = 30          // Breaks after 30 hits
    var/max_durability = 30
```

**Recipe (Crafting Table):**
| Component | Amount |
|-----------|--------|
| Wood | 3 |
| Stone | 1 (for sharpening) |

#### Metal Spear
An upgraded spear with a metal tip.

```dm
/obj/item/resurgence_weapon/spear/metal
    name = "metal-tipped spear"
    desc = "A spear with a forged metal tip. Much more durable."
    icon_state = "metal_spear"
    force = 22
    throwforce = 28
    throw_speed = 4
    reach = 2

    var/durability = 80
    var/max_durability = 80
```

**Recipe (Forge):**
| Component | Amount |
|-----------|--------|
| Wooden Plank | 2 |
| Metal Rod | 1 |
| Leather Strip | 1 (for grip) |

#### Spear Base Type

```dm
/obj/item/resurgence_weapon/spear
    name = "spear"
    icon = 'icons/obj/resurgence/weapons.dmi'
    slot_flags = ITEM_SLOT_BACK
    hitsound = 'sound/weapons/bladeslice.ogg'
    attack_verb = list("attacked", "stabbed", "jabbed")

    var/durability = 50
    var/max_durability = 50

/obj/item/resurgence_weapon/spear/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
    . = ..()
    if(proximity_flag)
        durability--
        if(durability <= 0)
            to_chat(user, "<span class='warning'>Your [name] breaks!</span>")
            playsound(src, 'sound/effects/woodhit.ogg', 50, TRUE)
            qdel(src)
        else if(durability <= max_durability * 0.2)
            to_chat(user, "<span class='warning'>Your [name] is close to breaking!</span>")

/obj/item/resurgence_weapon/spear/examine(mob/user)
    . = ..()
    var/condition
    var/percent = (durability / max_durability) * 100
    switch(percent)
        if(80 to 100)
            condition = "in excellent condition"
        if(60 to 79)
            condition = "in good condition"
        if(40 to 59)
            condition = "showing wear"
        if(20 to 39)
            condition = "damaged"
        else
            condition = "about to break"
    . += "It is [condition]."
```

### Ranged Weapons

#### Sling
A simple ranged weapon that launches stones.

```dm
/obj/item/resurgence_weapon/sling
    name = "sling"
    desc = "A leather sling for hurling stones at enemies."
    icon = 'icons/obj/resurgence/weapons.dmi'
    icon_state = "sling"
    w_class = WEIGHT_CLASS_SMALL

    var/obj/item/ammo_casing/resurgence/loaded_ammo = null
    var/fire_delay = 15          // 1.5 seconds between shots
    var/last_fire = 0

/obj/item/resurgence_weapon/sling/examine(mob/user)
    . = ..()
    if(loaded_ammo)
        . += "It is loaded with [loaded_ammo.name]."
    else
        . += "It is not loaded. Use stones or crafted shot to load it."

/obj/item/resurgence_weapon/sling/attackby(obj/item/I, mob/user, params)
    if(istype(I, /obj/item/ammo_casing/resurgence/sling))
        if(loaded_ammo)
            to_chat(user, "<span class='warning'>The sling is already loaded!</span>")
            return
        var/obj/item/ammo_casing/resurgence/sling/ammo = I
        if(ammo.amount > 0)
            loaded_ammo = new ammo.type(src)
            ammo.amount--
            if(ammo.amount <= 0)
                qdel(ammo)
            to_chat(user, "<span class='notice'>You load the sling.</span>")
        return
    ..()

/obj/item/resurgence_weapon/sling/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
    if(proximity_flag)
        return ..()  // Melee attack

    // Ranged attack
    if(!loaded_ammo)
        to_chat(user, "<span class='warning'>The sling is not loaded!</span>")
        return

    if(world.time < last_fire + fire_delay)
        return

    last_fire = world.time
    fire_projectile(target, user)

/obj/item/resurgence_weapon/sling/proc/fire_projectile(atom/target, mob/user)
    var/obj/projectile/P = new loaded_ammo.projectile_type(get_turf(user))
    P.preparePixelProjectile(target, user)
    P.firer = user
    P.fire()
    playsound(user, 'sound/weapons/bowfire.ogg', 50, TRUE)
    to_chat(user, "<span class='notice'>You hurl the [loaded_ammo.name] at [target]!</span>")
    QDEL_NULL(loaded_ammo)
```

**Recipe (Crafting Table):**
| Component | Amount |
|-----------|--------|
| Leather Strip | 2 |
| Rope | 1 |

#### Crossbow
A more powerful ranged weapon requiring bolts.

```dm
/obj/item/resurgence_weapon/crossbow
    name = "crossbow"
    desc = "A mechanical crossbow. Powerful but slow to reload."
    icon = 'icons/obj/resurgence/weapons.dmi'
    icon_state = "crossbow"
    w_class = WEIGHT_CLASS_NORMAL
    slot_flags = ITEM_SLOT_BACK

    var/obj/item/ammo_casing/resurgence/crossbow/loaded_bolt = null
    var/fire_delay = 30          // 3 seconds between shots
    var/last_fire = 0
    var/cocked = FALSE

/obj/item/resurgence_weapon/crossbow/attack_self(mob/user)
    if(cocked)
        to_chat(user, "<span class='warning'>The crossbow is already cocked.</span>")
        return
    to_chat(user, "<span class='notice'>You begin cocking the crossbow...</span>")
    if(do_after(user, 20, src))
        cocked = TRUE
        to_chat(user, "<span class='notice'>You cock the crossbow.</span>")
        update_icon()

/obj/item/resurgence_weapon/crossbow/examine(mob/user)
    . = ..()
    if(loaded_bolt)
        . += "It is loaded with [loaded_bolt.name]."
    else
        . += "It is not loaded."
    if(cocked)
        . += "It is cocked and ready to fire."
    else
        . += "It needs to be cocked before firing. Click it in hand."

/obj/item/resurgence_weapon/crossbow/attackby(obj/item/I, mob/user, params)
    if(istype(I, /obj/item/ammo_casing/resurgence/crossbow))
        if(loaded_bolt)
            to_chat(user, "<span class='warning'>The crossbow is already loaded!</span>")
            return
        var/obj/item/ammo_casing/resurgence/crossbow/bolt = I
        if(bolt.amount > 0)
            loaded_bolt = new bolt.type(src)
            bolt.amount--
            if(bolt.amount <= 0)
                qdel(bolt)
            to_chat(user, "<span class='notice'>You load a bolt into the crossbow.</span>")
            update_icon()
        return
    ..()

/obj/item/resurgence_weapon/crossbow/proc/fire_projectile(atom/target, mob/user)
    if(!cocked)
        to_chat(user, "<span class='warning'>You need to cock the crossbow first!</span>")
        return
    if(!loaded_bolt)
        to_chat(user, "<span class='warning'>The crossbow is not loaded!</span>")
        return

    var/obj/projectile/P = new loaded_bolt.projectile_type(get_turf(user))
    P.preparePixelProjectile(target, user)
    P.firer = user
    P.fire()
    playsound(user, 'sound/weapons/bowfire.ogg', 75, TRUE)
    to_chat(user, "<span class='notice'>You fire the crossbow!</span>")
    QDEL_NULL(loaded_bolt)
    cocked = FALSE
    update_icon()
```

**Recipe (Forge):**
| Component | Amount |
|-----------|--------|
| Wooden Plank | 3 |
| Metal Rod | 2 |
| Gear Assembly | 1 |
| Rope | 2 |

### Ammunition

#### Sling Stones
Basic ammunition gathered from the ground.

```dm
/obj/item/ammo_casing/resurgence/sling/stone
    name = "sling stones"
    desc = "Smooth stones suitable for slinging."
    icon_state = "sling_stones"
    projectile_type = /obj/projectile/resurgence/stone

    var/amount = 10
    var/max_amount = 20

/obj/projectile/resurgence/stone
    name = "stone"
    icon_state = "yourub_neutral"  // Placeholder
    damage = 15
    damage_type = BRUTE
    armour_penetration = 0
```

**Source:** Pick up from ground (scattered small rocks) or craft from larger stones.

#### Metal Shot
Crafted ammunition for slings - more damaging.

```dm
/obj/item/ammo_casing/resurgence/sling/metal_shot
    name = "metal shot"
    desc = "Small metal balls for slinging. More damaging than stones."
    icon_state = "metal_shot"
    projectile_type = /obj/projectile/resurgence/metal_shot

    var/amount = 10
    var/max_amount = 20

/obj/projectile/resurgence/metal_shot
    name = "metal shot"
    damage = 22
    damage_type = BRUTE
    armour_penetration = 10
```

**Recipe (Forge):**
| Input | Output |
|-------|--------|
| 1 Metal Sheet | 10 Metal Shot |

#### Wooden Bolts
Basic crossbow ammunition.

```dm
/obj/item/ammo_casing/resurgence/crossbow/wooden
    name = "wooden bolts"
    desc = "Simple wooden crossbow bolts."
    icon_state = "wooden_bolts"
    projectile_type = /obj/projectile/resurgence/bolt/wooden

    var/amount = 5
    var/max_amount = 10

/obj/projectile/resurgence/bolt/wooden
    name = "wooden bolt"
    damage = 25
    damage_type = BRUTE
    armour_penetration = 5
```

**Recipe (Crafting Table):**
| Input | Output |
|-------|--------|
| 2 Wood | 5 Wooden Bolts |

#### Metal Bolts
Upgraded crossbow ammunition.

```dm
/obj/item/ammo_casing/resurgence/crossbow/metal
    name = "metal bolts"
    desc = "Metal-tipped crossbow bolts. Deadly."
    icon_state = "metal_bolts"
    projectile_type = /obj/projectile/resurgence/bolt/metal

    var/amount = 5
    var/max_amount = 10

/obj/projectile/resurgence/bolt/metal
    name = "metal bolt"
    damage = 35
    damage_type = BRUTE
    armour_penetration = 20
```

**Recipe (Forge):**
| Input | Output |
|-------|--------|
| 1 Wood + 1 Metal Rod | 5 Metal Bolts |

### Weapon Summary

| Weapon | Type | Damage | Special | Recipe Location |
|--------|------|--------|---------|-----------------|
| Wooden Spear | Melee | 15 (22 thrown) | 2-tile reach, 30 durability | Crafting Table |
| Metal Spear | Melee | 22 (28 thrown) | 2-tile reach, 80 durability | Forge |
| Sling | Ranged | Varies by ammo | Fast reload | Crafting Table |
| Crossbow | Ranged | Varies by ammo | Slow, powerful, needs cocking | Forge |

| Ammo | Damage | Armor Pen | Recipe |
|------|--------|-----------|--------|
| Sling Stones | 15 | 0 | Found on ground |
| Metal Shot | 22 | 10 | 1 Metal → 10 |
| Wooden Bolts | 25 | 5 | 2 Wood → 5 |
| Metal Bolts | 35 | 20 | 1 Wood + 1 Metal Rod → 5 |

---

## Updated File Structure

```
code/modules/resurgence_outpost/
    # Objectives
    objectives/
        global_objectives.dm    # Objective datums and tracking

    # Building
    structures/
        resources_recorder.dm   # Export console structure
    structures.dm               # Chest, crate, barrel, tables, lantern, statues, etc.
    walls_floors.dm             # Wood wall, wood floor, window turfs
    doors.dm                    # Wood door

    # Blueprints
    blueprint_planner.dm    # Blueprint planning tool + UI
    blueprints.dm           # Blueprint ghost structures (all categories)
    blueprint_categories.dm # Category definitions and global list

    # Resources
    trees.dm                # Choppable trees, stumps, regrowth
    mining.dm               # Ore deposits, rock faces
    gathering.dm            # Sand digging, cotton harvesting
    processing.dm           # Forge smelting, Loom weaving
    tools.dm                # Hatchet, pickaxe, shovel, sickle

    # Components
    components.dm           # All crafted components (Tier 2 & 3)
    component_recipes.dm    # Recipes for components at various stations

    # Weapons
    weapons_melee.dm        # Spears and other melee weapons
    weapons_ranged.dm       # Sling, crossbow
    ammo.dm                 # Ammunition types and projectiles

    # Rooms
    room_designator.dm      # Room designator tool
    room_detection.dm       # Enclosed space detection
    room_types.dm           # Room type determination logic

    # Clothing
    faith_clothing_component.dm  # Component that adds faith to any clothing
    craft_speed_component.dm     # Component for crafting speed bonus

    # Core
    persistence.dm          # Save/load outpost state (DMM format)
    areas.dm                # Resurgence area types

tgui/packages/tgui/interfaces/
    BlueprintPlanner.tsx    # Category-based blueprint selection UI

code/modules/surgery/organs/
    resurgence_core.dm  # Updated with new faith/charge system

code/datums/
    faith_event.dm      # Faith event datum (mood-like system)

code/datums/faith_events/
    generic_events.dm   # Common faith events (community, injury, etc.)
    outpost_events.dm   # Outpost-specific events (objective completion, shelter)

code/game/gamemodes/resurgence_outpost/
    resurgence_outpost.dm   # Gamemode with 1.5hr timer

_maps/
    resurgence_outpost.dmm  # Base map (starting state)

data/resurgence_outpost/
    outpost_save.dmm        # Full map snapshot (generated at round end)
    outpost_meta.json       # Day number, objective progress, etc.

icons/obj/resurgence/
    components.dmi          # Component sprites
    weapons.dmi             # Weapon sprites
```

---

## Testing

### Building & Structures
1. Spawn chest, verify storage works
2. Build walls/floors from materials
3. Build rooms to complete building objectives, verify progress updates
4. Complete all building objectives, verify Phase 2 unlocks

### Persistence
5. Let round timer expire, verify save is created
6. Start new round, verify structures reload correctly
7. Verify chest contents persist across rounds

### Blueprint System
8. Spawn blueprint planner, verify radial menu opens
9. Select structure, click ground to place blueprint
10. Verify blueprint is transparent blue and walkable
11. Hit blueprint with wrong material, verify rejection
12. Hit blueprint with correct materials, verify progress
13. Complete blueprint, verify structure is built
14. Alt-click to rotate blueprint
15. Right-click to remove blueprint

### Faith & Charge System
16. Verify charge decays passively (no regen)
17. Add positive faith event, verify faith increases
18. Verify high faith slows charge decay
19. Add negative faith event, verify faith decreases
20. Verify low faith speeds up charge decay
21. Verify faith events with timeout expire correctly
22. Verify "Despairing" level applies movement penalty
23. Test objective completion adds faith event to all machines

### Components
24. Craft Tier 2 component (wooden plank) at Crafting Table
25. Verify Tier 2 components can be used in Tier 3 recipes
26. Craft Tier 3 component (metal frame) at Forge
27. Test Resources Recorder scans closets in Export Warehouse and exports correctly

### Weapons
28. Craft wooden spear, verify 2-tile reach
29. Use spear until durability depletes, verify it breaks
30. Craft metal spear at forge, verify higher durability
31. Craft sling, load with stones, fire at target
32. Verify sling fire delay works
33. Craft crossbow, verify cocking requirement
34. Load crossbow with wooden bolts, fire at target
35. Craft metal bolts, verify higher damage
36. Pick up sling stones from ground, verify they stack

### Rooms
37. Build enclosed 4-wall structure, use room designator inside
38. Verify basic room is created with +25% faith modifier
39. Add crafting table to room, verify it becomes Workshop (-25% faith)
40. Remove crafting table, add lantern, verify it becomes Common Room (+50% faith)
41. Use crafting table outside workshop, verify 3x crafting time
42. Use crafting table inside workshop, verify normal crafting time
43. Add statue to room, verify it becomes Shrine (+75% faith)
44. Build and remove structures, verify room type updates dynamically
45. Verify room designator fails in non-enclosed space
46. Verify room designator fails if space is too large (>100 tiles)

### Woven Outfits
47. Weave White Robe at Loom, verify it's created with faith component
48. Equip clan-woven White Robe, verify +3 faith bonus applied
49. Unequip robe, verify faith bonus removed
50. Weave Bishop's Robes (requires 2 Woven Tapestry)
51. Equip full outfit set (robe + hood + scarf + gloves), verify faith capped at +15
52. Wear Work Apron, verify 10% faster crafting
53. Examine clan-woven clothing, verify it shows faith bonus
54. Verify Loom uses 3x time when not in Workshop

---

## Room Ownership System

Players can claim rooms as their personal space. Having a room provides faith benefits, while being homeless causes faith penalties.

### Ownership Mechanics

```dm
/area/resurgence_outpost/room
    var/owner_ckey = null       // ckey of the player who owns this room
    var/room_id = null          // Unique ID for persistence

/datum/faith_event/room_ownership
    category = "room_ownership"

// Homeless event - applied when player has no room
/datum/faith_event/room_ownership/homeless
    description = "Homeless - no place to call home"
    faith_change = -10

// Has room event - applied when player owns a room
/datum/faith_event/room_ownership/has_room
    description = "Has personal room"
    faith_change = +5
```

### Claiming Rooms

```dm
/obj/item/room_designator/proc/claim_room(mob/user, area/resurgence_outpost/room/R)
    if(!istype(R))
        to_chat(user, span_warning("This is not a valid room to claim."))
        return FALSE

    if(R.owner_ckey)
        if(R.owner_ckey == user.ckey)
            to_chat(user, span_notice("You already own this room."))
        else
            to_chat(user, span_warning("This room is already claimed by someone else."))
        return FALSE

    // Check if player already owns a room
    for(var/area/resurgence_outpost/room/other_room in GLOB.resurgence_rooms)
        if(other_room.owner_ckey == user.ckey)
            to_chat(user, span_warning("You already own a room. Unclaim it first."))
            return FALSE

    // Claim the room
    R.owner_ckey = user.ckey
    to_chat(user, span_notice("You claim this room as your own!"))

    // Update faith event
    update_room_ownership_faith(user)
    return TRUE
```

### Faith Integration

```dm
/proc/update_room_ownership_faith(mob/living/carbon/human/H)
    if(!istype(H))
        return

    var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
    if(!istype(core))
        return

    // Check if player owns any room
    for(var/area/resurgence_outpost/room/R in GLOB.resurgence_rooms)
        if(R.owner_ckey == H.ckey)
            // Has a room
            var/datum/faith_event/room_ownership/has_room/E = new
            core.add_faith_event("room_ownership", E)
            return

    // No room - homeless
    var/datum/faith_event/room_ownership/homeless/E = new
    core.add_faith_event("room_ownership", E)
```

---

## Room Quality (Beauty) System

Room quality affects faith based on the total beauty of furniture inside. Uses the existing beauty component system as reference.

**Reference:** `code/datums/components/beauty.dm`

### Beauty Ratings

All items crafted via blueprints or crafting tables have a base beauty rating:

| Category | Item | Base Beauty |
|----------|------|-------------|
| **Furniture** | Basic Wooden Chair | +2 |
| | Wooden Table | +3 |
| | Bed | +5 |
| | Dresser | +4 |
| **Storage** | Storage Chest | +1 |
| | Crate | +1 |
| | Barrel | +1 |
| **Lighting** | Lantern Post | +4 |
| | Wall Torch | +2 |
| **Decor** | Banner Stand | +6 |
| | Small Statue | +10 |
| | Canvas Painting | +3 to +8 (quality varies) |
| **Flooring** | Carpet Tile | +1 per tile |
| | Wood Floor | +0.5 per tile |
| | Bare Floor | 0 |
| **Negative** | Rubble/Debris | -5 |
| | Blood stains | -3 |
| | Garbage | -4 |

### Room Quality Levels

| Total Beauty | Quality Level | Faith Effect |
|--------------|---------------|--------------|
| 50+ | Luxurious | +0.5 faith/min while inside |
| 30-49 | Comfortable | +0.3 faith/min while inside |
| 10-29 | Adequate | +0.1 faith/min while inside |
| 0-9 | Bare | No effect |
| -1 to -19 | Shabby | -0.1 faith/min while inside |
| -20 or less | Squalid | -0.3 faith/min while inside |

### Implementation

```dm
/area/resurgence_outpost/room
    var/total_beauty = 0
    var/quality_level = "bare"

/area/resurgence_outpost/room/proc/recalculate_beauty()
    total_beauty = 0

    for(var/turf/T in contents)
        // Check floor beauty
        if(istype(T, /turf/open/floor/resurgence/carpet))
            total_beauty += 1
        else if(istype(T, /turf/open/floor/resurgence/wood))
            total_beauty += 0.5

        // Check objects on turf
        for(var/obj/O in T)
            var/datum/component/beauty/B = O.GetComponent(/datum/component/beauty)
            if(B)
                total_beauty += B.beauty

    // Determine quality level
    if(total_beauty >= 50)
        quality_level = "luxurious"
    else if(total_beauty >= 30)
        quality_level = "comfortable"
    else if(total_beauty >= 10)
        quality_level = "adequate"
    else if(total_beauty >= 0)
        quality_level = "bare"
    else if(total_beauty >= -19)
        quality_level = "shabby"
    else
        quality_level = "squalid"

/area/resurgence_outpost/room/proc/get_faith_modifier_per_minute()
    switch(quality_level)
        if("luxurious")
            return 0.5
        if("comfortable")
            return 0.3
        if("adequate")
            return 0.1
        if("bare")
            return 0
        if("shabby")
            return -0.1
        if("squalid")
            return -0.3
    return 0
```

### Beauty Component for Crafted Items

```dm
// Applied automatically when items are crafted
/datum/component/resurgence_beauty
    var/base_beauty = 0
    var/crafter_bonus = 0  // From crafter's stat

/datum/component/resurgence_beauty/Initialize(base = 0, bonus = 0)
    base_beauty = base
    crafter_bonus = bonus

    // Add to room beauty calculations
    var/obj/O = parent
    if(istype(O))
        var/area/resurgence_outpost/room/R = get_area(O)
        if(istype(R))
            R.recalculate_beauty()

/datum/component/resurgence_beauty/proc/get_total_beauty()
    return base_beauty + crafter_bonus
```

### Cramped Room Penalty

Rooms that are too small or narrow apply a faith penalty to occupants:

| Condition | Faith Penalty | Description |
|-----------|---------------|-------------|
| ≤10 free tiles | -5 faith | "Cramped Room" - not enough space |
| Width or height <3 tiles | -5 faith | "Cramped Room" - too narrow |
| Both conditions | -8 faith | "Very Cramped" - claustrophobic |

**Implementation:**

```dm
/area/resurgence_outpost/room
    var/is_cramped = FALSE
    var/cramped_severity = 0  // 0 = not cramped, 1 = cramped, 2 = very cramped
    var/room_width = 0
    var/room_height = 0
    var/free_tiles = 0

/area/resurgence_outpost/room/proc/calculate_room_dimensions()
    // Find bounding box of room
    var/min_x = INFINITY
    var/max_x = 0
    var/min_y = INFINITY
    var/max_y = 0
    free_tiles = 0

    for(var/turf/T in contents)
        if(T.x < min_x) min_x = T.x
        if(T.x > max_x) max_x = T.x
        if(T.y < min_y) min_y = T.y
        if(T.y > max_y) max_y = T.y
        free_tiles++

    room_width = (max_x - min_x) + 1
    room_height = (max_y - min_y) + 1

    // Check cramped conditions
    var/too_small = (free_tiles <= 10)
    var/too_narrow = (room_width < 3 || room_height < 3)

    if(too_small && too_narrow)
        is_cramped = TRUE
        cramped_severity = 2  // Very cramped
    else if(too_small || too_narrow)
        is_cramped = TRUE
        cramped_severity = 1  // Cramped
    else
        is_cramped = FALSE
        cramped_severity = 0

/area/resurgence_outpost/room/proc/get_cramped_faith_penalty()
    switch(cramped_severity)
        if(2)
            return -8  // Very Cramped
        if(1)
            return -5  // Cramped
    return 0
```

**Faith Events for Cramped Rooms:**

```dm
/datum/faith_event/cramped
    category = "room_size"

/datum/faith_event/cramped/cramped
    description = "Cramped Room"
    faith_change = -5

/datum/faith_event/cramped/very_cramped
    description = "Very Cramped Room"
    faith_change = -8
```

### Common Room Eating Bonus

Eating food in a Common Room (a room with seating and tables) provides a bonus to meal quality:

- **+1 quality tier** when eating in a Common Room
- Encourages communal dining and building proper dining areas
- Stacks with other quality modifiers (cooking stat, kitchen cooking)

**Detection:** A room is considered a "Common Room" if it contains:
- At least one chair or bench (seating)
- At least one table

```dm
/area/resurgence_outpost/room
    var/is_common_room = FALSE

/area/resurgence_outpost/room/proc/check_common_room()
    var/has_seating = FALSE
    var/has_table = FALSE

    for(var/turf/T in contents)
        for(var/obj/structure/S in T)
            if(istype(S, /obj/structure/chair) || istype(S, /obj/structure/resurgence_chair))
                has_seating = TRUE
            if(istype(S, /obj/structure/table) || istype(S, /obj/structure/resurgence_table))
                has_table = TRUE

    is_common_room = (has_seating && has_table)

// In meal component, when eaten:
/datum/component/resurgence_meal/proc/get_eating_location_bonus(mob/living/eater)
    var/area/A = get_area(eater)

    // Check if in a common room
    if(istype(A, /area/resurgence_outpost/room))
        var/area/resurgence_outpost/room/R = A
        if(R.is_common_room)
            return 1  // +1 quality tier

    return 0  // No bonus for eating outside or in non-common rooms
```

**Quality Tier Progression with Common Room Bonus:**
| Base Quality | + Common Room | Final Quality |
|--------------|---------------|---------------|
| Awful | +1 | Poor |
| Poor | +1 | Decent |
| Decent | +1 | Good |
| Good | +1 | Excellent |
| Excellent | +1 | Masterwork |
| Masterwork | +1 | Masterwork (capped) |

---

## Character Stats System

Rimworld-inspired stats that affect gameplay and improve through use.

### Stats Overview

| Stat | Affects | Level 1 | Level 10 | Level 20 |
|------|---------|---------|----------|----------|
| **Construction** | Blueprint building | 1.5x time, -2 beauty | Normal | 0.5x time, +5 beauty |
| **Crafting** | Crafting stations | 1.5x time, -2 beauty | Normal | 0.5x time, +5 beauty |
| **Gathering** | Resource gathering | 0.5x yield, 1.5x time | Normal | 1.5x yield, 0.5x time |
| **Cooking** | Cooking meals | 1.5x time, -1 quality tier | Normal | 0.5x time, +2 quality tiers |

### Storage

Stats are stored on the resurgence_core organ:

```dm
/obj/item/organ/resurgence_core
    // Character stats (1-20 scale)
    var/stat_construction = 1
    var/stat_crafting = 1
    var/stat_gathering = 1
    var/stat_cooking = 1

    // XP tracking
    var/xp_construction = 0
    var/xp_crafting = 0
    var/xp_gathering = 0
    var/xp_cooking = 0

/obj/item/organ/resurgence_core/proc/get_stat_speed_modifier(stat_name)
    var/stat_level
    switch(stat_name)
        if("construction")
            stat_level = stat_construction
        if("crafting")
            stat_level = stat_crafting
        if("gathering")
            stat_level = stat_gathering
        if("cooking")
            stat_level = stat_cooking
        else
            return 1.0

    // 1.5 at level 1, 1.0 at level 10, 0.5 at level 20
    return 1.5 - (stat_level - 1) * (1.0 / 19)

/obj/item/organ/resurgence_core/proc/get_stat_beauty_bonus(stat_name)
    var/stat_level
    switch(stat_name)
        if("construction")
            stat_level = stat_construction
        if("crafting")
            stat_level = stat_crafting
        else
            return 0

    // -2 at level 1, 0 at level 10, +5 at level 20
    return round(-2 + (stat_level - 1) * (7.0 / 19))

/obj/item/organ/resurgence_core/proc/get_gathering_yield_modifier()
    // 0.5 at level 1, 1.0 at level 10, 1.5 at level 20
    return 0.5 + (stat_gathering - 1) * (1.0 / 19)
```

### XP and Leveling

```dm
#define XP_BASE_REQUIREMENT 100

/obj/item/organ/resurgence_core/proc/get_xp_required(current_level)
    // Doubles each level: 100, 200, 400, 800...
    return XP_BASE_REQUIREMENT * (2 ** (current_level - 1))

/obj/item/organ/resurgence_core/proc/add_xp(stat_name, amount)
    var/current_xp
    var/current_level

    switch(stat_name)
        if("construction")
            current_xp = xp_construction
            current_level = stat_construction
        if("crafting")
            current_xp = xp_crafting
            current_level = stat_crafting
        if("gathering")
            current_xp = xp_gathering
            current_level = stat_gathering
        else
            return

    current_xp += amount

    // Check for level up
    var/xp_needed = get_xp_required(current_level)
    while(current_xp >= xp_needed && current_level < 20)
        current_xp -= xp_needed
        current_level++
        xp_needed = get_xp_required(current_level)
        announce_level_up(stat_name, current_level)

    // Store back
    switch(stat_name)
        if("construction")
            xp_construction = current_xp
            stat_construction = current_level
        if("crafting")
            xp_crafting = current_xp
            stat_crafting = current_level
        if("gathering")
            xp_gathering = current_xp
            stat_gathering = current_level

/obj/item/organ/resurgence_core/proc/announce_level_up(stat_name, new_level)
    if(owner)
        to_chat(owner, span_notice("<b>Level Up!</b> Your [stat_name] skill is now level [new_level]!"))
```

### XP Gains

| Activity | XP Type | Amount |
|----------|---------|--------|
| Complete blueprint | Construction | 5-20 (based on material cost) |
| Complete craft | Crafting | 5-15 (based on work required) |
| Gather resource chunk | Gathering | 1 per work point |
| Complete cooking recipe | Cooking | 5-15 (based on work required) |

---

## Bed and Stat Viewing

Players can rest in a bed in their owned room to view stats and save progress.

### Bed Structure

```dm
/obj/structure/resurgence_bed
    name = "bed"
    desc = "A comfortable bed. Rest here to view your stats and save progress."
    icon = 'icons/obj/furniture.dmi'
    icon_state = "bed"
    anchored = TRUE
    var/base_beauty = 5

/obj/structure/resurgence_bed/attack_hand(mob/living/carbon/human/user)
    . = ..()
    if(!istype(user))
        return

    // Check if bed is in user's owned room
    var/area/resurgence_outpost/room/R = get_area(src)
    if(!istype(R) || R.owner_ckey != user.ckey)
        to_chat(user, span_warning("This isn't your room. You can only rest in your own room."))
        return

    // Open stats UI
    ui_interact(user)

/obj/structure/resurgence_bed/ui_interact(mob/user, datum/tgui/ui)
    ui = SStgui.try_update_ui(user, src, ui)
    if(!ui)
        ui = new(user, src, "ResurgenceStats", "Character Stats")
        ui.open()
```

### Stats UI (TGUI)

```
┌─────────────────────────────────────────────────────┐
│  CHARACTER STATS                                [X] │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Construction: Lv 5                                 │
│  ████████████░░░░░░░░░░░░░░░░░░ (320/400 XP)       │
│  Speed: 1.26x slower | Beauty: +0                  │
│                                                     │
│  Crafting: Lv 8                                     │
│  ██████████████████████░░░░░░░░ (1100/1600 XP)     │
│  Speed: 1.08x slower | Beauty: +2                  │
│                                                     │
│  Gathering: Lv 3                                    │
│  ██████░░░░░░░░░░░░░░░░░░░░░░░░ (80/200 XP)        │
│  Yield: 0.71x | Speed: 1.37x slower                │
│                                                     │
│  ─────────────────────────────────────────────────  │
│  Room Quality: Comfortable (+0.3 faith/min)         │
│  Total Beauty: 35                                   │
│                                                     │
│  [Save & Rest]                                      │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## Extended Resource Gathering

Resource gathering takes significant time and can be interrupted and resumed.

### Gathering Parameters

| Resource | Base Time | Base Yield | Work Needed | Faith Drain |
|----------|-----------|------------|-------------|-------------|
| Tree | 2.5 minutes | 45 wood | 300 work | -30 faith |
| Iron Ore Deposit | 2 minutes | 30 ore | 240 work | -24 faith |
| Stone Deposit | 1.5 minutes | 25 stone | 180 work | -18 faith |
| Cotton Plant | 30 seconds | 5 cotton | 60 work | -6 faith |
| Sand Pile | 45 seconds | 10 sand | 90 work | -9 faith |

### Work Drains Faith

**All work (gathering, crafting, cooking, construction) slowly drains faith directly.**

This is NOT a faith event - it directly reduces the faith value by 0.1 per work point. This creates a natural need for:
- Rest in comfortable rooms (passive faith gain)
- Good meals (faith bonus from eating)
- Community activities (faith events)

| Activity | Faith Drain Rate |
|----------|------------------|
| Gathering | -0.1 per work point |
| Crafting | -0.1 per work point |
| Cooking | -0.1 per work point |
| Construction | -0.1 per work point |

**Examples:**
- Chopping a full tree (300 work) = -30 faith
- Crafting a 20-work item = -2 faith
- Building a structure (50 work) = -5 faith

### Faith Requirement (Charge System Disabled)

**Players cannot gather or craft if faith is below 5.**

```dm
#define MIN_FAITH_FOR_WORK 5
#define FAITH_DRAIN_PER_WORK 0.1

/obj/structure/resurgence_tree/attackby(obj/item/I, mob/user)
    if(!is_axe(I))
        return ..()

    // Check faith
    var/obj/item/organ/resurgence_core/core = user.getorganslot(ORGAN_SLOT_HEART)
    if(!istype(core))
        to_chat(user, span_warning("You don't have a resurgence core."))
        return

    if(core.faith < MIN_FAITH_FOR_WORK)
        to_chat(user, span_warning("You're too exhausted to gather resources."))
        return

    start_chopping(user, I)
```

### Interruptible Progress

```dm
/obj/structure/resurgence_tree
    var/work_progress = 0
    var/work_needed = 300
    var/base_yield = 45

/obj/structure/resurgence_tree/proc/start_chopping(mob/user, obj/item/tool)
    var/obj/item/organ/resurgence_core/core = user.getorganslot(ORGAN_SLOT_HEART)
    if(!istype(core))
        return

    var/speed_mod = core.get_stat_speed_modifier("gathering")
    var/work_per_tick = 2 / speed_mod  // Higher gathering = more work per tick

    to_chat(user, span_notice("You begin chopping the tree... ([round(work_progress/work_needed*100)]% complete)"))

    while(work_progress < work_needed)
        // Check faith each second (charge system disabled)
        if(core.faith < MIN_FAITH_FOR_WORK)
            to_chat(user, span_warning("You're too exhausted to continue. Progress: [round(work_progress/work_needed*100)]%"))
            break

        // 1-second work interval
        if(!do_after(user, 1 SECONDS, src))
            to_chat(user, span_notice("You stop chopping. Progress saved: [round(work_progress/work_needed*100)]%"))
            break

        work_progress += work_per_tick

        // Award XP
        core.add_xp("gathering", work_per_tick)

        // Drain faith directly (not via events)
        core.adjust_faith(-FAITH_DRAIN_PER_WORK * work_per_tick)

        // Periodic feedback
        if(work_progress % 30 == 0)
            to_chat(user, span_notice("Chopping... [round(work_progress/work_needed*100)]%"))

    if(work_progress >= work_needed)
        complete_harvest(user)

/obj/structure/resurgence_tree/proc/complete_harvest(mob/user)
    var/obj/item/organ/resurgence_core/core = user.getorganslot(ORGAN_SLOT_HEART)

    var/yield_mod = core ? core.get_gathering_yield_modifier() : 1.0
    var/final_yield = round(base_yield * yield_mod)

    to_chat(user, span_notice("The tree falls! You gather [final_yield] wood."))
    new /obj/item/stack/sheet/mineral/wood(get_turf(src), final_yield)

    // Become stump
    become_stump()
```

---

## Harvester Tool

An automated gathering tool that can be attached to resources to harvest them without continuous player interaction.

### Variants

| Variant | Faith Storage | Search Range | Special |
|---------|--------------|--------------|---------|
| Simple Harvester | None (uses player) | None | Single target only |
| Advanced Harvester | 100 faith | 3 tiles | Auto-seeks next target |

### Simple Harvester

**Crafting:** Basic materials at Crafting Table
- 5 Wood
- 5 Metal
- 2 Rope

**Behavior:**
1. Player attaches harvester to a valid resource (tree, ore deposit, cotton plant, farm plot)
2. Faith cost is paid from player based on target's `work_needed` value
3. Harvester begins working at normal player speed
4. When complete, resource is harvested and loot drops at location
5. Harvester drops to ground, ready for reuse
6. Unlimited uses - no durability

**Faith Costs (based on resource work_needed):**

| Resource | Work Needed | Faith Cost |
|----------|-------------|------------|
| Tree | 300 | 30 |
| Iron Ore | 240 | 24 |
| Stone | 180 | 18 |
| Sand Pile | 90 | 9 |
| Cotton Plant | 60 | 6 |
| Farm Plot (harvest) | varies | varies |

### Advanced Harvester

**Crafting:** Upgrade at Forge
- 1 Simple Harvester
- 5 Metal
- 2 Silver

**Behavior:**
1. Has internal faith storage (100 faith capacity)
2. Player can "charge" it by transferring faith from their core
3. When attached to resource, uses stored faith instead of player's
4. After completing harvest, automatically seeks next valid target within 3 tiles
5. Only targets same resource type (trees -> trees, ore -> ore)
6. Continues until faith depleted or no valid targets remain
7. When stopped, drops to ground at last location

**Auto-Seek Logic:**
```dm
/obj/item/harvester/advanced/proc/find_next_target()
    var/list/candidates = list()
    for(var/obj/target in range(3, get_turf(src)))
        if(is_valid_harvest_target(target))
            if(is_same_resource_type(target, last_target_type))
                candidates += target

    if(candidates.len)
        return pick(candidates)
    return null
```

### Valid Targets

Both harvester variants can target:
- `/obj/structure/resurgence_tree` - Trees
- `/obj/structure/resurgence_ore_deposit` - Ore deposits
- `/obj/structure/resurgence_cotton` - Cotton plants
- `/obj/structure/farm_plot` - Farm plots (only when harvest-ready)

### Destruction Behavior

When a harvester is destroyed while in use:
- Drops to ground at current location
- Partially refunds faith (50% of remaining work value)
- Does NOT complete the harvest
- Resource retains its current progress

---

## Cooking System

Cooking allows players to create meals that provide faith bonuses (charge system disabled).

### Cooking Station

A crafting station (campfire, cooking pot, or stove) that uses the same work-based system as other stations:

```dm
/obj/structure/resurgence_crafting_table/cooking_station
    name = "cooking pot"
    desc = "A pot for cooking hearty meals over a fire."
    icon_state = "cooking_pot"

    action_verb = "Cook"
    busy_verb = "cooking"
    ui_color = "brown"
```

### Meal Component

All cooked food gets a component that tracks quality and provides faith bonuses:

```dm
/datum/component/resurgence_meal
    // var/charge_value = 10   // DISABLED - charge system not active
    var/quality = "decent"     // Quality tier
    var/faith_bonus = 5        // Faith event strength
    var/quality_name = ""      // Display name like "Good Meal"

/datum/component/resurgence_meal/Initialize(qual = "decent")
    quality = qual
    faith_bonus = get_faith_bonus_for_quality(qual)
    quality_name = get_quality_display_name(qual)

    // Hook into eating
    RegisterSignal(parent, COMSIG_FOOD_EATEN, PROC_REF(on_eaten))

/datum/component/resurgence_meal/proc/on_eaten(datum/source, mob/living/eater, mob/living/feeder)
    if(!ishuman(eater))
        return

    var/mob/living/carbon/human/H = eater
    var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
    if(!istype(core))
        return

    // Handle faith event (highest quality wins)
    apply_meal_faith_event(core)

/datum/component/resurgence_meal/proc/apply_meal_faith_event(obj/item/organ/resurgence_core/core)
    // Check for existing meal faith event
    var/datum/faith_event/existing = core.get_faith_event_by_category("meal")

    if(existing)
        // Only replace if our faith bonus is higher
        if(existing.faith_change >= faith_bonus)
            to_chat(core.owner, span_notice("You already feel well-fed from a better meal."))
            return
        // Remove the weaker event
        core.clear_faith_events_by_category("meal")

    // Add our faith event
    if(faith_bonus > 0)
        var/datum/faith_event/meal/E = new(quality, faith_bonus)
        core.add_faith_event("meal", E)
        to_chat(core.owner, span_notice("The [quality_name] lifts your spirits! (+[faith_bonus] faith for 5 minutes)"))
```

### Meal Quality Levels

| Quality | Faith Bonus | Description |
|---------|-------------|-------------|
| Awful | +0 | Burnt or spoiled - no faith benefit |
| Poor | +2 | Barely edible |
| Decent | +5 | Filling but plain |
| Good | +8 | Tasty and satisfying |
| Excellent | +12 | Delicious, well-prepared |
| Masterwork | +18 | A culinary masterpiece |

### Faith Event for Meals

```dm
/datum/faith_event/meal
    category = "meal"
    timeout = 5 MINUTES

/datum/faith_event/meal/New(quality, bonus)
    faith_change = bonus
    switch(quality)
        if("awful")
            description = "Ate an awful meal"
        if("poor")
            description = "Ate a poor meal"
        if("decent")
            description = "Ate a decent meal"
        if("good")
            description = "Ate a good meal"
        if("excellent")
            description = "Ate an excellent meal"
        if("masterwork")
            description = "Ate a masterwork meal"
    ..()
```

### Cooking Recipes

| Meal | Ingredients | Base Charge | Base Quality | Work |
|------|-------------|-------------|--------------|------|
| Roasted Meat | 1 Raw Meat | 15 | Decent | 10 |
| Grilled Vegetables | 2 Vegetables | 10 | Decent | 10 |
| Simple Soup | 1 Vegetable + 1 Water | 12 | Poor | 8 |
| Vegetable Stew | 2 Vegetables + 1 Water | 20 | Good | 20 |
| Meat Stew | 1 Raw Meat + 1 Vegetable + 1 Water | 25 | Good | 25 |
| Bread | 3 Wheat | 10 | Decent | 15 |
| Meat Pie | 1 Raw Meat + 2 Wheat | 30 | Good | 30 |
| Hearty Stew | 2 Meat + 2 Vegetables + 1 Water | 35 | Excellent | 40 |
| Feast Plate | 2 Meat + 2 Vegetables + 1 Bread | 40 | Excellent | 50 |

### Quality Modifiers

Quality can be improved or reduced by various factors:

**Positive Modifiers:**
- High Cooking stat: Up to +2 quality tiers at level 20
- Cooking in Kitchen room: +1 quality tier
- Using fresh/high-quality ingredients: +1 quality tier (future feature)

**Negative Modifiers:**
- Low Cooking stat: -1 quality tier at level 1
- Interrupted/cancelled cook: -2 quality tiers (burnt)
- Cooking outdoors: -1 quality tier

**Quality Tier Order:**
Awful → Poor → Decent → Good → Excellent → Masterwork

```dm
/obj/structure/resurgence_crafting_table/cooking_station/proc/calculate_final_quality(mob/user, base_quality)
    var/quality_index = quality_to_index(base_quality)

    // Check cooking stat
    var/obj/item/organ/resurgence_core/core = user.getorganslot(ORGAN_SLOT_HEART)
    if(istype(core))
        var/cooking_level = core.stat_cooking
        // Level 1: -1, Level 10: 0, Level 20: +2
        var/stat_mod = round(-1 + (cooking_level - 1) * (3.0 / 19))
        quality_index += stat_mod

    // Check if in kitchen
    var/area/A = get_area(src)
    if(istype(A, /area/resurgence_outpost/room/kitchen))
        quality_index += 1

    // Clamp to valid range
    quality_index = clamp(quality_index, 0, 5)

    return index_to_quality(quality_index)

/proc/quality_to_index(quality)
    switch(quality)
        if("awful") return 0
        if("poor") return 1
        if("decent") return 2
        if("good") return 3
        if("excellent") return 4
        if("masterwork") return 5
    return 2

/proc/index_to_quality(index)
    switch(index)
        if(0) return "awful"
        if(1) return "poor"
        if(2) return "decent"
        if(3) return "good"
        if(4) return "excellent"
        if(5) return "masterwork"
    return "decent"
```

### Cooking Stat

A fourth character stat for cooking:

```dm
/obj/item/organ/resurgence_core
    // Add to existing stats
    var/stat_cooking = 1
    var/xp_cooking = 0
```

**Cooking Stat Effects:**
| Level | Speed Modifier | Quality Modifier |
|-------|----------------|------------------|
| 1 | 1.5x slower | -1 tier |
| 10 | Normal | +0 tiers |
| 20 | 0.5x faster | +2 tiers |

### Kitchen Room Type

Add Kitchen as a room type that provides cooking bonuses:

```dm
/area/resurgence_outpost/room/kitchen
    name = "Kitchen"
    // Cooking stations inside get +1 quality tier
    // Faith modifier: +25% (good smells, warm atmosphere)
```

**Room Detection:** A room becomes a Kitchen if it contains a cooking station.

---

## Player Data Persistence

Player stats and room ownership are saved per ckey.

### Save Location

`data/resurgence_outpost/players/[ckey].json`

### Save Format

```json
{
    "ckey": "exampleplayer",
    "owned_room_id": "room_15",
    "stats": {
        "construction": {
            "level": 5,
            "xp": 320
        },
        "crafting": {
            "level": 8,
            "xp": 1100
        },
        "gathering": {
            "level": 3,
            "xp": 80
        }
    },
    "last_save": "2024-01-15T14:30:00Z"
}
```

### Save/Load Procs

```dm
/proc/save_player_data(mob/living/carbon/human/H)
    if(!H.ckey)
        return FALSE

    var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
    if(!istype(core))
        return FALSE

    // Find owned room
    var/owned_room_id = null
    for(var/area/resurgence_outpost/room/R in GLOB.resurgence_rooms)
        if(R.owner_ckey == H.ckey)
            owned_room_id = R.room_id
            break

    var/list/data = list(
        "ckey" = H.ckey,
        "owned_room_id" = owned_room_id,
        "stats" = list(
            "construction" = list("level" = core.stat_construction, "xp" = core.xp_construction),
            "crafting" = list("level" = core.stat_crafting, "xp" = core.xp_crafting),
            "gathering" = list("level" = core.stat_gathering, "xp" = core.xp_gathering)
        ),
        "last_save" = time2text(world.realtime, "YYYY-MM-DD hh:mm:ss")
    )

    var/json = json_encode(data)
    var/path = "data/resurgence_outpost/players/[H.ckey].json"

    rustg_file_write(json, path)
    return TRUE

/proc/load_player_data(mob/living/carbon/human/H)
    if(!H.ckey)
        return FALSE

    var/path = "data/resurgence_outpost/players/[H.ckey].json"
    if(!fexists(path))
        return FALSE

    var/json = file2text(path)
    var/list/data = json_decode(json)
    if(!data)
        return FALSE

    var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
    if(!istype(core))
        return FALSE

    // Restore stats
    var/list/stats = data["stats"]
    if(stats)
        if(stats["construction"])
            core.stat_construction = stats["construction"]["level"]
            core.xp_construction = stats["construction"]["xp"]
        if(stats["crafting"])
            core.stat_crafting = stats["crafting"]["level"]
            core.xp_crafting = stats["crafting"]["xp"]
        if(stats["gathering"])
            core.stat_gathering = stats["gathering"]["level"]
            core.xp_gathering = stats["gathering"]["xp"]

    // Restore room ownership
    var/owned_room_id = data["owned_room_id"]
    if(owned_room_id)
        for(var/area/resurgence_outpost/room/R in GLOB.resurgence_rooms)
            if(R.room_id == owned_room_id)
                R.owner_ckey = H.ckey
                break

    // Update faith events
    update_room_ownership_faith(H)

    return TRUE
```

---

## Updated File Structure

```
code/modules/resurgence_outpost/
    # Objectives
    objectives/
        global_objectives.dm    # Objective datums and tracking

    # Building
    structures/
        resources_recorder.dm   # Export console structure
    structures.dm               # Chest, crate, barrel, tables, lantern, statues, etc.
    walls_floors.dm             # Wood wall, wood floor, window turfs
    doors.dm                    # Wood door

    # Blueprints
    blueprint_planner.dm    # Blueprint planning tool + UI
    blueprints.dm           # Blueprint ghost structures (all categories)
    blueprint_categories.dm # Category definitions and global list

    # Resources
    trees.dm                # Choppable trees with interruptible progress
    mining.dm               # Ore deposits with interruptible progress
    gathering.dm            # Sand digging, cotton harvesting
    processing.dm           # Forge smelting, Loom weaving
    tools.dm                # Hatchet, pickaxe, shovel, sickle

    # Components
    components.dm           # All crafted components (Tier 2 & 3)
    component_recipes.dm    # Recipes for components at various stations

    # Weapons (DEPRIORITIZED)
    weapons_melee.dm        # Spears and other melee weapons
    weapons_ranged.dm       # Sling, crossbow
    ammo.dm                 # Ammunition types and projectiles

    # Rooms
    room_designator.dm      # Room designator tool
    room_detection.dm       # Enclosed space detection
    room_types.dm           # Room type determination logic
    room_ownership.dm       # Room claiming and ownership tracking
    room_quality.dm         # Beauty calculation and faith effects

    # Character Stats
    character_stats.dm      # Stat definitions and modifiers
    stat_leveling.dm        # XP system and leveling
    bed.dm                  # Bed structure and stat UI

    # Food & Cooking
    food/
        cooking_station.dm      # Cooking pot/campfire structure
        meal_component.dm       # Component for cooked meals (charge + quality)
        recipes.dm              # Cooking recipes
        ingredients.dm          # Raw ingredients (meat, vegetables, wheat)

    # Clothing
    faith_clothing_component.dm  # Component that adds faith to any clothing
    craft_speed_component.dm     # Component for crafting speed bonus

    # Core
    persistence.dm          # Save/load outpost state (DMM format)
    player_data.dm          # Per-ckey save/load for stats and room ownership
    areas.dm                # Resurgence area types

tgui/packages/tgui/interfaces/
    BlueprintPlanner.tsx    # Category-based blueprint selection UI
    ResurgenceCrafting.js   # Crafting table UI with batch crafting
    ResurgenceStats.tsx     # Character stats viewing UI

code/modules/surgery/organs/
    resurgence_core.dm      # Updated with stats (including cooking), XP tracking

code/datums/
    faith_event.dm          # Faith event datum (mood-like system)

code/datums/faith_events/
    generic_events.dm       # Common faith events (community, injury, etc.)
    outpost_events.dm       # Outpost-specific events (room ownership, quality, meals)

data/resurgence_outpost/
    outpost_save.dmm        # Full map snapshot (generated at round end)
    outpost_meta.json       # Day number, objective progress, etc.
    players/                # Per-player save files
        [ckey].json         # Individual player stats and room ownership
```

---

## Testing - Living Systems

### Room Ownership
55. Spawn as machine, verify -10 faith "Homeless" event appears
56. Build and designate room, claim it
57. Verify faith changes to +5 "Has Personal Room"
58. Try to claim second room, verify blocked
59. Have another player try to claim your room, verify blocked
60. Save/reload, verify room ownership persists

### Room Quality
61. Build empty room, verify beauty = 0
62. Add furniture (table, chair, bed), verify beauty increases
63. Stay in room with beauty 30+, verify faith slowly increases
64. Add debris/garbage to room, verify beauty decreases
65. Stay in squalid room, verify faith slowly decreases

### Cramped Rooms
66. Build tiny 2x3 room (6 tiles), verify "Very Cramped" debuff (-8 faith)
67. Build narrow 2x10 room, verify "Cramped Room" debuff for width <3 (-5 faith)
68. Build 3x3 room (9 tiles), verify "Cramped Room" debuff for ≤10 tiles (-5 faith)
69. Build 4x4 room (16 tiles), verify no cramped debuff
70. Build 3x4 room (12 tiles, both dimensions ≥3), verify no cramped debuff

### Common Room Eating Bonus
71. Build room with table and chairs (Common Room)
72. Cook a "Decent" quality meal
73. Eat meal outside, verify +5 faith event
74. Cook another "Decent" quality meal
75. Eat meal inside Common Room, verify +8 faith event (Decent +1 = Good)
76. Build room without table (just chairs), verify NOT a Common Room
77. Eat in non-Common Room, verify no eating bonus

### Character Stats
78. Start with level 1 construction, build something, verify 1.5x time
79. Repeat until level up, verify speed improves
80. Build at high level, verify beauty bonus applied
81. Craft items, verify crafting XP gained
82. Gather resources, verify gathering XP gained
83. Level up gathering, verify improved yield

### Bed and Stats UI
84. Build bed in owned room
85. Click bed, verify stats UI opens
86. Verify stats display correctly
87. Click "Save & Rest", verify data saved
88. Reload round, verify stats persist

### Charge Requirements
89. Reduce charge to below 5
90. Try to craft, verify blocked with message
91. Try to gather resources, verify blocked with message
92. Restore charge above 5, verify can work again

### Extended Gathering
93. Start chopping tree, interrupt halfway
94. Verify progress is saved on tree
95. Resume chopping, verify progress continues
96. Another player continues, verify progress shared
97. Complete gathering, verify yield based on gathering stat

### Faith Drain from Work
98. Note starting faith value
99. Chop full tree (300 work), verify faith decreased by ~30
100. Craft a 20-work item, verify faith decreased by ~2
101. Build a structure (50 work), verify faith decreased by ~5
102. Verify faith drain is direct (not a faith event in the list)
103. Verify comfortable room passive faith gain can offset work drain

### Cooking System
104. Build cooking station (pot/campfire)
105. Add raw meat, cook it, verify roasted meat created
106. Eat roasted meat, verify charge is restored
107. Verify faith event "Ate a decent meal" appears (+5 faith)
108. Cook excellent quality meal, eat it
109. Verify faith event upgrades to "Ate an excellent meal" (+12 faith)
110. Eat a poor quality meal while excellent event active
111. Verify faith event stays at excellent (highest quality wins)
112. Wait 5 minutes, verify meal faith event expires
113. Test cooking stat affects final quality
114. Build Kitchen room, cook inside, verify +1 quality tier
115. Interrupt cooking early, verify meal is burnt (-2 quality tiers)
116. Verify cooking XP gained from completing recipes
117. Level up cooking stat, verify speed and quality improve
