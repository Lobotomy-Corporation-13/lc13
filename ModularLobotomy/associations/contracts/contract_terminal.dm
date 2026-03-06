/// Association Contract Terminal — physical machine where non-fixers create contracts.
/// Hana has unlimited funding. Civilians pay from their bank account.
/// Association fixers cannot create contracts (they must be hired).
/obj/machinery/association_contract_terminal
	name = "association contract terminal"
	desc = "A terminal for creating association contracts. Hand the printed contract to a fixer."
	icon = 'icons/obj/computer.dmi'
	icon_state = "oldcomp"
	density = TRUE
	/// Available contract type definitions for the UI
	var/static/list/contract_type_defs
	/// Shared city map data singleton (generated once per round)
	var/static/datum/contract_citymap/citymap
	/// Waypoints placed during current map session
	var/list/citymap_waypoints
	/// Viewport grid-X position (1-indexed, left edge)
	var/view_gx = 0
	/// Viewport grid-Y position (1-indexed, bottom edge)
	var/view_gy = 0
	/// Debug mode — allows fixers to create contracts from this terminal
	var/debug_mode = FALSE

/obj/machinery/association_contract_terminal/Initialize(mapload)
	. = ..()
	if(!contract_type_defs)
		init_contract_type_defs()
	// Lazy-init the city map after a delay to ensure map is loaded
	if(!citymap)
		addtimer(CALLBACK(src, PROC_REF(delayed_map_init)), 10 SECONDS)

/// Delayed initialization for the city map.
/obj/machinery/association_contract_terminal/proc/delayed_map_init()
	if(!citymap)
		citymap = new /datum/contract_citymap()
		var/turf/our_turf = get_turf(src)
		if(our_turf)
			citymap.GenerateCityMap(our_turf.z)

