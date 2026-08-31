# Resurgence Outpost - Research System

## Overview

Add a research system that gates access to recipes and blueprints. Players start with only basic survival recipes and must research nodes to unlock more advanced options.

---

## Research Tree Design

### TIER 0 - Starting (Always Available)

**Crafting Table:**
- Metal Rods, Rope (all variants), Fertilizer
- Wooden Hatchet, Improvised Pickaxe, Wooden Bucket
- Cable Coil

**Forge:**
- Basic smelting (Metal, Glass, Silver, Gold, Sandstone)
- Iron Ore from Rock

**Loom:**
- Cloth (from cotton)

**Blueprints:**
- Wood wall, Wood door, Wood floor
- Sandstone wall
- Sandstone floor
- Sandstone door
- Primitive forge, Primitive loom
- Chair, Table, Rack, Stool
- Wooden crate
- Bed (Wooden Sleeper)
- **Research Station** (10 wood + 5 metal)

---

### TIER 1 - Foundation

| Node | Prereq | Unlocks |
|------|--------|---------|
| **Woodworking** | - | Crafting: Wooden Scythe. Blueprints: Crafting table, Table frame, Winged chair, Pew variants, Bookcase, Dresser, Dog bed, Easel, Ore box, Coffin, Large crate, Wooden barricade |
| **Metallurgy** | - | Forge: Iron Hatchet, Pickaxe, Shovel, Crowbar, Compact variants. Blueprints: Forge, Iron wall, Iron floor, Iron door, Metal crate |
| **Textiles** | - | Loom: Backpack, Satchel. Blueprints: Loom|

---

### TIER 2 - Specialization

| Node | Prereq | Unlocks |
|------|--------|---------|
| **Agriculture** | Woodworking | Blueprints: Seed extractor |
| **Artistry** | Woodworking | Crafting: All Canvas sizes, Painting Frame. Blueprints: Sign, Noticeboard |
| **Papercraft** | Textiles | Crafting: Paper, Pens, Folders, Clipboard, Paper Bin, Hand Labeler, Stamps. Blueprints: Filing cabinet, Chest drawer |
| **Flooring** | Textiles | Crafting: All Carpet tiles |
| **Harvesting Tech** | Woodworking + Metallurgy | Crafting: Simple Harvester |
| **Culinary** | Metallurgy | Forge: Beaker, Large Beaker, Bowl, Kitchen Knife, Universal Enzyme. Blueprints: Meat spike, Stove, Griddle, Food processor, Meat grinder, Grinder, Condiment station |
| **Machine Fabrication** | Metallurgy | Blueprints: Machine fabricator, Resources recorder |
| **Cleaning** | Metallurgy | Crafting: Push Broom, Spray Can, Trash Bag. Blueprints: Trash bin, Trash cart |
---

### TIER 3 - Advanced

| Node | Prereq | Unlocks |
|------|--------|---------|
| **Advanced Metallurgy** | Metallurgy | Forge: Plasteel, Silver Pickaxe, Ash Plating. Crafting: Plasteel Floor Tiles. Blueprints: Reinforced wall |
| **Faith Weaving** | Textiles | Loom: Simple Azure Faith Fabric |
| **Basic Music** | Woodworking | Crafting: Recorder, Harmonica, Banjo, Bike Horn |
---

### TIER 4 - Expert

| Node | Prereq | Unlocks |
|------|--------|---------|
| **Advanced Weaving** | Faith Weaving | Loom: Advanced Azure Faith Fabric, Duffel Bag, Explorer Backpack, Leather Satchel |
| **Fine Furniture** | Woodworking + Metallurgy | Blueprints: Comfy chair, Office chair, Sofa variants, Bar stool |
| **Advanced Music** | Basic Music + Metallurgy | Crafting: Violin, Guitar, Accordion, Trumpet, Saxophone, Glockenspiel, Musical Moth |
| **Advanced Cleaning** | Cleaning | Crafting: Infinite Spray Can, Trash Bag of Holding, Janitor Chem Sprayer |
| **Communications** | Metallurgy | Crafting: All Radio Headsets |
| **Storage Tech** | Metallurgy | Blueprints: Freezer, Fridge, Shower frame |

---

### TIER 5 - Master

