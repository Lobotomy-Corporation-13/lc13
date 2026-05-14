/*
 * Refraction-only wave system. Inspired by the W-Corp Cleanup wave_system
 * pattern (Activate -> spawn from a reserve -> track living mobs ->
 * fire RoomCleared when reserve depleted and all dead) but stripped to
 * refraction's actual needs:
 *   - One wave per node, no multi-wave logic.
 *   - Per-mob-type stock authored on the node datum (see node_datum.dm),
 *     not on the landmark. Live stock is multiplied by
 *     refraction_stock_mult(num_players) at activation; boss nodes skip
 *     the multiplier so their authored stock is honored exactly.
 *   - Healing scoped to the run's roster, not GLOB.human_list.
 *   - No physical barriers; advancement is via run datum teleports.
 *
 * Lifetime: SSrefraction_railway.RestampWaveLandmarks creates one
 * /datum/refraction_wave_controller per /datum/refraction_node on the line,
 * binding every /obj/effect/landmark/refraction/spawner whose `id`
 * matches the node's `landmark_id` as a spawn point. The run datum's
 * ActivateRoom finds the controller by namespaced id and calls Activate().
 *
 * The landmark is a passive position marker. All spawn state and logic
 * live on the controller.
 */

GLOBAL_LIST_EMPTY(refraction_wave_controllers)
/// Maps a spawned mob ref -> the controller that produced it. Lets the
/// controller's signal handler quickly skip mobs it didn't spawn.
GLOBAL_LIST_EMPTY(refraction_wave_mob_owners)

/// Visual warning before a mob materializes (deciseconds).
#define REFRACTION_SPAWN_DELAY 6
/// Per-controller cooldown after a spawn fires.
#define REFRACTION_SPAWN_COOLDOWN (3 SECONDS)

// ---------- Controller ----------

/datum/refraction_wave_controller
	/// Namespaced as "refraction_<run_uid>_<node.id>". Run-derived; the
	/// run controls lifetime via the subsystem's restamp/release flow.
	var/id
	/// Owning run + node identifiers.
	var/run_uid
	var/room_id = ""
	/// Source of truth for stock + concurrent_max + is_boss. Held so Reset
	/// can rebuild current_stock without round-tripping through the line.
	var/datum/refraction_node/node
	/// /obj/effect/landmark/refraction/spawner instances with matching
	/// landmark_id on the run's z. Picked from at random per spawn.
	var/list/spawn_landmarks = list()
	/// Live stock — built at Activate, decremented on each spawn, key
	/// pruned when a path hits 0.
	var/list/current_stock = list()
	/// Mobs spawned by us that are still alive.
	var/list/living_mobs = list()
	/// Live count across all spawn landmarks.
	var/current_alive = 0
	/// Effective concurrent cap for THIS activation. Computed at Activate
	/// from `node.concurrent_max * refraction_concurrent_mult(num_players)`
	/// (boss nodes skip the multiplier). Held as state so SpawnBatch
	/// doesn't have to redo the math, and so a Reset+reactivate at a
	/// different player count works correctly.
	var/effective_max = 0
	/// How many mobs spawn per cooldown cycle. Set to num_players at
	/// Activate (min 1) so a duo gets 2 spawns per batch, a quad gets 4,
	/// etc. The effective_max cap still bounds the total alive — small
	/// rooms naturally clip the batch size.
	var/spawns_per_cycle = 1
	/// LiveMemberCount() snapshot from Activate. Source of truth for
	/// per-mob HP / damage scaling at spawn time (see SpawnMob). Held
	/// separately from spawns_per_cycle even though they're currently
	/// equal, so future tuning of one doesn't silently retune the other.
	var/num_players = 1
	/// Cooldown gate — REFRACTION_SPAWN_COOLDOWN between BATCHES (not
	/// between individual spawns within a batch).
	var/on_cooldown = FALSE
	/// In-flight spawn effects (mob hasn't materialized yet).
	var/pending_spawns = 0
	/// True after Activate. Stays TRUE until Reset (lane reuse) or qdel.
	var/activated = FALSE
	/// True after the room is cleared.
	var/completed = FALSE

