/**
 * Grid Crafting System - Defines
 *
 * Constants for the enkephalin-based grid crafting system.
 * Movement types, template grades, and balance values.
 */

// ===== Movement Type Constants =====
// Each sin produces a unique movement pattern

/// Wrath - Straight line in cardinal direction (N/S/E/W), cannot stop early
#define CORE_MOVEMENT_CHARGE   1
/// Lust - Automatically moves toward nearest weapon point
#define CORE_MOVEMENT_ATTRACT  2
/// Sloth - Small random movement in random direction
#define CORE_MOVEMENT_SHUFFLE  3
/// Gluttony - Moves in any of 8 directions (octagonal)
#define CORE_MOVEMENT_EXPAND   4
/// Gloom - Curved/wandering path, direction influenced but not precise
#define CORE_MOVEMENT_DRIFT    5
/// Pride - Direct jump to any chosen point within range
#define CORE_MOVEMENT_TELEPORT 6
/// Envy - Copies and inverts the previous movement
#define CORE_MOVEMENT_MIRROR   7

// ===== Template Grade Constants =====

#define TEMPLATE_GRADE_BASIC    1
#define TEMPLATE_GRADE_STANDARD 2
#define TEMPLATE_GRADE_QUALITY  3
#define TEMPLATE_GRADE_SUPERIOR 4

// ===== Template Costs (Ahn) =====

#define TEMPLATE_COST_BASIC    50
#define TEMPLATE_COST_STANDARD 150
#define TEMPLATE_COST_QUALITY  400
#define TEMPLATE_COST_SUPERIOR 1000

// ===== Template Distance Ranges =====

#define TEMPLATE_DIST_BASIC_MIN    5
#define TEMPLATE_DIST_BASIC_MAX    15
#define TEMPLATE_DIST_STANDARD_MIN 10
#define TEMPLATE_DIST_STANDARD_MAX 25
#define TEMPLATE_DIST_QUALITY_MIN  25
#define TEMPLATE_DIST_QUALITY_MAX  35
#define TEMPLATE_DIST_SUPERIOR_MIN 35
#define TEMPLATE_DIST_SUPERIOR_MAX 45

// ===== Template Max Tiers =====

#define TEMPLATE_MAX_TIER_BASIC    1
#define TEMPLATE_MAX_TIER_STANDARD 2
#define TEMPLATE_MAX_TIER_QUALITY  3
#define TEMPLATE_MAX_TIER_SUPERIOR 4

// ===== Chem Quantity Thresholds =====

/// Minimum chem amount to create a core (results in -50% distance)
#define CHEM_QUANTITY_MIN 5
/// Optimal chem amount (100% distance)
#define CHEM_QUANTITY_OPTIMAL 15
/// Maximum effective chem amount (+50% distance)
#define CHEM_QUANTITY_MAX 25

// ===== Diminishing Returns =====

/// Penalty per consecutive same-type use (15%)
#define DIMINISHING_PENALTY_PER_USE 0.15
/// Maximum diminishing penalty (75%)
#define DIMINISHING_MAX_PENALTY 0.75
/// Maximum consecutive uses tracked
#define DIMINISHING_MAX_STACK 6

// ===== Shuffle System =====

/// Minimum crafts before shuffle
#define SHUFFLE_THRESHOLD_MIN 8
/// Maximum crafts before shuffle
#define SHUFFLE_THRESHOLD_MAX 15

/// Shuffle points added per tier
#define SHUFFLE_POINTS_TIER_0 1
#define SHUFFLE_POINTS_TIER_1 2
#define SHUFFLE_POINTS_TIER_2 3
#define SHUFFLE_POINTS_TIER_3 5
/// Tier 4 causes immediate shuffle (use -1 as flag)
#define SHUFFLE_POINTS_TIER_4 -1

// ===== Weapon Tier Distances (Ahn-Cost Balanced) =====

// Tier 0: 2-4 Basic cores (100-200 Ahn expected)
#define WEAPON_DIST_TIER_0_MIN 20
#define WEAPON_DIST_TIER_0_MAX 40
#define WEAPON_RADIUS_TIER_0_MIN 8
#define WEAPON_RADIUS_TIER_0_MAX 12

