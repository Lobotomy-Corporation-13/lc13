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
		for(var/category in list(CITY_FACTION_ALWAYS, CITY_FACTION_MAJOR, CITY_FACTION_MINOR, CITY_FACTION_SINGLET, CITY_FACTION_CLINIC))
			for(var/datum/city_faction/faction in SScity_factions.all_factions)
				if(faction.category != category)
					continue
				var/state = (faction in SScity_factions.active_factions) ? "ON" : "OFF"
				choices["\[[state]\] [faction.name] ([category], [faction.Headcount()] playing)"] = faction
		var/picked = tgui_input_list(src, "Pick a faction to turn on or off. Players already in a faction keep their jobs.", "Manage City Factions", choices)
		if(!picked || !check_rights(R_ADMIN))
			return
		if(SSticker.current_state == GAME_STATE_SETTING_UP)
			to_chat(src, span_warning("Roles are being assigned right now. Try again in a moment."))
			return
		var/datum/city_faction/faction = choices[picked]
		if(faction in SScity_factions.active_factions)
			var/headcount = faction.Headcount()
			if(headcount && tgui_alert(src, "[headcount] players are in [faction.name]. They keep their jobs, but nobody new can join. Disable it?", "Disable Faction", list("Yes", "No")) != "Yes")
				continue
			if(!check_rights(R_ADMIN) || !SScity_factions.DisableFaction(faction))
				continue
			log_admin("[key_name(src)] disabled the city faction [faction.name].")
			message_admins("[key_name_admin(src)] disabled the city faction [faction.name].")
		else
			SScity_factions.EnableFaction(faction)
			log_admin("[key_name(src)] enabled the city faction [faction.name].")
			message_admins("[key_name_admin(src)] enabled the city faction [faction.name].")
		SSblackbox.record_feedback("tally", "admin_verb", 1, "Manage City Factions")

#undef CITY_FACTION_MENU_MAX_TOGGLES
