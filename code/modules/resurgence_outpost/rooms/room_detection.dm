/**
 * Resurgence Outpost - Room Detection System
 *
 * Flood-fill algorithm for detecting enclosed spaces and determining room types.
 * Used by the room designator tool to create room areas.
 */

/// Maximum size of a designatable room in tiles
#define ROOM_MAX_SIZE 100

/// Room cramped thresholds
#define ROOM_MIN_TILES 9  // 10 or less = cramped
#define ROOM_MIN_DIMENSION 3  // width or height < 3 = cramped

/// Room type defines
#define ROOM_TYPE_BASIC           "Basic Room"
#define ROOM_TYPE_WORKSHOP        "Workshop"
#define ROOM_TYPE_COMMON          "Common Room"
#define ROOM_TYPE_STORAGE         "Storage Room"
#define ROOM_TYPE_KITCHEN         "Kitchen"
#define ROOM_TYPE_LIVING_QUARTERS "Living Quarters"
#define ROOM_TYPE_EXPORT_WAREHOUSE "Export Warehouse"
#define ROOM_TYPE_BARRACKS        "Barracks"

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
 * Determine all valid room types based on contained structures.
 *
 * A room can qualify as multiple types if it has the required structures.
 * The player will be able to choose if multiple types apply.
 *
 * Arguments:
 * * turfs - List of turfs that make up the room
 *
 * Returns: List of valid room type string constants
 */
/proc/determine_valid_room_types(list/turfs)
	var/list/valid_types = list()

	var/has_crafting_table = FALSE
	var/has_kitchen = FALSE
	var/has_table = FALSE
	var/has_chair = FALSE
	var/bed_count = 0
	var/has_closet = FALSE
	var/has_fridge = FALSE
	var/has_resources_recorder = FALSE

	// Scan all turfs for structures
	for(var/turf/T in turfs)
		for(var/obj/structure/S in T)
			if(istype(S, /obj/structure/resurgence_crafting_table))
				has_crafting_table = TRUE
			if(istype(S, /obj/structure/resurgence_kitchen))
				has_kitchen = TRUE
			if(istype(S, /obj/structure/table))
				has_table = TRUE
			if(istype(S, /obj/structure/chair))
				has_chair = TRUE
			if(istype(S, /obj/structure/resurgence_bed))
				bed_count++
			if(istype(S, /obj/structure/closet))
				has_closet = TRUE
			if(istype(S, /obj/structure/resources_recorder))
				has_resources_recorder = TRUE
		// Check for fridge (it's a closet subtype but special)
		for(var/obj/structure/closet/secure_closet/freezer/fridge/F in T)
			has_fridge = TRUE

	// Check each room type based on required structures
	if(has_crafting_table)
		valid_types += ROOM_TYPE_WORKSHOP
	if(has_kitchen || has_fridge)
		valid_types += ROOM_TYPE_KITCHEN
	if(has_table && has_chair)
		valid_types += ROOM_TYPE_COMMON
	if(bed_count >= 2)
		valid_types += ROOM_TYPE_BARRACKS
	if(bed_count >= 1)
		valid_types += ROOM_TYPE_LIVING_QUARTERS
	if(has_closet)
		valid_types += ROOM_TYPE_STORAGE
	if(has_resources_recorder)
		valid_types += ROOM_TYPE_EXPORT_WAREHOUSE

	// Default to basic if nothing else
	if(!length(valid_types))
		valid_types += ROOM_TYPE_BASIC

	return valid_types

/**
 * Determine the type of room based on contained structures.
 *
 * Wrapper that returns a single type (first valid or basic).
 * For multi-type selection, use determine_valid_room_types() instead.
 *
 * Arguments:
 * * turfs - List of turfs that make up the room
 *
 * Returns: Room type string constant
 */
/proc/determine_room_type(list/turfs)
	var/list/valid = determine_valid_room_types(turfs)
	return valid[1]

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
		if(ROOM_TYPE_KITCHEN)
			return "Clan Kitchen"
		if(ROOM_TYPE_LIVING_QUARTERS)
			return "Living Quarters"
		if(ROOM_TYPE_EXPORT_WAREHOUSE)
			return "Export Warehouse"
		if(ROOM_TYPE_BARRACKS)
			return "Clan Barracks"
		else
			return "Clan Room"

/**
 * Check if any boundary walls or doors are made of sandstone.
 *
 * Arguments:
 * * boundary_walls - List of wall turfs forming the boundary
 * * boundary_doors - List of door structures forming the boundary
 *
 * Returns: TRUE if any sandstone is found, FALSE otherwise
 */
/proc/check_for_sandstone_boundary(list/boundary_walls, list/boundary_doors)
	// Check walls for sandstone
	for(var/turf/closed/wall/mineral/sandstone/W in boundary_walls)
		return TRUE
	// Check doors for sandstone
	for(var/obj/structure/mineral_door/sandstone/D in boundary_doors)
		return TRUE
	return FALSE

/**
 * Get a list of room types that can be made with sandstone.
 *
 * Returns: List of valid room type constants for sandstone construction
 */
/proc/get_sandstone_allowed_room_types()
	return list(ROOM_TYPE_LIVING_QUARTERS, ROOM_TYPE_WORKSHOP)

/**
 * Check if a room would be considered cramped based on its turfs.
 *
 * A room is cramped if:
 * - It has 10 or fewer tiles (ROOM_MIN_TILES)
 * - OR any dimension (width/height) is less than 3 (ROOM_MIN_DIMENSION)
 *
 * Arguments:
 * * turfs - List of turfs that make up the room
 *
 * Returns: TRUE if the room is cramped, FALSE otherwise
 */
/proc/is_room_cramped(list/turfs)
	if(!turfs || !length(turfs))
		return TRUE

	// Check tile count
	if(length(turfs) <= ROOM_MIN_TILES)
		return TRUE

	// Calculate bounding box dimensions
	var/min_x = INFINITY
	var/max_x = -INFINITY
	var/min_y = INFINITY
	var/max_y = -INFINITY

	for(var/turf/T in turfs)
		min_x = min(min_x, T.x)
		max_x = max(max_x, T.x)
		min_y = min(min_y, T.y)
		max_y = max(max_y, T.y)

	var/width = max_x - min_x + 1
	var/height = max_y - min_y + 1

	// Check if any dimension is too small
	if(width < ROOM_MIN_DIMENSION || height < ROOM_MIN_DIMENSION)
		return TRUE

	return FALSE

/**
 * Get a list of room types that can be cramped.
 * Living Quarters and Common Room are exempt from cramped restrictions.
 *
 * Returns: List of room type constants that CANNOT be cramped
 */
/proc/get_cramped_restricted_room_types()
	return list(
		ROOM_TYPE_WORKSHOP,
		ROOM_TYPE_STORAGE,
		ROOM_TYPE_KITCHEN,
		ROOM_TYPE_EXPORT_WAREHOUSE,
		ROOM_TYPE_BARRACKS,
		ROOM_TYPE_BASIC
	)

