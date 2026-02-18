// RCE Tactical Map - A drawable command map for coordinating R-Corp operations
// Displays facility layout with drawing capabilities synced to all RCE team members

/// Global list of all tactical map machines for syncing
GLOBAL_LIST_EMPTY(rce_tactical_maps)

/// Static annotation data shared across all tactical map instances
GLOBAL_LIST_INIT(rce_tactical_annotations, list())

/// Counter for unique annotation IDs
GLOBAL_VAR_INIT(rce_tactical_annotation_id, 0)

/obj/machinery/rce_tactical_map
	name = "RCE tactical map"
	desc = "A tactical display for coordinating R-Corp operations. Click to interact."
	icon = 'icons/obj/machines/facilitymap.dmi'
	icon_state = "station_map"
	anchored = TRUE
	density = FALSE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	layer = ABOVE_WINDOW_LAYER

	/// The z-level this map displays
	var/map_z_level = 1
	/// Maximum number of annotations allowed
	var/max_annotations = 100
	/// Cached map grid data for TGUI
	var/list/cached_map_grid

/obj/machinery/rce_tactical_map/Initialize()
	. = ..()
	GLOB.rce_tactical_maps += src
	map_z_level = z

	// Pixel offsets based on direction (like facility_holomap)
	switch(dir)
		if(NORTH)
			pixel_x = 0
			pixel_y = -32
		if(SOUTH)
			pixel_x = 0
			pixel_y = 32
		if(WEST)
			pixel_x = 32
			pixel_y = 0
		if(EAST)
			pixel_x = -32
			pixel_y = 0

	// Generate map grid after holomap system initializes
	if(SSholomap.initialized)
		generate_map_grid()

/obj/machinery/rce_tactical_map/Destroy()
	GLOB.rce_tactical_maps -= src
	cached_map_grid = null
	return ..()

/obj/machinery/rce_tactical_map/examine(mob/user)
	. = ..()
	. += span_notice("Click to open the tactical map interface.")
	. += span_notice("Annotations: [length(GLOB.rce_tactical_annotations)]/[max_annotations]")
	if(can_user_edit(user))
		. += span_notice("You have permission to draw on this map.")
	else
		. += span_warning("You can only view this map, not draw on it.")

/obj/machinery/rce_tactical_map/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	ui_interact(user)

/// Allow examining from a distance to open the UI in view-only mode
/obj/machinery/rce_tactical_map/examine_more(mob/user)
	. = ..()
	// Open the UI when examining from any distance
	ui_interact(user)

/obj/machinery/rce_tactical_map/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RCETacticalMap")
		ui.open()

/obj/machinery/rce_tactical_map/ui_data(mob/user)
	var/list/data = list()

	// Send annotations
	data["annotations"] = GLOB.rce_tactical_annotations

	// Send map grid if cached
	if(cached_map_grid)
		data["mapGrid"] = cached_map_grid
		data["mapWidth"] = length(cached_map_grid)
		data["mapHeight"] = length(cached_map_grid) > 0 ? length(cached_map_grid[1]) : 0
	else
		data["mapGrid"] = null
		data["mapWidth"] = 0
		data["mapHeight"] = 0

	data["maxAnnotations"] = max_annotations
	data["canEdit"] = can_user_edit(user)
	data["isAdmin"] = check_rights_for(user.client, R_ADMIN, FALSE)

	return data

