// Expedition Corridor Manager
// Manages the single reusable corridor that transforms between terrain types

/**
 * Expedition Corridor Manager
 *
 * Singleton datum that manages the expedition corridor.
 * Handles terrain transformation, player teleportation, and transition logic.
 */
/datum/expedition_corridor_manager
	/// The current expedition party using the corridor
	var/datum/expedition_party/expedition
	/// Current index in the expedition route
	var/route_index = 0
	/// List of all floor turfs in the corridor
	var/list/turf/open/floor/expedition/floor_turfs = list()
	/// List of all wall turfs in the corridor
	var/list/turf/closed/wall/expedition/wall_turfs = list()
	/// Reference to the start landmark
	var/obj/effect/landmark/expedition_start/start_landmark
	/// Reference to the event landmark
	var/obj/effect/landmark/expedition_event/event_landmark
	/// Reference to the end landmark
	var/obj/effect/landmark/expedition_end/end_landmark
	/// Current terrain type being displayed
	var/current_terrain = TERRAIN_PLAINS
	/// Whether an event has been triggered this leg
	var/event_triggered = FALSE
	/// Whether the event has been completed this leg
	var/event_completed = FALSE
	/// Whether a transition is currently in progress
	var/transitioning = FALSE

/datum/expedition_corridor_manager/New()
	. = ..()

/datum/expedition_corridor_manager/Destroy()
	floor_turfs = null
	wall_turfs = null
	start_landmark = null
	event_landmark = null
	end_landmark = null
	expedition = null
	return ..()

/**
 * Initialize the corridor by finding all turfs and landmarks
 */
/datum/expedition_corridor_manager/proc/initialize_corridor()
	if(!GLOB.expedition_corridor_z)
		CRASH("Expedition corridor z-level not set")

	var/z_level = GLOB.expedition_corridor_z

	// Find all corridor turfs on the expedition z-level
	for(var/turf/T in block(locate(1, 1, z_level), locate(world.maxx, world.maxy, z_level)))
		if(istype(T, /turf/open/floor/expedition))
			var/turf/open/floor/expedition/ET = T
			floor_turfs += ET
		else if(istype(T, /turf/closed/wall/expedition))
			var/turf/closed/wall/expedition/WT = T
			wall_turfs += WT

		// Also check turf contents for landmarks
		// Set manager on ALL landmarks found, not just one
		for(var/obj/effect/landmark/L in T.contents)
			if(istype(L, /obj/effect/landmark/expedition_start))
				var/obj/effect/landmark/expedition_start/SL = L
				if(!start_landmark)
					start_landmark = SL
				SL.manager = src
			else if(istype(L, /obj/effect/landmark/expedition_event))
				var/obj/effect/landmark/expedition_event/EL = L
				if(!event_landmark)
					event_landmark = EL
				EL.manager = src
			else if(istype(L, /obj/effect/landmark/expedition_end))
				var/obj/effect/landmark/expedition_end/NL = L
				if(!end_landmark)
					end_landmark = NL
				NL.manager = src

	// Log what we found
	log_game("Expedition corridor initialized on z-level [z_level]:")
	log_game("  - [length(floor_turfs)] floor turfs")
	log_game("  - [length(wall_turfs)] wall turfs")
	log_game("  - Start landmark: [start_landmark ? "FOUND" : "NOT FOUND"]")
	log_game("  - Event landmark: [event_landmark ? "FOUND" : "NOT FOUND"]")
	log_game("  - End landmark: [end_landmark ? "FOUND" : "NOT FOUND"]")

/**
 * Register a floor turf (called from turf Initialize)
 */
/datum/expedition_corridor_manager/proc/register_floor_turf(turf/open/floor/expedition/T)
	floor_turfs |= T

/**
 * Register a wall turf (called from turf Initialize)
 */
/datum/expedition_corridor_manager/proc/register_wall_turf(turf/closed/wall/expedition/T)
	wall_turfs |= T

