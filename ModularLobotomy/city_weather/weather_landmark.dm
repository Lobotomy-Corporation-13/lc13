/obj/effect/landmark/city_weather_enabler
	name = "City Weather Enabler"
	desc = "This landmark enables the city weather system on this z-level."
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "weather"

/obj/effect/landmark/city_weather_enabler/Initialize()
	. = ..()
	// Check if controller already exists
	if(GLOB.city_weather_controller)
		return INITIALIZE_HINT_QDEL

	// Create the weather controller for this z-level
	GLOB.city_weather_controller = new /datum/city_weather_controller(z)

	message_admins("City weather system activated on z-level [z]")
	log_game("City weather system activated on z-level [z]")

	return INITIALIZE_HINT_QDEL

//Delayed variant - creates weather controller 4 minutes after initialization
/obj/effect/landmark/city_weather_enabler_delayed
	name = "Delayed City Weather Enabler"
	desc = "This landmark enables the city weather system on this z-level after 4 minutes."

/obj/effect/landmark/city_weather_enabler_delayed/Initialize()
	. = ..()
	// Check if controller already exists
	if(GLOB.city_weather_controller)
		return INITIALIZE_HINT_QDEL

	// Schedule weather controller creation after 4 minutes
	addtimer(CALLBACK(src, PROC_REF(create_weather_controller)), 4 MINUTES)

	message_admins("Delayed city weather system scheduled for z-level [z] (4 minutes)")
	log_game("Delayed city weather system scheduled for z-level [z] (4 minutes)")

/obj/effect/landmark/city_weather_enabler_delayed/proc/create_weather_controller()
	// Double check controller doesn't exist
	if(GLOB.city_weather_controller)
		return

	// Create the weather controller for this z-level
	GLOB.city_weather_controller = new /datum/city_weather_controller(z)

	message_admins("Delayed city weather system activated on z-level [z]")
	log_game("Delayed city weather system activated on z-level [z]")

	return INITIALIZE_HINT_QDEL
