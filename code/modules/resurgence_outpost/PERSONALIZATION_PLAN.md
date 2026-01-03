# Resurgence Character Personalization System

## Overview

A character customization system for Resurgence Machines with traits, passions, and starting stat allocation. Inspired by Rimworld's trait/passion systems.

---

## Core Features

### 1. Trait System
- **Point Budget**: 4 points for positive traits
- **Positive Traits**: Cost 1-3 points, provide bonuses
- **Negative Traits**: Give 1-2 points back, provide penalties
- Traits can have incompatibilities (e.g., Industrious + Lazy)

### 2. Passion System
- **Chosen Passion**: Player picks ONE stat = 50% XP bonus
- **Random Passions**: 2 additional passions randomly assigned at spawn
- **Very Passionate**: If chosen matches a random = 100% XP bonus (double)

### 3. Starting Stat Allocation
- **Point Budget**: 6 points to allocate
- **Max Per Stat**: 4 levels in any single skill
- **Random Bonus**: 4 levels randomly distributed at spawn
- Base stats start at level 1

### 4. UI Access
- Accessed via Preferences menu (like quirks)

---

## Trait List

### Positive Traits

| Trait | Cost | Effect |
|-------|------|--------|
| Industrious | 2 | +15% work speed on all tasks |
| Quick Learner | 2 | +25% XP gain from all activities |
| Tough | 2 | +3 brute and burn damage reduction |
| Green Thumb | 1 | +20% harvesting yield |
| Steady Hand | 1 | +2 beauty bonus on crafted/built items |
| Iron-Willed | 2 | Faith decreases 20% slower from negative events |
| Meticulous | 1 | +1 quality tier on crafted tools |
| Nimble | 1 | +10% movement speed |
| Kind | 2 | Hugging someone gives them a faith event (+0.2 faith/5s for 1 min). 1 min cooldown. |
| Beautiful | 2 | Character has a beauty component of +3, improving room quality when present. |
| Pretty | 1 | Character has a beauty component of +1, slightly improving room quality when present. |

### Negative Traits

| Trait | Points | Effect |
|-------|--------|--------|
| Lazy | -2 | -15% work speed on all tasks |
| Slow Learner | -2 | -25% XP gain from all activities |
| Pessimist | -2 | -10 maximum faith (90 instead of 100) |
| Clumsy | -1 | 15% chance to waste 1 material when crafting |
| Sickly | -1 | Faith decreases 20% faster from negative events |
| Slowpoke | -1 | -10% movement speed |
| Nervous | -1 | -10% work speed when faith below 50 |
| Ugly | -1 | Character has a beauty component of -2, reducing room quality when present. |
| Staggeringly Ugly | -2 | Character has a beauty component of -5, significantly reducing room quality. |

### Mixed Traits (Trade-offs)

| Trait | Cost | Effect |
|-------|------|--------|
| Too Smart | 1 | +50% XP gain from all activities, but faith decreases 30% faster from negative events. |

---

## Files to Create

| File | Description |
|------|-------------|
| `code/modules/resurgence_outpost/personalization/_personalization.dm` | Defines and globals |
| `code/modules/resurgence_outpost/personalization/traits.dm` | Trait datum definitions |
| `code/modules/resurgence_outpost/personalization/passions.dm` | Passion system |
| `code/modules/resurgence_outpost/personalization/starting_stats.dm` | Stat allocation |
| `code/modules/resurgence_outpost/personalization/preferences_ui.dm` | TGUI handler |
| `tgui/packages/tgui/interfaces/ResurgenceCharacterSetup.js` | Character setup UI |

## Files to Modify

| File | Changes |
|------|---------|
| `code/modules/surgery/organs/resurgence_core.dm` | Add passion vars, modify award_xp() |
| `code/modules/mob/living/carbon/human/species_types/resurgence_machine.dm` | Apply personalization at spawn |
| `code/modules/client/preferences.dm` | Add resurgence preference vars |
| `code/modules/client/preferences_savefile.dm` | Save/load resurgence prefs |
| `lobotomy-corp13.dme` | Include new files |

---

## Data Structures

### Defines