| Node | Prereq | Unlocks |
|------|--------|---------|
| **Master Weaving** | Advanced Weaving | Loom: Elegant Azure Faith Fabric, All dynamic clothing |
| **Industrial** | Advanced Metallurgy + Harvesting Tech | Forge: Advanced Harvester |
| **Master Music** | Advanced Music + Luxury Decor | Crafting: Golden Violin, Synthesizer, Synthesizer Headphones |
| **Luxury Decor** | Advanced Metallurgy | Crafting: Royal Carpets. Blueprints: Gold wall, Silver wall, Gold door, Silver door |

---

## Design Decisions

1. **Research Cost**: Faith points
   - Tier 1: 100 faith
   - Tier 2: 200 faith
   - Tier 3: 300 faith
   - Tier 4: 400 faith
   - Tier 5: 500 faith

2. **Research Scope**: Global (shared across all players)
   - One player researches a node, all players benefit
   - Stored on the research station or global datum

3. **Research Station**: Always available from the start (no prerequisites)
   - Add to Tier 0 blueprints

4. **UI Display**: Show locked recipes grayed out with "Requires: [Node]" tooltip
   - Players can see what's available to unlock
   - Encourages progression

---

## Recipe-to-Node Mapping

### Crafting Table

| Recipe | Node Required |
|--------|---------------|
| Metal Rods, Rope variants, Fertilizer, Wooden Hatchet, Improvised Pickaxe, Wooden Bucket, Cable Coil | (none) |
| Wooden Scythe | Woodworking |
| All Canvas, Painting Frame | Artistry |
| Paper, Pens, Folders, Clipboard, Paper Bin, Hand Labeler, Stamps | Papercraft |
| All Carpets (non-royal) | Flooring |
| Royal Carpets | Luxury Decor |
| Simple Harvester | Harvesting Tech |
| Push Broom, Spray Can, Trash Bag | Cleaning |
| Infinite Spray Can, Trash Bag of Holding, Janitor Chem Sprayer | Advanced Cleaning |
| Recorder, Harmonica, Banjo, Bike Horn | Basic Music |
| Violin, Guitar, Accordion, Trumpet, Saxophone, Glockenspiel, Musical Moth | Advanced Music |
| Golden Violin, Synthesizers | Master Music |
| Plasteel Floor Tiles | Advanced Metallurgy |
| All Radio Headsets | Communications |

### Forge

| Recipe | Node Required |
|--------|---------------|
| Metal Sheet, Glass Sheet, Silver Sheet, Gold Sheet, Sandstone, Iron Ore (Rock) | (none) |
| Iron Hatchet, Pickaxe, Compact Pickaxe, Shovel, Crowbar, Compact Crowbar, Scythe | Metallurgy |
| Silver Pickaxe, Plasteel, Ash Plating | Advanced Metallurgy |
| Beaker, Large Beaker, Bowl, Kitchen Knife, Universal Enzyme | Culinary |
| Advanced Harvester | Industrial |

### Loom

| Recipe | Node Required |
|--------|---------------|
| Cloth | (none) |
| Backpack, Satchel | Textiles |
| Duffel Bag, Explorer Backpack, Leather Satchel | Advanced Weaving |
| Simple Azure Faith Fabric | Faith Weaving |
| Advanced Azure Faith Fabric | Advanced Weaving |
| Elegant Azure Faith Fabric, All Clothing | Master Weaving |

### Blueprints

| Blueprint | Node Required |
|-----------|---------------|
| Wood wall, Wood door, Wood floor, Sandstone wall, Sandstone floor, Sandstone door, Primitive forge, Primitive loom, Chair, Table, Rack, Stool, Wooden crate, Bed, Research station | (none) |
| Crafting table, Winged chair, Pew variants, Bookcase, Dresser, Dog bed, Easel, Ore box, Coffin, Large crate, Wooden barricade, Table frame | Woodworking |
| Forge, Iron wall, Iron floor, Iron door, Metal crate | Metallurgy |
| Loom | Textiles |
| Seed extractor | Agriculture |
| Sign, Noticeboard | Artistry |
| Filing cabinet, Chest drawer | Papercraft |
| Meat spike, Stove, Griddle, Food processor, Meat grinder, Grinder, Condiment station | Culinary |
| Reinforced wall | Advanced Metallurgy |
| Comfy chair, Office chair, Sofas, Bar stool | Fine Furniture |
| Gold wall, Silver wall, Gold door, Silver door | Luxury Decor |
| Freezer, Fridge, Shower frame | Storage Tech |
| Machine fabricator, Resources recorder | Machine Fabrication |
| Trash bin, Trash cart | Cleaning |

