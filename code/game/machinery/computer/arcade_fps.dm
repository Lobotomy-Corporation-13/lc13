/// Leaderboard sort comparator (descending by score)
/proc/cmp_leaderboard_desc(list/a, list/b)
	return b["score"] - a["score"]

/// R Corp Hatchery - A DOOM-like first person shooter arcade minigame.
/// R Corp rabbit combat training simulation.
/// The game engine runs entirely client-side in JavaScript;
/// the DM backend only provides map data and tracks high scores.

/obj/machinery/computer/arcade/fps
	name = "R Corp Hatchery Arcade"
	desc = "R Corp combat training sim. Clear hostiles. Prove your worth, rabbit."
	icon_state = "arcade"
	icon_keyboard = "no_keyboard"
	icon_screen = "invaders"
	light_color = "#ff6633"
	circuit = /obj/item/circuitboard/computer/arcade/fps
	/// The current level
	var/current_level = 1
	/// Max level for this machine
	var/max_level = 8
	/// Leaderboard: list of list("name","score")
	var/list/leaderboard = list()
	/// Throttle for sound effects (world.time)
	var/last_sfx_time = 0

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
	data["needsKey"] = level_needs_key(current_level)
	data["isBossLevel"] = (current_level == max_level)
	return data

/obj/machinery/computer/arcade/fps/ui_data(mob/user)
	var/list/data = list()
	data["leaderboard"] = leaderboard
	return data

/obj/machinery/computer/arcade/fps/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("submit_score")
			var/score = text2num(params["score"])
			var/pname = params["name"]
			if(!pname || length(pname) < 1)
				pname = usr?.name || "???"
			pname = copytext(pname, 1, 7)
			leaderboard += list(list("name" = pname, "score" = score))
			// Sort descending, keep top 10
			leaderboard = sortTim(leaderboard, /proc/cmp_leaderboard_desc)
			if(length(leaderboard) > 10)
				leaderboard.Cut(11)
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
		if("sfx")
			var/snd = params["s"]
			if(world.time - last_sfx_time < 3)
				return
			last_sfx_time = world.time
			switch(snd)
				if("shoot")
					playsound(loc, 'sound/arcade/hit.ogg', 30, TRUE)
				if("shotgun")
					playsound(loc, 'sound/arcade/boom.ogg', 40, TRUE)
				if("kill")
					playsound(loc, 'sound/arcade/steal.ogg', 35, TRUE)
				if("pickup")
					playsound(loc, 'sound/arcade/heal.ogg', 35, TRUE)
				if("explode")
					playsound(loc, 'sound/arcade/boom.ogg', 50, TRUE)
			. = TRUE

