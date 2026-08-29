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
/// TRUE only while ExtractMobStats spawns a throwaway prototype in nullspace
/// to read its card stats; suppresses simple_animal's nullspace warning.
GLOBAL_VAR_INIT(refraction_extracting_mob_stats, FALSE)

/// Runs whose `entry["timestamp"]` (world.realtime at RecordRun time) is
/// strictly less than this value are silently hidden from leaderboard
/// payloads. The cutoff is 2026-06-14 15:00 EDT (= 19:00 UTC), expressed
/// in deciseconds since 2000-01-01 (BYOND world.realtime epoch).
/// Computed as: 9661 days × 86400 s × 10 ds = 8,347,104,000 ds for
/// 2026-06-14 00:00 UTC, plus 19 hours × 3600 s × 10 ds = 684,000 ds
/// to land on 19:00 UTC. Total: 8,347,788,000 ds.
/// Pre-cutoff runs are still persisted on disk — only the render path
/// hides them. The UI explains the gap via the cutoff-notice text.
#define REFRACTION_LEADERBOARD_CUTOFF_DS 8347788000
#define REFRACTION_LEADERBOARD_CUTOFF_TEXT "3:00 PM EDT, Sunday June 14, 2026"

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
	/// ckey (string) -> list of event id strings the player has unlocked.
	/// Drives the per-card `hidden_until` field and the per-line
	/// silhouette gate (`GetMobSilhouetteGates()`).
	var/list/unlocked_events = list()
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
	// ---- Gacha ID skin registry (built in Initialize via BuildGachaRegistry) ----
	/// skin_id (string) → /datum/id_skin
	var/list/id_skins = list()
	/// banner_id (string) → /datum/gacha_banner
	var/list/gacha_banners = list()
	/// Global rarity pools — every skin in the game indexed by tier.
	/// Each banner rolls from these and applies its own highlight
	/// weighting on top.
	var/list/gacha_pool_0   = list()
	var/list/gacha_pool_00  = list()
	var/list/gacha_pool_000 = list()
	/// rarity bucket name ("gray"/"red"/"gold") → base64 PNG of the
	/// gatch_tear fracture sprite tinted to that bucket. Baked once at
	/// boot time and shipped raw via ui_data so the gacha shop can
	/// render fractures without per-open getFlatIcon calls.
	var/list/gacha_fracture_icons = list()
	/// Pulls a player must spend on a banner before the pity counter
	/// caps out — at which point any of that banner's highlight skins
	/// can be claimed for free. Cap, then reset on redemption.
	var/gacha_pity_threshold = 100

/datum/controller/subsystem/refraction_railway/Initialize()
	InitializeLines()
	InitializeMobTips()
	InitializeMobPassives()
	InitializeMobAttacks()
	InitializeMobAchievements()
	BuildGachaRegistry()
	SSpersistence.LoadRefractionLeaderboards()
	SSpersistence.LoadRefractionEncounters()
	SSpersistence.LoadRefractionEvents()
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
	GLOB.refraction_extracting_mob_stats = TRUE
	var/mob/living/simple_animal/hostile/H = new mob_type(null)
	GLOB.refraction_extracting_mob_stats = FALSE
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

/// Records a finished run on the leaderboard for that line. Top 50 ascending.
/datum/controller/subsystem/refraction_railway/proc/RecordRun(line_id, list/entry)
	if(!line_id || !islist(entry))
		return
	var/list/board = leaderboards[line_id]
	if(!islist(board))
		board = list()
	board += list(entry)
	sortTim(board, cmp = GLOBAL_PROC_REF(cmp_refraction_entry_asc))
	if(length(board) > 50)
		board.Cut(51)
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
/// Entries whose timestamp predates REFRACTION_LEADERBOARD_CUTOFF_DS
/// are silently skipped — pre-update runs sat under different balance
/// (station traits, meltdowns, etc.) and aren't meaningfully
/// comparable with current results.
/datum/controller/subsystem/refraction_railway/proc/BuildLeaderboardPayload(line_id)
	var/list/entries_out = list()
	var/list/board = leaderboards[line_id]
	if(!islist(board))
		return entries_out
	var/datum/refraction_line/line = lines[line_id]
	for(var/list/entry as anything in board)
		var/ts = entry["timestamp"]
		if(isnum(ts) && ts < REFRACTION_LEADERBOARD_CUTOFF_DS)
			continue
		entries_out += list(BuildLeaderboardEntryPayload(entry, line))
	return entries_out

