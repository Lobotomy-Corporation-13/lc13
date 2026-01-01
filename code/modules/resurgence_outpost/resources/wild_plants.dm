/**
 * Resurgence Outpost - Wild Plants
 *
 * Harvestable wild plants that spawn with random seed types.
 * Players harvest them for produce, which can be put through a seed extractor.
 * Each plant type is globally unique - no two wild plants will have the same seed.
 */

/// Time for a harvested wild plant to regrow
#define WILD_PLANT_REGROW_TIME (8 MINUTES)

/// Global list of seed types that have been claimed by wild plants
GLOBAL_LIST_EMPTY(wild_plant_claimed_seeds)

/obj/structure/resurgence_wild_plant
	name = "wild plant"
	desc = "A wild plant growing in the outskirts. It looks harvestable."
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "soil"
	anchored = TRUE
	density = FALSE
	layer = LOW_OBJ_LAYER

	/// The seed type this plant grows
	var/obj/item/seeds/myseed
	/// Whether the plant is ready to harvest
	var/harvestable = TRUE
	/// Whether someone is currently harvesting
	var/being_harvested = FALSE
	/// The plant overlay appearance
	var/mutable_appearance/plant_overlay

	/// Static list of valid seed types (populated on first use)
	var/static/list/valid_seed_types

/obj/structure/resurgence_wild_plant/Initialize(mapload)
	. = ..()
	// Build the valid seed list if not already done
	if(!valid_seed_types)
		build_valid_seed_list()
	// Pick a random unclaimed seed
	pick_random_seed()
	// Apply the plant overlay
	update_plant_overlay()

/obj/structure/resurgence_wild_plant/Destroy()
	// Release our claimed seed back to the pool
	if(myseed)
		GLOB.wild_plant_claimed_seeds -= myseed.type
		QDEL_NULL(myseed)
	return ..()

/// Build the list of valid seed types (seeds with yields and products)
/obj/structure/resurgence_wild_plant/proc/build_valid_seed_list()
	valid_seed_types = list()
	for(var/seed_type in subtypesof(/obj/item/seeds))
		// Skip abstract types
		if(ispath(seed_type, /obj/item/seeds/sample))
			continue
		// Create a temporary seed to check its properties
		var/obj/item/seeds/temp_seed = new seed_type()
		// Must have a valid yield and product
		if(temp_seed.yield > 0 && temp_seed.product)
			// Skip rare/special seeds (rarity > 0 means it's a mutation result)
			if(temp_seed.rarity == 0)
				valid_seed_types += seed_type
		qdel(temp_seed)

/// Pick a random unclaimed seed type
/obj/structure/resurgence_wild_plant/proc/pick_random_seed()
	// Get list of available (unclaimed) seeds
	var/list/available_seeds = list()
	for(var/seed_type in valid_seed_types)
		if(!(seed_type in GLOB.wild_plant_claimed_seeds))
			available_seeds += seed_type

	if(!length(available_seeds))
		// All seeds claimed - just pick any valid one
		if(length(valid_seed_types))
			var/seed_type = pick(valid_seed_types)
			myseed = new seed_type()
		return

	// Pick and claim a random seed
	var/seed_type = pick(available_seeds)
	GLOB.wild_plant_claimed_seeds += seed_type
	myseed = new seed_type()

	// Update name and description
	if(myseed)
		name = "wild [myseed.plantname]"
		desc = "A wild [myseed.plantname] growing in the outskirts. It looks harvestable."

/// Update the plant overlay to show the harvestable state
/obj/structure/resurgence_wild_plant/proc/update_plant_overlay()
	cut_overlays()

	if(!myseed)
		return

	if(!harvestable)
		// Show bare soil when not harvestable
		return

	// Use harvest icon or final growth stage
	var/icon_state_to_use
	if(myseed.icon_harvest)
		icon_state_to_use = myseed.icon_harvest
	else
		icon_state_to_use = "[myseed.icon_grow][myseed.growthstages]"

	plant_overlay = mutable_appearance(myseed.growing_icon, icon_state_to_use, layer = layer + 0.01)
	add_overlay(plant_overlay)

	// Add harvest indicator
	add_overlay(mutable_appearance('icons/obj/hydroponics/equipment.dmi', "over_harvest3"))

