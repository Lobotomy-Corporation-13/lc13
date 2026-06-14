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

// Starlight award constants — tune here, knob in one place.
#define STARLIGHT_BASE_AWARD 100
#define STARLIGHT_PER_UNIQUE_ITEM 10
/// Caps the time bonus on both sides. Reaching the cap requires beating
/// (or overrunning) the expected time by 50% of itself: e.g. on a 9-min
/// expected line, finishing in 4:30 = +50, finishing in 13:30 = -50.
#define STARLIGHT_TIME_BONUS_CAP 50
/// Bias applied to PRUDENCE on every member at run start so that
/// `SanityLossEffect`'s "highest attribute" selector always picks
/// prudence — forcing prudence panics (not justice / fortitude /
/// temperance) inside the railway. The level_buff bumps get_level(),
/// which is what the selector reads; the offsetting stat_bonus
/// cancels the max-sanity inflation that the buff would otherwise
/// cause via get_printed_level_bonus.
#define REFRACTION_PRUDENCE_PANIC_BUFF 5
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
	/// Per-room timing entries, one per room actually entered this run.
	/// Each entry: list("room_id"=..., "sector"=..., "start_ds"=...,
	/// "end_ds"=...). end_ds == 0 means in-progress; closed by the next
	/// AdvanceRoomById or by OnSectionCleared.
	var/list/room_times = list()
	/// Per-ckey achievement state. ckey → list(achievement_id → TRUE/FALSE).
	/// TRUE = "currently earned" (or "still passing" for default-pass
	/// achievements). Evaluated at run complete; entries that resolve to
	/// TRUE fold their `reward` into that player's final Starlight.
	var/list/achievement_state = list()
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
	/// ckey -> volume integer (0..100). Defaults to 50 when unset; the
	/// console panel reads/writes through GetMusicVolume / SetMusicVolume.
	/// Per-run only — never persisted to disk.
	var/list/music_volumes = list()
	/// Sound file path currently looping on CHANNEL_REFRACTION_THEME, or
	/// null if no theme music is active. Used both to dedupe back-to-back
	/// StartThemeMusic calls and to drive the crossfade's "from" track.
	var/current_theme_music = null
	/// Monotonic counter incremented every time a crossfade starts. Each
	/// scheduled fade step carries the token it was queued under and
	/// no-ops if it no longer matches — protects against overlapping
	/// crossfades when phase transitions stack up.
	var/theme_music_fade_token = 0

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
	// Leaver should not keep hearing the run's theme on whatever z they
	// end up on.
	if(M && M.client)
		M.stop_sound_channel(CHANNEL_REFRACTION_THEME)
	members -= M
	if(M.ckey)
		loadouts -= M.ckey
		ready_states -= M.ckey
		last_checkpoint -= M.ckey
		home_turfs -= M.ckey
		pending_bench -= M.ckey
		music_volumes -= M.ckey
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
	// Force prudence to be the highest get_level() so panic always
	// resolves to a prudence panic. Offset stat_bonus by the same
	// amount × PRUDENCE_MOD so max sanity stays where the equalized
	// level set it.
	H.adjust_attribute_buff(PRUDENCE_ATTRIBUTE, REFRACTION_PRUDENCE_PANIC_BUFF)
	H.adjust_attribute_bonus(PRUDENCE_ATTRIBUTE, -REFRACTION_PRUDENCE_PANIC_BUFF * PRUDENCE_MOD)
	H.updatehealth()
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
	// Undo the prudence-panic bias.
	H.adjust_attribute_buff(PRUDENCE_ATTRIBUTE, -REFRACTION_PRUDENCE_PANIC_BUFF)
	H.adjust_attribute_bonus(PRUDENCE_ATTRIBUTE, REFRACTION_PRUDENCE_PANIC_BUFF * PRUDENCE_MOD)
	H.updatehealth()
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
	if(!IsUniqueLoadoutEnforced())
		return FALSE
	return HasUsedItemPath(ckey, path)

