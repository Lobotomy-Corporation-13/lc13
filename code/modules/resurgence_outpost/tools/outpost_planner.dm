/**
 * Resurgence Outpost - Outpost Planner
 *
 * Combined tool for blueprint placement and room designation.
 * Uses TGUI interface with tabs for Blueprints and Room Management.
 */

/// Blueprint category defines
#define BLUEPRINT_CAT_CONSTRUCTION "Construction"
#define BLUEPRINT_CAT_STORAGE "Storage"
#define BLUEPRINT_CAT_PRODUCTION "Production"
#define BLUEPRINT_CAT_FURNITURE "Furniture"

/obj/item/resurgence_outpost_planner
	name = "outpost planner"
	desc = "A versatile planning tool for the Resurgence Outpost. Use it to place construction blueprints or designate enclosed spaces as rooms."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "blueprints"
	w_class = WEIGHT_CLASS_SMALL
	item_flags = NOBLUDGEON

	// ===== Blueprint Planner Variables =====

	/// Currently selected blueprint type path
	var/selected_blueprint = null
	/// Display name of selected blueprint
	var/selected_name = null
	/// Currently viewed category
	var/selected_category = BLUEPRINT_CAT_CONSTRUCTION
	/// Currently selected direction for placement
	var/selected_direction = SOUTH

	/// Categories and their blueprints: list("Category" = list("Name" = blueprint_type))
	var/static/list/blueprint_categories

	// ===== Room Designator Variables =====

	/// Whether the tool is currently being used for room operations (prevents spam)
	var/in_use = FALSE

	// ===== Farming Zone Variables =====

	/// Whether we're in farming zone selection mode
	var/farming_mode = FALSE
	/// Turfs selected for new zone
	var/list/farming_zone_selection = list()
	/// Selection overlay effects
	var/list/selection_overlays = list()
	/// Maximum tiles per farming zone
	var/static/farming_max_tiles = 16

/obj/item/resurgence_outpost_planner/Initialize(mapload)
	. = ..()
	if(!blueprint_categories)
		init_blueprint_categories()

/// Initialize the static list of blueprint categories
/obj/item/resurgence_outpost_planner/proc/init_blueprint_categories()
	blueprint_categories = list()

	// Construction category - walls, floors, structures
	blueprint_categories[BLUEPRINT_CAT_CONSTRUCTION] = list(
		"Wood Wall" = /obj/structure/resurgence_blueprint/wood_wall,
		"Iron Wall" = /obj/structure/resurgence_blueprint/iron_wall,
		"Sandstone Wall" = /obj/structure/resurgence_blueprint/sandstone_wall,
		"Gold Wall" = /obj/structure/resurgence_blueprint/gold_wall,
		"Silver Wall" = /obj/structure/resurgence_blueprint/silver_wall,
		"Reinforced Wall" = /obj/structure/resurgence_blueprint/reinforced_wall,
		"Wood Door" = /obj/structure/resurgence_blueprint/wood_door,
		"Iron Door" = /obj/structure/resurgence_blueprint/iron_door,
		"Silver Door" = /obj/structure/resurgence_blueprint/silver_door,
		"Gold Door" = /obj/structure/resurgence_blueprint/gold_door,
		"Sandstone Door" = /obj/structure/resurgence_blueprint/sandstone_door,
		"Wood Floor" = /obj/structure/resurgence_blueprint/wood_floor,
		"Iron Floor" = /obj/structure/resurgence_blueprint/iron_floor,
		"Sandstone Floor" = /obj/structure/resurgence_blueprint/sandstone_floor
	)

	// Storage category - chests, crates
	blueprint_categories[BLUEPRINT_CAT_STORAGE] = list(
		"Storage Chest" = /obj/structure/resurgence_blueprint/storage_chest,
		"Crate" = /obj/structure/resurgence_blueprint/crate,
		"Large Crate" = /obj/structure/resurgence_blueprint/barrel
	)

	// Production category - crafting stations
	blueprint_categories[BLUEPRINT_CAT_PRODUCTION] = list(
		"Crafting Table" = /obj/structure/resurgence_blueprint/crafting_table,
		"Forge" = /obj/structure/resurgence_blueprint/forge,
		"Loom" = /obj/structure/resurgence_blueprint/loom,
		"Seed Extractor" = /obj/structure/resurgence_blueprint/seed_extractor
	)

	// Furniture category - beds, chairs, tables, racks
	blueprint_categories[BLUEPRINT_CAT_FURNITURE] = list(
		"Bed" = /obj/structure/resurgence_blueprint/bed,
		"Chair" = /obj/structure/resurgence_blueprint/chair,
		"Table" = /obj/structure/resurgence_blueprint/table,
		"Table Frame" = /obj/structure/resurgence_blueprint/table_frame,
		"Rack" = /obj/structure/resurgence_blueprint/rack
	)

