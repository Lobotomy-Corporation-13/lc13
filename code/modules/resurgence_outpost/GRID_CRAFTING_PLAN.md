# Resurgence Outpost - Grid Crafting System

## Overview

The **Grid Crafting System** is an advanced crafting mechanic where players navigate a "focus point" through a coordinate grid using **Ore Cores** to reach item coordinates and craft special equipment. This creates a strategic resource management challenge where core properties determine movement patterns.

This system is adapted from the City Weaponry Grid Crafting system for the Resurgence Outpost gamemode.

---

## Core Mechanics

### 1. The Grid

- **Infinite 2D coordinate system** with origin at (0, 0)
- **Focus Point**: Current position marker that starts at (0, 0)
- **Item Coordinates**: Fixed positions on the grid where items can be crafted
- **Craft Radius**: Each item has a circular area where it can be crafted when the focus point is within range

### 2. Ore Cores

Ore Cores are created by processing ores in the **Ore Refiner**. Each core inherits properties from its source ore.

#### Core Properties

**Ore Type** → Determines movement direction:
| Ore Type | Movement Pattern | Source |
|----------|------------------|--------|
| **Iron** | Cardinal (N/S/E/W) | Iron Ore, Iron Scrap |
| **Silver** | Diagonal (NE/NW/SE/SW) | Silver Ore |
| **Alloy** | 8-directional (any) | 1 Iron Core + 1 Silver Core (same level) |
| **Gold** | Teleport within range (player choice) | Gold Ore |

**Refinement Level** → Determines movement distance:
| Level | Name | Distance | Created From |
|-------|------|----------|--------------|
| 0 | Crude | 1-2 units | Raw ore (unrefined) |
| 1 | Common | 3-5 units | 2 Raw Ore → 1 Core |
| 2 | Refined | 6-10 units | 2 Common Cores → 1 Refined |
| 3 | Exceptional | 11-20 units | 2 Refined Cores → 1 Exceptional |
| 4 | Legendary | 21-40 units | 2 Exceptional Cores → 1 Legendary |

**Coal Fuel** → Modifies movement distance (set during refining):
| Fuel Level | Effect | Coal Cost |
|------------|--------|-----------|
| Unfueled | -50% distance | 0 Coal per ore |
| Low Fuel | -25% distance | 1 Coal per ore |
| Standard | Normal distance | 2 Coal per ore |
| High Fuel | +25% distance | 3 Coal per ore |
| Supercharged | +50% distance | 4 Coal per ore |

Coal acts as fuel for the cores - more coal means more energy and greater movement distance.

### 3. Item Placement Algorithm

Items are placed on the grid based on their tier. More items in a tier = smaller radius to prevent overlap.

| Tier | Item Count | Distance from Origin | Craft Radius |
|------|------------|---------------------|--------------|
| 0 (Basic) | Many | 5-25 | 6-10 |
| 1 (Common) | Moderate | 20-40 | 8-12 |
| 2 (Refined) | Many | 35-65 | 6-8 |
| 3 (Exceptional) | Few | 55-85 | 6-8 |
| 4 (Legendary) | Rare | 75-105 | 4-6 |

### 4. Crafting Process

1. Player starts at (0, 0)
2. Player uses Ore Cores to move the focus point
3. After using at least 1 core, system checks if focus point is within any item's craft radius
4. If within radius:
   - **Single item**: That item is crafted
   - **Multiple items**: Random selection (or player choice if Heavy core was used)
5. Focus point resets to (0, 0)

### Visual Example

```
       [T3:6]
         *     [T2:8]
                 *       [T2:12]
                           *

       F(0,0)     [T1:10]
                    *        [T1:8]
                               *
   [T0:10]
     *

Legend:
F = Focus Point
* = Item Coordinate
[Tn:r] = Tier 'n' item with radius 'r'
```

---

## Ore Refiner

The **Ore Refiner** converts raw ores into **Ore Cores** used for grid navigation. The type of core created depends on the ratio of primary materials (Iron, Silver, Gold), while Coal acts as fuel to boost distance.

### Operation