/**
 * Prepare the corridor for a specific terrain type
 * Updates all turfs and decorations
 */
/datum/expedition_corridor_manager/proc/prepare_for_terrain(terrain_type)
	current_terrain = terrain_type

	// Update all floor turfs
	for(var/turf/open/floor/expedition/T in floor_turfs)
		T.set_terrain(terrain_type)

	// Update all wall turfs
	for(var/turf/closed/wall/expedition/T in wall_turfs)
		T.set_terrain(terrain_type)

	// Clear and spawn decorations
	update_decorations(terrain_type)

	// Reset event state
	event_triggered = FALSE
	event_completed = FALSE
	transitioning = FALSE

	// Reset landmarks
	if(event_landmark)
		event_landmark.unblock()
	if(end_landmark)
		end_landmark.reset()

/**
 * Clear existing decorations and spawn new ones for the terrain
 */
/datum/expedition_corridor_manager/proc/update_decorations(terrain_type)
	// Remove existing decorations
	for(var/turf/T in floor_turfs)
		for(var/obj/structure/flora/expedition/F in T)
			qdel(F)

	// Get decoration types for this terrain
	var/list/deco_types = GLOB.expedition_decorations[terrain_type]
	if(!deco_types || !length(deco_types))
		return

	// Spawn new decorations on edge tiles only (marked with is_path = FALSE)
	for(var/turf/open/floor/expedition/T in floor_turfs)
		if(!T.is_path && prob(15))  // 15% chance per edge tile
			var/deco_type = pick(deco_types)
			new deco_type(T)

/**
 * Start an expedition in the corridor
 */
/datum/expedition_corridor_manager/proc/start_expedition(datum/expedition_party/party)
	if(!party || !length(party.route))
		log_game("Expedition start failed: No party or empty route")
		return FALSE

	// Verify corridor is ready
	if(!length(floor_turfs))
		log_game("Expedition start failed: No floor turfs found in corridor")
		return FALSE

	expedition = party
	route_index = 0

	// Debug: Log the route
	var/list/route_debug = list()
	for(var/datum/world_tile/tile in party.route)
		route_debug += "[GLOB.terrain_names[tile.terrain_type] || tile.terrain_type]"
	log_game("start_expedition: route = [route_debug.Join(" -> ")]")

	// Get the first terrain from route (skip outpost tile)
	var/datum/world_tile/first_tile = party.route[2]  // Index 1 is outpost, 2 is first travel tile
	if(!first_tile)
		log_game("Expedition start failed: No first tile in route")
		return FALSE

	var/terrain = first_tile.terrain_type
	// If it's a faction tile, use the underlying terrain or plains
	if(terrain == TERRAIN_FACTION || terrain == TERRAIN_OUTPOST)
		terrain = TERRAIN_PLAINS

	log_game("start_expedition: first_terrain=[GLOB.terrain_names[terrain] || terrain]")

	// Prepare corridor for first terrain
	prepare_for_terrain(terrain)

	// Find start turf - prefer landmark, fall back to first floor turf
	var/turf/start_turf = get_turf(start_landmark)
	if(!start_turf)
		log_game("Expedition: Start landmark not found, using fallback")
		// Use the first floor turf as fallback
		if(length(floor_turfs))
			start_turf = floor_turfs[1]

	if(!start_turf)
		log_game("Expedition start failed: Could not find valid start turf")
		return FALSE

	log_game("Expedition starting at turf: [start_turf] ([start_turf.x], [start_turf.y], [start_turf.z])")

	// Build terrain list for the journey (skip outpost at index 1)
	var/list/journey_terrains = list()
	for(var/i in 2 to length(party.route))
		var/datum/world_tile/tile = party.route[i]
		var/tname = GLOB.terrain_names[tile.terrain_type] || tile.terrain_type
		journey_terrains += tname

	for(var/mob/living/M in party.members)
		// Apply terrain movement speed modifier
		apply_terrain_speed(M, terrain)
		// Give them a map device if they don't have one
		give_map_device(M)
		// Teleport to start
		M.forceMove(start_turf)
		// Tell them the route
		if(length(journey_terrains))
			to_chat(M, span_notice("Your expedition begins. Route: [journey_terrains.Join(" -> ")]"))
		else
			to_chat(M, span_notice("Your expedition begins. Travel through [GLOB.terrain_names[terrain]] territory..."))

	party.state = EXPEDITION_TRAVELING
	return TRUE