```dm
#define TRAIT_POINT_POOL 4
#define STAT_POINT_POOL 6
#define MAX_STARTING_STAT 4
#define RANDOM_STAT_BONUS 4

#define PASSION_NONE 0
#define PASSION_INTERESTED 1    // 50% XP bonus
#define PASSION_PASSIONATE 2    // 100% XP bonus
```

### Trait Datum

```dm
/datum/resurgence_trait
    var/name = "Unnamed"
    var/desc = "Description"
    var/point_cost = 0
    var/list/incompatible = list()

    proc/apply(mob/living/carbon/human/H)
    proc/remove(mob/living/carbon/human/H)
```

### Core Modifications

```dm
/obj/item/organ/resurgence_core
    var/datum/resurgence_passions/passions
    var/work_speed_modifier = 1.0
    var/xp_gain_modifier = 1.0
    var/yield_modifier = 1.0
    var/list/applied_traits = list()
```

---

## Implementation Steps

### Step 1: Create Core Definitions
- Create `_personalization.dm` with defines
- Define `GLOB.resurgence_stat_types` list
- Define passion level constants

### Step 2: Create Trait System
- Create base `/datum/resurgence_trait` class
- Implement all 16 traits (8 positive, 8 negative)
- Each trait has `apply()` and `remove()` procs

### Step 3: Create Passion System
- Create `/datum/resurgence_passions` datum
- Implement `get_xp_multiplier(stat_type)` proc
- Handle chosen + random passion merging

### Step 4: Modify resurgence_core.dm
- Add passion and trait modifier variables
- Modify `award_xp()` to apply:
  1. `xp_gain_modifier` from traits
  2. Passion multiplier

### Step 5: Add Preference Storage
- Add to `/datum/preferences`:
  - `var/list/resurgence_traits`
  - `var/resurgence_passion`
  - `var/list/resurgence_stat_points`
- Add save/load in `preferences_savefile.dm`

### Step 6: Create Spawn Application
- Modify `resurgence_machine.dm` species
- In spawn hook:
  1. Apply allocated stat points
  2. Apply 4 random stat bonuses
  3. Setup passions (chosen + 2 random)
  4. Apply selected traits
  5. Notify player of random passions

### Step 7: Create TGUI Interface
- Create `ResurgenceCharacterSetup.js` with 3 tabs:
  1. Traits tab - select positive/negative
  2. Passion tab - choose one stat
  3. Stats tab - allocate 6 points

### Step 8: Hook into Preferences
- Add section/button in preferences UI
- Or create new preference panel

---

## Passion XP Calculation

In `award_xp()`:

```dm
// Apply trait XP modifier
amount *= xp_gain_modifier

// Apply passion bonus
if(passions)
    amount *= passions.get_xp_multiplier(stat_type)

// Multipliers:
// PASSION_NONE = 1.0x
// PASSION_INTERESTED = 1.5x
// PASSION_PASSIONATE = 2.0x
```

---

## Random Passion Assignment

```dm
// Pick 2 random from stats not chosen
var/list/available = GLOB.resurgence_stat_types.Copy()
if(chosen)
    available -= chosen

var/list/random_passions = list()
for(var/i in 1 to 2)
    if(length(available))
        random_passions += pick_n_take(available)

// If chosen in random_passions = Very Passionate
```

---

## UI Design

### Traits Tab
- Two columns: Positive / Negative
- Point counter: "0/4 points spent"
- Checkboxes with cost and description

### Passion Tab
- Radio buttons for 5 stats
- Flame icon for selected
- Note about random passions

### Stats Tab
- 5 rows with +/- buttons
- Progress bars (1 + allocated)
- Point counter: "0/6 points spent"
- Note: "4 random levels added at spawn"

---

## Critical Files

- `/code/modules/surgery/organs/resurgence_core.dm` - Stat system
- `/code/modules/mob/living/carbon/human/species_types/resurgence_machine.dm` - Spawn hook
- `/code/modules/client/preferences.dm` - Preference vars
- `/code/modules/client/preferences_savefile.dm` - Save/load
- `/code/datums/quirks/_quirk.dm` - Trait pattern reference
