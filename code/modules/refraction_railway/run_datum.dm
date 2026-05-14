/*
 * One instance per active refraction-railway run. Owns the lobby roster, the
 * loaded line z, the loadouts, the timer, and the per-member checkpoint and
 * ready state.
 *
 * Wave-controller activation is stubbed (`ActivateRoom` / `WipeRoomReserves`)
 * because `wave_system.dm` is not yet included in the DME. Wire those calls up
 * when the wave system lands.
 *
 * Map loading currently piggybacks on `GLOB.loaded_quest_z_levels` for dedupe,
 * matching the maploader pattern at ModularLobotomy/associations/machines.dm.
 */

GLOBAL_LIST_INIT(refraction_attribute_keys, list(
	FORTITUDE_ATTRIBUTE,
	PRUDENCE_ATTRIBUTE,
	TEMPERANCE_ATTRIBUTE,
	JUSTICE_ATTRIBUTE,
))
GLOBAL_LIST_INIT(refraction_ego_typecache, typecacheof(list(
	/obj/item/ego_weapon,
	/obj/item/clothing/suit/armor/ego_gear,
)))

/datum/refraction_run
	/// Unique identifier for this run instance, used for wave-controller namespacing.
	var/run_uid
	/// /datum/refraction_line ref this run is playing.
	var/datum/refraction_line/line
	/// Z-level claimed from SSrefraction_railway. 0 before claim, 0 after release.
	var/loaded_z = 0
	/// Mobs (the spawned bodies) currently part of the lobby. Includes the dead.
	var/list/members = list()
	/// 0 before the first sector starts, then 1-based sector index after BeginSector.
	var/current_section = 0
	/// Authored room id of the room the team is currently in (combat). Empty in checkpoint.
	var/current_room = ""
	/// True when the lobby is staging in the checkpoint room (between sectors).
	var/in_checkpoint = TRUE
	/// World.time snapshot when the timer was last unpaused.
	var/timer_started_at = 0
	/// Accumulated decisecond total before the most recent unpause.
	var/elapsed_baseline = 0
	/// True while the timer is paused; elapsed time is then just elapsed_baseline.
	var/timer_paused = TRUE
	/// ckey of the lobby owner. Receives kick/start/begin-sector privileges.
	var/lobby_owner
	/// LOBBY_OPEN / LOBBY_RUNNING / LOBBY_FINISHED.
	var/lobby_state = LOBBY_OPEN
	/// ckey -> list(weapon_path1, weapon_path2, armor_path). Paths are kept
	/// alongside the gear refs (below) so the UI can show loadout icons via
	/// SStestrange.GenerateEgoPreviewIcon and so we can respawn an item if it
	/// gets externally qdel'd while the run is live.
	var/list/loadouts = list()
	/// ckey -> list(item_ref_w1, item_ref_w2, item_ref_armor). Refs to the
	/// /obj/item instances we spawned for this player. Lets us pull gear back
	/// into their hands or qdel it regardless of where it ended up (floor,
	/// another mob's pocket, a backpack on the ground).
	var/list/gear_refs = list()
	/// Cumulative ElapsedDeciseconds at the moment each sector finished.
	/// Index 1 = end of sector 1, etc. Used for the per-sector breakdown in
	/// the final results display.
	var/list/sector_finish_times = list()
	/// elapsed_baseline snapshot taken at the start of the current sector.
	/// On team wipe we restore this so the failed attempt's clock is
	/// discarded — sector-N reported time reflects only the successful run.
	var/elapsed_baseline_at_section_start = 0
	/// Per-sector per-ckey loadout snapshot. Index N = list of assoc lists
	/// captured when sector N was successfully completed:
	///     list("ckey" = ckey, "name" = name, "loadout" = list(w1,w2,armor))
	/// Surfaced on the results screen so each clear's loadouts are visible.
	var/list/sector_loadouts = list()
	/// ckey -> assoc(attribute_key -> raw_level) snapshot, restored on run end.
	var/list/original_attributes = list()
	/// ckey -> 1-based sector index of last reached checkpoint. 0 = none yet.
	var/list/last_checkpoint = list()
	/// ckey -> bool ready flag at the Begin Sector console.
	var/list/ready_states = list()
	/// Cached eligible weapons (paths) for this run's attribute_set_value.
	var/list/usable_ego_weapons
	/// Cached eligible armor (paths) for this run's attribute_set_value.
	var/list/usable_ego_armor
	/// ckey -> /turf snapshot of the member's location when they joined the
	/// lobby, used by TeleportAllToHub to return everyone to the railway hub
	/// at run end without needing a dedicated hub-return landmark.
	var/list/home_turfs = list()
	/// world.time of the last Tick where at least one member had a client.
	/// Used by the disconnect-watchdog to auto-abandon runs where every
	/// player has dropped, so the lane doesn't sit claimed indefinitely.
	var/last_active_world_time = 0
	/// ckey -> TRUE for any member with an in-flight BenchIncapacitatedMember
	/// timer. Dedupes COMSIG_LIVING_DEATH + COMSIG_HUMAN_INSANE firing on
	/// the same tick so we don't queue two bench callbacks for one body.
	var/list/pending_bench = list()
	/// ckey -> list of /obj/item/reagent_containers/hypospray/medipen refs
	/// issued at the start of the current sector. Tracked so unused pens
	/// can be removed when the team returns to the checkpoint (used pens
	/// drop out automatically via the COMSIG_PARENT_QDELETING handler).
	/// Compensation for smaller parties — see PenCountForLobby.
	var/list/pen_refs = list()

/datum/refraction_run/New(datum/refraction_line/L, owner_ckey)
	. = ..()
	if(!istype(L))
		stack_trace("refraction_run created without a line datum")
		qdel(src)
		return
	GLOB.refraction_run_uid_counter++
	run_uid = GLOB.refraction_run_uid_counter
	line = L
	lobby_owner = owner_ckey
	SSrefraction_railway.active_runs += src

/datum/refraction_run/Destroy()
	if(loaded_z)
		SSrefraction_railway.ReleaseLane(loaded_z)
		loaded_z = 0
	for(var/mob/M as anything in members)
		UnregisterSignal(M, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING, COMSIG_HUMAN_INSANE))
	members.Cut()
	SSrefraction_railway.active_runs -= src
	return ..()

// ---------- Lobby ----------