/datum/refraction_wave_controller/New(new_id)
	. = ..()
	id = new_id
	GLOB.refraction_wave_controllers += src

/datum/refraction_wave_controller/Destroy()
	UnregisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH)
	GLOB.refraction_wave_controllers -= src
	for(var/mob/M as anything in living_mobs)
		GLOB.refraction_wave_mob_owners -= M
	living_mobs.Cut()
	spawn_landmarks.Cut()
	current_stock.Cut()
	node = null
	return ..()

/datum/refraction_wave_controller/proc/RegisterLandmark(obj/effect/landmark/refraction/spawner/L)
	spawn_landmarks |= L

/datum/refraction_wave_controller/proc/HasStock()
	return length(current_stock) > 0

/datum/refraction_wave_controller/proc/TotalStock()
	var/total = 0
	for(var/path in current_stock)
		total += current_stock[path]
	return total

/// Starts the room's spawning. `num_players` scales the per-type stocks
/// (boss nodes ignore the multiplier). Safe to call after a Reset (lane reuse).
/datum/refraction_wave_controller/proc/Activate(num_players = 1)
	if(activated)
		return
	if(!istype(node))
		return
	activated = TRUE
	completed = FALSE
	current_alive = 0
	on_cooldown = FALSE
	pending_spawns = 0
	current_stock = list()
	// Scaling toggles live on the subsystem so they're VV-changeable
	// without recompile. Each defaults TRUE; OFF means "use authored
	// values, no scaling".
	var/stock_mult = (node.is_boss || !SSrefraction_railway.scale_stock) ? 1 : refraction_stock_mult(num_players)
	for(var/path in node.mob_stock)
		var/scaled = round(node.mob_stock[path] * stock_mult)
		if(scaled < 1)
			scaled = 1
		current_stock[path] = scaled
	// Concurrent cap also scales with party size (bosses excluded so a 4-man
	// boss room still spawns one boss at a time).
	var/conc_mult = (node.is_boss || !SSrefraction_railway.scale_concurrent) ? 1 : refraction_concurrent_mult(num_players)
	effective_max = round(node.concurrent_max * conc_mult)
	if(effective_max < 1)
		effective_max = 1
	// Capture the snapshot once. Both per-batch spawn count and per-mob
	// HP/damage scaling read from src.num_players. Min 1 so a 0-player
	// edge case still ticks instead of silently jamming.
	src.num_players = max(1, num_players)
	spawns_per_cycle = SSrefraction_railway.scale_spawn_batch ? src.num_players : 1
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH, PROC_REF(OnMobDeath))
	SpawnBatch()

/// Fires up to `spawns_per_cycle` mobs at once, capped by the concurrent
/// cap and remaining stock. The cooldown is set ONCE for the batch (not
/// per spawn) — so a quad lobby gets 4 mobs simultaneously, then a 3s
/// breather, then the next batch. Caller-safe: short-circuits if on
/// cooldown, no node, no landmarks.
/datum/refraction_wave_controller/proc/SpawnBatch()
	if(on_cooldown)
		return 0
	if(!istype(node))
		return 0
	if(!LAZYLEN(spawn_landmarks))
		return 0
	if(!HasStock())
		return 0
	var/spawned = 0
	for(var/i = 1 to spawns_per_cycle)
		if(!HasStock())
			break
		if(current_alive >= effective_max)
			break
		if(!SpawnOneMob())
			break
		spawned++
	if(spawned > 0)
		on_cooldown = TRUE
		addtimer(CALLBACK(src, PROC_REF(EndCooldown)), REFRACTION_SPAWN_COOLDOWN)
	return spawned

