SUBSYSTEM_DEF(testrange)
	name = "Test Range"
	flags = SS_NO_FIRE
	/// This MUST initialize after Lobotomy Events subsystem, otherwise it can go anywhere really. If you're wondering why, it's because of GotS EGO.
	init_order = INIT_ORDER_TESTRANGE
	/// List of all EGO datums that aren't blacklisted
	var/static/list/ego_datums = list()
	/// List of all EGO datum paths, only used for the old EGO printer interface. Better to cache it than compute it every time, I think?
	var/static/list/ego_datum_paths = list()
	/// Cache of EGO preview images (base64 strings).
	var/static/list/ego_preview_icons_cache = list()
	/// Cache of Threat preview images (base64 strings).
	var/static/list/threat_preview_icons_cache = list()
	var/static/list/linked_ego_printers = list()
	var/static/list/linked_threat_simulators = list()
	var/static/ego_datums_initialized = FALSE
	var/static/ego_datums_initializing = FALSE
	var/static/threat_datums_initialized = FALSE
	var/static/threat_datums_initializing = FALSE
	/// This is an associative list with two entries; "arenas", which is an associative list of key: arena_name, value: list(turfs in that arena); and "lobby", which is a list of turfs in the test range lobby.
	var/static/list/test_range_turfs = list("arenas" = list(), "lobby" = list())
	/// This is an associative list with two entries; "arenas", the value of which is a list of test range arena areas, and "lobby", the value of which which is the test range lobby area.
	var/static/list/test_range_areas = list("arenas" = list(), "lobby" = null)
	/// This is an associative list of key: arena_name, value: test range arena landmark.
	var/static/list/test_range_arenas = list()
	/// This is an associative list of key: arena_name OR "lobby", value: telepad corresponding to that place.
	var/static/list/test_range_telepads = list()
	/// List of the threat datums available for use in the test range.
	var/static/list/test_range_threat_datums = list()
	/// This is a list of living test range agents. They'll be taken off the list upon death, and every time the list is emptied out, all living test range threats will be despawned, also.
	var/static/list/test_range_agents = list()
	/// This is a list of living test range threats. Dead threats will be removed from the list, and anything in this list will be deleted once the test_range_agents list is empty.
	var/static/list/test_range_living_threats = list()

/datum/controller/subsystem/testrange/Initialize(start_timeofday)
	ego_datums_initializing = TRUE
	INVOKE_ASYNC(src, PROC_REF(InitializeEgoDatums))

	threat_datums_initializing = TRUE

	// This is expensive (I think), but I'd rather do this once on initialize than many times per round.
	for(var/area/A in world)
		if(istype(A, /area/test_range_arena))
			var/area/test_range_arena/A1 = A
			test_range_areas["arenas"][A1.GetArenaName()] = A1
		else if(istype(A, /area/test_range_lobby))
			test_range_areas["lobby"] = A

	// Caching turfs corresponding to the test range's areas.
	for(var/arena_key in test_range_areas["arenas"])
		test_range_turfs["arenas"][arena_key] = list()
		for(var/turf/T in test_range_areas["arenas"][arena_key])
			test_range_turfs["arenas"][arena_key] |= T
			for(var/obj/machinery/quantumpad/warp/arena_telepad in T)
				test_range_telepads[arena_key] = arena_telepad

	for(var/turf/T2 in test_range_areas["lobby"])
		test_range_turfs["lobby"] |= T2
		for(var/obj/machinery/quantumpad/warp/lobby_telepad in T2)
			test_range_telepads["lobby"] = lobby_telepad

	INVOKE_ASYNC(src, PROC_REF(InitializeThreatDatums))
	return ..()

// Evil proc that generates an ego datum for every EGO that isn't test range blacklisted and has a path, also generating a preview icon WHICH IS A BIT HEAVY ON DISK USAGE ! ! !
// However, on my machine, this is actually only about as expensive on compute as someone firing Havana... I think that might say more about Havana though
/datum/controller/subsystem/testrange/proc/InitializeEgoDatums()
	if(!ego_datums_initialized)
		for(var/datumpath in subtypesof(/datum/ego_datum))
			var/datum/ego_datum/ED = new datumpath
			if(!(ED.testrange_blacklisted) && (ED.item_path)) // Condition 1 eliminates evil datums like Sorrow and condition 2 eliminates templates that don't have a path (like /ego_datum/weapon/)
				ego_datums |= ED
				ego_datum_paths |= ED.item_path
				GenerateEgoPreviewIcon(ED.item_path)
			else
				qdel(ED)

			stoplag() // Yes it's that bad. This makes the process take quite a while, but it's still under a minute and doesn't lag. The alternative is a biblical lagspike.

		// The datums list is currently in the order that they were 'found' in the directory tree. Now we sort them from highest PE cost to lowest PE cost.
		ego_datums = sortTim(ego_datums, cmp=GLOBAL_PROC_REF(cmp_ego_cost_dsc))

		ego_datums_initializing = FALSE
		ego_datums_initialized = TRUE

		for(var/obj/machinery/ego_printer/EP in linked_ego_printers)
			EP.ego_datums = src.ego_datums
			EP.ego_datum_paths = src.ego_datum_paths
			EP.ReadyMessage()

