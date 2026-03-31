/// Space Slayer - A DOOM-like first person shooter arcade minigame.
/// The game engine runs entirely client-side in JavaScript;
/// the DM backend only provides map data and tracks high scores.

/obj/machinery/computer/arcade/fps
	name = "Space Slayer Arcade"
	desc = "A retro first-person shooter arcade cabinet. Rip and tear!"
	icon_state = "arcade"
	icon_keyboard = "no_keyboard"
	icon_screen = "invaders"
	light_color = LIGHT_COLOR_GREEN
	circuit = /obj/item/circuitboard/computer/arcade/fps
	/// The current level
	var/current_level = 1
	/// Max level for this machine
	var/max_level = 7
	/// Persistent high score for this machine
	var/high_score = 0

/obj/machinery/computer/arcade/fps/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ArcadeFps", name)
		ui.open()

/obj/machinery/computer/arcade/fps/ui_static_data(mob/user)
	var/list/data = list()
	data["map"] = generate_map(current_level)
	data["entities"] = generate_entities(current_level)
	data["player_start"] = generate_player_start(current_level)
	data["level"] = current_level
	data["maxLevel"] = max_level
	return data

/obj/machinery/computer/arcade/fps/ui_data(mob/user)
	var/list/data = list()
	data["high_score"] = high_score
	return data

/obj/machinery/computer/arcade/fps/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("submit_score")
			var/score = text2num(params["score"])
			if(score > high_score)
				high_score = score
			prizevend(usr)
			playsound(loc, 'sound/arcade/win.ogg', 50, TRUE)
			. = TRUE
		if("next_level")
			current_level = min(current_level + 1, max_level)
			update_static_data(usr)
			. = TRUE
		if("restart")
			current_level = 1
			update_static_data(usr)
			. = TRUE
		if("died")
			playsound(loc, 'sound/arcade/lose.ogg', 50, TRUE)
			current_level = 1
			update_static_data(usr)
			. = TRUE

/// Builds a multi-story map from stacked floor grids.
/// Each floor is a list of row strings using:
///   0 = open/empty (no floor here)
///   1-4 = wall, 5 = exit, 6 = floor tile
/// Rules:
///   - Floor tiles on story N get floorH = N * 1.0
///   - Ceiling comes from the next solid floor above
///   - No roof on the top floor (ceilH = stories + 1)
///   - Walls are full-height solid columns
///   - Slopes (S/T/V/W) can be used on floor 0
/obj/machinery/computer/arcade/fps/proc/build_multistory(list/floors)
	// All floors must be same dimensions
	var/w = length(floors[1][1])
	var/h = length(floors[1])
	var/num_floors = length(floors)
	var/max_ceil = num_floors + 1

	var/list/data = list()
	data["width"] = w
	data["height"] = h
	var/list/cells = list()
	var/list/floorH = list()
	var/list/ceilH = list()
	var/list/slopes = list()
	var/has_slopes = FALSE

	for(var/gy in 1 to h)
		for(var/gx in 1 to w)
			// Read this cell on every floor
			var/list/floor_chars = list()
			for(var/fi in 1 to num_floors)
				var/row = floors[fi][gy]
				var/ch = copytext(row, gx, gx + 1)
				floor_chars += ch

			// Find what's here
			var/is_wall = FALSE
			var/wall_type = 0
			var/is_exit = FALSE
			var/lowest_floor = -1
			var/ceil_from_above = max_ceil
			var/slope_data = 0

			for(var/fi in 1 to num_floors)
				var/ch = floor_chars[fi]
				var/story_h = (fi - 1) * 1.0
				switch(ch)
					if("1","2","3","4")
						is_wall = TRUE
						wall_type = text2num(ch)
					if("5")
						is_exit = TRUE
						if(lowest_floor < 0)
							lowest_floor = story_h
					if("6")
						if(lowest_floor < 0)
							lowest_floor = story_h
						else
							// Upper floor = ceiling
							ceil_from_above = story_h
					if("S")
						if(lowest_floor < 0)
							lowest_floor = story_h
						slope_data = list("dir" = 0, "rise" = 1.0)
						has_slopes = TRUE
					if("T")
						if(lowest_floor < 0)
							lowest_floor = story_h
						slope_data = list("dir" = 1, "rise" = 1.0)
						has_slopes = TRUE
					if("V")
						if(lowest_floor < 0)
							lowest_floor = story_h
						slope_data = list("dir" = 2, "rise" = 1.0)
						has_slopes = TRUE
					if("W")
						if(lowest_floor < 0)
							lowest_floor = story_h
						slope_data = list("dir" = 3, "rise" = 1.0)
						has_slopes = TRUE
					// "0" = empty, skip

			if(is_wall)
				cells += wall_type
				floorH += 0
				ceilH += max_ceil
				slopes += 0
			else if(is_exit)
				cells += 5
				floorH += lowest_floor
				ceilH += ceil_from_above
				slopes += 0
			else if(lowest_floor >= 0)
				cells += 0
				floorH += lowest_floor
				ceilH += ceil_from_above
				if(slope_data)
					slopes += list(slope_data)
				else
					slopes += 0
			else
				// Empty on all floors = void wall
				cells += 1
				floorH += 0
				ceilH += max_ceil
				slopes += 0

	data["cells"] = cells
	data["floorH"] = floorH
	data["ceilH"] = ceilH
	if(has_slopes)
		data["slopes"] = slopes
	return data

