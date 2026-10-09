/**
 * Resurgence Outpost - Raid System
 *
 * Global definitions and manager for the faction raid system.
 * Factions with low reputation will send raiders to attack the outpost.
 */

// ==================== Raid Type Defines ====================

/// Delayed raid - spawn, wait 2-3 minutes at spawn point, then assault
#define RAID_TYPE_DELAYED "delayed"

/// Basic raid - spawn and immediately pathfind to targets
#define RAID_TYPE_BASIC "basic"

/// Pillage raid - steal items and retreat
#define RAID_TYPE_PILLAGE "pillage"

/// Siege raid - focus on destroying structures
#define RAID_TYPE_SIEGE "siege"

/// Assassination raid - target specific players
#define RAID_TYPE_ASSASSINATION "assassination"

/// Overwhelming force - large numbers of weak units
#define RAID_TYPE_OVERWHELMING "overwhelming"

// ==================== Raid State Defines ====================

/// Raid is pending start (waiting for delay/cooldown)
#define RAID_STATE_PENDING 0

/// Raid is currently spawning raiders
#define RAID_STATE_SPAWNING 1

/// Raid is waiting at spawn point (for delayed raids)
#define RAID_STATE_WAITING 2

/// Raid is actively in progress
#define RAID_STATE_ACTIVE 3

/// Raiders are retreating
#define RAID_STATE_RETREATING 4

/// Raid has completed
#define RAID_STATE_COMPLETE 5

// ==================== Raid Thresholds ====================

/// Reputation below this triggers raid chance
#define RAID_REPUTATION_THRESHOLD 20

/// Base chance per subsystem tick when reputation is below threshold (0-100)
#define RAID_BASE_CHANCE 5

/// Minimum cooldown between raids (in deciseconds)
#define RAID_MINIMUM_COOLDOWN (30 MINUTES)

/// Warning time before raid spawns (in deciseconds)
#define RAID_WARNING_TIME (1 MINUTES)

/// Time for delayed raids to wait at spawn before attacking
#define RAID_DELAYED_WAIT_TIME (2 MINUTES)

/// Retreat threshold - if this percentage of raiders die, they retreat
#define RAID_RETREAT_THRESHOLD 0.75

// ==================== Global Lists ====================

/// All raid spawn point landmarks
GLOBAL_LIST_EMPTY(raid_spawn_points)

/// Priority weights for room types (higher = more likely target)
GLOBAL_LIST_INIT(raid_room_priorities, list(
	ROOM_TYPE_STORAGE = 10,
	ROOM_TYPE_EXPORT_WAREHOUSE = 9,
	ROOM_TYPE_WORKSHOP = 7,
	ROOM_TYPE_KITCHEN = 6,
	ROOM_TYPE_COMMON = 5,
	ROOM_TYPE_LIVING_QUARTERS = 4,
	ROOM_TYPE_BARRACKS = 4,
	ROOM_TYPE_BASIC = 3
))

/// Raid type specific room preferences
GLOBAL_LIST_INIT(raid_type_room_preferences, list(
	RAID_TYPE_PILLAGE = list(ROOM_TYPE_STORAGE, ROOM_TYPE_EXPORT_WAREHOUSE, ROOM_TYPE_WORKSHOP),
	RAID_TYPE_SIEGE = list(ROOM_TYPE_WORKSHOP, ROOM_TYPE_KITCHEN, ROOM_TYPE_STORAGE),
	RAID_TYPE_ASSASSINATION = list(ROOM_TYPE_LIVING_QUARTERS, ROOM_TYPE_BARRACKS, ROOM_TYPE_COMMON),
	RAID_TYPE_BASIC = list()
))

// ==================== Raid Tier Defines ====================

/// Tier numbers for raid difficulty scaling
#define RAID_TIER_MILITIA 1
#define RAID_TIER_REGULAR 2
#define RAID_TIER_VETERAN 3
#define RAID_TIER_ELITE 4

