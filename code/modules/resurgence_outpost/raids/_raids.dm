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
#define RAID_BASE_CHANCE 15

/// Minimum cooldown between raids (in deciseconds)
#define RAID_MINIMUM_COOLDOWN (10 MINUTES)

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
