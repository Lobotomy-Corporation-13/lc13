/**
 * Resurgence Outpost - Farm Zone System
 *
 * Zone-based farming with shared timers to reduce server load.
 * All plots in a zone share a single growth timer instead of
 * each plot having its own process() call.
 * Compatible with standard hydroponics /obj/item/seeds.
 */

/// Global list of all farming zones
GLOBAL_LIST_EMPTY(resurgence_farm_zones)

/datum/farm_zone
	/// Display name for this zone
	var/name = "Farm Zone"
	/// List of /obj/structure/farm_plot in this zone
	var/list/plots = list()
	/// Time between growth ticks (30 seconds default)
	var/growth_interval = 30 SECONDS
	/// Timer ID for cancellation
	var/timer_id
	/// Unique zone identifier
	var/zone_id

/datum/farm_zone/New(zone_name)
	. = ..()
	name = zone_name
	zone_id = GLOB.resurgence_farm_zones.len + 1
	GLOB.resurgence_farm_zones += src
	start_growth_timer()

/datum/farm_zone/Destroy()
	stop_growth_timer()
	for(var/obj/structure/farm_plot/plot in plots)
		plot.parent_zone = null
		qdel(plot)
	plots.Cut()
	GLOB.resurgence_farm_zones -= src
	return ..()

/// Start the shared growth timer for this zone
/datum/farm_zone/proc/start_growth_timer()
	timer_id = addtimer(CALLBACK(src, PROC_REF(process_growth)), growth_interval, TIMER_LOOP | TIMER_STOPPABLE)

/// Stop the growth timer
/datum/farm_zone/proc/stop_growth_timer()
	if(timer_id)
		deltimer(timer_id)
		timer_id = null

/// Process all plots in zone - ONE timer call for ALL plots
/datum/farm_zone/proc/process_growth()
	for(var/obj/structure/farm_plot/plot in plots)
		if(QDELETED(plot))
			plots -= plot
			continue
		plot.on_zone_tick()

	// Dissolve zone if empty
	if(!plots.len)
		qdel(src)

/// Add a plot to this zone
/datum/farm_zone/proc/add_plot(obj/structure/farm_plot/plot)
	plots += plot
	plot.parent_zone = src

/// Remove a plot from this zone
/datum/farm_zone/proc/remove_plot(obj/structure/farm_plot/plot)
	plots -= plot
	if(!plots.len)
		qdel(src)

/// Get zone statistics for UI display
/datum/farm_zone/proc/get_stats()
	var/ready_count = 0
	var/total_water = 0
	for(var/obj/structure/farm_plot/plot in plots)
		if(plot.harvest)
			ready_count++
		total_water += plot.water_level
	return list(
		"id" = zone_id,
		"name" = name,
		"plot_count" = plots.len,
		"ready_count" = ready_count,
		"avg_water" = plots.len ? round(total_water / plots.len) : 0
	)
