/*
 * Refraction Railway hub console. Ghosts click to spawn a body in a nearby
 * sleeper; bodies open the subway-map UI for lines, lobbies, leaderboards.
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
		// Autoupdate so lobby state transitions propagate without a click.
		ui.set_autoupdate(TRUE)
		ui.open()

/obj/machinery/computer/refraction_railway_console/ui_data(mob/user)
	var/list/data = list()
	data["lines"] = BuildLinesPayload(user)
	data["my_run"] = BuildMyRunPayload(user)
	data["open_lobbies"] = BuildOpenLobbiesPayload()
	data["leaderboards"] = SSrefraction_railway.BuildLeaderboardsPayload()
	data["compensations"] = BuildCompensationsPayload()
	data["status_glossary"] = RefractionStatusGlossary()
	return data

/// Per-(line × flag) payload of small-party compensation flags. Each row
/// shows the *effective* state for that line — `SS.flag && line.flag` — so
/// per-line author overrides are visible alongside the global SS toggles.
/obj/machinery/computer/refraction_railway_console/proc/BuildCompensationsPayload()
	var/static/list/flag_specs = list(
		list("name" = "Stock multiplier",  "description" = "Per-mob-type reserves scale +20% per extra player. Bosses unaffected.",                                            "var" = "scale_stock"),
		list("name" = "Concurrent cap",    "description" = "Max simultaneously-alive mobs scales +20% per extra player. Bosses unaffected.",                                  "var" = "scale_concurrent"),
		list("name" = "Spawn batch",       "description" = "Mobs per spawn cycle equals the lobby size (1 solo, 4 quad).",                                                    "var" = "scale_spawn_batch"),
		list("name" = "Wave mob stats",    "description" = "Non-boss mobs gain +20% HP / +10% damage per extra player.",                                                      "var" = "scale_wave_stats"),
		list("name" = "Boss HP",           "description" = "Boss HP × player count (1x solo, 4x quad). Boss damage is always left at authored values.",                       "var" = "scale_boss_stats"),
		list("name" = "Compensation pens", "description" = "Smaller parties get mental + salacid medipens at the start of each sector (4/2/1/0 by lobby size).",              "var" = "give_compensation_pens"),
		list("name" = "Unique loadout per sector", "description" = "Players can't re-use the same EGO weapons or armor across sectors of the same run. Used items still appear in the loadout UI, crossed out and unselectable.", "var" = "unique_loadout_per_sector"),
	)
	var/list/out = list()
	for(var/line_id in SSrefraction_railway.lines)
		var/datum/refraction_line/L = SSrefraction_railway.lines[line_id]
		if(!istype(L))
			continue
		for(var/list/flag as anything in flag_specs)
			var/ss_on = SSrefraction_railway.vars[flag["var"]]
			var/line_on = L.vars[flag["var"]]
			out += list(list(
				"line_id"     = L.id,
				"name"        = "[L.name] — [flag["name"]]",
				"description" = flag["description"],
				"enabled"     = ss_on && line_on,
			))
	return out

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
			"locked"                  = L.locked,
		))
	return out

/// One entry per combat node with its mob cards (revealed per ckey).
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
		if(N.locked)
			// Locked nodes are still listed (so the SVG map's per-circle
			// indices stay aligned with the line's visual node list), but
			// they ship as a Restricted stub — no desc, no mob cards.
			out += list(list(
				"id"          = N.id,
				"name"        = "Restricted",
				"description" = "Encounter not yet authored.",
				"is_boss"     = N.is_boss,
				"mobs"        = list(),
				"locked"      = TRUE,
			))
			continue
		out += list(list(
			"id"           = N.id,
			"name"         = N.name,
			"description"  = N.description,
			"is_boss"      = N.is_boss,
			"mobs"         = mob_payloads,
			"locked"       = FALSE,
			"achievements" = BuildNodeAchievementsPayload(N, L.id, ckey),
		))
	return out

/// One assoc-list per achievement bound to any of this node's stocked
/// mob paths. Returns empty list if the ckey hasn't completed the line
/// yet — achievements stay hidden until a veteran clear unlocks them.
/obj/machinery/computer/refraction_railway_console/proc/BuildNodeAchievementsPayload(datum/refraction_node/N, line_id, ckey)
	var/list/out = list()
	if(!N || !line_id || !ckey)
		return out
	if(!SSrefraction_railway.HasCompletedLine(ckey, line_id))
		return out
	var/list/seen = list()
	for(var/mob_path in N.mob_stock)
		var/list/achs = SSrefraction_railway.mob_achievements[mob_path]
		if(!islist(achs))
			continue
		for(var/list/ach as anything in achs)
			if(!islist(ach))
				continue
			var/aid = ach["id"]
			if(!aid || seen[aid])
				continue
			seen[aid] = TRUE
			out += list(list(
				"id"     = aid,
				"name"   = ach["name"],
				"desc"   = ach["desc"],
				"reward" = ach["reward"],
				"kind"   = ach["default_state"] ? "avoid" : "earn",
			))
	return out

/obj/machinery/computer/refraction_railway_console/proc/BuildMyRunPayload(mob/user)
	if(!user?.ckey)
		return null
	var/datum/refraction_run/R = SSrefraction_railway.GetRunForCkey(user.ckey)
	if(!R)
		return null
	// Members carry both their ckey (owner check + kick action key) and the
	// display name shown in the UI — the player's mob name, not their ckey.
	var/list/members = list()
	for(var/mob/M as anything in R.members)
		if(!M.ckey)
			continue
		members += list(list(
			"ckey" = M.ckey,
			"name" = M.real_name || M.name,
		))
	return list(
		"run_uid"       = R.run_uid,
		"line_id"       = R.line.id,
		"lobby_state"   = R.lobby_state,
		"lobby_owner"   = R.lobby_owner,
		"members"       = members,
		"is_owner"      = R.lobby_owner == user.ckey,
	)

/obj/machinery/computer/refraction_railway_console/proc/BuildOpenLobbiesPayload()
	var/list/out = list()
	for(var/datum/refraction_run/R as anything in SSrefraction_railway.active_runs)
		if(R.lobby_state != LOBBY_OPEN)
			continue
		// Show the owner's mob name in the open-lobby list rather than ckey.
		var/member_count = 0
		var/owner_name = R.lobby_owner
		for(var/mob/M as anything in R.members)
			if(!M.ckey)
				continue
			member_count++
			if(M.ckey == R.lobby_owner)
				owner_name = M.real_name || M.name
		out += list(list(
			"run_uid"      = R.run_uid,
			"line_id"      = R.line.id,
			"owner_ckey"   = R.lobby_owner,
			"owner_name"   = owner_name,
			"member_count" = member_count,
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
	if(L.locked)
		to_chat(user, span_warning("[L.name] is under construction. No lobbies for it yet."))
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

// Read-only records terminal: a separate machine that only shows
// leaderboards, so checkpoint rooms / lobby halls can host a "scoreboard"
// without the full hub UI. Inherits everything but overrides the icon (no
// keyboard/screen overlays) and the UI surface (different TGUI interface,
// no lobby actions). All leaderboard payload work lives on the subsystem.
/obj/machinery/computer/refraction_railway_console/leaderboard
	name = "refraction railway records terminal"
	desc = "A terminal that displays the fastest recorded clears for each \
		refraction railway line."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "drone_maker"

// The base /obj/machinery/computer/update_overlays() adds keyboard/screen
// overlays sourced from icons/obj/computer.dmi, which would be invisible (and
// nonsensical) on top of the drone_maker sprite. It also side-effects via
// SSvis_overlays.add_vis_overlay, so we must skip the parent call entirely
// rather than just discarding its return.
/obj/machinery/computer/refraction_railway_console/leaderboard/update_overlays()
	SHOULD_CALL_PARENT(FALSE)
	return list()

/obj/machinery/computer/refraction_railway_console/leaderboard/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RefractionLeaderboard", "Refraction Railway Records")
		ui.set_autoupdate(TRUE)
		ui.open()

/obj/machinery/computer/refraction_railway_console/leaderboard/ui_data(mob/user)
	var/list/lines_out = list()
	for(var/id in SSrefraction_railway.lines)
		var/datum/refraction_line/L = SSrefraction_railway.lines[id]
		lines_out += list(list(
			"id"            = L.id,
			"name"          = L.name,
			"description"   = L.description,
			"display_color" = L.display_color,
		))
	return list(
		"lines"               = lines_out,
		"leaderboards"        = SSrefraction_railway.BuildLeaderboardsPayload(),
		"leaderboard_cutoff"  = REFRACTION_LEADERBOARD_CUTOFF_TEXT,
	)

// Read-only: no lobby / kick / start actions. We deliberately do NOT call
// parent — the inherited switch handles create_lobby / join_lobby / kick /
// start_run, and a client crafting one of those payloads against this
// terminal must not be able to mutate run state through it.
/obj/machinery/computer/refraction_railway_console/leaderboard/ui_act(action, list/params)
	SHOULD_CALL_PARENT(FALSE)
	return

// Ghost-spawn sleeper

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
	flavour_text = "\[Refraction Railway\] An authored boss-rush. Pick a line, party up, re-run as often as you want.\n\
		\n\
		\[Runs\] Each line is a chain of sectors. Pick a loadout (2 weapons + 1 armor) at the loadout console before each sector; the owner starts when ready. Incapacitated players revive at the last checkpoint.\n\
		\n\
		\[Rewards\] Clearing pays Starlight — meta-currency for permanent quirk unlocks at the Starlight terminal. The award itemises: flat clear bonus, signed time bonus vs. expected, +10 per distinct weapon/armor used, plus any achievements earned.\n\
		\n\
		\[Achievements\] Per-encounter challenges. Earnable only after your first clear of the line.\n\
		\n\
		\[Hub map\] Mobs in each node start hidden. Walking into a node reveals its mobs to you permanently."
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

// After the parent's create() builds a vanilla human and transfers the
// ghost's client onto it, copy the ghost's character preferences across so
// the body looks (and is named) like their saved character instead of a
// random Refraction Railway Agent. set_species() inside copy_to() can
// reset bodyparts, so re-equip the outfit afterwards.
/obj/effect/mob_spawn/human/refraction_railway_agent/create(ckey, newname)
	var/mob/M = ..()
	if(!ishuman(M))
		return M
	var/mob/living/carbon/human/H = M
	if(!H.client?.prefs)
		return H
	H.client.prefs.copy_to(H, roundstart_checks = FALSE)
	if(H.dna)
		H.dna.update_dna_identity()
	H.updateappearance(mutcolor_update = 1, mutations_overlay_update = 1)
	if(outfit)
		if(ispath(outfit))
			outfit = new outfit()
		H.equipOutfit(outfit)
	if(H.mind)
		H.mind.name = H.real_name
	// `copy_to(..., roundstart_checks = FALSE)` attaches the player's
	// quirks but suppresses each quirk's on_spawn() — the hook that
	// item-granting starlight quirks (Tagalong Rat, Scarlet Bouquet,
	// Sparkle Mine Launcher, Mutated Form) use to issue their item.
	// Re-fire on_spawn here so those items actually appear in the
	// player's slots.
	for(var/datum/quirk/Q as anything in H.roundstart_quirks)
		Q.on_spawn()
	return H
