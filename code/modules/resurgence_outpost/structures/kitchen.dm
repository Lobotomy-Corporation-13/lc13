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
	/// Room type required for this structure to work (null = works anywhere)
	var/required_room_type = ROOM_TYPE_KITCHEN

/// Check if structure is in the correct room type
/obj/structure/resurgence_kitchen/proc/check_room_type(mob/user)
	if(!required_room_type)
		return TRUE
	if(!is_in_room_type(src, required_room_type))
		to_chat(user, span_warning("[src] only works inside a [required_room_type]."))
		return FALSE
	return TRUE

/// Check if user has enough faith and is a resurgence machine
/obj/structure/resurgence_kitchen/proc/check_faith(mob/user)
	if(!ishuman(user))
		return FALSE
	var/mob/living/carbon/human/H = user
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		to_chat(user, span_warning("You lack the connection to use this."))
		return FALSE
	if(core.faith < faith_cost)
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

/// Finalize cooked food - set quality and award XP
/obj/structure/resurgence_kitchen/proc/finalize_cooked_food(mob/user, obj/item/food_item)
	if(!food_item)
		return
	// Award cooking XP
	award_cooking_xp(user, 10)
	// Calculate quality with kitchen room bonus
	var/skill = get_cooking_skill(user)
	var/in_kitchen = is_in_room_type(src, ROOM_TYPE_KITCHEN)
	var/food_quality = calculate_food_quality(skill, in_kitchen)
	// Apply quality to edible component
	var/datum/component/edible/E = food_item.GetComponent(/datum/component/edible)
	if(E)
		E.quality = food_quality

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
		update_icon()
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
	if(!check_room_type(user))
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
	update_icon()

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
		if(!check_room_type(user))
			return
		if(!check_faith(user))
			return

		busy = TRUE
		to_chat(user, span_notice("You begin grinding the meat..."))
		playsound(src, 'sound/machines/juicer.ogg', 50, TRUE)
		if(!do_after(user, process_time, src))
			busy = FALSE
			return

		consume_faith(user)
		qdel(I)

		// Produce 3 raw meatballs
		playsound(src, 'sound/effects/splat.ogg', 50, TRUE)
		for(var/i in 1 to 3)
			var/obj/item/food/meatball/meatball = new(get_turf(src))
			finalize_cooked_food(user, meatball)
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
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "processor1"

/obj/structure/resurgence_kitchen/food_processor/attackby(obj/item/I, mob/user, params)
	// Check for processable items using the game's processor recipe system
	var/datum/food_processor_process/recipe = select_recipe(I)
	if(recipe)
		if(busy)
			to_chat(user, span_warning("[src] is busy."))
			return
		if(!check_room_type(user))
			return
		if(!check_faith(user))
			return

		busy = TRUE
		to_chat(user, span_notice("You begin processing [I]..."))
		playsound(src, 'sound/machines/blender.ogg', 50, TRUE)
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
		var/obj/item/output_item = new recipe.output(output_loc)
		finalize_cooked_food(user, output_item)
	to_chat(user, span_notice("You process [I] into something new."))
	qdel(I)

// ============================================
// Stove
// Cooks raw food items (works like microwave - insert food, then click to cook)
// ============================================

/obj/structure/resurgence_kitchen/stove
	name = "stove"
	desc = "A simple stove for cooking food. Insert food, then click with an empty hand to start cooking."
	icon = 'ModularLobotomy/fishing/icons/fishmachines.dmi'
	icon_state = "stove_on"
	/// List of items currently in the stove
	var/list/ingredients = list()
	/// Maximum number of items
	var/max_items = 10
	/// Looping sound for cooking
	var/datum/looping_sound/microwave/soundloop

/obj/structure/resurgence_kitchen/stove/Initialize(mapload)
	. = ..()
	soundloop = new(list(src), FALSE)

/obj/structure/resurgence_kitchen/stove/Destroy()
	QDEL_NULL(soundloop)
	eject()
	return ..()

