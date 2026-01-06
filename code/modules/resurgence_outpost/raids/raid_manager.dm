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

	/// Minimum round time before raids can occur (5 minutes)
	var/minimum_round_time = 5 MINUTES

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
 * Arguments:
 * * faction_id - The faction ID triggering the raid
 * * raid_type - Optional specific raid type (random if not specified)
 *
 * Returns: The raid datum, or null if failed
 */
/datum/controller/subsystem/resurgence_raids/proc/trigger_raid(faction_id, raid_type = null)
	// Pick raid type if not specified
	if(!raid_type)
		raid_type = pick_raid_type(faction_id)

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

	log_admin("RAID: [raid.name] triggered for faction [faction_id]")

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
	weights[RAID_TYPE_DELAYED] = 20
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
 *
 * Arguments:
 * * faction_id - The faction ID
 * * raid_type - The raid type
 *
 * Returns: The raid datum, or null if failed
 */
/datum/controller/subsystem/resurgence_raids/proc/force_raid(faction_id, raid_type)
	return trigger_raid(faction_id, raid_type)

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

	var/list/raid_info = list()
	for(var/datum/resurgence_raid/raid in active_raids)
		raid_info += list(list(
			"name" = raid.name,
			"state" = raid.raid_state,
			"raiders" = raid.get_alive_raider_count(),
			"initial_raiders" = raid.initial_raider_count
		))
	info["raids"] = raid_info

	return info
