// World Map Console
// Physical console object for viewing and interacting with the world map

/**
 * World Map Console
 *
 * A wall-mounted or freestanding console that displays the world map.
 * Players can view terrain, plan routes, and initiate expeditions.
 */
/obj/structure/world_map_console
	name = "expedition planning console"
	desc = "A console displaying a map of the surrounding region. Use it to plan expeditions and view discovered territories."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE
	/// Currently selected destination tile coordinates
	var/selected_x = 0
	var/selected_y = 0
	/// Currently planned route
	var/list/planned_route
	/// Current expedition being formed at this console
	var/datum/expedition_party/forming_expedition

/obj/structure/world_map_console/Initialize(mapload)
	. = ..()
	// Register with global list for UI updates
	GLOB.world_map_consoles += src
	// Ensure world map is generated
	init_resurgence_world_map()

/obj/structure/world_map_console/Destroy()
	GLOB.world_map_consoles -= src
	if(forming_expedition)
		qdel(forming_expedition)
		forming_expedition = null
	return ..()

/obj/structure/world_map_console/examine(mob/user)
	. = ..()
	. += span_notice("Click to open the world map interface.")

/obj/structure/world_map_console/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	ui_interact(user)

/obj/structure/world_map_console/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ResurgenceWorldMap", name)
		ui.open()

/obj/structure/world_map_console/ui_data(mob/user)
	var/list/data = list()

	// Get base map data from manager
	if(GLOB.resurgence_world_map)
		data = GLOB.resurgence_world_map.get_ui_data()
	else
		data["generated"] = FALSE
		data["map_width"] = WORLD_MAP_WIDTH
		data["map_height"] = WORLD_MAP_HEIGHT

	// Add selection state
	data["selected_x"] = selected_x
	data["selected_y"] = selected_y

	// Add planned route if any
	if(planned_route && length(planned_route))
		var/list/route_data = list()
		for(var/datum/world_tile/tile in planned_route)
			route_data += list(list("x" = tile.x_coord, "y" = tile.y_coord))
		data["planned_route"] = route_data
		data["route_cost"] = GLOB.resurgence_world_map.get_path_cost(planned_route)
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

	// Add expedition data
	if(forming_expedition)
		data["expedition"] = forming_expedition.get_ui_data()
		data["has_expedition"] = TRUE
		// Check if user is in the expedition
		if(isliving(user))
			var/mob/living/L = user
			data["user_in_expedition"] = (L in forming_expedition.members)
			data["user_is_leader"] = (L == forming_expedition.leader)
		else
			data["user_in_expedition"] = FALSE
			data["user_is_leader"] = FALSE
	else
		data["expedition"] = null
		data["has_expedition"] = FALSE
		data["user_in_expedition"] = FALSE
		data["user_is_leader"] = FALSE

	// Check if corridor is loaded
	data["corridor_loaded"] = GLOB.expedition_corridor_loaded

	return data

/obj/structure/world_map_console/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("select_tile")
			var/x = text2num(params["x"])
			var/y = text2num(params["y"])
			if(x && y && GLOB.resurgence_world_map)
				var/datum/world_tile/tile = GLOB.resurgence_world_map.get_tile(x, y)
				// Allow selection if discovered OR in debug mode
				if(tile && (tile.discovered || GLOB.resurgence_world_map.debug_mode))
					selected_x = x
					selected_y = y
					// Calculate route from outpost to selected tile
					calculate_route()
					return TRUE

		if("clear_selection")
			selected_x = 0
			selected_y = 0
			planned_route = null
			return TRUE

		if("plan_expedition")
			if(planned_route && length(planned_route))
				return start_planning_expedition(usr)

		if("join_expedition")
			if(forming_expedition && isliving(usr))
				var/mob/living/L = usr
				if(forming_expedition.add_member(L))
					to_chat(usr, span_notice("You have joined the expedition."))
					return TRUE
				else
					to_chat(usr, span_warning("Could not join the expedition."))

		if("leave_expedition")
			if(forming_expedition && isliving(usr))
				var/mob/living/L = usr
				if(forming_expedition.remove_member(L))
					to_chat(usr, span_notice("You have left the expedition."))
					// If expedition is now empty, clear it
					if(!length(forming_expedition.members))
						forming_expedition = null
					return TRUE

		if("cancel_expedition")
			if(forming_expedition && isliving(usr))
				var/mob/living/L = usr
				// Only leader can cancel
				if(L == forming_expedition.leader)
					for(var/mob/living/M in forming_expedition.members)
						to_chat(M, span_warning("The expedition has been cancelled."))
					qdel(forming_expedition)
					forming_expedition = null
					return TRUE
				else
					to_chat(usr, span_warning("Only the expedition leader can cancel."))

		if("depart_expedition")
			if(forming_expedition && isliving(usr))
				var/mob/living/L = usr
				// Only leader can start departure
				if(L == forming_expedition.leader)
					return depart_expedition(usr)
				else
					to_chat(usr, span_warning("Only the expedition leader can start the departure."))

		if("toggle_debug")
			if(!check_rights_for(usr.client, R_DEBUG))
				to_chat(usr, span_warning("You don't have permission to toggle debug mode."))
				return FALSE
			if(GLOB.resurgence_world_map)
				GLOB.resurgence_world_map.debug_mode = !GLOB.resurgence_world_map.debug_mode
				to_chat(usr, span_notice("World map debug mode [GLOB.resurgence_world_map.debug_mode ? "enabled" : "disabled"]."))
				return TRUE

	return FALSE

