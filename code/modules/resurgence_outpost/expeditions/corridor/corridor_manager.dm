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
	// If it's a faction tile, use the faction's required terrain or plains
	if(terrain == TERRAIN_FACTION || terrain == TERRAIN_OUTPOST)
		terrain = get_faction_terrain(first_tile.faction_id)

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

	// Collect crates near the departure console to bring on the expedition
	var/list/departure_crates = list()
	if(party.departure_console)
		for(var/obj/structure/closet/crate/C in range(3, party.departure_console))
			departure_crates += C

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

	// Teleport crates from departure area to corridor start (on the start landmark turf)
	if(length(departure_crates))
		for(var/obj/structure/closet/crate/C in departure_crates)
			C.forceMove(start_turf)
		// Notify party about crates
		for(var/mob/living/M in party.members)
			to_chat(M, span_notice("[length(departure_crates)] crate(s) have been brought along on this expedition."))

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
	if(expedition?.state == EXPEDITION_STOPPED)
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
	// For faction/outpost tiles, use the faction's required terrain or fallback to plains
	if(next_terrain == TERRAIN_FACTION || next_terrain == TERRAIN_OUTPOST)
		next_terrain = get_faction_terrain(next_tile.faction_id)

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
	// Get the next tile for caravan check
	var/datum/world_tile/next_tile = expedition.route[route_index + 2]

	// Check for caravan on next tile BEFORE normal transition (including waiting caravans)
	if(next_tile?.caravan && next_tile.caravan.state != CARAVAN_DESTROYED && next_tile.caravan.state != CARAVAN_COMPLETE)
		start_caravan_encounter(next_tile.caravan)
		return

	// Check for raid caravan on next tile - offer intercept
	if(next_tile?.raid_caravan)
		offer_raid_intercept(next_tile.raid_caravan)
		return

	// Collect all items on floor (that aren't decorations or barriers)
	var/list/floor_items = list()
	for(var/turf/T in floor_turfs)
		for(var/obj/item/I in T)
			floor_items += I

	// Collect all crates on floor for transport
	var/list/floor_crates = list()
	for(var/turf/T in floor_turfs)
		for(var/obj/structure/closet/crate/C in T)
			floor_crates += C

	// Get start position
	var/turf/start_turf = get_turf(start_landmark)
	if(!start_turf)
		start_turf = locate(EXPEDITION_CORRIDOR_WIDTH / 2, EXPEDITION_START_Y + 1, GLOB.expedition_corridor_z)

	// Teleport all players to start
	for(var/mob/living/M in expedition.members)
		M.forceMove(start_turf)
		// Update speed modifier for new terrain
		apply_terrain_speed(M, next_terrain)

	// Teleport all items to start turf (landmark location)
	for(var/obj/item/I in floor_items)
		I.forceMove(start_turf)

	// Teleport all crates to start turf (landmark location)
	for(var/obj/structure/closet/crate/C in floor_crates)
		C.forceMove(start_turf)

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
		update_all_world_map_uis()

	transitioning = FALSE

/**
 * Stop the expedition mid-travel at the current tile
 * Called from the portable map device when the player wants to halt
 */
/datum/expedition_corridor_manager/proc/stop_expedition()
	if(!expedition || transitioning)
		return FALSE
	expedition.state = EXPEDITION_STOPPED
	// expedition.current_tile is already updated each transition
	for(var/mob/living/M in expedition.members)
		to_chat(M, span_notice("The expedition has stopped. Use the map device to plan a new route."))
	return TRUE

/**
 * Start a caravan encounter
 * Called when the expedition enters a tile with a caravan
 */
