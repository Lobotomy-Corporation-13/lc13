/**
 * Resurgence Outpost - Resources Recorder
 *
 * Wall-mounted console for scanning and exporting resources from the Export Warehouse.
 * Scans closets in the room, allows selection, and exports them with fulton animation.
 */

/obj/structure/resources_recorder
	name = "resources recorder"
	desc = "A wall-mounted console for tracking and exporting resources back to the Historian's village. Must be placed in an Export Warehouse room to function."
	icon = 'icons/obj/machines/mining_machines.dmi'
	icon_state = "console"
	anchored = TRUE
	density = FALSE
	layer = ABOVE_MOB_LAYER

	/// Direction this console is facing (towards the room, away from wall)
	var/wall_dir = SOUTH

	/// Last scan results: closet ref -> list(type_path -> count)
	var/list/last_scan_results

	/// Currently selected closets for export
	var/list/selected_for_export = list()

	/// Whether an export is currently in progress
	var/exporting = FALSE

/obj/structure/resources_recorder/Initialize(mapload)
	. = ..()
	// Apply pixel offset based on wall direction
	apply_wall_offset()

/obj/structure/resources_recorder/examine(mob/user)
	. = ..()
	if(!is_in_export_warehouse())
		. += span_warning("This console is not in an Export Warehouse room. Designate the room first.")
	else
		. += span_notice("Click to open the export interface.")
	. += span_notice("The console is mounted facing [dir2text(wall_dir)].")

/// Apply pixel offset to hug the wall
/obj/structure/resources_recorder/proc/apply_wall_offset()
	switch(wall_dir)
		if(NORTH)
			pixel_y = 32
			pixel_x = 0
		if(SOUTH)
			pixel_y = -32
			pixel_x = 0
		if(EAST)
			pixel_x = 32
			pixel_y = 0
		if(WEST)
			pixel_x = -32
			pixel_y = 0

/// Check if this recorder is in an Export Warehouse room
/obj/structure/resources_recorder/proc/is_in_export_warehouse()
	var/area/resurgence_outpost/room/R = get_area(src)
	if(!istype(R))
		return FALSE
	return R.room_type == ROOM_TYPE_EXPORT_WAREHOUSE

/// Get the room area this recorder is in
/obj/structure/resources_recorder/proc/get_warehouse_room()
	var/area/resurgence_outpost/room/R = get_area(src)
	if(!istype(R) || R.room_type != ROOM_TYPE_EXPORT_WAREHOUSE)
		return null
	return R

/obj/structure/resources_recorder/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return

	if(!is_in_export_warehouse())
		to_chat(user, span_warning("This console is not in an Export Warehouse room. Designate the room first."))
		return

	ui_interact(user)

// ===== TGUI Interface =====

/obj/structure/resources_recorder/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ResourcesRecorder", "Resources Recorder")
		ui.open()

/obj/structure/resources_recorder/ui_data(mob/user)
	var/list/data = list()

	data["in_warehouse"] = is_in_export_warehouse()
	data["exporting"] = exporting
	data["phase"] = GLOB.resurgence_objective_phase

	// Scanned closets
	data["scanned_closets"] = list()
	if(last_scan_results)
		for(var/obj/structure/closet/C in last_scan_results)
			if(QDELETED(C))
				continue
			var/list/closet_data = list(
				"ref" = REF(C),
				"name" = C.name,
				"contents" = list(),
				"selected" = (C in selected_for_export),
				"total_items" = 0
			)
			var/total = 0
			for(var/item_type in last_scan_results[C])
				var/count = last_scan_results[C][item_type]
				total += count
				closet_data["contents"] += list(list(
					"name" = get_item_name(item_type),
					"count" = count,
					"contributes" = does_contribute_to_objective(item_type)
				))
			closet_data["total_items"] = total
			data["scanned_closets"] += list(closet_data)

	// Current export objectives
	data["export_objectives"] = list()
	for(var/datum/resurgence_objective/export/obj in GLOB.resurgence_objectives)
		data["export_objectives"] += list(list(
			"name" = obj.name,
			"current" = obj.current_progress,
			"required" = obj.required_progress,
			"completed" = obj.completed
		))

	return data

/obj/structure/resources_recorder/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("scan")
			scan_warehouse()
			return TRUE

		if("toggle_select")
			var/ref = params["ref"]
			var/obj/structure/closet/C = locate(ref)
			if(C && !QDELETED(C) && (C in last_scan_results))
				if(C in selected_for_export)
					selected_for_export -= C
				else
					selected_for_export += C
			return TRUE

		if("select_all")
			selected_for_export = list()
			if(last_scan_results)
				for(var/obj/structure/closet/C in last_scan_results)
					if(!QDELETED(C))
						selected_for_export += C
			return TRUE

		if("deselect_all")
			selected_for_export = list()
			return TRUE

		if("export")
			if(!exporting && selected_for_export.len)
				export_selected(usr)
			return TRUE