/**
 * Calculate route from outpost to selected destination
 */
/obj/structure/world_map_console/proc/calculate_route()
	planned_route = null

	if(!GLOB.resurgence_world_map || selected_x <= 0 || selected_y <= 0)
		return

	var/datum/world_tile/start = GLOB.resurgence_world_map.outpost_tile
	var/datum/world_tile/goal = GLOB.resurgence_world_map.get_tile(selected_x, selected_y)

	if(!start || !goal)
		return

	planned_route = GLOB.resurgence_world_map.find_path(start, goal)

/**
 * Start planning an expedition to the selected destination
 */
/obj/structure/world_map_console/proc/start_planning_expedition(mob/user)
	if(!planned_route || !length(planned_route))
		to_chat(user, span_warning("No valid route selected."))
		return FALSE

	if(!isliving(user))
		return FALSE

	var/mob/living/L = user

	// Check if there's already an expedition forming
	if(forming_expedition)
		to_chat(user, span_warning("An expedition is already being planned. Join or wait for it to depart."))
		return FALSE

	// Get destination tile
	var/datum/world_tile/dest = GLOB.resurgence_world_map.get_tile(selected_x, selected_y)
	if(!dest)
		to_chat(user, span_warning("Invalid destination."))
		return FALSE

	// Create new expedition party
	forming_expedition = new /datum/expedition_party()
	if(!forming_expedition.set_destination(dest))
		to_chat(user, span_warning("Could not plan route to destination."))
		qdel(forming_expedition)
		forming_expedition = null
		return FALSE

	// Add the user as first member (and leader)
	forming_expedition.add_member(L)

	to_chat(user, span_notice("Expedition planned to [dest.terrain_name]. Other crew can join before departure."))
	return TRUE

/**
 * Start the expedition departure
 */
/obj/structure/world_map_console/proc/depart_expedition(mob/user)
	if(!forming_expedition)
		to_chat(user, span_warning("No expedition to depart."))
		return FALSE

	if(!length(forming_expedition.members))
		to_chat(user, span_warning("The expedition has no members."))
		return FALSE

	// Check corridor is loaded and ready
	if(!GLOB.expedition_corridor_loaded)
		to_chat(user, span_notice("Preparing expedition route... Please wait."))
		if(!load_expedition_corridor())
			to_chat(user, span_warning("Failed to prepare expedition route. Check server logs for details."))
			return FALSE
		to_chat(user, span_notice("Route prepared!"))

	// Verify corridor manager exists and has floor turfs
	if(!GLOB.expedition_corridor)
		to_chat(user, span_warning("Expedition corridor not initialized."))
		return FALSE

	if(!length(GLOB.expedition_corridor.floor_turfs))
		to_chat(user, span_warning("Expedition corridor has no valid turfs. Check the map file."))
		return FALSE

	// Set departure console for return teleportation
	forming_expedition.departure_console = src

	// Start the expedition
	if(!forming_expedition.depart())
		to_chat(user, span_warning("Failed to start expedition."))
		return FALSE

	// Clear from console (expedition is now active)
	var/datum/expedition_party/departing = forming_expedition
	forming_expedition = null

	// Clear selection
	selected_x = 0
	selected_y = 0
	planned_route = null

	// Notify
	for(var/mob/living/M in departing.members)
		to_chat(M, span_boldnotice("The expedition departs!"))

	// Update the UI to reflect the expedition departure
	SStgui.update_uis(src)

	return TRUE