---

## Files to Create/Modify

| File | Action |
|------|--------|
| `code/modules/resurgence_outpost/research/research_nodes.dm` | **CREATE** - Define all 22 research node datums |
| `code/modules/resurgence_outpost/research/research_manager.dm` | **CREATE** - Global research state singleton |
| `code/modules/resurgence_outpost/research/research_station.dm` | **CREATE** - Research station structure + TGUI |
| `tgui/packages/tgui/interfaces/ResurgenceResearch.js` | **CREATE** - Tech tree UI |
| `code/modules/resurgence_outpost/structures/crafting_table.dm` | **MODIFY** - Add research_required to recipes, filter in ui_data |
| `code/modules/resurgence_outpost/structures/forge.dm` | **MODIFY** - Add research_required to recipes |
| `code/modules/resurgence_outpost/structures/loom.dm` | **MODIFY** - Add research_required to recipes |
| `code/modules/resurgence_outpost/tools/outpost_planner.dm` | **MODIFY** - Add research filtering to blueprint lists |
| `code/modules/resurgence_outpost/blueprints/blueprint_types.dm` | **MODIFY** - Add research_required var + research station blueprint |
| `tgui/packages/tgui/interfaces/ResurgenceCrafting.js` | **MODIFY** - Show locked recipes grayed out |
| `tgui/packages/tgui/interfaces/OutpostPlanner.js` | **MODIFY** - Show locked blueprints grayed out |
| `lobotomy-corp13.dme` | **MODIFY** - Include new research files |

---

## Technical Architecture

### Global Research State

The research system uses a **global singleton datum** that persists across the entire game session. This ensures all players share the same research progress.

```dm
// Global variable - initialized on world start
GLOBAL_DATUM(resurgence_research, /datum/resurgence_research_manager)

/datum/resurgence_research_manager
    /// List of researched node IDs: list("woodworking", "metallurgy", ...)
    var/list/researched_nodes = list()

    /// All node datums by ID: list("woodworking" = /datum/resurgence_research_node/woodworking)
    var/list/all_nodes = list()
```

**Key Design Decisions:**
1. **Singleton Pattern**: Only one instance exists, accessed via `GLOB.resurgence_research`
2. **String IDs**: Nodes use string identifiers (e.g., "woodworking") for easy recipe/blueprint mapping
3. **Persistence**: Can be saved/loaded if round persistence is added later
4. **No Player Binding**: Research is collective - any player can contribute, all benefit

---

### How Outpost Planners Access Research

**Current Behavior:**
- `outpost_planner.dm` uses a static list `blueprint_categories` initialized once
- Categories map display names to blueprint type paths
- UI calls `ui_data()` which iterates through categories

**New Behavior with Research:**
The outpost planner will check research status when building the UI data, NOT when initializing categories. This means:

1. **Categories remain static** - No change to `init_blueprint_categories()`
2. **Research check happens in `ui_data()`** - Each blueprint is checked against global research state
3. **All planners (existing and future)** automatically respect research because they all use the same global state

```dm
/obj/item/resurgence_outpost_planner/ui_data(mob/user)
    // ... existing code ...

    // For each blueprint in category:
    var/obj/structure/resurgence_blueprint/BP = blueprint_type
    var/research_req = initial(BP.research_required)
    var/is_locked = FALSE
    var/lock_reason = null

    if(research_req && !GLOB.resurgence_research.is_researched(research_req))
        is_locked = TRUE
        lock_reason = GLOB.resurgence_research.get_node_name(research_req)

    // Add to UI data with lock status
    blueprint_data += list(list(
        "name" = name,
        "path" = "[blueprint_type]",
        "is_locked" = is_locked,
        "lock_reason" = lock_reason
    ))
```

**Why This Works for All Planners:**
- The outpost planner is an **item** (`/obj/item/resurgence_outpost_planner`)
- Every instance uses the same static `blueprint_categories` list
- Research check uses `GLOB.resurgence_research` - globally shared
- No per-planner state needed; all planners see the same research status
- Future planners created via crafting/spawning automatically inherit this behavior

