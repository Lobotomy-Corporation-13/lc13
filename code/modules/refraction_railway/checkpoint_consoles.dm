/*
 * Checkpoint-room consoles: the wall-mounted briefing display, and the
 * "Begin Sector" advance console. Both live in every line's checkpoint area
 * (one of each per line) and read run state from /datum/refraction_run.
 *
 * Briefing cards have two states per ckey: unrevealed (silhouette + damage
 * type + derived weakness) and revealed (full combat-log-book stats + tip).
 * The encountered-mob set is persisted via SSpersistence; cards stay revealed
 * across rounds.
 */

// ---------- Briefing display ----------

/obj/structure/refraction_briefing
	name = "refraction sector briefing"
	desc = "A wall-mounted display showing the upcoming sector's hostile composition."
	icon = 'icons/obj/computer.dmi'
	icon_state = "explosive"
	density = FALSE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE

/obj/structure/refraction_briefing/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	ui_interact(user)

/obj/structure/refraction_briefing/ui_interact(mob/user, datum/tgui/ui)
	var/datum/refraction_run/R = SSrefraction_railway.GetRunForCkey(user.ckey)
	if(!R)
		to_chat(user, span_warning("You aren't part of an active refraction run."))
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RefractionBriefing", "Sector Briefing")
		ui.open()

/obj/structure/refraction_briefing/ui_data(mob/user)
	var/list/data = list()
	var/datum/refraction_run/R = SSrefraction_railway.GetRunForCkey(user.ckey)
	if(!R)
		return data
	var/idx = R.current_section + 1
	if(idx > length(R.line.sector_briefings))
		data["finished"] = TRUE
		return data
	var/list/sector = R.line.sector_briefings[idx]
	data["sector"] = list(
		"name"         = sector["name"],
		"description"  = sector["description"],
		"faction"      = sector["faction"],
		"damage_hints" = sector["damage_hints"],
		"is_boss"      = sector["is_boss"],
	)
	data["sector_index"] = idx
	data["nodes"] = BuildNodesPayload(user, sector, R)
	return data

/obj/structure/refraction_briefing/proc/BuildNodesPayload(mob/user, list/sector, datum/refraction_run/R)
	var/list/out = list()
	if(!islist(sector["node_ids"]))
		return out
	var/list/seen = SSrefraction_railway.encountered_mobs[user.ckey] || list()
	for(var/node_id in sector["node_ids"])
		var/datum/refraction_node/N = R.line.combat_nodes[node_id]
		if(!istype(N))
			continue
		var/list/mob_payloads = list()
		for(var/mob_path in N.mob_stock)
			var/list/payload = BuildMobCardPayload(mob_path, mob_path in seen)
			payload["count"] = N.mob_stock[mob_path]
			mob_payloads += list(payload)
		out += list(list(
			"id"          = N.id,
			"name"        = N.name,
			"description" = N.description,
			"is_boss"     = N.is_boss,
			"mobs"        = mob_payloads,
		))
	return out

/obj/structure/refraction_briefing/proc/BuildMobCardPayload(mob_path, revealed)
	var/list/stats = SSrefraction_railway.GetMobStats(mob_path)
	if(!islist(stats))
		return list("path" = "[mob_path]", "revealed" = FALSE, "missing" = TRUE)
	if(revealed)
		var/tip = SSrefraction_railway.mob_tips[mob_path]
		var/list/payload = stats.Copy()
		payload["path"] = "[mob_path]"
		payload["revealed"] = TRUE
		if(tip)
			payload["tip"] = tip
		return payload
	// Unrevealed: silhouette icon + dealt damage type + derived weakness.
	var/list/payload = list(
		"path"               = "[mob_path]",
		"revealed"           = FALSE,
		"icon"               = stats["icon"],
		"melee_damage_type"  = stats["melee_damage_type"],
		"weakness"           = SSrefraction_railway.DerivedDamageWeakness(stats["resistances"]),
	)
	if(stats["is_ranged"])
		payload["ranged_damage_type"] = stats["ranged_damage_type"]
	return payload

