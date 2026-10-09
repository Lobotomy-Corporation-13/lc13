# Resurgence Outpost Raid System Plan

## Overview

A raid system where factions with low reputation send hostile mobs to attack the player's outpost. Initially implemented for the Insurgence Clan only.

---

## A* Pathfinding Solution

### The Problem

The A* system in `code/__HELPERS/AStar.dm` uses `reachableTurftest` which:
1. Checks `!T.density` - rejects walls (dense turfs)
2. Uses `LinkBlockedWithAccess` - only checks windows/railings/door-windows, NOT regular doors

This means mobs cannot pathfind through walls or doors, even if they have `environment_smash` capability.

### Solution: Custom Adjacent Proc for Raiders

Create a new adjacent proc that treats dense obstacles as passable for mobs that can smash them.

**File**: `code/__HELPERS/AStar.dm` (add to existing file)

```dm
/// Raider-aware turf test - allows pathing through smashable obstacles
/turf/proc/reachableTurftestRaider(requester, turf/T, ID, simulated_only)
	if(!T)
		return FALSE

	// Standard space check
	if(simulated_only && SSpathfinder.space_type_cache[T.type])
		return FALSE

	// Check if requester can smash through obstacles
	var/can_smash_walls = FALSE
	var/can_smash_structures = FALSE
	if(ishostile(requester))
		var/mob/living/simple_animal/hostile/H = requester
		can_smash_walls = (H.environment_smash & ENVIRONMENT_SMASH_WALLS)
		can_smash_structures = (H.environment_smash & ENVIRONMENT_SMASH_STRUCTURES)

	// Check turf density (walls)
	if(T.density)
		if(can_smash_walls && istype(T, /turf/closed/wall))
			// Wall is smashable - treat as passable for pathing
			return TRUE
		return FALSE  // Dense and can't smash

	// Turf is open - check for blocking objects
	return !LinkBlockedWithAccessRaider(T, requester, ID, can_smash_structures)

/// Raider-aware link check - allows pathing through smashable doors/structures
/turf/proc/LinkBlockedWithAccessRaider(turf/T, requester, ID, can_smash_structures)
	var/adir = get_dir(src, T)
	var/rdir = ((adir & MASK_ODD)<<1)|((adir & MASK_EVEN)>>1)

	// Check windows (same as original)
	for(var/obj/structure/window/W in src)
		if(!W.CanAStarPass(ID, adir))
			return TRUE

	// Check railings (same as original)
	for(var/obj/structure/railing/R in src)
		if(!R.CanAStarPass(ID, adir, requester))
			return TRUE

	// Check door windows (same as original)
	for(var/obj/machinery/door/window/W in src)
		if(!W.CanAStarPass(ID, adir))
			return TRUE

	// Check objects in target turf
	for(var/obj/O in T)
		if(!O.CanAStarPass(ID, rdir, requester))
			// Check if it's a smashable door/structure
			if(can_smash_structures && O.density)
				if(istype(O, /obj/machinery/door) || istype(O, /obj/structure))
					if(!(O.resistance_flags & INDESTRUCTIBLE))
						continue  // Smashable - don't block path
			return TRUE

	return FALSE
```

### Alternative Solution: Waypoint-Based Pathing

Instead of modifying A*, use a waypoint system:

1. **Pre-defined waypoints**: Place `/obj/effect/landmark/raid_waypoint` around the map
2. **Waypoint graph**: Build a graph of connected waypoints (manually or auto-generated)
3. **Simplified pathing**: Raiders path from waypoint to waypoint using simple `walk_to`
4. **Obstacle clearing**: When stuck between waypoints, use `DestroyPathToTarget`

```dm
/obj/effect/landmark/raid_waypoint
	name = "raid waypoint"
	invisibility = INVISIBILITY_ABSTRACT
	var/list/connected_waypoints = list()  // Linked waypoints
	var/waypoint_id = ""

/datum/raid_pathfinder
	var/list/waypoints = list()  // All waypoints on z-level

	/// Find path from start to end using waypoint graph
	proc/find_waypoint_path(turf/start, turf/end)
		// Find nearest waypoint to start
		// Find nearest waypoint to end
		// Use simple BFS/Dijkstra on waypoint graph
		// Return list of waypoints to traverse
```

### Hybrid Approach (Recommended)

Combine both:
1. **Primary**: Use standard A* with `reachableTurftestRaider` for smashing mobs
2. **Fallback**: If A* fails (path too long/complex), use waypoint system
3. **Stuck Detection**: If mob is stuck for X ticks, call `DestroyPathToTarget` in direction of target

