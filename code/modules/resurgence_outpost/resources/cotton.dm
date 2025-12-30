/**
 * Resurgence Outpost - Cotton Plants
 *
 * Harvestable cotton plants with work-based progress.
 * Cotton plants regenerate after being harvested.
 *
 * Growth stages (icons/obj/hydroponics/growing.dmi):
 * - cotton-grow1: Seedling (just started regrowing)
 * - cotton-grow2: Growing
 * - cotton-grow3: Almost mature
 * - cotton-harvest: Ready to harvest
 * - cotton-dead: Dead plant
 */

/// Growth stage constants
#define COTTON_STAGE_SEEDLING 1
#define COTTON_STAGE_GROWING 2
#define COTTON_STAGE_MATURING 3
#define COTTON_STAGE_HARVEST 4
#define COTTON_STAGE_DEAD 5

/obj/structure/resurgence_cotton
	name = "cotton plant"
	desc = "A fluffy cotton plant ready for harvesting."
	icon = 'icons/obj/hydroponics/growing.dmi'
	icon_state = "cotton-harvest"
	density = FALSE
	anchored = TRUE
	max_integrity = 50

	/// Current work points accumulated
	var/work_points = 0
	/// Total work points needed to harvest
	var/work_needed = 60
	/// Base amount of cotton dropped when harvested
	var/base_yield = 5
	/// Whether someone is currently harvesting
	var/being_worked = FALSE
	/// Current growth stage
	var/growth_stage = COTTON_STAGE_HARVEST
	/// Time between growth stages when regrowing
	var/growth_time = 1 MINUTES

/obj/structure/resurgence_cotton/Initialize(mapload)
	. = ..()
	update_icon()

/obj/structure/resurgence_cotton/update_icon_state()
	. = ..()
	switch(growth_stage)
		if(COTTON_STAGE_SEEDLING)
			icon_state = "cotton-grow1"
		if(COTTON_STAGE_GROWING)
			icon_state = "cotton-grow2"
		if(COTTON_STAGE_MATURING)
			icon_state = "cotton-grow3"
		if(COTTON_STAGE_HARVEST)
			icon_state = "cotton-harvest"
		if(COTTON_STAGE_DEAD)
			icon_state = "cotton-dead"

/obj/structure/resurgence_cotton/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return

	if(growth_stage != COTTON_STAGE_HARVEST)
		if(growth_stage == COTTON_STAGE_DEAD)
			to_chat(user, span_warning("This plant is dead."))
		else
			to_chat(user, span_warning("This plant isn't ready for harvest yet. It needs time to grow."))
		return

	if(being_worked)
		to_chat(user, span_warning("Someone is already harvesting this plant."))
		return

	if(!ishuman(user))
		return

	start_harvesting(user)

/obj/structure/resurgence_cotton/attackby(obj/item/W, mob/user, params)
	if(growth_stage != COTTON_STAGE_HARVEST)
		if(growth_stage == COTTON_STAGE_DEAD)
			to_chat(user, span_warning("This plant is dead."))
		else
			to_chat(user, span_warning("This plant isn't ready for harvest yet. It needs time to grow."))
		return

	if(being_worked)
		to_chat(user, span_warning("Someone is already harvesting this plant."))
		return

	// Allow harvesting with any item (or bare hands via attack_hand)
	if(!ishuman(user))
		return ..()

	start_harvesting(user)

/obj/structure/resurgence_cotton/proc/start_harvesting(mob/living/carbon/human/user)
	// Check faith requirement
	if(!can_gather(user))
		to_chat(user, span_warning("You're too exhausted to harvest. You need at least [MIN_FAITH_FOR_WORK] faith."))
		return

	// Work rate - cotton harvesting is done by hand at base rate
	var/work_per_tick = GATHER_WORK_PER_TICK

	// Starting message
	if(work_points > 0)
		var/progress_pct = round((work_points / work_needed) * 100)
		to_chat(user, span_notice("You continue harvesting [src]... ([progress_pct]% complete)"))
	else
		to_chat(user, span_notice("You begin harvesting [src]..."))

	playsound(src, 'sound/weapons/thudswoosh.ogg', 30, TRUE)

	being_worked = TRUE

	// Harvesting loop - continues until interrupted or complete
	while(work_points < work_needed)
		// Check faith each tick
		if(!can_gather(user))
			to_chat(user, span_warning("You're too exhausted to continue harvesting."))
			break

		// Do the work tick
		if(!do_after(user, GATHER_TICK_TIME, target = src))
			var/progress_pct = round((work_points / work_needed) * 100)
			to_chat(user, span_notice("You stop harvesting [src]. Progress: [progress_pct]%"))
			break

		// Add work and drain faith
		work_points += work_per_tick
		apply_work_faith_drain(user, work_per_tick)

		// Periodic sound (30% chance each tick)
		if(prob(30))
			playsound(src, 'sound/weapons/thudswoosh.ogg', 30, TRUE)

	being_worked = FALSE

	// Check completion
	if(work_points >= work_needed)
		complete_harvest(user)

