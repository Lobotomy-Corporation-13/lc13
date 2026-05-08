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
	/// ckey -> list(weapon_path1, weapon_path2, armor_path).
	var/list/loadouts = list()
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
		UnregisterSignal(M, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
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
	RegisterSignal(M, COMSIG_LIVING_DEATH, PROC_REF(OnMemberDeath))
	RegisterSignal(M, COMSIG_PARENT_QDELETING, PROC_REF(OnMemberQdel))
	return TRUE

/datum/refraction_run/proc/RemoveMember(mob/M)
	if(!(M in members))
		return FALSE
	UnregisterSignal(M, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
	members -= M
	if(M.ckey)
		loadouts -= M.ckey
		ready_states -= M.ckey
		last_checkpoint -= M.ckey
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

/datum/refraction_run/proc/StartRun()
	if(lobby_state != LOBBY_OPEN)
		return FALSE
	if(!length(members))
		return FALSE
	if(!EnsureMapsLoaded())
		return FALSE
	lobby_state = LOBBY_RUNNING
	BuildEligibleEgoLists()
	for(var/mob/living/carbon/human/H as anything in members)
		if(!ishuman(H))
			continue
		ApplyAttributeOverride(H)
		last_checkpoint[H.ckey] = 0
		ready_states[H.ckey] = FALSE
	EnterCheckpoint()
	return TRUE

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
	StripCurrentEgo(H)
	for(var/wpath in weapon_paths)
		var/obj/item/W = new wpath(get_turf(H))
		H.put_in_hands(W)
	var/obj/item/clothing/suit/armor/ego_gear/A = new armor_path(get_turf(H))
	// Force-equip with bypass; the no-delay equip path used by purchase consoles.
	H.equip_to_slot_or_del(A, ITEM_SLOT_OCLOTHING, TRUE)
	loadouts[ckey] = list(weapon_paths[1], weapon_paths[2], armor_path)
	return TRUE

/datum/refraction_run/proc/ReequipLoadout(mob/living/carbon/human/H)
	if(!ishuman(H) || !H.ckey)
		return
	var/list/desired = loadouts[H.ckey]
	if(!islist(desired) || length(desired) < 3)
		return
	// Inventory-driven repair: only spawn what's missing.
	var/list/owned = list()
	for(var/obj/item/I in H.contents)
		if(is_type_in_typecache(I, GLOB.refraction_ego_typecache))
			owned += I.type
	for(var/i in 1 to 2)
		var/wpath = desired[i]
		if(wpath && !(wpath in owned))
			var/obj/item/W = new wpath(get_turf(H))
			H.put_in_hands(W)
	var/armor_path = desired[3]
	if(armor_path && !(armor_path in owned))
		var/obj/item/clothing/suit/armor/ego_gear/A = new armor_path(get_turf(H))
		H.equip_to_slot_or_del(A, ITEM_SLOT_OCLOTHING, TRUE)

/datum/refraction_run/proc/StripCurrentEgo(mob/living/carbon/human/H)
	if(!ishuman(H))
		return
	var/list/to_remove = list()
	for(var/obj/item/I in H.contents)
		if(is_type_in_typecache(I, GLOB.refraction_ego_typecache))
			to_remove += I
	for(var/obj/item/I as anything in to_remove)
		qdel(I)

// ---------- State machine ----------

/datum/refraction_run/proc/EnterCheckpoint()
	in_checkpoint = TRUE
	timer_paused = TRUE
	current_room = ""
	for(var/mob/living/carbon/human/H as anything in members)
		if(!ishuman(H) || H.stat == DEAD)
			continue
		HealMember(H)
		ready_states[H.ckey] = FALSE
	TeleportToCheckpoint()
	// Briefing console reads `current_section + 1` so it reflects the upcoming sector.

/datum/refraction_run/proc/BeginSector(begin_ckey)
	if(begin_ckey != lobby_owner)
		return FALSE
	if(!in_checkpoint)
		return FALSE
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
	timer_paused = FALSE
	timer_started_at = world.time
	AdvanceRoomById(GetFirstRoomIdInSection(current_section))
	return TRUE

/datum/refraction_run/proc/OnRoomCleared(cleared_room_id)
	if(cleared_room_id != current_room)
		return
	addtimer(CALLBACK(src, PROC_REF(AdvanceRoom)), 5 SECONDS)

/datum/refraction_run/proc/AdvanceRoom()
	var/next_id = GetNextRoomIdInSection(current_section, current_room)
	if(!next_id)
		return
	AdvanceRoomById(next_id)

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
	if(section_id >= line.section_count)
		OnRunComplete()
		return
	EnterCheckpoint()

/datum/refraction_run/proc/last_checkpoint_for_all(section_id)
	for(var/mob/M as anything in members)
		if(!M.ckey)
			continue
		last_checkpoint[M.ckey] = section_id

/datum/refraction_run/proc/OnRunComplete()
	if(lobby_state == LOBBY_FINISHED)
		return
	lobby_state = LOBBY_FINISHED
	timer_paused = TRUE
	var/total_ds = ElapsedDeciseconds()
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
	)
	SSrefraction_railway.RecordRun(line.id, entry)
	// TODO: persist via SSpersistence.SaveRefractionLeaderboards once that's added.
	for(var/mob/living/carbon/human/H as anything in members)
		if(ishuman(H))
			RestoreAttributes(H)
	TeleportAllToHub()
	Cleanup()

/datum/refraction_run/proc/OnMemberDeath(mob/source, gibbed)
	SIGNAL_HANDLER
	if(!source || !(source in members))
		return
	addtimer(CALLBACK(src, PROC_REF(BenchDeadMember), source), 1 SECONDS)
	// If this leaves no live members in the active room and reserves remain,
	// force-advance the team to the checkpoint to prevent stale spawns.
	if(!HasLiveMemberInCombat())
		WipeRoomReserves(current_room)
		EnterCheckpoint()

/datum/refraction_run/proc/BenchDeadMember(mob/living/carbon/human/H)
	if(!ishuman(H) || !(H in members))
		return
	if(H.stat != DEAD)
		return
	H.revive(full_heal = TRUE, admin_revive = FALSE)
	HealMember(H)
	ReequipLoadout(H)
	// Last reached checkpoint, or the staging area if none reached yet.
	TeleportToCheckpoint(H)

// ---------- Timer ----------

/datum/refraction_run/proc/Tick(wait_ds)
	if(lobby_state != LOBBY_RUNNING)
		return
	// Timer is queried via ElapsedDeciseconds(); no per-tick work needed beyond
	// hooks like idle detection in the future.

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
	if(!islist(sector) || !islist(sector["nodes"]) || !length(sector["nodes"]))
		return ""
	var/list/node = sector["nodes"][1]
	return node["name"]

/// Returns the room_id of the next node in the same sector, or "" if last.
/datum/refraction_run/proc/GetNextRoomIdInSection(section_index, room_id)
	var/list/sector = GetSectorBriefing(section_index)
	if(!islist(sector) || !islist(sector["nodes"]))
		return ""
	var/list/nodes = sector["nodes"]
	for(var/i in 1 to length(nodes))
		var/list/node = nodes[i]
		if(node["name"] == room_id && i < length(nodes))
			var/list/next_node = nodes[i + 1]
			return next_node["name"]
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

/datum/refraction_run/proc/HasLiveMemberInCombat()
	if(in_checkpoint)
		return TRUE
	for(var/mob/M as anything in members)
		if(M.stat != DEAD)
			return TRUE
	return FALSE

/datum/refraction_run/proc/HealMember(mob/living/carbon/human/H)
	if(!ishuman(H))
		return
	H.revive(full_heal = TRUE, admin_revive = FALSE)

// ---------- Landmark lookup ----------

/// Returns refraction landmarks of `type_path` on this run's claimed z. If
/// `room_id` is non-null, only player_spawn landmarks with a matching room_id
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
			if(!istype(L, /obj/effect/landmark/refraction/player_spawn))
				continue
			var/obj/effect/landmark/refraction/player_spawn/PS = L
			if(PS.room_id != room_id)
				continue
		out += L
	return out

// ---------- Stubs to wire up alongside maps + wave_system ----------

/datum/refraction_run/proc/TeleportToCheckpoint(mob/specific)
	// TODO: forceMove members (or the specific mob) round-robin onto
	// GetRefractionLandmarks(/obj/effect/landmark/refraction/checkpoint_spawn) turfs.
	return

/datum/refraction_run/proc/TeleportToRoom(room_id)
	// TODO: forceMove all live members round-robin onto
	// GetRefractionLandmarks(/obj/effect/landmark/refraction/player_spawn, room_id).
	return

/datum/refraction_run/proc/TeleportAllToHub()
	// TODO: forceMove members back to a railway-hub landmark (lives on a
	// permanent z, not on `loaded_z`) and qdel their snapshotted run-side state.
	return

/datum/refraction_run/proc/ActivateRoom(room_id)
	// TODO: once wave_system.dm is in the DME, find the wave_controllers with
	// id == "refraction_<run_uid>_<room_id>" and call Activate() on them.
	return

/datum/refraction_run/proc/WipeRoomReserves(room_id)
	// TODO: drop any lingering reserve / pending spawns for the named room
	// to prevent stale mobs after a wipe.
	return

/datum/refraction_run/proc/MarkRoomEntered(room_id)
	var/list/sector = GetSectorBriefing(current_section)
	if(!islist(sector) || !islist(sector["nodes"]))
		return
	var/list/nodes = sector["nodes"]
	for(var/list/node as anything in nodes)
		if(node["name"] != room_id)
			continue
		var/list/mobs = node["mobs"]
		if(!islist(mobs))
			return
		var/list/live_ckeys = list()
		for(var/mob/M as anything in members)
			if(M.ckey && M.stat != DEAD)
				live_ckeys += M.ckey
		SSrefraction_railway.MarkEncountered(live_ckeys, mobs)
		return

// ---------- Cleanup ----------

/datum/refraction_run/proc/Cleanup()
	if(loaded_z)
		SSrefraction_railway.ReleaseLane(loaded_z)
		loaded_z = 0
	for(var/mob/M as anything in members)
		UnregisterSignal(M, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
	members.Cut()
	loadouts.Cut()
	ready_states.Cut()
	last_checkpoint.Cut()
	original_attributes.Cut()
	qdel(src)
