# Grid Crafting System Implementation Plan (Updated)

## Overview
A money-gated crafting system where players purchase core templates, fill them with abnochem reagents to determine movement type, then use them to navigate a coordinate grid to reach weapon locations. Weapon positions shuffle periodically to add variety.

---

## Core Design Philosophy

### Limiting Factor: Money
- **Primary bottleneck**: Players must purchase core templates using personal Ahn (from ID card bank accounts or holochips)
- Higher tier weapons require more navigation = more cores = more money spent
- This creates natural progression tied to work/economy rather than time/research

### Movement Types via AbnoChem
- Core templates are filled with abnochem reagents to determine movement pattern
- **7 movement types** - one for each base sin
- Chem quantity affects distance (under/overcharge system)
- Advanced chems (Level 3+) bypass quantity requirements

### Chem Quantity System
- **Optimal amount**: 15u of reagent = 100% distance
- **Undercharge**: Less than 15u = reduced distance (minimum -50% at ~5u)
- **Overcharge**: More than 15u = increased distance (maximum +50% at ~25u)
- **Advanced chems bypass**: Level 3 Derivatives and Level 4 chems always give 100% distance regardless of amount

### Diminishing Returns
- Using the same movement type repeatedly reduces effectiveness
- Each consecutive use of the same sin type: -10% distance (stacks up to -50%)
- Using a different movement type resets the penalty
- Encourages variety in core usage

### Shuffle Mechanic
- Every 8-15 weapons crafted globally, all weapon positions randomize
- Higher tier weapons add more to the shuffle counter
- Tier 4 weapons cause immediate shuffle upon crafting

---

## Movement Types (7 Total - One Per Sin)

Each base sin produces a unique movement pattern. More accurate movements travel shorter distances, while less predictable ones travel further to compensate.

| Sin | Movement Type | Pattern Description | Accuracy | Distance Modifier |
|-----|---------------|---------------------|----------|-------------------|
| **Wrath** | Charge | Straight line in one cardinal direction (N/S/E/W), cannot stop early | Baseline | **0%** (reference) |
| **Pride** | Teleport | Direct jump to any chosen point within range | Highest | **-30%** |
| **Lust** | Attract | Automatically moves toward the nearest weapon point | High | **-20%** |
| **Gluttony** | Expand | Moves in any of 8 directions (octagonal) | Medium-High | **-10%** |
| **Envy** | Mirror | Copies and inverts the previous movement | Medium | **+10%** |
| **Gloom** | Drift | Curved/wandering path, direction influenced but not precise | Low | **+20%** |
| **Sloth** | Shuffle | Random movement in random direction, very unpredictable | Lowest | **+30%** |

### Movement Modifier Rationale
- **Teleport (-30%)**: You pick the exact spot - maximum control, minimum distance
- **Attract (-20%)**: Auto-targets weapons - high accuracy but you don't choose direction
- **Expand (-10%)**: 8 directions vs 4 - slightly more flexible than Charge
- **Charge (0%)**: Baseline - 4 cardinal directions, predictable straight line
- **Mirror (+10%)**: Depends on previous move - some unpredictability in planning
- **Drift (+20%)**: You pick direction but path curves - compensated with extra distance
- **Shuffle (+30%)**: Completely random - highest distance to offset lack of control

### Chem Hierarchy and Movement Inheritance

**Level 1 - Sins** (Base, affected by quantity):
- Each sin = its own movement type
- Subject to under/overcharge based on quantity used

**Level 2 - Syrups** (Affected by quantity):
- Hearty Syrup (Sloth + Envy) → Shuffle movement
- Bitter Syrup (Envy + Lust) → Mirror movement
- Tasteless Syrup (Pride + Wrath) → Charge movement
- Focused Syrup (Gloom + Gluttony) → Drift movement

