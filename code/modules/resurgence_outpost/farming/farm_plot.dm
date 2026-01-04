/**
 * Resurgence Outpost - Farm Plot
 *
 * Individual farming plots that belong to a farm zone.
 * Plots respond to zone growth ticks rather than processing themselves.
 * Compatible with standard hydroponics /obj/item/seeds
 */

/// Base harvest work required (can be modified by potency)
#define FARM_HARVEST_WORK_BASE 5
/// Water drain per zone tick (reduced by 75% for resurgence farming)
#define FARM_WATER_DRAIN 1
/// Minimum water level for growth
#define FARM_MIN_WATER 10
/// Growth rate multiplier (3x slower than normal hydroponics)
#define FARM_GROWTH_MULTIPLIER 3

/obj/structure/farm_plot
	name = "farm plot"
	desc = "Tilled soil ready for planting."
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "soil"
	density = FALSE
	anchored = TRUE
	max_integrity = 500

	/// Reference to managing zone
	var/datum/farm_zone/parent_zone
	/// Currently planted seed (standard hydroponics seed)
	var/obj/item/seeds/myseed
	/// Water level 0-100
	var/water_level = 0
	/// Growth age in zone ticks
	var/age = 0
	/// Ready to harvest?
	var/harvest = FALSE
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
	// Drop the planted seed onto the ground
	if(myseed)
		var/turf/T = get_turf(src)
		if(T)
			myseed.forceMove(T)
		else
			QDEL_NULL(myseed)
		myseed = null
	return ..()

/// Called by zone during shared growth tick
/obj/structure/farm_plot/proc/on_zone_tick()
	if(!myseed)
		return

	// Already ready to harvest - don't process further
	if(harvest)
		return

	// Drain water
	water_level = max(0, water_level - FARM_WATER_DRAIN)

	// Check water requirement - no water = no growth (but doesn't die)
	if(water_level < FARM_MIN_WATER)
		update_icon()
		return

	// Advance age (apply global growth modifier from events)
	// Higher modifier = faster growth
	age += GLOB.resurgence_growth_modifier

	// Check if ready to harvest (based on maturation * growth multiplier)
	if(age >= myseed.maturation * FARM_GROWTH_MULTIPLIER)
		harvest = TRUE
		visible_message(span_notice("[src] is ready for harvest!"))

	update_icon()

/obj/structure/farm_plot/update_icon()
	. = ..()
	cut_overlays()
	update_icon_plant()
	update_icon_water()

/// Update plant overlay based on growth stage (using hydroponics seed properties)
/obj/structure/farm_plot/proc/update_icon_plant()
	if(!myseed)
		return

	var/icon_state_to_use
	if(harvest)
		// Use harvest icon or final growth stage
		if(myseed.icon_harvest)
			icon_state_to_use = myseed.icon_harvest
		else
			icon_state_to_use = "[myseed.icon_grow][myseed.growthstages]"
	else
		// Calculate growth stage from age vs adjusted maturation
		var/adjusted_maturation = myseed.maturation * FARM_GROWTH_MULTIPLIER
		var/growth_percent = age / max(adjusted_maturation, 1)
		var/stage = clamp(round(growth_percent * myseed.growthstages) + 1, 1, myseed.growthstages)
		icon_state_to_use = "[myseed.icon_grow][stage]"

	var/mutable_appearance/plant_overlay = mutable_appearance(myseed.growing_icon, icon_state_to_use, layer = OBJ_LAYER + 0.01)
	add_overlay(plant_overlay)

/// Update water indicator overlay
/obj/structure/farm_plot/proc/update_icon_water()
	// Show low water indicator when planted and needs water
	if(myseed && !harvest)
		if(water_level <= FARM_MIN_WATER)
			add_overlay(mutable_appearance('icons/obj/hydroponics/equipment.dmi', "over_lowwater3"))
	// Show harvest indicator when ready
	if(harvest)
		add_overlay(mutable_appearance('icons/obj/hydroponics/equipment.dmi', "over_harvest3"))

// ===== Interactions =====
/obj/structure/farm_plot/attackby(obj/item/I, mob/user, params)
	// Scythe triggers harvesting if ready
	if(istype(I, /obj/item/scythe))
		if(!myseed)
			to_chat(user, span_notice("Nothing is planted here."))
			return
		if(!harvest)
			to_chat(user, span_warning("This plant isn't ready for harvest yet."))
			return
		if(being_harvested)
			to_chat(user, span_warning("Someone is already harvesting this."))
			return
		if(ishuman(user))
			start_harvest(user)
		return

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

	// Plant any hydroponics seed
	if(istype(I, /obj/item/seeds))
		if(myseed)
			to_chat(user, span_warning("Something is already planted here."))
			return
		var/obj/item/seeds/S = I
		// Check if this seed can be harvested
		if(S.yield == -1)
			to_chat(user, span_warning("This seed cannot be planted in a farm plot."))
			return
		if(!S.product)
			to_chat(user, span_warning("This seed doesn't produce anything harvestable."))
			return
		plant_seed(S, user)
		return

	return ..()

/// Plant a seed in this plot
/obj/structure/farm_plot/proc/plant_seed(obj/item/seeds/S, mob/user)
	if(user)
		user.transferItemToLoc(S, src)
		to_chat(user, span_notice("You plant [S]."))
	else
		S.forceMove(src)

	myseed = S
	age = 0
	harvest = FALSE
	harvest_work_points = 0
	update_icon()

