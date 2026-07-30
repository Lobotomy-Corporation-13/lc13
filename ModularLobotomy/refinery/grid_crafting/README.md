# Grid Crafting System

A weapon/armor crafting minigame where players navigate an invisible 2D
coordinate grid using "navigation cores" until they land close enough to a
hidden weapon to craft it. Where a weapon sits on the grid is determined by its
power: stronger weapons are placed far from the origin, so reaching them costs
more cores (and therefore more Ahn).

Think of it as a **dartboard you can't fully see**. Each weapon is a target
somewhere on the board. Each core you use nudges your "dart" (the focus point)
across the board. When your focus point lands inside a weapon's radius, you can
craft it. Cheap weapons are near the bullseye (origin); endgame weapons are out
near the edges and require many precise moves to reach.

---

## Table of Contents

1. [The Big Picture](#the-big-picture)
2. [Player Loop (Step by Step)](#player-loop-step-by-step)
3. [The Files](#the-files)
4. [Core Concepts](#core-concepts)
   - [The Grid & Focus Point](#the-grid--focus-point)
   - [Weapon/Armor Placement (Tiers)](#weaponarmor-placement-tiers)
   - [Templates → Cores](#templates--cores)
   - [Chems → Movement Types (Sins)](#chems--movement-types-sins)
   - [Movement Types](#movement-types)
   - [Distance Calculation](#distance-calculation)
   - [Diminishing Returns](#diminishing-returns)
   - [Grid Zones](#grid-zones)
   - [Shuffling](#shuffling)
   - [Tier Unlocking (Ordeals)](#tier-unlocking-ordeals)
5. [Key Data Flow](#key-data-flow)
6. [Where to Change Things](#where-to-change-things)

---

## The Big Picture

There are **three machines** and **two items**:

| Thing | What it is |
|-------|------------|
| **Template Vendor** (`template_vendor.dm`) | Buy empty core templates with Ahn. |
| **Core Template** (`core_template.dm`) | An empty reagent container. Fill it with an abnormality chem, then activate to produce a Navigation Core. |
| **Navigation Core** (`navigation_core.dm`) | The finished, single-use item. Its chem decides *how* it moves; its template grade decides *how far*. |
| **Grid Crafting Station** (`grid_station.dm`) | The main machine. Insert cores, use them to move the focus point across the grid, and craft weapons/armor you reach. |
| **Debug Vendor** (`debug_vendor.dm`) | Admin tool to spawn any core/template for free. |

The whole point: **Ahn (template) + Abnochem (chem) → a navigation core → a
move on the grid → eventually a free city weapon.**

---

## Player Loop (Step by Step)

1. **Buy a template** from the Template Vendor (`50`–`1000` Ahn depending on
   grade). Grade sets the distance-per-move and the max weapon tier you can
   reach.
2. **Fill the template** with an abnormality chem (a "sin" reagent or a derived
   abnochem). The chem decides the **movement type**. How *much* chem you add
   scales the distance (5u = 50%, 15u = 100%, 25u = 150%) — unless it's an
   advanced chem that ignores quantity.
3. **Activate the template in hand** → it becomes a **Navigation Core**.
4. **Insert cores** into the Grid Crafting Station (`attackby`).
5. **Open the station UI**, select a core, and **move**. The core is consumed.
   The focus point shifts based on the core's movement type and rolled distance.
6. **Repeat** until your focus point lands inside a weapon's radius.
7. **Craft** the weapon (if its tier is unlocked). The weapon spawns on the
   floor, your focus point resets to origin, and you start again.

---

## The Files

| File | Responsibility |
|------|----------------|
| `code/__DEFINES/~lobotomy_defines/grid_crafting.dm` | **All tuning constants** (costs, distances, tiers, zone balance, movement modifiers). Not in this folder, but it's the balance knob for everything here. |
| `grid_system.dm` | The brain. The grid manager: weapon/armor placement, movement math, zones, shuffling, weapon discovery/caching. |
| `grid_station.dm` | The crafting machine object + its TGUI data/actions. |
| `core_template.dm` | The purchasable empty template; turns chem into a core. |
| `navigation_core.dm` | The finished core item; rolls distance and renders its appearance. |
| `chem_mapping.dm` | Lookup tables: chem → movement type, movement → name/modifier/sin, and the diminishing-returns math. |
| `template_vendor.dm` | Buy templates with Ahn. |
| `debug_vendor.dm` | Admin spawner. |

TGUI frontends (referenced by name, live in `tgui/packages/tgui/interfaces/`):
`EnkephalinGridStation`, `CoreTemplateVendor`, `GridDebugVendor`.

---

## Core Concepts

### The Grid & Focus Point

The grid is a continuous 2D plane centered on `(0, 0)`. The player's current
position is the **focus point** (`focus_x`, `focus_y` on
`/datum/grid_craft_manager`). Every move recomputes the focus point. Crafting or
resetting returns it to the origin.

Coordinates are floats rounded to 0.1; there is no fixed grid boundary — weapons
can be placed hundreds of units out.

### Weapon/Armor Placement (Tiers)

Each weapon is a `/datum/grid_craft_item` with a coordinate, a **craft radius**
(how close you must get), and a **tier** (0–4). Tier is derived from the
weapon's highest `attribute_requirements` value:

| Tier | Highest attribute req | Distance from origin | Expected cost |
|------|----------------------|----------------------|---------------|
| 0 | < 60 | 20–40 | ~100–200 Ahn |
| 1 | 60–79 | 40–80 | ~300–600 Ahn |
| 2 | 80–99 | 60–120 | ~800–1600 Ahn |
| 3 | 100–119 | 140–280 | ~2000–4000 Ahn |
| 4 | ≥ 120 | 300–550 | ~6000–12000 Ahn |

Placement happens in `PlaceItemsFromCache()`: each item is dropped at a random
angle and a tier-appropriate distance. The craft radius shrinks for higher tiers
(harder to hit) and also scales by **how many items share that tier** — if a tier
is crowded, radii shrink so they don't overlap into one giant blob; if a tier is
sparse, radii grow so they're still findable.

Weapons and armor live on **two separate grids** (`items` vs `armor_items`). The
player flips between them with the "flip" action (`viewing_armor`).

### Templates → Cores

A **template** (`/obj/item/reagent_containers/core_template`) is just a fancy
beaker. It has a **grade** (Basic/Standard/Quality/Superior) that sets:

- `min_distance` / `max_distance` — the base distance range of cores made from it.
- `max_tier` — the highest weapon tier a core from it can reach.
- `cost` — Ahn price at the vendor.

Activating a filled template (`attack_self`) reads its reagent, looks up the
movement type via `GetMovementFromChem()`, computes the quantity modifier, and
spawns a finished `/obj/item/navigation_core`, copying grade/distance/tier onto
it. The template is consumed.

### Chems → Movement Types (Sins)

The chem you put in the template decides the **movement pattern**, themed around
the seven deadly sins. The mapping lives in `GetMovementFromChem()`
(`chem_mapping.dm`), which returns `list(movement_type, bypasses_quantity, sin_type)`.

| Sin | Movement | Example chems |
|-----|----------|---------------|
| Wrath | Charge | sin/wrath, tastesyrup, nutrition, gaspilleur |
| Lust | Attract | sin/lust, violence, odisone, onesin |
| Sloth | Shuffle | sin/sloth, heartysyrup, cleanliness, piedrabital |
| Gluttony | Expand | sin/gluttony, abno_oil, serelam, fairy_festival |
| Gloom | Drift | sin/gloom, focussyrup, consensus, woe, nepenthe |
| Pride | Teleport | sin/pride, dyscrasone, bald |
| Envy | Mirror | sin/envy, bittersyrup, amusement, lesser_sange_rau |

Chems come in "levels":
- **Level 1 (raw sins) & Level 2 (syrups):** affected by quantity (`bypasses_quantity = FALSE`).
- **Level 3+ (derivatives / high-level abnochems):** `bypasses_quantity = TRUE`,
  so they always craft at 100% distance regardless of how much you load.

### Movement Types

How the focus point moves, executed by the `Execute*` procs in `grid_system.dm`.
Each type also has a permanent **distance modifier** (`MOVEMENT_MOD_*`) — more
*accurate* movements travel *shorter* distances, balancing precision against reach.

| Type | Behavior | Dist. mod | Notes |
|------|----------|-----------|-------|
| **Charge** (Wrath) | Straight line, one cardinal axis only | 1.0 | Distance roll favors the high end (max of two rolls). |
| **Attract** (Lust) | Moves toward the highlighted weapon (or nearest) | 0.8 | Extra −40% distance penalty; very accurate. |
| **Shuffle** (Sloth) | Random direction, random 50–100% distance | 1.75 | Longest reach, no control. |
| **Expand** (Gluttony) | Any of 8 directions (diagonals split distance) | 0.75 | |
| **Drift** (Gloom) | Cardinal move + random perpendicular shift | 1.2 | Imprecise "curved" path. |
| **Teleport** (Pride) | Jump straight to chosen coordinates | 0.5 | Fails if target is beyond max range. |
| **Mirror** (Envy) | Re-runs the *previous* move's type with its own distance | 1.1 | Acts like Shuffle if no prior move exists. |

Direction inputs (`dir_x`, `dir_y`) and teleport targets come from the TGUI as
`move` / `teleport` actions.

### Distance Calculation

The distance a single core actually moves is built up in layers
(`navigation_core.dm` → `grid_system.dm`):

```
base roll        rand(min_distance, max_distance)   ← from template grade
× movement mod   MOVEMENT_MOD_<type>                ← accuracy tradeoff
× quantity mod   0.5–1.5 (or 1.0 if bypassed)       ← how much chem was used
× diminishing    1.0 down to 0.25                   ← repeated-sin penalty
× zone mult      Tailwind ×1.5 / Drag ×0.5          ← where you departed from
= final distance
```

`RollDistance()` does the first three; `GetFinalDistance()` adds diminishing;
`UseCore()` applies the zone multiplier last.

### Diminishing Returns

To stop players from spamming one easy movement type, each station tracks how
often each **sin** has been used in `sin_overuse_counts` (sin → count). Logic is
in `chem_mapping.dm`:

- Each use of a sin **increments** its counter (capped at `DIMINISHING_MAX_STACK = 6`).
- Each use **decrements every *other* sin's** counter by 1 (removed at 0).
- The distance penalty is `(count − 1) × 15%`, capped at **−75%**.

So hammering one sin repeatedly tanks its distance, while diversifying your cores
lets the unused sins recover. A **Resonance Zone** wipes all counters instantly.

### Grid Zones

Generated once per station in `GenerateZones()` and persisting across shuffles,
zones are irregular blobs of 10×10 cells (built by random flood-fill in
`GenerateBlob()`). They are shared between the weapon and armor grids. Zone
effects are evaluated at the focus point's **departure** position in `UseCore()`:

| Zone | Effect |
|------|--------|
| **Tailwind** | ×1.5 distance on moves starting here. |
| **Drag** | ×0.5 distance on moves starting here. |
| **Resonance** | Clears all diminishing-returns counters. |
| **Exclusion** | Blocks 2–3 specific movement types entirely (move fails). |

Zones can stack if blobs overlap a cell (multipliers multiply together).

### Shuffling

To keep the grid from being "solved," weapon/armor positions periodically
**reshuffle** (`ShuffleWeapons()` → re-rolls `placement_seed` and re-places
everything). It's driven by points, not a fixed count:

- Crafting adds points by tier: T0=+1, T1=+2, T2=+3, T3=+5.
- **T4 craft = immediate shuffle.**
- When `shuffle_counter` ≥ `shuffle_threshold` (a random 8–15), the grid
  reshuffles and the threshold re-rolls.

### Tier Unlocking (Ordeals)

Even if a player can *reach* a high-tier weapon, they can only **craft** it if
the facility has unlocked that tier. This is **global** (shared by all stations)
and driven by ordeal completions, tracked in `GLOB.grid_craft_ordeal_tier`:

| Ordeal | Unlocks |
|--------|---------|
| Dawn | Tier 1 |
| Noon | Tier 2 |
| Dusk | Tier 3 |
| Midnight (or higher) | Tier 4 |

The station listens for `COMSIG_GLOB_ORDEAL_END` (registered once globally) in
`OnOrdealComplete()`. Higher-tier weapons are still **visible** on the grid but
shown **locked** until the matching ordeal clears. A core's template `max_tier`
and the ordeal tier are independent gates — you need both the reach *and* the
unlock. Debug stations (`/debug` subtype) ignore the gate.

---

## Key Data Flow

```
Template Vendor ──(buy, Ahn)──▶ Core Template (empty)
                                     │
                          fill with abnochem reagent
                                     │
                         attack_self() finalizes it
                                     ▼
                            Navigation Core
                          (movement + grade)
                                     │
                       attackby() into Station
                                     │
              select_core ▶ move/teleport (UI action)
                                     ▼
        grid_manager.UseCore()  ── consumes core
            ├─ zone check (departure)
            ├─ Execute<MovementType>()  → new focus point
            └─ apply diminishing returns
                                     │
              focus point lands in a weapon's radius
                                     │
                   craft (UI) ▶ CraftItem()
                     ├─ tier-access check (ordeal)
                     ├─ spawn weapon on floor
                     ├─ AddShufflePoints()
                     └─ ResetFocus()
```