```dm
/datum/component/raider/proc/NavigateToTarget(atom/destination)
	var/list/path = get_path_to(
		parent,
		destination,
		/turf/proc/Distance_cardinal,
		0,
		200,  // Increased max depth for raiders
		0,
		/turf/proc/reachableTurftestRaider  // Custom adjacent proc
	)

	if(!length(path))
		// A* failed - use direct approach with smashing
		var/mob/living/simple_animal/hostile/H = parent
		H.Goto(destination, H.move_to_delay, 0)
		return FALSE

	return path
```

---

## Component-Based Raider System

### Why Components Instead of Subtypes

Creating `/mob/living/simple_animal/hostile/clan/raider` as a subtype would:
- Duplicate all existing clan mob code (Scout, Defender, Drone, etc.)
- Require maintaining parallel hierarchies
- Prevent using the rich variety of existing clan mobs

Instead, use a **component** that can be attached to ANY existing clan mob.

### The Raider Component

**File**: `code/modules/resurgence_outpost/raids/raider_component.dm`

```dm
/// Component that makes any hostile mob into a raider
/datum/component/raider
	/// Reference to the raid this raider belongs to
	var/datum/resurgence_raid/raid
	/// Current raid objective (landmark to attack)
	var/atom/current_objective
	/// Items this raider has stolen (for pillage raids)
	var/list/stolen_items = list()
	/// Maximum items this raider can carry
	var/max_stolen = 3
	/// Whether this raider should retreat when inventory full
	var/retreat_when_full = FALSE
	/// Spawn point to retreat to
	var/obj/effect/landmark/raid_spawn/retreat_point
	/// Stuck counter for obstacle detection
	var/stuck_counter = 0
	/// Last position for stuck detection
	var/turf/last_position
	/// Timer for stuck checking
	var/stuck_check_timer

/datum/component/raider/Initialize(datum/resurgence_raid/_raid, atom/_objective, _retreat_point)
	if(!ishostile(parent))
		return COMPONENT_INCOMPATIBLE

	raid = _raid
	current_objective = _objective
	retreat_point = _retreat_point

	var/mob/living/simple_animal/hostile/H = parent

	// Ensure raider can smash structures (minimum)
	if(H.environment_smash < ENVIRONMENT_SMASH_STRUCTURES)
		H.environment_smash = ENVIRONMENT_SMASH_STRUCTURES

	// Register signals
	RegisterSignal(parent, COMSIG_LIVING_DEATH, PROC_REF(OnDeath))
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(OnMoved))

	// Start stuck detection timer
	stuck_check_timer = addtimer(CALLBACK(src, PROC_REF(CheckStuck)), 2 SECONDS, TIMER_LOOP | TIMER_STOPPABLE)

	// Start navigation
	NavigateToObjective()

/datum/component/raider/Destroy()
	if(stuck_check_timer)
		deltimer(stuck_check_timer)
	if(raid)
		raid.OnRaiderRemoved(parent)
	return ..()

/datum/component/raider/proc/OnDeath(datum/source)
	SIGNAL_HANDLER
	// Drop stolen items
	for(var/obj/item/I in stolen_items)
		I.forceMove(get_turf(parent))
	stolen_items = list()
	qdel(src)

/datum/component/raider/proc/OnMoved(datum/source, atom/old_loc, dir, forced)
	SIGNAL_HANDLER
	stuck_counter = 0  // Reset stuck counter on successful move

/datum/component/raider/proc/CheckStuck()
	var/mob/living/simple_animal/hostile/H = parent
	if(!H || H.stat == DEAD)
		return

	var/turf/current = get_turf(H)
	if(current == last_position)
		stuck_counter++
		if(stuck_counter >= 3)  // Stuck for 6+ seconds
			// Try to smash through obstacle
			H.DestroyPathToTarget()
			stuck_counter = 0
	else
		stuck_counter = 0

	last_position = current

/datum/component/raider/proc/NavigateToObjective()
	var/mob/living/simple_animal/hostile/H = parent
	if(!H || H.stat == DEAD || !current_objective)
		return

	// Try A* with raider-aware pathing
	var/list/path = get_path_to(
		H,
		current_objective,
		/turf/proc/Distance_cardinal,
		0,
		150,  // Generous max depth
		0,
		/turf/proc/reachableTurftestRaider
	)

	if(length(path))
		// Path found - let normal AI handle movement with path guidance
		H.target = current_objective
	else
		// No path - just move toward target and smash
		H.Goto(current_objective, H.move_to_delay, 0)

/// For pillage raids - attempt to pick up nearby valuable items
/datum/component/raider/proc/TryLoot()
	if(length(stolen_items) >= max_stolen)
		if(retreat_when_full)
			BeginRetreat()
		return FALSE

	var/mob/living/simple_animal/hostile/H = parent
	for(var/obj/item/I in range(1, H))
		if(I.anchored)
			continue
		var/value = get_item_trade_value(I)
		if(value >= 5)  // Only valuable items
			I.forceMove(H)
			stolen_items += I
			H.visible_message(span_warning("[H] grabs [I]!"))
			return TRUE
	return FALSE

/datum/component/raider/proc/BeginRetreat()
	if(!retreat_point)
		return
	var/mob/living/simple_animal/hostile/H = parent
	current_objective = retreat_point
	NavigateToObjective()
```