/datum/expedition_corridor_manager/proc/start_caravan_encounter(datum/faction_caravan/caravan)
	if(!caravan || !expedition)
		return FALSE

	log_game("Expedition [expedition.expedition_id] encountered caravan [caravan.caravan_id] ([caravan.name])")

	// Stop the caravan
	caravan.stop_for_encounter()

	// Update current position
	expedition.current_tile = caravan.current_tile

	// Load caravan encounter area if not loaded
	if(!GLOB.caravan_encounter_loaded)
		if(!load_caravan_encounter())
			// Failed to load - continue normal travel instead
			log_game("Failed to load caravan encounter area, continuing normal travel")
			var/next_terrain = caravan.current_tile.terrain_type
			if(next_terrain == TERRAIN_FACTION || next_terrain == TERRAIN_OUTPOST)
				next_terrain = get_faction_terrain(caravan.current_tile.faction_id)
			execute_transition_continue(next_terrain)
			return FALSE

	// Create encounter controller
	var/datum/caravan_encounter_controller/controller = new(caravan, expedition)

	// Notify players about the encounter
	for(var/mob/living/M in expedition.members)
		if(caravan.is_hostile())
			to_chat(M, span_boldwarning("You've encountered a hostile [caravan.name]!"))
		else
			to_chat(M, span_boldnotice("You've encountered a [caravan.name] from [caravan.owner_faction?.name || "unknown faction"]!"))

	// Start the encounter (teleport players to encounter area)
	if(!controller.start_encounter())
		log_game("Failed to start caravan encounter")
		qdel(controller)
		// Continue normal travel
		var/next_terrain = caravan.current_tile.terrain_type
		if(next_terrain == TERRAIN_FACTION || next_terrain == TERRAIN_OUTPOST)
			next_terrain = get_faction_terrain(caravan.current_tile.faction_id)
		execute_transition_continue(next_terrain)
		return FALSE

	transitioning = FALSE
	return TRUE

/**
 * Offer the expedition leader a choice to intercept a raid caravan
 */
/datum/expedition_corridor_manager/proc/offer_raid_intercept(datum/raid_caravan/raid_caravan)
	if(!raid_caravan || !expedition)
		// No raid caravan, continue normal transition
		var/datum/world_tile/next_tile = expedition.route[route_index + 2]
		var/next_terrain = next_tile?.terrain_type || TERRAIN_PLAINS
		if(next_terrain == TERRAIN_FACTION || next_terrain == TERRAIN_OUTPOST)
			next_terrain = get_faction_terrain(next_tile?.faction_id)
		execute_transition_continue(next_terrain)
		return

	log_game("Expedition [expedition.expedition_id] encountered raid caravan [raid_caravan.caravan_id]")

	// Fade players back in so they can see the popup
	for(var/mob/living/M in expedition.members)
		fade_from_black(M)

	// Get the expedition leader
	var/mob/living/leader = expedition.leader
	if(!leader?.client)
		// No leader, skip intercept
		to_chat(expedition.members, span_warning("You spot a hostile Insurgence raiding party, but have no leader to decide whether to engage..."))
		var/datum/world_tile/next_tile = expedition.route[route_index + 2]
		var/next_terrain = next_tile?.terrain_type || TERRAIN_PLAINS
		if(next_terrain == TERRAIN_FACTION || next_terrain == TERRAIN_OUTPOST)
			next_terrain = get_faction_terrain(next_tile?.faction_id)
		execute_transition_continue(next_terrain)
		return

	// Show intercept choice via tgui_alert
	var/choice = tgui_alert(leader, "A hostile Insurgence raiding party is on this tile! They are heading toward your outpost.\n\nDo you want to intercept them?", "HOSTILE RAIDERS DETECTED", list("Intercept", "Avoid"))

	if(choice == "Intercept")
		start_raid_intercept(raid_caravan)
	else
		to_chat(expedition.members, span_warning("The expedition avoids the raiding party... They continue toward your outpost."))
		var/datum/world_tile/next_tile = expedition.route[route_index + 2]
		var/next_terrain = next_tile?.terrain_type || TERRAIN_PLAINS
		if(next_terrain == TERRAIN_FACTION || next_terrain == TERRAIN_OUTPOST)
			next_terrain = get_faction_terrain(next_tile?.faction_id)
		execute_transition_continue(next_terrain)

/**
 * Start the raid intercept encounter
 */
