/**
 * Resurgence Outpost - Gathering Base
 *
 * Shared constants and helper procs for the extended gathering system.
 * Used by trees, ore deposits, and other harvestable resources.
 */

/// Minimum charge required to perform gathering work
#define MIN_CHARGE_FOR_WORK 5

/// Faith drained per work point during gathering
#define FAITH_DRAIN_PER_WORK 0.1

/// Work points added per 1-second gathering tick (base rate)
#define GATHER_WORK_PER_TICK 2

/// Time per gathering tick in deciseconds
#define GATHER_TICK_TIME 1 SECONDS

/// Check if user has enough charge to gather
/proc/can_gather(mob/living/carbon/human/user)
	if(!istype(user))
		return FALSE
	var/obj/item/organ/resurgence_core/core = user.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return FALSE
	return core.charge >= MIN_CHARGE_FOR_WORK

/// Apply faith drain for work done (directly, not via events)
/proc/apply_work_faith_drain(mob/living/carbon/human/user, work_amount)
	if(!istype(user))
		return
	var/obj/item/organ/resurgence_core/core = user.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return
	core.adjust_faith(-FAITH_DRAIN_PER_WORK * work_amount)