/**
 * Give a mob an expedition map device if they don't have one
 */
/datum/expedition_corridor_manager/proc/give_map_device(mob/living/M)
	// Check if they already have one
	for(var/obj/item/expedition_map/existing in M.contents)
		return // Already has one

	// Create and give them a map device
	var/obj/item/expedition_map/device = new(M)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(!H.put_in_hands(device))
			device.forceMove(get_turf(H))

/**
 * Apply movement speed modifier based on terrain
 */
/datum/expedition_corridor_manager/proc/apply_terrain_speed(mob/living/M, terrain_type)
	// Remove existing expedition speed modifier
	M.remove_movespeed_modifier(/datum/movespeed_modifier/expedition_terrain)

	// Get slowdown for terrain
	var/slowdown = GLOB.terrain_speed_modifiers[terrain_type]
	if(slowdown > 0)
		M.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/expedition_terrain, multiplicative_slowdown = slowdown)

/**
 * Remove terrain speed modifier
 */
/datum/expedition_corridor_manager/proc/remove_terrain_speed(mob/living/M)
	M.remove_movespeed_modifier(/datum/movespeed_modifier/expedition_terrain)

/**
 * Begin transition to next terrain/destination
 */
/datum/expedition_corridor_manager/proc/begin_transition()
	if(transitioning)
		return
	transitioning = TRUE

	// Advance route index
	route_index++

	// Check if we've reached the destination
	if(route_index >= (length(expedition.route) - 1))
		arrive_at_destination()
		return

	// Get next terrain
	var/datum/world_tile/next_tile = expedition.route[route_index + 2]  // +2 because index 1 is start position
	if(!next_tile)
		arrive_at_destination()
		return

	var/next_terrain = next_tile.terrain_type
	if(next_terrain == TERRAIN_FACTION || next_terrain == TERRAIN_OUTPOST)
		next_terrain = TERRAIN_PLAINS

	// Debug: Log the transition
	log_game("begin_transition: route_index=[route_index], next_tile index=[route_index + 2], next_terrain=[GLOB.terrain_names[next_terrain] || next_terrain]")

	// Fade out all players
	for(var/mob/living/M in expedition.members)
		fade_to_black(M)

	// Wait for fade, then execute transition
	addtimer(CALLBACK(src, PROC_REF(execute_transition), next_terrain), EXPEDITION_FADE_TIME + EXPEDITION_BLACK_TIME)

/**
 * Fade a player's screen to black
 */
/datum/expedition_corridor_manager/proc/fade_to_black(mob/living/M)
	if(!M.client)
		return
	var/client/C = M.client
	C.color = "#000000"

/**
 * Fade a player's screen back in from black
 */
/datum/expedition_corridor_manager/proc/fade_from_black(mob/living/M)
	if(!M.client)
		return
	var/client/C = M.client
	animate(C, color = null, time = EXPEDITION_FADE_TIME)

/**
 * Execute the terrain transition
 */
