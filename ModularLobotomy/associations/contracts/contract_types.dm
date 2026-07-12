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
	// Base EXP per waypoint, plus a scaling bonus for longer routes
	// Bonus: +10% per waypoint beyond the first (e.g. 5 waypoints = 1.4x multiplier)
	var/scaling = 1 + (wp_count - 1) * 0.1
	completion_exp = round(CONTRACT_PATROL_EXP_PER_POINT * wp_count * scaling)

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

// ============================================================
// Investigate Person — Objective-based, Seven-specific
// ============================================================

/// Investigate a target person by filing intel reports.
/// Completes when the required number of reports are filed on the target via the dossier.
/datum/association_contract/investigate_person
	contract_name = "Investigate Person"
	contract_type = "investigate_person"
	category = CONTRACT_CATEGORY_OBJECTIVE
	association_type = ASSOCIATION_SEVEN
	/// Number of reports required for completion
	var/required_reports = 2
	/// Number of reports filed so far
	var/reports_filed = 0

/// Override start_timers to enable passive EXP ticks even for objective contracts.
/datum/association_contract/investigate_person/start_timers()
	tick_timer_id = addtimer(CALLBACK(src, PROC_REF(tick)), CONTRACT_PASSIVE_INTERVAL, TIMER_STOPPABLE | TIMER_LOOP)

/// Only awards passive EXP — does not decrement time or auto-complete.
/// Completion is driven by on_report_filed().
/datum/association_contract/investigate_person/tick()
	if(state != CONTRACT_STATE_ACTIVE)
		stop_timers()
		return
	if(squad)
		var/exp_amount = CONTRACT_PASSIVE_EXP_TICK * get_exp_multiplier()
		squad.award_exp_to_all(exp_amount)
		passive_exp_accumulated += exp_amount

/// Set the required report count based on tier (1, 2, or 3).
/datum/association_contract/investigate_person/proc/set_report_tier(tier_value)
	switch(tier_value)
		if(1)
			required_reports = CONTRACT_INVESTIGATE_TIER1_REPORTS
		if(2)
			required_reports = CONTRACT_INVESTIGATE_TIER2_REPORTS
		if(3)
			required_reports = CONTRACT_INVESTIGATE_TIER3_REPORTS
		else
			required_reports = CONTRACT_INVESTIGATE_TIER1_REPORTS

/// Called by the dossier when a report is filed on this contract's target.
/datum/association_contract/investigate_person/proc/on_report_filed()
	if(state != CONTRACT_STATE_ACTIVE)
		return
	reports_filed++
	if(squad)
		for(var/mob/living/M in squad.members)
			to_chat(M, span_notice("Investigation progress: [reports_filed]/[required_reports] reports filed."))
	if(reports_filed >= required_reports)
		complete()

/datum/association_contract/investigate_person/set_completion_exp()
	completion_exp = CONTRACT_COMPLETION_OBJECTIVE

/datum/association_contract/investigate_person/get_status_text()
	if(state != CONTRACT_STATE_ACTIVE)
		return ..()
	var/target_text = target_mob ? target_mob.name : "Unknown"
	return "Investigating [target_text]. [reports_filed]/[required_reports] reports filed"

/datum/association_contract/investigate_person/get_display_data()
	var/list/data = ..()
	data["reports_filed"] = reports_filed
	data["required_reports"] = required_reports
	return data

// ============================================================
// Surveillance Post — Duration-based, Seven-specific
// ============================================================

/// Deploy Seven recorders to surveil a location.
/// Timer ticks only while at least one active squad recorder is within range of the surveillance point.
/datum/association_contract/surveillance_post
	contract_name = "Surveillance Post"
	contract_type = "surveillance_post"
	category = CONTRACT_CATEGORY_DURATION
	association_type = ASSOCIATION_SEVEN
	/// The single waypoint for this surveillance location
	var/list/surveillance_point
	/// Z-level for the waypoint turf
	var/waypoint_zlevel = 0
	/// City map reference
	var/datum/contract_citymap/citymap