**Level 3 - Derivatives** (Bypass quantity - always 100%):
- G.E.D. NT (Wrath + Lust + Pride) → Charge movement
- G.E.D. CN (Sloth + Gluttony + Wrath) → Shuffle movement
- G.E.D. CS (Gloom + Pride + Lust) → Drift movement
- G.E.D. AM (Envy + Gluttony + Pride) → Mirror movement
- G.E.D. VL (Lust + Gloom + Sloth) → Attract movement
- G.E.D. RO (Gluttony + Envy + Wrath) → Expand movement
- G.E.D. WP (Gloom + Envy + Sloth) → Drift movement

**Level 4 - High Level** (Bypass quantity - always 100%):
- Inherit movement from their primary derivative component
- Example: Odisone (Focused Syrup + G.E.D. VL) → Attract movement

---

## Money System Integration

### Template Purchase (via ID bank account)
Templates are purchased from a new section in the extraction cargo or a dedicated machine:

| Template Grade | Cost (Ahn) | Distance Range | Avg Distance | Available Tiers |
|----------------|------------|----------------|--------------|-----------------|
| Basic | 50 | 5-15 | 10 | 0-1 |
| Standard | 150 | 10-25 | 17.5 | 0-2 |
| Quality | 400 | 15-40 | 27.5 | 0-3 |
| Superior | 1000 | 25-60 | 42.5 | 0-4 |

### Money Sources (Reference)
- PE Sales machines: Holochips with 50-200 Ahn random
- Working on abnormalities
- Other existing economy systems

---

## Weapon Placement (Ahn-Cost Balanced)

Weapons are placed based on **expected Ahn cost to reach them**, not arbitrary distance bands. This creates a natural economy-based progression where players must invest more money to access better weapons.

### Placement Philosophy
- Calculate expected cores needed = `distance / average_core_distance`
- Expected Ahn cost = `cores_needed × template_cost`
- Higher tier weapons = further away = more cores = more Ahn

### Tier Placement Table

| Tier | Expected Ahn | Expected Cores | Distance Range | Radius |
|------|--------------|----------------|----------------|--------|
| **0** (Crude) | 100-200 | 2-4 Basic | 20-40 | 8-12 |
| **1** (Common) | 300-600 | 2-4 Standard | 40-80 | 6-10 |
| **2** (Refined) | 800-1,600 | 2-4 Quality | 60-120 | 5-8 |
| **3** (Exceptional) | 2,000-4,000 | 5-10 Quality/Superior | 140-280 | 4-7 |
| **4** (Legendary) | 6,000-12,000 | 6-12 Superior | 300-550 | 3-6 |

### Calculation Logic

```dm
/// Calculate weapon placement based on expected Ahn investment
/datum/grid_craft_manager/proc/generate_item_positions()
    // Tier placement config: distance based on expected core cost
    // Using average distances: Basic=10, Standard=17.5, Quality=27.5, Superior=42.5
    var/list/tier_config = list(
        // Tier 0: 2-4 Basic cores (100-200 Ahn)
        list("min_dist" = 20, "max_dist" = 40, "min_rad" = 8, "max_rad" = 12,
             "expected_ahn" = 150, "expected_cores" = 3),
        // Tier 1: 2-4 Standard cores (300-600 Ahn)
        list("min_dist" = 40, "max_dist" = 80, "min_rad" = 6, "max_rad" = 10,
             "expected_ahn" = 450, "expected_cores" = 3),
        // Tier 2: 2-4 Quality cores (800-1600 Ahn)
        list("min_dist" = 60, "max_dist" = 120, "min_rad" = 5, "max_rad" = 8,
             "expected_ahn" = 1200, "expected_cores" = 3),
        // Tier 3: 5-10 Quality/Superior cores (2000-4000 Ahn)
        list("min_dist" = 140, "max_dist" = 280, "min_rad" = 4, "max_rad" = 7,
             "expected_ahn" = 3000, "expected_cores" = 7),
        // Tier 4: 6-12 Superior cores (6000-12000 Ahn)
        list("min_dist" = 300, "max_dist" = 550, "min_rad" = 3, "max_rad" = 6,
             "expected_ahn" = 9000, "expected_cores" = 9)
    )
```

### Comparison: Old vs New

