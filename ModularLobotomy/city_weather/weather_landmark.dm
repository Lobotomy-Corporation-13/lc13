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