/datum/association_contract/surveillance_post/activate(datum/association_squad/_squad)
	. = ..()
	if(!.)
		return
	// Spawn zone effects around the surveillance point
	if(surveillance_point && waypoint_zlevel)
		LAZYINITLIST(zone_effects)
		var/sp_x = surveillance_point["x"]
		var/sp_y = surveillance_point["y"]
		for(var/dx in -CONTRACT_SURVEILLANCE_RADIUS to CONTRACT_SURVEILLANCE_RADIUS)
			for(var/dy in -CONTRACT_SURVEILLANCE_RADIUS to CONTRACT_SURVEILLANCE_RADIUS)
				var/turf/T = locate(sp_x + dx, sp_y + dy, waypoint_zlevel)
				if(T)
					var/obj/effect/contract_zone/zone = new(T)
					zone_effects += zone
					show_zone_to_squad(zone)

/// Pause when no active squad recorder is within range of the surveillance point.
/datum/association_contract/surveillance_post/should_pause()
	if(!surveillance_point || !squad)
		return TRUE
	var/sp_x = surveillance_point["x"]
	var/sp_y = surveillance_point["y"]
	for(var/mob/living/M in squad.members)
		var/owner_key = ref(M)
		var/list/recorders = GLOB.seven_active_recorders[owner_key]
		if(!islist(recorders))
			continue
		for(var/obj/item/seven_recorder/R in recorders)
			if(QDELETED(R) || !R.recording)
				continue
			var/turf/rec_turf = get_turf(R)
			if(!rec_turf || rec_turf.z != waypoint_zlevel)
				continue
			if(abs(rec_turf.x - sp_x) <= CONTRACT_SURVEILLANCE_RADIUS && abs(rec_turf.y - sp_y) <= CONTRACT_SURVEILLANCE_RADIUS)
				return FALSE
	return TRUE

/datum/association_contract/surveillance_post/get_status_text()
	if(state != CONTRACT_STATE_ACTIVE)
		return ..()
	var/time_text = DisplayTimeText(remaining_time)
	if(timer_paused)
		return "Surveillance post. [time_text] remaining (PAUSED \u2014 no recorder in area)"
	return "Surveillance post. [time_text] remaining"

// --- Surveillance Post Map Viewer (TGUI) ---

/datum/association_contract/surveillance_post/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PatrolRouteMap")
		ui.open()

/datum/association_contract/surveillance_post/ui_state()
	return GLOB.always_state

/// Static data: full city map grid and surveillance point as a single waypoint.
/datum/association_contract/surveillance_post/ui_static_data(mob/user)
	var/list/data = list()
	if(citymap?.generated)
		data["mapGrid"] = citymap.cached_map_grid
		data["gridWidth"] = citymap.grid_width
		data["gridHeight"] = citymap.grid_height
		data["offsetX"] = citymap.offset_x
		data["offsetY"] = citymap.offset_y
	if(surveillance_point)
		data["waypoints"] = list(surveillance_point)
	else
		data["waypoints"] = list()
	return data

/// Dynamic data: current progress.
/datum/association_contract/surveillance_post/ui_data(mob/user)
	var/list/data = list()
	data["currentWaypoint"] = 1
	data["stayProgress"] = 0
	data["stayRequired"] = 0
	data["statusText"] = get_status_text()
	return data

// ============================================================
// Guard Area — Duration-based, Zwei-specific
// ============================================================

/// Guard a designated area. Timer ticks while at least one squad member is inside the zone.
/datum/association_contract/guard_area
	contract_name = "Guard Area"
	contract_type = "guard_area"
	category = CONTRACT_CATEGORY_DURATION
	association_type = ASSOCIATION_ZWEI
	/// The center waypoint for the guard zone
	var/list/guard_point
	/// Z-level for the waypoint turf
	var/waypoint_zlevel = 0
	/// City map reference
	var/datum/contract_citymap/citymap