| Tier | Old Distance | New Distance | Change |
|------|--------------|--------------|--------|
| 0 | 10-40 | 20-40 | Slightly further |
| 1 | 60-100 | 40-80 | Closer (overlaps with T0) |
| 2 | 120-180 | 60-120 | Closer |
| 3 | 200-280 | 140-280 | Similar |
| 4 | 320-420 | 300-550 | Wider range, can be further |

### Why This Works
1. **Tier 0-1 overlap intentionally**: Cheap weapons are accessible with Basic cores, creating a smooth on-ramp
2. **Tier 2-3 require investment**: Quality cores are needed, significant Ahn commitment
3. **Tier 4 is expensive**: Only players who've accumulated wealth can realistically reach these
4. **Movement modifiers matter**: Shuffle (+30%) can reach further per core, but is random; Teleport (-30%) is precise but short

### Player Strategy Considerations

**Budget Approach** (Tier 0-1):
- Use Basic cores (50 Ahn each)
- Favor Shuffle/Drift for +20-30% extra distance
- Expected cost: 100-300 Ahn per weapon

**Mid-Game Approach** (Tier 2):
- Mix of Standard (150) and Quality (400) cores
- May need 3-5 cores to navigate
- Expected cost: 600-1500 Ahn per weapon

**Late-Game Approach** (Tier 3-4):
- Superior cores (1000 Ahn) for maximum distance
- Need efficient pathing to minimize cores used
- Teleport for final precise positioning
- Expected cost: 3000-10000+ Ahn per weapon

**Efficiency Tips**:
- Use high-distance movement types (Shuffle, Drift) for bulk travel
- Switch to Teleport for final approach to reset diminishing returns
- Overcharge (25u) sins for +50% distance when you have excess chems
- Use Level 3+ derivatives to avoid quantity penalties

### Purchase Flow
```dm
// Check ID card bank account
var/obj/item/card/id/C = user.get_idcard(TRUE)
if(!C?.registered_account)
    return FALSE
var/datum/bank_account/account = C.registered_account
if(!account.adjust_money(-template_cost))
    to_chat(user, span_warning("Insufficient funds!"))
    return FALSE
// Create template
```

---

## Shuffle System

### Shuffle Counter
- Stored on the grid station or globally
- Threshold: Random between 8-15 at initialization, re-rolls after each shuffle

### Shuffle Contribution by Tier
| Weapon Tier | Shuffle Points Added |
|-------------|---------------------|
| Tier 0 (Crude) | +1 |
| Tier 1 (Common) | +2 |
| Tier 2 (Refined) | +3 |
| Tier 3 (Exceptional) | +5 |
| Tier 4 (Legendary) | Immediate shuffle |

### On Shuffle
- All weapon positions regenerated with new random coordinates
- Shuffle counter resets
- New threshold rolled (8-15)
- Visual/audio feedback to users

---

## Files to Create

### ModularLobotomy/refinery/grid_crafting/

| File | Purpose | Lines (est.) |
|------|---------|--------------|
| `_defines.dm` | 7 movement type constants, template grades, quantity thresholds, shuffle defines | ~80 |
| `core_template.dm` | Purchasable template item with reagent container, converts to nav core | ~300 |
| `navigation_core.dm` | Final core with movement type, modifiers, sin tracking | ~250 |
| `chem_mapping.dm` | Chem-to-movement lookup, quantity modifier calc, diminishing returns | ~150 |
| `grid_system.dm` | Grid coordinate and crafting logic with shuffle, 7 movement behaviors | ~450 |
| `grid_station.dm` | The crafting station machine with diminishing returns tracking | ~450 |
| `template_vendor.dm` | Machine/UI for buying templates with Ahn | ~200 |

### TGUI
| File | Purpose |
|------|---------|
| `tgui/packages/tgui/interfaces/EnkephalinGridStation.js` | Main grid UI with shuffle indicator, diminishing returns display |
| `tgui/packages/tgui/interfaces/CoreTemplateVendor.js` | Template purchase UI with bank balance |

---

## Item Design

### Core Template (`/obj/item/core_template`)
- Purchasable item with a grade (basic/standard/quality/superior)
- Has reagent container (like a beaker) for abnochem
- When sufficient chem is added, converts to navigation core
- Grade determines base distance range and tier access

