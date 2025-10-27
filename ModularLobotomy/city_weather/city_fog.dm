#define STATUS_EFFECT_FOG_EXPOSURE /datum/status_effect/fog_exposure

GLOBAL_DATUM(city_fog_controller, /datum/city_fog_controller)

/datum/city_fog_controller
	var/active = FALSE
	var/z_level
	var/current_state = "clear" // States: "clear", "warning", "fog"

	/// How long the fog lasts
	var/fog_duration = 12 MINUTES

	/// How long between fog cycles (clear period)
	var/clear_duration = 20 MINUTES

	/// Warning period before fog appears
	var/warning_duration = 2 MINUTES

	/// Reference to current weather
	var/datum/weather/city_fog/current_weather

/datum/city_fog_controller/New(zlevel)
	..()
	z_level = zlevel
	active = TRUE
	ScheduleClearPhase()

/datum/city_fog_controller/proc/ScheduleClearPhase()
	if(!active)
		return

	current_state = "clear"

	// After clear_duration, start warning phase
	addtimer(CALLBACK(src, PROC_REF(StartWarningPhase)), clear_duration)

/datum/city_fog_controller/proc/StartWarningPhase()
	if(!active)
		return

	current_state = "warning"

	// Send warning messages to players
	for(var/mob/M in GLOB.player_list)
		var/turf/mob_turf = get_turf(M)
		if(mob_turf && mob_turf.z == z_level)
			to_chat(M, span_warning("The air is becoming thick and damp. A heavy fog is approaching..."))

	// After warning_duration, start fog
	addtimer(CALLBACK(src, PROC_REF(StartFog)), warning_duration)

/datum/city_fog_controller/proc/StartFog()
	if(!active)
		return

	current_state = "fog"

	// Start the fog weather
	SSweather.run_weather(/datum/weather/city_fog, z_level)

	// After fog_duration, end fog
	addtimer(CALLBACK(src, PROC_REF(EndFog)), fog_duration)

/datum/city_fog_controller/proc/EndFog()
	if(!active)
		return

	// End the fog weather
	SSweather.end_weather(/datum/weather/city_fog)

	// Schedule next cycle
	ScheduleClearPhase()

/datum/city_fog_controller/proc/GetStatus()
	if(!active)
		return "System inactive"

	switch(current_state)
		if("clear")
			return "Clear weather"
		if("warning")
			return "Fog warning active"
		if("fog")
			return "Heavy fog active"

	return "Unknown state"

// Fog Weather Datum
/datum/weather/city_fog
	name = "heavy fog"
	desc = "A thick, oppressive fog that damages those caught in it."
	immunity_type = "fog"

	telegraph_message = span_warning("The air grows thick with moisture...")
	telegraph_duration = 10 SECONDS
	telegraph_overlay = "light_fog"

	weather_message = span_userdanger("<i>A heavy fog envelops the area, draining your mind!</i>")
	weather_overlay = "heavy_fog"
	perpetual = TRUE

	end_message = span_boldannounce("The fog begins to dissipate.")
	end_overlay = "light_pollen"
	end_duration = 10 SECONDS

	area_type = /area
	protect_indoors = FALSE
	target_trait = ZTRAIT_STATION

/datum/weather/city_fog/telegraph()
	if(stage == STARTUP_STAGE)
		return
	stage = STARTUP_STAGE

	if(LAZYLEN(SSweather.processing))
		var/not_area_visual = FALSE
		// If someone is already using the area icon then resort to RVP
		for(var/datum/weather/weath in SSweather.processing)
			if(!weath.use_visual_pool)
				not_area_visual = TRUE
				break
		use_visual_pool = not_area_visual

	// Custom area filtering - only /area/city with in_city = FALSE
	var/list/affectareas = list()
	for(var/area/city/A in world)
		if(!A.in_city) // Only areas with in_city = FALSE
			if(protect_indoors && !A.outdoors)
				continue
			if(A.z in impacted_z_levels)
				affectareas += A

	impacted_areas = affectareas

	weather_duration = rand(weather_duration_lower, weather_duration_upper)
	SSweather.processing |= src
	update_areas()

	// Send telegraph messages
	for(var/M in GLOB.player_list)
		var/turf/mob_turf = get_turf(M)
		if(mob_turf && (mob_turf.z in impacted_z_levels))
			if(telegraph_message)
				to_chat(M, telegraph_message)
			if(telegraph_sound)
				SEND_SOUND(M, sound(telegraph_sound))

	addtimer(CALLBACK(src, PROC_REF(start)), telegraph_duration)

/datum/weather/city_fog/weather_act(mob/living/L)
	if(!ishuman(L))
		return

	var/mob/living/carbon/human/H = L

	// Apply fog exposure status effect
	if(!H.has_status_effect(STATUS_EFFECT_FOG_EXPOSURE))
		H.apply_status_effect(STATUS_EFFECT_FOG_EXPOSURE)

/datum/weather/city_fog/end()
	..()

	// Remove fog exposure from all players
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		H.remove_status_effect(STATUS_EFFECT_FOG_EXPOSURE)

// Status Effect for Fog Damage
/datum/status_effect/fog_exposure
	id = "fog_exposure"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1 // Infinite while in fog
	tick_interval = 1 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/fog_exposure

/datum/status_effect/fog_exposure/on_apply()
	. = ..()
	to_chat(owner, span_warning("The fog seeps into your mind, draining your sanity!"))

/datum/status_effect/fog_exposure/on_remove()
	to_chat(owner, span_nicegreen("You escape the fog's influence."))
	. = ..()

/datum/status_effect/fog_exposure/tick()
	if(!ishuman(owner))
		return

	var/mob/living/carbon/human/H = owner

	// Check if still in fog weather
	var/in_fog = FALSE
	for(var/datum/weather/city_fog/fog in SSweather.processing)
		if(can_weather_act(H, fog))
			in_fog = TRUE
			break

	if(!in_fog)
		qdel(src)
		return

	// Deal damage based on sanity state
	if(H.sanity_lost)
		// Insane: Deal 10% max HP as PALE damage
		var/damage = H.maxHealth * 0.2
		H.deal_damage(damage, PALE_DAMAGE)
		if(prob(25)) // Occasional message to avoid spam
			to_chat(H, span_danger("The fog tears at your broken mind, damaging your body!"))
	else
		// Sane: Deal 5% max SP as SP damage
		var/sp_damage = H.maxSanity * 0.1
		H.adjustSanityLoss(sp_damage)
		if(prob(25)) // Occasional message to avoid spam
			to_chat(H, span_warning("The fog drains your sanity..."))

/datum/status_effect/fog_exposure/proc/can_weather_act(mob/living/L, datum/weather/city_fog/fog)
	var/turf/mob_turf = get_turf(L)
	if(mob_turf && !(mob_turf.z in fog.impacted_z_levels))
		return FALSE
	if(fog.immunity_type in L.weather_immunities)
		return FALSE
	if(!(get_area(L) in fog.impacted_areas))
		return FALSE
	return TRUE

/atom/movable/screen/alert/status_effect/fog_exposure
	name = "Fog Exposure"
	desc = "The oppressive fog is draining your mind!"
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "foggy"

#undef STATUS_EFFECT_FOG_EXPOSURE
