/**
 * Resurgence Outpost - Room Area Types
 *
 * Area definitions for designated rooms with faith modifiers.
 * Different room types provide different faith bonuses/penalties.
 */



/// Base outpost area
/area/resurgence_outpost
	name = "Resurgence Outpost"
	icon_state = "green"
	has_gravity = STANDARD_GRAVITY
	requires_power = FALSE
	power_environ = FALSE
	power_equip = FALSE
	power_light = FALSE
	always_unpowered = TRUE

	/// Room type for designated rooms (null for undesignated areas)
	var/room_type = null
	/// Faith modifier multiplier (1.0 = neutral)
	var/faith_modifier = 1.0
	// Set outdoors to TRUE for base outpost area
	outdoors = TRUE

/// Outdoor/undesignated outpost area
/area/resurgence_outpost/outdoors
	name = "Outskirts"
	outdoors = TRUE
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED
	faith_modifier = 1.0  // Neutral

/// Base room area (enclosed but unspecialized)
/area/resurgence_outpost/room
	name = "Clan Room"
	outdoors = FALSE
	room_type = ROOM_TYPE_BASIC
	faith_modifier = 1.25  // +25% faith gain (shelter bonus)
	icon_state = "blue"

	/// List of wall turfs that form the room boundary
	var/list/boundary_walls = list()
	/// List of door structures that form the room boundary
	var/list/boundary_doors = list()
	/// Whether this room is being dissolved
	var/dissolving = FALSE

/area/resurgence_outpost/room/Destroy()
	unregister_boundary_signals()
	return ..()

/// Register signals on boundary doors and walls to detect destruction
/area/resurgence_outpost/room/proc/register_boundary_signals()
	// Register signals on doors
	for(var/obj/door in boundary_doors)
		RegisterSignal(door, COMSIG_PARENT_QDELETING, PROC_REF(on_boundary_door_destroyed))
	// Register signals on wall turfs for when they change
	for(var/turf/T in boundary_walls)
		RegisterSignal(T, COMSIG_TURF_CHANGE, PROC_REF(on_boundary_wall_changed))

/// Unregister all boundary signals
/area/resurgence_outpost/room/proc/unregister_boundary_signals()
	for(var/obj/door in boundary_doors)
		UnregisterSignal(door, COMSIG_PARENT_QDELETING)
	for(var/turf/T in boundary_walls)
		UnregisterSignal(T, COMSIG_TURF_CHANGE)

/// Called when a boundary door is destroyed
/area/resurgence_outpost/room/proc/on_boundary_door_destroyed(datum/source)
	SIGNAL_HANDLER
	if(dissolving)
		return
	// A door forming the room boundary was destroyed - dissolve the room
	dissolve_room("A door forming the room boundary was destroyed.")

/// Called when a boundary wall turf changes
/area/resurgence_outpost/room/proc/on_boundary_wall_changed(turf/source, path, list/new_baseturfs, flags, list/post_change_callbacks)
	SIGNAL_HANDLER
	if(dissolving)
		return
	// Check if the new turf type is still a closed turf (wall)
	// The path argument is the new turf type being changed to
	if(!ispath(path, /turf/closed))
		// Wall is being changed to an open turf - dissolve the room
		dissolve_room("A wall forming the room boundary was destroyed.")

/// Check if all boundary walls are still intact (manual check, backup for signals)
/area/resurgence_outpost/room/proc/check_boundary_integrity()
	if(dissolving)
		return TRUE
	for(var/turf/T in boundary_walls)
		if(!isclosedturf(T))
			// Wall was destroyed or changed to open turf
			dissolve_room("A wall forming the room boundary was destroyed.")
			return FALSE
	return TRUE

/// Dissolve this room back to outdoors
/area/resurgence_outpost/room/proc/dissolve_room(reason = "")
	if(dissolving)
		return
	dissolving = TRUE

	// Unregister signals first
	unregister_boundary_signals()

	// Get or create the outdoors area
	var/area/resurgence_outpost/outdoors/outdoor_area = locate() in GLOB.sortedAreas
	if(!outdoor_area)
		outdoor_area = new /area/resurgence_outpost/outdoors()
		outdoor_area.setup("Outskirts")
		outdoor_area.reg_in_areas_in_z()

	// Move all turfs back to outdoors
	var/list/turfs_to_move = list()
	for(var/turf/T in contents)
		turfs_to_move += T

	for(var/turf/T in turfs_to_move)
		outdoor_area.contents += T
		T.change_area(src, outdoor_area)

	// Announce to resurgence machines
	announce_room_dissolved(name, reason)

	// Delete this area
	qdel(src)

