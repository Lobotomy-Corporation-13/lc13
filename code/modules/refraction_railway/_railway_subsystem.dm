/*
 * Refraction Railway subsystem.
 *
 * Owns the registry of /datum/refraction_line definitions, the list of currently
 * active /datum/refraction_run instances, the per-line leaderboards, the per-ckey
 * encountered-mob set (for the briefing reveal flow), a lazy mob-stat cache, and
 * the hardcoded mob-tip table.
 *
 * Persistence (leaderboard + encounters) is intentionally NOT wired in this
 * foundation pass; data is in-memory only. Hook into SSpersistence in a follow-up.
 */

#define LOBBY_OPEN     "lobby_open"
#define LOBBY_RUNNING  "lobby_running"
#define LOBBY_FINISHED "lobby_finished"

GLOBAL_VAR_INIT(refraction_run_uid_counter, 0)

SUBSYSTEM_DEF(refraction_railway)
	name = "Refraction Railway"
	flags = SS_KEEP_TIMING | SS_BACKGROUND
	wait = 1 SECONDS
	// After SSpersistence (-2) and SStestrange (-70). Lower = later.
	init_order = -71

	/// id (string) -> /datum/refraction_line. Populated from subtypesof at init.
	var/list/lines = list()
	/// All currently active /datum/refraction_run instances.
	var/list/active_runs = list()
	/// line_id (string) -> list of run records, sorted ascending by time_ds.
	var/list/leaderboards = list()
	/// ckey (string) -> list of mob type-paths the player has fought.
	var/list/encountered_mobs = list()
	/// mob_type (path) -> cached extracted stat list. Lazy-populated.
	var/list/mob_stats_cache = list()
	/// mob_type (path) -> short author-written tip string. Hardcoded at init.
	var/list/mob_tips = list()
	/// One entry per loaded line dmm. Each entry:
	///   list("map_path" = str, "z" = int, "claimed_by" = /datum/refraction_run or null)
	/// A new lobby reuses the first free entry whose map_path matches; otherwise
	/// a new z is loaded and a new entry appended. BYOND has no clean unload-z
	/// primitive, so entries persist for the round once created.
	var/list/loaded_lanes = list()

/datum/controller/subsystem/refraction_railway/Initialize()
	InitializeLines()
	InitializeMobTips()
	// SSpersistence (-2) is fully initialized by the time we run (-71), so we
	// can pull saved leaderboards + encounter sets directly here.
	SSpersistence.LoadRefractionLeaderboards()
	SSpersistence.LoadRefractionEncounters()
	return ..()

/datum/controller/subsystem/refraction_railway/proc/InitializeLines()
	for(var/path in subtypesof(/datum/refraction_line))
		var/datum/refraction_line/L = new path
		if(!L.id)
			qdel(L)
			continue
		if(lines[L.id])
			stack_trace("Duplicate refraction_line id [L.id] from [path]")
			qdel(L)
			continue
		lines[L.id] = L

/datum/controller/subsystem/refraction_railway/proc/InitializeMobTips()
	// path -> tip string. Add entries as lines are authored.
	mob_tips = list()

/datum/controller/subsystem/refraction_railway/fire(resumed = FALSE)
	for(var/datum/refraction_run/R as anything in active_runs)
		R.Tick(wait)

/// Returns the run a given mob currently belongs to, or null.
/datum/controller/subsystem/refraction_railway/proc/GetRunForMob(mob/M)
	if(!M)
		return null
	for(var/datum/refraction_run/R as anything in active_runs)
		if(M in R.members)
			return R
	return null

/// Returns the run a given ckey currently belongs to, or null.
/datum/controller/subsystem/refraction_railway/proc/GetRunForCkey(ckey)
	if(!ckey)
		return null
	for(var/datum/refraction_run/R as anything in active_runs)
		for(var/mob/M as anything in R.members)
			if(M.ckey == ckey)
				return R
	return null

/// Returns the run with the given run_uid, or null. Used by the refraction
/// wave_controller to notify back into the run on CompleteWaves.
/datum/controller/subsystem/refraction_railway/proc/GetRunByUid(uid)
	if(!uid)
		return null
	for(var/datum/refraction_run/R as anything in active_runs)
		if(R.run_uid == uid)
			return R
	return null

