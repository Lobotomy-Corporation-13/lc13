/**
 * Resurgence Outpost - Raid Manager Subsystem
 *
 * Monitors faction reputation and triggers raids when conditions are met.
 */

SUBSYSTEM_DEF(resurgence_raids)
	name = "Resurgence Raids"
	wait = 1 MINUTES
	flags = SS_BACKGROUND
	runlevels = RUNLEVEL_GAME

	/// List of active raids
	var/list/datum/resurgence_raid/active_raids = list()

	/// Global raid cooldown (world.time when raids can happen again)
	var/raid_cooldown = 0

	/// Whether the raid system is enabled
	var/raids_enabled = TRUE

	/// Minimum round time before raids can occur (30 minutes)
	var/minimum_round_time = 30 MINUTES

	/// Minimum number of rooms required before raids can occur
	var/minimum_room_count = 3

/datum/controller/subsystem/resurgence_raids/Initialize()
	// Set initial cooldown
	raid_cooldown = world.time + minimum_round_time
	return ..()

/datum/controller/subsystem/resurgence_raids/fire(resumed = FALSE)
	if(!raids_enabled)
		return

	// Don't run raids too early in the round
	if(world.time < minimum_round_time)
		return

	// Don't run raids until there are enough rooms
	if(get_outpost_room_count() < minimum_room_count)
		return

	// Clean up completed raids
	clean_completed_raids()

	// Check cooldown
	if(world.time < raid_cooldown)
		return

	// Don't stack too many raids
	if(active_raids.len >= 2)
		return

	// Check faction reputation for raid triggers
	check_faction_raids()

/**
 * Clean up completed raids from the active list.
 */
/datum/controller/subsystem/resurgence_raids/proc/clean_completed_raids()
	for(var/datum/resurgence_raid/raid in active_raids)
		if(raid.raid_state == RAID_STATE_COMPLETE)
			active_raids -= raid
			qdel(raid)

/**
 * Check if any faction should trigger a raid based on reputation.
 */
/datum/controller/subsystem/resurgence_raids/proc/check_faction_raids()
	if(!GLOB.resurgence_trading)
		return

	// For now, only Insurgence Clan sends raids
	var/datum/trading_faction/insurgence = GLOB.resurgence_trading.get_faction("insurgence_clan")
	if(!insurgence)
		return

	// Check if reputation is below threshold
	if(insurgence.reputation >= RAID_REPUTATION_THRESHOLD)
		return

	// Roll for raid chance
	// Lower reputation = higher chance
	var/chance = RAID_BASE_CHANCE + ((RAID_REPUTATION_THRESHOLD - insurgence.reputation) * 2)
	if(!prob(chance))
		return

	// Trigger a raid!
	trigger_raid("insurgence_clan")

/**
 * Trigger a raid from the specified faction.
 *
 * If RAID_USE_CARAVAN_SYSTEM is enabled, this spawns a raid caravan that
 * travels across the world map to the outpost. Otherwise, the raid triggers immediately.
 *
 * Arguments:
 * * faction_id - The faction ID triggering the raid
 * * raid_type - Optional specific raid type (random if not specified)
 *
 * Returns: The raid datum (immediate) or raid caravan (caravan system), or null if failed
 */
/datum/controller/subsystem/resurgence_raids/proc/trigger_raid(faction_id, raid_type = null)
	// Pick raid type if not specified
	if(!raid_type)
		raid_type = pick_raid_type(faction_id)

	// Use caravan system if enabled
#if RAID_USE_CARAVAN_SYSTEM
	return spawn_raid_caravan(faction_id, raid_type)
#else
	return trigger_immediate_raid(faction_id, raid_type)
#endif

/**
 * Spawn a raid caravan that travels to the outpost.
 * The raid will trigger when the caravan arrives.
 *
 * Arguments:
 * * faction_id - The faction ID sending the raid
 * * raid_type - The type of raid the caravan will trigger on arrival
 *
 * Returns: The raid caravan datum, or null if failed
 */
/datum/controller/subsystem/resurgence_raids/proc/spawn_raid_caravan(faction_id, raid_type)
	// Check if there's already a raid caravan en route
	if(length(GLOB.active_raid_caravans))
		log_game("RAID: Cannot spawn raid caravan - one already en route")
		return null

	// Check if world map exists
	if(!GLOB.resurgence_world_map)
		log_game("RAID: Cannot spawn raid caravan - no world map")
		return trigger_immediate_raid(faction_id, raid_type)  // Fall back to immediate

	// Create the raid caravan
	var/datum/raid_caravan/caravan = new(raid_type)

	// Start the journey
	if(!caravan.start_journey())
		qdel(caravan)
		log_game("RAID: Raid caravan failed to start journey")
		return trigger_immediate_raid(faction_id, raid_type)  // Fall back to immediate

	// Set cooldown
	raid_cooldown = world.time + RAID_MINIMUM_COOLDOWN

	log_admin("RAID: Raid caravan spawned for faction [faction_id] with raid type [raid_type]")

	return caravan