/// Initialize the static list of available contract types.
/obj/machinery/association_contract_terminal/proc/init_contract_type_defs()
	contract_type_defs = list()
	contract_type_defs += list(list(
		"type" = "escort_person",
		"name" = "Escort Person",
		"desc" = "Assign fixers to escort a target. Timer only ticks while a fixer is within 7 tiles.",
		"category" = CONTRACT_CATEGORY_DURATION,
		"needs_target" = TRUE,
		"tiers" = list(
			list("tier" = CONTRACT_TIER_SHORT, "tier_name" = "Short (6 min)", "cost" = 375),
			list("tier" = CONTRACT_TIER_MEDIUM, "tier_name" = "Medium (10 min)", "cost" = 625),
			list("tier" = CONTRACT_TIER_LONG, "tier_name" = "Long (20 min)", "cost" = 1000),
		),
	))
	contract_type_defs += list(list(
		"type" = "eliminate_target",
		"name" = "Eliminate Target",
		"desc" = "Hire fixers to eliminate a specific target. Completes on target death.",
		"category" = CONTRACT_CATEGORY_OBJECTIVE,
		"needs_target" = TRUE,
		"tiers" = list(
			list("tier" = 0, "tier_name" = "Flat", "cost" = 1500),
		),
	))
	contract_type_defs += list(list(
		"type" = "patrol_route",
		"name" = "Patrol Route",
		"desc" = "Fixers visit each waypoint in order and hold position for 30 seconds. Place waypoints on the City Map tab. Cost scales with waypoints.",
		"category" = CONTRACT_CATEGORY_DURATION,
		"needs_target" = FALSE,
		"uses_waypoints" = TRUE,
		"tiers" = list(
			list("tier" = 0, "tier_name" = "Per Waypoint", "cost" = 0),
		),
	))
	contract_type_defs += list(list(
		"type" = "investigate_person",
		"name" = "Investigate Person",
		"desc" = "Hire Seven fixers to investigate a target. Requires filing 2/3/5 intel reports depending on tier.",
		"category" = CONTRACT_CATEGORY_OBJECTIVE,
		"needs_target" = TRUE,
		"association_type" = ASSOCIATION_SEVEN,
		"tiers" = list(
			list("tier" = 1, "tier_name" = "Basic (2 Reports)", "cost" = 500),
			list("tier" = 2, "tier_name" = "Standard (3 Reports)", "cost" = 800),
			list("tier" = 3, "tier_name" = "Thorough (5 Reports)", "cost" = 1250),
		),
	))
	contract_type_defs += list(list(
		"type" = "surveillance_post",
		"name" = "Surveillance Post",
		"desc" = "Deploy Seven recorders at a location. Timer ticks while a recorder is in range. Place one waypoint on the City Map tab.",
		"category" = CONTRACT_CATEGORY_DURATION,
		"needs_target" = FALSE,
		"association_type" = ASSOCIATION_SEVEN,
		"uses_waypoints" = TRUE,
		"single_waypoint" = TRUE,
		"tiers" = list(
			list("tier" = CONTRACT_TIER_SHORT, "tier_name" = "Short (6 min)", "cost" = 375),
			list("tier" = CONTRACT_TIER_MEDIUM, "tier_name" = "Medium (10 min)", "cost" = 625),
			list("tier" = CONTRACT_TIER_LONG, "tier_name" = "Long (20 min)", "cost" = 1000),
		),
	))
	contract_type_defs += list(list(
		"type" = "guard_area",
		"name" = "Guard Area",
		"desc" = "Hire Zwei fixers to guard a location. Timer ticks while a fixer is inside the zone. Place one waypoint on the City Map tab.",
		"category" = CONTRACT_CATEGORY_DURATION,
		"needs_target" = FALSE,
		"association_type" = ASSOCIATION_ZWEI,
		"uses_waypoints" = TRUE,
		"single_waypoint" = TRUE,
		"tiers" = list(
			list("tier" = CONTRACT_TIER_SHORT, "tier_name" = "Short (6 min)", "cost" = 500),
			list("tier" = CONTRACT_TIER_MEDIUM, "tier_name" = "Medium (10 min)", "cost" = 875),
			list("tier" = CONTRACT_TIER_LONG, "tier_name" = "Long (20 min)", "cost" = 1500),
		),
	))
	contract_type_defs += list(list(
		"type" = "protect_person",
		"name" = "Protect Person",
		"desc" = "Hire Zwei fixers to bodyguard a target. Timer ticks while a fixer is within 7 tiles. Client receives 15% damage reduction.",
		"category" = CONTRACT_CATEGORY_DURATION,
		"needs_target" = TRUE,
		"association_type" = ASSOCIATION_ZWEI,
		"tiers" = list(
			list("tier" = CONTRACT_TIER_SHORT, "tier_name" = "Short (6 min)", "cost" = 625),
			list("tier" = CONTRACT_TIER_MEDIUM, "tier_name" = "Medium (10 min)", "cost" = 1000),
			list("tier" = CONTRACT_TIER_LONG, "tier_name" = "Long (20 min)", "cost" = 1750),
		),
	))
	// -- Dieci Contracts --
	contract_type_defs += list(list(
		"type" = "host_event",
		"name" = "Host Event",
		"desc" = "Hire Dieci fixers to host a public event. Pick an event type and location. Hosting at the marked location doubles event EXP.",
		"category" = CONTRACT_CATEGORY_OBJECTIVE,
		"needs_target" = FALSE,
		"association_type" = ASSOCIATION_DIECI,
		"uses_waypoints" = TRUE,
		"single_waypoint" = TRUE,
		"tiers" = list(
			list("tier" = 1, "tier_name" = "Book Reading", "cost" = 500),
			list("tier" = 2, "tier_name" = "Training Session", "cost" = 1000),
			list("tier" = 3, "tier_name" = "Charity Sermon", "cost" = 1800),
		),
	))
	contract_type_defs += list(list(
		"type" = "medical_relief",
		"name" = "Medical Relief",
		"desc" = "Hire Dieci fixers to provide medical aid. Completes when the required number of unique patients are healed.",
		"category" = CONTRACT_CATEGORY_OBJECTIVE,
		"needs_target" = FALSE,
		"association_type" = ASSOCIATION_DIECI,
		"tiers" = list(
			list("tier" = 1, "tier_name" = "Basic (5 Patients)", "cost" = 400),
			list("tier" = 2, "tier_name" = "Standard (8 Patients)", "cost" = 700),
			list("tier" = 3, "tier_name" = "Thorough (12 Patients)", "cost" = 1100),
		),
	))
	contract_type_defs += list(list(
		"type" = "tend_to_person",
		"name" = "Tend to Person",
		"desc" = "Hire Dieci fixers to care for a target. Timer ticks while a fixer is within 7 tiles and target is above 50% HP. Healing the target grants +50% bonus EXP.",
		"category" = CONTRACT_CATEGORY_DURATION,
		"needs_target" = TRUE,
		"association_type" = ASSOCIATION_DIECI,
		"tiers" = list(
			list("tier" = CONTRACT_TIER_SHORT, "tier_name" = "Short (6 min)", "cost" = 500),
			list("tier" = CONTRACT_TIER_MEDIUM, "tier_name" = "Medium (10 min)", "cost" = 875),
			list("tier" = CONTRACT_TIER_LONG, "tier_name" = "Long (20 min)", "cost" = 1500),
		),
	))