/datum/refraction_run/proc/AddMember(mob/M)
	if(!M || (M in members))
		return FALSE
	if(lobby_state != LOBBY_OPEN)
		return FALSE
	if(length(members) >= line.max_lobby_size)
		return FALSE
	members += M
	if(M.ckey)
		var/turf/T = get_turf(M)
		if(T)
			home_turfs[M.ckey] = T
	RegisterSignal(M, COMSIG_LIVING_DEATH, PROC_REF(OnMemberIncapacitated))
	RegisterSignal(M, COMSIG_PARENT_QDELETING, PROC_REF(OnMemberQdel))
	// COMSIG_HUMAN_INSANE is only emitted by /mob/living/carbon/human, so
	// gate the register; UnregisterSignal is a no-op for unregistered
	// signals so the un-register sites don't need the same guard.
	if(ishuman(M))
		RegisterSignal(M, COMSIG_HUMAN_INSANE, PROC_REF(OnMemberIncapacitated))
	return TRUE

/datum/refraction_run/proc/RemoveMember(mob/M)
	if(!(M in members))
		return FALSE
	UnregisterSignal(M, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING, COMSIG_HUMAN_INSANE))
	if(M.ckey)
		// Strip first so the qdel signal handlers can find their slots before
		// we drop the gear_refs entry below.
		StripMemberGear(M.ckey)
		gear_refs -= M.ckey
	members -= M
	if(M.ckey)
		loadouts -= M.ckey
		ready_states -= M.ckey
		last_checkpoint -= M.ckey
		home_turfs -= M.ckey
		pending_bench -= M.ckey
		RemoveUnusedPensForCkey(M.ckey)
		// Restore attributes if we had snapped them.
		if(original_attributes[M.ckey] && ishuman(M))
			RestoreAttributes(M)
	if(!length(members) && lobby_state != LOBBY_FINISHED)
		Cleanup()
	return TRUE

/datum/refraction_run/proc/OnMemberQdel(datum/source)
	SIGNAL_HANDLER
	RemoveMember(source)

// ---------- Run start ----------

/// Owner-triggered run start. Flips lobby_state to LOBBY_STARTING immediately
/// so the UI can gray out Start/Leave/Kick and surface a "loading new z-level"
/// message, then defers the heavy lane-load + setup work to an async task so
/// the click handler returns right away.
/datum/refraction_run/proc/StartRun()
	if(lobby_state != LOBBY_OPEN)
		return FALSE
	if(!length(members))
		return FALSE
	lobby_state = LOBBY_STARTING
	INVOKE_ASYNC(src, PROC_REF(StartRunAsync))
	return TRUE

/// The actual setup work, deferred so the synchronous call to load_new_z()
/// inside ClaimLane doesn't block the click handler. While this runs, the
/// lobby is in LOBBY_STARTING and all member-mutating actions are refused.
/datum/refraction_run/proc/StartRunAsync()
	// SStestrange's ego_datums list builds asynchronously after roundstart;
	// BuildEligibleEgoLists below would otherwise capture an incomplete set
	// (the loadout console then silently shows fewer items than it should).
	// Wait it out — the owner already saw the LOBBY_STARTING grayed-out UI.
	UNTIL(SStestrange.ego_datums_initialized && !SStestrange.ego_datums_initializing)
	if(!EnsureMapsLoaded())
		// Lane couldn't be claimed (no map_path, load_new_z failure, etc.).
		// Revert to LOBBY_OPEN so the owner can retry / back out cleanly.
		lobby_state = LOBBY_OPEN
		return
	lobby_state = LOBBY_RUNNING
	// Watchdog baseline — without this, the very first Tick would see
	// last_active_world_time=0 and treat the gap as gigantic.
	last_active_world_time = world.time
	BuildEligibleEgoLists()
	for(var/mob/living/carbon/human/H as anything in members)
		if(!ishuman(H))
			continue
		ApplyAttributeOverride(H)
		last_checkpoint[H.ckey] = 0
		ready_states[H.ckey] = FALSE
	EnterCheckpoint()

/// Claims a lane (z-level) for this run. Returns TRUE on success, FALSE if no
/// lane could be allocated (in which case StartRun aborts before flipping state).
/// Each line's dmm contains its own checkpoint area, so a single load brings
/// both combat rooms and checkpoint in together. Subsequent runs of the same
/// line reuse a free lane via SSrefraction_railway.ClaimLane.
/datum/refraction_run/proc/EnsureMapsLoaded()
	loaded_z = SSrefraction_railway.ClaimLane(line, src)
	return loaded_z != 0

// ---------- Eligible gear ----------

/datum/refraction_run/proc/BuildEligibleEgoLists()
	usable_ego_weapons = list()
	usable_ego_armor = list()
	var/target = line.attribute_set_value
	for(var/datum/ego_datum/ED in SStestrange.ego_datums)
		if(!ED.item_path)
			continue
		var/list/reqs = ED.information["attribute_requirements"]
		if(islist(reqs))
			var/eligible = TRUE
			for(var/atr in reqs)
				if(reqs[atr] > target)
					eligible = FALSE
					break
			if(!eligible)
				continue
		if(istype(ED, /datum/ego_datum/weapon))
			usable_ego_weapons += ED.item_path
		else if(istype(ED, /datum/ego_datum/armor))
			usable_ego_armor += ED.item_path

// ---------- Attributes ----------

/datum/refraction_run/proc/ApplyAttributeOverride(mob/living/carbon/human/H)
	if(!ishuman(H) || !H.ckey)
		return
	var/list/snapshot = list()
	var/target = line.attribute_set_value
	for(var/key in GLOB.refraction_attribute_keys)
		var/datum/attribute/atr = H.attributes[key]
		if(!istype(atr))
			continue
		snapshot[key] = atr.level
		H.adjust_attribute_level(key, target - atr.level)
	original_attributes[H.ckey] = snapshot

/datum/refraction_run/proc/RestoreAttributes(mob/living/carbon/human/H)
	if(!ishuman(H) || !H.ckey)
		return
	var/list/snapshot = original_attributes[H.ckey]
	if(!islist(snapshot))
		return
	for(var/key in snapshot)
		var/datum/attribute/atr = H.attributes[key]
		if(!istype(atr))
			continue
		H.adjust_attribute_level(key, snapshot[key] - atr.level)
	original_attributes -= H.ckey

