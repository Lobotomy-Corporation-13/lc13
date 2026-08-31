/**
 * Resurgence Outpost - Base Event Datum
 *
 * Base class for all resurgence events.
 * Events modify global modifiers and have durations.
 */

/datum/resurgence_event
	/// Display name of the event
	var/name = "Unknown Event"
	/// Description shown to players
	var/desc = "Something is happening..."
	/// Category: EVENT_POSITIVE, EVENT_NEGATIVE, or EVENT_NEUTRAL
	var/category = EVENT_NEUTRAL
	/// Weight for random selection (higher = more likely)
	var/weight = 50
	/// Minimum round time before this event can trigger (deciseconds)
	var/min_round_time = 10 MINUTES
	/// Duration of the event (0 = instant)
	var/duration = 5 MINUTES
	/// Whether this event is currently active
	var/active = FALSE
	/// Timer ID for the end timer
	var/end_timer_id = null

/datum/resurgence_event/Destroy()
	if(active)
		end_event(silent = TRUE)
	return ..()

/// Check if this event can currently start
/datum/resurgence_event/proc/can_start()
	// Check minimum round time
	if(world.time - SSticker.round_start_time < min_round_time)
		return FALSE
	return TRUE

/// Start the event
/datum/resurgence_event/proc/start_event()
	if(active)
		return FALSE

	active = TRUE

	// Apply modifiers
	apply_modifiers()

	// Announce to players
	announce_resurgence_event(name, desc, category, duration)

	// Set end timer if not instant
	if(duration > 0)
		end_timer_id = addtimer(CALLBACK(src, PROC_REF(end_event)), duration, TIMER_STOPPABLE)

	// Log the event
	log_game("RESURGENCE EVENT: [name] started (duration: [duration / 10]s)")

	return TRUE

/// End the event
/datum/resurgence_event/proc/end_event(silent = FALSE)
	if(!active)
		return FALSE

	active = FALSE

	// Remove modifiers
	remove_modifiers()

	// Cancel timer if still running
	if(end_timer_id)
		deltimer(end_timer_id)
		end_timer_id = null

	// Announce end if not silent
	if(!silent && duration > 0)
		announce_event_end()

	// Log the event end
	log_game("RESURGENCE EVENT: [name] ended")

	return TRUE

/// Apply this event's modifiers to global variables
/datum/resurgence_event/proc/apply_modifiers()
	return

/// Remove this event's modifiers from global variables
/datum/resurgence_event/proc/remove_modifiers()
	return

/// Announce that the event has ended
/datum/resurgence_event/proc/announce_event_end()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(!istype(core))
			continue
		to_chat(H, span_notice("The [name] has ended."))

/// Get remaining duration in deciseconds
/datum/resurgence_event/proc/get_remaining_time()
	if(!active || !end_timer_id)
		return 0
	return timeleft(end_timer_id)
