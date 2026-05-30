/*
 * One instance per active refraction-railway run. Owns the lobby roster,
 * loaded line z, loadouts, timer, and per-member checkpoint/ready state.
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
	var/run_uid
	var/datum/refraction_line/line
	/// Z-level claimed from SSrefraction_railway. 0 before claim / after release.
	var/loaded_z = 0
	/// Member bodies in the lobby. Includes the dead.
	var/list/members = list()
	/// 0 before first sector, then 1-based sector index.
	var/current_section = 0
	/// Authored room id (combat). Empty in checkpoint.
	var/current_room = ""
	var/in_checkpoint = TRUE
	var/timer_started_at = 0
	/// Accumulated decisecond total before the most recent unpause.
	var/elapsed_baseline = 0
	var/timer_paused = TRUE
	var/lobby_owner
	/// LOBBY_OPEN / LOBBY_RUNNING / LOBBY_FINISHED.
	var/lobby_state = LOBBY_OPEN
	/// ckey -> list(weapon_path1, weapon_path2, armor_path).
	var/list/loadouts = list()
	/// ckey -> list(item_ref_w1, item_ref_w2, item_ref_armor).
	var/list/gear_refs = list()
	/// Cumulative ElapsedDeciseconds at the moment each sector finished.
	var/list/sector_finish_times = list()
	/// elapsed_baseline snapshot at sector start; restored on team wipe.
	var/elapsed_baseline_at_section_start = 0
	/// Per-sector per-ckey loadout snapshot. Index N = list of assoc lists.
	var/list/sector_loadouts = list()
	/// ckey -> assoc(attribute_key -> raw_level) snapshot, restored on run end.
	var/list/original_attributes = list()
	/// ckey -> 1-based sector index of last reached checkpoint. 0 = none yet.
	var/list/last_checkpoint = list()
	/// ckey -> bool ready flag at the Begin Sector console.
	var/list/ready_states = list()
	var/list/usable_ego_weapons
	var/list/usable_ego_armor
	/// ckey -> /turf where the member was standing at AddMember time.
	var/list/home_turfs = list()
	/// world.time of the last Tick where a member had a client.
	var/last_active_world_time = 0
	/// ckey -> TRUE while a BenchIncapacitatedMember timer is in-flight (dedupe).
	var/list/pending_bench = list()
	/// ckey -> list of medipen refs issued this sector.
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
	// COMSIG_HUMAN_INSANE only fires on humans; gate the register.
	if(ishuman(M))
		RegisterSignal(M, COMSIG_HUMAN_INSANE, PROC_REF(OnMemberIncapacitated))
	return TRUE

/datum/refraction_run/proc/RemoveMember(mob/M)
	if(!(M in members))
		return FALSE
	UnregisterSignal(M, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING, COMSIG_HUMAN_INSANE))
	if(M.ckey)
		// Strip before dropping gear_refs so qdel handlers find their slots.
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
		if(original_attributes[M.ckey] && ishuman(M))
			RestoreAttributes(M)
	if(!length(members) && lobby_state != LOBBY_FINISHED)
		Cleanup()
	return TRUE

/datum/refraction_run/proc/OnMemberQdel(datum/source)
	SIGNAL_HANDLER
	RemoveMember(source)

// ---------- Run start ----------

/// Owner-triggered run start; flips to LOBBY_STARTING and defers setup async.
/datum/refraction_run/proc/StartRun()
	if(lobby_state != LOBBY_OPEN)
		return FALSE
	if(!length(members))
		return FALSE
	lobby_state = LOBBY_STARTING
	INVOKE_ASYNC(src, PROC_REF(StartRunAsync))
	return TRUE

/// Deferred run setup; runs while lobby is LOBBY_STARTING.
/datum/refraction_run/proc/StartRunAsync()
	// Wait for SStestrange ego_datums; an incomplete set would yield a short
	// loadout list.
	UNTIL(SStestrange.ego_datums_initialized && !SStestrange.ego_datums_initializing)
	if(!EnsureMapsLoaded())
		// Lane couldn't be claimed; revert so the owner can retry.
		lobby_state = LOBBY_OPEN
		return
	lobby_state = LOBBY_RUNNING
	// Watchdog baseline, else the first Tick sees a gigantic gap.
	last_active_world_time = world.time
	BuildEligibleEgoLists()
	for(var/mob/living/carbon/human/H as anything in members)
		if(!ishuman(H))
			continue
		ApplyAttributeOverride(H)
		last_checkpoint[H.ckey] = 0
		ready_states[H.ckey] = FALSE
	EnterCheckpoint()

/// Claims a lane (z-level). TRUE on success, FALSE if none available.
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

/// TRUE iff SS-level AND this run's line both have unique-loadout-per-sector on.
/datum/refraction_run/proc/IsUniqueLoadoutEnforced()
	if(!SSrefraction_railway.unique_loadout_per_sector)
		return FALSE
	if(line && !line.unique_loadout_per_sector)
		return FALSE
	return TRUE

/// TRUE iff `ckey` already used `path` in a prior sector's loadout this run.
/// Always FALSE when unique-loadout enforcement is off.
/datum/refraction_run/proc/IsItemPathBlocked(ckey, path)
	if(!ckey || !path)
		return FALSE
	if(!IsUniqueLoadoutEnforced())
		return FALSE
	for(var/list/per_player as anything in sector_loadouts)
		if(!islist(per_player))
			continue
		for(var/list/entry as anything in per_player)
			if(entry["ckey"] != ckey)
				continue
			var/list/lo = entry["loadout"]
			if(islist(lo) && (path in lo))
				return TRUE
	return FALSE

/datum/refraction_run/proc/ApplyLoadout(ckey, list/weapon_paths, armor_path)
	if(!ckey || !islist(weapon_paths) || length(weapon_paths) != 2)
		return FALSE
	if(!armor_path)
		return FALSE
	for(var/wpath in weapon_paths)
		if(!(wpath in usable_ego_weapons))
			return FALSE
		if(IsItemPathBlocked(ckey, wpath))
			return FALSE
	if(!(armor_path in usable_ego_armor))
		return FALSE
	if(IsItemPathBlocked(ckey, armor_path))
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
	// Refraction-issued armor skips the 7s self-equip delay.
	A.equip_delay_self = 0
	H.equip_to_slot_or_del(A, ITEM_SLOT_OCLOTHING, TRUE)
	RegisterSignal(A, COMSIG_PARENT_QDELETING, PROC_REF(OnTrackedGearQdel))
	new_refs += A
	gear_refs[ckey] = new_refs
	loadouts[ckey] = list(weapon_paths[1], weapon_paths[2], armor_path)
	return TRUE

/// Per-slot reconcile of a player's tracked gear (leave/recover/respawn).
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
			// Externally destroyed; respawn from the path triple, re-track.
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
			// Already on the player; leave it where they put it.
			continue
		else
			// Yank it to the player's tile from wherever it ended up.
			I.forceMove(dest)
		if(istype(I, /obj/item/clothing/suit/armor/ego_gear))
			H.equip_to_slot_or_del(I, ITEM_SLOT_OCLOTHING, TRUE)
		else
			H.put_in_hands(I)

/// Strip-and-rebuild: qdels every tracked weapon/armor on this member,
/// then spawns fresh items from the stored loadout paths and re-equips
/// them. Used at sector boundaries and on team wipe to scrub any
/// run-time state that built up on the items (charge counters, kill
/// trackers, stack buffs, etc.) so progress doesn't carry between
/// sectors or wipe attempts. Idempotent on a stripped-then-rebuilt
/// player; safe to call back-to-back.
/datum/refraction_run/proc/FreshenLoadout(mob/living/carbon/human/H)
	if(!ishuman(H) || !H.ckey)
		return
	var/list/paths = loadouts[H.ckey]
	if(!islist(paths) || !length(paths))
		return
	// Phase 1: tear down. StripMemberGear qdels every tracked ref and
	// sweeps any stray ego items on the player so we can rebuild from a
	// clean slot triple.
	StripMemberGear(H.ckey)
	// Phase 2: rebuild from the stored paths. Mirrors ApplyLoadout's
	// flow (positions 1 & 2 are weapons, position 3 is armor).
	var/list/new_refs = list()
	var/turf/dest = get_turf(H)
	for(var/i in 1 to length(paths))
		var/path = paths[i]
		if(!path)
			new_refs += null
			continue
		var/obj/item/I = new path(dest)
		if(istype(I, /obj/item/clothing/suit/armor/ego_gear))
			var/obj/item/clothing/suit/armor/ego_gear/A = I
			A.equip_delay_self = 0
			H.equip_to_slot_or_del(A, ITEM_SLOT_OCLOTHING, TRUE)
		else
			H.put_in_hands(I)
		RegisterSignal(I, COMSIG_PARENT_QDELETING, PROC_REF(OnTrackedGearQdel))
		new_refs += I
	gear_refs[H.ckey] = new_refs

/// Removes all gear issued to this ckey, then sweeps any other ego items on
/// the player (gear brought from outside the railway).
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
	// Phase 2: catch ego items on the player that we don't own.
	var/mob/living/carbon/human/H = FindMemberByCkey(ckey)
	if(ishuman(H))
		var/list/to_qdel = list()
		for(var/obj/item/I in H.contents)
			if(is_type_in_typecache(I, GLOB.refraction_ego_typecache))
				to_qdel += I
		for(var/obj/item/I as anything in to_qdel)
			qdel(I)

/// Nulls a tracked gear ref when its item is destroyed externally.
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
			// Keep slot position so ReequipLoadout respawns the right path.
			refs[idx] = null
			return

// ---------- State machine ----------

/datum/refraction_run/proc/EnterCheckpoint()
	in_checkpoint = TRUE
	// PauseTimer (not a raw flag set) so the running interval isn't lost.
	PauseTimer()
	current_room = ""
	// Sweep last sector's pens before healing (pens are per-sector).
	RemoveUnusedPens()
	for(var/mob/living/carbon/human/H as anything in members)
		if(QDELETED(H) || !ishuman(H))
			continue
		ready_states[H.ckey] = FALSE
		// Insane (but alive) members defer to the 1s bench timer — healing
		// here would race the COMSIG_HUMAN_INSANE onset and let the AI
		// rebuild itself after we cleared it. Dead members ARE healed here
		// so the run no longer depends on the bench timer alone to revive.
		if(H.sanity_lost && H.stat != DEAD)
			continue
		HealMember(H)
		// FreshenLoadout (not ReequipLoadout) so any per-run state built
		// up on the items — charge counters, kill trackers, accumulated
		// stack buffs — is discarded at every sector boundary AND on
		// every team wipe (both routes hit EnterCheckpoint).
		FreshenLoadout(H)
	TeleportToCheckpoint()

/// Starts the next sector. `force` skips the all-ready + loadout gate.
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
	// First sector resets the timer; later sectors keep the running total.
	if(current_section == 1)
		elapsed_baseline = 0
	// Snapshot baseline so a team wipe can roll the clock back to here.
	elapsed_baseline_at_section_start = elapsed_baseline
	timer_paused = FALSE
	timer_started_at = world.time
	// Hand out pens BEFORE the AdvanceRoomById teleport so they ride along.
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
	// No next room — sector complete.
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

/// Sweeps the line z of cleanable decals and pending gibspawners.
/datum/refraction_run/proc/CleanLineArea()
	if(!loaded_z)
		return
	for(var/turf/T as anything in Z_TURFS(loaded_z))
		for(var/obj/effect/decal/cleanable/D in T)
			qdel(D)
		for(var/obj/effect/gibspawner/G in T)
			qdel(G)

/datum/refraction_run/proc/OnSectionCleared(section_id)
	if(section_id != current_section)
		return
	CleanLineArea()
	last_checkpoint_for_all(section_id)
	// Snapshot cumulative time before EnterCheckpoint pauses the timer.
	sector_finish_times += ElapsedDeciseconds()
	SnapshotSectorLoadouts(section_id)
	if(section_id >= line.section_count)
		OnRunComplete()
		return
	EnterCheckpoint()

/// Builds a per-sector breakdown (time + loadouts) for the leaderboard entry.
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

/// Records each member's loadout + name into sector_loadouts[section_id].
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
	// Do NOT EnterCheckpoint here: the "finished" state is intentionally
	// minimal — halt the timer and let the advance console drive the rest.
	PauseTimer()
	in_checkpoint = TRUE
	current_room = ""
	// Unused sector pens don't carry out as a reward.
	RemoveUnusedPens()
	var/total_ds = ElapsedDeciseconds()
	// Restore attributes now so a player stepping off isn't stuck overridden.
	for(var/mob/living/carbon/human/H as anything in members)
		if(ishuman(H))
			RestoreAttributes(H)
	// Bring everyone to the checkpoint; dead ones via the bench timer.
	TeleportToCheckpoint()
	for(var/mob/living/carbon/human/H as anything in members)
		if(QDELETED(H) || !ishuman(H))
			continue
		// Insane (but alive): bench timer cures after onset finishes.
		// Dead: revived here so success isn't gated on the bench timer.
		if(H.sanity_lost && H.stat != DEAD)
			continue
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
		"sectors"   = BuildSectorBreakdownForLeaderboard(),
	)
	SSrefraction_railway.RecordRun(line.id, entry)
	// Save now so a mid-round crash still preserves the leaderboard.
	SSpersistence.SaveRefractionLeaderboards()
	ShowFinalResults(total_ds)

/// TRUE iff the lobby owner has a mind AND a client on a member mob.
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
/datum/refraction_run/proc/AbandonRun(initiator_ckey)
	// Owner-only, unless the owner is inactive (else a dropped owner
	// softlocks the lane).
	if(initiator_ckey != lobby_owner && IsOwnerActive())
		return FALSE
	if(lobby_state != LOBBY_RUNNING)
		return FALSE
	if(!in_checkpoint)
		return FALSE
	ForceCleanup("Run abandoned by [initiator_ckey].")
	return TRUE

/// State-check-free finalizer for AbandonRun and the disconnect watchdog.
/datum/refraction_run/proc/ForceCleanup(reason)
	if(lobby_state == LOBBY_FINISHED)
		return
	lobby_state = LOBBY_FINISHED
	PauseTimer()
	if(reason)
		log_world("SSrefraction_railway run #[run_uid] ([line?.id]): [reason]")
	// In-flight combat: drain reserves so no further mobs queue up.
	if(current_room && !in_checkpoint)
		WipeRoomReserves(current_room)
	for(var/mob/living/carbon/human/H as anything in members)
		if(ishuman(H))
			RestoreAttributes(H)
	TeleportAllToHub()
	// Cleanup() strips the loadout (no reward for an aborted run); the lane
	// release here is defensive — Cleanup releases too.
	if(loaded_z)
		SSrefraction_railway.ReleaseLane(loaded_z)
		loaded_z = 0
	Cleanup()

/// Return-to-Lobby (finished run): untrack gear so it's kept as the reward.
/datum/refraction_run/proc/ReturnToLobby()
	if(lobby_state != LOBBY_FINISHED)
		return
	// Untrack issued gear so Cleanup's StripMemberGear doesn't qdel it.
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

/// Sends the final-results chat message (total + per-sector) to members.
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

/// Formats deciseconds as `M:SS.s`.
/datum/refraction_run/proc/FormatRefractionTime(ds)
	if(ds <= 0)
		return "0:00.0"
	var/total_seconds = ds * 0.1
	var/min = round(total_seconds / 60)
	var/sec = total_seconds - (min * 60)
	var/sec_str = (sec < 10) ? "0[round(sec, 0.1)]" : "[round(sec, 0.1)]"
	return "[min]:[sec_str]"

/// Handler for COMSIG_LIVING_DEATH + COMSIG_HUMAN_INSANE (dead OR insane).
/datum/refraction_run/proc/OnMemberIncapacitated(mob/source)
	SIGNAL_HANDLER
	if(!source || !(source in members))
		return
	// Body + dropped gear move to the checkpoint now; bench timer below.
	TeleportIncapacitatedToCheckpoint(source)
	// Dedupe: dying-while-insane fires both signals.
	if(source.ckey && !pending_bench[source.ckey])
		pending_bench[source.ckey] = TRUE
		addtimer(CALLBACK(src, PROC_REF(BenchIncapacitatedMember), source), 1 SECONDS)
	// No live members left: roll the failed-sector clock back and retry.
	// current_section is decremented since BeginSector pre-increments it.
	if(!HasLiveMemberInCombat())
		WipeRoomReserves(current_room)
		CleanLineArea()
		current_section = max(0, current_section - 1)
		elapsed_baseline = elapsed_baseline_at_section_start
		// EnterCheckpoint -> HealMember -> ReequipLoadout can sleep via
		// equip_to_slot_or_del's do_after, and we're in a SIGNAL_HANDLER.
		// Defer to a fresh chain.
		INVOKE_ASYNC(src, PROC_REF(EnterCheckpoint))
		// Retry the heal twice — the initial pass during EnterCheckpoint
		// can leave a die-and-insane player with sanity stuck (revive's
		// fully_heal no-ops adjustSanityLoss while stat == DEAD). By t+2s
		// the revive has settled; t+4s catches anything the first retry
		// missed.
		addtimer(CALLBACK(src, PROC_REF(WipeHealRetry)), 2 SECONDS)
		addtimer(CALLBACK(src, PROC_REF(WipeHealRetry)), 4 SECONDS)

/// Fires 1s after death/insanity: revive + heal + cure, then re-equip.
/// Always runs both halves — HealMember is a safe no-op when already
/// healed (EnterCheckpoint's wipe pass may have beat us to it), and
/// ReequipLoadout is idempotent (gear on the player is left alone).
/datum/refraction_run/proc/BenchIncapacitatedMember(mob/living/carbon/human/H)
	if(QDELETED(H) || !ishuman(H) || !(H in members))
		return
	if(H.ckey)
		pending_bench -= H.ckey
	HealMember(H)
	ReequipLoadout(H)

/// Post-wipe safety pass — re-applies HealMember only to members who are
/// still incapacitated (dead or insane). Run twice (2s and 4s after the
/// wipe) so a dead-and-insane player whose first revive left sanity stuck
/// gets a second chance once their stat has transitioned off DEAD.
/datum/refraction_run/proc/WipeHealRetry()
	for(var/mob/living/carbon/human/H as anything in members)
		if(QDELETED(H) || !ishuman(H))
			continue
		if(H.stat != DEAD && !H.sanity_lost)
			continue
		HealMember(H)

// ---------- Timer ----------

/// Disconnect-watchdog timeout: auto-abandon after this with no client.
#define REFRACTION_DISCONNECT_TIMEOUT_DS (60 SECONDS)

/datum/refraction_run/proc/Tick(wait_ds)
	if(lobby_state != LOBBY_RUNNING)
		return
	// Disconnect watchdog: refresh while connected, cleanup past threshold.
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

/// Returns the room_id of the first node in the given (1-based) sector.
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

/// True iff a member is alive AND has a client in combat (AFK doesn't count).
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

/// TRUE if the member can no longer act this combat (dead or insane).
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
	if(QDELETED(H) || !ishuman(H))
		return
	// admin_revive forces regenerate_limbs / regenerate_organs so a
	// dismembered or brain-missing body can come back. Without it,
	// can_be_revived() returns FALSE and the body stays DEAD.
	H.revive(full_heal = TRUE, admin_revive = TRUE)
	// Fallback: if revive's can_be_revived gate refused, the body stays
	// stat == DEAD. Force the stat transition and re-run fully_heal so the
	// in-revive adjustSanityLoss (which silently no-ops on dead bodies)
	// actually clears sanityloss on the retry pass.
	if(H.stat == DEAD)
		H.set_stat(UNCONSCIOUS)
		H.fully_heal(admin_revive = TRUE)
		H.updatehealth()
	CureMemberInsanity(H)

/// Restores a member to fully sane + player-controlled. Safe no-op when
/// healthy. GOTCHA: only call when alive (stat != DEAD) and AFTER insanity
/// onset finishes — never sync from COMSIG_HUMAN_INSANE (onset re-creates
/// ai_controller + panic overlay after the signal returns).
/datum/refraction_run/proc/CureMemberInsanity(mob/living/carbon/human/H)
	if(!ishuman(H) || H.stat == DEAD)
		return
	// Forced bypasses TRAIT_SANITY_HEALING_BLOCKED; skip when full.
	if(H.sanityloss > 0)
		H.adjustSanityLoss(-H.maxSanity, TRUE)
	H.sanity_lost = FALSE
	// ai_controller may be an unconverted typepath if onset was interrupted.
	if(ispath(H.ai_controller))
		H.ai_controller = null
	else if(H.ai_controller)
		QDEL_NULL(H.ai_controller)
	H.remove_status_effect(/datum/status_effect/panicked_type)
	H.remove_status_effect(/datum/status_effect/panicked)
	H.grab_ghost(force = TRUE)
	H.update_sanity_hud()
	H.med_hud_set_sanity()

/// ForceMoves the body to a checkpoint_spawn turf and pulls tracked gear
/// not on the body onto the same tile (gear in a teammate's inv is left).
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

/// Pen-compensation curve by party size (solo heavy, quad none).
/datum/refraction_run/proc/PenCountForLobby(num_players)
	switch(num_players)
		if(1)
			return 4
		if(2)
			return 2
		if(3)
			return 1
	return 0

/// Spawns this sector's mental + salacid medipens into member backpacks.
/datum/refraction_run/proc/GiveSectorPens()
	if(!SSrefraction_railway.give_compensation_pens)
		return
	if(line && !line.give_compensation_pens)
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
	// equip_to_slot_or_del qdels on failure; skip tracking those.
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

/// QDELs every still-live tracked pen and clears the tracking lists.
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

/// Returns refraction landmarks of `type_path` on the claimed z; if
/// `room_id` is set, only matching start_point landmarks pass.
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

/// Round-robin forceMove members (or `specific`) onto checkpoint_spawn
/// landmarks. Skips dead members.
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

/// Round-robin forceMove live members onto start_point landmarks for room_id.
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

/// ForceMove members back to their AddMember-time home turf (if still valid).
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
	// Lane reuse: a prior run may have left it completed; reset first.
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
		// Drain stock so nothing queues up, then qdel the living to flush.
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
	for(var/path in N.extra_preview_mobs)
		if(path in mob_paths)
			continue
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
	// Strip gear before unregister/members.Cut so OnTrackedGearQdel can
	// still resolve its gear_refs slot.
	for(var/ckey in gear_refs)
		StripMemberGear(ckey)
	// Sweep pens before unregister so OnPenQdel can find its slot.
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