/obj/machinery/rce_tactical_map/ui_act(action, params)
	. = ..()
	if(.)
		return

	var/mob/user = usr
	if(!can_user_edit(user))
		to_chat(user, span_warning("You don't have permission to edit the tactical map!"))
		return FALSE

	switch(action)
		if("add_annotation")
			if(length(GLOB.rce_tactical_annotations) >= max_annotations)
				to_chat(user, span_warning("Maximum annotations reached!"))
				return FALSE

			var/annotation_type = params["type"]
			var/x1 = params["x1"]
			var/y1 = params["y1"]
			var/x2 = params["x2"]
			var/y2 = params["y2"]
			var/color = params["color"]
			var/text = params["text"]
			var/icon_type = params["icon"]
			var/list/points = params["points"]

			GLOB.rce_tactical_annotation_id++
			var/list/annotation = list(
				"id" = GLOB.rce_tactical_annotation_id,
				"type" = annotation_type,
				"x1" = x1,
				"y1" = y1,
				"x2" = x2,
				"y2" = y2,
				"color" = color,
				"text" = text,
				"icon" = icon_type,
				"points" = points,
				"author" = user.name,
				"ckey" = user.ckey
			)

			GLOB.rce_tactical_annotations += list(annotation)
			update_all_uis()
			return TRUE

		if("delete_annotation")
			var/annotation_id = text2num(params["id"])
			for(var/i in 1 to length(GLOB.rce_tactical_annotations))
				var/list/annotation = GLOB.rce_tactical_annotations[i]
				if(annotation["id"] == annotation_id)
					GLOB.rce_tactical_annotations.Cut(i, i + 1)
					update_all_uis()
					return TRUE
			return FALSE

		if("clear_all")
			GLOB.rce_tactical_annotations.Cut()
			GLOB.rce_tactical_annotation_id = 0
			update_all_uis()
			to_chat(user, span_notice("All annotations cleared."))
			return TRUE

		if("undo")
			if(length(GLOB.rce_tactical_annotations))
				GLOB.rce_tactical_annotations.Cut(length(GLOB.rce_tactical_annotations))
				update_all_uis()
				return TRUE
			return FALSE

		if("erase_at")
			var/erase_x = text2num(params["x"])
			var/erase_y = text2num(params["y"])
			var/erase_radius = 5  // How close the click needs to be to delete
			var/closest_index = 0
			var/closest_dist = INFINITY

			// Find the closest annotation to the click point
			for(var/i in 1 to length(GLOB.rce_tactical_annotations))
				var/list/annotation = GLOB.rce_tactical_annotations[i]
				var/ann_x = annotation["x1"]
				var/ann_y = annotation["y1"]

				// For freeform, check first point
				if(annotation["type"] == "freeform")
					var/list/points = annotation["points"]
					if(length(points) > 0)
						ann_x = points[1]["x"]
						ann_y = points[1]["y"]

				var/dist = sqrt((ann_x - erase_x) ** 2 + (ann_y - erase_y) ** 2)
				if(dist < closest_dist && dist < erase_radius)
					closest_dist = dist
					closest_index = i

			if(closest_index > 0)
				GLOB.rce_tactical_annotations.Cut(closest_index, closest_index + 1)
				update_all_uis()
				return TRUE
			return FALSE

	return FALSE

/// List of job titles that can draw on the tactical map
GLOBAL_LIST_INIT(rce_tactical_map_editors, list(
	"Operations Commander",
	"Executive Officer",
	"Base Commander"
))

/// Check if user can edit the tactical map
/obj/machinery/rce_tactical_map/proc/can_user_edit(mob/user)
	if(!isliving(user))
		return FALSE

	// Admins can always edit
	if(user.client && check_rights_for(user.client, R_ADMIN, FALSE))
		return TRUE

	// Check if user has a command role
	var/mob/living/carbon/human/H = user
	if(!istype(H))
		return FALSE

	var/datum/job/user_job = H.mind?.assigned_role
	if(!user_job)
		return FALSE

	// Check job title against allowed editors list
	if(user_job in GLOB.rce_tactical_map_editors)
		return TRUE

	return FALSE

/// Update all tactical map UIs
/obj/machinery/rce_tactical_map/proc/update_all_uis()
	for(var/obj/machinery/rce_tactical_map/M in GLOB.rce_tactical_maps)
		SStgui.update_uis(M)

/// Generate simplified map grid from z-level turfs
/obj/machinery/rce_tactical_map/proc/generate_map_grid()
	// Use a reduced resolution for performance
	var/grid_scale = 2  // Each grid cell represents 2x2 turfs
	var/grid_width = round(world.maxx / grid_scale)
	var/grid_height = round(world.maxy / grid_scale)

	cached_map_grid = list()

	for(var/gx in 1 to grid_width)
		var/list/column = list()
		for(var/gy in 1 to grid_height)
			var/tx = gx * grid_scale
			var/ty = gy * grid_scale
			var/turf/T = locate(tx, ty, map_z_level)

			var/color = "#000000"  // Default: space/void

			if(T)
				var/area/A = T.loc
				if(A && !(A.area_flags & HIDE_FROM_HOLOMAP))
					if(istype(T, /turf/closed/wall) || istype(T, /turf/closed/indestructible))
						color = "#444444"  // Walls
					else if(istype(T, /turf/open/floor))
						color = "#888888"  // Floors
					else if(istype(T, /turf/closed/mineral))
						color = "#333333"  // Rock

			column += color
		cached_map_grid += list(column)