### Using the Component

```dm
// When spawning raiders for a raid:
/datum/resurgence_raid/proc/SpawnRaiders()
	var/list/spawn_points = GetSpawnPoints()
	var/list/targets = GetTargetLandmarks()

	for(var/mob_type in raid_composition)
		var/count = raid_composition[mob_type]
		for(var/i in 1 to count)
			var/turf/spawn_loc = pick(spawn_points)
			var/mob/living/simple_animal/hostile/M = new mob_type(spawn_loc)

			// Add raider component to existing mob type
			var/atom/target = pick(targets)
			M.AddComponent(/datum/component/raider, src, target, spawn_loc)

			raiders += M
```

---

## Core Systems

### 1. Raid Manager Subsystem

A subsystem that monitors faction reputation and triggers raids when conditions are met.

**File**: `code/modules/resurgence_outpost/raids/raid_manager.dm`

```dm
SUBSYSTEM_DEF(resurgence_raids)
    name = "Resurgence Raids"
    wait = 1 MINUTES
    flags = SS_BACKGROUND

    var/list/datum/resurgence_raid/active_raids = list()
    var/list/datum/resurgence_raid/pending_raids = list()
    var/raid_cooldown = 0
    var/global_raid_cooldown = 10 MINUTES
```

**Key Variables**:
- `raid_cooldown`: Global cooldown between raids
- `reputation_raid_threshold`: Rep below 20 triggers raids
- `raid_chance_per_cycle`: Probability check per subsystem fire

---

### 2. Raid Datum

Base raid datum that handles spawning, pathfinding, and raid objectives.

**File**: `code/modules/resurgence_outpost/raids/raid_base.dm`

```dm
/datum/resurgence_raid
    var/name = "Unknown Raid"
    var/raid_type = RAID_TYPE_BASIC
    var/datum/trading_faction/source_faction
    var/list/mob/living/raiders = list()
    var/list/turf/spawn_points = list()
    var/list/obj/effect/landmark/raid_target/targets = list()
    var/raid_state = RAID_PENDING
    var/delay_time = 0  // For delayed raids
    var/max_raiders = 5
```

---

### 3. Raid Types

| Type | Behavior | Mob Composition |
|------|----------|-----------------|
| **Delayed Raid** | Spawn, wait 2-3 min at spawn, then assault | Mixed composition |
| **Basic Raid** | Spawn and immediately pathfind to targets | Scouts + Defenders |
| **Pillage Raid** | Mobs pick up items, then retreat | Scouts + special "looter" behavior |
| **Siege Raid** | Focus on destroying structures | Demolishers + Bomber Spiders |
| **Assassination** | Target specific players | Assassins + Snipers |
| **Overwhelming Force** | Large numbers, weak units | Many Scouts |

**Defines**:
```dm
#define RAID_TYPE_DELAYED 1
#define RAID_TYPE_BASIC 2
#define RAID_TYPE_PILLAGE 3
#define RAID_TYPE_SIEGE 4
#define RAID_TYPE_ASSASSINATION 5
#define RAID_TYPE_OVERWHELMING 6

#define RAID_PENDING 0
#define RAID_SPAWNING 1
#define RAID_WAITING 2  // For delayed raids
#define RAID_ACTIVE 3
#define RAID_RETREATING 4
#define RAID_COMPLETE 5
```

---

### 4. Spawn Points and Room Targeting

**Spawn Points**: Landmarks placed at map edges where raiders enter.

**Target System**: Raiders target existing `/area/resurgence_outpost/room` subtypes on the map.

**File**: `code/modules/resurgence_outpost/raids/raid_landmarks.dm`

```dm
/// Spawn point landmark - place at map edges
/obj/effect/landmark/raid_spawn
	name = "raid spawn point"
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x"
	invisibility = INVISIBILITY_ABSTRACT
	var/spawn_id = "default"
	var/faction_id = "insurgence_clan"  // Which faction uses this spawn

/obj/effect/landmark/raid_spawn/Initialize(mapload)
	. = ..()
	GLOB.raid_spawn_points += src

/obj/effect/landmark/raid_spawn/Destroy()
	GLOB.raid_spawn_points -= src
	return ..()
```