---

### Crafting Table Research Integration

**Current Recipe Structure:**
```dm
recipes["Iron Hatchet"] = list(
    "result" = /obj/item/hatchet/resurgence,
    "result_amount" = 1,
    "materials" = list(/obj/item/stack/sheet/metal = 3),
    "total_work" = 20,
    "desc" = "3 Metal -> Iron Hatchet",
    "category" = CRAFT_CAT_SMELTING
)
```

**New Recipe Structure with Research:**
```dm
recipes["Iron Hatchet"] = list(
    "result" = /obj/item/hatchet/resurgence,
    "result_amount" = 1,
    "materials" = list(/obj/item/stack/sheet/metal = 3),
    "total_work" = 20,
    "desc" = "3 Metal -> Iron Hatchet",
    "category" = CRAFT_CAT_SMELTING,
    "research_required" = "metallurgy"  // NEW: Node ID or null
)
```

**Research Check in Base Crafting Table:**
The base `/obj/structure/resurgence_crafting_table` class handles research checking:

```dm
/obj/structure/resurgence_crafting_table/proc/is_recipe_available(recipe_name)
    var/list/recipe = recipes[recipe_name]
    if(!recipe)
        return FALSE

    var/research_req = recipe["research_required"]
    if(!research_req)
        return TRUE  // No research needed

    return GLOB.resurgence_research.is_researched(research_req)

/obj/structure/resurgence_crafting_table/ui_data(mob/user)
    // ... build recipe list ...
    for(var/recipe_name in recipes)
        var/list/recipe = recipes[recipe_name]
        var/research_req = recipe["research_required"]
        var/is_locked = FALSE
        var/lock_reason = null

        if(research_req && !GLOB.resurgence_research.is_researched(research_req))
            is_locked = TRUE
            lock_reason = GLOB.resurgence_research.get_node_name(research_req)

        recipe_list += list(list(
            // ... existing fields ...
            "is_locked" = is_locked,
            "lock_reason" = lock_reason
        ))
```

**Crafting Action Check:**
```dm
/obj/structure/resurgence_crafting_table/ui_act(action, params)
    if(action == "start_craft")
        var/recipe_name = params["recipe"]
        if(!is_recipe_available(recipe_name))
            to_chat(usr, span_warning("This recipe requires research!"))
            return TRUE
        // ... continue with normal crafting ...
```

---

### Primitive vs Non-Primitive Crafting Tables

**Current Design:**
- **Primitive Forge/Loom**: Override `init_recipes()` with a restricted subset
- **Full Forge/Loom**: Have complete recipe lists
- Primitive versions are slower (2x work time) and limited in what they can make

**Research Impact:**
1. **Primitive tables are NOT affected by research** - Their recipes are already Tier 0
2. **Full tables check research** - But inherit the same base class behavior
3. **No special interaction needed** - Primitive tables simply don't have locked recipes

**Reasoning:**
- Primitive forge only has: Metal/Glass/Silver/Gold/Sandstone smelting → All Tier 0
- Primitive loom only has: Cloth, Rope → All Tier 0
- These recipes have `"research_required" = null` (or field omitted)
- The `is_recipe_available()` check returns TRUE for null research requirements

**Upgrade Path (Primitive → Full):**
| Station | Unlocked By | Gains Access To |
|---------|-------------|-----------------|
| Primitive Forge → Forge | Metallurgy | Iron tools, Pickaxe, Crowbar, etc. |
| Primitive Loom → Loom | Textiles | Backpack, Satchel, faith fabrics, clothing |

**Blueprint Progression:**
1. Start: Can build Primitive Forge, Primitive Loom (Tier 0)
2. Research Metallurgy: Unlocks Forge blueprint
3. Research Textiles: Unlocks Loom blueprint
4. Build full versions to access researched recipes

---

### Recipe Inheritance and Research

**How Recipes Flow:**
```
/obj/structure/resurgence_crafting_table (base)
    └── init_recipes() - Basic crafting table recipes
    └── is_recipe_available() - Checks GLOB.resurgence_research

/obj/structure/resurgence_crafting_table/forge (subtype)
    └── init_recipes() - Override with forge recipes (smelting, tools)
    └── is_recipe_available() - Inherits from base, works identically

    /obj/structure/resurgence_crafting_table/forge/primitive (sub-subtype)
        └── init_recipes() - Override with restricted Tier 0 only
        └── is_recipe_available() - Inherits, but all recipes are Tier 0
```