### Navigation Core (`/obj/item/navigation_core`)
- Created from template + chem
- Properties:
  - `movement_type`: Determined by chem used (1-7)
  - `movement_modifier`: 0.7 to 1.3 based on movement type accuracy
  - `grade`: Inherited from template
  - `base_distance_range`: Based on grade
  - `quantity_modifier`: 0.5 to 1.5 based on chem amount (or 1.0 if bypassed)
  - `bypasses_quantity`: TRUE for Level 3+ chems
  - `max_tier`: Maximum weapon tier accessible
  - `sin_type`: Which of the 7 sins this core is based on (for diminishing returns)

### Final Distance Calculation
```
final_distance = base_distance * movement_modifier * quantity_modifier * diminishing_modifier
```
Where:
- `base_distance`: Random within grade's range
- `movement_modifier`: 0.7 to 1.3 based on movement type accuracy (see table above)
- `quantity_modifier`: 0.5 to 1.5 (or 1.0 for advanced chems)
- `diminishing_modifier`: 0.5 to 1.0 based on consecutive same-type use

### Example Calculations
Using a Standard template (base 10-25 range), 15u optimal chem, no diminishing penalty:

| Movement Type | Base Roll | Movement Mod | Quantity Mod | Diminish | Final |
|---------------|-----------|--------------|--------------|----------|-------|
| Charge (Wrath) | 20 | 1.0 | 1.0 | 1.0 | **20** |
| Teleport (Pride) | 20 | 0.7 | 1.0 | 1.0 | **14** |
| Shuffle (Sloth) | 20 | 1.3 | 1.0 | 1.0 | **26** |
| Drift w/ 25u | 20 | 1.2 | 1.5 | 1.0 | **36** |
| Charge w/ penalty | 20 | 1.0 | 1.0 | 0.7 | **14** |

---

## Chem to Movement Mapping

