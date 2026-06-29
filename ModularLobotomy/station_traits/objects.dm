//For the no-EGO stuff
/obj/effect/landmark/salesspawn_extra
	name = "extra sales machine spawner"
	desc = "This is weird. Please inform a coder that you have this. Thanks!"
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x4"

/obj/effect/landmark/salesspawn_extra/Initialize()
	..()
	if(SSmaptype.chosen_trait != FACILITY_TRAIT_NO_EGO)
		return INITIALIZE_HINT_QDEL
	if(!LAZYLEN(GLOB.unspawned_sales)) // You shouldn't ever need this but I mean go on I guess
		return INITIALIZE_HINT_QDEL
	var/obj/structure/pe_sales/spawning = pick_n_take(GLOB.unspawned_sales)
	new spawning(get_turf(src))
	return INITIALIZE_HINT_QDEL


/obj/effect/landmark/refinery/extra
	name = "extra machine spawner"
	desc = "This is weird. Please inform a coder that you have this. Thanks!"
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x4"

/obj/effect/landmark/refinery/extra/Initialize()
	..()
	if(SSmaptype.chosen_trait == FACILITY_TRAIT_NO_EGO)
		new /obj/structure/refinery (get_turf(src))
	if(SSmaptype.chosen_trait == FACILITY_TRAIT_PROSTHETICS)
		new /obj/machinery/vending/prosthetic (get_turf(src))
	return INITIALIZE_HINT_QDEL


/obj/effect/landmark/machine/extra
	name = "extra 2nd machine spawner"
	desc = "This is weird. Please inform a coder that you have this. Thanks!"
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x4"

/obj/effect/landmark/machine/extra/Initialize()
	..()
	if(SSmaptype.chosen_trait == FACILITY_TRAIT_PROSTHETICS)
		new /obj/machinery/augment_fabricator (get_turf(src))
	return INITIALIZE_HINT_QDEL


