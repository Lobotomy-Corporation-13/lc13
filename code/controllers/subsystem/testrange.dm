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
	var/static/list/linked_ego_printers = list()
	var/static/ego_datums_initialized = FALSE
	var/static/ego_datums_initializing = FALSE

// So, this subsystem currently exists primarily for the sake of EGO printers - I plan to keep updating the test range so this subsystem will likely be expanded upon

/datum/controller/subsystem/testrange/Initialize(start_timeofday)
	ego_datums_initializing = TRUE
	INVOKE_ASYNC(src, PROC_REF(InitializeDatums))
	return ..()

// Evil proc that generates an ego datum for every EGO that isn't test range blacklisted and has a path, also generating a preview icon WHICH IS A BIT HEAVY ON DISK USAGE ! ! !
// However, on my machine, this is actually only about as expensive on compute as someone firing Havana... I think that might say more about Havana though
/datum/controller/subsystem/testrange/proc/InitializeDatums()
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
/datum/controller/subsystem/proc/GetEgoDatumItemIcon(obj/item/item_path)
	if(!ispath(item_path))
		return
	var/item_icon = initial(item_path.icon)
	var/item_icon_state = initial(item_path.icon_state)
	if(!(item_icon_state in icon_states(icon(item_icon))))
		item_icon_state = "" // Some insidious datums have no icon state, like naked nest cure
	var/icon/final_icon = icon(icon = item_icon, icon_state = item_icon_state, frame = 1)
	return final_icon
