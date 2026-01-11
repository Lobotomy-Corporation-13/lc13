/**
 * Resurgence Outpost - Raider Component
 *
 * Component that can be attached to any hostile mob to give it raider behavior.
 * Handles navigation, stuck detection, objective tracking, and raid coordination.
 * Uses a commander-follower pattern: an invisible commander follows A* path, raiders follow commander.
 */

// ==================== RAID COMMANDER ====================

/**
 * Invisible effect that leads raiders along a pre-calculated A* path.
 * Raiders follow this commander instead of pathfinding individually.
 */
/obj/effect/raid_commander
	name = "raid commander"
	desc = "An incorporeal force leading raiders to their target."
	icon = 'ModularLobotomy/_Lobotomyicons/tegu_effects.dmi'
	icon_state = "target_field"
	invisibility = INVISIBILITY_OBSERVER  // Only visible to ghosts/admins
	movement_type = PHASING | FLYING
	anchored = FALSE
	density = FALSE

	/// The pre-calculated path to follow
	var/list/current_path = list()
	/// Timer for movement
	var/move_timer
	/// How many times we've failed to move
	var/move_failures = 0
	/// Maximum move failures before giving up
	var/max_failures = 10
	/// Movement delay in deciseconds (faster than wave_commander for responsive raiding)
	var/move_delay = 3
	/// Callback when we reach destination
	var/datum/callback/on_arrival
	/// Callback when we fail to reach destination
	var/datum/callback/on_failure
	/// Reference to the raider component that owns this commander
	var/datum/component/raider/owner_component
	/// Whether we're waiting for a door to be opened
	var/waiting_for_door = FALSE
	/// The door we're waiting on
	var/obj/structure/mineral_door/door_to_open

/obj/effect/raid_commander/Initialize(mapload, list/path, datum/callback/_on_arrival, datum/callback/_on_failure, datum/component/raider/_owner)
	. = ..()
	if(path?.len)
		current_path = path.Copy()
	on_arrival = _on_arrival
	on_failure = _on_failure
	owner_component = _owner

/obj/effect/raid_commander/Destroy()
	if(move_timer)
		deltimer(move_timer)
	on_arrival = null
	on_failure = null
	owner_component = null
	door_to_open = null
	current_path.Cut()
	return ..()

/// Start following the path
/obj/effect/raid_commander/proc/start_path()
	if(!current_path?.len)
		log_admin("RAID DEBUG: Commander has no path, failing")
		fail()
		return FALSE
	log_admin("RAID DEBUG: Commander starting path with [current_path.len] steps from [AREACOORD(src)]")
	move_timer = addtimer(CALLBACK(src, PROC_REF(step_path)), move_delay, TIMER_STOPPABLE)
	return TRUE

/// Take one step along the path
/obj/effect/raid_commander/proc/step_path()
	if(!current_path?.len)
		arrive()
		return

	// If waiting for door, don't move
	if(waiting_for_door)
		return

	var/turf/next_step = current_path[1]
	if(!next_step)
		current_path.Cut(1, 2)
		continue_path()
		return

	// Check for closed mineral door at next step
	var/obj/structure/mineral_door/door = locate() in next_step
	if(door && !door.door_opened)
		// Found closed door - wait for raider to open it
		waiting_for_door = TRUE
		door_to_open = door
		log_admin("RAID DEBUG: Commander found closed door at [AREACOORD(next_step)] - waiting for raider to open")
		if(owner_component)
			owner_component.open_door_for_commander(door)
		return // Don't schedule next step - door_opened_callback will resume

	// Try to move to next step
	forceMove(next_step)

	if(get_turf(src) == next_step)
		// Success - remove this step from path
		current_path.Cut(1, 2)
		move_failures = 0
	else
		// Failed to move
		move_failures++
		if(move_failures >= max_failures)
			log_admin("RAID DEBUG: Commander failed to move [max_failures] times, failing")
			fail()
			return

	continue_path()

/// Schedule next path step
/obj/effect/raid_commander/proc/continue_path()
	if(current_path?.len)
		move_timer = addtimer(CALLBACK(src, PROC_REF(step_path)), move_delay, TIMER_STOPPABLE)
	else
		arrive()

/// Called when we reach the destination
/obj/effect/raid_commander/proc/arrive()
	log_admin("RAID DEBUG: Commander arrived at destination [AREACOORD(src)]")
	if(on_arrival)
		on_arrival.Invoke()
	// Wait 1 second before deleting to allow the raider to catch up
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(qdel), src), 1 SECONDS)

/// Called when we fail to reach destination
/obj/effect/raid_commander/proc/fail()
	log_admin("RAID DEBUG: Commander failed to reach destination")
	if(on_failure)
		on_failure.Invoke()
	qdel(src)

/// Called by raider component when a door has been opened
/obj/effect/raid_commander/proc/door_opened_callback()
	if(!waiting_for_door)
		return

	log_admin("RAID DEBUG: Commander notified that door is now open - resuming path")
	waiting_for_door = FALSE
	door_to_open = null

	// Resume path progression
	continue_path()

// ==================== RAIDER COMPONENT ====================

/**
 * Base raider component - makes any hostile mob into a raider.
 */
