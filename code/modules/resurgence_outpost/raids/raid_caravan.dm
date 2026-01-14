/**
 * Raid Caravan
 *
 * A hostile caravan sent by the Insurgence Clan that travels across the world map
 * toward the player's outpost. When it arrives, a raid is triggered.
 * Players can intercept and destroy the caravan during expeditions.
 */

/// Counter for raid caravan IDs
GLOBAL_VAR_INIT(raid_caravan_id_counter, 0)

/datum/raid_caravan
	/// Unique caravan ID
	var/caravan_id
	/// The faction sending the raid (always insurgence_clan)
	var/faction_id = "insurgence_clan"
	/// The type of raid this caravan will trigger
	var/raid_type = RAID_TYPE_BASIC
	/// Current state of the caravan
	var/state = "traveling"
	/// Current world tile position
	var/datum/world_tile/current_tile
	/// Destination tile (always the outpost)
	var/datum/world_tile/destination
	/// Route as list of world tiles
	var/list/datum/world_tile/route
	/// Current position in route (1-indexed)
	var/route_index = 1
	/// Timer ID for movement
	var/move_timer_id
	/// Whether players have been alerted to this caravan
	var/has_been_spotted = FALSE
	/// Whether this caravan is currently being intercepted
	var/intercepted = FALSE
	/// Display name
	var/name = "Insurgence Raiding Party"
	/// Display color for world map (dark red)
	var/display_color = RAID_CARAVAN_DISPLAY_COLOR
	/// Number of raiders in this caravan (affects intercept difficulty)
	var/raider_count = 5

/datum/raid_caravan/New(raid_type_arg = RAID_TYPE_BASIC)
	. = ..()
	GLOB.raid_caravan_id_counter++
	caravan_id = GLOB.raid_caravan_id_counter
	raid_type = raid_type_arg
	setup_raider_count()

/**
 * Setup raider count based on raid type
 */
/datum/raid_caravan/proc/setup_raider_count()
	switch(raid_type)
		if(RAID_TYPE_BASIC)
			raider_count = 5
		if(RAID_TYPE_PILLAGE)
			raider_count = 6
		if(RAID_TYPE_SIEGE)
			raider_count = 6
		if(RAID_TYPE_ASSASSINATION)
			raider_count = 4
		if(RAID_TYPE_OVERWHELMING)
			raider_count = 8
		else
			raider_count = 5

/datum/raid_caravan/Destroy()
	// Remove from tile
	if(current_tile)
		current_tile.raid_caravan = null
	// Cancel movement timer
	if(move_timer_id)
		deltimer(move_timer_id)
	// Remove from global list
	GLOB.active_raid_caravans -= src
	current_tile = null
	destination = null
	route = null
	return ..()

/**
 * Start the raid caravan's journey from insurgence tile to outpost
 */
/datum/raid_caravan/proc/start_journey()
	if(!GLOB.resurgence_world_map)
		return FALSE

	// Get insurgence faction tile as start point
	var/datum/world_tile/start = GLOB.resurgence_world_map.get_faction_tile("insurgence_clan")
	if(!start)
		log_game("Raid caravan [caravan_id]: No insurgence faction tile found!")
		return FALSE

	// Get outpost tile as destination
	destination = GLOB.resurgence_world_map.outpost_tile
	if(!destination)
		log_game("Raid caravan [caravan_id]: No outpost tile found!")
		return FALSE

	current_tile = start
	current_tile.raid_caravan = src

	// Calculate route to outpost
	route = GLOB.resurgence_world_map.find_path(start, destination)
	if(!route || length(route) < 2)
		log_game("Raid caravan [caravan_id]: No path to outpost!")
		return FALSE

	route_index = 1
	state = "traveling"

	// Add to global list
	GLOB.active_raid_caravans += src

	// Start movement
	schedule_move()

	log_game("Raid caravan [caravan_id] started journey to outpost, route length: [length(route)] tiles")
	return TRUE

/**
 * Schedule next movement
 */
/datum/raid_caravan/proc/schedule_move()
	if(state != "traveling")
		return
	move_timer_id = addtimer(CALLBACK(src, PROC_REF(do_move)), RAID_CARAVAN_MOVE_DELAY, TIMER_STOPPABLE)

/**
 * Execute movement to next tile
 */