// ---------- Loadouts ----------

/datum/refraction_run/proc/ApplyLoadout(ckey, list/weapon_paths, armor_path)
	if(!ckey || !islist(weapon_paths) || length(weapon_paths) != 2)
		return FALSE
	if(!armor_path)
		return FALSE
	for(var/wpath in weapon_paths)
		if(!(wpath in usable_ego_weapons))
			return FALSE
	if(!(armor_path in usable_ego_armor))
		return FALSE
	var/mob/living/carbon/human/H = FindMemberByCkey(ckey)
	if(!ishuman(H))
		return FALSE
	StripMemberGear(ckey)
	var/list/new_refs = list()
	var/turf/dest = get_turf(H)
	for(var/wpath in weapon_paths)
		var/obj/item/W = new wpath(dest)
		H.put_in_hands(W)
		RegisterSignal(W, COMSIG_PARENT_QDELETING, PROC_REF(OnTrackedGearQdel))
		new_refs += W
	var/obj/item/clothing/suit/armor/ego_gear/A = new armor_path(dest)
	// Refraction-issued armor never makes the player wait the standard 7-second
	// self-equip; subsequent re-equips (after dropping, dying, etc.) are instant.
	A.equip_delay_self = 0
	// Initial equip uses the bypass-delay path used by purchase consoles.
	H.equip_to_slot_or_del(A, ITEM_SLOT_OCLOTHING, TRUE)
	RegisterSignal(A, COMSIG_PARENT_QDELETING, PROC_REF(OnTrackedGearQdel))
	new_refs += A
	gear_refs[ckey] = new_refs
	loadouts[ckey] = list(weapon_paths[1], weapon_paths[2], armor_path)
	return TRUE

/// Per-slot reconcile of a player's tracked gear:
/// - Already directly on the player (held / equipped / pocket): leave alone, no yank.
/// - On the floor / in a teammate's inventory / in a container: forceMove back, equip.
/// - Externally destroyed (QDELETED): respawn from the recorded path and equip.
/datum/refraction_run/proc/ReequipLoadout(mob/living/carbon/human/H)
	if(!ishuman(H) || !H.ckey)
		return
	var/list/refs = gear_refs[H.ckey]
	var/list/paths = loadouts[H.ckey]
	if(!islist(refs) || !length(refs))
		return
	var/turf/dest = get_turf(H)
	for(var/i in 1 to length(refs))
		var/obj/item/I = refs[i]
		if(QDELETED(I))
			// Externally destroyed. Respawn from the path triple, re-track.
			if(!islist(paths) || i > length(paths))
				continue
			var/path = paths[i]
			if(!path)
				continue
			I = new path(dest)
			if(istype(I, /obj/item/clothing/suit/armor/ego_gear))
				var/obj/item/clothing/suit/armor/ego_gear/A = I
				A.equip_delay_self = 0
			refs[i] = I
			RegisterSignal(I, COMSIG_PARENT_QDELETING, PROC_REF(OnTrackedGearQdel))
		else if(I.loc == H)
			// Already directly on the player (held / equipped / pocket).
			// Leave it where they put it instead of yanking to the floor and
			// shoving back into hands / suit.
			continue
		else
			// Yank it to the player's tile from wherever it ended up.
			I.forceMove(dest)
		if(istype(I, /obj/item/clothing/suit/armor/ego_gear))
			H.equip_to_slot_or_del(I, ITEM_SLOT_OCLOTHING, TRUE)
		else
			H.put_in_hands(I)

/// Removes ALL gear we ever issued to this ckey (regardless of where it ended
/// up), then sweeps any pre-existing ego items currently on the player to
/// catch gear they brought from outside the railway. Called from ApplyLoadout
/// before issuing a new set, from RemoveMember when a player leaves, and from
/// Cleanup at run end.
/datum/refraction_run/proc/StripMemberGear(ckey)
	if(!ckey)
		return
	// Phase 1: qdel every tracked ref no matter where it lives.
	var/list/refs = gear_refs[ckey]
	if(islist(refs))
		for(var/obj/item/I as anything in refs)
			if(QDELETED(I))
				continue
			UnregisterSignal(I, COMSIG_PARENT_QDELETING)
			qdel(I)
		refs.Cut()
	// Phase 2: catch ego items currently on the player that we don't own
	// (pre-existing gear brought from outside the railway).
	var/mob/living/carbon/human/H = FindMemberByCkey(ckey)
	if(ishuman(H))
		var/list/to_qdel = list()
		for(var/obj/item/I in H.contents)
			if(is_type_in_typecache(I, GLOB.refraction_ego_typecache))
				to_qdel += I
		for(var/obj/item/I as anything in to_qdel)
			qdel(I)

/// Drops a tracked ref from gear_refs when the item is destroyed by something
/// outside our control (admin nuke, falls into a singularity, etc.). The
/// /next/ ReequipLoadout will respawn from the path triple to fill the slot.
/datum/refraction_run/proc/OnTrackedGearQdel(datum/source)
	SIGNAL_HANDLER
	if(!source)
		return
	for(var/ckey in gear_refs)
		var/list/refs = gear_refs[ckey]
		if(!islist(refs))
			continue
		var/idx = refs.Find(source)
		if(idx)
			// Slot-aware: keep the position so ReequipLoadout knows which
			// loadouts[ckey] path to use when respawning.
			refs[idx] = null
			return

// ---------- State machine ----------

/datum/refraction_run/proc/EnterCheckpoint()
	in_checkpoint = TRUE
	// PauseTimer folds the running interval into elapsed_baseline before
	// flipping the flag; setting timer_paused directly would silently lose
	// the time spent in the just-finished sector.
	PauseTimer()
	current_room = ""
	// Sweep last sector's leftover starter pens before healing — pens are
	// per-sector, not per-run, so unused ones don't accumulate across
	// attempts (or get carried into a wipe-rollback retry).
	RemoveUnusedPens()
	for(var/mob/living/carbon/human/H as anything in members)
		if(!ishuman(H) || H.stat == DEAD)
			continue
		HealMember(H)
		ready_states[H.ckey] = FALSE
	TeleportToCheckpoint()
	// Briefing console reads `current_section + 1` so it reflects the upcoming sector.