/// Looks up cached stats for a mob; lazily extracts on miss. Mirrors the
/// extraction shape from code/modules/jobs/job_types/rcorp/factory/combat_log_book.dm.
/datum/controller/subsystem/refraction_railway/proc/GetMobStats(mob_type)
	if(!ispath(mob_type))
		return null
	var/list/cached = mob_stats_cache[mob_type]
	if(cached)
		return cached
	cached = ExtractMobStats(mob_type)
	if(cached)
		mob_stats_cache[mob_type] = cached
	return cached

/// Spawns a temp instance in nullspace, reads vars, qdels, returns the data list.
/datum/controller/subsystem/refraction_railway/proc/ExtractMobStats(mob_type)
	if(!ispath(mob_type, /mob/living/simple_animal/hostile))
		return null
	var/mob/living/simple_animal/hostile/H = new mob_type(null)
	var/list/data = list()
	data["type"] = H.type
	data["name"] = H.name
	data["icon"] = icon2base64(getFlatIcon(H))
	data["health"] = H.maxHealth
	data["max_health"] = H.maxHealth
	data["move_to_delay"] = H.move_to_delay
	data["melee_damage_lower"] = H.melee_damage_lower
	data["melee_damage_upper"] = H.melee_damage_upper
	data["melee_damage_type"] = H.melee_damage_type
	var/list/resistances = list()
	if(H.damage_coeff)
		var/datum/dam_coeff/DC = H.damage_coeff
		resistances["red"] = DC.red
		resistances["white"] = DC.white
		resistances["black"] = DC.black
		resistances["pale"] = DC.pale
	else
		resistances["red"] = 1
		resistances["white"] = 1
		resistances["black"] = 1
		resistances["pale"] = 1
	data["resistances"] = resistances
	if(H.rapid_melee > 1)
		data["rapid_melee"] = H.rapid_melee
	else if(H.attack_cooldown > 0)
		data["attack_cooldown"] = H.attack_cooldown
	else
		data["rapid_melee"] = 1
	if(H.casingtype)
		var/obj/item/ammo_casing/casing = new H.casingtype
		if(casing.projectile_type)
			var/obj/projectile/P = new casing.projectile_type
			data["ranged_damage"] = P.damage
			data["ranged_damage_type"] = P.damage_type
			qdel(P)
		qdel(casing)
		data["is_ranged"] = TRUE
		data["ranged_cooldown_time"] = H.ranged_cooldown_time
		if(H.rapid > 0)
			data["rapid"] = H.rapid
			data["rapid_fire_delay"] = H.rapid_fire_delay
	else if(H.projectiletype)
		var/obj/projectile/P = new H.projectiletype
		data["ranged_damage"] = P.damage
		data["ranged_damage_type"] = P.damage_type
		qdel(P)
		data["is_ranged"] = TRUE
		data["ranged_cooldown_time"] = H.ranged_cooldown_time
		if(H.rapid > 0)
			data["rapid"] = H.rapid
			data["rapid_fire_delay"] = H.rapid_fire_delay
	else
		data["is_ranged"] = FALSE
	qdel(H)
	return data

/// Returns the damage type with the highest multiplier in the resistances list,
/// or "Even" if all four are equal. Used for the unrevealed mob card weakness label.
/datum/controller/subsystem/refraction_railway/proc/DerivedDamageWeakness(list/resistances)
	if(!islist(resistances))
		return "Even"
	var/highest = -INFINITY
	var/winner = null
	var/all_same = TRUE
	var/seen = null
	for(var/k in resistances)
		var/v = resistances[k]
		if(seen == null)
			seen = v
		else if(v != seen)
			all_same = FALSE
		if(v > highest)
			highest = v
			winner = k
	if(all_same)
		return "Even"
	return winner

/// Records a finished run on the leaderboard for that line. Top 10 ascending.
/datum/controller/subsystem/refraction_railway/proc/RecordRun(line_id, list/entry)
	if(!line_id || !islist(entry))
		return
	var/list/board = leaderboards[line_id]
	if(!islist(board))
		board = list()
	board += list(entry)
	sortTim(board, cmp = GLOBAL_PROC_REF(cmp_refraction_entry_asc))
	if(length(board) > 10)
		board.Cut(11)
	leaderboards[line_id] = board

/// Marks the given mob types as encountered for every live ckey in the list.
/datum/controller/subsystem/refraction_railway/proc/MarkEncountered(list/ckeys, list/mob_types)
	if(!islist(ckeys) || !islist(mob_types))
		return
	for(var/ckey in ckeys)
		var/list/seen = encountered_mobs[ckey]
		if(!islist(seen))
			seen = list()
		seen |= mob_types
		encountered_mobs[ckey] = seen