// ===== Scanning =====

/// Scan all closets in the warehouse room
/obj/structure/resources_recorder/proc/scan_warehouse()
	var/area/resurgence_outpost/room/warehouse = get_warehouse_room()
	if(!warehouse)
		return

	last_scan_results = list()
	selected_for_export = list()

	// Find all closets in the room
	for(var/turf/T in warehouse.contents)
		for(var/obj/structure/closet/C in T)
			if(QDELETED(C))
				continue

			var/list/item_counts = list()

			// Count items in the closet
			for(var/obj/item/I in C.contents)
				var/item_type = I.type

				// For stacks, count the amount
				if(istype(I, /obj/item/stack))
					var/obj/item/stack/S = I
					if(!item_counts[item_type])
						item_counts[item_type] = 0
					item_counts[item_type] += S.amount
				else
					if(!item_counts[item_type])
						item_counts[item_type] = 0
					item_counts[item_type] += 1

			if(length(item_counts))
				last_scan_results[C] = item_counts

	playsound(src, 'sound/machines/terminal_prompt.ogg', 25, TRUE)

/// Get display name for an item type
/obj/structure/resources_recorder/proc/get_item_name(type_path)
	var/obj/item/temp = type_path
	return initial(temp.name)

/// Check if an item type contributes to any active export objective
/obj/structure/resources_recorder/proc/does_contribute_to_objective(type_path)
	if(GLOB.resurgence_objective_phase < 2)
		return FALSE

	for(var/datum/resurgence_objective/export/obj in GLOB.resurgence_objectives)
		// Use ispath to match subtypes as well
		if(!obj.completed && ispath(type_path, obj.export_type))
			return TRUE

	return FALSE

// ===== Exporting =====

/// Export all selected closets
/obj/structure/resources_recorder/proc/export_selected(mob/user)
	if(exporting)
		return
	if(!selected_for_export.len)
		to_chat(user, span_warning("No closets selected for export."))
		return
	if(GLOB.resurgence_objective_phase < 2)
		to_chat(user, span_warning("Export objectives are not yet unlocked. Complete all building objectives first."))
		return

	exporting = TRUE
	playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 25, TRUE)

	// Process each selected closet
	var/list/to_export = selected_for_export.Copy()
	for(var/obj/structure/closet/C in to_export)
		if(QDELETED(C))
			continue
		fulton_export(C)
		sleep(5) // Small delay between exports

	// Clear selections
	selected_for_export = list()
	last_scan_results = list()
	exporting = FALSE

	// Rescan to update UI
	scan_warehouse()

/// Export a single closet with fulton animation
/obj/structure/resources_recorder/proc/fulton_export(obj/structure/closet/target)
	if(QDELETED(target))
		return

	var/turf/T = get_turf(target)

	// Count and record exports BEFORE animation
	var/list/export_counts = list()
	for(var/obj/item/I in target.contents)
		var/item_type = I.type
		if(istype(I, /obj/item/stack))
			var/obj/item/stack/S = I
			if(!export_counts[item_type])
				export_counts[item_type] = 0
			export_counts[item_type] += S.amount
		else
			if(!export_counts[item_type])
				export_counts[item_type] = 0
			export_counts[item_type] += 1

	// Create balloon effect
	var/mutable_appearance/balloon = mutable_appearance('icons/obj/fulton_balloon.dmi', "fulton_expand")
	balloon.pixel_y = 10
	balloon.appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM
	target.add_overlay(balloon)

	// Sound effect
	playsound(T, 'sound/items/fultext_deploy.ogg', 50, TRUE, -3)

	sleep(4)

	// Switch to full balloon
	target.cut_overlay(balloon)
	balloon = mutable_appearance('icons/obj/fulton_balloon.dmi', "fulton_balloon")
	balloon.pixel_y = 10
	balloon.appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM
	target.add_overlay(balloon)

	// Rise animation
	animate(target, pixel_z = 10, time = 10)
	sleep(10)
	animate(target, pixel_z = 20, time = 10)
	sleep(10)

	playsound(T, 'sound/items/fultext_launch.ogg', 50, TRUE, -3)

	// Launch upward and fade
	animate(target, pixel_z = 200, alpha = 0, time = 20)
	sleep(20)

	// Add to export totals
	for(var/item_type in export_counts)
		add_exported_resources(item_type, export_counts[item_type])

	// Delete contents FIRST to prevent them from being dumped when closet is deleted
	for(var/atom/movable/AM in target.contents)
		qdel(AM)

	// Now delete the empty closet
	qdel(target)

/// Check if atom is in an export warehouse
/proc/is_in_export_warehouse(atom/source)
	return is_in_room_type(source, ROOM_TYPE_EXPORT_WAREHOUSE)