/datum/raid_caravan/proc/do_move()
	if(state != "traveling")
		return

	if(!route || !length(route))
		arrive_at_outpost()
		return

	// Calculate next position
	var/next_index = route_index + 1

	// Check if we've reached the outpost
	if(next_index > length(route))
		arrive_at_outpost()
		return

	// Get the next tile
	var/datum/world_tile/next_tile = route[next_index]
	if(!next_tile)
		arrive_at_outpost()
		return

	// Leave current tile
	if(current_tile)
		current_tile.raid_caravan = null

	// Enter new tile
	current_tile = next_tile
	current_tile.raid_caravan = src
	route_index = next_index

	// Check if we've been spotted (tile is discovered)
	check_discovered()

	// Check if we've arrived at outpost
	if(route_index >= length(route) || current_tile == destination)
		arrive_at_outpost()
		return

	// Schedule next move
	schedule_move()

	// Update world map UIs
	update_all_world_map_uis()

/**
 * Check if the caravan has entered a discovered tile
 * If so, alert players
 */
/datum/raid_caravan/proc/check_discovered()
	if(has_been_spotted)
		return
	if(!current_tile?.discovered)
		return

	has_been_spotted = TRUE
	alert_players()

/**
 * Alert all resurgence players that a raid caravan has been spotted
 */
/datum/raid_caravan/proc/alert_players()
	// Calculate ETA based on remaining tiles
	var/remaining_tiles = length(route) - route_index
	var/eta_seconds = remaining_tiles * (RAID_CARAVAN_MOVE_DELAY / 10)
	var/eta_minutes = round(eta_seconds / 60)

	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			to_chat(H, span_boldwarning("ALERT: A hostile Insurgence raiding party has been spotted heading toward the outpost!"))
			to_chat(H, span_warning("Estimated arrival: [eta_minutes] minutes. Check the world map to track their approach."))
			SEND_SOUND(H, sound('sound/machines/warning-buzzer.ogg'))

	// Update world map UIs to show the caravan
	update_all_world_map_uis()

/**
 * Handle arrival at the outpost - trigger the raid
 */
/datum/raid_caravan/proc/arrive_at_outpost()
	state = "arrived"
	if(move_timer_id)
		deltimer(move_timer_id)
		move_timer_id = null

	log_game("Raid caravan [caravan_id] arrived at outpost - triggering raid!")

	// Alert players that the raid is starting
	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			to_chat(H, span_boldwarning("The Insurgence raiding party has arrived! Defend the outpost!"))
			SEND_SOUND(H, sound('sound/machines/warning-buzzer.ogg'))

	// Create and start the raid using the existing raid system
	var/datum/resurgence_raid/raid = new(faction_id, raid_type)
	SSresurgence_raids.active_raids += raid
	raid.start_raid()

	// Cleanup
	GLOB.active_raid_caravans -= src
	if(current_tile)
		current_tile.raid_caravan = null
	qdel(src)

/**
 * Pause the caravan for an intercept encounter
 */
/datum/raid_caravan/proc/pause_for_intercept()
	intercepted = TRUE
	state = "intercepted"
	if(move_timer_id)
		deltimer(move_timer_id)
		move_timer_id = null
	log_game("Raid caravan [caravan_id] paused for intercept")

/**
 * Resume movement after a failed intercept
 */
/datum/raid_caravan/proc/resume_from_intercept()
	intercepted = FALSE
	state = "traveling"
	schedule_move()
	log_game("Raid caravan [caravan_id] resumed after failed intercept")

/**
 * Destroy the caravan (players successfully intercepted)
 */
/datum/raid_caravan/proc/destroy_caravan()
	state = "destroyed"
	if(move_timer_id)
		deltimer(move_timer_id)
		move_timer_id = null

	log_game("Raid caravan [caravan_id] was destroyed by players")

	// Alert all players
	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			to_chat(H, span_boldnotice("The Insurgence raiding party has been eliminated! The outpost is safe."))

	// Cleanup
	GLOB.active_raid_caravans -= src
	if(current_tile)
		current_tile.raid_caravan = null
	qdel(src)

/**
 * Get UI data for world map display
 */
/datum/raid_caravan/proc/get_ui_data()
	var/list/data = list()
	data["caravan_id"] = caravan_id
	data["faction_id"] = faction_id
	data["name"] = name
	data["state"] = state
	data["x"] = current_tile?.x_coord
	data["y"] = current_tile?.y_coord
	data["dest_x"] = destination?.x_coord
	data["dest_y"] = destination?.y_coord
	data["is_hostile"] = TRUE
	data["color"] = display_color
	data["raid_type"] = raid_type
	data["raider_count"] = raider_count
	data["spotted"] = has_been_spotted

	// Calculate ETA
	if(route && route_index < length(route))
		var/remaining_tiles = length(route) - route_index
		var/eta_seconds = remaining_tiles * (RAID_CARAVAN_MOVE_DELAY / 10)
		data["eta_minutes"] = round(eta_seconds / 60)
	else
		data["eta_minutes"] = 0

	return data
