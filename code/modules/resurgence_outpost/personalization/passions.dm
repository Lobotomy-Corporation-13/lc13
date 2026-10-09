/**
 * Resurgence Passion System
 *
 * Passions provide XP bonuses to specific stats.
 * - Chosen Passion: Player picks ONE stat = 50% XP bonus
 * - Random Passions: 2 additional passions randomly assigned at spawn
 * - Very Passionate: If chosen matches a random = 100% XP bonus
 */

// ============================================
// Passion Setup Procs
// ============================================

/**
 * Setup passions for a resurgence core with random fill-in
 *
 * Arguments:
 * * core - The resurgence core to setup passions for
 * * chosen_passion - The stat the player chose (can be null)
 */
/proc/setup_resurgence_passions(obj/item/organ/resurgence_core/core, chosen_passion)
	if(!core)
		return

	var/list/stat_types = GLOB.resurgence_stat_types.Copy()
	var/final_chosen = chosen_passion

	// If no passion chosen, pick one randomly
	if(!final_chosen || !(final_chosen in stat_types))
		final_chosen = pick(stat_types)
		if(core.owner)
			to_chat(core.owner, span_notice("No passion selected - randomly assigned: [capitalize(final_chosen)]"))

	// Create passions datum
	var/datum/resurgence_passions/passions = new()
	passions.chosen_passion = final_chosen

	// Remove chosen from pool for random selection
	stat_types -= final_chosen

	// Pick 2 random additional passions
	passions.random_passions = list()
	for(var/i in 1 to RANDOM_PASSION_COUNT)
		if(!length(stat_types))
			break
		var/random_passion = pick_n_take(stat_types)
		passions.random_passions += random_passion

	// Set passion levels for each stat
	passions.passion_levels = list()
	for(var/stat in GLOB.resurgence_stat_types)
		var/is_chosen = (stat == passions.chosen_passion)
		var/is_random = (stat in passions.random_passions)

		if(is_chosen && is_random)
			// Very Passionate - both chosen and random (shouldn't happen with current logic)
			passions.passion_levels[stat] = PASSION_PASSIONATE
		else if(is_chosen || is_random)
			// Interested - either chosen or random
			passions.passion_levels[stat] = PASSION_INTERESTED
		else
			// No passion
			passions.passion_levels[stat] = PASSION_NONE

	core.passions = passions

	// Notify player of passions
	if(core.owner)
		var/list/passion_summary = list()
		passion_summary += "[capitalize(passions.chosen_passion)] (Chosen)"
		for(var/rp in passions.random_passions)
			passion_summary += "[capitalize(rp)] (Random)"
		to_chat(core.owner, span_notice("Your passions: [english_list(passion_summary)]"))

/**
 * Get passion icon state for UI display
 *
 * Arguments:
 * * level - PASSION_NONE, PASSION_INTERESTED, or PASSION_PASSIONATE
 *
 * Returns icon state string for flame display
 */
/proc/get_passion_icon_state(level)
	switch(level)
		if(PASSION_PASSIONATE)
			return "double_flame"
		if(PASSION_INTERESTED)
			return "single_flame"
	return "no_flame"

/**
 * Get passion description for UI
 */
/proc/get_passion_description(level)
	switch(level)
		if(PASSION_PASSIONATE)
			return "Very Passionate (+100% XP)"
		if(PASSION_INTERESTED)
			return "Interested (+50% XP)"
	return "No Passion"

/**
 * Get the display name for a stat type
 */
/proc/get_stat_display_name(stat_type)
	switch(stat_type)
		if("crafting")
			return "Crafting"
		if("mining")
			return "Mining"
		if("harvesting")
			return "Harvesting"
		if("cooking")
			return "Cooking"
		if("analysis")
			return "Analysis"
		if("social")
			return "Social"
	return capitalize(stat_type)

/**
 * Get the icon for a stat type
 */
/proc/get_stat_icon(stat_type)
	switch(stat_type)
		if("crafting")
			return "hammer"
		if("mining")
			return "gem"
		if("harvesting")
			return "seedling"
		if("cooking")
			return "utensils"
		if("analysis")
			return "microscope"
		if("social")
			return "comments"
	return "question"
