// Expedition Map Device
// Portable device for viewing the world map and planning routes during expeditions

/**
 * Expedition Map Device
 *
 * A handheld device that displays the world map.
 * Can be used during expeditions to plan new routes from current position.
 */
/obj/item/expedition_map
	name = "expedition map device"
	desc = "A portable electronic map showing the surrounding region. Use it to plan your route during expeditions."
	icon = 'icons/obj/modular_tablet.dmi'
	icon_state = "map-tablet"
	w_class = WEIGHT_CLASS_SMALL
	/// The expedition party this device is tracking (if any)
	var/datum/expedition_party/tracked_expedition
	/// Currently selected destination X coordinate
	var/selected_x = 0
	/// Currently selected destination Y coordinate
	var/selected_y = 0

/obj/item/expedition_map/attack_self(mob/user)
	. = ..()
	ui_interact(user)

/obj/item/expedition_map/ui_interact(mob/user, datum/tgui/ui)
	// Try to find user's expedition if not already tracked
	if(!tracked_expedition)
		find_user_expedition(user)

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ResurgenceWorldMap", name)
		ui.open()

/obj/item/expedition_map/ui_data(mob/user)
	var/list/data = list()

	// Try to find expedition again in case it changed
	find_user_expedition(user)

	// Get base map data from manager
	if(GLOB.resurgence_world_map)
		data = GLOB.resurgence_world_map.get_ui_data()
	else
		data["generated"] = FALSE
		data["map_width"] = WORLD_MAP_WIDTH
		data["map_height"] = WORLD_MAP_HEIGHT

	// Mark this as a portable device
	data["is_portable"] = TRUE

	// Get current position for route calculation
	var/datum/world_tile/current_pos
	if(tracked_expedition?.current_tile)
		current_pos = tracked_expedition.current_tile
		data["current_x"] = current_pos.x_coord
		data["current_y"] = current_pos.y_coord
		data["on_expedition"] = TRUE
		data["expedition_state"] = tracked_expedition.state
	else if(GLOB.resurgence_world_map?.outpost_tile)
		current_pos = GLOB.resurgence_world_map.outpost_tile
		data["current_x"] = current_pos.x_coord
		data["current_y"] = current_pos.y_coord
		data["on_expedition"] = FALSE
	else
		data["on_expedition"] = FALSE

	// Selection state (stored on device)
	data["selected_x"] = selected_x
	data["selected_y"] = selected_y

	// Calculate and add planned route if selection exists
	if(selected_x > 0 && selected_y > 0 && current_pos && GLOB.resurgence_world_map)
		var/datum/world_tile/dest = GLOB.resurgence_world_map.get_tile(selected_x, selected_y)
		if(dest)
			var/list/route = GLOB.resurgence_world_map.find_path(current_pos, dest)
			if(route && length(route))
				var/list/route_data = list()
				for(var/datum/world_tile/tile in route)
					route_data += list(list("x" = tile.x_coord, "y" = tile.y_coord))
				data["planned_route"] = route_data
				data["route_cost"] = GLOB.resurgence_world_map.get_path_cost(route)
			else
				data["planned_route"] = list()
				data["route_cost"] = 0
		else
			data["planned_route"] = list()
			data["route_cost"] = 0
	else
		data["planned_route"] = list()
		data["route_cost"] = 0

	// Get selected tile info
	if(selected_x > 0 && selected_y > 0 && GLOB.resurgence_world_map)
		var/datum/world_tile/selected = GLOB.resurgence_world_map.get_tile(selected_x, selected_y)
		if(selected)
			data["selected_tile"] = selected.get_ui_data(FALSE)
		else
			data["selected_tile"] = null
	else
		data["selected_tile"] = null

	// Can stop mid-travel?
	data["can_stop"] = tracked_expedition?.state == EXPEDITION_TRAVELING

	// No expedition management from portable - just navigation
	data["has_expedition"] = FALSE
	data["expedition"] = null
	data["user_in_expedition"] = FALSE
	data["user_is_leader"] = FALSE

	return data

/obj/item/expedition_map/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("select_tile")
			var/x = text2num(params["x"])
			var/y = text2num(params["y"])
			if(x && y && GLOB.resurgence_world_map)
				var/datum/world_tile/tile = GLOB.resurgence_world_map.get_tile(x, y)
				// Allow selection of any tile (discovered or not)
				if(tile)
					selected_x = x
					selected_y = y
					return TRUE

		if("clear_selection")
			selected_x = 0
			selected_y = 0
			return TRUE

		if("set_new_destination")
			return set_expedition_destination(usr)

		if("stop_travel")
			return stop_travel(usr)

		if("return_to_outpost")
			return start_return_journey(usr)

		if("toggle_debug")
			if(!check_rights_for(usr.client, R_DEBUG))
				return FALSE
			if(GLOB.resurgence_world_map)
				GLOB.resurgence_world_map.debug_mode = !GLOB.resurgence_world_map.debug_mode
				return TRUE

	return FALSE