/obj/item/resurgence_outpost_planner/examine(mob/user)
	. = ..()
	. += span_notice("Click in hand to open the planning interface.")
	if(selected_blueprint)
		. += span_notice("Currently selected: <b>[selected_name]</b>")
		. += span_notice("Click on the ground to place the blueprint.")

/obj/item/resurgence_outpost_planner/attack_self(mob/user)
	. = ..()
	ui_interact(user)

// ===== TGUI Interface =====

/obj/item/resurgence_outpost_planner/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "OutpostPlanner", "Outpost Planner")
		ui.open()

/obj/item/resurgence_outpost_planner/ui_data(mob/user)
	var/list/data = list()

	// Build category data with structure info
	var/list/categories_data = list()
	for(var/cat_name in blueprint_categories)
		var/list/cat_data = list(
			"name" = cat_name,
			"structures" = list()
		)
		for(var/struct_name in blueprint_categories[cat_name])
			var/blueprint_type = blueprint_categories[cat_name][struct_name]
			var/list/struct_data = get_structure_data(struct_name, blueprint_type)
			cat_data["structures"] += list(struct_data)
		categories_data += list(cat_data)

	data["categories"] = categories_data
	data["selected_category"] = selected_category
	data["selected_name"] = selected_name
	data["selected_type"] = selected_blueprint ? "[selected_blueprint]" : null
	data["selected_direction"] = dir2text(selected_direction)

	// Room data
	var/turf/user_turf = get_turf(user)
	var/area/resurgence_outpost/room/current_room = get_area(user_turf)

	if(istype(current_room))
		// User is in a designated room
		data["in_room"] = TRUE
		data["room_name"] = current_room.name
		data["room_type"] = current_room.room_type
		data["room_faith_modifier"] = get_faith_modifier_info(current_room.room_type)

		// Count room turfs
		var/room_size = 0
		for(var/turf/T in current_room.contents)
			room_size++
		data["room_size"] = room_size
		data["room_walls"] = current_room.boundary_walls.len
		data["room_doors"] = current_room.boundary_doors.len
	else
		// Check if we can designate a room here
		data["in_room"] = FALSE
		var/list/detection_result = detect_enclosed_room(user_turf)
		if(detection_result)
			var/list/detected_turfs = detection_result["turfs"]
			var/list/detected_walls = detection_result["boundary_walls"]
			var/list/detected_doors = detection_result["boundary_doors"]
			data["can_designate"] = TRUE
			data["detected_size"] = detected_turfs.len
			data["detected_type"] = determine_room_type(detected_turfs)
			data["detected_faith"] = get_faith_modifier_info(data["detected_type"])
			data["detected_walls"] = detected_walls.len
			data["detected_doors"] = detected_doors.len
		else
			data["can_designate"] = FALSE

	data["in_use"] = in_use

	// Farming zone data
	data["farming_mode"] = farming_mode
	data["farming_selection"] = farming_zone_selection.len
	data["farming_max"] = farming_max_tiles
	data["existing_zones"] = get_farming_zones_data()

	// Check if selection will join an existing zone
	if(farming_mode && farming_zone_selection.len > 0)
		var/datum/farm_zone/adjacent = find_adjacent_zone()
		if(adjacent)
			data["will_join_zone"] = adjacent.name
		else
			data["will_join_zone"] = null
	else
		data["will_join_zone"] = null

	return data

