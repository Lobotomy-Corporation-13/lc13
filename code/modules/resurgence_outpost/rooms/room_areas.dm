/**
 * Resurgence Outpost - Room Area Types
 *
 * Area definitions for designated rooms with faith modifiers.
 * Different room types provide different faith bonuses/penalties.
 */

/// Global tracking of room ownership: ckey -> area reference
GLOBAL_LIST_EMPTY(resurgence_room_owners)

// Room quality thresholds (beauty per tile)
#define ROOM_QUALITY_LUXURIOUS 50
#define ROOM_QUALITY_COMFORTABLE 30
#define ROOM_QUALITY_ADEQUATE 10
#define ROOM_QUALITY_BARE 0
#define ROOM_QUALITY_SHABBY -20

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
	/// The ckey of the player who owns this room (null = unclaimed)
	var/owner_ckey = null
	/// Whether this room was built with sandstone walls/doors (halves quality bonus for living quarters)
	var/is_sandstone = FALSE

/area/resurgence_outpost/room/Destroy()
	// Clean up ownership before destroying
	if(owner_ckey)
		GLOB.resurgence_room_owners -= owner_ckey
		apply_homeless_faith_event(owner_ckey)
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

/// Claim this room for a player
/area/resurgence_outpost/room/proc/claim_room(ckey)
	if(!ckey)
		return FALSE

	// Only living quarters can be claimed
	if(room_type != ROOM_TYPE_LIVING_QUARTERS)
		return FALSE

	// Unclaim any previously owned room by this player
	var/area/resurgence_outpost/room/old_room = GLOB.resurgence_room_owners[ckey]
	if(old_room && !QDELETED(old_room) && old_room != src)
		old_room.unclaim_room(silent = TRUE)

	// Set new owner
	owner_ckey = ckey
	GLOB.resurgence_room_owners[ckey] = src

	// Update faith event for the owner
	update_owner_faith_event()
	return TRUE

/// Remove ownership from this room
/area/resurgence_outpost/room/proc/unclaim_room(silent = FALSE)
	if(!owner_ckey)
		return FALSE

	var/old_ckey = owner_ckey
	GLOB.resurgence_room_owners -= owner_ckey
	owner_ckey = null

	// Update faith event - player is now homeless (unless silent, for when claiming new room)
	if(!silent)
		apply_homeless_faith_event(old_ckey)
	return TRUE

/// Update the room owner's faith event to "Has Personal Room"
/area/resurgence_outpost/room/proc/update_owner_faith_event()
	if(!owner_ckey)
		return

	// Find the player's resurgence core
	var/obj/item/organ/resurgence_core/core = get_resurgence_core_by_ckey(owner_ckey)
	if(!core)
		return

	// Add "Has Personal Room" event (+5 faith per 30 seconds = +1 per 6-second tick)
	var/datum/faith_event/room_ownership/event = new(
		"You have a personal room.",
		1, // +1 per tick (applied every ~6 seconds, so ~+5 per 30 sec)
		null, // permanent until room lost
		"room_ownership"
	)
	core.add_faith_event("room_ownership", event)

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

/// Kitchen - food preparation, moderate faith bonus
/area/resurgence_outpost/room/kitchen
	name = "Kitchen"
	room_type = ROOM_TYPE_KITCHEN
	faith_modifier = 1.3  // +30% faith gain (nourishment)
	icon_state = "orange"

/// Living Quarters - personal sanctuary, only claimable room type
/area/resurgence_outpost/room/living_quarters
	name = "Living Quarters"
	room_type = ROOM_TYPE_LIVING_QUARTERS
	faith_modifier = 1.4  // +40% faith gain (personal sanctuary)
	icon_state = "pink"

