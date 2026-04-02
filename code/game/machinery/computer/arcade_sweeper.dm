/// Sweeper Survival - Survive the Night in the Backstreets
/// Top-down survival: dodge 3 Sweeper waves, collect Ahn,
/// hide in buildings before each wave passes.
/// Game engine runs client-side in JavaScript.

/obj/machinery/computer/arcade/sweeper
	name = "Sweeper Survival Arcade"
	desc = "Survive the Night in the Backstreets. 81 seconds. 3 waves. Don't get caught."
	icon_state = "arcade"
	icon_keyboard = "no_keyboard"
	icon_screen = "invaders"
	light_color = LIGHT_COLOR_GREEN
	circuit = /obj/item/circuitboard/computer/arcade/sweeper
	/// Leaderboard: list of list("name","score")
	var/list/leaderboard = list()
	/// Sound throttle
	var/last_sfx_time = 0

/obj/machinery/computer/arcade/sweeper/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ArcadeSweeper", name)
		ui.open()

/obj/machinery/computer/arcade/sweeper/ui_static_data(mob/user)
	var/list/data = list()
	data["map"] = generate_map()
	data["spawns"] = generate_spawns()
	return data

/obj/machinery/computer/arcade/sweeper/ui_data(mob/user)
	var/list/data = list()
	data["leaderboard"] = leaderboard
	return data

/obj/machinery/computer/arcade/sweeper/ui_act(action, params)
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
				if("pickup")
					playsound(loc, 'sound/arcade/mana.ogg', 30, TRUE)
				if("siren")
					playsound(loc, 'sound/arcade/boom.ogg', 40, TRUE)
				if("door")
					playsound(loc, 'sound/arcade/hit.ogg', 30, TRUE)
				if("sweep")
					playsound(loc, 'sound/arcade/boom.ogg', 50, TRUE)
			. = TRUE

/// Generates a 32x32 Backstreets map
/// 0 = street, 1 = building wall, 2 = door, 3 = interior floor
/obj/machinery/computer/arcade/sweeper/proc/generate_map()
	var/list/data = list()
	data["width"] = 32
	data["height"] = 32
	// Row-major: each char is a tile type
	var/list/rows = list(
		"11111111111111111111111111111111",
		"11110001111100001111000011110001",
		"11110001111100001111000011110001",
		"11110001111100001111000011110001",
		"11121001111100001111000011121001",
		"00000000000000000000000000000001",
		"00000000000000000000000000000001",
		"00000000000000000000000000000001",
		"11111111001111100011111001111111",
		"11111111001111100011111001111111",
		"11111111001111100011111001111111",
		"11111111001111100011121001111111",
		"00000000000000000000000000000001",
		"00000000000000000000000000000001",
		"12100000000000000000000000001211",
		"13100000000000000000000000001311",
		"11100000000000000000000000001111",
		"00000000000000000000000000000001",
		"00000000000000000000000000000001",
		"11111100111111001111110011111111",
		"11111100111111001111110011111111",
		"11111100111111001121110011111111",
		"00000000000000000000000000000001",
		"00000000000000000000000000000001",
		"00000000000000000000000000000001",
		"11110001111100011111000111121111",
		"11110001111100011111000111131111",
		"11110001111100011111000111111111",
		"11121001111100011111000111111111",
		"00000000000000000000000000000001",
		"00000000000000000000000000000001",
		"11111111111111111111111111111111"
	)
	var/list/cells = list()
	for(var/row in rows)
		for(var/i in 1 to length(row))
			cells += text2num(copytext(row, i, i + 1))
	data["cells"] = cells
	return data

/// Generates Ahn pickup spawn positions on street tiles
/obj/machinery/computer/arcade/sweeper/proc/generate_spawns()
	var/list/spawns = list()
	// Pre-placed Ahn positions on open streets
	var/list/positions = list(
		list(5, 5), list(12, 5), list(19, 6),
		list(26, 6), list(3, 7),
		list(10, 12), list(17, 12), list(25, 13),
		list(5, 13), list(28, 17),
		list(3, 17), list(10, 17), list(18, 18),
		list(25, 22), list(15, 23),
		list(5, 23), list(12, 24), list(20, 29),
		list(8, 29), list(27, 30)
	)
	for(var/list/pos in positions)
		spawns += list(list("x" = pos[1], "y" = pos[2]))
	return spawns

// Circuit board
/obj/item/circuitboard/computer/arcade/sweeper
	name = "Sweeper Survival Arcade (Computer Board)"
	icon_state = "generic"
	build_path = /obj/machinery/computer/arcade/sweeper