/obj/machinery/association_contract_terminal/ui_interact(mob/user, datum/tgui/ui)
	// Ensure map is generated before opening
	if(!citymap)
		citymap = new /datum/contract_citymap()
		var/turf/our_turf = get_turf(src)
		if(our_turf)
			citymap.GenerateCityMap(our_turf.z)
	if(!citymap_waypoints)
		citymap_waypoints = list()
	// Center viewport on first open
	if(citymap?.generated && !view_gx)
		var/vp = CITYMAP_VIEWPORT_SIZE
		view_gx = max(1, round((citymap.grid_width - vp) / 2) + 1)
		view_gy = max(1, round((citymap.grid_height - vp) / 2) + 1)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ContractTerminal")
		ui.open()

/obj/machinery/association_contract_terminal/ui_state()
	return GLOB.default_state

/// Dynamic data sent on each update.
/obj/machinery/association_contract_terminal/ui_data(mob/user)
	var/list/data = list()
	// User info
	var/datum/bank_account/account = get_user_bank_account(user)
	var/is_hana = is_hana_role(user)
	var/is_fixer = !!user.GetComponent(/datum/component/association_exp)
	data["user_balance"] = is_hana ? -1 : (account ? account.account_balance : 0)
	data["is_hana"] = is_hana
	data["is_fixer"] = debug_mode ? FALSE : is_fixer
	data["has_account"] = !!account
	// Check if user can view active contracts (observers, hana, and association fixers only)
	var/can_view_contracts = isobserver(user) || is_hana || is_fixer
	data["can_view_contracts"] = can_view_contracts
	// Available contract types (filtered by active associations)
	data["contract_types"] = get_available_contract_types()
	// Valid targets: living human players on the same Z-level
	var/list/targets = list()
	var/turf/our_turf = get_turf(src)
	if(our_turf)
		for(var/mob/living/carbon/human/H in GLOB.player_list)
			if(H.stat == DEAD)
				continue
			var/turf/their_turf = get_turf(H)
			if(!their_turf || their_turf.z != our_turf.z)
				continue
			targets += list(list("name" = H.name, "ref" = ref(H)))
	data["targets"] = targets
	// Active contracts across all squads (only for authorized viewers)
	var/list/active = list()
	if(can_view_contracts)
		for(var/datum/association_squad/squad in GLOB.association_squads)
			for(var/datum/association_contract/C in squad.active_contracts)
				active += list(C.get_display_data())
	data["active_contracts"] = active
	// Waypoints (dynamic — changes with user interaction)
	data["waypoints"] = citymap_waypoints
	data["waypoint_count"] = length(citymap_waypoints)
	data["patrol_cost"] = CONTRACT_PATROL_BASE_COST + (CONTRACT_PATROL_COST_PER_POINT * length(citymap_waypoints))
	// City map viewport chunk
	if(citymap?.generated)
		var/vp = CITYMAP_VIEWPORT_SIZE
		var/max_gx = max(1, citymap.grid_width - vp + 1)
		var/max_gy = max(1, citymap.grid_height - vp + 1)
		view_gx = clamp(view_gx, 1, max_gx)
		view_gy = clamp(view_gy, 1, max_gy)
		data["mapGrid"] = citymap.GetViewportChunk(view_gx, view_gy, vp)
		data["viewWorldX"] = citymap.offset_x + view_gx - 1
		data["viewWorldY"] = citymap.offset_y + view_gy - 1
		data["canMoveN"] = view_gy < max_gy
		data["canMoveS"] = view_gy > 1
		data["canMoveE"] = view_gx < max_gx
		data["canMoveW"] = view_gx > 1
		data["map_legend"] = citymap.cached_legend
	return data

