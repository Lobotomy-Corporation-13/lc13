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

## Random Fill-In System

When players don't make selections, the system automatically fills in with random choices.

### Defines

```dm
#define RANDOM_TRAIT_COUNT 2           // Number of random traits if none selected
#define RANDOM_PASSION_COUNT 2         // Additional random passions at spawn
#define TOTAL_STAT_POINTS 10           // 6 player choice + 4 random = 10 total
```

### Random Trait Assignment

If player selects no traits (or doesn't use all points), random traits are assigned:

```dm
/// Assign random traits when player hasn't selected any
/proc/assign_random_resurgence_traits(mob/living/carbon/human/H, list/selected_traits, points_remaining)
	if(!H)
		return list()

	var/list/final_traits = selected_traits?.Copy() || list()
	var/points_to_spend = points_remaining

	// If no traits selected at all, give them RANDOM_TRAIT_COUNT random traits
	if(!length(final_traits))
		points_to_spend = TRAIT_POINT_POOL

	// Get available positive traits (not already selected, no incompatibilities)
	var/list/available_positive = list()
	var/list/available_negative = list()

	for(var/trait_type in subtypesof(/datum/resurgence_trait))
		var/datum/resurgence_trait/T = new trait_type()
		if(T.point_cost > 0)
			available_positive += T
		else if(T.point_cost < 0)
			available_negative += T

	// Remove already selected and incompatible traits
	for(var/datum/resurgence_trait/selected in final_traits)
		available_positive -= selected
		available_negative -= selected
		// Remove incompatible traits
		for(var/datum/resurgence_trait/check in available_positive + available_negative)
			if(check.type in selected.incompatible)
				available_positive -= check
				available_negative -= check

	// Randomly assign traits until points are spent
	var/attempts = 0
	while(points_to_spend > 0 && attempts < 20)
		attempts++

		// Pick a random positive trait we can afford
		var/list/affordable = list()
		for(var/datum/resurgence_trait/T in available_positive)
			if(T.point_cost <= points_to_spend)
				affordable += T

		if(!length(affordable))
			break  // No affordable traits left

		var/datum/resurgence_trait/chosen = pick(affordable)
		final_traits += chosen
		points_to_spend -= chosen.point_cost
		available_positive -= chosen

		// Remove incompatible traits from pool
		for(var/datum/resurgence_trait/check in available_positive)
			if(check.type in chosen.incompatible)
				available_positive -= check

	// Notify player of random traits
	if(length(final_traits) > length(selected_traits))
		var/list/random_names = list()
		for(var/datum/resurgence_trait/T in final_traits)
			if(!(T in selected_traits))
				random_names += T.name
		to_chat(H, span_notice("Random traits assigned: [english_list(random_names)]"))

	return final_traits
```

### Random Stat Allocation

If player doesn't allocate all 6 points, remaining points join the random pool:

```dm
/// Apply stat points with random fill-in for unallocated points
/proc/apply_resurgence_stat_allocation(obj/item/organ/resurgence_core/core, list/player_allocation)
	if(!core)
		return

	var/list/stat_types = GLOB.resurgence_stat_types.Copy()

	// Calculate how many points player allocated
	var/player_points_used = 0
	if(player_allocation)
		for(var/stat in player_allocation)
			player_points_used += player_allocation[stat]

	// Remaining player points become random
	var/unallocated_player_points = STAT_POINT_POOL - player_points_used
	var/total_random_points = RANDOM_STAT_BONUS + unallocated_player_points

	// Apply player's chosen allocation first
	if(player_allocation)
		for(var/stat in player_allocation)
			var/amount = player_allocation[stat]
			if(amount > 0)
				core.add_stat_levels(stat, amount)

	// Distribute random points
	var/list/random_distribution = list()
	for(var/stat in stat_types)
		random_distribution[stat] = 0

	for(var/i in 1 to total_random_points)
		var/stat = pick(stat_types)
		random_distribution[stat]++
		core.add_stat_levels(stat, 1)

	// Notify player of random stats
	if(total_random_points > RANDOM_STAT_BONUS)
		to_chat(core.owner, span_notice("You received [total_random_points] random stat levels ([unallocated_player_points] from unallocated points + [RANDOM_STAT_BONUS] bonus)."))
	else
		to_chat(core.owner, span_notice("You received [RANDOM_STAT_BONUS] random stat levels."))

	// Show distribution
	var/list/stat_summary = list()
	for(var/stat in random_distribution)
		if(random_distribution[stat] > 0)
			stat_summary += "[stat]: +[random_distribution[stat]]"
	if(length(stat_summary))
		to_chat(core.owner, span_notice("Random distribution: [english_list(stat_summary)]"))
```

### Random Passion Assignment

If player doesn't pick a passion, one is randomly assigned:

```dm
/// Setup passions with random fill-in
/proc/setup_resurgence_passions(obj/item/organ/resurgence_core/core, chosen_passion)
	if(!core)
		return

	var/list/stat_types = GLOB.resurgence_stat_types.Copy()
	var/final_chosen = chosen_passion

	// If no passion chosen, pick one randomly
	if(!final_chosen || !(final_chosen in stat_types))
		final_chosen = pick(stat_types)
		to_chat(core.owner, span_notice("No passion selected - randomly assigned: [final_chosen]"))

	// Create passions datum
	var/datum/resurgence_passions/passions = new()
	passions.chosen_passion = final_chosen

	// Remove chosen from pool for random selection
	stat_types -= final_chosen

	// Pick 2 random additional passions
	passions.random_passions = list()
	for(var/i in 1 to RANDOM_PASSION_COUNT)
		if(!length(stat_types))
			break
		var/random_passion = pick_n_take(stat_types)
		passions.random_passions += random_passion

	// Check for "Very Passionate" - if random matched chosen (impossible now, but kept for clarity)
	// This can happen if we modify the system later to allow overlap

	// Set passion levels
	passions.passion_levels = list()
	for(var/stat in GLOB.resurgence_stat_types)
		if(stat == passions.chosen_passion)
			// Check if also in random (Very Passionate)
			if(stat in passions.random_passions)
				passions.passion_levels[stat] = PASSION_PASSIONATE  // 100% bonus
			else
				passions.passion_levels[stat] = PASSION_INTERESTED  // 50% bonus
		else if(stat in passions.random_passions)
			passions.passion_levels[stat] = PASSION_INTERESTED  // 50% bonus
		else
			passions.passion_levels[stat] = PASSION_NONE

	core.passions = passions

	// Notify player of passions
	var/list/passion_summary = list()
	passion_summary += "[passions.chosen_passion] (Chosen)"
	for(var/rp in passions.random_passions)
		passion_summary += "[rp] (Random)"
	to_chat(core.owner, span_notice("Your passions: [english_list(passion_summary)]"))
```

### Complete Spawn Application

Updated spawn hook that handles all random fill-in:

```dm
/// Apply all personalization to a resurgence machine at spawn
/proc/apply_resurgence_personalization(mob/living/carbon/human/H)
	if(!H?.client?.prefs)
		// No preferences - apply fully random build
		apply_random_resurgence_build(H)
		return

	var/datum/preferences/prefs = H.client.prefs
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return

	// === TRAITS ===
	var/list/selected_traits = prefs.resurgence_traits
	var/points_used = 0
	for(var/trait_type in selected_traits)
		var/datum/resurgence_trait/T = new trait_type()
		points_used += T.point_cost

	var/points_remaining = TRAIT_POINT_POOL - points_used
	var/list/final_traits = assign_random_resurgence_traits(H, selected_traits, points_remaining)

	// Apply all traits
	for(var/datum/resurgence_trait/T in final_traits)
		T.apply(H)
		core.applied_traits += T

	// === STATS ===
	var/list/stat_allocation = prefs.resurgence_stat_points
	apply_resurgence_stat_allocation(core, stat_allocation)

	// === PASSIONS ===
	var/chosen_passion = prefs.resurgence_passion
	setup_resurgence_passions(core, chosen_passion)

/// Apply a completely random build (no preferences available)
/proc/apply_random_resurgence_build(mob/living/carbon/human/H)
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return

	to_chat(H, span_notice("No character preferences found - generating random build..."))

	// Random traits (use full point pool)
	var/list/random_traits = assign_random_resurgence_traits(H, list(), TRAIT_POINT_POOL)
	for(var/datum/resurgence_trait/T in random_traits)
		T.apply(H)
		core.applied_traits += T

	// Random stats (all 10 points random)
	apply_resurgence_stat_allocation(core, null)

	// Random passion
	setup_resurgence_passions(core, null)
```

---

## Random Fill-In Summary

| Selection | If Not Selected | If Partially Selected |
|-----------|-----------------|----------------------|
| **Traits** | Random traits assigned using full 4-point budget | Remaining points spent on random positive traits |
| **Stats** | All 10 points distributed randomly | Unspent points added to random pool (6 unspent + 4 bonus = 10 random) |
| **Passion** | One passion randomly assigned | N/A (single choice) |

### Player Notifications

Players are always notified of random assignments:
- `"Random traits assigned: Industrious, Nimble"`
- `"No passion selected - randomly assigned: Mining"`
- `"You received 10 random stat levels (6 from unallocated points + 4 bonus)."`
- `"Random distribution: Mining: +3, Crafting: +2, Farming: +2, Construction: +2, Research: +1"`

### Edge Cases

| Scenario | Behavior |
|----------|----------|
| No preferences (new player) | Fully random build applied |
| Client disconnects before spawn | Random build applied |
| Negative trait points exceed budget | Only selected traits applied, no random fill |
| All traits incompatible | Stop assigning random traits early |

---

## UI Design

### Traits Tab
- Two columns: Positive / Negative
- Point counter: "0/4 points spent"
- Checkboxes with cost and description
- **Note**: "Unspent points will be randomly assigned"

### Passion Tab
- Radio buttons for 5 stats
- Flame icon for selected
- Note about random passions
- **Note**: "If none selected, one will be randomly assigned"

### Stats Tab
- 5 rows with +/- buttons
- Progress bars (1 + allocated)
- Point counter: "0/6 points spent"
- Note: "4 random levels added at spawn"
- **Note**: "Unspent points will be randomly distributed"

---

## Critical Files

- `/code/modules/surgery/organs/resurgence_core.dm` - Stat system
- `/code/modules/mob/living/carbon/human/species_types/resurgence_machine.dm` - Spawn hook
- `/code/modules/client/preferences.dm` - Preference vars
- `/code/modules/client/preferences_savefile.dm` - Save/load
- `/code/datums/quirks/_quirk.dm` - Trait pattern reference