/// Builds a multi-story map from stacked floor grids.
/// Each floor is a list of row strings using:
///   0 = open/empty (no floor here)
///   1-4 = wall, 5 = exit, 6 = floor tile
/// Rules:
///   - Floor tiles on story N get floorH = N
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
				var/story_h = fi - 1
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
						slope_data = list("dir" = 0, "rise" = 1)
						has_slopes = TRUE
					if("T")
						if(lowest_floor < 0)
							lowest_floor = story_h
						slope_data = list("dir" = 1, "rise" = 1)
						has_slopes = TRUE
					if("V")
						if(lowest_floor < 0)
							lowest_floor = story_h
						slope_data = list("dir" = 2, "rise" = 1)
						has_slopes = TRUE
					if("W")
						if(lowest_floor < 0)
							lowest_floor = story_h
						slope_data = list("dir" = 3, "rise" = 1)
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
///   F = second floor (floorH 1, ceilH 2)
///   G = ground under upper (floorH 0, ceilH 1)
///   O = open atrium (floorH 0, ceilH 2)
///   S = ramp up (+y, rise 1, full story)
///   T = ramp right (+x, rise 1, full story)
///   V = ramp down (-y, rise 1, full story)
///   W = ramp left (-x, rise 1, full story)
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
					ceilH += 1
					slopes += 0
				if("1", "2", "3", "4")
					cells += text2num(ch)
					floorH += 0
					ceilH += 1
					slopes += 0
				if("5")
					cells += 5
					floorH += 0
					ceilH += 1
					slopes += 0
				if("P")
					cells += 0
					floorH += 0.3
					ceilH += 1
					slopes += 0
				if("U")
					cells += 0
					floorH += 0.5
					ceilH += 1
					slopes += 0
				if("D")
					cells += 0
					floorH += -0.3
					ceilH += 1
					slopes += 0
				if("L")
					cells += 0
					floorH += 0
					ceilH += 0.6
					slopes += 0
				if("H")
					cells += 0
					floorH += 0
					ceilH += 1
					slopes += 0
					holes += length(cells)
				if("I")
					// Slope up-facing: rises toward +y
					cells += 0
					floorH += 0
					ceilH += 1
					slopes += list(list("dir" = 0, "rise" = 0.3))
					has_slopes = TRUE
				if("J")
					// Slope left-facing: rises toward -x
					cells += 0
					floorH += 0
					ceilH += 1
					slopes += list(list("dir" = 3, "rise" = 0.3))
					has_slopes = TRUE
				if("K")
					// Slope down-facing: rises toward -y
					cells += 0
					floorH += 0
					ceilH += 1
					slopes += list(list("dir" = 2, "rise" = 0.3))
					has_slopes = TRUE
				if("R")
					// Slope right-facing: rises toward +x
					cells += 0
					floorH += 0
					ceilH += 1
					slopes += list(list("dir" = 1, "rise" = 0.3))
					has_slopes = TRUE
				if("F")
					// Second floor
					cells += 0
					floorH += 1
					ceilH += 2
					slopes += 0
				if("G")
					// Ground under upper floor
					cells += 0
					floorH += 0
					ceilH += 1
					slopes += 0
				if("O")
					// Open atrium (double height)
					cells += 0
					floorH += 0
					ceilH += 2
					slopes += 0
				if("S")
					// Full story ramp up (+y)
					cells += 0
					floorH += 0
					ceilH += 2
					slopes += list(list("dir" = 0, "rise" = 1))
					has_slopes = TRUE
				if("T")
					// Full story ramp right (+x)
					cells += 0
					floorH += 0
					ceilH += 2
					slopes += list(list("dir" = 1, "rise" = 1))
					has_slopes = TRUE
				if("V")
					// Full story ramp down (-y)
					cells += 0
					floorH += 0
					ceilH += 2
					slopes += list(list("dir" = 2, "rise" = 1))
					has_slopes = TRUE
				if("W")
					// Full story ramp left (-x)
					cells += 0
					floorH += 0
					ceilH += 2
					slopes += list(list("dir" = 3, "rise" = 1))
					has_slopes = TRUE
				else
					cells += 0
					floorH += 0
					ceilH += 1
					slopes += 0

	data["cells"] = cells
	data["floorH"] = floorH
	data["ceilH"] = ceilH
	if(length(holes))
		data["holes"] = holes
	if(has_slopes)
		data["slopes"] = slopes
	return data

/// Whether this level requires a key to exit
/obj/machinery/computer/arcade/fps/proc/level_needs_key(level)
	switch(level)
		if(3, 5, 7)
			return TRUE
	return FALSE

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
		if(8)
			return generate_level_8()
	return generate_level_1()

/// Sector 1: Basic training, teaches movement
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

/// Sector 2: Intermediate training
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

/// Sector 3: Advanced training, dangerous
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

/// Sector 4: Hive simulation
/// Organic environment, swarm hostiles
/// Wall type 6 = amber/chitin
/obj/machinery/computer/arcade/fps/proc/generate_level_4()
	var/list/data = list()
	data["width"] = 24
	data["height"] = 24
	var/list/cells = list()
	var/list/rows = list(
		"666666666666666666666666",
		"600000006000000060000006",
		"600000006000000060000006",
		"600000006000000000000006",
		"600000000000000000000006",
		"600000000000006660000006",
		"666606666000006000000006",
		"600000006000006000066666",
		"600000006000006000000006",
		"600000000000000000000006",
		"600000000000000000000006",
		"666660666066660660006006",
		"600000000060000000006006",
		"600000000060000000006006",
		"600000000000000000000006",
		"666060666000000066606666",
		"600060006000000060000006",
		"600000006000000060000006",
		"600000000000006000000006",
		"600000000000006000000006",
		"666606666000006066606666",
		"600000006000000000000006",
		"600000006000000000000056",
		"666666666666666666666666"
	)
	for(var/row in rows)
		for(var/i in 1 to length(row))
			cells += text2num(copytext(row, i, i + 1))
	data["cells"] = cells
	return data