/datum/association_contract/guard_area/activate(datum/association_squad/_squad)
	. = ..()
	if(!.)
		return
	// Spawn zone effects around the guard point
	if(guard_point && waypoint_zlevel)
		LAZYINITLIST(zone_effects)
		var/gp_x = guard_point["x"]
		var/gp_y = guard_point["y"]
		for(var/dx in -CONTRACT_GUARD_AREA_RADIUS to CONTRACT_GUARD_AREA_RADIUS)
			for(var/dy in -CONTRACT_GUARD_AREA_RADIUS to CONTRACT_GUARD_AREA_RADIUS)
				var/turf/T = locate(gp_x + dx, gp_y + dy, waypoint_zlevel)
				if(T)
					var/obj/effect/contract_zone/zone = new(T)
					zone_effects += zone
					show_zone_to_squad(zone)

/// Pause when no squad member is inside the guard zone.
/datum/association_contract/guard_area/should_pause()
	if(!guard_point || !squad)
		return TRUE
	var/gp_x = guard_point["x"]
	var/gp_y = guard_point["y"]
	for(var/mob/living/M in squad.members)
		var/turf/T = get_turf(M)
		if(!T || T.z != waypoint_zlevel)
			continue
		if(abs(T.x - gp_x) <= CONTRACT_GUARD_AREA_RADIUS && abs(T.y - gp_y) <= CONTRACT_GUARD_AREA_RADIUS)
			return FALSE
	return TRUE

/datum/association_contract/guard_area/get_status_text()
	if(state != CONTRACT_STATE_ACTIVE)
		return ..()
	var/time_text = DisplayTimeText(remaining_time)
	if(timer_paused)
		return "Guarding area. [time_text] remaining (PAUSED \u2014 no fixer in zone)"
	return "Guarding area. [time_text] remaining"

// --- Guard Area Map Viewer (TGUI) ---

/datum/association_contract/guard_area/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PatrolRouteMap")
		ui.open()

/datum/association_contract/guard_area/ui_state()
	return GLOB.always_state

/// Static data: full city map grid and guard point as a single waypoint.
/datum/association_contract/guard_area/ui_static_data(mob/user)
	var/list/data = list()
	if(citymap?.generated)
		data["mapGrid"] = citymap.cached_map_grid
		data["gridWidth"] = citymap.grid_width
		data["gridHeight"] = citymap.grid_height
		data["offsetX"] = citymap.offset_x
		data["offsetY"] = citymap.offset_y
	if(guard_point)
		data["waypoints"] = list(guard_point)
	else
		data["waypoints"] = list()
	return data

/// Dynamic data: current progress.
/datum/association_contract/guard_area/ui_data(mob/user)
	var/list/data = list()
	data["currentWaypoint"] = 1
	data["stayProgress"] = 0
	data["stayRequired"] = 0
	data["statusText"] = get_status_text()
	return data

// ============================================================
// Protect Person — Duration-based, Zwei-specific
// ============================================================

/// Bodyguard a target person. Timer ticks while a squad member is within 7 tiles.
/// Client receives 15% damage reduction (post-hoc heal) while a fixer is nearby.
/datum/association_contract/protect_person
	contract_name = "Protect Person"
	contract_type = "protect_person"
	category = CONTRACT_CATEGORY_DURATION
	association_type = ASSOCIATION_ZWEI

/datum/association_contract/protect_person/activate(datum/association_squad/_squad)
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
		// Register damage reduction signal
		RegisterSignal(target_mob, COMSIG_MOB_AFTER_APPLY_DAMGE, PROC_REF(on_client_damaged))

/// Move the zone effect when the protected target moves.
/datum/association_contract/protect_person/proc/on_target_moved(datum/source)
	SIGNAL_HANDLER
	var/turf/T = get_turf(target_mob)
	for(var/obj/effect/contract_zone/zone in zone_effects)
		zone.forceMove(T)