/// Get data for all existing farming zones
/obj/item/resurgence_outpost_planner/proc/get_farming_zones_data()
	var/list/zones = list()
	for(var/datum/farm_zone/zone in GLOB.resurgence_farm_zones)
		zones += list(zone.get_stats())
	return zones

/// Get data for a single structure
/obj/item/resurgence_outpost_planner/proc/get_structure_data(name, blueprint_type)
	var/obj/structure/resurgence_blueprint/temp = new blueprint_type()
	var/list/data = list(
		"name" = name,
		"type" = "[blueprint_type]",
		"result_name" = temp.result_name,
		"materials" = list()
	)

	// Build materials list
	for(var/mat_type in temp.required_materials)
		var/amount = temp.required_materials[mat_type]
		var/mat_name = temp.get_material_name(mat_type)
		data["materials"] += list(list(
			"name" = mat_name,
			"amount" = amount
		))

	qdel(temp)
	return data

/// Get a human-readable description of the faith modifier for a room type.
/obj/item/resurgence_outpost_planner/proc/get_faith_modifier_info(room_type)
	switch(room_type)
		if(ROOM_TYPE_WORKSHOP)
			return "-25% (focused work)"
		if(ROOM_TYPE_COMMON)
			return "+50% (community)"
		if(ROOM_TYPE_STORAGE)
			return "+10% (organization)"
		if(ROOM_TYPE_SHRINE)
			return "+75% (spiritual)"
		else
			return "+25% (shelter)"

/obj/item/resurgence_outpost_planner/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		// ===== Blueprint Actions =====
		if("select_category")
			selected_category = params["category"]
			return TRUE

		if("select_structure")
			var/struct_name = params["name"]
			var/struct_type = text2path(params["type"])
			if(struct_type && blueprint_categories[selected_category]?[struct_name])
				selected_blueprint = struct_type
				selected_name = struct_name
				to_chat(usr, span_notice("Selected: <b>[selected_name]</b>. Click on the ground to place the blueprint."))
			return TRUE

		if("clear_selection")
			selected_blueprint = null
			selected_name = null
			return TRUE

		if("set_direction")
			var/dir_text = params["direction"]
			switch(dir_text)
				if("north")
					selected_direction = NORTH
				if("south")
					selected_direction = SOUTH
				if("east")
					selected_direction = EAST
				if("west")
					selected_direction = WEST
			return TRUE

		// ===== Room Actions =====
		if("designate_room")
			if(in_use)
				return TRUE
			in_use = TRUE
			designate_new_room(usr)
			in_use = FALSE
			return TRUE

		if("highlight_room")
			highlight_current_room(usr)
			return TRUE

		if("dissolve_room")
			if(in_use)
				return TRUE
			in_use = TRUE
			dissolve_current_room(usr)
			in_use = FALSE
			return TRUE

		// ===== Farming Actions =====
		if("toggle_farming_mode")
			farming_mode = !farming_mode
			if(!farming_mode)
				clear_farming_selection()
			else
				// Clear blueprint selection when entering farming mode
				selected_blueprint = null
				selected_name = null
			return TRUE

		if("confirm_farming_zone")
			if(farming_zone_selection.len >= 1)
				// Check if we're joining an existing zone (no name needed)
				var/datum/farm_zone/adjacent = find_adjacent_zone()
				if(adjacent)
					create_farming_zone(usr, null)
				else
					var/zone_name = stripped_input(usr, "Name your farm zone:", "Farm Zone", "Farm Zone", MAX_NAME_LEN)
					if(zone_name)
						create_farming_zone(usr, zone_name)
			return TRUE

		if("clear_farming_selection")
			clear_farming_selection()
			return TRUE

		if("dissolve_zone")
			var/zone_id = text2num(params["id"])
			for(var/datum/farm_zone/zone in GLOB.resurgence_farm_zones)
				if(zone.zone_id == zone_id)
					to_chat(usr, span_notice("Dissolved farm zone '[zone.name]'."))
					qdel(zone)
					break
			return TRUE

		if("highlight_zone")
			var/zone_id = text2num(params["id"])
			for(var/datum/farm_zone/zone in GLOB.resurgence_farm_zones)
				if(zone.zone_id == zone_id)
					highlight_farm_zone(zone, usr)
					break
			return TRUE