/// Sector 5: Open combat arena
/// Explosive hostiles, no cover
/// Wall type 4 = crimson
/obj/machinery/computer/arcade/fps/proc/generate_level_5()
	var/list/data = list()
	data["width"] = 24
	data["height"] = 24
	var/list/cells = list()
	var/list/rows = list(
		"444444444444444444444444",
		"400000000000000000000004",
		"400000000000000000000004",
		"400044400004440004440004",
		"400040000000400000400004",
		"400040000000400000400004",
		"400000000000000000000004",
		"400000000000000000000004",
		"400044000004440004400004",
		"400000000000000000000004",
		"400000000000000000000004",
		"400000000044440000000004",
		"400000000044440000000004",
		"400000000000000000000004",
		"400000000000000000000004",
		"400044000004440004400004",
		"400000000000000000000004",
		"400000000000000000000004",
		"400040000000400000400004",
		"400040000000400000400004",
		"400044400004440004440004",
		"400000000000000000000004",
		"400000000000000000000054",
		"444444444444444444444444"
	)
	for(var/row in rows)
		for(var/i in 1 to length(row))
			cells += text2num(copytext(row, i, i + 1))
	data["cells"] = cells
	return data

/// Sector 6: Defense grid simulation
/// Grid corridors, automated ranged hostiles
/// Wall type 7 = green/tech
/obj/machinery/computer/arcade/fps/proc/generate_level_6()
	var/list/data = list()
	data["width"] = 24
	data["height"] = 24
	var/list/cells = list()
	var/list/rows = list(
		"777777777777777777777777",
		"700000007000000070000007",
		"700000007000000070000007",
		"700000007000000070000007",
		"700000000000000000000007",
		"700000000000000000000007",
		"777707777000000077707777",
		"700000007000000070000007",
		"700000007000000070000007",
		"700000000000000000000007",
		"777707777077770777707777",
		"700000000070000000000007",
		"700000000070000000000007",
		"700000000000000000000007",
		"777707777077770777707777",
		"700000000000000000000007",
		"700000007000000070000007",
		"700000007000000070000007",
		"777707777000000077707777",
		"700000000000000000000007",
		"700000000000000000000007",
		"700000007000000070000007",
		"700000007000000070000057",
		"777777777777777777777777"
	)
	for(var/row in rows)
		for(var/i in 1 to length(row))
			cells += text2num(copytext(row, i, i + 1))
	data["cells"] = cells
	return data

/// Sector 7: Stealth maze
/// Dark corridors, cloaked hostiles
/// Wall type 8 = violet/eldritch
/obj/machinery/computer/arcade/fps/proc/generate_level_7()
	var/list/data = list()
	data["width"] = 24
	data["height"] = 24
	var/list/cells = list()
	var/list/rows = list(
		"888888888888888888888888",
		"800000008000000080000008",
		"808880008080000080888008",
		"800080008080000080800008",
		"800080000080888080800008",
		"800080008000000000800008",
		"800080008088880880000008",
		"800000008080000080000008",
		"888808888080000088808888",
		"800000000080000000000008",
		"800000000088880000000008",
		"808888808000000088888008",
		"800000008000000080000008",
		"800000008088880080000008",
		"808880008080000080880008",
		"800080008000000000080008",
		"800080008000008880080008",
		"800000000000008000000008",
		"888808888088808088808888",
		"800000008000000080000008",
		"800000000000000080000008",
		"800888008088880000000008",
		"800000008000000000000058",
		"888888888888888888888888"
	)
	for(var/row in rows)
		for(var/i in 1 to length(row))
			cells += text2num(copytext(row, i, i + 1))
	data["cells"] = cells
	return data

/// Sector 8: Final combat exam
/// One high-value target, open arena
/obj/machinery/computer/arcade/fps/proc/generate_level_8()
	var/list/data = list()
	data["width"] = 24
	data["height"] = 24
	var/list/cells = list()
	var/list/rows = list(
		"444444444444444444444444",
		"400000000000000000000004",
		"400000000000000000000004",
		"400044000000000000440004",
		"400044000000000000440004",
		"400000000000000000000004",
		"400000000000000000000004",
		"400000004400004400000004",
		"400000004400004400000004",
		"400000000000000000000004",
		"400000000000000000000004",
		"400000000000000000000004",
		"400000000000000000000004",
		"400000000000000000000004",
		"400000000000000000000004",
		"400000004400004400000004",
		"400000004400004400000004",
		"400000000000000000000004",
		"400000000000000000000004",
		"400044000000000000440004",
		"400044000000000000440004",
		"400000000000000000000004",
		"400000000000000000000054",
		"444444444444444444444444"
	)
	for(var/row in rows)
		for(var/i in 1 to length(row))
			cells += text2num(copytext(row, i, i + 1))
	data["cells"] = cells
	return data

