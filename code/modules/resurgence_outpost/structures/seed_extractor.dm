/**
 * Resurgence Outpost - Simple Seed Extractor
 *
 * A simplified, unpowered seed extractor for the outpost.
 * Extracts seeds from produce and drops them directly.
 * No storage system - just extract and receive.
 */

/obj/structure/resurgence_seed_extractor
	name = "seed extractor"
	desc = "A simple mechanical device for extracting seeds from produce. Insert food to get seeds."
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "sextractor"
	density = TRUE
	anchored = TRUE
	max_integrity = 150

	/// Number of seeds extracted per produce item
	var/seed_yield = 2

/obj/structure/resurgence_seed_extractor/examine(mob/user)
	. = ..()
	. += span_notice("Insert grown produce to extract seeds.")
	. += span_notice("Currently yields <b>[seed_yield]</b> seeds per item.")

/obj/structure/resurgence_seed_extractor/attackby(obj/item/I, mob/user, params)
	// Handle grown food - extract seeds
	if(istype(I, /obj/item/food/grown))
		var/obj/item/food/grown/produce = I
		if(!produce.seed)
			to_chat(user, span_warning("[produce] doesn't contain any extractable seeds."))
			return

		extract_seeds(produce, user)
		return

	// Handle non-food grown items (like cotton bundles)
	if(istype(I, /obj/item/grown))
		var/obj/item/grown/produce = I
		if(!produce.seed)
			to_chat(user, span_warning("[produce] doesn't contain any extractable seeds."))
			return

		extract_seeds_grown(produce, user)
		return

	// Handle plant bag - batch extraction
	if(istype(I, /obj/item/storage/bag/plants))
		var/obj/item/storage/bag/plants/bag = I
		var/extracted_count = 0

		// Process all grown food in the bag
		for(var/obj/item/food/grown/produce in bag.contents)
			if(produce.seed)
				extract_seeds(produce, user, silent = TRUE)
				extracted_count++

		// Process all non-food grown items
		for(var/obj/item/grown/produce in bag.contents)
			if(produce.seed)
				extract_seeds_grown(produce, user, silent = TRUE)
				extracted_count++

		if(extracted_count > 0)
			to_chat(user, span_notice("Extracted seeds from [extracted_count] items."))
			playsound(src, 'sound/machines/blender.ogg', 50, TRUE)
		else
			to_chat(user, span_warning("No produce with extractable seeds in the bag."))
		return

	// Allow deconstruction with wrench
	if(I.tool_behaviour == TOOL_WRENCH)
		to_chat(user, span_notice("You begin disassembling [src]..."))
		if(I.use_tool(src, user, 3 SECONDS, volume = 50))
			to_chat(user, span_notice("You disassemble [src]."))
			new /obj/item/stack/sheet/mineral/wood(get_turf(src), 5)
			new /obj/item/stack/sheet/metal(get_turf(src), 2)
			qdel(src)
		return

	return ..()

/// Extract seeds from /obj/item/food/grown
/obj/structure/resurgence_seed_extractor/proc/extract_seeds(obj/item/food/grown/produce, mob/user, silent = FALSE)
	if(!user.temporarilyRemoveItemFromInventory(produce))
		to_chat(user, span_warning("You can't let go of [produce]."))
		return

	var/seeds_created = 0
	for(var/i in 1 to seed_yield)
		var/obj/item/seeds/new_seed = produce.seed.Copy()
		new_seed.forceMove(get_turf(src))
		seeds_created++

	if(!silent)
		to_chat(user, span_notice("You extract [seeds_created] seeds from [produce]."))
		playsound(src, 'sound/machines/blender.ogg', 50, TRUE)

	qdel(produce)

/// Extract seeds from /obj/item/grown (like cotton bundles)
/obj/structure/resurgence_seed_extractor/proc/extract_seeds_grown(obj/item/grown/produce, mob/user, silent = FALSE)
	if(!user.temporarilyRemoveItemFromInventory(produce))
		to_chat(user, span_warning("You can't let go of [produce]."))
		return

	var/seeds_created = 0
	for(var/i in 1 to seed_yield)
		var/obj/item/seeds/new_seed = produce.seed.Copy()
		new_seed.forceMove(get_turf(src))
		seeds_created++

	if(!silent)
		to_chat(user, span_notice("You extract [seeds_created] seeds from [produce]."))
		playsound(src, 'sound/machines/blender.ogg', 50, TRUE)

	qdel(produce)

/obj/structure/resurgence_seed_extractor/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	to_chat(user, span_notice("Insert grown produce into [src] to extract seeds."))