/**
 * Find the user's current expedition party
 */
/obj/item/expedition_map/proc/find_user_expedition(mob/user)
	tracked_expedition = null

	if(!isliving(user))
		return

	var/mob/living/L = user

	// Check active expeditions
	for(var/datum/expedition_party/party in GLOB.active_expeditions)
		if(L in party.members)
			tracked_expedition = party
			return

/**
 * Set a new destination for the current expedition
 */
/obj/item/expedition_map/proc/set_expedition_destination(mob/user)
	if(!tracked_expedition)
		to_chat(user, span_warning("You are not on an expedition."))
		return FALSE

	if(tracked_expedition.state != EXPEDITION_AT_DESTINATION && tracked_expedition.state != EXPEDITION_STOPPED)
		to_chat(user, span_warning("You can only change destination when stopped or at a location."))
		return FALSE

	if(selected_x <= 0 || selected_y <= 0)
		to_chat(user, span_warning("No destination selected."))
		return FALSE

	var/datum/world_tile/dest = GLOB.resurgence_world_map?.get_tile(selected_x, selected_y)
	if(!dest)
		to_chat(user, span_warning("Invalid destination."))
		return FALSE

	// Calculate new route from current position
	var/datum/world_tile/current = tracked_expedition.current_tile
	if(!current)
		to_chat(user, span_warning("Cannot determine current location."))
		return FALSE

	var/list/new_route = GLOB.resurgence_world_map.find_path(current, dest)
	if(!new_route || !length(new_route))
		to_chat(user, span_warning("No valid path to destination."))
		return FALSE

	// Update expedition
	tracked_expedition.destination = dest
	tracked_expedition.route = new_route
	tracked_expedition.route_cost = GLOB.resurgence_world_map.get_path_cost(new_route)

	// Restart travel
	if(GLOB.expedition_corridor)
		GLOB.expedition_corridor.continue_expedition(tracked_expedition)

	to_chat(user, span_notice("New destination set: [dest.terrain_name]. Continuing expedition..."))

	// Clear selection
	selected_x = 0
	selected_y = 0

	return TRUE

/**
 * Stop the expedition mid-travel at the current tile
 */
/obj/item/expedition_map/proc/stop_travel(mob/user)
	if(!tracked_expedition)
		to_chat(user, span_warning("You are not on an expedition."))
		return FALSE

	if(tracked_expedition.state != EXPEDITION_TRAVELING)
		to_chat(user, span_warning("You can only stop while traveling."))
		return FALSE

	if(!GLOB.expedition_corridor)
		to_chat(user, span_warning("No corridor found."))
		return FALSE

	return GLOB.expedition_corridor.stop_expedition()

/**
 * Start the journey back to the outpost
 */
/obj/item/expedition_map/proc/start_return_journey(mob/user)
	if(!tracked_expedition)
		to_chat(user, span_warning("You are not on an expedition."))
		return FALSE

	if(tracked_expedition.state != EXPEDITION_AT_DESTINATION && tracked_expedition.state != EXPEDITION_STOPPED)
		to_chat(user, span_warning("You can only return when stopped or at a location."))
		return FALSE

	var/datum/world_tile/outpost = GLOB.resurgence_world_map?.outpost_tile
	if(!outpost)
		to_chat(user, span_warning("Cannot find outpost location."))
		return FALSE

	var/datum/world_tile/current = tracked_expedition.current_tile
	if(!current)
		to_chat(user, span_warning("Cannot determine current location."))
		return FALSE

	// Calculate route back to outpost
	var/list/return_route = GLOB.resurgence_world_map.find_path(current, outpost)
	if(!return_route || !length(return_route))
		to_chat(user, span_warning("No valid path to outpost."))
		return FALSE

	// Build terrain list for the return journey (skip first tile which is current position)
	var/list/terrain_names = list()
	for(var/i in 2 to length(return_route))
		var/datum/world_tile/tile = return_route[i]
		var/tname = GLOB.terrain_names[tile.terrain_type] || tile.terrain_type
		if(tile.terrain_type != TERRAIN_OUTPOST)
			terrain_names += tname

	// Log the return route
	log_game("Return route calculated from [current.terrain_name] ([current.x_coord],[current.y_coord]) to outpost: [terrain_names.Join(" -> ")] -> Outpost")

	// Update expedition for return journey
	tracked_expedition.destination = outpost
	tracked_expedition.route = return_route
	tracked_expedition.route_cost = GLOB.resurgence_world_map.get_path_cost(return_route)
	tracked_expedition.state = EXPEDITION_RETURNING

	// Start return travel
	if(GLOB.expedition_corridor)
		GLOB.expedition_corridor.continue_expedition(tracked_expedition)

	// Tell user the path they'll take
	if(length(terrain_names))
		to_chat(user, span_notice("Returning to outpost via: [terrain_names.Join(" -> ")] -> Outpost"))
	else
		to_chat(user, span_notice("Returning to outpost..."))

	// Clear selection
	selected_x = 0
	selected_y = 0

	return TRUE
