/*
 * Refraction Railway loadout console. Catalog comes from the run datum's
 * pre-filtered usable_ego_weapons / usable_ego_armor.
 */

/obj/machinery/computer/refraction_loadout
	name = "refraction loadout console"
	desc = "Selects the E.G.O. loadout for the upcoming sector. Only items \
		you can equip at the line's attribute level appear here."
	icon_screen = "request"
	icon_keyboard = "power_key"
	circuit = null
	resistance_flags = INDESTRUCTIBLE

/obj/machinery/computer/refraction_loadout/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	ui_interact(user)

/obj/machinery/computer/refraction_loadout/ui_interact(mob/user, datum/tgui/ui)
	if(!CheckInitializedDatums(user))
		return
	var/datum/refraction_run/R = SSrefraction_railway.GetRunForCkey(user.ckey)
	// Warn only with no run; wrong-state bails silently (TGUI re-invokes
	// ui_interact during state transitions).
	if(!R)
		to_chat(user, span_warning("You aren't currently part of a refraction run."))
		return
	if(R.lobby_state != LOBBY_RUNNING || !R.in_checkpoint)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RefractionLoadout", "Refraction Loadout")
		ui.set_autoupdate(FALSE)
		ui.open()

/// Gates UI on SStestrange ego_datums being initialized.
/obj/machinery/computer/refraction_loadout/proc/CheckInitializedDatums(mob/living/user)
	if(SStestrange.ego_datums_initializing || !SStestrange.ego_datums_initialized)
		var/loaded = SStestrange.ego_datums ? length(SStestrange.ego_datums) : 0
		var/msg = "System is still initializing. Please wait. [loaded] E.G.O. currently loaded."
		if(istype(user) && user.stat < DEAD)
			say(msg)
			playsound(get_turf(src), 'sound/machines/synth_no.ogg', 40, TRUE)
		else
			to_chat(user, span_warning(msg))
		return FALSE
	return TRUE

/obj/machinery/computer/refraction_loadout/ui_static_data(mob/user)
	var/list/data = list()
	data["weapons"] = list()
	data["armor"] = list()
	data["all_tags"] = list()
	for(var/tag in EGO_TAGS_DESCRIPTION_LIST)
		data["all_tags"] += list(list(
			"tag_name" = tag,
			"tag_description" = EGO_TAGS_DESCRIPTION_LIST[tag],
			"tag_checked" = FALSE,
		))
	var/datum/refraction_run/R = SSrefraction_railway.GetRunForCkey(user.ckey)
	if(!R)
		return data
	for(var/wpath in R.usable_ego_weapons)
		var/list/entry = BuildEgoEntry(wpath, user.ckey, R)
		if(entry)
			data["weapons"] += list(entry)
	for(var/apath in R.usable_ego_armor)
		var/list/entry = BuildEgoEntry(apath, user.ckey, R)
		if(entry)
			data["armor"] += list(entry)
	return data

/// Looks up the cached /datum/ego_datum by path and emits the TGUI payload.
/// `blocked` is TRUE iff the run's unique-loadout-per-sector rule is on and
/// the player has already used this item in a prior sector.
/obj/machinery/computer/refraction_loadout/proc/BuildEgoEntry(item_path, ckey, datum/refraction_run/R)
	var/datum/ego_datum/ED = SStestrange.ego_datums_by_path[item_path]
	if(!ED)
		return null
	return list(
		"path"        = ED.item_path,
		"cost"        = ED.cost,
		"information" = ED.information,
		"tags"        = ED.ego_tags,
		"icon"        = SStestrange.GenerateEgoPreviewIcon(ED.item_path),
		"threatclass" = ED.CostToThreatClass(),
		"origin"      = ED.origin,
		"blocked"     = R ? R.IsItemPathBlocked(ckey, ED.item_path) : FALSE,
		"used_before" = R ? R.HasUsedItemPath(ckey, ED.item_path) : FALSE,
	)

/obj/machinery/computer/refraction_loadout/ui_data(mob/user)
	var/list/data = list()
	var/datum/refraction_run/R = SSrefraction_railway.GetRunForCkey(user.ckey)
	if(!R)
		return data
	data["current_loadout"] = R.loadouts[user.ckey] || list()
	data["briefing_header"] = BuildBriefingHeader(R)
	data["sector_index"] = R.current_section + 1
	return data

/obj/machinery/computer/refraction_loadout/proc/BuildBriefingHeader(datum/refraction_run/R)
	if(!islist(R.line.sector_briefings))
		return list()
	var/idx = R.current_section + 1
	if(idx < 1 || idx > length(R.line.sector_briefings))
		return list()
	var/list/sector = R.line.sector_briefings[idx]
	return list(
		"name" = sector["name"],
	)

/obj/machinery/computer/refraction_loadout/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	if(action != "confirm_loadout")
		return
	var/datum/refraction_run/R = SSrefraction_railway.GetRunForCkey(usr.ckey)
	if(!R)
		return
	var/list/weapons_in = params["weapons"]
	var/armor_in = params["armor"]
	if(!islist(weapons_in) || length(weapons_in) != 2 || !armor_in)
		return
	var/w1 = text2path(weapons_in[1])
	var/w2 = text2path(weapons_in[2])
	var/armor_path = text2path(armor_in)
	if(!w1 || !w2 || !armor_path)
		return
	R.ApplyLoadout(usr.ckey, list(w1, w2), armor_path)
