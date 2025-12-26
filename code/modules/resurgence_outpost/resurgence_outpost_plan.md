# Resurgence Outpost - Simplified Core Mechanics Plan

## Overview

Focus on basic survival building mechanics first. Players gather resources, build structures, and contribute to a central statue.

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
| Contributed to monument | +15 | 5 min | "monument" |
| Near other machines | +5 | While nearby | "community" |
| Ate/recharged | +3 | 3 min | "sustenance" |
| Witnessed death | -20 | 10 min | "death" |
| Injured | -5 | Until healed | "injury" |
| In completed shelter | +5 | While inside | "shelter" |
| Low charge warning | -10 | While low | "charge_anxiety" |

### Charge (Passive Decay)
Charge no longer regenerates passively. It only decays.

**Changes from current system:**
- Remove `charge_regen_rate` (no passive regen)
- Add `charge_decay_rate` (base: 0.5 per life tick)
- Decay rate modified by faith level

**Charge Decay Formula:**
```dm
var/decay_modifier = get_faith_decay_modifier()  // 0.5 to 1.5 based on faith
var/actual_decay = charge_decay_rate * decay_modifier
adjust_charge(-actual_decay)
```

**Restoring Charge:**
- Consuming power cells/batteries
- Using charging stations
- Resting at powered structures
- Special items/abilities

### Updated Core Procs
```dm
/obj/item/organ/resurgence_core
    var/charge = 100
    var/max_charge = 100
    var/charge_decay_rate = 0.5  // per life tick (replaces regen)

    var/faith = 50              // Calculated from events
    var/max_faith = 100
    var/list/faith_events = list()  // category -> /datum/faith_event

/obj/item/organ/resurgence_core/proc/add_faith_event(category, datum/faith_event/event)
    // Replace existing event in same category
    if(faith_events[category])
        qdel(faith_events[category])
    faith_events[category] = event
    recalculate_faith()

/obj/item/organ/resurgence_core/proc/clear_faith_event(category)
    if(faith_events[category])
        qdel(faith_events[category])
        faith_events -= category
    recalculate_faith()

/obj/item/organ/resurgence_core/proc/recalculate_faith()
    var/total = 50  // Base faith
    for(var/category in faith_events)
        var/datum/faith_event/event = faith_events[category]
        total += event.faith_change
    faith = clamp(total, 0, max_faith)

/obj/item/organ/resurgence_core/proc/get_faith_decay_modifier()
    if(faith >= 80)
        return 0.5   // Inspired - 50% slower decay
    if(faith >= 60)
        return 0.75  // Steady - 25% slower
    if(faith >= 40)
        return 1.0   // Neutral - normal
    if(faith >= 20)
        return 1.25  // Wavering - 25% faster
    return 1.5       // Despairing - 50% faster
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

## Basic Building Recipes

### Walls
- **Metal Wall**: 5 metal sheets
- **Wood Wall**: 5 wood planks

### Floors
- **Metal Floor Tile**: 1 metal sheet = 4 tiles
- **Wood Floor**: 2 wood planks

### Structures
- **Storage Chest**: 10 wood planks
  - Simple container that holds items
- **Workbench**: 15 metal sheets + 10 wood
  - Crafting station for advanced recipes

Use existing stack recipe system (`/datum/stack_recipe`) for these.

---

## Monument of Hope (Statue)

Simple tiered construction - each stage requires ONE resource type:

| Stage | Requirement | Description |
|-------|-------------|-------------|
| 1 | 100 Metal Sheets | Foundation |
| 2 | 75 Wood Planks | Framework |
| 3 | 50 Glass Sheets | Detailing |
| 4 | 25 Plasteel Sheets | Completion |

**Total**: ~250 material units across all stages

### Statue Mechanics
- Click statue with material stack to add
- Shows current progress when examined
- Announces to all players when stage completes
- Victory when stage 4 complete

---

## File Structure (Minimal)

```
code/modules/resurgence_outpost/
    statue.dm           # Monument structure
    structures.dm       # Chest, workbench, shelter
    recipes.dm          # Stack recipes for building

code/game/gamemodes/resurgence_outpost/
    resurgence_outpost.dm   # Basic gamemode (later)
```

---

## Implementation Order

### Step 1: Storage Chest
Simple container structure.

### Step 2: Building Recipes
Add stack recipes to existing materials:
- Metal sheets � metal wall, metal floor
- Wood � wood wall, chest

### Step 3: Monument Structure
Basic `attackby()` to accept materials, `examine()` to show progress.

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
- All placed structures (walls, floors, chests, workbench, monument)
- Contents of containers (chests, storage)
- Monument progress (current stage + materials contributed)
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
  "monument_stage": 2,
  "monument_progress": 45,
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
    var/list/meta = list("day" = GLOB.outpost_day, "monument_stage" = ...)
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
    statue.dm           # Monument structure
    structures.dm       # Chest, workbench, walls
    recipes.dm          # Stack recipes for building
    persistence.dm      # Save/load outpost state

code/modules/surgery/organs/
    resurgence_core.dm  # Updated with new faith/charge system

code/datums/
    faith_event.dm      # Faith event datum (mood-like system)

code/datums/faith_events/
    generic_events.dm   # Common faith events (community, injury, etc.)
    outpost_events.dm   # Outpost-specific events (monument, shelter)

code/game/gamemodes/resurgence_outpost/
    resurgence_outpost.dm   # Gamemode with 1.5hr timer

_maps/
    resurgence_outpost.dmm  # Base map (starting state)

data/resurgence_outpost/
    outpost_save.dmm        # Full map snapshot (generated at round end)
    outpost_meta.json       # Day number, monument progress, etc.
```

---

## Testing

### Building & Structures
1. Spawn chest, verify storage works
2. Build walls/floors from materials
3. Add materials to monument, verify stage progression
4. Complete all 4 stages, verify victory message

### Persistence
5. Let round timer expire, verify save is created
6. Start new round, verify structures reload correctly
7. Verify chest contents persist across rounds

### Faith & Charge System
8. Verify charge decays passively (no regen)
9. Add positive faith event, verify faith increases
10. Verify high faith slows charge decay
11. Add negative faith event, verify faith decreases
12. Verify low faith speeds up charge decay
13. Verify faith events with timeout expire correctly
14. Verify "Despairing" level applies movement penalty
15. Test monument contribution adds faith event
