/**
 * Resurgence Outpost - Grid Crafting Station
 *
 * The Grid Crafting Station allows players to use Ore Cores to navigate
 * a coordinate grid and craft special equipment when they reach item locations.
 */

/obj/structure/grid_crafting_station
	name = "grid crafting station"
	desc = "An advanced crafting station that uses ore cores to navigate a coordinate grid and craft special equipment."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "tdoppler"
	density = TRUE
	anchored = TRUE

	/// The grid manager for this station
	var/datum/grid_craft_manager/grid_manager = null

	/// Currently selected core
	var/obj/item/ore_core/selected_core = null

	/// Last crafted item name (for display)
	var/last_crafted = null

	/// Movement direction being previewed (for UI)
	var/preview_dir_x = 0
	var/preview_dir_y = 0

	/// Cores stored in the machine
	var/list/stored_cores = list()

	/// Maximum cores that can be stored
	var/max_stored_cores = 50

	/// Debug mode - shows all weapons regardless of research
	var/debug_mode = FALSE

/obj/structure/grid_crafting_station/Initialize(mapload)
	. = ..()
	grid_manager = new(src)

/obj/structure/grid_crafting_station/Destroy()
	QDEL_NULL(grid_manager)
	QDEL_LIST(stored_cores)
	return ..()

/obj/structure/grid_crafting_station/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	ui_interact(user)
	return TRUE

/obj/structure/grid_crafting_station/attackby(obj/item/I, mob/user, params)
	// Handle ore core insertion into storage
	if(istype(I, /obj/item/ore_core))
		var/obj/item/ore_core/core = I
		if(length(stored_cores) >= max_stored_cores)
			to_chat(user, span_warning("The machine's core storage is full!"))
			return
		if(!user.transferItemToLoc(core, src))
			return
		stored_cores += core
		to_chat(user, span_notice("You insert [core] into the machine."))
		playsound(src, 'sound/machines/click.ogg', 30, TRUE)
		SStgui.update_uis(src)
		return

	return ..()

/// Select a core for use (from stored cores)
/obj/structure/grid_crafting_station/proc/select_core(obj/item/ore_core/core, mob/user)
	if(!istype(core))
		return

	// Make sure the core is in our storage
	if(!(core in stored_cores))
		to_chat(user, span_warning("That core is not in the machine!"))
		return

	selected_core = core
	to_chat(user, span_notice("You prepare to use the [core.name]."))
	SStgui.update_uis(src)

/// Retrieve a core from the machine
/obj/structure/grid_crafting_station/proc/retrieve_core(obj/item/ore_core/core, mob/user)
	if(!istype(core))
		return

	if(!(core in stored_cores))
		return

	stored_cores -= core
	if(selected_core == core)
		selected_core = null
	core.forceMove(get_turf(src))
	user.put_in_hands(core)
	to_chat(user, span_notice("You retrieve [core] from the machine."))
	SStgui.update_uis(src)

/// Use the selected core to move in a direction
/obj/structure/grid_crafting_station/proc/use_core_in_direction(mob/user, dir_x, dir_y)
	if(!selected_core)
		to_chat(user, span_warning("No core selected! Select a core from the machine's storage."))
		return FALSE

	if(QDELETED(selected_core))
		selected_core = null
		to_chat(user, span_warning("The selected core is no longer available."))
		return FALSE

	// Validate the core is still in machine storage
	if(!(selected_core in stored_cores))
		selected_core = null
		to_chat(user, span_warning("The selected core is no longer in the machine."))
		return FALSE

	// Attempt the movement
	var/old_x = grid_manager.focus_x
	var/old_y = grid_manager.focus_y

	if(!grid_manager.use_core(selected_core, dir_x, dir_y))
		to_chat(user, span_warning("Invalid direction for this core type!"))
		return FALSE

	// Core was used - consume it
	to_chat(user, span_notice("You use the [selected_core.name] to move from ([old_x], [old_y]) to ([grid_manager.focus_x], [grid_manager.focus_y])."))
	playsound(src, 'sound/machines/click.ogg', 30, TRUE)

	stored_cores -= selected_core
	qdel(selected_core)
	selected_core = null

	// Check if we can craft anything
	check_craftable_items(user)

	SStgui.update_uis(src)
	return TRUE