/datum/component/raider
	/// Reference to the raid this raider belongs to
	var/datum/resurgence_raid/raid

	/// Current raid objective (turf to navigate to)
	var/atom/current_objective

	/// Reference to the target room area
	var/datum/weakref/target_room_ref

	/// Items this raider has stolen (for pillage raids)
	var/list/stolen_items = list()

	/// Maximum items this raider can carry
	var/max_stolen = 3

	/// Whether this raider should retreat when inventory full
	var/retreat_when_full = FALSE

	/// Spawn point to retreat to
	var/obj/effect/landmark/raid_spawn/retreat_point

	/// Stuck counter for obstacle detection
	var/stuck_counter = 0

	/// Last position for stuck detection
	var/turf/last_position

	/// Timer for stuck checking
	var/stuck_check_timer

	/// Timer for objective navigation refresh
	var/nav_refresh_timer

	/// Whether the raider is currently retreating
	var/retreating = FALSE

	/// Whether the raider has successfully escaped (don't call on_raider_removed)
	var/escaped = FALSE

	/// Whether the raider has reached its initial objective
	var/reached_objective = FALSE

	/// List of rooms this raider has already visited/cleared
	var/list/visited_rooms = list()

	/// Time spent in current room (for room switching)
	var/room_clear_time = 0

	/// How long to spend in a room before moving to next (in deciseconds)
	var/room_clear_duration = 1 MINUTES

	/// Timer for room clearing check
	var/room_clear_timer

	/// Current door being attacked (mineral doors, not machinery)
	var/obj/structure/mineral_door/target_door

	/// Current commander leading this raider (for A* pathfinding)
	var/obj/effect/raid_commander/current_commander

	/// Maximum pathfinding distance for A*
	var/max_path_distance = 400

	/// Whether the raider is waiting at spawn (for delayed raids)
	var/waiting_at_spawn = FALSE

	/// List of crates to loot in the current room
	var/list/room_crates = list()

	/// Whether we're currently looting crates in a room
	var/looting_crates = FALSE

	/// Current crate we're navigating to
	var/obj/structure/closet/current_target_crate

/datum/component/raider/Initialize(datum/resurgence_raid/_raid, atom/_objective, obj/effect/landmark/raid_spawn/_retreat_point, start_waiting = FALSE)
	if(!ishostile(parent))
		log_admin("RAID DEBUG: Raider component rejected - parent [parent?.type] is not hostile")
		return COMPONENT_INCOMPATIBLE

	raid = _raid
	current_objective = _objective
	retreat_point = _retreat_point

	var/mob/living/simple_animal/hostile/H = parent

	// Ensure raider can smash structures (minimum)
	if(H.environment_smash < ENVIRONMENT_SMASH_STRUCTURES)
		H.environment_smash = ENVIRONMENT_SMASH_STRUCTURES

	// Change faction to insurgence raiders
	H.faction = list("insurgence_raiders")

	// Register signals
	RegisterSignal(parent, COMSIG_LIVING_DEATH, PROC_REF(on_death))
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))

	// Start stuck detection timer (check every 2 seconds)
	stuck_check_timer = addtimer(CALLBACK(src, PROC_REF(check_stuck)), 2 SECONDS, TIMER_LOOP | TIMER_STOPPABLE)

	// Start navigation refresh timer (refresh path every 3 seconds to keep raiders moving)
	nav_refresh_timer = addtimer(CALLBACK(src, PROC_REF(refresh_navigation)), 3 SECONDS, TIMER_LOOP | TIMER_STOPPABLE)

	// Start room clear timer (check every 5 seconds if we should switch rooms)
	room_clear_timer = addtimer(CALLBACK(src, PROC_REF(check_room_clear)), 5 SECONDS, TIMER_LOOP | TIMER_STOPPABLE)

	waiting_at_spawn = start_waiting
	log_admin("RAID DEBUG: Raider component initialized on [H.type] at [AREACOORD(H)], objective: [current_objective ? "[current_objective] at [AREACOORD(current_objective)]" : "NONE"], waiting: [waiting_at_spawn]")

	// Start navigation immediately (calculates A* path) unless waiting
	if(!waiting_at_spawn)
		navigate_to_objective()

/datum/component/raider/Destroy()
	if(stuck_check_timer)
		deltimer(stuck_check_timer)
	if(nav_refresh_timer)
		deltimer(nav_refresh_timer)
	if(room_clear_timer)
		deltimer(room_clear_timer)
	// Clean up commander
	if(current_commander && !QDELETED(current_commander))
		qdel(current_commander)
	current_commander = null
	// Only call on_raider_removed if we didn't already escape
	if(raid && !escaped)
		raid.on_raider_removed(parent)
	target_door = null
	current_target_crate = null
	room_crates.Cut()

	// Drop stolen items (only if we didn't escape - escaped raiders take their loot)
	if(stolen_items.len && !escaped)
		var/turf/drop_loc = get_turf(parent)
		for(var/obj/item/I in stolen_items)
			I.forceMove(drop_loc)
		stolen_items.Cut()

	return ..()

/**
 * Called when the raider dies.
 */
