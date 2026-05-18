/*
 * Refraction Railway hub console.
 *
 * Lives in the railway hub area on a permanent z. Ghosts attack-click it to
 * be funneled into the nearby /obj/effect/mob_spawn/human/refraction_railway_agent
 * (a testrange-style sleeper). Bodies then click it to open the subway-map UI
 * for line selection, lobby creation, and leaderboard browsing.
 *
 * Lobby state lives on /datum/refraction_run; this console is purely a view.
 */

/obj/machinery/computer/refraction_railway_console
	name = "refraction railway terminal"
	desc = "A console for selecting and joining refraction railway lines. \
		Ghosts may click this to materialize a body in a nearby sleeper."
	icon_screen = "explosive"
	icon_keyboard = "rd_key"
	circuit = null
	resistance_flags = INDESTRUCTIBLE

/obj/machinery/computer/refraction_railway_console/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	ui_interact(user)

/obj/machinery/computer/refraction_railway_console/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RefractionRailway", "Refraction Railway")
		// Auto-update so the LOBBY_STARTING -> LOBBY_RUNNING transition (and
		// the loading-state UI feedback) propagates without requiring the
		// user to click anything.
		ui.set_autoupdate(TRUE)
		ui.open()

/obj/machinery/computer/refraction_railway_console/ui_data(mob/user)
	var/list/data = list()
	data["lines"] = BuildLinesPayload(user)
	data["my_run"] = BuildMyRunPayload(user)
	data["open_lobbies"] = BuildOpenLobbiesPayload()
	data["leaderboards"] = BuildLeaderboardsPayload()
	data["compensations"] = BuildCompensationsPayload()
	data["status_glossary"] = RefractionStatusGlossary()
	return data

/// Builds the small per-effect payload shown under the line list, so
/// players can tell at a glance which small-party compensation effects
/// are currently active. Source-of-truth flags live on SSrefraction_railway.
/obj/machinery/computer/refraction_railway_console/proc/BuildCompensationsPayload()
	return list(
		list(
			"name"        = "Stock multiplier",
			"description" = "Per-mob-type reserves scale +20% per extra player. Bosses unaffected.",
			"enabled"     = SSrefraction_railway.scale_stock,
		),
		list(
			"name"        = "Concurrent cap",
			"description" = "Max simultaneously-alive mobs scales +20% per extra player. Bosses unaffected.",
			"enabled"     = SSrefraction_railway.scale_concurrent,
		),
		list(
			"name"        = "Spawn batch",
			"description" = "Mobs per spawn cycle equals the lobby size (1 solo, 4 quad).",
			"enabled"     = SSrefraction_railway.scale_spawn_batch,
		),
		list(
			"name"        = "Wave mob stats",
			"description" = "Non-boss mobs gain +20% HP / +10% damage per extra player.",
			"enabled"     = SSrefraction_railway.scale_wave_stats,
		),
		list(
			"name"        = "Boss HP",
			"description" = "Boss HP × player count (1x solo, 4x quad). Boss damage is always left at authored values.",
			"enabled"     = SSrefraction_railway.scale_boss_stats,
		),
		list(
			"name"        = "Compensation pens",
			"description" = "Smaller parties get mental + salacid medipens at the start of each sector (4/2/1/0 by lobby size).",
			"enabled"     = SSrefraction_railway.give_compensation_pens,
		),
	)

/// Augments each leaderboard entry's per-sector breakdown with rendered
/// loadout icons so the records modal can show what gear each player used
/// per sector. Loadouts are stored as paths (or strings post-JSON-load);
/// here they're converted to base64 icons via SStestrange's cached helper.
/obj/machinery/computer/refraction_railway_console/proc/BuildLeaderboardsPayload()
	var/list/out = list()
	for(var/line_id in SSrefraction_railway.leaderboards)
		var/list/board = SSrefraction_railway.leaderboards[line_id]
		var/list/entries_out = list()
		if(islist(board))
			for(var/list/entry as anything in board)
				entries_out += list(BuildLeaderboardEntryPayload(entry))
		out[line_id] = entries_out
	return out