/// Use a teleport core to move to specific coordinates
/obj/structure/grid_crafting_station/proc/use_teleport_core(mob/user, target_x, target_y)
	if(!selected_core)
		to_chat(user, span_warning("No core selected!"))
		return FALSE

	if(selected_core.core_move_type != CORE_MOVEMENT_TELEPORT)
		to_chat(user, span_warning("Only gold cores can teleport!"))
		return FALSE

	// Calculate relative movement
	var/rel_x = target_x - grid_manager.focus_x
	var/rel_y = target_y - grid_manager.focus_y

	return use_core_in_direction(user, rel_x, rel_y)

/// Check if any items are craftable at current position
/obj/structure/grid_crafting_station/proc/check_craftable_items(mob/user)
	var/list/datum/grid_craft_item/craftable = grid_manager.get_craftable_items()

	if(!length(craftable))
		return

	// Notify user that items are available - they can choose to craft or continue
	if(length(craftable) == 1)
		var/datum/grid_craft_item/first_item = craftable[1]
		to_chat(user, span_notice("You are in range of [first_item.name]! Use the UI to craft it or continue exploring."))
	else
		to_chat(user, span_notice("[length(craftable)] weapons available! Use the UI to craft one or continue exploring."))

/// Craft a specific item
/obj/structure/grid_crafting_station/proc/craft_item(mob/user, datum/grid_craft_item/item)
	if(!item)
		return FALSE

	if(!item.is_in_range(grid_manager.focus_x, grid_manager.focus_y))
		to_chat(user, span_warning("You're not close enough to craft [item.name]!"))
		return FALSE

	// Create the result
	if(item.result_type)
		var/obj/item/crafted = new item.result_type(get_turf(src))
		// Remove attribute requirements from crafted weapons
		if(istype(crafted, /obj/item/ego_weapon))
			var/obj/item/ego_weapon/weapon = crafted
			weapon.attribute_requirements = list()

	last_crafted = item.name
	to_chat(user, span_notice("<b>Crafted:</b> [item.name]!"))
	playsound(src, 'sound/machines/ping.ogg', 50, TRUE)

	// Reset focus point after crafting
	grid_manager.reset_focus()
	SStgui.update_uis(src)

	return TRUE

/// Reset the grid without crafting
/obj/structure/grid_crafting_station/proc/reset_grid(mob/user)
	if(grid_manager.cores_used == 0)
		to_chat(user, span_warning("Nothing to reset - you haven't used any cores yet."))
		return

	grid_manager.reset_focus()
	to_chat(user, span_notice("You reset the grid to origin."))
	SStgui.update_uis(src)

/// Get the maximum weapon tier revealed by research
/obj/structure/grid_crafting_station/proc/get_max_revealed_tier()
	if(debug_mode)
		return 4  // Show all tiers in debug mode

	if(!GLOB.resurgence_research)
		return 1  // Default to tier 0-1 if no research system

	var/datum/resurgence_research_manager/research = GLOB.resurgence_research

	// Check research nodes to determine max revealed tier
	// master_grid_crafting -> Tier 4
	// expert_grid_crafting -> Tier 3
	// advanced_grid_crafting -> Tier 2
	// grid_crafting -> Tier 1
	// No research -> Tier 0 only (but we give 1 as base)
	if(research.is_researched("master_grid_crafting"))
		return 4
	if(research.is_researched("expert_grid_crafting"))
		return 3
	if(research.is_researched("advanced_grid_crafting"))
		return 2
	if(research.is_researched("grid_crafting"))
		return 1

	return 0  // No grid crafting research - only tier 0 visible

// ===== TGUI Interface =====

/obj/structure/grid_crafting_station/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "GridCraftingStation", name)
		ui.open()

