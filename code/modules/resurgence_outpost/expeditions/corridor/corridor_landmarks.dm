// Expedition Corridor Landmarks
// Special trigger points for expedition mechanics

// ============================================
// START LANDMARK
// ============================================

/**
 * Start landmark - where players spawn/teleport to at the beginning of each leg
 */
/obj/effect/landmark/expedition_start
	name = "expedition start"
	desc = "The beginning of the path."
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x2"
	invisibility = INVISIBILITY_ABSTRACT
	/// Parent corridor manager reference
	var/datum/expedition_corridor_manager/manager

/obj/effect/landmark/expedition_start/Initialize(mapload)
	. = ..()
	// Register with global when corridor manager initializes
	if(GLOB.expedition_corridor)
		GLOB.expedition_corridor.start_landmark = src
		manager = GLOB.expedition_corridor

// ============================================
// EVENT LANDMARK
// ============================================

/**
 * Event landmark - triggers travel events and blocks passage until resolved
 * Placed at the halfway point of the corridor
 */
/obj/effect/landmark/expedition_event
	name = "event trigger"
	desc = "Something lies ahead..."
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x2"
	invisibility = INVISIBILITY_ABSTRACT
	/// Parent corridor manager reference
	var/datum/expedition_corridor_manager/manager
	/// Whether passage is currently blocked
	var/blocked = FALSE
	/// List of barrier objects blocking the path
	var/list/obj/structure/expedition_barrier/barriers = list()

/obj/effect/landmark/expedition_event/Initialize(mapload)
	. = ..()
	if(GLOB.expedition_corridor)
		GLOB.expedition_corridor.event_landmark = src
		manager = GLOB.expedition_corridor

/obj/effect/landmark/expedition_event/Crossed(atom/movable/AM)
	. = ..()
	if(!isliving(AM))
		return
	if(!manager)
		return
	if(manager.event_triggered)
		return

	var/mob/living/L = AM
	// Check if this mob is part of the active expedition
	if(!manager.expedition || !(L in manager.expedition.members))
		return

	trigger_event(L)

/**
 * Trigger a travel event
 */
/obj/effect/landmark/expedition_event/proc/trigger_event(mob/living/triggerer)
	if(!manager || manager.event_triggered)
		return

	manager.event_triggered = TRUE
	block_passage()

	// Notify the party
	for(var/mob/living/M in manager.expedition.members)
		to_chat(M, span_warning("Something blocks your path ahead! Approach the barrier to interact."))

	// The first barrier interaction will create and show the event popup

/**
 * Block passage past this point
 */
/obj/effect/landmark/expedition_event/proc/block_passage()
	blocked = TRUE

	// Spawn barrier walls across the corridor at Y+1
	var/barrier_y = src.y + 1
	var/datum/travel_event/shared_event = null

	for(var/bx in 2 to (EXPEDITION_CORRIDOR_WIDTH - 1))
		var/turf/T = locate(bx, barrier_y, src.z)
		if(T && !isclosedturf(T))
			var/obj/structure/expedition_barrier/B = new(T)
			B.parent_landmark = src
			barriers += B

			// First barrier creates the event, others share it
			if(!shared_event)
				B.create_event()
				shared_event = B.current_event
			else
				B.current_event = shared_event

/**
 * Unblock passage (call after event resolved)
 */
/obj/effect/landmark/expedition_event/proc/unblock()
	blocked = FALSE
	for(var/obj/structure/expedition_barrier/B in barriers)
		qdel(B)
	barriers = list()

/**
 * Resolve the current event and unblock passage
 */
/obj/effect/landmark/expedition_event/proc/resolve_event()
	if(!manager)
		return

	if(manager.event_completed)
		return

	manager.event_completed = TRUE
	unblock()

	// Event resolution message is handled by the travel_event datum

// ============================================
// END LANDMARK
// ============================================

/**
 * End landmark - triggers transition to next terrain when enough players arrive
 */
/obj/effect/landmark/expedition_end
	name = "path continues"
	desc = "The path continues beyond..."
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x2"
	invisibility = INVISIBILITY_ABSTRACT
	/// Parent corridor manager reference
	var/datum/expedition_corridor_manager/manager
	/// Players who have reached this point
	var/list/players_at_end = list()