// ---------- Advance ("Begin Sector") console ----------

/obj/machinery/computer/refraction_advance
	name = "refraction advance console"
	desc = "Coordinates the team's readiness for the upcoming sector. Lobby \
		owner triggers the actual sector start."
	icon_screen = "explosive"
	icon_keyboard = "rd_key"
	circuit = null
	resistance_flags = INDESTRUCTIBLE

/obj/machinery/computer/refraction_advance/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	ui_interact(user)

/obj/machinery/computer/refraction_advance/ui_interact(mob/user, datum/tgui/ui)
	var/datum/refraction_run/R = SSrefraction_railway.GetRunForCkey(user.ckey)
	if(!R || R.lobby_state != LOBBY_RUNNING || !R.in_checkpoint)
		to_chat(user, span_warning("You aren't currently staging in a refraction lobby."))
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RefractionAdvance", "Begin Sector")
		ui.open()

/obj/machinery/computer/refraction_advance/ui_data(mob/user)
	var/list/data = list()
	var/datum/refraction_run/R = SSrefraction_railway.GetRunForCkey(user.ckey)
	if(!R)
		return data
	var/all_ready = TRUE
	var/list/members_payload = list()
	for(var/mob/M as anything in R.members)
		var/ready = R.ready_states[M.ckey]
		if(M.stat != DEAD && !ready)
			all_ready = FALSE
		members_payload += list(BuildMemberPayload(M, R, ready))
	data["members"] = members_payload
	data["is_lobby_owner"] = R.lobby_owner == user.ckey
	data["my_ckey"] = user.ckey
	data["my_loadout_set"] = (R.loadouts[user.ckey] && length(R.loadouts[user.ckey]) >= 3) ? TRUE : FALSE
	data["current_sector"] = R.current_section
	data["next_sector_index"] = R.current_section + 1
	data["section_count"] = R.line.section_count
	data["next_sector_name"] = GetNextSectorName(R)
	data["all_ready"] = all_ready && length(members_payload) > 0
	data["leaderboard"] = SSrefraction_railway.leaderboards[R.line.id]
	data["line_id"] = R.line.id
	return data

/obj/machinery/computer/refraction_advance/proc/BuildMemberPayload(mob/M, datum/refraction_run/R, ready)
	var/list/loadout = R.loadouts[M.ckey]
	var/list/icons = list(null, null, null)
	if(islist(loadout) && length(loadout) >= 3)
		icons[1] = SStestrange.GenerateEgoPreviewIcon(loadout[1])
		icons[2] = SStestrange.GenerateEgoPreviewIcon(loadout[2])
		icons[3] = SStestrange.GenerateEgoPreviewIcon(loadout[3])
	return list(
		"ckey"          = M.ckey,
		"name"          = M.real_name || M.name,
		"ready"         = ready ? TRUE : FALSE,
		"loadout_icons" = icons,
		"is_owner"      = R.lobby_owner == M.ckey,
		"is_alive"      = M.stat != DEAD,
	)

/obj/machinery/computer/refraction_advance/proc/GetNextSectorName(datum/refraction_run/R)
	var/idx = R.current_section + 1
	if(!islist(R.line.sector_briefings))
		return ""
	if(idx < 1 || idx > length(R.line.sector_briefings))
		return ""
	var/list/sector = R.line.sector_briefings[idx]
	return sector["name"]

/obj/machinery/computer/refraction_advance/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	var/datum/refraction_run/R = SSrefraction_railway.GetRunForCkey(usr.ckey)
	if(!R)
		return
	switch(action)
		if("toggle_ready")
			if(!R.loadouts[usr.ckey])
				to_chat(usr, span_warning("You must confirm a loadout before readying up."))
				return
			R.ready_states[usr.ckey] = !R.ready_states[usr.ckey]
		if("begin_sector")
			R.BeginSector(usr.ckey)