/datum/expedition_corridor_manager/proc/execute_transition(next_terrain)
	// Collect all items on floor (that aren't decorations or barriers)
	var/list/floor_items = list()
	for(var/turf/T in floor_turfs)
		for(var/obj/item/I in T)
			floor_items += I

	// Get start position
	var/turf/start_turf = get_turf(start_landmark)
	if(!start_turf)
		start_turf = locate(EXPEDITION_CORRIDOR_WIDTH / 2, EXPEDITION_START_Y + 1, GLOB.expedition_corridor_z)

	// Teleport all players to start
	for(var/mob/living/M in expedition.members)
		M.forceMove(start_turf)
		// Update speed modifier for new terrain
		apply_terrain_speed(M, next_terrain)

	// Teleport all items to start area (spread them out a bit)
	var/item_offset = 0
	for(var/obj/item/I in floor_items)
		var/turf/item_dest = locate(start_turf.x + (item_offset % 3) - 1, start_turf.y + round(item_offset / 3), start_turf.z)
		I.forceMove(item_dest)
		item_offset++

	// Update terrain
	prepare_for_terrain(next_terrain)

	// Fade back in for all players
	for(var/mob/living/M in expedition.members)
		fade_from_black(M)
		to_chat(M, span_notice("You continue into [GLOB.terrain_names[next_terrain]] territory..."))

	// Update current position for map tracking
	expedition.current_tile = expedition.route[route_index + 2]

	// Update world map discovery
	if(expedition.current_tile && GLOB.resurgence_world_map)
		GLOB.resurgence_world_map.discover_radius(expedition.current_tile, VISIT_DISCOVERY_RADIUS)

	transitioning = FALSE

/**
 * Handle arrival at the final destination
 */
/datum/expedition_corridor_manager/proc/arrive_at_destination()
	if(!expedition)
		return

	// Fade out players
	for(var/mob/living/M in expedition.members)
		fade_to_black(M)

	addtimer(CALLBACK(src, PROC_REF(execute_arrival)), EXPEDITION_FADE_TIME + EXPEDITION_BLACK_TIME)

/**
 * Execute arrival at destination
 */
/datum/expedition_corridor_manager/proc/execute_arrival()
	var/datum/world_tile/dest_tile = expedition.destination
	if(!dest_tile)
		// No destination? Return to outpost
		return_to_outpost()
		return

	// Update current position to destination
	expedition.current_tile = dest_tile

	// Check if returning to outpost
	if(dest_tile == GLOB.resurgence_world_map?.outpost_tile)
		return_to_outpost()
		return

	// Check if destination is a faction
	if(dest_tile.faction_id)
		arrive_at_faction_hub(dest_tile)
	else
		// Non-faction destination - just mark as arrived
		for(var/mob/living/M in expedition.members)
			to_chat(M, span_notice("You arrive at your destination: [dest_tile.terrain_name]."))
			to_chat(M, span_notice("Use your expedition map device to set a new destination or return to the outpost."))
			remove_terrain_speed(M)
			fade_from_black(M)

		expedition.state = EXPEDITION_AT_DESTINATION

	// Discover destination tile
	if(GLOB.resurgence_world_map)
		GLOB.resurgence_world_map.discover_radius(dest_tile, VISIT_DISCOVERY_RADIUS)

/**
 * Handle arrival at a faction hub
 */
/datum/expedition_corridor_manager/proc/arrive_at_faction_hub(datum/world_tile/dest_tile)
	var/faction_id = dest_tile.faction_id
	if(!faction_id)
		return

	// Get or create the faction hub controller
	var/datum/faction_hub_controller/hub = get_faction_hub(faction_id)
	if(!hub)
		log_game("Could not get faction hub controller for [faction_id]")
		// Fall back to basic arrival
		for(var/mob/living/M in expedition.members)
			to_chat(M, span_notice("You arrive at [dest_tile.terrain_name]."))
			remove_terrain_speed(M)
			fade_from_black(M)
		expedition.state = EXPEDITION_AT_DESTINATION
		return

	// Check if hub has a spawn point
	if(!hub.spawn_point)
		log_game("Faction hub [faction_id] has no spawn point - hub map may not be loaded")
		// Fall back to basic arrival message
		for(var/mob/living/M in expedition.members)
			to_chat(M, span_notice("You arrive at [dest_tile.terrain_name]. (Hub area not available)"))
			to_chat(M, span_notice("Use your expedition map device to set a new destination."))
			remove_terrain_speed(M)
			fade_from_black(M)
		expedition.state = EXPEDITION_AT_DESTINATION
		return

	// Teleport all expedition members to the hub
	for(var/mob/living/M in expedition.members)
		remove_terrain_speed(M)
		hub.player_arrived(M, expedition)
		fade_from_black(M)

	expedition.state = EXPEDITION_AT_DESTINATION
	log_game("Expedition arrived at faction hub: [faction_id]")

