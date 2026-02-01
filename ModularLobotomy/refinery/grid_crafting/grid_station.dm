/**
 * Grid Crafting System - Grid Crafting Station
 *
 * The machine where players use navigation cores to navigate
 * a coordinate grid and craft city weapons.
 */

/obj/structure/grid_crafting_station
	name = "grid crafting station"
	desc = "An advanced crafting station that uses enkephalin navigation cores to locate and craft city weapons."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "tdoppler"
	density = TRUE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE

	/// The grid manager for this station
	var/datum/grid_craft_manager/grid_manager = null

	/// Currently selected core
	var/obj/item/navigation_core/selected_core = null

	/// Last crafted item name (for display)
	var/last_crafted = null

	/// Currently highlighted item ID (for UI line drawing)
	var/highlighted_item_id = null

	/// List of crafted item IDs
	var/list/crafted_item_ids = list()

	/// Cores stored in the machine
	var/list/stored_cores = list()

	/// Maximum cores that can be stored
	var/max_stored_cores = 50

	/// Debug mode - shows all weapons regardless of tier
	var/debug_mode = FALSE

	/// Sin overuse tracking for diminishing returns (sin_type -> count)
	var/list/sin_overuse_counts = list()

	/// Maximum tier accessible this session (based on highest core tier used)
	var/max_accessible_tier = 0

/obj/structure/grid_crafting_station/Initialize(mapload)
	. = ..()
	grid_manager = new(src)
	GLOB.lobotomy_devices += src
	// Register for ordeal completion signal (only once globally)
	InitializeOrdealTierTracking()

/obj/structure/grid_crafting_station/Destroy()
	GLOB.lobotomy_devices -= src
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
	// Handle navigation core insertion
	if(istype(I, /obj/item/navigation_core))
		var/obj/item/navigation_core/core = I
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

/// Select a core for use
/obj/structure/grid_crafting_station/proc/SelectCore(obj/item/navigation_core/core, mob/user)
	if(!istype(core))
		return

	if(!(core in stored_cores))
		to_chat(user, span_warning("That core is not in the machine!"))
		return

	selected_core = core
	to_chat(user, span_notice("You prepare to use the [core.name]."))
	SStgui.update_uis(src)

/// Retrieve a core from the machine
/obj/structure/grid_crafting_station/proc/RetrieveCore(obj/item/navigation_core/core, mob/user)
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

/// Use the selected core to move
/obj/structure/grid_crafting_station/proc/UseCoreMove(mob/user, dir_x, dir_y, target_x = 0, target_y = 0)
	if(!selected_core)
		to_chat(user, span_warning("No core selected! Select a core from storage."))
		return FALSE

	if(QDELETED(selected_core))
		selected_core = null
		to_chat(user, span_warning("The selected core is no longer available."))
		return FALSE

	if(!(selected_core in stored_cores))
		selected_core = null
		to_chat(user, span_warning("The selected core is no longer in the machine."))
		return FALSE

	// Check tier access
	var/max_tier_needed = 0
	for(var/datum/grid_craft_item/item in grid_manager.items)
		if(item.tier > max_tier_needed)
			max_tier_needed = item.tier

	var/old_x = grid_manager.focus_x
	var/old_y = grid_manager.focus_y

	if(!grid_manager.UseCore(selected_core, user, dir_x, dir_y, target_x, target_y))
		to_chat(user, span_warning("Invalid movement for this core type!"))
		return FALSE

	// Core was used successfully
	to_chat(user, span_notice("You use the [selected_core.name] to move from ([old_x], [old_y]) to ([grid_manager.focus_x], [grid_manager.focus_y])."))
	playsound(src, 'sound/machines/click.ogg', 30, TRUE)

	// Consume the core
	stored_cores -= selected_core
	qdel(selected_core)
	selected_core = null

	// Check for craftable items
	CheckCraftableItems(user)

	SStgui.update_uis(src)
	return TRUE

/// Check if any items are craftable at current position
/obj/structure/grid_crafting_station/proc/CheckCraftableItems(mob/user)
	var/list/datum/grid_craft_item/craftable = grid_manager.GetCraftableItems()

	if(!length(craftable))
		return

	if(length(craftable) == 1)
		var/datum/grid_craft_item/first_item = craftable[1]
		to_chat(user, span_notice("You are in range of [first_item.name]! Use the UI to craft it."))
	else
		to_chat(user, span_notice("[length(craftable)] weapons available! Use the UI to craft one."))