/// Starts the next sector. `force` skips the all-ready + everyone-has-a-loadout
/// gate so the owner can drag an AFK / unprepared member into the next sector
/// rather than wait on them; an unprepared member just goes in with whatever
/// loadout (possibly none) they currently have.
/datum/refraction_run/proc/BeginSector(begin_ckey, force = FALSE)
	if(begin_ckey != lobby_owner)
		return FALSE
	if(!in_checkpoint)
		return FALSE
	if(!force)
		for(var/mob/M as anything in members)
			if(M.stat == DEAD)
				continue
			if(!ready_states[M.ckey])
				return FALSE
			if(!loadouts[M.ckey])
				return FALSE
	current_section++
	in_checkpoint = FALSE
	for(var/mob/M as anything in members)
		ready_states[M.ckey] = FALSE
	// First sector start: reset the timer. Subsequent sectors keep the running total.
	if(current_section == 1)
		elapsed_baseline = 0
	// Snapshot the baseline so a team wipe can roll the clock back to here
	// before the next attempt. Any failed-attempt seconds get discarded.
	elapsed_baseline_at_section_start = elapsed_baseline
	timer_paused = FALSE
	timer_started_at = world.time
	// Hand out the per-sector compensation pens BEFORE the teleport in
	// AdvanceRoomById so the items go into the in-checkpoint backpack
	// (and thus follow the player into the room with the rest of their
	// gear). Skips on full quad parties — see PenCountForLobby.
	GiveSectorPens()
	AdvanceRoomById(GetFirstRoomIdInSection(current_section))
	return TRUE

/datum/refraction_run/proc/OnRoomCleared(cleared_room_id)
	if(cleared_room_id != current_room)
		return
	addtimer(CALLBACK(src, PROC_REF(AdvanceRoom)), 5 SECONDS)

/datum/refraction_run/proc/AdvanceRoom()
	var/next_id = GetNextRoomIdInSection(current_section, current_room)
	if(next_id)
		AdvanceRoomById(next_id)
		return
	// No next room in this sector — the sector is complete. The 5-second
	// breather scheduled by OnRoomCleared has already elapsed at this point,
	// so dispatch the section-end transition immediately.
	OnSectionCleared(current_section)

/datum/refraction_run/proc/AdvanceRoomById(room_id)
	if(!room_id)
		return
	current_room = room_id
	for(var/mob/living/carbon/human/H as anything in members)
		if(!ishuman(H) || H.stat == DEAD)
			continue
		ReequipLoadout(H)
	TeleportToRoom(room_id)
	MarkRoomEntered(room_id)
	ActivateRoom(room_id)

/datum/refraction_run/proc/OnSectionCleared(section_id)
	if(section_id != current_section)
		return
	last_checkpoint_for_all(section_id)
	// Snapshot cumulative time before the timer is paused by EnterCheckpoint
	// so the per-sector breakdown in the final results is accurate.
	sector_finish_times += ElapsedDeciseconds()
	SnapshotSectorLoadouts(section_id)
	if(section_id >= line.section_count)
		OnRunComplete()
		return
	EnterCheckpoint()

/// Builds a per-sector breakdown for the leaderboard entry. Combines
/// sector_finish_times with the captured sector_loadouts. Loadouts are kept
/// as paths so the storage is small; the hub console converts to icons at
/// render time (and post-JSON-decode they round-trip via text2path).
/datum/refraction_run/proc/BuildSectorBreakdownForLeaderboard()
	var/list/out = list()
	for(var/i in 1 to length(sector_finish_times))
		var/end_t = sector_finish_times[i]
		var/start_t = (i > 1) ? sector_finish_times[i - 1] : 0
		var/list/players_out = list()
		if(islist(sector_loadouts) && i <= length(sector_loadouts))
			var/list/snap = sector_loadouts[i]
			if(islist(snap))
				for(var/list/entry as anything in snap)
					var/list/lo = entry["loadout"]
					players_out += list(list(
						"ckey"    = entry["ckey"],
						"name"    = entry["name"],
						"loadout" = islist(lo) ? lo.Copy() : list(),
					))
		out += list(list(
			"index"   = i,
			"time_ds" = end_t - start_t,
			"players" = players_out,
		))
	return out

/// Records each member's loadout (paths) and display name at sector-clear time.
/// Stored at sector_loadouts[section_id]. Surfaced on the results screen so
/// players can see what each teammate ran on each sector.
/datum/refraction_run/proc/SnapshotSectorLoadouts(section_id)
	if(section_id < 1)
		return
	var/list/per_player = list()
	for(var/mob/M as anything in members)
		if(!M.ckey)
			continue
		var/list/lo = loadouts[M.ckey]
		var/list/lo_copy = islist(lo) ? lo.Copy() : list()
		per_player += list(list(
			"ckey"    = M.ckey,
			"name"    = M.real_name || M.name,
			"loadout" = lo_copy,
		))
	while(length(sector_loadouts) < section_id)
		sector_loadouts += list(list())
	sector_loadouts[section_id] = per_player

/datum/refraction_run/proc/last_checkpoint_for_all(section_id)
	for(var/mob/M as anything in members)
		if(!M.ckey)
			continue
		last_checkpoint[M.ckey] = section_id