/// TRUE iff `ckey` already used `path` in a prior sector's loadout this run.
/// Unlike IsItemPathBlocked, this is independent of the unique-loadout rule —
/// it's informational ("you won't earn the +unique-gear bonus from this one
/// again"), not a hard block on selection.
/datum/refraction_run/proc/HasUsedItemPath(ckey, path)
	if(!ckey || !path)
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
	GiveSectorPensForPlayer(H)
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
	GiveSectorPensForPlayer(H)

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
	// Checkpoint room is silent — theme music is per-combat-node only.
	StopThemeMusic()
	for(var/mob/living/carbon/human/H as anything in members)
		if(QDELETED(H) || !ishuman(H))
			continue
		ready_states[H.ckey] = FALSE
		// Insane (but alive) members defer to a 1s bench timer — healing
		// here would race the COMSIG_HUMAN_INSANE onset and let the AI
		// rebuild itself after we cleared it. The timer used to be
		// scheduled from OnMemberIncapacitated; since insanity no longer
		// teleports individuals, we schedule it from here at sector
		// clear (the first time the panicked player is brought to the
		// checkpoint). Dead members ARE healed here so the run no
		// longer depends on the bench timer alone to revive.
		if(H.sanity_lost && H.stat != DEAD)
			if(H.ckey && !pending_bench[H.ckey])
				pending_bench[H.ckey] = TRUE
				addtimer(CALLBACK(src, PROC_REF(BenchIncapacitatedMember), H), 1 SECONDS)
			continue
		HealMember(H)
		// Always strip and rebuild gear between sectors. Wipes any
		// accumulated run-time state on the items (charge counters, kill
		// trackers, stack buffs, ammo) so progress doesn't carry across
		// the sector boundary. On unique-loadout lines OnSectionCleared
		// has already cleared `loadouts[ckey]` before getting here, so
		// FreshenLoadout no-ops and the player goes into the loadout
		// console for a fresh pick.
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
	AdvanceRoomById(GetFirstRoomIdInSection(current_section))
	return TRUE

/datum/refraction_run/proc/OnRoomCleared(cleared_room_id)
	if(cleared_room_id != current_room)
		return
	// Boss dropped — gently tail off the node's theme over 3s so the
	// silence between rooms reads as resolution, not a hard cut. Falls
	// through to the existing 5s AdvanceRoom delay; the next room's
	// StartThemeMusic call (if any) re-arms the channel cleanly.
	FadeOutThemeMusic(3 SECONDS)
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
	CloseLastRoomTime()
	current_room = room_id
	for(var/mob/living/carbon/human/H as anything in members)
		if(!ishuman(H) || H.stat == DEAD)
			continue
		ReequipLoadout(H)
	TeleportToRoom(room_id)
	MarkRoomEntered(room_id)
	OpenRoomTime(room_id)
	ActivateRoom(room_id)
	// Kick the per-node theme loop. StartThemeMusic on a null path
	// stops any prior track, so non-theme'd nodes silently clear the
	// channel without a separate guard.
	if(line)
		var/datum/refraction_node/N = line.combat_nodes[room_id]
		if(istype(N))
			StartThemeMusic(N.theme_music)
		else
			StopThemeMusic()

/datum/refraction_run/proc/OpenRoomTime(room_id)
	room_times += list(list(
		"room_id"  = room_id,
		"sector"   = current_section,
		"start_ds" = ElapsedDeciseconds(),
		"end_ds"   = 0,
	))

