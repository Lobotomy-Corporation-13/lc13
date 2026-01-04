/**
 * Resurgence Outpost - Events System
 *
 * Defines and global variables for the random events system.
 * Events can be positive, negative, or neutral (weather).
 */

// Event category defines
#define EVENT_POSITIVE 1
#define EVENT_NEGATIVE 2
#define EVENT_NEUTRAL 3

// Event timing defines (in deciseconds)
#define EVENT_CHECK_INTERVAL (2 MINUTES)
#define EVENT_MIN_COOLDOWN (3 MINUTES)
#define EVENT_MIN_ROUND_TIME (5 MINUTES)

// Event weight defaults
#define EVENT_WEIGHT_POSITIVE 40
#define EVENT_WEIGHT_NEGATIVE 40
#define EVENT_WEIGHT_NEUTRAL 20

// Base event chance (percent)
#define EVENT_BASE_CHANCE 35

/// Global event manager singleton
GLOBAL_DATUM(resurgence_events, /datum/resurgence_event_manager)

/// Global modifiers set by active events - checked by other systems
GLOBAL_VAR_INIT(resurgence_yield_modifier, 1.0)
GLOBAL_VAR_INIT(resurgence_growth_modifier, 1.0)
GLOBAL_VAR_INIT(resurgence_work_modifier, 1.0)
GLOBAL_VAR_INIT(resurgence_sell_modifier, 1.0)
GLOBAL_VAR_INIT(resurgence_buy_modifier, 1.0)
GLOBAL_VAR_INIT(resurgence_faith_regen_modifier, 1.0)
GLOBAL_VAR_INIT(resurgence_quality_bonus, 0)
GLOBAL_VAR_INIT(resurgence_durability_modifier, 1.0)

/// Check if resurgence events system is active
/proc/resurgence_events_active()
	return GLOB.resurgence_events != null

/// Get current yield modifier (for gathering)
/proc/get_resurgence_yield_modifier()
	return GLOB.resurgence_yield_modifier

/// Get current growth modifier (for farming)
/proc/get_resurgence_growth_modifier()
	return GLOB.resurgence_growth_modifier

/// Get current work modifier (for all work actions)
/proc/get_resurgence_work_modifier()
	return GLOB.resurgence_work_modifier

/// Get current sell price modifier (for trading)
/proc/get_resurgence_sell_modifier()
	return GLOB.resurgence_sell_modifier

/// Get current buy price modifier (for trading)
/proc/get_resurgence_buy_modifier()
	return GLOB.resurgence_buy_modifier

/// Get current faith regen modifier
/proc/get_resurgence_faith_regen_modifier()
	return GLOB.resurgence_faith_regen_modifier

/// Get current quality bonus (for crafting)
/proc/get_resurgence_quality_bonus()
	return GLOB.resurgence_quality_bonus

/// Get current durability modifier (for tools)
/proc/get_resurgence_durability_modifier()
	return GLOB.resurgence_durability_modifier

/// Check if a specific weather type is currently active
/proc/is_resurgence_weather_active(weather_type)
	for(var/datum/weather/W in SSweather.processing)
		if(istype(W, weather_type))
			return TRUE
	return FALSE

/// Check if ANY resurgence weather is active
/proc/is_any_resurgence_weather_active()
	for(var/datum/weather/W in SSweather.processing)
		if(istype(W, /datum/weather/resurgence))
			return TRUE
	return FALSE

/// Announce an event to all resurgence players
/proc/announce_resurgence_event(name, desc, category, duration = 0)
	var/color
	var/sound_file

	switch(category)
		if(EVENT_POSITIVE)
			color = "green"
			sound_file = 'sound/misc/notice2.ogg'
		if(EVENT_NEGATIVE)
			color = "red"
			sound_file = 'sound/misc/notice1.ogg'
		if(EVENT_NEUTRAL)
			color = "yellow"
			sound_file = 'sound/misc/notice2.ogg'

	for(var/mob/living/carbon/human/H in GLOB.player_list)
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(!istype(core))
			continue

		to_chat(H, span_bold("[color == "green" ? span_nicegreen("EVENT: [name]") : color == "red" ? span_warning("EVENT: [name]") : span_notice("EVENT: [name]")]"))
		to_chat(H, span_notice("[desc]"))
		if(duration > 0)
			to_chat(H, span_notice("Duration: [round(duration / (1 MINUTES), 0.1)] minutes"))
		SEND_SOUND(H, sound(sound_file))