/datum/refraction_run/proc/OnRunComplete()
	if(lobby_state == LOBBY_FINISHED)
		return
	lobby_state = LOBBY_FINISHED
	// Pauses the wall clock and folds the final running interval into
	// elapsed_baseline so total_ds is accurate. Do NOT EnterCheckpoint here:
	// EnterCheckpoint would also wipe ready_states / call HealMember, but the
	// state machine for "finished" is intentionally minimal — just keep the
	// team where they are with the timer halted and let the advance console's
	// finished view drive the rest. Players move themselves over to the
	// console (or stay put); ReturnToLobby finalizes when they're ready.
	PauseTimer()
	in_checkpoint = TRUE
	current_room = ""
	// Sweep any unused sector pens — they don't carry out as a reward,
	// only the issued ego loadout does.
	RemoveUnusedPens()
	var/total_ds = ElapsedDeciseconds()
	// Restore each member to their pre-run attribute snapshot now (rather than
	// at finalize time) so a player who steps off the lane immediately isn't
	// stuck with the line's overrides.
	for(var/mob/living/carbon/human/H as anything in members)
		if(ishuman(H))
			RestoreAttributes(H)
	// Send everybody back to the checkpoint area so the advance console is in
	// reach. Live members get teleported; dead ones will be revived + brought
	// back by the per-mob bench timer.
	TeleportToCheckpoint()
	// Heal survivors so they can browse the results without bleeding out from
	// chip damage taken on the last room.
	for(var/mob/living/carbon/human/H as anything in members)
		if(ishuman(H) && H.stat != DEAD)
			HealMember(H)
	var/list/owner_loadout = loadouts[lobby_owner]
	var/list/member_ckeys = list()
	for(var/mob/M as anything in members)
		if(M.ckey)
			member_ckeys += M.ckey
	var/list/entry = list(
		"ckey"      = lobby_owner,
		"name"      = lobby_owner,
		"loadout"   = islist(owner_loadout) ? owner_loadout.Copy() : list(),
		"time_ds"   = total_ds,
		"members"   = member_ckeys,
		"timestamp" = world.realtime,
		// Per-sector drill-down: time + each player's loadout for that
		// sector. Surfaced by the hub console's records modal so a viewer
		// can see exactly what gear cleared each sector. Stored as paths
		// (json_encode flattens to strings; the console converts back via
		// text2path before rendering icons).
		"sectors"   = BuildSectorBreakdownForLeaderboard(),
	)
	SSrefraction_railway.RecordRun(line.id, entry)
	// Save-after-write: a crash mid-round still preserves the leaderboard
	// without waiting for SSpersistence.CollectData at round end.
	SSpersistence.SaveRefractionLeaderboards()
	ShowFinalResults(total_ds)

/// TRUE iff the lobby owner currently has both a mind AND an active client
/// on a member mob. Used to relax owner-only gates (abandon) when the
/// owner is AFK / disconnected / ghosted so the rest of the team isn't
/// stuck on the lane forever.
/datum/refraction_run/proc/IsOwnerActive()
	if(!lobby_owner)
		return FALSE
	var/mob/M = FindMemberByCkey(lobby_owner)
	if(!M)
		return FALSE
	if(!M.mind)
		return FALSE
	if(!M.client)
		return FALSE
	return TRUE

/// Owner-triggered abandon (or, when the owner is inactive, any member).
/// Scraps the run, restores attributes, strips the refraction-issued gear
/// (no reward — they didn't clear), teleports everyone to the hub, releases
/// the lane, and qdels the datum so the next lobby on this line can
/// immediately reuse the z-level.
/datum/refraction_run/proc/AbandonRun(initiator_ckey)
	// Normally owner-only, but if the owner is AFK/disconnected anyone in
	// the run can pull the rip cord — otherwise a dropped owner softlocks
	// the lane indefinitely.
	if(initiator_ckey != lobby_owner && IsOwnerActive())
		return FALSE
	if(lobby_state != LOBBY_RUNNING)
		return FALSE
	if(!in_checkpoint)
		return FALSE
	ForceCleanup("Run abandoned by [initiator_ckey].")
	return TRUE

/// State-check-free finalizer used by both AbandonRun (after its checks
/// pass) and the disconnect watchdog. Wipes any in-flight wave reserves,
/// restores attributes, strips the refraction-issued gear (no reward),
/// teleports everyone home, releases the lane, and qdels the datum.
/datum/refraction_run/proc/ForceCleanup(reason)
	if(lobby_state == LOBBY_FINISHED)
		return
	lobby_state = LOBBY_FINISHED
	PauseTimer()
	if(reason)
		log_world("SSrefraction_railway run #[run_uid] ([line?.id]): [reason]")
	// In-flight combat: drain reserves so no further mobs queue up while we
	// finalize. EnterCheckpoint isn't called here — players are getting
	// teleported home directly, no need to revive / heal anyone.
	if(current_room && !in_checkpoint)
		WipeRoomReserves(current_room)
	for(var/mob/living/carbon/human/H as anything in members)
		if(ishuman(H))
			RestoreAttributes(H)
	TeleportAllToHub()
	// Cleanup() qdels every tracked gear ref via StripMemberGear, so this
	// path naturally strips the loadout (no reward for an aborted run).
	// Lane release is also defensive — Cleanup releases too.
	if(loaded_z)
		SSrefraction_railway.ReleaseLane(loaded_z)
		loaded_z = 0
	Cleanup()

/// Triggered by the advance console's Return-to-Lobby button when the run
/// has finished. Hands the team back to wherever they joined from, drops
/// our tracking on their refraction-issued gear (without qdeling — clearing
/// the line is the reward, so they keep the loadout), releases the lane and
/// qdels the run datum.
/datum/refraction_run/proc/ReturnToLobby()
	if(lobby_state != LOBBY_FINISHED)
		return
	// Untrack the issued gear so Cleanup's StripMemberGear doesn't qdel it.
	// Items already reverted to plain world objects from the player's
	// perspective the moment we drop the qdel-on-leave signal.
	for(var/ckey in gear_refs)
		var/list/refs = gear_refs[ckey]
		if(!islist(refs))
			continue
		for(var/obj/item/I as anything in refs)
			if(QDELETED(I))
				continue
			UnregisterSignal(I, COMSIG_PARENT_QDELETING)
		refs.Cut()
	gear_refs.Cut()
	TeleportAllToHub()
	if(loaded_z)
		SSrefraction_railway.ReleaseLane(loaded_z)
		loaded_z = 0
	Cleanup()

/// Sends a final-results chat message to every member, with cumulative time
/// and a per-sector breakdown derived from sector_finish_times.
/datum/refraction_run/proc/ShowFinalResults(total_ds)
	var/list/lines_text = list()
	lines_text += "<b>Refraction Railway: [line.name] cleared!</b>"
	for(var/i in 1 to length(sector_finish_times))
		var/end_t = sector_finish_times[i]
		var/start_t = (i > 1) ? sector_finish_times[i - 1] : 0
		lines_text += "Sector [i]: [FormatRefractionTime(end_t - start_t)]"
	lines_text += "<b>Total: [FormatRefractionTime(total_ds)]</b>"
	var/joined = jointext(lines_text, "\n")
	for(var/mob/M as anything in members)
		if(M.client)
			to_chat(M, span_nicegreen(joined))