```dm
// Movement type constants
#define CORE_MOVEMENT_CHARGE   1  // Wrath - straight line cardinal
#define CORE_MOVEMENT_ATTRACT  2  // Lust - toward nearest weapon
#define CORE_MOVEMENT_SHUFFLE  3  // Sloth - small random
#define CORE_MOVEMENT_EXPAND   4  // Gluttony - octagonal
#define CORE_MOVEMENT_DRIFT    5  // Gloom - curved/wandering
#define CORE_MOVEMENT_TELEPORT 6  // Pride - direct jump
#define CORE_MOVEMENT_MIRROR   7  // Envy - copy previous

// Movement distance modifiers (accuracy tradeoff)
// More accurate = less distance, less accurate = more distance
GLOBAL_LIST_INIT(movement_distance_modifiers, list(
    CORE_MOVEMENT_CHARGE   = 1.0,   // Baseline (0%)
    CORE_MOVEMENT_ATTRACT  = 0.8,   // -20% (high accuracy)
    CORE_MOVEMENT_SHUFFLE  = 1.3,   // +30% (lowest accuracy)
    CORE_MOVEMENT_EXPAND   = 0.9,   // -10% (medium-high accuracy)
    CORE_MOVEMENT_DRIFT    = 1.2,   // +20% (low accuracy)
    CORE_MOVEMENT_TELEPORT = 0.7,   // -30% (highest accuracy)
    CORE_MOVEMENT_MIRROR   = 1.1    // +10% (medium accuracy)
))

/proc/get_movement_distance_modifier(movement_type)
    if(movement_type in GLOB.movement_distance_modifiers)
        return GLOB.movement_distance_modifiers[movement_type]
    return 1.0  // Default to baseline

// Returns list(movement_type, bypasses_quantity)
/proc/get_movement_from_chem(datum/reagent/R)
    // Level 1 - Sins (affected by quantity)
    if(istype(R, /datum/reagent/abnormality/sin/wrath))
        return list(CORE_MOVEMENT_CHARGE, FALSE)
    if(istype(R, /datum/reagent/abnormality/sin/lust))
        return list(CORE_MOVEMENT_ATTRACT, FALSE)
    if(istype(R, /datum/reagent/abnormality/sin/sloth))
        return list(CORE_MOVEMENT_SHUFFLE, FALSE)
    if(istype(R, /datum/reagent/abnormality/sin/gluttony))
        return list(CORE_MOVEMENT_EXPAND, FALSE)
    if(istype(R, /datum/reagent/abnormality/sin/gloom))
        return list(CORE_MOVEMENT_DRIFT, FALSE)
    if(istype(R, /datum/reagent/abnormality/sin/pride))
        return list(CORE_MOVEMENT_TELEPORT, FALSE)
    if(istype(R, /datum/reagent/abnormality/sin/envy))
        return list(CORE_MOVEMENT_MIRROR, FALSE)

    // Level 2 - Syrups (affected by quantity)
    if(istype(R, /datum/reagent/abnormality/heartysyrup))
        return list(CORE_MOVEMENT_SHUFFLE, FALSE)   // Sloth + Envy
    if(istype(R, /datum/reagent/abnormality/bittersyrup))
        return list(CORE_MOVEMENT_MIRROR, FALSE)    // Envy + Lust
    if(istype(R, /datum/reagent/abnormality/tastesyrup))
        return list(CORE_MOVEMENT_CHARGE, FALSE)    // Pride + Wrath
    if(istype(R, /datum/reagent/abnormality/focussyrup))
        return list(CORE_MOVEMENT_DRIFT, FALSE)     // Gloom + Gluttony

    // Level 3 - Derivatives (BYPASS quantity - always 100%)
    if(istype(R, /datum/reagent/abnormality/nutrition))      // NT
        return list(CORE_MOVEMENT_CHARGE, TRUE)
    if(istype(R, /datum/reagent/abnormality/cleanliness))    // CN
        return list(CORE_MOVEMENT_SHUFFLE, TRUE)
    if(istype(R, /datum/reagent/abnormality/consensus))      // CS
        return list(CORE_MOVEMENT_DRIFT, TRUE)
    if(istype(R, /datum/reagent/abnormality/amusement))      // AM
        return list(CORE_MOVEMENT_MIRROR, TRUE)
    if(istype(R, /datum/reagent/abnormality/violence))       // VL
        return list(CORE_MOVEMENT_ATTRACT, TRUE)
    if(istype(R, /datum/reagent/abnormality/abno_oil))       // RO
        return list(CORE_MOVEMENT_EXPAND, TRUE)
    if(istype(R, /datum/reagent/abnormality/woe))            // WP
        return list(CORE_MOVEMENT_DRIFT, TRUE)

    // Level 4 - High Level (BYPASS quantity - always 100%)
    if(istype(R, /datum/reagent/abnormality/odisone))
        return list(CORE_MOVEMENT_ATTRACT, TRUE)    // From VL
    if(istype(R, /datum/reagent/abnormality/gaspilleur))
        return list(CORE_MOVEMENT_CHARGE, TRUE)     // From NT
    if(istype(R, /datum/reagent/abnormality/lesser_sange_rau))
        return list(CORE_MOVEMENT_MIRROR, TRUE)     // From AM
    if(istype(R, /datum/reagent/abnormality/culpusumidus))
        return list(CORE_MOVEMENT_DRIFT, TRUE)      // From WP
    if(istype(R, /datum/reagent/abnormality/serelam))
        return list(CORE_MOVEMENT_EXPAND, TRUE)     // From RO
    if(istype(R, /datum/reagent/abnormality/nepenthe))
        return list(CORE_MOVEMENT_DRIFT, TRUE)      // From CS
    if(istype(R, /datum/reagent/abnormality/piedrabital))
        return list(CORE_MOVEMENT_SHUFFLE, TRUE)    // From CN
    if(istype(R, /datum/reagent/abnormality/dyscrasone))
        return list(CORE_MOVEMENT_TELEPORT, TRUE)   // Unique - both syrups

    return null // Invalid chem

/// Calculate distance modifier based on reagent quantity
/proc/get_quantity_modifier(amount, bypasses_quantity)
    if(bypasses_quantity)
        return 1.0  // Always 100% for advanced chems

    // Optimal = 15u = 100%
    // Minimum = 5u = 50% (-50%)
    // Maximum = 25u = 150% (+50%)
    var/modifier = clamp((amount - 5) / 20, 0, 1)  // 0 to 1 range
    return 0.5 + (modifier * 1.0)  // 0.5 to 1.5 range
```