1. **Load Primary Ores**: Insert Iron Ore, Silver Ore, and/or Gold Ore
2. **Load Coal**: Add coal to fuel the cores (affects distance)
3. **Activate**: Begin processing (5 seconds per batch)
4. **Output**: Receive Ore Cores based on material ratios

### Core Type (Based on Primary Ore Ratio)

The ratio of Iron, Silver, and Gold determines the core type. Ratios are calculated from the total primary ore count (Iron + Silver + Gold), excluding Coal.

#### Pure Cores (Single Ore Type)
| Iron % | Silver % | Gold % | Result | Movement |
|--------|----------|--------|--------|----------|
| 100% | 0% | 0% | Iron Core | Cardinal (N/S/E/W) |
| 0% | 100% | 0% | Silver Core | Diagonal (NE/NW/SE/SW) |
| 0% | 0% | 100% | Gold Core | Teleport (player choice) |

#### Alloy Cores (Balanced Mix)
| Iron % | Silver % | Gold % | Result | Movement |
|--------|----------|--------|--------|----------|
| 40-60% | 40-60% | 0% | Alloy Core | 8-directional |

#### Dominant Ore (Unbalanced Mix)
When Iron and Silver are mixed but NOT in the 40-60% balanced range, the **dominant ore** determines the core type:

| Dominant Ore | Minor Ore | Result | Movement | Bonus |
|--------------|-----------|--------|----------|-------|
| Iron (61%+) | Silver | Iron Core | Cardinal | +5% distance |
| Silver (61%+) | Iron | Silver Core | Diagonal | +5% distance |

The minor ore contribution grants a small distance bonus but doesn't change the movement pattern.

**Examples of Dominant Ore:**
- 90% Iron / 10% Silver → Iron Core with +5% distance
- 70% Silver / 30% Iron → Silver Core with +5% distance
- 65% Iron / 35% Silver → Iron Core with +5% distance

#### Gilded Variants (Gold Mixed In)
Adding Gold to any batch creates a "Gilded" variant with enhanced range:

| Gold % | Base Ore(s) | Result | Effect |
|--------|-------------|--------|--------|
| 1-25% | Iron dominant | Gilded Iron Core | Cardinal + 10% range |
| 1-25% | Silver dominant | Gilded Silver Core | Diagonal + 10% range |
| 1-25% | Iron/Silver balanced | Gilded Alloy Core | 8-dir + 10% range |
| 26-50% | Any | Gilded Gold Core | Teleport + 15% range |
| 51%+ | Any | Gold Core | Teleport (pure gold behavior) |

**Examples of Gilded Cores:**
- 80% Silver / 20% Gold → Gilded Silver Core (Diagonal, +10% range)
- 45% Iron / 45% Silver / 10% Gold → Gilded Alloy Core (8-dir, +10% range)
- 40% Iron / 30% Silver / 30% Gold → Gilded Gold Core (Teleport, +15% range)
- 30% Iron / 70% Gold → Gold Core (pure teleport)

#### Quick Reference: Ratio Resolution Order
1. If Gold ≥ 51%: **Gold Core**
2. If Gold 26-50%: **Gilded Gold Core**
3. If Gold 1-25%: Apply "Gilded" prefix to result below
4. If Iron 40-60% AND Silver 40-60%: **Alloy Core**
5. If Iron > Silver: **Iron Core** (with +5% if Silver present)
6. If Silver > Iron: **Silver Core** (with +5% if Iron present)
7. If Iron = Silver (and both > 0): **Alloy Core**

### Refinement Level (Based on Total Primary Ore)

| Total Primary Ore | Output | Refinement Level |
|-------------------|--------|------------------|
| 1-2 ore | 1 Core | Level 0 (Crude) |
| 3-5 ore | 1 Core | Level 1 (Common) |
| 6-10 ore | 1 Core | Level 2 (Refined) |
| 11-20 ore | 1 Core | Level 3 (Exceptional) |
| 21+ ore | 1 Core | Level 4 (Legendary) |

More ore invested = higher level core = greater base distance.

### Coal Fuel (Secondary Material)

