/**
 * Resurgence Outpost - Caravan Debug Tool
 *
 * Admin/debug tool for testing the caravan system.
 */

/obj/item/caravan_debug_tool
	name = "caravan debugger"
	desc = "A debug tool for testing the caravan system. Admin use only."
	icon = 'icons/obj/device.dmi'
	icon_state = "multitool"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/caravan_debug_tool/attack_self(mob/user)
	if(!check_rights_for(user.client, R_DEBUG))
		to_chat(user, span_warning("You don't have permission to use this."))
		return

	var/list/options = list(
		"Spawn Caravan",
		"List Active Caravans",
		"Delete All Caravans",
		"Force Caravan Move",
		"Teleport To Caravan",
		"Force Encounter",
		"Toggle Caravan System",
		"Toggle Debug Mode",
		"Show Debug Info",
		"Instant Move Caravan",
		"Set Caravan Destination"
	)

	var/choice = input(user, "Select caravan action", "Caravan Debug") as null|anything in options
	if(!choice)
		return

	switch(choice)
		if("Spawn Caravan")
			spawn_caravan(user)
		if("List Active Caravans")
			list_active_caravans(user)
		if("Delete All Caravans")
			delete_all_caravans(user)
		if("Force Caravan Move")
			force_caravan_move(user)
		if("Teleport To Caravan")
			teleport_to_caravan(user)
		if("Force Encounter")
			force_encounter(user)
		if("Toggle Caravan System")
			toggle_caravan_system(user)
		if("Toggle Debug Mode")
			toggle_debug_mode(user)
		if("Show Debug Info")
			show_debug_info(user)
		if("Instant Move Caravan")
			instant_move_caravan(user)
		if("Set Caravan Destination")
			set_caravan_destination(user)

/**
 * Spawn a new caravan for a chosen faction
 */
/obj/item/caravan_debug_tool/proc/spawn_caravan(mob/user)
	if(!GLOB.resurgence_world_map)
		to_chat(user, span_warning("World map not initialized."))
		return

	// Select faction
	var/list/faction_options = list(
		"Resurgence Clan" = "resurgence_clan",
		"Jiajia-ren" = "jiajia_ren",
		"Santata Factory" = "santata_factory",
		"Cloud Town" = "cloud_town",
		"Insurgence Clan (Hostile)" = "insurgence_clan"
	)

	var/faction_choice = input(user, "Select faction for caravan", "Spawn Caravan") as null|anything in faction_options
	if(!faction_choice)
		return

	var/faction_id = faction_options[faction_choice]

	// Get faction's home tile
	var/datum/world_tile/start_tile = get_faction_tile(faction_id)
	if(!start_tile)
		to_chat(user, span_warning("Could not find faction home tile."))
		return

	// Select destination
	var/datum/world_tile/dest_tile = select_destination_tile(user, "Select destination for caravan")
	if(!dest_tile)
		return

	// Create the caravan
	var/datum/faction_caravan/caravan = new(faction_id)
	if(caravan.start_journey(start_tile, dest_tile))
		to_chat(user, span_notice("Spawned [caravan.name] from ([start_tile.x_coord],[start_tile.y_coord]) to ([dest_tile.x_coord],[dest_tile.y_coord])"))
		message_admins("[key_name(user)] spawned caravan [caravan.name] via debug tool")
	else
		to_chat(user, span_warning("Failed to start caravan journey - pathfinding failed?"))
		qdel(caravan)

/**
 * Get the home tile for a faction
 */
/obj/item/caravan_debug_tool/proc/get_faction_tile(faction_id)
	if(!GLOB.resurgence_trading)
		return null

	var/datum/trading_faction/faction = GLOB.resurgence_trading.get_faction(faction_id)
	if(!faction)
		return null

	if(faction.world_x && faction.world_y)
		return GLOB.resurgence_world_map.tiles[faction.world_x][faction.world_y]

	return null

/**
 * Let user select a destination tile
 */