### Room-Based Targeting

Raiders dynamically find and target rooms using the existing area system.

**Key Feature**: Rooms are checked for accessibility before being targeted.

```dm
/// Priority weights for room types (higher = more likely target)
GLOBAL_LIST_INIT(raid_room_priorities, list(
	ROOM_TYPE_STORAGE = 10,         // High priority - resources
	ROOM_TYPE_EXPORT_WAREHOUSE = 9, // High priority - trade goods
	ROOM_TYPE_WORKSHOP = 7,         // Medium-high - destroy production
	ROOM_TYPE_KITCHEN = 6,          // Medium - disrupt food
	ROOM_TYPE_COMMON = 5,           // Medium - populated area
	ROOM_TYPE_LIVING_QUARTERS = 4,  // Lower - personal space
	ROOM_TYPE_BARRACKS = 4,         // Lower - sleeping area
	ROOM_TYPE_BASIC = 3             // Base priority
))

// ============================================
// Room Accessibility Checking
// ============================================

/// Check if a room is accessible (has doors or openings in boundary)
/// Returns TRUE if raiders can enter, FALSE if fully enclosed
/proc/is_room_accessible(area/resurgence_outpost/room/room)
	if(!room)
		return FALSE

	// If room has boundary doors, it's accessible
	if(room.boundary_doors?.len)
		return TRUE

	// Check if any boundary wall position has an adjacent open turf outside the room
	// This catches rooms with open doorways (no door object)
	for(var/turf/wall_turf in room.boundary_walls)
		for(var/dir in GLOB.cardinals)
			var/turf/adjacent = get_step(wall_turf, dir)
			if(!adjacent)
				continue
			// Check if adjacent turf is outside this room and is open
			if(adjacent.loc != room && !adjacent.density)
				// Found an opening - check if there's a path through
				// (the wall might have a door or be an airlock position)
				for(var/turf/room_turf in room.contents)
					if(get_dist(room_turf, adjacent) <= 2 && !room_turf.density)
						return TRUE

	// No doors and no openings found - room is enclosed
	return FALSE

/// Check if a room is accessible by wall-smashing raiders
/// Wall-smashers can target ANY room since they can break through
/proc/is_room_accessible_with_smash(area/resurgence_outpost/room/room, can_smash_walls = FALSE)
	if(!room)
		return FALSE

	// Wall-smashers can access any room
	if(can_smash_walls)
		return TRUE

	// Otherwise check normal accessibility
	return is_room_accessible(room)

/// Get the best entry point for a room
/// Returns a turf that raiders should pathfind to first
/proc/get_room_entry_point(area/resurgence_outpost/room/room)
	if(!room)
		return null

	// Priority 1: Find a door in the boundary
	for(var/obj/machinery/door/D in room.boundary_doors)
		var/turf/door_turf = get_turf(D)
		if(door_turf)
			return door_turf

	// Priority 2: Find any door object adjacent to room turfs
	for(var/turf/T in room.contents)
		for(var/dir in GLOB.cardinals)
			var/turf/adjacent = get_step(T, dir)
			if(!adjacent)
				continue
			for(var/obj/machinery/door/D in adjacent)
				return adjacent

	// Priority 3: Find any open turf on the room boundary
	for(var/turf/T in room.contents)
		for(var/dir in GLOB.cardinals)
			var/turf/adjacent = get_step(T, dir)
			if(!adjacent || adjacent.loc == room)
				continue
			if(!adjacent.density)
				return T  // Return the room turf near the opening

	// Priority 4: For wall-smashers, find a wall to break through
	if(room.boundary_walls?.len)
		return pick(room.boundary_walls)

	// Fallback: Random turf in room
	return get_random_turf_in_room(room)

/// Raid type specific room preferences
GLOBAL_LIST_INIT(raid_type_room_preferences, list(
	RAID_TYPE_PILLAGE = list(ROOM_TYPE_STORAGE, ROOM_TYPE_EXPORT_WAREHOUSE, ROOM_TYPE_WORKSHOP),
	RAID_TYPE_SIEGE = list(ROOM_TYPE_WORKSHOP, ROOM_TYPE_KITCHEN, ROOM_TYPE_STORAGE),
	RAID_TYPE_ASSASSINATION = list(ROOM_TYPE_LIVING_QUARTERS, ROOM_TYPE_BARRACKS, ROOM_TYPE_COMMON),
	RAID_TYPE_BASIC = list()  // No preference - uses priority weights
))

/// Get all valid room areas on the map
/// Arguments:
/// * require_accessible - If TRUE, only return rooms that have doors/openings
/// * can_smash_walls - If TRUE, enclosed rooms are also valid (for wall-smashers)
/proc/get_resurgence_room_areas(require_accessible = TRUE, can_smash_walls = FALSE)
	var/list/rooms = list()
	for(var/area/resurgence_outpost/room/R in GLOB.sortedAreas)
		if(R.contents.len == 0)  // No turfs - skip
			continue

		// Check accessibility if required
		if(require_accessible)
			if(!is_room_accessible_with_smash(R, can_smash_walls))
				continue  // Room is fully enclosed and we can't smash in

		rooms += R
	return rooms

/// Get a random turf inside a room area (for pathfinding target)
/proc/get_random_turf_in_room(area/resurgence_outpost/room/room)
	if(!room || !room.contents.len)
		return null
	var/list/valid_turfs = list()
	for(var/turf/T in room.contents)
		if(!T.density)  // Open turf
			valid_turfs += T
	if(!valid_turfs.len)
		return null
	return pick(valid_turfs)

/// Select target rooms for a raid based on raid type
/// Filters out inaccessible rooms unless raiders can smash walls
/datum/resurgence_raid/proc/SelectTargetRooms()
	// Check if any raiders in composition can smash walls
	var/can_smash = CheckRaidCanSmashWalls()

	// Get accessible rooms only
	var/list/all_rooms = get_resurgence_room_areas(TRUE, can_smash)
	if(!all_rooms.len)
		// No accessible rooms - raid cannot proceed
		log_game("RAID WARNING: No accessible rooms found for raid targeting")
		return list()

	var/list/preferred_types = GLOB.raid_type_room_preferences[raid_type]
	var/list/targets = list()

	// First, try to find preferred room types
	if(preferred_types?.len)
		for(var/area/resurgence_outpost/room/R in all_rooms)
			if(R.room_type in preferred_types)
				targets += R

	// If no preferred rooms found, use priority weights
	if(!targets.len)
		for(var/area/resurgence_outpost/room/R in all_rooms)
			var/priority = GLOB.raid_room_priorities[R.room_type] || 1
			for(var/i in 1 to priority)
				targets += R  // Add multiple times based on priority

	// Pick 1-3 target rooms
	var/num_targets = clamp(rand(1, 3), 1, targets.len)
	var/list/final_targets = list()
	for(var/i in 1 to num_targets)
		if(!targets.len)
			break
		final_targets += pick_n_take(targets)

	return final_targets

/// Check if any mob type in the raid composition can smash walls
/datum/resurgence_raid/proc/CheckRaidCanSmashWalls()
	var/list/composition = GetRaidComposition()
	for(var/mob_type in composition)
		// Create temporary mob to check environment_smash
		var/mob/living/simple_animal/hostile/temp = new mob_type()
		var/can_smash = (temp.environment_smash & ENVIRONMENT_SMASH_WALLS)
		qdel(temp)
		if(can_smash)
			return TRUE
	return FALSE
```

