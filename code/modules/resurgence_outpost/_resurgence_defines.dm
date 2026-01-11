/**
 * Resurgence Outpost - Central Defines
 *
 * This file must be included FIRST in the resurgence_outpost module.
 * Contains all defines needed by other files in this module.
 */

// ============================================
// TERRAIN TYPE DEFINES (from world_map)
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
/// Snow - Cold terrain, moderate difficulty
#define TERRAIN_SNOW "snow"
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
// DISCOVERY SETTINGS
// ============================================

/// Radius of tiles revealed when visiting a location
#define VISIT_DISCOVERY_RADIUS 1

// ============================================
// ROOM TYPE DEFINES
// ============================================

/// Maximum size of a designatable room in tiles
#define ROOM_MAX_SIZE 100

/// Room cramped thresholds
#define ROOM_MIN_TILES 9
#define ROOM_MIN_DIMENSION 3

/// Room type defines
#define ROOM_TYPE_BASIC           "Basic Room"
#define ROOM_TYPE_WORKSHOP        "Workshop"
#define ROOM_TYPE_COMMON          "Common Room"
#define ROOM_TYPE_STORAGE         "Storage Room"
#define ROOM_TYPE_KITCHEN         "Kitchen"
#define ROOM_TYPE_LIVING_QUARTERS "Living Quarters"
#define ROOM_TYPE_EXPORT_WAREHOUSE "Export Warehouse"
#define ROOM_TYPE_BARRACKS        "Barracks"

// ============================================
// STAT DEFINES
// ============================================

/// Maximum level for character stats
#define STAT_MAX_LEVEL 20

// ============================================
// GATHERING DEFINES
// ============================================

/// Minimum faith required to perform gathering work
#define MIN_FAITH_FOR_WORK 5

/// Faith drained per work point during gathering
#define FAITH_DRAIN_PER_WORK 0.05

/// Work points added per 1-second gathering tick (base rate)
#define GATHER_WORK_PER_TICK 2

/// Time per gathering tick in deciseconds
#define GATHER_TICK_TIME 2 SECONDS

// ============================================
// EVENT DEFINES
// ============================================

/// Event categories
#define EVENT_CATEGORY_HAZARD "hazard"
#define EVENT_CATEGORY_SCAVENGE "scavenge"
#define EVENT_CATEGORY_ENCOUNTER "encounter"

/// Event skill checks
#define EVENT_SKILL_MINING "mining"
#define EVENT_SKILL_CRAFTING "crafting"
#define EVENT_SKILL_COOKING "cooking"
#define EVENT_SKILL_HARVESTING "harvesting"
#define EVENT_SKILL_ANALYSIS "analysis"
#define EVENT_SKILL_SOCIAL "social"

// ============================================
// QUALITY TIER DEFINES (from tool_durability)
// ============================================

/// Tool quality tier constants
#define QUALITY_TIER_SHODDY 1
#define QUALITY_TIER_COMMON 2
#define QUALITY_TIER_QUALITY 3
#define QUALITY_TIER_EXCELLENT 4
#define QUALITY_TIER_MASTERWORK 5

// ============================================
// GRID CRAFTING DEFINES (from ore_cores)
// ============================================

/// Core movement types
#define CORE_MOVEMENT_CARDINAL 1   // N/S/E/W (Iron)
#define CORE_MOVEMENT_DIAGONAL 2   // NE/NW/SE/SW (Silver)
#define CORE_MOVEMENT_OCTAGONAL 3  // All 8 directions (Alloy)
#define CORE_MOVEMENT_TELEPORT 4   // Any point within range (Gold)