/obj/machinery/computer/refraction_railway_console/proc/BuildLeaderboardEntryPayload(list/entry)
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
			))
	return list(
		"ckey"     = entry["ckey"],
		"name"     = entry["name"],
		"time_ds"  = entry["time_ds"],
		"members"  = entry["members"],
		"sectors"  = sectors_out,
	)

/obj/machinery/computer/refraction_railway_console/proc/LoadoutIconsForPaths(list/paths)
	var/list/icons = list(null, null, null)
	if(!islist(paths))
		return icons
	for(var/i in 1 to min(3, length(paths)))
		var/p = paths[i]
		// Post-JSON entries arrive as strings; fresh in-memory entries are
		// real paths. GenerateEgoPreviewIcon needs a path either way.
		if(istext(p))
			p = text2path(p)
		if(!ispath(p))
			continue
		icons[i] = SStestrange.GenerateEgoPreviewIcon(p)
	return icons

/obj/machinery/computer/refraction_railway_console/proc/BuildLinesPayload(mob/user)
	var/list/out = list()
	var/ckey = user?.ckey
	for(var/id in SSrefraction_railway.lines)
		var/datum/refraction_line/L = SSrefraction_railway.lines[id]
		out += list(list(
			"id"           = L.id,
			"name"         = L.name,
			"description"  = L.description,
			"display_color" = L.display_color,
			"map_viewbox"  = L.map_viewbox,
			"nodes"        = L.nodes,
			"edges"        = L.edges,
			"combat_nodes" = BuildLineCombatNodesPayload(L, ckey),
			"recommended_tier_lines"  = L.recommended_tier_lines,
			"recommended_tier_offset" = L.recommended_tier_offset,
			"attribute_set_value"     = L.attribute_set_value,
			"max_lobby_size"          = L.max_lobby_size,
			"section_count"           = L.section_count,
		))
	return out

/// Returns one entry per /datum/refraction_node on the line, each with its
/// mob cards (revealed/unrevealed per `ckey`). Used by the subway-map node
/// click flow on the hub UI.
/obj/machinery/computer/refraction_railway_console/proc/BuildLineCombatNodesPayload(datum/refraction_line/L, ckey)
	var/list/out = list()
	if(!islist(L?.combat_nodes))
		return out
	for(var/node_id in L.combat_nodes)
		var/datum/refraction_node/N = L.combat_nodes[node_id]
		if(!istype(N))
			continue
		var/list/mob_payloads = list()
		for(var/mob_path in N.mob_stock)
			var/list/payload = SSrefraction_railway.BuildMobCardPayload(ckey, mob_path)
			payload["count"] = N.mob_stock[mob_path]
			mob_payloads += list(payload)
		for(var/mob_path in N.extra_preview_mobs)
			if(mob_path in N.mob_stock)
				continue
			var/list/payload = SSrefraction_railway.BuildMobCardPayload(ckey, mob_path)
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

/obj/machinery/computer/refraction_railway_console/proc/BuildMyRunPayload(mob/user)
	if(!user?.ckey)
		return null
	var/datum/refraction_run/R = SSrefraction_railway.GetRunForCkey(user.ckey)
	if(!R)
		return null
	var/list/member_ckeys = list()
	for(var/mob/M as anything in R.members)
		if(M.ckey)
			member_ckeys += M.ckey
	return list(
		"run_uid"       = R.run_uid,
		"line_id"       = R.line.id,
		"lobby_state"   = R.lobby_state,
		"lobby_owner"   = R.lobby_owner,
		"member_ckeys"  = member_ckeys,
		"is_owner"      = R.lobby_owner == user.ckey,
	)

/obj/machinery/computer/refraction_railway_console/proc/BuildOpenLobbiesPayload()
	var/list/out = list()
	for(var/datum/refraction_run/R as anything in SSrefraction_railway.active_runs)
		if(R.lobby_state != LOBBY_OPEN)
			continue
		var/list/member_ckeys = list()
		for(var/mob/M as anything in R.members)
			if(M.ckey)
				member_ckeys += M.ckey
		out += list(list(
			"run_uid"      = R.run_uid,
			"line_id"      = R.line.id,
			"owner_ckey"   = R.lobby_owner,
			"member_ckeys" = member_ckeys,
			"member_count" = length(member_ckeys),
			"max_lobby_size" = R.line.max_lobby_size,
		))
	return out

