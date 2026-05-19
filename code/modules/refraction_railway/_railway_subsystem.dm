/*
 * Refraction Railway subsystem: line registry, active runs, leaderboards,
 * encountered-mob sets, mob-stat cache, mob tips/passives/attacks.
 */

#define LOBBY_OPEN     "lobby_open"
/// Owner clicked Start; lobby mutation refused until load finishes or fails.
#define LOBBY_STARTING "lobby_starting"
#define LOBBY_RUNNING  "lobby_running"
#define LOBBY_FINISHED "lobby_finished"

GLOBAL_VAR_INIT(refraction_run_uid_counter, 0)

SUBSYSTEM_DEF(refraction_railway)
	name = "Refraction Railway"
	flags = SS_KEEP_TIMING | SS_BACKGROUND
	wait = 1 SECONDS
	init_order = -71

	/// id (string) -> /datum/refraction_line.
	var/list/lines = list()
	var/list/active_runs = list()
	/// line_id (string) -> list of run records, sorted ascending by time_ds.
	var/list/leaderboards = list()
	/// ckey (string) -> list of mob type-paths the player has fought.
	var/list/encountered_mobs = list()
	var/list/mob_stats_cache = list()
	var/list/mob_tips = list()
	/// mob_type (path) -> list of assoc passive entries (title/severity/text).
	var/list/mob_passives = list()
	/// mob_type (path) -> list of assoc attack entries (name/damage/cooldown/desc).
	var/list/mob_attacks = list()
	/// One entry per loaded line dmm: list(map_path, z, claimed_by). Persists for the round.
	var/list/loaded_lanes = list()
	/// VV debug flag: treat every mob as encountered for every player.
	var/debug_reveal_all = FALSE
	// Party-size compensation toggles. Take effect on the next activation/spawn batch.
	/// Per-mob-type stock multiplier.
	var/scale_stock = TRUE
	/// Concurrent-alive cap multiplier.
	var/scale_concurrent = TRUE
	/// Per-cycle spawn batch = num_players; OFF means 1 per cycle.
	var/scale_spawn_batch = TRUE
	/// Non-boss per-mob HP/damage scaling.
	var/scale_wave_stats = TRUE
	/// Boss per-mob HP scaling (HP only, never damage).
	var/scale_boss_stats = TRUE
	/// Compensation medipens for smaller parties each sector.
	var/give_compensation_pens = TRUE

/datum/controller/subsystem/refraction_railway/Initialize()
	InitializeLines()
	InitializeMobTips()
	InitializeMobPassives()
	InitializeMobAttacks()
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
	mob_tips = list()

/// Merges every line's GetMobPassives() into mob_passives; first registration wins.
/datum/controller/subsystem/refraction_railway/proc/InitializeMobPassives()
	mob_passives = list()
	var/list/owners = list()
	for(var/id in lines)
		var/datum/refraction_line/L = lines[id]
		var/list/contributions = L.GetMobPassives()
		if(!islist(contributions))
			continue
		for(var/mob_path in contributions)
			if(mob_passives[mob_path])
				stack_trace("Refraction passive collision: line '[L.id]' tried to register \
					passives for [mob_path], but line '[owners[mob_path]]' already owns it. \
					Ignoring the duplicate.")
				continue
			mob_passives[mob_path] = contributions[mob_path]
			owners[mob_path] = L.id

/// Merges every line's GetMobAttacks() into mob_attacks; first registration wins.
/datum/controller/subsystem/refraction_railway/proc/InitializeMobAttacks()
	mob_attacks = list()
	var/list/owners = list()
	for(var/id in lines)
		var/datum/refraction_line/L = lines[id]
		var/list/contributions = L.GetMobAttacks()
		if(!islist(contributions))
			continue
		for(var/mob_path in contributions)
			if(mob_attacks[mob_path])
				stack_trace("Refraction attack collision: line '[L.id]' tried to register \
					attacks for [mob_path], but line '[owners[mob_path]]' already owns it. \
					Ignoring the duplicate.")
				continue
			mob_attacks[mob_path] = contributions[mob_path]
			owners[mob_path] = L.id

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