/obj/structure/resurgence_kitchen/stove/examine(mob/user)
	. = ..()
	if(busy)
		. += span_notice("[src] is currently cooking.")
	else if(length(ingredients))
		. += span_notice("[src] contains:")
		for(var/atom/movable/AM in ingredients)
			. += span_notice("- [AM.name]")
		. += span_notice("Click with an empty hand to start cooking, or Alt-click to eject contents.")
	else
		. += span_notice("[src] is empty. Insert food to cook it.")

/obj/structure/resurgence_kitchen/stove/attackby(obj/item/I, mob/user, params)
	if(busy)
		to_chat(user, span_warning("[src] is busy cooking."))
		return

	// Insert edible items
	if(I.w_class <= WEIGHT_CLASS_NORMAL && !istype(I, /obj/item/storage))
		if(ingredients.len >= max_items)
			to_chat(user, span_warning("[src] is full!"))
			return
		if(!user.transferItemToLoc(I, src))
			to_chat(user, span_warning("[I] is stuck to your hand!"))
			return
		ingredients += I
		to_chat(user, span_notice("You add [I] to [src]."))
		return
	return ..()

/obj/structure/resurgence_kitchen/stove/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	if(busy)
		to_chat(user, span_warning("[src] is busy cooking."))
		return
	if(!length(ingredients))
		to_chat(user, span_warning("[src] is empty."))
		return
	cook(user)

/obj/structure/resurgence_kitchen/stove/AltClick(mob/user)
	. = ..()
	if(busy)
		to_chat(user, span_warning("[src] is busy cooking."))
		return
	if(!user.canUseTopic(src, BE_CLOSE))
		return
	eject()

/obj/structure/resurgence_kitchen/stove/proc/eject()
	for(var/atom/movable/AM in ingredients)
		AM.forceMove(drop_location())
	ingredients.Cut()

/obj/structure/resurgence_kitchen/stove/proc/cook(mob/user)
	if(!check_room_type(user))
		return
	if(!check_faith(user))
		return

	busy = TRUE
	consume_faith(user)
	visible_message(span_notice("[src] turns on."), null, span_hear("You hear a stove heating up."))
	soundloop.start()

	if(!do_after(user, process_time, src))
		soundloop.stop()
		busy = FALSE
		return

	soundloop.stop()

	// Cook all ingredients
	for(var/obj/item/I in ingredients)
		SEND_SIGNAL(I, COMSIG_ITEM_MICROWAVE_ACT, src, user)
		finalize_cooked_food(user, I)

	to_chat(user, span_notice("You finish cooking."))
	eject()
	busy = FALSE

// ============================================
// Hand Grinder
// Grinds items into reagents, outputs to inserted beaker
// ============================================

/obj/structure/resurgence_kitchen/grinder
	name = "hand grinder"
	desc = "A hand-cranked grinder for extracting reagents from items. Insert a beaker, then add items to grind."
	icon_state = "juicer0"
	/// Currently inserted beaker
	var/obj/item/reagent_containers/beaker = null

/obj/structure/resurgence_kitchen/grinder/update_icon_state()
	. = ..()
	if(beaker)
		icon_state = "juicer1"
	else
		icon_state = "juicer0"

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
		update_icon()
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

	if(!check_room_type(user))
		return

	if(!check_faith(user))
		return

	busy = TRUE
	to_chat(user, span_notice("You begin grinding [I]..."))
	playsound(src, 'sound/machines/blender.ogg', 50, TRUE)
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
	update_icon()

// ============================================
// Griddle
// A hot surface for grilling food items
// ============================================

/obj/structure/resurgence_kitchen/griddle
	name = "griddle"
	desc = "A hot surface for grilling food. Place items on it, then click to toggle heat. Costs 1 faith to turn on."
	icon = 'icons/obj/machines/griddle.dmi'
	icon_state = "griddle1_off"
	layer = BELOW_OBJ_LAYER
	/// Whether the griddle is currently on
	var/on = FALSE
	/// Items currently on the griddle
	var/list/griddled_objects = list()
	/// Maximum items that fit on the griddle
	var/max_items = 8
	/// Visual variant
	var/variant = 1
	/// Looping sound for grilling
	var/datum/looping_sound/grill/grill_loop