/obj/machinery/association_contract_terminal/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("create_contract")
			return handle_create_contract(usr, params)
		if("move_viewport")
			return handle_move_viewport(params)
		if("place_waypoint")
			return handle_place_waypoint(usr, params)
		if("clear_waypoints")
			citymap_waypoints.Cut()
			return TRUE
		if("cancel_contract")
			return handle_cancel_contract(usr, params)

/// Handle contract creation from the TGUI.
/obj/machinery/association_contract_terminal/proc/handle_create_contract(mob/living/user, list/params)
	if(!user || !istype(user))
		return FALSE
	// Fixers cannot create contracts (unless debug mode)
	if(!debug_mode && user.GetComponent(/datum/component/association_exp))
		to_chat(user, span_warning("Association members cannot create contracts."))
		return FALSE
	// Get contract type
	var/contract_type = params["contract_type"]
	var/list/type_def = find_type_def(contract_type)
	if(!type_def)
		return FALSE
	// Get tier (for duration contracts)
	var/tier_index = text2num(params["tier_index"])
	if(!tier_index || tier_index < 1 || tier_index > length(type_def["tiers"]))
		tier_index = 1
	var/list/tier_def = type_def["tiers"][tier_index]
	var/cost = tier_def["cost"]
	var/tier_value = tier_def["tier"]
	// Override cost and validation for patrol contracts
	if(contract_type == "patrol_route")
		if(!length(citymap_waypoints))
			to_chat(user, span_warning("Place waypoints on the City Map tab first."))
			return FALSE
		cost = CONTRACT_PATROL_BASE_COST + (CONTRACT_PATROL_COST_PER_POINT * length(citymap_waypoints))
		// Validate full pathfinding chain
		if(citymap?.generated)
			var/turf/term_turf = get_turf(src)
			var/prev_x = term_turf?.x
			var/prev_y = term_turf?.y
			for(var/list/wp in citymap_waypoints)
				if(prev_x && prev_y && citymap.IsFloorTile(prev_x, prev_y))
					if(!citymap.CanPathfind(prev_x, prev_y, wp["x"], wp["y"]))
						to_chat(user, span_warning("Route has unreachable segments. Clear and re-place waypoints."))
						return FALSE
				prev_x = wp["x"]
				prev_y = wp["y"]
	// Validate surveillance post: must have exactly 1 waypoint
	if(contract_type == "surveillance_post")
		if(length(citymap_waypoints) != 1)
			to_chat(user, span_warning("Place exactly one waypoint on the City Map tab for the surveillance location."))
			return FALSE
	// Validate guard area: must have exactly 1 waypoint
	if(contract_type == "guard_area")
		if(length(citymap_waypoints) != 1)
			to_chat(user, span_warning("Place exactly one waypoint on the City Map tab for the guard zone center."))
			return FALSE
	// Validate host event: must have exactly 1 waypoint
	if(contract_type == "host_event")
		if(length(citymap_waypoints) != 1)
			to_chat(user, span_warning("Place exactly one waypoint on the City Map tab for the event location."))
			return FALSE
	// Payment check
	var/is_hana = is_hana_role(user)
	var/datum/bank_account/account = get_user_bank_account(user)
	if(!is_hana)
		if(!account)
			to_chat(user, span_warning("You need a bank account to create contracts."))
			return FALSE
		if(!account.has_money(cost))
			to_chat(user, span_warning("Insufficient funds. You need [cost] Ahn."))
			return FALSE
	// Target selection (if needed)
	var/mob/living/target_mob
	if(type_def["needs_target"])
		var/target_ref = params["target_ref"]
		if(!target_ref)
			to_chat(user, span_warning("No target selected."))
			return FALSE
		target_mob = locate(target_ref) in GLOB.player_list
		if(!target_mob || QDELETED(target_mob) || !ishuman(target_mob))
			to_chat(user, span_warning("Invalid target."))
			return FALSE
		if(target_mob.stat == DEAD)
			to_chat(user, span_warning("Target is dead."))
			return FALSE
	// Determine source type
	var/source = is_hana ? CONTRACT_SOURCE_HANA : CONTRACT_SOURCE_CIVILIAN
	// Deduct payment (civilians only — Hana has unlimited funding)
	if(!is_hana && account)
		account.adjust_money(-cost)
	// Create the contract datum
	var/datum/association_contract/C = create_contract_datum(contract_type, source, cost, user, target_mob, tier_value)
	if(!C)
		// Refund if creation failed
		if(!is_hana && account)
			account.adjust_money(cost)
		return FALSE
	// Spawn the physical contract paper
	new /obj/item/association_contract_paper(get_turf(src), C)
	to_chat(user, span_nicegreen("Contract created! Hand the contract paper to an association fixer."))
	playsound(src, 'sound/machines/twobeep_high.ogg', 50, TRUE)
	// Clear waypoints after waypoint-based contract creation
	if(contract_type == "patrol_route" || contract_type == "surveillance_post" || contract_type == "guard_area" || contract_type == "host_event")
		citymap_waypoints.Cut()
	return TRUE