/// Generates entity spawn data for a level
/obj/machinery/computer/arcade/fps/proc/generate_entities(level)
	var/list/ents = list()
	switch(level)
		if(1)
			// Sector 1: basic targets
			ents += list(list("type" = "enemy_blob", "x" = 5.5, "y" = 3.5))
			ents += list(list("type" = "enemy_blob", "x" = 14.5, "y" = 5.5))
			ents += list(list("type" = "enemy_blob", "x" = 20.5, "y" = 3.5))
			ents += list(list("type" = "enemy_exploder", "x" = 5.5, "y" = 16.5))
			ents += list(list("type" = "pickup_health", "x" = 10.5, "y" = 7.5))
			ents += list(list("type" = "pickup_ammo", "x" = 3.5, "y" = 13.5))
			ents += list(list("type" = "pickup_health", "x" = 18.5, "y" = 18.5))
		if(2)
			// Sector 2: mixed hostiles
			ents += list(list("type" = "enemy_blob", "x" = 3.5, "y" = 2.5))
			ents += list(list("type" = "enemy_alien", "x" = 14.5, "y" = 2.5))
			ents += list(list("type" = "enemy_cult", "x" = 14.5, "y" = 10.5))
			ents += list(list("type" = "enemy_cult", "x" = 20.5, "y" = 14.5))
			ents += list(list("type" = "enemy_charger", "x" = 3.5, "y" = 16.5))
			ents += list(list("type" = "enemy_exploder", "x" = 10.5, "y" = 16.5))
			ents += list(list("type" = "enemy_alien", "x" = 20.5, "y" = 20.5))
			ents += list(list("type" = "enemy_blob", "x" = 3.5, "y" = 9.5))
			ents += list(list("type" = "pickup_health", "x" = 7.5, "y" = 10.5))
			ents += list(list("type" = "pickup_ammo", "x" = 15.5, "y" = 6.5))
			ents += list(list("type" = "pickup_health", "x" = 3.5, "y" = 20.5))
			ents += list(list("type" = "pickup_ammo", "x" = 20.5, "y" = 9.5))
		if(3)
			// Sector 3: all hostile types
			ents += list(list("type" = "enemy_blob", "x" = 5.5, "y" = 2.5))
			ents += list(list("type" = "enemy_cult", "x" = 14.5, "y" = 2.5))
			ents += list(list("type" = "enemy_cult", "x" = 20.5, "y" = 2.5))
			ents += list(list("type" = "enemy_charger", "x" = 2.5, "y" = 9.5))
			ents += list(list("type" = "enemy_stealth", "x" = 8.5, "y" = 13.5))
			ents += list(list("type" = "enemy_cult", "x" = 14.5, "y" = 10.5))
			ents += list(list("type" = "enemy_exploder", "x" = 20.5, "y" = 9.5))
			ents += list(list("type" = "enemy_charger", "x" = 2.5, "y" = 17.5))
			ents += list(list("type" = "enemy_alien", "x" = 8.5, "y" = 20.5))
			ents += list(list("type" = "enemy_stealth", "x" = 18.5, "y" = 17.5))
			ents += list(list("type" = "enemy_exploder", "x" = 14.5, "y" = 20.5))
			ents += list(list("type" = "enemy_alien", "x" = 20.5, "y" = 20.5))
			ents += list(list("type" = "pickup_health", "x" = 2.5, "y" = 6.5))
			ents += list(list("type" = "pickup_ammo", "x" = 10.5, "y" = 6.5))
			ents += list(list("type" = "pickup_health", "x" = 2.5, "y" = 14.5))
			ents += list(list("type" = "pickup_ammo", "x" = 20.5, "y" = 14.5))
			ents += list(list("type" = "pickup_health", "x" = 10.5, "y" = 20.5))
			ents += list(list("type" = "pickup_key", "x" = 8.5, "y" = 13.5))
		if(4)
			// Sector 4: swarm hostiles
			ents += list(list("type" = "enemy_blob", "x" = 3.5, "y" = 2.5))
			ents += list(list("type" = "enemy_blob", "x" = 14.5, "y" = 3.5))
			ents += list(list("type" = "enemy_blob", "x" = 3.5, "y" = 9.5))
			ents += list(list("type" = "enemy_blob", "x" = 20.5, "y" = 9.5))
			ents += list(list("type" = "enemy_exploder", "x" = 14.5, "y" = 10.5))
			ents += list(list("type" = "enemy_exploder", "x" = 3.5, "y" = 17.5))
			ents += list(list("type" = "enemy_exploder", "x" = 20.5, "y" = 17.5))
			ents += list(list("type" = "enemy_alien", "x" = 10.5, "y" = 14.5))
			ents += list(list("type" = "pickup_health", "x" = 5.5, "y" = 7.5))
			ents += list(list("type" = "pickup_ammo", "x" = 14.5, "y" = 7.5))
			ents += list(list("type" = "pickup_health", "x" = 3.5, "y" = 14.5))
			ents += list(list("type" = "pickup_ammo", "x" = 20.5, "y" = 20.5))
		if(5)
			// Sector 5: explosive combat
			ents += list(list("type" = "enemy_charger", "x" = 10.5, "y" = 1.5))
			ents += list(list("type" = "enemy_charger", "x" = 20.5, "y" = 6.5))
			ents += list(list("type" = "enemy_charger", "x" = 3.5, "y" = 13.5))
			ents += list(list("type" = "enemy_exploder", "x" = 15.5, "y" = 4.5))
			ents += list(list("type" = "enemy_exploder", "x" = 5.5, "y" = 9.5))
			ents += list(list("type" = "enemy_exploder", "x" = 18.5, "y" = 16.5))
			ents += list(list("type" = "enemy_blob", "x" = 3.5, "y" = 4.5))
			ents += list(list("type" = "enemy_blob", "x" = 20.5, "y" = 20.5))
			ents += list(list("type" = "pickup_health", "x" = 10.5, "y" = 9.5))
			ents += list(list("type" = "pickup_health", "x" = 10.5, "y" = 16.5))
			ents += list(list("type" = "pickup_ammo", "x" = 3.5, "y" = 20.5))
			ents += list(list("type" = "pickup_ammo", "x" = 20.5, "y" = 13.5))
			ents += list(list("type" = "pickup_key", "x" = 5.5, "y" = 11.5))
		if(6)
			// Sector 6: ranged defense grid
			ents += list(list("type" = "enemy_cult", "x" = 14.5, "y" = 2.5))
			ents += list(list("type" = "enemy_cult", "x" = 20.5, "y" = 2.5))
			ents += list(list("type" = "enemy_cult", "x" = 5.5, "y" = 8.5))
			ents += list(list("type" = "enemy_cult", "x" = 14.5, "y" = 12.5))
			ents += list(list("type" = "enemy_cult", "x" = 3.5, "y" = 17.5))
			ents += list(list("type" = "enemy_alien", "x" = 20.5, "y" = 8.5))
			ents += list(list("type" = "enemy_alien", "x" = 3.5, "y" = 12.5))
			ents += list(list("type" = "enemy_charger", "x" = 20.5, "y" = 19.5))
			ents += list(list("type" = "pickup_health", "x" = 5.5, "y" = 4.5))
			ents += list(list("type" = "pickup_health", "x" = 14.5, "y" = 15.5))
			ents += list(list("type" = "pickup_ammo", "x" = 20.5, "y" = 4.5))
			ents += list(list("type" = "pickup_ammo", "x" = 5.5, "y" = 19.5))
		if(7)
			// Sector 7: cloaked hostiles
			ents += list(list("type" = "enemy_stealth", "x" = 5.5, "y" = 2.5))
			ents += list(list("type" = "enemy_stealth", "x" = 14.5, "y" = 5.5))
			ents += list(list("type" = "enemy_stealth", "x" = 20.5, "y" = 9.5))
			ents += list(list("type" = "enemy_stealth", "x" = 3.5, "y" = 14.5))
			ents += list(list("type" = "enemy_cult", "x" = 14.5, "y" = 12.5))
			ents += list(list("type" = "enemy_cult", "x" = 5.5, "y" = 9.5))
			ents += list(list("type" = "enemy_exploder", "x" = 20.5, "y" = 17.5))
			ents += list(list("type" = "enemy_exploder", "x" = 10.5, "y" = 20.5))
			ents += list(list("type" = "enemy_blob", "x" = 3.5, "y" = 7.5))
			ents += list(list("type" = "enemy_blob", "x" = 18.5, "y" = 20.5))
			ents += list(list("type" = "pickup_health", "x" = 5.5, "y" = 7.5))
			ents += list(list("type" = "pickup_health", "x" = 14.5, "y" = 17.5))
			ents += list(list("type" = "pickup_ammo", "x" = 20.5, "y" = 5.5))
			ents += list(list("type" = "pickup_ammo", "x" = 3.5, "y" = 20.5))
			ents += list(list("type" = "pickup_key", "x" = 14.5, "y" = 9.5))
		if(8)
			// Final exam: one HVT
			ents += list(list("type" = "enemy_boss", "x" = 12.5, "y" = 5.5))
			ents += list(list("type" = "pickup_health", "x" = 3.5, "y" = 3.5))
			ents += list(list("type" = "pickup_health", "x" = 20.5, "y" = 3.5))
			ents += list(list("type" = "pickup_ammo", "x" = 3.5, "y" = 20.5))
			ents += list(list("type" = "pickup_ammo", "x" = 20.5, "y" = 20.5))
			ents += list(list("type" = "pickup_health", "x" = 12.5, "y" = 20.5))
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
			return list("x" = 1.5, "y" = 1.5, "angle" = 0)
		if(5)
			return list("x" = 1.5, "y" = 1.5, "angle" = 0)
		if(6)
			return list("x" = 1.5, "y" = 1.5, "angle" = 0)
		if(7)
			return list("x" = 1.5, "y" = 1.5, "angle" = 0)
		if(8)
			return list("x" = 12.5, "y" = 21.5, "angle" = -1.5708)
	return list("x" = 1.5, "y" = 1.5, "angle" = 0)

