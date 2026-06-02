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
	/// mob_type (path) -> list of assoc achievement entries (id/name/desc/reward/default_state).
	var/list/mob_achievements = list()
	/// Flat lookup for achievement entries by id, populated alongside mob_achievements.
	var/list/achievements_by_id = list()
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
	/// Forbid re-using EGO weapons/armor across sectors of the same run.
	/// Default ON at the SS level — per-line override is the authoring control.
	var/unique_loadout_per_sector = TRUE

/datum/controller/subsystem/refraction_railway/Initialize()
	InitializeLines()
	InitializeMobTips()
	InitializeMobPassives()
	InitializeMobAttacks()
	InitializeMobAchievements()
	SSpersistence.LoadRefractionLeaderboards()
	SSpersistence.LoadRefractionEncounters()
	SSpersistence.LoadRefractionStarlight()
	// Warm the mob-card cache in the background so the first hub-console
	// open doesn't pay for ~20 getFlatIcon + base64 encodes all at once.
	INVOKE_ASYNC(src, PROC_REF(PrewarmMobCards))
	return ..()

/// Pre-extracts stats (and the expensive flat-icon snapshot) for every mob
/// any line previews. Runs once, yielding between mobs so it never stalls
/// a tick. By the time a player reaches the console the cache is hot.
/datum/controller/subsystem/refraction_railway/proc/PrewarmMobCards()
	var/list/seen = list()
	for(var/id in lines)
		var/datum/refraction_line/L = lines[id]
		if(!istype(L) || !islist(L.combat_nodes))
			continue
		for(var/node_id in L.combat_nodes)
			var/datum/refraction_node/N = L.combat_nodes[node_id]
			if(!istype(N))
				continue
			for(var/mob_path in N.mob_stock)
				if(seen[mob_path])
					continue
				seen[mob_path] = TRUE
				GetMobStats(mob_path)
				CHECK_TICK
			for(var/mob_path in N.extra_preview_mobs)
				if(seen[mob_path])
					continue
				seen[mob_path] = TRUE
				GetMobStats(mob_path)
				CHECK_TICK

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
	// Re-key in display-name order so the hub sidebar lists "Line 1: ..."
	// above "Line 2: ..." regardless of subtype iteration order.
	var/list/sorted = list()
	for(var/id in lines)
		sorted += lines[id]
	sortTim(sorted, GLOBAL_PROC_REF(cmp_name_asc))
	lines = list()
	for(var/datum/refraction_line/L in sorted)
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

/// Merges every line's GetMobAchievements() into mob_achievements +
/// achievements_by_id. Entries collide on either the mob path or the
/// achievement id; first registration wins, the duplicate is dropped
/// with a stack trace.
/datum/controller/subsystem/refraction_railway/proc/InitializeMobAchievements()
	mob_achievements = list()
	achievements_by_id = list()
	var/list/mob_owners = list()
	var/list/id_owners = list()
	for(var/id in lines)
		var/datum/refraction_line/L = lines[id]
		var/list/contributions = L.GetMobAchievements()
		if(!islist(contributions))
			continue
		for(var/mob_path in contributions)
			if(mob_achievements[mob_path])
				stack_trace("Refraction achievement collision: line '[L.id]' \
					tried to register achievements for [mob_path], but line \
					'[mob_owners[mob_path]]' already owns it. Ignoring.")
				continue
			var/list/entries = contributions[mob_path]
			if(!islist(entries))
				continue
			mob_achievements[mob_path] = entries
			mob_owners[mob_path] = L.id
			for(var/list/entry as anything in entries)
				if(!islist(entry))
					continue
				var/aid = entry["id"]
				if(!aid)
					continue
				if(achievements_by_id[aid])
					stack_trace("Refraction achievement id collision: line \
						'[L.id]' tried to register id '[aid]', but line \
						'[id_owners[aid]]' already owns it. Ignoring.")
					continue
				achievements_by_id[aid] = entry
				id_owners[aid] = L.id

/datum/controller/subsystem/refraction_railway/fire(resumed = FALSE)
	for(var/datum/refraction_run/R as anything in active_runs)
		R.Tick(wait)

