// Facility Tactical Map System
// Manager-controlled tactical planning and coordination

// Global storage for facility tactical maps
GLOBAL_LIST_EMPTY(facility_tactical_maps)
GLOBAL_LIST_INIT(facility_tactical_annotations, list())
GLOBAL_VAR_INIT(facility_tactical_annotation_id, 0)

/obj/machinery/facility_tactical_map
	name = "facility tactical command map"
	desc = "A tactical planning interface for facility management. Authorized personnel can draw on this."
	icon = 'icons/obj/machines/facilitymap.dmi'
	icon_state = "station_map"
	anchored = TRUE
	density = FALSE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	layer = ABOVE_WINDOW_LAYER
	light_color = "#6495ED"  // Cornflower blue for facility management theme
	light_range = 4
	light_power = 1
	light_system = STATIC_LIGHT

	/// The z-level this map displays
	var/map_z_level = 1
	/// Maximum number of annotations allowed
	var/max_annotations = 200
	/// Cached map grid data for TGUI
	var/list/cached_map_grid
	/// Whether the map has been initialized
	var/map_initialized = FALSE
	/// List of job titles allowed to edit this map
	var/list/allowed_editors = list("Manager")

/obj/machinery/facility_tactical_map/Initialize()
	. = ..()
	GLOB.facility_tactical_maps += src
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

/obj/machinery/facility_tactical_map/Destroy()
	GLOB.facility_tactical_maps -= src
	cached_map_grid = null
	return ..()

/obj/machinery/facility_tactical_map/proc/initialize_map()
	if(!map_initialized && SSholomap?.initialized)
		generate_map_grid()
		map_initialized = TRUE

/obj/machinery/facility_tactical_map/examine(mob/user)
	. = ..()
	. += span_notice("Click to open the tactical map interface.")
	. += span_notice("Annotations: [length(GLOB.facility_tactical_annotations)]/[max_annotations]")
	if(can_user_edit(user))
		. += span_notice("You have permission to draw on this map.")
	else
		. += span_warning("You can only view this map, not draw on it.")

/obj/machinery/facility_tactical_map/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	ui_interact(user)

/// Allow examining from a distance to open the UI in view-only mode
/obj/machinery/facility_tactical_map/examine_more(mob/user)
	. = ..()
	ui_interact(user)

/obj/machinery/facility_tactical_map/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "FacilityTacticalMap")
		ui.open()

/obj/machinery/facility_tactical_map/ui_data(mob/user)
	var/list/data = list()

	// Send annotations
	data["annotations"] = GLOB.facility_tactical_annotations

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

/obj/machinery/facility_tactical_map/ui_act(action, params)
	. = ..()
	if(.)
		return

	var/mob/user = usr

	// Most actions require edit permission
	if(action != "refresh" && !can_user_edit(user))
		return FALSE

	switch(action)
		if("add_annotation")
			return add_annotation(user, params)
		if("delete_annotation")
			return delete_annotation(user, params)
		if("clear_all")
			return clear_all_annotations(user)
		if("undo")
			return undo_last_annotation(user)
		if("erase_at")
			return erase_at_position(user, params)
		if("refresh")
			return TRUE

	return FALSE

// ===== ANNOTATION MANAGEMENT =====

/obj/machinery/facility_tactical_map/proc/add_annotation(mob/user, list/params)
	if(!params || !params["type"])
		return FALSE

	// Check annotation limit
	if(length(GLOB.facility_tactical_annotations) >= max_annotations)
		to_chat(user, span_warning("Maximum annotation limit reached!"))
		return FALSE

	// Create new annotation
	var/list/annotation = list(
		"id" = ++GLOB.facility_tactical_annotation_id,
		"type" = params["type"],
		"x1" = text2num(params["x1"]),
		"y1" = text2num(params["y1"]),
		"color" = params["color"] || "#FF0000",
		"author" = user.name,
		"ckey" = user.ckey
	)

	// Add type-specific data
	switch(params["type"])
		if("point")
			// Just x1, y1
		if("line", "rect", "circle")
			annotation["x2"] = text2num(params["x2"])
			annotation["y2"] = text2num(params["y2"])
		if("text")
			annotation["text"] = params["text"] || ""
			annotation["x2"] = text2num(params["x2"])
			annotation["y2"] = text2num(params["y2"])
		if("icon")
			annotation["icon"] = params["icon"] || "waypoint"
		if("freeform")
			annotation["points"] = params["points"]

	GLOB.facility_tactical_annotations += list(annotation)

	log_game("[user.ckey] ([user]) added facility tactical annotation: [params["type"]] at ([annotation["x1"]], [annotation["y1"]])")

	update_all_uis()
	return TRUE

