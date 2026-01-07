// World Map System for Resurgence Outpost
// Provides a grid-based world map with terrain, factions, and expedition planning

// ============================================
// TERRAIN TYPE DEFINES
// ============================================

/// Plains - Default terrain, easy to traverse
#define TERRAIN_PLAINS "plains"
/// Forest - Moderate difficulty, more events
#define TERRAIN_FOREST "forest"
/// Mountain - Hard to traverse, fewer events
#define TERRAIN_MOUNTAIN "mountain"
/// Desert - Moderate difficulty, standard events
#define TERRAIN_DESERT "desert"
/// Ruins - Easy to traverse, many events (scavenging)
#define TERRAIN_RUINS "ruins"
/// Outpost - Player's home base
#define TERRAIN_OUTPOST "outpost"
/// Faction - Trading faction location
#define TERRAIN_FACTION "faction"

// ============================================
// MAP CONFIGURATION
// ============================================

/// World map width in tiles
#define WORLD_MAP_WIDTH 15
/// World map height in tiles
#define WORLD_MAP_HEIGHT 15
/// Center X coordinate (outpost location)
#define WORLD_MAP_CENTER_X 8
/// Center Y coordinate (outpost location)
#define WORLD_MAP_CENTER_Y 8

// ============================================
// FACTION PLACEMENT CONSTRAINTS
// ============================================

/// Minimum distance from outpost for faction placement
#define FACTION_MIN_DIST_FROM_OUTPOST 3
/// Maximum distance from outpost for faction placement
#define FACTION_MAX_DIST_FROM_OUTPOST 6
/// Minimum distance between factions
#define FACTION_MIN_DIST_BETWEEN 3

// ============================================
// DISCOVERY SETTINGS
// ============================================

/// Initial discovery radius around outpost
#define INITIAL_DISCOVERY_RADIUS 2
/// Discovery radius when visiting a tile
#define VISIT_DISCOVERY_RADIUS 1

// ============================================
// TERRAIN PROPERTIES
// Associative lists for terrain configuration
// ============================================

GLOBAL_LIST_INIT(terrain_travel_costs, list(
	TERRAIN_PLAINS = 1.0,
	TERRAIN_FOREST = 1.3,
	TERRAIN_MOUNTAIN = 2.0,
	TERRAIN_DESERT = 1.5,
	TERRAIN_RUINS = 1.2,
	TERRAIN_OUTPOST = 0,
	TERRAIN_FACTION = 0
))

GLOBAL_LIST_INIT(terrain_event_modifiers, list(
	TERRAIN_PLAINS = 1.0,
	TERRAIN_FOREST = 1.2,
	TERRAIN_MOUNTAIN = 0.8,
	TERRAIN_DESERT = 1.0,
	TERRAIN_RUINS = 2.0,
	TERRAIN_OUTPOST = 0,
	TERRAIN_FACTION = 0
))

GLOBAL_LIST_INIT(terrain_colors, list(
	TERRAIN_PLAINS = "#4a7c3f",
	TERRAIN_FOREST = "#2d5a27",
	TERRAIN_MOUNTAIN = "#8b8b8b",
	TERRAIN_DESERT = "#c2b280",
	TERRAIN_RUINS = "#6b5b4f",
	TERRAIN_OUTPOST = "#3366cc",
	TERRAIN_FACTION = "#cc9933"
))

GLOBAL_LIST_INIT(terrain_names, list(
	TERRAIN_PLAINS = "Plains",
	TERRAIN_FOREST = "Forest",
	TERRAIN_MOUNTAIN = "Mountains",
	TERRAIN_DESERT = "Desert",
	TERRAIN_RUINS = "Ruins",
	TERRAIN_OUTPOST = "Outpost",
	TERRAIN_FACTION = "Settlement"
))

GLOBAL_LIST_INIT(terrain_descriptions, list(
	TERRAIN_PLAINS = "Open grasslands with few obstacles. Easy to traverse.",
	TERRAIN_FOREST = "Dense woodland with winding paths. Moderate difficulty.",
	TERRAIN_MOUNTAIN = "Rocky highlands with steep terrain. Difficult to cross.",
	TERRAIN_DESERT = "Arid wasteland with scorching heat. Moderate difficulty.",
	TERRAIN_RUINS = "Crumbling structures from a forgotten era. Rich in salvage.",
	TERRAIN_OUTPOST = "Your home base. Safety and supplies await.",
	TERRAIN_FACTION = "A faction settlement. Trade and diplomacy opportunities."
))

// ============================================
// GLOBAL WORLD MAP MANAGER
// ============================================

GLOBAL_DATUM(resurgence_world_map, /datum/world_map_manager)

/// List of all world map consoles for UI updates
GLOBAL_LIST_EMPTY(world_map_consoles)

/// Initialize the world map manager - call this during game setup
/proc/init_resurgence_world_map()
	if(!GLOB.resurgence_world_map)
		GLOB.resurgence_world_map = new /datum/world_map_manager()
		GLOB.resurgence_world_map.generate_world()
	return GLOB.resurgence_world_map