/**
 * Trigger a raid immediately (bypasses caravan system).
 * Used as fallback when caravan system fails, or for direct raid triggers.
 *
 * Arguments:
 * * faction_id - The faction ID triggering the raid
 * * raid_type - The raid type
 *
 * Returns: The raid datum, or null if failed
 */
/datum/controller/subsystem/resurgence_raids/proc/trigger_immediate_raid(faction_id, raid_type)
	// Create the raid
	var/datum/resurgence_raid/raid = new(faction_id, raid_type)

	// Try to start it
	if(!raid.start_raid())
		qdel(raid)
		return null

	// Track it
	active_raids += raid

	// Set cooldown
	raid_cooldown = world.time + RAID_MINIMUM_COOLDOWN

	log_admin("RAID: [raid.name] triggered immediately for faction [faction_id]")

	return raid

/**
 * Pick a raid type based on faction and game state.
 *
 * Arguments:
 * * faction_id - The faction ID
 *
 * Returns: A RAID_TYPE_* constant
 */
/datum/controller/subsystem/resurgence_raids/proc/pick_raid_type(faction_id)
	var/list/weights = list()

	// Base weights
	weights[RAID_TYPE_BASIC] = 30
	weights[RAID_TYPE_PILLAGE] = 15
	weights[RAID_TYPE_SIEGE] = 10
	weights[RAID_TYPE_ASSASSINATION] = 10
	weights[RAID_TYPE_OVERWHELMING] = 15

	// Adjust based on game state
	// More pillage raids if outpost has lots of resources
	var/storage_rooms = 0
	for(var/area/resurgence_outpost/room/storage/S in GLOB.sortedAreas)
		if(S.contents.len > 0)
			storage_rooms++
	if(storage_rooms > 0)
		weights[RAID_TYPE_PILLAGE] += storage_rooms * 5

	// More assassination raids later in round
	if(world.time > 30 MINUTES)
		weights[RAID_TYPE_ASSASSINATION] += 10

	// Pick weighted random
	return pickweight(weights)

/**
 * Force trigger a raid immediately (for debug/admin use).
 * This always uses immediate raid, bypassing the caravan system.
 *
 * Arguments:
 * * faction_id - The faction ID
 * * raid_type - The raid type
 * * use_caravan - If TRUE, uses caravan system instead of immediate raid
 *
 * Returns: The raid datum or caravan, or null if failed
 */
/datum/controller/subsystem/resurgence_raids/proc/force_raid(faction_id, raid_type, use_caravan = FALSE)
	if(use_caravan)
		return spawn_raid_caravan(faction_id, raid_type)
	return trigger_immediate_raid(faction_id, raid_type)

/**
 * End all active raids.
 */
/datum/controller/subsystem/resurgence_raids/proc/end_all_raids()
	for(var/datum/resurgence_raid/raid in active_raids)
		raid.end_raid(TRUE)
	active_raids.Cut()

/**
 * Get info about the raid system for debugging.
 */
/datum/controller/subsystem/resurgence_raids/proc/get_debug_info()
	var/list/info = list()
	info["raids_enabled"] = raids_enabled
	info["raid_cooldown"] = raid_cooldown
	info["cooldown_remaining"] = max(0, raid_cooldown - world.time)
	info["active_raids"] = active_raids.len
	info["room_count"] = get_outpost_room_count()
	info["minimum_room_count"] = minimum_room_count
	info["caravan_system_enabled"] = RAID_USE_CARAVAN_SYSTEM

	var/list/raid_info = list()
	for(var/datum/resurgence_raid/raid in active_raids)
		raid_info += list(list(
			"name" = raid.name,
			"state" = raid.raid_state,
			"raiders" = raid.get_alive_raider_count(),
			"initial_raiders" = raid.initial_raider_count
		))
	info["raids"] = raid_info

	// Add raid caravan info
	var/list/caravan_info = list()
	for(var/datum/raid_caravan/caravan in GLOB.active_raid_caravans)
		caravan_info += list(list(
			"id" = caravan.caravan_id,
			"state" = caravan.state,
			"raid_type" = caravan.raid_type,
			"spotted" = caravan.has_been_spotted,
			"position" = "[caravan.current_tile?.x_coord],[caravan.current_tile?.y_coord]",
			"route_progress" = "[caravan.route_index]/[length(caravan.route)]"
		))
	info["raid_caravans"] = caravan_info

	return info

/**
 * Count the number of designated rooms in the outpost.
 * Only counts rooms that have contents (i.e., actual tiles assigned).
 */
/datum/controller/subsystem/resurgence_raids/proc/get_outpost_room_count()
	var/room_count = 0
	for(var/area/resurgence_outpost/room/R in GLOB.sortedAreas)
		if(R.contents.len)
			room_count++
	return room_count