/// Returns the run that currently owns the given z-level, or null. Boss
/// mobs spawned on a refraction line z use this to find their run for
/// achievement-state writes without walking the members list.
/proc/FindRefractionRunForZ(z)
	if(!z)
		return null
	for(var/datum/refraction_run/R as anything in SSrefraction_railway.active_runs)
		if(R.loaded_z == z)
			return R
	return null

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
	// Some mobs (Stone Keeper, keeper_piller) default to alpha=0 for an
	// entrance-fall cutscene, which would snapshot the card as an invisible
	// PNG. Force a fully opaque, on-ground render for the card icon.
	H.alpha = 255
	H.pixel_z = 0
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

/// Builds every leaderboard's UI-ready payload, with per-sector loadout
/// icons rendered. Shared between the Hub console and the per-sector
/// advance console so both surfaces show the same icon-rich records.
/datum/controller/subsystem/refraction_railway/proc/BuildLeaderboardsPayload()
	var/list/out = list()
	for(var/line_id in leaderboards)
		out[line_id] = BuildLeaderboardPayload(line_id)
	return out

/// Returns one line's leaderboard as a list of UI-ready entries.
/datum/controller/subsystem/refraction_railway/proc/BuildLeaderboardPayload(line_id)
	var/list/entries_out = list()
	var/list/board = leaderboards[line_id]
	if(!islist(board))
		return entries_out
	for(var/list/entry as anything in board)
		entries_out += list(BuildLeaderboardEntryPayload(entry))
	return entries_out

/datum/controller/subsystem/refraction_railway/proc/BuildLeaderboardEntryPayload(list/entry)
	if(!islist(entry))
		return list()
	var/list/sectors_in = entry["sectors"]
	var/list/sectors_out = list()
	if(islist(sectors_in))
		for(var/list/sector as anything in sectors_in)
			var/list/players_in = sector["players"]
			var/list/players_out = list()
			if(islist(players_in))
				for(var/list/p as anything in players_in)
					players_out += list(list(
						"ckey"          = p["ckey"],
						"name"          = p["name"],
						"loadout_icons" = LoadoutIconsForPaths(p["loadout"]),
					))
			sectors_out += list(list(
				"index"   = sector["index"],
				"time_ds" = sector["time_ds"],
				"players" = players_out,
				"rooms"   = islist(sector["rooms"]) ? sector["rooms"].Copy() : list(),
			))
	return list(
		"ckey"     = entry["ckey"],
		"name"     = entry["name"],
		"time_ds"  = entry["time_ds"],
		"members"  = entry["members"],
		"sectors"  = sectors_out,
	)

/datum/controller/subsystem/refraction_railway/proc/LoadoutIconsForPaths(list/paths)
	var/list/icons = list(null, null, null)
	if(!islist(paths))
		return icons
	for(var/i in 1 to min(3, length(paths)))
		var/p = paths[i]
		// Post-JSON entries arrive as strings; in-memory ones are real paths.
		if(istext(p))
			p = text2path(p)
		if(!ispath(p))
			continue
		icons[i] = SStestrange.GenerateEgoPreviewIcon(p)
	return icons

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

/// TRUE if the given ckey has ever finished any refraction-railway line
/// (i.e. appears on any leaderboard). Used by the Star Memories door to
/// gate access to the hidden room.
/datum/controller/subsystem/refraction_railway/proc/HasCkeyCompletedAnyLine(ckey)
	if(!ckey)
		return FALSE
	for(var/line_id in leaderboards)
		var/list/board = leaderboards[line_id]
		if(!islist(board))
			continue
		for(var/list/entry as anything in board)
			if(entry["ckey"] == ckey)
				return TRUE
	return FALSE

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
		C.line = run.line
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

// ---------- Starlight progression ----------

/// Returns the live entry for `ckey`, creating an empty one if missing.
/datum/controller/subsystem/refraction_railway/proc/GetOrCreateStarlightEntry(ckey)
	if(!ckey)
		return null
	var/list/entry = SSpersistence.starlight_data[ckey]
	if(!islist(entry))
		entry = list("balance" = 0, "unlocked" = list(), "completed_lines" = list())
		SSpersistence.starlight_data[ckey] = entry
	if(!islist(entry["unlocked"]))
		entry["unlocked"] = list()
	if(!islist(entry["completed_lines"]))
		entry["completed_lines"] = list()
	if(isnull(entry["balance"]))
		entry["balance"] = 0
	return entry