/// Post-hoc damage reduction: heal 15% of damage when a fixer is nearby.
/datum/association_contract/protect_person/proc/on_client_damaged(datum/source, damage, damagetype, def_zone)
	SIGNAL_HANDLER
	if(state != CONTRACT_STATE_ACTIVE || !squad)
		return
	if(!target_mob || QDELETED(target_mob))
		return
	// Check if any squad member is within range
	var/turf/target_turf = get_turf(target_mob)
	if(!target_turf)
		return
	var/fixer_nearby = FALSE
	for(var/mob/living/M in squad.members)
		if(get_dist(get_turf(M), target_turf) <= CONTRACT_PROTECT_PERSON_RANGE)
			fixer_nearby = TRUE
			break
	if(!fixer_nearby)
		return
	// Heal the target for 15% of damage taken
	var/heal_amount = damage * CONTRACT_PROTECT_PERSON_DR_HEAL
	if(heal_amount > 0)
		INVOKE_ASYNC(target_mob, TYPE_PROC_REF(/mob/living, adjustBruteLoss), -heal_amount)

/datum/association_contract/protect_person/cleanup_zones()
	cleanup_target_signals()
	..()

/datum/association_contract/protect_person/complete()
	cleanup_target_signals()
	return ..()

/datum/association_contract/protect_person/fail()
	cleanup_target_signals()
	return ..()

/datum/association_contract/protect_person/Destroy()
	cleanup_target_signals()
	return ..()

/// Unregister all signals from the target mob.
/datum/association_contract/protect_person/proc/cleanup_target_signals()
	if(target_mob && !QDELETED(target_mob))
		UnregisterSignal(target_mob, list(COMSIG_MOVABLE_MOVED, COMSIG_MOB_AFTER_APPLY_DAMGE))

/datum/association_contract/protect_person/should_pause()
	if(!target_mob || QDELETED(target_mob))
		return FALSE // Target gone — don't pause, let it tick down
	if(!squad)
		return TRUE
	// Check if any squad member is within range of the target
	var/turf/target_turf = get_turf(target_mob)
	if(!target_turf)
		return TRUE
	for(var/mob/living/M in squad.members)
		if(get_dist(get_turf(M), target_turf) <= CONTRACT_PROTECT_PERSON_RANGE)
			return FALSE
	return TRUE

/datum/association_contract/protect_person/get_status_text()
	if(state != CONTRACT_STATE_ACTIVE)
		return ..()
	var/time_text = DisplayTimeText(remaining_time)
	var/target_text = target_mob ? target_mob.name : "Unknown"
	if(timer_paused)
		return "Protecting [target_text]. [time_text] remaining (PAUSED \u2014 no fixer nearby)"
	return "Protecting [target_text]. [time_text] remaining"

// ============================================================
// Host Event — Objective-based, Dieci-specific
// ============================================================

/// Hire Dieci fixers to host a public event at a designated location.
/// Completes when the Director finishes hosting the required event type.
/// Hosting at the marked waypoint location doubles event tick EXP.
/datum/association_contract/host_event
	contract_name = "Host Event"
	contract_type = "host_event"
	category = CONTRACT_CATEGORY_OBJECTIVE
	association_type = ASSOCIATION_DIECI
	/// Required event type key (e.g., "book_reading", "training_session", "charity_sermon")
	var/required_event_type = ""
	/// Human-readable event type name
	var/required_event_name = ""
	/// The single waypoint for the event location
	var/list/event_waypoint
	/// Z-level for the waypoint turf
	var/waypoint_zlevel = 0
	/// City map reference
	var/datum/contract_citymap/citymap

/// Override start_timers to enable passive EXP ticks even for objective contracts.
/datum/association_contract/host_event/start_timers()
	tick_timer_id = addtimer(CALLBACK(src, PROC_REF(tick)), CONTRACT_PASSIVE_INTERVAL, TIMER_STOPPABLE | TIMER_LOOP)