/// Export Warehouse - logistics hub for exporting resources
/area/resurgence_outpost/room/export_warehouse
	name = "Export Warehouse"
	room_type = ROOM_TYPE_EXPORT_WAREHOUSE
	faith_modifier = 1.2  // +20% faith gain (logistics)
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

	// Check for sandstone in boundaries
	var/has_sandstone = check_for_sandstone_boundary(boundary_walls, boundary_doors)

	// Sandstone can only be used for Living Quarters and Workshop
	if(has_sandstone)
		var/list/allowed_types = get_sandstone_allowed_room_types()
		if(!(room_type in allowed_types))
			if(creator)
				to_chat(creator, span_warning("Sandstone walls and doors can only be used for Living Quarters and Workshop. For other room types, use proper building materials."))
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
		if(ROOM_TYPE_KITCHEN)
			new_area = new /area/resurgence_outpost/room/kitchen()
		if(ROOM_TYPE_LIVING_QUARTERS)
			new_area = new /area/resurgence_outpost/room/living_quarters()
		if(ROOM_TYPE_EXPORT_WAREHOUSE)
			new_area = new /area/resurgence_outpost/room/export_warehouse()
		else
			new_area = new /area/resurgence_outpost/room()

	// Setup the area with custom name
	new_area.setup(room_name)

	// Mark if room was built with sandstone (affects quality bonus)
	new_area.is_sandstone = has_sandstone

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

	// Recalculate beauty from scratch for the new room
	recalculate_area_beauty(new_area)

	// Announce to creator
	if(creator)
		to_chat(creator, span_notice("You have designated this space as '[room_name]' ([room_type])."))

	// Announce to all resurgence machines
	announce_room_created(room_name, room_type)

	// Update global objectives (building objectives track room counts)
	update_all_objectives()

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
 * Check if atom is in a room of the specified type.
 *
 * Arguments:
 * * source - The atom to check
 * * expected_type - The room type constant to check for
 *
 * Returns: TRUE if in correct room type, FALSE otherwise
 */
/proc/is_in_room_type(atom/source, expected_type)
	var/area/resurgence_outpost/room/R = get_area(source)
	if(!istype(R))
		return FALSE
	return R.room_type == expected_type

/**
 * Check if atom is in a kitchen.
 *
 * Arguments:
 * * source - The atom to check
 *
 * Returns: TRUE if in kitchen, FALSE otherwise
 */
/proc/is_in_kitchen(atom/source)
	return is_in_room_type(source, ROOM_TYPE_KITCHEN)

/**
 * Check if atom is in living quarters.
 *
 * Arguments:
 * * source - The atom to check
 *
 * Returns: TRUE if in living quarters, FALSE otherwise
 */
/proc/is_in_living_quarters(atom/source)
	return is_in_room_type(source, ROOM_TYPE_LIVING_QUARTERS)

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

/**
 * Apply "Homeless" faith event to a player without a room.
 *
 * Arguments:
 * * ckey - The ckey of the player to apply the event to
 */
/proc/apply_homeless_faith_event(ckey)
	if(!ckey)
		return

	var/obj/item/organ/resurgence_core/core = get_resurgence_core_by_ckey(ckey)
	if(!core)
		return

	// Add "Homeless" event (-1 per tick, following Faith Event Design Guidelines for permanent events)
	var/datum/faith_event/room_ownership/event = new(
		"You have no personal room.",
		-1, // -1 per tick (permanent events should be ≤ ±1 per tick per guidelines)
		null, // permanent until room claimed
		"room_ownership"
	)
	core.add_faith_event("room_ownership", event)

/**
 * Helper to find a resurgence core by ckey.
 *
 * Arguments:
 * * ckey - The ckey to search for
 *
 * Returns: The resurgence core if found, null otherwise
 */
/proc/get_resurgence_core_by_ckey(ckey)
	if(!ckey)
		return null
	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		if(H.ckey == ckey)
			var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
			if(istype(core))
				return core
	return null

/**
 * Check if a mob is eating in a common room.
 * Returns bonus tier adjustment for meal quality.
 *
 * Arguments:
 * * eater - The mob that is eating
 *
 * Returns: 1 if in common room, 0 otherwise
 */
/proc/get_common_room_eating_bonus(mob/living/eater)
	if(!ishuman(eater))
		return 0

	var/area/resurgence_outpost/room/room = get_area(eater)
	if(!istype(room))
		return 0

	if(room.room_type == ROOM_TYPE_COMMON)
		return 1  // +1 quality tier

	return 0

/**
 * Recalculate the beauty of an area from scratch.
 * Resets totalbeauty to 0 and counts all beauty components in the area.
 *
 * Arguments:
 * * target_area - The area to recalculate beauty for
 */
/proc/recalculate_area_beauty(area/target_area)
	if(!target_area)
		return

	// Don't calculate for outdoor areas
	if(target_area.outdoors)
		return

	// Reset beauty to 0
	target_area.totalbeauty = 0

	// Go through all turfs in the area
	for(var/turf/T in target_area.contents)
		// Check all atoms on this turf
		for(var/atom/A in T.contents)
			// Get the beauty component if it exists
			var/datum/component/beauty/B = A.GetComponent(/datum/component/beauty)
			if(B)
				target_area.totalbeauty += B.beauty

	// Update the beauty average
	target_area.update_beauty()
