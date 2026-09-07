/**
 * Resurgence Outpost - Raid Landmarks
 *
 * Landmark objects for raid spawn points.
 * Place these at map edges where raiders will enter.
 */

/**
 * Raid spawn point landmark.
 * Place at map edges where raiders should spawn.
 */
/obj/effect/landmark/raid_spawn
	name = "raid spawn point"
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x"
	invisibility = INVISIBILITY_ABSTRACT

	/// Unique identifier for this spawn point
	var/spawn_id = "default"

	/// Which faction uses this spawn point
	var/faction_id = "insurgence_clan"

	/// Direction raiders should face when spawning
	var/spawn_dir = SOUTH

/obj/effect/landmark/raid_spawn/Initialize(mapload)
	. = ..()
	GLOB.raid_spawn_points += src

/obj/effect/landmark/raid_spawn/Destroy()
	GLOB.raid_spawn_points -= src
	return ..()

/**
 * Get spawn points for a specific faction.
 *
 * Arguments:
 * * faction_id - The faction ID to filter by
 *
 * Returns: List of spawn points for that faction
 */
/proc/get_raid_spawn_points_for_faction(faction_id)
	var/list/spawns = list()
	for(var/obj/effect/landmark/raid_spawn/S in GLOB.raid_spawn_points)
		if(S.faction_id == faction_id)
			spawns += S
	return spawns

/**
 * Get all raid spawn points.
 *
 * Returns: List of all spawn points
 */
/proc/get_all_raid_spawn_points()
	return GLOB.raid_spawn_points.Copy()

// ==================== Faction-Specific Spawn Points ====================

/// Insurgence Clan spawn point
/obj/effect/landmark/raid_spawn/insurgence
	name = "insurgence raid spawn"
	faction_id = "insurgence_clan"
	spawn_dir = SOUTH

/// Insurgence Clan spawn - north approach
/obj/effect/landmark/raid_spawn/insurgence/north
	spawn_id = "insurgence_north"
	spawn_dir = SOUTH

/// Insurgence Clan spawn - south approach
/obj/effect/landmark/raid_spawn/insurgence/south
	spawn_id = "insurgence_south"
	spawn_dir = NORTH

/// Insurgence Clan spawn - east approach
/obj/effect/landmark/raid_spawn/insurgence/east
	spawn_id = "insurgence_east"
	spawn_dir = WEST

/// Insurgence Clan spawn - west approach
/obj/effect/landmark/raid_spawn/insurgence/west
	spawn_id = "insurgence_west"
	spawn_dir = EAST
