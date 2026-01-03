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
	/// Cooldown on highlight operations (prevents spam)
	var/highlight_cooldown = FALSE
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
		"Wooden Crate" = /obj/structure/resurgence_blueprint/storage_chest,
		"Metal Crate" = /obj/structure/resurgence_blueprint/crate,
		"Large Crate" = /obj/structure/resurgence_blueprint/barrel,
		"Ore Box" = /obj/structure/resurgence_blueprint/ore_box,
		"Freezer" = /obj/structure/resurgence_blueprint/freezer,
		"Refrigerator" = /obj/structure/resurgence_blueprint/fridge,
		"Dresser" = /obj/structure/resurgence_blueprint/dresser,
		"Bookcase" = /obj/structure/resurgence_blueprint/bookcase,
		"Trash Cart" = /obj/structure/resurgence_blueprint/trashcart,
		"Coffin" = /obj/structure/resurgence_blueprint/coffin,
		"Trash Bin" = /obj/structure/resurgence_blueprint/trashbin,
		"Filing Cabinet" = /obj/structure/resurgence_blueprint/filing_cabinet,
		"Chest Drawer" = /obj/structure/resurgence_blueprint/chest_drawer,
		"Sign" = /obj/structure/resurgence_blueprint/sign,
		"Notice Board" = /obj/structure/resurgence_blueprint/noticeboard
	)

	// Production category - crafting stations
	blueprint_categories[BLUEPRINT_CAT_PRODUCTION] = list(
		"Crafting Table" = /obj/structure/resurgence_blueprint/crafting_table,
		"Primitive Forge" = /obj/structure/resurgence_blueprint/forge/primitive,
		"Forge" = /obj/structure/resurgence_blueprint/forge,
		"Primitive Loom" = /obj/structure/resurgence_blueprint/loom/primitive,
		"Loom" = /obj/structure/resurgence_blueprint/loom,
		"Seed Extractor" = /obj/structure/resurgence_blueprint/seed_extractor,
		"Condiment Station" = /obj/structure/resurgence_blueprint/condiment_station,
		"Meat Grinder" = /obj/structure/resurgence_blueprint/meat_grinder,
		"Food Processor" = /obj/structure/resurgence_blueprint/food_processor,
		"Stove" = /obj/structure/resurgence_blueprint/stove,
		"Hand Grinder" = /obj/structure/resurgence_blueprint/grinder,
		"Griddle" = /obj/structure/resurgence_blueprint/griddle,
		"Meat Spike" = /obj/structure/resurgence_blueprint/meatspike,
		"Shower Frame" = /obj/structure/resurgence_blueprint/shower,
		"Resources Recorder" = /obj/structure/resurgence_blueprint/resources_recorder,
		"Machine Fabricator" = /obj/structure/resurgence_blueprint/machine_fabricator
	)

	// Furniture category - beds, chairs, tables, seating
	blueprint_categories[BLUEPRINT_CAT_FURNITURE] = list(
		"Wooden Sleeper" = /obj/structure/resurgence_blueprint/bed,
		"Dog Bed" = /obj/structure/resurgence_blueprint/dog_bed,
		"Chair" = /obj/structure/resurgence_blueprint/chair,
		"Winged Chair" = /obj/structure/resurgence_blueprint/winged_chair,
		"Stool" = /obj/structure/resurgence_blueprint/stool,
		"Bar Stool" = /obj/structure/resurgence_blueprint/bar_stool,
		"Comfy Chair" = /obj/structure/resurgence_blueprint/comfy_chair,
		"Office Chair" = /obj/structure/resurgence_blueprint/office_chair,
		"Sofa (Middle)" = /obj/structure/resurgence_blueprint/sofa_middle,
		"Sofa (Left)" = /obj/structure/resurgence_blueprint/sofa_left,
		"Sofa (Right)" = /obj/structure/resurgence_blueprint/sofa_right,
		"Sofa (Corner)" = /obj/structure/resurgence_blueprint/sofa_corner,
		"Pew" = /obj/structure/resurgence_blueprint/pew,
		"Pew (Left)" = /obj/structure/resurgence_blueprint/pew_left,
		"Pew (Right)" = /obj/structure/resurgence_blueprint/pew_right,
		"Table" = /obj/structure/resurgence_blueprint/table,
		"Table Frame" = /obj/structure/resurgence_blueprint/table_frame,
		"Rack" = /obj/structure/resurgence_blueprint/rack,
		"Wooden Barricade" = /obj/structure/resurgence_blueprint/wooden_barricade,
		"Easel" = /obj/structure/resurgence_blueprint/easel
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

		// Count room turfs
		var/room_size = 0
		for(var/turf/T in current_room.contents)
			room_size++
		data["room_size"] = room_size
		data["room_walls"] = current_room.boundary_walls.len
		data["room_doors"] = current_room.boundary_doors.len

		// Room beauty info
		data["room_beauty"] = current_room.totalbeauty
		data["room_beauty_avg"] = current_room.beauty

		// Room ownership info - handle barracks differently (multiple owners)
		data["user_ckey"] = user.ckey
		data["user_has_room"] = (GLOB.resurgence_room_owners[user.ckey] != null)
		data["is_barracks"] = (current_room.room_type == ROOM_TYPE_BARRACKS)
		if(current_room.room_type == ROOM_TYPE_BARRACKS)
			var/area/resurgence_outpost/room/barracks/barracks = current_room
			data["room_owner"] = barracks.owner_ckeys.len ? barracks.owner_ckeys.Join(", ") : null
			data["room_owner_count"] = barracks.owner_ckeys.len
			data["user_owns_this_room"] = (user.ckey in barracks.owner_ckeys)
		else
			data["room_owner"] = current_room.owner_ckey
			data["room_owner_count"] = current_room.owner_ckey ? 1 : 0
			data["user_owns_this_room"] = (current_room.owner_ckey == user.ckey)
	else
		// Check if we can designate a room here
		data["in_room"] = FALSE
		var/list/detection_result = detect_enclosed_room(user_turf)
		if(detection_result)
			var/list/detected_turfs = detection_result["turfs"]
			var/list/detected_walls = detection_result["boundary_walls"]
			var/list/detected_doors = detection_result["boundary_doors"]
			var/list/valid_types = determine_valid_room_types(detected_turfs)

			// Check if cramped and filter restricted types for display
			var/is_cramped = is_room_cramped(detected_turfs)
			data["detected_is_cramped"] = is_cramped
			if(is_cramped)
				var/list/restricted_types = get_cramped_restricted_room_types()
				var/list/allowed_types = list()
				for(var/rtype in valid_types)
					if(!(rtype in restricted_types))
						allowed_types += rtype
				valid_types = allowed_types

			data["can_designate"] = length(valid_types) > 0
			data["detected_size"] = detected_turfs.len
			if(length(valid_types) > 0)
				data["detected_type"] = valid_types[1]  // Primary type
				data["detected_valid_types"] = valid_types  // All valid types
			else
				data["detected_type"] = null
				data["detected_valid_types"] = list()
			data["detected_walls"] = detected_walls.len
			data["detected_doors"] = detected_doors.len
		else
			data["can_designate"] = FALSE
			data["detected_is_cramped"] = FALSE

	data["in_use"] = in_use

	// Farming zone data
	data["farming_mode"] = farming_mode
	data["farming_selection"] = farming_zone_selection.len
	data["farming_max"] = farming_max_tiles
	data["existing_zones"] = get_farming_zones_data()
	data["fertilizer_count"] = count_fertilizer(user)

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
			if(struct_type)
				// Search all categories for the structure (needed for search results)
				var/found = FALSE
				for(var/cat_name in blueprint_categories)
					if(blueprint_categories[cat_name]?[struct_name])
						found = TRUE
						break
				if(found)
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

		if("claim_room")
			if(in_use)
				return TRUE
			in_use = TRUE
			claim_current_room(usr)
			in_use = FALSE
			return TRUE

		if("unclaim_room")
			if(in_use)
				return TRUE
			in_use = TRUE
			unclaim_current_room(usr)
			in_use = FALSE
			return TRUE

		if("recalculate_beauty")
			recalculate_room_beauty(usr)
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

		if("regenerate_plots")
			var/zone_id = text2num(params["id"])
			for(var/datum/farm_zone/zone in GLOB.resurgence_farm_zones)
				if(zone.zone_id == zone_id)
					regenerate_zone_plots(zone, usr)
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

	// Check if the result type already exists on this turf
	var/is_floor_blueprint = FALSE
	if(selected_blueprint)
		var/obj/structure/resurgence_blueprint/temp_bp = selected_blueprint
		var/result_type = initial(temp_bp.result_type)
		if(result_type)
			// For turfs, check if this turf is already that type
			if(ispath(result_type, /turf))
				is_floor_blueprint = TRUE
				if(istype(T, result_type))
					to_chat(user, span_warning("This location already has that floor type."))
					return FALSE
			// For objects, check if one exists on the turf
			else
				for(var/atom/A in T)
					if(istype(A, result_type))
						to_chat(user, span_warning("There's already a [A.name] here."))
						return FALSE

	// Check for dense objects that would block construction (skip for floor blueprints)
	if(!is_floor_blueprint)
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
	// Special handling for wall-mounted structures like resources recorder and noticeboard
	if(ispath(selected_blueprint, /obj/structure/resurgence_blueprint/resources_recorder))
		place_wall_mounted_blueprint(T, user)
		return
	if(ispath(selected_blueprint, /obj/structure/resurgence_blueprint/noticeboard))
		place_wall_mounted_blueprint(T, user, "Notice Board")
		return

	var/obj/structure/resurgence_blueprint/BP = new selected_blueprint(T)
	if(BP)
		BP.setDir(selected_direction)
		BP.blueprint_category = selected_category
		to_chat(user, span_notice("You place a [BP.result_name] blueprint facing [dir2text(selected_direction)]. Add the required materials to build it."))
		playsound(T, 'sound/items/deconstruct.ogg', 30, TRUE)

/// Place a wall-mounted blueprint (resources recorder, noticeboard, etc.)
/obj/item/resurgence_outpost_planner/proc/place_wall_mounted_blueprint(turf/T, mob/user, custom_name = "Resources Recorder")
	// Check for wall in the selected direction
	var/turf/wall_turf = get_step(T, selected_direction)
	if(!isclosedturf(wall_turf))
		to_chat(user, span_warning("The [custom_name] must be placed adjacent to a wall. There is no wall to the [dir2text(selected_direction)]."))
		return

	// Create the blueprint with wall direction
	var/obj/structure/resurgence_blueprint/BP = new selected_blueprint(T, selected_direction)
	if(BP)
		BP.blueprint_category = selected_category
		to_chat(user, span_notice("You place a [BP.result_name] blueprint mounted towards the [dir2text(selected_direction)] wall. Add the required materials to build it."))
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

	// Determine valid room types based on contents
	var/list/valid_types = determine_valid_room_types(room_turfs)

	// Check if room is cramped and filter out restricted types
	var/is_cramped = is_room_cramped(room_turfs)
	if(is_cramped)
		var/list/restricted_types = get_cramped_restricted_room_types()
		var/list/allowed_types = list()
		for(var/rtype in valid_types)
			if(!(rtype in restricted_types))
				allowed_types += rtype
		if(!length(allowed_types))
			to_chat(user, span_warning("This space is too cramped for a specialized room. It needs more than [ROOM_MIN_TILES] tiles and dimensions of at least [ROOM_MIN_DIMENSION]x[ROOM_MIN_DIMENSION]. Only Living Quarters and Common Rooms can be cramped."))
			return
		valid_types = allowed_types

	var/room_type
	if(length(valid_types) == 1)
		room_type = valid_types[1]
	else
		// Let user pick from valid types
		var/choice = tgui_input_list(user, "This room qualifies as multiple types. Choose one:", "Room Type", valid_types)
		if(!choice)
			to_chat(user, span_notice("Room designation cancelled."))
			return
		room_type = choice

	if(!room_type)
		to_chat(user, span_warning("Failed to determine room type."))
		return

	var/room_name = get_default_room_name(room_type)

	// Create the room
	to_chat(user, span_notice("Designating room..."))
	playsound(user, 'sound/items/deconstruct.ogg', 50, TRUE)

	var/area/new_room = create_resurgence_room(room_turfs, room_type, room_name, user, boundary_walls, boundary_doors)

	if(new_room)
		to_chat(user, span_notice("<b>Success!</b> '[room_name]' has been designated as a [room_type]."))
		highlight_room(room_turfs)
	else
		to_chat(user, span_warning("Failed to create room. Please try again."))

/// Highlight the room the user is currently in
/obj/item/resurgence_outpost_planner/proc/highlight_current_room(mob/user)
	if(highlight_cooldown)
		to_chat(user, span_warning("Please wait before highlighting again."))
		return

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

	// Start cooldown
	highlight_cooldown = TRUE
	addtimer(CALLBACK(src, PROC_REF(reset_highlight_cooldown)), 3 SECONDS)

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

/// Claim the current room for the user
/obj/item/resurgence_outpost_planner/proc/claim_current_room(mob/user)
	var/turf/origin = get_turf(user)
	var/area/resurgence_outpost/room/room = get_area(origin)

	if(!istype(room))
		to_chat(user, span_warning("You must be inside a designated room to claim it."))
		return

	if(!user.ckey)
		to_chat(user, span_warning("You cannot claim rooms."))
		return

	// Only living quarters and barracks can be claimed
	if(room.room_type != ROOM_TYPE_LIVING_QUARTERS && room.room_type != ROOM_TYPE_BARRACKS)
		to_chat(user, span_warning("Only living quarters and barracks can be claimed. This room needs a bed."))
		return

	// Barracks can have multiple claimers, living quarters only one
	if(room.room_type == ROOM_TYPE_BARRACKS)
		var/area/resurgence_outpost/room/barracks/barracks = room
		// Check if user already claimed this barracks
		if(user.ckey in barracks.owner_ckeys)
			to_chat(user, span_warning("You already have a bunk in this barracks."))
			return
	else
		// Living quarters - check if already owned by someone else
		if(room.owner_ckey && room.owner_ckey != user.ckey)
			to_chat(user, span_warning("This room is already claimed by [room.owner_ckey]."))
			return

		// Check if user already owns this room
		if(room.owner_ckey == user.ckey)
			to_chat(user, span_warning("You already own this room."))
			return

	// Check if user owns another room (will be unclaimed)
	var/area/resurgence_outpost/room/old_room = GLOB.resurgence_room_owners[user.ckey]
	if(old_room && !QDELETED(old_room) && old_room != room)
		to_chat(user, span_notice("You will release ownership of '[old_room.name]' to claim this room."))

	// Claim the room (will auto-unclaim previous)
	if(!room.claim_room(user.ckey))
		to_chat(user, span_warning("Failed to claim room."))
		return
	to_chat(user, span_notice("You have claimed '[room.name]' as your personal room."))
	playsound(user, 'sound/items/deconstruct.ogg', 30, TRUE)

/// Unclaim the current room
/obj/item/resurgence_outpost_planner/proc/unclaim_current_room(mob/user)
	var/turf/origin = get_turf(user)
	var/area/resurgence_outpost/room/room = get_area(origin)

	if(!istype(room))
		to_chat(user, span_warning("You must be inside a designated room."))
		return

	// Handle barracks differently (multiple owners)
	if(room.room_type == ROOM_TYPE_BARRACKS)
		var/area/resurgence_outpost/room/barracks/barracks = room
		if(!(user.ckey in barracks.owner_ckeys))
			to_chat(user, span_warning("You don't have a bunk in this barracks."))
			return
		barracks.unclaim_room_by_ckey(user.ckey)
	else
		if(room.owner_ckey != user.ckey)
			to_chat(user, span_warning("You don't own this room."))
			return
		room.unclaim_room()

	to_chat(user, span_notice("You have unclaimed '[room.name]'."))
	playsound(user, 'sound/items/deconstruct.ogg', 30, TRUE)

/// Recalculate the beauty of the current room
/obj/item/resurgence_outpost_planner/proc/recalculate_room_beauty(mob/user)
	var/turf/origin = get_turf(user)
	var/area/resurgence_outpost/room/room = get_area(origin)

	if(!istype(room))
		to_chat(user, span_warning("You must be inside a designated room."))
		return

	var/old_beauty = room.totalbeauty
	recalculate_area_beauty(room)
	var/new_beauty = room.totalbeauty

	to_chat(user, span_notice("Recalculated room beauty: [old_beauty] -> [new_beauty]"))
	playsound(user, 'sound/items/deconstruct.ogg', 30, TRUE)

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
	// Check fertilizer requirement
	var/fertilizer_needed = farming_zone_selection.len
	var/fertilizer_available = count_fertilizer(user)

	if(fertilizer_available < fertilizer_needed)
		to_chat(user, span_warning("You need [fertilizer_needed] fertilizer to create [fertilizer_needed] plots, but only have [fertilizer_available]."))
		return

	// Consume fertilizer
	consume_fertilizer(user, fertilizer_needed)

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
		to_chat(user, span_notice("Added [plots_created] plots to existing zone '[zone.name]'. Used [fertilizer_needed] fertilizer."))
	else
		to_chat(user, span_notice("Created farm zone '[zone_name]' with [plots_created] plots. Used [fertilizer_needed] fertilizer."))
	playsound(user, 'sound/items/deconstruct.ogg', 50, TRUE)
	SStgui.update_uis(src)

	// Update global objectives (farming zone objectives track zone counts)
	update_all_objectives()

/// Highlight an existing farm zone's plots
/obj/item/resurgence_outpost_planner/proc/highlight_farm_zone(datum/farm_zone/zone, mob/user)
	if(highlight_cooldown)
		to_chat(user, span_warning("Please wait before highlighting again."))
		return

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

	// Start cooldown
	highlight_cooldown = TRUE
	addtimer(CALLBACK(src, PROC_REF(reset_highlight_cooldown)), 3 SECONDS)

/// Reset the highlight cooldown
/obj/item/resurgence_outpost_planner/proc/reset_highlight_cooldown()
	highlight_cooldown = FALSE

/// Regenerate missing plots in a farm zone
/obj/item/resurgence_outpost_planner/proc/regenerate_zone_plots(datum/farm_zone/zone, mob/user)
	if(!zone || QDELETED(zone))
		to_chat(user, span_warning("This zone no longer exists."))
		return

	if(!zone.zone_turfs || zone.zone_turfs.len == 0)
		to_chat(user, span_warning("This zone has no recorded turfs."))
		return

	// Check each turf in the zone for missing plots
	var/list/missing_turfs = list()
	for(var/turf/T in zone.zone_turfs)
		var/has_plot = FALSE
		for(var/obj/structure/farm_plot/plot in T)
			if(!QDELETED(plot) && plot.parent_zone == zone)
				has_plot = TRUE
				break
		if(!has_plot)
			missing_turfs += T

	if(missing_turfs.len == 0)
		to_chat(user, span_notice("All plots in '[zone.name]' are intact. Nothing to regenerate."))
		return

	// Check fertilizer
	var/fertilizer_available = count_fertilizer(user)
	if(fertilizer_available < missing_turfs.len)
		to_chat(user, span_warning("You need [missing_turfs.len] fertilizer to regenerate all missing plots, but only have [fertilizer_available]."))
		return

	// Consume fertilizer and create plots
	consume_fertilizer(user, missing_turfs.len)

	var/plots_created = 0
	for(var/turf/T in missing_turfs)
		var/obj/structure/farm_plot/plot = new(T)
		zone.add_plot(plot)
		plots_created++

	to_chat(user, span_notice("Regenerated [plots_created] plots in '[zone.name]'. Used [plots_created] fertilizer."))
	playsound(user, 'sound/items/deconstruct.ogg', 50, TRUE)
	SStgui.update_uis(src)

// ===== Fertilizer Helpers =====

/// Count how many fertilizer the user has available (stack-aware)
/obj/item/resurgence_outpost_planner/proc/count_fertilizer(mob/living/carbon/human/user)
	if(!istype(user))
		return 0

	var/count = 0

	// Check hands
	for(var/obj/item/stack/resurgence_fertilizer/F in user.held_items)
		count += F.amount

	// Check backpack
	var/obj/item/storage/backpack = user.get_item_by_slot(ITEM_SLOT_BACK)
	if(istype(backpack))
		for(var/obj/item/stack/resurgence_fertilizer/F in backpack.contents)
			count += F.amount

	return count

/// Consume fertilizer from the user (stack-aware)
/obj/item/resurgence_outpost_planner/proc/consume_fertilizer(mob/living/carbon/human/user, amount)
	if(!istype(user) || amount <= 0)
		return

	var/remaining = amount

	// Take from hands first
	for(var/obj/item/stack/resurgence_fertilizer/F in user.held_items)
		if(remaining <= 0)
			break
		var/to_use = min(F.amount, remaining)
		F.use(to_use)
		remaining -= to_use

	// Then from backpack
	if(remaining > 0)
		var/obj/item/storage/backpack = user.get_item_by_slot(ITEM_SLOT_BACK)
		if(istype(backpack))
			for(var/obj/item/stack/resurgence_fertilizer/F in backpack.contents)
				if(remaining <= 0)
					break
				var/to_use = min(F.amount, remaining)
				F.use(to_use)
				remaining -= to_use

#undef BLUEPRINT_CAT_CONSTRUCTION
#undef BLUEPRINT_CAT_STORAGE
#undef BLUEPRINT_CAT_PRODUCTION
#undef BLUEPRINT_CAT_FURNITURE