/// Announce that a room has been dissolved
/proc/announce_room_dissolved(room_name, reason)
	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		if(!H.mind)
			continue
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			to_chat(H, span_warning("The room '[room_name]' has been dissolved! [reason]"))

/// Workshop - production focused, reduced faith for focused work
/area/resurgence_outpost/room/workshop
	name = "Workshop"
	room_type = ROOM_TYPE_WORKSHOP
	faith_modifier = 0.75  // -25% faith gain (focused on work)
	icon_state = "yellow"

/// Common Room - community gathering, increased faith
/area/resurgence_outpost/room/common
	name = "Common Room"
	room_type = ROOM_TYPE_COMMON
	faith_modifier = 1.5  // +50% faith gain (community)
	icon_state = "green"

/// Storage Room - organized goods, small faith bonus
/area/resurgence_outpost/room/storage
	name = "Storage Room"
	room_type = ROOM_TYPE_STORAGE
	faith_modifier = 1.1  // +10% faith gain
	icon_state = "brown"

/// Shrine - spiritual center, highest faith bonus
/area/resurgence_outpost/room/shrine
	name = "Shrine"
	room_type = ROOM_TYPE_SHRINE
	faith_modifier = 1.75  // +75% faith gain (spiritual center)
	icon_state = "purple"

/**
 * Create a new resurgence room area from a list of turfs.
 *
 * Arguments:
 * * turfs - List of turfs to include in the room
 * * room_type - Type of room to create (ROOM_TYPE_* constant)
 * * room_name - Custom name for the room
 * * creator - The mob creating the room (for feedback)
 * * boundary_walls - List of wall turfs forming the boundary (optional)
 * * boundary_doors - List of door structures forming the boundary (optional)
 *
 * Returns: The created area, or null on failure
 */
/proc/create_resurgence_room(list/turfs, room_type, room_name, mob/creator, list/boundary_walls = null, list/boundary_doors = null)
	if(!turfs || !turfs.len)
		return null

	// Create the appropriate area type based on room type
	var/area/resurgence_outpost/room/new_area

	switch(room_type)
		if(ROOM_TYPE_WORKSHOP)
			new_area = new /area/resurgence_outpost/room/workshop()
		if(ROOM_TYPE_COMMON)
			new_area = new /area/resurgence_outpost/room/common()
		if(ROOM_TYPE_STORAGE)
			new_area = new /area/resurgence_outpost/room/storage()
		if(ROOM_TYPE_SHRINE)
			new_area = new /area/resurgence_outpost/room/shrine()
		else
			new_area = new /area/resurgence_outpost/room()

	// Setup the area with custom name
	new_area.setup(room_name)

	// Store boundary information for integrity checking
	if(boundary_walls)
		new_area.boundary_walls = boundary_walls.Copy()
	if(boundary_doors)
		new_area.boundary_doors = boundary_doors.Copy()

	// Register signals on walls and doors to detect destruction
	if(boundary_walls?.len || boundary_doors?.len)
		new_area.register_boundary_signals()

	// Transfer all turfs to the new area
	for(var/turf/T in turfs)
		var/area/old_area = T.loc
		new_area.contents += T
		T.change_area(old_area, new_area)

	// Register the area with the mapping subsystem
	new_area.reg_in_areas_in_z()

	// Announce to creator
	if(creator)
		to_chat(creator, span_notice("You have designated this space as '[room_name]' ([room_type])."))

	// Announce to all resurgence machines
	announce_room_created(room_name, room_type)

	return new_area

/**
 * Announce to all resurgence machines that a new room was created.
 *
 * Arguments:
 * * room_name - Name of the new room
 * * room_type - Type of the new room
 */
/proc/announce_room_created(room_name, room_type)
	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		if(!H.mind)
			continue
		// Check if they're a resurgence machine (has resurgence core)
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			to_chat(H, span_notice("A new [room_type] has been established: '[room_name]'."))

/**
 * Check if a crafting station is in a workshop area.
 * Used by crafting tables to determine if 3x time penalty applies.
 *
 * Arguments:
 * * source - The structure to check
 *
 * Returns: TRUE if in a workshop, FALSE otherwise
 */
/proc/is_in_workshop(atom/source)
	var/area/resurgence_outpost/room/R = get_area(source)
	if(!istype(R))
		return FALSE
	return R.room_type == ROOM_TYPE_WORKSHOP

/**
 * Get the faith modifier for an area.
 *
 * Arguments:
 * * source - The atom to check
 *
 * Returns: Faith modifier (1.0 = neutral)
 */
/proc/get_area_faith_modifier(atom/source)
	var/area/resurgence_outpost/A = get_area(source)
	if(!istype(A))
		return 1.0
	return A.faith_modifier