// Tier 1: 2-4 Standard cores (300-600 Ahn expected)
#define WEAPON_DIST_TIER_1_MIN 40
#define WEAPON_DIST_TIER_1_MAX 80
#define WEAPON_RADIUS_TIER_1_MIN 6
#define WEAPON_RADIUS_TIER_1_MAX 10

// Tier 2: 2-4 Quality cores (800-1600 Ahn expected)
#define WEAPON_DIST_TIER_2_MIN 60
#define WEAPON_DIST_TIER_2_MAX 120
#define WEAPON_RADIUS_TIER_2_MIN 5
#define WEAPON_RADIUS_TIER_2_MAX 8

// Tier 3: 5-10 Quality/Superior cores (2000-4000 Ahn expected)
#define WEAPON_DIST_TIER_3_MIN 140
#define WEAPON_DIST_TIER_3_MAX 280
#define WEAPON_RADIUS_TIER_3_MIN 4
#define WEAPON_RADIUS_TIER_3_MAX 7

// Tier 4: 6-12 Superior cores (6000-12000 Ahn expected)
#define WEAPON_DIST_TIER_4_MIN 300
#define WEAPON_DIST_TIER_4_MAX 550
#define WEAPON_RADIUS_TIER_4_MIN 3
#define WEAPON_RADIUS_TIER_4_MAX 6

// ===== Ordeal Tier Unlocking =====
// Completing ordeals globally unlocks weapon tiers for all grid stations

/// Global tier unlocked by completing ordeals (Dawn=1, Noon=2, Dusk=3, Midnight=4)
GLOBAL_VAR_INIT(grid_craft_ordeal_tier, 0)

/// Whether the ordeal tier system has been initialized
GLOBAL_VAR_INIT(grid_craft_ordeal_initialized, FALSE)

// ===== Movement Distance Modifiers =====
// More accurate movements travel shorter distances

/// Charge (Wrath) - Baseline
#define MOVEMENT_MOD_CHARGE   1.0
/// Attract (Lust) - High accuracy, -20%
#define MOVEMENT_MOD_ATTRACT  0.8
/// Shuffle (Sloth) - Lowest accuracy, +75%
#define MOVEMENT_MOD_SHUFFLE  1.75
/// Expand (Gluttony) - Medium-high accuracy, -25%
#define MOVEMENT_MOD_EXPAND   0.75
/// Drift (Gloom) - Low accuracy, +20%
#define MOVEMENT_MOD_DRIFT    1.2
/// Teleport (Pride) - Highest accuracy, -50%
#define MOVEMENT_MOD_TELEPORT 0.5
/// Mirror (Envy) - Medium accuracy, +10%
#define MOVEMENT_MOD_MIRROR   1.1

// ===== Grid Zone Types =====

#define GRID_ZONE_TAILWIND   1
#define GRID_ZONE_DRAG       2
#define GRID_ZONE_RESONANCE  3
#define GRID_ZONE_EXCLUSION  4

// ===== Grid Zone Balance =====

#define GRID_ZONE_COUNT_MIN  12
#define GRID_ZONE_COUNT_MAX  18

/// Each cell is 10x10 grid units
#define GRID_ZONE_CELL_SIZE  10
/// Cells per zone (blob size)
#define GRID_ZONE_CELLS_MIN  10
#define GRID_ZONE_CELLS_MAX  20

/// Zone center placement distance from origin
#define GRID_ZONE_DIST_MIN   30
#define GRID_ZONE_DIST_MAX   350

/// Tailwind zone distance multiplier
#define GRID_ZONE_TAILWIND_MULT  1.5
/// Drag zone distance multiplier
#define GRID_ZONE_DRAG_MULT      0.5

/// Exclusion zone blocked movement type count
#define GRID_ZONE_EXCLUSION_BLOCK_MIN 2
#define GRID_ZONE_EXCLUSION_BLOCK_MAX 3