## Diminishing Returns System

```dm
/// Tracks consecutive uses of same movement type per user
var/list/user_movement_history = list()  // ckey -> last_movement_type
var/list/user_consecutive_count = list() // ckey -> count

/proc/get_diminishing_modifier(ckey, movement_type)
    if(!user_movement_history[ckey])
        user_movement_history[ckey] = movement_type
        user_consecutive_count[ckey] = 1
        return 1.0

    if(user_movement_history[ckey] == movement_type)
        user_consecutive_count[ckey] = min(user_consecutive_count[ckey] + 1, 6)
    else
        user_movement_history[ckey] = movement_type
        user_consecutive_count[ckey] = 1
        return 1.0  // Reset - full effectiveness

    // -10% per consecutive use, max -50%
    var/penalty = (user_consecutive_count[ckey] - 1) * 0.1
    return max(0.5, 1.0 - penalty)
```

---

## Implementation Steps

### Step 1: Create Defines
Create `_defines.dm` with:
- 7 movement type constants (CHARGE, ATTRACT, SHUFFLE, EXPAND, DRIFT, TELEPORT, MIRROR)
- Template grade constants and their properties
- Quantity thresholds (5u min, 15u optimal, 25u max)
- Shuffle system defines

### Step 2: Create Chem Mapping System
Create `chem_mapping.dm` with:
- `get_movement_from_chem()` - returns movement type + bypass flag
- `get_quantity_modifier()` - calculates 0.5-1.5 multiplier
- `get_diminishing_modifier()` - tracks consecutive same-type use

### Step 3: Create Core Template Item
- Purchasable via bank account
- Has reagent container that accepts abnochem
- On reagent add: validates chem type, calculates modifiers
- Converts to navigation core when valid chem added

### Step 4: Create Navigation Core Item
- Final usable item with all calculated properties
- Stores: movement_type, sin_type, quantity_modifier, grade, max_tier
- Consumed on use at grid station

### Step 5: Create Template Vendor
- Machine that sells templates for Ahn
- Uses bank account from ID card
- Shows current balance
- Categories by grade with prices

### Step 6: Create Grid System Datum
- Adapt from `refining_weapons/grid_system.dm`
- Implement all 7 movement behaviors
- Add shuffle counter and threshold
- Weapon tier contributes to shuffle progress
- Immediate shuffle on Tier 4 craft
- Store last movement for Mirror type

### Step 7: Create Grid Station
- Adapt from `refining_weapons/grid_crafting_station.dm`
- Accept navigation cores
- Track diminishing returns per player (ckey)
- Display current penalty in UI
- Display shuffle progress
- Show what movement types have been used recently

### Step 8: Create TGUI Interfaces
- Grid station UI with:
  - Shuffle progress bar
  - Diminishing returns indicator per movement type
  - Movement type selector for directional types
  - Teleport coordinate picker for Pride
- Template vendor with bank balance display

---

## UI Considerations

### Grid Station UI Additions
- **Shuffle progress bar**: "Shuffle in: X/Y crafts"
  - When near shuffle: Warning indicator (amber/red)
  - On shuffle: Animation/flash effect
- **Diminishing returns display**:
  - Show current penalty percentage for each sin type used recently
  - Visual indicator (color gradient from green to red)
  - "Wrath: 80% | Lust: 100% | Gloom: 60%"
- **Movement type controls**:
  - Charge: 4 cardinal direction buttons
  - Attract: Auto (shows target weapon)
  - Shuffle: Single "Move" button
  - Expand: 8 direction buttons
  - Drift: 8 direction buttons + deviation preview
  - Teleport: Click-on-map or coordinate input
  - Mirror: Shows "Will mirror: [previous move]"