// This proc doesn't SEEM that bad but it's being run on like 800 things... so it's a LITTLE bad. If you can figure out a better way to move icons into TGUI then have at it
/// Takes an object's icon in DM and turns it into a base64 string, uses caching when possible
/datum/controller/subsystem/testrange/proc/GenerateEgoPreviewIcon(item_path)
	if(!ispath(item_path))
		return

	// Cached? Use that instead
	var/wait_did_we_already_do_this = ego_preview_icons_cache[item_path]
	if(wait_did_we_already_do_this)
		return wait_did_we_already_do_this

	var/icon/final_icon = GetEgoDatumItemIcon(item_path)
	var/base64icon = null

	if(final_icon)
		base64icon = icon2base64(final_icon) // Icon is now a string we can pass into TGUI
		ego_preview_icons_cache[item_path] = base64icon // Add to cache

	qdel(final_icon)
	return base64icon

/// Extracts an item's icon state so we can use it as a preview. Looks jank if it has directionals (W Corp Armour Vest my beloathed)
/datum/controller/subsystem/testrange/proc/GetEgoDatumItemIcon(obj/item/item_path)
	if(!ispath(item_path))
		return
	var/item_icon = initial(item_path.icon)
	var/item_icon_state = initial(item_path.icon_state)
	if(!(item_icon_state in icon_states(icon(item_icon))))
		item_icon_state = "" // Some insidious datums have no icon state, like naked nest cure
	var/icon/final_icon = icon(icon = item_icon, icon_state = item_icon_state, frame = 1)
	return final_icon

/datum/controller/subsystem/testrange/proc/InitializeThreatDatums()
	if(!threat_datums_initialized)
		for(var/datumpath in subtypesof(/datum/test_range_threat))
			var/datum/test_range_threat/TD = new datumpath
			if((TD.enabled) && (TD.mob_path))
				test_range_threat_datums |= TD
				GenerateThreatPreviewIcon(TD)
			else
				qdel(TD)

			stoplag()

		// The datums list is currently in the order that they were 'found' in the directory tree. Now we sort them from highest PE cost to lowest PE cost.
		test_range_threat_datums = sortTim(test_range_threat_datums, cmp=GLOBAL_PROC_REF(cmp_threat_difficulty_asc))

		for(var/obj/machinery/computer/testrangespawner/TRS in linked_threat_simulators)
			TRS.current_arena = pick(test_range_arenas)

			var/obj/machinery/quantumpad/warp/lobby_pad = test_range_telepads["lobby"]
			lobby_pad.linked_pad = test_range_telepads[TRS.current_arena]

			TRS.InitializeCamera()

		threat_datums_initializing = FALSE
		threat_datums_initialized = TRUE

/datum/controller/subsystem/testrange/proc/GenerateThreatPreviewIcon(datum/test_range_threat/threat_datum)
	if(!istype(threat_datum))
		return

	// Cached? Use that instead
	var/wait_did_we_already_do_this = threat_preview_icons_cache[threat_datum.mob_path]
	if(wait_did_we_already_do_this)
		return wait_did_we_already_do_this

	var/icon/final_icon = GetThreatDatumMobIcon(threat_datum.mob_path)
	var/base64icon = null

	if(final_icon)
		base64icon = icon2base64(final_icon) // Icon is now a string we can pass into TGUI
		ego_preview_icons_cache[threat_datum.mob_path] = base64icon // Add to cache

	qdel(final_icon)
	return base64icon

/datum/controller/subsystem/testrange/proc/GetThreatDatumMobIcon(mob_path)
	if(!ispath(mob_path, /mob/living/simple_animal))
		return
	var/mob/living/simple_animal/our_guy = mob_path
	var/mob_icon = initial(our_guy.icon)
	var/mob_icon_state = initial(our_guy.icon_state)
	if(!(mob_icon_state in icon_states(icon(mob_icon))))
		mob_icon_state = ""
	var/icon/final_icon = icon(icon = mob_icon, icon_state = mob_icon_state, dir = SOUTH, frame = 1)
	return final_icon

// Stolen code from Claw Smite.
/datum/controller/subsystem/testrange/proc/Despawn(mob/living/victim)
	var/turf/origin = get_turf(victim)
	var/list/all_turfs = origin.reachableAdjacentTurfs()
	for(var/turf/T in all_turfs)
		if(T == origin)
			continue
		new /obj/effect/temp_visual/dir_setting/claw_appears(T)
		break
	new /obj/effect/temp_visual/justitia_effect(origin)
	qdel(victim)

/datum/controller/subsystem/testrange/proc/CleanupCheck()
	if(!length(test_range_agents))
		// Cleanup will be started with a sliiiight delay to avoid some runtimes from null references from gibbing mobs and stuff...
		addtimer(CALLBACK(src, PROC_REF(Cleanup)), 1 SECONDS)

// This proc has sleeps in it because it looks cooler. Call it asynchronously
/datum/controller/subsystem/testrange/proc/Cleanup()
	for(var/mob/living/L in test_range_living_threats)
		Despawn(L)
		sleep(rand(1,2))

	// Sadly, some mobs spawn byproducts that do not disappear when they are destroyed or killed (Judgement Bird), so we're gonna need to scan every turf of every arena for them... It's not THAT expensive....?
	for(var/arena_key in test_range_turfs["arenas"])
		for(var/turf/T in test_range_turfs["arenas"][arena_key])
			for(var/mob/living/L2 in T)
				Despawn(L2)
				sleep(rand(1,2))
