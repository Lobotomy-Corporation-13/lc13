/*
 * Checkpoint-room consoles: wall-mounted briefing display and the
 * "Begin Sector" advance console. Read run state from /datum/refraction_run.
 */

// Briefing display

/obj/structure/refraction_briefing
	name = "refraction sector briefing"
	desc = "A wall-mounted display showing the upcoming sector's hostile composition."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "departmentdrone"
	density = TRUE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE
	/// Mappers flip this on to swap the briefing to its framed look —
	/// "departmentdrone_base" sprite + two color-tintable frame overlays.
	var/custom_frame = FALSE
	/// Color tints applied to the inner and outer frame overlays when
	/// custom_frame is enabled. Hex strings ("#ffffff" leaves the sprite
	/// at its authored color).
	var/inner_frame_color = "#ffffff"
	var/outer_frame_color = "#ffffff"

/obj/structure/refraction_briefing/Initialize(mapload)
	. = ..()
	if(custom_frame)
		icon_state = "departmentdrone_base"
		var/mutable_appearance/inner = mutable_appearance(icon, "departmentdrone_inner_frame")
		inner.color = inner_frame_color
		add_overlay(inner)
		var/mutable_appearance/outer = mutable_appearance(icon, "departmentdrone_outer_frame")
		outer.color = outer_frame_color
		add_overlay(outer)

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
		"name"        = sector["name"],
		"description" = sector["description"],
	)
	data["sector_index"] = idx
	data["nodes"] = BuildNodesPayload(user, sector, R)
	data["status_glossary"] = RefractionStatusGlossary()
	return data

/obj/structure/refraction_briefing/proc/BuildNodesPayload(mob/user, list/sector, datum/refraction_run/R)
	var/list/out = list()
	if(!islist(sector["node_ids"]))
		return out
	for(var/node_id in sector["node_ids"])
		var/datum/refraction_node/N = R.line.combat_nodes[node_id]
		if(!istype(N))
			continue
		var/list/mob_payloads = list()
		for(var/mob_path in N.mob_stock)
			var/list/payload = SSrefraction_railway.BuildMobCardPayload(user.ckey, mob_path)
			payload["count"] = N.mob_stock[mob_path]
			mob_payloads += list(payload)
		for(var/mob_path in N.extra_preview_mobs)
			if(mob_path in N.mob_stock)
				continue
			var/list/payload = SSrefraction_railway.BuildMobCardPayload(user.ckey, mob_path)
			payload["count"] = null
			mob_payloads += list(payload)
		out += list(list(
			"id"          = N.id,
			"name"        = N.name,
			"description" = N.description,
			"is_boss"     = N.is_boss,
			"mobs"        = mob_payloads,
		))
	return out

// Advance ("Begin Sector") console

/obj/machinery/computer/refraction_advance
	name = "refraction advance console"
	desc = "Coordinates the team's readiness for the upcoming sector. Lobby \
		owner triggers the actual sector start."
	icon_screen = "teleport"
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
	// Warn only with no run; wrong-state bails silently (TGUI re-invokes
	// ui_interact during state transitions).
	if(!R)
		to_chat(user, span_warning("You aren't currently part of a refraction run."))
		return
	if(R.lobby_state != LOBBY_RUNNING && R.lobby_state != LOBBY_FINISHED)
		return
	if(R.lobby_state == LOBBY_RUNNING && !R.in_checkpoint)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RefractionAdvance", "Begin Sector")
		// Autoupdate so state transitions propagate without a click.
		ui.set_autoupdate(TRUE)
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
	data["is_owner_active"] = R.IsOwnerActive()
	data["my_ckey"] = user.ckey
	data["my_loadout_set"] = (R.loadouts[user.ckey] && length(R.loadouts[user.ckey]) >= 3) ? TRUE : FALSE
	data["current_sector"] = R.current_section
	data["next_sector_index"] = R.current_section + 1
	data["section_count"] = R.line.section_count
	data["next_sector_name"] = GetNextSectorName(R)
	data["all_ready"] = all_ready && length(members_payload) > 0
	data["leaderboard"] = SSrefraction_railway.leaderboards[R.line.id]
	data["line_id"] = R.line.id
	// Last completed sector's elapsed time in deciseconds, 0 if none.
	data["last_sector_time_ds"] = GetLastSectorTimeDs(R)
	data["lobby_state"] = R.lobby_state
	if(R.lobby_state == LOBBY_FINISHED)
		data["results"] = BuildResultsPayload(R)
	return data

/obj/machinery/computer/refraction_advance/proc/GetLastSectorTimeDs(datum/refraction_run/R)
	var/list/finishes = R.sector_finish_times
	if(!islist(finishes) || !length(finishes))
		return 0
	var/end_t = finishes[length(finishes)]
	var/start_t = (length(finishes) >= 2) ? finishes[length(finishes) - 1] : 0
	return max(0, end_t - start_t)

/obj/machinery/computer/refraction_advance/proc/BuildResultsPayload(datum/refraction_run/R)
	var/list/sectors = list()
	var/list/finishes = R.sector_finish_times
	for(var/i in 1 to length(finishes))
		var/end_t = finishes[i]
		var/start_t = (i > 1) ? finishes[i - 1] : 0
		var/list/per_player = list()
		if(islist(R.sector_loadouts) && i <= length(R.sector_loadouts))
			var/list/snap = R.sector_loadouts[i]
			if(islist(snap))
				for(var/list/entry as anything in snap)
					var/list/loadout = entry["loadout"]
					var/list/icons = list(null, null, null)
					if(islist(loadout))
						for(var/j in 1 to min(3, length(loadout)))
							icons[j] = SStestrange.GenerateEgoPreviewIcon(loadout[j])
					per_player += list(list(
						"ckey"          = entry["ckey"],
						"name"          = entry["name"],
						"loadout_icons" = icons,
					))
		var/list/sector_briefing = (islist(R.line.sector_briefings) && i <= length(R.line.sector_briefings)) ? R.line.sector_briefings[i] : null
		sectors += list(list(
			"index"   = i,
			"name"    = sector_briefing ? sector_briefing["name"] : "Sector [i]",
			"time_ds" = end_t - start_t,
			"players" = per_player,
		))
	return list(
		"line_name" = R.line.name,
		"total_ds"  = R.ElapsedDeciseconds(),
		"sectors"   = sectors,
	)

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
			if(R.BeginSector(usr.ckey))
				SStgui.close_uis(src)
		if("force_begin_sector")
			// Owner-only AFK escape hatch; BeginSector enforces owner.
			if(R.BeginSector(usr.ckey, TRUE))
				SStgui.close_uis(src)
		if("return_to_lobby")
			if(R.lobby_state == LOBBY_FINISHED)
				R.ReturnToLobby()
		if("abandon_run")
			// Owner-only; two-click confirm is enforced UI-side.
			R.AbandonRun(usr.ckey)
