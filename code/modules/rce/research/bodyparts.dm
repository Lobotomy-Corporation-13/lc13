// RCE Body Parts - Items dropped by marked enemies

/obj/item/rce_bodypart
	name = "biological sample"
	desc = "A biological sample extracted from a terminated hostile organism. Used for research purposes."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "brain-x"
	w_class = WEIGHT_CLASS_SMALL
	var/base_value = 10 // Base research points
	var/list/traits = list() // List of traits this part has
	var/source_mob = "unknown" // Name of the mob this came from

/obj/item/rce_bodypart/Initialize()
	. = ..()
	update_appearance()

/obj/item/rce_bodypart/proc/assign_traits(list/new_traits)
	traits = new_traits.Copy()
	update_appearance()
	update_desc()

/obj/item/rce_bodypart/proc/update_appearance()
	// Change appearance based on traits
	if((TRAIT_CORRUPTED in traits) || (TRAIT_HYBRID in traits))
		color = "#8B008B" // Dark purple for corrupted
		name = "corrupted biological sample"
	else if(TRAIT_ORGANIC in traits)
		color = "#8B0000" // Dark red for organic
		name = "organic tissue sample"
	else if(TRAIT_MECHANICAL in traits)
		color = "#4682B4" // Steel blue for mechanical
		name = "mechanical component"
		icon_state = "cyberimp"

	if(TRAIT_ELITE in traits)
		name = "elite [name]"
		add_atom_colour("#FFD700", FIXED_COLOUR_PRIORITY) // Gold tint for elite

/obj/item/rce_bodypart/proc/update_desc()
	desc = initial(desc)
	if(source_mob != "unknown")
		desc += " Extracted from [source_mob]."

	if(length(traits))
		desc += "\n\nDetected traits:"
		for(var/trait in traits)
			desc += "\n• [trait]: [get_trait_description(trait)]"

	desc += "\n\nBase research value: [base_value] points"

/obj/item/rce_bodypart/examine(mob/user)
	. = ..()
	if(length(traits))
		. += span_notice("This sample contains [length(traits)] trait\s:")
		for(var/trait in traits)
			. += span_notice("• <b>[trait]</b>: [get_trait_description(trait)]")
		. += span_notice("Base value: <b>[base_value]</b> research points")

// Calculate the value of this part for a specific research project
/obj/item/rce_bodypart/proc/calculate_value(list/favored_traits, list/negative_traits, list/required_traits)
	var/value = base_value
	var/modifier = 0

	// Check if we meet requirements
	if(length(required_traits))
		var/meets_requirement = FALSE
		for(var/req_trait in required_traits)
			if(req_trait in traits)
				meets_requirement = TRUE
				break
		if(!meets_requirement)
			return 0 // Can't use this part for this research

	// Apply trait modifiers
	for(var/trait in traits)
		if(trait in favored_traits)
			modifier += favored_traits[trait]
		if(trait in negative_traits)
			modifier += negative_traits[trait]

	// Apply modifier
	value = round(value * (1 + modifier))
	return max(1, value) // Minimum 1 point

// Special body part variants for specific enemies
/obj/item/rce_bodypart/xcorp
	name = "X-Corp biological sample"
	desc = "A sample of the grotesque flesh that comprises X-Corp entities."
	base_value = 15

/obj/item/rce_bodypart/clan
	name = "Resurgence Clan component"
	desc = "A mechanical component from a Resurgence Clan unit."
	icon_state = "heart-c-u2-on"
	base_value = 12

/obj/item/rce_bodypart/greed
	name = "greed-touched sample"
	desc = "A horrifying fusion of mechanical and organic matter, corrupted by greed."
	icon_state = "heart-c-u2-on"
	base_value = 20

// Container for storing body parts in research machine
/obj/item/storage/box/rce_bodyparts
	name = "biological sample container"
	desc = "A specialized container for storing biological samples."
	icon_state = "brassbox"

/obj/item/storage/box/rce_bodyparts/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 20
	STR.can_hold = typecacheof(list(/obj/item/rce_bodypart))
	STR.max_combined_w_class = 40