/obj/structure/resurgence_cotton/proc/complete_harvest(mob/user)
	if(user)
		user.visible_message(
			span_notice("[user] finishes harvesting [src]."),
			span_notice("You harvest the cotton from [src]!"),
			span_hear("You hear rustling.")
		)
	else
		// Harvester or other automated source
		visible_message(span_notice("[src] is harvested!"))
	playsound(src, 'sound/weapons/thudswoosh.ogg', 50, TRUE)

	// Calculate yield
	var/yield = base_yield

	// Drop cotton
	new /obj/item/stack/sheet/cotton(get_turf(src), yield)

	// Start regrowth from seedling stage
	growth_stage = COTTON_STAGE_SEEDLING
	work_points = 0
	update_icon()

	// Start growth cycle
	addtimer(CALLBACK(src, PROC_REF(advance_growth)), growth_time)

/// Advance to the next growth stage
/obj/structure/resurgence_cotton/proc/advance_growth()
	if(growth_stage >= COTTON_STAGE_HARVEST || growth_stage == COTTON_STAGE_DEAD)
		return

	growth_stage++
	update_icon()

	// Continue growing if not yet harvestable
	if(growth_stage < COTTON_STAGE_HARVEST)
		addtimer(CALLBACK(src, PROC_REF(advance_growth)), growth_time)
	else
		// Ready to harvest
		visible_message(span_notice("[src] is now ready for harvest."))

/obj/structure/resurgence_cotton/examine(mob/user)
	. = ..()
	switch(growth_stage)
		if(COTTON_STAGE_SEEDLING)
			. += span_notice("It's a tiny seedling, just starting to grow.")
		if(COTTON_STAGE_GROWING)
			. += span_notice("It's growing steadily.")
		if(COTTON_STAGE_MATURING)
			. += span_notice("It's almost ready for harvest.")
		if(COTTON_STAGE_HARVEST)
			if(work_points > 0)
				var/progress_pct = round((work_points / work_needed) * 100)
				. += span_notice("It has been partially harvested. ([progress_pct]% complete)")
				. += span_notice("Anyone can continue harvesting it.")
			else
				. += span_notice("It's ready to be harvested by hand.")
		if(COTTON_STAGE_DEAD)
			. += span_warning("It's dead and withered.")

// ===== Cotton Plant Variants =====

/obj/structure/resurgence_cotton/wild
	name = "wild cotton plant"
	desc = "A wild cotton plant growing in the outskirts. Its fluffy bolls are ready to pick."
	base_yield = 3
	work_needed = 40
	/// Wild cotton dies after harvest instead of regrowing
	var/dies_after_harvest = TRUE

/obj/structure/resurgence_cotton/wild/complete_harvest(mob/user)
	if(user)
		user.visible_message(
			span_notice("[user] finishes harvesting [src]."),
			span_notice("You harvest the cotton from [src]. The plant withers away."),
			span_hear("You hear rustling.")
		)
	else
		// Harvester or other automated source
		visible_message(span_notice("[src] is harvested and withers away!"))
	playsound(src, 'sound/weapons/thudswoosh.ogg', 50, TRUE)

	// Drop cotton
	new /obj/item/stack/sheet/cotton(get_turf(src), base_yield)

	// Wild cotton dies after harvest
	qdel(src)

/obj/structure/resurgence_cotton/large
	name = "large cotton plant"
	desc = "A particularly healthy cotton plant with abundant fluffy bolls."
	base_yield = 8
	work_needed = 80
	growth_time = 1.5 MINUTES

#undef COTTON_STAGE_SEEDLING
#undef COTTON_STAGE_GROWING
#undef COTTON_STAGE_MATURING
#undef COTTON_STAGE_HARVEST
#undef COTTON_STAGE_DEAD
