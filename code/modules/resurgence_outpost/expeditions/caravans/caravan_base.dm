// Faction Caravan Datum
// Represents a faction's trading caravan traveling on the world map

/// Counter for caravan IDs
GLOBAL_VAR_INIT(caravan_id_counter, 0)

/**
 * Faction Caravan
 *
 * A caravan sent by a trading faction that moves across the world map.
 * Players can encounter caravans during expeditions for trading or combat.
 */
/datum/faction_caravan
	/// Unique caravan ID
	var/caravan_id
	/// The faction that owns this caravan
	var/datum/trading_faction/owner_faction
	/// Faction ID string
	var/faction_id
	/// Current state
	var/state = CARAVAN_TRAVELING
	/// Current world tile position
	var/datum/world_tile/current_tile
	/// Destination world tile
	var/datum/world_tile/destination
	/// Route as list of world tiles
	var/list/datum/world_tile/route
	/// Current position in route
	var/route_index = 0
	/// Stock carried by the caravan (subset of faction stock)
	var/list/stock = list()
	/// Current cash for buying
	var/caravan_cash = 500
	/// Number of guards
	var/guard_count = 3
	/// Whether this is a hostile patrol (Insurgence)
	var/is_patrol = FALSE
	/// Timer ID for movement
	var/move_timer_id
	/// Display name
	var/name = "Trading Caravan"
	/// Display color for map
	var/display_color = "#cc9933"

/datum/faction_caravan/New(faction_id_arg)
	. = ..()
	GLOB.caravan_id_counter++
	caravan_id = GLOB.caravan_id_counter

	faction_id = faction_id_arg
	if(faction_id && GLOB.resurgence_trading)
		owner_faction = GLOB.resurgence_trading.get_faction(faction_id)
		if(owner_faction)
			display_color = owner_faction.color || "#cc9933"
			setup_caravan_name()
			setup_stock()
			setup_guards()

/datum/faction_caravan/Destroy()
	// Remove from tile
	if(current_tile)
		current_tile.caravan = null
	// Cancel movement timer
	if(move_timer_id)
		deltimer(move_timer_id)
	// Remove from global list
	GLOB.active_caravans -= src
	// Clear current encounter if it's us
	if(GLOB.current_caravan_encounter == src)
		GLOB.current_caravan_encounter = null
	owner_faction = null
	current_tile = null
	destination = null
	route = null
	stock = null
	return ..()

/**
 * Setup caravan name based on faction
 */
/datum/faction_caravan/proc/setup_caravan_name()
	switch(faction_id)
		if("resurgence_clan")
			name = "Clan Pilgrims"
		if("jiajia_ren")
			name = "Flock Traders"
		if("santata_factory")
			name = "Gnome Convoy"
		if("cloud_town")
			name = "Frontier Wagon"
		if("insurgence_clan")
			name = "Raider Patrol"
			is_patrol = TRUE

/**
 * Setup caravan stock from faction
 */
/datum/faction_caravan/proc/setup_stock()
	if(!owner_faction)
		return

	// Copy a random subset of faction stock
	if(length(owner_faction.stock))
		var/list/available = owner_faction.stock.Copy()
		var/items_to_take = min(length(available), rand(3, 6))
		for(var/i in 1 to items_to_take)
			if(!length(available))
				break
			var/item = pick(available)
			available -= item
			// Add with reduced quantity
			stock[item] = rand(1, 5)

	// Set caravan cash based on faction
	caravan_cash = rand(300, 800)

/**
 * Setup guard count based on faction
 */
/datum/faction_caravan/proc/setup_guards()
	guard_count = GLOB.caravan_guard_counts[faction_id] || 3

/**
 * Start the caravan from a faction tile to a destination
 */
/datum/faction_caravan/proc/start_journey(datum/world_tile/start, datum/world_tile/dest)
	if(!start || !dest)
		return FALSE

	current_tile = start
	destination = dest

	// Register with current tile
	current_tile.caravan = src

	// Calculate route
	if(!GLOB.resurgence_world_map)
		return FALSE

	route = GLOB.resurgence_world_map.find_path(start, dest)
	if(!route || length(route) < 2)
		return FALSE

	route_index = 0
	state = CARAVAN_TRAVELING

	// Add to global list
	GLOB.active_caravans |= src

	// Start movement timer
	schedule_move()

	log_game("Caravan [caravan_id] ([name]) started journey from ([start.x_coord],[start.y_coord]) to ([dest.x_coord],[dest.y_coord])")
	return TRUE

/**
 * Schedule next movement
 */
/datum/faction_caravan/proc/schedule_move()
	if(state != CARAVAN_TRAVELING)
		return
	move_timer_id = addtimer(CALLBACK(src, PROC_REF(do_move)), CARAVAN_MOVE_DELAY, TIMER_STOPPABLE)