### Example: Raider Targeting a Room

```dm
/datum/component/raider/proc/AssignRoomTarget(area/resurgence_outpost/room/target_room)
	if(!target_room)
		return FALSE

	var/mob/living/simple_animal/hostile/H = parent
	var/can_smash_walls = (H.environment_smash & ENVIRONMENT_SMASH_WALLS)

	// Check if room is accessible to this raider
	if(!is_room_accessible_with_smash(target_room, can_smash_walls))
		return FALSE  // Can't reach this room

	// Get the best entry point for the room
	var/turf/entry_point = get_room_entry_point(target_room)
	if(!entry_point)
		// Fallback to random turf in room
		entry_point = get_random_turf_in_room(target_room)

	if(!entry_point)
		return FALSE

	current_objective = entry_point
	target_room_ref = WEAKREF(target_room)
	NavigateToObjective()
	return TRUE

/// Called when raider reaches entry point - navigate inside the room
/datum/component/raider/proc/OnReachedEntryPoint()
	var/area/resurgence_outpost/room/target_room = target_room_ref?.resolve()
	if(!target_room)
		return

	// Now get a turf inside the room
	var/turf/inside_turf = get_random_turf_in_room(target_room)
	if(inside_turf)
		current_objective = inside_turf
		NavigateToObjective()
```

---

### 5. Raider AI Behavior

#### Wall-Breaking Capability

Raiders need to attack walls blocking their path.

**Modification to base clan mob** (`lc13_resurgence_clan_mobs.dm`):