/obj/item/caravan_debug_tool/proc/select_destination_tile(mob/user, prompt_text)
	if(!GLOB.resurgence_world_map)
		return null

	// Build list of destination options
	var/list/dest_options = list()

	// Add outpost
	dest_options["Outpost (Center)"] = GLOB.resurgence_world_map.outpost_tile

	// Add faction locations
	if(GLOB.resurgence_trading)
		for(var/faction_id in list("resurgence_clan", "jiajia_ren", "santata_factory", "cloud_town", "insurgence_clan"))
			var/datum/trading_faction/faction = GLOB.resurgence_trading.get_faction(faction_id)
			if(faction && faction.world_x && faction.world_y)
				var/datum/world_tile/tile = GLOB.resurgence_world_map.tiles[faction.world_x][faction.world_y]
				dest_options["[faction.name] ([faction.world_x],[faction.world_y])"] = tile

	// Add option for custom coordinates
	dest_options["Custom Coordinates"] = "custom"

	var/dest_choice = input(user, prompt_text, "Select Destination") as null|anything in dest_options
	if(!dest_choice)
		return null

	if(dest_options[dest_choice] == "custom")
		// Get custom coordinates
		var/x_coord = input(user, "Enter X coordinate (1-[GLOB.resurgence_world_map.map_width])", "X Coordinate") as null|num
		if(!x_coord)
			return null
		var/y_coord = input(user, "Enter Y coordinate (1-[GLOB.resurgence_world_map.map_height])", "Y Coordinate") as null|num
		if(!y_coord)
			return null

		x_coord = clamp(x_coord, 1, GLOB.resurgence_world_map.map_width)
		y_coord = clamp(y_coord, 1, GLOB.resurgence_world_map.map_height)

		return GLOB.resurgence_world_map.tiles[x_coord][y_coord]

	return dest_options[dest_choice]

/**
 * List all active caravans
 */
/obj/item/caravan_debug_tool/proc/list_active_caravans(mob/user)
	if(!length(GLOB.active_caravans))
		to_chat(user, span_notice("No active caravans."))
		return

	to_chat(user, span_notice("=== Active Caravans ([length(GLOB.active_caravans)]) ==="))
	for(var/datum/faction_caravan/C in GLOB.active_caravans)
		var/state_text = "Unknown"
		switch(C.state)
			if(CARAVAN_TRAVELING)
				state_text = "Traveling"
			if(CARAVAN_STOPPED)
				state_text = "Stopped"
			if(CARAVAN_AT_DESTINATION)
				state_text = "At Destination"
			if(CARAVAN_DESTROYED)
				state_text = "Destroyed"
			if(CARAVAN_COMPLETE)
				state_text = "Complete"

		var/pos_text = C.current_tile ? "([C.current_tile.x_coord],[C.current_tile.y_coord])" : "Unknown"
		var/dest_text = C.destination ? "([C.destination.x_coord],[C.destination.y_coord])" : "None"
		var/route_progress = C.route ? "[C.route_index + 1]/[length(C.route)]" : "N/A"

		to_chat(user, span_notice("#[C.caravan_id] [C.name] ([C.faction_id])"))
		to_chat(user, span_notice("  State: [state_text] | Pos: [pos_text] | Dest: [dest_text] | Progress: [route_progress]"))
		to_chat(user, span_notice("  Guards: [C.guard_count] | Stock: [length(C.stock)] items | Cash: [C.caravan_cash]"))

/**
 * Delete all active caravans
 */
/obj/item/caravan_debug_tool/proc/delete_all_caravans(mob/user)
	var/count = length(GLOB.active_caravans)
	if(!count)
		to_chat(user, span_notice("No caravans to delete."))
		return

	// Copy list since we're modifying it
	var/list/to_delete = GLOB.active_caravans.Copy()
	for(var/datum/faction_caravan/C in to_delete)
		qdel(C)

	to_chat(user, span_notice("Deleted [count] caravans."))
	message_admins("[key_name(user)] deleted all caravans via debug tool")

/**
 * Force a specific caravan to move one tile
 */