**Key Points:**
1. `is_recipe_available()` is defined ONCE in the base class
2. All subtypes (forge, loom, primitive variants) inherit it
3. Research checking is automatic for any recipe that has `"research_required"`
4. Primitive variants work because their recipes lack research requirements

---

### Blueprint Research on Structures

**New Variable on Blueprints:**
```dm
/obj/structure/resurgence_blueprint
    /// Research node required to build this (null = always available)
    var/research_required = null

/obj/structure/resurgence_blueprint/forge
    research_required = "metallurgy"

/obj/structure/resurgence_blueprint/loom
    research_required = "textiles"

// Primitive versions have no requirement
/obj/structure/resurgence_blueprint/primitive_forge
    research_required = null

/obj/structure/resurgence_blueprint/primitive_loom
    research_required = null
```

**Placement Check:**
When a player attempts to place a blueprint via the outpost planner, the UI prevents locked selections. As a safety backup:

```dm
/obj/item/resurgence_outpost_planner/proc/place_blueprint(turf/T, mob/user)
    if(!selected_blueprint)
        return

    // Safety check - shouldn't happen if UI works correctly
    var/obj/structure/resurgence_blueprint/BP = selected_blueprint
    var/research_req = initial(BP.research_required)
    if(research_req && !GLOB.resurgence_research.is_researched(research_req))
        to_chat(user, span_warning("This blueprint requires research: \
            [GLOB.resurgence_research.get_node_name(research_req)]!"))
        return

    // ... proceed with placement ...
```

---

## Implementation Steps

### Step 1: Create Research Manager (Global State)
- Create `/datum/resurgence_research_manager` singleton
- Add `GLOBAL_DATUM_INIT(resurgence_research, /datum/resurgence_research_manager, new)`
- Track researched nodes in a list
- Procs: `is_researched(node_id)`, `research_node(node_id, mob/user)`, `get_node_by_id(id)`, `get_available_nodes()`, `get_node_name(id)`
- Initialize all node datums on `New()`

### Step 2: Create Research Nodes
- Define `/datum/resurgence_research_node` base type
- Create subtypes with proper prerequisites
- Each node has: id, name, desc, tier, faith_cost, prerequisites list
- Register nodes with manager on creation

### Step 3: Modify Base Crafting Table
- Add `is_recipe_available(recipe_name)` proc to base class
- Modify `ui_data()` to include `is_locked` and `lock_reason` for each recipe
- Modify `ui_act()` to check availability before starting craft
- Add `"research_required"` field to all recipes (null for Tier 0)

### Step 4: Modify Forge Recipes
- Add `"research_required" = "metallurgy"` to iron tool recipes
- Add `"research_required" = "advanced_metallurgy"` to advanced recipes
- Add `"research_required" = "culinary"` to kitchen recipes
- Primitive forge recipes remain without research requirements

### Step 5: Modify Loom Recipes
- Add `"research_required" = "textiles"` to backpack/satchel
- Add `"research_required" = "faith_weaving"` to simple faith fabric
- Add `"research_required" = "advanced_weaving"` to advanced items
- Add `"research_required" = "master_weaving"` to clothing/elegant fabric
- Primitive loom recipes remain without research requirements

### Step 6: Modify Blueprint Types
- Add `research_required` var to `/obj/structure/resurgence_blueprint`
- Set appropriate research requirement on each blueprint subtype
- Primitive forge/loom blueprints have `research_required = null`

### Step 7: Modify Outpost Planner
- Update `ui_data()` to check research status for each blueprint
- Include `is_locked` and `lock_reason` in blueprint data
- Add safety check in `place_blueprint()` proc

### Step 8: Update TGUI Interfaces
- **ResurgenceCrafting.js**: Show locked recipes grayed out with lock icon
- **OutpostPlanner.js**: Show locked blueprints grayed out with requirement text
- Both: Add tooltip showing "Requires: [Node Name]"

### Step 9: Create Research Station
- `/obj/structure/resurgence_research_station` structure
- Add to Tier 0 blueprints in outpost planner
- TGUI interface showing tech tree with nodes, lines, and status