/obj/structure/resurgence_kitchen/griddle/Initialize(mapload)
	. = ..()
	variant = rand(1, 3)
	grill_loop = new(list(src), FALSE)
	START_PROCESSING(SSobj, src)

/obj/structure/resurgence_kitchen/griddle/Destroy()
	STOP_PROCESSING(SSobj, src)
	QDEL_NULL(grill_loop)
	return ..()

/obj/structure/resurgence_kitchen/griddle/attackby(obj/item/I, mob/user, params)
	if(griddled_objects.len >= max_items)
		to_chat(user, span_notice("[src] can't fit more items!"))
		return

	var/list/modifiers = params2list(params)
	if(!LAZYACCESS(modifiers, ICON_X) || !LAZYACCESS(modifiers, ICON_Y))
		return

	if(user.transferItemToLoc(I, src, silent = FALSE))
		I.pixel_x = clamp(text2num(LAZYACCESS(modifiers, ICON_X)) - 16, -(world.icon_size/2), world.icon_size/2)
		I.pixel_y = clamp(text2num(LAZYACCESS(modifiers, ICON_Y)) - 16, -(world.icon_size/2), world.icon_size/2)
		to_chat(user, span_notice("You place [I] on [src]."))
		add_to_grill(I)
		update_icon()
	else
		return ..()

/obj/structure/resurgence_kitchen/griddle/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	// Toggle on/off
	if(!on)
		// Turning on costs faith and requires kitchen
		if(!check_room_type(user))
			return
		if(!check_faith(user))
			return
		consume_faith(user)
		on = TRUE
		grill_loop.start()
		to_chat(user, span_notice("You light the [src]."))
	else
		on = FALSE
		grill_loop.stop()
		to_chat(user, span_notice("You turn off the [src]."))
	update_icon()

/obj/structure/resurgence_kitchen/griddle/proc/add_to_grill(obj/item/I)
	vis_contents += I
	griddled_objects += I
	I.flags_1 |= IS_ONTOP_1
	RegisterSignal(I, COMSIG_MOVABLE_MOVED, PROC_REF(item_moved))
	RegisterSignal(I, COMSIG_GRILL_COMPLETED, PROC_REF(grill_completed))
	RegisterSignal(I, COMSIG_PARENT_QDELETING, PROC_REF(item_removed))

/obj/structure/resurgence_kitchen/griddle/proc/item_removed(obj/item/I)
	SIGNAL_HANDLER
	I.flags_1 &= ~IS_ONTOP_1
	griddled_objects -= I
	vis_contents -= I
	UnregisterSignal(I, list(COMSIG_GRILL_COMPLETED, COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))

/obj/structure/resurgence_kitchen/griddle/proc/item_moved(obj/item/I, atom/OldLoc, Dir, Forced)
	SIGNAL_HANDLER
	item_removed(I)

/obj/structure/resurgence_kitchen/griddle/proc/grill_completed(obj/item/source, atom/grilled_result)
	SIGNAL_HANDLER
	add_to_grill(grilled_result)

/obj/structure/resurgence_kitchen/griddle/process(delta_time)
	if(!on)
		return
	for(var/obj/item/griddled_item in griddled_objects)
		if(SEND_SIGNAL(griddled_item, COMSIG_ITEM_GRILLED, src, delta_time) & COMPONENT_HANDLED_GRILLING)
			continue
		griddled_item.fire_act(1000)
		if(prob(10))
			visible_message(span_danger("[griddled_item] doesn't seem to be doing too great on the [src]!"))

/obj/structure/resurgence_kitchen/griddle/update_icon_state()
	. = ..()
	icon_state = "griddle[variant]_[on ? "on" : "off"]"