/// Round time thresholds for tier transitions
#define RAID_REGULAR_THRESHOLD (45 MINUTES)
#define RAID_VETERAN_THRESHOLD (60 MINUTES)
#define RAID_ELITE_THRESHOLD (120 MINUTES)

/// Early-game (militia) raid compositions — melee only, no ranged units
GLOBAL_LIST_INIT(insurgence_raid_compositions_early, list(
	RAID_TYPE_BASIC = list(
		/mob/living/simple_animal/hostile/clan/raider/scout/militia = 4,
		/mob/living/simple_animal/hostile/clan/raider/defender/militia = 1
	),
	RAID_TYPE_PILLAGE = list(
		/mob/living/simple_animal/hostile/clan/raider/scout/pillager/militia = 4,
		/mob/living/simple_animal/hostile/clan/raider/defender/militia = 2
	),
	RAID_TYPE_SIEGE = list(
		/mob/living/simple_animal/hostile/clan/raider/defender/militia = 3,
		/mob/living/simple_animal/hostile/clan/raider/scout/militia = 3
	),
	RAID_TYPE_ASSASSINATION = list(
		/mob/living/simple_animal/hostile/clan/raider/scout/militia = 4
	),
	RAID_TYPE_OVERWHELMING = list(
		/mob/living/simple_animal/hostile/clan/raider/scout/militia = 8
	)
))

/// Insurgence Clan raid compositions by raid type
/// Uses raider variants with stealing/trampling/looting abilities
/// Ranged units use normal clan mobs (they provide cover fire, not looting)
GLOBAL_LIST_INIT(insurgence_raid_compositions, list(
	RAID_TYPE_BASIC = list(
		/mob/living/simple_animal/hostile/clan/raider/scout = 3,
		/mob/living/simple_animal/hostile/clan/raider/defender = 1,
		/mob/living/simple_animal/hostile/clan/ranged/rapid = 1
	),
	RAID_TYPE_PILLAGE = list(
		/mob/living/simple_animal/hostile/clan/raider/scout/pillager = 4,
		/mob/living/simple_animal/hostile/clan/raider/defender = 2
	),
	RAID_TYPE_SIEGE = list(
		/mob/living/simple_animal/hostile/clan/raider/defender = 2,
		/mob/living/simple_animal/hostile/clan/raider/scout = 2,
		/mob/living/simple_animal/hostile/clan/ranged/gunner = 2
	),
	RAID_TYPE_ASSASSINATION = list(
		/mob/living/simple_animal/hostile/clan/raider/scout = 2,
		/mob/living/simple_animal/hostile/clan/ranged/sniper = 1,
		/mob/living/simple_animal/hostile/clan/ranged/harpooner = 1
	),
	RAID_TYPE_OVERWHELMING = list(
		/mob/living/simple_animal/hostile/clan/raider/scout = 5,
		/mob/living/simple_animal/hostile/clan/ranged/rapid = 3
	)
))

/// Veteran raid compositions — stronger units for raids after 60 minutes
GLOBAL_LIST_INIT(insurgence_raid_compositions_veteran, list(
	RAID_TYPE_BASIC = list(
		/mob/living/simple_animal/hostile/clan/raider/scout/veteran = 3,
		/mob/living/simple_animal/hostile/clan/raider/defender/veteran = 1,
		/mob/living/simple_animal/hostile/clan/ranged/rapid/veteran = 1,
		/mob/living/simple_animal/hostile/clan/ranged/gunner/veteran = 1
	),
	RAID_TYPE_PILLAGE = list(
		/mob/living/simple_animal/hostile/clan/raider/scout/pillager/veteran = 4,
		/mob/living/simple_animal/hostile/clan/raider/defender/veteran = 2
	),
	RAID_TYPE_SIEGE = list(
		/mob/living/simple_animal/hostile/clan/raider/defender/veteran = 2,
		/mob/living/simple_animal/hostile/clan/raider/scout/veteran = 2,
		/mob/living/simple_animal/hostile/clan/ranged/gunner/veteran = 2
	),
	RAID_TYPE_ASSASSINATION = list(
		/mob/living/simple_animal/hostile/clan/raider/scout/veteran = 2,
		/mob/living/simple_animal/hostile/clan/ranged/sniper/veteran = 1,
		/mob/living/simple_animal/hostile/clan/ranged/harpooner/veteran = 1
	),
	RAID_TYPE_OVERWHELMING = list(
		/mob/living/simple_animal/hostile/clan/raider/scout/veteran = 5,
		/mob/living/simple_animal/hostile/clan/ranged/rapid/veteran = 3
	)
))