/// Craft a specific item
/obj/structure/grid_crafting_station/proc/CraftItem(mob/user, datum/grid_craft_item/item)
	if(!item)
		return FALSE

	if(!item.IsInRange(grid_manager.focus_x, grid_manager.focus_y))
		to_chat(user, span_warning("You're not close enough to craft [item.name]!"))
		return FALSE

	// Check if player can access this tier (based on ordeal completion)
	var/effective_tier = GetEffectiveMaxTier()
	if(!debug_mode && item.tier > effective_tier)
		var/needed_ordeal
		switch(item.tier)
			if(1)
				needed_ordeal = "Dawn"
			if(2)
				needed_ordeal = "Noon"
			if(3)
				needed_ordeal = "Dusk"
			if(4)
				needed_ordeal = "Midnight"
		to_chat(user, span_warning("[item.name] requires Tier [item.tier] access! The facility must complete a [needed_ordeal] ordeal first."))
		return FALSE

	// Create the result
	if(item.result_type)
		var/obj/item/crafted = new item.result_type(get_turf(src))
		// Remove attribute requirements from crafted weapons
		if(istype(crafted, /obj/item/ego_weapon))
			var/obj/item/ego_weapon/weapon = crafted
			weapon.attribute_requirements = list()

	last_crafted = item.name
	if(!(item.item_id in crafted_item_ids))
		crafted_item_ids += item.item_id

	to_chat(user, span_notice("<b>Crafted:</b> [item.name]!"))
	playsound(src, 'sound/machines/ping.ogg', 50, TRUE)

	// Add shuffle points
	grid_manager.AddShufflePoints(item.tier)

	// Reset focus point after crafting
	grid_manager.ResetFocus()
	SStgui.update_uis(src)

	return TRUE

/// Reset the grid without crafting
/obj/structure/grid_crafting_station/proc/ResetGrid(mob/user)
	if(grid_manager.cores_used == 0)
		to_chat(user, span_warning("Nothing to reset - you haven't used any cores yet."))
		return

	grid_manager.ResetFocus()
	to_chat(user, span_notice("You reset the grid to origin."))
	SStgui.update_uis(src)

// ===== TGUI Interface =====

/obj/structure/grid_crafting_station/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "EnkephalinGridStation", name)
		ui.open()

/obj/structure/grid_crafting_station/ui_data(mob/user)
	var/list/data = list()

	// Focus point position
	data["focus_x"] = grid_manager.focus_x
	data["focus_y"] = grid_manager.focus_y
	data["cores_used"] = grid_manager.cores_used

	// Shuffle info
	data["shuffle_counter"] = grid_manager.shuffle_counter
	data["shuffle_threshold"] = grid_manager.shuffle_threshold

	// Selected core info
	if(selected_core && !QDELETED(selected_core))
		var/diminishing = GetDiminishingModifier(src, selected_core.sin_type)
		var/consecutive = GetConsecutiveCount(src, selected_core.sin_type)
		data["selected_core"] = list(
			"name" = selected_core.name,
			"movement_type" = selected_core.nav_movement_type,
			"movement_name" = GetMovementTypeName(selected_core.nav_movement_type),
			"sin_name" = GetSinTypeName(selected_core.sin_type),
			"min_distance" = selected_core.GetMinPossibleDistance(),
			"max_distance" = selected_core.GetMaxPossibleDistance(),
			"diminishing_mod" = round(diminishing * 100),
			"consecutive_uses" = consecutive,
			"max_tier" = selected_core.max_tier
		)
	else
		data["selected_core"] = null

	// Stored cores
	var/list/core_data = list()
	for(var/obj/item/navigation_core/core in stored_cores)
		core_data += list(list(
			"ref" = REF(core),
			"name" = core.name,
			"movement_type" = core.nav_movement_type,
			"movement_name" = GetMovementTypeName(core.nav_movement_type),
			"sin_name" = GetSinTypeName(core.sin_type),
			"grade" = core.grade,
			"max_tier" = core.max_tier
		))
	data["available_cores"] = core_data
	data["stored_count"] = length(stored_cores)
	data["max_stored"] = max_stored_cores

	// Debug mode and tier access (ordeal-based only)
	data["debug_mode"] = debug_mode
	var/effective_tier = GetEffectiveMaxTier()
	data["max_accessible_tier"] = effective_tier
	data["ordeal_tier"] = GLOB.grid_craft_ordeal_tier

	// Nearby items (all visible, tier only restricts crafting)
	var/list/nearby = grid_manager.GetNearbyItems(50)
	var/list/item_data = list()
	for(var/datum/grid_craft_item/item in nearby)
		var/dist = item.DistanceFrom(grid_manager.focus_x, grid_manager.focus_y)
		var/in_range = item.IsInRange(grid_manager.focus_x, grid_manager.focus_y)
		var/can_craft = debug_mode || item.tier <= effective_tier
		item_data += list(list(
			"id" = item.item_id,
			"name" = item.name,
			"desc" = item.desc,
			"x" = item.coord_x,
			"y" = item.coord_y,
			"radius" = item.craft_radius,
			"tier" = item.tier,
			"distance" = round(dist, 0.1),
			"in_range" = in_range,
			"locked" = !can_craft
		))
	data["nearby_items"] = item_data

	// Craftable items at current position (all visible, but locked if tier too high)
	var/list/craftable = grid_manager.GetCraftableItems()
	var/list/craftable_data = list()
	for(var/datum/grid_craft_item/item in craftable)
		var/can_craft = debug_mode || item.tier <= effective_tier
		craftable_data += list(list(
			"id" = item.item_id,
			"name" = item.name,
			"desc" = item.desc,
			"tier" = item.tier,
			"locked" = !can_craft
		))
	data["craftable_items"] = craftable_data

	// Last crafted
	data["last_crafted"] = last_crafted

	// Highlighted item
	data["highlighted_item_id"] = highlighted_item_id

	// Crafted items
	data["crafted_item_ids"] = crafted_item_ids

	return data