/obj/item/caravan_debug_tool/proc/force_caravan_move(mob/user)
	var/datum/faction_caravan/caravan = select_caravan(user, "Select caravan to move")
	if(!caravan)
		return

	if(caravan.state != CARAVAN_TRAVELING)
		to_chat(user, span_warning("Caravan is not currently traveling."))
		return

	caravan.do_move()
	to_chat(user, span_notice("Forced [caravan.name] to move. Now at ([caravan.current_tile?.x_coord],[caravan.current_tile?.y_coord])"))

/**
 * Instantly move a caravan to its destination
 */
/obj/item/caravan_debug_tool/proc/instant_move_caravan(mob/user)
	var/datum/faction_caravan/caravan = select_caravan(user, "Select caravan to instantly move")
	if(!caravan)
		return

	if(!caravan.destination)
		to_chat(user, span_warning("Caravan has no destination."))
		return

	// Move directly to destination
	if(caravan.current_tile)
		caravan.current_tile.caravan = null

	caravan.current_tile = caravan.destination
	caravan.current_tile.caravan = caravan
	caravan.route_index = length(caravan.route) - 1

	to_chat(user, span_notice("Instantly moved [caravan.name] to destination ([caravan.destination.x_coord],[caravan.destination.y_coord])"))
	message_admins("[key_name(user)] instant-moved caravan [caravan.name] to destination")

/**
 * Set a new destination for a caravan
 */
/obj/item/caravan_debug_tool/proc/set_caravan_destination(mob/user)
	var/datum/faction_caravan/caravan = select_caravan(user, "Select caravan to redirect")
	if(!caravan)
		return

	var/datum/world_tile/new_dest = select_destination_tile(user, "Select new destination")
	if(!new_dest)
		return

	// Recalculate route from current position
	if(!caravan.current_tile)
		to_chat(user, span_warning("Caravan has no current position."))
		return

	var/list/new_route = GLOB.resurgence_world_map.find_path(caravan.current_tile, new_dest)
	if(!new_route || length(new_route) < 2)
		to_chat(user, span_warning("Could not find path to destination."))
		return

	caravan.destination = new_dest
	caravan.route = new_route
	caravan.route_index = 1  // Start at position 1 in the new route

	// Resume travel if stopped
	if(caravan.state == CARAVAN_STOPPED || caravan.state == CARAVAN_AT_DESTINATION)
		caravan.state = CARAVAN_TRAVELING
		caravan.schedule_move()

	to_chat(user, span_notice("Set [caravan.name] destination to ([new_dest.x_coord],[new_dest.y_coord]). Route length: [length(new_route)] tiles."))

/**
 * Teleport user to a caravan's world tile
 * Note: This shows the world map position, not physical teleportation
 */
/obj/item/caravan_debug_tool/proc/teleport_to_caravan(mob/user)
	var/datum/faction_caravan/caravan = select_caravan(user, "Select caravan to view")
	if(!caravan)
		return

	if(!caravan.current_tile)
		to_chat(user, span_warning("Caravan has no current position."))
		return

	to_chat(user, span_notice("=== Caravan Location ==="))
	to_chat(user, span_notice("[caravan.name] (#[caravan.caravan_id])"))
	to_chat(user, span_notice("World Position: ([caravan.current_tile.x_coord], [caravan.current_tile.y_coord])"))
	to_chat(user, span_notice("Terrain: [caravan.current_tile.terrain_name]"))

	if(caravan.destination)
		to_chat(user, span_notice("Heading to: ([caravan.destination.x_coord], [caravan.destination.y_coord])"))

	// If there's an encounter, show that info
	if(GLOB.current_caravan_encounter == caravan)
		to_chat(user, span_boldnotice("This caravan is currently being encountered!"))

/**
 * Force start a caravan encounter with the selected caravan
 */