### Step 10: Create Research UI (TGUI)
- **ResurgenceResearch.js**: Tech tree visualization
- Node boxes with tier grouping
- Lines showing prerequisites
- Color coding: green=researched, blue=available, gray=locked
- Click to research (checks prerequisites and faith cost)
- Show current faith and cost for each node

---

## UI Design (Rimworld-Style Tech Tree)

### Layout Overview

The research UI uses a **horizontal scrollable tree** layout similar to Rimworld:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  [Faith: 450]                              Resurgence Research              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   TIER 1          TIER 2           TIER 3          TIER 4         TIER 5   │
│                                                                             │
│  ┌──────────┐                     ┌──────────┐                              │
│  │Woodwork- │────────────────────▶│Basic     │                              │
│  │ing       │──┐                  │Music     │───┐                          │
│  │ 100 ⛪   │  │   ┌──────────┐   │ 300 ⛪   │   │    ┌──────────┐          │
│  └──────────┘  ├──▶│Agriculture│  └──────────┘   │    │Advanced  │          │
│                │   │ 200 ⛪   │                  ├───▶│Music     │──┐       │
│  ┌──────────┐  │   └──────────┘   ┌──────────┐   │    │ 400 ⛪   │  │       │
│  │Metallurgy│──┤                  │Harvesting│───┘    └──────────┘  │       │
│  │ 100 ⛪   │  │   ┌──────────┐   │Tech      │                      │       │
│  └──────────┘  ├──▶│Artistry  │   │ 300 ⛪   │   ┌──────────┐       │       │
│       │        │   │ 200 ⛪   │   └──────────┘   │Fine      │       │       │
│       │        │   └──────────┘        ▲        │Furniture │       │       │
│       │        │                       │        │ 400 ⛪   │       │       │
│       ├────────┼───────────────────────┘        └──────────┘       │       │
│       │        │                                     ▲             │       │
│       │        │   ┌──────────┐                      │             │       │
│       ├────────┴──▶│Culinary  │                      │             │       │
│       │            │ 200 ⛪   │                      │             │       │
│       │            └──────────┘                      │             ▼       │
│       │                                         ┌──────────┐  ┌──────────┐ │
│       │                                         │Luxury    │  │Master    │ │
│       └────────────────────────────────────────▶│Decor     │─▶│Music     │ │
│                    ┌──────────┐   ┌──────────┐  │ 500 ⛪   │  │ 500 ⛪   │ │
│  ┌──────────┐      │Papercraft│   │Advanced  │  └──────────┘  └──────────┘ │
│  │Textiles  │─────▶│ 200 ⛪   │   │Metallurgy│       ▲                     │
│  │ 100 ⛪   │      └──────────┘   │ 300 ⛪   │───────┘                     │
│  └──────────┘           │        └──────────┘                              │
│       │                 │              │        ┌──────────┐               │
│       │            ┌──────────┐        │        │Industrial│               │
│       │            │Flooring  │        └───────▶│ 500 ⛪   │               │
│       │            │ 200 ⛪   │                  └──────────┘               │
│       │            └──────────┘                       ▲                    │
│       │                                               │                    │
│       │            ┌──────────┐   ┌──────────┐   ┌──────────┐              │
│       └───────────▶│Faith     │──▶│Advanced  │──▶│Master    │              │
│                    │Weaving   │   │Weaving   │   │Weaving   │              │
│                    │ 300 ⛪   │   │ 400 ⛪   │   │ 500 ⛪   │              │
│                    └──────────┘   └──────────┘   └──────────┘              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Node Box Design

Each research node is a rectangular box:

```
┌────────────────┐
│  Node Name     │  ← Bold title
│                │
│   100 ⛪       │  ← Faith cost with icon
│                │
│  [Research]    │  ← Button (if available)
└────────────────┘
```

**Node States & Colors:**

