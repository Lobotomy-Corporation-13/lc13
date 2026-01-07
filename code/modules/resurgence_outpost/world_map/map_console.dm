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

/obj/structure/world_map_console/Initialize(mapload)
	. = ..()
	// Ensure world map is generated
	init_resurgence_world_map()

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
				if(tile && tile.discovered)
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
				// TODO: Open expedition signup UI
				to_chat(usr, span_notice("Expedition planning not yet implemented. Route has [length(planned_route)] tiles."))
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