/obj/structure/farm_plot/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return

	if(!myseed)
		to_chat(user, span_notice("Nothing is planted here."))
		return

	if(!harvest)
		to_chat(user, span_warning("This plant isn't ready for harvest yet."))
		return

	if(being_harvested)
		to_chat(user, span_warning("Someone is already harvesting this."))
		return

	if(!ishuman(user))
		return

	start_harvest(user)

/// Calculate harvest work based on seed properties
/obj/structure/farm_plot/proc/get_harvest_work()
	if(!myseed)
		return FARM_HARVEST_WORK_BASE
	// Higher yield = more work, potency affects slightly
	return (myseed.yield * 3)

/// Begin work-based harvesting
/obj/structure/farm_plot/proc/start_harvest(mob/living/carbon/human/user)
	// Check faith requirement
	if(!can_gather(user))
		to_chat(user, span_warning("You're too exhausted to harvest. You need at least [MIN_FAITH_FOR_WORK] faith."))
		return

	// Check if user is holding a scythe
	var/obj/item/tool = user.get_active_held_item()
	if(!istype(tool, /obj/item/scythe))
		tool = null

	var/total_work = get_harvest_work()

	// Work rate with harvesting stat bonus
	var/work_per_tick = GATHER_WORK_PER_TICK
	var/harvesting_level = get_harvesting_stat(user)
	work_per_tick += (harvesting_level - 1)

	// Tool tier bonus (scythe)
	work_per_tick += get_tool_work_bonus(tool)

	// Starting message
	if(harvest_work_points > 0)
		var/progress_pct = round((harvest_work_points / total_work) * 100)
		to_chat(user, span_notice("You continue harvesting [myseed.plantname]... ([progress_pct]% complete)"))
	else
		to_chat(user, span_notice("You begin harvesting [myseed.plantname]..."))

	playsound(src, 'sound/weapons/thudswoosh.ogg', 30, TRUE)

	being_harvested = TRUE

	// Harvesting loop - continues until interrupted or complete
	while(harvest_work_points < total_work)
		// Check faith each tick
		if(!can_gather(user))
			to_chat(user, span_warning("You're too exhausted to continue harvesting."))
			break

		// Do the work tick
		if(!do_after(user, GATHER_TICK_TIME, target = src))
			var/progress_pct = round((harvest_work_points / total_work) * 100)
			to_chat(user, span_notice("You stop harvesting. Progress: [progress_pct]%"))
			break

		// Add work and drain faith
		harvest_work_points += work_per_tick
		apply_work_faith_drain(user, work_per_tick)

		// Decrement tool durability
		if(tool && !use_tool_durability(tool, user))
			// Tool broke - continue without tool bonuses
			tool = null
			work_per_tick = GATHER_WORK_PER_TICK + (harvesting_level - 1)

		// Periodic sound (30% chance each tick)
		if(prob(30))
			playsound(src, 'sound/weapons/thudswoosh.ogg', 30, TRUE)

	being_harvested = FALSE

	// Check completion
	if(harvest_work_points >= total_work)
		complete_harvest(user, tool)

/// Finish harvesting and drop produce
/obj/structure/farm_plot/proc/complete_harvest(mob/user, obj/item/tool)
	// Calculate yield with harvesting skill bonus
	var/product_count = myseed.yield
	if(user)
		user.visible_message(
			span_notice("[user] harvests [myseed.plantname]."),
			span_notice("You harvest [myseed.plantname]!"),
			span_hear("You hear rustling.")
		)
		// Award harvesting XP based on yield (with tool multiplier)
		var/base_xp = myseed.yield * 2
		var/xp_mult = get_tool_xp_multiplier(tool)
		award_harvesting_xp(user, round(base_xp * xp_mult))
		// Apply harvesting yield bonus (+1 every 5 levels)
		var/harvesting_level = get_harvesting_stat(user)
		product_count += get_harvesting_yield_bonus(harvesting_level)
	else
		// Harvester or other automated source
		visible_message(span_notice("[myseed.plantname] is harvested!"))
	playsound(src, 'sound/weapons/thudswoosh.ogg', 50, TRUE)

	// Create produce using seed properties
	var/product_type = myseed.product

	for(var/i in 1 to product_count)
		new product_type(get_turf(src), myseed)

	// Reset for next harvest cycle
	harvest_work_points = 0
	harvest = FALSE
	age = 0  // Reset age to regrow

	update_icon()

/obj/structure/farm_plot/examine(mob/user)
	. = ..()
	. += span_notice("Water level: [water_level]%")
	if(myseed)
		if(harvest)
			. += span_notice("[myseed.plantname] - Ready to harvest!")
			if(harvest_work_points > 0)
				var/progress_pct = round((harvest_work_points / get_harvest_work()) * 100)
				. += span_notice("Harvest progress: [progress_pct]%")
		else
			var/adjusted_maturation = myseed.maturation * FARM_GROWTH_MULTIPLIER
			var/growth_pct = round((age / max(adjusted_maturation, 1)) * 100)
			. += span_notice("[myseed.plantname] - [min(growth_pct, 100)]% grown")
		if(water_level < FARM_MIN_WATER && !harvest)
			. += span_warning("Needs water to grow!")
	else
		. += span_notice("Ready for planting.")
	if(parent_zone)
		. += span_notice("Part of farm zone: [parent_zone.name]")

#undef FARM_HARVEST_WORK_BASE
#undef FARM_WATER_DRAIN
#undef FARM_MIN_WATER
#undef FARM_GROWTH_MULTIPLIER