| State | Background | Border | Text |
|-------|------------|--------|------|
| **Researched** | Dark green (#1a472a) | Bright green (#4a4) | White |
| **Available** | Dark gold (#3d3d00) | Yellow (#aa0) | White |
| **Locked** | Dark gray (#2a2a2a) | Gray (#555) | Gray (#888) |
| **In Progress** | Dark blue (#1a1a3d) | Blue (#55f) | White |

### Connecting Lines

Lines show prerequisite relationships:
- **Start** from the right edge of prerequisite node
- **End** at the left edge of dependent node
- Use SVG paths with bezier curves for smooth connections
- Line color matches the prerequisite node's state:
  - Green line = prerequisite is researched
  - Gray line = prerequisite not researched

```jsx
// SVG path example for prerequisite line
<line
  x1={prereqNode.x + nodeWidth}
  y1={prereqNode.y + nodeHeight/2}
  x2={currentNode.x}
  y2={currentNode.y + nodeHeight/2}
  stroke={prereqResearched ? "#4a4" : "#555"}
  strokeWidth={2}
/>
```

### Node Positioning (Grid Layout)

Nodes are positioned in a grid based on tier:

```javascript
const TIER_X_POSITIONS = {
  1: 50,    // Tier 1 starts at x=50
  2: 220,   // Tier 2 at x=220
  3: 390,   // Tier 3 at x=390
  4: 560,   // Tier 4 at x=560
  5: 730,   // Tier 5 at x=730
};

const NODE_WIDTH = 140;
const NODE_HEIGHT = 80;
const NODE_VERTICAL_GAP = 20;
```

### Node Y-Position Algorithm

Nodes within each tier are positioned vertically based on their prerequisites:

1. **Tier 1 nodes**: Evenly distributed vertically
2. **Later tiers**: Positioned to minimize line crossings
   - If single prerequisite: align Y with prerequisite
   - If multiple prerequisites: center between them

```javascript
// Simplified positioning logic
function calculateNodeY(node, allNodes) {
  if (node.tier === 1) {
    return node.tierIndex * (NODE_HEIGHT + NODE_VERTICAL_GAP);
  }

  const prereqNodes = node.prerequisites.map(id => allNodes[id]);
  if (prereqNodes.length === 1) {
    return prereqNodes[0].y;
  }

  // Center between prerequisites
  const minY = Math.min(...prereqNodes.map(n => n.y));
  const maxY = Math.max(...prereqNodes.map(n => n.y));
  return (minY + maxY) / 2;
}
```

### Complete Node Layout Map

```
TIER 1 (x=50)           TIER 2 (x=220)         TIER 3 (x=390)
─────────────           ──────────────         ──────────────
y=0:   Woodworking      y=0:   Agriculture     y=0:   Basic Music
y=100: Metallurgy       y=100: Artistry        y=100: Harvesting Tech
y=200: Textiles         y=200: Papercraft      y=200: Adv. Metallurgy
                        y=300: Flooring        y=300: Faith Weaving
                        y=400: Culinary
                        y=500: Machine Fab.
                        y=600: Cleaning

TIER 4 (x=560)          TIER 5 (x=730)
──────────────          ──────────────
y=0:   Advanced Music   y=0:   Master Music
y=100: Fine Furniture   y=100: Industrial
y=200: Adv. Weaving     y=200: Master Weaving
y=300: Luxury Decor
y=400: Adv. Cleaning
y=500: Communications
y=600: Storage Tech
```

### TGUI Component Structure

```jsx
// ResurgenceResearch.js
export const ResurgenceResearch = (props, context) => {
  const { data, act } = useBackend(context);
  const { nodes, current_faith, researched_nodes } = data;

  return (
    <Window width={900} height={600} title="Resurgence Research">
      <Window.Content>
        <Stack vertical fill>
          {/* Header with faith display */}
          <Stack.Item>
            <Section>
              <Box bold fontSize="16px">
                Faith Available: {current_faith} ⛪
              </Box>
            </Section>
          </Stack.Item>

          {/* Scrollable research tree */}
          <Stack.Item grow>
            <Section fill scrollable>
              <ResearchTree
                nodes={nodes}
                researched={researched_nodes}
                onResearch={nodeId => act('research', { node: nodeId })}
              />
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

// Research tree with SVG for lines
const ResearchTree = (props) => {
  const { nodes, researched, onResearch } = props;

  return (
    <Box position="relative" width="800px" height="700px">
      {/* SVG layer for connecting lines */}
      <svg
        style={{
          position: 'absolute',
          top: 0,
          left: 0,
          width: '100%',
          height: '100%',
          pointerEvents: 'none',
        }}
      >
        {nodes.map(node =>
          node.prerequisites.map(prereqId => (
            <PrerequisiteLine
              key={`${prereqId}-${node.id}`}
              from={nodes.find(n => n.id === prereqId)}
              to={node}
              researched={researched.includes(prereqId)}
            />
          ))
        )}
      </svg>

      {/* Node boxes */}
      {nodes.map(node => (
        <ResearchNode
          key={node.id}
          node={node}
          isResearched={researched.includes(node.id)}
          isAvailable={canResearch(node, researched)}
          onResearch={() => onResearch(node.id)}
        />
      ))}
    </Box>
  );
};
```

### Node Component

```jsx
const ResearchNode = (props) => {
  const { node, isResearched, isAvailable, onResearch } = props;

  const backgroundColor = isResearched
    ? 'rgba(26, 71, 42, 0.9)'    // Dark green
    : isAvailable
      ? 'rgba(61, 61, 0, 0.9)'   // Dark gold
      : 'rgba(42, 42, 42, 0.9)'; // Dark gray

  const borderColor = isResearched
    ? '#4a4'   // Bright green
    : isAvailable
      ? '#aa0' // Yellow
      : '#555'; // Gray

  return (
    <Box
      position="absolute"
      left={`${node.x}px`}
      top={`${node.y}px`}
      width="140px"
      height="80px"
      style={{
        backgroundColor,
        border: `2px solid ${borderColor}`,
        borderRadius: '4px',
        padding: '8px',
      }}
    >
      <Box bold color={isResearched || isAvailable ? 'white' : '#888'}>
        {node.name}
      </Box>
      <Box color={isResearched || isAvailable ? '#ccc' : '#666'}>
        {node.faith_cost} ⛪
      </Box>
      {isAvailable && !isResearched && (
        <Button
          content="Research"
          color="yellow"
          onClick={onResearch}
        />
      )}
      {isResearched && (
        <Box color="#4a4" italic>Researched</Box>
      )}
    </Box>
  );
};
```

### Prerequisite Line Component

```jsx
const PrerequisiteLine = (props) => {
  const { from, to, researched } = props;

  // Calculate line endpoints
  const x1 = from.x + 140; // Right edge of prereq
  const y1 = from.y + 40;  // Vertical center
  const x2 = to.x;         // Left edge of target
  const y2 = to.y + 40;    // Vertical center

  // Control points for bezier curve
  const midX = (x1 + x2) / 2;

  return (
    <path
      d={`M ${x1} ${y1} C ${midX} ${y1}, ${midX} ${y2}, ${x2} ${y2}`}
      fill="none"
      stroke={researched ? '#4a4' : '#555'}
      strokeWidth={2}
    />
  );
};
```

### Data Structure from Server

```dm
/obj/structure/resurgence_research_station/ui_data(mob/user)
    var/list/data = list()

    // Current player faith
    var/obj/item/organ/resurgence_core/core = get_resurgence_core(user)
    data["current_faith"] = core ? core.faith : 0

    // All nodes with positions
    var/list/nodes = list()
    for(var/datum/resurgence_research_node/node in GLOB.resurgence_research.all_nodes)
        nodes += list(list(
            "id" = node.id,
            "name" = node.name,
            "desc" = node.desc,
            "tier" = node.tier,
            "faith_cost" = node.faith_cost,
            "prerequisites" = node.prerequisites,
            "x" = node.ui_x,
            "y" = node.ui_y
        ))
    data["nodes"] = nodes

    // List of researched node IDs
    data["researched_nodes"] = GLOB.resurgence_research.researched_nodes

    return data
```

### Hover Tooltip

When hovering over a node, show a tooltip with details:

```
┌─────────────────────────────────┐
│ Advanced Metallurgy             │
├─────────────────────────────────┤
│ Cost: 300 Faith                 │
│                                 │
│ Requires: Metallurgy            │
│                                 │
│ Unlocks:                        │
│ • Forge: Plasteel, Silver Pick  │
│ • Crafting: Plasteel Floor      │
│ • Blueprint: Reinforced Wall    │
└─────────────────────────────────┘
```

### Mobile/Window Sizing

The tree should be scrollable within the window:
- **Window size**: 900x600 pixels
- **Tree canvas**: 850x700 pixels (scrollable)
- **Scroll**: Both horizontal and vertical if needed

### Research Animation

When a node is researched:
1. Flash the node border bright
2. Change color from gold to green
3. Update connected lines to green
4. Play a completion sound
