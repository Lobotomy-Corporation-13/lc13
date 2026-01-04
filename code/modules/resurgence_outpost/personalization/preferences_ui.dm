/**
 * Resurgence Character Setup - Preferences Integration
 *
 * Adds resurgence-specific preferences (traits, passions, starting stats)
 * to the client preferences system and provides a TGUI interface for setup.
 */

// ============================================
// Preference Variables Extension
// ============================================

/datum/preferences
	/// List of selected resurgence trait types
	var/list/resurgence_traits = list()
	/// The chosen passion stat ("crafting", "mining", etc.)
	var/resurgence_passion = null
	/// Associative list of stat -> allocated points
	var/list/resurgence_stat_points = list()

// ============================================
// Save/Load Hooks
// ============================================

/**
 * Load resurgence preferences from savefile
 * Called from load_character()
 */
/datum/preferences/proc/load_resurgence_prefs(savefile/S)
	READ_FILE(S["resurgence_traits"], resurgence_traits)
	READ_FILE(S["resurgence_passion"], resurgence_passion)
	READ_FILE(S["resurgence_stat_points"], resurgence_stat_points)

	// Sanitize
	resurgence_traits = SANITIZE_LIST(resurgence_traits)
	resurgence_stat_points = SANITIZE_LIST(resurgence_stat_points)

	// Validate traits
	if(!validate_resurgence_traits(resurgence_traits))
		resurgence_traits = list()

	// Validate stats
	if(!validate_resurgence_stats(resurgence_stat_points))
		resurgence_stat_points = list()

	// Validate passion
	if(!validate_resurgence_passion(resurgence_passion))
		resurgence_passion = null

/**
 * Save resurgence preferences to savefile
 * Called from save_character()
 */
/datum/preferences/proc/save_resurgence_prefs(savefile/S)
	// Convert trait instances to type paths for saving
	var/list/trait_types = list()
	for(var/trait_type in resurgence_traits)
		if(ispath(trait_type))
			trait_types += "[trait_type]"

	WRITE_FILE(S["resurgence_traits"], trait_types)
	WRITE_FILE(S["resurgence_passion"], resurgence_passion)
	WRITE_FILE(S["resurgence_stat_points"], resurgence_stat_points)

// ============================================
// TGUI Interface Handler
// ============================================

/**
 * Datum for handling the resurgence character setup UI
 */
/datum/resurgence_character_setup
	/// The client's preferences
	var/datum/preferences/prefs
	/// The mob using this (for UI ownership)
	var/mob/user

/datum/resurgence_character_setup/New(datum/preferences/P, mob/M)
	prefs = P
	user = M

/datum/resurgence_character_setup/Destroy()
	prefs = null
	user = null
	return ..()

/datum/resurgence_character_setup/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ResurgenceCharacterSetup", "Resurgence Character Setup")
		ui.open()
		ui.set_autoupdate(TRUE)

/datum/resurgence_character_setup/ui_state(mob/user)
	return GLOB.always_state

/datum/resurgence_character_setup/ui_static_data(mob/user)
	var/list/data = list()

	// Initialize trait cache if needed
	if(!length(GLOB.resurgence_trait_cache))
		init_resurgence_traits()

	// Trait definitions for UI
	var/list/positive_traits = list()
	var/list/negative_traits = list()
	var/list/mixed_traits = list()

	for(var/trait_type in GLOB.resurgence_trait_cache)
		var/datum/resurgence_trait/T = GLOB.resurgence_trait_cache[trait_type]
		var/list/trait_data = list(
			"type" = "[trait_type]",
			"name" = T.name,
			"desc" = T.desc,
			"cost" = T.point_cost,
			"incompatible" = list()
		)
		for(var/incompat_type in T.incompatible)
			trait_data["incompatible"] += "[incompat_type]"

		if(T.is_mixed)
			mixed_traits[++mixed_traits.len] = trait_data
		else if(T.point_cost > 0)
			positive_traits[++positive_traits.len] = trait_data
		else if(T.point_cost < 0)
			negative_traits[++negative_traits.len] = trait_data

	data["positive_traits"] = positive_traits
	data["negative_traits"] = negative_traits
	data["mixed_traits"] = mixed_traits

	// Stat definitions
	var/list/stats = list()
	for(var/stat in GLOB.resurgence_stat_types)
		stats += list(list(
			"id" = stat,
			"name" = get_stat_display_name(stat),
			"icon" = get_stat_icon(stat)
		))
	data["stats"] = stats

	// Point pools
	data["trait_point_pool"] = TRAIT_POINT_POOL
	data["stat_point_pool"] = STAT_POINT_POOL
	data["max_starting_stat"] = MAX_STARTING_STAT
	data["max_total_starting_stat"] = MAX_TOTAL_STARTING_STAT
	data["random_stat_bonus"] = RANDOM_STAT_BONUS

	return data