/obj/machinery/computer/refraction_railway_console/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	switch(action)
		if("create_lobby")
			return ActCreateLobby(usr, params["line_id"])
		if("join_lobby")
			return ActJoinLobby(usr, params["run_uid"])
		if("leave_lobby")
			return ActLeaveLobby(usr)
		if("kick_member")
			return ActKickMember(usr, params["ckey"])
		if("start_run")
			return ActStartRun(usr)

/obj/machinery/computer/refraction_railway_console/proc/ActCreateLobby(mob/user, line_id)
	if(!ishuman(user) || !user.ckey || !line_id)
		return FALSE
	if(SSrefraction_railway.GetRunForCkey(user.ckey))
		to_chat(user, span_warning("You're already in a lobby."))
		return FALSE
	var/datum/refraction_line/L = SSrefraction_railway.lines[line_id]
	if(!istype(L))
		return FALSE
	var/datum/refraction_run/R = new(L, user.ckey)
	R.AddMember(user)
	return TRUE

/obj/machinery/computer/refraction_railway_console/proc/ActJoinLobby(mob/user, run_uid)
	if(!ishuman(user) || !user.ckey)
		return FALSE
	var/uid = text2num(run_uid)
	if(!uid)
		return FALSE
	if(SSrefraction_railway.GetRunForCkey(user.ckey))
		to_chat(user, span_warning("You're already in a lobby."))
		return FALSE
	var/datum/refraction_run/R = SSrefraction_railway.GetRunByUid(uid)
	if(!R || R.lobby_state != LOBBY_OPEN)
		return FALSE
	return R.AddMember(user)

/obj/machinery/computer/refraction_railway_console/proc/ActLeaveLobby(mob/user)
	if(!user?.ckey)
		return FALSE
	var/datum/refraction_run/R = SSrefraction_railway.GetRunForCkey(user.ckey)
	if(!R || R.lobby_state != LOBBY_OPEN)
		return FALSE
	return R.RemoveMember(user)

/obj/machinery/computer/refraction_railway_console/proc/ActKickMember(mob/user, target_ckey)
	if(!user?.ckey || !target_ckey)
		return FALSE
	var/datum/refraction_run/R = SSrefraction_railway.GetRunForCkey(user.ckey)
	if(!R || R.lobby_owner != user.ckey)
		return FALSE
	if(target_ckey == user.ckey)
		return FALSE
	var/mob/target = R.FindMemberByCkey(target_ckey)
	if(!target)
		return FALSE
	return R.RemoveMember(target)

/obj/machinery/computer/refraction_railway_console/proc/ActStartRun(mob/user)
	if(!user?.ckey)
		return FALSE
	var/datum/refraction_run/R = SSrefraction_railway.GetRunForCkey(user.ckey)
	if(!R || R.lobby_owner != user.ckey)
		return FALSE
	return R.StartRun()

// ---------- Ghost-spawn sleeper ----------

/obj/effect/mob_spawn/human/refraction_railway_agent
	uses = -1
	death = FALSE
	roundstart = FALSE
	random = FALSE
	permanent = TRUE
	name = "refraction railway sleeper"
	desc = "A humming sleeper that materializes registered fixers for refraction railway runs."
	mob_name = "Refraction Railway Agent"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	resistance_flags = INDESTRUCTIBLE
	outfit = /datum/outfit/refraction_railway_agent
	short_desc = "Bodies spawned here run the refraction railway."
	assignedrole = "Refraction Railway Agent"

/datum/outfit/refraction_railway_agent
	head = null
	belt = null
	ears = null
	glasses = /obj/item/clothing/glasses/sunglasses
	uniform = /obj/item/clothing/under/suit/lobotomy
	suit = null
	shoes = /obj/item/clothing/shoes/laceup
	gloves = /obj/item/clothing/gloves/color/black
	implants = list(/obj/item/organ/cyberimp/eyes/hud/security)
	back = /obj/item/storage/backpack
