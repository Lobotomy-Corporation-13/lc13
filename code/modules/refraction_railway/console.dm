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
	/// Range used by attack_ghost to find a body-spawner.
	var/spawner_search_range = 7

/obj/machinery/computer/refraction_railway_console/attack_ghost(mob/user)
	. = ..()
	var/obj/effect/mob_spawn/human/refraction_railway_agent/closest
	for(var/obj/effect/mob_spawn/human/refraction_railway_agent/S in range(spawner_search_range, src))
		closest = S
		break
	if(!closest)
		to_chat(user, span_warning("No refraction railway sleeper is registered nearby. Notify a coder."))
		return
	closest.attack_ghost(user)

/obj/machinery/computer/refraction_railway_console/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	ui_interact(user)

/obj/machinery/computer/refraction_railway_console/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RefractionRailway", "Refraction Railway")
		ui.open()

/obj/machinery/computer/refraction_railway_console/ui_data(mob/user)
	var/list/data = list()
	data["lines"] = BuildLinesPayload()
	data["my_run"] = BuildMyRunPayload(user)
	data["open_lobbies"] = BuildOpenLobbiesPayload()
	data["leaderboards"] = SSrefraction_railway.leaderboards
	return data

/obj/machinery/computer/refraction_railway_console/proc/BuildLinesPayload()
	var/list/out = list()
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
			"recommended_tier_lines"  = L.recommended_tier_lines,
			"recommended_tier_offset" = L.recommended_tier_offset,
			"attribute_set_value"     = L.attribute_set_value,
			"max_lobby_size"          = L.max_lobby_size,
			"section_count"           = L.section_count,
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