```dm
/mob/living/simple_animal/hostile/clan/raider
    environment_smash = ENVIRONMENT_SMASH_WALLS
    var/is_raider = TRUE
    var/wall_attack_damage = 25
    var/wall_attack_sound = 'sound/weapons/smash.ogg'

/mob/living/simple_animal/hostile/clan/raider/CanSmashTurfs(turf/T)
    if(istype(T, /turf/closed/wall))
        return TRUE
    return ..()

/mob/living/simple_animal/hostile/clan/raider/proc/AttackWall(turf/closed/wall/W)
    if(!W)
        return
    playsound(src, wall_attack_sound, 50, TRUE)
    W.take_damage(wall_attack_damage, BRUTE)
    visible_message(span_danger("[src] attacks the wall!"))
```

#### Pathfinding Solution

Since A* struggles with doors/walls, use a hybrid approach:

1. **Initial Path**: Use A* to get the general direction
2. **Obstacle Detection**: When path is blocked, check what's blocking
3. **Dynamic Behavior**:
   - Doors: Attack the door until it breaks
   - Walls: Raiders with `environment_smash` attack walls
   - Objects: Smash or pathfind around

**Alternative: Wave Commander with Wall Breaking**

Modify the `wave_commander` to:
1. Path using standard A*
2. When stuck, broadcast to nearby raiders to clear obstacle
3. Resume pathing once cleared

```dm
/obj/effect/wave_commander/raider
    var/stuck_counter = 0
    var/max_stuck_attempts = 10

/obj/effect/wave_commander/raider/StepInPath(dest)
    var/result = ..()
    if(!result)
        stuck_counter++
        if(stuck_counter >= max_stuck_attempts)
            // Find blocking obstacle and signal raiders to destroy it
            var/turf/blocking = get_step_towards(src, dest)
            RequestObstacleClearing(blocking)
    else
        stuck_counter = 0
    return result

/obj/effect/wave_commander/raider/proc/RequestObstacleClearing(turf/T)
    for(var/mob/living/simple_animal/hostile/clan/raider/R in range(3, src))
        if(R.stat != DEAD)
            R.target = T  // Temporarily target the obstacle
```

---

### 6. Pillage Behavior

Special AI for pillage raids.

**File**: `code/modules/resurgence_outpost/raids/raid_pillage.dm`

```dm
/mob/living/simple_animal/hostile/clan/raider/looter
    name = "clan looter"
    var/list/stolen_items = list()
    var/max_carry = 3
    var/retreat_when_full = TRUE
    var/obj/effect/landmark/raid_spawn/retreat_point

/mob/living/simple_animal/hostile/clan/raider/looter/proc/TryLootItem()
    if(length(stolen_items) >= max_carry)
        return FALSE

    for(var/obj/item/I in range(1, src))
        if(IsValuable(I))
            PickupItem(I)
            return TRUE
    return FALSE

/mob/living/simple_animal/hostile/clan/raider/looter/proc/IsValuable(obj/item/I)
    // Check resurgence fallback prices or custom_price
    var/value = get_item_trade_value(I)
    return value >= 5  // Only loot items worth 5+ credits

/mob/living/simple_animal/hostile/clan/raider/looter/proc/PickupItem(obj/item/I)
    I.forceMove(src)
    stolen_items += I
    visible_message(span_warning("[src] grabs [I]!"))

    if(length(stolen_items) >= max_carry && retreat_when_full)
        BeginRetreat()
```

---

### 7. Raid Composition (Using Existing Mob Types)

**File**: `code/modules/resurgence_outpost/raids/raid_composition.dm`

All raids use **existing clan mob types** with the raider component attached at spawn.
No new mob subtypes are required.

```dm
// Insurgence Clan compositions based on raid type
// Uses existing types from:
// - ModularLobotomy/extra_mobs/lc13_resurgence_clan_mobs.dm
// - ModularLobotomy/extra_mobs/lc13_resurgence_clan_rce.dm
// - ModularLobotomy/extra_mobs/lc13_resurgence_clan_rce_ranged.dm

GLOBAL_LIST_INIT(insurgence_raid_compositions, list(
	RAID_TYPE_DELAYED = list(
		/mob/living/simple_animal/hostile/clan/scout = 3,
		/mob/living/simple_animal/hostile/clan/defender = 1,
		/mob/living/simple_animal/hostile/clan/ranged/gunner = 2
	),
	RAID_TYPE_BASIC = list(
		/mob/living/simple_animal/hostile/clan/scout = 4,
		/mob/living/simple_animal/hostile/clan/defender = 1
	),
	RAID_TYPE_PILLAGE = list(
		// Scouts with pillage component behavior enabled
		/mob/living/simple_animal/hostile/clan/scout = 4,
		/mob/living/simple_animal/hostile/clan/defender = 2
	),
	RAID_TYPE_SIEGE = list(
		/mob/living/simple_animal/hostile/clan/demolisher = 2,
		/mob/living/simple_animal/hostile/clan/bomber_spider = 4,
		/mob/living/simple_animal/hostile/clan/defender = 1
	),
	RAID_TYPE_ASSASSINATION = list(
		/mob/living/simple_animal/hostile/clan/assassin = 2,
		/mob/living/simple_animal/hostile/clan/ranged/sniper = 2
	),
	RAID_TYPE_OVERWHELMING = list(
		/mob/living/simple_animal/hostile/clan/scout = 8,
		/mob/living/simple_animal/hostile/clan/ranged/rapid = 4
	)
))

// Component variants for special behaviors
/datum/component/raider/pillager
	retreat_when_full = TRUE
	max_stolen = 3

	// Override to also loot during combat
	proc/OnAttackComplete(datum/source, atom/target)
		SIGNAL_HANDLER
		// After attacking, try to loot nearby
		TryLoot()
```

