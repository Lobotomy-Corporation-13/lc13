// ============================================================
// Contract Zone Effect — visual marker for active contracts
// ============================================================

/// Visual zone marker for active contracts. Invisible by default;
/// shown to squad members via client.images.
/obj/effect/contract_zone
	name = "contract zone"
	icon = 'icons/effects/effects.dmi'
	icon_state = "wave2"
	layer = ABOVE_NORMAL_TURF_LAYER
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	invisibility = INVISIBILITY_ABSTRACT

// ============================================================
// Escort Person — Duration-based, universal
// ============================================================

/// Escort a target person. Timer only ticks while a squad member is within 7 tiles of the target.
/datum/association_contract/escort_person
	contract_name = "Escort Person"
	contract_type = "escort_person"
	category = CONTRACT_CATEGORY_DURATION

/datum/association_contract/escort_person/activate(datum/association_squad/_squad)
	. = ..()
	if(!.)
		return
	if(target_mob)
		var/turf/T = get_turf(target_mob)
		if(T)
			var/obj/effect/contract_zone/zone = new(T)
			LAZYINITLIST(zone_effects)
			zone_effects += zone
			show_zone_to_squad(zone)
			RegisterSignal(target_mob, COMSIG_MOVABLE_MOVED, PROC_REF(on_target_moved))

/// Move the zone effect when the escort target moves.
/datum/association_contract/escort_person/proc/on_target_moved(datum/source)
	SIGNAL_HANDLER
	var/turf/T = get_turf(target_mob)
	for(var/obj/effect/contract_zone/zone in zone_effects)
		zone.forceMove(T)

/datum/association_contract/escort_person/cleanup_zones()
	if(target_mob && !QDELETED(target_mob))
		UnregisterSignal(target_mob, COMSIG_MOVABLE_MOVED)
	..()

/datum/association_contract/escort_person/should_pause()
	if(!target_mob || QDELETED(target_mob))
		return FALSE // Target gone — don't pause, let it tick down
	if(!squad)
		return TRUE
	// Check if any squad member is within 7 tiles of the target
	var/turf/target_turf = get_turf(target_mob)
	if(!target_turf)
		return TRUE
	for(var/mob/living/M in squad.members)
		if(get_dist(get_turf(M), target_turf) <= 7)
			return FALSE // At least one fixer is near
	return TRUE // No fixer in range — pause

/datum/association_contract/escort_person/get_status_text()
	if(state != CONTRACT_STATE_ACTIVE)
		return ..()
	var/time_text = DisplayTimeText(remaining_time)
	var/target_text = target_mob ? target_mob.name : "Unknown"
	if(timer_paused)
		return "Escorting [target_text]. [time_text] remaining (PAUSED — no fixer nearby)"
	return "Escorting [target_text]. [time_text] remaining"

// ============================================================
// Eliminate Target — Objective-based, universal
// ============================================================

/// Eliminate a specific target. Completes when the target dies or is deleted.
/datum/association_contract/eliminate_target
	contract_name = "Eliminate Target"
	contract_type = "eliminate_target"
	category = CONTRACT_CATEGORY_OBJECTIVE

/datum/association_contract/eliminate_target/activate(datum/association_squad/_squad)
	. = ..()
	if(!.)
		return
	// Register signals on the target to detect death or deletion
	if(target_mob)
		RegisterSignal(target_mob, COMSIG_LIVING_DEATH, PROC_REF(on_target_death))
		RegisterSignal(target_mob, COMSIG_PARENT_QDELETING, PROC_REF(on_target_deleted))
		// Spawn zone marker on target
		var/turf/T = get_turf(target_mob)
		if(T)
			var/obj/effect/contract_zone/zone = new(T)
			LAZYINITLIST(zone_effects)
			zone_effects += zone
			show_zone_to_squad(zone)
			RegisterSignal(target_mob, COMSIG_MOVABLE_MOVED, PROC_REF(on_target_moved))

/datum/association_contract/eliminate_target/complete()
	cleanup_target_signals()
	return ..()

/datum/association_contract/eliminate_target/fail()
	cleanup_target_signals()
	return ..()

/datum/association_contract/eliminate_target/Destroy()
	cleanup_target_signals()
	return ..()

/// Unregister signals from the target mob.
/datum/association_contract/eliminate_target/proc/cleanup_target_signals()
	if(target_mob && !QDELETED(target_mob))
		UnregisterSignal(target_mob, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))

/// Move the zone effect when the elimination target moves.
/datum/association_contract/eliminate_target/proc/on_target_moved(datum/source)
	SIGNAL_HANDLER
	var/turf/T = get_turf(target_mob)
	for(var/obj/effect/contract_zone/zone in zone_effects)
		zone.forceMove(T)

/datum/association_contract/eliminate_target/cleanup_zones()
	if(target_mob && !QDELETED(target_mob))
		UnregisterSignal(target_mob, COMSIG_MOVABLE_MOVED)
	..()

/// Target died — contract complete.
/datum/association_contract/eliminate_target/proc/on_target_death(datum/source, gibbed)
	SIGNAL_HANDLER
	if(state == CONTRACT_STATE_ACTIVE)
		// Use INVOKE_ASYNC since complete() may do chat/sound
		INVOKE_ASYNC(src, PROC_REF(complete))

/// Target was deleted (gibbed, etc.) — also counts as complete.
/datum/association_contract/eliminate_target/proc/on_target_deleted(datum/source)
	SIGNAL_HANDLER
	if(state == CONTRACT_STATE_ACTIVE)
		INVOKE_ASYNC(src, PROC_REF(complete))

/datum/association_contract/eliminate_target/get_status_text()
	if(state != CONTRACT_STATE_ACTIVE)
		return ..()
	if(!target_mob || QDELETED(target_mob))
		return "Target eliminated"
	if(target_mob.stat == DEAD)
		return "Target: [target_mob.name] — ELIMINATED"
	return "Target: [target_mob.name] — Alive"