/// Only awards passive EXP — completion is driven by on_event_complete().
/datum/association_contract/host_event/tick()
	if(state != CONTRACT_STATE_ACTIVE)
		stop_timers()
		return
	if(squad)
		var/exp_amount = CONTRACT_PASSIVE_EXP_TICK * get_exp_multiplier()
		squad.award_exp_to_all(exp_amount)
		passive_exp_accumulated += exp_amount

/datum/association_contract/host_event/activate(datum/association_squad/_squad)
	. = ..()
	if(!.)
		return
	// Spawn zone effects around the event waypoint
	if(event_waypoint && waypoint_zlevel)
		LAZYINITLIST(zone_effects)
		var/wp_x = event_waypoint["x"]
		var/wp_y = event_waypoint["y"]
		for(var/dx in -CONTRACT_HOST_EVENT_WAYPOINT_RANGE to CONTRACT_HOST_EVENT_WAYPOINT_RANGE)
			for(var/dy in -CONTRACT_HOST_EVENT_WAYPOINT_RANGE to CONTRACT_HOST_EVENT_WAYPOINT_RANGE)
				var/turf/T = locate(wp_x + dx, wp_y + dy, waypoint_zlevel)
				if(T)
					var/obj/effect/contract_zone/zone = new(T)
					zone.color = "#FFD700"
					zone_effects += zone
					show_zone_to_squad(zone)

/// Set the required event type based on tier value. 1=Book Reading, 2=Training Session, 3=Charity Sermon.
/datum/association_contract/host_event/proc/set_event_tier(tier_value)
	switch(tier_value)
		if(1)
			required_event_type = "book_reading"
			required_event_name = "Book Reading"
		if(2)
			required_event_type = "training_session"
			required_event_name = "Training Session"
		if(3)
			required_event_type = "charity_sermon"
			required_event_name = "Charity Sermon"
		else
			required_event_type = "book_reading"
			required_event_name = "Book Reading"

/// Check if a turf is within the waypoint proximity range.
/datum/association_contract/host_event/proc/is_near_waypoint(turf/T)
	if(!event_waypoint || !T)
		return FALSE
	if(T.z != waypoint_zlevel)
		return FALSE
	return (abs(T.x - event_waypoint["x"]) <= CONTRACT_HOST_EVENT_WAYPOINT_RANGE && abs(T.y - event_waypoint["y"]) <= CONTRACT_HOST_EVENT_WAYPOINT_RANGE)

/// Called by the event system when the matching event type completes.
/datum/association_contract/host_event/proc/on_event_complete()
	if(state != CONTRACT_STATE_ACTIVE)
		return
	complete()

/datum/association_contract/host_event/set_completion_exp()
	completion_exp = CONTRACT_COMPLETION_OBJECTIVE

/datum/association_contract/host_event/get_status_text()
	if(state != CONTRACT_STATE_ACTIVE)
		return ..()
	return "Host [required_event_name]. Awaiting event completion"

/datum/association_contract/host_event/get_display_data()
	var/list/data = ..()
	data["required_event_type"] = required_event_type
	data["required_event_name"] = required_event_name
	return data

// --- Host Event Map Viewer (TGUI) ---

/datum/association_contract/host_event/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PatrolRouteMap")
		ui.open()

/datum/association_contract/host_event/ui_state()
	return GLOB.always_state

/// Static data: full city map grid and event waypoint.
/datum/association_contract/host_event/ui_static_data(mob/user)
	var/list/data = list()
	if(citymap?.generated)
		data["mapGrid"] = citymap.cached_map_grid
		data["gridWidth"] = citymap.grid_width
		data["gridHeight"] = citymap.grid_height
		data["offsetX"] = citymap.offset_x
		data["offsetY"] = citymap.offset_y
	if(event_waypoint)
		data["waypoints"] = list(event_waypoint)
	else
		data["waypoints"] = list()
	return data