### How It Works

When spawning raiders:
1. Create the mob using its existing type (e.g., `/mob/living/simple_animal/hostile/clan/scout`)
2. Attach the raider component: `mob.AddComponent(/datum/component/raider, raid, target, retreat_point)`
3. For pillage raids, use the pillager variant: `mob.AddComponent(/datum/component/raider/pillager, ...)`

The component:
- Upgrades `environment_smash` if needed (for door/structure breaking)
- Provides navigation with stuck detection
- Handles pillaging, retreating, and raid coordination
- Cleans up on mob death

---

### 8. Raid Scaling

Scale difficulty based on:
- Outpost "wealth" (total resource value)
- Number of players
- Time elapsed in round
- Previous raid success/failure

```dm
/datum/resurgence_raid/proc/CalculateDifficulty()
    var/base_raiders = 4

    // Scale with player count
    var/player_count = length(GLOB.player_list)
    base_raiders += round(player_count * 0.5)

    // Scale with time (more raiders as round progresses)
    var/time_factor = min(world.time / (60 MINUTES), 2.0)
    base_raiders = round(base_raiders * (1 + time_factor * 0.5))

    // Cap at reasonable max
    return clamp(base_raiders, 3, 15)
```

---

### 9. Raid Warnings

Alert players before a raid arrives.

```dm
/datum/resurgence_raid/proc/SendWarning()
    // Insurgence Clan warning style
    for(var/mob/living/carbon/human/H in GLOB.player_list)
        var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
        if(istype(core))
            to_chat(H, span_userdanger("Your faith core trembles... Something approaches."))
            SEND_SOUND(H, sound('sound/effects/alert.ogg'))

    // Faction-specific warning message
    var/message = source_faction.get_dialogue("raid_warning")
    // Broadcast on comms console if available
```

---

## Files to Create

| File | Purpose |
|------|---------|
| `code/modules/resurgence_outpost/raids/_raids.dm` | Defines and globals |
| `code/modules/resurgence_outpost/raids/raid_manager.dm` | Raid subsystem |
| `code/modules/resurgence_outpost/raids/raid_base.dm` | Base raid datum |
| `code/modules/resurgence_outpost/raids/raid_types.dm` | Specific raid behaviors |
| `code/modules/resurgence_outpost/raids/raid_composition.dm` | Mob compositions |
| `code/modules/resurgence_outpost/raids/raid_landmarks.dm` | Spawn point landmarks only (targets use room areas) |
| `code/modules/resurgence_outpost/raids/raider_component.dm` | Component for raider behavior |
| `code/modules/resurgence_outpost/raids/raid_debug.dm` | Debug tool for testing |

## Files to Modify

| File | Changes |
|------|---------|
| `code/__HELPERS/AStar.dm` | Add `reachableTurftestRaider` and `LinkBlockedWithAccessRaider` procs |
| `code/modules/resurgence_outpost/trading/factions.dm` | Hook raid triggers to reputation |
| `lobotomy-corp13.dme` | Include new files |

---

## Implementation Steps

### Phase 1: A* Pathfinding Enhancement
1. Add `reachableTurftestRaider` proc to `code/__HELPERS/AStar.dm`
2. Add `LinkBlockedWithAccessRaider` proc for door/structure handling
3. Test pathfinding through walls and doors with `environment_smash` mobs

### Phase 2: Raider Component
1. Create `raider_component.dm` with base `/datum/component/raider`
2. Implement stuck detection and `DestroyPathToTarget` calls
3. Implement navigation with fallback to direct movement
4. Create `/datum/component/raider/pillager` variant for looting
5. Test attaching component to existing clan mobs