/datum/expedition_corridor_manager/proc/start_raid_intercept(datum/raid_caravan/raid_caravan)
	if(!raid_caravan || !expedition)
		return FALSE

	// Notify players
	for(var/mob/living/M in expedition.members)
		to_chat(M, span_boldwarning("You engage the Insurgence raiding party!"))

	// Create the intercept controller
	var/datum/raid_intercept_controller/controller = new(raid_caravan, expedition)

	// Start the intercept encounter
	if(!controller.start_intercept())
		to_chat(expedition.members, span_warning("Failed to initiate intercept! The raiders continue on..."))
		qdel(controller)
		// Continue normal transition
		var/datum/world_tile/next_tile = expedition.route[route_index + 2]
		var/next_terrain = next_tile?.terrain_type || TERRAIN_PLAINS
		if(next_terrain == TERRAIN_FACTION || next_terrain == TERRAIN_OUTPOST)
			next_terrain = get_faction_terrain(next_tile?.faction_id)
		execute_transition_continue(next_terrain)
		return FALSE

	transitioning = FALSE
	return TRUE

/**
 * Continue transition after caravan check failed
 */
/datum/expedition_corridor_manager/proc/execute_transition_continue(next_terrain)
	// Collect all crates on floor for transport
	var/list/floor_crates = list()
	for(var/turf/T in floor_turfs)
		for(var/obj/structure/closet/crate/C in T)
			floor_crates += C

	// Get start position
	var/turf/start_turf = get_turf(start_landmark)
	if(!start_turf)
		start_turf = locate(EXPEDITION_CORRIDOR_WIDTH / 2, EXPEDITION_START_Y + 1, GLOB.expedition_corridor_z)

	// Teleport all players to start
	for(var/mob/living/M in expedition.members)
		M.forceMove(start_turf)
		apply_terrain_speed(M, next_terrain)

	// Teleport all crates to start turf (landmark location)
	for(var/obj/structure/closet/crate/C in floor_crates)
		C.forceMove(start_turf)

	// Update terrain
	prepare_for_terrain(next_terrain)

	// Fade back in
	for(var/mob/living/M in expedition.members)
		fade_from_black(M)
		to_chat(M, span_notice("You continue into [GLOB.terrain_names[next_terrain]] territory..."))

	// Update current position
	expedition.current_tile = expedition.route[route_index + 2]

	// Update world map discovery
	if(expedition.current_tile && GLOB.resurgence_world_map)
		GLOB.resurgence_world_map.discover_radius(expedition.current_tile, VISIT_DISCOVERY_RADIUS)
		update_all_world_map_uis()

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
		update_all_world_map_uis()

/**
 * Handle arrival at a faction hub
 */
/datum/expedition_corridor_manager/proc/arrive_at_faction_hub(datum/world_tile/dest_tile)
	var/faction_id = dest_tile.faction_id
	if(!faction_id)
		return

	// Ensure the hub map is loaded and ready
	if(!ensure_faction_hub_ready(faction_id))
		log_game("Could not load or initialize faction hub for [faction_id]")
		// Fall back to basic arrival
		for(var/mob/living/M in expedition.members)
			to_chat(M, span_notice("You arrive at [dest_tile.terrain_name]. (Hub area not available)"))
			to_chat(M, span_notice("Use your expedition map device to set a new destination."))
			remove_terrain_speed(M)
			fade_from_black(M)
		expedition.state = EXPEDITION_AT_DESTINATION
		return

	// Get the faction hub controller
	var/datum/faction_hub_controller/hub = get_faction_hub(faction_id)
	if(!hub || !hub.spawn_point)
		log_game("Faction hub [faction_id] not properly initialized")
		// Fall back to basic arrival message
		for(var/mob/living/M in expedition.members)
			to_chat(M, span_notice("You arrive at [dest_tile.terrain_name]. (Hub area not available)"))
			to_chat(M, span_notice("Use your expedition map device to set a new destination."))
			remove_terrain_speed(M)
			fade_from_black(M)
		expedition.state = EXPEDITION_AT_DESTINATION
		return

	// Mark faction as discovered and visited for remote trading
	if(GLOB.resurgence_trading)
		var/datum/trading_faction/faction = GLOB.resurgence_trading.get_faction(faction_id)
		if(faction)
			var/first_visit = !faction.visited
			faction.discovered = TRUE
			faction.visited = TRUE
			if(first_visit)
				log_game("Faction [faction_id] visited for the first time - remote trading unlocked")
				for(var/mob/living/M in expedition.members)
					to_chat(M, span_notice("You have established contact with [faction.name]. Remote trading is now available."))

	// Collect all crates from the corridor
	var/list/floor_crates = list()
	for(var/turf/T in floor_turfs)
		for(var/obj/structure/closet/crate/C in T)
			floor_crates += C

	// Teleport all expedition members to the hub
	for(var/mob/living/M in expedition.members)
		remove_terrain_speed(M)
		hub.player_arrived(M, expedition)
		fade_from_black(M)

	// Teleport all crates to the hub spawn point turf
	var/turf/crate_dest_base = get_turf(hub.spawn_point)
	if(crate_dest_base)
		for(var/obj/structure/closet/crate/C in floor_crates)
			C.forceMove(crate_dest_base)

	expedition.state = EXPEDITION_AT_DESTINATION
	log_game("Expedition arrived at faction hub: [faction_id]")

	// Track faction hub visit for objectives
	on_faction_hub_visited(faction_id)