/// Parses a list of row strings into a map data dict.
/// Supports extended tile characters:
///   0 = floor, 1-4 = wall textures, 5 = exit
///   P = raised platform (floorH 0.3)
///   U = upper platform (floorH 0.5)
///   D = depression/pit (floorH -0.3)
///   L = low ceiling (ceilH 0.6)
///   H = hole (drop-through to Z below)
///   I = slope up-facing (+y, rise 0.3)
///   J = slope left-facing (-x, rise 0.3)
///   K = slope down-facing (-y, rise 0.3)
///   R = slope right-facing (+x, rise 0.3)
///   F = second floor (floorH 1.0, ceilH 2.0)
///   G = ground under upper (floorH 0, ceilH 1.0)
///   O = open atrium (floorH 0, ceilH 2.0)
///   S = ramp up (+y, rise 1.0, full story)
///   T = ramp right (+x, rise 1.0, full story)
///   V = ramp down (-y, rise 1.0, full story)
///   W = ramp left (-x, rise 1.0, full story)
/obj/machinery/computer/arcade/fps/proc/parse_map_string(list/rows)
	var/list/data = list()
	var/w = length(rows[1])
	var/h = length(rows)
	data["width"] = w
	data["height"] = h
	var/list/cells = list()
	var/list/floorH = list()
	var/list/ceilH = list()
	var/list/holes = list()
	var/list/slopes = list()
	var/has_slopes = FALSE

	for(var/row in rows)
		for(var/i in 1 to length(row))
			var/ch = copytext(row, i, i + 1)
			switch(ch)
				if("0")
					cells += 0
					floorH += 0
					ceilH += 1.0
					slopes += 0
				if("1", "2", "3", "4")
					cells += text2num(ch)
					floorH += 0
					ceilH += 1.0
					slopes += 0
				if("5")
					cells += 5
					floorH += 0
					ceilH += 1.0
					slopes += 0
				if("P")
					cells += 0
					floorH += 0.3
					ceilH += 1.0
					slopes += 0
				if("U")
					cells += 0
					floorH += 0.5
					ceilH += 1.0
					slopes += 0
				if("D")
					cells += 0
					floorH += -0.3
					ceilH += 1.0
					slopes += 0
				if("L")
					cells += 0
					floorH += 0
					ceilH += 0.6
					slopes += 0
				if("H")
					cells += 0
					floorH += 0
					ceilH += 1.0
					slopes += 0
					holes += length(cells)
				if("I")
					// Slope up-facing: rises toward +y
					cells += 0
					floorH += 0
					ceilH += 1.0
					slopes += list(list("dir" = 0, "rise" = 0.3))
					has_slopes = TRUE
				if("J")
					// Slope left-facing: rises toward -x
					cells += 0
					floorH += 0
					ceilH += 1.0
					slopes += list(list("dir" = 3, "rise" = 0.3))
					has_slopes = TRUE
				if("K")
					// Slope down-facing: rises toward -y
					cells += 0
					floorH += 0
					ceilH += 1.0
					slopes += list(list("dir" = 2, "rise" = 0.3))
					has_slopes = TRUE
				if("R")
					// Slope right-facing: rises toward +x
					cells += 0
					floorH += 0
					ceilH += 1.0
					slopes += list(list("dir" = 1, "rise" = 0.3))
					has_slopes = TRUE
				if("F")
					// Second floor
					cells += 0
					floorH += 1.0
					ceilH += 2.0
					slopes += 0
				if("G")
					// Ground under upper floor
					cells += 0
					floorH += 0
					ceilH += 1.0
					slopes += 0
				if("O")
					// Open atrium (double height)
					cells += 0
					floorH += 0
					ceilH += 2.0
					slopes += 0
				if("S")
					// Full story ramp up (+y)
					cells += 0
					floorH += 0
					ceilH += 2.0
					slopes += list(list("dir" = 0, "rise" = 1.0))
					has_slopes = TRUE
				if("T")
					// Full story ramp right (+x)
					cells += 0
					floorH += 0
					ceilH += 2.0
					slopes += list(list("dir" = 1, "rise" = 1.0))
					has_slopes = TRUE
				if("V")
					// Full story ramp down (-y)
					cells += 0
					floorH += 0
					ceilH += 2.0
					slopes += list(list("dir" = 2, "rise" = 1.0))
					has_slopes = TRUE
				if("W")
					// Full story ramp left (-x)
					cells += 0
					floorH += 0
					ceilH += 2.0
					slopes += list(list("dir" = 3, "rise" = 1.0))
					has_slopes = TRUE
				else
					cells += 0
					floorH += 0
					ceilH += 1.0
					slopes += 0

	data["cells"] = cells
	data["floorH"] = floorH
	data["ceilH"] = ceilH
	if(length(holes))
		data["holes"] = holes
	if(has_slopes)
		data["slopes"] = slopes
	return data