/obj/structure/grid_crafting_station/ui_data(mob/user)
	var/list/data = list()

	// Focus point position
	data["focus_x"] = grid_manager.focus_x
	data["focus_y"] = grid_manager.focus_y
	data["cores_used"] = grid_manager.cores_used

	// Selected core info
	if(selected_core && !QDELETED(selected_core))
		data["selected_core"] = list(
			"name" = selected_core.name,
			"ore_type" = selected_core.ore_type,
			"movement_type" = selected_core.core_move_type,
			"movement_desc" = selected_core.get_movement_description(),
			"distance_range" = selected_core.get_final_distance_range()
		)
	else
		data["selected_core"] = null

	// Cores stored in the machine
	var/list/core_data = list()
	for(var/obj/item/ore_core/core in stored_cores)
		core_data += list(list(
			"ref" = REF(core),
			"name" = core.name,
			"ore_type" = core.ore_type,
			"movement_type" = core.core_move_type,
			"level" = core.refinement_level,
			"fuel" = core.fuel_level,
			"gilded" = core.gilded
		))
	data["available_cores"] = core_data
	data["stored_count"] = length(stored_cores)
	data["max_stored"] = max_stored_cores

	// Get max revealed tier based on research
	var/max_tier = get_max_revealed_tier()
	data["max_revealed_tier"] = max_tier
	data["debug_mode"] = debug_mode

	// Nearby items (filtered by research tier)
	var/list/nearby = grid_manager.get_nearby_items(50)
	var/list/item_data = list()
	for(var/datum/grid_craft_item/item in nearby)
		// Filter by revealed tier
		if(item.tier > max_tier)
			continue
		var/dist = item.distance_from(grid_manager.focus_x, grid_manager.focus_y)
		var/in_range = item.is_in_range(grid_manager.focus_x, grid_manager.focus_y)
		item_data += list(list(
			"id" = item.item_id,
			"name" = item.name,
			"desc" = item.desc,
			"x" = item.coord_x,
			"y" = item.coord_y,
			"radius" = item.craft_radius,
			"tier" = item.tier,
			"distance" = round(dist, 0.1),
			"in_range" = in_range
		))
	data["nearby_items"] = item_data

	// Craftable items at current position (filtered by research tier)
	var/list/craftable = grid_manager.get_craftable_items()
	var/list/craftable_data = list()
	for(var/datum/grid_craft_item/item in craftable)
		// Filter by revealed tier
		if(item.tier > max_tier)
			continue
		craftable_data += list(list(
			"id" = item.item_id,
			"name" = item.name,
			"desc" = item.desc,
			"tier" = item.tier
		))
	data["craftable_items"] = craftable_data

	// Last crafted
	data["last_crafted"] = last_crafted

	return data

/obj/structure/grid_crafting_station/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("select_core")
			var/core_ref = params["ref"]
			var/obj/item/ore_core/core = locate(core_ref)
			if(istype(core))
				select_core(core, usr)
			return TRUE

		if("retrieve_core")
			var/core_ref = params["ref"]
			var/obj/item/ore_core/core = locate(core_ref)
			if(istype(core))
				retrieve_core(core, usr)
			return TRUE

		if("move")
			var/dir_x = text2num(params["x"]) || 0
			var/dir_y = text2num(params["y"]) || 0
			use_core_in_direction(usr, dir_x, dir_y)
			return TRUE

		if("teleport")
			var/target_x = text2num(params["x"]) || 0
			var/target_y = text2num(params["y"]) || 0
			use_teleport_core(usr, target_x, target_y)
			return TRUE

		if("craft")
			var/item_id = params["id"]
			for(var/datum/grid_craft_item/item in grid_manager.items)
				if(item.item_id == item_id)
					craft_item(usr, item)
					break
			return TRUE

		if("reset")
			reset_grid(usr)
			return TRUE

	return FALSE

/obj/structure/grid_crafting_station/examine(mob/user)
	. = ..()
	. += span_notice("Click to open the grid crafting interface.")
	. += span_notice("Use ore cores on this machine to insert them into storage.")
	. += span_notice("Stored cores: [length(stored_cores)]/[max_stored_cores]")
	. += span_notice("Current focus point: ([grid_manager.focus_x], [grid_manager.focus_y])")
	if(grid_manager.cores_used > 0)
		. += span_notice("Cores used this session: [grid_manager.cores_used]")
	if(last_crafted)
		. += span_notice("Last crafted: [last_crafted]")
	if(debug_mode)
		. += span_boldwarning("DEBUG MODE: All weapon tiers visible.")

/// Debug version that shows all weapons regardless of research
/obj/structure/grid_crafting_station/debug
	name = "grid crafting station (DEBUG)"
	debug_mode = TRUE