### Phase 3: Core Raid Infrastructure
1. Create defines and globals (`_raids.dm`)
2. Create raid manager subsystem
3. Create base raid datum with spawn/end logic
4. Create raid landmark objects (spawn points, targets)

### Phase 4: Raid Types
1. Implement Basic Raid (spawn → attack)
2. Implement Delayed Raid (spawn → wait → attack)
3. Implement Siege Raid (focus structures)
4. Implement Pillage Raid (loot and retreat)
5. Implement Assassination Raid (target players)
6. Implement Overwhelming Force Raid (many weak units)

### Phase 5: Integration
1. Hook raid system to faction reputation in `factions.dm`
2. Add raid warnings to players
3. Add raid scaling based on outpost state
4. Create debug tools for testing raids

### Phase 6: Polish
1. Add victory/defeat conditions
2. Add post-raid dialogue from factions
3. Add reputation changes from raid outcomes
4. Balance raid difficulty and frequency

---

## Raid Flow

```
1. Subsystem checks faction reputation each cycle
2. If reputation < threshold && cooldown passed:
   - Roll for raid chance
   - Select raid type based on faction/reputation
   - Create raid datum

3. Raid datum initialization:
   - Find spawn points for this faction (landmarks)
   - Find target rooms using get_resurgence_room_areas()
   - Select rooms based on raid type preferences:
     * PILLAGE → Storage, Export Warehouse, Workshop
     * SIEGE → Workshop, Kitchen, Storage
     * ASSASSINATION → Living Quarters, Barracks, Common
     * BASIC/DELAYED/OVERWHELMING → Priority-weighted selection
   - Calculate difficulty/composition
   - Send warning to players

4. Raid execution:
   - Spawn raiders at landmark spawn points
   - Attach /datum/component/raider to each mob
   - Assign target rooms to raiders:
     * Get random open turf in target room
     * Set as current_objective
     * Begin pathfinding with raider-aware A*

   Raid type behaviors:
   - DELAYED: Wait at spawn for 2-3 min, then navigate to rooms
   - BASIC: Immediately pathfind to room turfs
   - PILLAGE: Target storage rooms, loot items, retreat when full
   - SIEGE: Target workshop/kitchen, destroy structures
   - ASSASSINATION: Target living quarters, hunt players in area

5. Raid monitoring:
   - Track alive raiders via component signals
   - Check for victory (all raiders dead)
   - Check for defeat (objective complete - items stolen, structures destroyed)
   - Handle retreat conditions (>75% casualties)

6. Raid completion:
   - Clean up remaining raiders (retreat animation)
   - Update faction reputation based on outcome
   - Reset cooldown
   - Log results
```

---

## Pathfinding Strategy

Since A* cannot path through doors/walls, use this approach:

1. **Use `environment_smash`**: Raiders with ENVIRONMENT_SMASH_WALLS can attack blocking turfs
2. **DestroyPathToTarget override**: Make raiders check next step, attack if blocked
3. **Fallback movement**: If stuck for too long, pick random direction

```dm
/mob/living/simple_animal/hostile/clan/raider/MoveToTarget()
    . = ..()
    if(!.)
        // Failed to move, check if blocked
        var/turf/next = get_step_towards(src, target)
        if(next && next.density)
            // Attack the blocking turf
            DestroyObjectsInDirection(get_dir(src, next))
```

---

## Testing Debug Tool

**File**: `code/modules/resurgence_outpost/raids/raid_debug.dm`

```dm
/obj/item/raid_debug_tool
    name = "raid debugger"
    desc = "Debug tool for testing raid system."
    icon = 'icons/obj/device.dmi'
    icon_state = "multitool"

/obj/item/raid_debug_tool/attack_self(mob/user)
    var/list/options = list(
        "Trigger Basic Raid",
        "Trigger Delayed Raid",
        "Trigger Siege Raid",
        "Trigger Pillage Raid",
        "End All Raids",
        "List Active Raids",
        "Set Insurgence Rep to 5"
    )
    var/choice = input(user, "Select raid action", "Raid Debug") as null|anything in options
    // Handle choices...
```

---

## Balance Considerations

- **Raid Frequency**: Every 15-30 minutes when reputation < 20
- **Raid Size**: 4-12 raiders based on player count
- **Warning Time**: 1-2 minutes before raid spawns
- **Cooldown After Raid**: 10 minutes minimum
- **Retreat Threshold**: Raiders retreat if >75% casualties
- **Pillage Cap**: Looters can only carry 3 items each

---

## Future Expansion

- Multiple factions sending raids (not just Insurgence)
- Player actions affecting raid frequency (killing scouts = retribution)
- Defensive structures (turrets, traps) that affect raids
- Raid rewards (loot from dead raiders)
- "Raid boss" encounters for very low reputation
