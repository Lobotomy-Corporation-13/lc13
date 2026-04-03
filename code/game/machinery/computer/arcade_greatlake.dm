/// Great Lake Trawler - Dredge-inspired fishing arcade
/// Fish the Great Lake, manage cargo, sell at port,
/// survive nightfall when Calamity Whales surface.
/// Game engine runs client-side in JavaScript.

/obj/machinery/computer/arcade/greatlake
	name = "Great Lake Trawler Arcade"
	desc = "Fish the Great Lake. Fill your hold. Sell at port. Survive the night."
	icon_state = "arcade"
	icon_keyboard = "no_keyboard"
	icon_screen = "invaders"
	light_color = "#2266aa"
	circuit = /obj/item/circuitboard/computer/arcade/greatlake
	/// Leaderboard: list of list("name","score")
	var/list/leaderboard = list()
	/// Sound throttle
	var/last_sfx_time = 0

/obj/machinery/computer/arcade/greatlake/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ArcadeGreatLake", name)
		ui.open()

/obj/machinery/computer/arcade/greatlake/ui_static_data(mob/user)
	var/list/data = list()
	data["map"] = generate_map()
	data["fishSpots"] = generate_fish_spots()
	data["ports"] = generate_ports()
	data["whalePath"] = generate_whale_path()
	return data

/obj/machinery/computer/arcade/greatlake/ui_data(mob/user)
	var/list/data = list()
	data["leaderboard"] = leaderboard
	return data

/obj/machinery/computer/arcade/greatlake/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("submit_score")
			var/score = text2num(params["score"])
			var/pname = usr?.name || "Unknown"
			leaderboard += list(list("name" = pname, "score" = score))
			leaderboard = sortTim(leaderboard, /proc/cmp_leaderboard_desc)
			if(length(leaderboard) > 10)
				leaderboard.Cut(11)
			prizevend(usr)
			playsound(loc, 'sound/arcade/win.ogg', 50, TRUE)
			. = TRUE
		if("died")
			playsound(loc, 'sound/arcade/lose.ogg', 50, TRUE)
			. = TRUE
		if("restart")
			update_static_data(usr)
			. = TRUE
		if("sfx")
			var/snd = params["s"]
			if(world.time - last_sfx_time < 3)
				return
			last_sfx_time = world.time
			switch(snd)
				if("catch")
					playsound(loc, 'sound/arcade/mana.ogg', 30, TRUE)
				if("sell")
					playsound(loc, 'sound/arcade/heal.ogg', 35, TRUE)
				if("splash")
					playsound(loc, 'sound/arcade/hit.ogg', 25, TRUE)
				if("whale")
					playsound(loc, 'sound/arcade/boom.ogg', 45, TRUE)
				if("night")
					playsound(loc, 'sound/arcade/boom.ogg', 35, TRUE)
			. = TRUE

/// 40x30 Great Lake map
/// 0=water, 1=land, 2=port, 3=reef
/obj/machinery/computer/arcade/greatlake/proc/generate_map()
	var/list/data = list()
	data["width"] = 40
	data["height"] = 30
	var/list/rows = list(
		"1111111111111111111111111111111111111111",
		"1110000000000000001100000000000000001111",
		"1100000000000000000000000000000000000111",
		"1000000000000000000000000000000000000011",
		"1000000300000000000000000011100000000011",
		"1000003300000000000000000011100000000001",
		"1000000000000000000000000000000000000001",
		"1000000000001110000000000000000000000001",
		"1000000000001110000000000000003300000001",
		"1000000000000000000000000000003300000021",
		"1000000000000000000000000000000000000021",
		"1000000000000000000000000000000000000001",
		"1000000000000000001100000000000000000001",
		"1000000000000000001100000000000000000001",
		"1000000000000000000000000000000000000001",
		"1000000000000000000000000000110000000001",
		"1200000000000000000000000000110000000001",
		"1200000000000000000000000000000000000001",
		"1000000000000000000000000000000000000001",
		"1000000000000000000000000000000000000001",
		"1000000000003300000000000000000000000001",
		"1000000000003300000000001100000000000001",
		"1000000000000000000000001100000000000001",
		"1000000000000000000000000000000000000001",
		"1000000000000000000000000000000000000001",
		"1100000000000000000000000000000000000011",
		"1100000000000000000000000000000000000011",
		"1110000000002200000000000000000000000111",
		"1111000000002200000000000000000000011111",
		"1111111111111111111111111111111111111111"
	)
	var/list/cells = list()
	for(var/row in rows)
		for(var/i in 1 to length(row))
			cells += text2num(copytext(row, i, i + 1))
	data["cells"] = cells
	return data

/// Fishing spot positions (on water tiles)
/obj/machinery/computer/arcade/greatlake/proc/generate_fish_spots()
	return list(
		list("x" = 6, "y" = 3),
		list("x" = 18, "y" = 5),
		list("x" = 30, "y" = 4),
		list("x" = 8, "y" = 12),
		list("x" = 22, "y" = 11),
		list("x" = 35, "y" = 14),
		list("x" = 12, "y" = 20),
		list("x" = 25, "y" = 19),
		list("x" = 15, "y" = 25),
		list("x" = 33, "y" = 24)
	)

/// Port locations and names
/obj/machinery/computer/arcade/greatlake/proc/generate_ports()
	return list(
		list("x" = 1, "y" = 16, "name" = "Portship Dock"),
		list("x" = 38, "y" = 9, "name" = "Twinhook Cove"),
		list("x" = 12, "y" = 27, "name" = "Port Trawl")
	)

/// Whale patrol waypoints
/obj/machinery/computer/arcade/greatlake/proc/generate_whale_path()
	return list(
		list("x" = 8, "y" = 6),
		list("x" = 30, "y" = 8),
		list("x" = 32, "y" = 20),
		list("x" = 15, "y" = 22),
		list("x" = 5, "y" = 15)
	)

// Circuit board
/obj/item/circuitboard/computer/arcade/greatlake
	name = "Great Lake Trawler Arcade (Computer Board)"
	icon_state = "generic"
	build_path = /obj/machinery/computer/arcade/greatlake