/// Elite raid compositions — endgame units for raids after 90 minutes
GLOBAL_LIST_INIT(insurgence_raid_compositions_elite, list(
	RAID_TYPE_BASIC = list(
		/mob/living/simple_animal/hostile/clan/raider/scout/elite = 3,
		/mob/living/simple_animal/hostile/clan/raider/defender/elite = 1,
		/mob/living/simple_animal/hostile/clan/ranged/rapid/elite = 1,
		/mob/living/simple_animal/hostile/clan/ranged/gunner/elite = 1
	),
	RAID_TYPE_PILLAGE = list(
		/mob/living/simple_animal/hostile/clan/raider/scout/pillager/elite = 4,
		/mob/living/simple_animal/hostile/clan/raider/defender/elite = 2,
		/mob/living/simple_animal/hostile/clan/ranged/warper/elite = 1
	),
	RAID_TYPE_SIEGE = list(
		/mob/living/simple_animal/hostile/clan/raider/defender/elite = 2,
		/mob/living/simple_animal/hostile/clan/ranged/gunner/elite = 2,
		/mob/living/simple_animal/hostile/clan/ranged/sniper/elite = 1,
		/mob/living/simple_animal/hostile/clan/ranged/warper/elite = 1
	),
	RAID_TYPE_ASSASSINATION = list(
		/mob/living/simple_animal/hostile/clan/raider/scout/elite = 2,
		/mob/living/simple_animal/hostile/clan/ranged/sniper/elite = 1,
		/mob/living/simple_animal/hostile/clan/ranged/harpooner/elite = 1,
		/mob/living/simple_animal/hostile/clan/ranged/warper/elite = 1
	),
	RAID_TYPE_OVERWHELMING = list(
		/mob/living/simple_animal/hostile/clan/raider/scout/elite = 6,
		/mob/living/simple_animal/hostile/clan/ranged/rapid/elite = 3,
		/mob/living/simple_animal/hostile/clan/ranged/gunner/elite = 1
	)
))

// ==================== Raid Caravan System ====================

/// Whether the raid caravan system is enabled (hostile caravans travel to outpost)
#define RAID_USE_CARAVAN_SYSTEM TRUE

/// Time for raid caravan to move between world map tiles (in deciseconds)
#define RAID_CARAVAN_MOVE_DELAY (3 MINUTES)

/// Display color for raid caravans on world map (dark red)
#define RAID_CARAVAN_DISPLAY_COLOR "#990000"

/// Active raid caravans traveling toward the outpost
GLOBAL_LIST_EMPTY(active_raid_caravans)

/// Raid intercept encounter map path
#define RAID_INTERCEPT_MAP "_maps/map_files/Resurgence/raid_intercept.dmm"
#define RAID_INTERCEPT_MAP_NAME "raid_intercept"

/// Whether the raid intercept map has been loaded
GLOBAL_VAR_INIT(raid_intercept_loaded, FALSE)

/// Z-level of the raid intercept map
GLOBAL_VAR(raid_intercept_z)

/// Current raid intercept controller (if an intercept is in progress)
GLOBAL_VAR(raid_intercept_controller)

/// List of floor turfs in the raid intercept map
GLOBAL_LIST_EMPTY(raid_intercept_floor_turfs)

/// List of edge turfs in the raid intercept map (spawn decorations)
GLOBAL_LIST_EMPTY(raid_intercept_edge_turfs)