/datum/controller/subsystem/refraction_railway/proc/GetStarlight(ckey)
	var/list/entry = SSpersistence.starlight_data[ckey]
	return islist(entry) ? (entry["balance"] || 0) : 0

/datum/controller/subsystem/refraction_railway/proc/GetUnlockedQuirks(ckey)
	var/list/entry = SSpersistence.starlight_data[ckey]
	if(!islist(entry))
		return list()
	var/list/unlocked = entry["unlocked"]
	return islist(unlocked) ? unlocked.Copy() : list()

/datum/controller/subsystem/refraction_railway/proc/IsQuirkUnlocked(ckey, quirk_name)
	if(!ckey || !quirk_name)
		return FALSE
	var/list/entry = SSpersistence.starlight_data[ckey]
	if(!islist(entry))
		return FALSE
	var/list/unlocked = entry["unlocked"]
	return islist(unlocked) && (quirk_name in unlocked)

/datum/controller/subsystem/refraction_railway/proc/HasCompletedLine(ckey, line_id)
	if(!ckey || !line_id)
		return FALSE
	var/list/entry = SSpersistence.starlight_data[ckey]
	if(!islist(entry))
		return FALSE
	var/list/done = entry["completed_lines"]
	return islist(done) && (line_id in done)

/datum/controller/subsystem/refraction_railway/proc/MarkLineCompleted(ckey, line_id)
	if(!ckey || !line_id)
		return
	var/list/entry = GetOrCreateStarlightEntry(ckey)
	if(!entry)
		return
	var/list/done = entry["completed_lines"]
	if(!(line_id in done))
		done += line_id
		SSpersistence.SaveRefractionStarlight()

/datum/controller/subsystem/refraction_railway/proc/AwardStarlight(ckey, amount)
	if(!ckey || amount == 0)
		return
	var/list/entry = GetOrCreateStarlightEntry(ckey)
	if(!entry)
		return
	// Allow negative deductions (slow runs), but never let the balance
	// roll below zero — a bad run zeroes out, doesn't accumulate debt.
	entry["balance"] = max(0, (entry["balance"] || 0) + amount)
	SSpersistence.SaveRefractionStarlight()

/// Combined locks check used by the picker, server-side gate, and shop. TRUE iff:
///   - The quirk isn't `starlight_locked`, OR the ckey has purchased it.
///   - AND the quirk has no `required_line_completed`, OR the ckey has finished it.
/datum/controller/subsystem/refraction_railway/proc/IsQuirkAvailable(ckey, quirk_name)
	if(!quirk_name)
		return TRUE
	var/datum/quirk/Q = SSquirks.quirks[quirk_name]
	if(!Q)
		return TRUE
	if(initial(Q.starlight_locked) && !IsQuirkUnlocked(ckey, quirk_name))
		return FALSE
	var/req_line = initial(Q.required_line_completed)
	if(req_line)
		if(!HasCompletedLine(ckey, req_line))
			return FALSE
		var/datum/refraction_line/RL = lines[req_line]
		if(istype(RL) && RL.locked)
			return FALSE
	return TRUE

/// Spends starlight to permanently unlock a quirk for `ckey`. Returns TRUE on success.
/datum/controller/subsystem/refraction_railway/proc/PurchaseQuirk(ckey, quirk_name)
	if(!ckey || !quirk_name)
		return FALSE
	var/datum/quirk/Q = SSquirks.quirks[quirk_name]
	if(!Q || !initial(Q.starlight_locked))
		return FALSE
	if(IsQuirkUnlocked(ckey, quirk_name))
		return FALSE
	var/cost = initial(Q.starlight_cost)
	if(cost < 0)
		return FALSE
	var/req_line = initial(Q.required_line_completed)
	if(req_line)
		if(!HasCompletedLine(ckey, req_line))
			return FALSE
		var/datum/refraction_line/RL = lines[req_line]
		if(istype(RL) && RL.locked)
			return FALSE
	var/list/entry = GetOrCreateStarlightEntry(ckey)
	if(!entry)
		return FALSE
	var/balance = entry["balance"] || 0
	if(balance < cost)
		return FALSE
	entry["balance"] = balance - cost
	var/list/unlocked = entry["unlocked"]
	unlocked |= quirk_name
	SSpersistence.SaveRefractionStarlight()
	return TRUE