// ===== Blueprint Placement =====

/obj/item/resurgence_outpost_planner/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()

	// Handle farming mode tile selection
	if(farming_mode)
		handle_farming_selection(target, user)
		return

	if(!selected_blueprint)
		return

	// Check if clicking on a valid ground turf
	var/turf/T = get_turf(target)
	if(!T)
		return

	// Must be adjacent to place
	if(!user.Adjacent(T))
		to_chat(user, span_warning("You're too far away to place a blueprint there."))
		return

	// Check if the turf is suitable
	if(!is_valid_placement(T, user))
		return

	// Place the blueprint
	place_blueprint(T, user)

/// Check if a turf is valid for blueprint placement
/obj/item/resurgence_outpost_planner/proc/is_valid_placement(turf/T, mob/user)
	// Can't place on space
	if(isspaceturf(T))
		to_chat(user, span_warning("You can't build in space!"))
		return FALSE

	// Can't place on water
	if(istype(T, /turf/open/water))
		to_chat(user, span_warning("You can't build on water!"))
		return FALSE

	// Check for existing blueprints
	for(var/obj/structure/resurgence_blueprint/existing in T)
		to_chat(user, span_warning("There's already a blueprint here."))
		return FALSE

	// Check for dense objects that would block construction
	for(var/obj/structure/S in T)
		if(S.density)
			to_chat(user, span_warning("Something is blocking this location."))
			return FALSE

	// Check for walls (can't place on walls unless it's a door frame, etc.)
	if(isclosedturf(T))
		to_chat(user, span_warning("You can't place a blueprint on a wall."))
		return FALSE

	return TRUE

/// Place the selected blueprint on the turf
/obj/item/resurgence_outpost_planner/proc/place_blueprint(turf/T, mob/user)
	var/obj/structure/resurgence_blueprint/BP = new selected_blueprint(T)
	if(BP)
		BP.setDir(selected_direction)
		to_chat(user, span_notice("You place a [BP.result_name] blueprint facing [dir2text(selected_direction)]. Add the required materials to build it."))
		playsound(T, 'sound/items/deconstruct.ogg', 30, TRUE)

// ===== Room Designation =====

/// Designate a new room from the current location
/obj/item/resurgence_outpost_planner/proc/designate_new_room(mob/user)
	var/turf/origin = get_turf(user)
	if(!origin)
		to_chat(user, span_warning("You must be standing somewhere to designate a room."))
		return

	// Check if already in a room
	var/area/resurgence_outpost/room/existing_room = get_area(origin)
	if(istype(existing_room))
		to_chat(user, span_warning("You're already in a designated room. Use the Room tab to manage it."))
		return

	// Detect the enclosed room
	var/list/detection_result = detect_enclosed_room(origin)

	if(!detection_result)
		to_chat(user, span_warning("You must be in a fully enclosed space with walls on all sides."))
		return

	var/list/room_turfs = detection_result["turfs"]
	var/list/boundary_walls = detection_result["boundary_walls"]
	var/list/boundary_doors = detection_result["boundary_doors"]

	if(room_turfs.len > ROOM_MAX_SIZE)
		to_chat(user, span_warning("This space is too large. Maximum [ROOM_MAX_SIZE] tiles, current: [room_turfs.len]."))
		return

	// Determine the room type based on contents
	var/room_type = determine_room_type(room_turfs)
	var/default_name = get_default_room_name(room_type)

	// Prompt for custom name
	var/custom_name = stripped_input(user, "Enter a name for this room:", "Room Designation", default_name, MAX_NAME_LEN)

	if(!custom_name)
		to_chat(user, span_notice("Room designation cancelled."))
		return

	// Verify user is still valid
	if(!user.canUseTopic(src, BE_CLOSE))
		to_chat(user, span_warning("You need to stay near the planner."))
		return

	// Create the room
	to_chat(user, span_notice("Designating room..."))
	playsound(user, 'sound/items/deconstruct.ogg', 50, TRUE)

	var/area/new_room = create_resurgence_room(room_turfs, room_type, custom_name, user, boundary_walls, boundary_doors)

	if(new_room)
		to_chat(user, span_notice("<b>Success!</b> '[custom_name]' has been designated as a [room_type]."))
		highlight_room(room_turfs)
	else
		to_chat(user, span_warning("Failed to create room. Please try again."))