/datum/resurgence_character_setup/ui_data(mob/user)
	var/list/data = list()

	if(!prefs)
		return data

	// Selected traits (as type strings)
	var/list/selected_traits = list()
	for(var/trait_type in prefs.resurgence_traits)
		selected_traits += "[trait_type]"
	data["selected_traits"] = selected_traits

	// Calculate trait points used
	var/points_used = 0
	for(var/trait_type in prefs.resurgence_traits)
		var/datum/resurgence_trait/T = get_resurgence_trait(trait_type)
		if(T)
			points_used += T.point_cost
	data["trait_points_used"] = points_used

	// Selected passion
	data["selected_passion"] = prefs.resurgence_passion

	// Stat allocation
	var/list/stat_allocation = list()
	var/stat_points_used = 0
	for(var/stat in GLOB.resurgence_stat_types)
		var/points = 0
		if(prefs.resurgence_stat_points && prefs.resurgence_stat_points[stat])
			points = prefs.resurgence_stat_points[stat]
		stat_allocation[stat] = points
		stat_points_used += points
	data["stat_allocation"] = stat_allocation
	data["stat_points_used"] = stat_points_used

	return data

/datum/resurgence_character_setup/ui_act(action, list/params)
	. = ..()
	if(.)
		return

	if(!prefs)
		return FALSE

	switch(action)
		// Trait selection
		if("toggle_trait")
			var/trait_type_str = params["trait_type"]
			if(!trait_type_str)
				return FALSE

			var/trait_type = text2path(trait_type_str)
			if(!trait_type)
				return FALSE

			var/datum/resurgence_trait/T = get_resurgence_trait(trait_type)
			if(!T)
				return FALSE

			// Toggle selection
			if(trait_type in prefs.resurgence_traits)
				prefs.resurgence_traits -= trait_type
			else
				// Check if we can add this trait
				var/list/test_traits = prefs.resurgence_traits.Copy()
				test_traits += trait_type

				if(validate_resurgence_traits(test_traits))
					prefs.resurgence_traits += trait_type
				else
					return FALSE

			prefs.save_character()
			return TRUE

		// Clear all traits
		if("clear_traits")
			prefs.resurgence_traits = list()
			prefs.save_character()
			return TRUE

		// Passion selection
		if("select_passion")
			var/passion = params["passion"]
			if(passion && !(passion in GLOB.resurgence_stat_types))
				return FALSE

			prefs.resurgence_passion = passion
			prefs.save_character()
			return TRUE

		// Stat allocation
		if("adjust_stat")
			var/stat = params["stat"]
			var/adjustment = text2num(params["adjustment"])

			if(!stat || !(stat in GLOB.resurgence_stat_types))
				return FALSE
			if(!adjustment || (adjustment != 1 && adjustment != -1))
				return FALSE

			// Initialize if needed
			if(!prefs.resurgence_stat_points)
				prefs.resurgence_stat_points = list()

			var/current = prefs.resurgence_stat_points[stat] || 0
			var/new_value = current + adjustment

			// Validate bounds
			if(new_value < 0 || new_value > MAX_STARTING_STAT)
				return FALSE

			// Check total points
			var/total_used = -current + new_value
			for(var/s in prefs.resurgence_stat_points)
				if(s != stat)
					total_used += prefs.resurgence_stat_points[s]

			if(total_used > STAT_POINT_POOL)
				return FALSE

			prefs.resurgence_stat_points[stat] = new_value
			prefs.save_character()
			return TRUE

		// Clear all stats
		if("clear_stats")
			prefs.resurgence_stat_points = list()
			prefs.save_character()
			return TRUE

		// Reset all selections
		if("reset_all")
			prefs.resurgence_traits = list()
			prefs.resurgence_passion = null
			prefs.resurgence_stat_points = list()
			prefs.save_character()
			return TRUE

		// Close the UI
		if("close")
			SStgui.close_uis(src)
			return TRUE

	return FALSE

// ============================================
// Open UI Proc
// ============================================

/**
 * Open the resurgence character setup UI for a client
 */
/proc/open_resurgence_character_setup(client/C)
	if(!C?.prefs)
		return

	var/datum/resurgence_character_setup/setup = new(C.prefs, C.mob)
	setup.ui_interact(C.mob)

// ============================================
// Verb for Testing
// ============================================

/client/proc/resurgence_character_setup()
	set name = "Resurgence Character Setup"
	set category = "OOC"
	set desc = "Configure your Resurgence Machine character."

	if(!prefs)
		to_chat(src, span_warning("Preferences not loaded."))
		return

	// Only allow if they have a resurgence machine character selected
	// or if we're in debug mode
	open_resurgence_character_setup(src)