/datum/controller/subsystem/refraction_railway/proc/BuildLeaderboardEntryPayload(list/entry, datum/refraction_line/line)
	if(!islist(entry))
		return list()
	var/list/sectors_in = entry["sectors"]
	var/list/sectors_out = list()
	// Cap output to the line's real sector count so historical entries
	// whose `sectors` lists were inflated by the OnSectionCleared
	// double-append bug don't surface the bogus rows in the UI.
	var/sector_cap = islist(sectors_in) ? length(sectors_in) : 0
	if(line && line.section_count > 0)
		sector_cap = min(sector_cap, line.section_count)
	if(islist(sectors_in))
		for(var/i in 1 to sector_cap)
			var/list/sector = sectors_in[i]
			if(!islist(sector))
				continue
			var/list/players_in = sector["players"]
			var/list/players_out = list()
			if(islist(players_in))
				for(var/list/p as anything in players_in)
					players_out += list(list(
						"ckey"          = p["ckey"],
						"name"          = p["name"],
						"loadout_icons" = LoadoutIconsForPaths(p["loadout"]),
					))
			var/list/rooms_in = sector["rooms"]
			sectors_out += list(list(
				"index"   = sector["index"],
				"time_ds" = sector["time_ds"],
				"players" = players_out,
				"rooms"   = islist(rooms_in) ? rooms_in.Copy() : list(),
			))
	var/raw_ts = entry["timestamp"]
	return list(
		"ckey"           = entry["ckey"],
		"name"           = entry["name"],
		"time_ds"        = entry["time_ds"],
		"members"        = entry["members"],
		"sectors"        = sectors_out,
		"timestamp"      = raw_ts,
		"timestamp_text" = raw_ts ? time2text(raw_ts, "YYYY-MM-DD hh:mm") : "",
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
/// Honors the per-line silhouette gate: even an encountered mob stays
/// silhouette until its gating event is unlocked.
/datum/controller/subsystem/refraction_railway/proc/IsMobRevealed(ckey, mob_path)
	if(debug_reveal_all)
		return TRUE
	if(!ckey)
		return FALSE
	var/list/seen = encountered_mobs[ckey]
	if(!islist(seen) || !(mob_path in seen))
		return FALSE
	var/gate_event = GetMobSilhouetteGate(mob_path)
	if(gate_event && !IsEventUnlocked(ckey, gate_event))
		return FALSE
	return TRUE

/// Returns the gating event id for a mob path by polling every registered
/// line's GetMobSilhouetteGates(), or null if none gates this mob.
/datum/controller/subsystem/refraction_railway/proc/GetMobSilhouetteGate(mob_path)
	for(var/datum/refraction_line/L as anything in lines)
		var/list/gates = L.GetMobSilhouetteGates()
		if(islist(gates) && gates[mob_path])
			return gates[mob_path]
	return null

/// Returns TRUE if `ckey` has unlocked `event_id`. debug_reveal_all
/// short-circuits to TRUE so VV testing reveals everything.
/datum/controller/subsystem/refraction_railway/proc/IsEventUnlocked(ckey, event_id)
	if(debug_reveal_all)
		return TRUE
	if(!ckey || !event_id)
		return FALSE
	var/list/seen = unlocked_events[ckey]
	return islist(seen) && (event_id in seen)

/// Marks `event_id` as unlocked for each ckey in `ckeys`. Persists to
/// disk if any new (ckey, event_id) pair was actually added.
/datum/controller/subsystem/refraction_railway/proc/MarkEventUnlocked(list/ckeys, event_id)
	if(!event_id || !islist(ckeys) || !length(ckeys))
		return
	var/dirty = FALSE
	for(var/ckey in ckeys)
		if(!ckey)
			continue
		var/list/seen = unlocked_events[ckey]
		if(!islist(seen))
			seen = list()
			unlocked_events[ckey] = seen
		if(!(event_id in seen))
			seen += event_id
			dirty = TRUE
	if(dirty)
		SSpersistence.SaveRefractionEvents()

/// Returns a copy of `cards` (assoc-list attack or passive entries)
/// where any entry whose `hidden_until` event is still locked is
/// replaced with a placeholder `list("hidden" = TRUE)` so the briefing
/// UI can render a locked slot in its position. Entries without a
/// `hidden_until` field pass through unchanged.
/datum/controller/subsystem/refraction_railway/proc/MaskGatedCards(list/cards, ckey)
	if(!islist(cards) || !length(cards))
		return cards
	var/list/result = list()
	for(var/list/card as anything in cards)
		var/event_id = card["hidden_until"]
		if(event_id && !IsEventUnlocked(ckey, event_id))
			result += list(list("hidden" = TRUE))
			continue
		result += list(card)
	return result

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
		var/list/attacks = MaskGatedCards(mob_attacks[mob_path], ckey)
		if(islist(attacks) && length(attacks))
			payload["attacks"] = attacks
		var/list/passives = MaskGatedCards(mob_passives[mob_path], ckey)
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

// ---------- Gacha ID-skin persistence ----------

/// skin_id → copies (int). Empty list if the ckey has never pulled.
/datum/controller/subsystem/refraction_railway/proc/GetUnlockedIdSkins(ckey)
	var/list/entry = SSpersistence.starlight_data[ckey]
	if(!islist(entry))
		return list()
	var/list/skins = entry["id_skins"]
	return islist(skins) ? skins.Copy() : list()

/datum/controller/subsystem/refraction_railway/proc/IsIdSkinUnlocked(ckey, skin_id)
	if(!ckey || !skin_id)
		return FALSE
	var/list/entry = SSpersistence.starlight_data[ckey]
	if(!islist(entry))
		return FALSE
	var/list/skins = entry["id_skins"]
	return islist(skins) && (skin_id in skins) && (skins[skin_id] > 0)

/datum/controller/subsystem/refraction_railway/proc/GetEquippedIdSkin(ckey)
	if(!ckey)
		return null
	var/list/entry = SSpersistence.starlight_data[ckey]
	if(!islist(entry))
		return null
	return entry["id_skin_equipped"]

/// Sets the equipped skin. Rejects if the ckey doesn't own it
/// (passing `null` always succeeds — "revert to default").
/datum/controller/subsystem/refraction_railway/proc/SetEquippedIdSkin(ckey, skin_id)
	if(!ckey)
		return FALSE
	if(skin_id && !IsIdSkinUnlocked(ckey, skin_id))
		return FALSE
	var/list/entry = GetOrCreateStarlightEntry(ckey)
	if(!entry)
		return FALSE
	entry["id_skin_equipped"] = skin_id
	SSpersistence.SaveRefractionStarlight()
	return TRUE

/// IDs pulled from the registry but kept here for one-shot refund matching.
GLOBAL_LIST_INIT(retired_id_skins, list("kenyan", "american"))

/// Refunds any owned retired ID skins at 500 Starlight per copy and strips
/// them from the ledger. Returns the number of copies refunded so the caller
/// can surface a chat note. Idempotent — second call on a clean ledger no-ops.
/datum/controller/subsystem/refraction_railway/proc/RefundRetiredIdSkins(ckey)
	if(!ckey)
		return 0
	var/list/entry = SSpersistence.starlight_data[ckey]
	if(!islist(entry))
		return 0
	var/list/owned = entry["id_skins"]
	if(!islist(owned))
		return 0
	var/refunded = 0
	for(var/skin_id in GLOB.retired_id_skins)
		var/copies = owned[skin_id]
		if(isnull(copies) || copies <= 0)
			continue
		refunded += copies
		owned -= skin_id
	if(!refunded)
		return 0
	if(entry["id_skin_equipped"] in GLOB.retired_id_skins)
		entry["id_skin_equipped"] = null
	AwardStarlight(ckey, refunded * 500)
	return refunded

/// Dupe-refund value per rarity tier.
/datum/controller/subsystem/refraction_railway/proc/GachaDupeRefund(rarity)
	switch(rarity)
		if("0")
			return 5
		if("00")
			return 15
		if("000")
			return 50
	return 0

/// Cost in Starlight for an N-pull (1 or 10). Anything else returns 0
/// so the caller can detect a bad input.
/datum/controller/subsystem/refraction_railway/proc/GachaPullCost(count)
	switch(count)
		if(1)
			return 50
		if(10)
			return 500
	return 0

/// Resolves a pull request. Returns null on rejection (bad banner,
/// insufficient SL, no count match). Otherwise returns a list of
/// per-pull result blobs:
///   list("skin_id" = ..., "rarity" = "0"|"00"|"000",
///        "was_duplicate" = TRUE/FALSE, "dupe_refund" = <int>,
///        "stealth_lucky" = TRUE/FALSE)
/// stealth_lucky marks a 000 pull where the front-of-house golden
/// reveal flag did NOT fire (25% of 000s — the surprise pull-back).
/datum/controller/subsystem/refraction_railway/proc/PullGacha(mob/living/user, banner_id, count)
	if(!user?.ckey)
		return null
	var/datum/gacha_banner/B = gacha_banners[banner_id]
	if(!istype(B))
		return null
	if(count != 1 && count != 10)
		return null
	var/cost = GachaPullCost(count)
	if(GetStarlight(user.ckey) < cost)
		return null
	// Deduct up front so we can't double-spend on a race.
	AwardStarlight(user.ckey, -cost)
	AddGachaPity(user.ckey, banner_id, count)
	var/list/entry = GetOrCreateStarlightEntry(user.ckey)
	if(!islist(entry["id_skins"]))
		entry["id_skins"] = list()
	var/list/owned = entry["id_skins"]
	var/list/results = list()
	var/has_high_tier = FALSE
	for(var/i in 1 to count)
		var/list/roll_result = RollSingleGacha(B)
		results += list(roll_result)
		if(roll_result["rarity"] != "0")
			has_high_tier = TRUE
	// 10-pull guarantee: at least one 00+. If nothing landed, overwrite slot 10
	// with a weighted 00 pick so the banner's highlights still get their boost.
	if(count == 10 && !has_high_tier && length(gacha_pool_00))
		var/forced = RollFromPoolWeighted(B, "00")
		if(forced)
			results[10] = list(
				"skin_id" = forced,
				"rarity" = "00",
				"was_duplicate" = FALSE,
				"dupe_refund" = 0,
				"stealth_lucky" = FALSE,
			)
	// Pass 2: apply dupe accounting + refunds.
	var/total_refund = 0
	for(var/list/r as anything in results)
		var/skin_id = r["skin_id"]
		if(skin_id in owned)
			r["was_duplicate"] = TRUE
			r["dupe_refund"] = GachaDupeRefund(r["rarity"])
			owned[skin_id] = (owned[skin_id] || 0) + 1
			total_refund += r["dupe_refund"]
		else
			owned[skin_id] = 1
	if(total_refund > 0)
		AwardStarlight(user.ckey, total_refund)
	// Pass 3: decorate with the skin's display data so the UI doesn't
	// need to cross-reference banner state to render the reveal.
	for(var/list/r as anything in results)
		var/datum/id_skin/S = id_skins[r["skin_id"]]
		if(istype(S))
			r["name"] = S.name
			r["icon_data"] = S.icon_data
	SSpersistence.SaveRefractionStarlight()
	return results

/// Returns the player's current pity counter for `banner_id` (0 if
/// they've never pulled on this banner).
/datum/controller/subsystem/refraction_railway/proc/GetGachaPity(ckey, banner_id)
	if(!ckey || !banner_id)
		return 0
	var/list/entry = SSpersistence?.starlight_data?[ckey]
	if(!islist(entry))
		return 0
	var/list/pity_map = entry["gacha_pity"]
	if(!islist(pity_map))
		return 0
	return pity_map[banner_id] || 0

/// Increments the player's pity counter on `banner_id` by `amount`,
/// capping at the threshold. Saves immediately so progress survives a
/// crash mid-round.
/datum/controller/subsystem/refraction_railway/proc/AddGachaPity(ckey, banner_id, amount)
	if(!ckey || !banner_id || amount <= 0)
		return
	var/list/entry = GetOrCreateStarlightEntry(ckey)
	var/list/pity_map = entry["gacha_pity"]
	if(!islist(pity_map))
		pity_map = list()
		entry["gacha_pity"] = pity_map
	var/current = pity_map[banner_id] || 0
	pity_map[banner_id] = min(current + amount, gacha_pity_threshold)
	SSpersistence.SaveRefractionStarlight()

/// Spends a full pity counter to grant a chosen highlight skin. Returns
/// the result blob shaped like a single pull (so the UI can stash it
/// into pending_pull and reuse the results screen) on success, or null
/// on rejection (no banner, not enough pity, skin not a highlight).
/datum/controller/subsystem/refraction_railway/proc/RedeemGachaPity(mob/user, banner_id, skin_id)
	if(!user?.ckey || !banner_id || !skin_id)
		return null
	var/datum/gacha_banner/B = gacha_banners[banner_id]
	if(!istype(B))
		return null
	if(!(skin_id in B.highlight_skin_ids))
		return null
	var/datum/id_skin/picked = id_skins[skin_id]
	if(!istype(picked))
		return null
	if(GetGachaPity(user.ckey, banner_id) < gacha_pity_threshold)
		return null
	var/list/entry = GetOrCreateStarlightEntry(user.ckey)
	if(!islist(entry["id_skins"]))
		entry["id_skins"] = list()
	var/list/owned = entry["id_skins"]
	var/was_dup = !isnull(owned[skin_id])
	var/refund = 0
	if(was_dup)
		refund = GachaDupeRefund(picked.rarity)
		owned[skin_id] = (owned[skin_id] || 0) + 1
		if(refund > 0)
			AwardStarlight(user.ckey, refund)
	else
		owned[skin_id] = 1
	var/list/pity_map = entry["gacha_pity"]
	if(islist(pity_map))
		pity_map[banner_id] = 0
	SSpersistence.SaveRefractionStarlight()
	return list(
		"skin_id"       = skin_id,
		"rarity"        = picked.rarity,
		"name"          = picked.name,
		"icon_data"     = picked.icon_data,
		"was_duplicate" = was_dup,
		"dupe_refund"   = refund,
		"stealth_lucky" = FALSE,
	)

/// Returns the global pool list for the given rarity, or null if the
/// rarity string is unknown.
/datum/controller/subsystem/refraction_railway/proc/GachaPoolForRarity(rarity)
	switch(rarity)
		if("0")
			return gacha_pool_0
		if("00")
			return gacha_pool_00
		if("000")
			return gacha_pool_000
	return null

/// Picks one skin_id from the global `rarity` pool, respecting the
/// banner's highlight rules:
///   * For 000 rolls, the result is pinned to the banner's 000
///     highlights (uniform among them). The banner's "guaranteed
///     featured 000" is the headline reason to gamble on a specific
///     pool. Falls through to the base 000 pool if the banner has
///     none.
///   * For lower tiers, highlights just get a 2x roll weight on top
///     of the base pool — every other skin still has a real chance.
/// Returns null if the pool is empty.
/datum/controller/subsystem/refraction_railway/proc/RollFromPoolWeighted(datum/gacha_banner/B, rarity)
	var/list/pool = GachaPoolForRarity(rarity)
	if(!islist(pool) || !length(pool))
		return null
	var/list/highlights_for_tier = list()
	if(istype(B) && islist(B.highlight_skin_ids))
		for(var/skin_id in B.highlight_skin_ids)
			var/datum/id_skin/S = id_skins[skin_id]
			if(istype(S) && S.rarity == rarity && (skin_id in pool))
				highlights_for_tier += skin_id
	if(rarity == "000" && length(highlights_for_tier))
		return pick(highlights_for_tier)
	if(!length(highlights_for_tier))
		return pick(pool)
	// Each pool entry counts once; highlights get an extra duplicate
	// appended (total 2x weight) — straightforward weighted pick.
	var/list/weighted = pool.Copy()
	for(var/h in highlights_for_tier)
		weighted += h
	return pick(weighted)

/// Single-roll resolver: picks a rarity bucket from the fixed rate
/// table, then weight-rolls a skin from the global pool of that
/// rarity (banner highlights at 2x). Returns the per-pull result blob
/// (no dupe accounting yet — that's applied in pass 2 inside PullGacha).
/datum/controller/subsystem/refraction_railway/proc/RollSingleGacha(datum/gacha_banner/B)
	// Fixed-point 1–1000 roll. Buckets:
	//   1–29     → 000  (2.9%)
	//   30–157   → 00   (12.8%)
	//   158–1000 → 0    (catches the 1.3% residue too)
	var/roll = rand(1, 1000)
	var/rarity = "0"
	if(roll <= 29 && length(gacha_pool_000))
		rarity = "000"
	else if(roll <= 157 && length(gacha_pool_00))
		rarity = "00"
	else
		rarity = "0"
	// Fallback: if the rolled rarity's pool is empty, drop to the next
	// lower tier rather than returning a null skin.
	if(!length(GachaPoolForRarity(rarity)))
		rarity = (length(gacha_pool_00) ? "00" : "0")
	var/picked = RollFromPoolWeighted(B, rarity)
	// 75% of 000s telegraph via the golden-ball reveal flag; the
	// other 25% are "stealth" — surprise reveal when the chain is
	// pulled back.
	var/stealth_lucky = (rarity == "000" && prob(25))
	return list(
		"skin_id" = picked,
		"rarity" = rarity,
		"was_duplicate" = FALSE,
		"dupe_refund" = 0,
		"stealth_lucky" = stealth_lucky,
	)


