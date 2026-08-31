/**
 * Resurgence Outpost - Event Manager
 *
 * Manages the random event system, checking for and triggering events.
 * Initialized when the resurgence gamemode starts.
 */

/datum/resurgence_event_manager
	/// All registered event types (list of typepaths)
	var/list/event_types = list()
	/// Currently active events (list of event datums)
	var/list/active_events = list()
	/// Event history for this round (list of event records)
	var/list/event_history = list()
	/// Time of last event check
	var/last_check_time = 0
	/// Time of last event trigger
	var/last_event_time = 0
	/// Whether the event loop is running
	var/running = FALSE
	/// Timer ID for the event loop
	var/loop_timer_id = null

	/// Category weights (adjustable)
	var/positive_weight = EVENT_WEIGHT_POSITIVE
	var/negative_weight = EVENT_WEIGHT_NEGATIVE
	var/neutral_weight = EVENT_WEIGHT_NEUTRAL

/datum/resurgence_event_manager/New()
	. = ..()
	register_events()

/datum/resurgence_event_manager/Destroy()
	stop()
	for(var/datum/resurgence_event/E in active_events)
		E.end_event(silent = TRUE)
	active_events.Cut()
	event_types.Cut()
	return ..()

/// Register all event types
/datum/resurgence_event_manager/proc/register_events()
	// Get all subtypes of resurgence_event
	for(var/path in subtypesof(/datum/resurgence_event))
		var/datum/resurgence_event/E = path
		// Skip abstract types (weight = 0)
		if(initial(E.weight) <= 0)
			continue
		event_types += path

	log_game("RESURGENCE EVENTS: Registered [length(event_types)] event types")

/// Start the event loop
/datum/resurgence_event_manager/proc/start()
	if(running)
		return

	running = TRUE
	last_check_time = world.time
	schedule_next_check()
	log_game("RESURGENCE EVENTS: Event manager started")

/// Stop the event loop
/datum/resurgence_event_manager/proc/stop()
	if(!running)
		return

	running = FALSE
	if(loop_timer_id)
		deltimer(loop_timer_id)
		loop_timer_id = null
	log_game("RESURGENCE EVENTS: Event manager stopped")

/// Schedule the next event check
/datum/resurgence_event_manager/proc/schedule_next_check()
	if(!running)
		return

	loop_timer_id = addtimer(CALLBACK(src, PROC_REF(check_for_event)), EVENT_CHECK_INTERVAL, TIMER_STOPPABLE)

/// Check if an event should trigger
/datum/resurgence_event_manager/proc/check_for_event()
	if(!running)
		return

	last_check_time = world.time

	// Calculate event chance
	var/chance = calculate_event_chance()

	if(prob(chance))
		trigger_random_event()

	// Schedule next check
	schedule_next_check()

/// Calculate the current event chance
/datum/resurgence_event_manager/proc/calculate_event_chance()
	var/chance = EVENT_BASE_CHANCE

	// Increase chance over time (max +20%)
	var/round_time = world.time - SSticker.round_start_time
	chance += min(20, round_time / (5 MINUTES))

	// Decrease chance if recent event
	if(last_event_time > 0)
		var/time_since_event = world.time - last_event_time
		if(time_since_event < EVENT_MIN_COOLDOWN)
			chance *= 0.3  // Much lower chance during cooldown

	return chance

/// Trigger a random event
/datum/resurgence_event_manager/proc/trigger_random_event()
	// Select category
	var/category = select_category()

	// Get eligible events for this category
	var/list/eligible = get_eligible_events(category)

	if(!length(eligible))
		return FALSE

	// Select an event based on weight
	var/datum/resurgence_event/event_type = pick_weighted_event(eligible)
	if(!event_type)
		return FALSE

	// Create and start the event
	var/datum/resurgence_event/event = new event_type()
	if(event.start_event())
		active_events += event
		last_event_time = world.time
		event_history += list(list(
			"name" = event.name,
			"category" = event.category,
			"time" = world.time,
			"duration" = event.duration
		))

		// Set up callback to remove from active when done
		if(event.duration > 0)
			addtimer(CALLBACK(src, PROC_REF(on_event_end), event), event.duration + 1)

		return TRUE

	qdel(event)
	return FALSE

/// Called when an event ends
/datum/resurgence_event_manager/proc/on_event_end(datum/resurgence_event/event)
	active_events -= event
	qdel(event)

/// Select a random category based on weights
/datum/resurgence_event_manager/proc/select_category()
	var/total = positive_weight + negative_weight + neutral_weight
	var/roll = rand(1, total)

	if(roll <= positive_weight)
		return EVENT_POSITIVE
	else if(roll <= positive_weight + negative_weight)
		return EVENT_NEGATIVE
	else
		return EVENT_NEUTRAL

/// Get list of eligible events for a category
/datum/resurgence_event_manager/proc/get_eligible_events(category)
	var/list/eligible = list()

	for(var/path in event_types)
		var/datum/resurgence_event/E = path
		if(initial(E.category) != category)
			continue

		// Create temporary instance to check can_start
		var/datum/resurgence_event/temp = new path()
		if(temp.can_start())
			eligible += path
		qdel(temp)

	return eligible

/// Pick an event from a list based on weights
/datum/resurgence_event_manager/proc/pick_weighted_event(list/events)
	if(!length(events))
		return null

	var/list/weighted = list()
	for(var/path in events)
		var/datum/resurgence_event/E = path
		weighted[path] = initial(E.weight)

	return pickweight(weighted)

/// Force trigger a specific event type (for testing/admin)
/datum/resurgence_event_manager/proc/force_event(event_type)
	if(!ispath(event_type, /datum/resurgence_event))
		return FALSE

	var/datum/resurgence_event/event = new event_type()
	if(event.start_event())
		active_events += event
		if(event.duration > 0)
			addtimer(CALLBACK(src, PROC_REF(on_event_end), event), event.duration + 1)
		return TRUE

	qdel(event)
	return FALSE

/// Get list of currently active event names
/datum/resurgence_event_manager/proc/get_active_event_names()
	var/list/names = list()
	for(var/datum/resurgence_event/E in active_events)
		names += E.name
	return names

/// Check if a specific event type is active
/datum/resurgence_event_manager/proc/is_event_active(event_type)
	for(var/datum/resurgence_event/E in active_events)
		if(istype(E, event_type))
			return TRUE
	return FALSE

/// Get list of active events with full data for UI display
/datum/resurgence_event_manager/proc/get_active_events_data()
	var/list/events_data = list()
	for(var/datum/resurgence_event/E in active_events)
		var/remaining = E.get_remaining_time()
		events_data += list(list(
			"name" = E.name,
			"desc" = E.desc,
			"category" = E.category,
			"remaining" = remaining,
			"remaining_text" = remaining > 0 ? "[round(remaining / (1 MINUTES), 0.1)] min" : "Permanent"
		))
	return events_data

/// Get list of all registered event types for debug menu
/datum/resurgence_event_manager/proc/get_all_event_types()
	var/list/types_data = list()
	for(var/path in event_types)
		var/datum/resurgence_event/E = path
		types_data += list(list(
			"path" = "[path]",
			"name" = initial(E.name),
			"category" = initial(E.category)
		))
	return types_data

/// Force end a specific active event by name
/datum/resurgence_event_manager/proc/end_event_by_name(event_name)
	for(var/datum/resurgence_event/E in active_events)
		if(E.name == event_name)
			E.end_event()
			active_events -= E
			qdel(E)
			return TRUE
	return FALSE
