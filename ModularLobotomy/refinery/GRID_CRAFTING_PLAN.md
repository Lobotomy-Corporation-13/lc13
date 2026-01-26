# Grid Crafting System Implementation Plan

## Overview
Port the grid crafting system from `refining_weapons/` to `ModularLobotomy/refinery/`, replacing ore-based "Cores" with PE-based "Condensed Enkephalin" and using ordeal clears instead of research for tier unlocking.

---

## Files to Create

### ModularLobotomy/refinery/grid_crafting/

| File | Purpose | Lines (est.) |
|------|---------|--------------|
| `_defines.dm` | Movement type and level constants | ~40 |
| `condensed_enkephalin.dm` | Navigation item (replaces ore_cores.dm) | ~200 |
| `enkephalin_refinery.dm` | PE box to enkephalin converter | ~400 |
| `grid_system.dm` | Grid coordinate and crafting logic | ~300 |
| `grid_station.dm` | The crafting station machine | ~350 |

### TGUI
| File | Purpose |
|------|---------|
| `tgui/packages/tgui/interfaces/EnkephalinGridStation.js` | React UI (adapt from GridCraftingStation.js) |

---

## Files to Modify

### 1. `code/controllers/subsystem/lobotomy_corp.dm`
- Add `var/ordeal_clear_count = 0` variable
- Register signal handler for `COMSIG_GLOB_ORDEAL_END` in Initialize()
- Add `OnOrdealClear()` proc to increment counter

---

## System Design

### Condensed Enkephalin Properties
Replaces "Cores" from the original system:

| Property | Determined By | Values |
|----------|---------------|--------|
| **Quality** (movement pattern) | PE filter used during refining | RED=Cardinal, WHITE=Diagonal, BLACK=Octagonal, PALE=Teleport |
| **Refinement Level** (base distance) | PE box quantity | Crude (1-2), Common (3-5), Refined (6-10), Exceptional (11-20), Legendary (21+) |
| **Purity** (distance modifier) | Blackjack minigame result | Impure (-50%), Low (-25%), Standard, High (+25%), Pure (+50%) |
| **Enhanced** (bonus) | Perfect minigame + 30% chance | +10-15% range bonus |

### Filter to Quality Mapping
Repurposes existing filter items from refinery.dm:
- **Blue filter** → RED quality (Cardinal movement: N/S/E/W)
- **Green filter** → WHITE quality (Diagonal movement: NE/NW/SE/SW)
- **Red filter** → BLACK quality (Octagonal movement: all 8 directions)
- **Yellow filter** → PALE quality (Teleport: any point in range)

### Tier Unlocking (Linear)
Based on `SSlobotomy_corp.ordeal_clear_count`:
- **0 clears**: Tier 0 only (Crude weapons)
- **1 clear**: Tier 0-1 (Common weapons)
- **2 clears**: Tier 0-2 (Refined weapons)
- **3 clears**: Tier 0-3 (Exceptional weapons)
- **4+ clears**: Tier 0-4 (Legendary weapons)

### Weapons
Same city weapons from the original system - discovered automatically via `/obj/item/ego_weapon/city` subtypes.

---

## Implementation Steps

### Step 1: Create Defines
Create `_defines.dm` with movement type constants (ENKEPH_MOVEMENT_CARDINAL, etc.), refinement levels, and purity levels.

### Step 2: Modify SSlobotomy_corp
Add ordeal tracking:
```dm
var/ordeal_clear_count = 0

/datum/controller/subsystem/lobotomy_corp/Initialize()
    // ... existing code ...
    RegisterSignal(SSdcs, COMSIG_GLOB_ORDEAL_END, PROC_REF(OnOrdealClear))

/datum/controller/subsystem/lobotomy_corp/proc/OnOrdealClear(datum/source, datum/ordeal/O)
    SIGNAL_HANDLER
    ordeal_clear_count++
```

### Step 3: Create Condensed Enkephalin Item
Adapt `ore_cores.dm` - replace ore type with enkeph_quality, fuel_level with purity_level. Use `ebox_refined` icon.

### Step 4: Create Enkephalin Refinery
Adapt existing `refinery.dm` blackjack mechanic:
- Input: PE boxes + filter
- Filter determines quality type
- PE quantity determines refinement level
- Minigame result determines purity
- Output: Condensed Enkephalin item

### Step 5: Create Grid System Datum
Adapt `grid_system.dm`:
- Change `get_max_revealed_tier()` to use `SSlobotomy_corp.ordeal_clear_count`
- Replace core references with enkephalin references
- Keep city weapon discovery and tier calculation logic

### Step 6: Create Grid Station
Adapt `grid_crafting_station.dm`:
- Store up to 50 condensed enkephalin items
- Grid navigation using enkephalin movement types
- Craft city weapons when in range
- TGUI interface: `"EnkephalinGridStation"`

### Step 7: Create TGUI Interface
Adapt `GridCraftingStation.js` (~668 lines):
- Rename to EnkephalinGridStation
- Update terminology (cores → enkephalin)
- Update quality colors: RED=#CC3333, WHITE=#FFFFFF, BLACK=#333333, PALE=#AADDFF
- Show "Ordeal Clears: X" instead of research tier

---

## Icon Usage
- **Condensed Enkephalin**: `'ModularLobotomy/_Lobotomyicons/refiner.dmi'`, icon_state `"ebox_refined"`
- **Refinery**: `'ModularLobotomy/_Lobotomyicons/refiner.dmi'`, icon_state `"machine"`
- **Grid Station**: `'icons/obj/machines/research.dmi'`, icon_state `"tdoppler"` (or similar)

---

## Key Source Files for Reference
- `refining_weapons/ore_cores.dm` (260 lines) - Core item structure
- `refining_weapons/ore_refiner.dm` (517 lines) - Refinery logic
- `refining_weapons/grid_system.dm` (330 lines) - Grid datum
- `refining_weapons/grid_crafting_station.dm` (416 lines) - Station machine
- `refining_weapons/GridCraftingStation.js` (668 lines) - TGUI
- `ModularLobotomy/refinery/refinery.dm` - Blackjack minigame pattern
- `code/controllers/subsystem/lobotomy_corp.dm` - Subsystem to modify
- `code/__DEFINES/dcs/signals.dm:1106` - COMSIG_GLOB_ORDEAL_END definition

---

## Verification
1. Compile the codebase with new files
2. Spawn the Enkephalin Refinery and Grid Station in-game
3. Test PE box → Condensed Enkephalin conversion with different filters
4. Verify tier unlocking by simulating ordeal clears
5. Test grid navigation with all 4 movement types
6. Craft a city weapon and verify it spawns correctly