/// Spawns exactly one mob — no cooldown gate. Internal helper used by
/// SpawnBatch (which owns the cooldown). Returns TRUE on success, FALSE
/// if stock empty / cap reached / something else blocks.
/datum/refraction_wave_controller/proc/SpawnOneMob()
	if(!HasStock())
		return FALSE
	if(!istype(node))
		return FALSE
	if(current_alive >= effective_max)
		return FALSE
	if(!LAZYLEN(spawn_landmarks))
		return FALSE
	var/spawn_type = pickweight(current_stock)
	if(!spawn_type)
		return FALSE
	current_stock[spawn_type] -= 1
	if(current_stock[spawn_type] <= 0)
		current_stock -= spawn_type
	var/obj/effect/landmark/refraction/spawner/L = pick(spawn_landmarks)
	pending_spawns++
	var/turf/spawn_turf = node.is_boss ? get_turf(L) : GetSpawnTurfNear(L)
	if(!spawn_turf)
		spawn_turf = get_turf(L)
	new /obj/effect/refraction_mob_spawn(spawn_turf, spawn_type, src)
	current_alive++
	return TRUE

/datum/refraction_wave_controller/proc/EndCooldown()
	on_cooldown = FALSE
	// Cooldown could have been the only thing blocking the next batch —
	// try one now if there's still room and stock.
	if(istype(node) && HasStock() && current_alive < effective_max)
		SpawnBatch()

/// Returns a random non-dense turf within view(5) of L's turf for the
/// spawn-warning effect, so a wave's mobs don't all materialize on the
/// same tile. Boss nodes skip this and use L's tile directly (caller's
/// responsibility — see SpawnOneMob).
/datum/refraction_wave_controller/proc/GetSpawnTurfNear(obj/effect/landmark/refraction/spawner/L)
	if(!L)
		return null
	var/turf/origin = get_turf(L)
	if(!origin)
		return null
	var/list/valid = list()
	for(var/turf/T in view(5, origin))
		if(T.density)
			continue
		valid += T
	return LAZYLEN(valid) ? pick(valid) : origin

/// Per-mob death handler. Decrements current_alive, attempts a replacement
/// if stock remains, and fires RoomCleared when the room is empty.
/datum/refraction_wave_controller/proc/OnMobDeath(datum/source, mob/living/dead_mob)
	SIGNAL_HANDLER
	if(!(dead_mob in living_mobs))
		return
	living_mobs -= dead_mob
	GLOB.refraction_wave_mob_owners -= dead_mob
	current_alive = max(0, current_alive - 1)
	if(IsRoomEmpty())
		INVOKE_ASYNC(src, PROC_REF(RoomCleared))
	else if(HasStock())
		INVOKE_ASYNC(src, PROC_REF(TryReplacement))

/datum/refraction_wave_controller/proc/IsRoomEmpty()
	if(LAZYLEN(living_mobs))
		return FALSE
	if(pending_spawns > 0)
		return FALSE
	if(HasStock())
		return FALSE
	return TRUE

/datum/refraction_wave_controller/proc/TryReplacement()
	if(!HasStock())
		return
	if(!istype(node))
		return
	if(current_alive >= effective_max)
		return
	if(on_cooldown)
		// EndCooldown will retry via SpawnBatch.
		return
	sleep(0.5 SECONDS)
	SpawnBatch()

/datum/refraction_wave_controller/proc/RoomCleared()
	if(completed)
		return
	completed = TRUE
	UnregisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH)
	var/datum/refraction_run/R = SSrefraction_railway.GetRunByUid(run_uid)
	if(R)
		R.OnRoomCleared(room_id)

/// Called by the spawn-warning effect when the mob actually materializes.
/datum/refraction_wave_controller/proc/RegisterSpawnedMob(mob/living/M)
	if(!M)
		return
	living_mobs += M
	GLOB.refraction_wave_mob_owners[M] = src

/datum/refraction_wave_controller/proc/ResolvePendingSpawn()
	pending_spawns = max(0, pending_spawns - 1)
	if(IsRoomEmpty())
		INVOKE_ASYNC(src, PROC_REF(RoomCleared))