/// Generates a 24x24 map grid as a flat list.
/// 0 = empty, 1-4 = wall texture types, 5 = exit door
/obj/machinery/computer/arcade/fps/proc/generate_map(level)
	switch(level)
		if(1)
			return generate_level_1()
		if(2)
			return generate_level_2()
		if(3)
			return generate_level_3()
		if(4)
			return generate_level_4()
		if(5)
			return generate_level_5()
		if(6)
			return generate_level_6()
		if(7)
			return generate_level_7()
	return generate_level_1()

/// Level 1: Simple corridors, teaches movement
/obj/machinery/computer/arcade/fps/proc/generate_level_1()
	var/list/data = list()
	data["width"] = 24
	data["height"] = 24
	// Row-major flat grid
	var/list/cells = list()
	// Build the map row by row
	var/list/rows = list(
		"111111111111111111111111",
		"100000001000000010000001",
		"100000001000000010000001",
		"100000001000000010000001",
		"100000001000000000000001",
		"100000001000000000000001",
		"100000000000002200000001",
		"100000000000000000000001",
		"133300001000000000000001",
		"100000001000000010000001",
		"100000001000000010000001",
		"100000001111011110000001",
		"100000000000000000000001",
		"100000000000000000000001",
		"111101111000000000000001",
		"100000001000000011110111",
		"100000001000000010000001",
		"100000001000000010000001",
		"100000000000000010000001",
		"100000000000000010000001",
		"100000001000000000000001",
		"100000001000000000000051",
		"100000001000000000000001",
		"111111111111111111111111"
	)
	for(var/row in rows)
		for(var/i in 1 to length(row))
			cells += text2num(copytext(row, i, i + 1))
	data["cells"] = cells
	return data

/// Level 2: Rooms and corridors, more complex
/obj/machinery/computer/arcade/fps/proc/generate_level_2()
	var/list/data = list()
	data["width"] = 24
	data["height"] = 24
	var/list/cells = list()
	var/list/rows = list(
		"222222222222222222222222",
		"200000000020000000000002",
		"200000000020000000000002",
		"200000000020000000000002",
		"200000000000000003300002",
		"200000000000000003300002",
		"222202222020000000000002",
		"200000002020000000000002",
		"200000002022222022222222",
		"200000002000000000000002",
		"200000000000000000000002",
		"200000002000000000000002",
		"222222222022220222000002",
		"200000000020000002000002",
		"200000000020000002000002",
		"200000000020000002000002",
		"200033000000000000000002",
		"200033000000000002000002",
		"200000000020000002222022",
		"222220222020000000000002",
		"200000000020000000000002",
		"200000000020000000000052",
		"200000000020000000000002",
		"222222222222222222222222"
	)
	for(var/row in rows)
		for(var/i in 1 to length(row))
			cells += text2num(copytext(row, i, i + 1))
	data["cells"] = cells
	return data

/// Level 3: Maze with cult theme, hardest
/obj/machinery/computer/arcade/fps/proc/generate_level_3()
	var/list/data = list()
	data["width"] = 24
	data["height"] = 24
	var/list/cells = list()
	var/list/rows = list(
		"444444444444444444444444",
		"400000000040000000000004",
		"400000000040333040000004",
		"403330000040333040000004",
		"400030000040000040000004",
		"400030000000000044404444",
		"400000000040000000000004",
		"400000000040000000000004",
		"444440444040000043334004",
		"400000004040000040000004",
		"400000004000000040000004",
		"400000004000000040000004",
		"400000004044444040000004",
		"433300000000000000000004",
		"400000000000000044440044",
		"400000004044444000000004",
		"444404444040000000000004",
		"400000000040000043334004",
		"400000000040000040000004",
		"400000000040000040000004",
		"400333000000000000000004",
		"400000000040000000000054",
		"400000000040000000000004",
		"444444444444444444444444"
	)
	for(var/row in rows)
		for(var/i in 1 to length(row))
			cells += text2num(copytext(row, i, i + 1))
	data["cells"] = cells
	return data