/// Dynamic data: current status.
/datum/association_contract/host_event/ui_data(mob/user)
	var/list/data = list()
	data["currentWaypoint"] = 1
	data["stayProgress"] = 0
	data["stayRequired"] = 0
	data["statusText"] = get_status_text()
	return data

// ============================================================
// Medical Relief — Objective-based, Dieci-specific
// ============================================================

/// Provide medical aid to unique patients. Completes when the required number of different people are healed.
/datum/association_contract/medical_relief
	contract_name = "Medical Relief"
	contract_type = "medical_relief"
	category = CONTRACT_CATEGORY_OBJECTIVE
	association_type = ASSOCIATION_DIECI
	/// Number of unique patients required for completion
	var/required_patients = 5
	/// List of weakrefs to unique carbons healed so far
	var/list/healed_refs = list()

/// Override start_timers to enable passive EXP ticks even for objective contracts.
/datum/association_contract/medical_relief/start_timers()
	tick_timer_id = addtimer(CALLBACK(src, PROC_REF(tick)), CONTRACT_PASSIVE_INTERVAL, TIMER_STOPPABLE | TIMER_LOOP)

/// Only awards passive EXP — completion is driven by on_heal().
/datum/association_contract/medical_relief/tick()
	if(state != CONTRACT_STATE_ACTIVE)
		stop_timers()
		return
	if(squad)
		var/exp_amount = CONTRACT_PASSIVE_EXP_TICK * get_exp_multiplier()
		squad.award_exp_to_all(exp_amount)
		passive_exp_accumulated += exp_amount

/// Set the required patient count based on tier.
/datum/association_contract/medical_relief/proc/set_patient_tier(tier_value)
	switch(tier_value)
		if(1)
			required_patients = CONTRACT_MEDICAL_RELIEF_TIER1_PATIENTS
		if(2)
			required_patients = CONTRACT_MEDICAL_RELIEF_TIER2_PATIENTS
		if(3)
			required_patients = CONTRACT_MEDICAL_RELIEF_TIER3_PATIENTS
		else
			required_patients = CONTRACT_MEDICAL_RELIEF_TIER1_PATIENTS

/// Called by the healing kit when a patient is healed. Tracks unique patients.
/datum/association_contract/medical_relief/proc/on_heal(mob/living/carbon/target)
	if(state != CONTRACT_STATE_ACTIVE)
		return
	if(!target || QDELETED(target))
		return
	// Check if this target is already tracked
	var/target_ref = ref(target)
	if(target_ref in healed_refs)
		return
	healed_refs += target_ref
	// Notify squad of progress
	if(squad)
		for(var/mob/living/M in squad.members)
			to_chat(M, span_notice("Medical relief progress: [length(healed_refs)]/[required_patients] patients treated."))
	// Check completion
	if(length(healed_refs) >= required_patients)
		complete()

/datum/association_contract/medical_relief/set_completion_exp()
	completion_exp = CONTRACT_COMPLETION_OBJECTIVE

/datum/association_contract/medical_relief/get_status_text()
	if(state != CONTRACT_STATE_ACTIVE)
		return ..()
	return "[length(healed_refs)]/[required_patients] patients treated"

/datum/association_contract/medical_relief/get_display_data()
	var/list/data = ..()
	data["healed_count"] = length(healed_refs)
	data["required_patients"] = required_patients
	return data

// ============================================================
// Tend to Person — Duration-based, Dieci-specific
// ============================================================

/// Tend to a target person. Timer ticks while a squad member is within 7 tiles and target is above 50% HP.
/// Healing the target grants +50% bonus EXP per tick.
/datum/association_contract/tend_to_person
	contract_name = "Tend to Person"
	contract_type = "tend_to_person"
	category = CONTRACT_CATEGORY_DURATION
	association_type = ASSOCIATION_DIECI
	/// Whether a squad member healed the target since the last tick (for bonus EXP)
	var/healed_recently = FALSE