/obj/effect/landmark/expedition_end/Initialize(mapload)
	. = ..()
	if(GLOB.expedition_corridor)
		GLOB.expedition_corridor.end_landmark = src
		manager = GLOB.expedition_corridor

/obj/effect/landmark/expedition_end/Crossed(atom/movable/AM)
	. = ..()
	if(!isliving(AM))
		return
	if(!manager)
		return

	var/mob/living/L = AM
	// Check if this mob is part of the active expedition
	if(!manager.expedition || !(L in manager.expedition.members))
		return

	// Add to players at end
	players_at_end |= L
	check_transition()

/**
 * Check if enough players have arrived to trigger transition
 */
/obj/effect/landmark/expedition_end/proc/check_transition()
	if(!manager || !manager.expedition)
		return

	// Count living members
	var/living_members = 0
	for(var/mob/living/M in manager.expedition.members)
		if(M.stat != DEAD)
			living_members++

	if(living_members <= 0)
		return

	// Calculate needed players
	var/needed = max(1, round(living_members * EXPEDITION_TRANSITION_RATIO))

	// Count players at end who are still alive
	var/at_end = 0
	for(var/mob/living/M in players_at_end)
		if(M.stat != DEAD)
			at_end++

	if(at_end >= needed)
		manager.begin_transition()

/**
 * Reset for next leg
 */
/obj/effect/landmark/expedition_end/proc/reset()
	players_at_end = list()

// ============================================
// EXPEDITION BARRIER
// ============================================

/**
 * Temporary barrier that blocks passage during events
 * When bumped or clicked, opens an HTML popup for event interaction
 */
/obj/structure/expedition_barrier
	name = "impassable obstacle"
	desc = "Something blocks your way. Deal with the situation before proceeding."
	icon = 'icons/obj/flora/rocks.dmi'
	icon_state = "dvoid"
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE | FIRE_PROOF | ACID_PROOF
	/// Reference to the parent landmark
	var/obj/effect/landmark/expedition_event/parent_landmark
	/// The travel event datum for this barrier
	var/datum/travel_event/current_event
	/// Whether this barrier has been resolved
	var/resolved = FALSE

/obj/structure/expedition_barrier/Initialize(mapload)
	. = ..()
	// Make it invisible but still dense
	invisibility = INVISIBILITY_ABSTRACT
	alpha = 0

/obj/structure/expedition_barrier/Destroy()
	if(current_event)
		qdel(current_event)
		current_event = null
	parent_landmark = null
	return ..()

/obj/structure/expedition_barrier/Bumped(atom/movable/AM)
	. = ..()
	if(!isliving(AM))
		return
	if(resolved)
		return

	var/mob/living/L = AM
	interact_with_event(L)

/obj/structure/expedition_barrier/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(resolved)
		return
	interact_with_event(user)

/**
 * Handle interaction - create event if needed and show popup
 */
/obj/structure/expedition_barrier/proc/interact_with_event(mob/living/user)
	// Create event if we don't have one
	if(!current_event)
		create_event()

	// Show the popup
	if(current_event)
		current_event.show_popup(user)
	else
		to_chat(user, span_warning("You cannot pass until the obstacle ahead is dealt with!"))

/**
 * Create a travel event for this barrier
 */
/obj/structure/expedition_barrier/proc/create_event()
	if(current_event)
		return

	// Get current terrain from corridor manager
	var/terrain = TERRAIN_PLAINS
	if(parent_landmark?.manager)
		terrain = parent_landmark.manager.current_terrain

	// Pick an appropriate event
	var/event_type = pick_travel_event(terrain)
	if(event_type)
		current_event = new event_type(src)

/**
 * Resolve this barrier (called by the event when completed)
 */
/obj/structure/expedition_barrier/proc/resolve()
	if(resolved)
		return
	resolved = TRUE

	// Tell the parent landmark to unblock all barriers
	if(parent_landmark)
		parent_landmark.resolve_event()