/// Level 4: Multi-height level using extended tile chars
/obj/machinery/computer/arcade/fps/proc/generate_level_4()
	var/list/data = parse_map_string(list(
		"111111111111111111111111",
		"1PPPJ001000000010000001",
		"1PPPJ001000000010000001",
		"1PPPJ001000000000000001",
		"100000000000000000000001",
		"100000000000000000000001",
		"100000001000000010000001",
		"100000001000000010000001",
		"111100111100001111001111",
		"1UUUJ001000000010000001",
		"1UUUJ001000000010000001",
		"1UUUJ0000LLLLLL00000001",
		"100000000LLLLLL00000001",
		"100000000LLLLLL00000001",
		"100000001000000010000001",
		"111100111KKKKKK011100111",
		"100000001DDDDDD010000001",
		"100000001DDDDDD010000001",
		"100000000DDDDDD000000001",
		"1000000000000000IIIIIII1",
		"10000000100000000PPPPP01",
		"10000000100000000PPPPP51",
		"10000000100000000PPPPP01",
		"111111111111111111111111"
	))

	// Elevators (still need separate definition)
	data["elevators"] = list(
		list("x" = 5, "y" = 4, "minH" = 0, "maxH" = 0.5, "speed" = 0.2),
		list("x" = 5, "y" = 18, "minH" = -0.3, "maxH" = 0, "speed" = 0.15)
	)

	return data

/// Level 5: Two-story intro
/// Floor 1 = ground, Floor 2 = upper walkways
/// 6 = floor tile, 0 = empty/open
/obj/machinery/computer/arcade/fps/proc/generate_level_5()
	return build_multistory(list(
		// Floor 1 (ground, y=0)
		list(
			"111111111111111111111111",
			"166666616666666166666S1",
			"166666616666666166666661",
			"166666616666666166666661",
			"166666606666666066666661",
			"166666606666666066666661",
			"166666616666666166666661",
			"111101111111111111101111",
			"166666666666666666666661",
			"166666666666666666666661",
			"166666661111111166666661",
			"166666661000000166666661",
			"166666661000000166666661",
			"166666661000000166666661",
			"166666661000000166666661",
			"166666661111011166666661",
			"166666666666666666666661",
			"166666666666666666666661",
			"111101111111111111101111",
			"166666606666666066666661",
			"166666606666666066666661",
			"166666606666666066666651",
			"166666616666666166666661",
			"111111111111111111111111"
		),
		// Floor 2 (upper, height=1.0)
		list(
			"111111111111111111111111",
			"100000010000000100000001",
			"100000010000000100000001",
			"100000010000000100000001",
			"100000000000000000000001",
			"100000000000000000000001",
			"100000010000000100000001",
			"111101111111111111101111",
			"100000000000000000000001",
			"100000000000000000000001",
			"100000001111111100000001",
			"100000001666666100000001",
			"100000001666666100000001",
			"100000001666666100000001",
			"100000001666666100000001",
			"100000001111011100000001",
			"100000000000000000000001",
			"100000000000000000000001",
			"111101111111111111101111",
			"100000000000000000000001",
			"100000000000000000000001",
			"100000000000000000000001",
			"100000010000000100000001",
			"111111111111111111111111"
		)
	))

/// Level 6: Complex two-story with ramps
/obj/machinery/computer/arcade/fps/proc/generate_level_6()
	return build_multistory(list(
		// Floor 1 (ground)
		list(
			"111111111111111111111111",
			"166666616666666166666661",
			"166666616666666166666661",
			"166666616666666166666661",
			"16666S616666666166666661",
			"166666616666666166666661",
			"166666611111111166666661",
			"166666666666666666666661",
			"166666666666666666666661",
			"111111116666666611111111",
			"166666666666666666666661",
			"166666666666666666666661",
			"166666666000000066666661",
			"166666666000000066666S61",
			"166666666000000066666661",
			"111111116666666611111111",
			"166666666666666666666661",
			"166666666666666666666661",
			"166666S11111111166666661",
			"166666616666666166666661",
			"166666616666666166666661",
			"166666616666666166666651",
			"166666616666666166666661",
			"111111111111111111111111"
		),
		// Floor 2 (upper)
		list(
			"111111111111111111111111",
			"166666610000000100000001",
			"166666610000000100000001",
			"166666610000000100000001",
			"100000010000000100000001",
			"100000010000000166666661",
			"100000011111111100000001",
			"100000000000000000000001",
			"100000000000000000000001",
			"111111110000000011111111",
			"100000000000000016666661",
			"100000000000000016666661",
			"100000000666666016666661",
			"100000000666666000000001",
			"100000000666666000000001",
			"111111110000000011111111",
			"100000000000000000000001",
			"100000000000000000000001",
			"100000001111111100000001",
			"166666610000000166666661",
			"166666610000000166666661",
			"166666610000000166666661",
			"166666610000000166666661",
			"111111111111111111111111"
		)
	))

