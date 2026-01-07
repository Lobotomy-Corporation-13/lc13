// Expedition Party
// Tracks a group of players traveling together on an expedition

/**
 * Expedition Party
 *
 * Datum representing a group of players embarking on an expedition.
 * Tracks members, route, destination, and state.
 */
/datum/expedition_party
	/// Unique expedition ID
	var/expedition_id
	/// Current expedition state
	var/state = EXPEDITION_FORMING
	/// List of party members
	var/list/mob/living/members = list()
	/// The party leader
	var/mob/living/leader
	/// Destination world tile
	var/datum/world_tile/destination
	/// Current world tile (for tracking position)
	var/datum/world_tile/current_tile
	/// List of world tiles in the route
	var/list/datum/world_tile/route = list()
	/// Total travel cost for the route
	var/route_cost = 0
	/// Time the expedition started
	var/start_time
	/// Time the expedition ended
	var/end_time
	/// The console this expedition departed from (for return teleportation)
	var/obj/structure/world_map_console/departure_console

/// Static counter for expedition IDs
GLOBAL_VAR_INIT(expedition_id_counter, 0)

/datum/expedition_party/New()
	. = ..()
	GLOB.expedition_id_counter++
	expedition_id = GLOB.expedition_id_counter

/datum/expedition_party/Destroy()
	// Remove from global list
	GLOB.active_expeditions -= src
	// Clear references
	for(var/mob/living/M in members)
		unregister_member(M)
	members = null
	leader = null
	destination = null
	current_tile = null
	route = null
	return ..()

/**
 * Set the destination and calculate route
 */
/datum/expedition_party/proc/set_destination(datum/world_tile/dest)
	if(!dest)
		return FALSE
	if(!GLOB.resurgence_world_map)
		return FALSE

	destination = dest

	// Calculate route from outpost to destination
	var/datum/world_tile/outpost = GLOB.resurgence_world_map.outpost_tile
	if(!outpost)
		return FALSE

	route = GLOB.resurgence_world_map.find_path(outpost, dest)
	if(!route || !length(route))
		return FALSE

	// Calculate total travel cost
	route_cost = GLOB.resurgence_world_map.get_path_cost(route)

	return TRUE

/**
 * Add a member to the party
 */
/datum/expedition_party/proc/add_member(mob/living/M)
	if(!M)
		return FALSE
	if(M in members)
		return FALSE
	if(state != EXPEDITION_FORMING)
		return FALSE

	members += M
	RegisterSignal(M, COMSIG_LIVING_DEATH, PROC_REF(on_member_death))
	RegisterSignal(M, COMSIG_PARENT_QDELETING, PROC_REF(on_member_deleted))

	// First member becomes leader
	if(!leader)
		leader = M

	return TRUE

/**
 * Remove a member from the party
 */
/datum/expedition_party/proc/remove_member(mob/living/M)
	if(!M)
		return FALSE
	if(!(M in members))
		return FALSE

	unregister_member(M)
	members -= M

	// If leader left, assign new leader
	if(M == leader)
		leader = null
		if(length(members))
			leader = members[1]

	// If no members left during forming, delete party
	if(!length(members) && state == EXPEDITION_FORMING)
		qdel(src)

	return TRUE

/**
 * Unregister signals from a member
 */
/datum/expedition_party/proc/unregister_member(mob/living/M)
	UnregisterSignal(M, COMSIG_LIVING_DEATH)
	UnregisterSignal(M, COMSIG_PARENT_QDELETING)

/**
 * Handle member death
 */
/datum/expedition_party/proc/on_member_death(mob/living/M)
	SIGNAL_HANDLER

	// Check for party wipe
	check_party_wipe()

/**
 * Handle member deletion
 */
/datum/expedition_party/proc/on_member_deleted(mob/living/M)
	SIGNAL_HANDLER

	members -= M
	if(M == leader)
		leader = length(members) ? members[1] : null

	check_party_wipe()

/**
 * Check if the entire party is dead
 */
/datum/expedition_party/proc/check_party_wipe()
	if(state == EXPEDITION_FORMING || state == EXPEDITION_COMPLETE || state == EXPEDITION_FAILED)
		return

	var/alive_count = 0
	for(var/mob/living/M in members)
		if(M.stat != DEAD)
			alive_count++

	if(alive_count <= 0)
		party_wipe()

/**
 * Handle party wipe
 */
/datum/expedition_party/proc/party_wipe()
	state = EXPEDITION_FAILED
	end_time = world.time

	// TODO: Handle respawning, loot loss, etc.
	for(var/mob/living/M in members)
		if(M.stat == DEAD)
			to_chat(M, span_boldwarning("Your expedition has failed. All party members have fallen."))

	// End the expedition in corridor manager
	if(GLOB.expedition_corridor?.expedition == src)
		GLOB.expedition_corridor.end_expedition()

/**
 * Start the expedition (depart from outpost)
 */
/datum/expedition_party/proc/depart()
	if(state != EXPEDITION_FORMING)
		return FALSE
	if(!length(members))
		return FALSE
	if(!destination || !length(route))
		return FALSE

	// Load corridor if not already loaded
	if(!GLOB.expedition_corridor_loaded)
		load_expedition_corridor()

	// Start expedition in corridor
	if(!GLOB.expedition_corridor)
		return FALSE

	state = EXPEDITION_DEPARTING
	start_time = world.time
	current_tile = GLOB.resurgence_world_map?.outpost_tile

	// Add to active expeditions
	GLOB.active_expeditions += src

	// Start in corridor
	if(!GLOB.expedition_corridor.start_expedition(src))
		state = EXPEDITION_FORMING
		GLOB.active_expeditions -= src
		return FALSE

	return TRUE

/**
 * Get estimated travel time in seconds
 */
/datum/expedition_party/proc/get_estimated_time()
	// Base time per tile: 30 seconds
	// Multiply by route cost
	return route_cost * 30

/**
 * Get formatted travel time string
 */
/datum/expedition_party/proc/get_time_string()
	var/total_seconds = get_estimated_time()
	var/minutes = round(total_seconds / 60)
	var/seconds = total_seconds % 60
	return "[minutes]m [seconds]s"

/**
 * Get UI data for the party
 */
/datum/expedition_party/proc/get_ui_data()
	var/list/data = list()
	data["expedition_id"] = expedition_id
	data["state"] = state
	data["leader"] = leader?.name
	data["member_count"] = length(members)
	data["destination_name"] = destination?.terrain_name
	data["destination_x"] = destination?.x_coord
	data["destination_y"] = destination?.y_coord
	data["route_length"] = length(route)
	data["route_cost"] = route_cost
	data["estimated_time"] = get_time_string()

	var/list/member_data = list()
	for(var/mob/living/M in members)
		member_data += list(list(
			"name" = M.name,
			"is_leader" = (M == leader),
			"health" = M.health,
			"stat" = M.stat
		))
	data["members"] = member_data

	return data