/// Formats deciseconds as `M:SS.s` for the final results display.
/datum/refraction_run/proc/FormatRefractionTime(ds)
	if(ds <= 0)
		return "0:00.0"
	var/total_seconds = ds * 0.1
	var/min = round(total_seconds / 60)
	var/sec = total_seconds - (min * 60)
	var/sec_str = (sec < 10) ? "0[round(sec, 0.1)]" : "[round(sec, 0.1)]"
	return "[min]:[sec_str]"

/// Single handler for both COMSIG_LIVING_DEATH and COMSIG_HUMAN_INSANE.
/// "Incapacitated" = dead OR insane: in either case the body is teleported
/// to the checkpoint immediately (with any tracked gear that fell on the
/// floor), a bench timer is queued for the actual revive/cure work, and
/// the team-wipe trigger is checked to roll back the sector if no one is
/// left in combat.
/datum/refraction_run/proc/OnMemberIncapacitated(mob/source)
	SIGNAL_HANDLER
	if(!source || !(source in members))
		return
	// Body + dropped gear move to the checkpoint immediately. The 1s bench
	// delay still applies for the actual revive/cure work below.
	TeleportIncapacitatedToCheckpoint(source)
	// Dedupe: dying-while-insane fires both signals; one handler invocation
	// is enough.
	if(source.ckey && !pending_bench[source.ckey])
		pending_bench[source.ckey] = TRUE
		addtimer(CALLBACK(src, PROC_REF(BenchIncapacitatedMember), source), 1 SECONDS)
	// If this leaves no live members in the active room and reserves remain,
	// force-advance the team to the checkpoint to prevent stale spawns and
	// roll the failed-sector clock back so the next BeginSector retries
	// instead of skipping. current_section is decremented because BeginSector
	// pre-increments it at sector start.
	if(!HasLiveMemberInCombat())
		WipeRoomReserves(current_room)
		current_section = max(0, current_section - 1)
		elapsed_baseline = elapsed_baseline_at_section_start
		EnterCheckpoint()

/// Fires 1s after a member's death/insanity signal. Performs whichever of
/// {revive, cure-insanity} is still needed, then re-equips. Body is
/// already at the checkpoint from the instant teleport in
/// OnMemberIncapacitated, so no re-teleport here.
/datum/refraction_run/proc/BenchIncapacitatedMember(mob/living/carbon/human/H)
	if(!ishuman(H) || !(H in members))
		return
	if(H.ckey)
		pending_bench -= H.ckey
	var/was_dead = (H.stat == DEAD)
	var/was_insane = H.sanity_lost
	if(!was_dead && !was_insane)
		// Recovered externally (heal item, abnormality, admin revive)
		// during the 1s window; nothing to do.
		return
	if(was_dead)
		H.revive(full_heal = TRUE, admin_revive = FALSE)
	// revive(full_heal) does NOT touch sanity (confirmed user-reported
	// bug), so re-check sanity_lost after revive — a dead-AND-insane
	// member needs both branches to fully reset.
	if(H.sanity_lost)
		CureMemberInsanity(H)
	ReequipLoadout(H)

// ---------- Timer ----------

/// Threshold (deciseconds) for the disconnect watchdog. If no member has
/// had an active client for this long while LOBBY_RUNNING, the run is
/// auto-abandoned so the lane doesn't sit claimed by ghosts forever.
#define REFRACTION_DISCONNECT_TIMEOUT_DS (60 SECONDS)

/datum/refraction_run/proc/Tick(wait_ds)
	if(lobby_state != LOBBY_RUNNING)
		return
	// Disconnect watchdog: refresh last_active_world_time whenever any
	// member is connected; auto-cleanup if the gap grows past the threshold.
	if(AnyMemberHasClient())
		last_active_world_time = world.time
	else if(last_active_world_time \
		&& (world.time - last_active_world_time) >= REFRACTION_DISCONNECT_TIMEOUT_DS)
		ForceCleanup("All members disconnected for [REFRACTION_DISCONNECT_TIMEOUT_DS / 10]s; auto-abandoning.")

#undef REFRACTION_DISCONNECT_TIMEOUT_DS

/datum/refraction_run/proc/AnyMemberHasClient()
	for(var/mob/M as anything in members)
		if(M.client)
			return TRUE
	return FALSE

/datum/refraction_run/proc/ElapsedDeciseconds()
	if(timer_paused)
		return elapsed_baseline
	return elapsed_baseline + (world.time - timer_started_at)

/datum/refraction_run/proc/PauseTimer()
	if(timer_paused)
		return
	elapsed_baseline += world.time - timer_started_at
	timer_paused = TRUE

/datum/refraction_run/proc/ResumeTimer()
	if(!timer_paused)
		return
	timer_started_at = world.time
	timer_paused = FALSE

// ---------- Sector / room helpers ----------

/// Returns the room_id (which equals the node id) of the first node in the
/// given (1-based) sector.
/datum/refraction_run/proc/GetFirstRoomIdInSection(section_index)
	var/list/sector = GetSectorBriefing(section_index)
	if(!islist(sector) || !islist(sector["node_ids"]) || !length(sector["node_ids"]))
		return ""
	return sector["node_ids"][1]

/// Returns the room_id of the next node in the same sector, or "" if last.
/datum/refraction_run/proc/GetNextRoomIdInSection(section_index, room_id)
	var/list/sector = GetSectorBriefing(section_index)
	if(!islist(sector) || !islist(sector["node_ids"]))
		return ""
	var/list/node_ids = sector["node_ids"]
	for(var/i in 1 to length(node_ids))
		if(node_ids[i] == room_id && i < length(node_ids))
			return node_ids[i + 1]
	return ""

/datum/refraction_run/proc/GetSectorBriefing(section_index)
	if(!islist(line.sector_briefings))
		return null
	if(section_index < 1 || section_index > length(line.sector_briefings))
		return null
	return line.sector_briefings[section_index]

// ---------- Member helpers ----------

/datum/refraction_run/proc/FindMemberByCkey(ckey)
	for(var/mob/M as anything in members)
		if(M.ckey == ckey)
			return M
	return null

/// True iff at least one member is alive AND has an active client in the
/// active room. Disconnected mobs don't count — otherwise a single AFK
/// player could keep the team locked in combat indefinitely while the
/// last-live-member-dies wipe trigger never fires.
/datum/refraction_run/proc/HasLiveMemberInCombat()
	if(in_checkpoint)
		return TRUE
	for(var/mob/M as anything in members)
		if(IsMemberOutOfAction(M))
			continue
		if(!M.client)
			continue
		return TRUE
	return FALSE