/obj/machinery/facility_tactical_map/proc/delete_annotation(mob/user, list/params)
	if(!params || !params["id"])
		return FALSE

	var/annotation_id = text2num(params["id"])

	for(var/list/annotation in GLOB.facility_tactical_annotations)
		if(annotation["id"] == annotation_id)
			GLOB.facility_tactical_annotations -= list(annotation)
			log_game("[user.ckey] ([user]) deleted facility tactical annotation ID [annotation_id]")
			update_all_uis()
			return TRUE

	return FALSE

/obj/machinery/facility_tactical_map/proc/clear_all_annotations(mob/user)
	var/annotation_count = length(GLOB.facility_tactical_annotations)
	GLOB.facility_tactical_annotations = list()
	GLOB.facility_tactical_annotation_id = 0

	log_game("[user.ckey] ([user]) cleared all facility tactical annotations ([annotation_count] total)")

	update_all_uis()
	return TRUE

/obj/machinery/facility_tactical_map/proc/undo_last_annotation(mob/user)
	if(!length(GLOB.facility_tactical_annotations))
		return FALSE

	var/list/last_annotation = GLOB.facility_tactical_annotations[length(GLOB.facility_tactical_annotations)]
	GLOB.facility_tactical_annotations -= list(last_annotation)

	log_game("[user.ckey] ([user]) undid last facility tactical annotation")

	update_all_uis()
	return TRUE

/obj/machinery/facility_tactical_map/proc/erase_at_position(mob/user, list/params)
	if(!params)
		return FALSE

	var/erase_x = text2num(params["x"])
	var/erase_y = text2num(params["y"])
	var/erase_radius = text2num(params["radius"]) || 10

	var/deleted_count = 0
	for(var/list/annotation in GLOB.facility_tactical_annotations)
		var/x1 = annotation["x1"]
		var/y1 = annotation["y1"]

		if(sqrt((x1 - erase_x) ** 2 + (y1 - erase_y) ** 2) <= erase_radius)
			GLOB.facility_tactical_annotations -= list(annotation)
			deleted_count++

	if(deleted_count > 0)
		log_game("[user.ckey] ([user]) erased [deleted_count] facility tactical annotations at ([erase_x], [erase_y])")
		update_all_uis()
		return TRUE

	return FALSE

// ===== PERMISSION SYSTEM =====

/obj/machinery/facility_tactical_map/proc/can_user_edit(mob/user)
	if(!isliving(user))
		return FALSE

	// Admins can always edit
	if(user.client && check_rights_for(user.client, R_ADMIN, FALSE))
		return TRUE

	// Check if user has an allowed role
	var/mob/living/carbon/human/H = user
	if(!istype(H))
		return FALSE

	if(!H.mind?.assigned_role)
		return FALSE

	// Check if user's job title is in the allowed editors list
	if(H.mind.assigned_role.title in allowed_editors)
		return TRUE

	return FALSE

// ===== MAP GENERATION =====

/obj/machinery/facility_tactical_map/proc/generate_map_grid()
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

// ===== UI SYNCHRONIZATION =====

/obj/machinery/facility_tactical_map/proc/update_all_uis()
	// Update all facility tactical map UIs
	for(var/obj/machinery/facility_tactical_map/M in GLOB.facility_tactical_maps)
		SStgui.update_uis(M)

// ===== READ-ONLY DISPLAY VARIANT =====

/obj/machinery/facility_tactical_map/display
	name = "facility tactical map display"
	desc = "Displays tactical information from Command. Read-only."
	icon_state = "computer_display"

/obj/machinery/facility_tactical_map/display/can_user_edit(mob/user)
	// Only admins can edit display machines (for debugging)
	if(user.client && check_rights_for(user.client, R_ADMIN, FALSE))
		return TRUE

	return FALSE
