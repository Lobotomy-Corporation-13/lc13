/**
 * Resurgence Outpost - Room Area Types
 *
 * Area definitions for designated rooms with faith modifiers.
 * Different room types provide different faith bonuses/penalties.
 * Note: Players claim BEDS, not rooms. See bed.dm for ownership system.
 */

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
	// Set outdoors to TRUE for base outpost area
	outdoors = TRUE

	/// Total resurgence beauty in this area (separate from base game beauty)
	var/total_resurgence_beauty = 0
	/// Resurgence beauty average per open turf (used for room quality calculations)
	var/resurgence_beauty = 0

/**
 * Update the resurgence beauty average for this area.
 * Called when objects with resurgence_beauty components enter or exit.
 */
/area/resurgence_outpost/proc/update_resurgence_beauty()
	if(!areasize)
		resurgence_beauty = 0
		return FALSE
	if(areasize >= beauty_threshold)
		resurgence_beauty = 0
		return FALSE  // Too big
	resurgence_beauty = total_resurgence_beauty / areasize

/// Outdoor/undesignated outpost area - procedurally generated wilderness
/area/resurgence_outpost/outdoors
	name = "Outskirts"
	outdoors = TRUE
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED
	map_generator = /datum/map_generator/resurgence_generator

/// Central settlement area - static layout, excluded from terrain generation and ruin seeding
/area/resurgence_outpost/settlement
	name = "Settlement"
	outdoors = TRUE
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED

/// Base room area (enclosed but unspecialized)
/area/resurgence_outpost/room
	name = "Clan Room"
	outdoors = FALSE
	room_type = ROOM_TYPE_BASIC
	icon_state = "blue"

	/// List of wall turfs that form the room boundary
	var/list/boundary_walls = list()
	/// List of door structures that form the room boundary
	var/list/boundary_doors = list()
	/// Whether this room is being dissolved
	var/dissolving = FALSE
	/// Whether this room was built with sandstone walls/doors (halves quality bonus for living quarters)
	var/is_sandstone = FALSE

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

/// Workshop - production focused
/area/resurgence_outpost/room/workshop
	name = "Workshop"
	room_type = ROOM_TYPE_WORKSHOP
	icon_state = "yellow"

/// Common Room - community gathering
/area/resurgence_outpost/room/common
	name = "Common Room"
	room_type = ROOM_TYPE_COMMON
	icon_state = "green"

/// Storage Room - organized goods
/area/resurgence_outpost/room/storage
	name = "Storage Room"
	room_type = ROOM_TYPE_STORAGE
	icon_state = "brown"

/// Kitchen - food preparation
/area/resurgence_outpost/room/kitchen
	name = "Kitchen"
	room_type = ROOM_TYPE_KITCHEN
	icon_state = "orange"

/// Living Quarters - personal sanctuary, only claimable room type
/area/resurgence_outpost/room/living_quarters
	name = "Living Quarters"
	room_type = ROOM_TYPE_LIVING_QUARTERS
	icon_state = "pink"

/// Export Warehouse - logistics hub for exporting resources
/area/resurgence_outpost/room/export_warehouse
	name = "Export Warehouse"
	room_type = ROOM_TYPE_EXPORT_WAREHOUSE
	icon_state = "purple"

/// Barracks - shared sleeping quarters, multiple beds
/area/resurgence_outpost/room/barracks
	name = "Barracks"
	room_type = ROOM_TYPE_BARRACKS
	icon_state = "blue2"

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

	// Check for low quality walls (sandstone or raw mineral) in boundaries
	var/has_low_quality = check_for_low_quality_boundary(boundary_walls, boundary_doors)

	// Low quality walls can only be used for Living Quarters and Workshop
	if(has_low_quality)
		var/list/allowed_types = get_low_quality_allowed_room_types()
		if(!(room_type in allowed_types))
			if(creator)
				to_chat(creator, span_warning("Low quality walls (sandstone or unprocessed rock) can only be used for Living Quarters and Workshop. For other room types, use proper building materials."))
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
		if(ROOM_TYPE_BARRACKS)
			new_area = new /area/resurgence_outpost/room/barracks()
		else
			new_area = new /area/resurgence_outpost/room()

	// Setup the area with custom name
	new_area.setup(room_name)

	// Mark if room was built with low quality walls (affects quality bonus)
	new_area.is_sandstone = has_low_quality

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
 * Remove the homeless faith event for a player (used by barracks which gives no positive bonus).
 *
 * Arguments:
 * * ckey - The ckey of the player to remove the event from
 */