/datum/association_contract/eliminate_target/set_completion_exp()
	completion_exp = CONTRACT_COMPLETION_OBJECTIVE

// ============================================================
// Patrol Route — Waypoint-based, universal
// ============================================================

/// Patrol a series of waypoints in order. Fixer must hold position at each for 30 seconds.
/datum/association_contract/patrol_route
	contract_name = "Patrol Route"
	contract_type = "patrol_route"
	category = CONTRACT_CATEGORY_DURATION
	/// Ordered list of waypoint positions: list(list("x" = X, "y" = Y), ...)
	var/list/patrol_waypoints
	/// Index of the current active waypoint (1-indexed)
	var/current_waypoint = 1
	/// Deciseconds spent at the current waypoint
	var/stay_progress = 0
	/// Z-level for waypoint turfs (set during creation)
	var/waypoint_zlevel = 0
	/// City map reference (for route viewer TGUI)
	var/datum/contract_citymap/citymap

/datum/association_contract/patrol_route/activate(datum/association_squad/_squad)
	. = ..()
	if(!.)
		return
	// Spawn 7x7 zone effects around each waypoint (matching patrol radius)
	if(patrol_waypoints && waypoint_zlevel)
		LAZYINITLIST(zone_effects)
		for(var/list/wp in patrol_waypoints)
			for(var/dx in -CONTRACT_PATROL_RADIUS to CONTRACT_PATROL_RADIUS)
				for(var/dy in -CONTRACT_PATROL_RADIUS to CONTRACT_PATROL_RADIUS)
					var/turf/T = locate(wp["x"] + dx, wp["y"] + dy, waypoint_zlevel)
					if(T)
						var/obj/effect/contract_zone/zone = new(T)
						zone_effects += zone
						show_zone_to_squad(zone)

/datum/association_contract/patrol_route/tick()
	if(state != CONTRACT_STATE_ACTIVE)
		stop_timers()
		return
	if(!patrol_waypoints || current_waypoint > length(patrol_waypoints))
		complete()
		return
	// Check if any squad member is within patrol radius of current waypoint
	var/list/wp = patrol_waypoints[current_waypoint]
	var/wp_x = wp["x"]
	var/wp_y = wp["y"]
	var/fixer_present = FALSE
	if(squad)
		for(var/mob/living/M in squad.members)
			var/turf/T = get_turf(M)
			if(!T)
				continue
			if(abs(T.x - wp_x) <= CONTRACT_PATROL_RADIUS && abs(T.y - wp_y) <= CONTRACT_PATROL_RADIUS)
				fixer_present = TRUE
				break
	if(!fixer_present)
		timer_paused = TRUE
		return
	timer_paused = FALSE
	// Accumulate stay time
	stay_progress += CONTRACT_PASSIVE_INTERVAL
	// Award passive EXP
	if(squad)
		var/exp_amount = CONTRACT_PASSIVE_EXP_TICK * get_exp_multiplier()
		squad.award_exp_to_all(exp_amount)
		passive_exp_accumulated += exp_amount
	// Check if stay at current waypoint is complete
	if(stay_progress >= CONTRACT_PATROL_STAY_TIME)
		stay_progress = 0
		current_waypoint++
		if(current_waypoint > length(patrol_waypoints))
			complete()
			return
		// Notify squad of next waypoint
		if(squad)
			for(var/mob/living/M in squad.members)
				to_chat(M, span_notice("Waypoint [current_waypoint - 1] complete! Move to waypoint [current_waypoint]."))
	// Update remaining time for display
	var/wp_remaining = CONTRACT_PATROL_STAY_TIME - stay_progress
	var/future_time = (length(patrol_waypoints) - current_waypoint) * CONTRACT_PATROL_STAY_TIME
	remaining_time = wp_remaining + future_time

/datum/association_contract/patrol_route/set_completion_exp()
	var/wp_count = length(patrol_waypoints)
	if(!wp_count)
		wp_count = 1
	completion_exp = CONTRACT_PATROL_EXP_PER_POINT * wp_count

/datum/association_contract/patrol_route/get_status_text()
	if(state != CONTRACT_STATE_ACTIVE)
		return ..()
	var/wp_total = length(patrol_waypoints)
	var/stay_left = CONTRACT_PATROL_STAY_TIME - stay_progress
	var/stay_text = DisplayTimeText(stay_left)
	if(timer_paused)
		return "Patrol [current_waypoint]/[wp_total] — [stay_text] (PAUSED)"
	return "Patrol [current_waypoint]/[wp_total] — [stay_text] remaining"

// --- Patrol Route Map Viewer (TGUI) ---

/datum/association_contract/patrol_route/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PatrolRouteMap")
		ui.open()

/datum/association_contract/patrol_route/ui_state()
	return GLOB.always_state

/// Static data: full city map grid and all waypoints.
/datum/association_contract/patrol_route/ui_static_data(mob/user)
	var/list/data = list()
	if(citymap?.generated)
		data["mapGrid"] = citymap.cached_map_grid
		data["gridWidth"] = citymap.grid_width
		data["gridHeight"] = citymap.grid_height
		data["offsetX"] = citymap.offset_x
		data["offsetY"] = citymap.offset_y
	data["waypoints"] = patrol_waypoints
	return data

/// Dynamic data: current progress.
/datum/association_contract/patrol_route/ui_data(mob/user)
	var/list/data = list()
	data["currentWaypoint"] = current_waypoint
	data["stayProgress"] = stay_progress
	data["stayRequired"] = CONTRACT_PATROL_STAY_TIME
	data["statusText"] = get_status_text()
	return data

