/*
 * Refraction-only wave system: one wave per node, per-mob-type stock
 * authored on the node datum. One controller per node; landmarks are
 * passive position markers.
 */

GLOBAL_LIST_EMPTY(refraction_wave_controllers)
/// Spawned mob ref -> the controller that produced it.
GLOBAL_LIST_EMPTY(refraction_wave_mob_owners)

/// Visual warning before a mob materializes (deciseconds).
#define REFRACTION_SPAWN_DELAY 6
/// Per-controller cooldown after a spawn fires.
#define REFRACTION_SPAWN_COOLDOWN (3 SECONDS)

// ---------- Controller ----------

/datum/refraction_wave_controller
	/// Namespaced as "refraction_<run_uid>_<node.id>".
	var/id
	var/run_uid
	var/room_id = ""
	/// Source of truth for stock + concurrent_max + is_boss.
	var/datum/refraction_node/node
	/// Matching spawner landmarks on the run's z; picked at random per spawn.
	var/list/spawn_landmarks = list()
	/// Live stock; decremented per spawn, key pruned at 0.
	var/list/current_stock = list()
	/// Mobs we spawned that are still alive.
	var/list/living_mobs = list()
	var/current_alive = 0
	/// Concurrent cap for this activation (computed at Activate).
	var/effective_max = 0
	/// Mobs spawned per cooldown cycle.
	var/spawns_per_cycle = 1
	/// LiveMemberCount() snapshot from Activate; drives per-mob HP/damage scaling.
	var/num_players = 1
	/// Cooldown gate between BATCHES, not individual spawns.
	var/on_cooldown = FALSE
	/// In-flight spawn effects (mob hasn't materialized yet).
	var/pending_spawns = 0
	/// True after Activate until Reset or qdel.
	var/activated = FALSE
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

/// Starts the room's spawning. `num_players` scales per-type stocks (bosses excluded).
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
	var/stock_mult = (node.is_boss || !SSrefraction_railway.scale_stock) ? 1 : refraction_stock_mult(num_players)
	for(var/path in node.mob_stock)
		var/scaled = round(node.mob_stock[path] * stock_mult)
		if(scaled < 1)
			scaled = 1
		current_stock[path] = scaled
	var/conc_mult = (node.is_boss || !SSrefraction_railway.scale_concurrent) ? 1 : refraction_concurrent_mult(num_players)
	effective_max = round(node.concurrent_max * conc_mult)
	if(effective_max < 1)
		effective_max = 1
	src.num_players = max(1, num_players)
	spawns_per_cycle = SSrefraction_railway.scale_spawn_batch ? src.num_players : 1
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH, PROC_REF(OnMobDeath))
	SpawnBatch()

/// Fires up to `spawns_per_cycle` mobs, capped by concurrent cap and stock.
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

/// Spawns exactly one mob, no cooldown gate. Returns TRUE on success.
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
	if(istype(node) && HasStock() && current_alive < effective_max)
		SpawnBatch()

/// Returns a random non-dense turf within view(5) of L's turf, else L's turf.
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

/// Per-mob death handler: decrements alive, replaces or fires RoomCleared.
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

/// Resets controller state for a fresh activation (lane reuse).
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

/// Position marker authored on a line's dmm; `landmark_id` matches the node's.
/obj/effect/landmark/refraction/spawner
	name = "refraction spawner"
	desc = "Marks a possible mob spawn position for a refraction node. Notify a coder if you see this."
	icon_state = "x3"
	// `id` is inherited from /obj/effect/landmark/refraction; set it to match
	// the node's landmark_id (multiple landmarks may share an id).

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
	// Suppress butcher loot so cleared rooms don't litter the floor.
	H.butcher_results = null
	H.guaranteed_butcher_results = null
	// Per-mob party-size scaling: bosses get HP only, non-bosses use
	// refraction_scale_hostile (+20% HP / +10% damage per extra player).
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