/// Level 7: Three-story gauntlet
/obj/machinery/computer/arcade/fps/proc/generate_level_7()
	return build_multistory(list(
		// Floor 1 (ground)
		list(
			"444444444444444444444444",
			"466666646666666466666664",
			"466666646666666466666664",
			"466666646666666466666664",
			"46666S646666666466666664",
			"466666646666666466666664",
			"466666644444444466666664",
			"466666666666666666666664",
			"444404446666666644404444",
			"466666666666666666666664",
			"466666666666666666666664",
			"466666666666666666666664",
			"466666666666666666666664",
			"466666666666666666666664",
			"466666664444444466666664",
			"466666666666666666666664",
			"466666666666666666666664",
			"444404444444444444404444",
			"466666666666666666666664",
			"466666666666666666666664",
			"466666666666666666666664",
			"466666666666666666666654",
			"466666666666666666666664",
			"444444444444444444444444"
		),
		// Floor 2 (upper)
		list(
			"444444444444444444444444",
			"400000040000000400000004",
			"400000040000000400000004",
			"400000040000000400000004",
			"400000040000000400000004",
			"400000040000000466666664",
			"400000044444444400000004",
			"400000000000000000000004",
			"444404440000000044404444",
			"466666660000000000000004",
			"466666660000000000000004",
			"466666660000000000000004",
			"466666660000000000000004",
			"46666S660000000000000004",
			"466666664444444400000004",
			"400000000000000000000004",
			"400000000000000000000004",
			"444404444444444444404444",
			"400000000000000046666664",
			"400000000000000046666664",
			"400000000000000046666664",
			"400000000000000046666664",
			"400000000000000046666664",
			"444444444444444444444444"
		),
		// Floor 3 (top)
		list(
			"444444444444444444444444",
			"400000040000000400000004",
			"400000040000000400000004",
			"400000040000000400000004",
			"400000040000000400000004",
			"400000040000000400000004",
			"400000044444444400000004",
			"400000000000000000000004",
			"444404440000000044404444",
			"400000000000000000000004",
			"400000000000000000000004",
			"400000000000000000000004",
			"400000000000000000000004",
			"400000000000000000000004",
			"400000004444444400000004",
			"400000000000000000000004",
			"400000000000000000000004",
			"444404444444444444404444",
			"400000000000000400000004",
			"400000000000000400000004",
			"400000000000000400000004",
			"400000000000000400000004",
			"400000000000000400000004",
			"444444444444444444444444"
		)
	))