Coal is added separately and affects the final distance modifier:

| Coal Ratio | Effect |
|------------|--------|
| 0 Coal | -50% distance (Unfueled) |
| 1 Coal per 4 ore | -25% distance (Low Fuel) |
| 1 Coal per 2 ore | Normal distance (Standard) |
| 1 Coal per 1 ore | +25% distance (High Fuel) |
| 2 Coal per 1 ore | +50% distance (Supercharged) |

### Core Type Reference

| Core Type | Direction | Base Distance (by Level) |
|-----------|-----------|--------------------------|
| Iron Core | Cardinal (N/S/E/W) | L0: 1-2, L1: 3-5, L2: 6-10, L3: 11-20, L4: 21-40 |
| Silver Core | Diagonal (NE/NW/SE/SW) | L0: 1-2, L1: 3-5, L2: 6-10, L3: 11-20, L4: 21-40 |
| Alloy Core | 8-directional | L0: 1-2, L1: 3-5, L2: 6-10, L3: 11-20, L4: 21-40 |
| Gold Core | Teleport (choice) | L0: 1-2, L1: 3-5, L2: 6-10, L3: 11-20, L4: 21-40 |

### Usage Examples

**Example 1: Basic Iron Core**
- Input: 4 Iron Ore + 2 Coal
- Ratio: 100% Iron, Coal = 1:2 (Standard fuel)
- Output: 1 Iron Core (Level 1, Standard fuel)
- Movement: Cardinal, 3-5 units

**Example 2: Alloy Core**
- Input: 3 Iron Ore + 3 Silver Ore + 6 Coal
- Ratio: 50% Iron / 50% Silver, Coal = 1:1 (High Fuel)
- Output: 1 Alloy Core (Level 2, High Fuel)
- Movement: 8-directional, 6-10 units × 1.25 = 7.5-12.5 units

**Example 3: Gilded Silver Core**
- Input: 8 Silver Ore + 2 Gold Ore + 5 Coal
- Ratio: 80% Silver / 20% Gold, Coal = 1:2 (Standard)
- Output: 1 Gilded Silver Core (Level 2, Standard fuel, +10% range)
- Movement: Diagonal, 6-10 units × 1.10 = 6.6-11 units

**Example 4: Pure Gold Core**
- Input: 15 Gold Ore + 30 Coal
- Ratio: 100% Gold, Coal = 2:1 (Supercharged)
- Output: 1 Gold Core (Level 3, Supercharged)
- Movement: Teleport anywhere within 11-20 × 1.5 = 16.5-30 units

---

## Craftable Items

### Tier 0 - Basic Equipment
| Item | Description |
|------|-------------|
| Reinforced Wooden Hatchet | +1 work per tick |
| Reinforced Wooden Pickaxe | +1 work per tick |
| Sturdy Backpack | Slightly larger capacity |

### Tier 1 - Improved Tools
| Item | Description |
|------|-------------|
| Iron Hatchet+ | +2 work per tick, 125% durability |
| Iron Pickaxe+ | +2 work per tick, 125% durability |
| Iron Scythe+ | +2 work per tick, 125% durability |
| Miner's Satchel | Large ore-only storage |

### Tier 2 - Quality Equipment
| Item | Description |
|------|-------------|
| Efficient Hatchet | +3 work per tick, reduced stamina use |
| Efficient Pickaxe | +3 work per tick, bonus ore chance |
| Efficient Scythe | +3 work per tick, bonus harvest |
| Silver Pickaxe+ | +4 work per tick, fast mining |
| Faith Charm | +10% faith gain |

### Tier 3 - Superior Equipment
| Item | Description |
|------|-------------|
| Master's Hatchet | +5 work per tick, auto-replant chance |
| Master's Pickaxe | +5 work per tick, rare ore chance |
| Faith Amplifier | +25% faith gain from all sources |
| Acceleration Enhancer | Reduces acceleration protocol faith cost |

