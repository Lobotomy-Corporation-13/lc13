// Facility Tactical Map System
// Manager-controlled tactical planning and coordination

// Global storage for facility tactical maps
GLOBAL_LIST_EMPTY(facility_tactical_maps)
GLOBAL_LIST_INIT(facility_tactical_annotations, list())
GLOBAL_VAR_INIT(facility_tactical_annotation_id, 0)

/obj/machinery/facility_tactical_map
	name = "facility tactical command map"
	desc = "A tactical planning interface for facility management. Authorized personnel can draw on this."
	icon = 'icons/obj/machines/cryopod.dmi'
	icon_state = "cellconsole"
	color = "#00d9ff"
	anchored = TRUE
	density = FALSE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	layer = ABOVE_WINDOW_LAYER

	/// The z-level this map displays
	var/map_z_level = 2
	/// Maximum number of annotations allowed
	var/max_annotations = 200
	/// Cached map grid data for TGUI
	var/list/cached_map_grid
	/// Whether the map has been initialized
	var/map_initialized = FALSE
	/// List of job titles allowed to edit this map
	var/list/allowed_editors = list("Manager", "Extraction Officer", "Records Officer")
	//Automatic update it's Z level to match it's level?
	var/auto_update = FALSE


/obj/machinery/facility_tactical_map/Initialize()
	. = ..()
	GLOB.facility_tactical_maps += src
	if(auto_update)
		map_z_level = z

	// Generate map grid after a delay to ensure map is fully loaded
	addtimer(CALLBACK(src, PROC_REF(delayed_map_init)), 10 SECONDS)

/// Delayed initialization to ensure map is fully loaded
/obj/machinery/facility_tactical_map/proc/delayed_map_init()
	if(!cached_map_grid && SSholomap?.initialized)
		generate_map_grid()

/obj/machinery/facility_tactical_map/Destroy()
	GLOB.facility_tactical_maps -= src
	cached_map_grid = null
	return ..()

/// Returns the annotation list for this map's z-level, initializing it if needed
/obj/machinery/facility_tactical_map/proc/get_z_annotations()
	var/z_key = "[map_z_level]"
	if(!GLOB.facility_tactical_annotations[z_key])
		GLOB.facility_tactical_annotations[z_key] = list()
	return GLOB.facility_tactical_annotations[z_key]

/obj/machinery/facility_tactical_map/proc/initialize_map()
	if(!map_initialized && SSholomap?.initialized)
		generate_map_grid()
		map_initialized = TRUE

/obj/machinery/facility_tactical_map/examine(mob/user)
	. = ..()
	. += span_notice("Click to open the tactical map interface.")
	. += span_notice("Annotations: [length(get_z_annotations())]/[max_annotations]")
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
	// Ensure map grid is generated before opening UI
	if(!cached_map_grid && SSholomap?.initialized)
		generate_map_grid()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "FacilityTacticalMap")
		ui.open()

/// Static data sent only once when UI opens (map grid doesn't change)
/obj/machinery/facility_tactical_map/ui_static_data(mob/user)
	var/list/data = list()

	// Send map grid once on UI open (it never changes after initialization)
	if(cached_map_grid)
		data["mapGrid"] = cached_map_grid
		data["mapWidth"] = length(cached_map_grid)
		data["mapHeight"] = length(cached_map_grid) > 0 ? length(cached_map_grid[1]) : 0
	else
		data["mapGrid"] = null
		data["mapWidth"] = 0
		data["mapHeight"] = 0

	return data

/// Dynamic data sent on each update (annotations change frequently)
/obj/machinery/facility_tactical_map/ui_data(mob/user)
	var/list/data = list()

	// Send annotations for this z-level (dynamic data)
	data["annotations"] = get_z_annotations()

	// Send permission and config data
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

	var/list/z_annotations = get_z_annotations()

	// Check annotation limit
	if(length(z_annotations) >= max_annotations)
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
			annotation["fontSize"] = text2num(params["fontSize"]) || 14
		if("icon")
			annotation["icon"] = params["icon"] || "waypoint"
		if("freeform")
			annotation["points"] = params["points"]

	z_annotations += list(annotation)

	log_game("[user.ckey] ([user]) added facility tactical annotation: [params["type"]] at ([annotation["x1"]], [annotation["y1"]])")

	// Note: UI updates are now manual - user must press Update button
	return TRUE

