/**
 * Resurgence Outpost - Kitchen Structures
 *
 * Simple kitchen stations that function like base game machinery but:
 * - No power requirement
 * - Cost 1 faith per use
 * - Small processing delay via do_after()
 */

// ============================================
// Base Kitchen Structure
// ============================================

/obj/structure/resurgence_kitchen
	name = "kitchen structure"
	desc = "A simple kitchen station."
	icon = 'icons/obj/kitchen.dmi'
	anchored = TRUE
	density = TRUE
	/// Faith cost per operation
	var/faith_cost = 1
	/// Processing time
	var/process_time = 2 SECONDS
	/// Whether the structure is currently being used
	var/busy = FALSE

/// Check if user has enough faith and is a resurgence machine
/obj/structure/resurgence_kitchen/proc/check_faith(mob/user)
	if(!ishuman(user))
		return FALSE
	var/mob/living/carbon/human/H = user
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		to_chat(user, span_warning("You lack the connection to use this."))
		return FALSE
	if(core.stored_faith < faith_cost)
		to_chat(user, span_warning("You need [faith_cost] faith to use this."))
		return FALSE
	return TRUE

/// Consume faith from user
/obj/structure/resurgence_kitchen/proc/consume_faith(mob/user)
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(istype(core))
		core.adjust_faith(-faith_cost)

// ============================================
// Condiment Station
// Bottles reagents from beakers into condiment bottles
// ============================================

/obj/structure/resurgence_kitchen/condiment_station
	name = "condiment station"
	desc = "A manual station for bottling condiments from beakers. Insert a beaker, then click with an empty hand to bottle."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "mixer0"
	/// Currently inserted beaker
	var/obj/item/reagent_containers/beaker = null

/obj/structure/resurgence_kitchen/condiment_station/examine(mob/user)
	. = ..()
	if(beaker)
		. += span_notice("Contains [beaker]. Click with empty hand to bottle reagents or Alt-click to remove beaker.")
	else
		. += span_notice("Insert a beaker to begin bottling.")

/obj/structure/resurgence_kitchen/condiment_station/attackby(obj/item/I, mob/user, params)
	// Insert beaker
	if(istype(I, /obj/item/reagent_containers/glass))
		if(beaker)
			to_chat(user, span_warning("There's already a beaker inside."))
			return
		if(!user.transferItemToLoc(I, src))
			return
		beaker = I
		to_chat(user, span_notice("You insert [I] into [src]."))
		update_appearance()
		return
	return ..()

/obj/structure/resurgence_kitchen/condiment_station/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	if(!beaker)
		to_chat(user, span_warning("Insert a beaker first."))
		return
	if(!beaker.reagents || beaker.reagents.total_volume <= 0)
		to_chat(user, span_warning("The beaker is empty."))
		return
	if(busy)
		to_chat(user, span_warning("[src] is busy."))
		return
	if(!check_faith(user))
		return

	busy = TRUE
	to_chat(user, span_notice("You begin bottling the condiment..."))
	if(!do_after(user, process_time, src))
		busy = FALSE
		return

	consume_faith(user)

	// Create a condiment bottle with the reagents
	var/obj/item/reagent_containers/food/condiment/C = new(get_turf(src))
	beaker.reagents.trans_to(C, min(beaker.reagents.total_volume, C.volume), transfered_by = user)
	to_chat(user, span_notice("You bottle some condiment."))
	busy = FALSE

/obj/structure/resurgence_kitchen/condiment_station/AltClick(mob/user)
	. = ..()
	if(!beaker)
		return
	if(!user.canUseTopic(src, BE_CLOSE))
		return
	beaker.forceMove(get_turf(src))
	user.put_in_hands(beaker)
	to_chat(user, span_notice("You remove [beaker] from [src]."))
	beaker = null
	update_appearance()

/obj/structure/resurgence_kitchen/condiment_station/update_icon_state()
	. = ..()
	icon_state = beaker ? "mixer1" : "mixer0"

// ============================================
// Meat Grinder
// Turns meat slabs into meatballs
// ============================================

/obj/structure/resurgence_kitchen/meat_grinder
	name = "meat grinder"
	desc = "A hand-cranked meat grinder for processing meat into meatballs."
	icon_state = "grinder"

/obj/structure/resurgence_kitchen/meat_grinder/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/food/meat/slab))
		if(busy)
			to_chat(user, span_warning("[src] is busy."))
			return
		if(!check_faith(user))
			return

		busy = TRUE
		to_chat(user, span_notice("You begin grinding the meat..."))
		if(!do_after(user, process_time, src))
			busy = FALSE
			return

		consume_faith(user)
		qdel(I)

		// Produce 3 raw meatballs
		for(var/i in 1 to 3)
			new /obj/item/food/meatball(get_turf(src))
		to_chat(user, span_notice("You grind the meat into meatballs."))
		busy = FALSE
		return
	return ..()

// ============================================
// Food Processor
// Processes food items (potatoes->fries, etc.)
// ============================================

/obj/structure/resurgence_kitchen/food_processor
	name = "food processor"
	desc = "A manual food processor for preparing ingredients. Insert food items to process them."
	icon_state = "processor1"