/obj/item/caravan_debug_tool/proc/force_encounter(mob/user)
	var/datum/faction_caravan/caravan = select_caravan(user, "Select caravan to encounter")
	if(!caravan)
		return

	if(GLOB.current_caravan_encounter)
		to_chat(user, span_warning("An encounter is already active."))
		return

	// Load encounter map if needed
	if(!GLOB.caravan_encounter_loaded)
		load_caravan_encounter()

	// Stop the caravan
	caravan.stop_for_encounter()

	// Create encounter controller
	var/datum/caravan_encounter_controller/controller = new(caravan, null)

	// Start encounter (teleport user)
	if(controller.spawn_point)
		GLOB.current_caravan_encounter = caravan
		GLOB.current_caravan_controller = controller

		// Spawn guards based on caravan hostility
		if(caravan.is_hostile())
			controller.spawn_hostile_guards()
		else
			controller.spawn_passive_guards()
			controller.spawn_trader()

		// Teleport user
		user.forceMove(get_turf(controller.spawn_point))

		to_chat(user, span_notice("Started encounter with [caravan.name]. Explore the area!"))
		message_admins("[key_name(user)] forced caravan encounter via debug tool")
	else
		to_chat(user, span_warning("Failed to start encounter - no spawn point found. Is the encounter map loaded?"))
		qdel(controller)

/**
 * Toggle the caravan spawning system
 */
/obj/item/caravan_debug_tool/proc/toggle_caravan_system(mob/user)
	if(!GLOB.caravan_manager)
		// Initialize if not exists
		init_caravan_system()

	if(GLOB.caravan_manager.active)
		GLOB.caravan_manager.stop()
		to_chat(user, span_notice("Caravan system DISABLED."))
	else
		GLOB.caravan_manager.start()
		to_chat(user, span_notice("Caravan system ENABLED."))

	message_admins("[key_name(user)] toggled caravan system [GLOB.caravan_manager.active ? "ON" : "OFF"]")

/**
 * Toggle debug mode on world map (reveals all tiles)
 */
/obj/item/caravan_debug_tool/proc/toggle_debug_mode(mob/user)
	if(!GLOB.resurgence_world_map)
		to_chat(user, span_warning("World map not initialized."))
		return

	GLOB.resurgence_world_map.debug_mode = !GLOB.resurgence_world_map.debug_mode
	to_chat(user, span_notice("World map debug mode [GLOB.resurgence_world_map.debug_mode ? "ENABLED (all tiles visible)" : "DISABLED"]."))

/**
 * Show debug information about the caravan system
 */
/obj/item/caravan_debug_tool/proc/show_debug_info(mob/user)
	to_chat(user, span_notice("=== Caravan System Debug Info ==="))

	// System state
	to_chat(user, span_notice("Caravan Manager: [GLOB.caravan_manager ? "Initialized" : "NOT Initialized"]"))
	if(GLOB.caravan_manager)
		to_chat(user, span_notice("  Active: [GLOB.caravan_manager.active ? "YES" : "NO"]"))

	// World map state
	to_chat(user, span_notice("World Map: [GLOB.resurgence_world_map ? "Generated" : "NOT Generated"]"))
	if(GLOB.resurgence_world_map)
		to_chat(user, span_notice("  Size: [GLOB.resurgence_world_map.map_width]x[GLOB.resurgence_world_map.map_height]"))
		to_chat(user, span_notice("  Debug Mode: [GLOB.resurgence_world_map.debug_mode ? "ON" : "OFF"]"))

	// Encounter state
	to_chat(user, span_notice("Encounter Map Loaded: [GLOB.caravan_encounter_loaded ? "YES" : "NO"]"))
	if(GLOB.caravan_encounter_z)
		to_chat(user, span_notice("  Z-Level: [GLOB.caravan_encounter_z]"))

	to_chat(user, span_notice("Current Encounter: [GLOB.current_caravan_encounter ? GLOB.current_caravan_encounter.name : "None"]"))

	// Caravan counts
	to_chat(user, span_notice("Active Caravans: [length(GLOB.active_caravans)]"))

	// Count by faction
	var/list/faction_counts = list()
	for(var/datum/faction_caravan/C in GLOB.active_caravans)
		if(!(C.faction_id in faction_counts))
			faction_counts[C.faction_id] = 0
		faction_counts[C.faction_id]++

	for(var/fid in faction_counts)
		to_chat(user, span_notice("  [fid]: [faction_counts[fid]]"))

	// Configuration
	to_chat(user, span_notice("--- Configuration ---"))
	to_chat(user, span_notice("Spawn Chance: [CARAVAN_SPAWN_CHANCE]%"))
	to_chat(user, span_notice("Max Per Faction: [CARAVAN_MAX_PER_FACTION]"))
	to_chat(user, span_notice("Move Delay: [CARAVAN_MOVE_DELAY / 10]s"))