/// Resets controller state for a fresh activation. Used by ActivateRoom on
/// lane reuse, where the prior run's controllers may be in `completed` state.
/datum/refraction_wave_controller/proc/Reset()
	UnregisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH)
	for(var/mob/M as anything in living_mobs)
		GLOB.refraction_wave_mob_owners -= M
		if(!QDELETED(M))
			qdel(M)
	living_mobs.Cut()
	current_stock.Cut()
	current_alive = 0
	effective_max = 0
	spawns_per_cycle = 1
	num_players = 1
	on_cooldown = FALSE
	pending_spawns = 0
	activated = FALSE
	completed = FALSE

// ---------- Spawn landmark (passive position marker) ----------

/// Authored on a line's dmm. Just a position. Drop one or many in a node;
/// the controller for that node will pick a random landmark per spawn.
///
/// All spawn logic lives on the controller (see above). The author sets
/// `landmark_id` to match the node datum's `landmark_id`.
/obj/effect/landmark/refraction/spawner
	name = "refraction spawner"
	desc = "Marks a possible mob spawn position for a refraction node. Notify a coder if you see this."
	icon_state = "x3"
	// `id` is inherited from /obj/effect/landmark/refraction. Set it
	// (typically via a typed subtype baked into a per-line landmarks.dm)
	// and have it match the node's landmark_id — multiple landmarks may
	// share an id; the controller picks one at random per spawn.

// ---------- Mob spawn warning effect ----------

/obj/effect/refraction_mob_spawn
	name = "distortion"
	desc = "Reality warps as something prepares to emerge."
	icon = 'icons/effects/cult_effects.dmi'
	icon_state = "bloodin"
	move_force = INFINITY
	pull_force = INFINITY
	generic_canpass = FALSE
	movement_type = PHASING | FLYING
	layer = POINT_LAYER
	var/mob_type
	var/datum/refraction_wave_controller/controller

/obj/effect/refraction_mob_spawn/Initialize(mapload, spawn_type, datum/refraction_wave_controller/C)
	. = ..()
	mob_type = spawn_type
	controller = C
	addtimer(CALLBACK(src, PROC_REF(SpawnMob)), REFRACTION_SPAWN_DELAY)

/obj/effect/refraction_mob_spawn/proc/SpawnMob()
	if(!mob_type || !controller)
		controller?.ResolvePendingSpawn()
		qdel(src)
		return
	var/mob/living/simple_animal/hostile/H = new mob_type(get_turf(src))
	H.del_on_death = TRUE
	// Refraction-spawned mobs aren't a meat source; suppress butcher loot so a
	// cleared room doesn't litter the floor with organs / pelts / etc.
	H.butcher_results = null
	H.guaranteed_butcher_results = null
	// Per-mob party-size scaling. Boss / non-boss are independently
	// gated on the subsystem so an admin can disable wave scaling
	// without giving bosses a free pass (or vice versa).
	// - Boss nodes (scale_boss_stats): HP only, multiplied by raw
	//   num_players (1x solo, 4x quad). Damage stays at authored values
	//   so the boss's DPS profile doesn't escalate beyond what the
	//   authoring tested — added party members just have more HP to
	//   chew through.
	// - Non-boss mobs (scale_wave_stats): refraction_scale_hostile
	//   applies the standard +20% HP / +10% damage per extra player
	//   curve from scaling.dm.
	var/n = max(1, controller.num_players)
	if(controller.node && controller.node.is_boss)
		if(SSrefraction_railway.scale_boss_stats && n > 1)
			H.maxHealth = round(H.maxHealth * n)
			H.health = H.maxHealth
	else if(SSrefraction_railway.scale_wave_stats)
		refraction_scale_hostile(H, n)
	controller.RegisterSpawnedMob(H)
	controller.ResolvePendingSpawn()
	qdel(src)