/// Create the appropriate contract datum subtype based on contract_type string.
/obj/machinery/association_contract_terminal/proc/create_contract_datum(contract_type, source, cost, mob/living/issuer, mob/living/target, tier_value)
	var/datum/association_contract/C
	switch(contract_type)
		if("escort_person")
			C = new /datum/association_contract/escort_person(contract_type, source, cost, issuer)
			C.target_mob = target
			C.set_duration_tier(tier_value)
		if("eliminate_target")
			C = new /datum/association_contract/eliminate_target(contract_type, source, cost, issuer)
			C.target_mob = target
		if("patrol_route")
			var/datum/association_contract/patrol_route/PC = new(contract_type, source, cost, issuer)
			PC.patrol_waypoints = list()
			for(var/list/wp in citymap_waypoints)
				PC.patrol_waypoints += list(list("x" = wp["x"], "y" = wp["y"]))
			PC.total_duration = CONTRACT_PATROL_STAY_TIME * length(PC.patrol_waypoints)
			PC.remaining_time = PC.total_duration
			PC.set_completion_exp()
			// Set z-level and citymap reference for zone spawning and route viewer
			var/turf/term_turf = get_turf(src)
			if(term_turf)
				PC.waypoint_zlevel = term_turf.z
			PC.citymap = citymap
			C = PC
		if("investigate_person")
			var/datum/association_contract/investigate_person/IC = new(contract_type, source, cost, issuer)
			IC.target_mob = target
			IC.set_report_tier(tier_value)
			C = IC
		if("surveillance_post")
			var/datum/association_contract/surveillance_post/SC = new(contract_type, source, cost, issuer)
			SC.set_duration_tier(tier_value)
			SC.surveillance_point = list("x" = citymap_waypoints[1]["x"], "y" = citymap_waypoints[1]["y"])
			var/turf/term_turf = get_turf(src)
			if(term_turf)
				SC.waypoint_zlevel = term_turf.z
			SC.citymap = citymap
			C = SC
		if("guard_area")
			var/datum/association_contract/guard_area/GC = new(contract_type, source, cost, issuer)
			GC.set_duration_tier(tier_value)
			GC.guard_point = list("x" = citymap_waypoints[1]["x"], "y" = citymap_waypoints[1]["y"])
			var/turf/term_turf = get_turf(src)
			if(term_turf)
				GC.waypoint_zlevel = term_turf.z
			GC.citymap = citymap
			C = GC
		if("protect_person")
			C = new /datum/association_contract/protect_person(contract_type, source, cost, issuer)
			C.target_mob = target
			C.set_duration_tier(tier_value)
		if("host_event")
			var/datum/association_contract/host_event/HEC = new(contract_type, source, cost, issuer)
			HEC.set_event_tier(tier_value)
			HEC.event_waypoint = list("x" = citymap_waypoints[1]["x"], "y" = citymap_waypoints[1]["y"])
			var/turf/term_turf = get_turf(src)
			if(term_turf)
				HEC.waypoint_zlevel = term_turf.z
			HEC.citymap = citymap
			C = HEC
		if("medical_relief")
			var/datum/association_contract/medical_relief/MRC = new(contract_type, source, cost, issuer)
			MRC.set_patient_tier(tier_value)
			C = MRC
		if("tend_to_person")
			C = new /datum/association_contract/tend_to_person(contract_type, source, cost, issuer)
			C.target_mob = target
			C.set_duration_tier(tier_value)
		else
			// Generic fallback
			C = new(contract_type, source, cost, issuer)
			if(tier_value)
				C.set_duration_tier(tier_value)
	if(C && debug_mode)
		C.debug_mode = TRUE
	return C