/// Highlight the room the user is currently in
/obj/item/resurgence_outpost_planner/proc/highlight_current_room(mob/user)
	var/turf/origin = get_turf(user)
	var/area/resurgence_outpost/room/room = get_area(origin)

	if(!istype(room))
		to_chat(user, span_warning("You're not in a designated room."))
		return

	var/list/room_turfs = list()
	for(var/turf/T in room.contents)
		room_turfs += T

	to_chat(user, span_notice("Highlighting '[room.name]'..."))
	playsound(user, 'sound/items/deconstruct.ogg', 30, TRUE)
	highlight_room(room_turfs)

/// Dissolve the room the user is currently in
/obj/item/resurgence_outpost_planner/proc/dissolve_current_room(mob/user)
	var/turf/origin = get_turf(user)
	var/area/resurgence_outpost/room/room = get_area(origin)

	if(!istype(room))
		to_chat(user, span_warning("You're not in a designated room."))
		return

	// Confirm dissolution
	var/confirm = tgui_alert(user, "Are you sure you want to dissolve '[room.name]'? This cannot be undone.", "Confirm Dissolution", list("Yes", "No"))
	if(confirm != "Yes")
		to_chat(user, span_notice("Room dissolution cancelled."))
		return

	// Verify user is still valid
	if(!user.canUseTopic(src, BE_CLOSE))
		to_chat(user, span_warning("You need to stay near the planner."))
		return

	// Check room still exists
	if(QDELETED(room) || room.dissolving)
		to_chat(user, span_warning("The room no longer exists."))
		return

	to_chat(user, span_notice("Dissolving '[room.name]'..."))
	playsound(user, 'sound/items/deconstruct.ogg', 50, TRUE)
	room.dissolve_room("Manually dissolved by [user.name].")

/// Briefly highlight room turfs with a visual effect
/obj/item/resurgence_outpost_planner/proc/highlight_room(list/turfs)
	for(var/turf/T in turfs)
		var/obj/effect/temp_visual/decoy/fading/highlight = new(T)
		highlight.name = "room boundary"
		highlight.icon = 'icons/effects/effects.dmi'
		highlight.icon_state = "shieldsparkles"
		highlight.color = "#88ff88"
		highlight.alpha = 128
		QDEL_IN(highlight, 2 SECONDS)

// ===== Farming Zone Management =====

/// Handle tile selection for farming zones
/obj/item/resurgence_outpost_planner/proc/handle_farming_selection(atom/target, mob/user)
	var/turf/T = get_turf(target)
	if(!T || !user.Adjacent(T))
		return

	if(!is_valid_farm_tile(T))
		to_chat(user, span_warning("This tile cannot be farmed."))
		return

	// Toggle selection - removing is always allowed
	if(T in farming_zone_selection)
		farming_zone_selection -= T
		remove_selection_overlay(T)
		to_chat(user, span_notice("Removed tile from selection. ([farming_zone_selection.len]/[farming_max_tiles])"))
	else if(farming_zone_selection.len < farming_max_tiles)
		// Check adjacency requirement (first tile is free, rest must be adjacent)
		if(farming_zone_selection.len > 0 && !is_adjacent_to_selection(T))
			to_chat(user, span_warning("New tiles must be adjacent to existing selection."))
			return
		farming_zone_selection += T
		add_selection_overlay(T)
		to_chat(user, span_notice("Added tile to selection. ([farming_zone_selection.len]/[farming_max_tiles])"))
	else
		to_chat(user, span_warning("Maximum [farming_max_tiles] tiles per zone."))

	SStgui.update_uis(src)

/// Check if a turf is adjacent to any already-selected turf
/obj/item/resurgence_outpost_planner/proc/is_adjacent_to_selection(turf/T)
	for(var/turf/selected in farming_zone_selection)
		if(get_dist(T, selected) == 1)
			return TRUE
	return FALSE

