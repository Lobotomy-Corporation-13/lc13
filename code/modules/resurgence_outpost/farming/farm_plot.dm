/**
 * Resurgence Outpost - Farm Plot
 *
 * Individual farming plots that belong to a farm zone.
 * Plots respond to zone growth ticks rather than processing themselves.
 * Growth stage constants are defined in farm_zone.dm
 */

/obj/structure/farm_plot
	name = "farm plot"
	desc = "Tilled soil ready for planting."
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "soil"
	density = FALSE
	anchored = TRUE
	max_integrity = 100

	/// Reference to managing zone
	var/datum/farm_zone/parent_zone
	/// Currently planted crop (datum, not item)
	var/datum/farm_seed/planted_seed
	/// Water level 0-100
	var/water_level = 0
	/// Current growth stage
	var/growth_stage = FARM_STAGE_EMPTY
	/// Progress toward next stage (zone ticks)
	var/growth_progress = 0
	/// Prevents double-harvesting
	var/being_harvested = FALSE
	/// Accumulated harvest work points
	var/harvest_work_points = 0

/obj/structure/farm_plot/Initialize(mapload)
	. = ..()
	update_icon()

/obj/structure/farm_plot/Destroy()
	if(parent_zone)
		parent_zone.remove_plot(src)
	if(planted_seed)
		QDEL_NULL(planted_seed)
	return ..()

/// Called by zone during shared growth tick
/obj/structure/farm_plot/proc/on_zone_tick()
	if(!planted_seed || growth_stage == FARM_STAGE_EMPTY)
		return

	// Already ready to harvest - don't process further
	if(growth_stage == FARM_STAGE_HARVEST)
		return

	// Drain water
	water_level = max(0, water_level - planted_seed.water_drain)

	// Check water requirement - no water = no growth (but doesn't die)
	if(water_level < planted_seed.min_water)
		return

	// Advance growth progress
	growth_progress += 1
	if(growth_progress >= planted_seed.growth_per_stage)
		growth_progress = 0
		growth_stage = min(growth_stage + 1, FARM_STAGE_HARVEST)
		if(growth_stage == FARM_STAGE_HARVEST)
			visible_message(span_notice("[src] is ready for harvest!"))

	update_icon()

/obj/structure/farm_plot/update_overlays()
	. = ..()
	if(!planted_seed || growth_stage == FARM_STAGE_EMPTY)
		return

	// Add plant overlay based on growth stage
	var/mutable_appearance/plant_overlay = mutable_appearance(planted_seed.plant_icon, planted_seed.get_icon_state(growth_stage))
	. += plant_overlay

// ===== Interactions =====
/obj/structure/farm_plot/attackby(obj/item/I, mob/user, params)
	// Water with reagent containers
	if(istype(I, /obj/item/reagent_containers))
		var/obj/item/reagent_containers/container = I
		if(container.reagents?.has_reagent(/datum/reagent/water))
			var/transfer = min(container.reagents.get_reagent_amount(/datum/reagent/water), 100 - water_level)
			if(transfer > 0)
				container.reagents.remove_reagent(/datum/reagent/water, transfer)
				water_level += transfer
				to_chat(user, span_notice("You water the plot. ([water_level]%)"))
				playsound(src, 'sound/effects/slosh.ogg', 30, TRUE)
				update_icon()
			else
				to_chat(user, span_warning("The plot is already fully watered."))
			return

	// Plant seeds
	if(istype(I, /obj/item/seeds/farm))
		if(planted_seed)
			to_chat(user, span_warning("Something is already planted here."))
			return
		if(growth_stage != FARM_STAGE_EMPTY)
			to_chat(user, span_warning("Clear the plot first."))
			return
		var/obj/item/seeds/farm/seed_item = I
		plant_seed(seed_item.seed_datum)
		to_chat(user, span_notice("You plant [seed_item]."))
		qdel(I)
		return

	return ..()

/// Plant a seed in this plot
/obj/structure/farm_plot/proc/plant_seed(datum/farm_seed/seed)
	// Create a copy of the seed datum for this plot
	planted_seed = new seed.type()
	growth_stage = FARM_STAGE_GROWING_1
	growth_progress = 0
	harvest_work_points = 0
	update_icon()