/obj/structure/resurgence_kitchen/food_processor/attackby(obj/item/I, mob/user, params)
	// Check for processable items using the game's processor recipe system
	var/datum/food_processor_process/recipe = select_recipe(I)
	if(recipe)
		if(busy)
			to_chat(user, span_warning("[src] is busy."))
			return
		if(!check_faith(user))
			return

		busy = TRUE
		to_chat(user, span_notice("You begin processing [I]..."))
		if(!do_after(user, process_time, src))
			busy = FALSE
			return

		consume_faith(user)
		process_food(recipe, I, user)
		busy = FALSE
		return
	return ..()

/// Find a matching processor recipe for the item
/obj/structure/resurgence_kitchen/food_processor/proc/select_recipe(obj/item/I)
	for(var/recipe_type in subtypesof(/datum/food_processor_process))
		var/datum/food_processor_process/recipe = new recipe_type
		if(istype(I, recipe.input))
			// Check blacklist
			for(var/blacklisted in recipe.blacklist)
				if(istype(I, blacklisted))
					qdel(recipe)
					return null
			return recipe
		qdel(recipe)
	return null

/// Process the food item using the recipe
/obj/structure/resurgence_kitchen/food_processor/proc/process_food(datum/food_processor_process/recipe, obj/item/I, mob/user)
	var/output_loc = get_turf(src)
	// Create output items
	for(var/i in 1 to recipe.multiplier)
		new recipe.output(output_loc)
	to_chat(user, span_notice("You process [I] into something new."))
	qdel(I)

// ============================================
// Stove
// Cooks raw food items
// ============================================

/obj/structure/resurgence_kitchen/stove
	name = "stove"
	desc = "A simple stove for cooking food. Insert raw food to cook it."
	icon_state = "mw"

/obj/structure/resurgence_kitchen/stove/attackby(obj/item/I, mob/user, params)
	// Check if item is edible
	if(IS_EDIBLE(I))
		if(busy)
			to_chat(user, span_warning("[src] is busy."))
			return
		if(!check_faith(user))
			return

		busy = TRUE
		to_chat(user, span_notice("You begin cooking [I]..."))
		if(!do_after(user, process_time, src))
			busy = FALSE
			return

		consume_faith(user)

		// Trigger microwave behavior on the item
		SEND_SIGNAL(I, COMSIG_ITEM_MICROWAVE_ACT, src, user)
		to_chat(user, span_notice("You finish cooking."))
		busy = FALSE
		return
	return ..()

// ============================================
// Hand Grinder
// Grinds items into reagents, outputs to inserted beaker
// ============================================

/obj/structure/resurgence_kitchen/grinder
	name = "hand grinder"
	desc = "A hand-cranked grinder for extracting reagents from items. Insert a beaker, then add items to grind."
	icon_state = "juicer1"
	/// Currently inserted beaker
	var/obj/item/reagent_containers/beaker = null

/obj/structure/resurgence_kitchen/grinder/examine(mob/user)
	. = ..()
	if(beaker)
		. += span_notice("Contains [beaker] ([beaker.reagents.total_volume]/[beaker.reagents.maximum_volume] units). Alt-click to remove.")
	else
		. += span_notice("Insert a beaker to collect ground reagents.")

/obj/structure/resurgence_kitchen/grinder/attackby(obj/item/I, mob/user, params)
	// Insert beaker
	if(istype(I, /obj/item/reagent_containers/glass))
		if(beaker)
			to_chat(user, span_warning("There's already a beaker inside."))
			return
		if(!user.transferItemToLoc(I, src))
			return
		beaker = I
		to_chat(user, span_notice("You insert [I] into [src]."))
		return

	// Try to grind item
	if(!beaker)
		to_chat(user, span_warning("Insert a beaker first."))
		return

	// Check if item has grind_results
	var/list/grind_results = I.grind_results
	if(!grind_results || !length(grind_results))
		to_chat(user, span_warning("[I] cannot be ground."))
		return

	if(beaker.reagents.total_volume >= beaker.reagents.maximum_volume)
		to_chat(user, span_warning("The beaker is full."))
		return

	if(busy)
		to_chat(user, span_warning("[src] is busy."))
		return

	if(!check_faith(user))
		return

	busy = TRUE
	to_chat(user, span_notice("You begin grinding [I]..."))
	if(!do_after(user, process_time, src))
		busy = FALSE
		return

	consume_faith(user)

	// Add grind results to beaker
	for(var/reagent in grind_results)
		var/amount = grind_results[reagent]
		beaker.reagents.add_reagent(reagent, amount)

	to_chat(user, span_notice("You grind [I] and extract the reagents."))
	qdel(I)
	busy = FALSE

/obj/structure/resurgence_kitchen/grinder/AltClick(mob/user)
	. = ..()
	if(!beaker)
		return
	if(!user.canUseTopic(src, BE_CLOSE))
		return
	beaker.forceMove(get_turf(src))
	user.put_in_hands(beaker)
	to_chat(user, span_notice("You remove [beaker] from [src]."))
	beaker = null