/**
 * Return the expedition to the outpost
 */
/datum/expedition_corridor_manager/proc/return_to_outpost()
	if(!expedition)
		return

	// Collect all crates from the corridor to return with the party
	var/list/floor_crates = list()
	for(var/turf/T in floor_turfs)
		for(var/obj/structure/closet/crate/C in T)
			floor_crates += C

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

	// Teleport crates back to outpost (near the return turf)
	if(return_turf)
		for(var/obj/structure/closet/crate/C in floor_crates)
			C.forceMove(return_turf)

	expedition.state = EXPEDITION_COMPLETE
	expedition.end_time = world.time

	// Track expedition completion for objectives
	on_expedition_completed()

	end_expedition()

	// Update world map UI to reflect return
	update_all_world_map_uis()

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
		terrain = get_faction_terrain(first_tile.faction_id)

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
	// Get start position - use the landmark turf directly
	var/turf/start_turf = get_turf(start_landmark)
	if(!start_turf)
		start_turf = locate(EXPEDITION_CORRIDOR_WIDTH / 2, EXPEDITION_START_Y + 1, GLOB.expedition_corridor_z)

	// Collect crates from the faction hub before leaving (if coming from a hub)
	var/list/hub_crates = list()
	if(party.current_tile?.faction_id)
		var/datum/faction_hub_controller/hub = get_faction_hub(party.current_tile.faction_id)
		if(hub?.spawn_point)
			// Collect all crates near the hub spawn point
			for(var/obj/structure/closet/crate/C in range(7, hub.spawn_point))
				hub_crates += C

	// Update current tile to first position in new route
	if(length(party.route) >= 1)
		party.current_tile = party.route[1]

	// Teleport all players to start
	for(var/mob/living/M in party.members)
		M.forceMove(start_turf)
		apply_terrain_speed(M, terrain)

	// Teleport hub crates to the start landmark
	if(length(hub_crates))
		for(var/obj/structure/closet/crate/C in hub_crates)
			C.forceMove(start_turf)
		for(var/mob/living/M in party.members)
			to_chat(M, span_notice("[length(hub_crates)] crate(s) have been brought along from the hub."))

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

// ============================================
// GLOBAL HELPER PROCS
// ============================================

/**
 * Update all world map console UIs
 * Called when tiles are discovered or expedition state changes
 */
/proc/update_all_world_map_uis()
	for(var/obj/structure/world_map_console/console in GLOB.world_map_consoles)
		SStgui.update_uis(console)

/**
 * Get the terrain type for a faction tile
 * Returns the faction's required terrain from GLOB.faction_terrain_requirements, or TERRAIN_PLAINS as fallback
 */
/proc/get_faction_terrain(faction_id)
	if(!faction_id)
		return TERRAIN_PLAINS
	var/required_terrain = GLOB.faction_terrain_requirements[faction_id]
	if(required_terrain)
		return required_terrain
	return TERRAIN_PLAINS