/// Single source of truth for "this member can no longer act this combat".
/// Used by HasLiveMemberInCombat to gate the team-wipe rollback so that
/// going insane has the same effect as dying.
/datum/refraction_run/proc/IsMemberOutOfAction(mob/M)
	if(!M)
		return TRUE
	if(M.stat == DEAD)
		return TRUE
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.sanity_lost)
			return TRUE
	return FALSE

/datum/refraction_run/proc/HealMember(mob/living/carbon/human/H)
	if(!ishuman(H))
		return
	H.revive(full_heal = TRUE, admin_revive = FALSE)
	if(H.sanity_lost)
		// revive(full_heal) doesn't touch sanity (confirmed user-reported
		// bug); cure here so EnterCheckpoint / OnRunComplete reliably
		// converge an insane member to fully sane.
		CureMemberInsanity(H)

/// Always returns the player to fully sane state. Safe no-op when the
/// member is already sane. Calls the canonical cure in adjustSanityLoss
/// so flavor (visible_message, ghost-grab, panicked-status removal) still
/// fires, then explicitly re-tears-down the AI controller and the
/// sanity_lost flag — the canonical block at damage_procs.dm:77 silently
/// no-ops `QDEL_NULL(ai_controller)` if the controller was cleared or
/// reassigned externally between insanity and cure, leaving the player
/// flagged sane while the controller keeps driving the body.
/datum/refraction_run/proc/CureMemberInsanity(mob/living/carbon/human/H)
	if(!ishuman(H) || !H.sanity_lost)
		return
	// Canonical path — fires the cure block at damage_procs.dm:77.
	H.adjustSanityLoss(-H.maxSanity)
	// Defensive re-clear. If the canonical block ran fully these are
	// no-ops; if it didn't, this is what actually frees the player.
	if(H.sanity_lost)
		H.sanity_lost = FALSE
	if(H.ai_controller)
		QDEL_NULL(H.ai_controller)
	H.remove_status_effect(/datum/status_effect/panicked_type)
	// Reattach the original ghost — the canonical path does this, but if
	// it was skipped the mind is still in ghost form. No-op when the
	// player is already controlling the body.
	H.grab_ghost(force = TRUE)

/// Instantly forceMoves the body to a checkpoint_spawn turf and pulls any
/// tracked gear that's NOT on the body onto the same tile so a subsequent
/// ReequipLoadout finds it on the checkpoint z without reaching across.
/// Items in the body's slots/hands travel naturally with the forceMove;
/// items in a teammate's inventory are intentionally left alone (they're
/// being used in combat — ReequipLoadout's recover-from-anywhere pass
/// will reclaim them later if needed).
/datum/refraction_run/proc/TeleportIncapacitatedToCheckpoint(mob/M)
	if(!M)
		return
	var/list/spots = GetRefractionLandmarks(/obj/effect/landmark/refraction/checkpoint_spawn)
	if(!length(spots))
		return
	var/turf/dest = get_turf(pick(spots))
	if(!dest)
		return
	M.forceMove(dest)
	if(!M.ckey)
		return
	var/list/refs = gear_refs[M.ckey]
	if(!islist(refs))
		return
	for(var/obj/item/I as anything in refs)
		if(QDELETED(I))
			continue
		if(I.loc == M)
			continue
		if(ismob(I.loc) && I.loc != M)
			continue
		I.forceMove(dest)

// ---------- Per-sector starter pens ----------

/// Compensation curve for fewer-player parties. Solo gets a heavy stack;
/// quads get nothing. Per-sector — they don't carry across sectors, so
/// hoarding doesn't compound.
/datum/refraction_run/proc/PenCountForLobby(num_players)
	switch(num_players)
		if(1)
			return 4
		if(2)
			return 2
		if(3)
			return 1
	return 0

/// Spawns this sector's batch of mental + salacid medipens into each
/// in-action member's backpack. Tracks every pen in pen_refs so unused
/// ones can be reclaimed at sector end and used ones drop out via the
/// COMSIG_PARENT_QDELETING handler.
/datum/refraction_run/proc/GiveSectorPens()
	if(!SSrefraction_railway.give_compensation_pens)
		return
	var/count = PenCountForLobby(LiveMemberCount())
	if(count <= 0)
		return
	for(var/mob/living/carbon/human/H as anything in members)
		if(!ishuman(H) || IsMemberOutOfAction(H))
			continue
		if(!H.ckey)
			continue
		var/list/refs = pen_refs[H.ckey]
		if(!islist(refs))
			refs = list()
			pen_refs[H.ckey] = refs
		for(var/i = 1 to count)
			IssuePenAndTrack(H, /obj/item/reagent_containers/hypospray/medipen/mental, refs)
			IssuePenAndTrack(H, /obj/item/reagent_containers/hypospray/medipen/salacid, refs)

/datum/refraction_run/proc/IssuePenAndTrack(mob/living/carbon/human/H, pen_path, list/refs)
	var/obj/item/I = new pen_path(H)
	// equip_to_slot_or_del qdels the item if equip fails (no backpack,
	// full, etc.); QDELETED lets us skip tracking the failed cases.
	H.equip_to_slot_or_del(I, ITEM_SLOT_BACKPACK, TRUE)
	if(QDELETED(I))
		return
	RegisterSignal(I, COMSIG_PARENT_QDELETING, PROC_REF(OnPenQdel))
	refs += I

/datum/refraction_run/proc/OnPenQdel(datum/source)
	SIGNAL_HANDLER
	if(!source)
		return
	for(var/ckey in pen_refs)
		var/list/refs = pen_refs[ckey]
		if(islist(refs) && (source in refs))
			refs -= source
			return

/// QDELs every still-live tracked pen across the team and clears the
/// tracking lists. Called from EnterCheckpoint, OnRunComplete, Cleanup.
/datum/refraction_run/proc/RemoveUnusedPens()
	for(var/ckey in pen_refs)
		var/list/refs = pen_refs[ckey]
		if(!islist(refs))
			continue
		for(var/obj/item/I as anything in refs)
			if(QDELETED(I))
				continue
			UnregisterSignal(I, COMSIG_PARENT_QDELETING)
			qdel(I)
	pen_refs.Cut()