/datum/refraction_run/proc/CloseLastRoomTime()
	if(!length(room_times))
		return
	var/list/last = room_times[length(room_times)]
	if(last["end_ds"] == 0)
		last["end_ds"] = ElapsedDeciseconds()

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
	// Idempotent against duplicate AdvanceRoom callbacks for the same
	// sector-end boundary (e.g. a stale OnRoomCleared 5s timer firing
	// after the legitimate one already snapshotted the sector).
	// Without this, each duplicate appends another ElapsedDeciseconds()
	// to sector_finish_times, inflating the per-sector breakdown in
	// every persisted leaderboard entry.
	if(length(sector_finish_times) >= section_id)
		return
	CleanLineArea()
	last_checkpoint_for_all(section_id)
	// Snapshot cumulative time before EnterCheckpoint pauses the timer.
	CloseLastRoomTime()
	sector_finish_times += ElapsedDeciseconds()
	SnapshotSectorLoadouts(section_id)
	if(section_id >= line.section_count)
		OnRunComplete()
		return
	// Unique-loadout lines force a fresh pick each sector. Strip every
	// member's gear + clear their stored loadout so the BeginSector gate
	// (`if(!loadouts[M.ckey]) return FALSE`) makes them re-author from
	// the loadout console. SnapshotSectorLoadouts above already recorded
	// the items used this sector for IsItemPathBlocked's blocklist, so
	// they can't be re-picked. Team-wipe paths into EnterCheckpoint do
	// NOT pass through here, so a wipe still resets gear via
	// FreshenLoadout instead of forcing a new loadout.
	if(IsUniqueLoadoutEnforced())
		for(var/mob/M as anything in members)
			if(!M?.ckey)
				continue
			StripMemberGear(M.ckey)
			loadouts -= M.ckey
	EnterCheckpoint()

/// Builds a per-sector breakdown (time + loadouts + per-room times) for
/// the leaderboard entry.
/datum/refraction_run/proc/BuildSectorBreakdownForLeaderboard()
	var/list/out = list()
	var/cap = length(sector_finish_times)
	if(line && line.section_count > 0)
		cap = min(cap, line.section_count)
	for(var/i in 1 to cap)
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
			"rooms"   = BuildRoomTimesForSector(i),
		))
	return out

