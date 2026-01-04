/**
 * Resurgence Starting Stats System
 *
 * Handles stat allocation and random distribution at spawn.
 * - Point Budget: 6 points to allocate manually
 * - Max Per Stat: 4 levels in any single skill
 * - Random Bonus: 4 levels randomly distributed at spawn
 * - Base stats start at level 1
 */

// ============================================
// Stat Allocation Procs
// ============================================

/**
 * Apply stat points to a resurgence core with random fill-in for unallocated points
 *
 * Arguments:
 * * core - The resurgence core to apply stats to
 * * player_allocation - Associative list of stat -> points (e.g., list("mining" = 3, "crafting" = 2))
 */
/proc/apply_resurgence_stat_allocation(obj/item/organ/resurgence_core/core, list/player_allocation)
	if(!core)
		return

	var/list/stat_types = GLOB.resurgence_stat_types.Copy()

	// Calculate how many points player allocated
	var/player_points_used = 0
	if(player_allocation)
		for(var/stat in player_allocation)
			if(stat in stat_types)
				player_points_used += player_allocation[stat]

	// Remaining player points become random
	var/unallocated_player_points = STAT_POINT_POOL - player_points_used
	var/total_random_points = RANDOM_STAT_BONUS + unallocated_player_points

	// Track current levels per stat (to enforce MAX_TOTAL_STARTING_STAT cap)
	var/list/current_levels = list()
	for(var/stat in stat_types)
		current_levels[stat] = 0

	// Apply player's chosen allocation first
	if(player_allocation)
		for(var/stat in player_allocation)
			var/amount = player_allocation[stat]
			if(amount > 0 && (stat in stat_types))
				add_stat_levels(core, stat, amount)
				current_levels[stat] = amount

	// Distribute random points
	var/list/random_distribution = list()
	for(var/stat in stat_types)
		random_distribution[stat] = 0

	for(var/i in 1 to total_random_points)
		// Only pick from stats that haven't hit the cap
		var/list/available_stats = list()
		for(var/stat in stat_types)
			if(current_levels[stat] < MAX_TOTAL_STARTING_STAT)
				available_stats += stat

		if(!length(available_stats))
			break  // All stats at cap

		var/stat = pick(available_stats)
		random_distribution[stat]++
		current_levels[stat]++
		add_stat_levels(core, stat, 1)

	// Notify player of random stats
	if(core.owner)
		if(total_random_points > RANDOM_STAT_BONUS)
			to_chat(core.owner, span_notice("You received [total_random_points] random stat levels ([unallocated_player_points] from unallocated points + [RANDOM_STAT_BONUS] bonus)."))
		else
			to_chat(core.owner, span_notice("You received [RANDOM_STAT_BONUS] random stat levels."))

		// Show distribution
		var/list/stat_summary = list()
		for(var/stat in random_distribution)
			if(random_distribution[stat] > 0)
				stat_summary += "[capitalize(stat)]: +[random_distribution[stat]]"
		if(length(stat_summary))
			to_chat(core.owner, span_notice("Random distribution: [english_list(stat_summary)]"))

/**
 * Add stat levels to a core
 *
 * Arguments:
 * * core - The resurgence core
 * * stat_type - The stat to increase ("crafting", "mining", etc.)
 * * amount - Number of levels to add
 */
/proc/add_stat_levels(obj/item/organ/resurgence_core/core, stat_type, amount)
	if(!core || amount <= 0)
		return

	switch(stat_type)
		if("crafting")
			core.stat_crafting = min(core.stat_crafting + amount, STAT_MAX_LEVEL)
		if("mining")
			core.stat_mining = min(core.stat_mining + amount, STAT_MAX_LEVEL)
		if("harvesting")
			core.stat_harvesting = min(core.stat_harvesting + amount, STAT_MAX_LEVEL)
		if("cooking")
			core.stat_cooking = min(core.stat_cooking + amount, STAT_MAX_LEVEL)
		if("analysis")
			core.stat_analysis = min(core.stat_analysis + amount, STAT_MAX_LEVEL)
		if("social")
			core.stat_social = min(core.stat_social + amount, STAT_MAX_LEVEL)

// ============================================
// Random Trait Assignment
// ============================================

/**
 * Assign random traits when player hasn't selected any (or has points remaining)
 *
 * Arguments:
 * * H - The human mob to apply traits to
 * * selected_traits - List of already selected trait types
 * * points_remaining - Points left to spend
 *
 * Returns list of final trait types (selected + random)
 */
