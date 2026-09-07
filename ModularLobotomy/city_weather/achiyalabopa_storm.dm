#define STATUS_EFFECT_STORM_EXPOSURE /datum/status_effect/storm_exposure

/// Achiyalabopa Storm - Permanent dark storm with enhanced damage from certain mobs
/datum/weather/achiyalabopa_storm
	name = "achiyalabopa storm"
	desc = "A dark and ominous storm that shrouds the city in darkness."
	immunity_type = "achiyalabopa_storm"

	telegraph_message = span_userdanger("The sky darkens... An ominous presence approaches!")
	telegraph_duration = 10 SECONDS
	telegraph_overlay = "void"

	weather_message = span_userdanger("<b>The storm arrives! Darkness engulfs the city!</b>")
	weather_overlay = "void_storm"
	perpetual = TRUE // Lasts forever until manually ended

	end_message = span_boldannounce("The oppressive darkness begins to lift...")
	end_overlay = "void"
	end_duration = 10 SECONDS

	area_type = /area
	protect_indoors = TRUE
	target_trait = ZTRAIT_STATION

	/// List of spawned Mirage Reapers
	var/list/spawned_reapers = list()
	/// Timer for spawning Mirage Reapers
	var/reaper_spawn_timer
	/// How often to spawn reapers (in seconds)
	var/reaper_spawn_interval = 30 SECONDS

/datum/weather/achiyalabopa_storm/start()
	. = ..()
	// Start spawning Mirage Reapers
	StartReaperSpawning()

/datum/weather/achiyalabopa_storm/end()
	// Stop spawning reapers
	if(reaper_spawn_timer)
		deltimer(reaper_spawn_timer)
		reaper_spawn_timer = null

	// Clean up spawned reapers
	for(var/mob/living/simple_animal/hostile/mirage_reaper/reaper in spawned_reapers)
		if(!QDELETED(reaper))
			qdel(reaper)
	spawned_reapers.Cut()

	return ..()

/datum/weather/achiyalabopa_storm/weather_act(mob/living/L)
	if(!ishuman(L))
		return

	var/mob/living/carbon/human/H = L

	// Apply or refresh storm exposure status
	var/datum/status_effect/storm_exposure/storm = H.has_status_effect(STATUS_EFFECT_STORM_EXPOSURE)

	if(!storm)
		H.apply_status_effect(STATUS_EFFECT_STORM_EXPOSURE)
	else
		storm.RefreshDuration()

/// Starts the periodic spawning of Mirage Reapers
/datum/weather/achiyalabopa_storm/proc/StartReaperSpawning()
	SpawnMirageReaper() // Spawn one immediately
	reaper_spawn_timer = addtimer(CALLBACK(src, PROC_REF(ReaperSpawnLoop)), reaper_spawn_interval, TIMER_STOPPABLE)

/datum/weather/achiyalabopa_storm/proc/ReaperSpawnLoop()
	if(QDELETED(src))
		return

	SpawnMirageReaper()

	// Schedule next spawn
	reaper_spawn_timer = addtimer(CALLBACK(src, PROC_REF(ReaperSpawnLoop)), reaper_spawn_interval, TIMER_STOPPABLE)

/// Spawns a Mirage Reaper at a random landmark
/datum/weather/achiyalabopa_storm/proc/SpawnMirageReaper()
	if(!GLOB.mirage_reaper_spawns || !length(GLOB.mirage_reaper_spawns))
		return

	// Pick a random spawn landmark
	var/obj/effect/landmark/mirage_reaper_spawn/spawn_landmark = pick(GLOB.mirage_reaper_spawns)
	if(!spawn_landmark)
		return

	var/turf/spawn_turf = get_turf(spawn_landmark)
	if(!spawn_turf)
		return

	// Spawn the reaper
	var/mob/living/simple_animal/hostile/mirage_reaper/reaper = new(spawn_turf)
	spawned_reapers += reaper

	// Announce to nearby players
	for(var/mob/M in range(15, spawn_turf))
		to_chat(M, span_warning("A Mirage Reaper materializes from the storm!"))
	playsound(spawn_turf, 'sound/effects/ghost.ogg', 50, TRUE)

/// Storm Exposure - Applies gray color filter to affected humans
/datum/status_effect/storm_exposure
	id = "storm_exposure"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1
	tick_interval = 5 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/storm_exposure
	on_remove_on_mob_delete = TRUE
	/// Client reference for color manipulation
	var/client/C
	/// Original client color
	var/initial_color

/atom/movable/screen/alert/status_effect/storm_exposure
	name = "Storm Exposure"
	desc = "The dark storm dims your vision."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "storm_exposure"

/datum/status_effect/storm_exposure/on_apply()
	. = ..()
	if(!.)
		return

	// Get client reference
	if(ismob(owner))
		var/mob/M = owner
		if(M.client)
			C = M.client

	// Apply light gray color filter
	if(C)
		initial_color = C.color
		C.color = "#c8c8c8ff" // Light gray

	to_chat(owner, span_warning("The storm dims your vision..."))
	return TRUE

/datum/status_effect/storm_exposure/on_remove()
	// Restore color
	if(C)
		C.color = initial_color

	to_chat(owner, span_notice("Your vision clears as the storm's influence fades."))
	return ..()

/datum/status_effect/storm_exposure/tick()
	// Check if still in storm
	var/datum/weather/achiyalabopa_storm/storm = locate() in SSweather.processing
	if(!storm)
		qdel(src)
		return

	// Check if still outdoors
	var/turf/T = get_turf(owner)
	if(!T)
		qdel(src)
		return

	var/area/A = get_area(T)
	if(!istype(A) || !A.outdoors)
		qdel(src)
		return

/datum/status_effect/storm_exposure/proc/RefreshDuration()
	// Just keep it active, no need to do anything
	return

#undef STATUS_EFFECT_STORM_EXPOSURE