/obj/machinery/facility_tactical_map/proc/delete_annotation(mob/user, list/params)
	if(!params || !params["id"])
		return FALSE

	var/annotation_id = text2num(params["id"])
	var/list/z_annotations = get_z_annotations()

	for(var/list/annotation in z_annotations)
		if(annotation["id"] == annotation_id)
			z_annotations -= list(annotation)
			log_game("[user.ckey] ([user]) deleted facility tactical annotation ID [annotation_id]")
			return TRUE

	return FALSE

/obj/machinery/facility_tactical_map/proc/clear_all_annotations(mob/user)
	var/list/z_annotations = get_z_annotations()
	var/annotation_count = length(z_annotations)
	z_annotations.Cut()

	log_game("[user.ckey] ([user]) cleared facility tactical annotations on z-level [map_z_level] ([annotation_count] total)")

	return TRUE

/obj/machinery/facility_tactical_map/proc/undo_last_annotation(mob/user)
	var/list/z_annotations = get_z_annotations()
	if(!length(z_annotations))
		return FALSE

	var/list/last_annotation = z_annotations[length(z_annotations)]
	z_annotations -= list(last_annotation)

	log_game("[user.ckey] ([user]) undid last facility tactical annotation on z-level [map_z_level]")

	return TRUE

/obj/machinery/facility_tactical_map/proc/erase_at_position(mob/user, list/params)
	if(!params)
		return FALSE

	var/erase_x = text2num(params["x"])
	var/erase_y = text2num(params["y"])
	var/erase_radius = text2num(params["radius"]) || 10
	var/list/z_annotations = get_z_annotations()

	var/deleted_count = 0
	for(var/list/annotation in z_annotations)
		var/x1 = annotation["x1"]
		var/y1 = annotation["y1"]

		if(sqrt((x1 - erase_x) ** 2 + (y1 - erase_y) ** 2) <= erase_radius)
			z_annotations -= list(annotation)
			deleted_count++

	if(deleted_count > 0)
		log_game("[user.ckey] ([user]) erased [deleted_count] facility tactical annotations at ([erase_x], [erase_y]) on z-level [map_z_level]")
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
	if(H.mind.assigned_role in allowed_editors)
		return TRUE

	return FALSE

// ===== MAP GENERATION =====

/obj/machinery/facility_tactical_map/proc/generate_map_grid()
	// First pass: find the bounding box of actual map content
	var/min_x = world.maxx
	var/max_x = 1
	var/min_y = world.maxy
	var/max_y = 1

	for(var/tx in 1 to world.maxx)
		for(var/ty in 1 to world.maxy)
			var/turf/T = locate(tx, ty, map_z_level)
			if(T)
				var/area/A = T.loc
				if(A && !(A.area_flags & HIDE_FROM_HOLOMAP))
					if(istype(T, /turf/closed/wall) || istype(T, /turf/closed/indestructible) || istype(T, /turf/open/floor) || istype(T, /turf/closed/mineral))
						min_x = min(min_x, tx)
						max_x = max(max_x, tx)
						min_y = min(min_y, ty)
						max_y = max(max_y, ty)

	// Add small padding around the content
	var/padding = 2
	min_x = max(1, min_x - padding)
	max_x = min(world.maxx, max_x + padding)
	min_y = max(1, min_y - padding)
	max_y = min(world.maxy, max_y + padding)

	// Second pass: generate the cropped grid
	var/grid_width = max_x - min_x + 1
	var/grid_height = max_y - min_y + 1

	cached_map_grid = list()

	for(var/gx in 1 to grid_width)
		var/list/column = list()
		for(var/gy in 1 to grid_height)
			var/tx = min_x + gx - 1
			var/ty = min_y + gy - 1
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
	// Update facility tactical map UIs on the same z-level
	for(var/obj/machinery/facility_tactical_map/M in GLOB.facility_tactical_maps)
		if(M.map_z_level == map_z_level)
			SStgui.update_uis(M)
