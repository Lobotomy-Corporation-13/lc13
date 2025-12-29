/**
 * Resurgence Outpost - Room Detection System
 *
 * Flood-fill algorithm for detecting enclosed spaces and determining room types.
 * Used by the room designator tool to create room areas.
 */

/// Maximum size of a designatable room in tiles
#define ROOM_MAX_SIZE 100

/// Room type defines
#define ROOM_TYPE_BASIC     "Basic Room"
#define ROOM_TYPE_WORKSHOP  "Workshop"
#define ROOM_TYPE_COMMON    "Common Room"
#define ROOM_TYPE_STORAGE   "Storage Room"
#define ROOM_TYPE_SHRINE    "Shrine"

/**
 * Detect an enclosed room using flood-fill algorithm.
 *
 * Starts from origin turf and expands outward, stopping at walls/closed turfs.
 * Returns null if the space opens to outdoors, space, or water.
 * Returns null if the space exceeds ROOM_MAX_SIZE tiles.
 *
 * Arguments:
 * * origin - The starting turf for room detection
 *
 * Returns: List of turfs forming the enclosed room, or null if invalid
 */
/proc/detect_enclosed_room(turf/origin)
	if(!origin)
		return null

	// Can't start from a closed turf
	if(isclosedturf(origin))
		return null

	var/list/found_turfs = list()
	var/list/boundary_walls = list()    // Closed turfs that form the boundary
	var/list/boundary_doors = list()    // Door structures that form the boundary
	var/list/to_check = list(origin)
	var/list/checked = list()

	while(to_check.len && found_turfs.len <= ROOM_MAX_SIZE)
		var/turf/T = to_check[1]
		to_check.Cut(1, 2)

		if(T in checked)
			continue
		checked += T

		// Boundary check - closed turfs (walls) stop expansion but don't invalidate
		if(isclosedturf(T))
			boundary_walls += T
			continue

		// Check for door structures - they act as walls for room enclosure
		// Mineral doors and machinery doors form valid room boundaries
		var/obj/found_door = null
		for(var/obj/structure/mineral_door/door in T)
			found_door = door
			break
		if(!found_door)
			for(var/obj/machinery/door/door in T)
				found_door = door
				break

		// Doors act as room boundaries - stop expansion here
		if(found_door)
			boundary_doors += found_door
			continue

		// NOTE: Dense structures (crafting tables, etc.) do NOT block room detection
		// Only closed turfs and doors count as room boundaries

		// Invalid space check - these mean room is not enclosed
		if(isspaceturf(T))
			return null

		// Water turfs mean room is not valid for designation
		if(istype(T, /turf/open/water))
			return null

		found_turfs += T

		// Check cardinal adjacent tiles
		for(var/dir in GLOB.cardinals)
			var/turf/adjacent = get_step(T, dir)
			if(adjacent && !(adjacent in checked))
				to_check += adjacent

	// If we exceeded max size, room is too large
	if(found_turfs.len > ROOM_MAX_SIZE)
		return null

	// Must have at least 1 tile
	if(!found_turfs.len)
		return null

	// Return a list with all the data
	return list(
		"turfs" = found_turfs,
		"boundary_walls" = boundary_walls,
		"boundary_doors" = boundary_doors
	)

/**
 * Determine the type of room based on contained structures.
 *
 * Priority order: Shrine > Workshop > Common > Storage > Basic
 *
 * Arguments:
 * * turfs - List of turfs that make up the room
 *
 * Returns: Room type string constant
 */
/proc/determine_room_type(list/turfs)
	var/has_production = FALSE
	var/has_decor = FALSE
	var/has_storage = FALSE
	var/has_shrine = FALSE

	for(var/turf/T in turfs)
		for(var/obj/structure/S in T)
			// Production structures - make this a Workshop
			if(istype(S, /obj/structure/resurgence_crafting_table))
				has_production = TRUE

			// Decor structures - statues, easels, beds make it feel like a home
			if(istype(S, /obj/structure/statue) || \
			   istype(S, /obj/structure/easel) || \
			   istype(S, /obj/structure/bed) || \
			   istype(S, /obj/structure/chair))
				has_decor = TRUE

			// Storage structures
			if(istype(S, /obj/structure/closet))
				has_storage = TRUE

			// Shrine structures - statues are spiritual symbols
			if(istype(S, /obj/structure/statue))
				has_shrine = TRUE

	// Priority: Shrine > Workshop > Common > Storage > Basic
	if(has_shrine)
		return ROOM_TYPE_SHRINE
	if(has_production)
		return ROOM_TYPE_WORKSHOP
	if(has_decor && !has_production)
		return ROOM_TYPE_COMMON
	if(has_storage && !has_production && !has_decor)
		return ROOM_TYPE_STORAGE
	return ROOM_TYPE_BASIC

/**
 * Get the default name for a room type.
 *
 * Arguments:
 * * room_type - The room type constant
 *
 * Returns: Human-readable room name
 */
/proc/get_default_room_name(room_type)
	switch(room_type)
		if(ROOM_TYPE_WORKSHOP)
			return "Clan Workshop"
		if(ROOM_TYPE_COMMON)
			return "Common Area"
		if(ROOM_TYPE_STORAGE)
			return "Storage Chamber"
		if(ROOM_TYPE_SHRINE)
			return "Sacred Shrine"
		else
			return "Clan Room"