/proc/remove_homeless_faith_event(ckey)
	if(!ckey)
		return

	var/obj/item/organ/resurgence_core/core = get_resurgence_core_by_ckey(ckey)
	if(!core)
		return

	// Remove the room_ownership event entirely (barracks gives no bonus or penalty)
	core.clear_faith_event("room_ownership")

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
 * Recalculate the resurgence beauty of an area from scratch.
 * Resets total_resurgence_beauty to 0 and counts all resurgence_beauty components in the area.
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

	// Only works for resurgence outpost areas
	var/area/resurgence_outpost/outpost_area = target_area
	if(!istype(outpost_area))
		return

	// Reset beauty to 0
	outpost_area.total_resurgence_beauty = 0

	// Go through all turfs in the area
	for(var/turf/T in outpost_area.contents)
		// Check all atoms on this turf
		for(var/atom/A in T.contents)
			// Get the resurgence beauty component if it exists
			var/datum/component/resurgence_beauty/B = A.GetComponent(/datum/component/resurgence_beauty)
			if(B)
				// Sanity check - beauty values should be reasonable (-1000 to +1000)
				if(B.beauty < -1000 || B.beauty > 1000)
					// Log the problematic object for debugging
					log_game("RESURGENCE BEAUTY BUG: [A.type] at [T.x],[T.y],[T.z] has extreme beauty value: [B.beauty]")
					message_admins("RESURGENCE BEAUTY BUG: [A.type] has extreme beauty value: [B.beauty] - skipping")
					continue
				outpost_area.total_resurgence_beauty += B.beauty

	// Update the beauty average
	outpost_area.update_resurgence_beauty()

/**
 * Get a list of all beauty contributors in an area.
 * Returns a list of lists with name, beauty value, and source type.
 *
 * Arguments:
 * * target_area - The area to scan for beauty contributors
 *
 * Returns: List of associative lists with "name", "beauty", "type" keys
 */
/proc/get_area_beauty_breakdown(area/target_area)
	var/list/contributors = list()

	if(!target_area)
		return contributors

	// Only works for resurgence outpost areas
	var/area/resurgence_outpost/outpost_area = target_area
	if(!istype(outpost_area))
		return contributors

	// Track counted objects to avoid duplicates
	var/list/counted = list()

	// Go through all turfs in the area
	for(var/turf/T in outpost_area.contents)
		// Check the turf itself for beauty (carpets)
		var/datum/component/resurgence_beauty/turf_beauty = T.GetComponent(/datum/component/resurgence_beauty)
		if(turf_beauty && turf_beauty.beauty != 0 && !(T in counted))
			counted += T
			contributors += list(list(
				"name" = T.name,
				"beauty" = turf_beauty.beauty,
				"type" = "turf"
			))

		// Check all atoms on this turf
		for(var/atom/A in T.contents)
			if(A in counted)
				continue

			var/datum/component/resurgence_beauty/B = A.GetComponent(/datum/component/resurgence_beauty)
			if(B && B.beauty != 0)
				counted += A
				var/source_type = "object"
				if(ismob(A))
					source_type = "mob"
				else if(isobj(A))
					var/obj/O = A
					if(istype(O, /obj/structure))
						source_type = "structure"
					else if(istype(O, /obj/machinery))
						source_type = "machine"
					else if(istype(O, /obj/item))
						source_type = "item"

				contributors += list(list(
					"name" = A.name,
					"beauty" = B.beauty,
					"type" = source_type
				))

	// Sort by absolute beauty value (highest impact first)
	contributors = sortTim(contributors, GLOBAL_PROC_REF(cmp_beauty_value_desc))

	return contributors

/// Comparison proc for sorting beauty contributors by absolute value (descending)
/proc/cmp_beauty_value_desc(list/a, list/b)
	return abs(b["beauty"]) - abs(a["beauty"])
