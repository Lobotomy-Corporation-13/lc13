// Caravan Manager
// Handles caravan spawning, movement coordination, and world map integration

/**
 * Caravan Manager
 *
 * Singleton that manages caravan spawning and lifecycle.
 * Periodically checks if factions should spawn new caravans.
 */
/datum/caravan_manager
	/// Timer ID for spawn check
	var/spawn_timer_id
	/// Whether the manager is active
	var/active = FALSE

/datum/caravan_manager/New()
	. = ..()
	GLOB.caravan_manager = src

/datum/caravan_manager/Destroy()
	stop()
	if(GLOB.caravan_manager == src)
		GLOB.caravan_manager = null
	return ..()

/**
 * Start the caravan spawn system
 */
/datum/caravan_manager/proc/start()
	if(active)
		return
	active = TRUE
	// Do an immediate spawn check so caravans appear right away
	do_spawn_check()
	log_game("Caravan manager started")

/**
 * Stop the caravan spawn system
 */
/datum/caravan_manager/proc/stop()
	active = FALSE
	if(spawn_timer_id)
		deltimer(spawn_timer_id)
		spawn_timer_id = null

/**
 * Schedule the next spawn check
 */
/datum/caravan_manager/proc/schedule_spawn_check()
	if(!active)
		return
	// Check every 5 minutes
	spawn_timer_id = addtimer(CALLBACK(src, PROC_REF(do_spawn_check)), 5 MINUTES, TIMER_STOPPABLE)

/**
 * Check if any factions should spawn caravans
 */
/datum/caravan_manager/proc/do_spawn_check()
	if(!active)
		return

	// Check each trading faction
	var/list/trading_factions = list(
		"resurgence_clan",
		"jiajia_ren",
		"santata_factory",
		"cloud_town"
	)

	for(var/faction_id in trading_factions)
		try_spawn_caravan(faction_id)

	// Check Insurgence patrols separately
	try_spawn_patrol()

	// Schedule next check
	schedule_spawn_check()

	// Update world map UIs
	update_all_world_map_uis()

/**
 * Try to spawn a caravan for a faction
 */
/datum/caravan_manager/proc/try_spawn_caravan(faction_id)
	// Count existing caravans for this faction
	var/count = 0
	for(var/datum/faction_caravan/C in GLOB.active_caravans)
		if(C.faction_id == faction_id)
			count++

	// Check if at max
	if(count >= CARAVAN_MAX_PER_FACTION)
		return

	// Roll for spawn
	if(!prob(CARAVAN_SPAWN_CHANCE))
		return

	// Spawn the caravan
	spawn_caravan(faction_id)

/**
 * Try to spawn an Insurgence patrol
 *
 * NOTE: Insurgence patrols are currently DISABLED.
 * The current implementation causes infighting between hostile and neutral mobs.
 * Future plan: Insurgence will have their own DMM file for hostile ambushes,
 * and will be integrated into the raid system where hostile caravans approach
 * the outpost on the world map before triggering a raid.
 */
/datum/caravan_manager/proc/try_spawn_patrol()
	// DISABLED: Insurgence patrols currently broken (hostile/neutral mob infighting)
	// TODO: Implement hostile caravan system for raids instead
	return

	/*
	// Count existing patrols
	var/count = 0
	for(var/datum/faction_caravan/C in GLOB.active_caravans)
		if(C.faction_id == "insurgence_clan")
			count++

	// Check if at max
	if(count >= CARAVAN_MAX_PATROLS)
		return

	// Roll for spawn (higher chance)
	if(!prob(CARAVAN_PATROL_SPAWN_CHANCE))
		return

	// Spawn the patrol
	spawn_caravan("insurgence_clan")
	*/

/**
 * Spawn a caravan for a faction
 */
/datum/caravan_manager/proc/spawn_caravan(faction_id)
	if(!GLOB.resurgence_world_map)
		return null

	// Get faction's home tile
	var/datum/world_tile/start = GLOB.resurgence_world_map.get_faction_tile(faction_id)
	if(!start)
		return null

	// Pick a destination
	var/datum/world_tile/dest = pick_destination(faction_id, start)
	if(!dest)
		return null

	// Create the caravan
	var/datum/faction_caravan/caravan = new(faction_id)
	if(!caravan.start_journey(start, dest))
		qdel(caravan)
		return null

	log_game("Spawned caravan for [faction_id] heading to ([dest.x_coord],[dest.y_coord])")
	return caravan

/**
 * Pick a valid destination for a caravan
 */
/datum/caravan_manager/proc/pick_destination(faction_id, datum/world_tile/start)
	var/list/candidates = list()

	// Option 1: Another faction's hub
	for(var/datum/world_tile/ft in GLOB.resurgence_world_map.faction_tiles)
		if(ft.faction_id != faction_id && ft != start)
			// Insurgence doesn't trade with others
			if(faction_id == "insurgence_clan" || ft.faction_id == "insurgence_clan")
				continue
			candidates += ft

	// Option 2: The player outpost (friendly factions only)
	if(faction_id != "insurgence_clan")
		var/datum/world_tile/outpost = GLOB.resurgence_world_map.outpost_tile
		if(outpost && outpost != start)
			candidates += outpost

	// Option 3: Random discovered tile (for patrols)
	if(faction_id == "insurgence_clan")
		for(var/x in 1 to GLOB.resurgence_world_map.map_width)
			for(var/y in 1 to GLOB.resurgence_world_map.map_height)
				var/datum/world_tile/tile = GLOB.resurgence_world_map.tiles[x][y]
				if(tile.discovered && tile != start && tile.terrain_type != TERRAIN_OUTPOST)
					if(prob(20)) // Don't add every tile, just some
						candidates += tile

	if(!length(candidates))
		return null

	return pick(candidates)

/**
 * Get caravan on a specific tile
 */
/datum/caravan_manager/proc/get_caravan_on_tile(datum/world_tile/tile)
	if(!tile)
		return null
	return tile.caravan

/**
 * Check if a tile has a caravan
 */
/datum/caravan_manager/proc/tile_has_caravan(datum/world_tile/tile)
	return tile?.caravan != null

/**
 * Get all caravans visible on discovered tiles
 */
/datum/caravan_manager/proc/get_visible_caravans()
	var/list/visible = list()
	for(var/datum/faction_caravan/C in GLOB.active_caravans)
		if(C.current_tile?.discovered)
			visible += C
	return visible

/**
 * Get UI data for all visible caravans
 */
/datum/caravan_manager/proc/get_caravans_ui_data()
	var/list/data = list()
	for(var/datum/faction_caravan/C in GLOB.active_caravans)
		// Only show caravans on discovered tiles or in debug mode
		if(C.current_tile?.discovered || GLOB.resurgence_world_map?.debug_mode)
			data += list(C.get_ui_data())
	return data

// ============================================
// INITIALIZATION
// ============================================

/**
 * Initialize the caravan system
 * Called after world map is generated
 */
/proc/init_caravan_system()
	if(GLOB.caravan_manager)
		return GLOB.caravan_manager

	GLOB.caravan_manager = new /datum/caravan_manager()
	GLOB.caravan_manager.start()
	return GLOB.caravan_manager
