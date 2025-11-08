/obj/effect/landmark/city_fog_enabler
	name = "City Fog Enabler"
	desc = "This landmark enables the city fog weather system on this z-level."
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "weather"

/obj/effect/landmark/city_fog_enabler/Initialize()
	. = ..()
	// Check if controller already exists
	if(GLOB.city_fog_controller)
		return INITIALIZE_HINT_QDEL

	// Create the fog weather controller for this z-level
	GLOB.city_fog_controller = new /datum/city_fog_controller(z)

	message_admins("City fog weather system activated on z-level [z]")
	log_game("City fog weather system activated on z-level [z]")

	return INITIALIZE_HINT_QDEL

//Delayed variant - creates fog controller 4 minutes after initialization
/obj/effect/landmark/city_fog_enabler_delayed
	name = "Delayed City Fog Enabler"
	desc = "This landmark enables the city fog weather system on this z-level after 4 minutes."

/obj/effect/landmark/city_fog_enabler_delayed/Initialize()
	. = ..()
	// Check if controller already exists
	if(GLOB.city_fog_controller)
		return INITIALIZE_HINT_QDEL

	// Schedule fog controller creation after 4 minutes
	addtimer(CALLBACK(src, PROC_REF(create_fog_controller)), 4 MINUTES)

	message_admins("Delayed city fog weather system scheduled for z-level [z] (4 minutes)")
	log_game("Delayed city fog weather system scheduled for z-level [z] (4 minutes)")

/obj/effect/landmark/city_fog_enabler_delayed/proc/create_fog_controller()
	// Double check controller doesn't exist
	if(GLOB.city_fog_controller)
		return

	// Create the fog weather controller for this z-level
	GLOB.city_fog_controller = new /datum/city_fog_controller(z)

	message_admins("Delayed city fog weather system activated on z-level [z]")
	log_game("Delayed city fog weather system activated on z-level [z]")

	return INITIALIZE_HINT_QDEL