/proc/cmp_refraction_entry_asc(list/A, list/B)
	return A["time_ds"] - B["time_ds"]

// ---------- Lane management ----------

/// Returns a z-level for `run` to use (claims an existing free same-line lane,
/// or loads a new z and registers it). Returns 0 on failure. After the lane
/// is bound, every refraction wave landmark on the z is re-stamped with a
/// per-run controller_id and rebound to a fresh refraction wave_controller.
/datum/controller/subsystem/refraction_railway/proc/ClaimLane(datum/refraction_line/line, datum/refraction_run/run)
	if(!istype(line) || !istype(run))
		return 0
	if(!line.map_path)
		return 0
	for(var/list/lane as anything in loaded_lanes)
		if(lane["map_path"] != line.map_path)
			continue
		if(lane["claimed_by"])
			continue
		lane["claimed_by"] = run
		run.loaded_z = lane["z"]
		RestampWaveLandmarks(run)
		return lane["z"]
	var/new_z = LoadLineZ(line)
	if(!new_z)
		return 0
	loaded_lanes += list(list(
		"map_path"   = line.map_path,
		"z"          = new_z,
		"claimed_by" = run,
	))
	run.loaded_z = new_z
	RestampWaveLandmarks(run)
	return new_z

/// Marks the lane at `z` as free again. Lane entry persists for the round so a
/// later same-line claim can reuse it without reloading the dmm. Captures the
/// prior run's uid so ResetLaneState can clean its namespaced controllers.
/datum/controller/subsystem/refraction_railway/proc/ReleaseLane(z)
	if(!z)
		return
	for(var/list/lane as anything in loaded_lanes)
		if(lane["z"] != z)
			continue
		var/datum/refraction_run/old_run = lane["claimed_by"]
		var/old_uid = old_run?.run_uid
		lane["claimed_by"] = null
		ResetLaneState(z, old_uid)
		return

/// Builds one refraction_wave_controller per /datum/refraction_node defined
/// on the run's line, then binds every /obj/effect/landmark/refraction/spawn
/// on the run's z whose `landmark_id` matches the node's `landmark_id` as a
/// spawn point. The controller's id is namespaced
/// "refraction_<run_uid>_<node.id>" so concurrent runs don't collide.
/datum/controller/subsystem/refraction_railway/proc/RestampWaveLandmarks(datum/refraction_run/run)
	if(!istype(run) || !run.loaded_z)
		return
	if(!islist(run.line?.combat_nodes))
		return
	var/run_uid = run.run_uid

	for(var/node_id in run.line.combat_nodes)
		var/datum/refraction_node/N = run.line.combat_nodes[node_id]
		if(!istype(N))
			continue
		var/controller_id = "refraction_[run_uid]_[N.id]"
		var/datum/refraction_wave_controller/C = new(controller_id)
		C.run_uid = run_uid
		C.room_id = N.id
		C.node = N
		for(var/obj/effect/landmark/refraction/spawn/L in GLOB.landmarks_list)
			if(L.z != run.loaded_z)
				continue
			if(L.landmark_id != N.landmark_id)
				continue
			C.RegisterLandmark(L)

/// Per-lane cleanup between claims: qdel every refraction_wave_controller
/// bound to the prior run's namespace. Living mobs are qdel'd by the
/// controller's own Destroy(). Landmarks are passive position markers so
/// they need no per-lane state reset.
/datum/controller/subsystem/refraction_railway/proc/ResetLaneState(z, old_uid)
	if(!z)
		return
	if(old_uid)
		var/prefix = "refraction_[old_uid]_"
		var/list/to_delete = list()
		for(var/datum/refraction_wave_controller/C as anything in GLOB.refraction_wave_controllers)
			if(findtext(C.id, prefix) == 1)
				to_delete += C
		for(var/datum/refraction_wave_controller/C as anything in to_delete)
			qdel(C)

/// Loads the line's dmm onto a new z and returns the assigned z-level integer,
/// or 0 on failure. Mirrors `load_new_z_level` (code/modules/mapping/map_template.dm:185)
/// but captures `space_level.z_value` from the inner `load_new_z()` call.
/datum/controller/subsystem/refraction_railway/proc/LoadLineZ(datum/refraction_line/line)
	if(!line || !line.map_path)
		return 0
	var/datum/map_template/template = new(line.map_path, line.id)
	var/datum/space_level/level = template.load_new_z()
	return level?.z_value || 0