/**
 * Execute movement to next tile
 */
/datum/faction_caravan/proc/do_move()
	if(state != CARAVAN_TRAVELING)
		return

	// Advance route
	route_index++

	if(route_index >= length(route))
		// Reached destination
		arrive_at_destination()
		return

	// Move to next tile
	var/datum/world_tile/next_tile = route[route_index + 1]
	if(!next_tile)
		arrive_at_destination()
		return

	// Leave current tile
	if(current_tile)
		current_tile.caravan = null

	// Enter new tile
	current_tile = next_tile
	current_tile.caravan = src

	// Check if we entered a tile with an expedition
	check_expedition_collision()

	// Schedule next move
	schedule_move()

	// Update world map UIs
	update_all_world_map_uis()

/**
 * Check if we collided with an expedition on this tile
 */
/datum/faction_caravan/proc/check_expedition_collision()
	// Check if any active expedition is on this tile
	for(var/datum/expedition_party/party in GLOB.active_expeditions)
		if(party.current_tile == current_tile)
			// Stop the caravan - expedition will encounter us
			stop_for_encounter()
			return

/**
 * Stop the caravan for an encounter
 */
/datum/faction_caravan/proc/stop_for_encounter()
	state = CARAVAN_STOPPED
	if(move_timer_id)
		deltimer(move_timer_id)
		move_timer_id = null
	log_game("Caravan [caravan_id] stopped for encounter at ([current_tile.x_coord],[current_tile.y_coord])")

/**
 * Resume travel after encounter (if not destroyed)
 */
/datum/faction_caravan/proc/resume_travel()
	if(state == CARAVAN_DESTROYED || state == CARAVAN_COMPLETE)
		return
	state = CARAVAN_TRAVELING
	schedule_move()
	log_game("Caravan [caravan_id] resumed travel")

/**
 * Handle arrival at destination
 */
/datum/faction_caravan/proc/arrive_at_destination()
	state = CARAVAN_AT_DESTINATION
	if(move_timer_id)
		deltimer(move_timer_id)
		move_timer_id = null

	log_game("Caravan [caravan_id] arrived at destination ([destination.x_coord],[destination.y_coord])")

	// Despawn after a delay
	addtimer(CALLBACK(src, PROC_REF(complete_journey)), CARAVAN_DESPAWN_DELAY)

/**
 * Complete the journey and despawn
 */
/datum/faction_caravan/proc/complete_journey()
	state = CARAVAN_COMPLETE
	qdel(src)

/**
 * Mark caravan as destroyed (from combat)
 */
/datum/faction_caravan/proc/destroy_caravan()
	state = CARAVAN_DESTROYED
	if(move_timer_id)
		deltimer(move_timer_id)
		move_timer_id = null

	log_game("Caravan [caravan_id] was destroyed")

	// Clean up after a short delay
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(qdel), src), 5 SECONDS)

/**
 * Get UI data for world map display
 */
/datum/faction_caravan/proc/get_ui_data()
	var/list/data = list()
	data["caravan_id"] = caravan_id
	data["faction_id"] = faction_id
	data["name"] = name
	data["state"] = state
	data["x"] = current_tile?.x_coord
	data["y"] = current_tile?.y_coord
	data["dest_x"] = destination?.x_coord
	data["dest_y"] = destination?.y_coord
	data["is_patrol"] = is_patrol
	data["color"] = display_color
	data["guard_count"] = guard_count
	return data

/**
 * Check if this caravan is hostile (Insurgence patrol)
 */
/datum/faction_caravan/proc/is_hostile()
	return is_patrol || faction_id == "insurgence_clan"

/**
 * Get trade data for encounter UI
 */
/datum/faction_caravan/proc/get_trade_data()
	var/list/data = list()
	data["caravan_id"] = caravan_id
	data["faction_id"] = faction_id
	data["faction_name"] = owner_faction?.name || "Unknown"
	data["name"] = name
	data["cash"] = caravan_cash
	data["guard_count"] = guard_count
	data["is_hostile"] = is_hostile()

	// Build stock list
	var/list/stock_data = list()
	for(var/item_path in stock)
		var/obj/item/temp = item_path
		stock_data += list(list(
			"path" = "[item_path]",
			"name" = initial(temp.name),
			"quantity" = stock[item_path],
			"price" = get_item_price(item_path)
		))
	data["stock"] = stock_data

	return data

/**
 * Get price for an item (based on faction pricing)
 */
/datum/faction_caravan/proc/get_item_price(item_path)
	if(!owner_faction)
		return 50
	// Use faction's pricing if available
	if(item_path in owner_faction.prices)
		return owner_faction.prices[item_path]
	return 50