/// Builds a list of {room_id, name, time_ds} for every room entered in
/// the given sector index. Filters room_times by sector and resolves the
/// node display name from line.combat_nodes.
/datum/refraction_run/proc/BuildRoomTimesForSector(sector_index)
	var/list/out = list()
	for(var/list/rt as anything in room_times)
		if(rt["sector"] != sector_index)
			continue
		if(rt["end_ds"] <= 0)
			continue
		var/elapsed = rt["end_ds"] - rt["start_ds"]
		var/rid = rt["room_id"]
		var/node_name = ""
		var/datum/refraction_node/N = islist(line?.combat_nodes) ? line.combat_nodes[rid] : null
		if(istype(N))
			node_name = N.name
		out += list(list(
			"room_id" = rid,
			"name"    = node_name,
			"time_ds" = max(0, elapsed),
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
	StopThemeMusic()
	// Unused sector pens don't carry out as a reward.
	RemoveUnusedPens()
	var/total_ds = ElapsedDeciseconds()
	// Heal before RestoreAttributes: the attribute drop recalcs maxHealth
	// via updatehealth(), which kills any wounded player whose damage now
	// exceeds the new max. Heal first zeros damage, so the recalc lands
	// at health == new maxHealth. TeleportToCheckpoint runs last because
	// it skips DEAD mobs.
	for(var/mob/living/carbon/human/H as anything in members)
		if(QDELETED(H) || !ishuman(H))
			continue
		if(H.sanity_lost && H.stat != DEAD)
			continue
		HealMember(H)
	for(var/mob/living/carbon/human/H as anything in members)
		if(ishuman(H))
			RestoreAttributes(H)
	TeleportToCheckpoint()
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
	// Save now so a mid-round crash, sandbox round, or admin abort still
	// preserves the leaderboard AND the mobs we revealed during the run.
	// Round-end persistence (CollectData) handles these too but is gated
	// on `mode.allow_persistence_save`.
	SSpersistence.SaveRefractionLeaderboards()
	SSpersistence.SaveRefractionEncounters()
	AwardStarlightProgression(total_ds)
	ShowFinalResults(total_ds)

/// Awards per-ckey Starlight + marks the line completed. Award formula:
///   base + time bonus + (unique loadout items × per-item, only when
///   loadout variety is a player choice).
/// Time bonus is signed: positive when the run beats `line.expected_time_seconds`,
/// negative when it overruns. Loadout-variety bonus is suppressed when the
/// line forces a new loadout per sector — players don't get rewarded for a
/// variety the system was going to enforce on them anyway.
// ---------- Achievements ----------

/// Seed achievement state for every living member when a boss mob with
/// registered achievements spawns. Each member's per-achievement entry
/// is set to the achievement's default_state — but only if the entry
/// isn't already present, so a player who already earned a re-spawned
/// boss's achievement on an earlier kill doesn't get reset.
/datum/refraction_run/proc/InitAchievementsForMob(mob/M)
	if(!M)
		return
	var/list/entries = SSrefraction_railway.mob_achievements[M.type]
	if(!islist(entries) || !length(entries))
		return
	for(var/mob/X as anything in members)
		if(!X?.ckey)
			continue
		// Veteran gate: achievements are only earnable for ckeys that
		// have completed this line at least once. First-time runners
		// don't get their state seeded → no chat callout, no SL grant,
		// no leakage that the achievements exist yet.
		if(!SSrefraction_railway.HasCompletedLine(X.ckey, line.id))
			continue
		var/list/per = achievement_state[X.ckey]
		if(!islist(per))
			per = list()
			achievement_state[X.ckey] = per
		for(var/list/entry as anything in entries)
			if(!islist(entry))
				continue
			var/aid = entry["id"]
			if(!aid)
				continue
			if(per[aid] != null)
				continue
			per[aid] = entry["default_state"] ? TRUE : FALSE

/// Sets achievement_state[ckey][id] = value, but ONLY if the ckey was
/// already seeded by InitAchievementsForMob (i.e. they are a veteran of
/// this line). First-time runners have no state, and event hooks calling
/// this proc no-op on them — keeps the gate honest at the event layer.
/datum/refraction_run/proc/MarkAchievement(ckey, achievement_id, value)
	if(!ckey || !achievement_id)
		return
	var/list/per = achievement_state[ckey]
	if(!islist(per))
		return
	if(per[achievement_id] == null)
		return
	per[achievement_id] = value ? TRUE : FALSE

/datum/refraction_run/proc/EarnAchievement(ckey, achievement_id)
	MarkAchievement(ckey, achievement_id, TRUE)

/datum/refraction_run/proc/FailAchievement(ckey, achievement_id)
	MarkAchievement(ckey, achievement_id, FALSE)

/// Awards per-ckey Starlight + marks the line completed. Components:
///   base                — fixed STARLIGHT_BASE_AWARD floor.
///   time bonus          — signed. Reaches ±STARLIGHT_TIME_BONUS_CAP when
///                         the run beats / overruns expected by 50% of
///                         itself (e.g. on a 9-min line: 4:30 = +50,
///                         13:30 = -50).
///   unique gear         — +STARLIGHT_PER_UNIQUE_ITEM per distinct
///                         weapon/armor path across all sectors.
///   achievements        — sums `reward` of every achievement_state entry
///                         that resolved to TRUE for this ckey.
/// `multiplier` < 1 scales the final per-ckey award (used by
/// EndRunEarly so leaving partway pays a fraction). When `early` is
/// TRUE the line completion mark is skipped — quitting early doesn't
/// satisfy the veteran gate for achievement seeding.
/datum/refraction_run/proc/AwardStarlightProgression(total_ds, multiplier = 1.0, early = FALSE)
	var/total_seconds = round(total_ds / 10)
	var/expected = max(1, line.expected_time_seconds)
	var/time_diff = expected - total_seconds
	var/half_expected = max(1, round(expected / 2))
	var/time_bonus = clamp(round(time_diff * STARLIGHT_TIME_BONUS_CAP / half_expected), -STARLIGHT_TIME_BONUS_CAP, STARLIGHT_TIME_BONUS_CAP)
	// Per-ckey: collect unique weapon/armor paths used across every sector.
	var/list/unique_by_ckey = list()
	for(var/list/snap as anything in sector_loadouts)
		if(!islist(snap))
			continue
		for(var/list/entry as anything in snap)
			var/ck = entry["ckey"]
			if(!ck)
				continue
			var/list/seen = unique_by_ckey[ck]
			if(!islist(seen))
				seen = list()
				unique_by_ckey[ck] = seen
			var/list/lo = entry["loadout"]
			if(islist(lo))
				seen |= lo
	for(var/ckey in unique_by_ckey)
		var/list/seen = unique_by_ckey[ckey]
		var/unique_count = length(seen)
		var/unique_bonus = unique_count * STARLIGHT_PER_UNIQUE_ITEM
		var/list/earned_names = list()
		var/list/earned_rewards = list()
		var/list/earned_awards = list()
		var/achievement_bonus = 0
		var/list/per = achievement_state[ckey]
		if(islist(per))
			for(var/aid in per)
				if(!per[aid])
					continue
				var/list/entry = SSrefraction_railway.achievements_by_id[aid]
				if(!islist(entry))
					continue
				achievement_bonus += entry["reward"]
				earned_names += entry["name"]
				earned_rewards += entry["reward"]
				if(entry["award"])
					earned_awards += entry["award"]
		var/raw_award = STARLIGHT_BASE_AWARD + time_bonus + unique_bonus + achievement_bonus
		var/award = round(raw_award * multiplier)
		SSrefraction_railway.AwardStarlight(ckey, award)
		if(!early)
			SSrefraction_railway.MarkLineCompleted(ckey, line.id)
		var/mob/M = FindMemberByCkey(ckey)
		if(!M)
			continue
		// Cross-register the LC13 medal so the railway achievement shows
		// up in the standard achievements HUD / profile, not just in the
		// railway's own record. The Starlight bonus has already been
		// banked above.
		if(M.client)
			for(var/award_path in earned_awards)
				M.client.give_award(award_path, M)
		var/balance = SSrefraction_railway.GetStarlight(ckey)
		// Headline: total + new balance.
		if(award > 0)
			to_chat(M, span_nicegreen("You earned [award] Starlight. (balance: [balance])"))
		else if(award < 0)
			to_chat(M, span_warning("Your slow finish cost you [-award] Starlight. (balance: [balance])"))
		else
			to_chat(M, span_notice("You finished, but earned no Starlight this run. (balance: [balance])"))
		// Breakdown: one line per source, signed.
		if(early)
			var/pct = round(multiplier * 100)
			to_chat(M, span_warning("• Run ended early ([current_section]/[line.section_count] sectors cleared, [pct]%) — final award scaled by [pct]%"))
		to_chat(M, span_notice("• Base clear: +[STARLIGHT_BASE_AWARD] SL"))
		if(time_bonus > 0)
			to_chat(M, span_notice("• Time bonus (under expected): +[time_bonus] SL"))
		else if(time_bonus < 0)
			to_chat(M, span_warning("• Time penalty (over expected): [time_bonus] SL"))
		else
			to_chat(M, span_notice("• Time bonus: 0 SL"))
		if(unique_bonus > 0)
			to_chat(M, span_notice("• Unique gear ([unique_count] item\s): +[unique_bonus] SL"))
		if(length(earned_names))
			for(var/i in 1 to length(earned_names))
				to_chat(M, span_nicegreen("• Achievement \"[earned_names[i]]\": +[earned_rewards[i]] SL"))

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

/// Owner-triggered early end. Pays a fraction of the normal award
/// scaled by sectors-cleared / total-sectors, then sends everyone
/// back to the hub via the same path as a successful return. Skips
/// the leaderboard record and the line-completion mark.
/datum/refraction_run/proc/EndRunEarly(initiator_ckey)
	if(initiator_ckey != lobby_owner && IsOwnerActive())
		return FALSE
	if(lobby_state != LOBBY_RUNNING)
		return FALSE
	if(!in_checkpoint)
		return FALSE
	lobby_state = LOBBY_FINISHED
	PauseTimer()
	in_checkpoint = TRUE
	current_room = ""
	RemoveUnusedPens()
	var/total_ds = ElapsedDeciseconds()
	var/section_count = max(1, line.section_count)
	var/multiplier = clamp(current_section / section_count, 0, 1)
	AwardStarlightProgression(total_ds, multiplier, TRUE)
	log_world("SSrefraction_railway run #[run_uid] ([line?.id]): ended early by [initiator_ckey] at sector [current_section]/[section_count]")
	for(var/mob/living/carbon/human/H as anything in members)
		if(ishuman(H))
			RestoreAttributes(H)
	TeleportAllToHub()
	if(loaded_z)
		SSrefraction_railway.ReleaseLane(loaded_z)
		loaded_z = 0
	Cleanup()
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

/// Return-to-Lobby (finished run): teleport everyone home. Cleanup's
/// StripMemberGear then qdels every issued (and stray) EGO item so
/// players leave the run with nothing.
/datum/refraction_run/proc/ReturnToLobby()
	if(lobby_state != LOBBY_FINISHED)
		return
	TeleportAllToHub()
	if(loaded_z)
		SSrefraction_railway.ReleaseLane(loaded_z)
		loaded_z = 0
	Cleanup()

/// Sends the final-results chat message (total + per-sector) to members.
/datum/refraction_run/proc/ShowFinalResults(total_ds)
	var/list/lines_text = list()
	lines_text += "<b>Refraction Railway: [line.name] cleared!</b>"
	var/cap = length(sector_finish_times)
	if(line && line.section_count > 0)
		cap = min(cap, line.section_count)
	for(var/i in 1 to cap)
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
	// Both death and insanity now leave the affected player in place
	// so teammates can intervene (defib a corpse, mental medipen a
	// panicked teammate, etc.). Individuals are only pulled to the
	// checkpoint when the WHOLE team goes down — see the wipe block
	// below. Sector-clear EnterCheckpoint will pull leftover corpses
	// and heal them as part of its normal sweep.
	// No live members left: roll the failed-sector clock back and retry.
	// current_section is decremented since BeginSector pre-increments it.
	if(!HasLiveMemberInCombat())
		WipeRoomReserves(current_room)
		CleanLineArea()
		current_section = max(0, current_section - 1)
		// Roll the clock back AND mark the timer paused so the async
		// EnterCheckpoint below doesn't re-add the failed-attempt
		// duration via PauseTimer's `elapsed_baseline += world.time -
		// timer_started_at` math. Without this, the failed attempt
		// leaks into sector_finish_times even though room_times for
		// the failed sector are correctly cut below.
		elapsed_baseline = elapsed_baseline_at_section_start
		timer_paused = TRUE
		// Discard any room_times from the failed sector — the clock is
		// rolling back to its start, so those entries are stale.
		for(var/i in length(room_times) to 1 step -1)
			var/list/rt = room_times[i]
			if(rt["sector"] > current_section)
				room_times.Cut(i, i + 1)
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

/// Spawns this sector's mental + salacid medipens into one member's
/// backpack, alongside the weapon/armor handout. Called from
/// ApplyLoadout (first/unique-loadout pick) and FreshenLoadout
/// (re-issue at sector boundary), so pens land in the checkpoint
/// instead of mid-room. Idempotent per sector: pen_refs[ckey] is
/// cleared at EnterCheckpoint, so a second loadout pick before the
/// sector starts won't double-issue.
/datum/refraction_run/proc/GiveSectorPensForPlayer(mob/living/carbon/human/H)
	if(!SSrefraction_railway.give_compensation_pens)
		return
	if(line && !line.give_compensation_pens)
		return
	if(!ishuman(H) || !H.ckey || IsMemberOutOfAction(H))
		return
	var/list/refs = pen_refs[H.ckey]
	if(islist(refs) && length(refs))
		return
	var/count = PenCountForLobby(LiveMemberCount())
	if(count <= 0)
		return
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

// ---------- Per-node theme music ----------
// Each combat node may declare an optional looping theme music track.
// When AdvanceRoomById lands on a node with theme music, the run plays
// the track distance-independently on CHANNEL_REFRACTION_THEME at every
// member's personal volume. Encounter procs can crossfade to a different
// track via SwitchThemeMusic (e.g. the Overseer's phase-2 swap).

/// Player's stored volume, defaulting to 50. Defaults are NOT stored —
/// only an explicit SetMusicVolume populates the dict, so a brand-new
/// run begins with everyone at the default without a startup pass.
/datum/refraction_run/proc/GetMusicVolume(ckey)
	if(!ckey)
		return 50
	if(!isnum(music_volumes[ckey]))
		return 50
	return music_volumes[ckey]

/// Stores the new volume (clamped 0..100). If a theme track is live,
/// sends a SOUND_UPDATE on that one client so the slider behaves
/// like a live mixer without restarting the loop.
/datum/refraction_run/proc/SetMusicVolume(ckey, volume)
	if(!ckey)
		return
	volume = clamp(round(volume), 0, 100)
	music_volumes[ckey] = volume
	if(!current_theme_music)
		return
	var/mob/M = FindMemberByCkey(ckey)
	if(!M || !M.client)
		return
	var/sound/upd = sound(null, repeat = TRUE, channel = CHANNEL_REFRACTION_THEME, volume = volume)
	upd.status = SOUND_UPDATE
	SEND_SOUND(M, upd)

/// Begins (or replaces) the looping track on CHANNEL_REFRACTION_THEME
/// for every live member at their personal volume. Idempotent: a second
/// call with the same track is a no-op so AdvanceRoomById can call it
/// freely. Null track_path is a hard stop.
/datum/refraction_run/proc/StartThemeMusic(track_path)
	if(!track_path)
		StopThemeMusic()
		return
	if(current_theme_music == track_path)
		return
	current_theme_music = track_path
	// Any in-flight crossfade is now stale.
	theme_music_fade_token++
	for(var/mob/M as anything in members)
		PlayThemeMusicForMember(M, track_path)

/// Per-member helper used by StartThemeMusic and the resume side of
/// SwitchThemeMusic. Always plays the channel at this member's stored
/// volume, repeating, with reverb off (distance-independent).
/datum/refraction_run/proc/PlayThemeMusicForMember(mob/M, track_path)
	if(!M || !M.client)
		return
	if(!track_path)
		return
	var/vol = GetMusicVolume(M.ckey)
	var/sound/song = sound(track_path, repeat = TRUE, channel = CHANNEL_REFRACTION_THEME, volume = vol)
	M.playsound_local(get_turf(M), null, vol, channel = CHANNEL_REFRACTION_THEME, S = song, use_reverb = FALSE)

/// Crossfade entry point. Fades the current track to volume 0 across
/// `fade_seconds` (in `steps` SOUND_UPDATE ticks), then stops the
/// channel and starts the new track at the player's volume. Each
/// scheduled step carries the fade token it was queued under and
/// no-ops if a later SwitchThemeMusic / StartThemeMusic invalidated
/// it — so back-to-back phase swaps don't cross wires.
/datum/refraction_run/proc/SwitchThemeMusic(new_track_path, fade_seconds = 2 SECONDS, steps = 20)
	if(!current_theme_music)
		StartThemeMusic(new_track_path)
		return
	theme_music_fade_token++
	var/token = theme_music_fade_token
	var/step_delay = max(1, round(fade_seconds / steps))
	for(var/step in 1 to steps)
		addtimer(CALLBACK(src, PROC_REF(FadeThemeMusicStep), token, step, steps), step_delay * step)
	addtimer(CALLBACK(src, PROC_REF(CompleteThemeMusicSwitch), token, new_track_path), step_delay * steps)

/// Ducks every live member's CHANNEL_REFRACTION_THEME volume to
/// `fraction = 1 - step/steps` of their stored level. Bailout on a
/// stale token so a newer fade / Stop wins.
/datum/refraction_run/proc/FadeThemeMusicStep(token, step, steps)
	if(token != theme_music_fade_token)
		return
	var/fraction = max(0, 1 - (step / steps))
	for(var/mob/M as anything in members)
		if(!M || !M.client)
			continue
		var/vol = round(GetMusicVolume(M.ckey) * fraction)
		var/sound/upd = sound(null, repeat = TRUE, channel = CHANNEL_REFRACTION_THEME, volume = vol)
		upd.status = SOUND_UPDATE
		SEND_SOUND(M, upd)

/// End of fade: stop the channel cleanly, then start the new track at
/// each member's stored volume. Stale tokens bail.
/datum/refraction_run/proc/CompleteThemeMusicSwitch(token, new_track_path)
	if(token != theme_music_fade_token)
		return
	for(var/mob/M as anything in members)
		if(M && M.client)
			M.stop_sound_channel(CHANNEL_REFRACTION_THEME)
	current_theme_music = null
	StartThemeMusic(new_track_path)

/// Stops the theme music channel on every member, clears state, and
/// invalidates any in-flight fade.
/datum/refraction_run/proc/StopThemeMusic()
	if(!current_theme_music)
		return
	current_theme_music = null
	theme_music_fade_token++
	for(var/mob/M as anything in members)
		if(M && M.client)
			M.stop_sound_channel(CHANNEL_REFRACTION_THEME)

/// Soft cousin of StopThemeMusic — ducks the current track to silence
/// over `fade_seconds` instead of cutting it. Internally routes through
/// SwitchThemeMusic with a null target: same 20-step SOUND_UPDATE fade,
/// then CompleteThemeMusicSwitch stops the channel cleanly. No-op if
/// nothing is currently playing.
/datum/refraction_run/proc/FadeOutThemeMusic(fade_seconds = 3 SECONDS)
	if(!current_theme_music)
		return
	SwitchThemeMusic(null, fade_seconds)

/// Plays the 5-second mailman test clip one-shot on the theme channel
/// at this player's current volume. Re-uses the same channel so the
/// preview matches the live track exactly. If a theme track is
/// currently looping, that loop resumes after the clip finishes — but
/// since the test channel overlap stops the loop on this client, we
/// re-arm the loop right after the clip ends.
/datum/refraction_run/proc/PlayMusicTestSound(ckey)
	if(!ckey)
		return
	var/mob/M = FindMemberByCkey(ckey)
	if(!M || !M.client)
		return
	var/vol = GetMusicVolume(ckey)
	var/sound/clip = sound('sound/creatures/lc13/mailman.ogg', repeat = FALSE, channel = CHANNEL_REFRACTION_THEME, volume = vol)
	M.playsound_local(get_turf(M), null, vol, channel = CHANNEL_REFRACTION_THEME, S = clip, use_reverb = FALSE)
	// Re-arm the loop for this client 5s later if a track is still
	// supposed to be playing. The test clip is ~5s and shares the
	// channel; without this the live track stays silenced on the
	// tester's client only.
	if(current_theme_music)
		var/track = current_theme_music
		addtimer(CALLBACK(src, PROC_REF(ResumeThemeMusicForMember), M, track), 5 SECONDS)

/// Restarts the supplied track on a single client if it's still the
/// run's current_theme_music. Used by the test-sound resume hook.
/datum/refraction_run/proc/ResumeThemeMusicForMember(mob/M, track_path)
	if(!M || !M.client)
		return
	if(current_theme_music != track_path)
		return
	PlayThemeMusicForMember(M, track_path)

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
	if(!length(live_ckeys))
		return
	// Snapshot the pre-mark state so we only persist when a brand-new
	// (ckey, mob_path) pair was actually added. Avoids hammering disk on
	// every room hop when nothing new was learned.
	var/dirty = FALSE
	for(var/ckey in live_ckeys)
		var/list/seen = SSrefraction_railway.encountered_mobs[ckey]
		if(!islist(seen))
			dirty = TRUE
			break
		for(var/path in mob_paths)
			if(!(path in seen))
				dirty = TRUE
				break
		if(dirty)
			break
	SSrefraction_railway.MarkEncountered(live_ckeys, mob_paths)
	if(dirty)
		SSpersistence.SaveRefractionEncounters()

// ---------- Cleanup ----------

/datum/refraction_run/proc/Cleanup()
	StopThemeMusic()
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
