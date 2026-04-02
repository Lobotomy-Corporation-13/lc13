/// Delivery Dash - Devyat' Association courier game
/// Top-down maze runner: deliver packages before
/// the Poludnitsa trunk's deadline expires.
/// Speed increases as timer runs low.
/// Game engine runs client-side in JavaScript.

/obj/machinery/computer/arcade/delivery
	name = "Delivery Dash Arcade"
	desc = "Run deliveries for Devyat' Association. The trunk waits for no one."
	icon_state = "arcade"
	icon_keyboard = "no_keyboard"
	icon_screen = "invaders"
	light_color = LIGHT_COLOR_GREEN
	circuit = /obj/item/circuitboard/computer/arcade/delivery
	/// Leaderboard: list of list("name","score")
	var/list/leaderboard = list()
	/// Sound throttle
	var/last_sfx_time = 0

/obj/machinery/computer/arcade/delivery/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ArcadeDelivery", name)
		ui.open()

/obj/machinery/computer/arcade/delivery/ui_static_data(mob/user)
	var/list/data = list()
	data["maps"] = generate_maps()
	return data

/obj/machinery/computer/arcade/delivery/ui_data(mob/user)
	var/list/data = list()
	data["leaderboard"] = leaderboard
	return data

/obj/machinery/computer/arcade/delivery/ui_act(action, params)
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
		if("sfx")
			var/snd = params["s"]
			if(world.time - last_sfx_time < 3)
				return
			last_sfx_time = world.time
			switch(snd)
				if("step")
					playsound(loc, 'sound/arcade/hit.ogg', 20, TRUE)
				if("deliver")
					playsound(loc, 'sound/arcade/heal.ogg', 40, TRUE)
				if("warn")
					playsound(loc, 'sound/arcade/boom.ogg', 35, TRUE)
				if("explode")
					playsound(loc, 'sound/arcade/boom.ogg', 50, TRUE)
				if("pickup")
					playsound(loc, 'sound/arcade/mana.ogg', 30, TRUE)
			. = TRUE

/// Generates multiple maze maps for successive rounds
/// 0 = floor, 1 = wall, 2 = crate/obstacle
/obj/machinery/computer/arcade/delivery/proc/generate_maps()
	var/list/maps = list()
	// Round 1: Simple
	maps += list(make_map(list(
		"1111111111111111111111111",
		"1000000010000000100000001",
		"1011110010111010101111101",
		"1010000000100010100000001",
		"1010111110101110111011101",
		"1000100000001000000010001",
		"1110101111101011111010101",
		"1000100000001010000010101",
		"1011101110101010101110101",
		"1000001000101000100000101",
		"1011111011101110111010101",
		"1000000010000000001010001",
		"1111111111111111111111111"
	)))
	// Round 2: Wider with detours
	maps += list(make_map(list(
		"1111111111111111111111111",
		"1000000000001000000000001",
		"1011101111101011111011101",
		"1010000000000000001000101",
		"1010111011111110101110101",
		"1000001010000010100000001",
		"1111101010101010101011111",
		"1000001000101000001000001",
		"1011111110101111111111101",
		"1000000010100000000000101",
		"1011110010101111101110101",
		"1000010000000000001000001",
		"1111111111111111111111111"
	)))
	// Round 3: Dense maze
	maps += list(make_map(list(
		"1111111111111111111111111",
		"1000100000000000100010001",
		"1010101110101110101010101",
		"1010000010001000000010001",
		"1011111010111011101110101",
		"1000001000000010000000001",
		"1010101110111010101111101",
		"1010100000100000100000001",
		"1010101110101010101011101",
		"1010000000001000001010001",
		"1011111110101110111010101",
		"1000000000100000000010001",
		"1111111111111111111111111"
	)))
	return maps

/// Parses a row list into a map data dict
/obj/machinery/computer/arcade/delivery/proc/make_map(list/rows)
	var/list/data = list()
	data["width"] = length(rows[1])
	data["height"] = length(rows)
	var/list/cells = list()
	for(var/row in rows)
		for(var/i in 1 to length(row))
			cells += text2num(copytext(row, i, i + 1))
	data["cells"] = cells
	return data

// Circuit board
/obj/item/circuitboard/computer/arcade/delivery
	name = "Delivery Dash Arcade (Computer Board)"
	icon_state = "generic"
	build_path = /obj/machinery/computer/arcade/delivery