/// Per-ckey variant for RemoveMember. Same semantics, just one slot.
/datum/refraction_run/proc/RemoveUnusedPensForCkey(ckey)
	if(!ckey)
		return
	var/list/refs = pen_refs[ckey]
	if(!islist(refs))
		return
	for(var/obj/item/I as anything in refs)
		if(QDELETED(I))
			continue
		UnregisterSignal(I, COMSIG_PARENT_QDELETING)
		qdel(I)
	pen_refs -= ckey

// ---------- Landmark lookup ----------

/// Returns refraction landmarks of `type_path` on this run's claimed z. If
/// `room_id` is non-null, only start_point landmarks with a matching id
/// pass the filter. Iterates GLOB.landmarks_list (cheap at our scale).
/datum/refraction_run/proc/GetRefractionLandmarks(type_path, room_id = null)
	var/list/out = list()
	if(!loaded_z)
		return out
	for(var/obj/effect/landmark/L as anything in GLOB.landmarks_list)
		if(!istype(L, type_path))
			continue
		if(L.z != loaded_z)
			continue
		if(room_id != null)
			if(!istype(L, /obj/effect/landmark/refraction/start_point))
				continue
			var/obj/effect/landmark/refraction/start_point/PS = L
			if(PS.id != room_id)
				continue
		out += L
	return out

// ---------- Stubs to wire up alongside maps + wave_system ----------

/// Round-robin forceMove members (or just `specific`) onto the line's
/// checkpoint_spawn landmarks on the run's claimed z. Called by EnterCheckpoint
/// at run start and between sectors. Skips dead members.
/datum/refraction_run/proc/TeleportToCheckpoint(mob/specific)
	var/list/spots = GetRefractionLandmarks(/obj/effect/landmark/refraction/checkpoint_spawn)
	if(!length(spots))
		return
	if(specific)
		var/turf/T = get_turf(pick(spots))
		if(T)
			specific.forceMove(T)
		return
	var/i = 0
	for(var/mob/M as anything in members)
		if(M.stat == DEAD)
			continue
		var/obj/effect/landmark/L = spots[(i % length(spots)) + 1]
		var/turf/T = get_turf(L)
		if(T)
			M.forceMove(T)
		i++

/// Round-robin forceMove all live members onto the start_point landmarks
/// matching room_id on the run's claimed z. Called by AdvanceRoomById.
/datum/refraction_run/proc/TeleportToRoom(room_id)
	if(!room_id)
		return
	var/list/spots = GetRefractionLandmarks(/obj/effect/landmark/refraction/start_point, room_id)
	if(!length(spots))
		return
	var/i = 0
	for(var/mob/M as anything in members)
		if(M.stat == DEAD)
			continue
		var/obj/effect/landmark/L = spots[(i % length(spots)) + 1]
		var/turf/T = get_turf(L)
		if(T)
			M.forceMove(T)
		i++

/// ForceMove members back to wherever they were standing when they joined
/// the lobby. Captured per-ckey at AddMember-time. Called by OnRunComplete /
/// Cleanup. Members whose home_turf is gone (qdeleted) stay where they are.
/datum/refraction_run/proc/TeleportAllToHub()
	for(var/mob/M as anything in members)
		if(!M.ckey)
			continue
		var/turf/T = home_turfs[M.ckey]
		if(!istype(T) || QDELETED(T))
			continue
		M.forceMove(T)

/datum/refraction_run/proc/ActivateRoom(room_id)
	if(!room_id)
		return
	var/wanted_id = "refraction_[run_uid]_[room_id]"
	var/datum/refraction_wave_controller/found
	for(var/datum/refraction_wave_controller/C as anything in GLOB.refraction_wave_controllers)
		if(C.id != wanted_id)
			continue
		found = C
		break
	if(!found)
		return
	// Lane reuse: a previous run on this z may have left the controller in
	// `completed = TRUE`. Reset before re-activating.
	if(found.completed || found.activated)
		found.Reset()
	found.run_uid = run_uid
	found.Activate(LiveMemberCount())

/datum/refraction_run/proc/WipeRoomReserves(room_id)
	if(!room_id)
		return
	var/wanted_id = "refraction_[run_uid]_[room_id]"
	for(var/datum/refraction_wave_controller/C as anything in GLOB.refraction_wave_controllers)
		if(C.id != wanted_id)
			continue
		// Drain remaining stock so no further mobs queue up, then qdel the
		// living ones to flush the room.
		C.current_stock.Cut()
		C.pending_spawns = 0
		var/list/snapshot = C.living_mobs.Copy()
		C.living_mobs.Cut()
		for(var/mob/M as anything in snapshot)
			if(!QDELETED(M))
				qdel(M)
		return

/datum/refraction_run/proc/LiveMemberCount()
	var/count = 0
	for(var/mob/M as anything in members)
		if(M && M.stat != DEAD)
			count++
	return count

/datum/refraction_run/proc/MarkRoomEntered(room_id)
	var/datum/refraction_node/N = line.combat_nodes[room_id]
	if(!istype(N))
		return
	var/list/mob_paths = list()
	for(var/path in N.mob_stock)
		mob_paths += path
	if(!length(mob_paths))
		return
	var/list/live_ckeys = list()
	for(var/mob/M as anything in members)
		if(M.ckey && M.stat != DEAD)
			live_ckeys += M.ckey
	SSrefraction_railway.MarkEncountered(live_ckeys, mob_paths)

// ---------- Cleanup ----------

/datum/refraction_run/proc/Cleanup()
	if(loaded_z)
		SSrefraction_railway.ReleaseLane(loaded_z)
		loaded_z = 0
	// Strip every member's tracked gear (qdels regardless of location). Done
	// before signal-unregister + members.Cut so OnTrackedGearQdel still has
	// a working gear_refs entry to look up.
	for(var/ckey in gear_refs)
		StripMemberGear(ckey)
	// Sweep pens before signal-unregister so OnPenQdel can still find its
	// slot. RemoveUnusedPens unregisters its own signals.
	RemoveUnusedPens()
	for(var/mob/M as anything in members)
		UnregisterSignal(M, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING, COMSIG_HUMAN_INSANE))
	members.Cut()
	loadouts.Cut()
	gear_refs.Cut()
	ready_states.Cut()
	last_checkpoint.Cut()
	original_attributes.Cut()
	pending_bench.Cut()
	qdel(src)