/// Find a contract type definition by its type string.
/obj/machinery/association_contract_terminal/proc/find_type_def(contract_type)
	for(var/list/def in contract_type_defs)
		if(def["type"] == contract_type)
			return def
	return null

/// Get a user's bank account from their ID card.
/obj/machinery/association_contract_terminal/proc/get_user_bank_account(mob/living/user)
	if(!ishuman(user))
		return null
	var/mob/living/carbon/human/H = user
	var/obj/item/card/id/ID = H.get_idcard(TRUE)
	if(!ID)
		return null
	return ID.registered_account

/// Check if a user is a Hana Administrator or Representative (not Intern).
/obj/machinery/association_contract_terminal/proc/is_hana_role(mob/living/user)
	if(!user.mind?.assigned_role)
		return FALSE
	var/role = user.mind.assigned_role
	// Hana Administrator or Representative — NOT Intern
	if(role == "Hana Administrator" || role == "Hana Representative")
		return TRUE
	return FALSE

/// Returns the contract type defs filtered by which associations are currently active.
/// Universal contracts (no association_type) always show. Association-specific ones only show
/// when a squad of that type exists in GLOB.association_squads.
/obj/machinery/association_contract_terminal/proc/get_available_contract_types()
	var/list/available = list()
	for(var/list/def in contract_type_defs)
		var/assoc_type = def["association_type"]
		if(!assoc_type)
			available += list(def)
			continue
		for(var/datum/association_squad/squad in GLOB.association_squads)
			if(squad.association_type == assoc_type)
				available += list(def)
				break
	return available

// ============================================================
// City Map Handlers
// ============================================================

/// Handle viewport movement from TGUI arrow buttons.
/obj/machinery/association_contract_terminal/proc/handle_move_viewport(list/params)
	if(!citymap?.generated)
		return FALSE
	var/dir = params["dir"]
	var/step = CITYMAP_MOVE_STEP
	var/vp = CITYMAP_VIEWPORT_SIZE
	var/max_gx = max(1, citymap.grid_width - vp + 1)
	var/max_gy = max(1, citymap.grid_height - vp + 1)
	switch(dir)
		if("north")
			view_gy = clamp(view_gy + step, 1, max_gy)
		if("south")
			view_gy = clamp(view_gy - step, 1, max_gy)
		if("east")
			view_gx = clamp(view_gx + step, 1, max_gx)
		if("west")
			view_gx = clamp(view_gx - step, 1, max_gx)
	return TRUE