/obj/structure/farm_plot/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return

	if(growth_stage == FARM_STAGE_EMPTY)
		to_chat(user, span_notice("Nothing is planted here."))
		return

	if(growth_stage != FARM_STAGE_HARVEST)
		to_chat(user, span_warning("This plant isn't ready for harvest yet."))
		return

	if(being_harvested)
		to_chat(user, span_warning("Someone is already harvesting this."))
		return

	if(!ishuman(user))
		return

	start_harvest(user)

/// Begin work-based harvesting
/obj/structure/farm_plot/proc/start_harvest(mob/living/carbon/human/user)
	// Check charge requirement
	if(!can_gather(user))
		to_chat(user, span_warning("You're too exhausted to harvest. You need at least [MIN_CHARGE_FOR_WORK] charge."))
		return

	// Starting message
	if(harvest_work_points > 0)
		var/progress_pct = round((harvest_work_points / planted_seed.harvest_work) * 100)
		to_chat(user, span_notice("You continue harvesting [planted_seed.name]... ([progress_pct]% complete)"))
	else
		to_chat(user, span_notice("You begin harvesting [planted_seed.name]..."))

	playsound(src, 'sound/weapons/thudswoosh.ogg', 30, TRUE)

	being_harvested = TRUE

	// Harvesting loop - continues until interrupted or complete
	while(harvest_work_points < planted_seed.harvest_work)
		// Check charge each tick
		if(!can_gather(user))
			to_chat(user, span_warning("You're too exhausted to continue harvesting."))
			break

		// Do the work tick
		if(!do_after(user, GATHER_TICK_TIME, target = src))
			var/progress_pct = round((harvest_work_points / planted_seed.harvest_work) * 100)
			to_chat(user, span_notice("You stop harvesting. Progress: [progress_pct]%"))
			break

		// Add work and drain faith
		harvest_work_points += GATHER_WORK_PER_TICK
		apply_work_faith_drain(user, GATHER_WORK_PER_TICK)

		// Periodic sound (30% chance each tick)
		if(prob(30))
			playsound(src, 'sound/weapons/thudswoosh.ogg', 30, TRUE)

	being_harvested = FALSE

	// Check completion
	if(harvest_work_points >= planted_seed.harvest_work)
		complete_harvest(user)

/// Finish harvesting and drop produce
/obj/structure/farm_plot/proc/complete_harvest(mob/user)
	user.visible_message(
		span_notice("[user] harvests [planted_seed.name]."),
		span_notice("You harvest [planted_seed.name]!"),
		span_hear("You hear rustling.")
	)
	playsound(src, 'sound/weapons/thudswoosh.ogg', 50, TRUE)

	// Create produce
	var/product_type = planted_seed.product_type
	var/product_amount = planted_seed.product_amount
	if(ispath(product_type, /obj/item/stack))
		new product_type(get_turf(src), product_amount)
	else
		for(var/i in 1 to product_amount)
			new product_type(get_turf(src))

	// Reset work points
	harvest_work_points = 0

	// Handle regrowth or clear
	if(planted_seed.regrows)
		growth_stage = FARM_STAGE_GROWING_1
		growth_progress = 0
	else
		QDEL_NULL(planted_seed)
		growth_stage = FARM_STAGE_EMPTY

	update_icon()

/obj/structure/farm_plot/examine(mob/user)
	. = ..()
	. += span_notice("Water level: [water_level]%")
	if(planted_seed)
		switch(growth_stage)
			if(FARM_STAGE_GROWING_1)
				. += span_notice("[planted_seed.name] - Seedling")
			if(FARM_STAGE_GROWING_2)
				. += span_notice("[planted_seed.name] - Growing")
			if(FARM_STAGE_GROWING_3)
				. += span_notice("[planted_seed.name] - Almost ready")
			if(FARM_STAGE_HARVEST)
				. += span_notice("[planted_seed.name] - Ready to harvest!")
				if(harvest_work_points > 0)
					var/progress_pct = round((harvest_work_points / planted_seed.harvest_work) * 100)
					. += span_notice("Harvest progress: [progress_pct]%")
		if(water_level < planted_seed.min_water && growth_stage != FARM_STAGE_HARVEST)
			. += span_warning("Needs water to grow!")
	else
		. += span_notice("Ready for planting.")
	if(parent_zone)
		. += span_notice("Part of farm zone: [parent_zone.name]")
