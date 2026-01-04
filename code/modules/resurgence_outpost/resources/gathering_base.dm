/**
 * Resurgence Outpost - Gathering Base
 *
 * Shared constants and helper procs for the extended gathering system.
 * Used by trees, ore deposits, and other harvestable resources.
 */

/// Minimum faith required to perform gathering work
#define MIN_FAITH_FOR_WORK 5

/// Faith drained per work point during gathering
#define FAITH_DRAIN_PER_WORK 0.1

/// Work points added per 1-second gathering tick (base rate)
#define GATHER_WORK_PER_TICK 2

/// Time per gathering tick in deciseconds
#define GATHER_TICK_TIME 2 SECONDS

/// Check if user has enough faith to gather
/proc/can_gather(mob/living/carbon/human/user)
	if(!istype(user))
		return FALSE
	var/obj/item/organ/resurgence_core/core = user.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return FALSE
	return core.faith >= MIN_FAITH_FOR_WORK

/// Apply faith drain for work done (directly, not via events)
/proc/apply_work_faith_drain(mob/living/carbon/human/user, work_amount)
	if(!istype(user))
		return
	var/obj/item/organ/resurgence_core/core = user.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return
	core.adjust_faith(-FAITH_DRAIN_PER_WORK * work_amount)

/// Get the user's mining stat level (returns 1 if not a resurgence machine)
/proc/get_mining_stat(mob/living/carbon/human/user)
	if(!istype(user))
		return 1
	var/obj/item/organ/resurgence_core/core = user.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return 1
	return core.stat_mining

/// Get the user's harvesting stat level (returns 1 if not a resurgence machine)
/proc/get_harvesting_stat(mob/living/carbon/human/user)
	if(!istype(user))
		return 1
	var/obj/item/organ/resurgence_core/core = user.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return 1
	return core.stat_harvesting

/// Award mining XP to the user
/proc/award_mining_xp(mob/living/carbon/human/user, amount)
	if(!istype(user))
		return
	var/obj/item/organ/resurgence_core/core = user.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return
	core.award_xp("mining", amount)

/// Award harvesting XP to the user
/proc/award_harvesting_xp(mob/living/carbon/human/user, amount)
	if(!istype(user))
		return
	var/obj/item/organ/resurgence_core/core = user.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return
	core.award_xp("harvesting", amount)

/// Get the mining yield multiplier (25% bonus every 5 levels)
/// Level 1-4 = 1.0x, Level 5-9 = 1.25x, Level 10-14 = 1.5x, Level 15-19 = 1.75x, Level 20 = 2.0x
/// Also applies global yield modifier from events
/proc/get_mining_yield_multiplier(level)
	var/bonus_tiers = round(level / 5)
	var/base = 1.0 + (bonus_tiers * 0.25)
	// Apply global event modifier
	return base * GLOB.resurgence_yield_modifier

/// Get the harvesting yield bonus (+1 every 5 levels)
/// Level 1-4 = +0, Level 5-9 = +1, Level 10-14 = +2, Level 15-19 = +3, Level 20 = +4
/// Also applies global yield modifier from events
/proc/get_harvesting_yield_bonus(level)
	var/base = round(level / 5)
	// Apply global event modifier (multiply and round)
	return round(base * GLOB.resurgence_yield_modifier)

// Note: Scythe/tool bonuses are now handled by the tool_durability.dm system
// Use get_tool_work_bonus() and get_tool_xp_multiplier() instead
