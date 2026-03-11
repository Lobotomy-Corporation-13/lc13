// Expedition System for Resurgence Outpost
// Handles travel between world map tiles with physical corridor traversal

// ============================================
// EXPEDITION STATE DEFINES
// ============================================

/// Party is forming at the signup console
#define EXPEDITION_FORMING "forming"
/// Party is departing from outpost
#define EXPEDITION_DEPARTING "departing"
/// Party is traveling through corridor
#define EXPEDITION_TRAVELING "traveling"
/// Party has arrived at destination
#define EXPEDITION_AT_DESTINATION "at_destination"
/// Party is returning to outpost
#define EXPEDITION_RETURNING "returning"
/// Expedition is complete
#define EXPEDITION_COMPLETE "complete"
/// Expedition failed (party wipe, etc.)
#define EXPEDITION_FAILED "failed"
/// Party stopped mid-travel (can plan new route from current position)
#define EXPEDITION_STOPPED "stopped"

// ============================================
// CORRIDOR CONFIGURATION
// ============================================

/// Corridor width in tiles
#define EXPEDITION_CORRIDOR_WIDTH 14
/// Corridor height in tiles
#define EXPEDITION_CORRIDOR_HEIGHT 80
/// Y position of event landmark (halfway)
#define EXPEDITION_EVENT_Y 40
/// Y position of end landmark
#define EXPEDITION_END_Y 80
/// Y position of start landmark
#define EXPEDITION_START_Y 1

/// Minimum percentage of party needed at end to trigger transition
#define EXPEDITION_TRANSITION_RATIO 0.5

/// Path to the corridor map file
#define EXPEDITION_CORRIDOR_MAP "_maps/map_files/Resurgence/travel_outskirts.dmm"
/// Name for the loaded corridor z-level
#define EXPEDITION_CORRIDOR_MAP_NAME "expedition_corridor"

// ============================================
// SCREEN FADE TIMING
// ============================================

/// Time for screen fade to black (deciseconds)
#define EXPEDITION_FADE_TIME 5
/// Time to wait at black before transitioning (deciseconds)
#define EXPEDITION_BLACK_TIME 2

// ============================================
// GLOBAL EXPEDITION MANAGER
// ============================================

/// The expedition corridor z-level (set when loaded)
GLOBAL_VAR(expedition_corridor_z)

/// Whether the corridor has been loaded
GLOBAL_VAR_INIT(expedition_corridor_loaded, FALSE)

/// The active expedition corridor manager
GLOBAL_DATUM(expedition_corridor, /datum/expedition_corridor_manager)

/// List of active expedition parties
GLOBAL_LIST_EMPTY(active_expeditions)

// ============================================
// CORRIDOR LOADING
// ============================================

/**
 * Load the expedition corridor z-level
 * Called when the world map is generated
 */
/proc/load_expedition_corridor()
	if(GLOB.expedition_corridor_loaded)
		return TRUE

	log_game("Attempting to load expedition corridor from: [EXPEDITION_CORRIDOR_MAP]")

	// Use the standard map loading helper proc
	load_new_z_level(EXPEDITION_CORRIDOR_MAP, EXPEDITION_CORRIDOR_MAP_NAME)

	// Find the z-level that was just loaded
	GLOB.expedition_corridor_z = world.maxz

	if(GLOB.expedition_corridor_z <= 0)
		log_game("WARNING: Failed to load expedition corridor z-level")
		return FALSE

	// Initialize the corridor manager after a short delay to let turfs initialize
	GLOB.expedition_corridor = new /datum/expedition_corridor_manager()
	addtimer(CALLBACK(GLOB.expedition_corridor, TYPE_PROC_REF(/datum/expedition_corridor_manager, initialize_corridor)), 1 SECONDS)

	GLOB.expedition_corridor_loaded = TRUE
	log_game("Expedition corridor loaded successfully on z-level [GLOB.expedition_corridor_z]")

	return TRUE

// ============================================
// TERRAIN SPEED MODIFIERS
// ============================================

GLOBAL_LIST_INIT(terrain_speed_modifiers, list(
	TERRAIN_PLAINS = 0,
	TERRAIN_FOREST = 0.3,
	TERRAIN_MOUNTAIN = 1.0,
	TERRAIN_DESERT = 0.5,
	TERRAIN_RUINS = 0.2,
	TERRAIN_SNOW = 0.4
))

// ============================================
// DECORATION TYPES PER TERRAIN
// ============================================

GLOBAL_LIST_INIT(expedition_decorations, list(
	TERRAIN_PLAINS = list(/obj/structure/flora/expedition/grass, /obj/structure/flora/expedition/rock_small),
	TERRAIN_FOREST = list(/obj/structure/flora/expedition/tree, /obj/structure/flora/expedition/bush),
	TERRAIN_MOUNTAIN = list(/obj/structure/flora/expedition/rock_large, /obj/structure/flora/expedition/boulder),
	TERRAIN_DESERT = list(/obj/structure/flora/expedition/cactus, /obj/structure/flora/expedition/dead_bush),
	TERRAIN_RUINS = list(/obj/structure/flora/expedition/pillar, /obj/structure/flora/expedition/debris),
	TERRAIN_SNOW = list(/obj/structure/flora/expedition/snowpile, /obj/structure/flora/expedition/ice_rock, /obj/structure/flora/expedition/frozen_shrub)
))