/proc/assign_random_resurgence_traits(mob/living/carbon/human/H, list/selected_traits, points_remaining)
	if(!H)
		return list()

	// Make sure trait cache is initialized
	if(!length(GLOB.resurgence_trait_cache))
		init_resurgence_traits()

	var/list/final_traits = list()

	// Add already selected traits to final list
	if(selected_traits)
		final_traits = selected_traits.Copy()

	var/points_to_spend = points_remaining

	// If no traits selected at all, use full point pool
	if(!length(final_traits))
		points_to_spend = TRAIT_POINT_POOL

	// Get available positive traits (not already selected, no incompatibilities)
	var/list/available_positive = list()
	var/list/selected_incompatible = list()

	// Build incompatibility list from selected traits
	for(var/trait_type in final_traits)
		var/datum/resurgence_trait/T = get_resurgence_trait(trait_type)
		if(T)
			selected_incompatible |= T.incompatible

	// Find available traits
	for(var/trait_type in GLOB.resurgence_trait_types)
		// Skip already selected
		if(trait_type in final_traits)
			continue
		// Skip incompatible
		if(trait_type in selected_incompatible)
			continue

		var/datum/resurgence_trait/T = get_resurgence_trait(trait_type)
		if(T && T.point_cost > 0 && !T.is_mixed)
			available_positive += trait_type

	// Randomly assign traits until points are spent
	var/attempts = 0
	while(points_to_spend > 0 && attempts < 20)
		attempts++

		// Pick a random positive trait we can afford
		var/list/affordable = list()
		for(var/trait_type in available_positive)
			var/datum/resurgence_trait/T = get_resurgence_trait(trait_type)
			if(T && T.point_cost <= points_to_spend)
				affordable += trait_type

		if(!length(affordable))
			break  // No affordable traits left

		var/chosen_type = pick(affordable)
		var/datum/resurgence_trait/chosen = get_resurgence_trait(chosen_type)
		if(!chosen)
			continue

		final_traits += chosen_type
		points_to_spend -= chosen.point_cost
		available_positive -= chosen_type

		// Remove incompatible traits from pool
		for(var/trait_type in available_positive)
			if(trait_type in chosen.incompatible)
				available_positive -= trait_type

	// Notify player of random traits
	if(H && length(final_traits) > length(selected_traits))
		var/list/random_names = list()
		for(var/trait_type in final_traits)
			if(selected_traits && (trait_type in selected_traits))
				continue
			var/datum/resurgence_trait/T = get_resurgence_trait(trait_type)
			if(T)
				random_names += T.name
		if(length(random_names))
			to_chat(H, span_notice("Random traits assigned: [english_list(random_names)]"))

	return final_traits

// ============================================
// Complete Personalization Application
// ============================================

/**
 * Apply all personalization to a resurgence machine at spawn
 *
 * Arguments:
 * * H - The human mob to personalize
 */
/proc/apply_resurgence_personalization(mob/living/carbon/human/H)
	if(!H)
		return

	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return

	// Check for preferences
	if(!H.client?.prefs)
		// No preferences - apply fully random build
		apply_random_resurgence_build(H)
		return

	var/datum/preferences/prefs = H.client.prefs

	// === TRAITS ===
	var/list/selected_traits = list()
	var/points_used = 0

	// Get selected traits from preferences
	if(prefs.resurgence_traits)
		for(var/trait_type in prefs.resurgence_traits)
			var/datum/resurgence_trait/T = get_resurgence_trait(trait_type)
			if(T)
				selected_traits += trait_type
				points_used += T.point_cost

	var/points_remaining = TRAIT_POINT_POOL - points_used
	var/list/final_traits = assign_random_resurgence_traits(H, selected_traits, points_remaining)

	// Apply all traits
	for(var/trait_type in final_traits)
		var/datum/resurgence_trait/T = new trait_type()
		if(T.apply(H))
			core.applied_traits += T
		else
			qdel(T)

	// === STATS ===
	var/list/stat_allocation = prefs.resurgence_stat_points
	apply_resurgence_stat_allocation(core, stat_allocation)

	// === PASSIONS ===
	var/chosen_passion = prefs.resurgence_passion
	setup_resurgence_passions(core, chosen_passion)

/**
 * Apply a completely random build (no preferences available)
 *
 * Arguments:
 * * H - The human mob to personalize
 */
/proc/apply_random_resurgence_build(mob/living/carbon/human/H)
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return

	to_chat(H, span_notice("No character preferences found - generating random build..."))

	// Random traits (use full point pool)
	var/list/random_traits = assign_random_resurgence_traits(H, list(), TRAIT_POINT_POOL)
	for(var/trait_type in random_traits)
		var/datum/resurgence_trait/T = new trait_type()
		if(T.apply(H))
			core.applied_traits += T
		else
			qdel(T)

	// Random stats (all 10 points random)
	apply_resurgence_stat_allocation(core, null)

	// Random passion
	setup_resurgence_passions(core, null)

// ============================================
// Validation Procs
// ============================================

/**
 * Validate a trait selection
 *
 * Arguments:
 * * selected_traits - List of trait types
 *
 * Returns TRUE if valid, FALSE otherwise
 */
/proc/validate_resurgence_traits(list/selected_traits)
	if(!selected_traits)
		return TRUE  // Empty is valid

	var/total_cost = 0
	var/list/all_incompatible = list()

	for(var/trait_type in selected_traits)
		var/datum/resurgence_trait/T = get_resurgence_trait(trait_type)
		if(!T)
			return FALSE  // Invalid trait type

		// Check for incompatibilities
		if(trait_type in all_incompatible)
			return FALSE

		all_incompatible |= T.incompatible
		total_cost += T.point_cost

	// Check point budget (negative traits give points back)
	if(total_cost > TRAIT_POINT_POOL)
		return FALSE

	return TRUE

/**
 * Validate stat allocation
 *
 * Arguments:
 * * allocation - Associative list of stat -> points
 *
 * Returns TRUE if valid, FALSE otherwise
 */
/proc/validate_resurgence_stats(list/allocation)
	if(!allocation)
		return TRUE  // Empty is valid

	var/total_points = 0

	for(var/stat in allocation)
		if(!(stat in GLOB.resurgence_stat_types))
			return FALSE  // Invalid stat type

		var/points = allocation[stat]
		if(!isnum(points) || points < 0)
			return FALSE

		if(points > MAX_STARTING_STAT)
			return FALSE  // Too many points in one stat

		total_points += points

	if(total_points > STAT_POINT_POOL)
		return FALSE  // Over budget

	return TRUE

/**
 * Validate passion selection
 *
 * Arguments:
 * * passion - The chosen passion stat
 *
 * Returns TRUE if valid, FALSE otherwise
 */
/proc/validate_resurgence_passion(passion)
	if(!passion)
		return TRUE  // Empty is valid (will be randomly assigned)

	return passion in GLOB.resurgence_stat_types