/obj/structure/grid_crafting_station/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("select_core")
			var/core_ref = params["ref"]
			var/obj/item/navigation_core/core = locate(core_ref)
			if(istype(core))
				SelectCore(core, usr)
			return TRUE

		if("retrieve_core")
			var/core_ref = params["ref"]
			var/obj/item/navigation_core/core = locate(core_ref)
			if(istype(core))
				RetrieveCore(core, usr)
			return TRUE

		if("move")
			var/dir_x = text2num(params["x"]) || 0
			var/dir_y = text2num(params["y"]) || 0
			UseCoreMove(usr, dir_x, dir_y)
			return TRUE

		if("teleport")
			var/target_x = text2num(params["x"]) || 0
			var/target_y = text2num(params["y"]) || 0
			UseCoreMove(usr, 0, 0, target_x, target_y)
			return TRUE

		if("craft")
			var/item_id = params["id"]
			for(var/datum/grid_craft_item/item in grid_manager.items)
				if(item.item_id == item_id)
					CraftItem(usr, item)
					break
			return TRUE

		if("reset")
			ResetGrid(usr)
			return TRUE

		if("highlight_item")
			var/item_id = params["id"]
			if(highlighted_item_id == item_id)
				highlighted_item_id = null
			else
				highlighted_item_id = item_id
			return TRUE

		if("clear_highlight")
			highlighted_item_id = null
			return TRUE

	return FALSE

/obj/structure/grid_crafting_station/examine(mob/user)
	. = ..()
	. += span_notice("Click to open the grid crafting interface.")
	. += span_notice("Use navigation cores on this machine to insert them.")
	. += span_notice("Stored cores: [length(stored_cores)]/[max_stored_cores]")
	. += span_notice("Current position: ([grid_manager.focus_x], [grid_manager.focus_y])")
	. += span_notice("Shuffle progress: [grid_manager.shuffle_counter]/[grid_manager.shuffle_threshold]")
	if(grid_manager.cores_used > 0)
		. += span_notice("Cores used this session: [grid_manager.cores_used]")
	. += span_notice("Weapon tier access: [GLOB.grid_craft_ordeal_tier] (from ordeals)")
	if(last_crafted)
		. += span_notice("Last crafted: [last_crafted]")
	if(debug_mode)
		. += span_boldwarning("DEBUG MODE: All weapon tiers visible.")

/// Debug version
/obj/structure/grid_crafting_station/debug
	name = "grid crafting station (DEBUG)"
	debug_mode = TRUE

// ===== Ordeal Tier Unlocking System =====

/// Initialize the global ordeal tier tracking (called once)
/proc/InitializeOrdealTierTracking()
	if(GLOB.grid_craft_ordeal_initialized)
		return
	GLOB.grid_craft_ordeal_initialized = TRUE
	RegisterSignal(SSdcs, COMSIG_GLOB_ORDEAL_END, GLOBAL_PROC_REF(OnOrdealComplete))

/// Called when an ordeal completes - updates the global tier unlock
/proc/OnOrdealComplete(datum/source, datum/ordeal/completed_ordeal)
	SIGNAL_HANDLER
	if(!completed_ordeal)
		return

	// Map ordeal level to tier: Dawn(1)=Tier1, Noon(2)=Tier2, Dusk(3)=Tier3, Midnight(4)=Tier4
	var/ordeal_level = completed_ordeal.level
	// Handle special ordeal levels (6-9 are white ordeal variants of 1-4)
	if(ordeal_level >= 6 && ordeal_level <= 9)
		ordeal_level = ordeal_level - 5

	// Only update if this ordeal unlocks a higher tier
	if(ordeal_level > GLOB.grid_craft_ordeal_tier && ordeal_level <= 4)
		GLOB.grid_craft_ordeal_tier = ordeal_level
		// Announce the unlock
		var/tier_name
		switch(ordeal_level)
			if(1)
				tier_name = "Dawn"
			if(2)
				tier_name = "Noon"
			if(3)
				tier_name = "Dusk"
			if(4)
				tier_name = "Midnight"
		for(var/obj/structure/grid_crafting_station/station in GLOB.lobotomy_devices)
			station.visible_message(span_notice("Grid Crafting: [tier_name] ordeal completed! Tier [ordeal_level] weapons are now globally accessible."))

/// Get the effective maximum accessible tier (based on ordeal completion only)
/obj/structure/grid_crafting_station/proc/GetEffectiveMaxTier()
	return GLOB.grid_craft_ordeal_tier