/// Generates entity spawn data for a level
/obj/machinery/computer/arcade/fps/proc/generate_entities(level)
	var/list/ents = list()
	switch(level)
		if(1)
			// 4 blob enemies, some pickups
			ents += list(list("type" = "enemy_blob", "x" = 5.5, "y" = 3.5))
			ents += list(list("type" = "enemy_blob", "x" = 14.5, "y" = 5.5))
			ents += list(list("type" = "enemy_blob", "x" = 20.5, "y" = 3.5))
			ents += list(list("type" = "enemy_blob", "x" = 5.5, "y" = 16.5))
			ents += list(list("type" = "pickup_health", "x" = 10.5, "y" = 7.5))
			ents += list(list("type" = "pickup_ammo", "x" = 3.5, "y" = 13.5))
			ents += list(list("type" = "pickup_health", "x" = 18.5, "y" = 18.5))
		if(2)
			// 8 mixed enemies
			ents += list(list("type" = "enemy_blob", "x" = 3.5, "y" = 2.5))
			ents += list(list("type" = "enemy_alien", "x" = 14.5, "y" = 2.5))
			ents += list(list("type" = "enemy_blob", "x" = 3.5, "y" = 9.5))
			ents += list(list("type" = "enemy_alien", "x" = 14.5, "y" = 10.5))
			ents += list(list("type" = "enemy_blob", "x" = 3.5, "y" = 16.5))
			ents += list(list("type" = "enemy_alien", "x" = 10.5, "y" = 16.5))
			ents += list(list("type" = "enemy_cult", "x" = 20.5, "y" = 14.5))
			ents += list(list("type" = "enemy_cult", "x" = 20.5, "y" = 20.5))
			ents += list(list("type" = "pickup_health", "x" = 7.5, "y" = 10.5))
			ents += list(list("type" = "pickup_ammo", "x" = 15.5, "y" = 6.5))
			ents += list(list("type" = "pickup_health", "x" = 3.5, "y" = 20.5))
			ents += list(list("type" = "pickup_ammo", "x" = 20.5, "y" = 9.5))
		if(3)
			// 12 enemies including tough cultists
			ents += list(list("type" = "enemy_blob", "x" = 5.5, "y" = 2.5))
			ents += list(list("type" = "enemy_alien", "x" = 14.5, "y" = 2.5))
			ents += list(list("type" = "enemy_cult", "x" = 20.5, "y" = 2.5))
			ents += list(list("type" = "enemy_blob", "x" = 2.5, "y" = 9.5))
			ents += list(list("type" = "enemy_alien", "x" = 8.5, "y" = 13.5))
			ents += list(list("type" = "enemy_cult", "x" = 14.5, "y" = 10.5))
			ents += list(list("type" = "enemy_blob", "x" = 20.5, "y" = 9.5))
			ents += list(list("type" = "enemy_alien", "x" = 2.5, "y" = 17.5))
			ents += list(list("type" = "enemy_cult", "x" = 8.5, "y" = 20.5))
			ents += list(list("type" = "enemy_cult", "x" = 18.5, "y" = 17.5))
			ents += list(list("type" = "enemy_alien", "x" = 14.5, "y" = 20.5))
			ents += list(list("type" = "enemy_cult", "x" = 20.5, "y" = 20.5))
			ents += list(list("type" = "pickup_health", "x" = 2.5, "y" = 6.5))
			ents += list(list("type" = "pickup_ammo", "x" = 10.5, "y" = 6.5))
			ents += list(list("type" = "pickup_health", "x" = 2.5, "y" = 14.5))
			ents += list(list("type" = "pickup_ammo", "x" = 20.5, "y" = 14.5))
			ents += list(list("type" = "pickup_health", "x" = 10.5, "y" = 20.5))
		if(4)
			// Multi-height level enemies
			ents += list(list("type" = "enemy_blob", "x" = 2.5, "y" = 2.5))
			ents += list(list("type" = "enemy_alien", "x" = 14.5, "y" = 3.5))
			ents += list(list("type" = "enemy_cult", "x" = 20.5, "y" = 2.5))
			ents += list(list("type" = "enemy_blob", "x" = 2.5, "y" = 10.5))
			ents += list(list("type" = "enemy_alien", "x" = 11.5, "y" = 12.5))
			ents += list(list("type" = "enemy_cult", "x" = 20.5, "y" = 10.5))
			ents += list(list("type" = "enemy_blob", "x" = 2.5, "y" = 18.5))
			ents += list(list("type" = "enemy_alien", "x" = 11.5, "y" = 18.5))
			ents += list(list("type" = "enemy_cult", "x" = 20.5, "y" = 17.5))
			ents += list(list("type" = "enemy_cult", "x" = 20.5, "y" = 21.5))
			ents += list(list("type" = "pickup_health", "x" = 2.5, "y" = 6.5))
			ents += list(list("type" = "pickup_ammo", "x" = 14.5, "y" = 6.5))
			ents += list(list("type" = "pickup_health", "x" = 6.5, "y" = 14.5))
			ents += list(list("type" = "pickup_ammo", "x" = 20.5, "y" = 14.5))
			ents += list(list("type" = "pickup_health", "x" = 11.5, "y" = 20.5))
		if(5)
			// Two-layer level enemies (on upper floor)
			ents += list(list("type" = "enemy_blob", "x" = 5.5, "y" = 2.5))
			ents += list(list("type" = "enemy_alien", "x" = 14.5, "y" = 2.5))
			ents += list(list("type" = "enemy_cult", "x" = 20.5, "y" = 5.5))
			ents += list(list("type" = "enemy_blob", "x" = 2.5, "y" = 10.5))
			ents += list(list("type" = "enemy_alien", "x" = 14.5, "y" = 10.5))
			ents += list(list("type" = "enemy_cult", "x" = 20.5, "y" = 10.5))
			ents += list(list("type" = "enemy_blob", "x" = 2.5, "y" = 18.5))
			ents += list(list("type" = "enemy_alien", "x" = 10.5, "y" = 18.5))
			ents += list(list("type" = "enemy_cult", "x" = 20.5, "y" = 18.5))
			ents += list(list("type" = "enemy_cult", "x" = 10.5, "y" = 13.5))
			ents += list(list("type" = "pickup_health", "x" = 2.5, "y" = 5.5))
			ents += list(list("type" = "pickup_ammo", "x" = 14.5, "y" = 6.5))
			ents += list(list("type" = "pickup_health", "x" = 5.5, "y" = 14.5))
			ents += list(list("type" = "pickup_ammo", "x" = 20.5, "y" = 14.5))
			ents += list(list("type" = "pickup_health", "x" = 10.5, "y" = 20.5))
		if(6)
			// Two-story level enemies
			// Ground floor enemies
			ents += list(list("type" = "enemy_blob", "x" = 5.5, "y" = 9.5))
			ents += list(list("type" = "enemy_alien", "x" = 18.5, "y" = 9.5))
			ents += list(list("type" = "enemy_cult", "x" = 10.5, "y" = 16.5))
			ents += list(list("type" = "enemy_blob", "x" = 5.5, "y" = 16.5))
			ents += list(list("type" = "enemy_alien", "x" = 18.5, "y" = 16.5))
			// Upper floor enemies
			ents += list(list("type" = "enemy_cult", "x" = 18.5, "y" = 2.5))
			ents += list(list("type" = "enemy_cult", "x" = 3.5, "y" = 20.5))
			ents += list(list("type" = "enemy_alien", "x" = 14.5, "y" = 12.5))
			ents += list(list("type" = "enemy_blob", "x" = 10.5, "y" = 12.5))
			// Pickups
			ents += list(list("type" = "pickup_health", "x" = 3.5, "y" = 9.5))
			ents += list(list("type" = "pickup_ammo", "x" = 20.5, "y" = 9.5))
			ents += list(list("type" = "pickup_health", "x" = 3.5, "y" = 16.5))
			ents += list(list("type" = "pickup_ammo", "x" = 14.5, "y" = 20.5))
		if(7)
			// Multi-story gauntlet enemies
			ents += list(list("type" = "enemy_cult", "x" = 3.5, "y" = 2.5))
			ents += list(list("type" = "enemy_blob", "x" = 18.5, "y" = 2.5))
			ents += list(list("type" = "enemy_alien", "x" = 10.5, "y" = 7.5))
			ents += list(list("type" = "enemy_cult", "x" = 3.5, "y" = 10.5))
			ents += list(list("type" = "enemy_cult", "x" = 20.5, "y" = 10.5))
			ents += list(list("type" = "enemy_alien", "x" = 10.5, "y" = 11.5))
			ents += list(list("type" = "enemy_blob", "x" = 3.5, "y" = 16.5))
			ents += list(list("type" = "enemy_alien", "x" = 20.5, "y" = 16.5))
			ents += list(list("type" = "enemy_cult", "x" = 3.5, "y" = 20.5))
			ents += list(list("type" = "enemy_cult", "x" = 18.5, "y" = 20.5))
			ents += list(list("type" = "pickup_health", "x" = 10.5, "y" = 3.5))
			ents += list(list("type" = "pickup_ammo", "x" = 10.5, "y" = 16.5))
			ents += list(list("type" = "pickup_health", "x" = 3.5, "y" = 7.5))
			ents += list(list("type" = "pickup_ammo", "x" = 20.5, "y" = 7.5))
	return ents

