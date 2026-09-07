/**
 * Resurgence Outpost - Weather Events
 *
 * Weather datums using the existing /datum/weather system.
 * These provide visual effects and gameplay modifiers.
 * Indoor areas (designated rooms) are protected via protect_indoors.
 *
 * NOTE: Weather events are currently disabled due to z-level trait issues.
 * The weather system requires proper ZTRAIT_RESURGENCE setup to function.
 */

/*
// ============================================
// Base Resurgence Weather
// ============================================

/datum/weather/resurgence
	name = "resurgence weather"
	desc = "Weather affecting the resurgence outpost."
	area_type = /area/resurgence_outpost
	protect_indoors = TRUE
	target_trait = ZTRAIT_RESURGENCE
	probability = 0  // Not randomly triggered by SSweather

// ============================================
// Heavy Rain (Neutral)
// ============================================

/datum/weather/resurgence/heavy_rain
	name = "heavy rain"
	desc = "Heavy rainfall blankets the outpost."

	telegraph_message = span_warning("Dark clouds gather overhead...")
	telegraph_duration = 300
	telegraph_overlay = "light_rain"

	weather_message = span_notice("Heavy rain begins to fall across the outpost.")
	weather_duration_lower = 3000
	weather_duration_upper = 4200
	weather_overlay = "rain_storm"

	end_message = span_notice("The rain begins to let up.")
	end_duration = 100
	end_overlay = "light_rain"

	immunity_type = "rain"

/datum/weather/resurgence/heavy_rain/start()
	. = ..()
	// Apply growth bonus
	GLOB.resurgence_growth_modifier *= 1.25

/datum/weather/resurgence/heavy_rain/end()
	// Remove growth bonus
	GLOB.resurgence_growth_modifier /= 1.25
	return ..()

/datum/weather/resurgence/heavy_rain/weather_act(mob/living/L)
	if(!ishuman(L))
		return
	// Apply movement slowdown
	L.add_or_update_variable_movespeed_modifier(
		/datum/movespeed_modifier/resurgence_weather/rain,
		multiplicative_slowdown = 0.2
	)

// ============================================
// Dense Fog (Neutral - Aesthetic)
// ============================================

/datum/weather/resurgence/dense_fog
	name = "dense fog"
	desc = "A thick fog has rolled in across the outpost."

	telegraph_message = span_warning("The air grows thick and hazy...")
	telegraph_duration = 200
	telegraph_overlay = "light_fog"

	weather_message = span_notice("Dense fog blankets the area, reducing visibility.")
	weather_duration_lower = 2400
	weather_duration_upper = 3600
	weather_overlay = "heavy_fog"

	end_message = span_notice("The fog begins to lift.")
	end_duration = 150
	end_overlay = "light_fog"

	aesthetic = TRUE  // No gameplay effect

// ============================================
// Heat Wave (Negative)
// ============================================

/datum/weather/resurgence/heat_wave
	name = "heat wave"
	desc = "Extreme heat bears down on the outpost."

	telegraph_message = span_warning("The temperature begins to rise...")
	telegraph_duration = 300
	telegraph_overlay = "light_ash"

	weather_message = span_userdanger("A scorching heat wave grips the outpost!")
	weather_duration_lower = 4200
	weather_duration_upper = 5400
	weather_overlay = "heavy_ash"

	end_message = span_notice("The temperature starts to return to normal.")
	end_duration = 100
	end_overlay = "light_ash"

	immunity_type = "heat"

/datum/weather/resurgence/heat_wave/start()
	. = ..()
	// Reduce crop growth
	GLOB.resurgence_growth_modifier *= 0.75

/datum/weather/resurgence/heat_wave/end()
	// Restore crop growth
	GLOB.resurgence_growth_modifier /= 0.75
	return ..()

/datum/weather/resurgence/heat_wave/weather_act(mob/living/carbon/human/L)
	if(!ishuman(L))
		return
	// Heat wave increases faith drain - handled by checking is_resurgence_weather_active
	// in the faith tick proc (resurgence_core.dm)


// ============================================
// Movespeed Modifiers for Weather
// ============================================

/datum/movespeed_modifier/resurgence_weather
	variable = TRUE

/datum/movespeed_modifier/resurgence_weather/rain
	multiplicative_slowdown = 0.2

// ============================================
// Weather Event Wrappers
// These are resurgence_event datums that trigger weather
// ============================================

/datum/resurgence_event/weather
	/// The weather type to trigger
	var/weather_type = null
	/// Reference to the active weather datum
	var/datum/weather/active_weather = null

/datum/resurgence_event/weather/can_start()
	. = ..()
	if(!.)
		return FALSE
	// Don't start if weather of same type is already active
	if(is_resurgence_weather_active(weather_type))
		return FALSE
	return TRUE

/datum/resurgence_event/weather/start_event()
	if(!weather_type)
		return FALSE

	active = TRUE

	// Get resurgence z-levels
	var/list/resurgence_z_levels = list()
	for(var/z in 1 to world.maxz)
		if(SSmapping.level_trait(z, ZTRAIT_RESURGENCE))
			resurgence_z_levels += z

	if(!length(resurgence_z_levels))
		active = FALSE
		return FALSE

	// Create and start the weather
	active_weather = new weather_type(resurgence_z_levels)
	active_weather.telegraph()

	// Log the event
	log_game("RESURGENCE EVENT: [name] started (weather: [weather_type])")

	return TRUE

/datum/resurgence_event/weather/end_event(silent = FALSE)
	if(!active)
		return FALSE

	active = FALSE

	// End the weather if still running
	if(active_weather && active_weather.stage != END_STAGE)
		active_weather.end()

	active_weather = null

	log_game("RESURGENCE EVENT: [name] ended")

	return TRUE

/datum/resurgence_event/weather/get_remaining_time()
	if(!active_weather)
		return 0
	// Weather handles its own timing
	return active_weather.weather_duration

// ============================================
// Specific Weather Events
// ============================================

/datum/resurgence_event/weather/heavy_rain
	name = "Heavy Rain"
	desc = "Heavy rain falls across the outpost. Movement is slowed outdoors, but crops grow faster."
	category = EVENT_NEUTRAL
	weight = 65
	min_round_time = 12 MINUTES
	weather_type = /datum/weather/resurgence/heavy_rain

/datum/resurgence_event/weather/dense_fog
	name = "Dense Fog"
	desc = "A dense fog has rolled in, reducing visibility."
	category = EVENT_NEUTRAL
	weight = 50
	min_round_time = 15 MINUTES
	weather_type = /datum/weather/resurgence/dense_fog

/datum/resurgence_event/weather/heat_wave
	name = "Heat Wave"
	desc = "Extreme heat bears down on the outpost! Faith drains faster outdoors and crops grow slower."
	category = EVENT_NEGATIVE
	weight = 70
	min_round_time = 15 MINUTES
	weather_type = /datum/weather/resurgence/heat_wave

*/ // END OF COMMENTED WEATHER EVENTS

// ============================================
// Clear Skies (Positive - No Weather)
// ============================================

/datum/resurgence_event/clear_skies
	name = "Clear Skies"
	desc = "The weather is perfect for outdoor work!"
	category = EVENT_NEUTRAL
	weight = 60
	min_round_time = 10 MINUTES
	duration = 10 MINUTES

/datum/resurgence_event/clear_skies/can_start()
	. = ..()
	if(!.)
		return FALSE
	// Only trigger if no weather is currently active
	// Note: Weather events disabled, always allow clear skies
	// if(is_any_resurgence_weather_active())
	// 	return FALSE
	return TRUE

/datum/resurgence_event/clear_skies/apply_modifiers()
	GLOB.resurgence_work_modifier *= 1.1
	GLOB.resurgence_growth_modifier *= 1.1

/datum/resurgence_event/clear_skies/remove_modifiers()
	GLOB.resurgence_work_modifier /= 1.1
	GLOB.resurgence_growth_modifier /= 1.1