/// Handle waypoint placement or removal. Takes world coordinates from TGUI canvas click.
/obj/machinery/association_contract_terminal/proc/handle_place_waypoint(mob/user, list/params)
	if(!citymap || !citymap.generated)
		return FALSE
	var/world_x = text2num(params["world_x"])
	var/world_y = text2num(params["world_y"])
	if(!world_x || !world_y)
		return FALSE
	// Must be a floor tile
	if(!citymap.IsFloorTile(world_x, world_y))
		return FALSE
	// Cannot place waypoints on water turfs or lake areas
	var/turf/src_turf = get_turf(src)
	if(!src_turf)
		return FALSE
	var/turf/target_turf = locate(world_x, world_y, src_turf.z)
	if(target_turf)
		if(istype(target_turf, /turf/open/water/deep))
			if(user)
				to_chat(user, span_warning("Cannot place a waypoint on water."))
			return FALSE
		var/area/target_area = get_area(target_turf)
		if(istype(target_area, /area/city/lake))
			if(user)
				to_chat(user, span_warning("Cannot place a waypoint on water."))
			return FALSE
	// Check for existing waypoint at this location — toggle off
	for(var/list/wp in citymap_waypoints)
		if(wp["x"] == world_x && wp["y"] == world_y)
			citymap_waypoints -= list(wp)
			renumber_waypoints()
			return TRUE
	// Add new waypoint (up to max)
	if(length(citymap_waypoints) >= CITYMAP_MAX_WAYPOINTS)
		return FALSE
	// Validate pathfinding from previous point (or terminal)
	if(!length(citymap_waypoints))
		// First waypoint: validate from terminal location
		var/turf/term_turf = get_turf(src)
		if(term_turf && citymap.IsFloorTile(term_turf.x, term_turf.y))
			if(!citymap.CanPathfind(term_turf.x, term_turf.y, world_x, world_y))
				if(user)
					to_chat(user, span_warning("Cannot reach that location from this terminal."))
				return FALSE
	else
		// Subsequent waypoint: validate from last waypoint
		var/list/last_wp = citymap_waypoints[length(citymap_waypoints)]
		if(!citymap.CanPathfind(last_wp["x"], last_wp["y"], world_x, world_y))
			if(user)
				to_chat(user, span_warning("Cannot reach that location from the previous waypoint."))
			return FALSE
	citymap_waypoints += list(list("x" = world_x, "y" = world_y, "order" = length(citymap_waypoints) + 1))
	return TRUE

/// Handle contract cancellation by a fixer. Refunds the issuer.
/obj/machinery/association_contract_terminal/proc/handle_cancel_contract(mob/living/user, list/params)
	if(!user)
		return FALSE
	// Only fixers can cancel contracts
	if(!user.GetComponent(/datum/component/association_exp))
		to_chat(user, span_warning("Only association members can cancel contracts."))
		return FALSE
	var/contract_id = text2num(params["contract_id"])
	if(!contract_id)
		return FALSE
	// Find the contract across all squads
	for(var/datum/association_squad/squad in GLOB.association_squads)
		for(var/datum/association_contract/C in squad.active_contracts)
			if(C.contract_id == contract_id)
				to_chat(user, span_notice("Cancelling contract \"[C.contract_name]\"."))
				C.cancel()
				return TRUE
	to_chat(user, span_warning("Contract not found."))
	return FALSE

/// Renumber waypoints sequentially after removal.
/obj/machinery/association_contract_terminal/proc/renumber_waypoints()
	for(var/i in 1 to length(citymap_waypoints))
		var/list/wp = citymap_waypoints[i]
		wp["order"] = i