/datum/component/raider/proc/on_death(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/**
 * Called when the raider moves.
 */
/datum/component/raider/proc/on_moved(datum/source, atom/old_loc, dir, forced)
	SIGNAL_HANDLER
	stuck_counter = 0

	// Check if we've reached our retreat point (teleport away within 3 tiles)
	if(retreating && retreat_point)
		var/turf/retreat_turf = get_turf(retreat_point)
		var/turf/our_turf = get_turf(parent)
		if(our_turf == retreat_turf || get_dist(our_turf, retreat_turf) <= 3)
			INVOKE_ASYNC(src, PROC_REF(on_reached_retreat_point))
			return

	// Check if we've reached a crate we're looting
	if(looting_crates && current_target_crate && !QDELETED(current_target_crate))
		var/turf/crate_turf = get_turf(current_target_crate)
		var/turf/our_turf = get_turf(parent)
		if(our_turf == crate_turf || get_dist(our_turf, crate_turf) <= 1)
			INVOKE_ASYNC(src, PROC_REF(on_reached_crate))
			return

	// Check if we've reached our objective
	if(current_objective && !reached_objective)
		var/turf/obj_turf = get_turf(current_objective)
		var/turf/our_turf = get_turf(parent)
		if(our_turf == obj_turf || get_dist(our_turf, obj_turf) <= 1)
			// Use INVOKE_ASYNC since on_reached_objective can sleep via navigate_to_objective
			INVOKE_ASYNC(src, PROC_REF(on_reached_objective))

/**
 * Check if the raider is stuck and needs to smash through obstacles.
 */
/datum/component/raider/proc/check_stuck()
	var/mob/living/simple_animal/hostile/H = parent
	if(!H || H.stat == DEAD)
		return

	// Don't check stuck while waiting at spawn
	if(waiting_at_spawn)
		return

	var/turf/current = get_turf(H)
	if(current == last_position)
		stuck_counter++
		if(stuck_counter >= 2) // Stuck for 4+ seconds
			// First, check for closed doors nearby
			var/obj/structure/mineral_door/door = find_blocking_door()
			if(door)
				log_admin("RAID DEBUG: [H.type] found blocking door at [AREACOORD(door)] - opening it")
				open_door(door)
				stuck_counter = 0
				return

			// Try to step around obstacles
			if(stuck_counter >= 3)
				log_admin("RAID DEBUG: [H.type] stuck at [AREACOORD(H)] for [stuck_counter * 2]+ seconds - trying to step around")
				try_step_around_obstacle()
				stuck_counter = 0

			// After many attempts, try smashing
			if(stuck_counter >= 5)
				log_admin("RAID DEBUG: [H.type] still stuck - attempting to smash obstacles")
				H.DestroyPathToTarget()
				stuck_counter = 0
	else
		stuck_counter = 0

	last_position = current

/**
 * Try to step around an obstacle by moving in a perpendicular direction.
 */
/datum/component/raider/proc/try_step_around_obstacle()
	var/mob/living/simple_animal/hostile/H = parent
	if(!H || !current_objective)
		return

	var/turf/target_turf = get_turf(current_objective)
	if(!target_turf)
		return

	// Get direction to target
	var/dir_to_target = get_dir(H, target_turf)

	// Try perpendicular directions first, then diagonal
	var/list/try_dirs = list()

	// Add perpendicular directions based on primary direction
	if(dir_to_target & NORTH || dir_to_target & SOUTH)
		try_dirs += list(EAST, WEST)
	if(dir_to_target & EAST || dir_to_target & WEST)
		try_dirs += list(NORTH, SOUTH)

	// Add diagonal directions
	try_dirs += list(NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST)

	// Shuffle to add randomness
	try_dirs = shuffle(try_dirs)

	// Try each direction
	for(var/try_dir in try_dirs)
		var/turf/try_turf = get_step(H, try_dir)
		if(!try_turf || try_turf.density)
			continue
		// Check for dense structures/objects
		var/blocked = FALSE
		for(var/obj/O in try_turf)
			if(O.density)
				blocked = TRUE
				break
		if(blocked)
			continue
		if(H.Move(try_turf))
			log_admin("RAID DEBUG: [H.type] stepped [dir2text(try_dir)] to avoid obstacle")
			// Re-navigate after stepping
			addtimer(CALLBACK(src, PROC_REF(navigate_to_objective)), 0.5 SECONDS)
			return

	log_admin("RAID DEBUG: [H.type] couldn't find a way around obstacle")

/**
 * Find a closed mineral door blocking the raider's path.
 */
/datum/component/raider/proc/find_blocking_door()
	var/mob/living/simple_animal/hostile/H = parent
	if(!H)
		return null

	// Check adjacent tiles for closed doors
	for(var/dir in GLOB.cardinals)
		var/turf/T = get_step(H, dir)
		if(!T)
			continue
		for(var/obj/structure/mineral_door/door in T)
			if(!door.door_opened)
				return door

	// Also check the turf we're trying to reach
	if(current_objective)
		var/turf/obj_turf = get_turf(current_objective)
		if(obj_turf)
			// Check turfs between us and objective
			var/turf/next_step = get_step_towards(H, obj_turf)
			if(next_step)
				for(var/obj/structure/mineral_door/door in next_step)
					if(!door.door_opened)
						return door

	return null

/// How long doors stay jammed open (in deciseconds)
#define DOOR_JAM_DURATION 15 SECONDS

/**
 * Open a door and jam it open temporarily.
 */
/datum/component/raider/proc/open_door(obj/structure/mineral_door/door)
	var/mob/living/simple_animal/hostile/H = parent
	if(!H || !door || QDELETED(door))
		return

	// If door is already open, just navigate through
	if(door.door_opened)
		target_door = null
		navigate_to_objective()
		return

	// If door is currently switching states, wait
	if(door.isSwitchingStates)
		return

	target_door = door

	// Face the door
	H.face_atom(door)

	// Stop current movement to open the door
	walk(H, 0)

	log_admin("RAID DEBUG: [H.type] opening door [door] at [AREACOORD(door)]")
	H.visible_message(span_warning("[H] forces open [door]!"))

	// Use the door's jam function to open and keep it open
	door.jam(DOOR_JAM_DURATION)

	// Resume navigation after a short delay for the door to finish opening
	addtimer(CALLBACK(src, PROC_REF(resume_after_door)), 1.5 SECONDS)

/**
 * Open a door for the commander and notify it when done.
 * Called by the raid commander when it encounters a closed door in its path.
 */
/datum/component/raider/proc/open_door_for_commander(obj/structure/mineral_door/door)
	var/mob/living/simple_animal/hostile/H = parent
	if(!H || !door || QDELETED(door))
		// Still notify commander to continue
		if(current_commander)
			current_commander.door_opened_callback()
		return

	// If door is already open, just notify commander
	if(door.door_opened)
		if(current_commander)
			current_commander.door_opened_callback()
		return

	// If door is currently switching states, wait for it
	if(door.isSwitchingStates)
		addtimer(CALLBACK(src, PROC_REF(open_door_for_commander), door), 0.5 SECONDS)
		return

	target_door = door

	// Face the door
	H.face_atom(door)

	// Stop current movement to open the door
	walk(H, 0)

	log_admin("RAID DEBUG: [H.type] opening door for commander at [AREACOORD(door)]")
	H.visible_message(span_warning("[H] forces open [door]!"))

	// Use the door's jam function to open and keep it open
	door.jam(DOOR_JAM_DURATION)

	// Notify commander after a short delay for the door to finish opening
	addtimer(CALLBACK(src, PROC_REF(notify_commander_door_opened)), 1.5 SECONDS)

/**
 * Notify the commander that we finished opening a door.
 */
/datum/component/raider/proc/notify_commander_door_opened()
	target_door = null
	if(current_commander && !QDELETED(current_commander))
		current_commander.door_opened_callback()

/**
 * Resume navigation after opening a door.
 */
/datum/component/raider/proc/resume_after_door()
	target_door = null

	// If we were navigating to a room entry point (door), we've now opened the door
	// So we should navigate to a point INSIDE the room
	var/area/resurgence_outpost/room/target_room = target_room_ref?.resolve()
	if(target_room)
		var/turf/inside_turf = get_random_turf_in_room(target_room)
		if(inside_turf)
			current_objective = inside_turf
			reached_objective = FALSE
			log_admin("RAID DEBUG: [parent?.type] door opened, now navigating inside room to [AREACOORD(inside_turf)]")

	navigate_to_objective()

#undef DOOR_JAM_DURATION

/**
 * Refresh navigation to current objective.
 * Only re-navigates if we're stuck or haven't started moving.
 */
/datum/component/raider/proc/refresh_navigation()
	var/mob/living/simple_animal/hostile/H = parent
	if(!H || H.stat == DEAD)
		return

	// Don't navigate while waiting at spawn
	if(waiting_at_spawn)
		return

	// Don't interrupt combat - let the mob's AI handle fighting
	if(H.target && isliving(H.target))
		var/mob/living/T = H.target
		if(T.stat != DEAD && get_dist(H, T) <= H.vision_range)
			return // Still fighting, don't redirect

	// If we have a door to open, keep trying to open it
	if(target_door && !QDELETED(target_door) && !target_door.door_opened)
		if(get_dist(H, target_door) <= 1)
			open_door(target_door)
			return
		else
			// Door is far away, clear it and navigate
			target_door = null

	// Only re-navigate if we seem stuck (same position as last check)
	// This prevents constant walk_to() calls which can reset movement
	var/turf/current = get_turf(H)
	if(current_objective && !retreating)
		if(current == last_position && stuck_counter >= 1)
			// We're stuck, try navigating again
			navigate_to_objective()
		else if(!last_position)
			// First navigation
			navigate_to_objective()

/**
 * Check if we've been in the current room long enough and should switch.
 */
/datum/component/raider/proc/check_room_clear()
	var/mob/living/simple_animal/hostile/H = parent
	if(!H || H.stat == DEAD || retreating || waiting_at_spawn)
		return

	// Check if we're in a room
	var/area/resurgence_outpost/room/current_room = get_area(H)
	if(!istype(current_room))
		room_clear_time = 0
		return

	var/area/resurgence_outpost/room/target_room = target_room_ref?.resolve()

	// If we're in our target room, increment time
	if(current_room == target_room)
		room_clear_time += 5 SECONDS

		// Check if we've spent enough time in this room
		if(room_clear_time >= room_clear_duration)
			log_admin("RAID DEBUG: [H.type] finished clearing room [current_room.name] after [room_clear_time / 10] seconds")
			// Mark room as visited
			visited_rooms += current_room
			// Switch to a new room
			switch_to_new_room()
	else
		// We're in a different room (maybe passing through)
		room_clear_time = 0

/**
 * Switch to targeting a new room that hasn't been visited.
 */
/datum/component/raider/proc/switch_to_new_room()
	var/mob/living/simple_animal/hostile/H = parent
	if(!H || H.stat == DEAD)
		return

	// Stop all current movement and looting before switching
	walk(H, 0)
	if(current_commander && !QDELETED(current_commander))
		qdel(current_commander)
		current_commander = null

	// Clear looting state
	looting_crates = FALSE
	current_target_crate = null
	room_crates.Cut()
	current_objective = null

	// Get all accessible rooms
	var/can_smash_walls = (H.environment_smash & ENVIRONMENT_SMASH_WALLS)
	var/list/all_rooms = get_resurgence_room_areas(FALSE, can_smash_walls) // FALSE = don't require open access, raiders can smash doors

	// Filter out visited rooms
	var/list/unvisited_rooms = list()
	for(var/area/resurgence_outpost/room/R in all_rooms)
		if(!(R in visited_rooms))
			unvisited_rooms += R

	if(!unvisited_rooms.len)
		log_admin("RAID DEBUG: [H.type] has visited all [visited_rooms.len] rooms - staying in current area")
		// All rooms visited - just stay and look for targets
		H.FindTarget()
		return

	// Pick a random unvisited room
	var/area/resurgence_outpost/room/new_room = pick(unvisited_rooms)
	log_admin("RAID DEBUG: [H.type] switching to new room: [new_room.name] ([unvisited_rooms.len] unvisited rooms remaining)")

	// Reset room clear time
	room_clear_time = 0

	// Assign the new room
	assign_room_target(new_room)

// ==================== CRATE LOOTING ====================

/**
 * Scan the current room for crates to loot.
 * Returns TRUE if crates were found and looting started.
 */
/datum/component/raider/proc/scan_room_for_crates()
	var/mob/living/simple_animal/hostile/H = parent
	if(!H || H.stat == DEAD)
		return FALSE

	// Check if this raider can loot crates
	if(!istype(H, /mob/living/simple_animal/hostile/clan/raider))
		return FALSE
	var/mob/living/simple_animal/hostile/clan/raider/R = H
	if(!R.crate_looter)
		return FALSE

	// Get current room
	var/area/resurgence_outpost/room/current_room = get_area(H)
	if(!istype(current_room))
		return FALSE

	// Clear previous crate list
	room_crates.Cut()
	current_target_crate = null

	// Track if there's any loot worth staying for
	var/has_loot_remaining = FALSE

	// Find all crates/closets in the room
	for(var/obj/structure/closet/crate in current_room)
		if(QDELETED(crate))
			continue
		// Check global looted list - another raider may have already claimed this crate
		if(crate in GLOB.raid_looted_crates)
			continue

		if(crate.opened)
			// Crate is open - check if there's loot on the same turf
			var/turf/crate_turf = get_turf(crate)
			for(var/obj/item/I in crate_turf)
				if(!I.anchored)
					has_loot_remaining = TRUE
					break
			continue // Don't add open crates to the list to navigate to

		// Closed crate - add to list
		room_crates += crate
		has_loot_remaining = TRUE

	// If no closed crates and no loot remaining, room is cleared
	if(!room_crates.len && !has_loot_remaining)
		log_admin("RAID DEBUG: [H.type] found no crates or loot in room [current_room.name] - room cleared")
		// Mark room as visited and switch to new room
		visited_rooms += current_room
		switch_to_new_room()
		return FALSE

	if(!room_crates.len)
		log_admin("RAID DEBUG: [H.type] found no closed crates in room [current_room.name], but loot remains on ground")
		return FALSE

	log_admin("RAID DEBUG: [H.type] found [room_crates.len] crates to loot in room [current_room.name]")
	looting_crates = TRUE

	// Start looting the first crate
	loot_next_crate()
	return TRUE

/**
 * Navigate to and loot the next crate in the room.
 */
/datum/component/raider/proc/loot_next_crate()
	var/mob/living/simple_animal/hostile/H = parent
	if(!H || H.stat == DEAD || retreating)
		looting_crates = FALSE
		return

	// Remove any invalid or already-looted crates from the list
	for(var/obj/structure/closet/crate in room_crates)
		if(QDELETED(crate) || crate.opened || (crate in GLOB.raid_looted_crates))
			room_crates -= crate

	if(!room_crates.len)
		// All crates looted - stop walking and find targets
		log_admin("RAID DEBUG: [H.type] finished looting all crates in room")
		looting_crates = FALSE
		current_target_crate = null
		current_objective = null
		// Stop any ongoing walk_to
		walk(H, 0)
		// Clean up commander
		if(current_commander && !QDELETED(current_commander))
			qdel(current_commander)
			current_commander = null

		// Check if there's any loot remaining in the room
		var/area/resurgence_outpost/room/current_room = get_area(H)
		if(istype(current_room))
			var/has_loot = FALSE
			for(var/obj/structure/closet/crate in current_room)
				if(QDELETED(crate) || (crate in GLOB.raid_looted_crates))
					continue
				if(crate.opened)
					// Check for items on crate's turf
					var/turf/crate_turf = get_turf(crate)
					for(var/obj/item/I in crate_turf)
						if(!I.anchored)
							has_loot = TRUE
							break
				else
					has_loot = TRUE // Closed crate still has potential loot
				if(has_loot)
					break

			if(!has_loot)
				log_admin("RAID DEBUG: [H.type] no loot remaining in room [current_room.name] - switching rooms")
				visited_rooms += current_room
				switch_to_new_room()
				return

		// Continue with normal room clearing (look for targets)
		H.FindTarget()
		return

	// Pick the closest crate
	var/obj/structure/closet/closest_crate = null
	var/closest_dist = INFINITY
	for(var/obj/structure/closet/crate in room_crates)
		var/dist = get_dist(H, crate)
		if(dist < closest_dist)
			closest_dist = dist
			closest_crate = crate

	if(!closest_crate)
		looting_crates = FALSE
		current_objective = null
		walk(H, 0)
		return

	current_target_crate = closest_crate
	room_crates -= closest_crate

	// Mark the crate as claimed in the global list to prevent other raiders targeting it
	GLOB.raid_looted_crates += closest_crate

	log_admin("RAID DEBUG: [H.type] targeting crate at [AREACOORD(closest_crate)], [room_crates.len] crates remaining")

	// Navigate to the crate
	current_objective = get_turf(closest_crate)
	reached_objective = FALSE
	navigate_to_objective()

/**
 * Called when raider reaches a crate they're trying to loot.
 */
/datum/component/raider/proc/on_reached_crate()
	var/mob/living/simple_animal/hostile/H = parent
	if(!H || H.stat == DEAD)
		return

	if(!current_target_crate || QDELETED(current_target_crate))
		// Crate is gone, move to next
		loot_next_crate()
		return

	// Check if crate was already opened (by Move() or another raider)
	if(current_target_crate.opened)
		log_admin("RAID DEBUG: [H.type] reached crate at [AREACOORD(current_target_crate)] - already opened, moving on")
		current_target_crate = null
		current_objective = null
		// Stop walking to this spot
		walk(H, 0)
		// Move to next crate immediately
		loot_next_crate()
		return

	log_admin("RAID DEBUG: [H.type] reached crate at [AREACOORD(current_target_crate)]")

	// Open the crate
	if(istype(H, /mob/living/simple_animal/hostile/clan/raider))
		var/mob/living/simple_animal/hostile/clan/raider/R = H
		if(current_target_crate.locked || current_target_crate.welded)
			if(R.crate_breaker)
				R.attack_crate(current_target_crate)
				// Wait a bit then check again
				addtimer(CALLBACK(src, PROC_REF(check_crate_opened)), 2 SECONDS)
				return
			else
				// Can't open locked crate, skip it
				log_admin("RAID DEBUG: [H.type] can't open locked crate - skipping")
		else
			R.open_crate(current_target_crate)

	current_target_crate = null
	current_objective = null

	// Stop walking to this spot
	walk(H, 0)

	// Short delay before moving to next crate (for stealing items)
	addtimer(CALLBACK(src, PROC_REF(loot_next_crate)), 1 SECONDS)

/**
 * Check if a crate was opened after attacking it.
 */
/datum/component/raider/proc/check_crate_opened()
	var/mob/living/simple_animal/hostile/H = parent
	if(!H || H.stat == DEAD)
		return

	if(!current_target_crate || QDELETED(current_target_crate))
		loot_next_crate()
		return

	// If crate is now open or destroyed, move on
	if(current_target_crate.opened)
		// Steal items from it
		if(istype(H, /mob/living/simple_animal/hostile/clan/raider))
			var/mob/living/simple_animal/hostile/clan/raider/R = H
			R.try_steal_items()
		current_target_crate = null
		current_objective = null
		walk(H, 0)
		addtimer(CALLBACK(src, PROC_REF(loot_next_crate)), 1 SECONDS)
	else
		// Still locked, keep attacking
		if(istype(H, /mob/living/simple_animal/hostile/clan/raider))
			var/mob/living/simple_animal/hostile/clan/raider/R = H
			if(R.crate_breaker)
				R.attack_crate(current_target_crate)
				addtimer(CALLBACK(src, PROC_REF(check_crate_opened)), 2 SECONDS)
				return
		// Give up on this crate
		current_target_crate = null
		current_objective = null
		walk(H, 0)
		loot_next_crate()

/**
 * Navigate to the current objective using commander-follower A* pathfinding.
 * Creates an invisible commander that follows a pre-calculated A* path,
 * and the raider follows the commander using walk_to().
 */
/datum/component/raider/proc/navigate_to_objective()
	var/mob/living/simple_animal/hostile/H = parent
	if(!H || H.stat == DEAD)
		log_admin("RAID DEBUG: navigate_to_objective() aborted - mob dead or missing")
		return
	if(!current_objective)
		log_admin("RAID DEBUG: navigate_to_objective() aborted - [H.type] has no objective")
		return

	var/turf/target_turf = get_turf(current_objective)
	if(!target_turf)
		log_admin("RAID DEBUG: navigate_to_objective() aborted - could not get turf for objective [current_objective]")
		return

	// IMPORTANT: Set approaching_target to FALSE to prevent LoseTarget() from
	// calling walk(src, 0) which would cancel our movement.
	// The hostile mob AI calls LoseTarget() when it can't find an attackable target,
	// but only if approaching_target is TRUE.
	H.approaching_target = FALSE

	// Also set stop_automated_movement to 0 so the mob doesn't override our walk
	H.stop_automated_movement = FALSE

	var/dist = get_dist(H, target_turf)
	log_admin("RAID DEBUG: [H.type] at [AREACOORD(H)] navigating to [AREACOORD(target_turf)], distance: [dist]")

	// Stop any existing walk_to before starting new navigation
	walk(H, 0)

	// Clean up any existing commander
	if(current_commander && !QDELETED(current_commander))
		qdel(current_commander)
		current_commander = null

	// Calculate A* path to objective using raider-aware pathfinding
	// This allows pathing through doors and smashable obstacles
	var/list/path = get_path_to(
		H,
		target_turf,
		/turf/proc/Distance_cardinal,
		0,
		max_path_distance,
		1, // mintargetdist - get within 1 tile
		/turf/proc/reachableTurftestRaider, // Use raider-aware pathfinding
		null, // no ID
		null, // no exclude
		TRUE  // simulated_only
	)

	if(!path?.len)
		log_admin("RAID DEBUG: [H.type] A* pathfinding failed (no path found) - falling back to direct walk_to")
		// Fallback to direct walk_to if A* fails
		walk_to(H, target_turf, 1, H.move_to_delay)
		return

	log_admin("RAID DEBUG: [H.type] A* path calculated with [path.len] steps from [AREACOORD(H)] to [AREACOORD(target_turf)]")

	// Create commander at raider's position with arrival/failure callbacks
	// Pass src as owner so commander can call us back when it encounters doors
	var/datum/callback/arrival_cb = CALLBACK(src, PROC_REF(on_commander_arrived))
	var/datum/callback/failure_cb = CALLBACK(src, PROC_REF(on_commander_failed))
	current_commander = new /obj/effect/raid_commander(get_turf(H), path, arrival_cb, failure_cb, src)

	// Have the raider follow the commander
	walk_to(H, current_commander, rand(0, 2), H.move_to_delay)

	// Start the commander moving along the path
	current_commander.start_path()

/**
 * Called when the commander reaches its destination.
 */
/datum/component/raider/proc/on_commander_arrived()
	log_admin("RAID DEBUG: [parent?.type] commander arrived at destination")
	current_commander = null
	// The on_moved signal will handle detecting when we've reached the objective

/**
 * Called when the commander fails to reach its destination.
 */
/datum/component/raider/proc/on_commander_failed()
	log_admin("RAID DEBUG: [parent?.type] commander failed to reach destination")
	current_commander = null

	// Try direct walk_to as fallback
	var/mob/living/simple_animal/hostile/H = parent
	if(H && H.stat != DEAD && current_objective)
		var/turf/target_turf = get_turf(current_objective)
		if(target_turf)
			log_admin("RAID DEBUG: [H.type] falling back to direct walk_to")
			walk_to(H, target_turf, 1, H.move_to_delay)

/**
 * Called when raider reaches their objective.
 */
/datum/component/raider/proc/on_reached_objective()
	var/mob/living/simple_animal/hostile/H = parent
	log_admin("RAID DEBUG: [H?.type] reached objective at [AREACOORD(H)]")

	reached_objective = TRUE

	// Check if we're at a door that needs opening
	var/obj/structure/mineral_door/door = find_blocking_door()
	if(door)
		log_admin("RAID DEBUG: [H?.type] found door at objective - opening it")
		open_door(door)
		return

	// If targeting a room, check if we're inside it
	var/area/resurgence_outpost/room/target_room = target_room_ref?.resolve()
	var/area/current_area = get_area(H)

	if(target_room)
		if(current_area == target_room)
			// We're inside the target room - start clearing it
			log_admin("RAID DEBUG: [H?.type] entered room [target_room.name] - starting to clear it")
			room_clear_time = 0 // Reset timer, check_room_clear will track time
			// First, scan for crates to loot
			if(scan_room_for_crates())
				return // Crate looting started, will call FindTarget when done
			// No crates (or can't loot) - look for targets in the room
			H.FindTarget()
		else
			// We're at the entry point but not inside yet - get a turf inside
			var/turf/inside_turf = get_random_turf_in_room(target_room)
			if(inside_turf)
				log_admin("RAID DEBUG: [H?.type] at entry point, navigating inside room [target_room.name]")
				current_objective = inside_turf
				reached_objective = FALSE
				navigate_to_objective()
				return

	// No target room or reached final destination - look for players to attack
	log_admin("RAID DEBUG: [H?.type] at final objective - switching to FindTarget() mode")
	H.FindTarget()

/**
 * Assign a room as the target for this raider.
 *
 * Arguments:
 * * target_room - The room area to target
 *
 * Returns: TRUE if successfully assigned, FALSE otherwise
 */
/datum/component/raider/proc/assign_room_target(area/resurgence_outpost/room/target_room)
	if(!target_room)
		return FALSE

	var/mob/living/simple_animal/hostile/H = parent
	var/can_smash_walls = (H.environment_smash & ENVIRONMENT_SMASH_WALLS)

	// Check if room is accessible
	if(!is_room_accessible_with_smash(target_room, can_smash_walls))
		log_admin("RAID DEBUG: [H?.type] cannot access room [target_room.name] - not accessible")
		return FALSE

	// Get entry point for the room
	var/turf/entry_point = get_room_entry_point(target_room)
	if(!entry_point)
		entry_point = get_random_turf_in_room(target_room)

	if(!entry_point)
		log_admin("RAID DEBUG: [H?.type] cannot find entry point for room [target_room.name]")
		return FALSE

	// Check what's at the entry point (for debugging)
	var/entry_info = "open turf"
	for(var/obj/structure/mineral_door/door in entry_point)
		entry_info = "mineral door ([door.door_opened ? "open" : "closed"])"
		break
	for(var/obj/machinery/door/door in entry_point)
		entry_info = "machinery door"
		break

	log_admin("RAID DEBUG: [H?.type] assigned to room [target_room.name], entry point: [AREACOORD(entry_point)] ([entry_info]), boundary_doors: [target_room.boundary_doors?.len || 0]")

	current_objective = entry_point
	target_room_ref = WEAKREF(target_room)
	reached_objective = FALSE
	navigate_to_objective()
	return TRUE

/**
 * Stop waiting at spawn and start navigating to objective.
 * Called when delayed raids begin their attack phase.
 */
/datum/component/raider/proc/start_attack()
	if(!waiting_at_spawn)
		// Already attacking - but make sure we're navigating
		if(current_objective && !current_commander)
			navigate_to_objective()
		return

	waiting_at_spawn = FALSE
	log_admin("RAID DEBUG: [parent?.type] starting attack - no longer waiting at spawn")

	// Start navigating to objective (calculates A* path)
	if(current_objective)
		navigate_to_objective()

/**
 * Begin retreating to the spawn point.
 */
/datum/component/raider/proc/begin_retreat()
	if(!retreat_point || retreating)
		return

	retreating = TRUE
	current_objective = retreat_point
	reached_objective = FALSE

	var/mob/living/simple_animal/hostile/H = parent
	log_admin("RAID DEBUG: [H?.type] beginning retreat to spawn point at [AREACOORD(retreat_point)]")

	navigate_to_objective()

/**
 * Called when the raider reaches their retreat point.
 */
/datum/component/raider/proc/on_reached_retreat_point()
	var/mob/living/simple_animal/hostile/H = parent
	if(!H || H.stat == DEAD)
		return

	log_admin("RAID DEBUG: [H?.type] reached retreat point - teleporting away")

	// Mark as escaped so Destroy() doesn't double-process
	escaped = TRUE

	// If the parent is a raider with retreat_teleport(), use that
	if(istype(H, /mob/living/simple_animal/hostile/clan/raider))
		var/mob/living/simple_animal/hostile/clan/raider/R = H
		R.retreat_teleport()
	else
		// Generic retreat for non-raider mobs
		H.visible_message(span_warning("[H] vanishes!"))
		playsound(H, 'sound/effects/ordeals/white/pale_teleport_out.ogg', 25, TRUE)
		new /obj/effect/temp_visual/beam_out(get_turf(H))
		if(raid)
			raid.on_raider_escaped(H)
		qdel(H)

/**
 * For pillage raids - attempt to pick up nearby valuable items.
 *
 * Returns: TRUE if an item was looted, FALSE otherwise
 */
/datum/component/raider/proc/try_loot()
	if(length(stolen_items) >= max_stolen)
		if(retreat_when_full)
			begin_retreat()
		return FALSE

	var/mob/living/simple_animal/hostile/H = parent
	for(var/obj/item/I in range(1, H))
		if(I.anchored)
			continue
		var/value = get_item_trade_value(I)
		if(value >= 5)
			I.forceMove(H)
			stolen_items += I
			H.visible_message(span_warning("[H] grabs [I]!"))
			return TRUE
	return FALSE

// ==================== Room Utility Procs ====================

/**
 * Check if a room is accessible (has doors or openings in boundary).
 * Raiders can break through closed doors, so rooms with ANY door are accessible.
 * Uses the boundary_doors list populated by room_detection.dm
 *
 * Arguments:
 * * room - The room area to check
 *
 * Returns: TRUE if raiders can enter, FALSE if fully enclosed
 */
/proc/is_room_accessible(area/resurgence_outpost/room/room)
	if(!room)
		return FALSE

	// Room detection stores all boundary doors (mineral and machinery) in boundary_doors
	// Raiders can break through any door, so if doors exist, room is accessible
	if(room.boundary_doors?.len)
		return TRUE

	// Check if any boundary wall position has an adjacent open turf outside the room
	for(var/turf/wall_turf in room.boundary_walls)
		for(var/dir in GLOB.cardinals)
			var/turf/adjacent = get_step(wall_turf, dir)
			if(!adjacent)
				continue
			if(adjacent.loc != room && !adjacent.density)
				for(var/turf/room_turf in room.contents)
					if(get_dist(room_turf, adjacent) <= 2 && !room_turf.density)
						return TRUE

	return FALSE

/**
 * Check if a room is accessible by wall-smashing raiders.
 *
 * Arguments:
 * * room - The room area to check
 * * can_smash_walls - Whether the raider can smash through walls
 *
 * Returns: TRUE if room is accessible, FALSE otherwise
 */
/proc/is_room_accessible_with_smash(area/resurgence_outpost/room/room, can_smash_walls = FALSE)
	if(!room)
		return FALSE

	// Wall-smashers can access any room
	if(can_smash_walls)
		return TRUE

	return is_room_accessible(room)

/**
 * Get the best entry point for a room.
 * Uses the boundary_doors list populated by room_detection.dm
 * Returns a turf OUTSIDE the room, adjacent to a door.
 *
 * Arguments:
 * * room - The room area to find entry for
 *
 * Returns: A turf that raiders should pathfind to first (outside the room, next to a door)
 */
/proc/get_room_entry_point(area/resurgence_outpost/room/room)
	if(!room)
		return null

	// Priority 1: Use boundary_doors - find a turf OUTSIDE the room adjacent to the door
	if(room.boundary_doors?.len)
		for(var/obj/door in room.boundary_doors)
			var/turf/door_turf = get_turf(door)
			if(!door_turf)
				continue
			// Find an adjacent turf that is OUTSIDE the room
			for(var/dir in GLOB.cardinals)
				var/turf/adjacent = get_step(door_turf, dir)
				if(!adjacent)
					continue
				// Must be outside the room and not dense
				if(adjacent.loc != room && !adjacent.density)
					return adjacent

	// Priority 2: Find any open turf outside the room boundary
	for(var/turf/T in room.contents)
		for(var/dir in GLOB.cardinals)
			var/turf/adjacent = get_step(T, dir)
			if(!adjacent || adjacent.loc == room)
				continue
			if(!adjacent.density)
				return adjacent

	// Priority 3: For wall-smashers, find a wall to break through
	if(room.boundary_walls?.len)
		return pick(room.boundary_walls)

	// Fallback: Random turf in room
	return get_random_turf_in_room(room)

/**
 * Get all valid room areas on the map.
 *
 * Arguments:
 * * require_accessible - If TRUE, only return rooms that have doors/openings
 * * can_smash_walls - If TRUE, enclosed rooms are also valid
 *
 * Returns: List of valid room areas
 */
/proc/get_resurgence_room_areas(require_accessible = TRUE, can_smash_walls = FALSE)
	var/list/rooms = list()
	for(var/area/resurgence_outpost/room/R in GLOB.sortedAreas)
		if(R.contents.len == 0)
			continue

		if(require_accessible)
			if(!is_room_accessible_with_smash(R, can_smash_walls))
				continue

		rooms += R
	return rooms

/**
 * Get a random open turf inside a room area.
 *
 * Arguments:
 * * room - The room area to search
 *
 * Returns: A random open turf in the room, or null if none found
 */
/proc/get_random_turf_in_room(area/resurgence_outpost/room/room)
	if(!room || !room.contents.len)
		return null
	var/list/valid_turfs = list()
	for(var/turf/T in room.contents)
		if(!T.density)
			valid_turfs += T
	if(!valid_turfs.len)
		return null
	return pick(valid_turfs)

// ==================== Pillager Variant ====================

/**
 * Pillager raider component - automatically loots items and retreats when full.
 */
/datum/component/raider/pillager
	retreat_when_full = TRUE
	max_stolen = 3

/datum/component/raider/pillager/on_reached_objective()
	. = ..()
	// Try to loot when reaching objective
	try_loot()

/datum/component/raider/pillager/check_stuck()
	. = ..()
	// Also try to loot while moving around
	var/mob/living/simple_animal/hostile/H = parent
	if(H && H.stat != DEAD && !retreating)
		try_loot()
