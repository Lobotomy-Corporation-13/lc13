/**
 * Resurgence Character Personalization System
 *
 * Defines and globals for the trait, passion, and starting stat systems.
 * Inspired by Rimworld's trait/passion systems.
 */

// ============================================
// Point Pool Defines
// ============================================

/// Number of trait points players can spend on positive traits
#define TRAIT_POINT_POOL 4

/// Number of stat points players can allocate manually
#define STAT_POINT_POOL 6

/// Maximum levels a player can put into a single stat via menu
#define MAX_STARTING_STAT 4

/// Maximum total levels a single stat can have at spawn (menu + random)
#define MAX_TOTAL_STARTING_STAT 6

/// Number of random stat levels added at spawn
#define RANDOM_STAT_BONUS 4

/// Number of random traits if none selected
#define RANDOM_TRAIT_COUNT 2

/// Number of additional random passions at spawn
#define RANDOM_PASSION_COUNT 2

/// Total stat points (player choice + random)
#define TOTAL_STAT_POINTS 10

// ============================================
// Passion Level Defines
// ============================================

/// No passion for this stat
#define PASSION_NONE 0

/// Interested - 50% XP bonus
#define PASSION_INTERESTED 1

/// Passionate (Very Passionate) - 100% XP bonus
#define PASSION_PASSIONATE 2

// ============================================
// Global Lists
// ============================================

/// List of all stat types in the game
GLOBAL_LIST_INIT(resurgence_stat_types, list(
	"crafting",
	"mining",
	"harvesting",
	"cooking",
	"analysis",
	"social"
))

/// List of all available trait types (populated at runtime)
GLOBAL_LIST_EMPTY(resurgence_trait_types)

/// Cache of trait instances for UI display
GLOBAL_LIST_EMPTY(resurgence_trait_cache)

// ============================================
// Passions Datum
// ============================================

/**
 * Stores passion information for a resurgence machine
 */
/datum/resurgence_passions
	/// The stat the player chose to be passionate about
	var/chosen_passion = null
	/// List of randomly assigned passions
	var/list/random_passions = list()
	/// Cached passion levels per stat (PASSION_NONE, PASSION_INTERESTED, PASSION_PASSIONATE)
	var/list/passion_levels = list()

/**
 * Get the XP multiplier for a specific stat based on passions
 *
 * Arguments:
 * * stat_type - The stat to check ("crafting", "mining", etc.)
 *
 * Returns:
 * * 1.0 for no passion
 * * 1.5 for interested (50% bonus)
 * * 2.0 for passionate (100% bonus)
 */
/datum/resurgence_passions/proc/get_xp_multiplier(stat_type)
	if(!passion_levels || !passion_levels[stat_type])
		return 1.0

	switch(passion_levels[stat_type])
		if(PASSION_INTERESTED)
			return 1.5
		if(PASSION_PASSIONATE)
			return 2.0
	return 1.0

/**
 * Get the passion level for a stat (for UI display)
 */
/datum/resurgence_passions/proc/get_passion_level(stat_type)
	if(!passion_levels || !passion_levels[stat_type])
		return PASSION_NONE
	return passion_levels[stat_type]

/**
 * Check if a stat has any passion
 */
/datum/resurgence_passions/proc/has_passion(stat_type)
	return get_passion_level(stat_type) > PASSION_NONE

// ============================================
// Helper Procs
// ============================================

/**
 * Initialize the trait cache with all available traits
 * Called once at world startup
 */
/proc/init_resurgence_traits()
	if(length(GLOB.resurgence_trait_cache))
		return  // Already initialized

	for(var/trait_type in subtypesof(/datum/resurgence_trait))
		var/datum/resurgence_trait/T = new trait_type()
		if(T.name == "Unnamed" || T.abstract_type)
			qdel(T)
			continue
		GLOB.resurgence_trait_types += trait_type
		GLOB.resurgence_trait_cache[trait_type] = T

/**
 * Get a cached trait instance by type
 */
/proc/get_resurgence_trait(trait_type)
	if(!length(GLOB.resurgence_trait_cache))
		init_resurgence_traits()
	return GLOB.resurgence_trait_cache[trait_type]

/**
 * Get all positive traits (sorted by cost)
 */
/proc/get_positive_resurgence_traits()
	if(!length(GLOB.resurgence_trait_cache))
		init_resurgence_traits()

	var/list/positive = list()
	for(var/trait_type in GLOB.resurgence_trait_cache)
		var/datum/resurgence_trait/T = GLOB.resurgence_trait_cache[trait_type]
		if(T.point_cost > 0)
			positive += T
	return positive

/**
 * Get all negative traits (sorted by cost)
 */
/proc/get_negative_resurgence_traits()
	if(!length(GLOB.resurgence_trait_cache))
		init_resurgence_traits()

	var/list/negative = list()
	for(var/trait_type in GLOB.resurgence_trait_cache)
		var/datum/resurgence_trait/T = GLOB.resurgence_trait_cache[trait_type]
		if(T.point_cost < 0)
			negative += T
	return negative

/**
 * Get mixed traits (trade-off traits)
 */
/proc/get_mixed_resurgence_traits()
	if(!length(GLOB.resurgence_trait_cache))
		init_resurgence_traits()

	var/list/mixed = list()
	for(var/trait_type in GLOB.resurgence_trait_cache)
		var/datum/resurgence_trait/T = GLOB.resurgence_trait_cache[trait_type]
		if(T.is_mixed)
			mixed += T
	return mixed