/// Check if a turf is valid for farming
/obj/item/resurgence_outpost_planner/proc/is_valid_farm_tile(turf/T)
	if(isspaceturf(T))
		return FALSE
	if(isclosedturf(T))
		return FALSE
	if(istype(T, /turf/open/water))
		return FALSE
	// Check for existing farm plots
	for(var/obj/structure/farm_plot/plot in T)
		return FALSE
	// Check for dense objects
	for(var/obj/O in T)
		if(O.density)
			return FALSE
	return TRUE

/// Add a selection overlay to a turf
/obj/item/resurgence_outpost_planner/proc/add_selection_overlay(turf/T)
	var/obj/effect/farm_selection_overlay/selection = new(T)
	selection_overlays[T] = selection

/// Remove a selection overlay from a turf
/obj/item/resurgence_outpost_planner/proc/remove_selection_overlay(turf/T)
	var/obj/effect/farm_selection_overlay/selection = selection_overlays[T]
	if(selection)
		qdel(selection)
		selection_overlays -= T

/// Visual overlay for farm zone tile selection
/obj/effect/farm_selection_overlay
	name = "farm zone selection"
	desc = "This tile is selected for a farm zone."
	icon = 'icons/effects/effects.dmi'
	icon_state = "shieldsparkles"
	layer = ABOVE_MOB_LAYER
	color = "#88ff88"
	alpha = 180
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/// Clear all farming zone selections
/obj/item/resurgence_outpost_planner/proc/clear_farming_selection()
	for(var/turf/T in farming_zone_selection)
		remove_selection_overlay(T)
	farming_zone_selection.Cut()
	selection_overlays.Cut()

/// Find an existing farm zone adjacent to any of the selected tiles
/obj/item/resurgence_outpost_planner/proc/find_adjacent_zone()
	for(var/turf/T in farming_zone_selection)
		// Check all cardinal directions for existing farm plots
		for(var/dir in GLOB.cardinals)
			var/turf/adjacent = get_step(T, dir)
			for(var/obj/structure/farm_plot/plot in adjacent)
				if(plot.parent_zone)
					return plot.parent_zone
	return null

/// Create a farming zone from selected tiles (or add to existing adjacent zone)
/obj/item/resurgence_outpost_planner/proc/create_farming_zone(mob/user, zone_name)
	// Check for adjacent existing zone first
	var/datum/farm_zone/zone = find_adjacent_zone()
	var/joined_existing = FALSE

	if(zone)
		joined_existing = TRUE
	else
		zone = new(zone_name)

	var/plots_created = 0
	for(var/turf/T in farming_zone_selection)
		var/obj/structure/farm_plot/plot = new(T)
		zone.add_plot(plot)
		plots_created++

	clear_farming_selection()
	farming_mode = FALSE

	if(joined_existing)
		to_chat(user, span_notice("Added [plots_created] plots to existing zone '[zone.name]'."))
	else
		to_chat(user, span_notice("Created farm zone '[zone_name]' with [plots_created] plots."))
	playsound(user, 'sound/items/deconstruct.ogg', 50, TRUE)
	SStgui.update_uis(src)

/// Highlight an existing farm zone's plots
/obj/item/resurgence_outpost_planner/proc/highlight_farm_zone(datum/farm_zone/zone, mob/user)
	to_chat(user, span_notice("Highlighting farm zone '[zone.name]'..."))
	playsound(user, 'sound/items/deconstruct.ogg', 30, TRUE)

	for(var/obj/structure/farm_plot/plot in zone.plots)
		var/turf/T = get_turf(plot)
		if(T)
			var/obj/effect/temp_visual/decoy/fading/highlight = new(T)
			highlight.name = "farm plot"
			highlight.icon = 'icons/effects/effects.dmi'
			highlight.icon_state = "shieldsparkles"
			highlight.color = "#88ff88"
			highlight.alpha = 180
			QDEL_IN(highlight, 3 SECONDS)

#undef BLUEPRINT_CAT_CONSTRUCTION
#undef BLUEPRINT_CAT_STORAGE
#undef BLUEPRINT_CAT_PRODUCTION
#undef BLUEPRINT_CAT_FURNITURE