/obj/structure/resurgence_wild_plant/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return

	if(!myseed)
		to_chat(user, span_warning("This plant has nothing to harvest."))
		return

	if(!harvestable)
		to_chat(user, span_warning("This plant has already been harvested. It needs time to regrow."))
		return

	if(being_harvested)
		to_chat(user, span_warning("Someone is already harvesting this."))
		return

	if(!ishuman(user))
		return

	start_harvest(user)

/obj/structure/resurgence_wild_plant/attackby(obj/item/I, mob/user, params)
	// Allow harvesting with any item by falling back to hand
	return attack_hand(user)

/obj/structure/resurgence_wild_plant/proc/start_harvest(mob/living/carbon/human/user)
	// Check faith requirement
	if(!can_gather(user))
		to_chat(user, span_warning("You're too exhausted to harvest. You need at least [MIN_FAITH_FOR_WORK] faith."))
		return

	to_chat(user, span_notice("You begin harvesting [src]..."))
	playsound(src, 'sound/weapons/thudswoosh.ogg', 30, TRUE)

	being_harvested = TRUE

	// Simple harvest - just one do_after
	if(!do_after(user, 2 SECONDS, target = src))
		to_chat(user, span_notice("You stop harvesting."))
		being_harvested = FALSE
		return

	// Check faith after harvest
	if(!can_gather(user))
		to_chat(user, span_warning("You're too exhausted to finish harvesting."))
		being_harvested = FALSE
		return

	being_harvested = FALSE
	complete_harvest(user)

/obj/structure/resurgence_wild_plant/proc/complete_harvest(mob/user)
	if(!myseed || !harvestable)
		return

	user.visible_message(
		span_notice("[user] harvests [src]."),
		span_notice("You harvest [src]!"),
		span_hear("You hear rustling.")
	)
	playsound(src, 'sound/weapons/thudswoosh.ogg', 50, TRUE)

	// Drop 1-3 produce with harvesting skill bonus
	var/product_type = myseed.product
	var/yield = rand(1, 3)
	// Apply harvesting yield bonus (+1 every 5 levels)
	var/harvesting_level = get_harvesting_stat(user)
	yield += get_harvesting_yield_bonus(harvesting_level)

	for(var/i in 1 to yield)
		new product_type(get_turf(src), myseed)

	// Apply faith drain
	apply_work_faith_drain(user, 5)

	// Award harvesting XP
	award_harvesting_xp(user, 5)

	// Mark as harvested and start regrowth timer
	harvestable = FALSE
	update_plant_overlay()

	addtimer(CALLBACK(src, PROC_REF(regrow)), WILD_PLANT_REGROW_TIME)

/obj/structure/resurgence_wild_plant/proc/regrow()
	harvestable = TRUE
	update_plant_overlay()
	visible_message(span_notice("[src] has regrown and is ready for harvest!"))

/obj/structure/resurgence_wild_plant/examine(mob/user)
	. = ..()
	if(myseed)
		if(harvestable)
			. += span_notice("It's ready to harvest. You can gather produce from it.")
		else
			. += span_warning("It's been harvested recently. It needs time to regrow.")
	else
		. += span_warning("This plant seems barren.")

/// Spread our seed type to nearby uninitialized wild plants
/obj/structure/resurgence_wild_plant/proc/spread_to_neighbors()
	for(var/obj/structure/resurgence_wild_plant/neighbor in range(2, src))
		if(neighbor == src)
			continue
		if(neighbor.myseed)
			continue
		// Give neighbor our seed type
		neighbor.myseed = new myseed.type()
		neighbor.name = "wild [neighbor.myseed.plantname]"
		neighbor.desc = "A wild [neighbor.myseed.plantname] growing in the outskirts. It looks harvestable."
		neighbor.update_plant_overlay()

#undef WILD_PLANT_REGROW_TIME