/datum/association_contract/tend_to_person/activate(datum/association_squad/_squad)
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

/// Move the zone effect when the target moves.
/datum/association_contract/tend_to_person/proc/on_target_moved(datum/source)
	SIGNAL_HANDLER
	var/turf/T = get_turf(target_mob)
	for(var/obj/effect/contract_zone/zone in zone_effects)
		zone.forceMove(T)

/datum/association_contract/tend_to_person/cleanup_zones()
	cleanup_target_signals()
	..()

/datum/association_contract/tend_to_person/complete()
	cleanup_target_signals()
	return ..()

/datum/association_contract/tend_to_person/fail()
	cleanup_target_signals()
	return ..()

/datum/association_contract/tend_to_person/Destroy()
	cleanup_target_signals()
	return ..()

/// Unregister signals from the target mob.
/datum/association_contract/tend_to_person/proc/cleanup_target_signals()
	if(target_mob && !QDELETED(target_mob))
		UnregisterSignal(target_mob, COMSIG_MOVABLE_MOVED)

/// Pause when no fixer is within range OR target is below 50% HP.
/datum/association_contract/tend_to_person/should_pause()
	if(!target_mob || QDELETED(target_mob))
		return FALSE // Target gone — don't pause, let it tick down
	if(target_mob.stat == DEAD)
		return FALSE
	// Check HP threshold
	if(target_mob.health / target_mob.maxHealth < CONTRACT_TEND_PERSON_HP_THRESHOLD)
		return TRUE
	// Check if any squad member is within range
	if(!squad)
		return TRUE
	var/turf/target_turf = get_turf(target_mob)
	if(!target_turf)
		return TRUE
	for(var/mob/living/M in squad.members)
		if(get_dist(get_turf(M), target_turf) <= CONTRACT_TEND_PERSON_RANGE)
			return FALSE // At least one fixer is near
	return TRUE // No fixer in range — pause

/// Custom tick that applies heal bonus EXP when the target was recently healed.
/datum/association_contract/tend_to_person/tick()
	if(state != CONTRACT_STATE_ACTIVE)
		stop_timers()
		return
	// Check pause condition
	if(should_pause())
		timer_paused = TRUE
		healed_recently = FALSE
		return
	timer_paused = FALSE
	// Decrement remaining time
	remaining_time -= CONTRACT_PASSIVE_INTERVAL
	// Calculate EXP with optional heal bonus
	var/exp_mult = get_exp_multiplier()
	if(healed_recently)
		exp_mult *= CONTRACT_TEND_PERSON_HEAL_EXP_BONUS
	healed_recently = FALSE
	// Award passive EXP
	if(squad)
		var/exp_amount = CONTRACT_PASSIVE_EXP_TICK * exp_mult
		squad.award_exp_to_all(exp_amount)
		passive_exp_accumulated += exp_amount
	// Check completion
	if(remaining_time <= 0)
		remaining_time = 0
		complete()

/datum/association_contract/tend_to_person/get_status_text()
	if(state != CONTRACT_STATE_ACTIVE)
		return ..()
	var/time_text = DisplayTimeText(remaining_time)
	var/target_text = target_mob ? target_mob.name : "Unknown"
	if(timer_paused)
		// Determine reason for pause
		if(target_mob && !QDELETED(target_mob) && target_mob.stat != DEAD)
			if(target_mob.health / target_mob.maxHealth < CONTRACT_TEND_PERSON_HP_THRESHOLD)
				return "Tending to [target_text]. [time_text] remaining (PAUSED \u2014 target below 50% HP)"
		return "Tending to [target_text]. [time_text] remaining (PAUSED \u2014 no fixer nearby)"
	if(healed_recently)
		return "Tending to [target_text]. [time_text] remaining (healing bonus active)"
	return "Tending to [target_text]. [time_text] remaining"

