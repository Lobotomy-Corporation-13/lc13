/**
 * Resurgence Outpost - Water Source
 *
 * Extends water turfs to allow filling containers with water.
 * Useful for filling buckets to water farm plots.
 */

/turf/open/water/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(.)
		return

	// Check if it's a reagent container
	if(istype(I, /obj/item/reagent_containers))
		var/obj/item/reagent_containers/container = I
		fill_container(container, user)
		return TRUE

/turf/open/water/proc/fill_container(obj/item/reagent_containers/container, mob/user)
	// Check if container can hold reagents
	if(!container.reagents)
		to_chat(user, span_warning("[container] can't hold liquids."))
		return

	// Check if container is already full
	if(container.reagents.total_volume >= container.volume)
		to_chat(user, span_warning("[container] is already full."))
		return

	// Calculate how much water to add
	var/space_available = container.volume - container.reagents.total_volume

	// Fill with water
	container.reagents.add_reagent(/datum/reagent/water, space_available)

	to_chat(user, span_notice("You fill [container] with water from [src]."))
	playsound(src, 'sound/effects/slosh.ogg', 50, TRUE)

/turf/open/water/examine(mob/user)
	. = ..()
	. += span_notice("You can fill containers with water here.")