/// Returns the player start position for a level
/obj/machinery/computer/arcade/fps/proc/generate_player_start(level)
	switch(level)
		if(1)
			return list("x" = 1.5, "y" = 1.5, "angle" = 0)
		if(2)
			return list("x" = 1.5, "y" = 1.5, "angle" = 0)
		if(3)
			return list("x" = 1.5, "y" = 1.5, "angle" = 0)
		if(4)
			return list("x" = 6.5, "y" = 5.5, "angle" = 0)
		if(5)
			return list("x" = 3.5, "y" = 8.5, "angle" = 0)
		if(6)
			return list("x" = 3.5, "y" = 7.5, "angle" = 0)
		if(7)
			return list("x" = 10.5, "y" = 7.5, "angle" = 0)
	return list("x" = 1.5, "y" = 1.5, "angle" = 0)

// Subtypes that start on specific levels for testing
/obj/machinery/computer/arcade/fps/level4
	name = "Space Slayer Arcade (Level 4)"
	desc = "Pre-loaded to the multi-height level."
	current_level = 4

/obj/machinery/computer/arcade/fps/level5
	name = "Space Slayer Arcade (Level 5)"
	desc = "Pre-loaded to the multi-Z level."
	current_level = 5

/obj/machinery/computer/arcade/fps/level6
	name = "Space Slayer Arcade (Two-Story)"
	desc = "A two-story building. Look up!"
	current_level = 6

/// Dedicated multi-story arcade - 3 levels of
/// two-story buildings (levels 5, 6, 7)
/obj/machinery/computer/arcade/fps/multistory
	name = "Space Slayer: Vertical Ops"
	desc = "Multi-story combat. Watch your head... and the floor beneath your feet."
	current_level = 5
	max_level = 7

/obj/machinery/computer/arcade/fps/multistory/ui_act(action, params)
	. = ..()
	if(.)
		return
	// Override restart/died to reset to level 5
	switch(action)
		if("restart")
			current_level = 5
			update_static_data(usr)
			return TRUE
		if("died")
			playsound(loc, 'sound/arcade/lose.ogg', 50, TRUE)
			current_level = 5
			update_static_data(usr)
			return TRUE

// Circuit board
/obj/item/circuitboard/computer/arcade/fps
	name = "Space Slayer Arcade (Computer Board)"
	icon_state = "generic"
	build_path = /obj/machinery/computer/arcade/fps

// ==========================================
// Station Map Variant
// Reads the live station map around the
// arcade machine and converts it to an
// FPS-playable grid.
// ==========================================

#define STATION_FPS_CHUNK 48

/obj/machinery/computer/arcade/fps/station
	name = "Space Slayer Arcade (Station Map)"
	desc = "A retro FPS arcade that scans the surrounding facility. Looks familiar..."
	/// Cached floor tile positions for entity placement
	var/list/floor_tiles