/**
 * Helper to select a caravan from the active list
 */
/obj/item/caravan_debug_tool/proc/select_caravan(mob/user, prompt_text)
	if(!length(GLOB.active_caravans))
		to_chat(user, span_warning("No active caravans."))
		return null

	var/list/caravan_options = list()
	for(var/datum/faction_caravan/C in GLOB.active_caravans)
		var/pos_text = C.current_tile ? "([C.current_tile.x_coord],[C.current_tile.y_coord])" : "?"
		caravan_options["#[C.caravan_id] [C.name] @ [pos_text]"] = C

	var/choice = input(user, prompt_text, "Select Caravan") as null|anything in caravan_options
	if(!choice)
		return null

	return caravan_options[choice]

// ==================== Admin Verb ====================

/client/proc/caravan_debug_panel()
	set name = "Caravan Debug Panel"
	set category = "Debug"

	if(!check_rights(R_DEBUG))
		return

	var/list/options = list(
		"Spawn Caravan",
		"List Active Caravans",
		"Delete All Caravans",
		"Toggle Caravan System",
		"Show Debug Info"
	)

	var/choice = input(usr, "Select caravan action", "Caravan Debug") as null|anything in options
	if(!choice)
		return

	switch(choice)
		if("Spawn Caravan")
			spawn_caravan_panel()
		if("List Active Caravans")
			list_caravans_panel()
		if("Delete All Caravans")
			for(var/datum/faction_caravan/C in GLOB.active_caravans.Copy())
				qdel(C)
			to_chat(usr, span_notice("All caravans deleted."))
		if("Toggle Caravan System")
			if(GLOB.caravan_manager)
				if(GLOB.caravan_manager.active)
					GLOB.caravan_manager.stop()
				else
					GLOB.caravan_manager.start()
				to_chat(usr, span_notice("Caravan system [GLOB.caravan_manager.active ? "enabled" : "disabled"]."))
		if("Show Debug Info")
			to_chat(usr, span_notice("Caravans: [length(GLOB.active_caravans)] | Manager: [GLOB.caravan_manager?.active ? "ON" : "OFF"] | Encounter: [GLOB.current_caravan_encounter ? "Active" : "None"]"))

/client/proc/spawn_caravan_panel()
	var/list/factions = list("resurgence_clan", "jiajia_ren", "santata_factory", "cloud_town", "insurgence_clan")
	var/faction = input(usr, "Select faction", "Spawn Caravan") as null|anything in factions
	if(!faction)
		return

	if(!GLOB.resurgence_world_map || !GLOB.resurgence_trading)
		to_chat(usr, span_warning("World map or trading system not initialized."))
		return

	var/datum/trading_faction/tf = GLOB.resurgence_trading.get_faction(faction)
	if(!tf || !tf.world_x || !tf.world_y)
		to_chat(usr, span_warning("Faction has no world position."))
		return

	var/datum/world_tile/start = GLOB.resurgence_world_map.tiles[tf.world_x][tf.world_y]
	var/datum/world_tile/dest = GLOB.resurgence_world_map.outpost_tile

	var/datum/faction_caravan/C = new(faction)
	if(C.start_journey(start, dest))
		to_chat(usr, span_notice("Spawned [C.name] heading to outpost."))
	else
		to_chat(usr, span_warning("Failed to spawn caravan."))
		qdel(C)

/client/proc/list_caravans_panel()
	if(!length(GLOB.active_caravans))
		to_chat(usr, span_notice("No active caravans."))
		return

	for(var/datum/faction_caravan/C in GLOB.active_caravans)
		to_chat(usr, span_notice("#[C.caravan_id] [C.name] ([C.state]) @ ([C.current_tile?.x_coord],[C.current_tile?.y_coord])"))