// Subtypes that start on specific levels for testing
/obj/machinery/computer/arcade/fps/level4
	name = "R Corp Hatchery (Sector 4: Hive)"
	desc = "Training sector with organic hostiles."
	current_level = 4

/obj/machinery/computer/arcade/fps/level5
	name = "R Corp Hatchery (Sector 5: Arena)"
	desc = "Open combat arena. Explosives expected."
	current_level = 5

/obj/machinery/computer/arcade/fps/level6
	name = "R Corp Hatchery (Sector 6: Facility)"
	desc = "Automated defense grid. Watch for turrets."
	current_level = 6

/obj/machinery/computer/arcade/fps/level8
	name = "R Corp Hatchery (Final Exam)"
	desc = "The final combat evaluation. One target."
	current_level = 8

/// Advanced training arcade - plays sectors 4-7
/// (the four advanced training sectors)
/obj/machinery/computer/arcade/fps/ordeals
	name = "R Corp Hatchery: Advanced Training"
	desc = "Four advanced training sectors. Each one harder than the last."
	current_level = 4
	max_level = 7

/obj/machinery/computer/arcade/fps/ordeals/ui_act(action, params)
	. = ..()
	if(.)
		return
	// Override restart/died to reset to level 4
	switch(action)
		if("restart")
			current_level = 4
			update_static_data(usr)
			return TRUE
		if("died")
			playsound(loc, 'sound/arcade/lose.ogg', 50, TRUE)
			current_level = 4
			update_static_data(usr)
			return TRUE

// Circuit board
/obj/item/circuitboard/computer/arcade/fps
	name = "R Corp Hatchery Arcade (Computer Board)"
	icon_state = "generic"
	build_path = /obj/machinery/computer/arcade/fps

// Station Map Variant
// Reads the live station map around the
// arcade machine and converts it to an
// FPS-playable grid.

#define STATION_FPS_CHUNK 48

/obj/machinery/computer/arcade/fps/station
	name = "R Corp Hatchery (Local Scan)"
	desc = "Scans the local facility for training. These halls look familiar..."
	/// Cached floor tile positions for entity placement
	var/list/floor_tiles = list()

/obj/machinery/computer/arcade/fps/station/generate_map(level)
	var/list/data = list()
	data["width"] = STATION_FPS_CHUNK
	data["height"] = STATION_FPS_CHUNK
	var/list/cells = list()
	floor_tiles.Cut()

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
	if(!length(floor_tiles))
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
	name = "R Corp Hatchery - Local Branch (Computer Board)"
	icon_state = "generic"
	build_path = /obj/machinery/computer/arcade/fps/station

#undef STATION_FPS_CHUNK