- **Last movement indicator**: Shows what the previous movement was (for Mirror)

### Template Vendor UI
- Show player's current Ahn balance prominently
- Template grades with prices
- Disabled/grayed options if insufficient funds
- Tooltip showing template properties (distance range, tier access)

### Core Template UI (when filling)
- Current reagent amount display
- Quantity modifier preview: "Distance: 75% (need 10u more for 100%)"
- Movement type preview based on detected chem
- Warning if using Level 1-2 chem with suboptimal amount

---

## Key Source Files for Reference
- `refining_weapons/ore_cores.dm` - Core item structure
- `refining_weapons/grid_system.dm` - Grid datum
- `refining_weapons/grid_crafting_station.dm` - Station machine
- `refining_weapons/GridCraftingStation.js` - TGUI
- `code/game/machinery/computer/extraction_cargo.dm` - Purchase pattern with PE
- `ModularLobotomy/refinery/sales.dm` - Holochip/Ahn generation
- `ModularLobotomy/tegu_legacy/tegu_chemistry/abnochem/` - Chem system

---

## Verification
1. Compile the codebase with new files
2. Spawn the Template Vendor and Grid Station in-game
3. Test purchasing templates with varying Ahn amounts (insufficient funds rejected)
4. Test filling templates with different abnochem types:
   - Level 1 sins: verify quantity affects distance
   - Level 2 syrups: verify quantity affects distance
   - Level 3 derivatives: verify quantity is bypassed (always 100%)
   - Level 4 high-level: verify quantity is bypassed (always 100%)
5. Test quantity system:
   - 5u = 50% distance
   - 15u = 100% distance
   - 25u = 150% distance
6. Test all 7 movement types and their distance modifiers:
   - Charge (0%): moves straight cardinal, baseline distance
   - Teleport (-30%): exact coordinate jump, shortest distance
   - Attract (-20%): moves toward nearest weapon
   - Expand (-10%): 8-directional
   - Mirror (+10%): inverts previous movement
   - Drift (+20%): curved path with deviation
   - Shuffle (+30%): random movement, longest distance
7. Test diminishing returns:
   - First use = 100%
   - Second consecutive same type = 90%
   - Third = 80%, etc. down to 50%
   - Different type resets to 100%
8. Test shuffle mechanic:
   - Counter increases on craft (T0=+1, T1=+2, T2=+3, T3=+5)
   - Shuffle triggers at threshold (8-15)
   - T4 craft causes immediate shuffle
9. Craft weapons across all tiers and verify progression

---

## Open Questions
1. Should shuffle be per-station or global across all stations?
2. Should there be any way to preview upcoming shuffle (like "3 crafts until shuffle")?
3. Should diminishing returns be per-player or per-station?
4. Should template vendor be a new machine or integrated into extraction cargo?
5. For **Attract** movement (Lust): What happens if no weapons are in range?
6. For **Mirror** movement (Envy): Should it mirror globally (any player's last move) or just that player's?
7. For **Drift** movement (Gloom): How much deviation from chosen direction? Random curve amount?

## Movement Type Details

### Charge (Wrath)
- Player picks cardinal direction (N/S/E/W)
- Moves full distance in that direction
- Cannot stop early or change direction mid-movement

### Attract (Lust)
- Automatically moves toward nearest visible weapon point
- Distance determines how far it travels toward that weapon
- If no weapons in range, could either fail or act as shuffle

### Shuffle (Sloth)
- Small random movement
- Direction is random, distance is reduced (maybe 50% of normal)
- Good for fine-tuning position

### Expand (Gluttony)
- Player picks any of 8 directions
- Moves full distance in that direction
- Most versatile directional movement

### Drift (Gloom)
- Player picks a general direction
- Actual movement curves/deviates from intended path
- Deviation amount could be random (10-30 degrees off?)

### Teleport (Pride)
- Player clicks exact target coordinates
- Jumps directly to that point if within range
- Most precise but requires accurate planning

### Mirror (Envy)
- Copies the previous movement made at this station
- Inverts direction (if last was +X, this is -X)
- If no previous movement, acts as Shuffle
