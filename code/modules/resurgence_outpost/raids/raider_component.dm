/**
 * Resurgence Outpost - Raider Component
 *
 * Component that can be attached to any hostile mob to give it raider behavior.
 * Handles navigation, stuck detection, objective tracking, and raid coordination.
 */

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

	/// Whether the raider has reached its initial objective
	var/reached_objective = FALSE

/datum/component/raider/Initialize(datum/resurgence_raid/_raid, atom/_objective, obj/effect/landmark/raid_spawn/_retreat_point)
	if(!ishostile(parent))
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

	// Start navigation refresh timer (refresh path every 10 seconds)
	nav_refresh_timer = addtimer(CALLBACK(src, PROC_REF(refresh_navigation)), 10 SECONDS, TIMER_LOOP | TIMER_STOPPABLE)

	// Start navigation
	navigate_to_objective()

/datum/component/raider/Destroy()
	if(stuck_check_timer)
		deltimer(stuck_check_timer)
	if(nav_refresh_timer)
		deltimer(nav_refresh_timer)
	if(raid)
		raid.on_raider_removed(parent)

	// Drop stolen items
	if(stolen_items.len)
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

	// Check if we've reached our objective
	if(current_objective && !reached_objective)
		var/turf/obj_turf = get_turf(current_objective)
		var/turf/our_turf = get_turf(parent)
		if(our_turf == obj_turf || get_dist(our_turf, obj_turf) <= 1)
			on_reached_objective()

/**
 * Check if the raider is stuck and needs to smash through obstacles.
 */
/datum/component/raider/proc/check_stuck()
	var/mob/living/simple_animal/hostile/H = parent
	if(!H || H.stat == DEAD)
		return

	var/turf/current = get_turf(H)
	if(current == last_position)
		stuck_counter++
		if(stuck_counter >= 3) // Stuck for 6+ seconds
			// Try to smash through obstacle
			H.DestroyPathToTarget()
			stuck_counter = 0
	else
		stuck_counter = 0

	last_position = current

/**
 * Refresh navigation to current objective.
 */
/datum/component/raider/proc/refresh_navigation()
	var/mob/living/simple_animal/hostile/H = parent
	if(!H || H.stat == DEAD)
		return

	if(current_objective && !retreating)
		navigate_to_objective()

/**
 * Navigate to the current objective using raider-aware pathfinding.
 */
/datum/component/raider/proc/navigate_to_objective()
	var/mob/living/simple_animal/hostile/H = parent
	if(!H || H.stat == DEAD || !current_objective)
		return

	// Get path using raider-aware A*
	var/list/path = get_path_to(
		H,
		current_objective,
		/turf/proc/Distance_cardinal,
		0,
		150,
		0,
		/turf/proc/reachableTurftestRaider
	)

	if(length(path))
		// Path found - set the target and let AI handle movement
		H.target = current_objective
		if(H.ai_controller)
			H.ai_controller.current_movement_target = current_objective
	else
		// No path found - use direct approach
		H.Goto(current_objective, H.move_to_delay, 0)

/**
 * Called when raider reaches their objective.
 */
/datum/component/raider/proc/on_reached_objective()
	reached_objective = TRUE

	// If targeting a room, get a random turf inside it
	var/area/resurgence_outpost/room/target_room = target_room_ref?.resolve()
	if(target_room)
		var/turf/inside_turf = get_random_turf_in_room(target_room)
		if(inside_turf)
			current_objective = inside_turf
			reached_objective = FALSE
			navigate_to_objective()
			return

	// Otherwise, look for players to attack or items to loot
	var/mob/living/simple_animal/hostile/H = parent
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
		return FALSE

	// Get entry point for the room
	var/turf/entry_point = get_room_entry_point(target_room)
	if(!entry_point)
		entry_point = get_random_turf_in_room(target_room)

	if(!entry_point)
		return FALSE

	current_objective = entry_point
	target_room_ref = WEAKREF(target_room)
	reached_objective = FALSE
	navigate_to_objective()
	return TRUE

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
	H.visible_message(span_warning("[H] begins retreating!"))

	navigate_to_objective()

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
 *
 * Arguments:
 * * room - The room area to check
 *
 * Returns: TRUE if raiders can enter, FALSE if fully enclosed
 */
/proc/is_room_accessible(area/resurgence_outpost/room/room)
	if(!room)
		return FALSE

	// If room has boundary doors, it's accessible
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
 *
 * Arguments:
 * * room - The room area to find entry for
 *
 * Returns: A turf that raiders should pathfind to first
 */
/proc/get_room_entry_point(area/resurgence_outpost/room/room)
	if(!room)
		return null

	// Priority 1: Find a door in the boundary
	for(var/obj/machinery/door/D in room.boundary_doors)
		var/turf/door_turf = get_turf(D)
		if(door_turf)
			return door_turf

	// Priority 2: Find any door adjacent to room turfs
	for(var/turf/T in room.contents)
		for(var/dir in GLOB.cardinals)
			var/turf/adjacent = get_step(T, dir)
			if(!adjacent)
				continue
			for(var/obj/machinery/door/D in adjacent)
				return adjacent

	// Priority 3: Find any open turf on the room boundary
	for(var/turf/T in room.contents)
		for(var/dir in GLOB.cardinals)
			var/turf/adjacent = get_step(T, dir)
			if(!adjacent || adjacent.loc == room)
				continue
			if(!adjacent.density)
				return T

	// Priority 4: For wall-smashers, find a wall to break through
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