### Tier 4 - Legendary Equipment
| Item | Description |
|------|-------------|
| Legendary Hatchet | +8 work, 300% durability, special effects |
| Legendary Pickaxe | +8 work, 300% durability, double ore chance |
| Historian's Blessing | Permanent +1 to a chosen stat |
| Resurgence Banner | Major outpost-wide production buff |

---

## Structure: Grid Crafting Station

### Blueprint Requirements
- 15 Plasteel
- 10 Silver Sheets
- 5 Gold Sheets
- 10 Glass Sheets

### Research Required
- `advanced_metallurgy`
- `grid_crafting` (new research node)

### Features
- Displays current focus point position
- Shows nearby craftable items and their radii
- Core input slots
- Movement preview
- Craft history log

---

## Structure: Ore Refiner

### Blueprint Requirements
- 10 Metal Sheets
- 5 Plasteel
- 20 Coal

### Research Required
- `metallurgy`

### Features
- Ore input slots
- Coal input for density modification
- Core output
- Core combination interface (for upgrading core levels)

---

## UI Design

### Grid Crafting Station - Main Interface
```
+----------------------------------+
|     GRID CRAFTING STATION        |
+----------------------------------+
|  Focus Point: (12, -8)           |
|  Cores Used: 3                   |
+----------------------------------+
|         GRID VIEW                |
|    (visual representation)       |
|    showing focus point and       |
|    nearby item coordinates       |
+----------------------------------+
|  NEARBY ITEMS:                   |
|  - Master's Hatchet (dist: 4)    |
|  - Efficient Pickaxe (dist: 7)   |
+----------------------------------+
|  [Use Core] [Reset] [Craft]      |
+----------------------------------+
```

### Core Selection
```
+----------------------------------+
|  SELECT CORE TO USE              |
+----------------------------------+
|  [Iron Core L2] x5               |
|    Cardinal, 6-10 units, Normal  |
|                                  |
|  [Silver Core L1] x8             |
|    Diagonal, 3-5 units, Normal   |
|                                  |
|  [Gold Core L3] x2               |
|    Teleport, 11-20 units, Heavy  |
+----------------------------------+
```

---

## Balance Considerations

1. **Core Investment**: Higher tier items require higher level cores = more ore investment
2. **Gold Rarity**: Gold Cores (teleport) are rare but allow precise positioning - very valuable
3. **Density Trade-off**: Heavy cores move less but allow item selection on overlap
4. **Ore Type Strategy**: Different ore types needed for different navigation challenges
5. **Skill Integration**: Player's Crafting stat could:
   - Slightly increase movement distance (+1% per level)
   - Expand craft radii (+0.5 per 5 levels)
   - Reveal item positions further from focus point

---

## Implementation Priority

### Phase 1 - Core System
- [ ] Ore Core item type with properties (ore_type, level, density)
- [ ] Grid coordinate system
- [ ] Focus point tracking
- [ ] Movement calculations based on core properties

### Phase 2 - Ore Refiner
- [ ] Ore Refiner structure
- [ ] Core generation from ores
- [ ] Core combination/upgrading
- [ ] Density modification with coal

### Phase 3 - Grid Crafting Station
- [ ] Crafting station structure
- [ ] Item coordinate generation and placement
- [ ] TGUI interface with grid visualization
- [ ] Crafting on reaching item radius

### Phase 4 - Polish & Balance
- [ ] Crafting skill integration
- [ ] Sound effects and visual feedback
- [ ] All craftable items defined
- [ ] Balance tuning based on playtesting

---

## Notes

- This system mirrors the City Weaponry Grid Crafting but uses ores instead of weapon shards
- Ore types map to damage types: Iron→RED(Cardinal), Silver→WHITE(Diagonal), Alloy→BLACK(8-dir), Gold→PALE(Teleport)
- Alloy Cores require combining Iron + Silver cores, adding a resource sink
- Coal acts as fuel during refining - more coal = more distance (0-4 coal per ore)
- Core levels mirror weapon rarity tiers
- Coal fuel system creates strategic resource management
- Standard crafting tables remain for basic items - grid crafting is for **special/unique** items only
- Gold Cores are the most valuable due to teleport ability - Gold Ore should remain rare
