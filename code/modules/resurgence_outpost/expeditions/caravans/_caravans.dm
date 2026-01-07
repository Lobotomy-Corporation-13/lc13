// Caravan System for Resurgence Outpost
// Factions send caravans across the world map for trading opportunities

// ============================================
// CARAVAN STATE DEFINES
// ============================================

/// Caravan is traveling on the world map
#define CARAVAN_TRAVELING "traveling"
/// Caravan is stopped (encountered by players)
#define CARAVAN_STOPPED "stopped"
/// Caravan is at a destination (faction hub, outpost, etc.)
#define CARAVAN_AT_DESTINATION "at_destination"
/// Caravan has been destroyed (attacked and defeated)
#define CARAVAN_DESTROYED "destroyed"
/// Caravan has completed its journey and despawned
#define CARAVAN_COMPLETE "complete"

// ============================================
// CARAVAN CONFIGURATION
// ============================================

/// Chance per faction per tick to spawn a caravan (percent)
#define CARAVAN_SPAWN_CHANCE 10
/// Insurgence patrol spawn chance (higher than normal)
#define CARAVAN_PATROL_SPAWN_CHANCE 15
/// Maximum caravans per trading faction
#define CARAVAN_MAX_PER_FACTION 1
/// Maximum Insurgence patrols
#define CARAVAN_MAX_PATROLS 2
/// Movement delay between tiles (deciseconds) - 3 minutes
#define CARAVAN_MOVE_DELAY 180 SECONDS
/// Caravan despawn time after reaching destination (deciseconds)
#define CARAVAN_DESPAWN_DELAY 300 SECONDS

// ============================================
// CARAVAN ENCOUNTER CONFIGURATION
// ============================================

/// Path to the caravan encounter map file
#define CARAVAN_ENCOUNTER_MAP "_maps/map_files/Resurgence/caravan_encounter.dmm"
/// Name for the loaded caravan encounter z-level
#define CARAVAN_ENCOUNTER_MAP_NAME "caravan_encounter"

// ============================================
// CARAVAN GUARD STRENGTH
// ============================================

GLOBAL_LIST_INIT(caravan_guard_counts, list(
	"resurgence_clan" = 2,
	"jiajia_ren" = 3,
	"santata_factory" = 4,
	"cloud_town" = 3,
	"insurgence_clan" = 5
))

// ============================================
// GLOBAL CARAVAN DATA
// ============================================

/// List of all active caravans
GLOBAL_LIST_EMPTY(active_caravans)

/// The caravan manager singleton
GLOBAL_DATUM(caravan_manager, /datum/caravan_manager)

/// Whether caravan encounter z-level is loaded
GLOBAL_VAR_INIT(caravan_encounter_loaded, FALSE)

/// The caravan encounter z-level
GLOBAL_VAR(caravan_encounter_z)

/// The current caravan being encountered (if any)
GLOBAL_DATUM(current_caravan_encounter, /datum/faction_caravan)

// ============================================
// CARAVAN ENCOUNTER LOADING
// ============================================

/**
 * Load the caravan encounter z-level
 */
/proc/load_caravan_encounter()
	if(GLOB.caravan_encounter_loaded)
		return TRUE

	log_game("Attempting to load caravan encounter from: [CARAVAN_ENCOUNTER_MAP]")

	// Use the standard map loading helper proc
	load_new_z_level(CARAVAN_ENCOUNTER_MAP, CARAVAN_ENCOUNTER_MAP_NAME)

	// Find the z-level that was just loaded
	GLOB.caravan_encounter_z = world.maxz

	if(GLOB.caravan_encounter_z <= 0)
		log_game("WARNING: Failed to load caravan encounter z-level")
		return FALSE

	GLOB.caravan_encounter_loaded = TRUE
	log_game("Caravan encounter loaded successfully on z-level [GLOB.caravan_encounter_z]")

	return TRUE

// ============================================
// CARAVAN REPUTATION CHANGES
// ============================================

/// Reputation loss for attacking a caravan
#define CARAVAN_ATTACK_REP_LOSS -20
/// Reputation loss with other factions for attacking
#define CARAVAN_ATTACK_REP_LOSS_OTHER -5
/// Reputation loss for failing to steal
#define CARAVAN_STEAL_FAIL_REP_LOSS -10
/// Reputation gain for successful trade
#define CARAVAN_TRADE_REP_GAIN 2
