#define CITY_FACTION_MENU_MAX_TOGGLES 20

/client/proc/ManageCityFactions()
	set category = "Admin.Game"
	set name = "Manage City Factions"
	if(!check_rights(R_ADMIN))
		return
	if(!SScity_factions.all_factions.len)
		to_chat(src, span_warning("City factions only exist on city maps."))
		return
	for(var/i in 1 to CITY_FACTION_MENU_MAX_TOGGLES)
		var/list/choices = list()
		//This builds the list of faction, in the order of categories to make it more easy to read. With majors being at the top, and minors below them.
		for(var/category in list(CITY_FACTION_ALWAYS, CITY_FACTION_MAJOR, CITY_FACTION_MINOR, CITY_FACTION_SINGLET, CITY_FACTION_CLINIC))
			for(var/datum/city_faction/faction in SScity_factions.all_factions)
				if(faction.category != category)
					continue
				var/state = (faction in SScity_factions.active_factions) ? "ON" : "OFF"
				//Makes a string that shows info about the faction, and connects it to the faction datum for later use.
				choices["\[[state]\] [faction.name] ([category], [faction.Headcount()] playing)"] = faction
		var/picked = tgui_input_list(src, "Pick a faction to turn on or off. Players already in a faction keep their jobs.", "Manage City Factions", choices)
		if(!picked || !check_rights(R_ADMIN))
			return
		if(SSticker.current_state == GAME_STATE_SETTING_UP)
			to_chat(src, span_warning("Roles are being assigned right now. Try again in a moment."))
			return
		var/datum/city_faction/faction = choices[picked]
		if(faction in SScity_factions.active_factions)
			DisableCityFaction(faction)
		else
			EnableCityFaction(faction)

// Just got to warn admins before nuking a poor faction with players.
/client/proc/DisableCityFaction(datum/city_faction/faction)
	if(!ConfirmCityFactionDisable(faction))
		return
	//Don't worry, the config is checked within AskCityFactionReason.
	var/reason = AskCityFactionReason("disabling [faction.name]")
	if(isnull(reason) || !SScity_factions.DisableFaction(faction))
		return
	ReportCityFactionChange("disabled the city faction [faction.name].", reason)

//Moving it here to make it more simple to read.
/client/proc/ConfirmCityFactionDisable(datum/city_faction/faction)
	var/headcount = faction.Headcount()
	if(!headcount)
		return TRUE
	return tgui_alert(src, "[headcount] players are in [faction.name]. They keep their jobs, but nobody new can join. Disable it?", "Disable Faction", list("Yes", "No")) == "Yes"

/client/proc/EnableCityFaction(datum/city_faction/faction)
	//Check the config, and if the faction limit is not reached, just enable the faction after asking.
	//Checking the config early here, just to make sure we don't go through this whole process if we don't have to.
	if(CONFIG_GET(flag/no_city_faction_oversight) || !SScity_factions.faction_limit || !SScity_factions.CategoryFull(faction.category))
		var/reason = AskCityFactionReason("enabling [faction.name]")
		if(isnull(reason) || !SScity_factions.EnableFaction(faction))
			return
		ReportCityFactionChange("enabled the city faction [faction.name].", reason)
		return

	//Make a list of what factions we can swap out with the faction we are trying to enable. Then we ask the admin to pick one.
	var/list/swap_choices = list()
	for(var/datum/city_faction/active in SScity_factions.active_factions)
		if(active.category == faction.category)
			swap_choices["[active.name] ([active.Headcount()] playing)"] = active
	var/picked = tgui_input_list(src, "The faction limit allows no more [faction.category] factions. Pick one to disable in place of [faction.name].", "Swap Faction", swap_choices)
	if(!picked || !check_rights(R_ADMIN))
		return

	//We doulbe check with the admin if we want to disable a faction with players, if the admin backs out from here, we stop right here via return.
	var/datum/city_faction/swap_out = swap_choices[picked]
	if(!ConfirmCityFactionDisable(swap_out))
		return

	//We ask the admin for why they are swapping, and then we swap the factions.
	var/reason = AskCityFactionReason("swapping [swap_out.name] for [faction.name]")
	if(isnull(reason))
		return

	//Small check to make sure we don't mess something up if another admin swaps out factions while we are picking.
	if(!(swap_out in SScity_factions.active_factions) || (faction in SScity_factions.active_factions))
		to_chat(src, span_warning("Another admin changed these factions while you were choosing."))
		return
	SScity_factions.DisableFaction(swap_out)
	SScity_factions.EnableFaction(faction)
	ReportCityFactionChange("swapped the city faction [swap_out.name] for [faction.name].", reason)

// Sending the message to admin TGS, copied from code\modules\client\client_procs.dm, when people log out.
//Along with sending messages to admin log, admin chat, and recording feedback for blackbox. Got to keep people informed
/client/proc/ReportCityFactionChange(message, reason)
	var/reason_text = reason ? " Reason: [reason]" : ""
	log_admin("[key_name(src)] [message][reason_text]")
	message_admins("[key_name_admin(src)] [message][html_encode(reason_text)]")
	if(!CONFIG_GET(flag/no_city_faction_oversight))
		send2adminchat("CITY FACTIONS", "[key_name(src)] [message][reason_text]")
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Manage City Factions")

/client/proc/AskCityFactionReason(action)
	if(CONFIG_GET(flag/no_city_faction_oversight))
		return check_rights(R_ADMIN) ? "" : null
	var/reason = input(src, "Why are you [action]? This is sent to the admin chat.", "Manage City Factions") as text|null
	// Got to clean up the reason by removing spaces on both ends.
	reason = trim(reason)
	if(!reason || !check_rights(R_ADMIN))
		return null
	return reason

#undef CITY_FACTION_MENU_MAX_TOGGLES