/obj/machinery/computer/arcade/fps/station/generate_map(level)
	var/list/data = list()
	data["width"] = STATION_FPS_CHUNK
	data["height"] = STATION_FPS_CHUNK
	var/list/cells = list()
	floor_tiles = list()

	var/half = STATION_FPS_CHUNK / 2
	var/origin_x = src.x - half
	var/origin_y = src.y - half
	var/src_z = src.z

	for(var/gy in 0 to STATION_FPS_CHUNK - 1)
		for(var/gx in 0 to STATION_FPS_CHUNK - 1)
			var/wx = origin_x + gx
			var/wy = origin_y + gy
			var/turf/T = locate(wx, wy, src_z)

			if(!T)
				cells += 1
				continue

			// Check for doors - treat as passable
			var/has_door = FALSE
			for(var/obj/machinery/door/D in T)
				has_door = TRUE
				break

			if(has_door)
				cells += 0
				floor_tiles += list(list(gx, gy))
				continue

			if(isclosedturf(T) || isspaceturf(T))
				// Vary wall texture by position
				var/wall_type = ((gx + gy) % 4) + 1
				cells += wall_type
			else
				cells += 0
				floor_tiles += list(list(gx, gy))

	// Place exit at the furthest reachable floor
	var/exit_pos = find_furthest_floor(cells, half, half)
	if(exit_pos)
		cells[exit_pos] = 5

	data["cells"] = cells
	return data

/// BFS from center to find the furthest reachable floor tile.
/// Returns the 1-indexed cell position for the exit, or null.
/obj/machinery/computer/arcade/fps/station/proc/find_furthest_floor(list/cells, start_x, start_y)
	var/w = STATION_FPS_CHUNK
	var/list/visited = list()
	var/list/queue = list(list(start_x, start_y))
	var/last_floor_idx = null
	var/key = "[start_x],[start_y]"
	visited[key] = TRUE

	while(length(queue))
		var/list/pos = queue[1]
		queue.Cut(1, 2)
		var/px = pos[1]
		var/py = pos[2]
		var/idx = py * w + px + 1
		if(idx >= 1 && idx <= length(cells) && cells[idx] == 0)
			last_floor_idx = idx

		// Check 4 neighbors
		var/list/dirs = list(
			list(px + 1, py),
			list(px - 1, py),
			list(px, py + 1),
			list(px, py - 1)
		)
		for(var/list/d in dirs)
			var/nx = d[1]
			var/ny = d[2]
			if(nx < 0 || nx >= w || ny < 0 || ny >= w)
				continue
			var/nkey = "[nx],[ny]"
			if(visited[nkey])
				continue
			var/ni = ny * w + nx + 1
			if(ni < 1 || ni > length(cells))
				continue
			if(cells[ni] != 0)
				continue
			visited[nkey] = TRUE
			queue += list(list(nx, ny))

	return last_floor_idx

/obj/machinery/computer/arcade/fps/station/generate_entities(level)
	var/list/ents = list()
	if(!floor_tiles || !length(floor_tiles))
		return ents

	var/half = STATION_FPS_CHUNK / 2
	var/list/available = floor_tiles.Copy()
	var/list/enemy_types = list("enemy_blob", "enemy_alien", "enemy_cult")

	// Place 10 enemies at random floor tiles, away from center
	var/enemies_placed = 0
	var/attempts = 0
	while(enemies_placed < 10 && length(available) && attempts < 100)
		attempts++
		var/pick_idx = rand(1, length(available))
		var/list/tile = available[pick_idx]
		var/tx = tile[1]
		var/ty = tile[2]
		// Must be at least 5 tiles from player start (center)
		var/dx = tx - half
		var/dy = ty - half
		if(dx * dx + dy * dy < 25)
			continue
		available.Cut(pick_idx, pick_idx + 1)
		var/etype = pick(enemy_types)
		ents += list(list("type" = etype, "x" = tx + 0.5, "y" = ty + 0.5))
		enemies_placed++

	// Place 5 pickups
	var/pickups_placed = 0
	attempts = 0
	while(pickups_placed < 5 && length(available) && attempts < 50)
		attempts++
		var/pick_idx = rand(1, length(available))
		var/list/tile = available[pick_idx]
		available.Cut(pick_idx, pick_idx + 1)
		var/ptype = prob(50) ? "pickup_health" : "pickup_ammo"
		ents += list(list("type" = ptype, "x" = tile[1] + 0.5, "y" = tile[2] + 0.5))
		pickups_placed++

	return ents

/obj/machinery/computer/arcade/fps/station/generate_player_start(level)
	var/half = STATION_FPS_CHUNK / 2
	return list("x" = half + 0.5, "y" = half + 0.5, "angle" = 0)

/obj/machinery/computer/arcade/fps/station/ui_static_data(mob/user)
	var/list/data = list()
	data["map"] = generate_map(1)
	data["entities"] = generate_entities(1)
	data["player_start"] = generate_player_start(1)
	// Send level 3 so the JS engine treats exit as final win
	data["level"] = 3
	return data

// Circuit board for station variant
/obj/item/circuitboard/computer/arcade/fps/station
	name = "Space Slayer Arcade - Station Map (Computer Board)"
	icon_state = "generic"
	build_path = /obj/machinery/computer/arcade/fps/station

#undef STATION_FPS_CHUNK