/**
 * Return the expedition to the outpost
 */
/datum/expedition_corridor_manager/proc/return_to_outpost()
	if(!expedition)
		return

	// Find return location - near the departure console
	var/turf/return_turf
	if(expedition.departure_console)
		return_turf = get_turf(expedition.departure_console)
		// Try to find an adjacent open turf
		for(var/dir in GLOB.cardinals)
			var/turf/T = get_step(return_turf, dir)
			if(T && !T.density)
				return_turf = T
				break

	// Teleport and notify all members
	for(var/mob/living/M in expedition.members)
		to_chat(M, span_notice("You return safely to the outpost."))
		remove_terrain_speed(M)
		fade_from_black(M)
		if(return_turf)
			M.forceMove(return_turf)

	expedition.state = EXPEDITION_COMPLETE
	expedition.end_time = world.time
	end_expedition()

/**
 * Continue an expedition with a new route (after setting new destination)
 */
/datum/expedition_corridor_manager/proc/continue_expedition(datum/expedition_party/party)
	if(!party || !length(party.route))
		return FALSE

	// Make sure this is our current expedition or take over
	if(expedition && expedition != party)
		return FALSE

	expedition = party
	route_index = 0

	// Get first terrain from new route
	var/datum/world_tile/first_tile = party.route[min(2, length(party.route))]
	if(!first_tile)
		first_tile = party.route[1]

	var/terrain = first_tile.terrain_type
	if(terrain == TERRAIN_FACTION || terrain == TERRAIN_OUTPOST)
		terrain = TERRAIN_PLAINS

	// Debug: Log what we're about to do
	log_game("continue_expedition: route_index=[route_index], route_length=[length(party.route)], first_terrain=[GLOB.terrain_names[terrain] || terrain]")

	// Fade out, prepare terrain, teleport to start
	for(var/mob/living/M in party.members)
		fade_to_black(M)

	addtimer(CALLBACK(src, PROC_REF(execute_continue), party, terrain), EXPEDITION_FADE_TIME + EXPEDITION_BLACK_TIME)

	return TRUE

/**
 * Execute the continuation after fade
 */
/datum/expedition_corridor_manager/proc/execute_continue(datum/expedition_party/party, terrain)
	// Get start position
	var/turf/start_turf = get_turf(start_landmark)
	if(!start_turf)
		start_turf = locate(EXPEDITION_CORRIDOR_WIDTH / 2, EXPEDITION_START_Y + 1, GLOB.expedition_corridor_z)

	// Update current tile to first position in new route
	if(length(party.route) >= 1)
		party.current_tile = party.route[1]

	// Teleport all players to start
	for(var/mob/living/M in party.members)
		M.forceMove(start_turf)
		apply_terrain_speed(M, terrain)

	// Update terrain
	prepare_for_terrain(terrain)

	// Update state
	party.state = EXPEDITION_TRAVELING

	// Fade back in
	for(var/mob/living/M in party.members)
		fade_from_black(M)
		to_chat(M, span_notice("You continue your journey through [GLOB.terrain_names[terrain]] territory..."))

/**
 * End the current expedition and clean up
 */
/datum/expedition_corridor_manager/proc/end_expedition()
	if(!expedition)
		return

	GLOB.active_expeditions -= expedition
	expedition = null
	route_index = 0
	transitioning = FALSE

// ============================================
// MOVEMENT SPEED MODIFIER
// ============================================

/datum/movespeed_modifier/expedition_terrain
	variable = TRUE
	multiplicative_slowdown = 0  // Set dynamically based on terrain