/// Returns the run with the given run_uid, or null.
/datum/controller/subsystem/refraction_railway/proc/GetRunByUid(uid)
	if(!uid)
		return null
	for(var/datum/refraction_run/R as anything in active_runs)
		if(R.run_uid == uid)
			return R
	return null

/// Looks up cached stats for a mob; lazily extracts on miss.
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
	data["icon"] = icon2base64(getFlatIcon(H, no_anim = TRUE))
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

/// Returns the damage type with the highest resistance multiplier, or "Even".
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

/// Returns TRUE if `mob_path` should be shown revealed for this ckey.
/datum/controller/subsystem/refraction_railway/proc/IsMobRevealed(ckey, mob_path)
	if(debug_reveal_all)
		return TRUE
	if(!ckey)
		return FALSE
	var/list/seen = encountered_mobs[ckey]
	return islist(seen) && (mob_path in seen)

/// Returns the mob-card payload: full stats+tip if revealed, else a silhouette.
/datum/controller/subsystem/refraction_railway/proc/BuildMobCardPayload(ckey, mob_path)
	var/list/stats = GetMobStats(mob_path)
	if(!islist(stats))
		return list(
			"path"     = "[mob_path]",
			"revealed" = FALSE,
			"missing"  = TRUE,
		)
	if(IsMobRevealed(ckey, mob_path))
		var/list/payload = stats.Copy()
		payload["path"] = "[mob_path]"
		payload["revealed"] = TRUE
		var/tip = mob_tips[mob_path]
		if(tip)
			payload["tip"] = tip
		var/list/attacks = mob_attacks[mob_path]
		if(islist(attacks) && length(attacks))
			payload["attacks"] = attacks
		var/list/passives = mob_passives[mob_path]
		if(islist(passives) && length(passives))
			payload["passives"] = passives
		return payload
	var/list/payload = list(
		"path"              = "[mob_path]",
		"revealed"          = FALSE,
		"icon"              = stats["icon"],
		"melee_damage_type" = stats["melee_damage_type"],
		"weakness"          = DerivedDamageWeakness(stats["resistances"]),
	)
	if(stats["is_ranged"])
		payload["ranged_damage_type"] = stats["ranged_damage_type"]
	return payload

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

/// Returns a z-level for `run` (claims a free same-line lane or loads a new z). 0 on failure.
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

/// Marks the lane at `z` free again and resets its namespaced controllers.
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

/// Builds one namespaced wave controller per node and binds its matching spawners.
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
		for(var/obj/effect/landmark/refraction/spawner/L in GLOB.landmarks_list)
			if(L.z != run.loaded_z)
				continue
			if(L.id != N.landmark_id)
				continue
			C.RegisterLandmark(L)

/// Per-lane cleanup between claims: qdel the prior run's namespaced controllers.
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

/// Loads the line's dmm onto a new z; returns the z-level integer or 0 on failure.
/datum/controller/subsystem/refraction_railway/proc/LoadLineZ(datum/refraction_line/line)
	if(!line || !line.map_path)
		return 0
	// Snapshot+reset SSatoms.initialized_changed so a leaked non-zero value
	// doesn't corrupt the dmm load; restore it afterwards.
	var/saved_changed = SSatoms.initialized_changed
	var/saved_initialized = SSatoms.initialized
	if(saved_changed != 0)
		log_world("SSrefraction_railway: SSatoms.initialized_changed=[saved_changed] before load — resetting for safe maploading.")
		SSatoms.initialized_changed = 0
		SSatoms.initialized = INITIALIZATION_INNEW_REGULAR
	var/datum/map_template/template = new(line.map_path, line.id)
	var/datum/space_level/level = template.load_new_z()
	if(saved_changed != 0)
		SSatoms.initialized_changed = saved_changed
		SSatoms.initialized = saved_initialized
	return level?.z_value || 0

