// RCE Leaderboard Console - In-game terminal to view expedition statistics

/obj/machinery/computer/rce_leaderboard
	name = "R-Corp Expedition Records"
	desc = "A terminal displaying historical expedition statistics and combat records."
	icon = 'icons/obj/computer.dmi'
	icon_state = "ratvarcomputer1"
	icon_screen = "ratvar1"
	icon_keyboard = "ratvar_key1"
	circuit = null
	light_color = COLOR_SOFT_RED

/obj/machinery/computer/rce_leaderboard/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	ui_interact(user)

/obj/machinery/computer/rce_leaderboard/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RCELeaderboard")
		ui.open()

/obj/machinery/computer/rce_leaderboard/ui_data(mob/user)
	var/list/data = list()

	if(!SSgamedirector.rce_leaderboard)
		data["error"] = "Leaderboard system not initialized"
		return data

	var/datum/rce_leaderboard/L = SSgamedirector.rce_leaderboard

	// Current round stats
	data["current"] = list(
		"expedition_number" = SSpersistence.rce_expedition_number,
		"total_items_produced" = L.total_items_produced,
		"materials_consumed" = L.materials_consumed,
		"total_mob_kills" = L.total_mob_kills,
		"players_participated" = length(L.participated_players),
		"heart_killed" = L.heart_killed,
		"round_time" = DisplayTimeText(world.time - L.round_start_time),
		"grenades_primed" = L.grenades_primed,
		"conveyor_belts_placed" = L.conveyor_belts_placed,
		"surgeries_completed" = L.surgeries_completed,
		"most_deaths_player" = L.GetMostDeathsPlayer()
	)

	// Current round factory breakdown
	var/list/current_factories = list()
	for(var/factory_path in L.factory_stats)
		var/list/factory_data = L.factory_stats[factory_path]
		current_factories += list(list(
			"path" = factory_path,
			"name" = L.GetFactoryName(factory_path),
			"items_produced" = factory_data["items_produced"],
			"materials" = factory_data["materials_consumed"]
		))
	data["current_factories"] = current_factories

	// Current round mob kill breakdown
	var/list/current_mobs = list()
	for(var/mob_path in L.mob_kills_by_type)
		current_mobs += list(list(
			"path" = mob_path,
			"name" = L.GetMobName(mob_path),
			"kills" = L.mob_kills_by_type[mob_path]
		))
	data["current_mobs"] = current_mobs

	// Current round players
	var/list/current_players = list()
	for(var/list/player in L.participated_players)
		current_players += list(list(
			"ckey" = player["ckey"],
			"name" = player["name"],
			"job" = player["job"]
		))
	data["current_players"] = current_players

	// Historical data - format for display
	var/list/history = list()
	for(var/list/expedition in L.expedition_history)
		var/list/exp_data = list()
		exp_data["expedition_number"] = expedition["expedition_number"]
		exp_data["timestamp"] = expedition["timestamp"]
		exp_data["duration"] = expedition["duration_seconds"] ? "[round(expedition["duration_seconds"] / 60)] min" : "Unknown"
		exp_data["end_condition"] = FormatEndCondition(expedition["end_condition"])
		exp_data["heart_killed"] = expedition["heart_killed"]

		var/list/players = expedition["players"]
		if(players)
			exp_data["participants"] = length(players["participated"])
			exp_data["survivors"] = length(players["survived"])
			exp_data["deaths"] = length(players["died"])
		else
			exp_data["participants"] = 0
			exp_data["survivors"] = 0
			exp_data["deaths"] = 0

		var/list/factory = expedition["factory_stats"]
		if(factory)
			exp_data["items_produced"] = factory["total_items"]
			exp_data["materials"] = factory["materials"]
		else
			exp_data["items_produced"] = 0
			exp_data["materials"] = list("green" = 0, "red" = 0, "blue" = 0, "purple" = 0, "orange" = 0, "silver" = 0)

		var/list/mobs = expedition["mob_kills"]
		if(mobs)
			exp_data["mob_kills"] = mobs["total"]
		else
			exp_data["mob_kills"] = 0

		// Additional stats
		exp_data["grenades_primed"] = expedition["grenades_primed"] || 0
		exp_data["conveyor_belts_placed"] = expedition["conveyor_belts_placed"] || 0
		exp_data["surgeries_completed"] = expedition["surgeries_completed"] || 0
		exp_data["most_deaths_player"] = expedition["most_deaths_player"]

		history += list(exp_data)
	data["history"] = history

	// All-time stats
	data["all_time"] = L.all_time_stats

	return data

/obj/machinery/computer/rce_leaderboard/ui_static_data(mob/user)
	var/list/data = list()
	return data

/// Format end condition for display
/obj/machinery/computer/rce_leaderboard/proc/FormatEndCondition(end_condition)
	switch(end_condition)
		if(RCE_END_HEART_KILLED)
			return "Victory - Heart Killed"
		if(RCE_END_SHUTTLE_ESCAPE)
			return "Shuttle Escape"
		if(RCE_END_ALL_DIED)
			return "Total Loss"
		if(RCE_END_ALL_DIED_LASTWAVE)
			return "Last Stand Failed"
		else
			return "Unknown"

// Wall-mounted variant
/obj/machinery/computer/rce_leaderboard/wall
	name = "R-Corp Expedition Records Terminal"
	desc = "A wall-mounted display showing expedition statistics."
	icon = 'icons/obj/machines/facilitymap.dmi'
	icon_state = "station_map"
	density = FALSE
	layer = ABOVE_WINDOW_LAYER
